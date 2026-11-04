import 'package:flutter/material.dart';
import '../../../domain/model/condition_type.dart';
import '../../../ui/app_colors.dart';

/// 선호 운동 환경 선택 세그먼트
class EnvironmentSelector extends StatelessWidget {
  const EnvironmentSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ExerciseEnvironment selected;
  final ValueChanged<ExerciseEnvironment> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '운동 환경 선택',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: ExerciseEnvironment.values.map((env) {
            final isSelected = selected == env;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onSelected(env),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          env.icon,
                          size: 20,
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          env.label.split(' ')[0], // '전체', '헬스장', '홈트레이닝'
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
