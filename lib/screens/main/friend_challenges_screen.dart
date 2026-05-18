import 'package:flutter/material.dart';
import '../../config/strings.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../services/friends_storage.dart';
import '../../services/friend_challenge.dart';
import '../../widgets/nebula/nebula.dart';

class FriendChallengesScreen extends StatefulWidget {
  const FriendChallengesScreen({super.key});

  @override
  State<FriendChallengesScreen> createState() =>
      _FriendChallengesScreenState();
}

class _FriendChallengesScreenState extends State<FriendChallengesScreen> {
  List<FriendChallenge> _list = [];
  List<Friend> _friends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await FriendChallenges.all();
    final fr = await FriendsStorage.all();
    if (!mounted) return;
    setState(() {
      _list = l;
      _friends = fr;
      _loading = false;
    });
  }

  void _showCreateSheet() {
    if (_friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
        content: Text(S.get('challenge_no_friend'),
            style: TextStyle()),
      ));
      return;
    }
    Friend? friend = _friends.first;
    final titleCtrl = TextEditingController(text: S.tr('7 kunlik sprint', '7-дневный спринт', '7-day sprint'));
    int goal = 3;
    int days = 7;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(
                top:
                    BorderSide(color: AppColors.glassBorder, width: 1.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    S.get('challenge_new'),
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: titleCtrl,
                    label: S.tr('Sarlavha', 'Заголовок', 'Title'),
                    prefixIcon: Iconsax.cup,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.card,
                      value: friend?.id,
                      items: _friends
                          .map((f) => DropdownMenuItem(
                                value: f.id,
                                child: Row(
                                  children: [
                                    Text(f.emoji,
                                        style: const TextStyle(
                                            fontSize: 18)),
                                    const SizedBox(width: 10),
                                    Text(f.name,
                                        style: TextStyle(
                                          color: AppColors.txt,
                                          fontSize: 13,
                                        )),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setS(() => friend = _friends
                            .firstWhere((f) => f.id == v));
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _numField(
                          label: S.get('day'),
                          value: days,
                          min: 3,
                          max: 30,
                          onChange: (v) => setS(() => days = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _numField(
                          label: S.get('goal_daily_task'),
                          value: goal,
                          min: 1,
                          max: 10,
                          onChange: (v) => setS(() => goal = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  NebulaButton(
                    label: S.get('challenge_start'),
                    icon: Iconsax.send_2,
                    onTap: () async {
                      if (friend == null) return;
                      await FriendChallenges.create(
                        friendId: friend!.id,
                        friendName: friend!.name,
                        title: titleCtrl.text.trim().isEmpty
                            ? '7 kunlik sprint'
                            : titleCtrl.text.trim(),
                        days: days,
                        goalTasksPerDay: goal,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _load();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _numField({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChange,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppColors.sub, fontSize: 11)),
                Text('$value',
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (value < max) onChange(value + 1);
                },
                child: Icon(LucideIcons.chevronUp,
                    color: AppColors.primary, size: 22),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (value > min) onChange(value - 1);
                },
                child: Icon(LucideIcons.chevronDown,
                    color: AppColors.primary, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _reportFriendScore(FriendChallenge c) {
    final ctrl = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(S.get('challenge_today_score'),
            style: TextStyle(
              color: AppColors.txt,
              fontWeight: FontWeight.w700,
            )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.get('friend_score_q').replaceAll('{name}', c.friendName),
              style: TextStyle(
                  color: AppColors.sub, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppColors.txt),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.get('cancel'),
                style: TextStyle(color: AppColors.sub)),
          ),
          ElevatedButton(
            onPressed: () async {
              final n = int.tryParse(ctrl.text) ?? 0;
              await FriendChallenges.recordFriendTask(c.id, n);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(S.get('save'),
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.txt),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(S.get('challenges'),
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              )),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: AppColors.primary),
            onPressed: _showCreateSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                    ? _empty()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                            16, 60, 16, 40),
                        children: _list.map(_challengeCard).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\u{1F3C6}', style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 14),
            Text(S.get('challenge_empty'),
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            Text(
              S.get('challenge_empty_sub'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.sub, fontSize: 12),
            ),
            const SizedBox(height: 20),
            NebulaButton(
              label: S.get('create_new'),
              icon: LucideIcons.plus,
              expand: false,
              onTap: _showCreateSheet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _challengeCard(FriendChallenge c) {
    final myPct = (c.myTotal / c.goalTotal).clamp(0.0, 1.0);
    final frPct = (c.friendTotal / c.goalTotal).clamp(0.0, 1.0);
    final winning = c.myTotal >= c.friendTotal;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                c.isActive
                    ? LucideIcons.timer
                    : LucideIcons.checkCircle2,
                color: c.isActive
                    ? AppColors.primary
                    : AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.title,
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    )),
              ),
              if (c.isActive)
                Text('${c.daysLeft} ${S.get("unit_day")}',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )
              else
                Text(winning ? 'G\'olib' : '2-o\'rin',
                    style: TextStyle(
                      color: winning
                          ? AppColors.accent
                          : AppColors.sub,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    )),
            ],
          ),
          const SizedBox(height: 4),
          Text(S.get('challenge_recap').replaceAll('{a}', '${c.goalTasksPerDay}').replaceAll('{b}', '${c.days}'),
              style: TextStyle(
                  color: AppColors.sub, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 14),
          _progressRow('Siz', c.myTotal, c.goalTotal, myPct,
              AppColors.primary, winning),
          const SizedBox(height: 8),
          _progressRow(c.friendName, c.friendTotal, c.goalTotal,
              frPct, AppColors.pink, !winning),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reportFriendScore(c),
                  icon: Icon(LucideIcons.pencil,
                      color: AppColors.accent, size: 16),
                  label: Text(S.get('challenge_friend_score'),
                      style: TextStyle(
                        color: AppColors.txt,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      )),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.accent.withOpacity(0.4)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(LucideIcons.trash2,
                    color: AppColors.danger.withOpacity(0.7)),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await FriendChallenges.remove(c.id);
                  _load();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressRow(
      String name, int value, int goal, double pct, Color color,
      bool leading) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(name,
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 11,
                fontWeight:
                    leading ? FontWeight.w700 : FontWeight.w500,
              )),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value/$goal',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
      ],
    );
  }
}
