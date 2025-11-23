class SensorData {
  final double temperature; // in Celsius
  final double humidity; // in %
  final double soilMoisture; // in %
  final double lightLevel; // in Lux
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightLevel,
    required this.timestamp,
  });

  // Factory for initial empty state
  factory SensorData.initial() {
    return SensorData(
      temperature: 0.0,
      humidity: 0.0,
      soilMoisture: 0.0,
      lightLevel: 0.0,
      timestamp: DateTime.now(),
    );
  }
}
