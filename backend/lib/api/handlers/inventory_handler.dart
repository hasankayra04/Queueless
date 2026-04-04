// Inventory HTTP handlers

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../middleware.dart';
import '../../services/inventory_service.dart';
import '../../services/business_service.dart';
import '../../models/user.dart';

Router inventoryRouter(
    InventoryService inventoryService, BusinessService businessService) {
  final router = Router();

  // GET /inventory/:businessId  — list all items (public)
  router.get('/<businessId>', (Request req, String businessId) async {
    final items = inventoryService.getInventory(businessId);
    return ok(items.map((i) => i.toJson()).toList());
  });

  // POST /inventory/:businessId  — add item (owner only)
  router.post('/<businessId>', (Request req, String businessId) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();
    if (user.role != UserRole.businessOwner) return forbidden();

    final business = businessService.getBusiness(businessId);
    if (business == null) return notFound('Business not found');
    if (business.ownerId != user.id) return forbidden();

    final body = await parseBody(req);
    final name = body['name'] as String? ?? '';
    if (name.trim().isEmpty) return badRequest('Item name is required');

    final quantity = (body['quantity'] as num?)?.toInt() ?? 0;
    final description = body['description'] as String?;
    final lowStockThreshold =
        (body['lowStockThreshold'] as num?)?.toInt();
    final price = (body['price'] as num?)?.toDouble();

    final item = inventoryService.addItem(
      businessId: businessId,
      name: name,
      quantity: quantity,
      description: description,
      lowStockThreshold: lowStockThreshold,
      price: price,
    );
    return created(item.toJson());
  });

  // PATCH /inventory/:businessId/:itemId  — update item (owner only)
  router.patch('/<businessId>/<itemId>',
      (Request req, String businessId, String itemId) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();
    if (user.role != UserRole.businessOwner) return forbidden();

    final business = businessService.getBusiness(businessId);
    if (business == null) return notFound('Business not found');
    if (business.ownerId != user.id) return forbidden();

    final body = await parseBody(req);

    // Update quantity if provided
    if (body.containsKey('quantity')) {
      final newQty = (body['quantity'] as num).toInt();
      final result = inventoryService.updateQuantity(
        businessId: businessId,
        itemId: itemId,
        newQuantity: newQty,
      );
      if (result.error != null) return badRequest(result.error!);
    }

    // Update metadata
    final result = inventoryService.updateItem(
      businessId: businessId,
      itemId: itemId,
      name: body['name'] as String?,
      description: body['description'] as String?,
      lowStockThreshold:
          (body['lowStockThreshold'] as num?)?.toInt(),
      price: (body['price'] as num?)?.toDouble(),
    );
    if (result.error != null) return badRequest(result.error!);
    return ok(result.item!.toJson());
  });

  // POST /inventory/:businessId/:itemId/out-of-stock  — mark out of stock (owner)
  router.post('/<businessId>/<itemId>/out-of-stock',
      (Request req, String businessId, String itemId) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();
    if (user.role != UserRole.businessOwner) return forbidden();

    final business = businessService.getBusiness(businessId);
    if (business == null) return notFound('Business not found');
    if (business.ownerId != user.id) return forbidden();

    final result = inventoryService.markOutOfStock(
      businessId: businessId,
      itemId: itemId,
    );
    if (result.error != null) return badRequest(result.error!);
    return ok(result.item!.toJson());
  });

  // DELETE /inventory/:businessId/:itemId  — delete item (owner only)
  router.delete('/<businessId>/<itemId>',
      (Request req, String businessId, String itemId) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();
    if (user.role != UserRole.businessOwner) return forbidden();

    final business = businessService.getBusiness(businessId);
    if (business == null) return notFound('Business not found');
    if (business.ownerId != user.id) return forbidden();

    final result = inventoryService.deleteItem(
      businessId: businessId,
      itemId: itemId,
    );
    if (result.error != null) return notFound(result.error!);
    return ok({'message': 'Item deleted'});
  });

  return router;
}
