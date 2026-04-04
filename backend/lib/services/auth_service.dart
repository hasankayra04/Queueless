import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../core/event_bus.dart';
import '../models/user.dart';

/// Service for user authentication and authorization.
///
/// Provides secure login/registration with password hashing and JWT tokens.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _users = <String, User>{};
  final _eventBus = EventBus();

  // In production, use a proper secret management system.
  static const _jwtSecret = 'queueless-jwt-secret-key-change-in-production';
  static const _tokenExpiry = Duration(hours: 24);

  /// Hash a password using SHA-256 with a salt.
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  /// Generate a random salt.
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Generate a unique ID.
  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Register a new user.
  ///
  /// Returns the created user or throws if email already exists.
  User register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.customer,
  }) {
    // Check for existing user
    final existing = _users.values.where((u) => u.email == email);
    if (existing.isNotEmpty) {
      throw AuthException('A user with this email already exists.');
    }

    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }

    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);
    final user = User(
      id: _generateId(),
      name: name,
      email: email,
      passwordHash: '$salt:$passwordHash',
      role: role,
    );

    _users[user.id] = user;
    _eventBus.publish(AppEvent(
      type: EventType.userRegistered,
      data: {'userId': user.id, 'email': email, 'role': role.name},
    ));
    return user;
  }

  /// Authenticate a user and return a JWT token.
  ///
  /// Returns a token string or throws if credentials are invalid.
  String login({required String email, required String password}) {
    final user = _users.values.where((u) => u.email == email).firstOrNull;
    if (user == null) {
      throw AuthException('Invalid email or password.');
    }

    final parts = user.passwordHash.split(':');
    if (parts.length != 2) {
      throw AuthException('Invalid email or password.');
    }

    final salt = parts[0];
    final storedHash = parts[1];
    final inputHash = _hashPassword(password, salt);

    if (inputHash != storedHash) {
      throw AuthException('Invalid email or password.');
    }

    final jwt = JWT({
      'userId': user.id,
      'email': user.email,
      'role': user.role.name,
    });

    final token = jwt.sign(
      SecretKey(_jwtSecret),
      expiresIn: _tokenExpiry,
    );

    _eventBus.publish(AppEvent(
      type: EventType.userLoggedIn,
      data: {'userId': user.id, 'email': email},
    ));

    return token;
  }

  /// Verify a JWT token and return the payload.
  ///
  /// Throws if the token is invalid or expired.
  Map<String, dynamic> verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      return jwt.payload as Map<String, dynamic>;
    } on JWTExpiredException {
      throw AuthException('Token has expired.');
    } on JWTException {
      throw AuthException('Invalid token.');
    }
  }

  /// Get a user by their ID.
  User? getUserById(String id) => _users[id];

  /// Get a user by their email.
  User? getUserByEmail(String email) =>
      _users.values.where((u) => u.email == email).firstOrNull;

  /// Get all users.
  List<User> getAllUsers() => _users.values.toList();
}

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
