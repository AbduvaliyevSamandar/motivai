import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgState();
}

class _ProgState extends State<ProgressScreen> {
  bool _loaded = false;

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
        title: Text('📊 ${S.get("analytics")}',
            style: GoogleFonts.poppins(
              color: AppColors.txt,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.sub),
            onPressed: () {
              tasks.loadInsights();
              auth.refresh();
            },
          ),
        ],
      ),
      body: tasks.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await tasks.loadInsights();
                await auth.refresh();
              },
              child: ListView(
                padding: const EdgeInsets.all(D.sp16),
                children: [
                  _StatsGrid(auth: auth),
                  const SizedBox(height: D.sp16),
                  _LevelCard(auth: auth, ins: ins),
                  const SizedBox(height: D.sp16),
                  if (ins != null) ...[
                    _WeeklyChart(ins: ins),
                    const SizedBox(height: D.sp16),
                    _CatCard(ins: ins),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

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
      childAspectRatio: 1.6,
      children: [
        _SC('⭐', S.get('total_points'), '${auth.points}', AppColors.accent),
        _SC('🎯', S.get('level'), '${auth.level}', AppColors.primary),
        _SC('🔥', S.get('streak'), '${auth.streak} ${S.get("day")}',
            const Color(0xFFFF6584)),
        _SC('✅', S.get('tasks_label'), '${auth.totalTasks}',
            AppColors.success),
      ],
    );
  }
}

class _SC extends StatelessWidget {
  final String e, l, v;
  final Color c;
  const _SC(this.e, this.l, this.v, this.c);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Text(e, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: D.sp8),
            Text(l,
                style: GoogleFonts.poppins(
                    color: AppColors.sub, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Text(v,
              style: GoogleFonts.poppins(
                color: c,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final AuthProvider auth;
  final Map<String, dynamic>? ins;
  const _LevelCard({required this.auth, required this.ins});

  @override
  Widget build(BuildContext context) {
    final ptsNext = (ins?['points_to_next_level'] ?? 100) as int;
    final lvl = auth.level;
    // Simple progress estimate
    final progress = ptsNext > 0
        ? (1 - ptsNext / (ptsNext + 200)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(auth.levelEmoji,
                style: const TextStyle(fontSize: 32)),
            const SizedBox(width: D.sp12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${S.get("level")} $lvl',
                      style: GoogleFonts.poppins(
                        color: AppColors.txt,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                  Text(
                      '${S.get("next_level")}: $ptsNext ${S.get("points")}',
                      style: GoogleFonts.poppins(
                          color: AppColors.sub, fontSize: 12)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(D.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
              '${(progress * 100).toStringAsFixed(0)}% '
              '• ${auth.points} ball to\'plangan',
              style: GoogleFonts.poppins(
                  color: AppColors.sub, fontSize: 12)),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final Map<String, dynamic> ins;
  const _WeeklyChart({required this.ins});

  @override
  Widget build(BuildContext context) {
    final raw = ins['weekly_points'];
    final weekly = (raw is List)
        ? raw.map((e) => (e as num).toInt()).toList()
        : List<int>.filled(7, 0);
    final days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    final today = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📈 ${S.get("weekly_points")}',
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: D.sp20),
          SizedBox(
            height: 150,
            child: BarChart(BarChartData(
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: AppColors.surface,
                  getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                    '${rod.toY.toInt()} ball',
                    GoogleFonts.poppins(
                        color: AppColors.txt, fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(
                      days[v.toInt() % 7],
                      style: GoogleFonts.poppins(
                          color: AppColors.sub, fontSize: 11),
                    ),
                  ),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              barGroups: List.generate(7, (i) {
                final isToday = i == today;
                final val =
                    i < weekly.length ? weekly[i].toDouble() : 0.0;
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: val,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    gradient: isToday
                        ? const LinearGradient(
                            colors: AppColors.gradPrimary,
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          )
                        : LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.3),
                              AppColors.primary.withValues(alpha: 0.5),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                  ),
                ]);
              }),
            )),
          ),
        ],
      ),
    );
  }
}

class _CatCard extends StatelessWidget {
  final Map<String, dynamic> ins;
  const _CatCard({required this.ins});

  static const _labels = {
    'study': ('📚', "O'qish"),
    'exercise': ('💪', 'Jismoniy'),
    'reading': ('📖', 'Kitob'),
    'meditation': ('🧘', 'Meditatsiya'),
    'social': ('👥', 'Ijtimoiy'),
    'creative': ('🎨', 'Ijodiy'),
    'productivity': ('⚡', 'Samaradorlik'),
    'challenge': ('🏆', 'Musobaqa'),
  };

  @override
  Widget build(BuildContext context) {
    final raw = ins['category_breakdown'];
    if (raw == null) return const SizedBox.shrink();
    final cats = (raw as Map).cast<String, int>();
    if (cats.isEmpty) return const SizedBox.shrink();
    final total = cats.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🗂 ${S.get("cat_breakdown")}',
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 14),
          ...cats.entries.map((e) {
            final info = _labels[e.key];
            final pct = total > 0 ? e.value / total : 0.0;
            final color = AppColors.cat[e.key] ?? AppColors.primary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(children: [
                Row(children: [
                  Text(info?.$1 ?? '📌',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: D.sp8),
                  Expanded(
                    child: Text(info?.$2 ?? e.key,
                        style: GoogleFonts.poppins(
                            color: AppColors.txt, fontSize: 13)),
                  ),
                  Text(
                      '${e.value} ta  '
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                          color: AppColors.sub, fontSize: 12)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(D.sp4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
