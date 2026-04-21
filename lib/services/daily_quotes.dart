/// Curated motivational quotes (uz + world figures).
/// Rotates by day-of-year so every user sees the same quote on a given date.
class Quote {
  final String text;
  final String author;
  const Quote(this.text, this.author);
}

class DailyQuotes {
  static const _quotes = <Quote>[
    // ── Uzbek thinkers ───────────────────────────────
    Quote(
      "Olimu komil bo'lmoq uchun dil poku ilmi komil kerak.",
      'Alisher Navoiy',
    ),
    Quote(
      "Bilmoq uchun o'qishing kerak, o'qimoq uchun bilishing kerak.",
      'Abdulla Qodiriy',
    ),
    Quote(
      "Ilm izlagan — aqlini boyitadi, aql — uni baxtli qiladi.",
      'Abu Rayhon Beruniy',
    ),
    Quote(
      "Ilm bilan hayotni boyit, amal bilan ilmni ko'rkamlat.",
      "Abu Nasr Forobiy",
    ),
    Quote(
      "Sabr — barcha yaxshi ishlarning kalidi.",
      'Shayx Sa\'diy',
    ),
    Quote(
      "Inson faqatgina o'z mehnati orqasidan mevalarga erishadi.",
      'Mahmud Qoshg\'ariy',
    ),
    // ── World figures ────────────────────────────────
    Quote(
      "Imkonsiz so'zi — o'zingizga aytgan yolg'oningiz.",
      'Albert Einstein',
    ),
    Quote(
      "Kichkina ishlar qiling, lekin har kuni.",
      'Steve Jobs',
    ),
    Quote(
      "Mag'lubiyat — muvaffaqiyatdagi 1 qadam oldingi joy.",
      'Thomas Edison',
    ),
    Quote(
      "Bilim — qurol, ammo faqat foydalanilganda.",
      'Benjamin Franklin',
    ),
    Quote(
      "Muvaffaqiyat — ko'p marta qulash, har safar qaytib turish.",
      'Winston Churchill',
    ),
    Quote(
      "Agar siz o'zgartirmasangiz, hech narsa o'zgarmaydi.",
      'Tony Robbins',
    ),
    Quote(
      "O'qishning eng ajoyib tomoni — bilgan kishilar buni hech qachon sizdan tortib ola olmaydilar.",
      'B.B. King',
    ),
    Quote(
      "Vaqt — eng qimmat resurs. Uni tejang.",
      'Peter Drucker',
    ),
    // ── Universal motivational ──────────────────────
    Quote(
      "Bugun qilgan kichik harakating — ertangi katta o'zgarishni boshlaydi.",
      'MotivAI',
    ),
    Quote(
      "Dasturchi bo'lmoq — kodlashdan ham ko'proq, fikrlash.",
      'Linus Torvalds',
    ),
    Quote(
      "Boshqalar hech narsa qilmaganda — siz boshlang.",
      'Maktab hikmati',
    ),
    Quote(
      "Maqsad — sababsizgina emas, sabablar bilan yuraman.",
      'Mahatma Gandhi',
    ),
    Quote(
      "Siz bo'lishingiz kerak bo'lgan hech kimdan kam emassiz.",
      'Mark Twain',
    ),
    Quote(
      "Katta yutuqlar — intizomdan, ilhomdan emas.",
      'James Clear',
    ),
    Quote(
      "O'zingga ishon. Sen o'ylagandan ko'ra kuchliroqsan.",
      'A. A. Milne',
    ),
    Quote(
      "Har kun — yangi imkoniyat. Tomchisidan ham qoldirma.",
      'MotivAI',
    ),
    Quote(
      "Savol bermagan hech narsa bilmaydi.",
      'Xalq maqoli',
    ),
    Quote(
      "Yo'lda qiynalmaslik uchun manzilga yaqinlashayotganingni his qil.",
      'Rumiy',
    ),
    Quote(
      "Yutuq — sen va oldingi sen o'rtasidagi farqdir.",
      'Muhammad Ali',
    ),
    Quote(
      "Hayot 10% sodir bo'ladigan narsa, 90% sizning munosabatingiz.",
      'Charles R. Swindoll',
    ),
    Quote(
      "Hech qachon kech emas — siz bo'lishingiz mumkin bo'lgan shaxs bo'lish uchun.",
      'George Eliot',
    ),
    Quote(
      "Bilim olingan soat — hayotda ikki marta qaytariladi.",
      'MotivAI',
    ),
    Quote(
      "Ko'p o'qi, ko'p yoz, ko'p tinglang — aql shu uch narsadan o'sadi.",
      'Abu Ali ibn Sino',
    ),
    Quote(
      "Dunyo yoki sen — faqat birida bir xil bo'lishi mumkin.",
      'Franz Kafka',
    ),
  ];

  /// Today's quote — stable across reloads within the same day.
  static Quote today() {
    final now = DateTime.now();
    final dayOfYear = int.parse(
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
    );
    return _quotes[dayOfYear % _quotes.length];
  }

  static Quote byIndex(int i) => _quotes[i.abs() % _quotes.length];

  static int get total => _quotes.length;

  /// Cycle to the next index from current.
  static int next(int current) => (current + 1) % _quotes.length;
  static int prev(int current) =>
      (current - 1 + _quotes.length) % _quotes.length;
}
