import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override State<ProgressScreen> createState() => _State();
}

class _State extends State<ProgressScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_loaded) {
        _loaded = true;
        await context.read<TaskProvider>().loadInsights();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final tasks  = context.watch<TaskProvider>();
    final ins    = tasks.insights;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('📊 Tahlil',
            style: TextStyle(color: C.txt, fontWeight: FontWeight.bold)),
        backgroundColor: C.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: C.sub),
            onPressed: () => tasks.loadInsights(),
          ),
        ],
      ),
      body: tasks.isLoading
          ? const Center(child: CircularProgressIndicator(color: C.primary))
          : RefreshIndicator(
              color: C.primary,
              onRefresh: () async {
                await tasks.loadInsights();
                await auth.refresh();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats grid
                  _StatsGrid(auth: auth),
                  const SizedBox(height: 20),

                  // Level progress
                  _LevelCard(auth: auth, ins: ins),
                  const SizedBox(height: 20),

                  // Weekly chart
                  if (ins != null) ...[
                    _WeeklyChart(ins: ins),
                    const SizedBox(height: 20),
                  ],

                  // Category breakdown
                  if (ins != null) _CategoryCard(ins: ins),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────
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
      childAspectRatio: 1.6,
      children: [
        _StatCard('⭐', 'Jami ball', auth.points.toString(), C.gold),
        _StatCard('🎯', 'Daraja', '${auth.level}', C.primary),
        _StatCard('🔥', 'Streak', '${auth.streak} kun', C.accent),
        _StatCard('🏆', 'Yutuqlar', '${auth.achiev.length}', C.success),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _StatCard(this.emoji, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(color: C.sub, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(color: color, fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Level Card ────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final AuthProvider auth;
  final Map<String, dynamic>? ins;
  const _LevelCard({required this.auth, required this.ins});

  @override
  Widget build(BuildContext context) {
    final ptsNext = (ins?['points_to_next_level'] ?? 100) as int;
    final ptsNow  = auth.points;
    final level   = auth.level;
    // progress fraction
    final levelStart = _levelThreshold(level - 1);
    final levelEnd   = _levelThreshold(level);
    final progress   = levelEnd > levelStart
        ? (ptsNow - levelStart) / (levelEnd - levelStart)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.primary.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(auth.levelEmoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Daraja $level',
                  style: const TextStyle(color: C.txt, fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text('Keyingi darajaga: $ptsNext ball',
                  style: const TextStyle(color: C.sub, fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: C.border,
            valueColor: const AlwaysStoppedAnimation(C.primary),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        Text('${(progress * 100).toStringAsFixed(0)}% — '
            '$ptsNow / ${_levelThreshold(level)} ball',
            style: const TextStyle(color: C.sub, fontSize: 12)),
      ]),
    );
  }

  int _levelThreshold(int l) {
    if (l <= 0) return 0;
    return (100 * (1.5 * l - 1)).toInt();
  }
}

// ── Weekly Chart ──────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final Map<String, dynamic> ins;
  const _WeeklyChart({required this.ins});

  @override
  Widget build(BuildContext context) {
    final weekly = (ins['weekly_points'] as List?)?.cast<int>() ??
        [0, 0, 0, 0, 0, 0, 0];
    final days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📈 Haftalik ballar',
            style: TextStyle(color: C.txt, fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: C.surface,
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${rod.toY.toInt()} ball',
                    const TextStyle(color: C.txt, fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(
                      days[v.toInt() % 7],
                      style: const TextStyle(color: C.sub, fontSize: 11),
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
                    FlLine(color: C.border, strokeWidth: 1),
              ),
              barGroups: weekly.asMap().entries.map((e) {
                final isToday = e.key == DateTime.now().weekday - 1;
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: e.value.toDouble(),
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    gradient: isToday
                        ? const LinearGradient(
                            colors: C.gradPrimary,
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter)
                        : LinearGradient(
                            colors: [
                              C.primary.withOpacity(0.3),
                              C.primary.withOpacity(0.5)
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Category Breakdown ────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> ins;
  const _CategoryCard({required this.ins});

  static const _cats = {
    'study': ('📚', 'O\'qish'),
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
    final cats = (ins['category_breakdown'] as Map?)?.cast<String, int>() ?? {};
    if (cats.isEmpty) return const SizedBox.shrink();
    final total = cats.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🗂 Kategoriya taqsimoti',
            style: TextStyle(color: C.txt, fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        ...cats.entries.map((e) {
          final info = _cats[e.key];
          final pct  = total > 0 ? e.value / total : 0.0;
          final color= C.catColors[e.key] ?? C.primary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(children: [
              Row(children: [
                Text(info?.$1 ?? '📌',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(info?.$2 ?? e.key,
                      style: const TextStyle(color: C.txt, fontSize: 13)),
                ),
                Text('${e.value} ta  ${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: C.sub, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}
