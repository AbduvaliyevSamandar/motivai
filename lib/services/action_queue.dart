import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'user_scope.dart';

/// Action queue for offline mode — any action that fails due to no network
/// is persisted and replayed when we come back online.
class PendingAction {
  final String id;
  final String method;     // 'POST' | 'PATCH' | 'DELETE'
  final String endpoint;   // e.g. '/plans/<id>/tasks/<id>/complete'
  final Map<String, dynamic>? body;
  final DateTime createdAt;

  PendingAction({
    required this.id,
    required this.method,
    required this.endpoint,
    this.body,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'endpoint': endpoint,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
      };

  static PendingAction fromJson(Map<String, dynamic> j) => PendingAction(
        id: j['id'],
        method: j['method'],
        endpoint: j['endpoint'],
        body: j['body'] as Map<String, dynamic>?,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ??
            DateTime.now(),
      );
}

class ActionQueue extends ChangeNotifier {
  static final instance = ActionQueue._();
  ActionQueue._() {
    _init();
  }

  static const _keyBase = 'motivai_action_queue_v1';
  static String get _key => UserScope.key(_keyBase);
  final _api = Api();
  List<PendingAction> _queue = [];
  bool _online = true;
  bool _syncing = false;
  Timer? _syncTimer;
  StreamSubscription? _sub;

  bool get online => _online;
  int get pendingCount => _queue.length;
  bool get syncing => _syncing;

  Future<void> _init() async {
    await _load();
    try {
      final conn = await Connectivity().checkConnectivity();
      _online = !conn.contains(ConnectivityResult.none);
    } catch (_) {
      _online = true;
    }
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final was = _online;
      _online = !results.contains(ConnectivityResult.none);
      notifyListeners();
      if (!was && _online) _trySync();
    });
    if (_online) _trySync();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _queue = list
            .map((e) => PendingAction.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _queue = [];
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(_queue.map((e) => e.toJson()).toList()));
  }

  Future<void> enqueue(PendingAction a) async {
    _queue.add(a);
    await _persist();
    notifyListeners();
    if (_online) _trySync();
  }

  Future<void> clear() async {
    _queue.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _trySync() async {
    if (_syncing || _queue.isEmpty) return;
    _syncing = true;
    notifyListeners();

    final stillFailed = <PendingAction>[];
    for (final a in List<PendingAction>.from(_queue)) {
      try {
        switch (a.method) {
          case 'POST':
            await _api.post(a.endpoint, a.body ?? {});
            break;
          case 'PUT':
            await _api.put(a.endpoint, a.body ?? {});
            break;
          case 'DELETE':
            await _api.delete(a.endpoint);
            break;
        }
      } catch (_) {
        stillFailed.add(a);
      }
    }
    _queue = stillFailed;
    await _persist();
    _syncing = false;
    notifyListeners();
  }

  /// Force sync (e.g. from a retry button)
  Future<void> syncNow() async {
    if (!_online) return;
    await _trySync();
  }
}
