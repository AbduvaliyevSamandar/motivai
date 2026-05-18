import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/nebula/nebula.dart';
import '../../widgets/productivity_score_card.dart';

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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          tasks.isLoading && ins == null
              ? Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary),
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
                    padding: EdgeInsets.zero,
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            children: [
                              Text(
                                  S.get('analytics'),
                                  style: TextStyle(
                                    color: AppColors.txt,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              const Spacer(),
                              Material(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    tasks.loadInsights();
                                    auth.refresh();
                                  },
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.border),
                                    ),
                                    child: Icon(
                                        LucideIcons.refreshCw,
                                        color: AppColors.sub,
                                        size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: _StatsGrid(auth: auth),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: ProductivityScoreCard(
                          tasks: tasks.all,
                          streak: auth.streak,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: _LevelHero(auth: auth, ins: ins),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: _PeriodFilter(
                          selected: _period,
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            setState(() => _period = v);
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: _CosmicLineChart(ins: ins),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: _HeatmapCard(ins: ins),
                      ),
                      const SizedBox(height: 14),
                      if (ins != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          child: _PieCategoryCard(ins: ins),
                        ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STATS GRID
// ═══════════════════════════════════════════════════════════
class _StatsGrid extends StatelessWidget {
  final AuthProvider auth;
  const _StatsGrid({required this.auth});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        BentoCard(
          icon: Iconsax.star_1,
          value: '${auth.points}',
          label: S.get('total_points'),
          gradient: AppColors.gradGold,
          accent: AppColors.accent,
          trend: '+8%',
        ),
        BentoCard(
          icon: LucideIcons.trendingUp,
          value: '${auth.level}',
          label: S.get('level'),
          gradient: AppColors.gradCosmic,
          accent: AppColors.primary,
        ),
        BentoCard(
          icon: Iconsax.flash_1,
          value: '${auth.streak}',
          label: S.get('streak'),
          gradient: AppColors.gradFire,
          accent: AppColors.accent,
        ),
        BentoCard(
          icon: LucideIcons.checkCircle2,
          value: '${auth.totalTasks}',
          label: S.get('tasks_label'),
          gradient: AppColors.gradSuccess,
          accent: AppColors.success,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LEVEL HERO (XP ring + next level)
// ═══════════════════════════════════════════════════════════
class _LevelHero extends StatelessWidget {
  final AuthProvider auth;
  final Map<String, dynamic>? ins;
  const _LevelHero({required this.auth, required this.ins});

  @override
  Widget build(BuildContext context) {
    final ptsNext = (ins?['points_to_next_level'] ?? 100) as int;
    final progress = ptsNext > 0
        ? (1 - ptsNext / (ptsNext + 200)).clamp(0.0, 1.0)
        : 1.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          XPRing(
            progress: progress,
            size: 110,
            strokeWidth: 8,
            gradientColors: [AppColors.primary],
            center: Text(
              auth.levelEmoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.tr('DARAJA', 'УРОВЕНЬ', 'LEVEL'),
                  style: TextStyle(
                    color: AppColors.sub,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                BigNumber(
                  value: '${auth.level}',
                  size: 54,
                  gradient: AppColors.gradCosmic,
                  align: TextAlign.start,
                ),
                const SizedBox(height: 8),
                Text(
                  '${S.get("next_level")}: $ptsNext XP',
                  style: TextStyle(
                    color: AppColors.sub,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
              ],
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
  const _PeriodFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      S.tr('Kunlik', 'День', 'Daily'),
      S.tr('Haftalik', 'Неделя', 'Weekly'),
      S.tr('Oylik', 'Месяц', 'Monthly'),
    ];
    return Row(
      children: List.generate(items.length, (i) {
        return Padding(
          padding: EdgeInsets.only(
              right: i < items.length - 1 ? 8 : 0),
          child: NebulaChip(
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
//  COSMIC LINE CHART
// ═══════════════════════════════════════════════════════════
class _CosmicLineChart extends StatelessWidget {
  final Map<String, dynamic>? ins;
  const _CosmicLineChart({required this.ins});

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
    final maxY = weekly.isEmpty ? 10.0 : weekly.reduce((a, b) => a > b ? a : b);
    final chartMax = maxY < 10 ? 10.0 : maxY * 1.25;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.lineChart,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                S.get('weekly_points'),
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMax,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.primary,
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        '${s.y.toInt()} XP',
                        TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withOpacity(0.4),
                    strokeWidth: 1,
                    dashArray: [4, 6],
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
                            style: TextStyle(
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
                        style: TextStyle(
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
                    color: AppColors.primary,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    shadow: Shadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 12,
                    ),
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
                      color: AppColors.primary.withOpacity(0.35),
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
//  HEATMAP (nebula dots)
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
      final w = ins?['weekly_points'];
      final avg = (w is List && w.isNotEmpty)
          ? (w.map((e) => (e as num).toInt())
                      .reduce((a, b) => a + b) /
                  w.length)
              .round()
          : 0;
      data = List.generate(35, (i) {
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

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.calendarDays,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                S.get('activity_heatmap'),
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              const cols = 5;
              const rows = 7;
              final gap = 6.0;
              final cell =
                  ((c.maxWidth - gap * (cols - 1)) / cols).clamp(14.0, 36.0);
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
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                S.tr('Kam', 'Мало', 'Less'),
                style: TextStyle(
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
                      color: AppColors.primary.withOpacity(0.1 + i * 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(
                S.get('many'),
                style: TextStyle(
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
    final op = intensity == 0 ? 0.05 : (0.15 + intensity * 0.75);
    return Tooltip(
      message: value > 0 ? '$value ${S.get('remaining')}' : S.tr("Bo'sh", 'Пусто', 'Empty'),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(op),
          borderRadius: BorderRadius.circular(8),
          boxShadow: intensity > 0.5
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(intensity * 0.3),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PIE CATEGORY
// ═══════════════════════════════════════════════════════════
class _PieCategoryCard extends StatefulWidget {
  final Map<String, dynamic> ins;
  const _PieCategoryCard({required this.ins});
  @override
  State<_PieCategoryCard> createState() => _PieCategoryCardState();
}

class _PieCategoryCardState extends State<_PieCategoryCard> {
  int _touchedIndex = -1;

  Map<String, (String, String)> get _labels => {
    'study': ('', S.tr("O'qish", 'Учёба', 'Study')),
    'exercise': ('\u{1F4AA}', S.tr('Jismoniy', 'Спорт', 'Exercise')),
    'reading': ('\u{1F4D6}', S.tr('Kitob', 'Чтение', 'Reading')),
    'meditation': ('\u{1F9D8}', S.tr('Meditatsiya', 'Медитация', 'Meditation')),
    'social': ('\u{1F465}', S.tr('Ijtimoiy', 'Социальное', 'Social')),
    'creative': ('\u{1F3A8}', S.tr('Ijodiy', 'Творчество', 'Creative')),
    'productivity': ('\u{26A1}', S.tr('Samaradorlik', 'Продуктивность', 'Productivity')),
    'challenge': ('\u{1F3C6}', S.tr('Musobaqa', 'Челлендж', 'Challenge')),
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

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pink.withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.pieChart,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                S.get('cat_breakdown'),
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                      sectionsSpace: 3,
                      centerSpaceRadius: 38,
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
                          radius: isTouched ? 72 : 58,
                          titleStyle: TextStyle(
                            fontSize: isTouched ? 14 : 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          borderSide: BorderSide(
                            color: AppColors.card,
                            width: 2,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                info?.$2 ?? e.key,
                                style: TextStyle(
                                  color: AppColors.txt,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: TextStyle(
                                color: AppColors.sub,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
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
