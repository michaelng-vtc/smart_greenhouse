import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';

class GreenhouseProvider with ChangeNotifier {
  SensorData _data = SensorData.initial();
  final List<SensorData> _history = [];
  Timer? _timer;
  bool _isConnected = false;

  SensorData get data => _data;
  List<SensorData> get history => List.unmodifiable(_history);
  bool get isConnected => _isConnected;

  // Simulate connecting to a cloud service (e.g., MQTT, Firebase, REST API)
  void connect() {
    _isConnected = true;
    notifyListeners();

    // Simulate periodic updates
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchMockData();
    });
  }

  void disconnect() {
    _timer?.cancel();
    _isConnected = false;
    notifyListeners();
  }

  void _fetchMockData() {
    // In a real app, this would be an API call or WebSocket message
    final random = Random();

    // Generate somewhat realistic variations
    double newTemp = 22.0 + random.nextDouble() * 5 - 2.5; // 19.5 - 24.5
    double newHumidity = 60.0 + random.nextDouble() * 10 - 5; // 55 - 65
    double newSoil = 40.0 + random.nextDouble() * 5 - 2.5; // 37.5 - 42.5
    double newLight = 500.0 + random.nextDouble() * 100 - 50; // 450 - 550

    _data = SensorData(
      temperature: double.parse(newTemp.toStringAsFixed(1)),
      humidity: double.parse(newHumidity.toStringAsFixed(1)),
      soilMoisture: double.parse(newSoil.toStringAsFixed(1)),
      lightLevel: double.parse(newLight.toStringAsFixed(0)),
      timestamp: DateTime.now(),
    );

    _history.add(_data);
    if (_history.length > 20) {
      _history.removeAt(0);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
