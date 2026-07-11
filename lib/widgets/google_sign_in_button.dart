import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/utils/auth_error_messages.dart';

/// "Continue with Google" button shared by the login & register screens.
///
/// Drives [AuthRepository.signInWithGoogle]; on success calls [onSignedIn] with
/// the resolved (patient) account, and surfaces friendly errors via [onError].
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onSignedIn,
    this.onError,
  });

  final ValueChanged<AppUser> onSignedIn;
  final ValueChanged<String>? onError;

  @override
  ConsumerState<GoogleSignInButton> createState() =>
      _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _loading = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _loading = true);
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!mounted) return;
      widget.onSignedIn(user);
    } catch (e) {
      if (!mounted) return;
      widget.onError?.call(friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _continueWithGoogle,
        icon: _loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const _GoogleGlyph(),
        label: Text(strings.t('Continue with Google')),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.outline),
          foregroundColor: scheme.onSurface,
        ),
      ),
    );
  }
}

/// Minimal Google "G" wordmark glyph (brand colours), avoiding a bundled asset.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Color(0xFF4285F4), // Google blue
        ),
      ),
    );
  }
}
