import 'dart:async';

/// Types of events in the system.
enum EventType {
  queueUpdated,
  customerJoined,
  customerLeft,
  customerServed,
  customerCompleted,
  positionChanged,
  priorityChanged,
  inventoryUpdated,
  itemOutOfStock,
  itemRestocked,
  userLoggedIn,
  userRegistered,
}

/// An event that flows through the Event Bus.
class AppEvent {
  final EventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  AppEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Event Bus for asynchronous, decoupled communication between components.
///
/// Uses the Event-Driven approach described in the architecture.
/// Components can subscribe to specific event types and publish events
/// without knowing about each other.
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final _controller = StreamController<AppEvent>.broadcast();
  final _eventHistory = <AppEvent>[];

  /// Clear event history (useful for testing).
  void clearHistory() => _eventHistory.clear();

  /// Stream of all events.
  Stream<AppEvent> get stream => _controller.stream;

  /// Subscribe to events of a specific type.
  StreamSubscription<AppEvent> on(
    EventType type,
    void Function(AppEvent event) handler,
  ) {
    return _controller.stream
        .where((event) => event.type == type)
        .listen(handler);
  }

  /// Subscribe to multiple event types.
  StreamSubscription<AppEvent> onAny(
    Set<EventType> types,
    void Function(AppEvent event) handler,
  ) {
    return _controller.stream
        .where((event) => types.contains(event.type))
        .listen(handler);
  }

  /// Publish an event to all subscribers.
  void publish(AppEvent event) {
    _eventHistory.add(event);
    _controller.add(event);
  }

  /// Get recent events of a specific type.
  List<AppEvent> getRecentEvents(EventType type, {int limit = 50}) {
    return _eventHistory
        .where((e) => e.type == type)
        .toList()
        .reversed
        .take(limit)
        .toList();
  }

  /// Clean up resources.
  void dispose() {
    _controller.close();
  }
}
