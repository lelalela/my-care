import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../domain/model/condition_type.dart';
import '../../../domain/model/prescription.dart';

/// 에셋 JSON(`assets/data/exercise_database.json`)에서
/// 국민체력100 및 임상 처방 운동 데이터를 로드하여 관리하는 데이터 소스
class ExerciseLocalDataSource {
  ExerciseLocalDataSource();

  static const String _assetPath = 'assets/data/exercise_database.json';
  static List<Map<String, dynamic>>? _cachedExercises;

  /// JSON 데이터 비동기 사전 로드 또는 캐시 반환
  Future<List<Map<String, dynamic>>> loadExercises() async {
    if (_cachedExercises != null) {
      return _cachedExercises!;
    }
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> parsed = json.decode(jsonString);
      _cachedExercises = parsed.cast<Map<String, dynamic>>();
      return _cachedExercises!;
    } catch (e) {
      // 로드 실패 시 빈 리스트
      return [];
    }
  }

  /// 캐시가 로드되어 있으면 동기 반환, 아니면 기본 폴백
  List<Map<String, dynamic>> getLoadedExercisesSync() {
    return _cachedExercises ?? [];
  }

  /// 운동 환경 및 선택 질환 조건에 부합하는 운동 목록 필터링
  List<PrescribedExercise> filterExercises({
    required List<Map<String, dynamic>> rawData,
    required Set<ConditionType> conditions,
    required ExerciseEnvironment environment,
    Set<String>? selectedExerciseNames,
  }) {
    if (rawData.isEmpty) return [];

    final conditionIds = conditions.map((c) => c.id).toSet();
    final conditionNames = conditions.map((c) => c.name).toSet();
    final matchedList = <Map<String, dynamic>>[];

    for (final item in rawData) {
      final itemCategory = item['category'] as String?;
      final itemConditions = (item['conditions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {};

      // 환경 필터링
      final isGym = environment == ExerciseEnvironment.gym;
      if (isGym && itemCategory != 'gym_machine') continue;
      if (!isGym &&
          itemCategory != 'home_bodyweight' &&
          itemCategory != 'home_tool') {
        continue;
      }

      // 질환 연관성 필터링 (선택 질환 id 또는 name과 하나 이상 교집합)
      if (conditions.isNotEmpty &&
          itemConditions.intersection(conditionIds).isEmpty &&
          itemConditions.intersection(conditionNames).isEmpty) {
        continue;
      }

      matchedList.add(item);
    }

    // 우선순위 정렬 (priority 오름차순)
    matchedList.sort((a, b) {
      final pA = (a['priority'] as num?)?.toInt() ?? 99;
      final pB = (b['priority'] as num?)?.toInt() ?? 99;
      return pA.compareTo(pB);
    });

    // PrescribedExercise 객체로 변환
    var result = matchedList.map((m) {
      final jointList = (m['jointCautions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      final imageList = (m['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      final stepList = (m['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];

      return PrescribedExercise(
        name: m['name'] as String,
        category: m['category'] as String,
        target: m['target'] as String,
        reps: m['defaultReps'] as String,
        benefit: m['benefit'] as String,
        caution: m['caution'] as String,
        source: m['source'] as String?,
        jointCautions: jointList,
        images: imageList,
        steps: stepList,
        videoUrl: m['videoUrl'] as String?,
      );
    }).toList();

    // 사용자가 선택한 특정 운동이 있는 경우 필터링
    if (selectedExerciseNames != null && selectedExerciseNames.isNotEmpty) {
      result =
          result.where((e) => selectedExerciseNames.contains(e.name)).toList();
    } else if (result.length > 5) {
      // 과부하 방지 최대 5종목 추천
      result = result.sublist(0, 5);
    }

    return result;
  }
}
