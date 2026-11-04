/// 운동 완료 기록 모델
class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.completedAt,
    required this.durationMinutes,
    required this.steps,
    required this.calories,
    required this.spm,
    required this.conditions,
  });

  final String id;
  final DateTime completedAt;
  final int durationMinutes;
  final int steps;
  final int calories;
  final int spm;
  final List<String> conditions;

  Map<String, dynamic> toJson() => {
        'id': id,
        'completedAt': completedAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'steps': steps,
        'calories': calories,
        'spm': spm,
        'conditions': conditions,
      };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
        id: json['id'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
        durationMinutes: json['durationMinutes'] as int,
        steps: json['steps'] as int,
        calories: json['calories'] as int,
        spm: json['spm'] as int,
        conditions: (json['conditions'] as List<dynamic>).cast<String>(),
      );
}
