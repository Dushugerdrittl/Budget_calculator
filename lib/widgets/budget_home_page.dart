import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/entries.dart' as models;
import 'currency_selector.dart';
import 'expense_input.dart';
import 'subscription_input.dart';
import 'expense_list.dart';
import 'subscription_list.dart';
import 'monthly_summary.dart';
import 'budget_graph.dart';
import 'yearly_summary.dart';

class BudgetHomePage extends StatefulWidget {
  const BudgetHomePage({
    super.key,
    required this.title,
    this.initialCurrencySymbol = '\$', // Default if not provided
  });

  final String title;
  final String initialCurrencySymbol;

  @override
  State<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends State<BudgetHomePage> {
  late Box<models.ExpenseEntry> _expenseBox;
  late Box<models.SubscriptionEntry> _subscriptionBox;

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
        _expenseBox.values.map((e) => e.category ?? 'N/A').toSet().toList();
    categories.sort();
    return categories;
  }

  final Map<String, String> currencySymbols = {
    'Dollars': '\$',
    'Rupees': '₹',
    'Yen': '¥',
    'Euros': '€',
  };

  @override
  void initState() {
    super.initState();
    // Call super.initState() first
    _expenseBox = Hive.box<models.ExpenseEntry>('expenses');
    _selectedCurrency = widget.initialCurrencySymbol;
    _subscriptionBox = Hive.box<models.SubscriptionEntry>('subscriptions');
    _loadData();
  }

  void _loadData() {
    setState(() {
      Iterable<models.ExpenseEntry> filteredExpenses = _expenseBox.values;
      Iterable<models.SubscriptionEntry> filteredSubscriptions =
          _subscriptionBox.values;

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

  void _addExpense(double value, String category) {
    final entry = models.ExpenseEntry(
      amount: value,
      date: DateTime.now(),
      category: category,
    );
    _expenseBox.add(entry);
    _loadData();
  }

  void _addSubscription(String name, double value) {
    final entry = models.SubscriptionEntry(
      name: name,
      amount: value,
      date: DateTime.now(),
    );
    _subscriptionBox.add(entry);
    _loadData();
  }

  Future<void> _showEditAmountDialog({
    required String title,
    required double currentAmount,
    required void Function(double) onSave,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: currentAmount.toString(),
    );
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $title Amount'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
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
                final newAmount = double.tryParse(controller.text);
                if (newAmount != null && newAmount > 0) {
                  onSave(newAmount);
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
    final entry = _expenseBox.getAt(index);
    if (entry == null) return;
    _showEditAmountDialog(
      title: 'Expense',
      currentAmount: entry.amount,
      onSave: (newAmount) {
        entry.amount = newAmount;
        entry.save();
        _loadData();
      },
    );
  }

  void _editSubscription(int index) {
    final entry = _subscriptionBox.getAt(index);
    if (entry == null) return;
    _showEditAmountDialog(
      title: 'Subscription',
      currentAmount: entry.amount,
      onSave: (newAmount) {
        entry.amount = newAmount;
        entry.save();
        _loadData();
      },
    );
  }

  void _deleteExpense(int index) {
    _expenseBox.deleteAt(index);
    _loadData();
  }

  void _deleteSubscription(int index) {
    _subscriptionBox.deleteAt(index);
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
                    }).toList(),
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
