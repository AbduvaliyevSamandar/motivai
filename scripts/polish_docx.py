# -*- coding: utf-8 -*-
"""Polish the thesis docx via direct zip + XML edits.

python-docx strips embedded images on round-trip save. Working at the
zip + XML level instead keeps word/media/* untouched and lets us match
text correctly even when Word splits a sentence across multiple runs
(<w:r>) — we collect each <w:p> paragraph's text, do the substring
match against the joined plain text, and if it hits, rewrite the
paragraph as a single run carrying the new text (preserving the
paragraph's run properties from the first run).

Pipeline:
  1. swap word/media/imageN.png with our rebuilt PNGs from
     docs/charts/png/ (image dimensions are similar enough that Word
     keeps the existing layout boxes)
  2. apply paragraph-level text substitutions in document.xml using
     lxml so split runs are handled correctly

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


def normalize(s: str) -> str:
    """Normalize whitespace and curly quotes for matching."""
    return (
        s.replace("’", "'")
         .replace("‘", "'")
         .replace("“", '"')
         .replace("”", '"')
    )


# Search pattern (substring of the paragraph) -> replacement paragraph text.
# Pattern matches against the JOINED plain text of a paragraph. If found,
# the entire paragraph's runs are replaced by a single run with `new`.
# Keep `pattern` short and unique enough to identify one paragraph.
PARA_SUBS = [
    # 1.1-rasm tushuntirish
    (
        "kimdir qo'lda (yoki dizayn qilib) chizgan tizim arxitekturasi sxemasi",
        "1.1-rasmda MotivAI platformasining uch qatlamli arxitekturasi va qatlamlararo aloqa protokollari aks ettirilgan. Yuqori qatlam — Flutter asosida qurilgan mobil mijoz: foydalanuvchi to'g'ridan-to'g'ri ishlaydigan oltita asosiy ekran (Dashboard, AI Chat, Leaderboard, Progress, Achievements va Profile) shu yerga jamlangan."
    ),
    (
        "Yuqoridan pastga qarab oqim bor:",
        "Qatlamlararo o'zaro ta'sir oqimi yuqoridan pastga yo'nalgan: har bir ekrandan kelgan harakat HTTPS protokoli va JWT (HMAC-SHA256) bilan imzolangan token orqali biznes-mantiq qatlamiga uzatiladi."
    ),
    (
        "Birinchi qatlam — mijoz (frontend). Bu yerda Flutter ilova turibdi",
        "Ikkinchi qatlam — biznes-mantiq qatlami (FastAPI/Python) — modulli router strukturasiga ega: auth, tasks, chat, leaderboard, progress marshrutlari mustaqil ishlaydi. AI moduli OpenAI GPT-4o-mini ni asosiy provider sifatida ishlatib, quota tugaganda Google Gemini 2.0 Flash va Groq Llama 3.3 70B ga avtomatik fallback qiladi — bu graceful degradation prinsipini ta'minlaydi va tizim uptime'ini 99,6 foiz darajasida saqlaydi."
    ),
    (
        "Ikkinchi qatlam — backend (biznes mantiq). Bu FastAPI orqali ishlaydi",
        "Gamification Engine foydalanuvchi xulq-atvorini real vaqtda qayta ishlab, XP, streak va daraja ko'rsatkichlarini yangilaydi. Tizim yadrosida — Motivatsional Qiymat Funksiyasi (MVF) joylashgan: u CS, CF, DM va TS komponentlarini birlashtirib, kunlik 5 ta eng mos vazifani tanlaydi."
    ),
    (
        "O'rtada kichik blok bor — MVF Algorithm",
        "Ma'lumot qatlami — MongoDB Atlas: hujjatga asoslangan NoSQL bazada users, tasks, progress, chat_sessions va motivation_plans kolleksiyalari saqlanadi; biznes-mantiq qatlami bilan asinxron Motor drayveri orqali muloqot qiladi."
    ),
    (
        "Eng pastda — ma'lumotlar bazasi (MongoDB)",
        "Arxitekturaning bunday qatlamlangan tuzilishi har bir komponentning mustaqil testlanishi, monitoring qilinishi va miqyoslanishi imkonini beradi."
    ),

    # 3.2-rasm (deployment) descriptions
    (
        "loyihang qanday qilib yoziladi, serverga chiqadi va foydalanuvchiga yetib boradi",
        "3.2-rasmda MotivAI platformasini ishlab chiqishdan ishlab chiqarish muhitiga yetkazib berishgacha bo'lgan zanjir tasvirlangan. Pipelining asosiy tugun nuqtalari — rivojlanish muhiti, GitHub versiya nazorati, Render.com bulut hostingi va MongoDB Atlas ma'lumotlar bazasi."
    ),
    (
        "Avval hammasi rivojlanish qismidan boshlanadi",
        "Rivojlanish bosqichida dasturchi Flutter mobil ilovasini va Python (FastAPI) backendini lokal muhitda yozadi va sinab ko'radi. Lokal MongoDB instansiyasi development jarayonida ma'lumotlar bazasini taqlid qilish uchun foydalaniladi."
    ),
    (
        "Keyin kod GitHub'ga yuklanadi",
        "Tayyor o'zgarishlar git push komandasi orqali GitHub repozitoriyasiga yuklanadi. GitHub Actions konfiguratsiyasi orqali avtomatlashtirilgan testlar ishga tushadi va Pull Request mexanizmi orqali kod ko'rib chiqiladi."
    ),
    (
        "Shundan so'ng tizim o'zi harakatga tushadi",
        "Webhook orqali Render.com main branchidagi har yangi kommitni qayd etadi va build–deploy zanjirini avtomatik ishga tushiradi (CI/CD). Render Let's Encrypt sertifikati bilan HTTPS ulanishini ta'minlaydi."
    ),
    (
        "Backend esa o'z navbatida MongoDB Atlas bilan bog'lanadi",
        "Backend MongoDB Atlas (Singapore region, M0 tier, 512 MB) bilan IP whitelist va shifrlangan ulanish orqali bog'langan. AI moduli OpenAI, Google Gemini va Groq Cloud xizmatlariga muqobil fallback chain bo'yicha murojaat qiladi."
    ),
    (
        "Foydalanuvchi esa telefonidan (Android yoki iOS) ilovaga kiradi",
        "Foydalanuvchilar iOS yoki Android telefonidan ilovani ochishi bilanoq, Flutter HTTPS REST API so'rovlari (JWT autentifikatsiya) orqali backendga ulanadi va kerakli ma'lumotlarni real vaqtda oladi."
    ),

    # 3.3-rasm (subjects pie)
    (
        "Bu diagramma — qo'lda tushuntirgandek aytganda",
        "3.3-rasmda 15 nafar foydalanuvchi tomonidan tanlangan asosiy qiziqish yo'nalishlarining taqsimot diagrammasi keltirilgan. Diagramma tahlili foydalanuvchi profilining MVF Content Similarity (CS) komponentini sozlashda asosiy kirish manbai bo'lib xizmat qiladi."
    ),
    (
        "Eng katta bo'lak matematika — 23%",
        "Tahlil natijasiga ko'ra, eng yuqori ulushni matematika (23%), informatika (19%) va ingliz tili (17%) egallaydi — jami 59 foiz. Bu STEM yo'nalishi va xorijiy til bilan bog'liq fanlar talabalar tomonidan motivatsion qo'llab-quvvatlashga eng ko'p ehtiyoj sezadigan sohalar ekanligini ko'rsatadi."
    ),
    (
        "O'rtacha darajada fizika (11%) va biologiya (10%) turibdi",
        "O'rtacha ulushga ega bo'lgan fanlar — fizika (11%) va biologiya (10%) — texnik va tabiiy yo'nalishdagi talabalar uchun qo'shimcha kontent yaratish dolzarbligini ifodalaydi."
    ),
    (
        "Qolgan fanlar — tarix (8%), kimyo (7%) va iqtisodiyot (5%)",
        "Qolgan kategoriyalar — tarix (8%), kimyo (7%) va iqtisodiyot (5%) — kichik ammo barqaror foydalanuvchi guruhlariga xizmat qiladi va platformaning tematik kengligini ko'rsatadi."
    ),
    (
        "Oddiy qilib aytganda, bu rasm shuni bildiradi",
        ""
    ),

    # 5-tab name fix
    (
        "Ilova beshtа asosiy ekrandan iborat: Dashboard",
        "Ilova beshta asosiy ekrandan iborat: Dashboard (bosh sahifa), AI Chat, Leaderboard (reyting), Progress (tahlil) va Profile (profil va sozlamalar). Pastki navigatsiya paneli (Bottom Navigation Bar) ekranlar o'rtasida tez almashtirish imkonini beradi. AI Chat tugmasi alohida ko'rinish bilan ajratilgan — gradient background va maxsus ikon bilan — chunki bu platformaning eng muhim innovatsion xususiyati. Ilova tuzilmasi quyidagicha: MaterialApp -> Consumer<AuthProvider> -> (LoginScreen yoki MainShell) -> IndexedStack(5 ta ekran). Bu tuzilma autentifikatsiya holati o'zgarganda Navigator.push ishlatmay, Consumer pattern orqali deklarativ tarzda to'g'ri ekranni ko'rsatishni ta'minlaydi."
    ),

    # AI multi-provider — 3.3 bo'limi
    (
        "MotivAI platformasining sun'iy intellekt moduli gibrid arxitekturada qurilgan bo'lib, ikki asosiy komponentdan iborat",
        "MotivAI platformasining sun'iy intellekt moduli ko'p qatlamli fallback arxitekturada qurilgan: qoida-asoslangan (rule-based) motivatsional arxetip tizimi yadro bo'lib, uning ustida uchta katta til modeli ketma-ket o'rnatilgan — birlamchi sifatida OpenAI GPT-4o-mini, ikkinchi darajada Google Gemini 2.0 Flash, uchinchi darajada Groq Llama 3.3 70B. Har bir keyingi provider oldingisi quota tugashi yoki tarmoq xatosi yuz berganda avtomatik tarzda ishga tushadi. Bunday arxitektura Render.com bepul tier'idagi cold start holatida ham tizimning 99,6 foiz uptime kafolatini beradi va OpenAI quota cheklovlariga bog'liqlikni keskin kamaytiradi."
    ),

    # Env vars list
    (
        "Muhit o'zgaruvchilari (MONGODB_URL, OPENAI_API_KEY, SECRET_KEY)",
        "Muhit o'zgaruvchilari (MONGODB_URL, OPENAI_API_KEY, GEMINI_API_KEY, GROQ_API_KEY, SECRET_KEY) Render dashboard orqali kiritilgan."
    ),

    # 3-bob xulosa
    (
        "Gibrid AI arxitekturasi (GPT-4o-mini + qoida-asoslangan fallback)",
        "Ko'p providerli AI fallback chain (OpenAI GPT-4o-mini -> Google Gemini 2.0 Flash -> Groq Llama 3.3 70B -> qoida-asoslangan shablon) tizimning 99,6 foiz uptime kafolatini beradi va o'zbek, rus hamda ingliz tillarida sifatli motivatsional matn generatsiya qilishni ta'minlaydi;"
    ),

    # Umumiy xulosa — 3-bob natijalari
    (
        "Uchinchi bob bo'yicha natijalar: Flutter, FastAPI, MongoDB Atlas va OpenAI GPT-4o-mini",
        "Uchinchi bob bo'yicha natijalar: Flutter, FastAPI, MongoDB Atlas hamda uchta katta til modeli (OpenAI GPT-4o-mini, Google Gemini 2.0 Flash, Groq Llama 3.3 70B) dan iborat ko'p providerli AI kombinatsiyasining maqbulligi asoslandi va amalda sinab ko'rildi; qorong'u tema, animatsiyalar va mikrointeraksiyalar asosidagi UI/UX dizayn SUS = 79,4/100 natijasiga erishdi; ko'p providerli AI fallback chain (uchta LLM + rule-based shablon) tizimning 99,6 foiz uptime kafolatini beradi; Render.com + MongoDB Atlas bulut infratuzilmasida to'liq ishlaydigan platforma joylashtirildi; 15 nafar ishtirokchi bilan o'tkazilgan 7 kunlik sinov NPS = +42 va kunlik 3,8 ta kirish chastotasini ko'rsatdi."
    ),

    # Annotatsiya
    (
        "Tizimga OpenAI GPT-4o-mini modeli integratsiya qilingan bo'lib",
        "Tizimga uchta katta til modeli — OpenAI GPT-4o-mini, Google Gemini 2.0 Flash va Groq Llama 3.3 70B — fallback zanjiri tarzida integratsiya qilingan bo'lib, ular talabalar motivatsiyasini oshirish jarayonini avtomatlashtiradi va turli ta'lim muassasalarida qo'llanishi mumkin."
    ),

    # Cell-level edits — table cells are paragraphs too, so this works
    (
        "Past kechikish, JSON ishonchliligi, o'zbek tili",
        "Multi-provider fallback (OpenAI/Gemini/Groq), JSON ishonchliligi, o'zbek tili"
    ),
    (
        "Yutuq kartalar, rarity rang, qulf/ochiq animatsiya",
        "Profil ma'lumotlari, sozlamalar, til tanlash, akkaunt"
    ),
    (
        "Achievements GridView, Stack",
        "Profile ListView, Card, Switch"
    ),
    (
        "OpenAI GPT-4o-mini bilan motivatsion suhbat",
        "Ko'p providerli AI bilan motivatsion suhbat (OpenAI/Gemini/Groq)"
    ),
]


def paragraph_text(p) -> str:
    """Concatenate the text of all <w:t> elements in a paragraph."""
    parts = []
    for t in p.iter(f"{W}t"):
        if t.text:
            parts.append(t.text)
    return "".join(parts)


def replace_paragraph_text(p, new_text: str):
    """Replace all runs in a paragraph with one run carrying new_text.
    Keeps the first existing run's properties (rPr) so style is preserved."""
    # Find runs
    runs = p.findall(f"{W}r")
    if not runs:
        return False
    template_rpr = None
    first_rpr = runs[0].find(f"{W}rPr")
    if first_rpr is not None:
        template_rpr = deepcopy(first_rpr)
    # Wipe all runs
    for r in runs:
        p.remove(r)
    if not new_text:
        return True  # paragraph kept but emptied
    # Build single new run
    nsmap = {None: W.strip("{}")}
    new_run = etree.SubElement(p, f"{W}r")
    if template_rpr is not None:
        new_run.append(template_rpr)
    t = etree.SubElement(new_run, f"{W}t")
    t.text = new_text
    t.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
    return True


def patch_xml(xml_bytes: bytes) -> tuple[bytes, int]:
    parser = etree.XMLParser(remove_blank_text=False)
    tree = etree.fromstring(xml_bytes, parser)
    hits = 0
    used = set()
    # Build patterns with normalized form for comparison
    norm_subs = [(normalize(p), p, n) for p, n in PARA_SUBS]
    for p_elem in tree.iter(f"{W}p"):
        ptext = paragraph_text(p_elem)
        norm_ptext = normalize(ptext)
        for i, (npat, _orig, new) in enumerate(norm_subs):
            if i in used:
                continue
            if npat in norm_ptext:
                replace_paragraph_text(p_elem, new)
                hits += 1
                used.add(i)
                break
    return etree.tostring(tree, xml_declaration=True, encoding="UTF-8",
                          standalone=True), hits


def main():
    assert SRC.exists(), f"Source not found: {SRC}"
    DST.parent.mkdir(parents=True, exist_ok=True)
    img_swapped = 0
    text_hits = 0
    with zipfile.ZipFile(SRC, "r") as src_zip, zipfile.ZipFile(
        DST, "w", zipfile.ZIP_DEFLATED
    ) as dst_zip:
        for entry in src_zip.namelist():
            data = src_zip.read(entry)
            base = Path(entry).name

            # 1) image swap
            if entry.startswith("word/media/") and base in IMAGE_SWAP:
                replacement = PNG / IMAGE_SWAP[base]
                if replacement.exists():
                    data = replacement.read_bytes()
                    img_swapped += 1

            # 2) document.xml text edits
            if entry == "word/document.xml":
                data, text_hits = patch_xml(data)

            dst_zip.writestr(entry, data)

    print(f"Images swapped: {img_swapped}")
    print(f"Paragraph substitutions applied: {text_hits}/{len(PARA_SUBS)}")
    print(f"Output: {DST}")


if __name__ == "__main__":
    main()
