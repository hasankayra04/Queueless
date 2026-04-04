import 'dart:math';

import '../core/event_bus.dart';
import '../models/inventory_item.dart';

/// Service for managing business inventory.
///
/// Tracks stock levels, handles out-of-stock management,
/// and publishes events when stock changes.
class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  final _items = <String, InventoryItem>{};
  final _eventBus = EventBus();

  /// Clear all items (useful for testing).
  void reset() => _items.clear();

  /// Generate a unique ID.
  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Get all inventory items.
  List<InventoryItem> getAllItems() => _items.values.toList();

  /// Get a specific item by ID.
  InventoryItem? getItem(String id) => _items[id];

  /// Add a new inventory item.
  InventoryItem addItem({
    required String name,
    int quantity = 0,
    String unit = 'pieces',
    bool autoOutOfStock = true,
    int lowStockThreshold = 0,
  }) {
    final item = InventoryItem(
      id: _generateId(),
      name: name,
      quantity: quantity,
      unit: unit,
      autoOutOfStock: autoOutOfStock,
      lowStockThreshold: lowStockThreshold,
    );

    item.checkStock();
    _items[item.id] = item;

    _eventBus.publish(AppEvent(
      type: EventType.inventoryUpdated,
      data: {'itemId': item.id, 'action': 'added', 'name': name},
    ));

    return item;
  }

  /// Update stock quantity for an item.
  InventoryItem updateStock(String id, int newQuantity) {
    final item = _items[id];
    if (item == null) {
      throw InventoryException('Inventory item not found.');
    }

    item.quantity = newQuantity;
    item.updatedAt = DateTime.now();
    item.checkStock();

    _eventBus.publish(AppEvent(
      type: EventType.inventoryUpdated,
      data: {
        'itemId': id,
        'action': 'stockUpdated',
        'quantity': newQuantity,
      },
    ));

    if (item.isOutOfStock) {
      _eventBus.publish(AppEvent(
        type: EventType.itemOutOfStock,
        data: {'itemId': id, 'name': item.name},
      ));
    }

    return item;
  }

  /// Manually set an item's out-of-stock status.
  InventoryItem setOutOfStock(String id, bool outOfStock) {
    final item = _items[id];
    if (item == null) {
      throw InventoryException('Inventory item not found.');
    }

    item.isOutOfStock = outOfStock;
    item.updatedAt = DateTime.now();

    if (outOfStock) {
      _eventBus.publish(AppEvent(
        type: EventType.itemOutOfStock,
        data: {'itemId': id, 'name': item.name},
      ));
    } else {
      _eventBus.publish(AppEvent(
        type: EventType.itemRestocked,
        data: {'itemId': id, 'name': item.name},
      ));
    }

    return item;
  }

  /// Update item details.
  InventoryItem updateItem(
    String id, {
    String? name,
    String? unit,
    bool? autoOutOfStock,
    int? lowStockThreshold,
  }) {
    final item = _items[id];
    if (item == null) {
      throw InventoryException('Inventory item not found.');
    }

    if (name != null) item.name = name;
    if (unit != null) item.unit = unit;
    if (autoOutOfStock != null) item.autoOutOfStock = autoOutOfStock;
    if (lowStockThreshold != null) item.lowStockThreshold = lowStockThreshold;
    item.updatedAt = DateTime.now();
    item.checkStock();

    _eventBus.publish(AppEvent(
      type: EventType.inventoryUpdated,
      data: {'itemId': id, 'action': 'updated'},
    ));

    return item;
  }

  /// Remove an inventory item.
  void removeItem(String id) {
    if (!_items.containsKey(id)) {
      throw InventoryException('Inventory item not found.');
    }
    _items.remove(id);

    _eventBus.publish(AppEvent(
      type: EventType.inventoryUpdated,
      data: {'itemId': id, 'action': 'removed'},
    ));
  }

  /// Get items that are out of stock.
  List<InventoryItem> getOutOfStockItems() =>
      _items.values.where((i) => i.isOutOfStock).toList();

  /// Get items with low stock.
  List<InventoryItem> getLowStockItems() => _items.values
      .where((i) => !i.isOutOfStock && i.quantity <= i.lowStockThreshold)
      .toList();
}

/// Custom exception for inventory operations.
class InventoryException implements Exception {
  final String message;
  InventoryException(this.message);

  @override
  String toString() => 'InventoryException: $message';
}
