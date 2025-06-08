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

  // Calculates total spending per category for each year for expenses
  Map<int, Map<String, double>> _calculateYearlyExpenseCategoryTotals(
    List<models.ExpenseEntry> entries,
  ) {
    Map<int, Map<String, double>> yearlyCategoryTotals = {};

    for (var entry in entries) {
      int year = entry.date.year;
      String category = entry.category ?? 'N/A'; // Handle null category

      yearlyCategoryTotals.putIfAbsent(
        year,
        () => {},
      ); // Ensure year map exists
      yearlyCategoryTotals[year]![category] =
          (yearlyCategoryTotals[year]![category] ?? 0) + entry.amount;
    }
    return yearlyCategoryTotals;
  }

  // Helper to calculate simple yearly totals (used for overall year total for expenses/subscriptions)
  Map<int, double> _calculateSimpleYearlyTotals(List<dynamic> entries) {
    Map<int, double> yearlyTotals = {};
    for (var entry in entries) {
      yearlyTotals[entry.date.year] =
          (yearlyTotals[entry.date.year] ?? 0) + entry.amount;
    }
    return yearlyTotals;
  }

  @override
  Widget build(BuildContext context) {
    final expenseTotalsPerYear = _calculateSimpleYearlyTotals(expenses);
    final subscriptionTotalsPerYear = _calculateSimpleYearlyTotals(
      subscriptions,
    );
    final yearlyExpenseCategoryTotals = _calculateYearlyExpenseCategoryTotals(
      expenses,
    );

    final allYears =
        <int>{
            ...expenseTotalsPerYear.keys,
            ...subscriptionTotalsPerYear.keys,
          }.toList()
          ..sort((a, b) => b.compareTo(a)); // Sort years descending

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yearly Spending Summary:',
          style: TextStyle(
            fontSize: 22, // Slightly larger title
            fontWeight: FontWeight.bold,
            color: Colors.pinkAccent, // Use a more vibrant pink
          ),
        ),
        const SizedBox(height: 8),
        ...allYears.map((year) {
          final expenseTotal = expenseTotalsPerYear[year] ?? 0;
          final subscriptionTotal = subscriptionTotalsPerYear[year] ?? 0;
          final total = expenseTotal + subscriptionTotal;
          final categoryBreakdownForYear =
              yearlyExpenseCategoryTotals[year] ?? {};

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 3, // Slightly more elevation for a "lifted" look
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$year Summary',
                    style: TextStyle(
                      fontSize: 20, // Larger year summary title
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(
                            context,
                          ).colorScheme.primary, // Use theme primary color
                    ),
                  ),
                  const Divider(height: 16, thickness: 1), // Add a divider
                  Text(
                    'Total Spending: $currency${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          Colors
                              .black87, // Darker text for better contrast on light theme
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          color: Colors.orange.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expenses: $currency${expenseTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.autorenew,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Subscriptions: $currency${subscriptionTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (categoryBreakdownForYear.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Text(
                        'Expense Breakdown:',
                        style: TextStyle(
                          fontSize: 16, // Slightly larger
                          fontWeight: FontWeight.w600, // Bolder
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.secondary, // Use theme secondary
                        ),
                      ),
                    ),
                    ...categoryBreakdownForYear.entries.map((catEntry) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          top: 3.0,
                          bottom: 3.0,
                        ), // More padding
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween, // Align amount to the right
                          children: [
                            Text(
                              catEntry.key,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              '$currency${catEntry.value.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
