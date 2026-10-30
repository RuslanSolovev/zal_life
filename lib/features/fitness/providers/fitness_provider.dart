// features/fitness/providers/fitness_provider.dart
// 🆕 v17: format-aware агрегация + format-aware addExerciseToDay
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/fitness_database.dart';
import '../models/fitness_models.dart';
import '../models/enums.dart';
import '../models/helpers.dart';

class FitnessProvider extends ChangeNotifier {
  final FitnessDatabase _db = FitnessDatabase();
  final Uuid _uuid = const Uuid();

  List<Exercise> _exercises = [];
  List<WorkoutProgram> _programs = [];
  List<WorkoutLog> _logs = [];
  List<ProgressRecord> _progressRecords = [];
  UserFitnessProfile? _profile;
  List<WorkoutTemplate> _templates = [];
  List<FitnessPhoto> _photos = [];
  List<WellbeingNote> _wellbeingNotes = [];

  // 🔥 v7: Сессии прохождения программ
  List<ProgramSession> _sessions = [];

  // 🔥 v8: Фитнес-цели
  List<FitnessTarget> _targets = [];

  WorkoutDay? _activeWorkoutDay;
  WorkoutLog? _activeWorkoutLog;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  bool _isWorkoutActive = false;
  DateTime? _workoutStartTime;
  Duration _totalRestTime = Duration.zero;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isRestTimerActive = false;

  // ============================================================
  // ГЕТТЕРЫ
  // ============================================================

  List<Exercise> get exercises => _exercises;
  List<WorkoutProgram> get programs => _programs;
  List<WorkoutLog> get logs => _logs;
  List<ProgressRecord> get progressRecords => _progressRecords;
  UserFitnessProfile? get profile => _profile;
  List<WorkoutTemplate> get templates => _templates;
  List<FitnessPhoto> get photos => _photos;
  List<WellbeingNote> get wellbeingNotes => _wellbeingNotes;

  // 🔥 v7: Геттеры для сессий
  List<ProgramSession> get sessions => _sessions;

  // 🔥 v8: Геттеры для целей
  List<FitnessTarget> get targets => _targets;
  List<FitnessTarget> get activeTargets =>
      _targets.where((t) => t.status == FitnessTargetStatus.active).toList();
  List<FitnessTarget> get completedTargets =>
      _targets.where((t) => t.status == FitnessTargetStatus.completed).toList();

  ProgramSession? get activeSession {
    try {
      return _sessions
          .firstWhere((s) => s.status == ProgramSessionStatus.active);
    } catch (_) {
      return null;
    }
  }

  List<ProgramSession> get completedSessions =>
      _sessions.where((s) => s.status == ProgramSessionStatus.completed).toList();

  WorkoutDay? get activeWorkoutDay => _activeWorkoutDay;
  WorkoutLog? get activeWorkoutLog => _activeWorkoutLog;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get currentSetIndex => _currentSetIndex;
  bool get isWorkoutActive => _isWorkoutActive;
  DateTime? get workoutStartTime => _workoutStartTime;
  Duration get totalRestTime => _totalRestTime;
  int get restSecondsRemaining => _restSecondsRemaining;
  bool get isRestTimerActive => _isRestTimerActive;

  WorkoutExercise? get currentExercise {
    if (_activeWorkoutDay == null ||
        _currentExerciseIndex >= _activeWorkoutDay!.exercises.length) {
      return null;
    }
    return _activeWorkoutDay!.exercises[_currentExerciseIndex];
  }

  ExerciseSet? get currentSet {
    final exercise = currentExercise;
    if (exercise == null || _currentSetIndex >= exercise.sets.length) {
      return null;
    }
    return exercise.sets[_currentSetIndex];
  }

  // ============================================================
  // ИНИЦИАЛИЗАЦИЯ И ЗАГРУЗКА
  // ============================================================

  Future<void> init() async {
    debugPrint('🏋️ Инициализация FitnessProvider...');
    await Future.wait([
      _loadExercises(),
      _loadPrograms(),
      _loadLogs(),
      _loadProgress(),
      _loadProfile(),
      _loadTemplates(),
      _loadPhotos(),
      _loadWellbeingNotes(),
      _loadSessions(),
      _loadTargets(),
    ]);
    debugPrint('✅ FitnessProvider инициализирован');
    debugPrint(
        '📋 Сессий программ: ${_sessions.length}, активных: ${activeSession != null ? 1 : 0}');
    debugPrint(
        '🎯 Целей: ${_targets.length}, активных: ${activeTargets.length}');
    notifyListeners();
  }

  Future<void> _loadExercises() async {
    final data = await _db.query('exercises', orderBy: 'name ASC');
    _exercises = data.map((e) => Exercise.fromMap(e)).toList();
  }

  Future<void> _loadPrograms() async {
    final data =
    await _db.query('workout_programs', orderBy: 'createdAt DESC');
    _programs = [];
    for (final p in data) {
      final program = WorkoutProgram.fromMap(p);
      final daysData = await _db.query('workout_days',
          where: 'programId = ?',
          whereArgs: [program.id],
          orderBy: 'dayNumber ASC');
      program.days.clear();
      program.days.addAll(daysData.map((d) => WorkoutDay.fromMap(d)));
      _programs.add(program);
    }
    debugPrint('📋 Загружено программ: ${_programs.length}');
  }

  Future<void> _loadLogs() async {
    final data =
    await _db.query('workout_logs', orderBy: 'date DESC', limit: 1000);
    _logs = data.map((l) => WorkoutLog.fromMap(l)).toList();
  }

  Future<void> _loadProgress() async {
    final data = await _db.query('progress_records', orderBy: 'date ASC');
    _progressRecords = data.map((p) => ProgressRecord.fromMap(p)).toList();
    debugPrint('📊 Загружено записей прогресса: ${_progressRecords.length}');
  }

  Future<void> _loadProfile() async {
    final data = await _db.query('user_fitness_profile', limit: 1);
    if (data.isNotEmpty) {
      _profile = UserFitnessProfile.fromMap(data.first);
    }
  }

  Future<void> _loadTemplates() async {
    final data = await _db.query('workout_templates', orderBy: 'name ASC');
    _templates = data.map((t) => WorkoutTemplate.fromMap(t)).toList();
  }

  Future<void> _loadPhotos() async {
    final data = await _db.query('fitness_photos', orderBy: 'date DESC');
    _photos = data.map((p) => FitnessPhoto.fromMap(p)).toList();
  }

  Future<void> _loadWellbeingNotes() async {
    final data = await _db.query('wellbeing_notes', orderBy: 'date DESC');
    _wellbeingNotes = data.map((n) => WellbeingNote.fromMap(n)).toList();
  }

  Future<void> _loadSessions() async {
    final data = await _db.query('program_sessions', orderBy: 'startDate DESC');
    _sessions = data.map((s) => ProgramSession.fromMap(s)).toList();
  }

  Future<void> _loadTargets() async {
    final data = await _db.query('fitness_targets', orderBy: 'createdAt DESC');
    _targets = data.map((t) => FitnessTarget.fromMap(t)).toList();
  }

  // ============================================================
  // ПРОФИЛЬ
  // ============================================================

  Future<void> createProfile(UserFitnessProfile profile) async {
    await _db.insert('user_fitness_profile', profile.toMap());
    _profile = profile;
    notifyListeners();
  }

  Future<void> updateProfile(UserFitnessProfile profile) async {
    await _db.update('user_fitness_profile', profile.toMap(),
        where: 'id = ?', whereArgs: [profile.id]);
    _profile = profile;
    await _updateTargetsProgress();
    notifyListeners();
  }

  Future<void> addBodyWeight(double weight) async {
    if (_profile == null) {
      await createProfile(UserFitnessProfile(id: _uuid.v4()));
    }
    final entry = BodyWeightEntry(date: DateTime.now(), weight: weight);
    final updatedHistory = List<BodyWeightEntry>.from(_profile!.bodyWeightHistory)
      ..add(entry);
    final updatedProfile =
    _profile!.copyWith(bodyWeightHistory: updatedHistory);
    await updateProfile(updatedProfile);
    await _updateTargetsProgress();
  }

  // ============================================================
  // УПРАЖНЕНИЯ
  // ============================================================

  Future<Exercise> addExercise({
    required String name,
    String description = '',
    List<MuscleGroup> muscleGroups = const [],
    String? imageUrl,
    ExerciseType exerciseType = ExerciseType.strength,
    String? videoUrl,
    String? techniqueTips,
    String? commonMistakes,
    ExerciseFormat? defaultFormat,
  }) async {
    final exercise = Exercise(
      id: _uuid.v4(),
      name: name,
      description: description,
      muscleGroups: muscleGroups,
      imageUrl: imageUrl,
      exerciseType: exerciseType,
      isCustom: true,
      videoUrl: videoUrl,
      techniqueTips: techniqueTips,
      commonMistakes: commonMistakes,
      defaultFormat: defaultFormat,
    );
    await _db.insert('exercises', exercise.toMap());
    _exercises.add(exercise);
    _exercises.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return exercise;
  }

  Future<void> updateExercise(Exercise exercise) async {
    await _db.update('exercises', exercise.toMap(),
        where: 'id = ?', whereArgs: [exercise.id]);
    final index = _exercises.indexWhere((e) => e.id == exercise.id);
    if (index != -1) _exercises[index] = exercise;
    notifyListeners();
  }

  Future<void> deleteExercise(String id) async {
    await _db.delete('exercises', where: 'id = ?', whereArgs: [id]);
    _exercises.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<Exercise> getExercisesByMuscle(MuscleGroup muscle) {
    return _exercises.where((e) => e.muscleGroups.contains(muscle)).toList();
  }

  List<Exercise> searchExercises(String query) {
    final lower = query.toLowerCase();
    return _exercises
        .where((e) =>
    e.name.toLowerCase().contains(lower) ||
        e.description.toLowerCase().contains(lower) ||
        e.muscleGroups
            .any((m) => m.displayName.toLowerCase().contains(lower)))
        .toList();
  }

  List<Exercise> filterExercises(
      {List<MuscleGroup>? muscles, ExerciseType? type, bool? isCustom}) {
    return _exercises.where((e) {
      if (muscles != null && !e.muscleGroups.any((m) => muscles.contains(m))) {
        return false;
      }
      if (type != null && e.exerciseType != type) return false;
      if (isCustom != null && e.isCustom != isCustom) return false;
      return true;
    }).toList();
  }

  // ============================================================
  // ПРОГРАММЫ
  // ============================================================

  Future<WorkoutProgram> createProgram({
    required String name,
    ProgramType type = ProgramType.weekly,
    String? description,
  }) async {
    final program = WorkoutProgram(
        id: _uuid.v4(), name: name, type: type, description: description);
    await _db.insert('workout_programs', program.toMap());
    _programs.insert(0, program);
    notifyListeners();
    return program;
  }

  Future<void> updateProgram(WorkoutProgram program) async {
    await _db.update('workout_programs', program.toMap(),
        where: 'id = ?', whereArgs: [program.id]);

    await _db.delete('workout_days',
        where: 'programId = ?', whereArgs: [program.id]);

    for (final day in program.days) {
      final dayToSave = day.programId == program.id
          ? day
          : day.copyWith(programId: program.id);
      await _db.insert('workout_days', dayToSave.toMap());
    }

    final index = _programs.indexWhere((p) => p.id == program.id);
    if (index != -1) {
      _programs[index] = program;
    }

    notifyListeners();

    debugPrint(
        '✅ Программа обновлена: "${program.name}", дней: ${program.days.length}, упражнений: ${program.days.fold<int>(0, (s, d) => s + d.exercises.length)}');
  }

  Future<void> deleteProgram(String id) async {
    await _db.delete('workout_days', where: 'programId = ?', whereArgs: [id]);
    await _db.delete('workout_programs', where: 'id = ?', whereArgs: [id]);
    _programs.removeWhere((p) => p.id == id);
    notifyListeners();
    debugPrint('🗑️ Программа удалена: $id');
  }

  Future<WorkoutDay> addDayToProgram({
    required String programId,
    int dayNumber = 1,
    DateTime? date,
    bool isRestDay = false,
    String? notes,
  }) async {
    final day = WorkoutDay(
      id: _uuid.v4(),
      programId: programId,
      dayNumber: dayNumber,
      date: date,
      isRestDay: isRestDay,
      notes: notes,
    );
    await _db.insert('workout_days', day.toMap());
    final program = _programs.firstWhere((p) => p.id == programId);
    final updatedDays = List<WorkoutDay>.from(program.days)..add(day);
    final updatedProgram = program.copyWith(days: updatedDays);
    await updateProgram(updatedProgram);
    return day;
  }

  Future<void> updateDay(WorkoutDay day) async {
    final program = _programs.firstWhere((p) => p.id == day.programId);
    final dayIndex = program.days.indexWhere((d) => d.id == day.id);
    if (dayIndex != -1) {
      final updatedDays = List<WorkoutDay>.from(program.days);
      updatedDays[dayIndex] = day;
      final updatedProgram = program.copyWith(days: updatedDays);
      await updateProgram(updatedProgram);
    }
  }

  /// 🆕 v17: format-aware добавление упражнения в день.
  ///
  /// Создаёт сеты с полями, соответствующими формату упражнения:
  /// - setsReps   → reps: 10, weight: 0
  /// - timedSets  → duration: 60, reps: 10
  /// - hold       → holdSeconds: 30, intensity: 5
  /// - intervals  → distance: 0.4, duration: 0 (заполнит пользователь)
  /// - continuous → duration: 600 (10 мин)
  /// - rounds     → rounds: 3, roundDuration: 180, restBetweenRounds: 60
  /// - freeform   → duration: 300
  Future<void> addExerciseToDay({
    required String dayId,
    required String exerciseId,
    int sets = 3,
    int reps = 10,
    double weight = 0.0,
    ExerciseGroupType groupType = ExerciseGroupType.straight,
    int? groupId,
    int? restBetweenSeconds,
  }) async {
    final program =
    _programs.firstWhere((p) => p.days.any((d) => d.id == dayId));
    final day = program.days.firstWhere((d) => d.id == dayId);

    // 🆕 Резолвим формат по данным упражнения
    final exData = _findExerciseById(exerciseId);
    final template = WorkoutExercise(
      id: '',
      exerciseId: exerciseId,
      format: null,
    );
    final format = FitnessHelpers.resolveFormat(
      template,
      exData.id.isEmpty ? null : exData,
    );

    // 🆕 Создаём сеты по формату
    final exerciseSets = List.generate(sets, (i) {
      switch (format) {
        case ExerciseFormat.setsReps:
          return ExerciseSet(
            setNumber: i + 1,
            reps: reps,
            weight: weight,
            restSeconds: restBetweenSeconds ??
                FitnessHelpers.getRecommendedRestSeconds(format),
          );

        case ExerciseFormat.timedSets:
          return ExerciseSet(
            setNumber: i + 1,
            reps: reps,
            duration: 60,
            intensity: 5,
            restSeconds: restBetweenSeconds ??
                FitnessHelpers.getRecommendedRestSeconds(format),
          );

        case ExerciseFormat.hold:
          return ExerciseSet(
            setNumber: i + 1,
            reps: 0,
            holdSeconds: 30,
            intensity: 5,
          );

        case ExerciseFormat.intervals:
          return ExerciseSet(
            setNumber: i + 1,
            distance: 0.4,
            duration: 0,
            restSeconds: restBetweenSeconds ??
                FitnessHelpers.getRecommendedRestSeconds(format),
          );

        case ExerciseFormat.continuous:
          return ExerciseSet(
            setNumber: i + 1,
            duration: 600,
          );

        case ExerciseFormat.rounds:
          return ExerciseSet(
            setNumber: i + 1,
            rounds: 3,
            roundDuration: 180,
            restBetweenRounds: restBetweenSeconds ??
                FitnessHelpers.getRecommendedRestSeconds(format),
            intensity: 7,
          );

        case ExerciseFormat.freeform:
          return ExerciseSet(
            setNumber: i + 1,
            duration: 300,
            intensity: 5,
          );
      }
    });

    final workoutExercise = WorkoutExercise(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      order: day.exercises.length,
      sets: exerciseSets,
      groupType: groupType,
      groupId: groupId,
      restBetweenSeconds: restBetweenSeconds,
      format: format, // 🆕 фиксируем формат
    );

    debugPrint(
        '➕ Упражнение $exerciseId в день $dayId: формат=$format, '
            'сетов=${exerciseSets.length}');

    final updatedExercises =
    List<WorkoutExercise>.from(day.exercises)..add(workoutExercise);
    final updatedDay = day.copyWith(exercises: updatedExercises);
    await updateDay(updatedDay);
  }

  Future<void> removeExerciseFromDay(String dayId, String exerciseId) async {
    final program =
    _programs.firstWhere((p) => p.days.any((d) => d.id == dayId));
    final day = program.days.firstWhere((d) => d.id == dayId);
    final updatedExercises =
    day.exercises.where((e) => e.id != exerciseId).toList();
    for (int i = 0; i < updatedExercises.length; i++) {
      updatedExercises[i] = updatedExercises[i].copyWith(order: i);
    }
    final updatedDay = day.copyWith(exercises: updatedExercises);
    await updateDay(updatedDay);
  }

  Future<WorkoutProgram> addFullProgram({
    required String name,
    required ProgramType type,
    required List<Map<String, dynamic>> daysData,
    String? description,
    String emoji = '💪',
    int accentColorValue = 0xFFFF6B35,
    String difficulty = 'medium',
    String goal = 'general',
    int sessionDurationMinutes = 60,
  }) async {
    final program = WorkoutProgram(
      id: _uuid.v4(),
      name: name,
      type: type,
      description: description,
      emoji: emoji,
      accentColorValue: accentColorValue,
      difficulty: difficulty,
      goal: goal,
      sessionDurationMinutes: sessionDurationMinutes,
    );
    await _db.insert('workout_programs', program.toMap());

    final days = <WorkoutDay>[];
    for (final dayData in daysData) {
      final exercisesData = dayData['exercises'];
      final List<WorkoutExercise> exercises = [];

      if (exercisesData is List) {
        for (final exData in exercisesData) {
          if (exData is WorkoutExercise) {
            exercises.add(exData);
          } else if (exData is Map) {
            final Map<String, dynamic> exMap = {};
            (exData as Map).forEach((key, value) {
              exMap[key.toString()] = value;
            });
            exercises.add(WorkoutExercise.fromMap(exMap));
          }
        }
      }

      debugPrint(
          '📋 День ${dayData['dayNumber']}: ${exercises.length} упражнений');

      final day = WorkoutDay(
        id: _uuid.v4(),
        programId: program.id,
        dayNumber: dayData['dayNumber'] ?? 1,
        isRestDay: dayData['isRestDay'] ?? false,
        notes: dayData['notes'],
        exercises: exercises,
      );

      await _db.insert('workout_days', day.toMap());
      days.add(day);
    }

    final updatedProgram = program.copyWith(days: days);
    await _db.update('workout_programs', updatedProgram.toMap(),
        where: 'id = ?', whereArgs: [program.id]);

    _programs.insert(0, updatedProgram);
    notifyListeners();

    debugPrint(
        '✅ Программа создана: ${updatedProgram.name}, дней: ${updatedProgram.days.length}');
    return updatedProgram;
  }

  Future<void> createTemplateFromProgram(
      String programId, String templateName) async {
    final program = _programs.firstWhere((p) => p.id == programId);
    final template = WorkoutTemplate(
      id: _uuid.v4(),
      name: templateName,
      description: program.description ?? '',
      type: program.type,
      days: program.days,
      category: 'custom',
    );
    await _db.insert('workout_templates', template.toMap());
    _templates.add(template);
    notifyListeners();
  }

  Future<WorkoutProgram> createProgramFromTemplate(String templateId) async {
    final template = _templates.firstWhere((t) => t.id == templateId);

    debugPrint('📋 Создание программы из шаблона: ${template.name}');
    debugPrint('📋 Дней в шаблоне: ${template.days.length}');

    final program = WorkoutProgram(
      id: _uuid.v4(),
      name: template.name,
      type: template.type,
      description: template.description,
    );
    await _db.insert('workout_programs', program.toMap());

    final days = <WorkoutDay>[];
    for (final templateDay in template.days) {
      debugPrint(
          '📋 День ${templateDay.dayNumber}: ${templateDay.exercises.length} упражнений');

      final exercises = templateDay.exercises.map((e) {
        final sets = e.sets
            .map((s) => ExerciseSet(
          setNumber: s.setNumber,
          reps: s.reps,
          weight: s.weight,
          isWarmup: s.isWarmup,
          rpe: s.rpe,
          status: SetStatus.pending,
          // 🆕 сохраняем новые метрики
          duration: s.duration,
          distance: s.distance,
          pace: s.pace,
          heartRate: s.heartRate,
          calories: s.calories,
          incline: s.incline,
          resistance: s.resistance,
          rounds: s.rounds,
          roundDuration: s.roundDuration,
          restBetweenRounds: s.restBetweenRounds,
          punches: s.punches,
          holdSeconds: s.holdSeconds,
          tempo: s.tempo,
          intensity: s.intensity,
        ))
            .toList();

        return WorkoutExercise(
          id: _uuid.v4(),
          exerciseId: e.exerciseId,
          order: e.order,
          sets: sets,
          groupType: e.groupType,
          restBetweenSeconds: e.restBetweenSeconds,
          notes: e.notes,
          format: e.format, // 🆕 сохраняем формат
        );
      }).toList();

      final day = WorkoutDay(
        id: _uuid.v4(),
        programId: program.id,
        dayNumber: templateDay.dayNumber,
        isRestDay: templateDay.isRestDay,
        notes: templateDay.notes,
        exercises: exercises,
      );

      await _db.insert('workout_days', day.toMap());
      days.add(day);
    }

    final updatedProgram = program.copyWith(days: days);
    await updateProgram(updatedProgram);

    _programs.insert(0, updatedProgram);
    notifyListeners();

    debugPrint(
        '✅ Программа создана: ${updatedProgram.name}, дней: ${updatedProgram.days.length}');
    return updatedProgram;
  }

  // ============================================================
  // АКТИВНАЯ ТРЕНИРОВКА
  // ============================================================

  Future<void> startWorkout(WorkoutDay day) async {
    _activeWorkoutDay = day;
    _currentExerciseIndex = 0;
    _currentSetIndex = 0;
    _isWorkoutActive = true;
    _workoutStartTime = DateTime.now();
    _totalRestTime = Duration.zero;
    _activeWorkoutLog = WorkoutLog(
      id: _uuid.v4(),
      date: DateTime.now(),
      programId: day.programId,
      dayNumber: day.dayNumber,
      startTime: _workoutStartTime,
      status: WorkoutDayStatus.pending,
    );
    notifyListeners();
  }

  Future<void> logSet({
    required int reps,
    required double weight,
    double? rpe,
    String? notes,
  }) async {
    if (!_isWorkoutActive || currentExercise == null || currentSet == null) {
      return;
    }
    final updatedSet = currentSet!.copyWith(
        reps: reps,
        weight: weight,
        rpe: rpe,
        status: SetStatus.completed,
        notes: notes);
    final day = _activeWorkoutDay!;
    final exercises = List<WorkoutExercise>.from(day.exercises);
    final exercise = exercises[_currentExerciseIndex];
    final sets = List<ExerciseSet>.from(exercise.sets);
    sets[_currentSetIndex] = updatedSet;
    exercises[_currentExerciseIndex] = exercise.copyWith(sets: sets);
    _activeWorkoutDay = day.copyWith(exercises: exercises);
    _activeWorkoutLog = _activeWorkoutLog!.copyWith(exercisesLog: exercises);
    _startRestTimer(exercise.restBetweenSeconds ?? 90);
    notifyListeners();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    _restSecondsRemaining = seconds;
    _isRestTimerActive = true;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        _restSecondsRemaining--;
        _totalRestTime += const Duration(seconds: 1);
        notifyListeners();
      } else {
        timer.cancel();
        _isRestTimerActive = false;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void skipRest() {
    _restTimer?.cancel();
    _restSecondsRemaining = 0;
    _isRestTimerActive = false;
    notifyListeners();
  }

  Future<void> nextSet() async {
    if (!_isWorkoutActive || currentExercise == null) return;
    final exercise = currentExercise!;
    if (_currentSetIndex < exercise.sets.length - 1) {
      _currentSetIndex++;
    } else {
      _currentSetIndex = 0;
      _currentExerciseIndex++;
    }
    notifyListeners();
  }

  Future<void> skipExercise() async {
    if (!_isWorkoutActive) return;
    _currentSetIndex = 0;
    _currentExerciseIndex++;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 ХЕЛПЕРЫ (используются format-aware методами ниже)
  // ══════════════════════════════════════════════════════════

  /// Находит Exercise по id (или заглушку). Нужно для резолвинга формата.
  Exercise _findExerciseById(String id) {
    return _exercises.firstWhere(
          (e) => e.id == id,
      orElse: () => Exercise(id: '', name: 'Удалено'),
    );
  }

  /// Складывает две карты метрик поключево.
  Map<String, double> _mergeMetrics(
      Map<String, double> a,
      Map<String, double> b,
      ) {
    final result = Map<String, double>.from(a);
    b.forEach((k, v) {
      result[k] = (result[k] ?? 0) + v;
    });
    return result;
  }

  /// Строит ProgressRecord по формату упражнения.
  /// Для силовых — bestWeight / 1RM / volume.
  /// Для кардио — bestDistance / bestPace / bestDuration.
  /// Для бокса — bestRounds (сумма раундов за тренировку).
  /// Для статики — bestHoldSeconds (лучшее удержание, max).
  ProgressRecord _buildProgressRecord({
    required String exerciseId,
    required DateTime date,
    required List<ExerciseSet> completedSets,
    required ExerciseFormat format,
  }) {
    final rpeValues =
    completedSets.where((s) => s.rpe != null).map((s) => s.rpe!).toList();
    final avgRpe = rpeValues.isNotEmpty
        ? rpeValues.reduce((a, b) => a + b) / rpeValues.length
        : null;

    switch (format) {
      case ExerciseFormat.setsReps:
        ExerciseSet bestSet = completedSets.first;
        for (final set in completedSets) {
          if (set.volume > bestSet.volume) bestSet = set;
        }
        final estimated1RM =
        FitnessHelpers.calculate1RM(bestSet.weight, bestSet.reps);
        final totalVolume =
        completedSets.fold(0.0, (sum, s) => sum + s.volume);
        return ProgressRecord(
          id: _uuid.v4(),
          exerciseId: exerciseId,
          date: date,
          bestWeight: bestSet.weight,
          bestReps: bestSet.reps,
          estimated1RM: estimated1RM,
          totalVolume: totalVolume,
          totalSets: completedSets.length,
          avgRpe: avgRpe,
        );

      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        final totalDur = completedSets.fold<int>(
          0,
              (sum, s) => sum + (s.effectiveDuration ?? 0),
        );
        return ProgressRecord(
          id: _uuid.v4(),
          exerciseId: exerciseId,
          date: date,
          bestDuration: totalDur > 0 ? totalDur : null,
          totalSets: completedSets.length,
          avgRpe: avgRpe,
        );

      case ExerciseFormat.intervals:
      case ExerciseFormat.continuous:
        final totalDist = completedSets.fold<double>(
          0,
              (sum, s) => sum + (s.distance ?? 0),
        );
        final totalDur = completedSets.fold<int>(
          0,
              (sum, s) => sum + (s.duration ?? 0),
        );
        final paces = completedSets
            .where((s) => s.pace != null && s.pace! > 0)
            .map((s) => s.pace!)
            .toList();
        final bestPace =
        paces.isNotEmpty ? paces.reduce((a, b) => a < b ? a : b) : null;
        return ProgressRecord(
          id: _uuid.v4(),
          exerciseId: exerciseId,
          date: date,
          bestDistance: totalDist > 0 ? totalDist : null,
          bestDuration: totalDur > 0 ? totalDur : null,
          bestPace: bestPace,
          totalSets: completedSets.length,
          avgRpe: avgRpe,
        );

      case ExerciseFormat.rounds:
        final totalRounds = completedSets.fold<int>(
          0,
              (sum, s) => sum + (s.rounds ?? 0),
        );
        return ProgressRecord(
          id: _uuid.v4(),
          exerciseId: exerciseId,
          date: date,
          bestRounds: totalRounds > 0 ? totalRounds : null,
          totalSets: completedSets.length,
          avgRpe: avgRpe,
        );

      case ExerciseFormat.hold:
        int maxHold = 0;
        for (final s in completedSets) {
          final h = s.effectiveHoldSeconds ?? 0;
          if (h > maxHold) maxHold = h;
        }
        return ProgressRecord(
          id: _uuid.v4(),
          exerciseId: exerciseId,
          date: date,
          bestHoldSeconds: maxHold > 0 ? maxHold : null,
          totalSets: completedSets.length,
          avgRpe: avgRpe,
        );
    }
  }

  // ══════════════════════════════════════════════════════════
  // ЗАВЕРШЕНИЕ ТРЕНИРОВКИ
  // ══════════════════════════════════════════════════════════

  Future<WorkoutLog> finishWorkout(
      {String? comment, String? bodyWeight}) async {
    if (!_isWorkoutActive) throw Exception('Нет активной тренировки');
    final endTime = DateTime.now();
    final exercises = _activeWorkoutDay!.exercises;

    // 🆕 Агрегируем все метрики (кг / км / сек / раунды / удары / ккал)
    final totalByMetric = FitnessHelpers.calculateTotalByMetric(
      exercises,
      findExercise: _findExerciseById,
    );
    // 🆕 Тоннаж (кг) — только для силовых форматов
    final totalVolume = totalByMetric['kg'] ?? 0.0;
    final avgRpe = FitnessHelpers.calculateAverageRpe(exercises);

    final completedLog = _activeWorkoutLog!.copyWith(
      status: WorkoutDayStatus.completed,
      comment: comment,
      endTime: endTime,
      exercisesLog: exercises,
      totalRestTime: _totalRestTime,
      totalVolume: totalVolume, // legacy
      totalByMetric: totalByMetric, // 🆕
      avgRpe: avgRpe,
      bodyWeight: bodyWeight,
    );
    await _db.insert('workout_logs', completedLog.toMap());
    _logs.insert(0, completedLog);
    await _updateProgress(exercises);
    final day = _activeWorkoutDay!;
    await updateDay(day.copyWith(status: WorkoutDayStatus.completed));

    await _updateSessionAfterWorkout(totalByMetric, avgRpe); // 🆕
    await _updateTargetsProgress();

    _resetWorkoutState();
    notifyListeners();
    return completedLog;
  }

  Future<void> skipWorkout({String? comment}) async {
    if (!_isWorkoutActive) return;
    final skippedLog = _activeWorkoutLog!.copyWith(
        status: WorkoutDayStatus.skipped,
        comment: comment ?? 'Пропущена',
        endTime: DateTime.now());
    await _db.insert('workout_logs', skippedLog.toMap());
    _logs.insert(0, skippedLog);
    final day = _activeWorkoutDay!;
    await updateDay(day.copyWith(status: WorkoutDayStatus.skipped));

    await _skipCurrentDayInSession(comment ?? 'Пропущена');

    _resetWorkoutState();
    notifyListeners();
  }

  void _resetWorkoutState() {
    _restTimer?.cancel();
    _activeWorkoutDay = null;
    _activeWorkoutLog = null;
    _currentExerciseIndex = 0;
    _currentSetIndex = 0;
    _isWorkoutActive = false;
    _workoutStartTime = null;
    _totalRestTime = Duration.zero;
    _restSecondsRemaining = 0;
    _isRestTimerActive = false;
  }

  // ══════════════════════════════════════════════════════════
  // ПРОГРЕСС
  // ══════════════════════════════════════════════════════════

  Future<void> _updateProgress(List<WorkoutExercise> exercises) async {
    final now = DateTime.now();
    for (final exercise in exercises) {
      final completedSets = exercise.sets
          .where((s) => s.status == SetStatus.completed && !s.isWarmup)
          .toList();
      if (completedSets.isEmpty) continue;

      final exData = _findExerciseById(exercise.exerciseId);
      final format = FitnessHelpers.resolveFormat(exercise, exData);

      final record = _buildProgressRecord(
        exerciseId: exercise.exerciseId,
        date: now,
        completedSets: completedSets,
        format: format,
      );

      try {
        await _db.insert('progress_records', record.toMap());
        _progressRecords.add(record);
        debugPrint(
            '✅ Прогресс сохранён для: ${exercise.exerciseId} ($format)');
      } catch (e) {
        debugPrint('❌ Ошибка сохранения прогресса: $e');
      }
    }
    notifyListeners();
  }

  Future<void> saveWorkoutLogDirect(WorkoutLog log) async {
    try {
      // 🆕 Если totalByMetric не задан — посчитаем из exercisesLog
      final logToSave = log.totalByMetric == null
          ? log.copyWith(
        totalByMetric: FitnessHelpers.calculateTotalByMetric(
          log.exercisesLog,
          findExercise: _findExerciseById,
        ),
      )
          : log;

      await _db.insert('workout_logs', logToSave.toMap());
      _logs.insert(0, logToSave);

      await _updateProgressFromExercises(
          logToSave.exercisesLog, logToSave.date);

      await _updateSessionFromLog(logToSave);

      await _updateTargetsProgress();

      notifyListeners();
      debugPrint('✅ Лог тренировки сохранён: ${logToSave.id}');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения лога: $e');
    }
  }

  Future<void> _updateSessionFromLog(WorkoutLog log) async {
    final session = activeSession;
    if (session == null) {
      debugPrint('ℹ️ Нет активной сессии, пропускаем обновление');
      return;
    }

    if (log.programId != session.programId) {
      debugPrint('ℹ️ Лог для другой программы (${log.programId}), пропускаем');
      return;
    }

    if (log.dayNumber == null) {
      debugPrint('⚠️ У лога нет dayNumber, пропускаем');
      return;
    }

    final program = _programs.firstWhere(
          (p) => p.id == session.programId,
      orElse: () => _programs.first,
    );

    final dayIndex =
    program.days.indexWhere((d) => d.dayNumber == log.dayNumber);
    if (dayIndex == -1) {
      debugPrint('⚠️ День ${log.dayNumber} не найден в программе');
      return;
    }

    if (dayIndex != session.currentDayIndex) {
      debugPrint(
          '⚠️ Лог для дня ${log.dayNumber}, но текущий день ${session.currentDayIndex + 1}');
      return;
    }

    if (session.daySessions[dayIndex].status == DaySessionStatus.completed) {
      debugPrint('⚠️ День ${log.dayNumber} уже помечен как выполненный');
      return;
    }

    debugPrint('📊 Обновляем сессию из лога: день ${log.dayNumber}');

    final updatedDays = List<DaySession>.from(session.daySessions);
    updatedDays[dayIndex] = updatedDays[dayIndex].copyWith(
      status: DaySessionStatus.completed,
      completedAt: log.endTime ?? DateTime.now(),
      volumeDone: log.totalVolume,
      avgRpe: log.avgRpe,
    );

    int nextIndex = dayIndex + 1;
    bool isProgramComplete = nextIndex >= program.days.length;

    while (nextIndex < program.days.length &&
        program.days[nextIndex].isRestDay) {
      updatedDays[nextIndex] = updatedDays[nextIndex].copyWith(
        status: DaySessionStatus.completed,
        completedAt: DateTime.now(),
        notes: 'Автоматический день отдыха',
      );
      nextIndex++;
      if (nextIndex >= program.days.length) {
        isProgramComplete = true;
        break;
      }
    }

    if (!isProgramComplete && nextIndex < program.days.length) {
      updatedDays[nextIndex] = updatedDays[nextIndex].copyWith(
        status: DaySessionStatus.current,
      );
    }

    int newStreak = session.streak + 1;
    int newLongest =
    newStreak > session.longestStreak ? newStreak : session.longestStreak;
    final newCompleted = session.totalWorkoutsCompleted + 1;

    final newAvgRpe = log.avgRpe != null
        ? (session.averageRpe * session.totalWorkoutsCompleted + log.avgRpe!) /
        newCompleted
        : session.averageRpe;

    // 🆕 Обновляем метрики (кг / км / сек / раунды...)
    final logMetrics = log.totalByMetric ??
        (log.totalVolume != null
            ? {'kg': log.totalVolume!}
            : <String, double>{});

    final updatedSession = session.copyWith(
      currentDayIndex: isProgramComplete ? session.currentDayIndex : nextIndex,
      daySessions: updatedDays,
      streak: newStreak,
      longestStreak: newLongest,
      totalVolumeCompleted:
      session.totalVolumeCompleted + (log.totalVolume ?? 0),
      totalByMetricCompleted:
      _mergeMetrics(session.totalByMetricCompleted, logMetrics), // 🆕
      totalWorkoutsCompleted: newCompleted,
      averageRpe: newAvgRpe,
      status: isProgramComplete
          ? ProgramSessionStatus.completed
          : ProgramSessionStatus.active,
      endDate: isProgramComplete ? DateTime.now() : null,
      completedAt: isProgramComplete ? DateTime.now() : null,
    );

    await _db.update('program_sessions', updatedSession.toMap(),
        where: 'id = ?', whereArgs: [session.id]);

    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) _sessions[index] = updatedSession;

    debugPrint(
        '✅ Сессия обновлена: день ${dayIndex + 1}/${program.days.length}, серия: $newStreak, прогресс: ${(updatedSession.progressPercent * 100).toInt()}%');

    if (isProgramComplete) {
      debugPrint('🏆 Программа завершена!');
      await _generateProgramSummary(updatedSession, program);
    }
  }

  Future<void> _updateProgressFromExercises(
      List<WorkoutExercise> exercises,
      DateTime date,
      ) async {
    int savedCount = 0;
    for (final exercise in exercises) {
      final completedSets = exercise.sets
          .where((s) => s.status == SetStatus.completed && !s.isWarmup)
          .toList();
      if (completedSets.isEmpty) continue;

      final exData = _findExerciseById(exercise.exerciseId);
      final format = FitnessHelpers.resolveFormat(exercise, exData);

      final record = _buildProgressRecord(
        exerciseId: exercise.exerciseId,
        date: date,
        completedSets: completedSets,
        format: format,
      );

      try {
        await _db.insert('progress_records', record.toMap());
        _progressRecords.add(record);
        savedCount++;
      } catch (e) {
        debugPrint('❌ Ошибка сохранения прогресса: $e');
      }
    }
    debugPrint('📊 Сохранено записей прогресса: $savedCount');
    notifyListeners();
  }

  ExerciseDetailedSummary getExerciseDetailedSummary(String exerciseId) {
    final records = getExerciseProgress(exerciseId);
    if (records.isEmpty) {
      return ExerciseDetailedSummary.empty(exerciseId);
    }

    double minWeight = double.infinity;
    double maxWeight = 0;
    double totalWeight = 0;
    DateTime? minDate;
    DateTime? maxDate;
    int totalSets = 0;

    // 🆕 агрегируем по метрикам формата
    double? bestDistance;
    double? bestPace;
    int? bestDuration;
    int? bestRounds;
    int? bestHoldSeconds;

    for (final r in records) {
      if (r.bestWeight > 0 && r.bestWeight < minWeight) {
        minWeight = r.bestWeight;
        minDate = r.date;
      }
      if (r.bestWeight > maxWeight) {
        maxWeight = r.bestWeight;
        maxDate = r.date;
      }
      if (r.bestWeight > 0) totalWeight += r.bestWeight;
      totalSets += r.totalSets;

      // 🆕
      if (r.bestDistance != null) {
        bestDistance = (bestDistance ?? 0) + r.bestDistance!;
      }
      if (r.bestPace != null) {
        bestPace =
        bestPace == null ? r.bestPace : (r.bestPace! < bestPace! ? r.bestPace : bestPace);
      }
      if (r.bestDuration != null) {
        bestDuration = (bestDuration ?? 0) + r.bestDuration!;
      }
      if (r.bestRounds != null) {
        bestRounds = (bestRounds ?? 0) + r.bestRounds!;
      }
      if (r.bestHoldSeconds != null) {
        bestHoldSeconds = bestHoldSeconds == null
            ? r.bestHoldSeconds
            : (r.bestHoldSeconds! > bestHoldSeconds
            ? r.bestHoldSeconds
            : bestHoldSeconds);
      }
    }

    final nonZeroWeightCount =
        records.where((r) => r.bestWeight > 0).length;

    return ExerciseDetailedSummary(
      exerciseId: exerciseId,
      minWeight: minWeight == double.infinity ? 0 : minWeight,
      maxWeight: maxWeight,
      avgWeight:
      nonZeroWeightCount > 0 ? totalWeight / nonZeroWeightCount : 0,
      minDate: minDate,
      maxDate: maxDate,
      totalWorkouts: records.length,
      totalSets: totalSets,
      totalVolume: records.fold(0.0, (sum, r) => sum + r.totalVolume),
      bestDistance: bestDistance,
      bestPace: bestPace,
      bestDuration: bestDuration,
      bestRounds: bestRounds,
      bestHoldSeconds: bestHoldSeconds,
    );
  }

  Future<void> updateLogComment(String logId, String comment) async {
    final log = _logs.firstWhere((l) => l.id == logId);
    final updatedLog = log.copyWith(comment: comment);
    await _db.update('workout_logs', updatedLog.toMap(),
        where: 'id = ?', whereArgs: [logId]);
    final index = _logs.indexWhere((l) => l.id == logId);
    if (index != -1) _logs[index] = updatedLog;
    notifyListeners();
  }

  List<WorkoutLog> getLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _logs
        .where((l) => l.date.isAfter(start) && l.date.isBefore(end))
        .toList();
  }

  List<WorkoutLog> getLogsForDateRange(DateTime start, DateTime end) {
    return _logs
        .where((l) =>
    l.date.isAfter(start.subtract(const Duration(days: 1))) &&
        l.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  Map<DateTime, List<WorkoutLog>> getLogsGroupedByDate(int days) {
    final map = <DateTime, List<WorkoutLog>>{};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final logs = getLogsForDate(date);
      map[date] = logs;
    }
    return map;
  }

  List<ProgressRecord> getExerciseProgress(String exerciseId) {
    return _progressRecords.where((r) => r.exerciseId == exerciseId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  ProgressRecord? getLastProgress(String exerciseId) {
    final records = getExerciseProgress(exerciseId);
    return records.isNotEmpty ? records.last : null;
  }

  double getExerciseBest1RM(String exerciseId) {
    final records = getExerciseProgress(exerciseId);
    if (records.isEmpty) return 0.0;
    return records.map((r) => r.estimated1RM).reduce((a, b) => a > b ? a : b);
  }

  TrendLine getExerciseTrend(String exerciseId) {
    return FitnessHelpers.calculateTrendLine(getExerciseProgress(exerciseId));
  }

  // ============================================================
  // ФОТО / САМОЧУВСТВИЕ
  // ============================================================

  Future<FitnessPhoto> addPhoto({
    required String imageUrl,
    String? label,
    double? weight,
    String? notes,
    double? chest,
    double? waist,
    double? hips,
    double? biceps,
    double? thigh,
    double? calf,
    double? neck,
    double? forearm,
  }) async {
    final photo = FitnessPhoto(
      id: _uuid.v4(),
      date: DateTime.now(),
      imageUrl: imageUrl,
      label: label,
      weight: weight,
      notes: notes,
      chest: chest,
      waist: waist,
      hips: hips,
      biceps: biceps,
      thigh: thigh,
      calf: calf,
      neck: neck,
      forearm: forearm,
    );
    await _db.insert('fitness_photos', photo.toMap());
    _photos.insert(0, photo);
    await _updateTargetsProgress();
    notifyListeners();
    return photo;
  }

  Future<void> updatePhoto(FitnessPhoto photo) async {
    await _db.update('fitness_photos', photo.toMap(),
        where: 'id = ?', whereArgs: [photo.id]);
    final index = _photos.indexWhere((p) => p.id == photo.id);
    if (index != -1) _photos[index] = photo;
    await _updateTargetsProgress();
    notifyListeners();
  }

  Future<void> deletePhoto(String id) async {
    await _db.delete('fitness_photos', where: 'id = ?', whereArgs: [id]);
    _photos.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<WellbeingNote> addWellbeingNote({
    int energyLevel = 5,
    int sleepQuality = 5,
    int motivationLevel = 5,
    List<String> painAreas = const [],
    String? notes,
  }) async {
    final note = WellbeingNote(
      id: _uuid.v4(),
      date: DateTime.now(),
      energyLevel: energyLevel,
      sleepQuality: sleepQuality,
      motivationLevel: motivationLevel,
      painAreas: painAreas,
      notes: notes,
    );
    await _db.insert('wellbeing_notes', note.toMap());
    _wellbeingNotes.insert(0, note);
    notifyListeners();
    return note;
  }

  Future<void> updateWellbeingNote(WellbeingNote note) async {
    await _db.update('wellbeing_notes', note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
    final index = _wellbeingNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) _wellbeingNotes[index] = note;
    notifyListeners();
  }

  Future<void> deleteWellbeingNote(String id) async {
    await _db.delete('wellbeing_notes', where: 'id = ?', whereArgs: [id]);
    _wellbeingNotes.removeWhere((note) => note.id == id);
    notifyListeners();
    debugPrint('🗑️ Запись самочувствия удалена: $id');
  }

  WellbeingNote? getTodayWellbeing() {
    final now = DateTime.now();
    final index = _wellbeingNotes.indexWhere((n) =>
    n.date.year == now.year &&
        n.date.month == now.month &&
        n.date.day == now.day);
    return index != -1 ? _wellbeingNotes[index] : null;
  }

  // ============================================================
  // СТАТИСТИКА
  // ============================================================

  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final weekLogs = _logs.where((l) => l.date.isAfter(weekStart)).toList();
    final monthLogs = _logs.where((l) => l.date.isAfter(monthStart)).toList();
    final rpeValues =
    _logs.where((l) => l.avgRpe != null).map((l) => l.avgRpe!).toList();

    // 🆕 Сумма метрик по всем логам (кг / км / сек / раунды / удары / ккал)
    final totalByMetric = <String, double>{};
    for (final log in _logs) {
      if (log.totalByMetric != null) {
        log.totalByMetric!.forEach((k, v) {
          totalByMetric[k] = (totalByMetric[k] ?? 0) + v;
        });
      } else if (log.totalVolume != null) {
        totalByMetric['kg'] = (totalByMetric['kg'] ?? 0) + log.totalVolume!;
      }
    }

    // 🆕 Сколько тренировок каждого типа (по типам упражнений в логе)
    final workoutsByType = <ExerciseType, int>{};
    for (final log in _logs) {
      final types = <ExerciseType>{};
      for (final exLog in log.exercisesLog) {
        final ex = _findExerciseById(exLog.exerciseId);
        if (ex.id.isNotEmpty) types.add(ex.exerciseType);
      }
      for (final t in types) {
        workoutsByType[t] = (workoutsByType[t] ?? 0) + 1;
      }
    }

    return {
      'totalWorkouts': _logs.length,
      'workoutsThisWeek': weekLogs.length,
      'workoutsThisMonth': monthLogs.length,
      'currentStreak': _calculateStreak(),
      'totalVolume':
      _logs.fold(0.0, (sum, l) => sum + (l.totalVolume ?? 0)), // legacy
      'totalByMetric': totalByMetric, // 🆕
      'workoutsByType': workoutsByType, // 🆕
      'averageRpe': rpeValues.isNotEmpty
          ? rpeValues.reduce((a, b) => a + b) / rpeValues.length
          : 0,
      'totalExercises': _exercises.length,
      'customExercises': _exercises.where((e) => e.isCustom).length,
      'activePrograms': _programs.length,
    };
  }

  int _calculateStreak() {
    if (_logs.isEmpty) return 0;
    int streak = 0;
    final now = DateTime.now();
    final sortedLogs = _logs
        .where((l) => l.status == WorkoutDayStatus.completed)
        .map((l) => l.date)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (sortedLogs.isEmpty) return 0;
    for (int i = 0; i < sortedLogs.length; i++) {
      final expectedDate = now.subtract(Duration(days: i));
      final actualDate = DateTime(
          sortedLogs[i].year, sortedLogs[i].month, sortedLogs[i].day);
      final expectedDay =
      DateTime(expectedDate.year, expectedDate.month, expectedDate.day);
      if (actualDate == expectedDay) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// 🆕 Возвращает Map<exerciseId, ExerciseTonnageInfo>.
  /// Упражнение попадает в Map, если есть хоть одна метрика.
  Map<String, ExerciseTonnageInfo> getTonnageByExercise() {
    final map = <String, ExerciseTonnageInfo>{};

    for (final log in _logs) {
      for (final exLog in log.exercisesLog) {
        final exData = _findExerciseById(exLog.exerciseId);
        final format = FitnessHelpers.resolveFormat(exLog, exData);

        final metrics = FitnessHelpers.calculateTotalByMetric(
          [exLog],
          findExercise: (_) => exData,
        );
        if (metrics.isEmpty) continue;

        final info =
        map.putIfAbsent(exLog.exerciseId, () => ExerciseTonnageInfo());
        final kg = metrics['kg'] ?? 0;

        info.totalVolume += kg;
        info.totalWorkouts++;
        metrics.forEach((k, v) {
          info.byMetric[k] = (info.byMetric[k] ?? 0) + v;
        });

        if (kg > info.maxSingleWorkoutVolume) {
          info.maxSingleWorkoutVolume = kg;
          info.maxDate = log.date;
        }
      }
    }

    return map;
  }

  /// 🆕 Аналогично для мышц. Для каждой мышцы суммируются метрики
  /// по всем упражнениям, где она участвует.
  Map<MuscleGroup, MuscleTonnageInfo> getTonnageByMuscle() {
    final map = <MuscleGroup, MuscleTonnageInfo>{};

    for (final log in _logs) {
      for (final exLog in log.exercisesLog) {
        final exData = _findExerciseById(exLog.exerciseId);
        if (exData.id.isEmpty) continue;

        final metrics = FitnessHelpers.calculateTotalByMetric(
          [exLog],
          findExercise: (_) => exData,
        );
        if (metrics.isEmpty) continue;

        final completedSets = exLog.sets
            .where((s) => s.status == SetStatus.completed && !s.isWarmup)
            .length;

        for (final muscle in exData.muscleGroups) {
          final info = map.putIfAbsent(muscle, () => MuscleTonnageInfo());
          info.totalVolume += (metrics['kg'] ?? 0);
          info.totalSets += completedSets;
          info.totalWorkouts++;
          metrics.forEach((k, v) {
            info.byMetric[k] = (info.byMetric[k] ?? 0) + v;
          });
        }
      }
    }

    return map;
  }

  // ============================================================
  // 🔥 v7: СИСТЕМА СЛЕДОВАНИЯ ПРОГРАММАМ
  // ============================================================

  Future<ProgramSession> startProgramSession(
      String programId, {
        ProgramDifficulty difficulty = ProgramDifficulty.standard,
      }) async {
    if (activeSession != null) {
      throw Exception(
          'У вас уже есть активная программа "${_programs.firstWhere((p) => p.id == activeSession!.programId).name}". Завершите или приостановите её.');
    }

    final program = _programs.firstWhere((p) => p.id == programId);

    final daySessions = program.days.asMap().entries.map((entry) {
      final isFirst = entry.key == 0;
      return DaySession(
        dayIndex: entry.key,
        status: isFirst ? DaySessionStatus.current : DaySessionStatus.locked,
      );
    }).toList();

    final session = ProgramSession(
      id: _uuid.v4(),
      programId: programId,
      startDate: DateTime.now(),
      difficulty: difficulty,
      daySessions: daySessions,
    );

    await _db.insert('program_sessions', session.toMap());
    _sessions.insert(0, session);
    notifyListeners();

    debugPrint(
        '✅ Начата программа: ${program.name} (${program.days.length} дней, сложность: ${difficulty.name})');
    return session;
  }

  Future<void> _updateSessionAfterWorkout(
      Map<String, double> totalByMetric, // 🆕
      double? avgRpe,
      ) async {
    final session = activeSession;
    if (session == null) return;

    final program = _programs.firstWhere((p) => p.id == session.programId);

    // 🆕 Тоннаж в кг для legacy-поля volumeDone
    final volume = totalByMetric['kg'] ?? 0.0;

    final updatedDays = List<DaySession>.from(session.daySessions);
    updatedDays[session.currentDayIndex] =
        updatedDays[session.currentDayIndex].copyWith(
          status: DaySessionStatus.completed,
          completedAt: DateTime.now(),
          volumeDone: volume,
          avgRpe: avgRpe,
        );

    int nextIndex = session.currentDayIndex + 1;
    bool isProgramComplete = nextIndex >= program.days.length;

    while (nextIndex < program.days.length &&
        program.days[nextIndex].isRestDay) {
      updatedDays[nextIndex] = updatedDays[nextIndex].copyWith(
        status: DaySessionStatus.completed,
        completedAt: DateTime.now(),
        notes: 'Автоматический день отдыха',
      );
      nextIndex++;
      if (nextIndex >= program.days.length) {
        isProgramComplete = true;
        break;
      }
    }

    if (!isProgramComplete && nextIndex < program.days.length) {
      updatedDays[nextIndex] = updatedDays[nextIndex].copyWith(
        status: DaySessionStatus.current,
      );
    }

    int newStreak = session.streak + 1;
    int newLongest =
    newStreak > session.longestStreak ? newStreak : session.longestStreak;
    final newCompleted = session.totalWorkoutsCompleted + 1;

    final newAvgRpe = avgRpe != null
        ? (session.averageRpe * session.totalWorkoutsCompleted + avgRpe) /
        newCompleted
        : session.averageRpe;

    final updatedSession = session.copyWith(
      currentDayIndex: isProgramComplete ? session.currentDayIndex : nextIndex,
      daySessions: updatedDays,
      streak: newStreak,
      longestStreak: newLongest,
      totalVolumeCompleted: session.totalVolumeCompleted + volume,
      totalByMetricCompleted:
      _mergeMetrics(session.totalByMetricCompleted, totalByMetric), // 🆕
      totalWorkoutsCompleted: newCompleted,
      averageRpe: newAvgRpe,
      status: isProgramComplete
          ? ProgramSessionStatus.completed
          : ProgramSessionStatus.active,
      endDate: isProgramComplete ? DateTime.now() : null,
      completedAt: isProgramComplete ? DateTime.now() : null,
    );

    await _db.update('program_sessions', updatedSession.toMap(),
        where: 'id = ?', whereArgs: [session.id]);

    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) _sessions[index] = updatedSession;

    debugPrint(
        '📊 Сессия обновлена: день ${session.currentDayIndex + 1}/${program.days.length}, серия: $newStreak');

    if (isProgramComplete) {
      await _generateProgramSummary(updatedSession, program);
    }
  }

  Future<void> _skipCurrentDayInSession(String reason) async {
    final session = activeSession;
    if (session == null) return;

    final program = _programs.firstWhere((p) => p.id == session.programId);
    final updatedDays = List<DaySession>.from(session.daySessions);

    if (session.difficulty == ProgramDifficulty.hardcore) {
      final weekStart = (session.currentDayIndex ~/ 7) * 7;
      for (int i = weekStart; i < session.currentDayIndex; i++) {
        if (i < updatedDays.length &&
            updatedDays[i].status == DaySessionStatus.completed) {
          updatedDays[i] = updatedDays[i].copyWith(
            status: DaySessionStatus.pending,
            completedAt: null,
            volumeDone: null,
          );
        }
      }
      debugPrint('⚠️ Hardcore режим: сброшена неделя ${weekStart ~/ 7 + 1}');
    }

    updatedDays[session.currentDayIndex] =
        updatedDays[session.currentDayIndex].copyWith(
          status: DaySessionStatus.skipped,
          completedAt: DateTime.now(),
          notes: reason,
        );

    int nextIndex = session.currentDayIndex + 1;

    while (nextIndex < program.days.length &&
        program.days[nextIndex].isRestDay) {
      updatedDays[nextIndex] = updatedDays[nextIndex].copyWith(
        status: DaySessionStatus.completed,
        completedAt: DateTime.now(),
        notes: 'Автоматический день отдыха',
      );
      nextIndex++;
    }

    if (nextIndex < program.days.length) {
      updatedDays[nextIndex] = updatedDays[nextIndex].copyWith(
        status: DaySessionStatus.current,
      );
    }

    final newStreak = session.difficulty == ProgramDifficulty.flexible
        ? session.streak
        : 0;

    final updatedSession = session.copyWith(
      currentDayIndex:
      nextIndex < program.days.length ? nextIndex : session.currentDayIndex,
      daySessions: updatedDays,
      streak: newStreak,
      totalWorkoutsSkipped: session.totalWorkoutsSkipped + 1,
    );

    await _db.update('program_sessions', updatedSession.toMap(),
        where: 'id = ?', whereArgs: [session.id]);

    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) _sessions[index] = updatedSession;

    debugPrint('⏭️ День пропущен, следующий день: ${nextIndex + 1}');
  }

  Future<void> skipCurrentDay({String? reason}) async {
    await _skipCurrentDayInSession(reason ?? 'Пропущен вручную');
    notifyListeners();
  }

  Future<void> pauseProgramSession() async {
    final session = activeSession;
    if (session == null) return;

    final updated = session.copyWith(status: ProgramSessionStatus.paused);
    await _db.update('program_sessions', updated.toMap(),
        where: 'id = ?', whereArgs: [session.id]);

    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) _sessions[index] = updated;

    debugPrint('⏸️ Программа приостановлена');
    notifyListeners();
  }

  Future<void> resumeProgramSession(String sessionId) async {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    if (session.status != ProgramSessionStatus.paused) return;

    if (activeSession != null) {
      throw Exception(
          'Сначала завершите или приостановьте текущую активную программу');
    }

    final updated = session.copyWith(status: ProgramSessionStatus.active);
    await _db.update('program_sessions', updated.toMap(),
        where: 'id = ?', whereArgs: [session.id]);

    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) _sessions[index] = updated;

    debugPrint('▶️ Программа возобновлена');
    notifyListeners();
  }

  Future<void> abandonProgramSession(String sessionId) async {
    final session = _sessions.firstWhere((s) => s.id == sessionId);

    final updated = session.copyWith(
      status: ProgramSessionStatus.abandoned,
      endDate: DateTime.now(),
    );
    await _db.update('program_sessions', updated.toMap(),
        where: 'id = ?', whereArgs: [session.id]);

    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) _sessions[index] = updated;

    debugPrint(
        '❌ Программа брошена: ${_programs.firstWhere((p) => p.id == session.programId).name}');
    notifyListeners();
  }

  Future<void> _generateProgramSummary(
      ProgramSession session, WorkoutProgram program) async {
    debugPrint('🏆 Генерация сводки для: ${program.name}');

    final completedDays = session.daySessions
        .where((d) => d.status == DaySessionStatus.completed)
        .toList();
    final skippedDays = session.daySessions
        .where((d) => d.status == DaySessionStatus.skipped)
        .toList();

    final exerciseStats = <String, Map<String, dynamic>>{};

    for (final log in _logs.where((l) => l.date.isAfter(session.startDate))) {
      for (final exLog in log.exercisesLog) {
        if (!exerciseStats.containsKey(exLog.exerciseId)) {
          exerciseStats[exLog.exerciseId] = {
            'totalVolume': 0.0,
            'totalSets': 0,
            'firstWeight': 0.0,
            'lastWeight': 0.0,
            'firstReps': 0,
            'lastReps': 0,
            'workouts': 0,
          };
        }

        final stats = exerciseStats[exLog.exerciseId]!;
        final volume = exLog.sets
            .where((s) => s.status == SetStatus.completed && !s.isWarmup)
            .fold(0.0, (sum, s) => sum + s.volume);

        stats['totalVolume'] = (stats['totalVolume'] as double) + volume;
        stats['totalSets'] = (stats['totalSets'] as int) +
            exLog.sets.where((s) => s.status == SetStatus.completed).length;
        stats['workouts'] = (stats['workouts'] as int) + 1;

        if (stats['workouts'] == 1) {
          final firstSet = exLog.sets
              .firstWhere((s) => !s.isWarmup,
              orElse: () => exLog.sets.first);
          stats['firstWeight'] = firstSet.weight;
          stats['firstReps'] = firstSet.reps;
        }

        final lastSet = exLog.sets.lastWhere((s) => !s.isWarmup,
            orElse: () => exLog.sets.last);
        stats['lastWeight'] = lastSet.weight;
        stats['lastReps'] = lastSet.reps;
      }
    }

    final summary = {
      'programName': program.name,
      'startDate': session.startDate.toIso8601String(),
      'endDate': DateTime.now().toIso8601String(),
      'durationDays': DateTime.now().difference(session.startDate).inDays,
      'completedDays': completedDays.length,
      'skippedDays': skippedDays.length,
      'totalDays': program.days.length,
      'totalVolume': session.totalVolumeCompleted,
      'totalByMetric': session.totalByMetricCompleted, // 🆕
      'averageRpe': session.averageRpe,
      'longestStreak': session.longestStreak,
      'difficulty': session.difficulty.name,
      'exerciseStats': exerciseStats,
    };

    final updatedSession = session.copyWith(summaryData: summary);
    await _db.update('program_sessions', updatedSession.toMap(),
        where: 'id = ?', whereArgs: [session.id]);

    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) _sessions[index] = updatedSession;

    notifyListeners();

    debugPrint(
        '🏆 Сводка сгенерирована: ${completedDays.length}/${program.days.length} дней, тоннаж: ${session.totalVolumeCompleted.toStringAsFixed(0)} кг');
  }

  WorkoutProgram? getProgramForSession(String sessionId) {
    try {
      final session = _sessions.firstWhere((s) => s.id == sessionId);
      return _programs.firstWhere((p) => p.id == session.programId);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // 🎯 v8: СИСТЕМА ФИТНЕС-ЦЕЛЕЙ
  // ============================================================

  Future<FitnessTarget> addTarget(FitnessTarget target) async {
    await _db.insert('fitness_targets', target.toMap());
    _targets.insert(0, target);
    notifyListeners();
    debugPrint('🎯 Добавлена цель: ${target.name}');
    return target;
  }

  Future<void> updateTarget(FitnessTarget target) async {
    await _db.update('fitness_targets', target.toMap(),
        where: 'id = ?', whereArgs: [target.id]);
    final index = _targets.indexWhere((t) => t.id == target.id);
    if (index != -1) _targets[index] = target;
    notifyListeners();
  }

  Future<void> deleteTarget(String id) async {
    await _db.delete('fitness_targets', where: 'id = ?', whereArgs: [id]);
    _targets.removeWhere((t) => t.id == id);
    notifyListeners();
    debugPrint('🗑️ Цель удалена: $id');
  }

  Future<void> completeTarget(String id) async {
    final target = _targets.firstWhere((t) => t.id == id);
    final updated = target.copyWith(
      status: FitnessTargetStatus.completed,
      currentValue: target.targetValue,
      completedAt: DateTime.now(),
    );
    await updateTarget(updated);
    debugPrint('🏆 Цель достигнута: ${target.name}');
  }

  Future<void> pauseTarget(String id) async {
    final target = _targets.firstWhere((t) => t.id == id);
    await updateTarget(target.copyWith(status: FitnessTargetStatus.paused));
  }

  Future<void> resumeTarget(String id) async {
    final target = _targets.firstWhere((t) => t.id == id);
    await updateTarget(target.copyWith(status: FitnessTargetStatus.active));
  }

  Future<void> addTargetEntry(String targetId, double value,
      {String? note}) async {
    final targetIndex = _targets.indexWhere((t) => t.id == targetId);
    if (targetIndex == -1) {
      debugPrint('⚠️ Цель $targetId не найдена');
      return;
    }

    final target = _targets[targetIndex];
    final entry = FitnessTargetEntry(
      date: DateTime.now(),
      value: value,
      note: note,
      bodyWeight: _profile?.currentWeight,
    );

    final updatedEntries = List<FitnessTargetEntry>.from(target.entries)
      ..add(entry);

    double newCurrentValue = target.currentValue;
    if (target.isAscending) {
      if (value > target.currentValue) newCurrentValue = value;
    } else {
      if (value < target.currentValue || target.currentValue == 0) {
        newCurrentValue = value;
      }
    }

    final bool isNowCompleted;
    if (target.isAscending) {
      isNowCompleted = newCurrentValue >= target.targetValue;
    } else {
      isNowCompleted = newCurrentValue <= target.targetValue;
    }

    final updated = target.copyWith(
      entries: updatedEntries,
      currentValue: newCurrentValue,
      status: isNowCompleted ? FitnessTargetStatus.completed : target.status,
      completedAt: isNowCompleted && !target.isCompleted
          ? DateTime.now()
          : target.completedAt,
    );

    await _db.update('fitness_targets', updated.toMap(),
        where: 'id = ?', whereArgs: [updated.id]);
    _targets[targetIndex] = updated;
    notifyListeners();

    if (isNowCompleted && !target.isCompleted) {
      debugPrint('🏆🎯 Цель достигнута через запись прогресса: ${target.name}');
    } else {
      debugPrint(
          '📝 Запись прогресса для "${target.name}": $value ${target.unit}');
    }
  }

  Future<void> removeTargetEntry(String targetId, DateTime entryDate) async {
    final targetIndex = _targets.indexWhere((t) => t.id == targetId);
    if (targetIndex == -1) return;

    final target = _targets[targetIndex];
    final updatedEntries = target.entries
        .where((e) => e.date.toIso8601String() != entryDate.toIso8601String())
        .toList();

    double newCurrentValue = target.startValue;
    if (updatedEntries.isNotEmpty) {
      if (target.isAscending) {
        newCurrentValue = updatedEntries
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b);
      } else {
        newCurrentValue = updatedEntries
            .map((e) => e.value)
            .reduce((a, b) => a < b ? a : b);
      }
    }

    final updated = target.copyWith(
      entries: updatedEntries,
      currentValue: newCurrentValue,
    );

    await _db.update('fitness_targets', updated.toMap(),
        where: 'id = ?', whereArgs: [updated.id]);
    _targets[targetIndex] = updated;
    notifyListeners();
    debugPrint('🗑️ Удалена запись из журнала цели: ${target.name}');
  }

  Map<String, dynamic> calculateForecast(FitnessTarget target) {
    if (target.entries.length < 2) {
      return {
        'days': null,
        'date': null,
        'speed': 0.0,
        'isRealistic': false,
        'reason': 'Недостаточно данных (нужно минимум 2 записи)',
        'entriesCount': target.entries.length,
        'trendDays': 0,
      };
    }

    final sorted = List<FitnessTargetEntry>.from(target.entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final recentCount = sorted.length.clamp(2, 10);
    final recent = sorted.sublist(sorted.length - recentCount);

    final first = recent.first;
    final last = recent.last;
    final daysDiff = last.date.difference(first.date).inDays;

    if (daysDiff == 0) {
      return {
        'days': null,
        'date': null,
        'speed': 0.0,
        'isRealistic': false,
        'reason': 'Все записи за один день',
        'entriesCount': sorted.length,
        'trendDays': 0,
      };
    }

    final valueDiff = last.value - first.value;
    final speedPerDay = valueDiff / daysDiff;

    if (target.isAscending && speedPerDay <= 0) {
      return {
        'days': null,
        'date': null,
        'speed': speedPerDay,
        'isRealistic': false,
        'reason': 'Прогресс остановился или идёт в обратную сторону',
        'entriesCount': sorted.length,
        'trendDays': daysDiff,
      };
    }
    if (!target.isAscending && speedPerDay >= 0) {
      return {
        'days': null,
        'date': null,
        'speed': speedPerDay,
        'isRealistic': false,
        'reason': 'Прогресс остановился или идёт в обратную сторону',
        'entriesCount': sorted.length,
        'trendDays': daysDiff,
      };
    }

    final remaining = target.isAscending
        ? target.targetValue - target.currentValue
        : target.currentValue - target.targetValue;

    final daysToGoal = (remaining / speedPerDay.abs()).ceil();
    final estimatedDate = DateTime.now().add(Duration(days: daysToGoal));

    final isRealistic = daysToGoal > 0 && daysToGoal < 1095;

    return {
      'days': daysToGoal,
      'date': estimatedDate,
      'speed': speedPerDay.abs(),
      'isRealistic': isRealistic,
      'reason': isRealistic
          ? 'На основе последних $recentCount записей'
          : 'Прогноз слишком далёкий',
      'entriesCount': sorted.length,
      'trendDays': daysDiff,
    };
  }

  List<FitnessTargetEntry> getTargetEntries(String targetId) {
    try {
      final target = _targets.firstWhere((t) => t.id == targetId);
      final sorted = List<FitnessTargetEntry>.from(target.entries);
      sorted.sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    } catch (_) {
      return [];
    }
  }

  Future<void> _updateTargetsProgress() async {
    bool changed = false;

    for (final target in _targets
        .where((t) => t.status == FitnessTargetStatus.active)
        .toList()) {
      try {
        final newValue = _calculateTargetProgress(target);
        if ((newValue - target.currentValue).abs() > 0.001) {
          final isNowCompleted =
              newValue >= target.targetValue && !target.isCompleted;
          final updated = target.copyWith(
            currentValue: newValue,
            status:
            isNowCompleted ? FitnessTargetStatus.completed : target.status,
            completedAt: isNowCompleted ? DateTime.now() : target.completedAt,
          );
          await _db.update('fitness_targets', updated.toMap(),
              where: 'id = ?', whereArgs: [updated.id]);
          final idx = _targets.indexWhere((t) => t.id == updated.id);
          if (idx != -1) _targets[idx] = updated;
          changed = true;

          if (isNowCompleted) {
            debugPrint('🏆🎯 Цель автоматически достигнута: ${target.name}');
          } else {
            debugPrint(
                '📈 Обновлён прогресс цели "${target.name}": $newValue/${target.targetValue}');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка обновления цели ${target.name}: $e');
      }
    }

    if (changed) notifyListeners();
  }

  double _calculateTargetProgress(FitnessTarget target) {
    switch (target.type) {
      case FitnessTargetType.strengthMax:
        if (target.exerciseId == null) return target.currentValue;
        double maxWeight = 0;
        for (final log in _logs) {
          for (final ex in log.exercisesLog) {
            if (ex.exerciseId == target.exerciseId) {
              for (final set in ex.sets) {
                if (set.status == SetStatus.completed &&
                    set.weight > maxWeight) {
                  maxWeight = set.weight;
                }
              }
            }
          }
        }
        return maxWeight;

      case FitnessTargetType.strengthReps:
        if (target.exerciseId == null) return target.currentValue;
        final targetReps = target.extra['reps'] as int? ?? 0;
        double bestWeight = 0;
        for (final log in _logs) {
          for (final ex in log.exercisesLog) {
            if (ex.exerciseId == target.exerciseId) {
              for (final set in ex.sets) {
                if (set.status == SetStatus.completed &&
                    set.reps >= targetReps &&
                    set.weight > bestWeight) {
                  bestWeight = set.weight;
                }
              }
            }
          }
        }
        return bestWeight;

      case FitnessTargetType.bodyweightReps:
        if (target.exerciseId == null) return target.currentValue;
        int maxReps = 0;
        for (final log in _logs) {
          for (final ex in log.exercisesLog) {
            if (ex.exerciseId == target.exerciseId) {
              for (final set in ex.sets) {
                if (set.status == SetStatus.completed && set.reps > maxReps) {
                  maxReps = set.reps;
                }
              }
            }
          }
        }
        return maxReps.toDouble();

      case FitnessTargetType.volume:
        double maxVolume = 0;
        for (final log in _logs) {
          final vol = log.metricValue('kg'); // 🆕 totalByMetric['kg'] ?? totalVolume
          if (vol > maxVolume) maxVolume = vol;
        }
        return maxVolume;

      case FitnessTargetType.endurance:
        return target.currentValue;

      case FitnessTargetType.bodyWeight:
        final weight = _profile?.currentWeight;
        if (weight == null) return target.currentValue;
        return weight;

      case FitnessTargetType.bodyMeasurement:
        if (_photos.isEmpty) return target.currentValue;
        final sorted = List<FitnessPhoto>.from(_photos)
          ..sort((a, b) => b.date.compareTo(a.date));
        final latest = sorted.first;
        final measurementKey = target.extra['measurement'] as String?;
        if (measurementKey == null) return target.currentValue;
        final values = {
          'chest': latest.chest,
          'waist': latest.waist,
          'hips': latest.hips,
          'biceps': latest.biceps,
          'thigh': latest.thigh,
          'calf': latest.calf,
          'neck': latest.neck,
          'forearm': latest.forearm,
        };
        return values[measurementKey] ?? target.currentValue;

      case FitnessTargetType.cardioDistance:
      case FitnessTargetType.cardioTime:
      case FitnessTargetType.custom:
        return target.currentValue;

    // 🆕 Сумма раундов за всё время (или для конкретного упражнения)
      case FitnessTargetType.boxingRounds:
        int totalRounds = 0;
        for (final log in _logs) {
          for (final ex in log.exercisesLog) {
            if (target.exerciseId != null &&
                ex.exerciseId != target.exerciseId) {
              continue;
            }
            for (final set in ex.sets) {
              if (set.status == SetStatus.completed) {
                totalRounds += set.rounds ?? 0;
              }
            }
          }
        }
        return totalRounds.toDouble();

    // 🆕 Лучшее (максимальное) удержание в одном подходе
      case FitnessTargetType.holdTime:
        if (target.exerciseId == null) return target.currentValue;
        int maxHold = 0;
        for (final log in _logs) {
          for (final ex in log.exercisesLog) {
            if (ex.exerciseId == target.exerciseId) {
              for (final set in ex.sets) {
                if (set.status == SetStatus.completed) {
                  final h = set.effectiveHoldSeconds ?? 0;
                  if (h > maxHold) maxHold = h;
                }
              }
            }
          }
        }
        return maxHold.toDouble();
    }
  }

  List<FitnessTarget> getTargetTemplates() {
    return [
      FitnessTarget(
        id: 'tpl_bench_100',
        name: 'Жим лёжа 100 кг',
        description: 'Покорить сотку в жиме лёжа',
        type: FitnessTargetType.strengthMax,
        exerciseId: 'ex_default_001',
        targetValue: 100,
        unit: 'кг',
        accentColor: const Color(0xFFFF6B35),
      ),
      FitnessTarget(
        id: 'tpl_pullups_10',
        name: 'Подтянуться 10 раз',
        description: 'Классический норматив',
        type: FitnessTargetType.bodyweightReps,
        exerciseId: 'ex_default_005',
        targetValue: 10,
        unit: 'раз',
        accentColor: const Color(0xFF4CAF50),
      ),
      FitnessTarget(
        id: 'tpl_run_5k',
        name: 'Пробежать 5 км',
        description: 'Дистанция для выносливости',
        type: FitnessTargetType.cardioDistance,
        targetValue: 5,
        unit: 'км',
        accentColor: const Color(0xFF4A9BFF),
      ),
      FitnessTarget(
        id: 'tpl_bench_50x50',
        name: 'Жим 50 кг × 50 раз',
        description: 'Силовая выносливость',
        type: FitnessTargetType.strengthReps,
        exerciseId: 'ex_default_001',
        targetValue: 50,
        unit: 'кг',
        extra: {'reps': 50},
        accentColor: const Color(0xFFE91E63),
      ),
      FitnessTarget(
        id: 'tpl_squat_150',
        name: 'Присед 150 кг',
        description: 'Серьёзный результат в приседе',
        type: FitnessTargetType.strengthMax,
        exerciseId: 'ex_default_012',
        targetValue: 150,
        unit: 'кг',
        accentColor: const Color(0xFF9C27B0),
      ),
      FitnessTarget(
        id: 'tpl_deadlift_200',
        name: 'Становая 200 кг',
        description: '200 кг — элитный уровень',
        type: FitnessTargetType.strengthMax,
        exerciseId: 'ex_default_008',
        targetValue: 200,
        unit: 'кг',
        accentColor: const Color(0xFF795548),
      ),
      FitnessTarget(
        id: 'tpl_plank_180',
        name: 'Планка 3 минуты',
        description: 'Стальной кор',
        type: FitnessTargetType.holdTime, // 🆕
        exerciseId: 'ex_default_022',
        targetValue: 180,
        unit: 'сек',
        accentColor: const Color(0xFF00C7BE),
      ),
      // 🆕 Новый шаблон для бокса
      FitnessTarget(
        id: 'tpl_boxing_100',
        name: '100 раундов',
        description: 'Суммарно 100 раундов на груше',
        type: FitnessTargetType.boxingRounds,
        exerciseId: 'ex_default_027',
        targetValue: 100,
        unit: 'раунд',
        accentColor: const Color(0xFFFF2D55),
      ),
      FitnessTarget(
        id: 'tpl_pushups_100',
        name: '100 отжиманий',
        description: 'За одну тренировку',
        type: FitnessTargetType.bodyweightReps,
        exerciseId: 'ex_default_004',
        targetValue: 100,
        unit: 'раз',
        accentColor: const Color(0xFFFF9500),
      ),
      FitnessTarget(
        id: 'tpl_volume_10t',
        name: '10 тонн за тренировку',
        description: 'Объёмная силовая работа',
        type: FitnessTargetType.volume,
        targetValue: 10000,
        unit: 'кг',
        accentColor: const Color(0xFF3F51B5),
      ),
      FitnessTarget(
        id: 'tpl_biceps_40',
        name: 'Бицепс 40 см',
        description: 'Классическая цель качков',
        type: FitnessTargetType.bodyMeasurement,
        targetValue: 40,
        unit: 'см',
        extra: {'measurement': 'biceps'},
        accentColor: const Color(0xFFFF5722),
      ),
    ];
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}

// ==================== ВСПОМОГАТЕЛЬНЫЕ КЛАССЫ ====================

class ExerciseDetailedSummary {
  final String exerciseId;
  final double minWeight;
  final double maxWeight;
  final double avgWeight;
  final DateTime? minDate;
  final DateTime? maxDate;
  final int totalWorkouts;
  final int totalSets;
  final double totalVolume;

  // 🆕 Метрики для не-силовых форматов
  final double? bestDistance;
  final double? bestPace;
  final int? bestDuration;
  final int? bestRounds;
  final int? bestHoldSeconds;

  ExerciseDetailedSummary({
    required this.exerciseId,
    required this.minWeight,
    required this.maxWeight,
    required this.avgWeight,
    this.minDate,
    this.maxDate,
    required this.totalWorkouts,
    required this.totalSets,
    required this.totalVolume,
    this.bestDistance,
    this.bestPace,
    this.bestDuration,
    this.bestRounds,
    this.bestHoldSeconds,
  });

  factory ExerciseDetailedSummary.empty(String exerciseId) =>
      ExerciseDetailedSummary(
        exerciseId: exerciseId,
        minWeight: 0,
        maxWeight: 0,
        avgWeight: 0,
        totalWorkouts: 0,
        totalSets: 0,
        totalVolume: 0,
      );
}

class ExerciseTonnageInfo {
  double totalVolume = 0; // кг (legacy, только для setsReps)
  double maxSingleWorkoutVolume = 0;
  DateTime? maxDate;
  int totalWorkouts = 0;
  // 🆕 Полный набор метрик: {kg, km, sec, rounds, punches, kcal, reps}
  Map<String, double> byMetric = {};
}

class MuscleTonnageInfo {
  double totalVolume = 0; // кг (legacy)
  int totalSets = 0;
  int totalWorkouts = 0;
  // 🆕
  Map<String, double> byMetric = {};
}

extension ListExtension<T> on List<T> {
  T let(T Function(List<T>) block) => block(this);
}