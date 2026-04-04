import 'package:flutter/foundation.dart';

import '../models/queue_entry.dart';
import 'api_client.dart';

/// Service for queue state management.
///
/// Implements the Observer pattern on the client side — the UI observes
/// this service via [ChangeNotifier] and re-renders when the queue updates.
class QueueService extends ChangeNotifier {
  final ApiClient _api;
  List<QueueEntry> _queue = [];
  int _waitingCount = 0;
  Map<String, dynamic>? _myPosition;
  bool _isLoading = false;
  String? _error;

  QueueService(this._api);

  List<QueueEntry> get queue => _queue;
  int get waitingCount => _waitingCount;
  Map<String, dynamic>? get myPosition => _myPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch the current queue from the server.
  Future<void> fetchQueue() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/api/queue/');
      final entries = (response['queue'] as List)
          .map((e) => QueueEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      _queue = entries;
      _waitingCount = response['waitingCount'] as int;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Join the queue.
  Future<QueueEntry?> joinQueue({
    required String customerId,
    required String customerName,
    QueuePriority priority = QueuePriority.normal,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post('/api/queue/join', {
        'customerId': customerId,
        'customerName': customerName,
        'priority': priority.name,
      });

      final entry =
          QueueEntry.fromJson(response['entry'] as Map<String, dynamic>);
      await fetchQueue();
      _error = null;
      return entry;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Leave the queue.
  Future<bool> leaveQueue(String entryId) async {
    try {
      await _api.delete('/api/queue/$entryId');
      await fetchQueue();
      _error = null;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Get the current customer's position.
  Future<void> fetchMyPosition(String customerId) async {
    try {
      _myPosition = await _api.get('/api/queue/position/$customerId');
      _error = null;
    } on ApiException {
      _myPosition = null;
    }
    notifyListeners();
  }

  /// Serve the next person in queue (owner action).
  Future<QueueEntry?> serveNext() async {
    try {
      final response = await _api.post('/api/queue/serve-next');
      final entry =
          QueueEntry.fromJson(response['entry'] as Map<String, dynamic>);
      await fetchQueue();
      return entry;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  /// Complete service for an entry (owner action).
  Future<bool> completeService(String entryId) async {
    try {
      await _api.post('/api/queue/$entryId/complete');
      await fetchQueue();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Change entry priority (owner action).
  Future<bool> setPriority(String entryId, QueuePriority priority) async {
    try {
      await _api.put('/api/queue/$entryId/priority', {
        'priority': priority.name,
      });
      await fetchQueue();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Clear error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
