import 'package:flutter/material.dart';

class ExpenseInput extends StatefulWidget {
  final Function(double amount, String category) onAddExpense;

  const ExpenseInput({super.key, required this.onAddExpense});

  @override
  State<ExpenseInput> createState() => _ExpenseInputState();
}

class _ExpenseInputState extends State<ExpenseInput> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedCategory = 'General'; // Default category

  final List<String> _categories = [
    'General',
    'Food',
    'Transport',
    'Shopping',
    'Utilities',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  void _handleAdd() {
    final value = double.tryParse(_controller.text);
    final category = _selectedCategory ?? 'General';

    if (value != null && value > 0) {
      widget.onAddExpense(value, category);
      _controller.clear();
      setState(() {
        _selectedCategory = 'General'; // Reset to default
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          // Wrap the Column with Expanded
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                // width:
                //     MediaQuery.of(context).size.width *
                //     0.55, // No longer need fixed width here
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Expense Amount',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money_off),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                // width: MediaQuery.of(context).size.width * 0.55, // No longer need fixed width
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items:
                      _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _handleAdd,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
          child: const Text('Add\nExpense', textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
