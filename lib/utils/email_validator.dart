/// SmartBunda — shared email validation.
///
/// A single, pragmatic email check used by every auth form so validation is
/// consistent (the old `value.contains('@')` accepted things like "a@" or "@@").
library smartbunda.email_validator;

/// Matches `local@domain.tld` with no spaces and at least one dot in the
/// domain. Not RFC-perfect (no validator is) but rejects the common typos a
/// bare `contains('@')` would let through.
final RegExp _emailRegExp = RegExp(
  r"^[\w.+\-']+@[\w\-]+(\.[\w\-]+)+$",
);

/// True when [value] looks like a valid email address.
bool isValidEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return false;
  return _emailRegExp.hasMatch(v);
}
