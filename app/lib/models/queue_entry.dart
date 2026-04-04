/// Priority levels for queue entries.
enum QueuePriority { normal, vip, urgent }

/// Status of a queue entry.
enum QueueStatus { waiting, serving, completed, cancelled }

/// Represents a single entry in the queue.
class QueueEntry {
  final String id;
  final String customerId;
  final String customerName;
  final int position;
  final QueuePriority priority;
  final QueueStatus status;
  final DateTime joinedAt;
  final int estimatedWaitMinutes;

  QueueEntry({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.position,
    required this.priority,
    required this.status,
    required this.joinedAt,
    required this.estimatedWaitMinutes,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) => QueueEntry(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        position: json['position'] as int,
        priority: QueuePriority.values.byName(json['priority'] as String),
        status: QueueStatus.values.byName(json['status'] as String),
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        estimatedWaitMinutes: json['estimatedWaitMinutes'] as int? ?? 0,
      );
}
