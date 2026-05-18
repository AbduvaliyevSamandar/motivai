# -*- coding: utf-8 -*-
"""Generate a polished MotivAI launcher icon and resize for every
Android density. Writes:
  assets/icon/icon.png             (1024x1024 — full bg)
  assets/icon/icon_foreground.png  (1024x1024 — transparent bg)
  android/app/src/main/res/mipmap-*/ic_launcher.png       (5 sizes)
  android/app/src/main/res/drawable-*/ic_launcher_foreground.png (5 sizes)
"""
from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SIZE = 1024
RADIUS = 224  # iOS-ish rounded square


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def diagonal_gradient(size, c1, c2):
    """Smooth top-left -> bottom-right gradient."""
    img = Image.new("RGB", (size, size), c1)
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = ((x + y) / (2 * size))
            px[x, y] = lerp(c1, c2, t)
    return img


def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def draw_letter_m(draw, size, color, shadow=False):
    """Draw a stylized M with thick rounded strokes."""
    # The M occupies roughly the middle 60% horizontally and 55% vertically
    w = int(size * 0.62)
    h = int(size * 0.56)
    cx, cy = size // 2, int(size * 0.52)
    left = cx - w // 2
    right = cx + w // 2
    top = cy - h // 2
    bottom = cy + h // 2

    stroke = int(size * 0.115)
    half = stroke // 2

    # Four anchor points: bottom-left, top-left peak, middle valley,
    # top-right peak, bottom-right.
    p_bl = (left + half, bottom - half)
    p_tl = (left + half, top + half)
    p_mid = (cx, top + int(h * 0.42))
    p_tr = (right - half, top + half)
    p_br = (right - half, bottom - half)

    points = [p_bl, p_tl, p_mid, p_tr, p_br]

    if shadow:
        shifted = [(x + int(size * 0.012), y + int(size * 0.018))
                   for (x, y) in points]
        draw.line(shifted, fill=(0, 0, 0, 110), width=stroke, joint="curve")
        # Rounded line endcaps
        r = half
        for (x, y) in (shifted[0], shifted[-1]):
            draw.ellipse((x - r + int(size * 0.012),
                          y - r + int(size * 0.018),
                          x + r + int(size * 0.012),
                          y + r + int(size * 0.018)),
                         fill=(0, 0, 0, 110))
        return

    draw.line(points, fill=color, width=stroke, joint="curve")
    r = half
    for (x, y) in (p_bl, p_br):
        draw.ellipse((x - r, y - r, x + r, y + r), fill=color)


def draw_growth_arrow(layer, size, color):
    """Small ascending arrow / spark to the upper-right of the M."""
    d = ImageDraw.Draw(layer)
    # Arrow shaft + head, anchored near top-right of the M's right leg
    base_x = int(size * 0.755)
    base_y = int(size * 0.36)
    tip_x = int(size * 0.83)
    tip_y = int(size * 0.21)
    shaft_w = int(size * 0.04)
    # Shaft
    d.line([(base_x, base_y), (tip_x, tip_y)], fill=color, width=shaft_w)
    # Arrow head
    head = int(size * 0.07)
    cos = math.cos(math.radians(45))
    sin = math.sin(math.radians(45))
    # head triangle
    hx1 = tip_x - int(head * cos)
    hy1 = tip_y + int(head * sin * 0.3)
    hx2 = tip_x + int(head * sin * 0.3)
    hy2 = tip_y + int(head * cos)
    d.polygon([(tip_x, tip_y - int(head * 0.2)),
               (hx1, hy1),
               (tip_x, tip_y + int(head * 0.4)),
               (hx2, hy2)],
              fill=color)


def draw_accent_dot(layer, size):
    """Amber accent dot at the bottom-left tip of the M."""
    d = ImageDraw.Draw(layer)
    cx = int(size * 0.205)
    cy = int(size * 0.795)
    r = int(size * 0.04)
    # Soft glow
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for i in range(6, 0, -1):
        gd.ellipse((cx - r - i * 4, cy - r - i * 4,
                    cx + r + i * 4, cy + r + i * 4),
                   fill=(245, 158, 11, 24))
    glow = glow.filter(ImageFilter.GaussianBlur(6))
    layer.alpha_composite(glow)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(245, 158, 11, 255))
    # Tiny highlight
    hr = int(r * 0.45)
    d.ellipse((cx - hr - r // 3, cy - hr - r // 3,
               cx + hr - r // 3, cy + hr - r // 3),
              fill=(254, 215, 170, 230))


def build_master():
    # Premium indigo->purple gradient
    bg = diagonal_gradient(SIZE, (79, 70, 229), (124, 58, 237))  # #4F46E5 -> #7C3AED
    # Mild inner highlight (top-left lighter spot)
    highlight = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    hd = ImageDraw.Draw(highlight)
    for i in range(30):
        alpha = int(60 * (1 - i / 30))
        hd.ellipse((-200 + i * 4, -200 + i * 4,
                    500 + i * 4, 500 + i * 4),
                   fill=(255, 255, 255, alpha // 4))
    highlight = highlight.filter(ImageFilter.GaussianBlur(40))
    bg = bg.convert("RGBA")
    bg.alpha_composite(highlight)

    # Subtle vignette in bottom-right
    vignette = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    for i in range(20):
        a = int(36 * (i / 20))
        vd.ellipse((SIZE - 600 - i * 6, SIZE - 600 - i * 6,
                    SIZE + 200 - i * 6, SIZE + 200 - i * 6),
                   fill=(20, 0, 60, a))
    vignette = vignette.filter(ImageFilter.GaussianBlur(60))
    bg.alpha_composite(vignette)

    # Apply rounded square mask
    mask = rounded_mask(SIZE, RADIUS)
    rounded_bg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    rounded_bg.paste(bg, (0, 0), mask)

    # Mark layer (M + arrow + accent)
    mark = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    md = ImageDraw.Draw(mark)
    draw_letter_m(md, SIZE, (255, 255, 255, 255), shadow=False)
    draw_growth_arrow(mark, SIZE, (255, 255, 255, 255))
    draw_accent_dot(mark, SIZE)

    # Soft drop shadow under mark
    shadow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_layer)
    draw_letter_m(sd, SIZE, (0, 0, 0, 0), shadow=True)
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(12))

    full = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    full.alpha_composite(rounded_bg)
    full.alpha_composite(shadow_layer)
    full.alpha_composite(mark)
    return full, mark


def main():
    full_icon, foreground_only = build_master()

    icon_dir = ROOT / "assets" / "icon"
    icon_dir.mkdir(parents=True, exist_ok=True)
    full_icon.save(icon_dir / "icon.png", "PNG")
    foreground_only.save(icon_dir / "icon_foreground.png", "PNG")

    # Android mipmap sizes for ic_launcher.png
    mipmap = {
        "mdpi":    48,
        "hdpi":    72,
        "xhdpi":   96,
        "xxhdpi":  144,
        "xxxhdpi": 192,
    }
    res_dir = ROOT / "android" / "app" / "src" / "main" / "res"
    for density, sz in mipmap.items():
        out = res_dir / f"mipmap-{density}" / "ic_launcher.png"
        if not out.parent.exists():
            continue
        full_icon.resize((sz, sz), Image.LANCZOS).save(out, "PNG")
        print(f"  wrote {out}")

    # Adaptive icon foreground sizes
    drawable = {
        "mdpi":    108,
        "hdpi":    162,
        "xhdpi":   216,
        "xxhdpi":  324,
        "xxxhdpi": 432,
    }
    # Foreground needs ~33% inner padding for adaptive masking
    pad = 0.10
    canvas = int(SIZE)
    inner_size = int(SIZE * (1 - 2 * pad))
    fg_canvas = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    shrunk = foreground_only.resize((inner_size, inner_size), Image.LANCZOS)
    fg_canvas.paste(shrunk, ((canvas - inner_size) // 2,
                             (canvas - inner_size) // 2), shrunk)

    for density, sz in drawable.items():
        out = res_dir / f"drawable-{density}" / "ic_launcher_foreground.png"
        if not out.parent.exists():
            continue
        fg_canvas.resize((sz, sz), Image.LANCZOS).save(out, "PNG")
        print(f"  wrote {out}")

    print(f"\nMaster: {icon_dir / 'icon.png'}")


if __name__ == "__main__":
    main()
