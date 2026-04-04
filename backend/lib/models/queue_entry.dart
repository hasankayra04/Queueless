// QueueEntry — a single slot in the queue for a customer

enum QueuePriority { normal, vip, urgent }

enum QueueEntryStatus { waiting, serving, served, cancelled }

class QueueEntry {
  final String id;
  final String queueId;
  final String customerId;
  final String customerName;
  QueuePriority priority;
  QueueEntryStatus status;
  int position;
  final DateTime joinedAt;
  DateTime? servedAt;
  String? note;

  QueueEntry({
    required this.id,
    required this.queueId,
    required this.customerId,
    required this.customerName,
    this.priority = QueuePriority.normal,
    this.status = QueueEntryStatus.waiting,
    required this.position,
    DateTime? joinedAt,
    this.servedAt,
    this.note,
  }) : joinedAt = joinedAt ?? DateTime.now();

  /// Estimated wait time based on position and average service time (minutes).
  int estimatedWaitMinutes(int avgServiceTimeMinutes) =>
      (position - 1) * avgServiceTimeMinutes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'queueId': queueId,
        'customerId': customerId,
        'customerName': customerName,
        'priority': priority.name,
        'status': status.name,
        'position': position,
        'joinedAt': joinedAt.toIso8601String(),
        'servedAt': servedAt?.toIso8601String(),
        'note': note,
      };
}
