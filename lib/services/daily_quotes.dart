import '../config/strings.dart';

/// Curated motivational quotes (uz + world figures).
/// Rotates by day-of-year so every user sees the same quote on a given date.
class Quote {
  final String text;
  final String author;
  const Quote(this.text, this.author);
}

class DailyQuotes {
  static List<Quote> get _quotes => [
    // ── Uzbek thinkers ───────────────────────────────
    Quote(
      S.tr(
        "Olimu komil bo'lmoq uchun dil poku ilmi komil kerak.",
        'Чтобы стать совершенным учёным, нужны чистое сердце и совершенное знание.',
        'To be a complete scholar, one needs a pure heart and complete knowledge.',
      ),
      'Alisher Navoiy',
    ),
    Quote(
      S.tr(
        "Bilmoq uchun o'qishing kerak, o'qimoq uchun bilishing kerak.",
        'Чтобы знать, нужно учиться; чтобы учиться, нужно знать.',
        'To know, you must read; to read, you must know.',
      ),
      'Abdulla Qodiriy',
    ),
    Quote(
      S.tr(
        "Ilm izlagan — aqlini boyitadi, aql — uni baxtli qiladi.",
        'Кто ищет знание — обогащает разум, а разум делает человека счастливым.',
        'Seeking knowledge enriches the mind; the mind makes one happy.',
      ),
      'Abu Rayhon Beruniy',
    ),
    Quote(
      S.tr(
        "Ilm bilan hayotni boyit, amal bilan ilmni ko'rkamlat.",
        'Обогати жизнь знанием, а знание укрась делами.',
        'Enrich life with knowledge; adorn knowledge with action.',
      ),
      "Abu Nasr Forobiy",
    ),
    Quote(
      S.tr(
        "Sabr — barcha yaxshi ishlarning kalidi.",
        'Терпение — ключ ко всем добрым делам.',
        'Patience is the key to all good deeds.',
      ),
      'Shayx Sa\'diy',
    ),
    Quote(
      S.tr(
        "Inson faqatgina o'z mehnati orqasidan mevalarga erishadi.",
        'Человек получает плоды только благодаря собственному труду.',
        'A person reaps rewards only through their own labor.',
      ),
      'Mahmud Qoshg\'ariy',
    ),
    // ── World figures ────────────────────────────────
    Quote(
      S.tr(
        "Imkonsiz so'zi — o'zingizga aytgan yolg'oningiz.",
        'Слово «невозможно» — это ложь, которую вы говорите себе.',
        '"Impossible" is a lie you tell yourself.',
      ),
      'Albert Einstein',
    ),
    Quote(
      S.tr(
        "Kichkina ishlar qiling, lekin har kuni.",
        'Делайте маленькие дела, но каждый день.',
        'Do small things, but every day.',
      ),
      'Steve Jobs',
    ),
    Quote(
      S.tr(
        "Mag'lubiyat — muvaffaqiyatdagi 1 qadam oldingi joy.",
        'Поражение — это шаг, предшествующий успеху.',
        'Defeat is one step before success.',
      ),
      'Thomas Edison',
    ),
    Quote(
      S.tr(
        "Bilim — qurol, ammo faqat foydalanilganda.",
        'Знание — оружие, но только когда применяется.',
        'Knowledge is a weapon, but only when used.',
      ),
      'Benjamin Franklin',
    ),
    Quote(
      S.tr(
        "Muvaffaqiyat — ko'p marta qulash, har safar qaytib turish.",
        'Успех — это много раз падать и каждый раз вставать.',
        'Success is falling many times and rising every time.',
      ),
      'Winston Churchill',
    ),
    Quote(
      S.tr(
        "Agar siz o'zgartirmasangiz, hech narsa o'zgarmaydi.",
        'Если вы не меняетесь — ничто не изменится.',
        'If you don\'t change, nothing changes.',
      ),
      'Tony Robbins',
    ),
    Quote(
      S.tr(
        "O'qishning eng ajoyib tomoni — bilgan kishilar buni hech qachon sizdan tortib ola olmaydilar.",
        'Лучшее в учёбе — никто не сможет отнять у вас то, что вы знаете.',
        'The best part of learning — no one can ever take it from you.',
      ),
      'B.B. King',
    ),
    Quote(
      S.tr(
        "Vaqt — eng qimmat resurs. Uni tejang.",
        'Время — самый ценный ресурс. Берегите его.',
        'Time is the most valuable resource. Save it.',
      ),
      'Peter Drucker',
    ),
    // ── Universal motivational ──────────────────────
    Quote(
      S.tr(
        "Bugun qilgan kichik harakating — ertangi katta o'zgarishni boshlaydi.",
        'Маленькое действие сегодня — начало большого изменения завтра.',
        'A small action today starts a big change tomorrow.',
      ),
      'MotivAI',
    ),
    Quote(
      S.tr(
        "Dasturchi bo'lmoq — kodlashdan ham ko'proq, fikrlash.",
        'Быть программистом — это больше думать, чем кодить.',
        'Being a programmer is more about thinking than coding.',
      ),
      'Linus Torvalds',
    ),
    Quote(
      S.tr(
        "Boshqalar hech narsa qilmaganda — siz boshlang.",
        'Когда другие ничего не делают — начинайте вы.',
        'When others do nothing — you start.',
      ),
      'Maktab hikmati',
    ),
    Quote(
      S.tr(
        "Maqsad — sababsizgina emas, sabablar bilan yuraman.",
        'Я иду к цели не просто так — я иду с причинами.',
        'I walk toward my goal — not without reasons, but with them.',
      ),
      'Mahatma Gandhi',
    ),
    Quote(
      S.tr(
        "Siz bo'lishingiz kerak bo'lgan hech kimdan kam emassiz.",
        'Вы не хуже того, кем должны стать.',
        'You are no less than who you are meant to be.',
      ),
      'Mark Twain',
    ),
    Quote(
      S.tr(
        "Katta yutuqlar — intizomdan, ilhomdan emas.",
        'Большие достижения рождаются от дисциплины, а не от вдохновения.',
        'Great achievements come from discipline, not inspiration.',
      ),
      'James Clear',
    ),
    Quote(
      S.tr(
        "O'zingga ishon. Sen o'ylagandan ko'ra kuchliroqsan.",
        'Верь в себя. Ты сильнее, чем думаешь.',
        'Believe in yourself. You are stronger than you think.',
      ),
      'A. A. Milne',
    ),
    Quote(
      S.tr(
        "Har kun — yangi imkoniyat. Tomchisidan ham qoldirma.",
        'Каждый день — новая возможность. Не упусти ни капли.',
        'Every day is a new opportunity. Don\'t miss a drop.',
      ),
      'MotivAI',
    ),
    Quote(
      S.tr(
        "Savol bermagan hech narsa bilmaydi.",
        'Кто не задаёт вопросов — ничего не знает.',
        'Whoever asks no questions, knows nothing.',
      ),
      'Xalq maqoli',
    ),
    Quote(
      S.tr(
        "Yo'lda qiynalmaslik uchun manzilga yaqinlashayotganingni his qil.",
        'Чтобы не уставать в пути — чувствуй, что приближаешься к цели.',
        'To not tire on the way — feel that you\'re nearing the destination.',
      ),
      'Rumiy',
    ),
    Quote(
      S.tr(
        "Yutuq — sen va oldingi sen o'rtasidagi farqdir.",
        'Достижение — это разница между тобой нынешним и прежним.',
        'Achievement is the difference between you and your past self.',
      ),
      'Muhammad Ali',
    ),
    Quote(
      S.tr(
        "Hayot 10% sodir bo'ladigan narsa, 90% sizning munosabatingiz.",
        'Жизнь — это 10% того, что происходит, и 90% вашего отношения.',
        'Life is 10% what happens and 90% your reaction.',
      ),
      'Charles R. Swindoll',
    ),
    Quote(
      S.tr(
        "Hech qachon kech emas — siz bo'lishingiz mumkin bo'lgan shaxs bo'lish uchun.",
        'Никогда не поздно стать тем, кем вы могли бы быть.',
        'It\'s never too late to be who you might have been.',
      ),
      'George Eliot',
    ),
    Quote(
      S.tr(
        "Bilim olingan soat — hayotda ikki marta qaytariladi.",
        'Час, потраченный на знания, возвращается в жизни вдвойне.',
        'An hour of learning is paid back twice in life.',
      ),
      'MotivAI',
    ),
    Quote(
      S.tr(
        "Ko'p o'qi, ko'p yoz, ko'p tinglang — aql shu uch narsadan o'sadi.",
        'Много читай, много пиши, много слушай — ум растёт от этих трёх.',
        'Read much, write much, listen much — the mind grows from these three.',
      ),
      'Abu Ali ibn Sino',
    ),
    Quote(
      S.tr(
        "Dunyo yoki sen — faqat birida bir xil bo'lishi mumkin.",
        'Мир или ты — лишь одно из них может остаться прежним.',
        'The world or you — only one of them can stay the same.',
      ),
      'Franz Kafka',
    ),
  ];

  /// Today's quote — stable across reloads within the same day.
  static Quote today() {
    final now = DateTime.now();
    final dayOfYear = int.parse(
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
    );
    final list = _quotes;
    return list[dayOfYear % list.length];
  }

  static Quote byIndex(int i) {
    final list = _quotes;
    return list[i.abs() % list.length];
  }

  static int get total => _quotes.length;

  /// Cycle to the next index from current.
  static int next(int current) => (current + 1) % _quotes.length;
  static int prev(int current) =>
      (current - 1 + _quotes.length) % _quotes.length;
}
