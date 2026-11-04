/// 운동 완료 기록 모델 (안심 휴식일 지원)
class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.completedAt,
    required this.durationMinutes,
    required this.steps,
    required this.calories,
    required this.spm,
    required this.conditions,
    this.isRestDay = false,
    this.exerciseName,
    this.completedSets,
  });

  final String id;
  final DateTime completedAt;
  final int durationMinutes;
  final int steps;
  final int calories;
  final int spm;
  final List<String> conditions;
  final bool isRestDay;
  final String? exerciseName;
  final int? completedSets;

  Map<String, dynamic> toJson() => {
        'id': id,
        'completedAt': completedAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'steps': steps,
        'calories': calories,
        'spm': spm,
        'conditions': conditions,
        'isRestDay': isRestDay,
        'exerciseName': exerciseName,
        'completedSets': completedSets,
      };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
        id: json['id'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        steps: (json['steps'] as num?)?.toInt() ?? 0,
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        spm: (json['spm'] as num?)?.toInt() ?? 0,
        conditions: (json['conditions'] as List<dynamic>?)?.cast<String>() ?? [],
        isRestDay: json['isRestDay'] as bool? ?? false,
        exerciseName: json['exerciseName'] as String?,
        completedSets: (json['completedSets'] as num?)?.toInt(),
      );
}
