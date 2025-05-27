import 'package:flutter/material.dart';

class BudgetGraph extends StatelessWidget {
  final double totalSpending;
  final double? budgetLimit;
  final String currency;

  const BudgetGraph({
    super.key,
    required this.totalSpending,
    required this.budgetLimit,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOverBudget =
        budgetLimit != null && totalSpending > budgetLimit!;
    final double maxValue =
        (budgetLimit != null) ? (budgetLimit! * 1.2) : (totalSpending * 1.2);

    double spendingBarWidth = (totalSpending / maxValue).clamp(0.0, 1.0);
    double budgetBarWidth =
        budgetLimit != null ? (budgetLimit! / maxValue).clamp(0.0, 1.0) : 0;

    final double maxBarWidth =
        MediaQuery.of(context).size.width - 64; // padding adjustment

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Budget vs Spending',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                Container(
                  height: 30,
                  width: maxBarWidth * budgetBarWidth,
                  decoration: BoxDecoration(
                    color: Colors.pink.shade300,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                Container(
                  height: 30,
                  width: maxBarWidth * spendingBarWidth,
                  decoration: BoxDecoration(
                    color: isOverBudget ? Colors.redAccent : Colors.pinkAccent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spending: $currency${totalSpending.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                ),
                Text(
                  budgetLimit == null
                      ? 'No Budget Limit Set'
                      : 'Budget Limit: $currency${budgetLimit!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverBudget ? Colors.redAccent : Colors.pink,
                  ),
                ),
              ],
            ),
            if (isOverBudget)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'You have exceeded your budget limit!',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
