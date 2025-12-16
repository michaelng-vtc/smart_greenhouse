CREATE DATABASE IF NOT EXISTS greenhouse_db;
USE greenhouse_db;

CREATE TABLE IF NOT EXISTS sensor_readings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    topic VARCHAR(255) NOT NULL,
    value_key VARCHAR(255) NOT NULL,
    value FLOAT,
    INDEX idx_timestamp (timestamp),
    INDEX idx_key (value_key),
    INDEX idx_topic (topic)
);

CREATE TABLE IF NOT EXISTS fan_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    duty_cycle INT NOT NULL,
    status VARCHAR(50) NOT NULL,
    INDEX idx_timestamp (timestamp)
);

CREATE TABLE IF NOT EXISTS curtain_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    status VARCHAR(50) NOT NULL,
    lux FLOAT,
    INDEX idx_timestamp (timestamp)
);

CREATE TABLE IF NOT EXISTS irrigation_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    status VARCHAR(50) NOT NULL,
    soil_moisture FLOAT,
    INDEX idx_timestamp (timestamp)
);

CREATE TABLE IF NOT EXISTS heater_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    status VARCHAR(50) NOT NULL,
    temp FLOAT,
    INDEX idx_timestamp (timestamp)
);

CREATE TABLE IF NOT EXISTS mister_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    status VARCHAR(50) NOT NULL,
    vpd FLOAT,
    INDEX idx_timestamp (timestamp)
);

CREATE TABLE IF NOT EXISTS config_settings (
    `key` VARCHAR(255) PRIMARY KEY,
    `value` TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    verification_code VARCHAR(6),
    is_verified TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS plant_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS plant_info_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    plant_info_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plant_info_id) REFERENCES plant_info(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Insert sample data for plant_info
INSERT INTO plant_info (title, content, image_url) VALUES
('Tomato Care Tips', 'Tomatoes need consistent watering and plenty of sunlight. Prune suckers to encourage fruit growth.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Tomato_je.jpg/1200px-Tomato_je.jpg'),
('Basil Harvesting', 'Harvest basil leaves regularly to encourage bushier growth. Pinch off flowers to maintain flavor.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Basil-Basilico-Ocimum_basilicum-albahaca.jpg/1200px-Basil-Basilico-Ocimum_basilicum-albahaca.jpg'),
('Pest Control: Aphids', 'Aphids can be controlled with neem oil or a strong blast of water. Ladybugs are also natural predators.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Aphid_on_leaf05.jpg/1200px-Aphid_on_leaf05.jpg');

-- Insert sample data for sensor_readings
INSERT INTO sensor_readings (timestamp, topic, value_key, value) VALUES
(DATE_SUB(NOW(), INTERVAL 90 MINUTE), 'greenhouse/sensor/air_th', 'temp', 22.1),
(DATE_SUB(NOW(), INTERVAL 90 MINUTE), 'greenhouse/sensor/air_th', 'humidity', 55.0),
(DATE_SUB(NOW(), INTERVAL 90 MINUTE), 'greenhouse/sensor/air_th', 'co2', 450.0),
(DATE_SUB(NOW(), INTERVAL 90 MINUTE), 'greenhouse/sensor/soil', 'soil_percent', 60.0),
(DATE_SUB(NOW(), INTERVAL 90 MINUTE), 'greenhouse/sensor/light', 'lux', 1000.0),

(DATE_SUB(NOW(), INTERVAL 80 MINUTE), 'greenhouse/sensor/air_th', 'temp', 22.5),
(DATE_SUB(NOW(), INTERVAL 80 MINUTE), 'greenhouse/sensor/air_th', 'humidity', 56.0),
(DATE_SUB(NOW(), INTERVAL 80 MINUTE), 'greenhouse/sensor/air_th', 'co2', 480.0),
(DATE_SUB(NOW(), INTERVAL 80 MINUTE), 'greenhouse/sensor/soil', 'soil_percent', 58.0),
(DATE_SUB(NOW(), INTERVAL 80 MINUTE), 'greenhouse/sensor/light', 'lux', 5000.0),

(DATE_SUB(NOW(), INTERVAL 70 MINUTE), 'greenhouse/sensor/air_th', 'temp', 23.0),
(DATE_SUB(NOW(), INTERVAL 70 MINUTE), 'greenhouse/sensor/air_th', 'humidity', 58.0),
(DATE_SUB(NOW(), INTERVAL 70 MINUTE), 'greenhouse/sensor/air_th', 'co2', 520.0),
(DATE_SUB(NOW(), INTERVAL 70 MINUTE), 'greenhouse/sensor/soil', 'soil_percent', 55.0),
(DATE_SUB(NOW(), INTERVAL 70 MINUTE), 'greenhouse/sensor/light', 'lux', 12000.0),

(DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'greenhouse/sensor/air_th', 'temp', 23.8),
(DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'greenhouse/sensor/air_th', 'humidity', 60.0),
(DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'greenhouse/sensor/air_th', 'co2', 600.0),
(DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'greenhouse/sensor/soil', 'soil_percent', 52.0),
(DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'greenhouse/sensor/light', 'lux', 25000.0),

(DATE_SUB(NOW(), INTERVAL 50 MINUTE), 'greenhouse/sensor/air_th', 'temp', 24.5),
(DATE_SUB(NOW(), INTERVAL 50 MINUTE), 'greenhouse/sensor/air_th', 'humidity', 62.0),
(DATE_SUB(NOW(), INTERVAL 50 MINUTE), 'greenhouse/sensor/air_th', 'co2', 750.0),
(DATE_SUB(NOW(), INTERVAL 50 MINUTE), 'greenhouse/sensor/soil', 'soil_percent', 50.0),
(DATE_SUB(NOW(), INTERVAL 50 MINUTE), 'greenhouse/sensor/light', 'lux', 45000.0),

(DATE_SUB(NOW(), INTERVAL 40 MINUTE), 'greenhouse/sensor/air_th', 'temp', 25.2),
(DATE_SUB(NOW(), INTERVAL 40 MINUTE), 'greenhouse/sensor/air_th', 'humidity', 65.0),
(DATE_SUB(NOW(), INTERVAL 40 MINUTE), 'greenhouse/sensor/air_th', 'co2', 850.0),
(DATE_SUB(NOW(), INTERVAL 40 MINUTE), 'greenhouse/sensor/soil', 'soil_percent', 48.0),
(DATE_SUB(NOW(), INTERVAL 40 MINUTE), 'greenhouse/sensor/light', 'lux', 55000.0),

(DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'greenhouse/sensor/air_th', 'temp', 26.0),
(DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'greenhouse/sensor/air_th', 'humidity', 68.0),
(DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'greenhouse/sensor/air_th', 'co2', 900.0),
(DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'greenhouse/sensor/soil', 'soil_percent', 45.0),
(DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'greenhouse/sensor/light', 'lux', 52000.0),

(DATE_SUB(NOW(), INTERVAL 20 MINUTE), 'greenhouse/sensor/air_th', 'temp', 25.5),
(DATE_SUB(NOW(), INTERVAL 20 MINUTE), 'greenhouse/sensor/air_th', 'humidity', 66.0),
(DATE_SUB(NOW(), INTERVAL 20 MINUTE), 'greenhouse/sensor/air_th', 'co2', 800.0),
(DATE_SUB(NOW(), INTERVAL 20 MINUTE), 'greenhouse/sensor/soil', 'soil_percent', 42.0),
(DATE_SUB(NOW(), INTERVAL 20 MINUTE), 'greenhouse/sensor/light', 'lux', 40000.0),

(DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'greenhouse/sensor/air_th', 'temp', 24.8),
(DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'greenhouse/sensor/air_th', 'humidity', 63.0),
(DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'greenhouse/sensor/air_th', 'co2', 700.0),
(DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'greenhouse/sensor/soil', 'soil_percent', 40.0),
(DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'greenhouse/sensor/light', 'lux', 20000.0),

(NOW(), 'greenhouse/sensor/air_th', 'temp', 24.2),
(NOW(), 'greenhouse/sensor/air_th', 'humidity', 61.0),
(NOW(), 'greenhouse/sensor/air_th', 'co2', 650.0),
(NOW(), 'greenhouse/sensor/soil', 'soil_percent', 38.0),
(NOW(), 'greenhouse/sensor/light', 'lux', 15000.0);

-- Insert sample data for fan_logs
INSERT INTO fan_logs (timestamp, duty_cycle, status) VALUES
(DATE_SUB(NOW(), INTERVAL 90 MINUTE), 0, 'OFF'),
(DATE_SUB(NOW(), INTERVAL 80 MINUTE), 0, 'OFF'),
(DATE_SUB(NOW(), INTERVAL 70 MINUTE), 20, 'ON'),
(DATE_SUB(NOW(), INTERVAL 60 MINUTE), 40, 'ON'),
(DATE_SUB(NOW(), INTERVAL 50 MINUTE), 60, 'ON'),
(DATE_SUB(NOW(), INTERVAL 40 MINUTE), 80, 'ON'),
(DATE_SUB(NOW(), INTERVAL 30 MINUTE), 100, 'ON'),
(DATE_SUB(NOW(), INTERVAL 20 MINUTE), 70, 'ON'),
(DATE_SUB(NOW(), INTERVAL 10 MINUTE), 40, 'ON'),
(NOW(), 20, 'ON');

-- Insert sample data for curtain_logs
INSERT INTO curtain_logs (timestamp, status, lux) VALUES
(DATE_SUB(NOW(), INTERVAL 90 MINUTE), 'OFF', 1000.0),
(DATE_SUB(NOW(), INTERVAL 80 MINUTE), 'OFF', 5000.0),
(DATE_SUB(NOW(), INTERVAL 70 MINUTE), 'OFF', 12000.0),
(DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'OFF', 25000.0),
(DATE_SUB(NOW(), INTERVAL 50 MINUTE), 'OFF', 45000.0),
(DATE_SUB(NOW(), INTERVAL 40 MINUTE), 'ON', 55000.0),
(DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'ON', 52000.0),
(DATE_SUB(NOW(), INTERVAL 20 MINUTE), 'OFF', 40000.0),
(DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'OFF', 20000.0),
(NOW(), 'OFF', 15000.0);

-- Insert sample data for irrigation_logs
INSERT INTO irrigation_logs (timestamp, status, soil_moisture) VALUES
(DATE_SUB(NOW(), INTERVAL 90 MINUTE), 'OFF', 60.0),
(DATE_SUB(NOW(), INTERVAL 80 MINUTE), 'OFF', 58.0),
(DATE_SUB(NOW(), INTERVAL 70 MINUTE), 'OFF', 55.0),
(DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'OFF', 52.0),
(DATE_SUB(NOW(), INTERVAL 50 MINUTE), 'OFF', 50.0),
(DATE_SUB(NOW(), INTERVAL 40 MINUTE), 'OFF', 48.0),
(DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'OFF', 45.0),
(DATE_SUB(NOW(), INTERVAL 20 MINUTE), 'OFF', 42.0),
(DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'OFF', 40.0),
(NOW(), 'ON', 38.0);

-- Insert sample data for heater_logs
INSERT INTO heater_logs (timestamp, status, temp) VALUES
(DATE_SUB(NOW(), INTERVAL 90 MINUTE), 'ON', 18.0),
(DATE_SUB(NOW(), INTERVAL 80 MINUTE), 'ON', 19.5),
(DATE_SUB(NOW(), INTERVAL 70 MINUTE), 'OFF', 21.0),
(DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'OFF', 22.5),
(DATE_SUB(NOW(), INTERVAL 50 MINUTE), 'OFF', 24.0),
(DATE_SUB(NOW(), INTERVAL 40 MINUTE), 'OFF', 25.5),
(DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'OFF', 26.0),
(DATE_SUB(NOW(), INTERVAL 20 MINUTE), 'OFF', 25.5),
(DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'OFF', 24.8),
(NOW(), 'OFF', 24.2);

-- Insert sample data for mister_logs
INSERT INTO mister_logs (timestamp, status, vpd) VALUES
(DATE_SUB(NOW(), INTERVAL 90 MINUTE), 'OFF', 0.8),
(DATE_SUB(NOW(), INTERVAL 80 MINUTE), 'OFF', 0.9),
(DATE_SUB(NOW(), INTERVAL 70 MINUTE), 'OFF', 1.0),
(DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'OFF', 1.1),
(DATE_SUB(NOW(), INTERVAL 50 MINUTE), 'OFF', 1.2),
(DATE_SUB(NOW(), INTERVAL 40 MINUTE), 'ON', 1.5),
(DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'ON', 1.6),
(DATE_SUB(NOW(), INTERVAL 20 MINUTE), 'ON', 1.4),
(DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'OFF', 1.2),
(NOW(), 'OFF', 1.1);

-- Insert Default Profile
INSERT INTO config_settings (`key`, `value`) VALUES 
('active_profile_name', '{"name": "Default"}'),
('profile_Default', '{
    "profile_name": "Default",
    "setpoints": {
        "vpd_target_low": 0.8,
        "vpd_target_high": 1.2,
        "vpd_mister_threshold": 1.0,
        "temp_min_c": 18.0,
        "temp_max_c": 30.0,
        "co2_min_ppm": 500,
        "co2_low_ppm": 600,
        "co2_high_ppm": 1500,
        "light_max_lux": 50000,
        "soil_min_percent": 30.0
    }
}'),
('profile_Strawberry', '{
    "profile_name": "Strawberry",
    "setpoints": {
        "vpd_target_low": 0.6,
        "vpd_target_high": 1.0,
        "vpd_mister_threshold": 1.1,
        "temp_min_c": 16.0,
        "temp_max_c": 24.0,
        "co2_min_ppm": 600,
        "co2_low_ppm": 700,
        "co2_high_ppm": 1000,
        "light_max_lux": 45000,
        "soil_min_percent": 40.0
    }
}'),
('soil_calib', '{"dry_adc": 3000, "wet_adc": 1200}');

CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(255),
    stock INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS chat_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS friends (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    friend_id INT NOT NULL,
    status ENUM('pending', 'accepted') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_friendship (user_id, friend_id)
);

-- Insert sample products
INSERT INTO products (name, description, price, image_url, stock) VALUES
('Tomato Seeds', 'Organic heirloom tomato seeds.', 2.99, 'assets/images/tomato_seeds.png', 100),
('Basil Seeds', 'Fresh sweet basil seeds.', 1.99, 'assets/images/basil_seeds.png', 150),
('Lettuce Seeds', 'Crisp romaine lettuce seeds.', 2.49, 'assets/images/lettuce_seeds.png', 120),
('Pepper Seeds', 'Spicy jalapeño pepper seeds.', 3.49, 'assets/images/pepper_seeds.png', 80),
('Cucumber Seeds', 'Crunchy garden cucumber seeds.', 2.99, 'assets/images/cucumber_seeds.png', 90),
('Strawberry Seeds', 'Sweet wild strawberry seeds.', 4.99, 'assets/images/strawberry_seeds.png', 60);