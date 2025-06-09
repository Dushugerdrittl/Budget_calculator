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

  Category({required this.id, required this.name, required this.userId});

  // Factory constructor to create a Category from a Firestore document
  factory Category.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return Category(
      id: snapshot.id,
      name: data?['name'] ?? '',
      userId: data?['userId'] ?? '',
    );
  }

  // Method to convert a Category instance to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'userId': userId,
      // 'createdAt': FieldValue.serverTimestamp(), // Optional: if you want to track creation time
    };
  }
}
