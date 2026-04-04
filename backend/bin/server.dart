import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:queueless_backend/middleware/auth_middleware.dart';
import 'package:queueless_backend/routes/auth_routes.dart';
import 'package:queueless_backend/routes/inventory_routes.dart';
import 'package:queueless_backend/routes/queue_routes.dart';

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // Build the router
  final app = Router();

  // Public auth routes (no auth required for login/register)
  app.mount('/api/auth/', AuthRoutes().router.call);

  // Protected queue routes
  final queueHandler = const Pipeline()
      .addMiddleware(authMiddleware())
      .addHandler(QueueRoutes().router.call);
  app.mount('/api/queue/', queueHandler);

  // Protected inventory routes
  final inventoryHandler = const Pipeline()
      .addMiddleware(authMiddleware())
      .addHandler(InventoryRoutes().router.call);
  app.mount('/api/inventory/', inventoryHandler);

  // Health check
  app.get('/health', (Request request) {
    return Response.ok('{"status": "ok"}',
        headers: {'content-type': 'application/json'});
  });

  // Build the pipeline with CORS and logging
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(app.call);

  final server = await shelf_io.serve(handler, ip, port);
  print(
      '🚀 QueueLess server running on http://${server.address.host}:${server.port}');
}
