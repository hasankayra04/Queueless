// Server entry point — wires all services and starts the HTTP server

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:queueless_backend/database/in_memory_db.dart';
import 'package:queueless_backend/patterns/event_bus.dart';
import 'package:queueless_backend/services/auth_service.dart';
import 'package:queueless_backend/services/business_service.dart';
import 'package:queueless_backend/services/queue_manager.dart';
import 'package:queueless_backend/services/inventory_service.dart';
import 'package:queueless_backend/api/middleware.dart';
import 'package:queueless_backend/api/handlers/auth_handler.dart';
import 'package:queueless_backend/api/handlers/business_handler.dart';
import 'package:queueless_backend/api/handlers/queue_handler.dart';
import 'package:queueless_backend/api/handlers/inventory_handler.dart';

void main(List<String> args) async {
  final port = int.tryParse(
          Platform.environment['PORT'] ??
              (args.isNotEmpty ? args[0] : '8080')) ??
      8080;

  // ── Dependency injection ──────────────────────────────────────────────────
  final db = InMemoryDatabase();
  final bus = EventBus();
  final authService = AuthService(db);
  final businessService = BusinessService(db);
  final queueManager = QueueManager(db, bus);
  final inventoryService = InventoryService(db, bus);

  // ── Event bus listeners (logging) ─────────────────────────────────────────
  bus.on<CustomerJoinedEvent>((e) {
    print('[EventBus] ${e.customerName} joined queue ${e.queueId} at position ${e.position}');
  });
  bus.on<CustomerServedEvent>((e) {
    print('[EventBus] Customer ${e.customerId} served in queue ${e.queueId}');
  });
  bus.on<ItemOutOfStockEvent>((e) {
    print('[EventBus] Item "${e.itemName}" is now OUT OF STOCK in business ${e.businessId}');
  });

  // ── Route handlers ────────────────────────────────────────────────────────
  // Auth routes inject the current user into context for protected endpoints.
  // Individual handlers check currentUser(req) to enforce authorization.
  final authHandler = Pipeline()
      .addMiddleware(_optionalAuth(authService))
      .addHandler(authRouter(authService).call);

  final businessHandler = Pipeline()
      .addMiddleware(_optionalAuth(authService))
      .addHandler(businessRouter(businessService).call);

  final queueHandler = Pipeline()
      .addMiddleware(_optionalAuth(authService))
      .addHandler(queueRouter(queueManager, businessService).call);

  final inventoryHandler = Pipeline()
      .addMiddleware(_optionalAuth(authService))
      .addHandler(inventoryRouter(inventoryService, businessService).call);

  // ── Top-level router ──────────────────────────────────────────────────────
  final router = Router();

  router.mount('/auth/', authHandler);
  router.mount('/businesses/', businessHandler);
  router.mount('/queue/', queueHandler);
  router.mount('/inventory/', inventoryHandler);
  router.get('/health', (Request req) => ok({'status': 'ok', 'service': 'QueueLess API'}));

  // ── Middleware stack ──────────────────────────────────────────────────────
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  // ── Start server ──────────────────────────────────────────────────────────
  final server = await io.serve(handler, '0.0.0.0', port);
  print('QueueLess API server running on http://${server.address.host}:${server.port}');
}

/// Optional auth middleware — populates user context if a valid token is provided,
/// but does NOT reject the request if no token is present.
/// Individual handlers decide whether auth is required.
Middleware _optionalAuth(AuthService authService) {
  return (Handler inner) => (Request req) async {
        final token = extractToken(req);
        if (token != null) {
          final user = authService.getUserFromToken(token);
          if (user != null) {
            return inner(req.change(context: {'token': user}));
          }
        }
        return inner(req);
      };
}

/// Simple CORS middleware for frontend access.
Middleware _corsMiddleware() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };

  return (Handler inner) => (Request req) async {
        if (req.method == 'OPTIONS') {
          return Response.ok('', headers: headers);
        }
        final res = await inner(req);
        return res.change(headers: {...res.headers, ...headers});
      };
}

