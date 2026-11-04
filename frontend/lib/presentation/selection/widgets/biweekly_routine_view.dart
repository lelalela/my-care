import 'package:flutter/material.dart';
import '../../../domain/model/biweekly_routine.dart';
import '../../../ui/app_colors.dart';
import '../../common/exercise_detail_dialog.dart';

class BiWeeklyRoutineView extends StatelessWidget {
  const BiWeeklyRoutineView({
    super.key,
    required this.plan,
    required this.selectedWeek,
    required this.selectedDayIndex,
    required this.onSelectWeek,
    required this.onSelectDayIndex,
  });

  final BiWeeklyRoutinePlan plan;
  final int selectedWeek; // 1 or 2
  final int selectedDayIndex; // 0..6
  final ValueChanged<int> onSelectWeek;
  final ValueChanged<int> onSelectDayIndex;

  @override
  Widget build(BuildContext context) {
    final days = selectedWeek == 1 ? plan.week1Days : plan.week2Days;
    final currentDay = days[selectedDayIndex.clamp(0, days.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 주차 선택 탭
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildWeekTab(
                  week: 1,
                  label: '1주차: 월·수·금·일 (주 4회)',
                  isSelected: selectedWeek == 1,
                ),
              ),
              Expanded(
                child: _buildWeekTab(
                  week: 2,
                  label: '2주차: 화·목·토 (주 3회)',
                  isSelected: selectedWeek == 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 주차 안내 설명 배너
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryContainer,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedWeek == 1
                      ? '1주차는 격일로 4회 운동하며 주초/주말 하체 혈당 대사를 집중 관리합니다.'
                      : '2주차는 격일로 3회 운동하며 상체 대근육과 등/코어를 순환합니다.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 7개 요일 캘린더 칩 리스트
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(days.length, (idx) {
              final day = days[idx];
              final isSelected = selectedDayIndex == idx;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelectDayIndex(idx),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (day.isRestDay
                              ? AppColors.secondary
                              : AppColors.primary)
                          : (day.isRestDay
                              ? AppColors.surfaceContainerHigh
                              : AppColors.primaryContainer
                                  .withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (day.isRestDay
                                ? AppColors.secondary
                                : AppColors.primary)
                            : AppColors.outlineVariant,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          day.dayLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.isRestDay ? '🛌 휴식' : day.routineType,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.95)
                                : (day.isRestDay
                                    ? AppColors.textSecondary
                                    : AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 18),

        // 선택한 요일 상세 카드
        if (currentDay.isRestDay)
          _buildRestDayCard(currentDay)
        else
          _buildWorkoutDayCard(currentDay),
      ],
    );
  }

  Widget _buildWeekTab({
    required int week,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        onSelectWeek(week);
        onSelectDayIndex(0); // 주차 변경 시 첫 번째 요일(월)로 자동 리셋
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestDayCard(SplitDayRoutine day) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.4),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          const Text('🛌', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            '${day.dayLabel}요일은 안심 휴식일입니다',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            day.clinicalGoal,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: AppColors.secondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '무리한 웨이트 대신 가벼운 산책이나 충분한 수분 섭취를 권장합니다.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutDayCard(SplitDayRoutine day) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${day.weekNumber}주차 ${day.dayLabel}요일',
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
                  day.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            day.clinicalGoal,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // 유산소 가이드라인
          if (day.aerobic != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_walk_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '필수 유산소: ${day.aerobic!.durationMinutes}분 (${day.aerobic!.cadenceSpm} SPM 속보)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // 추천 종목 목록 (각 3세트)
          const Text(
            '맞춤 근력 종목 (각 3세트)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...day.exercises.map((exercise) {
            return Builder(
              builder: (ctx) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '타깃: ${exercise.target}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      exercise.reps,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: '자세 및 가이드 보기',
                      onPressed: () =>
                          ExerciseDetailDialog.show(ctx, exercise),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
