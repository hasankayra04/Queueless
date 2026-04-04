import 'package:flutter/foundation.dart';

import '../models/inventory_item.dart';
import 'api_client.dart';

/// Service for inventory state management.
class InventoryService extends ChangeNotifier {
  final ApiClient _api;
  List<InventoryItem> _items = [];
  bool _isLoading = false;
  String? _error;

  InventoryService(this._api);

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all inventory items.
  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/api/inventory/');
      _items = (response['items'] as List)
          .map((i) => InventoryItem.fromJson(i as Map<String, dynamic>))
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new inventory item.
  Future<InventoryItem?> addItem({
    required String name,
    int quantity = 0,
    String unit = 'pieces',
    bool autoOutOfStock = true,
    int lowStockThreshold = 0,
  }) async {
    try {
      final response = await _api.post('/api/inventory/', {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'autoOutOfStock': autoOutOfStock,
        'lowStockThreshold': lowStockThreshold,
      });

      final item =
          InventoryItem.fromJson(response['item'] as Map<String, dynamic>);
      await fetchItems();
      return item;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  /// Update stock quantity.
  Future<bool> updateStock(String id, int quantity) async {
    try {
      await _api.put('/api/inventory/$id/stock', {'quantity': quantity});
      await fetchItems();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Set out-of-stock status.
  Future<bool> setOutOfStock(String id, bool outOfStock) async {
    try {
      await _api.put(
          '/api/inventory/$id/out-of-stock', {'outOfStock': outOfStock});
      await fetchItems();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Update item details.
  Future<bool> updateItem(String id, Map<String, dynamic> updates) async {
    try {
      await _api.put('/api/inventory/$id', updates);
      await fetchItems();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Remove an inventory item.
  Future<bool> removeItem(String id) async {
    try {
      await _api.delete('/api/inventory/$id');
      await fetchItems();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Clear error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
