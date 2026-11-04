import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/model/prescription.dart';
import '../../../ui/app_colors.dart';
import '../../common/exercise_detail_dialog.dart';

/// 오늘의 맞춤 하루 운동 루틴 (유산소 1단계 + 근력 2단계 통합 카드)
class DailyWorkoutCard extends StatefulWidget {
  const DailyWorkoutCard({
    super.key,
    required this.aerobic,
    required this.exercises,
    required this.defaultTargetSets,
    required this.customExerciseSets,
    this.aerobicType = 'walking',
    required this.onStartWalking,
    required this.onExerciseTapped,
    required this.onConfigureGlobalSets,
  });

  final AerobicPrescription aerobic;
  final List<PrescribedExercise> exercises;
  final int defaultTargetSets;
  final Map<String, int> customExerciseSets;
  final String aerobicType;
  final ValueChanged<int> onStartWalking;
  final ValueChanged<PrescribedExercise> onExerciseTapped;
  final VoidCallback onConfigureGlobalSets;

  @override
  State<DailyWorkoutCard> createState() => _DailyWorkoutCardState();
}

class _DailyWorkoutCardState extends State<DailyWorkoutCard> {
  late int _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.aerobic.durationMinutes;
  }

  @override
  void didUpdateWidget(covariant DailyWorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aerobic.durationMinutes != widget.aerobic.durationMinutes) {
      _selectedDuration = widget.aerobic.durationMinutes;
    }
  }

  String _formatReps(String rawReps, int sets) {
    if (rawReps.contains('×')) {
      final base = rawReps.split('×')[0].trim();
      return '$base × $sets세트';
    }
    return rawReps;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aerobic = widget.aerobic;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 통합 루틴 메인 헤더 ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sports_score_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              '오늘의 맞춤 하루 운동 루틴',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '총 ${widget.exercises.length + 1}개 종목',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '대사 개선을 위한 [1단계 유산소 + 2단계 근력] 복합 루틴',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.outlineVariant),

          // ─── [1단계] 식후 맞춤 유산소 ───
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '1단계',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.aerobicType == 'treadmill'
                              ? '트레드밀 (러닝머신)'
                              : '식후 맞춤 유산소 (워킹)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '권장 ${aerobic.durationMinutes}분',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 케이던스 & 시속 박스
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineVariant, width: 1),
                  ),
                  child: Row(
                    children: [
                      // 분당 걸음수(SPM)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '목표 케이던스',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${aerobic.cadenceSpm}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'SPM',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '권장: ${aerobic.cadenceMin}~${aerobic.cadenceMax}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 42,
                        color: AppColors.outlineVariant,
                      ),
                      const SizedBox(width: 16),

                      // 권장 시속
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '목표 시속',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${aerobic.speedMin}~${aerobic.speedMax}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'km/h',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '중등도 빠른 걸음',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ─── 목표 시간 조절 Stepper (+ / - 10분 단위 버튼) ───
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            '목표 워킹 시간',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _HoldableStepperButton(
                            icon: Icons.remove,
                            enabled: _selectedDuration > 10,
                            tooltip: '10분 줄이기 (길게 눌러 연속 조절)',
                            onTrigger: () {
                              if (_selectedDuration > 10) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedDuration -= 10);
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_selectedDuration분',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _HoldableStepperButton(
                            icon: Icons.add,
                            enabled: _selectedDuration < 120,
                            tooltip: '10분 늘리기 (길게 눌러 연속 조절)',
                            onTrigger: () {
                              if (_selectedDuration < 120) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedDuration += 10);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 골든타임 타이밍 안내
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.amberContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        size: 16,
                        color: AppColors.amberHighlight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aerobic.timingMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (aerobic.tips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...aerobic.tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(color: AppColors.textTertiary)),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // 워킹 코칭 시작 버튼
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => widget.onStartWalking(_selectedDuration),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      widget.aerobicType == 'treadmill'
                          ? '${aerobic.cadenceSpm} SPM 트레드밀 코칭 시작 ($_selectedDuration분)'
                          : '${aerobic.cadenceSpm} SPM 워킹 코칭 시작 ($_selectedDuration분)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.outlineVariant),

          // ─── [2단계] 대사 맞춤 근력 & 홈트 루틴 ───
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '2단계',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '맞춤 근력 & 홈트',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    ActionChip(
                      avatar: const Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      label: Text('전체 ${widget.defaultTargetSets}세트'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(
                        color: AppColors.primaryContainer,
                        width: 1.2,
                      ),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      onPressed: widget.onConfigureGlobalSets,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 근력 종목 리스트
                ...widget.exercises.map((item) {
                  final targetSets =
                      widget.customExerciseSets[item.name] ??
                          widget.defaultTargetSets;
                  return _DailyExerciseItemTile(
                    item: item,
                    targetSets: targetSets,
                    formattedReps: _formatReps(item.reps, targetSets),
                    onTap: () => widget.onExerciseTapped(item),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyExerciseItemTile extends StatelessWidget {
  const _DailyExerciseItemTile({
    required this.item,
    required this.targetSets,
    required this.formattedReps,
    required this.onTap,
  });

  final PrescribedExercise item;
  final int targetSets;
  final String formattedReps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        formattedReps,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      tooltip: '자세 및 가이드 보기',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => ExerciseDetailDialog.show(context, item),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.adjust_outlined,
                    size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  item.target,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Text(
                  '세트 시작 ⏱️',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.benefit,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 13,
                    color: AppColors.amberHighlight,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.caution,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.25,
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

/// 길게 누르면 연속으로 증감되는 햅틱 스텝퍼 버튼
class _HoldableStepperButton extends StatefulWidget {
  const _HoldableStepperButton({
    required this.icon,
    required this.enabled,
    required this.onTrigger,
    required this.tooltip,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTrigger;
  final String tooltip;

  @override
  State<_HoldableStepperButton> createState() => _HoldableStepperButtonState();
}

class _HoldableStepperButtonState extends State<_HoldableStepperButton> {
  Timer? _timer;

  void _startHold() {
    if (!widget.enabled) return;
    widget.onTrigger();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (widget.enabled) {
        widget.onTrigger();
      } else {
        _stopHold();
      }
    });
  }

  void _stopHold() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _stopHold(),
      onLongPressCancel: () => _stopHold(),
      child: IconButton.filledTonal(
        onPressed: widget.enabled ? widget.onTrigger : null,
        icon: Icon(widget.icon, size: 18),
        visualDensity: VisualDensity.compact,
        tooltip: widget.tooltip,
      ),
    );
  }
}

