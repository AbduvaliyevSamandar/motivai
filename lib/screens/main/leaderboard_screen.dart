import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: () => tasks.refreshLeaderboard(),
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: _MyRankHeader(rank: tasks.myRank, auth: auth),
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
              ? const Center(
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
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final TabController tab;
  final VoidCallback onRefresh;

  _TabsDelegate({required this.tab, required this.onRefresh});

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: D.sp16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(D.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: tab,
                indicator: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: AppColors.gradPrimary),
                  borderRadius: BorderRadius.circular(D.radiusMd - 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(3),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
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
                  Tab(text: '\u{1F30D} ${S.get("all_time")}'),
                  Tab(text: '\u{1F4C5} ${S.get("this_week")}'),
                ],
              ),
            ),
          ),
          const SizedBox(width: D.sp8),
          Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(D.radiusMd),
            child: InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(D.radiusMd),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(D.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(Icons.refresh_rounded,
                    color: AppColors.sub, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsDelegate old) => old.tab != tab;
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

    return Container(
      margin: const EdgeInsets.all(D.sp16),
      padding:
          const EdgeInsets.fromLTRB(D.sp20, D.sp20, D.sp20, D.sp20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: D.sp16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      auth.name.isEmpty ? 'User' : auth.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${auth.levelEmoji} ${S.get("level")} ${auth.level}  \u2022  \u2B50 ${auth.points}',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                    if (tot > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Top ${(100 - pct.toDouble()).toStringAsFixed(0)}%   •   $tot ${S.get("students")}',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '#$r',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S.get('rating'),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.accent.withOpacity(0.12),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child:
                        Text('\u{1F680}', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: D.sp16),
                Text(
                  S.get('empty_board'),
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${S.get("tasks_label")}!',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
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
      padding: const EdgeInsets.fromLTRB(D.sp16, D.sp8, D.sp16, 80),
      children: [
        if (top3.isNotEmpty)
          _Podium(top: top3, myId: myId),
        const SizedBox(height: D.sp12),
        ...rest.map((e) => _LbTile(
              entry: e,
              isMe: e.id == myId,
            )),
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
    // slot layout: [2nd, 1st, 3rd]
    final second = top.length > 1 ? top[1] : null;
    final first = top[0];
    final third = top.length > 2 ? top[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: D.sp12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSlot(
              entry: second,
              rank: 2,
              height: 120,
              gradient: const [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
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
              gradient: const [Color(0xFFFFB74D), Color(0xFFE65100)],
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
                gradient: LinearGradient(colors: widget.gradient),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
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
                    style: GoogleFonts.poppins(
                      color: AppColors.txt,
                      fontSize: 20,
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
              style: GoogleFonts.poppins(
                color: widget.isMe ? AppColors.primary : AppColors.txt,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${e.points}',
              style: GoogleFonts.poppins(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.last.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '#${widget.rank}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
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
      margin: const EdgeInsets.only(bottom: D.sp8),
      padding:
          const EdgeInsets.symmetric(horizontal: D.sp12, vertical: D.sp12),
      decoration: BoxDecoration(
        gradient: isMe
            ? LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.12),
                  AppColors.secondary.withOpacity(0.06),
                ],
              )
            : null,
        color: isMe ? null : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isMe ? AppColors.primary : AppColors.sub,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isMe
                  ? AppColors.gradPrimary
                  : [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.secondary.withOpacity(0.1),
                    ],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              entry.fullName.isNotEmpty
                  ? entry.fullName[0].toUpperCase()
                  : 'U',
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: D.sp12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(
                    entry.fullName,
                    style: GoogleFonts.poppins(
                      color: isMe ? AppColors.primary : AppColors.txt,
                      fontSize: 14,
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
                      gradient: const LinearGradient(
                          colors: AppColors.gradPrimary),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SIZ',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 9,
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
                  style: GoogleFonts.poppins(
                      color: AppColors.sub, fontSize: 11),
                ),
                const SizedBox(width: 10),
                Text('\u{1F525} ${entry.streak}',
                    style: GoogleFonts.poppins(
                        color: AppColors.sub, fontSize: 11)),
              ]),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _fmt(entry.points),
              style: GoogleFonts.poppins(
                color: AppColors.accent,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              S.get('points'),
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 11,
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
