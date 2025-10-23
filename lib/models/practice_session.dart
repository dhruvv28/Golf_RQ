class PracticeSession {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final List<int> shotIds; // References to shots in this session
  final String? courseName;
  final String? weatherConditions;

  PracticeSession({
    this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.notes,
    this.shotIds = const [],
    this.courseName,
    this.weatherConditions,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime?.millisecondsSinceEpoch,
        'notes': notes,
        'shotIds': shotIds.join(','),
        'courseName': courseName,
        'weatherConditions': weatherConditions,
      };

  factory PracticeSession.fromMap(Map<String, dynamic> m) => PracticeSession(
        id: m['id'] as int?,
        name: m['name'] as String,
        startTime: DateTime.fromMillisecondsSinceEpoch(m['startTime'] as int),
        endTime: m['endTime'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(m['endTime'] as int)
            : null,
        notes: m['notes'] as String?,
        shotIds: (m['shotIds'] as String?)?.split(',').map(int.parse).toList() ?? [],
        courseName: m['courseName'] as String?,
        weatherConditions: m['weatherConditions'] as String?,
      );

  Duration? get duration => endTime?.difference(startTime);
  
  bool get isActive => endTime == null;
}
