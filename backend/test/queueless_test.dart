// Integration tests for core business logic

import 'package:test/test.dart';

import 'package:queueless_backend/database/in_memory_db.dart';
import 'package:queueless_backend/patterns/event_bus.dart';
import 'package:queueless_backend/patterns/observer.dart';
import 'package:queueless_backend/services/auth_service.dart';
import 'package:queueless_backend/services/business_service.dart';
import 'package:queueless_backend/services/queue_manager.dart';
import 'package:queueless_backend/services/inventory_service.dart';
import 'package:queueless_backend/models/user.dart';
import 'package:queueless_backend/models/queue_entry.dart';
import 'package:queueless_backend/models/inventory_item.dart';

void main() {
  late InMemoryDatabase db;
  late EventBus bus;
  late AuthService auth;
  late BusinessService businesses;
  late QueueManager queue;
  late InventoryService inventory;

  setUp(() {
    db = InMemoryDatabase.fresh();
    bus = EventBus();
    auth = AuthService(db);
    businesses = BusinessService(db);
    queue = QueueManager(db, bus);
    inventory = InventoryService(db, bus);
  });

  // ── Auth tests ─────────────────────────────────────────────────────────────
  group('AuthService', () {
    test('registers a new user', () {
      final result = auth.register(
        name: 'Alice',
        email: 'alice@example.com',
        password: 'secret123',
        role: UserRole.customer,
      );
      expect(result.error, isNull);
      expect(result.user, isNotNull);
      expect(result.user!.name, 'Alice');
      expect(result.user!.role, UserRole.customer);
    });

    test('rejects duplicate email', () {
      auth.register(
          name: 'Alice',
          email: 'alice@example.com',
          password: 'pass123',
          role: UserRole.customer);
      final r = auth.register(
          name: 'Bob',
          email: 'alice@example.com',
          password: 'pass456',
          role: UserRole.customer);
      expect(r.error, isNotNull);
    });

    test('login returns token', () {
      auth.register(
          name: 'Alice',
          email: 'alice@example.com',
          password: 'pass123',
          role: UserRole.customer);
      final r = auth.login(email: 'alice@example.com', password: 'pass123');
      expect(r.error, isNull);
      expect(r.token, isNotEmpty);
    });

    test('login fails with wrong password', () {
      auth.register(
          name: 'Alice',
          email: 'alice@example.com',
          password: 'pass123',
          role: UserRole.customer);
      final r = auth.login(email: 'alice@example.com', password: 'wrong');
      expect(r.error, isNotNull);
      expect(r.token, isNull);
    });

    test('getUserFromToken resolves user', () {
      auth.register(
          name: 'Alice',
          email: 'alice@example.com',
          password: 'pass123',
          role: UserRole.customer);
      final r = auth.login(email: 'alice@example.com', password: 'pass123');
      final user = auth.getUserFromToken(r.token!);
      expect(user, isNotNull);
      expect(user!.email, 'alice@example.com');
    });

    test('logout invalidates token', () {
      auth.register(
          name: 'Alice',
          email: 'alice@example.com',
          password: 'pass123',
          role: UserRole.customer);
      final r = auth.login(email: 'alice@example.com', password: 'pass123');
      auth.logout(r.token!);
      expect(auth.getUserFromToken(r.token!), isNull);
    });
  });

  // ── Queue tests ────────────────────────────────────────────────────────────
  group('QueueManager', () {
    late String businessId;

    setUp(() {
      final b = businesses.createBusiness(
        ownerId: 'owner1',
        name: 'Alice Bakery',
        description: 'Fresh bread',
        category: 'Bakery',
        avgServiceTimeMinutes: 3,
      );
      businessId = b.id;
    });

    test('customer joins queue', () {
      final r = queue.joinQueue(
          businessId: businessId,
          customerId: 'c1',
          customerName: 'Bob');
      expect(r.error, isNull);
      expect(r.entry!.position, 1);
    });

    test('second customer gets position 2', () {
      queue.joinQueue(businessId: businessId, customerId: 'c1', customerName: 'Bob');
      final r = queue.joinQueue(
          businessId: businessId, customerId: 'c2', customerName: 'Carol');
      expect(r.entry!.position, 2);
    });

    test('duplicate join is rejected', () {
      queue.joinQueue(businessId: businessId, customerId: 'c1', customerName: 'Bob');
      final r = queue.joinQueue(
          businessId: businessId, customerId: 'c1', customerName: 'Bob');
      expect(r.error, isNotNull);
    });

    test('customer can leave queue', () {
      queue.joinQueue(businessId: businessId, customerId: 'c1', customerName: 'Bob');
      final r = queue.leaveQueue(businessId: businessId, customerId: 'c1');
      expect(r.error, isNull);
      expect(queue.getQueue(businessId), isEmpty);
    });

    test('positions recalculate after leave', () {
      queue.joinQueue(businessId: businessId, customerId: 'c1', customerName: 'Bob');
      queue.joinQueue(businessId: businessId, customerId: 'c2', customerName: 'Carol');
      queue.joinQueue(businessId: businessId, customerId: 'c3', customerName: 'Dave');
      queue.leaveQueue(businessId: businessId, customerId: 'c1');
      final q = queue.getQueue(businessId);
      expect(q.length, 2);
      expect(q[0].position, 1);
      expect(q[1].position, 2);
    });

    test('serve next dequeues first customer', () {
      queue.joinQueue(businessId: businessId, customerId: 'c1', customerName: 'Bob');
      queue.joinQueue(businessId: businessId, customerId: 'c2', customerName: 'Carol');
      final r = queue.serveNext(businessId: businessId);
      expect(r.error, isNull);
      expect(r.entry!.customerId, 'c1');
      expect(r.entry!.status, QueueEntryStatus.serving);
      expect(queue.getQueue(businessId).length, 1);
    });

    test('VIP priority moves customer forward', () {
      queue.joinQueue(businessId: businessId, customerId: 'c1', customerName: 'Bob');
      queue.joinQueue(businessId: businessId, customerId: 'c2', customerName: 'Carol');
      queue.joinQueue(businessId: businessId, customerId: 'c3', customerName: 'Dave');

      final q = queue.getQueue(businessId);
      final carolEntry = q.firstWhere((e) => e.customerId == 'c2');
      queue.setPriority(
          businessId: businessId,
          entryId: carolEntry.id,
          priority: QueuePriority.vip);

      final sorted = queue.getQueue(businessId);
      expect(sorted[0].customerId, 'c2'); // VIP moved to front
    });

    test('Urgent priority beats VIP', () {
      queue.joinQueue(businessId: businessId, customerId: 'c1', customerName: 'Bob');
      queue.joinQueue(businessId: businessId, customerId: 'c2', customerName: 'Carol');
      queue.joinQueue(businessId: businessId, customerId: 'c3', customerName: 'Dave');

      final q = queue.getQueue(businessId);
      final carolEntry = q.firstWhere((e) => e.customerId == 'c2');
      final daveEntry = q.firstWhere((e) => e.customerId == 'c3');

      queue.setPriority(
          businessId: businessId,
          entryId: carolEntry.id,
          priority: QueuePriority.vip);
      queue.setPriority(
          businessId: businessId,
          entryId: daveEntry.id,
          priority: QueuePriority.urgent);

      final sorted = queue.getQueue(businessId);
      expect(sorted[0].customerId, 'c3'); // Urgent first
      expect(sorted[1].customerId, 'c2'); // VIP second
    });

    test('estimated wait time is calculated correctly', () {
      queue.joinQueue(businessId: businessId, customerId: 'c1', customerName: 'Bob');
      queue.joinQueue(businessId: businessId, customerId: 'c2', customerName: 'Carol');
      final q = queue.getQueue(businessId);
      expect(q[0].estimatedWaitMinutes(3), 0); // position 1 = 0 wait
      expect(q[1].estimatedWaitMinutes(3), 3); // position 2 = 3 min
    });
  });

  // ── Observer Pattern tests ────────────────────────────────────────────────
  group('Observer Pattern', () {
    late String businessId;
    late _MockObserver observer;

    setUp(() {
      final b = businesses.createBusiness(
        ownerId: 'owner1',
        name: 'Test Shop',
        description: '',
        category: 'Other',
      );
      businessId = b.id;
      observer = _MockObserver();
      queue.addObserver(observer);
    });

    test('observer is notified when customer joins', () {
      queue.joinQueue(
          businessId: businessId, customerId: 'c1', customerName: 'Bob');
      expect(observer.events, isNotEmpty);
      expect(
          observer.events.any((e) => e.changeType == QueueChangeType.customerJoined),
          isTrue);
    });

    test('observer is notified when customer leaves', () {
      queue.joinQueue(
          businessId: businessId, customerId: 'c1', customerName: 'Bob');
      observer.events.clear();
      queue.leaveQueue(businessId: businessId, customerId: 'c1');
      expect(
          observer.events.any((e) => e.changeType == QueueChangeType.customerLeft),
          isTrue);
    });
  });

  // ── Event Bus tests ───────────────────────────────────────────────────────
  group('EventBus', () {
    late String businessId;

    setUp(() {
      final b = businesses.createBusiness(
        ownerId: 'owner1',
        name: 'Test Shop',
        description: '',
        category: 'Other',
      );
      businessId = b.id;
    });

    test('emits CustomerJoinedEvent on join', () async {
      CustomerJoinedEvent? received;
      bus.on<CustomerJoinedEvent>((e) => received = e);

      queue.joinQueue(
          businessId: businessId, customerId: 'c1', customerName: 'Bob');

      await Future.delayed(Duration.zero);
      expect(received, isNotNull);
      expect(received!.customerId, 'c1');
    });
  });

  // ── Inventory tests ───────────────────────────────────────────────────────
  group('InventoryService', () {
    late String businessId;

    setUp(() {
      final b = businesses.createBusiness(
        ownerId: 'owner1',
        name: 'Bakery',
        description: '',
        category: 'Bakery',
      );
      businessId = b.id;
    });

    test('adds an item', () {
      final item = inventory.addItem(
          businessId: businessId, name: 'Baklava', quantity: 50);
      expect(item.name, 'Baklava');
      expect(item.quantity, 50);
      expect(item.status, InventoryStatus.available);
    });

    test('updates quantity and status', () {
      final item = inventory.addItem(
          businessId: businessId, name: 'Baklava', quantity: 50);
      inventory.updateQuantity(
          businessId: businessId, itemId: item.id, newQuantity: 0);
      expect(item.status, InventoryStatus.outOfStock);
    });

    test('marks item as out of stock', () {
      final item = inventory.addItem(
          businessId: businessId, name: 'Churros', quantity: 20);
      inventory.markOutOfStock(businessId: businessId, itemId: item.id);
      expect(item.status, InventoryStatus.outOfStock);
      expect(item.quantity, 0);
    });

    test('limited status when below threshold', () {
      final item = inventory.addItem(
          businessId: businessId,
          name: 'Croissant',
          quantity: 5,
          lowStockThreshold: 10);
      expect(item.status, InventoryStatus.limited);
    });

    test('deletes item', () {
      final item = inventory.addItem(
          businessId: businessId, name: 'Muffin', quantity: 10);
      final r = inventory.deleteItem(businessId: businessId, itemId: item.id);
      expect(r.error, isNull);
      expect(inventory.getInventory(businessId), isEmpty);
    });

    test('emits ItemOutOfStockEvent when item runs out', () async {
      ItemOutOfStockEvent? received;
      bus.on<ItemOutOfStockEvent>((e) => received = e);

      final item = inventory.addItem(
          businessId: businessId, name: 'Baklava', quantity: 5);
      inventory.updateQuantity(
          businessId: businessId, itemId: item.id, newQuantity: 0);

      await Future.delayed(Duration.zero);
      expect(received, isNotNull);
      expect(received!.itemName, 'Baklava');
    });
  });
}

class _MockObserver implements QueueObserver {
  final List<QueueChangedEvent> events = [];

  @override
  void onQueueUpdated(QueueChangedEvent event) {
    events.add(event);
  }
}
