import '../models/queue_entry.dart';

/// Observer interface for the Observer Pattern.
///
/// Classes that want to be notified of queue changes implement this interface.
/// The [QueueManager] acts as the Subject that notifies all registered observers.
abstract class QueueObserver {
  /// Called when the queue is updated (entry added, removed, or reordered).
  void onQueueUpdated(List<QueueEntry> queue);

  /// Called when a specific entry's status changes.
  void onEntryStatusChanged(QueueEntry entry);

  /// Called when a customer's position changes.
  void onPositionChanged(String customerId, int newPosition);
}
