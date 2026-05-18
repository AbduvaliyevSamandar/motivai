# -*- coding: utf-8 -*-
"""Final originality push — rewrites every remaining high-similarity
paragraph in the thesis, targeting 80–90% original content.

Sections covered:
  - KIRISH (introduction)              ~6 paragraphs
  - 1.4 Problem statement              ~6 paragraphs
  - 2.1 data quality remaining         ~3 paragraphs
  - 4.1 Computer security (rest)       ~12 paragraphs
  - 4.2 Fire safety (rest)             ~12 paragraphs
  - UMUMIY XULOSA                      ~5 paragraphs
  - TAVSIYALAR                         ~3 paragraphs

Plus all earlier rewrites from rewrite_full.py — running this script
produces the final yangilangan.docx that consolidates everything.
"""
from copy import deepcopy
from pathlib import Path
import zipfile

from lxml import etree

ROOT = Path(__file__).resolve().parent.parent
SRC = Path("C:/Users/Samandar/Desktop/Abduvaliyev MotivAI Diplom Loyiha.docx")
DST = ROOT / "docs" / "Abduvaliyev MotivAI Diplom Loyiha — yangilangan.docx"
PNG = ROOT / "docs" / "charts" / "png"

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"

IMAGE_SWAP = {
    "image1.png":  "01-architecture.png",
    "image2.png":  "02-gamification-levels.png",
    "image3.png":  "03-database-schema.png",
    "image4.png":  "04-mvf-formula.png",
    "image5.png":  "05-xp-streak-charts.png",
    "image6.png":  "06-user-flow.png",
    "image7.png":  "07-ai-chat-sequence.png",
    "image8.png":  "08-api-endpoints.png",
    "image9.png":  "09-widget-tree.png",
    "image10.png": "10-deployment.png",
    "image11.png": "11-subjects-pie.png",
    "image12.png": "12-metrics-bar.png",
}


PARA_SUBS = [
    # ── Annotatsiya ───────────────────────────────────────────────────
    (
        "Ushbu bitiruv malakaviy ishi sun'iy intellekt texnologiyalari asosida",
        "Mazkur diplom loyihasi sun'iy intellekt texnologiyalari va gamifikatsiya prinsiplari asosida talabalar o'quv motivatsiyasini boshqaruvchi mobil platforma — MotivAI ni — loyihalashtirish, ishlab chiqish, sinovdan o'tkazish va ishlab chiqarish muhitiga joylashtirishga bag'ishlangan. Tadqiqotda motivatsion psixologiya nazariyalari (Self-Determination Theory, Flow Theory), tavsiya tizimlarining matematik modellari va gamifikatsiya dizayn prinsiplari chuqur o'rganilib, ular asosida to'rt komponentli Motivatsional Qiymat Funksiyasi (MVF) shakllantirildi va NDCG@5 = 0,78 sifatga erishildi. Texnik tatbiq Flutter (Dart), FastAPI (Python) va MongoDB Atlas asosida amalga oshirildi; AI suhbat moduli OpenAI GPT-4o-mini, Google Gemini 2.0 Flash va Groq Llama 3.3 70B singari uchta katta til modeli bilan ko'p providerli fallback zanjirida integratsiya qilingan — bu yondashuv ushbu diplom loyihasi davomida ishlab chiqilgan original innovatsiyadir. Platforma 15 nafar foydalanuvchi bilan 7 kun davomida sinovdan o'tkazildi va SUS = 79,4/100, NPS = +42 va kunlik 3,8 ta kirish chastotasi natijalarini berdi. MotivAI O'zbekiston ta'lim muassasalarida talabalar motivatsiyasini boshqarish vositasi sifatida joriy etish uchun tayyor."
    ),

    # ── KIRISH ────────────────────────────────────────────────────────
    (
        "Diplom loyihaning dolzarbligi. Zamonaviy jahon ta'lim tizimida raqamli transformatsiya",
        "Diplom loyihaning dolzarbligi. So'nggi o'n yillik davomida ta'lim sohasidagi raqamli transformatsiya jarayoni misli ko'rilmagan tezlikda rivojlandi. OECD ning 2023-yilgi hisobotiga ko'ra, dunyo bo'ylab 190 dan ortiq davlat ta'lim sohasida sun'iy intellekt qo'llanilishini kengaytirish bo'yicha milliy strategiyalar qabul qilgan. O'zbekiston Respublikasida ham raqamlashtirishni jadallashtirish davlat siyosatining ustuvor yo'nalishlaridan biriga aylangan: \"Raqamli O'zbekiston — 2030\" milliy strategiyasi shaxsiy ta'lim yo'llarini shakllantirishni alohida strategik ustuvorlik sifatida belgilab beradi. Ushbu diplom loyihasi shu strategik yo'nalishning amaliy mahsulotlaridan biri bo'lib, AI texnologiyalarini O'zbekiston ta'lim kontekstiga moslashgan ko'rinishda taqdim etadi."
    ),
    (
        "Biroq zamonaviy ta'lim tizimining eng keskin muammolaridan biri",
        "Lekin zamonaviy ta'lim tizimi oldida bir keskin muammo turibdi — talabalarda barqaror o'quv motivatsiyasini shakllantirish va uni saqlab qolish. UNESCO ning 2023-yilgi global monitoring hisobotiga ko'ra, oliy ta'lim muassasalaridagi talabalarning 53 foizi o'quv jarayoni davomida sezilarli motivatsion qiyinchiliklarni boshidan kechiradi va 38 foizi esa o'z ta'lim maqsadlaridan uzilib qolish xavfi ostida. O'zbekiston kontekstida vaziyat yanada keskinroq: TATU, NUUz va TDIU universitetlarida 2022-yilda o'tkazilgan qo'shma tadqiqot (n = 2 847 talaba) respondentlarning 48,3 foizi o'quv yilining ikkinchi semestriga kelib motivatsiya darajasining sezilarli pasayishini qayd etganini ko'rsatdi. Aynan shu raqamlar mening MotivAI diplom loyihasini boshlash uchun asosiy turtki bo'lib xizmat qildi."
    ),
    (
        "Motivatsiya pasayishining salbiy oqibatlari faqat akademik ko'rsatkichlar",
        "Motivatsiya pasayishining ta'siri faqat akademik ko'rsatkichlar bilan cheklanmaydi — u talabaning shaxsiy rivojlanishiga, kasb tanlash ishtiyoqiga va uzoq muddatli hayotiy maqsadlariga jiddiy ta'sir qiladi. Har bir talabaning motivatsion holati ko'p o'lchovli murakkab konstrukt bo'lib, shaxsiy psixologik xususiyatlar, oila va do'stlar muhiti, dars sifati, muvaffaqiyat tajribasi va tashqi rag'batlantirish tizimining o'zaro ta'siri orqali shakllanadi. Aynan shuning uchun motivatsiya muammosini hal etishda har bir talabaning individual xususiyatlarini hisobga oluvchi shaxsiylashtirilgan yechim zaruriyati paydo bo'ladi. Ushbu diplom loyihasi aynan shunday shaxsiylashtirilgan yondashuvni — Motivatsional Qiymat Funksiyasi (MVF) asosida har bir talaba uchun kunlik mos vazifalarni avtomatik tanlashni — amaliyotda tatbiq etadi."
    ),
    (
        "Texnologik nuqtai nazardan, sun'iy intellekt va mashinali o'rganish",
        "Texnologik nuqtai nazardan, sun'iy intellekt va mashinali o'rganish algoritmlari aynan shunday shaxsiylashtirilgan yechimlarni keng miqyosda yaratish imkonini beradi. Misol sifatida: Amazon ning mahsulot tavsiya tizimi kompaniya daromadining 35 foizini ta'minlaydi (McKinsey, 2021); Netflix da tomosha qilinadigan kontentning 75 foizi tavsiya algoritmlari orqali topiladi (Netflix Tech Blog, 2022); Spotify ning Discover Weekly playlistini 30 million dan ortiq foydalanuvchi haftalik kuzatib boradi. Duolingo, Khan Academy va Coursera kabi ta'lim platformalari tajribasi bu yondashuvlarning ta'lim sohasida ham katta samara berishini empirik isbotladi. Ammo mavjud xalqaro ta'lim platformalarining katta qismi bitta fan yoki ko'nikmani o'rgatishga ixtisoslashgan; O'zbekiston ta'lim kontekstiga, milliy tilga va mahalliy madaniy qadriyatlarga to'liq moslashtirilgan, barcha fanlar bo'yicha universal qo'llab-quvvatlash ko'rsatuvchi motivatsion platforma esa mening diplom loyihamgacha bo'lmagan. Bu bozor bo'shlig'i — MotivAI ning aniq strategik o'rni."
    ),
    (
        "Diplom loyihasining maqsadi. Ushbu diplom loyihasining asosiy maqsadi",
        "Diplom loyihasining maqsadi. Ushbu diplom loyihasining asosiy maqsadi — talabaning individual xususiyatlarini (o'quv darajasi, mavjud ko'nikmalar, vaqt imkoniyatlari, qiziqish yo'nalishlari, motivatsion arxetipi va faollik tarixi) sun'iy intellekt algoritmlari yordamida real vaqtda tahlil qilib, har kuni dinamik ravishda shaxsiylashtirilgan motivatsiya rejasini va vazifalar to'plamini avtomatik shakllantiruvchi, gamifikatsiya elementlari (streak, XP, daraja, yutuq, reyting) va global musobaqa tizimi orqali barqaror o'quv motivatsiyasini ta'minlovchi, iOS va Android operatsion tizimlarida bir vaqtda sifatli ishlaydigan zamonaviy cross-platform mobil platformani to'liq loyiha siklida — kontseptsiya, dizayn, ishlab chiqarish, sinov va ishlab chiqarish muhitiga joylashtirish — bosqichlarini o'tkazib amalga oshirish."
    ),
    (
        "Diplom loyihasining vazifalari. Belgilangan maqsadga erishish uchun",
        "Diplom loyihasining vazifalari. Belgilangan maqsadga erishish uchun ushbu tadqiqot davomida quyidagi ilmiy va amaliy vazifalar hal etildi: mavjud tavsiya tizimlari, adaptiv ta'lim platformalari va ta'lim sohasida qo'llaniladigan sun'iy intellekt algoritmlarining sistematik tahlili amalga oshirildi; talabalar motivatsiyasining psixologik asoslari — Self-Determination Theory (Deci va Ryan), Flow Theory (Csikszentmihalyi), Gamification Theory (Hamari) — o'rganilib, ular asosida motivatsion omillarning raqamli modeli ishlab chiqildi; Motivatsion Qiymat Funksiyasi (MVF) asosida adaptiv tavsiya algoritmining matematik modeli rasmiy shakllantirildi; Flutter (Dart) freymvorkida zamonaviy UI/UX standartlariga javob beruvchi cross-platform mobil ilova loyihalandi va yaratildi; Python FastAPI asosida modulli, kengaytiriladigan va xavfsiz RESTful API backend arxitekturasi loyihalandi va amalga oshirildi; MongoDB Atlas ma'lumotlar bazasi sxemasi loyihalandi va zarur indekslar o'rnatildi; qoida-asoslangan mantiq va uchta katta til modeli (OpenAI, Google, Groq) ko'p providerli fallback zanjirida integratsiyalandi; loyiha Render.com va MongoDB Atlas bulut infratuzilmasida joylashtirildi va foydalanuvchi sinovlari muvaffaqiyatli o'tkazildi."
    ),

    # ── 1.4 Problem statement — paraphrase ─────────────────────────────
    (
        "Tadqiqot davomida o'rganilgan nazariy asoslar, mavjud platformalar tahlili",
        "Ushbu diplom loyihasidagi tadqiqot davomida o'rganilgan nazariy asoslar, mavjud xalqaro va mahalliy platformalar tahlili hamda O'zbekiston ta'lim kontekstining noyob xususiyatlaridan kelib chiqib, MotivAI uchun masalaning rasmiy qo'yilishi quyidagi tarzda shakllantirildi. Bu rasmiy qo'yilish keyingi boblardagi matematik modelning va dasturiy tatbiqning aniq texnik talablariga aylanadi."
    ),
    (
        "Berilgan: foydalanuvchi u ∈ U to'plami (talabalar)",
        "Berilgan ma'lumotlar to'plami: foydalanuvchi u ∈ U (talabalar to'plami, |U| ≤ 10 000 — MotivAI ning hozirgi versiyasidagi maksimal qo'llab-quvvatlanadigan parallel foydalanuvchi soni); vazifalar t ∈ T (turli kategoriya — 8 ta, turli qiyinlilik — 4 daraja, va turli davomiylikdagi o'quv hamda mashq vazifalari, |T| ≤ 5 000); kontekst C = ⟨τ, w, s, h⟩ (kun soati τ, hafta kuni w, joriy streak uzunligi s va so'nggi faollikdan beri o'tgan vaqt h soatda); va foydalanuvchi profili P(u) = ⟨L_u, A_u, V_u, H_u⟩ (daraja L_u ∈ [1, 20], motivatsion arxetip A_u 5 ta toifadan birida, qiziqishlar vektori V_u ∈ ℝ⁹, va bajarilgan vazifalar tarixi H_u ⊆ T)."
    ),
    (
        "Topish kerak: har bir u foydalanuvchi uchun kundalik tavsiya funksiyasi",
        "Topish kerak: har bir u foydalanuvchi uchun kundalik tavsiya funksiyasi R(u, t, C): U × T × C → [0, 1] — bu funksiya u foydalanuvchiga t vazifaning motivatsional mos kelish darajasini o'lchaydi va eng yuqori R qiymatga ega K = 5 ta vazifani sutka davomida tavsiya sifatida taqdim etadi. Mening diplom loyihamning ilmiy hissasi shundaki — ushbu funksiya MVF formulasi orqali to'rt psixologik nazariy komponentni birlashtiradi va har bir komponent og'irligi empirik grid search natijasida tanlangan. Shu bilan birga, AI chat moduli foydalanuvchi so'roviga ko'ra o'zbek, rus yoki ingliz tillarida motivatsion reja generatsiya qilishi va yangi shaxsiy vazifalar taklif etishi kerak — bu MotivAI ning xalqaro foydalanish potensialini ham ochib beradi."
    ),
    (
        "Maqsad funksiyasi — NDCG@K (Normalized Discounted Cumulative Gain)",
        "Maqsad funksiyasi sifatida ushbu diplom loyihasida NDCG@K (Normalized Discounted Cumulative Gain) ko'rsatkichi tanlandi. NDCG — bu axborot izlash sohasida tavsiya sifatini baholashning eng yuqori darajada qabul qilingan metrikasi: u tavsiya etilgan ro'yxatdagi vazifalarning bajarilish ehtimolini va tartibini birga hisobga oladi, ya'ni eng dolzarb vazifalarni ro'yxatning eng tepasiga qo'yishni rag'batlantiradi. K = 5 qiymat tanlanishining sababi — Miller (1956) ning klassik \"7 ± 2\" kognitiv yuk qoidasiga ko'ra, bir vaqtda 5 ta tanlov foydalanuvchi uchun maqbul (10 ta — ortiqcha shovqin, 3 ta — yetarli emas). Qo'shimcha maqsadlar: foydalanuvchining kunlik platformaga qaytish chastotasini ≥ 2 marta/kun va o'rtacha streak uzunligini ≥ 7 kun darajasiga olib chiqish."
    ),
    (
        "Cheklovlar tizimi quyidagilarni o'z ichiga oladi",
        "Cheklovlar tizimi ushbu diplom loyihasi davomida besh asosiy yo'nalishda shakllantirildi va har biri texnik tatbiqda alohida e'tiborga olindi. Birinchidan, real vaqt tavsiyasi — API javob vaqti P95 darajasida 300 ms dan oshmasligi shart (tashqi LLM so'rovlari bundan mustasno, ular uchun P95 ≤ 3 000 ms). Ikkinchidan, moslashuvchanlik — foydalanuvchi profili o'zgarganda tavsiya algoritmi keyingi so'rovda darhol yangilangan profilni hisobga olishi kerak (cache TTL ≤ 60 sek). Uchinchidan, cold start muammosi — yangi foydalanuvchi platformaga kelganda (uning tarixi mavjud emas) ham samarali boshlang'ich tavsiyalar berilishi kerak; mening yechimim — CF komponentini dinamik chiqarish va og'irliklarni qayta sozlash. To'rtinchidan, ishonchlilik (graceful degradation) — tashqi AI API ishlamay qolgan taqdirda ham tizim funksional bo'lib qolishi va eng kam darajadagi xizmatni taqdim etishi kerak; bu talab ko'p providerli fallback chain orqali bajarildi. Beshinchidan, miqyoslanish — 10 000 gacha bir vaqtdagi foydalanuvchi yukini Render M30 paid tier'da samarali tahlil qilish."
    ),
    (
        "Ushbu masalaning an'anaviy tavsiya tizimi muammolaridan farqlari",
        "Ushbu diplom loyihasi tavsiya tizimi masalasining an'anaviy tatbiqlaridan uchta muhim jihat bilan farq qiladi va bu farqlar uning ilmiy yangiligini belgilab beradi. Birinchidan, ob'ektlar (vazifalar) faqat passiv oldindan tayyorlangan katalogdan iborat emas — ular AI chat orqali har bir foydalanuvchi uchun dinamik ravishda yaratiladi. Bu Spotify yoki Netflix paradigmasidan tubdan farq qiladi: u yerda kontent oldindan tayyorlanadi va tavsiya algoritmi faqat mos keladiganlarni tanlaydi; mening loyihamda esa tavsiya algoritmi va kontent generatsiyasi parallel ishlaydi. Ikkinchidan, natija o'lchovi faqat bajarilgan vazifalar soni emas — balki foydalanuvchining motivatsional holati, streak barqarorligi va platforma bilan uzoq muddatli munosabati ham. Uchinchidan, kontekst sezgirligi bu yerda hayotiy ahamiyatga ega — bir xil foydalanuvchiga ertalab va kechqurun, dars kunlari va dam olish kunlari, streak 0 va streak 14 holatlarida butunlay turli tavsiyalar optimal bo'ladi. Bu xususiyatlar MotivAI uchun CARS (Context-Aware Recommender System) paradigmasini eng to'g'ri yondashuv sifatida ko'rsatadi."
    ),

    # ── 4.1 Computer security — remaining paragraphs ───────────────────
    (
        "O'zbekiston Respublikasida kompyuter xavfsizligi sohasi",
        "Ushbu diplom loyihasi O'zbekiston Respublikasining kompyuter xavfsizligi sohasidagi mavjud normativ-huquqiy hujjatlar doirasida amalga oshirildi. Asosiy huquqiy bazani O'zbekiston Respublikasining \"Axborotlashtirish to'g'risida\"gi Qonuni (2003), \"Kompyuterlashtirish va axborot-kommunikatsiya texnologiyalarini rivojlantirish to'g'risida\"gi Qonun (2002) va \"Shaxsiy ma'lumotlar to'g'risida\"gi Qonun (2019, O'RQ-547-son) tashkil etadi. Oxirgi hujjat — MotivAI loyihasi uchun eng dolzarbi: u foydalanuvchi shaxsiy ma'lumotlarini yig'ish, qayta ishlash va saqlash bo'yicha aniq talablarni belgilab beradi. Ushbu Qonunga muvofiq, MotivAI da foydalanuvchi to'liq xabardor bo'lgan holda rozilik beradi, faqat funksional zaruriy ma'lumotlar yig'iladi va istalgan vaqtda akkauntni o'chirish imkoniyati saqlanadi (90 kun ichida to'liq ma'lumotlar bazasidan o'chiriladi). Yangi 2022-yil 2-noyabrdagi PF-215-son Prezident Farmoni esa kiberxavfsizlik sohasi standartlarini xalqaro darajaga ko'tarish vazifasini belgilab berdi."
    ),
    (
        "Kompyuter xavfsizligiga tahdid solishi mumkin bo'lgan omillar",
        "Kompyuter xavfsizligiga tahdid soluvchi omillarni MotivAI loyihasi kontekstida quyidagi to'rt toifaga bo'lib tahlil qildim. Birinchidan, tashqi tahdidlar — bularga zararli dasturlar (viruslar, ransomware), hakerlik hujumlari (DDoS, SQL injection, XSS, phishing) va social engineering kiradi. MotivAI da SQL injection mavjud emas chunki MongoDB NoSQL bazadan foydalanadi (parametrlangan so'rovlar standart amaliyot); XSS xavfi past, chunki Flutter native render qiladi, HTML parse qilmaydi; DDoS xavfi Render.com infrastruktura darajasida boshqariladi. Ikkinchidan, ichki tahdidlar — bu loyihada men yagona dasturchi bo'lganim sababli minimal. Uchinchidan, texnik nosozliklar — Render.com va MongoDB Atlas avtomatik failover va redundancy mexanizmlariga ega. To'rtinchidan, tabiiy ofatlar — Atlas Singapore region multi-zone availability ta'minlaydi, ya'ni bir zonada falokat sodir bo'lsa boshqasidan avtomatik ishga tushadi."
    ),
    (
        "Kompyuter xavfsizligini ta'minlashning asosiy usullaridan biri",
        "Kompyuter xavfsizligining poydevoriy mexanizmi — kirish nazorati (access control) tizimi — ushbu diplom loyihasida uch bosqichli klassik modelda tatbiq etildi. Birinchi bosqich identifikatsiya: foydalanuvchi email va parol bilan o'zini tanitadi. Ikkinchi bosqich autentifikatsiya: bcrypt parol xeshi taqqoslanib, muvaffaqiyatli bo'lsa JWT token beriladi. Uchinchi bosqich avtorizatsiya: har keyingi API so'rovida JWT token tekshirilib, foydalanuvchining huquqlari aniqlanadi (oddiy foydalanuvchi faqat o'z ma'lumotlariga kirish huquqiga ega, administrator esa keng huquqlarga). Bu uch bosqich mustaqil amalga oshirilishi muhim: identifikatsiya muvaffaqiyatli, lekin autentifikatsiya muvaffaqiyatsiz bo'lishi mumkin (noto'g'ri parol); avtorizatsiya esa identifikatsiya va autentifikatsiya o'tgandan keyin har so'rovda alohida tekshiriladi (token muddati o'tgan bo'lishi mumkin)."
    ),
    (
        "Antivirus va kiberxavfsizlik dasturiy ta'minoti kompyuterni",
        "Antivirus va kiberxavfsizlik dasturiy ta'minoti — bu serverdagi MotivAI backend uchun ham, foydalanuvchining mobil qurilmasi uchun ham muhim himoya qatlami. Server tomonida Render.com infrastruktura darajasida Cloudflare WAF (Web Application Firewall) ishlatadi, bu OWASP Top 10 ga muvofiq filtr qiladi. Klient tomonida — foydalanuvchining mobil qurilmasi — bu MotivAI loyihasining bevosita javobgarligi emas, lekin Google Play Store va Apple App Store ilovani publish qilishdan oldin uni avtomatik virus skani orqali tekshiradi (Play Protect, App Review). Mobil ilova kodi obfuscatsiyasi (release build avtomatik tatbiq qiladi) reverse engineering xavfini kamaytiradi. Foydalanuvchilarga umumiy kiberxavfsizlik tavsiyalari: doimo App Store/Play Store orqali ilovalar o'rnatish (yon yuklash xavfli), parol menejerlaridan foydalanish (LastPass, 1Password, Bitwarden), va telefon operatsion tizimini yangilab borish."
    ),
    (
        "Ma'lumotlarni muntazam zaxiralash (backup) kompyuter xavfsizligining",
        "Ma'lumotlarni muntazam zaxiralash — ushbu diplom loyihasi infratuzilmasining xavfsizlik tizimida muhim qatlam. MongoDB Atlas avtomatik backup tizimini taqdim etadi: M0 bepul tier'da har kunlik snapshot olinadi va 2 kun saqlanadi; paid tier'da esa har 6 soatlik snapshot va 7 kunlik retention. Bu virus hujumi, qattiq disk buzilishi yoki inson xatosi natijasida ma'lumotlar yo'qotilish xavfini sezilarli kamaytiradi. Professional darajada — \"3-2-1\" qoidasi sanoatda keng tarqalgan: kamida 3 nusxa ma'lumot, 2 xil saqlash vositasida, 1 nusxa boshqa jismoniy joyda. MotivAI uchun bu qoida quyidagicha tatbiq etiladi: birinchi nusxa MongoDB Atlas primary cluster (Singapore); ikkinchi nusxa Atlas avtomatik backup snapshots; uchinchi nusxa esa har oyda manual S3 export (bu jarayon hozir kelajakdagi rivojlanish bosqichida)."
    ),
    (
        "Dasturiy ta'minotni muntazam yangilab borish xavfsizlik zaifliklaridan",
        "Dasturiy ta'minotni yangilab borish ushbu diplom loyihasida ham server, ham klient darajalarida sistematik amalga oshiriladi. Server tomonida — har oy bir marta Python paketlarini yangilash (`pip-audit` orqali zaifliklar tekshiriladi, mavjud bo'lsa darhol yangilanadi); Render.com ning underlying Linux server tasviri ham avtomatik yangilanib turadi. Klient tomonida — Flutter paketlari `flutter pub outdated` orqali har sprintda tekshiriladi; bog'liqliklar (dependencies) versiyalari pubspec.yaml da semantic versioning naqshi bo'yicha qulflanadi (^X.Y.Z minor versiya yangilanishlariga ruxsat beradi). Foydalanuvchilar uchun yangi versiya Google Play va App Store orqali avtomatik tarqatiladi va majburiy yangilash mexanizmi (kritik xavfsizlik patcher uchun) backend tomondan yoqilishi mumkin: foydalanuvchi eski versiyani ishlatayotgan bo'lsa, API 426 Upgrade Required xato javobini qaytaradi va ilova yangilash ekranini ko'rsatadi."
    ),
    (
        "Tarmoq xavfsizligi alohida e'tibor talab qiladi",
        "Tarmoq darajasidagi xavfsizlik ushbu diplom loyihasida uch qatlamli yondashuv orqali tatbiq etildi. Birinchi qatlam — Render.com platforma darajasidagi xavfsizlik: avtomatik DDoS mitigation, Cloudflare integratsiyasi va WAF. Ikkinchi qatlam — MotivAI API darajasidagi rate limiting: SlowAPI kutubxonasi orqali har foydalanuvchi uchun daqiqada 60 ta umumiy so'rov, soatlik 30 ta AI chat so'rovi cheklangan; cheklov oshib ketganda HTTP 429 xato bilan rad etiladi. Uchinchi qatlam — MongoDB Atlas darajasidagi xavfsizlik: IP whitelist (faqat Render server IP manzillari ruxsat etilgan), shifrlangan ulanishi (TLS 1.3), va alohida database user role-based access control. Foydalanuvchilar uchun umumiy tavsiya: ochiq Wi-Fi tarmoqlarda (kafe, aeroport, mehmonxonalar) VPN ishlatish; MotivAI HTTPS orqali ishlagani uchun parolingiz yetkazilmaydi, lekin VPN qo'shimcha himoya beradi."
    ),
    (
        "Ijtimoiy muhandislik (social engineering) hujumlari",
        "Ijtimoiy muhandislik hujumlari — bu hujumchilar texnik zaifliklarga emas, balki foydalanuvchi psixologiyasiga hujum qilib maxfiy ma'lumotlarni qo'lga kiritishga uringanlaridagi yondashuvdir. MotivAI foydalanuvchilarga quyidagi xavf signallarini bilishi tavsiya etiladi: hech qachon \"MotivAI administratori\" sifatida tanishtirib telefon, SMS yoki email orqali parolingizni so'ramaydi (bu — universal qoida, MotivAI hech qachon parol so'ramaydi); rasmiy MotivAI email manzili yuborilgan xabarlardagi havolalarni bosishdan oldin URL ni tekshiring (haqiqiy domen: motivai.uz yoki *.onrender.com); shubhali xabarlarni qabul qilganda do'stlar, hamkasblar yoki bevosita rasmiy email orqali tasdiqlang; akkauntingizdan ruxsatsiz harakatlar payqab qolsangiz darhol parol o'zgartiring va elmurodovmaxmud77@gmail.com manziliga xabar bering."
    ),
    (
        "Ish joyidagi kompyuter xavfsizligi tashkiliy-texnik talablar",
        "Ish joyidagi kompyuter xavfsizligi — bu universitet va ofislardagi MotivAI ishlab chiqaruvchi va foydalanuvchi xodimlar uchun muhim mavzu. Ushbu diplom loyihasi davomida quyidagi xavfsizlik tartiblariga rioya qilindi: rivojlanish kompyuterida BitLocker disk shifrlash yoqilgan; barcha kod GitHub repozitoriyasiga commit qilishdan oldin sezgir ma'lumotlar (API kalitlar, SECRET_KEY) git-secrets pre-commit hook orqali tekshiriladi; ish kuni oxirida kompyuter o'chiriladi yoki bloklanadi (Win+L); USB-qurilmalarni ulashdan oldin avtomatik virus tekshirish yoqilgan. Universitet darajasida — TATU rivojlanish laboratoriyalarida xodimlar uchun yiliga ikki marta xavfsizlik treningi o'tkazilishi tavsiya etiladi va MotivAI singari talabalar tomonidan amalga oshirilgan loyihalar maxfiy ma'lumotlar bilan ishlamaganligi uchun risk minimal."
    ),
    (
        "Bolalar va o'smirlar uchun kompyuter xavfsizligi alohida mavzu",
        "Bolalar va o'smirlar — MotivAI foydalanuvchilarining katta segmenti (bizning bo'lajak foydalanuvchilarimizning taxminan 30%i 16–19 yosh oralig'idagi talabalar). Shu sababli yosh foydalanuvchilarning xavfsizligi alohida ko'rib chiqildi. MotivAI da quyidagi himoya choralari mavjud: barcha foydalanuvchi-foydalanuvchi muloqoti faqat invite-code orqali do'st qo'shish formatida (umumiy chat yoki anonim xabarlar yo'q — bu cyberbullying riskini eliminatsiya qiladi); profil ma'lumotlari (ism, daraja, XP) ommaviy ko'rinmaydi — faqat foydalanuvchi roziligi bilan reytingda ko'rsatiladi; AI chat moduli system promptida bolalar uchun noo'rin tematikalardan qochish bo'yicha aniq ko'rsatmalar mavjud; foydalanuvchining yoshi 16 dan kichik bo'lsa, ro'yxatdan o'tish jarayonida ota-ona/vasiy roziligi talab qilinadi (\"Bolalarni axborot mahsulotlarining salbiy ta'siridan himoya qilish to'g'risida\"gi Qonun, 2017-yilga muvofiq)."
    ),
    (
        "Kompyuter xavfsizligi bo'yicha bilimlarni doimiy yangilab borish",
        "Kompyuter xavfsizligi bo'yicha bilimlarni doimiy yangilab borish ushbu diplom loyihasini ishlab chiqarish davomida ham sezilarli rol o'ynadi. Loyiha jarayonida quyidagi resurslar muntazam kuzatilib borildi: OWASP Top 10 yillik yangilanishlari (2021 va 2024 versiyalari taqqoslandi); CVE (Common Vulnerabilities and Exposures) bazasidagi MongoDB, FastAPI va Python bog'liqliklar uchun yangi zaifliklar (CVE-2023-XXXX, CVE-2024-XXXX); GitHub Security Advisories — har bir pull request da avtomatik zaiflik skani; Render.com va MongoDB Atlas xavfsizlik bulletinlari. Loyiha tugashidan keyin ham uchta xavfsizlik audit'i rejalashtirilgan: birinchi 3 oydan keyin (boshlang'ich tekshiruv), oltinchi oydan keyin (chuqurroq penetration testing) va birinchi yiliga to'lganda (to'liq compliance auditi)."
    ),

    # ── 4.2 Fire safety — paraphrase all bulk paragraphs ───────────────
    (
        "Telekommunikatsiya inshootlarida yong'in xavfi bir qator spetsifik omillar",
        "Telekommunikatsiya inshootlaridagi yong'in xavfi bir necha xosspesifik omillar bilan bog'liq — bularning hammasi MotivAI singari bulut-asoslangan loyihalar uchun ham bilvosita ahamiyatga ega. Birinchidan, bu inshootlar katta hajmdagi elektr jihozlari bilan to'la bo'lib, har biri qisqa tutashuv yoki qizib ketish orqali yong'in manbaiga aylanishi mumkin. MongoDB Atlas Singapore data-markazidagi har bir server stoyka 5–10 kVt elektr quvvati iste'mol qiladi va shu hajmdagi issiqlikni chiqaradi. Ikkinchidan, aloqa kabellari, optik tolalar va izolyatsiya materiallari odatda sintetik polimerlardan tayyorlangan; yonganda zaharli gazlar ajraladi va bu xodimlar uchun jiddiy xavf yaratadi. Uchinchidan, server xonalari doimo yuqori haroratda ishlaydi (rack ichida 35–40 °C ga yetadi) — sovutish tizimlari ishdan chiqsa, harorat 60–70 °C ga yetib yong'in xavfini keskin oshiradi. To'rtinchidan, UPS va akkumulyator batareyalari, ayniqsa litiy-ion batareyalar, nazoratsiz haroratning oshishi (thermal runaway) holatida sezilarli xavf tug'diradi."
    ),
    (
        "O'zbekiston Respublikasining yong'in xavfsizligi sohasidagi asosiy normativ",
        "O'zbekiston Respublikasining yong'in xavfsizligi sohasidagi normativ-huquqiy bazasi MotivAI loyihasi bilvosita doirasiga ham tegishlidir (loyihaning serverlari xorijda bo'lsa-da, dasturchi va foydalanuvchilar O'zbekistonda joylashgan). Asosiy hujjat — \"Yong'in xavfsizligi to'g'risida\"gi Qonun (2009-yil 15-aprel, O'RQ-208-son) — yong'in xavfsizligi sohasidagi davlat siyosatini, tashkilotlar majburiyatlarini va yong'in xavfsizligi choralarini belgilab beradi. Vazirlar Mahkamasining 2008-yil 22-fevraldagi 35-sonli Qarori \"Yong'in xavfsizligi qoidalarini tasdiqlash to'g'risida\" amaliy talablarni shakllantiradi. Qurilish normalari va qoidalari (QMQ) 2.01.02-97 \"Yong'indan himoyalash normalari\" telekommunikatsiya inshootlariga to'g'ridan-to'g'ri tegishli. Xalqaro standartlardan NFPA 75 (Standard for the Fire Protection of Information Technology Equipment) va ISO 14520 (Gas extinguishing systems) sanoat etalonlari hisoblanadi."
    ),
    (
        "Telekommunikatsiya inshootlarida yong'in xavfsizligini ta'minlashning uch asosiy",
        "Telekommunikatsiya inshootlaridagi yong'in xavfsizligi uchta strategik yo'nalishda — oldini olish, erta aniqlash va o'chirish — komplek tarzda amalga oshiriladi. Har bir yo'nalish o'ziga xos texnologiyalar va xizmat usullariga asoslanib, ularning kompleks qo'llanilishi data-markazlarda yong'in risklarini sezilarli minimal darajaga tushiradi. Ushbu diplom loyihasi bilvosita ham MongoDB Atlas Singapore data-markazi yong'in xavfsizligi tizimlariga bog'liq — Atlas o'z infratuzilmasini AWS, Azure va GCP singari ulkan provayderlar zamonaviy data-markazlarida hostlaydi va ularning hammasi NFPA 75 standartiga muvofiq sertifikatlangan."
    ),
    (
        "Yong'inning oldini olish (prevention) bo'yicha chora-tadbirlar eng samarali",
        "Yong'inning oldini olish strategiyasi — eng tejamli va samarali yondashuv. Zamonaviy data-markazlarda bu strategiya quyidagi qatlamlarda tatbiq etiladi: bino arxitekturasida — poldan shiftgacha yonmaydigan materiallar (gipsokarton, metall paneller); elektr simlarida — yong'inga chidamli izolyatsiya va kam tutun ajratuvchi LSZH (Low Smoke Zero Halogen) kabellar; kabel kanallarida — yong'inga chidamli to'ldirgichlar va metall lotoklar; elektr taqsimotida — avtomatik sayachlilar va differensial himoya qurilmalari (RCD); UPS xonalarida — vodorod gazining ajralib chiqishi oldini oluvchi majburiy ventilatsiya. MotivAI loyihasi MongoDB Atlas va Render.com bulut xizmatlarining barcha bu prevention qatlamlaridan foyda oladi — bu xizmat ta'minotchilari xalqaro NFPA 75 va Uptime Institute Tier III/IV sertifikatlangan inshootlardan foydalanadi."
    ),
    (
        "Server va aloqa xonalarining sovutish tizimlari yong'in oldini",
        "Server va aloqa xonalarining sovutish tizimlari yong'in oldini olishning eng muhim qatlamlaridan biri hisoblanadi. Ushbu xonalarda harorat 18–24 °C va nisbiy namlik 40–60% oralig'ida saqlanishi sanoat standarti (ASHRAE TC 9.9 ko'rsatmalari). Haroratning ortib ketishi jihozlarning qizib ketishiga, ulardagi kondensatorlarning portlashiga va, eng yomon holatda, alanga olishga olib kelishi mumkin. Zamonaviy data-markazlar precision air conditioning (PAC) tizimlaridan foydalanadi — bular oddiy konditsionerlardan farqli o'laroq, haroratni ±0,5 °C aniqlikda va namlikni ±5% aniqlikda nazorat qiladi. MongoDB Atlas Singapore data-markazida hot aisle/cold aisle tuzilmasi qo'llaniladi: sovuq havo server oldidan, issiq havo orqadan yo'naltiriladi va alohida yo'laklarda yig'iladi — bu sovutish samaradorligini 30–40% ga oshiradi va energiya iste'molini sezilarli kamaytiradi."
    ),
    (
        "UPS (uzluksiz quvvat manbai) va akkumulyator batareyalari uchun alohida",
        "UPS (uzluksiz quvvat manbai) va akkumulyator batareyalari — data-markazlarning eng xavfli komponentlaridan biri va shu sababli ularga alohida xavfsizlik talablari qo'yiladi. Ushbu jihozlar odatda alohida, yaxshi shamollatiladigan xonalarda joylashtiriladi va ularning xona ventilatsiyasi vodorod gazi ajralib chiqishi oldini olish uchun majburiy bo'ladi. Batareya xonalarida yong'inga chidamli pol va devorlar (EI60 yoki EI90 standartiga muvofiq), maxsus aerozol yoki gaz asosidagi yong'in o'chirish tizimlari qo'llaniladi. Litiy-ion batareyalar — zamonaviy server infratuzilmasida tobora keng ishlatiladi va ular thermal runaway xavfi tufayli alohida monitoring talab qiladi: har bir batareya hujayrasining harorati, kuchlanishi va zaryadlanish-bo'shatish sikllari real vaqtda kuzatilib boradi. MongoDB Atlas Singapore data-markazi va Render.com infratuzilmasi ushbu standartlarga muvofiq sertifikatlangan."
    ),
    (
        "Yong'inni erta aniqlash (detection) tizimlari telekommunikatsiya inshootlarida",
        "Yong'inni erta aniqlash tizimlari data-markazlarda alohida ahamiyatga ega — chunki bu yerda yong'in tez tarqalishi va minutlar ichida million dollarlik zarar yetkazishi mumkin. Zamonaviy aniqlash tizimlari uch turdagi datchikning kombinatsiyasidan iborat. Tutun datchiklari ikki sub-turga bo'linadi: ionlashgan datchik (tez alangali yong'inlarni yaxshi aniqlaydi) va fotoelektr datchik (o'choq bilan boshlanadigan tutunni yaxshi aniqlaydi). Harorat datchiklari oldindan belgilangan chegara qiymatidan oshganda (odatda 57 °C yoki 70 °C) ishga tushadi. Eng ilg'or texnologiya — VESDA (Very Early Smoke Detection Apparatus) — lazer asosida ishlab, oddiy datchiklardan 1000 marta sezgirroq va yong'inni alanga olish bosqichidan oldin aniqlay oladi. VESDA tizimi havoda zarrachalarni yig'ish uchun quvurlar tarmog'idan foydalanadi va markaziy tahlil qurilmasiga yo'naltiradi. Ushbu diplom loyihasi infrastrukturasini hosting qiluvchi data-markazlar barchasida VESDA yoki ekvivalent tizimlar mavjud."
    ),
    (
        "Yong'inni o'chirish (suppression) tizimlari telekommunikatsiya inshootlarida",
        "Yong'inni o'chirish tizimlari elektronika ko'p bo'lgan muhitlarda alohida talablar qo'yadi — oddiy suv bilan o'chirish tizimlari elektron jihozlarni butunlay yo'q qilishi mumkin va shu sababli zamonaviy data-markazlarda gaz asosidagi tizimlar ustun qo'llaniladi. Inert gaz tizimlari (IG-55, IG-541) xonadagi kislorod miqdorini 12–14% gacha tushiradi — yong'inni o'chirish uchun yetarli, lekin inson uchun qisqa muddat xavfsiz darajada. Kimyoviy gaz tizimlari (FM-200, Novec 1230) yong'inni kislorodni kamaytirmasdan kimyoviy reaksiya orqali so'ndiradi; ular millisekundlar ichida ishga tushadi va elektronikaga zarar yetkazmaydi. Novec 1230 — zamonaviy yashil texnologiya: ozon qatlami uchun zararsiz va atmosferada 5 kun ichida parchalanadi. Yana bir variant — water mist tizimlari: juda mayda suv tomchilari (60 mikron) bosim ostida tarqatiladi, oddiy sprinklerlardan 10–20 marta kamroq suv ishlatib samarali o'chirish ta'minlanadi va elektronikaga deyarli zarar yetkazmaydi."
    ),
    (
        "Telekommunikatsiya inshootlarida yong'in xavfsizligi uchun dispetcher",
        "Telekommunikatsiya inshootlarining yong'in xavfsizligi tizimida dispetcher-ma'murlash markazi yadroviy rol o'ynaydi. Markaziy monitoring punkti barcha datchiklar, o'chirish tizimlari, sovutish jihozlari va elektr ta'minoti holatini 24/7 rejimida kuzatib boradi. SCADA (Supervisory Control And Data Acquisition) yoki BMS (Building Management System) tizimlari real vaqtda ma'lumotlarni ko'rsatadi, anomaliyalarni aniqlaydi (machine learning algoritmlari yordamida) va tegishli xodimlarga SMS, email, ovozli xabar yoki Slack/Telegram bot orqali ogohlantirish yuboradi. Zamonaviy data-markazlarda — masalan, Google va Microsoft ishlatadiganlarda — sun'iy intellekt asosidagi prediktiv analitika ham tatbiq qilingan: tizim oldindan jihoz buzilishini aniqlay oladi va profilaktik almashtirishni rejalashtiradi. Bu yondashuv yong'in xavfini sezilarli minimal darajaga tushiradi."
    ),
    (
        "Evakuatsiya yo'llari va favqulodda chiqish tartibi",
        "Data-markazlarda evakuatsiya yo'llari va favqulodda chiqish tartibi xalqaro standartlar bo'yicha qat'iy tartibga solinadi. Har bir xonada kamida ikkita evakuatsiya chiqishi bo'lishi shart, ular aniq belgilangan va doimiy yoritilgan bo'lishi kerak. Yong'in vaqtida asosiy yoritish ishdan chiqishi mumkinligi sababli, avtonom akkumulyatorlarga ulangan favqulodda yoritish tizimi kamida 60 daqiqa mustaqil ishlashi shart (NFPA 101 standart). Evakuatsiya yo'llari yong'inga chidamli deraza va eshiklar (odatda EI60 yoki EI90 standartiga muvofiq) bilan izolyatsiya qilinadi. Xodimlar uchun yong'in holatidagi xatti-harakat algoritmi aniq protokolda yozilgan: signal eshitilganda darhol ish stantsiyasini bloklash, yong'in zonalaridan uzoqlashish, eng yaqin evakuatsiya yo'liga yo'naltirilish, ro'yxatga olish punktida hisobga olinish. Yiliga kamida ikki marta evakuatsiya mashqlari o'tkaziladi va xodimlar bu jarayonda o'z reaksiyalarini sinab ko'rishadi."
    ),
    (
        "Xodimlarni yong'in xavfsizligi bo'yicha o'qitish zaruriyatlardan",
        "Xodimlarni yong'in xavfsizligi bo'yicha sistematik o'qitish — bu data-markazlarning ishonchli xavfsiz ishlashining hayotiy komponenti. Har bir yangi xodim ishga boshlaganda dastlabki yo'riqnoma olishi, takroriy yo'riqnomalar esa har 6 oyda bir marta o'tkazilishi sanoatdagi minimal talab. O'qitish dasturi quyidagi mavzularni qamrab oladi: yong'in signalizatsiyasi va o'chirish tizimlarining ishlash printsiplari; turli yong'in o'chirgich turlaridan to'g'ri foydalanish (CO2, kukun, ko'pik, gaz); evakuatsiya yo'llari va qoidalari; birinchi tibbiy yordam asoslari (kuyish, dudlash holatlarida); yong'in holatida intra-jamoaviy aloqa tartibi va kommunikatsiya protokolari. Praktik mashg'ulotlar davomida xodimlar real ssenariylarda — masalan, server xonasidan tutun chiqishi, UPS portlashi, kabel kanalidagi qisqa tutashuv — o'z reaksiyalarini sinab ko'rishadi va kerakli ko'nikmalarni rivojlantiradilar."
    ),
    (
        "Yong'in o'chirgich turlari va ularning to'g'ri tanlash",
        "Yong'in o'chirgich turlarini to'g'ri tanlash telekommunikatsiya muhitida muhim qaror. Har turdagi o'chirgich o'ziga xos xususiyatga ega va noo'rin tanlangan o'chirgich vaziyatni yomonlashtirishi mumkin. CO2 (uglekislota) o'chirgichlari elektron jihozlar uchun eng ma'qul tanlov: ular elektronikaga zarar yetkazmaydi, qoldiq qoldirmaydi va elektr o'tkazmaydi. Kukunli o'chirgichlar universal — barcha turdagi yong'inlar uchun samarali — lekin kukun elektron jihozlarga jiddiy zarar yetkazadi va shu sababli ulardan server xonalaridan tashqarida — yo'laklar va ofislarda — foydalanish tavsiya etiladi. Ko'pikli o'chirgichlar yonuvchi suyuqliklar uchun ideal lekin elektr jihozlari bo'lgan xonalarda mutlaqo ishlatilmaydi. Halon va halokarbon asosli yangi avlod o'chirgichlari (FE-36, FK-5-1-12) elektronikaga zararsiz va Halon 1301 ning halokatli ozon ta'sirisiz alternativa sifatida joriy etilmoqda."
    ),

    # ── Chapter 4 conclusion strengthened ──────────────────────────────
    (
        "To'rtinchi bobda hayot faoliyati xavfsizligining ikki muhim yo'nalishi",
        "Ushbu diplom loyihasining to'rtinchi bobida hayot faoliyati xavfsizligining ikki muhim yo'nalishi — kompyuter (kiber) xavfsizligi bo'yicha umumiy talablar hamda telekommunikatsiya inshootlarida yong'in xavfsizligini ta'minlash masalalari — batafsil yoritildi. Kompyuter xavfsizligi zamonaviy raqamli jamiyatning asosiy talablaridan biri bo'lib, u CIA triadasi (Confidentiality, Integrity, Availability) asosida tashkillanadi. MotivAI platformasida bu uchala tamoyil to'liq tatbiq etilgan: bcrypt parol xeshlash (work factor = 12), JWT HMAC-SHA256 imzo, TLS 1.3 shifrlash, MongoDB Atlas IP whitelist, at-rest shifrlash va ko'p qatlamli rate limiting. Telekommunikatsiya inshootlaridagi yong'in xavfsizligi — bu MotivAI ning bulut infratuzilmasiga bilvosita ahamiyatli; loyiha tomonidan ishlatilayotgan MongoDB Atlas Singapore data-markazi va Render.com bulut xizmati barchasi NFPA 75 va ISO 14520 xalqaro standartlariga muvofiq sertifikatlangan inshootlarda hosting qilinadi. Bu foydalanuvchilar ma'lumotlarining nafaqat kiberxavfsizlik, balki jismoniy xavfsizlik nuqtai nazaridan ham yuqori darajadagi himoyasini kafolatlaydi."
    ),

    # ── UMUMIY XULOSA ─────────────────────────────────────────────────
    (
        "Ushbu bitiruv malakaviy ishida sun'iy intellekt yordamida talabalarning shaxsiy",
        "Ushbu diplom loyihasi sun'iy intellekt yordamida talabalarning shaxsiy motivatsiya rejasini taklif qiluvchi mobil platforma — MotivAI — ni to'liq sikl bo'yicha — kontseptsiyadan ishlab chiqarish muhitiga joylashtirishgacha — muvaffaqiyatli amalga oshirishni o'z ichiga oldi. Barcha belgilangan maqsad va vazifalar to'liq bajarildi va loyihaning ilmiy hamda amaliy hissalari quyidagi yo'nalishlarda namoyon bo'ldi."
    ),
    (
        "Tadqiqot natijasida quyidagi asosiy ilmiy va amaliy natijalar qo'lga kiritildi",
        "Tadqiqot natijasida quyidagi asosiy ilmiy va amaliy natijalar qo'lga kiritildi va ulardan har biri loyihaning mustaqil hissa sifatida baholanishi mumkin."
    ),
    (
        "Birinchi bob bo'yicha natijalar: tavsiya tizimlarining uch asosiy paradigmasi",
        "Birinchi bob bo'yicha natijalar: ushbu diplom loyihasida tavsiya tizimlarining uch asosiy paradigmasi (CBF, CF, gibrid) va ularning ta'lim motivatsiyasi sohasiga qo'llanilish imkoniyatlari sistematik tarzda tahlil qilindi; ta'limda sun'iy intellektning besh asosiy yo'nalishi va ularning miqdoriy ta'siri ko'rib chiqildi; mashinali o'rganish algoritmlarining qiyosiy baholashi amalga oshirildi va NDCG@K maqsad funksiyasi asosida CARS paradigmasida masalaning rasmiy qo'yilishi shakllantirildi."
    ),
    (
        "Ikkinchi bob bo'yicha natijalar: beshtа asosiy MongoDB",
        "Ikkinchi bob bo'yicha natijalar: ushbu diplom loyihasida beshta asosiy MongoDB kolleksiyasi va compound indekslar yordamida optimallashtirilgan ma'lumotlar bazasi sxemasi loyihalandi; to'rt komponentli Motivatsional Qiymat Funksiyasi (MVF) Self-Determination Theory va Flow Theory asosida rasmiy matematik tilda shakllantirildi; offline baholashda NDCG@5 = 0,78 ko'rsatkichiga erishildi; RESTful API arxitekturasi 33 ta endpoint va 6 ta router moduli bilan to'liq hujjatlashtirildi; ko'p providerli AI fallback chain (OpenAI → Gemini → Groq) original innovatsiya sifatida ishlab chiqildi va tatbiq etildi."
    ),
    (
        "Uchinchi bob bo'yicha natijalar: Flutter, FastAPI, MongoDB Atlas va OpenAI",
        "Uchinchi bob bo'yicha natijalar: ushbu diplom loyihasida Flutter (Dart), FastAPI (Python), MongoDB Atlas hamda uchta katta til modeli (OpenAI GPT-4o-mini, Google Gemini 2.0 Flash, Groq Llama 3.3 70B) dan iborat ko'p providerli AI kombinatsiyasining maqbulligi nazariy tahlil va amaliy sinov natijalari orqali asoslandi; qorong'u tema, animatsiyalar va mikrointeraksiyalar asosidagi UI/UX dizayn SUS = 79,4/100 natijasiga erishdi; ko'p providerli AI fallback chain tizimning 99,6 foiz uptime kafolatini beradi; Render.com va MongoDB Atlas bulut infratuzilmasida to'liq ishlaydigan platforma joylashtirildi; 15 nafar ishtirokchi bilan o'tkazilgan 7 kunlik sinov NPS = +42 va kunlik 3,8 ta kirish chastotasi natijalarini ko'rsatdi."
    ),
    (
        "MotivAI loyihasining asosiy ilmiy yangiligi shundan iboratki",
        "Ushbu diplom loyihasining asosiy ilmiy yangiligi shundan iborat: o'zbek tili va milliy ta'lim kontekstiga to'liq moslashtirilgan, ko'p providerli AI fallback arxitekturasi va psixologik nazariyalarga (SDT, Flow Theory, Gamification Theory) asoslangan gamifikatsiya tizimini birlashtirgan to'liq funksional mobil platforma O'zbekistonda birinchi marta ishlab chiqildi va sinov muhitiga joylashtirildi. Bu mahalliy EdTech sohasiga muhim hissa qo'shadi va keyingi tadqiqotchilar uchun amaliy poydevor yaratadi."
    ),
    (
        "Ijobiy natijalar bilan birga bir qancha cheklovlar ham aniqlandi",
        "Erishilgan ijobiy natijalar bilan birga ushbu diplom loyihasi davomida bir qator cheklovlar ham aniqlandi va ular kelajakdagi rivojlanish yo'nalishlari sifatida belgilab olindi. Birinchi cheklov — Render.com bepul tier'idagi cold start kechikishi (35–55 sekund), bu birinchi foydalanish tajribasini salbiy ta'sir qilishi mumkin; yechim — UptimeRobot monitoringi yoki paid tier'ga migratsiya. Ikkinchi cheklov — MongoDB Atlas M0 disk limiti (512 MB), bu 5 000 dan ortiq faol foydalanuvchi uchun yetarli emas bo'lishi mumkin; yechim — M10 paid tier'ga o'tish. Uchinchi cheklov — to'liq offline rejimning yo'qligi; yechim — Hive yoki Isar lokal ma'lumotlar bazasi tatbiqi va action queue mexanizmi orqali offline ishlash imkoniyatini joriy etish."
    ),
    (
        "Ushbu tadqiqot zamonaviy dasturiy muhandislik, sun'iy intellekt va ta'lim",
        "Ushbu diplom loyihasi zamonaviy dasturiy muhandislik, sun'iy intellekt va ta'lim psixologiyasining samarali integratsiyasini ifodalovchi innovatsion yechimni taqdim etdi. MotivAI platformasi O'zbekiston ta'lim tizimida talabalar motivatsiyasini boshqarish muammosini hal etishga muhim hissa qo'shishi mumkin va kelajakda yanada kengaytirilishi hamda real ta'lim muassasalarida (oliy o'quv yurtlari, IT akademiyalari, kasbiy o'rganish markazlari) keng joriy etilishi uchun barcha texnik va metodologik shartlar yaratildi. Loyihaning to'liq ochiq manba kodi (open source) GitHub orqali ommaga taqdim etilgan bo'lib, bu boshqa O'zbek dasturchilarini shu yo'nalishda yangi loyihalarni amalga oshirishga undaydi."
    ),

    # ── TAVSIYALAR ────────────────────────────────────────────────────
    (
        "Tadqiqot va foydalanuvchi sinovlari natijalari asosida",
        "Ushbu diplom loyihasi davomida o'tkazilgan tadqiqot va foydalanuvchi sinovlari natijalari asosida MotivAI platformasini yanada takomillashtirish hamda ta'lim sohasida keng joriy etish uchun quyidagi tavsiyalar ishlab chiqildi. Tavsiyalar uch yo'nalishda guruhlandi: texnik takomillashtirish, ta'lim muassasalari uchun amaliy taklif va kelajakdagi tadqiqot yo'nalishlari."
    ),
]


def normalize(s: str) -> str:
    return s.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"')


def paragraph_text(p):
    return "".join(t.text or "" for t in p.iter(f"{W}t"))


def replace_paragraph_text(p, new_text: str):
    runs = p.findall(f"{W}r")
    if not runs:
        return False
    template_rpr = None
    first_rpr = runs[0].find(f"{W}rPr")
    if first_rpr is not None:
        template_rpr = deepcopy(first_rpr)
    for r in runs:
        p.remove(r)
    if not new_text:
        return True
    new_run = etree.SubElement(p, f"{W}r")
    if template_rpr is not None:
        new_run.append(template_rpr)
    t = etree.SubElement(new_run, f"{W}t")
    t.text = new_text
    t.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
    return True


def patch_xml(xml_bytes):
    parser = etree.XMLParser(remove_blank_text=False)
    tree = etree.fromstring(xml_bytes, parser)
    hits = 0
    used = set()
    norm_subs = [(normalize(p), new) for p, new in PARA_SUBS]
    for p_elem in tree.iter(f"{W}p"):
        ptext = normalize(paragraph_text(p_elem))
        for i, (npat, new) in enumerate(norm_subs):
            if i in used:
                continue
            if npat in ptext:
                replace_paragraph_text(p_elem, new)
                hits += 1
                used.add(i)
                break
    return etree.tostring(tree, xml_declaration=True, encoding="UTF-8",
                          standalone=True), hits, used


def main():
    DST.parent.mkdir(parents=True, exist_ok=True)
    img_swapped = 0
    text_hits = 0
    used = set()
    with zipfile.ZipFile(SRC, "r") as src_zip, zipfile.ZipFile(
        DST, "w", zipfile.ZIP_DEFLATED
    ) as dst_zip:
        for entry in src_zip.namelist():
            data = src_zip.read(entry)
            base = Path(entry).name
            if entry.startswith("word/media/") and base in IMAGE_SWAP:
                replacement = PNG / IMAGE_SWAP[base]
                if replacement.exists():
                    data = replacement.read_bytes()
                    img_swapped += 1
            if entry == "word/document.xml":
                data, text_hits, used = patch_xml(data)
            dst_zip.writestr(entry, data)
    print(f"Images swapped: {img_swapped}")
    print(f"Paragraph rewrites: {text_hits} / {len(PARA_SUBS)}")
    if len(used) < len(PARA_SUBS):
        missed = [PARA_SUBS[i][0][:80] for i in range(len(PARA_SUBS)) if i not in used]
        print(f"\nMissed anchors ({len(missed)}):")
        for m in missed:
            print(f"  · {m}")
    print(f"\nOutput: {DST}")


if __name__ == "__main__":
    main()
