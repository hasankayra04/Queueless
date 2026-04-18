// Business service — CRUD for business profiles

import 'package:uuid/uuid.dart';

import '../models/business.dart';
import '../database/in_memory_db.dart';

class BusinessService {
  final InMemoryDatabase _db;
  final _uuid = const Uuid();

  BusinessService(this._db);

  Business createBusiness({
    required String ownerId,
    required String name,
    required String description,
    required String category,
    String? address,
    int avgServiceTimeMinutes = 5,
  }) {
    final b = Business(
      id: _uuid.v4(),
      ownerId: ownerId,
      name: name,
      description: description,
      category: category,
      address: address,
      avgServiceTimeMinutes: avgServiceTimeMinutes,
    );
    _db.businesses[b.id] = b;
    return b;
  }

  ({String? error, Business? business}) updateBusiness({
    required String businessId,
    required String requesterId,
    String? name,
    String? description,
    String? category,
    String? address,
    int? avgServiceTimeMinutes,
    bool? isOpen,
  }) {
    final b = _db.businesses[businessId];
    if (b == null) return (error: 'Business not found', business: null);
    if (b.ownerId != requesterId) return (error: 'Forbidden', business: null);

    if (name != null) b.name = name;
    if (description != null) b.description = description;
    if (category != null) b.category = category;
    if (address != null) b.address = address;
    if (avgServiceTimeMinutes != null) {
      b.avgServiceTimeMinutes = avgServiceTimeMinutes;
    }
    if (isOpen != null) b.isOpen = isOpen;
    return (error: null, business: b);
  }

  Business? getBusiness(String businessId) => _db.businesses[businessId];

  List<Business> getAllBusinesses() => _db.businesses.values.toList();

  List<Business> getBusinessesByOwner(String ownerId) =>
      _db.getBusinessesByOwner(ownerId);
}
