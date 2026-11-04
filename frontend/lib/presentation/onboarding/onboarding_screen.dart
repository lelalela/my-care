import 'package:flutter/material.dart';
import '../../domain/model/condition_type.dart';
import '../../ui/app_colors.dart';
import 'onboarding_view_model.dart';
import 'widgets/clinical_highlights_banner.dart';
import 'widgets/condition_card.dart';
import 'widgets/environment_selector.dart';

/// Onboarding Root: ViewModel 주입 및 상태 구독
class OnboardingRoot extends StatefulWidget {
  const OnboardingRoot({super.key});

  @override
  State<OnboardingRoot> createState() => _OnboardingRootState();
}

class _OnboardingRootState extends State<OnboardingRoot> {
  late final OnboardingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingViewModel();
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
        return OnboardingScreen(
          state: _viewModel.state,
          onAction: _viewModel.onAction,
        );
      },
    );
  }
}

/// Onboarding Screen: 순수 StatelessWidget UI
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  final OnboardingState state;
  final ValueChanged<OnboardingAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My-Care'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // 상단 안내 헤더
                  Text(
                    '맞춤 대사 운동 처방',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '관리 중이거나 주의가 필요한\n질환을 모두 선택해 주세요',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '선택하신 질환들의 임상 가이드라인을 교차 분석하여\n무리 없는 운동 타이밍과 강도를 설계해 드립니다.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // 6대 질환 카드 리스트
                  ...ConditionType.values.map((condition) {
                    final isSelected = state.selectedConditions.contains(condition);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ConditionCard(
                        condition: condition,
                        isSelected: isSelected,
                        onTap: () => onAction(ToggleConditionAction(condition)),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // 운동 선호 환경
                  EnvironmentSelector(
                    selected: state.environment,
                    onSelected: (env) => onAction(SelectEnvironmentAction(env)),
                  ),

                  const SizedBox(height: 20),

                  // 실시간 복수 질환 결합 처방 하이라이트 배너
                  ClinicalHighlightsBanner(
                    highlights: state.clinicalHighlights,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),

            // 하단 고정 CTA 버튼
            _BottomCtaBar(
              canProceed: state.canProceed,
              selectedCount: state.selectedConditions.length,
              isSubmitting: state.isSubmitting,
              onSubmit: () => onAction(const SubmitOnboardingAction()),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCtaBar extends StatelessWidget {
  const _BottomCtaBar({
    required this.canProceed,
    required this.selectedCount,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final bool canProceed;
  final int selectedCount;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: const Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: canProceed && !isSubmitting ? onSubmit : null,
        style: FilledButton.styleFrom(
          backgroundColor: canProceed ? AppColors.primary : AppColors.outlineVariant,
          foregroundColor: canProceed ? AppColors.onPrimary : AppColors.textTertiary,
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                canProceed
                    ? '$selectedCount개 질환 맞춤 운동 처방 받기'
                    : '관리 중인 질환을 1개 이상 선택해 주세요',
              ),
      ),
    );
  }
}
