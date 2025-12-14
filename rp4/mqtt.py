#!/usr/bin/env python3
import json
import sqlite3
import asyncio
from datetime import datetime, timedelta
import uvicorn
from fastapi import FastAPI, HTTPException, Path
from fastapi.middleware.cors import CORSMiddleware
import paho.mqtt.client as mqtt
import RPi.GPIO as GPIO
# 引入 Pydantic 進行數據驗證
from pydantic import BaseModel, Field

# ==================== Configuration & Globals ====================
BROKER = "127.0.0.1"
PORT = 1883
CLIENT_ID = "pi_receiver"
DB_NAME = "greenhouse_data.db"
API_PORT = 5000

TOPICS = [
    "greenhouse/sensor/air_th",
    "greenhouse/sensor/soil",
    "greenhouse/sensor/light"
]

# Fan PWM pin (BCM numbering)
FAN_INA = 17
PWM_FREQ = 1000  # Hz

# Hysteresis to prevent fan flickering (±10 ppm)
HYSTERESIS = 10

# --- System Pins (BCM) ---
CURTAIN_PIN = 27  # Blackout Curtain (Shading)
HEATER_PIN = 22   # Heating System
PUMP_PIN = 23     # Irrigation Pump
MISTER_PIN = 26   # NEW: Misting/Fogging System

# --- Internal Keys ---
ACTIVE_PROFILE_KEY = "active_profile_name"
DEFAULT_PROFILE_NAME = "Default"
SOIL_CALIB_KEY = "soil_calib"

# Topic for sending configuration command to ESP32
CONFIG_TOPIC = "greenhouse/config/soil" 

# Global reference for the MQTT client
mqtt_client = None 

# Global Fan State
current_duty = 0
last_co2 = 0 


# ==================== Pydantic Models for API Input ====================

class SoilCalibration(BaseModel):
    """Data model for soil sensor calibration values (ADC)."""
    dry_adc: int = Field(..., ge=0, le=4095, description="ADC reading for completely dry soil (0%).")
    wet_adc: int = Field(..., ge=0, le=4095, description="ADC reading for saturated soil (100%).")

class ClimateSetpoints(BaseModel):
    """Comprehensive setpoints for a plant growth stage."""
    # VPD Targets (kPa) - 核心控制變數
    vpd_target_low: float = Field(0.8, description="目標最低 VPD (kPa)")
    vpd_target_high: float = Field(1.2, description="目標最高 VPD (kPa)")
    vpd_mister_threshold: float = Field(1.0, description="VPD 觸發霧化系統的閾值 (kPa)") # 新增 VPD 閾值
    
    # Temperature Targets (Celsius) - 加熱/排氣決策
    temp_min_c: float = Field(18.0, description="最低溫度 setpoint (開加熱)")
    temp_max_c: float = Field(30.0, description="最高溫度 setpoint (開排氣/霧化)")
    
    # CO2 Targets (ppm) - 排氣決策
    co2_min_ppm: int = Field(500, description="CO2 最低閾值 (風扇全關)")
    co2_low_ppm: int = Field(600, description="CO2 啟動閾值 (開始排氣)")
    co2_high_ppm: int = Field(1500, description="CO2 高閾值 (最大排氣)")
    
    # Light Target (Lux) - 遮光決策
    light_max_lux: int = Field(50000, description="最大光照強度 (關閉遮光布)")

    # Soil Target (Percent) - 灌溉決策
    soil_min_percent: float = Field(30.0, description="最低土壤濕度百分比 (開水泵)")

class PlantProfile(BaseModel):
    """Structure for saving a named plant profile."""
    profile_name: str = Field(..., description="唯一的植物配置檔案名稱")
    setpoints: ClimateSetpoints

# ==================== GPIO Setup ====================
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(FAN_INA, GPIO.OUT)
pwm = GPIO.PWM(FAN_INA, PWM_FREQ)
pwm.start(0)

# Initialize all system pins
for pin in [CURTAIN_PIN, HEATER_PIN, PUMP_PIN, MISTER_PIN]: # 加入 MISTER_PIN
    GPIO.setup(pin, GPIO.OUT)
    GPIO.output(pin, GPIO.LOW) # Ensure all systems are OFF initially


# ==================== Helper Functions: Math & Configuration ====================

def calculate_vpd(T: float, RH: float) -> float | None:
    """Calculates Vapor Pressure Deficit (VPD) in kPa using Tetens' formula."""
    if T is None or RH is None:
        return None
    
    RH = max(0.01, min(100.0, RH))
    
    try:
        # SVP formula (in hPa)
        svp_hpa = 6.1078 * (10 ** ((7.5 * T) / (237.3 + T)))
        
        # Convert hPa to kPa
        svp_kpa = svp_hpa / 10
        
        # Actual Vapour Pressure (AVP)
        avp_kpa = svp_kpa * (RH / 100.0)
        
        # VPD = SVP - AVP
        vpd = svp_kpa - avp_kpa
        
        return vpd
    except Exception as e:
        print(f"[VPD Error] Calculation failed: {e}")
        return None

def get_active_setpoints() -> dict:
    """Loads and returns the setpoints of the currently active plant profile (with default fallback)."""
    active_name_config = load_config_from_db(ACTIVE_PROFILE_KEY)
    active_name = active_name_config.get('name', DEFAULT_PROFILE_NAME) if active_name_config else DEFAULT_PROFILE_NAME
    setpoints_config = load_config_from_db(f"profile_{active_name}")
    
    if setpoints_config:
        try:
            # 確保使用最新的 Pydantic 模型進行驗證和預設值填充
            return ClimateSetpoints(**setpoints_config).model_dump()
        except Exception:
            # 如果舊的配置結構不兼容，則返回預設值
            print("[CONFIG WARNING] Active profile failed Pydantic validation. Falling back to default.")
            setpoints_config = None
    
    # Fallback to default
    default_setpoints = ClimateSetpoints().model_dump()
    save_config_to_db(f"profile_{DEFAULT_PROFILE_NAME}", default_setpoints)
    save_config_to_db(ACTIVE_PROFILE_KEY, {'name': DEFAULT_PROFILE_NAME})
    return default_setpoints


# ==================== GPIO Control Functions with Interlocks ====================

def set_output_state(pin: int, state: bool, system_name: str):
    """Generic function to set GPIO output state and log the action."""
    target_state = GPIO.HIGH if state else GPIO.LOW
    
    if GPIO.input(pin) != target_state:
        GPIO.output(pin, target_state)
        status = "ON" if state else "OFF"
        print(f"      [{system_name}] Switched {status}")


def control_curtain(lux: float, setpoints: dict):
    """Controls the blackout curtain based on light intensity."""
    light_max_lux = setpoints['light_max_lux']

    if lux > light_max_lux:
        set_output_state(CURTAIN_PIN, True, "Curtain") 
    else:
        set_output_state(CURTAIN_PIN, False, "Curtain")


def control_irrigation(soil_raw: float, setpoints: dict):
    """Controls the irrigation pump based on calculated soil moisture percentage."""
    soil_min_percent = setpoints['soil_min_percent']

    config = load_config_from_db(SOIL_CALIB_KEY)
    
    if not config:
        print("      [System Warning] No soil calibration found. Pump control skipped.")
        return

    try:
        dry = float(config['dry_adc'])
        wet = float(config['wet_adc'])
        
        if dry == wet:
            print("      [System Warning] Soil calibration (dry==wet) invalid. Pump control skipped.")
            return

        percent = ((dry - soil_raw) / (dry - wet)) * 100
        percent = max(0, min(100, percent))
        
        print(f"      [Soil] Moisture {percent:.1f}% (Target Min: {soil_min_percent}%)")

        if percent < soil_min_percent:
            set_output_state(PUMP_PIN, True, "Pump") 
        else:
            set_output_state(PUMP_PIN, False, "Pump")
            
    except (ValueError, TypeError) as e:
        print(f"      [System Error] Soil data or calibration invalid: {e}")

def calculate_fan_duty(co2_ppm: float, setpoints: dict) -> int:
    """Calculates the fan PWM duty cycle based on CO2 level and hysteresis."""
    global current_duty
    
    co2_min = setpoints.get('co2_min_ppm', 500)
    co2_low = setpoints.get('co2_low_ppm', 600)
    co2_high = setpoints.get('co2_high_ppm', 1500)

    target_co2 = co2_ppm
    if current_duty > 0:
        target_co2 += HYSTERESIS
    else:
        target_co2 -= HYSTERESIS

    if target_co2 <= co2_min:
        return 0
    elif target_co2 <= co2_low:
        return int(30 * (target_co2 - co2_min) / (co2_low - co2_min))
    elif target_co2 < co2_high:
        return int(30 + 70 * (target_co2 - co2_low) / (co2_high - co2_low))
    else:
        return 100

def control_fan_duty(co2_ppm: float, setpoints: dict):
    """Calculates and sets the fan PWM duty cycle based on CO2 level (original logic)."""
    global last_co2
    
    duty = calculate_fan_duty(co2_ppm, setpoints)
    set_fan_duty(duty)
    
    # Logging trend
    co2_for_trend = last_co2 
    last_co2 = co2_ppm 
    status = "ON" if duty > 0 else "OFF"
    trend = ""
    if co2_ppm > co2_for_trend + 20:
        trend = " (rising)"
    elif co2_ppm < co2_for_trend - 20:
        trend = " (falling)"
    
    print(f"      [Fan Status] CO2 {co2_ppm:.0f} ppm{trend} → Fan {status} ({duty:3d}%)")

def control_climate(co2: float, temp: float, hum: float, current_vpd: float, setpoints: dict):
    """
    VPD/Temperature 優先的整合氣候控制函式。
    優先級: VPD/Temp Override > CO2 Control
    """
    temp_min = setpoints['temp_min_c']
    temp_max = setpoints['temp_max_c']
    vpd_low = setpoints['vpd_target_low']
    vpd_high = setpoints['vpd_target_high']
    vpd_mister = setpoints['vpd_mister_threshold'] # 使用霧化閾值

    # 1. VPD/Temperature 過高決策 (需要降溫/加濕)
    if current_vpd > vpd_mister or temp > temp_max:
        # 強制執行降溫/加濕動作
        
        # 行動 A: 啟動霧化系統 (同時降溫和加濕，快速降低 VPD)
        set_output_state(MISTER_PIN, True, "Mister")
        
        # 行動 B: 鎖定加熱系統
        set_output_state(HEATER_PIN, False, "Heater")
        
        # 行動 C: 排氣以引入外部空氣或驅散熱量 (如果溫度過高)
        if temp > temp_max:
            set_fan_duty(100)
            print(f"      [Climate Override] Temp ({temp:.1f}°C) is HIGH. Fan 100% (Cooling).")
        else:
            # 如果只是 VPD 高，但溫度不高，傾向不排氣以保留濕潤空氣
            set_fan_duty(0)
            print(f"      [Climate Override] VPD ({current_vpd:.2f} kPa) is HIGH. Mister ON. Fan OFF (Retain Humid Air).")
        
        return # 氣候有緊急狀況，跳過 CO2 決策

    # 2. VPD 略高 (乾燥) 決策 (需要保濕)
    elif current_vpd > vpd_high:
        # VPD 介於 High 和 Mister 之間。空氣乾燥但未達霧化標準。
        # 啟動霧化系統以加濕，並關閉風扇以保留水分。
        set_output_state(MISTER_PIN, True, "Mister")
        set_output_state(HEATER_PIN, False, "Heater")
        set_fan_duty(0)
        print(f"      [Climate Override] VPD ({current_vpd:.2f} kPa) is High (Dry). Mister ON. Fan OFF.")
        return

    # 3. VPD/Temperature 過低決策 (需要除濕/升溫)
    elif current_vpd < vpd_low or temp < temp_min:
        # 強制執行除濕/升溫動作
        
        # 行動 A: 關閉霧化系統
        set_output_state(MISTER_PIN, False, "Mister")
        
        if current_vpd < vpd_low:
            # VPD 過低 (太潮濕)。強制排氣以除濕/提升 VPD。
            set_fan_duty(100)
            print(f"      [Climate Override] VPD ({current_vpd:.2f} kPa) is LOW. Fan 100% (Dehumidify).")
            # 除非溫度也低，否則不開加熱器
            if temp < temp_min:
                 set_output_state(HEATER_PIN, True, "Heater")
                 print("      [Climate Override] Temp LOW. Heater ON (VPD is also low).")
            else:
                 set_output_state(HEATER_PIN, False, "Heater")
                 
        elif temp < temp_min:
            # 溫度過低，但 VPD 正常。啟動加熱。
            set_output_state(HEATER_PIN, True, "Heater")
            set_fan_duty(0) # 關閉排氣以保留熱量
            print(f"      [Climate Override] Temp ({temp:.1f}°C) is LOW. Heater ON. Fan OFF.")
            
        return # 氣候有緊急狀況，跳過 CO2 決策

    # 3. CO2 標準控制 (VPD 和溫度都在目標範圍內)
    else:
        # 關閉所有氣候調節系統，開始 CO2 監測
        set_output_state(HEATER_PIN, False, "Heater")
        set_output_state(MISTER_PIN, False, "Mister")
        print("      [Climate Stable] Executing CO2 Control.")
        control_fan_duty(co2, setpoints) # 執行標準 CO2 漸變控制

# ==================== Fan & DB Utilities ====================

def log_fan_state(duty_cycle: int):
    """Logs the fan's new duty cycle and ON/OFF status into fan_logs table."""
    ts = datetime.now().isoformat()
    status = "ON" if duty_cycle > 0 else "OFF"
    
    try:
        conn = get_db_connection()
        conn.execute(
            "INSERT INTO fan_logs (timestamp, duty_cycle, status) VALUES (?, ?, ?)",
            (ts, duty_cycle, status)
        )
        conn.commit()
    except sqlite3.Error as e:
        print(f"[DB WRITE ERROR] Fan log failed: {e}") 
    finally:
        if conn:
            conn.close()

def set_fan_duty(duty: int):
    """Sets the fan PWM duty cycle and logs the change if it occurs."""
    global current_duty
    duty = max(0, min(100, duty))
    
    if duty != current_duty:
        pwm.ChangeDutyCycle(duty)
        log_fan_state(duty)
        current_duty = duty
        
# ----------------------------------------------------------------------------------
# DB Functions
# ----------------------------------------------------------------------------------
def get_db_connection():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sensor_readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT NOT NULL, topic TEXT NOT NULL, value_key TEXT NOT NULL, value REAL
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS fan_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT NOT NULL, duty_cycle INTEGER NOT NULL, status TEXT NOT NULL 
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS config_settings (
            key TEXT PRIMARY KEY, value TEXT NOT NULL 
        )
    """)
    conn.commit()
    conn.close()

def save_data_to_db(topic: str, data: dict):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        current_ts = datetime.now().isoformat()
        records = []
        for key, value in data.items():
            if key.lower() == 'rssi': continue
            try:
                numeric_value = float(value) 
                records.append((current_ts, topic, key, numeric_value))
            except (ValueError, TypeError): pass
        if records:
            cursor.executemany("INSERT INTO sensor_readings (timestamp, topic, value_key, value) VALUES (?, ?, ?, ?)", records)
            conn.commit()
    except sqlite3.Error as e:
        print(f"[DB WRITE ERROR] Sensor log failed: {e}")
    finally:
        if conn: conn.close()

def save_config_to_db(key: str, config: dict):
    conn = get_db_connection()
    config_json = json.dumps(config)
    conn.execute("""INSERT OR REPLACE INTO config_settings (key, value) VALUES (?, ?)""", (key, config_json))
    conn.commit()
    conn.close()
    print(f"[CONFIG] New configuration saved to SQLite for key: {key}")

def load_config_from_db(key: str) -> dict | None:
    conn = get_db_connection()
    result = conn.execute("SELECT value FROM config_settings WHERE key = ?", (key,)).fetchone()
    conn.close()
    if result: return json.loads(result['value'])
    return None

def init_default_profiles():
    """Initializes default plant profiles if they don't exist."""
    # 1. Default Profile
    if not load_config_from_db(f"profile_{DEFAULT_PROFILE_NAME}"):
        save_config_to_db(f"profile_{DEFAULT_PROFILE_NAME}", ClimateSetpoints().model_dump())

    # 2. Strawberry Profile
    strawberry_name = "Strawberry"
    if not load_config_from_db(f"profile_{strawberry_name}"):
        strawberry_setpoints = ClimateSetpoints(
            vpd_target_low=0.6,
            vpd_target_high=1.0,
            vpd_mister_threshold=1.1,
            temp_min_c=16.0,
            temp_max_c=24.0,
            co2_min_ppm=600,
            co2_low_ppm=700,
            co2_high_ppm=1000,
            light_max_lux=45000,
            soil_min_percent=40.0
        ).model_dump()
        save_config_to_db(f"profile_{strawberry_name}", strawberry_setpoints)
        print(f"[CONFIG] Initialized default profile: {strawberry_name}")

# ==================== MQTT Functions ====================

def publish_config(topic: str, payload: str):
    global mqtt_client
    if mqtt_client and mqtt_client.is_connected():
        mqtt_client.publish(topic, payload, qos=1) 
        print(f"[MQTT CONFIG] Published to {topic}: {payload}")
    else:
        print("[MQTT CONFIG ERROR] Client not connected. Configuration failed.")
        raise RuntimeError("MQTT client is not connected to the broker.")

def on_connect(client, userdata, flags, reasoncode, properties):
    if reasoncode == 0:
        print("[MQTT] Connected successfully. Subscribing topics...")
        for topic in TOPICS: client.subscribe(topic); print(f"    Subscribed: {topic}")
        # Initialize default setpoints if they don't exist
        get_active_setpoints() 
    else: print(f"[MQTT] Connection failed, reasoncode={reasoncode}")

def on_disconnect(client, userdata, flags, reasoncode, properties):
    print("[MQTT] Disconnected from broker. Will auto-reconnect...")

def on_message(client, userdata, msg):
    """Main control loop: reads sensor data, saves it, and executes hierarchical control logic."""
    payload = msg.payload.decode("utf-8")
    topic = msg.topic
    ts_str = datetime.now().strftime("%H:%M:%S")

    device_name = { "greenhouse/sensor/air_th": "ESP32 Air_TH Sensor", "greenhouse/sensor/soil": "ESP32 Soil Sensor", "greenhouse/sensor/light": "ESP32 Light Sensor" }.get(topic, "Unknown Device")
    print(f"\n[{ts_str}] Data from {device_name} ({topic}):")
    try: data = json.loads(payload)
    except json.JSONDecodeError: print(f"    Warning: Non-JSON payload: {payload}"); return
    for key, value in data.items(): print(f"    {key:>8}: {value}")
    
    save_data_to_db(topic, data)
    setpoints = get_active_setpoints()
    active_profile = load_config_from_db(ACTIVE_PROFILE_KEY)
    print(f"    [Profile] Active: {active_profile.get('name')}, VPD Target: {setpoints['vpd_target_low']:.2f}-{setpoints['vpd_target_high']:.2f} kPa")

    # ==================== 智能控制決策鏈 ====================
    if topic == "greenhouse/sensor/air_th":
        try:
            temp = float(data.get("temp"))
            hum = float(data.get("hum"))
            co2 = float(data.get("co2"))
            current_vpd = calculate_vpd(temp, hum)
            print(f"      [VPD] Calculated VPD: {current_vpd:.2f} kPa")
            
            # 核心決策: VPD, Temp, CO2, Heater, Mister, Fan
            control_climate(co2, temp, hum, current_vpd, setpoints)
            
        except (ValueError, TypeError) as e:
            print(f"    Error processing air data: {e}")
            
    elif topic == "greenhouse/sensor/soil":
        val = data.get("soil_raw") or data.get("value")
        if val is not None:
            try: control_irrigation(float(val), setpoints)
            except (ValueError, TypeError): pass
            
    elif topic == "greenhouse/sensor/light" and "lux" in data:
        try: control_curtain(float(data["lux"]), setpoints)
        except (ValueError, TypeError): pass

# ==================== FastAPI API Routes ====================

app = FastAPI(title="Greenhouse Sensor API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"], 
    allow_headers=["*"], 
)

# --- Configuration API Routes: Soil Calibration ---
@app.post("/api/v1/config/soil")
async def set_soil_calibration(config: SoilCalibration):
    if config.dry_adc <= config.wet_adc: raise HTTPException(status_code=400, detail="Dry ADC value must be greater than Wet ADC value for correct calculation.")
    config_dict = config.model_dump()
    save_config_to_db(SOIL_CALIB_KEY, config_dict)
    payload_data = {"cmd": "CALIBRATE_SOIL", "dry": config.dry_adc, "wet": config.wet_adc}
    payload = json.dumps(payload_data)
    try:
        publish_config(CONFIG_TOPIC, payload)
        return {"status": "success", "message": "Soil calibration command sent successfully.", "config_sent": payload_data}
    except RuntimeError as e: raise HTTPException(status_code=503, detail=str(e))

@app.get("/api/v1/config/soil")
async def get_soil_calibration():
    config = load_config_from_db(SOIL_CALIB_KEY)
    if config is None: raise HTTPException(status_code=404, detail="Soil calibration configuration not found. Please set initial values.")
    return config

# --- Plant Profiles API Routes ---
@app.get("/api/v1/profiles")
async def get_all_profiles():
    conn = get_db_connection()
    active_name_config = load_config_from_db(ACTIVE_PROFILE_KEY)
    active_name = active_name_config.get('name') if active_name_config else DEFAULT_PROFILE_NAME
    profiles = conn.execute("SELECT key, value FROM config_settings WHERE key LIKE 'profile_%'").fetchall()
    conn.close()
    result = {"active_profile": active_name, "profiles": {}}
    for row in profiles:
        profile_name = row['key'].replace('profile_', '')
        try:
            setpoints = json.loads(row['value'])
            result["profiles"][profile_name] = ClimateSetpoints(**setpoints).model_dump()
        except json.JSONDecodeError:
            result["profiles"][profile_name] = {"error": "Invalid JSON format in DB"}
    if not result["profiles"] and active_name == DEFAULT_PROFILE_NAME:
         result["profiles"][DEFAULT_PROFILE_NAME] = get_active_setpoints()
    return result

@app.post("/api/v1/profiles")
async def save_plant_profile(profile: PlantProfile):
    if not profile.profile_name: raise HTTPException(status_code=400, detail="Profile name cannot be empty.")
    db_key = f"profile_{profile.profile_name}"
    setpoints_dict = profile.setpoints.model_dump()
    save_config_to_db(db_key, setpoints_dict)
    return {"status": "success", "message": f"Profile '{profile.profile_name}' saved successfully.", "setpoints": setpoints_dict}

@app.post("/api/v1/profiles/activate/{profile_name}")
async def activate_profile(profile_name: str = Path(..., description="The name of the profile to activate.")):
    db_key = f"profile_{profile_name}"
    if load_config_from_db(db_key) is None: raise HTTPException(status_code=404, detail=f"Profile '{profile_name}' not found.")
    save_config_to_db(ACTIVE_PROFILE_KEY, {'name': profile_name})
    new_setpoints = get_active_setpoints()
    print(f"[CONFIG] Activated new profile: {profile_name}")
    return {"status": "success", "message": f"Profile '{profile_name}' is now active.", "setpoints": new_setpoints}

# --- Sensor Data API Routes ---
def get_latest_value_from_db(value_key: str):
    conn = get_db_connection()
    latest_reading = conn.execute("""SELECT timestamp, value FROM sensor_readings WHERE value_key = ? ORDER BY id DESC LIMIT 1""", (value_key,)).fetchone()
    conn.close()
    if latest_reading: return {"timestamp": latest_reading['timestamp'], "value": latest_reading['value']}
    else: return None

@app.get("/api/v1/latest")
async def get_latest_data():
    conn = get_db_connection()
    latest_data = conn.execute("""
        SELECT t1.timestamp, t1.topic, t1.value_key, t1.value
        FROM sensor_readings t1
        INNER JOIN (
            SELECT MAX(id) AS max_id FROM sensor_readings GROUP BY topic, value_key
        ) t2 ON t1.id = t2.max_id ORDER BY t1.timestamp DESC
    """).fetchall()
    conn.close()
    result = {}
    for row in latest_data:
        key = row['value_key'].lower()
        result[key] = {"timestamp": row['timestamp'], "value": row['value']}
    return result

@app.get("/api/v1/latest/{value_key}")
async def get_latest_value(value_key: str):
    db_key = value_key.lower() 
    data = get_latest_value_from_db(db_key)
    if data is None: raise HTTPException(status_code=404, detail=f"Sensor key '{value_key}' not found or no data recorded.")
    return data

@app.get("/api/v1/history/{value_key}")
async def get_generic_history(value_key: str, hours: int = 24):
    conn = get_db_connection()
    time_threshold = (datetime.now() - timedelta(hours=hours)).isoformat()
    db_key = value_key.lower()
    data = conn.execute(
        f"""SELECT timestamp, value FROM sensor_readings WHERE value_key = ? AND timestamp > ? ORDER BY timestamp ASC""",
        (db_key, time_threshold,)
    ).fetchall()
    conn.close()
    if not data:
        if hours == 24: raise HTTPException(status_code=404, detail=f"No historical data found for key: '{value_key}'")
        else: return []
    history = [{"timestamp": row['timestamp'], value_key.lower(): row['value']} for row in data]
    return history

@app.get("/api/v1/fan/history")
async def get_fan_history(hours: int = 24):
    conn = get_db_connection()
    time_threshold = (datetime.now() - timedelta(hours=hours)).isoformat()
    data = conn.execute(
        """SELECT timestamp, duty_cycle, status FROM fan_logs WHERE timestamp > ? ORDER BY timestamp ASC""",
        (time_threshold,)
    ).fetchall()
    conn.close()
    history = [dict(row) for row in data]
    return history

# ==================== Main Execution ====================

# Uvicorn Server Configuration
class Server(uvicorn.Server):
    def __init__(self, app, host='0.0.0.0', port=5000):
        config = uvicorn.Config(app, host=host, port=port, log_level="info") 
        super().__init__(config=config)

async def main_async():
    global mqtt_client 
    init_db()
    init_default_profiles()
    
    # Use CallbackAPIVersion.VERSION2 for paho-mqtt 2.0+ compatibility
    client = mqtt.Client(client_id=CLIENT_ID, protocol=mqtt.MQTTv5, callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.on_message = on_message
    print(f"[MQTT] Connecting to {BROKER}:{PORT} ...")
    client.connect(BROKER, PORT, keepalive=60)
    client.loop_start() 
    
    mqtt_client = client
    
    server = Server(app, host="0.0.0.0", port=API_PORT)
    server_task = asyncio.create_task(server.serve())
    print(f"[System] API Server running on http://0.0.0.0:{API_PORT}")

    try: await server_task 
    except asyncio.CancelledError: print("[System] Task cancelled. Starting cleanup sequence...")
    except KeyboardInterrupt: pass 

    finally:
        print("[System] Shutting down services...")
        client.loop_stop()
        client.disconnect()
        set_fan_duty(0)
        pwm.stop()
        try:
            # Clean up GPIO pins
            GPIO.output(FAN_INA, GPIO.LOW)
            GPIO.output(CURTAIN_PIN, GPIO.LOW)
            GPIO.output(HEATER_PIN, GPIO.LOW)
            GPIO.output(PUMP_PIN, GPIO.LOW)
            GPIO.output(MISTER_PIN, GPIO.LOW) # 確保霧化系統關閉
            GPIO.cleanup()
        except Exception as e: print(f"[GPIO Warning] Failed to clean up GPIO: {e}")
        print("Shutdown complete.")

if __name__ == "__main__":
    try: asyncio.run(main_async())
    except KeyboardInterrupt:
        print("Program interrupted by user. Performing forced cleanup...")
        # Emergency cleanup for KeyboardInterrupt
        set_fan_duty(0)
        pwm.stop()
        try:
            GPIO.output(FAN_INA, GPIO.LOW)
            GPIO.output(CURTAIN_PIN, GPIO.LOW)
            GPIO.output(HEATER_PIN, GPIO.LOW)
            GPIO.output(PUMP_PIN, GPIO.LOW)
            GPIO.output(MISTER_PIN, GPIO.LOW)
            GPIO.cleanup()
        except:
            pass