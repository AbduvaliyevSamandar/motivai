import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final progress = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('📊 Progress')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats cards
            stats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Xatolik',
                  style: TextStyle(color: AppTheme.textSecondary)),
              data: (data) => _StatsGrid(data: data),
            ),
            const SizedBox(height: 20),

            // Weekly summary
            const Text('Haftalik Hisobot',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            progress.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Xatolik',
                  style: TextStyle(color: AppTheme.textSecondary)),
              data: (data) => _WeeklySummary(data: data),
            ),
            const SizedBox(height: 20),

            // AI Analysis button
            _AIAnalysisCard(ref: ref),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': '⚡', 'value': '${data['xp'] ?? 0}', 'label': 'Jami XP', 'color': AppTheme.primary},
      {'icon': '🎯', 'value': '${data['level'] ?? 1}', 'label': 'Daraja', 'color': AppTheme.secondary},
      {'icon': '🔥', 'value': '${data['streak'] ?? 0}', 'label': 'Streak', 'color': const Color(0xFFFF6B6B)},
      {'icon': '✅', 'value': '${data['total_tasks_completed'] ?? 0}', 'label': 'Bajarilgan', 'color': const Color(0xFF66BB6A)},
      {'icon': '📚', 'value': '${((data['total_study_minutes'] ?? 0) / 60).toStringAsFixed(1)}s', 'label': 'O\'qish soat', 'color': const Color(0xFF42A5F5)},
      {'icon': '🤖', 'value': '${data['ai_messages_count'] ?? 0}', 'label': 'AI Suhbat', 'color': const Color(0xFFAB47BC)},
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: items.map((item) => Container(
        decoration: BoxDecoration(
          color: (item['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: (item['color'] as Color).withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item['icon'] as String,
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              item['value'] as String,
              style: TextStyle(
                color: item['color'] as Color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              item['label'] as String,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  final Map<String, dynamic> data;

  const _WeeklySummary({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(
                icon: '⚡',
                value: '${data['weekly_xp'] ?? 0}',
                label: 'XP bu hafta',
              ),
              _SummaryItem(
                icon: '✅',
                value: '${data['weekly_tasks'] ?? 0}',
                label: 'Vazifalar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _AIAnalysisCard extends StatefulWidget {
  final WidgetRef ref;

  const _AIAnalysisCard({required this.ref});

  @override
  State<_AIAnalysisCard> createState() => _AIAnalysisCardState();
}

class _AIAnalysisCardState extends State<_AIAnalysisCard> {
  String? _analysis;
  bool _loading = false;

  Future<void> _getAnalysis() async {
    setState(() => _loading = true);
    try {
      final api = widget.ref.read(apiServiceProvider);
      final res = await api.analyzeProgress();
      setState(() {
        _analysis = res['data']['analysis'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.1),
            AppTheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'AI Progress Tahlili',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_analysis != null)
            Text(
              _analysis!,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13, height: 1.5),
            )
          else
            const Text(
              'AI sizning progress\'ingizni tahlil qiladi va maslahatlar beradi',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _getAnalysis,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.analytics_rounded, size: 18),
              label: Text(_loading ? 'Tahlil qilinmoqda...' : 'Tahlil qilish'),
            ),
          ),
        ],
      ),
    );
  }
}
