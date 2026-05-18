# -*- coding: utf-8 -*-
"""Generate the MotivAI app logo as 1024x1024 PNGs.

Concept: rounded-square gradient (indigo -> purple) with a stylized
white "M" whose right leg lifts into an upward arrow — visual shorthand
for motivation rising. A small accent dot marks the AI/spark.

Outputs:
  assets/icon/icon.png            — full square icon (Play Store / launcher)
  assets/icon/icon_foreground.png — transparent foreground for Android
                                     adaptive icons (the launcher draws
                                     the background separately)
  assets/icon/logo_master.png     — same as icon.png, kept as the
                                     editable master for marketing use

After running this, run flutter_launcher_icons to regenerate the
per-density Android assets.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "icon"
OUT.mkdir(parents=True, exist_ok=True)

SIZE = 1024
RADIUS = 220  # rounded corner radius for the icon square

# Brand palette (matches AppColors.primary / secondary)
INDIGO = (79, 70, 229)      # #4F46E5
PURPLE = (124, 58, 237)     # #7C3AED
WHITE = (255, 255, 255)
ACCENT = (251, 191, 36)     # #FBBF24 amber spark


def gradient_background(size: int) -> Image.Image:
    """Diagonal indigo → purple gradient, rounded corners."""
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pixels = bg.load()
    diag = (size - 1) * 1.4
    for y in range(size):
        for x in range(size):
            t = (x + y) / diag
            t = max(0.0, min(1.0, t))
            r = int(INDIGO[0] + (PURPLE[0] - INDIGO[0]) * t)
            g = int(INDIGO[1] + (PURPLE[1] - INDIGO[1]) * t)
            b = int(INDIGO[2] + (PURPLE[2] - INDIGO[2]) * t)
            pixels[x, y] = (r, g, b, 255)
    return bg


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def draw_glyph(canvas: Image.Image, color, with_glow=True):
    """Stylized 'M' with the right leg sweeping into an upward arrow.

    Drawn as a series of polygons so the strokes have crisp,
    intentional terminals — better than rendering a text "M"."""
    w, h = canvas.size
    cx = w / 2
    # Geometry tuned for visual balance at 1024×1024
    stroke = w * 0.105
    inset_x = w * 0.30
    top_y = h * 0.30
    bottom_y = h * 0.72
    mid_x = cx
    valley_y = h * 0.55

    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    # Left vertical leg of the M
    left_x = w * 0.30
    d.rounded_rectangle(
        (left_x - stroke / 2, top_y, left_x + stroke / 2, bottom_y),
        radius=int(stroke * 0.35), fill=color,
    )

    # Diagonal: top-left -> valley
    d.polygon([
        (left_x - stroke * 0.22, top_y + stroke * 0.20),
        (left_x + stroke * 0.78, top_y + stroke * 0.20),
        (mid_x + stroke * 0.40, valley_y),
        (mid_x - stroke * 0.60, valley_y),
    ], fill=color)

    # Diagonal: valley -> top-right
    right_x = w * 0.70
    d.polygon([
        (right_x - stroke * 0.78, top_y + stroke * 0.20),
        (right_x + stroke * 0.22, top_y + stroke * 0.20),
        (mid_x + stroke * 0.60, valley_y),
        (mid_x - stroke * 0.40, valley_y),
    ], fill=color)

    # Right leg curving upward into the arrow head — drawn as a tilted
    # tapered bar plus an arrow head triangle floating above-right.
    # Right vertical
    d.rounded_rectangle(
        (right_x - stroke / 2, top_y, right_x + stroke / 2, bottom_y),
        radius=int(stroke * 0.35), fill=color,
    )

    # Upward arrow shaft (the right leg "lifts off" beyond the M)
    arrow_x = right_x + w * 0.04
    arrow_top = h * 0.20
    arrow_bottom = top_y - stroke * 0.05
    d.rounded_rectangle(
        (arrow_x - stroke * 0.32, arrow_top,
         arrow_x + stroke * 0.32, arrow_bottom),
        radius=int(stroke * 0.20), fill=color,
    )
    # Arrow head
    head = stroke * 1.05
    d.polygon([
        (arrow_x, arrow_top - head * 0.85),
        (arrow_x - head * 0.85, arrow_top + head * 0.10),
        (arrow_x + head * 0.85, arrow_top + head * 0.10),
    ], fill=color)

    # Subtle accent spark — bottom-left of the M, suggests AI / motion
    spark_x = left_x - w * 0.06
    spark_y = bottom_y + stroke * 0.10
    spark_r = stroke * 0.30
    d.ellipse((spark_x - spark_r, spark_y - spark_r,
               spark_x + spark_r, spark_y + spark_r), fill=ACCENT)

    if with_glow:
        glow = layer.filter(ImageFilter.GaussianBlur(8))
        canvas.alpha_composite(glow)
    canvas.alpha_composite(layer)


def build_full_icon():
    """Square icon with gradient bg + rounded corners + glyph."""
    bg = gradient_background(SIZE)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(bg, (0, 0), rounded_mask(SIZE, RADIUS))
    draw_glyph(canvas, WHITE, with_glow=True)
    return canvas


def build_foreground():
    """Transparent background, glyph only — for Android adaptive icon.

    Adaptive icons reserve a 25% safe-zone padding on every side, so the
    glyph is drawn into a 1024×1024 frame but visually occupies only the
    central ~768×768 area (Android crops/clips around it)."""
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    # Draw glyph into a smaller inner area (66% of frame), centered.
    inner = Image.new("RGBA", (int(SIZE * 0.66), int(SIZE * 0.66)),
                      (0, 0, 0, 0))
    draw_glyph(inner, WHITE, with_glow=False)
    offset = (SIZE - inner.size[0]) // 2
    canvas.alpha_composite(inner, (offset, offset))
    return canvas


def main():
    icon = build_full_icon()
    icon.save(OUT / "icon.png", optimize=True)
    icon.save(OUT / "logo_master.png", optimize=True)
    fg = build_foreground()
    fg.save(OUT / "icon_foreground.png", optimize=True)
    print(f"icon.png            -> {(OUT / 'icon.png').stat().st_size // 1024} KB")
    print(f"icon_foreground.png -> {(OUT / 'icon_foreground.png').stat().st_size // 1024} KB")
    print(f"logo_master.png     -> {(OUT / 'logo_master.png').stat().st_size // 1024} KB")
    print(f"Saved to {OUT}")


if __name__ == "__main__":
    main()
