import 'package:flutter_test/flutter_test.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/services/in_memory_auth_repository.dart';

void main() {
  test('register and login flow works in in-memory auth', () async {
    final auth = InMemoryAuthRepository();

    final created = await auth.register(
      email: 'patient_new@example.com',
      password: 'Password1!',
      role: UserRole.patient,
      displayName: 'Patient',
    );

    expect(created.email, 'patient_new@example.com');
    expect(created.role, UserRole.patient);
    expect(auth.currentUser, isNotNull);

    await auth.signOut();
    expect(auth.currentUser, isNull);

    final loggedIn =
        await auth.signIn(email: 'patient_new@example.com', password: 'Password1!');
    expect(loggedIn.id, created.id);
    expect(auth.currentUser, isNotNull);
  });

  test('healthcare professionals cannot self-register', () async {
    final auth = InMemoryAuthRepository();
    // Staff roles must be created by an administrator, not self-registered.
    for (final role in const [
      UserRole.doctor,
      UserRole.nurse,
      UserRole.dietitian,
    ]) {
      await expectLater(
        auth.register(
          email: '${role.name}_new@example.com',
          password: 'TheirSecret1!',
          role: role,
          displayName: 'Staff',
        ),
        throwsA(isA<Exception>()),
      );
    }

    // No pending approvals are created for self-registration attempts.
    final pending = await auth.pendingApprovals();
    expect(pending, isEmpty);
  });

  test('admin can create a healthcare professional account', () async {
    final auth = InMemoryAuthRepository();
    final created = await auth.createUser(
      email: 'dietitian_admin@example.com',
      password: 'AdminMade1!',
      role: UserRole.dietitian,
      displayName: 'Dietitian',
    );
    expect(created.role, UserRole.dietitian);

    final user = await auth.signIn(
      email: 'dietitian_admin@example.com',
      password: 'AdminMade1!',
    );
    expect(user.role, UserRole.dietitian);
  });
}
