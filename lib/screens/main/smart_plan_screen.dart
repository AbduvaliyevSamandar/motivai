import 'package:flutter/material.dart';
import '../../config/strings.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
              description: '${S.get("smart_plan")} • ${b.minutes} ${S.get("unit_minute")}',
              category: _area,
              difficulty: b.minutes >= 50 ? 'medium' : 'easy',
              durationMinutes: b.minutes,
              estimatedPoints: 10 + (b.minutes ~/ 10),
            ))
        .toList();
    await tasks.addSuggestions(
      suggestions: suggestions,
      planTitle: '${S.get("smart_plan_subj")} - ${_hours.round()} ${S.get("unit_hour")}',
      goal: S.tr('${_hours.round()} soatlik optimal vaqt bloki', 'Оптимальный блок на ${_hours.round()} ч.', 'Optimal ${_hours.round()}-hour time block'),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      content: Text(S.get('tasks_added_n').replaceAll('{n}', '${suggestions.length}'),
          style: TextStyle(),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
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
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.txt),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(S.get('smart_plan_title'),
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              )),
      ),
      body: Stack(
        children: [
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.lightbulb,
                              color: AppColors.accent, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              S.get('smart_plan_intro'),
                              style: TextStyle(
                                color: AppColors.sub,
                                fontSize: 11,
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
                      label: S.get('add_to_tasks'),
                      icon: LucideIcons.listPlus,
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
        color: AppColors.primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.get('smart_plan_hours_q'),
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 13,
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
                  '${_hours.round()} ${S.get('unit_hour')}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.txt,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(S.get('direction_label'),
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 13,
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
                    color: active ? AppColors.primary.withOpacity(0.35) : AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
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
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        a.name,
                        style: TextStyle(
                          color: AppColors.txt,
                          fontSize: 11,
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
                  S.get('pomodoro_breaks'),
                  style: TextStyle(
                    color: AppColors.sub,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          NebulaButton(
            label: _plan == null ? S.tr('Yaratish', 'Создать', 'Create') : S.tr('Qayta yaratish', 'Пересоздать', 'Recreate'),
            icon: Iconsax.magicpen,
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jami',
                    style: TextStyle(
                        color: AppColors.sub, fontSize: 11)),
                Text('$total min',
                    style: TextStyle(
                        color: AppColors.txt,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fokus',
                    style: TextStyle(
                        color: AppColors.sub, fontSize: 11)),
                Text('$focus min',
                    style: TextStyle(
                        color: AppColors.success,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
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
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 13,
                fontWeight:
                    focus ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text('${b.minutes}m',
              style: TextStyle(
                color: c,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
