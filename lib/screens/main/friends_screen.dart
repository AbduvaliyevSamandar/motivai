import 'package:flutter/material.dart';
import '../../config/strings.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/friends_storage.dart';
import '../../services/coins_storage.dart';
import '../../widgets/nebula/nebula.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Friend> _friends = [];
  String _myCode = '';
  int _myCoins = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await FriendsStorage.all();
    final code = await FriendsStorage.myCode();
    final coins = await CoinsStorage.balance();
    if (!mounted) return;
    setState(() {
      _friends = list;
      _myCode = code;
      _myCoins = coins;
      _loading = false;
    });
  }

  void _showAddSheet() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String emoji = '\u{1F642}';
    final emojis = const [
      '\u{1F642}',
      '\u{1F60E}',
      '\u{1F9D1}',
      '\u{1F469}',
      '\u{1F468}',
      '\u{1F913}',
      '\u{1F92A}',
      '\u{1F47D}',
      '\u{1F431}',
      '\u{1F436}',
    ];
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
                  S.get('friend_add'),
                  style: TextStyle(
                    color: AppColors.txt,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: emojis.map((e) {
                      final active = e == emoji;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setS(() => emoji = e);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? AppColors.primary.withOpacity(0.25)
                                : AppColors.bg,
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: active ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(e,
                                style:
                                    const TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                GlassTextField(
                  controller: nameCtrl,
                  label: S.tr('Ism', 'Имя', 'Name'),
                  prefixIcon: LucideIcons.user,
                ),
                const SizedBox(height: 10),
                GlassTextField(
                  controller: codeCtrl,
                  label: S.get('invite_code_label'),
                  prefixIcon: LucideIcons.key,
                ),
                const SizedBox(height: 18),
                NebulaButton(
                  label: S.get('add_btn'),
                  icon: LucideIcons.userPlus,
                  onTap: () async {
                    final ok = await FriendsStorage.add(
                      name: nameCtrl.text,
                      code: codeCtrl.text,
                      emoji: emoji,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: ok
                            ? AppColors.success
                            : AppColors.danger,
                        content: Text(
                          ok
                              ? S.tr('Do\'st qo\'shildi', 'Друг добавлен', 'Friend added')
                              : S.tr('Xato: kod mavjud yoki o\'zingizniki', 'Ошибка: код уже есть или ваш собственный', 'Error: code exists or is your own'),
                          style: TextStyle(),
                        ),
                      ),
                    );
                    if (ok) _load();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendCoins(Friend f) {
    final ctrl = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          '${f.emoji} ${f.name} ${S.tr('ga sovg\'a', '— подарок', 'gift')}',
          style: TextStyle(
              color: AppColors.txt, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${S.tr('Balansingiz', 'Ваш баланс', 'Your balance')}: $_myCoins',
                style: TextStyle(color: AppColors.sub),
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
                suffixText: 'tanga',
                suffixStyle:
                    TextStyle(color: AppColors.sub),
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
              final amount = int.tryParse(ctrl.text) ?? 0;
              if (amount <= 0 || amount > _myCoins) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.danger,
                  content: Text(S.get('wrong_amount'),
                      style: TextStyle()),
                ));
                return;
              }
              await CoinsStorage.spend(amount);
              await FriendsStorage.sendCoins(f.id, amount);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _load();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.success,
                content: Text(
                  S.tr('${f.name} ga $amount tanga yuborildi', '${f.name} получил $amount монет', '$amount coins sent to ${f.name}'),
                  style: TextStyle(),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(S.tr('Yuborish', 'Отправить', 'Send'),
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.txt),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            S.get('friends_title'),
            style: TextStyle(
              color: AppColors.txt,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.userPlus, color: AppColors.primary),
            onPressed: _showAddSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 40),
                    children: [
                      _myCodeCard(auth.name),
                      const SizedBox(height: 16),
                      if (_friends.isEmpty)
                        _emptyState()
                      else
                        ..._friends.map(_friendTile),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _myCodeCard(String myName) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.qrCode, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(S.get('your_invite_code'),
                  style: TextStyle(
                    color: AppColors.sub,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _myCode,
                        style: TextStyle(
                          color: AppColors.txt,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(LucideIcons.copy,
                            color: AppColors.primary, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text:
                                  '${S.tr('MotivAI do\'st kodim', 'Мой код друга MotivAI', 'My MotivAI friend code')}: $_myCode'));
                          HapticFeedback.selectionClick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.success,
                              content: Text(S.get('copied'),
                                  style: TextStyle()),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            S.get('send_invite'),
            style: TextStyle(
                color: AppColors.sub, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.circleDollarSign,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text('$_myCoins ${S.get('unit_coin')}',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text('\u{1F46F}', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            S.get('friends_empty'),
            style: TextStyle(
              color: AppColors.txt,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            S.get('friends_empty_sub'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.sub, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _friendTile(Friend f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(f.emoji,
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name,
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${f.code} • ${S.tr('yuborgan', 'отправлено', 'sent')} ${f.coinsSent}',
                      style: TextStyle(
                          color: AppColors.sub, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.gift,
                color: AppColors.accent),
            onPressed: () => _sendCoins(f),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2,
                color: AppColors.danger.withOpacity(0.7)),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await FriendsStorage.remove(f.id);
              _load();
            },
          ),
        ],
      ),
    );
  }
}
