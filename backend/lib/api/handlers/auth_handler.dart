// Auth HTTP handlers

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../middleware.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

Router authRouter(AuthService authService) {
  final router = Router();

  // POST /auth/register
  router.post('/register', (Request req) async {
    final body = await parseBody(req);
    final name = body['name'] as String? ?? '';
    final email = body['email'] as String? ?? '';
    final password = body['password'] as String? ?? '';
    final roleStr = body['role'] as String? ?? 'customer';

    final role =
        roleStr == 'businessOwner' ? UserRole.businessOwner : UserRole.customer;

    final result =
        authService.register(name: name, email: email, password: password, role: role);
    if (result.error != null) return badRequest(result.error!);

    return created({'message': 'Registered successfully', 'user': result.user!.toJson()});
  });

  // POST /auth/login
  router.post('/login', (Request req) async {
    final body = await parseBody(req);
    final email = body['email'] as String? ?? '';
    final password = body['password'] as String? ?? '';

    final result = authService.login(email: email, password: password);
    if (result.error != null) return badRequest(result.error!);

    return ok({'token': result.token, 'user': result.user!.toJson()});
  });

  // POST /auth/logout  (requires auth)
  router.post('/logout', (Request req) async {
    final token = extractToken(req);
    if (token != null) authService.logout(token);
    return ok({'message': 'Logged out'});
  });

  // GET /auth/me  (requires auth)
  router.get('/me', (Request req) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();
    return ok(user.toJson());
  });

  return router;
}
