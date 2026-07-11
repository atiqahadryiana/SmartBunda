import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/utils/auth_error_messages.dart';
import 'package:smartbunda/utils/email_validator.dart';
import 'package:smartbunda/utils/password_policy.dart';
import 'package:smartbunda/widgets/auth_shell.dart';
import 'package:smartbunda/widgets/google_sign_in_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  static const routeName = '/register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Public sign-up is restricted to patients. Healthcare professional
      // accounts (doctor / nurse / dietitian) are created by an administrator.
      await ref.read(authRepositoryProvider).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: UserRole.patient,
            displayName: _nameController.text.trim(),
          );
      if (mounted) {
        await _showVerifyEmailDialog(_emailController.text.trim());
        if (mounted) await Navigator.of(context).maybePop();
      }
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showVerifyEmailDialog(String email) async {
    final strings = AppStrings.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        var sending = false;
        String? info;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            icon: const Icon(Icons.mark_email_unread_outlined),
            title: Text(strings.t('Verify your email')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t(
                      'We sent a verification link to $email. Please check your inbox and verify your email to secure your account.'),
                ),
                if (info != null) ...[
                  const SizedBox(height: 8),
                  Text(info!,
                      style: TextStyle(
                          color: Theme.of(ctx).colorScheme.primary)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: sending
                    ? null
                    : () async {
                        setState(() => sending = true);
                        try {
                          await ref
                              .read(authRepositoryProvider)
                              .sendEmailVerification();
                          setState(() => info =
                              strings.t('Verification email resent.'));
                        } catch (_) {
                          setState(() => info =
                              strings.t('Could not resend. Try again later.'));
                        } finally {
                          setState(() => sending = false);
                        }
                      },
                child: Text(strings.t('Resend email')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(strings.t('Done')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AuthShell(
      title: strings.t('Create account'),
      subtitle: strings
          .t('Join Smartbunda to personalize nutrition tracking and care.'),
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(strings.t('Already have an account?')),
          TextButton(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false),
            child: Text(strings.t('Sign in')),
          ),
        ],
      ),
      child: Builder(
        builder: (context) {
          final muted =
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.588);
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.t('Set up your profile'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  strings.t(
                      'Create your patient account to start tracking your nutrition and care.'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: muted),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: strings.t('Name'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : strings.t('Required'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: strings.t('Email'),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) => isValidEmail(v)
                      ? null
                      : strings.t('Enter a valid email'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: strings.t('Password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscure
                          ? strings.t('Show password')
                          : strings.t('Hide password'),
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => PasswordPolicy.isValid(v ?? '')
                      ? null
                      : strings.t(PasswordPolicy.errorMessage),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: strings.t('Confirm password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v == _passwordController.text
                      ? null
                      : strings.t('Passwords do not match'),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.471),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.t(
                            'Healthcare professional accounts (doctor, nurse, dietitian) are created by a system administrator. Please contact your administrator for access.',
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final scheme = Theme.of(context).colorScheme;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: scheme.error.withValues(alpha: 0.353)),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(strings.t('Create account')),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: muted.withValues(alpha: 0.353))),
                    const SizedBox(width: 12),
                    Text(strings.t('or'),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Expanded(child: Divider(color: muted.withValues(alpha: 0.353))),
                  ],
                ),
                const SizedBox(height: 16),
                GoogleSignInButton(
                  // First Google sign-in creates a patient account; pop back to
                  // the auth gate which routes to the home/profile flow.
                  onSignedIn: (_) {
                    if (mounted) Navigator.of(context).maybePop();
                  },
                  onError: (msg) => setState(() => _error = msg),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
