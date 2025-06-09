import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class SubscriptionInput extends StatefulWidget {
  final void Function(
    String name,
    double amount,
    bool enableReminder,
    DateTime nextDueDate,
  )
  onAddSubscription;

  const SubscriptionInput({super.key, required this.onAddSubscription});

  @override
  State<SubscriptionInput> createState() => _SubscriptionInputState();
}

class _SubscriptionInputState extends State<SubscriptionInput> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _enableReminderForNewSub = false; // State for the reminder switch
  DateTime _selectedNextDueDate =
      DateTime.now(); // State for the selected due date

  void _submit() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text);
    if (name.isNotEmpty && amount != null && amount > 0) {
      widget.onAddSubscription(
        name,
        amount,
        _enableReminderForNewSub,
        _selectedNextDueDate,
      );
      _nameController.clear();
      _amountController.clear();
      setState(() {
        _enableReminderForNewSub = false; // Reset switch
        _selectedNextDueDate = DateTime.now(); // Reset date picker
      });
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
        ListTile(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          leading: const Icon(Icons.calendar_today),
          title: Text(
            'Next Due Date: ${DateFormat.yMd().format(_selectedNextDueDate)}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_calendar_outlined),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedNextDueDate,
                firstDate: DateTime.now(), // User can't select past dates
                lastDate: DateTime(
                  DateTime.now().year + 5,
                ), // Allow up to 5 years in future
              );
              if (picked != null && picked != _selectedNextDueDate) {
                setState(() {
                  _selectedNextDueDate = picked;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Enable Reminder'),
          value: _enableReminderForNewSub,
          onChanged: (bool value) {
            setState(() {
              _enableReminderForNewSub = value;
            });
          },
          activeColor: Colors.pinkAccent,
          contentPadding: EdgeInsets.zero,
          dense: true,
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
