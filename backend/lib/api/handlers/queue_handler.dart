// Queue HTTP handlers

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../middleware.dart';
import '../../services/queue_manager.dart';
import '../../services/business_service.dart';
import '../../models/queue_entry.dart';
import '../../models/user.dart';

Router queueRouter(QueueManager queueManager, BusinessService businessService) {
  final router = Router();

  // GET /queue/:businessId  — get current queue (public)
  router.get('/<businessId>', (Request req, String businessId) async {
    final business = businessService.getBusiness(businessId);
    if (business == null) return notFound('Business not found');

    final queue = queueManager.getQueue(businessId);
    final business_ = business;
    return ok({
      'businessId': businessId,
      'businessName': business_.name,
      'avgServiceTimeMinutes': business_.avgServiceTimeMinutes,
      'entries': queue
          .map((e) => {
                ...e.toJson(),
                'estimatedWaitMinutes':
                    e.estimatedWaitMinutes(business_.avgServiceTimeMinutes),
              })
          .toList(),
      'totalWaiting': queue.length,
    });
  });

  // GET /queue/:businessId/my  — get current user's queue entry (requires auth)
  router.get('/<businessId>/my', (Request req, String businessId) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();

    final entry = queueManager.getCustomerEntry(businessId, user.id);
    if (entry == null) return notFound('Not in queue');

    final business = businessService.getBusiness(businessId);
    return ok({
      ...entry.toJson(),
      'estimatedWaitMinutes': entry
          .estimatedWaitMinutes(business?.avgServiceTimeMinutes ?? 5),
    });
  });

  // POST /queue/:businessId/join  — customer joins queue (requires auth)
  router.post('/<businessId>/join', (Request req, String businessId) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();
    if (user.role != UserRole.customer) {
      return forbidden('Only customers can join queues');
    }

    final business = businessService.getBusiness(businessId);
    if (business == null) return notFound('Business not found');
    if (!business.isOpen) return badRequest('Business is currently closed');

    final body = await parseBody(req);
    final note = body['note'] as String?;

    final result = queueManager.joinQueue(
      businessId: businessId,
      customerId: user.id,
      customerName: user.name,
      note: note,
    );
    if (result.error != null) return badRequest(result.error!);

    return created({
      ...result.entry!.toJson(),
      'estimatedWaitMinutes':
          result.entry!.estimatedWaitMinutes(business.avgServiceTimeMinutes),
    });
  });

  // DELETE /queue/:businessId/leave  — customer leaves queue (requires auth)
  router.delete('/<businessId>/leave', (Request req, String businessId) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();

    final result = queueManager.leaveQueue(
      businessId: businessId,
      customerId: user.id,
    );
    if (result.error != null) return badRequest(result.error!);
    return ok({'message': 'Left queue successfully'});
  });

  // POST /queue/:businessId/serve-next  — owner serves next customer (requires auth)
  router.post('/<businessId>/serve-next',
      (Request req, String businessId) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();
    if (user.role != UserRole.businessOwner) {
      return forbidden('Only business owners can serve customers');
    }

    final business = businessService.getBusiness(businessId);
    if (business == null) return notFound('Business not found');
    if (business.ownerId != user.id) return forbidden();

    final body = await parseBody(req);
    final specificEntryId = body['entryId'] as String?;

    final result = queueManager.serveNext(
      businessId: businessId,
      specificEntryId: specificEntryId,
    );
    if (result.error != null) return badRequest(result.error!);
    return ok(result.entry!.toJson());
  });

  // PATCH /queue/:businessId/entry/:entryId/priority  — set priority (owner)
  router.patch('/<businessId>/entry/<entryId>/priority',
      (Request req, String businessId, String entryId) async {
    final user = currentUser(req);
    if (user == null) return unauthorized();
    if (user.role != UserRole.businessOwner) return forbidden();

    final business = businessService.getBusiness(businessId);
    if (business == null) return notFound('Business not found');
    if (business.ownerId != user.id) return forbidden();

    final body = await parseBody(req);
    final priorityStr = body['priority'] as String? ?? 'normal';
    final priority = QueuePriority.values.firstWhere(
      (p) => p.name == priorityStr,
      orElse: () => QueuePriority.normal,
    );

    final result = queueManager.setPriority(
      businessId: businessId,
      entryId: entryId,
      priority: priority,
    );
    if (result.error != null) return badRequest(result.error!);
    return ok({'message': 'Priority updated'});
  });

  return router;
}
