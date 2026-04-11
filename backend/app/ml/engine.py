import random

DAILY_TASKS = {
    "morning": [
        {"id": "t01", "emoji": "🌅", "title": "Ertalabki meditatsiya",  "desc": "10 daqiqa nafas mashqi",         "points": 50,  "duration": 10},
        {"id": "t02", "emoji": "📖", "title": "Kitob oqish",            "desc": "30 daqiqa kitob ochi",           "points": 100, "duration": 30},
        {"id": "t03", "emoji": "🏃", "title": "Sport mashqi",           "desc": "20 daqiqa yugurish",             "points": 80,  "duration": 20},
        {"id": "t04", "emoji": "✍️", "title": "Kunlik maqsad yozish",   "desc": "Bugungi 3 maqsadni yoz",         "points": 30,  "duration": 5},
        {"id": "t05", "emoji": "🥗", "title": "Soghlom nonushta",       "desc": "Togri ovqatlan",                 "points": 40,  "duration": 15},
    ],
    "afternoon": [
        {"id": "t06", "emoji": "💻", "title": "Loyiha ustida ishlash",  "desc": "1 soat kurs loyihang",           "points": 150, "duration": 60},
        {"id": "t07", "emoji": "📝", "title": "Konspekt yozish",        "desc": "Bugungi darslarni qayta yoz",    "points": 120, "duration": 45},
        {"id": "t08", "emoji": "🤝", "title": "Guruh muhokamasi",       "desc": "Dostlar bilan muhokama",         "points": 70,  "duration": 30},
        {"id": "t09", "emoji": "🔍", "title": "Mustaqil tadqiqot",      "desc": "Bir mavzuni chuqur organ",       "points": 130, "duration": 45},
    ],
    "evening": [
        {"id": "t10", "emoji": "🎯", "title": "Flashcard takrorlash",   "desc": "Anki bilan takrorlash",          "points": 90,  "duration": 20},
        {"id": "t11", "emoji": "📊", "title": "Kunlik tahlil",          "desc": "Bugun nima organdim?",           "points": 40,  "duration": 10},
        {"id": "t12", "emoji": "🌙", "title": "Ertangi reja",           "desc": "Ertangi 3 vazifani belgilab qoy","points": 35,  "duration": 5},
        {"id": "t13", "emoji": "📚", "title": "Uy vazifasi",            "desc": "Barcha uy vazifalarni bajaring", "points": 120, "duration": 60},
    ],
    "night": [
        {"id": "t14", "emoji": "📵", "title": "Screen-free soat",       "desc": "1 soat telefonsiz",              "points": 100, "duration": 60},
        {"id": "t15", "emoji": "📔", "title": "Jurnal yozish",          "desc": "Bugungi hissiyotlarni yoz",      "points": 60,  "duration": 15},
        {"id": "t16", "emoji": "🧘", "title": "Uxlash meditatsiyasi",   "desc": "Tinch uxlash uchun nafas",       "points": 50,  "duration": 10},
    ],
}

CHALLENGES = [
    {"id": "c01", "emoji": "🔥", "title": "7 kunlik Streak",     "desc": "7 kun uzluksiz vazifalarni bajaring", "points": 500,  "days": 7},
    {"id": "c02", "emoji": "📚", "title": "30 soat oqish",       "desc": "Bir oyda 30 soat oqish",             "points": 1000, "days": 30},
    {"id": "c03", "emoji": "💪", "title": "Sport Champion",      "desc": "2 hafta har kuni sport qiling",      "points": 700,  "days": 14},
    {"id": "c04", "emoji": "🧘", "title": "Stress-Free Hafta",   "desc": "7 kun meditatsiya qiling",           "points": 400,  "days": 7},
    {"id": "c05", "emoji": "⭐", "title": "Perfect Attendance",  "desc": "Bir oy barcha darslarga boring",     "points": 1500, "days": 30},
]

QUOTES = {
    "critical": ["Hamma qiyin davrdan otadi. Bugun bitta kichik qadam qoy!", "Eng uzun sayohat bitta qadam bilan boshlanadi."],
    "low":      ["Sen togri yoldassan! Har kuni 1% yaxshilan.", "Qiyin kunlar seni kuchliroq qiladi. Davom et!"],
    "medium":   ["Ajoyib ketayapsan! Shu tempni saqla!", "Maqsadingga har kuni bir qadam yaqinlashyapsan!"],
    "high":     ["Sen bir istisnosan! Bugun ham ozingdan otib ket!", "Bunday energiya bilan hech narsa imkonsiz emas!"],
}


def get_motivation_quote(level: int) -> str:
    key = "critical" if level <= 3 else "low" if level <= 5 else "medium" if level <= 7 else "high"
    return random.choice(QUOTES[key])


def get_tasks_for_user(preferred_time: str) -> list:
    main  = DAILY_TASKS.get(preferred_time, DAILY_TASKS["morning"])
    extra = [tasks[0] for t, tasks in DAILY_TASKS.items() if t != preferred_time]
    return main + extra[:2]


def analyze_and_recommend(user_data: dict) -> dict:
    motivation = int(user_data.get("motivation_level", 5))
    stress     = int(user_data.get("stress_level",     5))
    mood       = int(user_data.get("mood_score",        5))
    energy     = int(user_data.get("energy_level",      5))
    gpa        = float(user_data.get("gpa",               3.0))
    sleep      = float(user_data.get("sleep_hours",       7.0))
    study      = float(user_data.get("daily_study_hours", 3.0))
    streak     = int(user_data.get("streak_days",       0))
    ptime      = str(user_data.get("preferred_time",    "morning"))

    wellness = round((motivation + (10 - stress) + mood + energy) / 4, 1)

    improvements = []
    if stress >= 7:
        improvements.append({"area": "stress", "priority": "high",   "title": "Stress juda yuqori!", "tip": "4-7-8 nafas texnikasini sinab koring."})
    if sleep < 6:
        improvements.append({"area": "sleep",  "priority": "high",   "title": "Uyqu juda kam!",      "tip": f"Hozir {sleep:.0f} soat uxlayapsiz. Kamida 7-8 soat kerak."})
    elif sleep < 7:
        improvements.append({"area": "sleep",  "priority": "medium", "title": "Uyqu biroz kam",      "tip": "7-8 soat uxlashga harakat qiling."})
    if study < 2:
        improvements.append({"area": "study",  "priority": "high",   "title": "Oqish vaqti kam!",    "tip": "Kuniga kamida 2-3 soat sifatli oqish zarur."})
    if gpa < 2.5:
        improvements.append({"area": "gpa",    "priority": "high",   "title": "GPA past",            "tip": "Professor bilan konsultatsiyaga boring."})
    if mood <= 3:
        improvements.append({"area": "mood",   "priority": "medium", "title": "Kayfiyat past",       "tip": "Sevimli taom, muzika yoki dost bilan suhbat."})
    if streak == 0:
        improvements.append({"area": "streak", "priority": "low",    "title": "Streak yoq",          "tip": "Bugun bitta vazifani bajaring va streakni boshlang!"})

    if wellness >= 8:   summary = f"Bugun siz chooqqidasiz! Motivatsiya {motivation}/10."
    elif wellness >= 6: summary = f"Yaxshi holatsiz! Motivatsiya {motivation}/10."
    elif wellness >= 4: summary = f"Normal kun. Stress {stress}/10 biroz kop."
    else:               summary = f"Bugun ogir kun. Ozingizga mehribon boling."

    return {
        "wellness_score":         wellness,
        "motivational_quote":     get_motivation_quote(motivation),
        "improvements":           improvements[:4],
        "daily_tasks":            get_tasks_for_user(ptime),
        "recommended_challenges": CHALLENGES[:3],
        "ai_summary":             summary,
    }
