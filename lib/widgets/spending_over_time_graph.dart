import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/entries.dart' as models;

class SpendingOverTimeGraph extends StatelessWidget {
  final List<models.ExpenseEntry> expenses;
  final String period; // 'daily', 'weekly', 'monthly', 'yearly'
  final String currency;

  const SpendingOverTimeGraph({
    super.key,
    required this.expenses,
    required this.period,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    // Aggregate expenses based on the selected period
    Map<dynamic, double> aggregatedSpending = {};

    for (var expense in expenses) {
      dynamic key;
      switch (period) {
        case 'daily':
          key = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          break;
        case 'weekly':
          // Find the start of the week (e.g., Monday)
          final date = expense.date;
          final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
          key = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          break;
        case 'monthly':
          key = DateTime(expense.date.year, expense.date.month);
          break;
        case 'yearly':
          key = expense.date.year;
          break;
        default:
          key = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
      }
      aggregatedSpending[key] = (aggregatedSpending[key] ?? 0) + expense.amount;
    }

    // Sort the keys (dates/years) for proper display order
    final sortedKeys = aggregatedSpending.keys.toList();
    if (sortedKeys.isNotEmpty && sortedKeys.first is DateTime) {
      sortedKeys.sort((a, b) => a.compareTo(b));
    } else if (sortedKeys.isNotEmpty && sortedKeys.first is int) {
      sortedKeys.sort((a, b) => a.compareTo(b));
    }

    // Prepare data for the Bar Chart
    final List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final amount = aggregatedSpending[key] ?? 0;
      if (amount > maxY) maxY = amount;

      barGroups.add(
        BarChartGroupData(
          x: i, // Use index as x-value
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Theme.of(context).colorScheme.primary, // Use theme color
              width: 16, // Adjust bar width
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    // Add some padding to maxY, ensure it's at least a small value if all amounts are 0
    if (maxY == 0 && barGroups.isNotEmpty) {
      // If there are bars but all are 0
      maxY = 10; // Default maxY so the chart renders
    } else {
      maxY = maxY * 1.2;
    }

    return AspectRatio(
      aspectRatio: 1.8, // Adjust aspect ratio
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              barGroups.isEmpty
                  ? Center(
                    child: Text(
                      'No spending data for this period.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                  : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < sortedKeys.length) {
                                final key = sortedKeys[index];
                                String label;
                                if (key is DateTime) {
                                  switch (period) {
                                    case 'daily':
                                      label = DateFormat.Md().format(
                                        key,
                                      ); // e.g., 6/10
                                      break;
                                    case 'weekly':
                                      label = DateFormat.Md().format(
                                        key,
                                      ); // Start of week
                                      break;
                                    case 'monthly':
                                      label = DateFormat.yM().format(
                                        key,
                                      ); // e.g., 2025/6
                                      break;
                                    default:
                                      label = '';
                                  }
                                } else if (key is int) {
                                  // Yearly
                                  label = key.toString();
                                } else {
                                  label = '';
                                }

                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 4.0,
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Container(),
                              );
                            },
                            reservedSize: 20,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (maxY <= 0)
                                return const Text(
                                  '',
                                ); // Don't show labels if no data or all zero

                              // Show labels at reasonable intervals or at specific points
                              // This is a simple example; fl_chart has more advanced interval logic
                              // if you let it auto-calculate by not providing getTitlesWidget or by setting interval.
                              if (value == 0 ||
                                  value == meta.max ||
                                  (value == meta.max / 2 && meta.max > 0)) {
                                return Text(
                                  NumberFormat.compact().format(
                                    value.toInt(),
                                  ), // Use compact format for large numbers
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: false, // Hide border
                      ),
                      gridData: const FlGridData(
                        show: false,
                      ), // Hide grid lines
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (BarChartGroupData group) {
                            return Colors
                                .blueGrey; // Your desired tooltip background color
                          },
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final key = sortedKeys[group.x];
                            String labelPrefix;
                            if (key is DateTime) {
                              switch (period) {
                                case 'daily':
                                  labelPrefix = DateFormat.yMd().format(key);
                                  break;
                                case 'weekly':
                                  final endOfWeek = key.add(
                                    const Duration(days: 6),
                                  );
                                  labelPrefix =
                                      '${DateFormat.yMd().format(key)} - ${DateFormat.yMd().format(endOfWeek)}';
                                  break;
                                case 'monthly':
                                  labelPrefix = DateFormat.yMMMM().format(key);
                                  break;
                                default: // Should not happen with defined periods
                                  labelPrefix = key.toString();
                              }
                            } else if (key is int) {
                              // Yearly
                              labelPrefix = key.toString();
                            } else {
                              labelPrefix = 'Period';
                            }

                            return BarTooltipItem(
                              '$labelPrefix\n${currency}${rod.toY.toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
        ),
      ),
    );
  }
}
