import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/providers/app_providers.dart';

/// Defense-in-depth permission guard for clinically-sensitive screens.
///
/// SmartBunda enforces RBAC primarily by filtering the bottom-nav tabs in
/// [HomeScreen], but any screen reached via `Navigator.push` (a deep link, a
/// button that pushes a route, the back stack) renders without re-checking the
/// actor's permissions. Wrap such screens in a [PermissionGate] so they verify
/// the signed-in user actually holds [permission] before showing [child];
/// otherwise they show an "access denied" placeholder instead of the protected
/// content.
///
/// This is a CLIENT-SIDE guard only — it improves UX and stops accidental
/// navigation, but it is NOT a security boundary. Firestore Security Rules
/// remain the real backstop for who can read/write data.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.title,
  });

  /// The permission the current user must hold to see [child].
  final AccessPermission permission;

  /// The protected screen.
  final Widget child;

  /// Optional title for the denied-state scaffold's app bar.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return _DeniedScaffold(
        title: title,
        icon: Icons.lock_outline,
        message: 'Please sign in to view this page.',
      );
    }
    if (!user.hasPermission(permission)) {
      return _DeniedScaffold(
        title: title,
        icon: Icons.no_accounts_outlined,
        message: 'You do not have permission to view this page.\n'
            'Contact an administrator if you believe this is a mistake.',
      );
    }
    return child;
  }
}

class _DeniedScaffold extends StatelessWidget {
  const _DeniedScaffold({
    required this.icon,
    required this.message,
    this.title,
  });

  final IconData icon;
  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Access restricted')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: scheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
