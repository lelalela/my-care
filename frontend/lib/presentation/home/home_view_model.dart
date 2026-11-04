import 'package:flutter/foundation.dart';
import '../../data/repository/prescription_repository.dart';
import '../../domain/model/condition_type.dart';
import '../../domain/model/prescription.dart';

class HomeState {
  const HomeState({
    required this.conditions,
    required this.environment,
    this.prescription,
    this.isLoading = false,
  });

  final Set<ConditionType> conditions;
  final ExerciseEnvironment environment;
  final WorkoutPrescription? prescription;
  final bool isLoading;

  HomeState copyWith({
    Set<ConditionType>? conditions,
    ExerciseEnvironment? environment,
    WorkoutPrescription? prescription,
    bool? isLoading,
  }) {
    return HomeState(
      conditions: conditions ?? this.conditions,
      environment: environment ?? this.environment,
      prescription: prescription ?? this.prescription,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

sealed class HomeAction {
  const HomeAction();
}

final class LoadPrescriptionAction extends HomeAction {
  const LoadPrescriptionAction();
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required Set<ConditionType> initialConditions,
    required ExerciseEnvironment initialEnvironment,
    PrescriptionRepository? repository,
  })  : _repository = repository ?? const PrescriptionRepository(),
        _state = HomeState(
          conditions: initialConditions,
          environment: initialEnvironment,
        ) {
    _loadPrescription();
  }

  final PrescriptionRepository _repository;
  HomeState _state;
  HomeState get state => _state;

  void onAction(HomeAction action) {
    switch (action) {
      case LoadPrescriptionAction():
        _loadPrescription();
    }
  }

  void _loadPrescription() {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final result = _repository.generatePrescription(
      conditions: _state.conditions,
      environment: _state.environment,
    );

    _state = _state.copyWith(
      prescription: result,
      isLoading: false,
    );
    notifyListeners();
  }
}
