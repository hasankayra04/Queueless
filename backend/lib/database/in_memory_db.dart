// In-memory database — single source of truth for all runtime data

import '../models/user.dart';
import '../models/business.dart';
import '../models/queue_entry.dart';
import '../models/inventory_item.dart';

class InMemoryDatabase {
  static final InMemoryDatabase _instance = InMemoryDatabase._internal();
  factory InMemoryDatabase() => _instance;
  InMemoryDatabase._internal();

  /// Create a fresh, independent instance (useful for testing).
  InMemoryDatabase.fresh();

  // ── Tables ────────────────────────────────────────────────────────────────
  final Map<String, User> users = {};
  final Map<String, Business> businesses = {};

  /// businessId → list of queue entries (ordered by position)
  final Map<String, List<QueueEntry>> queues = {};

  /// businessId → list of inventory items
  final Map<String, List<InventoryItem>> inventory = {};

  // ── User helpers ──────────────────────────────────────────────────────────
  User? findUserByEmail(String email) =>
      users.values.where((u) => u.email == email).firstOrNull;

  // ── Business helpers ──────────────────────────────────────────────────────
  List<Business> getBusinessesByOwner(String ownerId) =>
      businesses.values.where((b) => b.ownerId == ownerId).toList();

  // ── Queue helpers ─────────────────────────────────────────────────────────
  List<QueueEntry> getQueue(String businessId) =>
      (queues[businessId] ?? [])
          .where((e) => e.status == QueueEntryStatus.waiting)
          .toList()
        ..sort((a, b) {
          // Urgent first, then VIP, then Normal; within same priority by position
          final pa = _priorityValue(a.priority);
          final pb = _priorityValue(b.priority);
          if (pa != pb) return pb.compareTo(pa);
          return a.position.compareTo(b.position);
        });

  QueueEntry? findEntry(String businessId, String entryId) =>
      (queues[businessId] ?? []).where((e) => e.id == entryId).firstOrNull;

  QueueEntry? findEntryByCustomer(String businessId, String customerId) =>
      (queues[businessId] ?? [])
          .where((e) =>
              e.customerId == customerId &&
              e.status == QueueEntryStatus.waiting)
          .firstOrNull;

  int _priorityValue(QueuePriority p) => switch (p) {
        QueuePriority.urgent => 2,
        QueuePriority.vip => 1,
        QueuePriority.normal => 0,
      };

  // ── Inventory helpers ─────────────────────────────────────────────────────
  List<InventoryItem> getInventory(String businessId) =>
      inventory[businessId] ?? [];

  InventoryItem? findItem(String businessId, String itemId) =>
      (inventory[businessId] ?? []).where((i) => i.id == itemId).firstOrNull;
}
