// HTTP API service — communicates with the QueueLess backend

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/models.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  final String baseUrl;
  String? _token;

  ApiService({required this.baseUrl});

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handleResponse(res);
  }

  Future<dynamic> _post(String path, [Map<String, dynamic>? body]) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(res);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  Future<dynamic> _delete(String path) async {
    final res =
        await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handleResponse(res);
  }

  dynamic _handleResponse(http.Response res) {
    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    final message = (decoded is Map ? decoded['error'] : null) as String? ??
        'Request failed';
    throw ApiException(res.statusCode, message);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<({String token, User user})> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final data = await _post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'role': role == UserRole.businessOwner ? 'businessOwner' : 'customer',
    });
    final loginData = await login(email: email, password: password);
    return loginData;
  }

  Future<({String token, User user})> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  Future<void> logout() async {
    await _post('/auth/logout');
    _token = null;
  }

  Future<User> getMe() async {
    final data = await _get('/auth/me');
    return User.fromJson(data as Map<String, dynamic>);
  }

  // ── Businesses ────────────────────────────────────────────────────────────

  Future<List<Business>> getBusinesses() async {
    final data = await _get('/businesses/');
    return (data as List).map((j) => Business.fromJson(j)).toList();
  }

  Future<Business> getBusiness(String id) async {
    final data = await _get('/businesses/$id');
    return Business.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Business>> getMyBusinesses() async {
    final data = await _get('/businesses/my');
    return (data as List).map((j) => Business.fromJson(j)).toList();
  }

  Future<Business> createBusiness({
    required String name,
    required String description,
    required String category,
    String? address,
    int avgServiceTimeMinutes = 5,
  }) async {
    final data = await _post('/businesses/', {
      'name': name,
      'description': description,
      'category': category,
      if (address != null) 'address': address,
      'avgServiceTimeMinutes': avgServiceTimeMinutes,
    });
    return Business.fromJson(data as Map<String, dynamic>);
  }

  Future<Business> updateBusiness(
      String id, Map<String, dynamic> changes) async {
    final data = await _patch('/businesses/$id', changes);
    return Business.fromJson(data as Map<String, dynamic>);
  }

  // ── Queue ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getQueue(String businessId) async {
    return await _get('/queue/$businessId') as Map<String, dynamic>;
  }

  Future<QueueEntry> getMyEntry(String businessId) async {
    final data = await _get('/queue/$businessId/my');
    return QueueEntry.fromJson(data as Map<String, dynamic>);
  }

  Future<QueueEntry> joinQueue(String businessId, {String? note}) async {
    final data = await _post('/queue/$businessId/join',
        note != null ? {'note': note} : {});
    return QueueEntry.fromJson(data as Map<String, dynamic>);
  }

  Future<void> leaveQueue(String businessId) async {
    await _delete('/queue/$businessId/leave');
  }

  Future<QueueEntry> serveNext(String businessId, {String? entryId}) async {
    final data = await _post(
        '/queue/$businessId/serve-next',
        entryId != null ? {'entryId': entryId} : {});
    return QueueEntry.fromJson(data as Map<String, dynamic>);
  }

  Future<void> setPriority(
      String businessId, String entryId, String priority) async {
    await _patch(
        '/queue/$businessId/entry/$entryId/priority', {'priority': priority});
  }

  // ── Inventory ─────────────────────────────────────────────────────────────

  Future<List<InventoryItem>> getInventory(String businessId) async {
    final data = await _get('/inventory/$businessId');
    return (data as List).map((j) => InventoryItem.fromJson(j)).toList();
  }

  Future<InventoryItem> addInventoryItem(String businessId,
      {required String name,
      required int quantity,
      String? description,
      int? lowStockThreshold,
      double? price}) async {
    final data = await _post('/inventory/$businessId', {
      'name': name,
      'quantity': quantity,
      if (description != null) 'description': description,
      if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
      if (price != null) 'price': price,
    });
    return InventoryItem.fromJson(data as Map<String, dynamic>);
  }

  Future<InventoryItem> updateInventoryItem(
      String businessId, String itemId, Map<String, dynamic> changes) async {
    final data = await _patch('/inventory/$businessId/$itemId', changes);
    return InventoryItem.fromJson(data as Map<String, dynamic>);
  }

  Future<InventoryItem> markOutOfStock(
      String businessId, String itemId) async {
    final data =
        await _post('/inventory/$businessId/$itemId/out-of-stock');
    return InventoryItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteInventoryItem(String businessId, String itemId) async {
    await _delete('/inventory/$businessId/$itemId');
  }
}
