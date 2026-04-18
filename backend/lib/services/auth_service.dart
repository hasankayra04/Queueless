// Authentication service — registration, login, session tokens

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import '../database/in_memory_db.dart';

class AuthService {
  final InMemoryDatabase _db;
  final _uuid = const Uuid();

  /// In-memory session store: token → userId
  final Map<String, String> _sessions = {};

  AuthService(this._db);

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  String _generateToken() => _uuid.v4().replaceAll('-', '');

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Register a new user. Returns [null] on success, error message on failure.
  ({String? error, User? user}) register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    if (name.trim().isEmpty) return (error: 'Name is required', user: null);
    if (!email.contains('@')) return (error: 'Invalid email', user: null);
    if (password.length < 6) {
      return (error: 'Password must be at least 6 characters', user: null);
    }
    if (_db.findUserByEmail(email) != null) {
      return (error: 'Email already registered', user: null);
    }

    final user = User(
      id: _uuid.v4(),
      name: name.trim(),
      email: email.toLowerCase().trim(),
      passwordHash: _hash(password),
      role: role,
    );
    _db.users[user.id] = user;
    return (error: null, user: user);
  }

  /// Login. Returns a session token on success or an error message.
  ({String? error, String? token, User? user}) login({
    required String email,
    required String password,
  }) {
    final user = _db.findUserByEmail(email.toLowerCase().trim());
    if (user == null || user.passwordHash != _hash(password)) {
      return (error: 'Invalid email or password', token: null, user: null);
    }

    final token = _generateToken();
    _sessions[token] = user.id;
    return (error: null, token: token, user: user);
  }

  /// Logout — invalidate the session token.
  void logout(String token) => _sessions.remove(token);

  /// Resolve a token to a User, or null if invalid.
  User? getUserFromToken(String token) {
    final userId = _sessions[token];
    if (userId == null) return null;
    return _db.users[userId];
  }
}
