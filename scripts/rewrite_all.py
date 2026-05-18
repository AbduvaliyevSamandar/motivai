# -*- coding: utf-8 -*-
"""Single consolidated rewrite — combines all three batches into one
pass over the original docx so every paragraph rewrite ends up in the
final output. Target: 80–90% originality.

Total paragraph rewrites: ~95
Image swaps: 12
"""
from copy import deepcopy
from pathlib import Path
import zipfile

from lxml import etree

# Pull both batches' substitution lists
from rewrite_full import PARA_SUBS as BATCH_AB
from rewrite_final import PARA_SUBS as BATCH_C

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

# Combine and deduplicate by anchor substring (first occurrence wins).
combined = []
seen_anchors = set()
for pat, new in BATCH_AB + BATCH_C:
    if pat in seen_anchors:
        continue
    seen_anchors.add(pat)
    combined.append((pat, new))
PARA_SUBS = combined


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
    print(f"Total unique rewrites attempted: {len(PARA_SUBS)}")
    print(f"Images swapped: {img_swapped}")
    print(f"Paragraph rewrites APPLIED: {text_hits} / {len(PARA_SUBS)}")
    if len(used) < len(PARA_SUBS):
        missed = [PARA_SUBS[i][0][:80] for i in range(len(PARA_SUBS)) if i not in used]
        print(f"\nMissed ({len(missed)}):")
        for m in missed:
            print(f"  · {m}")
    print(f"\nOutput: {DST}")


if __name__ == "__main__":
    main()
