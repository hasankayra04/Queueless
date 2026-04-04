import 'package:test/test.dart';

import 'package:queueless_backend/services/inventory_service.dart';

void main() {
  late InventoryService inventoryService;

  setUp(() {
    inventoryService = InventoryService();
    inventoryService.reset();
  });

  group('InventoryService', () {
    test('addItem creates a new item', () {
      final item = inventoryService.addItem(
        name: 'Baklava',
        quantity: 50,
        unit: 'pieces',
      );

      expect(item.name, equals('Baklava'));
      expect(item.quantity, equals(50));
      expect(item.unit, equals('pieces'));
      expect(item.id, isNotEmpty);
    });

    test('getAllItems returns all items', () {
      inventoryService.addItem(name: 'Baklava', quantity: 50);
      inventoryService.addItem(name: 'Churros', quantity: 30);

      final items = inventoryService.getAllItems();
      expect(items.length, equals(2));
    });

    test('getItem returns specific item', () {
      final added = inventoryService.addItem(name: 'Baklava');
      final found = inventoryService.getItem(added.id);

      expect(found, isNotNull);
      expect(found!.name, equals('Baklava'));
    });

    test('updateStock changes quantity', () {
      final item = inventoryService.addItem(name: 'Baklava', quantity: 50);
      final updated = inventoryService.updateStock(item.id, 25);

      expect(updated.quantity, equals(25));
    });

    test('auto out-of-stock when quantity reaches threshold', () {
      final item = inventoryService.addItem(
        name: 'Baklava',
        quantity: 10,
        autoOutOfStock: true,
        lowStockThreshold: 5,
      );

      expect(item.isOutOfStock, isFalse);

      final updated = inventoryService.updateStock(item.id, 3);
      expect(updated.isOutOfStock, isTrue);
    });

    test('setOutOfStock manually marks item', () {
      final item = inventoryService.addItem(name: 'Baklava', quantity: 50);

      expect(item.isOutOfStock, isFalse);

      final updated = inventoryService.setOutOfStock(item.id, true);
      expect(updated.isOutOfStock, isTrue);
    });

    test('setOutOfStock can restock item', () {
      final item = inventoryService.addItem(name: 'Baklava', quantity: 0);
      inventoryService.setOutOfStock(item.id, true);

      final restocked = inventoryService.setOutOfStock(item.id, false);
      expect(restocked.isOutOfStock, isFalse);
    });

    test('updateItem changes item details', () {
      final item = inventoryService.addItem(name: 'Baklava', unit: 'pieces');

      final updated = inventoryService.updateItem(
        item.id,
        name: 'Premium Baklava',
        unit: 'boxes',
      );

      expect(updated.name, equals('Premium Baklava'));
      expect(updated.unit, equals('boxes'));
    });

    test('removeItem deletes item', () {
      final item = inventoryService.addItem(name: 'Baklava');

      inventoryService.removeItem(item.id);

      expect(inventoryService.getItem(item.id), isNull);
    });

    test('removeItem throws for non-existent item', () {
      expect(
        () => inventoryService.removeItem('nonexistent'),
        throwsA(isA<InventoryException>()),
      );
    });

    test('getOutOfStockItems returns correct items', () {
      inventoryService.addItem(name: 'Baklava', quantity: 50);
      final outItem = inventoryService.addItem(name: 'Churros', quantity: 0);
      inventoryService.setOutOfStock(outItem.id, true);

      final outOfStock = inventoryService.getOutOfStockItems();
      expect(outOfStock.length, equals(1));
      expect(outOfStock.first.name, equals('Churros'));
    });

    test('getLowStockItems returns items at or below threshold', () {
      inventoryService.addItem(
        name: 'Baklava',
        quantity: 3,
        autoOutOfStock: false,
        lowStockThreshold: 5,
      );
      inventoryService.addItem(
        name: 'Churros',
        quantity: 50,
        lowStockThreshold: 5,
      );

      final lowStock = inventoryService.getLowStockItems();
      expect(lowStock.length, equals(1));
      expect(lowStock.first.name, equals('Baklava'));
    });
  });
}
