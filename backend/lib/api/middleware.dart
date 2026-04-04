// Shared API utilities: response helpers, auth middleware

import 'dart:convert';
import 'package:shelf/shelf.dart';

import '../services/auth_service.dart';
import '../models/user.dart';

// ── Response helpers ──────────────────────────────────────────────────────────

Response ok(dynamic body) => Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Response created(dynamic body) => Response(
      201,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Response badRequest(String message) => Response(
      400,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );

Response unauthorized([String message = 'Unauthorized']) => Response(
      401,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );

Response forbidden([String message = 'Forbidden']) => Response(
      403,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );

Response notFound([String message = 'Not found']) => Response(
      404,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );

Response serverError([String message = 'Internal server error']) => Response(
      500,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );

// ── Body parsing ─────────────────────────────────────────────────────────────

Future<Map<String, dynamic>> parseBody(Request req) async {
  final body = await req.readAsString();
  if (body.isEmpty) return {};
  return jsonDecode(body) as Map<String, dynamic>;
}

// ── Auth middleware ───────────────────────────────────────────────────────────

const _tokenKey = 'token';

/// Extracts Bearer token from Authorization header.
String? extractToken(Request req) {
  final auth = req.headers['authorization'] ?? '';
  if (auth.startsWith('Bearer ')) return auth.substring(7).trim();
  return null;
}

/// Middleware that injects the authenticated [User] into request context.
Middleware authMiddleware(AuthService authService) {
  return (Handler inner) {
    return (Request req) async {
      final token = extractToken(req);
      if (token == null) return unauthorized();

      final user = authService.getUserFromToken(token);
      if (user == null) return unauthorized('Invalid or expired token');

      final updatedReq = req.change(context: {_tokenKey: user});
      return inner(updatedReq);
    };
  };
}

/// Retrieve the authenticated user from request context (set by authMiddleware).
User? currentUser(Request req) => req.context[_tokenKey] as User?;
