import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../models/queue_entry.dart';
import '../services/queue_manager.dart';

/// Routes for queue management.
class QueueRoutes {
  final _queueManager = QueueManager();

  Router get router {
    final router = Router();

    /// GET /api/queue — get the current queue.
    router.get('/', (Request request) {
      final entries = _queueManager.queue.map((e) => e.toJson()).toList();
      return Response.ok(
        jsonEncode({
          'queue': entries,
          'waitingCount': _queueManager.waitingCount,
        }),
        headers: {'content-type': 'application/json'},
      );
    });

    /// POST /api/queue/join — join the queue.
    router.post('/join', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final customerId =
            body['customerId'] as String? ?? request.context['userId'] as String?;
        final customerName = body['customerName'] as String?;
        final priorityStr = body['priority'] as String?;

        if (customerId == null || customerName == null) {
          return Response(
            400,
            body: jsonEncode(
                {'error': 'customerId and customerName are required.'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final priority = priorityStr != null
            ? QueuePriority.values.byName(priorityStr)
            : QueuePriority.normal;

        final entry = _queueManager.joinQueue(
          customerId: customerId,
          customerName: customerName,
          priority: priority,
        );

        return Response(
          201,
          body: jsonEncode({
            'message': 'Successfully joined the queue.',
            'entry': entry.toJson(),
          }),
          headers: {'content-type': 'application/json'},
        );
      } on QueueException catch (e) {
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

    /// DELETE /api/queue/<entryId> — leave the queue.
    router.delete('/<entryId>', (Request request, String entryId) {
      try {
        _queueManager.leaveQueue(entryId);
        return Response.ok(
          jsonEncode({'message': 'Successfully left the queue.'}),
          headers: {'content-type': 'application/json'},
        );
      } on QueueException catch (e) {
        return Response(
          404,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    /// GET /api/queue/position/<customerId> — get customer's position.
    router.get('/position/<customerId>',
        (Request request, String customerId) {
      final position = _queueManager.getCustomerPosition(customerId);
      if (position == null) {
        return Response(
          404,
          body: jsonEncode({'error': 'Customer not found in queue.'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(position),
        headers: {'content-type': 'application/json'},
      );
    });

    /// POST /api/queue/serve-next — serve the next person (owner only).
    router.post('/serve-next', (Request request) {
      final entry = _queueManager.serveNext();
      if (entry == null) {
        return Response(
          404,
          body: jsonEncode({'error': 'Queue is empty.'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'message': 'Now serving customer.',
          'entry': entry.toJson(),
        }),
        headers: {'content-type': 'application/json'},
      );
    });

    /// POST /api/queue/<entryId>/complete — mark service as completed.
    router.post('/<entryId>/complete', (Request request, String entryId) {
      try {
        _queueManager.completeService(entryId);
        return Response.ok(
          jsonEncode({'message': 'Service completed.'}),
          headers: {'content-type': 'application/json'},
        );
      } on QueueException catch (e) {
        return Response(
          404,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    /// PUT /api/queue/<entryId>/priority — change entry priority.
    router.put('/<entryId>/priority',
        (Request request, String entryId) async {
      try {
        final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final priorityStr = body['priority'] as String?;

        if (priorityStr == null) {
          return Response(
            400,
            body: jsonEncode({'error': 'Priority is required.'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final priority = QueuePriority.values.byName(priorityStr);
        _queueManager.setPriority(entryId, priority);

        return Response.ok(
          jsonEncode({'message': 'Priority updated.'}),
          headers: {'content-type': 'application/json'},
        );
      } on QueueException catch (e) {
        return Response(
          404,
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

    return router;
  }
}
