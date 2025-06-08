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

  ExpenseEntry({
    required this.amount,
    required this.date,
    this.category = 'General', // Default category still applies for new entries
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

  SubscriptionEntry({
    required this.name,
    required this.amount,
    required this.date,
  });
}
