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
      version: 21,
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
        debugPrint('🔧 v4: Пересоздаём шаблоны');
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
            } catch (e) {
              debugPrint('  ⚠️ Ошибка добавления ${entry.key}: $e');
            }
          }
        }
      }

      if (oldVersion < 6) {
        debugPrint('🔧 v6: Настроение и фото в workout_logs');
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
            } catch (e) {
              debugPrint('  ⚠️ Ошибка: $e');
            }
          }
        }
      }

      if (oldVersion < 7) {
        debugPrint('🔧 v7: Таблица program_sessions');
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
        }
      }

      if (oldVersion < 8) {
        debugPrint('🔧 v8: Таблица fitness_targets');
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
        }
      }

      if (oldVersion < 9) {
        debugPrint('🔧 v9: Колонка entries в fitness_targets');
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final tableNames = tables.map((t) => t['name'] as String).toList();
        if (tableNames.contains('fitness_targets')) {
          final columns = await db.rawQuery('PRAGMA table_info(fitness_targets)');
          final columnNames = columns.map((c) => c['name'] as String).toList();
          if (!columnNames.contains('entries')) {
            try {
              await db.execute("ALTER TABLE fitness_targets ADD COLUMN entries TEXT DEFAULT '[]'");
            } catch (e) {
              debugPrint('  ⚠️ Ошибка: $e');
            }
          }
        }
      }

      if (oldVersion < 10) {
        debugPrint('🔧 v10: Новые поля в workout_programs');
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
              } catch (e) {
                debugPrint('  ⚠️ Ошибка: $e');
              }
            }
          }
        }
      }

      // v11–v15: пересборка стандартных упражнений (исторические шаги).
      // Теперь база содержит 50 упражнений — все миграции ниже идемпотентно
      // пересоздают стандартный набор.
      if (oldVersion < 11) {
        debugPrint('🔧 v11: Пересобираем стандартные упражнения');
        try {
          await db.delete('exercises', where: 'isCustom = ?', whereArgs: [0]);
        } catch (e) {
          debugPrint('  ⚠️ Ошибка удаления: $e');
        }
        await _seedDefaultExercises(db);
        await db.delete('workout_templates');
        await _seedDefaultTemplates(db);
      }

      if (oldVersion < 12 || oldVersion < 13 || oldVersion < 14 || oldVersion < 15) {
        debugPrint('🔧 v12–v15: Пересобираем 50 упражнений с расширенными описаниями');
        try {
          await db.delete('exercises', where: 'isCustom = ?', whereArgs: [0]);
        } catch (e) {
          debugPrint('  ⚠️ Ошибка: $e');
        }
        await _seedDefaultExercises(db);
      }

      if (oldVersion < 16) {
        debugPrint('🔧 v16: format-метрики (кардио/бокс/статика)');

        await _safeAddColumn(db, 'exercises', 'defaultFormat', 'TEXT');
        await _safeAddColumn(db, 'progress_records', 'bestDistance', 'REAL');
        await _safeAddColumn(db, 'progress_records', 'bestPace', 'REAL');
        await _safeAddColumn(db, 'progress_records', 'bestDuration', 'INTEGER');
        await _safeAddColumn(db, 'progress_records', 'bestRounds', 'INTEGER');
        await _safeAddColumn(db, 'progress_records', 'bestHoldSeconds', 'INTEGER');
        await _safeAddColumn(db, 'workout_logs', 'totalByMetric', 'TEXT');
        await _safeAddColumn(
          db,
          'program_sessions',
          'totalByMetricCompleted',
          "TEXT DEFAULT '{}'",
        );

        // Проставляем defaultFormat только для тех упражнений, которые остались в базе
        final formatUpdates = <String, String>{
          'ex_default_022': 'hold',       // Планка
          'ex_default_051': 'hold',       // Боковая планка
          'ex_default_054': 'timedSets',  // Прыжки на скакалке
          'ex_default_089': 'timedSets',  // Альпинист
          'ex_default_108': 'timedSets',  // Тяга каната (обычный strength, но оставим дефолт)
        };
        for (final entry in formatUpdates.entries) {
          try {
            await db.update(
              'exercises',
              {'defaultFormat': entry.value},
              where: 'id = ? AND isCustom = 0',
              whereArgs: [entry.key],
            );
          } catch (e) {
            debugPrint('  ⚠️ ${entry.key}: $e');
          }
        }
      }

      if (oldVersion < 17) {
        debugPrint('🔧 v17: defaultFormat для всех стандартных');
        try {
          final rows = await db.query(
            'exercises',
            where: "isCustom = 0 AND (defaultFormat IS NULL OR defaultFormat = '')",
          );
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
              debugPrint('  ⚠️ $id: $e');
            }
          }
          debugPrint('  ✅ defaultFormat: $fixed/${rows.length}');
        } catch (e) {
          debugPrint('  ⚠️ Ошибка v17: $e');
        }
      }

      if (oldVersion < 18) {
        debugPrint('🔧 v18: backgroundImage в workout_programs');
        await _safeAddColumn(db, 'workout_programs', 'backgroundImage', 'TEXT');
      }

      if (oldVersion < 19) {
        debugPrint('🔧 v19: изображения стандартным');
        try {
          await applyDefaultExerciseImages(db);
        } catch (e) {
          debugPrint('  ⚠️ Ошибка v19: $e');
        }
      }

      if (oldVersion < 20) {
        debugPrint('🔧 v20: локальные assets');
        try {
          await db.update('exercises', {'imageUrl': null}, where: 'isCustom = 0');
          await applyDefaultExerciseImages(db);
        } catch (e) {
          debugPrint('  ⚠️ Ошибка v20: $e');
        }
      }

      // 🔥 v21: Оставляем ровно 50 ключевых упражнений, чистим остальные
      // и пересобираем шаблоны, чтобы не было «сиротских» ссылок.
      if (oldVersion < 21) {
        debugPrint('🔧 v21: Пересобираем ядро из 50 упражнений');
        try {
          final deleted = await db.delete('exercises', where: 'isCustom = ?', whereArgs: [0]);
          debugPrint('  🗑️ Удалено $deleted стандартных упражнений');
        } catch (e) {
          debugPrint('  ⚠️ Ошибка удаления: $e');
        }
        await _seedDefaultExercises(db);
        await db.delete('workout_templates');
        await _seedDefaultTemplates(db);
        debugPrint('  ✅ v21 завершена (50 упражнений, 15 шаблонов)');
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка миграции фитнес БД: $e');
    }
    await _createIndexes(db);
  }

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
      if (tables.isEmpty) return;

      final columns = await db.rawQuery('PRAGMA table_info($table)');
      final names = columns.map((c) => c['name'] as String).toList();
      if (names.contains(column)) return;

      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
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

  // ==================== УПРАЖНЕНИЯ (50 ключевых) ====================

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
      if (allDefaults.length >= 50) {
        debugPrint('📦 Все 50 дефолтных упражнений уже есть, пропускаем');
        return;
      }
      debugPrint('⚠️ Найдено ${allDefaults.length}/50 дефолтных, дополняем...');
    } else {
      debugPrint('🌱 Заполняем базу 50 ключевыми упражнениями...');
    }

    final now = DateTime.now().toIso8601String();

    final defaultExercises = [
      // ==================== ГРУДЬ (6) ====================
      {
        'id': 'ex_default_001',
        'name': 'Жим штанги лёжа',
        'description':
        'Жим штанги лёжа — фундаментальное многосуставное упражнение, образующее ядро практически любой программы тренировки верха тела: бодибилдинг, пауэрлифтинг, кроссфит, оздоровительный фитнес. В движении участвует большая грудная мышца (ключичная, грудинная и рёберная части), передние пучки дельтовидных мышц, трицепсы, а также мышцы-стабилизаторы лопаток и кора. Упражнение позволяет работать с большими весами и служит основным индикатором силы жимового движения. Техника масштабируется под любой уровень: новички начинают с пустого грифа и отработки паттерна, опытные атлеты работают с максимальными весами, варьируя хват, наклон, паузы и темп. Регулярное выполнение напрямую влияет на объём и плотность груди, силу верхней части тела и общую жимовую выносливость. Жим лёжа — это универсальный маркер прогресса, который легко отслеживать и сравнивать с нормативными значениями. В пауэрлифтинге это одно из трёх соревновательных движений, что дополнительно мотивирует работать над техникой. Правильная техника сведения лопаток, нейтральная линия запястья и контроль траектории грифа — фундамент для безопасного прогресса. Исследования показывают, что жим эффективно стимулирует гипертрофию грудных при работе в диапазоне 6–12 повторений с достаточной нагрузкой; для силовых целей оптимальны подходы на 3–6 повторений с около-максимальными весами. Вариации — наклонная скамья, узкий хват, пауза на груди, работа с цепями или резинками — позволяют смещать акцент на разные части грудных, трицепсы или дельты, делая упражнение универсальным инструментом тренировки верха тела. При работе с большими весами обязательно используйте страховку или помощь партнёра: это даёт возможность безопасно прогрессировать и пробовать новые веса. Разминка плечевого пояса перед жимом обязательна и должна включать вращения, разведения и лёгкие подходы с пустым грифом.',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Лягте на скамью так, чтобы гриф оказался на уровне глаз, стопы полностью на полу, ягодицы и лопатки — плотно прижаты к скамье.\n'
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
        'commonMistakes':
        '1. Отрыв таза от скамьи — перегружает поясницу, снижает силу жима и повышает риск травмы.\n'
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
        'description':
        'Жим гантелей лёжа — важное многосуставное упражнение для развития грудных мышц, передних дельт и трицепсов, дающее большую амплитуду по сравнению с жимом штанги. Каждая рука работает независимо, что помогает выявить и устранить мышечный дисбаланс, повышает требования к стабилизаторам и делает движение более безопасным для плеч. Гантели позволяют комфортно разворачивать кисти и подстраивать траекторию под индивидуальную анатомию, поэтому упражнение часто рекомендуют людям с чувствительными плечевыми суставами. По сравнению со штангой здесь сложнее работать с максимальными весами, зато проще контролировать растяжение грудных в нижней точке и пиковое сокращение в верхней. Жим гантелей отлично подходит как для гипертрофии, так и для силовой выносливости, а также используется как вспомогательное движение для улучшения жима штанги. Благодаря независимой работе рук вы учитесь держать баланс и включать стабилизаторы плечевого пояса, что положительно сказывается на общей технике жимовых движений. Дополнительный бонус — возможность работать в большем диапазоне движения: гантели можно опустить глубже, чем гриф, что усиливает растяжение грудных и стимулирует больше мышечных волокон. В тренировочных программах жим гантелей часто ставят после жима штанги как второй жимовой блок или используют как основное упражнение для людей с ограничениями по плечам. Техника с супинацией кистей в верхней точке усиливает сокращение грудных. Для максимальной безопасности используйте помощь партнёра при подаче гантелей и работе с большими весами. Помните: главное в этом упражнении — контроль амплитуды и стабильность лопаток, а не максимальный вес.',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Возьмите гантели нейтральным хватом, сядьте на край скамьи, затем аккуратно откиньтесь назад, упираясь гантелями в бёдра.\n'
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
        'commonMistakes':
        '1. Слишком большой вес — теряется контроль, амплитуда и техника.\n'
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
        'id': 'ex_default_004',
        'name': 'Отжимания от пола',
        'description':
        'Отжимания от пола — базовое упражнение с собственным весом, которое тренирует грудь, передние дельты и трицепсы, одновременно укрепляя кор и стабилизаторы. Доступно в любых условиях и легко масштабируется: от отжиманий с колен для новичков до отжиманий с отягощением или на нестабильной опоре для продвинутых. Это функциональное движение, которое напрямую переносится на жимовые результаты и общую физическую форму. Регулярное выполнение улучшает осанку, выносливость верхней части тела и учит правильно держать корпус в закрытой кинетической цепи. Отжимания отлично сочетаются с жимами и используются как разминочное, добивочное или самостоятельное упражнение. Для прогресса можно менять положение рук (широкая, узкая, «алмаз»), высоту опоры (ноги на скамье), темп и добавлять отягощение. Отжимания — одно из немногих упражнений, которое одновременно развивает силу, выносливость и координацию, поэтому оно входит в программы подготовки военных, спасателей, спортсменов и просто людей, которые хотят быть в форме. Помимо грудных, отжимания нагружают трицепс, передние дельты, зубчатые мышцы и мышцы кора, что делает упражнение практически полноценной тренировкой верха тела. В отличие от жимов со свободными весами, здесь нет необходимости в страховке — вы всегда можете прекратить подход, опустившись на колени. При этом отжимания легко прогрессировать: изменение рычага, добавление веса, работа на одной руке — всё это открывает широкий простор для роста без оборудования. Для новичков рекомендуются отжимания с колен или с наклоном вверх (руки на скамье), для опытных — с ногами на скамье или с отягощением на спине.',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips':
        '1. Примите упор лёжа: ладони чуть шире плеч, пальцы направлены вперёд или слегка внутрь.\n'
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
        'commonMistakes':
        '1. Провисание поясницы или поднятый таз — нарушает технику и нагружает спину.\n'
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
        'description':
        'Жим гантелей на наклонной скамье (30–45°) переносит акцент на верхнюю (ключичную) часть большой грудной мышцы — зону, которая часто отстаёт при горизонтальном жиме. Гантели позволяют работать в большей амплитуде и комфортнее для плеч, чем штанга, а также требуют активного включения стабилизаторов и учат держать симметрию. Упражнение отлично подходит как для набора массы, так и для формирования визуально «полной» груди. Правильный угол наклона — ключ к тому, чтобы нагрузка шла в грудь, а не в дельты. Как и другие жимы гантелей, это упражнение способствует устранению мышечного дисбаланса. Отлично сочетается с горизонтальным жимом и разводкой, а также с упражнениями на верх груди на блочных тренажёрах. Наклонная скамья перераспределяет нагрузку: чем больше угол (в разумных пределах 30–45°), тем активнее работает ключичная часть грудной мышцы, но при слишком большом наклоне (близком к вертикали) основная нагрузка уходит в передние дельты. Оптимальный угол — 30° для акцента на верх груди при сохранении хорошего растяжения. Работа с гантелями позволяет варьировать положение кистей (нейтральный хват, супинация), что снижает риск травм плеча. Упражнение часто используется как основное жимовое в день груди для тех, у кого отстаёт верхняя часть, или как вспомогательное после горизонтального жима. При больших весах важна помощь партнёра для подачи гантелей и страховки. Техника сведения лопаток и стабильного положения таза на скамье критически важна для безопасного прогресса.',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Установите наклон скамьи 30–45° — это оптимум для верха груди.\n'
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
        'commonMistakes':
        '1. Слишком большой наклон (близко к вертикали) — работа переходит на дельты.\n'
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
        'id': 'ex_default_034',
        'name': 'Жим штанги на наклонной скамье',
        'description':
        'Жим штанги на наклонной скамье — многосуставное упражнение, совмещающее преимущества классического жима лёжа и акцента на верхнюю (ключичную) часть грудных. Штанга позволяет работать с большими весами, чем гантели, что важно для силового и гипертрофийного прогресса. Наклон 30–45° перераспределяет нагрузку на ключичную часть большой грудной мышцы, а также включает передние дельты и трицепсы. Упражнение требует хорошей техники и контроля лопаток, особенно при работе с большими весами. Оно отлично подходит как основное жимовое движение в день груди для тех, у кого отстаёт верхняя часть. Как и классический жим лёжа, это упражнение требует страховки при работе с максимальными весами и хорошей разминки плечевых суставов. В отличие от жима гантелей, штанга фиксирует руки на одной линии, что делает движение более стабильным, но и более требовательным к мобильности плеч. Правильный угол наклона скамьи — критически важный параметр: слишком маленький угол превращает упражнение в горизонтальный жим, слишком большой — в жим сидя. При работе на наклонной скамье гриф опускается к верхней части груди (ключицам), а не к соскам, как в горизонтальном жиме. Это требует определённой координации и опыта. Упражнение отлично сочетается с жимом гантелей на наклонной, разводкой и кроссовером, а также с упражнениями на верх груди на блочных тренажёрах. Для новичков рекомендуется начинать с умеренных весов и отработки траектории, постепенно увеличивая нагрузку.',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Установите наклон скамьи 30–45°, сядьте и прижмите лопатки к скамье.\n'
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
        'commonMistakes':
        '1. Слишком большой вес — потеря техники и травмоопасность.\n'
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
      {
        'id': 'ex_default_032',
        'name': 'Сведение рук в кроссовере',
        'description':
        'Сведение рук в кроссовере — изолирующее упражнение для грудных мышц на блочном тренажёре. Главное преимущество — постоянное натяжение на протяжении всей амплитуды, в отличие от свободных весов, где нагрузка «проваливается» в верхней и нижней точках. Это делает упражнение идеальным для пампинга, доработки формы груди и работы над средней линией. Кроссовер позволяет менять угол и высоту блоков, акцентируя верх, середину или низ груди, а также использовать различные рукоятки для комфорта запястий. Упражнение подходит и новичкам, и опытным атлетам, и отлично вписывается в конец тренировки груди. Постоянное натяжение также помогает лучше чувствовать целевую мышцу, что особенно полезно для людей, у которых грудь «не отзывается» на жимы. При правильной технике упражнение безопасно для плеч и позволяет комфортно контролировать амплитуду. Сведение в кроссовере часто используется как добивочное после жимов, но может быть и основным изолирующим упражнением для груди. Вариации: высокие блоки (акцент на низ груди), средние (середина), низкие (верх груди), работа одной рукой для лучшей концентрации. Упражнение отлично сочетается с жимами, разводкой и отжиманиями. Правильная техника с фиксированными локтями и контролем корпуса — ключ к тому, чтобы нагрузка шла именно в грудные, а не в дельты или трицепс.',
        'muscleGroups': '["chest","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Установите блоки на нужную высоту (обычно чуть выше плеч) и возьмите рукоятки.\n'
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
        'commonMistakes':
        '1. Использование инерции и раскачивание корпусом — снижает эффективность.\n'
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

      // ==================== СПИНА (7) ====================
      {
        'id': 'ex_default_005',
        'name': 'Подтягивания',
        'description':
        'Подтягивания — базовое упражнение с собственным весом для развития широчайших мышц спины, бицепсов и мышц-стабилизаторов лопаток. Это один из главных показателей силовой подготовки верхней части тела и неотъемлемая часть функционального тренинга. Подтягивания развивают не только силу, но и контроль над лопатками, что напрямую влияет на осанку и здоровье плечевых суставов. Упражнение легко масштабируется: от негативных подтягиваний и резинки до подтягиваний с отягощением. Регулярная практика значительно улучшает форму спины, ширину плеч и общую силовую выносливость. Подтягивания также отлично развивают координацию и учат правильно включать широчайшие, что переносится на все тяговые движения. В отличие от тяги верхнего блока, подтягивания требуют работы всего тела и активного включения мышц кора, что делает их более функциональными. Это упражнение часто используется как тест на силовую подготовку: количество чистых подтягиваний — универсальный индикатор уровня атлета. Подтягивания можно выполнять разными хватами: прямым, обратным, нейтральным, широким, узким — каждый вариант смещает акцент на разные участки широчайших и бицепса. Для новичков рекомендуется начинать с негативных подтягиваний, австралийских подтягиваний или работы с резинкой. Для продвинутых — с отягощением на поясе, «выходы силой» и подтягивания на одной руке. Подтягивания — это упражнение, которое стоит осваивать с первых месяцев тренировок, поскольку оно формирует базу для всей тяговой работы и укрепляет плечевой пояс.',
        'muscleGroups': '["back","biceps","lats"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips':
        '1. Возьмитесь за перекладину хватом чуть шире плеч, ладони направлены от себя.\n'
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
        'commonMistakes':
        '1. Раскачивание и рывки — инерция вместо работы мышц.\n'
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
        'description':
        'Тяга штанги в наклоне — мощное многосуставное упражнение для толщины спины. Оно прорабатывает широчайшие, ромбовидные, задние дельты и бицепсы, а также укрепляет поясницу и мышцы-разгибатели. Это одно из базовых движений для построения плотной, сильной спины и одно из главных упражнений в силовых программах. Тяга требует хорошей техники и контроля нейтрального положения позвоночника, поэтому для новичков рекомендуется начинать с лёгких весов и отработки паттерна наклона. При правильном выполнении упражнение развивает силу хвата и общую силовую выносливость, а также улучшает осанку. Тяга отлично сочетается с подтягиваниями, тягой верхнего блока и горизонтальной тягой. В отличие от тяги верхнего блока, здесь нет фиксированной траектории, что делает движение более функциональным, но и более требовательным к технике. Варианты выполнения: классическая тяга штанги в наклоне, тяга Т-грифа, тяга Пендлей (взрывная), тяга с опорой на скамью. Каждый вариант имеет свои особенности: например, тяга Пендлей акцентирует взрывную силу, а тяга с опорой снимает нагрузку с поясницы. Упражнение часто используется как основное для толщины спины в программах бодибилдинга и пауэрлифтинга. При работе с большими весами критически важна нейтральная спина и активное включение кора. Тяга штанги в наклоне — это упражнение, которое требует определённого уровня подготовки, поэтому новичкам стоит начинать с лёгких весов и постепенно прогрессировать. Для людей с проблемами поясницы рекомендуется заменить классическую тягу на тягу с опорой или тягу гантели.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Возьмите штангу хватом чуть шире плеч, встаньте ровно, стопы на ширине таза.\n'
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
        'commonMistakes':
        '1. Округление спины — травмоопасно для позвоночника.\n'
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
        'description':
        'Тяга верхнего блока — аналог подтягиваний на тренажёре, который позволяет точно дозировать вес и контролировать траекторию. Отлично подходит новичкам, которые ещё не могут подтягиваться, и опытным атлетам для добивки широчайших. Упражнение прорабатывает широчайшие, ромбовидные и бицепсы, при этом минимально нагружает поясницу. Регулируемый вес позволяет комфортно прогрессировать и концентрироваться на технике, а стабильная траектория снижает риск травмы. Тяга верхнего блока — отличное упражнение для отработки паттерна подтягиваний и для работы над осанкой. Его часто используют как разминочное или как основное упражнение для спины для людей с ограничениями. В отличие от подтягиваний, здесь вы работаете сидя, что снижает нагрузку на кор и позволяет сконцентрироваться на широчайших. Вариации: прямой хват (классика), обратный хват (акцент на бицепс и низ широчайших), нейтральный хват (комфорт для плеч), тяга к груди (стандарт) и тяга за голову (травмоопасно, не рекомендуется). Правильная техника с лопатками, сведёнными вниз и назад, — ключ к тому, чтобы нагрузка шла именно в широчайшие, а не в руки. Упражнение отлично сочетается с тягой штанги в наклоне, подтягиваниями и горизонтальной тягой. Для новичков это одно из лучших упражнений для начала работы над спиной. Для продвинутых — способ добить широчайшие после подтягиваний или проработать их в более контролируемом режиме.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Сядьте, зафиксируйте бёдра под валиками, возьмите рукоять хватом чуть шире плеч.\n'
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
        'commonMistakes':
        '1. Сильное отклонение корпуса назад — упражнение превращается в тягу к поясу.\n'
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
        'description':
        'Становая тяга — «король» упражнений, задействующий практически всё тело: спину, ягодицы, бицепс бедра, трапеции, кор и хват. Это одно из трёх соревновательных движений в пауэрлифтинге и мощнейший стимул для общего роста силы и массы. Техника критически важна: неправильное выполнение легко приводит к травме поясницы, поэтому осваивать её нужно постепенно, начиная с лёгких весов и с тренером. Освоив технику, вы получаете упражнение, которое развивает не только мышцы, но и функциональную силу, осанку и уверенность в зале. Становая тяга также улучшает хват, укрепляет кор и учит правильно поднимать тяжести в повседневной жизни. Она отлично сочетается с приседаниями и жимами в силовых программах и является базовым движением для силового троеборья. Вариации: классическая становая (с пола), румынская (с акцентом на заднюю цепь), сумо (широкая постановка ног), становая с трап-грифом (более безопасная для поясницы). Каждый вариант имеет свои особенности и подходит для разных целей. Классическая становая — универсальное движение, развивающее всю заднюю цепь. Сумо акцентирует квадрицепсы и внутреннюю поверхность бедра. Румынская — бицепс бедра и ягодицы. При работе с большими весами обязательна страховка и тщательная разминка. Становая тяга — упражнение, которое требует серьёзного подхода: отрабатывайте технику на лёгких весах, следите за нейтральной спиной и не гонитесь за весом в ущерб технике. Для новичков рекомендуется начинать с румынской тяги или становой с трап-грифом, чтобы освоить паттерн и укрепить спину.',
        'muscleGroups': '["back","glutes","hamstrings","lowerBack","traps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Штанга на полу, гриф над серединой стопы, носки под грифом.\n'
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
        'commonMistakes':
        '1. Округление спины — самая частая и опасная ошибка.\n'
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
        'description':
        'Тяга горизонтального блока сидя — упражнение для проработки средней и нижней части широчайших, а также ромбовидных мышц. Благодаря стабильной опоре и фиксированной траектории оно безопасно для поясницы и отлично подходит для работы над осанкой. Постоянное натяжение блока обеспечивает хороший контроль и позволяет концентрироваться на сведении лопаток. Регулярное выполнение улучшает форму спины и укрепляет мышцы-стабилизаторы. Упражнение отлично подходит для новичков и людей с ограничениями по пояснице, а также как добивка после тяги штанги или подтягиваний. Горизонтальная тяга учит правильно сводить лопатки, что напрямую влияет на осанку и здоровье плеч. В отличие от тяги верхнего блока, здесь акцент смещается на середину спины, что важно для баланса развития. Вариации: узкий нейтральный хват (акцент на середину), широкий прямой хват (акцент на задние дельты и верх спины), обратный хват (акцент на бицепс и низ широчайших), тяга одной рукой. Упражнение отлично сочетается с тягой штанги в наклоне, подтягиваниями и тягой верхнего блока. Для людей с проблемами поясницы это одно из лучших упражнений для спины, поскольку нагрузка на поясницу минимальна. Для продвинутых атлетов — способ добить середину спины после базовых тяг.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Сядьте, упритесь стопами в платформу, возьмите рукоять нейтральным хватом.\n'
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
        'commonMistakes':
        '1. Раскачивание корпусом для помощи тяге — снижает эффект.\n'
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
        'id': 'ex_default_038',
        'name': 'Тяга гантели к поясу',
        'description':
        'Тяга гантели к поясу с опорой на скамью — одностороннее упражнение для широчайших и ромбовидных мышц. Позволяет работать в большой амплитуде и растягивать мышцу в нижней точке, что делает его отличным для гипертрофии. Опора на скамью снимает нагрузку с поясницы и позволяет сконцентрироваться на одной стороне. Упражнение также помогает выявить и устранить мышечный дисбаланс. Тяга гантели отлично сочетается с подтягиваниями и тягой штанги. Односторонняя работа позволяет лучше почувствовать широчайшие и работать в более полной амплитуде, чем при двусторонней тяге. Это упражнение часто используется как основное в программах для спины у людей с проблемами поясницы, поскольку опора снимает нагрузку с позвоночника. Вариации: с опорой на скамью (классика), без опоры (требует стабильности кора), с резинкой (для дополнительного сопротивления в верхней точке). Правильная техника с фиксированным корпусом — ключ к тому, чтобы нагрузка шла в широчайшие, а не в поясницу. Упражнение отлично сочетается с тягой штанги в наклоне и подтягиваниями. Для новичков — отличный способ отработать паттерн тяги, не перегружая поясницу. Для продвинутых — возможность добить широчайшие в одностороннем режиме, работая в полной амплитуде.',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Поставьте одну ногу и руку на скамью, вторая нога — на полу.\n'
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
        'commonMistakes':
        '1. Скручивание корпуса — работа переходит на поясницу.\n'
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
      {
        'id': 'ex_default_042',
        'name': 'Румынская тяга',
        'description':
        'Румынская тяга — упражнение для бицепса бедра, ягодиц и поясницы, выполняемое с полусогнутыми ногами. В отличие от классической становой, акцент здесь на растяжении и работе задней цепи, а не на подъёме с пола. Это одно из лучших упражнений для развития бицепса бедра и ягодиц. Требует хорошей техники наклона и контроля нейтральной спины. Румынская тяга отлично сочетается с приседаниями, сгибаниями ног и хип-трастом. Это одно из ключевых упражнений для задней цепи и ягодиц. Название «румынская» происходит от легенды о румынском тяжелоатлете, который выполнял становую тягу с почти прямыми ногами. Техника: штанга опускается по ногам за счёт отведения таза назад, а не сгибания коленей. В нижней точке вы должны чувствовать сильное растяжение в бицепсе бедра — это и есть рабочий диапазон. Вариации: со штангой, с гантелями, на одной ноге (требует баланса), с паузой в нижней точке (для усиления растяжения). Упражнение отлично подходит как для гипертрофии, так и для силовых целей. Для гипертрофии работайте в диапазоне 8–12 повторений с контролем темпа; для силы — 4–6 повторений с большим весом. При работе с большими весами обязательна страховка. Техника с нейтральной спиной и отведением таза — ключ к безопасному прогрессу. Для новичков рекомендуется начинать с лёгких весов и отработки паттерна наклона без веса.',
        'muscleGroups': '["hamstrings","glutes","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Возьмите штангу хватом чуть шире плеч, встаньте ровно.\n'
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
        'commonMistakes':
        '1. Округление спины — риск травмы поясницы.\n'
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

      // ==================== ПЛЕЧИ (5) ====================
      {
        'id': 'ex_default_009',
        'name': 'Жим штанги стоя',
        'description':
        'Жим штанги стоя (армейский жим) — базовое многосуставное упражнение для развития дельт и трицепсов. Выполняется стоя, что требует активной работы кора и стабилизаторов. Армейский жим — это классика для развития силы плечевого пояса и общей силовой подготовки. Он отлично переносится на жимовые движения и помогает укрепить мышцы-стабилизаторы плеча и лопаток. Жим стоя также развивает координацию и учит правильно держать корпус в вертикальной нагрузке. Упражнение отлично сочетается с махами в стороны, разведениями и тягой к подбородку. Это одно из главных упражнений для тех, кто хочет иметь сильные и объёмные плечи. В отличие от жима сидя, здесь нет опоры для спины, поэтому нагрузка на кор и стабилизаторы значительно выше. Это делает упражнение более функциональным, но и более требовательным к технике. Жим стоя часто включают в программы для развития силы верхней части тела, а также в кроссфит и функциональный тренинг. Вариации: с полным жимом (от груди), с паузой на груди, с толчком ногами (пуш-пресс), жим из-за головы (травмоопасно для плеч). Правильная техника с напряжённым кором и нейтральной спиной — ключ к безопасному прогрессу. Для новичков рекомендуется начинать с пустого грифа или лёгких гантелей, чтобы отработать паттерн. Для продвинутых — работа с большими весами, что требует особенно тщательной разминки и страховки.',
        'muscleGroups': '["shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Возьмите штангу хватом чуть шире плеч, стойка на ширине таза.\n'
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
        'commonMistakes':
        '1. Избыточный прогиб в пояснице — травмоопасно.\n'
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
        'description':
        'Махи гантелями в стороны — изолирующее упражнение для средних дельт, создающее визуальную ширину плеч. Средняя дельта — одна из самых сложных для роста мышц, поэтому требует регулярной и точной работы. Махи отлично подходят для добивки в день плеч и для формирования эстетичной линии плеч. Правильная техника с локтями чуть выше кистей и контролем корпуса — ключ к результату. Упражнение требует относительно небольшого веса и внимания к деталям. Махи отлично сочетаются с жимами и разведениями в наклоне. Это одно из самых популярных упражнений в бодибилдинге и фитнесе. Правильное выполнение с акцентом на работу локтями (а не кистями) позволяет изолировать среднюю дельту и избежать включения трапеций. Работа с небольшим весом в диапазоне 12–15 повторений — оптимальный режим для гипертрофии средней дельты. Вариации: стоя, сидя, с наклоном корпуса (акцент на заднюю дельту), в кроссовере (постоянное натяжение), с разворотом кисти (акцент на переднюю дельту). Для новичков — начинать с лёгких весов и отработки техники без веса. Для продвинутых — работа с акцентом на пиковое сокращение и медленный негатив. Махи — упражнение, которое требует терпения: средняя дельта растёт медленно, но при регулярной работе даёт заметный визуальный эффект.',
        'muscleGroups': '["shoulders"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Встаньте ровно, гантели в опущенных руках, стопы на ширине плеч.\n'
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
        'commonMistakes':
        '1. Раскачивание корпусом и рывки — снижает эффект.\n'
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
        'id': 'ex_default_039',
        'name': 'Жим гантелей сидя',
        'description':
        'Жим гантелей сидя — вариант жима над головой с опорой спины на скамью. Прорабатывает передние и средние дельты, трицепсы, при этом снижает нагрузку на поясницу по сравнению с жимом стоя. Гантели позволяют работать в большей амплитуде и комфортнее для плеч. Упражнение подходит и новичкам, и опытным атлетам, легко масштабируется по весу. Жим сидя отлично сочетается с махами и разведениями. Опора спины делает упражнение безопаснее для поясницы и позволяет сконцентрироваться на дельтах. Это одно из базовых упражнений в день плеч. По сравнению с жимом штанги стоя, здесь меньше требований к стабилизаторам, что позволяет работать с более контролируемой техникой и акцентировать дельты. Вариации: с супинацией кистей в верхней точке (акцент на переднюю дельту), с нейтральным хватом (комфорт для плеч), с разворотом кистей (жим Арнольда). Упражнение отлично подходит для людей с проблемами поясницы, поскольку опора спины снимает нагрузку с позвоночника. Для новичков — начинать с лёгких гантелей и отработки техники. Для продвинутых — работа с большими весами и акцентом на пиковое сокращение. Правильная техника с напряжённым кором и контролем амплитуды — ключ к безопасному прогрессу.',
        'muscleGroups': '["shoulders","triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Сядьте на скамью с вертикальной спинкой, прижмите спину и лопатки.\n'
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
        'commonMistakes':
        '1. Прогиб в пояснице — работа переходит на неё.\n'
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
        'description':
        'Махи гантелями в наклоне — изолирующее упражнение для задних дельт, которые часто остаются в тени. Слаборазвитые задние дельты ведут к дисбалансу и ухудшению осанки, поэтому это упражнение важно включать в план. Оно выполняется с наклоном корпуса, что дополнительно включает мышцы-стабилизаторы спины. Правильная техника — залог того, что нагрузка пойдёт в дельты, а не в спину. Махи в наклоне отлично сочетаются с разведениями в кроссовере и жимами. Это одно из ключевых упражнений для баланса развития плеч и профилактики травм. Задняя дельта — одна из самых проблемных зон у большинства атлетов, поскольку она редко получает достаточную нагрузку в базовых упражнениях. Махи в наклоне решают эту проблему. Правильное выполнение с локтями чуть выше кистей и контролем корпуса позволяет изолировать заднюю дельту и избежать включения трапеций и ромбовидных. Вариации: с опорой на скамью (снимает нагрузку с поясницы), с наклоном вперёд (акцент на заднюю дельту), с разворотом кистей (акцент на внешнюю часть задней дельты). Для новичков — начинать с лёгких весов и отработки техники без веса. Для продвинутых — работа с акцентом на пиковое сокращение и медленный негатив. Махи в наклоне — упражнение, которое требует терпения, но при регулярной работе даёт заметный эффект в виде более сбалансированных плеч и улучшенной осанки.',
        'muscleGroups': '["shoulders","back"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Возьмите гантели, наклоните корпус вперёд (примерно до 45°), спина прямая.\n'
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
        'commonMistakes':
        '1. Работа спиной вместо дельт.\n'
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
        'id': 'ex_default_108',
        'name': 'Тяга каната к лицу',
        'description':
        'Тяга каната к лицу (face pull) — упражнение для задних дельт, трапеций и вращательной манжеты плеча. Улучшает осанку и здоровье плеч, поскольку укрепляет мышцы, которые часто остаются слабыми у людей, проводящих много времени за компьютером. Тяга к лицу — одно из лучших профилактических упражнений для плечевых суставов. Оно акцентирует внешние ротаторы плеча, которые отвечают за стабильность сустава и защищают от импинджмента. Упражнение выполняется на блочном тренажёре с канатной рукоятью. Правильная техника с разведением рук в стороны и сведением лопаток позволяет изолировать заднюю дельту и мышцы-стабилизаторы. Тяга к лицу отлично сочетается с обратными разведениями и махами в наклоне. Это упражнение часто включают в разминку перед жимами и в программы для профилактики травм плеч. Вариации: с канатом (классика), с верёвкой, с прямым хватом (акцент на заднюю дельту), с широкой рукоятью. Для новичков — начинать с лёгких весов и отработки техники. Для продвинутых — работа с большими весами и акцентом на пиковое сокращение. Тяга к лицу — упражнение, которое стоит включать в каждую тренировку плеч или верха тела: оно не только развивает задние дельты, но и защищает плечевые суставы от травм.',
        'muscleGroups': '["shoulders","back","traps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Установите блок на уровне лица.\n'
            '2. Возьмите канат нейтральным хватом.\n'
            '3. Тяните канат к лицу, разводя локти в стороны.\n'
            '4. Сводите лопатки и делайте паузу на 1 секунду.\n'
            '5. В конечной точке руки согнуты, локти на уровне плеч.\n'
            '6. Возвращайте контролируемо, растягивая задние дельты.\n'
            '7. Корпус держите стабильным, без раскачивания.\n'
            '8. Плечи не поднимайте к ушам.\n'
            '9. Запястья нейтрально, хват уверенный.\n'
            '10. Дышите: выдох на тяге, вдох на возврате.\n'
            '11. Работайте с весом, который позволяет сделать 12–15 повторений с полным контролем.\n'
            '12. Для акцента на внешние ротаторы держите локти чуть ниже уровня плеч.',
        'commonMistakes':
        '1. Работа только руками, без сведения лопаток.\n'
            '2. Слишком большой вес.\n'
            '3. Рывки.\n'
            '4. Неполная амплитуда.\n'
            '5. Отсутствие паузы в конечной точке.\n'
            '6. Слишком быстрый темп.\n'
            '7. Раскачивание корпусом.\n'
            '8. Слишком высокое или низкое положение блока.\n'
            '9. Работа через боль в плечах.\n'
            '10. Отсутствие разминки.\n'
            '11. Работа без полной амплитуды.\n'
            '12. Работа с максимальными весами без техники.',
        'createdAt': now,
        'updatedAt': now,
      },

      // ==================== НОГИ (8) ====================
      {
        'id': 'ex_default_012',
        'name': 'Приседания со штангой',
        'description':
        'Приседания со штангой — базовое упражнение для ног и всего тела. Прорабатывает квадрицепсы, ягодицы, бицепс бедра, кор и поясницу. Это одно из главных движений в силовых видах спорта и одно из самых эффективных для общего роста силы и массы. Приседания улучшают мобильность, координацию и функциональную силу, которая переносится на повседневную жизнь и спорт. Упражнение требует хорошей техники и контроля нейтральной спины. Приседания отлично сочетаются с жимом ногами, румынской тягой и выпадами. Это одно из главных упражнений для развития ног и ягодиц. Приседания — это «король» упражнений для нижней части тела: они задействуют практически все мышцы ног, а также требуют активной работы кора и спины. Правильная техника с коленями, движущимися в сторону носков, и нейтральной спиной — ключ к безопасному прогрессу. Вариации: классические приседания (со штангой на плечах), фронтальные приседания (штанга на груди, акцент на квадрицепсы), приседания сумо (широкая постановка ног), приседания с паузой (для развития силы в нижней точке). Для новичков рекомендуется начинать с пустого грифа и отработки паттерна. Для продвинутых — работа с большими весами и страховкой. Приседания также являются одним из трёх соревновательных движений в пауэрлифтинге, что дополнительно мотивирует работать над техникой. Исследования показывают, что приседания эффективно стимулируют рост мышц ног и ягодиц, а также улучшают плотность костей и гормональный отклик.',
        'muscleGroups': '["quadriceps","glutes","hamstrings","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Штанга на трапециях, лопатки сведены, хват чуть шире плеч.\n'
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
        'commonMistakes':
        '1. Отрыв пяток — теряется равновесие и нагрузка уходит вперёд.\n'
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
        'description':
        'Жим ногами — упражнение в тренажёре для изоляции квадрицепсов и ягодиц. Минимальная нагрузка на поясницу делает его отличным выбором для новичков и людей с проблемами спины. Позволяет работать с большим весом и безопасно концентрироваться на ногах. Жим ногами хорошо сочетается с приседаниями, разгибаниями и сгибаниями ног в комплексной программе. Упражнение отлично подходит для добивки после приседаний и для изоляции квадрицепсов. Регулируемая амплитуда позволяет безопасно работать даже при ограничениях по коленям. Жим ногами — одно из самых популярных упражнений для ног, поскольку оно позволяет работать с большими весами без нагрузки на поясницу. Правильная техника с коленями, движущимися в сторону носков, и контролем амплитуды — ключ к безопасному прогрессу. Вариации: с узкой постановкой стоп (акцент на квадрицепсы), с широкой постановкой (акцент на ягодицы), с высокой постановкой (акцент на ягодицы), с низкой постановкой (акцент на квадрицепсы), одной ногой (для устранения дисбаланса). Для новичков — начинать с лёгких весов и отработки техники. Для продвинутых — работа с большими весами и акцентом на пиковое сокращение. Жим ногами — упражнение, которое отлично подходит как для массонабора, так и для силовой работы. Оно позволяет безопасно нагружать ноги даже при проблемах с поясницей.',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Сядьте в тренажёр, прижмите спину и таз к спинке.\n'
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
        'commonMistakes':
        '1. Полное выпрямление коленей — травмоопасно.\n'
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
        'description':
        'Выпады с гантелями — функциональное упражнение для ног и ягодиц, которое развивает баланс, координацию и силу каждой ноги отдельно. Хорошо подходит для коррекции мышечного дисбаланса и улучшения стабильности. Выпады также задействуют кор и мышцы-стабилизаторы, что делает их отличным дополнением к приседаниям и жиму ногами. Масштабируются весом и длиной шага. Выпады отлично сочетаются с болгарскими выпадами и зашагиваниями на платформу. Это одно из лучших функциональных упражнений для нижней части тела. Выпады — это одностороннее упражнение, которое акцентирует работу каждой ноги отдельно, что помогает устранить дисбаланс и улучшить координацию. Правильная техника с коленом передней ноги, не выходящим за носок, и вертикальным корпусом — ключ к безопасному прогрессу. Вариации: выпады вперёд, выпады назад (более безопасны для коленей), выпады на месте, выпады с шагом, болгарские выпады (задняя нога на возвышении). Для новичков — начинать с выпадов без веса и отработки техники. Для продвинутых — работа с гантелями, штангой или в комбинации с прыжками. Выпады — упражнение, которое отлично подходит как для гипертрофии ног и ягодиц, так и для функциональной подготовки. Оно также улучшает баланс и координацию, что переносится на повседневную жизнь и спорт.',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Возьмите гантели в опущенные руки, встаньте ровно.\n'
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
        'commonMistakes':
        '1. Наклон корпуса вперёд.\n'
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
        'description':
        'Сгибания ног в тренажёре — изолирующее упражнение для бицепса бедра. Эффективно для проработки задней поверхности бедра и профилактики дисбаланса между квадрицепсом и бицепсом бедра. Слабость бицепса бедра повышает риск травм колена и поясницы, поэтому это упражнение важно включать в план. Тренажёр позволяет безопасно работать с хорошим весом и контролировать амплитуду. Сгибания ног отлично сочетаются с румынской тягой и становой тягой. Это одно из ключевых упражнений для задней поверхности бедра. В отличие от румынской тяги, где акцент на растяжении, здесь акцент на пиковом сокращении в верхней точке. Это делает упражнение идеальным для добивки бицепса бедра. Вариации: лёжа (классика), сидя (акцент на нижнюю часть бицепса бедра), стоя (одной ногой), с паузой в верхней точке (для усиления сокращения). Для новичков — начинать с лёгких весов и отработки техники. Для продвинутых — работа с большими весами и акцентом на пиковое сокращение. Сгибания ног — упражнение, которое стоит включать в каждую тренировку ног: оно не только развивает бицепс бедра, но и защищает колени и поясницу от травм. Регулярная работа над задней поверхностью бедра — это инвестиция в здоровье коленей и поясницы на годы вперёд.',
        'muscleGroups': '["hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Сядьте в тренажёр, таз прижат к сиденью.\n'
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
        'commonMistakes':
        '1. Отрыв таза — перегрузка поясницы.\n'
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
        'description':
        'Подъёмы на носки стоя — базовое упражнение для икроножных мышц. Икры часто отстают из-за генетики и недостаточной амплитуды, поэтому здесь важны полная амплитуда, пауза в верхней точке и медленный негатив. Упражнение можно выполнять со штангой, гантелями или в тренажёре. Регулярная работа над икрами улучшает не только эстетику, но и стабильность голеностопа. Подъёмы на носки отлично сочетаются с подъёмами сидя. Это одно из ключевых упражнений для развития икр. Икроножная мышца состоит из двух головок и работает при прямых коленях, поэтому подъёмы стоя акцентируют именно её. Камбаловидная мышца работает при согнутых коленях, поэтому для её проработки нужны подъёмы сидя. Комбинация этих двух упражнений даёт максимальный эффект для развития икр. Вариации: со штангой на плечах, с гантелями в руках, в тренажёре (стоя или сидя), на одной ноге (для устранения дисбаланса), с паузой в верхней точке (для усиления сокращения). Для новичков — начинать с веса тела и отработки техники. Для продвинутых — работа с большими весами и акцентом на пиковое сокращение. Подъёмы на носки — упражнение, которое требует терпения: икры растут медленно, но при регулярной работе и полной амплитуде дают заметный эффект. Для максимального роста икр работайте в диапазоне 12–20 повторений с паузой в верхней точке.',
        'muscleGroups': '["calves"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Встаньте на платформу так, чтобы пятки свисали.\n'
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
        'commonMistakes':
        '1. Быстрые движения без амплитуды.\n'
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
        'id': 'ex_default_043',
        'name': 'Болгарские выпады',
        'description':
        'Болгарские выпады — одностороннее упражнение с задней ногой на возвышении, которое одно из лучших для ягодиц и квадрицепсов. Требует баланса, координации и активной работы стабилизаторов. Позволяет работать с хорошим весом и концентрироваться на одной стороне. Отлично подходит для коррекции дисбаланса и развития функциональной силы ног. Болгарские выпады отлично сочетаются с обычными выпадами и зашагиваниями на платформу. Это одно из ключевых упражнений для ягодиц и ног. Название «болгарские» происходит от болгарских тяжелоатлетов, которые использовали это упражнение в своей подготовке. Болгарские выпады акцентируют ягодицы и квадрицепсы, при этом требуя активной работы стабилизаторов и кора. Правильная техника с вертикальным корпусом и коленом передней ноги, не выходящим за носок, — ключ к безопасному прогрессу. Вариации: с гантелями (классика), со штангой на плечах, с одной ногой на скамье, с наклоном корпуса вперёд (акцент на ягодицы). Для новичков — начинать без веса и отработки техники. Для продвинутых — работа с большими весами и акцентом на пиковое сокращение. Болгарские выпады — упражнение, которое отлично подходит как для гипертрофии ягодиц и ног, так и для функциональной подготовки. Оно также улучшает баланс и координацию, что переносится на повседневную жизнь и спорт.',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Поставьте одну ногу назад на скамью, передняя нога — опорная.\n'
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
        'commonMistakes':
        '1. Потеря равновесия и наклон корпуса.\n'
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
        'id': 'ex_default_078',
        'name': 'Хип-траст со штангой',
        'description':
        'Хип-траст со штангой — мощное упражнение для ягодиц. Позволяет работать с большим весом, отлично для роста ягодиц. Требует хорошей техники и контроля. Хип-траст отлично сочетается с ягодичным мостом и выпадами. Это одно из ключевых упражнений для ягодиц. Хип-траст — это упражнение, которое изолирует ягодичные мышцы и позволяет работать с большим весом, чем приседания или выпады. Правильная техника с тазом, поднимающимся до полного разгибания, и сжатием ягодиц в верхней точке — ключ к безопасному прогрессу. Вариации: со штангой (классика), с резинкой (для дополнительного сопротивления), на одной ноге (для устранения дисбаланса), с паузой в верхней точке (для усиления сокращения). Для новичков — начинать с ягодичного моста без веса и отработки техники. Для продвинутых — работа с большими весами и акцентом на пиковое сокращение. Хип-траст — упражнение, которое отлично подходит как для гипертрофии ягодиц, так и для силовой работы. Оно позволяет безопасно нагружать ягодицы даже при проблемах с поясницей, если выполняется с правильной техникой. Регулярная работа над ягодицами — это не только эстетика, но и здоровье поясницы и коленей.',
        'muscleGroups': '["glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Лягте на скамью, штанга на бёдрах.\n'
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
        'commonMistakes':
        '1. Переразгибание в пояснице.\n'
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
        'description':
        'Зашагивания на платформу — функциональное упражнение для ног и ягодиц. Развивает баланс и координацию. Отлично для функциональной подготовки. Масштабируется высотой платформы. Зашагивания отлично сочетаются с выпадами и приседаниями. Это одно из ключевых функциональных упражнений для ног. Зашагивания на платформу — это одностороннее упражнение, которое акцентирует работу каждой ноги отдельно, что помогает устранить дисбаланс и улучшить координацию. Правильная техника с вертикальным корпусом и работой передней ноги (без отталкивания задней) — ключ к безопасному прогрессу. Вариации: с гантелями (классика), со штангой на плечах, с одной ногой на платформе, с высокой платформой (акцент на ягодицы), с низкой платформой (акцент на квадрицепс). Для новичков — начинать с низкой платформы без веса. Для продвинутых — работа с большими весами и высокой платформой. Зашагивания — упражнение, которое отлично подходит как для гипертрофии ног и ягодиц, так и для функциональной подготовки. Оно также улучшает баланс и координацию, что переносится на повседневную жизнь и спорт. Регулярная работа над зашагиваниями — это инвестиция в здоровье коленей и поясницы.',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Встаньте перед платформой.\n'
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
        'commonMistakes':
        '1. Потеря равновесия.\n'
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

      // ==================== РУКИ (7) ====================
      {
        'id': 'ex_default_017',
        'name': 'Подъём штанги на бицепс',
        'description':
        'Подъём штанги на бицепс — классическое упражнение для двуглавой мышцы плеча и плечевой мышцы. Одно из самых популярных движений в зале и базовое для развития рук. Правильная техника с прижатыми локтями и контролем корпуса превращает его в мощный стимул для роста бицепса. Подходит для всех уровней подготовки и легко масштабируется. Подъём на бицепс отлично сочетается с молотками, французским жимом и разгибаниями на блоке. Это одно из ключевых упражнений для бицепса. Бицепс — это мышца, которая хорошо отзывается на изоляцию и работу в диапазоне 8–12 повторений с контролем темпа. Правильная техника с фиксированными локтями и полной амплитудой — ключ к росту. Вариации: со штангой (классика), с гантелями, с EZ-грифом (комфортнее для запястий), с прямым грифом (акцент на длинную головку), с узким хватом (акцент на длинную головку), с широким хватом (акцент на короткую головку), на скамье Скотта (для пикового сокращения), концентрированные сгибания. Для новичков — начинать с лёгких весов и отработки техники. Для продвинутых — работа с большими весами и акцентом на пиковое сокращение. Подъём на бицепс — упражнение, которое стоит включать в каждую тренировку рук: оно не только развивает бицепс, но и улучшает силу хвата и общую силовую подготовку.',
        'muscleGroups': '["biceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Возьмите штангу хватом снизу чуть шире плеч.\n'
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
        'commonMistakes':
        '1. Читинг и раскачивание корпусом.\n'
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
        'description':
        'Французский жим — изолирующее упражнение для трицепса, выполняемое из-за головы. Отлично растягивает длинную головку трицепса, которая часто отстаёт при других движениях. Требует фиксации локтей и умеренного веса, чтобы избежать травм локтевых суставов. Хорошо сочетается с жимами и разгибаниями на блоке в день рук. Французский жим отлично подходит для добивки трицепса и для работы над длинной головкой. Это одно из ключевых упражнений для трицепса. Трицепс состоит из трёх головок: длинной, латеральной и медиальной. Французский жим акцентирует длинную головку, которая придаёт трицепсу объём и форму. Правильная техника с фиксированными локтями и контролем амплитуды — ключ к безопасному прогрессу. Вариации: со штангой (классика), с гантелью (комфортнее для локтей), с EZ-грифом (удобный хват), с канатом на блоке (постоянное натяжение), сидя (акцент на длинную головку), лёжа (акцент на все головки). Для новичков — начинать с лёгких весов и отработки техники. Для продвинутых — работа с большими весами и акцентом на растяжение. Французский жим — упражнение, которое стоит включать в каждую тренировку рук: оно не только развивает трицепс, но и улучшает общую силу жимовых движений.',
        'muscleGroups': '["triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Лягте на скамью или сядьте, локти направлены вверх.\n'
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
        'commonMistakes':
        '1. Разведение локтей в стороны.\n'
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
        'description':
        'Молотки — подъём гантелей нейтральным хватом, при котором кисти смотрят друг на друга. Развивает бицепс, плечевую мышцу (brachialis) и предплечья, придавая рукам толщину. Это отличное упражнение для комплексного развития рук, особенно если бицепс уже хорошо отзывается на классические подъёмы. Нейтральный хват комфортнее для запястий. Молотки отлично сочетаются с подъёмом штанги и концентрационными сгибаниями. Это одно из ключевых упражнений для толщины рук. Плечевая мышца (brachialis) лежит под бицепсом и при её развитии она «выталкивает» бицепс вверх, делая руку визуально толще и объёмнее. Молотки — лучшее упражнение для проработки плечевой мышцы. Правильная техника с фиксированными локтями и контролем амплитуды — ключ к безопасному прогрессу. Вариации: стоя (классика), сидя (исключает читинг), с разворотом кисти (акцент на бицепс), поочерёдно (для концентрации), с гантелями или с канатом на блоке. Для новичков — начинать с лёгких весов и отработки техники. Для продвинутых — работа с большими весами и акцентом на пиковое сокращение. Молотки — упражнение, которое стоит включать в каждую тренировку рук: оно не только развивает бицепс и плечевую мышцу, но и укрепляет предплечья и хват, что переносится на все тяговые движения.',
        'muscleGroups': '["biceps","forearms"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Возьмите гантели нейтральным хватом (ладони внутрь).\n'
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
        'commonMistakes':
        '1. Раскачивание корпусом.\n'
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
        'description':
        'Отжимания на брусьях — базовое упражнение с собственным весом для трицепса и груди. При вертикальном корпусе акцент смещается на трицепс, при наклоне вперёд — на грудь. Легко масштабируется дополнительным отягощением или резинкой. Одно из лучших упражнений для трицепса с точки зрения соотношения «эффективность — доступность». Отжимания на брусьях отлично сочетаются с французским жимом и разгибаниями на блоке. Это одно из ключевых упражнений для трицепса. Отжимания на брусьях — это многосуставное упражнение, которое задействует трицепс, грудь и передние дельты. Правильная техника с локтями, прижатыми к корпусу (для акцента на трицепс), и контролем амплитуды — ключ к безопасному прогрессу. Вариации: с вертикальным корпусом (акцент на трицепс), с наклоном вперёд (акцент на грудь), с отягощением на поясе (для продвинутых), с резинкой (для облегчения), на одной руке (для продвинутых). Для новичков — начинать с резинки или тренажёра с противовесом. Для продвинутых — работа с отягощением и акцентом на пиковое сокращение. Отжимания на брусьях — упражнение, которое стоит включать в каждую тренировку рук или груди: оно не только развивает трицепс и грудь, но и улучшает общую силовую подготовку и функциональность. Это одно из лучших упражнений для верха тела с собственным весом.',
        'muscleGroups': '["triceps","chest","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips':
        '1. Возьмитесь за брусья, поднимитесь на прямых руках, плечи опущены.\n'
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
        'commonMistakes':
        '1. Неполная амплитуда.\n'
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
        'id': 'ex_default_046',
        'name': 'Разгибание рук на блоке',
        'description':
        'Разгибание рук на блоке — изолирующее упражнение для трицепса с постоянным натяжением. Блок обеспечивает стабильную траекторию и безопасность для локтей. Отлично подходит как для новичков, так и для опытных атлетов для добивки трицепса. Хорошо сочетается с французским жимом и отжиманиями на брусьях. Разгибание на блоке отлично подходит для работы над формой трицепса. Это одно из ключевых упражнений для трицепса. Постоянное натяжение блока — главное преимущество этого упражнения: в отличие от свободных весов, нагрузка не «проваливается» в верхней и нижней точках. Это делает разгибание на блоке идеальным для добивки трицепса и работы над его формой. Правильная техника с фиксированными локтями и контролем амплитуды — ключ к безопасному прогрессу. Вариации: с прямой рукоятью (акцент на латеральную головку), с канатом (акцент на длинную головку), с верёвкой (комфортнее для запястий), с одной рукой (для концентрации), с наклоном корпуса вперёд (акцент на длинную головку). Для новичков — начинать с лёгких весов и отработки техники. Для продвинутых — работа с большими весами и акцентом на пиковое сокращение. Разгибание на блоке — упражнение, которое стоит включать в каждую тренировку рук: оно не только развивает трицепс, но и улучшает форму рук и общую силовую подготовку.',
        'muscleGroups': '["triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Встаньте у блока, возьмите рукоять хватом сверху.\n'
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
        'commonMistakes':
        '1. Движение плечами.\n'
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
        'id': 'ex_default_082',
        'name': 'Разгибание рук с гантелью из-за головы',
        'description':
        'Разгибание рук с гантелью из-за головы — французский жим с гантелью, выполняемый сидя или стоя. Изолирует трицепс, растягивает длинную головку. Хорошо для формы рук. Масштабируется весом. Разгибание из-за головы отлично сочетается с разгибанием на блоке и французским жимом. Это одно из ключевых упражнений для трицепса. В отличие от французского жима со штангой, гантель позволяет работать в более комфортной для локтей траектории и лучше растягивать длинную головку трицепса. Правильная техника с фиксированными локтями и контролем амплитуды — ключ к безопасному прогрессу. Вариации: сидя (классика), стоя (требует стабильности кора), с одной рукой (для концентрации), с наклоном корпуса вперёд (акцент на длинную головку). Для новичков — начинать с лёгких весов и отработки техники. Для продвинутых — работа с большими весами и акцентом на растяжение. Разгибание из-за головы — упражнение, которое стоит включать в тренировку рук: оно не только развивает трицепс, но и улучшает форму рук и общую силовую подготовку. Регулярная работа над длинной головкой трицепса — это инвестиция в объём и форму рук на годы вперёд.',
        'muscleGroups': '["triceps"]',
        'imageUrl': '',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips':
        '1. Сядьте или встаньте, гантель над головой.\n'
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
        'commonMistakes':
        '1. Разведение локтей.\n'
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
        'id': 'ex_default_084',
        'name': 'Обратные отжимания от скамьи',
        'description':
        'Обратные отжимания от скамьи — упражнение для трицепса с весом тела. Простое и эффективное для дома. Хорошо для начинающих. Масштабируется положением ног. Обратные отжимания отлично сочетаются с французским жимом и разгибанием на блоке. Это одно из ключевых упражнений для трицепса в домашних условиях. Обратные отжимания от скамьи — это упражнение, которое не требует специального оборудования и доступно в любых условиях. Правильная техника с локтями, направленными назад, и контролем амплитуды — ключ к безопасному прогрессу. Вариации: с согнутыми ногами (облегчённый вариант), с прямыми ногами (усложнённый), с ногами на скамье (для продвинутых), с отягощением на бёдрах (для продвинутых), с одной ногой (для баланса). Для новичков — начинать с согнутыми ногами и отработки техники. Для продвинутых — работа с прямыми ногами, отягощением и акцентом на пиковое сокращение. Обратные отжимания — упражнение, которое стоит включать в тренировку рук: оно не только развивает трицепс, но и улучшает общую силовую подготовку. Это одно из лучших упражнений для трицепса в домашних условиях, доступное без оборудования.',
        'muscleGroups': '["triceps","chest"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips':
        '1. Сядьте на край скамьи, руки на скамье чуть шире плеч.\n'
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
        'commonMistakes':
        '1. Локти в стороны — перегрузка плеч.\n'
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

      // ==================== ПРЕСС И КОР (7) ====================
      {
        'id': 'ex_default_021',
        'name': 'Скручивания',
        'description':
        'Скручивания — базовое упражнение для прямых мышц живота. Простое, но эффективное для развития пресса. Правильная техника — скручивание корпуса, а не подъём всего тела. Хорошо подходит для новичков и для разминки перед более сложными упражнениями на пресс. Масштабируется дополнительным весом. Скручивания отлично сочетаются с планкой и подъёмом ног. Это одно из ключевых упражнений для пресса. Прямая мышца живота — это одна мышца, которая идёт от груди до лобка. Скручивания акцентируют её верхнюю часть. Правильная техника с прижатой поясницей и скручиванием корпуса (а не подъёмом всего тела) — ключ к безопасному прогрессу. Вариации: с руками за головой (классика), с руками на груди (для новичков), с отягощением на груди (для продвинутых), на наклонной скамье (для увеличения амплитуды), на блоке (для прогрессии в весе). Для новичков — начинать с 15–20 повторений без веса. Для продвинутых — работа с отягощением и акцентом на пиковое сокращение. Скручивания — упражнение, которое стоит включать в каждую тренировку пресса: оно не только развивает прямую мышцу живота, но и улучшает общую стабильность кора. Регулярная работа над прессом — это не только эстетика, но и здоровье поясницы.',
        'muscleGroups': '["abs"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips':
        '1. Лягте на спину, ноги согнуты, стопы на полу.\n'
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
        'commonMistakes':
        '1. Рывки и работа шеей.\n'
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
        'description':
        'Планка — статическое упражнение для кора, которое укрепляет мышцы живота, спины и стабилизаторы. Одно из самых эффективных и доступных упражнений для укрепления центра тела. Улучшает осанку и снижает риск травм поясницы. Легко масштабируется временем удержания и усложнёнными вариантами (боковая планка, планка с подъёмом руки и т.д.). Планка отлично сочетается со скручиваниями и подъёмом ног. Это одно из ключевых упражнений для кора. Планка — это изометрическое упражнение, которое тренирует мышцы кора в статическом режиме. Она задействует прямую мышцу живота, косые мышцы, поперечную мышцу живота, мышцы-разгибатели спины и ягодицы. Правильная техника с прямой линией тела и напряжённым кором — ключ к безопасному прогрессу. Вариации: классическая планка на предплечьях, планка на прямых руках, боковая планка, планка с подъёмом руки/ноги, планка на нестабильной опоре. Для новичков — начинать с 20–30 секунд и отработки техники. Для продвинутых — работа с усложнёнными вариантами и удержанием 60+ секунд. Планка — упражнение, которое стоит включать в каждую тренировку: оно не только укрепляет кор, но и улучшает осанку и снижает риск травм поясницы. Регулярная работа над кором — это инвестиция в здоровье спины на годы вперёд.',
        'muscleGroups': '["abs","obliques","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'defaultFormat': 'hold',
        'techniqueTips':
        '1. Примите упор на предплечья и носки.\n'
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
        'commonMistakes':
        '1. Провисание в пояснице.\n'
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
        'description':
        'Подъём ног в висе — сложное упражнение для нижнего пресса, требующее силы хвата и контроля кора. Одно из самых эффективных для нижней части живота. Выполняется на перекладине или в висе на брусьях. Масштабируется сгибанием коленей (облегчённый вариант). Подъём ног в висе отлично сочетается со скручиваниями и планкой. Это одно из ключевых упражнений для нижнего пресса. Нижняя часть прямой мышцы живота — это зона, которая часто отстаёт при обычных скручиваниях. Подъём ног в висе акцентирует именно её. Правильная техника с работой пресса (а не сгибателей бедра) и контролем амплитуды — ключ к безопасному прогрессу. Вариации: с согнутыми коленями (облегчённый вариант), с прямыми ногами (усложнённый), с отягощением (для продвинутых), на брусьях (с опорой на предплечья). Для новичков — начинать с согнутых коленей и отработки техники. Для продвинутых — работа с прямыми ногами и отягощением. Подъём ног в висе — упражнение, которое стоит включать в тренировку пресса: оно не только развивает нижний пресс, но и улучшает силу хвата и общую стабильность кора. Регулярная работа над нижним прессом — это инвестиция в эстетику и здоровье поясницы.',
        'muscleGroups': '["abs","obliques"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips':
        '1. Повисните на перекладине, хват чуть шире плеч.\n'
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
        'commonMistakes':
        '1. Раскачивание.\n'
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
        'description':
        'Боковая планка — статическое упражнение для косых мышц живота и стабильности кора. Укрепляет боковые мышцы, улучшает баланс и снижает риск травм поясницы. Отлично дополняет классическую планку и скручивания. Легко масштабируется временем удержания. Боковая планка отлично сочетается со скручиваниями и русским твистом. Это одно из ключевых упражнений для косых мышц. Боковая планка — это изометрическое упражнение, которое тренирует косые мышцы живота, квадратную мышцу поясницы и стабилизаторы плеча. Правильная техника с прямой линией тела и опорой на локоть под плечом — ключ к безопасному прогрессу. Вариации: классическая боковая планка на предплечье, боковая планка на прямой руке, боковая планка с подъёмом верхней ноги, боковая планка с поворотом корпуса (для продвинутых). Для новичков — начинать с 20–30 секунд и отработки техники. Для продвинутых — работа с усложнёнными вариантами и удержанием 60+ секунд. Боковая планка — упражнение, которое стоит включать в тренировку кора: оно не только укрепляет косые мышцы, но и улучшает баланс и стабильность, что переносится на все функциональные движения.',
        'muscleGroups': '["obliques","abs","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'defaultFormat': 'hold',
        'isCustom': 0,
        'techniqueTips':
        '1. Лягте на бок, опора на локоть под плечом.\n'
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
        'commonMistakes':
        '1. Провисание таза.\n'
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
        'id': 'ex_default_087',
        'name': 'Велосипед',
        'description':
        'Велосипед — скручивания с попеременным движением ног. Прорабатывает прямые и косые мышцы живота. Простое и эффективное. Масштабируется темпом. Велосипед отлично сочетается со скручиваниями и планкой. Это одно из ключевых упражнений для пресса и косых мышц. «Велосипед» — это динамическое упражнение, которое одновременно тренирует прямую и косые мышцы живота. Правильная техника с прижатой поясницей и медленным темпом — ключ к безопасному прогрессу. Вариации: с медленным темпом (акцент на контроль), с паузой в верхней точке (для усиления сокращения), с отягощением (для продвинутых), с подъёмом ног выше (для увеличения нагрузки). Для новичков — начинать с медленного темпа и отработки техники. Для продвинутых — работа с отягощением и акцентом на пиковое сокращение. «Велосипед» — упражнение, которое стоит включать в тренировку пресса: оно не только развивает пресс и косые мышцы, но и улучшает координацию и общую стабильность кора. Регулярная работа над прессом — это не только эстетика, но и здоровье поясницы.',
        'muscleGroups': '["abs","obliques"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips':
        '1. Лягте на спину, руки за головой.\n'
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
        'commonMistakes':
        '1. Работа шеей.\n'
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
        'id': 'ex_default_089',
        'name': 'Альпинист',
        'description':
        'Альпинист (mountain climbers) — динамическое упражнение на кор и кардио. Отлично сочетает статику и динамику. Хорошо для HIIT. Масштабируется темпом. Альпинист отлично сочетается с берпи и планкой. Это одно из ключевых функциональных упражнений для кора. «Альпинист» — это упражнение, которое одновременно тренирует кор, плечи и кардио. Правильная техника с прямой линией тела и контролем темпа — ключ к безопасному прогрессу. Вариации: с медленным темпом (акцент на контроль), с быстрым темпом (акцент на кардио), с перекрёстным подтягиванием колена (акцент на косые мышцы), с прыжком (для продвинутых). Для новичков — начинать с медленного темпа и отработки техники. Для продвинутых — работа с быстрым темпом и усложнёнными вариантами. «Альпинист» — упражнение, которое стоит включать в тренировку кора или HIIT: оно не только развивает кор, но и улучшает кардио и общую функциональность. Это одно из лучших упражнений для комплексной тренировки тела без оборудования.',
        'muscleGroups': '["abs","cardio_vascular","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips':
        '1. Примите упор лёжа.\n'
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
        'commonMistakes':
        '1. Провисание таза.\n'
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
        'description':
        'Ролик для пресса — мощное упражнение для всего кора. Требует силы и контроля. Отлично для продвинутых. Масштабируется амплитудой. Ролик отлично сочетается с планкой и скручиваниями. Это одно из ключевых упражнений для кора. Ролик для пресса — это упражнение, которое одновременно тренирует прямую мышцу живота, косые мышцы, поперечную мышцу, мышцы-разгибатели спины и плечевой пояс. Правильная техника с нейтральной спиной и контролем амплитуды — ключ к безопасному прогрессу. Вариации: с колен (классика), стоя (для продвинутых), с опорой на стену (для новичков), с резинкой (для облегчения). Для новичков — начинать с короткого выката и отработки техники. Для продвинутых — работа с полной амплитудой и усложнёнными вариантами. Ролик для пресса — упражнение, которое стоит включать в тренировку кора: оно не только развивает кор, но и улучшает общую стабильность и функциональность. Это одно из лучших упражнений для комплексной тренировки кора, доступное без сложного оборудования.',
        'muscleGroups': '["abs","obliques","lowerBack"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips':
        '1. Встаньте на колени, ролик перед собой.\n'
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
        'commonMistakes':
        '1. Прогиб в пояснице.\n'
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

      // ==================== КАРДИО (6) ====================
      {
        'id': 'ex_default_024',
        'name': 'Бег на дорожке',
        'description':
        'Бег на дорожке — классическое кардио для сжигания калорий и укрепления сердечно-сосудистой системы. Легко регулировать темп, наклон и продолжительность. Подходит для любого уровня подготовки. Регулярный бег улучшает выносливость, работу сердца и общее самочувствие. Бег отлично сочетается с силовыми тренировками и йогой. Это одно из самых популярных кардио-упражнений. Бег на дорожке — это контролируемое кардио, которое позволяет точно дозировать нагрузку и отслеживать прогресс. Правильная техника с постановкой стопы с пятки на носок и ровным дыханием — ключ к безопасному прогрессу. Вариации: равномерный бег, интервальный бег (чередование спринта и ходьбы), бег в гору (с наклоном), бег с ускорениями. Для новичков — начинать с ходьбы и постепенно переходить к бегу. Для продвинутых — работа с интервалами и наклоном. Бег на дорожке — упражнение, которое стоит включать в программу для кардио и жиросжигания: оно не только улучшает работу сердца, но и повышает общую выносливость и сжигает калории. Регулярный бег — это инвестиция в здоровье сердца и сосудов на годы вперёд. При этом важно следить за пульсом и не перегружать себя, особенно на начальном этапе.',
        'muscleGroups': '["cardio_vascular","quadriceps","calves"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips':
        '1. Начните с разминки 5 минут ходьбы.\n'
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
        'commonMistakes':
        '1. Слишком быстрый старт.\n'
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
        'description':
        'Велотренажёр — кардио с низкой нагрузкой на суставы. Отлично подходит для сжигания жира и укрепления сердца, безопасно для коленей и поясницы. Легко регулировать сопротивление и темп. Хорошо подходит для интервальных тренировок и для восстановления. Велотренажёр отлично сочетается с силовыми тренировками. Это одно из самых безопасных кардио-упражнений. Велотренажёр — это кардио с минимальной ударной нагрузкой на суставы, что делает его идеальным для людей с проблемами коленей или поясницы, а также для восстановления после травм. Правильная техника с отрегулированной высотой сиденья и ровным темпом — ключ к безопасному прогрессу. Вариации: равномерное педалирование, интервальное педалирование (чередование высокой и низкой интенсивности), педалирование с высокой нагрузкой (для силы ног), педалирование с низкой нагрузкой (для восстановления). Для новичков — начинать с низкого сопротивления и постепенно увеличивать. Для продвинутых — работа с интервалами и высоким сопротивлением. Велотренажёр — упражнение, которое стоит включать в программу для кардио и жиросжигания: оно не только улучшает работу сердца, но и безопасно для суставов. Регулярная работа на велотренажёре — это инвестиция в здоровье сердца и сосудов на годы вперёд.',
        'muscleGroups': '["cardio_vascular","quadriceps","glutes"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips':
        '1. Отрегулируйте высоту сиденья: нога почти прямая в нижней точке.\n'
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
        'commonMistakes':
        '1. Слишком низкое сиденье.\n'
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
        'description':
        'Плавание — кардио на всё тело с минимальной нагрузкой на суставы. Отлично развивает выносливость, укрепляет мышцы и улучшает работу сердечно-сосудистой системы. Подходит для людей с ограничениями по суставам и для восстановления после травм. Требует базовой техники. Плавание отлично сочетается с силовыми тренировками и йогой. Это одно из самых полезных кардио-упражнений. Плавание — это уникальное кардио, которое одновременно тренирует сердечно-сосудистую систему и все основные группы мышц, при этом минимально нагружая суставы. Правильная техника дыхания и гребка — ключ к безопасному прогрессу. Вариации: кроль (классика), брасс, спина, баттерфляй (для продвинутых), свободное плавание (для восстановления). Для новичков — начинать с брасса и свободного плавания. Для продвинутых — работа с интервалами и разными стилями. Плавание — упражнение, которое стоит включать в программу для кардио и восстановления: оно не только улучшает работу сердца, но и безопасно для суставов, а также развивает все группы мышц. Регулярное плавание — это инвестиция в здоровье сердца, сосудов и суставов на годы вперёд.',
        'muscleGroups': '["cardio_vascular","fullBody"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips':
        '1. Начните с разминки в воде.\n'
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
        'commonMistakes':
        '1. Задержка дыхания.\n'
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
        'description':
        'Прыжки на скакалке — эффективное кардио для всего тела. Развивает выносливость, координацию и силу ног. Доступно в любых условиях и не требует много места. Хорошо подходит для разминки и для интервальных тренировок. Прыжки на скакалке отлично сочетаются с силовыми тренировками и HIIT. Это одно из самых эффективных кардио-упражнений. Прыжки на скакалке — это кардио, которое одновременно тренирует сердечно-сосудистую систему, координацию, силу ног и выносливость. Правильная техника с мягким приземлением и вращением кистями (а не плечами) — ключ к безопасному прогрессу. Вариации: обычные прыжки, двойные прыжки (для продвинутых), прыжки с высокими коленями (акцент на кардио), прыжки с перекрёстным движением рук (для координации), прыжки на одной ноге (для баланса). Для новичков — начинать с 30 секунд и постепенно увеличивать. Для продвинутых — работа с интервалами и усложнёнными техниками. Прыжки на скакалке — упражнение, которое стоит включать в программу для кардио и жиросжигания: оно не только улучшает работу сердца, но и развивает координацию и силу ног. Это одно из самых эффективных кардио-упражнений для сжигания калорий.',
        'muscleGroups': '["cardio_vascular","calves","shoulders"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips':
        '1. Возьмите скакалку правильно: локти близко к корпусу.\n'
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
        'commonMistakes':
        '1. Сильное приземление.\n'
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
      {
        'id': 'ex_default_058',
        'name': 'Берпи',
        'description':
        'Берпи — комплексное функциональное упражнение, сочетающее присед, отжимание и прыжок. Развивает взрывную силу, выносливость и сжигает много калорий. Одно из лучших упражнений для HIIT. Требует базовой физической подготовки. Берпи отлично сочетается с другими HIIT-упражнениями. Это одно из самых эффективных функциональных упражнений. Берпи — это упражнение, которое одновременно тренирует всё тело: ноги, грудь, плечи, кор и сердечно-сосудистую систему. Правильная техника с контролем на каждом этапе (присед, упор лёжа, отжимание, возврат, прыжок) — ключ к безопасному прогрессу. Вариации: классические берпи, берпи без отжимания (облегчённый), берпи с прыжком (усложнённый), берпи с одной ногой (для баланса), берпи с отягощением (для продвинутых). Для новичков — начинать с медленного темпа и без отжимания. Для продвинутых — работа с прыжком и усложнёнными вариантами. Берпи — упражнение, которое стоит включать в HIIT-тренировки: оно не только развивает взрывную силу и выносливость, но и сжигает много калорий. Это одно из самых эффективных упражнений для комплексной тренировки тела без оборудования.',
        'muscleGroups': '["fullBody","cardio_vascular","chest","quadriceps"]',
        'imageUrl': '',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips':
        '1. Из стойки присядьте и поставьте ладони на пол.\n'
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
        'commonMistakes':
        '1. Рывки.\n'
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
        'id': 'ex_default_091',
        'name': 'Гребля на тренажёре',
        'description':
        'Гребля на тренажёре — кардио на всё тело. Минимальная нагрузка на суставы. Отличная тренировка спины. Хорошо для кардио и функционала. Масштабируется темпом. Гребля отлично сочетается с силовыми тренировками и плаванием. Это одно из самых эффективных кардио-упражнений. Гребля на тренажёре — это уникальное кардио, которое одновременно тренирует сердечно-сосудистую систему и все основные группы мышц (спина, ноги, кор, руки), при этом минимально нагружая суставы. Правильная техника с последовательностью «ноги-корпус-руки» — ключ к безопасному прогрессу. Вариации: равномерная гребля, интервальная гребля (чередование высокой и низкой интенсивности), гребля с акцентом на ноги, гребля с акцентом на спину. Для новичков — начинать с медленного темпа и отработки техники. Для продвинутых — работа с интервалами и акцентом на мощность. Гребля — упражнение, которое стоит включать в программу для кардио и функционала: оно не только улучшает работу сердца, но и тренирует всё тело без нагрузки на суставы. Регулярная гребля — это инвестиция в здоровье сердца, сосудов и суставов на годы вперёд.',
        'muscleGroups': '["cardio_vascular","back","quadriceps"]',
        'imageUrl': '',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips':
        '1. Сядьте в тренажёр.\n'
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
        'commonMistakes':
        '1. Работа только руками.\n'
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

      // ==================== БОКС (2) ====================
      {
        'id': 'ex_default_027',
        'name': 'Работа на груше',
        'description':
        'Работа на груше — ударная тренировка, развивающая координацию, взрывную силу и выносливость. Отлично подходит для кардио и функциональной подготовки. Улучшает технику ударов и работу ног. Доступно в любом зале с грушей. Работа на груше отлично сочетается с боем с тенью и кардио. Это одно из ключевых упражнений в боксе и фитнесе. Работа на груше — это уникальное упражнение, которое одновременно тренирует сердечно-сосудистую систему, координацию, взрывную силу и технику ударов. Правильная техника с работой ног и контролем дистанции — ключ к безопасному прогрессу. Вариации: работа на тяжёлой груше (акцент на силу), работа на скоростной груше (акцент на скорость), работа на пневмогруше (акцент на точность), работа на груше с комбинациями (акцент на технику). Для новичков — начинать с медленного темпа и отработки техники. Для продвинутых — работа с комбинациями и высокой интенсивностью. Работа на груше — упражнение, которое стоит включать в программу для кардио и функциональной подготовки: оно не только улучшает работу сердца, но и развивает координацию и взрывную силу. Это одно из самых эффективных упражнений для комплексной тренировки тела и боевых навыков.',
        'muscleGroups': '["shoulders","back","abs","fullBody"]',
        'imageUrl': '',
        'exerciseType': 'boxing',
        'isCustom': 0,
        'techniqueTips':
        '1. Руки у подбородка, стойка боксёрская.\n'
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
        'commonMistakes':
        '1. Опускание рук.\n'
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
        'description':
        'Бой с тенью — имитация боя без снаряда, развивающая координацию, технику и выносливость. Отлично подходит для разминки и кардио-сессий. Позволяет отрабатывать комбинации и работу ног без риска травмы. Не требует оборудования. Бой с тенью отлично сочетается с работой на груше и кардио. Это одно из ключевых упражнений в боксе и фитнесе. Бой с тенью — это упражнение, которое одновременно тренирует технику, координацию, выносливость и работу ног. Правильная техника с движением на носках и контролем рук у подбородка — ключ к безопасному прогрессу. Вариации: бой с тенью в медленном темпе (акцент на технику), бой с тенью в быстром темпе (акцент на выносливость), бой с тенью с гантелями (акцент на силу плеч), бой с тенью с комбинациями (акцент на координацию). Для новичков — начинать с медленного темпа и отработки техники. Для продвинутых — работа с высокой интенсивностью и сложными комбинациями. Бой с тенью — упражнение, которое стоит включать в программу для кардио и функциональной подготовки: оно не только улучшает работу сердца, но и развивает координацию и технику. Это одно из самых доступных упражнений для комплексной тренировки тела и боевых навыков — оно не требует оборудования и может выполняться в любом месте.',
        'muscleGroups': '["shoulders","fullBody","cardio_vascular"]',
        'imageUrl': '',
        'exerciseType': 'boxing',
        'isCustom': 0,
        'techniqueTips':
        '1. Двигайтесь на носках.\n'
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
        'commonMistakes':
        '1. Статичность.\n'
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

      // ==================== ЙОГА И РАСТЯЖКА (2) ====================
      {
        'id': 'ex_default_029',
        'name': 'Растяжка всего тела',
        'description':
        'Растяжка всего тела — комплекс упражнений на гибкость и расслабление. Подходит для завершения тренировки или отдельной сессии. Улучшает подвижность, снижает риск травм и помогает восстановлению. Особенно важно после силовых и кардио-тренировок. Растяжка отлично сочетается с йогой и медитацией. Это одно из ключевых упражнений для восстановления. Растяжка всего тела — это комплексное упражнение, которое одновременно улучшает гибкость, подвижность суставов, снижает риск травм и помогает восстановлению после тренировок. Правильная техника с медленным входом в каждое положение, ровным дыханием и удержанием 20–30 секунд — ключ к безопасному прогрессу. Вариации: динамическая растяжка (перед тренировкой), статическая растяжка (после тренировки), миофасциальный релиз (с роллом), йога (комплексный подход). Для новичков — начинать с 5–10 минут и постепенно увеличивать. Для продвинутых — работа с более сложными положениями и длительным удержанием. Растяжка — упражнение, которое стоит включать в каждую тренировку: оно не только улучшает гибкость, но и снижает риск травм и помогает восстановлению. Регулярная растяжка — это инвестиция в здоровье суставов и мышц на годы вперёд.',
        'muscleGroups': '["flexibility","fullBody"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips':
        '1. Дышите глубоко и ровно.\n'
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
        'commonMistakes':
        '1. Пружинистые движения.\n'
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
        'description':
        'Собака мордой вниз — классическая асана йоги, которая растягивает и укрепляет всё тело, особенно спину, плечи, заднюю поверхность бедра и икры. Улучшает кровообращение и снимает напряжение. Подходит для любого уровня, легко модифицируется. Собака мордой вниз отлично сочетается с другими асанами йоги. Это одна из самых популярных асан в йоге. Собака мордой вниз — это асана, которая одновременно растягивает заднюю цепь (спина, бицепс бедра, икры) и укрепляет плечи, руки и кор. Правильная техника с прямой спиной, пятками к полу (или с согнутыми коленями) и расслабленной шеей — ключ к безопасному прогрессу. Вариации: классическая собака мордой вниз, с согнутыми коленями (для новичков), на носках (для растяжки икр), с опорой на блоки (для продвинутых). Для новичков — начинать с согнутых коленей и отработки техники. Для продвинутых — работа с прямыми ногами и более глубоким растяжением. Собака мордой вниз — асана, которую стоит включать в тренировку йоги или растяжки: она не только улучшает гибкость, но и снимает напряжение и улучшает кровообращение. Это одна из самых универсальных асан йоги, доступная для любого уровня подготовки.',
        'muscleGroups': '["flexibility","shoulders","hamstrings","calves"]',
        'imageUrl': '',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips':
        '1. Встаньте на четвереньки, ладони под плечами.\n'
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
        'commonMistakes':
        '1. Округление спины.\n'
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
    debugPrint('✅ Добавлено $inserted новых упражнений (всего дефолтных: 50)');

    // Гарантируем defaultFormat для всех
    try {
      final rowsToFix = await db.query(
        'exercises',
        where: "isCustom = 0 AND (defaultFormat IS NULL OR defaultFormat = '')",
      );
      if (rowsToFix.isNotEmpty) {
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
          } catch (e) {
            debugPrint('  ⚠️ $id: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка пост-обработки defaultFormat: $e');
    }

    // Изображения
    try {
      final imgCount = await applyDefaultExerciseImages(db);
      debugPrint('🖼️ Изображения для $imgCount упражнений');
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
          [1, ['ex_default_001', 'ex_default_002', 'ex_default_032', 'ex_default_020'], false],
          [2, ['ex_default_005', 'ex_default_006', 'ex_default_017', 'ex_default_035'], false],
          [3, ['ex_default_012', 'ex_default_013', 'ex_default_014', 'ex_default_015'], false],
          [4, ['ex_default_031', 'ex_default_034', 'ex_default_002', 'ex_default_082'], false],
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
          [2, ['ex_default_010', 'ex_default_040', 'ex_default_019', 'ex_default_082'], false],
          [3, ['ex_default_012', 'ex_default_015', 'ex_default_016', 'ex_default_042'], false],
          [4, ['ex_default_008', 'ex_default_005', 'ex_default_017', 'ex_default_038'], false],
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
          [4, ['ex_default_016', 'ex_default_014', 'ex_default_024', 'ex_default_015'], false],
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
          [3, ['ex_default_026', 'ex_default_029', 'ex_default_030', 'ex_default_089'], false],
          [4, ['ex_default_024', 'ex_default_027', 'ex_default_020', 'ex_default_054'], false],
          [5, ['ex_default_030', 'ex_default_022', 'ex_default_023', 'ex_default_029'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_006', 'name': 'Бицепс и трицепс', 'type': 'weekly', 'category': 'arms', 'recommendedLevel': 'intermediate',
        'description': 'Специализированная программа для рук. Бицепс + трицепс 2 раза в неделю.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_017', 'ex_default_018', 'ex_default_019', 'ex_default_046', 'ex_default_082'], false],
          [2, ['ex_default_001', 'ex_default_005', 'ex_default_012', 'ex_default_021'], false],
          [3, ['ex_default_017', 'ex_default_019', 'ex_default_020', 'ex_default_082'], false],
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
          [1, ['ex_default_009', 'ex_default_010', 'ex_default_039', 'ex_default_040'], false],
          [2, ['ex_default_001', 'ex_default_006', 'ex_default_012', 'ex_default_021'], false],
          [3, ['ex_default_009', 'ex_default_010', 'ex_default_040', 'ex_default_108'], false],
          [4, ['ex_default_002', 'ex_default_005', 'ex_default_013', 'ex_default_022'], false],
          [5, ['ex_default_039', 'ex_default_009', 'ex_default_010', 'ex_default_040'], false],
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
          [5, ['ex_default_024', 'ex_default_014', 'ex_default_019', 'ex_default_022', 'ex_default_089'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_009', 'name': 'Набор массы', 'type': 'weekly', 'category': 'hypertrophy', 'recommendedLevel': 'advanced',
        'description': 'Программа для увеличения мышечной массы. Высокий объём и интенсивность.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_001', 'ex_default_002', 'ex_default_032', 'ex_default_020', 'ex_default_082'], false],
          [2, ['ex_default_008', 'ex_default_005', 'ex_default_006', 'ex_default_007', 'ex_default_035'], false],
          [3, ['ex_default_012', 'ex_default_013', 'ex_default_014', 'ex_default_015', 'ex_default_043'], false],
          [4, ['ex_default_031', 'ex_default_032', 'ex_default_034', 'ex_default_004', 'ex_default_020'], false],
          [5, ['ex_default_005', 'ex_default_038', 'ex_default_035', 'ex_default_006', 'ex_default_017'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_010', 'name': 'Йога и гибкость', 'type': 'weekly', 'category': 'yoga', 'recommendedLevel': 'beginner',
        'description': 'Комплекс на развитие гибкости и восстановление. Йога, пилатес, стретчинг.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_029', 'ex_default_030', 'ex_default_021', 'ex_default_022', 'ex_default_051'], false],
          [2, ['ex_default_030', 'ex_default_051', 'ex_default_022', 'ex_default_089'], false],
          [3, ['ex_default_029', 'ex_default_030', 'ex_default_021', 'ex_default_022', 'ex_default_051'], false],
          [4, ['ex_default_030', 'ex_default_051', 'ex_default_022', 'ex_default_090'], false],
          [5, ['ex_default_029', 'ex_default_030', 'ex_default_021', 'ex_default_051'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_011', 'name': 'Full Body для начинающих', 'type': 'weekly', 'category': 'beginner', 'recommendedLevel': 'beginner',
        'description': 'Три полноценные тренировки на всё тело в неделю. Идеально для старта.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_012', 'ex_default_001', 'ex_default_005', 'ex_default_021'], false],
          [2, [], true],
          [3, ['ex_default_013', 'ex_default_007', 'ex_default_004', 'ex_default_022'], false],
          [4, [], true],
          [5, ['ex_default_014', 'ex_default_010', 'ex_default_019', 'ex_default_020'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_012', 'name': 'Сплит: Спина + Бицепс', 'type': 'weekly', 'category': 'back', 'recommendedLevel': 'intermediate',
        'description': 'Классический сплит. Спина и бицепс дважды в неделю.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_005', 'ex_default_006', 'ex_default_007', 'ex_default_035', 'ex_default_017'], false],
          [2, ['ex_default_012', 'ex_default_013', 'ex_default_015', 'ex_default_016'], false],
          [3, ['ex_default_001', 'ex_default_009', 'ex_default_020', 'ex_default_021'], false],
          [4, ['ex_default_008', 'ex_default_006', 'ex_default_038', 'ex_default_035', 'ex_default_018'], false],
          [5, ['ex_default_010', 'ex_default_040', 'ex_default_108', 'ex_default_022'], false],
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
          [4, ['ex_default_002', 'ex_default_082', 'ex_default_032', 'ex_default_046', 'ex_default_019'], false],
          [5, ['ex_default_009', 'ex_default_010', 'ex_default_039', 'ex_default_040'], false],
          [6, [], true],
          [7, [], true],
        ])),
      },
      {
        'id': 'tpl_014', 'name': 'HIIT жиросжигание', 'type': 'weekly', 'category': 'hiit', 'recommendedLevel': 'intermediate',
        'description': 'Высокоинтенсивные интервальные тренировки. 4 сессии в неделю по 25-30 минут.',
        'days': jsonEncode(_createTemplateDays(uuid, [
          [1, ['ex_default_058', 'ex_default_089', 'ex_default_087', 'ex_default_054'], false],
          [2, ['ex_default_054', 'ex_default_087', 'ex_default_089', 'ex_default_058'], false],
          [3, [], true],
          [4, ['ex_default_058', 'ex_default_089', 'ex_default_087', 'ex_default_054'], false],
          [5, ['ex_default_087', 'ex_default_054', 'ex_default_089', 'ex_default_058'], false],
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