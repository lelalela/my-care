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
    this.defaultTargetSets = 3,
    this.customExerciseSets = const <String, int>{},
    this.aerobicType = 'walking',
    this.selectedExerciseNames,
    this.isLoading = false,
  });

  final Set<ConditionType> conditions;
  final ExerciseEnvironment environment;
  final WorkoutPrescription? prescription;
  final int streakDays;
  final Set<int> completedWeekdays;
  final int weeklyMinutes;
  final List<WorkoutRecord> records;
  final int defaultTargetSets;
  final Map<String, int> customExerciseSets;
  final String aerobicType;
  final Set<String>? selectedExerciseNames;
  final bool isLoading;

  int getTargetSetsFor(String exerciseName) {
    return customExerciseSets[exerciseName] ?? defaultTargetSets;
  }

  HomeState copyWith({
    Set<ConditionType>? conditions,
    ExerciseEnvironment? environment,
    WorkoutPrescription? prescription,
    int? streakDays,
    Set<int>? completedWeekdays,
    int? weeklyMinutes,
    List<WorkoutRecord>? records,
    int? defaultTargetSets,
    Map<String, int>? customExerciseSets,
    String? aerobicType,
    Set<String>? selectedExerciseNames,
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
      defaultTargetSets: defaultTargetSets ?? this.defaultTargetSets,
      customExerciseSets: customExerciseSets ?? this.customExerciseSets,
      aerobicType: aerobicType ?? this.aerobicType,
      selectedExerciseNames:
          selectedExerciseNames ?? this.selectedExerciseNames,
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

final class UpdateGlobalTargetSetsAction extends HomeAction {
  const UpdateGlobalTargetSetsAction(this.targetSets);
  final int targetSets;
}

final class UpdateExerciseTargetSetsAction extends HomeAction {
  const UpdateExerciseTargetSetsAction({
    required this.exerciseName,
    required this.targetSets,
    required this.applyToAll,
  });
  final String exerciseName;
  final int targetSets;
  final bool applyToAll;
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required Set<ConditionType> initialConditions,
    required ExerciseEnvironment initialEnvironment,
    Set<String>? selectedExerciseNames,
    String aerobicType = 'walking',
    this._aerobicDurationMinutes,
    this._aerobicTargetSpm,
    int targetSets = 3,
    PrescriptionRepository? repository,
    WorkoutHistoryRepository? historyRepository,
  })  : _repository = repository ?? const PrescriptionRepository(),
        _historyRepository =
            historyRepository ?? const WorkoutHistoryRepository(),
        _state = HomeState(
          conditions: initialConditions,
          environment: initialEnvironment,
          selectedExerciseNames: selectedExerciseNames,
          aerobicType: aerobicType,
          defaultTargetSets: targetSets,
        ) {
    _loadPrescription();
    _loadHistory();
  }

  final PrescriptionRepository _repository;
  final WorkoutHistoryRepository _historyRepository;
  final int? _aerobicDurationMinutes;
  final int? _aerobicTargetSpm;
  HomeState _state;
  HomeState get state => _state;

  void onAction(HomeAction action) {
    switch (action) {
      case LoadPrescriptionAction():
        _loadPrescription();
      case RefreshHistoryAction():
        _loadHistory();
      case UpdateGlobalTargetSetsAction(:final targetSets):
        _state = _state.copyWith(
          defaultTargetSets: targetSets,
          customExerciseSets: {},
        );
        notifyListeners();
      case UpdateExerciseTargetSetsAction(
          :final exerciseName,
          :final targetSets,
          :final applyToAll
        ):
        if (applyToAll) {
          _state = _state.copyWith(
            defaultTargetSets: targetSets,
            customExerciseSets: {},
          );
        } else {
          final updated = Map<String, int>.from(_state.customExerciseSets);
          updated[exerciseName] = targetSets;
          _state = _state.copyWith(customExerciseSets: updated);
        }
        notifyListeners();
    }
  }

  Future<void> _loadPrescription() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final result = await _repository.getPrescription(
      conditions: _state.conditions,
      environment: _state.environment,
      selectedExerciseNames: _state.selectedExerciseNames,
      aerobicType: _state.aerobicType,
      customAerobicDuration: _aerobicDurationMinutes,
      customAerobicCadence: _aerobicTargetSpm,
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

  Future<void> logStrengthWorkout(PrescribedExercise exercise, [int completedSets = 3]) async {
    final now = DateTime.now();
    // 세트 수에 비례한 운동 시간 산출 (세트당 약 3분)
    final duration = (completedSets * 3).clamp(5, 60);
    final calories = completedSets * 12;

    final record = WorkoutRecord(
      id: 'strength_${now.millisecondsSinceEpoch}',
      completedAt: now,
      durationMinutes: duration,
      steps: 0,
      calories: calories,
      spm: 0,
      conditions: _state.conditions.map((c) => c.name).toList(),
    );
    await _historyRepository.saveRecord(record);
    await _loadHistory();
  }
}
