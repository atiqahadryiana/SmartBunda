import 'package:flutter_test/flutter_test.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/services/in_memory_auth_repository.dart';

void main() {
  test('register and login flow works in in-memory auth', () async {
    final auth = InMemoryAuthRepository();

    final created = await auth.register(
      email: 'patient@example.com',
      password: 'password',
      role: UserRole.patient,
      displayName: 'Patient',
    );

    expect(created.email, 'patient@example.com');
    expect(created.role, UserRole.patient);
    expect(auth.currentUser, isNotNull);

    await auth.signOut();
    expect(auth.currentUser, isNull);

    final loggedIn =
        await auth.signIn(email: 'patient@example.com', password: 'password');
    expect(loggedIn.id, created.id);
    expect(auth.currentUser, isNotNull);
  });

  test('staff approval uses submitted password', () async {
    final auth = InMemoryAuthRepository();
    // submit as dietitian (goes to pending)
    expect(
      () => auth.register(
        email: 'dietitian_new@example.com',
        password: 'their-secret',
        role: UserRole.dietitian,
        displayName: 'Dietitian',
      ),
      throwsA(isA<Exception>()),
    );

    final pending = await auth.pendingApprovals();
    expect(
      pending.any(
        (p) => p.email == 'dietitian_new@example.com' && p.role == UserRole.dietitian,
      ),
      isTrue,
    );

    await auth.approveUser(email: 'dietitian_new@example.com');
    // They can now sign in with their own password.
    final user =
        await auth.signIn(email: 'dietitian_new@example.com', password: 'their-secret');
    expect(user.role, UserRole.dietitian);
  });
}
