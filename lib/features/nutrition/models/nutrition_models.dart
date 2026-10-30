import 'dart:convert';
import 'package:flutter/material.dart';

// ==================== ПРОДУКТ ====================

class FoodProduct {
  final String id;
  final String name;
  final String category;
  final double calories; // на 100г
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final bool isCustom;
  final String? barcode;
  final String? imageUrl;
  final bool isFavorite;

  FoodProduct({
    required this.id,
    required this.name,
    this.category = 'other',
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.fiber = 0,
    this.isCustom = false,
    this.barcode,
    this.imageUrl,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'fiber': fiber,
    'isCustom': isCustom ? 1 : 0,
    'barcode': barcode,
    'imageUrl': imageUrl,
    'isFavorite': isFavorite ? 1 : 0,
    'createdAt': DateTime.now().toIso8601String(),
  };

  factory FoodProduct.fromMap(Map<String, dynamic> m) => FoodProduct(
    id: m['id'] as String,
    name: m['name'] as String,
    category: (m['category'] as String?) ?? 'other',
    calories: (m['calories'] as num).toDouble(),
    protein: (m['protein'] as num).toDouble(),
    fat: (m['fat'] as num).toDouble(),
    carbs: (m['carbs'] as num).toDouble(),
    fiber: (m['fiber'] as num?)?.toDouble() ?? 0,
    isCustom: (m['isCustom'] as int?) == 1,
    barcode: m['barcode'] as String?,
    imageUrl: m['imageUrl'] as String?,
    isFavorite: (m['isFavorite'] as int?) == 1,
  );

  /// КБЖУ для произвольной массы (в граммах)
  ({double calories, double protein, double fat, double carbs}) forGrams(double grams) {
    final k = grams / 100;
    return (
    calories: calories * k,
    protein: protein * k,
    fat: fat * k,
    carbs: carbs * k,
    );
  }

  String get categoryEmoji {
    switch (category) {
      case 'meat': return '🥩';
      case 'fish': return '🐟';
      case 'dairy': return '🥛';
      case 'grains': return '🌾';
      case 'vegetables': return '🥬';
      case 'fruits': return '🍎';
      case 'nuts': return '🥜';
      case 'seeds': return '🌱';
      case 'legumes': return '🫘';
      case 'oils': return '🫒';
      case 'sweets': return '🍫';
      case 'drinks': return '☕';
      case 'bakery': return '🥐';
      case 'fastfood': return '🍔';
      case 'supplements': return '💊';
      case 'sauces': return '🧂';
      default: return '🍽️';
    }
  }

  String get categoryName {
    switch (category) {
      case 'meat': return 'Мясо';
      case 'fish': return 'Рыба';
      case 'dairy': return 'Молочка';
      case 'grains': return 'Крупы';
      case 'vegetables': return 'Овощи';
      case 'fruits': return 'Фрукты';
      case 'nuts': return 'Орехи';
      case 'seeds': return 'Семена';
      case 'legumes': return 'Бобовые';
      case 'oils': return 'Масла';
      case 'sweets': return 'Сладости';
      case 'drinks': return 'Напитки';
      case 'bakery': return 'Выпечка';
      case 'fastfood': return 'Фастфуд';
      case 'supplements': return 'Добавки';
      case 'sauces': return 'Соусы';
      default: return 'Другое';
    }
  }
}

// ==================== ЗАПИСЬ В ДНЕВНИКЕ ====================

enum MealType {
  breakfast, snack1, lunch, snack2, dinner, other;

  String get displayName {
    switch (this) {
      case MealType.breakfast: return 'Завтрак';
      case MealType.snack1: return 'Перекус';
      case MealType.lunch: return 'Обед';
      case MealType.snack2: return 'Полдник';
      case MealType.dinner: return 'Ужин';
      case MealType.other: return 'Другое';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast: return '🌅';
      case MealType.snack1: return '🍎';
      case MealType.lunch: return '☀️';
      case MealType.snack2: return '🫐';
      case MealType.dinner: return '🌙';
      case MealType.other: return '🍽️';
    }
  }

  static MealType suggestForNow() {
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 13) return MealType.snack1;
    if (hour < 16) return MealType.lunch;
    if (hour < 19) return MealType.snack2;
    return MealType.dinner;
  }
}

class FoodDiaryEntry {
  final String id;
  final DateTime date;
  final MealType mealType;
  final String productId;
  final double grams;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final String? time;
  final String? note;
  final String productName;
  final String productCategory;

  // НОВОЕ: привязка к шаблону (блюду)
  final String? templateId;
  final String? templateName;

  FoodDiaryEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.productId,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.time,
    this.note,
    required this.productName,
    this.productCategory = 'other',
    this.templateId,
    this.templateName,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String().split('T').first,
    'mealType': mealType.name,
    'productId': productId,
    'grams': grams,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'time': time ?? DateTime.now().toIso8601String(),
    'note': note,
    'templateId': templateId,
    'templateName': templateName,
    'createdAt': DateTime.now().toIso8601String(),
  };

  factory FoodDiaryEntry.fromMap(Map<String, dynamic> m, FoodProduct? product) =>
      FoodDiaryEntry(
        id: m['id'] as String,
        date: DateTime.parse(m['date'] as String),
        mealType: MealType.values.firstWhere(
              (t) => t.name == m['mealType'],
          orElse: () => MealType.other,
        ),
        productId: m['productId'] as String,
        grams: (m['grams'] as num).toDouble(),
        calories: (m['calories'] as num).toDouble(),
        protein: (m['protein'] as num).toDouble(),
        fat: (m['fat'] as num).toDouble(),
        carbs: (m['carbs'] as num).toDouble(),
        time: m['time'] as String?,
        note: m['note'] as String?,
        productName: product?.name ?? 'Удалённый продукт',
        productCategory: product?.category ?? 'other',
        templateId: m['templateId'] as String?,
        templateName: m['templateName'] as String?,
      );
}

// ==================== ЦЕЛИ ПИТАНИЯ ====================

class NutritionGoals {
  final String id;
  final DateTime? date; // null = дефолтные цели
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final int waterMl;
  final bool isActive;

  NutritionGoals({
    required this.id,
    this.date,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.waterMl = 2000,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date?.toIso8601String().split('T').first,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'waterMl': waterMl,
    'isActive': isActive ? 1 : 0,
    'createdAt': DateTime.now().toIso8601String(),
  };

  factory NutritionGoals.fromMap(Map<String, dynamic> m) => NutritionGoals(
    id: m['id'] as String,
    date: m['date'] != null ? DateTime.tryParse(m['date'] as String) : null,
    calories: (m['calories'] as num).toDouble(),
    protein: (m['protein'] as num).toDouble(),
    fat: (m['fat'] as num).toDouble(),
    carbs: (m['carbs'] as num).toDouble(),
    waterMl: (m['waterMl'] as int?) ?? 2000,
    isActive: (m['isActive'] as int?) == 1,
  );

  NutritionGoals copyWith({
    double? calories, double? protein, double? fat,
    double? carbs, int? waterMl, bool? isActive, DateTime? date,
  }) => NutritionGoals(
    id: id,
    date: date ?? this.date,
    calories: calories ?? this.calories,
    protein: protein ?? this.protein,
    fat: fat ?? this.fat,
    carbs: carbs ?? this.carbs,
    waterMl: waterMl ?? this.waterMl,
    isActive: isActive ?? this.isActive,
  );

  /// Рассчитать цели по параметрам (формула Миффлина-Сан Жеора)
  static NutritionGoals calculate({
    required String id,
    required double weight,
    required double height,
    required int age,
    required bool isMale,
    required double activityFactor, // 1.2 - 1.9
    required String goal, // 'lose' | 'maintain' | 'gain'
    DateTime? date,
  }) {
    // Базовый метаболизм
    final bmr = isMale
        ? (10 * weight + 6.25 * height - 5 * age + 5)
        : (10 * weight + 6.25 * height - 5 * age - 161);

    double tdee = bmr * activityFactor;

    // Корректировка под цель
    switch (goal) {
      case 'lose': tdee *= 0.8; break;
      case 'gain': tdee *= 1.15; break;
    }

    // Распределение БЖУ
    double pRatio, fRatio, cRatio;
    switch (goal) {
      case 'lose':
        pRatio = 0.40; fRatio = 0.30; cRatio = 0.30;
        break;
      case 'gain':
        pRatio = 0.30; fRatio = 0.25; cRatio = 0.45;
        break;
      default:
        pRatio = 0.30; fRatio = 0.30; cRatio = 0.40;
    }

    return NutritionGoals(
      id: id,
      date: date,
      calories: tdee.roundToDouble(),
      protein: ((tdee * pRatio) / 4).roundToDouble(), // 4 ккал/г
      fat: ((tdee * fRatio) / 9).roundToDouble(),     // 9 ккал/г
      carbs: ((tdee * cRatio) / 4).roundToDouble(),   // 4 ккал/г
      waterMl: (weight * 35).round(), // 35 мл на кг веса
    );
  }
}

// ==================== ШАБЛОН ПРИЁМА ====================

class MealTemplateItem {
  final String productId;
  final double grams;
  final String name;

  MealTemplateItem({required this.productId, required this.grams, required this.name});

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'grams': grams,
    'name': name,
  };

  factory MealTemplateItem.fromMap(Map<String, dynamic> m) => MealTemplateItem(
    productId: m['productId'] as String,
    grams: (m['grams'] as num).toDouble(),
    name: (m['name'] as String?) ?? '',
  );
}

class MealTemplate {
  final String id;
  final String name;
  final List<MealTemplateItem> items;

  MealTemplate({required this.id, required this.name, required this.items});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'items': jsonEncode(items.map((i) => i.toMap()).toList()),
    'createdAt': DateTime.now().toIso8601String(),
  };

  factory MealTemplate.fromMap(Map<String, dynamic> m) => MealTemplate(
    id: m['id'] as String,
    name: m['name'] as String,
    items: (jsonDecode(m['items'] as String) as List)
        .map((i) => MealTemplateItem.fromMap(Map<String, dynamic>.from(i as Map)))
        .toList(),
  );
}

// ==================== ВОДА ====================

class WaterEntry {
  final String id;
  final DateTime date;
  final int amountMl;
  final String? time;

  WaterEntry({required this.id, required this.date, required this.amountMl, this.time});

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String().split('T').first,
    'amountMl': amountMl,
    'time': time ?? DateTime.now().toIso8601String(),
    'createdAt': DateTime.now().toIso8601String(),
  };

  factory WaterEntry.fromMap(Map<String, dynamic> m) => WaterEntry(
    id: m['id'] as String,
    date: DateTime.parse(m['date'] as String),
    amountMl: m['amountMl'] as int,
    time: m['time'] as String?,
  );
}

// ==================== ДНЕВНАЯ СВОДКА ====================

class DailyNutritionSummary {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final int waterMl;
  final int entriesCount;

  const DailyNutritionSummary({
    this.calories = 0, this.protein = 0, this.fat = 0,
    this.carbs = 0, this.waterMl = 0, this.entriesCount = 0,
  });

  double percentOf(NutritionGoals g) =>
      g.calories > 0 ? (calories / g.calories).clamp(0, 2) : 0;

  double proteinPercentOf(NutritionGoals g) =>
      g.protein > 0 ? (protein / g.protein).clamp(0, 2) : 0;

  double fatPercentOf(NutritionGoals g) =>
      g.fat > 0 ? (fat / g.fat).clamp(0, 2) : 0;

  double carbsPercentOf(NutritionGoals g) =>
      g.carbs > 0 ? (carbs / g.carbs).clamp(0, 2) : 0;

  double waterPercentOf(NutritionGoals g) =>
      g.waterMl > 0 ? (waterMl / g.waterMl).clamp(0, 2) : 0;
}

// ==================== ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ====================

enum Gender { male, female }

enum ActivityLevel {
  sedentary,    // Сидячий образ жизни, мало движения
  light,        // Лёгкая активность 1-2 раза в неделю
  moderate,     // Умеренная активность 3-5 раз в неделю
  active,       // Активный образ жизни 6-7 раз в неделю
  veryActive,   // Очень активный, физическая работа
  professional, // Профессиональный спортсмен
}

enum GoalType {
  maintain,      // Поддержание веса
  lose,          // Похудение
  gain,          // Набор веса
  muscleGain,    // Набор мышечной массы
  recomposition, // Ре-композиция (сжигание жира + набор мышц)
}

enum GoalPace {
  slow,      // Медленно (безопасно)
  moderate,  // Умеренно
  fast,      // Быстро (экстремально)
}

class UserProfile {
  final String id;
  final DateTime? createdAt;
  final Gender gender;
  final int age;
  final double weight;
  final double height;
  final ActivityLevel activityLevel;
  final GoalType goalType;
  final GoalPace goalPace;
  final double? targetWeight;      // Целевой вес (если есть)
  final int? targetDays;          // За сколько дней достичь цели
  final int stepsPerDay;          // Среднее количество шагов в день
  final int workoutsPerWeek;      // Тренировки в неделю
  final double bodyFatPercentage; // Процент жира (опционально)

  UserProfile({
    required this.id,
    this.createdAt,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.activityLevel,
    required this.goalType,
    required this.goalPace,
    this.targetWeight,
    this.targetDays,
    this.stepsPerDay = 5000,
    this.workoutsPerWeek = 0,
    this.bodyFatPercentage = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'gender': gender.name,
    'age': age,
    'weight': weight,
    'height': height,
    'activityLevel': activityLevel.name,
    'goalType': goalType.name,
    'goalPace': goalPace.name,
    'targetWeight': targetWeight,
    'targetDays': targetDays,
    'stepsPerDay': stepsPerDay,
    'workoutsPerWeek': workoutsPerWeek,
    'bodyFatPercentage': bodyFatPercentage,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    id: m['id'] as String,
    createdAt: m['createdAt'] != null ? DateTime.tryParse(m['createdAt'] as String) : null,
    gender: Gender.values.firstWhere((e) => e.name == m['gender'],
        orElse: () => Gender.male),
    age: m['age'] as int,
    weight: (m['weight'] as num).toDouble(),
    height: (m['height'] as num).toDouble(),
    activityLevel: ActivityLevel.values.firstWhere((e) => e.name == m['activityLevel'],
        orElse: () => ActivityLevel.moderate),
    goalType: GoalType.values.firstWhere((e) => e.name == m['goalType'],
        orElse: () => GoalType.maintain),
    goalPace: GoalPace.values.firstWhere((e) => e.name == m['goalPace'],
        orElse: () => GoalPace.moderate),
    targetWeight: (m['targetWeight'] as num?)?.toDouble(),
    targetDays: m['targetDays'] as int?,
    stepsPerDay: m['stepsPerDay'] as int? ?? 5000,
    workoutsPerWeek: m['workoutsPerWeek'] as int? ?? 0,
    bodyFatPercentage: (m['bodyFatPercentage'] as num?)?.toDouble() ?? 0,
  );

  // Расчёт базового метаболизма (BMR) по формуле Миффлина-Сан Жеора
  double get bmr {
    if (gender == Gender.male) {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  // Коэффициент активности
  double get activityMultiplier {
    switch (activityLevel) {
      case ActivityLevel.sedentary: return 1.2;
      case ActivityLevel.light: return 1.375;
      case ActivityLevel.moderate: return 1.55;
      case ActivityLevel.active: return 1.725;
      case ActivityLevel.veryActive: return 1.9;
      case ActivityLevel.professional: return 2.2;
    }
  }

  // TDEE - общий расход энергии
  double get tdee => bmr * activityMultiplier;

  // ИМТ
  double get bmi {
    final h = height / 100;
    return weight / (h * h);
  }

  String get bmiCategory {
    final b = bmi;
    if (b < 16) return 'Выраженный дефицит массы';
    if (b < 18.5) return 'Дефицит массы';
    if (b < 25) return 'Норма';
    if (b < 30) return 'Избыточная масса (предожирение)';
    if (b < 35) return 'Ожирение I степени';
    if (b < 40) return 'Ожирение II степени';
    return 'Ожирение III степени';
  }

  // Целевая калорийность
  double get targetCalories {
    double multiplier = 1.0;
    switch (goalType) {
      case GoalType.maintain:
        multiplier = 1.0;
        break;
      case GoalType.lose:
        switch (goalPace) {
          case GoalPace.slow: multiplier = 0.85; break;
          case GoalPace.moderate: multiplier = 0.8; break;
          case GoalPace.fast: multiplier = 0.75; break;
        }
        break;
      case GoalType.gain:
        switch (goalPace) {
          case GoalPace.slow: multiplier = 1.1; break;
          case GoalPace.moderate: multiplier = 1.15; break;
          case GoalPace.fast: multiplier = 1.2; break;
        }
        break;
      case GoalType.muscleGain:
        switch (goalPace) {
          case GoalPace.slow: multiplier = 1.12; break;
          case GoalPace.moderate: multiplier = 1.18; break;
          case GoalPace.fast: multiplier = 1.25; break;
        }
        break;
      case GoalType.recomposition:
        multiplier = 1.0; // Поддерживаем, но меняем состав
        break;
    }
    return tdee * multiplier;
  }

  // Рекомендуемый белок (г)
  double get recommendedProtein {
    switch (goalType) {
      case GoalType.maintain:
        return weight * 1.2;
      case GoalType.lose:
        return weight * 1.6;
      case GoalType.gain:
        return weight * 1.8;
      case GoalType.muscleGain:
        return weight * 2.2;
      case GoalType.recomposition:
        return weight * 2.0;
    }
  }

  // Рекомендуемый жир (г)
  double get recommendedFat {
    return (targetCalories * 0.25) / 9;
  }

  // Рекомендуемые углеводы (г)
  double get recommendedCarbs {
    final proteinCal = recommendedProtein * 4;
    final fatCal = recommendedFat * 9;
    return (targetCalories - proteinCal - fatCal) / 4;
  }

  // Рекомендуемая вода (мл)
  int get recommendedWater {
    return (weight * 35).round();
  }

  // Прогноз достижения цели
  Map<String, dynamic> get goalPrediction {
    if (targetWeight == null) {
      return {'canPredict': false};
    }

    final diff = weight - targetWeight!;
    final isLose = diff > 0;
    final absDiff = diff.abs();

    // Предполагаемая скорость в зависимости от темпа
    double ratePerWeek;
    switch (goalPace) {
      case GoalPace.slow: ratePerWeek = 0.3; break;
      case GoalPace.moderate: ratePerWeek = 0.5; break;
      case GoalPace.fast: ratePerWeek = 0.8; break;
    }

    // Для набора мышц скорость ниже
    if (goalType == GoalType.muscleGain) {
      ratePerWeek = 0.2;
    }

    final weeks = absDiff / ratePerWeek;
    final days = (weeks * 7).round();

    return {
      'canPredict': true,
      'weeks': weeks,
      'days': days,
      'ratePerWeek': ratePerWeek,
      'isLose': isLose,
      'absDiff': absDiff,
    };
  }
}