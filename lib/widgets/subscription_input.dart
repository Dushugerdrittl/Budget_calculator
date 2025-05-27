import 'package:flutter/material.dart';

class SubscriptionInput extends StatefulWidget {
  final void Function(String name, double amount) onAddSubscription;

  const SubscriptionInput({super.key, required this.onAddSubscription});

  @override
  State<SubscriptionInput> createState() => _SubscriptionInputState();
}

class _SubscriptionInputState extends State<SubscriptionInput> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  void _submit() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text);
    if (name.isNotEmpty && amount != null && amount > 0) {
      widget.onAddSubscription(name, amount);
      _nameController.clear();
      _amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Subscription',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Subscription Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.subscriptions),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
