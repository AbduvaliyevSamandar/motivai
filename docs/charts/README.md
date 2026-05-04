# MotivAI — Diplom Loyiha Diagrammalari

Bu papkada diplom loyihasidagi 12 ta rasm Mermaid formatida qayta chizilgan.
Har bir `.md` fayli VS Code'da preview qilinganda chiroyli render bo'ladi
(`Ctrl+Shift+V`). Yoki to'g'ridan-to'g'ri GitHub'da ko'rsatish mumkin —
GitHub mermaid blok'larni avtomatik chizadi.

## Diagrammalar ro'yxati

| # | Fayl | Mavzu |
|---|---|---|
| 1 | [01-architecture.md](./01-architecture.md) | 3-pog'onali arxitektura (Flutter / FastAPI / MongoDB) |
| 2 | [02-gamification-levels.md](./02-gamification-levels.md) | Foydalanuvchining 5 ta darajasi |
| 3 | [03-database-schema.md](./03-database-schema.md) | MongoDB ER sxemasi (5 ta kolleksiya) |
| 4 | [04-mvf-formula.md](./04-mvf-formula.md) | MVF — to'rt komponentli gibrid model |
| 5 | [05-xp-streak-charts.md](./05-xp-streak-charts.md) | XP egri chizig'i + streak bonus |
| 6 | [06-user-flow.md](./06-user-flow.md) | Foydalanuvchi tajriba tsikli (6 fasl) |
| 7 | [07-ai-chat-sequence.md](./07-ai-chat-sequence.md) | AI chat — sequence diagram |
| 8 | [08-api-endpoints.md](./08-api-endpoints.md) | RESTful API endpoint xaritasi |
| 9 | [09-widget-tree.md](./09-widget-tree.md) | Flutter widget daraxti |
| 10 | [10-deployment.md](./10-deployment.md) | Deployment infratuzilmasi |
| 11 | [11-subjects-pie.md](./11-subjects-pie.md) | Fanlar bo'yicha foydalanuvchi taqsimoti |
| 12 | [12-metrics-bar.md](./12-metrics-bar.md) | UX va kirish chastotasi ko'rsatkichlari |

## Tayyor PNG fayllar (Word/LaTeX uchun)

`docs/charts/png/` papkada **matplotlib bilan chizilgan yuqori sifatli
PNG'lar** turibdi (DPI 220, ~150-235 KB har biri). Diplom Word fayliga
to'g'ridan-to'g'ri vstavka qiling:

| # | PNG | Mermaid manba |
|---|---|---|
| 1 | [01-architecture.png](./png/01-architecture.png) | [01-architecture.md](./01-architecture.md) |
| 2 | [02-gamification-levels.png](./png/02-gamification-levels.png) | [02-gamification-levels.md](./02-gamification-levels.md) |
| 3 | [03-database-schema.png](./png/03-database-schema.png) | [03-database-schema.md](./03-database-schema.md) |
| 4 | [04-mvf-formula.png](./png/04-mvf-formula.png) | [04-mvf-formula.md](./04-mvf-formula.md) |
| 5 | [05-xp-streak-charts.png](./png/05-xp-streak-charts.png) | [05-xp-streak-charts.md](./05-xp-streak-charts.md) |
| 6 | [06-user-flow.png](./png/06-user-flow.png) | [06-user-flow.md](./06-user-flow.md) |
| 7 | [07-ai-chat-sequence.png](./png/07-ai-chat-sequence.png) | [07-ai-chat-sequence.md](./07-ai-chat-sequence.md) |
| 8 | [08-api-endpoints.png](./png/08-api-endpoints.png) | [08-api-endpoints.md](./08-api-endpoints.md) |
| 9 | [09-widget-tree.png](./png/09-widget-tree.png) | [09-widget-tree.md](./09-widget-tree.md) |
| 10 | [10-deployment.png](./png/10-deployment.png) | [10-deployment.md](./10-deployment.md) |
| 11 | [11-subjects-pie.png](./png/11-subjects-pie.png) | [11-subjects-pie.md](./11-subjects-pie.md) |
| 12 | [12-metrics-bar.png](./png/12-metrics-bar.png) | [12-metrics-bar.md](./12-metrics-bar.md) |

Qayta chizish kerak bo'lsa: `python scripts/build_diagrams.py` — barcha
12 ta PNG yangilanadi (matplotlib bilan, DPI 220).

## Mermaid versiyalari

Mermaid `.md` fayllari saqlanadi — GitHub'da avtomatik render bo'ladi
(repo'da `docs/charts/01-...md` ni oching), VS Code preview (Ctrl+Shift+V)
da ko'rinadi. Tahrir qilish kerak bo'lsa mermaid kodga to'g'ridan-to'g'ri
o'zgartiring va [mermaid.live](https://mermaid.live) da preview qiling.
