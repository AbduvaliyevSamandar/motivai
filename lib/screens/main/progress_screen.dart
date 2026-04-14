import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
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
    final auth  = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final ins   = tasks.insights;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('📊 Tahlil',
            style: TextStyle(
                color: C.txt,
                fontWeight: FontWeight.bold)),
        backgroundColor: C.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: C.sub),
            onPressed: () {
              tasks.loadInsights();
              auth.refresh();
            }),
        ],
      ),
      body: tasks.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: C.primary))
          : RefreshIndicator(
              color: C.primary,
              onRefresh: () async {
                await tasks.loadInsights();
                await auth.refresh();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatsGrid(auth: auth),
                  const SizedBox(height: 16),
                  _LevelCard(auth: auth, ins: ins),
                  const SizedBox(height: 16),
                  if (ins != null) ...[
                    _WeeklyChart(ins: ins),
                    const SizedBox(height: 16),
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
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _SC('⭐', 'Jami ball', '${auth.points}', C.gold),
        _SC('🎯', 'Daraja', '${auth.level}', C.primary),
        _SC('🔥', 'Streak', '${auth.streak} kun', C.accent),
        _SC('✅', 'Vazifalar', '${auth.totalTasks}', C.success),
      ],
    );
  }
}

class _SC extends StatelessWidget {
  final String e, l, v;
  final Color  c;
  const _SC(this.e, this.l, this.v, this.c);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Text(e, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(l, style: const TextStyle(
                color: C.sub, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Text(v, style: TextStyle(
              color: c, fontSize: 22,
              fontWeight: FontWeight.bold)),
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
    final lvl     = auth.level;
    // Simple progress estimate
    final progress = ptsNext > 0
        ? (1 - ptsNext / (ptsNext + 200)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.primary.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(children: [
          Text(auth.levelEmoji,
              style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text('Daraja $lvl',
                style: const TextStyle(
                    color: C.txt, fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('Keyingi darajaga: $ptsNext ball',
                style: const TextStyle(
                    color: C.sub, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: C.border,
            valueColor:
                const AlwaysStoppedAnimation(C.primary),
            minHeight: 10)),
        const SizedBox(height: 6),
        Text('${(progress * 100).toStringAsFixed(0)}% '
            '• ${auth.points} ball to\'plangan',
            style: const TextStyle(
                color: C.sub, fontSize: 12)),
      ]),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final Map<String, dynamic> ins;
  const _WeeklyChart({required this.ins});

  @override
  Widget build(BuildContext context) {
    final raw    = ins['weekly_points'];
    final weekly = (raw is List)
        ? raw.map((e) => (e as num).toInt()).toList()
        : List<int>.filled(7, 0);
    final days   = ['Du','Se','Ch','Pa','Ju','Sh','Ya'];
    final today  = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const Text('📈 Haftalik ballar',
            style: TextStyle(
                color: C.txt, fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: BarChart(BarChartData(
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => C.surface,
                getTooltipItem: (g, _, rod, __) =>
                    BarTooltipItem(
                        '${rod.toY.toInt()} ball',
                        const TextStyle(
                            color: C.txt,
                            fontSize: 12)),
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Text(
                    days[v.toInt() % 7],
                    style: const TextStyle(
                        color: C.sub, fontSize: 11)),
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
                  const FlLine(
                      color: C.border, strokeWidth: 1)),
            barGroups: List.generate(7, (i) {
              final isToday = i == today;
              final val = i < weekly.length
                  ? weekly[i].toDouble()
                  : 0.0;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: val,
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
                          end: Alignment.topCenter)),
              ]);
            }),
          )),
        ),
      ]),
    );
  }
}

class _CatCard extends StatelessWidget {
  final Map<String, dynamic> ins;
  const _CatCard({required this.ins});

  static const _labels = {
    'study':       ('📚', "O'qish"),
    'exercise':    ('💪', 'Jismoniy'),
    'reading':     ('📖', 'Kitob'),
    'meditation':  ('🧘', 'Meditatsiya'),
    'social':      ('👥', 'Ijtimoiy'),
    'creative':    ('🎨', 'Ijodiy'),
    'productivity':('⚡', 'Samaradorlik'),
    'challenge':   ('🏆', 'Musobaqa'),
  };

  @override
  Widget build(BuildContext context) {
    final raw  = ins['category_breakdown'];
    if (raw == null) return const SizedBox.shrink();
    final cats = (raw as Map).cast<String, int>();
    if (cats.isEmpty) return const SizedBox.shrink();
    final total = cats.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const Text('🗂 Kategoriya taqsimoti',
            style: TextStyle(
                color: C.txt, fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        ...cats.entries.map((e) {
          final info  = _labels[e.key];
          final pct   = total > 0 ? e.value / total : 0.0;
          final color = C.cat[e.key] ?? C.primary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(children: [
              Row(children: [
                Text(info?.$1 ?? '📌',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(child: Text(info?.$2 ?? e.key,
                    style: const TextStyle(
                        color: C.txt, fontSize: 13))),
                Text('${e.value} ta  '
                    '${(pct*100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: C.sub, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor:
                      color.withOpacity(0.15),
                  valueColor:
                      AlwaysStoppedAnimation(color),
                  minHeight: 6)),
            ]),
          );
        }),
      ]),
    );
  }
}
