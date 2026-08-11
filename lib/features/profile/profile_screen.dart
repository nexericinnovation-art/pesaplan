import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/services/auth_identity_service.dart';
import 'account_security_screen.dart';
import 'appearance_screen.dart';
import '../debts/debts_screen.dart';
import '../insights/health_score_screen.dart';
import '../insights/insights_screen.dart';
import '../legal/legal_content.dart';
import '../legal/legal_document_screen.dart';
import '../recurring/recurring_transactions_screen.dart';
import '../reports/reports_screen.dart';
import 'coming_soon_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ClerkAuth.of(context, listen: true);
    final clerkUserId = AuthIdentityService.currentClerkUserId(auth) ?? '';
    final currency = ref.watch(profileControllerProvider).valueOrNull?.currency ?? 'KES';
    final email = AuthIdentityService.currentClerkEmail(auth) ?? 'No email';
    final user = auth.client.user;
    final name = (user != null)
        ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
        : 'PesaPlan User';
    final displayName = name.isNotEmpty ? name : 'PesaPlan User';
    final avatarUrl = user?.imageUrl;

    const backgroundColor = Color(0xFFEFF3FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Page Header Title
              const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 28),

              // Neumorphic Avatar Container
              _buildNeumorphicAvatar(avatarUrl, displayName),
              const SizedBox(height: 24),

              // User Info Card
              _NeumorphicCard(
                borderRadius: 24,
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                backgroundColor: backgroundColor,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Settings Items Card
              _NeumorphicCard(
                borderRadius: 28,
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                backgroundColor: backgroundColor,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.query_stats_rounded,
                      title: 'Financial Health Score',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HealthScoreScreen(clerkUserId: clerkUserId),
                          ),
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.insights_rounded,
                      title: 'Insights',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InsightsScreen(clerkUserId: clerkUserId, currency: currency),
                          ),
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Debts',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DebtsScreen(clerkUserId: clerkUserId, currency: currency),
                          ),
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.event_repeat_rounded,
                      title: 'Recurring',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecurringTransactionsScreen(clerkUserId: clerkUserId, currency: currency),
                          ),
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Reports',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportsScreen(clerkUserId: clerkUserId, currency: currency),
                          ),
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.shield_outlined,
                      title: 'Account Security',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                      builder: (_) => const AccountSecurityScreen(),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ComingSoonScreen(
                            title: 'Notifications',
                            description: 'Budget alerts, bill reminders, and monthly summaries will be configurable here.',
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                      builder: (_) => const AppearanceScreen(),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LegalDocumentScreen(
                            title: 'Terms of Service',
                            body: LegalContent.termsOfService,
                            lastUpdated: LegalContent.lastUpdated,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LegalDocumentScreen(
                            title: 'Privacy Policy',
                            body: LegalContent.privacyPolicy,
                            lastUpdated: LegalContent.lastUpdated,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Log Out Button
              GestureDetector(
                onTap: () async {
                  await auth.signOut();
                },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF3B82F6),
                        Color(0xFF1D4ED8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicAvatar(String? avatarUrl, String displayName) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-8, -8),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFFBCCCDD).withValues(alpha: 0.6),
            offset: const Offset(8, 8),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10.0),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF1D4ED8),
            ],
          ),
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildDefaultAvatarContent(displayName),
                )
              : _buildDefaultAvatarContent(displayName),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatarContent(String displayName) {
    return const Center(
      child: Icon(
        Icons.person,
        size: 78,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            // Neumorphic icon container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3FA),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: const Color(0xFFAEBECF).withValues(alpha: 0.5),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1D4ED8),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  const _NeumorphicCard({
    required this.child,
    required this.borderRadius,
    required this.padding,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-6, -6),
            blurRadius: 14,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFFAEBECF).withValues(alpha: 0.45),
            offset: const Offset(6, 6),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}