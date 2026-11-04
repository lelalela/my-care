import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WalkingState {
  const WalkingState({
    required this.targetSpm,
    required this.targetDurationMinutes,
    this.elapsedSeconds = 0,
    this.isActive = true,
    this.isCompleted = false,
  });

  final int targetSpm;
  final int targetDurationMinutes;
  final int elapsedSeconds;
  final bool isActive;
  final bool isCompleted;

  int get targetSeconds => targetDurationMinutes * 60;
  int get remainingSeconds => (targetSeconds - elapsedSeconds).clamp(0, targetSeconds);
  double get progress => targetSeconds > 0 ? (elapsedSeconds / targetSeconds).clamp(0.0, 1.0) : 0.0;

  // 추정 걸음 수 및 소비 칼로리 (표준 대사량 기준)
  int get estimatedSteps => ((elapsedSeconds * targetSpm) / 60).round();
  int get estimatedCalories => (estimatedSteps * 0.038).round();

  String get formattedElapsed {
    final m = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get formattedRemaining {
    final m = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  WalkingState copyWith({
    int? targetSpm,
    int? targetDurationMinutes,
    int? elapsedSeconds,
    bool? isActive,
    bool? isCompleted,
  }) {
    return WalkingState(
      targetSpm: targetSpm ?? this.targetSpm,
      targetDurationMinutes: targetDurationMinutes ?? this.targetDurationMinutes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

sealed class WalkingAction {
  const WalkingAction();
}

final class TogglePlayPauseAction extends WalkingAction {
  const TogglePlayPauseAction();
}

final class AdjustSpmAction extends WalkingAction {
  const AdjustSpmAction(this.delta);
  final int delta; // e.g. +5 or -5
}

final class AdjustDurationAction extends WalkingAction {
  const AdjustDurationAction(this.deltaMinutes);
  final int deltaMinutes; // e.g. +10 or -10
}

final class TickAction extends WalkingAction {
  const TickAction();
}

final class FinishWalkingAction extends WalkingAction {
  const FinishWalkingAction();
}

class WalkingViewModel extends ChangeNotifier {
  WalkingViewModel({
    required int initialSpm,
    required int initialDurationMinutes,
  }) : _state = WalkingState(
          targetSpm: initialSpm,
          targetDurationMinutes: initialDurationMinutes,
        ) {
    _startTimer();
  }

  WalkingState _state;
  WalkingState get state => _state;
  Timer? _timer;

  void onAction(WalkingAction action) {
    switch (action) {
      case TogglePlayPauseAction():
        if (_state.isActive) {
          _timer?.cancel();
          _state = _state.copyWith(isActive: false);
        } else {
          _startTimer();
          _state = _state.copyWith(isActive: true);
        }
        notifyListeners();

      case AdjustSpmAction(:final delta):
        final newSpm = (_state.targetSpm + delta).clamp(80, 160);
        _state = _state.copyWith(targetSpm: newSpm);
        HapticFeedback.selectionClick();
        notifyListeners();

      case AdjustDurationAction(:final deltaMinutes):
        final newDuration = (_state.targetDurationMinutes + deltaMinutes).clamp(10, 120);
        _state = _state.copyWith(targetDurationMinutes: newDuration);
        HapticFeedback.selectionClick();
        notifyListeners();

      case TickAction():
        final newElapsed = _state.elapsedSeconds + 1;
        final completed = newElapsed >= _state.targetSeconds;
        if (completed && !_state.isCompleted) {
          _timer?.cancel();
          _state = _state.copyWith(
            elapsedSeconds: newElapsed,
            isActive: false,
            isCompleted: true,
          );
        } else {
          _state = _state.copyWith(elapsedSeconds: newElapsed);
        }
        notifyListeners();

      case FinishWalkingAction():
        _timer?.cancel();
        _state = _state.copyWith(isActive: false, isCompleted: true);
        notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      onAction(const TickAction());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
