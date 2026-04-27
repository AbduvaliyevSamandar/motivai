class K {
  static const base = 'https://motivai-20s9.onrender.com/api/v1';

  // Auth
  static const login    = '/auth/login';
  static const register = '/auth/register';
  static const me       = '/auth/me';
  static const logout   = '/auth/logout';
  static const profile  = '/auth/profile';
  static const sendOtp  = '/auth/send-otp';
  static const verifyOtp = '/auth/verify-otp';
  static const registerOtp = '/auth/register-with-otp';
  static const forgotPass = '/auth/forgot-password';
  static const resetPass  = '/auth/reset-password';
  static const googleAuth = '/auth/google';

  // Google OAuth — Web client ID from Cloud Console. Same value goes
  // into the backend's GOOGLE_OAUTH_CLIENT_ID env var so it can verify
  // the audience claim of issued ID tokens.
  static const googleClientId =
      '815399791454-4jme84tp3umt0l58uti61umn7esik3nk.apps.googleusercontent.com';

  // Plans (backend task tizimi plans orqali ishlaydi)
  static const plans        = '/plans';
  static const planStats    = '/plans/stats/summary';

  // AI
  static const aiChat       = '/ai/chat';
  static const fromChat     = '/ai/add-tasks'; // Backendda yo'q, lekin chat provider ishlatadi
  static const insights     = '/ai/daily-insight';
  static const quickMotivate = '/ai/quick-motivate';
  static const analyzeProgress = '/ai/analyze-progress';
  static const dailyTip     = '/ai/daily-tip';
  static const aiHistory    = '/ai/history';
  static const aiSessions   = '/ai/sessions';

  // Leaderboard
  static const leaderboard = '/leaderboard';
  static const myRank      = '/leaderboard/my-rank';

  // Progress
  static const progress    = '/progress';
  static const heatmap     = '/progress/heatmap';

  // Storage
  static const tokenKey = 'motivai_auth_token';
  static const userKey  = 'motivai_user_cache';

  // Timeouts
  static const timeout   = Duration(seconds: 30);
  static const aiTimeout = Duration(seconds: 90);
}