import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entries.dart' as models;
import 'package:fl_chart/fl_chart.dart';

class MonthlySummary extends StatelessWidget {
  final List<models.ExpenseEntry> expenses;
  // Subscriptions are not typically categorized in the same way,
  // so we'll focus on expense categories for this summary.
  // final List<models.SubscriptionEntry> subscriptions;
  final String currency;

  const MonthlySummary({
    super.key,
    required this.expenses,
    // required this.subscriptions,
    required this.currency,
  });

  Map<String, double> _calculateCategoryTotalsForCurrentMonth(
    List<models.ExpenseEntry> currentMonthExpenses,
  ) {
    Map<String, double> categoryTotals = {};

    for (var expense in currentMonthExpenses) {
      String category =
          expense.category ?? 'N/A'; // Use 'N/A' if category is null
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  List<PieChartSectionData> _generatePieChartSections(
    Map<String, double> categoryTotals,
    BuildContext context,
  ) {
    final List<Color> colors = [
      Colors.blue.shade300,
      Colors.red.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.yellow.shade700,
      Colors.teal.shade300,
      Colors.pink.shade300,
    ];
    int colorIndex = 0;

    return categoryTotals.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title:
            '${entry.key}\n$currency${entry.value.toStringAsFixed(0)}', // Simplified title
        radius: 50, // Adjust radius as needed
        titleStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black54,
        ),
        titlePositionPercentageOffset: 0.6, // Adjust label position
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonthExpenses =
        expenses.where((expense) {
          return expense.date.year == now.year &&
              expense.date.month == now.month;
        }).toList();

    final categoryTotals = _calculateCategoryTotalsForCurrentMonth(
      currentMonthExpenses,
    );

    double totalCurrentMonthSpending = currentMonthExpenses.fold(
      0,
      (sum, item) => sum + item.amount,
    );

    final String currentMonthName = DateFormat.yMMMM().format(now);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending for $currentMonthName:',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: $currency${totalCurrentMonthSpending.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (categoryTotals.isEmpty && currentMonthExpenses.isNotEmpty)
              const Text(
                'No categorized expenses this month.',
                style: TextStyle(fontSize: 16),
              )
            else if (categoryTotals.isEmpty && currentMonthExpenses.isEmpty)
              const Text(
                'No expenses this month.',
                style: TextStyle(fontSize: 16),
              )
            else
              const Text(
                'By Category:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 4),
            if (categoryTotals.isNotEmpty)
              SizedBox(
                height: 150, // Adjust height as needed
                child: PieChart(
                  PieChartData(
                    sections: _generatePieChartSections(
                      categoryTotals,
                      context,
                    ),
                    centerSpaceRadius: 30, // Adjust center space
                    sectionsSpace: 2, // Space between sections
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Optional: Handle touch events on chart sections
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12), // Spacer after chart
            // Text list of categories (optional, can be removed if chart is sufficient)
            ...categoryTotals.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  '  ${entry.key}: $currency${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
