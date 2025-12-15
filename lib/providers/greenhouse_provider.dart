import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import '../models/system_status.dart';
import 'settings_provider.dart';

class GreenhouseProvider with ChangeNotifier {
  // IMPORTANT: Update this with your actual backend server IP address
  // For Raspberry Pi on local network, use something like: 'http://192.168.x.x:5000'
  // For testing on emulator with localhost, use: 'http://10.0.2.2:5000' (Android)
  // For iOS simulator with localhost, use: 'http://127.0.0.1:5000'
  // Assuming the backend is served from /api/public based on the folder structure
  String _apiUrl = 'http://192.168.1.217/api/public';

  SensorData _data = SensorData.initial();
  SystemStatus _systemStatus = SystemStatus.initial();
  final Map<String, List<Map<String, dynamic>>> _historyData = {};
  List<Map<String, dynamic>> _fanHistory = [];
  Timer? _timer;
  bool _isConnected = false;
  String? _errorMessage;

  // Reference to SettingsProvider for calibration
  SettingsProvider? _settings;

  void updateSettings(SettingsProvider settings) {
    _settings = settings;
    notifyListeners();
  }

  SensorData get data {
    if (_settings == null) return _data;

    // Calculate soil moisture percentage based on calibration
    // Formula: (raw - dry) / (wet - dry) * 100
    // But usually dry > wet for capacitive sensors, so: (dry - raw) / (dry - wet) * 100
    // We clamp the result between 0 and 100
    double soilPercent = 0.0;
    if (_settings!.dryAdc != _settings!.wetAdc) {
      soilPercent =
          ((_settings!.dryAdc - _data.soilRaw) /
              (_settings!.dryAdc - _settings!.wetAdc)) *
          100;
      soilPercent = soilPercent.clamp(0.0, 100.0);
    }

    return _data.copyWith(soilMoisture: soilPercent);
  }

  // Get history for a specific sensor as a list of timestamped values
  List<Map<String, dynamic>> getHistory(String key) {
    // If requesting soil percent history, calculate it from soil_raw history
    if (key == 'soil_percent' && _settings != null) {
      final rawHistory = _historyData['soil_raw'] ?? [];

      return rawHistory.map((point) {
        final newPoint = Map<String, dynamic>.from(point);
        double rawValue = 0.0;

        // Extract raw value (it might be under 'soil_raw' or 'value')
        if (newPoint['soil_raw'] is num) {
          rawValue = (newPoint['soil_raw'] as num).toDouble();
        } else if (newPoint['value'] is num) {
          rawValue = (newPoint['value'] as num).toDouble();
        }

        // Calculate percentage
        double soilPercent = 0.0;
        if (_settings!.dryAdc != _settings!.wetAdc) {
          soilPercent =
              ((_settings!.dryAdc - rawValue) /
                  (_settings!.dryAdc - _settings!.wetAdc)) *
              100;
          soilPercent = soilPercent.clamp(0.0, 100.0);
        }

        // Return as 'soil_percent' for the chart
        newPoint['soil_percent'] = soilPercent;
        return newPoint;
      }).toList();
    }

    return _historyData[key] ?? [];
  }

  List<Map<String, dynamic>> get fanHistory => _fanHistory;

  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;
  String get apiUrl => _apiUrl;

  // Allow updating API URL (useful for configuration)
  void setApiUrl(String url) {
    _apiUrl = url;
    notifyListeners();
  }

  SystemStatus get systemStatus => _systemStatus;

  // Connect to the backend API
  void connect() {
    _isConnected = true;
    _errorMessage = null;
    notifyListeners();

    // Fetch data every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchRealData();
      _fetchSystemStatus();
      _fetchHistoryData();
      _fetchFanHistory();
    });

    // Fetch immediately on connect
    _fetchRealData();
    _fetchSystemStatus();
    _fetchHistoryData();
    _fetchFanHistory();
  }

  void disconnect() {
    _timer?.cancel();
    _isConnected = false;
    notifyListeners();
  }

  Future<void> _fetchSystemStatus() async {
    try {
      // Fetch status for each system
      final fanResp = await http.get(Uri.parse('$_apiUrl/v1/fan/status'));
      final curtainResp = await http.get(
        Uri.parse('$_apiUrl/v1/curtain/status'),
      );
      final pumpResp = await http.get(
        Uri.parse('$_apiUrl/v1/irrigation/status'),
      );
      final heaterResp = await http.get(Uri.parse('$_apiUrl/v1/heater/status'));
      final misterResp = await http.get(Uri.parse('$_apiUrl/v1/mister/status'));

      bool isFanOn = false;
      bool isCurtainOn = false;
      bool isPumpOn = false;
      bool isHeaterOn = false;
      bool isMisterOn = false;

      if (fanResp.statusCode == 200) {
        final data = json.decode(fanResp.body);
        isFanOn = data['status'] == 'ON';
      }
      if (curtainResp.statusCode == 200) {
        final data = json.decode(curtainResp.body);
        isCurtainOn = data['status'] == 'ON';
      }
      if (pumpResp.statusCode == 200) {
        final data = json.decode(pumpResp.body);
        isPumpOn = data['status'] == 'ON';
      }
      if (heaterResp.statusCode == 200) {
        final data = json.decode(heaterResp.body);
        isHeaterOn = data['status'] == 'ON';
      }
      if (misterResp.statusCode == 200) {
        final data = json.decode(misterResp.body);
        isMisterOn = data['status'] == 'ON';
      }

      _systemStatus = SystemStatus(
        isFanOn: isFanOn,
        isCurtainOn: isCurtainOn,
        isPumpOn: isPumpOn,
        isHeaterOn: isHeaterOn,
        isMisterOn: isMisterOn,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching system status: $e');
      }
    }
  }

  Future<void> _fetchRealData() async {
    final url = '$_apiUrl/v1/latest';
    try {
      if (kDebugMode) {
        print('Fetching data from: $url');
      }
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map<String, dynamic>) {
          _data = SensorData.fromJson(jsonData);
          _errorMessage = null;
        } else {
          _errorMessage = 'Invalid JSON format';
          if (kDebugMode) print('Invalid JSON: $jsonData');
        }
        notifyListeners();
      } else {
        _errorMessage = 'Server error: ${response.statusCode}';
        if (kDebugMode) {
          print('Server error (${response.statusCode}): ${response.body}');
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Connection failed: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching data from $url: $e');
      }
      notifyListeners();
    }
  }

  Future<void> _fetchHistoryData() async {
    // Fetch history for the last 1 hour (can be adjusted)
    // Note: We fetch 'soil_raw' instead of 'soil_percent' to calculate percentage locally
    // The backend handles key aliases (e.g. 'hum' -> 'humidity'), so we just request the standard keys.
    final sensorKeys = ['temp', 'humidity', 'co2', 'lux', 'soil_raw'];

    try {
      for (var key in sensorKeys) {
        final response = await http
            .get(Uri.parse('$_apiUrl/v1/history/$key?hours=1'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body) as List;
          _historyData[key] = List<Map<String, dynamic>>.from(jsonData);
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching history: $e');
      }
    }
  }

  Future<void> _fetchFanHistory() async {
    try {
      final response = await http
          .get(Uri.parse('$_apiUrl/v1/fan/history'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List;
        _fanHistory = List<Map<String, dynamic>>.from(jsonData);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching fan history: $e');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
