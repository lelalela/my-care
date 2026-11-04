import 'condition_type.dart';

/// 맞춤 운동 루틴 템플릿 모델
class RoutineTemplate {
  const RoutineTemplate({
    required this.id,
    required this.name,
    required this.environment,
    required this.conditionNames,
    required this.aerobicType, // 'treadmill' or 'walking'
    required this.aerobicDurationMinutes,
    required this.aerobicTargetSpm,
    required this.selectedExerciseNames,
    required this.targetSets,
    required this.createdAt,
    this.isPreset = false,
  });

  final String id;
  final String name;
  final ExerciseEnvironment environment;
  final List<String> conditionNames;
  final String aerobicType;
  final int aerobicDurationMinutes;
  final int aerobicTargetSpm;
  final List<String> selectedExerciseNames;
  final int targetSets;
  final DateTime createdAt;
  final bool isPreset;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'environment': environment.name,
      'conditionNames': conditionNames,
      'aerobicType': aerobicType,
      'aerobicDurationMinutes': aerobicDurationMinutes,
      'aerobicTargetSpm': aerobicTargetSpm,
      'selectedExerciseNames': selectedExerciseNames,
      'targetSets': targetSets,
      'createdAt': createdAt.toIso8601String(),
      'isPreset': isPreset,
    };
  }

  factory RoutineTemplate.fromJson(Map<String, dynamic> json) {
    return RoutineTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      environment: ExerciseEnvironment.values.firstWhere(
        (e) => e.name == json['environment'],
        orElse: () => ExerciseEnvironment.home,
      ),
      conditionNames: (json['conditionNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      aerobicType: json['aerobicType'] as String? ?? 'walking',
      aerobicDurationMinutes: json['aerobicDurationMinutes'] as int? ?? 30,
      aerobicTargetSpm: json['aerobicTargetSpm'] as int? ?? 115,
      selectedExerciseNames: (json['selectedExerciseNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      targetSets: json['targetSets'] as int? ?? 3,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isPreset: json['isPreset'] as bool? ?? false,
    );
  }

  RoutineTemplate copyWith({
    String? id,
    String? name,
    ExerciseEnvironment? environment,
    List<String>? conditionNames,
    String? aerobicType,
    int? aerobicDurationMinutes,
    int? aerobicTargetSpm,
    List<String>? selectedExerciseNames,
    int? targetSets,
    DateTime? createdAt,
    bool? isPreset,
  }) {
    return RoutineTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      environment: environment ?? this.environment,
      conditionNames: conditionNames ?? this.conditionNames,
      aerobicType: aerobicType ?? this.aerobicType,
      aerobicDurationMinutes:
          aerobicDurationMinutes ?? this.aerobicDurationMinutes,
      aerobicTargetSpm: aerobicTargetSpm ?? this.aerobicTargetSpm,
      selectedExerciseNames:
          selectedExerciseNames ?? this.selectedExerciseNames,
      targetSets: targetSets ?? this.targetSets,
      createdAt: createdAt ?? this.createdAt,
      isPreset: isPreset ?? this.isPreset,
    );
  }
}
