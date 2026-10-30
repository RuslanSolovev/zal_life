// features/fitness/models/helpers.dart
// 🆕 v16: format-aware хелперы (кардио/бокс/статика) + все старые методы сохранены
import 'dart:math';
import 'fitness_models.dart';
import 'enums.dart';

class FitnessHelpers {
  // ============================================================
  // 🆕 РЕЗОЛВИНГ ФОРМАТА
  // ============================================================

  /// Возвращает эффективный формат упражнения с fallback-цепочкой:
  /// `WorkoutExercise.format` → `Exercise.defaultFormat` →
  /// `defaultFormatByType[type]` → `setsReps`.
  static ExerciseFormat resolveFormat(
      WorkoutExercise we,
      Exercise? exercise,
      ) {
    return we.format ??
        exercise?.defaultFormat ??
        defaultFormatByType[exercise?.exerciseType ?? ExerciseType.strength] ??
        ExerciseFormat.setsReps;
  }

  /// Упрощённая версия для случая, когда нет доступа к Exercise.
  static ExerciseFormat resolveFormatSimple(WorkoutExercise we) {
    return we.format ?? ExerciseFormat.setsReps;
  }

  // ============================================================
  // 🆕 ЧТЕНИЕ МЕТРИК ПОДХОДА
  // ============================================================

  /// Возвращает значение конкретной метрики (или null, если не заполнена).
  static double? metricValue(ExerciseSet s, ExerciseMetric metric) {
    switch (metric) {
      case ExerciseMetric.reps:
        return s.reps > 0 ? s.reps.toDouble() : null;
      case ExerciseMetric.weight:
        return s.weight > 0 ? s.weight : null;
      case ExerciseMetric.rpe:
        return s.rpe;
      case ExerciseMetric.restSeconds:
        return s.restSeconds?.toDouble();
      case ExerciseMetric.duration:
        return s.duration?.toDouble();
      case ExerciseMetric.distance:
        return s.distance;
      case ExerciseMetric.pace:
        return s.pace;
      case ExerciseMetric.heartRate:
        return s.heartRate?.toDouble();
      case ExerciseMetric.calories:
        return s.calories?.toDouble();
      case ExerciseMetric.incline:
        return s.incline;
      case ExerciseMetric.resistance:
        return s.resistance;
      case ExerciseMetric.rounds:
        return s.rounds?.toDouble();
      case ExerciseMetric.roundDuration:
        return s.roundDuration?.toDouble();
      case ExerciseMetric.restBetweenRounds:
        return s.restBetweenRounds?.toDouble();
      case ExerciseMetric.punches:
        return s.punches?.toDouble();
      case ExerciseMetric.holdSeconds:
        return s.holdSeconds?.toDouble();
      case ExerciseMetric.tempo:
        return null; // tempo — строковое, обрабатывается отдельно
      case ExerciseMetric.intensity:
        return s.intensity;
    }
  }

  /// Главная метрика формата (для героя/карточки).
  static double? setPrimaryValue(ExerciseSet s, ExerciseFormat format) {
    return metricValue(s, format.primaryMetric) ??
        metricValue(s, ExerciseMetric.duration) ??
        metricValue(s, ExerciseMetric.reps);
  }

  /// Раскладывает подход в Map<метрика-ключ, значение>.
  /// Ключи: kg / km / sec / rounds / punches / kcal / reps / hold
  /// Используется для агрегации в `calculateTotalByMetric`.
  static Map<String, double> setToMetricMap(
      ExerciseSet s,
      ExerciseFormat format,
      ) {
    final map = <String, double>{};

    switch (format) {
      case ExerciseFormat.setsReps:
        if (s.weight > 0 && s.reps > 0) {
          map['kg'] = s.weight * s.reps;
        }
        if (s.reps > 0) map['reps'] = s.reps.toDouble();
        break;

      case ExerciseFormat.timedSets:
        final sec = s.effectiveDuration ?? 0;
        if (sec > 0) map['sec'] = sec.toDouble();
        break;

      case ExerciseFormat.intervals:
        if (s.distance != null && s.distance! > 0) {
          map['km'] = s.distance!;
        }
        if (s.duration != null && s.duration! > 0) {
          map['sec'] = s.duration!.toDouble();
        }
        if (s.calories != null && s.calories! > 0) {
          map['kcal'] = s.calories!.toDouble();
        }
        break;

      case ExerciseFormat.rounds:
        final r = s.rounds ?? 0;
        if (r > 0) map['rounds'] = r.toDouble();
        // секунды раундов = кол-во × длительность одного
        final rd = s.roundDuration ?? 0;
        if (r > 0 && rd > 0) {
          map['sec'] = (r * rd).toDouble();
        }
        if (s.punches != null && s.punches! > 0) {
          map['punches'] = s.punches!.toDouble();
        }
        break;

      case ExerciseFormat.continuous:
        if (s.distance != null && s.distance! > 0) {
          map['km'] = s.distance!;
        }
        if (s.duration != null && s.duration! > 0) {
          map['sec'] = s.duration!.toDouble();
        }
        if (s.calories != null && s.calories! > 0) {
          map['kcal'] = s.calories!.toDouble();
        }
        break;

      case ExerciseFormat.hold:
        final h = s.effectiveHoldSeconds ?? 0;
        if (h > 0) map['sec'] = h.toDouble();
        break;

      case ExerciseFormat.freeform:
        if (s.duration != null && s.duration! > 0) {
          map['sec'] = s.duration!.toDouble();
        }
        if (s.calories != null && s.calories! > 0) {
          map['kcal'] = s.calories!.toDouble();
        }
        break;
    }

    return map;
  }

  // ============================================================
  // 🆕 АГРЕГАЦИЯ ПО ТРЕНИРОВКЕ
  // ============================================================

  /// Суммирует все метрики по всем выполненным подходам.
  /// Возвращает словарь: {"kg": 4200, "km": 5.1, "sec": 1080, ...}
  ///
  /// [findExercise] нужен для правильного резолвинга формата,
  /// когда у `WorkoutExercise.format == null`. Если не передан —
  /// используется `we.format ?? setsReps`.
  static Map<String, double> calculateTotalByMetric(
      List<WorkoutExercise> exercises, {
        Exercise? Function(String exerciseId)? findExercise,
        bool onlyCompleted = true,
      }) {
    final totals = <String, double>{};

    for (final we in exercises) {
      final ex = findExercise?.call(we.exerciseId);
      final format = resolveFormat(we, ex);

      for (final s in we.sets) {
        if (onlyCompleted && s.status != SetStatus.completed) continue;
        if (s.isWarmup) continue;

        final partial = setToMetricMap(s, format);
        partial.forEach((k, v) {
          totals[k] = (totals[k] ?? 0) + v;
        });
      }
    }

    return totals;
  }

  /// Старый метод, теперь format-aware:
  /// возвращает ТОЛЬКО тоннаж в кг (для силовых форматов).
  /// Для остальных форматов — 0 (тоннаж не имеет смысла).
  static double calculateTotalVolume(
      List<WorkoutExercise> exercises, {
        Exercise? Function(String exerciseId)? findExercise,
      }) {
    double total = 0;
    for (final we in exercises) {
      final ex = findExercise?.call(we.exerciseId);
      final format = resolveFormat(we, ex);
      if (format != ExerciseFormat.setsReps) continue;

      for (final s in we.sets) {
        if (s.status != SetStatus.completed) continue;
        if (s.isWarmup) continue;
        total += s.weight * s.reps;
      }
    }
    return total;
  }

  /// Средний RPE — берётся только по completed-подходам, где rpe != null.
  static double? calculateAverageRpe(List<WorkoutExercise> exercises) {
    final rpeValues = <double>[];
    for (final we in exercises) {
      for (final s in we.sets) {
        if (s.rpe != null && s.status == SetStatus.completed) {
          rpeValues.add(s.rpe!);
        }
      }
    }
    if (rpeValues.isEmpty) return null;
    return rpeValues.reduce((a, b) => a + b) / rpeValues.length;
  }

  // ============================================================
  // 🆕 ОТОБРАЖЕНИЕ ПОДХОДА
  // ============================================================

  /// Компактная строка подхода для карточек:
  /// - setsReps:    "80кг × 8"
  /// - timedSets:   "60 сек"
  /// - intervals:   "0.40км · 1м30с"
  /// - rounds:      "3 × 3м"
  /// - continuous:  "5.10км · 27м"
  /// - hold:        "1м30с"
  /// - freeform:    "30м"
  static String formatSetForDisplay(
      ExerciseSet s,
      ExerciseFormat format,
      ) {
    switch (format) {
      case ExerciseFormat.setsReps:
        final w = s.weight;
        final wStr = w == w.roundToDouble()
            ? w.toStringAsFixed(0)
            : w.toStringAsFixed(1);
        return '${wStr}кг × ${s.reps}';

      case ExerciseFormat.timedSets:
        return formatHold(s.effectiveDuration ?? 0);

      case ExerciseFormat.intervals:
        final parts = <String>[];
        if (s.distance != null && s.distance! > 0) {
          parts.add(formatDistance(s.distance!));
        }
        if (s.duration != null && s.duration! > 0) {
          parts.add(formatHold(s.duration!));
        }
        if (parts.isEmpty) return '—';
        return parts.join(' · ');

      case ExerciseFormat.rounds:
        final r = s.rounds ?? 0;
        final rd = s.roundDuration ?? 0;
        if (r <= 0) return '—';
        if (rd <= 0) return '$r раунд';
        return '$r × ${formatHold(rd)}';

      case ExerciseFormat.continuous:
        final parts = <String>[];
        if (s.distance != null && s.distance! > 0) {
          parts.add(formatDistance(s.distance!));
        }
        if (s.duration != null && s.duration! > 0) {
          parts.add(formatHold(s.duration!));
        }
        if (parts.isEmpty) return '—';
        return parts.join(' · ');

      case ExerciseFormat.hold:
        return formatHold(s.effectiveHoldSeconds ?? 0);

      case ExerciseFormat.freeform:
        return formatHold(s.duration ?? 0);
    }
  }

  /// Расширенная строка с доп. метриками — для активного экрана/лога.
  /// Примеры:
  /// - "80кг × 8 · RPE 8"
  /// - "5.10км · 27м · 5:18/км · 152уд/мин"
  /// - "3 × 3м · отдых 1м · 120 ударов"
  static String formatMetricsSummary(
      ExerciseSet s,
      ExerciseFormat format, {
        bool compact = false,
      }) {
    final parts = <String>[formatSetForDisplay(s, format)];

    switch (format) {
      case ExerciseFormat.setsReps:
        if (s.rpe != null) parts.add('RPE ${s.rpe!.toStringAsFixed(1)}');
        if (!compact && s.restSeconds != null && s.restSeconds! > 0) {
          parts.add('отдых ${formatHold(s.restSeconds!)}');
        }
        break;

      case ExerciseFormat.timedSets:
        if (s.intensity != null) {
          parts.add('${s.intensity!.toStringAsFixed(0)}/10');
        }
        if (!compact && s.restSeconds != null && s.restSeconds! > 0) {
          parts.add('отдых ${formatHold(s.restSeconds!)}');
        }
        break;

      case ExerciseFormat.intervals:
        if (s.pace != null) parts.add('${formatPace(s.pace!)}/км');
        if (!compact && s.heartRate != null) {
          parts.add('${s.heartRate}уд/мин');
        }
        break;

      case ExerciseFormat.rounds:
        if (!compact && s.restBetweenRounds != null &&
            s.restBetweenRounds! > 0) {
          parts.add('отдых ${formatHold(s.restBetweenRounds!)}');
        }
        if (s.punches != null && s.punches! > 0) {
          parts.add('${s.punches} уд.');
        }
        if (s.intensity != null) {
          parts.add('${s.intensity!.toStringAsFixed(0)}/10');
        }
        break;

      case ExerciseFormat.continuous:
        if (s.pace != null) parts.add('${formatPace(s.pace!)}/км');
        if (!compact && s.heartRate != null) {
          parts.add('${s.heartRate}уд/мин');
        }
        if (!compact && s.calories != null) {
          parts.add('${s.calories}ккал');
        }
        break;

      case ExerciseFormat.hold:
        if (s.intensity != null) {
          parts.add('${s.intensity!.toStringAsFixed(0)}/10');
        }
        break;

      case ExerciseFormat.freeform:
        if (s.calories != null) parts.add('${s.calories}ккал');
        if (s.intensity != null) {
          parts.add('${s.intensity!.toStringAsFixed(0)}/10');
        }
        break;
    }

    return parts.join(' · ');
  }

  // ============================================================
  // 🆕 ФОРМАТТЕРЫ ЧИСЕЛ
  // ============================================================

  /// "5.10 км" для дистанций >= 1 км, "400 м" для < 1 км.
  static String formatDistance(double km) {
    if (km <= 0) return '0 м';
    if (km < 1) return '${(km * 1000).round()} м';
    return '${km.toStringAsFixed(2)} км';
  }

  /// "5:30" — темп в мин/км. Принимает минуты (дробные).
  static String formatPace(double minPerKm) {
    if (minPerKm <= 0) return '—';
    final minutes = minPerKm.floor();
    final seconds = ((minPerKm - minutes) * 60).round();
    // Округление может дать 60 — нормализуем
    if (seconds == 60) {
      return '${minutes + 1}:00';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// "1м 30с" / "45с" / "0:00" для секунд.
  static String formatHold(int seconds) {
    if (seconds <= 0) return '0с';
    if (seconds < 60) return '${seconds}с';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return '${m}м';
    return '${m}м ${s}с';
  }

  /// "80 кг" / "82.5 кг".
  static String formatWeight(double kg) {
    if (kg <= 0) return '0 кг';
    return kg == kg.roundToDouble()
        ? '${kg.toStringAsFixed(0)} кг'
        : '${kg.toStringAsFixed(1)} кг';
  }

  /// "3 × 3м" или "5 раундов".
  static String formatRounds(int rounds, int? roundDuration) {
    if (rounds <= 0) return '—';
    if (roundDuration == null || roundDuration <= 0) {
      return '$rounds раунд${rounds > 1 ? "ов" : ""}';
    }
    return '$rounds × ${formatHold(roundDuration)}';
  }

  /// Старый форматтер длительности (Duration → "1ч 30м" / "45м").
  /// ✅ без изменений
  static String formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}ч ${minutes}м';
    }
    return '${minutes}м';
  }

  // ============================================================
  // 🆕 ОТДЫХ ПО ФОРМАТУ
  // ============================================================

  /// Рекомендуемый отдых для формата. Если в сете задан `restSeconds` —
  /// он имеет приоритет (для форматов, где отдых применим).
  static int getRecommendedRestSeconds(
      ExerciseFormat format, {
        int? fromSet,
      }) {
    // Явно заданный отдых важнее
    if (fromSet != null && fromSet > 0) return fromSet;

    switch (format) {
      case ExerciseFormat.setsReps:
        return 90;
      case ExerciseFormat.timedSets:
        return 60;
      case ExerciseFormat.intervals:
        return 60;
      case ExerciseFormat.rounds:
        return 60;
      case ExerciseFormat.continuous:
      case ExerciseFormat.hold:
      case ExerciseFormat.freeform:
        return 0; // таймер не запускается
    }
  }

  // ============================================================
  // ✅ СТАРЫЕ МЕТОДЫ — БЕЗ ИЗМЕНЕНИЙ (сохранены для обратной совместимости)
  // ============================================================

  /// Формула Эпли
  static double calculate1RM(double weight, int reps) {
    if (reps <= 0 || weight <= 0) return 0.0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  /// Формула Бжицки
  static double calculate1RMBrzycki(double weight, int reps) {
    if (reps <= 0 || weight <= 0) return 0.0;
    if (reps == 1) return weight;
    return weight / (1.0278 - 0.0278 * reps);
  }

  static double calculateWeightFromPercentage(double oneRM, double percentage) {
    return oneRM * (percentage / 100.0);
  }

  static int estimateRepsFromPercentage(double percentage) {
    if (percentage >= 100) return 1;
    if (percentage >= 95) return 2;
    if (percentage >= 90) return 3;
    if (percentage >= 85) return 5;
    if (percentage >= 80) return 8;
    if (percentage >= 75) return 10;
    if (percentage >= 70) return 12;
    if (percentage >= 65) return 15;
    return 20;
  }

  static double calculateIntensity(double weight, double oneRM) {
    if (oneRM <= 0) return 0.0;
    return (weight / oneRM) * 100.0;
  }

  static List<ExerciseSet> generateWarmupSets(
      double workWeight, {
        int totalWarmupSets = 3,
      }) {
    final warmupSets = <ExerciseSet>[];
    final percentages = [0.5, 0.7, 0.9];
    final reps = [10, 5, 2];

    for (int i = 0; i < min(totalWarmupSets, percentages.length); i++) {
      warmupSets.add(ExerciseSet(
        setNumber: i + 1,
        weight: (workWeight * percentages[i]).roundToDouble(),
        reps: reps[i],
        isWarmup: true,
        status: SetStatus.pending,
        rpe: percentages[i] <= 0.5 ? 3.0 : (percentages[i] <= 0.7 ? 5.0 : 7.0),
      ));
    }

    return warmupSets;
  }

  static List<ExerciseSet> generateAdvancedWarmup(
      double workWeight, {
        FitnessLevel level = FitnessLevel.intermediate,
      }) {
    switch (level) {
      case FitnessLevel.beginner:
        return generateWarmupSets(workWeight, totalWarmupSets: 4);
      case FitnessLevel.intermediate:
        return generateWarmupSets(workWeight, totalWarmupSets: 3);
      case FitnessLevel.advanced:
      case FitnessLevel.elite:
        return generateWarmupSets(workWeight, totalWarmupSets: 5);
    }
  }

  static double? suggestWeightIncrease({
    required List<ProgressRecord> recentRecords,
    required double currentWeight,
    int lookbackPeriod = 3,
    int targetReps = 8,
    double repsTolerance = 1.0,
  }) {
    if (recentRecords.isEmpty) return null;

    final recent = recentRecords
        .where((r) => r.bestWeight > 0 && r.bestReps > 0)
        .take(lookbackPeriod)
        .toList();

    if (recent.isEmpty) return null;

    final bool allCompleted =
    recent.every((r) => r.bestReps >= targetReps - repsTolerance);
    if (!allCompleted) return null;

    final avgWeight = recent
        .map((r) => r.bestWeight)
        .reduce((a, b) => a + b) /
        recent.length;

    double increment;
    if (currentWeight <= 20) {
      increment = 1.0;
    } else if (currentWeight <= 50) {
      increment = 2.5;
    } else if (currentWeight <= 100) {
      increment = 5.0;
    } else {
      increment = 10.0;
    }

    double suggestedWeight = avgWeight + increment;
    if (suggestedWeight > avgWeight * 1.05) {
      suggestedWeight = (avgWeight * 1.05).roundToDouble();
    }

    return suggestedWeight;
  }

  static ProgressionStatus checkProgressionReadiness({
    required List<ExerciseSet> completedSets,
    required int targetReps,
    required double targetRpe,
  }) {
    if (completedSets.isEmpty) {
      return ProgressionStatus.insufficientData;
    }

    final allCompleted =
    completedSets.every((s) => s.status == SetStatus.completed);
    if (!allCompleted) {
      return ProgressionStatus.notAllSetsCompleted;
    }

    final repsAchieved =
    completedSets.every((s) => s.reps >= targetReps);

    final rpeValues = completedSets
        .where((s) => s.rpe != null)
        .map((s) => s.rpe!)
        .toList();

    final avgRpe = rpeValues.isEmpty
        ? 0.0
        : rpeValues.reduce((a, b) => a + b) / rpeValues.length;

    if (repsAchieved && avgRpe < targetRpe) {
      return ProgressionStatus.readyToIncrease;
    } else if (repsAchieved && avgRpe <= targetRpe) {
      return ProgressionStatus.maintain;
    } else {
      return ProgressionStatus.needsMoreWork;
    }
  }

  static Map<MuscleGroup, double> calculateMuscleVolume(
      List<WorkoutLog> recentLogs, {
        int lookbackWeeks = 4,
      }) {
    final volumeByMuscle = <MuscleGroup, double>{};
    final cutoffDate =
    DateTime.now().subtract(Duration(days: lookbackWeeks * 7));

    for (final log in recentLogs) {
      if (log.date.isBefore(cutoffDate)) continue;

      for (final exercise in log.exercisesLog) {
        final exerciseVolume = exercise.sets
            .where((s) =>
        s.status == SetStatus.completed && !s.isWarmup)
            .fold(0.0, (sum, set) => sum + set.volume);

        // Распределение по мышцам — в провайдере (там есть Exercise).
      }
    }

    return volumeByMuscle;
  }

  static List<MuscleImbalance> detectImbalances(
      Map<MuscleGroup, double> volumeByMuscle, {
        double imbalanceThreshold = 0.3,
      }) {
    final imbalances = <MuscleImbalance>[];

    final antagonistPairs = [
      [MuscleGroup.chest, MuscleGroup.back],
      [MuscleGroup.biceps, MuscleGroup.triceps],
      [MuscleGroup.quadriceps, MuscleGroup.hamstrings],
      [MuscleGroup.abs, MuscleGroup.lowerBack],
      [MuscleGroup.shoulders, MuscleGroup.lats],
    ];

    for (final pair in antagonistPairs) {
      final first = volumeByMuscle[pair[0]] ?? 0;
      final second = volumeByMuscle[pair[1]] ?? 0;

      if (first == 0 && second == 0) continue;

      double ratio;
      MuscleGroup weaker;
      MuscleGroup stronger;

      if (first > second) {
        ratio = second / (first == 0 ? 1 : first);
        weaker = pair[1];
        stronger = pair[0];
      } else {
        ratio = first / (second == 0 ? 1 : second);
        weaker = pair[0];
        stronger = pair[1];
      }

      if (ratio < (1 - imbalanceThreshold)) {
        imbalances.add(MuscleImbalance(
          weakerMuscle: weaker,
          strongerMuscle: stronger,
          ratio: ratio,
          recommendation: 'Увеличьте объём на ${weaker.displayName}',
        ));
      }
    }

    return imbalances;
  }

  static DateTime? predictGoalAchievement({
    required List<ProgressRecord> history,
    required double goalWeight,
    double weeklyIncrease = 2.5,
  }) {
    if (history.isEmpty || weeklyIncrease <= 0) return null;

    history.sort((a, b) => a.date.compareTo(b.date));
    final lastRecord = history.last;

    if (lastRecord.estimated1RM >= goalWeight) return null;

    final remaining = goalWeight - lastRecord.estimated1RM;
    final weeksNeeded = (remaining / weeklyIncrease).ceil();

    return lastRecord.date.add(Duration(days: weeksNeeded * 7));
  }

  static TrendLine calculateTrendLine(List<ProgressRecord> history) {
    if (history.length < 2) {
      return TrendLine(slope: 0, intercept: 0, confidence: 0);
    }

    final n = history.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    final firstDate = history.first.date;
    final List<double> xValues = [];
    final List<double> yValues = [];

    for (final record in history) {
      final x = record.date.difference(firstDate).inDays.toDouble();
      final y = record.estimated1RM;
      xValues.add(x);
      yValues.add(y);
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    final yMean = sumY / n;
    double ssRes = 0, ssTot = 0;
    for (int i = 0; i < n; i++) {
      final yPred = slope * xValues[i] + intercept;
      ssRes += pow(yValues[i] - yPred, 2).toDouble();
      ssTot += pow(yValues[i] - yMean, 2).toDouble();
    }
    final rSquared = ssTot > 0 ? 1 - (ssRes / ssTot) : 0.0;

    return TrendLine(
      slope: slope,
      intercept: intercept,
      confidence: rSquared,
    );
  }

  static double predictFuture1RM(TrendLine trend, int daysFromNow) {
    return trend.slope * daysFromNow + trend.intercept;
  }

  static Duration? calculateWorkoutDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    return end.difference(start);
  }

  /// ✅ старый метод — рекомендует отдых по интенсивности (для 1RM-процентов).
  static int getRecommendedRestSecondsByIntensity(double intensity) {
    if (intensity >= 90) return 180;
    if (intensity >= 80) return 120;
    if (intensity >= 70) return 90;
    if (intensity >= 60) return 60;
    return 45;
  }

  static double calculateStimulation(List<ExerciseSet> sets) {
    if (sets.isEmpty) return 0.0;
    return sets
        .where((s) => s.status == SetStatus.completed)
        .fold(0.0, (sum, set) {
      final rpeFactor =
      set.rpe != null ? (1 - set.rpe! / 10) : 0.3;
      return sum + (set.volume * rpeFactor);
    });
  }

  static List<MuscleGroup> getAntagonistMuscles(MuscleGroup muscle) {
    switch (muscle) {
      case MuscleGroup.chest:
        return [MuscleGroup.back, MuscleGroup.lats];
      case MuscleGroup.back:
      case MuscleGroup.lats:
        return [MuscleGroup.chest];
      case MuscleGroup.biceps:
        return [MuscleGroup.triceps];
      case MuscleGroup.triceps:
        return [MuscleGroup.biceps];
      case MuscleGroup.quadriceps:
        return [MuscleGroup.hamstrings];
      case MuscleGroup.hamstrings:
        return [MuscleGroup.quadriceps];
      case MuscleGroup.abs:
        return [MuscleGroup.lowerBack];
      case MuscleGroup.lowerBack:
        return [MuscleGroup.abs];
      case MuscleGroup.shoulders:
        return [MuscleGroup.lats, MuscleGroup.back];
      default:
        return [];
    }
  }

  static bool canFormSuperset(MuscleGroup muscle1, MuscleGroup muscle2) {
    return getAntagonistMuscles(muscle1).contains(muscle2) ||
        getAntagonistMuscles(muscle2).contains(muscle1);
  }
}

// ============================================================
// ✅ ВСПОМОГАТЕЛЬНЫЕ КЛАССЫ — БЕЗ ИЗМЕНЕНИЙ
// ============================================================

enum ProgressionStatus {
  readyToIncrease,
  maintain,
  needsMoreWork,
  notAllSetsCompleted,
  insufficientData,
}

extension ProgressionStatusExtension on ProgressionStatus {
  String get displayName {
    switch (this) {
      case ProgressionStatus.readyToIncrease:
        return 'Можно увеличить вес';
      case ProgressionStatus.maintain:
        return 'Сохранить текущий вес';
      case ProgressionStatus.needsMoreWork:
        return 'Нужно ещё поработать';
      case ProgressionStatus.notAllSetsCompleted:
        return 'Не все подходы выполнены';
      case ProgressionStatus.insufficientData:
        return 'Недостаточно данных';
    }
  }

  String get emoji {
    switch (this) {
      case ProgressionStatus.readyToIncrease: return '⬆️';
      case ProgressionStatus.maintain: return '➡️';
      case ProgressionStatus.needsMoreWork: return '💪';
      case ProgressionStatus.notAllSetsCompleted: return '⚠️';
      case ProgressionStatus.insufficientData: return '📊';
    }
  }
}

class MuscleImbalance {
  final MuscleGroup weakerMuscle;
  final MuscleGroup strongerMuscle;
  final double ratio;
  final String recommendation;

  MuscleImbalance({
    required this.weakerMuscle,
    required this.strongerMuscle,
    required this.ratio,
    required this.recommendation,
  });

  double get imbalancePercent => ((1 - ratio) * 100).roundToDouble();
}

class TrendLine {
  final double slope;
  final double intercept;
  final double confidence;

  TrendLine({
    required this.slope,
    required this.intercept,
    required this.confidence,
  });

  double predict(int day) => slope * day + intercept;

  String get confidenceLevel {
    if (confidence > 0.8) return 'Высокая точность';
    if (confidence > 0.5) return 'Средняя точность';
    return 'Низкая точность';
  }
}