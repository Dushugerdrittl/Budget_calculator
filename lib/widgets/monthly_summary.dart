import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entries.dart' as models;

class MonthlySummary extends StatelessWidget {
  final List<models.ExpenseEntry> expenses;
  final List<models.SubscriptionEntry> subscriptions;
  final String currency;

  const MonthlySummary({
    super.key,
    required this.expenses,
    required this.subscriptions,
    required this.currency,
  });

  Map<String, double> _calculateMonthlyTotals(List<dynamic> entries) {
    Map<String, double> monthlyTotals = {};
    final DateFormat monthFormat = DateFormat('yyyy-MM');

    for (var entry in entries) {
      String month = monthFormat.format(entry.date);
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + entry.amount;
    }
    return monthlyTotals;
  }

  @override
  Widget build(BuildContext context) {
    final expenseTotals = _calculateMonthlyTotals(expenses);
    final subscriptionTotals = _calculateMonthlyTotals(subscriptions);

    final allMonths =
        <String>{...expenseTotals.keys, ...subscriptionTotals.keys}.toList()
          ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Summary:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        ...allMonths.map((month) {
          final expenseTotal = expenseTotals[month] ?? 0;
          final subscriptionTotal = subscriptionTotals[month] ?? 0;
          final total = expenseTotal + subscriptionTotal;
          return Text(
            '$month: $currency${total.toStringAsFixed(2)} (Expenses: $currency${expenseTotal.toStringAsFixed(2)}, Subscriptions: $currency${subscriptionTotal.toStringAsFixed(2)})',
          );
        }),
      ],
    );
  }
}
