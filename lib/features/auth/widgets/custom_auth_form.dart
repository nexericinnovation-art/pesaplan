import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth_colors.dart';
import 'forgot_password_dialog.dart';

enum _Mode { signIn, signUp }

enum _SignInStep { details, verifyCode }

enum _SignUpStep { details, verifyEmail }

/// Custom PesaPlan-styled sign-in / sign-up form, calling the same
/// [ClerkAuthState] methods the prebuilt `ClerkAuthentication()` widget uses
/// internally (`attemptSignIn`, `attemptSignUp`, `ssoSignIn`, `safelyCall`)
/// — this doesn't bypass Clerk, it only replaces the UI layer, matching
/// what Clerk's own docs call a "Custom Flow".
///
/// Scope: email + password + whatever OAuth providers are configured in the
/// Clerk Dashboard, plus optional first/last name. If your Dashboard
/// requires additional fields (username, phone) not collected here,
/// sign-up will surface a Clerk error rather than silently failing.
class CustomAuthForm extends StatefulWidget {
  const CustomAuthForm({super.key});

  @override
  State<CustomAuthForm> createState() => _CustomAuthFormState();
}

class _CustomAuthFormState extends State<CustomAuthForm> {
  _Mode _mode = _Mode.signIn;
  _SignInStep _signInStep = _SignInStep.details;
  _SignUpStep _signUpStep = _SignUpStep.details;

  final _signInEmail = TextEditingController();
  final _signInPassword = TextEditingController();
  final _signInCode = TextEditingController();
  bool _signInPasswordVisible = false;
  clerk.Strategy? _signInFactorStrategy;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();
  final _signUpConfirmPassword = TextEditingController();
  final _code = TextEditingController();
  bool _signUpPasswordVisible = false;
  bool _signUpConfirmVisible = false;

  bool _hasLegalAcceptance = false;
  String? _inlineError;
  bool _isSubmitting = false;

  StreamSubscription<clerk.ClerkError>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    // Mirrors the SDK's own custom-flow examples: safelyCall() catches auth
    // errors and pushes them to errorStream, but nothing displays them
    // without an explicit subscription.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _errorSubscription = ClerkAuth.of(context, listen: false).errorStream.listen((error) {
        if (!mounted) return;
        setState(() {
          _inlineError = error.message;
          _isSubmitting = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    _signInEmail.dispose();
    _signInPassword.dispose();
    _signInCode.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    _signUpConfirmPassword.dispose();
    _code.dispose();
    super.dispose();
  }

  void _switchMode(_Mode mode) {
    setState(() {
      _mode = mode;
      _signInStep = _SignInStep.details;
      _signUpStep = _SignUpStep.details;
      _inlineError = null;
    });
  }

  Future<void> _ssoSignIn(clerk.Strategy strategy) async {
    setState(() => _inlineError = null);
    final authState = ClerkAuth.of(context, listen: false);
    // ssoSignIn handles the whole OAuth flow itself (in-app browser dialog,
    // redirect handling) — this one call covers sign-in AND sign-up, since
    // Clerk creates the account automatically if it's a new OAuth user.
    await authState.ssoSignIn(context, strategy);
  }

  Future<void> _signIn() async {
    setState(() {
      _inlineError = null;
      _isSubmitting = true;
    });
    final authState = ClerkAuth.of(context, listen: false);
    await authState.safelyCall(context, () async {
      await authState.attemptSignIn(
        strategy: clerk.Strategy.password,
        identifier: _signInEmail.text.trim(),
        password: _signInPassword.text,
      );

      final signIn = authState.signIn;
      if (signIn != null && signIn.status.needsFactor && mounted) {
        final stage = clerk.Stage.forStatus(signIn.status);
        final factors = stage == clerk.Stage.first ? signIn.supportedFirstFactors : signIn.supportedSecondFactors;
        if (factors.isEmpty) {
          setState(() {
            _inlineError = 'Additional verification is required, but no method is available.';
            _isSubmitting = false;
          });
          return;
        }
        final factor = factors.firstWhere(
          (f) => f.strategy == clerk.Strategy.emailCode,
          orElse: () => factors.first,
        );
        _signInFactorStrategy = factor.strategy;
        await authState.attemptSignIn(strategy: factor.strategy);
        if (mounted) {
          setState(() {
            _signInStep = _SignInStep.verifyCode;
            _isSubmitting = false;
          });
        }
      } else if (mounted) {
        setState(() => _isSubmitting = false);
      }
    });
  }

  Future<void> _submitSignInCode() async {
    setState(() {
      _inlineError = null;
      _isSubmitting = true;
    });
    final authState = ClerkAuth.of(context, listen: false);
    final strategy = _signInFactorStrategy ?? clerk.Strategy.emailCode;
    await authState.safelyCall(context, () async {
      await authState.attemptSignIn(strategy: strategy, code: _signInCode.text.trim());
    });
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _resendSignInCode() async {
    final authState = ClerkAuth.of(context, listen: false);
    final strategy = _signInFactorStrategy ?? clerk.Strategy.emailCode;
    await authState.safelyCall(context, () async {
      await authState.resendCode(strategy);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code resent.')));
    }
  }

  Future<void> _submitSignUpDetails() async {
    setState(() => _inlineError = null);
    final authState = ClerkAuth.of(context, listen: false);

    final passwordError = authState.checkPassword(
      _signUpPassword.text,
      _signUpConfirmPassword.text,
      context,
    );
    if (passwordError != null) {
      setState(() => _inlineError = passwordError);
      return;
    }

    final needsLegalAcceptance = authState.env.user.signUp.legalConsentEnabled;
    if (needsLegalAcceptance && !_hasLegalAcceptance) {
      setState(() => _inlineError = 'Please accept the terms to continue.');
      return;
    }

    setState(() => _isSubmitting = true);
    await authState.safelyCall(context, () async {
      await authState.attemptSignUp(
        strategy: clerk.Strategy.password,
        firstName: _firstName.text.trim().isEmpty ? null : _firstName.text.trim(),
        lastName: _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
        emailAddress: _signUpEmail.text.trim(),
        password: _signUpPassword.text,
        passwordConfirmation: _signUpConfirmPassword.text,
        legalAccepted: needsLegalAcceptance ? _hasLegalAcceptance : null,
      );

      final signUp = authState.signUp;
      if (signUp != null && signUp.unverified(clerk.Field.emailAddress) && mounted) {
        if (authState.env.supportsEmailCode) {
          await authState.attemptSignUp(strategy: clerk.Strategy.emailCode);
          if (mounted) {
            setState(() {
              _signUpStep = _SignUpStep.verifyEmail;
              _isSubmitting = false;
            });
          }
        }
      } else if (mounted) {
        setState(() => _isSubmitting = false);
      }
    });
  }

  Future<void> _submitCode() async {
    setState(() {
      _inlineError = null;
      _isSubmitting = true;
    });
    final authState = ClerkAuth.of(context, listen: false);
    await authState.safelyCall(context, () async {
      await authState.attemptSignUp(strategy: clerk.Strategy.emailCode, code: _code.text.trim());
    });
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _resendCode() async {
    final authState = ClerkAuth.of(context, listen: false);
    await authState.safelyCall(context, () async {
      await authState.resendCode(clerk.Strategy.emailCode);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code resent.')));
    }
  }

  // ─── Shared visual pieces ────────────────────────────────────────────────

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    bool showVisibilityToggle = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5FB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: onSubmitted != null ? TextInputAction.done : TextInputAction.next,
            onSubmitted: onSubmitted,
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
              hintText: label == 'Email'
                  ? 'Enter your email'
                  : label == 'Password'
                      ? 'Enter your password'
                      : label,
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9AA6C0)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientButton({required String label, required VoidCallback onPressed, bool loading = false}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AuthColors.primary, AuthColors.primaryDark]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AuthColors.primaryDark.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOAuthSection(ClerkAuthState authState) {
    final strategies = authState.env.strategies.where((s) => s.isOauth).toList();
    if (strategies.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final strategy in strategies) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AuthColors.primary, AuthColors.primaryDark]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AuthColors.primaryDark.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _ssoSignIn(strategy),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Text(
                          'G',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4285F4)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Continue with ${strategy.provider ?? strategy.name}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _errorText() {
    if (_inlineError == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(_inlineError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
    );
  }

  // ─── Screens ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_mode == _Mode.signIn && _signInStep == _SignInStep.verifyCode) {
      return _buildVerifyScreen(
        title: "Verify it's you",
        subtitle: "We sent a verification code to confirm this sign-in.",
        codeController: _signInCode,
        onSubmit: _submitSignInCode,
        onResend: _resendSignInCode,
      );
    }
    if (_mode == _Mode.signUp && _signUpStep == _SignUpStep.verifyEmail) {
      return _buildVerifyScreen(
        title: 'Verify it\'s you',
        subtitle: 'We sent a verification code to ${_signUpEmail.text.trim()}.',
        codeController: _code,
        onSubmit: _submitCode,
        onResend: _resendCode,
      );
    }
    return _mode == _Mode.signIn ? _buildSignIn() : _buildSignUpDetails();
  }

  Widget _buildSignIn() {
    final authState = ClerkAuth.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Sign in', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AuthColors.textDark)),
        const Text('Access your account', style: TextStyle(color: AuthColors.textMuted, fontSize: 13)),
        const SizedBox(height: 20),
        _buildOAuthSection(authState),
        _field(label: 'Email', icon: Icons.mail_outline_rounded, controller: _signInEmail, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _field(
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          controller: _signInPassword,
          obscureText: !_signInPasswordVisible,
          showVisibilityToggle: true,
          onToggleVisibility: () => setState(() => _signInPasswordVisible = !_signInPasswordVisible),
          onSubmitted: (_) => _signIn(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => ForgotPasswordDialog.show(context),
            style: TextButton.styleFrom(foregroundColor: AuthColors.primary),
            child: const Text('Forgot password?'),
          ),
        ),
        _errorText(),
        const SizedBox(height: 8),
        _gradientButton(label: 'Sign in', onPressed: _signIn, loading: _isSubmitting),
        const SizedBox(height: 16),
        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: AuthColors.textMuted, fontSize: 13),
              children: [
                const TextSpan(text: "Don't have an account? "),
                TextSpan(
                  text: 'Sign up',
                  style: const TextStyle(color: AuthColors.primary, fontWeight: FontWeight.w700),
                  recognizer: TapGestureRecognizer()..onTap = () => _switchMode(_Mode.signUp),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpDetails() {
    final authState = ClerkAuth.of(context);
    final needsLegalAcceptance = authState.env.user.signUp.legalConsentEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Create your account',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AuthColors.textDark)),
        const Text('Get started with PesaPlan', style: TextStyle(color: AuthColors.textMuted, fontSize: 13)),
        const SizedBox(height: 20),
        _buildOAuthSection(authState),
        Row(
          children: [
            Expanded(child: _field(label: 'First name', icon: Icons.person_outline_rounded, controller: _firstName)),
            const SizedBox(width: 12),
            Expanded(child: _field(label: 'Last name', icon: Icons.person_outline_rounded, controller: _lastName)),
          ],
        ),
        const SizedBox(height: 14),
        _field(label: 'Email', icon: Icons.mail_outline_rounded, controller: _signUpEmail, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _field(
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          controller: _signUpPassword,
          obscureText: !_signUpPasswordVisible,
          showVisibilityToggle: true,
          onToggleVisibility: () => setState(() => _signUpPasswordVisible = !_signUpPasswordVisible),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Use 8+ characters with a mix of letters, numbers & symbols',
            style: TextStyle(fontSize: 11, color: AuthColors.textMuted),
          ),
        ),
        const SizedBox(height: 14),
        _field(
          label: 'Confirm password',
          icon: Icons.lock_outline_rounded,
          controller: _signUpConfirmPassword,
          obscureText: !_signUpConfirmVisible,
          showVisibilityToggle: true,
          onToggleVisibility: () => setState(() => _signUpConfirmVisible = !_signUpConfirmVisible),
          onSubmitted: (_) => _submitSignUpDetails(),
        ),
        if (needsLegalAcceptance) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _hasLegalAcceptance,
                onChanged: (v) => setState(() => _hasLegalAcceptance = v ?? false),
              ),
              const Expanded(child: Text('I agree to the Terms of Service and Privacy Policy', style: TextStyle(fontSize: 13))),
            ],
          ),
        ],
        _errorText(),
        const SizedBox(height: 8),
        _gradientButton(label: 'Create account', onPressed: _submitSignUpDetails, loading: _isSubmitting),
        const SizedBox(height: 16),
        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: AuthColors.textMuted, fontSize: 13),
              children: [
                const TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Sign in',
                  style: const TextStyle(color: AuthColors.primary, fontWeight: FontWeight.w700),
                  recognizer: TapGestureRecognizer()..onTap = () => _switchMode(_Mode.signIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyScreen({
    required String title,
    required String subtitle,
    required TextEditingController codeController,
    required VoidCallback onSubmit,
    required VoidCallback onResend,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: AuthColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.shield_outlined, color: AuthColors.primary, size: 32),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AuthColors.textDark)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AuthColors.textMuted, fontSize: 13)),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Verification code',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        ),
        const SizedBox(height: 8),
        _OtpCodeBoxes(controller: codeController, onCompleted: onSubmit),
        _errorText(),
        const SizedBox(height: 20),
        _gradientButton(label: 'Verify', onPressed: onSubmit, loading: _isSubmitting),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: AuthColors.textMuted, fontSize: 13),
            children: [
              const TextSpan(text: "Didn't get a code? "),
              TextSpan(
                text: 'Resend',
                style: const TextStyle(color: AuthColors.primary, fontWeight: FontWeight.w700),
                recognizer: TapGestureRecognizer()..onTap = onResend,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Six individual boxes for OTP-style code entry, syncing to a single
/// [TextEditingController] so the rest of the form's submit logic (reading
/// `controller.text`) doesn't need to change. Auto-advances focus forward
/// on entry and backward on backspace.
class _OtpCodeBoxes extends StatefulWidget {
  const _OtpCodeBoxes({required this.controller, this.length = 6, this.onCompleted});

  final TextEditingController controller;
  final int length;
  final VoidCallback? onCompleted;

  @override
  State<_OtpCodeBoxes> createState() => _OtpCodeBoxesState();
}

class _OtpCodeBoxesState extends State<_OtpCodeBoxes> {
  late final List<TextEditingController> _digitControllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _digitControllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Handles pasting a full code into one box.
      final chars = value.split('').take(widget.length).toList();
      for (var i = 0; i < chars.length && i < widget.length; i++) {
        _digitControllers[i].text = chars[i];
      }
      _syncToController();
      if (chars.length >= widget.length) {
        _focusNodes[widget.length - 1].unfocus();
        widget.onCompleted?.call();
      }
      return;
    }
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _syncToController();
    final combined = widget.controller.text;
    if (combined.length == widget.length) {
      FocusScope.of(context).unfocus();
      widget.onCompleted?.call();
    }
  }

  void _syncToController() {
    widget.controller.text = _digitControllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 44,
          height: 52,
          child: RawKeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKey: (event) {
              if (event is RawKeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _digitControllers[index].text.isEmpty &&
                  index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
            child: TextField(
              controller: _digitControllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: widget.length, // allows a full paste to land in one box
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AuthColors.textDark),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF1F5FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AuthColors.primary, width: 2),
                ),
              ),
              onChanged: (value) => _onChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}
