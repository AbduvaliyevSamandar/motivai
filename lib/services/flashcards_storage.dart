import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_scope.dart';

class Flashcard {
  final String id;
  final String deckId;
  String front;
  String back;
  DateTime createdAt;
  // Spaced repetition state
  DateTime nextReview;
  int interval; // days
  double easeFactor;
  int reviews;
  int correctStreak;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    DateTime? nextReview,
    this.interval = 0,
    this.easeFactor = 2.5,
    this.reviews = 0,
    this.correctStreak = 0,
  }) : nextReview = nextReview ?? DateTime.now();

  bool get isDue => !nextReview.isAfter(DateTime.now());

  /// SM-2 inspired — quality 0..3 (0=again, 1=hard, 2=good, 3=easy)
  void review(int quality) {
    reviews++;
    if (quality < 2) {
      correctStreak = 0;
      interval = 1;
      easeFactor = (easeFactor - 0.2).clamp(1.3, 2.5);
    } else {
      correctStreak++;
      if (correctStreak == 1) {
        interval = 1;
      } else if (correctStreak == 2) {
        interval = 3;
      } else {
        interval = (interval * easeFactor).round();
      }
      if (quality == 3) easeFactor = (easeFactor + 0.15).clamp(1.3, 3.0);
    }
    nextReview = DateTime.now().add(Duration(days: interval));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'deckId': deckId,
        'front': front,
        'back': back,
        'createdAt': createdAt.toIso8601String(),
        'nextReview': nextReview.toIso8601String(),
        'interval': interval,
        'easeFactor': easeFactor,
        'reviews': reviews,
        'correctStreak': correctStreak,
      };

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
        id: j['id'] ?? '',
        deckId: j['deckId'] ?? '',
        front: j['front'] ?? '',
        back: j['back'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ??
            DateTime.now(),
        nextReview: DateTime.tryParse(j['nextReview'] ?? ''),
        interval: (j['interval'] ?? 0) as int,
        easeFactor: (j['easeFactor'] as num?)?.toDouble() ?? 2.5,
        reviews: (j['reviews'] ?? 0) as int,
        correctStreak: (j['correctStreak'] ?? 0) as int,
      );
}

class FlashDeck {
  final String id;
  String name;
  final String emoji;
  final DateTime createdAt;

  FlashDeck({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FlashDeck.fromJson(Map<String, dynamic> j) => FlashDeck(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        emoji: j['emoji'] ?? '\u{1F4D2}',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ??
            DateTime.now(),
      );
}

class FlashcardsStorage {
  static const _decksKeyBase = 'motivai_flash_decks_v1';
  static String get _decksKey => UserScope.key(_decksKeyBase);
  static const _cardsKeyBase = 'motivai_flash_cards_v1';
  static String get _cardsKey => UserScope.key(_cardsKeyBase);

  static Future<List<FlashDeck>> loadDecks() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_decksKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => FlashDeck.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Flashcard>> loadCards() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_cardsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDecks(List<FlashDeck> decks) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_decksKey,
        jsonEncode(decks.map((d) => d.toJson()).toList()));
  }

  static Future<void> saveCards(List<Flashcard> cards) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_cardsKey,
        jsonEncode(cards.map((c) => c.toJson()).toList()));
  }

  static Future<FlashDeck> addDeck(
      {required String name, String emoji = '\u{1F4D2}'}) async {
    final decks = await loadDecks();
    final d = FlashDeck(
      id: 'deck_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
    decks.add(d);
    await saveDecks(decks);
    return d;
  }

  static Future<Flashcard> addCard({
    required String deckId,
    required String front,
    required String back,
  }) async {
    final cards = await loadCards();
    final c = Flashcard(
      id: 'card_${DateTime.now().microsecondsSinceEpoch}',
      deckId: deckId,
      front: front,
      back: back,
      createdAt: DateTime.now(),
    );
    cards.add(c);
    await saveCards(cards);
    return c;
  }

  static Future<void> removeDeck(String deckId) async {
    final decks = await loadDecks();
    decks.removeWhere((d) => d.id == deckId);
    await saveDecks(decks);
    final cards = await loadCards();
    cards.removeWhere((c) => c.deckId == deckId);
    await saveCards(cards);
  }

  static Future<void> removeCard(String cardId) async {
    final cards = await loadCards();
    cards.removeWhere((c) => c.id == cardId);
    await saveCards(cards);
  }

  static Future<void> updateCard(Flashcard updated) async {
    final cards = await loadCards();
    final i = cards.indexWhere((c) => c.id == updated.id);
    if (i != -1) {
      cards[i] = updated;
      await saveCards(cards);
    }
  }

  static Future<List<Flashcard>> cardsInDeck(String deckId) async {
    final cards = await loadCards();
    return cards.where((c) => c.deckId == deckId).toList();
  }

  static Future<List<Flashcard>> dueCards(String deckId) async {
    final cards = await cardsInDeck(deckId);
    return cards.where((c) => c.isDue).toList()
      ..sort((a, b) => a.nextReview.compareTo(b.nextReview));
  }
}
