# -*- coding: utf-8 -*-
"""Render all 12 thesis diagrams as polished PNGs.

Produces docs/charts/png/01-..png ... 12-..png at DPI 220.
Style mirrors the original matplotlib charts in the .docx: rounded
boxes, drop shadows, bold colored headers, curved arrows on a light
neutral background.
"""
from __future__ import annotations

import math
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Rectangle

# ── Style ──────────────────────────────────────────────────────────────
plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "font.size": 11,
    "axes.titlesize": 14,
    "axes.titleweight": "bold",
    "savefig.facecolor": "white",
    "savefig.dpi": 220,
})

C = {
    "indigo":  "#4F46E5",
    "purple":  "#7C3AED",
    "pink":    "#EC4899",
    "amber":   "#F59E0B",
    "amber_l": "#FBBF24",
    "emerald": "#10B981",
    "emerald_d": "#059669",
    "red":     "#EF4444",
    "sky":     "#0EA5E9",
    "slate":   "#64748B",
    "ink":     "#0F172A",
    "txt":     "#1F2937",
    "sub":     "#6B7280",
    "border":  "#E5E7EB",
}

OUT = Path(__file__).resolve().parent.parent / "docs" / "charts" / "png"
OUT.mkdir(parents=True, exist_ok=True)


def tint(hexcol: str, amount: float) -> str:
    """Lighten a hex color by mixing with white."""
    h = hexcol.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    r = int(r + (255 - r) * amount)
    g = int(g + (255 - g) * amount)
    b = int(b + (255 - b) * amount)
    return f"#{r:02X}{g:02X}{b:02X}"


def box(ax, x, y, w, h, *, color=C["indigo"], fill=None, lw=1.8, radius=0.06,
        shadow=True):
    """Rounded rect with optional drop shadow."""
    if fill is None:
        fill = tint(color, 0.92)
    if shadow:
        sh = FancyBboxPatch((x + 0.04, y - 0.06), w, h,
                            boxstyle=f"round,pad=0,rounding_size={radius}",
                            linewidth=0, facecolor="#00000010", zorder=1)
        ax.add_patch(sh)
    p = FancyBboxPatch((x, y), w, h,
                       boxstyle=f"round,pad=0,rounding_size={radius}",
                       linewidth=lw, edgecolor=color, facecolor=fill, zorder=2)
    ax.add_patch(p)
    return p


def title_inside(ax, x, y, w, h, text, *, color=C["indigo"],
                 size=12, weight="bold"):
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            color=color, fontsize=size, fontweight=weight, zorder=4)


def arrow(ax, p1, p2, *, color=C["slate"], lw=1.6, rad=0.0, label=None,
          label_color=None, style="-|>"):
    a = FancyArrowPatch(p1, p2, arrowstyle=style, mutation_scale=16,
                        color=color, linewidth=lw,
                        connectionstyle=f"arc3,rad={rad}", zorder=3)
    ax.add_patch(a)
    if label:
        mx, my = (p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2
        ax.text(mx, my, label, ha="center", va="center",
                color=label_color or color, fontsize=9, fontstyle="italic",
                bbox=dict(boxstyle="round,pad=0.2", fc="white", ec="none"),
                zorder=5)


def fig(w=14, h=8):
    f, ax = plt.subplots(figsize=(w, h))
    ax.set_xlim(0, 100); ax.set_ylim(0, 100)
    ax.axis("off"); ax.set_aspect("auto")
    return f, ax


def save(f, name):
    path = OUT / name
    f.savefig(path, bbox_inches="tight", facecolor="white")
    plt.close(f)
    return path


# ── 01: 3-tier architecture ─────────────────────────────────────────────
def d01_architecture():
    f, ax = fig(14, 9)
    # Tier 1: Mijoz
    box(ax, 5, 75, 90, 18, color=C["indigo"], fill=tint(C["indigo"], 0.95), radius=0.04)
    ax.text(50, 91, "MIJOZ QATLAMI (Flutter / Dart)", ha="center", va="center",
            fontsize=14, fontweight="bold", color=C["indigo"])
    screens = ["Dashboard", "AI Chat", "Leaderboard", "Progress", "Achievements", "Profile"]
    for i, s in enumerate(screens):
        x = 7 + i * 14.6
        box(ax, x, 78, 13, 8, color=C["indigo"], fill="white", radius=0.10, shadow=False, lw=1.4)
        title_inside(ax, x, 78, 13, 8, s, color=C["indigo"], size=10)

    # Tier 2: Biznes
    box(ax, 5, 38, 90, 28, color=C["purple"], fill=tint(C["purple"], 0.96), radius=0.04)
    ax.text(50, 62, "BIZNES MANTIQ QATLAMI (FastAPI / Python)", ha="center", va="center",
            fontsize=14, fontweight="bold", color=C["purple"])
    routers = ["Auth\nRouter", "Tasks\nRouter", "Chat\nRouter", "Leaderboard\nRouter",
               "Progress\nRouter", "AI Module\n(GPT-4o-mini)", "Gamification\nEngine"]
    for i, r in enumerate(routers):
        x = 6 + i * 12.8
        box(ax, x, 47, 11.5, 9, color=C["purple"], fill="white", radius=0.10, shadow=False, lw=1.4)
        ax.text(x + 5.75, 51.5, r, ha="center", va="center",
                fontsize=9, color=C["purple"], fontweight="bold")
    # MVF box
    box(ax, 33, 39.5, 34, 5, color=C["amber"], fill=tint(C["amber"], 0.85), radius=0.20, shadow=False, lw=1.4)
    ax.text(50, 42, "MVF Algoritmi (CS + CF + DM + TS)", ha="center", va="center",
            fontsize=11, fontweight="bold", color="#92400E")

    # Tier 3: Data
    box(ax, 5, 7, 90, 22, color=C["emerald"], fill=tint(C["emerald"], 0.95), radius=0.04)
    ax.text(50, 26, "MA'LUMOTLAR QATLAMI (MongoDB Atlas)", ha="center", va="center",
            fontsize=14, fontweight="bold", color=C["emerald_d"])
    cols = ["users", "tasks", "progress", "chat_sessions", "motivation_plans"]
    for i, c in enumerate(cols):
        x = 7 + i * 17.6
        box(ax, x, 11, 16, 9, color=C["emerald"], fill="white", radius=0.08, shadow=False, lw=1.4)
        title_inside(ax, x, 11, 16, 9, c, color=C["emerald_d"], size=11)

    # Connecting arrows + labels
    arrow(ax, (50, 75), (50, 66), color=C["slate"], lw=1.4)
    ax.text(54, 70.5, "HTTPS / JWT", color=C["slate"], fontsize=10, fontstyle="italic")
    arrow(ax, (50, 38), (50, 29), color=C["slate"], lw=1.4)
    ax.text(54, 33.5, "Motor (async)", color=C["slate"], fontsize=10, fontstyle="italic")

    # External OpenAI box (dashed)
    p = FancyBboxPatch((78.5, 67.5), 16, 5.5,
                       boxstyle="round,pad=0,rounding_size=0.4",
                       linewidth=1.6, edgecolor=C["red"], facecolor=tint(C["red"], 0.92),
                       linestyle="dashed", zorder=2)
    ax.add_patch(p)
    ax.text(86.5, 70.25, "OpenAI API\n(GPT-4o-mini)", ha="center", va="center",
            color=C["red"], fontsize=9, fontweight="bold")
    arrow(ax, (86.5, 67.5), (86.5, 56), color=C["red"], lw=1.4, style="-|>", rad=0.0)

    save(f, "01-architecture.png")


# ── 02: Gamification levels ────────────────────────────────────────────
def d02_levels():
    f, ax = fig(15, 8)
    levels = [
        ("1", "Boshlang'ich", "Beginner",       "Jami bajarilgan\nvazifa = 0",
         ["Oson vazifalar", "Katta mukofot", "Onboarding"], C["emerald"]),
        ("2", "Tadqiqotchi",  "Explorer",       "Haftalik < 5\nvazifa",
         ["Turli kategoriyalar", "Kashfiyot effekti", "Yangi mavzular"], C["sky"]),
        ("3", "Izchil",       "Consistent",     "Streak ≥ 3 kun",
         ["Barqaror tavsiya", "Streak himoyasi", "Haftalik maqsad"], C["purple"]),
        ("4", "Muvaffaqiyatli", "Achiever",     "Haftalik > 5\nvazifa",
         ["Qiyin vazifalar", "Yutuq nishonlari", "Shaxsiy rekord"], C["amber"]),
        ("5", "Chempion",     "Champion",       "Streak ≥ 14 &\nhaftalik > 10",
         ["Ekspert darajasi", "Reyting Top 10%", "Global raqobat"], C["red"]),
    ]
    n = len(levels)
    pad = 1.2
    w = (100 - pad * (n + 1)) / n
    for i, (num, name, en, criterion, bullets, col) in enumerate(levels):
        x = pad + i * (w + pad)
        # Top: number circle
        box(ax, x, 70, w, 26, color=col, fill="white", radius=0.06, lw=2.0)
        circle = plt.Circle((x + w/2, 88), 4.2, color=col, zorder=4)
        ax.add_patch(circle)
        ax.text(x + w/2, 88, num, ha="center", va="center",
                color="white", fontsize=18, fontweight="bold", zorder=5)
        ax.text(x + w/2, 78, name, ha="center", va="center",
                color=col, fontsize=13, fontweight="bold")
        ax.text(x + w/2, 74, en, ha="center", va="center",
                color=C["sub"], fontsize=10, fontstyle="italic")
        # Middle: criterion tinted strip
        box(ax, x, 55, w, 11, color=col, fill=tint(col, 0.85), radius=0.10, lw=0, shadow=False)
        ax.text(x + w/2, 60.5, criterion, ha="center", va="center",
                color=C["txt"], fontsize=10)
        # Bottom: bullets
        box(ax, x, 22, w, 28, color=col, fill="white", radius=0.06, lw=1.6)
        for bi, b in enumerate(bullets):
            ax.text(x + 1.5, 43 - bi * 5, f"• {b}", ha="left", va="center",
                    color=C["txt"], fontsize=9.5)
        # Arrow to next
        if i < n - 1:
            arrow(ax, (x + w + 0.2, 88), (x + w + pad - 0.2, 88), color=col, lw=2.0, style="-|>")
    save(f, "02-gamification-levels.png")


# ── 03: MongoDB schema ER ──────────────────────────────────────────────
def d03_schema():
    f, ax = fig(14, 9)
    ax.text(50, 95, "MongoDB Atlas ma'lumotlar bazasi sxemasi (5 ta asosiy kolleksiya)",
            ha="center", va="center", fontsize=14, fontweight="bold", color=C["ink"])

    def coll(x, y, w, h, name, fields, col):
        box(ax, x, y, w, h, color=col, fill="white", radius=0.05, lw=1.8)
        # header
        hdr = FancyBboxPatch((x, y + h - 5), w, 5,
                             boxstyle="round,pad=0,rounding_size=0.05",
                             linewidth=0, facecolor=tint(col, 0.85), zorder=3)
        ax.add_patch(hdr)
        ax.text(x + w/2, y + h - 2.5, name, ha="center", va="center",
                color=col, fontsize=12, fontweight="bold")
        # fields
        for i, fl in enumerate(fields):
            ax.text(x + 1.5, y + h - 7.5 - i * 2.6, fl,
                    fontsize=9, color=C["txt"], family="monospace")

    coll(8, 60, 24, 28, "users", [
        "_id: ObjectId", "email: str (UNIQUE)", "password_hash: str",
        "name: str", "level: int", "xp: int", "streak: int", "archetype: str",
        "preferences: {}", "badges: []", "created_at: datetime",
    ], C["indigo"])
    coll(38, 60, 24, 28, "tasks", [
        "_id: ObjectId", "title: str", "description: str", "category: str",
        "difficulty: int (1-4)", "xp_reward: int", "duration_minutes: int",
        "is_active: bool", "tags: []",
    ], C["purple"])
    coll(68, 60, 24, 28, "progress", [
        "_id: ObjectId", "user_id: ObjectId →", "task_id: ObjectId →",
        "completed_at: datetime", "category: str", "duration_actual: int",
        "status: enum",
    ], C["emerald"])
    coll(8, 18, 28, 26, "chat_sessions", [
        "_id: ObjectId", "user_id: ObjectId →",
        "created_at: datetime", "task_suggestions: []",
        "archetype_context: str",
    ], C["amber"])
    coll(60, 18, 32, 26, "motivation_plans", [
        "_id: ObjectId", "user_id: ObjectId →", "archetype: enum",
        "weekly_goals: []", "schedule: []", "created_at: datetime",
        "ai_generated: bool",
    ], C["red"])

    # Relations with cardinality
    arrow(ax, (32, 74), (38, 74), color=C["slate"], lw=1.4)
    ax.text(35, 76, "1:N", fontsize=9, color=C["slate"], ha="center")
    arrow(ax, (32, 70), (68, 70), color=C["slate"], lw=1.4, rad=-0.18)
    ax.text(50, 65, "1:N", fontsize=9, color=C["slate"], ha="center")
    arrow(ax, (62, 74), (68, 74), color=C["slate"], lw=1.4)
    ax.text(65, 76, "1:N", fontsize=9, color=C["slate"], ha="center")
    arrow(ax, (20, 60), (22, 44), color=C["slate"], lw=1.4)
    arrow(ax, (20, 60), (76, 44), color=C["slate"], lw=1.4, rad=-0.15)

    ax.text(50, 6, "Indekslar: email (unique), xp (desc), user_id+completed_at (compound)",
            ha="center", va="center", fontsize=10, fontstyle="italic", color=C["sub"])
    save(f, "03-database-schema.png")


# ── 04: MVF formula ────────────────────────────────────────────────────
def d04_mvf():
    f, ax = fig(14, 9)
    ax.text(50, 95, "Motivatsional Qiymat Funksiyasi (MVF) — to'rt komponentli gibrid model",
            ha="center", va="center", fontsize=14, fontweight="bold", color=C["ink"])

    comps = [
        ("CS(u, t)", "Kontent\nO'xshashlik",  "w₁ = 0.25", C["indigo"]),
        ("CF(u, t)", "Kollaborativ\nFiltrlash", "w₂ = 0.25", C["purple"]),
        ("DM(u, t, L)", "Qiyinlilik\nMosligi", "w₃ = 0.35", C["amber"]),
        ("TS(u, t, C)", "Vaqtinchalik\nMuvofiqlik", "w₄ = 0.15", C["emerald"]),
    ]
    cw = 17
    gap = (100 - 4 * cw) / 5
    for i, (sym, name, w, col) in enumerate(comps):
        x = gap + i * (cw + gap)
        box(ax, x, 65, cw, 18, color=col, fill="white", radius=0.10, lw=2.0)
        ax.text(x + cw/2, 79, sym, ha="center", color=col, fontsize=12, fontweight="bold")
        ax.text(x + cw/2, 74, name, ha="center", color=C["txt"], fontsize=10)
        ax.text(x + cw/2, 68, w, ha="center", color=col, fontsize=9, fontstyle="italic")
        # arrow down
        arrow(ax, (x + cw/2, 65), (50, 50), color=col, lw=1.4, rad=0.10 if i < 2 else -0.10)

    # MVF main box
    box(ax, 33, 35, 34, 14, color=C["indigo"], fill=C["indigo"], radius=0.10, lw=0)
    ax.text(50, 42, "MVF(u, t, C)", ha="center", va="center",
            color="white", fontsize=20, fontweight="bold")

    # Formula
    box(ax, 25, 24, 50, 6, color=C["amber"], fill=tint(C["amber"], 0.85), radius=0.10, lw=0, shadow=False)
    ax.text(50, 27, "MVF = w₁·CS + w₂·CF + w₃·DM + w₄·TS",
            ha="center", va="center", color="#92400E", fontsize=14, fontweight="bold")

    ax.text(50, 17, "Nazariy asos: Self-Determination Theory (Deci & Ryan, 1985)  +  Flow Theory (Csikszentmihalyi, 1990)",
            ha="center", va="center", fontsize=10, fontstyle="italic", color=C["sub"])

    box(ax, 25, 5, 50, 7, color=C["emerald"], fill=tint(C["emerald"], 0.85), radius=0.10, lw=1.6)
    ax.text(50, 8.5, "Natija: Top K=5 ta kunlik vazifa (NDCG@5 = 0.78)",
            ha="center", va="center", fontsize=12, fontweight="bold", color=C["emerald_d"])
    save(f, "04-mvf-formula.png")


# ── 05: XP curve + Streak bonus ────────────────────────────────────────
def d05_xp_streak():
    f, axes = plt.subplots(1, 2, figsize=(14, 6))
    f.patch.set_facecolor("white")

    # Left: XP per level
    levels = np.arange(1, 21)
    xp = (levels - 1) ** 2 * 50 + (levels - 1) * 80
    ax1 = axes[0]
    ax1.plot(levels, xp, color=C["indigo"], linewidth=2.6, marker="o",
             markersize=7, markerfacecolor="white", markeredgewidth=2.2)
    ax1.fill_between(levels, xp, alpha=0.18, color=C["indigo"])
    ax1.set_title("MotivAI darajalar tizimi (1-20)", fontsize=14, fontweight="bold")
    ax1.set_xlabel("Daraja (Level)", fontsize=11)
    ax1.set_ylabel("Talab qilinadigan umumiy XP", fontsize=11)
    ax1.set_xticks(np.arange(1, 21, 2))
    ax1.grid(True, alpha=0.3)
    ax1.set_facecolor("#FAFAFA")
    # Annotations
    for lvl, lbl in [(1, "Yangi boshlovchi"), (5, "Intiluvchan"),
                     (10, "Tirishqoq"), (15, "Mahoratli"), (20, "Akademik usto")]:
        ax1.annotate(lbl, xy=(lvl, xp[lvl - 1]),
                     xytext=(lvl - 1, xp[lvl - 1] + 1500),
                     fontsize=9, color=C["sub"],
                     arrowprops=dict(arrowstyle="->", color=C["sub"], lw=0.8))

    # Right: Streak bonus
    ax2 = axes[1]
    streak = np.arange(0, 31)
    sb = np.minimum(1.5, 1 + 0.05 * streak)
    ax2.plot(streak, sb, color=C["amber"], linewidth=2.6, marker="o",
             markersize=6, markerfacecolor="white", markeredgewidth=2.0)
    ax2.fill_between(streak, sb, 1.0, alpha=0.20, color=C["amber"])
    ax2.axhline(1.5, color=C["red"], linestyle="--", linewidth=1.4, label="Maksimum (1.5×)")
    ax2.set_title("Streak bonus formulasi: SB(s) = min(1.5, 1 + 0.05·s)", fontsize=14, fontweight="bold")
    ax2.set_xlabel("Streak (kun)", fontsize=11)
    ax2.set_ylabel("Bonus koeffitsienti", fontsize=11)
    ax2.set_ylim(1.0, 1.6); ax2.grid(True, alpha=0.3); ax2.legend(loc="lower right")
    ax2.set_facecolor("#FAFAFA")

    plt.tight_layout()
    save(f, "05-xp-streak-charts.png")


# ── 06: User flow circle ───────────────────────────────────────────────
def d06_user_flow():
    f, ax = fig(11, 11)
    cx, cy, R = 50, 50, 28
    ax.add_patch(plt.Circle((cx, cy), 12, color=C["indigo"], alpha=0.92, zorder=2))
    ax.add_patch(plt.Circle((cx, cy), 38, fill=False, color=C["sub"], lw=0.8, linestyle=(0, (4, 4)), zorder=1))

    items = [
        ("1. Vazifa\ntanlash",      "MVF algoritmi\nkunlik 5 ta\nvazifani tanlaydi",          C["indigo"], 90),
        ("2. Bajarish",              "Foydalanuvchi\nvazifani bajaradi\n(timer + UI)",          C["purple"], 30),
        ("3. XP mukofot",            "Qiyinlik × Streak\nbonusi asosida\nXP beriladi",          C["amber"], -30),
        ("4. Daraja\no'sishi",       "XP yetarli bo'lsa,\ndaraja ko'tariladi\n(1→20)",          C["emerald"], -90),
        ("5. Yutuq va\nnishon",      "8 kategoriyadan\nbirida yutuqqa\nega bo'lish",            C["pink"], -150),
        ("6. Reyting va\nraqobat",   "Global va haftalik\nreytingda o'rin\negallaydi",          C["sky"], 150),
    ]
    pts = []
    for i, (title, desc, col, deg) in enumerate(items):
        rad = math.radians(deg)
        x = cx + R * math.cos(rad) - 9
        y = cy + R * math.sin(rad) - 5
        box(ax, x, y, 18, 11, color=col, fill="white", radius=0.10, lw=2.0)
        ax.text(x + 9, y + 8.5, title, ha="center", va="center",
                color=col, fontsize=10, fontweight="bold")
        ax.text(x + 9, y + 4, desc, ha="center", va="center",
                color=C["txt"], fontsize=8.5)
        pts.append((x + 9, y + 5.5, col))
    # arrows around
    for i in range(len(pts)):
        p, q = pts[i], pts[(i + 1) % len(pts)]
        arrow(ax, (p[0], p[1]), (q[0], q[1]), color=p[2], lw=1.5, rad=-0.18)
    save(f, "06-user-flow.png")


# ── 07: AI chat sequence ───────────────────────────────────────────────
def d07_ai_sequence():
    f, ax = fig(15, 9)
    actors = [
        ("Foydalanuvchi", C["ink"]),
        ("Flutter\nChatProvider", C["indigo"]),
        ("FastAPI\n/ai/chat", C["purple"]),
        ("MongoDB", C["emerald"]),
        ("OpenAI\ngpt-4o-mini", C["red"]),
        ("Gemini\n2.0 Flash", C["amber"]),
        ("Groq\nLlama 70B", C["sky"]),
    ]
    n = len(actors)
    xs = [6 + i * (88 / (n - 1)) for i in range(n)]
    top_y = 90
    for x, (label, col) in zip(xs, actors):
        # Header box
        box(ax, x - 6, top_y - 3, 12, 6, color=col, fill=col, radius=0.12, lw=0)
        ax.text(x, top_y, label, ha="center", va="center",
                color="white", fontsize=10, fontweight="bold")
        # Lifeline
        ax.plot([x, x], [4, top_y - 3], color=col, linestyle="--", linewidth=1.0, alpha=0.5)

    # Steps
    steps = [
        (0, 1, "1. Xabar yozish",                       72, C["ink"]),
        (1, 2, "2. POST /ai/chat + tarix",              68, C["indigo"]),
        (2, 3, "3. User profil olish",                  64, C["purple"]),
        (3, 2, "4. User ma'lumotlari",                  60, C["emerald"]),
    ]
    # Multi-provider rect
    rect = Rectangle((xs[2] - 4, 28), xs[6] - xs[2] + 8, 28,
                     facecolor=tint(C["indigo"], 0.95), edgecolor=C["indigo"],
                     linewidth=1.2, linestyle="--", alpha=0.5, zorder=1)
    ax.add_patch(rect)
    ax.text((xs[2] + xs[6]) / 2, 56, "Multi-provider fallback chain",
            ha="center", va="center", color=C["indigo"], fontsize=11,
            fontstyle="italic", fontweight="bold")

    fallback_steps = [
        (2, 4, "5a. OpenAI so'rov", 50, C["red"]),
        (4, 2, "javob / xato",      46, C["red"]),
        (2, 5, "5b. Gemini fallback", 42, C["amber"]),
        (5, 2, "javob / xato",      38, C["amber"]),
        (2, 6, "5c. Groq fallback", 34, C["sky"]),
        (6, 2, "javob",             30, C["sky"]),
    ]
    after = [
        (2, 3, "6. Chat tarix saqlash", 22, C["purple"]),
        (2, 1, "7. {message, suggested_tasks}", 18, C["purple"]),
        (1, 0, "8. UI bubble + vazifa paneli",  14, C["indigo"]),
        (0, 1, "9. 'Qo'shish' bosish",          10, C["ink"]),
        (1, 2, "10. addSuggestions → plan",      6, C["indigo"]),
    ]

    def step_arrow(i, j, label, y, col):
        x1, x2 = xs[i], xs[j]
        if abs(i - j) > 1:
            ax.annotate("", xy=(x2, y), xytext=(x1, y),
                        arrowprops=dict(arrowstyle="-|>", color=col, lw=1.4,
                                        connectionstyle="arc3,rad=0"))
        else:
            ax.annotate("", xy=(x2, y), xytext=(x1, y),
                        arrowprops=dict(arrowstyle="-|>", color=col, lw=1.4))
        ax.text((x1 + x2) / 2, y + 1, label, ha="center", va="bottom",
                color=col, fontsize=9, fontweight="bold")

    for s in steps + fallback_steps + after:
        step_arrow(*s)
    save(f, "07-ai-chat-sequence.png")


# ── 08: API endpoints ──────────────────────────────────────────────────
def d08_api():
    f, ax = fig(14, 9)
    ax.text(50, 95, "MotivAI RESTful API endpointlar xaritasi",
            ha="center", va="center", fontsize=14, fontweight="bold", color=C["ink"])

    cols = [
        ("/auth", C["indigo"], ["POST /register", "POST /login", "GET /me",
                                 "PUT /profile", "PUT /change-password"]),
        ("/tasks", C["purple"], ["GET /daily", "GET /recommended", "POST /complete",
                                  "POST /from-chat"]),
        ("/ai", C["red"], ["POST /chat", "POST /add-tasks", "GET /motivation-plan",
                           "GET /daily-insight", "GET /achievements"]),
        ("/leaderboard", C["amber"], ["GET /global", "GET /weekly", "GET /user-rank"]),
        ("/progress", C["emerald"], ["GET /weekly", "GET /monthly", "GET /category-breakdown"]),
    ]
    cw = 16
    gap = (100 - len(cols) * cw) / (len(cols) + 1)
    for i, (name, col, eps) in enumerate(cols):
        x = gap + i * (cw + gap)
        # Header
        box(ax, x, 75, cw, 12, color=col, fill=col, radius=0.10, lw=0)
        ax.text(x + cw/2, 81, name, ha="center", va="center",
                color="white", fontsize=14, fontweight="bold")
        # Endpoints
        for ei, ep in enumerate(eps):
            y = 70 - ei * 7
            box(ax, x, y, cw, 5.5, color=col, fill=tint(col, 0.92), radius=0.18, lw=1.0, shadow=False)
            ax.text(x + cw/2, y + 2.75, ep, ha="center", va="center",
                    fontsize=9, color=col, family="monospace", fontweight="bold")

    # Bottom meta
    box(ax, 6, 8, 88, 12, color=C["slate"], fill="white", radius=0.06, lw=1.6)
    ax.text(50, 16, "Jami: 33 endpoint  •  6 router  •  O'rtacha javob vaqti: 94 ms (AI: 1920 ms)",
            ha="center", va="center", fontsize=12, color=C["ink"], fontweight="bold")
    ax.text(50, 11, "Autentifikatsiya: JWT Bearer (HMAC-SHA256)  •  Validatsiya: Pydantic v2  •  Rate limit: 20/min",
            ha="center", va="center", fontsize=10, color=C["sub"], fontstyle="italic")
    save(f, "08-api-endpoints.png")


# ── 09: Widget tree ────────────────────────────────────────────────────
def d09_widget_tree():
    f, ax = fig(14, 10)
    ax.text(50, 96, "MotivAI Flutter ilovasining widget daraxti (Widget Tree)",
            ha="center", va="center", fontsize=14, fontweight="bold", color=C["ink"])

    box(ax, 40, 84, 20, 6, color=C["indigo"], fill=C["indigo"], radius=0.18, lw=0)
    ax.text(50, 87, "MaterialApp", ha="center", va="center",
            color="white", fontsize=12, fontweight="bold")

    box(ax, 35, 73, 30, 6, color=C["purple"], fill=C["purple"], radius=0.18, lw=0)
    ax.text(50, 76, "MultiProvider", ha="center", va="center",
            color="white", fontsize=12, fontweight="bold")

    arrow(ax, (50, 84), (50, 79), color=C["sub"], lw=1.4)

    # 3 providers
    providers = [("AuthProvider", C["pink"], 12),
                 ("TaskProvider", C["amber"], 40),
                 ("ChatProvider", C["emerald"], 68)]
    for name, col, x in providers:
        box(ax, x, 60, 20, 6, color=col, fill="white", radius=0.18, lw=2.0)
        ax.text(x + 10, 63, name, ha="center", va="center",
                color=col, fontsize=11, fontweight="bold")
        arrow(ax, (50, 73), (x + 10, 66), color=C["sub"], lw=1.0, rad=-0.05)

    # Consumer
    box(ax, 30, 47, 40, 6, color=C["slate"], fill="white", radius=0.10, lw=1.6)
    ax.text(50, 50, "Consumer<AuthProvider>", ha="center", va="center",
            color=C["txt"], fontsize=11, fontweight="bold")
    arrow(ax, (22, 60), (40, 53), color=C["sub"], lw=1.0, rad=-0.10)

    # Login / Shell
    box(ax, 14, 34, 26, 7, color=C["red"], fill=tint(C["red"], 0.92), radius=0.10, lw=1.6)
    ax.text(27, 37.5, "LoginScreen (token yo'q)", ha="center", va="center",
            color=C["red"], fontsize=10, fontweight="bold")
    box(ax, 60, 34, 26, 7, color=C["emerald"], fill=tint(C["emerald"], 0.92), radius=0.10, lw=1.6)
    ax.text(73, 37.5, "MainShell (token mavjud)", ha="center", va="center",
            color=C["emerald_d"], fontsize=10, fontweight="bold")
    arrow(ax, (45, 47), (33, 41), color=C["sub"], lw=1.2, rad=-0.10)
    arrow(ax, (55, 47), (67, 41), color=C["sub"], lw=1.2, rad=0.10)

    # IndexedStack
    box(ax, 30, 22, 40, 6, color=C["indigo"], fill="white", radius=0.10, lw=2.0)
    ax.text(50, 25, "IndexedStack (5 ekran)", ha="center", va="center",
            color=C["indigo"], fontsize=11, fontweight="bold")
    arrow(ax, (73, 34), (50, 28), color=C["sub"], lw=1.2, rad=-0.10)

    # 5 screens
    screens = ["Dashboard", "AI Chat", "Leaderboard", "Progress", "Profile"]
    for i, s in enumerate(screens):
        x = 6 + i * 18
        box(ax, x, 11, 16, 6, color=C["indigo"], fill=tint(C["indigo"], 0.94), radius=0.12, lw=1.0, shadow=False)
        ax.text(x + 8, 14, s, ha="center", va="center",
                color=C["indigo"], fontsize=10, fontweight="bold")
        arrow(ax, (50, 22), (x + 8, 17), color=C["sub"], lw=0.7, rad=-0.05)

    box(ax, 20, 2, 60, 5, color=C["slate"], fill=tint(C["slate"], 0.95), radius=0.20, lw=1.0, shadow=False)
    ax.text(50, 4.5, "BottomNavigationBar (5 ta tab)",
            ha="center", va="center", color=C["txt"], fontsize=10, fontstyle="italic")
    save(f, "09-widget-tree.png")


# ── 10: Deployment ─────────────────────────────────────────────────────
def d10_deploy():
    f, ax = fig(14, 8)
    ax.text(50, 95, "MotivAI deployment infratuzilmasi",
            ha="center", va="center", fontsize=14, fontweight="bold", color=C["ink"])

    nodes = [
        ("RIVOJLANISH", ["Developer (Samandar)", "Flutter + VS Code", "Python 3.11 + FastAPI", "Local MongoDB"], 4, 60, C["indigo"]),
        ("GITHUB", ["Version Control", "GitHub Actions", "Automated Tests", "Pull Request Review"], 28, 60, C["ink"]),
        ("RENDER.COM", ["Backend Hosting", "FastAPI + Uvicorn", "Auto HTTPS (Let's Encrypt)", "Auto Deploy on Push"], 52, 60, C["emerald"]),
        ("MONGODB ATLAS", ["M0 Free Tier", "Singapore Region", "512 MB + Auto Backup", "IP Whitelist"], 76, 60, C["emerald_d"]),
    ]
    for name, items, x, y, col in nodes:
        box(ax, x, y, 20, 24, color=col, fill="white", radius=0.06, lw=2.0)
        ax.text(x + 10, y + 21, name, ha="center", va="center",
                color=col, fontsize=12, fontweight="bold")
        for i, it in enumerate(items):
            ax.text(x + 10, y + 16 - i * 3.6, it, ha="center", va="center",
                    color=C["txt"], fontsize=9)

    # Arrows
    ax.annotate("", xy=(28, 72), xytext=(24, 72),
                arrowprops=dict(arrowstyle="-|>", color=C["ink"], lw=1.6))
    ax.text(26, 75, "git push", ha="center", color=C["ink"],
            fontsize=9, fontweight="bold", fontstyle="italic")
    ax.annotate("", xy=(52, 72), xytext=(48, 72),
                arrowprops=dict(arrowstyle="-|>", color=C["emerald"], lw=1.6))
    ax.text(50, 75, "Webhook", ha="center", color=C["emerald_d"],
            fontsize=9, fontweight="bold", fontstyle="italic")

    # Users
    box(ax, 6, 22, 24, 14, color=C["amber"], fill="white", radius=0.08, lw=2.0)
    ax.text(18, 32, "FOYDALANUVCHILAR", ha="center", color=C["amber"],
            fontsize=11, fontweight="bold")
    ax.text(18, 28, "iOS (iPhone/iPad)", ha="center", color=C["txt"], fontsize=9)
    ax.text(18, 25.5, "Android (telefon/planshet)", ha="center", color=C["txt"], fontsize=9)
    ax.text(18, 23, "Flutter kompilyatsiya", ha="center", color=C["txt"], fontsize=9)

    # OpenAI external (dashed)
    p = FancyBboxPatch((50, 22), 26, 14,
                       boxstyle="round,pad=0,rounding_size=0.4",
                       linewidth=1.6, edgecolor=C["red"], facecolor=tint(C["red"], 0.94),
                       linestyle="dashed", zorder=2)
    ax.add_patch(p)
    ax.text(63, 32, "OpenAI / Gemini / Groq API",
            ha="center", color=C["red"], fontsize=11, fontweight="bold")
    ax.text(63, 27.5, "Tashqi xizmatlar — AI chat\nMulti-provider fallback",
            ha="center", color=C["txt"], fontsize=9)

    # User → Render
    a = FancyArrowPatch((30, 32), (52, 60), arrowstyle="-|>", mutation_scale=18,
                        color=C["slate"], linewidth=1.5,
                        connectionstyle="arc3,rad=-0.25", zorder=4)
    ax.add_patch(a)
    ax.text(40, 50, "HTTPS REST API\n(JWT)", ha="center", color=C["slate"],
            fontsize=9, fontstyle="italic",
            bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="none"))

    # Render → OpenAI
    a2 = FancyArrowPatch((62, 60), (63, 36), arrowstyle="-|>", mutation_scale=14,
                         color=C["red"], linewidth=1.4, linestyle="--",
                         connectionstyle="arc3,rad=0.18", zorder=4)
    ax.add_patch(a2)

    save(f, "10-deployment.png")


# ── 11: Subjects pie ───────────────────────────────────────────────────
def d11_pie():
    f, ax = plt.subplots(figsize=(11, 9))
    f.patch.set_facecolor("white")
    labels = ["Matematika", "Informatika", "Ingliz tili", "Fizika",
              "Biologiya", "Tarix", "Kimyo", "Iqtisodiyot"]
    sizes = [23, 19, 17, 11, 10, 8, 7, 5]
    colors = [C["indigo"], C["purple"], C["amber"], C["emerald"],
              C["sky"], C["pink"], C["red"], C["emerald_d"]]
    wedges, texts, autotexts = ax.pie(
        sizes, labels=labels, colors=colors, startangle=90,
        autopct="%1.1f%%", pctdistance=0.72,
        wedgeprops=dict(edgecolor="white", linewidth=2),
        textprops={"fontsize": 13, "fontweight": "bold"},
    )
    for t in autotexts:
        t.set_color("white")
        t.set_fontsize(12)
        t.set_fontweight("bold")
    for t in texts:
        t.set_color(C["txt"])
    ax.set_title("Foydalanuvchi qiziqishlari — fanlar bo'yicha taqsimot (n=15)",
                 fontsize=14, fontweight="bold", pad=20)
    plt.tight_layout()
    save(f, "11-subjects-pie.png")


# ── 12: Metrics bars ───────────────────────────────────────────────────
def d12_metrics():
    f, axes = plt.subplots(1, 2, figsize=(15, 7))
    f.patch.set_facecolor("white")

    # Left: daily access
    days = ["1-kun", "2-kun", "3-kun", "4-kun", "5-kun", "6-kun", "7-kun"]
    vals = [2.1, 3.4, 3.9, 4.2, 3.8, 4.1, 3.8]
    colors = [C["amber"]] + [C["indigo"]] * 6
    ax1 = axes[0]
    bars = ax1.bar(days, vals, color=colors, edgecolor="white", linewidth=2)
    for b, v in zip(bars, vals):
        ax1.text(b.get_x() + b.get_width()/2, v + 0.1, f"{v}",
                 ha="center", fontsize=11, fontweight="bold", color=C["txt"])
    ax1.axhline(2, color=C["red"], linestyle="--", linewidth=1.6,
                label="Soha standarti (≥ 2/kun)")
    ax1.set_title("Kunlik ilovaga kirish chastotasi (n=15, 7 kun)",
                  fontsize=14, fontweight="bold")
    ax1.set_ylabel("O'rtacha kirish soni", fontsize=11)
    ax1.set_ylim(0, 5.2)
    ax1.legend(loc="upper left")
    ax1.grid(True, axis="y", alpha=0.3)
    ax1.set_facecolor("#FAFAFA")

    # Right: KPIs
    cats = ["SUS\nbali", "NPS\n(Net Promoter)", "Ilovani\no'rganish",
            "Bajarish\nfoizi", "AI chat\nfoydaliligi"]
    motivai = [79.4, 42, 58, 67, 81]
    standard = [68, 30, 58, 50, 70]
    x = np.arange(len(cats))
    w = 0.36
    ax2 = axes[1]
    b1 = ax2.bar(x - w/2, motivai, w, color=C["emerald"], edgecolor="white", linewidth=2, label="MotivAI natija")
    b2 = ax2.bar(x + w/2, standard, w, color=C["slate"], alpha=0.55, edgecolor="white", linewidth=2, label="Soha standarti")
    for b, v in zip(b1, motivai):
        ax2.text(b.get_x() + b.get_width()/2, v + 1.2, f"{v}",
                 ha="center", fontsize=10, fontweight="bold", color=C["txt"])
    for b, v in zip(b2, standard):
        ax2.text(b.get_x() + b.get_width()/2, v + 1.2, f"{v}",
                 ha="center", fontsize=9, color=C["sub"])
    ax2.set_xticks(x); ax2.set_xticklabels(cats, fontsize=10)
    ax2.set_title("MotivAI sinov ko'rsatkichlari vs soha standarti",
                  fontsize=14, fontweight="bold")
    ax2.set_ylabel("Ko'rsatkich qiymati", fontsize=11)
    ax2.set_ylim(0, 95)
    ax2.legend(loc="upper right")
    ax2.grid(True, axis="y", alpha=0.3)
    ax2.set_facecolor("#FAFAFA")

    plt.tight_layout()
    save(f, "12-metrics-bar.png")


# ── Run all ────────────────────────────────────────────────────────────
def main():
    fns = [d01_architecture, d02_levels, d03_schema, d04_mvf,
           d05_xp_streak, d06_user_flow, d07_ai_sequence, d08_api,
           d09_widget_tree, d10_deploy, d11_pie, d12_metrics]
    for fn in fns:
        print(f"  rendering {fn.__name__} ...")
        fn()
    print(f"\nDone. {len(fns)} PNGs in {OUT}")


if __name__ == "__main__":
    main()
