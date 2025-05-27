import 'package:flutter/material.dart';
import '../models/entries.dart' as models;

class YearlySummary extends StatelessWidget {
  final List<models.ExpenseEntry> expenses;
  final List<models.SubscriptionEntry> subscriptions;
  final String currency;

  const YearlySummary({
    super.key,
    required this.expenses,
    required this.subscriptions,
    required this.currency,
  });

  Map<int, double> _calculateYearlyTotals(List<dynamic> entries) {
    Map<int, double> yearlyTotals = {};

    for (var entry in entries) {
      int year = entry.date.year;
      yearlyTotals[year] = (yearlyTotals[year] ?? 0) + entry.amount;
    }
    return yearlyTotals;
  }

  @override
  Widget build(BuildContext context) {
    final expenseTotals = _calculateYearlyTotals(expenses);
    final subscriptionTotals = _calculateYearlyTotals(subscriptions);

    final allYears =
        <int>{...expenseTotals.keys, ...subscriptionTotals.keys}.toList()
          ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yearly Spending Summary:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        const SizedBox(height: 8),
        ...allYears.map((year) {
          final expenseTotal = expenseTotals[year] ?? 0;
          final subscriptionTotal = subscriptionTotals[year] ?? 0;
          final total = expenseTotal + subscriptionTotal;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '$year: $currency${total.toStringAsFixed(2)} (Expenses: $currency${expenseTotal.toStringAsFixed(2)}, Subscriptions: $currency${subscriptionTotal.toStringAsFixed(2)})',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }),
      ],
    );
  }
}
