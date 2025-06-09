import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entries.dart' as models;

class SubscriptionList extends StatelessWidget {
  final List<models.SubscriptionEntry> subscriptions;
  final String currency;
  final void Function(int index) onDelete;
  final void Function(int index) onEdit;
  final void Function(int index) onMarkAsPaid; // Callback for marking as paid

  const SubscriptionList({
    super.key,
    required this.subscriptions,
    required this.currency,
    required this.onDelete,
    required this.onEdit,
    required this.onMarkAsPaid,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subscriptions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              'Subscriptions:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ...subscriptions.asMap().entries.map((entry) {
          int idx = entry.key;
          models.SubscriptionEntry s = entry.value;
          bool isReminderEnabled = s.enableReminder ?? false;
          bool isReminderScheduled = s.reminderScheduled ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            elevation: 2,
            child: ListTile(
              leading: Icon(
                Icons.autorenew, // Changed icon for subscriptions
                color: Theme.of(context).colorScheme.secondary,
                size: 30,
              ),
              title: Text(
                s.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount: $currency${s.amount.toStringAsFixed(2)}'),
                  Text(
                    'Next Due: ${s.nextDueDate != null ? formatter.format(s.nextDueDate!) : 'N/A'}',
                  ),
                  if (isReminderEnabled)
                    Text(
                      isReminderScheduled
                          ? 'Reminder Scheduled'
                          : 'Reminder Pending (App Restart)',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color:
                            isReminderScheduled ? Colors.green : Colors.orange,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.payment,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Mark as Paid & Advance Due Date',
                    onPressed: () => onMarkAsPaid(idx),
                  ),
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
