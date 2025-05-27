import 'package:flutter/material.dart';

class TotalBudgetDisplay extends StatelessWidget {
  final double totalBudget;
  final String currency;

  const TotalBudgetDisplay({
    super.key,
    required this.totalBudget,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Total Monthly Budget: $currency${totalBudget.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
