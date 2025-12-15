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
        final dynamic decodedData = json.decode(response.body);

        // Guard against receiving a List instead of a Map
        if (decodedData is! Map<String, dynamic>) {
          debugPrint('Error: Expected Map but got ${decodedData.runtimeType}');
          return;
        }

        final data = decodedData;
        _activeProfileName = data['active_profile'] ?? 'Default';

        if (data['profiles'] is Map<String, dynamic>) {
          final profilesMap = data['profiles'] as Map<String, dynamic>;
          _availableProfiles = profilesMap.keys.toList();

          // Update current setpoints based on active profile
          if (profilesMap.containsKey(_activeProfileName)) {
            // The profile map value might be the setpoints directly OR a wrapper
            final profileData = profilesMap[_activeProfileName];
            if (profileData is Map<String, dynamic>) {
              if (profileData.containsKey('setpoints')) {
                 _currentSetpoints = ClimateSetpoints.fromJson(profileData['setpoints']);
              } else {
                 // Assume it's the setpoints directly if no 'setpoints' key
                 _currentSetpoints = ClimateSetpoints.fromJson(profileData);
              }
            }
          }
        } else {
          // Handle case where profiles might be empty list or null
          _availableProfiles = ['Default'];
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
        
        // The API returns 'setpoints' directly in the response, but it might be the full profile object
        if (data['setpoints'] != null) {
          final responseData = data['setpoints'];
          if (responseData is Map<String, dynamic> && responseData.containsKey('setpoints')) {
             // It's the full profile object with nested setpoints
             _currentSetpoints = ClimateSetpoints.fromJson(responseData['setpoints']);
          } else {
             // It's likely the setpoints map directly
             _currentSetpoints = ClimateSetpoints.fromJson(responseData);
          }
        } else {
          // Fallback: try to find it in our local list if API didn't return it
          // This handles the case where we might have the data already
          await fetchProfiles(apiUrl);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error activating profile: $e');
    }
  }
}
