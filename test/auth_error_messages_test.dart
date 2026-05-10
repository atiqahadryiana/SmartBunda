import 'package:flutter_test/flutter_test.dart';
import 'package:smartbunda/utils/auth_error_messages.dart';

void main() {
  test('hides Firebase invalid credential details', () {
    final message = friendlyAuthError(
      Exception(
        '[firebase_auth/invalid-credential] The supplied auth credential is incorrect.',
      ),
    );

    expect(message, 'Wrong email or password.');
    expect(message.toLowerCase(), isNot(contains('firebase')));
  });

  test('maps duplicate email to simple copy', () {
    expect(
      friendlyAuthError(Exception('[firebase_auth/email-already-in-use]')),
      'Email already registered.',
    );
  });
}
