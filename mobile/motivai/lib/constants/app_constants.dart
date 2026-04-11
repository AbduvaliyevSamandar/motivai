// lib/constants/app_constants.dart
class AppConstants {
  static const String appName = 'MotivAI';
  // Change this to your deployed backend URL
  // Android emulator: http://10.0.2.2:8000/api/v1
  // iOS simulator: http://localhost:8000/api/v1
  // Production: https://your-domain.com/api/v1
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  static const List<String> levelNames = [
    '',
    "Yangi boshlovchi",
    "O'rganuvchi",
    "Faol talaba",
    "Izlanuvchan",
    "Ustamon",
    "Professional",
    "Mutaxassis",
    "Ekspert",
    "Master",
    "Champion"
  ];
  
  static const Map<String, String> categoryIcons = {
    'academic': '📚',
    'personal': '🌱',
    'career': '💼',
    'health': '💪',
    'skills': '🎯',
    'language': '🌍',
  };
  
  static const Map<String, String> taskIcons = {
    'study': '📖',
    'exercise': '🏃',
    'reading': '📰',
    'practice': '✏️',
    'review': '🔄',
    'other': '📌',
  };
}
