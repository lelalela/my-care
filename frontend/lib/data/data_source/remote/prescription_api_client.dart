import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/model/condition_type.dart';
import '../../../domain/model/prescription.dart';

/// FastAPI 백엔드 연동 클라이언트
class PrescriptionApiClient {
  PrescriptionApiClient({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static String get _defaultBaseUrl {
    // Android 에뮬레이터에서는 호스트 루프백이 10.0.2.2 입니다.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// FastAPI /api/recommend 호출
  Future<WorkoutPrescription?> fetchRecommendation({
    required Set<ConditionType> conditions,
    required ExerciseEnvironment environment,
    int? recentMealMinutesAgo,
  }) async {
    final url = Uri.parse('$_baseUrl/api/recommend');
    final payload = {
      'condition_ids': conditions.map((c) => c.id).toList(),
      'preferred_environment': environment.id,
      'available_time_minutes': 45,
      if (recentMealMinutesAgo != null) ...{
        'recent_meal_minutes_ago': recentMealMinutesAgo,
      },
    };

    try {
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return _parsePrescription(data);
      }
    } catch (_) {
      // 서버 미구동 시 null 반환하여 로컬 리포지토리로 안전 폴백
    }
    return null;
  }

  WorkoutPrescription _parsePrescription(Map<String, dynamic> data) {
    final aerobicJson = data['aerobic_prescription'] as Map<String, dynamic>;
    final cadenceRange = aerobicJson['cadence_range'] as Map<String, dynamic>? ?? {};
    final speedRange = aerobicJson['target_speed_kmh'] as Map<String, dynamic>? ?? {};

    final aerobic = AerobicPrescription(
      durationMinutes: aerobicJson['target_duration_minutes'] as int? ?? 35,
      cadenceSpm: aerobicJson['recommended_cadence_spm'] as int? ?? 110,
      cadenceMin: cadenceRange['min'] as int? ?? 100,
      cadenceMax: cadenceRange['max'] as int? ?? 120,
      speedMin: (speedRange['min'] as num?)?.toDouble() ?? 4.8,
      speedMax: (speedRange['max'] as num?)?.toDouble() ?? 5.6,
      timingMessage: aerobicJson['optimal_timing_message'] as String? ?? '',
      tips: (aerobicJson['tips'] as List<dynamic>?)?.cast<String>() ?? [],
    );

    final exercisesJson = (data['resistance_exercises'] as List<dynamic>?) ?? [];
    final exercises = exercisesJson.map((e) {
      final map = e as Map<String, dynamic>;
      return PrescribedExercise(
        name: map['name'] as String? ?? '',
        category: map['category'] as String? ?? '',
        target: map['target'] as String? ?? '',
        reps: map['reps'] as String? ?? '',
        benefit: map['benefit'] as String? ?? '',
        caution: map['caution'] as String? ?? '',
      );
    }).toList();

    return WorkoutPrescription(
      conditionNames: (data['user_conditions'] as List<dynamic>?)?.cast<String>() ?? [],
      primaryGoals: (data['primary_goals'] as List<dynamic>?)?.cast<String>() ?? [],
      aerobic: aerobic,
      exercises: exercises,
      safetyWarnings: (data['contraindications_and_safety_warnings'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
    );
  }
}
