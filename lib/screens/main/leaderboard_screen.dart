import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
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
    final auth  = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final rank  = tasks.myRank;

    return Scaffold(
      backgroundColor: C.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            backgroundColor: C.surface,
            pinned: true,
            expandedHeight: 170,
            flexibleSpace: FlexibleSpaceBar(
              background: _MyRankCard(
                  rank: rank, auth: auth),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: C.primary,
              labelColor: C.primary,
              unselectedLabelColor: C.sub,
              tabs: const [
                Tab(text: '🌍 Barcha vaqt'),
                Tab(text: '📅 Bu hafta'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh,
                    color: C.sub),
                onPressed: () =>
                    tasks.refreshLeaderboard()),
            ],
          ),
        ],
        body: tasks.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: C.primary))
            : TabBarView(
                controller: _tab,
                children: [
                  _LbList(
                    entries: tasks.globalLb,
                    myId:
                        auth.user?['_id']?.toString() ??
                        auth.user?['id']?.toString() ??
                        '',
                  ),
                  _LbList(
                    entries: tasks.weeklyLb,
                    myId:
                        auth.user?['_id']?.toString() ??
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
  const _MyRankCard(
      {required this.rank, required this.auth});

  @override
  Widget build(BuildContext context) {
    final r   = rank?['rank']        ?? '—';
    final pct = rank?['percentile']  ?? 0;
    final tot = rank?['total_users'] ?? 0;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(20, 52, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [C.surface, C.bg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 54, height: 54,
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: C.gradPrimary),
            shape: BoxShape.circle),
          child: Center(
            child: Text(
              auth.name.isNotEmpty
                  ? auth.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(auth.name,
                style: const TextStyle(
                    color: C.txt,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${auth.levelEmoji} Daraja ${auth.level}'
              '  •  ⭐ ${auth.points} ball',
              style: const TextStyle(
                  color: C.sub, fontSize: 12)),
          ],
        )),
        // Rank badge
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: C.gradPrimary),
              borderRadius: BorderRadius.circular(14)),
            child: Text('#$r',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(
            'Top ${(100 - (pct as num).toDouble()).toStringAsFixed(0)}%',
            style: const TextStyle(
                color: C.sub, fontSize: 11)),
          if (tot > 0)
            Text('$tot talaba',
                style: const TextStyle(
                    color: C.sub, fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _LbList extends StatelessWidget {
  final List<LbEntry> entries;
  final String myId;
  const _LbList(
      {required this.entries, required this.myId});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🏆', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Reyting hali bo\'sh',
              style: TextStyle(color: C.sub, fontSize: 16)),
          SizedBox(height: 6),
          Text('Vazifalar bajaring va birinchi bo\'ling!',
              style: TextStyle(
                  color: C.primary, fontSize: 13)),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: entries.length,
      itemBuilder: (_, i) => _LbTile(
        entry: entries[i],
        isMe:  entries[i].id == myId,
      ),
    );
  }
}

class _LbTile extends StatelessWidget {
  final LbEntry entry;
  final bool    isMe;
  const _LbTile({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isMe ? C.primary.withOpacity(0.1) : C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? C.primary.withOpacity(0.5)
              : C.border,
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
                    style: const TextStyle(
                        fontSize: 22))
                : Text('#${entry.rank}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isMe ? C.primary : C.sub)),
          ),
        ),
        const SizedBox(width: 8),
        // Avatar
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isMe
                  ? C.gradPrimary
                  : [C.surface, C.card]),
            shape: BoxShape.circle),
          child: Center(
            child: Text(
              entry.fullName.isNotEmpty
                  ? entry.fullName[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                color: isMe ? Colors.white : C.sub,
                fontSize: 16,
                fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        // Name + info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(
                child: Text(entry.fullName,
                    style: TextStyle(
                      color: isMe ? C.primary : C.txt,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
              if (isMe) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: C.primary,
                    borderRadius:
                        BorderRadius.circular(6)),
                  child: const Text('SIZ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.bold))),
              ],
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Text('${entry.levelEmoji} Daraja ${entry.level}',
                  style: const TextStyle(
                      color: C.sub, fontSize: 11)),
              const SizedBox(width: 10),
              Text('🔥 ${entry.streak} kun',
                  style: const TextStyle(
                      color: C.sub, fontSize: 11)),
            ]),
          ],
        )),
        // Points
        Column(crossAxisAlignment: CrossAxisAlignment.end,
            children: [
          Text(_fmt(entry.points),
              style: const TextStyle(
                  color: C.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const Text('ball',
              style: TextStyle(
                  color: C.sub, fontSize: 11)),
        ]),
      ]),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}
