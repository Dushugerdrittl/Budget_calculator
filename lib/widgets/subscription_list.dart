import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entries.dart' as models;
import 'animated_list_item.dart'; // Import the animation widget

class SubscriptionList extends StatelessWidget {
  final List<models.SubscriptionEntry> subscriptions;
  final String currency;
  final void Function(models.SubscriptionEntry subscription)
  onDelete; // Changed
  final void Function(models.SubscriptionEntry subscription) onEdit; // Changed
  final void Function(models.SubscriptionEntry subscription)
  onMarkAsPaid; // Changed

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
    if (subscriptions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No subscriptions recorded yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ListView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // To prevent nested scrolling issues
          itemCount: subscriptions.length,
          itemBuilder: (context, index) {
            final subscription = subscriptions[index];
            bool isReminderEnabled = subscription.enableReminder ?? false;
            bool isReminderScheduled = subscription.reminderScheduled ?? false;

            return AnimatedListItem(
              // Wrap Card/ListTile with AnimatedListItem
              index: index,
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    Icons.autorenew, // Changed icon for subscriptions
                    color: Theme.of(context).colorScheme.secondary,
                    size: 30,
                  ),
                  title: Text(
                    subscription.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount: $currency${subscription.amount.toStringAsFixed(2)}',
                      ),
                      Text(
                        'Next Due: ${subscription.nextDueDate != null ? formatter.format(subscription.nextDueDate!) : 'N/A'}',
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
                                isReminderScheduled
                                    ? Colors.green
                                    : Colors.orange,
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
                        onPressed:
                            () => onMarkAsPaid(subscription), // Pass object
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => onEdit(subscription), // Pass object
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => onDelete(subscription), // Pass object
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
