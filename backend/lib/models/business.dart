// Business model — represents a service provider (e.g., bakery, barbershop)

class Business {
  final String id;
  final String ownerId;
  String name;
  String description;
  String category;
  String? address;
  int avgServiceTimeMinutes;
  bool isOpen;
  final DateTime createdAt;

  Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    this.address,
    this.avgServiceTimeMinutes = 5,
    this.isOpen = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
        'description': description,
        'category': category,
        'address': address,
        'avgServiceTimeMinutes': avgServiceTimeMinutes,
        'isOpen': isOpen,
        'createdAt': createdAt.toIso8601String(),
      };
}
