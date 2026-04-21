import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import '../services/morning_ritual.dart';
import 'nebula/nebula.dart';

class MorningRitualCard extends StatefulWidget {
  const MorningRitualCard({super.key});

  @override
  State<MorningRitualCard> createState() => _MorningRitualCardState();
}

class _MorningRitualCardState extends State<MorningRitualCard> {
  bool _loading = true;
  MorningRitualEntry? _today;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await MorningRitual.todaysEntry();
    if (mounted) {
      setState(() {
        _today = t;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 0);
    final done = _today != null;
    final hour = DateTime.now().hour;
    // Only show before noon if undone; show "done" card all day so user sees their own entry
    if (!done && hour >= 14) return const SizedBox(height: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        onTap: () => _openSheet(context),
        glowColors: [AppColors.accent, AppColors.pink],
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.accent.withOpacity(0.35),
                  AppColors.pink.withOpacity(0.2),
                ]),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: Center(
                child: Text(
                  done ? MorningRitual.moodEmojis[_today!.mood - 1] : '\u{2600}',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done ? 'Bugungi maqsad' : 'Kun boshi rituali',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.txt,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    done
                        ? (_today!.mainGoal.isEmpty
                            ? '\u{1F4AB} ${_today!.gratitude}'
                            : _today!.mainGoal)
                        : '1 daqiqa — kayfiyat, maqsad, minnatdorlik',
                    style: GoogleFonts.poppins(
                      color: AppColors.sub,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_rounded,
              color: done ? AppColors.success : AppColors.accent,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RitualSheet(
        initial: _today,
        onSaved: () {
          _load();
        },
      ),
    );
  }
}

class _RitualSheet extends StatefulWidget {
  final MorningRitualEntry? initial;
  final VoidCallback onSaved;
  const _RitualSheet({required this.initial, required this.onSaved});

  @override
  State<_RitualSheet> createState() => _RitualSheetState();
}

class _RitualSheetState extends State<_RitualSheet> {
  int _mood = 3;
  final _goal = TextEditingController();
  final _grat = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _mood = widget.initial!.mood;
      _goal.text = widget.initial!.mainGoal;
      _grat.text = widget.initial!.gratitude;
    }
  }

  @override
  void dispose() {
    _goal.dispose();
    _grat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await MorningRitual.save(MorningRitualEntry(
      date: date,
      mood: _mood,
      mainGoal: _goal.text.trim(),
      gratitude: _grat.text.trim(),
    ));
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSaved();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      content: Text('Ritual saqlandi \u{1F31F}', style: GoogleFonts.poppins()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            const SizedBox(height: 18),
            ShaderMask(
              shaderCallback: (b) => LinearGradient(
                colors: AppColors.titleGradient,
              ).createShader(b),
              blendMode: BlendMode.srcIn,
              child: Text(
                'Kun boshi rituali',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '1 daqiqa — o\'z kuningizni asoslang',
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            _label('1. Kayfiyatingiz qanday?'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final n = i + 1;
                final selected = n == _mood;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _mood = n);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(colors: [
                              AppColors.primary.withOpacity(0.35),
                              AppColors.secondary.withOpacity(0.2),
                            ])
                          : null,
                      color: selected ? null : AppColors.bg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        MorningRitual.moodEmojis[i],
                        style: TextStyle(
                            fontSize: selected ? 28 : 22),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            _label('2. Bugungi asosiy maqsadingiz?'),
            const SizedBox(height: 10),
            GlassTextField(
              controller: _goal,
              label: 'Masalan: 3 vazifani tugatish',
              prefixIcon: Icons.flag_rounded,
            ),
            const SizedBox(height: 16),
            _label('3. Nima uchun minnatdorsiz?'),
            const SizedBox(height: 10),
            GlassTextField(
              controller: _grat,
              label: 'Bir narsa yozing…',
              prefixIcon: Icons.favorite_rounded,
            ),
            const SizedBox(height: 24),
            NebulaButton(
              label: 'Saqlash',
              icon: Icons.check_rounded,
              onTap: _save,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          t,
          style: GoogleFonts.poppins(
            color: AppColors.sub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
