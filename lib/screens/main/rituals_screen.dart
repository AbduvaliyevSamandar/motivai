import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    '\u{1F4DA}',
    '\u{1F310}',
    '\u{1F4AA}',
    '\u{1F9D8}',
    '\u{270D}',
    '\u{1F393}',
    '\u{1F4BB}',
    '\u{1F3A8}',
    '\u{1F3C3}',
    '\u{1F305}',
  ];

  void _showEditor({Ritual? existing}) {
    final titleCtrl =
        TextEditingController(text: existing?.title ?? 'Ertalab 20 min ingliz');
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
                  const BorderRadius.vertical(top: Radius.circular(28)),
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
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existing == null ? 'Yangi ritual' : 'Ritualni tahrirlash',
                    style: GoogleFonts.poppins(
                      color: AppColors.txt,
                      fontSize: 20,
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
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: titleCtrl,
                    label: 'Ritual nomi',
                    prefixIcon: LucideIcons.pencil,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _stepper(
                          label: 'Soat',
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
                          label: 'Daqiqa',
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
                          label: 'Davomi',
                          value: duration,
                          min: 5,
                          max: 120,
                          step: 5,
                          fmt: (v) => '$v min',
                          onChange: (v) => setS(() => duration = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Kunlar',
                        style: GoogleFonts.poppins(
                          color: AppColors.sub,
                          fontSize: 12,
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
                            gradient: active
                                ? LinearGradient(
                                    colors: AppColors.gradCosmic)
                                : null,
                            color: active ? null : AppColors.bg,
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
                              style: GoogleFonts.poppins(
                                color: active
                                    ? Colors.white
                                    : AppColors.sub,
                                fontSize: 12,
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
                    label: existing == null ? 'Saqlash' : 'Yangilash',
                    icon: LucideIcons.check,
                    onTap: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty || weekdays.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.danger,
                            content: Text(
                              'Ism va kamida 1 kunni tanlang',
                              style: GoogleFonts.poppins(),
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
              style: GoogleFonts.poppins(
                  color: AppColors.sub, fontSize: 10)),
          Text(fmt(value),
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 17,
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
        title: ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: AppColors.titleGradient,
          ).createShader(b),
          blendMode: BlendMode.srcIn,
          child: Text('Rituallar',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              )),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: AppColors.primary),
            onPressed: () => _showEditor(),
          ),
        ],
      ),
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 22),
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
            Text('\u{1F9D8}', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 14),
            Text('Rituallar yo\'q',
                style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            Text(
              '"Har ertalab 20 min ingliz" kabi takroriy ishlar',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: AppColors.sub, fontSize: 13),
            ),
            const SizedBox(height: 20),
            NebulaButton(
              label: 'Yangi ritual',
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
        nextLabel = 'Keyin ${diff.inDays} kunda';
      } else if (diff.inHours > 0) {
        nextLabel = 'Keyin ${diff.inHours} soat';
      } else {
        nextLabel = 'Keyin ${diff.inMinutes} daqiqa';
      }
    }
    final daysLabel = r.weekdays
        .map((d) => _dayShort[d])
        .join(' ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
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
              gradient: r.enabled
                  ? LinearGradient(colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.secondary.withOpacity(0.15),
                    ])
                  : null,
              color: r.enabled ? null : AppColors.bg,
              shape: BoxShape.circle,
              border: Border.all(
                  color: r.enabled
                      ? AppColors.primary.withOpacity(0.4)
                      : AppColors.border),
            ),
            child: Center(
              child: Text(r.emoji,
                  style: const TextStyle(fontSize: 22)),
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
                    style: GoogleFonts.poppins(
                      color: AppColors.txt,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 2),
                Text(
                  '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')} • ${r.durationMin} min • $daysLabel',
                  style: GoogleFonts.poppins(
                      color: AppColors.sub, fontSize: 11),
                ),
                Text(nextLabel,
                    style: GoogleFonts.poppins(
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
