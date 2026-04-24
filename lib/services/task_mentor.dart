/// Rule-based mentor: produces a step-by-step action plan for any task
/// without needing a remote AI call. The server AI endpoint is unreliable
/// (quota / cold start), so we keep this fully offline and fast.
class TaskMentor {
  static MentorPlan plan({
    required String title,
    String description = '',
    String category = 'general',
    int durationMin = 30,
  }) {
    final t = title.toLowerCase();
    final d = description.toLowerCase();
    final combined = '$t $d';

    final bank = _templates;
    // Pick the most specific bucket by keyword match.
    String picked = 'general';
    int bestScore = 0;
    for (final entry in bank.entries) {
      final keys = entry.value.keywords;
      var score = 0;
      for (final k in keys) {
        if (combined.contains(k)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        picked = entry.key;
      }
    }
    // Category always contributes
    if (bank.containsKey(category)) picked = category;

    final bucket = bank[picked]!;
    // Scale step durations to fit the target
    final steps = bucket.steps;
    final totalBase = steps.fold<int>(0, (a, b) => a + b.minutes);
    final scale = totalBase == 0 ? 1.0 : durationMin / totalBase;
    final scaled = steps
        .map((s) => MentorStep(
              title: s.title,
              tip: s.tip,
              minutes: (s.minutes * scale).clamp(1, 120).round(),
            ))
        .toList();

    return MentorPlan(
      title: bucket.title,
      tldr: bucket.tldr,
      steps: scaled,
      closing: bucket.closing,
    );
  }

  static final _templates = <String, _Bucket>{
    'study': _Bucket(
      title: 'O\'qish / mashg\'ulot',
      tldr: 'Active recall + spaced practice ishlaydi. Faqat o\'qish kam.',
      keywords: ['o\'qish', 'kitob', 'konspekt', 'study', 'read'],
      steps: [
        _BStep('Maqsadni aniqlash',
            '1 jumlada: bu mashg\'ulotdan nima eslab qolishingiz kerak?', 3),
        _BStep('Skim + tayyor savollar',
            'Sarlavhalar + tasvirlar bo\'yicha o\'tib, 3 ta savol yozing.', 5),
        _BStep('Chuqur o\'qish',
            'Har savolga javob toping — telefonsiz, qalam+daftar.', 15),
        _BStep('Active recall',
            'Kitobni yopib, konspekt yozing — faqat xotiradan.', 5),
        _BStep('Qayta tekshirish',
            'Bo\'sh joylarni o\'qib to\'ldiring.', 2),
      ],
      closing: 'Ertaga shu mavzuni 5 daqiqada qayta eslashga urinib ko\'ring.',
    ),
    'code': _Bucket(
      title: 'Kod / dasturlash',
      tldr: 'Kichik bosqichlarga bo\'ling + har qadamda test qiling.',
      keywords: ['kod', 'code', 'function', 'bug', 'debug', 'api', 'flutter'],
      steps: [
        _BStep('Muammoni aniqlash',
            'Input / output nima bo\'lishi kerak? Misol yozing.', 3),
        _BStep('Pseudo-kod',
            'Avval inglizcha / o\'zbekcha so\'zlar bilan algoritm tuzing.', 5),
        _BStep('Eng kichik ishlovchi versiya',
            'Test kirit + konsolga chiqar. Hech narsa qo\'shmasdan.', 10),
        _BStep('Bitta yangi funksiya',
            '1 ta kichik xususiyat qo\'shing. Ishlashini tekshiring.', 8),
        _BStep('Refactor + commit',
            'Takrorlanadigan kodni ajratib, git commit qiling.', 4),
      ],
      closing: 'Tugamagan bo\'lsa — "keyingi qadam" ni yozib qo\'ying.',
    ),
    'language': _Bucket(
      title: 'Til o\'rganish',
      tldr: 'Ko\'p kirim (input) > ko\'p qoida. Nutqqa vaqt bering.',
      keywords: ['english', 'ingliz', 'rus', 'so\'z', 'word', 'grammar', 'til'],
      steps: [
        _BStep('10 yangi so\'z',
            'Kontekst bilan: har birini misolli gapda.', 6),
        _BStep('Tinglash',
            'Podcast / YouTube (subtitrsiz) 1 urug\' material.', 8),
        _BStep('Talaffuz',
            '3-5 gapni ovoz yozib, qayta tinglang.', 5),
        _BStep('Yozma mashq',
            '5 ta gap yoki qisqa matn yozing.', 8),
        _BStep('Flashcards',
            'Bugungi so\'zlarni Flashcards\'ga qo\'shing.', 3),
      ],
      closing: 'Kuniga 20 min > haftada 3 soat. Consistent bo\'ling.',
    ),
    'exercise': _Bucket(
      title: 'Sport / mashq',
      tldr: 'Isinish → asosiy → cho\'zilish. Formasi to\'g\'ri bo\'lsin.',
      keywords: ['sport', 'yugur', 'push', 'exercise', 'mashq', 'gym'],
      steps: [
        _BStep('Isinish',
            '5-7 daqiqa: bo\'yin → yelka → tana → oyoq.', 6),
        _BStep('Asosiy set 1',
            'Og\'ir vazn / tez emas — to\'g\'ri formada.', 10),
        _BStep('Asosiy set 2',
            '1-setdan 20% ko\'proq harakat / takror.', 10),
        _BStep('Kardio',
            '5-10 daqiqa yurish yoki sekin yugurish.', 8),
        _BStep('Cho\'zilish',
            'Ishlatilgan mushaklarni 20-30s ushlab cho\'zing.', 4),
      ],
      closing: '24-48 soat dam bering, suv + oqsil.',
    ),
    'creative': _Bucket(
      title: 'Ijodiy ish',
      tldr: 'Avval yomon yozing / chizing — keyin polish.',
      keywords: ['yoz', 'ijod', 'rasm', 'design', 'draft', 'hikoya'],
      steps: [
        _BStep('Ilhom va cheklov',
            'Mavzu + vaqt cheki. "Kichik" bo\'lsin — 1 sahifa, 1 rasm.',
            3),
        _BStep('Draft (yomon bo\'lsa ham)',
            'O\'zingizni tanqid qilmang — to\'xtovsiz yozing/chizing.', 15),
        _BStep('Kritik ko\'z',
            '5 daqiqa dam oling → qayta o\'qing/qarang.', 3),
        _BStep('2-versiya',
            'Eng yaxshi qismlarni qoldirib, boshqasini almashtiring.', 8),
        _BStep('Share / saqlash',
            '1 ta odamga ko\'rsating yoki arxivga qo\'shing.', 1),
      ],
      closing: '"Published" > "Perfect". Ertaga yangisini boshlang.',
    ),
    'meditation': _Bucket(
      title: 'Meditatsiya / dam',
      tldr: 'Asosiy maqsad — hozirgi daqiqada bo\'lish, natija emas.',
      keywords: ['med', 'yoga', 'breath', 'nafas', 'dam', 'rest'],
      steps: [
        _BStep('Joyni tayyorlash',
            'Jim joy, telefon jim rejimga.', 2),
        _BStep('Nafas sanash',
            'Nafas olish + chiqarish = 1. 10 gacha sanang.', 8),
        _BStep('Body scan',
            'Boshdan oyoqgacha har a\'zoni sezing (tahlilsiz).', 10),
        _BStep('Minnatdorchilik',
            '3 ta narsa uchun minnatdor bo\'ling.', 3),
        _BStep('Sekin qaytish',
            'Ko\'z ochib, 3 nafas. Hech narsani tez qilmang.', 2),
      ],
      closing: 'Bugungi hissiyotingizni 1 jumlada yozib qo\'ying.',
    ),
    'general': _Bucket(
      title: 'Umumiy vazifa',
      tldr: 'Eng qiyin qismdan boshlang. Telefon boshqa xonada.',
      keywords: [],
      steps: [
        _BStep('1 daqiqada aniqlik',
            'Vazifa aynan nimadan iborat? 1 jumlada yozing.', 1),
        _BStep('Qurol va muhit',
            'Kerak narsalarni stolga qo\'ying, bildirishnomalarni o\'chiring.',
            3),
        _BStep('Birinchi 5 daqiqa',
            'Eng osonidan emas — eng qiyin qismidan boshlang.', 6),
        _BStep('Chuqur ishlash',
            'Fokus — bitta ish. Messenjerlar yo\'q.', 15),
        _BStep('Yakunlash',
            'Qayta ko\'rish + natijani fayl/daftarga qayd.', 5),
      ],
      closing: 'Ertaga nimadan boshlash kerakligini hozir yozib qo\'ying.',
    ),
  };
}

class MentorPlan {
  final String title;
  final String tldr;
  final List<MentorStep> steps;
  final String closing;
  MentorPlan({
    required this.title,
    required this.tldr,
    required this.steps,
    required this.closing,
  });

  int get totalMinutes => steps.fold(0, (a, b) => a + b.minutes);
}

class MentorStep {
  final String title;
  final String tip;
  final int minutes;
  MentorStep({required this.title, required this.tip, required this.minutes});
}

class _Bucket {
  final String title;
  final String tldr;
  final List<String> keywords;
  final List<_BStep> steps;
  final String closing;
  _Bucket({
    required this.title,
    required this.tldr,
    required this.keywords,
    required this.steps,
    required this.closing,
  });
}

class _BStep {
  final String title;
  final String tip;
  final int minutes;
  _BStep(this.title, this.tip, this.minutes);
}
