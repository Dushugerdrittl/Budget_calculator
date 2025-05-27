import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entries.dart' as models;

class SubscriptionList extends StatelessWidget {
  final List<models.SubscriptionEntry> subscriptions;
  final String currency;
  final void Function(int index) onDelete;
  final void Function(int index) onEdit;

  const SubscriptionList({
    super.key,
    required this.subscriptions,
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
          'Subscriptions:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        ...subscriptions.asMap().entries.map((entry) {
          int idx = entry.key;
          models.SubscriptionEntry s = entry.value;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.pink.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    s.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.pink,
                    ),
                  ),
                ),
                Text(
                  formatter.format(s.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$currency${s.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.pink),
                  onPressed: () => onEdit(idx),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => onDelete(idx),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
