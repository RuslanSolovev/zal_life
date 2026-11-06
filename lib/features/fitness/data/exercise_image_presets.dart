// features/fitness/data/exercise_image_presets.dart
// Локальные assets 1-45.jpg

enum ExerciseTypeHint { strength, cardio, boxing, yoga }

class ExerciseImagePresets {
  static final List<String> all = List.generate(
    45,
        (i) => 'assets/exercise_presets/${i + 1}.jpg',
  );

  static Map<String, List<String>> get byCategory => {
    'Грудь':     all.sublist(0, 5),    // 1-5
    'Спина':     all.sublist(5, 10),   // 6-10
    'Ноги':      all.sublist(10, 15),  // 11-15
    'Плечи':     all.sublist(15, 20),  // 16-20
    'Руки':      all.sublist(20, 25),  // 21-25
    'Пресс':     all.sublist(25, 30),  // 26-30
    'Кардио':    all.sublist(30, 35),  // 31-35
    'Бокс':      all.sublist(35, 39),  // 36-39
    'Йога':      all.sublist(39, 42),  // 40-42
    'Растяжка':  all.sublist(42, 45),  // 43-45
  };

  static String? defaultCategoryFor(ExerciseTypeHint hint) {
    switch (hint) {
      case ExerciseTypeHint.cardio:   return 'Кардио';
      case ExerciseTypeHint.boxing:   return 'Бокс';
      case ExerciseTypeHint.yoga:     return 'Йога';
      case ExerciseTypeHint.strength: return null;
    }
  }
}