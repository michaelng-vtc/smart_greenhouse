import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/greenhouse_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';

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
      final settings = context.read<SettingsProvider>();
      // Ensure we have a valid API URL before fetching
      if (provider.apiUrl.isNotEmpty) {
        settings.fetchProfiles(provider.apiUrl);
        settings.fetchSoilCalibration(provider.apiUrl);
      }
    });
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    final l10n = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.changePassword),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  decoration: InputDecoration(labelText: l10n.oldPassword),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? l10n.required : null,
                ),
                TextFormField(
                  controller: newPasswordController,
                  decoration: InputDecoration(labelText: l10n.newPassword),
                  obscureText: true,
                  validator: (value) =>
                      value!.length < 6 ? l10n.min6Chars : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        final success = await context
                            .read<AuthProvider>()
                            .changePassword(
                              oldPasswordController.text,
                              newPasswordController.text,
                            );

                        if (!context.mounted) return;

                        setState(() => isLoading = false);
                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.passwordChanged),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.read<AuthProvider>().errorMessage ??
                                    l10n.failed,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeUsernameDialog() async {
    final newUsernameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    final l10n = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.changeUsername),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: newUsernameController,
              decoration: InputDecoration(labelText: l10n.newUsername),
              validator: (value) => value!.isEmpty ? l10n.required : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        final success = await context
                            .read<AuthProvider>()
                            .changeUsername(newUsernameController.text);

                        if (!context.mounted) return;

                        setState(() => isLoading = false);
                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.usernameChanged),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.read<AuthProvider>().errorMessage ??
                                    l10n.failed,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiUrl = context.read<GreenhouseProvider>().apiUrl;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(l10n.userProfile),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(l10n.changeUsername),
                      subtitle: Text(
                        context.watch<AuthProvider>().username ?? '',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showChangeUsernameDialog,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: Text(l10n.changePassword),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.plantProfile),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.activeProfile,
                        style: const TextStyle(
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
                            hint: Text(l10n.selectProfile),
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
                      Text(
                        l10n.currentSetpoints,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSetpointRow(
                        l10n.tempRange,
                        '${settings.currentSetpoints.tempMinC}°C - ${settings.currentSetpoints.tempMaxC}°C',
                      ),
                      _buildSetpointRow(
                        l10n.vpdTarget,
                        '${settings.currentSetpoints.vpdTargetLow} - ${settings.currentSetpoints.vpdTargetHigh} kPa',
                      ),
                      _buildSetpointRow(
                        l10n.co2Limit,
                        '${settings.currentSetpoints.co2HighPpm} ppm',
                      ),
                      _buildSetpointRow(
                        l10n.lightMax,
                        '${settings.currentSetpoints.lightMaxLux} lx',
                      ),
                      _buildSetpointRow(
                        l10n.soilMin,
                        '${settings.currentSetpoints.soilMinPercent}%',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.language),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.appLanguage),
                  trailing: DropdownButton<Locale>(
                    value: settings.locale,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: const Locale('en'),
                        child: Text(l10n.english),
                      ),
                      DropdownMenuItem(
                        value: const Locale('zh'),
                        child: Text(l10n.chinese),
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
              _buildSectionHeader(l10n.soilSensorCalibration),
              Text(
                l10n.calibrationDesc,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildCalibrationCard(
                l10n.dryValue,
                '',
                settings.dryAdc,
                (val) => settings.setSoilCalibration(val, settings.wetAdc),
                onEnd: (_) => settings.saveSoilCalibration(apiUrl),
                min: (settings.wetAdc + 50).clamp(0.0, 4095.0),
                max: 4095,
                divisions: 4095,
              ),
              _buildCalibrationCard(
                l10n.wetValue,
                '',
                settings.wetAdc,
                (val) => settings.setSoilCalibration(settings.dryAdc, val),
                onEnd: (_) => settings.saveSoilCalibration(apiUrl),
                min: 0,
                max: (settings.dryAdc - 50).clamp(0.0, 4095.0),
                divisions: 4095,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
