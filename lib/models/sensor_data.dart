class SensorData {
  final double temperature; // in Celsius
  final double humidity; // in %
  final double soilMoisture; // in %
  final double soilRaw; // raw soil sensor value
  final double lightLevel; // in Lux
  final double co2; // in ppm
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.soilRaw,
    required this.lightLevel,
    required this.co2,
    required this.timestamp,
  });

  // Factory for initial empty state
  factory SensorData.initial() {
    return SensorData(
      temperature: 0.0,
      humidity: 0.0,
      soilMoisture: 0.0,
      soilRaw: 0.0,
      lightLevel: 0.0,
      co2: 0.0,
      timestamp: DateTime.now(),
    );
  }

  // Factory to parse API response
  factory SensorData.fromJson(Map<String, dynamic> json) {
    DateTime parseTimestamp(String? tsString) {
      if (tsString == null) return DateTime.now();
      try {
        return DateTime.parse(tsString);
      } catch (e) {
        return DateTime.now();
      }
    }

    double getValue(Map<String, dynamic>? data) {
      if (data == null) return 0.0;
      var value = data['value'];
      if (value == null) return 0.0;
      return (value is num) ? value.toDouble() : 0.0;
    }

    // Get the most recent timestamp from all sensors
    DateTime getMostRecentTimestamp() {
      List<DateTime> timestamps = [];
      for (var key in ['temp', 'humidity', 'lux', 'co2', 'soil_percent']) {
        if (json[key] != null && json[key]['timestamp'] != null) {
          timestamps.add(parseTimestamp(json[key]['timestamp']));
        }
      }
      if (timestamps.isEmpty) return DateTime.now();
      timestamps.sort((a, b) => b.compareTo(a));
      return timestamps.first;
    }

    return SensorData(
      temperature: getValue(json['temp']),
      humidity: getValue(json['humidity']),
      soilMoisture: getValue(json['soil_percent']),
      soilRaw: getValue(json['soil_raw']),
      lightLevel: getValue(json['lux']),
      co2: getValue(json['co2']),
      timestamp: getMostRecentTimestamp(),
    );
  }

  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? soilMoisture,
    double? soilRaw,
    double? lightLevel,
    double? co2,
    DateTime? timestamp,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      soilRaw: soilRaw ?? this.soilRaw,
      lightLevel: lightLevel ?? this.lightLevel,
      co2: co2 ?? this.co2,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
