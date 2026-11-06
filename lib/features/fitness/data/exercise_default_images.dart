// features/fitness/data/exercise_default_images.dart
// Генератор imageUrl для всех стандартных упражнений БД.
// Работает по muscleGroups + exerciseType, распределяет URL по кругу
// внутри категории.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'exercise_image_presets.dart';

/// Возвращает категорию упражнения по его muscleGroups и exerciseType.
/// Тот же «смысловой» маппинг, что и в UI-пресетах.
String categoryForExercise(List<String> muscles, String type) {
  // Сначала тип — он жёстче мышц.
  if (type == 'cardio') return 'Кардио';
  if (type == 'boxing') return 'Бокс';
  if (type == 'yoga') {
    // Гибкость/пресс/поясница → растяжка, остальное → йога.
    if (muscles.contains('flexibility') ||
        muscles.contains('abs') ||
        muscles.contains('obliques') ||
        muscles.contains('lowerBack')) {
      return 'Растяжка';
    }
    return 'Йога';
  }

  // strength / bodyweight / other — по мышцам.
  if (muscles.contains('chest')) return 'Грудь';

  if (muscles.contains('back') ||
      muscles.contains('lats') ||
      muscles.contains('traps')) {
    return 'Спина';
  }

  if (muscles.contains('quadriceps') ||
      muscles.contains('glutes') ||
      muscles.contains('hamstrings') ||
      muscles.contains('calves')) {
    return 'Ноги';
  }

  if (muscles.contains('shoulders')) return 'Плечи';

  if (muscles.contains('biceps') ||
      muscles.contains('triceps') ||
      muscles.contains('forearms')) {
    return 'Руки';
  }

  if (muscles.contains('abs') ||
      muscles.contains('obliques') ||
      muscles.contains('lowerBack')) {
    return 'Пресс';
  }

  // Fallback — чтобы не осталось пустого изображения.
  return 'Грудь';
}

/// Строит карту `exerciseId → imageUrl` для всех дефолтных упражнений БД.
/// Упражнения одной категории получают URL по кругу (с повторами, если
/// URL в пуле меньше, чем упражнений — это нормально).
Future<Map<String, String>> buildExerciseDefaultImages(Database db) async {
  final rows = await db.query(
    'exercises',
    columns: ['id', 'muscleGroups', 'exerciseType'],
    where: 'isCustom = 0',
  );

  final counters = <String, int>{};
  final result = <String, String>{};

  for (final row in rows) {
    final id = row['id'] as String;
    final type = (row['exerciseType'] as String?) ?? 'strength';

    List<String> muscles = [];
    final raw = row['muscleGroups'];
    if (raw is String && raw.isNotEmpty) {
      try {
        muscles = (jsonDecode(raw) as List).cast<String>();
      } catch (_) {}
    }

    final category = categoryForExercise(muscles, type);
    final urls = ExerciseImagePresets.byCategory[category];
    if (urls == null || urls.isEmpty) continue;

    final index = counters[category] ?? 0;
    result[id] = urls[index % urls.length];
    counters[category] = index + 1;
  }

  debugPrint(
      '🖼️ buildExerciseDefaultImages: ${result.length} назначений, '
          'по категориям: ${counters.entries.map((e) => '${e.key}=${e.value}').join(', ')}');

  return result;
}

/// Проставляет `imageUrl` всем стандартным упражнениям, у которых оно пустое.
/// Идемпотентно: не трогает уже заполненные.
/// Возвращает количество обновлённых записей.
Future<int> applyDefaultExerciseImages(Database db) async {
  final mapping = await buildExerciseDefaultImages(db);
  if (mapping.isEmpty) return 0;

  int updated = 0;

  // Каждое упражнение обновляем отдельным UPDATE, чтобы получить корректный
  // row-count (batch с noResult: true не даёт per-row счётчик).
  for (final entry in mapping.entries) {
    try {
      final n = await db.update(
        'exercises',
        {'imageUrl': entry.value},
        where:
        "id = ? AND isCustom = 0 AND (imageUrl IS NULL OR imageUrl = '')",
        whereArgs: [entry.key],
      );
      updated += n;
    } catch (e) {
      debugPrint('  ⚠️ imageUrl для ${entry.key}: $e');
    }
  }

  debugPrint('🖼️ applyDefaultExerciseImages: обновлено $updated из ${mapping.length}');
  return updated;
}