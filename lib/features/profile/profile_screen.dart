import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_identity_service.dart';
import '../../app/theme/app_colors.dart';
import '../../ui/design_system/components/app_card.dart';
import '../../ui/design_system/components/app_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = ClerkAuth.of(context, listen: true);
    final email = AuthIdentityService.currentClerkEmail(auth) ?? 'No email';
    final user = auth.client.user;
    final name = (user != null)
        ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
        : 'PesaPlan User';
    final displayName = name.isNotEmpty ? name : 'PesaPlan User';
    final avatarUrl = user?.imageUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Beautiful Header
              Text(
                'My Profile',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 32),

              // Avatar Card with Bevel Highlight
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildDefaultAvatar(context, displayName),
                            )
                          : _buildDefaultAvatar(context, displayName),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User Info Card
              AppCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Items Card
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.shield_outlined,
                      title: 'Account Security',
                      color: Colors.blueAccent,
                    ),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    _buildSettingsTile(
                      context,
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      color: Colors.amber,
                    ),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    _buildSettingsTile(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  isPrimary: false,
                  onPressed: () async {
                    await auth.signOut();
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context, String name) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P';
    return CircleAvatar(
      backgroundColor: AppColors.primary.withOpacity(0.15),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26, size: 18),
      onTap: () {
        // Can expand in future
      },
    );
  }
}
