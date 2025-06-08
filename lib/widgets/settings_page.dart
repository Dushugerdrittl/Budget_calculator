import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:shared_preferences/shared_preferences.dart'; // Though not directly used in this diff, it's good practice if settings persist

class SettingsPage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final Function(BuildContext) onClearAllData; // Changed to accept BuildContext
  final VoidCallback onExportData;
  final VoidCallback onImportData;
  final String defaultCurrencySymbol;
  final ValueChanged<String> onDefaultCurrencyChanged;

  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onClearAllData,
    required this.onExportData,
    required this.onImportData,
    required this.defaultCurrencySymbol,
    required this.onDefaultCurrencyChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Duplicating for simplicity, ideally this comes from a shared source
  // or is passed in if it can change dynamically elsewhere.
  final Map<String, String> _currencySymbols = const {
    'Dollars': '\$',
    'Rupees': '₹',
    'Yen': '¥',
    'Euros': '€',
  };

  late String _selectedCurrencySymbol;

  @override
  void initState() {
    super.initState();
    _selectedCurrencySymbol = widget.defaultCurrencySymbol;
  }

  Future<void> _signOut() async {
    print("[SettingsPage] Attempting to sign out...");
    try {
      await FirebaseAuth.instance.signOut();
      print("[SettingsPage] Sign out successful from FirebaseAuth.");
      // After signing out, the StreamBuilder in main.dart should automatically
      // navigate the user to the LoginScreen.
      // No explicit navigation needed here if AppRoot is set up correctly.
    } catch (e) {
      print("[SettingsPage] Error during sign out: $e");
      if (mounted) {
        // Check if the widget is still in the tree
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.brightness_auto,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('System Default'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: widget.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) widget.onThemeChanged(value);
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              onTap: () => widget.onThemeChanged(ThemeMode.system),
            ),
            ListTile(
              leading: Icon(
                Icons.wb_sunny,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Light Mode'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: widget.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) widget.onThemeChanged(value);
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              onTap: () => widget.onThemeChanged(ThemeMode.light),
            ),
            ListTile(
              leading: Icon(
                Icons.brightness_2,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Dark Mode'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: widget.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) widget.onThemeChanged(value);
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              onTap: () => widget.onThemeChanged(ThemeMode.dark),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Preferences',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.attach_money,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Default Currency'),
              trailing: DropdownButton<String>(
                value: _selectedCurrencySymbol, // Use state variable
                underline: Container(), // Remove underline
                items:
                    _currencySymbols.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.value,
                        child: Text('${entry.key} (${entry.value})'),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      // Update local state for the dropdown
                      _selectedCurrencySymbol = newValue;
                    });
                    widget.onDefaultCurrencyChanged(newValue); // Call callback
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.download_for_offline_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Export Data (CSV)'),
              subtitle: const Text('Share your expenses and subscriptions.'),
              onTap: widget.onExportData,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.upload_file_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Import Data (CSV)'),
              subtitle: const Text(
                'Load expenses and subscriptions from a CSV file.',
              ),
              onTap: widget.onImportData,
            ),
            const Divider(),

            // You can add more settings sections here
            // Example:
            // Padding(
            //   padding: const EdgeInsets.symmetric(vertical: 8.0),
            //   child: Text('Notifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
            // ),
            // SwitchListTile(
            //   title: const Text('Enable Notifications'),
            //   value: true, // Replace with actual state
            //   onChanged: (bool value) {
            //     // Handle change
            //   },
            //   secondary: Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.secondary),
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Data Management',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Card(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withOpacity(0.3),
              elevation: 0, // Optional: remove card shadow for a flatter look
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Clear All Data',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => widget.onClearAllData(context),
              ),
            ),
            const Divider(),
            const SizedBox(height: 20), // Spacing before the button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
              ),
              onPressed: _signOut,
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 20), // Spacing after the button
          ],
        ),
      ),
    );
  }
}
