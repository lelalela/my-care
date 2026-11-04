import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/feedback_service.dart';
import '../../../data/repository/workout_history_repository.dart';
import '../../../domain/model/prescription.dart';
import '../../../domain/model/workout_record.dart';
import '../../../ui/app_colors.dart';
import 'set_count_input_dialog.dart';

/// 근력 운동 세트별 체크리스트 & 60초 휴식 타이머 바텀시트
class ExerciseSetTrackerDialog extends StatefulWidget {
  const ExerciseSetTrackerDialog({
    super.key,
    required this.exercise,
    required this.targetSets,
    required this.onExerciseCompleted,
    required this.onUpdateTargetSets,
    this.conditions = const ['전당뇨', '고혈압'],
  });

  final PrescribedExercise exercise;
  final int targetSets;
  final ValueChanged<int> onExerciseCompleted;
  final void Function(int newSets, bool applyToAll) onUpdateTargetSets;
  final List<String> conditions;

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
  final WorkoutHistoryRepository _historyRepository =
      const WorkoutHistoryRepository();

  // 혈당 입력 상태
  final TextEditingController _preGlucoseController = TextEditingController();
  final TextEditingController _postGlucoseController = TextEditingController();
  bool _showBloodSugarInput = false;
  int? _recordedDrop;

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
    _preGlucoseController.dispose();
    _postGlucoseController.dispose();
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
        _handleAllSetsCompleted();
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
      _handleAllSetsCompleted();
    }
  }

  void _handleAllSetsCompleted() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _showBloodSugarInput = true;
    });
    _feedbackService.playCompletionFeedback();
    widget.onExerciseCompleted(_completedSets);
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
        // 3초 전 약한 틱 진동 피드백
        if (_restSecondsRemaining <= 3) {
          HapticFeedback.selectionClick();
        }
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
    HapticFeedback.lightImpact();
    setState(() {
      _restSecondsRemaining = (_restSecondsRemaining + delta).clamp(5, 180);
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _isResting = false;
    });
  }

  /// 혈당 기록 저장
  Future<void> _saveBloodSugarData() async {
    final pre = int.tryParse(_preGlucoseController.text.trim());
    final post = int.tryParse(_postGlucoseController.text.trim());

    if (pre != null && post != null) {
      final drop = pre - post;
      setState(() {
        _recordedDrop = drop;
      });

      // 최신 운동 기록에 혈당 업데이트 저장
      final record = WorkoutRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        completedAt: DateTime.now(),
        durationMinutes: 15,
        steps: 0,
        calories: 60,
        spm: 0,
        conditions: widget.conditions,
        exerciseName: widget.exercise.name,
        completedSets: _completedSets,
        preBloodSugar: pre,
        postBloodSugar: post,
      );
      await _historyRepository.saveRecord(record);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final allDone = _completedSets >= _totalSets;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 상단 드래그 핸들 ───
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ─── 운동 종목 헤더 ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ex.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.amberHighlight),
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
            const SizedBox(height: 16),

            // ─── [UI 2] 세트 체크리스트 (56dp Row 전체 터치 타깃) ───
            ...List.generate(_totalSets, (index) {
              final setNum = index + 1;
              final isDone = _completedSets >= setNum;
              final isCurrent = _completedSets == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isCurrent && !_isResting
                        ? () => _onSetCompleted(setNum)
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      constraints: const BoxConstraints(minHeight: 56), // 56dp 보장
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.primaryContainer.withValues(alpha: 0.35)
                            : (isCurrent
                                ? AppColors.surface
                                : AppColors.surfaceContainerHigh),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDone
                              ? AppColors.primary
                              : (isCurrent
                                  ? AppColors.primary
                                  : AppColors.outlineVariant),
                          width: isCurrent ? 1.8 : 1,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDone
                                    ? Icons.check_circle_rounded
                                    : (isCurrent
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_unchecked_rounded),
                                color: isDone || isCurrent
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                                size: 24,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                '$setNum세트',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isCurrent || isDone
                                      ? FontWeight.w800
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '탭하여 완료',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            )
                          else if (isDone)
                            const Text(
                              '✓ 완료',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // ─── [UI 3] 초대형 60초 휴식 타이머 뷰 ───
            if (_isResting) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.hourglass_bottom_rounded,
                                size: 20, color: AppColors.amberHighlight),
                            SizedBox(width: 8),
                            Text(
                              '세트 간 혈압 안정 휴식',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _skipRest,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('휴식 스킵',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // [UI 3] 거대 타이머 폰트 (44sp)
                    Text(
                      '00:${_restSecondsRemaining.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 프로그레스 바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _restSecondsRemaining / 60.0,
                        backgroundColor: AppColors.outlineVariant,
                        color: AppColors.primary,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Thumb Zone 하단 조작 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => _adjustRestTime(-15),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('-15초',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton(
                          onPressed: () => _adjustRestTime(15),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('+15초',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // ─── [기획 3] 운동 전후 혈당(선택) 로깅 섹션 ───
            if (allDone || _showBloodSugarInput) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.bloodtype_outlined,
                            size: 18, color: AppColors.secondary),
                        SizedBox(width: 6),
                        Text(
                          '운동 전/후 혈당 변화 기록 (선택)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '근력 운동으로 인한 식후 혈당 강하 효과를 확인해 보세요.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _preGlucoseController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '운동 전 (mg/dL)',
                              hintText: '예: 165',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward,
                            size: 16, color: AppColors.outline),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _postGlucoseController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '운동 후 (mg/dL)',
                              hintText: '예: 128',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_recordedDrop != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('📉 ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                _recordedDrop! > 0
                                    ? '식후 혈당이 $_recordedDrop mg/dL 안정화되었습니다!'
                                    : '혈당 기록이 저장되었습니다.',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _saveBloodSugarData,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('혈당 저장',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            if (allDone) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '🎉 $_totalSets세트 완료! 대사 건강이 한층 강화되었습니다.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            // 하단 닫기/완료 버튼 (Thumb Zone)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  allDone ? '완료 및 닫기' : '나중에 이어서 하기 (닫기)',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
