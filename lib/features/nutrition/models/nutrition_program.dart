import 'dart:convert';
import 'nutrition_models.dart';

enum ProgramMode { byKbju, byMeals }

extension ProgramModeX on ProgramMode {
  String get label => this == ProgramMode.byKbju ? 'По КБЖУ' : 'По приёмам';
  String get hint => this == ProgramMode.byKbju
      ? 'Только цели на день, приёмы опциональны'
      : 'Каждый приём получает своё КБЖУ';
}

enum PlanDayType {
  regular, training, cheat, vacation;

  String get label => switch (this) {
    regular => 'Обычный',
    training => 'Тренировка',
    cheat => 'Читмил',
    vacation => 'Отпуск',
  };

  String get emoji => switch (this) {
    regular => '',
    training => '💪',
    cheat => '🍕',
    vacation => '🏖️',
  };

  bool get countsForStats => this == regular || this == training;

  static PlanDayType fromName(String? n) =>
      PlanDayType.values.firstWhere((e) => e.name == n, orElse: () => regular);
}

class MealSlotTarget {
  final MealType mealType;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  const MealSlotTarget({
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  Map<String, dynamic> toMap() => {
    'mealType': mealType.name,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
  };

  factory MealSlotTarget.fromMap(Map<String, dynamic> m) => MealSlotTarget(
    mealType: MealType.values.firstWhere(
            (e) => e.name == m['mealType'],
        orElse: () => MealType.other),
    calories: (m['calories'] as num?)?.toDouble() ?? 0,
    protein: (m['protein'] as num?)?.toDouble() ?? 0,
    fat: (m['fat'] as num?)?.toDouble() ?? 0,
    carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
  );
}

class NutritionProgram {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime endDate;
  final ProgramMode mode;
  final double targetCalories;
  final double targetProtein;
  final double targetFat;
  final double targetCarbs;
  final List<MealSlotTarget> slots;
  final bool isActive;
  final String? backgroundImage; // 🆕 ДОБАВЛЕНО

  const NutritionProgram({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.mode,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetFat,
    required this.targetCarbs,
    this.slots = const [],
    this.isActive = true,
    this.backgroundImage, // 🆕 ДОБАВЛЕНО
  });

  int get totalDays => endDate.difference(startDate).inDays + 1;

  MealSlotTarget? slotFor(MealType t) {
    for (final s in slots) {
      if (s.mealType == t) return s;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'startDate': startDate.toIso8601String().split('T').first,
    'endDate': endDate.toIso8601String().split('T').first,
    'mode': mode.name,
    'targetCalories': targetCalories,
    'targetProtein': targetProtein,
    'targetFat': targetFat,
    'targetCarbs': targetCarbs,
    'slots': jsonEncode(slots.map((s) => s.toMap()).toList()),
    'isActive': isActive ? 1 : 0,
    'backgroundImage': backgroundImage, // 🆕 ДОБАВЛЕНО
  };

  factory NutritionProgram.fromMap(Map<String, dynamic> m) => NutritionProgram(
    id: m['id'] as String,
    name: m['name'] as String,
    createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
        DateTime.now(),
    startDate: DateTime.parse(m['startDate'] as String),
    endDate: DateTime.parse(m['endDate'] as String),
    mode: ProgramMode.values.firstWhere(
            (e) => e.name == m['mode'],
        orElse: () => ProgramMode.byKbju),
    targetCalories: (m['targetCalories'] as num).toDouble(),
    targetProtein: (m['targetProtein'] as num).toDouble(),
    targetFat: (m['targetFat'] as num).toDouble(),
    targetCarbs: (m['targetCarbs'] as num).toDouble(),
    slots: _decodeSlots(m['slots']),
    isActive: (m['isActive'] as num?)?.toInt() == 1,
    backgroundImage: m['backgroundImage'] as String?, // 🆕 ДОБАВЛЕНО
  );

  static List<MealSlotTarget> _decodeSlots(dynamic raw) {
    try {
      final d = jsonDecode(raw as String? ?? '[]');
      if (d is! List) return const [];
      return d
          .whereType<Map>()
          .map((s) => MealSlotTarget.fromMap(Map<String, dynamic>.from(s)))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}