import 'package:flutter/material.dart';
import '../../../ui/app_colors.dart';

/// 임상 안전 가이드 및 주의사항 카드
class SafetyWarningCard extends StatelessWidget {
  const SafetyWarningCard({
    super.key,
    required this.warnings,
  });

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.redAlert.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.redAlert,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '임상 안전 수칙 (필독)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.redAlert,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ ',
                    style: TextStyle(fontSize: 12),
                  ),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
