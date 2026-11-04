import 'package:flutter/material.dart';
import '../../ui/app_colors.dart';
import 'walking_view_model.dart';
import 'widgets/walking_rhythm_visualizer.dart';

/// Walking Root: ViewModel 주입 및 상태 구독
class WalkingRoot extends StatefulWidget {
  const WalkingRoot({
    super.key,
    required this.targetSpm,
    required this.durationMinutes,
  });

  final int targetSpm;
  final int durationMinutes;

  @override
  State<WalkingRoot> createState() => _WalkingRootState();
}

class _WalkingRootState extends State<WalkingRoot> {
  late final WalkingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = WalkingViewModel(
      initialSpm: widget.targetSpm,
      initialDurationMinutes: widget.durationMinutes,
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
        return WalkingScreen(
          state: state,
          onAction: _viewModel.onAction,
          onClose: () => _handleClose(context),
        );
      },
    );
  }

  void _handleClose(BuildContext context) {
    if (_viewModel.state.elapsedSeconds > 10 && !_viewModel.state.isCompleted) {
      showAdaptiveDialog(
        context: context,
        builder: (ctx) => AlertDialog.adaptive(
          title: const Text('운동 종료 확인'),
          content: const Text('지금 종료하시겠습니까? 오늘 기록된 시간과 걸음 수가 저장됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('계속하기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('종료', style: TextStyle(color: AppColors.redAlert)),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}

/// Walking Screen: 순수 StatelessWidget UI
class WalkingScreen extends StatelessWidget {
  const WalkingScreen({
    super.key,
    required this.state,
    required this.onAction,
    required this.onClose,
  });

  final WalkingState state;
  final ValueChanged<WalkingAction> onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('실시간 워킹 코칭'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 목표 시간 프로그레스 바
            LinearProgressIndicator(
              value: state.progress,
              backgroundColor: AppColors.outlineVariant,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '경과 ${state.formattedElapsed}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: state.targetDurationMinutes > 10
                            ? () => onAction(const AdjustDurationAction(-10))
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '-10분',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '목표 ${state.targetDurationMinutes}분',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: state.targetDurationMinutes < 120
                            ? () => onAction(const AdjustDurationAction(10))
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '+10분',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 2. 중앙 메트로놈 펄스 비트 시각화
            WalkingRhythmVisualizer(
              spm: state.targetSpm,
              isActive: state.isActive,
            ),
            const SizedBox(height: 16),

            // SPM 속도 미세 조절 버튼 (-5 / +5)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onAction(const AdjustSpmAction(-5)),
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('5 SPM 늦게'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => onAction(const AdjustSpmAction(5)),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('5 SPM 빠르게'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // 3. 실시간 운동 데이터 지표 (시간, 걸음수, 칼로리)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: '운동 시간',
                    value: state.formattedElapsed,
                    unit: '',
                  ),
                  Container(width: 1, height: 32, color: AppColors.outlineVariant),
                  _StatItem(
                    label: '추정 걸음',
                    value: '${state.estimatedSteps}',
                    unit: '보',
                  ),
                  Container(width: 1, height: 32, color: AppColors.outlineVariant),
                  _StatItem(
                    label: '소비 칼로리',
                    value: '${state.estimatedCalories}',
                    unit: 'kcal',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. 하단 컨트롤러 (일시정지/재생 & 완료 버튼)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // 운동 완료 버튼
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => _showCompletionDialog(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('운동 완료'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 재생 / 일시정지 버튼
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => onAction(const TogglePlayPauseAction()),
                      icon: Icon(
                        state.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 22,
                      ),
                      label: Text(state.isActive ? '일시 정지' : '다시 걷기'),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            state.isActive ? AppColors.textPrimary : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog.adaptive(
          title: const Text('오늘의 워킹 완료! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '총 운동 시간: ${state.formattedElapsed}\n'
                '달성 걸음 수: 약 ${state.estimatedSteps}보\n'
                '소모 칼로리: 약 ${state.estimatedCalories} kcal\n\n'
                '규칙적인 SPM 걷기로 대사 질환 관리에 큰 효과를 거두셨습니다. 수분을 충분히 섭취해 주세요!',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('대시보드로 돌아가기'),
            ),
          ],
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
