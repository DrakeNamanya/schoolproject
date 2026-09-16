import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_provider.dart';
import '../../models/user.dart';
import '../../theme/tokens.dart';
import '../../widgets/brand.dart';

/// Shown when a signed-in user holds more than one role
/// (e.g. a teacher who is also a parent).
class RolePickerScreen extends StatelessWidget {
  const RolePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Crest(size: 48),
              const SizedBox(height: 20),
              Text('Hello, ${user.displayName}', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              const Text(
                'You have more than one role at Timbitwire. How would you like to continue?',
                style: TextStyle(fontSize: 13, color: TgsColors.fg2),
              ),
              const SizedBox(height: 24),
              for (final r in user.roles) ...[
                _RoleCard(r, onTap: () => auth.chooseRole(r)),
                const SizedBox(height: 10),
              ],
              const Spacer(),
              Center(
                child: TextButton(onPressed: auth.signOut, child: const Text('Sign out')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard(this.role, {required this.onTap});
  final UserRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tint, desc) = switch (role.shell) {
      AppShell.parent => (Icons.family_restroom_rounded, TgsColors.brick500, "Your daughter's fees, marks, clinic and school news"),
      AppShell.staff => (Icons.badge_outlined, TgsColors.navy500, 'Check-in, schedule, marks entry and alerts'),
      AppShell.admin => (Icons.admin_panel_settings_outlined, TgsColors.maroon500, 'Administration console'),
    };
    return TgsCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBox(icon, tint: tint, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: TgsColors.fg3)),
              ],
            ),
          ),
          const Chevron(),
        ],
      ),
    );
  }
}
