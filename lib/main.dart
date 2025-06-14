// Copyright (c) 2024 Master Nithin sai koushik kancharla. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found in the LICENSE file.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/entries.dart' as models;
import 'models/category.dart'; // Import the Category model
import 'models/saving_goal.dart'; // Import the SavingGoal model
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
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'firebase_options.dart'; // Import the generated Firebase options
import 'login_screen.dart'; // Import the LoginScreen - THIS LINE IS ALREADY PRESENT, NO CHANGE NEEDED
import 'package:animations/animations.dart'; // Import the animations package
import 'widgets/welcome_animation_screen.dart'; // Import the new welcome screen
import 'services/notification_service.dart'; // Import NotificationService

const String _themeModePrefsKey =
    'themeModeIndex'; // Use a constant for the key
const String _defaultCurrencyKey = 'defaultCurrencySymbol';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  Hive.registerAdapter(models.ExpenseEntryAdapter());
  Hive.registerAdapter(models.SubscriptionEntryAdapter());
  Hive.registerAdapter(CategoryAdapter()); // Register the new adapter
  Hive.registerAdapter(SavingGoalAdapter()); // Register the SavingGoal adapter

  // Initialize NotificationService
  await NotificationService().init();

  // We will open user-specific boxes after login, so remove global box opening here.
  // await Hive.openBox<models.ExpenseEntry>('expenses');
  // await Hive.openBox<models.SubscriptionEntry>('subscriptions');

  // Load the saved theme mode before running the app
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? themeModeIndex = prefs.getInt(_themeModePrefsKey);
  String? defaultCurrency = prefs.getString(_defaultCurrencyKey);
  runApp(
    AppRoot(
      // Changed MyApp to AppRoot to contain the AuthWrapper
      savedThemeModeIndex: themeModeIndex,
      savedDefaultCurrency: defaultCurrency,
    ),
  );
}

class AppRoot extends StatefulWidget {
  final int? savedThemeModeIndex;
  final String? savedDefaultCurrency;

  const AppRoot({
    super.key,
    this.savedThemeModeIndex,
    this.savedDefaultCurrency,
  });

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late ThemeMode _currentThemeMode;
  bool _showWelcomeAnimation = false;
  User? _currentUserForWelcome;

  @override
  void initState() {
    super.initState();
    _currentThemeMode =
        ThemeMode.values[widget.savedThemeModeIndex ?? ThemeMode.system.index];
  }

  Future<void> _handleThemeChanged(ThemeMode themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModePrefsKey, themeMode.index);
    setState(() {
      _currentThemeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // AppRoot now returns the single top-level MaterialApp
    return MaterialApp(
      title: 'Hello Kitty Budget App', // You can keep a consistent title
      themeMode: _currentThemeMode, // Use state variable for themeMode
      theme: ThemeData(
        fontFamily: 'Comic Sans MS', // Applying a playful font globally
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFFF8BBD0,
          ), // A light, soft pink (Material Pink 100)
          brightness: Brightness.light,
          primary: const Color(
            0xFFE91E63,
          ), // A more vibrant pink for primary elements
          secondary: const Color(
            0xFFF06292,
          ), // A complementary pink for secondary elements
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Comic Sans MS', // Applying a playful font globally
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFFF8BBD0,
          ), // Same seed for dark theme consistency
          brightness: Brightness.dark,
          primary: const Color(
            0xFFF48FB1,
          ), // Lighter pink for primary in dark mode
          secondary: const Color(
            0xFFF8BBD0,
          ), // Even lighter for secondary in dark mode
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          print(
            "[AppRoot] Auth StreamBuilder rebuilt. ConnectionState: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, HasError: ${snapshot.hasError}, Error: ${snapshot.error}, User: ${snapshot.data}",
          );
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ); // Content for the MaterialApp's home
          }
          if (snapshot.hasData) {
            _currentUserForWelcome = snapshot.data!;
            if (_showWelcomeAnimation && _currentUserForWelcome != null) {
              return WelcomeAnimationScreen(
                userName:
                    _currentUserForWelcome!.displayName ??
                    _currentUserForWelcome!.email ??
                    "Friend",
                onAnimationComplete: () {
                  if (mounted) {
                    setState(() {
                      _showWelcomeAnimation = false;
                    });
                  }
                },
              );
            } else {
              // User is logged in, show the main app content
              return MyApp(
                currentUser: _currentUserForWelcome!,
                currentThemeMode: _currentThemeMode,
                onThemeChanged: _handleThemeChanged,
                savedDefaultCurrency: widget.savedDefaultCurrency,
              );
            }
          }
          // User is not logged in, show the LoginScreen
          _currentUserForWelcome = null; // Clear user
          return LoginScreen(
            onSuccessfulLogin: (User user) {
              if (mounted) {
                setState(() {
                  _currentUserForWelcome = user;
                  _showWelcomeAnimation = true;
                });
              }
            },
          );
        },
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final String? savedDefaultCurrency;
  final User currentUser; // Add a field for the current user
  final ThemeMode currentThemeMode; // Receive current theme
  final ValueChanged<ThemeMode> onThemeChanged; // Receive theme change handler

  const MyApp({
    super.key,
    required this.currentUser, // Make currentUser required
    required this.currentThemeMode,
    required this.onThemeChanged,
    this.savedDefaultCurrency,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  // bool _isLoadingTheme = true; // Theme loading is now handled by AppRoot
  Key _budgetHomePageKey = UniqueKey(); // Key to refresh BudgetHomePage
  // Initialize with a sensible default to avoid LateInitializationError,
  // it will be updated by _loadInitialSettings.
  String _currentDefaultCurrency = '\$';
  // We will open user-specific boxes later in initState
  late List<Widget> _pages; // For IndexedStack

  bool _hiveBoxesOpened = false; // To track if boxes are opened

  @override
  void initState() {
    super.initState();
    print("[MyApp] initState called for user: ${widget.currentUser.uid}");
    _initializeAsyncData();
    _pages = _generatePageList(); // Initialize pages here
  }

  void _loadInitialSettings() {
    // Load Default Currency
    // _currentDefaultCurrency already has a default.
    // Update it with the saved value if available, otherwise keep the default.
    _currentDefaultCurrency =
        widget.savedDefaultCurrency ?? _currentDefaultCurrency;

    // Theme is now managed by AppRoot, so no need to set _isLoadingTheme here
    // related to theme. We still need to wait for Hive boxes.
  }

  Future<void> _initializeAsyncData() async {
    _loadInitialSettings(); // Load theme and currency first
    await _openUserSpecificHiveBoxes(); // Then open Hive boxes
    if (mounted) {
      setState(() {
        _hiveBoxesOpened = true; // Mark boxes as opened
        // Re-generate pages if their dependencies might have changed after async init
        _pages = _generatePageList();
      });
    }
  }

  Future<void> _openUserSpecificHiveBoxes() async {
    final userId = widget.currentUser.uid;
    print("[MyApp] Opening Hive boxes for user: $userId");
    await Hive.openBox<models.ExpenseEntry>('expenses_$userId');
    await Hive.openBox<models.SubscriptionEntry>('subscriptions_$userId');
    await Hive.openBox<Category>(
      'categories_$userId',
    ); // Open category box for the user
    print("[MyApp] Hive boxes opened for user: $userId");
    // Trigger a rebuild of BudgetHomePage if necessary, e.g., by updating its key
    // or ensuring BudgetHomePage re-reads from the new boxes.
    _budgetHomePageKey = UniqueKey();
    // Update the _pages list as the key for BudgetHomePage has changed
    if (mounted) setState(() => _pages = _generatePageList());
    _scheduleSubscriptionReminders(); // Add this call
  }

  Future<void> _setDefaultCurrency(String currencySymbol) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultCurrencyKey, currencySymbol);
    setState(() {
      _currentDefaultCurrency = currencySymbol;
      _budgetHomePageKey =
          UniqueKey(); // Refresh budget page to reflect new default
      // Update the _pages list as the currency for BudgetHomePage and SettingsPage has changed
      _pages = _generatePageList();
    });
  }

  Future<void> _scheduleSubscriptionReminders() async {
    final userId = widget.currentUser.uid;
    final subscriptionBox = Hive.box<models.SubscriptionEntry>(
      'subscriptions_$userId',
    );
    final notificationService = NotificationService();

    for (var entry in subscriptionBox.values) {
      if (entry.firestoreId == null) continue; // Should have a firestoreId

      // Only proceed if reminders are enabled for this subscription
      if (entry.enableReminder != true) {
        // Treat null as false
        continue;
      }

      // Reminder a day before the due date at 9 AM
      DateTime baseDueDate =
          entry.nextDueDate ??
          entry.date; // Use entry.date if nextDueDate is somehow null
      DateTime reminderDateTime = baseDueDate.subtract(const Duration(days: 1));
      reminderDateTime = DateTime(
        reminderDateTime.year,
        reminderDateTime.month,
        reminderDateTime.day,
        9,
        0,
        0,
      );

      // Check if the reminder date is in the future and not already scheduled
      if (reminderDateTime.isAfter(DateTime.now()) &&
          !(entry.reminderScheduled ?? false)) {
        // Use a unique ID for each notification.
        // We can derive it from the subscription's Firestore ID.
        // Firestore IDs are strings, notifications need int IDs.
        // A simple hash or a more robust mapping might be needed if IDs clash.
        // For now, let's use the hash code of the firestoreId.
        final notificationId = entry.firestoreId.hashCode;

        await notificationService.scheduleNotification(
          id: notificationId,
          title: 'Subscription Due Soon: ${entry.name}',
          body:
              '${entry.name} for \$${entry.amount.toStringAsFixed(2)} is due tomorrow!',
          scheduledDateTime: reminderDateTime,
          payload: 'subscription_${entry.firestoreId}', // Optional payload
        );

        // Mark as scheduled in Hive and update Firestore
        entry.reminderScheduled = true;
        await entry.save(); // Save to Hive
        await FirebaseFirestore
            .instance // This line should work if cloud_firestore is imported.
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .doc(entry.firestoreId)
            .update({
              'reminderScheduled': true,
              'enableReminder': entry.enableReminder,
            }); // Also save enableReminder status
      }
    }
  }

  Future<void> _handleClearAllData(BuildContext contextForDialog) async {
    final bool? confirmed = await showDialog<bool>(
      context: contextForDialog, // Use the context passed from SettingsPage
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Confirm Clear Data',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
          content: const Text(
            'Are you sure you want to delete all your expenses and subscriptions?\n\nThis action cannot be undone.',
            style: TextStyle(fontSize: 16.0),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          actionsPadding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
              child: const Text('Yes, Clear Data'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final userId = widget.currentUser.uid;
      await Hive.box<models.ExpenseEntry>('expenses_$userId').clear();
      await Hive.box<models.SubscriptionEntry>('subscriptions_$userId').clear();
      _budgetHomePageKey = UniqueKey(); // Refresh UI
      // Optionally, show a SnackBar or navigate away
      if (mounted && contextForDialog.mounted) {
        ScaffoldMessenger.of(
          contextForDialog, // Use the context passed from SettingsPage for SnackBar
        ).showSnackBar(const SnackBar(content: Text('All data cleared.')));
        // If BudgetHomePage needs an explicit refresh, you'd handle it here
        // For now, data will be empty next time BudgetHomePage loads its data.
        setState(() {
          // Ensure UI rebuilds to reflect cleared data
          _budgetHomePageKey = UniqueKey();
          // Update the _pages list as the key for BudgetHomePage has changed
          _pages = _generatePageList();
        });
      }
    }
  }

  Future<void> _handleExportData(BuildContext contextForSnackbar) async {
    List<models.ExpenseEntry> expenses =
        Hive.box<models.ExpenseEntry>('expenses').values.toList();
    final userId = widget.currentUser.uid;
    List<models.ExpenseEntry> userExpenses =
        Hive.box<models.ExpenseEntry>('expenses_$userId').values.toList();
    List<models.SubscriptionEntry> subscriptions =
        Hive.box<models.SubscriptionEntry>(
          'subscriptions_$userId',
        ).values.toList();
    List<List<dynamic>> rows = [];

    // Add headers
    rows.add(['Type', 'Name/Description', 'Amount', 'Date']);

    // Add expense data
    for (var expense in userExpenses) {
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
        final userId = widget.currentUser.uid;

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
              'expenses_$userId',
            ).add(models.ExpenseEntry(amount: amount, date: date));
            importedExpenses++;
          } else if (type.toLowerCase() == 'subscription') {
            Hive.box<models.SubscriptionEntry>('subscriptions_$userId').add(
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
          // Update the _pages list as the key for BudgetHomePage has changed
          _pages = _generatePageList();
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

  // Helper method to generate the list of pages
  List<Widget> _generatePageList() {
    return <Widget>[
      BudgetHomePage(
        key: _budgetHomePageKey, // Assign the key here
        initialCurrencySymbol: _currentDefaultCurrency,
        scheduleRemindersCallback:
            _scheduleSubscriptionReminders, // Pass the callback
        userId: widget.currentUser.uid, // Pass userId to BudgetHomePage
        title: 'Hello Kitty Budget Calculator',
      ),
      SettingsPage(
        themeMode: widget.currentThemeMode, // Pass theme from AppRoot
        onThemeChanged: widget.onThemeChanged, // Pass callback from AppRoot
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
    if (!_hiveBoxesOpened) {
      // Only wait for Hive boxes now
      // Show a loading indicator while the theme is being loaded
      return const Scaffold(
        // Consistently return a Scaffold
        body: Center(
          child: CircularProgressIndicator(),
        ), // Indicator as the body
      );
    }

    // MyApp now returns the Scaffold directly, to be used as the 'home' of AppRoot's MaterialApp
    return Scaffold(
      body: IndexedStack(
        // Use IndexedStack to preserve page states
        index: _selectedIndex,
        children: _pages, // Use the _pages list
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          // Removed 'const' here
          BottomNavigationBarItem(
            // Removed 'const' here
            icon: Image.asset(
              'assets/images/kitty_budget_icon.jpg',
              width: 24, // Standard icon size
              height: 24,
            ),
            activeIcon: Image.asset(
              'assets/images/kitty_budget_icon.jpg',
              width: 24, // Ensure active icon also has a size
              height: 24,
            ),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            // Removed 'const' here
            icon: Image.asset(
              'assets/images/kitty_settings_icon.jpg', // Corrected: Pass the string path directly
              width: 24, // Standard icon size
              height: 24,
            ),
            activeIcon: Image.asset(
              'assets/images/kitty_settings_icon.jpg', // Corrected: Pass the string path directly
              width: 24, // Ensure active icon also has a size
              height: 24,
            ),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor:
            Theme.of(context).colorScheme.primary, // Use theme color
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6), // Softer color for unselected
        onTap: _onItemTapped,
      ),
    );
  }
}
