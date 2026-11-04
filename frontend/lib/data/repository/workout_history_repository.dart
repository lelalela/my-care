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
    // 이번 주 월요일 00:00:00 계산
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    final completedDays = <int>{};
    for (final r in records) {
      if (r.completedAt.isAfter(monday)) {
        completedDays.add(r.completedAt.weekday);
      }
    }
    return completedDays;
  }

  /// 연속 운동 스트릭(Streak) 일수 계산
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
      return 0; // 오늘 또는 어제 운동 기록이 없으면 스트릭 끊김
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
}
