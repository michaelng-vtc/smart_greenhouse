#!/usr/bin/env python3
import json
import asyncio
from datetime import datetime
import requests
import paho.mqtt.client as mqtt
import RPi.GPIO as GPIO

# ==================== Configuration & Globals ====================
BROKER = "127.0.0.1"
PORT = 1883
CLIENT_ID = "pi_controller"

# Remote API Configuration (CentOS 7 PHP Backend)
# Replace with your actual CentOS server IP
REMOTE_API_BASE = "http://192.168.1.217/api/public/v1" 

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
MISTER_PIN = 26   # Misting/Fogging System

# Global reference for the MQTT client
mqtt_client = None 

# Global State
current_duty = 0
current_curtain_state = False
current_pump_state = False
last_co2 = 0 
last_log_time = {}
LOG_INTERVAL = 30 # Log every 30 seconds per topic
received_topics_for_separator = set()

# State tracking for periodic logging
last_heater_state = None
last_mister_state = None

EXPECTED_TOPICS = {
    "greenhouse/sensor/air_th",
    "greenhouse/sensor/soil",
    "greenhouse/sensor/light"
}

# Cache for configuration (fetched from remote API)
cached_setpoints = {
    "vpd_target_low": 0.8,
    "vpd_target_high": 1.2,
    "temp_min_c": 18.0,
    "temp_max_c": 30.0,
    "co2_min_ppm": 500,
    "co2_low_ppm": 600,
    "co2_high_ppm": 1500,
    "light_max_lux": 50000,
    "soil_min_percent": 30.0
}

cached_soil_calib = {
    "dry_adc": 3000,
    "wet_adc": 1200
}

# ==================== GPIO Setup ====================
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(FAN_INA, GPIO.OUT)
pwm = GPIO.PWM(FAN_INA, PWM_FREQ)
pwm.start(0)

# Initialize all system pins
for pin in [CURTAIN_PIN, HEATER_PIN, PUMP_PIN, MISTER_PIN]:
    GPIO.setup(pin, GPIO.OUT)
    GPIO.output(pin, GPIO.LOW) # Ensure all systems are OFF initially


# ==================== Remote API Functions ====================

def fetch_remote_config():
    """Fetches the active profile and calibration from the remote PHP API."""
    global cached_setpoints, cached_soil_calib
    
    # 1. Fetch Active Profile
    try:
        resp = requests.get(f"{REMOTE_API_BASE}/profiles/active", timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            if 'setpoints' in data:
                cached_setpoints.update(data['setpoints'])
                print(f"[API] Updated setpoints from profile: {data.get('profile_name', 'Unknown')}")
                print(f"      Setpoints: {json.dumps(cached_setpoints, indent=2)}")
    except Exception as e:
        print(f"[API Warning] Failed to fetch profile: {e}")

    # 2. Fetch Soil Calibration
    try:
        resp = requests.get(f"{REMOTE_API_BASE}/config/soil", timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            # Ensure keys match what the PHP API returns
            if 'dry_adc' in data and 'wet_adc' in data:
                cached_soil_calib['dry_adc'] = float(data['dry_adc'])
                cached_soil_calib['wet_adc'] = float(data['wet_adc'])
                print(f"[API] Updated soil calibration.")
                print(f"      Calibration: {json.dumps(cached_soil_calib, indent=2)}")
    except Exception as e:
        print(f"[API Warning] Failed to fetch soil calibration: {e}")

def upload_sensor_data(topic: str, payload: dict):
    """Uploads sensor data to the remote PHP API."""
    try:
        # Prepare data for the PHP backend
        # The PHP backend likely expects a POST with 'topic' and 'payload' (or flattened data)
        data_to_send = {
            "topic": topic,
            "timestamp": datetime.now().isoformat(),
            "data": payload
        }
        
        # Fire and forget (with short timeout) to not block control loop too long
        # In a production system, you might use a queue or async HTTP client
        resp = requests.post(f"{REMOTE_API_BASE}/sensors", json=data_to_send, timeout=2)
        if resp.status_code != 200:
            print(f"[API Error] Upload failed: {resp.status_code} - {resp.text}")
        
    except Exception as e:
        print(f"[API Error] Failed to upload data: {e}")


# ==================== Helper Functions: Math ====================

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


# ==================== GPIO Control Functions ====================

def set_output_state(pin: int, state: bool, system_name: str):
    """Generic function to set GPIO output state and log the action."""
    target_state = GPIO.HIGH if state else GPIO.LOW
    
    if GPIO.input(pin) != target_state:
        GPIO.output(pin, target_state)
        status = "ON" if state else "OFF"
        print(f"      [{system_name}] Switched {status}")

def log_fan_state(duty_cycle: int):
    """
    Logs the fan state. 
    In this headless version, we could upload this event to the API too if needed.
    For now, we just print it.
    """
    status = "ON" if duty_cycle > 0 else "OFF"
    # Upload fan state change to API
    try:
        payload = {
            "duty_cycle": duty_cycle, 
            "status": status,
            "timestamp": datetime.now().isoformat()
        }
        resp = requests.post(f"{REMOTE_API_BASE}/fan/log", json=payload, timeout=2)
        if resp.status_code != 200:
            print(f"[API Error] Failed to upload fan log: {resp.status_code} - {resp.text}")
    except Exception as e:
        print(f"[API Error] Failed to upload fan log: {e}")

def log_curtain_state(state: bool, lux: float):
    """Logs the curtain state change to the API."""
    status = "ON" if state else "OFF"
    try:
        payload = {
            "status": status,
            "lux": lux,
            "timestamp": datetime.now().isoformat()
        }
        resp = requests.post(f"{REMOTE_API_BASE}/curtain/log", json=payload, timeout=2)
        if resp.status_code != 200:
            print(f"[API Error] Failed to upload curtain log: {resp.status_code} - {resp.text}")
    except Exception as e:
        print(f"[API Error] Failed to upload curtain log: {e}")

def log_irrigation_state(state: bool, moisture: float):
    """Logs the irrigation pump state change to the API."""
    status = "ON" if state else "OFF"
    try:
        payload = {
            "status": status,
            "soil_moisture": moisture,
            "timestamp": datetime.now().isoformat()
        }
        resp = requests.post(f"{REMOTE_API_BASE}/irrigation/log", json=payload, timeout=2)
        if resp.status_code != 200:
            print(f"[API Error] Failed to upload irrigation log: {resp.status_code} - {resp.text}")
    except Exception as e:
        print(f"[API Error] Failed to upload irrigation log: {e}")

def log_heater_state(state: bool, temp: float):
    """Logs the heater state change to the API."""
    status = "ON" if state else "OFF"
    try:
        payload = {
            "status": status,
            "temp": temp,
            "timestamp": datetime.now().isoformat()
        }
        resp = requests.post(f"{REMOTE_API_BASE}/heater/log", json=payload, timeout=2)
        if resp.status_code != 200:
            print(f"[API Error] Failed to upload heater log: {resp.status_code} - {resp.text}")
    except Exception as e:
        print(f"[API Error] Failed to upload heater log: {e}")

def log_mister_state(state: bool, vpd: float):
    """Logs the mister state change to the API."""
    status = "ON" if state else "OFF"
    try:
        payload = {
            "status": status,
            "vpd": vpd,
            "timestamp": datetime.now().isoformat()
        }
        resp = requests.post(f"{REMOTE_API_BASE}/mister/log", json=payload, timeout=2)
        if resp.status_code != 200:
            print(f"[API Error] Failed to upload mister log: {resp.status_code} - {resp.text}")
    except Exception as e:
        print(f"[API Error] Failed to upload mister log: {e}")

def set_fan_duty(duty: int):
    """Sets the fan PWM duty cycle."""
    global current_duty
    duty = max(0, min(100, duty))
    
    if duty != current_duty:
        pwm.ChangeDutyCycle(duty)
        current_duty = duty
    
    # Log every time as requested
    log_fan_state(duty)

def control_fan_duty(co2_ppm: float, setpoints: dict, verbose: bool = True):
    """Calculates and sets the fan PWM duty cycle based on CO2 level."""
    global current_duty, last_co2
    
    # --- Calculation Logic ---
    co2_min = setpoints.get('co2_min_ppm', 500)
    co2_low = setpoints.get('co2_low_ppm', 600)
    co2_high = setpoints.get('co2_high_ppm', 1500)

    target_co2 = co2_ppm
    if current_duty > 0:
        target_co2 += HYSTERESIS
    else:
        target_co2 -= HYSTERESIS

    if target_co2 <= co2_min:
        duty = 0
    elif target_co2 <= co2_low:
        duty = int(30 * (target_co2 - co2_min) / (co2_low - co2_min))
    elif target_co2 < co2_high:
        duty = int(30 + 70 * (target_co2 - co2_low) / (co2_high - co2_low))
    else:
        duty = 100
    
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
    
    if verbose:
        print(f"      [Fan Status] CO2 {co2_ppm:.0f} ppm{trend} → Fan {status} ({duty:3d}%)")

def control_curtain(lux: float, setpoints: dict, verbose: bool = True):
    """Controls the blackout curtain based on light intensity."""
    light_max_lux = setpoints.get('light_max_lux', 50000)
    
    target_state = lux > light_max_lux
    status_str = "ON" if target_state else "OFF"
    
    if verbose:
        print(f"      [Curtain Status] Light {lux:.1f} lux (Max: {light_max_lux}) → Curtain {status_str}")

    log_curtain_state(target_state, lux)
    set_output_state(CURTAIN_PIN, target_state, "Curtain")

def control_irrigation(soil_raw: float, setpoints: dict, verbose: bool = True):
    """Controls the irrigation pump based on calculated soil moisture percentage."""
    soil_min_percent = setpoints.get('soil_min_percent', 30.0)
    
    # Use cached calibration
    dry = cached_soil_calib.get('dry_adc', 3000)
    wet = cached_soil_calib.get('wet_adc', 1200)
    
    if dry == wet:
        return

    percent = ((dry - soil_raw) / (dry - wet)) * 100
    percent = max(0, min(100, percent))
    
    target_state = percent < soil_min_percent
    status_str = "ON" if target_state else "OFF"

    if verbose:
        print(f"      [Pump Status] Moisture {percent:.1f}% (Min: {soil_min_percent}%) → Pump {status_str}")

    log_irrigation_state(target_state, percent)
    set_output_state(PUMP_PIN, target_state, "Pump")

def control_climate(co2: float, temp: float, hum: float, current_vpd: float, setpoints: dict, verbose: bool = True):
    """
    【最終精簡版本】VPD/Temperature 優先的整合氣候控制函式。
    優先級: 溫度極限 (安全) > VPD (生理優化) > CO2 (生長優化)
    """
    temp_min = setpoints.get('temp_min_c', 18.0)
    temp_max = setpoints.get('temp_max_c', 30.0)
    vpd_low = setpoints.get('vpd_target_low', 0.8)
    vpd_high = setpoints.get('vpd_target_high', 1.2)
    
    heater_state = False
    mister_state = False
    
    # 1. 溫度極限緊急覆蓋 (Priority 1: Safety & Survival)
    if temp > temp_max:
        mister_state = True # 霧化輔助降溫
        set_fan_duty(100) # 強制最大排氣
        print(f"      [SAFETY OVERRIDE] Temp ({temp:.1f}°C) is EXTREME HIGH. Mister ON, Fan 100%.")

    elif temp < temp_min:
        heater_state = True
        set_fan_duty(0) # 關閉風扇保留熱量
        print(f"      [SAFETY OVERRIDE] Temp ({temp:.1f}°C) is EXTREME LOW. Heater ON, Fan OFF.")

    # 2. VPD 偏離目標範圍決策 (Priority 2: Physiological Optimization)
    # A. VPD 過高 (乾燥)：需要加濕
    elif current_vpd > vpd_high:
        mister_state = True
        set_fan_duty(0) 
        print(f"      [VPD Override] VPD ({current_vpd:.2f} kPa) is HIGH (Dry). Mister ON, Fan OFF.")

    # B. VPD 過低 (潮濕)：需要除濕
    elif current_vpd < vpd_low:
        set_fan_duty(100)
        print(f"      [VPD Override] VPD ({current_vpd:.2f} kPa) is LOW (Wet). Fan 100% (Dehumidify).")

    # 3. CO2 標準控制 (Priority 3: Growth Optimization)
    else:
        if verbose:
            print("      [Climate Stable] Executing CO2 Control.")
        control_fan_duty(co2, setpoints, verbose)

    # Apply and Log States
    set_output_state(HEATER_PIN, heater_state, "Heater")
    
    global last_heater_state
    # Log if state changed OR if verbose (periodic heartbeat)
    if last_heater_state != heater_state or verbose:
        log_heater_state(heater_state, temp)
        last_heater_state = heater_state
    
    set_output_state(MISTER_PIN, mister_state, "Mister")
    
    global last_mister_state
    # Log if state changed OR if verbose (periodic heartbeat)
    if last_mister_state != mister_state or verbose:
        log_mister_state(mister_state, current_vpd)
        last_mister_state = mister_state


# ==================== MQTT Functions ====================

def on_connect(client, userdata, flags, reasoncode, properties):
    if reasoncode == 0:
        print("[MQTT] Connected successfully. Subscribing topics...")
        for topic in TOPICS:
            client.subscribe(topic)
            print(f"    Subscribed: {topic}")
        
        # Fetch initial config on connect
        fetch_remote_config()
    else:
        print(f"[MQTT] Connection failed, reasoncode={reasoncode}")

def on_disconnect(client, userdata, flags, reasoncode, properties):
    print("[MQTT] Disconnected from broker. Will auto-reconnect...")

def on_message(client, userdata, msg):
    """Main control loop: reads sensor data, uploads it, and executes control logic."""
    global last_log_time, received_topics_for_separator
    payload = msg.payload.decode("utf-8")
    topic = msg.topic
    ts_str = datetime.now().strftime("%H:%M:%S")
    now = datetime.now()

    device_name = {
        "greenhouse/sensor/air_th": "ESP32 Air_TH Sensor",
        "greenhouse/sensor/soil": "ESP32 Soil Sensor",
        "greenhouse/sensor/light": "ESP32 Light Sensor"
    }.get(topic, "Unknown Device")

    verbose = False
    if topic not in last_log_time or (now - last_log_time[topic]).total_seconds() > LOG_INTERVAL:
        verbose = True
        last_log_time[topic] = now

    if verbose:
        print(f"\n[{ts_str}] Data from {device_name} ({topic}):")
    
    try:
        data = json.loads(payload)
    except json.JSONDecodeError:
        print(f"    Warning: Non-JSON payload: {payload}")
        return

    if verbose:
        for key, value in data.items():
            print(f"    {key:>8}: {value}")
    
    # 1. Upload Data to Remote API
    upload_sensor_data(topic, data)

    # 2. Execute Control Logic (using cached setpoints)
    if topic == "greenhouse/sensor/air_th":
        try:
            raw_temp = data.get("temp")
            raw_hum = data.get("hum") or data.get("humidity")
            raw_co2 = data.get("co2")

            if raw_temp is not None and raw_hum is not None and raw_co2 is not None:
                temp = float(raw_temp)
                hum = float(raw_hum)
                co2 = float(raw_co2)
                
                current_vpd = calculate_vpd(temp, hum)
                if current_vpd is not None:
                    if verbose:
                        print(f"      [VPD] Calculated VPD: {current_vpd:.2f} kPa")
                    control_climate(co2, temp, hum, current_vpd, cached_setpoints, verbose)
        except (ValueError, TypeError) as e:
            print(f"    Error processing air data: {e}")
            
    elif topic == "greenhouse/sensor/soil":
        val = data.get("soil_raw") or data.get("value")
        if val is not None:
            try:
                control_irrigation(float(val), cached_setpoints, verbose)
            except (ValueError, TypeError):
                pass
            
    elif topic == "greenhouse/sensor/light":
        raw_lux = data.get("lux")
        if raw_lux is not None:
            try:
                control_curtain(float(raw_lux), cached_setpoints, verbose)
            except (ValueError, TypeError):
                pass

    # Print separator if all topics have been logged in this cycle
    if verbose:
        received_topics_for_separator.add(topic)
        if EXPECTED_TOPICS.issubset(received_topics_for_separator):
            print("-" * 60)
            received_topics_for_separator.clear()

# ==================== Main Execution ====================

async def config_refresh_loop():
    """Background task to refresh configuration periodically."""
    while True:
        await asyncio.sleep(60) # Refresh every 60 seconds
        print("[System] Refreshing configuration from remote API...")
        fetch_remote_config()

async def main_async():
    global mqtt_client 
    
    # Use CallbackAPIVersion.VERSION2 for paho-mqtt 2.0+ compatibility
    client = mqtt.Client(client_id=CLIENT_ID, protocol=mqtt.MQTTv5, callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.on_message = on_message
    
    print(f"[MQTT] Connecting to {BROKER}:{PORT} ...")
    try:
        client.connect(BROKER, PORT, keepalive=60)
        client.loop_start() 
        mqtt_client = client
        
        # Start the config refresh loop
        await config_refresh_loop()
        
    except Exception as e:
        print(f"[System Error] {e}")
    finally:
        print("[System] Shutting down services...")
        client.loop_stop()
        client.disconnect()
        set_fan_duty(0)
        pwm.stop()
        try:
            GPIO.output(FAN_INA, GPIO.LOW)
            GPIO.output(CURTAIN_PIN, GPIO.LOW)
            GPIO.output(HEATER_PIN, GPIO.LOW)
            GPIO.output(PUMP_PIN, GPIO.LOW)
            GPIO.output(MISTER_PIN, GPIO.LOW)
            GPIO.cleanup()
        except Exception as e:
            print(f"[GPIO Warning] Failed to clean up GPIO: {e}")
        print("Shutdown complete.")

if __name__ == "__main__":
    try:
        asyncio.run(main_async())
    except KeyboardInterrupt:
        print("Program interrupted by user. Performing forced cleanup...")
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
