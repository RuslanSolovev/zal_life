// features/fitness/models/enums.dart
import 'package:flutter/material.dart';

// ============================================================
// БАЗОВЫЕ ENUM'Ы (оригинал без изменений)
// ============================================================

/// Тип упражнения
enum ExerciseType {
  strength,    // силовое (тренажёры, свободные веса)
  cardio,      // кардио (бег, велосипед, плавание)
  bodyweight,  // с собственным весом
  boxing,      // бокс/груша
  yoga,        // йога/растяжка
  other,       // другое
}

/// Группы мышц (основные)
enum MuscleGroup {
  chest,         // грудь
  back,          // спина
  shoulders,     // плечи
  biceps,        // бицепс
  triceps,       // трицепс
  forearms,      // предплечья
  abs,           // пресс
  obliques,      // косые мышцы живота
  glutes,        // ягодицы
  quadriceps,    // квадрицепс
  hamstrings,    // бицепс бедра
  calves,        // икры
  traps,         // трапеции
  lats,          // широчайшие
  lowerBack,     // поясница
  fullBody,      // всё тело
  cardio_vascular, // сердечно-сосудистая
  flexibility,   // гибкость
}

/// Тип тренировочной программы
enum ProgramType {
  daily,    // на один день
  weekly,   // на неделю
  monthly,  // на месяц
}

/// Статус выполнения дня тренировки
enum WorkoutDayStatus {
  pending,    // ожидает
  completed,  // выполнена
  skipped,    // пропущена
  rest,       // день отдыха
}

/// Тип группировки упражнений
enum ExerciseGroupType {
  straight,  // обычный порядок
  superset,  // суперсет (2 упражнения)
  circuit,   // круговая (3+ упражнений)
}

/// Статус подхода
enum SetStatus {
  pending,    // не начат
  inProgress, // выполняется
  completed,  // завершён
  skipped,    // пропущен
  failed,     // не выполнен (отказ)
}

/// Пол пользователя (для схематической фигуры)
enum UserGender {
  male,
  female,
}

/// Уровень подготовки
enum FitnessLevel {
  beginner,      // новичок
  intermediate,  // средний
  advanced,      // продвинутый
  elite,         // элитный
}

/// Цель тренировок
enum FitnessGoal {
  strength,      // сила
  hypertrophy,   // масса
  endurance,     // выносливость
  weightLoss,    // похудение
  flexibility,   // гибкость
  general,       // общая физподготовка
}

// ============================================================
// РАСШИРЕНИЯ БАЗОВЫХ ENUM'ОВ (оригинал без изменений)
// ============================================================

extension ExerciseTypeExtension on ExerciseType {
  String get displayName {
    switch (this) {
      case ExerciseType.strength: return 'Силовое';
      case ExerciseType.cardio: return 'Кардио';
      case ExerciseType.bodyweight: return 'Свой вес';
      case ExerciseType.boxing: return 'Бокс';
      case ExerciseType.yoga: return 'Йога';
      case ExerciseType.other: return 'Другое';
    }
  }

  String get emoji {
    switch (this) {
      case ExerciseType.strength: return '🏋️';
      case ExerciseType.cardio: return '🏃';
      case ExerciseType.bodyweight: return '🤸';
      case ExerciseType.boxing: return '🥊';
      case ExerciseType.yoga: return '🧘';
      case ExerciseType.other: return '🔧';
    }
  }
}

extension MuscleGroupExtension on MuscleGroup {
  String get displayName {
    switch (this) {
      case MuscleGroup.chest: return 'Грудь';
      case MuscleGroup.back: return 'Спина';
      case MuscleGroup.shoulders: return 'Плечи';
      case MuscleGroup.biceps: return 'Бицепс';
      case MuscleGroup.triceps: return 'Трицепс';
      case MuscleGroup.forearms: return 'Предплечья';
      case MuscleGroup.abs: return 'Пресс';
      case MuscleGroup.obliques: return 'Косые';
      case MuscleGroup.glutes: return 'Ягодицы';
      case MuscleGroup.quadriceps: return 'Квадрицепс';
      case MuscleGroup.hamstrings: return 'Бицепс бедра';
      case MuscleGroup.calves: return 'Икры';
      case MuscleGroup.traps: return 'Трапеции';
      case MuscleGroup.lats: return 'Широчайшие';
      case MuscleGroup.lowerBack: return 'Поясница';
      case MuscleGroup.fullBody: return 'Всё тело';
      case MuscleGroup.cardio_vascular: return 'Кардио';
      case MuscleGroup.flexibility: return 'Гибкость';
    }
  }

  String get emoji {
    switch (this) {
      case MuscleGroup.chest: return '🦾';
      case MuscleGroup.back: return '🔙';
      case MuscleGroup.shoulders: return '🦿';
      case MuscleGroup.biceps: return '💪';
      case MuscleGroup.triceps: return '💪';
      case MuscleGroup.forearms: return '🤲';
      case MuscleGroup.abs: return '🏋️';
      case MuscleGroup.obliques: return '🔄';
      case MuscleGroup.glutes: return '🍑';
      case MuscleGroup.quadriceps: return '🦵';
      case MuscleGroup.hamstrings: return '🦵';
      case MuscleGroup.calves: return '🦶';
      case MuscleGroup.traps: return '🏔️';
      case MuscleGroup.lats: return '🦅';
      case MuscleGroup.lowerBack: return '🔻';
      case MuscleGroup.fullBody: return '🧍';
      case MuscleGroup.cardio_vascular: return '❤️';
      case MuscleGroup.flexibility: return '🧘';
    }
  }

  /// Цвет для отображения на схеме мышц
  Color get color {
    switch (this) {
      case MuscleGroup.chest: return const Color(0xFFE53935);
      case MuscleGroup.back: return const Color(0xFF1E88E5);
      case MuscleGroup.shoulders: return const Color(0xFFFF9800);
      case MuscleGroup.biceps: return const Color(0xFF43A047);
      case MuscleGroup.triceps: return const Color(0xFF66BB6A);
      case MuscleGroup.forearms: return const Color(0xFFA1887F);
      case MuscleGroup.abs: return const Color(0xFFFDD835);
      case MuscleGroup.obliques: return const Color(0xFFFFB300);
      case MuscleGroup.glutes: return const Color(0xFF8D6E63);
      case MuscleGroup.quadriceps: return const Color(0xFF1565C0);
      case MuscleGroup.hamstrings: return const Color(0xFF1976D2);
      case MuscleGroup.calves: return const Color(0xFF64B5F6);
      case MuscleGroup.traps: return const Color(0xFF9C27B0);
      case MuscleGroup.lats: return const Color(0xFF7B1FA2);
      case MuscleGroup.lowerBack: return const Color(0xFF6A1B9A);
      case MuscleGroup.fullBody: return const Color(0xFF607D8B);
      case MuscleGroup.cardio_vascular: return const Color(0xFFF44336);
      case MuscleGroup.flexibility: return const Color(0xFF4CAF50);
    }
  }
}

extension ProgramTypeExtension on ProgramType {
  String get displayName {
    switch (this) {
      case ProgramType.daily: return 'На день';
      case ProgramType.weekly: return 'На неделю';
      case ProgramType.monthly: return 'На месяц';
    }
  }
}

extension WorkoutDayStatusExtension on WorkoutDayStatus {
  String get displayName {
    switch (this) {
      case WorkoutDayStatus.pending: return 'Ожидает';
      case WorkoutDayStatus.completed: return 'Выполнена';
      case WorkoutDayStatus.skipped: return 'Пропущена';
      case WorkoutDayStatus.rest: return 'Отдых';
    }
  }

  Color get color {
    switch (this) {
      case WorkoutDayStatus.pending: return const Color(0xFFBDBDBD);
      case WorkoutDayStatus.completed: return const Color(0xFF4CAF50);
      case WorkoutDayStatus.skipped: return const Color(0xFFF44336);
      case WorkoutDayStatus.rest: return const Color(0xFF9E9E9E);
    }
  }

  IconData get icon {
    switch (this) {
      case WorkoutDayStatus.pending: return Icons.schedule;
      case WorkoutDayStatus.completed: return Icons.check_circle;
      case WorkoutDayStatus.skipped: return Icons.cancel;
      case WorkoutDayStatus.rest: return Icons.bedtime;
    }
  }
}

extension FitnessGoalExtension on FitnessGoal {
  String get displayName {
    switch (this) {
      case FitnessGoal.strength: return 'Сила';
      case FitnessGoal.hypertrophy: return 'Масса';
      case FitnessGoal.endurance: return 'Выносливость';
      case FitnessGoal.weightLoss: return 'Похудение';
      case FitnessGoal.flexibility: return 'Гибкость';
      case FitnessGoal.general: return 'ОФП';
    }
  }
}

// ============================================================
// 🆕 МЕТРИКИ — что именно измеряется в подходе
// ============================================================

/// Атомарные единицы измерения, которые может собирать упражнение.
/// Список валидных метрик для упражнения определяется ExerciseFormat
/// (см. metricsByFormat ниже). ExerciseSet хранит только те метрики,
/// которые реально заполнены — остальные остаются null.
enum ExerciseMetric {
  // --- силовые ---
  reps,
  weight,
  rpe,
  restSeconds,
  // --- кардио ---
  duration,
  distance,
  pace,
  heartRate,
  calories,
  incline,
  resistance,
  // --- бокс ---
  rounds,
  roundDuration,
  restBetweenRounds,
  punches,
  // --- статика / гибкость / свободное ---
  holdSeconds,
  tempo,
  intensity,
}

extension ExerciseMetricExtension on ExerciseMetric {
  String get displayName {
    switch (this) {
      case ExerciseMetric.reps: return 'Повторы';
      case ExerciseMetric.weight: return 'Вес';
      case ExerciseMetric.rpe: return 'RPE';
      case ExerciseMetric.restSeconds: return 'Отдых';
      case ExerciseMetric.duration: return 'Время';
      case ExerciseMetric.distance: return 'Дистанция';
      case ExerciseMetric.pace: return 'Темп';
      case ExerciseMetric.heartRate: return 'Пульс';
      case ExerciseMetric.calories: return 'Калории';
      case ExerciseMetric.incline: return 'Наклон';
      case ExerciseMetric.resistance: return 'Сопротивление';
      case ExerciseMetric.rounds: return 'Раунды';
      case ExerciseMetric.roundDuration: return 'Длит. раунда';
      case ExerciseMetric.restBetweenRounds: return 'Отдых';
      case ExerciseMetric.punches: return 'Удары';
      case ExerciseMetric.holdSeconds: return 'Удержание';
      case ExerciseMetric.tempo: return 'Темп';
      case ExerciseMetric.intensity: return 'Интенсивность';
    }
  }

  String get shortLabel {
    switch (this) {
      case ExerciseMetric.reps: return 'ПОВТ';
      case ExerciseMetric.weight: return 'ВЕС';
      case ExerciseMetric.rpe: return 'RPE';
      case ExerciseMetric.restSeconds: return 'ОТДЫХ';
      case ExerciseMetric.duration: return 'ВРЕМЯ';
      case ExerciseMetric.distance: return 'КМ';
      case ExerciseMetric.pace: return 'ТЕМП';
      case ExerciseMetric.heartRate: return 'ПУЛЬС';
      case ExerciseMetric.calories: return 'ККАЛ';
      case ExerciseMetric.incline: return 'НАКЛОН';
      case ExerciseMetric.resistance: return 'СОПР.';
      case ExerciseMetric.rounds: return 'РАУНД';
      case ExerciseMetric.roundDuration: return 'ДЛИТ.';
      case ExerciseMetric.restBetweenRounds: return 'ОТДЫХ';
      case ExerciseMetric.punches: return 'УДАРЫ';
      case ExerciseMetric.holdSeconds: return 'УДЕРЖ.';
      case ExerciseMetric.tempo: return 'ТЕМПО';
      case ExerciseMetric.intensity: return 'ИНТЕНС.';
    }
  }

  String get unit {
    switch (this) {
      case ExerciseMetric.reps: return 'повт';
      case ExerciseMetric.weight: return 'кг';
      case ExerciseMetric.rpe: return '';
      case ExerciseMetric.restSeconds: return 'сек';
      case ExerciseMetric.duration: return 'сек';
      case ExerciseMetric.distance: return 'км';
      case ExerciseMetric.pace: return 'мин/км';
      case ExerciseMetric.heartRate: return 'уд/мин';
      case ExerciseMetric.calories: return 'ккал';
      case ExerciseMetric.incline: return '%';
      case ExerciseMetric.resistance: return '';
      case ExerciseMetric.rounds: return 'раунд';
      case ExerciseMetric.roundDuration: return 'сек';
      case ExerciseMetric.restBetweenRounds: return 'сек';
      case ExerciseMetric.punches: return 'удар';
      case ExerciseMetric.holdSeconds: return 'сек';
      case ExerciseMetric.tempo: return '';
      case ExerciseMetric.intensity: return '/10';
    }
  }

  String get emoji {
    switch (this) {
      case ExerciseMetric.reps: return '🔢';
      case ExerciseMetric.weight: return '⚖️';
      case ExerciseMetric.rpe: return '💯';
      case ExerciseMetric.restSeconds: return '⏸️';
      case ExerciseMetric.duration: return '⏱️';
      case ExerciseMetric.distance: return '📏';
      case ExerciseMetric.pace: return '⚡';
      case ExerciseMetric.heartRate: return '❤️';
      case ExerciseMetric.calories: return '🔥';
      case ExerciseMetric.incline: return '⛰️';
      case ExerciseMetric.resistance: return '🎚️';
      case ExerciseMetric.rounds: return '🔔';
      case ExerciseMetric.roundDuration: return '⏱️';
      case ExerciseMetric.restBetweenRounds: return '⏸️';
      case ExerciseMetric.punches: return '🥊';
      case ExerciseMetric.holdSeconds: return '🧘';
      case ExerciseMetric.tempo: return '🎵';
      case ExerciseMetric.intensity: return '💪';
    }
  }

  bool get isNumeric => this != ExerciseMetric.tempo;

  bool get isDecimal {
    return this == ExerciseMetric.weight ||
        this == ExerciseMetric.distance ||
        this == ExerciseMetric.pace ||
        this == ExerciseMetric.incline ||
        this == ExerciseMetric.resistance ||
        this == ExerciseMetric.intensity;
  }
}

// ============================================================
// 🆕 ФОРМАТ ВЫПОЛНЕНИЯ — как упражнение структурирует подходы
// ============================================================

/// Формат — это «сценарий» выполнения. Определяет,
/// какие метрики имеет смысл собирать (см. metricsByFormat).
enum ExerciseFormat {
  setsReps,     // 3×10 @ 80кг (классика)
  timedSets,    // 3×60сек (планка, тим-сеты)
  intervals,    // 8×400м, work/rest (интервалы)
  rounds,       // 3 раунда × 3 мин (бокс/груша)
  continuous,   // 5 км / 30 мин (непрерывный бег)
  hold,         // статика: сколько держу
  freeform,     // своя форма
}

extension ExerciseFormatExtension on ExerciseFormat {
  String get displayName {
    switch (this) {
      case ExerciseFormat.setsReps: return 'Подходы × повторы';
      case ExerciseFormat.timedSets: return 'Подходы × время';
      case ExerciseFormat.intervals: return 'Интервалы';
      case ExerciseFormat.rounds: return 'Раунды';
      case ExerciseFormat.continuous: return 'Непрерывно';
      case ExerciseFormat.hold: return 'Удержание';
      case ExerciseFormat.freeform: return 'Свободно';
    }
  }

  String get shortName {
    switch (this) {
      case ExerciseFormat.setsReps: return 'ПОДХОДЫ';
      case ExerciseFormat.timedSets: return 'ТАЙМ-СЕТЫ';
      case ExerciseFormat.intervals: return 'ИНТЕРВАЛЫ';
      case ExerciseFormat.rounds: return 'РАУНДЫ';
      case ExerciseFormat.continuous: return 'НЕПРЕРЫВНО';
      case ExerciseFormat.hold: return 'СТАТИКА';
      case ExerciseFormat.freeform: return 'СВОБОДНО';
    }
  }

  String get description {
    switch (this) {
      case ExerciseFormat.setsReps: return 'Классика: вес × повторы';
      case ExerciseFormat.timedSets: return 'Каждый подход — на время';
      case ExerciseFormat.intervals:
        return 'Работа / отдых, дистанция или время';
      case ExerciseFormat.rounds: return 'Бокс/груша: раунды и отдых';
      case ExerciseFormat.continuous: return 'Один заход: дистанция и время';
      case ExerciseFormat.hold: return 'Статика: сколько держу';
      case ExerciseFormat.freeform: return 'Свободная форма';
    }
  }

  String get emoji {
    switch (this) {
      case ExerciseFormat.setsReps: return '🏋️';
      case ExerciseFormat.timedSets: return '⏱️';
      case ExerciseFormat.intervals: return '🔁';
      case ExerciseFormat.rounds: return '🥊';
      case ExerciseFormat.continuous: return '🏃';
      case ExerciseFormat.hold: return '🧘';
      case ExerciseFormat.freeform: return '✨';
    }
  }

  bool get usesRest =>
      this == ExerciseFormat.setsReps ||
          this == ExerciseFormat.timedSets ||
          this == ExerciseFormat.intervals ||
          this == ExerciseFormat.rounds;

  bool get isStrengthStyle => this == ExerciseFormat.setsReps;

  bool get isDistanceBased =>
      this == ExerciseFormat.continuous || this == ExerciseFormat.intervals;

  bool get isRoundsBased => this == ExerciseFormat.rounds;

  bool get isTimed =>
      this == ExerciseFormat.timedSets ||
          this == ExerciseFormat.continuous ||
          this == ExerciseFormat.hold;

  /// Главная метрика для отображения в карточках/герое.
  ExerciseMetric get primaryMetric {
    switch (this) {
      case ExerciseFormat.setsReps: return ExerciseMetric.weight;
      case ExerciseFormat.timedSets: return ExerciseMetric.duration;
      case ExerciseFormat.intervals: return ExerciseMetric.distance;
      case ExerciseFormat.rounds: return ExerciseMetric.rounds;
      case ExerciseFormat.continuous: return ExerciseMetric.distance;
      case ExerciseFormat.hold: return ExerciseMetric.holdSeconds;
      case ExerciseFormat.freeform: return ExerciseMetric.duration;
    }
  }

  /// Все метрики, которые собираются для формата.
  List<ExerciseMetric> get metrics =>
      metricsByFormat[this] ?? const <ExerciseMetric>[];

  bool hasMetric(ExerciseMetric m) => metrics.contains(m);
}

// ============================================================
// 🗺️ СХЕМЫ: дефолты по типу, доступные альтернативы, метрики по формату
// ============================================================

/// Дефолтный формат для типа упражнения.
const Map<ExerciseType, ExerciseFormat> defaultFormatByType = {
  ExerciseType.strength: ExerciseFormat.setsReps,
  ExerciseType.cardio: ExerciseFormat.continuous,
  ExerciseType.bodyweight: ExerciseFormat.setsReps,
  ExerciseType.boxing: ExerciseFormat.rounds,
  ExerciseType.yoga: ExerciseFormat.hold,
  ExerciseType.other: ExerciseFormat.timedSets,
};

/// Допустимые форматы для типа (для выпадашки в редакторе).
const Map<ExerciseType, List<ExerciseFormat>> availableFormatsByType = {
  ExerciseType.strength: [
    ExerciseFormat.setsReps,
    ExerciseFormat.timedSets,
  ],
  ExerciseType.cardio: [
    ExerciseFormat.continuous,
    ExerciseFormat.intervals,
    ExerciseFormat.timedSets,
  ],
  ExerciseType.bodyweight: [
    ExerciseFormat.setsReps,
    ExerciseFormat.timedSets,
    ExerciseFormat.hold,
  ],
  ExerciseType.boxing: [
    ExerciseFormat.rounds,
    ExerciseFormat.intervals,
  ],
  ExerciseType.yoga: [
    ExerciseFormat.hold,
    ExerciseFormat.timedSets,
  ],
  ExerciseType.other: [
    ExerciseFormat.timedSets,
    ExerciseFormat.freeform,
  ],
};

/// Список метрик, собираемых для каждого формата.
/// Именно этот список определяет UI-поля в редакторе/активном экране.
const Map<ExerciseFormat, List<ExerciseMetric>> metricsByFormat = {
  ExerciseFormat.setsReps: [
    ExerciseMetric.weight,
    ExerciseMetric.reps,
    ExerciseMetric.rpe,
    ExerciseMetric.restSeconds,
  ],
  ExerciseFormat.timedSets: [
    ExerciseMetric.duration,
    ExerciseMetric.intensity,
    ExerciseMetric.restSeconds,
  ],
  ExerciseFormat.intervals: [
    ExerciseMetric.distance,
    ExerciseMetric.duration,
    ExerciseMetric.pace,
    ExerciseMetric.heartRate,
    ExerciseMetric.restSeconds,
  ],
  ExerciseFormat.rounds: [
    ExerciseMetric.rounds,
    ExerciseMetric.roundDuration,
    ExerciseMetric.restBetweenRounds,
    ExerciseMetric.punches,
    ExerciseMetric.intensity,
  ],
  ExerciseFormat.continuous: [
    ExerciseMetric.distance,
    ExerciseMetric.duration,
    ExerciseMetric.pace,
    ExerciseMetric.heartRate,
    ExerciseMetric.calories,
    ExerciseMetric.incline,
  ],
  ExerciseFormat.hold: [
    ExerciseMetric.holdSeconds,
    ExerciseMetric.intensity,
  ],
  ExerciseFormat.freeform: [
    ExerciseMetric.duration,
    ExerciseMetric.intensity,
    ExerciseMetric.calories,
  ],
};

// ============================================================
// 🆕 РАСШИРЕНИЕ ExerciseType — формат-хелперы
// ============================================================

extension ExerciseTypeFormatExtension on ExerciseType {
  ExerciseFormat get defaultFormat =>
      defaultFormatByType[this] ?? ExerciseFormat.freeform;

  List<ExerciseFormat> get availableFormats =>
      availableFormatsByType[this] ?? [ExerciseFormat.freeform];

  /// Эвристика для миграции старых упражнений без явного format
  ExerciseFormat inferFormatFromName(String name) {
    final lower = name.toLowerCase();

    // ── КАРДИО ────────────────────────────────────────────
    if (this == ExerciseType.cardio) {
      // Интервалы / спринты
      if (lower.contains('интерв') ||
          lower.contains('interval') ||
          lower.contains('спринт') ||
          lower.contains('sprint')) {
        return ExerciseFormat.intervals;
      }
      // Скакалки и прыжковые — на время
      if (lower.contains('скакалк') ||
          lower.contains('прыжк') ||
          lower.contains('джамп') ||
          lower.contains('джек') ||
          lower.contains('джак')) {
        return ExerciseFormat.timedSets;
      }
      // Всё остальное (бег, вело, плавание) — непрерывно
      return ExerciseFormat.continuous;
    }

    // ── БОКС ──────────────────────────────────────────────
    if (this == ExerciseType.boxing) return ExerciseFormat.rounds;

    // ── ЙОГА ──────────────────────────────────────────────
    if (this == ExerciseType.yoga) return ExerciseFormat.hold;

    // ── СИЛА ──────────────────────────────────────────────
    if (this == ExerciseType.strength) {
      // Переноски на время
      if (lower.contains('фермер') ||
          lower.contains('прогулк') ||
          lower.contains('переноск')) {
        return ExerciseFormat.timedSets;
      }
      return ExerciseFormat.setsReps;
    }

    // ── СВОЙ ВЕС ──────────────────────────────────────────
    if (this == ExerciseType.bodyweight) {
      // Статика
      if (lower.contains('планк') ||
          lower.contains('вакуум') ||
          lower.contains('вис ') ||
          lower.contains('удерж') ||
          lower.contains('статика')) {
        return ExerciseFormat.hold;
      }
      // Упражнения на время
      if (lower.contains('альпинист') ||
          lower.contains('ножниц') ||
          lower.contains('джек') ||
          lower.contains('джак') ||
          lower.contains('маятник')) {
        return ExerciseFormat.timedSets;
      }
      // Всё остальное — reps (берпи, отжимания, подтягивания)
      return ExerciseFormat.setsReps;
    }

    // ── OTHER ─────────────────────────────────────────────
    return defaultFormat;
  }
}

// ============================================================
// 🎯 ЦЕЛИ (TARGETS)
// ============================================================

/// Тип фитнес-цели.
/// 🆕 добавлены boxingRounds и holdTime.
enum FitnessTargetType {
  strengthMax,        // Максимальный вес (1ПМ): пожать 100 кг
  strengthReps,       // Вес × повторения: 50 кг × 50 раз
  bodyweightReps,     // Собственный вес: подтянуться 10 раз
  cardioDistance,     // Дистанция: пробежать 5 км
  cardioTime,         // Время на дистанцию: 5 км за 25 мин
  endurance,          // Выносливость: планка 3 мин
  bodyMeasurement,    // Обхват: бицепс 40 см
  bodyWeight,         // Вес тела: похудеть до 75 кг
  volume,             // Объём за тренировку: 10 тонн
  custom,             // Своя цель
  boxingRounds,       // 🆕 Раунды: 100 раундов за месяц
  holdTime,           // 🆕 Статика: планка 3 мин
}

/// Статус фитнес-цели
enum FitnessTargetStatus {
  active,      // В процессе
  completed,   // Достигнута
  paused,      // На паузе
  abandoned,   // Отменена
}

extension FitnessTargetTypeExtension on FitnessTargetType {
  String get displayName {
    switch (this) {
      case FitnessTargetType.strengthMax: return 'Максимальный вес';
      case FitnessTargetType.strengthReps: return 'Вес × повторения';
      case FitnessTargetType.bodyweightReps: return 'Свой вес';
      case FitnessTargetType.cardioDistance: return 'Дистанция';
      case FitnessTargetType.cardioTime: return 'Время на дистанции';
      case FitnessTargetType.endurance: return 'Выносливость';
      case FitnessTargetType.bodyMeasurement: return 'Обхват тела';
      case FitnessTargetType.bodyWeight: return 'Вес тела';
      case FitnessTargetType.volume: return 'Объём тренировки';
      case FitnessTargetType.custom: return 'Своя цель';
      case FitnessTargetType.boxingRounds: return 'Раунды';
      case FitnessTargetType.holdTime: return 'Удержание';
    }
  }

  String get emoji {
    switch (this) {
      case FitnessTargetType.strengthMax: return '🏋️';
      case FitnessTargetType.strengthReps: return '💪';
      case FitnessTargetType.bodyweightReps: return '🤸';
      case FitnessTargetType.cardioDistance: return '🏃';
      case FitnessTargetType.cardioTime: return '⏱️';
      case FitnessTargetType.endurance: return '⚡';
      case FitnessTargetType.bodyMeasurement: return '📏';
      case FitnessTargetType.bodyWeight: return '⚖️';
      case FitnessTargetType.volume: return '📊';
      case FitnessTargetType.custom: return '🎯';
      case FitnessTargetType.boxingRounds: return '🥊';
      case FitnessTargetType.holdTime: return '🧘';
    }
  }

  String get defaultUnit {
    switch (this) {
      case FitnessTargetType.strengthMax: return 'кг';
      case FitnessTargetType.strengthReps: return 'кг×раз';
      case FitnessTargetType.bodyweightReps: return 'раз';
      case FitnessTargetType.cardioDistance: return 'км';
      case FitnessTargetType.cardioTime: return 'мин';
      case FitnessTargetType.endurance: return 'сек';
      case FitnessTargetType.bodyMeasurement: return 'см';
      case FitnessTargetType.bodyWeight: return 'кг';
      case FitnessTargetType.volume: return 'кг';
      case FitnessTargetType.custom: return '';
      case FitnessTargetType.boxingRounds: return 'раунд';
      case FitnessTargetType.holdTime: return 'сек';
    }
  }

  /// Требует привязки к упражнению? (для UI-формы создания цели)
  bool get requiresExercise =>
      this == FitnessTargetType.strengthMax ||
          this == FitnessTargetType.strengthReps ||
          this == FitnessTargetType.bodyweightReps ||
          this == FitnessTargetType.endurance ||
          this == FitnessTargetType.boxingRounds ||
          this == FitnessTargetType.holdTime;

  /// Требует выбора «обхвата» (chest/waist/...)?
  bool get requiresMeasurement =>
      this == FitnessTargetType.bodyMeasurement;
}

extension FitnessTargetStatusExtension on FitnessTargetStatus {
  String get displayName {
    switch (this) {
      case FitnessTargetStatus.active: return 'В процессе';
      case FitnessTargetStatus.completed: return 'Достигнута';
      case FitnessTargetStatus.paused: return 'На паузе';
      case FitnessTargetStatus.abandoned: return 'Отменена';
    }
  }

  Color get color {
    switch (this) {
      case FitnessTargetStatus.active: return const Color(0xFFFF6B35);
      case FitnessTargetStatus.completed: return const Color(0xFF4CAF50);
      case FitnessTargetStatus.paused: return Colors.orange;
      case FitnessTargetStatus.abandoned: return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case FitnessTargetStatus.active: return Icons.bolt_rounded;
      case FitnessTargetStatus.completed: return Icons.emoji_events_rounded;
      case FitnessTargetStatus.paused: return Icons.pause_circle_rounded;
      case FitnessTargetStatus.abandoned: return Icons.close_rounded;
    }
  }
}