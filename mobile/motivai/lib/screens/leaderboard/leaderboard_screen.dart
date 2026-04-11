// lib/screens/leaderboard/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _period = 'weekly';
  List _leaderboard = [];
  Map _myRank = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final lb = await api.getLeaderboard(period: _period);
      final rank = await api.getMyRank();
      setState(() {
        _leaderboard = lb['data']['leaderboard'] ?? [];
        _myRank = rank['data'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('🏆 Reyting')),
      body: Column(
        children: [
          // Period filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                for (final p in [
                  {'key': 'daily', 'label': 'Bugun'},
                  {'key': 'weekly', 'label': 'Hafta'},
                  {'key': 'monthly', 'label': 'Oy'},
                  {'key': 'alltime', 'label': "Barchasi"},
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _period = p['key']!);
                        _load();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _period == p['key']
                              ? AppTheme.primary
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _period == p['key']
                                ? AppTheme.primary
                                : AppTheme.divider,
                          ),
                        ),
                        child: Text(
                          p['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _period == p['key']
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // My rank card
          if (_myRank.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sizning o\'rningiz: #${_myRank['rank'] ?? '-'}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                  ),
                  Text(
                    'Top ${100 - (_myRank['percentile'] ?? 0).toInt()}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Leaderboard list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _leaderboard.length,
                    itemBuilder: (ctx, i) {
                      final user = _leaderboard[i];
                      final isMe = user['_id'] == currentUser?.id;
                      final rank = i + 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppTheme.primary.withOpacity(0.08)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isMe
                                ? AppTheme.primary.withOpacity(0.4)
                                : AppTheme.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank
                            SizedBox(
                              width: 32,
                              child: rank <= 3
                                  ? Text(
                                      rank == 1
                                          ? '🥇'
                                          : rank == 2
                                              ? '🥈'
                                              : '🥉',
                                      style:
                                          const TextStyle(fontSize: 22),
                                    )
                                  : Text(
                                      '#$rank',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textSecondary,
                                          fontSize: 13),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            // Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  AppTheme.primary.withOpacity(0.2),
                              child: Text(
                                (user['name'] as String? ?? 'U')[0]
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Name & info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        user['name'] ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isMe
                                              ? AppTheme.primary
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text('Sen',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${user['level'] ?? 1}-daraja • 🔥${user['streak'] ?? 0} streak',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            // XP
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${user['xp'] ?? 0} XP',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${user['total_tasks_completed'] ?? 0} vazifa',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
