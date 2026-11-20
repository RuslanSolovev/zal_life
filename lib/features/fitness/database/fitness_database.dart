import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/enums.dart';

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
        final formatUpdates = <String, String>{
          'ex_default_022': 'hold',
          'ex_default_051': 'hold',
          'ex_default_054': 'timedSets',
          'ex_default_089': 'timedSets',
          'ex_default_108': 'timedSets',
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
        debugPrint('🔧 v19: изображения стандартным (устарело, используется syncExerciseImages)');
      }
      if (oldVersion < 20) {
        debugPrint('🔧 v20: локальные assets (устарело, используется syncExerciseImages)');
      }
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
      {
        'id': 'ex_default_001',
        'name': 'Жим штанги лёжа',
        'description': 'Жим штанги лёжа — фундаментальное многосуставное упражнение...',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': 'assets/exercise_presets/1.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на скамью...',
        'commonMistakes': '1. Отрыв таза от скамьи...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_002',
        'name': 'Жим гантелей лёжа',
        'description': 'Жим гантелей лёжа — важное многосуставное упражнение...',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': 'assets/exercise_presets/zim_gantelei_leoja.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите гантели...',
        'commonMistakes': '1. Слишком большой вес...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_004',
        'name': 'Отжимания от пола',
        'description': 'Отжимания от пола — базовое упражнение с собственным весом...',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': 'assets/exercise_presets/otjimanie.jpg',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Примите упор лёжа...',
        'commonMistakes': '1. Провисание поясницы...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_031',
        'name': 'Жим гантелей на наклонной скамье',
        'description': 'Жим гантелей на наклонной скамье (30–45°) переносит акцент...',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': 'assets/exercise_presets/zim_gantelei_sidy.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Установите наклон скамьи...',
        'commonMistakes': '1. Слишком большой наклон...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_034',
        'name': 'Жим штанги на наклонной скамье',
        'description': 'Жим штанги на наклонной скамье — многосуставное упражнение...',
        'muscleGroups': '["chest","shoulders","triceps"]',
        'imageUrl': 'assets/exercise_presets/zim_htangi_na_naklonnoi.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Установите наклон скамьи...',
        'commonMistakes': '1. Слишком большой вес...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_032',
        'name': 'Сведение рук в кроссовере',
        'description': 'Сведение рук в кроссовере — изолирующее упражнение для грудных...',
        'muscleGroups': '["chest","shoulders"]',
        'imageUrl': 'assets/exercise_presets/svedenie_ruk_v_krosovere.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Установите блоки...',
        'commonMistakes': '1. Использование инерции...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_005',
        'name': 'Подтягивания',
        'description': 'Подтягивания — базовое упражнение с собственным весом...',
        'muscleGroups': '["back","biceps","lats"]',
        'imageUrl': 'assets/exercise_presets/podtygivanie.jpg',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Возьмитесь за перекладину...',
        'commonMistakes': '1. Раскачивание и рывки...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_006',
        'name': 'Тяга штанги в наклоне',
        'description': 'Тяга штанги в наклоне — мощное многосуставное упражнение...',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': 'assets/exercise_presets/tyaga_htangi_v_naklone.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу...',
        'commonMistakes': '1. Округление спины...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_007',
        'name': 'Тяга верхнего блока',
        'description': 'Тяга верхнего блока — аналог подтягиваний на тренажёре...',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': 'assets/exercise_presets/tyga_verhnego_bloka.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте, зафиксируйте бёдра...',
        'commonMistakes': '1. Сильное отклонение корпуса...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_008',
        'name': 'Становая тяга',
        'description': 'Становая тяга — «король» упражнений...',
        'muscleGroups': '["back","glutes","hamstrings","lowerBack","traps"]',
        'imageUrl': 'assets/exercise_presets/10.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Штанга на полу...',
        'commonMistakes': '1. Округление спины...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_035',
        'name': 'Тяга горизонтального блока сидя',
        'description': 'Тяга горизонтального блока сидя — упражнение для проработки...',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': 'assets/exercise_presets/tyga_gorizontalnogo_bloka.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте, упритесь стопами...',
        'commonMistakes': '1. Раскачивание корпусом...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_038',
        'name': 'Тяга гантели к поясу',
        'description': 'Тяга гантели к поясу с опорой на скамью...',
        'muscleGroups': '["back","lats","biceps"]',
        'imageUrl': 'assets/exercise_presets/tyga_ganteli_k_poesy.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Поставьте одну ногу и руку...',
        'commonMistakes': '1. Скручивание корпуса...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_042',
        'name': 'Румынская тяга',
        'description': 'Румынская тяга — упражнение для бицепса бедра...',
        'muscleGroups': '["hamstrings","glutes","lowerBack"]',
        'imageUrl': 'assets/exercise_presets/ruminskay_tyaga.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу...',
        'commonMistakes': '1. Округление спины...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_009',
        'name': 'Жим штанги стоя',
        'description': 'Жим штанги стоя (армейский жим)...',
        'muscleGroups': '["shoulders","triceps"]',
        'imageUrl': 'assets/exercise_presets/gim_shtangi_stoy.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу...',
        'commonMistakes': '1. Избыточный прогиб в пояснице...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_010',
        'name': 'Махи гантелями в стороны',
        'description': 'Махи гантелями в стороны — изолирующее упражнение...',
        'muscleGroups': '["shoulders"]',
        'imageUrl': 'assets/exercise_presets/17.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте ровно...',
        'commonMistakes': '1. Раскачивание корпусом...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_039',
        'name': 'Жим гантелей сидя',
        'description': 'Жим гантелей сидя — вариант жима над головой...',
        'muscleGroups': '["shoulders","triceps"]',
        'imageUrl': 'assets/exercise_presets/16.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте на скамью...',
        'commonMistakes': '1. Прогиб в пояснице...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_040',
        'name': 'Махи гантелями в наклоне',
        'description': 'Махи гантелями в наклоне — изолирующее упражнение для задних дельт...',
        'muscleGroups': '["shoulders","back"]',
        'imageUrl': 'assets/exercise_presets/mahi_ganteli_v_naklone.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите гантели, наклоните корпус...',
        'commonMistakes': '1. Работа спиной вместо дельт...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_108',
        'name': 'Тяга каната к лицу',
        'description': 'Тяга каната к лицу (face pull)...',
        'muscleGroups': '["shoulders","back","traps"]',
        'imageUrl': 'assets/exercise_presets/tyga_kanata_k_licy.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Установите блок на уровне лица...',
        'commonMistakes': '1. Работа только руками...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_012',
        'name': 'Приседания со штангой',
        'description': 'Приседания со штангой — базовое упражнение для ног...',
        'muscleGroups': '["quadriceps","glutes","hamstrings","lowerBack"]',
        'imageUrl': 'assets/exercise_presets/14.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Штанга на трапециях...',
        'commonMistakes': '1. Отрыв пяток...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_013',
        'name': 'Жим ногами',
        'description': 'Жим ногами — упражнение в тренажёре...',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': 'assets/exercise_presets/gim_nogami.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте в тренажёр...',
        'commonMistakes': '1. Полное выпрямление коленей...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_014',
        'name': 'Выпады с гантелями',
        'description': 'Выпады с гантелями — функциональное упражнение...',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': 'assets/exercise_presets/vipadi_s_gantelymi.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите гантели...',
        'commonMistakes': '1. Наклон корпуса вперёд...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_015',
        'name': 'Сгибания ног в тренажёре',
        'description': 'Сгибания ног в тренажёре — изолирующее упражнение...',
        'muscleGroups': '["hamstrings"]',
        'imageUrl': 'assets/exercise_presets/sgibanie_nog_v_trnagore.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте в тренажёр...',
        'commonMistakes': '1. Отрыв таза...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_016',
        'name': 'Подъёмы на носки стоя',
        'description': 'Подъёмы на носки стоя — базовое упражнение для икр...',
        'muscleGroups': '["calves"]',
        'imageUrl': 'assets/exercise_presets/ikri.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте на платформу...',
        'commonMistakes': '1. Быстрые движения без амплитуды...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_043',
        'name': 'Болгарские выпады',
        'description': 'Болгарские выпады — одностороннее упражнение...',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': 'assets/exercise_presets/bolgar_vipadi.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Поставьте одну ногу назад...',
        'commonMistakes': '1. Потеря равновесия...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_078',
        'name': 'Хип-траст со штангой',
        'description': 'Хип-траст со штангой — мощное упражнение для ягодиц...',
        'muscleGroups': '["glutes","hamstrings"]',
        'imageUrl': 'assets/exercise_presets/hip_trast.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на скамью...',
        'commonMistakes': '1. Переразгибание в пояснице...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_079',
        'name': 'Зашагивания на платформу',
        'description': 'Зашагивания на платформу — функциональное упражнение...',
        'muscleGroups': '["quadriceps","glutes","hamstrings"]',
        'imageUrl': 'assets/exercise_presets/shag_vverh.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте перед платформой...',
        'commonMistakes': '1. Потеря равновесия...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_017',
        'name': 'Подъём штанги на бицепс',
        'description': 'Подъём штанги на бицепс — классическое упражнение...',
        'muscleGroups': '["biceps"]',
        'imageUrl': 'assets/exercise_presets/shtanga_na_bicepc.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите штангу хватом снизу...',
        'commonMistakes': '1. Читинг и раскачивание...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_018',
        'name': 'Французский жим',
        'description': 'Французский жим — изолирующее упражнение для трицепса...',
        'muscleGroups': '["triceps"]',
        'imageUrl': 'assets/exercise_presets/franc_gim.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на скамью или сядьте...',
        'commonMistakes': '1. Разведение локтей в стороны...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_019',
        'name': 'Молотки',
        'description': 'Молотки — подъём гантелей нейтральным хватом...',
        'muscleGroups': '["biceps","forearms"]',
        'imageUrl': 'assets/exercise_presets/molotki.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите гантели нейтральным хватом...',
        'commonMistakes': '1. Раскачивание корпусом...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_020',
        'name': 'Отжимания на брусьях',
        'description': 'Отжимания на брусьях — базовое упражнение с собственным весом...',
        'muscleGroups': '["triceps","chest","shoulders"]',
        'imageUrl': 'assets/exercise_presets/brusiy.jpg',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Возьмитесь за брусья...',
        'commonMistakes': '1. Неполная амплитуда...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_046',
        'name': 'Разгибание рук на блоке',
        'description': 'Разгибание рук на блоке — изолирующее упражнение...',
        'muscleGroups': '["triceps"]',
        'imageUrl': 'assets/exercise_presets/24.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте у блока...',
        'commonMistakes': '1. Движение плечами...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_082',
        'name': 'Разгибание рук с гантелью из-за головы',
        'description': 'Разгибание рук с гантелью из-за головы...',
        'muscleGroups': '["triceps"]',
        'imageUrl': 'assets/exercise_presets/25.jpg',
        'exerciseType': 'strength',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте или встаньте...',
        'commonMistakes': '1. Разведение локтей...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_084',
        'name': 'Обратные отжимания от скамьи',
        'description': 'Обратные отжимания от скамьи — упражнение для трицепса...',
        'muscleGroups': '["triceps","chest"]',
        'imageUrl': 'assets/exercise_presets/obrat_otgim.jpg',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте на край скамьи...',
        'commonMistakes': '1. Локти в стороны...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_021',
        'name': 'Скручивания',
        'description': 'Скручивания — базовое упражнение для прямых мышц живота...',
        'muscleGroups': '["abs"]',
        'imageUrl': 'assets/exercise_presets/30.jpg',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на спину...',
        'commonMistakes': '1. Рывки и работа шеей...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_022',
        'name': 'Планка',
        'description': 'Планка — статическое упражнение для кора...',
        'muscleGroups': '["abs","obliques","lowerBack"]',
        'imageUrl': 'assets/exercise_presets/planka.jpg',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'defaultFormat': 'hold',
        'techniqueTips': '1. Примите упор на предплечья...',
        'commonMistakes': '1. Провисание в пояснице...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_023',
        'name': 'Подъём ног в висе',
        'description': 'Подъём ног в висе — сложное упражнение для нижнего пресса...',
        'muscleGroups': '["abs","obliques"]',
        'imageUrl': 'assets/exercise_presets/podem_nog_vvise.jpg',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Повисните на перекладине...',
        'commonMistakes': '1. Раскачивание...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_051',
        'name': 'Боковая планка',
        'description': 'Боковая планка — статическое упражнение для косых мышц...',
        'muscleGroups': '["obliques","abs","shoulders"]',
        'imageUrl': 'assets/exercise_presets/29.jpg',
        'exerciseType': 'bodyweight',
        'defaultFormat': 'hold',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на бок...',
        'commonMistakes': '1. Провисание таза...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_087',
        'name': 'Велосипед',
        'description': 'Велосипед — скручивания с попеременным движением ног...',
        'muscleGroups': '["abs","obliques"]',
        'imageUrl': 'assets/exercise_presets/26.jpg',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Лягте на спину...',
        'commonMistakes': '1. Работа шеей...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_089',
        'name': 'Альпинист',
        'description': 'Альпинист (mountain climbers) — динамическое упражнение...',
        'muscleGroups': '["abs","cardio_vascular","shoulders"]',
        'imageUrl': 'assets/exercise_presets/alpinist.jpg',
        'exerciseType': 'bodyweight',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips': '1. Примите упор лёжа...',
        'commonMistakes': '1. Провисание таза...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_090',
        'name': 'Ролик для пресса',
        'description': 'Ролик для пресса — мощное упражнение для всего кора...',
        'muscleGroups': '["abs","obliques","lowerBack"]',
        'imageUrl': 'assets/exercise_presets/press_rolik.jpg',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте на колени...',
        'commonMistakes': '1. Прогиб в пояснице...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_024',
        'name': 'Бег на дорожке',
        'description': 'Бег на дорожке — классическое кардио...',
        'muscleGroups': '["cardio_vascular","quadriceps","calves"]',
        'imageUrl': 'assets/exercise_presets/beg_na_dorogki.jpg',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips': '1. Начните с разминки...',
        'commonMistakes': '1. Слишком быстрый старт...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_025',
        'name': 'Велотренажёр',
        'description': 'Велотренажёр — кардио с низкой нагрузкой на суставы...',
        'muscleGroups': '["cardio_vascular","quadriceps","glutes"]',
        'imageUrl': 'assets/exercise_presets/velik.jpg',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips': '1. Отрегулируйте высоту сиденья...',
        'commonMistakes': '1. Слишком низкое сиденье...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_026',
        'name': 'Плавание',
        'description': 'Плавание — кардио на всё тело...',
        'muscleGroups': '["cardio_vascular","fullBody"]',
        'imageUrl': 'assets/exercise_presets/plavat.jpg',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips': '1. Начните с разминки в воде...',
        'commonMistakes': '1. Задержка дыхания...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_054',
        'name': 'Прыжки на скакалке',
        'description': 'Прыжки на скакалке — эффективное кардио...',
        'muscleGroups': '["cardio_vascular","calves","shoulders"]',
        'imageUrl': 'assets/exercise_presets/skakalka.jpg',
        'exerciseType': 'cardio',
        'defaultFormat': 'timedSets',
        'isCustom': 0,
        'techniqueTips': '1. Возьмите скакалку правильно...',
        'commonMistakes': '1. Сильное приземление...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_058',
        'name': 'Берпи',
        'description': 'Берпи — комплексное функциональное упражнение...',
        'muscleGroups': '["fullBody","cardio_vascular","chest","quadriceps"]',
        'imageUrl': 'assets/exercise_presets/berpi.jpg',
        'exerciseType': 'bodyweight',
        'isCustom': 0,
        'techniqueTips': '1. Из стойки присядьте...',
        'commonMistakes': '1. Рывки...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_091',
        'name': 'Гребля на тренажёре',
        'description': 'Гребля на тренажёре — кардио на всё тело...',
        'muscleGroups': '["cardio_vascular","back","quadriceps"]',
        'imageUrl': 'assets/exercise_presets/grebly.jpg',
        'exerciseType': 'cardio',
        'isCustom': 0,
        'techniqueTips': '1. Сядьте в тренажёр...',
        'commonMistakes': '1. Работа только руками...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_027',
        'name': 'Работа на груше',
        'description': 'Работа на груше — ударная тренировка...',
        'muscleGroups': '["shoulders","back","abs","fullBody"]',
        'imageUrl': 'assets/exercise_presets/36.jpg',
        'exerciseType': 'boxing',
        'isCustom': 0,
        'techniqueTips': '1. Руки у подбородка...',
        'commonMistakes': '1. Опускание рук...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_028',
        'name': 'Бой с тенью',
        'description': 'Бой с тенью — имитация боя без снаряда...',
        'muscleGroups': '["shoulders","fullBody","cardio_vascular"]',
        'imageUrl': 'assets/exercise_presets/40.jpg',
        'exerciseType': 'boxing',
        'isCustom': 0,
        'techniqueTips': '1. Двигайтесь на носках...',
        'commonMistakes': '1. Статичность...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_029',
        'name': 'Растяжка всего тела',
        'description': 'Растяжка всего тела — комплекс упражнений на гибкость...',
        'muscleGroups': '["flexibility","fullBody"]',
        'imageUrl': 'assets/exercise_presets/42.jpg',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Дышите глубоко и ровно...',
        'commonMistakes': '1. Пружинистые движения...',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'ex_default_030',
        'name': 'Собака мордой вниз',
        'description': 'Собака мордой вниз — классическая асана йоги...',
        'muscleGroups': '["flexibility","shoulders","hamstrings","calves"]',
        'imageUrl': 'assets/exercise_presets/41.jpg',
        'exerciseType': 'yoga',
        'isCustom': 0,
        'techniqueTips': '1. Встаньте на четвереньки...',
        'commonMistakes': '1. Округление спины...',
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

  // ============================================================
  // 🆕 АВТОСИНХРОНИЗАЦИЯ ИЗОБРАЖЕНИЙ (без миграций!)
  // ============================================================
  /// Синхронизирует изображения стандартных упражнений с кодом.
  /// Обновляет ТОЛЬКО те imageUrl, которые null, пустые или начинаются с 'assets/exercise_presets/'.
  /// Пользовательские картинки (из галереи или URL) НЕ перезаписываются.
  Future<void> syncExerciseImages() async {
    final db = await database;

    // 🎯 ЕДИНОЕ МЕСТО, где задаются картинки.
    // Теперь здесь прописаны ТВОИ оригинальные имена файлов!
    final Map<String, String> imageMapping = {
      'ex_default_001': 'assets/exercise_presets/1.jpg',
      'ex_default_002': 'assets/exercise_presets/zim_gantelei_leoja.jpg',
      'ex_default_004': 'assets/exercise_presets/otjimanie.jpg',
      'ex_default_031': 'assets/exercise_presets/zim_gantelei_sidy.jpg',
      'ex_default_034': 'assets/exercise_presets/zim_htangi_na_naklonnoi.jpg',
      'ex_default_032': 'assets/exercise_presets/svedenie_ruk_v_krosovere.jpg',
      'ex_default_005': 'assets/exercise_presets/podtygivanie.jpg',
      'ex_default_006': 'assets/exercise_presets/tyaga_htangi_v_naklone.jpg',
      'ex_default_007': 'assets/exercise_presets/tyga_verhnego_bloka.jpg',
      'ex_default_008': 'assets/exercise_presets/10.jpg',
      'ex_default_035': 'assets/exercise_presets/tyga_gorizontalnogo_bloka.jpg',
      'ex_default_038': 'assets/exercise_presets/tyga_ganteli_k_poesy.jpg',
      'ex_default_042': 'assets/exercise_presets/ruminskay_tyaga.jpg',
      'ex_default_009': 'assets/exercise_presets/gim_shtangi_stoy.jpg',
      'ex_default_010': 'assets/exercise_presets/17.jpg',
      'ex_default_039': 'assets/exercise_presets/16.jpg',
      'ex_default_040': 'assets/exercise_presets/mahi_ganteli_v_naklone.jpg',
      'ex_default_108': 'assets/exercise_presets/tyga_kanata_k_licy.jpg',
      'ex_default_012': 'assets/exercise_presets/14.jpg',
      'ex_default_013': 'assets/exercise_presets/gim_nogami.jpg',
      'ex_default_014': 'assets/exercise_presets/vipadi_s_gantelymi.jpg',
      'ex_default_015': 'assets/exercise_presets/sgibanie_nog_v_trnagore.jpg',
      'ex_default_016': 'assets/exercise_presets/ikri.jpg',
      'ex_default_043': 'assets/exercise_presets/bolgar_vipadi.jpg',
      'ex_default_078': 'assets/exercise_presets/hip_trast.jpg',
      'ex_default_079': 'assets/exercise_presets/shag_vverh.jpg',
      'ex_default_017': 'assets/exercise_presets/shtanga_na_bicepc.jpg',
      'ex_default_018': 'assets/exercise_presets/franc_gim.jpg',
      'ex_default_019': 'assets/exercise_presets/molotki.jpg',
      'ex_default_020': 'assets/exercise_presets/brusiy.jpg',
      'ex_default_046': 'assets/exercise_presets/24.jpg',
      'ex_default_082': 'assets/exercise_presets/25.jpg',
      'ex_default_084': 'assets/exercise_presets/obrat_otgim.jpg',
      'ex_default_021': 'assets/exercise_presets/30.jpg',
      'ex_default_022': 'assets/exercise_presets/planka.jpg',
      'ex_default_023': 'assets/exercise_presets/podem_nog_vvise.jpg',
      'ex_default_051': 'assets/exercise_presets/29.jpg',
      'ex_default_087': 'assets/exercise_presets/26.jpg',
      'ex_default_089': 'assets/exercise_presets/alpinist.jpg',
      'ex_default_090': 'assets/exercise_presets/press_rolik.jpg',
      'ex_default_024': 'assets/exercise_presets/beg_na_dorogki.jpg', // Бег
      'ex_default_025': 'assets/exercise_presets/velik.jpg',          // Велотренажер
      'ex_default_026': 'assets/exercise_presets/plavat.jpg',         // Плавание
      'ex_default_054': 'assets/exercise_presets/skakalka.jpg',       // Скакалка
      'ex_default_058': 'assets/exercise_presets/berpi.jpg',          // Берпи
      'ex_default_091': 'assets/exercise_presets/grebly.jpg',         // Гребля
      'ex_default_027': 'assets/exercise_presets/36.jpg',             // Груша
      'ex_default_028': 'assets/exercise_presets/40.jpg',             // Бой с тенью
      'ex_default_029': 'assets/exercise_presets/42.jpg',             // Растяжка
      'ex_default_030': 'assets/exercise_presets/41.jpg',             // Собака мордой вниз
    };

    int updated = 0;
    for (final entry in imageMapping.entries) {
      try {
        final rows = await db.query(
          'exercises',
          columns: ['imageUrl'],
          where: 'id = ? AND isCustom = 0',
          whereArgs: [entry.key],
          limit: 1,
        );
        if (rows.isEmpty) continue;

        final currentUrl = rows.first['imageUrl'] as String?;
        final newUrl = entry.value;

        // Обновляем ТОЛЬКО если картинка дефолтная, пустая или null
        // Это защищает картинки, которые пользователь загрузил из галереи или по ссылке!
        if (currentUrl == null || currentUrl.isEmpty || currentUrl.startsWith('assets/exercise_presets/')) {
          if (currentUrl != newUrl) {
            await db.update(
              'exercises',
              {'imageUrl': newUrl},
              where: 'id = ?',
              whereArgs: [entry.key],
            );
            updated++;
          }
        }
      } catch (e) {
        debugPrint('  ⚠️ syncExerciseImages ${entry.key}: $e');
      }
    }

    if (updated > 0) {
      debugPrint('🖼️ syncExerciseImages: обновлено $updated изображений');
    }
  }
}