import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/greenhouse_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GreenhouseProvider>();
      context.read<SettingsProvider>().fetchProfiles(provider.apiUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiUrl = context.read<GreenhouseProvider>().apiUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Plant Profile'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value:
                                settings.availableProfiles.contains(
                                  settings.activeProfileName,
                                )
                                ? settings.activeProfileName
                                : null,
                            hint: const Text('Select Profile'),
                            items: settings.availableProfiles.map((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                settings.activateProfile(apiUrl, newValue);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Current Setpoints:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSetpointRow(
                        'Temp Range',
                        '${settings.currentSetpoints.tempMinC}°C - ${settings.currentSetpoints.tempMaxC}°C',
                      ),
                      _buildSetpointRow(
                        'VPD Target',
                        '${settings.currentSetpoints.vpdTargetLow} - ${settings.currentSetpoints.vpdTargetHigh} kPa',
                      ),
                      _buildSetpointRow(
                        'CO2 Limit',
                        '${settings.currentSetpoints.co2HighPpm} ppm',
                      ),
                      _buildSetpointRow(
                        'Light Max',
                        '${settings.currentSetpoints.lightMaxLux} lx',
                      ),
                      _buildSetpointRow(
                        'Soil Min',
                        '${settings.currentSetpoints.soilMinPercent}%',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Language'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('App Language'),
                  trailing: DropdownButton<Locale>(
                    value: settings.locale,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: Locale('en'),
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: Locale('zh'),
                        child: Text('Chinese'),
                      ),
                    ],
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        settings.setLocale(newLocale);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Soil Sensor Calibration'),
              const Text(
                'Calibrate the soil moisture sensor by setting the raw ADC values for dry (air) and wet (water) conditions.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildCalibrationCard(
                'Dry ADC Value (Air)',
                '',
                settings.dryAdc,
                (val) => settings.setSoilCalibration(val, settings.wetAdc),
                onEnd: (_) => settings.saveSoilCalibration(apiUrl),
                min: (settings.wetAdc + 50).clamp(0.0, 4095.0),
                max: 4095,
                divisions: 4095,
              ),
              _buildCalibrationCard(
                'Wet ADC Value (Water)',
                '',
                settings.wetAdc,
                (val) => settings.setSoilCalibration(settings.dryAdc, val),
                onEnd: (_) => settings.saveSoilCalibration(apiUrl),
                min: 0,
                max: (settings.dryAdc - 50).clamp(0.0, 4095.0),
                divisions: 4095,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSetpointRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildCalibrationCard(
    String title,
    String unit,
    double value,
    Function(double) onChanged, {
    Function(double)? onEnd,
    double min = -10.0,
    double max = 10.0,
    int? divisions,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${value > 0 ? '+' : ''}${value.toStringAsFixed(0)} $unit',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions:
                  divisions ?? ((max - min) * 2).toInt(), // 0.5 steps default
              label: value.toStringAsFixed(0),
              activeColor: Colors.green,
              onChanged: onChanged,
              onChangeEnd: onEnd,
            ),
          ],
        ),
      ),
    );
  }
}
