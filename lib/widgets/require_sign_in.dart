import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/providers/app_providers.dart';

class RequireSignIn extends ConsumerWidget {
  const RequireSignIn({
    super.key,
    required this.child,
    this.title,
    this.message,
    this.showAppBar = false,
    this.overrideUser,
  });

  final Widget child;
  final String? title;
  final String? message;
  final bool showAppBar;
  final Object? overrideUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user != null || overrideUser != null) {
      return child;
    }
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title ?? 'Sign in')) : null,
      body: Center(child: Text(message ?? 'Please sign in.')),
    );
  }
}
