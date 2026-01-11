import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/service_providers.dart';
import '../widgets/auth_shell.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  static const routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _emailLinkKey = 'emailLinkSignInEmail';
  static const _emailLinkContinueUrl =
      'https://smartbunda-d7761.firebaseapp.com/emailSignIn';
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _linkSending = false;
  bool _checkedEmailLink = false;
  String? _error;
  bool _didRedirect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEmailLinkSignIn();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      _didRedirect = true;
      _goHome(user);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showResetDialog() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    String? info;
    String? error;
    bool loading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Reset password'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  if (info != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      info!,
                      style: const TextStyle(color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () async {
                        setState(() {
                          loading = true;
                          error = null;
                          info = null;
                        });
                        try {
                          final response = await ref
                              .read(authRepositoryProvider)
                              .requestPasswordReset(emailCtrl.text.trim());
                          setState(() {
                            info = response.isEmpty
                                ? 'The reset link has been sent to your email.'
                                : response;
                          });
                        } catch (e) {
                          setState(() => error = e.toString());
                        } finally {
                          setState(() => loading = false);
                        }
                      },
                child: const Text('Send reset link'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _goHome(AppUser user) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _checkEmailLinkSignIn() async {
    if (_checkedEmailLink) return;
    _checkedEmailLink = true;
    final link = Uri.base.toString();
    bool isEmailLink;
    try {
      isEmailLink = fb.FirebaseAuth.instance.isSignInWithEmailLink(link);
    } catch (_) {
      return;
    }
    if (!isEmailLink) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString(_emailLinkKey);
      final email = storedEmail ?? await _promptForEmail();
      if (email == null || email.trim().isEmpty) {
        throw Exception('Email is required to complete sign-in.');
      }
      await fb.FirebaseAuth.instance.signInWithEmailLink(
        email: email.trim(),
        emailLink: link,
      );
      final user = await ref
          .read(authRepositoryProvider)
          .signInWithEmailLink(email: email.trim());
      if (!mounted) return;
      _didRedirect = true;
      _goHome(user);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<String?> _promptForEmail() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm your email'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _sendEmailLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email for email link sign-in.');
      return;
    }
    setState(() {
      _linkSending = true;
      _error = null;
    });
    final continueUrl = kIsWeb ? Uri.base.origin : _emailLinkContinueUrl;
    final actionCodeSettings = fb.ActionCodeSettings(
      url: continueUrl,
      handleCodeInApp: true,
      androidPackageName: 'com.example.smartbunda',
      androidInstallApp: true,
      androidMinimumVersion: '12',
      iOSBundleId: 'com.example.smartbunda',
    );
    try {
      await fb.FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailLinkKey, email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email link sent. Check your inbox.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _linkSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && !_didRedirect && mounted) {
          _didRedirect = true;
          _goHome(user);
        }
      });
    });

    return AuthShell(
      title: 'Smartbunda',
      subtitle: 'A calm way to track pregnancy nutrition and stay in sync with care.',
      footer: Builder(
        builder: (context) {
          final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 140);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text('New here?', style: TextStyle(color: muted)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(RegisterScreen.routeName),
                    child: const Text('Create account'),
                  ),
                ],
             // ),
             // TextButton(
             //   onPressed: () => Navigator.of(context).pushNamed('/onboarding'),
             //   child: const Text('View app tour'),
             ),
            ],
          );
        },
      ),
      child: Builder(
        builder: (context) {
          final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 150);
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Welcome back', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Sign in to review your plan, logs, and recommendations.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      v != null && v.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : 'Min 6 characters',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showResetDialog,
                    child: const Text('Forgot password?'),
                  ),
                ),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 120)),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: muted.withValues(alpha: 90))),
                    const SizedBox(width: 12),
                    Text('or', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Expanded(child: Divider(color: muted.withValues(alpha: 90))),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Passwordless sign-in', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'We will email a secure link. Use it on this device to finish signing in.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _linkSending ? null : _sendEmailLink,
                    icon: _linkSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.email_outlined),
                    label: const Text('Send sign-in link'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
