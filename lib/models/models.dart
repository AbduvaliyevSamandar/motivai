class User {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String role;
  final int points;
  final int level;
  final String? avatarUrl;
  final String? bio;
  final int totalTasksCompleted;
  final int streak;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.role,
    required this.points,
    required this.level,
    this.avatarUrl,
    this.bio,
    required this.totalTasksCompleted,
    required this.streak,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both old and new backend field names
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? json['name'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      role: json['role'] ?? 'student',
      points: (json['points'] ?? json['xp'] ?? 0) as int,
      level: (json['level'] ?? 1) as int,
      avatarUrl: json['avatar_url'] ?? json['avatar'],
      bio: json['bio'],
      totalTasksCompleted: (json['total_tasks_completed'] ?? 0) as int,
      streak: (json['streak'] ?? 0) as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'full_name': fullName,
    'role': role,
    'points': points,
    'level': level,
    'avatar_url': avatarUrl,
    'bio': bio,
    'total_tasks_completed': totalTasksCompleted,
    'streak': streak,
    'created_at': createdAt.toIso8601String(),
  };
}

class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int pointsReward;
  final int durationMinutes;
  final DateTime createdAt;
  final int completionCount;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.pointsReward,
    required this.durationMinutes,
    required this.createdAt,
    required this.completionCount,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      pointsReward: json['points_reward'] ?? 10,
      durationMinutes: json['duration_minutes'] ?? 30,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      completionCount: json['completion_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'difficulty': difficulty,
    'points_reward': pointsReward,
    'duration_minutes': durationMinutes,
    'created_at': createdAt.toIso8601String(),
    'completion_count': completionCount,
  };
}

class Progress {
  final String id;
  final String taskId;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int pointsEarned;

  Progress({
    required this.id,
    required this.taskId,
    required this.status,
    this.startedAt,
    this.completedAt,
    required this.pointsEarned,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      id: json['id'] ?? '',
      taskId: json['task_id'] ?? '',
      status: json['status'] ?? 'not_started',
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      pointsEarned: json['points_earned'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'task_id': taskId,
    'status': status,
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'points_earned': pointsEarned,
  };
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final int points;
  final int level;
  final String? avatarUrl;
  final int totalTasksCompleted;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.points,
    required this.level,
    this.avatarUrl,
    required this.totalTasksCompleted,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      points: json['points'] ?? 0,
      level: json['level'] ?? 1,
      avatarUrl: json['avatar_url'],
      totalTasksCompleted: json['total_tasks_completed'] ?? 0,
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'user_id': userId,
    'username': username,
    'points': points,
    'level': level,
    'avatar_url': avatarUrl,
    'total_tasks_completed': totalTasksCompleted,
    'is_current_user': isCurrentUser,
  };
}

class MotivationPlan {
  final String taskId;
  final String taskTitle;
  final String reason;
  final String difficulty;
  final int estimatedDuration;
  final int pointsAvailable;
  final String motivationalQuote;

  MotivationPlan({
    required this.taskId,
    required this.taskTitle,
    required this.reason,
    required this.difficulty,
    required this.estimatedDuration,
    required this.pointsAvailable,
    required this.motivationalQuote,
  });

  factory MotivationPlan.fromJson(Map<String, dynamic> json) {
    return MotivationPlan(
      taskId: json['task']['id'] ?? '',
      taskTitle: json['task']['title'] ?? '',
      reason: json['reason'] ?? '',
      difficulty: json['task']['difficulty'] ?? 'medium',
      estimatedDuration: json['task']['duration_minutes'] ?? 30,
      pointsAvailable: json['task']['points_reward'] ?? 10,
      motivationalQuote: json['motivation_quote'] ?? 'Keep going!',
    );
  }

  Map<String, dynamic> toJson() => {
    'task_id': taskId,
    'task_title': taskTitle,
    'reason': reason,
    'difficulty': difficulty,
    'estimated_duration': estimatedDuration,
    'points_available': pointsAvailable,
    'motivational_quote': motivationalQuote,
  };
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime earnedAt;
  final String type;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.earnedAt,
    required this.type,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏆',
      earnedAt: json['earned_at'] != null
          ? DateTime.parse(json['earned_at'])
          : DateTime.now(),
      type: json['type'] ?? 'general',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'earned_at': earnedAt.toIso8601String(),
    'type': type,
  };
}
