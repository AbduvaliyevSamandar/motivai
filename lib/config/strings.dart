/// Til tizimi - uz, ru, en
class S {
  static String _lang = 'uz';
  static String get lang => _lang;
  static void setLang(String l) => _lang = l;

  static String get(String key) => (_all[key]?[_lang]) ?? (_all[key]?['uz']) ?? key;

  static const _all = <String, Map<String, String>>{
    // ── Common ──
    'app_name':      {'uz': 'MotivAI', 'ru': 'MotivAI', 'en': 'MotivAI'},
    'loading':       {'uz': 'Yuklanmoqda...', 'ru': 'Загрузка...', 'en': 'Loading...'},
    'save':          {'uz': 'Saqlash', 'ru': 'Сохранить', 'en': 'Save'},
    'cancel':        {'uz': 'Bekor', 'ru': 'Отмена', 'en': 'Cancel'},
    'delete':        {'uz': 'O\'chirish', 'ru': 'Удалить', 'en': 'Delete'},
    'error':         {'uz': 'Xato yuz berdi', 'ru': 'Произошла ошибка', 'en': 'An error occurred'},
    'retry':         {'uz': 'Qayta urinish', 'ru': 'Повторить', 'en': 'Retry'},
    'yes':           {'uz': 'Ha', 'ru': 'Да', 'en': 'Yes'},
    'no':            {'uz': 'Yo\'q', 'ru': 'Нет', 'en': 'No'},
    'done':          {'uz': 'Tayyor', 'ru': 'Готово', 'en': 'Done'},
    'continue_btn':  {'uz': 'Davom etish', 'ru': 'Продолжить', 'en': 'Continue'},

    // ── Auth ──
    'login':         {'uz': 'Kirish', 'ru': 'Войти', 'en': 'Login'},
    'register':      {'uz': 'Ro\'yxatdan o\'tish', 'ru': 'Регистрация', 'en': 'Register'},
    'email':         {'uz': 'Email', 'ru': 'Эл. почта', 'en': 'Email'},
    'password':      {'uz': 'Parol', 'ru': 'Пароль', 'en': 'Password'},
    'full_name':     {'uz': 'To\'liq ism', 'ru': 'Полное имя', 'en': 'Full name'},
    'username':      {'uz': 'Foydalanuvchi nomi', 'ru': 'Имя пользователя', 'en': 'Username'},
    'forgot_pass':   {'uz': 'Parolni unutdingizmi?', 'ru': 'Забыли пароль?', 'en': 'Forgot password?'},
    'no_account':    {'uz': 'Hisobingiz yo\'qmi?', 'ru': 'Нет аккаунта?', 'en': 'No account?'},
    'has_account':   {'uz': 'Hisobingiz bormi?', 'ru': 'Есть аккаунт?', 'en': 'Have an account?'},
    'login_google':  {'uz': 'Google bilan kirish', 'ru': 'Войти через Google', 'en': 'Sign in with Google'},
    'login_phone':   {'uz': 'Telefon bilan kirish', 'ru': 'Войти по телефону', 'en': 'Sign in with Phone'},
    'or':            {'uz': 'yoki', 'ru': 'или', 'en': 'or'},
    'motto':         {'uz': 'Maqsadga — har kuni bir qadam!', 'ru': 'К цели — каждый день по шагу!', 'en': 'One step closer to your goal every day!'},
    'min_6':         {'uz': 'Kamida 6 belgi', 'ru': 'Минимум 6 символов', 'en': 'At least 6 characters'},
    'enter_email':   {'uz': 'Email kiriting', 'ru': 'Введите email', 'en': 'Enter email'},
    'valid_email':   {'uz': 'To\'g\'ri email kiriting', 'ru': 'Введите корректный email', 'en': 'Enter valid email'},
    'reset_pass':    {'uz': 'Parolni tiklash', 'ru': 'Восстановить пароль', 'en': 'Reset password'},
    'reset_sent':    {'uz': 'Parol tiklash havolasi yuborildi', 'ru': 'Ссылка отправлена', 'en': 'Reset link sent'},
    'phone_number':  {'uz': 'Telefon raqam', 'ru': 'Номер телефона', 'en': 'Phone number'},
    'send_sms':      {'uz': 'SMS yuborish', 'ru': 'Отправить SMS', 'en': 'Send SMS'},
    'coming_soon':   {'uz': 'Tez orada qo\'shiladi', 'ru': 'Скоро будет доступно', 'en': 'Coming soon'},

    // ── Navigation ──
    'home':          {'uz': 'Bosh sahifa', 'ru': 'Главная', 'en': 'Home'},
    'chat':          {'uz': 'AI Chat', 'ru': 'AI Чат', 'en': 'AI Chat'},
    'rating':        {'uz': 'Reyting', 'ru': 'Рейтинг', 'en': 'Rating'},
    'analytics':     {'uz': 'Tahlil', 'ru': 'Аналитика', 'en': 'Analytics'},
    'profile':       {'uz': 'Profil', 'ru': 'Профиль', 'en': 'Profile'},

    // ── Dashboard ──
    'good_morning':  {'uz': 'Xayrli tong', 'ru': 'Доброе утро', 'en': 'Good morning'},
    'good_day':      {'uz': 'Xayrli kun', 'ru': 'Добрый день', 'en': 'Good afternoon'},
    'good_evening':  {'uz': 'Xayrli kech', 'ru': 'Добрый вечер', 'en': 'Good evening'},
    'today_goal':    {'uz': 'Bugungi maqsad', 'ru': 'Цель дня', 'en': 'Today\'s goal'},
    'today_tasks':   {'uz': 'Bugungi vazifalar', 'ru': 'Задачи на сегодня', 'en': 'Today\'s tasks'},
    'no_tasks':      {'uz': 'Hozircha vazifalar yo\'q', 'ru': 'Пока нет задач', 'en': 'No tasks yet'},
    'add_task':      {'uz': 'Vazifa qo\'shish', 'ru': 'Добавить задачу', 'en': 'Add task'},
    'all_done':      {'uz': 'Barcha vazifalar bajarildi!', 'ru': 'Все задачи выполнены!', 'en': 'All tasks completed!'},
    'completed':     {'uz': 'bajarildi', 'ru': 'выполнено', 'en': 'completed'},
    'level':         {'uz': 'Daraja', 'ru': 'Уровень', 'en': 'Level'},
    'points':        {'uz': 'ball', 'ru': 'баллов', 'en': 'points'},
    'streak':        {'uz': 'Streak', 'ru': 'Серия', 'en': 'Streak'},
    'day':           {'uz': 'kun', 'ru': 'дн.', 'en': 'days'},
    'tasks_label':   {'uz': 'Vazifalar', 'ru': 'Задачи', 'en': 'Tasks'},
    'ai_suggest':    {'uz': 'AI Tavsiyalar', 'ru': 'AI Рекомендации', 'en': 'AI Suggestions'},
    'pull_refresh':  {'uz': 'Yangilash uchun pastga torting', 'ru': 'Потяните вниз для обновления', 'en': 'Pull to refresh'},
    'today':         {'uz': 'bugun', 'ru': 'сегодня', 'en': 'today'},

    // ── Task ──
    'easy':          {'uz': 'Oson', 'ru': 'Легко', 'en': 'Easy'},
    'medium':        {'uz': 'O\'rta', 'ru': 'Средне', 'en': 'Medium'},
    'hard':          {'uz': 'Qiyin', 'ru': 'Сложно', 'en': 'Hard'},
    'expert':        {'uz': 'Expert', 'ru': 'Эксперт', 'en': 'Expert'},
    'task_title':    {'uz': 'Vazifa nomi', 'ru': 'Название задачи', 'en': 'Task title'},
    'task_desc':     {'uz': 'Tavsif', 'ru': 'Описание', 'en': 'Description'},
    'duration':      {'uz': 'Davomiyligi (daqiqa)', 'ru': 'Продолжительность (мин)', 'en': 'Duration (min)'},
    'priority':      {'uz': 'Muhimlik', 'ru': 'Приоритет', 'en': 'Priority'},
    'low':           {'uz': 'Past', 'ru': 'Низкий', 'en': 'Low'},
    'high':          {'uz': 'Yuqori', 'ru': 'Высокий', 'en': 'High'},
    'urgent':        {'uz': 'Shoshilinch', 'ru': 'Срочный', 'en': 'Urgent'},
    'category':      {'uz': 'Kategoriya', 'ru': 'Категория', 'en': 'Category'},
    'task_added':    {'uz': 'Vazifa qo\'shildi!', 'ru': 'Задача добавлена!', 'en': 'Task added!'},

    // ── Chat ──
    'ai_assistant':  {'uz': 'AI Assistent', 'ru': 'AI Ассистент', 'en': 'AI Assistant'},
    'type_message':  {'uz': 'Xabar yozing...', 'ru': 'Введите сообщение...', 'en': 'Type a message...'},
    'ai_typing':     {'uz': 'AI yozmoqda...', 'ru': 'AI печатает...', 'en': 'AI is typing...'},
    'clear_chat':    {'uz': 'Tarixni tozalash', 'ru': 'Очистить историю', 'en': 'Clear history'},
    'chat_cleared':  {'uz': 'Suhbat tozalandi', 'ru': 'Чат очищен', 'en': 'Chat cleared'},

    // ── Leaderboard ──
    'all_time':      {'uz': 'Barcha vaqt', 'ru': 'За всё время', 'en': 'All time'},
    'this_week':     {'uz': 'Bu hafta', 'ru': 'Эта неделя', 'en': 'This week'},
    'students':      {'uz': 'talaba', 'ru': 'студ.', 'en': 'students'},
    'empty_board':   {'uz': 'Reyting hali bo\'sh', 'ru': 'Рейтинг пока пуст', 'en': 'Leaderboard is empty'},

    // ── Profile ──
    'settings':      {'uz': 'Sozlamalar', 'ru': 'Настройки', 'en': 'Settings'},
    'dark_mode':     {'uz': 'Tungi rejim', 'ru': 'Тёмная тема', 'en': 'Dark mode'},
    'light_mode':    {'uz': 'Kunduzgi rejim', 'ru': 'Светлая тема', 'en': 'Light mode'},
    'change_pass':   {'uz': 'Parolni o\'zgartirish', 'ru': 'Изменить пароль', 'en': 'Change password'},
    'language':      {'uz': 'Til', 'ru': 'Язык', 'en': 'Language'},
    'notifications': {'uz': 'Bildirishnomalar', 'ru': 'Уведомления', 'en': 'Notifications'},
    'clear_cache':   {'uz': 'Keshni tozalash', 'ru': 'Очистить кэш', 'en': 'Clear cache'},
    'logout':        {'uz': 'Chiqish', 'ru': 'Выйти', 'en': 'Log out'},
    'logout_confirm':{'uz': 'Hisobdan chiqmoqchimisiz?', 'ru': 'Вы хотите выйти?', 'en': 'Do you want to log out?'},
    'account':       {'uz': 'Hisob', 'ru': 'Аккаунт', 'en': 'Account'},
    'edit_profile':  {'uz': 'Profilni tahrirlash', 'ru': 'Редактировать профиль', 'en': 'Edit profile'},
    'achievements':  {'uz': 'Yutuqlar', 'ru': 'Достижения', 'en': 'Achievements'},
    'current_pass':  {'uz': 'Joriy parol', 'ru': 'Текущий пароль', 'en': 'Current password'},
    'new_pass':      {'uz': 'Yangi parol', 'ru': 'Новый пароль', 'en': 'New password'},
    'confirm_pass':  {'uz': 'Parolni tasdiqlang', 'ru': 'Подтвердите пароль', 'en': 'Confirm password'},
    'pass_changed':  {'uz': 'Parol o\'zgartirildi', 'ru': 'Пароль изменён', 'en': 'Password changed'},
    'pass_mismatch': {'uz': 'Parollar mos kelmadi', 'ru': 'Пароли не совпадают', 'en': 'Passwords don\'t match'},
    'select_lang':   {'uz': 'Tilni tanlang', 'ru': 'Выберите язык', 'en': 'Select language'},

    // ── Progress ──
    'weekly_points': {'uz': 'Haftalik ballar', 'ru': 'Баллы за неделю', 'en': 'Weekly points'},
    'total_points':  {'uz': 'Jami ball', 'ru': 'Всего баллов', 'en': 'Total points'},
    'cat_breakdown': {'uz': 'Kategoriya taqsimoti', 'ru': 'Разбивка по категориям', 'en': 'Category breakdown'},
    'next_level':    {'uz': 'Keyingi darajaga', 'ru': 'До следующего уровня', 'en': 'To next level'},

    // ── Completion ──
    'task_done':     {'uz': 'Bajarildi!', 'ru': 'Выполнено!', 'en': 'Completed!'},
    'level_up':      {'uz': 'DARAJA OSHDI!', 'ru': 'УРОВЕНЬ ПОВЫШЕН!', 'en': 'LEVEL UP!'},

    // ── Back to exit ──
    'back_exit':     {'uz': 'Chiqish uchun yana bir marta bosing', 'ru': 'Нажмите ещё раз для выхода', 'en': 'Press again to exit'},

    // ── Profile sections / tiles ──
    'auto_theme':       {'uz': 'Avto tema', 'ru': 'Авто тема', 'en': 'Auto theme'},
    'auto_theme_sub':   {'uz': 'Soatga qarab avtomatik', 'ru': 'По времени суток', 'en': 'Switch by clock'},
    'theme_color':      {'uz': 'Rang mavzusi', 'ru': 'Цветовая тема', 'en': 'Color theme'},
    'flashcards':       {'uz': 'Flashcards', 'ru': 'Карточки', 'en': 'Flashcards'},
    'habits':           {'uz': 'Kundalik odatlar', 'ru': 'Привычки', 'en': 'Habits'},
    'habits_sub':       {'uz': 'Kundalik rivojlanish', 'ru': 'Ежедневный рост', 'en': 'Daily growth'},
    'wrapped':          {'uz': 'Haftalik xulosa', 'ru': 'Итоги недели', 'en': 'Weekly wrap-up'},
    'smart_plan':       {'uz': 'Aqlli reja', 'ru': 'Умный план', 'en': 'Smart plan'},
    'smart_plan_sub':   {'uz': 'Vaqtni rejaga ajratish', 'ru': 'Распределение времени', 'en': 'Time-block planner'},
    'journey':          {'uz': 'Sayohat', 'ru': 'Путешествие', 'en': 'Journey'},
    'journey_sub':      {'uz': '30 kunlik progress', 'ru': '30-дневный прогресс', 'en': '30-day progress'},
    'heatmap':          {'uz': 'Mahsuldorlik xaritasi', 'ru': 'Карта продуктивности', 'en': 'Productivity heatmap'},
    'heatmap_sub':      {'uz': 'Soat va kun statistikasi', 'ru': 'Часы и дни', 'en': 'Hours and days'},
    'rituals':          {'uz': 'Rituallar', 'ru': 'Ритуалы', 'en': 'Rituals'},
    'rituals_sub':      {'uz': 'Takroriy eslatma', 'ru': 'Регулярные напоминания', 'en': 'Recurring reminders'},
    'friends':          {'uz': 'Do\'stlar', 'ru': 'Друзья', 'en': 'Friends'},
    'friends_sub':      {'uz': 'Taklif kodi orqali', 'ru': 'По коду приглашения', 'en': 'Via invite code'},
    'challenges':       {'uz': 'Chellenjlar', 'ru': 'Челленджи', 'en': 'Challenges'},
    'challenges_sub':   {'uz': '7 kunlik turnir', 'ru': '7-дневный турнир', 'en': '7-day tournament'},
    'sound_pack':       {'uz': 'Tovush pachkasi', 'ru': 'Звуковой пакет', 'en': 'Sound pack'},
    'haptics':          {'uz': 'Titrash kuchi', 'ru': 'Сила вибрации', 'en': 'Haptic strength'},
    'test_notif':       {'uz': 'Bildirishnomani sinash', 'ru': 'Тест уведомления', 'en': 'Test notification'},
    'test_notif_sub':   {'uz': '5 soniyadan keyin test keladi', 'ru': 'Через 5 секунд', 'en': 'Arrives in 5s'},
    'export_data':      {'uz': 'Ma\'lumotlarni eksport', 'ru': 'Экспорт данных', 'en': 'Export data'},
    'export_data_sub':  {'uz': 'JSON formatida', 'ru': 'В формате JSON', 'en': 'JSON format'},
    'share_template':   {'uz': 'Template ulashish', 'ru': 'Поделиться шаблоном', 'en': 'Share template'},
    'share_template_sub':{'uz':'Do\'stga jo\'natish uchun','ru':'Отправить другу','en':'Send to a friend'},
    'import_template':  {'uz': 'Template import', 'ru': 'Импорт шаблона', 'en': 'Import template'},
    'import_template_sub':{'uz':'JSON yopishtiring','ru':'Вставьте JSON','en':'Paste JSON'},
    'about_app':        {'uz': 'Ilova haqida', 'ru': 'О приложении', 'en': 'About app'},
    'about_motivai':    {'uz': 'MotivAI haqida', 'ru': 'О MotivAI', 'en': 'About MotivAI'},
    'help':             {'uz': 'Yordam', 'ru': 'Помощь', 'en': 'Help'},
    'help_sub':         {'uz': 'Qo\'llanma', 'ru': 'Руководство', 'en': 'Guide'},
    'privacy_policy':   {'uz': 'Maxfiylik siyosati', 'ru': 'Политика конфиденциальности', 'en': 'Privacy policy'},
    'terms_of_service': {'uz': 'Foydalanish shartlari', 'ru': 'Условия использования', 'en': 'Terms of service'},
    'delete_account':   {'uz': 'Akkauntni o\'chirish', 'ru': 'Удалить аккаунт', 'en': 'Delete account'},
    'delete_account_sub':{'uz':'Butunlay o\'chirish','ru':'Удалить полностью','en':'Permanent removal'},
    'reminder_min_one': {'uz': 'min oldin eslatma', 'ru': 'мин. до напоминания', 'en': 'min before reminder'},
    'reminder_off':     {'uz': 'O\'chirilgan', 'ru': 'Выключено', 'en': 'Off'},
  };
}
