import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/progress_bar_animated.dart';
import '../../widgets/custom_chip.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgState();
}

class _ProgState extends State<ProgressScreen> {
  bool _loaded = false;
  int _period = 1; // 0=day, 1=week, 2=month

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_loaded) {
        _loaded = true;
        context.read<TaskProvider>().loadInsights();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final ins = tasks.insights;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          '\u{1F4CA} ${S.get("analytics")}',
          style: GoogleFonts.poppins(
            color: AppColors.txt,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.sub),
            onPressed: () {
              HapticFeedback.lightImpact();
              tasks.loadInsights();
              auth.refresh();
            },
          ),
        ],
      ),
      body: tasks.isLoading && ins == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              onRefresh: () async {
                await tasks.loadInsights();
                await auth.refresh();
              },
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    D.sp16, D.sp8, D.sp16, 80),
                children: [
                  _StatsGrid(auth: auth),
                  const SizedBox(height: D.sp16),
                  _LevelCard(auth: auth, ins: ins),
                  const SizedBox(height: D.sp16),
                  _PeriodFilter(
                    selected: _period,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _period = v);
                    },
                  ),
                  const SizedBox(height: D.sp16),
                  _WeeklyLineChart(ins: ins),
                  const SizedBox(height: D.sp16),
                  _HeatmapCard(ins: ins),
                  const SizedBox(height: D.sp16),
                  if (ins != null) _CategoryPieCard(ins: ins),
                ],
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STATS GRID — 4 gradient cards
// ═══════════════════════════════════════════════════════════
class _StatsGrid extends StatelessWidget {
  final AuthProvider auth;
  const _StatsGrid({required this.auth});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: D.sp12,
      mainAxisSpacing: D.sp12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        StatCard(
          icon: Icons.star_rounded,
          value: '${auth.points}',
          label: S.get('total_points'),
          gradient: AppColors.gradGold,
          trend: '+8%',
        ),
        StatCard(
          icon: Icons.trending_up_rounded,
          value: '${auth.level}',
          label: S.get('level'),
          gradient: AppColors.gradPrimary,
        ),
        StatCard(
          icon: Icons.local_fire_department_rounded,
          value: '${auth.streak}',
          label: S.get('streak'),
          gradient: AppColors.gradAccent,
        ),
        StatCard(
          icon: Icons.check_circle_rounded,
          value: '${auth.totalTasks}',
          label: S.get('tasks_label'),
          gradient: AppColors.gradSuccess,
          trend: '+${auth.totalTasks}',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LEVEL CARD
// ═══════════════════════════════════════════════════════════
class _LevelCard extends StatelessWidget {
  final AuthProvider auth;
  final Map<String, dynamic>? ins;
  const _LevelCard({required this.auth, required this.ins});

  @override
  Widget build(BuildContext context) {
    final ptsNext = (ins?['points_to_next_level'] ?? 100) as int;
    final lvl = auth.level;
    final progress = ptsNext > 0
        ? (1 - ptsNext / (ptsNext + 200)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: AppColors.gradPrimary),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    auth.levelEmoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: D.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${S.get("level")} $lvl',
                      style: GoogleFonts.poppins(
                        color: AppColors.txt,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${S.get("next_level")}: $ptsNext ${S.get("points")}',
                      style: GoogleFonts.poppins(
                        color: AppColors.sub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: D.sp16),
          ProgressBarAnimated(value: progress, height: 10, showPercent: true),
          const SizedBox(height: D.sp8),
          Text(
            '${auth.points} ${S.get("points")} \u2022 ${(progress * 100).toInt()}%',
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PERIOD FILTER
// ═══════════════════════════════════════════════════════════
class _PeriodFilter extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _PeriodFilter(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = ['Kunlik', 'Haftalik', 'Oylik'];
    return Row(
      children: List.generate(items.length, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < items.length - 1 ? D.sp8 : 0),
          child: CustomChip(
            label: items[i],
            selected: selected == i,
            onTap: () => onChanged(i),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  WEEKLY LINE CHART with gradient fill
// ═══════════════════════════════════════════════════════════
class _WeeklyLineChart extends StatelessWidget {
  final Map<String, dynamic>? ins;
  const _WeeklyLineChart({required this.ins});

  @override
  Widget build(BuildContext context) {
    final raw = ins?['weekly_points'];
    final weekly = (raw is List)
        ? raw.map((e) => (e as num).toDouble()).toList()
        : List<double>.filled(7, 0);
    while (weekly.length < 7) {
      weekly.add(0);
    }
    final days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    final maxY = weekly.reduce((a, b) => a > b ? a : b);
    final chartMax = maxY < 10 ? 10.0 : maxY * 1.25;

    return Container(
      padding: const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppColors.isDark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(D.sp8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.gradPrimary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart_rounded,
                    color: Colors.white, size: D.iconMd),
              ),
              const SizedBox(width: D.sp12),
              Text(
                S.get('weekly_points'),
                style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: D.sp24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMax,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.txt,
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        '${s.y.toInt()} ${S.get("points")}',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withOpacity(0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            days[i],
                            style: GoogleFonts.poppins(
                              color: AppColors.sub,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: chartMax / 4,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.poppins(
                          color: AppColors.sub,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      weekly.length,
                      (i) => FlSpot(i.toDouble(), weekly[i]),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: const LinearGradient(
                      colors: AppColors.gradPrimary,
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: AppColors.primary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.25),
                          AppColors.secondary.withOpacity(0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HEATMAP — 5 weeks x 7 days
// ═══════════════════════════════════════════════════════════
class _HeatmapCard extends StatelessWidget {
  final Map<String, dynamic>? ins;
  const _HeatmapCard({required this.ins});

  @override
  Widget build(BuildContext context) {
    final raw = ins?['heatmap'] ?? ins?['activity'];
    final List<int> data;
    if (raw is List) {
      data = raw.map((e) => (e as num).toInt()).toList();
    } else {
      // Fallback: generate mock-ish based on weekly
      final w = ins?['weekly_points'];
      final avg = (w is List && w.isNotEmpty)
          ? (w.map((e) => (e as num).toInt()).reduce((a, b) => a + b) /
                  w.length)
              .round()
          : 0;
      data = List.generate(35, (i) {
        // Lower activity for later weeks
        final factor = (i / 35) * 0.5 + 0.5;
        final base = (avg * factor).round();
        return (i % 3 == 0 ? base + 1 : base).clamp(0, 10);
      });
    }
    while (data.length < 35) {
      data.add(0);
    }

    final maxVal = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1 : maxVal;

    return Container(
      padding: const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(D.sp8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.gradSuccess),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: D.iconMd),
              ),
              const SizedBox(width: D.sp12),
              Text(
                'Faollik (35 kun)',
                style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: D.sp16),
          LayoutBuilder(
            builder: (context, c) {
              const cols = 5;
              const rows = 7;
              final gap = 6.0;
              final cell = ((c.maxWidth - gap * (cols - 1)) / cols)
                  .clamp(14.0, 36.0);
              return SizedBox(
                height: rows * cell + (rows - 1) * gap,
                child: Column(
                  children: List.generate(rows, (r) {
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: r < rows - 1 ? gap : 0),
                      child: Row(
                        children: List.generate(cols, (col) {
                          final idx = col * rows + r;
                          final v = idx < data.length ? data[idx] : 0;
                          final intensity = v / safeMax;
                          return Padding(
                            padding: EdgeInsets.only(
                                right: col < cols - 1 ? gap : 0),
                            child: _HeatCell(
                              size: cell,
                              intensity: intensity,
                              value: v,
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: D.sp12),
          Row(
            children: [
              Text(
                'Kam',
                style: GoogleFonts.poppins(
                  color: AppColors.sub,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              ...List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(
                        0.15 + i * 0.18,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(
                'Ko\'p',
                style: GoogleFonts.poppins(
                  color: AppColors.sub,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  final double size;
  final double intensity;
  final int value;
  const _HeatCell({
    required this.size,
    required this.intensity,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = intensity == 0 ? 0.08 : (0.15 + intensity * 0.75);
    return Tooltip(
      message: value > 0 ? '$value ta' : 'Bo\'sh',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(opacity),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PIE CHART — Category breakdown
// ═══════════════════════════════════════════════════════════
class _CategoryPieCard extends StatefulWidget {
  final Map<String, dynamic> ins;
  const _CategoryPieCard({required this.ins});

  @override
  State<_CategoryPieCard> createState() => _CategoryPieCardState();
}

class _CategoryPieCardState extends State<_CategoryPieCard> {
  int _touchedIndex = -1;

  static const _labels = {
    'study': ('\u{1F4DA}', "O'qish"),
    'exercise': ('\u{1F4AA}', 'Jismoniy'),
    'reading': ('\u{1F4D6}', 'Kitob'),
    'meditation': ('\u{1F9D8}', 'Meditatsiya'),
    'social': ('\u{1F465}', 'Ijtimoiy'),
    'creative': ('\u{1F3A8}', 'Ijodiy'),
    'productivity': ('\u{26A1}', 'Samaradorlik'),
    'challenge': ('\u{1F3C6}', 'Musobaqa'),
  };

  @override
  Widget build(BuildContext context) {
    final raw = widget.ins['category_breakdown'];
    if (raw == null) return const SizedBox.shrink();
    final cats = (raw as Map).cast<String, dynamic>();
    final entries = cats.entries
        .map((e) => MapEntry(e.key, (e.value as num).toInt()))
        .where((e) => e.value > 0)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    final total = entries.fold<int>(0, (a, e) => a + e.value);

    return Container(
      padding: const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(D.sp8),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: AppColors.gradAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_rounded,
                    color: Colors.white, size: D.iconMd),
              ),
              const SizedBox(width: D.sp12),
              Text(
                S.get('cat_breakdown'),
                style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: D.sp20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = response
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      startDegreeOffset: -90,
                      sections: List.generate(entries.length, (i) {
                        final e = entries[i];
                        final pct = e.value / total;
                        final color =
                            AppColors.cat[e.key] ?? AppColors.primary;
                        final isTouched = i == _touchedIndex;
                        return PieChartSectionData(
                          color: color,
                          value: e.value.toDouble(),
                          title: '${(pct * 100).toInt()}%',
                          radius: isTouched ? 70 : 58,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: isTouched ? 14 : 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: D.sp16),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.map((e) {
                      final info = _labels[e.key];
                      final color =
                          AppColors.cat[e.key] ?? AppColors.primary;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: D.sp8),
                            Expanded(
                              child: Text(
                                info?.$2 ?? e.key,
                                style: GoogleFonts.poppins(
                                  color: AppColors.txt,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: GoogleFonts.poppins(
                                color: AppColors.sub,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
