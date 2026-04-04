/// Represents an item in the business owner's inventory.
class InventoryItem {
  final String id;
  final String name;
  final int quantity;
  final String unit;
  final bool isOutOfStock;
  final bool autoOutOfStock;
  final int lowStockThreshold;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isOutOfStock,
    required this.autoOutOfStock,
    required this.lowStockThreshold,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        quantity: json['quantity'] as int? ?? 0,
        unit: json['unit'] as String? ?? 'pieces',
        isOutOfStock: json['isOutOfStock'] as bool? ?? false,
        autoOutOfStock: json['autoOutOfStock'] as bool? ?? true,
        lowStockThreshold: json['lowStockThreshold'] as int? ?? 0,
      );
}
