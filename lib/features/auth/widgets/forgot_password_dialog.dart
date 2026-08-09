import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../../ui/design_system/components/app_button.dart';
import '../../../ui/design_system/components/app_text_field.dart';

enum _ResetStep { enterEmail, enterCodeAndPassword }

/// Password reset, using the same real Clerk API the official
/// `ClerkForgottenPasswordPanel` uses (`initiatePasswordReset`, then
/// `attemptSignIn` with both the code and the new password together in one
/// call) — verified against the SDK's own source, not guessed.
///
/// Deliberately self-contained: uses its own try/catch rather than sharing
/// `CustomAuthForm`'s errorStream subscription, so errors always display
/// inside this dialog regardless of what else is happening in the parent
/// form underneath it.
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(context: context, builder: (_) => const ForgotPasswordDialog());
  }

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  _ResetStep _step = _ResetStep.enterEmail;
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    setState(() {
      _error = null;
      _isLoading = true;
    });
    final authState = ClerkAuth.of(context, listen: false);
    try {
      await authState.initiatePasswordReset(
        identifier: _email.text.trim(),
        strategy: clerk.Strategy.resetPasswordEmailCode,
      );
      final ready = authState.signIn?.status == clerk.Status.needsFirstFactor;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (ready) {
          _step = _ResetStep.enterCodeAndPassword;
        } else {
          _error = "Couldn't start password reset. Check the email and try again.";
        }
      });
    } catch (e) {
      debugPrint('PASSWORD RESET INIT FAILED: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = "Couldn't send a reset code. Check your connection and try again.";
      });
    }
  }

  Future<void> _submitReset() async {
    setState(() => _error = null);
    final authState = ClerkAuth.of(context, listen: false);

    final passwordError = authState.checkPassword(_newPassword.text, _confirmPassword.text, context);
    if (passwordError != null) {
      setState(() => _error = passwordError);
      return;
    }
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Enter the code we sent you.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await authState.attemptSignIn(
        strategy: clerk.Strategy.resetPasswordEmailCode,
        identifier: _email.text.trim(),
        password: _newPassword.text,
        code: _code.text.trim(),
      );
      if (!mounted) return;
      if (authState.isSignedIn) {
        // A successful reset signs the user in directly — the app's
        // existing router redirect logic takes it from here.
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
          _error = "That code didn't work. Check it and try again.";
        });
      }
    } catch (e) {
      debugPrint('PASSWORD RESET SUBMIT FAILED: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = "Couldn't reset your password. Check the code and try again.";
      });
    }
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 6),
        AppTextField(controller: controller, hintText: label, obscureText: obscureText, keyboardType: keyboardType),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset your password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == _ResetStep.enterEmail) ...[
              const Text(
                "Enter your account email and we'll send you a code to reset your password.",
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _labeledField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress),
            ] else ...[
              Text(
                'Enter the code sent to ${_email.text.trim()}, and choose a new password.',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _labeledField(label: 'Verification code', controller: _code, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _labeledField(label: 'New password', controller: _newPassword, obscureText: true),
              const SizedBox(height: 12),
              _labeledField(label: 'Confirm new password', controller: _confirmPassword, obscureText: true),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          AppButton(
            onPressed: _step == _ResetStep.enterEmail ? _sendCode : _submitReset,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(_step == _ResetStep.enterEmail ? 'Send code' : 'Reset password'),
          ),
      ],
    );
  }
}
