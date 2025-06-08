import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../models/entries.dart' as models;
import 'currency_selector.dart';
import 'expense_input.dart';
import 'subscription_input.dart';
import 'expense_list.dart';
import 'monthly_summary.dart';
import 'budget_graph.dart';
import 'yearly_summary.dart';

class BudgetHomePage extends StatefulWidget {
  const BudgetHomePage({
    super.key,
    required this.title,
    required this.userId, // Add userId
    this.initialCurrencySymbol = '\$', // Default if not provided
  });

  final String title;
  final String initialCurrencySymbol;
  final String userId; // Add userId field

  @override
  State<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends State<BudgetHomePage> {
  // late Box<models.ExpenseEntry> _expenseBox; // Not needed as direct member
  // late Box<models.SubscriptionEntry> _subscriptionBox; // Not needed as direct member

  List<models.ExpenseEntry> _expenses = [];
  List<models.SubscriptionEntry> _subscriptions = [];

  late String _selectedCurrency;
  double? _monthlyBudgetLimit;
  String _searchQuery = '';
  List<String> _selectedFilterCategories = [];
  String _filterTransactionType = 'All'; // 'All', 'Expense', 'Subscription'

  // Get unique categories from expenses for filter options
  List<String> get _availableCategories {
    final categories =
        _getExpenseBox().values
            .map((e) => e.category ?? 'N/A')
            .toSet()
            .toList();
    categories.sort();
    return categories;
  }

  // Helper methods to get user-specific boxes
  Box<models.ExpenseEntry> _getExpenseBox() =>
      Hive.box<models.ExpenseEntry>('expenses_${widget.userId}');
  Box<models.SubscriptionEntry> _getSubscriptionBox() =>
      Hive.box<models.SubscriptionEntry>('subscriptions_${widget.userId}');

  final Map<String, String> currencySymbols = {
    'Dollars': '\$',
    'Rupees': '₹',
    'Yen': '¥',
    'Euros': '€',
  };

  @override
  void initState() {
    super.initState();
    // Boxes are now opened in MyApp's initState.
    // We just need to ensure they are ready before loading data.
    _selectedCurrency = widget.initialCurrencySymbol;
    _initializeAndLoadAllData();
  }

  Future<void> _initializeAndLoadAllData() async {
    // Ensure boxes are open (this should be guaranteed by MyApp's _hiveBoxesOpened flag)
    if (!Hive.isBoxOpen('expenses_${widget.userId}') ||
        !Hive.isBoxOpen('subscriptions_${widget.userId}')) {
      print("BudgetHomePage: Waiting for Hive boxes to be opened by MyApp...");
      // Optionally, wait a short duration and retry, or rely on MyApp to trigger a rebuild
      // For now, we assume MyApp handles this and BudgetHomePage is built when boxes are ready.
      return;
    }
    await _fetchDataFromFirestoreAndPopulateHive();
    _loadData(); // This will now load from the potentially updated Hive boxes
  }

  Future<void> _fetchDataFromFirestoreAndPopulateHive() async {
    print("Fetching data from Firestore for user ${widget.userId}");
    final expenseBox = _getExpenseBox();
    final subscriptionBox = _getSubscriptionBox();

    // Clear local boxes before populating from Firestore to avoid duplicates (simplistic sync)
    await expenseBox.clear();
    await subscriptionBox.clear();

    // Fetch and populate expenses
    final expenseSnapshots =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('expenses')
            .get();
    for (var doc in expenseSnapshots.docs) {
      // When fetching, store the Firestore doc.id as firestoreId
      final data = doc.data();
      expenseBox.add(
        models.ExpenseEntry(
          amount: (data['amount'] as num).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
          category: data['category'] as String?,
          firestoreId: doc.id, // Store Firestore document ID
        ),
      );
    }

    // Fetch and populate subscriptions
    final subscriptionSnapshots =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('subscriptions')
            .get();
    for (var doc in subscriptionSnapshots.docs) {
      final data = doc.data();
      subscriptionBox.add(
        models.SubscriptionEntry(
          name: data['name'] as String,
          amount: (data['amount'] as num).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
          firestoreId: doc.id, // Store Firestore document ID
        ),
      );
    }
    print("Data fetched from Firestore and Hive populated.");
  }

  void _loadData() {
    // Ensure boxes are open before trying to access them
    if (!Hive.isBoxOpen('expenses_${widget.userId}') ||
        !Hive.isBoxOpen('subscriptions_${widget.userId}')) {
      print(
        "BudgetHomePage: _loadData called but boxes not open. User: ${widget.userId}",
      );
      return; // Or show a loading state / handle error
    }
    setState(() {
      Iterable<models.ExpenseEntry> filteredExpenses = _getExpenseBox().values;
      Iterable<models.SubscriptionEntry> filteredSubscriptions =
          _getSubscriptionBox().values;

      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filteredExpenses = filteredExpenses.where((expense) {
          return expense.amount.toString().toLowerCase().contains(query) ||
              (expense.category?.toLowerCase().contains(query) ?? false);
        });
        filteredSubscriptions = filteredSubscriptions.where((sub) {
          return sub.name.toLowerCase().contains(query) ||
              sub.amount.toString().toLowerCase().contains(query);
        });
      }

      // Apply category filter (only for expenses)
      if (_selectedFilterCategories.isNotEmpty) {
        filteredExpenses = filteredExpenses.where(
          (expense) =>
              _selectedFilterCategories.contains(expense.category ?? 'N/A'),
        );
      }

      // Apply transaction type filter
      if (_filterTransactionType == 'Expense') {
        _expenses = filteredExpenses.toList();
        _subscriptions =
            []; // Show no subscriptions if filtering for expenses only
      } else if (_filterTransactionType == 'Subscription') {
        _expenses = []; // Show no expenses
        _subscriptions = filteredSubscriptions.toList();
      } else {
        // 'All'
        _expenses = filteredExpenses.toList();
        _subscriptions = filteredSubscriptions.toList();
      }
    });
  }

  Future<void> _addExpense(double value, String category) async {
    // Mark as async
    final newExpenseHive = models.ExpenseEntry(
      amount: value,
      date: DateTime.now(),
      category: category,
    );
    // Add to Hive first to get an object reference for finding index later
    // Make this async to await the key
    int hiveKey = await _getExpenseBox().add(newExpenseHive);

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('expenses')
        .add({
          'amount': newExpenseHive.amount,
          'date': Timestamp.fromDate(newExpenseHive.date),
          'category': newExpenseHive.category,
        })
        .then((docRef) async {
          print("Expense added to Firestore with ID: ${docRef.id}");
          newExpenseHive.firestoreId = docRef.id;
          // Update the Hive entry with the firestoreId using the key from add()
          await _getExpenseBox().put(hiveKey, newExpenseHive);
        })
        .catchError((error) {
          print("Failed to add expense to Firestore: $error");
        });
    _loadData();
  }

  Future<void> _addSubscription(String name, double value) async {
    // Mark as async
    final newSubscriptionHive = models.SubscriptionEntry(
      name: name,
      amount: value,
      date: DateTime.now(),
    );
    // Add to Hive first and get its key
    int hiveKey = await _getSubscriptionBox().add(newSubscriptionHive);

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('subscriptions')
        .add({
          'name': newSubscriptionHive.name,
          'amount': newSubscriptionHive.amount,
          'date': Timestamp.fromDate(newSubscriptionHive.date),
        })
        .then((docRef) async {
          print("Subscription added to Firestore with ID: ${docRef.id}");
          newSubscriptionHive.firestoreId = docRef.id;
          // Update the Hive entry with the firestoreId using the key from add()
          await _getSubscriptionBox().put(hiveKey, newSubscriptionHive);
        })
        .catchError((error) {
          print("Failed to add subscription to Firestore: $error");
        });
    _loadData();
  }

  Future<void> _showEditAmountDialog({
    required String title,
    required double currentAmount,
    required void Function(double) onSave,
    String? currentName, // Optional for subscriptions
    void Function(String)? onNameSave, // Optional for subscriptions
  }) async {
    final TextEditingController amountController = TextEditingController(
      text: currentAmount.toString(),
    );
    final TextEditingController? nameController =
        currentName != null ? TextEditingController(text: currentName) : null;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (nameController != null)
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (nameController != null) const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                final newAmount = double.tryParse(amountController.text);
                if (newAmount != null && newAmount > 0) {
                  onSave(newAmount);
                  if (nameController != null && onNameSave != null) {
                    onNameSave(nameController.text);
                  }
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _editExpense(int index) {
    final entry = _getExpenseBox().getAt(index);
    if (entry == null) return;
    _showEditAmountDialog(
      title: 'Expense',
      currentAmount: entry.amount,
      onSave: (newAmount) async {
        entry.amount = newAmount;
        await entry.save(); // Hive save

        if (entry.firestoreId != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('expenses')
              .doc(entry.firestoreId)
              .update({'amount': newAmount})
              .catchError((error) {
                print("Failed to update expense in Firestore: $error");
              });
        }
        _loadData();
      },
    );
  }

  void _editSubscription(int index) {
    final entry = _getSubscriptionBox().getAt(index);
    if (entry == null) return;
    _showEditAmountDialog(
      title: 'Subscription',
      currentAmount: entry.amount,
      currentName: entry.name, // Pass current name
      onSave: (newAmount) async {
        entry.amount = newAmount;
        // Name is handled by onNameSave
        // await entry.save(); // Hive save will be called after name save
      },
      onNameSave: (newName) async {
        // Handle name change
        entry.name = newName;
        await entry.save(); // Save both amount and name changes to Hive

        if (entry.firestoreId != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('subscriptions')
              .doc(entry.firestoreId)
              .update({
                'amount': entry.amount, // Use the (potentially) updated amount
                'name': newName,
              })
              .catchError((error) {
                print("Failed to update subscription in Firestore: $error");
              });
        }
        _loadData();
      },
    );
  }

  void _deleteExpense(int index) {
    final entry = _getExpenseBox().getAt(index);
    if (entry == null) return;

    _getExpenseBox().deleteAt(index); // Delete from Hive

    if (entry.firestoreId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('expenses')
          .doc(entry.firestoreId)
          .delete()
          .then((_) => print("Expense deleted from Firestore"))
          .catchError(
            (error) => print("Failed to delete expense from Firestore: $error"),
          );
    }
    _loadData();
  }

  void _deleteSubscription(int index) {
    final entry = _getSubscriptionBox().getAt(index);
    if (entry == null) return;

    _getSubscriptionBox().deleteAt(index); // Delete from Hive

    if (entry.firestoreId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('subscriptions')
          .doc(entry.firestoreId)
          .delete()
          .then((_) => print("Subscription deleted from Firestore"))
          .catchError(
            (error) =>
                print("Failed to delete subscription from Firestore: $error"),
          );
    }
    _loadData();
  }

  Future<void> _showSetBudgetLimitDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _monthlyBudgetLimit?.toString() ?? '',
    );
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Monthly Budget Limit'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Budget Limit',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                final limit = double.tryParse(controller.text);
                if (limit != null && limit > 0) {
                  setState(() {
                    _monthlyBudgetLimit = limit;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _setCurrency(String currency) {
    setState(() {
      _selectedCurrency = currency;
    });
  }

  Future<void> _showFilterDialog() async {
    List<String> tempSelectedCategories = List.from(_selectedFilterCategories);
    String tempTransactionType = _filterTransactionType;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          // Use StatefulBuilder for dialog's own state
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Transactions'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text(
                      'Transaction Type:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RadioListTile<String>(
                      title: const Text('All'),
                      value: 'All',
                      groupValue: tempTransactionType,
                      onChanged:
                          (value) => setDialogState(
                            () => tempTransactionType = value!,
                          ),
                    ),
                    RadioListTile<String>(
                      title: const Text('Expenses'),
                      value: 'Expense',
                      groupValue: tempTransactionType,
                      onChanged:
                          (value) => setDialogState(
                            () => tempTransactionType = value!,
                          ),
                    ),
                    RadioListTile<String>(
                      title: const Text('Subscriptions'),
                      value: 'Subscription',
                      groupValue: tempTransactionType,
                      onChanged:
                          (value) => setDialogState(
                            () => tempTransactionType = value!,
                          ),
                    ),
                    const Divider(),
                    const Text(
                      'Categories (Expenses):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_availableCategories.isEmpty)
                      const Text('No categories available to filter.'),
                    ..._availableCategories.map((category) {
                      return CheckboxListTile(
                        title: Text(category),
                        value: tempSelectedCategories.contains(category),
                        onChanged: (bool? selected) {
                          setDialogState(() {
                            if (selected == true) {
                              tempSelectedCategories.add(category);
                            } else {
                              tempSelectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Clear Filters'),
                  onPressed: () {
                    setState(() {
                      _selectedFilterCategories = [];
                      _filterTransactionType = 'All';
                      _loadData();
                    });
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: const Text('Apply'),
                  onPressed: () {
                    setState(() {
                      _selectedFilterCategories = tempSelectedCategories;
                      _filterTransactionType = tempTransactionType;
                      _loadData();
                    });
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  double get totalBudget {
    double totalExpenses = _expenses.fold(0, (sum, item) => sum + item.amount);
    double totalSubscriptions = _subscriptions.fold(
      0,
      (sum, item) => sum + item.amount,
    );
    return totalExpenses + totalSubscriptions;
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverBudget =
        _monthlyBudgetLimit != null && totalBudget > _monthlyBudgetLimit!;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/hellokittyx.png',
            fit: BoxFit.cover,
            color: Colors.pinkAccent.withOpacity(0.6),
            colorBlendMode: BlendMode.modulate,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                        fontFamily: 'Comic Sans MS',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Search Transactions...',
                              hintText: 'Name, category, amount',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              filled: true,
                              fillColor: Theme.of(
                                context,
                              ).cardColor.withOpacity(0.8),
                            ),
                            onChanged: (value) {
                              _searchQuery = value;
                              _loadData(); // Re-filter and update lists
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'Filter Transactions',
                          onPressed: _showFilterDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CurrencySelector(
                          currencySymbols: currencySymbols,
                          selectedCurrency: _selectedCurrency,
                          onCurrencyChanged: _setCurrency,
                        ),
                        ElevatedButton(
                          onPressed: _showSetBudgetLimitDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: FittedBox(
                            // Allow text to scale down
                            fit: BoxFit.scaleDown,
                            child: const Text(
                              'Set Budget', // Use the shorter text
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ), // Ensure text color is set
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ExpenseInput(onAddExpense: _addExpense),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SubscriptionInput(
                          onAddSubscription: _addSubscription,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ExpenseList(
                          expenses: _expenses,
                          currency: _selectedCurrency,
                          onDelete: _deleteExpense,
                          onEdit: _editExpense,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ), // Added margin
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isOverBudget
                                ? Colors.redAccent.withOpacity(0.8)
                                : Colors.pinkAccent.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize
                                  .min, // So column doesn't take full height
                          children: [
                            Text(
                              'Total Spending: $_selectedCurrency${totalBudget.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_monthlyBudgetLimit != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Budget Limit: $_selectedCurrency${_monthlyBudgetLimit!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    BudgetGraph(
                      totalSpending: totalBudget,
                      budgetLimit: _monthlyBudgetLimit,
                      currency: _selectedCurrency,
                    ),
                    const SizedBox(height: 20),
                    MonthlySummary(
                      expenses: _expenses,
                      // subscriptions: _subscriptions, // Removed as MonthlySummary no longer accepts it
                      currency: _selectedCurrency,
                    ),
                    const SizedBox(height: 20),
                    YearlySummary(
                      expenses: _expenses,
                      subscriptions: _subscriptions,
                      currency: _selectedCurrency,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
