import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // For ValueListenableBuilder and Hive.box
import '../models/category.dart'; // Import your Category model

class ExpenseInput extends StatefulWidget {
  final Function(double amount, String category) onAddExpense;
  final String userId; // Add userId

  const ExpenseInput({
    super.key,
    required this.onAddExpense,
    required this.userId, // Make userId required
  });

  @override
  State<ExpenseInput> createState() => _ExpenseInputState();
}

class _ExpenseInputState extends State<ExpenseInput> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategoryName; // Store the name of the selected category

  void _handleAdd() {
    final enteredAmount = double.tryParse(_amountController.text);

    if (enteredAmount == null ||
        enteredAmount <= 0 ||
        _selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount and select a category.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    widget.onAddExpense(enteredAmount, _selectedCategoryName!);
    _amountController.clear();
    // Optionally reset _selectedCategoryName or keep it for next entry
    // setState(() { _selectedCategoryName = null; });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
      children: [
        Expanded(
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Column takes minimum vertical space
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Expense Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money_off),
                ),
                onSubmitted:
                    (_) => _handleAdd(), // Allow submitting with enter key
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<Box<Category>>(
                valueListenable:
                    Hive.box<Category>(
                      'categories_${widget.userId}',
                    ).listenable(),
                builder: (context, categoryBox, _) {
                  final categories =
                      categoryBox.values.toList()..sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
                      );

                  // Ensure _selectedCategoryName is still valid or reset it
                  if (_selectedCategoryName != null &&
                      !categories.any((c) => c.name == _selectedCategoryName)) {
                    // Use addPostFrameCallback to avoid calling setState during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        // Check if the widget is still in the tree
                        setState(() {
                          _selectedCategoryName = null;
                        });
                      }
                    });
                  }

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.category),
                      hintText:
                          categories.isEmpty
                              ? 'No categories available'
                              : 'Select Category',
                    ),
                    value: _selectedCategoryName,
                    isExpanded: true,
                    items:
                        categories.map((Category category) {
                          return DropdownMenuItem<String>(
                            value: category.name, // Use category name as value
                            child: Text(category.name),
                          );
                        }).toList(),
                    onChanged:
                        categories.isEmpty
                            ? null
                            : (String? newValue) {
                              setState(() {
                                _selectedCategoryName = newValue;
                              });
                            },
                    validator:
                        (value) =>
                            value == null ? 'Please select a category' : null,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _handleAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ), // Adjust padding
            minimumSize: const Size(
              0,
              50,
            ), // Ensure button has reasonable height
          ),
          child: const Text('Add\nExpense', textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
