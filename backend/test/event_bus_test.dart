import 'dart:async';

import 'package:test/test.dart';

import 'package:queueless_backend/core/event_bus.dart';

void main() {
  // Create a fresh EventBus for testing (not using the singleton).
  late EventBus eventBus;

  setUp(() {
    eventBus = EventBus();
    eventBus.clearHistory();
  });

  group('EventBus', () {
    test('publish and subscribe to events', () async {
      final events = <AppEvent>[];
      eventBus.on(EventType.customerJoined, (event) {
        events.add(event);
      });

      eventBus.publish(AppEvent(
        type: EventType.customerJoined,
        data: {'customerId': 'c1'},
      ));

      // Allow the stream to deliver
      await Future<void>.delayed(Duration.zero);

      expect(events.length, equals(1));
      expect(events.first.data['customerId'], equals('c1'));
    });

    test('subscription filters by event type', () async {
      final joinEvents = <AppEvent>[];
      final leaveEvents = <AppEvent>[];

      eventBus.on(EventType.customerJoined, (event) {
        joinEvents.add(event);
      });
      eventBus.on(EventType.customerLeft, (event) {
        leaveEvents.add(event);
      });

      eventBus.publish(AppEvent(
        type: EventType.customerJoined,
        data: {'customerId': 'c1'},
      ));
      eventBus.publish(AppEvent(
        type: EventType.customerLeft,
        data: {'customerId': 'c2'},
      ));

      await Future<void>.delayed(Duration.zero);

      expect(joinEvents.length, equals(1));
      expect(leaveEvents.length, equals(1));
    });

    test('onAny subscribes to multiple types', () async {
      final events = <AppEvent>[];

      eventBus.onAny(
        {EventType.customerJoined, EventType.customerLeft},
        (event) => events.add(event),
      );

      eventBus.publish(AppEvent(
        type: EventType.customerJoined,
        data: {},
      ));
      eventBus.publish(AppEvent(
        type: EventType.customerLeft,
        data: {},
      ));
      eventBus.publish(AppEvent(
        type: EventType.inventoryUpdated,
        data: {},
      ));

      await Future<void>.delayed(Duration.zero);

      expect(events.length, equals(2));
    });

    test('getRecentEvents returns history', () {
      eventBus.publish(AppEvent(
        type: EventType.customerJoined,
        data: {'id': '1'},
      ));
      eventBus.publish(AppEvent(
        type: EventType.customerJoined,
        data: {'id': '2'},
      ));
      eventBus.publish(AppEvent(
        type: EventType.inventoryUpdated,
        data: {'id': '3'},
      ));

      final joinEvents = eventBus.getRecentEvents(EventType.customerJoined);
      expect(joinEvents.length, equals(2));
    });
  });
}
