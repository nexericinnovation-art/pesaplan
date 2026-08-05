import 'package:flutter/material.dart';

import 'savings_goals_repository.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({super.key, required this.goal, required this.clerkUserId, required this.currency});

  final SavingsGoalRecord goal;
  final String clerkUserId;
  final String currency;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late SavingsGoalRecord _goal;
  List<GoalContributionRecord> _contributions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() => _isLoading = true);
    try {
      final contributions = await SavingsGoalsRepository.fetchContributions(
        goalId: _goal.id,
        clerkUserId: widget.clerkUserId,
      );
      if (!mounted) return;
      setState(() {
        _contributions = contributions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load this goal's history.";
      });
    }
  }

  Future<void> _openContributionDialog(String type) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final result = await showDialog<num>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'deposit' ? 'Add money' : 'Withdraw money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              autofocus: true,
              decoration: InputDecoration(labelText: 'Amount', prefixText: '${widget.currency} '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final amount = num.tryParse(amountController.text.trim());
              Navigator.pop(context, amount);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (result == null || result <= 0) return;

    try {
      final updatedGoal = await SavingsGoalsRepository.addContribution(
        goalId: _goal.id,
        clerkUserId: widget.clerkUserId,
        amount: result,
        contributionType: type,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _goal = updatedGoal);
      _loadContributions();
    } catch (error) {
      if (!mounted) return;
      final message = type == 'withdrawal' && error.toString().contains('exceeds')
          ? "You can't withdraw more than you've saved."
          : "Couldn't record that. Try again.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _setStatus(String status) async {
    try {
      final updated = await SavingsGoalsRepository.setStatus(
        goalId: _goal.id,
        clerkUserId: widget.clerkUserId,
        status: status,
      );
      if (!mounted) return;
      setState(() => _goal = updated);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't update this goal.")));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this goal?'),
        content: const Text('This permanently deletes the goal and its contribution history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await SavingsGoalsRepository.deleteGoal(goalId: _goal.id, clerkUserId: widget.clerkUserId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't delete this goal.")));
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _money(num value) => '${widget.currency} ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final required = _goal.requiredMonthlyAmount;
    final onTrack = _goal.isOnTrack;

    return Scaffold(
      appBar: AppBar(
        title: Text(_goal.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete();
              } else {
                _setStatus(value);
              }
            },
            itemBuilder: (context) => [
              if (_goal.status != 'active') const PopupMenuItem(value: 'active', child: Text('Resume')),
              if (_goal.status == 'active') const PopupMenuItem(value: 'paused', child: Text('Pause')),
              if (_goal.status != 'completed') const PopupMenuItem(value: 'completed', child: Text('Mark complete')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadContributions,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_money(_goal.currentAmount)} of ${_money(_goal.targetAmount)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: _goal.percentComplete, minHeight: 10),
                      ),
                      const SizedBox(height: 8),
                      Text('${(_goal.percentComplete * 100).toStringAsFixed(0)}% complete'),
                      if (_goal.deadline != null) ...[
                        const SizedBox(height: 4),
                        Text('Deadline: ${_formatDate(_goal.deadline!)}'),
                      ],
                      const SizedBox(height: 12),
                      if (required != null)
                        Text(
                          onTrack == true
                              ? "You're on track."
                              : 'You need to save ${_money(required)} more per month to reach your target.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: onTrack == true ? Colors.green.shade700 : Colors.orange.shade800,
                          ),
                        )
                      else if (_goal.deadline == null)
                        const Text("Set a deadline to see whether you're on track.")
                      else
                        const Text("This goal's deadline has passed."),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openContributionDialog('deposit'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add money'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openContributionDialog('withdrawal'),
                      icon: const Icon(Icons.remove),
                      label: const Text('Withdraw'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('History', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Text(_errorMessage!)
              else if (_contributions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No contributions yet.'),
                )
              else
                ..._contributions.map((c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        c.contributionType == 'deposit' ? Icons.add_circle_outline : Icons.remove_circle_outline,
                        color: c.contributionType == 'deposit' ? Colors.green.shade700 : Colors.orange.shade800,
                      ),
                      title: Text('${c.contributionType == 'deposit' ? '+' : '-'}${_money(c.amount)}'),
                      subtitle: Text(c.note?.isNotEmpty == true ? c.note! : _formatDate(c.createdAt)),
                      trailing: Text(_formatDate(c.createdAt)),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
