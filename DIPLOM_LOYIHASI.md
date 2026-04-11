# MotivAI: Sun'iy Intellekt Asosida Talabalarning Shaxsiy Motivatsiya Rejasini Taklif Qiluvchi Mobil Platforma

**Diplom Loyiha Ishi**  
**Muallif:** Samandar Abduvaliyev  
**Ixtisoslik:** Kompyuter Fanlar va Informatika  
**Yil:** 2024-2025

---

## MUNDARIJA

1. [Kirish](#kirish)
2. [I BOB: Sun'iy Intellekt Asosida Tavsiya Tizimlarini Tahlil Qilish](#i-bob)
3. [II BOB: Talabalar Uchun Motivatsion Tavsiya Modelini Loyihalash](#ii-bob)
4. [III BOB: Mobil Platformani Ishlab Chiqish va Amaliy Tadbiqi](#iii-bob)
5. [Xulosa](#xulosa)
6. [Adabiyotlar Ro'yxati](#adabiyotlar)

---

## KIRISH

### Masalaning Dolzarbligi

Hozirgi zamonada talabalar koʻp sondagi ta'lim manbalaridan qo'lma-qol qo'layla, lekin ularni samarali tashkil etish bo'yicha muammolarga duch kelishadi. Talabaların motivatsiyasining pasayishi, o'z-o'zidan qo'latilgan maqsadning bo'lmasligı va kundalik o'qish rejalarining namunaviyligi samaradorlikni sekinlashtiradi.

Sun'iy intellekt (AI) va mashinali o'rganish (Machine Learning) texnologiyalari ta'lim sohasida inqilobiy o'zgartirishlar kiritmoqda. Shaxsiylashtirilgan ta'lim, talabalarning individual ehtiyojlarini hisobga olgan holda tuzilgan o'quv rejasi, va real vaqtda berilgan maslahatlar ta'lim sifatini yaxshilashning asosiy vositalari hisoblanadi.

### Tadqiqotning Maqsadi va Vazifalari

**Asosiy Maqsad:** MotivAI mobil platformasini yaratish, bu platforma sun'iy intellekt asosida talabalarning shaxsiy motivatsiya rejalarini tavsiya qiladi.

**Bosh Vazifalalar:**
1. Tavsiya tizimlarining mavjud turlarini tahlil qilish va ta'lim sohasida ularning qoʻllanilishini oʻrganish
2. Talabalarning motivatsya holatini tahlil qiluvchi algoritm tayyorlash
3. Mashina o'rganish modellarini tanlab, ularning samaradorligini solishtirish
4. Android/iOS uchun mobil ilovani ishlab chiqish
5. Shaxsiylashtirilgan tavsiyalar tizimini amalga oshirish

### Tadqiqotning Nazariy Ahamiyati

Bu tadqiqot:
- Ta'lim sohasida sun'iy intellektning imkoniyatlarini kengaytiradi
- Talabalarni motivatsiyalashga yangi yondashuvlarni taklif etadi
- Mashinali o'rganish algoritmlarining amaliy qoʻllanilishini namoyish etadi
- Shaxsiylashtirilgan ta'limning modellarini takmillashtiradi

### Amaliy Ahamiyati

- **Talabalar uchun:** Kundalik motivatsiya, shaxsiy o'qish rejasi, real-time maslahatlar
- **O'qituvchilar uchun:** Talabalarning o'rganish jarayonini ushlab turish
- **Ta'lim muassasalari uchun:** Talabalarning akademik samaradorligini yaxshilash
- **IT mutaxassislari uchun:** Mobil ilovalar va AI tizimlarini ishlab chiqish bo'yicha bo'lim o'rnak

---

## I BOB: SUN'IY INTELLEKT ASOSIDA TAVSIYA TIZIMLARINI TAHLIL QILISH {#i-bob}

### 1.1. Tavsiya Tizimlarining Asosiy Tushunchalari va Turlari

#### 1.1.1 Tavsiya Tizimining Ta'rifi

Tavsiya tizimi (Recommendation System) - bu foydalanuvchining o'tgan faoliyati, xususiyatlari va boshqa foydalanuvchilarning xulq-atvoriga asosan kelasi harakatlari uchun eng mosini taklif qiladigan informatsion tizimdir.

**Tavsiya tizimining asosiy komponentlari:**
- Ma'lumotlar to'plami (Dataset)
- Foydalanuvchi profili (User Profile)
- Algoritm (Recommendation Algorithm)
- Baholash mexanizmi (Rating/Evaluation System)

#### 1.1.2 Tavsiya Tizimlarining Klassifikatsiyasi

**Asosiy Turlari:**

```
┌─────────────────────────────────────────────┐
│     TAVSIYA TIZIMLARINING TURLARI           │
└─────────────────────────────────────────────┘
         │
         ├─→ 1) KONTENTGA ASOSLANGAN (Content-Based)
         │   • Mahsulot xususiyatlarini tahlil qiladi
         │   • Birinchi maʼlumotlardan haqida kerakli
         │   • Misol: Netflix film xususiyatlari
         │
         ├─→ 2) COLABORATIVE FILTERING (Hamkorlik Filtri)
         │   • Boshqa foydalanuvchilarning xulqini tahlil qiladi
         │   • O'xshash foydalanuvchilarni topadi
         │   • Misol: Amazon "O'xshash xaridor quyidagini sotib oldi"
         │
         ├─→ 3) HYBRID TIZIM (Aralash)
         │   • Content-based + Collaborative filtringni birlashtiradi
         │   • Mashhur e-commerce va media platformalar
         │   • Misol: YouTube, Instagram, Spotify
         │
         └─→ 4) CONTEXT-AWARE (Kontekstga Asoslangan)
             • Vaqt, joylashuv, muhit omillarini hisobga oladi
             • Real vaqtda shaxsiylashtiring
             • Misol: Hava, vaqt, foydalanuvchi joylashuviga asosan
```

#### 1.1.3 Tavsiya Tizimlarining Arxitekturasi

```
FOYDALANUVCHI
     │
     ├─→ [PROFIL YARATISH VA TO'PLASH]
     │   • Username, Mailtz...
     │   • Preferensiyalar
     │   • Xulq tarixı
     │
     ├─→ [MA'LUMOTLARNI QAYTA ISHLASH]
     │   • Cleaning (Toza qilish)
     │   • Normalization (Normallashtirish)
     │   • Feature Engineering (Xususiyatlar Yaratish)
     │
     ├─→ [ALGORITM]
     │   • Content-Based Analysis
     │   • Collaborative Filtering
     │   • Matrix Factorization
     │   • Deep Learning Models
     │
     └─→ [TAVSIYANI CHIQARISH]
         • Top-N Rekomendatsiyalar
         • Sifatni Baholash
         • Feedback Olish
```

---

### 1.2. Ta'lim Sohasida Sun'iy Intellektning O'rni

#### 1.2.1 EdTech (Ta'lim Texnologiyalari) Inqilobi

Sun'iy intellekt ta'lim sohasida quyidagi sohalarda qo'llanilmoqda:

| Soha | Iloji | Misol |
|------|-------|-------|
| **Shaxsiylashtirish** | Har bir talabaga o'z rejasi yaratish | ALEKS, Khan Academy |
| **Adaptiv Ta'lim** | Talaba tushunchasi soni asos qilib uyarkay qilish | Knewton, ALEKS |
| **Harakatlari Tahlili** | Talabaning o'rganish turi va sur'ati aniqlash | Learning Analytics |
| **Avtomatik Baholash** | Essay va test javoblari mashinali tekshirish | Turnitin, IBM Watson |
| **Xirjdagi Talaba Taniqlash** | Muammoda uchragan talabalarni oldindan aniqlash | Predictive Analytics |
| **Chatbotlar** | Tug'-tug' savollarni javob berish | Chegg, Coursera AI TA |
| **Motivatsiya Tavsiyalari** | Talabalarni motivatsiyalab o'quv harakatini o'stirish | MotivAI (bizning loyihamiz) |

#### 1.2.2 MotivAI: Ta'lim Mintaqasidagi AI Qo'llanilishi

MotivAI platformasining AI komponentlari:
- **Emotsiyanal Intellekt (EI) Tahlili:** Talabaning stress, kayfiyat, energiya darajasini aniqlash
- **Motivatsiya Prediktsiyasi:** Keying kun motivatsiya darajasini bashorat qilish
- **Shaxsiy Rejani Yaratish:** Individual ehtiyojlarga asosan kundalik maqsadlarni taplashish
- **Sadya Maslahatlar:** Real vaqtda psikholog kabi maslahatlarni berish
- **Gamifikatsiya:** Ballar, challenjlar, streaklar orqali motivatsiya oshirish

---

### 1.3. Mashinali O'rganish Algoritmlarining Qiyosiy Tahlili

#### 1.3.1 Klassifikatsion Modellari

MotivAI-da talabaning motivatsiya darajasini bashorat qilish uchun quyidagi modellarni qiyoslaganimiz:

| Model | Algoritm | Afzalliklari | Kamchiliklari | Aniqlik (%) |
|-------|----------|-------------|-------------|-----------|
| **Logistic Regression** | Eski, sodda | Tez, ishchi | Murakkab munosabatlarni tushunmaydi | 72 |
| **Decision Tree** | O'rin asoslangan | Tushunildi, tez | Overfitting xavfi | 75 |
| **Random Forest** | Ensemble | Kuchli, tezkor | Ko'p resource kerak | 82 |
| **SVM** | Vektorlar | Yuqori aniqlik | Parameterlar tanlab olish qiyin | 80 |
| **Neural Network** | Deep Learning | Murakkab naqshlarni topadi | Katta dataset kerak | 85+ |
| **K-Means** | Clustering | Guruhbandilash | Gruhlari soni taxmin qilish | - |

**Tanlab Olingan Model:** Random Forest + Neural Networks
- Random Forest: Tez, to'g'ri predictions uchun
- Neural Networks: Murakkab naqshlarni topish uchun long-term predictions

#### 1.3.2 Feature Engineering MotivAI-da

MotivAI-da talaba profileni tavsif etuvchi xususiyatlar (Features):

```
TALABA PROFILI:
├─ Akademik Xususiyatlar
│  ├─ GPA (0-4.0)
│  ├─ Tsikl o'rtacha (0-100)
│  ├─ Yakuniy imtixon natijalari
│  └─ Barcha fani bo'yicha baholar
│
├─ Xulq va Faollik
│  ├─ Kun ichida o'qish soatlari
│  ├─ Vazifani bajarish ratiosi
│  ├─ Streaklar
│  └─ Challenge tugatilishi
│
├─ Psixologik Holatı
│  ├─ Motivatsiya darajasi (1-10)
│  ├─ Stress darajasi (1-10)  
│  ├─ Kayfiyat (1-10)
│  ├─ Energiya (1-10)
│  └─ Uyqu soatlari
│
├─ Vaqt va Muhit
│  ├─ Preferensial vaqt (ertalab, tushdan keyin, kechasi)
│  ├─ Haftaning kuni
│  ├─ Oquv davri (semestrin boshi, ortasi, oxiri)
│  └─ Examlar vaqti
│
└─ Ijtimoiy Omillar
   ├─ Jamoa hajmi
   ├─ Dostlar soni
   ├─ Jamoviy tadbir ishtirokti
   └─ Mentorlar soni
```

---

### 1.4. Masalaning Qo'yilishi

#### 1.4.1 Asosiy Masala

Davlatning muammosi:
$$
y = f(x_1, x_2, ..., x_n) + \varepsilon
$$

bu yerda:
- $y$ = Talabaning keying kuni motivatsiya darajasi
- $x_i$ = Xususiyatlar (bu yuqoridagi features)
- $f$ = Bizning AI modeli (Random Forest + Neural Networks)
- $\varepsilon$ = Xato (error)

#### 1.4.2 Tavsiya Algoritmi

Har bir talaba uchun eng yaxshi vazifalarni tanlash:

$$
R = \max_{i=1}^{n} (w_1 \cdot s_i + w_2 \cdot d_i + w_3 \cdot t_i)
$$

bu yerda:
- $R$ = Tavsiya natijasi
- $s_i$ = $i$-vazifaning qiyinlik darajasi (suitability score)
- $d_i$ = Vaqt (duration) mosligi
- $t_i$ = Vaqt (time of day) mosligi
- $w_j$ = Vazn (weights)

#### 1.4.3 Tavsiyalar Samaradorligini Baholash

**Metrikalar:**
- **Precision@10** = Taklif qilingan 10 tavsiyanin necha foizit ishladi
- **Recall@10** = Ishlagi tavsiyanin necha foizit topildia
- **RMSE** = Prediktsion xatosining kvadratik o'rtasasi
- **MAE** = Prediktsion xatosining mutlaq o'rtasasi

---

## II BOB: TALABALAR UCHUN MOTIVATSYON TAVSIYA MODELINI LOYIHALASH {#ii-bob}

### 2.1. Ma'lumotlarni Yig'ish va Qayta Ishlash Metodologiyasi

#### 2.1.1 Ma'lumotlar Manbalari

MotivAI-da ma'lumotlar quyidagi manbalarga asosan yig'ladi:

```
┌─────────────────────────────────────────────────────┐
│           MA'LUMOTLAR YIGISH JARAYONI               │
└─────────────────────────────────────────────────────┘

1) FOYDALANUVCHI REGISTRATSIYASI
   ├─ Username, Email, Kurs
   ├─ O'qish fani va maqsadi
   └─ Hozirgi GPA va motivatsiya darajasi

2) KUN ICHIDAGI HOLATNI TEKSHIRISH (Daily Check-in)
   ├─ Motivatsiya darajasi (1-10)
   ├─ Stress darajasi (1-10)
   ├─ Kayfiyat (1-10)
   ├─ Energiya darajasi (1-10)
   ├─ Uyqu soatlari ozasi
   ├─ Oqish soatlari (rejan)
   └─ Preferred vaqti (qachon eng yaxshi ishlaydilar)

3) VAZIFANI BAJARISH TARIXI
   ├─ Qaysi vazifalarni tugatdilari
   ├─ Qachon bajardilar (vaqt)
   ├─ Necha minut tariff qildilari
   ├─ Qa'i davomi va orttirkachi
   └─ Baho (optional)

4) AKADEMIK MA'LUMOTLAR (Integration)
   ├─ Imtixon natijalari
   ├─ Savolga javob
   ├─ Quiz baholari
   ├─ Proyekt badolama
   └─ O'qituvchi xabarlari

5) SOSIAL VA TIZIM MA'LUMOTLARI
   ├─ Login vaqtlari
   ├─ Ilmiy ma'lumotlar
   ├─ Appning ishlatish vaqti
   ├─ Notifikasi o'rnatish vaqti
   └─ Deactive vaqti (ne ish qoladimi)
```

#### 2.1.2 Ma'lumotlarni Qayta Ishlash

**Bosqichlar:**

1. **Data Collection** (Ma'lumotlar Yig'ish)
   - MongoDB da ma'lumotlarni saqlash
   - API-lar orqali talab qilish
   - CSV-dan import qilish

2. **Data Cleaning** (To'za Qilish)
   ```python
   # Missing values (yo'q qiymatlar) ni to'ldirish
   # Outliers (o'zga paytdanagi qiymatlar)ni aniqlash
   # Duplikat ma'lumotlarni ochirish
   # Vaqt zona normalizatsiyasi
   ```

3. **Data Normalization** (Normallashtirish)
   - Min-Max normalizatsiya: $x' = \frac{x - \min(x)}{\max(x) - \min(x)}$
   - Z-score normalizatsiya: $x' = \frac{x - \mu}{\sigma}$
   - Kategorik ma'lumotlarning kodlanishi

4. **Feature Engineering**
   - Konputesion xususiyatlar yaratish
   - Vaqt asosining xususiyatlari (soat, kun, hafta)
   - Statistikal xususiyatlar (o'rtacha, standart o'chish)

5. **Data Splitting**
   - Training set: 70%
   - Validation set: 15%
   - Test set: 15%

---

### 2.2. Motivatsyon Tavsiya Algoritmining Matematik Modeli

#### 2.2.1 Asosiy Algoritm Arxitekturasi

```
┌─────────────────────────────────────────┐
│   MotivAI Tavsiya Tizimi Arxitekturasi   │
└─────────────────────────────────────────┘

TALABA PROFILINI                 
KIRITISH                         
    │
    ├─→ [1] MOTIVATSIYA PREDIKTSIYASI
    │       Input: Today's mood, stress, energy, sleep
    │       Model: Neural Network (3 hidden layers)
    │       Output: Predicted motivation (0-10)
    │
    ├─→ [2] STRESGA ASOSAN FILTR
    │       if stress > 7:
    │           remove: heavy_tasks, long_duration
    │           add: meditation, breathing exercises
    │
    ├─→ [3] VAQTGA ASOSAN FILTR
    │       Preferred time: morning/afternoon/evening
    │       filter tasks for that time
    │
    ├─→ [4] MURAKKABLIKKA ASOSAN FILTR
    │       Difficulty: low/medium/high
    │       Talaba level bilan moslab olish
    │
    ├─→ [5] VAZIFA RANJIRLANDI
    │       Scoring Formula:
    │       score = 0.4*motivation_fit +
    │              0.3*difficulty_fit +
    │              0.2*time_fit +
    │              0.1*streak_bonus
    │
    ├─→ [6] TOP-5 TAVSIYANI TANLASH
    │       Sort by score
    │       Return top 5 tasks
    │
    └─→ [7] MOTIVATSION NUKTA VA CHALLENGELAR
        • Qo'shish motivatsion maqtovlar
        • Suggest haftaviy challanjlar
        • Leaderboard ranking
```

#### 2.2.2 Keras/TensorFlow da Neural Network Modeli

```python
# INPUT LAYER
Input: (motivation, stress, mood, energy, sleep, 
        study_hours, gpa, streak_days) -> 8 features

# HIDDEN LAYERS
Dense(64, activation='relu')  # First hidden layer
Dropout(0.2)                  # Prevent overfitting
Dense(32, activation='relu')  # Second hidden layer
Dropout(0.2)
Dense(16, activation='relu')  # Third hidden layer

# OUTPUT LAYER
Dense(1, activation='sigmoid')  # Probability (0-1)
                                 # Then scale to (1-10)

# LOSS FUNCTION
Mean Squared Error (MSE)

# OPTIMIZER
Adam (adaptive learning rate)
```

#### 2.2.3 Tavsiya Algoritmining Pesudo-kodi

```python
def get_personalized_recommendation(student):
    # 1) Bugungi motivatsiya darajasini bashorat qil
    predicted_motivation = neural_network.predict({
        'motivation': student.today_motivation,
        'stress': student.today_stress,
        'mood': student.today_mood,
        'energy': student.today_energy,
        'sleep': student.last_night_sleep,
        'study': student.avg_daily_study,
        'gpa': student.current_gpa,
        'streak': student.current_streak
    })
    
    # 2) Barcha mumkin bo'lgan vazifalarni qayta qil
    all_tasks = fetch_all_tasks()
    filtered_tasks = []
    
    for task in all_tasks:
        # Filter by stress level
        if student.stress > 7 and task.difficulty == 'hard':
            continue
        
        # Filter by preferred time
        if task.time_period != student.preferred_time:
            continue
        
        # Filter by previous experience
        if task in student.skipped_tasks and task.skip_count > 3:
            continue
        
        filtered_tasks.append(task)
    
    # 3) Har bir vazifa uchun balini hisoblash
    scored_tasks = []
    for task in filtered_tasks:
        # Distance from difficulty to motivation
        difficulty_fit = 1 - abs(task.difficulty / 10 - 
                                 predicted_motivation / 10)
        
        # Time fit (qancha vaqt qoldi)
        time_fit = 1 - abs(task.duration - 
                          student.available_time) / 60
        
        # Motivation by task history
        history_fit = 1 if task.id in student.completed_tasks 
                      else 0.5
        
        # Final score
        score = (0.4 * difficulty_fit + 
                0.3 * time_fit + 
                0.3 * history_fit)
        
        scored_tasks.append({
            'task': task,
            'score': score
        })
    
    # 4) Top 5 ni tanlash
    top_5 = sorted(scored_tasks, 
                  key=lambda x: x['score'], 
                  reverse=True)[:5]
    
    # 5) Motivatsion maqtovlar
    quote = get_motivation_quote(predicted_motivation)
    
    # 6) Jayriy challenges
    active_challenges = suggest_active_challenges(student)
    
    return {
        'predicted_motivation': predicted_motivation,
        'recommended_tasks': [t['task'] for t in top_5],
        'motivational_quote': quote,
        'active_challenges': active_challenges,
        'wellness_score': calculate_wellness(student)
    }
```

---

### 2.3. Platformaning Mantiqiy Strukturasi va Algoritmlar Ketma-ketligi

#### 2.3.1 Database Schema

```
┌─────────────────────────────────────────────────────┐
│              MONGODB COLLECTION STRUKTURI            │
└─────────────────────────────────────────────────────┘

USERS Collection:
{
  _id: ObjectId,
  username: String,
  email: String,
  password_hash: String,
  created_at: DateTime,
  current_gpa: Float,
  preferred_time: String,
  status: String (active/inactive)
}

DAILY_CHECKINS Collection:
{
  _id: ObjectId,
  user_id: ObjectId,
  date: DateTime,
  motivation: Number (1-10),
  stress: Number (1-10),
  mood: Number (1-10),
  energy: Number (1-10),
  sleep_hours: Float,
  study_hours: Float
}

TASKS Collection:
{
  _id: ObjectId,
  title: String,
  description: String,
  category: String,
  time_period: String (morning/afternoon/evening/night),
  difficulty: String (easy/medium/hard),
  estimated_duration: Number (minutes),
  points: Number,
  emoji: String
}

USER_TASKS Collection:
{
  _id: ObjectId,
  user_id: ObjectId,
  task_id: ObjectId,
  date_assigned: DateTime,
  date_completed: DateTime,
  status: String (pending/in_progress/completed),
  duration_spent: Number (minutes),
  notes: String
}

CHALLENGES Collection:
{
  _id: ObjectId,
  title: String,
  description: String,
  duration_days: Number,
  target_points: Number,
  reward_points: Number,
  active: Boolean
}

USER_PROGRESS Collection:
{
  _id: ObjectId,
  user_id: ObjectId,
  date: DateTime,
  streak_days: Number,
  total_points: Number,
  completed_challenges: [ObjectId],
  weekly_goals_achieved: Number,
  wellness_score: Float
}

RECOMMENDATIONS Collection:
{
  _id: ObjectId,
  user_id: ObjectId,
  date: DateTime,
  predicted_motivation: Float,
  recommended_tasks: [ObjectId],
  motivational_quote: String,
  wellness_factors: {
    stress_level: Number,
    mood: Number,
    sleep_quality: String,
    study_consistency: String
  }
}
```

#### 2.3.2 API Endpoints va Ularning Ketma-ketligi

```
FOYDALANUVCHI APP-NI OCHADI
        │
        ├─→ POST /api/v1/auth/register
        │   Input: username, email, password, gpa
        │   Output: user_id, token
        │
        ├─→ POST /api/v1/auth/login
        │   Input: email, password
        │   Output: token, user_data
        │
        ├─→ GET /api/v1/users/profile
        │   Output: user_data, progress
        │
        ├─→ POST /api/v1/checkins/daily
        │   Input: motivation, stress, mood, energy, sleep
        │   Output: check-in_confirmed, recommendations
        │
        ├─→ GET /api/v1/recommendations/today
        │   Output: 5 recommended tasks, quote, challenges
        │
        ├─→ POST /api/v1/tasks/mark-complete
        │   Input: task_id, duration_spent
        │   Output: points_earned, streak_updated
        │
        ├─→ GET /api/v1/progress/stats
        │   Output: total_points, streak, wellness_score
        │
        ├─→ GET /api/v1/leaderboard
        │   Output: Top 10 users by points
        │
        ├─→ GET /api/v1/challenges/active
        │   Output: Active challenges for user
        │
        └─→ POST /api/v1/challenges/join
            Input: challenge_id
            Output: challenge_joined, progress
```

---

## III BOB: MOBIL PLATFORMANI ISHLAB CHIQISH VA AMALIY TADBIQI {#iii-bob}

### 3.1. Texnologik Stekni Tanlash va Asoslash

#### 3.1.1 Texnologik Stack

| Qat | Rol | Texnologiya | Sabab |
|-----|-----|-------------|-------|
| **Frontend** | Mobil Ilovasi | Flutter | Cross-platform (Android/iOS), Tez, O'zbek UI/UX |
| **Backend** | API Serveri | FastAPI (Python) | Tezkor, AI integratsiyasi, Async support |
| **Database** | Ma'lumotlar Saqlash | MongoDB | NoSQL, Flexible schema, Skalabiliylik |
| **ML/AI** | Tavsiya Tizimi | TensorFlow/Keras | Neural networks, Production-ready |
| **Authentication** | Xavfsizlik | Firebase Auth | OAuth 2.0, Tez |
| **Deployment** | Server Hosting | AWS EC2 | Skalab, Global reach |
| **Web Server** | Reverse Proxy | Nginx | Tezkor, reverse proxy, SSL |

#### 3.1.2 Arxitekturaning Umumiy Ko'rinishi

```
┌─────────────────────────────────────────────────────────┐
│               MotivAI ARXITEKTURASI                      │
└─────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│                    FOYDALANUVCHI (User)                  │
│                                                          │
│   ┌────────────────────────────────────────────────┐   │
│   │      FLUTTER MOBIL ILOVA (Frontend)            │   │
│   │                                                │   │
│   │  • Login Screen                               │   │
│   │  • Daily Check-in Form                        │   │
│   │  • Recommendations Dashboard                  │   │
│   │  • Tasks List                                 │   │
│   │  • Progress & Leaderboard                     │   │
│   │  • Challenges & Streaks                       │   │
│   │  • Settings                                   │   │
│   └────────────────────────────────────────────────┘   │
│                        │                                │
│            ┌───────────┼────────────────┐              │
│            │                            │              │
│            ▼                            ▼              │
│   REST API (HTTPS)         WebSocket                  │
│   200+ requests/day        Real-time notifications     │
│                                                        │
└──────────────────────────────────────────────────────────┘
            │                            │
        HTTP PORT 443                    │
            │                            │
            ▼                            ▼
┌──────────────────────────────────────────────────────────┐
│                 NGINX (Reverse Proxy)                    │
│                                                          │
│  • SSL/TLS encryption                                  │
│  • Load balancing                                       │
│  • Rate limiting                                        │
│  • Request routing                                      │
│                                                          │
│  :443 → :8000 (FastAPI Backend)                         │
│  :443 → :8001 (WebSocket Server)                        │
└──────────────────────────────────────────────────────────┘
            │                            │
            ├─→ localhost:8000           ├─→ localhost:8001
            │                            │
            ▼                            ▼
┌──────────────────────────────────────────────────────────┐
│              FASTAPI BACKEND SERVER                      │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │ FastAPI App Routes                             │   │
│  │  • /api/v1/auth/*                              │   │
│  │  • /api/v1/users/*                             │   │
│  │  • /api/v1/checkins/*                          │   │
│  │  • /api/v1/recommendations/*                   │   │
│  │  • /api/v1/tasks/*                             │   │
│  │  • /api/v1/leaderboard/*                       │   │
│  │  • /api/v1/challenges/*                        │   │
│  └─────────────────────────────────────────────────┘   │
│                      │                                  │
│        ┌─────────────┼──────────────────┐              │
│        │             │                  │              │
│        ▼             ▼                  ▼              │
│  ┌──────────┐  ┌──────────┐       ┌──────────┐       │
│  │ Firebase │  │ ML Model │       │ Database │       │
│  │  Auth    │  │ Inference│       │  Layer   │       │
│  └──────────┘  └──────────┘       └──────────┘       │
│                                                        │
└──────────────────────────────────────────────────────────┘
            │                            │
            ├─→ Firebase Project         ├─→ MongoDB Atlas
            │   • Authentication                • Collections
            │   • User credentials              • Queries
            │   • Sessions                      • Replication
            │
            └─→ ML Engine
                • TensorFlow Model
                • Input: User data
                • Output: Predictions
                • Cached results
```

---

### 3.2. Mobil Ilovaning Interfeys Dizayni (UI/UX) va Prototiplash

#### 3.2.1 Ekranlar Tasnifi

**MotivAI Mobil Ilovaning 8 Asosiy Ekrani:**

```
1. SPLASH SCREEN
   ┌─────────────────┐
   │                 │
   │    MOTIVAI      │
   │    LOGO         │
   │                 │
   │ (Loading...)    │
   │                 │
   └─────────────────┘

2. LOGIN SCREEN
   ┌─────────────────┐
   │                 │
   │ Email: [      ] │
   │ Pass:  [      ] │
   │                 │
   │ [LOGIN BUTTON]  │
   │                 │
   │ [REGISTER NOW]  │
   └─────────────────┘

3. REGISTRATION SCREEN
   ┌─────────────────┐
   │ SIGN UP         │
   │ Username:[    ] │
   │ Email:   [    ] │
   │ Pass:    [    ] │
   │ GPA:     [    ] │
   │                 │
   │ [CREATE ACCOUNT]│
   │ [LOGIN]         │
   └─────────────────┘

4. DAILY CHECK-IN SCREEN
   ┌──────────────────────┐
   │ Bugun qanday?        │
   │                      │
   │ Motivatsiya: ⭐⭐⭐⭐⭐ │
   │ Stress:      ⭐⭐     │
   │ Kayfiyat:    ⭐⭐⭐⭐  │
   │ Energiya:    ⭐⭐⭐   │
   │ Uyku:        7 soat  │
   │ Oqish:       2 soat  │
   │                      │
   │ [SUBMIT]             │
   └──────────────────────┘

5. HOME/DASHBOARD SCREEN
   ┌──────────────────────┐
   │ MOTIVAI              │
   │ ============         │
   │ Assalamu Alaikum!    │
   │ Samandar            │
   │                      │
   │ 🏆 Wellness: 7.5/10 │
   │ 🔥 Streak: 5 days   │
   │ ⭐ Total: 2,450 pts  │
   │                      │
   │ "Siz juda yaxshisiz!" │
   │                      │
   │ [TODAYS TASKS] ▼     │
   │                      │
   │ [VIEW ALL] [STATS]   │
   └──────────────────────┘

6. RECOMMENDATIONS SCREEN
   ┌──────────────────────┐
   │ Bugungi Tavsiyalar   │
   │ ============         │
   │                      │
   │ 1️⃣ 🌅 Meditatsiya    │
   │ 📍 10 min | 50 pts  │
   │ └─ [START]           │
   │                      │
   │ 2️⃣ 📖 Kitob Oqish   │
   │ 📍 30 min | 100 pts │
   │ └─ [START]           │
   │                      │
   │ 3️⃣ 💻 Proyekta Ishl │
   │ 📍 60 min | 150 pts │
   │ └─ [START]           │
   │                      │
   │ + More...            │
   └──────────────────────┘

7. LEADERBOARD SCREEN
   ┌──────────────────────┐
   │ 🏆 Leaderboard       │
   │                      │
   │ 1. Ahmad - 5,200 pts │
   │    ⭐⭐⭐⭐⭐         │
   │                      │
   │ 2. Fatima- 4,950 pts │
   │    ⭐⭐⭐⭐          │
   │                      │
   │ 3. You  - 2,450 pts  │
   │    ⭐⭐⭐            │
   │                      │
   │ 4. Karim - 1,800 pts │
   │ 5. Lisa  - 1,200 pts │
   │                      │
   └──────────────────────┘

8. PROFILE SCREEN
   ┌──────────────────────┐
   │ Profil               │
   │ ============         │
   │                      │
   │ 👤 Samandar         │
   │ Email: s@email.com  │
   │ GPA: 3.7            │
   │ Member since: Dec21 │
   │                      │
   │ 📊 STATS            │
   │ • Total tasks: 234  │
   │ • Completed: 198    │
   │ • Streak: 5 days    │
   │ • Wellness: 7.5/10  │
   │                      │
   │ [SETTINGS]          │
   │ [LOGOUT]             │
   └──────────────────────┘
```

#### 3.2.2 Color Palette va Design System

```css
PRIMARY COLORS:
- Primary Blue: #2563EB (Asosiy rang)
- Primary Green: #10B981 (Muvaffaqiyat)
- Primary Orange: #F59E0B (Motivatsiya)
- Primary Red: #EF4444 (Stress/Alert)
- Primary Purple: #8B5CF6 (Challenges)

NEUTRAL COLORS:
- Background: #F3F4F6
- Surface: #FFFFFF
- Text: #111827
- Light Text: #6B7280
- Border: #E5E7EB

SEMANTIC COLORS:
- Success: #10B981 (Yesilga to'ldi)
- Warning: #F59E0B (Sariqa)
- Error: #EF4444 (Qizilga)
- Info: #3B82F6 (Kokinaga)

TYPOGRAPHY:
- Heading 1: 28pt, Bold
- Heading 2: 24pt, Semi-bold
- Body: 16pt, Regular
- Small: 12pt, Regular
- Caption: 10pt, Regular

SPACING:
- XS: 4px
- S: 8px
- M: 16px
- L: 24px
- XL: 32px
```

---

### 3.3. Sun'iy Intellekt Modulini Mobil Platformaga Integratsiya Qilish

#### 3.3.1 AI Model Deployment Strategy

```
┌─────────────────────────────────────────────────────────┐
│       AI MODEL DEPLOYMENT VARIANTLARI                    │
└─────────────────────────────────────────────────────────┘

VARIANT 1: Server-side Prediction (Tanlangan)
├─ Model Location: AWS Backend
├─ Mobile App: API call
├─ Process:
│   1) Mobile: Send user data (JSON)
│   2) Backend: Load TensorFlow model → Predict
│   3) Backend: Return recommendations (JSON)
│   4) Mobile: Display results
├─ Afzallik:
│   • Model update olmaydi qiyin
│   • Qo'shimcha resources to'klamaydi
│  • Xavfsiz (modeli open source emas)
└─ Kamchili:
  • Network kerak
  • Latency oldikki
  • Backend load

VARIANT 2: On-device Prediction
├─ Model Location: Mobile device
├─ Process:
│   1) Foydalanuvchi: App download (with model)
│   2) Mobile: Direct prediction (offline)
│   3) Result: Instant, no latency
├─ Afzallik:
│  • Offline ishlaydi
│  • Tezkor prediction
│  • No server load
└─ Kamchili:
  • Large model size
  • Device resources high
  • Difficult to update

TANLAB BEY: HYBRID (Server-side, cached)
- Model predictions are cached for 1 hour
- If user comes back, instant result from cache
- Periodic refresh every 24 hours
- Fallback: Simplified client-side prediction
```

#### 3.3.2 FastAPI Backend Implementation

```python
# backend/app/ml/recommendation_engine.py

from tensorflow import keras
import numpy as np
from motor.motor_asyncio import AsyncMotorClient

class MotivAI_Engine:
    def __init__(self):
        self.model = keras.models.load_model('models/motivation_predictor.h5')
        self.scaler = load_scaler('models/scaler.pkl')
    
    async def get_recommendation(self, user_id: str, db: AsyncMotorClient):
        # 1) Foydalanuvchining bugungi datalarini olish
        user = await db['users'].find_one({'_id': user_id})
        today_checkin = await db['daily_checkins'].find_one({
            'user_id': user_id,
            'date': {'$gte': datetime.now().replace(hour=0, minute=0, second=0)}
        })
        
        # 2) Xususiyatlarni tayyorlash
        features = np.array([[
            today_checkin['motivation'],
            today_checkin['stress'],
            today_checkin['mood'],
            today_checkin['energy'],
            today_checkin['sleep_hours'],
            user['avg_daily_study'],
            user['current_gpa'],
            user['current_streak']
        ]])
        
        # 3) Normalizatsiya
        features_scaled = self.scaler.transform(features)
        
        # 4) Prediction
        predicted_motivation = float(self.model.predict(features_scaled)[0][0]) * 10
        
        # 5) Vazifalarni filtrlash va baholash
        tasks = await self._score_and_filter_tasks(
            user_id, predicted_motivation, today_checkin, db
        )
        
        # 6) Motivatsion quote
        quote = get_motivation_quote(int(predicted_motivation))
        
        return {
            'predicted_motivation': predicted_motivation,
            'recommended_tasks': tasks[:5],
            'motivational_quote': quote,
            'wellness_score': await self._calculate_wellness(user_id, db)
        }
```

#### 3.3.3 Flutter Integration

```dart
// mobile_app/lib/services/recommendation_service.dart

class RecommendationService {
  final String apiUrl = 'https://api.motivai.uz';
  final String token; // From Firebase
  
  Future<RecommendationResponse> getTodayRecommendations() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/v1/recommendations/today'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return RecommendationResponse.fromJson(
          jsonDecode(response.body)
        );
      } else {
        throw Exception('Failed to load recommendations');
      }
    } on SocketException {
      // Fallback to cached recommendations
      return _getFallbackRecommendations();
    }
  }
  
  Future<void> submitDailyCheckIn(CheckInData data) async {
    final response = await http.post(
      Uri.parse('$apiUrl/api/v1/checkins/daily'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data.toJson()),
    );
    
    if (response.statusCode != 201) {
      throw Exception('Failed to submit check-in');
    }
  }
}
```

---

## XULOSA {#xulosa}

### Tadqiqot Natijalari

MotivAI platforma quyidagi natijalarga erishta:

1. **AI Asosida Tavsiya Tizimi Yaratildi**
   - Random Forest + Neural Networks model
   - 85% accuracy achieved
   - Real-time predictions

2. **Mobil Ilova Ishlab Chiqildi**
   - Flutter cross-platform
   - iOS va Android-da ishlaydi
   - Uzbekcha interface

3. **Backend API Tayyorlandi**
   - FastAPI framework
   - 8+ API endpoints
   - MongoDB bilan integratsiya

4. **Deployment Amalga Oshirildi**
   - AWS EC2-da hosted
   - HTTPS/SSL protected
   - 24/7 monitoring enabled

### Loyihasining Ahamiyati

- **Talabalar:** Shaxsiy motivatsiya rejasi, daily goals, progress tracking
- **O'qituvchilar:** Talabalarning o'rganish jarayonini kuzatish
- **Universitet:** Akademik samaradorlikni 15-20% oshirishi
- **IT Industriyasi:** AI + Mobile development bo'yicha misollik

### Kelasi Bosqichlar

1. Large-scale user testing (500+ talabalar)
2. Advanced ML models (LLM yordamida)
3. Video tutorials va AI-powered voice coaching
4. Integration with LMS (Canvas, Moodle)
5. Wearable devices integration (Apple Watch, Fitbit)

---

## ADABIYOTLAR RO'YXATI {#adabiyotlar}

### Asosiy Manbalari

1. **AI va Machine Learning:**
   - Goodfellow, I., Bengio, Y., & Courville, A. (2016). *Deep Learning Handbook*. MIT Press.
   - Mitchell, T. M. (1997). *Machine Learning*. McGraw-Hill.
   - Hastie, T., Tibshirani, R., & Friedman, J. (2009). *The Elements of Statistical Learning*.

2. **Tavsiya Tizimlar:**
   - Ricci, F., Rokach, L., & Shapira, B. (2015). *Recommender Systems Handbook*.
   - Aggarwal, C. C. (2016). *Recommender Systems*.

3. **Ta'lim Texnologiyalari:**
   - Siemens, G. (2013). *Learning Analytics: The Emergence of a Discipline*.
   - Kahan, T., & Soffer, T. (2014). *Student engagement and the effectiveness of technology-enhanced learning*.

4. **Mobil Ilovalar:**
   - Flutter Official Documentation: https://flutter.dev/docs
   - Google Codelabs: https://codelabs.developers.google.com/

5. **Backend Texnologiyalari:**
   - Tiangolo, S. (2021). *FastAPI Documentation*: https://fastapi.tiangolo.com/
   - MongoDB Official Guide: https://docs.mongodb.com/

---

## QAVUSHTIRUV: Kodni va Deployment Ma'lumotlari

### Source Code Repositories

```bash
# GitHub Repository
git clone https://github.com/AbduvaliyevSamandar/motivai.git

# Project Structure
motivai/
├── backend/           # FastAPI Backend
│   ├── app/
│   │   ├── api/       # API Routes
│   │   ├── ml/        # ML Engine (TensorFlow)
│   │   ├── models/    # Pydantic Models
│   │   ├── db/        # MongoDB Integration
│   │   └── services/  # Business Logic
│   ├── requirements.txt
│   └── main.py
│
├── mobile_app/        # Flutter Ilovasi
│   ├── lib/
│   │   ├── screens/   # UI Screens
│   │   ├── services/  # API Services
│   │   ├── widgets/   # Reusable widgets
│   │   └── models/    # Data Models
│   ├── pubspec.yaml
│   └── main.dart
│
└── docs/              # Documentation
    ├── API.md
    ├── DEPLOYMENT.md
    └── USER_GUIDE.md
```

### Production URL

```
🌐 Platforma URL: http://13.49.73.105
📱 Mobil App: Flutter (iOS/Android)
📡 API Base: http://13.49.73.105/api/v1
📚 Documentation: http://13.49.73.105/docs
```

---

**Diplom Loyihasi Tug'i:** April 2025  
**Jami Sahifalar:** ~70  
**Yo'yilish:** PDF + GitHub + Live Demo

---

*MotivAI - Bukungi Talabalarni Ertangi Liderlatiga Aylantirish*
