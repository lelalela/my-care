import 'package:flutter/foundation.dart';
import '../../domain/model/condition_type.dart';

/// 온보딩 화면의 불변 상태(State)
class OnboardingState {
  const OnboardingState({
    this.selectedConditions = const <ConditionType>{},
    this.environment = ExerciseEnvironment.all,
    this.isSubmitting = false,
  });

  final Set<ConditionType> selectedConditions;
  final ExerciseEnvironment environment;
  final bool isSubmitting;

  bool get canProceed => selectedConditions.isNotEmpty;

  /// 복수 질환 선택 시 실시간 결합 처방 하이라이트 요약
  List<String> get clinicalHighlights {
    if (selectedConditions.isEmpty) return const [];
    final highlights = <String>[];

    if (selectedConditions.contains(ConditionType.prediabetes)) {
      highlights.add('식후 30~60분 이내 걷기 골든타임 적용');
    }
    if (selectedConditions.contains(ConditionType.fattyLiver)) {
      highlights.add('내장지방 산화를 위한 40분 이상 지속 유산소 권장');
    }
    if (selectedConditions.contains(ConditionType.hypertension)) {
      highlights.add('발살바 호흡 차단 및 안전한 머신 서킷 우선');
    }
    if (selectedConditions.contains(ConditionType.dyslipidemia)) {
      highlights.add('지질 대사 개선을 위한 중강도 인터벌 세팅');
    }
    if (selectedConditions.contains(ConditionType.obesity)) {
      highlights.add('체중 부하를 분산하는 저충격 관절 보호 모드');
    }
    if (selectedConditions.contains(ConditionType.gout)) {
      highlights.add('젖산 축적 방지를 위해 저~중등도 강도 유지');
    }

    return highlights;
  }

  OnboardingState copyWith({
    Set<ConditionType>? selectedConditions,
    ExerciseEnvironment? environment,
    bool? isSubmitting,
  }) {
    return OnboardingState(
      selectedConditions: selectedConditions ?? this.selectedConditions,
      environment: environment ?? this.environment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// 온보딩 화면의 이벤트 액션
sealed class OnboardingAction {
  const OnboardingAction();
}

final class ToggleConditionAction extends OnboardingAction {
  const ToggleConditionAction(this.condition);
  final ConditionType condition;
}

final class SelectEnvironmentAction extends OnboardingAction {
  const SelectEnvironmentAction(this.environment);
  final ExerciseEnvironment environment;
}

final class SubmitOnboardingAction extends OnboardingAction {
  const SubmitOnboardingAction();
}

/// MVI 패턴의 Onboarding ViewModel (ChangeNotifier 기반)
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({OnboardingState initialState = const OnboardingState()})
      : _state = initialState;

  OnboardingState _state;
  OnboardingState get state => _state;

  void onAction(OnboardingAction action) {
    switch (action) {
      case ToggleConditionAction(:final condition):
        final updated = Set<ConditionType>.from(_state.selectedConditions);
        if (updated.contains(condition)) {
          updated.remove(condition);
        } else {
          updated.add(condition);
        }
        _state = _state.copyWith(selectedConditions: updated);
        notifyListeners();

      case SelectEnvironmentAction(:final environment):
        _state = _state.copyWith(environment: environment);
        notifyListeners();

      case SubmitOnboardingAction():
        // 제출 및 처방 대시보드로 이동 준비
        _state = _state.copyWith(isSubmitting: true);
        notifyListeners();
    }
  }
}
