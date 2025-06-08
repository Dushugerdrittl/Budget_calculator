import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/entries.dart' as models;
import 'widgets/budget_home_page.dart';
// import 'widgets/notebook_page.dart'; // This line should be removed or remain commented out
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/settings_page.dart'; // Import the new settings page
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // For File operations
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data'; // For Uint8List
import 'package:file_picker/file_picker.dart';
import 'web_export_helper.dart'
    if (dart.library.html) 'web_export_helper.dart'
    if (dart.library.io) 'mobile_export_helper.dart';

const String _themeModePrefsKey =
    'themeModeIndex'; // Use a constant for the key
const String _defaultCurrencyKey = 'defaultCurrencySymbol';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(models.ExpenseEntryAdapter());
  Hive.registerAdapter(models.SubscriptionEntryAdapter());

  await Hive.openBox<models.ExpenseEntry>('expenses');
  await Hive.openBox<models.SubscriptionEntry>('subscriptions');

  // Load the saved theme mode before running the app
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? themeModeIndex = prefs.getInt(_themeModePrefsKey);
  String? defaultCurrency = prefs.getString(_defaultCurrencyKey);
  runApp(
    MyApp(
      savedThemeModeIndex: themeModeIndex,
      savedDefaultCurrency: defaultCurrency,
    ),
  );
}

class MyApp extends StatefulWidget {
  // Add a constructor to accept the saved theme mode
  final int? savedThemeModeIndex;
  final String? savedDefaultCurrency;

  const MyApp({super.key, this.savedThemeModeIndex, this.savedDefaultCurrency});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  late ThemeMode _themeMode;
  bool _isLoadingTheme = true; // Add a loading state
  Key _budgetHomePageKey = UniqueKey(); // Key to refresh BudgetHomePage
  // Initialize with a sensible default to avoid LateInitializationError,
  // it will be updated by _loadInitialSettings.
  String _currentDefaultCurrency = '\$';

  @override
  void initState() {
    super.initState();
    _loadInitialSettings();
  }

  void _loadInitialSettings() {
    // Load Theme
    ThemeMode initialThemeMode = ThemeMode.system; // Default
    if (widget.savedThemeModeIndex != null) {
      // Ensure the index is valid
      if (widget.savedThemeModeIndex! >= 0 &&
          widget.savedThemeModeIndex! < ThemeMode.values.length) {
        initialThemeMode = ThemeMode.values[widget.savedThemeModeIndex!];
      }
    }
    _themeMode = initialThemeMode;

    // Load Default Currency
    // _currentDefaultCurrency already has a default.
    // Update it with the saved value if available, otherwise keep the default.
    _currentDefaultCurrency =
        widget.savedDefaultCurrency ?? _currentDefaultCurrency;

    // All settings loaded, update UI to remove loading indicator
    if (mounted) {
      setState(() {
        _isLoadingTheme = false; // Set loading to false once theme is loaded
      });
    }
  }

  Future<void> _changeTheme(ThemeMode themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModePrefsKey, themeMode.index);
    setState(() {
      _themeMode = themeMode;
    });
  }

  Future<void> _setDefaultCurrency(String currencySymbol) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultCurrencyKey, currencySymbol);
    setState(() {
      _currentDefaultCurrency = currencySymbol;
      _budgetHomePageKey =
          UniqueKey(); // Refresh budget page to reflect new default
    });
  }

  Future<void> _handleClearAllData(BuildContext contextForDialog) async {
    final bool? confirmed = await showDialog<bool>(
      context: contextForDialog, // Use the context passed from SettingsPage
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Clear Data'),
          content: const Text(
            'Are you sure you want to delete all expenses and subscriptions? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear Data'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await Hive.box<models.ExpenseEntry>('expenses').clear();
      await Hive.box<models.SubscriptionEntry>('subscriptions').clear();
      // Optionally, show a SnackBar or navigate away
      if (mounted && contextForDialog.mounted) {
        ScaffoldMessenger.of(
          contextForDialog, // Use the context passed from SettingsPage for SnackBar
        ).showSnackBar(const SnackBar(content: Text('All data cleared.')));
        // If BudgetHomePage needs an explicit refresh, you'd handle it here
        // For now, data will be empty next time BudgetHomePage loads its data.
      }
    }
  }

  Future<void> _handleExportData(BuildContext contextForSnackbar) async {
    List<models.ExpenseEntry> expenses =
        Hive.box<models.ExpenseEntry>('expenses').values.toList();
    List<models.SubscriptionEntry> subscriptions =
        Hive.box<models.SubscriptionEntry>('subscriptions').values.toList();

    List<List<dynamic>> rows = [];

    // Add headers
    rows.add(['Type', 'Name/Description', 'Amount', 'Date']);

    // Add expense data
    for (var expense in expenses) {
      rows.add([
        'Expense',
        'Expense',
        expense.amount,
        expense.date.toIso8601String(),
      ]);
    }

    // Add subscription data
    for (var sub in subscriptions) {
      rows.add([
        'Subscription',
        sub.name,
        sub.amount,
        sub.date.toIso8601String(),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    try {
      final String fileName =
          'budget_data_${DateTime.now().toIso8601String().split('T').first}.csv';

      if (kIsWeb) {
        downloadFileOnWeb(csvData, fileName);
      } else {
        // For mobile, use share_plus
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsString(csvData);
        Share.shareXFiles([XFile(path)], text: 'My Budget Data');
      }
    } catch (e) {
      if (contextForSnackbar.mounted) {
        ScaffoldMessenger.of(
          contextForSnackbar,
        ).showSnackBar(SnackBar(content: Text('Error exporting data: $e')));
      }
    }
  }

  Future<void> _handleImportData(BuildContext contextForFeedback) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.single;
        String csvString;

        if (kIsWeb) {
          // For web, read bytes and decode
          final Uint8List? fileBytes = platformFile.bytes;
          if (fileBytes == null) {
            throw Exception("Failed to load file bytes on web.");
          }
          csvString = String.fromCharCodes(fileBytes);
        } else {
          // For mobile, read from path
          final String? filePath = platformFile.path;
          if (filePath == null) {
            // This case should ideally not happen if result.files.isNotEmpty is true for non-web
            throw Exception("File path is null for non-web platform.");
          }
          final file = File(filePath);
          csvString = await file.readAsString();
        }

        List<List<dynamic>> csvTable = const CsvToListConverter().convert(
          csvString,
        );

        int importedExpenses = 0;
        int importedSubscriptions = 0;

        // Skip header row if present (optional, adjust as needed)
        for (var i = 1; i < csvTable.length; i++) {
          var row = csvTable[i];
          if (row.length < 4) continue; // Basic validation

          String type = row[0].toString();
          String nameOrDesc = row[1].toString();
          double? amount = double.tryParse(row[2].toString());
          DateTime? date = DateTime.tryParse(row[3].toString());

          if (amount == null || date == null) continue;

          if (type.toLowerCase() == 'expense') {
            Hive.box<models.ExpenseEntry>(
              'expenses',
            ).add(models.ExpenseEntry(amount: amount, date: date));
            importedExpenses++;
          } else if (type.toLowerCase() == 'subscription') {
            Hive.box<models.SubscriptionEntry>('subscriptions').add(
              models.SubscriptionEntry(
                name: nameOrDesc,
                amount: amount,
                date: date,
              ),
            );
            importedSubscriptions++;
          }
        }
        // Refresh BudgetHomePage by changing its key
        setState(() {
          _budgetHomePageKey = UniqueKey();
        });
        if (contextForFeedback.mounted) {
          ScaffoldMessenger.of(contextForFeedback).showSnackBar(
            SnackBar(
              content: Text(
                'Imported $importedExpenses expenses and $importedSubscriptions subscriptions.',
              ),
            ),
          );
        }
      } else {
        // User canceled the picker
        if (contextForFeedback.mounted) {
          ScaffoldMessenger.of(contextForFeedback).showSnackBar(
            const SnackBar(
              content: Text('File import canceled or no file selected.'),
            ),
          );
        }
      }
    } catch (e) {
      if (contextForFeedback.mounted) {
        ScaffoldMessenger.of(
          contextForFeedback,
        ).showSnackBar(SnackBar(content: Text('Error importing data: $e')));
      }
    }
  }

  List<Widget> _buildPages() {
    return <Widget>[
      BudgetHomePage(
        key: _budgetHomePageKey, // Assign the key here
        initialCurrencySymbol: _currentDefaultCurrency,
        title: 'Hello Kitty Budget Calculator',
      ),
      SettingsPage(
        themeMode: _themeMode,
        onThemeChanged: _changeTheme,
        onClearAllData: _handleClearAllData, // Pass the method reference
        onExportData:
            () => _handleExportData(
              context,
            ), // Pass context for potential Snackbars
        onImportData:
            () => _handleImportData(context), // Pass context for feedback
        defaultCurrencySymbol: _currentDefaultCurrency,
        onDefaultCurrencyChanged: _setDefaultCurrency,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTheme) {
      // Show a loading indicator while the theme is being loaded
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'Hello Kitty Budget App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: Scaffold(
        body: _buildPages()[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.pinkAccent,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
