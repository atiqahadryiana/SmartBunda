/// SmartBunda — Change Password
///
/// Lets the signed-in user change their password. Re-authenticates with the
/// current password first (handled by the auth repository).
library smartbunda.change_password_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/utils/password_policy.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = AppStrings.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('Password changed successfully.'))),
      );
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError('$error', strings))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(String raw, AppStrings strings) {
    final lower = raw.toLowerCase();
    if (lower.contains('incorrect') ||
        lower.contains('wrong-password') ||
        lower.contains('invalid-credential')) {
      return strings.t('Current password is incorrect.');
    }
    if (lower.contains('requires-recent-login')) {
      return strings.t('Please sign in again before changing your password.');
    }
    return strings.t('Could not change password. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('Change Password'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _currentCtrl,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: strings.t('Current Password'),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? strings.t('Required')
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: strings.t('New Password'),
                helperText: PasswordPolicy.errorMessage,
                helperMaxLines: 3,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return strings.t('Required');
                }
                if (!PasswordPolicy.isValid(value)) {
                  return PasswordPolicy.errorMessage;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: strings.t('Confirm New Password'),
              ),
              validator: (value) => value != _newCtrl.text
                  ? strings.t('Passwords do not match.')
                  : null,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.t('Update Password')),
            ),
          ],
        ),
      ),
    );
  }
}
