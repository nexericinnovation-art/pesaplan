import 'package:flutter/material.dart';

import 'savings_goals_repository.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _initialController = TextEditingController(text: '0');
  DateTime? _deadline;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _initialController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await SavingsGoalsRepository.createGoal(
        clerkUserId: widget.clerkUserId,
        name: _nameController.text.trim(),
        targetAmount: num.parse(_targetController.text.trim()),
        initialAmount: num.tryParse(_initialController.text.trim()) ?? 0,
        deadline: _deadline,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = "Couldn't save this goal. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a goal')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'What are you saving for?', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Give this goal a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Target amount',
                  prefixText: '${widget.currency} ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = num.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) return 'Enter a valid target amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialController,
                decoration: InputDecoration(
                  labelText: 'Already saved (optional)',
                  prefixText: '${widget.currency} ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Deadline (optional)'),
                subtitle: Text(
                  _deadline == null
                      ? 'No deadline set'
                      : '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDeadline,
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
