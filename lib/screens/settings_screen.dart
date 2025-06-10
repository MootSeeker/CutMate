import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:cutmate/services/settings_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Screen for displaying and updating app settings
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }
  
  /// Load app version information
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _appVersion = AppConstants.appVersion;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                final settings = settingsProvider.settings;
                
                return ListView(
                  children: [                    // Appearance section
                    _buildSectionHeader('Appearance'),
                    ListTile(
                      title: const Text('Theme'),
                      subtitle: Text('Control the app appearance'),
                      trailing: DropdownButton<String>(
                        value: settings.themeMode,
                        onChanged: (value) {
                          if (value != null) {
                            settingsProvider.setThemeMode(value);
                          }
                        },                        items: const [
                          DropdownMenuItem(value: 'system', child: Text('System Default')),
                          DropdownMenuItem(value: 'light', child: Text('Light')),
                          DropdownMenuItem(value: 'dark', child: Text('Dark')),
                        ],
                      ),
                    ),
                    
                    const Divider(),
                    
                    // Units section
                    _buildSectionHeader('Units'),
                    ListTile(
                      title: const Text('Weight Unit'),
                      subtitle: Text('Current: ${settings.weightUnit}'),
                      trailing: DropdownButton<String>(
                        value: settings.weightUnit,
                        onChanged: (value) {
                          if (value != null) {
                            settingsProvider.setWeightUnit(value);
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('Kilograms (kg)')),
                          DropdownMenuItem(value: 'lbs', child: Text('Pounds (lbs)')),
                        ],
                      ),
                    ),
                    
                    const Divider(),
                    
                    // Chart settings section
                    _buildSectionHeader('Chart Settings'),
                    SwitchListTile(
                      title: const Text('Weight Change Indicators'),
                      subtitle: const Text('Show indicators for weight changes'),
                      value: settings.showWeightChangeIndicators,
                      onChanged: (value) => 
                          settingsProvider.setShowWeightChangeIndicators(value),
                    ),
                    ListTile(
                      title: const Text('Default Chart Period'),
                      subtitle: Text('${settings.defaultChartPeriod} days'),
                      trailing: DropdownButton<int>(
                        value: settings.defaultChartPeriod,
                        onChanged: (value) {
                          if (value != null) {
                            settingsProvider.setDefaultChartPeriod(value);
                          }
                        },
                        items: AppConstants.chartTimePeriods.map((days) {
                          return DropdownMenuItem(
                            value: days,
                            child: Text('$days days'),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const Divider(),
                    
                    // Notifications section
                    _buildSectionHeader('Notifications'),
                    SwitchListTile(
                      title: const Text('Weekly Reminders'),
                      subtitle: const Text('Remind me to log my weight'),
                      value: settings.enableWeeklyReminders,
                      onChanged: (value) => 
                          settingsProvider.setEnableWeeklyReminders(value),
                    ),
                    
                    const Divider(),
                    
                    // About section
                    _buildSectionHeader('About'),
                    ListTile(
                      title: const Text('Version'),
                      subtitle: Text(_appVersion),
                      trailing: const Icon(Icons.info_outline),
                      onTap: _showAboutDialog,
                    ),
                  ],
                );
              },
            ),
    );
  }
  
  /// Build a section header with the given title
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  /// Show the about dialog
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: _appVersion,
      applicationLegalese: '© 2025',
      children: [
        const SizedBox(height: 16),
        const Text(AppConstants.appTagline),
      ],
    );
  }
}
