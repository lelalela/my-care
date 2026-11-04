import 'package:flutter/material.dart';
import '../../data/repository/routine_template_repository.dart';
import '../../domain/model/condition_type.dart';
import '../../domain/model/routine_template.dart';
import '../../ui/app_colors.dart';
import '../home/home_screen.dart';
import '../selection/exercise_selection_screen.dart';
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
          onAction: (action) {
            if (action is SubmitOnboardingAction) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExerciseSelectionScreen(
                    selectedConditions: _viewModel.state.selectedConditions,
                  ),
                ),
              );
              return;
            }
            _viewModel.onAction(action);
          },
        );
      },
    );
  }
}

/// Onboarding Screen: 빠른 템플릿 시작 (Fast-Track) 및 신규 맞춤 처방 분기 화면
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  final OnboardingState state;
  final ValueChanged<OnboardingAction> onAction;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final RoutineTemplateRepository _templateRepository =
      const RoutineTemplateRepository();
  List<RoutineTemplate> _templates = [];
  bool _isLoadingTemplates = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final list = await _templateRepository.getTemplates();
    if (mounted) {
      setState(() {
        _templates = list;
        _isLoadingTemplates = false;
      });
    }
  }

  /// [Fast-Track] 템플릿 클릭 시 1·2단계 건너뛰고 3단계 홈으로 즉시 직행
  void _startRoutineWithTemplate(RoutineTemplate t) {
    // 질환 이름들을 ConditionType 매핑
    final conditionSet = <ConditionType>{};
    for (final name in t.conditionNames) {
      for (final c in ConditionType.values) {
        if (c.name == name || c.id == name) {
          conditionSet.add(c);
        }
      }
    }
    if (conditionSet.isEmpty) {
      conditionSet.add(ConditionType.prediabetes);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeRoot(
          selectedConditions: conditionSet,
          environment: t.environment,
          selectedExerciseNames: t.selectedExerciseNames.toSet(),
          aerobicType: t.aerobicType,
          aerobicDurationMinutes: t.aerobicDurationMinutes,
          aerobicTargetSpm: t.aerobicTargetSpm,
          targetSets: t.targetSets,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final onAction = widget.onAction;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My-Care'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // ─── [Fast-Track 1단계] 저장된 템플릿 바로 시작 캐러셀 ───
                  if (!_isLoadingTemplates && _templates.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Text('⚡ ', style: TextStyle(fontSize: 16)),
                            Text(
                              '저장된 루틴 바로 시작',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '1-Tap 직행',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _templates.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (ctx, index) {
                          final t = _templates[index];
                          final isGym =
                              t.environment == ExerciseEnvironment.gym;
                          return _TemplateFastTrackCard(
                            template: t,
                            isGym: isGym,
                            onTap: () => _startRoutineWithTemplate(t),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: AppColors.outlineVariant),
                    const SizedBox(height: 18),
                  ],

                  // ─── [신규 처방 섹션] ───
                  Text(
                    '새로운 맞춤 대사 운동 처방',
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
                    final isSelected =
                        state.selectedConditions.contains(condition);
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

/// 1단계 빠른 시작용 템플릿 카드
class _TemplateFastTrackCard extends StatelessWidget {
  const _TemplateFastTrackCard({
    required this.template,
    required this.isGym,
    required this.onTap,
  });

  final RoutineTemplate template;
  final bool isGym;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: template.isPreset
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.outlineVariant,
              width: template.isPreset ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isGym
                          ? AppColors.primaryContainer
                          : AppColors.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isGym ? '🏋️ 헬스장' : '🏠 홈트',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isGym ? AppColors.primary : AppColors.secondary,
                      ),
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        '시작',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
              Text(
                template.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '유산소 ${template.aerobicDurationMinutes}분 · 근력 ${template.selectedExerciseNames.length}종목 (${template.targetSets}세트)',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
          backgroundColor:
              canProceed ? AppColors.primary : AppColors.outlineVariant,
          foregroundColor:
              canProceed ? AppColors.onPrimary : AppColors.textTertiary,
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
