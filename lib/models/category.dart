import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'category.g.dart'; // For Hive code generation

@HiveType(typeId: 2) // Ensure typeId is unique in your Hive setup
class Category extends HiveObject {
  @HiveField(0)
  String id; // Firestore document ID

  @HiveField(1)
  String name;

  @HiveField(2)
  String userId;

  @HiveField(3) // New field for category-specific budget
  double? budget; // Optional budget for the category

  Category({
    required this.id,
    required this.name,
    required this.userId,
    this.budget,
  });

  // Factory constructor to create a Category from a Firestore document
  factory Category.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return Category(
      id: snapshot.id,
      name: data?['name'] ?? '',
      userId: data?['userId'] ?? '',
      budget: (data?['budget'] as num?)?.toDouble(), // Load budget
    );
  }

  // Method to convert a Category instance to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'userId': userId,
      'budget': budget, // Save budget
      // 'createdAt': FieldValue.serverTimestamp(), // Optional: if you want to track creation time
    };
  }
}
