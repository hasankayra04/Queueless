// App-wide state providers

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api;

  User? _user;
  String? _token;
  String? _error;
  bool _loading = false;

  AuthProvider(this.api);

  User? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      api.setToken(token);
      try {
        _user = await api.getMe();
        _token = token;
        notifyListeners();
      } catch (_) {
        await prefs.remove('token');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await api.login(email: email, password: password);
      _token = result.token;
      _user = result.user;
      api.setToken(_token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
      String name, String email, String password, UserRole role) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await api.register(
          name: name, email: email, password: password, role: role);
      _token = result.token;
      _user = result.user;
      api.setToken(_token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {}
    _user = null;
    _token = null;
    api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class BusinessProvider extends ChangeNotifier {
  final ApiService api;

  List<Business> _businesses = [];
  List<Business> _myBusinesses = [];
  Business? _selectedBusiness;
  String? _error;
  bool _loading = false;

  BusinessProvider(this.api);

  List<Business> get businesses => _businesses;
  List<Business> get myBusinesses => _myBusinesses;
  Business? get selectedBusiness => _selectedBusiness;
  String? get error => _error;
  bool get loading => _loading;

  void selectBusiness(Business b) {
    _selectedBusiness = b;
    notifyListeners();
  }

  Future<void> loadBusinesses() async {
    _loading = true;
    notifyListeners();
    try {
      _businesses = await api.getBusinesses();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyBusinesses() async {
    _loading = true;
    notifyListeners();
    try {
      _myBusinesses = await api.getMyBusinesses();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Business?> createBusiness({
    required String name,
    required String description,
    required String category,
    String? address,
    int avgServiceTimeMinutes = 5,
  }) async {
    try {
      final b = await api.createBusiness(
        name: name,
        description: description,
        category: category,
        address: address,
        avgServiceTimeMinutes: avgServiceTimeMinutes,
      );
      _myBusinesses.add(b);
      notifyListeners();
      return b;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> toggleOpen(String businessId, bool isOpen) async {
    try {
      final updated =
          await api.updateBusiness(businessId, {'isOpen': isOpen});
      final idx = _myBusinesses.indexWhere((b) => b.id == businessId);
      if (idx != -1) _myBusinesses[idx] = updated;
      if (_selectedBusiness?.id == businessId) _selectedBusiness = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class QueueProvider extends ChangeNotifier {
  final ApiService api;

  List<QueueEntry> _entries = [];
  QueueEntry? _myEntry;
  int _totalWaiting = 0;
  String? _error;
  bool _loading = false;

  QueueProvider(this.api);

  List<QueueEntry> get entries => _entries;
  QueueEntry? get myEntry => _myEntry;
  int get totalWaiting => _totalWaiting;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> loadQueue(String businessId) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await api.getQueue(businessId);
      _entries = (data['entries'] as List)
          .map((j) => QueueEntry.fromJson(j))
          .toList();
      _totalWaiting = (data['totalWaiting'] as num).toInt();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyEntry(String businessId) async {
    try {
      _myEntry = await api.getMyEntry(businessId);
    } on ApiException {
      _myEntry = null;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> joinQueue(String businessId, {String? note}) async {
    _error = null;
    try {
      _myEntry = await api.joinQueue(businessId, note: note);
      await loadQueue(businessId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveQueue(String businessId) async {
    try {
      await api.leaveQueue(businessId);
      _myEntry = null;
      await loadQueue(businessId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> serveNext(String businessId, {String? entryId}) async {
    try {
      await api.serveNext(businessId, entryId: entryId);
      await loadQueue(businessId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setPriority(
      String businessId, String entryId, String priority) async {
    try {
      await api.setPriority(businessId, entryId, priority);
      await loadQueue(businessId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class InventoryProvider extends ChangeNotifier {
  final ApiService api;

  List<InventoryItem> _items = [];
  String? _error;
  bool _loading = false;

  InventoryProvider(this.api);

  List<InventoryItem> get items => _items;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> loadInventory(String businessId) async {
    _loading = true;
    notifyListeners();
    try {
      _items = await api.getInventory(businessId);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem(String businessId,
      {required String name,
      required int quantity,
      String? description,
      int? lowStockThreshold,
      double? price}) async {
    try {
      final item = await api.addInventoryItem(businessId,
          name: name,
          quantity: quantity,
          description: description,
          lowStockThreshold: lowStockThreshold,
          price: price);
      _items.add(item);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuantity(
      String businessId, String itemId, int quantity) async {
    try {
      final updated = await api
          .updateInventoryItem(businessId, itemId, {'quantity': quantity});
      final idx = _items.indexWhere((i) => i.id == itemId);
      if (idx != -1) _items[idx] = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markOutOfStock(String businessId, String itemId) async {
    try {
      final updated = await api.markOutOfStock(businessId, itemId);
      final idx = _items.indexWhere((i) => i.id == itemId);
      if (idx != -1) _items[idx] = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String businessId, String itemId) async {
    try {
      await api.deleteInventoryItem(businessId, itemId);
      _items.removeWhere((i) => i.id == itemId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
