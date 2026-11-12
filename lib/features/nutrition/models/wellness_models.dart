// features/nutrition/models/wellness_models.dart
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
//  NUTRIENTS
// ═══════════════════════════════════════════════════════════════════
enum NutrientKind {
  vitaminC, vitaminA, vitaminB9, vitaminB12, vitaminD, vitaminK, vitaminE,
  potassium, magnesium, calcium, iron, zinc, omega3, fiber, antioxidants,
}

class NutrientMeta {
  final NutrientKind kind;
  final String name;
  final String emoji;
  final Color color;
  final String unit;
  final String benefit;

  const NutrientMeta({
    required this.kind, required this.name, required this.emoji,
    required this.color, required this.unit, required this.benefit,
  });
}

const kNutrientMetas = <NutrientKind, NutrientMeta>{
  NutrientKind.vitaminC: NutrientMeta(
    kind: NutrientKind.vitaminC, name: 'Витамин C', emoji: '🍊',
    color: Color(0xFFEF9563), unit: 'мг',
    benefit: 'Иммунитет, кожа, усвоение железа',
  ),
  NutrientKind.vitaminA: NutrientMeta(
    kind: NutrientKind.vitaminA, name: 'Витамин A', emoji: '🥕',
    color: Color(0xFFE0B054), unit: 'мкг',
    benefit: 'Зрение, кожа, слизистые',
  ),
  NutrientKind.vitaminB9: NutrientMeta(
    kind: NutrientKind.vitaminB9, name: 'Фолат (B9)', emoji: '🥬',
    color: Color(0xFF6C9E88), unit: 'мкг',
    benefit: 'Кроветворение, клетки, беременность',
  ),
  NutrientKind.vitaminB12: NutrientMeta(
    kind: NutrientKind.vitaminB12, name: 'Витамин B12', emoji: '🥩',
    color: Color(0xFFD17A8F), unit: 'мкг',
    benefit: 'Нервы, энергия, кровь',
  ),
  NutrientKind.vitaminD: NutrientMeta(
    kind: NutrientKind.vitaminD, name: 'Витамин D', emoji: '☀️',
    color: Color(0xFFE0B054), unit: 'МЕ',
    benefit: 'Кости, иммунитет, настроение',
  ),
  NutrientKind.vitaminK: NutrientMeta(
    kind: NutrientKind.vitaminK, name: 'Витамин K', emoji: '🥦',
    color: Color(0xFF6C9E88), unit: 'мкг',
    benefit: 'Свёртывание крови, кости',
  ),
  NutrientKind.vitaminE: NutrientMeta(
    kind: NutrientKind.vitaminE, name: 'Витамин E', emoji: '🌻',
    color: Color(0xFFE0B054), unit: 'мг',
    benefit: 'Антиоксидант, кожа, иммунитет',
  ),
  NutrientKind.potassium: NutrientMeta(
    kind: NutrientKind.potassium, name: 'Калий', emoji: '🍌',
    color: Color(0xFF7E9DC6), unit: 'мг',
    benefit: 'Сердце, давление, мышцы',
  ),
  NutrientKind.magnesium: NutrientMeta(
    kind: NutrientKind.magnesium, name: 'Магний', emoji: '🌰',
    color: Color(0xFF9381BB), unit: 'мг',
    benefit: 'Сон, мышцы, нервы',
  ),
  NutrientKind.calcium: NutrientMeta(
    kind: NutrientKind.calcium, name: 'Кальций', emoji: '🥛',
    color: Color(0xFF7E9DC6), unit: 'мг',
    benefit: 'Кости, зубы, мышцы',
  ),
  NutrientKind.iron: NutrientMeta(
    kind: NutrientKind.iron, name: 'Железо', emoji: '🫘',
    color: Color(0xFFD17A8F), unit: 'мг',
    benefit: 'Энергия, гемоглобин',
  ),
  NutrientKind.zinc: NutrientMeta(
    kind: NutrientKind.zinc, name: 'Цинк', emoji: '🦪',
    color: Color(0xFF6C9E88), unit: 'мг',
    benefit: 'Иммунитет, кожа, заживление',
  ),
  NutrientKind.omega3: NutrientMeta(
    kind: NutrientKind.omega3, name: 'Омега-3', emoji: '🐟',
    color: Color(0xFF7E9DC6), unit: 'г',
    benefit: 'Сердце, мозг, зрение',
  ),
  NutrientKind.fiber: NutrientMeta(
    kind: NutrientKind.fiber, name: 'Клетчатка', emoji: '🌾',
    color: Color(0xFFE0B054), unit: 'г',
    benefit: 'Пищеварение, сытость, сахар',
  ),
  NutrientKind.antioxidants: NutrientMeta(
    kind: NutrientKind.antioxidants, name: 'Антиоксиданты', emoji: '🫐',
    color: Color(0xFF9381BB), unit: '',
    benefit: 'Защита клеток, старение',
  ),
};

// ═══════════════════════════════════════════════════════════════════
//  HEALTH BENEFITS
// ═══════════════════════════════════════════════════════════════════
enum HealthBenefit {
  immunity, skin, heart, digestion, energy, bones, brain, eyes, sleep, weight,
}

class BenefitMeta {
  final HealthBenefit kind;
  final String name;
  final String emoji;
  final Color color;
  final String tagline;
  const BenefitMeta({
    required this.kind, required this.name, required this.emoji,
    required this.color, required this.tagline,
  });
}

const kBenefitMetas = <HealthBenefit, BenefitMeta>{
  HealthBenefit.immunity: BenefitMeta(
      kind: HealthBenefit.immunity, name: 'Иммунитет', emoji: '🛡',
      color: Color(0xFF6C9E88), tagline: 'Защита и восстановление'),
  HealthBenefit.skin: BenefitMeta(
      kind: HealthBenefit.skin, name: 'Кожа', emoji: '✨',
      color: Color(0xFFD17A8F), tagline: 'Чистота, упругость, блеск'),
  HealthBenefit.heart: BenefitMeta(
      kind: HealthBenefit.heart, name: 'Сердце', emoji: '❤️',
      color: Color(0xFFD17A8F), tagline: 'Давление, сосуды, холестерин'),
  HealthBenefit.digestion: BenefitMeta(
      kind: HealthBenefit.digestion, name: 'Пищеварение', emoji: '🌿',
      color: Color(0xFF6C9E88), tagline: 'Микрофлора и регулярность'),
  HealthBenefit.energy: BenefitMeta(
      kind: HealthBenefit.energy, name: 'Энергия', emoji: '⚡',
      color: Color(0xFFE0B054), tagline: 'Бодрость и тонус'),
  HealthBenefit.bones: BenefitMeta(
      kind: HealthBenefit.bones, name: 'Кости', emoji: '🦴',
      color: Color(0xFF7E9DC6), tagline: 'Плотность и прочность'),
  HealthBenefit.brain: BenefitMeta(
      kind: HealthBenefit.brain, name: 'Мозг', emoji: '🧠',
      color: Color(0xFF9381BB), tagline: 'Память и ясность'),
  HealthBenefit.eyes: BenefitMeta(
      kind: HealthBenefit.eyes, name: 'Зрение', emoji: '👁',
      color: Color(0xFF7E9DC6), tagline: 'Сетчатка и зрительный нерв'),
  HealthBenefit.sleep: BenefitMeta(
      kind: HealthBenefit.sleep, name: 'Сон', emoji: '🌙',
      color: Color(0xFF9381BB), tagline: 'Качество и засыпание'),
  HealthBenefit.weight: BenefitMeta(
      kind: HealthBenefit.weight, name: 'Вес', emoji: '⚖️',
      color: Color(0xFF6C9E88), tagline: 'Сытость и метаболизм'),
};

// ═══════════════════════════════════════════════════════════════════
//  CONTRAINDICATIONS
// ═══════════════════════════════════════════════════════════════════
enum ContraSeverity { info, caution, warning }

class Contra {
  final String title;
  final String message;
  final ContraSeverity severity;
  const Contra({
    required this.title, required this.message,
    this.severity = ContraSeverity.caution,
  });
}

// ═══════════════════════════════════════════════════════════════════
//  PRODUCT KNOWLEDGE
// ═══════════════════════════════════════════════════════════════════
class ProductKnowledge {
  /// Нормализованный ключ (lowercase, snake_case, латиница).
  /// Используется для сопоставления с `FoodProduct.id` или `.name`.
  final String key;
  final String displayName;
  final String emoji;
  final List<NutrientKind> richIn;
  final List<HealthBenefit> benefits;
  final List<Contra> contraindications;
  final List<int> seasonMonths; // 1..12
  final String? funFact;

  const ProductKnowledge({
    required this.key,
    required this.displayName,
    required this.emoji,
    this.richIn = const [],
    this.benefits = const [],
    this.contraindications = const [],
    this.seasonMonths = const [],
    this.funFact,
  });

  bool get isSeasonal => seasonMonths.isNotEmpty;

  bool isInSeason(DateTime date) => seasonMonths.contains(date.month);
}