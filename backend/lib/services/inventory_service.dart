// Inventory service — manage stock for a business

import 'package:uuid/uuid.dart';

import '../models/inventory_item.dart';
import '../patterns/event_bus.dart';
import '../database/in_memory_db.dart';

class InventoryService {
  final InMemoryDatabase _db;
  final EventBus _bus;
  final _uuid = const Uuid();

  InventoryService(this._db, this._bus);

  // ── CRUD ───────────────────────────────────────────────────────────────────

  InventoryItem addItem({
    required String businessId,
    required String name,
    required int quantity,
    String? description,
    int? lowStockThreshold,
    double? price,
  }) {
    final item = InventoryItem(
      id: _uuid.v4(),
      businessId: businessId,
      name: name,
      description: description,
      quantity: quantity,
      lowStockThreshold: lowStockThreshold,
      price: price,
    );
    _db.inventory.putIfAbsent(businessId, () => []).add(item);
    return item;
  }

  ({String? error, InventoryItem? item}) updateQuantity({
    required String businessId,
    required String itemId,
    required int newQuantity,
  }) {
    final item = _db.findItem(businessId, itemId);
    if (item == null) return (error: 'Item not found', item: null);

    final wasAvailable = item.status != InventoryStatus.outOfStock;
    item.quantity = newQuantity;
    item.refreshStatus();

    _bus.emit(InventoryUpdatedEvent(
      businessId: businessId,
      itemId: itemId,
      newQuantity: newQuantity,
    ));

    if (wasAvailable && item.status == InventoryStatus.outOfStock) {
      _bus.emit(ItemOutOfStockEvent(
        businessId: businessId,
        itemId: itemId,
        itemName: item.name,
      ));
    }

    return (error: null, item: item);
  }

  /// Manually mark an item as out of stock.
  ({String? error, InventoryItem? item}) markOutOfStock({
    required String businessId,
    required String itemId,
  }) =>
      updateQuantity(businessId: businessId, itemId: itemId, newQuantity: 0);

  ({String? error, InventoryItem? item}) updateItem({
    required String businessId,
    required String itemId,
    String? name,
    String? description,
    int? lowStockThreshold,
    double? price,
  }) {
    final item = _db.findItem(businessId, itemId);
    if (item == null) return (error: 'Item not found', item: null);

    if (name != null) item.name = name;
    if (description != null) item.description = description;
    if (lowStockThreshold != null) item.lowStockThreshold = lowStockThreshold;
    if (price != null) item.price = price;
    item.refreshStatus();
    return (error: null, item: item);
  }

  ({String? error}) deleteItem({
    required String businessId,
    required String itemId,
  }) {
    final list = _db.inventory[businessId];
    if (list == null) return (error: 'Business not found');
    final lengthBefore = list.length;
    list.removeWhere((i) => i.id == itemId);
    return list.length < lengthBefore ? (error: null) : (error: 'Item not found');
  }

  List<InventoryItem> getInventory(String businessId) =>
      _db.getInventory(businessId);
}
