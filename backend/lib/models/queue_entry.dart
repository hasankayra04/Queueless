/// Priority levels for queue entries.
enum QueuePriority { normal, vip, urgent }

/// Status of a queue entry.
enum QueueStatus { waiting, serving, completed, cancelled }

/// Represents a single entry in the queue.
class QueueEntry implements Comparable<QueueEntry> {
  final String id;
  final String customerId;
  final String customerName;
  int position;
  QueuePriority priority;
  QueueStatus status;
  final DateTime joinedAt;
  DateTime? servedAt;
  DateTime? completedAt;

  QueueEntry({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.position = 0,
    this.priority = QueuePriority.normal,
    this.status = QueueStatus.waiting,
    DateTime? joinedAt,
    this.servedAt,
    this.completedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  /// Estimated wait time in minutes based on position and priority.
  int get estimatedWaitMinutes {
    const avgServiceTime = 5; // minutes per customer
    return position * avgServiceTime;
  }

  /// Higher priority entries come first; ties broken by join time.
  @override
  int compareTo(QueueEntry other) {
    final priorityComparison =
        other.priority.index.compareTo(priority.index);
    if (priorityComparison != 0) return priorityComparison;
    return joinedAt.compareTo(other.joinedAt);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'position': position,
        'priority': priority.name,
        'status': status.name,
        'joinedAt': joinedAt.toIso8601String(),
        'servedAt': servedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'estimatedWaitMinutes': estimatedWaitMinutes,
      };

  factory QueueEntry.fromJson(Map<String, dynamic> json) => QueueEntry(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        position: json['position'] as int,
        priority: QueuePriority.values.byName(json['priority'] as String),
        status: QueueStatus.values.byName(json['status'] as String),
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        servedAt: json['servedAt'] != null
            ? DateTime.parse(json['servedAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}
