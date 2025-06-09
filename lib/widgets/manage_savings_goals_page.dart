import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/saving_goal.dart';

class ManageSavingsGoalsPage extends StatefulWidget {
  final String userId;

  const ManageSavingsGoalsPage({super.key, required this.userId});

  @override
  State<ManageSavingsGoalsPage> createState() => _ManageSavingsGoalsPageState();
}

class _ManageSavingsGoalsPageState extends State<ManageSavingsGoalsPage> {
  late Box<SavingGoal> _goalBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  DateTime? _selectedTargetDate;

  @override
  void initState() {
    super.initState();
    _openBox().then((_) {
      _loadGoalsFromFirestore();
    });
  }

  Future<void> _openBox() async {
    final boxName = 'savings_goals_${widget.userId}';
    if (!Hive.isBoxOpen(boxName)) {
      _goalBox = await Hive.openBox<SavingGoal>(boxName);
    } else {
      _goalBox = Hive.box<SavingGoal>(boxName);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadGoalsFromFirestore() async {
    if (!_goalBox.isOpen) await _openBox();
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(widget.userId)
              .collection('savings_goals')
              .orderBy('createdAt', descending: true)
              .get();

      final firestoreGoals =
          querySnapshot.docs
              .map((doc) => SavingGoal.fromFirestore(doc))
              .toList();

      // Basic sync: clear local and add all from Firestore.
      // Consider a more sophisticated sync for offline changes later if needed.
      // await _goalBox.clear(); // Clears all goals before adding new ones
      for (var goal in firestoreGoals) {
        await _goalBox.put(goal.id, goal);
      }

      if (mounted) {
        setState(() {});
        print("Savings goals loaded from Firestore and synced to Hive.");
      }
    } catch (e) {
      print("Error loading savings goals from Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading goals: $e')));
      }
    }
  }

  Future<void> _addOrEditGoalDialog({SavingGoal? existingGoal}) async {
    _nameController.text = existingGoal?.name ?? '';
    _targetAmountController.text = existingGoal?.targetAmount.toString() ?? '';
    _selectedTargetDate = existingGoal?.targetDate;
    final bool isEditing = existingGoal != null;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                      isEditing ? 'Edit Savings Goal' : 'Add New Savings Goal',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Goal Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.flag_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a goal name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _targetAmountController,
                        decoration: InputDecoration(
                          labelText: 'Target Amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a target amount';
                          }
                          if (double.tryParse(value.trim()) == null ||
                              double.parse(value.trim()) <= 0) {
                            return 'Please enter a valid positive amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          _selectedTargetDate == null
                              ? 'Select Target Date (Optional)'
                              : 'Target Date: ${DateFormat.yMd().format(_selectedTargetDate!)}',
                        ),
                        trailing:
                            _selectedTargetDate != null
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setDialogState(() {
                                      _selectedTargetDate = null;
                                    });
                                  },
                                )
                                : null,
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedTargetDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _selectedTargetDate = picked;
                            });
                          }
                        },
                      ),
                    ],
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
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: Text(isEditing ? 'Save' : 'Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final name = _nameController.text.trim();
                      final targetAmount = double.parse(
                        _targetAmountController.text.trim(),
                      );

                      if (isEditing && existingGoal != null) {
                        // Update existing goal
                        final updatedGoal = SavingGoal(
                          id: existingGoal.id,
                          name: name,
                          targetAmount: targetAmount,
                          currentAmount:
                              existingGoal.currentAmount, // Keep current amount
                          targetDate: _selectedTargetDate,
                          userId: widget.userId,
                          createdAt:
                              existingGoal
                                  .createdAt, // Keep original creation date
                        );
                        try {
                          await _firestore
                              .collection('users')
                              .doc(widget.userId)
                              .collection('savings_goals')
                              .doc(updatedGoal.id)
                              .set(
                                updatedGoal.toFirestore(),
                                SetOptions(merge: true),
                              );
                          await _goalBox.put(updatedGoal.id, updatedGoal);
                          if (mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('Goal updated!')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Error updating goal: $e'),
                              ),
                            );
                          }
                        }
                      } else {
                        // Add new goal
                        final newGoalRef =
                            _firestore
                                .collection('users')
                                .doc(widget.userId)
                                .collection('savings_goals')
                                .doc();
                        final newGoal = SavingGoal(
                          id: newGoalRef.id,
                          name: name,
                          targetAmount: targetAmount,
                          currentAmount: 0.0,
                          targetDate: _selectedTargetDate,
                          userId: widget.userId,
                          createdAt: DateTime.now(),
                        );
                        try {
                          await newGoalRef.set(newGoal.toFirestore());
                          await _goalBox.put(newGoal.id, newGoal);
                          if (mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('New goal added!')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Error adding goal: $e')),
                            );
                          }
                        }
                      }
                      Navigator.of(dialogContext).pop();
                      _formKey.currentState?.reset();
                      _nameController.clear();
                      _targetAmountController.clear();
                      _selectedTargetDate = null;
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteGoal(SavingGoal goal) async {
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
                  'Confirm Delete Goal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete the goal "${goal.name}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
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
            .collection('savings_goals')
            .doc(goal.id)
            .delete();
        await _goalBox.delete(goal.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Goal "${goal.name}" deleted.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting goal: $e')));
        }
      }
    }
  }

  Future<void> _addFundsDialog(SavingGoal goal) async {
    final TextEditingController fundsController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text('Add Funds to "${goal.name}"'),
          content: TextField(
            controller: fundsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount to Add',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              prefixIcon: const Icon(Icons.savings_outlined),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Add Funds'),
              onPressed: () async {
                final double? amountToAdd = double.tryParse(
                  fundsController.text,
                );
                if (amountToAdd != null && amountToAdd > 0) {
                  final newCurrentAmount = goal.currentAmount + amountToAdd;
                  final updatedGoal = SavingGoal(
                    id: goal.id,
                    name: goal.name,
                    targetAmount: goal.targetAmount,
                    currentAmount: newCurrentAmount.clamp(
                      0,
                      goal.targetAmount,
                    ), // Ensure it doesn't exceed target
                    targetDate: goal.targetDate,
                    userId: goal.userId,
                    createdAt: goal.createdAt,
                  );
                  try {
                    await _firestore
                        .collection('users')
                        .doc(widget.userId)
                        .collection('savings_goals')
                        .doc(updatedGoal.id)
                        .update({'currentAmount': updatedGoal.currentAmount});
                    await _goalBox.put(updatedGoal.id, updatedGoal);
                    if (mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Funds added!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Error adding funds: $e')),
                      );
                    }
                  }
                  Navigator.of(dialogContext).pop();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid positive amount.'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Savings Goals'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          !_goalBox.isOpen
              ? const Center(child: CircularProgressIndicator())
              : ValueListenableBuilder<Box<SavingGoal>>(
                valueListenable: _goalBox.listenable(),
                builder: (context, box, _) {
                  final goals =
                      box.values.toList()..sort(
                        (a, b) => b.createdAt.compareTo(a.createdAt),
                      ); // Newest first

                  if (goals.isEmpty) {
                    return const Center(
                      child: Text('No savings goals yet. Create one!'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      goal.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        onPressed:
                                            () => _addOrEditGoalDialog(
                                              existingGoal: goal,
                                            ),
                                        tooltip: 'Edit Goal',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                        ),
                                        onPressed: () => _deleteGoal(goal),
                                        tooltip: 'Delete Goal',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Target: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(goal.targetAmount)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Saved: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(goal.currentAmount)} (${goal.progressFormatted})',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              if (goal.targetDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Target Date: ${DateFormat.yMd().format(goal.targetDate!)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: goal.progressPercentage,
                                backgroundColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                                minHeight: 10,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.add_card_outlined),
                                  label: const Text('Add Funds'),
                                  onPressed: () => _addFundsDialog(goal),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditGoalDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
