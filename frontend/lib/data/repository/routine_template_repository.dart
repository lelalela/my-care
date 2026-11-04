import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/model/condition_type.dart';
import '../../domain/model/routine_template.dart';

class RoutineTemplateRepository {
  const RoutineTemplateRepository();

  static const String _keyTemplates = 'my_care_routine_templates_v1';

  /// 저장된 템플릿 목록 조회 (비어있으면 기본 프리셋 2종 자동 제공)
  Future<List<RoutineTemplate>> getTemplates({
    Set<ConditionType>? conditions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyTemplates);

    final templates = <RoutineTemplate>[];
    if (rawList != null && rawList.isNotEmpty) {
      for (final item in rawList) {
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          templates.add(RoutineTemplate.fromJson(map));
        } catch (_) {}
      }
    }

    // 기본 프리셋 템플릿이 없으면 기본 추천 프리셋 2종 추가
    if (templates.isEmpty) {
      final presets = _createDefaultPresets();
      final encodedList = presets.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_keyTemplates, encodedList);
      return presets;
    }

    return templates;
  }

  /// 템플릿 저장 (신규 등록 or 수정)
  Future<void> saveTemplate(RoutineTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyTemplates) ?? <String>[];

    final existingIndex = rawList.indexWhere((item) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['id'] == template.id;
      } catch (_) {
        return false;
      }
    });

    final encoded = jsonEncode(template.toJson());
    if (existingIndex >= 0) {
      rawList[existingIndex] = encoded;
    } else {
      rawList.insert(0, encoded);
    }

    await prefs.setStringList(_keyTemplates, rawList);
  }

  /// 템플릿 삭제
  Future<void> deleteTemplate(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyTemplates) ?? <String>[];

    rawList.removeWhere((item) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['id'] == id;
      } catch (_) {
        return false;
      }
    });

    await prefs.setStringList(_keyTemplates, rawList);
  }

  List<RoutineTemplate> _createDefaultPresets() {
    final now = DateTime.now();
    return [
      RoutineTemplate(
        id: 'preset_gym_metabolic',
        name: '⭐ [추천] 대사 케어 헬스장 루틴',
        environment: ExerciseEnvironment.gym,
        conditionNames: ['전당뇨', '고혈압', '비만'],
        aerobicType: 'treadmill',
        aerobicDurationMinutes: 40,
        aerobicTargetSpm: 115,
        selectedExerciseNames: [
          '시티드 레그프레스',
          '체스트 프레스 머신',
          '시티드 레그익스텐션 (저중량)',
          '랫풀다운 머신',
        ],
        targetSets: 3,
        createdAt: now,
        isPreset: true,
      ),
      RoutineTemplate(
        id: 'preset_home_glucose',
        name: '⭐ [추천] 식후 안심 홈트 루틴',
        environment: ExerciseEnvironment.home,
        conditionNames: ['전당뇨', '고혈압'],
        aerobicType: 'walking',
        aerobicDurationMinutes: 30,
        aerobicTargetSpm: 115,
        selectedExerciseNames: [
          '체어 스쿼트 (의자 스쿼트)',
          '카프 레이즈 (발뒤꿈치 들기)',
          '월 푸시업 (벽 짚고 밀기)',
          '월 싯 (벽 대고 버티기)',
        ],
        targetSets: 3,
        createdAt: now,
        isPreset: true,
      ),
    ];
  }
}
