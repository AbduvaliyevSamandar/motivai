# -*- coding: utf-8 -*-
"""Swap embedded images in the thesis docx with our matplotlib PNGs.

The docx is a zip; embedded images live at word/media/imageN.png. We
replace each with the corresponding chart from docs/charts/png/ and
write a new docx alongside the original — the original is never
modified.
"""
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = Path("C:/Users/Samandar/Desktop/Abduvaliyev MotivAI Diplom Loyiha.docx")
DST = ROOT / "docs" / "Abduvaliyev MotivAI Diplom Loyiha — yangilangan.docx"
PNG = ROOT / "docs" / "charts" / "png"

# Original image1..12 -> our new chart files (1:1 by order in the doc).
SWAP = {
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


def main():
    assert SRC.exists(), f"Source docx not found: {SRC}"
    DST.parent.mkdir(parents=True, exist_ok=True)
    print(f"Reading: {SRC.name}")
    print(f"Writing: {DST.name}")
    swapped = 0
    with zipfile.ZipFile(SRC, "r") as src_zip, zipfile.ZipFile(
        DST, "w", zipfile.ZIP_DEFLATED
    ) as dst_zip:
        for entry in src_zip.namelist():
            data = src_zip.read(entry)
            base = Path(entry).name
            if entry.startswith("word/media/") and base in SWAP:
                replacement = PNG / SWAP[base]
                if not replacement.exists():
                    print(f"  ! missing replacement {replacement.name} — keeping original")
                else:
                    data = replacement.read_bytes()
                    swapped += 1
                    print(f"  swapped {base:<14} -> {SWAP[base]}  ({len(data) // 1024} KB)")
            dst_zip.writestr(entry, data)
    print(f"\nDone. {swapped} images replaced.")
    print(f"Output: {DST}")


if __name__ == "__main__":
    main()
