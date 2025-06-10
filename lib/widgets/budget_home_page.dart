import 'package:expance/widgets/spending_over_time_graph.dart'; // Import the new bar graph widget
import 'package:expance/widgets/subscription_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../models/category.dart'; // Import Category model
import '../models/entries.dart' as models;
import 'currency_selector.dart';
import 'expense_input.dart';
import 'subscription_input.dart';
import 'expense_list.dart';
import 'monthly_summary.dart';
import 'budget_graph.dart'; // This is now the Pie Chart
import 'yearly_summary.dart';
import '../services/notification_service.dart'; // Import NotificationService

class BudgetHomePage extends StatefulWidget {
  const BudgetHomePage({
    super.key,
    required this.title,
    required this.userId, // Add userId
    required this.scheduleRemindersCallback, // Add callback for scheduling
    this.initialCurrencySymbol = '\$', // Default if not provided
  });

  final String title;
  final String initialCurrencySymbol;
  final String userId; // Add userId field
  final Future<void> Function() scheduleRemindersCallback; // Callback

  @override
  State<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends State<BudgetHomePage> {
  List<models.ExpenseEntry> _expenses = [];
  List<models.SubscriptionEntry> _subscriptions = [];

  late String _selectedCurrency;
  double? _monthlyBudgetLimit;
  String _searchQuery = '';
  List<String> _selectedFilterCategories = [];
  String _filterTransactionType = 'All'; // 'All', 'Expense', 'Subscription'
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _currentSortOrder = 'date_desc'; // Default sort order

  DateTime? _graphStartDate; // Date range for the Pie Chart
  DateTime? _graphEndDate; // Date range for the Pie Chart

  String _barGraphPeriod = 'monthly'; // 'daily', 'weekly', 'monthly', 'yearly'
  final List<String> _barGraphPeriods = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  // State for tracking monthly budget notifications
  String _currentMonthForNotificationTracking = "";
  final Map<String, String> _categoryNotificationStatusForMonth =
      {}; // Key: category.id, Value: 'warning' or 'alert'

  final Map<String, String> _sortOptions = {
    'date_desc': 'Date (Newest First)',
    'date_asc': 'Date (Oldest First)',
    'amount_desc': 'Amount (High to Low)',
    'amount_asc': 'Amount (Low to High)',
    'name_asc': 'Name/Category (A-Z)',
    'name_desc': 'Name/Category (Z-A)',
  };

  Box<Category> _getCategoryBox() =>
      Hive.box<Category>('categories_${widget.userId}');

  List<String> get _availableCategories {
    final categories =
        _getCategoryBox().values.map((c) => c.name).toSet().toList();
    categories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return categories;
  }

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
    _selectedCurrency = widget.initialCurrencySymbol;
    // Initialize graph date range to the current month
    final now = DateTime.now();
    _graphStartDate = DateTime(now.year, now.month, 1);
    _graphEndDate = DateTime(now.year, now.month, now.day); // Up to today
    _initializeAndLoadAllData();
  }

  Future<void> _initializeAndLoadAllData() async {
    if (!Hive.isBoxOpen('expenses_${widget.userId}') ||
        !Hive.isBoxOpen('subscriptions_${widget.userId}')) {
      print("BudgetHomePage: Waiting for Hive boxes to be opened by MyApp...");
      return;
    }
    await _fetchDataFromFirestoreAndPopulateHive();
    _loadData(); // This will call _checkCategoryBudgets
  }

  Future<void> _fetchDataFromFirestoreAndPopulateHive() async {
    print("Fetching data from Firestore for user ${widget.userId}");
    final expenseBox = _getExpenseBox();
    final subscriptionBox = _getSubscriptionBox();

    await expenseBox.clear();
    await subscriptionBox.clear();

    final expenseSnapshots =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('expenses')
            .get();
    for (var doc in expenseSnapshots.docs) {
      final data = doc.data();
      expenseBox.add(
        models.ExpenseEntry(
          amount: (data['amount'] as num).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
          category: data['category'] as String?,
          firestoreId: doc.id,
        ),
      );
    }

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
          firestoreId: doc.id,
          nextDueDate:
              (data['nextDueDate'] as Timestamp?)?.toDate() ??
              (data['date'] as Timestamp).toDate(),
          reminderScheduled: data['reminderScheduled'] as bool? ?? false,
          enableReminder: data['enableReminder'] as bool? ?? false,
        ),
      );
    }
    print("Data fetched from Firestore and Hive populated.");
  }

  void _loadData() {
    if (!Hive.isBoxOpen('expenses_${widget.userId}') ||
        !Hive.isBoxOpen('subscriptions_${widget.userId}')) {
      print(
        "BudgetHomePage: _loadData called but boxes not open. User: ${widget.userId}",
      );
      return;
    }
    setState(() {
      Iterable<models.ExpenseEntry> filteredExpenses = _getExpenseBox().values;
      Iterable<models.SubscriptionEntry> filteredSubscriptions =
          _getSubscriptionBox().values;

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

      if (_selectedFilterCategories.isNotEmpty) {
        filteredExpenses = filteredExpenses.where(
          (expense) =>
              _selectedFilterCategories.contains(expense.category ?? 'N/A'),
        );
      }

      if (_filterStartDate != null) {
        filteredExpenses = filteredExpenses.where(
          (expense) => !expense.date.isBefore(_filterStartDate!),
        );
        filteredSubscriptions = filteredSubscriptions.where(
          (sub) => !sub.date.isBefore(_filterStartDate!),
        );
      }
      if (_filterEndDate != null) {
        final inclusiveEndDate = DateTime(
          _filterEndDate!.year,
          _filterEndDate!.month,
          _filterEndDate!.day,
          23,
          59,
          59,
        );
        filteredExpenses = filteredExpenses.where(
          (expense) => !expense.date.isAfter(inclusiveEndDate),
        );
        filteredSubscriptions = filteredSubscriptions.where(
          (sub) => !sub.date.isAfter(inclusiveEndDate),
        );
      }

      if (_filterTransactionType == 'Expense') {
        _expenses = filteredExpenses.toList();
        _subscriptions = [];
      } else if (_filterTransactionType == 'Subscription') {
        _expenses = [];
        _subscriptions = filteredSubscriptions.toList();
      } else {
        _expenses = filteredExpenses.toList();
        _subscriptions = filteredSubscriptions.toList();
      }
    });
    _applySorting();
    _checkCategoryBudgets(); // Also check after filtering/sorting if data changes
  }

  void _applySorting() {
    setState(() {
      _expenses.sort((a, b) {
        switch (_currentSortOrder) {
          case 'date_asc':
            return a.date.compareTo(b.date);
          case 'amount_desc':
            return b.amount.compareTo(a.amount);
          case 'amount_asc':
            return a.amount.compareTo(b.amount);
          case 'name_asc':
            return (a.category ?? '').toLowerCase().compareTo(
              (b.category ?? '').toLowerCase(),
            );
          case 'name_desc':
            return (b.category ?? '').toLowerCase().compareTo(
              (a.category ?? '').toLowerCase(),
            );
          case 'date_desc':
          default:
            return b.date.compareTo(a.date);
        }
      });

      _subscriptions.sort((a, b) {
        switch (_currentSortOrder) {
          case 'date_asc':
            return a.date.compareTo(b.date);
          case 'amount_desc':
            return b.amount.compareTo(a.amount);
          case 'amount_asc':
            return a.amount.compareTo(b.amount);
          case 'name_asc':
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case 'name_desc':
            return b.name.toLowerCase().compareTo(a.name.toLowerCase());
          case 'date_desc':
          default:
            return b.date.compareTo(a.date);
        }
      });
    });
  }

  String _formatDateForDisplay(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat.yMd().format(date);
  }

  Future<void> _addExpense(double value, String category) async {
    final newExpenseHive = models.ExpenseEntry(
      amount: value,
      date: DateTime.now(),
      category: category,
    );
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
          await _getExpenseBox().put(hiveKey, newExpenseHive);
        })
        .catchError((error) {
          print("Failed to add expense to Firestore: $error");
        });
    _loadData();
  }

  Future<void> _addSubscription(
    String name,
    double value,
    bool enableReminder,
    DateTime nextDueDate,
  ) async {
    final newSubscriptionHive = models.SubscriptionEntry(
      name: name,
      amount: value,
      date: DateTime.now(),
      nextDueDate: nextDueDate,
      enableReminder: enableReminder,
    );
    int hiveKey = await _getSubscriptionBox().add(newSubscriptionHive);

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('subscriptions')
        .add({
          'name': newSubscriptionHive.name,
          'amount': newSubscriptionHive.amount,
          'date': Timestamp.fromDate(newSubscriptionHive.date),
          'nextDueDate': Timestamp.fromDate(newSubscriptionHive.nextDueDate!),
          'enableReminder': newSubscriptionHive.enableReminder,
          'reminderScheduled': newSubscriptionHive.reminderScheduled ?? false,
        })
        .then((docRef) async {
          print("Subscription added to Firestore with ID: ${docRef.id}");
          newSubscriptionHive.firestoreId = docRef.id;
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
    String? currentName,
    void Function(String)? onNameSave,
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

  void _editExpense(models.ExpenseEntry expenseToEdit) {
    // expenseToEdit is the actual Hive object from the list
    _showEditAmountDialog(
      title: 'Expense',
      currentAmount: expenseToEdit.amount,
      onSave: (newAmount) async {
        expenseToEdit.amount = newAmount;
        await expenseToEdit.save(); // Save the Hive object

        if (expenseToEdit.firestoreId != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('expenses')
              .doc(expenseToEdit.firestoreId)
              .update({'amount': newAmount}) // Use entry for firestoreId
              .catchError((error) {
                print("Failed to update expense in Firestore: $error");
              });
        }
        _loadData();
      },
    );
  }

  void _editSubscription(models.SubscriptionEntry subscriptionToEdit) {
    // subscriptionToEdit is the actual Hive object
    _showEditAmountDialog(
      title: 'Subscription',
      currentAmount: subscriptionToEdit.amount,
      currentName: subscriptionToEdit.name,
      onSave: (newAmount) async {
        subscriptionToEdit.amount = newAmount;
      },
      onNameSave: (newName) async {
        subscriptionToEdit.name = newName;
        await subscriptionToEdit.save(); // Save the Hive object

        if (subscriptionToEdit.firestoreId != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('subscriptions')
              .doc(subscriptionToEdit.firestoreId)
              .update({
                'amount': subscriptionToEdit.amount,
                'name': newName,
              }) // Use subscriptionToEdit
              .catchError((error) {
                print("Failed to update subscription in Firestore: $error");
              });
        }
        _loadData();
      },
    );
  }

  void _deleteExpense(models.ExpenseEntry expenseToDelete) {
    // expenseToDelete is the actual Hive object
    final String? firestoreId =
        expenseToDelete.firestoreId; // Store before deleting
    expenseToDelete.delete(); // Delete from Hive

    if (firestoreId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('expenses')
          .doc(firestoreId)
          .delete() // Use firestoreId
          .then((_) => print("Expense deleted from Firestore"))
          .catchError(
            (error) => print("Failed to delete expense from Firestore: $error"),
          );
    }
    _loadData();
  }

  Future<void> _markSubscriptionAsPaid(
    models.SubscriptionEntry subscriptionToMark,
  ) async {
    // subscriptionToMark is the actual Hive object
    subscriptionToMark.advanceNextDueDate();
    await subscriptionToMark.save(); // Save to Hive

    if (subscriptionToMark.firestoreId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('subscriptions')
            .doc(subscriptionToMark.firestoreId)
            .update({
              // Use subscriptionToMark
              'nextDueDate': Timestamp.fromDate(
                subscriptionToMark.nextDueDate!,
              ),
              'reminderScheduled':
                  subscriptionToMark.reminderScheduled ?? false,
            });
        await widget.scheduleRemindersCallback();
      } catch (e) {
        print(
          "Error updating subscription in Firestore after marking as paid: $e",
        );
      }
    }
    _loadData();
  }

  void _deleteSubscription(models.SubscriptionEntry subscriptionToDelete) {
    // subscriptionToDelete is the actual Hive object
    final String? firestoreId =
        subscriptionToDelete.firestoreId; // Store before deleting
    subscriptionToDelete.delete(); // Delete from Hive

    if (firestoreId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('subscriptions')
          .doc(firestoreId)
          .delete() // Use firestoreId
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Set Monthly Budget',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Budget Limit',
              hintText: 'Enter amount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              prefixText: '$_selectedCurrency ',
            ),
            autofocus: true,
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                final limit = double.tryParse(controller.text);
                if (limit != null && limit > 0) {
                  setState(() {
                    _monthlyBudgetLimit = limit;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
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

  // This method is for the Pie Chart date range
  Future<void> _selectGraphDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _graphStartDate ?? DateTime.now(),
        end: _graphEndDate ?? DateTime.now(),
      ),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Select date range for graph',
      cancelText: 'CANCEL',
      confirmText: 'APPLY',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme, // Use app's theme
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _graphStartDate = picked.start;
        _graphEndDate = picked.end;
      });
    }
  }

  Future<void> _showFilterDialog() async {
    List<String> tempSelectedCategories = List.from(_selectedFilterCategories);
    String tempTransactionType = _filterTransactionType;
    DateTime? tempStartDate = _filterStartDate;
    DateTime? tempEndDate = _filterEndDate;
    String tempSortOrder = _currentSortOrder;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: const Text('Filter Transactions'),
              titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Transaction Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text('All'),
                      value: 'All',
                      groupValue: tempTransactionType,
                      onChanged:
                          (value) => setDialogState(
                            () => tempTransactionType = value!,
                          ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('Expenses'),
                      value: 'Expense',
                      groupValue: tempTransactionType,
                      onChanged:
                          (value) => setDialogState(
                            () => tempTransactionType = value!,
                          ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('Subscriptions'),
                      value: 'Subscription',
                      groupValue: tempTransactionType,
                      onChanged:
                          (value) => setDialogState(
                            () => tempTransactionType = value!,
                          ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    ExpansionTile(
                      title: Text(
                        'Categories (Expenses)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                      ),
                      initiallyExpanded: tempSelectedCategories.isNotEmpty,
                      children:
                          _availableCategories.isEmpty
                              ? [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text('No categories available.'),
                                ),
                              ]
                              : _availableCategories.map((category) {
                                return CheckboxListTile(
                                  title: Text(category),
                                  value: tempSelectedCategories.contains(
                                    category,
                                  ),
                                  onChanged: (bool? selected) {
                                    setDialogState(() {
                                      if (selected == true) {
                                        tempSelectedCategories.add(category);
                                      } else {
                                        tempSelectedCategories.remove(category);
                                      }
                                    });
                                  },
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                );
                              }).toList(),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Text(
                        'Date Range',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            child: Text(_formatDateForDisplay(tempStartDate)),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: tempStartDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (picked != null && picked != tempStartDate) {
                                setDialogState(() => tempStartDate = picked);
                              }
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text("to"),
                        ),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            child: Text(_formatDateForDisplay(tempEndDate)),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: tempEndDate ?? DateTime.now(),
                                firstDate: tempStartDate ?? DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (picked != null && picked != tempEndDate) {
                                setDialogState(() => tempEndDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        child: const Text("Clear Date Range"),
                        onPressed:
                            () => setDialogState(() {
                              tempStartDate = null;
                              tempEndDate = null;
                            }),
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Text(
                        'Sort By',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: tempSortOrder,
                      items:
                          _sortOptions.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() => tempSortOrder = newValue);
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedFilterCategories = [];
                      _filterTransactionType = 'All';
                      _filterStartDate = null;
                      _filterEndDate = null;
                      _currentSortOrder = 'date_desc';
                      _loadData();
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Clear Filters'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedFilterCategories = tempSelectedCategories;
                      _filterTransactionType = tempTransactionType;
                      _filterStartDate = tempStartDate;
                      _filterEndDate = tempEndDate;
                      _currentSortOrder = tempSortOrder;
                      _loadData();
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Apply'),
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

  void _checkCategoryBudgets() {
    print("[BudgetCheck] Running _checkCategoryBudgets...");

    if (!_getCategoryBox().isOpen || !_getExpenseBox().isOpen) {
      print("Budget check skipped: Boxes not open.");
      return;
    }

    final now = DateTime.now();
    final String monthYearKey = "${now.year}-${now.month}";

    // Reset notification status if the month has changed
    if (_currentMonthForNotificationTracking != monthYearKey) {
      _currentMonthForNotificationTracking = monthYearKey;
      _categoryNotificationStatusForMonth.clear();
      print(
        "[BudgetCheck] New month ($monthYearKey) detected, resetting category notification statuses.",
      );
    }

    final currentMonthExpenses =
        _getExpenseBox().values
            .where(
              (expense) =>
                  expense.date.year == now.year &&
                  expense.date.month == now.month,
            )
            .toList();

    print(
      "[BudgetCheck] Current month expenses count: ${currentMonthExpenses.length}",
    );

    Map<String, double> spendingPerCategory = {};
    for (var expense in currentMonthExpenses) {
      if (expense.category != null) {
        spendingPerCategory[expense.category!] =
            (spendingPerCategory[expense.category!] ?? 0) + expense.amount;
      }
    }
    print(
      "[BudgetCheck] Spending per category this month: $spendingPerCategory",
    );

    final categories = _getCategoryBox().values;
    for (var category in categories) {
      print(
        "[BudgetCheck] Checking category: ${category.name}, Budget: ${category.budget}",
      );
      if (category.budget != null && category.budget! > 0) {
        double spent = spendingPerCategory[category.name] ?? 0.0;
        double budget = category.budget!;
        double percentageSpent = (spent / budget) * 100;

        print(
          "[BudgetCheck] For category '${category.name}': Spent: $spent, Budget: $budget, Percentage: ${percentageSpent.toStringAsFixed(1)}%",
        );

        final int warningNotificationId = 1000000 + category.id.hashCode.abs();
        final int alertNotificationId = 2000000 + category.id.hashCode.abs();

        String categoryNotificationKey =
            category.id; // Assuming category.id is unique and stable
        String currentStatus =
            _categoryNotificationStatusForMonth[categoryNotificationKey] ?? "";

        if (percentageSpent >= 100) {
          if (currentStatus != 'alert') {
            // Only send if not already alerted this month
            print(
              "ALERT: Budget EXCEEDED for category '${category.name}'. Spent: $_selectedCurrency${spent.toStringAsFixed(2)}, Budget: $_selectedCurrency${budget.toStringAsFixed(2)} (${percentageSpent.toStringAsFixed(1)}%) - Sending Notification",
            );
            NotificationService().showSimpleNotification(
              id: alertNotificationId,
              title: 'Budget Exceeded: ${category.name}',
              body:
                  'You\'ve spent $_selectedCurrency${spent.toStringAsFixed(2)} of your $_selectedCurrency${budget.toStringAsFixed(2)} budget for ${category.name}.',
              channelId: 'budget_alerts_exceeded',
              channelName: 'Budget Exceeded Alerts',
              channelDescription:
                  'Notifications for when a category budget is exceeded.',
              importance: Importance.high, // Ensure it's prominent
            );
            _categoryNotificationStatusForMonth[categoryNotificationKey] =
                'alert';
          }
        } else if (percentageSpent >= 80) {
          if (currentStatus == "") {
            // Only send warning if no notification (warning or alert) sent yet this month
            print(
              "WARNING: Budget APPROACHING for category '${category.name}'. Spent: $_selectedCurrency${spent.toStringAsFixed(2)}, Budget: $_selectedCurrency${budget.toStringAsFixed(2)} (${percentageSpent.toStringAsFixed(1)}%) - Sending Notification",
            );
            NotificationService().showSimpleNotification(
              id: warningNotificationId,
              title: 'Budget Warning: ${category.name}',
              body:
                  'You\'ve spent $_selectedCurrency${spent.toStringAsFixed(2)} (${percentageSpent.toStringAsFixed(1)}%) of your $_selectedCurrency${budget.toStringAsFixed(2)} budget for ${category.name}.',
              channelId: 'budget_warnings',
              channelName: 'Budget Warnings',
              channelDescription:
                  'Notifications for when a category budget is approaching its limit.',
              importance:
                  Importance
                      .defaultImportance, // Slightly less prominent than exceeded
            );
            _categoryNotificationStatusForMonth[categoryNotificationKey] =
                'warning';
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverBudget =
        _monthlyBudgetLimit != null && totalBudget > _monthlyBudgetLimit!;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent,
                        fontFamily: 'Comic Sans MS',
                      ),
                    ),
                    const SizedBox(height: 16),
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
                              fillColor: Colors.white.withOpacity(0.85),
                            ),
                            onChanged: (value) {
                              _searchQuery = value;
                              _loadData();
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color: Colors.pinkAccent,
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
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Set Budget',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ExpenseInput(
                          onAddExpense: _addExpense,
                          userId: widget.userId,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SubscriptionInput(
                          onAddSubscription: _addSubscription,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 8.0,
                        ),
                        child: ExpenseList(
                          expenses: _expenses,
                          currency: _selectedCurrency,
                          onDelete: _deleteExpense,
                          onEdit: _editExpense,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Add SubscriptionList here
                    SubscriptionList(
                      subscriptions: _subscriptions,
                      currency: _selectedCurrency,
                      onDelete: _deleteSubscription,
                      onEdit: _editSubscription,
                      onMarkAsPaid: _markSubscriptionAsPaid,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 12.0),
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
                          mainAxisSize: MainAxisSize.min,
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
                    Row(
                      // Row for Pie Chart title and date picker
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spending by Category',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Flexible(
                          // Wrap the TextButton.icon in Flexible
                          child: TextButton.icon(
                            onPressed: _selectGraphDateRange,
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                            ), // Adjusted icon size
                            label: Flexible(
                              // Allow the label to be flexible
                              child: Text(
                                _graphStartDate != null && _graphEndDate != null
                                    ? '${DateFormat.yMd().format(_graphStartDate!)} - ${DateFormat.yMd().format(_graphEndDate!)}'
                                    : 'Select Range',
                                overflow:
                                    TextOverflow
                                        .ellipsis, // Handle long text by truncating
                                style: TextStyle(
                                  fontSize:
                                      14, // Slightly larger for visibility
                                  fontWeight: FontWeight.bold, // Make it bold
                                  color:
                                      Colors
                                          .black87, // Use a dark color for contrast
                                ),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ), // Adjust padding if needed
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BudgetGraph(
                      // This is the Pie Chart
                      // Pass the filtered expenses and date range to the graph
                      expenses:
                          _expenses.where((expense) {
                            return (_graphStartDate == null ||
                                    !expense.date.isBefore(_graphStartDate!)) &&
                                (_graphEndDate == null ||
                                    !expense.date.isAfter(
                                      DateTime(
                                        _graphEndDate!.year,
                                        _graphEndDate!.month,
                                        _graphEndDate!.day,
                                        23,
                                        59,
                                        59,
                                      ),
                                    ));
                          }).toList(),
                      budgetLimit: _monthlyBudgetLimit,
                      currency: _selectedCurrency,
                    ),
                    const SizedBox(height: 20),
                    // New Section for Spending Over Time Bar Graph
                    Text(
                      'Spending Over Time',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Period Selector for Bar Graph
                    Center(
                      child: SegmentedButton<String>(
                        segments:
                            _barGraphPeriods.map((period) {
                              String label =
                                  period[0].toUpperCase() +
                                  period.substring(
                                    1,
                                  ); // Capitalize first letter
                              if (period == 'daily') label = 'Day';
                              if (period == 'weekly') label = 'Week';
                              if (period == 'monthly') label = 'Month';
                              if (period == 'yearly') label = 'Year';
                              return ButtonSegment<String>(
                                value: period,
                                label: Text(label),
                              );
                            }).toList(),
                        selected: {_barGraphPeriod},
                        onSelectionChanged: (Set<String> newSelection) {
                          if (newSelection.isNotEmpty) {
                            setState(() {
                              _barGraphPeriod = newSelection.first;
                            });
                          }
                        },
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          selectedForegroundColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // New Bar Graph Widget
                    SpendingOverTimeGraph(
                      expenses: _expenses, // Pass all filtered expenses
                      period: _barGraphPeriod,
                      currency: _selectedCurrency,
                    ),
                    const SizedBox(height: 20),

                    // Monthly and Yearly Summaries remain below the graphs
                    MonthlySummary(
                      expenses: _expenses,
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
