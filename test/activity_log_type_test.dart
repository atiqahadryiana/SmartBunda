import 'package:flutter_test/flutter_test.dart';
import 'package:smartbunda/models/activity_log.dart';

void main() {
  group('activityTypeFromName', () {
    test('round-trips every ActivityType via its stored name', () {
      // Logs persist `type.name`; reading it back must yield the same type.
      for (final type in ActivityType.values) {
        expect(
          activityTypeFromName(type.name),
          type,
          reason: '${type.name} should round-trip',
        );
      }
    });

    test('matches camelCase names regardless of input casing', () {
      // Regression: a previous parser lowercased the input then compared it to
      // camelCase literals, so these non-login types silently became "login".
      expect(activityTypeFromName('approvalRequested'),
          ActivityType.approvalRequested);
      expect(activityTypeFromName('userDeactivated'),
          ActivityType.userDeactivated);
      expect(activityTypeFromName('passwordResetAdmin'),
          ActivityType.passwordResetAdmin);

      // Case-insensitive: stored value may differ in casing.
      expect(activityTypeFromName('USERCREATED'), ActivityType.userCreated);
      expect(activityTypeFromName('  userUpdated  '), ActivityType.userUpdated);
    });

    test('falls back to login for null, empty, or unknown values', () {
      expect(activityTypeFromName(null), ActivityType.login);
      expect(activityTypeFromName(''), ActivityType.login);
      expect(activityTypeFromName('   '), ActivityType.login);
      expect(activityTypeFromName('somethingElse'), ActivityType.login);
    });
  });
}
