import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entries.dart' as models;
import 'animated_list_item.dart'; // Import the animation widget

class ExpenseList extends StatelessWidget {
  final List<models.ExpenseEntry> expenses;
  final String currency;
  final void Function(models.ExpenseEntry expense) onDelete; // Changed
  final void Function(models.ExpenseEntry expense) onEdit; // Changed

  const ExpenseList({
    super.key,
    required this.expenses,
    required this.currency,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    if (expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No expenses recorded yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expenses:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        ListView.builder(
          shrinkWrap: true, // Important if inside a SingleChildScrollView
          physics:
              const NeverScrollableScrollPhysics(), // To prevent nested scrolling issues
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return AnimatedListItem(
              // Wrap Card/ListTile with AnimatedListItem
              index: index,
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(
                    Icons.receipt_long,
                    color: Colors.pinkAccent,
                    size: 30,
                  ),
                  title: Text(
                    '$currency${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${formatter.format(expense.date)}'),
                      Text(
                        'Category: ${expense.category ?? 'N/A'}', // Handle null category
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => onEdit(expense), // Pass object
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => onDelete(expense), // Pass object
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
