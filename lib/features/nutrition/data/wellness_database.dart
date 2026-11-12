// features/nutrition/data/wellness_database.dart
import '../models/wellness_models.dart';

/// Локальная база знаний. Ключи нормализованы — сопоставление с
/// `FoodProduct` идёт по нормализованному `name` или `id`.
const List<ProductKnowledge> kWellnessDatabase = [
  // ═══════════════ ФРУКТЫ ═══════════════
  ProductKnowledge(
    key: 'strawberry', displayName: 'Клубника', emoji: '🍓',
    seasonMonths: [5, 6, 7],
    richIn: [NutrientKind.vitaminC, NutrientKind.antioxidants, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.skin, HealthBenefit.heart],
    contraindications: [
      Contra(title: 'Аллергия', message: 'Частая аллергия у детей и взрослых',
          severity: ContraSeverity.warning),
    ],
    funFact: 'В 100 г клубники — суточная норма витамина C.',
  ),
  ProductKnowledge(
    key: 'apple', displayName: 'Яблоко', emoji: '🍎',
    seasonMonths: [8, 9, 10],
    richIn: [NutrientKind.fiber, NutrientKind.antioxidants, NutrientKind.vitaminC],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart, HealthBenefit.weight],
    contraindications: [
      Contra(title: 'СРК', message: 'Много фруктозы — при СРК ограничить',
          severity: ContraSeverity.info),
    ],
    funFact: 'Кожура содержит большую часть пектина и полифенолов.',
  ),
  ProductKnowledge(
    key: 'banana', displayName: 'Банан', emoji: '🍌',
    richIn: [NutrientKind.potassium, NutrientKind.vitaminB9, NutrientKind.fiber],
    benefits: [HealthBenefit.heart, HealthBenefit.energy, HealthBenefit.digestion],
    contraindications: [
      Contra(title: 'Диабет', message: 'Средний ГИ — следи за порцией',
          severity: ContraSeverity.caution),
      Contra(title: 'Почки', message: 'Много калия — при ХБП осторожно',
          severity: ContraSeverity.warning),
    ],
  ),
  ProductKnowledge(
    key: 'orange', displayName: 'Апельсин', emoji: '🍊',
    seasonMonths: [12, 1, 2, 3],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminB9, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.skin],
    contraindications: [
      Contra(title: 'ГЭРБ', message: 'Кислый — может усиливать изжогу',
          severity: ContraSeverity.info),
    ],
  ),
  ProductKnowledge(
    key: 'tangerine', displayName: 'Мандарин', emoji: '🍊',
    seasonMonths: [11, 12, 1],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminA],
    benefits: [HealthBenefit.immunity, HealthBenefit.skin],
  ),
  ProductKnowledge(
    key: 'watermelon', displayName: 'Арбуз', emoji: '🍉',
    seasonMonths: [7, 8],
    richIn: [NutrientKind.vitaminC, NutrientKind.antioxidants],
    benefits: [HealthBenefit.heart, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'blueberry', displayName: 'Голубика', emoji: '🫐',
    seasonMonths: [7, 8],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC, NutrientKind.fiber],
    benefits: [HealthBenefit.brain, HealthBenefit.eyes, HealthBenefit.heart],
    funFact: 'Антоцианы — пигмент, поддерживающий зрение.',
  ),
  ProductKnowledge(
    key: 'raspberry', displayName: 'Малина', emoji: '🍇',
    seasonMonths: [7, 8],
    richIn: [NutrientKind.fiber, NutrientKind.vitaminC, NutrientKind.antioxidants],
    benefits: [HealthBenefit.digestion, HealthBenefit.immunity],
  ),
  ProductKnowledge(
    key: 'pomegranate', displayName: 'Гранат', emoji: '🍎',
    seasonMonths: [10, 11, 12],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC, NutrientKind.fiber],
    benefits: [HealthBenefit.heart, HealthBenefit.skin],
    contraindications: [
      Contra(title: 'Гастрит', message: 'Кислый — при обострении осторожно',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'persimmon', displayName: 'Хурма', emoji: '🟠',
    seasonMonths: [10, 11, 12],
    richIn: [NutrientKind.vitaminA, NutrientKind.fiber, NutrientKind.vitaminC],
    benefits: [HealthBenefit.eyes, HealthBenefit.skin, HealthBenefit.immunity],
    contraindications: [
      Contra(title: 'Гастрит', message: 'Таннины могут вызвать дискомфорт',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'grape', displayName: 'Виноград', emoji: '🍇',
    seasonMonths: [8, 9, 10],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminK],
    benefits: [HealthBenefit.heart, HealthBenefit.skin],
    contraindications: [
      Contra(title: 'Диабет', message: 'Высокое содержание сахара',
          severity: ContraSeverity.warning),
    ],
  ),
  ProductKnowledge(
    key: 'kiwi', displayName: 'Киви', emoji: '🥝',
    seasonMonths: [12, 1, 2, 3],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminK, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'lemon', displayName: 'Лимон', emoji: '🍋',
    seasonMonths: [11, 12, 1, 2, 3],
    richIn: [NutrientKind.vitaminC, NutrientKind.antioxidants],
    benefits: [HealthBenefit.immunity, HealthBenefit.skin],
  ),
  ProductKnowledge(
    key: 'avocado', displayName: 'Авокадо', emoji: '🥑',
    richIn: [NutrientKind.omega3, NutrientKind.fiber, NutrientKind.potassium],
    benefits: [HealthBenefit.heart, HealthBenefit.weight, HealthBenefit.skin],
  ),

  // ═══════════════ ОВОЩИ ═══════════════
  ProductKnowledge(
    key: 'cucumber', displayName: 'Огурец', emoji: '🥒',
    seasonMonths: [5, 6, 7, 8],
    richIn: [NutrientKind.vitaminK, NutrientKind.fiber],
    benefits: [HealthBenefit.weight, HealthBenefit.skin],
  ),
  ProductKnowledge(
    key: 'tomato', displayName: 'Помидор', emoji: '🍅',
    seasonMonths: [6, 7, 8, 9],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC, NutrientKind.vitaminK],
    benefits: [HealthBenefit.heart, HealthBenefit.skin, HealthBenefit.eyes],
    contraindications: [
      Contra(title: 'Гастрит', message: 'Кислый — при обострении осторожно',
          severity: ContraSeverity.info),
    ],
  ),
  ProductKnowledge(
    key: 'pepper', displayName: 'Болгарский перец', emoji: '🫑',
    seasonMonths: [7, 8, 9],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminA, NutrientKind.vitaminB9],
    benefits: [HealthBenefit.immunity, HealthBenefit.skin, HealthBenefit.eyes],
  ),
  ProductKnowledge(
    key: 'zucchini', displayName: 'Кабачок', emoji: '🥒',
    seasonMonths: [6, 7, 8],
    richIn: [NutrientKind.fiber, NutrientKind.potassium],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'pumpkin', displayName: 'Тыква', emoji: '🎃',
    seasonMonths: [9, 10, 11],
    richIn: [NutrientKind.vitaminA, NutrientKind.fiber, NutrientKind.antioxidants],
    benefits: [HealthBenefit.eyes, HealthBenefit.immunity, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'carrot', displayName: 'Морковь', emoji: '🥕',
    seasonMonths: [9, 10, 11, 12, 1, 2],
    richIn: [NutrientKind.vitaminA, NutrientKind.fiber, NutrientKind.antioxidants],
    benefits: [HealthBenefit.eyes, HealthBenefit.skin, HealthBenefit.immunity],
    funFact: 'Бета-каротин лучше усваивается с жиром.',
  ),
  ProductKnowledge(
    key: 'beet', displayName: 'Свёкла', emoji: '🟣',
    seasonMonths: [9, 10, 11, 12, 1, 2],
    richIn: [NutrientKind.fiber, NutrientKind.vitaminB9, NutrientKind.antioxidants],
    benefits: [HealthBenefit.heart, HealthBenefit.energy, HealthBenefit.digestion],
    contraindications: [
      Contra(title: 'Камни в почках', message: 'Оксалаты — ограничить',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'broccoli', displayName: 'Брокколи', emoji: '🥦',
    seasonMonths: [6, 7, 8, 9, 10],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminK, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.bones, HealthBenefit.digestion],
    contraindications: [
      Contra(title: 'Гипотиреоз', message: 'Гойтрогены — при снижении щитовидки',
          severity: ContraSeverity.caution),
      Contra(title: 'Антикоагулянты', message: 'Много витамина K — обсуди с врачом',
          severity: ContraSeverity.warning),
    ],
  ),
  ProductKnowledge(
    key: 'spinach', displayName: 'Шпинат', emoji: '🥬',
    seasonMonths: [4, 5, 6, 9, 10],
    richIn: [NutrientKind.iron, NutrientKind.vitaminK, NutrientKind.vitaminB9],
    benefits: [HealthBenefit.energy, HealthBenefit.bones, HealthBenefit.eyes],
    contraindications: [
      Contra(title: 'Камни в почках', message: 'Оксалаты — ограничить',
          severity: ContraSeverity.warning),
      Contra(title: 'Антикоагулянты', message: 'Много витамина K',
          severity: ContraSeverity.warning),
    ],
  ),
  ProductKnowledge(
    key: 'cabbage', displayName: 'Капуста', emoji: '🥬',
    seasonMonths: [9, 10, 11, 12, 1, 2, 3],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminK, NutrientKind.fiber],
    benefits: [HealthBenefit.digestion, HealthBenefit.immunity],
    contraindications: [
      Contra(title: 'СРК / вздутие', message: 'Много клетчатки и серы',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'radish', displayName: 'Редис', emoji: '🌶',
    seasonMonths: [5, 6, 7],
    richIn: [NutrientKind.vitaminC, NutrientKind.fiber],
    benefits: [HealthBenefit.digestion, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'lettuce', displayName: 'Салат листовой', emoji: '🥬',
    seasonMonths: [4, 5, 6, 7, 8, 9],
    richIn: [NutrientKind.vitaminK, NutrientKind.vitaminA, NutrientKind.fiber],
    benefits: [HealthBenefit.weight, HealthBenefit.skin],
  ),
  ProductKnowledge(
    key: 'potato', displayName: 'Картофель', emoji: '🥔',
    seasonMonths: [9, 10, 11, 12, 1],
    richIn: [NutrientKind.potassium, NutrientKind.vitaminC, NutrientKind.fiber],
    benefits: [HealthBenefit.energy, HealthBenefit.heart],
    contraindications: [
      Contra(title: 'Диабет', message: 'Высокий ГИ — учитывай порцию',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'onion', displayName: 'Лук', emoji: '🧅',
    seasonMonths: [6, 7, 8, 9],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC],
    benefits: [HealthBenefit.immunity, HealthBenefit.heart],
    contraindications: [
      Contra(title: 'ГЭРБ', message: 'Может усиливать изжогу',
          severity: ContraSeverity.info),
    ],
  ),
  ProductKnowledge(
    key: 'garlic', displayName: 'Чеснок', emoji: '🧄',
    seasonMonths: [9, 10, 11, 12, 1, 2, 3, 4],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC],
    benefits: [HealthBenefit.immunity, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'mushrooms', displayName: 'Грибы', emoji: '🍄',
    seasonMonths: [8, 9, 10],
    richIn: [NutrientKind.vitaminD, NutrientKind.vitaminB9, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.bones],
  ),

  // ═══════════════ ЗЕЛЕНЬ ═══════════════
  ProductKnowledge(
    key: 'parsley', displayName: 'Петрушка', emoji: '🌿',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.vitaminK, NutrientKind.vitaminC, NutrientKind.antioxidants],
    benefits: [HealthBenefit.immunity, HealthBenefit.bones, HealthBenefit.skin],
  ),
  ProductKnowledge(
    key: 'dill', displayName: 'Укроп', emoji: '🌿',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminA],
    benefits: [HealthBenefit.digestion, HealthBenefit.immunity],
  ),

  // ═══════════════ БЕЛОК ═══════════════
  ProductKnowledge(
    key: 'chicken_breast', displayName: 'Куриная грудка', emoji: '🍗',
    richIn: [NutrientKind.vitaminB12, NutrientKind.zinc],
    benefits: [HealthBenefit.energy, HealthBenefit.weight, HealthBenefit.immunity],
  ),
  ProductKnowledge(
    key: 'beef', displayName: 'Говядина', emoji: '🥩',
    richIn: [NutrientKind.iron, NutrientKind.vitaminB12, NutrientKind.zinc],
    benefits: [HealthBenefit.energy, HealthBenefit.bones],
    contraindications: [
      Contra(title: 'Подагра', message: 'Пурины — ограничить',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'salmon', displayName: 'Лосось', emoji: '🐟',
    richIn: [NutrientKind.omega3, NutrientKind.vitaminD, NutrientKind.vitaminB12],
    benefits: [HealthBenefit.heart, HealthBenefit.brain, HealthBenefit.bones],
    funFact: 'Одна из лучших комбинаций омега-3 + витамин D.',
  ),
  ProductKnowledge(
    key: 'cod', displayName: 'Треска', emoji: '🐟',
    richIn: [NutrientKind.omega3, NutrientKind.vitaminB12, NutrientKind.zinc],
    benefits: [HealthBenefit.heart, HealthBenefit.brain],
  ),
  ProductKnowledge(
    key: 'eggs', displayName: 'Яйца', emoji: '🥚',
    richIn: [NutrientKind.vitaminD, NutrientKind.vitaminB12, NutrientKind.zinc],
    benefits: [HealthBenefit.bones, HealthBenefit.energy, HealthBenefit.eyes],
    contraindications: [
      Contra(title: 'Аллергия', message: 'Частая пищевая аллергия',
          severity: ContraSeverity.warning),
    ],
  ),
  ProductKnowledge(
    key: 'cottage_cheese', displayName: 'Творог', emoji: '🥛',
    richIn: [NutrientKind.calcium, NutrientKind.vitaminB12],
    benefits: [HealthBenefit.bones, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'kefir', displayName: 'Кефир', emoji: '🥛',
    richIn: [NutrientKind.calcium, NutrientKind.vitaminB12],
    benefits: [HealthBenefit.digestion, HealthBenefit.bones],
  ),
  ProductKnowledge(
    key: 'greek_yogurt', displayName: 'Греческий йогурт', emoji: '🥛',
    richIn: [NutrientKind.calcium, NutrientKind.vitaminB12],
    benefits: [HealthBenefit.digestion, HealthBenefit.bones, HealthBenefit.weight],
  ),

  // ═══════════════ КРУПЫ / БОБОВЫЕ ═══════════════
  ProductKnowledge(
    key: 'buckwheat', displayName: 'Гречка', emoji: '🌾',
    richIn: [NutrientKind.iron, NutrientKind.magnesium, NutrientKind.fiber],
    benefits: [HealthBenefit.energy, HealthBenefit.heart, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'oatmeal', displayName: 'Овсянка', emoji: '🌾',
    richIn: [NutrientKind.fiber, NutrientKind.magnesium],
    benefits: [HealthBenefit.heart, HealthBenefit.digestion, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'lentils', displayName: 'Чечевица', emoji: '🫘',
    richIn: [NutrientKind.iron, NutrientKind.vitaminB9, NutrientKind.fiber],
    benefits: [HealthBenefit.energy, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'chickpeas', displayName: 'Нут', emoji: '🫘',
    richIn: [NutrientKind.vitaminB9, NutrientKind.iron, NutrientKind.fiber],
    benefits: [HealthBenefit.digestion, HealthBenefit.energy],
  ),
  ProductKnowledge(
    key: 'walnuts', displayName: 'Грецкие орехи', emoji: '🌰',
    richIn: [NutrientKind.omega3, NutrientKind.antioxidants, NutrientKind.magnesium],
    benefits: [HealthBenefit.brain, HealthBenefit.heart],
    contraindications: [
      Contra(title: 'Аллергия', message: 'Частая аллергия на орехи',
          severity: ContraSeverity.warning),
    ],
  ),
  ProductKnowledge(
    key: 'almonds', displayName: 'Миндаль', emoji: '🌰',
    richIn: [NutrientKind.magnesium, NutrientKind.calcium],
    benefits: [HealthBenefit.bones, HealthBenefit.heart, HealthBenefit.sleep],
  ),

  // ═══════════════ 🍑 ЛЕТО (июнь–август) ═══════════════
  ProductKnowledge(
    key: 'cherry', displayName: 'Черешня', emoji: '🍒',
    seasonMonths: [6, 7],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC, NutrientKind.potassium],
    benefits: [HealthBenefit.heart, HealthBenefit.skin, HealthBenefit.immunity],
    funFact: 'Тёмные сорта — больше антоцианов для сосудов.',
  ),
  ProductKnowledge(
    key: 'sweet_cherry', displayName: 'Вишня', emoji: '🍒',
    seasonMonths: [7, 8],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC],
    benefits: [HealthBenefit.heart, HealthBenefit.sleep],
    contraindications: [
      Contra(title: 'Гастрит', message: 'Кислая — при обострении осторожно',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'black_currant', displayName: 'Смородина чёрная', emoji: '🫐',
    seasonMonths: [6, 7, 8],
    richIn: [NutrientKind.vitaminC, NutrientKind.antioxidants, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.skin, HealthBenefit.eyes],
    funFact: 'В 4 раза больше витамина C, чем в лимоне.',
  ),
  ProductKnowledge(
    key: 'gooseberry', displayName: 'Крыжовник', emoji: '🟢',
    seasonMonths: [6, 7, 8],
    richIn: [NutrientKind.fiber, NutrientKind.vitaminC],
    benefits: [HealthBenefit.digestion, HealthBenefit.immunity],
  ),
  ProductKnowledge(
    key: 'peach', displayName: 'Персик', emoji: '🍑',
    seasonMonths: [7, 8],
    richIn: [NutrientKind.vitaminA, NutrientKind.vitaminC, NutrientKind.potassium],
    benefits: [HealthBenefit.skin, HealthBenefit.eyes, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'apricot', displayName: 'Абрикос', emoji: '🍑',
    seasonMonths: [6, 7, 8],
    richIn: [NutrientKind.vitaminA, NutrientKind.fiber, NutrientKind.potassium],
    benefits: [HealthBenefit.eyes, HealthBenefit.heart, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'melon', displayName: 'Дыня', emoji: '🍈',
    seasonMonths: [7, 8, 9],
    richIn: [NutrientKind.vitaminA, NutrientKind.vitaminC, NutrientKind.potassium],
    benefits: [HealthBenefit.heart, HealthBenefit.skin],
    contraindications: [
      Contra(title: 'Диабет', message: 'Высокий ГИ — следи за порцией',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'eggplant', displayName: 'Баклажан', emoji: '🍆',
    seasonMonths: [7, 8, 9],
    richIn: [NutrientKind.fiber, NutrientKind.antioxidants, NutrientKind.potassium],
    benefits: [HealthBenefit.heart, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'corn', displayName: 'Кукуруза', emoji: '🌽',
    seasonMonths: [7, 8, 9],
    richIn: [NutrientKind.fiber, NutrientKind.vitaminB9, NutrientKind.magnesium],
    benefits: [HealthBenefit.energy, HealthBenefit.digestion],
  ),

  // ═══════════════ 🍂 ОСЕНЬ (сентябрь–ноябрь) ═══════════════
  ProductKnowledge(
    key: 'pear', displayName: 'Груша', emoji: '🍐',
    seasonMonths: [8, 9, 10],
    richIn: [NutrientKind.fiber, NutrientKind.vitaminC, NutrientKind.potassium],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'plum', displayName: 'Слива', emoji: '🟣',
    seasonMonths: [7, 8, 9],
    richIn: [NutrientKind.fiber, NutrientKind.antioxidants, NutrientKind.vitaminK],
    benefits: [HealthBenefit.digestion, HealthBenefit.bones],
    contraindications: [
      Contra(title: 'СРК', message: 'Сорбитол — может усиливать вздутие',
          severity: ContraSeverity.info),
    ],
  ),
  ProductKnowledge(
    key: 'quince', displayName: 'Айва', emoji: '🟡',
    seasonMonths: [9, 10, 11],
    richIn: [NutrientKind.fiber, NutrientKind.vitaminC, NutrientKind.antioxidants],
    benefits: [HealthBenefit.digestion, HealthBenefit.immunity],
  ),
  ProductKnowledge(
    key: 'fig', displayName: 'Инжир', emoji: '🟤',
    seasonMonths: [8, 9, 10],
    richIn: [NutrientKind.fiber, NutrientKind.calcium, NutrientKind.potassium],
    benefits: [HealthBenefit.bones, HealthBenefit.digestion],
    funFact: 'Один из древнейших окультуренных плодов.',
  ),
  ProductKnowledge(
    key: 'feijoa', displayName: 'Фейхоа', emoji: '🟢',
    seasonMonths: [10, 11, 12],
    richIn: [NutrientKind.vitaminC, NutrientKind.fiber, NutrientKind.antioxidants],
    benefits: [HealthBenefit.immunity, HealthBenefit.digestion],
    funFact: 'Йод в легкоусвояемой форме.',
  ),
  ProductKnowledge(
    key: 'cranberry', displayName: 'Клюква', emoji: '🔴',
    seasonMonths: [9, 10, 11, 12],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'lingonberry', displayName: 'Брусника', emoji: '🔴',
    seasonMonths: [9, 10, 11],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC],
    benefits: [HealthBenefit.immunity, HealthBenefit.eyes],
  ),

  // ═══════════════ ❄️ ЗИМА (декабрь–февраль) ═══════════════
  ProductKnowledge(
    key: 'grapefruit', displayName: 'Грейпфрут', emoji: '🍊',
    seasonMonths: [12, 1, 2, 3],
    richIn: [NutrientKind.vitaminC, NutrientKind.antioxidants, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.weight, HealthBenefit.heart],
    contraindications: [
      Contra(title: 'Лекарства', message: 'Влияет на метаболизм некоторых препаратов',
          severity: ContraSeverity.warning),
    ],
  ),
  ProductKnowledge(
    key: 'pomelo', displayName: 'Помело', emoji: '🍊',
    seasonMonths: [12, 1, 2],
    richIn: [NutrientKind.vitaminC, NutrientKind.fiber, NutrientKind.potassium],
    benefits: [HealthBenefit.immunity, HealthBenefit.heart],
  ),

  // ═══════════════ 🌿 ВЕСНА (март–май) ═══════════════
  ProductKnowledge(
    key: 'sorrel', displayName: 'Щавель', emoji: '🍃',
    seasonMonths: [4, 5, 6],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminK, NutrientKind.iron],
    benefits: [HealthBenefit.immunity, HealthBenefit.digestion],
    contraindications: [
      Contra(title: 'Камни в почках', message: 'Оксалаты — ограничить',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'ramson', displayName: 'Черемша', emoji: '🌿',
    seasonMonths: [3, 4, 5],
    richIn: [NutrientKind.vitaminC, NutrientKind.antioxidants],
    benefits: [HealthBenefit.immunity, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'green_onion', displayName: 'Зелёный лук', emoji: '🌱',
    seasonMonths: [3, 4, 5, 6],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminK, NutrientKind.vitaminA],
    benefits: [HealthBenefit.immunity, HealthBenefit.eyes],
  ),
  ProductKnowledge(
    key: 'asparagus', displayName: 'Спаржа', emoji: '🌱',
    seasonMonths: [4, 5, 6],
    richIn: [NutrientKind.vitaminB9, NutrientKind.fiber, NutrientKind.vitaminK],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'basil', displayName: 'Базилик', emoji: '🌿',
    seasonMonths: [6, 7, 8, 9],
    richIn: [NutrientKind.vitaminK, NutrientKind.antioxidants],
    benefits: [HealthBenefit.digestion, HealthBenefit.immunity],
  ),
  ProductKnowledge(
    key: 'cilantro', displayName: 'Кинза', emoji: '🌿',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.vitaminK, NutrientKind.vitaminA],
    benefits: [HealthBenefit.digestion, HealthBenefit.skin],
  ),

  // ═══════════════ 🥩 БЕЛОК / КРУПЫ (круглый год) ═══════════════
  ProductKnowledge(
    key: 'turkey', displayName: 'Индейка', emoji: '🦃',
    richIn: [NutrientKind.vitaminB12, NutrientKind.zinc],
    benefits: [HealthBenefit.energy, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'tuna', displayName: 'Тунец', emoji: '🐟',
    richIn: [NutrientKind.omega3, NutrientKind.vitaminD, NutrientKind.vitaminB12],
    benefits: [HealthBenefit.heart, HealthBenefit.brain, HealthBenefit.eyes],
  ),
  ProductKnowledge(
    key: 'mackerel', displayName: 'Скумбрия', emoji: '🐟',
    richIn: [NutrientKind.omega3, NutrientKind.vitaminD],
    benefits: [HealthBenefit.heart, HealthBenefit.bones],
  ),
  ProductKnowledge(
    key: 'quinoa', displayName: 'Киноа', emoji: '🌾',
    seasonMonths: [8, 9, 10],
    richIn: [NutrientKind.fiber, NutrientKind.magnesium, NutrientKind.iron],
    benefits: [HealthBenefit.digestion, HealthBenefit.energy, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'brown_rice', displayName: 'Бурый рис', emoji: '🍚',
    richIn: [NutrientKind.fiber, NutrientKind.magnesium],
    benefits: [HealthBenefit.energy, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'milk', displayName: 'Молоко', emoji: '🥛',
    richIn: [NutrientKind.calcium, NutrientKind.vitaminD, NutrientKind.vitaminB12],
    benefits: [HealthBenefit.bones, HealthBenefit.energy],
    contraindications: [
      Contra(title: 'Лактоза', message: 'При непереносимости — заменитель',
          severity: ContraSeverity.info),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════
  //  🆕 РАСШИРЕНИЕ БАЗЫ — +45 продуктов
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════ ЯГОДЫ (расширение) ═══════════════
  ProductKnowledge(
    key: 'currant_red', displayName: 'Красная смородина', emoji: '🍒',
    seasonMonths: [6, 7, 8],
    richIn: [NutrientKind.vitaminC, NutrientKind.antioxidants, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.heart, HealthBenefit.skin],
    funFact: 'Больше витамина C, чем в апельсине, и много пектина.',
  ),
  ProductKnowledge(
    key: 'currant_white', displayName: 'Белая смородина', emoji: '🟡',
    seasonMonths: [7, 8],
    richIn: [NutrientKind.vitaminC, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'sea_buckthorn', displayName: 'Облепиха', emoji: '🟠',
    seasonMonths: [8, 9, 10],
    richIn: [NutrientKind.vitaminC, NutrientKind.omega3, NutrientKind.antioxidants],
    benefits: [HealthBenefit.immunity, HealthBenefit.skin, HealthBenefit.heart],
    funFact: 'Омега-3 из растительного источника — редкость.',
  ),
  ProductKnowledge(
    key: 'blackberry', displayName: 'Ежевика', emoji: '🫐',
    seasonMonths: [7, 8, 9],
    richIn: [NutrientKind.antioxidants, NutrientKind.fiber, NutrientKind.vitaminK],
    benefits: [HealthBenefit.brain, HealthBenefit.digestion, HealthBenefit.immunity],
  ),
  ProductKnowledge(
    key: 'strawberry_wild', displayName: 'Земляника лесная', emoji: '🍓',
    seasonMonths: [6, 7],
    richIn: [NutrientKind.vitaminC, NutrientKind.antioxidants],
    benefits: [HealthBenefit.immunity, HealthBenefit.skin],
    funFact: 'Ароматнее садовой клубники за счёт большего числа эфирных масел.',
  ),
  ProductKnowledge(
    key: 'cowberry', displayName: 'Клюква болотная', emoji: '🔴',
    seasonMonths: [9, 10, 11],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC],
    benefits: [HealthBenefit.immunity, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'blackberry_arctic', displayName: 'Морошка', emoji: '🟡',
    seasonMonths: [7, 8],
    richIn: [NutrientKind.vitaminC, NutrientKind.antioxidants, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.skin],
    funFact: 'Северная ягода, в 3 раза больше витамина C, чем в апельсине.',
  ),
  ProductKnowledge(
    key: 'viburnum', displayName: 'Калина', emoji: '🔴',
    seasonMonths: [9, 10, 11],
    richIn: [NutrientKind.vitaminC, NutrientKind.antioxidants, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.heart],
    contraindications: [
      Contra(title: 'Гипотония', message: 'Снижает давление — осторожно',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'chokeberry', displayName: 'Арония (черноплодка)', emoji: '⚫',
    seasonMonths: [9, 10],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC, NutrientKind.fiber],
    benefits: [HealthBenefit.heart, HealthBenefit.immunity],
    contraindications: [
      Contra(title: 'Гипотония', message: 'Снижает давление',
          severity: ContraSeverity.caution),
    ],
  ),

  // ═══════════════ ФРУКТЫ (расширение) ═══════════════
  ProductKnowledge(
    key: 'pear_winter', displayName: 'Груша зимняя', emoji: '🍐',
    seasonMonths: [10, 11, 12],
    richIn: [NutrientKind.fiber, NutrientKind.vitaminC, NutrientKind.potassium],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart],
    funFact: 'Хорошо хранится до весны без потери витаминов.',
  ),
  ProductKnowledge(
    key: 'apple_green', displayName: 'Яблоко зелёное', emoji: '🍏',
    seasonMonths: [8, 9, 10, 11, 12],
    richIn: [NutrientKind.fiber, NutrientKind.antioxidants, NutrientKind.vitaminC],
    benefits: [HealthBenefit.digestion, HealthBenefit.weight, HealthBenefit.heart],
    funFact: 'Меньше сахара, чем в красных сортах — подходит для диабетиков.',
  ),
  ProductKnowledge(
    key: 'nectarine', displayName: 'Нектарин', emoji: '🍑',
    seasonMonths: [7, 8],
    richIn: [NutrientKind.vitaminA, NutrientKind.vitaminC, NutrientKind.potassium],
    benefits: [HealthBenefit.skin, HealthBenefit.eyes, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'grape_white', displayName: 'Виноград белый', emoji: '🍇',
    seasonMonths: [8, 9, 10],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminK, NutrientKind.potassium],
    benefits: [HealthBenefit.heart, HealthBenefit.skin],
    contraindications: [
      Contra(title: 'Диабет', message: 'Высокое содержание сахара',
          severity: ContraSeverity.warning),
    ],
  ),
  ProductKnowledge(
    key: 'cranberry_dried', displayName: 'Клюква сушёная', emoji: '🔴',
    seasonMonths: [11, 12, 1, 2],
    richIn: [NutrientKind.antioxidants, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.digestion],
    funFact: 'Сушёная хранится до года и не теряет полезных свойств.',
  ),
  ProductKnowledge(
    key: 'dates', displayName: 'Финики', emoji: '🟤',
    seasonMonths: [10, 11, 12],
    richIn: [NutrientKind.fiber, NutrientKind.potassium, NutrientKind.magnesium],
    benefits: [HealthBenefit.energy, HealthBenefit.heart, HealthBenefit.digestion],
    contraindications: [
      Contra(title: 'Диабет', message: 'Очень сладкие — ограничить',
          severity: ContraSeverity.caution),
    ],
    funFact: 'Естественный источник быстрой энергии для спортсменов.',
  ),
  ProductKnowledge(
    key: 'dried_apricot', displayName: 'Курага', emoji: '🟠',
    seasonMonths: [7, 8, 9],
    richIn: [NutrientKind.potassium, NutrientKind.fiber, NutrientKind.iron],
    benefits: [HealthBenefit.heart, HealthBenefit.energy, HealthBenefit.eyes],
  ),
  ProductKnowledge(
    key: 'raisins', displayName: 'Изюм', emoji: '🍇',
    seasonMonths: [8, 9, 10],
    richIn: [NutrientKind.iron, NutrientKind.potassium, NutrientKind.fiber],
    benefits: [HealthBenefit.energy, HealthBenefit.heart],
    contraindications: [
      Contra(title: 'Диабет', message: 'Сладкий, высокий ГИ',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'prunes', displayName: 'Чернослив', emoji: '🟤',
    seasonMonths: [9, 10, 11],
    richIn: [NutrientKind.fiber, NutrientKind.antioxidants, NutrientKind.potassium],
    benefits: [HealthBenefit.digestion, HealthBenefit.bones],
    funFact: 'Мягкое натуральное слабительное.',
  ),

  // ═══════════════ ОВОЩИ (расширение) ═══════════════
  ProductKnowledge(
    key: 'rutabaga', displayName: 'Брюква', emoji: '🟡',
    seasonMonths: [10, 11, 12, 1, 2],
    richIn: [NutrientKind.vitaminC, NutrientKind.fiber, NutrientKind.potassium],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'turnip', displayName: 'Репа', emoji: '⚪',
    seasonMonths: [9, 10, 11, 12],
    richIn: [NutrientKind.vitaminC, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'parsnip', displayName: 'Пастернак', emoji: '🟡',
    seasonMonths: [10, 11, 12, 1],
    richIn: [NutrientKind.fiber, NutrientKind.vitaminC, NutrientKind.vitaminB9],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'celery_root', displayName: 'Сельдерей корневой', emoji: '🌿',
    seasonMonths: [9, 10, 11, 12],
    richIn: [NutrientKind.fiber, NutrientKind.vitaminK, NutrientKind.potassium],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'celery_stalk', displayName: 'Сельдерей стеблевой', emoji: '🌿',
    seasonMonths: [7, 8, 9, 10],
    richIn: [NutrientKind.vitaminK, NutrientKind.fiber, NutrientKind.fiber],
    benefits: [HealthBenefit.weight, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'leek', displayName: 'Лук-порей', emoji: '🧅',
    seasonMonths: [9, 10, 11, 12, 1, 2],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminK, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'red_onion', displayName: 'Красный лук', emoji: '🧅',
    seasonMonths: [7, 8, 9],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC],
    benefits: [HealthBenefit.heart, HealthBenefit.immunity],
  ),
  ProductKnowledge(
    key: 'shallot', displayName: 'Шалот', emoji: '🧅',
    seasonMonths: [7, 8, 9],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC],
    benefits: [HealthBenefit.immunity, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'bell_pepper_yellow', displayName: 'Перец жёлтый', emoji: '🟡',
    seasonMonths: [7, 8, 9],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminA, NutrientKind.antioxidants],
    benefits: [HealthBenefit.immunity, HealthBenefit.skin, HealthBenefit.eyes],
  ),
  ProductKnowledge(
    key: 'chili', displayName: 'Перец чили', emoji: '🌶',
    seasonMonths: [7, 8, 9, 10],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC],
    benefits: [HealthBenefit.heart, HealthBenefit.weight],
    contraindications: [
      Contra(title: 'Гастрит', message: 'Острый — при проблемах ЖКТ осторожно',
          severity: ContraSeverity.warning),
      Contra(title: 'ГЭРБ', message: 'Может усиливать изжогу',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'kohlrabi', displayName: 'Кольраби', emoji: '🟢',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.vitaminC, NutrientKind.fiber, NutrientKind.potassium],
    benefits: [HealthBenefit.immunity, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'cauliflower', displayName: 'Цветная капуста', emoji: '⚪',
    seasonMonths: [6, 7, 8, 9, 10],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminK, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.bones, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'brussels_sprouts', displayName: 'Брюссельская капуста', emoji: '🟢',
    seasonMonths: [9, 10, 11, 12],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminK, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.bones],
    contraindications: [
      Contra(title: 'Гипотиреоз', message: 'Гойтрогены — при снижении щитовидки',
          severity: ContraSeverity.caution),
    ],
  ),
  ProductKnowledge(
    key: 'savoy_cabbage', displayName: 'Капуста савойская', emoji: '🥬',
    seasonMonths: [9, 10, 11],
    richIn: [NutrientKind.vitaminC, NutrientKind.vitaminK, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'daikon', displayName: 'Дайкон', emoji: '⚪',
    seasonMonths: [10, 11, 12],
    richIn: [NutrientKind.vitaminC, NutrientKind.fiber],
    benefits: [HealthBenefit.digestion, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'sweet_potato', displayName: 'Батат', emoji: '🍠',
    seasonMonths: [9, 10, 11, 12],
    richIn: [NutrientKind.vitaminA, NutrientKind.fiber, NutrientKind.potassium],
    benefits: [HealthBenefit.energy, HealthBenefit.eyes, HealthBenefit.digestion],
    funFact: 'Медленные углеводы — идеален для диабетиков.',
  ),
  ProductKnowledge(
    key: 'artichoke', displayName: 'Артишок', emoji: '🟢',
    seasonMonths: [5, 6, 7],
    richIn: [NutrientKind.fiber, NutrientKind.vitaminK, NutrientKind.antioxidants],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'asparagus_green', displayName: 'Спаржа зелёная', emoji: '🌱',
    seasonMonths: [4, 5, 6],
    richIn: [NutrientKind.vitaminB9, NutrientKind.fiber, NutrientKind.vitaminK],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart, HealthBenefit.weight],
  ),

  // ═══════════════ ЗЕЛЕНЬ / ТРАВЫ (расширение) ═══════════════
  ProductKnowledge(
    key: 'mint', displayName: 'Мята', emoji: '🌿',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminA],
    benefits: [HealthBenefit.digestion, HealthBenefit.sleep],
    funFact: 'Успокаивает ЖКТ и улучшает пищеварение.',
  ),
  ProductKnowledge(
    key: 'rosemary', displayName: 'Розмарин', emoji: '🌿',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminA],
    benefits: [HealthBenefit.brain, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'thyme', displayName: 'Тимьян (чабрец)', emoji: '🌿',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminC],
    benefits: [HealthBenefit.immunity, HealthBenefit.digestion],
    funFact: 'Природный антисептик — добавляют в чай при простуде.',
  ),
  ProductKnowledge(
    key: 'sage', displayName: 'Шалфей', emoji: '🌿',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminK],
    benefits: [HealthBenefit.digestion, HealthBenefit.brain],
  ),
  ProductKnowledge(
    key: 'oregano', displayName: 'Орегано', emoji: '🌿',
    seasonMonths: [6, 7, 8, 9],
    richIn: [NutrientKind.antioxidants, NutrientKind.vitaminK],
    benefits: [HealthBenefit.immunity, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'arugula', displayName: 'Руккола', emoji: '🥬',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.vitaminK, NutrientKind.vitaminA, NutrientKind.fiber],
    benefits: [HealthBenefit.bones, HealthBenefit.eyes, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'chard', displayName: 'Мангольд', emoji: '🥬',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.vitaminK, NutrientKind.vitaminA, NutrientKind.magnesium],
    benefits: [HealthBenefit.bones, HealthBenefit.eyes, HealthBenefit.heart],
  ),
  ProductKnowledge(
    key: 'sorrel_wild', displayName: 'Щавель лесной', emoji: '🍃',
    seasonMonths: [4, 5, 6],
    richIn: [NutrientKind.vitaminC, NutrientKind.iron],
    benefits: [HealthBenefit.immunity, HealthBenefit.energy],
  ),

  // ═══════════════ ГРИБЫ (расширение) ═══════════════
  ProductKnowledge(
    key: 'porcini', displayName: 'Белый гриб', emoji: '🍄',
    seasonMonths: [7, 8, 9, 10],
    richIn: [NutrientKind.vitaminD, NutrientKind.vitaminB12, NutrientKind.fiber],
    benefits: [HealthBenefit.bones, HealthBenefit.immunity, HealthBenefit.energy],
    funFact: 'Царский гриб — сочетает вкус и полноценный белок.',
  ),
  ProductKnowledge(
    key: 'chanterelle', displayName: 'Лисички', emoji: '🍄',
    seasonMonths: [6, 7, 8, 9],
    richIn: [NutrientKind.vitaminD, NutrientKind.antioxidants],
    benefits: [HealthBenefit.immunity, HealthBenefit.bones],
    funFact: 'Не бывают червивыми — природный антипаразитик.',
  ),
  ProductKnowledge(
    key: 'oyster_mushroom', displayName: 'Вешенки', emoji: '🍄',
    seasonMonths: [9, 10, 11, 12, 1, 2, 3, 4],
    richIn: [NutrientKind.vitaminD, NutrientKind.vitaminB12, NutrientKind.fiber],
    benefits: [HealthBenefit.bones, HealthBenefit.immunity, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'shiitake', displayName: 'Шиитаке', emoji: '🍄',
    seasonMonths: [5, 6, 7, 8, 9, 10],
    richIn: [NutrientKind.vitaminD, NutrientKind.antioxidants, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.heart],
    funFact: 'Лентинан — уникальное соединение для иммунитета.',
  ),
  ProductKnowledge(
    key: 'oyster_mushroom_winter', displayName: 'Опята зимние', emoji: '🍄',
    seasonMonths: [10, 11, 12, 1, 2],
    richIn: [NutrientKind.vitaminD, NutrientKind.vitaminB12, NutrientKind.fiber],
    benefits: [HealthBenefit.immunity, HealthBenefit.bones],
  ),

  // ═══════════════ БЕЛОК / РЫБА (расширение) ═══════════════
  ProductKnowledge(
    key: 'herring', displayName: 'Сельдь', emoji: '🐟',
    seasonMonths: [10, 11, 12, 1, 2],
    richIn: [NutrientKind.omega3, NutrientKind.vitaminD, NutrientKind.vitaminB12],
    benefits: [HealthBenefit.heart, HealthBenefit.brain, HealthBenefit.bones],
  ),
  ProductKnowledge(
    key: 'sardine', displayName: 'Сардина', emoji: '🐟',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.omega3, NutrientKind.vitaminD, NutrientKind.calcium],
    benefits: [HealthBenefit.heart, HealthBenefit.bones, HealthBenefit.brain],
    funFact: 'Мелкие кости — источник кальция.',
  ),
  ProductKnowledge(
    key: 'halibut', displayName: 'Палтус', emoji: '🐟',
    seasonMonths: [7, 8, 9, 10],
    richIn: [NutrientKind.omega3, NutrientKind.vitaminD, NutrientKind.vitaminB12],
    benefits: [HealthBenefit.heart, HealthBenefit.brain],
  ),
  ProductKnowledge(
    key: 'trout', displayName: 'Форель', emoji: '🐟',
    seasonMonths: [5, 6, 7, 8, 9],
    richIn: [NutrientKind.omega3, NutrientKind.vitaminD, NutrientKind.vitaminB12],
    benefits: [HealthBenefit.heart, HealthBenefit.brain, HealthBenefit.eyes],
  ),
  ProductKnowledge(
    key: 'pollock', displayName: 'Минтай', emoji: '🐟',
    richIn: [NutrientKind.omega3, NutrientKind.vitaminB12, NutrientKind.zinc],
    benefits: [HealthBenefit.heart, HealthBenefit.brain, HealthBenefit.weight],
  ),

  // ═══════════════ ОРЕХИ / СЕМЕЧКИ (расширение) ═══════════════
  ProductKnowledge(
    key: 'hazelnuts', displayName: 'Лесной орех', emoji: '🌰',
    seasonMonths: [8, 9, 10],
    richIn: [NutrientKind.vitaminE, NutrientKind.magnesium, NutrientKind.omega3],
    benefits: [HealthBenefit.heart, HealthBenefit.brain, HealthBenefit.skin],
  ),
  ProductKnowledge(
    key: 'cashews', displayName: 'Кешью', emoji: '🌰',
    richIn: [NutrientKind.magnesium, NutrientKind.zinc, NutrientKind.iron],
    benefits: [HealthBenefit.bones, HealthBenefit.energy, HealthBenefit.immunity],
  ),
  ProductKnowledge(
    key: 'pistachios', displayName: 'Фисташки', emoji: '🌰',
    richIn: [NutrientKind.antioxidants, NutrientKind.magnesium, NutrientKind.fiber],
    benefits: [HealthBenefit.heart, HealthBenefit.eyes, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'pine_nuts', displayName: 'Кедровые орехи', emoji: '🌰',
    seasonMonths: [9, 10, 11],
    richIn: [NutrientKind.omega3, NutrientKind.magnesium, NutrientKind.zinc],
    benefits: [HealthBenefit.brain, HealthBenefit.heart, HealthBenefit.immunity],
  ),
  ProductKnowledge(
    key: 'pumpkin_seeds', displayName: 'Тыквенные семечки', emoji: '🌰',
    seasonMonths: [9, 10, 11],
    richIn: [NutrientKind.zinc, NutrientKind.magnesium, NutrientKind.omega3],
    benefits: [HealthBenefit.immunity, HealthBenefit.bones, HealthBenefit.sleep],
    funFact: 'Богаты цинком — важны для мужского здоровья.',
  ),
  ProductKnowledge(
    key: 'sunflower_seeds', displayName: 'Семечки подсолнечника', emoji: '🌰',
    seasonMonths: [8, 9, 10],
    richIn: [NutrientKind.vitaminE, NutrientKind.magnesium, NutrientKind.fiber],
    benefits: [HealthBenefit.heart, HealthBenefit.skin, HealthBenefit.bones],
  ),
  ProductKnowledge(
    key: 'sesame', displayName: 'Кунжут', emoji: '⚪',
    richIn: [NutrientKind.calcium, NutrientKind.iron, NutrientKind.omega3],
    benefits: [HealthBenefit.bones, HealthBenefit.energy],
    funFact: 'Один из лучших растительных источников кальция.',
  ),
  ProductKnowledge(
    key: 'flax_seeds', displayName: 'Семена льна', emoji: '🌰',
    richIn: [NutrientKind.omega3, NutrientKind.fiber, NutrientKind.antioxidants],
    benefits: [HealthBenefit.heart, HealthBenefit.digestion, HealthBenefit.skin],
    funFact: 'Лигнаны — фитоэстрогены, особенно полезны женщинам.',
  ),
  ProductKnowledge(
    key: 'chia', displayName: 'Семена чиа', emoji: '⚫',
    richIn: [NutrientKind.omega3, NutrientKind.fiber, NutrientKind.calcium],
    benefits: [HealthBenefit.weight, HealthBenefit.digestion, HealthBenefit.bones],
    funFact: 'Впитывают воды в 12 раз больше своего веса.',
  ),

  // ═══════════════ КРУПЫ (расширение) ═══════════════
  ProductKnowledge(
    key: 'bulgur', displayName: 'Булгур', emoji: '🌾',
    richIn: [NutrientKind.fiber, NutrientKind.magnesium, NutrientKind.iron],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart, HealthBenefit.energy],
  ),
  ProductKnowledge(
    key: 'millet', displayName: 'Пшено', emoji: '🌾',
    richIn: [NutrientKind.magnesium, NutrientKind.fiber, NutrientKind.iron],
    benefits: [HealthBenefit.heart, HealthBenefit.digestion, HealthBenefit.energy],
  ),
  ProductKnowledge(
    key: 'pearl_barley', displayName: 'Перловка', emoji: '🌾',
    richIn: [NutrientKind.fiber, NutrientKind.magnesium, NutrientKind.vitaminB9],
    benefits: [HealthBenefit.digestion, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'spelt', displayName: 'Полба', emoji: '🌾',
    richIn: [NutrientKind.fiber, NutrientKind.magnesium, NutrientKind.iron],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart, HealthBenefit.energy],
    funFact: 'Древний злак, содержит больше белка, чем пшеница.',
  ),
  ProductKnowledge(
    key: 'wild_rice', displayName: 'Дикий рис', emoji: '🍚',
    richIn: [NutrientKind.fiber, NutrientKind.magnesium, NutrientKind.antioxidants],
    benefits: [HealthBenefit.digestion, HealthBenefit.heart, HealthBenefit.weight],
  ),
  ProductKnowledge(
    key: 'red_rice', displayName: 'Красный рис', emoji: '🍚',
    richIn: [NutrientKind.antioxidants, NutrientKind.magnesium, NutrientKind.fiber],
    benefits: [HealthBenefit.heart, HealthBenefit.digestion],
  ),
  ProductKnowledge(
    key: 'freekeh', displayName: 'Фрике', emoji: '🌾',
    richIn: [NutrientKind.fiber, NutrientKind.iron, NutrientKind.magnesium],
    benefits: [HealthBenefit.digestion, HealthBenefit.weight],
    funFact: 'Копчёный молодой пшеничный злак с низким ГИ.',
  ),

  // ═══════════════ ПРОЧЕЕ ═══════════════
  ProductKnowledge(
    key: 'seaweed', displayName: 'Морская капуста', emoji: '🌿',
    seasonMonths: [5, 6, 7, 8, 9, 10],
    richIn: [NutrientKind.iron, NutrientKind.calcium, NutrientKind.vitaminK],
    benefits: [HealthBenefit.immunity, HealthBenefit.bones, HealthBenefit.eyes],
    funFact: 'Йод в легкоусвояемой форме — поддержка щитовидки.',
  ),
  ProductKnowledge(
    key: 'spirulina', displayName: 'Спирулина', emoji: '🟢',
    richIn: [NutrientKind.iron, NutrientKind.vitaminB12, NutrientKind.antioxidants],
    benefits: [HealthBenefit.energy, HealthBenefit.immunity],
    funFact: '60% белка в сухом весе — рекорд среди растений.',
  ),
  ProductKnowledge(
    key: 'olive_oil', displayName: 'Оливковое масло', emoji: '🫒',
    richIn: [NutrientKind.omega3, NutrientKind.vitaminE, NutrientKind.antioxidants],
    benefits: [HealthBenefit.heart, HealthBenefit.skin, HealthBenefit.brain],
    funFact: 'Extra virgin сохраняет полифенолы — антиоксиданты.',
  ),
];