import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'sound_pack.dart';

/// Thin wrapper around flutter_local_notifications.
/// On web, methods become no-ops (web not supported by the plugin).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _enabled = true;

  bool get enabled => _enabled;
  set enabled(bool v) => _enabled = v;

  static const _channel = AndroidNotificationChannel(
    'motivai_default',
    'MotivAI',
    description: 'Vazifalar, eslatmalar va yutuqlar',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));
      } catch (_) {
        // fallback to UTC
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const init = InitializationSettings(android: android, iOS: ios);
      await _plugin.initialize(init);

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Request runtime permission (Android 13+ / iOS)
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _ready = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  NotificationDetails get _details {
    final pack = SoundPackStore.current;
    final info = SoundPackStore.info(pack);
    final hasSound =
        pack != SoundPack.vibrate && pack != SoundPack.silent;
    final hasVibration = pack != SoundPack.silent;
    final priority = pack == SoundPack.urgent
        ? Priority.max
        : pack == SoundPack.calm
            ? Priority.defaultPriority
            : Priority.high;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        info.channel,
        'MotivAI ${info.name}',
        channelDescription: info.desc,
        importance: pack == SoundPack.urgent
            ? Importance.max
            : Importance.high,
        priority: priority,
        playSound: hasSound,
        enableVibration: hasVibration,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: hasSound,
      ),
    );
  }

  /// Immediate notification (overdue, achievements, etc.)
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !_ready || !_enabled) return;
    try {
      await _plugin.show(id, title, body, _details, payload: payload);
    } catch (e) {
      debugPrint('show() error: $e');
    }
  }

  /// Schedule a notification for a specific moment.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    if (kIsWeb || !_ready || !_enabled) return;
    if (at.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(at, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('scheduleAt() error: $e');
    }
  }

  Future<void> cancel(int id) async {
    if (kIsWeb || !_ready) return;
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('cancel() error: $e');
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb || !_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Deterministic numeric id from task id string
  static int taskReminderId(String taskId) =>
      'R_$taskId'.hashCode & 0x7FFFFFFF;
  static int taskOverdueId(String taskId) =>
      'O_$taskId'.hashCode & 0x7FFFFFFF;
}
