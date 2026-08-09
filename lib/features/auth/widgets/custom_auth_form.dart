import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../../ui/design_system/components/app_button.dart';
import '../../../ui/design_system/components/app_text_field.dart';

enum _Mode { signIn, signUp }

enum _SignInStep { details, verifyCode }

enum _SignUpStep { details, verifyEmail }

/// Custom PesaPlan-styled sign-in / sign-up form, calling the same
/// [ClerkAuthState] methods the prebuilt `ClerkAuthentication()` widget uses
/// internally (`attemptSignIn`, `attemptSignUp`, `ssoSignIn`, `safelyCall`)
/// — this doesn't bypass Clerk, it only replaces the UI layer with the
/// app's own claymorphism design system (AppTextField / AppButton), matching
/// what Clerk's own docs call a "Custom Flow".
///
/// Scope: email + password + whatever OAuth providers are configured in the
/// Clerk Dashboard, plus optional first/last name. If your Dashboard
/// requires additional fields (username, phone) not collected here,
/// sign-up will surface a Clerk error rather than silently failing — that's
/// a sign to adjust the Dashboard config or extend this form.
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
  clerk.Strategy? _signInFactorStrategy;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();
  final _signUpConfirmPassword = TextEditingController();
  final _code = TextEditingController();

  bool _hasLegalAcceptance = false;
  String? _inlineError;

  StreamSubscription<clerk.ClerkError>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    // Mirrors the SDK's own custom-flow examples: safelyCall() catches auth
    // errors and pushes them to errorStream, but nothing displays them
    // without an explicit subscription — there's no default visible error
    // UI otherwise, so a wrong password would silently do nothing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _errorSubscription = ClerkAuth.of(context, listen: false).errorStream.listen((error) {
        if (!mounted) return;
        setState(() => _inlineError = error.message);
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
    setState(() => _inlineError = null);
    final authState = ClerkAuth.of(context, listen: false);
    await authState.safelyCall(context, () async {
      await authState.attemptSignIn(
        strategy: clerk.Strategy.password,
        identifier: _signInEmail.text.trim(),
        password: _signInPassword.text,
      );

      // Password alone isn't always enough to finish — Clerk's "Client
      // Trust" check (on by default) or an actual second factor can leave
      // the sign-in needing one more step, without throwing an error.
      final signIn = authState.signIn;
      if (signIn != null && signIn.status.needsFactor && mounted) {
        final stage = clerk.Stage.forStatus(signIn.status);
        final factors = stage == clerk.Stage.first ? signIn.supportedFirstFactors : signIn.supportedSecondFactors;
        if (factors.isEmpty) {
          setState(() => _inlineError = 'Additional verification is required, but no method is available.');
          return;
        }
        // Clerk's own docs describe email code as the default strategy for
        // this step; prefer it if offered, otherwise take whatever's first.
        final factor = factors.firstWhere(
          (f) => f.strategy == clerk.Strategy.emailCode,
          orElse: () => factors.first,
        );
        _signInFactorStrategy = factor.strategy;
        // Triggers Clerk to send the code — same "call again with just the
        // strategy" pattern used for sign-up verification below.
        await authState.attemptSignIn(strategy: factor.strategy);
        if (mounted) setState(() => _signInStep = _SignInStep.verifyCode);
      }
    });
  }

  Future<void> _submitSignInCode() async {
    setState(() => _inlineError = null);
    final authState = ClerkAuth.of(context, listen: false);
    final strategy = _signInFactorStrategy ?? clerk.Strategy.emailCode;
    await authState.safelyCall(context, () async {
      await authState.attemptSignIn(strategy: strategy, code: _signInCode.text.trim());
    });
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
          // Triggers Clerk to send the verification code — same two-call
          // pattern the official ClerkSignUpPanel uses.
          await authState.attemptSignUp(strategy: clerk.Strategy.emailCode);
          if (mounted) setState(() => _signUpStep = _SignUpStep.verifyEmail);
        }
      }
    });
  }

  Future<void> _submitCode() async {
    setState(() => _inlineError = null);
    final authState = ClerkAuth.of(context, listen: false);
    await authState.safelyCall(context, () async {
      await authState.attemptSignUp(strategy: clerk.Strategy.emailCode, code: _code.text.trim());
    });
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

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 6),
        AppTextField(
          controller: controller,
          hintText: label,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: onSubmitted != null ? TextInputAction.done : TextInputAction.next,
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }

  Widget _buildOAuthSection(ClerkAuthState authState) {
    final strategies = authState.env.strategies.where((s) => s.isOauth).toList();
    if (strategies.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final strategy in strategies) ...[
          AppButton(
            isPrimary: false,
            onPressed: () => _ssoSignIn(strategy),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login_rounded, size: 18),
                const SizedBox(width: 8),
                Text('Continue with ${strategy.provider ?? strategy.name}'),
              ],
            ),
          ),
          const SizedBox(height: 10),
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

  @override
  Widget build(BuildContext context) {
    if (_mode == _Mode.signIn && _signInStep == _SignInStep.verifyCode) {
      return _buildSignInVerify();
    }
    if (_mode == _Mode.signUp && _signUpStep == _SignUpStep.verifyEmail) {
      return _buildVerifyEmail();
    }
    return _mode == _Mode.signIn ? _buildSignIn() : _buildSignUpDetails();
  }

  Widget _buildSignIn() {
    final authState = ClerkAuth.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sign in', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildOAuthSection(authState),
        _labeledField(label: 'Email', controller: _signInEmail, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _labeledField(
          label: 'Password',
          controller: _signInPassword,
          obscureText: true,
          onSubmitted: (_) => _signIn(),
        ),
        if (_inlineError != null) ...[
          const SizedBox(height: 8),
          Text(_inlineError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        AppButton(
          onPressed: _signIn,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Center(child: Text('Sign in')),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => _switchMode(_Mode.signUp),
            child: const Text("Don't have an account? Sign up"),
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
        Text('Create your account', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildOAuthSection(authState),
        Row(
          children: [
            Expanded(child: _labeledField(label: 'First name', controller: _firstName)),
            const SizedBox(width: 12),
            Expanded(child: _labeledField(label: 'Last name', controller: _lastName)),
          ],
        ),
        const SizedBox(height: 12),
        _labeledField(label: 'Email', controller: _signUpEmail, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _labeledField(label: 'Password', controller: _signUpPassword, obscureText: true),
        const SizedBox(height: 12),
        _labeledField(
          label: 'Confirm password',
          controller: _signUpConfirmPassword,
          obscureText: true,
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
              const Expanded(child: Text('I agree to the Terms of Service and Privacy Policy')),
            ],
          ),
        ],
        if (_inlineError != null) ...[
          const SizedBox(height: 8),
          Text(_inlineError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        AppButton(
          onPressed: _submitSignUpDetails,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Center(child: Text('Create account')),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => _switchMode(_Mode.signIn),
            child: const Text('Already have an account? Sign in'),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInVerify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Verify it's you", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          "We sent a verification code to confirm this sign-in.",
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        _labeledField(
          label: 'Verification code',
          controller: _signInCode,
          keyboardType: TextInputType.number,
          onSubmitted: (_) => _submitSignInCode(),
        ),
        if (_inlineError != null) ...[
          const SizedBox(height: 8),
          Text(_inlineError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        AppButton(
          onPressed: _submitSignInCode,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Center(child: Text('Verify')),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(onPressed: _resendSignInCode, child: const Text("Didn't get a code? Resend")),
        ),
      ],
    );
  }

  Widget _buildVerifyEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Check your email', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'We sent a verification code to ${_signUpEmail.text.trim()}.',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        _labeledField(
          label: 'Verification code',
          controller: _code,
          keyboardType: TextInputType.number,
          onSubmitted: (_) => _submitCode(),
        ),
        if (_inlineError != null) ...[
          const SizedBox(height: 8),
          Text(_inlineError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        AppButton(
          onPressed: _submitCode,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Center(child: Text('Verify')),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(onPressed: _resendCode, child: const Text("Didn't get a code? Resend")),
        ),
      ],
    );
  }
}