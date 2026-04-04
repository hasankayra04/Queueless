import 'dart:async';

/// Lightweight client-side event bus for UI notifications.
///
/// Used to communicate between different parts of the Flutter app
/// without tight coupling.
class AppEventBus {
  static final AppEventBus _instance = AppEventBus._internal();
  factory AppEventBus() => _instance;
  AppEventBus._internal();

  final _controller = StreamController<AppUIEvent>.broadcast();

  Stream<AppUIEvent> get stream => _controller.stream;

  StreamSubscription<AppUIEvent> on(
    String type,
    void Function(AppUIEvent) handler,
  ) {
    return _controller.stream
        .where((event) => event.type == type)
        .listen(handler);
  }

  void emit(AppUIEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}

class AppUIEvent {
  final String type;
  final Map<String, dynamic> data;

  AppUIEvent({required this.type, this.data = const {}});
}
