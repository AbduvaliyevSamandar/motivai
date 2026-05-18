import 'package:flutter/material.dart';
import '../../config/strings.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../services/flashcards_storage.dart';
import '../../widgets/nebula/nebula.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});
  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<FlashDeck> _decks = [];
  List<Flashcard> _allCards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final decks = await FlashcardsStorage.loadDecks();
    final cards = await FlashcardsStorage.loadCards();
    if (mounted) {
      setState(() {
        _decks = decks;
        _allCards = cards;
        _loading = false;
      });
    }
  }

  Future<void> _addDeck() async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<(String, String)?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AddDeckSheet(),
    );
    if (result != null) {
      await FlashcardsStorage.addDeck(
          name: result.$1, emoji: result.$2);
      _load();
    }
  }

  Future<void> _openDeck(FlashDeck d) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeckDetailScreen(deck: d),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        onPressed: _addDeck,
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: Container(
          width: 56,
          height: 56,
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
          child: const Icon(LucideIcons.plus,
              color: Colors.white, size: 26),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.chevronLeft,
                            color: AppColors.txt, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                          'Flashcards',
                          style: TextStyle(
                            color: AppColors.txt,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : _decks.isEmpty
                          ? _empty()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 100),
                              itemCount: _decks.length,
                              itemBuilder: (_, i) {
                                final d = _decks[i];
                                final cardsInDeck = _allCards
                                    .where((c) => c.deckId == d.id)
                                    .toList();
                                final due = cardsInDeck
                                    .where((c) => c.isDue)
                                    .length;
                                return _DeckCard(
                                  deck: d,
                                  totalCards: cardsInDeck.length,
                                  dueCards: due,
                                  onTap: () => _openDeck(d),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('\u{1F4D2}', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              S.get('flashcards_empty'),
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.get('deck_yarating'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.sub,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final FlashDeck deck;
  final int totalCards;
  final int dueCards;
  final VoidCallback onTap;

  const _DeckCard({
    required this.deck,
    required this.totalCards,
    required this.dueCards,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: dueCards > 0
                    ? AppColors.accent.withOpacity(0.5)
                    : AppColors.border,
                width: dueCards > 0 ? 1.5 : 1,
              ),
              boxShadow: dueCards > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(deck.emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: TextStyle(
                          color: AppColors.txt,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.creditCard,
                              color: AppColors.sub, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$totalCards ta',
                            style: TextStyle(
                              color: AppColors.sub,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                          if (dueCards > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$dueCards ${S.get('review_count')}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight,
                    color: AppColors.sub, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ADD DECK SHEET
// ═══════════════════════════════════════════════════════════
class _AddDeckSheet extends StatefulWidget {
  const _AddDeckSheet();
  @override
  State<_AddDeckSheet> createState() => _AddDeckSheetState();
}

class _AddDeckSheetState extends State<_AddDeckSheet> {
  final _ctrl = TextEditingController();
  String _emoji = '\u{1F4D2}';
  static const _emojis = [
    '\u{1F4D2}', '', '\u{1F4D8}', '',
    '', '', '',
    '', '', '\u{1F680}', '\u{1F52C}', '\u{1F3A8}',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            S.get('deck_new'),
            style: TextStyle(
              color: AppColors.txt,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _ctrl,
            label: S.get('deck_name'),
            hint: S.tr('Masalan: Ingliz tili so\'zlari', 'Например: Английские слова', 'E.g. English words'),
            prefixIcon: LucideIcons.pencil,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis.map((e) {
              final sel = _emoji == e;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _emoji = e);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? Colors.transparent
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          NebulaButton(
            label: S.tr('Yaratish', 'Создать', 'Create'),
            icon: LucideIcons.plus,
            onTap: () {
              final t = _ctrl.text.trim();
              if (t.isEmpty) return;
              Navigator.pop<(String, String)?>(context, (t, _emoji));
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DECK DETAIL (card list + study button)
// ═══════════════════════════════════════════════════════════
class DeckDetailScreen extends StatefulWidget {
  final FlashDeck deck;
  const DeckDetailScreen({super.key, required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  List<Flashcard> _cards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await FlashcardsStorage.cardsInDeck(widget.deck.id);
    if (mounted) setState(() => _cards = c);
  }

  Future<void> _addCard() async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<(String, String)?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AddCardSheet(),
    );
    if (result != null) {
      await FlashcardsStorage.addCard(
        deckId: widget.deck.id,
        front: result.$1,
        back: result.$2,
      );
      _load();
    }
  }

  Future<void> _study() async {
    final due = await FlashcardsStorage.dueCards(widget.deck.id);
    if (due.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.get('flashcard_no_repeat'),
            style: TextStyle()),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(
          deck: widget.deck,
          initialCards: due,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final due = _cards.where((c) => c.isDue).length;
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: Container(
          width: 56,
          height: 56,
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
          child: const Icon(LucideIcons.plus,
              color: Colors.white, size: 26),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.chevronLeft,
                            color: AppColors.txt, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(widget.deck.emoji,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.deck.name,
                          style: TextStyle(
                            color: AppColors.txt,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_cards.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: NebulaButton(
                      label: due > 0
                          ? "$due ${S.get('review_count')}"
                          : S.tr('Barchasi ko\'rib chiqilgan', 'Все повторены', 'All reviewed'),
                      icon: LucideIcons.graduationCap,
                      disabled: due == 0,
                      onTap: _study,
                    ),
                  ),
                Expanded(
                  child: _cards.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('\u{1F4D6}',
                                    style: TextStyle(fontSize: 32)),
                                const SizedBox(height: 14),
                                Text(
                                  S.get('no_card_yet'),
                                  style: TextStyle(
                                    color: AppColors.txt,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  S.get('card_add_help'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.sub,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              16, 8, 16, 100),
                          itemCount: _cards.length,
                          itemBuilder: (_, i) {
                            final c = _cards[i];
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                      color: c.isDue
                                          ? AppColors.accent
                                              .withOpacity(0.4)
                                          : AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.front,
                                            style: TextStyle(
                                              color: AppColors.txt,
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            c.back,
                                            style: TextStyle(
                                              color: AppColors.sub,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (c.reviews > 0)
                                      Container(
                                        padding: const EdgeInsets
                                                .symmetric(
                                            horizontal: 6,
                                            vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.info
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${c.reviews}x',
                                          style: TextStyle(
                                              color: AppColors.info,
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Card Sheet ─────────────────────────────────
class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();
  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _front = TextEditingController();
  final _back = TextEditingController();

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            S.get('card_new'),
            style: TextStyle(
              color: AppColors.txt,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _front,
            label: S.get('card_front_q'),
            prefixIcon: LucideIcons.helpCircle,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          GlassTextField(
            controller: _back,
            label: S.get('card_back_a'),
            prefixIcon: LucideIcons.lightbulb,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          NebulaButton(
            label: S.get('add_action'),
            icon: LucideIcons.plus,
            onTap: () {
              final f = _front.text.trim();
              final b = _back.text.trim();
              if (f.isEmpty || b.isEmpty) return;
              Navigator.pop<(String, String)?>(context, (f, b));
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STUDY SCREEN (flip card + SR rating)
// ═══════════════════════════════════════════════════════════
class StudyScreen extends StatefulWidget {
  final FlashDeck deck;
  final List<Flashcard> initialCards;
  const StudyScreen({
    super.key,
    required this.deck,
    required this.initialCards,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late List<Flashcard> _queue;
  int _idx = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _queue = List.from(widget.initialCards);
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  Future<void> _rate(int quality) async {
    HapticFeedback.selectionClick();
    final card = _queue[_idx];
    card.review(quality);
    await FlashcardsStorage.updateCard(card);
    if (_idx < _queue.length - 1) {
      setState(() {
        _idx++;
        _revealed = false;
        _flipCtrl.reset();
      });
    } else {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF08091A),
        body: Center(
          child: Text(S.get('flashcard_no_card'),
              style: TextStyle(color: Colors.white)),
        ),
      );
    }
    final card = _queue[_idx];

    return Scaffold(
      backgroundColor: const Color(0xFF08091A),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.x,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        '${_idx + 1} / ${_queue.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _revealed = !_revealed);
                      if (_revealed) {
                        _flipCtrl.forward();
                      } else {
                        _flipCtrl.reverse();
                      }
                    },
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _flipCtrl,
                        builder: (_, __) {
                          final angle =
                              _flipCtrl.value * 3.14159;
                          final isBack = _flipCtrl.value > 0.5;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 32),
                              padding: const EdgeInsets.all(28),
                              constraints: const BoxConstraints(
                                  minHeight: 280),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: isBack
                                    ? (Matrix4.identity()
                                      ..rotateY(3.14159))
                                    : Matrix4.identity(),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isBack ? 'JAVOB' : 'SAVOL',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withOpacity(0.6),
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.w700,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        isBack
                                            ? card.back
                                            : card.front,
                                        textAlign: TextAlign.center,
                                        style:
                                            TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (_revealed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        _rateBtn(S.tr('Qaytadan', 'Снова', 'Again'), AppColors.danger, 0),
                        const SizedBox(width: 6),
                        _rateBtn(S.get('hard'), AppColors.accent, 1),
                        const SizedBox(width: 6),
                        _rateBtn(S.tr('Yaxshi', 'Хорошо', 'Good'), AppColors.info, 2),
                        const SizedBox(width: 6),
                        _rateBtn(S.get('easy'), AppColors.success, 3),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                    child: Text(
                      S.get('flashcard_tap_for_back'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateBtn(String label, Color color, int quality) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _rate(quality),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
