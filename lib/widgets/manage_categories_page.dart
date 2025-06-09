import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  final TextEditingController _categoryBudgetController =
      TextEditingController(); // Controller for budget
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _openBox().then((_) {
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
    if (mounted) {
      setState(() {});
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
        await _openBox();
        print(
          "Category box was not open during Firestore load. This shouldn't happen if _openBox is called in initState.",
        );
        return;
      }

      final firestoreCategories =
          querySnapshot.docs.map((doc) {
            return Category.fromFirestore(doc); // Use factory constructor
          }).toList();

      for (var category in firestoreCategories) {
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

  Future<void> _addOrEditCategoryDialog({Category? existingCategory}) async {
    final bool isEditing = existingCategory != null;
    _categoryNameController.text = existingCategory?.name ?? '';
    _categoryBudgetController.text =
        existingCategory?.budget?.toStringAsFixed(2) ?? ''; // Format budget

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Use a local controller for the dialog to avoid issues if the main controller is cleared prematurely
        final TextEditingController localNameController = TextEditingController(
          text: _categoryNameController.text,
        );
        final TextEditingController localBudgetController =
            TextEditingController(text: _categoryBudgetController.text);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_note : Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing ? 'Edit Category' : 'Add New Category',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: localNameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: "Category Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: localBudgetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: "Monthly Budget (Optional)",
                    hintText: "e.g., 100.00",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                  ),
                ),
              ],
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
                Navigator.of(dialogContext).pop(); // Pop with no result
              },
            ),
            ElevatedButton(
              child: Text(isEditing ? 'Save' : 'Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                final name = localNameController.text.trim();
                final budgetStr = localBudgetController.text.trim();
                double? budgetValue;
                if (budgetStr.isNotEmpty) {
                  budgetValue = double.tryParse(budgetStr);
                  if (budgetValue == null || budgetValue < 0) {
                    // Basic validation for budget
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid positive budget or leave it empty.',
                        ),
                      ),
                    );
                    return;
                  }
                }

                if (name.isNotEmpty) {
                  Navigator.of(
                    dialogContext,
                  ).pop({'name': name, 'budget': budgetValue});
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Category name cannot be empty.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      final categoryName = result['name'] as String?;
      final categoryBudget = result['budget'] as double?;

      if (categoryName != null && categoryName.isNotEmpty) {
        final existing = _categoryBox.values.any(
          (cat) =>
              cat.name.toLowerCase() == categoryName.toLowerCase() &&
              (!isEditing || cat.id != existingCategory?.id),
        );

        if (existing) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "$categoryName" already exists.')),
          );
          return;
        }

        if (isEditing && existingCategory != null) {
          final updatedCategory = Category(
            id: existingCategory.id,
            name: categoryName,
            userId: widget.userId,
            budget: categoryBudget,
          );
          try {
            await _firestore
                .collection('users')
                .doc(widget.userId)
                .collection('categories')
                .doc(updatedCategory.id)
                .set(updatedCategory.toFirestore(), SetOptions(merge: true));
            await _categoryBox.put(updatedCategory.id, updatedCategory);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category "${updatedCategory.name}" updated.'),
                ),
              );
            }
          } catch (e) {
            print("Error updating category: $e");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating category: $e')),
              );
            }
          }
        } else {
          // Add new category
          try {
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
              budget: categoryBudget,
            );

            await newCategoryRef.set(newCategory.toFirestore());
            await _categoryBox.put(newCategory.id, newCategory);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Category "$categoryName" added.')),
              );
            }
          } catch (e) {
            print("Error adding category: $e");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add category: $e')),
              );
            }
          }
        }
      }
    }
    // Clear main controllers after dialog is closed, regardless of result
    _categoryNameController.clear();
    _categoryBudgetController.clear();
  }

  Future<void> _deleteCategory(Category category) async {
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
        await _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('categories')
            .doc(category.id)
            .delete();
        await _categoryBox.delete(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "${category.name}" deleted.')),
          );
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
                  final categories =
                      box.values.toList()..sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
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
                          subtitle:
                              category.budget != null
                                  ? Text(
                                    'Budget: \$${category.budget!.toStringAsFixed(2)}', // Assuming USD for now
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                    ),
                                  )
                                  : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed:
                                    () => _addOrEditCategoryDialog(
                                      existingCategory: category,
                                    ),
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
        onPressed: () => _addOrEditCategoryDialog(),
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }
}
