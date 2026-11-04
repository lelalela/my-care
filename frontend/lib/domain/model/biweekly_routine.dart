import 'condition_type.dart';
import 'prescription.dart';

/// 2주 순환 루틴의 단일 일자 정의
class SplitDayRoutine {
  const SplitDayRoutine({
    required this.weekNumber, // 1 or 2
    required this.weekday, // 1=월, 2=화, ..., 7=일
    required this.dayLabel, // '월', '화', ...
    required this.isRestDay,
    required this.routineType, // 'A', 'B', 'C', 'A\'', 'B\'', 'C\'', or 'REST'
    required this.title, // '루틴 A (하체 집중)', '안심 휴식일'
    required this.clinicalGoal, // '대퇴사두근/둔근 GLUT4 포도당 흡수 극대화'
    required this.exercises,
    this.aerobic,
    this.targetSets = 3,
  });

  final int weekNumber;
  final int weekday;
  final String dayLabel;
  final bool isRestDay;
  final String routineType;
  final String title;
  final String clinicalGoal;
  final List<PrescribedExercise> exercises;
  final AerobicPrescription? aerobic;
  final int targetSets;

  String get dayKey => 'W${weekNumber}_$weekday';
}

/// 2주 순환 루틴 전체 플랜 (14일간의 격일 루틴)
class BiWeeklyRoutinePlan {
  const BiWeeklyRoutinePlan({
    required this.planId,
    required this.title,
    required this.description,
    required this.conditions,
    required this.environment,
    required this.days,
  });

  final String planId;
  final String title;
  final String description;
  final Set<ConditionType> conditions;
  final ExerciseEnvironment environment;
  final List<SplitDayRoutine> days;

  /// 오늘 날짜에 해당하는 SplitDayRoutine 찾기
  SplitDayRoutine getTodayRoutine({DateTime? now, int? currentWeek}) {
    final date = now ?? DateTime.now();
    // 1년의 홀수/짝수 주차 기반으로 1주차/2주차 결정 (또는 사용자 지정)
    final week = currentWeek ??
        ((date.difference(DateTime(date.year, 1, 1)).inDays ~/ 7) % 2 + 1);
    final weekday = date.weekday; // 1=Mon .. 7=Sun

    return days.firstWhere(
      (d) => d.weekNumber == week && d.weekday == weekday,
      orElse: () => days.first,
    );
  }

  /// 1주차 일자 목록 (7일: 월, 화, 수, 목, 금, 토, 일)
  List<SplitDayRoutine> get week1Days =>
      days.where((d) => d.weekNumber == 1).toList();

  /// 2주차 일자 목록 (7일: 월, 화, 수, 목, 금, 토, 일)
  List<SplitDayRoutine> get week2Days =>
      days.where((d) => d.weekNumber == 2).toList();
}
