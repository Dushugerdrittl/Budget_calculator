import 'package:flutter/material.dart';

class ExpenseInput extends StatefulWidget {
  final ValueChanged<double> onAddExpense;

  const ExpenseInput({super.key, required this.onAddExpense});

  @override
  State<ExpenseInput> createState() => _ExpenseInputState();
}

class _ExpenseInputState extends State<ExpenseInput> {
  final TextEditingController _controller = TextEditingController();

  void _handleAdd() {
    final value = double.tryParse(_controller.text);
    if (value != null && value > 0) {
      widget.onAddExpense(value);
      _controller.clear();
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
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Add Expense',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.money_off),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _handleAdd,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
