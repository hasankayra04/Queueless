import 'package:test/test.dart';

import 'package:queueless_backend/services/queue_manager.dart';
import 'package:queueless_backend/models/queue_entry.dart';
import 'package:queueless_backend/core/observer.dart';

/// A test observer that records notifications.
class TestQueueObserver implements QueueObserver {
  final List<List<QueueEntry>> queueUpdates = [];
  final List<QueueEntry> statusChanges = [];
  final List<Map<String, dynamic>> positionChanges = [];

  @override
  void onQueueUpdated(List<QueueEntry> queue) {
    queueUpdates.add(List.from(queue));
  }

  @override
  void onEntryStatusChanged(QueueEntry entry) {
    statusChanges.add(entry);
  }

  @override
  void onPositionChanged(String customerId, int newPosition) {
    positionChanges.add({
      'customerId': customerId,
      'newPosition': newPosition,
    });
  }
}

void main() {
  late QueueManager queueManager;
  late TestQueueObserver observer;

  setUp(() {
    queueManager = QueueManager();
    queueManager.resetQueue();
    observer = TestQueueObserver();
    queueManager.addObserver(observer);
  });

  tearDown(() {
    queueManager.removeObserver(observer);
  });

  group('QueueManager', () {
    test('joinQueue adds customer to queue', () {
      final entry = queueManager.joinQueue(
        customerId: 'c1',
        customerName: 'Alice',
      );

      expect(entry.customerId, equals('c1'));
      expect(entry.customerName, equals('Alice'));
      expect(entry.position, equals(1));
      expect(entry.status, equals(QueueStatus.waiting));
    });

    test('joinQueue maintains correct positions', () {
      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      queueManager.joinQueue(customerId: 'c2', customerName: 'Bob');
      queueManager.joinQueue(customerId: 'c3', customerName: 'Charlie');

      final queue = queueManager.queue;
      expect(queue.length, equals(3));
      expect(queue[0].position, equals(1));
      expect(queue[1].position, equals(2));
      expect(queue[2].position, equals(3));
    });

    test('joinQueue rejects duplicate customer', () {
      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');

      expect(
        () => queueManager.joinQueue(customerId: 'c1', customerName: 'Alice'),
        throwsA(isA<QueueException>()),
      );
    });

    test('leaveQueue removes customer', () {
      final entry =
          queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      queueManager.joinQueue(customerId: 'c2', customerName: 'Bob');

      queueManager.leaveQueue(entry.id);

      expect(queueManager.waitingCount, equals(1));
      expect(queueManager.queue.first.customerName, equals('Bob'));
      expect(queueManager.queue.first.position, equals(1));
    });

    test('serveNext serves the first person', () {
      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      queueManager.joinQueue(customerId: 'c2', customerName: 'Bob');

      final served = queueManager.serveNext();

      expect(served, isNotNull);
      expect(served!.customerName, equals('Alice'));
      expect(served.status, equals(QueueStatus.serving));
      expect(queueManager.waitingCount, equals(1));
    });

    test('serveNext returns null for empty queue', () {
      final served = queueManager.serveNext();
      expect(served, isNull);
    });

    test('completeService marks entry as completed', () {
      final entry =
          queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      queueManager.serveNext();

      queueManager.completeService(entry.id);

      final all = queueManager.allEntries;
      final completed = all.where((e) => e.id == entry.id).first;
      expect(completed.status, equals(QueueStatus.completed));
    });

    test('VIP priority moves customer ahead', () {
      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      queueManager.joinQueue(customerId: 'c2', customerName: 'Bob');
      final vipEntry = queueManager.joinQueue(
        customerId: 'c3',
        customerName: 'VIP Charlie',
      );

      queueManager.setPriority(vipEntry.id, QueuePriority.vip);

      final queue = queueManager.queue;
      expect(queue[0].customerName, equals('VIP Charlie'));
      expect(queue[0].position, equals(1));
    });

    test('Urgent priority takes top position', () {
      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      queueManager.joinQueue(
        customerId: 'c2',
        customerName: 'VIP Bob',
        priority: QueuePriority.vip,
      );
      final urgentEntry = queueManager.joinQueue(
        customerId: 'c3',
        customerName: 'Urgent Charlie',
      );

      queueManager.setPriority(urgentEntry.id, QueuePriority.urgent);

      final queue = queueManager.queue;
      expect(queue[0].customerName, equals('Urgent Charlie'));
      expect(queue[1].customerName, equals('VIP Bob'));
      expect(queue[2].customerName, equals('Alice'));
    });

    test('getCustomerPosition returns correct info', () {
      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      queueManager.joinQueue(customerId: 'c2', customerName: 'Bob');

      final position = queueManager.getCustomerPosition('c2');

      expect(position, isNotNull);
      expect(position!['position'], equals(2));
    });

    test('getCustomerPosition returns null for non-existent customer', () {
      final position = queueManager.getCustomerPosition('nonexistent');
      expect(position, isNull);
    });

    test('waitingCount is accurate', () {
      expect(queueManager.waitingCount, equals(0));

      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      expect(queueManager.waitingCount, equals(1));

      queueManager.joinQueue(customerId: 'c2', customerName: 'Bob');
      expect(queueManager.waitingCount, equals(2));

      queueManager.serveNext();
      expect(queueManager.waitingCount, equals(1));
    });

    test('estimatedWaitMinutes is calculated correctly', () {
      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      final entry =
          queueManager.joinQueue(customerId: 'c2', customerName: 'Bob');

      // Position 2, 5 minutes per customer = 10 minutes
      expect(entry.estimatedWaitMinutes, equals(10));
    });
  });

  group('Observer Pattern', () {
    test('observer is notified on joinQueue', () {
      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');

      expect(observer.queueUpdates, isNotEmpty);
    });

    test('observer is notified on leaveQueue', () {
      final entry =
          queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      final initialUpdates = observer.queueUpdates.length;

      queueManager.leaveQueue(entry.id);

      expect(observer.queueUpdates.length, greaterThan(initialUpdates));
      expect(observer.statusChanges, isNotEmpty);
    });

    test('observer is notified on serveNext', () {
      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      final initialUpdates = observer.queueUpdates.length;

      queueManager.serveNext();

      expect(observer.queueUpdates.length, greaterThan(initialUpdates));
      expect(observer.statusChanges, isNotEmpty);
    });

    test('observer receives position changes', () {
      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');
      queueManager.joinQueue(customerId: 'c2', customerName: 'Bob');
      queueManager.joinQueue(customerId: 'c3', customerName: 'Charlie');

      observer.positionChanges.clear();

      // Setting VIP should trigger position changes
      final queue = queueManager.queue;
      queueManager.setPriority(queue.last.id, QueuePriority.vip);

      expect(observer.positionChanges, isNotEmpty);
    });

    test('removed observer is not notified', () {
      queueManager.removeObserver(observer);

      queueManager.joinQueue(customerId: 'c1', customerName: 'Alice');

      expect(observer.queueUpdates, isEmpty);
    });
  });
}
