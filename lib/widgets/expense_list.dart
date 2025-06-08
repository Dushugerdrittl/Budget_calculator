import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entries.dart' as models; // Added missing import

class ExpenseList extends StatelessWidget {
  final List<models.ExpenseEntry> expenses;
  final String currency;
  final void Function(int index) onDelete;
  final void Function(int index) onEdit;

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
        ...expenses.asMap().entries.map((entry) {
          int idx = entry.key;
          models.ExpenseEntry e = entry.value; // Assuming models is imported
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            elevation: 2,
            child: ListTile(
              leading: const Icon(
                Icons.receipt_long,
                color: Colors.pinkAccent,
                size: 30,
              ),
              title: Text(
                '$currency${e.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${formatter.format(e.date)}'),
                  Text(
                    'Category: ${e.category ?? 'N/A'}', // Handle null category
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () => onEdit(idx),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => onDelete(idx),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// Make sure you have this import if it's not already there from other changes:
// import '../models/entries.dart' as models;
