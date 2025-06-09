import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Not strictly needed if userId is passed
import '../models/category.dart';

class ManageCategoriesPage extends StatefulWidget {
  final String userId;

  const ManageCategoriesPage({super.key, required this.userId});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  late Box<Category> _categoryBox;
  final TextEditingController _categoryNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _openBox().then((_) {
      // After the box is open, load categories from Firestore
      _loadCategoriesFromFirestore();
    });
  }

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen('categories_${widget.userId}')) {
      _categoryBox = await Hive.openBox<Category>(
        'categories_${widget.userId}',
      );
    } else {
      _categoryBox = Hive.box<Category>('categories_${widget.userId}');
    }
    // No need to call _loadCategoriesFromFirestore here if ValueListenableBuilder handles updates
    if (mounted) {
      setState(() {}); // To rebuild with the opened box
    }
  }

  Future<void> _loadCategoriesFromFirestore() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(widget.userId)
              .collection('categories')
              .get();

      if (!_categoryBox.isOpen) {
        // Ensure box is open before writing
        await _openBox();
        print(
          "Category box was not open during Firestore load. This shouldn't happen if _openBox is called in initState.",
        );
        return;
      }

      final firestoreCategories =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return Category(
              id: doc.id,
              name: data['name'],
              userId: data['userId'],
            );
          }).toList();

      for (var category in firestoreCategories) {
        // Add or update in Hive. Using ID as key.
        await _categoryBox.put(category.id, category);
      }

      if (mounted) {
        setState(() {});
        print("Categories loaded/refreshed from Firestore and synced to Hive.");
      }
    } catch (e) {
      print("Error loading categories from Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
      }
    }
  }

  Future<void> _addCategoryDialog() async {
    _categoryNameController.clear();
    String? categoryName = await showDialog<String>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Add New Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
          content: SingleChildScrollView(
            child: TextField(
              controller: _categoryNameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: "Category Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          actionsPadding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                final name = _categoryNameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop(name);
                }
              },
            ),
          ],
        );
      },
    );

    if (categoryName != null && categoryName.isNotEmpty) {
      // Check for duplicates (case-insensitive) in Hive box
      final existing = _categoryBox.values.any(
        (cat) => cat.name.toLowerCase() == categoryName.toLowerCase(),
      );
      if (existing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "$categoryName" already exists.')),
        );
        return;
      }

      try {
        // Create a new document reference to get an ID
        final newCategoryRef =
            _firestore
                .collection('users')
                .doc(widget.userId)
                .collection('categories')
                .doc();

        final newCategory = Category(
          id: newCategoryRef.id,
          name: categoryName,
          userId: widget.userId,
        );

        // Add to Firestore
        await newCategoryRef.set({
          'name': newCategory.name,
          'userId':
              newCategory
                  .userId, // Storing userId for potential cross-user queries (though rules prevent)
        });
        // Add to Hive, using Firestore ID as key
        await _categoryBox.put(newCategory.id, newCategory);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "$categoryName" added.')),
          );
          // ValueListenableBuilder will automatically update the UI
        }
      } catch (e) {
        print("Error adding category: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to add category: $e')));
        }
      }
    }
  }

  Future<void> _editCategoryDialog(Category category) async {
    _categoryNameController.text = category.name; // Pre-fill current name
    String? updatedName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit_note,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Edit Category "${category.name}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
          content: SingleChildScrollView(
            child: TextField(
              controller: _categoryNameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: "New Category Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          actionsPadding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                final name = _categoryNameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop(name);
                }
              },
            ),
          ],
        );
      },
    );

    if (updatedName != null &&
        updatedName.isNotEmpty &&
        updatedName != category.name) {
      // Check for duplicates (case-insensitive) - excluding the current category being edited
      final existing = _categoryBox.values.any(
        (cat) =>
            cat.id != category.id &&
            cat.name.toLowerCase() == updatedName.toLowerCase(),
      );
      if (existing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Another category with the name "$updatedName" already exists.',
            ),
          ),
        );
        return;
      }

      final updatedCategory = Category(
        id: category.id,
        name: updatedName,
        userId: category.userId,
      );

      try {
        // Update in Firestore
        await _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('categories')
            .doc(category.id)
            .update({'name': updatedName});

        // Update in Hive
        await _categoryBox.put(category.id, updatedCategory);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Category "${category.name}" updated to "$updatedName".',
              ),
            ),
          );
          // ValueListenableBuilder will update the UI
        }
      } catch (e) {
        print("Error updating category: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating category: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    // TODO: Consider implications: What happens to expenses/subscriptions using this category?
    // For now, we'll just delete the category.
    // A more robust solution might involve:
    // 1. Preventing deletion if in use.
    // 2. Allowing re-assignment of expenses/subscriptions.
    // 3. Marking category as "archived" instead of deleting.

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Confirm Delete',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
          content: Text(
            'Are you sure you want to delete the category "${category.name}"? This action cannot be undone.',
            style: const TextStyle(fontSize: 16.0),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          actionsPadding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Delete from Firestore
        await _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('categories')
            .doc(category.id)
            .delete();

        // Delete from Hive
        await _categoryBox.delete(category.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "${category.name}" deleted.')),
          );
          // ValueListenableBuilder will update the UI
        }
      } catch (e) {
        print("Error deleting category: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting category: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          !_categoryBox.isOpen
              ? const Center(child: CircularProgressIndicator())
              : ValueListenableBuilder<Box<Category>>(
                valueListenable: _categoryBox.listenable(),
                builder: (context, box, _) {
                  final categories = box.values.toList();
                  // Sort categories alphabetically by name (case-insensitive)
                  categories.sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );

                  if (categories.isEmpty) {
                    return const Center(
                      child: Text('No categories yet. Add one!'),
                    );
                  }
                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(category.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () => _editCategoryDialog(category),
                                tooltip: 'Edit Category',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                onPressed: () => _deleteCategory(category),
                                tooltip: 'Delete Category',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategoryDialog,
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }
}
