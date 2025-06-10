import 'package:hive/hive.dart';

part 'entries.g.dart';

@HiveType(typeId: 0)
class ExpenseEntry extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  DateTime date;

  @HiveField(2) // New field for category
  String? category; // Make category nullable

  @HiveField(3) // New field for Firestore document ID
  String? firestoreId; // Optional: to store Firestore document ID

  ExpenseEntry({
    required this.amount,
    required this.date,
    this.category = 'General', // Default category still applies for new entries
    this.firestoreId,
  });
}

@HiveType(typeId: 1)
class SubscriptionEntry extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3) // New field for Firestore document ID
  String? firestoreId; // Optional: to store Firestore document ID

  @HiveField(4) // New field for the next due date of the subscription
  DateTime? nextDueDate;

  @HiveField(
    5,
  ) // New field to track if a reminder has been scheduled for the current nextDueDate
  bool? reminderScheduled;

  @HiveField(
    6,
  ) // New field to control if reminders are enabled for this subscription
  bool? enableReminder;

  SubscriptionEntry({
    required this.name,
    required this.amount,
    required this.date,
    this.firestoreId,
    this.nextDueDate,
    this.reminderScheduled,
    this.enableReminder = false, // Default to false for new entries
  }) {
    // Ensure nextDueDate has a default if not provided
    nextDueDate = nextDueDate ?? date;
  }

  // Helper to advance the next due date by one month
  // Call this after a payment is made or a reminder is acknowledged
  void advanceNextDueDate() {
    if (nextDueDate == null) {
      return; // Or handle appropriately, e.g., set to DateTime.now() then advance
    }
    nextDueDate = DateTime(
      nextDueDate!.year,
      nextDueDate!.month + 1,
      nextDueDate!.day,
    );
    reminderScheduled = false; // Explicitly set to false after advancing
  }
}
