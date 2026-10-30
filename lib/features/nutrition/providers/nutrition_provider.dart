import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/nutrition_database.dart';
import '../models/nutrition_models.dart';

class NutritionProvider extends ChangeNotifier {
  final NutritionDatabase _db = NutritionDatabase();
  final Uuid _uuid = const Uuid();

  List<FoodProduct> _products = [];
  List<FoodDiaryEntry> _diary = [];
  List<MealTemplate> _templates = [];
  List<WaterEntry> _waterEntries = [];
  NutritionGoals? _defaultGoals;
  final Map<String, NutritionGoals> _dailyGoals = {};
  UserProfile? _userProfile;

  List<FoodProduct> get products => _products;
  List<MealTemplate> get templates => _templates;
  NutritionGoals? get defaultGoals => _defaultGoals;
  UserProfile? get userProfile => _userProfile;

  List<FoodProduct> get favoriteProducts => _products.where((p) => p.isFavorite).toList();
  List<FoodProduct> get customProducts => _products.where((p) => p.isCustom).toList();

  Future<void> init() async {
    debugPrint('🥗 Инициализация NutritionProvider...');
    await Future.wait([
      _loadProducts(),
      _loadTemplates(),
      _loadDiary(),
      _loadWater(),
      _loadGoals(),
      _loadUserProfile(),
    ]);
    debugPrint('✅ NutritionProvider готов: ${_products.length} продуктов');
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    final data = await _db.query('food_products', orderBy: 'name ASC');
    _products = data.map((m) => FoodProduct.fromMap(m)).toList();
  }

  Future<void> _loadTemplates() async {
    final data = await _db.query('meal_templates', orderBy: 'createdAt DESC');
    _templates = data.map((m) => MealTemplate.fromMap(m)).toList();
  }

  Future<void> _loadDiary() async {
    final data = await _db.query('food_diary', orderBy: 'date DESC, time DESC', limit: 2000);
    _diary = data.map((m) {
      final product = _findProduct(m['productId'] as String);
      return FoodDiaryEntry.fromMap(m, product);
    }).toList();
  }

  Future<void> _loadWater() async {
    final data = await _db.query('water_entries', orderBy: 'date DESC', limit: 500);
    _waterEntries = data.map((m) => WaterEntry.fromMap(m)).toList();
  }

  Future<void> _loadGoals() async {
    final data = await _db.query('nutrition_goals');
    for (final m in data) {
      final g = NutritionGoals.fromMap(m);
      if (g.date == null) {
        _defaultGoals = g;
      } else {
        _dailyGoals[_dateKey(g.date!)] = g;
      }
    }
    _defaultGoals ??= NutritionGoals(
      id: _uuid.v4(),
      calories: 2200,
      protein: 140,
      fat: 70,
      carbs: 250,
      waterMl: 2500,
    );
  }

  Future<void> _loadUserProfile() async {
    final data = await _db.query('user_profile', orderBy: 'createdAt DESC', limit: 1);
    if (data.isNotEmpty) {
      _userProfile = UserProfile.fromMap(data.first);
      // Если есть профиль, обновляем цели
      if (_userProfile != null) {
        await updateGoals(NutritionGoals(
          id: _defaultGoals?.id ?? _uuid.v4(),
          date: null,
          calories: _userProfile!.targetCalories,
          protein: _userProfile!.recommendedProtein,
          fat: _userProfile!.recommendedFat,
          carbs: _userProfile!.recommendedCarbs,
          waterMl: _userProfile!.recommendedWater,
        ));
      }
    }
  }

  FoodProduct? _findProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  // ==================== ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ====================

  Future<void> saveUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await _db.insert('user_profile', profile.toMap());

    // Обновляем цели на основе профиля
    await updateGoals(NutritionGoals(
      id: _defaultGoals?.id ?? _uuid.v4(),
      date: null,
      calories: profile.targetCalories,
      protein: profile.recommendedProtein,
      fat: profile.recommendedFat,
      carbs: profile.recommendedCarbs,
      waterMl: profile.recommendedWater,
    ));
    notifyListeners();
  }

  // ==================== ПРОДУКТЫ ====================

  List<FoodProduct> searchProducts(String query) {
    final q = query.toLowerCase();
    return _products.where((p) =>
    p.name.toLowerCase().contains(q) ||
        p.categoryName.toLowerCase().contains(q),
    ).toList();
  }

  List<FoodProduct> getRecentProducts({int limit = 10}) {
    final recent = <String>[];
    for (final entry in _diary) {
      if (!recent.contains(entry.productId)) recent.add(entry.productId);
      if (recent.length >= limit) break;
    }
    return recent.map((id) => _findProduct(id)).whereType<FoodProduct>().toList();
  }

  Future<void> toggleFavorite(String productId) async {
    final p = _findProduct(productId);
    if (p == null) return;
    final updated = FoodProduct(
      id: p.id, name: p.name, category: p.category,
      calories: p.calories, protein: p.protein, fat: p.fat, carbs: p.carbs,
      fiber: p.fiber, isCustom: p.isCustom, barcode: p.barcode,
      imageUrl: p.imageUrl, isFavorite: !p.isFavorite,
    );
    await _db.update('food_products', updated.toMap(),
        where: 'id = ?', whereArgs: [p.id]);
    final i = _products.indexWhere((x) => x.id == p.id);
    if (i != -1) _products[i] = updated;
    notifyListeners();
  }

  Future<FoodProduct> addCustomProduct({
    required String name,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    String category = 'other',
  }) async {
    final p = FoodProduct(
      id: _uuid.v4(), name: name, category: category,
      calories: calories, protein: protein, fat: fat, carbs: carbs,
      isCustom: true,
    );
    await _db.insert('food_products', p.toMap());
    _products.add(p);
    _products.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return p;
  }

  // ==================== ДНЕВНИК ====================

  Future<void> addEntry({
    required FoodProduct product,
    required double grams,
    required MealType mealType,
    DateTime? date,
    String? note,
    String? templateId,
    String? templateName,
  }) async {
    final finalDate = date ?? DateTime.now();
    final macros = product.forGrams(grams);
    final nowIso = DateTime.now().toIso8601String();

    final entry = FoodDiaryEntry(
      id: _uuid.v4(),
      date: finalDate,
      mealType: mealType,
      productId: product.id,
      grams: grams,
      calories: macros.calories,
      protein: macros.protein,
      fat: macros.fat,
      carbs: macros.carbs,
      time: nowIso,
      note: note,
      productName: product.name,
      productCategory: product.category,
      templateId: templateId,
      templateName: templateName,
    );

    await _db.insert('food_diary', entry.toMap());
    _diary.insert(0, entry);
    notifyListeners();
  }

  Future<void> addTemplateAsMeal(
      MealTemplate template,
      MealType mealType, {
        DateTime? date,
      }) async {
    // Уникальный id группы — чтобы все ингредиенты одного добавления
    // визуально собрались в одно "блюдо"
    final groupId = _uuid.v4();
    for (final item in template.items) {
      final product = _findProduct(item.productId);
      if (product != null) {
        await addEntry(
          product: product,
          grams: item.grams,
          mealType: mealType,
          date: date,
          templateId: groupId,
          templateName: template.name,
        );
      }
    }
  }

  Future<void> removeEntry(String id) async {
    await _db.delete('food_diary', where: 'id = ?', whereArgs: [id]);
    _diary.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<FoodDiaryEntry> getEntriesForDate(DateTime date) {
    final key = _dateKey(date);
    return _diary.where((e) => _dateKey(e.date) == key).toList();
  }

  List<FoodDiaryEntry> getEntriesForDateRange(DateTime from, DateTime to) {
    return _diary.where((e) =>
    e.date.isAfter(from.subtract(const Duration(days: 1))) &&
        e.date.isBefore(to.add(const Duration(days: 1))),
    ).toList();
  }

  // ==================== ВОДА ====================

  Future<void> addWater(int amountMl, {DateTime? date}) async {
    final e = WaterEntry(id: _uuid.v4(), date: date ?? DateTime.now(), amountMl: amountMl);
    await _db.insert('water_entries', e.toMap());
    _waterEntries.insert(0, e);
    notifyListeners();
  }

  int getWaterForDate(DateTime date) {
    final key = _dateKey(date);
    return _waterEntries
        .where((e) => _dateKey(e.date) == key)
        .fold<int>(0, (sum, e) => sum + e.amountMl);
  }

  // ==================== ЦЕЛИ ====================

  NutritionGoals getGoalsForDate(DateTime date) {
    final daily = _dailyGoals[_dateKey(date)];
    if (daily != null) return daily;
    if (_defaultGoals != null) return _defaultGoals!;
    return NutritionGoals(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      calories: 2200,
      protein: 140,
      fat: 70,
      carbs: 250,
      waterMl: 2500,
    );
  }

  Future<void> updateGoals(NutritionGoals goals) async {
    if (goals.date == null) {
      if (_defaultGoals != null) {
        await _db.update('nutrition_goals', goals.toMap(),
            where: 'id = ?', whereArgs: [_defaultGoals!.id]);
      } else {
        await _db.insert('nutrition_goals', goals.toMap());
      }
      _defaultGoals = goals;
    } else {
      _dailyGoals[_dateKey(goals.date!)] = goals;
      await _db.insert('nutrition_goals', goals.toMap());
    }
    notifyListeners();
  }

  Future<void> recalculateGoals({
    required double weight,
    required double height,
    required int age,
    required bool isMale,
    required double activityFactor,
    required String goal,
  }) async {
    final g = NutritionGoals.calculate(
      id: _defaultGoals?.id ?? _uuid.v4(),
      weight: weight, height: height, age: age,
      isMale: isMale, activityFactor: activityFactor, goal: goal,
    );
    await updateGoals(g);
  }

  // ==================== СВОДКИ ====================

  DailyNutritionSummary getSummaryForDate(DateTime date) {
    final entries = getEntriesForDate(date);
    return DailyNutritionSummary(
      calories: entries.fold<double>(0, (s, e) => s + e.calories),
      protein: entries.fold<double>(0, (s, e) => s + e.protein),
      fat: entries.fold<double>(0, (s, e) => s + e.fat),
      carbs: entries.fold<double>(0, (s, e) => s + e.carbs),
      waterMl: getWaterForDate(date),
      entriesCount: entries.length,
    );
  }

  List<DailyNutritionSummary> getLast7DaysSummaries() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return getSummaryForDate(d);
    });
  }

  // ==================== УМНЫЕ РЕКОМЕНДАЦИИ ====================

  List<NutritionRecommendation> getRecommendations(DateTime date) {
    final recs = <NutritionRecommendation>[];
    final summary = getSummaryForDate(date);
    final goals = getGoalsForDate(date);
    final now = DateTime.now();
    final hour = now.hour;

    // 1. Белковый дефицит вечером
    if (hour >= 18 && goals.protein > 0 && summary.protein < goals.protein * 0.7) {
      final missing = (goals.protein - summary.protein).round();
      recs.add(NutritionRecommendation(
        type: RecommendationType.protein,
        priority: 3,
        title: 'Белковый дефицит',
        message: 'До цели ещё $missing г белка. Добавь творог (150г) или куриную грудку (100г)',
        emoji: '🥩',
        color: const Color(0xFF00FF9D),
      ));
    }

    // 2. Калорийный дефицит 3+ дня подряд
    if (goals.calories > 0) {
      int deficitDays = 0;
      for (int i = 0; i < 3; i++) {
        final d = date.subtract(Duration(days: i));
        final s = getSummaryForDate(d);
        if (s.calories < goals.calories * 0.75) deficitDays++;
      }
      if (deficitDays >= 3) {
        recs.add(NutritionRecommendation(
          type: RecommendationType.warning,
          priority: 2,
          title: 'Хронический дефицит',
          message: '$deficitDays дня подряд дефицит калорий >25%. Риск потери мышц и замедления метаболизма',
          emoji: '⚠️',
          color: const Color(0xFFFFD60A),
        ));
      }
    }

    // 3. Мало воды
    if (goals.waterMl > 0 && summary.waterMl < goals.waterMl * 0.5 && hour >= 15) {
      final missing = goals.waterMl - summary.waterMl;
      recs.add(NutritionRecommendation(
        type: RecommendationType.water,
        priority: 2,
        title: 'Пей больше воды',
        message: 'Выпито только ${summary.waterMl} мл из ${goals.waterMl}. Нужно ещё $missing мл',
        emoji: '💧',
        color: const Color(0xFF00D4FF),
      ));
    }

    // 4. Тайминг приёмов
    final todayEntries = getEntriesForDate(date);
    if (todayEntries.isNotEmpty) {
      final lastEntry = todayEntries.reduce((a, b) {
        final aTime = a.time ?? '';
        final bTime = b.time ?? '';
        return aTime.compareTo(bTime) > 0 ? a : b;
      });

      final lastTimeStr = lastEntry.time;
      if (lastTimeStr != null && lastTimeStr.isNotEmpty) {
        final lastTime = DateTime.tryParse(lastTimeStr);
        if (lastTime != null) {
          final hoursPassed = now.difference(lastTime).inHours;
          if (hoursPassed >= 5 && hour < 22) {
            recs.add(NutritionRecommendation(
              type: RecommendationType.timing,
              priority: 1,
              title: 'Пора перекусить',
              message: 'Прошло $hoursPassed ч после последнего приёма пищи',
              emoji: '⏰',
              color: const Color(0xFFFF9500),
            ));
          }
        }
      }
    } else if (hour >= 10) {
      final hoursSinceMorning = hour - 6;
      recs.add(NutritionRecommendation(
        type: RecommendationType.timing,
        priority: 2,
        title: 'Не забудь позавтракать',
        message: 'Уже $hoursSinceMorning часов утра, а завтрак ещё не был',
        emoji: '🌅',
        color: const Color(0xFFFF9500),
      ));
    }

    // 5. Профицит жиров
    if (goals.fat > 0 && summary.fat > goals.fat * 1.2) {
      final percent = ((summary.fat / goals.fat - 1) * 100).round();
      recs.add(NutritionRecommendation(
        type: RecommendationType.warning,
        priority: 1,
        title: 'Перебор с жирами',
        message: '${summary.fat.round()} г из ${goals.fat.round()} — превышение на $percent%',
        emoji: '🧈',
        color: const Color(0xFFFF2D55),
      ));
    }

    // 6. Недостаток углеводов
    if (goals.carbs > 0 && summary.carbs < goals.carbs * 0.5 && hour >= 16) {
      recs.add(NutritionRecommendation(
        type: RecommendationType.energy,
        priority: 1,
        title: 'Мало энергии',
        message: 'Углеводов только ${summary.carbs.round()} г. Добавь рис, банан или овсянку',
        emoji: '🍌',
        color: const Color(0xFFFFD60A),
      ));
    }

    // 7. Рекомендации на основе профиля пользователя
    if (_userProfile != null) {
      final profile = _userProfile!;

      // Прогноз достижения цели
      final prediction = profile.goalPrediction;
      if (prediction['canPredict'] == true && prediction['days'] > 30) {
        recs.add(NutritionRecommendation(
          type: RecommendationType.energy,
          priority: 1,
          title: 'Корректировка темпа',
          message: 'Прогнозируемый срок: ${prediction['days']} дней. Возможно, стоит ускорить темп или пересмотреть цель',
          emoji: '📊',
          color: const Color(0xFFFF9500),
        ));
      }

      // Проверка ИМТ
      if (profile.bmiCategory != 'Норма') {
        recs.add(NutritionRecommendation(
          type: RecommendationType.warning,
          priority: 1,
          title: 'Внимание: ИМТ',
          message: 'Ваш ИМТ: ${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})',
          emoji: '⚖️',
          color: const Color(0xFFFF2D55),
        ));
      }
    }

    recs.sort((a, b) => b.priority.compareTo(a.priority));
    return recs;
  }
}

// ==================== РЕКОМЕНДАЦИЯ ====================

enum RecommendationType { protein, water, warning, timing, energy, workout }

class NutritionRecommendation {
  final RecommendationType type;
  final int priority;
  final String title;
  final String message;
  final String emoji;
  final Color color;

  NutritionRecommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.emoji,
    required this.color,
  });
}