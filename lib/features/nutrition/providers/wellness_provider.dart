// features/nutrition/providers/wellness_provider.dart
import 'package:flutter/foundation.dart';

import '../data/wellness_database.dart';
import '../models/nutrition_models.dart' show FoodProduct;
import '../models/wellness_models.dart';

class WellnessProvider extends ChangeNotifier {
  WellnessProvider({DateTime? now}) : _now = now ?? DateTime.now();

  final DateTime _now;
  late final Map<String, ProductKnowledge> _byKey = {
    for (final k in kWellnessDatabase) k.key: k,
  };

  DateTime get today => _now;
  int get currentMonth => _now.month;

  // ── Сезонные крайности ────────────────────────────────────────
  int get _nextMonth => _now.month == 12 ? 1 : _now.month + 1;

  /// Продукты, которые заканчивают сезон в этом месяце (последний месяц).
  List<ProductKnowledge> get endingThisMonth {
    return _byKey.values.where((k) {
      if (k.seasonMonths.isEmpty) return false;
      if (!k.seasonMonths.contains(_now.month)) return false;
      return !k.seasonMonths.contains(_nextMonth);
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  /// Продукты, которые начнутся в следующем месяце.
  List<ProductKnowledge> get startingNextMonth {
    return _byKey.values.where((k) {
      if (k.seasonMonths.isEmpty) return false;
      if (k.seasonMonths.contains(_now.month)) return false;
      return k.seasonMonths.contains(_nextMonth);
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  /// Продукты, которые уже в сезоне второй месяц и более (уверенно).
  List<ProductKnowledge> get firmlyInSeason {
    final prev = _now.month == 1 ? 12 : _now.month - 1;
    return _byKey.values.where((k) {
      if (!k.seasonMonths.contains(_now.month)) return false;
      return k.seasonMonths.contains(prev);
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  // ── Продукты по месяцу ──────────────────────────────────────
  /// Все продукты, которые в сезоне в указанном месяце (1..12).
  List<ProductKnowledge> productsForMonth(int month) {
    return _byKey.values
        .where((k) => k.seasonMonths.contains(month))
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  /// Месяцы (1..12), в которых есть хотя бы один сезонный продукт.
  Set<int> get monthsWithSeason {
    final months = <int>{};
    for (final k in _byKey.values) {
      months.addAll(k.seasonMonths);
    }
    return months;
  }

  // ── Knowledge ──────────────────────────────────────────────────
  ProductKnowledge? knowledgeForKey(String key) => _byKey[key];

  /// Сопоставление с `FoodProduct` (по id или имени).
  ProductKnowledge? knowledgeFor(FoodProduct? product) {
    if (product == null) return null;
    final direct = _byKey[product.id];
    if (direct != null) return direct;
    final normalizedName = _normalize(product.name);
    if (_byKey.containsKey(normalizedName)) return _byKey[normalizedName];
    // частичное совпадение
    for (final k in _byKey.keys) {
      if (normalizedName.contains(k) || k.contains(normalizedName)) {
        return _byKey[k];
      }
    }
    return null;
  }

  bool isInSeason(FoodProduct? product) =>
      knowledgeFor(product)?.isInSeason(_now) ?? false;

  // ── Сегодняшняя выборка ───────────────────────────────────────
  List<ProductKnowledge> get seasonalNow {
    return _byKey.values
        .where((k) => k.isInSeason(_now))
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  /// Продукт дня — ротация по дню года.
  ProductKnowledge? get productOfDay {
    final pool = seasonalNow.isNotEmpty
        ? seasonalNow
        : _byKey.values.toList();
    if (pool.isEmpty) return null;
    final seed = _now.difference(DateTime(_now.year, 1, 1)).inDays;
    return pool[seed % pool.length];
  }

  // ── Витамины ──────────────────────────────────────────────────
  List<ProductKnowledge> productsRichIn(NutrientKind kind) {
    return _byKey.values.where((k) => k.richIn.contains(kind)).toList()
      ..sort((a, b) => b.seasonMonths.length.compareTo(a.seasonMonths.length));
  }

  Map<NutrientKind, int> get nutrientCounts {
    final map = <NutrientKind, int>{};
    for (final k in _byKey.values) {
      for (final n in k.richIn) {
        map[n] = (map[n] ?? 0) + 1;
      }
    }
    return map;
  }

  // ── Польза ────────────────────────────────────────────────────
  List<ProductKnowledge> productsForBenefit(HealthBenefit benefit) {
    return _byKey.values.where((k) => k.benefits.contains(benefit)).toList();
  }

  // ── Осторожно ─────────────────────────────────────────────────
  List<ProductKnowledge> get productsWithContra =>
      _byKey.values.where((k) => k.contraindications.isNotEmpty).toList();

  List<ProductKnowledge> get productsWithWarning => productsWithContra
      .where((k) => k.contraindications
      .any((c) => c.severity == ContraSeverity.warning))
      .toList();

  // ── Рекомендации по профилю питания ──────────────────────────
  /// Возвращает 6 подходящих продуктов: 3 сезонных + 3 по цели.
  List<ProductKnowledge> recommendationsFor({String? goal}) {
    final seasonal = seasonalNow.take(3).toList();
    final goalRelated = <ProductKnowledge>[];
    final targetBenefit = switch (goal) {
      'lose' || 'Похудение' => HealthBenefit.weight,
      'muscleGain' || 'Набор мышц' => HealthBenefit.energy,
      'gain' || 'Набор веса' => HealthBenefit.energy,
      'recomposition' || 'Рекомпозиция' => HealthBenefit.weight,
      _ => HealthBenefit.immunity,
    };
    goalRelated.addAll(productsForBenefit(targetBenefit).take(3));
    return [...seasonal, ...goalRelated]
        .where((k) => !seasonal.contains(k) || true)
        .toSet()
        .toList();
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zа-я0-9_]'), '');
  }
}