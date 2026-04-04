// Shared data models for the Flutter frontend.
// These mirror the backend models and are used for JSON deserialization.

enum UserRole { customer, businessOwner }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] == 'businessOwner'
            ? UserRole.businessOwner
            : UserRole.customer,
      );

  bool get isOwner => role == UserRole.businessOwner;
}

// ─────────────────────────────────────────────────────────────────────────────

class Business {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String category;
  final String? address;
  final int avgServiceTimeMinutes;
  final bool isOpen;

  Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    this.address,
    required this.avgServiceTimeMinutes,
    required this.isOpen,
  });

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? '',
        address: json['address'] as String?,
        avgServiceTimeMinutes: (json['avgServiceTimeMinutes'] as num).toInt(),
        isOpen: json['isOpen'] as bool,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

enum QueuePriority { normal, vip, urgent }

enum QueueEntryStatus { waiting, serving, served, cancelled }

class QueueEntry {
  final String id;
  final String queueId;
  final String customerId;
  final String customerName;
  final QueuePriority priority;
  final QueueEntryStatus status;
  final int position;
  final DateTime joinedAt;
  final int estimatedWaitMinutes;
  final String? note;

  QueueEntry({
    required this.id,
    required this.queueId,
    required this.customerId,
    required this.customerName,
    required this.priority,
    required this.status,
    required this.position,
    required this.joinedAt,
    required this.estimatedWaitMinutes,
    this.note,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) => QueueEntry(
        id: json['id'] as String,
        queueId: json['queueId'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        priority: QueuePriority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => QueuePriority.normal,
        ),
        status: QueueEntryStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => QueueEntryStatus.waiting,
        ),
        position: (json['position'] as num).toInt(),
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        estimatedWaitMinutes:
            (json['estimatedWaitMinutes'] as num?)?.toInt() ?? 0,
        note: json['note'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

enum InventoryStatus { available, outOfStock, limited }

class InventoryItem {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final int quantity;
  final double? price;
  final InventoryStatus status;

  InventoryItem({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.quantity,
    this.price,
    required this.status,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        quantity: (json['quantity'] as num).toInt(),
        price: (json['price'] as num?)?.toDouble(),
        status: InventoryStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => InventoryStatus.available,
        ),
      );
}
