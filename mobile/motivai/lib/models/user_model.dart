// lib/models/user_model.dart
class UserProfile {
  final String? university;
  final String? faculty;
  final int? year;
  final List<String> goals;
  final List<String> interests;
  final String learningStyle;

  UserProfile({
    this.university,
    this.faculty,
    this.year,
    this.goals = const [],
    this.interests = const [],
    this.learningStyle = 'visual',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    university: json['university'],
    faculty: json['faculty'],
    year: json['year'],
    goals: List<String>.from(json['goals'] ?? []),
    interests: List<String>.from(json['interests'] ?? []),
    learningStyle: json['learning_style'] ?? 'visual',
  );

  Map<String, dynamic> toJson() => {
    'university': university,
    'faculty': faculty,
    'year': year,
    'goals': goals,
    'interests': interests,
    'learning_style': learningStyle,
  };
}

class Badge {
  final String id;
  final String name;
  final String icon;

  Badge({required this.id, required this.name, required this.icon});

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
    id: json['id'],
    name: json['name'],
    icon: json['icon'],
  );
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String language;
  final String country;
  final int xp;
  final int level;
  final int streak;
  final int totalTasksCompleted;
  final int totalStudyMinutes;
  final int aiMessagesCount;
  final UserProfile profile;
  final List<Badge> badges;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.language = 'uz',
    this.country = 'UZ',
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.totalTasksCompleted = 0,
    this.totalStudyMinutes = 0,
    this.aiMessagesCount = 0,
    UserProfile? profile,
    this.badges = const [],
  }) : profile = profile ?? UserProfile();

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    avatar: json['avatar'],
    language: json['language'] ?? 'uz',
    country: json['country'] ?? 'UZ',
    xp: json['xp'] ?? 0,
    level: json['level'] ?? 1,
    streak: json['streak'] ?? 0,
    totalTasksCompleted: json['total_tasks_completed'] ?? 0,
    totalStudyMinutes: json['total_study_minutes'] ?? 0,
    aiMessagesCount: json['ai_messages_count'] ?? 0,
    profile: json['profile'] != null ? UserProfile.fromJson(json['profile']) : null,
    badges: (json['badges'] as List<dynamic>?)
        ?.map((b) => Badge.fromJson(b))
        .toList() ?? [],
  );
}
