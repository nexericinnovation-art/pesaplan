import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../core/services/auth_identity_service.dart';
import '../../core/services/supabase_service.dart';

/// Currencies we support today. The schema itself isn't limited to these —
/// `profiles.currency` is a free-text column — this list is just what the
/// picker offers so we don't ship a currency the rest of the app can't
/// format correctly yet.
const _supportedCurrencies = ['KES', 'USD', 'UGX', 'TZS', 'NGN', 'GHS', 'ZAR'];

const _budgetingMethods = [
  '50/30/20 rule',
  'Zero-based budgeting',
  'Envelope method',
  'Pay yourself first',
  'Not sure yet',
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.clerkUserId, required this.onComplete});

  final String clerkUserId;
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _countryController = TextEditingController(text: 'Kenya');
  final _monthlyIncomeController = TextEditingController();
  final _monthlySavingsTargetController = TextEditingController();
  final _existingDebtController = TextEditingController();

  String _currency = 'KES';
  String? _incomeSource;
  String? _financialGoal;
  String? _budgetingMethod;

  bool _isSaving = false;
  String? _errorMessage;

  static const _incomeSources = [
    'Salary',
    'Business',
    'Freelance',
    'Investment',
    'Rental income',
    'Other',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _countryController.dispose();
    _monthlyIncomeController.dispose();
    _monthlySavingsTargetController.dispose();
    _existingDebtController.dispose();
    super.dispose();
  }

  num? _parseOptionalNumber(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return num.tryParse(trimmed);
  }

  Future<void> _submit({required bool skippingOptional}) async {
    if (!skippingOptional && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updates = <String, dynamic>{
        'onboarding_completed': true,
        if (_fullNameController.text.trim().isNotEmpty) 'full_name': _fullNameController.text.trim(),
        if (_countryController.text.trim().isNotEmpty) 'country': _countryController.text.trim(),
        'currency': _currency,
        'monthly_income': _parseOptionalNumber(_monthlyIncomeController.text),
        'income_source': _incomeSource,
        'financial_goal': _financialGoal?.trim().isEmpty == true ? null : _financialGoal?.trim(),
        'monthly_savings_target': _parseOptionalNumber(_monthlySavingsTargetController.text),
        'existing_debt_amount': _parseOptionalNumber(_existingDebtController.text),
        'preferred_budgeting_method': _budgetingMethod,
      };

      final sessionToken = await AuthIdentityService.currentSessionToken(ClerkAuth.of(context, listen: false));
      if (sessionToken == null || sessionToken.isEmpty) {
        throw StateError('No session token available.');
      }

      await SupabaseService.updateProfile(sessionToken: sessionToken, updates: updates);

      if (!mounted) return;
      widget.onComplete();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Couldn't save your details. Check your connection and try again.";
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Let's set up your finances")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'A few quick questions so PesaPlan can work for you. '
                'Everything except currency is optional — you can always fill it in later.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                items: _supportedCurrencies
                    .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                    .toList(),
                onChanged: (value) => setState(() => _currency = value ?? _currency),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monthlyIncomeController,
                decoration: InputDecoration(
                  labelText: 'Monthly income',
                  prefixText: '$_currency ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _incomeSource,
                decoration: const InputDecoration(labelText: 'Main income source', border: OutlineInputBorder()),
                items: _incomeSources
                    .map((source) => DropdownMenuItem(value: source, child: Text(source)))
                    .toList(),
                onChanged: (value) => setState(() => _incomeSource = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Financial goal',
                  hintText: 'e.g. Buy a car, build an emergency fund',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _financialGoal = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monthlySavingsTargetController,
                decoration: InputDecoration(
                  labelText: 'Monthly savings target',
                  prefixText: '$_currency ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _existingDebtController,
                decoration: InputDecoration(
                  labelText: 'Existing debt (total)',
                  prefixText: '$_currency ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _budgetingMethod,
                decoration: const InputDecoration(
                  labelText: 'Preferred budgeting method',
                  border: OutlineInputBorder(),
                ),
                items: _budgetingMethods
                    .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                    .toList(),
                onChanged: (value) => setState(() => _budgetingMethod = value),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _isSaving ? null : () => _submit(skippingOptional: false),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save and continue'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSaving ? null : () => _submit(skippingOptional: true),
                child: const Text("Skip for now — I'll fill this in later"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
