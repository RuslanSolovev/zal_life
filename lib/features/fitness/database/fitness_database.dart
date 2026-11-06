import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/enums.dart';

import '../data/exercise_default_images.dart';

class FitnessDatabase {
  static final FitnessDatabase _instance = FitnessDatabase._internal();
  static Database? _database;

  FitnessDatabase._internal();

  factory FitnessDatabase() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> deleteDatabaseFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'fitness_app.db');
    try {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
      final dbFile = File(path);
      if (await dbFile.exists()) await dbFile.delete();
      final walFile = File('$path-wal');
      if (await walFile.exists()) await walFile.delete();
      final shmFile = File('$path-shm');
      if (await shmFile.exists()) await shmFile.delete();
      debugPrint('✅ Все файлы БД фитнеса очищены');
    } catch (e) {
      debugPrint('⚠️ Ошибка удаления БД фитнеса: $e');
    }
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'fitness_app.db');
    return await openDatabase(
      path,
      version: 20,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('📦 Создание базы фитнеса версии $version');

    await db.execute('''CREATE TABLE exercises (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT DEFAULT '',
      muscleGroups TEXT DEFAULT '[]', imageUrl TEXT, exerciseType TEXT DEFAULT 'strength',
      isCustom INTEGER DEFAULT 0, videoUrl TEXT, techniqueTips TEXT, commonMistakes TEXT,
      createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL,
      defaultFormat TEXT
    )''');

    await db.execute('''CREATE TABLE workout_programs (
  id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT DEFAULT 'weekly',
  days TEXT DEFAULT '[]', templateName TEXT, description TEXT,
  createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL,
  emoji TEXT DEFAULT '💪',
  accentColorValue INTEGER DEFAULT 4294929975,
  difficulty TEXT DEFAULT 'medium',
  goal TEXT DEFAULT 'general',
  sessionDurationMinutes INTEGER DEFAULT 60,
  backgroundImage TEXT
)''');

    await db.execute('''CREATE TABLE workout_days (
      id TEXT PRIMARY KEY, programId TEXT NOT NULL, dayNumber INTEGER DEFAULT 1,
      date TEXT, exercises TEXT DEFAULT '[]', isRestDay INTEGER DEFAULT 0,
      notes TEXT, status TEXT DEFAULT 'pending',
      FOREIGN KEY (programId) REFERENCES workout_programs(id) ON DELETE CASCADE
    )''');

    await db.execute('''CREATE TABLE workout_logs (
      id TEXT PRIMARY KEY, date TEXT NOT NULL, programId TEXT, dayNumber INTEGER,
      status TEXT DEFAULT 'completed', comment TEXT, startTime TEXT, endTime TEXT,
      exercisesLog TEXT DEFAULT '[]', totalRestTime INTEGER, totalVolume REAL,
      avgRpe REAL, bodyWeight TEXT, createdAt TEXT NOT NULL,
      moodEnergy INTEGER, moodSleep INTEGER, moodMotivation INTEGER,
      moodNotes TEXT, workoutPhotoPath TEXT,
      totalByMetric TEXT
    )''');

    await db.execute('''CREATE TABLE progress_records (
      id TEXT PRIMARY KEY, exerciseId TEXT NOT NULL, date TEXT NOT NULL,
      bestWeight REAL DEFAULT 0.0, bestReps INTEGER DEFAULT 0,
      estimated1RM REAL DEFAULT 0.0, totalVolume REAL DEFAULT 0.0,
      totalSets INTEGER DEFAULT 0, avgRpe REAL,
      bestDistance REAL, bestPace REAL, bestDuration INTEGER,
      bestRounds INTEGER, bestHoldSeconds INTEGER,
      FOREIGN KEY (exerciseId) REFERENCES exercises(id) ON DELETE CASCADE
    )''');

    await db.execute('''CREATE TABLE user_fitness_profile (
      id TEXT PRIMARY KEY, name TEXT DEFAULT 'Атлет', avatarUrl TEXT,
      bodyWeightHistory TEXT DEFAULT '[]', goal TEXT DEFAULT 'general',
      level TEXT DEFAULT 'intermediate', gender TEXT DEFAULT 'male',
      height REAL, age INTEGER, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE workout_templates (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT DEFAULT '',
      type TEXT DEFAULT 'weekly', days TEXT DEFAULT '[]',
      category TEXT DEFAULT 'custom', recommendedLevel TEXT DEFAULT 'intermediate'
    )''');

    await db.execute('''CREATE TABLE fitness_photos (
      id TEXT PRIMARY KEY, date TEXT NOT NULL, imageUrl TEXT NOT NULL,
      label TEXT, weight REAL, notes TEXT, createdAt TEXT NOT NULL,
      chest REAL, waist REAL, hips REAL, biceps REAL,
      thigh REAL, calf REAL, neck REAL, forearm REAL
    )''');

    await db.execute('''CREATE TABLE wellbeing_notes (
      id TEXT PRIMARY KEY, date TEXT NOT NULL, energyLevel INTEGER DEFAULT 5,
      sleepQuality INTEGER DEFAULT 5, motivationLevel INTEGER DEFAULT 5,
      painAreas TEXT DEFAULT '[]', notes TEXT, createdAt TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE program_sessions (
      id TEXT PRIMARY KEY,
      programId TEXT NOT NULL,
      startDate TEXT NOT NULL,
      endDate TEXT,
      currentDayIndex INTEGER DEFAULT 0,
      difficulty TEXT DEFAULT 'standard',
      status TEXT DEFAULT 'active',
      daySessions TEXT DEFAULT '[]',
      streak INTEGER DEFAULT 0,
      longestStreak INTEGER DEFAULT 0,
      totalVolumeCompleted REAL DEFAULT 0,
      totalWorkoutsCompleted INTEGER DEFAULT 0,
      totalWorkoutsSkipped INTEGER DEFAULT 0,
      averageRpe REAL DEFAULT 0,
      completedAt TEXT,
      summaryData TEXT DEFAULT '{}',
      totalByMetricCompleted TEXT DEFAULT '{}',
      FOREIGN KEY (programId) REFERENCES workout_programs(id) ON DELETE CASCADE
    )''');

    await db.execute('''CREATE TABLE fitness_targets (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT DEFAULT '',
      type TEXT NOT NULL,
      exerciseId TEXT,
      targetValue REAL NOT NULL,
      currentValue REAL DEFAULT 0,
      startValue REAL DEFAULT 0,
      unit TEXT NOT NULL,
      deadline TEXT,
      createdAt TEXT NOT NULL,
      completedAt TEXT,
      status TEXT DEFAULT 'active',
      accentColor INTEGER DEFAULT 4294929975,
      extra TEXT DEFAULT '{}',
      entries TEXT DEFAULT '[]'
    )''');

    await _createIndexes(db);
    await _seedDefaultExercises(db);
    await _seedDefaultTemplates(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Миграция фитнес БД: $oldVersion → $newVersion');
    try {
      if (oldVersion < 2) {
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final tableNames = tables.map((t) => t['name'] as String).toList();
        if (!tableNames.contains('fitness_photos')) {
          await db.execute('''CREATE TABLE fitness_photos (
          id TEXT PRIMARY KEY, date TEXT NOT NULL, imageUrl TEXT NOT NULL,
          label TEXT, weight REAL, notes TEXT, createdAt TEXT NOT NULL
        )''');
        }
        if (!tableNames.contains('wellbeing_notes')) {
          await db.execute('''CREATE TABLE wellbeing_notes (
          id TEXT PRIMARY KEY, date TEXT NOT NULL, energyLevel INTEGER DEFAULT 5,
          sleepQuality INTEGER DEFAULT 5, motivationLevel INTEGER DEFAULT 5,
          painAreas TEXT DEFAULT '[]', notes TEXT, createdAt TEXT NOT NULL
        )''');
        }
        if (!tableNames.contains('workout_templates')) {
          await db.execute('''CREATE TABLE workout_templates (
          id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT DEFAULT '',
          type TEXT DEFAULT 'weekly', days TEXT DEFAULT '[]',
          category TEXT DEFAULT 'custom', recommendedLevel TEXT DEFAULT 'intermediate'
        )''');
          await _seedDefaultTemplates(db);
        }
      }

      if (oldVersion < 3) {
        await _seedDefaultTemplates(db);
      }

      if (oldVersion < 4) {
        debugPrint('🔧 v4: Пересоздаём шаблоны с правильной сериализацией');
        await db.delete('workout_templates');
        await _seedDefaultTemplates(db);
      }

      if (oldVersion < 5) {
        debugPrint('🔧 v5: Добавляем обхваты тела в fitness_photos');
        final columns = await db.rawQuery('PRAGMA table_info(fitness_photos)');
        final columnNames = columns.map((c) => c['name'] as String).toList();
        final newColumns = {
          'chest': 'REAL', 'waist': 'REAL', 'hips': 'REAL', 'biceps': 'REAL',
          'thigh': 'REAL', 'calf': 'REAL', 'neck': 'REAL', 'forearm': 'REAL',
        };
        for (final entry in newColumns.entries) {
          if (!columnNames.contains(entry.key)) {
            try {
              await db.execute('ALTER TABLE fitness_photos ADD COLUMN ${entry.key} ${entry.value}');
              debugPrint('  ✅ Добавлен столбец: ${entry.key}');
            } catch (e) {
              debugPrint('  ⚠️ Ошибка добавления ${entry.key}: $e');
            }
          }
        }
      }

      if (oldVersion < 6) {
        debugPrint('🔧 v6: Добавляем настроение и фото в workout_logs');
        final columns = await db.rawQuery('PRAGMA table_info(workout_logs)');
        final columnNames = columns.map((c) => c['name'] as String).toList();
        final newColumns = {
          'moodEnergy': 'INTEGER', 'moodSleep': 'INTEGER', 'moodMotivation': 'INTEGER',
          'moodNotes': 'TEXT', 'workoutPhotoPath': 'TEXT',
        };
        for (final entry in newColumns.entries) {
          if (!columnNames.contains(entry.key)) {
            try {
              await db.execute('ALTER TABLE workout_logs ADD COLUMN ${entry.key} ${entry.value}');
              debugPrint('  ✅ Добавлен столбец: ${entry.key}');
            } catch (e) {
              debugPrint('  ⚠️ Ошибка добавления ${entry.key}: $e');
            }
          }
        }
      }

      if (oldVersion < 7) {
        debugPrint('🔧 v7: Добавляем таблицу program_sessions');
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final tableNames = tables.map((t) => t['name'] as String).toList();
        if (!tableNames.contains('program_sessions')) {
          await db.execute('''CREATE TABLE program_sessions (
            id TEXT PRIMARY KEY, programId TEXT NOT NULL,
            startDate TEXT NOT NULL, endDate TEXT,
            currentDayIndex INTEGER DEFAULT 0, difficulty TEXT DEFAULT 'standard',
            status TEXT DEFAULT 'active', daySessions TEXT DEFAULT '[]',
            streak INTEGER DEFAULT 0, longestStreak INTEGER DEFAULT 0,
            totalVolumeCompleted REAL DEFAULT 0,
            totalWorkoutsCompleted INTEGER DEFAULT 0,
            totalWorkoutsSkipped INTEGER DEFAULT 0,
            averageRpe REAL DEFAULT 0, completedAt TEXT,
            summaryData TEXT DEFAULT '{}'
          )''');
          debugPrint('  ✅ Таблица program_sessions создана');
        }
      }

      if (oldVersion < 8) {
        debugPrint('🔧 v8: Добавляем таблицу fitness_targets');
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final tableNames = tables.map((t) => t['name'] as String).toList();
        if (!tableNames.contains('fitness_targets')) {
          await db.execute('''CREATE TABLE fitness_targets (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT DEFAULT '',
            type TEXT NOT NULL, exerciseId TEXT,
            targetValue REAL NOT NULL, currentValue REAL DEFAULT 0,
            startValue REAL DEFAULT 0, unit TEXT NOT NULL, deadline TEXT,
            createdAt TEXT NOT NULL, completedAt TEXT,
            status TEXT DEFAULT 'active', accentColor INTEGER DEFAULT 4294929975,
            extra TEXT DEFAULT '{}'
          )''');
          debugPrint('  ✅ Таблица fitness_targets создана');
        }
      }

      if (oldVersion < 9) {
        debugPrint('🔧 v9: Добавляем колонку entries в fitness_targets');
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final tableNames = tables.map((t) => t['name'] as String).toList();
        if (tableNames.contains('fitness_targets')) {
          final columns = await db.rawQuery('PRAGMA table_info(fitness_targets)');
          final columnNames = columns.map((c) => c['name'] as String).toList();
          if (!columnNames.contains('entries')) {
            try {
              await db.execute("ALTER TABLE fitness_targets ADD COLUMN entries TEXT DEFAULT '[]'");
              debugPrint('  ✅ Колонка entries добавлена в fitness_targets');
            } catch (e) {
              debugPrint('  ⚠️ Ошибка добавления колонки entries: $e');
            }
          }
        }
      }

      if (oldVersion < 10) {
        debugPrint('🔧 v10: Добавляем новые поля в workout_programs');
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final tableNames = tables.map((t) => t['name'] as String).toList();
        if (tableNames.contains('workout_programs')) {
          final columns = await db.rawQuery('PRAGMA table_info(workout_programs)');
          final columnNames = columns.map((c) => c['name'] as String).toList();
          final newColumns = {
            'emoji': "TEXT DEFAULT '💪'",
            'accentColorValue': 'INTEGER DEFAULT 4294929975',
            'difficulty': "TEXT DEFAULT 'medium'",
            'goal': "TEXT DEFAULT 'general'",
            'sessionDurationMinutes': 'INTEGER DEFAULT 60',
          };
          for (final entry in newColumns.entries) {
            if (!columnNames.contains(entry.key)) {
              try {
                await db.execute("ALTER TABLE workout_programs ADD COLUMN ${entry.key} ${entry.value}");
                debugPrint('  ✅ Колонка ${entry.key} добавлена в workout_programs');
              } catch (e) {
                debugPrint('  ⚠️ Ошибка добавления ${entry.key}: $e');
              }
            }
          }
        }
      }

      if (oldVersion < 11) {
        debugPrint('🔧 v11: Обновляем базу упражнений до 60 шт и программ до 10');
        try {
          final deleted = await db.delete('exercises', where: 'isCustom = ?', whereArgs: [0]);
          debugPrint('  🗑️ Удалено $deleted стандартных упражнений');
        } catch (e) {
          debugPrint('  ⚠️ Ошибка удаления стандартных упражнений: $e');
        }
        for (int i = 1; i <= 30; i++) {
          final id = 'ex_default_${i.toString().padLeft(3, '0')}';
          try {
            await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
          } catch (_) {}
        }
        await _seedDefaultExercises(db);
        await db.delete('workout_templates');
        await _seedDefaultTemplates(db);
        debugPrint('  ✅ База обновлена до v11 (пользовательские упражнения сохранены)');
      }

      if (oldVersion < 12) {
        debugPrint('🔧 v12: Расширяем базу упражнений до 100');
        try {
          final deleted = await db.delete('exercises', where: 'isCustom = ?', whereArgs: [0]);
          debugPrint('  🗑️ Удалено $deleted стандартных упражнений');
        } catch (e) {
          debugPrint('  ⚠️ Ошибка удаления стандартных упражнений: $e');
        }
        await _seedDefaultExercises(db);
        debugPrint('  ✅ База обновлена до v12 (100 упражнений, пользовательские сохранены)');
      }

      if (oldVersion < 13) {
        debugPrint('🔧 v13: Расширяем базу упражнений до 130 и программ до 15');
        try {
          final deleted = await db.delete('exercises', where: 'isCustom = ?', whereArgs: [0]);
          debugPrint('  🗑️ Удалено $deleted стандартных упражнений');
        } catch (e) {
          debugPrint('  ⚠️ Ошибка удаления стандартных упражнений: $e');
        }
        await _seedDefaultExercises(db);
        await db.delete('workout_templates');
        await _seedDefaultTemplates(db);
        debugPrint('  ✅ База обновлена до v13 (130 упражнений, 15 программ)');
      }

      if (oldVersion < 14) {
        debugPrint('🔧 v14: Расширяем описания, советы по технике и типичные ошибки');
        try {
          final deleted = await db.delete('exercises', where: 'isCustom = ?', whereArgs: [0]);
          debugPrint('  🗑️ Удалено $deleted стандартных упражнений');
        } catch (e) {
          debugPrint('  ⚠️ Ошибка удаления стандартных упражнений: $e');
        }
        await _seedDefaultExercises(db);
        debugPrint('  ✅ База обновлена до v14 (подробные описания всех упражнений)');
      }

      // 🔥 v15: Углублённые описания (5–8 предложений), 10–12 советов по технике и 10–12 ошибок
      if (oldVersion < 15) {
        debugPrint('🔧 v15: Максимально подробные описания, 10–12 советов и 10–12 ошибок для каждого упражнения');

        try {
          final deleted = await db.delete('exercises', where: 'isCustom = ?', whereArgs: [0]);
          debugPrint('  🗑️ Удалено $deleted стандартных упражнений');
        } catch (e) {
          debugPrint('  ⚠️ Ошибка удаления стандартных упражнений: $e');
        }

        await _seedDefaultExercises(db);
        debugPrint('  ✅ База обновлена до v15 (максимальная детализация всех 130 упражнений)');
      }

      // 🔥 v16: Формат-зависимые метрики (кардио / бокс / статика)
      if (oldVersion < 16) {
        debugPrint('🔧 v16: Добавляем format-метрики (кардио/бокс/статика)');

        // 1. exercises — формат по умолчанию (опционально для каждого упражнения)
        await _safeAddColumn(db, 'exercises', 'defaultFormat', 'TEXT');

        // 2. progress_records — метрики для не-силовых форматов
        await _safeAddColumn(db, 'progress_records', 'bestDistance', 'REAL');
        await _safeAddColumn(db, 'progress_records', 'bestPace', 'REAL');
        await _safeAddColumn(db, 'progress_records', 'bestDuration', 'INTEGER');
        await _safeAddColumn(db, 'progress_records', 'bestRounds', 'INTEGER');
        await _safeAddColumn(db, 'progress_records', 'bestHoldSeconds', 'INTEGER');

        // 3. workout_logs — JSON со суммой по метрикам
        await _safeAddColumn(db, 'workout_logs', 'totalByMetric', 'TEXT');

        // 4. program_sessions — то же, но за всю сессию
        await _safeAddColumn(
          db,
          'program_sessions',
          'totalByMetricCompleted',
          "TEXT DEFAULT '{}'",
        );

        // 🆕 5. Проставляем defaultFormat для нетипичных стандартных упражнений
        //    (планка, вакуум, скакалки, спринты, фермерская прогулка и т.д.)
        final formatUpdates = <String, String>{
          'ex_default_022': 'hold',       // Планка
          'ex_default_051': 'hold',       // Боковая планка
          'ex_default_052': 'hold',       // Вакуум живота
          'ex_default_053': 'timedSets',  // Ножницы ногами
          'ex_default_054': 'timedSets',  // Прыжки на скакалке
          'ex_default_089': 'timedSets',  // Альпинист
          'ex_default_095': 'timedSets',  // Прыжки через скакалку двойные
          'ex_default_099': 'timedSets',  // Фермерская прогулка
          'ex_default_125': 'timedSets',  // Скакалка с высокими коленями
          'ex_default_126': 'intervals',  // Спринт-интервалы
          'ex_default_127': 'timedSets',  // Джампинг Джек
        };

        int patched = 0;
        for (final entry in formatUpdates.entries) {
          try {
            final updated = await db.update(
              'exercises',
              {'defaultFormat': entry.value},
              where: 'id = ? AND isCustom = 0',
              whereArgs: [entry.key],
            );
            if (updated > 0) patched++;
          } catch (e) {
            debugPrint('  ⚠️ ${entry.key}: $e');
          }
        }
        debugPrint('  ✅ defaultFormat проставлен для $patched/${formatUpdates.length} упражнений');

        debugPrint('  ✅ Миграция v16 завершена (все колонки nullable — старые данные работают без изменений)');
      }

      // 🔥 v17: Гарантируем defaultFormat для всех стандартных упражнений
      //   После v16 defaultFormat проставлен только у ~11 нетипичных упражнений.
      //   Остальные (~115) полагаются на fallback defaultFormatByType[type],
      //   но это хрупко: inferFormatFromName в helpers.dart для них не вызывается.
      //   Явно фиксируем формат в БД, чтобы будущие правки helpers.dart не ломали поведение.
      if (oldVersion < 17) {
        debugPrint('🔧 v17: Заполняем defaultFormat для всех упражнений без него');

        try {
          final rows = await db.query(
            'exercises',
            where: "isCustom = 0 AND (defaultFormat IS NULL OR defaultFormat = '')",
          );
          debugPrint('  🔍 Найдено ${rows.length} упражнений без defaultFormat');

          int fixed = 0;
          for (final row in rows) {
            final id = row['id'] as String;
            final name = (row['name'] as String?) ?? '';
            final typeStr = (row['exerciseType'] as String?) ?? 'strength';

            final exerciseType = ExerciseType.values.firstWhere(
                  (t) => t.name == typeStr,
              orElse: () => ExerciseType.strength,
            );
            final format = exerciseType.inferFormatFromName(name);

            try {
              await db.update(
                'exercises',
                {'defaultFormat': format.name},
                where: 'id = ?',
                whereArgs: [id],
              );
              fixed++;
            } catch (e) {
              debugPrint('  ⚠️ Ошибка для $id: $e');
            }
          }
          debugPrint('  ✅ defaultFormat проставлен для $fixed/${rows.length}');
        } catch (e) {
          debugPrint('  ⚠️ Ошибка v17: $e');
        }

        debugPrint('  ✅ Миграция v17 завершена');
      }

      // 🔥 v18: Добавляем колонку backgroundImage в workout_programs
      if (oldVersion < 18) {
        debugPrint('🔧 v18: Добавляем колонку backgroundImage в workout_programs');
        await _safeAddColumn(db, 'workout_programs', 'backgroundImage', 'TEXT');
        debugPrint('  ✅ Миграция v18 завершена');
      }

      // 🔥 v19: проставляем imageUrl всем стандартным упражнениям
      if (oldVersion < 19) {
        debugPrint('🔧 v19: проставляем изображения стандартным упражнениям');
        try {
          final count = await applyDefaultExerciseImages(db);
          debugPrint('  ✅ imageUrl обновлён у $count упражнений');
        } catch (e) {
          debugPrint('  ⚠️ Ошибка v19: $e');
        }
      }

      // 🔥 v21: принудительно ставим локальные assets
      if (oldVersion < 20) {
        debugPrint('🔧 v21: ставим локальные assets');
        try {
          // 1. Стираем все старые сетевые ссылки у стандартных упражнений
          await db.update('exercises', {'imageUrl': null}, where: 'isCustom = 0');

          // 2. Проставляем локальные пути (1.jpg - 45.jpg)
          final filled = await applyDefaultExerciseImages(db);
          debugPrint('  ✅ Проставлено локальных картинок: $filled');
        } catch (e) {
          debugPrint('  ⚠️ Ошибка v21: $e');
        }
      }

    } catch (e) {
      debugPrint('⚠️ Ошибка миграции фитнес БД: $e');
    }
    await _createIndexes(db);
  }

  // ============================================================
  // 🆕 v16: Идемпотентное добавление колонки
  // ============================================================

  /// Безопасно добавляет колонку:
  /// - не падает, если таблицы нет (пропускает с логом)
  /// - не падает, если колонка уже есть (сообщает и выходит)
  /// - в случае ошибки ALTER TABLE — только лог, миграция продолжается
  Future<void> _safeAddColumn(
      Database db,
      String table,
      String column,
      String type,
      ) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table],
      );
      if (tables.isEmpty) {
        debugPrint('  ⚠️ [$table.$column] таблица не найдена — пропуск');
        return;
      }

      final columns = await db.rawQuery('PRAGMA table_info($table)');
      final names = columns.map((c) => c['name'] as String).toList();
      if (names.contains(column)) {
        debugPrint('  ✓ [$table.$column] уже существует');
        return;
      }

      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
      debugPrint('  ✅ Добавлено: $table.$column ($type)');
    } catch (e) {
      debugPrint('  ⚠️ Ошибка добавления $table.$column: $e');
    }
  }

  Future<void> _createIndexes(Database db) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_exercises_type ON exercises(exerciseType)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_exercises_custom ON exercises(isCustom)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_workout_days_program ON workout_days(programId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_workout_days_date ON workout_days(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_workout_logs_date ON workout_logs(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_workout_logs_program ON workout_logs(programId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_progress_exercise ON progress_records(exerciseId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_progress_date ON progress_records(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_fitness_photos_date ON fitness_photos(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_wellbeing_date ON wellbeing_notes(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_program_sessions_status ON program_sessions(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_program_sessions_program ON program_sessions(programId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_program_sessions_start ON program_sessions(startDate)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_fitness_targets_status ON fitness_targets(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_fitness_targets_type ON fitness_targets(type)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_fitness_targets_exercise ON fitness_targets(exerciseId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_fitness_targets_created ON fitness_targets(createdAt)');
    } catch (e) {
      debugPrint('⚠️ Ошибка создания индексов фитнес: $e');
    }
  }

  // ==================== УПРАЖНЕНИЯ (130 шт) ====================

  Future<void> _seedDefaultExercises(Database db) async {
    final existingDefault = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: ['ex_default_001'],
      limit: 1,
    );

    if (existingDefault.isNotEmpty) {
      final allDefaults = await db.query(
        'exercises',
        where: 'isCustom = ?',
        whereArgs: [0],
      );
      if (allDefaults.length >= 130) {
        debugPrint('📦 Все 130 дефолтных упражнений уже есть, пропускаем');
        return;
      }
      debugPrint('⚠️ Найдено ${allDefaults.length}/130 дефолтных, дополняем...');
    } else {
      debugPrint('🌱 Заполняем базу начальными упражнениями (130 шт)...');
    }

    final now = DateTime.now().toIso8601String();

    final defaultExercises = [
      // ============================================================
      // ГРУДЬ (CHEST) — 8
      // ============================================================
      {
        'id': 'ex_default_001',
        'name': 'Жим штанги лёжа',
        'description': 'Жим штанги лёжа — фундаментальное многосуставное упражнение, образующее ядро практически любой программы тренировки верха тела, будь то бодибилдинг, пауэрлифтинг, кроссфит или оздоровительный фитнес. В движении участвует большая грудная мышца (ключичная, грудинная и рёберная части), передние пучки дельтовидных мышц, трицепсы, а также мышцы-стабилизаторы лопаток и кора. Упражнение позволяет работать с большими весами и служит основным индикатором силы жимового движения. Техника масштабируется под любой уровень: новички могут начинать с пустого грифа и отработки паттерна, опытные атлеты — работать с максимальными весами, варьируя хват, наклон, паузы и темп. Регулярное выполнение напрямую влияет на объём и плотность груди, силу верхней части тела и общую жимовую выносливость. Кроме того, жим штанги лёжа — это универсальный маркер прогресса, который легко отслеживать и сравнивать с нормативными значениями. Для безопасного прогресса критически важны сведение лопаток, нейтральная линия запястья и контроль траектории грифа.',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на скамью так, чтобы гриф оказался на уровне глаз, стопы полностью на полу, ягодицы и лопатки — плотно прижаты к скамье.\n'
            '2. Сведите и опустите лопатки, создавая «карман» и жёсткую платформу — это защищает плечевые суставы и добавляет силы жима.\n'
            '3. Сохраняйте естественный, но умеренный прогиб в пояснице, не отрывая таз от скамьи на протяжении всего подхода.\n'
            '4. Возьмите гриф чуть шире плеч так, чтобы предплечья в нижней точке были перпендикулярны полу.\n'
            '5. Держите запястья нейтрально (не разогнуты назад) — это снимает нагрузку с лучезапястного сустава.\n'
            '6. Локти под углом около 45–60° к корпусу — не разводите их строго в стороны и не прижимайте к туловищу.\n'
            '7. Опускайте штангу контролируемо за 2–3 секунды до линии сосков или чуть ниже, касаясь груди без отбива.\n'
            '8. В нижней точке сохраняйте напряжение в груди, не «проваливайте» плечи вперёд.\n'
            '9. Выжимайте гриф по лёгкой дуге от груди к голове, мысленно отталкивая скамью, а не поднимая гриф.\n'
            '10. В верхней точке оставляйте микро-изгиб в локтях и сохраняйте напряжение в грудных.\n'
            '11. Дышите: вдох при опускании, выдох при подъёме; задерживайте дыхание только коротко на самом тяжёлом участке.\n'
            '12. При работе с большими весами используйте страховку или помощь партнёра — это позволяет безопасно прогрессировать.',
        'commonMistakes': '1. Отрыв таза от скамьи — перегружает поясницу, снижает силу жима и повышает риск травмы.\n'
            '2. Сведение лопаток в верхней точке или в начале жима — «разваливает» опору и снижает стабильность.\n'
            '3. Слишком широкий хват — повышает риск травмы плечевого сустава и снижает вклад трицепса.\n'
            '4. Слишком узкий хват — перегружает трицепс и лучезапястные суставы.\n'
            '5. Отбивание штанги от груди — опасно для рёбер, хрящей и снижает рабочий вес в долгосрочной перспективе.\n'
            '6. Разведение локтей строго в стороны — перегружает передние дельты и плечевые суставы.\n'
            '7. Опускание штанги к шее или животу — смещает нагрузку и травмоопасно.\n'
            '8. Разгибание запястий назад — перегрузка лучезапястного сустава.\n'
            '9. Неполная амплитуда (не до груди или без полного выпрямления) — снижает эффект.\n'
            '10. Отсутствие разминки с пустым грифом — повышает риск травмы.\n'
            '11. Задержка дыхания на всё движение — повышает внутригрудное давление.\n'
            '12. Работа без страховки с максимальными весами — высокий риск.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_002',
        'name': 'Жим гантелей лёжа',
        'description': 'Жим гантелей лёжа — важное многосуставное упражнение для развития грудных мышц, передних дельт и трицепсов, которое даёт большую амплитуду по сравнению с жимом штанги. Каждая рука работает независимо, что помогает выявить и устранить мышечный дисбаланс, повышает требования к стабилизаторам и делает движение более безопасным для плеч. Гантели позволяют комфортно разворачивать кисти и подстраивать траекторию под индивидуальную анатомию, поэтому упражнение часто рекомендуют людям с чувствительными плечевыми суставами. По сравнению со штангой здесь сложнее работать с максимальными весами, зато проще контролировать растяжение грудных в нижней точке и пиковое сокращение в верхней. Жим гантелей отлично подходит как для гипертрофии, так и для силовой выносливости, а также используется как вспомогательное движение для улучшения жима штанги. Благодаря независимой работе рук вы учитесь держать баланс и включать стабилизаторы плечевого пояса, что положительно сказывается на общей технике жимовых движений.',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите гантели нейтральным хватом, сядьте на край скамьи, затем аккуратно откиньтесь назад, упираясь гантелями в бёдра.\n'
            '2. Лопатки сведены и опущены, стопы плотно на полу, корпус — единая жёсткая платформа.\n'
            '3. Держите гантели над грудью, ладони направлены вперёд или слегка внутрь — так комфортнее плечам.\n'
            '4. Опускайте гантели медленно по широкой дуге, пока не почувствуете комфортное растяжение в груди.\n'
            '5. В нижней точке локти находятся на уровне плеч или чуть ниже, но не уходят сильно назад.\n'
            '6. Не разводите локти строго в стороны — держите их под углом ~45–60° к корпусу.\n'
            '7. Выжимайте гантели вверх и слегка внутрь, но не сталкивайте их — сохраняйте напряжение в грудных.\n'
            '8. В верхней точке оставляйте небольшой изгиб в локтях и не «выключайте» грудь.\n'
            '9. Контролируйте симметрию — обе гантели должны двигаться синхронно.\n'
            '10. Держите запястья нейтрально, не разгибайте их назад.\n'
            '11. Дышите: вдох при опускании, выдох при подъёме.\n'
            '12. При больших весах используйте помощь партнёра для подачи и страховки.',
        'commonMistakes': '1. Слишком большой вес — теряется контроль, амплитуда и техника.\n'
            '2. Разведение гантелей в стороны на прямых руках — опасно для плечевых суставов.\n'
            '3. Опускание гантелей слишком глубоко с разворотом плеч внутрь — риск травмы.\n'
            '4. Раскачивание корпусом для помощи жиму — перегружает поясницу.\n'
            '5. Сведение гантелей в верхней точке — снимает напряжение с грудных.\n'
            '6. Слишком быстрый негатив — теряется растяжение и контроль.\n'
            '7. Асимметричная работа рук — одна рука «тащит» другую, формируя дисбаланс.\n'
            '8. Отрыв таза или лопаток от скамьи — потеря стабильности.\n'
            '9. Разгибание запястий назад — перегрузка лучезапястных суставов.\n'
            '10. Неполная амплитуда — снижает эффект.\n'
            '11. Слишком быстрый темп — теряется контроль.\n'
            '12. Отсутствие разминки плеч — риск травмы.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_003',
        'name': 'Разведение гантелей',
        'description': 'Разведение гантелей лёжа — классическое изолирующее упражнение для грудных мышц, которое акцентированно растягивает их в нижней точке и сводит в верхней. Это упражнение идеально подходит как «добивка» после жимов: оно помогает добиться пампа, дополнительной стимуляции мышечных волокон и лучшего ощущения грудных. Плечо работает практически в полную амплитуду без активного участия трицепса, поэтому рабочий вес здесь существенно ниже, чем в жимах. Правильная техника с фиксированным лёгким изгибом локтей и контролируемым темпом делает его безопасным даже для людей с чувствительными плечами. Упражнение отлично сочетается с жимами штанги и гантелей, а также с кроссовером. Разведение развивает не столько силу, сколько форму, объём и «отстающую» внутреннюю часть груди, поэтому часто используется в гипертрофийных программах.',
        'muscleGroups': '["chest"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на горизонтальную скамью, стопы на полу, лопатки сведены и опущены.\n'
            '2. Держите гантели над грудью на слегка согнутых руках — лёгкий изгиб в локтях фиксирован на всё движение.\n'
            '3. Опускайте гантели по широкой дуге в стороны, пока не почувствуете комфортное растяжение грудных.\n'
            '4. В нижней точке локти на уровне плеч или чуть ниже, предплечья почти параллельны полу.\n'
            '5. Не уводите плечи слишком далеко назад — это травмоопасно для суставов.\n'
            '6. Сводите гантели обратно по той же дуге, мысленно «обнимая большое дерево».\n'
            '7. В верхней точке сводите гантели, но не сталкивайте их и не выпрямляйте руки полностью.\n'
            '8. Работайте в умеренном темпе, концентрируясь на ощущении растяжения и сокращения грудных.\n'
            '9. Локти должны быть на одном уровне на протяжении всего движения — не поднимайте и не опускайте их.\n'
            '10. Запястья держите нейтрально, гантели параллельны друг другу.\n'
            '11. Дышите: вдох при опускании, выдох при сведении.\n'
            '12. Работайте с весом, который позволяет сделать 10–15 повторений с полным контролем.',
        'commonMistakes': '1. Полностью выпрямленные руки — нагрузка уходит в плечи и локтевые суставы.\n'
            '2. Слишком тяжёлые гантели — теряется контроль, упражнение превращается в жим.\n'
            '3. Слишком быстрый темп — отсутствует пиковое сокращение и растяжение.\n'
            '4. Сведение лопаток и прогиб в пояснице — перегрузка спины.\n'
            '5. Опускание гантелей слишком глубоко — риск травмы плеч.\n'
            '6. Сгибание-разгибание локтей во время движения — превращает разводку в жим.\n'
            '7. Отрыв таза от скамьи для помощи — снижает стабильность.\n'
            '8. Подъём локтей выше плеч — перегрузка дельт.\n'
            '9. Столкновение гантелей в верхней точке — снижает напряжение.\n'
            '10. Слишком быстрый негатив — теряется растяжение.\n'
            '11. Работа с весом, не позволяющим полную амплитуду.\n'
            '12. Отсутствие разминки плеч — риск травмы.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_004',
        'name': 'Отжимания от пола',
        'description': 'Отжимания от пола — базовое упражнение с собственным весом, которое тренирует грудь, передние дельты и трицепсы, одновременно укрепляя кор и стабилизаторы. Доступно в любых условиях и легко масштабируется: от отжиманий с колен для новичков до отжиманий с отягощением или на нестабильной опоре для продвинутых. Это функциональное движение, которое напрямую переносится на жимовые результаты и общую физическую форму. Регулярное выполнение улучшает осанку, выносливость верхней части тела и учит правильно держать корпус в закрытой кинетической цепи. Отжимания отлично сочетаются с жимами и используются как разминочное, добивочное или самостоятельное упражнение. Для прогресса можно менять положение рук (широкая, узкая, «алмаз»), высоту опоры (ноги на скамье), темп и добавлять отягощение.',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Примите упор лёжа: ладони чуть шире плеч, пальцы направлены вперёд или слегка внутрь.\n'
            '2. Тело — прямая линия от пяток до макушки: пресс, ягодицы и бёдра напряжены, таз не провисает.\n'
            '3. Локти направлены под углом ~45° к корпусу — это защищает плечи и смещает нагрузку на грудь.\n'
            '4. Опускайтесь контролируемо, пока грудь почти не коснётся пола, не прогибая поясницу.\n'
            '5. В нижней точке лопатки сведены, грудь раскрыта — не «проваливайтесь» в плечи.\n'
            '6. Выжимайте равномерно, отталкиваясь всей ладонью, а не только пальцами.\n'
            '7. В верхней точке оставляйте микро-изгиб в локтях и сохраняйте напряжение в груди.\n'
            '8. Держите голову в нейтральном положении, взгляд чуть вперёд — не прижимайте подбородок к груди.\n'
            '9. Для облегчения ставьте колени на пол (но сохраняйте прямую линию от колен до макушки).\n'
            '10. Для усложнения положите ноги на скамью, добавьте отягощение или используйте нестабильную опору.\n'
            '11. Дышите: вдох при опускании, выдох при подъёме.\n'
            '12. Запястья держите нейтрально, при необходимости используйте упоры для отжиманий.',
        'commonMistakes': '1. Провисание поясницы или поднятый таз — нарушает технику и нагружает спину.\n'
            '2. Локти строго в стороны — риск травмы плеч и снижение вклада груди.\n'
            '3. Неполная амплитуда — снижает эффективность упражнения.\n'
            '4. Слишком быстрый темп без контроля — теряется напряжение и растёт риск травмы.\n'
            '5. Опускание головы к полу вместо груди — смещает нагрузку и нарушает линию тела.\n'
            '6. «Проваливание» в плечи в нижней точке — перегрузка суставов.\n'
            '7. Отталкивание только пальцами — слабая стабильность запястий.\n'
            '8. Слишком широкий хват — перегрузка плеч.\n'
            '9. Подъём таза вверх — снижает вклад груди.\n'
            '10. Слишком быстрый негатив — теряется растяжение.\n'
            '11. Разгибание запястий назад — перегрузка лучезапястных суставов.\n'
            '12. Отсутствие разминки плеч — риск травмы.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_031',
        'name': 'Жим гантелей на наклонной скамье',
        'description': 'Жим гантелей на наклонной скамье (30–45°) переносит акцент на верхнюю (ключичную) часть большой грудной мышцы — зону, которая часто отстаёт при горизонтальном жиме. Гантели позволяют работать в большей амплитуде и комфортнее для плеч, чем штанга, а также требуют активного включения стабилизаторов и учат держать симметрию. Упражнение отлично подходит как для набора массы, так и для формирования визуально «полной» груди. Правильный угол наклона — ключ к тому, чтобы нагрузка шла в грудь, а не в дельты. Как и другие жимы гантелей, это упражнение способствует устранению мышечного дисбаланса. Отлично сочетается с горизонтальным жимом и разводкой, а также с упражнениями на верх груди на блочных тренажёрах.',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Установите наклон скамьи 30–45° — это оптимум для верха груди.\n'
            '2. Сядьте, прижмите лопатки к скамье, стопы плотно на полу, корпус стабилен.\n'
            '3. Гантели держите на уровне верхней части груди, ладони вперёд или чуть внутрь.\n'
            '4. Опускайте гантели контролируемо к верхней части груди, локти под углом ~45–60° к корпусу.\n'
            '5. В нижней точке чувствуйте растяжение верхней части грудных, но не уходите слишком глубоко.\n'
            '6. Выжимайте гантели вверх и слегка внутрь, не сталкивая их в верхней точке.\n'
            '7. В верхней точке сохраняйте напряжение в груди, не выпрямляйте локти до конца.\n'
            '8. Не отрывайте таз и поясницу от скамьи — стабильность критически важна.\n'
            '9. Держите запястья нейтрально на протяжении всего движения.\n'
            '10. Следите за симметрией — обе гантели должны двигаться синхронно.\n'
            '11. Дышите: вдох при опускании, выдох при подъёме.\n'
            '12. Работайте с весом, который позволяет сделать 8–12 повторений с полным контролем.',
        'commonMistakes': '1. Слишком большой наклон (близко к вертикали) — работа переходит на дельты.\n'
            '2. Слишком маленький наклон — упражнение почти не отличается от горизонтального жима.\n'
            '3. Слишком тяжёлый вес — теряется контроль и амплитуда.\n'
            '4. Опускание гантелей к животу вместо верхней части груди — смещает нагрузку.\n'
            '5. Отрыв таза или поясницы от скамьи — потеря стабильности.\n'
            '6. Сведение гантелей в верхней точке — снижает напряжение в грудных.\n'
            '7. Слишком быстрый негатив — теряется растяжение.\n'
            '8. Разгибание запястий назад — перегрузка лучезапястных суставов.\n'
            '9. Асимметричная работа рук — формирует дисбаланс.\n'
            '10. Слишком большой вес без страховки.\n'
            '11. Отсутствие разминки плеч — риск травмы.\n'
            '12. Работа без полной амплитуды.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_032',
        'name': 'Сведение рук в кроссовере',
        'description': 'Сведение рук в кроссовере — изолирующее упражнение для грудных мышц на блочном тренажёре. Главное преимущество — постоянное натяжение на протяжении всей амплитуды, в отличие от свободных весов, где нагрузка «проваливается» в верхней и нижней точках. Это делает упражнение идеальным для пампинга, доработки формы груди и работы над средней линией. Кроссовер позволяет менять угол и высоту блоков, акцентируя верх, середину или низ груди, а также использовать различные рукоятки для комфорта запястий. Упражнение подходит и новичкам, и опытным атлетам, и отлично вписывается в конец тренировки груди. Постоянное натяжение также помогает лучше чувствовать целевую мышцу, что особенно полезно для людей, у которых грудь «не отзывается» на жимы. При правильной технике упражнение безопасно для плеч и позволяет комфортно контролировать амплитуду.',
        'muscleGroups': '["chest","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Установите блоки на нужную высоту (обычно чуть выше плеч) и возьмите рукоятки.\n'
            '2. Встаньте между блоками, одна нога впереди для устойчивости, корпус слегка наклонён вперёд.\n'
            '3. Локти чуть согнуты и зафиксированы на протяжении всего движения — не сгибайте и не разгибайте их.\n'
            '4. Сводите руки перед собой по дуге, делая паузу на пике сокращения на 1–2 секунды.\n'
            '5. В точке сведения кисти скрещиваются или почти соприкасаются — это усиливает сокращение.\n'
            '6. Возвращайте руки контролируемо, растягивая грудные, но не уводя плечи назад слишком далеко.\n'
            '7. Работайте в умеренном темпе, концентрируясь на ощущении работы грудных.\n'
            '8. Держите корпус стабильным, без раскачивания и помощи инерцией.\n'
            '9. Плечи опущены и отведены назад — не поднимайте их к ушам.\n'
            '10. Запястья держите нейтрально, рукоятки держите крепко, но без перенапряжения.\n'
            '11. Дышите: вдох при разведении, выдох при сведении.\n'
            '12. Для акцента на верх груди блоки ставьте ниже, для низа — выше.',
        'commonMistakes': '1. Использование инерции и раскачивание корпусом — снижает эффективность.\n'
            '2. Слишком большой вес — движение превращается в тягу, а не в сведение.\n'
            '3. Полное выпрямление рук в верхней точке — нагрузка уходит в плечи.\n'
            '4. Разведение рук слишком далеко назад — риск травмы плеч.\n'
            '5. Движение плечами вместо локтей — перегрузка дельт.\n'
            '6. Слишком быстрый темп — отсутствует пиковое сокращение.\n'
            '7. Округление спины в наклоне — перегрузка поясницы.\n'
            '8. Подъём плеч к ушам — перегрузка трапеций.\n'
            '9. Сгибание-разгибание локтей в движении — превращает упражнение в жим.\n'
            '10. Отсутствие паузы на пике сокращения.\n'
            '11. Слишком быстрый негатив — теряется растяжение.\n'
            '12. Работа без полной амплитуды.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_033',
        'name': 'Отжимания на брусьях (грудь)',
        'description': 'Отжимания на брусьях с наклоном корпуса вперёд — одно из лучших упражнений с собственным весом для нижней и средней части грудных. Смещение корпуса вперёд переключает нагрузку с трицепса на грудь и увеличивает амплитуду растяжения. Упражнение легко масштабируется дополнительным отягощением или резинкой, что позволяет прогрессировать как новичкам, так и опытным атлетам. Оно хорошо подходит как для набора массы, так и для силовой выносливости, однако требует подвижности плеч и уверенной техники. Отжимания на брусьях также сильно нагружают трицепс и передние дельты, поэтому важно контролировать наклон корпуса, чтобы акцентировать именно грудь. Это упражнение часто используется в кроссфите и функциональных тренировках, а также как эффективная замена жимам для людей с ограничениями по оборудованию.',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Возьмитесь за брусья, подтянитесь на прямых руках, плечи опущены и стабильны.\n'
            '2. Наклоните корпус вперёд на 20–30° — это включает грудные мышцы.\n'
            '3. Ноги держите сзади или подогнутыми, чтобы сохранить наклон.\n'
            '4. Локти разводите в стороны, а не прижимайте к корпусу — это акцент на грудь.\n'
            '5. Опускайтесь до ощущения растяжения в груди (обычно угол в локте ~90°), но без боли в плечах.\n'
            '6. Поднимайтесь контролируемо, отталкиваясь грудью, а не только руками.\n'
            '7. В верхней точке не блокируйте локти жёстко — оставляйте микро-изгиб.\n'
            '8. Плечи не поднимайте к ушам — держите их опущенными на протяжении всего движения.\n'
            '9. Запястья держите нейтрально, хват уверенный.\n'
            '10. Для облегчения используйте резинку или тренажёр с противовесом.\n'
            '11. Для усложнения добавьте отягощение на пояс.\n'
            '12. Дышите: вдох при опускании, выдох при подъёме.',
        'commonMistakes': '1. Вертикальное положение корпуса — работа переходит на трицепс.\n'
            '2. Слишком глубокое опускание — риск травмы плеч.\n'
            '3. Раскачивание и рывки — снижают контроль и эффективность.\n'
            '4. Неполная амплитуда в верхней части — грудь не работает в полном сокращении.\n'
            '5. Подъём плеч к ушам — перегрузка трапеций и шеи.\n'
            '6. Резкое разгибание локтей в верхней точке — риск перегрузки суставов.\n'
            '7. Отсутствие разминки плеч — высокий риск травмы.\n'
            '8. Слишком сильный наклон вперёд — перегрузка груди и передних дельт.\n'
            '9. Отсутствие контроля в нижней точке.\n'
            '10. Слишком быстрый темп без техники.\n'
            '11. Разгибание запястий назад — перегрузка лучезапястных суставов.\n'
            '12. Работа через боль в плечах.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_034',
        'name': 'Жим штанги на наклонной скамье',
        'description': 'Жим штанги на наклонной скамье — многосуставное упражнение, совмещающее преимущества классического жима лёжа и акцента на верхнюю (ключичную) часть грудных. Штанга позволяет работать с большими весами, чем гантели, что важно для силового и гипертрофийного прогресса. Наклон 30–45° перераспределяет нагрузку на ключичную часть большой грудной мышцы, а также включает передние дельты и трицепсы. Упражнение требует хорошей техники и контроля лопаток, особенно при работе с большими весами. Оно отлично подходит как основное жимовое движение в день груди для тех, у кого отстаёт верхняя часть. Как и классический жим лёжа, это упражнение требует страховки при работе с максимальными весами и хорошей разминки плечевых суставов.',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Установите наклон скамьи 30–45°, сядьте и прижмите лопатки к скамье.\n'
            '2. Стопы плотно на полу, таз не отрывается от скамьи.\n'
            '3. Хват чуть шире плеч, предплечья перпендикулярны полу в нижней точке.\n'
            '4. Опускайте штангу контролируемо к верхней части груди (ключицам) без отбива.\n'
            '5. Локти держите под углом ~45–60° к корпусу, не разводите строго в стороны.\n'
            '6. Выжимайте штангу по дуге от груди к голове, не теряя сведения лопаток.\n'
            '7. В верхней точке оставляйте микро-изгиб в локтях, сохраняя напряжение в груди.\n'
            '8. Держите запястья нейтрально, не разгибайте их назад.\n'
            '9. Не отрывайте таз и поясницу от скамьи.\n'
            '10. Дышите: вдох при опускании, выдох при подъёме.\n'
            '11. При больших весах используйте страховку или помощь партнёра.\n'
            '12. Начинайте с пустого грифа для разминки.',
        'commonMistakes': '1. Слишком большой вес — потеря техники и травмоопасность.\n'
            '2. Отрыв таза от скамьи — перегрузка поясницы.\n'
            '3. Слишком большой наклон — нагрузка уходит в дельты.\n'
            '4. Опускание штанги к животу вместо верха груди — смещает нагрузку.\n'
            '5. Разведение локтей строго в стороны — перегрузка плеч.\n'
            '6. Сведение лопаток в верхней точке — потеря стабильности.\n'
            '7. Отсутствие страховки при работе с большим весом — высокий риск.\n'
            '8. Слишком узкий или слишком широкий хват — перегрузка суставов.\n'
            '9. Разгибание запястий назад — перегрузка лучезапястных суставов.\n'
            '10. Неполная амплитуда.\n'
            '11. Отсутствие разминки плеч.\n'
            '12. Слишком быстрый негатив — теряется растяжение.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ============================================================
      // СПИНА (BACK) — 8
      // ============================================================
      {
        'id': 'ex_default_005',
        'name': 'Подтягивания',
        'description': 'Подтягивания — базовое упражнение с собственным весом для развития широчайших мышц спины, бицепсов и мышц-стабилизаторов лопаток. Это один из главных показателей силовой подготовки верхней части тела и неотъемлемая часть функционального тренинга. Подтягивания развивают не только силу, но и контроль над лопатками, что напрямую влияет на осанку и здоровье плечевых суставов. Упражнение легко масштабируется: от негативных подтягиваний и резинки до подтягиваний с отягощением. Регулярная практика значительно улучшает форму спины, ширину плеч и общую силовую выносливость. Подтягивания также отлично развивают координацию и учат правильно включать широчайшие, что переносится на все тяговые движения.',
        'muscleGroups': '["back","biceps","lats"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Возьмитесь за перекладину хватом чуть шире плеч, ладони направлены от себя.\n'
            '2. Начните движение со сведения и опускания лопаток — это включает широчайшие, а не руки.\n'
            '3. Тянитесь грудью к перекладине, локти направляйте вниз-назад, а не в стороны.\n'
            '4. В верхней точке подбородок выше перекладины, лопатки сведены, грудь раскрыта.\n'
            '5. Опускайтесь контролируемо до почти полного выпрямления рук — не «сбрасывайте» тело.\n'
            '6. Держите корпус стабильным, без раскачивания и рывков.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Плечи не поднимайте к ушам — держите их опущенными.\n'
            '9. Запястья нейтрально, хват уверенный, но без перенапряжения.\n'
            '10. Для облегчения используйте резинку или тренажёр с противовесом.\n'
            '11. Для усложнения добавьте отягощение на пояс.\n'
            '12. Начинайте с разминки хвата и плеч.',
        'commonMistakes': '1. Раскачивание и рывки — инерция вместо работы мышц.\n'
            '2. Неполная амплитуда (не до конца вниз или не до верха).\n'
            '3. Разведение локтей в стороны — нагрузка уходит с широчайших.\n'
            '4. Расслабленные плечи в нижней точке — риск травмы.\n'
            '5. Подъём плеч к ушам — перегрузка трапеций и шеи.\n'
            '6. «Дёрганье» ногами для помощи — снижает эффект и травмоопасно.\n'
            '7. Отсутствие разминки хвата и плеч — риск растяжений.\n'
            '8. Слишком широкий хват — перегрузка плеч.\n'
            '9. Слишком узкий хват — перегрузка локтей.\n'
            '10. Слишком быстрый негатив — теряется контроль.\n'
            '11. Работа через боль в плечах или локтях.\n'
            '12. Работа без полного выпрямления рук в нижней точке.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_006',
        'name': 'Тяга штанги в наклоне',
        'description': 'Тяга штанги в наклоне — мощное многосуставное упражнение для толщины спины. Оно прорабатывает широчайшие, ромбовидные, задние дельты и бицепсы, а также укрепляет поясницу и мышцы-разгибатели. Это одно из базовых движений для построения плотной, сильной спины и одно из главных упражнений в силовых программах. Тяга требует хорошей техники и контроля нейтрального положения позвоночника, поэтому для новичков рекомендуется начинать с лёгких весов и отработки паттерна наклона. При правильном выполнении упражнение развивает силу хвата и общую силовую выносливость, а также улучшает осанку. Тяга отлично сочетается с подтягиваниями, тягой верхнего блока и горизонтальной тягой.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу хватом чуть шире плеч, встаньте ровно, стопы на ширине таза.\n'
            '2. Наклоните корпус вперёд до ~45°, колени чуть согнуты, спина прямая, взгляд вперёд.\n'
            '3. Лопатки сведены, штанга висит на прямых руках — это исходное положение.\n'
            '4. Тяните штангу к низу живота, локти ведите назад, а не в стороны.\n'
            '5. В верхней точке сводите лопатки и делайте паузу на 1 секунду.\n'
            '6. Опускайте контролируемо, не бросая вес и не теряя нейтральной спины.\n'
            '7. Дышите: вдох перед тягой, выдох в верхней точке.\n'
            '8. Держите корпус стабильным, без раскачивания и помощи инерцией.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Напрягайте пресс и поясницу, чтобы защитить позвоночник.\n'
            '11. Для облегчения используйте Т-гриф или тягу с опорой.\n'
            '12. Начинайте с лёгких весов для отработки техники.',
        'commonMistakes': '1. Округление спины — травмоопасно для позвоночника.\n'
            '2. Рывки и читинг корпусом — снижает эффект и повышает риск.\n'
            '3. Слишком большой вес — теряется техника.\n'
            '4. Тяга к груди вместо живота — перегрузка дельт.\n'
            '5. Разведение локтей в стороны — нагрузка уходит с широчайших.\n'
            '6. Слишком прямой корпус (почти вертикальный) — превращает упражнение в шраги.\n'
            '7. Отсутствие напряжения в коре — перегрузка поясницы.\n'
            '8. Слишком высокий подъём штанги — перегрузка плеч.\n'
            '9. Слишком быстрый негатив — теряется контроль.\n'
            '10. Работа без полной амплитуды.\n'
            '11. Слишком быстрый темп без техники.\n'
            '12. Работа через боль в пояснице.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_007',
        'name': 'Тяга верхнего блока',
        'description': 'Тяга верхнего блока — аналог подтягиваний на тренажёре, который позволяет точно дозировать вес и контролировать траекторию. Отлично подходит новичкам, которые ещё не могут подтягиваться, и опытным атлетам для добивки широчайших. Упражнение прорабатывает широчайшие, ромбовидные и бицепсы, при этом минимально нагружает поясницу. Регулируемый вес позволяет комфортно прогрессировать и концентрироваться на технике, а стабильная траектория снижает риск травмы. Тяга верхнего блока — отличное упражнение для отработки паттерна подтягиваний и для работы над осанкой. Его часто используют как разминочное или как основное упражнение для спины для людей с ограничениями.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте, зафиксируйте бёдра под валиками, возьмите рукоять хватом чуть шире плеч.\n'
            '2. Корпус держите почти вертикально, допустим лёгкий наклон назад (10–15°).\n'
            '3. Начните движение со сведения лопаток, затем тяните рукоять к верхней части груди.\n'
            '4. Локти направляйте вниз-назад, а не в стороны.\n'
            '5. В нижней точке сведите лопатки и сделайте паузу на 1 секунду.\n'
            '6. Опускайте контролируемо до полного выпрямления рук, растягивая широчайшие.\n'
            '7. Дышите ровно: выдох на тяге, вдох на возврате.\n'
            '8. Плечи не поднимайте к ушам.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Держите корпус стабильным.\n'
            '11. Для акцента на широчайшие используйте прямой хват, для бицепса — обратный.\n'
            '12. Начинайте с лёгких весов для отработки техники.',
        'commonMistakes': '1. Сильное отклонение корпуса назад — упражнение превращается в тягу к поясу.\n'
            '2. Рывки и раскачивание — снижает эффект.\n'
            '3. Слишком большой вес — теряется амплитуда.\n'
            '4. Тяга за голову — травмоопасно для плеч.\n'
            '5. Разведение локтей в стороны — нагрузка уходит с широчайших.\n'
            '6. Подъём плеч к ушам — перегрузка трапеций.\n'
            '7. Неполная амплитуда в верхней точке.\n'
            '8. Слишком быстрый негатив — теряется контроль.\n'
            '9. Слишком широкий или узкий хват — перегрузка плеч или локтей.\n'
            '10. Отсутствие сведения лопаток.\n'
            '11. Слишком быстрый темп без техники.\n'
            '12. Работа без разминки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_008',
        'name': 'Становая тяга',
        'description': 'Становая тяга — «король» упражнений, задействующий практически всё тело: спину, ягодицы, бицепс бедра, трапеции, кор и хват. Это одно из трёх соревновательных движений в пауэрлифтинге и мощнейший стимул для общего роста силы и массы. Техника критически важна: неправильное выполнение легко приводит к травме поясницы, поэтому осваивать её нужно постепенно, начиная с лёгких весов и с тренером. Освоив технику, вы получаете упражнение, которое развивает не только мышцы, но и функциональную силу, осанку и уверенность в зале. Становая тяга также улучшает хват, укрепляет кор и учит правильно поднимать тяжести в повседневной жизни. Она отлично сочетается с приседаниями и жимами в силовых программах и является базовым движением для силового троеборья.',
        'muscleGroups': '["back","glutes","hamstrings","lowerBack","traps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Штанга на полу, гриф над серединой стопы, носки под грифом.\n'
            '2. Наклонитесь, возьмите гриф хватом чуть шире плеч, голени почти касаются грифа.\n'
            '3. Спина прямая, лопатки сведены, взгляд вперёд, таз отведён назад.\n'
            '4. Поднимайте штангу за счёт разгибания ног и таза, а не спины.\n'
            '5. Гриф скользит вдоль ног, плечи над грифом на протяжении всего подъёма.\n'
            '6. В верхней точке встаньте прямо, не переразгибайте поясницу.\n'
            '7. Опускайте контролируемо в обратном порядке: сначала таз назад, потом сгибание ног.\n'
            '8. Дышите: вдох перед подъёмом, задержка на самом тяжёлом участке, выдох в верхней точке.\n'
            '9. Напрягайте пресс и поясницу для защиты позвоночника.\n'
            '10. Держите гриф близко к телу — не отрывайте его от ног.\n'
            '11. Начинайте с лёгких весов для отработки техники.\n'
            '12. При больших весах используйте страховку или помощь партнёра.',
        'commonMistakes': '1. Округление спины — самая частая и опасная ошибка.\n'
            '2. Отрыв штанги от ног — перегрузка поясницы.\n'
            '3. Рывки в начальной фазе — теряется контроль.\n'
            '4. Слишком большой вес без контроля техники.\n'
            '5. Переразгибание в верхней точке — перегрузка поясницы.\n'
            '6. Подъём плеч раньше таза — «разваливает» движение.\n'
            '7. Отсутствие напряжения в коре — риск травмы.\n'
            '8. Слишком высокое положение таза в начале — перегрузка поясницы.\n'
            '9. Слишком быстрый негатив — теряется контроль.\n'
            '10. Работа через боль в пояснице.\n'
            '11. Отсутствие разминки.\n'
            '12. Слишком широкий или узкий хват.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_035',
        'name': 'Тяга горизонтального блока сидя',
        'description': 'Тяга горизонтального блока сидя — упражнение для проработки средней и нижней части широчайших, а также ромбовидных мышц. Благодаря стабильной опоре и фиксированной траектории оно безопасно для поясницы и отлично подходит для работы над осанкой. Постоянное натяжение блока обеспечивает хороший контроль и позволяет концентрироваться на сведении лопаток. Регулярное выполнение улучшает форму спины и укрепляет мышцы-стабилизаторы. Упражнение отлично подходит для новичков и людей с ограничениями по пояснице, а также как добивка после тяги штанги или подтягиваний. Горизонтальная тяга учит правильно сводить лопатки, что напрямую влияет на осанку и здоровье плеч.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте, упритесь стопами в платформу, возьмите рукоять нейтральным хватом.\n'
            '2. Спина прямая, лёгкий наклон вперёд в исходном положении.\n'
            '3. Тяните рукоять к животу, локти ведите назад и чуть вниз.\n'
            '4. В конечной точке сводите лопатки и делайте паузу на 1 секунду.\n'
            '5. Возвращайте рукоять контролируемо, растягивая широчайшие.\n'
            '6. Корпус держите стабильным, без раскачивания.\n'
            '7. Дышите ровно: выдох на тяге, вдох на возврате.\n'
            '8. Плечи не поднимайте к ушам.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Напрягайте пресс для стабильности корпуса.\n'
            '11. Для акцента на широчайшие используйте прямой хват, для бицепса — обратный.\n'
            '12. Начинайте с лёгких весов для отработки техники.',
        'commonMistakes': '1. Раскачивание корпусом для помощи тяге — снижает эффект.\n'
            '2. Работа только бицепсом без включения спины.\n'
            '3. Округление спины — перегрузка поясницы.\n'
            '4. Слишком большой вес — теряется амплитуда.\n'
            '5. Подъём плеч к ушам — перегрузка трапеций.\n'
            '6. Отсутствие сведения лопаток — снижает вклад спины.\n'
            '7. Рывки в начальной фазе.\n'
            '8. Слишком быстрый негатив — теряется контроль.\n'
            '9. Слишком высокий подъём рукояти — перегрузка плеч.\n'
            '10. Работа без полной амплитуды.\n'
            '11. Слишком быстрый темп без техники.\n'
            '12. Работа без разминки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_036',
        'name': 'Тяга Т-грифа',
        'description': 'Тяга Т-грифа — вариация тяги в наклоне с фиксированной траекторией, которая позволяет работать с большим весом и стабильной техникой. Хорошо прорабатывает середину спины, ромбовидные и широчайшие. Упражнение подходит как для массонабора, так и для силовой работы. Т-гриф снижает нагрузку на поясницу по сравнению с классической тягой штанги, если выполняется в специальной стойке. Тяга Т-грифа отлично сочетается с подтягиваниями, тягой верхнего блока и горизонтальной тягой. Она часто используется как основное упражнение для толщины спины и для акцента на середину спины. Благодаря стабильной траектории упражнение удобно для контроля и прогрессии.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте над Т-грифом, ноги на ширине плеч, колени чуть согнуты.\n'
            '2. Наклоните корпус вперёд до ~45°, спина прямая, лопатки сведены.\n'
            '3. Возьмите рукоятки, начните тягу к груди или верху живота.\n'
            '4. Локти ведите назад и чуть вниз.\n'
            '5. В верхней точке сводите лопатки, делайте паузу.\n'
            '6. Опускайте контролируемо, не теряя нейтральной спины.\n'
            '7. Дышите ровно: выдох на тяге, вдох на возврате.\n'
            '8. Напрягайте пресс для стабильности корпуса.\n'
            '9. Держите корпус стабильным, без раскачивания.\n'
            '10. Запястья нейтрально, хват уверенный.\n'
            '11. При больших весах используйте страховку или помощь партнёра.\n'
            '12. Начинайте с лёгких весов для отработки техники.',
        'commonMistakes': '1. Округление спины — риск травмы поясницы.\n'
            '2. Работа бицепсом вместо спины — снижает вклад широчайших.\n'
            '3. Рывки и читинг корпусом.\n'
            '4. Слишком большой вес — снижение амплитуды.\n'
            '5. Разведение локтей в стороны — нагрузка уходит с широчайших.\n'
            '6. Подъём плеч к ушам — перегрузка трапеций.\n'
            '7. Отсутствие напряжения в коре.\n'
            '8. Слишком высокий подъём грифа — перегрузка плеч.\n'
            '9. Слишком быстрый негатив — теряется контроль.\n'
            '10. Работа без полной амплитуды.\n'
            '11. Слишком быстрый темп без техники.\n'
            '12. Работа через боль в пояснице.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_037',
        'name': 'Разведение рук с гантелями стоя',
        'description': 'Разведение рук с гантелями стоя (в наклоне или прямом положении) — изолирующее упражнение, которое прорабатывает среднюю и заднюю дельту, а также трапеции. Это одно из ключевых движений для ширины плеч и здоровой осанки. Упражнение требует относительно небольшого веса и внимания к технике, чтобы нагрузка шла в дельты, а не в трапеции. Часто используется как добивка в день плеч. Правильная техника с локтями чуть выше кистей и контролем корпуса — ключ к результату. Разведение в наклоне особенно важно для баланса развития плеч и профилактики импинджмента. Упражнение отлично сочетается с жимами и махами в стороны.',
        'muscleGroups': '["shoulders","back"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте ровно, стопы на ширине плеч, гантели в опущенных руках.\n'
            '2. Локти чуть согнуты, лёгкий изгиб фиксирован на всё движение.\n'
            '3. Разводите руки в стороны до уровня плеч, не выше.\n'
            '4. Ведите движение локтями, а не кистями — так работают дельты.\n'
            '5. В верхней точке локти чуть выше кистей, пауза на 1 секунду.\n'
            '6. Опускайте контролируемо, не расслабляя дельты полностью.\n'
            '7. Корпус держите стабильным, без раскачивания.\n'
            '8. Для акцента на задние дельты наклоните корпус вперёд.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Плечи не поднимайте к ушам.\n'
            '11. Дышите: вдох при опускании, выдох при подъёме.\n'
            '12. Работайте с весом, который позволяет сделать 12–15 повторений с полным контролем.',
        'commonMistakes': '1. Раскачивание корпусом и рывки — снижает эффект.\n'
            '2. Слишком большой вес — движение выполняется трапециями.\n'
            '3. Подъём рук выше плеч — риск травмы.\n'
            '4. Полностью выпрямленные руки — нагрузка уходит в локти.\n'
            '5. Подъём плеч к ушам — перегрузка трапеций.\n'
            '6. Слишком быстрый темп — отсутствует пиковое сокращение.\n'
            '7. Наклон корпуса вперёд без необходимости — смещает нагрузку.\n'
            '8. Слишком большой вес без контроля.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Отсутствие паузы в верхней точке.\n'
            '11. Слишком быстрый негатив.\n'
            '12. Работа без разминки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_038',
        'name': 'Тяга гантели к поясу',
        'description': 'Тяга гантели к поясу с опорой на скамью — одностороннее упражнение для широчайших и ромбовидных мышц. Позволяет работать в большой амплитуде и растягивать мышцу в нижней точке, что делает его отличным для гипертрофии. Опора на скамью снимает нагрузку с поясницы и позволяет сконцентрироваться на одной стороне. Упражнение также помогает выявить и устранить мышечный дисбаланс. Тяга гантели отлично сочетается с подтягиваниями и тягой штанги. Односторонняя работа позволяет лучше почувствовать широчайшие и работать в более полной амплитуде, чем при двусторонней тяге.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Поставьте одну ногу и руку на скамью, вторая нога — на полу.\n'
            '2. Спина прямая, корпус стабилен, взгляд вперёд.\n'
            '3. Возьмите гантель нейтральным хватом, рука свободно висит вниз.\n'
            '4. Тяните гантель к поясу, локоть ведите вдоль корпуса.\n'
            '5. В верхней точке сводите лопатки, делайте паузу на 1 секунду.\n'
            '6. Опускайте контролируемо, растягивая широчайшую в нижней точке.\n'
            '7. Корпус держите стабильным, без скручивания.\n'
            '8. Плечо не поднимайте к уху.\n'
            '9. Запястье нейтрально, хват уверенный.\n'
            '10. Напрягайте пресс для стабильности корпуса.\n'
            '11. Дышите: выдох на тяге, вдох на опускании.\n'
            '12. Работайте с весом, который позволяет сделать 10–12 повторений с полным контролем.',
        'commonMistakes': '1. Скручивание корпуса — работа переходит на поясницу.\n'
            '2. Работа только бицепсом — снижает вклад спины.\n'
            '3. Рывки и слишком большой вес.\n'
            '4. Округление спины — риск травмы.\n'
            '5. Подъём плеча к уху — перегрузка трапеции.\n'
            '6. Слишком короткая амплитуда.\n'
            '7. Отсутствие стабильности опорной руки.\n'
            '8. Слишком быстрый негатив — теряется контроль.\n'
            '9. Слишком высокий подъём гантели — перегрузка плеча.\n'
            '10. Работа без полной амплитуды.\n'
            '11. Слишком быстрый темп без техники.\n'
            '12. Работа через боль в пояснице.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ============================================================
      // ПЛЕЧИ (SHOULDERS) — 6
      // ============================================================
      {
        'id': 'ex_default_009',
        'name': 'Жим штанги стоя',
        'description': 'Жим штанги стоя (армейский жим) — базовое многосуставное упражнение для развития дельт и трицепсов. Выполняется стоя, что требует активной работы кора и стабилизаторов. Армейский жим — это классика для развития силы плечевого пояса и общей силовой подготовки. Он отлично переносится на жимовые движения и помогает укрепить мышцы-стабилизаторы плеча и лопаток. Жим стоя также развивает координацию и учит правильно держать корпус в вертикальной нагрузке. Упражнение отлично сочетается с махами в стороны, разведениями и тягой к подбородку. Это одно из главных упражнений для тех, кто хочет иметь сильные и объёмные плечи.',
        'muscleGroups': '["shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу хватом чуть шире плеч, стойка на ширине таза.\n'
            '2. Пресс напряжён, таз слегка подан вперёд — это защищает поясницу.\n'
            '3. Локти под углом ~45° к корпусу, штанга на уровне ключиц.\n'
            '4. Выжимайте штангу над головой по дуге, слегка отводя голову назад.\n'
            '5. В верхней точке штанга над серединой стопы, локти не блокированы жёстко.\n'
            '6. Опускайте контролируемо до уровня подбородка или ключиц.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Держите корпус стабильным, без прогиба в пояснице.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Плечи не поднимайте к ушам.\n'
            '11. При больших весах используйте страховку или помощь партнёра.\n'
            '12. Начинайте с пустого грифа для разминки.',
        'commonMistakes': '1. Избыточный прогиб в пояснице — травмоопасно.\n'
            '2. Слишком большой вес — потеря техники.\n'
            '3. Опускание штанги за голову — риск травмы плеч.\n'
            '4. Рывки в нижней точке.\n'
            '5. Разведение локтей строго в стороны — перегрузка плеч.\n'
            '6. Расслабленный кор — нестабильность.\n'
            '7. Задержка дыхания на всё движение.\n'
            '8. Слишком широкий или узкий хват.\n'
            '9. Слишком быстрый негатив.\n'
            '10. Работа без полной амплитуды.\n'
            '11. Работа без разминки.\n'
            '12. Работа через боль в плечах.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_010',
        'name': 'Махи гантелями в стороны',
        'description': 'Махи гантелями в стороны — изолирующее упражнение для средних дельт, создающее визуальную ширину плеч. Средняя дельта — одна из самых сложных для роста мышц, поэтому требует регулярной и точной работы. Махи отлично подходят для добивки в день плеч и для формирования эстетичной линии плеч. Правильная техника с локтями чуть выше кистей и контролем корпуса — ключ к результату. Упражнение требует относительно небольшого веса и внимания к деталям. Махи отлично сочетаются с жимами и разведениями в наклоне. Это одно из самых популярных упражнений в бодибилдинге и фитнесе.',
        'muscleGroups': '["shoulders"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте ровно, гантели в опущенных руках, стопы на ширине плеч.\n'
            '2. Локти чуть согнуты, лёгкий изгиб фиксирован на всё движение.\n'
            '3. Поднимайте руки в стороны до уровня плеч, не выше.\n'
            '4. Ведите движение локтями, а не кистями — так работают дельты.\n'
            '5. В верхней точке локти чуть выше кистей, пауза на 1 секунду.\n'
            '6. Опускайте контролируемо, не расслабляя дельты полностью.\n'
            '7. Корпус держите стабильным, без раскачивания.\n'
            '8. Плечи не поднимайте к ушам.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Дышите: вдох при опускании, выдох при подъёме.\n'
            '11. Работайте с весом, который позволяет сделать 12–15 повторений с полным контролем.\n'
            '12. Для акцента на среднюю дельту держите мизинец чуть выше большого пальца.',
        'commonMistakes': '1. Раскачивание корпусом и рывки — снижает эффект.\n'
            '2. Слишком большой вес — подключаются трапеции.\n'
            '3. Подъём выше плеч — риск травмы.\n'
            '4. Полностью выпрямленные руки — нагрузка уходит в локти.\n'
            '5. Подъём плеч к ушам — перегрузка трапеций.\n'
            '6. Слишком быстрый темп — отсутствует пиковое сокращение.\n'
            '7. Наклон корпуса вперёд — смещает нагрузку.\n'
            '8. Слишком большой вес без контроля.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Отсутствие паузы в верхней точке.\n'
            '11. Слишком быстрый негатив.\n'
            '12. Работа без разминки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_011',
        'name': 'Тяга штанги к подбородку',
        'description': 'Тяга штанги к подбородку — комплексное упражнение для средних дельт и трапеций. Несмотря на популярность, оно считается спорным по безопасности: при слишком узком хвате или подъёме выше подбородка повышается риск импинджмента плеча. При правильной технике и умеренном весе это эффективное упражнение для верхней части плеч и трапеций. Хорошо сочетается с махами и жимами в день плеч. Тяга к подбородку также развивает силу хвата и учит правильно включать трапеции. Рекомендуется использовать умеренный вес и не поднимать штангу выше подбородка.',
        'muscleGroups': '["shoulders","traps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу хватом чуть шире плеч (не узким!) — это снижает риск для плеч.\n'
            '2. Стойка ровная, пресс напряжён, спина нейтральная.\n'
            '3. Тяните штангу к подбородку, локти ведите вверх и чуть в стороны.\n'
            '4. В верхней точке локти выше кистей, штанга на уровне подбородка.\n'
            '5. Не поднимайте штангу выше подбородка — это травмоопасно.\n'
            '6. Опускайте контролируемо, не бросая вес.\n'
            '7. Работайте с умеренным весом, сохраняя контроль.\n'
            '8. Держите корпус стабильным, без раскачивания.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Плечи не поднимайте к ушам.\n'
            '11. Дышите: выдох на тяге, вдох на опускании.\n'
            '12. Для безопасности работайте в диапазоне 8–12 повторений.',
        'commonMistakes': '1. Слишком узкий хват — травмоопасно для плеч.\n'
            '2. Слишком большой вес — потеря техники.\n'
            '3. Тяга за счёт кистей, а не локтей.\n'
            '4. Рывки в верхней фазе.\n'
            '5. Подъём штанги выше подбородка — риск импинджмента.\n'
            '6. Отсутствие напряжения в коре.\n'
            '7. Слишком быстрый темп.\n'
            '8. Слишком широкий хват — перегрузка трапеций.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Отсутствие разминки.\n'
            '11. Работа через боль в плечах.\n'
            '12. Работа без страховки с большими весами.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_039',
        'name': 'Жим гантелей сидя',
        'description': 'Жим гантелей сидя — вариант жима над головой с опорой спины на скамью. Прорабатывает передние и средние дельты, трицепсы, при этом снижает нагрузку на поясницу по сравнению с жимом стоя. Гантели позволяют работать в большей амплитуде и комфортнее для плеч. Упражнение подходит и новичкам, и опытным атлетам, легко масштабируется по весу. Жим сидя отлично сочетается с махами и разведениями. Опора спины делает упражнение безопаснее для поясницы и позволяет сконцентрироваться на дельтах. Это одно из базовых упражнений в день плеч.',
        'muscleGroups': '["shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте на скамью с вертикальной спинкой, прижмите спину и лопатки.\n'
            '2. Гантели на уровне плеч, ладони направлены вперёд.\n'
            '3. Пресс напряжён, стопы плотно на полу.\n'
            '4. Выжимайте гантели вверх по дуге, слегка сводя их в верхней точке.\n'
            '5. В верхней точке не сталкивайте гантели и не блокируйте локти жёстко.\n'
            '6. Опускайте контролируемо до уровня плеч.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Держите корпус стабильным, без прогиба в пояснице.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Плечи не поднимайте к ушам.\n'
            '11. При больших весах используйте помощь партнёра для подачи гантелей.\n'
            '12. Работайте с весом, который позволяет сделать 8–12 повторений с полным контролем.',
        'commonMistakes': '1. Прогиб в пояснице — работа переходит на неё.\n'
            '2. Слишком большой вес — потеря техники.\n'
            '3. Неполная амплитуда.\n'
            '4. Разведение локтей строго в стороны — перегрузка плеч.\n'
            '5. Сталкивание гантелей в верхней точке — снижает напряжение.\n'
            '6. Рывки в нижней точке.\n'
            '7. Отрыв спины от скамьи.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Запястья разгибаются назад — перегрузка лучезапястных суставов.\n'
            '10. Отсутствие разминки.\n'
            '11. Работа через боль в плечах.\n'
            '12. Работа без полной амплитуды.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_040',
        'name': 'Махи гантелями в наклоне',
        'description': 'Махи гантелями в наклоне — изолирующее упражнение для задних дельт, которые часто остаются в тени. Слаборазвитые задние дельты ведут к дисбалансу и ухудшению осанки, поэтому это упражнение важно включать в план. Оно выполняется с наклоном корпуса, что дополнительно включает мышцы-стабилизаторы спины. Правильная техника — залог того, что нагрузка пойдёт в дельты, а не в спину. Махи в наклоне отлично сочетаются с разведениями в кроссовере и жимами. Это одно из ключевых упражнений для баланса развития плеч и профилактики травм.',
        'muscleGroups': '["shoulders","back"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите гантели, наклоните корпус вперёд (примерно до 45°), спина прямая.\n'
            '2. Локти чуть согнуты, зафиксированы на всё движение.\n'
            '3. Разводите руки в стороны, ведя локтями, а не кистями.\n'
            '4. В верхней точке локти на уровне плеч, пауза на 1 секунду.\n'
            '5. Сводите лопатки в верхней точке для дополнительного сокращения.\n'
            '6. Опускайте контролируемо, не расслабляя дельты.\n'
            '7. Корпус стабилен, без раскачивания.\n'
            '8. Плечи не поднимайте к ушам.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Дышите: вдох при опускании, выдох при подъёме.\n'
            '11. Работайте с весом, который позволяет сделать 12–15 повторений с полным контролем.\n'
            '12. Для акцента на заднюю дельту держите мизинец чуть выше большого пальца.',
        'commonMistakes': '1. Работа спиной вместо дельт.\n'
            '2. Округление спины — риск травмы.\n'
            '3. Слишком большой вес и рывки.\n'
            '4. Подъём рук выше плеч — риск травмы.\n'
            '5. Подъём плеч к ушам — перегрузка трапеций.\n'
            '6. Полностью выпрямленные руки.\n'
            '7. Слишком быстрый темп.\n'
            '8. Слишком большой вес без контроля.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Отсутствие паузы в верхней точке.\n'
            '11. Слишком быстрый негатив.\n'
            '12. Работа без разминки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_041',
        'name': 'Жим штанги из-за головы',
        'description': 'Жим штанги из-за головы — вариация жима стоя с опусканием штанги за голову. Акцентирует средние дельты, но требует хорошей подвижности плеч и осторожности. Это упражнение не рекомендуется новичкам и людям с ограниченной подвижностью плечевого пояса. При правильной технике и умеренном весе оно эффективно дополняет стандартный жим и махи в день плеч. Жим из-за головы требует хорошей разминки плеч и контроля амплитуды. Упражнение часто используется в бодибилдинге для акцента на средние дельты, но требует осторожности. Это одно из самых спорных по безопасности упражнений, поэтому важно соблюдать технику.',
        'muscleGroups': '["shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу хватом чуть шире плеч, локти под углом ~45°.\n'
            '2. Пресс напряжён, спина нейтральная, без прогиба.\n'
            '3. Опускайте штангу только до уровня ушей — не ниже.\n'
            '4. Выжимайте штангу вверх по дуге, голову слегка отводите вперёд.\n'
            '5. В верхней точке штанга над серединой стопы.\n'
            '6. Опускайте контролируемо.\n'
            '7. Работайте с умеренным весом и хорошей разминкой плеч.\n'
            '8. Держите корпус стабильным, без прогиба в пояснице.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Плечи не поднимайте к ушам.\n'
            '11. Дышите: выдох на подъёме, вдох на опускании.\n'
            '12. При больших весах используйте страховку или помощь партнёра.',
        'commonMistakes': '1. Слишком низкое опускание — травма плеч.\n'
            '2. Слишком большой вес.\n'
            '3. Прогиб в пояснице.\n'
            '4. Резкие движения.\n'
            '5. Отсутствие разминки плеч.\n'
            '6. Слишком узкий хват.\n'
            '7. Работа без страховки.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в плечах.\n'
            '11. Отсутствие контроля в нижней точке.\n'
            '12. Работа с максимальными весами без подготовки.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ============================================================
      // НОГИ (LEGS) — 8
      // ============================================================
      {
        'id': 'ex_default_012',
        'name': 'Приседания со штангой',
        'description': 'Приседания со штангой — базовое упражнение для ног и всего тела. Прорабатывает квадрицепсы, ягодицы, бицепс бедра, кор и поясницу. Это одно из главных движений в силовых видах спорта и одно из самых эффективных для общего роста силы и массы. Приседания улучшают мобильность, координацию и функциональную силу, которая переносится на повседневную жизнь и спорт. Упражнение требует хорошей техники и контроля нейтральной спины. Приседания отлично сочетаются с жимом ногами, румынской тягой и выпадами. Это одно из главных упражнений для развития ног и ягодиц.',
        'muscleGroups': '["quadriceps","glutes","hamstrings","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Штанга на трапециях, лопатки сведены, хват чуть шире плеч.\n'
            '2. Стопы на ширине плеч или чуть шире, носки слегка развёрнуты.\n'
            '3. Колени движутся в сторону носков на протяжении всего движения.\n'
            '4. Спина прямая, взгляд вперёд, вес на середине стопы.\n'
            '5. Приседайте до параллели бёдер с полом или чуть ниже.\n'
            '6. Пятки не отрываются от пола, таз не «подкручивается».\n'
            '7. Поднимайтесь за счёт ног и таза, сохраняя спину прямой.\n'
            '8. Дышите: вдох перед приседанием, задержка на дне, выдох на подъёме.\n'
            '9. Напрягайте пресс и поясницу для защиты позвоночника.\n'
            '10. Держите корпус стабильным, без наклона вперёд.\n'
            '11. При больших весах используйте страховку или помощь партнёра.\n'
            '12. Начинайте с пустого грифа для отработки техники.',
        'commonMistakes': '1. Отрыв пяток — теряется равновесие и нагрузка уходит вперёд.\n'
            '2. Округление спины — риск травмы поясницы.\n'
            '3. Колени внутрь — травма коленей.\n'
            '4. Неполная амплитуда — снижает эффект.\n'
            '5. Подъём таза раньше плеч — «разваливает» движение.\n'
            '6. Слишком большой вес без контроля техники.\n'
            '7. Задержка дыхания на всё движение.\n'
            '8. Слишком широкий или узкий хват.\n'
            '9. Слишком быстрый негатив.\n'
            '10. Работа без полной амплитуды.\n'
            '11. Работа через боль в коленях или пояснице.\n'
            '12. Отсутствие разминки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_013',
        'name': 'Жим ногами',
        'description': 'Жим ногами — упражнение в тренажёре для изоляции квадрицепсов и ягодиц. Минимальная нагрузка на поясницу делает его отличным выбором для новичков и людей с проблемами спины. Позволяет работать с большим весом и безопасно концентрироваться на ногах. Жим ногами хорошо сочетается с приседаниями, разгибаниями и сгибаниями ног в комплексной программе. Упражнение отлично подходит для добивки после приседаний и для изоляции квадрицепсов. Регулируемая амплитуда позволяет безопасно работать даже при ограничениях по коленям.',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте в тренажёр, прижмите спину и таз к спинке.\n'
            '2. Стопы на ширине плеч, носки слегка развёрнуты.\n'
            '3. Опускайте платформу до угла ~90° в коленях.\n'
            '4. Колени движутся в сторону носков, не внутрь.\n'
            '5. Не выпрямляйте колени полностью в верхней точке — оставляйте микро-изгиб.\n'
            '6. Поднимайте платформу за счёт ног, не отрывая таз.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Держите корпус стабильным, без отрыва таза.\n'
            '9. Запястья нейтрально, хват уверенный за рукоятки.\n'
            '10. Плечи не поднимайте.\n'
            '11. При больших весах используйте страховку.\n'
            '12. Работайте с весом, который позволяет сделать 10–12 повторений с полным контролем.',
        'commonMistakes': '1. Полное выпрямление коленей — травмоопасно.\n'
            '2. Отрыв таза от сиденья — перегрузка поясницы.\n'
            '3. Слишком большой вес и неполная амплитуда.\n'
            '4. Колени внутрь — риск травмы.\n'
            '5. Слишком низкое опускание — перегрузка коленей.\n'
            '6. Отрыв пяток от платформы.\n'
            '7. Быстрый темп без контроля.\n'
            '8. Слишком высокое положение стоп — акцент на ягодицы.\n'
            '9. Слишком низкое положение стоп — акцент на квадрицепс.\n'
            '10. Работа без полной амплитуды.\n'
            '11. Работа через боль в коленях.\n'
            '12. Отсутствие разминки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_014',
        'name': 'Выпады с гантелями',
        'description': 'Выпады с гантелями — функциональное упражнение для ног и ягодиц, которое развивает баланс, координацию и силу каждой ноги отдельно. Хорошо подходит для коррекции мышечного дисбаланса и улучшения стабильности. Выпады также задействуют кор и мышцы-стабилизаторы, что делает их отличным дополнением к приседаниям и жиму ногами. Масштабируются весом и длиной шага. Выпады отлично сочетаются с болгарскими выпадами и зашагиваниями на платформу. Это одно из лучших функциональных упражнений для нижней части тела.',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите гантели в опущенные руки, встаньте ровно.\n'
            '2. Сделайте шаг вперёд и опуститесь до угла ~90° в обоих коленях.\n'
            '3. Колено передней ноги не выходит за носок.\n'
            '4. Спина прямая, корпус вертикально.\n'
            '5. Отталкивайтесь передней пяткой, возвращаясь в исходное положение.\n'
            '6. Держите корпус стабильным, без наклона вперёд.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Плечи не поднимайте, гантели держите по бокам.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Для акцента на ягодицы увеличьте длину шага.\n'
            '11. Для акцента на квадрицепс используйте короткий шаг.\n'
            '12. Работайте с весом, который позволяет сделать 10–12 повторений на каждую ногу.',
        'commonMistakes': '1. Наклон корпуса вперёд.\n'
            '2. Потеря равновесия.\n'
            '3. Слишком короткий шаг — перегрузка колена.\n'
            '4. Слишком большой вес.\n'
            '5. Колено выходит за носок — перегрузка коленного сустава.\n'
            '6. Отрыв пятки от пола.\n'
            '7. Быстрый темп без контроля.\n'
            '8. Слишком длинный шаг — перегрузка ягодиц.\n'
            '9. Асимметричная работа ног.\n'
            '10. Работа без полной амплитуды.\n'
            '11. Работа через боль в коленях.\n'
            '12. Отсутствие разминки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_015',
        'name': 'Сгибания ног в тренажёре',
        'description': 'Сгибания ног в тренажёре — изолирующее упражнение для бицепса бедра. Эффективно для проработки задней поверхности бедра и профилактики дисбаланса между квадрицепсом и бицепсом бедра. Слабость бицепса бедра повышает риск травм колена и поясницы, поэтому это упражнение важно включать в план. Тренажёр позволяет безопасно работать с хорошим весом и контролировать амплитуду. Сгибания ног отлично сочетаются с румынской тягой и становой тягой. Это одно из ключевых упражнений для задней поверхности бедра.',
        'muscleGroups': '["hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте в тренажёр, таз прижат к сиденью.\n'
            '2. Валик на задней поверхности голеней чуть выше пяток.\n'
            '3. Сгибайте ноги до максимального сокращения бицепса бедра.\n'
            '4. В верхней точке делайте паузу на 1 секунду.\n'
            '5. Опускайте контролируемо, не расслабляя мышцу полностью.\n'
            '6. Таз не отрывайте от сиденья на протяжении всего движения.\n'
            '7. Дышите ровно: выдох на сгибании, вдох на разгибании.\n'
            '8. Держите корпус стабильным, без раскачивания.\n'
            '9. Запястья нейтрально, хват уверенный за рукоятки.\n'
            '10. Не поднимайте плечи к ушам.\n'
            '11. При больших весах используйте страховку.\n'
            '12. Работайте с весом, который позволяет сделать 10–12 повторений с полным контролем.',
        'commonMistakes': '1. Отрыв таза — перегрузка поясницы.\n'
            '2. Рывки и слишком большой вес.\n'
            '3. Неполная амплитуда.\n'
            '4. Слишком быстрый темп.\n'
            '5. Расслабление мышцы в нижней точке.\n'
            '6. Слишком сильное сгибание коленей — перегрузка суставов.\n'
            '7. Отсутствие паузы в верхней точке.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в коленях.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа без контроля таза.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_016',
        'name': 'Подъёмы на носки стоя',
        'description': 'Подъёмы на носки стоя — базовое упражнение для икроножных мышц. Икры часто отстают из-за генетики и недостаточной амплитуды, поэтому здесь важны полная амплитуда, пауза в верхней точке и медленный негатив. Упражнение можно выполнять со штангой, гантелями или в тренажёре. Регулярная работа над икрами улучшает не только эстетику, но и стабильность голеностопа. Подъёмы на носки отлично сочетаются с подъёмами сидя. Это одно из ключевых упражнений для развития икр.',
        'muscleGroups': '["calves"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте на платформу так, чтобы пятки свисали.\n'
            '2. Опуститесь в глубокое растяжение икр.\n'
            '3. Поднимайтесь на носки до максимального сокращения.\n'
            '4. В верхней точке задерживайтесь на 1–2 секунды.\n'
            '5. Опускайтесь медленно, не «роняя» пятки.\n'
            '6. Держите корпус стабильным, не помогайте корпусом.\n'
            '7. Работайте в полной амплитуде.\n'
            '8. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '9. Плечи не поднимайте.\n'
            '10. Запястья нейтрально.\n'
            '11. Работайте с весом, который позволяет сделать 12–15 повторений с полным контролем.\n'
            '12. Для акцента на икры держите колени прямыми.',
        'commonMistakes': '1. Быстрые движения без амплитуды.\n'
            '2. Слишком большой вес и рывки.\n'
            '3. Сгибание коленей — снижает вклад икр.\n'
            '4. Неполная амплитуда.\n'
            '5. Отсутствие паузы в верхней точке.\n'
            '6. Работа только за счёт стопы без полной амплитуды.\n'
            '7. Слишком быстрый негатив.\n'
            '8. Отсутствие контроля.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в ахилле.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с слишком большим весом без техники.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_042',
        'name': 'Румынская тяга',
        'description': 'Румынская тяга — упражнение для бицепса бедра, ягодиц и поясницы, выполняемое с полусогнутыми ногами. В отличие от классической становой, акцент здесь на растяжении и работе задней цепи, а не на подъёме с пола. Это одно из лучших упражнений для развития бицепса бедра и ягодиц. Требует хорошей техники наклона и контроля нейтральной спины. Румынская тяга отлично сочетается с приседаниями, сгибаниями ног и хип-трастом. Это одно из ключевых упражнений для задней цепи и ягодиц.',
        'muscleGroups': '["hamstrings","glutes","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу хватом чуть шире плеч, встаньте ровно.\n'
            '2. Ноги почти прямые, лёгкий изгиб в коленях.\n'
            '3. Спина прямая, наклоняйтесь за счёт отведения таза назад.\n'
            '4. Опускайтесь до ощущения растяжения в бицепсе бедра (обычно на уровне середины голени).\n'
            '5. Поднимайтесь за счёт ягодиц и бицепса бедра, а не спины.\n'
            '6. В верхней точке сжимайте ягодицы, но не переразгибайте поясницу.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Держите корпус стабильным, без раскачивания.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Плечи не поднимайте.\n'
            '11. При больших весах используйте страховку.\n'
            '12. Работайте с весом, который позволяет сделать 8–12 повторений с полным контролем.',
        'commonMistakes': '1. Округление спины — риск травмы поясницы.\n'
            '2. Сгибание ног — превращается в обычную тягу.\n'
            '3. Слишком глубокий наклон без растяжки.\n'
            '4. Слишком большой вес.\n'
            '5. Переразгибание в верхней точке.\n'
            '6. Слишком быстрый негатив.\n'
            '7. Отсутствие сжатия ягодиц.\n'
            '8. Слишком быстрый темп без контроля.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в пояснице.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с максимальными весами без подготовки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_043',
        'name': 'Болгарские выпады',
        'description': 'Болгарские выпады — одностороннее упражнение с задней ногой на возвышении, которое одно из лучших для ягодиц и квадрицепсов. Требует баланса, координации и активной работы стабилизаторов. Позволяет работать с хорошим весом и концентрироваться на одной стороне. Отлично подходит для коррекции дисбаланса и развития функциональной силы ног. Болгарские выпады отлично сочетаются с обычными выпадами и зашагиваниями на платформу. Это одно из ключевых упражнений для ягодиц и ног.',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Поставьте одну ногу назад на скамью, передняя нога — опорная.\n'
            '2. Корпус вертикально, лёгкий наклон вперёд допустим.\n'
            '3. Опускайтесь до угла ~90° в переднем колене.\n'
            '4. Переднее колено не выходит за носок.\n'
            '5. Отталкивайтесь передней пяткой.\n'
            '6. Корпус держите стабильным, без потери равновесия.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Плечи не поднимайте, гантели держите по бокам.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Для акцента на ягодицы используйте наклон корпуса вперёд.\n'
            '11. Для акцента на квадрицепс держите корпус вертикально.\n'
            '12. Работайте с весом, который позволяет сделать 8–12 повторений на каждую ногу.',
        'commonMistakes': '1. Потеря равновесия и наклон корпуса.\n'
            '2. Слишком большой вес.\n'
            '3. Слишком высокое возвышение — перегрузка колена.\n'
            '4. Короткая амплитуда.\n'
            '5. Переднее колено выходит за носок.\n'
            '6. Отрыв пятки.\n'
            '7. Слишком быстрый темп.\n'
            '8. Слишком низкое возвышение — снижение нагрузки.\n'
            '9. Асимметричная работа ног.\n'
            '10. Работа без полной амплитуды.\n'
            '11. Работа через боль в коленях.\n'
            '12. Отсутствие разминки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_044',
        'name': 'Подъёмы на носки сидя',
        'description': 'Подъёмы на носки сидя — вариант упражнения для икр с акцентом на камбаловидную мышцу. Камбаловидная отвечает за толщину голени и работает при согнутом колене, поэтому сидячая версия — ключ к её полноценной стимуляции. Упражнение отлично дополняет подъёмы стоя и делает голень более объёмной. Требует полной амплитуды и паузы в верхней точке. Подъёмы сидя отлично сочетаются с подъёмами стоя. Это одно из ключевых упражнений для развития камбаловидной мышцы.',
        'muscleGroups': '["calves"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте в тренажёр, колени согнуты под углом ~90°.\n'
            '2. Валики на коленях, пятки на платформе.\n'
            '3. Опускайтесь в глубокое растяжение икр.\n'
            '4. Поднимайтесь на носки до максимального сокращения.\n'
            '5. Задерживайтесь в верхней точке на 1–2 секунды.\n'
            '6. Опускайтесь медленно, не «роняя» пятки.\n'
            '7. Работайте в полной амплитуде.\n'
            '8. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '9. Держите корпус стабильным.\n'
            '10. Запястья нейтрально.\n'
            '11. Работайте с весом, который позволяет сделать 12–15 повторений с полным контролем.\n'
            '12. Для акцента на камбаловидную держите колени согнутыми.',
        'commonMistakes': '1. Неполная амплитуда.\n'
            '2. Рывки и слишком быстрый темп.\n'
            '3. Слишком большой вес.\n'
            '4. Отрыв пяток от платформы.\n'
            '5. Отсутствие паузы в верхней точке.\n'
            '6. Слишком быстрый негатив.\n'
            '7. Расслабление икр в нижней точке.\n'
            '8. Отсутствие контроля.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в ахилле.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с максимальными весами без техники.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ============================================================
      // РУКИ (ARMS) — 10
      // ============================================================
      {
        'id': 'ex_default_017',
        'name': 'Подъём штанги на бицепс',
        'description': 'Подъём штанги на бицепс — классическое упражнение для двуглавой мышцы плеча и плечевой мышцы. Одно из самых популярных движений в зале и базовое для развития рук. Правильная техника с прижатыми локтями и контролем корпуса превращает его в мощный стимул для роста бицепса. Подходит для всех уровней подготовки и легко масштабируется. Подъём на бицепс отлично сочетается с молотками, французским жимом и разгибаниями на блоке. Это одно из ключевых упражнений для бицепса.',
        'muscleGroups': '["biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу хватом снизу чуть шире плеч.\n'
            '2. Локти прижаты к корпусу, не разводите их.\n'
            '3. Поднимайте штангу до уровня груди за счёт сгибания в локтях.\n'
            '4. Делайте паузу на пике сокращения на 1 секунду.\n'
            '5. Опускайте контролируемо, до почти полного выпрямления рук.\n'
            '6. Корпус стабилен, без раскачивания.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Плечи не поднимайте.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Работайте с весом, который позволяет сделать 10–12 повторений с полным контролем.\n'
            '11. Для акцента на длинную головку используйте узкий хват.\n'
            '12. Для акцента на короткую головку используйте широкий хват.',
        'commonMistakes': '1. Читинг и раскачивание корпусом.\n'
            '2. Слишком большой вес.\n'
            '3. Разведение локтей в стороны.\n'
            '4. Неполная амплитуда.\n'
            '5. Расслабление бицепса в нижней точке.\n'
            '6. Слишком быстрый темп.\n'
            '7. Работа плечами вместо локтей.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в локтях.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с максимальными весами без техники.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_018',
        'name': 'Французский жим',
        'description': 'Французский жим — изолирующее упражнение для трицепса, выполняемое из-за головы. Отлично растягивает длинную головку трицепса, которая часто отстаёт при других движениях. Требует фиксации локтей и умеренного веса, чтобы избежать травм локтевых суставов. Хорошо сочетается с жимами и разгибаниями на блоке в день рук. Французский жим отлично подходит для добивки трицепса и для работы над длинной головкой. Это одно из ключевых упражнений для трицепса.',
        'muscleGroups': '["triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на скамью или сядьте, локти направлены вверх.\n'
            '2. Держите штангу/гантель над головой, локти зафиксированы.\n'
            '3. Опускайте штангу за голову контролируемо.\n'
            '4. Разгибайте руки до полного сокращения трицепса.\n'
            '5. В верхней точке не блокируйте локти жёстко.\n'
            '6. Работайте с умеренным весом.\n'
            '7. Дышите ровно: выдох на разгибании, вдох на сгибании.\n'
            '8. Держите корпус стабильным.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Плечи не поднимайте.\n'
            '11. Работайте с весом, который позволяет сделать 10–12 повторений с полным контролем.\n'
            '12. Для акцента на длинную головку используйте наклон скамьи.',
        'commonMistakes': '1. Разведение локтей в стороны.\n'
            '2. Слишком большой вес — травма локтей.\n'
            '3. Рывки.\n'
            '4. Движение плечами.\n'
            '5. Неполная амплитуда.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие фиксации локтей.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в локтях.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с максимальными весами без техники.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_019',
        'name': 'Молотки',
        'description': 'Молотки — подъём гантелей нейтральным хватом, при котором кисти смотрят друг на друга. Развивает бицепс, плечевую мышцу (brachialis) и предплечья, придавая рукам толщину. Это отличное упражнение для комплексного развития рук, особенно если бицепс уже хорошо отзывается на классические подъёмы. Нейтральный хват комфортнее для запястий. Молотки отлично сочетаются с подъёмом штанги и концентрационными сгибаниями. Это одно из ключевых упражнений для толщины рук.',
        'muscleGroups': '["biceps","forearms"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите гантели нейтральным хватом (ладони внутрь).\n'
            '2. Локти прижаты к корпусу.\n'
            '3. Поднимайте гантели до уровня плеч.\n'
            '4. Задерживайтесь на пике на 1 секунду.\n'
            '5. Опускайте контролируемо.\n'
            '6. Корпус стабилен, без раскачивания.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Плечи не поднимайте.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Работайте с весом, который позволяет сделать 10–12 повторений с полным контролем.\n'
            '11. Можно выполнять сидя для исключения читинга.\n'
            '12. Для акцента на плечевую мышцу используйте более тяжёлый вес.',
        'commonMistakes': '1. Раскачивание корпусом.\n'
            '2. Разворот кистей — превращает в обычный подъём.\n'
            '3. Слишком большой вес.\n'
            '4. Работа плечами.\n'
            '5. Неполная амплитуда.\n'
            '6. Слишком быстрый темп.\n'
            '7. Разведение локтей в стороны.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в локтях.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с максимальными весами без техники.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_020',
        'name': 'Отжимания на брусьях',
        'description': 'Отжимания на брусьях — базовое упражнение с собственным весом для трицепса и груди. При вертикальном корпусе акцент смещается на трицепс, при наклоне вперёд — на грудь. Легко масштабируется дополнительным отягощением или резинкой. Одно из лучших упражнений для трицепса с точки зрения соотношения «эффективность — доступность». Отжимания на брусьях отлично сочетаются с французским жимом и разгибаниями на блоке. Это одно из ключевых упражнений для трицепса.',
        'muscleGroups': '["triceps","chest","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Возьмитесь за брусья, поднимитесь на прямых руках, плечи опущены.\n'
            '2. Корпус держите вертикально — акцент на трицепс.\n'
            '3. Локти прижаты к корпусу, не разводите их в стороны.\n'
            '4. Опускайтесь до параллели плеча и предплечья.\n'
            '5. Поднимайтесь за счёт трицепса.\n'
            '6. В верхней точке не блокируйте локти жёстко.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Плечи не поднимайте к ушам.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Для облегчения используйте резинку или тренажёр с противовесом.\n'
            '11. Для усложнения добавьте отягощение на пояс.\n'
            '12. Работайте с полной амплитудой.',
        'commonMistakes': '1. Неполная амплитуда.\n'
            '2. Разведение локтей — перегрузка плеч.\n'
            '3. Слишком глубокое опускание.\n'
            '4. Раскачивание.\n'
            '5. Подъём плеч к ушам.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие разминки плеч.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в плечах или локтях.\n'
            '11. Работа без разминки.\n'
            '12. Работа без страховки с отягощением.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_045',
        'name': 'Сгибания рук с гантелями сидя',
        'description': 'Сгибания рук с гантелями сидя — изолирующее упражнение для бицепса. Положение сидя исключает читинг корпусом и позволяет сконцентрироваться на работе мышцы. Акцент на длинную головку бицепса, если выполнять с супинацией. Хорошо подходит для добивки и работы над пиковым сокращением. Сгибания сидя отлично сочетаются с молотками и подъёмом штанги. Это одно из ключевых упражнений для бицепса.',
        'muscleGroups': '["biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте на скамью, спина прямая, гантели в опущенных руках.\n'
            '2. Локти прижаты к корпусу.\n'
            '3. Поднимайте гантели с супинацией (разворотом кисти вверх).\n'
            '4. Пауза на пике сокращения на 1 секунду.\n'
            '5. Опускайте медленно.\n'
            '6. Корпус стабилен.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Плечи не поднимайте.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Работайте с весом, который позволяет сделать 10–12 повторений с полным контролем.\n'
            '11. Для акцента на длинную головку используйте супинацию.\n'
            '12. Для акцента на короткую головку используйте нейтральный хват.',
        'commonMistakes': '1. Раскачивание корпусом.\n'
            '2. Работа плечами.\n'
            '3. Слишком большой вес.\n'
            '4. Неполная амплитуда.\n'
            '5. Отсутствие супинации — снижает акцент на бицепс.\n'
            '6. Слишком быстрый темп.\n'
            '7. Расслабление бицепса в нижней точке.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в локтях.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с максимальными весами без техники.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_046',
        'name': 'Разгибание рук на блоке',
        'description': 'Разгибание рук на блоке — изолирующее упражнение для трицепса с постоянным натяжением. Блок обеспечивает стабильную траекторию и безопасность для локтей. Отлично подходит как для новичков, так и для опытных атлетов для добивки трицепса. Хорошо сочетается с французским жимом и отжиманиями на брусьях. Разгибание на блоке отлично подходит для работы над формой трицепса. Это одно из ключевых упражнений для трицепса.',
        'muscleGroups': '["triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте у блока, возьмите рукоять хватом сверху.\n'
            '2. Локти прижаты к корпусу и зафиксированы.\n'
            '3. Разгибайте руки до полного сокращения трицепса.\n'
            '4. Пауза в нижней точке на 1 секунду.\n'
            '5. Возвращайте контролируемо, до угла ~90° в локтях.\n'
            '6. Корпус стабилен, без раскачивания.\n'
            '7. Дышите ровно: выдох на разгибании, вдох на сгибании.\n'
            '8. Плечи не поднимайте.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Работайте с весом, который позволяет сделать 10–12 повторений с полным контролем.\n'
            '11. Для акцента на длинную головку используйте канат.\n'
            '12. Для акцента на латеральную головку используйте прямую рукоять.',
        'commonMistakes': '1. Движение плечами.\n'
            '2. Слишком большой вес.\n'
            '3. Неполная амплитуда.\n'
            '4. Разведение локтей.\n'
            '5. Слишком быстрый темп.\n'
            '6. Расслабление трицепса в верхней точке.\n'
            '7. Раскачивание корпусом.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в локтях.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с максимальными весами без техники.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_047',
        'name': 'Сгибание рук со штангой обратным хватом',
        'description': 'Сгибание рук со штангой обратным хватом — упражнение для плечевой мышцы и разгибателей предплечья. Придаёт рукам толщину и улучшает внешний вид предплечий. Часто используется как дополнение к классическим подъёмам на бицепс. Требует умеренного веса из-за слабости разгибателей. Сгибание обратным хватом отлично сочетается с молотками и сгибанием запястий. Это одно из ключевых упражнений для предплечий.',
        'muscleGroups': '["biceps","forearms"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу хватом сверху (обратным), чуть шире плеч.\n'
            '2. Локти прижаты к корпусу.\n'
            '3. Поднимайте штангу до уровня груди.\n'
            '4. Пауза на пике на 1 секунду.\n'
            '5. Опускайте контролируемо.\n'
            '6. Корпус стабилен.\n'
            '7. Работайте с умеренным весом.\n'
            '8. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '9. Плечи не поднимайте.\n'
            '10. Запястья нейтрально, хват уверенный.\n'
            '11. Работайте с весом, который позволяет сделать 10–12 повторений с полным контролем.\n'
            '12. Для акцента на предплечья используйте более тяжёлый вес.',
        'commonMistakes': '1. Слишком большой вес — работа запястьями.\n'
            '2. Раскачивание.\n'
            '3. Разведение локтей.\n'
            '4. Неполная амплитуда.\n'
            '5. Слишком быстрый темп.\n'
            '6. Сгибание запястий — перегрузка.\n'
            '7. Расслабление в нижней точке.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в локтях или запястьях.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с максимальными весами без техники.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_048',
        'name': 'Трицепсовые отжимания от скамьи',
        'description': 'Трицепсовые отжимания от скамьи — простое и эффективное упражнение для трицепса с собственным весом. Не требует специального оборудования, доступно в любых условиях. Основная нагрузка идёт на трицепс, при правильной технике также включаются передние дельты. Хорошо масштабируется положением ног и дополнительным весом. Трицепсовые отжимания отлично сочетаются с другими упражнениями на трицепс. Это одно из ключевых упражнений для трицепса в домашних условиях.',
        'muscleGroups': '["triceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте на край скамьи, руки на скамье чуть шире плеч.\n'
            '2. Сдвиньте таз вперёд, ноги на полу или на другой скамье.\n'
            '3. Локти направлены назад, а не в стороны.\n'
            '4. Опускайтесь до угла 90° в локтях.\n'
            '5. Спина близко к скамье.\n'
            '6. Поднимайтесь за счёт трицепса.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Плечи не поднимайте к ушам.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Для облегчения согните ноги, для усложнения выпрямите.\n'
            '11. Для усложнения положите отягощение на бёдра.\n'
            '12. Работайте с полной амплитудой.',
        'commonMistakes': '1. Локти в стороны — перегрузка плеч.\n'
            '2. Слишком низкое опускание.\n'
            '3. Отрыв таза от скамьи.\n'
            '4. Слишком быстрый темп.\n'
            '5. Нагрузка на плечи вместо трицепса.\n'
            '6. Отсутствие контроля в нижней точке.\n'
            '7. Слишком большой объём без разминки.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в плечах или локтях.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с отягощением без страховки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_049',
        'name': 'Концентрационные сгибания',
        'description': 'Концентрационные сгибания — изолирующее упражнение для бицепса с опорой на колено. Акцент на пиковое сокращение и максимальную концентрацию на мышце. Позволяет работать в медленном темпе и чувствовать каждое волокно. Отлично подходит для добивки и работы над пиком бицепса. Концентрационные сгибания отлично сочетаются с подъёмом штанги и молотками. Это одно из ключевых упражнений для пикового сокращения бицепса.',
        'muscleGroups': '["biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте на скамью, ноги широко, локоть опирается на внутреннюю сторону бедра.\n'
            '2. Локоть зафиксирован на протяжении движения.\n'
            '3. Поднимайте гантель до максимального сокращения бицепса.\n'
            '4. Пауза на пике на 1–2 секунды.\n'
            '5. Опускайте медленно и контролируемо.\n'
            '6. Не помогайте корпусом.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Плечи не поднимайте.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Работайте с весом, который позволяет сделать 10–12 повторений с полным контролем.\n'
            '11. Работайте медленно, концентрируясь на ощущении.\n'
            '12. Выполняйте поочерёдно для каждой руки.',
        'commonMistakes': '1. Раскачивание.\n'
            '2. Слишком большой вес.\n'
            '3. Слишком быстрый темп.\n'
            '4. Работа плечом.\n'
            '5. Неполная амплитуда.\n'
            '6. Отсутствие паузы на пике.\n'
            '7. Смещение локтя с опоры.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в локтях.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с максимальными весами без техники.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_050',
        'name': 'Сгибание запястий',
        'description': 'Сгибание запястий — упражнение для развития мышц предплечья и силы хвата. Сильный хват важен для тяговых движений и повседневной жизни. Упражнение простое и безопасное, при этом эффективно для укрепления предплечий. Рекомендуется включать в план регулярно. Сгибание запястий отлично сочетается со сгибанием обратным хватом и молотками. Это одно из ключевых упражнений для предплечий и хвата.',
        'muscleGroups': '["forearms"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте, предплечья на коленях или скамье.\n'
            '2. Хват снизу, гантели или штанга.\n'
            '3. Сгибайте только запястья, поднимая вес вверх.\n'
            '4. Полная амплитуда: от глубокого разгибания до максимального сгибания.\n'
            '5. Медленный контролируемый темп.\n'
            '6. Локти не двигаются.\n'
            '7. Дышите ровно: выдох на сгибании, вдох на разгибании.\n'
            '8. Плечи не поднимайте.\n'
            '9. Запястья работают в полной амплитуде.\n'
            '10. Работайте с весом, который позволяет сделать 12–15 повторений с полным контролем.\n'
            '11. Для акцента на предплечья используйте штангу.\n'
            '12. Для акцента на баланс используйте гантели.',
        'commonMistakes': '1. Рывки.\n'
            '2. Слишком большой вес.\n'
            '3. Работа локтями.\n'
            '4. Неполная амплитуда.\n'
            '5. Слишком быстрый темп.\n'
            '6. Расслабление в нижней точке.\n'
            '7. Отсутствие контроля над запястьями.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в запястьях.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с максимальными весами без техники.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ============================================================
      // ПРЕСС И КОР (CORE) — 6
      // ============================================================
      {
        'id': 'ex_default_021',
        'name': 'Скручивания',
        'description': 'Скручивания — базовое упражнение для прямых мышц живота. Простое, но эффективное для развития пресса. Правильная техника — скручивание корпуса, а не подъём всего тела. Хорошо подходит для новичков и для разминки перед более сложными упражнениями на пресс. Масштабируется дополнительным весом. Скручивания отлично сочетаются с планкой и подъёмом ног. Это одно из ключевых упражнений для пресса.',
        'muscleGroups': '["abs"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на спину, ноги согнуты, стопы на полу.\n'
            '2. Поясница прижата к полу.\n'
            '3. Подбородок не прижимайте к груди.\n'
            '4. Скручивайте корпус за счёт напряжения пресса, а не тяните шеей.\n'
            '5. Пауза в верхней точке на 1 секунду.\n'
            '6. Опускайтесь медленно, не расслабляя пресс полностью.\n'
            '7. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '8. Руки за головой, но не тяните ими.\n'
            '9. Плечи не поднимайте к ушам.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Для усложнения добавьте отягощение на грудь.\n'
            '12. Работайте с весом, который позволяет сделать 15–20 повторений с полным контролем.',
        'commonMistakes': '1. Рывки и работа шеей.\n'
            '2. Неполная амплитуда.\n'
            '3. Отрыв поясницы.\n'
            '4. Слишком быстрый темп.\n'
            '5. Тяга руками за голову.\n'
            '6. Расслабление пресса в нижней точке.\n'
            '7. Слишком высокий подъём корпуса (превращается в подъём всего тела).\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в пояснице или шее.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с отягощением без техники.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_022',
        'name': 'Планка',
        'description': 'Планка — статическое упражнение для кора, которое укрепляет мышцы живота, спины и стабилизаторы. Одно из самых эффективных и доступных упражнений для укрепления центра тела. Улучшает осанку и снижает риск травм поясницы. Легко масштабируется временем удержания и усложнёнными вариантами (боковая планка, планка с подъёмом руки и т.д.). Планка отлично сочетается со скручиваниями и подъёмом ног. Это одно из ключевых упражнений для кора.',
        'muscleGroups': '["abs","obliques","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'defaultFormat': 'hold',  // 🆕
        'techniqueTips': '1. Примите упор на предплечья и носки.\n'
            '2. Тело — прямая линия от пяток до макушки.\n'
            '3. Пресс и ягодицы напряжены.\n'
            '4. Не прогибайтесь в пояснице и не поднимайте таз.\n'
            '5. Локти под плечами.\n'
            '6. Дышите ровно.\n'
            '7. Держите 30–60 секунд в зависимости от уровня.\n'
            '8. Голова в нейтральном положении, взгляд в пол.\n'
            '9. Плечи не поднимайте к ушам.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Для усложнения поднимите одну руку или ногу.\n'
            '12. Для усложнения используйте нестабильную опору.',
        'commonMistakes': '1. Провисание в пояснице.\n'
            '2. Поднятый таз.\n'
            '3. Задержка дыхания.\n'
            '4. Слишком долгое удержание в ущерб технике.\n'
            '5. Расслабленный пресс.\n'
            '6. Голова опущена вниз — перегрузка шеи.\n'
            '7. Локти слишком далеко впереди плеч.\n'
            '8. Подъём плеч к ушам.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в пояснице или плечах.\n'
            '11. Отсутствие разминки.\n'
            '12. Слишком длинное удержание без подготовки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_023',
        'name': 'Подъём ног в висе',
        'description': 'Подъём ног в висе — сложное упражнение для нижнего пресса, требующее силы хвата и контроля кора. Одно из самых эффективных для нижней части живота. Выполняется на перекладине или в висе на брусьях. Масштабируется сгибанием коленей (облегчённый вариант). Подъём ног в висе отлично сочетается со скручиваниями и планкой. Это одно из ключевых упражнений для нижнего пресса.',
        'muscleGroups': '["abs","obliques"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Повисните на перекладине, хват чуть шире плеч.\n'
            '2. Не раскачивайтесь, корпус стабилен.\n'
            '3. Поднимайте ноги до параллели с полом или выше.\n'
            '4. Опускайте контролируемо, не давая ногам упасть.\n'
            '5. Работайте за счёт пресса, а не сгибателей бедра.\n'
            '6. Дышите ровно: выдох на подъёме, вдох на опускании.\n'
            '7. Начинайте с согнутых коленей, если тяжело.\n'
            '8. Плечи не поднимайте к ушам.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Для усложнения добавьте отягощение.\n'
            '12. Работайте с весом, который позволяет сделать 10–15 повторений с полным контролем.',
        'commonMistakes': '1. Раскачивание.\n'
            '2. Работа сгибателями бедра.\n'
            '3. Неполная амплитуда.\n'
            '4. Расслабленный кор.\n'
            '5. Слишком быстрый темп.\n'
            '6. Отсутствие контроля в нижней точке.\n'
            '7. Слишком большой объём без разминки.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в пояснице или плечах.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с отягощением без подготовки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_051',
        'name': 'Боковая планка',
        'description': 'Боковая планка — статическое упражнение для косых мышц живота и стабильности кора. Укрепляет боковые мышцы, улучшает баланс и снижает риск травм поясницы. Отлично дополняет классическую планку и скручивания. Легко масштабируется временем удержания. Боковая планка отлично сочетается со скручиваниями и русским твистом. Это одно из ключевых упражнений для косых мышц.',
        'muscleGroups': '["obliques","abs","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'defaultFormat': 'hold',  // 🆕
        'isCustom': 0,
        'techniqueTips': '1. Лягте на бок, опора на локоть под плечом.\n'
            '2. Тело — прямая линия сбоку.\n'
            '3. Таз не провисает.\n'
            '4. Вторая рука на поясе или вытянута вверх.\n'
            '5. Дышите ровно.\n'
            '6. Держите 20–40 секунд на каждую сторону.\n'
            '7. Следите за стабильностью плеча.\n'
            '8. Голова в нейтральном положении.\n'
            '9. Плечи не поднимайте к ушам.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Для усложнения поднимите верхнюю ногу.\n'
            '12. Для усложнения используйте нестабильную опору.',
        'commonMistakes': '1. Провисание таза.\n'
            '2. Сгибание в пояснице.\n'
            '3. Опора на плечо вместо локтя.\n'
            '4. Задержка дыхания.\n'
            '5. Слишком долгое удержание в ущерб технике.\n'
            '6. Расслабленный кор.\n'
            '7. Голова провисает.\n'
            '8. Подъём плеч к ушам.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в плечах.\n'
            '11. Отсутствие разминки.\n'
            '12. Слишком длинное удержание без подготовки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_052',
        'name': 'Вакуум живота',
        'description': 'Вакуум живота — дыхательное упражнение для поперечной мышцы живота. Укрепляет кор, улучшает осанку и визуально уменьшает живот. Выполняется натощак для лучшего эффекта. Не заменяет силовые упражнения на пресс, но хорошо дополняет их. Вакуум отлично сочетается со скручиваниями и планкой. Это одно из ключевых упражнений для поперечной мышцы живота.',
        'muscleGroups': '["abs"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'defaultFormat': 'hold',  // 🆕
        'isCustom': 0,
        'techniqueTips': '1. Встаньте прямо или сядьте, спина прямая.\n'
            '2. Сделайте полный выдох.\n'
            '3. Максимально втяните живот, как будто пытаетесь дотянуться пупком до позвоночника.\n'
            '4. Задержите дыхание на 15–30 секунд.\n'
            '5. Медленно выдохните и расслабьтесь.\n'
            '6. Работайте натощак для лучшего эффекта.\n'
            '7. Повторяйте 3–5 подходов.\n'
            '8. Дышите ровно после упражнения.\n'
            '9. Плечи не поднимайте.\n'
            '10. Работайте с полной амплитудой втягивания.\n'
            '11. Для усложнения выполняйте лёжа.\n'
            '12. Работайте регулярно для лучшего эффекта.',
        'commonMistakes': '1. Поверхностное дыхание.\n'
            '2. Неправильная техника втягивания.\n'
            '3. Слишком долгая задержка дыхания.\n'
            '4. Резкий выход.\n'
            '5. Выполнение после еды.\n'
            '6. Слишком малое количество повторений.\n'
            '7. Отсутствие регулярности.\n'
            '8. Слишком сильное напряжение.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через головокружение.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с задержкой дыхания дольше 30 секунд.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_053',
        'name': 'Ножницы ногами',
        'description': 'Ножницы ногами — динамическое упражнение для нижнего пресса и бёдер. Простое и эффективное, хорошо подходит для дома и для разминки. Активно работает нижняя часть живота и косые мышцы. Легко масштабируется амплитудой и темпом. Ножницы отлично сочетаются со скручиваниями и подъёмом ног. Это одно из ключевых упражнений для нижнего пресса.',
        'muscleGroups': '["abs","obliques","quadriceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на спину, руки вдоль тела или под таз.\n'
            '2. Поясница прижата к полу.\n'
            '3. Поднимите ноги на 15–20 см от пола.\n'
            '4. Скрещивайте ноги попеременно, как ножницы.\n'
            '5. Работайте в умеренном темпе.\n'
            '6. Дышите ровно.\n'
            '7. Выполняйте 20–30 секунд.\n'
            '8. Руки под таз для поддержки поясницы.\n'
            '9. Плечи не поднимайте.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Для усложнения поднимите ноги выше.\n'
            '12. Работайте с весом, который позволяет сделать 20–30 секунд с полным контролем.',
        'commonMistakes': '1. Отрыв поясницы.\n'
            '2. Согнутые колени.\n'
            '3. Слишком быстрый темп.\n'
            '4. Расслабленный пресс.\n'
            '5. Слишком высокий подъём ног — снижает нагрузку.\n'
            '6. Задержка дыхания.\n'
            '7. Отсутствие контроля над ногами.\n'
            '8. Слишком быстрый негатив.\n'
            '9. Работа без полной амплитуды.\n'
            '10. Работа через боль в пояснице.\n'
            '11. Отсутствие разминки.\n'
            '12. Работа с отягощением без техники.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ============================================================
      // КАРДИО (CARDIO) — 4
      // ============================================================
      {
        'id': 'ex_default_024',
        'name': 'Бег на дорожке',
        'description': 'Бег на дорожке — классическое кардио для сжигания калорий и укрепления сердечно-сосудистой системы. Легко регулировать темп, наклон и продолжительность. Подходит для любого уровня подготовки. Регулярный бег улучшает выносливость, работу сердца и общее самочувствие. Бег отлично сочетается с силовыми тренировками и йогой. Это одно из самых популярных кардио-упражнений.',
        'muscleGroups': '["cardio_vascular","quadriceps","calves"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips': '1. Начните с разминки 5 минут ходьбы.\n'
            '2. Ровный темп, дыхание через нос.\n'
            '3. Следите за пульсом (обычно 60–75% от максимума).\n'
            '4. Правильная постановка стопы — с пятки на носок.\n'
            '5. Не держитесь за поручни.\n'
            '6. Завершайте заминкой 5 минут ходьбы.\n'
            '7. Пейте воду до и после.\n'
            '8. Правильная обувь.\n'
            '9. Следите за осанкой.\n'
            '10. Дышите ровно.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Регулируйте наклон для разнообразия.',
        'commonMistakes': '1. Слишком быстрый старт.\n'
            '2. Неправильная постановка стопы.\n'
            '3. Опора на поручни.\n'
            '4. Игнорирование разминки и заминки.\n'
            '5. Слишком высокий пульс без необходимости.\n'
            '6. Обезвоживание.\n'
            '7. Неправильная обувь.\n'
            '8. Слишком длинная сессия без подготовки.\n'
            '9. Работа без контроля пульса.\n'
            '10. Работа через боль в суставах.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Работа без плана.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_025',
        'name': 'Велотренажёр',
        'description': 'Велотренажёр — кардио с низкой нагрузкой на суставы. Отлично подходит для сжигания жира и укрепления сердца, безопасно для коленей и поясницы. Легко регулировать сопротивление и темп. Хорошо подходит для интервальных тренировок и для восстановления. Велотренажёр отлично сочетается с силовыми тренировками. Это одно из самых безопасных кардио-упражнений.',
        'muscleGroups': '["cardio_vascular","quadriceps","glutes"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips': '1. Отрегулируйте высоту сиденья: нога почти прямая в нижней точке.\n'
            '2. Ровный темп.\n'
            '3. Полная амплитуда педалирования.\n'
            '4. Следите за осанкой, не сутультесь.\n'
            '5. Дышите ровно.\n'
            '6. Пейте воду.\n'
            '7. Завершайте заминкой.\n'
            '8. Правильная обувь.\n'
            '9. Следите за пульсом.\n'
            '10. Регулируйте сопротивление.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Работайте с полной амплитудой.',
        'commonMistakes': '1. Слишком низкое сиденье.\n'
            '2. Слишком большое сопротивление.\n'
            '3. Сутулость.\n'
            '4. Слишком быстрый темп без контроля.\n'
            '5. Отсутствие разминки.\n'
            '6. Обезвоживание.\n'
            '7. Слишком долгая сессия без перерыва.\n'
            '8. Неправильная обувь.\n'
            '9. Работа без контроля пульса.\n'
            '10. Работа через боль в коленях.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Работа без плана.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_026',
        'name': 'Плавание',
        'description': 'Плавание — кардио на всё тело с минимальной нагрузкой на суставы. Отлично развивает выносливость, укрепляет мышцы и улучшает работу сердечно-сосудистой системы. Подходит для людей с ограничениями по суставам и для восстановления после травм. Требует базовой техники. Плавание отлично сочетается с силовыми тренировками и йогой. Это одно из самых полезных кардио-упражнений.',
        'muscleGroups': '["cardio_vascular","fullBody"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips': '1. Начните с разминки в воде.\n'
            '2. Следите за дыханием: вдох над водой, выдох в воду.\n'
            '3. Работайте ногами.\n'
            '4. Правильная техника гребка.\n'
            '5. Ровный темп.\n'
            '6. Пейте воду.\n'
            '7. Завершайте спокойным плаванием.\n'
            '8. Правильная техника безопасности.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте стили плавания.',
        'commonMistakes': '1. Задержка дыхания.\n'
            '2. Неправильная техника.\n'
            '3. Слишком быстрый темп.\n'
            '4. Игнорирование разминки.\n'
            '5. Обезвоживание.\n'
            '6. Слишком длинные сессии без отдыха.\n'
            '7. Отсутствие техники безопасности.\n'
            '8. Работа без контроля пульса.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_054',
        'name': 'Прыжки на скакалке',
        'description': 'Прыжки на скакалке — эффективное кардио для всего тела. Развивает выносливость, координацию и силу ног. Доступно в любых условиях и не требует много места. Хорошо подходит для разминки и для интервальных тренировок. Прыжки на скакалке отлично сочетаются с силовыми тренировками и HIIT. Это одно из самых эффективных кардио-упражнений.',
        'muscleGroups': '["cardio_vascular","calves","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите скакалку правильно: локти близко к корпусу.\n'
            '2. Ритмичные прыжки на носках.\n'
            '3. Вращение кистями, а не плечами.\n'
            '4. Мягкое приземление.\n'
            '5. Ровное дыхание.\n'
            '6. Начните с 30 секунд и постепенно увеличивайте.\n'
            '7. Завершайте заминкой.\n'
            '8. Правильная обувь.\n'
            '9. Следите за пульсом.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте техники прыжков.',
        'commonMistakes': '1. Сильное приземление.\n'
            '2. Вращение плечами.\n'
            '3. Слишком высокие прыжки.\n'
            '4. Слишком быстрый темп в начале.\n'
            '5. Отсутствие разминки.\n'
            '6. Слишком длинная сессия.\n'
            '7. Неправильная обувь.\n'
            '8. Работа без контроля пульса.\n'
            '9. Работа через боль в коленях или ахилле.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ============================================================
      // БОКС (BOXING) — 2
      // ============================================================
      {
        'id': 'ex_default_027',
        'name': 'Работа на груше',
        'description': 'Работа на груше — ударная тренировка, развивающая координацию, взрывную силу и выносливость. Отлично подходит для кардио и функциональной подготовки. Улучшает технику ударов и работу ног. Доступно в любом зале с грушей. Работа на груше отлично сочетается с боем с тенью и кардио. Это одно из ключевых упражнений в боксе и фитнесе.',
        'muscleGroups': '["shoulders","back","abs","fullBody"]',
        'imageUrl': '',
        'exerciseType': 'boxing',
        'isCustom': 0,
        'techniqueTips': '1. Руки у подбородка, стойка боксёрская.\n'
            '2. Работайте ногами, а не только руками.\n'
            '3. Дышите ровно, не задерживайте дыхание.\n'
            '4. Правильная дистанция.\n'
            '5. Бейте техникой, а не силой.\n'
            '6. Двигайтесь вокруг груши.\n'
            '7. Завершайте растяжкой плеч.\n'
            '8. Правильная стойка.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте комбинации.',
        'commonMistakes': '1. Опускание рук.\n'
            '2. Неправильная дистанция.\n'
            '3. Работа только руками без ног.\n'
            '4. Задержка дыхания.\n'
            '5. Слишком сильные удары без техники.\n'
            '6. Отсутствие разминки.\n'
            '7. Неправильная стойка.\n'
            '8. Работа без контроля техники.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_028',
        'name': 'Бой с тенью',
        'description': 'Бой с тенью — имитация боя без снаряда, развивающая координацию, технику и выносливость. Отлично подходит для разминки и кардио-сессий. Позволяет отрабатывать комбинации и работу ног без риска травмы. Не требует оборудования. Бой с тенью отлично сочетается с работой на груше и кардио. Это одно из ключевых упражнений в боксе и фитнесе.',
        'muscleGroups': '["shoulders","fullBody","cardio_vascular"]',
        'imageUrl': '',
        'exerciseType': 'boxing',
        'isCustom': 0,
        'techniqueTips': '1. Двигайтесь на носках.\n'
            '2. Работайте ногами, а не только руками.\n'
            '3. Дыхание через нос.\n'
            '4. Представляйте реального соперника.\n'
            '5. Меняйте темп и комбинации.\n'
            '6. Держите руки у подбородка.\n'
            '7. Завершайте растяжкой.\n'
            '8. Правильная стойка.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте комбинации.',
        'commonMistakes': '1. Статичность.\n'
            '2. Опускание рук.\n'
            '3. Работа только руками.\n'
            '4. Задержка дыхания.\n'
            '5. Отсутствие работы ног.\n'
            '6. Однообразные движения.\n'
            '7. Слишком быстрый темп без техники.\n'
            '8. Работа без контроля техники.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ============================================================
      // ЙОГА И РАСТЯЖКА — 4
      // ============================================================
      {
        'id': 'ex_default_029',
        'name': 'Растяжка всего тела',
        'description': 'Растяжка всего тела — комплекс упражнений на гибкость и расслабление. Подходит для завершения тренировки или отдельной сессии. Улучшает подвижность, снижает риск травм и помогает восстановлению. Особенно важно после силовых и кардио-тренировок. Растяжка отлично сочетается с йогой и медитацией. Это одно из ключевых упражнений для восстановления.',
        'muscleGroups': '["flexibility","fullBody"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Дышите глубоко и ровно.\n'
            '2. Не делайте резких движений.\n'
            '3. Слушайте тело, не идите через боль.\n'
            '4. Задерживайтесь в каждом положении 20–30 секунд.\n'
            '5. Растягивайте все основные группы мышц.\n'
            '6. Завершайте расслаблением.\n'
            '7. Пейте воду после.\n'
            '8. Правильная техника.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте упражнения.',
        'commonMistakes': '1. Пружинистые движения.\n'
            '2. Задержка дыхания.\n'
            '3. Слишком сильное растяжение.\n'
            '4. Спешка.\n'
            '5. Пропуск групп мышц.\n'
            '6. Растяжка на холодные мышцы.\n'
            '7. Неправильная техника.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_030',
        'name': 'Собака мордой вниз',
        'description': 'Собака мордой вниз — классическая асана йоги, которая растягивает и укрепляет всё тело, особенно спину, плечи, заднюю поверхность бедра и икры. Улучшает кровообращение и снимает напряжение. Подходит для любого уровня, легко модифицируется. Собака мордой вниз отлично сочетается с другими асанами йоги. Это одна из самых популярных асан в йоге.',
        'muscleGroups': '["flexibility","shoulders","hamstrings","calves"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте на четвереньки, ладони под плечами.\n'
            '2. Поднимите таз вверх, формируя перевёрнутую V.\n'
            '3. Пятки к полу (можно чуть согнуть колени).\n'
            '4. Спина прямая, руки прямые.\n'
            '5. Голова между рук, шея расслаблена.\n'
            '6. Дышите ровно.\n'
            '7. Держите 30–60 секунд.\n'
            '8. Плечи не поднимайте к ушам.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного входа.\n'
            '12. Разнообразьте варианты (с согнутыми коленями, на носках).',
        'commonMistakes': '1. Округление спины.\n'
            '2. Отрыв пяток.\n'
            '3. Согнутые руки.\n'
            '4. Задержка дыхания.\n'
            '5. Слишком сильное давление на запястья.\n'
            '6. Голова поднята — перегрузка шеи.\n'
            '7. Слишком быстрый вход в позу.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_055',
        'name': 'Кобра',
        'description': 'Кобра — асана с прогибом назад из положения лёжа. Укрепляет спину, раскрывает грудную клетку и улучшает осанку. Полезна для людей, проводящих много времени за компьютером. Требует осторожности при проблемах с поясницей. Кобра отлично сочетается с собакой мордой вниз и другими асанами. Это одна из ключевых асан для спины.',
        'muscleGroups': '["flexibility","back","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на живот, ладони под плечами.\n'
            '2. Начинайте с лёгкого прогиба.\n'
            '3. Не перенапрягайте поясницу.\n'
            '4. Дышите ровно.\n'
            '5. Следите за ощущениями.\n'
            '6. Держите 15–30 секунд.\n'
            '7. Опускайтесь медленно.\n'
            '8. Плечи не поднимайте к ушам.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного входа.\n'
            '12. Разнообразьте варианты (с опорой на предплечья).',
        'commonMistakes': '1. Резкий прогиб.\n'
            '2. Перенапряжение.\n'
            '3. Задержка дыхания.\n'
            '4. Слишком сильное давление на руки.\n'
            '5. Слишком высокий подъём без подготовки.\n'
            '6. Слишком быстрый выход из позы.\n'
            '7. Работа через боль.\n'
            '8. Работа без контроля.\n'
            '9. Работа без плана.\n'
            '10. Отсутствие разнообразия.\n'
            '11. Слишком быстрый старт.\n'
            '12. Работа без разминки.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_056',
        'name': 'Растяжка подколенных сухожилий',
        'description': 'Растяжка подколенных сухожилий — упражнение для бицепса бедра и икроножных мышц. Важна для профилактики травм и улучшения гибкости. Особенно полезна для людей, которые много сидят. Улучшает осанку и снижает нагрузку на поясницу. Растяжка отлично сочетается с йогой и силовыми тренировками. Это одно из ключевых упражнений для задней поверхности бедра.',
        'muscleGroups': '["flexibility","hamstrings","calves"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте или встаньте, ноги вместе или на ширине плеч.\n'
            '2. Наклоняйтесь вперёд, спина прямая.\n'
            '3. Не круглите спину.\n'
            '4. Дышите ровно.\n'
            '5. Задерживайтесь 20–30 секунд.\n'
            '6. Не пружиньте.\n'
            '7. Растягивайте до комфортного натяжения.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного входа.\n'
            '12. Разнообразьте варианты (стоя, сидя, лёжа).',
        'commonMistakes': '1. Округление спины.\n'
            '2. Рывки.\n'
            '3. Слишком сильное растяжение.\n'
            '4. Задержка дыхания.\n'
            '5. Слишком быстрый вход в позу.\n'
            '6. Пружинистые движения.\n'
            '7. Отсутствие регулярности.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ============================================================
      // ДОПОЛНИТЕЛЬНЫЕ — 4
      // ============================================================
      {
        'id': 'ex_default_057',
        'name': 'Гиперэкстензия',
        'description': 'Гиперэкстензия — упражнение для поясницы и ягодиц на специальной скамье. Укрепляет позвоночник и мышцы-разгибатели спины. Полезна для профилактики болей в пояснице. Требует умеренного темпа и аккуратной техники. Гиперэкстензия отлично сочетается со становой тягой и румынской тягой. Это одно из ключевых упражнений для поясницы.',
        'muscleGroups': '["lowerBack","glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Зафиксируйте ноги на скамье, бёдра на подушке.\n'
            '2. Медленный подъём корпуса.\n'
            '3. Задержка в верхней точке.\n'
            '4. Не переразгибайте поясницу.\n'
            '5. Дышите ровно.\n'
            '6. Опускайтесь контролируемо.\n'
            '7. Работайте с собственным весом или умеренным отягощением.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте варианты (с отягощением, с паузой).',
        'commonMistakes': '1. Рывки.\n'
            '2. Слишком высокий подъём.\n'
            '3. Слишком большой вес.\n'
            '4. Расслабленная спина.\n'
            '5. Слишком быстрый темп.\n'
            '6. Переразгибание в верхней точке.\n'
            '7. Отсутствие контроля в нижней точке.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_058',
        'name': 'Берпи',
        'description': 'Берпи — комплексное функциональное упражнение, сочетающее присед, отжимание и прыжок. Развивает взрывную силу, выносливость и сжигает много калорий. Одно из лучших упражнений для HIIT. Требует базовой физической подготовки. Берпи отлично сочетается с другими HIIT-упражнениями. Это одно из самых эффективных функциональных упражнений.',
        'muscleGroups': '["fullBody","cardio_vascular","chest","quadriceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Из стойки присядьте и поставьте ладони на пол.\n'
            '2. Прыжком перейдите в упор лёжа.\n'
            '3. Отжимание (опционально).\n'
            '4. Прыжком вернитесь в присед.\n'
            '5. Выпрыгните вверх.\n'
            '6. Плавные движения, дыхание ровное.\n'
            '7. Контролируемый темп.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте варианты (без отжимания, с прыжком).',
        'commonMistakes': '1. Рывки.\n'
            '2. Неполная амплитуда.\n'
            '3. Провисание в упоре.\n'
            '4. Слишком быстрый темп без контроля.\n'
            '5. Неправильная техника приземления.\n'
            '6. Отсутствие разминки.\n'
            '7. Слишком большой объём без подготовки.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях или пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_059',
        'name': 'Запрыгивания на тумбу',
        'description': 'Запрыгивания на тумбу — плиометрическое упражнение для развития взрывной силы ног. Тренирует мощь, скорость и координацию. Широко используется в спортивной подготовке. Требует безопасной высоты и хорошей техники приземления. Запрыгивания отлично сочетаются с приседаниями и выпадами. Это одно из ключевых плиометрических упражнений.',
        'muscleGroups': '["quadriceps","glutes","calves"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте перед тумбой.\n'
            '2. Присядьте и выпрыгните на тумбу.\n'
            '3. Мягкое приземление на полную стопу.\n'
            '4. Работа коленями, а не спиной.\n'
            '5. Безопасная высота тумбы.\n'
            '6. Сходите с тумбы шагом, а не прыжком.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с низкой тумбы.\n'
            '12. Разнообразьте варианты (с одной ноги, с отягощением).',
        'commonMistakes': '1. Жёсткое приземление.\n'
            '2. Слишком высокая тумба.\n'
            '3. Неправильная техника.\n'
            '4. Недостаточная разминка.\n'
            '5. Прыжок вниз с тумбы.\n'
            '6. Слишком большое количество повторений.\n'
            '7. Отсутствие контроля над коленями.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_060',
        'name': 'Русский твист',
        'description': 'Русский твист — упражнение для косых мышц живота и пресса. Можно выполнять с весом или без. Развивает силу кора и стабильность. Хорошо дополняет классические скручивания и планку. Масштабируется весом и скоростью. Русский твист отлично сочетается со скручиваниями и боковой планкой. Это одно из ключевых упражнений для косых мышц.',
        'muscleGroups': '["abs","obliques","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте на пол, ноги на весу или на полу.\n'
            '2. Корпус слегка отклонён назад.\n'
            '3. Поворачивайте корпус в стороны.\n'
            '4. Спина прямая.\n'
            '5. Дышите ровно.\n'
            '6. Работайте в умеренном темпе.\n'
            '7. Можете держать гантель или мяч.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте варианты (с весом, с ногами на весу).',
        'commonMistakes': '1. Работа ногами, а не корпусом.\n'
            '2. Округление спины.\n'
            '3. Слишком быстрый темп.\n'
            '4. Слишком большой вес.\n'
            '5. Отсутствие контроля над корпусом.\n'
            '6. Неполная амплитуда.\n'
            '7. Задержка дыхания.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ============================================================
      // v12: 61–100
      // ============================================================
      {
        'id': 'ex_default_061',
        'name': 'Жим Свенда',
        'description': 'Жим Свенда — изолирующее упражнение для внутренней части грудных. Выполняется с блином, который нужно сжимать ладонями. Создаёт мощное напряжение в груди. Отлично подходит для добивки. Не требует много оборудования. Жим Свенда отлично сочетается со сведением в кроссовере и разводкой. Это одно из ключевых упражнений для внутренней части груди.',
        'muscleGroups': '["chest","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите блин двумя ладонями перед грудью.\n'
            '2. Сжимайте ладони, создавая напряжение.\n'
            '3. Выжимайте блин перед грудью вперёд.\n'
            '4. Пауза в верхней точке.\n'
            '5. Медленное возвращение.\n'
            '6. Работайте с умеренным весом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого блина.\n'
            '12. Разнообразьте варианты (сидя, стоя).',
        'commonMistakes': '1. Слишком большой вес.\n'
            '2. Рывки.\n'
            '3. Разведение рук.\n'
            '4. Слишком быстрый темп.\n'
            '5. Отсутствие сжатия ладоней.\n'
            '6. Неполная амплитуда.\n'
            '7. Работа плечами вместо груди.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_062',
        'name': 'Пуловер с гантелью',
        'description': 'Пуловер с гантелью — упражнение, растягивающее грудные и широчайшие мышцы. Отлично для дыхания и раскрытия грудной клетки. Улучшает подвижность плеч. Хорошо сочетается с жимами. Пуловер отлично сочетается с разводкой и сведением в кроссовере. Это одно из ключевых упражнений для растяжения груди и широчайших.',
        'muscleGroups': '["chest","lats","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на скамью, держите гантель двумя руками над грудью.\n'
            '2. Медленно опускайте гантель за голову.\n'
            '3. Растягивайте грудь и широчайшие.\n'
            '4. Контролируемая амплитуда.\n'
            '5. Дышите ровно: вдох при опускании.\n'
            '6. Поднимайте обратно по той же траектории.\n'
            '7. Работайте с умеренным весом.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с гантелью, со штангой).',
        'commonMistakes': '1. Слишком большой вес.\n'
            '2. Прогиб в пояснице.\n'
            '3. Рывки.\n'
            '4. Слишком быстрый темп.\n'
            '5. Слишком глубокое опускание.\n'
            '6. Сгибание локтей.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_063',
        'name': 'Отжимания с широкой постановкой',
        'description': 'Отжимания с широкой постановкой рук — вариант отжиманий с акцентом на внешнюю часть грудных. Руки ставятся шире плеч. Хорошо дополняет классические отжимания. Масштабируется положением ног. Отжимания отлично сочетаются с жимами и разводкой. Это одно из ключевых упражнений для внешней части груди.',
        'muscleGroups': '["chest","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Примите упор лёжа с широкой постановкой рук.\n'
            '2. Тело — прямая линия.\n'
            '3. Локти в стороны.\n'
            '4. Опускайтесь до касания грудью пола.\n'
            '5. Полная амплитуда.\n'
            '6. Корпус стабилен.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с колен.\n'
            '12. Разнообразьте варианты (с ногами на скамье).',
        'commonMistakes': '1. Провисание таза.\n'
            '2. Неполная амплитуда.\n'
            '3. Слишком широкий хват.\n'
            '4. Быстрый темп.\n'
            '5. Отсутствие контроля.\n'
            '6. Работа шеей.\n'
            '7. Прогиб в пояснице.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_064',
        'name': 'Жим гантелей лежа на полу',
        'description': 'Жим гантелей лежа на полу — безопасная вариация жима, которая ограничивает амплитуду и защищает плечи. Отлично подходит для людей с чувствительными плечами. Развивает грудь и трицепсы. Масштабируется весом гантелей. Жим на полу отлично сочетается с жимом на скамье и разводкой. Это одно из ключевых упражнений для людей с проблемами плеч.',
        'muscleGroups': '["chest","triceps","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на пол, ноги согнуты.\n'
            '2. Гантели над грудью, ладони вперёд.\n'
            '3. Опускайте гантели до касания локтями пола.\n'
            '4. Не выпрямляйте руки полностью.\n'
            '5. Лопатки сведены.\n'
            '6. Контролируемый темп.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с одной гантелью).',
        'commonMistakes': '1. Слишком большой вес.\n'
            '2. Отрыв таза.\n'
            '3. Слишком быстрый темп.\n'
            '4. Разведение локтей.\n'
            '5. Неполная амплитуда.\n'
            '6. Расслабление в нижней точке.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_065',
        'name': 'Подтягивания обратным хватом',
        'description': 'Подтягивания обратным хватом — вариант подтягиваний с акцентом на бицепс и низ широчайших. Хват узкий, ладони к себе. Проще классических подтягиваний, хорошо подходит для новичков. Масштабируется резинкой. Подтягивания обратным хватом отлично сочетаются с тягой и подъёмом на бицепс. Это одно из ключевых упражнений для низа широчайших и бицепса.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Возьмитесь за перекладину обратным хватом (ладони к себе).\n'
            '2. Хват узкий, чуть уже плеч.\n'
            '3. Тянитесь грудью к перекладине.\n'
            '4. Локти вниз-назад.\n'
            '5. Опускайтесь контролируемо.\n'
            '6. Корпус стабилен.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с резинки.\n'
            '12. Разнообразьте варианты (с отягощением).',
        'commonMistakes': '1. Раскачивание.\n'
            '2. Неполная амплитуда.\n'
            '3. Расслабленные плечи.\n'
            '4. Рывки.\n'
            '5. Слишком широкий хват.\n'
            '6. Отсутствие разминки.\n'
            '7. Слишком быстрый темп.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_066',
        'name': 'Тяга штанги к поясу',
        'description': 'Тяга штанги к поясу в наклоне — вариант тяги с акцентом на нижнюю часть широчайших и ромбовидные. Тяга выполняется к низу живота. Хорошо развивает толщину спины. Требует нейтральной спины. Тяга к поясу отлично сочетается с подтягиваниями и тягой верхнего блока. Это одно из ключевых упражнений для толщины спины.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу хватом чуть шире плеч.\n'
            '2. Наклоните корпус до ~45°.\n'
            '3. Спина прямая.\n'
            '4. Тяните штангу к низу живота.\n'
            '5. Сводите лопатки в верхней точке.\n'
            '6. Опускайте контролируемо.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с Т-грифом).',
        'commonMistakes': '1. Округление спины.\n'
            '2. Рывки.\n'
            '3. Слишком большой вес.\n'
            '4. Тяга к груди.\n'
            '5. Разведение локтей.\n'
            '6. Отсутствие сведения лопаток.\n'
            '7. Слишком быстрый темп.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_067',
        'name': 'Тяга блока к груди обратным хватом',
        'description': 'Тяга верхнего блока обратным хватом — вариант тяги, прорабатывающий бицепс и широчайшие. Хват снизу. Отлично подходит для новичков. Масштабируется весом. Тяга обратным хватом отлично сочетается с подтягиваниями и подъёмом на бицепс. Это одно из ключевых упражнений для низа широчайших.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте, зафиксируйте бёдра.\n'
            '2. Возьмите рукоять обратным хватом.\n'
            '3. Тяните к груди.\n'
            '4. Сводите лопатки.\n'
            '5. Опускайте контролируемо.\n'
            '6. Корпус стабилен.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разным хватом).',
        'commonMistakes': '1. Отклонение корпуса.\n'
            '2. Слишком большой вес.\n'
            '3. Рывки.\n'
            '4. Неполная амплитуда.\n'
            '5. Подъём плеч к ушам.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие разминки.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_068',
        'name': 'Шраги со штангой',
        'description': 'Шраги со штангой — упражнение для трапеций. Развивает мощные плечи и шею, улучшает осанку. Выполняется с прямыми руками. Масштабируется весом штанги. Шраги отлично сочетаются с тягой к подбородку и махами. Это одно из ключевых упражнений для трапеций.',
        'muscleGroups': '["traps","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу хватом чуть шире плеч.\n'
            '2. Стойка ровная.\n'
            '3. Поднимайте плечи вверх.\n'
            '4. Задерживайтесь на секунду в верхней точке.\n'
            '5. Опускайте контролируемо.\n'
            '6. Не вращайте плечами.\n'
            '7. Работайте с умеренным весом.\n'
            '8. Следите за осанкой.\n'
            '9. Дышите ровно.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с гантелями, с штангой).',
        'commonMistakes': '1. Вращение плечами.\n'
            '2. Сгибание рук.\n'
            '3. Слишком большой вес.\n'
            '4. Рывки.\n'
            '5. Отсутствие паузы в верхней точке.\n'
            '6. Слишком быстрый темп.\n'
            '7. Расслабление в нижней точке.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в шее.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_069',
        'name': 'Пулловер на блоке',
        'description': 'Пулловер на блоке — изолирующее упражнение, растягивающее широчайшие и грудную клетку. Выполняется с прямыми руками. Хорошо дополняет тяги. Масштабируется весом. Пулловер на блоке отлично сочетается с тягой верхнего блока и пуловером с гантелью. Это одно из ключевых упражнений для растяжения широчайших.',
        'muscleGroups': '["back","lats","chest"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте у блока, возьмите рукоять.\n'
            '2. Руки прямые.\n'
            '3. Тяните рукоятку к бёдрам по дуге.\n'
            '4. Растягивайте широчайшие.\n'
            '5. Контролируемое движение.\n'
            '6. Корпус стабилен.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разной рукоятью).',
        'commonMistakes': '1. Сгибание локтей.\n'
            '2. Слишком большой вес.\n'
            '3. Рывки.\n'
            '4. Раскачивание корпусом.\n'
            '5. Неполная амплитуда.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_070',
        'name': 'Обратные разведения в кроссовере',
        'description': 'Обратные разведения в кроссовере — изолирующее упражнение для задних дельт. Отлично для осанки и сбалансированного развития плеч. Постоянное натяжение блока. Масштабируется весом. Обратные разведения отлично сочетаются с махами в наклоне и тягой к лицу. Это одно из ключевых упражнений для задних дельт.',
        'muscleGroups': '["shoulders","back"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте между блоками, возьмите рукоятки.\n'
            '2. Наклоните корпус вперёд.\n'
            '3. Разводите руки в стороны.\n'
            '4. Локти чуть согнуты.\n'
            '5. Работайте локтями.\n'
            '6. Держите корпус стабильным.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разными рукоятями).',
        'commonMistakes': '1. Работа спиной.\n'
            '2. Слишком большой вес.\n'
            '3. Рывки.\n'
            '4. Подъём выше плеч.\n'
            '5. Округление спины.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_071',
        'name': 'Подъём гантелей перед собой',
        'description': 'Подъём гантелей перед собой — упражнение для передних дельт. Простое и эффективное. Хорошо дополняет махи в стороны. Масштабируется весом. Подъём перед собой отлично сочетается с махами в стороны и жимами. Это одно из ключевых упражнений для передних дельт.',
        'muscleGroups': '["shoulders"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте ровно, гантели перед бёдрами.\n'
            '2. Поднимайте гантели перед собой.\n'
            '3. До уровня глаз.\n'
            '4. Локти чуть согнуты.\n'
            '5. Корпус стабилен.\n'
            '6. Работайте в умеренном темпе.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (поочерёдно, одновременно).',
        'commonMistakes': '1. Раскачивание.\n'
            '2. Работа корпусом.\n'
            '3. Слишком большой вес.\n'
            '4. Подъём выше глаз.\n'
            '5. Слишком быстрый темп.\n'
            '6. Полностью выпрямленные руки.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_072',
        'name': 'Жим Арнольда',
        'description': 'Жим Арнольда — вариация жима гантелей с разворотом кистей. Вовлекает все пучки дельт. Требует координации. Назван в честь Арнольда Шварценеггера. Масштабируется весом. Жим Арнольда отлично сочетается с махами и разведениями. Это одно из ключевых упражнений для дельт.',
        'muscleGroups': '["shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте, гантели перед грудью, ладони к себе.\n'
            '2. Разворачивайте кисти вверх при подъёме.\n'
            '3. Плавное движение.\n'
            '4. Спина прямая.\n'
            '5. Выжимайте вверх.\n'
            '6. Опускайте контролируемо.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (стоя, сидя).',
        'commonMistakes': '1. Слишком большой вес.\n'
            '2. Рывки.\n'
            '3. Прогиб в пояснице.\n'
            '4. Неполная амплитуда.\n'
            '5. Слишком быстрый темп.\n'
            '6. Отсутствие разворота кистей.\n'
            '7. Работа корпусом.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_073',
        'name': 'Разведение гантелей в наклоне',
        'description': 'Разведение гантелей в наклоне — изолирующее упражнение для задних дельт. Часто используется для баланса развития плеч. Улучшает осанку. Масштабируется весом. Разведение в наклоне отлично сочетается с обратными разведениями в кроссовере и тягой к лицу. Это одно из ключевых упражнений для задних дельт.',
        'muscleGroups': '["shoulders","back"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Наклоните корпус вперёд, спина прямая.\n'
            '2. Гантели в опущенных руках.\n'
            '3. Разводите руки в стороны.\n'
            '4. Работайте локтями.\n'
            '5. Сводите лопатки в верхней точке.\n'
            '6. Опускайте контролируемо.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с опорой на скамью).',
        'commonMistakes': '1. Округление спины.\n'
            '2. Работа трапециями.\n'
            '3. Слишком большой вес.\n'
            '4. Рывки.\n'
            '5. Подъём выше плеч.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_074',
        'name': 'Фронтальные приседания',
        'description': 'Фронтальные приседания — вариант приседаний со штангой на груди. Акцент на квадрицепсы и кор. Требует хорошей подвижности плеч. Отлично для развития ног. Масштабируется весом. Фронтальные приседания отлично сочетаются с приседаниями со штангой и выпадами. Это одно из ключевых упражнений для квадрицепсов.',
        'muscleGroups': '["quadriceps","glutes","abs"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Штанга на передних дельтах.\n'
            '2. Локти вперёд.\n'
            '3. Спина прямая.\n'
            '4. Колени в сторону носков.\n'
            '5. Приседайте до параллели.\n'
            '6. Поднимайтесь контролируемо.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разным хватом).',
        'commonMistakes': '1. Округление спины.\n'
            '2. Наклон вперёд.\n'
            '3. Опускание локтей.\n'
            '4. Неполная амплитуда.\n'
            '5. Колени внутрь.\n'
            '6. Слишком большой вес.\n'
            '7. Отрыв пяток.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях или пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_075',
        'name': 'Гакк-приседания',
        'description': 'Гакк-приседания — приседания в специальном тренажёре. Изолирует квадрицепсы, минимальная нагрузка на спину. Отлично для добивки ног. Масштабируется весом. Гакк-приседания отлично сочетаются с приседаниями и жимом ногами. Это одно из ключевых упражнений для квадрицепсов.',
        'muscleGroups': '["quadriceps","glutes"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте в гакк-тренажёр.\n'
            '2. Спина прижата к спинке.\n'
            '3. Колени по направлению носков.\n'
            '4. Опускайтесь до параллели.\n'
            '5. Не выпрямляйте колени полностью.\n'
            '6. Поднимайтесь контролируемо.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разной постановкой стоп).',
        'commonMistakes': '1. Отрыв пяток.\n'
            '2. Неполная амплитуда.\n'
            '3. Колени внутрь.\n'
            '4. Слишком большой вес.\n'
            '5. Полное выпрямление коленей.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_076',
        'name': 'Разгибания ног в тренажёре',
        'description': 'Разгибания ног в тренажёре — изолирующее упражнение для квадрицепсов. Отличная добивка после приседаний или жима ногами. Масштабируется весом. Хорошо для работы над формой ног. Разгибания ног отлично сочетаются с приседаниями и жимом ногами. Это одно из ключевых упражнений для квадрицепсов.',
        'muscleGroups': '["quadriceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте в тренажёр.\n'
            '2. Валик на голенях.\n'
            '3. Медленно разгибайте ноги.\n'
            '4. Пиковое сокращение в верхней точке.\n'
            '5. Опускайте контролируемо.\n'
            '6. Работайте с умеренным весом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (одной ногой).',
        'commonMistakes': '1. Рывки.\n'
            '2. Слишком большой вес.\n'
            '3. Неполная амплитуда.\n'
            '4. Быстрый темп.\n'
            '5. Отсутствие пикового сокращения.\n'
            '6. Расслабление в нижней точке.\n'
            '7. Слишком быстрый негатив.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_077',
        'name': 'Ягодичный мост',
        'description': 'Ягодичный мост — упражнение для ягодиц и бицепса бедра. Простое и безопасное для дома. Улучшает форму ягодиц. Масштабируется весом и положением ног. Ягодичный мост отлично сочетается с хип-трастом и выпадами. Это одно из ключевых упражнений для ягодиц.',
        'muscleGroups': '["glutes","hamstrings","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на спину, ноги согнуты.\n'
            '2. Опора на пятки.\n'
            '3. Поднимайте таз вверх.\n'
            '4. Сжимайте ягодицы вверху.\n'
            '5. Задерживайтесь на секунду.\n'
            '6. Опускайтесь контролируемо.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с отягощением, одной ногой).',
        'commonMistakes': '1. Прогиб в пояснице.\n'
            '2. Неполная амплитуда.\n'
            '3. Слишком быстрый темп.\n'
            '4. Работа только ногами.\n'
            '5. Отсутствие сжатия ягодиц.\n'
            '6. Слишком большой вес.\n'
            '7. Расслабление в нижней точке.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_078',
        'name': 'Хип-траст со штангой',
        'description': 'Хип-траст со штангой — мощное упражнение для ягодиц. Позволяет работать с большим весом. Отлично для роста ягодиц. Требует хорошей техники и контроля. Хип-траст отлично сочетается с ягодичным мостом и выпадами. Это одно из ключевых упражнений для ягодиц.',
        'muscleGroups': '["glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на скамью, штанга на бёдрах.\n'
            '2. Стопы на ширине плеч.\n'
            '3. Толкайте таз вверх.\n'
            '4. Сжимайте ягодицы в верхней точке.\n'
            '5. Опускайтесь контролируемо.\n'
            '6. Работайте с умеренным весом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с резинкой, с одной ногой).',
        'commonMistakes': '1. Переразгибание в пояснице.\n'
            '2. Слишком большой вес.\n'
            '3. Неполная амплитуда.\n'
            '4. Работа ногами вместо ягодиц.\n'
            '5. Слишком быстрый темп.\n'
            '6. Отсутствие сжатия в верхней точке.\n'
            '7. Неправильная постановка стоп.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_079',
        'name': 'Зашагивания на платформу',
        'description': 'Зашагивания на платформу — функциональное упражнение для ног и ягодиц. Развивает баланс и координацию. Отлично для функциональной подготовки. Масштабируется высотой платформы. Зашагивания отлично сочетаются с выпадами и приседаниями. Это одно из ключевых функциональных упражнений для ног.',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте перед платформой.\n'
            '2. Поставьте ногу на платформу.\n'
            '3. Поднимайтесь за счёт передней ноги.\n'
            '4. Корпус вертикально.\n'
            '5. Не отталкивайтесь задней ногой.\n'
            '6. Спускайтесь контролируемо.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с низкой платформы.\n'
            '12. Разнообразьте варианты (с гантелями, с одной ногой).',
        'commonMistakes': '1. Потеря равновесия.\n'
            '2. Слишком высокий шаг.\n'
            '3. Слишком большой вес.\n'
            '4. Работа только одной ногой.\n'
            '5. Отталкивание задней ногой.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_080',
        'name': 'Подъём на бицепс на скамье Скотта',
        'description': 'Подъём на бицепс на скамье Скотта — изолирующее упражнение для бицепса. Локти фиксированы. Отлично для пикового сокращения. Масштабируется весом. Подъём на скамье Скотта отлично сочетается с молотками и концентрационными сгибаниями. Это одно из ключевых упражнений для бицепса.',
        'muscleGroups': '["biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте на скамью Скотта, локти на подставке.\n'
            '2. Возьмите штангу или гантели.\n'
            '3. Медленно опускайте.\n'
            '4. Пауза на пике сокращения.\n'
            '5. Контролируемое движение.\n'
            '6. Работайте с умеренным весом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (со штангой, с гантелями).',
        'commonMistakes': '1. Рывки.\n'
            '2. Слишком большой вес.\n'
            '3. Неполная амплитуда.\n'
            '4. Работа плечами.\n'
            '5. Слишком быстрый темп.\n'
            '6. Отсутствие паузы.\n'
            '7. Расслабление в нижней точке.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_081',
        'name': 'Подъём гантелей на бицепс с супинацией',
        'description': 'Подъём гантелей на бицепс с супинацией — классическое упражнение с разворотом кисти. Усиливает сокращение бицепса. Отлично для пикового сокращения. Масштабируется весом. Подъём с супинацией отлично сочетается с молотками и подъёмом штанги. Это одно из ключевых упражнений для бицепса.',
        'muscleGroups': '["biceps","forearms"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Стоя или сидя, гантели в опущенных руках.\n'
            '2. Локти прижаты.\n'
            '3. Поднимайте гантели с разворотом кисти.\n'
            '4. Пауза на пике.\n'
            '5. Опускайте контролируемо.\n'
            '6. Корпус стабилен.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (поочерёдно, одновременно).',
        'commonMistakes': '1. Раскачивание.\n'
            '2. Работа плечами.\n'
            '3. Слишком большой вес.\n'
            '4. Неполная амплитуда.\n'
            '5. Слишком быстрый темп.\n'
            '6. Отсутствие супинации.\n'
            '7. Расслабление в нижней точке.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_082',
        'name': 'Разгибание рук с гантелью из-за головы',
        'description': 'Разгибание рук с гантелью из-за головы — французский жим с гантелью. Изолирует трицепс, растягивает длинную головку. Хорошо для формы рук. Масштабируется весом. Разгибание из-за головы отлично сочетается с разгибанием на блоке и французским жимом. Это одно из ключевых упражнений для трицепса.',
        'muscleGroups': '["triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте или встаньте, гантель над головой.\n'
            '2. Локти смотрят вверх.\n'
            '3. Опускайте гантель за голову.\n'
            '4. Контролируемое движение.\n'
            '5. Полная амплитуда.\n'
            '6. Работайте с умеренным весом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (сидя, стоя).',
        'commonMistakes': '1. Разведение локтей.\n'
            '2. Рывки.\n'
            '3. Слишком большой вес.\n'
            '4. Движение плечами.\n'
            '5. Неполная амплитуда.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_083',
        'name': 'Кикбэки с гантелью',
        'description': 'Кикбэки с гантелью — изолирующее упражнение для трицепса. Работает в верхней точке амплитуды. Хорошо для формы рук. Масштабируется весом. Кикбэки отлично сочетаются с разгибанием на блоке и французским жимом. Это одно из ключевых упражнений для трицепса.',
        'muscleGroups': '["triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Наклоните корпус вперёд, гантель в руке.\n'
            '2. Локоть фиксирован.\n'
            '3. Разгибайте руку назад.\n'
            '4. Пауза в верхней точке.\n'
            '5. Контролируемое движение.\n'
            '6. Работайте с умеренным весом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с опорой на скамью).',
        'commonMistakes': '1. Движение плечом.\n'
            '2. Слишком большой вес.\n'
            '3. Неполная амплитуда.\n'
            '4. Рывки.\n'
            '5. Слишком быстрый темп.\n'
            '6. Отсутствие паузы.\n'
            '7. Отсутствие фиксации локтя.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_084',
        'name': 'Обратные отжимания от скамьи',
        'description': 'Обратные отжимания от скамьи — упражнение для трицепса с весом тела. Простое и эффективное для дома. Хорошо для начинающих. Масштабируется положением ног. Обратные отжимания отлично сочетаются с французским жимом и разгибанием на блоке. Это одно из ключевых упражнений для трицепса в домашних условиях.',
        'muscleGroups': '["triceps","chest"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте на край скамьи, руки на скамье.\n'
            '2. Сдвиньте таз вперёд.\n'
            '3. Локти назад.\n'
            '4. Опускайтесь до угла 90°.\n'
            '5. Спина близко к скамье.\n'
            '6. Работайте трицепсом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с согнутых ног.\n'
            '12. Разнообразьте варианты (с отягощением).',
        'commonMistakes': '1. Локти в стороны.\n'
            '2. Слишком низкое опускание.\n'
            '3. Отрыв таза.\n'
            '4. Быстрый темп.\n'
            '5. Нагрузка на плечи вместо трицепса.\n'
            '6. Отсутствие контроля.\n'
            '7. Слишком большой объём.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_085',
        'name': 'Сгибание запястий обратным хватом',
        'description': 'Сгибание запястий обратным хватом — упражнение для разгибателей предплечья. Развивает баланс силы рук. Хорошо для профилактики травм. Масштабируется весом. Сгибание обратным хватом отлично сочетается с обычным сгибанием запястий и молотками. Это одно из ключевых упражнений для предплечий.',
        'muscleGroups': '["forearms"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте, предплечья на коленях.\n'
            '2. Хват сверху.\n'
            '3. Работайте только кистями.\n'
            '4. Полная амплитуда.\n'
            '5. Медленный темп.\n'
            '6. Локти не двигаются.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (со штангой, с гантелями).',
        'commonMistakes': '1. Слишком большой вес.\n'
            '2. Движение локтями.\n'
            '3. Рывки.\n'
            '4. Неполная амплитуда.\n'
            '5. Слишком быстрый темп.\n'
            '6. Отсутствие контроля.\n'
            '7. Расслабление в нижней точке.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в запястьях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_086',
        'name': 'Скручивания на блоке',
        'description': 'Скручивания на блоке — утяжелённые скручивания. Позволяют прогрессировать в весе. Отлично для роста пресса. Масштабируется весом. Скручивания на блоке отлично сочетаются с подъёмом ног и планкой. Это одно из ключевых упражнений для пресса.',
        'muscleGroups': '["abs"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте на колени у блока.\n'
            '2. Возьмите канат.\n'
            '3. Скручивайте корпус.\n'
            '4. Не тяните руками.\n'
            '5. Пауза в верхней точке.\n'
            '6. Опускайтесь контролируемо.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разными рукоятями).',
        'commonMistakes': '1. Работа руками.\n'
            '2. Рывки.\n'
            '3. Слишком большой вес.\n'
            '4. Неполная амплитуда.\n'
            '5. Слишком быстрый темп.\n'
            '6. Отсутствие паузы.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_087',
        'name': 'Велосипед',
        'description': 'Велосипед — скручивания с попеременным движением ног. Прорабатывает прямые и косые мышцы живота. Простое и эффективное. Масштабируется темпом. Велосипед отлично сочетается со скручиваниями и планкой. Это одно из ключевых упражнений для пресса и косых мышц.',
        'muscleGroups': '["abs","obliques"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на спину, руки за головой.\n'
            '2. Поднимите ноги и лопатки.\n'
            '3. Противоположный локоть к колену.\n'
            '4. Поясница прижата.\n'
            '5. Медленный темп.\n'
            '6. Дышите ровно.\n'
            '7. Работайте 20–30 секунд.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте варианты (с паузой, с весом).',
        'commonMistakes': '1. Работа шеей.\n'
            '2. Отрыв поясницы.\n'
            '3. Слишком быстрый темп.\n'
            '4. Неполная амплитуда.\n'
            '5. Расслабленный пресс.\n'
            '6. Задержка дыхания.\n'
            '7. Работа только ногами.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_088',
        'name': 'Подъём ног лёжа',
        'description': 'Подъём ног лёжа — упражнение для нижнего пресса. Простое и эффективное. Подходит для дома. Масштабируется положением рук и темпом. Подъём ног отлично сочетается со скручиваниями и планкой. Это одно из ключевых упражнений для нижнего пресса.',
        'muscleGroups': '["abs"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на спину, руки вдоль тела.\n'
            '2. Поясница прижата.\n'
            '3. Поднимайте ноги до 90°.\n'
            '4. Опускайте контролируемо.\n'
            '5. Дышите ровно.\n'
            '6. Работайте 15–20 повторений.\n'
            '7. Не отрывайте поясницу.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с согнутых ног.\n'
            '12. Разнообразьте варианты (с подъёмом таза).',
        'commonMistakes': '1. Отрыв поясницы.\n'
            '2. Рывки.\n'
            '3. Слишком быстрый темп.\n'
            '4. Согнутые колени.\n'
            '5. Расслабление в нижней точке.\n'
            '6. Задержка дыхания.\n'
            '7. Слишком большой объём без разминки.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_089',
        'name': 'Альпинист',
        'description': 'Альпинист — динамическое упражнение на кор и кардио. Отлично сочетает статику и динамику. Хорошо для HIIT. Масштабируется темпом. Альпинист отлично сочетается с берпи и планкой. Это одно из ключевых функциональных упражнений для кора.',
        'muscleGroups': '["abs","cardio_vascular","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips': '1. Примите упор лёжа.\n'
            '2. Руки под плечами.\n'
            '3. Попеременно подтягивайте колени к груди.\n'
            '4. Ровное дыхание.\n'
            '5. Контролируемый темп.\n'
            '6. Не прогибайте таз.\n'
            '7. Работайте 20–30 секунд.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте варианты (с прыжком).',
        'commonMistakes': '1. Провисание таза.\n'
            '2. Слишком быстрый темп.\n'
            '3. Неполная амплитуда.\n'
            '4. Задержка дыхания.\n'
            '5. Прогиб в пояснице.\n'
            '6. Отсутствие контроля.\n'
            '7. Работа только ногами.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_090',
        'name': 'Ролик для пресса',
        'description': 'Ролик для пресса — мощное упражнение для всего кора. Требует силы и контроля. Отлично для продвинутых. Масштабируется амплитудой. Ролик отлично сочетается с планкой и скручиваниями. Это одно из ключевых упражнений для кора.',
        'muscleGroups': '["abs","obliques","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте на колени, ролик перед собой.\n'
            '2. Не прогибайте поясницу.\n'
            '3. Катитесь на выдохе.\n'
            '4. Контролируемое движение.\n'
            '5. Работайте в доступной амплитуде.\n'
            '6. Возвращайтесь медленно.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с короткого выката.\n'
            '12. Разнообразьте варианты (с опорой на стену).',
        'commonMistakes': '1. Прогиб в пояснице.\n'
            '2. Слишком большой выкат.\n'
            '3. Рывки.\n'
            '4. Работа руками.\n'
            '5. Слишком быстрый темп.\n'
            '6. Отсутствие контроля.\n'
            '7. Слишком большой объём без разминки.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_091',
        'name': 'Гребля на тренажёре',
        'description': 'Гребля на тренажёре — кардио на всё тело. Минимальная нагрузка на суставы. Отличная тренировка спины. Хорошо для кардио и функционала. Масштабируется темпом. Гребля отлично сочетается с силовыми тренировками и плаванием. Это одно из самых эффективных кардио-упражнений.',
        'muscleGroups': '["cardio_vascular","back","quadriceps"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте в тренажёр.\n'
            '2. Толчок ногами, затем корпус, затем руки.\n'
            '3. Ровный темп.\n'
            '4. Дыхание ровное.\n'
            '5. Полная амплитуда.\n'
            '6. Не округляйте спину.\n'
            '7. Завершайте заминкой.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте интервалы.',
        'commonMistakes': '1. Работа только руками.\n'
            '2. Округление спины.\n'
            '3. Слишком быстрый темп.\n'
            '4. Неполная амплитуда.\n'
            '5. Отсутствие разминки.\n'
            '6. Слишком длинная сессия.\n'
            '7. Обезвоживание.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_092',
        'name': 'Эллиптический тренажёр',
        'description': 'Эллиптический тренажёр — кардио с низкой ударной нагрузкой. Безопасно для коленей и суставов. Хорошо для кардио. Масштабируется сопротивлением. Эллиптический тренажёр отлично сочетается с силовыми тренировками и йогой. Это одно из самых безопасных кардио-упражнений.',
        'muscleGroups': '["cardio_vascular","quadriceps","glutes"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте на тренажёр.\n'
            '2. Держите корпус прямо.\n'
            '3. Работайте руками и ногами.\n'
            '4. Ровный темп.\n'
            '5. Следите за дыханием.\n'
            '6. Не наклоняйтесь вперёд.\n'
            '7. Завершайте заминкой.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте интервалы.',
        'commonMistakes': '1. Наклон корпуса вперёд.\n'
            '2. Слишком большое сопротивление.\n'
            '3. Опора на поручни.\n'
            '4. Слишком быстрый темп.\n'
            '5. Отсутствие разминки.\n'
            '6. Обезвоживание.\n'
            '7. Слишком длинная сессия.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_093',
        'name': 'Ходьба в гору',
        'description': 'Ходьба в гору — кардио с наклоном дорожки. Отлично сжигает жир и укрепляет ягодицы. Безопасно для коленей. Масштабируется наклоном и темпом. Ходьба в гору отлично сочетается с силовыми тренировками. Это одно из самых эффективных кардио-упражнений для сжигания жира.',
        'muscleGroups': '["cardio_vascular","glutes","calves"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips': '1. Установите наклон 8–12%.\n'
            '2. Ровный темп.\n'
            '3. Не держитесь за поручни.\n'
            '4. Следите за пульсом.\n'
            '5. Дыхание ровное.\n'
            '6. Пейте воду.\n'
            '7. Завершайте заминкой.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте наклоном.',
        'commonMistakes': '1. Слишком быстрый темп.\n'
            '2. Опора на поручни.\n'
            '3. Слишком маленький наклон.\n'
            '4. Игнорирование разминки.\n'
            '5. Обезвоживание.\n'
            '6. Слишком длинная сессия.\n'
            '7. Неправильная обувь.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_094',
        'name': 'Бой с тенью с гантелями',
        'description': 'Бой с тенью с гантелями — бокс с утяжелением. Развивает плечи и выносливость. Хорошо для функционала. Масштабируется весом гантелей. Бой с тенью с гантелями отлично сочетается с работой на груше. Это одно из ключевых упражнений для функциональной подготовки.',
        'muscleGroups': '["shoulders","cardio_vascular","fullBody"]',
        'imageUrl': '',
        'exerciseType': 'boxing',
        'isCustom': 0,
        'techniqueTips': '1. Небольшой вес гантелей.\n'
            '2. Работайте техникой.\n'
            '3. Ровное дыхание.\n'
            '4. Контролируемый темп.\n'
            '5. Двигайтесь на носках.\n'
            '6. Держите руки у подбородка.\n'
            '7. Завершайте растяжкой.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте комбинации.',
        'commonMistakes': '1. Слишком большой вес.\n'
            '2. Потеря техники.\n'
            '3. Опускание рук.\n'
            '4. Задержка дыхания.\n'
            '5. Статичность.\n'
            '6. Отсутствие работы ног.\n'
            '7. Слишком быстрый темп.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_095',
        'name': 'Прыжки через скакалку двойные',
        'description': 'Двойные прыжки через скакалку — продвинутая техника для кардио и координации. Требует хорошей подготовки. Отлично для HIIT. Масштабируется темпом. Двойные прыжки отлично сочетаются с обычными прыжками на скакалке. Это одно из самых эффективных кардио-упражнений.',
        'muscleGroups': '["cardio_vascular","calves","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips': '1. Прыгайте выше, чем обычно.\n'
            '2. Вращение кистями дважды.\n'
            '3. Мягкое приземление.\n'
            '4. Ровное дыхание.\n'
            '5. Контролируемый темп.\n'
            '6. Начинайте с малого количества.\n'
            '7. Завершайте заминкой.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте интервалы.',
        'commonMistakes': '1. Сильное приземление.\n'
            '2. Слишком быстрый темп.\n'
            '3. Вращение плечами.\n'
            '4. Недостаточная высота прыжка.\n'
            '5. Отсутствие разминки.\n'
            '6. Слишком длинная сессия.\n'
            '7. Неправильная обувь.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в ахилле.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_096',
        'name': 'Поза ребёнка',
        'description': 'Поза ребёнка — расслабляющая асана йоги. Растягивает спину и бёдра, успокаивает нервную систему. Отлично для завершения тренировки. Подходит для всех. Поза ребёнка отлично сочетается с другими асанами йоги. Это одна из ключевых асан для восстановления.',
        'muscleGroups': '["flexibility","back","glutes"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте на пятки.\n'
            '2. Наклонитесь вперёд.\n'
            '3. Руки вытянуты.\n'
            '4. Лоб на полу.\n'
            '5. Дышите глубоко.\n'
            '6. Держите 30–60 секунд.\n'
            '7. Расслабьте шею.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного входа.\n'
            '12. Разнообразьте варианты (с подушкой).',
        'commonMistakes': '1. Напряжение в шее.\n'
            '2. Неполное расслабление.\n'
            '3. Задержка дыхания.\n'
            '4. Спешка.\n'
            '5. Слишком сильное давление на колени.\n'
            '6. Слишком быстрый вход в позу.\n'
            '7. Отсутствие концентрации.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_097',
        'name': 'Поза воина',
        'description': 'Поза воина — классическая асана йоги. Укрепляет ноги и раскрывает грудную клетку. Отлично для баланса и силы. Подходит для всех уровней. Поза воина отлично сочетается с другими асанами йоги. Это одна из ключевых асан для силы и баланса.',
        'muscleGroups': '["flexibility","quadriceps","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Шагните вперёд одной ногой.\n'
            '2. Переднее колено над стопой.\n'
            '3. Руки вытянуты вверх.\n'
            '4. Дышите ровно.\n'
            '5. Следите за равновесием.\n'
            '6. Держите 20–30 секунд.\n'
            '7. Повторите на другую сторону.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного входа.\n'
            '12. Разнообразьте варианты (с опорой).',
        'commonMistakes': '1. Колено выходит за носок.\n'
            '2. Потеря равновесия.\n'
            '3. Задержка дыхания.\n'
            '4. Слишком сильное напряжение.\n'
            '5. Слишком короткая стойка.\n'
            '6. Отсутствие концентрации.\n'
            '7. Слишком быстрый вход.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_098',
        'name': 'Растяжка грудных у стены',
        'description': 'Растяжка грудных у стены — упражнение для растяжения груди и плеч. Хорошо после жимовых тренировок. Помогает снять напряжение. Подходит для всех. Растяжка у стены отлично сочетается с другими упражнениями на гибкость. Это одно из ключевых упражнений для растяжения груди.',
        'muscleGroups': '["flexibility","chest","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте боком к стене.\n'
            '2. Рука на стене.\n'
            '3. Поворачивайте корпус.\n'
            '4. Дышите ровно.\n'
            '5. Задерживайтесь 20–30 секунд.\n'
            '6. Не пружиньте.\n'
            '7. Повторите на другую сторону.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного входа.\n'
            '12. Разнообразьте варианты (с разной высотой руки).',
        'commonMistakes': '1. Резкие движения.\n'
            '2. Слишком сильное растяжение.\n'
            '3. Задержка дыхания.\n'
            '4. Спешка.\n'
            '5. Слишком быстрый вход в позу.\n'
            '6. Отсутствие расслабления.\n'
            '7. Слишком короткое удержание.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_099',
        'name': 'Фермерская прогулка',
        'description': 'Фермерская прогулка — переноска тяжёлых гантелей. Развивает хват, трапеции, кор и выносливость. Функциональное упражнение. Масштабируется весом. Фермерская прогулка отлично сочетается с силовыми тренировками. Это одно из ключевых функциональных упражнений.',
        'muscleGroups': '["fullBody","forearms","traps","abs"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите тяжёлые гантели.\n'
            '2. Спина прямая.\n'
            '3. Идите ровным шагом.\n'
            '4. Руки прямые.\n'
            '5. Дышите ровно.\n'
            '6. Не наклоняйтесь.\n'
            '7. Работайте 20–40 метров.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с одной гантелью).',
        'commonMistakes': '1. Наклон корпуса.\n'
            '2. Согнутые руки.\n'
            '3. Слишком большой вес.\n'
            '4. Спешка.\n'
            '5. Отсутствие контроля.\n'
            '6. Неправильная обувь.\n'
            '7. Слишком длинная дистанция.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_100',
        'name': 'Бёрпи с отжиманием',
        'description': 'Бёрпи с отжиманием — усложнённая версия бёрпи. Всё тело + кардио + сила. Отлично для HIIT. Требует подготовки. Масштабируется темпом. Бёрпи с отжиманием отлично сочетается с другими HIIT-упражнениями. Это одно из самых эффективных функциональных упражнений.',
        'muscleGroups': '["fullBody","chest","cardio_vascular","quadriceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Из стойки присядьте.\n'
            '2. Прыжком в упор лёжа.\n'
            '3. Отжимание.\n'
            '4. Прыжком обратно в присед.\n'
            '5. Выпрыгните вверх.\n'
            '6. Плавные движения.\n'
            '7. Ровное дыхание.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте варианты (без прыжка).',
        'commonMistakes': '1. Рывки.\n'
            '2. Прогиб в пояснице.\n'
            '3. Неполная амплитуда.\n'
            '4. Слишком быстрый темп.\n'
            '5. Неправильная техника приземления.\n'
            '6. Отсутствие разминки.\n'
            '7. Слишком большой объём.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ============================================================
      // v13: 101–130
      // ============================================================
      {
        'id': 'ex_default_101',
        'name': 'Жим узким хватом',
        'description': 'Жим узким хватом — вариант жима лёжа с акцентом на трицепс и внутреннюю часть груди. Отлично для силы трицепса. Масштабируется весом. Требует контроля локтей. Жим узким хватом отлично сочетается с французским жимом и разгибанием на блоке. Это одно из ключевых упражнений для трицепса.',
        'muscleGroups': '["chest","triceps","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на скамью.\n'
            '2. Хват на ширине плеч.\n'
            '3. Локти близко к корпусу.\n'
            '4. Опускайте к низу груди.\n'
            '5. Выжимайте контролируемо.\n'
            '6. Лопатки сведены.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с паузой).',
        'commonMistakes': '1. Слишком узкий хват.\n'
            '2. Отрыв таза.\n'
            '3. Слишком большой вес.\n'
            '4. Разведение локтей.\n'
            '5. Неполная амплитуда.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_102',
        'name': 'Разведение в наклонном кроссовере',
        'description': 'Разведение в наклонном кроссовере — разведение рук в кроссовере под углом. Акцент на нижнюю часть груди. Постоянное натяжение блока. Масштабируется весом. Разведение в наклонном кроссовере отлично сочетается со сведением рук в кроссовере и разводкой. Это одно из ключевых упражнений для нижней части груди.',
        'muscleGroups': '["chest"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Установите блоки снизу.\n'
            '2. Возьмите рукоятки.\n'
            '3. Тяните блоки снизу вверх.\n'
            '4. Сводите кисти перед грудью.\n'
            '5. Локти чуть согнуты.\n'
            '6. Контролируемый темп.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разной высотой блоков).',
        'commonMistakes': '1. Работа плечами.\n'
            '2. Слишком большой вес.\n'
            '3. Неполная амплитуда.\n'
            '4. Рывки.\n'
            '5. Слишком быстрый темп.\n'
            '6. Отсутствие контроля.\n'
            '7. Раскачивание корпусом.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_103',
        'name': 'Отжимания алмазные',
        'description': 'Отжимания алмазные — отжимания с узкой постановкой рук. Акцент на трицепс. Простое и эффективное. Масштабируется положением ног. Отжимания алмазные отлично сочетаются с французским жимом и разгибанием на блоке. Это одно из ключевых упражнений для трицепса в домашних условиях.',
        'muscleGroups': '["chest","triceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Примите упор лёжа.\n'
            '2. Ладони образуют ромб.\n'
            '3. Локти к корпусу.\n'
            '4. Полная амплитуда.\n'
            '5. Корпус стабилен.\n'
            '6. Дышите ровно.\n'
            '7. Контролируемый темп.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с колен.\n'
            '12. Разнообразьте варианты (с ногами на скамье).',
        'commonMistakes': '1. Локти в стороны.\n'
            '2. Прогиб в пояснице.\n'
            '3. Неполная амплитуда.\n'
            '4. Слишком быстрый темп.\n'
            '5. Отсутствие контроля.\n'
            '6. Работа шеей.\n'
            '7. Слишком большой объём.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_104',
        'name': 'Тяга штанги одной рукой в наклоне',
        'description': 'Тяга штанги одной рукой в наклоне — односторонняя тяга. Проработка широчайших и устранение асимметрии. Требует стабильной опоры. Масштабируется весом. Тяга одной рукой отлично сочетается с тягой гантели к поясу и подтягиваниями. Это одно из ключевых упражнений для устранения дисбаланса.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Опора на скамью.\n'
            '2. Спина прямая.\n'
            '3. Тяните гриф к поясу.\n'
            '4. Сводите лопатки.\n'
            '5. Контролируемое опускание.\n'
            '6. Корпус стабилен.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с гантелью).',
        'commonMistakes': '1. Скручивание корпуса.\n'
            '2. Рывки.\n'
            '3. Округление спины.\n'
            '4. Слишком большой вес.\n'
            '5. Отсутствие сведения лопаток.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_105',
        'name': 'Австралийские подтягивания',
        'description': 'Австралийские подтягивания — горизонтальные подтягивания. Отличное упражнение для начинающих. Масштабируется высотой перекладины. Хорошо для спины. Австралийские подтягивания отлично сочетаются с подтягиваниями и тягой. Это одно из ключевых упражнений для начинающих.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Возьмитесь за перекладину.\n'
            '2. Тело прямое.\n'
            '3. Тянитесь грудью к перекладине.\n'
            '4. Сводите лопатки.\n'
            '5. Контролируемое движение.\n'
            '6. Корпус стабилен.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с высокой перекладины.\n'
            '12. Разнообразьте варианты (с отягощением).',
        'commonMistakes': '1. Провисание таза.\n'
            '2. Неполная амплитуда.\n'
            '3. Рывки.\n'
            '4. Слишком высокий хват.\n'
            '5. Отсутствие сведения лопаток.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_106',
        'name': 'Тяга Пендлей',
        'description': 'Тяга Пендлей — взрывная тяга в наклоне. Развивает толщину спины и силу. Требует хорошей техники. Масштабируется весом. Тяга Пендлей отлично сочетается с тягой штанги в наклоне и подтягиваниями. Это одно из ключевых упражнений для толщины спины.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу хватом чуть шире плеч.\n'
            '2. Наклоните корпус под 45°.\n'
            '3. Спина прямая.\n'
            '4. Тяните штангу взрывным движением.\n'
            '5. Сводите лопатки.\n'
            '6. Опускайте контролируемо.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с паузой).',
        'commonMistakes': '1. Округление спины.\n'
            '2. Слишком большой вес.\n'
            '3. Рывки.\n'
            '4. Неполная амплитуда.\n'
            '5. Отсутствие сведения лопаток.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_107',
        'name': 'Подтягивания широким хватом',
        'description': 'Подтягивания широким хватом — вариант подтягиваний с акцентом на верх широчайших. Требует силы. Масштабируется резинкой. Хорошо для ширины спины. Подтягивания широким хватом отлично сочетаются с подтягиваниями обратным хватом и тягой. Это одно из ключевых упражнений для ширины спины.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Возьмитесь за перекладину широким хватом.\n'
            '2. Тянитесь грудью к перекладине.\n'
            '3. Сводите лопатки.\n'
            '4. Опускайтесь контролируемо.\n'
            '5. Корпус стабилен.\n'
            '6. Дышите ровно.\n'
            '7. Без раскачивания.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с резинки.\n'
            '12. Разнообразьте варианты (с отягощением).',
        'commonMistakes': '1. Неполная амплитуда.\n'
            '2. Рывки.\n'
            '3. Раскачивание.\n'
            '4. Расслабленные плечи.\n'
            '5. Отсутствие разминки.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_108',
        'name': 'Тяга каната к лицу',
        'description': 'Тяга каната к лицу — упражнение для задних дельт, трапеций и ротаторов плеча. Улучшает осанку и здоровье плеч. Хорошо для баланса. Масштабируется весом. Тяга каната к лицу отлично сочетается с обратными разведениями в кроссовере и махами в наклоне. Это одно из ключевых упражнений для задних дельт и осанки.',
        'muscleGroups': '["shoulders","back","traps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Установите блок на уровне лица.\n'
            '2. Тяните канат к лицу.\n'
            '3. Локти в стороны.\n'
            '4. Сводите лопатки.\n'
            '5. Контролируемый темп.\n'
            '6. Корпус стабилен.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разной высотой блока).',
        'commonMistakes': '1. Работа только руками.\n'
            '2. Слишком большой вес.\n'
            '3. Рывки.\n'
            '4. Неполная амплитуда.\n'
            '5. Отсутствие сведения лопаток.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_109',
        'name': 'Махи в кроссовере на средние дельты',
        'description': 'Махи в кроссовере на средние дельты — изолирующее упражнение с постоянным натяжением. Хорошо для ширины плеч. Масштабируется весом. Махи в кроссовере отлично сочетаются с махами в стороны и жимами. Это одно из ключевых упражнений для средних дельт.',
        'muscleGroups': '["shoulders"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте боком к блоку.\n'
            '2. Тяните трос в сторону.\n'
            '3. Локоть чуть выше кисти.\n'
            '4. Корпус стабилен.\n'
            '5. Контролируемый темп.\n'
            '6. Не поднимайте выше плеч.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разной высотой блока).',
        'commonMistakes': '1. Раскачивание.\n'
            '2. Слишком большой вес.\n'
            '3. Рывки.\n'
            '4. Подъём выше плеч.\n'
            '5. Отсутствие контроля.\n'
            '6. Слишком быстрый темп.\n'
            '7. Работа корпусом.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_110',
        'name': 'Разведение в тренажёре задние дельты',
        'description': 'Разведение в тренажёре задние дельты — изолирующее упражнение для задних дельт. Отличная осанка. Безопасная траектория. Масштабируется весом. Разведение в тренажёре отлично сочетается с тягой каната к лицу и обратными разведениями. Это одно из ключевых упражнений для задних дельт.',
        'muscleGroups': '["shoulders","back"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте в тренажёр лицом к спинке.\n'
            '2. Возьмите рукоятки.\n'
            '3. Разводите руки в стороны.\n'
            '4. Сводите лопатки.\n'
            '5. Контролируемый темп.\n'
            '6. Локти чуть согнуты.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разным хватом).',
        'commonMistakes': '1. Работа спиной.\n'
            '2. Слишком большой вес.\n'
            '3. Рывки.\n'
            '4. Подъём выше плеч.\n'
            '5. Отсутствие контроля.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие сведения лопаток.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_111',
        'name': 'Разгибания ног одной ногой',
        'description': 'Разгибания ног одной ногой — одностороннее разгибание ног. Для устранения асимметрии. Хорошо для изоляции квадрицепса. Масштабируется весом. Разгибания одной ногой отлично сочетаются с приседаниями и жимом ногами. Это одно из ключевых упражнений для устранения дисбаланса ног.',
        'muscleGroups': '["quadriceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте в тренажёр.\n'
            '2. Валик на голени.\n'
            '3. Медленно разгибайте.\n'
            '4. Задерживайтесь в верхней точке.\n'
            '5. Опускайте контролируемо.\n'
            '6. Работайте с умеренным весом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с паузой).',
        'commonMistakes': '1. Рывки.\n'
            '2. Слишком большой вес.\n'
            '3. Неполная амплитуда.\n'
            '4. Быстрый темп.\n'
            '5. Отсутствие пикового сокращения.\n'
            '6. Расслабление в нижней точке.\n'
            '7. Слишком быстрый негатив.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_112',
        'name': 'Сгибания ног лёжа',
        'description': 'Сгибания ног лёжа — сгибания ног на животе. Изолирует бицепс бедра. Хорошо для задней поверхности бедра. Масштабируется весом. Сгибания ног лёжа отлично сочетаются с румынской тягой и сгибаниями сидя. Это одно из ключевых упражнений для бицепса бедра.',
        'muscleGroups': '["hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на тренажёр на живот.\n'
            '2. Валик на голенях.\n'
            '3. Сгибайте ноги.\n'
            '4. Пиковое сокращение.\n'
            '5. Медленное опускание.\n'
            '6. Не отрывайте таз.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (одной ногой).',
        'commonMistakes': '1. Рывки.\n'
            '2. Слишком большой вес.\n'
            '3. Отрыв таза.\n'
            '4. Быстрый темп.\n'
            '5. Неполная амплитуда.\n'
            '6. Отсутствие пикового сокращения.\n'
            '7. Расслабление в нижней точке.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_113',
        'name': 'Приседания сумо',
        'description': 'Приседания сумо — приседания с широкой постановкой ног. Акцент на внутреннюю поверхность бедра. Хорошо для ног. Масштабируется весом. Приседания сумо отлично сочетаются с приседаниями со штангой и выпадами. Это одно из ключевых упражнений для внутренней поверхности бедра.',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Стопы широко, носки развёрнуты.\n'
            '2. Спина прямая.\n'
            '3. Опускайтесь до параллели.\n'
            '4. Колени в сторону носков.\n'
            '5. Поднимайтесь контролируемо.\n'
            '6. Работайте с умеренным весом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с гантелью, со штангой).',
        'commonMistakes': '1. Колени внутрь.\n'
            '2. Слишком большой вес.\n'
            '3. Округление спины.\n'
            '4. Неполная амплитуда.\n'
            '5. Отрыв пяток.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_114',
        'name': 'Отведение ноги в кроссовере',
        'description': 'Отведение ноги в кроссовере — изолирует ягодичные мышцы. Развивает форму ягодиц. Хорошо для акцента на ягодицы. Масштабируется весом. Отведение ноги отлично сочетается с ягодичным мостом и выпадами. Это одно из ключевых упражнений для ягодиц.',
        'muscleGroups': '["glutes"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте у блока.\n'
            '2. Прикрепите манжету к ноге.\n'
            '3. Отводите ногу назад-в сторону.\n'
            '4. Сжимайте ягодицу.\n'
            '5. Корпус стабилен.\n'
            '6. Контролируемый темп.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разной высотой блока).',
        'commonMistakes': '1. Работа поясницей.\n'
            '2. Слишком большой вес.\n'
            '3. Рывки.\n'
            '4. Раскачивание.\n'
            '5. Отсутствие контроля.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие сжатия ягодицы.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_115',
        'name': 'Становая на прямых ногах с гантелями',
        'description': 'Становая на прямых ногах с гантелями — румынская тяга с гантелями. Для бицепса бедра и ягодиц. Хорошо для задней цепи. Масштабируется весом. Становая с гантелями отлично сочетается со становой тягой и сгибаниями ног. Это одно из ключевых упражнений для задней цепи.',
        'muscleGroups': '["hamstrings","glutes","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите гантели.\n'
            '2. Ноги почти прямые.\n'
            '3. Наклон до растяжки в бицепсе бедра.\n'
            '4. Спина прямая.\n'
            '5. Поднимайтесь за счёт ягодиц.\n'
            '6. Сжимайте ягодицы в верхней точке.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (со штангой).',
        'commonMistakes': '1. Округление спины.\n'
            '2. Сгибание ног.\n'
            '3. Слишком большой вес.\n'
            '4. Рывки.\n'
            '5. Отсутствие сжатия ягодиц.\n'
            '6. Слишком быстрый темп.\n'
            '7. Переразгибание в верхней точке.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_116',
        'name': 'Подъёмы на носки в тренажёре',
        'description': 'Подъёмы на носки в тренажёре — изолирует икроножные мышцы. Максимальная амплитуда. Хорошо для икр. Масштабируется весом. Подъёмы в тренажёре отлично сочетаются с подъёмами стоя и сидя. Это одно из ключевых упражнений для икр.',
        'muscleGroups': '["calves"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте в тренажёр.\n'
            '2. Полная амплитуда.\n'
            '3. Задерживайтесь на пике.\n'
            '4. Медленное опускание.\n'
            '5. Корпус стабилен.\n'
            '6. Работайте с умеренным весом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с паузой).',
        'commonMistakes': '1. Быстрые движения.\n'
            '2. Неполная амплитуда.\n'
            '3. Слишком большой вес.\n'
            '4. Сгибание коленей.\n'
            '5. Отсутствие паузы на пике.\n'
            '6. Слишком быстрый негатив.\n'
            '7. Расслабление в нижней точке.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в ахилле.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_117',
        'name': 'Подъём штанги на бицепс стоя у стены',
        'description': 'Подъём штанги на бицепс стоя у стены — жёсткая вариация. Не даёт читинговать. Отлично для изоляции бицепса. Масштабируется весом. Подъём у стены отлично сочетается с молотками и концентрационными сгибаниями. Это одно из ключевых упражнений для бицепса.',
        'muscleGroups': '["biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте спиной к стене.\n'
            '2. Спина и локти прижаты к стене.\n'
            '3. Поднимайте штангу до уровня груди.\n'
            '4. Пауза на пике.\n'
            '5. Медленное опускание.\n'
            '6. Работайте с умеренным весом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с гантелями).',
        'commonMistakes': '1. Отрыв спины от стены.\n'
            '2. Слишком большой вес.\n'
            '3. Рывки.\n'
            '4. Неполная амплитуда.\n'
            '5. Отсутствие паузы на пике.\n'
            '6. Слишком быстрый темп.\n'
            '7. Расслабление в нижней точке.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_118',
        'name': 'Жим лёжа узким хватом (трицепс)',
        'description': 'Жим лёжа узким хватом с акцентом на трицепс. Отлично для силы трицепса. Хорошо для жима. Масштабируется весом. Жим узким хватом отлично сочетается с французским жимом и разгибанием на блоке. Это одно из ключевых упражнений для трицепса.',
        'muscleGroups': '["triceps","chest"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на скамью.\n'
            '2. Хват на ширине плеч.\n'
            '3. Локти к корпусу.\n'
            '4. Опускайте к низу груди.\n'
            '5. Выжимайте контролируемо.\n'
            '6. Лопатки сведены.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с паузой).',
        'commonMistakes': '1. Слишком узкий хват.\n'
            '2. Слишком большой вес.\n'
            '3. Отрыв таза.\n'
            '4. Разведение локтей.\n'
            '5. Неполная амплитуда.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_119',
        'name': 'Разгибание одной рукой на блоке',
        'description': 'Разгибание одной рукой на блоке — одностороннее разгибание для трицепса. Изолирует трицепс. Хорошо для формы рук. Масштабируется весом. Разгибание одной рукой отлично сочетается с французским жимом и разгибанием двумя руками. Это одно из ключевых упражнений для трицепса.',
        'muscleGroups': '["triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте у блока.\n'
            '2. Возьмите рукоять одной рукой.\n'
            '3. Локоть фиксирован.\n'
            '4. Полное разгибание.\n'
            '5. Пауза в нижней точке.\n'
            '6. Контролируемый возврат.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с разными рукоятями).',
        'commonMistakes': '1. Движение плечом.\n'
            '2. Рывки.\n'
            '3. Неполная амплитуда.\n'
            '4. Слишком большой вес.\n'
            '5. Отсутствие фиксации локтя.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_120',
        'name': 'Сгибание одной рукой с упором',
        'description': 'Сгибание одной рукой с упором — концентрированное сгибание. Пиковое сокращение. Хорошо для изоляции бицепса. Масштабируется весом. Сгибание с упором отлично сочетается с молотками и подъёмом штанги. Это одно из ключевых упражнений для бицепса.',
        'muscleGroups': '["biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте на скамью.\n'
            '2. Локоть на бедре.\n'
            '3. Локоть фиксирован.\n'
            '4. Пауза на пике.\n'
            '5. Медленное опускание.\n'
            '6. Не помогайте корпусом.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (с гантелью, со штангой).',
        'commonMistakes': '1. Раскачивание.\n'
            '2. Слишком большой вес.\n'
            '3. Работа плечом.\n'
            '4. Быстрый темп.\n'
            '5. Неполная амплитуда.\n'
            '6. Отсутствие паузы.\n'
            '7. Смещение локтя.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_121',
        'name': 'Сгибание "паук"',
        'description': 'Сгибание "паук" — сгибание на скамье лицом вниз. Изолирует бицепс. Хорошо для пикового сокращения. Масштабируется весом. Сгибание "паук" отлично сочетается с молотками и концентрационными сгибаниями. Это одно из ключевых упражнений для бицепса.',
        'muscleGroups': '["biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на скамью грудью вниз.\n'
            '2. Возьмите гантели.\n'
            '3. Локти вниз.\n'
            '4. Пауза на пике.\n'
            '5. Медленное опускание.\n'
            '6. Не помогайте плечами.\n'
            '7. Дышите ровно.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с лёгкого веса.\n'
            '12. Разнообразьте варианты (со штангой).',
        'commonMistakes': '1. Работа плечами.\n'
            '2. Рывки.\n'
            '3. Слишком большой вес.\n'
            '4. Неполная амплитуда.\n'
            '5. Отсутствие паузы.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в локтях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_122',
        'name': 'Подъём ног в упоре на брусьях',
        'description': 'Подъём ног в упоре на брусьях — упражнение для нижнего пресса. Требует силы. Хорошо для кора. Масштабируется согнутыми ногами. Подъём ног на брусьях отлично сочетается с подъёмом ног в висе и скручиваниями. Это одно из ключевых упражнений для нижнего пресса.',
        'muscleGroups': '["abs","obliques"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Примите упор на брусьях.\n'
            '2. Не раскачивайтесь.\n'
            '3. Поднимайте ноги до параллели.\n'
            '4. Контролируемое опускание.\n'
            '5. Корпус стабилен.\n'
            '6. Дышите ровно.\n'
            '7. Работайте за счёт пресса.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с согнутых ног.\n'
            '12. Разнообразьте варианты (с отягощением).',
        'commonMistakes': '1. Раскачивание.\n'
            '2. Работа сгибателями бедра.\n'
            '3. Неполная амплитуда.\n'
            '4. Расслабленный кор.\n'
            '5. Отсутствие контроля.\n'
            '6. Слишком быстрый темп.\n'
            '7. Отсутствие разминки.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в плечах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_123',
        'name': 'Скручивания с подъёмом ног',
        'description': 'Скручивания с подъёмом ног — комбинированное упражнение. Работает весь пресс. Простое и эффективное. Масштабируется темпом. Скручивания с подъёмом ног отлично сочетаются со скручиваниями и подъёмом ног. Это одно из ключевых упражнений для пресса.',
        'muscleGroups': '["abs","obliques"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на спину.\n'
            '2. Одновременно скручивайте корпус и поднимайте ноги.\n'
            '3. Поясница прижата.\n'
            '4. Медленный темп.\n'
            '5. Дышите ровно.\n'
            '6. Работайте 15–20 повторений.\n'
            '7. Не рывками.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте варианты (с весом).',
        'commonMistakes': '1. Отрыв поясницы.\n'
            '2. Рывки.\n'
            '3. Слишком быстрый темп.\n'
            '4. Расслабленный пресс.\n'
            '5. Задержка дыхания.\n'
            '6. Неполная амплитуда.\n'
            '7. Отсутствие контроля.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_124',
        'name': 'Мёртвый жук',
        'description': 'Мёртвый жук — упражнение на стабильность кора. Безопасно для спины. Отлично для начинающих. Масштабируется темпом. Мёртвый жук отлично сочетается с планкой и скручиваниями. Это одно из ключевых упражнений для стабильности кора.',
        'muscleGroups': '["abs","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на спину, руки вверх.\n'
            '2. Поясница прижата.\n'
            '3. Противоположные рука и нога опускаются.\n'
            '4. Медленный темп.\n'
            '5. Дышите ровно.\n'
            '6. Работайте 10–15 повторений.\n'
            '7. Контролируйте движение.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте варианты (с весом).',
        'commonMistakes': '1. Отрыв поясницы.\n'
            '2. Слишком быстрый темп.\n'
            '3. Неполная амплитуда.\n'
            '4. Расслабленный пресс.\n'
            '5. Задержка дыхания.\n'
            '6. Отсутствие контроля.\n'
            '7. Неправильная координация.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_125',
        'name': 'Скакалка с высокими коленями',
        'description': 'Скакалка с высокими коленями — интенсивное кардио. Прокачивает ноги и координацию. Отлично для HIIT. Масштабируется темпом. Скакалка с высокими коленями отлично сочетается с обычными прыжками на скакалке. Это одно из самых эффективных кардио-упражнений.',
        'muscleGroups': '["cardio_vascular","quadriceps","calves"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите скакалку.\n'
            '2. Высокие колени.\n'
            '3. Мягкое приземление.\n'
            '4. Ровное дыхание.\n'
            '5. Контролируемый темп.\n'
            '6. Начните с 30 секунд.\n'
            '7. Завершайте заминкой.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте интервалы.',
        'commonMistakes': '1. Сильное приземление.\n'
            '2. Слишком быстрый темп.\n'
            '3. Вращение плечами.\n'
            '4. Неполная амплитуда.\n'
            '5. Отсутствие разминки.\n'
            '6. Слишком длинная сессия.\n'
            '7. Неправильная обувь.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в ахилле.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_126',
        'name': 'Спринт-интервалы',
        'description': 'Спринт-интервалы — высокоинтенсивный интервальный спринт. Максимальный жиросжигающий эффект. Отлично для кардио. Требует подготовки. Масштабируется длиной интервалов. Спринт-интервалы отлично сочетаются с силовыми тренировками. Это одно из самых эффективных кардио-упражнений для сжигания жира.',
        'muscleGroups': '["cardio_vascular","quadriceps","glutes"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips': '1. 30 секунд спринт.\n'
            '2. 90 секунд ходьба.\n'
            '3. Повторите 6–8 раз.\n'
            '4. Ровное дыхание.\n'
            '5. Правильная техника бега.\n'
            '6. Следите за пульсом.\n'
            '7. Завершайте заминкой.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте интервалы.',
        'commonMistakes': '1. Слишком длинные интервалы.\n'
            '2. Недостаток восстановления.\n'
            '3. Слишком быстрый старт.\n'
            '4. Игнорирование разминки.\n'
            '5. Обезвоживание.\n'
            '6. Слишком много интервалов.\n'
            '7. Неправильная обувь.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_127',
        'name': 'Джампинг Джек',
        'description': 'Джампинг Джек — классическое кардио с прыжками. Разминка, HIIT. Простое и эффективное. Масштабируется темпом. Джампинг Джек отлично сочетается с другими кардио-упражнениями. Это одно из самых популярных кардио-упражнений.',
        'muscleGroups': '["cardio_vascular","fullBody","calves"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips': '1. Прыжки с разведением ног и рук.\n'
            '2. Мягкое приземление.\n'
            '3. Ровное дыхание.\n'
            '4. Контролируемый темп.\n'
            '5. Начните с 30 секунд.\n'
            '6. Работайте 20–30 повторений.\n'
            '7. Завершайте заминкой.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного темпа.\n'
            '12. Разнообразьте интервалы.',
        'commonMistakes': '1. Жёсткое приземление.\n'
            '2. Слишком быстрый темп.\n'
            '3. Работа только руками.\n'
            '4. Задержка дыхания.\n'
            '5. Отсутствие разминки.\n'
            '6. Слишком длинная сессия.\n'
            '7. Неправильная обувь.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_128',
        'name': 'Растяжка ягодиц',
        'description': 'Растяжка ягодиц — растяжка ягодичных мышц лёжа. Помогает снять напряжение. Отлично после тренировки ног. Подходит для всех. Растяжка ягодиц отлично сочетается с другими упражнениями на гибкость. Это одно из ключевых упражнений для растяжки ягодиц.',
        'muscleGroups': '["flexibility","glutes"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на спину.\n'
            '2. Нога на ногу.\n'
            '3. Тяните колено к груди.\n'
            '4. Дышите ровно.\n'
            '5. Задерживайтесь 20–30 секунд.\n'
            '6. Повторите на другую сторону.\n'
            '7. Не пружиньте.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного входа.\n'
            '12. Разнообразьте варианты (сидя, стоя).',
        'commonMistakes': '1. Резкие движения.\n'
            '2. Слишком сильное растяжение.\n'
            '3. Задержка дыхания.\n'
            '4. Спешка.\n'
            '5. Слишком короткое удержание.\n'
            '6. Отсутствие расслабления.\n'
            '7. Слишком быстрый вход.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в ягодицах.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_129',
        'name': 'Наклон вперёд сидя',
        'description': 'Наклон вперёд сидя — растяжка задней поверхности бедра и спины. Улучшает гибкость. Отлично для восстановления. Подходит для всех. Наклон вперёд сидя отлично сочетается с другими упражнениями на гибкость. Это одно из ключевых упражнений для растяжки задней поверхности бедра.',
        'muscleGroups': '["flexibility","hamstrings","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте, ноги вытянуты.\n'
            '2. Наклоняйтесь плавно.\n'
            '3. Спину не круглите.\n'
            '4. Дышите ровно.\n'
            '5. Задерживайтесь 20–30 секунд.\n'
            '6. Не пружиньте.\n'
            '7. Расслабляйте спину.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного входа.\n'
            '12. Разнообразьте варианты (с согнутыми коленями).',
        'commonMistakes': '1. Рывки.\n'
            '2. Округление спины.\n'
            '3. Слишком сильное растяжение.\n'
            '4. Задержка дыхания.\n'
            '5. Спешка.\n'
            '6. Слишком короткое удержание.\n'
            '7. Отсутствие расслабления.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в пояснице.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_130',
        'name': 'Поза голубя',
        'description': 'Поза голубя — глубокая растяжка бёдер и ягодиц. Отлично после тренировки ног. Улучшает гибкость. Требует подготовки. Масштабируется подушкой под таз. Поза голубя отлично сочетается с другими асанами йоги. Это одна из ключевых асан для растяжки бёдер.',
        'muscleGroups': '["flexibility","glutes","quadriceps"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Передняя нога согнута.\n'
            '2. Задняя прямая.\n'
            '3. Таз к полу.\n'
            '4. Дышите ровно.\n'
            '5. Задерживайтесь 30–60 секунд.\n'
            '6. Повторите на другую сторону.\n'
            '7. Не пружиньте.\n'
            '8. Плечи не поднимайте.\n'
            '9. Следите за осанкой.\n'
            '10. Работайте с полной амплитудой.\n'
            '11. Начинайте с медленного входа.\n'
            '12. Разнообразьте варианты (с подушкой, с опорой).',
        'commonMistakes': '1. Резкие движения.\n'
            '2. Слишком сильное растяжение.\n'
            '3. Задержка дыхания.\n'
            '4. Спешка.\n'
            '5. Слишком короткое удержание.\n'
            '6. Отсутствие расслабления.\n'
            '7. Неправильная техника.\n'
            '8. Работа без контроля.\n'
            '9. Работа через боль в коленях.\n'
            '10. Работа без плана.\n'
            '11. Отсутствие разнообразия.\n'
            '12. Слишком быстрый старт.',
        'createdAt': now,
        'updatedAt': now,
      },
    ];

    int inserted = 0;
    for (final exercise in defaultExercises) {
      try {
        final existing = await db.query('exercises',
            where: 'id = ?', whereArgs: [exercise['id']], limit: 1);
        if (existing.isEmpty) {
          await db.insert('exercises', exercise);
          inserted++;
        }
      } catch (e) {
        debugPrint('  ⚠️ Пропуск ${exercise['id']}: $e');
      }
    }
    debugPrint('✅ Добавлено $inserted новых упражнений (всего дефолтных: 130)');

    // 🆕 v17: пост-обработка — гарантируем defaultFormat для всех
    try {
      final rowsToFix = await db.query(
        'exercises',
        where: "isCustom = 0 AND (defaultFormat IS NULL OR defaultFormat = '')",
      );
      if (rowsToFix.isNotEmpty) {
        debugPrint(
            '🔧 Пост-обработка: ${rowsToFix.length} упражнений без defaultFormat');
        int fixed = 0;
        for (final row in rowsToFix) {
          final id = row['id'] as String;
          final name = (row['name'] as String?) ?? '';
          final typeStr = (row['exerciseType'] as String?) ?? 'strength';

          final exerciseType = ExerciseType.values.firstWhere(
                (t) => t.name == typeStr,
            orElse: () => ExerciseType.strength,
          );
          final format = exerciseType.inferFormatFromName(name);

          try {
            await db.update(
              'exercises',
              {'defaultFormat': format.name},
              where: 'id = ?',
              whereArgs: [id],
            );
            fixed++;
          } catch (e) {
            debugPrint('  ⚠️ Ошибка для $id: $e');
          }
        }
        debugPrint('  ✅ defaultFormat проставлен для $fixed/${rowsToFix.length}');
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка пост-обработки defaultFormat: $e');
    }

    // 🆕 v19: проставляем изображения стандартным упражнениям
    try {
      final imgCount = await applyDefaultExerciseImages(db);
      debugPrint('🖼️ Проставлены изображения для $imgCount упражнений');
    } catch (e) {
      debugPrint('⚠️ Ошибка простановки изображений: $e');
    }
  }

  // ==================== ШАБЛОНЫ ПРОГРАММ (15 шт) ====================

  Future<void> _seedDefaultTemplates(Database db) async {
    debugPrint('🌱 Заполняем шаблоны программ (15 шт)...');
    await db.delete('workout_templates');

    final uuid = const Uuid();
    final templates = [
      {
        'id': 'tpl_001', 'name': 'Грудь и жим', 'type': 'weekly', 'category': 'chest', 'recommendedLevel': 'intermediate',
        'description': 'Упор на грудные мышцы и жимовые движения. 5 тренировок в неделю.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_001', 'ex_default_002', 'ex_default_003', 'ex_default_020'], false],
          [2, ['ex_default_005', 'ex_default_006', 'ex_default_017', 'ex_default_035'], false],
          [3, ['ex_default_012', 'ex_default_013', 'ex_default_014', 'ex_default_015'], false],
          [4, ['ex_default_031', 'ex_default_032', 'ex_default_033', 'ex_default_034'], false],
          [5, ['ex_default_004', 'ex_default_021', 'ex_default_022', 'ex_default_023'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_002', 'name': 'Спина и становая', 'type': 'weekly', 'category': 'back', 'recommendedLevel': 'advanced',
        'description': 'Мощная программа для развития спины. Становая тяга, подтягивания и тяги.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_008', 'ex_default_005', 'ex_default_006', 'ex_default_007', 'ex_default_035'], false],
          [2, ['ex_default_010', 'ex_default_011', 'ex_default_019', 'ex_default_040'], false],
          [3, ['ex_default_012', 'ex_default_015', 'ex_default_016', 'ex_default_042'], false],
          [4, ['ex_default_008', 'ex_default_005', 'ex_default_017', 'ex_default_036'], false],
          [5, ['ex_default_021', 'ex_default_022', 'ex_default_023', 'ex_default_038'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_003', 'name': 'Ноги и присед', 'type': 'weekly', 'category': 'legs', 'recommendedLevel': 'intermediate',
        'description': 'Интенсивная программа для ног. Приседания, жим ногами и выпады.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_012', 'ex_default_013', 'ex_default_014', 'ex_default_015', 'ex_default_043'], false],
          [2, ['ex_default_001', 'ex_default_009', 'ex_default_017', 'ex_default_018'], false],
          [3, ['ex_default_012', 'ex_default_008', 'ex_default_005', 'ex_default_042'], false],
          [4, ['ex_default_016', 'ex_default_014', 'ex_default_024', 'ex_default_044'], false],
          [5, ['ex_default_021', 'ex_default_022', 'ex_default_025', 'ex_default_058'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_004', 'name': 'Сбалансированная (три базы)', 'type': 'weekly', 'category': 'balanced', 'recommendedLevel': 'advanced',
        'description': 'Жим, становая и присед в одной программе. Для продвинутых атлетов.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_001', 'ex_default_008', 'ex_default_012', 'ex_default_002'], false],
          [2, ['ex_default_005', 'ex_default_009', 'ex_default_017', 'ex_default_010'], false],
          [3, ['ex_default_020', 'ex_default_021', 'ex_default_022', 'ex_default_023'], false],
          [4, ['ex_default_031', 'ex_default_006', 'ex_default_042', 'ex_default_013'], false],
          [5, ['ex_default_006', 'ex_default_010', 'ex_default_018', 'ex_default_019', 'ex_default_022'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_005', 'name': 'Кардио и функционал', 'type': 'weekly', 'category': 'cardio', 'recommendedLevel': 'beginner',
        'description': 'Упор на кардио, собственный вес и бокс. Для новичков.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_024', 'ex_default_027', 'ex_default_004', 'ex_default_054'], false],
          [2, ['ex_default_025', 'ex_default_028', 'ex_default_021', 'ex_default_022'], false],
          [3, ['ex_default_026', 'ex_default_029', 'ex_default_030', 'ex_default_055'], false],
          [4, ['ex_default_024', 'ex_default_027', 'ex_default_020', 'ex_default_053'], false],
          [5, ['ex_default_030', 'ex_default_022', 'ex_default_023', 'ex_default_056'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_006', 'name': 'Бицепс и трицепс', 'type': 'weekly', 'category': 'arms', 'recommendedLevel': 'intermediate',
        'description': 'Специализированная программа для рук. Бицепс + трицепс 2 раза в неделю.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_017', 'ex_default_018', 'ex_default_019', 'ex_default_046', 'ex_default_047'], false],
          [2, ['ex_default_001', 'ex_default_005', 'ex_default_012', 'ex_default_021'], false],
          [3, ['ex_default_045', 'ex_default_048', 'ex_default_049', 'ex_default_050', 'ex_default_020'], false],
          [4, ['ex_default_009', 'ex_default_006', 'ex_default_013', 'ex_default_022'], false],
          [5, ['ex_default_017', 'ex_default_046', 'ex_default_018', 'ex_default_019'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_007', 'name': 'Плечи и трапеции', 'type': 'weekly', 'category': 'shoulders', 'recommendedLevel': 'intermediate',
        'description': 'Программа для развития дельт и трапеций. Красивые плечи.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_009', 'ex_default_010', 'ex_default_011', 'ex_default_039', 'ex_default_040'], false],
          [2, ['ex_default_001', 'ex_default_006', 'ex_default_012', 'ex_default_021'], false],
          [3, ['ex_default_041', 'ex_default_010', 'ex_default_011', 'ex_default_037', 'ex_default_040'], false],
          [4, ['ex_default_002', 'ex_default_005', 'ex_default_013', 'ex_default_022'], false],
          [5, ['ex_default_039', 'ex_default_009', 'ex_default_010', 'ex_default_011'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_008', 'name': 'Жиросжигание', 'type': 'weekly', 'category': 'fatLoss', 'recommendedLevel': 'intermediate',
        'description': 'Интенсивная программа для сжигания жира. Кардио + круговые тренировки.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_024', 'ex_default_012', 'ex_default_001', 'ex_default_021'], false],
          [2, ['ex_default_025', 'ex_default_006', 'ex_default_017', 'ex_default_022', 'ex_default_054'], false],
          [3, ['ex_default_027', 'ex_default_028', 'ex_default_020', 'ex_default_023', 'ex_default_058'], false],
          [4, ['ex_default_026', 'ex_default_013', 'ex_default_005', 'ex_default_021', 'ex_default_051'], false],
          [5, ['ex_default_024', 'ex_default_014', 'ex_default_019', 'ex_default_022', 'ex_default_053'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_009', 'name': 'Набор массы', 'type': 'weekly', 'category': 'hypertrophy', 'recommendedLevel': 'advanced',
        'description': 'Программа для увеличения мышечной массы. Высокий объём и интенсивность.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_001', 'ex_default_002', 'ex_default_003', 'ex_default_020', 'ex_default_033'], false],
          [2, ['ex_default_008', 'ex_default_005', 'ex_default_006', 'ex_default_007', 'ex_default_035'], false],
          [3, ['ex_default_012', 'ex_default_013', 'ex_default_014', 'ex_default_015', 'ex_default_043'], false],
          [4, ['ex_default_031', 'ex_default_032', 'ex_default_034', 'ex_default_004', 'ex_default_020'], false],
          [5, ['ex_default_005', 'ex_default_036', 'ex_default_038', 'ex_default_006', 'ex_default_017'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_010', 'name': 'Йога и гибкость', 'type': 'weekly', 'category': 'yoga', 'recommendedLevel': 'beginner',
        'description': 'Комплекс на развитие гибкости и восстановление. Йога, пилатес, стретчинг.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_029', 'ex_default_030', 'ex_default_021', 'ex_default_022', 'ex_default_055'], false],
          [2, ['ex_default_056', 'ex_default_030', 'ex_default_052', 'ex_default_053', 'ex_default_051'], false],
          [3, ['ex_default_029', 'ex_default_030', 'ex_default_021', 'ex_default_022', 'ex_default_055'], false],
          [4, ['ex_default_056', 'ex_default_030', 'ex_default_052', 'ex_default_053', 'ex_default_051'], false],
          [5, ['ex_default_029', 'ex_default_030', 'ex_default_055', 'ex_default_056', 'ex_default_021'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },

      // ============ v13: 11-15 ============

      {
        'id': 'tpl_011', 'name': 'Full Body для начинающих', 'type': 'weekly', 'category': 'beginner', 'recommendedLevel': 'beginner',
        'description': 'Три полноценные тренировки на всё тело в неделю. Идеально для старта.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_012', 'ex_default_001', 'ex_default_005', 'ex_default_021'], false],
          [2, [], true],
          [3, ['ex_default_013', 'ex_default_007', 'ex_default_004', 'ex_default_022'], false],
          [4, [], true],
          [5, ['ex_default_014', 'ex_default_010', 'ex_default_019', 'ex_default_048'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_012', 'name': 'Сплит: Спина + Бицепс', 'type': 'weekly', 'category': 'back', 'recommendedLevel': 'intermediate',
        'description': 'Классический сплит. Спина и бицепс дважды в неделю.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_005', 'ex_default_006', 'ex_default_007', 'ex_default_035', 'ex_default_017'], false],
          [2, ['ex_default_012', 'ex_default_013', 'ex_default_015', 'ex_default_044'], false],
          [3, ['ex_default_001', 'ex_default_009', 'ex_default_020', 'ex_default_021'], false],
          [4, ['ex_default_008', 'ex_default_066', 'ex_default_067', 'ex_default_065', 'ex_default_018'], false],
          [5, ['ex_default_010', 'ex_default_011', 'ex_default_040', 'ex_default_022'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_013', 'name': 'Сплит: Грудь + Трицепс', 'type': 'weekly', 'category': 'chest', 'recommendedLevel': 'intermediate',
        'description': 'Проработка груди и трицепса. Классический пуш-сплит.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_001', 'ex_default_031', 'ex_default_032', 'ex_default_020', 'ex_default_018'], false],
          [2, ['ex_default_008', 'ex_default_005', 'ex_default_006', 'ex_default_021'], false],
          [3, ['ex_default_012', 'ex_default_013', 'ex_default_014', 'ex_default_022'], false],
          [4, ['ex_default_002', 'ex_default_033', 'ex_default_003', 'ex_default_046', 'ex_default_019'], false],
          [5, ['ex_default_009', 'ex_default_010', 'ex_default_041', 'ex_default_040'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_014', 'name': 'HIIT жиросжигание', 'type': 'weekly', 'category': 'hiit', 'recommendedLevel': 'intermediate',
        'description': 'Высокоинтенсивные интервальные тренировки. 4 сессии в неделю по 25-30 минут.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_058', 'ex_default_125', 'ex_default_127', 'ex_default_089'], false],
          [2, ['ex_default_054', 'ex_default_087', 'ex_default_088', 'ex_default_127'], false],
          [3, [], true],
          [4, ['ex_default_126', 'ex_default_058', 'ex_default_089', 'ex_default_124'], false],
          [5, ['ex_default_125', 'ex_default_087', 'ex_default_054', 'ex_default_127'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_015', 'name': 'Сила 5×5', 'type': 'weekly', 'category': 'strength', 'recommendedLevel': 'advanced',
        'description': 'Программа силы по схеме 5 подходов × 5 повторений. Три базовых упражнения.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_012', 'ex_default_001', 'ex_default_006', 'ex_default_022'], false],
          [2, [], true],
          [3, ['ex_default_012', 'ex_default_009', 'ex_default_008', 'ex_default_021'], false],
          [4, [], true],
          [5, ['ex_default_012', 'ex_default_001', 'ex_default_006', 'ex_default_023'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
    ];

    for (final t in templates) {
      await db.insert('workout_templates', t);
    }
    debugPrint('✅ Добавлено ${templates.length} шаблонов программ');
  }

  List<Map<String, dynamic>> _createTemplateDays(Uuid uuid, List<List<dynamic>> daysData) {
    final result = <Map<String, dynamic>>[];
    for (final dayData in daysData) {
      final dayNumber = dayData[0] as int;
      final exerciseIds = List<String>.from(dayData[1] as List);
      final isRestDay = dayData[2] as bool;

      final exercises = exerciseIds.map((exId) {
        return {
          'id': uuid.v4(),
          'exerciseId': exId,
          'order': 0,
          'sets': [
            {'setNumber': 1, 'reps': 12, 'weight': 0.0, 'isWarmup': true, 'status': 'pending', 'rpe': null, 'notes': null, 'restSeconds': 60},
            {'setNumber': 2, 'reps': 12, 'weight': 0.0, 'isWarmup': false, 'status': 'pending', 'rpe': null, 'notes': null, 'restSeconds': 90},
            {'setNumber': 3, 'reps': 12, 'weight': 0.0, 'isWarmup': false, 'status': 'pending', 'rpe': null, 'notes': null, 'restSeconds': 90},
            {'setNumber': 4, 'reps': 10, 'weight': 0.0, 'isWarmup': false, 'status': 'pending', 'rpe': null, 'notes': null, 'restSeconds': 90},
          ],
          'groupType': 'straight',
          'restBetweenSeconds': 90,
          'notes': null,
        };
      }).toList();

      result.add({
        'id': uuid.v4(),
        'programId': '',
        'dayNumber': dayNumber,
        'date': null,
        'exercises': exercises,
        'isRestDay': isRestDay,
        'notes': null,
        'status': 'pending',
      });
    }
    return result;
  }

  // ==================== ОБЩИЕ МЕТОДЫ ====================

  Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(String table, {bool? distinct, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) async {
    final db = await database;
    return await db.query(table, distinct: distinct ?? false, where: where, whereArgs: whereArgs, groupBy: groupBy, having: having, orderBy: orderBy, limit: limit, offset: offset);
  }

  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> deleteAll(String table) async {
    final db = await database;
    await db.delete(table);
  }

  Future<int> count(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    final result = await db.query(table, where: where, whereArgs: whereArgs, columns: ['COUNT(*) as count']);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}