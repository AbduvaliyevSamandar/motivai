import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../providers/task_provider.dart';
import '../../models/models.dart';
import '../../widgets/nebula/nebula.dart';
import '../widgets/task_detail_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _visibleMonth = DateTime.now();
  DateTime _selected = DateTime.now();

  static const _weekdayLabels = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    // Bucket tasks by day (based on scheduledAt or completedAt fallback)
    final byDay = <String, List<Task>>{};
    for (final t in tasks.all) {
      final d = t.scheduledAt ?? t.completedAt;
      if (d == null) continue;
      final k = _key(d);
      byDay.putIfAbsent(k, () => []).add(t);
    }

    final tasksOfDay = byDay[_key(_selected)] ?? const <Task>[];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 20),
          SafeArea(
            child: Column(
              children: [
                _header(),
                _monthNav(),
                const SizedBox(height: 8),
                _weekHeader(),
                const SizedBox(height: 6),
                _grid(byDay),
                const SizedBox(height: 12),
                Expanded(
                  child: _taskList(context, tasksOfDay),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.chevronLeft,
                color: AppColors.txt, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: AppColors.titleGradient,
            ).createShader(b),
            blendMode: BlendMode.srcIn,
            child: Text(
              'Kalendar',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Spacer(),
          Material(
            color: AppColors.card.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selected = DateTime.now();
                  _visibleMonth = DateTime.now();
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Bugun',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthNav() {
    final monthNames = [
      'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
      'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
      child: Row(
        children: [
          _arrow(LucideIcons.chevronLeft, () {
            setState(() {
              _visibleMonth = DateTime(
                _visibleMonth.year,
                _visibleMonth.month - 1,
                1,
              );
            });
          }),
          Expanded(
            child: Center(
              child: Text(
                '${monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            ),
          ),
          _arrow(LucideIcons.chevronRight, () {
            setState(() {
              _visibleMonth = DateTime(
                _visibleMonth.year,
                _visibleMonth.month + 1,
                1,
              );
            });
          }),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.card.withOpacity(0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.sub, size: 18),
        ),
      ),
    );
  }

  Widget _weekHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _weekdayLabels
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: GoogleFonts.poppins(
                        color: AppColors.sub,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _grid(Map<String, List<Task>> byDay) {
    final firstOfMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final firstWeekday = (firstOfMonth.weekday + 6) % 7; // Mon=0
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: totalCells,
        itemBuilder: (_, i) {
          final dayNum = i - firstWeekday + 1;
          if (dayNum < 1 || dayNum > daysInMonth) {
            return const SizedBox.shrink();
          }
          final d = DateTime(
              _visibleMonth.year, _visibleMonth.month, dayNum);
          final isToday = d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
          final isSelected = d.year == _selected.year &&
              d.month == _selected.month &&
              d.day == _selected.day;
          final dayTasks = byDay[_key(d)] ?? const <Task>[];
          final hasDone = dayTasks.any((t) => t.isCompleted);
          final hasPending = dayTasks.any((t) => !t.isCompleted);

          return _CalendarCell(
            day: dayNum,
            isToday: isToday,
            isSelected: isSelected,
            hasDone: hasDone,
            hasPending: hasPending,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selected = d);
            },
          );
        },
      ),
    );
  }

  Widget _taskList(BuildContext context, List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.secondary.withOpacity(0.1),
                  ]),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('\u{1F4C5}',
                      style: TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bu kunda vazifa yo\'q',
                style: GoogleFonts.poppins(
                  color: AppColors.sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: tasks.length,
      itemBuilder: (_, i) => _CalTaskItem(
        task: tasks[i],
        onTap: () => showTaskDetail(context, tasks[i]),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasDone;
  final bool hasPending;
  final VoidCallback onTap;

  const _CalendarCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasDone,
    required this.hasPending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: AppColors.gradCosmic)
              : null,
          color: isSelected
              ? null
              : (isToday
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isToday
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.border.withOpacity(0.3)),
            width: isToday ? 1.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: GoogleFonts.poppins(
                color: isSelected
                    ? Colors.white
                    : (isToday ? AppColors.primary : AppColors.txt),
                fontSize: 13,
                fontWeight:
                    (isSelected || isToday) ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            if (hasPending || hasDone)
              Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDone)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasDone && hasPending)
                      const SizedBox(width: 2),
                    if (hasPending)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalTaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  const _CalTaskItem({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: done
                    ? AppColors.success.withOpacity(0.3)
                    : task.color.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: task.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(task.emoji,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: AppColors.txt,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.timeLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.timeLabel,
                          style: GoogleFonts.poppins(
                            color: AppColors.sub,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  done
                      ? LucideIcons.checkCircle2
                      : LucideIcons.chevronRight,
                  color: done ? AppColors.success : AppColors.sub,
                  size: done ? 20 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
