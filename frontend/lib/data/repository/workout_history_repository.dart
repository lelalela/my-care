import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/model/workout_record.dart';

/// 운동 기록 및 주간 스트릭 영구 저장소
class WorkoutHistoryRepository {
  const WorkoutHistoryRepository();

  static const String _storageKey = 'mycare_workout_history';

  Future<void> saveRecord(WorkoutRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    records.insert(0, record); // 최신순 저장

    final jsonList = records.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<List<WorkoutRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => WorkoutRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 이번 주 (월~일) 운동을 완료한 요일 세트 (1=월, 7=일)
  Future<Set<int>> getWeeklyCompletedDays() async {
    final records = await getRecords();
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    final completedDays = <int>{};
    for (final r in records) {
      if (r.completedAt.isAfter(monday) && !r.isRestDay) {
        completedDays.add(r.completedAt.weekday);
      }
    }
    return completedDays;
  }

  /// 이번 주 (월~일) 안심 휴식일(Rest Day) 요일 세트
  Future<Set<int>> getWeeklyRestDays() async {
    final records = await getRecords();
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    final restDays = <int>{};
    for (final r in records) {
      if (r.completedAt.isAfter(monday) && r.isRestDay) {
        restDays.add(r.completedAt.weekday);
      }
    }
    return restDays;
  }

  /// 오늘을 '안심 휴식일(Rest Day)'로 저장 (주 1회 회복)
  Future<void> saveRestDay(List<String> conditions) async {
    final record = WorkoutRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      completedAt: DateTime.now(),
      durationMinutes: 0,
      steps: 0,
      calories: 0,
      spm: 0,
      conditions: conditions,
      isRestDay: true,
    );
    await saveRecord(record);
  }

  /// 연속 운동 스트릭(Streak) 일수 계산 (안심 휴식일도 스트릭 유지)
  Future<int> getStreak() async {
    final records = await getRecords();
    if (records.isEmpty) return 0;

    final dates = records
        .map((r) => DateTime(r.completedAt.year, r.completedAt.month, r.completedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 최신 날짜순

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (!dates.contains(today) && !dates.contains(yesterday)) {
      return 0; // 오늘 또는 어제 기록이 없으면 스트릭 끊김
    }

    int streak = 0;
    DateTime checkDate = dates.contains(today) ? today : yesterday;

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// 이번 주 총 누적 운동 시간(분)
  Future<int> getWeeklyTotalMinutes() async {
    final records = await getRecords();
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    int total = 0;
    for (final r in records) {
      if (r.completedAt.isAfter(monday)) {
        total += r.durationMinutes;
      }
    }
    return total;
  }

  /// 의료진 제출용 주간 대사 케어 순응도 리포트 데이터
  Future<Map<String, dynamic>> getWeeklyMedicalReportStats() async {
    final records = await getRecords();
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    final weeklyRecords =
        records.where((r) => r.completedAt.isAfter(monday)).toList();

    int totalMinutes = 0;
    int totalSteps = 0;
    int totalStrengthSets = 0;
    int workoutDaysCount = 0;
    int restDaysCount = 0;
    List<int> validSpmList = [];

    final activeDays = <int>{};
    for (final r in weeklyRecords) {
      if (r.isRestDay) {
        restDaysCount++;
      } else {
        totalMinutes += r.durationMinutes;
        totalSteps += r.steps;
        if (r.spm > 0) validSpmList.add(r.spm);
        if (r.completedSets != null) {
          totalStrengthSets += r.completedSets!;
        }
        activeDays.add(r.completedAt.weekday);
      }
    }
    workoutDaysCount = activeDays.length;

    final avgSpm = validSpmList.isEmpty
        ? 0
        : (validSpmList.reduce((a, b) => a + b) / validSpmList.length).round();

    // 목표 150분 대비 달성률 (%)
    final complianceRate = ((totalMinutes / 150.0) * 100).clamp(0, 100).round();

    return {
      'totalMinutes': totalMinutes,
      'totalSteps': totalSteps,
      'targetMinutes': 150,
      'complianceRate': complianceRate,
      'workoutDaysCount': workoutDaysCount,
      'restDaysCount': restDaysCount,
      'totalStrengthSets': totalStrengthSets,
      'avgSpm': avgSpm,
    };
  }
}
