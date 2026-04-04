import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/inventory_service.dart';

/// Routes for inventory management.
class InventoryRoutes {
  final _inventoryService = InventoryService();

  Router get router {
    final router = Router();

    /// GET /api/inventory — get all inventory items.
    router.get('/', (Request request) {
      final items =
          _inventoryService.getAllItems().map((i) => i.toJson()).toList();
      return Response.ok(
        jsonEncode({'items': items}),
        headers: {'content-type': 'application/json'},
      );
    });

    /// GET /api/inventory/<id> — get a specific item.
    router.get('/<id>', (Request request, String id) {
      final item = _inventoryService.getItem(id);
      if (item == null) {
        return Response(
          404,
          body: jsonEncode({'error': 'Item not found.'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'item': item.toJson()}),
        headers: {'content-type': 'application/json'},
      );
    });

    /// POST /api/inventory — add a new inventory item.
    router.post('/', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final name = body['name'] as String?;

        if (name == null) {
          return Response(
            400,
            body: jsonEncode({'error': 'Item name is required.'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final item = _inventoryService.addItem(
          name: name,
          quantity: body['quantity'] as int? ?? 0,
          unit: body['unit'] as String? ?? 'pieces',
          autoOutOfStock: body['autoOutOfStock'] as bool? ?? true,
          lowStockThreshold: body['lowStockThreshold'] as int? ?? 0,
        );

        return Response(
          201,
          body: jsonEncode({
            'message': 'Item added successfully.',
            'item': item.toJson(),
          }),
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

    /// PUT /api/inventory/<id> — update an inventory item.
    router.put('/<id>', (Request request, String id) async {
      try {
        final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

        final item = _inventoryService.updateItem(
          id,
          name: body['name'] as String?,
          unit: body['unit'] as String?,
          autoOutOfStock: body['autoOutOfStock'] as bool?,
          lowStockThreshold: body['lowStockThreshold'] as int?,
        );

        // Update stock if provided
        if (body.containsKey('quantity')) {
          _inventoryService.updateStock(id, body['quantity'] as int);
        }

        return Response.ok(
          jsonEncode({
            'message': 'Item updated successfully.',
            'item': item.toJson(),
          }),
          headers: {'content-type': 'application/json'},
        );
      } on InventoryException catch (e) {
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

    /// PUT /api/inventory/<id>/stock — update stock quantity.
    router.put('/<id>/stock', (Request request, String id) async {
      try {
        final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final quantity = body['quantity'] as int?;

        if (quantity == null) {
          return Response(
            400,
            body: jsonEncode({'error': 'Quantity is required.'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final item = _inventoryService.updateStock(id, quantity);
        return Response.ok(
          jsonEncode({
            'message': 'Stock updated.',
            'item': item.toJson(),
          }),
          headers: {'content-type': 'application/json'},
        );
      } on InventoryException catch (e) {
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

    /// PUT /api/inventory/<id>/out-of-stock — set out-of-stock status.
    router.put('/<id>/out-of-stock', (Request request, String id) async {
      try {
        final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final outOfStock = body['outOfStock'] as bool?;

        if (outOfStock == null) {
          return Response(
            400,
            body: jsonEncode({'error': 'outOfStock field is required.'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final item = _inventoryService.setOutOfStock(id, outOfStock);
        return Response.ok(
          jsonEncode({
            'message': outOfStock ? 'Item marked as out of stock.' : 'Item restocked.',
            'item': item.toJson(),
          }),
          headers: {'content-type': 'application/json'},
        );
      } on InventoryException catch (e) {
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

    /// DELETE /api/inventory/<id> — remove an inventory item.
    router.delete('/<id>', (Request request, String id) {
      try {
        _inventoryService.removeItem(id);
        return Response.ok(
          jsonEncode({'message': 'Item removed.'}),
          headers: {'content-type': 'application/json'},
        );
      } on InventoryException catch (e) {
        return Response(
          404,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    /// GET /api/inventory/status/out-of-stock — get out-of-stock items.
    router.get('/status/out-of-stock', (Request request) {
      final items =
          _inventoryService.getOutOfStockItems().map((i) => i.toJson()).toList();
      return Response.ok(
        jsonEncode({'items': items}),
        headers: {'content-type': 'application/json'},
      );
    });

    /// GET /api/inventory/status/low-stock — get low-stock items.
    router.get('/status/low-stock', (Request request) {
      final items =
          _inventoryService.getLowStockItems().map((i) => i.toJson()).toList();
      return Response.ok(
        jsonEncode({'items': items}),
        headers: {'content-type': 'application/json'},
      );
    });

    return router;
  }
}
