class Goal {
  final int? id;
  final String title;
  final String description;
  final GoalType type;
  final double targetValue;
  final double currentValue;
  final DateTime targetDate;
  final DateTime createdAt;
  final bool isCompleted;
  final String? club; // For club-specific goals

  Goal({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.targetDate,
    required this.createdAt,
    this.isCompleted = false,
    this.club,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'targetDate': targetDate.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isCompleted': isCompleted ? 1 : 0,
        'club': club,
      };

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
        id: m['id'] as int?,
        title: m['title'] as String,
        description: m['description'] as String,
        type: GoalType.values.firstWhere((e) => e.name == m['type']),
        targetValue: (m['targetValue'] as num).toDouble(),
        currentValue: (m['currentValue'] as num).toDouble(),
        targetDate: DateTime.fromMillisecondsSinceEpoch(m['targetDate'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
        isCompleted: (m['isCompleted'] as int) == 1,
        club: m['club'] as String?,
      );

  double get progressPercentage => (currentValue / targetValue * 100).clamp(0, 100);
  
  bool get isOverdue => DateTime.now().isAfter(targetDate) && !isCompleted;
  
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;
}

enum GoalType {
  consistency, // Lower standard deviation
  distance,    // Increase average distance
  accuracy,    // Hit target more often
  practice,    // Practice frequency
  improvement, // General improvement metric
}
