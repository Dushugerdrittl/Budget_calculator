import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'saving_goal.g.dart'; // Will be generated

@HiveType(
  typeId: 3,
) // Ensure this typeId is unique (0 for Expense, 1 for Subscription, 2 for Category)
class SavingGoal extends HiveObject {
  @HiveField(0)
  String id; // Firestore document ID

  @HiveField(1)
  String name;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  double currentAmount;

  @HiveField(4)
  DateTime? targetDate; // Optional

  @HiveField(5)
  String userId;

  @HiveField(6)
  DateTime createdAt;

  SavingGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    required this.userId,
    required this.createdAt,
  });

  // Factory constructor to create a SavingGoal from a Firestore document
  factory SavingGoal.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Saving goal data is null in Firestore snapshot!");
    }
    return SavingGoal(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Unnamed Goal',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: (data['targetDate'] as Timestamp?)?.toDate(),
      userId: data['userId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Method to convert a SavingGoal instance to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  String get progressFormatted {
    return "${(progressPercentage * 100).toStringAsFixed(1)}%";
  }
}
