import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/task_provider.dart';
import '../../models/models.dart';
import '../../services/smart_plan.dart';
import '../../widgets/nebula/nebula.dart';

class SmartPlanScreen extends StatefulWidget {
  const SmartPlanScreen({super.key});

  @override
  State<SmartPlanScreen> createState() => _SmartPlanScreenState();
}

class _SmartPlanScreenState extends State<SmartPlanScreen> {
  double _hours = 3;
  String _area = 'study';
  bool _pomodoro = true;
  SmartPlan? _plan;

  void _generate() {
    HapticFeedback.mediumImpact();
    setState(() {
      _plan = SmartPlanner.build(
        hours: _hours.round(),
        area: _area,
        includePomodoro: _pomodoro,
      );
    });
  }

  Future<void> _addToTasks() async {
    if (_plan == null) return;
    HapticFeedback.heavyImpact();
    final tasks = context.read<TaskProvider>();
    final focusBlocks =
        _plan!.blocks.where((b) => b.kind == 'focus').take(8).toList();
    final suggestions = focusBlocks
        .map((b) => TaskSuggestion(
              title: '${b.emoji ?? '\u{2B50}'} ${b.title}',
              description: 'Smart plan • ${b.minutes} daqiqa',
              category: _area,
              difficulty: b.minutes >= 50 ? 'medium' : 'easy',
              durationMinutes: b.minutes,
              estimatedPoints: 10 + (b.minutes ~/ 10),
            ))
        .toList();
    await tasks.addSuggestions(
      suggestions: suggestions,
      planTitle: 'Aqlli reja — ${_hours.round()} soat',
      goal: '${_hours.round()} soatlik optimal vaqt bloki',
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      content: Text('${suggestions.length} vazifa qo\'shildi!',
          style: GoogleFonts.poppins()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.txt),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: AppColors.titleGradient,
          ).createShader(b),
          blendMode: BlendMode.srcIn,
          child: Text('Aqlli reja',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              )),
        ),
      ),
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 24),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputCard(),
                  const SizedBox(height: 16),
                  if (_plan == null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded,
                              color: AppColors.accent, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Soat va yo\'nalishni belgilab, reja yarating. AI shu vaqtni optimal bloklarga bo\'ladi.',
                              style: GoogleFonts.poppins(
                                color: AppColors.sub,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _planHeader(),
                    const SizedBox(height: 12),
                    ..._plan!.blocks.map(_blockTile),
                    const SizedBox(height: 16),
                    NebulaButton(
                      label: 'Vazifalarga qo\'shish',
                      icon: Icons.playlist_add_rounded,
                      onTap: _addToTasks,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary.withOpacity(0.18),
          AppColors.secondary.withOpacity(0.08),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Qancha vaqtingiz bor?',
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _hours,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) {
                      setState(() => _hours = v);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${_hours.round()} soat',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Yo\'nalish:',
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SmartPlanner.areas().map((a) {
              final active = _area == a.id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _area = a.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: active
                        ? LinearGradient(colors: [
                            AppColors.primary.withOpacity(0.35),
                            AppColors.secondary.withOpacity(0.2),
                          ])
                        : null,
                    color: active ? null : AppColors.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? AppColors.primary
                          : AppColors.border,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(a.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        a.name,
                        style: GoogleFonts.poppins(
                          color: AppColors.txt,
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Switch.adaptive(
                value: _pomodoro,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _pomodoro = v),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pomodoro tanaffuslar',
                  style: GoogleFonts.poppins(
                    color: AppColors.sub,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          NebulaButton(
            label: _plan == null ? 'Yaratish' : 'Qayta yaratish',
            icon: Icons.auto_awesome_rounded,
            onTap: _generate,
          ),
        ],
      ),
    );
  }

  Widget _planHeader() {
    final total = _plan!.totalMinutes;
    final focus = _plan!.blocks
        .where((b) => b.kind == 'focus')
        .fold<int>(0, (a, b) => a + b.minutes);
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jami',
                    style: GoogleFonts.poppins(
                        color: AppColors.sub, fontSize: 11)),
                Text('$total min',
                    style: GoogleFonts.poppins(
                        color: AppColors.txt,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fokus',
                    style: GoogleFonts.poppins(
                        color: AppColors.sub, fontSize: 11)),
                Text('$focus min',
                    style: GoogleFonts.poppins(
                        color: AppColors.success,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _blockTile(SmartBlock b) {
    final focus = b.kind == 'focus';
    final c = focus
        ? AppColors.primary
        : b.kind == 'long_break'
            ? AppColors.accent
            : AppColors.info;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(focus ? 0.6 : 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                c.withOpacity(0.3),
                c.withOpacity(0.1),
              ]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                b.emoji ?? '\u{2B50}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              b.title,
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 13,
                fontWeight:
                    focus ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text('${b.minutes}m',
              style: GoogleFonts.poppins(
                color: c,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
