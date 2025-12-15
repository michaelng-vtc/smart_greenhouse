import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/plant_profile.dart';

class SettingsProvider with ChangeNotifier {
  Locale _locale = const Locale('en');

  // Soil Sensor Calibration
  double _dryAdc = 3000.0; // Default dry value (air)
  double _wetAdc = 1200.0; // Default wet value (water)

  // Plant Profiles
  List<String> _availableProfiles = ['Default'];
  String _activeProfileName = 'Default';
  ClimateSetpoints _currentSetpoints = ClimateSetpoints();

  Locale get locale => _locale;
  double get dryAdc => _dryAdc;
  double get wetAdc => _wetAdc;

  List<String> get availableProfiles => _availableProfiles;
  String get activeProfileName => _activeProfileName;
  ClimateSetpoints get currentSetpoints => _currentSetpoints;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void setSoilCalibration(double dry, double wet) {
    _dryAdc = dry;
    _wetAdc = wet;
    notifyListeners();
  }

  Future<void> fetchSoilCalibration(String apiUrl) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/v1/config/soil'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['dry_adc'] != null && data['wet_adc'] != null) {
          _dryAdc = (data['dry_adc'] as num).toDouble();
          _wetAdc = (data['wet_adc'] as num).toDouble();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching calibration: $e');
    }
  }

  Future<void> saveSoilCalibration(String apiUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/v1/config/soil'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'dry_adc': _dryAdc.round(),
          'wet_adc': _wetAdc.round(),
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to save calibration: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error saving calibration: $e');
    }
  }

  Future<void> fetchProfiles(String apiUrl) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/v1/profiles'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _activeProfileName = data['active_profile'] ?? 'Default';

        final profilesMap = data['profiles'] as Map<String, dynamic>;
        _availableProfiles = profilesMap.keys.toList();

        // Update current setpoints based on active profile
        if (profilesMap.containsKey(_activeProfileName)) {
          _currentSetpoints = ClimateSetpoints.fromJson(
            profilesMap[_activeProfileName],
          );
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
    }
  }

  Future<void> activateProfile(String apiUrl, String profileName) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/v1/profiles/activate/$profileName'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _activeProfileName = profileName;
        if (data['setpoints'] != null) {
          _currentSetpoints = ClimateSetpoints.fromJson(data['setpoints']);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error activating profile: $e');
    }
  }
}
