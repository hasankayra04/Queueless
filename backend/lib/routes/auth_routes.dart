import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

/// Routes for user authentication (login / register).
class AuthRoutes {
  final _authService = AuthService();

  Router get router {
    final router = Router();

    /// POST /api/auth/register
    router.post('/register', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final name = body['name'] as String?;
        final email = body['email'] as String?;
        final password = body['password'] as String?;
        final roleStr = body['role'] as String?;

        if (name == null || email == null || password == null) {
          return Response(
            400,
            body: jsonEncode({'error': 'Name, email, and password are required.'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final role = roleStr == 'owner' ? UserRole.owner : UserRole.customer;
        final user = _authService.register(
          name: name,
          email: email,
          password: password,
          role: role,
        );

        return Response(
          201,
          body: jsonEncode({
            'message': 'User registered successfully.',
            'user': user.toJson(),
          }),
          headers: {'content-type': 'application/json'},
        );
      } on AuthException catch (e) {
        return Response(
          400,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'},
        );
      } on FormatException {
        return Response(
          400,
          body: jsonEncode({'error': 'Invalid JSON body.'}),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    /// POST /api/auth/login
    router.post('/login', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final email = body['email'] as String?;
        final password = body['password'] as String?;

        if (email == null || password == null) {
          return Response(
            400,
            body: jsonEncode({'error': 'Email and password are required.'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final token = _authService.login(email: email, password: password);

        return Response.ok(
          jsonEncode({'token': token}),
          headers: {'content-type': 'application/json'},
        );
      } on AuthException catch (e) {
        return Response(
          401,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'},
        );
      } on FormatException {
        return Response(
          400,
          body: jsonEncode({'error': 'Invalid JSON body.'}),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    /// GET /api/auth/me — get current user info (requires auth).
    router.get('/me', (Request request) {
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response(
          401,
          body: jsonEncode({'error': 'Not authenticated.'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final user = _authService.getUserById(userId);
      if (user == null) {
        return Response(
          404,
          body: jsonEncode({'error': 'User not found.'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'user': user.toJson()}),
        headers: {'content-type': 'application/json'},
      );
    });

    return router;
  }
}
