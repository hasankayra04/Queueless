/// Represents an item in the business owner's inventory.
class InventoryItem {
  final String id;
  String name;
  int quantity;
  String unit;
  bool isOutOfStock;
  bool autoOutOfStock;
  int lowStockThreshold;
  final DateTime createdAt;
  DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.name,
    this.quantity = 0,
    this.unit = 'pieces',
    this.isOutOfStock = false,
    this.autoOutOfStock = true,
    this.lowStockThreshold = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Checks stock level and auto-sets out-of-stock if enabled.
  void checkStock() {
    if (autoOutOfStock && quantity <= lowStockThreshold) {
      isOutOfStock = true;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'isOutOfStock': isOutOfStock,
        'autoOutOfStock': autoOutOfStock,
        'lowStockThreshold': lowStockThreshold,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        quantity: json['quantity'] as int? ?? 0,
        unit: json['unit'] as String? ?? 'pieces',
        isOutOfStock: json['isOutOfStock'] as bool? ?? false,
        autoOutOfStock: json['autoOutOfStock'] as bool? ?? true,
        lowStockThreshold: json['lowStockThreshold'] as int? ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}
