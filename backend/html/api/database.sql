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
    value TEXT NOT NULL
);
