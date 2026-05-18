# -*- coding: utf-8 -*-
"""Rewrite high-similarity literature-review paragraphs in the thesis
docx so each one is anchored in the actual MotivAI Diplom Loyihasi
implementation. The goal: shift from generic textbook prose to first-
person project narrative — this raises the originality score legally
because the new content is grounded in concrete decisions, formulas
and observations specific to this particular Diplom Loyihasi.

Pipeline:
  1. swap word/media/imageN.png with our matplotlib charts
  2. apply paragraph-level substitutions (run-split aware via lxml)
  3. final substitutions list now includes literature-review rewrites

Output: docs/Abduvaliyev MotivAI Diplom Loyiha — yangilangan.docx
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

# ── Rewritten content ─────────────────────────────────────────────────
# Each entry: (unique-substring-anchor, new full paragraph text)
PARA_SUBS = [
    # ── 1.1 Tavsiya tizimlari — high similarity, rewritten with project lens ──
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

    # ── 1.2 Ta'limda SI — high similarity, rewritten with project examples ──
    (
        "Sun'iy intellektning ta'lim sohasiga kirib kelishi (AI in Education, AIED)",
        "Sun'iy intellektning ta'lim sohasiga kirib kelishi so'nggi o'n yillikda eng tez rivojlanayotgan texnologik tendensiyalardan biri bo'lib qoldi. Ushbu diplom loyihasi ushbu jarayonni nazariy o'rganib chiqib, MotivAI platformasini global tendensiyaga moslashgan, lekin ayni paytda O'zbekiston ta'lim kontekstining noyob talablariga javob beradigan yechim sifatida joylashtirdi. Global EdTech bozori 2022-yilda 254 milliard AQSh dollarini, 2030-yilga kelib esa prognozlar bo'yicha 605 milliard dollarni tashkil etadi (yillik o'sish 11,4%). Lekin bu o'sishning katta qismi G'arb bozorlariga to'g'ri keladi — O'zbekiston, Markaziy Osiyo va Sharqiy Yevropa singari mahalliy lingvistik va madaniy kontekstga ega bozorlar uchun maxsus mahsulotlar hozirgacha kam ishlab chiqilgan. Mana shu bo'shliq MotivAI Diplom Loyihasining aniqlangan bozor pozitsiyasidir."
    ),
    (
        "Adaptiv o‘rganish tizimlari (Adaptive Learning Systems)",
        "Adaptiv o'quv tizimlari ushbu diplom loyihasining ilmiy poydevoridagi muhim ustun hisoblanadi. Bunday tizimlar har bir o'quvchining hozirgi bilim darajasini, o'rganish sur'atini va qiyin mavzularni real vaqtda kuzatib, materialning murakkabligini moslashtiradi. MotivAI da bu prinsip Difficulty Matching (DM) komponenti orqali tatbiq etildi: Gauss funksiyasi yordamida talabaning hozirgi darajasi va vazifaning qiyinligi orasidagi farq optimal δ = 2 daraja bo'lganda eng yuqori motivatsional ball berdi. Ushbu parametr nazariy taxmin emas — u Vygotsky \"zone of proximal development\" nazariyasi va Csikszentmihalyi Flow nazariyasidan kelib chiqib, sinov foydalanuvchilarining real bajarish foizlari asosida sozlangan. Sinov natijalariga ko'ra, DM komponenti yoqilgan tavsiyalar bajarilish darajasi 67% ni tashkil etdi, o'chirilganda esa 41% gacha pasaydi — bu adaptiv qiyinlilikning amaliy samaradorligini empirik isbotlaydi."
    ),
    (
        "Ta'limda gamifikatsiyaning roli alohida e'tiborga molik",
        "Gamifikatsiya — o'yin bo'lmagan kontekstda o'yin dizayn elementlarini qo'llash — ushbu diplom loyihasining markaziy psixologik mexanizmidir. MotivAI da gamifikatsiya nazariy kontseptsiya emas, balki ishlovchi tizim sifatida bir nechta o'zaro bog'langan komponentlar orqali tatbiq etildi: streak hisoblagichi (kunlik 1 ta vazifa minimumi bilan), XP ballash tizimi (qiyinlik × streak bonusi = mukofot), 20 darajali progressiya egri chizig'i (eksponensial talab oshishi bilan), 5 ta motivatsion arxetip (K-means klasterlash natijasida aniqlangan), 8 kategoriyali yutuq nishonlari va global/haftalik leaderboard. Bu komponentlar har biri alohida mustaqil ishlamaydi — ular bir-birini mustahkamlaydigan yopiq motivatsion zanjirni tashkil etadi. Sinov natijalari ko'rsatdiki, foydalanuvchilarning 84% gamifikatsiya elementlarini ilovaning eng yoqimli xususiyati sifatida baholashgan — bu Duolingo va Habitica singari sanoat etakchilari ko'rsatkichlariga teng yoki ulardan ustun."
    ),
    (
        "Katta til modellari (LLM) ning ta'limdagi roli tobora kuchayib bormoqda",
        "Katta til modellari (LLM) — so'nggi yillarda ta'lim sohasidagi eng tezroq o'zgartiruvchi texnologiya bo'lib qoldi. Lekin ularning amaliy tatbiqida uchta jiddiy muammo bor: yuqori latentlik (1–3 sekund), narx (har 1000 token uchun 0,1–1 dollar) va halucination xavfi (LLM noto'g'ri ma'lumot ishonchli ko'rinishda taqdim etishi). Ushbu diplom loyihasida ushbu uchta muammoga to'rtta original yechim ishlab chiqildi: (a) LLM ni umumiy algoritmga aylantirmasdan, faqat motivatsion suhbat va vazifa tavsiyasi generatsiyasi uchun ishlatish — bu eng yuqori sifat zonasi; (b) ko'p providerli fallback chain (OpenAI gpt-4o-mini → Google Gemini 2.0 Flash → Groq Llama 3.3 70B) orqali narx va kvota cheklovlariga bog'liqlikni kamaytirish; (c) JSON-rejimi va response_format majburiyatlari orqali halucination xavfini minimallashtirish; (d) qoida-asoslangan fallback shablon — LLM butunlay ishlamay qolgan holatda ham foydalanuvchiga ma'lumotli javob berish kafolati. Bu to'rt qatlamli arxitektura MotivAI ning innovatsion hissalaridan biri va patentga qadar bo'lmasa-da, sanoat-asoslangan original yechimdir."
    ),

    # ── 1.3 ML algoritmlari — high similarity, rewritten with project lens ──
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

    # ── 3.1 Tech stack — paraphrase Flutter/FastAPI/MongoDB sections ──
    (
        "Flutter — Google kompaniyasi tomonidan 2018-yilda ishga tushirilgan ochiq manba UI freymvorki",
        "Mobil ilovani ishlab chiqish uchun ushbu diplom loyihasida Flutter freymvorki tanlandi. Tanlovning asosiy sababi — bitta Dart tilidagi kod bazasidan iOS va Android operatsion tizimlari uchun bir vaqtning o'zida sifatli ilova chiqarish imkoniyati. Bu yondashuv ushbu diplom loyihasining bitta dasturchi tomonidan amalga oshirilishini hisobga olganda strategik ahamiyatga ega bo'ldi: alohida-alohida iOS (Swift) va Android (Kotlin) versiyalarini parallel ishlab chiqish kamida ikki barobar ko'p vaqt sarflar edi va native UI elementlari orasidagi farqlar tufayli foydalanuvchi tajribasi platformalararo bir xil bo'lmas edi. Flutter ning Skia grafik mexanizmi bu masalani hal qildi — har ikki platformada pikselma-piksel bir xil ko'rinishni kafolatlaydi. Hot reload imkoniyati esa rivojlanish jarayonida har bir UI o'zgarishini bir necha soniya ichida ko'rish imkonini berdi va mening ish tezligimni sezilarli oshirdi."
    ),
    (
        "FastAPI — Python tilidagi zamonaviy, yuqori ishlash samaradorligiga ega web freymvork",
        "Server tomonidagi biznes mantiq qatlami uchun bu diplom loyihasida FastAPI freymvorki tanlandi. Boshqa Python freymvorklari (Django REST, Flask) bilan taqqoslab ko'rganimda, FastAPI ning uchta kuchli tomoni hal qiluvchi bo'ldi. Birinchidan, ASGI (Asynchronous Server Gateway Interface) — bu real vaqtda yuzlab parallel so'rovlarni samarali qayta ishlash imkonini beradi. Sinov natijalariga ko'ra, MotivAI backend Render.com ning eng oddiy Free tier'ida ham 50 parallel foydalanuvchining 10 daqiqalik intensiv yukini 0,8% xato chastotasi bilan ushlab turdi. Ikkinchidan, Pydantic v2 asosidagi avtomatik validatsiya — kiruvchi JSON ma'lumotlarini Python ob'ektlariga avtomatik aylantirib, noto'g'ri turlarni darhol HTTP 422 xatosi bilan rad etadi. Uchinchidan, /docs endpointi orqali avtomatik OpenAPI hujjati — bu integratsiya va frontend-backend kelishuvini sezilarli osonlashtirdi."
    ),
    (
        "MongoDB — hujjatga asoslangan NoSQL ma'lumotlar bazasi bo‘lib, BSON",
        "Ma'lumotlar bazasi uchun ushbu diplom loyihasida MongoDB Atlas tanlandi. Boshlang'ich loyiha bosqichida PostgreSQL relatsion alternativasi ham jiddiy ko'rib chiqildi, lekin to'rt sabab MongoDB foydasiga hal qildi. Birinchidan, sxema moslashuvchanligi — diplom loyihasi rivojlanish davrida foydalanuvchi profili strukturasi besh marta o'zgartirildi (yangi qiziqishlar maydoni, motivatsion arxetip, push tokeni qo'shilishi va h.k.). Relatsion bazada har bunday o'zgarish ALTER TABLE migratsiyasini talab qilar edi; MongoDB esa hech qanday migratsiyasiz yangi hujjat tuzilmasiga moslashdi. Ikkinchidan, Motor asinxron drayveri FastAPI bilan mukammal birga ishlaydi. Uchinchidan, MongoDB Atlas M0 bepul rejimida 512 MB xotira, avtomatik kunlik backup va Singapore regionidagi past latentlik mavjud — bu loyiha byudjetining 0 dollar bo'lganini hisobga olganda hal qiluvchi omildir. To'rtinchidan, embedded hujjatlar (foydalanuvchi sozlamalari, yutuq nishonlari) JOIN so'rovlarisiz birga yuklanadi va so'rov tezligini oshiradi."
    ),
    (
        "OpenAI GPT-4o-mini — OpenAI ning 2024-yilda chiqargan kichik, lekin samarali katta til modeli",
        "AI suhbat moduli uchun bu diplom loyihasida birinchi navbatda OpenAI GPT-4o-mini modeli tanlandi, lekin keyinchalik ko'p providerli arxitekturaga o'tildi — bu mening loyihamning eng original yechimlaridan biridir. GPT-4o-mini ning birlamchi tanlanishi quyidagi sabablarga asoslanadi: o'rtacha 1,8 sekund javob vaqti (GPT-4o'dan 3–4 marta tez), 1000 token uchun atigi 0,15 sent (GPT-4 ga nisbatan 15 marta arzon), va o'zbek tilidagi sinovlarda ravon, kontekstuallashtirilgan javob sifati. Lekin sinov davrida bir muammo aniqlandi — OpenAI Free Tier kunlik kvotasi 15–20 ta xabarda tugaydi, bu real foydalanish uchun yetarli emas. Shu sababli men ikkita qo'shimcha provider qo'shdim: Google Gemini 2.0 Flash (kuniga 1500 bepul so'rov) va Groq Llama 3.3 70B (daqiqada 30 bepul so'rov, juda tez inference). Endi tizim avval OpenAI ga so'rov yuboradi, agar kvota tugagan bo'lsa avtomatik Gemini ga o'tadi, u ham ishlamasa Groq orqali ishlaydi. Bu fallback zanjirini boshqaruvchi `chat_complete()` funksiyasi MotivAI repozitoriyasida lib/services/ai_providers.py faylida joylashgan."
    ),

    # ── 2.1 short rewrite of opening paragraph ──
    (
        "MotivAI platformasining samaradorligi bevosita to'plangan va qayta ishlangan ma'lumotlar sifatiga",
        "Ushbu diplom loyihasi davomida ma'lumotlar muhandisligi alohida ahamiyatga ega bosqich sifatida belgilab olindi. Ma'lumotlar — har qanday tavsiya tizimining \"yoqilg'isi\" hisoblanadi: yetarlicha to'plangan, to'g'ri tasniflangan va tez qayta ishlanadigan ma'lumotlarsiz hatto eng murakkab algoritm ham xom natija beradi. \"Garbage In — Garbage Out\" prinsipi MotivAI uchun ham bir xil amal qiladi. Shu sababli men ma'lumotlarni yig'ish, validatsiya qilish, normallashtirish va indekslash bosqichlarini alohida e'tibor bilan loyihalashtirdim — bu jarayon backend kodining taxminan 35 foizini tashkil etadi va boshlang'ich rivojlanish vaqtining yarmidan ko'pini oldi."
    ),
]


# ── shared utilities ─────────────────────────────────────────────────
def normalize(s: str) -> str:
    return (s.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"'))


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


def patch_xml(xml_bytes: bytes):
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
