class K {
  // ── Backend URL (Render.com) ───────────────────────────
  static const base = 'https://motivai-20s9.onrender.com/api/v1';

  // Lokal test uchun:
  // static const base = 'http://10.0.2.2:8000/api/v1'; // Android emulator
  // static const base = 'http://localhost:8000/api/v1';  // iOS simulator

  // ── Auth ─────────────────────────────────────────────
  static const login    = '/auth/login';
  static const register = '/auth/register';
  static const me       = '/auth/me';
  static const logout   = '/auth/logout';

  // ── Tasks ─────────────────────────────────────────────
  static const tasks       = '/tasks';
  static const daily       = '/tasks/daily';
  static const recommended = '/tasks/recommended';
  static const complete    = '/tasks/complete';
  static const fromChat    = '/tasks/from-chat';

  // ── AI ───────────────────────────────────────────────
  static const aiChat      = '/ai/chat';
  static const aiPlan      = '/ai/motivation-plan';
  static const aiQuote     = '/ai/motivation-quote';
  static const insights    = '/ai/daily-insight';
  static const achievements= '/ai/achievements';

  // ── Leaderboard ───────────────────────────────────────
  static const globalLb = '/leaderboard/global';
  static const weeklyLb = '/leaderboard/weekly';
  static const myRank   = '/leaderboard/my-rank';

  // ── Users ─────────────────────────────────────────────
  static const profile  = '/users/profile';
  static const progress = '/users/progress';

  // ── Storage keys ─────────────────────────────────────
  static const tokenKey = 'motivai_auth_token';
  static const userKey  = 'motivai_user_cache';

  // ── Timeouts ─────────────────────────────────────────
  static const timeout    = Duration(seconds: 30);
  static const aiTimeout  = Duration(seconds: 90);
}
