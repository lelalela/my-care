import 'package:flutter/material.dart';
import '../../data/repository/routine_template_repository.dart';
import '../../domain/model/biweekly_routine.dart';
import '../../domain/model/condition_type.dart';
import '../../domain/model/prescription.dart';
import '../../domain/model/routine_template.dart';
import '../../ui/app_colors.dart';
import '../walking/walking_screen.dart';
import 'home_view_model.dart';
import 'widgets/daily_workout_card.dart';
import 'widgets/exercise_set_tracker_dialog.dart';
import 'widgets/safety_warning_card.dart';
import 'widgets/set_count_input_dialog.dart';
import 'widgets/weekly_streak_card.dart';

/// Home Root: ViewModel 주입 및 상태 구독
class HomeRoot extends StatefulWidget {
  const HomeRoot({
    super.key,
    required this.selectedConditions,
    required this.environment,
    this.selectedExerciseNames,
    this.aerobicType = 'walking',
    this.aerobicDurationMinutes = 35,
    this.aerobicTargetSpm = 115,
    this.targetSets = 3,
    this.biWeeklyPlan,
    this.activeSplitDay,
  });

  final Set<ConditionType> selectedConditions;
  final ExerciseEnvironment environment;
  final Set<String>? selectedExerciseNames;
  final String aerobicType;
  final int aerobicDurationMinutes;
  final int aerobicTargetSpm;
  final int targetSets;
  final BiWeeklyRoutinePlan? biWeeklyPlan;
  final SplitDayRoutine? activeSplitDay;

  @override
  State<HomeRoot> createState() => _HomeRootState();
}

class _HomeRootState extends State<HomeRoot> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      initialConditions: widget.selectedConditions,
      initialEnvironment: widget.environment,
      selectedExerciseNames: widget.selectedExerciseNames,
      aerobicType: widget.aerobicType,
      aerobicDurationMinutes: widget.aerobicDurationMinutes,
      aerobicTargetSpm: widget.aerobicTargetSpm,
      targetSets: widget.targetSets,
      biWeeklyPlan: widget.biWeeklyPlan,
      activeSplitDay: widget.activeSplitDay,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        if (state.isLoading || state.prescription == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        }
        return HomeScreen(
          state: state,
          onAction: _viewModel.onAction,
          onEditProfile: () => Navigator.of(context).pop(),
          onLogStrength: _viewModel.logStrengthWorkout,
          onRefreshHistory: () =>
              _viewModel.onAction(const RefreshHistoryAction()),
        );
      },
    );
  }
}

/// Home Screen: 순수 StatelessWidget UI
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.onAction,
    required this.onEditProfile,
    required this.onLogStrength,
    required this.onRefreshHistory,
  });

  final HomeState state;
  final ValueChanged<HomeAction> onAction;
  final VoidCallback onEditProfile;
  final void Function(PrescribedExercise exercise, [int sets]) onLogStrength;
  final VoidCallback onRefreshHistory;

  @override
  Widget build(BuildContext context) {
    final prescription = state.prescription!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 운동 처방'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: '현재 구성을 템플릿으로 저장',
            onPressed: () => _saveCurrentRoutineAsTemplate(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: '질환 및 환경 재설정',
            onPressed: onEditProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 상단 환자 프로필 및 관리 질환 배지 영역
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '관리 중인 대사 질환 (${state.conditions.length}개)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // 환경 태그
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          state.environment.label.split(' ')[0],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: state.conditions.map((c) {
                      return Chip(
                        label: Text(c.name),
                        avatar: Icon(c.icon, size: 16, color: AppColors.primary),
                        backgroundColor:
                            AppColors.primaryContainer.withValues(alpha: 0.3),
                        side: const BorderSide(
                            color: AppColors.primaryContainer, width: 1),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. 주간 스트릭 & 운동 잔디 카드
            WeeklyStreakCard(
              streakDays: state.streakDays,
              completedWeekdays: state.completedWeekdays,
              restWeekdays: state.restWeekdays,
              weeklyMinutes: state.weeklyMinutes,
              records: state.records,
              onLogRestDay: () => onAction(const LogRestDayAction()),
            ),
            const SizedBox(height: 20),

            // [신규] 2주 순환 격일 루틴 배너
            if (state.activeSplitDay != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: state.isRestDay
                      ? AppColors.secondary.withValues(alpha: 0.1)
                      : AppColors.primaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: state.isRestDay
                        ? AppColors.secondary.withValues(alpha: 0.6)
                        : AppColors.primary,
                    width: 1.4,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: state.isRestDay
                            ? AppColors.secondary.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          state.isRestDay ? '🛌' : '📅',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: state.isRestDay
                                      ? AppColors.secondary
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${state.activeSplitDay!.weekNumber}주차 ${state.activeSplitDay!.dayLabel}요일',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.activeSplitDay!.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: state.isRestDay
                                        ? AppColors.secondary
                                        : AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.activeSplitDay!.clinicalGoal,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. 오늘의 맞춤 하루 운동 루틴 (유산소 1단계 + 근력 2단계 통합)
            DailyWorkoutCard(
              aerobic: prescription.aerobic,
              exercises: prescription.exercises,
              defaultTargetSets: state.defaultTargetSets,
              customExerciseSets: state.customExerciseSets,
              aerobicType: state.aerobicType,
              onStartWalking: (durationMinutes) async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WalkingRoot(
                      targetSpm: prescription.aerobic.cadenceSpm,
                      durationMinutes: durationMinutes,
                      conditions: state.conditions.map((c) => c.name).toList(),
                    ),
                  ),
                );
                onRefreshHistory();
              },
              onExerciseTapped: (exercise) {
                _openExerciseTracker(context, exercise);
              },
              onConfigureGlobalSets: () => _openGlobalSetDialog(context),
            ),
            const SizedBox(height: 24),

            // 3. 임상 안전 및 주의사항 카드
            SafetyWarningCard(warnings: prescription.safetyWarnings),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _openGlobalSetDialog(BuildContext context) async {
    final result = await SetCountInputDialog.show(
      context,
      initialSets: state.defaultTargetSets,
      showApplyToAll: false,
    );
    if (result != null) {
      onAction(UpdateGlobalTargetSetsAction(result.sets));
    }
  }

  void _openExerciseTracker(BuildContext context, PrescribedExercise exercise) {
    final targetSets = state.getTargetSetsFor(exercise.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ExerciseSetTrackerDialog(
        exercise: exercise,
        targetSets: targetSets,
        onExerciseCompleted: (sets) => onLogStrength(exercise, sets),
        onUpdateTargetSets: (newSets, applyToAll) {
          onAction(
            UpdateExerciseTargetSetsAction(
              exerciseName: exercise.name,
              targetSets: newSets,
              applyToAll: applyToAll,
            ),
          );
        },
      ),
    );
  }

  /// [기획/UI 3단계] 홈 화면에서 현재 루틴을 새 템플릿으로 저장 (환류 루프)
  Future<void> _saveCurrentRoutineAsTemplate(BuildContext context) async {
    const templateRepo = RoutineTemplateRepository();
    final defaultConditionStr =
        state.conditions.map((c) => c.name).join('+');
    final defaultEnvStr =
        state.environment == ExerciseEnvironment.gym ? '헬스장' : '홈트';
    final controller = TextEditingController(
      text: '$defaultConditionStr $defaultEnvStr 루틴',
    );

    final prescription = state.prescription!;
    final templateName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bookmark_add_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('현재 루틴 템플릿 저장',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '유산소 ${prescription.aerobic.durationMinutes}분 + 근력 ${prescription.exercises.length}개 종목 (각 ${state.defaultTargetSets}세트) 구성이 템플릿으로 저장됩니다.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
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

    if (templateName != null && context.mounted) {
      final newTemplate = RoutineTemplate(
        id: 'template_${DateTime.now().millisecondsSinceEpoch}',
        name: templateName,
        environment: state.environment,
        conditionNames: state.conditions.map((c) => c.name).toList(),
        aerobicType: state.aerobicType,
        aerobicDurationMinutes: prescription.aerobic.durationMinutes,
        aerobicTargetSpm: prescription.aerobic.cadenceSpm,
        selectedExerciseNames:
            prescription.exercises.map((e) => e.name).toList(),
        targetSets: state.defaultTargetSets,
        createdAt: DateTime.now(),
      );

      await templateRepo.saveTemplate(newTemplate);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '\'$templateName\' 템플릿이 저장되었습니다! 💾\n다음번에는 1단계 첫 화면에서 바로 시작하실 수 있습니다.'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
