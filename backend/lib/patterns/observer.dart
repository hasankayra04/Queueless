// Observer Pattern Interfaces
// QueueManager acts as Subject; Customer objects act as Observers.

/// Observer interface — any object that wants to be notified of queue changes.
abstract class QueueObserver {
  void onQueueUpdated(QueueChangedEvent event);
}

/// Subject interface — the observable entity (QueueManager).
abstract class QueueSubject {
  void addObserver(QueueObserver observer);
  void removeObserver(QueueObserver observer);
  void notifyObservers(QueueChangedEvent event);
}

/// Event emitted to observers when the queue state changes.
class QueueChangedEvent {
  final String queueId;
  final QueueChangeType changeType;
  final String? customerId;
  final int? newPosition;
  final DateTime timestamp;

  QueueChangedEvent({
    required this.queueId,
    required this.changeType,
    this.customerId,
    this.newPosition,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'QueueChangedEvent(queue=$queueId, type=$changeType, customer=$customerId, pos=$newPosition)';
}

enum QueueChangeType {
  customerJoined,
  customerLeft,
  customerServed,
  positionChanged,
  vipPrioritized,
  urgentPrioritized,
}
