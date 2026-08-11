import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../auth/auth_colors.dart';

/// Account security: change password, review active sessions (sign out of
/// other devices), and delete the account. Every method here is verified
/// against the real clerk_auth source (updateUserPassword, client.sessions,
/// signOutOf, deleteUser) — not guessed.
class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Security')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionCard(
              icon: Icons.lock_outline_rounded,
              title: 'Change password',
              subtitle: 'Update the password you use to sign in.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _ChangePasswordScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.devices_outlined,
              title: 'Active sessions',
              subtitle: 'See where you\'re signed in, and sign out of other devices.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _ActiveSessionsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.delete_outline_rounded,
              title: 'Delete account',
              subtitle: 'Permanently delete your account and all your data.',
              iconColor: Colors.red,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _DeleteAccountScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AuthColors.primary),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

// ─── Change Password ─────────────────────────────────────────────────────

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final authState = ClerkAuth.of(context, listen: false);

    if (_current.text.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    final passwordError = authState.checkPassword(_newPassword.text, _confirm.text, context);
    if (passwordError != null) {
      setState(() => _error = passwordError);
      return;
    }

    setState(() => _isSaving = true);
    try {
      // signOut: false — they just proved identity with their current
      // password, no reason to also sign them out of this device.
      await authState.updateUserPassword(_current.text, _newPassword.text, signOut: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('PASSWORD UPDATE FAILED: $e');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = "Couldn't update your password. Check your current password and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password', border: OutlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Update password'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Active Sessions ──────────────────────────────────────────────────────

class _ActiveSessionsScreen extends StatefulWidget {
  const _ActiveSessionsScreen();

  @override
  State<_ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<_ActiveSessionsScreen> {
  String? _error;
  String? _revokingSessionId;

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _signOutOf(clerk.Session session) async {
    setState(() {
      _error = null;
      _revokingSessionId = session.id;
    });
    final authState = ClerkAuth.of(context, listen: false);
    try {
      await authState.signOutOf(session);
      if (mounted) setState(() => _revokingSessionId = null);
    } catch (e) {
      debugPrint('SESSION SIGN OUT FAILED: $e');
      if (!mounted) return;
      setState(() {
        _revokingSessionId = null;
        _error = "Couldn't sign out of that session. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ClerkAuth.of(context);
    final sessions = authState.client.sessions;
    final currentSessionId = authState.client.lastActiveSessionId;

    return Scaffold(
      appBar: AppBar(title: const Text('Active sessions')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 12),
            ],
            for (final session in sessions)
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.smartphone_rounded,
                    color: session.id == currentSessionId ? AuthColors.primary : Colors.black45,
                  ),
                  title: Text(session.id == currentSessionId ? 'This device' : 'Other device'),
                  subtitle: Text('Last active: ${_formatDate(session.lastActiveAt)}'),
                  trailing: session.id == currentSessionId
                      ? null
                      : (_revokingSessionId == session.id
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : TextButton(
                              onPressed: () => _signOutOf(session),
                              child: const Text('Sign out'),
                            )),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Delete Account ───────────────────────────────────────────────────────

class _DeleteAccountScreen extends StatefulWidget {
  const _DeleteAccountScreen();

  @override
  State<_DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<_DeleteAccountScreen> {
  final _confirmText = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  static const _confirmPhrase = 'DELETE';

  @override
  void dispose() {
    _confirmText.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your account and every transaction, budget, goal, debt, and '
          'recurring item you\'ve added. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });
    final authState = ClerkAuth.of(context, listen: false);
    try {
      await authState.deleteUser();
      // deleteUser() doesn't throw when Clerk's Dashboard has self-deletion
      // disabled — it routes an error to Clerk's errorStream instead. This
      // screen has no subscription to that stream, so the real signal is
      // whether the user object is actually gone afterward.
      if (!mounted) return;
      if (authState.client.user == null) {
        // The app's existing router redirect logic takes over from here —
        // no signed-in user means it sends them to /auth automatically.
        return;
      }
      setState(() {
        _isDeleting = false;
        _error = "Account deletion isn't enabled for this app yet. Contact support to delete your account.";
      });
    } catch (e) {
      debugPrint('ACCOUNT DELETE FAILED: $e');
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _error = "Couldn't delete your account. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _confirmText.text.trim() == _confirmPhrase;

    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Deleting your account permanently removes all your data — transactions, budgets, '
              'goals, debts, and recurring items. This cannot be undone.',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Text('Type $_confirmPhrase to confirm', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmText,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: (canDelete && !_isDeleting) ? _delete : null,
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: _isDeleting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Delete my account permanently'),
            ),
          ],
        ),
      ),
    );
  }
}
