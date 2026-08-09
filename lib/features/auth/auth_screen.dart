import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../app/config/environment.dart';
import 'auth_colors.dart';
import 'auth_status_view.dart';
import 'widgets/custom_auth_form.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasConfig = AppEnvironment.hasRequiredClientConfig;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: hasConfig ? const _AuthBody() : _MissingConfigBody(),
    );
  }
}

// ─── Missing config fallback ──────────────────────────────────────────────

class _MissingConfigBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            AuthStatusView(
              message:
                  'Missing public configuration. Configure Clerk and Supabase before continuing.',
              isError: true,
            ),
            SizedBox(height: 16),
            Text(
              'Use values from your public environment configuration only.',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main auth body ─────────────────────────────────────────────────────────

class _AuthBody extends StatelessWidget {
  const _AuthBody();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    return Stack(
      children: [
        // Background gradient — light pastel blue, not the old dark purple.
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AuthColors.headerTop, AuthColors.headerBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Main content
        SafeArea(
          child: Column(
            children: [
              // ── Header with ATM Card ────────────────────────────────────
              SizedBox(
                height: isKeyboardVisible ? 80 : 200,
                child: isKeyboardVisible
                    ? _buildCompactHeader()
                    : _buildHeaderWithCard(),
              ),

              // ── Scrollable card ─────────────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 20,
                        bottom: math.max(20, bottomInset + 16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Handle indicator
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Welcome text (visible when keyboard is open)
                          if (isKeyboardVisible) ...[
                            Text(
                              'Welcome Back',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AuthColors.textDark,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to continue',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Custom Sign In / Sign Up Form ──────────────
                          const CustomAuthForm(),
                          const SizedBox(height: 16),

                          // ── Security badge ─────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: AuthColors.primary.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 6),
                              Text.rich(
                                TextSpan(
                                  text: 'Secured by ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Clerk',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Header with ATM Card ─────────────────────────────────────────────────

  Widget _buildHeaderWithCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        children: [
          // Left side - welcome text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'PesaPlan',
                    style: TextStyle(
                      color: AuthColors.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome Back 👋',
                style: TextStyle(
                  color: AuthColors.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Sign in to manage your finances',
                style: TextStyle(
                  color: AuthColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // Right side - ATM Card
          Positioned(
            right: 0,
            top: 20,
            child: _buildAtmCard(),
          ),
        ],
      ),
    );
  }

  // ─── ATM Card Widget ──────────────────────────────────────────────────────

  Widget _buildAtmCard() {
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        width: 120,
        height: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AuthColors.primary, AuthColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AuthColors.primaryDark.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              top: -12,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PesaPlan',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '•••• 5678',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'VISA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Compact Header ──────────────────────────────────────────────────────

  Widget _buildCompactHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'PesaPlan',
            style: TextStyle(
              color: AuthColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AuthColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Secure',
              style: TextStyle(
                color: AuthColors.primaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
