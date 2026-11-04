import 'package:flutter/material.dart';
import '../../domain/model/condition_type.dart';
import '../../domain/model/prescription.dart';
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
  });

  final Set<ConditionType> selectedConditions;
  final ExerciseEnvironment environment;
  final Set<String>? selectedExerciseNames;
  final String aerobicType;
  final int aerobicDurationMinutes;
  final int aerobicTargetSpm;
  final int targetSets;

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
              weeklyMinutes: state.weeklyMinutes,
              records: state.records,
            ),
            const SizedBox(height: 20),

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
}
