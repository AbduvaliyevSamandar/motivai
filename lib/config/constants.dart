class K {
  static const base = 'https://motivai-20s9.onrender.com/api/v1';

  // Auth
  static const login    = '/auth/login';
  static const register = '/auth/register';
  static const me       = '/auth/me';
  static const logout   = '/auth/logout';

  // Tasks
  static const daily       = '/tasks/daily';
  static const recommended = '/tasks/recommended';
  static const complete    = '/tasks/complete';
  static const fromChat    = '/ai/add-tasks';

  // AI
  static const aiChat      = '/ai/chat';
  static const aiPlan      = '/ai/motivation-plan';
  static const aiQuote     = '/ai/motivation-quote';
  static const insights    = '/ai/daily-insight';
  static const achievements= '/ai/achievements';

  // Leaderboard — ANIQ endpoint nomlari
  static const globalLb = '/leaderboard/global';
  static const weeklyLb = '/leaderboard/global';   // weekly yo'q, global ishlatamiz
  static const myRank   = '/leaderboard/user-rank'; // my-rank EMAS!

  // Users
  static const profile  = '/users/me';
  static const progress = '/users/me/progress';

  // Storage
  static const tokenKey = 'motivai_auth_token';
  static const userKey  = 'motivai_user_cache';

  // Timeouts
  static const timeout   = Duration(seconds: 30);
  static const aiTimeout = Duration(seconds: 90);
}