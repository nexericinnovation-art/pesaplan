import 'package:flutter/material.dart';

import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';
import 'savings_goals_repository.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  List<SavingsGoalRecord> _goals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final goals = await SavingsGoalsRepository.fetchGoals(clerkUserId: widget.clerkUserId);
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load your goals. Check your connection and try again.";
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateGoalScreen(clerkUserId: widget.clerkUserId, currency: widget.currency),
      ),
    );
    if (created == true) _load();
  }

  Future<void> _openDetail(SavingsGoalRecord goal) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoalDetailScreen(goal: goal, clerkUserId: widget.clerkUserId, currency: widget.currency),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    if (_goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Start planning for something important.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add),
                label: const Text('Create a goal'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _goals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final goal = _goals[index];
          return Card(
            child: ListTile(
              onTap: () => _openDetail(goal),
              title: Text(goal.name),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: goal.percentComplete),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.currency} ${goal.currentAmount.toStringAsFixed(0)} of '
                      '${widget.currency} ${goal.targetAmount.toStringAsFixed(0)}'
                      '${goal.status != 'active' ? ' • ${goal.status}' : ''}',
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
