# -*- coding: utf-8 -*-
"""Use assets/images/D-seal.png as the single source of truth for the
app icon. Distribute it to:
  - assets/icon/icon.png            (master)
  - assets/icon/icon_foreground.png (adaptive fg, transparent bg + padding)
  - assets/images/logo.png          (used by splash / login screens)
  - android/.../mipmap-*/ic_launcher.png        (5 densities)
  - android/.../drawable-*/ic_launcher_foreground.png (5 densities)
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "images" / "D-seal.png"

# Cream background sampled from the D-seal logo
ADAPTIVE_BG = "#EDE9DC"


def sample_corner_color(img: Image.Image) -> tuple[int, int, int]:
    """Average a 16x16 swatch from the top-left to get bg color."""
    swatch = img.crop((4, 4, 20, 20)).convert("RGB")
    px = list(swatch.getdata())
    r = sum(p[0] for p in px) // len(px)
    g = sum(p[1] for p in px) // len(px)
    b = sum(p[2] for p in px) // len(px)
    return r, g, b


def main():
    if not SRC.exists():
        raise SystemExit(f"Source not found: {SRC}")
    master = Image.open(SRC).convert("RGBA")
    if master.width != 1024 or master.height != 1024:
        master = master.resize((1024, 1024), Image.LANCZOS)

    bg_rgb = sample_corner_color(master)
    bg_hex = "#{:02X}{:02X}{:02X}".format(*bg_rgb)
    print(f"Sampled background: {bg_hex}")

    # ── assets/icon/* ─────────────────────────────────────────────
    icon_dir = ROOT / "assets" / "icon"
    icon_dir.mkdir(parents=True, exist_ok=True)
    master.save(icon_dir / "icon.png", "PNG")
    print(f"  wrote {icon_dir / 'icon.png'}")

    # Adaptive foreground: same artwork, on a transparent canvas with
    # inner padding so the adaptive mask doesn't crop the wordmark.
    pad = 0.15
    inner = int(1024 * (1 - 2 * pad))
    fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    shrunk = master.resize((inner, inner), Image.LANCZOS)
    fg.paste(shrunk, ((1024 - inner) // 2, (1024 - inner) // 2), shrunk)
    fg.save(icon_dir / "icon_foreground.png", "PNG")
    print(f"  wrote {icon_dir / 'icon_foreground.png'}")

    # ── assets/images/logo.png (used by splash / login) ───────────
    logo_path = ROOT / "assets" / "images" / "logo.png"
    master.save(logo_path, "PNG")
    print(f"  wrote {logo_path}")

    # ── Android mipmap-* ic_launcher.png ──────────────────────────
    mipmap = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    res_dir = ROOT / "android" / "app" / "src" / "main" / "res"
    for density, sz in mipmap.items():
        out = res_dir / f"mipmap-{density}" / "ic_launcher.png"
        if not out.parent.exists():
            continue
        master.resize((sz, sz), Image.LANCZOS).save(out, "PNG")
        print(f"  wrote {out}")

    # ── Android drawable-* ic_launcher_foreground.png ─────────────
    drawable = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324,
                "xxxhdpi": 432}
    for density, sz in drawable.items():
        out = res_dir / f"drawable-{density}" / "ic_launcher_foreground.png"
        if not out.parent.exists():
            continue
        fg.resize((sz, sz), Image.LANCZOS).save(out, "PNG")
        print(f"  wrote {out}")

    print(f"\nMaster: {SRC}")
    print(f"Adaptive bg: {bg_hex}  -> set this in pubspec.yaml "
          f"flutter_launcher_icons.adaptive_icon_background")


if __name__ == "__main__":
    main()
