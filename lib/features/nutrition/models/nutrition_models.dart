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
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    int? waterMl,
    bool? isActive,
    DateTime? date,
  }) =>
      NutritionGoals(
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
      case 'lose':
        tdee *= 0.8;
        break;
      case 'gain':
        tdee *= 1.15;
        break;
    }

    // Распределение БЖУ
    double pRatio, fRatio, cRatio;
    switch (goal) {
      case 'lose':
        pRatio = 0.40;
        fRatio = 0.30;
        cRatio = 0.30;
        break;
      case 'gain':
        pRatio = 0.30;
        fRatio = 0.25;
        cRatio = 0.45;
        break;
      default:
        pRatio = 0.30;
        fRatio = 0.30;
        cRatio = 0.40;
    }

    return NutritionGoals(
      id: id,
      date: date,
      calories: tdee.roundToDouble(),
      protein: ((tdee * pRatio) / 4).roundToDouble(), // 4 ккал/г
      fat: ((tdee * fRatio) / 9).roundToDouble(), // 9 ккал/г
      carbs: ((tdee * cRatio) / 4).roundToDouble(), // 4 ккал/г
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

  MealTemplateItem copyWith({double? grams, String? name}) => MealTemplateItem(
    productId: productId,
    grams: grams ?? this.grams,
    name: name ?? this.name,
  );
}

// ==================== 🆕 v8: РЕЦЕПТЫ — расширения ====================

/// Сложность рецепта.
enum RecipeDifficulty {
  easy, medium, hard;

  String get displayName {
    switch (this) {
      case RecipeDifficulty.easy: return 'Легко';
      case RecipeDifficulty.medium: return 'Средне';
      case RecipeDifficulty.hard: return 'Сложно';
    }
  }

  String get emoji {
    switch (this) {
      case RecipeDifficulty.easy: return '🟢';
      case RecipeDifficulty.medium: return '🟡';
      case RecipeDifficulty.hard: return '🔴';
    }
  }

  static RecipeDifficulty fromName(String? name) {
    return RecipeDifficulty.values.firstWhere(
          (e) => e.name == name,
      orElse: () => RecipeDifficulty.easy,
    );
  }
}

/// Типизированные теги рецептов — чтобы не было строковых опечаток.
class RecipeTags {
  // приёмы пищи
  static const breakfast = 'breakfast';
  static const lunch = 'lunch';
  static const dinner = 'dinner';
  static const snack = 'snack';
  static const mealPrep = 'meal_prep';

  // диеты
  static const highProtein = 'high_protein';
  static const lowCarb = 'low_carb';
  static const vegetarian = 'vegetarian';
  static const vegan = 'vegan';
  static const glutenFree = 'gluten_free';
  static const dairyFree = 'dairy_free';

  // контекст
  static const quick = 'quick'; // < 15 мин
  static const budget = 'budget'; // дёшево
  static const seasonal = 'seasonal'; // сезонное
  static const comfort = 'comfort'; // домашнее

  static const all = <String>[
    breakfast, lunch, dinner, snack, mealPrep,
    highProtein, lowCarb, vegetarian, vegan, glutenFree, dairyFree,
    quick, budget, seasonal, comfort,
  ];

  static const labels = <String, String>{
    breakfast: 'Завтрак',
    lunch: 'Обед',
    dinner: 'Ужин',
    snack: 'Перекус',
    mealPrep: 'Meal prep',
    highProtein: 'Много белка',
    lowCarb: 'Low-carb',
    vegetarian: 'Вегетарианское',
    vegan: 'Веганское',
    glutenFree: 'Без глютена',
    dairyFree: 'Без лактозы',
    quick: 'Быстро',
    budget: 'Экономно',
    seasonal: 'Сезонное',
    comfort: 'Домашнее',
  };

  static String label(String tag) => labels[tag] ?? tag;

  static String emoji(String tag) {
    switch (tag) {
      case breakfast: return '🌅';
      case lunch: return '☀️';
      case dinner: return '🌙';
      case snack: return '🍎';
      case mealPrep: return '🍱';
      case highProtein: return '💪';
      case lowCarb: return '🥩';
      case vegetarian: return '🥗';
      case vegan: return '🌱';
      case glutenFree: return '🌾';
      case dairyFree: return '🥛';
      case quick: return '⚡';
      case budget: return '💰';
      case seasonal: return '🍂';
      case comfort: return '🏠';
      default: return '🏷️';
    }
  }
}

/// Шаг приготовления с опциональным таймером.
class RecipeStep {
  final int order;
  final String text;
  final int? timerSec; // опциональный таймер

  const RecipeStep({
    required this.order,
    required this.text,
    this.timerSec,
  });

  Map<String, dynamic> toMap() => {
    'order': order,
    'text': text,
    'timerSec': timerSec,
  };

  factory RecipeStep.fromMap(Map<String, dynamic> m) => RecipeStep(
    order: (m['order'] as num?)?.toInt() ?? 0,
    text: (m['text'] as String?) ?? '',
    timerSec: (m['timerSec'] as num?)?.toInt(),
  );

  RecipeStep copyWith({int? order, String? text, int? timerSec}) => RecipeStep(
    order: order ?? this.order,
    text: text ?? this.text,
    timerSec: timerSec ?? this.timerSec,
  );
}

/// Запись о приготовлении рецепта.
class RecipeCookLog {
  final String id;
  final String templateId;
  final DateTime cookedAt;
  final int portions;
  final int? rating; // 1..5
  final String? note;
  final String? photoBase64;

  const RecipeCookLog({
    required this.id,
    required this.templateId,
    required this.cookedAt,
    this.portions = 1,
    this.rating,
    this.note,
    this.photoBase64,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'templateId': templateId,
    'cookedAt': cookedAt.toIso8601String(),
    'portions': portions,
    'rating': rating,
    'note': note,
    'photoBase64': photoBase64,
    'createdAt': DateTime.now().toIso8601String(),
  };

  factory RecipeCookLog.fromMap(Map<String, dynamic> m) => RecipeCookLog(
    id: m['id'] as String,
    templateId: m['templateId'] as String,
    cookedAt: DateTime.tryParse(m['cookedAt'] as String? ?? '') ?? DateTime.now(),
    portions: (m['portions'] as num?)?.toInt() ?? 1,
    rating: (m['rating'] as num?)?.toInt(),
    note: m['note'] as String?,
    photoBase64: m['photoBase64'] as String?,
  );
}

// ==================== 🆕 v8: РАСШИРЕННЫЙ MealTemplate ====================

class MealTemplate {
  final String id;
  final String name;
  final String? description;
  final List<MealTemplateItem> items;

  // 🆕 v8
  final int portions;
  final double? cookedWeight;
  final List<RecipeStep> steps;
  final List<String> tags;
  final String? photoBase64;
  final bool isFavorite;
  final int? prepTimeMin;
  final int? cookTimeMin;
  final RecipeDifficulty difficulty;

  // 🆕 v8: кэш КБЖУ (заполняется БД автоматически)
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double totalGrams;

  final DateTime? createdAt;

  MealTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.items,
    this.portions = 1,
    this.cookedWeight,
    this.steps = const [],
    this.tags = const [],
    this.photoBase64,
    this.isFavorite = false,
    this.prepTimeMin,
    this.cookTimeMin,
    this.difficulty = RecipeDifficulty.easy,
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.fiber = 0,
    this.totalGrams = 0,
    this.createdAt,
  });

  // 🆕 удобно: КБЖУ на одну порцию
  double get caloriesPerPortion => portions > 0 ? calories / portions : calories;
  double get proteinPerPortion => portions > 0 ? protein / portions : protein;
  double get fatPerPortion => portions > 0 ? fat / portions : fat;
  double get carbsPerPortion => portions > 0 ? carbs / portions : carbs;
  double get fiberPerPortion => portions > 0 ? fiber / portions : fiber;

  // 🆕 общее время
  int? get totalTimeMin {
    if (prepTimeMin == null && cookTimeMin == null) return null;
    return (prepTimeMin ?? 0) + (cookTimeMin ?? 0);
  }

  // 🆕 готовый вес одной порции (учёт ужарки)
  double get gramsPerPortion {
    final base = cookedWeight ?? totalGrams;
    return portions > 0 ? base / portions : base;
  }

  // 🆕 быстрые проверки тегов
  bool get isQuick => tags.contains(RecipeTags.quick);
  bool get isHighProtein => tags.contains(RecipeTags.highProtein);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'items': jsonEncode(items.map((i) => i.toMap()).toList()),
    'portions': portions,
    'cookedWeight': cookedWeight,
    'steps': jsonEncode(steps.map((s) => s.toMap()).toList()),
    'tags': jsonEncode(tags),
    'photoBase64': photoBase64,
    'isFavorite': isFavorite ? 1 : 0,
    'prepTimeMin': prepTimeMin,
    'cookTimeMin': cookTimeMin,
    'difficulty': difficulty.name,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory MealTemplate.fromMap(Map<String, dynamic> m) => MealTemplate(
    id: m['id'] as String,
    name: m['name'] as String,
    description: m['description'] as String?,
    items: _decodeItems(m['items']),
    portions: (m['portions'] as num?)?.toInt() ?? 1,
    cookedWeight: (m['cookedWeight'] as num?)?.toDouble(),
    steps: _decodeSteps(m['steps']),
    tags: _decodeTags(m['tags']),
    photoBase64: m['photoBase64'] as String?,
    isFavorite: (m['isFavorite'] as num?)?.toInt() == 1,
    prepTimeMin: (m['prepTimeMin'] as num?)?.toInt(),
    cookTimeMin: (m['cookTimeMin'] as num?)?.toInt(),
    difficulty: RecipeDifficulty.fromName(m['difficulty'] as String?),
    calories: (m['calories'] as num?)?.toDouble() ?? 0,
    protein: (m['protein'] as num?)?.toDouble() ?? 0,
    fat: (m['fat'] as num?)?.toDouble() ?? 0,
    carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
    fiber: (m['fiber'] as num?)?.toDouble() ?? 0,
    totalGrams: (m['totalGrams'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.tryParse(m['createdAt'] as String? ?? ''),
  );

  MealTemplate copyWith({
    String? name,
    String? description,
    List<MealTemplateItem>? items,
    int? portions,
    double? cookedWeight,
    List<RecipeStep>? steps,
    List<String>? tags,
    String? photoBase64,
    bool? isFavorite,
    int? prepTimeMin,
    int? cookTimeMin,
    RecipeDifficulty? difficulty,
  }) =>
      MealTemplate(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        items: items ?? this.items,
        portions: portions ?? this.portions,
        cookedWeight: cookedWeight ?? this.cookedWeight,
        steps: steps ?? this.steps,
        tags: tags ?? this.tags,
        photoBase64: photoBase64 ?? this.photoBase64,
        isFavorite: isFavorite ?? this.isFavorite,
        prepTimeMin: prepTimeMin ?? this.prepTimeMin,
        cookTimeMin: cookTimeMin ?? this.cookTimeMin,
        difficulty: difficulty ?? this.difficulty,
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
        fiber: fiber,
        totalGrams: totalGrams,
        createdAt: createdAt,
      );

  // ── приватные декодеры (не падают на битых данных) ──
  static List<MealTemplateItem> _decodeItems(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String? ?? '[]');
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((i) => MealTemplateItem.fromMap(Map<String, dynamic>.from(i)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static List<RecipeStep> _decodeSteps(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String? ?? '[]');
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((s) => RecipeStep.fromMap(Map<String, dynamic>.from(s)))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } catch (_) {
      return const [];
    }
  }

  static List<String> _decodeTags(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String? ?? '[]');
      if (decoded is! List) return const [];
      return decoded.whereType<String>().toList();
    } catch (_) {
      return const [];
    }
  }
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
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.waterMl = 0,
    this.entriesCount = 0,
  });

  double percentOf(NutritionGoals g) => g.calories > 0 ? (calories / g.calories).clamp(0, 2) : 0;

  double proteinPercentOf(NutritionGoals g) => g.protein > 0 ? (protein / g.protein).clamp(0, 2) : 0;

  double fatPercentOf(NutritionGoals g) => g.fat > 0 ? (fat / g.fat).clamp(0, 2) : 0;

  double carbsPercentOf(NutritionGoals g) => g.carbs > 0 ? (carbs / g.carbs).clamp(0, 2) : 0;

  double waterPercentOf(NutritionGoals g) => g.waterMl > 0 ? (waterMl / g.waterMl).clamp(0, 2) : 0;
}

// ==================== ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ====================

enum Gender { male, female }

enum ActivityLevel {
  sedentary, // Сидячий образ жизни, мало движения
  light, // Лёгкая активность 1-2 раза в неделю
  moderate, // Умеренная активность 3-5 раз в неделю
  active, // Активный образ жизни 6-7 раз в неделю
  veryActive, // Очень активный, физическая работа
  professional, // Профессиональный спортсмен
}

enum GoalType {
  maintain, // Поддержание веса
  lose, // Похудение
  gain, // Набор веса
  muscleGain, // Набор мышечной массы
  recomposition, // Ре-композиция (сжигание жира + набор мышц)
}

enum GoalPace {
  slow, // Медленно (безопасно)
  moderate, // Умеренно
  fast, // Быстро (экстремально)
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
  final double? targetWeight; // Целевой вес (если есть)
  final int? targetDays; // За сколько дней достичь цели
  final int stepsPerDay; // Среднее количество шагов в день
  final int workoutsPerWeek; // Тренировки в неделю
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
    gender: Gender.values.firstWhere((e) => e.name == m['gender'], orElse: () => Gender.male),
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

// ==================== 🆕 v8: КЛАДОВАЯ (PANTRY) ====================

class PantryItem {
  final String id;
  final String? productId; // Ссылка на каталог, если есть
  final String? customName; // Если продукта нет в каталоге
  final double quantity;
  final String unit; // г, мл, шт
  final DateTime? expiresAt;
  final DateTime addedAt;
  final double? price; // Цена за всю единицу измерения

  PantryItem({
    required this.id,
    this.productId,
    this.customName,
    required this.quantity,
    this.unit = 'г',
    this.expiresAt,
    required this.addedAt,
    this.price,
  });

  String get displayName => customName ?? 'Продукт';

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  int get daysUntilExpiry {
    if (expiresAt == null) return 999;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'customName': customName,
    'quantity': quantity,
    'unit': unit,
    'expiresAt': expiresAt?.toIso8601String(),
    'addedAt': addedAt.toIso8601String(),
    'price': price,
    'createdAt': DateTime.now().toIso8601String(),
  };

  factory PantryItem.fromMap(Map<String, dynamic> m) => PantryItem(
    id: m['id'] as String,
    productId: m['productId'] as String?,
    customName: m['customName'] as String?,
    quantity: (m['quantity'] as num).toDouble(),
    unit: (m['unit'] as String?) ?? 'г',
    expiresAt: m['expiresAt'] != null ? DateTime.tryParse(m['expiresAt'] as String) : null,
    addedAt: DateTime.tryParse(m['addedAt'] as String) ?? DateTime.now(),
    price: (m['price'] as num?)?.toDouble(),
  );
}

// ==================== 🆕 v8: ПЛАН НЕДЕЛИ ====================

class PlanDay {
  final String id;
  final DateTime date;
  final double? targetCalories;
  final double? targetProtein;
  final double? targetFat;
  final double? targetCarbs;
  final bool isCheatDay;
  final bool isVacation;

  PlanDay({
    required this.id,
    required this.date,
    this.targetCalories,
    this.targetProtein,
    this.targetFat,
    this.targetCarbs,
    this.isCheatDay = false,
    this.isVacation = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String().split('T').first,
    'targetCalories': targetCalories,
    'targetProtein': targetProtein,
    'targetFat': targetFat,
    'targetCarbs': targetCarbs,
    'isCheatDay': isCheatDay ? 1 : 0,
    'isVacation': isVacation ? 1 : 0,
    'createdAt': DateTime.now().toIso8601String(),
  };

  factory PlanDay.fromMap(Map<String, dynamic> m) => PlanDay(
    id: m['id'] as String,
    date: DateTime.parse(m['date'] as String),
    targetCalories: (m['targetCalories'] as num?)?.toDouble(),
    targetProtein: (m['targetProtein'] as num?)?.toDouble(),
    targetFat: (m['targetFat'] as num?)?.toDouble(),
    targetCarbs: (m['targetCarbs'] as num?)?.toDouble(),
    isCheatDay: (m['isCheatDay'] as int?) == 1,
    isVacation: (m['isVacation'] as int?) == 1,
  );
}

class PlanMeal {
  final String id;
  final String dayId;
  final MealType mealType;
  final String? templateId; // Ссылка на рецепт
  final double portions;
  final List<String> alternatives; // ID альтернативных рецептов (JSON cache)
  final bool isCompleted;
  final double? actualGrams; // Если съел не по плану
  final String? note;

  PlanMeal({
    required this.id,
    required this.dayId,
    required this.mealType,
    this.templateId,
    this.portions = 1,
    this.alternatives = const [],
    this.isCompleted = false,
    this.actualGrams,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'dayId': dayId,
    'mealType': mealType.name,
    'templateId': templateId,
    'portions': portions,
    'alternatives': jsonEncode(alternatives),
    'isCompleted': isCompleted ? 1 : 0,
    'actualGrams': actualGrams,
    'note': note,
    'createdAt': DateTime.now().toIso8601String(),
  };

  factory PlanMeal.fromMap(Map<String, dynamic> m) => PlanMeal(
    id: m['id'] as String,
    dayId: m['dayId'] as String,
    mealType: MealType.values.firstWhere(
          (e) => e.name == m['mealType'],
      orElse: () => MealType.other,
    ),
    templateId: m['templateId'] as String?,
    portions: (m['portions'] as num?)?.toDouble() ?? 1,
    alternatives: _decodeStringList(m['alternatives']),
    isCompleted: (m['isCompleted'] as int?) == 1,
    actualGrams: (m['actualGrams'] as num?)?.toDouble(),
    note: m['note'] as String?,
  );

  static List<String> _decodeStringList(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String? ?? '[]');
      if (decoded is! List) return [];
      return decoded.whereType<String>().toList();
    } catch (_) {
      return [];
    }
  }
}

// ==================== 🆕 v8: СПИСОК ПОКУПОК ====================

/// Базис, к которому привязана цена (`estimatedPrice`).
enum PriceBasis {
  perPiece, // ₽ за штуку
  perGram, // ₽ за 1 г
  per100g, // ₽ за 100 г
  perKg, // ₽ за 1 кг
  perMl, // ₽ за 1 мл
  per100ml, // ₽ за 100 мл
  perLiter, // ₽ за 1 л
  perPackage; // ₽ за упаковку (используется вместе с packageWeight)

  String get label {
    switch (this) {
      case PriceBasis.perPiece: return 'за шт';
      case PriceBasis.perGram: return 'за г';
      case PriceBasis.per100g: return 'за 100 г';
      case PriceBasis.perKg: return 'за кг';
      case PriceBasis.perMl: return 'за мл';
      case PriceBasis.per100ml: return 'за 100 мл';
      case PriceBasis.perLiter: return 'за л';
      case PriceBasis.perPackage: return 'за упаковку';
    }
  }

  static PriceBasis fromName(String? name) {
    return PriceBasis.values.firstWhere(
          (e) => e.name == name,
      orElse: () => PriceBasis.perKg, // исторический дефолт
    );
  }
}

class ShoppingItem {
  final String id;
  final String? productId;
  final String? customName;
  final double quantity;
  final String unit; // 'шт', 'г', 'кг', 'мл', 'л'
  final double? packageWeight; // вес одной упаковки в г/мл (опционально)
  final double? estimatedPrice; // цена в базисе priceBasis
  final PriceBasis priceBasis; // 🆕 v9
  final String? store;
  final bool isUrgent;
  final bool isBought;
  final String? fallbackName;
  final String? category; // 🆕 ДОБАВЛЕНО: Отдел магазина
  final DateTime createdAt; // 🆕 ДОБАВЛЕНО: Для сортировки истории

  ShoppingItem({
    required this.id,
    this.productId,
    this.customName,
    required this.quantity,
    this.unit = 'г',
    this.packageWeight,
    this.estimatedPrice,
    this.priceBasis = PriceBasis.perKg,
    this.store,
    this.isUrgent = false,
    this.isBought = false,
    this.fallbackName,
    this.category, // 🆕 ДОБАВЛЕНО
    DateTime? createdAt, // 🆕 ДОБАВЛЕНО
  }) : this.createdAt = createdAt ?? DateTime.now(); // 🆕 ДОБАВЛЕНО

  String get displayName => customName ?? 'Продукт';

  double get _quantityInBase {
    switch (unit) {
      case 'кг': return quantity * 1000;
      case 'л': return quantity * 1000;
      default: return quantity;
    }
  }

  double get _pricePerBase {
    final p = estimatedPrice ?? 0;
    switch (priceBasis) {
      case PriceBasis.perPiece: return p;
      case PriceBasis.perGram: return p;
      case PriceBasis.per100g: return p / 100;
      case PriceBasis.perKg: return p / 1000;
      case PriceBasis.perMl: return p;
      case PriceBasis.per100ml: return p / 100;
      case PriceBasis.perLiter: return p / 1000;
      case PriceBasis.perPackage:
        {
          if (packageWeight == null || packageWeight! <= 0) return 0;
          return p / packageWeight!;
        }
    }
  }

  // 🆕 ДОБАВЛЕНО: Публичный геттер для честного сравнения цен в истории
  double get pricePerBaseUnit => _pricePerBase;

  double get totalPrice {
    if (estimatedPrice == null) return 0;
    return _quantityInBase * _pricePerBase;
  }

  int get packagesNeeded {
    if (packageWeight == null || packageWeight! <= 0) return 1;
    final base = _quantityInBase;
    return (base / packageWeight!).ceil();
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'customName': customName,
    'quantity': quantity,
    'unit': unit,
    'packageWeight': packageWeight,
    'estimatedPrice': estimatedPrice,
    'priceBasis': priceBasis.name,
    'store': store,
    'isUrgent': isUrgent ? 1 : 0,
    'isBought': isBought ? 1 : 0,
    'fallbackName': fallbackName,
    'category': category, // 🆕 ДОБАВЛЕНО
    'createdAt': createdAt.toIso8601String(), // 🆕 ИСПРАВЛЕНО: используем поле, а не DateTime.now()
    'updatedAt': DateTime.now().toIso8601String(),
  };

  factory ShoppingItem.fromMap(Map<String, dynamic> m) => ShoppingItem(
    id: m['id'] as String,
    productId: m['productId'] as String?,
    customName: m['customName'] as String?,
    quantity: (m['quantity'] as num).toDouble(),
    unit: (m['unit'] as String?) ?? 'г',
    packageWeight: (m['packageWeight'] as num?)?.toDouble(),
    estimatedPrice: (m['estimatedPrice'] as num?)?.toDouble(),
    priceBasis: PriceBasis.fromName(m['priceBasis'] as String?),
    store: m['store'] as String?,
    isUrgent: (m['isUrgent'] as int?) == 1,
    isBought: (m['isBought'] as int?) == 1,
    fallbackName: m['fallbackName'] as String?,
    category: m['category'] as String?, // 🆕 ДОБАВЛЕНО
    createdAt: m['createdAt'] != null ? DateTime.parse(m['createdAt'] as String) : DateTime.now(), // 🆕 ИСПРАВЛЕНО
  );

  ShoppingItem copyWith({
    String? id,
    String? productId,
    String? customName,
    double? quantity,
    String? unit,
    double? packageWeight,
    double? estimatedPrice,
    PriceBasis? priceBasis,
    String? store,
    bool? isUrgent,
    bool? isBought,
    String? fallbackName,
    String? category, // 🆕 ДОБАВЛЕНО
    DateTime? createdAt,
  }) =>
      ShoppingItem(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        customName: customName ?? this.customName,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        packageWeight: packageWeight ?? this.packageWeight,
        estimatedPrice: estimatedPrice ?? this.estimatedPrice,
        priceBasis: priceBasis ?? this.priceBasis,
        store: store ?? this.store,
        isUrgent: isUrgent ?? this.isUrgent,
        isBought: isBought ?? this.isBought,
        fallbackName: fallbackName ?? this.fallbackName,
        category: category ?? this.category, // 🆕 ДОБАВЛЕНО
        createdAt: createdAt ?? this.createdAt,
      );
}

// ═══════════════════════════════════════════════════════════════
// 🆕 v9: МОДЕЛИ ДЛЯ ШТРИХКОДОВ И ИСТОРИИ (ОБЯЗАТЕЛЬНО ДЛЯ КОМПИЛЯЦИИ)
// ═══════════════════════════════════════════════════════════════

enum BarcodeSource { localDb, cache, openFoodFacts, upcItemDb, manual }

class BarcodeProduct {
  final String barcode;
  final String? name;
  final String? brand;
  final String category;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double? packageGrams;
  final String? imageUrl;
  final String? rawCategories;
  final BarcodeSource source;

  const BarcodeProduct({
    required this.barcode,
    this.name,
    this.brand,
    this.category = 'other',
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.fiber = 0,
    this.packageGrams,
    this.imageUrl,
    this.rawCategories,
    this.source = BarcodeSource.openFoodFacts,
  });

  bool get hasName => (name ?? '').trim().isNotEmpty;
  bool get hasNutrition => calories > 0 || protein > 0 || fat > 0 || carbs > 0;

  String get displayName {
    final n = (name ?? '').trim();
    final b = (brand ?? '').trim();
    if (n.isNotEmpty && b.isNotEmpty && !n.toLowerCase().contains(b.toLowerCase())) {
      return '$n ($b)';
    }
    if (n.isNotEmpty) return n;
    return b;
  }

  BarcodeProduct copyWith({String? name, String? category, double? packageGrams}) => BarcodeProduct(
    barcode: barcode,
    name: name ?? this.name,
    brand: brand,
    category: category ?? this.category,
    calories: calories,
    protein: protein,
    fat: fat,
    carbs: carbs,
    fiber: fiber,
    packageGrams: packageGrams ?? this.packageGrams,
    imageUrl: imageUrl,
    rawCategories: rawCategories,
    source: source,
  );

  Map<String, dynamic> toMap() => {
    'barcode': barcode,
    'name': name,
    'brand': brand,
    'category': category,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'fiber': fiber,
    'packageGrams': packageGrams,
    'imageUrl': imageUrl,
    'rawCategories': rawCategories,
    'source': source.name,
  };

  factory BarcodeProduct.fromMap(Map<String, dynamic> m) => BarcodeProduct(
    barcode: m['barcode'] as String,
    name: m['name'] as String?,
    brand: m['brand'] as String?,
    category: (m['category'] as String?) ?? 'other',
    calories: (m['calories'] as num?)?.toDouble() ?? 0,
    protein: (m['protein'] as num?)?.toDouble() ?? 0,
    fat: (m['fat'] as num?)?.toDouble() ?? 0,
    carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
    fiber: (m['fiber'] as num?)?.toDouble() ?? 0,
    packageGrams: (m['packageGrams'] as num?)?.toDouble(),
    imageUrl: m['imageUrl'] as String?,
    rawCategories: m['rawCategories'] as String?,
    source: BarcodeSource.values.firstWhere(
          (e) => e.name == m['source'],
      orElse: () => BarcodeSource.cache,
    ),
  );
}

class BarcodeLookupResult {
  final BarcodeProduct? product;
  final bool notFound;
  final String? hint; // страна по префиксу / пояснение
  final bool fromCache;

  const BarcodeLookupResult({
    this.product,
    this.notFound = false,
    this.hint,
    this.fromCache = false,
  });

  bool get isSuccess => product != null;
}

class OnlineHit {
  final String? barcode;
  final String name;
  final String? brand;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  const OnlineHit({
    this.barcode,
    required this.name,
    this.brand,
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
  });
}

// Модель для истории сканирований (ИДЕЯ 2)
class ScanHistoryEntry {
  final String barcode;
  final String name;
  final String category;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final DateTime scannedAt;

  const ScanHistoryEntry({
    required this.barcode,
    required this.name,
    this.category = 'other',
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.fiber = 0,
    required this.scannedAt,
  });

  Map<String, dynamic> toMap() => {
    'barcode': barcode,
    'name': name,
    'category': category,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'fiber': fiber,
    'scannedAt': scannedAt.toIso8601String(),
  };

  factory ScanHistoryEntry.fromMap(Map<String, dynamic> m) => ScanHistoryEntry(
    barcode: m['barcode'] as String,
    name: m['name'] as String,
    category: (m['category'] as String?) ?? 'other',
    calories: (m['calories'] as num?)?.toDouble() ?? 0,
    protein: (m['protein'] as num?)?.toDouble() ?? 0,
    fat: (m['fat'] as num?)?.toDouble() ?? 0,
    carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
    fiber: (m['fiber'] as num?)?.toDouble() ?? 0,
    scannedAt: DateTime.tryParse(m['scannedAt'] as String? ?? '') ?? DateTime.now(),
  );
}