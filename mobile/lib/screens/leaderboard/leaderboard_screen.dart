import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final periods = ['weekly', 'monthly', 'alltime'];
  final periodLabels = ['Haftalik', 'Oylik', 'Hamma vaqt'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Global Reyting'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: periodLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: periods.map((period) {
          final data = ref.watch(leaderboardProvider(period));
          return data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Xatolik: $e',
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ),
            data: (data) {
              final leaderboard = data['leaderboard'] as List? ?? [];
              final myRank = data['current_user_rank'];

              return RefreshIndicator(
                onRefresh: () => ref.refresh(leaderboardProvider(period).future),
                child: ListView(
                  children: [
                    // My rank card
                    if (myRank != null)
                      _MyRankCard(rank: myRank),

                    // Top 3 podium
                    if (leaderboard.length >= 3)
                      _PodiumWidget(top3: leaderboard.take(3).toList()),

                    // Full list
                    ...leaderboard.asMap().entries.map((e) {
                      final i = e.key;
                      final entry = e.value;
                      if (i < 3) return const SizedBox.shrink();
                      return _LeaderboardRow(entry: entry, rank: i + 1);
                    }),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  final int rank;

  const _MyRankCard({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.military_tech_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sizning o\'rningiz',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('#$rank',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumWidget extends StatelessWidget {
  final List<dynamic> top3;

  const _PodiumWidget({required this.top3});

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    final colors = [AppTheme.gold, const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];

    // Order: 2nd, 1st, 3rd
    final order = [1, 0, 2];
    final heights = [80.0, 120.0, 60.0];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: order.map((i) {
          if (i >= top3.length) return const Expanded(child: SizedBox());
          final entry = top3[i];
          return Expanded(
            child: Column(
              children: [
                Text(medals[i], style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  entry['name'] ?? 'User',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('${entry['xp']} XP',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 10)),
                const SizedBox(height: 4),
                Container(
                  height: heights[order.indexOf(i)],
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: colors[i].withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                    border: Border.all(color: colors[i].withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Text(
                      '#${i + 1}',
                      style: TextStyle(
                          color: colors[i], fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int rank;

  const _LeaderboardRow({required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = entry['is_current_user'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primary.withOpacity(0.1)
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? AppTheme.primary.withOpacity(0.4)
              : AppTheme.divider,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: isCurrentUser ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCurrentUser
                    ? [AppTheme.primary, AppTheme.secondary]
                    : [AppTheme.surface, AppTheme.surfaceCard],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (entry['name'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry['name'] ?? 'User'}${isCurrentUser ? ' (Siz)' : ''}',
                  style: TextStyle(
                    color: isCurrentUser
                        ? AppTheme.primary
                        : AppTheme.textPrimary,
                    fontWeight:
                        isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      entry['country'] ?? 'UZ',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '🔥 ${entry['streak'] ?? 0} kun',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry['xp']} XP',
                style: TextStyle(
                  color: isCurrentUser ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                'Lv.${entry['level'] ?? 1}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
