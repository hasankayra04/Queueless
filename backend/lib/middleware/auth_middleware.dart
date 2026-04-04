import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../services/auth_service.dart';

/// Middleware that verifies JWT tokens for protected routes.
///
/// Extracts the token from the Authorization header, verifies it,
/// and adds user info to the request context.
Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(
          401,
          body: jsonEncode({'error': 'Missing or invalid authorization header.'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final token = authHeader.substring(7);
      try {
        final payload = AuthService().verifyToken(token);
        final updatedRequest = request.change(
          context: {
            ...request.context,
            'userId': payload['userId'],
            'email': payload['email'],
            'role': payload['role'],
          },
        );
        return innerHandler(updatedRequest);
      } on AuthException catch (e) {
        return Response(
          401,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

/// Middleware that checks if the user has the 'owner' role.
Middleware ownerOnly() {
  return (Handler innerHandler) {
    return (Request request) {
      final role = request.context['role'] as String?;
      if (role != 'owner') {
        return Response(
          403,
          body: jsonEncode({'error': 'Access denied. Owner role required.'}),
          headers: {'content-type': 'application/json'},
        );
      }
      return innerHandler(request);
    };
  };
}
