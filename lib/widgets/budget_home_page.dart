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
  const BudgetHomePage({super.key, required this.title});

  final String title;

  @override
  State<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends State<BudgetHomePage> {
  late Box<models.ExpenseEntry> _expenseBox;
  late Box<models.SubscriptionEntry> _subscriptionBox;

  List<models.ExpenseEntry> _expenses = [];
  List<models.SubscriptionEntry> _subscriptions = [];

  String _selectedCurrency = '\$'; // Default to dollars
  double? _monthlyBudgetLimit;

  final Map<String, String> currencySymbols = {
    'Dollars': '\$',
    'Rupees': '₹',
    'Yen': '¥',
    'Euros': '€',
  };

  @override
  void initState() {
    super.initState();
    _expenseBox = Hive.box<models.ExpenseEntry>('expenses');
    _subscriptionBox = Hive.box<models.SubscriptionEntry>('subscriptions');
    _loadData();
  }

  void _loadData() {
    setState(() {
      _expenses = _expenseBox.values.toList();
      _subscriptions = _subscriptionBox.values.toList();
    });
  }

  void _addExpense(double value) {
    final entry = models.ExpenseEntry(amount: value, date: DateTime.now());
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
                          child: const Text(
                            'Set Monthly Budget',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ExpenseInput(onAddExpense: _addExpense),
                    const SizedBox(height: 12),
                    SubscriptionInput(onAddSubscription: _addSubscription),
                    const SizedBox(height: 20),
                    ExpenseList(
                      expenses: _expenses,
                      currency: _selectedCurrency,
                      onDelete: _deleteExpense,
                      onEdit: _editExpense,
                    ),
                    const SizedBox(height: 12),
                    SubscriptionList(
                      subscriptions: _subscriptions,
                      currency: _selectedCurrency,
                      onDelete: _deleteSubscription,
                      onEdit: _editSubscription,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isOverBudget
                                ? Colors.redAccent
                                : Colors.pinkAccent.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _monthlyBudgetLimit == null
                              ? 'Total Monthly Budget: $_selectedCurrency${totalBudget.toStringAsFixed(2)}'
                              : 'Total Monthly Budget: $_selectedCurrency${totalBudget.toStringAsFixed(2)} / Budget Limit: $_selectedCurrency${_monthlyBudgetLimit!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
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
                      subscriptions: _subscriptions,
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
