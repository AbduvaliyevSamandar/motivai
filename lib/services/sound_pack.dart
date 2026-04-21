import 'package:shared_preferences/shared_preferences.dart';

/// Notification sound/vibration style. Since we can't ship custom audio
/// assets at runtime, each pack tunes the built-in channel: priority,
/// vibration pattern, sound on/off.
enum SoundPack { chime, calm, urgent, vibrate, silent }

class SoundPackStore {
  static const _key = 'motivai_sound_pack';
  static SoundPack _current = SoundPack.chime;
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final name = p.getString(_key);
    if (name != null) {
      _current = SoundPack.values.firstWhere(
        (e) => e.name == name,
        orElse: () => SoundPack.chime,
      );
    }
    _loaded = true;
  }

  static SoundPack get current => _current;

  static Future<void> set(SoundPack s) async {
    _current = s;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, s.name);
  }

  /// UI-friendly description for each pack
  static ({String name, String emoji, String desc, String channel}) info(
      SoundPack s) {
    switch (s) {
      case SoundPack.chime:
        return (
          name: 'Chime',
          emoji: '\u{1F514}',
          desc: 'Standart tovush, oddiy eslatma',
          channel: 'motivai_default'
        );
      case SoundPack.calm:
        return (
          name: 'Calm',
          emoji: '\u{1F338}',
          desc: 'Yumshoq tovush, tanaffuslarga yaxshi',
          channel: 'motivai_calm'
        );
      case SoundPack.urgent:
        return (
          name: 'Urgent',
          emoji: '\u{26A1}',
          desc: 'Kuchli vibratsiya, muhim eslatmalar uchun',
          channel: 'motivai_urgent'
        );
      case SoundPack.vibrate:
        return (
          name: 'Faqat vibratsiya',
          emoji: '\u{1F4F3}',
          desc: 'Tovushsiz — faqat titrash',
          channel: 'motivai_vibrate'
        );
      case SoundPack.silent:
        return (
          name: 'Jim',
          emoji: '\u{1F507}',
          desc: 'Tovushsiz va vibratsiyasiz',
          channel: 'motivai_silent'
        );
    }
  }
}
