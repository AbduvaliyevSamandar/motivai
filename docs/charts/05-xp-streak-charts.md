# XP Darajalar Egri Chizig'i va Streak Bonus Formulasi

## XP Talab Qiluvchi Daraja (1–20)

```mermaid
xychart-beta
    title "MotivAI darajalar tizimi (1-20)"
    x-axis "Daraja (Level)" [1, 3, 5, 7, 9, 11, 13, 15, 17, 19]
    y-axis "Talab qilinadigan umumiy XP" 0 --> 22000
    line [0, 600, 1700, 3200, 5200, 7700, 10000, 13100, 16300, 20000]
```

**Daraja nomlari:**
- Level 1 — Yangi boshlovchi (0 XP)
- Level 5 — Intiluvchan (~1700 XP)
- Level 10 — Tirishqoq (~6300 XP)
- Level 15 — Mahoratli (~13100 XP)
- Level 20 — Akademik usto (~22000 XP)

---

## Streak Bonus Koeffitsienti

**Formula:** `SB(s) = min(1.5, 1 + 0.05·s)`

```mermaid
xychart-beta
    title "Streak bonus formulasi"
    x-axis "Streak (kun)" [0, 5, 10, 15, 20, 25, 30]
    y-axis "Bonus koeffitsienti" 1.0 --> 1.6
    line [1.0, 1.25, 1.5, 1.5, 1.5, 1.5, 1.5]
```

- 0–10 kun: chiziqli o'sish (1.0 → 1.5x)
- 10+ kun: maksimum 1.5x da to'xtaydi
