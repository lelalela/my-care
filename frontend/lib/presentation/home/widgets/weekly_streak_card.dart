import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/repository/workout_history_repository.dart';
import '../../../domain/model/workout_record.dart';
import '../../../ui/app_colors.dart';

/// 주간 스트릭 & 잔디 달성도 카드 (안심 휴식일 + 의료진 제출 리포트 연동)
class WeeklyStreakCard extends StatelessWidget {
  const WeeklyStreakCard({
    super.key,
    required this.streakDays,
    required this.completedWeekdays,
    this.restWeekdays = const <int>{},
    required this.weeklyMinutes,
    required this.records,
    this.onLogRestDay,
  });

  final int streakDays;
  final Set<int> completedWeekdays; // 1=월, 7=일
  final Set<int> restWeekdays; // 안심 휴식일
  final int weeklyMinutes;
  final List<WorkoutRecord> records;
  final VoidCallback? onLogRestDay;

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final todayWeekday = DateTime.now().weekday;
    final isTodayRest = restWeekdays.contains(todayWeekday);
    final isTodayDone = completedWeekdays.contains(todayWeekday);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 상단 헤더: 스트릭 뱃지 & 액션 버튼 ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('🔥 ', style: TextStyle(fontSize: 18)),
                    Flexible(
                      child: Text(
                        streakDays > 0
                            ? '$streakDays일 연속!'
                            : '오늘의 운동을 시작해 보세요!',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // [기획 4] 의료진 리포트 버튼
                  InkWell(
                    onTap: () => _showMedicalReportDialog(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.assignment_outlined,
                              size: 13, color: AppColors.primary),
                          SizedBox(width: 3),
                          Text(
                            '의사용 리포트',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _showHistorySheet(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 3),
                      child: Row(
                        children: const [
                          Text(
                            '기록',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 15, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── 월~일 주간 잔디 동그라미 (운동완료 / 안심휴식일 구분) ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final isCompleted = completedWeekdays.contains(weekday);
              final isRest = restWeekdays.contains(weekday);
              final isToday = weekday == todayWeekday;

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary
                          : (isRest
                              ? AppColors.secondary.withValues(alpha: 0.85)
                              : (isToday
                                  ? AppColors.primaryContainer
                                      .withValues(alpha: 0.4)
                                  : AppColors.surfaceContainerHigh)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isToday
                            ? AppColors.primary
                            : (isCompleted
                                ? AppColors.primary
                                : (isRest
                                    ? AppColors.secondary
                                    : AppColors.outlineVariant)),
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 20, color: AppColors.onPrimary)
                          : (isRest
                              ? const Text('🌿',
                                  style: TextStyle(fontSize: 16))
                              : (isToday
                                  ? Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weekdayLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color:
                          isToday ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),

          // ─── 주간 누적 요약 & 안심 휴식일 버튼 ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '이번 주 $weeklyMinutes분 운동',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                // [기획 2] 오늘 안심 휴식일 지정 버튼
                if (!isTodayDone && !isTodayRest && onLogRestDay != null)
                  InkWell(
                    onTap: () => _confirmRestDay(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            AppColors.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Text('🌿 ', style: TextStyle(fontSize: 11)),
                          Text(
                            '안심 휴식일 지정',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (isTodayRest)
                  const Text(
                    '🌿 오늘 안심 휴식 중',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  )
                else
                  Text(
                    '${completedWeekdays.length}/7일 실천',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// [기획 2] 안심 휴식일 확인 다이얼로그
  void _confirmRestDay(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Text('🌿 '),
            Text(
              '안심 휴식일 선언',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Text(
          '만성질환 케어에서 적절한 휴식은 운동만큼 중요한 치료의 일부입니다.\n\n'
          '오늘은 무리한 운동 대신 가벼운 스트레칭과 숙면을 취하세요.\n'
          '연속 실천 스트릭은 안전하게 유지됩니다!',
          style: TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onLogRestDay?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🌿 오늘을 안심 휴식일로 지정했습니다. 편안한 하루 되세요!'),
                  backgroundColor: AppColors.secondary,
                ),
              );
            },
            child: const Text('휴식일로 지정'),
          ),
        ],
      ),
    );
  }

  /// [기획 4] 의료진 제출용 주간 대사 케어 리포트 다이얼로그
  Future<void> _showMedicalReportDialog(BuildContext context) async {
    const historyRepo = WorkoutHistoryRepository();
    final stats = await historyRepo.getWeeklyMedicalReportStats();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.medical_services_outlined,
                color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              '대사 케어 주간 순응도 소견서',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• 진료 외래 상담 시 주치의에게 본 순응도 데이터를 제시하세요.',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '주간 권장 유산소 순응률:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${stats['complianceRate']}% (150분 기준)',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildReportRow('총 유산소 시간', '${stats['totalMinutes']}분 (목표 150분)'),
              _buildReportRow('평균 보행 케이던스',
                  stats['avgSpm'] > 0 ? '${stats['avgSpm']} SPM' : '-'),
              _buildReportRow(
                  '근력 운동 완수 세트', '${stats['totalStrengthSets']}세트'),
              _buildReportRow(
                  '주간 실천 일수', '${stats['workoutDaysCount']}일 운동 / ${stats['restDaysCount']}일 안심휴식'),
              if (stats['hasBloodSugarData'] == true)
                _buildReportRow('운동 후 평균 혈당 강하',
                    '▼ ${stats['avgBloodSugarDrop']} mg/dL 개선'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: '[My-Care 대사 케어 주간 운동 순응도 리포트]\n'
                    '• 유산소 달성률: ${stats['complianceRate']}%\n'
                    '• 총 운동 시간: ${stats['totalMinutes']}분\n'
                    '• 평균 SPM: ${stats['avgSpm']} SPM\n'
                    '• 근력 완수 세트: ${stats['totalStrengthSets']}세트\n'
                    '• 운동 일수: ${stats['workoutDaysCount']}일, 휴식일: ${stats['restDaysCount']}일',
              ));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('의료진 제출용 소견서가 클립보드에 복사되었습니다.')),
              );
            },
            child: const Text('클립보드 복사'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const Text(
                    '최근 운동 및 휴식 기록',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (records.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          '아직 기록된 운동이 없습니다.\n오늘의 첫 워킹 코칭을 시작해 보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, height: 1.5),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const Divider(height: 16),
                        itemBuilder: (_, index) {
                          final r = records[index];
                          final dateStr =
                              '${r.completedAt.month}월 ${r.completedAt.day}일 ${r.completedAt.hour.toString().padLeft(2, '0')}:${r.completedAt.minute.toString().padLeft(2, '0')}';

                          if (r.isRestDay) {
                            return Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer
                                        .withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('🌿',
                                        style: TextStyle(fontSize: 18)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        '안심 휴식일 (근육 회복 및 스트릭 유지)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  r.exerciseName != null
                                      ? Icons.fitness_center
                                      : Icons.directions_walk,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      r.exerciseName != null
                                          ? '${r.exerciseName} ${r.completedSets ?? 3}세트 완료'
                                          : '${r.durationMinutes}분 걷기 · ${r.steps}보 · ${r.calories} kcal',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (r.preBloodSugar != null &&
                                        r.postBloodSugar != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '혈당: ${r.preBloodSugar} ➡️ ${r.postBloodSugar} mg/dL (▼${r.preBloodSugar! - r.postBloodSugar!}mg/dL)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
