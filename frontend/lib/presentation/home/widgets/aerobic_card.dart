import 'package:flutter/material.dart';
import '../../../domain/model/prescription.dart';
import '../../../ui/app_colors.dart';

/// 오늘의 맞춤 유산소 처방 카드
class AerobicCard extends StatefulWidget {
  const AerobicCard({
    super.key,
    required this.prescription,
    required this.onStartWalking,
  });

  final AerobicPrescription prescription;
  final ValueChanged<int> onStartWalking;

  @override
  State<AerobicCard> createState() => _AerobicCardState();
}

class _AerobicCardState extends State<AerobicCard> {
  late int _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.prescription.durationMinutes;
  }

  @override
  void didUpdateWidget(covariant AerobicCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prescription.durationMinutes !=
        widget.prescription.durationMinutes) {
      _selectedDuration = widget.prescription.durationMinutes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prescription = widget.prescription;

    return Container(
      padding: const EdgeInsets.all(20),
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
          // 카드 상단 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_walk,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '오늘의 맞춤 유산소',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '권장 ${prescription.durationMinutes}분',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 핵심 지표 박스 (목표 SPM & 권장 속도)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${prescription.cadenceSpm}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'SPM',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '권장 범위: ${prescription.cadenceMin}~${prescription.cadenceMax}',
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
                  height: 46,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${prescription.speedMin}~${prescription.speedMax}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'km/h',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
          const SizedBox(height: 16),

          // 10분 단위 목표 시간 선택 칩
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '목표 운동 시간 선택',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$_selectedDuration분 설정됨',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 10분 단위 퀵 칩 선택 바
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [10, 20, 30, 40, 50, 60].map((mins) {
                final isSelected = _selectedDuration == mins;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('$mins분'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedDuration = mins),
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                    ),
                    selectedColor: AppColors.primary,
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // 골든타임 타이밍 안내 바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    prescription.timingMessage,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 임상 팁 리스트
          if (prescription.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...prescription.tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.textTertiary)),
                    Expanded(
                      child: Text(
                        tip,
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
            ),
          ],

          const SizedBox(height: 16),

          // 워킹 코칭 시작 버튼
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => widget.onStartWalking(_selectedDuration),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text('${prescription.cadenceSpm} SPM 워킹 코칭 시작 ($_selectedDuration분)'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
