// Business HTTP handlers

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../middleware.dart';
import '../../services/business_service.dart';
import '../../models/user.dart';

Router businessRouter(BusinessService businessService) {
  final router = Router();

  // GET /businesses  — list all businesses (public)
  router.get('/', (Request req) async {
    final businesses = businessService.getAllBusinesses();
    return ok(businesses.map((b) => b.toJson()).toList());
  });

  // GET /businesses/:id  — get single business (public)
  router.get('/<id>', (Request req, String id) async {
    final b = businessService.getBusiness(id);
    if (b == null) return notFound('Business not found');
    return ok(b.toJson());
  });

  // POST /businesses  — create business (owner only)
  router.post('/', (Request req) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();
    if (user.role != UserRole.businessOwner) {
      return forbidden('Only business owners can create businesses');
    }

    final body = await parseBody(req);
    final name = body['name'] as String? ?? '';
    final description = body['description'] as String? ?? '';
    final category = body['category'] as String? ?? '';
    if (name.trim().isEmpty) return badRequest('Business name is required');
    if (category.trim().isEmpty) return badRequest('Category is required');

    final b = businessService.createBusiness(
      ownerId: user.id,
      name: name,
      description: description,
      category: category,
      address: body['address'] as String?,
      avgServiceTimeMinutes:
          (body['avgServiceTimeMinutes'] as num?)?.toInt() ?? 5,
    );
    return created(b.toJson());
  });

  // PATCH /businesses/:id  — update business (owner only)
  router.patch('/<id>', (Request req, String id) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();
    if (user.role != UserRole.businessOwner) return forbidden();

    final body = await parseBody(req);
    final result = businessService.updateBusiness(
      businessId: id,
      requesterId: user.id,
      name: body['name'] as String?,
      description: body['description'] as String?,
      category: body['category'] as String?,
      address: body['address'] as String?,
      avgServiceTimeMinutes:
          (body['avgServiceTimeMinutes'] as num?)?.toInt(),
      isOpen: body['isOpen'] as bool?,
    );
    if (result.error != null) return badRequest(result.error!);
    return ok(result.business!.toJson());
  });

  // GET /businesses/my  — list owner's businesses (owner only)
  router.get('/my', (Request req) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();
    if (user.role != UserRole.businessOwner) return forbidden();

    final businesses = businessService.getBusinessesByOwner(user.id);
    return ok(businesses.map((b) => b.toJson()).toList());
  });

  return router;
}
