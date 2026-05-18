# -*- coding: utf-8 -*-
"""Build a Taqriz.docx for the MotivAI thesis using the existing
Taqriz.docx as a formatting template. Replaces the body text in
place, preserves fonts / paragraph styles / signature block."""
from copy import deepcopy
from pathlib import Path
import zipfile

from lxml import etree

DESKTOP = Path(r"C:\Users\Samandar\Desktop")
SRC = DESKTOP / "Taqriz.docx"
DST = DESKTOP / "Taqriz - MotivAI - yangi.docx"

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
XML_NS = "{http://www.w3.org/XML/1998/namespace}"


HEADER = (
    "60610500 — Kompyuter injiniringi (\"AT servis\") ta'lim yo'nalishi talabasi "
    "Abduvaliyev Samandar Qobil o'g'lining "
    "\"Sun'iy intellekt yordamida talabalarning motivatsion rejasini taklif "
    "qiluvchi mobil ilova yaratish\" "
    "mavzusidagi diplom loyihaga"
)

BODY_PARAS = [
    # Para 1 — context + project introduction
    "Zamonaviy raqamli ta'lim muhitida talabalar motivatsiyasini saqlash va "
    "boshqarish dolzarb muammolardan biriga aylangan. UNESCO va OECD ning "
    "so'nggi yillardagi hisobotlari bo'yicha oliy ta'lim muassasalaridagi "
    "talabalarning yarmidan ko'pi motivatsion qiyinchiliklarni boshidan "
    "kechiradi. Ushbu sharoitda sun'iy intellekt, mashinali o'rganish va "
    "gamifikatsiya prinsiplari asosida shaxsiylashtirilgan motivatsiya "
    "tizimini yaratish katta ilmiy va amaliy ahamiyatga ega. Abduvaliyev "
    "Samandarning diplom loyihasida ishlab chiqilgan MotivAI mobil "
    "platformasi aynan shu zamonaviy ehtiyojlarga javob beruvchi original "
    "yechim hisoblanadi.",

    # Para 2 — what the thesis covers
    "Diplom loyihada tavsiya tizimlarining nazariy asoslari, ta'limda "
    "sun'iy intellektning o'rni, mashinali o'rganish algoritmlarining "
    "qiyosiy tahlili va masalaning rasmiy qo'yilishi sistematik tarzda "
    "yoritilgan. Self-Determination Theory va Csikszentmihalyi Flow "
    "nazariyalariga tayanib, muallif tomonidan to'rt komponentli "
    "Motivatsional Qiymat Funksiyasi (MVF) shakllantirilgan. Kontent "
    "o'xshashligi, kollaborativ filtrlash, qiyinlilik mosligi va "
    "vaqtinchalik muvofiqlik komponentlari empirik grid search natijasida "
    "tanlangan og'irliklar (0,25 / 0,25 / 0,35 / 0,15) bilan birlashtirilib, "
    "offline baholashda NDCG@5 = 0,78 ko'rsatkichiga erishilgan. K-means "
    "klasterlash asosida besh motivatsion arxetip (silhouette = 0,62) "
    "aniqlangan va gamifikatsiya tizimining yadrosiga aylantirilgan.",

    # Para 3 — practical implementation
    "Texnik tatbiq bosqichida Flutter (Dart), FastAPI (Python) va MongoDB "
    "Atlas asosida cross-platform mobil ilova hamda modulli RESTful API "
    "muvaffaqiyatli ishlab chiqilgan. API arxitekturasi 33 ta endpoint va "
    "6 ta router moduli bilan to'liq hujjatlashtirilgan, o'rtacha javob "
    "vaqti 94 ms ni tashkil etgan. Loyihaning eng original innovatsion "
    "yechimi sifatida ko'p providerli AI fallback zanjiri (OpenAI "
    "GPT-4o-mini → Google Gemini 2.0 Flash → Groq Llama 3.3 70B → qoida-"
    "asoslangan shablon) ishlab chiqilgan bo'lib, tizimning 99,6 foiz uptime "
    "kafolatini ta'minlaydi. Render.com va MongoDB Atlas bulut "
    "infratuzilmasida joylashtirilgan platforma 15 nafar foydalanuvchi "
    "ishtirokida 7 kunlik sinovdan o'tkazilgan va SUS = 79,4/100, "
    "NPS = +42, kunlik 3,8 ta kirish chastotasi natijalarini ko'rsatgan.",

    # Para 4 — applicability
    "Ish nazariy va amaliy jihatlarning uyg'un kombinatsiyasiga ega. "
    "Bitiruvchi mustaqil ravishda zamonaviy dasturiy muhandislik, sun'iy "
    "intellekt va ta'lim psixologiyasi sohalaridan kelib chiqib, butun "
    "ishlab chiqarish siklini — kontseptsiyadan publication darajasidagi "
    "deploy gacha — yakka holda amalga oshirgan. To'rtinchi bobda hayot "
    "faoliyati xavfsizligining ikki yo'nalishi (kompyuter xavfsizligi va "
    "telekommunikatsiya inshootlarida yong'in xavfsizligi) o'zbek va "
    "xalqaro normativ-huquqiy hujjatlar doirasida atroflicha yoritilgan. "
    "MotivAI platformasi O'zbekiston oliy ta'lim muassasalari, IT "
    "akademiyalari va kasbiy o'rganish markazlarida talabalar "
    "motivatsiyasini boshqarish vositasi sifatida joriy etish uchun "
    "tayyor. Loyihaning to'liq ochiq manba kodi GitHub orqali ommaga "
    "taqdim etilgan bo'lib, mahalliy EdTech ekotizimini rivojlantirishga "
    "muhim hissa qo'shadi.",

    # Conclusion
    "Yuqorida ko'rsatilgan fikr-mulohazalardan kelib chiqib, Abduvaliyev "
    "Samandar Qobil o'g'lining \"Sun'iy intellekt yordamida talabalarning "
    "motivatsion rejasini taklif qiluvchi mobil ilova yaratish\" mavzusidagi "
    "diplom loyihasi belgilangan talablarga to'liq mos keladi va muallif "
    "yuqori baho — \"a'lo\" (5) bahosiga loyiqdir.",
]


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
    new_run = etree.SubElement(p, f"{W}r")
    if template_rpr is not None:
        new_run.append(template_rpr)
    t = etree.SubElement(new_run, f"{W}t")
    t.text = new_text
    t.set(f"{XML_NS}space", "preserve")
    return True


def patch_xml(xml_bytes):
    parser = etree.XMLParser(remove_blank_text=False)
    tree = etree.fromstring(xml_bytes, parser)

    paras = list(tree.iter(f"{W}p"))
    # Original mapping:
    #   [0]  Header
    #   [1]  blank
    #   [2]  TAQRIZ
    #   [3]  blank
    #   [4]  body 1
    #   [5]  body 2
    #   [6]  body 3
    #   [7]  body 4
    #   [8]  conclusion
    #   [9..] blank + signature block

    replace_paragraph_text(paras[0], HEADER)
    body_para_idx = [4, 5, 6, 7, 8]
    for i, txt in zip(body_para_idx, BODY_PARAS):
        replace_paragraph_text(paras[i], txt)

    return etree.tostring(tree, xml_declaration=True, encoding="UTF-8",
                          standalone=True)


def main():
    if not SRC.exists():
        raise SystemExit(f"Template not found: {SRC}")
    with zipfile.ZipFile(SRC, "r") as src_zip, zipfile.ZipFile(
        DST, "w", zipfile.ZIP_DEFLATED
    ) as dst_zip:
        for entry in src_zip.namelist():
            data = src_zip.read(entry)
            if entry == "word/document.xml":
                data = patch_xml(data)
            dst_zip.writestr(entry, data)
    print(f"Output: {DST}")


if __name__ == "__main__":
    main()
