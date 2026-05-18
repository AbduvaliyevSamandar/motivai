import '../config/strings.dart';

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

  static Map<String, _Bucket> get _templates => <String, _Bucket>{
        'study': _Bucket(
          title: S.get('subject_reading'),
          tldr: S.tr(
            'Active recall + spaced practice ishlaydi. Faqat o\'qish kam.',
            'Active recall + интервальное повторение работают. Простого чтения мало.',
            'Active recall + spaced practice work. Reading alone is not enough.',
          ),
          keywords: ['o\'qish', 'kitob', 'konspekt', 'study', 'read'],
          steps: [
            _BStep(
                S.tr('Maqsadni aniqlash', 'Определите цель', 'Define the goal'),
                S.tr(
                    '1 jumlada: bu mashg\'ulotdan nima eslab qolishingiz kerak?',
                    'Одним предложением: что вы должны запомнить с этого занятия?',
                    'In one sentence: what should you remember from this session?'),
                3),
            _BStep(
                S.tr('Skim + tayyor savollar', 'Беглый просмотр + вопросы',
                    'Skim + prepared questions'),
                S.tr(
                    'Sarlavhalar + tasvirlar bo\'yicha o\'tib, 3 ta savol yozing.',
                    'Пройдитесь по заголовкам и иллюстрациям, запишите 3 вопроса.',
                    'Skim the headings and visuals, then write 3 questions.'),
                5),
            _BStep(
                S.tr('Chuqur o\'qish', 'Глубокое чтение', 'Deep reading'),
                S.tr(
                    'Har savolga javob toping — telefonsiz, qalam+daftar.',
                    'Найдите ответ на каждый вопрос — без телефона, с ручкой и тетрадью.',
                    'Find an answer to each question — no phone, pen and paper.'),
                15),
            _BStep(
                S.tr('Active recall', 'Активное вспоминание', 'Active recall'),
                S.tr(
                    'Kitobni yopib, konspekt yozing — faqat xotiradan.',
                    'Закройте книгу и запишите конспект — только по памяти.',
                    'Close the book and write notes — purely from memory.'),
                5),
            _BStep(
                S.tr('Qayta tekshirish', 'Перепроверка', 'Re-check'),
                S.tr(
                    'Bo\'sh joylarni o\'qib to\'ldiring.',
                    'Перечитайте и заполните пробелы.',
                    'Re-read and fill in the blanks.'),
                2),
          ],
          closing: S.tr(
            'Ertaga shu mavzuni 5 daqiqada qayta eslashga urinib ko\'ring.',
            'Завтра попробуйте за 5 минут вспомнить эту тему ещё раз.',
            'Tomorrow, try to recall this topic again in 5 minutes.',
          ),
        ),
        'code': _Bucket(
          title: S.get('subject_coding'),
          tldr: S.tr(
            'Kichik bosqichlarga bo\'ling + har qadamda test qiling.',
            'Разбейте на маленькие шаги + тестируйте каждый шаг.',
            'Break it into small steps + test at every step.',
          ),
          keywords: ['kod', 'code', 'function', 'bug', 'debug', 'api', 'flutter'],
          steps: [
            _BStep(
                S.tr('Muammoni aniqlash', 'Определите задачу',
                    'Define the problem'),
                S.tr(
                    'Input / output nima bo\'lishi kerak? Misol yozing.',
                    'Каким должен быть вход и выход? Запишите пример.',
                    'What should the input/output be? Write an example.'),
                3),
            _BStep(
                S.tr('Pseudo-kod', 'Псевдокод', 'Pseudo-code'),
                S.tr(
                    'Avval inglizcha / o\'zbekcha so\'zlar bilan algoritm tuzing.',
                    'Сначала составьте алгоритм словами на русском или английском.',
                    'First write the algorithm in plain English words.'),
                5),
            _BStep(
                S.tr('Eng kichik ishlovchi versiya', 'Минимальная рабочая версия',
                    'Smallest working version'),
                S.tr(
                    'Test kirit + konsolga chiqar. Hech narsa qo\'shmasdan.',
                    'Подайте вход и выведите в консоль. Без лишнего.',
                    'Feed input + print to console. Nothing extra.'),
                10),
            _BStep(
                S.tr('Bitta yangi funksiya', 'Одна новая функция',
                    'One new feature'),
                S.tr(
                    '1 ta kichik xususiyat qo\'shing. Ishlashini tekshiring.',
                    'Добавьте 1 маленькую функцию. Проверьте, что работает.',
                    'Add 1 small feature. Verify it works.'),
                8),
            _BStep(
                S.tr('Refactor + commit', 'Рефакторинг + commit',
                    'Refactor + commit'),
                S.tr(
                    'Takrorlanadigan kodni ajratib, git commit qiling.',
                    'Вынесите повторяющийся код и сделайте git commit.',
                    'Extract repeating code and make a git commit.'),
                4),
          ],
          closing: S.tr(
            'Tugamagan bo\'lsa — "keyingi qadam" ni yozib qo\'ying.',
            'Если не закончили — запишите "следующий шаг".',
            'If not finished — write down the "next step".',
          ),
        ),
        'language': _Bucket(
          title: S.get('subject_language'),
          tldr: S.tr(
            'Ko\'p kirim (input) > ko\'p qoida. Nutqqa vaqt bering.',
            'Много input важнее многих правил. Уделяйте время речи.',
            'Lots of input > lots of rules. Give time to speaking.',
          ),
          keywords: ['english', 'ingliz', 'rus', 'so\'z', 'word', 'grammar', 'til'],
          steps: [
            _BStep(
                S.tr('10 yangi so\'z', '10 новых слов', '10 new words'),
                S.tr(
                    'Kontekst bilan: har birini misolli gapda.',
                    'С контекстом: каждое в примерном предложении.',
                    'With context: each in an example sentence.'),
                6),
            _BStep(
                S.tr('Tinglash', 'Аудирование', 'Listening'),
                S.tr(
                    'Podcast / YouTube (subtitrsiz) 1 urug\' material.',
                    'Подкаст / YouTube (без субтитров) — короткий материал.',
                    'Podcast / YouTube (no subtitles) — a short clip.'),
                8),
            _BStep(
                S.tr('Talaffuz', 'Произношение', 'Pronunciation'),
                S.tr(
                    '3-5 gapni ovoz yozib, qayta tinglang.',
                    'Запишите 3–5 фраз и переслушайте.',
                    'Record 3–5 sentences and listen back.'),
                5),
            _BStep(
                S.tr('Yozma mashq', 'Письменная практика', 'Writing practice'),
                S.tr(
                    '5 ta gap yoki qisqa matn yozing.',
                    'Напишите 5 предложений или короткий текст.',
                    'Write 5 sentences or a short text.'),
                8),
            _BStep(
                S.tr('Flashcards', 'Карточки', 'Flashcards'),
                S.tr(
                    'Bugungi so\'zlarni Flashcards\'ga qo\'shing.',
                    'Добавьте сегодняшние слова во Flashcards.',
                    'Add today\'s words to Flashcards.'),
                3),
          ],
          closing: S.tr(
            'Kuniga 20 min > haftada 3 soat. Consistent bo\'ling.',
            '20 минут в день лучше 3 часов в неделю. Будьте последовательны.',
            '20 min a day beats 3 hours a week. Be consistent.',
          ),
        ),
        'exercise': _Bucket(
          title: S.get('subject_sport'),
          tldr: S.tr(
            'Isinish → asosiy → cho\'zilish. Formasi to\'g\'ri bo\'lsin.',
            'Разминка → основное → растяжка. Следите за техникой.',
            'Warm-up → main set → stretch. Keep the form right.',
          ),
          keywords: ['sport', 'yugur', 'push', 'exercise', 'mashq', 'gym'],
          steps: [
            _BStep(
                S.tr('Isinish', 'Разминка', 'Warm-up'),
                S.tr(
                    '5-7 daqiqa: bo\'yin → yelka → tana → oyoq.',
                    '5–7 минут: шея → плечи → корпус → ноги.',
                    '5–7 minutes: neck → shoulders → torso → legs.'),
                6),
            _BStep(
                S.tr('Asosiy set 1', 'Основной сет 1', 'Main set 1'),
                S.tr(
                    'Og\'ir vazn / tez emas — to\'g\'ri formada.',
                    'Не тяжёлый вес и не быстро — главное техника.',
                    'Not heavy / not fast — focus on correct form.'),
                10),
            _BStep(
                S.tr('Asosiy set 2', 'Основной сет 2', 'Main set 2'),
                S.tr(
                    '1-setdan 20% ko\'proq harakat / takror.',
                    'На 20% больше движений / повторов, чем в 1-м сете.',
                    '20% more movement / reps than set 1.'),
                10),
            _BStep(
                S.tr('Kardio', 'Кардио', 'Cardio'),
                S.tr(
                    '5-10 daqiqa yurish yoki sekin yugurish.',
                    '5–10 минут ходьбы или лёгкого бега.',
                    '5–10 minutes of walking or easy jogging.'),
                8),
            _BStep(
                S.tr('Cho\'zilish', 'Растяжка', 'Stretching'),
                S.tr(
                    'Ishlatilgan mushaklarni 20-30s ushlab cho\'zing.',
                    'Растягивайте задействованные мышцы по 20–30 с.',
                    'Hold a stretch for 20–30s on the muscles you used.'),
                4),
          ],
          closing: S.tr(
            '24-48 soat dam bering, suv + oqsil.',
            'Дайте отдых 24–48 часов, вода + белок.',
            'Rest 24–48 hours, water + protein.',
          ),
        ),
        'creative': _Bucket(
          title: S.get('subject_creative'),
          tldr: S.tr(
            'Avval yomon yozing / chizing — keyin polish.',
            'Сначала пишите/рисуйте плохо — потом доводите.',
            'Write / draw badly first — polish afterwards.',
          ),
          keywords: ['yoz', 'ijod', 'rasm', 'design', 'draft', 'hikoya'],
          steps: [
            _BStep(
                S.tr('Ilhom va cheklov', 'Идея и рамки',
                    'Inspiration and constraint'),
                S.tr(
                    'Mavzu + vaqt cheki. "Kichik" bo\'lsin — 1 sahifa, 1 rasm.',
                    'Тема + лимит времени. Пусть будет "малое" — 1 страница, 1 рисунок.',
                    'Topic + time limit. Keep it "small" — 1 page, 1 drawing.'),
                3),
            _BStep(
                S.tr('Draft (yomon bo\'lsa ham)', 'Черновик (даже если плохой)',
                    'Draft (even if it\'s bad)'),
                S.tr(
                    'O\'zingizni tanqid qilmang — to\'xtovsiz yozing/chizing.',
                    'Не критикуйте себя — пишите/рисуйте без остановки.',
                    'Don\'t criticise yourself — write/draw without stopping.'),
                15),
            _BStep(
                S.tr('Kritik ko\'z', 'Критический взгляд', 'Critical eye'),
                S.tr(
                    '5 daqiqa dam oling → qayta o\'qing/qarang.',
                    'Отдохните 5 минут → перечитайте/пересмотрите.',
                    'Take a 5-minute break → re-read / re-look.'),
                3),
            _BStep(
                S.tr('2-versiya', '2-я версия', 'Version 2'),
                S.tr(
                    'Eng yaxshi qismlarni qoldirib, boshqasini almashtiring.',
                    'Оставьте лучшие части, остальное переделайте.',
                    'Keep the best parts, replace the rest.'),
                8),
            _BStep(
                S.tr('Share / saqlash', 'Поделиться / сохранить',
                    'Share / save'),
                S.tr(
                    '1 ta odamga ko\'rsating yoki arxivga qo\'shing.',
                    'Покажите кому-то одному или сохраните в архив.',
                    'Show it to one person or save it to your archive.'),
                1),
          ],
          closing: S.tr(
            '"Published" > "Perfect". Ertaga yangisini boshlang.',
            '"Published" > "Perfect". Завтра начните новое.',
            '"Published" > "Perfect". Start a new one tomorrow.',
          ),
        ),
        'meditation': _Bucket(
          title: S.get('subject_meditation'),
          tldr: S.tr(
            'Asosiy maqsad — hozirgi daqiqada bo\'lish, natija emas.',
            'Главная цель — быть в настоящем моменте, а не результат.',
            'The main goal is being in the present moment, not a result.',
          ),
          keywords: ['med', 'yoga', 'breath', 'nafas', 'dam', 'rest'],
          steps: [
            _BStep(
                S.tr('Joyni tayyorlash', 'Подготовьте место',
                    'Prepare the space'),
                S.tr(
                    'Jim joy, telefon jim rejimga.',
                    'Тихое место, телефон в беззвучный режим.',
                    'A quiet spot, phone on silent.'),
                2),
            _BStep(
                S.tr('Nafas sanash', 'Счёт дыханий', 'Breath counting'),
                S.tr(
                    'Nafas olish + chiqarish = 1. 10 gacha sanang.',
                    'Вдох + выдох = 1. Считайте до 10.',
                    'Inhale + exhale = 1. Count up to 10.'),
                8),
            _BStep(
                S.tr('Body scan', 'Сканирование тела', 'Body scan'),
                S.tr(
                    'Boshdan oyoqgacha har a\'zoni sezing (tahlilsiz).',
                    'От головы до ног прочувствуйте каждую часть (без анализа).',
                    'From head to toe, feel each part (without analysing).'),
                10),
            _BStep(
                S.tr('Minnatdorchilik', 'Благодарность', 'Gratitude'),
                S.tr(
                    '3 ta narsa uchun minnatdor bo\'ling.',
                    'Поблагодарите за 3 вещи.',
                    'Be thankful for 3 things.'),
                3),
            _BStep(
                S.tr('Sekin qaytish', 'Медленное возвращение',
                    'Slow return'),
                S.tr(
                    'Ko\'z ochib, 3 nafas. Hech narsani tez qilmang.',
                    'Откройте глаза, 3 вдоха. Ничего не делайте быстро.',
                    'Open your eyes, take 3 breaths. Don\'t rush anything.'),
                2),
          ],
          closing: S.tr(
            'Bugungi hissiyotingizni 1 jumlada yozib qo\'ying.',
            'Запишите сегодняшние ощущения одним предложением.',
            'Write today\'s feelings down in one sentence.',
          ),
        ),
        'general': _Bucket(
          title: S.get('general_task'),
          tldr: S.tr(
            'Eng qiyin qismdan boshlang. Telefon boshqa xonada.',
            'Начинайте с самого сложного. Телефон — в другой комнате.',
            'Start with the hardest part. Phone in another room.',
          ),
          keywords: [],
          steps: [
            _BStep(
                S.tr('1 daqiqada aniqlik', 'Минута на ясность',
                    '1 minute of clarity'),
                S.tr(
                    'Vazifa aynan nimadan iborat? 1 jumlada yozing.',
                    'В чём именно состоит задача? Запишите одним предложением.',
                    'What exactly is the task? Write it in one sentence.'),
                1),
            _BStep(
                S.tr('Qurol va muhit', 'Инструменты и среда',
                    'Tools and environment'),
                S.tr(
                    'Kerak narsalarni stolga qo\'ying, bildirishnomalarni o\'chiring.',
                    'Положите нужное на стол, выключите уведомления.',
                    'Put what you need on the desk, turn off notifications.'),
                3),
            _BStep(
                S.tr('Birinchi 5 daqiqa', 'Первые 5 минут', 'First 5 minutes'),
                S.tr(
                    'Eng osonidan emas — eng qiyin qismidan boshlang.',
                    'Не с самого простого — начните с самого сложного.',
                    'Not the easiest — start with the hardest part.'),
                6),
            _BStep(
                S.tr('Chuqur ishlash', 'Глубокая работа', 'Deep work'),
                S.tr(
                    'Fokus — bitta ish. Messenjerlar yo\'q.',
                    'Фокус — одно дело. Никаких мессенджеров.',
                    'Focus — one task. No messengers.'),
                15),
            _BStep(
                S.tr('Yakunlash', 'Завершение', 'Wrap-up'),
                S.tr(
                    'Qayta ko\'rish + natijani fayl/daftarga qayd.',
                    'Просмотр + запись результата в файл или тетрадь.',
                    'Review + record the result in a file or notebook.'),
                5),
          ],
          closing: S.tr(
            'Ertaga nimadan boshlash kerakligini hozir yozib qo\'ying.',
            'Запишите прямо сейчас, с чего начнёте завтра.',
            'Write down right now what you\'ll start with tomorrow.',
          ),
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
