import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Keyboard Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Haptic Feedback"),
            subtitle: const Text("Vibrate when keys are pressed"),
            value: settings.isVibrationEnabled,
            onChanged: (val) => settings.toggleVibration(val),
          ),
           const Divider(),
           ListTile(
            title: const Text("Translation Languages"),
            subtitle: Text(settings.selectedLanguages.join(", ")),
            leading: const Icon(Icons.translate),
            onTap: () => _showLanguageDialog(context, settings),
           ),
           const Divider(),
           ListTile(
            title: const Text("Enable Keyboard"),
            subtitle: const Text("Go to settings to enable the keyboard"),
            leading: const Icon(Icons.keyboard),
            onTap: () {
               // In a real app, this would open system settings
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please go to Android Settings > System > Keyboard to enable.")));
            },
           ),
           ListTile(
             title: const Text("About"),
             subtitle: const Text("AI Keyboard Assistant v1.0"),
             leading: const Icon(Icons.info_outline),
           ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(settings.selectedLanguages);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Translation Languages"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: SettingsProvider.availableLanguages.map((lang) {
                    final isSelected = tempSelected.contains(lang);
                    return CheckboxListTile(
                      title: Text(lang),
                      value: isSelected,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            tempSelected.add(lang);
                          } else {
                            if (tempSelected.length > 1) {
                              tempSelected.remove(lang);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    settings.setSelectedLanguages(tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
