import 'package:test/test.dart';

import 'package:queueless_backend/services/auth_service.dart';
import 'package:queueless_backend/models/user.dart';

void main() {
  late AuthService authService;

  setUp(() {
    // Create a fresh instance for each test by resetting singleton state.
    authService = AuthService();
  });

  group('AuthService', () {
    test('register creates a new user', () {
      final user = authService.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      );

      expect(user.name, equals('Test User'));
      expect(user.email, equals('test@example.com'));
      expect(user.role, equals(UserRole.customer));
      expect(user.id, isNotEmpty);
    });

    test('register with owner role', () {
      final user = authService.register(
        name: 'Owner',
        email: 'owner@example.com',
        password: 'password123',
        role: UserRole.owner,
      );

      expect(user.role, equals(UserRole.owner));
    });

    test('register rejects duplicate email', () {
      authService.register(
        name: 'User 1',
        email: 'dup@example.com',
        password: 'password123',
      );

      expect(
        () => authService.register(
          name: 'User 2',
          email: 'dup@example.com',
          password: 'password456',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('register rejects short password', () {
      expect(
        () => authService.register(
          name: 'User',
          email: 'short@example.com',
          password: '12345',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('login returns a JWT token', () {
      authService.register(
        name: 'Login Test',
        email: 'login@example.com',
        password: 'password123',
      );

      final token = authService.login(
        email: 'login@example.com',
        password: 'password123',
      );

      expect(token, isNotEmpty);
    });

    test('login fails with wrong password', () {
      authService.register(
        name: 'Wrong Pass',
        email: 'wrong@example.com',
        password: 'password123',
      );

      expect(
        () => authService.login(
          email: 'wrong@example.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('login fails with non-existent email', () {
      expect(
        () => authService.login(
          email: 'nonexistent@example.com',
          password: 'password123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('verifyToken validates a valid token', () {
      authService.register(
        name: 'Token Test',
        email: 'token@example.com',
        password: 'password123',
      );

      final token = authService.login(
        email: 'token@example.com',
        password: 'password123',
      );

      final payload = authService.verifyToken(token);
      expect(payload['email'], equals('token@example.com'));
      expect(payload['role'], equals('customer'));
    });

    test('verifyToken rejects invalid token', () {
      expect(
        () => authService.verifyToken('invalid-token'),
        throwsA(isA<AuthException>()),
      );
    });

    test('getUserById returns correct user', () {
      final user = authService.register(
        name: 'Find Me',
        email: 'find@example.com',
        password: 'password123',
      );

      final found = authService.getUserById(user.id);
      expect(found, isNotNull);
      expect(found!.email, equals('find@example.com'));
    });

    test('getUserByEmail returns correct user', () {
      authService.register(
        name: 'Find Email',
        email: 'findemail@example.com',
        password: 'password123',
      );

      final found = authService.getUserByEmail('findemail@example.com');
      expect(found, isNotNull);
      expect(found!.name, equals('Find Email'));
    });
  });
}
