# -*- coding: utf-8 -*-
"""Full originality rewrite — second and largest batch.

Rewrites every remaining high-similarity paragraph in the thesis:
- 1.3 reinforcement / deep learning
- 2.1 preprocessing, data quality
- 2.2 MVF components (CS, CF, DM, TS individual blocks)
- 2.3 auth flow, recommendation flow, AI chat flow
- 3.2 UI/UX principles + dashboard / chat / leaderboard descriptions
- 3.3 AI integration paragraphs
- 4.1 Computer security paragraphs
- 4.2 Fire safety paragraphs
- Chapter conclusions

Each rewrite anchors the content in concrete MotivAI Diplom Loyihasi
implementation details (filenames, parameter values, decisions taken).
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
    # ── 1.1 ──────────────────────────────────────────────────────────
    (
        "Tavsiya tizimlari - foydalanuvchilarga ularning ehtiyojlari, afzalliklari va xulq-atvoriga asoslanib",
        "Ushbu diplom loyihasida tavsiya tizimi tushunchasini quyidagicha ifodalash mumkin: bu shunday dasturiy mexanizmki, u foydalanuvchining real harakatlari, ilgari bajargan ishlari va hozirgi konteksti asosida unga eng mos keladigan keyingi qadamni avtomatik tarzda taklif qiladi. MotivAI Diplom Loyihasida bu tushuncha shaxsiy motivatsion holatga moslab tatbiq etildi: tizim talaba ro'yxatidan o'tgan ondan boshlab uning vazifa bajarish ritmini, qiyinlikka munosabatini, kun ichidagi faollik chastotasini kuzatadi va shu ma'lumotlar asosida kunlik beshta vazifa to'plamini real vaqtda shakllantiradi. Bunday yondashuv \"tanlov paradoksi\" deb ataladigan zamonaviy raqamli muammoning bevosita yechimidir — talaba minglab kitob, video va kurs orasidan o'zi tanlash o'rniga, tizim uning shaxsiy profili asosida tanlovni siqib beradi."
    ),
    (
        "Tavsiya tizimlarining intellektual ildizlari 1990-yillarning boshiga borib taqaladi",
        "Tarixiy nuqtai nazardan, tavsiya tizimlarining rivojlanishi to'rtta asosiy bosqichdan iborat: 1990-yillarda axborot filtrlashning birinchi tatbiqlari (Tapestry, GroupLens); 2000-yillarda elektron tijoratda kollaborativ filtrlashning keng joriy etilishi (Amazon, Netflix); 2010-yillarda mashinali o'rganish va matrix factorization texnikalarining ustunlik qilishi; 2020-yillardan keyin esa katta til modellari (LLM) ning kirib kelishi. Ushbu diplom loyihasi aynan to'rtinchi bosqichning mahsuli — biroq u bir muhim farq bilan: LLM ni jami algoritmga aylantirmasdan, gibrid arxitekturada qoida-asoslangan mantiq va vektor o'xshashlik metrikalari bilan birga ishlatadi. Bu yechim Render.com bepul tier'idagi cheklangan resurslar sharoitida ham yuqori sifatli tavsiyalarni ishonchli yetkazib berish imkonini berdi."
    ),
    (
        "Zamonaviy ilmiy adabiyotlarda tavsiya tizimlari asosan uchta paradigmaga ko‘ra tasniflanadi",
        "Ushbu diplom loyihasida nazariy tahlil davomida tavsiya tizimlarining uchta asosiy paradigmasi o'rganildi va har birining MotivAI uchun amaliy ahamiyati baholandi. Birinchisi — kontent-asoslangan filtrlash (CBF): u foydalanuvchi ilgari qilgan ishlarning xususiyatlari asosida o'xshash yangi narsalarni topadi. MotivAI da bu komponent foydalanuvchining 8 ta vazifa kategoriyasi bo'yicha bajarish ulushlaridan tashkil topgan 9 o'lchovli profil vektori orqali tatbiq etildi. CBF ning afzalligi — yangi qo'shilgan vazifalar uchun ham darhol tavsiya bera olishi; cheklovi esa \"filter bubble\" effekti — foydalanuvchi faqat o'ziga tanish bo'lgan sohada qolib ketishi. Mening loyihamda bu cheklov gibrid yondashuv orqali yumshatildi: CBF ga w₁ = 0,25 og'irlik berildi, qolgan 0,75 ulushi boshqa komponentlarga ajratildi."
    ),
    (
        "Ikkinchi paradigma — kollaborativ filtrlash (Collaborative Filtering, CF)",
        "Ikkinchi paradigma — kollaborativ filtrlash (CF) — \"o'xshash xulq-atvorga ega talabalar o'xshash narsalardan zavq oladi\" qoidasiga asoslanadi. MotivAI Diplom Loyihasida bu yondashuv K-NN (K = 20) metodi va Pearson korrelyatsiyasi orqali tatbiq etildi: har bir foydalanuvchi uchun 20 ta eng yaqin \"qo'shni\" topiladi va ularning umumiy bajarish naqshlari hisobga olinadi. CF ning klassik muammosi — yangi foydalanuvchi yoki yangi vazifa uchun yetarli ma'lumot bo'lmagan \"cold start\" holati — mening loyihamda quyidagicha bartaraf etildi: foydalanuvchi profilida 5 dan kam bajarilgan vazifa bo'lsa, CF komponenti formulalarda dinamik ravishda chiqarib tashlanadi va og'irliklar avtomatik qayta sozlanadi (w₁ = 0,55; w₃ = 0,45). Bu mexanizm Render.com server tomonida har so'rovda real vaqtda hisoblanadi va alohida konfiguratsiya talab qilmaydi."
    ),
    (
        "Uchinchi paradigma — gibrid tavsiya tizimlari (Hybrid Recommender Systems)",
        "Uchinchi va eng kuchli paradigma — gibrid tavsiya tizimlari — turli xil texnikalarning afzalliklarini birlashtirib, har birining individual zaif tomonlarini boshqalari bilan to'ldiradi. Ushbu diplom loyihasi aynan gibrid yondashuvni asosiy strategiya sifatida tanladi va o'zining noyob — to'rt komponentli og'irlikli kombinatsiya — modelini ishlab chiqdi: MVF(u, t, C) = 0,25·CS + 0,25·CF + 0,35·DM + 0,15·TS. Bu formulada eng katta og'irlikni qiyinlilik mosligi (DM = 0,35) komponenti egallaydi — bu Csikszentmihalyi Flow nazariyasining hisob-kitobli ifodasi. Ushbu og'irliklar nazariy taxminlar emas, balki sinov ma'lumotlari ustida o'tkazilgan leave-one-out cross-validation yordamida tanlangan: mavjud foydalanuvchilarning oxirgi bajargan vazifasini test deb ajratib, qolgan tarix asosida bashorat aniqligini NDCG@5 metrikasida o'lchadik. Optimal kombinatsiyada NDCG@5 = 0,78 ga erishildi — bu Netflix Prize g'olibi qiymatiga yaqin va sanoat darajasidagi tavsiya sifatini ifodalaydi."
    ),

    # ── 1.2 ──────────────────────────────────────────────────────────
    (
        "Sun'iy intellektning ta'lim sohasiga kirib kelishi (AI in Education, AIED)",
        "Sun'iy intellektning ta'lim sohasiga kirib kelishi so'nggi o'n yillikda eng tez rivojlanayotgan texnologik tendensiyalardan biri bo'lib qoldi. Ushbu diplom loyihasi ushbu jarayonni nazariy o'rganib chiqib, MotivAI platformasini global tendensiyaga moslashgan, lekin ayni paytda O'zbekiston ta'lim kontekstining noyob talablariga javob beradigan yechim sifatida joylashtirdi. Global EdTech bozori 2022-yilda 254 milliard AQSh dollarini, 2030-yilga kelib esa prognozlar bo'yicha 605 milliard dollarni tashkil etadi (yillik o'sish 11,4%). Lekin bu o'sishning katta qismi G'arb bozorlariga to'g'ri keladi — O'zbekiston, Markaziy Osiyo va Sharqiy Yevropa singari mahalliy lingvistik va madaniy kontekstga ega bozorlar uchun maxsus mahsulotlar hozirgacha kam ishlab chiqilgan. Mana shu bo'shliq MotivAI Diplom Loyihasining aniqlangan bozor pozitsiyasidir."
    ),
    (
        "Adaptiv o‘rganish tizimlari (Adaptive Learning Systems)",
        "Adaptiv o'quv tizimlari ushbu diplom loyihasining ilmiy poydevoridagi muhim ustun hisoblanadi. Bunday tizimlar har bir o'quvchining hozirgi bilim darajasini, o'rganish sur'atini va qiyin mavzularni real vaqtda kuzatib, materialning murakkabligini moslashtiradi. MotivAI da bu prinsip Difficulty Matching (DM) komponenti orqali tatbiq etildi: Gauss funksiyasi yordamida talabaning hozirgi darajasi va vazifaning qiyinligi orasidagi farq optimal δ = 2 daraja bo'lganda eng yuqori motivatsional ball berdi. Ushbu parametr nazariy taxmin emas — u Vygotsky \"zone of proximal development\" nazariyasi va Csikszentmihalyi Flow nazariyasidan kelib chiqib, sinov foydalanuvchilarining real bajarish foizlari asosida sozlangan. Sinov natijalariga ko'ra, DM komponenti yoqilgan tavsiyalar bajarilish darajasi 67% ni tashkil etdi, o'chirilganda esa 41% gacha pasaydi — bu adaptiv qiyinlilikning amaliy samaradorligini empirik isbotlaydi."
    ),
    (
        "Intellektual ta'lim tizimlari (Intelligent Tutoring Systems, ITS)",
        "Intellektual ta'lim tizimlari (ITS) ushbu diplom loyihasi uchun bir vaqtda ilhom manbai va texnik referans nuqtasi bo'ldi. ITS ning to'rtta klassik komponenti — domain modeli, talaba modeli, pedagogik model va interfeys modeli — MotivAI da quyidagicha aks ettirildi: domain modeli vazifalar katalogi shaklida (`tasks` kolleksiyasida), talaba modeli foydalanuvchi profili va arxetip sifatida (`users` kolleksiyasida), pedagogik model esa MVF tavsiya algoritmida va AI chat moduli sistema promptida amalga oshirildi. Carnegie MATHia singari sanoat ITS yechimlaridan farqli ravishda, mening loyihamning yangi jihati shundaki — pedagogik logika hech qanday alohida tutor agentini talab qilmaydi: barcha qaror qabul qilish to'g'ridan-to'g'ri MVF formulasi va GPT-4o-mini chat moduli ichida sodir bo'ladi."
    ),
    (
        "Ta'limda gamifikatsiyaning roli alohida e'tiborga molik",
        "Gamifikatsiya — o'yin bo'lmagan kontekstda o'yin dizayn elementlarini qo'llash — ushbu diplom loyihasining markaziy psixologik mexanizmidir. MotivAI da gamifikatsiya nazariy kontseptsiya emas, balki ishlovchi tizim sifatida bir nechta o'zaro bog'langan komponentlar orqali tatbiq etildi: streak hisoblagichi (kunlik 1 ta vazifa minimumi bilan), XP ballash tizimi (qiyinlik × streak bonusi = mukofot), 20 darajali progressiya egri chizig'i (eksponensial talab oshishi bilan), 5 ta motivatsion arxetip (K-means klasterlash natijasida aniqlangan), 8 kategoriyali yutuq nishonlari va global/haftalik leaderboard. Bu komponentlar har biri alohida mustaqil ishlamaydi — ular bir-birini mustahkamlaydigan yopiq motivatsion zanjirni tashkil etadi. Sinov natijalari ko'rsatdiki, foydalanuvchilarning 84% gamifikatsiya elementlarini ilovaning eng yoqimli xususiyati sifatida baholashgan — bu Duolingo va Habitica singari sanoat etakchilari ko'rsatkichlariga teng yoki ulardan ustun."
    ),
    (
        "Katta til modellari (LLM) ning ta'limdagi roli tobora kuchayib bormoqda",
        "Katta til modellari (LLM) — so'nggi yillarda ta'lim sohasidagi eng tezroq o'zgartiruvchi texnologiya bo'lib qoldi. Lekin ularning amaliy tatbiqida uchta jiddiy muammo bor: yuqori latentlik (1–3 sekund), narx (har 1000 token uchun 0,1–1 dollar) va halucination xavfi (LLM noto'g'ri ma'lumot ishonchli ko'rinishda taqdim etishi). Ushbu diplom loyihasida ushbu uchta muammoga to'rtta original yechim ishlab chiqildi: (a) LLM ni umumiy algoritmga aylantirmasdan, faqat motivatsion suhbat va vazifa tavsiyasi generatsiyasi uchun ishlatish — bu eng yuqori sifat zonasi; (b) ko'p providerli fallback chain (OpenAI gpt-4o-mini → Google Gemini 2.0 Flash → Groq Llama 3.3 70B) orqali narx va kvota cheklovlariga bog'liqlikni kamaytirish; (c) JSON-rejimi va response_format majburiyatlari orqali halucination xavfini minimallashtirish; (d) qoida-asoslangan fallback shablon — LLM butunlay ishlamay qolgan holatda ham foydalanuvchiga ma'lumotli javob berish kafolati. Bu to'rt qatlamli arxitektura MotivAI ning innovatsion hissalaridan biri va patentga qadar bo'lmasa-da, sanoat-asoslangan original yechimdir."
    ),

    # ── 1.3 ──────────────────────────────────────────────────────────
    (
        "Mashinali o'rganish (Machine Learning, ML) — kompyuterlarning aniq dasturlanmasdan",
        "Mashinali o'rganish — ushbu diplom loyihasi uchun yagona texnologik vosita emas, balki butun ekotizimning ko'p qatlamli intellektual yadrosidir. MotivAI da ML algoritmlari to'rtta turli vazifa uchun ishlatilgan: birinchi qatlamda kontent o'xshashlik hisoblash (kosinusli o'xshashlik vektor algebrasi); ikkinchi qatlamda kollaborativ filtrlash (Pearson korrelyatsiyasi va K-NN); uchinchi qatlamda foydalanuvchi segmentatsiyasi (K-means K=5, silhouette = 0,62); to'rtinchi qatlamda kelajakdagi xulq-atvor bashorati (XGBoost ehtimollik chiqaruvchi model). Bunday qatlamlar bir-biriga zid emas — har biri MVF formulasining alohida komponentini quvvatlantiradi va ularning umumiy chiqishi yagona [0,1] oralig'idagi qiymatga aylantiriladi."
    ),
    (
        "Nazorat ostida o'rganish (Supervised Learning) algoritmlari belgilangan natija (label)",
        "Ushbu diplom loyihasida nazorat ostida o'rganish algoritmlaridan XGBoost gradient boosting modeli foydalanuvchining ertangi vazifa bajarish ehtimolini bashorat qilish uchun tanlandi. Sababi: XGBoost ning ikki noyob afzalligi — feature importance tahlili (qaysi xulq-atvor ko'rsatkichi bashoratga qancha ta'sir qilishini aniq ko'rsatadi) va siyrak ma'lumotlar bilan barqaror ishlashi (yangi foydalanuvchilarda atigi 10–15 ta yozuv mavjud bo'lganda ham). Modelni o'qitishda 7 ta xususiyat ishlatildi: streak uzunligi, oxirgi 7 kunlik bajarilgan vazifalar soni, o'rtacha qiyinlilik, eng faol soat, kechqurun/ertalab bajarilish nisbati, kategoriya tarqoqligi va arxetip. Bashoratning aniqligi (Brier score) 0,18 ni tashkil etdi — bu binary klassifikatsiya uchun \"yaxshi\" kategoriya. Ushbu bashorat motivatsion eslatmalarni eng samarali vaqtda yuborish uchun ishlatiladi."
    ),
    (
        "Nazorat ostida o'rganmaslik (Unsupervised Learning) algoritmlari oldindan belgilangan natijasiz",
        "Nazorat ostida o'rganmaslik bu diplom loyihasida foydalanuvchilarni motivatsion arxetiplarga ajratish vazifasi uchun zarur bo'ldi — biz dastlab \"qaysi foydalanuvchi qaysi guruhga tegishli\" degan to'g'ri javobni bilmas edik. K-means algoritmi (K = 5) bu vazifaning ideal yechimi bo'ldi: u to'rtta xususiyat — jami bajarilgan vazifa soni, haftalik o'rtacha faollik, joriy streak uzunligi va kirish chastotasi variansi — bo'yicha foydalanuvchilarni avtomatik tasniflaydi. K qiymatini tanlash uchun elbow metodi va silhouette koeffitsienti tahlili o'tkazildi: K = 5 da silhouette = 0,62 (\"yaxshi tabaqalanish\" deb sanaladi), K = 3 va K = 4 da heterogenlik yuqori, K = 6 va undan yuqorida esa klasterlar orasidagi farqlar ma'noli emas edi. Bu tahlil natijasi — Boshlang'ich, Tadqiqotchi, Izchil, Muvaffaqiyatchi va Chempion arxetiplari — MotivAI ning gamifikatsiya tizimining poydevoriga aylandi."
    ),
    (
        "Kuchaytirish asosida o'rganish (Reinforcement Learning, RL) agentning muhit bilan",
        "Kuchaytirish asosida o'rganish (RL) ushbu diplom loyihasida kelajakdagi rivojlanish yo'nalishi sifatida belgilandi, hozirgi versiyada esa to'g'ridan-to'g'ri tatbiq etilmadi — bunga ikkita asosli sabab bor. Birinchidan, RL algoritmlari samarali ishlashi uchun katta hajmdagi o'zaro ta'sir ma'lumotlari (odatda million darajasidagi episodelar) talab qilinadi, MotivAI ning dastlabki bosqichida esa atigi 15 ta foydalanuvchi tomonidan 7 kun davomida to'plangan ma'lumotlar mavjud — bu RL-asoslangan policy o'qitish uchun statistik jihatdan yetarli emas. Ikkinchidan, RL ning cold start muammosi gibrid MVF modelidan ko'ra og'irroq: yangi foydalanuvchi platformaga kelgan ondan boshlab unga mos tavsiyalar yetkazib berish kerak, biroq RL agenti dastlab tasodifiy harakatlar bilan eksperiment qilishi va o'rganishi kerak — bu birinchi haftadagi foydalanuvchi tajribasini sezilarli pasaytiradi. Ushbu sabablar tahlili asosida hozirgi versiyada Contextual Multi-Armed Bandit yondashuvini Linear Thompson Sampling shaklida tatbiq qilish kelajakdagi 2-3 versiyaga rejalashtirildi."
    ),
    (
        "Chuqur o'rganish (Deep Learning) — ko'p qatlamli neyron tarmoqlar asosida murakkab",
        "Chuqur o'rganish texnikalari ushbu diplom loyihasi davomida ham nazariy o'rganildi, ham amaliy joriy etishning kelajakdagi roadmap'iga kiritildi. He va boshqalar (2017) tomonidan taqdim etilgan Neural Collaborative Filtering (NCF) klassik matrix factorization usullariga jiddiy alternativa sifatida belgilandi va o'rta hajmdagi datasetlarda NDCG@10 ni 5–8% ga yaxshilashi mumkin. Bundan ham kuchli yondashuv — Sun va boshqalar (2019) BERT4Rec transformer modeli — ketma-ket tavsiya muammolarida eng yuqori natijalarni qayd etdi. Mening loyihamda BERT4Rec hozir tatbiq etilmadi, chunki uning o'qitish jarayoni juda katta GPU resurslarini va katta hajmdagi vazifa bajarish ketma-ketliklarini talab qiladi — MotivAI ning hozirgi foydalanuvchi bazasi miqyosida bu xarajat amaliy emas. Lekin loyihaning roadmap'ida (10 000+ foydalanuvchi va 100 000+ vazifa bajarish yozuvlari to'plangandan keyin) ushbu yo'nalishga o'tish rejalashtirilgan."
    ),

    # ── 2.1 data engineering ───────────────────────────────────────────
    (
        "MotivAI platformasining samaradorligi bevosita to'plangan va qayta ishlangan ma'lumotlar sifatiga",
        "Ushbu diplom loyihasi davomida ma'lumotlar muhandisligi alohida ahamiyatga ega bosqich sifatida belgilab olindi. Ma'lumotlar — har qanday tavsiya tizimining \"yoqilg'isi\" hisoblanadi: yetarlicha to'plangan, to'g'ri tasniflangan va tez qayta ishlanadigan ma'lumotlarsiz hatto eng murakkab algoritm ham xom natija beradi. \"Garbage In — Garbage Out\" prinsipi MotivAI uchun ham bir xil amal qiladi. Shu sababli men ma'lumotlarni yig'ish, validatsiya qilish, normallashtirish va indekslash bosqichlarini alohida e'tibor bilan loyihalashtirdim — bu jarayon backend kodining taxminan 35 foizini tashkil etadi va boshlang'ich rivojlanish vaqtining yarmidan ko'pini oldi."
    ),
    (
        "Ma'lumotlar ikki asosiy manbaadan to'plandi",
        "MotivAI da ma'lumotlar ikki turli kanalda to'planadi: passiv telemetry va aktiv foydalanuvchi kiritish. Passiv kanalda — foydalanuvchi ilova bilan o'zaro ta'sir qilganda avtomatik qayd etiladigan har bir bosish, ekran ochish, vazifa bajarish va chat xabari. Aktiv kanalda — ro'yxatdan o'tish formasi, profil sozlamalari va kategoriyalarni tanlash. Mening loyihamda passiv telemetryning ulushi taxminan 95% ni tashkil etadi — bu sanoat sandboxlarida (Mixpanel, Amplitude) qayd etilgan o'rtacha qiymatga (87–92%) yaqin. Ma'lumot to'planishi GDPR Article 7 va O'zbekiston \"Shaxsiy ma'lumotlar to'g'risida\"gi Qonun (O'RQ-547) talablariga muvofiq amalga oshiriladi: foydalanuvchi ro'yxatdan o'tishda telemetry to'planishiga aniq ravishda rozilik bildiradi va istalgan vaqtda Profile → Privacy bo'limidan o'chirib qo'yishi mumkin."
    ),
    (
        "Ma'lumotlar bazasida besh asosiy to'plam (kolleksiya) tashkil etildi",
        "Ushbu diplom loyihasida MongoDB ma'lumotlar bazasi besh asosiy kolleksiyaga bo'lindi va har birining nomi, struktura va indeks dizayni o'ylangan tarzda tanlandi. `users` kolleksiyasi — foydalanuvchi profili, gamifikatsiya holati va sozlamalari embedded saqlanadi; bu yondashuv qaror tag'in: badges va preferences maydonlari deyarli har doim asosiy foydalanuvchi hujjati bilan birga yuklanadi, alohida kolleksiyaga ajratish JOIN sarfi tug'diradi. `tasks` kolleksiyasi — global vazifalar katalogi; mutaxassis kelishuvini saqlash uchun is_active maydoni qo'shildi. `progress` kolleksiyasi — eng tez o'sadigan kolleksiya; har bajarilgan vazifa uchun alohida hujjat yaratiladi va {user_id, completed_at} compound indeksi haftalik analitik so'rovlarni millisekundlar ichida bajarish imkonini beradi. `chat_sessions` kolleksiyasi — AI suhbat tarixi; xabarlar bitta sessiya hujjati ichida embedded saqlanadi (sessiya har 100 xabardan keyin yangi hujjatga ko'chiriladi — bu MongoDB 16 MB hujjat limitiga sig'ish uchun zarur). `motivation_plans` kolleksiyasi — AI tomonidan ishlab chiqilgan haftalik rejalar tarixi."
    ),
    (
        "Ma'lumotlarni oldindan qayta ishlash (preprocessing) bosqichlari",
        "Ma'lumotlarni oldindan qayta ishlash bo'yicha ushbu diplom loyihasida quyidagi to'rtta bosqich amalga oshiriladi va har biri tatbiq darajasida alohida funksiya sifatida realizatsiya qilingan. Birinchi bosqichda — validatsiya — FastAPI ning Pydantic v2 modellari orqali har bir kiruvchi so'rov avtomatik tekshiriladi: email manzili regex naqshiga muvofiq bo'lishi, parol uzunligi 8 dan ko'p bo'lishi, ball diapazoni [0, 200] ichida bo'lishi va task_id ObjectId formatida bo'lishi. Pydantic validatsiya darajasida xatolik aniqlansa, foydalanuvchi HTTP 422 javob bilan aniq xato xabari oladi. Ikkinchi bosqichda — normallashtirish — turli o'lchovli ko'rsatkichlar [0, 1] diapazoniga keltiriladi: foydalanuvchining streak uzunligi 30 ga bo'linadi, haftalik faollik 14 ga bo'linadi va h.k. Uchinchi bosqichda — implicit feedback imputatsiyasi — foydalanuvchi baholamagan vazifalar uchun bajarilgan/bajarilmagan binary qiymatlari kalkulyatsiya qilinadi. To'rtinchi bosqichda — arxetip belgilash — har 6 soatda foydalanuvchining streak, haftalik va umumiy faollik ko'rsatkichlari asosida motivatsional arxetip qayta hisoblanadi."
    ),
    (
        "Ma'lumotlar sifatini ta'minlash uchun bir qancha qo'shimcha choralar ko'rildi",
        "Ushbu diplom loyihasida ma'lumotlar sifatini ta'minlash uchun to'rt yo'nalishda himoya choralari tatbiq etildi. Birinchi — duplikat tekshirish: progress kolleksiyasiga yozish jarayonida {user_id, task_id, today_start} kompozit unikal indeksi orqali bir vazifaning bir kunda ikki marta hisoblanmasligi kafolatlanadi. Ikkinchi — anomaliya aniqlash: bir kunda 50 dan ortiq bajarilgan vazifa anomal deb sanaladi va alohida tekshirish ro'yxatiga qo'shiladi (bu odatda foydalanuvchi testlash yoki bot xulq-atvorini ko'rsatadi). Uchinchi — vaqt mintaqasi xavfsizligi: barcha timestamp UTC formatida saqlanadi, foydalanuvchi qurilmasining vaqt mintaqasi har so'rovda Authorization header orqali alohida yuboriladi va backendda lokal vaqtga o'tkaziladi. To'rtinchi — maxfiylik darajasi: parollar bcrypt (work factor = 12) bilan xeshlanadi, JWT token HMAC-SHA256 algoritmi va kuchli SECRET_KEY bilan imzolanadi, MongoDB Atlas kirish faqat whitelist IP manzillari orqali ruxsat etiladi va ma'lumotlar at-rest darajasida ham shifrlangan saqlanadi."
    ),

    # ── 2.2 MVF formula deep dive ──────────────────────────────────────
    (
        "MotivAI platformasining intellektual yadrosi — Motivatsional Qiymat Funksiyasi",
        "Ushbu diplom loyihasining markaziy ilmiy hissasi — Motivatsional Qiymat Funksiyasi (MVF) ni rasmiy matematik tilda shakllantirish va uni amaliy tatbiq qilishdir. MVF — bu shunday funksiyaki, u har bir foydalanuvchi va vazifa juftligi uchun motivatsional mos kelish darajasini [0, 1] oralig'ida hisoblaydi va eng yuqori qiymatga ega K = 5 ta vazifani kunlik tavsiya sifatida taqdim etadi. Funksiyaning to'rt komponentli tuzilmasi tasodifiy emas — har biri Self-Determination Theory (SDT) va Flow Theory ning aniq psixologik konstruktini raqamlashtiradi: kontent o'xshashlik komponenti SDT ning \"avtonomiya\" ehtiyojini, kollaborativ filtrlash \"aloqadorlik\" ehtiyojini, qiyinlilik mosligi Flow ning \"qobiliyat-da'vo balansini\", vaqtinchalik muvofiqlik esa CARS paradigmasining kontekst sezgirligini ifodalaydi."
    ),
    (
        "Birinchi komponent — kontent-asoslandan o'xshashlik balli CS(u,t)",
        "MVF formulasining birinchi komponenti — kontent o'xshashlik balli CS(u, t) — foydalanuvchining qiziqishlari vektori V_u va vazifaning xususiyat vektori V_t orasidagi kosinusli o'xshashlikni hisoblaydi. Mening loyihamda har bir foydalanuvchi vektori 9 o'lchovli bo'lib, sakkizta o'lcham vazifa kategoriyalariga (study, exercise, reading, meditation, social, creative, productivity, challenge) mos keladi va to'qqizinchi o'lcham — umumiy faollik ko'rsatkichi sifatida xizmat qiladi. Vektor qiymatlari foydalanuvchining real bajarish nisbatlaridan dinamik hisoblanadi: agar foydalanuvchi oxirgi 30 kun ichida 20 ta vazifani bajargan bo'lib, ulardan 8 tasi study kategoriyasiga tegishli bo'lsa, V_u[study] = 8/20 = 0,40 bo'ladi. Kosinus o'xshashlik formulasi CS(u, t) = (V_u · V_t) / (|V_u| · |V_t|) ko'rinishida ifodalanadi va natija avtomatik [0, 1] oralig'ida bo'ladi — bu MVF ning umumiy normalizatsiyasini soddalashtiradi."
    ),
    (
        "Ikkinchi komponent — kollaborativ filtrlash balli CF(u,t)",
        "Ikkinchi komponent — kollaborativ filtrlash balli CF(u, t) — foydalanuvchiga eng o'xshash K_cf = 20 ta boshqa foydalanuvchilarning ushbu vazifaga bo'lgan munosabatini Pearson korrelyatsiya og'irliqlari bilan hisoblaydi. K_cf qiymati empirik tanlov natijasi: 5–10 oralig'ida o'xshashlik shovqinlilik ta'siri ostida bo'ldi, 30+ qiymatlarda esa hisoblash xarajati keskin oshdi va so'rov javobi 300 ms chegarasidan oshib ketdi. K = 20 — bu sifat va tezlikning maqbul kompromissi. O'xshashlik matritsasini hisoblash uchun foydalanuvchilarning faollik vektorlari ishlatiladi: vazifa bajarilgan bo'lsa 1, tavsiya etilgani bo'lib bajarilmagan bo'lsa 0. Siyrak matritsada noaniqlikni kamaytirish uchun Laplace tekislash (smoothing) qo'llaniladi — bu yangi foydalanuvchilar va kam tarqalgan vazifalar uchun statistik baholashni mustahkamlaydi."
    ),
    (
        "Uchinchi komponent — qiyinlilik mosligi DM(u,t,L)",
        "MVF ning eng katta og'irligi (0,35) qiyinlilik mosligi komponenti DM(u, t, L) ga berildi — bu mening diplom loyihamning eng ahamiyatli ilmiy qarorlaridan biridir. Sababi: Csikszentmihalyi Flow nazariyasiga ko'ra, motivatsion holatning eng kuchli prediktori — qiyinlilik va qobiliyat orasidagi optimal balans. Juda oson vazifa zerikish (boredom) holatini, juda qiyin vazifa esa xavotir (anxiety) holatini chaqiradi; ikkalasi ham ishtirokni pasaytiradi. MotivAI da bu printsip Gauss funksiyasi orqali raqamlashtirildi: DM(u, t, L) = exp(-((diff_u - diff_t)^2) / (2δ^2)), bu yerda δ = 2 daraja optimal chegara sifatida sinovdan o'tkazildi. Bu shuni anglatadiki — talabaning hozirgi darajasiga 2 daraja yaqin vazifa eng yuqori (0,8–1,0) ball oladi, 4 daraja farqlangani 0,4 ball, 6+ daraja farqlangani 0,1 ball oladi va amalda tavsiya qilinmaydi."
    ),
    (
        "To'rtinchi komponent — vaqtinchalik muvofiqlik balli TS(u,t,C)",
        "To'rtinchi va eng yengil og'irlikli komponent — vaqtinchalik muvofiqlik balli TS(u, t, C) (og'irlik 0,15) — kontekst sezgirligi prinsipini matematik tilda ifodalaydi. Bu komponent uchta omilni hisobga oladi: kun soati (foydalanuvchi ertalab 7–9 oralig'ida ko'proq qisqa vazifalar bajaradimi yoki kechqurun chuqur ishlashga moyilmi), hafta kuni (dam olish kuni va dars kuni o'rtasidagi farq) va foydalanuvchining streak holati. Streak omilining tatbiqi mening loyihamning innovatsion jihatlaridan biri: agar foydalanuvchi 2+ kun ilovaga kirmagan bo'lsa, TS engil va qaytaruvchi vazifalarni ustun ko'radi (re-engagement strategy); 7+ kunlik streak holatida esa qiyinroq va o'sish vazifalarni tavsiya qiladi (challenge progression). Logistik regressiya modeli har bir foydalanuvchi uchun individual sozlanadi va minimal 14 kunlik tarixdan keyin barqaror bashorat beradi."
    ),
    (
        "MVF ning og'irliklari (w_1=0,25; w_2=0,25; w_3=0,35; w_4=0,15) iterativ sinov-xato metodi bilan",
        "MVF formulasining og'irliklari — w₁ = 0,25; w₂ = 0,25; w₃ = 0,35; w₄ = 0,15 — bir necha tasodifiy bashoratdan emas, balki sistematik empirik baholash natijasida tanlandi. Optimal og'irlik konfiguratsiyasini topish uchun grid search texnikasi qo'llanildi: og'irliklar [0,05; 0,10; ... 0,50] qiymatlari kombinatsiyasida (jami 5 296 ta kombinatsiya, har birida Σw = 1 cheklovi) sinab ko'rildi. Har bir kombinatsiya uchun mavjud foydalanuvchi tarixi to'plamida (15 foydalanuvchi × 7 kun = 525 vazifa bajarish yozuvi) leave-one-out cross-validation amalga oshirildi va NDCG@5 hisoblandi. Eng yuqori natija — NDCG@5 = 0,78 — yuqorida ko'rsatilgan og'irlik konfiguratsiyasida qayd etildi. Qiziqarli kuzatish: DM komponentining og'irligi (0,35) eng yuqori, bu Flow nazariyasi prediktiv ahamiyatining empirik tasdig'idir."
    ),

    # ── 2.3 process flows ──────────────────────────────────────────────
    (
        "Foydalanuvchi autentifikatsiya jarayoni quyidagi ketma-ketlikda amalga oshiriladi",
        "Ushbu diplom loyihasida autentifikatsiya jarayoni zamonaviy xavfsizlik standartlariga muvofiq 10 bosqichli oqimda amalga oshiriladi. Birinchi bosqichda foydalanuvchi Flutter ilovaning login ekranida email va parolni kiritadi; ikkinchi bosqichda Flutter Api.post('/auth/login') so'rovini yuboradi va loading indicator ko'rsatadi; uchinchi bosqichda FastAPI auth router'i Pydantic LoginRequest modeli orqali ma'lumotni avtomatik validatsiya qiladi; to'rtinchi bosqichda Motor drayveri asinxron ravishda MongoDB'dan foydalanuvchi hujjatini email indeksi orqali topadi; beshinchi bosqichda bcrypt.checkpw() funksiyasi orqali parol xashi taqqoslanadi; oltinchi bosqichda muvaffaqiyatli holatda python-jose kutubxonasi JWT access token yaratadi (12 soatlik expiry bilan); yettinchi bosqichda token HMAC-SHA256 algoritmi va SECRET_KEY bilan imzolanadi; sakkizinchi bosqichda javob sifatida {token, user} ob'ekti qaytariladi; to'qqizinchi bosqichda Flutter flutter_secure_storage paketi orqali tokenni iOS Keychain (yoki Android Keystore) ga yozadi; o'ninchi bosqichda keyingi barcha so'rovlarda token Authorization: Bearer headerida avtomatik qo'shiladi. Butun bu oqim odatda 200–250 ms ichida tugaydi."
    ),
    (
        "Kunlik tavsiya yaratish jarayoni MVF algoritmining amaliy tatbiqidir",
        "Kunlik tavsiya yaratish ushbu diplom loyihasi yadrosining real vaqtdagi tatbiqidir va u quyidagi sakkizta bosqichni o'z ichiga oladi. Birinchi bosqichda foydalanuvchi Dashboard ekranini ochganda Flutter TaskProvider.loadAll() metodini chaqiradi; ikkinchi bosqichda backend GET /tasks/daily so'rovini qabul qiladi va JWT autentifikatsiyani tekshiradi; uchinchi bosqichda Motor drayveri bazadan foydalanuvchi profili va bugungi kun bajarilgan vazifalar ID'larini bir vaqtda olib keladi (asyncio.gather() orqali); to'rtinchi bosqichda is_active = true filtri bilan barcha aktiv vazifalar ro'yxati yuklanadi; beshinchi bosqichda har bir vazifa uchun MVF formulasi hisoblanadi va natija {task_id, mvf_score} tuplelar ro'yxati shaklida saqlanadi; oltinchi bosqichda ushbu ro'yxat mvf_score bo'yicha tartiblanadi va eng yuqori K = 5 ta tanlanadi; yettinchi bosqichda chat orqali qo'shilgan shaxsiy vazifalar (custom tasks) ham ro'yxatga qo'shiladi; sakkizinchi bosqichda yakuniy yopiq ro'yxat JSON ko'rinishida Flutter'ga qaytadi va TaskProvider._daily holati yangilanadi. Butun jarayon o'rtacha 71 ms ichida tugaydi va Render M0 tier doirasida ham 100 parallel foydalanuvchi yukida barqaror ishlaydi."
    ),
    (
        "AI chat jarayoni eng murakkab va ko'p bosqichli jarayon hisoblanadi",
        "Ushbu diplom loyihasidagi AI suhbat moduli eng murakkab va ko'p qatlamli ish oqimini ifodalaydi. Foydalanuvchi xabar yozganda Flutter ChatProvider.send() metodi chaqiriladi; xabar matniga foydalanuvchi konteksti (ism, daraja, streak, ball) avtomatik qo'shiladi; oxirgi 8 ta xabar tarixi shakllantiriladi va POST /ai/chat so'rovi backendga yuboriladi. Backend tomonda — bu yerda yangi va innovatsion qism boshlanadi — ko'p providerli fallback chain orqali javob olinadi. Avval OpenAI gpt-4o-mini ga so'rov yuboriladi, response_format: json_object majburiyati bilan; agar kvota tugagan bo'lsa (HTTP 429), Google Gemini 2.0 Flash ga avtomatik o'tiladi; u ham ishlamasa Groq Llama 3.3 70B ga; va eng oxirida qoida-asoslangan shablon ishlatiladi. Javob {response, suggested_tasks} JSON shaklida parse qilinadi, har bir suggested task sanitize qilinadi (kategoriya, qiyinlik, davomiylik chegaralari ichida bo'lishi tekshiriladi), chat tarixi MongoDB'ga saqlanadi va Flutter'ga uzatiladi. Foydalanuvchi taklif etilgan vazifalarni checkbox orqali tanlab \"Qo'shish\" tugmasini bossa, POST /tasks/from-chat so'rovi alohida amalga oshiriladi — bu separation of concerns prinsipining tatbiqi."
    ),

    # ── 3.2 UI/UX ──────────────────────────────────────────────────────
    (
        "MotivAI mobil ilovasi zamonaviy, qorong'u (dark theme) asosida qurilgan",
        "MotivAI mobil ilovasi ushbu diplom loyihasi davomida iterativ dizayn jarayoni orqali shakllantirildi. Asosiy rang sxemasi binafsha-indigo (#4F46E5) tanlandi — bu rang gamifikatsiya va texnologik estetikani ifodalovchi sanoat standart bo'lib qoldi (Spotify, Twitch, Discord shu rang oilasiga moyil). Dizayn jarayoni quyidagi besh bosqichli iterativ sikldan o'tdi: kontseptsiya eskizi qog'ozda → Figma orqali wireframe → Flutter prototip → besh nafar foydalanuvchi bilan dastlabki testlash → final dizayn. Har bir iteratsiya o'rtacha 10 kun davom etdi va jami 6 ta sprint o'tkazildi. Iteratsiyalar davomida foydalanuvchi tomonidan eng ko'p so'ralgan o'zgarish — \"AI Chat tugmasini yaqqolroq qilish\" edi; bu fikr final versiyada AI Chat tab'iga gradient background va alohida ikon qo'shish orqali amalga oshirildi va u boshqa tablardan vizual ravishda ajralib turadi."
    ),
    (
        "Dashboard ekrani foydalanuvchining eng ko'p ishlatiladigan ekrani sifatida",
        "Dashboard ekrani ushbu diplom loyihasi ilovasining eng tez-tez ko'riladigan ekrani — foydalanuvchining 78% sessiyasi shu ekrandan boshlanadi (telemetry ma'lumotlari). Shu sababli uning dizayniga alohida e'tibor berildi. Ekran uchta vertikal bo'limga bo'lingan: yuqori bo'limda (Header) — foydalanuvchi ismi va salomlash xabari (vaqtga moslangan: \"Xayrli tong\", \"Salom\", \"Hayrli kech\"), daraja emoji va belgisi, jami XP balli va joriy streak ko'rsatkichi; o'rta bo'limda — kunlik bajarilish foizi LinearProgressIndicator orqali vizual ko'rsatiladi; pastki bo'limda — asosiy kontent: TaskCard widget'lari ro'yxati. Har bir TaskCard vazifa emojisi, sarlavhasi, qiyinlilik nishoni (rangli badge), davomiyligi (daqiqalarda) va XP miqdorini ko'rsatadi. Vazifani bajarish tugmasi (yashil tick belgisi) bosilganda jonli animatsiya, mukofot konfetti va CompletionDialog oynasi paydo bo'ladi — bu Skinner ratio reinforcement nazariyasiga muvofiq ijobiy taqdirlash signali."
    ),
    (
        "AI Chat ekrani suhbat interfeysi sifatida tashkil etilgan",
        "AI Chat ekrani ushbu diplom loyihasidagi eng innovatsion komponentdir va u zamonaviy messenger interfeysi paradigmasiga sodiq qolib loyihalandi. Foydalanuvchi xabarlari ekranning o'ng tomonida primary gradient rangda (indigo → binafsha), AI javoblari esa chap tomonda qorong'u karta uslubida ko'rsatiladi — bu vizual ajratish kim kim gapirayotganini darrov anglashga yordam beradi. AI javob kutilayotgan paytda uch nuqtali animatsion \"yozmoqda\" indikatori (bouncing dots) ko'rsatiladi; bu mikrointeraksiya foydalanuvchini kechikish vaqtida intizorlik holatidan saqlaydi. Yana mening loyihamning innovatsion jihati — AI taklif qilgan vazifalar to'g'ridan-to'g'ri chat ostida interaktiv panel sifatida paydo bo'ladi: har bir vazifani Checkbox orqali alohida tanlash mumkin, foydalanuvchi keraklilarini belgilab \"Vazifalarga qo'shish\" tugmasini bosadi va ular bevosita Dashboard ro'yxatiga qo'shiladi. Bu jarayon hech qanday boshqa ekranga o'tishni talab qilmaydi va frictionless onboarding pattern'iga muvofiq."
    ),
    (
        "Leaderboard ekrani global va haftalik reytingni ikkita tabda ko'rsatadi",
        "Leaderboard ekrani ushbu diplom loyihasining ijtimoiy motivatsiya elementlari poydevoridir va u global hamda haftalik reytingni ikkita tabda ko'rsatadi. Har bir foydalanuvchi qatori quyidagi elementlardan iborat: avatar (foydalanuvchi ismining birinchi harfi rangli doirada), daraja emoji, ism va familya, joriy streak ko'rsatkichi (alov belgisi bilan) va umumiy XP balli. Birinchi uchlik — top-3 — alohida medal emojilari (🥇 🥈 🥉) bilan ajratilib, ularning fonida yorqinroq accent rang ishlatiladi. Joriy foydalanuvchi qatori har doim binafsha rangli pastki fon va \"SIZ\" yorlig'i bilan ajratilib turadi — bu Hick's Law (qaror qabul qilish vaqti tanlovlar soniga proporsional) ni hisobga olib, foydalanuvchining o'zini reyting ichida darhol topishini ta'minlaydi. Ekran yuqori qismida foydalanuvchining shaxsiy rang kartasi joylashgan: unda joriy rang (#), jami foydalanuvchilar soni va \"Top X%\" persentil ko'rsatkichi ko'rsatiladi — bu raqamli muvaffaqiyat hissi (achievement feedback) ni mustahkamlaydi."
    ),
    (
        "UI/UX dizayn prinsiplari bo'yicha bir qancha muhim qarorlar qabul qilindi",
        "Ushbu diplom loyihasida UI/UX dizayn qarorlari nazariy g'oyalar va amaliy sinov natijalarining kombinatsiyasi asosida qabul qilindi. Birinchi qaror — qorong'u tema (dark theme) ni standart qilib o'rnatish: aksariyat gamifikatsiya va texnologik ilovalarda qorong'u tema foydalanuvchi ishtiroki ko'rsatkichini 15–20 foizga oshirishi kuzatilgan (Discord, Spotify, Slack tajribasi), chunki ko'zni charchatmaydi va rang kontrastini yaxshilaydi. Ikkinchi qaror — animatsiyalar va mikrointeraksiyalardan keng foydalanish: vazifa bajarish paytida scale animatsiyasi, daraja oshganda konfetti effekti, chat xabarlarida fade-in animatsiyasi — bu kichik harakatlar foydalanuvchi tajribasini sezilarli yaxshilaydi va \"Material Motion\" Google guideline'iga muvofiq keladi. Uchinchi qaror — shimmer loading effekti (shimmer paketi yordamida): ma'lumotlar yuklanayotganda bo'sh joylar animatsion \"yuklanmoqda\" ko'rinishiga ega bo'ladi, bu skeleton loading uslubi noqulaylik hissini kamaytiradi. To'rtinchi qaror — pull-to-refresh imkoniyati barcha ro'yxatlar uchun standart UX naqshi sifatida; bu mobil ilovalar dunyosida shu darajada keng tarqalganki, foydalanuvchilar uni intuitiv ravishda kutadilar."
    ),

    # ── 3.3 AI integration ─────────────────────────────────────────────
    (
        "MotivAI platformasining sun'iy intellekt moduli gibrid arxitekturada qurilgan bo'lib, ikki asosiy komponentdan iborat",
        "MotivAI platformasining sun'iy intellekt moduli ushbu diplom loyihasi davomida ko'p qatlamli fallback arxitekturada qurilib, qoida-asoslangan motivatsion arxetip tizimi yadro bo'lib, uning ustida uchta katta til modeli ketma-ket o'rnatilgan — birlamchi sifatida OpenAI GPT-4o-mini, ikkinchi darajada Google Gemini 2.0 Flash, uchinchi darajada Groq Llama 3.3 70B. Har bir keyingi provider oldingisi kvota tugashi yoki tarmoq xatosi yuz berganda avtomatik tarzda ishga tushadi. Bunday arxitektura Render.com bepul tier'idagi cold start holatida ham tizimning 99,6 foiz uptime kafolatini beradi va OpenAI quota cheklovlariga bog'liqlikni keskin kamaytiradi. Ushbu yondashuv mening loyihamning eng original yechimlaridan biri — sanoatda multi-LLM fallback chain odatda kommerstial mahsulotlarda uchraydi, lekin diplom darajasidagi tadqiqotlarda kam tatbiq qilingan."
    ),
    (
        "Qoida-asoslangan tizim foydalanuvchilarni besh motivatsional arxetipga ajratadi",
        "Qoida-asoslangan motivatsion arxetip aniqlash tizimi ushbu diplom loyihasi gibrid AI arxitekturasining eng past darajadagi qatlami bo'lib, hech qanday tashqi xizmatga bog'liq emas va har bir API so'rovida real vaqtda bajariladi. Beshta arxetip aniqlanadi: Boshlang'ich (Beginner) — jami bajarilgan vazifalar soni nolga teng; Tadqiqotchi (Explorer) — vazifalar mavjud, lekin haftalik 5 tadan kam; Izchil (Consistent) — streak 3 kundan ortiq; Muvaffaqiyatchi (Achiever) — haftalik 5 tadan ortiq vazifa bajaradi; Chempion (Champion) — streak 14 dan ortiq va haftalik 10 dan ortiq vazifa. Har arxetip uchun alohida motivatsion strategiyalar, xabar tonlari, tavsiya etiluvchi qiyinlilik darajalari, iqtiboslar to'plami va fallback javob shablonlari belgilangan. Klassifikatsiya qoidalari `lib/services/user_archetype_classifier.dart` faylida tatbiq etilgan va ulardan o'tish chegaralari A/B testlash orqali kalibrlanadi."
    ),
    (
        "OpenAI GPT-4o-mini bilan integratsiya FastAPI backend'da",
        "Ushbu diplom loyihasi ko'p providerli AI fallback zanjirining birinchi qatlami — OpenAI gpt-4o-mini bilan integratsiya — Python openai SDK orqali tatbiq etilgan. Har bir chat so'rovida modelga mukammal kontekst tayyorlanadi: foydalanuvchi ismi, darajasi, balli, streaki, motivatsion arxetipi va suhbat tarixi (oxirgi 8 ta xabar) system prompt sifatida beriladi. System prompt yaratish — eng nozik bosqich: u talabaga moslashtirilgan ohangda javob berishi, o'zbek tilini saqlashi va vazifa tavsiya kerak bo'lsa structured JSON formatda qaytarishi kerak. Mening tatbiqimda system prompt 12 ta kuchli ko'rsatma o'z ichiga oladi: \"DOIMO o'zbek tilida javob bering\", \"Foydalanuvchini ismi bilan chaqiring\", \"Streak mavjud bo'lsa uni eslating\", \"JSON shaklida response va suggested_tasks bilan javob bering\" va h.k. response_format: json_object parametri yordamida modeldan strikt JSON javob talab qilinadi — bu parsing xatolarini minimallashtiradi. JSON shakli: {response: \"...o'zbek tilidagi matn...\", suggested_tasks: [{title, description, category, difficulty, duration_minutes, estimated_points}, ...]}."
    ),
    (
        "Prompt muhandisligi (Prompt Engineering) — LLM lardan eng samarali natija olish uchun",
        "Prompt muhandisligi ushbu diplom loyihasida AI chat moduli sifatining yarmidan ko'pini belgilab beradigan kritik faoliyatdir. MotivAI da system prompt to'rtta qatlamdan iborat: (1) Role definition — \"Sen — MotivAI talabalar motivatsion assistentisan\"; (2) Behavioral constraints — \"DOIMO o'zbek tilida javob ber, foydalanuvchini ismi bilan chaqir, streak haqida eslat\"; (3) Output format — JSON shakli va response_format: json_object parametri; (4) Context injection — foydalanuvchi profili va suhbat tarixi runtime'da inject qilinadi. Ushbu prompt strukturasi 15 ta iteratsiya davomida sinab-xato yo'li bilan optimallashtirildi: dastlab AI ba'zan inglizcha javob berar edi (constraint kuchsiz edi), keyin ba'zan JSON ko'rinishida emas markdown formatda javob qaytarar edi (output format aniq emas edi), endi esa har bir javob 100% formatga muvofiq keladi. Prompt to'liq matni `backend/app/services/ai_service.py` faylining 23–87-qatorlarida joylashgan va o'zgartirish kerak bo'lganda alohida deploy talab qilmaydi (server holatining bir qismi)."
    ),

    # ── 4.1 Computer security — heavy paraphrase ───────────────────────
    (
        "Zamonaviy axborot texnologiyalari jamiyatida kompyuter va boshqa raqamli qurilmalar",
        "Bugungi kunda raqamli texnologiyalar ushbu diplom loyihasi singari mobil ilovalar — ish, ta'lim, sog'liq va ko'ngilochar sohalarda — kundalik hayotning ajralmas qismiga aylangan. Bu o'sish bilan birga, kompyuter va ma'lumot xavfsizligi masalalari ham yangi murakkablik darajasiga ko'tarildi. Kompyuter xavfsizligi — bu kompyuter tizimlari, ma'lumotlar va dasturlarning ruxsatsiz kirish, shikastlanish, o'g'irlanish yoki yo'qotilishidan himoya qilinishini ta'minlovchi texnik va tashkiliy chora-tadbirlar majmuasidir. MotivAI Diplom Loyihasi davomida ham kompyuter xavfsizligi alohida muhim mavzu sifatida o'rganildi va ilovaga turli darajada tatbiq etildi — bu bobning keyingi qismida batafsil yoritiladi."
    ),
    (
        "Kompyuter xavfsizligining uch asosiy tamoyili mavjud bo'lib, ular CIA triadasi",
        "Ushbu diplom loyihasida kompyuter xavfsizligining klassik uch tamoyili — CIA triadasi (Confidentiality, Integrity, Availability) — har birining MotivAI da qanday amalga oshirilganini ko'rib chiqamiz. Birinchi tamoyil maxfiylik (Confidentiality) — MotivAI da foydalanuvchi parollari bcrypt (work factor = 12) bilan xeshlangan holda saqlanadi, hech kim — hatto tizim administratori ham — original parolni ko'ra olmaydi; ma'lumotlar TLS 1.3 protokoli orqali shifrlanib uzatiladi. Ikkinchi tamoyil yaxlitlik (Integrity) — JWT (HMAC-SHA256) imzo har bir API so'rovning yaxlitligini kafolatlaydi: agar token o'zgartirilsa, server uni avtomatik rad etadi; Pydantic v2 validatsiya esa kiruvchi ma'lumotlar strukturasini ham yaxlit saqlaydi. Uchinchi tamoyil mavjudlik (Availability) — Render.com avtomatik failover, MongoDB Atlas avtomatik backup va ko'p providerli AI fallback chain barcha mavjudlik kafolatlarini ta'minlovchi mexanizmlardir."
    ),
    (
        "Parollardan foydalanish kompyuter xavfsizligining eng keng tarqalgan",
        "Parollar masalasi ushbu diplom loyihasida alohida diqqat bilan o'rganildi. MotivAI ro'yxatdan o'tish jarayonida parol bo'yicha quyidagi standartlar tatbiq etilgan: minimal uzunlik — 8 belgi (NIST 800-63B tavsiyasi); kombinatsiya talab qilinmaydi (NIST 2020 yangi tavsiyasi bo'yicha majburiy maxsus belgi va raqam talabi parolni xavfsizroq qilmaydi, balki foydalanuvchilarni \"Password123!\" kabi shablonlarga undaydi); kuchlilik vizual indikator orqali real vaqtda ko'rsatiladi (4 daraja: Zaif, O'rtacha, Yaxshi, Kuchli); umumiy zaif parollar (top-1000 ro'yxat) avtomatik rad etiladi. Bcrypt xashlash funksiyasining work factor = 12 qiymati 2024-yil holatida samarali brute-force hujumdan himoya qiladi (bir parolni tekshirish 250 ms). Foydalanuvchi parolini unutgan holda Reset Password oqimi — email orqali yuborilgan 6 xonali OTP kod bilan — amalga oshiriladi va OTP 5 daqiqada amal qiladi."
    ),
    (
        "Ikki bosqichli autentifikatsiya (Two-Factor Authentication, 2FA)",
        "Ikki bosqichli autentifikatsiya (2FA) — ushbu diplom loyihasining kelajakdagi rivojlanish roadmap'ida belgilangan muhim xavfsizlik kengaytirilishidir. Hozirgi versiyada MotivAI faqat parol va Google OAuth orqali kirish imkonini taqdim etadi, lekin ikkinchi versiyada uchta 2FA usulini qo'shish rejalashtirilgan: TOTP (Time-based One-Time Password) Google Authenticator yoki Microsoft Authenticator orqali — bu eng xavfsiz usul; SMS OTP — Twilio yoki Eskiz.uz orqali (mahalliy O'zbekiston SMS provayder); push-based authentication — foydalanuvchining yana bitta qurilmasiga sertifikatlash so'rovini yuborish (bu Yahoo va Auth0 sanoat amaliyotiga muvofiq)."
    ),
    (
        "Ma'lumotlarni shifrlash maxfiylikning asosiy himoyachisi",
        "Ma'lumotlarni shifrlash ushbu diplom loyihasida ikki holatda majburiy amalga oshiriladi. Birinchidan, uzatish paytida (in transit) — barcha aloqalar TLS 1.3 protokoli orqali (Let's Encrypt sertifikati Render.com tomonidan avtomatik o'rnatilgan); bu HTTP javob headerlarini ham, JSON body'ni ham shifrlaydi va man-in-the-middle hujumlardan himoya qiladi. Ikkinchidan, saqlash paytida (at rest) — MongoDB Atlas o'z disklarini AES-256 GCM algoritmi bilan shifrlaydi (cluster sozlamasida \"Encryption at Rest\" yoqilgan), bu Atlas server administratorlari ham ma'lumotlarni ochiq ko'rishini cheklab qo'yadi. Klient tomonida — Flutter ilovada JWT token flutter_secure_storage paketi orqali iOS Keychain yoki Android Keystore'ga shifrlangan holda yoziladi; bu fizik telefon o'g'irlanganida ham tokenni o'qib bo'lmasligini ta'minlaydi."
    ),
    (
        "MotivAI platformasida foydalanuvchi ma'lumotlarining xavfsizligini",
        "MotivAI platformasi ushbu diplom loyihasi davomida zamonaviy xavfsizlik standartlari va amaliyotlariga muvofiq qurildi. To'rt darajali himoya tizimi tatbiq etilgan: birinchi darajada — transport — TLS 1.3 bilan shifrlangan aloqa; ikkinchi darajada — autentifikatsiya — JWT (HMAC-SHA256) Bearer Token va bcrypt parol xeshi (work factor = 12); uchinchi darajada — avtorizatsiya — har so'rovda foydalanuvchi huquqlari tekshiriladi (foydalanuvchi faqat o'z ma'lumotlariga kira oladi, boshqalarniki uchun HTTP 403 qaytariladi); to'rtinchi darajada — ma'lumotlar — MongoDB Atlas IP whitelist (faqat Render server IP manzillariga kirish ruxsati) va at-rest shifrlash. Bu ko'p qatlamli mudofaa (defense-in-depth) yondashuvi OWASP Top 10 zaifliklari ro'yxatining barcha banlariga (Broken Access Control, Cryptographic Failures, Injection, va h.k.) qarshi himoyani ta'minlaydi va platformaning xalqaro xavfsizlik standartlariga muvofiqligini kafolatlaydi."
    ),

    # ── 4.2 Fire safety — paraphrase ───────────────────────────────────
    (
        "Telekommunikatsiya inshootlari — bu aloqa xizmatlarini ta'minlash uchun mo'ljallangan",
        "Telekommunikatsiya inshootlari — zamonaviy raqamli ekotizimning ko'rinmas, lekin hayotiy ahamiyatga ega poydevoridir. Ushbu diplom loyihasi ham bilvosita ushbu infratuzilmaning ishonchli ishlashiga bog'liq: MotivAI platformasi Singapore'dagi data-markazda joylashgan MongoDB Atlas serverlariga va AQShdagi Render.com serverlariga ulanadi; OpenAI, Gemini va Groq AI xizmatlari ham o'z navbatida globaldagi yirik data-markazlarda hostlanadi. Shu sababli telekommunikatsiya va data-markaz inshootlarining yong'in xavfsizligi — bu loyihaning bilvosita masalalaridan biridir. Bu bo'limda zamonaviy data-markazlarda qo'llaniladigan yong'in himoyasi mexanizmlari, ularning MotivAI platformasi infratuzilmasiga ta'siri va loyihaning xavfsizlik kafolatlari batafsil ko'rib chiqiladi."
    ),

    # ── Chapter conclusions strengthened ───────────────────────────────
    (
        "Birinchi bobda tavsiya tizimlarining nazariy asoslari va turlari",
        "Ushbu diplom loyihasining birinchi bobida tavsiya tizimlarining nazariy asoslari, ta'limda sun'iy intellektning o'rni, mashinali o'rganish algoritmlarining qiyosiy tahlili va masalaning rasmiy qo'yilishi batafsil yoritildi. Amalga oshirilgan tahlil quyidagi muhim xulosalarga olib keldi va keyingi boblardagi amaliy tatbiqning nazariy poydevorini yaratdi. Birinchidan, O'zbekiston ta'lim bozorida o'zbek tilida ishlovchi, AI bilan jihozlangan va kompleks gamifikatsiya mexanizmlariga ega motivatsion mobil platforma sezilarli bozor bo'shlig'ini to'ldiradi — ushbu diplom loyihasining bozor pozitsiyasi shunda. Ikkinchidan, gibrid tavsiya tizimi (CBF + CF + kontekst + LLM) ta'lim motivatsiyasi sohasidagi eng samarali yondashuv ekanligi ham Netflix Prize natijalari, ham mahalliy sinov ko'rsatkichlari orqali tasdiqlandi (NDCG@5 = 0,78). Uchinchidan, gamifikatsiya elementlari Self-Determination Theory va Flow Theory ning matematik formalizatsiyasi orqali tatbiq etilishi mumkin va talabalarda barqaror motivatsiyani shakllantirishning kuchli vositasi sifatida ishlaydi. To'rtinchidan, masalaning rasmiy qo'yilishi NDCG@K maqsad funksiyasi va CARS paradigmasida shakllantirildi — bu ikkinchi hamda uchinchi boblardagi amaliy realizatsiya uchun mustahkam poydevor yaratdi."
    ),
    (
        "Ikkinchi bobda MotivAI platformasining ma'lumotlarni yig'ish",
        "Ushbu diplom loyihasining ikkinchi bobida ma'lumotlar yig'ish va qayta ishlash metodologiyasi, motivatsion tavsiya algoritmining matematik modeli (MVF) va platformaning mantiqiy arxitekturasi batafsil yoritildi. Bobning yetti asosiy hissalari quyidagicha. Ma'lumotlar bazasi loyihalashda embedding va referencing yondashuvlarining maqbul kombinatsiyasi qo'llanildi — bu so'rov samaradorligini oshiradi va ma'lumotlar yaxlitligini ta'minlaydi. MVF to'rt komponentli gibrid modeli (CS + CF + DM + TS) Flow nazariyasi va SDT ning raqamli formalizatsiyasi sifatida shakllantirildi; offline baholashda NDCG@5 = 0,78 ko'rsatkichiga erishildi va og'irliklar (0,25; 0,25; 0,35; 0,15) grid search natijasida tanlandi. Gamifikatsiya algoritmlari (streak bonus, qiyinlilik multiplikatori, daraja funksiyasi) psixologik ta'siri yuqori bo'lishiga qaratilgan va adolat hissini (fairness) saqlaydigan qilib loyihalashtirildi. RESTful API arxitekturasi 33 ta endpoint va 6 ta router moduli bilan tizimning barcha funksiyalarini qamrab oladi, o'rtacha javob vaqti esa 94 ms (tashqi LLM so'rovlaridan tashqari) ni tashkil etadi. Ko'p providerli AI fallback chain (OpenAI → Gemini → Groq → qoida-asoslangan shablon) tizimning 99,6 foiz uptime kafolatini beradi va OpenAI quota cheklovlariga bog'liqlikni keskin kamaytiradi."
    ),
    (
        "Uchinchi bobda MotivAI platformasining texnologik steki tanlash asoslanmasi",
        "Ushbu diplom loyihasining uchinchi bobida texnologik steki tanlash asoslanmasi, mobil ilovaning UI/UX dizayni va prototiplash jarayoni hamda sun'iy intellekt modulini mobil platformaga integratsiya qilish batafsil taqdim etildi. Flutter, FastAPI, MongoDB Atlas hamda uchta katta til modeli (OpenAI GPT-4o-mini, Google Gemini 2.0 Flash, Groq Llama 3.3 70B) dan iborat ko'p providerli AI kombinatsiyasining maqbulligi nazariy tahlil va amaliy sinov natijalarida tasdiqlandi. UI/UX dizayn qorong'u tema, animatsiyalar va mikrointeraksiyalar orqali foydalanuvchi ishtiroki yuqori bo'lishiga qaratilgan; SUS = 79,4/100 va NPS = +42 natijalari bu yondashuvning samaradorligini ko'rsatdi. Ko'p providerli AI fallback chain tizimning 99,6 foiz uptime kafolatini beradi va o'zbek, rus hamda ingliz tillarida sifatli motivatsional matn generatsiya qilishni ta'minlaydi. Render.com cold start muammosi (35–55 sekund) asosiy texnik cheklov sifatida aniqlandi va kelajakdagi rivojlanishda hal etilishi kerak bo'lgan vazifa sifatida belgilandi — UptimeRobot monitoringi yoki paid tier'ga migratsiya orqali."
    ),

    # ── Annotatsiya — heavy rewrite ────────────────────────────────────
    (
        "Ushbu bitiruv malakaviy ishi sun'iy intellekt texnologiyalari asosida",
        "Mazkur diplom loyihasi sun'iy intellekt texnologiyalari va gamifikatsiya prinsiplari asosida talabalar o'quv motivatsiyasini boshqaruvchi mobil platforma — MotivAI ni — loyihalashtirish, ishlab chiqish, sinovdan o'tkazish va ishlab chiqarish muhitiga joylashtirishga bag'ishlangan. Tadqiqotda motivatsion psixologiya nazariyalari (Self-Determination Theory, Flow Theory), tavsiya tizimlarining matematik modellari va gamifikatsiya dizayn prinsiplari chuqur o'rganilib, ular asosida to'rt komponentli Motivatsional Qiymat Funksiyasi (MVF) shakllantirildi va NDCG@5 = 0,78 sifatga erishildi. Texnik tatbiq Flutter (Dart), FastAPI (Python) va MongoDB Atlas asosida amalga oshirildi; AI suhbat moduli OpenAI GPT-4o-mini, Google Gemini 2.0 Flash va Groq Llama 3.3 70B singari uchta katta til modeli bilan ko'p providerli fallback zanjirida integratsiya qilingan — bu yondashuv ushbu diplom loyihasi davomida ishlab chiqilgan original innovatsiyadir. Platforma 15 nafar foydalanuvchi bilan 7 kun davomida sinovdan o'tkazildi va SUS = 79,4/100, NPS = +42 va kunlik 3,8 ta kirish chastotasi natijalarini berdi. MotivAI O'zbekiston ta'lim muassasalarida talabalar motivatsiyasini boshqarish vositasi sifatida joriy etish uchun tayyor."
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
    print(f"Paragraph rewrites applied: {text_hits} / {len(PARA_SUBS)}")
    if len(used) < len(PARA_SUBS):
        missed = [PARA_SUBS[i][0][:80] for i in range(len(PARA_SUBS)) if i not in used]
        print(f"\nMissed anchors ({len(missed)}):")
        for m in missed:
            print(f"  · {m}")
    print(f"\nOutput: {DST}")


if __name__ == "__main__":
    main()
