import 'package:flutter/material.dart';
import '../../config/strings.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../services/rituals_storage.dart';
import '../../widgets/nebula/nebula.dart';

class RitualsScreen extends StatefulWidget {
  const RitualsScreen({super.key});

  @override
  State<RitualsScreen> createState() => _RitualsScreenState();
}

class _RitualsScreenState extends State<RitualsScreen> {
  List<Ritual> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await RitualsStorage.all();
    if (!mounted) return;
    setState(() {
      _list = l;
      _loading = false;
    });
  }

  static const _dayShort = ['', 'Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  static const _emojis = [
    '',
    '\u{1F310}',
    '',
    '\u{1F9D8}',
    '\u{270D}',
    '\u{1F393}',
    '',
    '\u{1F3A8}',
    '\u{1F3C3}',
    '\u{1F305}',
  ];

  void _showEditor({Ritual? existing}) {
    final titleCtrl =
        TextEditingController(text: existing?.title ?? S.tr('Ertalab 20 min ingliz', 'Утром 20 мин английского', 'Morning 20 min English'));
    String emoji = existing?.emoji ?? _emojis[0];
    int hour = existing?.hour ?? 7;
    int minute = existing?.minute ?? 30;
    int duration = existing?.durationMin ?? 20;
    final weekdays = <int>{...?existing?.weekdays, if (existing == null) ...[1, 2, 3, 4, 5]};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(
                top:
                    BorderSide(color: AppColors.glassBorder, width: 1.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existing == null ? S.get('ritual_new') : 'Ritualni tahrirlash',
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _emojis.map((e) {
                        final active = e == emoji;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setS(() => emoji = e);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 4),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? AppColors.primary.withOpacity(0.25)
                                  : AppColors.bg,
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: active ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(e,
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: titleCtrl,
                    label: S.get('ritual_name'),
                    prefixIcon: LucideIcons.pencil,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _stepper(
                          label: S.get('hour_short'),
                          value: hour,
                          min: 0,
                          max: 23,
                          fmt: (v) => v.toString().padLeft(2, '0'),
                          onChange: (v) => setS(() => hour = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _stepper(
                          label: S.get('minute_short'),
                          value: minute,
                          min: 0,
                          max: 59,
                          step: 5,
                          fmt: (v) => v.toString().padLeft(2, '0'),
                          onChange: (v) => setS(() => minute = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _stepper(
                          label: S.tr('Davomi', 'Длит.', 'Duration'),
                          value: duration,
                          min: 5,
                          max: 120,
                          step: 5,
                          fmt: (v) => '$v ${S.tr('min', 'мин', 'min')}',
                          onChange: (v) => setS(() => duration = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(S.get('days_label'),
                        style: TextStyle(
                          color: AppColors.sub,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final d = i + 1; // 1..7
                      final active = weekdays.contains(d);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setS(() {
                            if (active) {
                              weekdays.remove(d);
                            } else {
                              weekdays.add(d);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? AppColors.primary : AppColors.bg,
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: active ? 0 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _dayShort[d],
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : AppColors.sub,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  NebulaButton(
                    label: existing == null ? S.get('save') : S.tr('Yangilash', 'Обновить', 'Update'),
                    icon: LucideIcons.check,
                    onTap: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty || weekdays.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.danger,
                            content: Text(
                              S.get('habit_name_validate'),
                              style: TextStyle(),
                            ),
                          ),
                        );
                        return;
                      }
                      if (existing == null) {
                        await RitualsStorage.create(
                          title: title,
                          emoji: emoji,
                          hour: hour,
                          minute: minute,
                          durationMin: duration,
                          weekdays: weekdays.toList()..sort(),
                        );
                      } else {
                        await RitualsStorage.update(existing.copyWith(
                          title: title,
                          emoji: emoji,
                          hour: hour,
                          minute: minute,
                          durationMin: duration,
                          weekdays: weekdays.toList()..sort(),
                        ));
                      }
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _load();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required int min,
    required int max,
    int step = 1,
    required String Function(int) fmt,
    required ValueChanged<int> onChange,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.sub, fontSize: 10)),
          Text(fmt(value),
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final n = value - step;
                  if (n >= min) onChange(n);
                },
                child: Icon(LucideIcons.chevronDown,
                    color: AppColors.primary, size: 22),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final n = value + step;
                  if (n <= max) onChange(n);
                },
                child: Icon(LucideIcons.chevronUp,
                    color: AppColors.primary, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.txt),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(S.get('rituals'),
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              )),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: AppColors.primary),
            onPressed: () => _showEditor(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                    ? _empty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16, 60, 16, 40),
                        itemCount: _list.length,
                        itemBuilder: (_, i) => _tile(_list[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\u{1F9D8}', style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 14),
            Text(S.get('rituals_empty'),
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            Text(
              S.get('ritual_examples'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.sub, fontSize: 12),
            ),
            const SizedBox(height: 20),
            NebulaButton(
              label: S.get('ritual_new'),
              icon: LucideIcons.plus,
              expand: false,
              onTap: () => _showEditor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Ritual r) {
    final next = r.nextFireAfter(DateTime.now());
    String nextLabel = '—';
    if (next != null) {
      final diff = next.difference(DateTime.now());
      if (diff.inDays > 0) {
        nextLabel = S.get('after_days').replaceAll('{n}', '${diff.inDays}');
      } else if (diff.inHours > 0) {
        nextLabel = S.get('after_hours').replaceAll('{n}', '${diff.inHours}');
      } else {
        nextLabel = S.get('after_minutes').replaceAll('{n}', '${diff.inMinutes}');
      }
    }
    final daysLabel = r.weekdays
        .map((d) => _dayShort[d])
        .join(' ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: r.enabled
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: r.enabled
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.bg,
              shape: BoxShape.circle,
              border: Border.all(
                  color: r.enabled
                      ? AppColors.primary.withOpacity(0.4)
                      : AppColors.border),
            ),
            child: Center(
              child: Text(r.emoji,
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 2),
                Text(
                  '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')} • ${r.durationMin} min • $daysLabel',
                  style: TextStyle(
                      color: AppColors.sub, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                Text(nextLabel,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Switch.adaptive(
            value: r.enabled,
            activeColor: AppColors.primary,
            onChanged: (v) async {
              HapticFeedback.selectionClick();
              await RitualsStorage.update(r.copyWith(enabled: v));
              _load();
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.pencil,
                color: AppColors.sub, size: 18),
            onPressed: () => _showEditor(existing: r),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2,
                color: AppColors.danger.withOpacity(0.7), size: 18),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await RitualsStorage.delete(r.id);
              _load();
            },
          ),
        ],
      ),
    );
  }
}
