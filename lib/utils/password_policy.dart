class PasswordPolicy {
  static const int minLength = 6;
  static const String errorMessage =
      'Password must include uppercase, lowercase, number, and symbol (min 6 characters).';
  static final RegExp _pattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{6,}$',
  );

  static bool isValid(String password) => _pattern.hasMatch(password);
}
