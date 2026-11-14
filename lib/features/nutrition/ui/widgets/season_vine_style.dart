// lib/features/nutrition/ui/widgets/season_vine_style.dart
import 'package:flutter/foundation.dart';

enum SeasonVineStyle {
  postage,
  botanica,
  aurora,
  flipboard,
  metro,
  kintsugi,
  hourglass,
  circuit,
  conveyor,
  clock,
  lighthouse,
}

class SeasonVineStyleController {
  SeasonVineStyleController._();

  static final ValueNotifier<SeasonVineStyle> current =
  ValueNotifier(SeasonVineStyle.postage);

  /// Опциональный хук персистенции.
  /// Пример: см. раздел "Персистенция" ниже.
  static Future<void> Function(String? save)? onPersist;

  static void select(SeasonVineStyle style) {
    if (current.value == style) return;
    current.value = style;
    onPersist?.call(style.name);
  }
}