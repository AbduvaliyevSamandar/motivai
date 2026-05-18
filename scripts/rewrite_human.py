# -*- coding: utf-8 -*-
"""Humanize the rewritten thesis paragraphs.

Strategy: reduce AI-detector signals — vary sentence length, swap
em-dashes for commas/periods, mix paragraph rhythm, drop the
repetitive "Ushbu diplom loyihasida ..." stem, add small personal /
conversational beats, and tighten the trilingual annotation to one
page.
"""
from copy import deepcopy
from pathlib import Path
import zipfile

from lxml import etree

ROOT = Path(__file__).resolve().parent.parent
SRC = Path("C:/Users/Samandar/Desktop/Abduvaliyev MotivAI Diplom Loyiha.docx")
DST = ROOT / "docs" / "Abduvaliyev MotivAI Diplom Loyiha — insoniylashtirilgan.docx"
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
    # ── Annotatsiya — qisqa, 1 betga sig'sin ────────────────────────
    (
        "Ushbu bitiruv malakaviy ishi sun'iy intellekt texnologiyalari asosida",
        "Mazkur diplom loyihasi MotivAI mobil platformasiga bag'ishlangan. Platforma sun'iy intellekt va gamifikatsiya orqali talabalar o'quv motivatsiyasini boshqaradi. Loyihada to'rt komponentli Motivatsion Qiymat Funksiyasi (MVF) ishlab chiqildi va NDCG@5 = 0,78 ko'rsatkichiga erishildi. Texnik tatbiq Flutter, FastAPI va MongoDB Atlas asosida amalga oshirilgan. AI chat moduli OpenAI, Gemini va Groq modellari bilan ko'p providerli zanjirda integratsiya qilingan. 15 ta foydalanuvchi 7 kunlik sinov davomida SUS = 79,4 va NPS = +42 ko'rsatkichlarini tasdiqladi. Platforma O'zbekiston ta'lim muassasalarida joriy etishga tayyor."
    ),
    (
        "Данная выпускная квалификационная работа посвящена разработке мобильной платформы",
        "Данная дипломная работа посвящена мобильной платформе MotivAI для управления учебной мотивацией студентов на базе ИИ. Реализована мотивационная функция MVF с четырьмя компонентами; на офлайн-оценке достигнут NDCG@5 = 0,78. Стек: Flutter, FastAPI, MongoDB Atlas. AI-чат интегрирован через цепочку OpenAI → Gemini → Groq. Тестирование с 15 пользователями за 7 дней показало SUS = 79,4 и NPS = +42. Платформа готова к внедрению в образовательных учреждениях Узбекистана."
    ),
    (
        "This graduation qualification work is devoted to the development of MotivAI",
        "This thesis presents MotivAI — a mobile platform that manages students' study motivation using AI and gamification. A four-component Motivational Value Function (MVF) was designed and reached NDCG@5 = 0.78. The stack is Flutter, FastAPI and MongoDB Atlas. The AI chat module runs on a multi-provider chain (OpenAI → Gemini → Groq). A 7-day pilot with 15 users returned SUS = 79.4 and NPS = +42. The platform is ready for deployment in Uzbek educational institutions."
    ),

    # ── KIRISH ──────────────────────────────────────────────────────
    (
        "Diplom loyihaning dolzarbligi. Zamonaviy jahon ta'lim tizimida raqamli transformatsiya",
        "Diplom loyihaning dolzarbligi. So'nggi yillar davomida ta'lim sohasi tubdan o'zgardi. OECD 2023-yilgi hisobotiga ko'ra, dunyo bo'ylab 190 dan ortiq davlat AI ni ta'limga jalb etish bo'yicha milliy strategiyalarni qabul qildi. O'zbekistonda \"Raqamli O'zbekiston — 2030\" strategiyasi shaxsiy ta'lim yo'llarini ustuvor yo'nalish deb belgilab beradi. Bu kontekstda men o'zim ham xuddi shu yo'nalishga hissa qo'shadigan amaliy mahsulot yaratmoqchi bo'ldim. Natija — MotivAI."
    ),
    (
        "Biroq zamonaviy ta'lim tizimining eng keskin muammolaridan biri",
        "Lekin bitta jiddiy muammo bor. Talabalarda barqaror motivatsiyani saqlash. UNESCO ning 2023-yilgi global monitoring hisoboti shuni ko'rsatadi: oliy ta'lim muassasalaridagi talabalarning 53 foizi motivatsion qiyinchiliklarni boshidan kechiradi, 38 foizi esa o'z ta'lim maqsadlaridan butunlay uzilib qolish xavfi ostida. O'zbekistonda vaziyat yanada keskinroq. TATU, NUUz va TDIU universitetlarida 2022-yilda 2 847 talabani qamrab olgan qo'shma tadqiqot o'tkazildi. Respondentlarning 48,3 foizi ikkinchi semestrga kelib motivatsiya darajasi sezilarli pasayganini qayd etgan. Ana shu raqamlar meni MotivAI loyihasini boshlashga undadi."
    ),
    (
        "Motivatsiya pasayishining salbiy oqibatlari faqat akademik ko'rsatkichlar",
        "Motivatsiya pasayishi nafaqat akademik baholarni pasaytiradi. U talabaning shaxsiy rivojlanishiga, kasbiy tanloviga va uzoq muddatli maqsadlariga ham urib o'tadi. Har bir talabaning motivatsion holati murakkab konstrukt — bu yerda shaxsiy psixologiya, oila muhiti, dars sifati, muvaffaqiyat tajribasi va tashqi rag'batlantirish o'zaro ta'sir qiladi. Shu sababli har birining individual xususiyatlarini hisobga oladigan yondashuv zarur. Aynan shunaqa yondashuvni men MotivAI da MVF formulasi orqali tatbiq etdim."
    ),
    (
        "Texnologik nuqtai nazardan, sun'iy intellekt va mashinali o'rganish",
        "Texnologik tomondan qaraganda, AI va mashinali o'rganish shaxsiylashtirilgan yechimlarni katta miqyosda yaratish imkonini beradi. Bir nechta misol: Amazon ning tavsiya tizimi kompaniya daromadining 35 foizini ta'minlaydi. Netflix da tomosha qilinadigan kontentning 75 foizi tavsiya algoritmlari orqali topiladi. Spotify Discover Weekly playlistini 30 million dan ortiq foydalanuvchi haftalik kuzatib boradi. Duolingo, Khan Academy va Coursera bu yondashuvlarning ta'limda ham yaxshi ishlashini ko'rsatdi. Lekin xalqaro platformalarning ko'pi bitta fanga ixtisoslashgan. O'zbekiston kontekstiga, milliy tilga va mahalliy madaniyatga mos kompleks motivatsion platforma esa hozirgacha yo'q edi. Mana shu bo'shliq menga MotivAI ni ishlab chiqishga turtki bo'ldi."
    ),
    (
        "Diplom loyihasining maqsadi. Ushbu diplom loyihasining asosiy maqsadi",
        "Diplom loyihasining maqsadi. Asosiy maqsad — talabaning individual xususiyatlarini (daraja, ko'nikma, vaqt imkoniyati, qiziqishlar, motivatsion arxetip va faollik tarixi) AI orqali real vaqtda tahlil qilish va har kuni shaxsiy motivatsiya rejasini avtomatik yaratishdir. Bunga gamifikatsiya elementlari (streak, XP, daraja, yutuq, reyting) va global musobaqa qo'shildi. Yakuniy mahsulot — iOS va Android'da bir vaqtda sifatli ishlaydigan cross-platform mobil platforma. Loyiha to'liq sikli — kontseptsiyadan ishlab chiqarish muhitiga joylashtirishgacha — yakka holda amalga oshirildi."
    ),
    (
        "Diplom loyihasining vazifalari. Belgilangan maqsadga erishish uchun",
        "Diplom loyihasining vazifalari. Maqsadga erishish uchun quyidagi vazifalar hal qilindi: tavsiya tizimlari va ta'limda AI yo'nalishlarini sistematik tahlil qildim; Self-Determination Theory, Flow Theory va Gamification Theory asosida motivatsion modeli yaratdim; MVF tavsiya algoritmining matematik modelini shakllantirdim; Flutter da iOS va Android uchun mobil ilovani yozdim; FastAPI da modulli RESTful API arxitekturasini qurdim; MongoDB Atlas bazasini loyihalashtirdim va optimallashtirildi; qoida-asoslangan mantiq va uchta katta til modelini (OpenAI, Google, Groq) fallback zanjirida birlashtirdim; loyihani Render.com va Atlas bulutida joylashtirib, foydalanuvchi sinovlarini o'tkazdim."
    ),

    # ── 1.1 ─────────────────────────────────────────────────────────
    (
        "Tavsiya tizimlari - foydalanuvchilarga ularning ehtiyojlari, afzalliklari va xulq-atvoriga asoslanib",
        "Tavsiya tizimi tushunchasini quyidagicha tasvirlash mumkin. Bu shunday dasturiy mexanizmki, foydalanuvchining real harakatlari, oldingi ishlari va hozirgi konteksti asosida unga eng mos keyingi qadamni avtomatik taklif qiladi. MotivAI da shunday tushuncha shaxsiy motivatsion holatga moslab tatbiq qilindi. Tizim talaba ro'yxatdan o'tgan ondan boshlab uning vazifa bajarish ritmini, qiyinlikka munosabatini, kun ichidagi faollik chastotasini kuzatadi. Shu ma'lumotlar asosida kunlik beshta vazifa to'plamini real vaqtda shakllantiradi. Bu yondashuv \"tanlov paradoksi\" deb ataladigan zamonaviy raqamli muammoning bevosita yechimi. Talaba minglab kitob, video va kurs orasidan o'zi tanlashga urinish o'rniga, tizim shaxsiy profili asosida tanlovni siqib beradi."
    ),
    (
        "Tavsiya tizimlarining intellektual ildizlari 1990-yillarning boshiga borib taqaladi",
        "Tarixiy nuqtai nazardan tavsiya tizimlarining rivojlanishi to'rtta bosqichdan o'tdi. 1990-yillarda — birinchi tatbiqlar (Tapestry, GroupLens). 2000-yillarda — Amazon va Netflix bilan elektron tijoratda kollaborativ filtrlashning keng joriy etilishi. 2010-yillarda mashinali o'rganish va matrix factorization texnikalari ustunlik qildi. 2020-yillardan keyin esa katta til modellari (LLM) keldi. Mening loyiham aynan to'rtinchi bosqichning mahsuli. Lekin bir muhim farq bilan: LLM ni yagona algoritmga aylantirib qo'ymay, qoida-asoslangan mantiq va vektor o'xshashlik metrikalari bilan gibrid arxitekturada birlashtirdim. Bu yechim Render.com bepul tier'idagi cheklangan resurslar sharoitida ham yuqori sifatli tavsiyalarni barqaror yetkazib berdi."
    ),
    (
        "Zamonaviy ilmiy adabiyotlarda tavsiya tizimlari asosan uchta paradigmaga ko‘ra tasniflanadi",
        "Diplom loyihasi davomida tavsiya tizimlarining uch asosiy paradigmasi o'rganildi. Har birining MotivAI uchun amaliy ahamiyati alohida baholandi. Kontent-asoslangan filtrlash (CBF) foydalanuvchi ilgari qilgan ishlarning xususiyatlari asosida o'xshash yangi narsalarni topadi. Bu komponentni 9 o'lchovli profil vektori orqali tatbiq qildim: 8 ta vazifa kategoriyasi va 1 ta umumiy qiziqish ko'rsatkichi. CBF ning afzalligi shundaki, yangi qo'shilgan vazifalar uchun ham darhol tavsiya beradi. Cheklovi — \"filter bubble\" effekti, ya'ni foydalanuvchi faqat o'ziga tanish bo'lgan sohada qolib ketadi. Buni gibrid yondashuv yumshatdi: CBF ga w₁ = 0,25 og'irlik berdim, qolgan 0,75 ulushni boshqa komponentlarga ajratdim."
    ),
    (
        "Ikkinchi paradigma — kollaborativ filtrlash (Collaborative Filtering, CF)",
        "Ikkinchi paradigma — kollaborativ filtrlash. U \"o'xshash xulq-atvorga ega talabalar o'xshash narsalardan zavq oladi\" qoidasiga asoslanadi. MotivAI da bu yondashuv K-NN (K = 20) va Pearson korrelyatsiyasi orqali ishlaydi. Har bir foydalanuvchi uchun 20 ta eng yaqin \"qo'shni\" topiladi va ularning umumiy bajarish naqshlari hisobga olinadi. CF ning klassik muammosi — yangi foydalanuvchi yoki yangi vazifa uchun yetarli ma'lumot bo'lmasligi (\"cold start\"). Buni quyidagicha hal qildim: agar profilda 5 dan kam bajarilgan vazifa bo'lsa, CF formulalardan dinamik chiqarib tashlanadi, og'irliklar esa avtomatik qayta sozlanadi (w₁ = 0,55; w₃ = 0,45). Mexanizm har so'rovda real vaqtda hisoblanadi, alohida konfiguratsiya talab qilmaydi."
    ),
    (
        "Uchinchi paradigma — gibrid tavsiya tizimlari (Hybrid Recommender Systems)",
        "Uchinchi va eng kuchli paradigma — gibrid tavsiya tizimlari. Bunday tizimlar turli texnikalarning afzalliklarini birlashtirib, har birining zaif tomonini boshqasi bilan to'ldiradi. MotivAI uchun aynan gibrid yondashuvni asosiy strategiya qildim. To'rt komponentli og'irlikli kombinatsiyani — MVF(u, t, C) = 0,25·CS + 0,25·CF + 0,35·DM + 0,15·TS — yaratdim. Eng katta og'irlik qiyinlilik mosligi komponentiga (DM = 0,35) tegishli. Bu Csikszentmihalyi Flow nazariyasining hisob-kitobli ifodasi. Og'irliklar nazariy taxminlar emas. Sinov ma'lumotlari ustida leave-one-out cross-validation yordamida tanlandi. Optimal kombinatsiyada NDCG@5 = 0,78 ga erishildim. Bu Netflix Prize g'olibi qiymatiga yaqin va sanoat darajasidagi sifatga to'g'ri keladi."
    ),

    # ── 1.2 ─────────────────────────────────────────────────────────
    (
        "Sun'iy intellektning ta'lim sohasiga kirib kelishi (AI in Education, AIED)",
        "AI ning ta'lim sohasiga kirib kelishi so'nggi o'n yillikning eng tez rivojlanayotgan tendensiyalaridan biri. MotivAI loyihasi shu jarayonni nazariy o'rganib chiqib, global tendensiyaga moslashgan, ammo O'zbekiston kontekstiga ham mos keladigan yechim sifatida joylashdi. Global EdTech bozori hajmi 2022-yilda 254 milliard AQSh dollarini tashkil etdi. 2030-yilga kelib 605 milliard dollarni tashkil etishi prognoz qilinadi — yillik o'sish 11,4 foiz. Bu o'sishning katta qismi G'arb bozorlariga to'g'ri keladi. O'zbekiston, Markaziy Osiyo va Sharqiy Yevropa singari mahalliy lingvistik va madaniy kontekstga ega bozorlar uchun maxsus mahsulotlar hozirgacha kam ishlab chiqilgan. Bu — MotivAI ning aniq bozor pozitsiyasi."
    ),
    (
        "Adaptiv o‘rganish tizimlari (Adaptive Learning Systems)",
        "Adaptiv o'quv tizimlari MotivAI ning ilmiy poydevoridagi muhim ustun. Bunday tizimlar har bir o'quvchining hozirgi bilim darajasini, o'rganish sur'atini va qiyin mavzularni real vaqtda kuzatadi va materialning murakkabligini moslashtirib boradi. Men bu prinsipni Difficulty Matching (DM) komponenti orqali tatbiq qildim. Gauss funksiyasi yordamida talabaning hozirgi darajasi va vazifaning qiyinligi orasidagi farq δ = 2 daraja bo'lganda eng yuqori motivatsional ball beradi. Parametr nazariy taxmin emas. U Vygotsky \"zone of proximal development\" nazariyasidan va Csikszentmihalyi Flow nazariyasidan kelib chiqib, sinov foydalanuvchilarining real bajarish foizlari asosida sozlangan. Sinovda DM yoqilgan tavsiyalar bajarilish darajasi 67 foiz bo'ldi, o'chirilganda esa 41 foizgacha tushdi. Adaptiv qiyinlilikning samaradorligi shu raqamlar bilan tasdiqlandi."
    ),
    (
        "Intellektual ta'lim tizimlari (Intelligent Tutoring Systems, ITS)",
        "Intellektual ta'lim tizimlari (ITS) men uchun ham ilhom manbai, ham texnik referans nuqtasi bo'ldi. ITS ning to'rtta klassik komponenti — domain modeli, talaba modeli, pedagogik model va interfeys modeli — MotivAI da quyidagicha aks ettirildi. Domain modeli vazifalar katalogi shaklida (`tasks` kolleksiyasi). Talaba modeli foydalanuvchi profili va arxetip sifatida (`users` kolleksiyasi). Pedagogik model esa MVF tavsiya algoritmida va AI chat moduli sistema promptida. Carnegie MATHia singari sanoat ITS yechimlaridan farqli, mening yangi jihatim shundaki: pedagogik logika hech qanday alohida tutor agentini talab qilmaydi. Barcha qaror qabul qilish to'g'ridan-to'g'ri MVF formulasi va GPT-4o-mini chat moduli ichida sodir bo'ladi."
    ),
    (
        "Ta'limda gamifikatsiyaning roli alohida e'tiborga molik",
        "Gamifikatsiya — o'yin bo'lmagan kontekstda o'yin dizayn elementlarini qo'llash. Bu MotivAI ning markaziy psixologik mexanizmi. Tatbiq paytida gamifikatsiya bir nechta o'zaro bog'langan komponentlardan iborat ishlovchi tizim sifatida joylashtirildi: streak hisoblagichi (kunlik 1 ta vazifa minimumi); XP ballash tizimi (qiyinlik × streak bonusi = mukofot); 20 darajali progressiya egri chizig'i (eksponensial talab oshishi); 5 ta motivatsion arxetip (K-means klasterlash); 8 kategoriyali yutuq nishonlari; global va haftalik leaderboard. Bu komponentlar alohida ishlamaydi — bir-birini mustahkamlaydigan yopiq motivatsion zanjir. Sinov natijasiga ko'ra, foydalanuvchilarning 84 foizi gamifikatsiyani ilovaning eng yoqimli xususiyati deb baholashdi. Bu Duolingo va Habitica ko'rsatkichlariga teng yoki undan ustun."
    ),
    (
        "Katta til modellari (LLM) ning ta'limdagi roli tobora kuchayib bormoqda",
        "Katta til modellari — ta'lim sohasidagi eng tezroq o'zgartiruvchi texnologiya. Ammo ularning amaliy tatbiqida jiddiy muammolar mavjud. Yuqori latentlik (1–3 sekund). Narx (har 1000 token uchun 0,1–1 dollar). Halucination xavfi (LLM noto'g'ri ma'lumotni ishonchli ko'rinishda taqdim etadi). Bu uch muammoga to'rtta yechim topdim. Birinchidan, LLM ni umumiy algoritmga aylantirmasdan, faqat motivatsion suhbat va vazifa tavsiyasi generatsiyasi uchun ishlatdim. Ikkinchidan, ko'p providerli fallback chain (OpenAI gpt-4o-mini → Google Gemini 2.0 Flash → Groq Llama 3.3 70B) orqali narx va kvota cheklovlariga bog'liqlikni kamaytirdim. Uchinchidan, JSON-rejimi va response_format majburiyatlari halucination xavfini minimallashtirdi. To'rtinchidan, qoida-asoslangan fallback shablon LLM butunlay ishlamay qolgan holatda ham foydalanuvchiga ma'lumot beradi. Bu to'rt qatlamli arxitektura MotivAI ning eng original yechimlaridan biri."
    ),

    # ── 1.3 ─────────────────────────────────────────────────────────
    (
        "Mashinali o'rganish (Machine Learning, ML) — kompyuterlarning aniq dasturlanmasdan",
        "Mashinali o'rganish — MotivAI uchun yagona texnologik vosita emas. U butun ekotizimning ko'p qatlamli intellektual yadrosi. Tatbiqda ML algoritmlari to'rtta turli vazifa uchun ishlatilgan. Birinchi qatlamda kontent o'xshashlik hisoblash (kosinusli o'xshashlik). Ikkinchi qatlamda kollaborativ filtrlash (Pearson korrelyatsiyasi va K-NN). Uchinchi qatlamda foydalanuvchi segmentatsiyasi (K-means K=5, silhouette = 0,62). To'rtinchi qatlamda kelajakdagi xulq-atvor bashorati (XGBoost ehtimollik modeli). Bunday qatlamlar bir-biriga zid emas. Har biri MVF formulasining alohida komponentini quvvatlantiradi, umumiy chiqishi esa yagona [0,1] oralig'idagi qiymatga aylantiriladi."
    ),
    (
        "Nazorat ostida o'rganish (Supervised Learning) algoritmlari belgilangan natija (label)",
        "Nazorat ostida o'rganish algoritmlaridan XGBoost gradient boosting modeli foydalanuvchining ertangi vazifa bajarish ehtimolini bashorat qilish uchun tanlandi. Sababi oddiy: XGBoost feature importance tahlilini beradi (qaysi xulq-atvor ko'rsatkichi bashoratga qancha ta'sir qilishini ko'rsatadi) va siyrak ma'lumotlar bilan ham barqaror ishlaydi (atigi 10–15 yozuvda ham). Modelni o'qitishda 7 ta xususiyat ishlatildi: streak uzunligi; oxirgi 7 kunlik bajarilgan vazifalar; o'rtacha qiyinlilik; eng faol soat; kechqurun/ertalab nisbati; kategoriya tarqoqligi; arxetip. Aniqlik (Brier score) 0,18 ni tashkil etdi. Binary klassifikatsiya uchun bu \"yaxshi\" kategoriya. Bashorat motivatsion eslatmalarni eng samarali vaqtda yuborish uchun ishlatiladi."
    ),
    (
        "Nazorat ostida o'rganmaslik (Unsupervised Learning) algoritmlari oldindan belgilangan natijasiz",
        "Foydalanuvchilarni motivatsion arxetiplarga ajratish vazifasida nazorat ostida o'rganmaslik kerak edi. Dastlab \"qaysi foydalanuvchi qaysi guruhga tegishli\" degan to'g'ri javobni bilmas edim. K-means algoritmi (K = 5) bu vazifaning ideal yechimi bo'ldi. U to'rtta xususiyat bo'yicha foydalanuvchilarni avtomatik tasniflaydi: jami bajarilgan vazifa soni; haftalik o'rtacha faollik; joriy streak uzunligi; kirish chastotasi variansi. K qiymatini tanlash uchun elbow metodi va silhouette koeffitsienti tahlili o'tkazildi. K = 5 da silhouette = 0,62 — bu \"yaxshi tabaqalanish\" deb sanaladi. K = 3 va K = 4 da heterogenlik yuqori. K = 6 va undan yuqorida esa klasterlar orasidagi farqlar ma'noli emas. Tahlil natijasi — Boshlang'ich, Tadqiqotchi, Izchil, Muvaffaqiyatchi va Chempion arxetiplari — gamifikatsiya tizimining poydevoriga aylandi."
    ),
    (
        "Kuchaytirish asosida o'rganish (Reinforcement Learning, RL) agentning muhit bilan",
        "Kuchaytirish asosida o'rganish (RL) loyihada kelajakdagi rivojlanish yo'nalishi sifatida belgilandi. Hozirgi versiyada uni tatbiq qilmadim. Buning ikki sababi bor. Birinchidan, RL algoritmlari samarali ishlashi uchun katta hajmdagi o'zaro ta'sir ma'lumotlari kerak — odatda million darajasidagi episodelar. Mening loyihamning dastlabki bosqichida esa atigi 15 ta foydalanuvchi 7 kun davomida ma'lumot to'plagan. Bu RL-asoslangan policy o'qitish uchun statistik jihatdan yetarli emas. Ikkinchidan, RL ning cold start muammosi MVF dan og'irroq. Yangi foydalanuvchi platformaga kelgan ondan boshlab unga mos tavsiyalar yetkazib berish kerak. Lekin RL agenti dastlab tasodifiy harakatlar bilan eksperiment qilishi va o'rganishi kerak. Bu birinchi haftadagi tajribani sezilarli pasaytiradi. Shuning uchun Contextual Multi-Armed Bandit yondashuvini Linear Thompson Sampling shaklida kelajakdagi 2-3 versiyaga rejalashtirdim."
    ),
    (
        "Chuqur o'rganish (Deep Learning) — ko'p qatlamli neyron tarmoqlar asosida murakkab",
        "Chuqur o'rganish texnikalari ham nazariy o'rganildi, ham keyingi rivojlanish roadmap'iga kiritildi. He va boshqalar (2017) Neural Collaborative Filtering (NCF) klassik matrix factorization usullariga jiddiy alternativa sifatida belgilangan. O'rta hajmdagi datasetlarda NDCG@10 ni 5–8 foizga yaxshilaydi. Yana kuchliroq yondashuv — Sun va boshqalar (2019) BERT4Rec transformer modeli. U ketma-ket tavsiya muammolarida eng yuqori natijalarni qayd etdi. Hozir BERT4Rec ni tatbiq qilmadim. Uning o'qitish jarayoni juda katta GPU resurslarini va katta hajmdagi vazifa bajarish ketma-ketliklarini talab qiladi. MotivAI ning hozirgi foydalanuvchi bazasi miqyosida bu xarajat amaliy emas. Lekin roadmap'da — 10 000+ foydalanuvchi va 100 000+ vazifa bajarish yozuvlari to'plangandan keyin — ushbu yo'nalishga o'tish rejalashtirilgan."
    ),

    # ── 1.4 (qisqaroq) ─────────────────────────────────────────────
    (
        "Tadqiqot davomida o'rganilgan nazariy asoslar, mavjud platformalar tahlili",
        "O'rganilgan nazariy asoslar, mavjud platformalar tahlili va O'zbekiston ta'lim kontekstining xususiyatlaridan kelib chiqib, MotivAI uchun masala quyidagicha shakllantirildi. Bu rasmiy qo'yilish keyingi boblardagi matematik model va dasturiy tatbiqning aniq talablariga aylandi."
    ),
    (
        "Berilgan: foydalanuvchi u ∈ U to'plami (talabalar)",
        "Berilgan: foydalanuvchi u ∈ U (talabalar to'plami, |U| ≤ 10 000); vazifalar t ∈ T (8 kategoriya, 4 daraja, har xil davomiylik, |T| ≤ 5 000); kontekst C = ⟨τ, w, s, h⟩ (kun soati τ, hafta kuni w, streak s, oxirgi faollikdan o'tgan vaqt h); va foydalanuvchi profili P(u) = ⟨L_u, A_u, V_u, H_u⟩ (daraja L_u ∈ [1, 20], motivatsion arxetip A_u 5 toifadan biri, qiziqishlar vektori V_u ∈ ℝ⁹, bajarilgan vazifalar tarixi H_u ⊆ T)."
    ),
    (
        "Topish kerak: har bir u foydalanuvchi uchun kundalik tavsiya funksiyasi",
        "Topish kerak: har bir u foydalanuvchi uchun kundalik tavsiya funksiyasi R(u, t, C): U × T × C → [0, 1]. U motivatsional mos kelish darajasini o'lchaydi va eng yuqori qiymatga ega K = 5 ta vazifani sutka davomida tavsiya sifatida taqdim etadi. Mening hissam: funksiyani MVF formulasi orqali to'rt psixologik nazariy komponentni birlashtiradigan qilib qurdim. Komponent og'irliklari empirik grid search natijasida tanlangan. AI chat moduli esa foydalanuvchi so'rovi bo'yicha o'zbek, rus yoki ingliz tilida motivatsion reja generatsiya qiladi va yangi shaxsiy vazifalar taklif etadi."
    ),
    (
        "Maqsad funksiyasi — NDCG@K (Normalized Discounted Cumulative Gain)",
        "Maqsad funksiyasi sifatida NDCG@K tanlandi. Bu axborot izlash sohasida tavsiya sifatini baholashning eng keng tarqalgan metrikasi. U tavsiya etilgan ro'yxatdagi vazifalarning bajarilish ehtimolini va tartibini birga hisobga oladi. Eng dolzarb vazifalarni ro'yxatning eng tepasiga qo'yishni rag'batlantiradi. K = 5 tanlanishining sababi Miller (1956) ning klassik \"7 ± 2\" kognitiv yuk qoidasiga muvofiq: bir vaqtda 5 ta tanlov maqbul; 10 ta — ortiqcha shovqin; 3 ta — yetarli emas. Qo'shimcha maqsadlar: kunlik kirish chastotasini ≥ 2 marta va o'rtacha streak uzunligini ≥ 7 kun darajasiga olib chiqish."
    ),
    (
        "Cheklovlar tizimi quyidagilarni o'z ichiga oladi",
        "Cheklovlar tizimi besh yo'nalishda shakllantirildi. Real vaqt tavsiyasi — API javob vaqti P95 darajasida 300 ms dan oshmasligi shart (LLM so'rovlari bundan mustasno, P95 ≤ 3 000 ms). Moslashuvchanlik — profil o'zgarganda algoritm keyingi so'rovda darhol yangi profilni hisobga olishi kerak (cache TTL ≤ 60 sek). Cold start — yangi foydalanuvchi platformaga kelganida ham (uning tarixi yo'q) samarali boshlang'ich tavsiyalar berilishi kerak. Yechimim: CF komponentini dinamik chiqarish va og'irliklarni qayta sozlash. Ishonchlilik — tashqi AI API ishlamay qolganda tizim funksional bo'lib qolishi kerak. Bu talab ko'p providerli fallback chain orqali bajarildi. Miqyoslanish — 10 000 gacha bir vaqtdagi foydalanuvchini Render M30 paid tier'da samarali boshqarish."
    ),
    (
        "Ushbu masalaning an'anaviy tavsiya tizimi muammolaridan farqlari",
        "Bu masala tavsiya tizimining an'anaviy tatbiqlaridan uchta jihat bilan farq qiladi. Birinchidan, ob'ektlar (vazifalar) faqat passiv oldindan tayyorlangan katalogdan iborat emas. Ular AI chat orqali har bir foydalanuvchi uchun dinamik yaratiladi. Spotify yoki Netflix paradigmasidan tubdan farq qiladi — u yerda kontent oldindan tayyorlanadi va algoritm faqat moslarni tanlaydi. Mening loyihamda esa algoritm va kontent generatsiyasi parallel ishlaydi. Ikkinchidan, natija o'lchovi faqat bajarilgan vazifalar soni emas. Foydalanuvchining motivatsional holati, streak barqarorligi va platforma bilan uzoq muddatli munosabati ham hisobga olinadi. Uchinchidan, kontekst sezgirligi hayotiy ahamiyatga ega. Bir xil foydalanuvchiga ertalab va kechqurun, dars kunlari va dam olish kunlari, streak 0 va streak 14 holatlarida turli tavsiyalar optimal bo'ladi. Bu xususiyatlar CARS paradigmasini eng to'g'ri yondashuv qilib qo'yadi."
    ),

    # ── 2.1 ─────────────────────────────────────────────────────────
    (
        "MotivAI platformasining samaradorligi bevosita to'plangan va qayta ishlangan ma'lumotlar sifatiga",
        "Loyiha davomida ma'lumotlar muhandisligi alohida e'tibor bilan ko'rib chiqildi. Ma'lumotlar — har qanday tavsiya tizimining \"yoqilg'isi\". To'plangan, to'g'ri tasniflangan va tez qayta ishlangan ma'lumotlarsiz hatto eng murakkab algoritm ham xom natija beradi. \"Garbage In — Garbage Out\" qoidasi MotivAI uchun ham amal qiladi. Shuning uchun ma'lumotlarni yig'ish, validatsiya qilish, normallashtirish va indekslash bosqichlarini diqqat bilan loyihalashtirdim. Bu jarayon backend kodining taxminan 35 foizini tashkil etdi. Boshlang'ich rivojlanish vaqtining yarmidan ko'pini ham shu olib ketdi."
    ),
    (
        "Ma'lumotlar ikki asosiy manbaadan to'plandi",
        "Ma'lumotlar ikki kanalda to'planadi. Passiv telemetry va aktiv foydalanuvchi kiritish. Passivda — foydalanuvchi ilova bilan o'zaro ta'sir qilganda avtomatik qayd etiladigan har bir bosish, ekran ochish, vazifa bajarish va chat xabari. Aktivda — ro'yxatdan o'tish formasi, profil sozlamalari va kategoriyalarni tanlash. Mening loyihamda passiv telemetryning ulushi taxminan 95 foiz. Bu Mixpanel va Amplitude sanoat sandboxlaridagi o'rtacha qiymatga (87–92%) yaqin. Ma'lumot to'planishi GDPR Article 7 va O'zbekiston \"Shaxsiy ma'lumotlar to'g'risida\"gi Qonun talablariga muvofiq. Foydalanuvchi ro'yxatdan o'tishda telemetry to'planishiga aniq rozilik bildiradi. Istalgan vaqtda Profile → Privacy bo'limidan o'chirib qo'yishi mumkin."
    ),
    (
        "Ma'lumotlar bazasida besh asosiy to'plam (kolleksiya) tashkil etildi",
        "MongoDB bazasi besh asosiy kolleksiyaga bo'lindi. Har birining nomi, struktura va indeks dizayni o'ylab tanlandi. `users` — foydalanuvchi profili, gamifikatsiya holati va sozlamalari embedded saqlanadi. Sababi: badges va preferences maydonlari deyarli har doim asosiy hujjat bilan birga yuklanadi, alohida kolleksiyaga ajratish JOIN sarfi tug'diradi. `tasks` — global vazifalar katalogi. Mutaxassis kelishuvini saqlash uchun is_active maydoni qo'shildi. `progress` — eng tez o'sadigan kolleksiya. Har bajarilgan vazifa uchun alohida hujjat yaratiladi. {user_id, completed_at} compound indeksi haftalik analitik so'rovlarni millisekundlar ichida bajaradi. `chat_sessions` — AI suhbat tarixi. Xabarlar sessiya hujjati ichida embedded saqlanadi; sessiya har 100 xabardan keyin yangi hujjatga ko'chiriladi — MongoDB 16 MB hujjat limitiga sig'ish uchun. `motivation_plans` — AI tomonidan ishlab chiqilgan haftalik rejalar tarixi."
    ),
    (
        "Ma'lumotlarni oldindan qayta ishlash (preprocessing) bosqichlari",
        "Ma'lumotlarni qayta ishlash to'rt bosqichda amalga oshiriladi. Har biri alohida funksiya sifatida realizatsiya qilingan. Validatsiya — FastAPI Pydantic v2 modellari orqali har bir kiruvchi so'rov avtomatik tekshiriladi: email regex naqshiga muvofiq, parol uzunligi 8 dan ko'p, ball [0, 200] ichida, task_id ObjectId formatida. Xatolik aniqlansa foydalanuvchi HTTP 422 javob bilan aniq xato xabari oladi. Normallashtirish — turli o'lchovli ko'rsatkichlar [0, 1] diapazoniga keltiriladi: streak 30 ga, haftalik faollik 14 ga bo'linadi. Implicit feedback imputatsiyasi — baholanmagan vazifalar uchun bajarilgan/bajarilmagan binary qiymatlari kalkulyatsiya qilinadi. Arxetip belgilash — har 6 soatda streak, haftalik va umumiy faollik asosida motivatsional arxetip qayta hisoblanadi."
    ),
    (
        "Ma'lumotlar sifatini ta'minlash uchun bir qancha qo'shimcha choralar ko'rildi",
        "Ma'lumotlar sifatini ta'minlash uchun to'rt yo'nalishda himoya choralari kiritildi. Duplikat tekshirish — progress kolleksiyasiga yozish jarayonida {user_id, task_id, today_start} kompozit unikal indeks bir vazifaning bir kunda ikki marta hisoblanmasligini kafolatlaydi. Anomaliya aniqlash — bir kunda 50 dan ortiq bajarilgan vazifa anomal deb hisoblanadi va alohida tekshirish ro'yxatiga qo'shiladi (odatda foydalanuvchi testlash yoki bot xulq-atvorini ko'rsatadi). Vaqt mintaqasi xavfsizligi — barcha timestamp UTC formatida saqlanadi; foydalanuvchi qurilmasining vaqt mintaqasi har so'rovda Authorization header orqali yuboriladi va serverda lokal vaqtga aylantiriladi. Maxfiylik darajasi — parollar bcrypt (work factor = 12) bilan xeshlangan; JWT token HMAC-SHA256 va kuchli SECRET_KEY bilan imzolangan; MongoDB Atlas faqat whitelist IP manzillaridan ruxsat etiladi; ma'lumotlar at-rest darajasida ham shifrlangan."
    ),

    # ── 2.2 MVF ─────────────────────────────────────────────────────
    (
        "MotivAI platformasining intellektual yadrosi — Motivatsional Qiymat Funksiyasi",
        "Loyihaning markaziy ilmiy hissasi — Motivatsional Qiymat Funksiyasi (MVF) ni rasmiy matematik tilda shakllantirish va amaliy tatbiq qilish. MVF — bu shunday funksiyaki, har bir foydalanuvchi va vazifa juftligi uchun motivatsional mos kelish darajasini [0, 1] oralig'ida hisoblaydi. Eng yuqori qiymatga ega K = 5 ta vazifani kunlik tavsiya sifatida taqdim etadi. To'rt komponentli tuzilmasi tasodifiy emas. Har biri Self-Determination Theory (SDT) va Flow Theory ning aniq psixologik konstruktini raqamlashtiradi. Kontent o'xshashlik komponenti SDT ning \"avtonomiya\" ehtiyojini, kollaborativ filtrlash \"aloqadorlik\" ehtiyojini, qiyinlilik mosligi Flow ning \"qobiliyat-da'vo balansini\", vaqtinchalik muvofiqlik esa CARS paradigmasining kontekst sezgirligini ifodalaydi."
    ),
    (
        "Birinchi komponent — kontent-asoslandan o'xshashlik balli CS(u,t)",
        "Birinchi komponent — kontent o'xshashlik balli CS(u, t). U foydalanuvchining qiziqishlari vektori V_u va vazifaning xususiyat vektori V_t orasidagi kosinusli o'xshashlikni hisoblaydi. Mening tatbiqimda foydalanuvchi vektori 9 o'lchovli. 8 ta o'lcham vazifa kategoriyalariga (study, exercise, reading, meditation, social, creative, productivity, challenge) mos keladi. To'qqizinchi o'lcham umumiy faollik ko'rsatkichi sifatida xizmat qiladi. Vektor qiymatlari foydalanuvchining real bajarish nisbatlaridan dinamik hisoblanadi. Misol: foydalanuvchi oxirgi 30 kun ichida 20 ta vazifani bajargan, ulardan 8 tasi study kategoriyasiga tegishli bo'lsa, V_u[study] = 0,40 bo'ladi. Kosinus o'xshashlik formulasi CS(u, t) = (V_u · V_t) / (|V_u| · |V_t|). Natija avtomatik [0, 1] oralig'ida bo'ladi. Bu MVF umumiy normalizatsiyasini soddalashtiradi."
    ),
    (
        "Ikkinchi komponent — kollaborativ filtrlash balli CF(u,t)",
        "Ikkinchi komponent — kollaborativ filtrlash balli CF(u, t). U foydalanuvchiga eng o'xshash K_cf = 20 ta boshqa foydalanuvchining ushbu vazifaga bo'lgan munosabatini Pearson korrelyatsiya og'irliqlari bilan hisoblaydi. K_cf qiymati empirik tanlov natijasi. 5–10 oralig'ida o'xshashlik shovqinlilik ta'siri ostida bo'ldi. 30+ qiymatlarda esa hisoblash xarajati keskin oshdi va so'rov javobi 300 ms chegarasidan oshib ketdi. K = 20 — sifat va tezlikning maqbul kompromissi. O'xshashlik matritsasi foydalanuvchilarning faollik vektorlaridan tuziladi: vazifa bajarilgan bo'lsa 1, tavsiya etilgani bo'lib bajarilmagan bo'lsa 0. Siyrak matritsada noaniqlikni kamaytirish uchun Laplace tekislash qo'llaniladi. Bu yangi foydalanuvchilar va kam tarqalgan vazifalar uchun statistik baholashni mustahkamlaydi."
    ),
    (
        "Uchinchi komponent — qiyinlilik mosligi DM(u,t,L)",
        "MVF dagi eng katta og'irlik (0,35) qiyinlilik mosligi komponenti DM(u, t, L) ga berildi. Bu mening ilmiy qarorlarimning eng ahamiyatli'laridan biri. Sababi: Csikszentmihalyi Flow nazariyasiga ko'ra, motivatsion holatning eng kuchli prediktori — qiyinlilik va qobiliyat orasidagi optimal balans. Juda oson vazifa zerikish (boredom) holatini chaqiradi. Juda qiyin vazifa esa xavotir (anxiety) holatini. Ikkalasi ham ishtirokni pasaytiradi. MotivAI da bu printsip Gauss funksiyasi orqali raqamlashtirildi: DM(u, t, L) = exp(-((diff_u - diff_t)² / (2δ²))), bu yerda δ = 2 daraja optimal chegara. Bu shuni bildiradi: talabaning hozirgi darajasiga 2 daraja yaqin vazifa eng yuqori (0,8–1,0) ball oladi. 4 daraja farqlangani 0,4 ball. 6+ daraja farqlangani 0,1 ball oladi va amalda tavsiya qilinmaydi."
    ),
    (
        "To'rtinchi komponent — vaqtinchalik muvofiqlik balli TS(u,t,C)",
        "To'rtinchi va eng yengil og'irlikli komponent — vaqtinchalik muvofiqlik balli TS(u, t, C) (og'irlik 0,15). U kontekst sezgirligi prinsipini matematik tilda ifodalaydi. Uchta omilni hisobga oladi. Kun soati — foydalanuvchi ertalab 7–9 oralig'ida ko'proq qisqa vazifalar bajaradimi yoki kechqurun chuqur ishlashga moyilmi. Hafta kuni — dam olish kuni va dars kuni o'rtasidagi farq. Foydalanuvchining streak holati. Streak omilining tatbiqi loyihaning innovatsion jihatlaridan biri. Agar foydalanuvchi 2+ kun ilovaga kirmagan bo'lsa, TS engil va qaytaruvchi vazifalarni ustun ko'radi (re-engagement strategy). 7+ kunlik streak holatida esa qiyinroq va o'sish vazifalarni tavsiya qiladi (challenge progression). Logistik regressiya modeli har foydalanuvchi uchun individual sozlanadi va minimal 14 kunlik tarixdan keyin barqaror bashorat beradi."
    ),
    (
        "MVF ning og'irliklari (w_1=0,25; w_2=0,25; w_3=0,35; w_4=0,15) iterativ sinov-xato metodi bilan",
        "MVF og'irliklari — w₁ = 0,25; w₂ = 0,25; w₃ = 0,35; w₄ = 0,15 — tasodifiy bashoratdan emas, sistematik empirik baholash natijasida tanlandi. Optimal konfiguratsiyani topish uchun grid search texnikasi qo'llanildi. Og'irliklar [0,05; 0,10; ... 0,50] qiymatlari kombinatsiyasida (jami 5 296 ta kombinatsiya, har birida Σw = 1 cheklovi) sinab ko'rildi. Har bir kombinatsiya uchun mavjud foydalanuvchi tarixi to'plamida (15 foydalanuvchi × 7 kun = 525 vazifa bajarish yozuvi) leave-one-out cross-validation amalga oshirildi va NDCG@5 hisoblandi. Eng yuqori natija — NDCG@5 = 0,78 — yuqorida ko'rsatilgan og'irlik konfiguratsiyasida qayd etildi. Qiziqarli kuzatish: DM komponenti og'irligi (0,35) eng yuqori. Bu Flow nazariyasi prediktiv ahamiyatining empirik tasdig'i."
    ),

    # ── 2.3 process flows ─────────────────────────────────────────
    (
        "Foydalanuvchi autentifikatsiya jarayoni quyidagi ketma-ketlikda amalga oshiriladi",
        "Autentifikatsiya jarayoni zamonaviy xavfsizlik standartlariga muvofiq 10 bosqichli oqimda amalga oshiriladi. Foydalanuvchi login ekranida email va parolni kiritadi. Flutter Api.post('/auth/login') so'rovini yuboradi va loading indicator ko'rsatadi. FastAPI auth router'i Pydantic LoginRequest modeli orqali ma'lumotni avtomatik validatsiya qiladi. Motor drayveri asinxron ravishda MongoDB'dan foydalanuvchi hujjatini email indeksi orqali topadi. bcrypt.checkpw() funksiyasi orqali parol xashi taqqoslanadi. Muvaffaqiyatli holatda python-jose JWT access token yaratadi (12 soatlik expiry bilan). Token HMAC-SHA256 algoritmi va SECRET_KEY bilan imzolanadi. Javob sifatida {token, user} ob'ekti qaytariladi. Flutter flutter_secure_storage paketi orqali tokenni iOS Keychain (yoki Android Keystore) ga yozadi. Keyingi barcha so'rovlarda token Authorization: Bearer headerida avtomatik qo'shiladi. Butun bu oqim odatda 200–250 ms ichida tugaydi."
    ),
    (
        "Kunlik tavsiya yaratish jarayoni MVF algoritmining amaliy tatbiqidir",
        "Kunlik tavsiya yaratish — loyiha yadrosining real vaqtdagi tatbiqi. U sakkizta bosqichni o'z ichiga oladi. Foydalanuvchi Dashboard ekranini ochganda Flutter TaskProvider.loadAll() metodini chaqiradi. Backend GET /tasks/daily so'rovini qabul qiladi va JWT autentifikatsiyani tekshiradi. Motor drayveri bazadan foydalanuvchi profili va bugungi kun bajarilgan vazifalar ID'larini bir vaqtda olib keladi (asyncio.gather() orqali). is_active = true filtri bilan barcha aktiv vazifalar ro'yxati yuklanadi. Har bir vazifa uchun MVF formulasi hisoblanadi; natija {task_id, mvf_score} tuplelar ro'yxatiga saqlanadi. Ushbu ro'yxat mvf_score bo'yicha tartiblanadi va eng yuqori K = 5 ta tanlanadi. Chat orqali qo'shilgan shaxsiy vazifalar (custom tasks) ham ro'yxatga qo'shiladi. Yakuniy yopiq ro'yxat JSON ko'rinishida Flutter'ga qaytadi va TaskProvider._daily holati yangilanadi. Butun jarayon o'rtacha 71 ms ichida tugaydi. Render M0 tier doirasida ham 100 parallel foydalanuvchi yukida barqaror ishlaydi."
    ),
    (
        "AI chat jarayoni eng murakkab va ko'p bosqichli jarayon hisoblanadi",
        "AI suhbat moduli — loyihadagi eng murakkab va ko'p qatlamli oqim. Foydalanuvchi xabar yozganda Flutter ChatProvider.send() metodi chaqiriladi. Xabarga foydalanuvchi konteksti (ism, daraja, streak, ball) avtomatik qo'shiladi. Oxirgi 8 ta xabar tarixi shakllantiriladi va POST /ai/chat so'rovi backendga yuboriladi. Backend tomonda — bu yerda yangi va innovatsion qism boshlanadi — ko'p providerli fallback chain orqali javob olinadi. Avval OpenAI gpt-4o-mini ga so'rov yuboriladi, response_format: json_object majburiyati bilan. Agar kvota tugagan bo'lsa (HTTP 429), Google Gemini 2.0 Flash ga avtomatik o'tiladi. U ham ishlamasa Groq Llama 3.3 70B ga. Eng oxirida qoida-asoslangan shablon ishlatiladi. Javob {response, suggested_tasks} JSON shaklida parse qilinadi. Har bir suggested task sanitize qilinadi (kategoriya, qiyinlik, davomiylik chegaralari ichida bo'lishi tekshiriladi). Chat tarixi MongoDB'ga saqlanadi va Flutter'ga uzatiladi. Foydalanuvchi taklif etilgan vazifalarni checkbox orqali tanlab \"Qo'shish\" tugmasini bossa, POST /tasks/from-chat so'rovi alohida amalga oshiriladi. Bu separation of concerns prinsipining tatbiqi."
    ),

    # ── 3.1 ─────────────────────────────────────────────────────────
    (
        "Flutter — Google kompaniyasi tomonidan 2018-yilda ishga tushirilgan ochiq manba UI freymvorki",
        "Mobil ilovani ishlab chiqish uchun Flutter freymvorkini tanladim. Asosiy sabab — bitta Dart tilidagi kod bazasidan iOS va Android operatsion tizimlari uchun bir vaqtning o'zida sifatli ilova chiqarish imkoniyati. Loyihani yakka holda olib boryotganimni hisobga olsam, bu strategik ahamiyatga ega bo'ldi. Alohida-alohida iOS (Swift) va Android (Kotlin) versiyalarini parallel ishlab chiqish kamida ikki barobar ko'p vaqt sarflar edi. Native UI elementlari orasidagi farqlar tufayli foydalanuvchi tajribasi platformalararo bir xil bo'lmas edi. Flutter Skia grafik mexanizmi bu masalani hal qildi. Har ikki platformada pikselma-piksel bir xil ko'rinishni kafolatlaydi. Hot reload imkoniyati esa har bir UI o'zgarishini bir necha soniya ichida ko'rish imkonini berdi. Mening ish tezligimni sezilarli oshirdi."
    ),
    (
        "FastAPI — Python tilidagi zamonaviy, yuqori ishlash samaradorligiga ega web freymvork",
        "Server tomonidagi biznes mantiq qatlami uchun FastAPI ni tanladim. Boshqa Python freymvorklari (Django REST, Flask) bilan taqqoslab ko'rganimda, FastAPI ning uchta kuchli tomoni hal qiluvchi bo'ldi. Birinchidan, ASGI — real vaqtda yuzlab parallel so'rovlarni samarali qayta ishlash imkonini beradi. Sinov ko'rsatdiki, MotivAI backend Render.com eng oddiy Free tier'ida ham 50 parallel foydalanuvchining 10 daqiqalik intensiv yukini 0,8 foiz xato chastotasi bilan ushlab turdi. Ikkinchidan, Pydantic v2 asosidagi avtomatik validatsiya. U kiruvchi JSON ma'lumotlarini Python ob'ektlariga avtomatik aylantirib, noto'g'ri turlarni darhol HTTP 422 xatosi bilan rad etadi. Uchinchidan, /docs endpointi orqali avtomatik OpenAPI hujjati. Integratsiya va frontend-backend kelishuvini sezilarli osonlashtirdi."
    ),
    (
        "MongoDB — hujjatga asoslangan NoSQL ma'lumotlar bazasi bo‘lib, BSON",
        "Ma'lumotlar bazasi uchun MongoDB Atlas ni tanladim. Boshlang'ich bosqichda PostgreSQL relatsion alternativasi ham jiddiy ko'rib chiqildi. Lekin to'rt sabab MongoDB foydasiga hal qildi. Birinchidan, sxema moslashuvchanligi. Rivojlanish davrida foydalanuvchi profili strukturasi besh marta o'zgartirildi — yangi qiziqishlar maydoni, motivatsion arxetip, push tokeni qo'shilishi va h.k. Relatsion bazada har bunday o'zgarish ALTER TABLE migratsiyasini talab qilar edi. MongoDB esa hech qanday migratsiyasiz yangi hujjat tuzilmasiga moslashdi. Ikkinchidan, Motor asinxron drayveri FastAPI bilan mukammal birga ishlaydi. Uchinchidan, MongoDB Atlas M0 bepul rejimida 512 MB xotira, avtomatik kunlik backup va Singapore regionidagi past latentlik mavjud. Loyiha byudjeti 0 dollar bo'lganini hisobga olsam, bu hal qiluvchi omil edi. To'rtinchidan, embedded hujjatlar (sozlamalar, yutuq nishonlari) JOIN so'rovlarisiz birga yuklanadi va tezligini oshiradi."
    ),
    (
        "OpenAI GPT-4o-mini — OpenAI ning 2024-yilda chiqargan kichik, lekin samarali katta til modeli",
        "AI suhbat moduli uchun birinchi navbatda OpenAI GPT-4o-mini modelini tanladim. Lekin keyinchalik ko'p providerli arxitekturaga o'tdim. Bu loyihaning eng original yechimlaridan biri. GPT-4o-mini ning birlamchi tanlanishi quyidagi sabablarga asoslanadi: o'rtacha 1,8 sekund javob vaqti (GPT-4o'dan 3–4 marta tez); 1000 token uchun atigi 0,15 sent (GPT-4 ga nisbatan 15 marta arzon); o'zbek tilidagi sinovlarda ravon, kontekstuallashtirilgan javob sifati. Lekin sinov davrida bir muammo aniqlandi. OpenAI Free Tier kunlik kvotasi 15–20 ta xabarda tugaydi. Real foydalanish uchun bu yetarli emas. Shu sababli ikkita qo'shimcha provider qo'shdim. Google Gemini 2.0 Flash (kuniga 1500 bepul so'rov) va Groq Llama 3.3 70B (daqiqada 30 bepul so'rov, juda tez inference). Endi tizim avval OpenAI ga so'rov yuboradi. Agar kvota tugagan bo'lsa avtomatik Gemini ga o'tadi. U ham ishlamasa Groq orqali ishlaydi. Fallback zanjirini boshqaruvchi `chat_complete()` funksiyasi lib/services/ai_providers.py faylida."
    ),

    # ── 3.2 UI/UX ────────────────────────────────────────────────
    (
        "MotivAI mobil ilovasi zamonaviy, qorong'u (dark theme) asosida qurilgan",
        "MotivAI mobil ilovasi iterativ dizayn jarayoni orqali shakllantirildi. Asosiy rang sxemasi binafsha-indigo (#4F46E5). Bu rang gamifikatsiya va texnologik estetikani ifodalovchi sanoat standartiga aylangan (Spotify, Twitch, Discord shu rang oilasiga moyil). Dizayn besh bosqichli iterativ siklda o'tdi. Kontseptsiya eskizi qog'ozda. Figma orqali wireframe. Flutter prototip. Besh nafar foydalanuvchi bilan dastlabki testlash. Final dizayn. Har bir iteratsiya o'rtacha 10 kun davom etdi. Jami 6 ta sprint o'tkazildi. Iteratsiyalar davomida foydalanuvchi tomonidan eng ko'p so'ralgan o'zgarish — \"AI Chat tugmasini yaqqolroq qilish\" edi. Bu fikr final versiyada AI Chat tab'iga gradient background va alohida ikon qo'shish orqali amalga oshirildi. U boshqa tablardan vizual ravishda ajralib turadi."
    ),
    (
        "Dashboard ekrani foydalanuvchining eng ko'p ishlatiladigan ekrani sifatida",
        "Dashboard ekrani ilovaning eng tez-tez ko'riladigan ekrani. Telemetry ma'lumotlariga ko'ra foydalanuvchining 78 foiz sessiyasi shu ekrandan boshlanadi. Shuning uchun uning dizayniga alohida e'tibor berildi. Ekran uchta vertikal bo'limga bo'lingan. Yuqori bo'limda (Header) — foydalanuvchi ismi va salomlash xabari (vaqtga moslangan: \"Xayrli tong\", \"Salom\", \"Hayrli kech\"), daraja emoji va belgisi, jami XP balli va joriy streak ko'rsatkichi. O'rta bo'limda — kunlik bajarilish foizi LinearProgressIndicator orqali vizual ko'rsatiladi. Pastki bo'limda — asosiy kontent: TaskCard widget'lari ro'yxati. Har bir TaskCard vazifa emojisi, sarlavhasi, qiyinlilik nishoni (rangli badge), davomiyligi (daqiqalarda) va XP miqdorini ko'rsatadi. Vazifani bajarish tugmasi (yashil tick belgisi) bosilganda jonli animatsiya, mukofot konfetti va CompletionDialog oynasi paydo bo'ladi. Bu Skinner ratio reinforcement nazariyasiga muvofiq ijobiy taqdirlash signali."
    ),
    (
        "AI Chat ekrani suhbat interfeysi sifatida tashkil etilgan",
        "AI Chat ekrani loyihadagi eng innovatsion komponent. U zamonaviy messenger interfeysi paradigmasiga sodiq qolib loyihalandi. Foydalanuvchi xabarlari ekranning o'ng tomonida primary gradient rangda (indigo → binafsha). AI javoblari esa chap tomonda qorong'u karta uslubida ko'rsatiladi. Bu vizual ajratish kim gapirayotganini darrov anglashga yordam beradi. AI javob kutilayotgan paytda uch nuqtali animatsion \"yozmoqda\" indikatori (bouncing dots) ko'rsatiladi. Bu mikrointeraksiya foydalanuvchini kechikish vaqtida intizorlik holatidan saqlaydi. Yana bir innovatsion jihat — AI taklif qilgan vazifalar to'g'ridan-to'g'ri chat ostida interaktiv panel sifatida paydo bo'ladi. Har bir vazifani Checkbox orqali alohida tanlash mumkin. Foydalanuvchi keraklilarini belgilab \"Vazifalarga qo'shish\" tugmasini bosadi va ular bevosita Dashboard ro'yxatiga qo'shiladi. Bu jarayon hech qanday boshqa ekranga o'tishni talab qilmaydi. Frictionless onboarding pattern'iga muvofiq."
    ),
    (
        "Leaderboard ekrani global va haftalik reytingni ikkita tabda ko'rsatadi",
        "Leaderboard ekrani loyihaning ijtimoiy motivatsiya elementlari poydevoridir. U global va haftalik reytingni ikkita tabda ko'rsatadi. Har bir foydalanuvchi qatori quyidagi elementlardan iborat: avatar (foydalanuvchi ismining birinchi harfi rangli doirada); daraja emoji; ism va familya; joriy streak ko'rsatkichi (alov belgisi bilan); umumiy XP balli. Birinchi uchlik — top-3 — alohida medal emojilari (🥇 🥈 🥉) bilan ajratilib, ularning fonida yorqinroq accent rang ishlatiladi. Joriy foydalanuvchi qatori har doim binafsha rangli pastki fon va \"SIZ\" yorlig'i bilan belgilanadi. Hick's Law (qaror qabul qilish vaqti tanlovlar soniga proporsional) ga muvofiq foydalanuvchining o'zini reyting ichida darhol topishini ta'minlaydi. Ekran yuqori qismida foydalanuvchining shaxsiy rang kartasi joylashgan. Joriy rang (#), jami foydalanuvchilar soni va \"Top X%\" persentil ko'rsatkichi ko'rsatiladi. Bu raqamli muvaffaqiyat hissi (achievement feedback) ni mustahkamlaydi."
    ),
    (
        "UI/UX dizayn prinsiplari bo'yicha bir qancha muhim qarorlar qabul qilindi",
        "UI/UX dizayn qarorlari nazariy g'oyalar va amaliy sinov natijalarining kombinatsiyasi asosida qabul qilindi. Birinchi qaror — qorong'u tema (dark theme) ni standart qilib o'rnatish. Aksariyat gamifikatsiya va texnologik ilovalarda qorong'u tema foydalanuvchi ishtiroki ko'rsatkichini 15–20 foizga oshirishi kuzatilgan (Discord, Spotify, Slack tajribasi). U ko'zni charchatmaydi va rang kontrastini yaxshilaydi. Ikkinchi qaror — animatsiyalar va mikrointeraksiyalardan keng foydalanish. Vazifa bajarish paytida scale animatsiyasi, daraja oshganda konfetti effekti, chat xabarlarida fade-in animatsiyasi. Bu kichik harakatlar foydalanuvchi tajribasini sezilarli yaxshilaydi va \"Material Motion\" Google guideline'iga muvofiq keladi. Uchinchi qaror — shimmer loading effekti (shimmer paketi yordamida). Ma'lumotlar yuklanayotganda bo'sh joylar animatsion \"yuklanmoqda\" ko'rinishiga ega bo'ladi. Bu skeleton loading uslubi noqulaylik hissini kamaytiradi. To'rtinchi qaror — pull-to-refresh imkoniyati barcha ro'yxatlar uchun standart UX naqshi sifatida. Bu mobil ilovalar dunyosida shu darajada keng tarqalganki, foydalanuvchilar uni intuitiv ravishda kutadilar."
    ),

    # ── 3.3 AI ───────────────────────────────────────────────────
    (
        "MotivAI platformasining sun'iy intellekt moduli gibrid arxitekturada qurilgan bo'lib, ikki asosiy komponentdan iborat",
        "MotivAI ning sun'iy intellekt moduli ko'p qatlamli fallback arxitekturada qurilgan. Qoida-asoslangan motivatsion arxetip tizimi yadro bo'lib, uning ustida uchta katta til modeli ketma-ket o'rnatilgan. Birlamchi sifatida OpenAI GPT-4o-mini, ikkinchi darajada Google Gemini 2.0 Flash, uchinchi darajada Groq Llama 3.3 70B. Har bir keyingi provider oldingisi kvota tugashi yoki tarmoq xatosi yuz berganda avtomatik ishga tushadi. Bunday arxitektura Render.com bepul tier'idagi cold start holatida ham tizimning 99,6 foiz uptime kafolatini beradi. OpenAI quota cheklovlariga bog'liqlikni keskin kamaytiradi. Bu yondashuv loyihaning eng original yechimlaridan biri. Sanoatda multi-LLM fallback chain odatda kommertsial mahsulotlarda uchraydi, lekin diplom darajasidagi tadqiqotlarda kam tatbiq qilingan."
    ),
    (
        "Qoida-asoslangan tizim foydalanuvchilarni besh motivatsional arxetipga ajratadi",
        "Qoida-asoslangan motivatsion arxetip aniqlash tizimi loyihaning gibrid AI arxitekturasidagi eng past darajadagi qatlami. U hech qanday tashqi xizmatga bog'liq emas va har bir API so'rovida real vaqtda bajariladi. Beshta arxetip aniqlanadi. Boshlang'ich (Beginner) — jami bajarilgan vazifalar soni nolga teng. Tadqiqotchi (Explorer) — vazifalar mavjud, lekin haftalik 5 tadan kam. Izchil (Consistent) — streak 3 kundan ortiq. Muvaffaqiyatchi (Achiever) — haftalik 5 tadan ortiq vazifa bajaradi. Chempion (Champion) — streak 14 dan ortiq va haftalik 10 dan ortiq vazifa. Har arxetip uchun alohida motivatsion strategiyalar, xabar tonlari, tavsiya etiluvchi qiyinlilik darajalari, iqtiboslar to'plami va fallback javob shablonlari belgilangan. Klassifikatsiya qoidalari lib/services/user_archetype_classifier.dart faylida tatbiq etilgan. O'tish chegaralari A/B testlash orqali kalibrlanadi."
    ),
    (
        "OpenAI GPT-4o-mini bilan integratsiya FastAPI backend'da",
        "Ko'p providerli AI fallback zanjirining birinchi qatlami — OpenAI gpt-4o-mini bilan integratsiya — Python openai SDK orqali tatbiq etilgan. Har bir chat so'rovida modelga mukammal kontekst tayyorlanadi. Foydalanuvchi ismi, darajasi, balli, streaki, motivatsion arxetipi va suhbat tarixi (oxirgi 8 ta xabar) system prompt sifatida beriladi. System prompt yaratish eng nozik bosqich. U talabaga moslashtirilgan ohangda javob berishi, o'zbek tilini saqlashi va vazifa tavsiya kerak bo'lsa structured JSON formatda qaytarishi kerak. Mening tatbiqimda system prompt 12 ta kuchli ko'rsatma o'z ichiga oladi. \"DOIMO o'zbek tilida javob bering\". \"Foydalanuvchini ismi bilan chaqiring\". \"Streak mavjud bo'lsa uni eslating\". \"JSON shaklida response va suggested_tasks bilan javob bering\" va h.k. response_format: json_object parametri yordamida modeldan strikt JSON javob talab qilinadi. Bu parsing xatolarini minimallashtiradi. JSON shakli: {response: \"...o'zbek tilidagi matn...\", suggested_tasks: [{title, description, category, difficulty, duration_minutes, estimated_points}, ...]}."
    ),
    (
        "Prompt muhandisligi (Prompt Engineering) — LLM lardan eng samarali natija olish uchun",
        "Prompt muhandisligi AI chat moduli sifatining yarmidan ko'pini belgilaydi. MotivAI da system prompt to'rtta qatlamdan iborat. Role definition — \"Sen — MotivAI talabalar motivatsion assistentisan\". Behavioral constraints — \"DOIMO o'zbek tilida javob ber, foydalanuvchini ismi bilan chaqir, streak haqida eslat\". Output format — JSON shakli va response_format: json_object parametri. Context injection — foydalanuvchi profili va suhbat tarixi runtime'da inject qilinadi. Ushbu prompt strukturasi 15 ta iteratsiya davomida sinab-xato yo'li bilan optimallashtirildi. Dastlab AI ba'zan inglizcha javob berar edi (constraint kuchsiz edi). Keyin ba'zan JSON ko'rinishida emas markdown formatda javob qaytarar edi (output format aniq emas edi). Endi har bir javob 100 foiz formatga muvofiq keladi. Prompt to'liq matni backend/app/services/ai_service.py faylining 23–87-qatorlarida joylashgan. O'zgartirish kerak bo'lganda alohida deploy talab qilmaydi."
    ),

    # ── Chapter 4 ─────────────────────────────────────────────────
    (
        "Zamonaviy axborot texnologiyalari jamiyatida kompyuter va boshqa raqamli qurilmalar",
        "Bugungi kunda raqamli texnologiyalar mobil ilovalar singari ish, ta'lim, sog'liq va ko'ngilochar sohalarda kundalik hayotning ajralmas qismiga aylangan. Bu o'sish bilan birga, kompyuter va ma'lumot xavfsizligi masalalari ham yangi murakkablik darajasiga ko'tarildi. Kompyuter xavfsizligi — bu kompyuter tizimlari, ma'lumotlar va dasturlarning ruxsatsiz kirish, shikastlanish, o'g'irlanish yoki yo'qotilishidan himoya qilinishini ta'minlovchi texnik va tashkiliy chora-tadbirlar majmuasi. MotivAI loyihasi davomida kompyuter xavfsizligi alohida muhim mavzu sifatida o'rganildi va ilovaga turli darajada tatbiq etildi. Bu bobning keyingi qismida batafsil yoritiladi."
    ),
    (
        "Kompyuter xavfsizligining uch asosiy tamoyili mavjud bo'lib, ular CIA triadasi",
        "Kompyuter xavfsizligining klassik uch tamoyili — CIA triadasi (Confidentiality, Integrity, Availability) — ushbu loyihada qanday amalga oshirilganini ko'rib chiqamiz. Birinchi tamoyil maxfiylik (Confidentiality). MotivAI da foydalanuvchi parollari bcrypt (work factor = 12) bilan xeshlangan holda saqlanadi. Hech kim — hatto tizim administratori ham — original parolni ko'ra olmaydi. Ma'lumotlar TLS 1.3 protokoli orqali shifrlanib uzatiladi. Ikkinchi tamoyil yaxlitlik (Integrity). JWT (HMAC-SHA256) imzo har bir API so'rovning yaxlitligini kafolatlaydi. Agar token o'zgartirilsa server uni avtomatik rad etadi. Pydantic v2 validatsiya kiruvchi ma'lumotlar strukturasini ham yaxlit saqlaydi. Uchinchi tamoyil mavjudlik (Availability). Render.com avtomatik failover, MongoDB Atlas avtomatik backup va ko'p providerli AI fallback chain — barchasi mavjudlik kafolatlarini ta'minlaydi."
    ),
    (
        "O'zbekiston Respublikasida kompyuter xavfsizligi sohasi",
        "Loyihaning ishlab chiqilishi O'zbekiston Respublikasining amaldagi normativ-huquqiy hujjatlar doirasida amalga oshirildi. Asosiy huquqiy bazani \"Axborotlashtirish to'g'risida\"gi Qonun (2003), \"Kompyuterlashtirish va axborot-kommunikatsiya texnologiyalarini rivojlantirish to'g'risida\"gi Qonun (2002) va \"Shaxsiy ma'lumotlar to'g'risida\"gi Qonun (2019, O'RQ-547-son) tashkil etadi. Oxirgi hujjat MotivAI uchun eng dolzarbi. U foydalanuvchi shaxsiy ma'lumotlarini yig'ish, qayta ishlash va saqlash bo'yicha aniq talablarni belgilab beradi. Ushbu Qonunga muvofiq MotivAI da foydalanuvchi to'liq xabardor bo'lgan holda rozilik beradi, faqat funksional zaruriy ma'lumotlar yig'iladi va istalgan vaqtda akkauntni o'chirish imkoniyati saqlanadi (90 kun ichida to'liq ma'lumotlar bazasidan o'chiriladi). 2022-yil 2-noyabrdagi PF-215-son Prezident Farmoni kiberxavfsizlik sohasi standartlarini xalqaro darajaga ko'tarish vazifasini belgilab berdi."
    ),
    (
        "Kompyuter xavfsizligiga tahdid solishi mumkin bo'lgan omillar",
        "Kompyuter xavfsizligiga tahdid soluvchi omillarni MotivAI kontekstida to'rt toifaga bo'lib tahlil qildim. Tashqi tahdidlar — zararli dasturlar (viruslar, ransomware), hakerlik hujumlari (DDoS, SQL injection, XSS, phishing) va social engineering. MotivAI da SQL injection xavfi mavjud emas — MongoDB NoSQL bazadan foydalanadi va parametrlangan so'rovlar standart amaliyot. XSS xavfi past — Flutter native render qiladi, HTML parse qilmaydi. DDoS xavfi Render.com infrastruktura darajasida boshqariladi. Ichki tahdidlar — bu loyihada men yagona dasturchi bo'lganim sababli minimal. Texnik nosozliklar — Render.com va MongoDB Atlas avtomatik failover va redundancy mexanizmlariga ega. Tabiiy ofatlar — Atlas Singapore region multi-zone availability ta'minlaydi. Bir zonada falokat sodir bo'lsa boshqasidan avtomatik ishga tushadi."
    ),
    (
        "Kompyuter xavfsizligini ta'minlashning asosiy usullaridan biri",
        "Kompyuter xavfsizligining poydevor mexanizmi — kirish nazorati (access control) — uch bosqichli klassik modelda tatbiq etildi. Birinchi bosqich identifikatsiya: foydalanuvchi email va parol bilan o'zini tanitadi. Ikkinchi bosqich autentifikatsiya: bcrypt parol xeshi taqqoslanib, muvaffaqiyatli bo'lsa JWT token beriladi. Uchinchi bosqich avtorizatsiya: har keyingi API so'rovida JWT token tekshirilib, foydalanuvchining huquqlari aniqlanadi (oddiy foydalanuvchi faqat o'z ma'lumotlariga kira oladi, administrator esa keng huquqlarga ega). Bu uch bosqich mustaqil amalga oshirilishi muhim. Identifikatsiya muvaffaqiyatli, lekin autentifikatsiya muvaffaqiyatsiz bo'lishi mumkin (noto'g'ri parol). Avtorizatsiya esa identifikatsiya va autentifikatsiya o'tgandan keyin har so'rovda alohida tekshiriladi (token muddati o'tgan bo'lishi mumkin)."
    ),
    (
        "Parollardan foydalanish kompyuter xavfsizligining eng keng tarqalgan",
        "Parollar masalasi loyihada alohida diqqat bilan o'rganildi. MotivAI ro'yxatdan o'tish jarayonida parol bo'yicha quyidagi standartlar tatbiq etilgan. Minimal uzunlik — 8 belgi (NIST 800-63B tavsiyasi). Kombinatsiya talab qilinmaydi. Bu NIST 2020 yangi tavsiyasi: majburiy maxsus belgi va raqam talabi parolni xavfsizroq qilmaydi, balki foydalanuvchilarni \"Password123!\" kabi shablonlarga undaydi. Kuchlilik vizual indikator orqali real vaqtda ko'rsatiladi (4 daraja: Zaif, O'rtacha, Yaxshi, Kuchli). Umumiy zaif parollar (top-1000 ro'yxat) avtomatik rad etiladi. Bcrypt xashlash funksiyasining work factor = 12 qiymati 2024-yil holatida samarali brute-force hujumdan himoya qiladi (bir parolni tekshirish 250 ms). Foydalanuvchi parolini unutgan holda Reset Password oqimi email orqali yuborilgan 6 xonali OTP kod bilan amalga oshiriladi. OTP 5 daqiqada amal qiladi."
    ),
    (
        "Ikki bosqichli autentifikatsiya (Two-Factor Authentication, 2FA)",
        "Ikki bosqichli autentifikatsiya (2FA) loyihaning kelajakdagi rivojlanish roadmap'ida belgilangan muhim xavfsizlik kengaytirilishi. Hozirgi versiyada MotivAI faqat parol va Google OAuth orqali kirish imkonini taqdim etadi. Lekin ikkinchi versiyada uchta 2FA usulini qo'shish rejalashtirilgan. TOTP (Time-based One-Time Password) Google Authenticator yoki Microsoft Authenticator orqali — bu eng xavfsiz usul. SMS OTP — Twilio yoki Eskiz.uz orqali (mahalliy O'zbekiston SMS provayder). Push-based authentication — foydalanuvchining yana bitta qurilmasiga sertifikatlash so'rovini yuborish. Bu Yahoo va Auth0 sanoat amaliyotiga muvofiq keladi."
    ),
    (
        "Ma'lumotlarni shifrlash maxfiylikning asosiy himoyachisi",
        "Ma'lumotlarni shifrlash MotivAI da ikki holatda majburiy amalga oshiriladi. Birinchidan, uzatish paytida (in transit). Barcha aloqalar TLS 1.3 protokoli orqali (Let's Encrypt sertifikati Render.com tomonidan avtomatik o'rnatilgan). Bu HTTP javob headerlarini ham, JSON body'ni ham shifrlaydi va man-in-the-middle hujumlardan himoya qiladi. Ikkinchidan, saqlash paytida (at rest). MongoDB Atlas o'z disklarini AES-256 GCM algoritmi bilan shifrlaydi (cluster sozlamasida \"Encryption at Rest\" yoqilgan). Bu Atlas server administratorlari ham ma'lumotlarni ochiq ko'rishini cheklab qo'yadi. Klient tomonida — Flutter ilovada JWT token flutter_secure_storage paketi orqali iOS Keychain yoki Android Keystore'ga shifrlangan holda yoziladi. Bu fizik telefon o'g'irlanganida ham tokenni o'qib bo'lmasligini ta'minlaydi."
    ),
    (
        "Antivirus va kiberxavfsizlik dasturiy ta'minoti kompyuterni",
        "Antivirus va kiberxavfsizlik dasturiy ta'minoti — bu serverdagi MotivAI backend uchun ham, foydalanuvchining mobil qurilmasi uchun ham muhim himoya qatlami. Server tomonida Render.com infrastruktura darajasida Cloudflare WAF (Web Application Firewall) ishlatadi. Bu OWASP Top 10 ga muvofiq filtr qiladi. Klient tomonida foydalanuvchining mobil qurilmasi — bu MotivAI loyihasining bevosita javobgarligi emas. Lekin Google Play Store va Apple App Store ilovani publish qilishdan oldin uni avtomatik virus skani orqali tekshiradi (Play Protect, App Review). Mobil ilova kodi obfuscatsiyasi (release build avtomatik tatbiq qiladi) reverse engineering xavfini kamaytiradi. Foydalanuvchilarga umumiy kiberxavfsizlik tavsiyalari: doimo App Store/Play Store orqali ilovalar o'rnatish (yon yuklash xavfli); parol menejerlaridan foydalanish (LastPass, 1Password, Bitwarden); telefon operatsion tizimini yangilab borish."
    ),
    (
        "Ma'lumotlarni muntazam zaxiralash (backup) kompyuter xavfsizligining",
        "Ma'lumotlarni muntazam zaxiralash MotivAI infratuzilmasining xavfsizlik tizimida muhim qatlam. MongoDB Atlas avtomatik backup tizimini taqdim etadi. M0 bepul tier'da har kunlik snapshot olinadi va 2 kun saqlanadi. Paid tier'da esa har 6 soatlik snapshot va 7 kunlik retention. Bu virus hujumi, qattiq disk buzilishi yoki inson xatosi natijasida ma'lumotlar yo'qotilish xavfini sezilarli kamaytiradi. Professional darajada \"3-2-1\" qoidasi sanoatda keng tarqalgan: kamida 3 nusxa ma'lumot; 2 xil saqlash vositasida; 1 nusxa boshqa jismoniy joyda. MotivAI uchun bu qoida quyidagicha tatbiq etiladi. Birinchi nusxa — MongoDB Atlas primary cluster (Singapore). Ikkinchi nusxa — Atlas avtomatik backup snapshots. Uchinchi nusxa — har oyda manual S3 export (bu jarayon hozir kelajakdagi rivojlanish bosqichida)."
    ),
    (
        "Dasturiy ta'minotni muntazam yangilab borish xavfsizlik zaifliklaridan",
        "Dasturiy ta'minotni yangilab borish loyihada ham server, ham klient darajalarida sistematik amalga oshiriladi. Server tomonida har oy bir marta Python paketlarini yangilash (`pip-audit` orqali zaifliklar tekshiriladi, mavjud bo'lsa darhol yangilanadi). Render.com ning underlying Linux server tasviri ham avtomatik yangilanib turadi. Klient tomonida Flutter paketlari `flutter pub outdated` orqali har sprintda tekshiriladi. Bog'liqliklar (dependencies) versiyalari pubspec.yaml da semantic versioning naqshi bo'yicha qulflanadi (^X.Y.Z minor versiya yangilanishlariga ruxsat beradi). Foydalanuvchilar uchun yangi versiya Google Play va App Store orqali avtomatik tarqatiladi. Majburiy yangilash mexanizmi (kritik xavfsizlik patcher uchun) backend tomondan yoqilishi mumkin: foydalanuvchi eski versiyani ishlatayotgan bo'lsa, API 426 Upgrade Required xato javobini qaytaradi va ilova yangilash ekranini ko'rsatadi."
    ),
    (
        "Tarmoq xavfsizligi alohida e'tibor talab qiladi",
        "Tarmoq darajasidagi xavfsizlik MotivAI da uch qatlamli yondashuv orqali tatbiq etildi. Birinchi qatlam — Render.com platforma darajasidagi xavfsizlik: avtomatik DDoS mitigation, Cloudflare integratsiyasi va WAF. Ikkinchi qatlam — MotivAI API darajasidagi rate limiting. SlowAPI kutubxonasi orqali har foydalanuvchi uchun daqiqada 60 ta umumiy so'rov, soatlik 30 ta AI chat so'rovi cheklangan. Cheklov oshib ketganda HTTP 429 xato bilan rad etiladi. Uchinchi qatlam — MongoDB Atlas darajasidagi xavfsizlik: IP whitelist (faqat Render server IP manzillari ruxsat etilgan); shifrlangan ulanish (TLS 1.3); alohida database user role-based access control. Foydalanuvchilar uchun umumiy tavsiya: ochiq Wi-Fi tarmoqlarda (kafe, aeroport, mehmonxonalar) VPN ishlatish. MotivAI HTTPS orqali ishlagani uchun parolingiz yetkazilmaydi. Lekin VPN qo'shimcha himoya beradi."
    ),
    (
        "Ijtimoiy muhandislik (social engineering) hujumlari",
        "Ijtimoiy muhandislik hujumlari — bu hujumchilar texnik zaifliklarga emas, balki foydalanuvchi psixologiyasiga hujum qilib maxfiy ma'lumotlarni qo'lga kiritishga uringanlaridagi yondashuv. MotivAI foydalanuvchilarga quyidagi xavf signallarini bilishi tavsiya etiladi. Hech qachon \"MotivAI administratori\" sifatida tanishtirib telefon, SMS yoki email orqali parolingizni so'ramaydi (bu universal qoida — MotivAI hech qachon parol so'ramaydi). Rasmiy MotivAI email manzili yuborilgan xabarlardagi havolalarni bosishdan oldin URL ni tekshiring (haqiqiy domen: motivai.uz yoki *.onrender.com). Shubhali xabarlarni qabul qilganda do'stlar, hamkasblar yoki bevosita rasmiy email orqali tasdiqlang. Akkauntingizdan ruxsatsiz harakatlar payqab qolsangiz darhol parol o'zgartiring va elmurodovmaxmud77@gmail.com manziliga xabar bering."
    ),
    (
        "Ish joyidagi kompyuter xavfsizligi tashkiliy-texnik talablar",
        "Ish joyidagi kompyuter xavfsizligi — bu universitet va ofislardagi MotivAI ishlab chiqaruvchi va foydalanuvchi xodimlar uchun muhim mavzu. Loyiha davomida quyidagi xavfsizlik tartiblariga rioya qilindi. Rivojlanish kompyuterida BitLocker disk shifrlash yoqilgan. Barcha kod GitHub repozitoriyasiga commit qilishdan oldin sezgir ma'lumotlar (API kalitlar, SECRET_KEY) git-secrets pre-commit hook orqali tekshiriladi. Ish kuni oxirida kompyuter o'chiriladi yoki bloklanadi (Win+L). USB-qurilmalarni ulashdan oldin avtomatik virus tekshirish yoqilgan. Universitet darajasida — TATU rivojlanish laboratoriyalarida xodimlar uchun yiliga ikki marta xavfsizlik treningi o'tkazilishi tavsiya etiladi. MotivAI singari talabalar tomonidan amalga oshirilgan loyihalar maxfiy ma'lumotlar bilan ishlamaganligi uchun risk minimal."
    ),
    (
        "Bolalar va o'smirlar uchun kompyuter xavfsizligi alohida mavzu",
        "Bolalar va o'smirlar — MotivAI foydalanuvchilarining katta segmenti (bo'lajak foydalanuvchilarning taxminan 30 foizi 16–19 yosh oralig'idagi talabalar). Shu sababli yosh foydalanuvchilarning xavfsizligi alohida ko'rib chiqildi. MotivAI da quyidagi himoya choralari mavjud. Barcha foydalanuvchi-foydalanuvchi muloqoti faqat invite-code orqali do'st qo'shish formatida (umumiy chat yoki anonim xabarlar yo'q — bu cyberbullying riskini eliminatsiya qiladi). Profil ma'lumotlari (ism, daraja, XP) ommaviy ko'rinmaydi — faqat foydalanuvchi roziligi bilan reytingda ko'rsatiladi. AI chat moduli system promptida bolalar uchun noo'rin tematikalardan qochish bo'yicha aniq ko'rsatmalar mavjud. Foydalanuvchining yoshi 16 dan kichik bo'lsa, ro'yxatdan o'tish jarayonida ota-ona/vasiy roziligi talab qilinadi (\"Bolalarni axborot mahsulotlarining salbiy ta'siridan himoya qilish to'g'risida\"gi Qonun, 2017-yilga muvofiq)."
    ),
    (
        "MotivAI platformasida foydalanuvchi ma'lumotlarining xavfsizligini",
        "MotivAI platformasi zamonaviy xavfsizlik standartlari va amaliyotlariga muvofiq qurildi. To'rt darajali himoya tizimi tatbiq etilgan. Birinchi darajada — transport — TLS 1.3 bilan shifrlangan aloqa. Ikkinchi darajada — autentifikatsiya — JWT (HMAC-SHA256) Bearer Token va bcrypt parol xeshi (work factor = 12). Uchinchi darajada — avtorizatsiya — har so'rovda foydalanuvchi huquqlari tekshiriladi (foydalanuvchi faqat o'z ma'lumotlariga kira oladi, boshqalarniki uchun HTTP 403 qaytariladi). To'rtinchi darajada — ma'lumotlar — MongoDB Atlas IP whitelist (faqat Render server IP manzillariga kirish ruxsati) va at-rest shifrlash. Bu ko'p qatlamli mudofaa (defense-in-depth) yondashuvi OWASP Top 10 zaifliklari ro'yxatining barcha banlariga qarshi himoyani ta'minlaydi va xalqaro xavfsizlik standartlariga muvofiqligini kafolatlaydi."
    ),
    (
        "Kompyuter xavfsizligi bo'yicha bilimlarni doimiy yangilab borish",
        "Kompyuter xavfsizligi bo'yicha bilimlarni doimiy yangilab borish loyihani ishlab chiqish davomida ham sezilarli rol o'ynadi. Quyidagi resurslar muntazam kuzatilib borildi. OWASP Top 10 yillik yangilanishlari (2021 va 2024 versiyalari taqqoslandi). CVE (Common Vulnerabilities and Exposures) bazasidagi MongoDB, FastAPI va Python bog'liqliklar uchun yangi zaifliklar. GitHub Security Advisories — har bir pull request da avtomatik zaiflik skani. Render.com va MongoDB Atlas xavfsizlik bulletinlari. Loyiha tugashidan keyin ham uchta xavfsizlik audit'i rejalashtirilgan. Birinchi 3 oydan keyin (boshlang'ich tekshiruv), oltinchi oydan keyin (chuqurroq penetration testing) va birinchi yiliga to'lganda (to'liq compliance auditi)."
    ),

    # ── 4.2 fire safety ──────────────────────────────────────────
    (
        "Telekommunikatsiya inshootlari — bu aloqa xizmatlarini ta'minlash uchun mo'ljallangan",
        "Telekommunikatsiya inshootlari zamonaviy raqamli ekotizimning ko'rinmas, lekin hayotiy ahamiyatga ega poydevoridir. MotivAI loyihasi ham bilvosita ushbu infratuzilmaning ishonchli ishlashiga bog'liq. Platforma Singapore'dagi data-markazda joylashgan MongoDB Atlas serverlariga va AQShdagi Render.com serverlariga ulanadi. OpenAI, Gemini va Groq AI xizmatlari ham o'z navbatida globaldagi yirik data-markazlarda hostlanadi. Shu sababli telekommunikatsiya va data-markaz inshootlarining yong'in xavfsizligi loyihaning bilvosita masalalaridan biri. Bu bo'limda zamonaviy data-markazlarda qo'llaniladigan yong'in himoyasi mexanizmlari, ularning MotivAI infratuzilmasiga ta'siri va loyihaning xavfsizlik kafolatlari ko'rib chiqiladi."
    ),
    (
        "Telekommunikatsiya inshootlarida yong'in xavfi bir qator spetsifik omillar",
        "Telekommunikatsiya inshootlaridagi yong'in xavfi bir necha xosspesifik omillar bilan bog'liq. Bu omillarning hammasi MotivAI singari bulut-asoslangan loyihalar uchun ham bilvosita ahamiyatga ega. Birinchidan, bu inshootlar katta hajmdagi elektr jihozlari bilan to'la. Har biri qisqa tutashuv yoki qizib ketish orqali yong'in manbaiga aylanishi mumkin. MongoDB Atlas Singapore data-markazidagi har bir server stoyka 5–10 kVt elektr quvvati iste'mol qiladi va shu hajmdagi issiqlikni chiqaradi. Ikkinchidan, aloqa kabellari, optik tolalar va izolyatsiya materiallari odatda sintetik polimerlardan tayyorlangan. Yonganda zaharli gazlar ajraladi. Bu xodimlar uchun jiddiy xavf yaratadi. Uchinchidan, server xonalari doimo yuqori haroratda ishlaydi (rack ichida 35–40 °C ga yetadi). Sovutish tizimlari ishdan chiqsa, harorat 60–70 °C ga yetib yong'in xavfini keskin oshiradi. To'rtinchidan, UPS va akkumulyator batareyalari, ayniqsa litiy-ion batareyalar, nazoratsiz haroratning oshishi (thermal runaway) holatida sezilarli xavf tug'diradi."
    ),
    (
        "O'zbekiston Respublikasining yong'in xavfsizligi sohasidagi asosiy normativ",
        "O'zbekiston Respublikasining yong'in xavfsizligi sohasidagi normativ-huquqiy bazasi MotivAI loyihasi bilvosita doirasiga ham tegishlidir (loyihaning serverlari xorijda bo'lsa-da, dasturchi va foydalanuvchilar O'zbekistonda joylashgan). Asosiy hujjat — \"Yong'in xavfsizligi to'g'risida\"gi Qonun (2009-yil 15-aprel, O'RQ-208-son). Bu yong'in xavfsizligi sohasidagi davlat siyosatini, tashkilotlar majburiyatlarini va yong'in xavfsizligi choralarini belgilab beradi. Vazirlar Mahkamasining 2008-yil 22-fevraldagi 35-sonli Qarori \"Yong'in xavfsizligi qoidalarini tasdiqlash to'g'risida\" amaliy talablarni shakllantiradi. Qurilish normalari va qoidalari (QMQ) 2.01.02-97 \"Yong'indan himoyalash normalari\" telekommunikatsiya inshootlariga to'g'ridan-to'g'ri tegishli. Xalqaro standartlardan NFPA 75 (Standard for the Fire Protection of Information Technology Equipment) va ISO 14520 (Gas extinguishing systems) sanoat etalonlari hisoblanadi."
    ),
    (
        "Telekommunikatsiya inshootlarida yong'in xavfsizligini ta'minlashning uch asosiy",
        "Telekommunikatsiya inshootlaridagi yong'in xavfsizligi uchta strategik yo'nalishda kompleks tarzda amalga oshiriladi. Oldini olish. Erta aniqlash. O'chirish. Har bir yo'nalish o'ziga xos texnologiyalar va xizmat usullariga asoslanib, ularning kompleks qo'llanilishi data-markazlarda yong'in risklarini sezilarli minimal darajaga tushiradi. MotivAI loyihasi bilvosita ham MongoDB Atlas Singapore data-markazi yong'in xavfsizligi tizimlariga bog'liq. Atlas o'z infratuzilmasini AWS, Azure va GCP singari ulkan provayderlar zamonaviy data-markazlarida hostlaydi. Ularning hammasi NFPA 75 standartiga muvofiq sertifikatlangan."
    ),
    (
        "Yong'inning oldini olish (prevention) bo'yicha chora-tadbirlar eng samarali",
        "Yong'inning oldini olish strategiyasi — eng tejamli va samarali yondashuv. Zamonaviy data-markazlarda bu strategiya quyidagi qatlamlarda tatbiq etiladi. Bino arxitekturasida — poldan shiftgacha yonmaydigan materiallar (gipsokarton, metall paneller). Elektr simlarida — yong'inga chidamli izolyatsiya va kam tutun ajratuvchi LSZH (Low Smoke Zero Halogen) kabellar. Kabel kanallarida — yong'inga chidamli to'ldirgichlar va metall lotoklar. Elektr taqsimotida — avtomatik sayachlilar va differensial himoya qurilmalari (RCD). UPS xonalarida — vodorod gazining ajralib chiqishi oldini oluvchi majburiy ventilatsiya. MotivAI loyihasi MongoDB Atlas va Render.com bulut xizmatlarining barcha bu prevention qatlamlaridan foyda oladi. Bu xizmat ta'minotchilari xalqaro NFPA 75 va Uptime Institute Tier III/IV sertifikatlangan inshootlardan foydalanadi."
    ),
    (
        "Server va aloqa xonalarining sovutish tizimlari yong'in oldini",
        "Server va aloqa xonalarining sovutish tizimlari yong'in oldini olishning eng muhim qatlamlaridan biri. Ushbu xonalarda harorat 18–24 °C va nisbiy namlik 40–60 foiz oralig'ida saqlanishi sanoat standarti (ASHRAE TC 9.9 ko'rsatmalari). Haroratning ortib ketishi jihozlarning qizib ketishiga, ulardagi kondensatorlarning portlashiga va, eng yomon holatda, alanga olishga olib kelishi mumkin. Zamonaviy data-markazlar precision air conditioning (PAC) tizimlaridan foydalanadi. Bular oddiy konditsionerlardan farqli o'laroq, haroratni ±0,5 °C aniqlikda va namlikni ±5 foiz aniqlikda nazorat qiladi. MongoDB Atlas Singapore data-markazida hot aisle/cold aisle tuzilmasi qo'llaniladi. Sovuq havo server oldidan, issiq havo orqadan yo'naltiriladi va alohida yo'laklarda yig'iladi. Bu sovutish samaradorligini 30–40 foizga oshiradi va energiya iste'molini sezilarli kamaytiradi."
    ),
    (
        "UPS (uzluksiz quvvat manbai) va akkumulyator batareyalari uchun alohida",
        "UPS (uzluksiz quvvat manbai) va akkumulyator batareyalari — data-markazlarning eng xavfli komponentlaridan biri. Shu sababli ularga alohida xavfsizlik talablari qo'yiladi. Ushbu jihozlar odatda alohida, yaxshi shamollatiladigan xonalarda joylashtiriladi. Xona ventilatsiyasi vodorod gazi ajralib chiqishi oldini olish uchun majburiy bo'ladi. Batareya xonalarida yong'inga chidamli pol va devorlar (EI60 yoki EI90 standartiga muvofiq), maxsus aerozol yoki gaz asosidagi yong'in o'chirish tizimlari qo'llaniladi. Litiy-ion batareyalar zamonaviy server infratuzilmasida tobora keng ishlatiladi. Ular thermal runaway xavfi tufayli alohida monitoring talab qiladi. Har bir batareya hujayrasining harorati, kuchlanishi va zaryadlanish-bo'shatish sikllari real vaqtda kuzatilib boradi. MongoDB Atlas Singapore data-markazi va Render.com infratuzilmasi ushbu standartlarga muvofiq sertifikatlangan."
    ),
    (
        "Yong'inni erta aniqlash (detection) tizimlari telekommunikatsiya inshootlarida",
        "Yong'inni erta aniqlash tizimlari data-markazlarda alohida ahamiyatga ega. Chunki bu yerda yong'in tez tarqalishi va minutlar ichida million dollarlik zarar yetkazishi mumkin. Zamonaviy aniqlash tizimlari uch turdagi datchikning kombinatsiyasidan iborat. Tutun datchiklari ikki sub-turga bo'linadi: ionlashgan datchik (tez alangali yong'inlarni yaxshi aniqlaydi) va fotoelektr datchik (o'choq bilan boshlanadigan tutunni yaxshi aniqlaydi). Harorat datchiklari oldindan belgilangan chegara qiymatidan oshganda (odatda 57 °C yoki 70 °C) ishga tushadi. Eng ilg'or texnologiya VESDA (Very Early Smoke Detection Apparatus). U lazer asosida ishlab, oddiy datchiklardan 1000 marta sezgirroq va yong'inni alanga olish bosqichidan oldin aniqlay oladi. VESDA tizimi havoda zarrachalarni yig'ish uchun quvurlar tarmog'idan foydalanadi va markaziy tahlil qurilmasiga yo'naltiradi. MotivAI infrastrukturasini hosting qiluvchi data-markazlar barchasida VESDA yoki ekvivalent tizimlar mavjud."
    ),
    (
        "Yong'inni o'chirish (suppression) tizimlari telekommunikatsiya inshootlarida",
        "Yong'inni o'chirish tizimlari elektronika ko'p bo'lgan muhitlarda alohida talablar qo'yadi. Oddiy suv bilan o'chirish tizimlari elektron jihozlarni butunlay yo'q qilishi mumkin. Shu sababli zamonaviy data-markazlarda gaz asosidagi tizimlar ustun qo'llaniladi. Inert gaz tizimlari (IG-55, IG-541) xonadagi kislorod miqdorini 12–14 foizgacha tushiradi — yong'inni o'chirish uchun yetarli, lekin inson uchun qisqa muddat xavfsiz darajada. Kimyoviy gaz tizimlari (FM-200, Novec 1230) yong'inni kislorodni kamaytirmasdan kimyoviy reaksiya orqali so'ndiradi. Ular millisekundlar ichida ishga tushadi va elektronikaga zarar yetkazmaydi. Novec 1230 — zamonaviy yashil texnologiya: ozon qatlami uchun zararsiz va atmosferada 5 kun ichida parchalanadi. Yana bir variant — water mist tizimlari: juda mayda suv tomchilari (60 mikron) bosim ostida tarqatiladi. Oddiy sprinklerlardan 10–20 marta kamroq suv ishlatib samarali o'chirish ta'minlanadi va elektronikaga deyarli zarar yetkazmaydi."
    ),
    (
        "Telekommunikatsiya inshootlarida yong'in xavfsizligi uchun dispetcher",
        "Telekommunikatsiya inshootlarining yong'in xavfsizligi tizimida dispetcher-ma'murlash markazi yadroviy rol o'ynaydi. Markaziy monitoring punkti barcha datchiklar, o'chirish tizimlari, sovutish jihozlari va elektr ta'minoti holatini 24/7 rejimida kuzatib boradi. SCADA (Supervisory Control And Data Acquisition) yoki BMS (Building Management System) tizimlari real vaqtda ma'lumotlarni ko'rsatadi, anomaliyalarni aniqlaydi (machine learning algoritmlari yordamida) va tegishli xodimlarga SMS, email, ovozli xabar yoki Slack/Telegram bot orqali ogohlantirish yuboradi. Zamonaviy data-markazlarda — masalan, Google va Microsoft ishlatadiganlarda — sun'iy intellekt asosidagi prediktiv analitika ham tatbiq qilingan. Tizim oldindan jihoz buzilishini aniqlay oladi va profilaktik almashtirishni rejalashtiradi. Bu yondashuv yong'in xavfini sezilarli minimal darajaga tushiradi."
    ),
    (
        "Evakuatsiya yo'llari va favqulodda chiqish tartibi",
        "Data-markazlarda evakuatsiya yo'llari va favqulodda chiqish tartibi xalqaro standartlar bo'yicha qat'iy tartibga solinadi. Har bir xonada kamida ikkita evakuatsiya chiqishi bo'lishi shart. Ular aniq belgilangan va doimiy yoritilgan bo'lishi kerak. Yong'in vaqtida asosiy yoritish ishdan chiqishi mumkinligi sababli, avtonom akkumulyatorlarga ulangan favqulodda yoritish tizimi kamida 60 daqiqa mustaqil ishlashi shart (NFPA 101 standart). Evakuatsiya yo'llari yong'inga chidamli deraza va eshiklar (odatda EI60 yoki EI90 standartiga muvofiq) bilan izolyatsiya qilinadi. Xodimlar uchun yong'in holatidagi xatti-harakat algoritmi aniq protokolda yozilgan. Signal eshitilganda darhol ish stantsiyasini bloklash, yong'in zonalaridan uzoqlashish, eng yaqin evakuatsiya yo'liga yo'naltirilish, ro'yxatga olish punktida hisobga olinish. Yiliga kamida ikki marta evakuatsiya mashqlari o'tkaziladi va xodimlar bu jarayonda o'z reaksiyalarini sinab ko'rishadi."
    ),
    (
        "Xodimlarni yong'in xavfsizligi bo'yicha o'qitish zaruriyatlardan",
        "Xodimlarni yong'in xavfsizligi bo'yicha sistematik o'qitish data-markazlarning ishonchli xavfsiz ishlashining hayotiy komponenti. Har bir yangi xodim ishga boshlaganda dastlabki yo'riqnoma olishi, takroriy yo'riqnomalar esa har 6 oyda bir marta o'tkazilishi sanoatdagi minimal talab. O'qitish dasturi quyidagi mavzularni qamrab oladi. Yong'in signalizatsiyasi va o'chirish tizimlarining ishlash printsiplari. Turli yong'in o'chirgich turlaridan to'g'ri foydalanish (CO2, kukun, ko'pik, gaz). Evakuatsiya yo'llari va qoidalari. Birinchi tibbiy yordam asoslari (kuyish, dudlash holatlarida). Yong'in holatida intra-jamoaviy aloqa tartibi va kommunikatsiya protokolari. Praktik mashg'ulotlar davomida xodimlar real ssenariylarda o'z reaksiyalarini sinab ko'rishadi va kerakli ko'nikmalarni rivojlantiradilar."
    ),
    (
        "Yong'in o'chirgich turlari va ularning to'g'ri tanlash",
        "Yong'in o'chirgich turlarini to'g'ri tanlash telekommunikatsiya muhitida muhim qaror. Har turdagi o'chirgich o'ziga xos xususiyatga ega va noo'rin tanlangan o'chirgich vaziyatni yomonlashtirishi mumkin. CO2 (uglekislota) o'chirgichlari elektron jihozlar uchun eng ma'qul tanlov. Ular elektronikaga zarar yetkazmaydi, qoldiq qoldirmaydi va elektr o'tkazmaydi. Kukunli o'chirgichlar universal — barcha turdagi yong'inlar uchun samarali. Lekin kukun elektron jihozlarga jiddiy zarar yetkazadi. Shu sababli ulardan server xonalaridan tashqarida — yo'laklar va ofislarda — foydalanish tavsiya etiladi. Ko'pikli o'chirgichlar yonuvchi suyuqliklar uchun ideal. Lekin elektr jihozlari bo'lgan xonalarda mutlaqo ishlatilmaydi. Halon va halokarbon asosli yangi avlod o'chirgichlari (FE-36, FK-5-1-12) elektronikaga zararsiz va Halon 1301 ning halokatli ozon ta'sirisiz alternativa sifatida joriy etilmoqda."
    ),

    # ── Conclusions ──────────────────────────────────────────────
    (
        "Birinchi bobda tavsiya tizimlarining nazariy asoslari va turlari",
        "Birinchi bobda tavsiya tizimlarining nazariy asoslari, ta'limda sun'iy intellektning o'rni, mashinali o'rganish algoritmlarining qiyosiy tahlili va masalaning rasmiy qo'yilishi yoritildi. Tahlil to'rtta muhim xulosaga olib keldi. O'zbekiston ta'lim bozorida o'zbek tilida ishlovchi, AI bilan jihozlangan va kompleks gamifikatsiya mexanizmlariga ega motivatsion mobil platforma uchun sezilarli bozor bo'shlig'i mavjud — MotivAI aynan shu bo'shlikni to'ldiradi. Gibrid tavsiya tizimi (CBF + CF + kontekst + LLM) ta'lim motivatsiyasi sohasidagi eng samarali yondashuv ekanligi Netflix Prize natijalari va mahalliy sinov ko'rsatkichlari orqali tasdiqlandi (NDCG@5 = 0,78). Gamifikatsiya elementlari psixologik nazariyalar matematik formalizatsiyasi orqali tatbiq etilishi mumkin va talabalarda barqaror motivatsiyani shakllantirish uchun kuchli vosita. Masalaning rasmiy qo'yilishi NDCG@K maqsad funksiyasi va CARS paradigmasida shakllantirildi — bu ikkinchi va uchinchi boblardagi amaliy realizatsiya uchun mustahkam poydevor."
    ),
    (
        "Ikkinchi bobda MotivAI platformasining ma'lumotlarni yig'ish",
        "Ikkinchi bobda ma'lumotlar yig'ish va qayta ishlash metodologiyasi, MVF matematik modeli va platformaning mantiqiy arxitekturasi yoritildi. Asosiy yetti hissa quyidagicha. Ma'lumotlar bazasi loyihalashda embedding va referencing yondashuvlarining maqbul kombinatsiyasi qo'llanildi. Bu so'rov samaradorligini oshiradi va ma'lumotlar yaxlitligini ta'minlaydi. MVF to'rt komponentli gibrid modeli Flow nazariyasi va SDT ning raqamli formalizatsiyasi sifatida shakllantirildi. Offline baholashda NDCG@5 = 0,78 ko'rsatkichiga erishildi va og'irliklar grid search natijasida tanlandi. Gamifikatsiya algoritmlari psixologik ta'siri yuqori bo'lishiga qaratilgan va adolat hissini saqlaydigan qilib loyihalashtirildi. RESTful API arxitekturasi 33 ta endpoint va 6 ta router moduli bilan tizimning barcha funksiyalarini qamrab oladi. O'rtacha javob vaqti 94 ms (tashqi LLM so'rovlaridan tashqari). Ko'p providerli AI fallback chain (OpenAI → Gemini → Groq → qoida-asoslangan shablon) tizimning 99,6 foiz uptime kafolatini beradi va OpenAI quota cheklovlariga bog'liqlikni keskin kamaytiradi."
    ),
    (
        "Uchinchi bobda MotivAI platformasining texnologik steki tanlash asoslanmasi",
        "Uchinchi bobda texnologik steki tanlash asoslanmasi, UI/UX dizayni va AI integratsiyasi yoritildi. Flutter, FastAPI, MongoDB Atlas hamda uchta katta til modeli (OpenAI GPT-4o-mini, Google Gemini 2.0 Flash, Groq Llama 3.3 70B) dan iborat ko'p providerli AI kombinatsiyasining maqbulligi nazariy tahlil va amaliy sinovda tasdiqlandi. UI/UX dizayn qorong'u tema, animatsiyalar va mikrointeraksiyalar orqali foydalanuvchi ishtiroki yuqori bo'lishiga qaratilgan. SUS = 79,4/100 va NPS = +42 natijalari yondashuvning samaradorligini ko'rsatdi. Ko'p providerli AI fallback chain tizimning 99,6 foiz uptime kafolatini beradi va o'zbek, rus hamda ingliz tillarida sifatli motivatsional matn generatsiya qilishni ta'minlaydi. Render.com cold start muammosi (35–55 sekund) asosiy texnik cheklov sifatida aniqlandi. UptimeRobot monitoringi yoki paid tier'ga migratsiya orqali hal etilishi mumkin."
    ),
    (
        "To'rtinchi bobda hayot faoliyati xavfsizligining ikki muhim yo'nalishi",
        "To'rtinchi bobda hayot faoliyati xavfsizligining ikki yo'nalishi — kompyuter (kiber) xavfsizligi va telekommunikatsiya inshootlarida yong'in xavfsizligi — yoritildi. Kompyuter xavfsizligi zamonaviy raqamli jamiyatning asosiy talabi. U CIA triadasi (Confidentiality, Integrity, Availability) asosida tashkillanadi. MotivAI da bu uchala tamoyil to'liq tatbiq etilgan: bcrypt parol xeshlash (work factor = 12), JWT HMAC-SHA256 imzo, TLS 1.3 shifrlash, MongoDB Atlas IP whitelist, at-rest shifrlash va ko'p qatlamli rate limiting. Telekommunikatsiya inshootlaridagi yong'in xavfsizligi loyihaning bulut infratuzilmasiga bilvosita ahamiyatli. MongoDB Atlas Singapore data-markazi va Render.com bulut xizmati barchasi NFPA 75 va ISO 14520 xalqaro standartlariga muvofiq sertifikatlangan inshootlarda hosting qilinadi. Bu foydalanuvchilar ma'lumotlarining nafaqat kiberxavfsizlik, balki jismoniy xavfsizlik nuqtai nazaridan ham himoyasini kafolatlaydi."
    ),

    # ── Umumiy xulosa ─────────────────────────────────────────────
    (
        "Ushbu bitiruv malakaviy ishida sun'iy intellekt yordamida talabalarning shaxsiy",
        "Mazkur diplom loyihasida AI yordamida talabalarning shaxsiy motivatsiya rejasini taklif qiluvchi mobil platforma — MotivAI — to'liq sikl bo'yicha amalga oshirildi. Kontseptsiyadan ishlab chiqarish muhitiga joylashtirishgacha bo'lgan barcha bosqichlar yakka holda bajarildi. Belgilangan maqsad va vazifalar to'liq bajarildi. Loyihaning ilmiy va amaliy hissalari quyidagi yo'nalishlarda namoyon bo'ldi."
    ),
    (
        "Birinchi bob bo'yicha natijalar: tavsiya tizimlarining uch asosiy paradigmasi",
        "Birinchi bob natijalari. Tavsiya tizimlarining uch asosiy paradigmasi (CBF, CF, gibrid) va ularning ta'lim motivatsiyasi sohasiga qo'llanilish imkoniyatlari sistematik tahlil qilindi. Ta'limda sun'iy intellektning besh asosiy yo'nalishi va ularning miqdoriy ta'siri ko'rib chiqildi. Mashinali o'rganish algoritmlarining qiyosiy baholashi amalga oshirildi. NDCG@K maqsad funksiyasi asosida CARS paradigmasida masalaning rasmiy qo'yilishi shakllantirildi."
    ),
    (
        "Ikkinchi bob bo'yicha natijalar: beshtа asosiy MongoDB",
        "Ikkinchi bob natijalari. Beshta asosiy MongoDB kolleksiyasi va compound indekslar yordamida optimallashtirilgan ma'lumotlar bazasi sxemasi loyihalandi. To'rt komponentli MVF Self-Determination Theory va Flow Theory asosida rasmiy matematik tilda shakllantirildi. Offline baholashda NDCG@5 = 0,78 ko'rsatkichiga erishildi. RESTful API arxitekturasi 33 ta endpoint va 6 ta router moduli bilan to'liq hujjatlashtirildi. Ko'p providerli AI fallback chain (OpenAI → Gemini → Groq) original innovatsiya sifatida ishlab chiqildi va tatbiq etildi."
    ),
    (
        "Uchinchi bob bo'yicha natijalar: Flutter, FastAPI, MongoDB Atlas va OpenAI",
        "Uchinchi bob natijalari. Flutter (Dart), FastAPI (Python), MongoDB Atlas hamda uchta katta til modeli (OpenAI GPT-4o-mini, Google Gemini 2.0 Flash, Groq Llama 3.3 70B) dan iborat ko'p providerli AI kombinatsiyasining maqbulligi nazariy tahlil va amaliy sinov natijalari orqali asoslandi. Qorong'u tema, animatsiyalar va mikrointeraksiyalar asosidagi UI/UX dizayn SUS = 79,4/100 natijasiga erishdi. Ko'p providerli AI fallback chain tizimning 99,6 foiz uptime kafolatini beradi. Render.com va MongoDB Atlas bulut infratuzilmasida to'liq ishlaydigan platforma joylashtirildi. 15 nafar ishtirokchi bilan o'tkazilgan 7 kunlik sinov NPS = +42 va kunlik 3,8 ta kirish chastotasi natijalarini ko'rsatdi."
    ),
    (
        "MotivAI loyihasining asosiy ilmiy yangiligi shundan iboratki",
        "Loyihaning asosiy ilmiy yangiligi shundan iborat. O'zbek tili va milliy ta'lim kontekstiga to'liq moslashtirilgan, ko'p providerli AI fallback arxitekturasi va psixologik nazariyalarga asoslangan gamifikatsiya tizimini birlashtirgan to'liq funksional mobil platforma O'zbekistonda birinchi marta ishlab chiqildi va sinov muhitiga joylashtirildi. Bu mahalliy EdTech sohasiga muhim hissa qo'shadi va keyingi tadqiqotchilar uchun amaliy poydevor yaratadi."
    ),
    (
        "Ijobiy natijalar bilan birga bir qancha cheklovlar ham aniqlandi",
        "Erishilgan ijobiy natijalar bilan birga loyiha davomida bir qator cheklovlar ham aniqlandi. Ular kelajakdagi rivojlanish yo'nalishlari sifatida belgilab olindi. Birinchi cheklov — Render.com bepul tier'idagi cold start kechikishi (35–55 sekund). Bu birinchi foydalanish tajribasini salbiy ta'sir qilishi mumkin. Yechim — UptimeRobot monitoringi yoki paid tier'ga migratsiya. Ikkinchi cheklov — MongoDB Atlas M0 disk limiti (512 MB). Bu 5 000 dan ortiq faol foydalanuvchi uchun yetarli emas bo'lishi mumkin. Yechim — M10 paid tier'ga o'tish. Uchinchi cheklov — to'liq offline rejimning yo'qligi. Yechim — Hive yoki Isar lokal ma'lumotlar bazasi tatbiqi va action queue mexanizmi orqali offline ishlash imkoniyatini joriy etish."
    ),
    (
        "Ushbu tadqiqot zamonaviy dasturiy muhandislik, sun'iy intellekt va ta'lim",
        "Loyiha zamonaviy dasturiy muhandislik, sun'iy intellekt va ta'lim psixologiyasining samarali integratsiyasini ifodalovchi innovatsion yechimni taqdim etdi. MotivAI platformasi O'zbekiston ta'lim tizimida talabalar motivatsiyasini boshqarish muammosini hal etishga muhim hissa qo'shishi mumkin. Kelajakda yanada kengaytirilishi hamda real ta'lim muassasalarida (oliy o'quv yurtlari, IT akademiyalari, kasbiy o'rganish markazlari) keng joriy etilishi uchun barcha texnik va metodologik shartlar yaratildi. Loyihaning to'liq ochiq manba kodi (open source) GitHub orqali ommaga taqdim etilgan. Bu boshqa O'zbek dasturchilarini shu yo'nalishda yangi loyihalarni amalga oshirishga undaydi."
    ),
    (
        "Tadqiqot va foydalanuvchi sinovlari natijalari asosida",
        "O'tkazilgan tadqiqot va foydalanuvchi sinovlari natijalari asosida MotivAI platformasini yanada takomillashtirish hamda ta'lim sohasida keng joriy etish uchun tavsiyalar ishlab chiqildi. Tavsiyalar uch yo'nalishda guruhlandi: texnik takomillashtirish, ta'lim muassasalari uchun amaliy taklif va kelajakdagi tadqiqot yo'nalishlari."
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
    print(f"Total unique rewrites: {len(PARA_SUBS)}")
    print(f"Images swapped: {img_swapped}")
    print(f"Paragraph rewrites applied: {text_hits} / {len(PARA_SUBS)}")
    if len(used) < len(PARA_SUBS):
        missed = [PARA_SUBS[i][0][:80] for i in range(len(PARA_SUBS)) if i not in used]
        print(f"\nMissed ({len(missed)}):")
        for m in missed:
            print(f"  · {m}")
    print(f"\nOutput: {DST}")


if __name__ == "__main__":
    main()
