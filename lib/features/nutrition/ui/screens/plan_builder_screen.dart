// features/nutrition/ui/screens/plan_builder_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_models.dart';
import '../../models/nutrition_program.dart';
import '../../providers/nutrition_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM — «Терракота» (warm editorial)
// ═══════════════════════════════════════════════════════════════════
class _T {
  // Фоны
  static const bg          = Color(0xFFF9F5EE); // тёплый крем
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF2ECE2);

  // Текст
  static const ink         = Color(0xFF2B2420); // тёплый уголь
  static const inkSoft     = Color(0xFF5C544C);
  static const muted       = Color(0xFF9A8F82);
  static const faint       = Color(0xFFCFC5B8);

  // Акценты
  static const terracotta      = Color(0xFFCA6D4E);
  static const terracottaDark  = Color(0xFFA5502F);
  static const terracottaLight = Color(0xFFF7E4DB);

  static const sage        = Color(0xFF7A9678);
  static const sageLight   = Color(0xFFE6EDE2);

  static const mustard     = Color(0xFFD9A83F);
  static const mustardLight= Color(0xFFFCF0D4);

  static const sky         = Color(0xFF6E96B8);
  static const skyLight    = Color(0xFFE3EBF2);

  static const rose        = Color(0xFFC86B7A);
  static const roseLight   = Color(0xFFF7E1E5);

  static const border      = Color(0xFFE8DFD2);
  static const borderStrong= Color(0xFFD9CCB8);
}

// ─── Типографика ───
TextStyle _display({
  double size = 22,
  FontWeight weight = FontWeight.w600,
  Color color = _T.ink,
  double height = 1.15,
}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: -0.3,
    );

TextStyle _body({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _T.ink,
  double height = 1.4,
}) =>
    GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

TextStyle _mono({
  double size = 11,
  FontWeight weight = FontWeight.w600,
  Color color = _T.muted,
  double letterSpacing = 0.6,
}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );

// ═══════════════════════════════════════════════════════════════════
//  МОДЕЛЬ ВЫБРАННОЙ ЕДЫ
// ═══════════════════════════════════════════════════════════════════
class _SelectedFood {
  final bool isProduct;
  final String id;
  final String name;
  final double baseCalories;
  final double portions;
  final double grams;

  /// Калории исключённых ингредиентов на 1 порцию рецепта
  final double excludedCaloriesPerPortion;
  final Set<String> excludedIngredientIds;

  _SelectedFood({
    required this.isProduct,
    required this.id,
    required this.name,
    required this.baseCalories,
    this.portions = 1.0,
    this.grams = 100.0,
    this.excludedCaloriesPerPortion = 0.0,
    Set<String>? excludedIngredientIds,
  }) : excludedIngredientIds = excludedIngredientIds ?? {};

  double get netCaloriesPerPortion {
    final v = baseCalories - excludedCaloriesPerPortion;
    return v < 0 ? 0 : v;
  }

  double get totalCalories => isProduct
      ? (baseCalories * (grams / 100.0))
      : (netCaloriesPerPortion * portions);

  _SelectedFood copyWith({
    double? portions,
    double? grams,
    double? excludedCaloriesPerPortion,
    Set<String>? excludedIngredientIds,
  }) {
    return _SelectedFood(
      isProduct: isProduct,
      id: id,
      name: name,
      baseCalories: baseCalories,
      portions: portions ?? this.portions,
      grams: grams ?? this.grams,
      excludedCaloriesPerPortion:
      excludedCaloriesPerPortion ?? this.excludedCaloriesPerPortion,
      excludedIngredientIds:
      excludedIngredientIds ?? this.excludedIngredientIds,
    );
  }
}

class _PlannedMeal {
  final MealType type;
  final List<_SelectedFood> foods;

  _PlannedMeal({required this.type, List<_SelectedFood>? foods})
      : foods = foods ?? [];
}

// ═══════════════════════════════════════════════════════════════════
//  ЭКРАН СОЗДАНИЯ ПРОГРАММЫ
// ═══════════════════════════════════════════════════════════════════
class PlanBuilderScreen extends StatefulWidget {
  const PlanBuilderScreen({super.key});

  @override
  State<PlanBuilderScreen> createState() => _PlanBuilderScreenState();
}

class _PlanBuilderScreenState extends State<PlanBuilderScreen> {
  final _nameCtrl    = TextEditingController(text: 'Моя программа');
  final _kcalCtrl    = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl     = TextEditingController();
  final _carbsCtrl   = TextEditingController();

  int _durationDays = 7;
  DateTime _startDate = DateTime.now();
  late DateTime _selectedDate;
  bool _creating = false;

  final Map<String, List<_PlannedMeal>> _dailyMeals = {};
  final Map<String, PlanDayType> _dailyTypes = {};

  String? _backgroundImage;
  final List<String> _presetBackgrounds = [
    'assets/images/nature_hero3.jpg',
    'assets/images/nature_hero5.jpg',
    'assets/images/nature_hero8.jpg',
    'assets/images/nature_hero12.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = _startDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NutritionProvider>();
      final goals = provider.defaultGoals;
      final profile = provider.userProfile;
      if (goals != null) {
        _kcalCtrl.text    = goals.calories.round().toString();
        _proteinCtrl.text = goals.protein.round().toString();
        _fatCtrl.text     = goals.fat.round().toString();
        _carbsCtrl.text   = goals.carbs.round().toString();
      } else if (profile != null) {
        _kcalCtrl.text    = profile.targetCalories.round().toString();
        _proteinCtrl.text = profile.recommendedProtein.round().toString();
        _fatCtrl.text     = profile.recommendedFat.round().toString();
        _carbsCtrl.text   = profile.recommendedCarbs.round().toString();
      }
      _initDailyMeals();
      setState(() {});
    });
  }

  void _initDailyMeals() {
    _dailyMeals.clear();
    _dailyTypes.clear();
    for (int i = 0; i < _durationDays; i++) {
      final date = _startDate.add(Duration(days: i));
      final key = _dateKey(date);
      _dailyMeals[key] = [
        _PlannedMeal(type: MealType.breakfast),
        _PlannedMeal(type: MealType.lunch),
        _PlannedMeal(type: MealType.dinner),
      ];
      _dailyTypes[key] = PlanDayType.regular;
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbsCtrl.dispose();
    super.dispose();
  }

  double get _kcal    => double.tryParse(_kcalCtrl.text) ?? 0;
  double get _protein => double.tryParse(_proteinCtrl.text) ?? 0;
  double get _fat     => double.tryParse(_fatCtrl.text) ?? 0;
  double get _carbs   => double.tryParse(_carbsCtrl.text) ?? 0;

  List<DateTime> get _allDates =>
      List.generate(_durationDays, (i) => _startDate.add(Duration(days: i)));

  Future<void> _create() async {
    if (_kcal <= 0 || _protein <= 0 || _fat <= 0 || _carbs <= 0) {
      _info('Заполни цели', 'Все значения КБЖУ должны быть больше нуля');
      return;
    }
    setState(() => _creating = true);
    try {
      final Map<
          String,
          List<
              ({
              MealType type,
              String? templateId,
              double portions,
              double grams,
              List<String> excluded
              })>> dailyPlansMap = {};

      for (final date in _allDates) {
        final key = _dateKey(date);
        final mealsForDay = <({
        MealType type,
        String? templateId,
        double portions,
        double grams,
        List<String> excluded
        })>[];

        for (final plannedMeal in _dailyMeals[key] ?? []) {
          if (plannedMeal.foods.isEmpty) {
            mealsForDay.add((
            type: plannedMeal.type,
            templateId: null,
            portions: 1.0,
            grams: 100.0,
            excluded: []
            ));
          } else {
            for (final food in plannedMeal.foods) {
              final templateId =
              food.isProduct ? 'PROD:${food.id}' : food.id;
              mealsForDay.add((
              type: plannedMeal.type,
              templateId: templateId,
              portions: food.portions,
              grams: food.grams,
              excluded: food.excludedIngredientIds.toList(),
              ));
            }
          }
        }
        dailyPlansMap[key] = mealsForDay;
      }

      await context.read<NutritionProvider>().createProgram(
        name: _nameCtrl.text.trim().isEmpty
            ? 'Моя программа'
            : _nameCtrl.text.trim(),
        startDate: _startDate,
        endDate: _startDate.add(Duration(days: _durationDays - 1)),
        targetCalories: _kcal,
        targetProtein: _protein,
        targetFat: _fat,
        targetCarbs: _carbs,
        dailyPlans: dailyPlansMap,
        backgroundImage: _backgroundImage,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _info(String t, String m) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _T.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(t, style: _display(size: 20, weight: FontWeight.w600)),
      content: Text(m, style: _body(size: 14, color: _T.inkSoft)),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('ОК',
              style: _body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: _T.terracotta)),
        ),
      ],
    ),
  );

  Future<void> _addFoodToMeal(String dateKey, int mealIndex) async {
    final provider = context.read<NutritionProvider>();
    final selected = await showModalBottomSheet<_SelectedFood>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EnhancedFoodPicker(provider: provider),
    );
    if (selected != null && mounted) {
      setState(() {
        _dailyMeals[dateKey]![mealIndex].foods.add(selected);
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _addMealType() async {
    final currentMeals = _dailyMeals[_dateKey(_selectedDate)]!;
    final availableTypes = MealType.values
        .where((t) => !currentMeals.any((pm) => pm.type == t))
        .toList();

    if (availableTypes.isEmpty) {
      _info('Все приемы добавлены',
          'Для этого дня уже выбраны все типы приемов пищи.');
      return;
    }

    final selectedType = await showModalBottomSheet<MealType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _T.faint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Добавить приём',
                  style: _display(size: 24, weight: FontWeight.w600)),
              const SizedBox(height: 20),
              ...availableTypes.map(
                    (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(ctx, t),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _T.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _T.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _T.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(t.emoji,
                                style: const TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(t.displayName,
                                style: _body(
                                    size: 15, weight: FontWeight.w700)),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: _T.faint),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedType != null && mounted) {
      setState(() => _dailyMeals[_dateKey(_selectedDate)]!
          .add(_PlannedMeal(type: selectedType)));
      HapticFeedback.selectionClick();
    }
  }

  void _applyCurrentDayToAll() {
    final currentDayMeals = _dailyMeals[_dateKey(_selectedDate)]!;
    final currentDayType =
        _dailyTypes[_dateKey(_selectedDate)] ?? PlanDayType.regular;

    final copiedMeals = currentDayMeals
        .map((m) => _PlannedMeal(
      type: m.type,
      foods: m.foods
          .map((f) => _SelectedFood(
        isProduct: f.isProduct,
        id: f.id,
        name: f.name,
        baseCalories: f.baseCalories,
        portions: f.portions,
        grams: f.grams,
        excludedCaloriesPerPortion: f.excludedCaloriesPerPortion,
        excludedIngredientIds:
        Set.from(f.excludedIngredientIds),
      ))
          .toList(),
    ))
        .toList();

    setState(() {
      for (final date in _allDates) {
        final key = _dateKey(date);
        _dailyMeals[key] = copiedMeals
            .map((m) => _PlannedMeal(
          type: m.type,
          foods: m.foods
              .map((f) => _SelectedFood(
            isProduct: f.isProduct,
            id: f.id,
            name: f.name,
            baseCalories: f.baseCalories,
            portions: f.portions,
            grams: f.grams,
            excludedCaloriesPerPortion:
            f.excludedCaloriesPerPortion,
            excludedIngredientIds:
            Set.from(f.excludedIngredientIds),
          ))
              .toList(),
        ))
            .toList();
        _dailyTypes[key] = currentDayType;
      }
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: _T.sage),
            const SizedBox(width: 10),
            Text('Применено ко всем дням',
                style: _body(size: 13, weight: FontWeight.w600)),
          ],
        ),
        backgroundColor: _T.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _T.border),
        ),
      ),
    );
  }

  void _cycleDayType() {
    final key = _dateKey(_selectedDate);
    final current = _dailyTypes[key] ?? PlanDayType.regular;
    PlanDayType next;
    if (current == PlanDayType.regular) {
      next = PlanDayType.cheat;
    } else if (current == PlanDayType.cheat) {
      next = PlanDayType.vacation;
    } else {
      next = PlanDayType.regular;
    }
    setState(() => _dailyTypes[key] = next);
    HapticFeedback.selectionClick();
  }

  void _showBackgroundPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _T.faint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Обложка программы',
                  style: _display(size: 24, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Выберите визуальный характер плана',
                  style: _body(size: 13, color: _T.muted)),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _bgOption(null, 'Без обложки', Icons.block_rounded),
                  ..._presetBackgrounds.map((p) => _bgOption(p, null, null)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bgOption(String? path, String? label, IconData? icon) {
    final isSel = _backgroundImage == path;
    return GestureDetector(
      onTap: () {
        setState(() => _backgroundImage = path);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _T.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? _T.terracotta : _T.border,
            width: isSel ? 2 : 1,
          ),
          image: path != null
              ? DecorationImage(image: AssetImage(path), fit: BoxFit.cover)
              : null,
        ),
        child: path == null
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Icons.block_rounded,
                  size: 22, color: _T.muted),
              const SizedBox(height: 6),
              Text(label ?? '',
                  style: _body(
                      size: 11,
                      weight: FontWeight.w600,
                      color: _T.muted)),
            ],
          ),
        )
            : null,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final currentKey = _dateKey(_selectedDate);
    final currentMeals = _dailyMeals[currentKey] ?? [];
    final currentDayType = _dailyTypes[currentKey] ?? PlanDayType.regular;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 130),
                children: [
                  _hero(context),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('01', 'Название и период'),
                        const SizedBox(height: 12),
                        _namePeriodCard(),
                        const SizedBox(height: 32),
                        _sectionLabel('02', 'Цели на день'),
                        const SizedBox(height: 12),
                        _goalsCard(),
                        const SizedBox(height: 32),
                        _sectionLabel('03', 'Расписание'),
                        const SizedBox(height: 12),
                        _scheduleCard(
                            currentKey, currentMeals, currentDayType),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _createButton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero ───
  Widget _hero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _circleBtn(Icons.close_rounded, () => Navigator.pop(context)),
              const Spacer(),
              _bgButton(),
            ],
          ),
          const SizedBox(height: 28),
          Text('Новая программа',
              style: _display(size: 36, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Задай план — и следуй ему',
              style: _body(size: 15, color: _T.muted)),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _T.surface,
          shape: BoxShape.circle,
          border: Border.all(color: _T.border, width: 1.2),
        ),
        child: Icon(icon, size: 18, color: _T.ink),
      ),
    );
  }

  // ─── Крупная кнопка выбора обложки ───
  Widget _bgButton() {
    final hasBg = _backgroundImage != null;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showBackgroundPicker();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: hasBg ? _T.surfaceAlt : _T.terracottaLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: hasBg
                ? _T.terracotta
                : _T.terracotta.withOpacity(0.4),
            width: 1.6,
          ),
          image: hasBg
              ? DecorationImage(
            image: AssetImage(_backgroundImage!),
            fit: BoxFit.cover,
          )
              : null,
          boxShadow: [
            BoxShadow(
              color: _T.terracotta.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: hasBg
            ? Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _T.terracotta,
                  shape: BoxShape.circle,
                  border: Border.all(color: _T.bg, width: 2),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 12, color: Colors.white),
              ),
            ),
          ],
        )
            : const Icon(
          Icons.add_photo_alternate_outlined,
          size: 26,
          color: _T.terracotta,
        ),
      ),
    );
  }

  // ─── Section label ───
  Widget _sectionLabel(String num, String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(num,
            style: GoogleFonts.fraunces(
              fontSize: 34,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              color: _T.terracotta,
              height: 0.85,
            )),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(title.toUpperCase(),
              style: _mono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: _T.inkSoft,
                  letterSpacing: 1.8)),
        ),
      ],
    );
  }

  // ─── Name & period ───
  Widget _namePeriodCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('НАЗВАНИЕ',
              style: _mono(
                  size: 10, weight: FontWeight.w700, letterSpacing: 1.8)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            style: _display(size: 22, weight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'Моя программа',
              hintStyle: _display(
                  size: 22, weight: FontWeight.w600, color: _T.faint),
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: _T.border),
          const SizedBox(height: 20),
          Text('ПЕРИОД',
              style: _mono(
                  size: 10, weight: FontWeight.w700, letterSpacing: 1.8)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _periodBtn('7 дней', 7)),
              const SizedBox(width: 10),
              Expanded(child: _periodBtn('30 дней', 30)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodBtn(String label, int days) {
    final sel = _durationDays == days;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _durationDays = days;
          _initDailyMeals();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? _T.ink : _T.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: _body(
                size: 14,
                weight: FontWeight.w700,
                color: sel ? Colors.white : _T.ink)),
      ),
    );
  }

  // ─── Goals ───
  Widget _goalsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        children: [
          _goalTile('Калории', _kcalCtrl, 'ккал', _T.terracotta,
              _T.terracottaLight, Icons.local_fire_department_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _goalTile('Белки', _proteinCtrl, 'г', _T.sage,
                    _T.sageLight, Icons.eco_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _goalTile('Жиры', _fatCtrl, 'г', _T.mustard,
                    _T.mustardLight, Icons.opacity_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _goalTile('Углев.', _carbsCtrl, 'г', _T.sky,
                    _T.skyLight, Icons.grain_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              final p = context.read<NutritionProvider>().userProfile;
              if (p == null) return;
              setState(() {
                _kcalCtrl.text = p.targetCalories.round().toString();
                _proteinCtrl.text = p.recommendedProtein.round().toString();
                _fatCtrl.text = p.recommendedFat.round().toString();
                _carbsCtrl.text = p.recommendedCarbs.round().toString();
              });
            },
            icon: const Icon(Icons.auto_awesome_rounded,
                size: 16, color: _T.terracotta),
            label: Text('Взять из профиля',
                style: _body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: _T.terracotta)),
          ),
        ],
      ),
    );
  }

  Widget _goalTile(String label, TextEditingController c, String unit,
      Color accent, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 6),
              Text(label.toUpperCase(),
                  style: _mono(
                      size: 9,
                      weight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: c,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: _display(size: 24, weight: FontWeight.w600,
                      color: accent),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle: _display(
                        size: 24,
                        weight: FontWeight.w600,
                        color: accent.withOpacity(0.35)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: _body(
                        size: 11,
                        weight: FontWeight.w600,
                        color: accent.withOpacity(0.7))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Schedule ───
  Widget _scheduleCard(
      String currentKey, List<_PlannedMeal> currentMeals, PlanDayType dayType) {
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _datePicker(),
          Divider(height: 1, color: _T.border),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${_fmt(_selectedDate)}',
                          style: _display(
                              size: 20, weight: FontWeight.w600)),
                    ),
                    _applyAllBtn(),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  currentMeals.length,
                      (i) => _mealCard(currentKey, currentMeals, i),
                ),
                const SizedBox(height: 8),
                _addMealBtn(),
                const SizedBox(height: 16),
                _dayTypeBtn(dayType),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePicker() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: _allDates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final date = _allDates[i];
          final isSel = _sameDay(date, _selectedDate);
          final dayType = _dailyTypes[_dateKey(date)] ?? PlanDayType.regular;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDate = date);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? _T.terracotta : _T.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_weekShort(date.weekday),
                      style: _mono(
                          size: 9,
                          weight: FontWeight.w700,
                          color: isSel
                              ? Colors.white.withOpacity(0.85)
                              : _T.muted,
                          letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text('${date.day}',
                      style: _display(
                          size: 20,
                          weight: FontWeight.w600,
                          color: isSel ? Colors.white : _T.ink)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 14,
                    child: dayType != PlanDayType.regular
                        ? Text(dayType.emoji,
                        style: const TextStyle(fontSize: 12))
                        : Text(_monthRuShort(date.month),
                        style: _body(
                            size: 10,
                            weight: FontWeight.w600,
                            color: isSel
                                ? Colors.white.withOpacity(0.7)
                                : _T.muted)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _applyAllBtn() {
    return InkWell(
      onTap: _applyCurrentDayToAll,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _T.skyLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.copy_all_rounded, size: 14, color: _T.sky),
            const SizedBox(width: 6),
            Text('На все дни',
                style: _body(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _T.sky)),
          ],
        ),
      ),
    );
  }

  Widget _mealCard(
      String key, List<_PlannedMeal> all, int mealIndex) {
    final meal = all[mealIndex];
    final hasFoods = meal.foods.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _T.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child:
                Text(meal.type.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(meal.type.displayName,
                    style: _display(size: 17, weight: FontWeight.w600)),
              ),
              InkWell(
                onTap: () =>
                    setState(() => all.removeAt(mealIndex)),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.remove_circle_outline_rounded,
                      size: 20, color: _T.rose),
                ),
              ),
            ],
          ),
          if (hasFoods) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: List.generate(meal.foods.length, (fi) {
                  final food = meal.foods[fi];
                  return _foodRow(
                    food,
                    isLast: fi == meal.foods.length - 1,
                    onRemove: () =>
                        setState(() => meal.foods.removeAt(fi)),
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _addFoodToMeal(key, mealIndex),
            borderRadius: BorderRadius.circular(12),
            child: DashedBorder(
              color: _T.borderStrong,
              strokeWidth: 1.2,
              gap: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 18, color: _T.inkSoft),
                    const SizedBox(width: 6),
                    Text(
                      hasFoods ? 'Добавить ещё' : 'Выбрать еду',
                      style: _body(
                          size: 13,
                          weight: FontWeight.w700,
                          color: _T.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodRow(_SelectedFood food,
      {required bool isLast, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: !isLast
          ? BoxDecoration(
          border: Border(
              bottom: BorderSide(color: _T.border, width: 1)))
          : null,
      child: Row(
        children: [
          Icon(
            food.isProduct
                ? Icons.apple_rounded
                : Icons.restaurant_menu_rounded,
            size: 16,
            color: food.isProduct ? _T.sage : _T.sky,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name,
                    style: _body(size: 13, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (!food.isProduct && food.portions != 1.0)
                  Text('Порция ${food.portions}x',
                      style: _body(size: 11, color: _T.muted)),
                if (food.isProduct && food.grams != 100.0)
                  Text('Вес ${food.grams.toInt()} г',
                      style: _body(size: 11, color: _T.muted)),
                if (food.excludedIngredientIds.isNotEmpty)
                  Text('Без ${food.excludedIngredientIds.length} инг.',
                      style: _body(size: 11, color: _T.rose)),
              ],
            ),
          ),
          Text('${food.totalCalories.round()}',
              style: _mono(
                  size: 12,
                  weight: FontWeight.w700,
                  color: _T.terracotta)),
          const SizedBox(width: 3),
          Text('ккал',
              style: _body(size: 10, color: _T.muted)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child:
              Icon(Icons.close_rounded, size: 16, color: _T.faint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addMealBtn() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addMealType,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('Добавить приём пищи',
            style: _body(size: 13, weight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _T.ink,
          side: const BorderSide(color: _T.borderStrong, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _dayTypeBtn(PlanDayType type) {
    final isRegular = type == PlanDayType.regular;
    return InkWell(
      onTap: _cycleDayType,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRegular ? _T.surfaceAlt : _T.mustardLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ТИП ДНЯ',
                      style: _mono(
                          size: 9,
                          weight: FontWeight.w700,
                          letterSpacing: 1.4)),
                  const SizedBox(height: 2),
                  Text(type.label,
                      style:
                      _body(size: 14, weight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.swap_horiz_rounded,
                size: 18, color: _T.muted),
          ],
        ),
      ),
    );
  }

  // ─── Плавающая кнопка создания (поверх контента) ───
  Widget _createButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _T.terracotta.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: _T.terracotta,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _creating ? null : _create,
          child: Center(
            child: _creating
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Создать программу',
                    style: _body(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded,
                    size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekShort(int wd) =>
      const ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'][wd - 1];

  String _monthRuShort(int m) => const [
    'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
    'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'
  ][m - 1];

  String _fmt(DateTime d) {
    const m = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    const wd = [
      'Понедельник', 'Вторник', 'Среда', 'Четверг',
      'Пятница', 'Суббота', 'Воскресенье'
    ];
    return '${wd[d.weekday - 1]}, ${d.day} ${m[d.month - 1]}';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ВЫБОР ЕДЫ
// ═══════════════════════════════════════════════════════════════════
class _EnhancedFoodPicker extends StatefulWidget {
  final NutritionProvider provider;

  const _EnhancedFoodPicker({required this.provider});

  @override
  State<_EnhancedFoodPicker> createState() => _EnhancedFoodPickerState();
}

class _EnhancedFoodPickerState extends State<_EnhancedFoodPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _SelectedFood? _configuringFood;
  late TextEditingController _gramsCtrl;

  @override
  void initState() {
    super.initState();
    _gramsCtrl = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  void _startConfiguring(_SelectedFood food) {
    _gramsCtrl.text = food.grams.toInt().toString();
    setState(() => _configuringFood = food);
  }

  void _confirmSelection() {
    if (_configuringFood != null) {
      Navigator.pop(context, _configuringFood);
    }
  }

  // ─── Калорийность ингредиента: ищем продукт по имени ───
  double _itemKcal(dynamic item) {
    final name = (item.name as String).trim().toLowerCase();
    final grams = (item.grams as num).toDouble();
    final product = widget.provider.products
        .where((p) => p.name.trim().toLowerCase() == name)
        .firstOrNull;
    if (product == null) return 0;
    return product.calories * grams / 100.0;
  }

  double _excludedCaloriesFor(_SelectedFood food) {
    if (food.isProduct || food.excludedIngredientIds.isEmpty) return 0;
    final template = widget.provider.templates
        .where((t) => t.id == food.id)
        .firstOrNull;
    if (template == null) return 0;
    double sum = 0;
    for (var i = 0; i < template.items.length; i++) {
      if (food.excludedIngredientIds.contains('idx_$i')) {
        sum += _itemKcal(template.items[i]);
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final templates = widget.provider.templates
        .where((t) =>
    _query.isEmpty ||
        t.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final products = widget.provider.products
        .where((p) =>
    _query.isEmpty ||
        p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _T.faint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _configuringFood == null
                          ? 'Что добавим?'
                          : 'Настройка',
                      style: _display(size: 26, weight: FontWeight.w600),
                    ),
                  ),
                  if (_configuringFood != null)
                    TextButton(
                      onPressed: () =>
                          setState(() => _configuringFood = null),
                      child: Text('Назад',
                          style: _body(
                              size: 14,
                              weight: FontWeight.w700,
                              color: _T.terracotta)),
                    )
                  else
                    _circleBtn(Icons.close_rounded,
                            () => Navigator.pop(context)),
                ],
              ),
            ),
            if (_configuringFood == null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: _T.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _T.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: _body(size: 14, weight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Найти рецепт или продукт...',
                      hintStyle:
                      _body(size: 14, color: _T.muted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _T.muted, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: _configuringFood != null
                  ? _buildConfigPanel()
                  : ListView(
                padding:
                const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  if (templates.isNotEmpty) ...[
                    _sectionTag('РЕЦЕПТЫ · ${templates.length}', _T.sky),
                    const SizedBox(height: 10),
                    ...templates.map(
                          (t) => _FoodItemTile(
                        emoji: '🍱',
                        name: t.name,
                        subtitle:
                        '${t.caloriesPerPortion.round()} ккал',
                        badge: 'Рецепт',
                        badgeColor: _T.sky,
                        onTap: () => _startConfiguring(_SelectedFood(
                          isProduct: false,
                          id: t.id,
                          name: t.name,
                          baseCalories: t.caloriesPerPortion,
                        )),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  if (products.isNotEmpty) ...[
                    _sectionTag('ПРОДУКТЫ · ${products.length}', _T.sage),
                    const SizedBox(height: 10),
                    ...products.map(
                          (p) => _FoodItemTile(
                        emoji: p.categoryEmoji ?? '🍎',
                        name: p.name,
                        subtitle:
                        '${p.calories.round()} ккал / 100г',
                        badge: 'Продукт',
                        badgeColor: _T.sage,
                        onTap: () => _startConfiguring(_SelectedFood(
                          isProduct: true,
                          id: p.id,
                          name: p.name,
                          baseCalories: p.calories,
                        )),
                      ),
                    ),
                  ],
                  if (templates.isEmpty && products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 60),
                      child: Center(
                        child: Column(
                          children: [
                            const Text('🔍',
                                style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 16),
                            Text('Ничего не найдено',
                                style: _body(
                                    size: 15,
                                    weight: FontWeight.w600,
                                    color: _T.muted)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_configuringFood != null)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                decoration: const BoxDecoration(
                  color: _T.bg,
                  border: Border(top: BorderSide(color: _T.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _T.terracotta,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Добавить · ${_configuringFood!.totalCalories.round()} ккал',
                            style: _body(
                                size: 15,
                                weight: FontWeight.w700,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _T.surface,
          shape: BoxShape.circle,
          border: Border.all(color: _T.border, width: 1.2),
        ),
        child: Icon(icon, size: 18, color: _T.ink),
      ),
    );
  }

  Widget _sectionTag(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: _mono(
                size: 11,
                weight: FontWeight.w700,
                color: _T.inkSoft,
                letterSpacing: 1.8)),
      ],
    );
  }

  Widget _buildConfigPanel() {
    final food = _configuringFood!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _T.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(food.isProduct ? '🍎' : '🍱',
                  style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      style:
                      _display(size: 22, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(food.isProduct ? 'ПРОДУКТ' : 'РЕЦЕПТ',
                      style: _mono(
                          size: 9,
                          weight: FontWeight.w700,
                          letterSpacing: 1.4)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        if (food.isProduct) ...[
          Text('ВЕС',
              style: _mono(
                  size: 10, weight: FontWeight.w700, letterSpacing: 1.8)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: _gramsCtrl,
                    style:
                    _display(size: 32, weight: FontWeight.w600),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '0',
                    ),
                    onChanged: (val) {
                      final grams = double.tryParse(val) ?? 0;
                      if (grams >= 0) {
                        setState(() => _configuringFood =
                            food.copyWith(grams: grams));
                      }
                    },
                  ),
                ),
                Text('г',
                    style: _body(
                        size: 16,
                        weight: FontWeight.w600,
                        color: _T.muted)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [50, 100, 150, 200, 250, 300]
                .map((g) => _chip('$g г', food.grams == g, () {
              _gramsCtrl.text = '$g';
              setState(() => _configuringFood =
                  food.copyWith(grams: g.toDouble()));
            }))
                .toList(),
          ),
        ] else ...[
          Text('ПОРЦИИ',
              style: _mono(
                  size: 10, weight: FontWeight.w700, letterSpacing: 1.8)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
                .map((p) => _chip('${p}×', food.portions == p,
                    () => setState(() =>
                _configuringFood = food.copyWith(portions: p))))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text('ИНГРЕДИЕНТЫ',
              style: _mono(
                  size: 10, weight: FontWeight.w700, letterSpacing: 1.8)),
          const SizedBox(height: 6),
          Text('Нажми, чтобы исключить или вернуть — калории пересчитаются',
              style: _body(size: 12, color: _T.muted)),
          const SizedBox(height: 10),
          ..._buildIngredientList(food),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _T.terracottaLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroStat(
                  'Ккал', food.totalCalories.round(), _T.terracotta),
              _macroStat('Б',
                  (food.totalCalories * 0.3 / 4).round(), _T.sage),
              _macroStat('Ж',
                  (food.totalCalories * 0.3 / 9).round(), _T.mustard),
              _macroStat('У',
                  (food.totalCalories * 0.4 / 4).round(), _T.sky),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildIngredientList(_SelectedFood food) {
    final template = widget.provider.templates
        .where((t) => t.id == food.id)
        .firstOrNull;
    if (template == null) {
      return [
        Text('Данные рецепта не найдены',
            style: _body(size: 13, color: _T.muted))
      ];
    }
    return template.items.asMap().entries.map((e) {
      final idx = e.key;
      final item = e.value;
      final isExcluded =
      food.excludedIngredientIds.contains('idx_$idx');
      final scaledGrams = item.grams * food.portions;
      final kcal = _itemKcal(item) * food.portions;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            final newExcluded =
            Set<String>.from(food.excludedIngredientIds);
            if (isExcluded) {
              newExcluded.remove('idx_$idx');
            } else {
              newExcluded.add('idx_$idx');
            }
            final updated =
            food.copyWith(excludedIngredientIds: newExcluded);
            setState(() => _configuringFood = updated.copyWith(
              excludedCaloriesPerPortion:
              _excludedCaloriesFor(updated),
            ));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isExcluded ? _T.roseLight : _T.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExcluded
                    ? _T.rose.withOpacity(0.3)
                    : _T.border,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isExcluded ? _T.rose : _T.sage,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExcluded ? Icons.close_rounded : Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: _body(
                              size: 14,
                              weight: FontWeight.w600,
                              color: isExcluded
                                  ? _T.muted
                                  : _T.ink)
                              .copyWith(
                            decoration: isExcluded
                                ? TextDecoration.lineThrough
                                : null,
                          )),
                      Text(
                        kcal > 0
                            ? '${scaledGrams.toInt()} г · ${kcal.round()} ккал'
                            : '${scaledGrams.toInt()} г',
                        style: _mono(
                            size: 11, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _T.ink : _T.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _T.ink : _T.border,
            width: 1.2,
          ),
        ),
        child: Text(label,
            style: _body(
                size: 13,
                weight: FontWeight.w700,
                color: selected ? Colors.white : _T.ink)),
      ),
    );
  }

  Widget _macroStat(String label, int value, Color color) {
    return Column(
      children: [
        Text('$value',
            style: _display(size: 20, weight: FontWeight.w600,
                color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: _mono(
                size: 10, weight: FontWeight.w700, color: _T.inkSoft)),
      ],
    );
  }
}

class _FoodItemTile extends StatelessWidget {
  final String emoji, name, subtitle, badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _FoodItemTile({
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _T.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                      _display(size: 16, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: _mono(
                          size: 11, weight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge,
                  style: _mono(
                      size: 9,
                      weight: FontWeight.w700,
                      color: badgeColor,
                      letterSpacing: 0.8)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: _T.faint),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DASHED BORDER
// ═══════════════════════════════════════════════════════════════════
class DashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double gap;

  const DashedBorder({
    required this.child,
    this.color = Colors.white,
    this.strokeWidth = 1.5,
    this.gap = 4,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
          color: color, strokeWidth: strokeWidth, gap: gap),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
            metric.extractPath(distance, distance + 6), Offset.zero);
        distance += 6 + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}