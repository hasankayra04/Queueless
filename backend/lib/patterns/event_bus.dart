// Event Bus — asynchronous, decoupled communication between components.

import 'dart:async';

/// A simple event bus that allows components to publish and subscribe to events.
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final Map<Type, StreamController<dynamic>> _controllers = {};

  /// Subscribe to events of type [T].
  StreamSubscription<T> on<T>(void Function(T event) handler) {
    final controller = _getController<T>();
    return controller.stream.listen(handler);
  }

  /// Publish an event of type [T] to all subscribers.
  void emit<T>(T event) {
    if (_controllers.containsKey(T)) {
      _controllers[T]!.add(event);
    }
  }

  StreamController<T> _getController<T>() {
    _controllers.putIfAbsent(T, () => StreamController<T>.broadcast());
    return _controllers[T] as StreamController<T>;
  }

  /// Dispose all stream controllers.
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}

// ─── Domain events ───────────────────────────────────────────────────────────

class CustomerJoinedEvent {
  final String queueId;
  final String customerId;
  final String customerName;
  final int position;
  CustomerJoinedEvent(
      {required this.queueId,
      required this.customerId,
      required this.customerName,
      required this.position});
}

class CustomerLeftEvent {
  final String queueId;
  final String customerId;
  CustomerLeftEvent({required this.queueId, required this.customerId});
}

class CustomerServedEvent {
  final String queueId;
  final String customerId;
  CustomerServedEvent({required this.queueId, required this.customerId});
}

class InventoryUpdatedEvent {
  final String businessId;
  final String itemId;
  final int newQuantity;
  InventoryUpdatedEvent(
      {required this.businessId,
      required this.itemId,
      required this.newQuantity});
}

class ItemOutOfStockEvent {
  final String businessId;
  final String itemId;
  final String itemName;
  ItemOutOfStockEvent(
      {required this.businessId,
      required this.itemId,
      required this.itemName});
}
