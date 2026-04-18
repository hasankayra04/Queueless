// QueueManager — the Observer Subject.
// Manages all queues, notifies Customer observers on every state change.

import 'package:uuid/uuid.dart';

import '../models/queue_entry.dart';
import '../patterns/observer.dart';
import '../patterns/event_bus.dart';
import '../database/in_memory_db.dart';

class QueueManager implements QueueSubject {
  final InMemoryDatabase _db;
  final EventBus _bus;
  final _uuid = const Uuid();

  /// Per-queue observer lists: queueId (== businessId) → observers
  final Map<String, List<QueueObserver>> _observers = {};

  QueueManager(this._db, this._bus);

  // ── QueueSubject ───────────────────────────────────────────────────────────

  @override
  void addObserver(QueueObserver observer) {
    // Observers registered globally across all queues are stored under '*'
    _observers.putIfAbsent('*', () => []).add(observer);
  }

  @override
  void removeObserver(QueueObserver observer) {
    for (final list in _observers.values) {
      list.remove(observer);
    }
  }

  @override
  void notifyObservers(QueueChangedEvent event) {
    final global = _observers['*'] ?? [];
    final perQueue = _observers[event.queueId] ?? [];
    for (final obs in [...global, ...perQueue]) {
      obs.onQueueUpdated(event);
    }
  }

  void addQueueObserver(String queueId, QueueObserver observer) {
    _observers.putIfAbsent(queueId, () => []).add(observer);
  }

  // ── Queue operations ───────────────────────────────────────────────────────

  /// Customer joins the queue for [businessId].
  ({String? error, QueueEntry? entry}) joinQueue({
    required String businessId,
    required String customerId,
    required String customerName,
    QueuePriority priority = QueuePriority.normal,
    String? note,
  }) {
    // Prevent duplicate active entries
    if (_db.findEntryByCustomer(businessId, customerId) != null) {
      return (error: 'Already in this queue', entry: null);
    }

    _db.queues.putIfAbsent(businessId, () => []);
    final queue = _db.getQueue(businessId);
    final position = queue.length + 1;

    final entry = QueueEntry(
      id: _uuid.v4(),
      queueId: businessId,
      customerId: customerId,
      customerName: customerName,
      priority: priority,
      position: position,
      note: note,
    );
    _db.queues[businessId]!.add(entry);
    _recomputePositions(businessId);

    final updatedEntry = _db.findEntry(businessId, entry.id)!;

    // Notify observers
    notifyObservers(QueueChangedEvent(
      queueId: businessId,
      changeType: QueueChangeType.customerJoined,
      customerId: customerId,
      newPosition: updatedEntry.position,
    ));

    // Publish to event bus
    _bus.emit(CustomerJoinedEvent(
      queueId: businessId,
      customerId: customerId,
      customerName: customerName,
      position: updatedEntry.position,
    ));

    return (error: null, entry: updatedEntry);
  }

  /// Customer leaves (cancels) their queue entry.
  ({String? error}) leaveQueue({
    required String businessId,
    required String customerId,
  }) {
    final entry = _db.findEntryByCustomer(businessId, customerId);
    if (entry == null) return (error: 'Not in queue');

    entry.status = QueueEntryStatus.cancelled;
    _recomputePositions(businessId);

    notifyObservers(QueueChangedEvent(
      queueId: businessId,
      changeType: QueueChangeType.customerLeft,
      customerId: customerId,
    ));
    _bus.emit(CustomerLeftEvent(queueId: businessId, customerId: customerId));
    return (error: null);
  }

  /// Serve (dequeue) the next customer or a specific entry.
  ({String? error, QueueEntry? entry}) serveNext({
    required String businessId,
    String? specificEntryId,
  }) {
    final queue = _db.getQueue(businessId);
    if (queue.isEmpty) return (error: 'Queue is empty', entry: null);

    QueueEntry? entry;
    if (specificEntryId != null) {
      entry = queue.where((e) => e.id == specificEntryId).firstOrNull;
      if (entry == null) return (error: 'Entry not found', entry: null);
    } else {
      entry = queue.first; // already sorted by priority + position
    }

    entry.status = QueueEntryStatus.serving;
    entry.servedAt = DateTime.now();
    _recomputePositions(businessId);

    notifyObservers(QueueChangedEvent(
      queueId: businessId,
      changeType: QueueChangeType.customerServed,
      customerId: entry.customerId,
    ));
    _bus.emit(CustomerServedEvent(
        queueId: businessId, customerId: entry.customerId));
    return (error: null, entry: entry);
  }

  /// Owner promotes a customer to VIP or Urgent priority.
  ({String? error}) setPriority({
    required String businessId,
    required String entryId,
    required QueuePriority priority,
  }) {
    final entry = _db.findEntry(businessId, entryId);
    if (entry == null || entry.status != QueueEntryStatus.waiting) {
      return (error: 'Entry not found or not waiting');
    }

    entry.priority = priority;
    _recomputePositions(businessId);

    final changeType = priority == QueuePriority.urgent
        ? QueueChangeType.urgentPrioritized
        : QueueChangeType.vipPrioritized;

    notifyObservers(QueueChangedEvent(
      queueId: businessId,
      changeType: changeType,
      customerId: entry.customerId,
      newPosition: entry.position,
    ));
    return (error: null);
  }

  /// Returns the active (waiting) queue for a business, sorted by priority+position.
  List<QueueEntry> getQueue(String businessId) => _db.getQueue(businessId);

  /// Returns the queue entry for a specific customer in a specific business.
  QueueEntry? getCustomerEntry(String businessId, String customerId) =>
      _db.findEntryByCustomer(businessId, customerId);

  // ── Internal helpers ───────────────────────────────────────────────────────

  /// Recalculate sequential positions after any change.
  void _recomputePositions(String businessId) {
    final sorted = _db.getQueue(businessId); // already sorted
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i].position != i + 1) {
        sorted[i].position = i + 1;
        notifyObservers(QueueChangedEvent(
          queueId: businessId,
          changeType: QueueChangeType.positionChanged,
          customerId: sorted[i].customerId,
          newPosition: i + 1,
        ));
      }
    }
  }
}
