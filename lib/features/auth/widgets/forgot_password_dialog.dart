import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../auth_colors.dart';

enum _ResetStep { enterEmail, enterCodeAndPassword }

/// Password reset, using the same real Clerk API the official
/// `ClerkForgottenPasswordPanel` uses (`initiatePasswordReset`, then
/// `attemptSignIn` with both the code and the new password together in one
/// call) — verified against the SDK's own source.
///
/// Self-contained: uses its own try/catch rather than sharing
/// `CustomAuthForm`'s errorStream subscription, so errors always display
/// inside this dialog regardless of what else is happening underneath it.
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
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
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

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    bool showVisibilityToggle = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF1F5FB), borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: AuthColors.textDark),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: const Color(0xFF8B98B5)),
              suffixIcon: showVisibilityToggle
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF8B98B5),
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset your password', style: TextStyle(color: AuthColors.textDark)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == _ResetStep.enterEmail) ...[
              const Text(
                "Enter your account email and we'll send you a code to reset your password.",
                style: TextStyle(color: AuthColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _field(label: 'Email', icon: Icons.mail_outline_rounded, controller: _email, keyboardType: TextInputType.emailAddress),
            ] else ...[
              Text(
                'Enter the code sent to ${_email.text.trim()}, and choose a new password.',
                style: const TextStyle(color: AuthColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _field(label: 'Verification code', icon: Icons.pin_outlined, controller: _code, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _field(
                label: 'New password',
                icon: Icons.lock_outline_rounded,
                controller: _newPassword,
                obscureText: !_newPasswordVisible,
                showVisibilityToggle: true,
                onToggleVisibility: () => setState(() => _newPasswordVisible = !_newPasswordVisible),
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Confirm new password',
                icon: Icons.lock_outline_rounded,
                controller: _confirmPassword,
                obscureText: !_confirmPasswordVisible,
                showVisibilityToggle: true,
                onToggleVisibility: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
              ),
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
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AuthColors.primary)),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AuthColors.primary, AuthColors.primaryDark]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _step == _ResetStep.enterEmail ? _sendCode : _submitReset,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    _step == _ResetStep.enterEmail ? 'Send code' : 'Reset password',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
