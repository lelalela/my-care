import 'package:flutter/material.dart';
import '../../domain/model/condition_type.dart';
import '../../ui/app_colors.dart';
import '../walking/walking_screen.dart';
import 'home_view_model.dart';
import 'widgets/aerobic_card.dart';
import 'widgets/exercise_routine_card.dart';
import 'widgets/safety_warning_card.dart';

/// Home Root: ViewModel 주입 및 상태 구독
class HomeRoot extends StatefulWidget {
  const HomeRoot({
    super.key,
    required this.selectedConditions,
    required this.environment,
  });

  final Set<ConditionType> selectedConditions;
  final ExerciseEnvironment environment;

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
  });

  final HomeState state;
  final ValueChanged<HomeAction> onAction;
  final VoidCallback onEditProfile;

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
            const SizedBox(height: 20),

            // 1. 오늘의 맞춤 유산소 카드
            AerobicCard(
              prescription: prescription.aerobic,
              onStartWalking: (durationMinutes) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WalkingRoot(
                      targetSpm: prescription.aerobic.cadenceSpm,
                      durationMinutes: durationMinutes,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 2. 오늘의 맞춤 근력 / 홈트 루틴 카드 목록
            ExerciseRoutineCard(exercises: prescription.exercises),
            const SizedBox(height: 24),

            // 3. 임상 안전 및 주의사항 카드
            SafetyWarningCard(warnings: prescription.safetyWarnings),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
