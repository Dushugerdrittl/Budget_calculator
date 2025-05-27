import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/entries.dart' as models;
import 'widgets/budget_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(models.ExpenseEntryAdapter());
  Hive.registerAdapter(models.SubscriptionEntryAdapter());

  await Hive.openBox<models.ExpenseEntry>('expenses');
  await Hive.openBox<models.SubscriptionEntry>('subscriptions');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const BudgetHomePage(title: 'Hello Kitty Budget Calculator'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hello Kitty Budget App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate),
              label: 'Budget',
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
