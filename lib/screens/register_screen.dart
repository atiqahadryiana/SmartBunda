import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/service_providers.dart';
import '../widgets/auth_shell.dart';

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
  final _nameController = TextEditingController();
  final _mmcController = TextEditingController();
  final _jlmController = TextEditingController();
  UserRole _role = UserRole.patient;
  bool _loading = false;
  String? _error;
  bool _requiresLicense(UserRole role) {
    return role == UserRole.doctor ||
        role == UserRole.nurse ||
        role == UserRole.dietitian;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _mmcController.dispose();
    _jlmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final requiresLicense = _requiresLicense(_role);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
        displayName: _nameController.text.trim(),
        mmcNumber: requiresLicense ? _mmcController.text.trim() : null,
        jlmNumber: requiresLicense ? _jlmController.text.trim() : null,
      );
      if (mounted) {
        await Navigator.of(context).maybePop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiresLicense = _requiresLicense(_role);
    return AuthShell(
      title: 'Create account',
      subtitle: 'Join Smartbunda to personalize nutrition tracking and care.',
      topAction: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to login'),
        ),
      ),
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          const Text('Already have an account?'),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Sign in'),
          ),
        ],
      ),
      child: Builder(
        builder: (context) {
          final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 150);
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Set up your profile', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Choose your role so we can match the right tools and permissions.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.patient,
                      child: Text('Patient'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.doctor,
                      child: Text('Doctor (needs admin approval)'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.nurse,
                      child: Text('Nurse (needs admin approval)'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.dietitian,
                      child: Text('Dietitian / Nutritionist (needs admin approval)'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Admin'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _role = value);
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                if (requiresLicense) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 200),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withValues(alpha: 30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_outlined, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'License details',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _mmcController,
                          decoration: const InputDecoration(
                            labelText: 'MMC number',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (v) => v != null && v.trim().isNotEmpty
                              ? null
                              : 'Required for this role',
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _jlmController,
                          decoration: const InputDecoration(
                            labelText: 'JLM number',
                            prefixIcon: Icon(Icons.confirmation_number_outlined),
                          ),
                          validator: (v) => v != null && v.trim().isNotEmpty
                              ? null
                              : 'Required for this role',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Admin approval is required before staff accounts can sign in.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_error != null) ...[
                  const SizedBox(height: 8),
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
                        : const Text('Create account'),
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
