import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Локальная SQLite-база питания.
///
/// Правила v7 (устойчивые):
/// - все КБЖУ продуктов хранятся на 100 г;
/// - КБЖУ готового блюда — сумма ингредиентов;
/// - дедупликация продуктов и блюд по `nameNormalized`
///   (trim + collapse spaces + lowercase);
/// - UNIQUE-индексы на `nameNormalized` — на них опираются INSERT OR IGNORE;
/// - при изменении продукта пересчитываются зависимые блюда;
/// - миграция 6 → 7 не требует удаления существующей БД.
///
/// Числа в каталоге — справочные средние значения.
/// Для конкретного бренда лучше использовать этикетку.
class NutritionDatabase {
  static final NutritionDatabase _instance = NutritionDatabase._internal();

  static Database? _database;

  NutritionDatabase._internal();

  factory NutritionDatabase() => _instance;

  static const int currentVersion = 7;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
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
        // Защита от случая, когда индексы не успели создаться
        // из-за падения предыдущей миграции.
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
      if (_database != null && _database!.isOpen) {
        await _database!.close();
      }
      _database = null;

      final dbFile = File(dbPath);
      if (await dbFile.exists()) await dbFile.delete();

      final walFile = File('$dbPath-wal');
      if (await walFile.exists()) await walFile.delete();

      final shmFile = File('$dbPath-shm');
      if (await shmFile.exists()) await shmFile.delete();

      debugPrint('✅ Все файлы БД питания очищены');
    } catch (e) {
      debugPrint('⚠️ Ошибка удаления БД питания: $e');
    }
  }

  // ==========================================================================
  // SCHEMA
  // ==========================================================================

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('📦 Создание БД питания версии $version');

    await db.transaction((txn) async {
      await _createSchema(txn);
      await _createIndexes(txn);

      await _insertV7Products(txn);
      await _insertV7Templates(txn);

      await _recalculateAllTemplateNutrition(txn);
      await _seedDefaultGoals(txn);
    });

    debugPrint('✅ БД питания v7 создана');
  }

  Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_products (
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
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_diary (
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
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        nameNormalized TEXT,
        items TEXT DEFAULT '[]',
        calories REAL DEFAULT 0,
        protein REAL DEFAULT 0,
        fat REAL DEFAULT 0,
        carbs REAL DEFAULT 0,
        fiber REAL DEFAULT 0,
        totalGrams REAL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS nutrition_goals (
        id TEXT PRIMARY KEY,
        date TEXT,
        calories REAL DEFAULT 0,
        protein REAL DEFAULT 0,
        fat REAL DEFAULT 0,
        carbs REAL DEFAULT 0,
        waterMl INTEGER DEFAULT 2000,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS water_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        amountMl INTEGER NOT NULL,
        time TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
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
      )
    ''');

    // Миграционные доработки колонок на случай старых БД.
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
  }

  Future<void> _addColumnIfMissing(
      DatabaseExecutor db,
      String table,
      String column,
      String definition,
      ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);

    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
      debugPrint('✅ Добавлена колонка $table.$column');
    }
  }

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    debugPrint('🔄 Миграция БД питания: $oldVersion → $newVersion');

    await db.transaction((txn) async {
      // 1. Схема (IF NOT EXISTS + add columns).
      await _createSchema(txn);

      // 2. Заполняем nameNormalized для всех строк, где его нет.
      await _backfillNormalizedNames(txn);

      // 3. Дедупликация до создания UNIQUE-индексов.
      if (oldVersion < 7) {
        await _cleanupDuplicateProductsV7(txn);
        await _cleanupDuplicateTemplatesV7(txn);
      }

      // 4. Все индексы (UNIQUE на nameNormalized в том числе).
      await _createIndexes(txn);

      // 5. Добиваем новым каталогом (INSERT OR IGNORE).
      if (oldVersion < 7) {
        await _insertV7Products(txn);
        await _insertV7Templates(txn);
        await _recalculateAllTemplateNutrition(txn);
      }

      await _seedDefaultGoals(txn);
    });

    final productCount = await _countUniqueNames(db, 'food_products');
    final templateCount = await _countUniqueNames(db, 'meal_templates');

    debugPrint('📊 v7: уникальных продуктов = $productCount');
    debugPrint('🍽️ v7: уникальных блюд = $templateCount');

    debugPrint('✅ ===== МИГРАЦИЯ v7 ЗАВЕРШЕНА =====');
  }

  Future<int> _countUniqueNames(DatabaseExecutor db, String table) async {
    final rows = await db.rawQuery('''
      SELECT COUNT(DISTINCT nameNormalized) AS count
      FROM $table
      WHERE nameNormalized IS NOT NULL
        AND TRIM(nameNormalized) <> ''
    ''');
    return (rows.first['count'] as num?)?.toInt() ?? 0;
  }

  // ==========================================================================
  // NORMALIZATION
  // ==========================================================================

  /// Нормализованное имя: trim + collapse spaces + lowercase.
  /// Используется как ключ уникальности и для поиска.
  String _normalizeName(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // ← важно: r'\s+', не r'\\s+'
        .toLowerCase();
  }

  Future<void> _backfillNormalizedNames(DatabaseExecutor db) async {
    await _backfillTable(db, 'food_products');
    await _backfillTable(db, 'meal_templates');
  }

  Future<void> _backfillTable(
      DatabaseExecutor db,
      String table,
      ) async {
    final rows = await db.query(
      table,
      columns: ['id', 'name', 'nameNormalized'],
    );

    for (final row in rows) {
      final current = row['nameNormalized'] as String?;
      if (current != null && current.isNotEmpty) continue;

      final normalized = _normalizeName(row['name'] as String? ?? '');
      await db.update(
        table,
        {'nameNormalized': normalized},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  // ==========================================================================
  // DUPLICATES
  // ==========================================================================

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

        final ad = a['createdAt'] as String? ?? '';
        final bd = b['createdAt'] as String? ?? '';
        return ad.compareTo(bd);
      });

      final canonical = group.first;
      final canonicalId = canonical['id'] as String;

      final favorite = group.any(
            (row) => ((row['isFavorite'] as num?)?.toInt() ?? 0) == 1,
      );

      if (favorite) {
        await db.update(
          'food_products',
          {'isFavorite': 1},
          where: 'id = ?',
          whereArgs: [canonicalId],
        );
      }

      for (final duplicate in group.skip(1)) {
        final duplicateId = duplicate['id'] as String;

        await db.update(
          'food_diary',
          {'productId': canonicalId},
          where: 'productId = ?',
          whereArgs: [duplicateId],
        );

        await _replaceProductIdInAllTemplates(
          db,
          duplicateId,
          canonicalId,
          canonical['name'] as String,
        );

        await db.delete(
          'food_products',
          where: 'id = ?',
          whereArgs: [duplicateId],
        );

        deleted++;
      }
    }

    debugPrint('🧹 v7: удалено дублей продуктов: $deleted');
  }

  Future<void> _replaceProductIdInAllTemplates(
      DatabaseExecutor db,
      String oldProductId,
      String newProductId,
      String canonicalName,
      ) async {
    final templates = await db.query('meal_templates');

    for (final template in templates) {
      final raw = template['items'] as String? ?? '[]';

      dynamic decoded;
      try {
        decoded = jsonDecode(raw);
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
        await db.update(
          'meal_templates',
          {'items': jsonEncode(updatedItems)},
          where: 'id = ?',
          whereArgs: [template['id']],
        );
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

      group.sort((a, b) {
        final ac = _templateItemCount(a['items']);
        final bc = _templateItemCount(b['items']);
        return bc.compareTo(ac);
      });

      final canonical = group.first;
      final canonicalId = canonical['id'] as String;
      final canonicalName = canonical['name'] as String;

      for (final duplicate in group.skip(1)) {
        final duplicateId = duplicate['id'] as String;

        await db.update(
          'food_diary',
          {
            'templateId': canonicalId,
            'templateName': canonicalName,
          },
          where: 'templateId = ?',
          whereArgs: [duplicateId],
        );

        await db.delete(
          'meal_templates',
          where: 'id = ?',
          whereArgs: [duplicateId],
        );

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
  // PRODUCTS
  // ==========================================================================

  Future<void> _insertV7Products(DatabaseExecutor db) async {
    const rawProducts = r'''
Куриная грудка|meat|165|31|3.6|0|0
Куриное бедро|meat|209|26|10.9|0|0
Куриное крыло|meat|222|24|12|0|0
Куриная печень|meat|136|19|6|0|0
Куриные сердечки|meat|158|16|10|0|0
Говядина|meat|250|26|15|0|0
Говяжья печень|meat|127|20|3|4|0
Говяжий язык|meat|250|14|19|0|0
Свинина|meat|242|27|14|0|0
Свиная печень|meat|109|19|4|2|0
Индейка|meat|189|29|7|0|0
Кролик|meat|156|21|8|0|0
Баранина|meat|294|25|21|0|0
Утка|meat|337|19|28|0|0
Сосиски|meat|277|11|23|3.7|0
Колбаса варёная|meat|260|12|22|2|0
Бекон|meat|541|37|42|1.4|0
Ветчина|meat|145|18|7|1.5|0
Курица копчёная|meat|184|27|8|0|0
Фарш говяжий|meat|241|17|19|0|0
Фарш куриный|meat|143|17|8|0|0
Котлеты домашние|meat|215|17|15|2|0
Стейк говяжий|meat|271|26|18|0|0
Индейка копчёная|meat|189|29|7|0|0
Гусь|meat|371|15|33|0|0
Перепел|meat|192|21|11|0|0
Свиной язык|meat|228|16|17|0|0
Свиные уши|meat|330|22|26|0|0
Свиные ножки|meat|275|20|21|0|0
Бастурма|meat|215|28|10|0|0
Суджук|meat|280|22|20|3|0
Салями|meat|350|22|28|2|0
Балык|meat|194|24|10|0|0
Карбонад|meat|210|25|12|0|0
Шейка свиная|meat|290|17|24|0|0
Лопатка свиная|meat|270|20|20|0|0
Окорок свиной|meat|260|21|18|0|0
Грудинка свиная|meat|420|14|40|0|0
Рёбрышки свиные|meat|320|18|27|0|0
Вырезка телячья|meat|110|21|2.5|0|0
Телятина|meat|130|20|5|0|0
Конина|meat|143|20|7|0|0
Оленина|meat|120|22|3.5|0|0
Мясо страуса|meat|130|22|4|0|0
Фарш свиной|meat|263|16|21|0|0
Фарш индюшиный|meat|165|18|10|0|0
Фарш смешанный|meat|235|17|18|0|0
Колбаса докторская|meat|257|13|22|1.5|0
Колбаса любительская|meat|301|12|27|1.5|0
Колбаса молочная|meat|252|11|22|2|0
Колбаса сервелат|meat|360|15|32|2|0
Колбаса краковская|meat|310|13|28|1.5|0
Сосиски молочные|meat|261|10|23|4|0
Сардельки|meat|250|11|22|3|0
Шпикачки|meat|300|9|28|2|0
Ветчина из индейки|meat|120|16|5|1.5|0
Ветчина варёная|meat|145|18|7|1.5|0
Ветчина копчёная|meat|170|16|11|1|0
Куриная грудка без кожи сырая|meat|120|22.5|2.6|0|0
Куриная грудка варёная|meat|151|29|3.2|0|0
Куриная грудка запечённая|meat|165|31|3.6|0|0
Куриное бедро без кожи|meat|177|24|8|0|0
Филе индейки сырое|meat|114|23.7|1.5|0|0
Филе индейки запечённое|meat|147|30|2.1|0|0
Говядина постная|meat|217|26|12|0|0
Говяжья вырезка|meat|190|27|9|0|0
Ростбиф|meat|174|26|6.5|0|0
Свинина вырезка|meat|143|21.4|6.3|0|0
Свинина вырезка запечённая|meat|196|28|8|0|0
Баранина постная|meat|206|25|11|0|0
Кролик запечённый|meat|206|29|9|0|0
Лосось|fish|208|20|13|0|0
Горбуша|fish|140|20|6|0|0
Форель|fish|208|20|13|0|0
Тунец|fish|132|28|1|0|0
Треска|fish|82|18|0.7|0|0
Минтай|fish|79|16|1|0|0
Сельдь|fish|217|18|15|0|0
Скумбрия|fish|262|18|21|0|0
Окунь морской|fish|124|18|5|0|0
Дорадо|fish|96|19|1.5|0|0
Судак|fish|84|19|1|0|0
Креветки|fish|99|24|0.3|0.2|0
Кальмар|fish|92|18|2|0|0
Осьминог|fish|82|15|1|0|0
Мидии|fish|77|12|2|0|0
Краб|fish|84|18|1|0|0
Крабовые палочки|fish|73|6|0.5|10|0
Икра красная|fish|252|24|18|0|0
Сёмга|fish|219|20|15|0|0
Сардины|fish|208|24|11|0|0
Палтус|fish|186|19|12|0|0
Макрель|fish|262|18|21|0|0
Кижуч|fish|140|21|6|0|0
Нерка|fish|152|20|8|0|0
Чавыча|fish|148|20|7|0|0
Кета|fish|127|19|5.5|0|0
Голец|fish|135|20|6|0|0
Хариус|fish|88|17|2|0|0
Ленок|fish|93|18|2.2|0|0
Таймень|fish|110|19|3.5|0|0
Щука|fish|84|18|1|0|0
Жерех|fish|86|19|0.7|0|0
Лещ|fish|105|17|4|0|0
Карп|fish|112|16|5|0|0
Сазан|fish|97|18|2.5|0|0
Линь|fish|88|18|1.5|0|0
Налим|fish|79|18|0.8|0|0
Пикша|fish|74|17|0.5|0|0
Мерланг|fish|78|18|0.6|0|0
Мойва|fish|118|13|7|0|0
Корюшка|fish|112|15|5.5|0|0
Ряпушка|fish|74|16|0.9|0|0
Снеток|fish|82|18|1|0|0
Тунец консервированный|fish|128|28|1.5|0|0
Сардины консервированные|fish|208|24|11|0|0
Шпроты|fish|362|17|32|0|0
Килька|fish|137|15|8|0|0
Анчоусы|fish|210|20|14|0|0
Угорь|fish|262|18|21|0|0
Морской язык|fish|91|18|1.8|0|0
Морской окунь|fish|103|18|3|0|0
Зубатка|fish|126|18|6|0|0
Луфарь|fish|116|20|3.5|0|0
Барабулька|fish|117|19|4|0|0
Кефаль|fish|117|19|4|0|0
Пеламида|fish|158|20|8|0|0
Ставрида|fish|114|19|4|0|0
Сайра|fish|213|18|15|0|0
Треска запечённая|fish|105|23|0.9|0|0
Минтай запечённый|fish|101|21|1.3|0|0
Хек|fish|86|18.5|1.5|0|0
Хек запечённый|fish|108|23|1.8|0|0
Форель запечённая|fish|190|26|9|0|0
Лосось запечённый|fish|206|22|12|0|0
Тунец консервированный в воде|fish|116|26|1|0|0
Креветки варёные|fish|99|24|0.3|0.2|0
Кальмар варёный|fish|92|15.6|1.4|3|0
Мидии варёные|fish|172|24|4.5|7|0
Морские гребешки|fish|111|20.5|0.8|5.4|0
Устрицы|fish|68|7|2.5|4.2|0
Осьминог варёный|fish|164|29.8|2.1|4.4|0
Копчёная скумбрия|fish|305|18|25|0|0
Яйцо куриное|dairy|155|13|11|1.1|0
Яйцо перепелиное|dairy|168|12|11|0.5|0
Яйцо куриное C0|dairy|155|13|11|1.1|0
Яйцо куриное C1|dairy|150|12.5|10.5|1|0
Яйцо куриное C2|dairy|145|12|10|0.9|0
Яйцо куриное C3|dairy|140|11.5|9.5|0.8|0
Творог 5%|dairy|121|17|5|1.8|0
Творог обезжиренный|dairy|71|18|0.6|1.8|0
Творог 9%|dairy|156|18|9|2|0
Молоко 2.5%|dairy|52|2.8|2.5|4.7|0
Молоко 3.2%|dairy|60|3|3.2|4.7|0
Молоко обезжиренное|dairy|35|3.2|0.1|5|0
Кефир 1%|dairy|40|3|1|4|0
Кефир 2.5%|dairy|50|2.9|2.5|4|0
Ряженка|dairy|67|2.8|4|4.2|0
Йогурт натуральный|dairy|60|4|3.2|3.5|0
Йогурт греческий|dairy|59|8|0.4|3.6|0
Сметана 15%|dairy|115|2.6|15|3|0
Сметана 20%|dairy|206|2.5|20|3.4|0
Сыр твёрдый|dairy|350|25|27|2|0
Сыр моцарелла|dairy|280|28|17|2.2|0
Сыр пармезан|dairy|392|33|28|3|0
Сыр адыгейский|dairy|240|19|14|0|0
Сыр фета|dairy|264|14|21|4|0
Сыр плавленый|dairy|257|21|23|2|0
Сливки 10%|dairy|118|2.8|10|4|0
Сливки 20%|dairy|206|2.5|20|3.4|0
Сливки 30%|dairy|296|2.2|30|3.4|0
Сливки 35%|dairy|345|2.1|35|3.4|0
Молоко топлёное|dairy|84|3|4|4.7|0
Молоко козье|dairy|68|3.3|4.2|4.5|0
Молоко овечье|dairy|108|5.5|7|5|0
Кумыс|dairy|50|2.1|1.9|5|0
Айран|dairy|25|1.5|0.5|4|0
Тан|dairy|30|1.5|0.5|5|0
Снежок|dairy|80|3|3|10|0
Варенец|dairy|53|2.9|2.5|4.2|0
Простокваша|dairy|52|2.9|2.5|4.2|0
Масло сливочное 82.5%|dairy|748|0.8|82.5|0.8|0
Масло топлёное|dairy|876|0.3|99|0|0
Сыр рикотта|dairy|174|11|13|3|0
Сыр маскарпоне|dairy|429|4|43|2.5|0
Сыр гауда|dairy|356|25|27|2|0
Сыр эдам|dairy|330|25|24|2|0
Сыр горгонзола|dairy|353|21|29|1.5|0
Сыр дор блю|dairy|353|21|29|1.5|0
Сыр рокфор|dairy|369|22|30|1.5|0
Сыр камамбер|dairy|300|20|24|1.5|0
Сыр бри|dairy|334|21|27|1.5|0
Сыр сулугуни|dairy|285|20|22|1|0
Сыр чечил|dairy|290|19|23|1|0
Сыр косичка|dairy|295|19|23|1|0
Сыр халуми|dairy|310|22|24|2|0
Творожный сыр|dairy|120|8|9|3|0
Плавленый сыр 50%|dairy|257|21|23|2|0
Плавленый сыр 30%|dairy|190|15|12|8|0
Сметана 10%|dairy|115|2.6|10|3|0
Сметана 25%|dairy|247|2.4|25|3.4|0
Сметана 30%|dairy|296|2.3|30|3.4|0
Сметана 40%|dairy|395|2.2|40|3.4|0
Йогурт питьевой|dairy|75|3|2.5|10|0
Йогурт с наполнителем|dairy|85|3|2.8|12|0
Йогурт домашний|dairy|62|4.5|3.2|3.5|0
Яичный белок|dairy|52|10.9|0.2|0.7|0
Яичный желток|dairy|322|15.9|26.5|3.6|0
Яйцо варёное|dairy|155|12.6|10.6|1.1|0
Творог 2%|dairy|103|18|2|3|0
Творог 4%|dairy|120|17|4|2.5|0
Йогурт греческий 2%|dairy|73|9.9|2|3.9|0
Йогурт греческий 5%|dairy|97|9|5|3.8|0
Молоко 1.5%|dairy|44|3|1.5|4.8|0
Молоко 3.5%|dairy|62|3|3.5|4.7|0
Кефир 0%|dairy|35|3|0.1|4|0
Кефир 1.5%|dairy|41|3|1.5|4|0
Ряженка 2.5%|dairy|54|2.9|2.5|4.2|0
Ряженка 3.2%|dairy|58|2.9|3.2|4.2|0
Овсянка|grains|366|12|6|60|10
Гречка сухая|grains|343|13|3.4|72|10
Гречка варёная|grains|92|3.4|0.6|20|2.7
Рис белый сухой|grains|344|6.7|0.7|78|1
Рис белый варёный|grains|130|2.7|0.3|28|0.4
Рис бурый варёный|grains|111|2.6|0.9|23|1.8
Макароны варёные|grains|131|5|1.1|25|1.8
Макароны сухие|grains|344|12|1.5|70|3
Хлеб цельнозерновой|grains|247|13|3.4|41|7
Хлеб белый|grains|265|9|3.2|49|2.7
Хлеб бородинский|grains|208|6.9|1.2|41|8
Киноа варёная|grains|120|4.4|1.9|21|2.8
Булгур варёный|grains|83|3.1|0.2|18|4.5
Кус-кус варёный|grains|112|3.8|0.2|23|1.4
Перловка варёная|grains|109|3.1|0.4|23|3
Пшено варёное|grains|90|3.5|1|21|1.5
Хлебцы ржаные|grains|310|11|2.7|63|16
Овсяные хлопья|grains|363|12|6|60|10
Мюсли|grains|325|10|5|60|8
Гранола|grains|471|10|20|60|7
Хлебцы рисовые|grains|387|8|1|80|2
Манка|grains|338|10|1|73|3
Каша рисовая на молоке|grains|97|3.2|2.7|16|0.3
Манная каша|grains|98|3|3.2|15|0.5
Каша овсяная на молоке|grains|105|4|4|15|2
Полба варёная|grains|127|5.5|0.8|26|3.5
Спельта варёная|grains|132|5|0.9|27|4
Амарант варёный|grains|102|3.8|1.6|19|2.1
Тефф варёный|grains|101|3.9|0.7|20|2
Сорго варёный|grains|116|3.3|1.2|24|2.5
Ячмень варёный|grains|123|2.3|0.4|28|3.5
Овсяные отруби|grains|246|17|7|66|15
Пшеничные отруби|grains|216|16|4.3|64|42
Рисовая мука|grains|366|6|1.4|80|2.4
Кукурузная мука|grains|364|7|3.9|76|7.3
Гречневая мука|grains|343|13|3.4|72|10
Овсяная мука|grains|404|14|9|68|8
Нутовая мука|grains|387|22|6.7|58|10
Чечевичная мука|grains|353|25|1.1|63|8
Киноа мука|grains|374|14|6|64|7
Кус-кус сухой|grains|376|13|0.6|77|5
Булгур сухой|grains|342|12|1.3|70|18
Макароны цельнозерновые|grains|124|5.3|1.4|24|3.8
Спагетти варёные|grains|158|5.8|0.9|31|1.8
Лапша рисовая варёная|grains|109|1.6|0.2|25|0.8
Лапша гречневая варёная|grains|99|3.8|0.3|21|1.3
Хлеб ржаной|grains|210|6.5|1.2|42|6.5
Хлеб с отрубями|grains|220|11|3.5|38|8
Хлеб безглютеновый|grains|230|4|3|45|4
Хлеб кукурузный|grains|265|6|3|55|5
Хлеб картофельный|grains|248|5|2|52|3
Лаваш тонкий|grains|220|7.5|1|45|2
Тортилья кукурузная|grains|218|5.7|2.8|44|6
Тортилья пшеничная|grains|300|8|7|50|4
Крекеры|grains|450|10|15|70|3
Хлебцы гречневые|grains|310|12|3|62|14
Хлебцы пшеничные|grains|320|11|2|68|8
Рис жасмин сухой|grains|356|7.1|0.7|79|1.3
Рис жасмин варёный|grains|129|2.7|0.3|28|0.4
Рис басмати сухой|grains|365|7.1|0.7|78|1.3
Рис басмати варёный|grains|130|2.7|0.3|28|0.4
Рис красный сухой|grains|356|7.5|2.7|74|4.1
Рис красный варёный|grains|111|2.3|0.8|23|1.8
Рис чёрный сухой|grains|356|8.5|3.3|75|4.7
Рис чёрный варёный|grains|145|4|1|30|1.8
Пшено сухое|grains|378|11|4.2|72|8.5
Киноа сухая|grains|368|14.1|6.1|64.2|7
Амарант сухой|grains|371|13.6|7|65|6.7
Тефф сухой|grains|367|13.3|2.4|73|8
Сорго сухое|grains|329|10.6|3.5|72|6.7
Полента готовая|grains|70|1.6|0.8|14.7|1.5
Кукурузная крупа сухая|grains|362|8.1|3.6|76.9|7.3
Гречневые хлопья|grains|343|13|3.4|72|10
Ржаные хлопья|grains|335|9.5|2|69|15
Пшеничные хлопья|grains|352|11|2|70|10
Лапша удон варёная|grains|127|3|0.2|27|1
Лапша соба сухая|grains|336|14|1|70|5.1
Лапша соба варёная|grains|99|5|0.1|21|2
Фунчоза готовая|grains|109|0.2|0.1|27|0
Рисовая лапша сухая|grains|364|5.9|0.6|80|1.6
Макароны из твёрдых сортов сухие|grains|350|13|1.5|70|4
Макароны из твёрдых сортов варёные|grains|157|5.8|0.9|30|2.8
Спагетти цельнозерновые сухие|grains|348|14.6|2.5|66|9
Спагетти цельнозерновые варёные|grains|149|6.3|1.5|27|4.5
Паста из чечевицы сухая|grains|345|25|2|57|10
Паста из нута сухая|grains|365|21|6|58|10
Огурец|vegetables|15|0.8|0.1|3.6|0.5
Помидор|vegetables|18|0.9|0.2|3.9|1.2
Морковь|vegetables|41|0.9|0.2|10|2.8
Брокколи|vegetables|34|2.8|0.4|7|2.6
Шпинат|vegetables|23|2.9|0.4|3.6|2.2
Картофель варёный|vegetables|87|2|0.4|17|1.8
Картофель жареный|vegetables|192|2.5|9.5|23|2
Батат|vegetables|86|1.6|0.1|20|3
Перец болгарский|vegetables|31|1|0.3|6|2.1
Лук репчатый|vegetables|40|1.1|0.1|9|1.7
Капуста белокочанная|vegetables|25|1.3|0.1|6|2.5
Капуста цветная|vegetables|25|1.9|0.3|5|2
Кабачок|vegetables|17|1.2|0.3|3.1|1
Баклажан|vegetables|25|1|0.2|6|3
Свёкла|vegetables|43|1.6|0.2|10|2.8
Редис|vegetables|16|0.7|0.1|3.4|1.6
Сельдерей|vegetables|16|0.9|0.2|3|1.6
Фасоль стручковая|vegetables|31|1.8|0.1|7|2.5
Кукуруза|vegetables|86|3.2|1.2|19|2.4
Тыква|vegetables|26|1|0.1|6.5|0.5
Шампиньоны|vegetables|27|4.3|1|0.1|1
Грибы белые|vegetables|22|3.1|0.3|3.3|1
Огурцы солёные|vegetables|11|0.3|0.1|2|1
Капуста квашеная|vegetables|19|1.6|0.1|4.3|2.5
Оливки|vegetables|115|0.8|10.7|6|3.2
Салат листовой|vegetables|15|1.4|0.2|2.9|1.5
Руккола|vegetables|25|2.6|0.7|3.7|1.6
Укроп|vegetables|43|3.5|1.1|7|2.1
Петрушка|vegetables|47|3.7|0.8|7.6|3.3
Базилик|vegetables|23|3.2|0.6|2.7|1.6
Чеснок|vegetables|149|6.4|0.5|33|2.1
Имбирь|vegetables|80|1.8|0.8|18|2
Спаржа|vegetables|20|2.2|0.1|3.9|2.1
Артишок|vegetables|47|3.3|0.2|11|5.4
Топинамбур|vegetables|73|2|0.1|17|1.6
Пастернак|vegetables|75|1.2|0.3|18|4.9
Корень сельдерея|vegetables|42|1.5|0.3|9.2|3.1
Петрушка корневая|vegetables|47|3.7|0.8|7.6|3.3
Хрен|vegetables|48|2.4|0.4|11|3.2
Редька|vegetables|21|1.2|0.1|4.1|1.6
Репа|vegetables|28|0.9|0.1|6|1.8
Брюква|vegetables|38|1.2|0.1|8|2.3
Свекла листовая|vegetables|19|2.2|0.2|3.7|1.5
Мангольд|vegetables|19|1.8|0.2|3.7|1.6
Крапива|vegetables|42|3.5|0.5|7|6.5
Щавель|vegetables|22|1.5|0.3|2.9|2.9
Шпинат молодой|vegetables|23|2.9|0.4|3.6|2.2
Рукола молодая|vegetables|25|2.6|0.7|3.7|1.6
Кресс-салат|vegetables|32|2.6|0.7|5.5|1.1
Латук|vegetables|15|1.4|0.2|2.9|1.5
Радиччио|vegetables|23|1.4|0.2|4.5|0.9
Эндивий|vegetables|17|1.3|0.2|3.4|3.1
Фенхель|vegetables|31|1.2|0.2|7|3.1
Лук-порей|vegetables|36|1.5|0.3|8|1.8
Лук-шалот|vegetables|72|2.5|0.1|17|3.2
Лук зелёный|vegetables|32|1.3|0.1|6.5|1.8
Чеснок молодой|vegetables|149|6.4|0.5|33|2.1
Горошек зелёный|vegetables|81|5.4|0.4|14|5.7
Кукуруза сахарная|vegetables|86|3.2|1.2|19|2.4
Перец чили|vegetables|40|1.8|0.4|8.8|1.5
Перец сладкий красный|vegetables|31|1|0.3|6|2.1
Перец сладкий жёлтый|vegetables|27|1|0.2|6.3|1.8
Перец сладкий зелёный|vegetables|20|0.9|0.2|4.6|1.7
Тыква мускатная|vegetables|45|1|0.1|12|2
Тыква обыкновенная|vegetables|26|1|0.1|6.5|0.5
Патиссон|vegetables|19|0.6|0.1|4.3|0.9
Огурец корнишон|vegetables|15|0.8|0.1|3.6|0.5
Огурец парниковый|vegetables|14|0.7|0.1|2.8|0.7
Помидоры черри|vegetables|18|0.9|0.2|3.9|1.2
Помидоры жёлтые|vegetables|15|0.9|0.2|3|1.2
Томаты вяленые|vegetables|258|4|2|56|8
Картофель молодой|vegetables|77|2|0.4|16|1.8
Картофель красный|vegetables|87|2|0.4|17|1.8
Батат оранжевый|vegetables|86|1.6|0.1|20|3
Батат фиолетовый|vegetables|90|1.7|0.1|21|3.2
Картофель запечённый|vegetables|93|2.5|0.1|21|2.2
Картофельное пюре|vegetables|113|2.3|4|17|1.5
Брокколи варёная|vegetables|35|2.4|0.4|7.2|3.3
Цветная капуста варёная|vegetables|23|1.8|0.5|4.1|2.3
Морковь варёная|vegetables|35|0.8|0.2|8.2|3
Свёкла варёная|vegetables|44|1.7|0.2|10|2
Краснокочанная капуста|vegetables|31|1.4|0.2|7.4|2.1
Брюссельская капуста|vegetables|43|3.4|0.3|9|3.8
Капуста пекинская|vegetables|16|1.2|0.2|3.2|1.2
Кольраби|vegetables|27|1.7|0.1|6.2|3.6
Грибы шиитаке|vegetables|34|2.2|0.5|6.8|2.5
Вешенки|vegetables|33|3.3|0.4|6.1|2.3
Лисички|vegetables|32|1.5|0.5|6.9|3.8
Тыква хоккайдо|vegetables|34|1|0.1|8|1.5
Кабачок гриль|vegetables|24|1.2|0.4|4|1.1
Кабачок запечённый|vegetables|24|1.2|0.3|4.5|1.2
Баклажан запечённый|vegetables|35|1|0.2|8|3
Перец печёный|vegetables|35|1.1|0.4|7|2
Брокколи замороженная|vegetables|34|2.8|0.4|7|3.3
Цветная капуста замороженная|vegetables|25|2|0.3|5|2
Шпинат замороженный|vegetables|29|3|0.5|4|2.5
Стручковая фасоль замороженная|vegetables|31|1.8|0.1|7|3.4
Кукуруза замороженная|vegetables|86|3.2|1.2|19|2.7
Яблоко|fruits|52|0.3|0.2|14|2.4
Банан|fruits|89|1.1|0.3|23|2.6
Апельсин|fruits|47|0.9|0.1|12|2.4
Клубника|fruits|32|0.7|0.3|7.7|2
Черника|fruits|57|0.7|0.3|14|2.4
Виноград|fruits|69|0.7|0.2|18|0.9
Авокадо|fruits|160|2|15|9|7
Манго|fruits|60|0.8|0.4|15|1.6
Груша|fruits|57|0.4|0.1|15|3.1
Персик|fruits|39|0.9|0.3|10|1.5
Ананас|fruits|50|0.5|0.1|13|1.4
Киви|fruits|61|1.1|0.5|15|3
Грейпфрут|fruits|42|0.8|0.1|11|2
Арбуз|fruits|30|0.6|0.2|7.6|0.4
Дыня|fruits|34|0.6|0.2|8.2|0.9
Вишня|fruits|50|1.1|0.3|12|1.6
Черешня|fruits|63|1.1|0.4|16|1.4
Слива|fruits|46|0.7|0.3|11.4|1.4
Абрикос|fruits|48|1.4|0.4|11|2
Гранат|fruits|83|1.7|1.2|19|4
Лимон|fruits|29|1.1|0.3|9|2.8
Малина|fruits|52|1.2|0.7|12|6.5
Смородина|fruits|63|1.4|0.4|15|4.3
Сухофрукты|fruits|286|3.4|0.5|70|8
Финики|fruits|282|2.5|0.4|75|7
Изюм|fruits|299|3.1|0.5|79|3.7
Папайя|fruits|43|0.5|0.3|11|1.7
Гуава|fruits|68|2.6|1|14|5.4
Маракуйя|fruits|97|2.2|0.7|23|10.4
Фейхоа|fruits|49|1|0.6|11|6.4
Хурма|fruits|70|0.6|0.3|18|3.6
Кумкват|fruits|71|1.9|0.9|16|6.5
Лайм|fruits|30|0.7|0.2|11|2.8
Помело|fruits|38|0.8|0.1|10|1
Свити|fruits|43|0.8|0.1|11|1
Угли|fruits|45|0.8|0.1|11|1.2
Мандарин|fruits|53|0.8|0.3|13|1.8
Клементин|fruits|47|0.8|0.2|12|1.7
Рамбутан|fruits|84|0.9|0.4|21|0.9
Личи|fruits|66|0.8|0.4|16|1.3
Лонган|fruits|60|1.3|0.1|15|1.1
Джекфрут|fruits|95|1.7|0.6|23|1.5
Дуриан|fruits|147|1.5|5.3|27|3.8
Мангустин|fruits|73|0.4|0.6|18|0.5
Сахарное яблоко|fruits|94|2.1|0.3|24|4.4
Черимойя|fruits|75|1.6|0.6|18|3.3
Сметанное яблоко|fruits|66|1|0.3|17|3.3
Старфрут|fruits|31|1|0.3|7|2.8
Карамбола|fruits|31|1|0.3|7|2.8
Питахайя|fruits|60|1.2|0.4|13|0.9
Кивано|fruits|44|2|1|7|3
Пепино|fruits|35|1|0.2|8|0.3
Томатильо|fruits|32|1|1|6|1.9
Аки|fruits|151|2|7|20|2
Саподилла|fruits|83|0.4|0.5|20|5.3
Салак|fruits|82|1|0.4|21|3.5
Момордика|fruits|17|1|0.2|3|2
Нектарин|fruits|44|1.1|0.3|10.6|1.7
Инжир свежий|fruits|74|0.8|0.3|19.2|2.9
Голубика|fruits|57|0.7|0.3|14.5|2.4
Ежевика|fruits|43|1.4|0.5|9.6|5.3
Клюква свежая|fruits|46|0.4|0.1|12|4.6
Крыжовник|fruits|44|0.9|0.6|10.2|4.3
Облепиха|fruits|82|1.2|5.4|5.7|3.3
Шелковица|fruits|43|1.4|0.4|9.8|1.7
Брусника|fruits|46|0.7|0.5|8.2|2.5
Финики меджул|fruits|277|1.8|0.2|75|6.7
Банан зелёный|fruits|89|1.1|0.3|23|2.6
Яблоко зелёное|fruits|52|0.3|0.2|14|2.4
Яблоко сладкое|fruits|54|0.3|0.2|14.5|2.4
Груша конференс|fruits|57|0.4|0.1|15|3.1
Апельсин красный|fruits|47|0.9|0.1|12|2.4
Грейпфрут красный|fruits|42|0.8|0.1|11|1.6
Ягоды лесные|fruits|50|1|0.4|11|4
Облепиха замороженная|fruits|82|1.2|5.4|5.7|3.3
Миндаль|nuts|579|21|50|22|12
Грецкий орех|nuts|654|15|65|14|7
Арахис|nuts|567|26|49|16|8
Кешью|nuts|553|18|44|30|3.3
Фисташки|nuts|562|20|45|28|10
Фундук|nuts|628|15|61|17|9.7
Кедровые орехи|nuts|673|14|68|13|3.7
Арахисовая паста|nuts|588|25|50|20|6
Макадамия|nuts|718|8|76|14|9
Пекан|nuts|691|9|72|14|10
Бразильский орех|nuts|659|14|66|12|7.5
Орех кола|nuts|550|8|30|50|10
Орех пили|nuts|720|10|75|10|8
Орех чёрный|nuts|619|24|59|9|6
Орех гикори|nuts|691|9|72|14|10
Буковый орех|nuts|576|21|50|18|5
Каштан сладкий|nuts|213|2.4|2.3|46|3.4
Каштан японский|nuts|200|2.2|2|44|3
Миндаль сладкий|nuts|579|21|50|22|12
Миндаль горький|nuts|579|21|50|22|12
Арахис сырой|nuts|567|26|49|16|8
Арахис жареный|nuts|585|26|52|14|8
Фисташки жареные|nuts|572|20|46|28|10
Кешью жареные|nuts|574|18|46|30|3.3
Грецкий орех зелёный|nuts|340|15|35|12|4
Фундук жареный|nuts|628|15|61|17|9.7
Ореховая паста|nuts|590|15|55|20|6
Урбеч|nuts|590|15|55|20|6
Миндаль бланшированный|nuts|580|21|50|22|12
Миндаль жареный без соли|nuts|597|21|52|22|11.2
Грецкий орех очищенный|nuts|654|15.2|65.2|13.7|6.7
Кешью сырой|nuts|553|18.2|43.9|30.2|3.3
Фисташки несолёные|nuts|560|20.2|45.3|27.2|10.6
Фундук сырой|nuts|628|15|60.8|16.7|9.7
Пекан сырой|nuts|691|9.2|72|13.9|9.6
Макадамия сырая|nuts|718|7.9|75.8|13.8|8.6
Бразильский орех сырой|nuts|659|14.3|67.1|11.7|7.5
Фисташковая паста|nuts|566|20|45|28|10
Миндальная паста|nuts|614|21|56|19|10
Арахисовая паста без сахара|nuts|588|25|50|20|6
Кунжутная паста тахини|nuts|595|17|54|21|9
Кедровый орех жареный|nuts|673|14|68|13|3.7
Фисташки солёные|nuts|569|21|46|28|10
Орехи кешью жареные без соли|nuts|574|18|46|30|3.3
Смесь орехов|nuts|607|18|54|20|8
Ореховая смесь с семенами|nuts|600|19|52|22|9
Семена чиа|seeds|486|17|31|42|34
Семена льна|seeds|534|18|42|29|27
Тыквенные семечки|seeds|559|30|49|11|6
Кунжут|seeds|573|18|49|23|12
Семена подсолнуха|seeds|584|21|50|20|8.6
Семена конопли|seeds|553|25|48|8|28
Семена мака|seeds|525|18|42|28|20
Семена горчицы|seeds|508|26|36|28|12
Семена тмина|seeds|375|17|15|50|38
Семена укропа|seeds|305|15|15|40|30
Семена аниса|seeds|337|18|16|50|35
Семена фенхеля|seeds|345|16|15|52|40
Семена сельдерея|seeds|392|18|25|41|28
Семена тыквы очищенные|seeds|559|30|49|11|6
Семена подсолнечника очищенные|seeds|584|20.8|51.5|20|8.6
Семена льна молотые|seeds|534|18.3|42.2|28.9|27.3
Семена чиа сухие|seeds|486|16.5|30.7|42.1|34.4
Кунжут белый|seeds|573|17.7|49.7|23.4|11.8
Кунжут чёрный|seeds|573|17.7|49.7|23.4|11.8
Семена конопли очищенные|seeds|553|31.6|48.8|8.7|4
Псиллиум|seeds|189|0.6|0.6|88|78
Семена амаранта|seeds|371|13.6|7|65|6.7
Семена льна золотистого|seeds|534|18|42|29|27
Семена укропа молотые|seeds|305|15|15|40|30
Семена фенхеля молотые|seeds|345|16|15|52|40
Фасоль варёная|legumes|123|8.7|0.5|22|7.4
Чечевица варёная|legumes|116|9|0.4|20|7.9
Нут варёный|legumes|164|8.9|2.6|27|7.6
Горох|legumes|81|5.4|0.4|14|5.7
Тофу|legumes|76|8|4.8|1.9|0.3
Соя|legumes|381|36|17|30|9.3
Эдамаме|legumes|122|11|5|9|5.2
Маш|legumes|129|8|0.5|24|5.8
Адзуки|legumes|128|7.5|0.1|25|4.5
Вигна|legumes|132|8|0.3|24|5
Бобы|legumes|109|7|0.5|20|5
Бобы чёрные|legumes|132|9|0.5|23|8.7
Бобы белые|legumes|129|9|0.5|23|6.5
Бобы красные|legumes|127|8.7|0.5|22|6.4
Нут чёрный|legumes|164|8.9|2.6|27|7.6
Фасоль пинто|legumes|114|7|0.5|20|6
Фасоль мунг|legumes|127|7|0.5|23|5.5
Чечевица красная|legumes|116|9|0.4|20|7.9
Чечевица зелёная|legumes|116|9|0.4|20|7.9
Чечевица чёрная|legumes|116|9|0.4|20|7.9
Чечевица французская|legumes|116|9|0.4|20|7.9
Тофу твёрдый|legumes|145|15|8|3.5|1
Тофу мягкий|legumes|76|8|4.8|1.9|0.3
Тофу копчёный|legumes|105|10|6|2.5|0.5
Темпе|legumes|193|19|11|9|6
Натто|legumes|200|17|9|12|8
Эдамаме варёные|legumes|122|11|5|9|5.2
Бобовая паста|legumes|250|12|5|45|10
Фасоль белая консервированная|legumes|114|8|0.5|20|6.3
Фасоль красная консервированная|legumes|99|6.7|0.4|17.7|6.4
Фасоль чёрная консервированная|legumes|91|6.5|0.6|16|6.9
Нут консервированный|legumes|139|7.2|2.4|21|7.4
Чечевица белуга готовая|legumes|116|9|0.4|20|8
Жёлтая чечевица готовая|legumes|118|9|0.4|21|7.5
Горох колотый варёный|legumes|118|8.3|0.4|21|8.3
Сейтан|legumes|141|24|2|12|0.6
Соевые бобы варёные|legumes|173|16.6|9|9.9|6
Соевый фарш сухой|legumes|345|52|1|33|13
Фалафель|legumes|333|13|18|31|7
Хумус|legumes|166|8|10|14|6
Эдамаме очищенные|legumes|121|11.9|5.2|8.9|5.2
Фасоль масляная|legumes|115|7.4|0.5|21|6
Фасоль борлотти|legumes|127|9|0.5|23|8
Фасоль адзуки варёная|legumes|128|7.5|0.1|25|7
Чечевица жёлтая|legumes|116|9|0.4|20|8
Масло оливковое|oils|884|0|100|0|0
Масло подсолнечное|oils|884|0|100|0|0
Масло сливочное|oils|717|0.9|81|0.1|0
Масло кокосовое|oils|862|0|99|0|0
Масло льняное|oils|884|0|100|0|0
Масло авокадо|oils|884|0|100|0|0
Масло рапсовое|oils|884|0|100|0|0
Масло виноградных косточек|oils|884|0|100|0|0
Масло кунжутное|oils|884|0|100|0|0
Масло тыквенных семечек|oils|884|0|100|0|0
Масло грецкого ореха|oils|884|0|100|0|0
Масло кукурузное|oils|884|0|100|0|0
Масло соевое|oils|884|0|100|0|0
Масло арахисовое|oils|884|0|100|0|0
Соевый соус|sauces|53|5|0|8|0
Майонез|sauces|680|1|75|2.6|0
Кетчуп|sauces|112|1.7|0.1|26|0.3
Мустард|sauces|66|4|3|6|0
Паста томатная|sauces|29|1.3|0.1|6|1.1
Песто|sauces|387|5|38|6|1.5
Соус BBQ|sauces|172|1|0.6|41|1
Соус терияки|sauces|141|5|0|28|0.5
Соус сырный|sauces|245|6|22|8|0
Соус песто красный|sauces|200|3|18|8|2
Соус тартар|sauces|390|1|42|2|0
Соус горчичный|sauces|145|4|8|15|2
Соус барбекю сладкий|sauces|215|1|0.5|52|1
Соус карри|sauces|180|2|10|20|3
Соус устричный|sauces|65|3|0.5|13|0.5
Соус рыбовый|sauces|50|4|0.5|8|0
Соус вустерский|sauces|70|2|0|15|0
Соус чили|sauces|70|1|0.5|15|1
Аджика|sauces|60|1.5|0.5|12|2
Ткемали|sauces|70|1|1|15|2
Сацибели|sauces|80|2|3|12|2
Наршараб|sauces|210|0.5|0|55|0.5
Бальзамический уксус|sauces|80|0|0|20|0
Яблочный уксус|sauces|15|0|0|4|0
Винный уксус|sauces|20|0|0|5|0
Рисовый уксус|sauces|20|0|0|5|0
Имбирь маринованный|sauces|20|0.5|0.1|4.5|0.3
Васаби|sauces|55|1.5|0.5|12|2
Хрен столовый|sauces|48|2.4|0.4|11|3.2
Соус йогуртовый|sauces|100|4|6|6|0
Гуакамоле|sauces|150|2|13|8|6
Тахини|sauces|595|17|54|21|9
Соус цезарь|sauces|470|3|48|5|0.5
Соус чесночный|sauces|350|2|34|6|0.5
Соус томатный|sauces|70|2|0.5|13|2
Соус грибной|sauces|120|3|8|8|1
Соус сливочный|sauces|180|3|16|6|0.5
Соус терияки без сахара|sauces|80|5|0|12|0.5
Кофе чёрный|drinks|2|0.3|0|0|0
Кофе латте|drinks|40|2|1.5|4.5|0
Кофе капучино|drinks|35|1.8|1.5|4|0
Чай зелёный|drinks|1|0.2|0|0|0
Чай чёрный|drinks|1|0.2|0|0.3|0
Сок апельсиновый|drinks|45|0.7|0.2|10|0.2
Сок яблочный|drinks|46|0.1|0.1|11|0.2
Кока-кола|drinks|42|0|0|11|0
Протеиновый коктейль|drinks|60|12|1|2|0
Молоко миндальное|drinks|24|0.6|1.1|3|0.4
Какао|drinks|88|3|3.5|12|1
Компот|drinks|60|0.2|0|15|0.3
Вода|drinks|0|0|0|0|0
Квас|drinks|27|0.2|0|6.5|0
Матча|drinks|3|0.6|0|0.5|0.1
Ройбуш|drinks|1|0.1|0|0.1|0
Каркаде|drinks|1|0.1|0|0.1|0
Молочный улун|drinks|1|0.1|0|0.1|0
Пуэр|drinks|1|0.1|0|0.1|0
Сок гранатовый|drinks|60|0.2|0.2|14|0.1
Сок морковный|drinks|40|1|0.1|9|0.3
Сок свекольный|drinks|42|1|0.1|10|0.5
Сок тыквенный|drinks|35|0.5|0.1|8|0.2
Сок томатный|drinks|17|0.9|0.1|3.8|0.4
Сок сельдерея|drinks|16|0.9|0.2|3|1.6
Сок лимона|drinks|29|1.1|0.3|9|2.8
Сок лайма|drinks|30|0.7|0.2|11|2.8
Сок клюквы|drinks|46|0.4|0.1|12|0.5
Морс клюквенный|drinks|30|0.2|0.1|8|0.2
Компот из сухофруктов|drinks|60|0.3|0.1|15|0.5
Кисель|drinks|80|0.5|0|20|0.5
Морс ягодный|drinks|35|0.2|0.1|9|0.2
Шиповник настой|drinks|15|0.3|0|3.5|0.5
Зелёный смузи|drinks|35|1.5|0.5|7|2
Сок виноградный|drinks|60|0.4|0.1|14.7|0.2
Сок ананасовый|drinks|53|0.4|0.1|12.9|0.2
Кокосовая вода|drinks|19|0.7|0.2|3.7|1
Молоко овсяное|drinks|46|1|1.5|6.7|0.8
Молоко соевое|drinks|33|3.3|1.8|0.6|0.4
Эспрессо|drinks|9|0.1|0.2|1.7|0
Американо|drinks|2|0.1|0|0.3|0
Кофе с молоком|drinks|30|1.5|1|3|0
Чай травяной|drinks|1|0.1|0|0.1|0
Лимонад домашний|drinks|45|0|0|11|0
Смузи ягодный|drinks|55|1|0.4|11|2
Смузи банановый|drinks|70|2|1|12|1
Смузи зелёный|drinks|40|1.5|0.5|8|2
Мёд|sweets|304|0.3|0|82|0.2
Шоколад тёмный 70%|sweets|598|7.8|43|46|11
Шоколад молочный|sweets|535|8|30|59|3.4
Мороженое|sweets|207|3.5|11|20|0.7
Халва|sweets|516|12|30|54|4
Зефир|sweets|326|0.8|0.1|80|0.5
Мармелад|sweets|293|0.1|0|77|0.5
Печенье|sweets|417|7.5|21|67|2
Торт|sweets|349|5|22|45|1
Пончик|sweets|426|5|25|51|1.5
Блинчики|sweets|233|6|7|37|1
Сырники|sweets|183|15|10|15|0.5
Варенье|sweets|271|0.4|0.1|70|0.5
Сахар|sweets|387|0|0|100|0
Мёд гречишный|sweets|309|0.3|0|83|0.2
Мёд акациевый|sweets|304|0.3|0|82|0.2
Мёд липовый|sweets|320|0.3|0|80|0.2
Мёд горный|sweets|310|0.3|0|82|0.2
Сироп кленовый|sweets|260|0|0|67|0
Сироп агавы|sweets|310|0|0|76|0
Сироп топинамбура|sweets|267|0|0|70|0
Финиковая паста|sweets|282|2.5|0.4|75|7
Инжир сушёный|sweets|249|3.3|0.9|63|9.8
Курага|sweets|241|3.4|0.5|63|7.3
Чернослив|sweets|240|2.3|0.4|63|7.1
Изюм светлый|sweets|299|3.1|0.5|79|3.7
Изюм тёмный|sweets|290|3|0.5|77|3.7
Цукаты|sweets|300|0.5|0.3|78|2
Мармелад желейный|sweets|293|0.1|0|77|0.5
Мармелад фруктовый|sweets|280|0.2|0|72|1
Зефир ванильный|sweets|326|0.8|0.1|80|0.5
Зефир шоколадный|sweets|350|1|5|78|0.5
Пастила|sweets|310|0.5|0.1|78|0.5
Нуга|sweets|380|5|10|70|1
Халва подсолнечная|sweets|516|12|30|54|4
Халва тахинная|sweets|500|15|28|50|5
Козинак|sweets|520|15|30|50|5
Чурчхела|sweets|400|5|10|75|2
Леденец|sweets|380|0|0|95|0
Ирис|sweets|380|3|10|75|0.5
Карамель|sweets|380|0|0|95|0
Шоколад белый|sweets|539|6|32|59|0.1
Шоколад с орехами|sweets|550|8|35|50|5
Шоколад с изюмом|sweets|520|7|30|55|4
Шоколад пористый|sweets|520|6|28|60|2
Батончик мюсли|sweets|380|8|12|60|5
Батончик протеиновый|sweets|350|30|12|35|3
Пряники|sweets|360|5|5|75|2
Коврижка|sweets|350|4|6|72|2
Сухарики|sweets|370|10|5|72|3
Бублики|sweets|250|8|1.5|50|2
Сушки|sweets|250|8|1.5|50|2
Баранки|sweets|250|8|1.5|50|2
Кекс|sweets|380|5|18|50|1.5
Маффин шоколадный|sweets|400|5|20|50|1.5
Капкейк|sweets|380|4|18|52|1
Мёд цветочный|sweets|304|0.3|0|82.4|0.2
Шоколад тёмный 85%|sweets|598|11|43|46|11
Сорбет фруктовый|sweets|130|0.5|0.1|31|0.5
Гранола без сахара|sweets|430|10|16|60|8
Мюсли без сахара|sweets|350|10|7|63|9
Круассан|bakery|406|8.2|21|45|2.6
Багет|bakery|274|10|2.6|52|2.4
Булочка с маком|bakery|330|9|9|60|2
Лаваш|bakery|236|7.9|1|48|2
Пита|bakery|275|9|1.2|56|2.5
Бублик|bakery|250|8|1.5|50|2
Маффин|bakery|375|5|17|53|1.5
Чизкейк|bakery|321|8|22|25|0.5
Лаваш цельнозерновой|bakery|248|9|1.8|47|6
Пита цельнозерновая|bakery|250|9|1.5|50|6
Хлеб ржаной цельнозерновой|bakery|208|6.5|1.2|42|6.5
Хлеб пшеничный цельнозерновой|bakery|247|13|3.4|41|7
Хлеб с семенами|bakery|270|10|7|43|7
Хлеб белковый|bakery|250|20|8|18|8
Тортилья цельнозерновая|bakery|310|9|8|47|6
Хлеб кукурузный цельнозерновой|bakery|260|7|4|49|5
Чиабатта|bakery|271|9|4|50|2
Фокачча|bakery|280|8|8|42|2
Хлеб овсяный|bakery|247|10|4|43|6
Хлеб гречневый|bakery|240|8|3|44|6
Хлеб с отрубями ржаной|bakery|215|8|2.5|42|8
Пицца маргарита|fastfood|266|11|10|33|2
Пицца пепперони|fastfood|298|12|13|33|2
Бургер|fastfood|295|17|14|24|1
Чизбургер|fastfood|303|15|15|27|1
Картофель фри|fastfood|312|3.4|15|41|3.8
Хот-дог|fastfood|290|10|18|24|1
Шаурма|fastfood|210|12|12|17|1.5
Наггетсы|fastfood|296|15|18|17|1
Суши с лососем|fastfood|150|6|1.5|28|1
Ролл Филадельфия|fastfood|142|6|4|20|1
Пицца 4 сыра|fastfood|285|12|15|26|1.5
Пицца с курицей|fastfood|240|14|9|26|2
Бургер куриный|fastfood|260|15|12|23|1.5
Бургер двойной|fastfood|330|22|19|24|1
Кесадилья с курицей|fastfood|250|16|11|22|2
Тако с говядиной|fastfood|210|12|10|19|3
Фалафель в пите|fastfood|260|10|10|31|6
Картофельные дольки|fastfood|250|4|11|34|4
Паста карбонара|fastfood|190|7|9|21|1
Лазанья мясная|fastfood|160|9|8|13|1.5
Суп рамен|fastfood|75|4|2|9|1
Протеин сывороточный|supplements|370|80|5|10|0
Казеин|supplements|360|70|5|10|0
Протеиновый батончик|supplements|350|30|12|35|3
BCAA|supplements|0|0|0|0|0
Креатин|supplements|0|0|0|0|0
Омега-3|supplements|902|0|100|0|0
Гейнер|supplements|380|15|5|70|1
Коллаген|supplements|355|90|0|0|0
Изолят сывороточного белка|supplements|360|85|0.5|3|0
Гидролизат сывороточного белка|supplements|365|80|2|8|0
Казеин мицеллярный|supplements|360|75|1|6|0
Протеин яичный|supplements|370|80|2|6|0
Протеин гороховый|supplements|390|75|6|8|0
Протеин рисовый|supplements|380|80|4|8|0
Креатин моногидрат|supplements|0|0|0|0|0
Электролиты без сахара|supplements|0|0|0|0|0
Глютамин|supplements|0|0|0|0|0
Аргинин|supplements|0|0|0|0|0
Цитруллин|supplements|0|0|0|0|0
Декстроза|supplements|380|0|0|95|0
Корица|spices|247|4|1.2|81|53
Мята свежая|spices|44|3.3|0.7|8.4|6.8
Куркума|spices|312|9.7|3.2|67|22.7
Паприка|spices|282|14.1|12.9|54.9|34.9
Чёрный перец молотый|spices|251|10.4|3.3|64|25.3
Орегано|spices|265|9|4.3|69|42.5
Базилик сушёный|spices|233|23|4.1|47|37.7
Чесночный порошок|spices|331|16.6|0.7|72.7|9
Имбирь молотый|spices|335|9|4.2|71.6|14.1
Кардамон|spices|311|11|6.7|68.5|28
Мускатный орех|spices|525|5.8|36.3|49.3|20.8
Кориандр молотый|spices|298|12.4|17.8|54.9|41.9
Зира|spices|375|17.8|22.3|44.2|10.5
Розмарин сушёный|spices|331|4.9|15.2|64|42.6
Тимьян сушёный|spices|276|9.1|7.4|63.9|37
Петрушка сушёная|spices|292|26.6|5.5|50.6|26.7
Ваниль|spices|288|0.1|0.1|12.7|0
Какао-бобы|sweets|228|19.6|13.1|57.9|29.8
Соль|spices|0|0|0|0|0
Мята|spices|44|3.3|0.7|8.4|6.8
Сыр сливочный|dairy|342|6|34|4|0''';

    final lines = rawProducts
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);

    int added = 0;
    final now = DateTime.now().toIso8601String();
    final uuid = const Uuid();

    for (final line in lines) {
      final parts = line.split('|');
      if (parts.length != 7) {
        debugPrint('⚠️ Некорректная строка продукта: $line');
        continue;
      }

      final name = parts[0].trim();
      final category = parts[1].trim();

      final calories = double.tryParse(parts[2]) ?? 0;
      final protein = double.tryParse(parts[3]) ?? 0;
      final fat = double.tryParse(parts[4]) ?? 0;
      final carbs = double.tryParse(parts[5]) ?? 0;
      final fiber = double.tryParse(parts[6]) ?? 0;

      if (name.isEmpty) continue;

      final result = await db.insert(
        'food_products',
        {
          'id': uuid.v4(),
          'name': name,
          'nameNormalized': _normalizeName(name),
          'category': category,
          'calories': calories,
          'protein': protein,
          'fat': fat,
          'carbs': carbs,
          'fiber': fiber,
          'isCustom': 0,
          'isFavorite': 0,
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      if (result != 0) added++;
    }

    debugPrint('✅ v7: добавлено продуктов: $added');
  }

  // ==========================================================================
  // TEMPLATES
  // ==========================================================================

  Future<void> _insertV7Templates(DatabaseExecutor db) async {
    final products = await _loadProductMap(db);

    final templates = <List<String>>[
      const [
        'Овсянка с бананом и орехами',
        'Овсянка:50;Банан:100;Молоко 2.5%:200;Грецкий орех:15',
      ],
      const [
        'Овсянка с ягодами и мёдом',
        'Овсянка:50;Клубника:80;Черника:50;Мёд:15',
      ],
      const [
        'Овсянка с орехами и сухофруктами',
        'Овсянка:50;Миндаль:20;Изюм:20;Мёд:10',
      ],
      const [
        'Яичница с авокадо',
        'Яйцо куриное C0:120;Авокадо:100;Хлеб цельнозерновой:40;Масло оливковое:5',
      ],
      const [
        'Омлет с овощами и сыром',
        'Яйцо куриное C0:120;Помидор:80;Перец болгарский:50;Сыр твёрдый:30;Молоко 2.5%:50',
      ],
      const [
        'Сырники со сметаной и ягодами',
        'Сырники:150;Сметана 15%:30;Клубника:50;Мёд:10',
      ],
      const [
        'Творог с мёдом и орехами',
        'Творог 5%:200;Мёд:20;Грецкий орех:20;Черника:30',
      ],
      const [
        'Творог с бананом',
        'Творог 5%:200;Банан:100;Мёд:10',
      ],
      const [
        'Бутерброд с авокадо и яйцом',
        'Хлеб цельнозерновой:50;Авокадо:80;Яйцо куриное C0:60;Лимон:10',
      ],
      const [
        'Бутерброд с сыром и ветчиной',
        'Хлеб белый:60;Сыр твёрдый:30;Ветчина:30;Масло сливочное:10',
      ],
      const [
        'Гречневая каша с молоком',
        'Гречка варёная:150;Молоко 2.5%:150;Масло сливочное:10',
      ],
      const [
        'Рисовая каша с яблоком',
        'Каша рисовая на молоке:200;Яблоко:80',
      ],
      const [
        'Яичница с помидорами и сыром',
        'Яйцо куриное C0:120;Помидор:100;Сыр твёрдый:30;Масло оливковое:10',
      ],
      const [
        'Бутерброд с лососем и сливочным сыром',
        'Хлеб цельнозерновой:60;Лосось:60;Творожный сыр:30;Лимон:10',
      ],
      const [
        'Овсянка с тыквой и специями',
        'Овсянка:50;Тыква:100;Молоко 2.5%:150;Корица:2',
      ],
      const [
        'Киноа с овощами и тофу',
        'Киноа варёная:150;Тофу:100;Брокколи:80;Морковь:50;Масло оливковое:10',
      ],
      const [
        'Запечённый лосось с овощами',
        'Лосось:150;Брокколи:100;Морковь:50;Масло оливковое:10;Лимон:20',
      ],
      const [
        'Куриная грудка с киноа и авокадо',
        'Куриная грудка:150;Киноа варёная:120;Авокадо:80;Помидор:60',
      ],
      const [
        'Индейка с овощным рагу',
        'Индейка:150;Кабачок:80;Морковь:50;Перец болгарский:50;Паста томатная:30',
      ],
      const [
        'Рыбное филе с рисом и шпинатом',
        'Минтай:150;Рис белый варёный:120;Шпинат:80;Масло оливковое:10',
      ],
      const [
        'Куриные котлеты с гречкой',
        'Котлеты домашние:150;Гречка варёная:150;Огурец:80;Сметана 15%:20',
      ],
      const [
        'Булгур с овощами и нутом',
        'Булгур варёный:150;Нут варёный:100;Морковь:50;Перец болгарский:50;Масло оливковое:10',
      ],
      const [
        'Нисуаз с тунцом',
        'Тунец:100;Яйцо куриное C0:60;Огурец:80;Помидор:80;Фасоль стручковая:50;Масло оливковое:10',
      ],
      const [
        'Тёплый салат с курицей',
        'Куриная грудка:100;Руккола:40;Помидор:80;Сыр пармезан:20;Масло оливковое:10',
      ],
      const [
        'Салат с киноа и гранатом',
        'Киноа варёная:100;Гранат:80;Руккола:40;Огурец:60;Масло оливковое:10',
      ],
      const [
        'Салат с креветками и манго',
        'Креветки:100;Манго:80;Авокадо:60;Салат листовой:40;Лимон:10',
      ],
      const [
        'Салат с фасолью и киноа',
        'Фасоль варёная:100;Киноа варёная:80;Огурец:60;Помидор:60;Масло оливковое:10',
      ],
      const [
        'Салат с яблоком и орехами',
        'Яблоко:100;Салат листовой:50;Грецкий орех:30;Сыр твёрдый:30;Масло оливковое:10',
      ],
      const [
        'Курица с бататом и брокколи',
        'Куриная грудка:150;Батат:150;Брокколи:100;Масло оливковое:10',
      ],
      const [
        'Рыба с киноа и овощами',
        'Минтай:150;Киноа варёная:120;Цветная капуста:100;Масло оливковое:10',
      ],
      const [
        'Тофу с овощами в азиатском стиле',
        'Тофу:120;Перец болгарский:80;Брокколи:80;Соевый соус:20;Масло кунжутное:10',
      ],
      const [
        'Запеканка с индейкой и овощами',
        'Индейка:120;Кабачок:80;Морковь:50;Сыр твёрдый:30;Яйцо куриное C0:60',
      ],
      const [
        'Куриные рулетики с сыром',
        'Куриная грудка:120;Сыр твёрдый:30;Шпинат:40;Масло оливковое:10',
      ],
      const [
        'Хумус с овощами',
        'Хумус:60;Морковь:80;Огурец:80;Перец болгарский:60',
      ],
      const [
        'Греческий йогурт с мёдом',
        'Йогурт греческий:150;Мёд:15;Грецкий орех:15',
      ],
      const [
        'Смузи с ананасом и шпинатом',
        'Ананас:100;Шпинат:40;Банан:80;Молоко 2.5%:150',
      ],
      const [
        'Творог с зеленью и огурцом',
        'Творог 5%:150;Огурец:60;Укроп:10;Лук зелёный:10',
      ],
      const [
        'Яблочные дольки с ореховой пастой',
        'Яблоко:150;Арахисовая паста:20',
      ],
      const [
        'Смузи с манго и бананом',
        'Манго:100;Банан:80;Йогурт греческий:100;Молоко 2.5%:100',
      ],
      const [
        'Овощные палочки с гуакамоле',
        'Авокадо:80;Помидор:40;Лук репчатый:20;Морковь:60;Огурец:60',
      ],
      const [
        'Протеиновый омлет с овощами',
        'Яйцо куриное C0:120;Протеин сывороточный:20;Помидор:60;Шпинат:40;Масло оливковое:10',
      ],
      const [
        'Протеиновые панкейки',
        'Протеин сывороточный:30;Яйцо куриное C0:30;Овсянка:20;Банан:60',
      ],
      const [
        'Творожный десерт с ягодами',
        'Творог 5%:150;Клубника:60;Черника:40;Мёд:15',
      ],
      const [
        'Шоколадный протеиновый пудинг',
        'Протеин сывороточный:30;Молоко 2.5%:150;Какао:10;Мёд:10',
      ],
      const [
        'Боул Куриная грудка с рис и брокколи',
        'Куриная грудка:160;Рис белый варёный:180;Брокколи:120',
      ],
      const [
        'Боул Куриная грудка с гречка варёная и помидор',
        'Куриная грудка:160;Гречка варёная:170;Помидор:120',
      ],
      const [
        'Боул Куриная грудка с макароны варёные и огурец',
        'Куриная грудка:160;Макароны варёные:180;Огурец:120',
      ],
      const [
        'Боул Куриная грудка с киноа варёная и морковь',
        'Куриная грудка:160;Киноа варёная:170;Морковь:120',
      ],
      const [
        'Боул Куриная грудка с булгур и перец болгарский',
        'Куриная грудка:160;Булгур варёный:170;Перец болгарский:120',
      ],
      const [
        'Боул Куриная грудка с картофель и капуста цветная',
        'Куриная грудка:160;Картофель варёный:170;Капуста цветная:120',
      ],
      const [
        'Боул Индейка с рис и помидор',
        'Индейка:160;Рис белый варёный:180;Помидор:120',
      ],
      const [
        'Боул Индейка с гречка варёная и огурец',
        'Индейка:160;Гречка варёная:170;Огурец:120',
      ],
      const [
        'Боул Индейка с макароны варёные и морковь',
        'Индейка:160;Макароны варёные:180;Морковь:120',
      ],
      const [
        'Боул Индейка с киноа варёная и перец болгарский',
        'Индейка:160;Киноа варёная:170;Перец болгарский:120',
      ],
      const [
        'Боул Индейка с булгур и капуста цветная',
        'Индейка:160;Булгур варёный:170;Капуста цветная:120',
      ],
      const [
        'Боул Индейка с картофель и брокколи',
        'Индейка:160;Картофель варёный:170;Брокколи:120',
      ],
      const [
        'Боул Говядина с рис и огурец',
        'Говядина:160;Рис белый варёный:180;Огурец:120',
      ],
      const [
        'Боул Говядина с гречка варёная и морковь',
        'Говядина:160;Гречка варёная:170;Морковь:120',
      ],
      const [
        'Боул Говядина с макароны варёные и перец болгарский',
        'Говядина:160;Макароны варёные:180;Перец болгарский:120',
      ],
      const [
        'Боул Говядина с киноа варёная и капуста цветная',
        'Говядина:160;Киноа варёная:170;Капуста цветная:120',
      ],
      const [
        'Боул Говядина с булгур и брокколи',
        'Говядина:160;Булгур варёный:170;Брокколи:120',
      ],
      const [
        'Боул Говядина с картофель и помидор',
        'Говядина:160;Картофель варёный:170;Помидор:120',
      ],
      const [
        'Боул Телятина с рис и морковь',
        'Телятина:160;Рис белый варёный:180;Морковь:120',
      ],
      const [
        'Боул Телятина с гречка варёная и перец болгарский',
        'Телятина:160;Гречка варёная:170;Перец болгарский:120',
      ],
      const [
        'Боул Телятина с макароны варёные и капуста цветная',
        'Телятина:160;Макароны варёные:180;Капуста цветная:120',
      ],
      const [
        'Боул Телятина с киноа варёная и брокколи',
        'Телятина:160;Киноа варёная:170;Брокколи:120',
      ],
      const [
        'Боул Телятина с булгур и помидор',
        'Телятина:160;Булгур варёный:170;Помидор:120',
      ],
      const [
        'Боул Телятина с картофель и огурец',
        'Телятина:160;Картофель варёный:170;Огурец:120',
      ],
      const [
        'Боул Свинина вырезка с рис и перец болгарский',
        'Свинина вырезка:160;Рис белый варёный:180;Перец болгарский:120',
      ],
      const [
        'Боул Свинина вырезка с гречка варёная и капуста цветная',
        'Свинина вырезка:160;Гречка варёная:170;Капуста цветная:120',
      ],
      const [
        'Боул Свинина вырезка с макароны варёные и брокколи',
        'Свинина вырезка:160;Макароны варёные:180;Брокколи:120',
      ],
      const [
        'Боул Свинина вырезка с киноа варёная и помидор',
        'Свинина вырезка:160;Киноа варёная:170;Помидор:120',
      ],
      const [
        'Боул Свинина вырезка с булгур и огурец',
        'Свинина вырезка:160;Булгур варёный:170;Огурец:120',
      ],
      const [
        'Боул Свинина вырезка с картофель и морковь',
        'Свинина вырезка:160;Картофель варёный:170;Морковь:120',
      ],
      const [
        'Боул Кролик с рис и капуста цветная',
        'Кролик:160;Рис белый варёный:180;Капуста цветная:120',
      ],
      const [
        'Боул Кролик с гречка варёная и брокколи',
        'Кролик:160;Гречка варёная:170;Брокколи:120',
      ],
      const [
        'Боул Кролик с макароны варёные и помидор',
        'Кролик:160;Макароны варёные:180;Помидор:120',
      ],
      const [
        'Боул Кролик с киноа варёная и огурец',
        'Кролик:160;Киноа варёная:170;Огурец:120',
      ],
      const [
        'Боул Кролик с булгур и морковь',
        'Кролик:160;Булгур варёный:170;Морковь:120',
      ],
      const [
        'Боул Кролик с картофель и перец болгарский',
        'Кролик:160;Картофель варёный:170;Перец болгарский:120',
      ],
      const [
        'Боул Лосось с рис и брокколи',
        'Лосось:160;Рис белый варёный:180;Брокколи:120',
      ],
      const [
        'Боул Лосось с гречка варёная и помидор',
        'Лосось:160;Гречка варёная:170;Помидор:120',
      ],
      const [
        'Боул Лосось с макароны варёные и огурец',
        'Лосось:160;Макароны варёные:180;Огурец:120',
      ],
      const [
        'Боул Лосось с киноа варёная и морковь',
        'Лосось:160;Киноа варёная:170;Морковь:120',
      ],
      const [
        'Боул Лосось с булгур и перец болгарский',
        'Лосось:160;Булгур варёный:170;Перец болгарский:120',
      ],
      const [
        'Боул Лосось с картофель и капуста цветная',
        'Лосось:160;Картофель варёный:170;Капуста цветная:120',
      ],
      const [
        'Боул Треска с рис и помидор',
        'Треска:160;Рис белый варёный:180;Помидор:120',
      ],
      const [
        'Боул Треска с гречка варёная и огурец',
        'Треска:160;Гречка варёная:170;Огурец:120',
      ],
      const [
        'Боул Треска с макароны варёные и морковь',
        'Треска:160;Макароны варёные:180;Морковь:120',
      ],
      const [
        'Боул Треска с киноа варёная и перец болгарский',
        'Треска:160;Киноа варёная:170;Перец болгарский:120',
      ],
      const [
        'Боул Треска с булгур и капуста цветная',
        'Треска:160;Булгур варёный:170;Капуста цветная:120',
      ],
      const [
        'Боул Треска с картофель и брокколи',
        'Треска:160;Картофель варёный:170;Брокколи:120',
      ],
      const [
        'Боул Минтай с рис и огурец',
        'Минтай:160;Рис белый варёный:180;Огурец:120',
      ],
      const [
        'Боул Минтай с гречка варёная и морковь',
        'Минтай:160;Гречка варёная:170;Морковь:120',
      ],
      const [
        'Боул Минтай с макароны варёные и перец болгарский',
        'Минтай:160;Макароны варёные:180;Перец болгарский:120',
      ],
      const [
        'Боул Минтай с киноа варёная и капуста цветная',
        'Минтай:160;Киноа варёная:170;Капуста цветная:120',
      ],
      const [
        'Боул Минтай с булгур и брокколи',
        'Минтай:160;Булгур варёный:170;Брокколи:120',
      ],
      const [
        'Боул Минтай с картофель и помидор',
        'Минтай:160;Картофель варёный:170;Помидор:120',
      ],
      const [
        'Боул Хек с рис и морковь',
        'Хек:160;Рис белый варёный:180;Морковь:120',
      ],
      const [
        'Боул Хек с гречка варёная и перец болгарский',
        'Хек:160;Гречка варёная:170;Перец болгарский:120',
      ],
      const [
        'Боул Хек с макароны варёные и капуста цветная',
        'Хек:160;Макароны варёные:180;Капуста цветная:120',
      ],
      const [
        'Боул Хек с киноа варёная и брокколи',
        'Хек:160;Киноа варёная:170;Брокколи:120',
      ],
      const [
        'Боул Хек с булгур и помидор',
        'Хек:160;Булгур варёный:170;Помидор:120',
      ],
      const [
        'Боул Хек с картофель и огурец',
        'Хек:160;Картофель варёный:170;Огурец:120',
      ],
      const [
        'Боул Тунец с рис и перец болгарский',
        'Тунец:160;Рис белый варёный:180;Перец болгарский:120',
      ],
      const [
        'Боул Тунец с гречка варёная и капуста цветная',
        'Тунец:160;Гречка варёная:170;Капуста цветная:120',
      ],
      const [
        'Боул Тунец с макароны варёные и брокколи',
        'Тунец:160;Макароны варёные:180;Брокколи:120',
      ],
      const [
        'Боул Тунец с киноа варёная и помидор',
        'Тунец:160;Киноа варёная:170;Помидор:120',
      ],
      const [
        'Боул Тунец с булгур и огурец',
        'Тунец:160;Булгур варёный:170;Огурец:120',
      ],
      const [
        'Боул Тунец с картофель и морковь',
        'Тунец:160;Картофель варёный:170;Морковь:120',
      ],
      const [
        'Боул Горбуша с рис и капуста цветная',
        'Горбуша:160;Рис белый варёный:180;Капуста цветная:120',
      ],
      const [
        'Боул Горбуша с гречка варёная и брокколи',
        'Горбуша:160;Гречка варёная:170;Брокколи:120',
      ],
      const [
        'Боул Горбуша с макароны варёные и помидор',
        'Горбуша:160;Макароны варёные:180;Помидор:120',
      ],
      const [
        'Боул Горбуша с киноа варёная и огурец',
        'Горбуша:160;Киноа варёная:170;Огурец:120',
      ],
      const [
        'Боул Горбуша с булгур и морковь',
        'Горбуша:160;Булгур варёный:170;Морковь:120',
      ],
      const [
        'Боул Горбуша с картофель и перец болгарский',
        'Горбуша:160;Картофель варёный:170;Перец болгарский:120',
      ],
      const [
        'Боул Форель с рис и брокколи',
        'Форель:160;Рис белый варёный:180;Брокколи:120',
      ],
      const [
        'Боул Форель с гречка варёная и помидор',
        'Форель:160;Гречка варёная:170;Помидор:120',
      ],
      const [
        'Боул Форель с макароны варёные и огурец',
        'Форель:160;Макароны варёные:180;Огурец:120',
      ],
      const [
        'Боул Форель с киноа варёная и морковь',
        'Форель:160;Киноа варёная:170;Морковь:120',
      ],
      const [
        'Боул Форель с булгур и перец болгарский',
        'Форель:160;Булгур варёный:170;Перец болгарский:120',
      ],
      const [
        'Боул Форель с картофель и капуста цветная',
        'Форель:160;Картофель варёный:170;Капуста цветная:120',
      ],
      const [
        'Боул Креветки с рис и помидор',
        'Креветки:180;Рис белый варёный:180;Помидор:120',
      ],
      const [
        'Боул Креветки с гречка варёная и огурец',
        'Креветки:180;Гречка варёная:170;Огурец:120',
      ],
      const [
        'Боул Креветки с макароны варёные и морковь',
        'Креветки:180;Макароны варёные:180;Морковь:120',
      ],
      const [
        'Боул Креветки с киноа варёная и перец болгарский',
        'Креветки:180;Киноа варёная:170;Перец болгарский:120',
      ],
      const [
        'Боул Креветки с булгур и капуста цветная',
        'Креветки:180;Булгур варёный:170;Капуста цветная:120',
      ],
      const [
        'Боул Креветки с картофель и брокколи',
        'Креветки:180;Картофель варёный:170;Брокколи:120',
      ],
      const [
        'Боул Кальмар с рис и огурец',
        'Кальмар:180;Рис белый варёный:180;Огурец:120',
      ],
      const [
        'Боул Кальмар с гречка варёная и морковь',
        'Кальмар:180;Гречка варёная:170;Морковь:120',
      ],
      const [
        'Боул Кальмар с макароны варёные и перец болгарский',
        'Кальмар:180;Макароны варёные:180;Перец болгарский:120',
      ],
      const [
        'Боул Кальмар с киноа варёная и капуста цветная',
        'Кальмар:180;Киноа варёная:170;Капуста цветная:120',
      ],
      const [
        'Боул Кальмар с булгур и брокколи',
        'Кальмар:180;Булгур варёный:170;Брокколи:120',
      ],
      const [
        'Боул Кальмар с картофель и помидор',
        'Кальмар:180;Картофель варёный:170;Помидор:120',
      ],
      const [
        'Боул Мидии с рис и морковь',
        'Мидии:180;Рис белый варёный:180;Морковь:120',
      ],
      const [
        'Боул Мидии с гречка варёная и перец болгарский',
        'Мидии:180;Гречка варёная:170;Перец болгарский:120',
      ],
      const [
        'Боул Мидии с макароны варёные и капуста цветная',
        'Мидии:180;Макароны варёные:180;Капуста цветная:120',
      ],
      const [
        'Боул Мидии с киноа варёная и брокколи',
        'Мидии:180;Киноа варёная:170;Брокколи:120',
      ],
      const [
        'Боул Мидии с булгур и помидор',
        'Мидии:180;Булгур варёный:170;Помидор:120',
      ],
      const [
        'Боул Мидии с картофель и огурец',
        'Мидии:180;Картофель варёный:170;Огурец:120',
      ],
      const [
        'Боул Тофу с рис и перец болгарский',
        'Тофу:160;Рис белый варёный:180;Перец болгарский:120',
      ],
      const [
        'Боул Тофу с гречка варёная и капуста цветная',
        'Тофу:160;Гречка варёная:170;Капуста цветная:120',
      ],
      const [
        'Боул Тофу с макароны варёные и брокколи',
        'Тофу:160;Макароны варёные:180;Брокколи:120',
      ],
      const [
        'Боул Тофу с киноа варёная и помидор',
        'Тофу:160;Киноа варёная:170;Помидор:120',
      ],
      const [
        'Боул Тофу с булгур и огурец',
        'Тофу:160;Булгур варёный:170;Огурец:120',
      ],
      const [
        'Боул Тофу с картофель и морковь',
        'Тофу:160;Картофель варёный:170;Морковь:120',
      ],
      const [
        'Боул Темпе с рис и капуста цветная',
        'Темпе:160;Рис белый варёный:180;Капуста цветная:120',
      ],
      const [
        'Боул Темпе с гречка варёная и брокколи',
        'Темпе:160;Гречка варёная:170;Брокколи:120',
      ],
      const [
        'Боул Темпе с макароны варёные и помидор',
        'Темпе:160;Макароны варёные:180;Помидор:120',
      ],
      const [
        'Боул Темпе с киноа варёная и огурец',
        'Темпе:160;Киноа варёная:170;Огурец:120',
      ],
      const [
        'Боул Темпе с булгур и морковь',
        'Темпе:160;Булгур варёный:170;Морковь:120',
      ],
      const [
        'Боул Темпе с картофель и перец болгарский',
        'Темпе:160;Картофель варёный:170;Перец болгарский:120',
      ],
      const [
        'Боул Сейтан с рис и брокколи',
        'Сейтан:160;Рис белый варёный:180;Брокколи:120',
      ],
      const [
        'Боул Сейтан с гречка варёная и помидор',
        'Сейтан:160;Гречка варёная:170;Помидор:120',
      ],
      const [
        'Боул Сейтан с макароны варёные и огурец',
        'Сейтан:160;Макароны варёные:180;Огурец:120',
      ],
      const [
        'Боул Сейтан с киноа варёная и морковь',
        'Сейтан:160;Киноа варёная:170;Морковь:120',
      ],
      const [
        'Боул Сейтан с булгур и перец болгарский',
        'Сейтан:160;Булгур варёный:170;Перец болгарский:120',
      ],
      const [
        'Боул Сейтан с картофель и капуста цветная',
        'Сейтан:160;Картофель варёный:170;Капуста цветная:120',
      ],
      const [
        'Боул Фасоль варёная с рис и помидор',
        'Фасоль варёная:160;Рис белый варёный:180;Помидор:120',
      ],
      const [
        'Боул Фасоль варёная с гречка варёная и огурец',
        'Фасоль варёная:160;Гречка варёная:170;Огурец:120',
      ],
      const [
        'Боул Фасоль варёная с макароны варёные и морковь',
        'Фасоль варёная:160;Макароны варёные:180;Морковь:120',
      ],
      const [
        'Боул Фасоль варёная с киноа варёная и перец болгарский',
        'Фасоль варёная:160;Киноа варёная:170;Перец болгарский:120',
      ],
      const [
        'Боул Фасоль варёная с булгур и капуста цветная',
        'Фасоль варёная:160;Булгур варёный:170;Капуста цветная:120',
      ],
      const [
        'Боул Фасоль варёная с картофель и брокколи',
        'Фасоль варёная:160;Картофель варёный:170;Брокколи:120',
      ],
    ];

    int added = 0;
    final now = DateTime.now().toIso8601String();
    final uuid = const Uuid();

    for (final entry in templates) {
      if (entry.length != 2) continue;

      final name = entry[0];
      final ingredients = entry[1];

      final items = _parseTemplateIngredients(products, ingredients, name);
      if (items == null || items.isEmpty) continue;

      final result = await db.insert(
        'meal_templates',
        {
          'id': uuid.v4(),
          'name': name,
          'nameNormalized': _normalizeName(name),
          'items': jsonEncode(items),
          'calories': 0.0,
          'protein': 0.0,
          'fat': 0.0,
          'carbs': 0.0,
          'fiber': 0.0,
          'totalGrams': 0.0,
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      if (result != 0) added++;
    }

    debugPrint('✅ v7: добавлено готовых блюд: $added');
  }

  Future<Map<String, Map<String, dynamic>>> _loadProductMap(
      DatabaseExecutor db,
      ) async {
    final rows = await db.query('food_products');
    final map = <String, Map<String, dynamic>>{};

    for (final row in rows) {
      final normalized = (row['nameNormalized'] as String?)?.trim() ??
          _normalizeName(row['name'] as String? ?? '');

      if (normalized.isEmpty) continue;

      map[normalized] = {
        'id': row['id'] as String,
        'name': row['name'] as String,
        'calories': (row['calories'] as num?)?.toDouble() ?? 0,
        'protein': (row['protein'] as num?)?.toDouble() ?? 0,
        'fat': (row['fat'] as num?)?.toDouble() ?? 0,
        'carbs': (row['carbs'] as num?)?.toDouble() ?? 0,
        'fiber': (row['fiber'] as num?)?.toDouble() ?? 0,
      };
    }
    return map;
  }

  List<Map<String, dynamic>>? _parseTemplateIngredients(
      Map<String, Map<String, dynamic>> products,
      String rawIngredients,
      String templateName,
      ) {
    final parts = rawIngredients
        .split(';')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);

    final items = <Map<String, dynamic>>[];

    for (final part in parts) {
      final separator = part.lastIndexOf(':');
      if (separator <= 0) {
        debugPrint('⚠️ Некорректный ингредиент "$part" в "$templateName"');
        return null;
      }

      final productName = part.substring(0, separator).trim();
      final grams = double.tryParse(part.substring(separator + 1).trim());

      if (grams == null || grams <= 0) {
        debugPrint('⚠️ Некорректный вес "$part" в "$templateName"');
        return null;
      }

      final product = products[_normalizeName(productName)];
      if (product == null) {
        debugPrint('⚠️ Продукт "$productName" не найден в "$templateName"');
        return null;
      }

      items.add({
        'productId': product['id'],
        'grams': grams,
        'name': product['name'],
      });
    }

    return items;
  }

  // ==========================================================================
  // AUTOMATIC NUTRITION CALCULATION
  // ==========================================================================

  Future<Map<String, double>> calculateTemplateNutrition(String templateId) async {
    final db = await database;
    return _calculateTemplateNutritionWithDb(db, templateId);
  }

  Future<Map<String, double>> _calculateTemplateNutritionWithDb(
      DatabaseExecutor db,
      String templateId,
      ) async {
    final templateRows = await db.query(
      'meal_templates',
      where: 'id = ?',
      whereArgs: [templateId],
      limit: 1,
    );

    if (templateRows.isEmpty) {
      return {
        'calories': 0,
        'protein': 0,
        'fat': 0,
        'carbs': 0,
        'fiber': 0,
        'grams': 0,
      };
    }

    final template = templateRows.first;

    dynamic decoded;
    try {
      decoded = jsonDecode(template['items'] as String? ?? '[]');
    } catch (_) {
      decoded = <dynamic>[];
    }

    if (decoded is! List) decoded = <dynamic>[];

    double calories = 0;
    double protein = 0;
    double fat = 0;
    double carbs = 0;
    double fiber = 0;
    double totalGrams = 0;

    final productCache = <String, Map<String, Object?>>{};

    for (final rawItem in decoded) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);

      final productId = item['productId'] as String?;
      final grams = (item['grams'] as num?)?.toDouble() ?? 0;

      if (productId == null || productId.isEmpty || grams <= 0) continue;

      Map<String, Object?>? product = productCache[productId];
      if (product == null) {
        final rows = await db.query(
          'food_products',
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
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

    return {
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'fiber': fiber,
      'grams': totalGrams,
    };
  }

  Future<void> _recalculateTemplateNutrition(
      DatabaseExecutor db,
      String templateId,
      ) async {
    final nutrition = await _calculateTemplateNutritionWithDb(db, templateId);

    await db.update(
      'meal_templates',
      {
        'calories': nutrition['calories'] ?? 0,
        'protein': nutrition['protein'] ?? 0,
        'fat': nutrition['fat'] ?? 0,
        'carbs': nutrition['carbs'] ?? 0,
        'fiber': nutrition['fiber'] ?? 0,
        'totalGrams': nutrition['grams'] ?? 0,
      },
      where: 'id = ?',
      whereArgs: [templateId],
    );
  }

  Future<void> _recalculateAllTemplateNutrition(DatabaseExecutor db) async {
    final templates = await db.query('meal_templates', columns: ['id']);

    int recalculated = 0;
    for (final template in templates) {
      final id = template['id'] as String?;
      if (id == null || id.isEmpty) continue;
      await _recalculateTemplateNutrition(db, id);
      recalculated++;
    }

    debugPrint('✅ Пересчитано блюд: $recalculated');
  }

  Future<void> refreshTemplatesForProduct(String productId) async {
    final db = await database;

    final templates = await db.query('meal_templates', columns: ['id', 'items']);

    for (final template in templates) {
      final raw = template['items'] as String? ?? '[]';

      dynamic decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        continue;
      }
      if (decoded is! List) continue;

      final containsProduct =
      decoded.any((item) => item is Map && item['productId'] == productId);
      if (!containsProduct) continue;

      await _recalculateTemplateNutrition(db, template['id'] as String);
    }
  }

  // ==========================================================================
  // NUTRITION AUDIT
  // ==========================================================================

  Future<List<Map<String, dynamic>>> auditNutritionValues() async {
    final db = await database;
    final rows = await db.query('food_products', orderBy: 'name COLLATE NOCASE ASC');

    final suspicious = <Map<String, dynamic>>[];

    for (final row in rows) {
      final calories = (row['calories'] as num?)?.toDouble() ?? 0;
      final protein = (row['protein'] as num?)?.toDouble() ?? 0;
      final fat = (row['fat'] as num?)?.toDouble() ?? 0;
      final carbs = (row['carbs'] as num?)?.toDouble() ?? 0;

      if (calories <= 0 && protein == 0 && fat == 0 && carbs == 0) continue;

      final macroCalories = protein * 4 + fat * 9 + carbs * 4;
      if (calories <= 0 || macroCalories <= 0) continue;

      final relativeDifference =
          (calories - macroCalories).abs() / macroCalories;

      if (relativeDifference > 0.20) {
        suspicious.add({
          'id': row['id'],
          'name': row['name'],
          'calories': calories,
          'macroCalories': macroCalories,
          'differencePercent': relativeDifference * 100,
          'protein': protein,
          'fat': fat,
          'carbs': carbs,
        });
      }
    }

    return suspicious;
  }

  // ==========================================================================
  // INDEXES
  // ==========================================================================

  Future<void> _createIndexes(DatabaseExecutor db) async {
    try {
      // Обычные индексы — безопасны всегда.
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_products_category
        ON food_products(category)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_products_custom
        ON food_products(isCustom)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_products_favorite
        ON food_products(isFavorite)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_diary_date
        ON food_diary(date)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_diary_product
        ON food_diary(productId)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_diary_template
        ON food_diary(templateId)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_water_date
        ON water_entries(date)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_templates_name_norm
        ON meal_templates(nameNormalized)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_products_name_norm
        ON food_products(nameNormalized)
      ''');

      // Уникальные — только по nameNormalized.
      // К моменту вызова мы уже прогнали дедупликацию, дублей нет.
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_products_unique_name_norm
        ON food_products(nameNormalized)
      ''');
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_templates_unique_name_norm
        ON meal_templates(nameNormalized)
      ''');
    } catch (e) {
      debugPrint('⚠️ Ошибка создания индексов: $e');
    }
  }

  // ==========================================================================
  // DEFAULT GOALS
  // ==========================================================================

  Future<void> _seedDefaultGoals(DatabaseExecutor db) async {
    final count = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM nutrition_goals',
    );
    final existing = (count.first['count'] as num?)?.toInt() ?? 0;
    if (existing > 0) return;

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

    debugPrint('✅ Созданы дефолтные цели питания');
  }

  // ==========================================================================
  // CRUD
  // ==========================================================================

  Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;

    final payload = Map<String, dynamic>.from(data);

    // Автоматически проставляем нормализованное имя, если есть name.
    if (!payload.containsKey('nameNormalized') &&
        payload.containsKey('name')) {
      final name = payload['name'] as String? ?? '';
      payload['nameNormalized'] = _normalizeName(name);
    }

    await db.insert(
      table,
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (table == 'food_products') {
      final id = payload['id'];
      final isCustom = (payload['isCustom'] as num?)?.toInt() ?? 0;

      // Для кастомных продуктов, на которые ещё никто не ссылается,
      // пересчёт не нужен. Для остальных — да.
      if (id is String && id.isNotEmpty && isCustom == 0) {
        await refreshTemplatesForProduct(id);
      }
    }

    if (table == 'meal_templates') {
      final id = payload['id'];
      if (id is String && id.isNotEmpty) {
        await _recalculateTemplateNutrition(db, id);
      }
    }
  }

  Future<List<Map<String, dynamic>>> query(
      String table, {
        String? where,
        List<Object?>? whereArgs,
        String? orderBy,
        int? limit,
      }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
      String table,
      Map<String, dynamic> values, {
        String? where,
        List<Object?>? whereArgs,
      }) async {
    final db = await database;

    final payload = Map<String, dynamic>.from(values);
    if (!payload.containsKey('nameNormalized') &&
        payload.containsKey('name')) {
      final name = payload['name'] as String? ?? '';
      payload['nameNormalized'] = _normalizeName(name);
    }

    final result = await db.update(
      table,
      payload,
      where: where,
      whereArgs: whereArgs,
    );

    if (table == 'food_products' &&
        result > 0 &&
        where == 'id = ?' &&
        whereArgs != null &&
        whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      if (id is String && id.isNotEmpty) {
        await refreshTemplatesForProduct(id);
      }
    }

    if (table == 'meal_templates' &&
        result > 0 &&
        where == 'id = ?' &&
        whereArgs != null &&
        whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      if (id is String && id.isNotEmpty) {
        await _recalculateTemplateNutrition(db, id);
      }
    }

    return result;
  }

  Future<int> delete(
      String table, {
        String? where,
        List<Object?>? whereArgs,
      }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }
}