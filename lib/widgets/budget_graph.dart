import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/entries.dart' as models; // Import expense model

class BudgetGraph extends StatelessWidget {
  final List<models.ExpenseEntry> expenses; // Receive filtered expenses
  final double? budgetLimit;
  final String currency;

  const BudgetGraph({
    super.key,
    required this.expenses,
    this.budgetLimit,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate spending per category from the provided expenses
    Map<String, double> spendingPerCategory = {};
    for (var expense in expenses) {
      spendingPerCategory[expense.category ?? 'Uncategorized'] =
          (spendingPerCategory[expense.category ?? 'Uncategorized'] ?? 0) +
          expense.amount;
    }

    // Prepare data for a Pie Chart (Spending by Category)
    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    final List<Color> colors = [
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.tealAccent,
      Colors.redAccent,
      Colors.indigoAccent,
      Colors.cyanAccent,
      Colors.limeAccent,
    ]; // Define a set of colors

    spendingPerCategory.forEach((category, amount) {
      if (amount > 0) {
        sections.add(
          PieChartSectionData(
            value: amount,
            color: colors[colorIndex % colors.length], // Cycle through colors
            title: '${category}\n${currency}${amount.toStringAsFixed(2)}',
            radius: 80, // Adjust size as needed
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.black54,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
            titlePositionPercentageOffset: 0.55, // Adjust text position
          ),
        );
        colorIndex++;
      }
    });

    // Add a section for remaining budget if a limit is set and not exceeded
    double totalSpent = expenses.fold(0, (sum, item) => sum + item.amount);
    if (budgetLimit != null && budgetLimit! > totalSpent) {
      double remaining = budgetLimit! - totalSpent;
      sections.add(
        PieChartSectionData(
          value: remaining,
          color: Colors.grey.shade300, // Color for remaining budget
          title: 'Remaining\n${currency}${remaining.toStringAsFixed(2)}',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            shadows: [
              Shadow(
                blurRadius: 2.0,
                color: Colors.white54,
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
          titlePositionPercentageOffset: 0.55,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.3, // Adjust aspect ratio as needed
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PieChart(
            // Changed to PieChart
            PieChartData(
              sections: sections,
              borderData: FlBorderData(show: false),
              sectionsSpace: 2, // Space between sections
              centerSpaceRadius: 40, // Inner circle radius
              // Optional: Add touch interactions
              // pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) { ... }),
            ),
          ),
        ),
      ),
    );
  }
}
