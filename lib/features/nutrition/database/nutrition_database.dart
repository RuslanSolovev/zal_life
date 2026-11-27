import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'database_seeds.dart'; // 🆕 Импорт файла с начальными данными

class NutritionDatabase {
  static final NutritionDatabase _instance = NutritionDatabase._internal();
  static Database? _database;

  NutritionDatabase._internal();

  factory NutritionDatabase() => _instance;

  // 🆕 Версия увеличена до 13 для добавления backgroundImage в программы
  static const int currentVersion = 13;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = join(directory.path, 'nutrition_app.db');
    return openDatabase(
      dbPath,
      version: currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        try {
          await _createIndexes(db);
        } catch (e) {
          debugPrint('⚠️ onOpen _createIndexes: $e');
        }
      },
    );
  }

  Future<void> deleteDatabaseFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = join(directory.path, 'nutrition_app.db');
    try {
      if (_database != null && _database!.isOpen) await _database!.close();
      _database = null;
      final dbFile = File(dbPath);
      if (await dbFile.exists()) await dbFile.delete();
      if (await File('$dbPath-wal').exists()) await File('$dbPath-wal').delete();
      if (await File('$dbPath-shm').exists()) await File('$dbPath-shm').delete();
      debugPrint('✅ Все файлы БД питания очищены');
    } catch (e) {
      debugPrint('⚠️ Ошибка удаления БД питания: $e');
    }
  }

  // ==========================================================================
  // SCHEMA & INITIALIZATION
  // ==========================================================================
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('📦 Создание БД питания версии $version');
    await db.transaction((txn) async {
      await _createSchema(txn);
      await _createIndexes(txn);
      await seedV7Products(txn); // 🆕 Вызов из database_seeds.dart
      await seedV7Templates(txn); // 🆕 Вызов из database_seeds.dart
      await _recalculateAllTemplateNutrition(txn);
      await _seedDefaultGoals(txn);
      await _backfillRecipesV8(txn);
    });
    debugPrint('✅ БД питания v$version создана');
  }

  Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS food_products (
      id TEXT PRIMARY KEY, 
      name TEXT NOT NULL, 
      nameNormalized TEXT, 
      category TEXT DEFAULT 'other', 
      calories REAL DEFAULT 0, 
      protein REAL DEFAULT 0, 
      fat REAL DEFAULT 0, 
      carbs REAL DEFAULT 0, 
      fiber REAL DEFAULT 0, 
      isCustom INTEGER DEFAULT 0, 
      barcode TEXT, 
      imageUrl TEXT, 
      isFavorite INTEGER DEFAULT 0, 
      createdAt TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS food_diary (
      id TEXT PRIMARY KEY, 
      date TEXT NOT NULL, 
      mealType TEXT NOT NULL, 
      productId TEXT NOT NULL, 
      grams REAL NOT NULL, 
      calories REAL DEFAULT 0, 
      protein REAL DEFAULT 0, 
      fat REAL DEFAULT 0, 
      carbs REAL DEFAULT 0, 
      time TEXT, 
      note TEXT, 
      templateId TEXT, 
      templateName TEXT, 
      createdAt TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS meal_templates (
      id TEXT PRIMARY KEY, 
      name TEXT NOT NULL, 
      nameNormalized TEXT, 
      description TEXT, 
      items TEXT DEFAULT '[]', 
      portions INTEGER DEFAULT 1, 
      cookedWeight REAL, 
      steps TEXT DEFAULT '[]', 
      tags TEXT DEFAULT '[]', 
      photoBase64 TEXT, 
      isFavorite INTEGER DEFAULT 0, 
      prepTimeMin INTEGER, 
      cookTimeMin INTEGER, 
      difficulty TEXT DEFAULT 'easy', 
      calories REAL DEFAULT 0, 
      protein REAL DEFAULT 0, 
      fat REAL DEFAULT 0, 
      carbs REAL DEFAULT 0, 
      fiber REAL DEFAULT 0, 
      totalGrams REAL DEFAULT 0, 
      caloriesPer100g REAL DEFAULT 0, 
      proteinPer100g REAL DEFAULT 0, 
      fatPer100g REAL DEFAULT 0, 
      carbsPer100g REAL DEFAULT 0, 
      createdAt TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS nutrition_goals (
      id TEXT PRIMARY KEY, 
      date TEXT, 
      calories REAL DEFAULT 0, 
      protein REAL DEFAULT 0, 
      fat REAL DEFAULT 0, 
      carbs REAL DEFAULT 0, 
      waterMl INTEGER DEFAULT 2000, 
      isActive INTEGER DEFAULT 1, 
      createdAt TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS water_entries (
      id TEXT PRIMARY KEY, 
      date TEXT NOT NULL, 
      amountMl INTEGER NOT NULL, 
      time TEXT, 
      createdAt TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS user_profile (
      id TEXT PRIMARY KEY, 
      createdAt TEXT NOT NULL, 
      gender TEXT NOT NULL, 
      age INTEGER NOT NULL, 
      weight REAL NOT NULL, 
      height REAL NOT NULL, 
      activityLevel TEXT NOT NULL, 
      goalType TEXT NOT NULL, 
      goalPace TEXT NOT NULL, 
      targetWeight REAL, 
      targetDays INTEGER, 
      stepsPerDay INTEGER DEFAULT 5000, 
      workoutsPerWeek INTEGER DEFAULT 0, 
      bodyFatPercentage REAL DEFAULT 0
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS recipe_cook_logs (
      id TEXT PRIMARY KEY, 
      templateId TEXT NOT NULL, 
      cookedAt TEXT NOT NULL, 
      portions INTEGER DEFAULT 1, 
      rating INTEGER, 
      note TEXT, 
      photoBase64 TEXT, 
      createdAt TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS price_history (
      id TEXT PRIMARY KEY, 
      productId TEXT NOT NULL, 
      price REAL NOT NULL, 
      unit TEXT DEFAULT 'package', 
      store TEXT, 
      date TEXT NOT NULL, 
      createdAt TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS pantry_items (
      id TEXT PRIMARY KEY, 
      productId TEXT, 
      customName TEXT, 
      quantity REAL NOT NULL, 
      unit TEXT DEFAULT 'г', 
      expiresAt TEXT, 
      addedAt TEXT NOT NULL, 
      price REAL, 
      createdAt TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS plan_days (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  programId TEXT,
  dayType TEXT DEFAULT 'regular',
  targetCalories REAL,
  targetProtein REAL,
  targetFat REAL,
  targetCarbs REAL,
  isCheatDay INTEGER DEFAULT 0,
  isVacation INTEGER DEFAULT 0,
  createdAt TEXT NOT NULL
)
''');

    await db.execute('''CREATE TABLE IF NOT EXISTS plan_meals (
      id TEXT PRIMARY KEY, 
      dayId TEXT NOT NULL, 
      mealType TEXT NOT NULL, 
      templateId TEXT, 
      portions REAL DEFAULT 1, 
      alternatives TEXT DEFAULT '[]', 
      isCompleted INTEGER DEFAULT 0, 
      actualGrams REAL, 
      note TEXT, 
      createdAt TEXT NOT NULL, 
      FOREIGN KEY (dayId) REFERENCES plan_days(id) ON DELETE CASCADE
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS shopping_items (
      id TEXT PRIMARY KEY, 
      productId TEXT, 
      customName TEXT, 
      quantity REAL NOT NULL, 
      unit TEXT DEFAULT 'г', 
      packageWeight REAL, 
      estimatedPrice REAL, 
      priceBasis TEXT DEFAULT 'perKg', 
      store TEXT, 
      isUrgent INTEGER DEFAULT 0, 
      isBought INTEGER DEFAULT 0, 
      fallbackName TEXT, 
      category TEXT, 
      createdAt TEXT NOT NULL, 
      updatedAt TEXT NOT NULL
    )''');

    // 🆕 Таблица для кэша штрихкодов (используется в lookupBarcode)
    await db.execute('''CREATE TABLE IF NOT EXISTS barcode_cache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      barcode TEXT NOT NULL,
      found INTEGER DEFAULT 0,
      payload TEXT,
      source TEXT,
      checkedAt TEXT NOT NULL
    )''');

    // 🆕 Таблица для истории сканирований (ИДЕЯ 2)
    await db.execute('''CREATE TABLE IF NOT EXISTS barcode_scan_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      barcode TEXT NOT NULL,
      name TEXT NOT NULL,
      category TEXT DEFAULT 'other',
      calories REAL DEFAULT 0,
      protein REAL DEFAULT 0,
      fat REAL DEFAULT 0,
      carbs REAL DEFAULT 0,
      fiber REAL DEFAULT 0,
      scannedAt TEXT NOT NULL
    )''');

    // 🆕 Таблица для программ питания (v11) — 🆕 ДОБАВЛЕНО backgroundImage
    await db.execute('''CREATE TABLE IF NOT EXISTS nutrition_programs (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      startDate TEXT NOT NULL,
      endDate TEXT NOT NULL,
      mode TEXT NOT NULL,
      targetCalories REAL NOT NULL,
      targetProtein REAL NOT NULL,
      targetFat REAL NOT NULL,
      targetCarbs REAL NOT NULL,
      slots TEXT DEFAULT '[]',
      isActive INTEGER DEFAULT 1,
      backgroundImage TEXT
    )''');

    await _addColumnIfMissing(db, 'food_products', 'nameNormalized', 'TEXT');
    await _addColumnIfMissing(db, 'meal_templates', 'nameNormalized', 'TEXT');
    await _addColumnIfMissing(db, 'food_diary', 'templateId', 'TEXT');
    await _addColumnIfMissing(db, 'food_diary', 'templateName', 'TEXT');
    await _addColumnIfMissing(db, 'meal_templates', 'calories', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'meal_templates', 'protein', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'meal_templates', 'fat', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'meal_templates', 'carbs', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'meal_templates', 'fiber', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'meal_templates', 'totalGrams', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'meal_templates', 'description', 'TEXT');
    await _addColumnIfMissing(db, 'meal_templates', 'portions', 'INTEGER DEFAULT 1');
    await _addColumnIfMissing(db, 'meal_templates', 'cookedWeight', 'REAL');
    await _addColumnIfMissing(db, 'meal_templates', 'steps', "TEXT DEFAULT '[]'");
    await _addColumnIfMissing(db, 'meal_templates', 'tags', "TEXT DEFAULT '[]'");
    await _addColumnIfMissing(db, 'meal_templates', 'photoBase64', 'TEXT');
    await _addColumnIfMissing(db, 'meal_templates', 'isFavorite', 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(db, 'meal_templates', 'prepTimeMin', 'INTEGER');
    await _addColumnIfMissing(db, 'meal_templates', 'cookTimeMin', 'INTEGER');
    await _addColumnIfMissing(db, 'meal_templates', 'difficulty', "TEXT DEFAULT 'easy'");
    await _addColumnIfMissing(db, 'meal_templates', 'caloriesPer100g', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'meal_templates', 'proteinPer100g', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'meal_templates', 'fatPer100g', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'meal_templates', 'carbsPer100g', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'shopping_items', 'category', 'TEXT');
    await _addColumnIfMissing(db, 'shopping_items', 'fallbackName', 'TEXT');

    // 🆕 Новые колонки для v11
    await _addColumnIfMissing(db, 'plan_days', 'programId', 'TEXT');
    await _addColumnIfMissing(db, 'plan_days', 'dayType', "TEXT DEFAULT 'regular'");
    await _addColumnIfMissing(db, 'plan_meals', 'targetCalories', 'REAL');
    await _addColumnIfMissing(db, 'plan_meals', 'targetProtein', 'REAL');
    await _addColumnIfMissing(db, 'plan_meals', 'targetFat', 'REAL');
    await _addColumnIfMissing(db, 'plan_meals', 'targetCarbs', 'REAL');
  }

  Future<void> _addColumnIfMissing(DatabaseExecutor db, String table, String column, String definition) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (!columns.any((row) => row['name'] == column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
      debugPrint('✅ Добавлена колонка $table.$column');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Миграция БД питания: $oldVersion → $newVersion');
    await db.transaction((txn) async {
      await _createSchema(txn);
      await _backfillNormalizedNames(txn);

      if (oldVersion < 7) {
        await _cleanupDuplicateProductsV7(txn);
        await _cleanupDuplicateTemplatesV7(txn);
      }

      await _createIndexes(txn);

      if (oldVersion < 7) {
        await seedV7Products(txn); // 🆕
        await seedV7Templates(txn); // 🆕
        await _recalculateAllTemplateNutrition(txn);
      }

      if (oldVersion < 8) await _backfillRecipesV8(txn);

      // 🆕 Миграция для версии 10 (история сканирований)
      if (oldVersion < 10) {
        await txn.execute('''CREATE TABLE IF NOT EXISTS barcode_scan_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barcode TEXT NOT NULL,
          name TEXT NOT NULL,
          category TEXT DEFAULT 'other',
          calories REAL DEFAULT 0,
          protein REAL DEFAULT 0,
          fat REAL DEFAULT 0,
          carbs REAL DEFAULT 0,
          fiber REAL DEFAULT 0,
          scannedAt TEXT NOT NULL
        )''');

        // Также создаем таблицу кэша, если её вдруг не было
        await txn.execute('''CREATE TABLE IF NOT EXISTS barcode_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barcode TEXT NOT NULL,
          found INTEGER DEFAULT 0,
          payload TEXT,
          source TEXT,
          checkedAt TEXT NOT NULL
        )''');

        debugPrint('✅ v10: добавлены таблицы barcode_scan_history и barcode_cache');
      }

      // 🆕 Миграция для версии 11 (программы питания и таргеты)
      if (oldVersion < 11) {
        await txn.execute('''CREATE TABLE IF NOT EXISTS nutrition_programs (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          startDate TEXT NOT NULL,
          endDate TEXT NOT NULL,
          mode TEXT NOT NULL,
          targetCalories REAL NOT NULL,
          targetProtein REAL NOT NULL,
          targetFat REAL NOT NULL,
          targetCarbs REAL NOT NULL,
          slots TEXT DEFAULT '[]',
          isActive INTEGER DEFAULT 1
        )''');

        await _addColumnIfMissing(txn, 'plan_days', 'programId', 'TEXT');
        await _addColumnIfMissing(txn, 'plan_days', 'dayType', "TEXT DEFAULT 'regular'");
        await _addColumnIfMissing(txn, 'plan_meals', 'targetCalories', 'REAL');
        await _addColumnIfMissing(txn, 'plan_meals', 'targetProtein', 'REAL');
        await _addColumnIfMissing(txn, 'plan_meals', 'targetFat', 'REAL');
        await _addColumnIfMissing(txn, 'plan_meals', 'targetCarbs', 'REAL');

        debugPrint('✅ v11: nutrition_programs + target-поля для plan_meals');
      }


      if (oldVersion < 12) {
        await txn.execute('''CREATE TABLE plan_days_new (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL,
    programId TEXT,
    dayType TEXT DEFAULT 'regular',
    targetCalories REAL,
    targetProtein REAL,
    targetFat REAL,
    targetCarbs REAL,
    isCheatDay INTEGER DEFAULT 0,
    isVacation INTEGER DEFAULT 0,
    createdAt TEXT NOT NULL
  )''');
        await txn.execute('''
    INSERT OR IGNORE INTO plan_days_new
      (id, date, programId, dayType, targetCalories, targetProtein, targetFat, targetCarbs, isCheatDay, isVacation, createdAt)
    SELECT id, date, programId, dayType, targetCalories, targetProtein, targetFat, targetCarbs, isCheatDay, isVacation, createdAt
    FROM plan_days
  ''');
        await txn.execute('DROP TABLE plan_days');
        await txn.execute('ALTER TABLE plan_days_new RENAME TO plan_days');
        await _createIndexes(txn);
        debugPrint('✅ v12: plan_days пересоздана без UNIQUE(date)');
      }

      // 🆕 Миграция для версии 13 (добавление backgroundImage в программы)
      if (oldVersion < 13) {
        await _addColumnIfMissing(txn, 'nutrition_programs', 'backgroundImage', 'TEXT');
        debugPrint('✅ v13: добавлена колонка backgroundImage в nutrition_programs');
      }

      await _seedDefaultGoals(txn);
    });

    debugPrint('✅ ===== МИГРАЦИЯ v$newVersion ЗАВЕРШЕНА =====');
  }



  // ==========================================================================
  // NORMALIZATION & DEDUPLICATION
  // ==========================================================================
  String _normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  Future<void> _backfillNormalizedNames(DatabaseExecutor db) async {
    await _backfillTable(db, 'food_products');
    await _backfillTable(db, 'meal_templates');
  }

  Future<void> _backfillTable(DatabaseExecutor db, String table) async {
    final rows = await db.query(table, columns: ['id', 'name', 'nameNormalized']);
    for (final row in rows) {
      final current = row['nameNormalized'] as String?;
      if (current != null && current.isNotEmpty) continue;
      await db.update(table, {'nameNormalized': _normalizeName(row['name'] as String? ?? '')},
          where: 'id = ?', whereArgs: [row['id']]);
    }
  }

  Future<void> _cleanupDuplicateProductsV7(DatabaseExecutor db) async {
    final rows = await db.query('food_products', orderBy: 'createdAt ASC');
    final groups = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      final key = (row['nameNormalized'] as String? ?? '').trim();
      if (key.isEmpty) continue;
      groups.putIfAbsent(key, () => <Map<String, Object?>>[]).add(row);
    }
    int deleted = 0;
    for (final group in groups.values) {
      if (group.length < 2) continue;
      group.sort((a, b) {
        final ac = (a['isCustom'] as num?)?.toInt() ?? 0;
        final bc = (b['isCustom'] as num?)?.toInt() ?? 0;
        if (ac != bc) return bc.compareTo(ac);
        final af = (a['isFavorite'] as num?)?.toInt() ?? 0;
        final bf = (b['isFavorite'] as num?)?.toInt() ?? 0;
        if (af != bf) return bf.compareTo(af);
        return (a['createdAt'] as String? ?? '').compareTo(b['createdAt'] as String? ?? '');
      });
      final canonical = group.first;
      final canonicalId = canonical['id'] as String;
      if (group.any((row) => ((row['isFavorite'] as num?)?.toInt() ?? 0) == 1)) {
        await db.update('food_products', {'isFavorite': 1}, where: 'id = ?', whereArgs: [canonicalId]);
      }
      for (final duplicate in group.skip(1)) {
        final duplicateId = duplicate['id'] as String;
        await db.update('food_diary', {'productId': canonicalId}, where: 'productId = ?', whereArgs: [duplicateId]);
        await _replaceProductIdInAllTemplates(db, duplicateId, canonicalId, canonical['name'] as String);
        await db.delete('food_products', where: 'id = ?', whereArgs: [duplicateId]);
        deleted++;
      }
    }
    debugPrint('🧹 v7: удалено дублей продуктов: $deleted');
  }

  Future<void> _replaceProductIdInAllTemplates(DatabaseExecutor db, String oldProductId, String newProductId, String canonicalName) async {
    final templates = await db.query('meal_templates');
    for (final template in templates) {
      dynamic decoded;
      try {
        decoded = jsonDecode(template['items'] as String? ?? '[]');
      } catch (_) {
        continue;
      }
      if (decoded is! List) continue;
      bool changed = false;
      final updatedItems = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        if (map['productId'] == oldProductId) {
          map['productId'] = newProductId;
          map['name'] = canonicalName;
          changed = true;
        }
        updatedItems.add(map);
      }
      if (changed) {
        await db.update('meal_templates', {'items': jsonEncode(updatedItems)},
            where: 'id = ?', whereArgs: [template['id']]);
      }
    }
  }

  Future<void> _cleanupDuplicateTemplatesV7(DatabaseExecutor db) async {
    final rows = await db.query('meal_templates', orderBy: 'createdAt ASC');
    final groups = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      final key = (row['nameNormalized'] as String? ?? '').trim();
      if (key.isEmpty) continue;
      groups.putIfAbsent(key, () => <Map<String, Object?>>[]).add(row);
    }
    int deleted = 0;
    for (final group in groups.values) {
      if (group.length < 2) continue;
      group.sort((a, b) => _templateItemCount(b['items']).compareTo(_templateItemCount(a['items'])));
      final canonical = group.first;
      final canonicalId = canonical['id'] as String;
      final canonicalName = canonical['name'] as String;
      for (final duplicate in group.skip(1)) {
        final duplicateId = duplicate['id'] as String;
        await db.update('food_diary', {'templateId': canonicalId, 'templateName': canonicalName},
            where: 'templateId = ?', whereArgs: [duplicateId]);
        await db.delete('meal_templates', where: 'id = ?', whereArgs: [duplicateId]);
        deleted++;
      }
    }
    debugPrint('🧹 v7: удалено дублей готовых блюд: $deleted');
  }

  int _templateItemCount(Object? rawItems) {
    try {
      final decoded = jsonDecode(rawItems as String? ?? '[]');
      return decoded is List ? decoded.length : 0;
    } catch (_) {
      return 0;
    }
  }

  // ==========================================================================
  // BACKFILL & NUTRITION CALCULATION
  // ==========================================================================
  Future<void> _backfillRecipesV8(DatabaseExecutor db) async {
    await db.rawUpdate('UPDATE meal_templates SET portions = 1 WHERE portions IS NULL OR portions < 1');
    await db.rawUpdate("UPDATE meal_templates SET difficulty = 'easy' WHERE difficulty IS NULL OR TRIM(difficulty) = ''");
    await db.rawUpdate("UPDATE meal_templates SET tags = '[]' WHERE tags IS NULL OR TRIM(tags) = ''");
    await db.rawUpdate("UPDATE meal_templates SET steps = '[]' WHERE steps IS NULL OR TRIM(steps) = ''");
  }

  Future<Map<String, double>> calculateTemplateNutrition(String templateId) async {
    final db = await database;
    return _calculateTemplateNutritionWithDb(db, templateId);
  }

  Future<Map<String, double>> _calculateTemplateNutritionWithDb(DatabaseExecutor db, String templateId) async {
    final templateRows = await db.query('meal_templates', where: 'id = ?', whereArgs: [templateId], limit: 1);
    if (templateRows.isEmpty) {
      return {'calories': 0, 'protein': 0, 'fat': 0, 'carbs': 0, 'fiber': 0, 'grams': 0};
    }
    final template = templateRows.first;
    dynamic decoded;
    try {
      decoded = jsonDecode(template['items'] as String? ?? '[]');
    } catch (_) {
      decoded = <dynamic>[];
    }
    if (decoded is! List) decoded = <dynamic>[];
    double calories = 0, protein = 0, fat = 0, carbs = 0, fiber = 0, totalGrams = 0;
    final productCache = <String, Map<String, Object?>>{};
    for (final rawItem in decoded) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final productId = item['productId'] as String?;
      final grams = (item['grams'] as num?)?.toDouble() ?? 0;
      if (productId == null || productId.isEmpty || grams <= 0) continue;
      Map<String, Object?>? product = productCache[productId];
      if (product == null) {
        final rows = await db.query('food_products', where: 'id = ?', whereArgs: [productId], limit: 1);
        if (rows.isEmpty) continue;
        product = Map<String, Object?>.from(rows.first);
        productCache[productId] = product;
      }
      final factor = grams / 100.0;
      calories += ((product['calories'] as num?)?.toDouble() ?? 0) * factor;
      protein += ((product['protein'] as num?)?.toDouble() ?? 0) * factor;
      fat += ((product['fat'] as num?)?.toDouble() ?? 0) * factor;
      carbs += ((product['carbs'] as num?)?.toDouble() ?? 0) * factor;
      fiber += ((product['fiber'] as num?)?.toDouble() ?? 0) * factor;
      totalGrams += grams;
    }
    return {'calories': calories, 'protein': protein, 'fat': fat, 'carbs': carbs, 'fiber': fiber, 'grams': totalGrams};
  }

  Future<void> _recalculateTemplateNutrition(DatabaseExecutor db, String templateId) async {
    final templateRows = await db.query('meal_templates', where: 'id = ?', whereArgs: [templateId], limit: 1);
    if (templateRows.isEmpty) return;
    final rawNutrition = await _calculateTemplateNutritionWithDb(db, templateId);
    final template = templateRows.first;
    final cookedWeight = (template['cookedWeight'] as num?)?.toDouble();
    double cPer100 = 0, pPer100 = 0, fPer100 = 0, cbPer100 = 0;
    if (cookedWeight != null && cookedWeight > 0) {
      final factor = 100.0 / cookedWeight;
      cPer100 = (rawNutrition['calories'] ?? 0) * factor;
      pPer100 = (rawNutrition['protein'] ?? 0) * factor;
      fPer100 = (rawNutrition['fat'] ?? 0) * factor;
      cbPer100 = (rawNutrition['carbs'] ?? 0) * factor;
    }
    await db.update('meal_templates', {
      'calories': rawNutrition['calories'] ?? 0,
      'protein': rawNutrition['protein'] ?? 0,
      'fat': rawNutrition['fat'] ?? 0,
      'carbs': rawNutrition['carbs'] ?? 0,
      'fiber': rawNutrition['fiber'] ?? 0,
      'totalGrams': rawNutrition['grams'] ?? 0,
      'caloriesPer100g': cPer100,
      'proteinPer100g': pPer100,
      'fatPer100g': fPer100,
      'carbsPer100g': cbPer100,
    }, where: 'id = ?', whereArgs: [templateId]);
  }

  Future<void> _recalculateAllTemplateNutrition(DatabaseExecutor db) async {
    final allProducts = await db.query('food_products');
    final productMap = <String, Map<String, Object?>>{};
    for (final p in allProducts) productMap[p['id'] as String] = p;
    final allTemplates = await db.query('meal_templates');
    final batch = db.batch();
    for (final template in allTemplates) {
      final id = template['id'] as String;
      final rawItems = template['items'] as String? ?? '[]';
      final cookedWeight = (template['cookedWeight'] as num?)?.toDouble();
      dynamic decoded;
      try {
        decoded = jsonDecode(rawItems);
      } catch (_) {
        continue;
      }
      if (decoded is! List) continue;
      double cal = 0, pro = 0, fat = 0, carb = 0, fib = 0, grams = 0;
      for (final rawItem in decoded) {
        if (rawItem is! Map) continue;
        final productId = rawItem['productId'] as String?;
        final g = (rawItem['grams'] as num?)?.toDouble() ?? 0;
        if (productId == null || g <= 0) continue;
        final product = productMap[productId];
        if (product == null) continue;
        final factor = g / 100.0;
        cal += ((product['calories'] as num?)?.toDouble() ?? 0) * factor;
        pro += ((product['protein'] as num?)?.toDouble() ?? 0) * factor;
        fat += ((product['fat'] as num?)?.toDouble() ?? 0) * factor;
        carb += ((product['carbs'] as num?)?.toDouble() ?? 0) * factor;
        fib += ((product['fiber'] as num?)?.toDouble() ?? 0) * factor;
        grams += g;
      }
      double cPer100 = 0, pPer100 = 0, fPer100 = 0, cbPer100 = 0;
      if (cookedWeight != null && cookedWeight > 0) {
        final f = 100.0 / cookedWeight;
        cPer100 = cal * f;
        pPer100 = pro * f;
        fPer100 = fat * f;
        cbPer100 = carb * f;
      }
      batch.update('meal_templates', {
        'calories': cal,
        'protein': pro,
        'fat': fat,
        'carbs': carb,
        'fiber': fib,
        'totalGrams': grams,
        'caloriesPer100g': cPer100,
        'proteinPer100g': pPer100,
        'fatPer100g': fPer100,
        'carbsPer100g': cbPer100,
      }, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    debugPrint('✅ Batch-пересчёт блюд: ${allTemplates.length}');
  }

  Future<void> refreshTemplatesForProduct(String productId) async {
    final db = await database;
    final templates = await db.query('meal_templates', columns: ['id', 'items']);
    for (final template in templates) {
      dynamic decoded;
      try {
        decoded = jsonDecode(template['items'] as String? ?? '[]');
      } catch (_) {
        continue;
      }
      if (decoded is! List) continue;
      if (decoded.any((item) => item is Map && item['productId'] == productId)) {
        await _recalculateTemplateNutrition(db, template['id'] as String);
      }
    }
  }

  // ==========================================================================
  // INDEXES & DEFAULTS
  // ==========================================================================
  Future<void> _createIndexes(DatabaseExecutor db) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON food_products(category)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_custom ON food_products(isCustom)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_favorite ON food_products(isFavorite)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_diary_date ON food_diary(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_diary_product ON food_diary(productId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_diary_template ON food_diary(templateId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_water_date ON water_entries(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_templates_name_norm ON meal_templates(nameNormalized)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name_norm ON food_products(nameNormalized)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_templates_favorite ON meal_templates(isFavorite)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cook_logs_template ON recipe_cook_logs(templateId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cook_logs_date ON recipe_cook_logs(cookedAt)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_price_product ON price_history(productId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_product ON pantry_items(productId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_expires ON pantry_items(expiresAt)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plan_days_date ON plan_days(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plan_meals_day ON plan_meals(dayId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_shopping_bought ON shopping_items(isBought)');
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_products_unique_name_norm ON food_products(nameNormalized)');
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_templates_unique_name_norm ON meal_templates(nameNormalized)');

      // 🆕 Индексы для новых таблиц
      await db.execute('CREATE INDEX IF NOT EXISTS idx_barcode_cache_code ON barcode_cache(barcode)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_scan_history_date ON barcode_scan_history(scannedAt DESC)');

      // 🆕 Индексы для v11
      await db.execute('CREATE INDEX IF NOT EXISTS idx_programs_active ON nutrition_programs(isActive)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plan_days_program ON plan_days(programId)');
    } catch (e) {
      debugPrint('⚠️ Ошибка создания индексов: $e');
    }
  }

  Future<void> _seedDefaultGoals(DatabaseExecutor db) async {
    final count = await db.rawQuery('SELECT COUNT(*) AS count FROM nutrition_goals');
    // 🆕 ДОБАВЛЕНЫ СКОБКИ: (( ... ?? 0) > 0)
    if (((count.first['count'] as num?)?.toInt() ?? 0) > 0) return;
    await db.insert('nutrition_goals', {
      'id': const Uuid().v4(),
      'date': null,
      'calories': 2200.0,
      'protein': 140.0,
      'fat': 70.0,
      'carbs': 250.0,
      'waterMl': 2500,
      'isActive': 1,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // ==========================================================================
  // CRUD OPERATIONS
  // ==========================================================================
  Future<String> insertOrGetExisting(String table, Map<String, dynamic> data) async {
    final db = await database;
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('nameNormalized') && payload.containsKey('name')) {
      payload['nameNormalized'] = _normalizeName(payload['name'] as String);
    }
    final conflictAlgo = (table == 'food_products' || table == 'meal_templates')
        ? ConflictAlgorithm.ignore
        : ConflictAlgorithm.replace;
    final result = await db.insert(table, payload, conflictAlgorithm: conflictAlgo);
    String finalId = payload['id'] as String;
    if (result == 0 && (table == 'food_products' || table == 'meal_templates')) {
      final existing = await db.query(table, columns: ['id'],
          where: 'nameNormalized = ?', whereArgs: [payload['nameNormalized']], limit: 1);
      if (existing.isNotEmpty) finalId = existing.first['id'] as String;
    }
    if (table == 'food_products' && result != 0) {
      final isCustom = (payload['isCustom'] as num?)?.toInt() ?? 0;
      if (isCustom == 0) await refreshTemplatesForProduct(finalId);
    }
    if (table == 'meal_templates' && result != 0) await _recalculateTemplateNutrition(db, finalId);
    return finalId;
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<Object?>? whereArgs, String? orderBy, int? limit}) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }

  Future<int> update(String table, Map<String, dynamic> values,
      {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    final payload = Map<String, dynamic>.from(values);
    if (!payload.containsKey('nameNormalized') && payload.containsKey('name')) {
      payload['nameNormalized'] = _normalizeName(payload['name'] as String? ?? '');
    }
    final result = await db.update(table, payload, where: where, whereArgs: whereArgs);
    if (table == 'food_products' && result > 0 && where == 'id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      if (id is String && id.isNotEmpty) await refreshTemplatesForProduct(id);
    }
    if (table == 'meal_templates' && result > 0 && where == 'id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      if (id is String && id.isNotEmpty) await _recalculateTemplateNutrition(db, id);
    }
    return result;
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}