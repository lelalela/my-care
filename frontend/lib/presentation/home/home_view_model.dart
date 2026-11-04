import 'package:flutter/foundation.dart';
import '../../data/repository/prescription_repository.dart';
import '../../data/repository/workout_history_repository.dart';
import '../../domain/model/condition_type.dart';
import '../../domain/model/prescription.dart';
import '../../domain/model/workout_record.dart';

class HomeState {
  const HomeState({
    required this.conditions,
    required this.environment,
    this.prescription,
    this.streakDays = 0,
    this.completedWeekdays = const <int>{},
    this.weeklyMinutes = 0,
    this.records = const <WorkoutRecord>[],
    this.isLoading = false,
  });

  final Set<ConditionType> conditions;
  final ExerciseEnvironment environment;
  final WorkoutPrescription? prescription;
  final int streakDays;
  final Set<int> completedWeekdays;
  final int weeklyMinutes;
  final List<WorkoutRecord> records;
  final bool isLoading;

  HomeState copyWith({
    Set<ConditionType>? conditions,
    ExerciseEnvironment? environment,
    WorkoutPrescription? prescription,
    int? streakDays,
    Set<int>? completedWeekdays,
    int? weeklyMinutes,
    List<WorkoutRecord>? records,
    bool? isLoading,
  }) {
    return HomeState(
      conditions: conditions ?? this.conditions,
      environment: environment ?? this.environment,
      prescription: prescription ?? this.prescription,
      streakDays: streakDays ?? this.streakDays,
      completedWeekdays: completedWeekdays ?? this.completedWeekdays,
      weeklyMinutes: weeklyMinutes ?? this.weeklyMinutes,
      records: records ?? this.records,
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

final class RefreshHistoryAction extends HomeAction {
  const RefreshHistoryAction();
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required Set<ConditionType> initialConditions,
    required ExerciseEnvironment initialEnvironment,
    PrescriptionRepository? repository,
    WorkoutHistoryRepository? historyRepository,
  })  : _repository = repository ?? const PrescriptionRepository(),
        _historyRepository = historyRepository ?? const WorkoutHistoryRepository(),
        _state = HomeState(
          conditions: initialConditions,
          environment: initialEnvironment,
        ) {
    _loadPrescription();
    _loadHistory();
  }

  final PrescriptionRepository _repository;
  final WorkoutHistoryRepository _historyRepository;
  HomeState _state;
  HomeState get state => _state;

  void onAction(HomeAction action) {
    switch (action) {
      case LoadPrescriptionAction():
        _loadPrescription();
      case RefreshHistoryAction():
        _loadHistory();
    }
  }

  Future<void> _loadPrescription() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final result = await _repository.getPrescription(
      conditions: _state.conditions,
      environment: _state.environment,
    );

    _state = _state.copyWith(
      prescription: result,
      isLoading: false,
    );
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final streak = await _historyRepository.getStreak();
    final weekdays = await _historyRepository.getWeeklyCompletedDays();
    final minutes = await _historyRepository.getWeeklyTotalMinutes();
    final records = await _historyRepository.getRecords();

    _state = _state.copyWith(
      streakDays: streak,
      completedWeekdays: weekdays,
      weeklyMinutes: minutes,
      records: records,
    );
    notifyListeners();
  }

  Future<void> logStrengthWorkout(PrescribedExercise exercise) async {
    final now = DateTime.now();
    final record = WorkoutRecord(
      id: 'strength_${now.millisecondsSinceEpoch}',
      completedAt: now,
      durationMinutes: 10,
      steps: 0,
      calories: 35,
      spm: 0,
      conditions: _state.conditions.map((c) => c.name).toList(),
    );
    await _historyRepository.saveRecord(record);
    await _loadHistory();
  }
}
