// features/nutrition/providers/nutrition_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zal_life/features/nutrition/ui/screens/barcode_lookup_service.dart' hide BarcodeLookupResult, BarcodeProduct, BarcodeSource;
import '../database/nutrition_database.dart';
import '../models/nutrition_models.dart';
import '../models/nutrition_program.dart';
import '../ui/screens/add_pantry_screen.dart' hide ScanHistoryEntry;
import '../ui/screens/barcode_lookup_service.dart' hide BarcodeLookupResult, BarcodeProduct, BarcodeSource, OnlineHit;
import 'dart:convert';
import 'package:http/http.dart' as http;

class NutritionProvider extends ChangeNotifier {
  final NutritionDatabase _db = NutritionDatabase();
  final Uuid _uuid = const Uuid();

  // --- Основные данные ---
  List<FoodProduct> _products = [];
  List<FoodDiaryEntry> _diary = [];
  List<MealTemplate> _templates = [];
  List<WaterEntry> _waterEntries = [];

  // --- Цели и Профиль ---
  NutritionGoals? _defaultGoals;
  final Map<String, NutritionGoals> _dailyGoals = {};
  UserProfile? _userProfile;

  // --- 🆕 v8: Кухня (Pantry, Plan, Shopping) ---
  List<PantryItem> _pantryItems = [];
  List<PlanDay> _planDays = [];
  List<PlanMeal> _planMeals = [];
  List<ShoppingItem> _shoppingItems = [];

  // --- 🆕 Программы питания (v11) ---
  List<NutritionProgram> _programs = [];
  List<NutritionProgram> get programs => _programs;
  NutritionProgram? get activeProgram => _programs.where((p) => p.isActive).firstOrNull;

  // --- 🆕 История сканирований ---
  List<ScanHistoryEntry> _scanHistory = [];
  List<ScanHistoryEntry> get recentScans => _scanHistory;

  // --- Геттеры ---
  List<FoodProduct> get products => _products;
  List<MealTemplate> get templates => _templates;
  NutritionGoals? get defaultGoals => _defaultGoals;
  UserProfile? get userProfile => _userProfile;
  List<FoodProduct> get favoriteProducts => _products.where((p) => p.isFavorite).toList();
  List<FoodProduct> get customProducts => _products.where((p) => p.isCustom).toList();

  // 🆕 v8 Геттеры
  List<PantryItem> get pantryItems => _pantryItems;
  List<PlanDay> get planDays => _planDays;
  List<PlanMeal> get planMeals => _planMeals;
  List<ShoppingItem> get shoppingItems => _shoppingItems;
  List<ShoppingItem> get activeShoppingList => _shoppingItems.where((i) => !i.isBought).toList();
  List<PantryItem> get expiringSoonItems => _pantryItems.where((i) => i.daysUntilExpiry <= 3 && i.daysUntilExpiry >= 0).toList();

  Future<void> init() async {
    debugPrint('🥗 Инициализация NutritionProvider...');

    // Пачка 1: независимые справочники
    await Future.wait([
      _loadProducts(),
      _loadTemplates(),   // ← добавили, раньше потерялся
      _loadWater(),
      _loadPantry(),
      _loadShoppingList(),
      _loadScanHistory(),
    ]);

    // Пачка 2: профиль перезаписывает дефолтные цели
    await Future.wait([
      _loadGoals(),
      _loadUserProfile(),
    ]);

    // Пачка 3: дневнику нужны загруженные _products
    await _loadDiary();

    // Пачка 4: строго последовательно — план зависит от программ
    await _loadPrograms();
    await _loadPlan();

    debugPrint('✅ NutritionProvider готов: ${_products.length} продуктов, '
        '${_templates.length} рецептов, ${_programs.length} программ, '
        '${_planDays.length} дней плana, ${_planMeals.length} приемов');
    notifyListeners();
  }



  // ==================== ЗАГРУЗКА ДАННЫХ ====================
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

  // ═══ АВТО-КЛАДОВАЯ: купленный товар → на полку ═══
  Future<void> markBoughtAndStock(String shoppingItemId) async {
    ShoppingItem? item;
    try {
      item = shoppingItems.firstWhere((i) => i.id == shoppingItemId);
    } catch (_) {
      return;
    }
    final wasBought = item.isBought;
    await toggleShoppingItem(shoppingItemId);
    if (wasBought) return; // сняли отметку — кладовую не трогаем

    final pid = item.productId;
    final hasPid = pid != null && pid.isNotEmpty;
    final name = item.displayName;
    final key = hasPid ? 'p:$pid' : 'n:${name.toLowerCase().trim()}';

    // ищем такую же позицию на полке (тот же продукт + та же единица)
    PantryItem? existing;
    for (final p in pantryItems) {
      final pPid = p.productId;
      final pKey = (pPid != null && pPid.isNotEmpty)
          ? 'p:$pPid'
          : 'n:${p.displayName.toLowerCase().trim()}';
      if (pKey == key && p.unit == item.unit) {
        existing = p;
        break;
      }
    }

    final freshExpiry =
    DateTime.now().add(Duration(days: _pantryShelfDays(item.category)));
    var expiry = freshExpiry;
    var qty = item.quantity;

    if (existing != null) {
      qty += existing.quantity;
      final old = existing.expiresAt;
      if (old != null && old.isBefore(freshExpiry)) expiry = old;
      removeFromPantry(existing.id);
    }

    await addToPantry(
      productId: pid,
      customName: name,
      quantity: qty,
      unit: item.unit,
      expiresAt: expiry,
    );
  }

  int _pantryShelfDays(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'fish': case 'рыба': return 2;
      case 'meat': case 'мясо': return 3;
      case 'bakery': case 'хлеб': return 4;
      case 'dairy': case 'молочка': return 7;
      case 'vegetables': case 'овощи': return 7;
      case 'fruits': case 'фрукты': return 7;
      case 'drinks': case 'напитки': return 30;
      case 'sweets': case 'сладости': return 30;
      case 'sauces': case 'соусы': return 60;
      case 'frozen': case 'заморозка': return 90;
      case 'grains': case 'бакалея': case 'крупы': return 180;
      default: return 14;
    }
  }

  Future<void> _loadUserProfile() async {
    final data = await _db.query('user_profile', orderBy: 'createdAt DESC', limit: 1);
    if (data.isNotEmpty) {
      _userProfile = UserProfile.fromMap(data.first);
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

  Future<void> _loadPantry() async {
    final data = await _db.query('pantry_items', orderBy: 'expiresAt ASC');
    _pantryItems = data.map((m) => PantryItem.fromMap(m)).toList();
  }

  // 🆕 ИСПРАВЛЕНО: Загружаем ВСЕ программы, а потом план ТОЛЬКО для активной
  Future<void> _loadPlan() async {
    final activeProg = activeProgram;
    if (activeProg == null) {
      _planDays = [];
      _planMeals = [];
      return;
    }

    final activeProgramId = activeProg.id;

    final daysData = await _db.query(
      'plan_days',
      where: 'programId = ?',
      whereArgs: [activeProgramId],
      orderBy: 'date ASC',
    );
    _planDays = daysData.map((m) => PlanDay.fromMap(m)).toList();

    if (_planDays.isNotEmpty) {
      final dayIds = _planDays.map((d) => d.id).toList();
      final placeholders = dayIds.map((_) => '?').join(',');
      final mealsData = await _db.query(
        'plan_meals',
        where: 'dayId IN ($placeholders)',
        whereArgs: dayIds,
        orderBy: 'createdAt ASC',
      );
      _planMeals = mealsData.map((m) => PlanMeal.fromMap(m)).toList();
    } else {
      _planMeals = [];
    }
  }

  Future<void> _loadShoppingList() async {
    final data = await _db.query('shopping_items', orderBy: 'isBought ASC, isUrgent DESC');
    _shoppingItems = data.map((m) => ShoppingItem.fromMap(m)).toList();
  }

  Future<void> _loadScanHistory() async {
    try {
      final data = await _db.query('barcode_scan_history', orderBy: 'scannedAt DESC', limit: 50);
      _scanHistory
        ..clear()
        ..addAll(data.map((m) => ScanHistoryEntry.fromMap(m)));
    } catch (e) {
      debugPrint('⚠️ _loadScanHistory: $e');
    }
  }

  Future<void> _loadPrograms() async {
    final data = await _db.query('nutrition_programs', orderBy: 'createdAt DESC');
    _programs = data.map((m) => NutritionProgram.fromMap(m)).toList();
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================
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

  bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  // ==================== ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ====================
  Future<void> saveUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await _db.insert('user_profile', profile.toMap());
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
    return _products.where((p) => p.name.toLowerCase().contains(q) || p.categoryName.toLowerCase().contains(q)).toList();
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
    await _db.update('food_products', updated.toMap(), where: 'id = ?', whereArgs: [p.id]);
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
    await _db.insertOrGetExisting('food_products', p.toMap());
    await _loadProducts();
    notifyListeners();
    return p;
  }

  // ==================== 🆕 v8: РЕЦЕПТЫ ====================
  Future<void> saveTemplate(MealTemplate template) async {
    final map = template.toMap();
    final existing = _templates.where((t) => t.id == template.id).toList();
    if (existing.isEmpty) {
      await _db.insert('meal_templates', map);
      _templates.insert(0, template);
    } else {
      await _db.update('meal_templates', map, where: 'id = ?', whereArgs: [template.id]);
      final idx = _templates.indexWhere((t) => t.id == template.id);
      if (idx != -1) _templates[idx] = template;
    }
    await _db.refreshTemplatesForProduct('');
    notifyListeners();
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

  Future<void> addTemplateAsMeal(MealTemplate template, MealType mealType, {DateTime? date, double portions = 1.0}) async {
    for (final item in template.items) {
      final product = _findProduct(item.productId);
      if (product != null) {
        await addEntry(
          product: product,
          grams: item.grams * portions,
          mealType: mealType,
          date: date,
          templateId: template.id,
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

  // ==================== 🆕 v11: ПРОГРАММЫ ПИТАНИЯ ====================

  Future<NutritionProgram> createProgram({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required double targetCalories,
    required double targetProtein,
    required double targetFat,
    required double targetCarbs,
    // 🆕 ОБНОВЛЕННАЯ СИГНАТУРА: принимаем порции, граммы и исключения
    required Map<String, List<({
    MealType type,
    String? templateId,
    double portions,
    double grams,
    List<String> excluded
    })>> dailyPlans,
    String? backgroundImage,
  }) async {
    debugPrint('🆕 Создание новой программы: $name');

    // Деактивируем старую активную программу (если есть)
    final oldActive = _programs.where((p) => p.isActive).firstOrNull;
    if (oldActive != null) {
      await _db.update('nutrition_programs', {'isActive': 0}, where: 'id = ?', whereArgs: [oldActive.id]);
      final idx = _programs.indexWhere((p) => p.id == oldActive.id);
      if (idx != -1) {
        _programs[idx] = _cloneWithActive(_programs[idx], false);
      }
    }

    final program = NutritionProgram(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      mode: ProgramMode.byMeals,
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetFat: targetFat,
      targetCarbs: targetCarbs,
      slots: [],
      isActive: true,
      backgroundImage: backgroundImage, // 🆕 Фон
    );

    await _db.insert('nutrition_programs', program.toMap());
    _programs.insert(0, program);

    // Создаем дни и приемы пищи
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final total = end.difference(start).inDays + 1;

    for (int i = 0; i < total; i++) {
      final d = start.add(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final day = PlanDay(
        id: _uuid.v4(),
        date: d,
        programId: program.id,
        targetCalories: targetCalories,
        targetProtein: targetProtein,
        targetFat: targetFat,
        targetCarbs: targetCarbs,
      );
      await _db.insert('plan_days', day.toMap());
      _planDays.add(day);

      final mealsForDay = dailyPlans[key] ?? [];

      // Если приемов пищи нет, создаем пустые слоты по умолчанию (опционально)
      if (mealsForDay.isEmpty) {
        // Можно добавить логику создания пустых слотов, если нужно
      }

      for (final planned in mealsForDay) {
        // 🆕 Расчет КБЖУ с учетом порций/граммов
        double mKcal = planned.templateId != null ? 0 : (targetCalories / (mealsForDay.length > 0 ? mealsForDay.length : 1));
        double mPro = planned.templateId != null ? 0 : (targetProtein / (mealsForDay.length > 0 ? mealsForDay.length : 1));
        double mFat = planned.templateId != null ? 0 : (targetFat / (mealsForDay.length > 0 ? mealsForDay.length : 1));
        double mCarb = planned.templateId != null ? 0 : (targetCarbs / (mealsForDay.length > 0 ? mealsForDay.length : 1));

        if (planned.templateId != null) {
          final isProduct = planned.templateId!.startsWith('PROD:');
          final actualId = isProduct ? planned.templateId!.replaceFirst('PROD:', '') : planned.templateId;

          if (isProduct) {
            final prod = _products.where((p) => p.id == actualId).firstOrNull;
            if (prod != null) {
              // Для продуктов считаем по граммам
              mKcal = prod.calories * (planned.grams / 100.0);
              mPro = prod.protein * (planned.grams / 100.0);
              mFat = prod.fat * (planned.grams / 100.0);
              mCarb = prod.carbs * (planned.grams / 100.0);
            }
          } else {
            final tpl = _templates.where((t) => t.id == actualId).firstOrNull;
            if (tpl != null) {
              // Для рецептов считаем по порциям
              mKcal = tpl.caloriesPerPortion * planned.portions;
              mPro = tpl.proteinPerPortion * planned.portions;
              mFat = tpl.fatPerPortion * planned.portions;
              mCarb = tpl.carbsPerPortion * planned.portions;
            }
          }
        }

        final meal = PlanMeal(
          id: _uuid.v4(),
          dayId: day.id,
          mealType: planned.type,
          templateId: planned.templateId,
          targetCalories: mKcal,
          targetProtein: mPro,
          targetFat: mFat,
          targetCarbs: mCarb,
          portions: planned.portions, // 🆕 Сохраняем порции
          // grams и excluded можно сохранить в note или добавить новые колонки в БД,
          // если они критичны для отображения в трекере прямо сейчас.
          // Пока сохраняем их в note в формате JSON для простоты, если нужно:
          note: planned.excluded.isNotEmpty ? jsonEncode({'excluded': planned.excluded, 'grams': planned.grams}) : null,
        );
        await _db.insert('plan_meals', meal.toMap());
        _planMeals.add(meal);
      }
    }

    _planDays.sort((a, b) => a.date.compareTo(b.date));
    debugPrint('✅ Программа создана: ${_planDays.length} дней, ${_planMeals.length} приемов пищи');
    notifyListeners();
    return program;
  }

  Future<void> startProgram(String programId) async {
    // Деактивируем все программы
    await _db.update('nutrition_programs', {'isActive': 0});
    // Активируем выбранную
    await _db.update('nutrition_programs', {'isActive': 1}, where: 'id = ?', whereArgs: [programId]);
    _programs = _programs.map((p) => p.id == programId ? _cloneWithActive(p, true) : _cloneWithActive(p, false)).toList();

    // Перезагружаем план для новой активной программы
    await _loadPlan();
    notifyListeners();
  }

  Future<void> finishProgram(String programId) async {
    await _db.update('nutrition_programs', {'isActive': 0}, where: 'id = ?', whereArgs: [programId]);
    _programs = _programs.map((p) => p.id == programId ? _cloneWithActive(p, false) : p).toList();
    await _loadPlan();
    notifyListeners();
  }

  Future<void> cancelProgram(String programId) async {
    await _db.update('nutrition_programs', {'isActive': 0}, where: 'id = ?', whereArgs: [programId]);
    _programs = _programs.map((p) => p.id == programId ? _cloneWithActive(p, false) : p).toList();
    await _loadPlan();
    notifyListeners();
  }

  NutritionProgram _cloneWithActive(NutritionProgram p, bool isActive) {
    return NutritionProgram(
      id: p.id, name: p.name, createdAt: p.createdAt, startDate: p.startDate,
      endDate: p.endDate, mode: p.mode, targetCalories: p.targetCalories,
      targetProtein: p.targetProtein, targetFat: p.targetFat, targetCarbs: p.targetCarbs,
      slots: p.slots, isActive: isActive, backgroundImage: p.backgroundImage, // 🆕 ДОБАВЛЕНО
    );
  }

  Future<void> setPlanDayType(String dayId, PlanDayType type) async {
    await _db.update('plan_days', {'dayType': type.name}, where: 'id = ?', whereArgs: [dayId]);
    final i = _planDays.indexWhere((d) => d.id == dayId);
    if (i == -1) return;
    final old = _planDays[i];
    _planDays[i] = PlanDay(
      id: old.id, date: old.date, programId: old.programId,
      targetCalories: old.targetCalories, targetProtein: old.targetProtein,
      targetFat: old.targetFat, targetCarbs: old.targetCarbs,
      isCheatDay: type == PlanDayType.cheat, isVacation: type == PlanDayType.vacation, dayType: type,
    );
    notifyListeners();
  }

  List<MealTemplate> suggestTemplatesForSlot({required double? calories, required double? protein, int limit = 5}) {
    if (calories == null || calories <= 0) return _templates.take(limit).toList();
    final list = List<MealTemplate>.from(_templates);
    list.sort((a, b) {
      final da = (a.caloriesPerPortion - calories).abs() + ((a.proteinPerPortion - (protein ?? 0)).abs() * 0.5);
      final db_ = (b.caloriesPerPortion - calories).abs() + ((b.proteinPerPortion - (protein ?? 0)).abs() * 0.5);
      return da.compareTo(db_);
    });
    return list.take(limit).toList();
  }

  // ==================== 🆕 v8: ПЛАН НЕДЕЛИ (УЛУЧШЕННАЯ ЛОГИКА) ====================

  // 🆕 ИСПРАВЛЕНО: Корректная обработка продуктов (PROD:) при отметке "Съел"
  Future<void> markMealAsCompleted(String mealId, {double portions = 1.0, DateTime? date}) async {
    final index = _planMeals.indexWhere((m) => m.id == mealId);
    if (index == -1) return;

    final meal = _planMeals[index];
    final targetDate = date ?? DateTime.now();

    final updatedMeal = PlanMeal(
      id: meal.id, dayId: meal.dayId, mealType: meal.mealType, templateId: meal.templateId,
      portions: portions, alternatives: meal.alternatives, isCompleted: true,
      actualGrams: meal.actualGrams, note: meal.note == 'Пропущено' ? null : meal.note,
    );

    await _db.update('plan_meals', {'isCompleted': 1, 'portions': portions, 'note': updatedMeal.note}, where: 'id = ?', whereArgs: [mealId]);
    _planMeals[index] = updatedMeal;

    // 🆕 ИСПРАВЛЕНО: Безопасное извлечение ID
    final isProduct = meal.templateId?.startsWith('PROD:') ?? false;
    final actualId = isProduct ? meal.templateId!.replaceFirst('PROD:', '') : meal.templateId;

    if (actualId != null && portions > 0) {
      if (isProduct) {
        final product = _products.where((p) => p.id == actualId).firstOrNull;
        if (product != null) {
          final alreadyLogged = getEntriesForDate(targetDate).any((e) => e.productId == product.id && e.mealType == meal.mealType);
          if (!alreadyLogged) {
            await addEntry(
              product: product, grams: 100, mealType: meal.mealType, date: targetDate,
              templateId: meal.templateId, templateName: product.name,
            );
          }
        }
      } else {
        final template = _templates.where((t) => t.id == actualId).firstOrNull;
        if (template != null) {
          final alreadyLogged = getEntriesForDate(targetDate).any((e) => e.templateId == template.id && e.mealType == meal.mealType);
          if (!alreadyLogged) {
            await _addTemplateAsMealWithPortions(template, meal.mealType, portions: portions, date: targetDate);
          }
        }
      }
    }
    notifyListeners();
  }

  Future<void> skipMeal(String mealId) async {
    final index = _planMeals.indexWhere((m) => m.id == mealId);
    if (index == -1) return;

    final meal = _planMeals[index];

    final updatedMeal = PlanMeal(
      id: meal.id,
      dayId: meal.dayId,
      mealType: meal.mealType,
      templateId: meal.templateId,
      portions: meal.portions,
      alternatives: meal.alternatives,
      isCompleted: true,
      actualGrams: 0,
      note: 'Пропущено',
    );

    await _db.update('plan_meals', {'isCompleted': 1, 'actualGrams': 0, 'note': 'Пропущено'}, where: 'id = ?', whereArgs: [mealId]);
    _planMeals[index] = updatedMeal;
    notifyListeners();
  }

  // 🆕 НОВЫЙ МЕТОД: Замена продукта/рецепта в приеме пищи
  Future<void> replaceMealItem(String mealId, String newTemplateId) async {
    final index = _planMeals.indexWhere((m) => m.id == mealId);
    if (index == -1) return;

    final oldMeal = _planMeals[index];

    // 🆕 ИСПРАВЛЕНО: Безопасное извлечение ID
    final isProduct = newTemplateId.startsWith('PROD:');
    final actualId = isProduct ? newTemplateId.replaceFirst('PROD:', '') : newTemplateId;

    double mKcal = oldMeal.targetCalories ?? 0;
    double mPro = oldMeal.targetProtein ?? 0;
    double mFat = oldMeal.targetFat ?? 0;
    double mCarb = oldMeal.targetCarbs ?? 0;

    if (isProduct) {
      final prod = _products.where((p) => p.id == actualId).firstOrNull;
      if (prod != null) {
        mKcal = prod.calories;
        mPro = prod.protein;
        mFat = prod.fat;
        mCarb = prod.carbs;
      }
    } else {
      final tpl = _templates.where((t) => t.id == actualId).firstOrNull;
      if (tpl != null) {
        mKcal = tpl.caloriesPerPortion;
        mPro = tpl.proteinPerPortion;
        mFat = tpl.fatPerPortion;
        mCarb = tpl.carbsPerPortion;
      }
    }

    final updatedMeal = PlanMeal(
      id: oldMeal.id,
      dayId: oldMeal.dayId,
      mealType: oldMeal.mealType,
      templateId: newTemplateId,
      targetCalories: mKcal,
      targetProtein: mPro,
      targetFat: mFat,
      targetCarbs: mCarb,
      portions: oldMeal.portions,
      isCompleted: false, // Сбрасываем статус "съедено"
      note: null,
    );

    await _db.update('plan_meals', updatedMeal.toMap(), where: 'id = ?', whereArgs: [mealId]);
    _planMeals[index] = updatedMeal;
    notifyListeners();
  }

  // 🆕 НОВЫЙ МЕТОД: Удаление приема пищи из плана
  Future<void> removeMealItem(String mealId) async {
    await _db.delete('plan_meals', where: 'id = ?', whereArgs: [mealId]);
    _planMeals.removeWhere((m) => m.id == mealId);
    notifyListeners();
  }

  Future<void> unmarkMealAsCompleted(String mealId) async {
    final index = _planMeals.indexWhere((m) => m.id == mealId);
    if (index == -1) return;

    final meal = _planMeals[index];

    final updatedMeal = PlanMeal(
      id: meal.id,
      dayId: meal.dayId,
      mealType: meal.mealType,
      templateId: meal.templateId,
      portions: meal.portions,
      alternatives: meal.alternatives,
      isCompleted: false,
      actualGrams: null,
      note: null,
    );

    await _db.update('plan_meals', {'isCompleted': 0, 'actualGrams': null, 'note': null}, where: 'id = ?', whereArgs: [mealId]);
    _planMeals[index] = updatedMeal;
    notifyListeners();
  }

  Future<void> _addTemplateAsMealWithPortions(MealTemplate template, MealType mealType, {required double portions, DateTime? date}) async {
    for (final item in template.items) {
      final product = _findProduct(item.productId);
      if (product != null) {
        await addEntry(product: product, grams: item.grams * portions, mealType: mealType, date: date, templateId: template.id, templateName: template.name);
      }
    }
  }

  List<MealTemplate> getAlternativeMeals(MealTemplate current, {int limit = 3}) {
    if (current.id.isEmpty) return [];
    final candidates = _templates.where((t) => t.id != current.id).toList();
    candidates.sort((a, b) => _calculateMacroDistance(current, a).compareTo(_calculateMacroDistance(current, b)));
    return candidates.take(limit).toList();
  }

  double _calculateMacroDistance(MealTemplate target, MealTemplate candidate) {
    final calDiff = (target.calories - candidate.calories).abs() / (target.calories + 1);
    final proDiff = (target.protein - candidate.protein).abs() / (target.protein + 1);
    final fatDiff = (target.fat - candidate.fat).abs() / (target.fat + 1);
    final carbDiff = (target.carbs - candidate.carbs).abs() / (target.carbs + 1);
    return (calDiff * 2.0) + (proDiff * 1.5) + (fatDiff * 1.0) + (carbDiff * 1.0);
  }

  Future<void> addToPlan({required DateTime date, required MealType mealType, String? templateId, double portions = 1}) async {
    final dateKey = _dateKey(date);
    var day = _planDays.firstWhere((d) => _dateKey(d.date) == dateKey, orElse: () => PlanDay(id: '', date: date));
    if (day.id.isEmpty) {
      final activeProg = activeProgram;
      if (activeProg == null) return;
      day = PlanDay(id: _uuid.v4(), date: date, programId: activeProg.id);
      await _db.insert('plan_days', day.toMap());
      _planDays.add(day);
      _planDays.sort((a, b) => a.date.compareTo(b.date));
    }

    // 🆕 ИСПРАВЛЕНО: Безопасное извлечение ID
    double mKcal = 0, mPro = 0, mFat = 0, mCarb = 0;
    if (templateId != null) {
      final isProduct = templateId.startsWith('PROD:');
      final actualId = isProduct ? templateId.replaceFirst('PROD:', '') : templateId;

      if (isProduct) {
        final prod = _products.where((p) => p.id == actualId).firstOrNull;
        if (prod != null) {
          mKcal = prod.calories;
          mPro = prod.protein;
          mFat = prod.fat;
          mCarb = prod.carbs;
        }
      } else {
        final tpl = _templates.where((t) => t.id == actualId).firstOrNull;
        if (tpl != null) {
          mKcal = tpl.caloriesPerPortion;
          mPro = tpl.proteinPerPortion;
          mFat = tpl.fatPerPortion;
          mCarb = tpl.carbsPerPortion;
        }
      }
    }

    final meal = PlanMeal(
      id: _uuid.v4(),
      dayId: day.id,
      mealType: mealType,
      templateId: templateId,
      portions: portions,
      targetCalories: mKcal,
      targetProtein: mPro,
      targetFat: mFat,
      targetCarbs: mCarb,
    );
    await _db.insert('plan_meals', meal.toMap());
    _planMeals.add(meal);
    notifyListeners();
  }

  Future<void> removeFromPlan(String mealId) async {
    await _db.delete('plan_meals', where: 'id = ?', whereArgs: [mealId]);
    _planMeals.removeWhere((m) => m.id == mealId);
    notifyListeners();
  }

  List<PlanMeal> getMealsForDay(DateTime date) {
    final day = _planDays.firstWhere((d) => _dateKey(d.date) == _dateKey(date), orElse: () => PlanDay(id: '', date: date));
    if (day.id.isEmpty) return [];
    return _planMeals.where((m) => m.dayId == day.id).toList()..sort((a, b) => a.mealType.index.compareTo(b.mealType.index));
  }

  // ==================== 🆕 v8: СПИСОК ПОКУПОК ====================
  Future<void> generateShoppingListFromPlan(DateTime startDate, DateTime endDate) async {
    final daysInRange = _planDays.where((d) => !d.date.isBefore(startDate) && !d.date.isAfter(endDate)).toList();
    for (final day in daysInRange) {
      final meals = _planMeals.where((m) => m.dayId == day.id).toList();
      for (final meal in meals) {
        if (meal.templateId == null) continue;
        final template = _templates.firstWhere((t) => t.id == meal.templateId, orElse: () => MealTemplate(id: '', name: '', items: []));
        for (final item in template.items) {
          final existingIndex = _shoppingItems.indexWhere((si) => si.productId == item.productId && !si.isBought);
          if (existingIndex != -1) {
            final current = _shoppingItems[existingIndex];
            final newQty = current.quantity + (item.grams * meal.portions);
            await _db.update('shopping_items', {'quantity': newQty}, where: 'id = ?', whereArgs: [current.id]);
            _shoppingItems[existingIndex] = ShoppingItem(
              id: current.id, productId: current.productId, customName: current.customName, quantity: newQty,
              unit: current.unit, packageWeight: current.packageWeight, estimatedPrice: current.estimatedPrice, isBought: false,
            );
          } else {
            final product = _findProduct(item.productId);
            final newItem = ShoppingItem(id: _uuid.v4(), productId: item.productId, customName: product?.name, quantity: item.grams * meal.portions, unit: 'г');
            await _db.insert('shopping_items', newItem.toMap());
            _shoppingItems.add(newItem);
          }
        }
      }
    }
    notifyListeners();
  }

  Future<void> deleteShoppingItem(String id) async {
    await _db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
    _shoppingItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  Future<void> toggleShoppingItem(String id) async {
    final index = _shoppingItems.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final item = _shoppingItems[index];
    final newState = !item.isBought;
    await _db.update('shopping_items', {'isBought': newState ? 1 : 0, 'updatedAt': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
    _shoppingItems[index] = item.copyWith(isBought: newState);
    notifyListeners();
  }

  Future<void> addShoppingItem({String? productId, String? customName, required double quantity, String unit = 'г', double? packageWeight, double? estimatedPrice, PriceBasis priceBasis = PriceBasis.perKg, bool isUrgent = false, String? fallbackName, String? category}) async {
    final item = ShoppingItem(id: _uuid.v4(), productId: productId, customName: customName, quantity: quantity, unit: unit, packageWeight: packageWeight, estimatedPrice: estimatedPrice, priceBasis: priceBasis, isUrgent: isUrgent, fallbackName: fallbackName, category: category);
    await _db.insert('shopping_items', item.toMap());
    _shoppingItems.add(item);
    notifyListeners();
  }

  Future<void> updateShoppingItemPrice(String id, double price, {PriceBasis? basis}) async {
    final index = _shoppingItems.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final old = _shoppingItems[index];
    final newBasis = basis ?? old.priceBasis;
    await _db.update('shopping_items', {'estimatedPrice': price, 'priceBasis': newBasis.name, 'updatedAt': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
    _shoppingItems[index] = old.copyWith(estimatedPrice: price, priceBasis: newBasis);
    notifyListeners();
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
    return List.generate(7, (i) => getSummaryForDate(now.subtract(Duration(days: 6 - i))));
  }

  Future<void> addWater(int amountMl, {DateTime? date}) async {
    final e = WaterEntry(id: _uuid.v4(), date: date ?? DateTime.now(), amountMl: amountMl);
    await _db.insert('water_entries', e.toMap());
    _waterEntries.insert(0, e);
    notifyListeners();
  }

  int getWaterForDate(DateTime date) {
    final key = _dateKey(date);
    return _waterEntries.where((e) => _dateKey(e.date) == key).fold<int>(0, (sum, e) => sum + e.amountMl);
  }

  NutritionGoals getGoalsForDate(DateTime date) {
    final daily = _dailyGoals[_dateKey(date)];
    if (daily != null) return daily;
    if (_defaultGoals != null) return _defaultGoals!;
    return NutritionGoals(id: 'fallback_${DateTime.now().millisecondsSinceEpoch}', calories: 2200, protein: 140, fat: 70, carbs: 250, waterMl: 2500);
  }

  Future<void> updateGoals(NutritionGoals goals) async {
    if (goals.date == null) {
      if (_defaultGoals != null) {
        await _db.update('nutrition_goals', goals.toMap(), where: 'id = ?', whereArgs: [_defaultGoals!.id]);
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

  // ==================== 🆕 v8: КЛАДОВАЯ (PANTRY) ====================
  Future<void> addToPantry({String? productId, String? customName, required double quantity, String unit = 'г', DateTime? expiresAt, double? price}) async {
    final item = PantryItem(id: _uuid.v4(), productId: productId, customName: customName, quantity: quantity, unit: unit, expiresAt: expiresAt, addedAt: DateTime.now(), price: price);
    await _db.insert('pantry_items', item.toMap());
    _pantryItems.add(item);
    _pantryItems.sort((a, b) => (a.expiresAt ?? DateTime(9999)).compareTo(b.expiresAt ?? DateTime(9999)));
    notifyListeners();
  }

  Future<void> removeFromPantry(String id) async {
    await _db.delete('pantry_items', where: 'id = ?', whereArgs: [id]);
    _pantryItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  Future<void> updatePantryQuantity(String id, double newQuantity) async {
    final item = _pantryItems.firstWhere((i) => i.id == id);
    await _db.update('pantry_items', {'quantity': newQuantity}, where: 'id = ?', whereArgs: [id]);
    final index = _pantryItems.indexWhere((i) => i.id == id);
    if (index != -1) {
      _pantryItems[index] = PantryItem(id: item.id, productId: item.productId, customName: item.customName, quantity: newQuantity, unit: item.unit, expiresAt: item.expiresAt, addedAt: item.addedAt, price: item.price);
    }
    notifyListeners();
  }

  // ==================== 🆕 ИСТОРИЯ ЦЕН ====================
  List<ShoppingItem> getPriceHistory(String productName, String currentItemId, {int limit = 3}) {
    final nameLower = productName.toLowerCase().trim();
    final history = _shoppingItems.where((item) {
      final itemName = (item.customName ?? 'Продукт').toLowerCase().trim();
      return itemName == nameLower && item.id != currentItemId;
    }).toList();
    history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return history.take(limit).toList();
  }

  double? getAverageHistoricalBasePrice(List<ShoppingItem> history) {
    if (history.isEmpty) return null;
    final totalBasePrice = history.fold<double>(0, (sum, item) => sum + item.pricePerBaseUnit);
    return totalBasePrice / history.length;
  }

  // ==================== УМНЫЕ РЕКОМЕНДАЦИИ ====================
  List<NutritionRecommendation> getRecommendations(DateTime date) {
    final recs = <NutritionRecommendation>[];
    final summary = getSummaryForDate(date);
    final goals = getGoalsForDate(date);
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 18 && goals.protein > 0 && summary.protein < goals.protein * 0.7) {
      recs.add(NutritionRecommendation(type: RecommendationType.protein, priority: 3, title: 'Белковый дефицит', message: 'До цели ещё ${(goals.protein - summary.protein).round()} г белка. Добавь творог или куриную грудку', emoji: '🥩', color: const Color(0xFF00FF9D)));
    }
    if (goals.calories > 0) {
      int deficitDays = 0;
      for (int i = 0; i < 3; i++) {
        if (getSummaryForDate(date.subtract(Duration(days: i))).calories < goals.calories * 0.75) deficitDays++;
      }
      if (deficitDays >= 3) {
        recs.add(NutritionRecommendation(type: RecommendationType.warning, priority: 2, title: 'Хронический дефицит', message: '$deficitDays дня подряд дефицит калорий >25%. Риск потери мышц.', emoji: '⚠️', color: const Color(0xFFFFD60A)));
      }
    }
    if (goals.waterMl > 0 && summary.waterMl < goals.waterMl * 0.5 && hour >= 15) {
      recs.add(NutritionRecommendation(type: RecommendationType.water, priority: 2, title: 'Пей больше воды', message: 'Выпито только ${summary.waterMl} мл из ${goals.waterMl}.', emoji: '💧', color: const Color(0xFF00D4FF)));
    }

    final todayEntries = getEntriesForDate(date);
    if (todayEntries.isNotEmpty) {
      final lastTimeStr = todayEntries.reduce((a, b) => (a.time ?? '').compareTo(b.time ?? '') > 0 ? a : b).time;
      if (lastTimeStr != null) {
        final lastTime = DateTime.tryParse(lastTimeStr);
        if (lastTime != null && now.difference(lastTime).inHours >= 5 && hour < 22) {
          recs.add(NutritionRecommendation(type: RecommendationType.timing, priority: 1, title: 'Пора перекусить', message: 'Прошло ${now.difference(lastTime).inHours} ч после последнего приёма пищи', emoji: '⏰', color: const Color(0xFFFF9500)));
        }
      }
    } else if (hour >= 10) {
      recs.add(NutritionRecommendation(type: RecommendationType.timing, priority: 2, title: 'Не забудь позавтракать', message: 'Уже ${hour - 6} часов утра, а завтрак ещё не был', emoji: '🌅', color: const Color(0xFFFF9500)));
    }

    if (goals.fat > 0 && summary.fat > goals.fat * 1.2) {
      recs.add(NutritionRecommendation(type: RecommendationType.warning, priority: 1, title: 'Перебор с жирами', message: 'Превышение на ${((summary.fat / goals.fat - 1) * 100).round()}%', emoji: '🧈', color: const Color(0xFFFF2D55)));
    }
    if (goals.carbs > 0 && summary.carbs < goals.carbs * 0.5 && hour >= 16) {
      recs.add(NutritionRecommendation(type: RecommendationType.energy, priority: 1, title: 'Мало энергии', message: 'Углеводов только ${summary.carbs.round()} г. Добавь рис или банан', emoji: '🍌', color: const Color(0xFFFFD60A)));
    }

    if (_userProfile != null) {
      final prediction = _userProfile!.goalPrediction;
      if (prediction['canPredict'] == true && prediction['days'] > 30) {
        recs.add(NutritionRecommendation(type: RecommendationType.energy, priority: 1, title: 'Корректировка темпа', message: 'Прогноз: ${prediction['days']} дней. Стоит ускорить темп.', emoji: '📊', color: const Color(0xFFFF9500)));
      }
      if (_userProfile!.bmiCategory != 'Норма') {
        recs.add(NutritionRecommendation(type: RecommendationType.warning, priority: 1, title: 'Внимание: ИМТ', message: 'Ваш ИМТ: ${_userProfile!.bmi.toStringAsFixed(1)} (${_userProfile!.bmiCategory})', emoji: '⚖️', color: const Color(0xFFFF2D55)));
      }
    }

    recs.sort((a, b) => b.priority.compareTo(a.priority));
    return recs;
  }

  // ==================== 🆕 v9: PRO BARCODE LOOKUP ====================
  final BarcodeLookupService _barcodeService = BarcodeLookupService();
  final Map<String, Future<BarcodeLookupResult>> _inFlight = {};
  static const _negativeTtlDays = 7;
  static const _positiveTtlDays = 30;

  Future<BarcodeLookupResult> lookupBarcode(String rawCode) {
    final gtin = BarcodeLookupService.extractGtin(rawCode) ?? rawCode.trim();
    if (gtin.isEmpty) return Future.value(const BarcodeLookupResult(notFound: true, hint: 'Пустой код'));
    return _inFlight.putIfAbsent(gtin, () async {
      try { return await _lookupInternal(gtin); } finally { _inFlight.remove(gtin); }
    });
  }

  Future<BarcodeLookupResult> _lookupInternal(String barcode) async {
    final country = BarcodeLookupService.countryFromBarcode(barcode);
    final local = await findProductByBarcode(barcode);
    if (local != null) {
      return BarcodeLookupResult(product: BarcodeProduct(barcode: barcode, name: local.name, category: local.category, calories: local.calories, protein: local.protein, fat: local.fat, carbs: local.carbs, fiber: local.fiber, source: BarcodeSource.localDb), hint: country);
    }
    final cached = await _readBarcodeCache(barcode);
    if (cached != null) {
      if (cached.found && cached.product != null) return BarcodeLookupResult(product: cached.product, hint: country, fromCache: true);
      if (!cached.found) return BarcodeLookupResult(notFound: true, hint: country == null ? 'Уже проверяли — в базах нет' : '$country · уже проверяли, в базах нет', fromCache: true);
    }
    if (BarcodeLookupService.isInternalBarcode(barcode)) return const BarcodeLookupResult(notFound: true, hint: 'Внутренний код — введи название вручную');

    var product = await _barcodeService.fetchOpenFoodFacts(barcode);
    product ??= await _barcodeService.fetchUpcItemDb(barcode);
    if (product == null) {
      await _writeBarcodeCache(barcode, null);
      return BarcodeLookupResult(notFound: true, hint: country);
    }

    final matched = _matchLocalCatalog(product);
    if (matched != null) {
      await attachBarcodeToProduct(matched.id, barcode);
      await _writeBarcodeCache(barcode, BarcodeProduct(barcode: barcode, name: matched.name, category: matched.category, calories: matched.calories, protein: matched.protein, fat: matched.fat, carbs: matched.carbs, fiber: matched.fiber, packageGrams: product.packageGrams, source: BarcodeSource.localDb));
      final p = _findProduct(matched.id)!;
      return BarcodeLookupResult(product: BarcodeProduct(barcode: barcode, name: p.name, category: p.category, calories: p.calories, protein: p.protein, fat: p.fat, carbs: p.carbs, fiber: p.fiber, packageGrams: product.packageGrams, source: BarcodeSource.localDb), hint: 'Сопоставлено с локальным каталогом');
    }
    await _writeBarcodeCache(barcode, product);
    return BarcodeLookupResult(product: product, hint: country);
  }

  FoodProduct? _matchLocalCatalog(BarcodeProduct p) {
    final haystack = '${p.name ?? ''} ${p.rawCategories ?? ''}'.toLowerCase();
    if (haystack.trim().isEmpty) return null;
    for (final entry in BarcodeLookupService.basicGoodsRu.entries) {
      if (!haystack.contains(entry.key)) continue;
      for (final candidate in entry.value) {
        final c = candidate.toLowerCase();
        for (final local in _products) { if (local.name.toLowerCase() == c) return local; }
        for (final local in _products) { if (local.name.toLowerCase().contains(c)) return local; }
      }
    }
    final n = (p.name ?? '').toLowerCase().trim();
    if (n.length >= 3) { for (final local in _products) { if (local.name.toLowerCase() == n) return local; } }
    return null;
  }

  Future<void> attachBarcodeToProduct(String productId, String barcode) async {
    await _db.update('food_products', {'barcode': barcode}, where: 'id = ?', whereArgs: [productId]);
    final i = _products.indexWhere((p) => p.id == productId);
    if (i != -1) {
      final p = _products[i];
      _products[i] = FoodProduct(id: p.id, name: p.name, category: p.category, calories: p.calories, protein: p.protein, fat: p.fat, carbs: p.carbs, fiber: p.fiber, isCustom: p.isCustom, barcode: barcode, imageUrl: p.imageUrl, isFavorite: p.isFavorite);
    }
    notifyListeners();
  }

  Future<FoodProduct> saveScannedProduct(BarcodeProduct p, {String? nameOverride}) async {
    final name = (nameOverride ?? p.displayName).trim();
    final draft = FoodProduct(id: _uuid.v4(), name: name.isEmpty ? 'Продукт ${p.barcode}' : name, category: p.category, calories: p.calories, protein: p.protein, fat: p.fat, carbs: p.carbs, fiber: p.fiber, isCustom: true, barcode: p.barcode, imageUrl: p.imageUrl);
    final realId = await _db.insertOrGetExisting('food_products', draft.toMap());
    await _db.update('food_products', {'barcode': p.barcode}, where: 'id = ?', whereArgs: [realId]);
    await _loadProducts();
    await _writeBarcodeCache(p.barcode, p.copyWith(name: draft.name));
    notifyListeners();
    return _findProduct(realId) ?? draft;
  }

  Future<List<OnlineHit>> searchProductsOnline(String query) => _barcodeService.searchByName(query);

  Future<({bool found, BarcodeProduct? product})?> _readBarcodeCache(String barcode) async {
    final rows = await _db.query('barcode_cache', where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    final checkedAt = DateTime.tryParse(r['checkedAt'] as String? ?? '');
    if (checkedAt == null) return null;
    final found = (r['found'] as int? ?? 0) == 1;
    final ttl = found ? _positiveTtlDays : _negativeTtlDays;
    if (DateTime.now().difference(checkedAt).inDays > ttl) return null;
    BarcodeProduct? p;
    final payload = r['payload'] as String?;
    if (found && payload != null && payload.isNotEmpty) {
      try { p = BarcodeProduct.fromMap(jsonDecode(payload) as Map<String, dynamic>); } catch (_) {}
    }
    return (found: found, product: p);
  }

  Future<void> _writeBarcodeCache(String barcode, BarcodeProduct? p) async {
    await _db.insert('barcode_cache', {'barcode': barcode, 'found': p != null ? 1 : 0, 'payload': p != null ? jsonEncode(p.toMap()) : null, 'source': p?.source.name, 'checkedAt': DateTime.now().toIso8601String()});
  }

  Future<void> invalidateBarcodeCache(String barcode) async {
    await _db.delete('barcode_cache', where: 'barcode = ?', whereArgs: [barcode]);
  }

  Future<void> addToScanHistory(BarcodeProduct product) async {
    final entry = ScanHistoryEntry(barcode: product.barcode, name: product.displayName, category: product.category, calories: product.calories, protein: product.protein, fat: product.fat, carbs: product.carbs, fiber: product.fiber, scannedAt: DateTime.now());
    try {
      await _db.insert('barcode_scan_history', entry.toMap());
      _scanHistory.insert(0, entry);
      if (_scanHistory.length > 50) _scanHistory.removeRange(50, _scanHistory.length);
      notifyListeners();
    } catch (e) { debugPrint('⚠️ addToScanHistory: $e'); }
  }

  // ==================== 🆕 v8: УМНАЯ КЛАДОВАЯ (OCR & Barcode) ====================
  Map<String, dynamic> parseOCRLabel(String text) {
    final result = <String, dynamic>{};
    final normalized = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final weightMatch = RegExp(r'(?:масса|вес|нетто|объем)?.{0,10}?(\d+(?:[.,]\d+)?)\s*(г|мл|кг|л)').firstMatch(normalized);
    if (weightMatch != null) {
      result['quantity'] = double.tryParse(weightMatch.group(1)!.replaceAll(',', '.')) ?? 0;
      result['unit'] = weightMatch.group(2) == 'кг' ? 'г' : (weightMatch.group(2) == 'л' ? 'мл' : weightMatch.group(2));
      if (result['unit'] == 'г' && (result['quantity'] as double) < 10) result['quantity'] = (result['quantity'] as double) * 1000;
    }
    final proteinMatch = RegExp(r'(?:белки|protein).*?(\d+(?:[.,]\d+)?)').firstMatch(normalized);
    if (proteinMatch != null) result['protein'] = double.tryParse(proteinMatch.group(1)!.replaceAll(',', '.'));
    final fatMatch = RegExp(r'(?:жиры|fat).*?(\d+(?:[.,]\d+)?)').firstMatch(normalized);
    if (fatMatch != null) result['fat'] = double.tryParse(fatMatch.group(1)!.replaceAll(',', '.'));
    final carbMatch = RegExp(r'(?:углеводы|carbs).*?(\d+(?:[.,]\d+)?)').firstMatch(normalized);
    if (carbMatch != null) result['carbs'] = double.tryParse(carbMatch.group(1)!.replaceAll(',', '.'));
    final calMatch = RegExp(r'(?:калорийность|энергетическая ценность|ккал).*?(\d+)').firstMatch(normalized);
    if (calMatch != null) result['calories'] = double.tryParse(calMatch.group(1)!);
    return result;
  }

  Future<FoodProduct?> findProductByBarcode(String barcode) async {
    try { return _products.firstWhere((p) => p.barcode == barcode); } catch (_) { return null; }
  }

  Future<FoodProduct?> fetchAndSaveProductFromBarcode(String barcode) async {
    try {
      final url = Uri.parse('https://ru.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final p = data['product'] as Map<String, dynamic>;
          final nutriments = p['nutriments'] as Map<String, dynamic>? ?? {};
          final name = (p['product_name_ru'] as String?)?.trim() ?? (p['product_name'] as String?)?.trim() ?? (p['product_name_en'] as String?)?.trim() ?? 'Продукт без названия';
          final brand = (p['brands'] as String?)?.trim() ?? '';
          final fullName = brand.isNotEmpty && name != 'Продукт без названия' ? '$name ($brand)' : (brand.isNotEmpty ? brand : name);
          final newProduct = FoodProduct(id: _uuid.v4(), name: fullName, category: 'other', calories: (nutriments['energy-kcal_100g'] as num?)?.toDouble() ?? 0, protein: (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0, fat: (nutriments['fat_100g'] as num?)?.toDouble() ?? 0, carbs: (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0, isCustom: true, barcode: barcode);
          await _db.insertOrGetExisting('food_products', newProduct.toMap());
          await _loadProducts();
          return newProduct;
        }
      }
    } catch (e) { debugPrint('❌ Ошибка OpenFoodFacts: $e'); }
    return null;
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

  NutritionRecommendation({required this.type, required this.priority, required this.title, required this.message, required this.emoji, required this.color});
}