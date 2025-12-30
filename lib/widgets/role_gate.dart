import 'package:flutter/material.dart';

import '../models/app_user.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({
    super.key,
    required this.user,
    required this.allowed,
    required this.child,
    this.fallback,
  });

  final AppUser? user;
  final List<UserRole> allowed;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    if (user == null || !allowed.contains(user!.role)) {
      return fallback ?? const SizedBox.shrink();
    }
    return child;
  }
}
