String friendlyAuthError(Object error) {
  final raw = error.toString();
  final normalized = raw.toLowerCase();

  if (_containsAny(normalized, [
    'invalid-credential',
    'wrong-password',
    'invalid-password',
    'user-not-found',
    'invalid credentials',
  ])) {
    return 'Wrong email or password.';
  }
  if (_containsAny(normalized, ['invalid-email', 'malformed'])) {
    return 'Invalid email address.';
  }
  if (_containsAny(
      normalized, ['email-already-in-use', 'email already in use'])) {
    return 'Email already registered.';
  }
  if (_containsAny(normalized, ['weak-password'])) {
    return 'Password is too weak.';
  }
  if (_containsAny(normalized, ['too-many-requests'])) {
    return 'Too many attempts. Please try again later.';
  }
  if (_containsAny(normalized, ['network-request-failed', 'network'])) {
    return 'Network error. Please check your connection.';
  }
  if (_containsAny(
      normalized, ['expired-action-code', 'invalid-action-code'])) {
    return 'This sign-in link is invalid or expired.';
  }
  if (_containsAny(normalized, ['account not approved'])) {
    return 'Account not approved yet.';
  }
  if (_containsAny(normalized, ['deactivated'])) {
    return 'Account is deactivated. Contact admin.';
  }
  if (_containsAny(normalized, ['access disabled'])) {
    return 'Access disabled. Contact admin.';
  }
  if (_containsAny(normalized, ['registration submitted'])) {
    return 'Registration submitted. Awaiting admin approval.';
  }
  if (_containsAny(normalized, ['email is required'])) {
    return 'Email is required.';
  }

  final cleaned = raw
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceAll(RegExp(r'\[firebase_auth/[^\]]+\]\s*'), '')
      .trim();
  if (cleaned.isEmpty || cleaned == raw && normalized.contains('firebase')) {
    return 'Account invalid. Please try again.';
  }
  return cleaned;
}

bool _containsAny(String value, List<String> needles) {
  return needles.any(value.contains);
}
