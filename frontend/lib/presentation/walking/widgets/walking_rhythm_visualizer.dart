import 'package:flutter/material.dart';
import '../../../ui/app_colors.dart';

/// 현재 SPM 주기에 맞춰 부드럽게 펄스(박자)를 시각화하는 메트로놈 위젯
class WalkingRhythmVisualizer extends StatefulWidget {
  const WalkingRhythmVisualizer({
    super.key,
    required this.spm,
    required this.isActive,
  });

  final int spm;
  final bool isActive;

  @override
  State<WalkingRhythmVisualizer> createState() => _WalkingRhythmVisualizerState();
}

class _WalkingRhythmVisualizerState extends State<WalkingRhythmVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    // 1회 박동 시간(초) = 60 / SPM
    final beatDurationMs = (60000 / widget.spm).round();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: beatDurationMs),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant WalkingRhythmVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spm != widget.spm) {
      final beatDurationMs = (60000 / widget.spm).round();
      _pulseController.duration = Duration(milliseconds: beatDurationMs);
    }
    if (widget.isActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final scale = widget.isActive ? _scaleAnimation.value : 1.0;
        final speedKmh = (widget.spm * 0.045).toStringAsFixed(1);

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 바깥쪽 부드러운 펄스 링
              Container(
                width: 250 * scale,
                height: 250 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
              // 안쪽 메인 비트 원
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainer,
                  border: Border.all(
                    color: widget.isActive
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: widget.isActive ? 0.15 : 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 26,
                      color: widget.isActive
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.spm}',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: widget.isActive
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SPM (분당 걸음수)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: widget.isActive
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.isActive
                            ? AppColors.primaryContainer.withValues(alpha: 0.6)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '예상 속도 약 $speedKmh km/h',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.isActive
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
