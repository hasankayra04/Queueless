import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'api_client.dart';

/// Service for authentication state management.
///
/// Uses [ChangeNotifier] for Flutter's Provider pattern to notify
/// the UI when auth state changes.
class AuthService extends ChangeNotifier {
  final ApiClient _api;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthService(this._api);

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isOwner => _currentUser?.role == UserRole.owner;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Register a new user.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.customer,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/api/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'role': role.name,
      });

      _currentUser =
          User.fromJson(response['user'] as Map<String, dynamic>);

      // Auto-login after registration
      await login(email: email, password: password);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Log in with email and password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/api/auth/login', {
        'email': email,
        'password': password,
      });

      _api.token = response['token'] as String;

      // Fetch user info
      final meResponse = await _api.get('/api/auth/me');
      _currentUser =
          User.fromJson(meResponse['user'] as Map<String, dynamic>);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Log out the current user.
  void logout() {
    _currentUser = null;
    _api.token = null;
    notifyListeners();
  }

  /// Clear any error messages.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
