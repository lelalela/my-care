import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/feedback_service.dart';
import '../../../domain/model/prescription.dart';
import '../../../ui/app_colors.dart';
import 'set_count_input_dialog.dart';

/// 근력 운동 세트별 체크리스트 & 60초 휴식 타이머 시트
class ExerciseSetTrackerDialog extends StatefulWidget {
  const ExerciseSetTrackerDialog({
    super.key,
    required this.exercise,
    required this.targetSets,
    required this.onExerciseCompleted,
    required this.onUpdateTargetSets,
  });

  final PrescribedExercise exercise;
  final int targetSets;
  final ValueChanged<int> onExerciseCompleted;
  final void Function(int newSets, bool applyToAll) onUpdateTargetSets;

  @override
  State<ExerciseSetTrackerDialog> createState() =>
      _ExerciseSetTrackerDialogState();
}

class _ExerciseSetTrackerDialogState extends State<ExerciseSetTrackerDialog> {
  late int _totalSets;
  int _completedSets = 0;
  bool _isResting = false;
  int _restSecondsRemaining = 60;
  Timer? _restTimer;
  late final FeedbackService _feedbackService;

  @override
  void initState() {
    super.initState();
    _totalSets = widget.targetSets;
    _feedbackService = FeedbackService();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _feedbackService.dispose();
    super.dispose();
  }

  Future<void> _openChangeTargetSets() async {
    final result = await SetCountInputDialog.show(
      context,
      initialSets: _totalSets,
      exerciseName: widget.exercise.name,
      showApplyToAll: true,
    );

    if (result != null && mounted) {
      setState(() {
        _totalSets = result.sets;
      });
      widget.onUpdateTargetSets(result.sets, result.applyToAll);

      if (_completedSets >= _totalSets) {
        _restTimer?.cancel();
        _isResting = false;
        _feedbackService.playCompletionFeedback();
        widget.onExerciseCompleted(_completedSets);
      }
    }
  }

  void _onSetCompleted(int setNumber) {
    if (setNumber != _completedSets + 1) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _completedSets++;
    });

    if (_completedSets < _totalSets) {
      _startRestTimer();
    } else {
      // 모든 세트 완료!
      _restTimer?.cancel();
      _feedbackService.playCompletionFeedback();
      widget.onExerciseCompleted(_completedSets);
    }
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = 60;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 1) {
        setState(() {
          _restSecondsRemaining--;
        });
      } else {
        timer.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _isResting = false;
        });
      }
    });
  }

  void _adjustRestTime(int delta) {
    setState(() {
      _restSecondsRemaining = (_restSecondsRemaining + delta).clamp(5, 180);
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final allDone = _completedSets >= _totalSets;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들 바
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

          // 운동 종목 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ex.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ex.reps.contains('×')
                      ? '${ex.reps.split('×')[0].trim()} × $_totalSets세트'
                      : ex.reps,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ex.target,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              InkWell(
                onTap: _openChangeTargetSets,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '목표 $_totalSets세트 (변경)',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 주의사항 배너
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.amberHighlight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ex.caution,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3세트 체크리스트
          ...List.generate(_totalSets, (index) {
            final setNum = index + 1;
            final isDone = _completedSets >= setNum;
            final isCurrent = _completedSets == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: isCurrent && !_isResting ? () => _onSetCompleted(setNum) : null,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primaryContainer.withValues(alpha: 0.35)
                        : (isCurrent
                            ? AppColors.surface
                            : AppColors.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDone
                          ? AppColors.primary
                          : (isCurrent
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.outlineVariant),
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle
                                : (isCurrent
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked),
                            color: isDone || isCurrent
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$setNum세트',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isCurrent || isDone
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDone
                                  ? AppColors.primary
                                  : (isCurrent
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary),
                            ),
                          ),
                        ],
                      ),
                      if (isCurrent && !_isResting)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '세트 완료 체크',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        )
                      else if (isDone)
                        const Text(
                          '완료됨',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // 60초 휴식 타이머 뷰
          if (_isResting) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.hourglass_bottom_rounded,
                              size: 18, color: AppColors.amberHighlight),
                          SizedBox(width: 8),
                          Text(
                            '세트 간 호흡 정리 휴식',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _skipRest,
                        child: const Text('휴식 스킵', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '00:${_restSecondsRemaining.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => _adjustRestTime(-15),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('-15초', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => _adjustRestTime(15),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('+15초', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (allDone) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '🎉 $_totalSets세트를 모두 완수하셨습니다!',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(allDone ? '확인 (닫기)' : '나중에 이어서 하기'),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
