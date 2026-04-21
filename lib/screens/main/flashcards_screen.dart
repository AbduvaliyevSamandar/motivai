import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
            gradient:
                LinearGradient(colors: AppColors.gradCosmic),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded,
              color: Colors.white, size: 26),
        ),
      ),
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 18),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.txt, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          colors: AppColors.titleGradient,
                        ).createShader(b),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          'Flashcards',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withOpacity(0.25),
                  AppColors.secondary.withOpacity(0.1),
                ]),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('\u{1F4D2}', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Hali flashcards yo\'q',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.txt,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Yangi deck yarating — yodlash oson bo\'ladi',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 13,
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
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: dueCards > 0
                    ? AppColors.accent.withOpacity(0.5)
                    : AppColors.border,
                width: dueCards > 0 ? 1.5 : 1,
              ),
              boxShadow: dueCards > 0
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.18),
                        blurRadius: 14,
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
                    gradient: const LinearGradient(
                        colors: AppColors.gradCosmic),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(deck.emoji,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.txt,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.credit_card_rounded,
                              color: AppColors.sub, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$totalCards ta',
                            style: GoogleFonts.poppins(
                              color: AppColors.sub,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (dueCards > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: AppColors.gradFire),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$dueCards ta takror',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
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
    '\u{1F4D2}', '\u{1F4DA}', '\u{1F4D8}', '\u{1F1EC}\u{1F1E7}',
    '\u{1F1FA}\u{1F1FF}', '\u{1F1F7}\u{1F1FA}', '\u{1F5FA}\u{FE0F}',
    '\u{1F9EA}', '\u{1F4BB}', '\u{1F680}', '\u{1F52C}', '\u{1F3A8}',
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
            const BorderRadius.vertical(top: Radius.circular(28)),
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
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Yangi deck',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.txt,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _ctrl,
            label: 'Deck nomi',
            hint: 'Masalan: Ingliz tili so\'zlari',
            prefixIcon: Icons.edit_rounded,
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
                    gradient: sel
                        ? const LinearGradient(
                            colors: AppColors.gradCosmic)
                        : null,
                    color: sel ? null : AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? Colors.transparent
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          NebulaButton(
            label: 'Yaratish',
            icon: Icons.add_rounded,
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
        content: Text('Takrorlash uchun karta yo\'q',
            style: GoogleFonts.poppins()),
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
            gradient:
                LinearGradient(colors: AppColors.gradCosmic),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded,
              color: Colors.white, size: 26),
        ),
      ),
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.txt, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(widget.deck.emoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.deck.name,
                          style: GoogleFonts.spaceGrotesk(
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
                          ? "$due ta takrorlash"
                          : 'Barchasi ko\'rib chiqilgan',
                      icon: Icons.school_rounded,
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
                                    style: TextStyle(fontSize: 44)),
                                const SizedBox(height: 14),
                                Text(
                                  'Hali karta yo\'q',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.txt,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Old-orqa tomon bilan karta qo\'shing',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
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
                                      AppColors.card.withOpacity(0.5),
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
                                            style: GoogleFonts.poppins(
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
                                            style: GoogleFonts.poppins(
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
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${c.reviews}x',
                                          style: GoogleFonts
                                                  .spaceGrotesk(
                                              color: AppColors.info,
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w700),
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
            const BorderRadius.vertical(top: Radius.circular(28)),
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
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Yangi karta',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.txt,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _front,
            label: 'Old tomon (savol)',
            prefixIcon: Icons.help_outline_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          GlassTextField(
            controller: _back,
            label: 'Orqa tomon (javob)',
            prefixIcon: Icons.lightbulb_outline_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          NebulaButton(
            label: "Qo'shish",
            icon: Icons.add_rounded,
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
          child: Text('Karta yo\'q',
              style: GoogleFonts.poppins(color: Colors.white)),
        ),
      );
    }
    final card = _queue[_idx];

    return Scaffold(
      backgroundColor: const Color(0xFF08091A),
      body: Stack(
        children: [
          const AuroraBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        '${_idx + 1} / ${_queue.length}',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
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
                                gradient: LinearGradient(
                                  colors: isBack
                                      ? AppColors.gradAurora
                                      : AppColors.gradCosmic,
                                ),
                                borderRadius:
                                    BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 2,
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
                                        style: GoogleFonts.poppins(
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
                                            GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 22,
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
                        _rateBtn('Qaytadan', AppColors.danger, 0),
                        const SizedBox(width: 6),
                        _rateBtn('Qiyin', AppColors.accent, 1),
                        const SizedBox(width: 6),
                        _rateBtn('Yaxshi', AppColors.info, 2),
                        const SizedBox(width: 6),
                        _rateBtn('Oson', AppColors.success, 3),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                    child: Text(
                      'Javobni ko\'rish uchun kartaga bosing',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 12,
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
