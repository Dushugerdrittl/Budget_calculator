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

  SubscriptionEntry({
    required this.name,
    required this.amount,
    required this.date,
    this.firestoreId,
  });
}
