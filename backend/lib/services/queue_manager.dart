import 'dart:math';

import '../core/event_bus.dart';
import '../core/observer.dart';
import '../models/queue_entry.dart';

/// QueueManager acts as the Subject in the Observer Pattern.
///
/// It manages the queue and notifies all registered [QueueObserver]s
/// when the queue state changes (entries added, removed, or reordered).
class QueueManager {
  static final QueueManager _instance = QueueManager._internal();
  factory QueueManager() => _instance;
  QueueManager._internal();

  final _queue = <QueueEntry>[];
  final _observers = <QueueObserver>[];
  final _eventBus = EventBus();

  /// Get a snapshot of the current queue (waiting entries, sorted by position).
  List<QueueEntry> get queue => List.unmodifiable(
        _queue.where((e) => e.status == QueueStatus.waiting).toList()..sort(),
      );

  /// Get all entries including completed/cancelled.
  List<QueueEntry> get allEntries => List.unmodifiable(_queue);

  /// Number of people currently waiting.
  int get waitingCount =>
      _queue.where((e) => e.status == QueueStatus.waiting).length;

  // --- Observer Pattern Methods ---

  /// Register an observer to receive queue updates.
  void addObserver(QueueObserver observer) {
    _observers.add(observer);
  }

  /// Remove an observer.
  void removeObserver(QueueObserver observer) {
    _observers.remove(observer);
  }

  /// Notify all observers of queue changes.
  void _notifyQueueUpdated() {
    final currentQueue = queue;
    for (final observer in _observers) {
      observer.onQueueUpdated(currentQueue);
    }
  }

  /// Notify all observers of an entry status change.
  void _notifyEntryStatusChanged(QueueEntry entry) {
    for (final observer in _observers) {
      observer.onEntryStatusChanged(entry);
    }
  }

  /// Notify all observers of a position change.
  void _notifyPositionChanged(String customerId, int newPosition) {
    for (final observer in _observers) {
      observer.onPositionChanged(customerId, newPosition);
    }
  }

  // --- Queue Management ---

  /// Generate a unique ID.
  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Add a customer to the queue.
  ///
  /// Returns the created [QueueEntry] with position information.
  QueueEntry joinQueue({
    required String customerId,
    required String customerName,
    QueuePriority priority = QueuePriority.normal,
  }) {
    // Check if customer is already in queue
    final existing = _queue.where(
      (e) => e.customerId == customerId && e.status == QueueStatus.waiting,
    );
    if (existing.isNotEmpty) {
      throw QueueException('Customer is already in the queue.');
    }

    final entry = QueueEntry(
      id: _generateId(),
      customerId: customerId,
      customerName: customerName,
      priority: priority,
    );

    _queue.add(entry);
    _recalculatePositions();

    _eventBus.publish(AppEvent(
      type: EventType.customerJoined,
      data: {
        'entryId': entry.id,
        'customerId': customerId,
        'customerName': customerName,
        'position': entry.position,
        'priority': priority.name,
      },
    ));

    _notifyQueueUpdated();
    return entry;
  }

  /// Remove a customer from the queue (cancel).
  void leaveQueue(String entryId) {
    final entry = _queue.where((e) => e.id == entryId).firstOrNull;
    if (entry == null) {
      throw QueueException('Queue entry not found.');
    }

    entry.status = QueueStatus.cancelled;
    _recalculatePositions();

    _eventBus.publish(AppEvent(
      type: EventType.customerLeft,
      data: {'entryId': entryId, 'customerId': entry.customerId},
    ));

    _notifyEntryStatusChanged(entry);
    _notifyQueueUpdated();
  }

  /// Mark the next person in queue as being served.
  QueueEntry? serveNext() {
    final waiting = queue;
    if (waiting.isEmpty) return null;

    final entry = waiting.first;
    entry.status = QueueStatus.serving;
    entry.servedAt = DateTime.now();
    _recalculatePositions();

    _eventBus.publish(AppEvent(
      type: EventType.customerServed,
      data: {
        'entryId': entry.id,
        'customerId': entry.customerId,
        'customerName': entry.customerName,
      },
    ));

    _notifyEntryStatusChanged(entry);
    _notifyQueueUpdated();
    return entry;
  }

  /// Mark a serving entry as completed.
  void completeService(String entryId) {
    final entry = _queue.where((e) => e.id == entryId).firstOrNull;
    if (entry == null) {
      throw QueueException('Queue entry not found.');
    }

    entry.status = QueueStatus.completed;
    entry.completedAt = DateTime.now();

    _eventBus.publish(AppEvent(
      type: EventType.customerCompleted,
      data: {'entryId': entryId, 'customerId': entry.customerId},
    ));

    _notifyEntryStatusChanged(entry);
  }

  /// Change priority of a queue entry (VIP/Urgent prioritization).
  ///
  /// This allows owners to prioritize specific customers.
  void setPriority(String entryId, QueuePriority priority) {
    final entry = _queue.where((e) => e.id == entryId).firstOrNull;
    if (entry == null) {
      throw QueueException('Queue entry not found.');
    }

    entry.priority = priority;
    _recalculatePositions();

    _eventBus.publish(AppEvent(
      type: EventType.priorityChanged,
      data: {
        'entryId': entryId,
        'customerId': entry.customerId,
        'newPriority': priority.name,
        'newPosition': entry.position,
      },
    ));

    _notifyQueueUpdated();
  }

  /// Get the position and estimated wait for a specific customer.
  Map<String, dynamic>? getCustomerPosition(String customerId) {
    final entry = _queue
        .where(
          (e) => e.customerId == customerId && e.status == QueueStatus.waiting,
        )
        .firstOrNull;

    if (entry == null) return null;

    return {
      'entryId': entry.id,
      'position': entry.position,
      'estimatedWaitMinutes': entry.estimatedWaitMinutes,
      'priority': entry.priority.name,
      'joinedAt': entry.joinedAt.toIso8601String(),
    };
  }

  /// Recalculate positions based on priority and join time.
  void _recalculatePositions() {
    final waiting = _queue
        .where((e) => e.status == QueueStatus.waiting)
        .toList()
      ..sort();

    for (var i = 0; i < waiting.length; i++) {
      final oldPosition = waiting[i].position;
      waiting[i].position = i + 1;

      if (oldPosition != waiting[i].position) {
        _notifyPositionChanged(waiting[i].customerId, waiting[i].position);

        _eventBus.publish(AppEvent(
          type: EventType.positionChanged,
          data: {
            'customerId': waiting[i].customerId,
            'oldPosition': oldPosition,
            'newPosition': waiting[i].position,
          },
        ));
      }
    }
  }

  /// Clear all completed and cancelled entries.
  void clearHistory() {
    _queue.removeWhere(
      (e) =>
          e.status == QueueStatus.completed ||
          e.status == QueueStatus.cancelled,
    );
  }

  /// Reset the entire queue.
  void resetQueue() {
    _queue.clear();
    _notifyQueueUpdated();
  }
}

/// Custom exception for queue operations.
class QueueException implements Exception {
  final String message;
  QueueException(this.message);

  @override
  String toString() => 'QueueException: $message';
}
