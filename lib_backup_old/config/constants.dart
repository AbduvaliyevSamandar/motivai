class K {
  // ── BASE URL ───────────────────────────────────────────
  static const baseUrl = 'https://motivai-20s9.onrender.com/api/v1';

  // ── AUTH ──────────────────────────────────────────────
  static const login    = '/auth/login';
  static const register = '/auth/register';
  static const me       = '/auth/me';
  static const logout   = '/auth/logout';

  // ── TASKS ─────────────────────────────────────────────
  static const tasks       = '/tasks';
  static const daily       = '/tasks/daily';
  static const recommended = '/tasks/recommended';
  static const complete    = '/tasks/complete';
  static const fromChat    = '/tasks/from-chat';

  // ── AI ────────────────────────────────────────────────
  static const aiChat   = '/ai/chat';
  static const aiPlan   = '/ai/motivation-plan';
  static const aiQuote  = '/ai/quote';
  static const insights = '/ai/insights';
  static const achievements = '/ai/achievements';

  // ── LEADERBOARD ───────────────────────────────────────
  static const globalLb = '/leaderboard/global';
  static const weeklyLb = '/leaderboard/weekly';
  static const myRank   = '/leaderboard/my-rank';

  // ── USERS ─────────────────────────────────────────────
  static const profile  = '/users/me/profile';
  static const progress = '/users/me/progress';

  // ── STORAGE KEYS ──────────────────────────────────────
  static const tokenKey = 'auth_token';
  static const userKey  = 'cached_user';

  // ── TIMEOUTS ──────────────────────────────────────────
  static const connectTimeout = Duration(seconds: 30);
  static const aiTimeout      = Duration(seconds: 90); // OpenAI sekin bo'lishi mumkin
}
