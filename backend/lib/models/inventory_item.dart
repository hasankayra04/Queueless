// InventoryItem — a product or service the business offers

enum InventoryStatus { available, outOfStock, limited }

class InventoryItem {
  final String id;
  final String businessId;
  String name;
  String? description;
  int quantity;
  int? lowStockThreshold;
  double? price;
  InventoryStatus status;
  final DateTime createdAt;
  DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.quantity,
    this.lowStockThreshold,
    this.price,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : status = InventoryStatus.available,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    refreshStatus();
  }

  /// Recompute status based on current quantity and threshold.
  void refreshStatus() {
    if (quantity <= 0) {
      status = InventoryStatus.outOfStock;
    } else if (lowStockThreshold != null && quantity <= lowStockThreshold!) {
      status = InventoryStatus.limited;
    } else {
      status = InventoryStatus.available;
    }
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'name': name,
        'description': description,
        'quantity': quantity,
        'lowStockThreshold': lowStockThreshold,
        'price': price,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
