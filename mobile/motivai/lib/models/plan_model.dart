// lib/models/plan_model.dart

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String category;
  final int durationMinutes;
  final String difficulty;
  final int xpReward;
  final bool isCompleted;
  final String? scheduledTime;
  final List<String> dayOfWeek;
  final int order;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.category = 'study',
    this.durationMinutes = 30,
    this.difficulty = 'medium',
    this.xpReward = 10,
    this.isCompleted = false,
    this.scheduledTime,
    this.dayOfWeek = const [],
    this.order = 0,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'],
    category: json['category'] ?? 'study',
    durationMinutes: json['duration_minutes'] ?? 30,
    difficulty: json['difficulty'] ?? 'medium',
    xpReward: json['xp_reward'] ?? 10,
    isCompleted: json['is_completed'] ?? false,
    scheduledTime: json['scheduled_time'],
    dayOfWeek: List<String>.from(json['day_of_week'] ?? []),
    order: json['order'] ?? 0,
  );

  TaskModel copyWith({bool? isCompleted}) => TaskModel(
    id: id, title: title, description: description,
    category: category, durationMinutes: durationMinutes,
    difficulty: difficulty, xpReward: xpReward,
    isCompleted: isCompleted ?? this.isCompleted,
    scheduledTime: scheduledTime, dayOfWeek: dayOfWeek, order: order,
  );
}

class MilestoneModel {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final int xpReward;

  MilestoneModel({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.xpReward = 50,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> json) => MilestoneModel(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'],
    isCompleted: json['is_completed'] ?? false,
    xpReward: json['xp_reward'] ?? 50,
  );
}

class PlanModel {
  final String id;
  final String title;
  final String? description;
  final String goal;
  final String category;
  final int durationDays;
  final double progress;
  final List<TaskModel> tasks;
  final List<MilestoneModel> milestones;
  final List<String> aiSuggestions;
  final bool aiGenerated;
  final bool isActive;
  final bool isCompleted;
  final int tasksTotal;
  final int tasksCompleted;
  final DateTime createdAt;

  PlanModel({
    required this.id,
    required this.title,
    this.description,
    required this.goal,
    this.category = 'academic',
    this.durationDays = 30,
    this.progress = 0,
    this.tasks = const [],
    this.milestones = const [],
    this.aiSuggestions = const [],
    this.aiGenerated = false,
    this.isActive = true,
    this.isCompleted = false,
    this.tasksTotal = 0,
    this.tasksCompleted = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PlanModel.fromJson(Map<String, dynamic> json) => PlanModel(
    id: json['_id'] ?? json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'],
    goal: json['goal'] ?? '',
    category: json['category'] ?? 'academic',
    durationDays: json['duration_days'] ?? 30,
    progress: (json['progress'] ?? 0).toDouble(),
    tasks: (json['tasks'] as List<dynamic>?)
        ?.map((t) => TaskModel.fromJson(t))
        .toList() ?? [],
    milestones: (json['milestones'] as List<dynamic>?)
        ?.map((m) => MilestoneModel.fromJson(m))
        .toList() ?? [],
    aiSuggestions: List<String>.from(json['ai_suggestions'] ?? []),
    aiGenerated: json['ai_generated'] ?? false,
    isActive: json['is_active'] ?? true,
    isCompleted: json['is_completed'] ?? false,
    tasksTotal: json['tasks_total'] ?? 0,
    tasksCompleted: json['tasks_completed'] ?? 0,
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
  );
}

class ChatMessage {
  final String id;
  final String role; // user | assistant
  final String content;
  final String? sessionId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.sessionId,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['_id'] ?? json['id'] ?? '',
    role: json['role'] ?? 'user',
    content: json['content'] ?? '',
    sessionId: json['session_id'],
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
    metadata: json['metadata'],
  );
}
