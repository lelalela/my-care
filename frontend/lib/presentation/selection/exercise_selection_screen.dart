import 'package:flutter/material.dart';
import '../../data/repository/prescription_repository.dart';
import '../../data/repository/routine_template_repository.dart';
import '../../domain/model/condition_type.dart';
import '../../domain/model/prescription.dart';
import '../../domain/model/routine_template.dart';
import '../../ui/app_colors.dart';
import '../home/home_screen.dart';

/// 2단계: 운동 환경(헬스장/홈트) 탭 & 추천 운동 체크리스트 + 템플릿 관리 화면
class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({
    super.key,
    required this.selectedConditions,
    this.initialTemplate,
  });

  final Set<ConditionType> selectedConditions;
  final RoutineTemplate? initialTemplate;

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  final PrescriptionRepository _prescriptionRepository =
      const PrescriptionRepository();
  final RoutineTemplateRepository _templateRepository =
      const RoutineTemplateRepository();

  late ExerciseEnvironment _environment;
  late int _aerobicDuration;
  late int _aerobicSpm;
  late String _aerobicType;
  late int _targetSets;

  final Set<String> _selectedExerciseNames = <String>{};
  List<PrescribedExercise> _recommendedExercises = [];
  List<RoutineTemplate> _savedTemplates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final template = widget.initialTemplate;
    if (template != null) {
      _environment = template.environment;
      _aerobicType = template.aerobicType;
      _aerobicDuration = template.aerobicDurationMinutes;
      _aerobicSpm = template.aerobicTargetSpm;
      _targetSets = template.targetSets;
      _selectedExerciseNames.addAll(template.selectedExerciseNames);
    } else {
      _environment = ExerciseEnvironment.home;
      _aerobicType = 'walking';
      _aerobicDuration = 35;
      _aerobicSpm = 115;
      _targetSets = 3;
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    _savedTemplates = await _templateRepository.getTemplates(
      conditions: widget.selectedConditions,
    );
    await _refreshRecommendedExercises();
    setState(() => _isLoading = false);
  }

  Future<void> _refreshRecommendedExercises({bool updateDuration = true}) async {
    final prescription = _prescriptionRepository.generatePrescription(
      conditions: widget.selectedConditions,
      environment: _environment,
      aerobicType: _aerobicType,
    );

    _recommendedExercises = prescription.exercises;
    _aerobicSpm = prescription.aerobic.cadenceSpm;
    if (updateDuration && widget.initialTemplate == null) {
      _aerobicDuration = prescription.aerobic.durationMinutes;
    }
    if (widget.initialTemplate == null && _selectedExerciseNames.isEmpty) {
      _selectedExerciseNames.addAll(_recommendedExercises.map((e) => e.name));
    }
  }

  void _switchEnvironment(ExerciseEnvironment newEnv) {
    if (_environment == newEnv) return;
    setState(() {
      _environment = newEnv;
      _aerobicType = newEnv == ExerciseEnvironment.gym ? 'treadmill' : 'walking';
      _selectedExerciseNames.clear();
    });
    _refreshRecommendedExercises(updateDuration: false).then((_) {
      setState(() {
        _selectedExerciseNames.addAll(_recommendedExercises.map((e) => e.name));
      });
    });
  }

  void _applyTemplate(RoutineTemplate template) {
    setState(() {
      _environment = template.environment;
      _aerobicType = template.aerobicType;
      _aerobicDuration = template.aerobicDurationMinutes;
      _aerobicSpm = template.aerobicTargetSpm;
      _targetSets = template.targetSets;
      _selectedExerciseNames.clear();
      _selectedExerciseNames.addAll(template.selectedExerciseNames);
    });

    _refreshRecommendedExercises(updateDuration: false).then((_) {
      setState(() {
        // 템플릿에 지정된 항목 중 현재 추천에 존재하는 것들 매칭
        for (final ex in _recommendedExercises) {
          if (template.selectedExerciseNames.contains(ex.name)) {
            _selectedExerciseNames.add(ex.name);
          }
        }
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('\'${template.name}\' 템플릿이 적용되었습니다!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openSaveTemplateDialog() async {
    final controller = TextEditingController(
      text: _environment == ExerciseEnvironment.gym
          ? '나의 헬스장 기구 루틴'
          : '식후 30분 안심 홈트',
    );

    final templateName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bookmark_add_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('루틴 템플릿 저장', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '현재 설정한 유산소와 근력 종목 구성을 템플릿으로 저장하여 언제든 꺼내 쓸 수 있습니다.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '템플릿 이름',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (templateName != null && mounted) {
      final newTemplate = RoutineTemplate(
        id: 'template_${DateTime.now().millisecondsSinceEpoch}',
        name: templateName,
        environment: _environment,
        conditionNames: widget.selectedConditions.map((c) => c.name).toList(),
        aerobicType: _aerobicType,
        aerobicDurationMinutes: _aerobicDuration,
        aerobicTargetSpm: _aerobicSpm,
        selectedExerciseNames: _selectedExerciseNames.toList(),
        targetSets: _targetSets,
        createdAt: DateTime.now(),
      );

      await _templateRepository.saveTemplate(newTemplate);
      _savedTemplates = await _templateRepository.getTemplates();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\'$templateName\' 템플릿이 저장되었습니다! 💾'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openTemplateListSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.folder_special_rounded,
                            color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          '저장된 루틴 템플릿',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_savedTemplates.length}개',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_savedTemplates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        '저장된 템플릿이 없습니다.',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _savedTemplates.length,
                      itemBuilder: (context, index) {
                        final t = _savedTemplates[index];
                        final isGym = t.environment == ExerciseEnvironment.gym;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.outlineVariant, width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isGym
                                    ? AppColors.primaryContainer.withValues(alpha: 0.5)
                                    : AppColors.secondaryContainer.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isGym ? Icons.fitness_center : Icons.home_rounded,
                                color: isGym
                                    ? AppColors.primary
                                    : AppColors.secondary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              t.name,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${isGym ? "러닝머신" : "걷기"} ${t.aerobicDurationMinutes}분 · 근력 ${t.selectedExerciseNames.length}종목 (${t.targetSets}세트)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _applyTemplate(t);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                  ),
                                  child: const Text('적용',
                                      style: TextStyle(fontSize: 12)),
                                ),
                                if (!t.isPreset)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: Colors.redAccent),
                                    onPressed: () async {
                                      await _templateRepository.deleteTemplate(t.id);
                                      _savedTemplates = await _templateRepository.getTemplates();
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                    tooltip: '삭제',
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToHomeScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeRoot(
          selectedConditions: widget.selectedConditions,
          environment: _environment,
          selectedExerciseNames: _selectedExerciseNames,
          aerobicType: _aerobicType,
          aerobicDurationMinutes: _aerobicDuration,
          aerobicTargetSpm: _aerobicSpm,
          targetSets: _targetSets,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGym = _environment == ExerciseEnvironment.gym;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('2단계: 맞춤 운동 선별'),
        actions: [
          TextButton.icon(
            onPressed: _openTemplateListSheet,
            icon: const Icon(Icons.star_rounded, color: AppColors.amberHighlight, size: 20),
            label: const Text(
              '템플릿',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // 상단 환경 전환 탭 (헬스장 vs 홈트)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _switchEnvironment(ExerciseEnvironment.gym),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isGym
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isGym
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fitness_center_rounded,
                                    size: 18,
                                    color: isGym
                                        ? AppColors.onPrimary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '🏋️ 헬스장 (기구 운동)',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: isGym
                                          ? AppColors.onPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _switchEnvironment(ExerciseEnvironment.home),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isGym
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: !isGym
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.home_rounded,
                                    size: 18,
                                    color: !isGym
                                        ? AppColors.onPrimary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '🏠 홈트 (맨몸/소도구)',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: !isGym
                                          ? AppColors.onPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ─── 1. 유산소 설정 (헬스장: 트레드밀 vs 홈트: 걷기) ───
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isGym
                                        ? Icons.directions_run_rounded
                                        : Icons.directions_walk_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isGym
                                      ? '트레드밀 (러닝머신 워킹)'
                                      : '식후 야외 / 실내 걷기',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '유산소 필수',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isGym
                            ? '헬스장 트레드밀 계기판을 속도 4.8~5.6 km/h (경사도 1~2%)로 설정하고 리듬에 맞춰 걸으세요.'
                            : '식후 30분 시점에 시작하여 혈당 스파이크를 방지하는 최적 케이던스 걷기입니다.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 목표 시간 Stepper
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isGym ? '러닝머신 목표 시간' : '걷기 목표 시간',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton.filledTonal(
                                    onPressed: _aerobicDuration > 10
                                        ? () => setState(
                                            () => _aerobicDuration -= 10)
                                        : null,
                                    icon: const Icon(Icons.remove, size: 16),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: '10분 줄이기',
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '$_aerobicDuration분',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton.filledTonal(
                                    onPressed: _aerobicDuration < 120
                                        ? () => setState(
                                            () => _aerobicDuration += 10)
                                        : null,
                                    icon: const Icon(Icons.add, size: 16),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: '10분 늘리기',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── 2. 맞춤 근력 추천 종목 체크리스트 ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGym ? '추천 기구 운동 선별' : '추천 맨몸/소도구 선별',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '오늘 가능한 운동만 체크하세요 (${_selectedExerciseNames.length}/${_recommendedExercises.length}개 선택)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedExerciseNames.length ==
                                _recommendedExercises.length) {
                              _selectedExerciseNames.clear();
                            } else {
                              _selectedExerciseNames.addAll(
                                  _recommendedExercises.map((e) => e.name));
                            }
                          });
                        },
                        child: Text(
                          _selectedExerciseNames.length ==
                                  _recommendedExercises.length
                              ? '선택 해제'
                              : '전체 선택',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 운동 종목 체크 아이템 목록
                  ..._recommendedExercises.map((exercise) {
                    final isChecked =
                        _selectedExerciseNames.contains(exercise.name);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isChecked) {
                            _selectedExerciseNames.remove(exercise.name);
                          } else {
                            _selectedExerciseNames.add(exercise.name);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? AppColors.primaryContainer.withValues(alpha: 0.25)
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isChecked
                                ? AppColors.primary
                                : AppColors.outlineVariant,
                            width: isChecked ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isChecked,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedExerciseNames.add(exercise.name);
                                  } else {
                                    _selectedExerciseNames.remove(exercise.name);
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exercise.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isChecked
                                                ? AppColors.textPrimary
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        exercise.reps,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '타깃: ${exercise.target}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exercise.benefit,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textTertiary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ─── 하단 액션 바 (템플릿 저장 & 오늘 루틴 시작) ───
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.outlineVariant, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openSaveTemplateDialog,
                    icon: const Icon(Icons.bookmark_border_rounded, size: 18),
                    label: const Text('현재 구성을 템플릿으로 저장 💾'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _selectedExerciseNames.isEmpty
                        ? null
                        : _navigateToHomeScreen,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '선택한 ${_selectedExerciseNames.length}개 운동으로 루틴 시작 ➔',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
