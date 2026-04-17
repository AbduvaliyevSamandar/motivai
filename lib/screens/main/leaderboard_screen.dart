import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LbState();
}

class _LbState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final rank = tasks.myRank;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            backgroundColor: AppColors.surface,
            pinned: true,
            expandedHeight: 170,
            flexibleSpace: FlexibleSpaceBar(
              background: _MyRankCard(rank: rank, auth: auth),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.sub,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: '🌍 ${S.get("all_time")}'),
                Tab(text: '📅 ${S.get("this_week")}'),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: AppColors.sub),
                onPressed: () => tasks.refreshLeaderboard(),
              ),
            ],
          ),
        ],
        body: tasks.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tab,
                children: [
                  _LbList(
                    entries: tasks.globalLb,
                    myId: auth.user?['_id']?.toString() ??
                        auth.user?['id']?.toString() ??
                        '',
                  ),
                  _LbList(
                    entries: tasks.weeklyLb,
                    myId: auth.user?['_id']?.toString() ??
                        auth.user?['id']?.toString() ??
                        '',
                  ),
                ],
              ),
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  final Map<String, dynamic>? rank;
  final AuthProvider auth;
  const _MyRankCard({required this.rank, required this.auth});

  @override
  Widget build(BuildContext context) {
    final r = rank?['rank'] ?? '—';
    final pct = rank?['percentile'] ?? 0;
    final tot = rank?['total_users'] ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(D.sp20, 52, D.sp20, D.sp16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.bg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.gradPrimary),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              auth.name.isNotEmpty ? auth.name[0].toUpperCase() : 'U',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(auth.name,
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: D.sp4),
              Text(
                '${auth.levelEmoji} ${S.get("level")} ${auth.level}'
                '  •  ⭐ ${auth.points} ball',
                style: GoogleFonts.poppins(
                    color: AppColors.sub, fontSize: 12),
              ),
            ],
          ),
        ),
        // Rank badge
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: D.sp8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.gradPrimary),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('#$r',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
          ),
          const SizedBox(height: D.sp4),
          Text(
            'Top ${(100 - (pct as num).toDouble()).toStringAsFixed(0)}%',
            style: GoogleFonts.poppins(color: AppColors.sub, fontSize: 11),
          ),
          if (tot > 0)
            Text('$tot ${S.get("students")}',
                style: GoogleFonts.poppins(
                    color: AppColors.sub, fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _LbList extends StatelessWidget {
  final List<LbEntry> entries;
  final String myId;
  const _LbList({required this.entries, required this.myId});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: D.sp12),
            Text(S.get('empty_board'),
                style: GoogleFonts.poppins(
                    color: AppColors.sub, fontSize: 16)),
            const SizedBox(height: 6),
            Text('${S.get("tasks_label")}!',
                style: GoogleFonts.poppins(
                    color: AppColors.primary, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(D.sp16, D.sp12, D.sp16, 80),
      itemCount: entries.length,
      itemBuilder: (_, i) => _LbTile(
        entry: entries[i],
        isMe: entries[i].id == myId,
      ),
    );
  }
}

class _LbTile extends StatelessWidget {
  final LbEntry entry;
  final bool isMe;
  const _LbTile({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: D.sp8),
      padding: const EdgeInsets.all(D.sp12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // Rank
        SizedBox(
          width: 42,
          child: Center(
            child: entry.rank <= 3
                ? Text(entry.rankBadge,
                    style: const TextStyle(fontSize: 22))
                : Text('#${entry.rank}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isMe ? AppColors.primary : AppColors.sub,
                    )),
          ),
        ),
        const SizedBox(width: D.sp8),
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isMe
                  ? AppColors.gradPrimary
                  : [AppColors.surface, AppColors.card],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              entry.fullName.isNotEmpty
                  ? entry.fullName[0].toUpperCase()
                  : 'U',
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : AppColors.sub,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: D.sp12),
        // Name + info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(entry.fullName,
                      style: GoogleFonts.poppins(
                        color: isMe ? AppColors.primary : AppColors.txt,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('SIZ',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ],
              ]),
              const SizedBox(height: D.sp4),
              Row(children: [
                Text(
                    '${entry.levelEmoji} ${S.get("level")} ${entry.level}',
                    style: GoogleFonts.poppins(
                        color: AppColors.sub, fontSize: 11)),
                const SizedBox(width: 10),
                Text('🔥 ${entry.streak} kun',
                    style: GoogleFonts.poppins(
                        color: AppColors.sub, fontSize: 11)),
              ]),
            ],
          ),
        ),
        // Points
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmt(entry.points),
                style: GoogleFonts.poppins(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                )),
            Text(S.get('points'),
                style: GoogleFonts.poppins(
                    color: AppColors.sub, fontSize: 11)),
          ],
        ),
      ]),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}
