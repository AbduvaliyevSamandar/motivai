import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/strings.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../widgets/nebula/nebula.dart';

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
    _tab.addListener(() {
      if (_tab.indexIsChanging) HapticFeedback.selectionClick();
    });
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: () => tasks.refreshLeaderboard(),
            child: NestedScrollView(
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: _MyRankHeader(
                        rank: tasks.myRank, auth: auth),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabsDelegate(
                    tab: _tab,
                    onRefresh: () {
                      HapticFeedback.lightImpact();
                      tasks.refreshLeaderboard();
                    },
                  ),
                ),
              ],
              body: tasks.isLoading && tasks.globalLb.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _LbTab(
                          entries: tasks.globalLb,
                          myId: auth.user?['_id']?.toString() ??
                              auth.user?['id']?.toString() ??
                              '',
                        ),
                        _LbTab(
                          entries: tasks.weeklyLb,
                          myId: auth.user?['_id']?.toString() ??
                              auth.user?['id']?.toString() ??
                              '',
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

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final TabController tab;
  final VoidCallback onRefresh;
  _TabsDelegate({required this.tab, required this.onRefresh});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bg.withOpacity(0.85),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(3),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.sub,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: '${S.get("all_time")}'),
                  Tab(text: '${S.get("this_week")}'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(LucideIcons.refreshCw,
                    color: AppColors.sub, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  // Always rebuild — tab labels read S.get(...) which depends on the
  // active language. Returning false here freezes the labels on whatever
  // lang was active at first render.
  bool shouldRebuild(covariant _TabsDelegate old) => true;
}

class _MyRankHeader extends StatelessWidget {
  final Map<String, dynamic>? rank;
  final AuthProvider auth;
  const _MyRankHeader({required this.rank, required this.auth});

  @override
  Widget build(BuildContext context) {
    final r = rank?['rank'] ?? '—';
    final pct = (rank?['percentile'] ?? 0) as num;
    final tot = rank?['total_users'] ?? 0;
    final initials = auth.name.isEmpty
        ? 'U'
        : auth.name.trim().split(RegExp(r'\s+')).take(2).map((s) => s[0]).join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.name.isEmpty ? 'User' : auth.name,
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${auth.levelEmoji} Lvl ${auth.level}  \u2022  \u2B50 ${auth.points}',
                    style: TextStyle(
                      color: AppColors.sub,
                      fontSize: 11,
                    ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                  if (tot > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Top ${(100 - pct.toDouble()).toStringAsFixed(0)}% \u2022 $tot ${S.get("students")}',
                      style: TextStyle(
                        color: AppColors.hint,
                        fontSize: 11,
                      ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Text(
                    '#$r',
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1,
                    ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                const SizedBox(height: 2),
                Text(
                  S.get('rating').toUpperCase(),
                  style: TextStyle(
                    color: AppColors.sub,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LbTab extends StatelessWidget {
  final List<LbEntry> entries;
  final String myId;
  const _LbTab({required this.entries, required this.myId});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child:
                        Text('\u{1F680}', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  S.get('empty_board'),
                  style: TextStyle(
                    color: AppColors.txt,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${S.get("tasks_label")}!',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
              ],
            ),
          ),
        ],
      );
    }

    final top3 = entries.take(3).toList();
    final rest = entries.length > 3 ? entries.sublist(3) : <LbEntry>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (top3.isNotEmpty) _Podium(top: top3, myId: myId),
        const SizedBox(height: 12),
        ...rest.map(
            (e) => _LbTile(entry: e, isMe: e.id == myId)),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LbEntry> top;
  final String myId;
  const _Podium({required this.top, required this.myId});

  @override
  Widget build(BuildContext context) {
    final second = top.length > 1 ? top[1] : null;
    final first = top[0];
    final third = top.length > 2 ? top[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSlot(
              entry: second,
              rank: 2,
              height: 120,
              gradient: const [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
              isMe: second?.id == myId,
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              entry: first,
              rank: 1,
              height: 160,
              gradient: AppColors.gradGold,
              isMe: first.id == myId,
              crown: true,
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              entry: third,
              rank: 3,
              height: 100,
              gradient: const [Color(0xFFFCA589), Color(0xFFC04A14)],
              isMe: third?.id == myId,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatefulWidget {
  final LbEntry? entry;
  final int rank;
  final double height;
  final List<Color> gradient;
  final bool isMe;
  final bool crown;

  const _PodiumSlot({
    required this.entry,
    required this.rank,
    required this.height,
    required this.gradient,
    required this.isMe,
    this.crown = false,
  });

  @override
  State<_PodiumSlot> createState() => _PodiumSlotState();
}

class _PodiumSlotState extends State<_PodiumSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    Future.delayed(Duration(milliseconds: 120 * widget.rank), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entry == null) {
      return SizedBox(height: widget.height);
    }
    final e = widget.entry!;
    final initials = e.fullName.isEmpty ? 'U' : e.fullName[0].toUpperCase();
    final scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);

    return ScaleTransition(
      scale: scale,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.crown)
              const Text('\u{1F451}', style: TextStyle(fontSize: 24)),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.gradient.first,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              e.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.isMe
                    ? AppColors.primary
                    : AppColors.txt,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${e.points}',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.gradient.first,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '#${widget.rank}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.18) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(children: [
        SizedBox(
          width: 36,
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isMe ? AppColors.primary : AppColors.sub,
                letterSpacing: -0.3,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : AppColors.primary.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              entry.fullName.isNotEmpty
                  ? entry.fullName[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.primary,
                fontSize: 18,
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
              Row(children: [
                Flexible(
                  child: Text(
                    entry.fullName,
                    style: TextStyle(
                      color: isMe ? AppColors.primary : AppColors.txt,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      S.tr('SIZ', 'ВЫ', 'YOU'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Text(
                  '${entry.levelEmoji} Lvl ${entry.level}',
                  style: TextStyle(
                      color: AppColors.sub, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                const SizedBox(width: 10),
                Text('${entry.streak}',
                    style: TextStyle(
                        color: AppColors.sub, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
              ]),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
                _fmt(entry.points),
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            Text(
              'XP',
              style: TextStyle(
                color: AppColors.sub,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ]),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}
