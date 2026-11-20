// features/nutrition/ui/screens/plan_builder_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';

class _P {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Colors.white;
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);

  // 🆕 Премиальная темная карточка (глубокий серо-синий, не черный)
  static const mealCardBg = Color(0xFF252932);
  static const mealCardText = Color(0xFFFFFFFF); // Чисто белый для заголовков
  static const mealCardMuted = Color(0xFF9CA3AF); // Светло-серый для второстепенного текста
  static const mealCardSurface = Color(0xFF323741); // Чуть светлее для внутренних блоков

  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF5A8A73);
  static const skySoft = Color(0xFFE8EFF8);
  static const skyDeep = Color(0xFF6A8AB5);
  static const peachSoft = Color(0xFFFBEDE4);
  static const peachDeep = Color(0xFFE08550);
  static const yellowSoft = Color(0xFFFDF5E6);
  static const yellowDeep = Color(0xFFD0A040);
  static const pinkSoft = Color(0xFFFCF0F2);
  static const pinkDeep = Color(0xFFC16A7F);
}

// 🆕 Хранит список выбранных продуктов/блюд. Список гарантированно изменяемый.
class _PlannedMeal {
  final MealType type;
  final List<_SelectedFood> foods;

  _PlannedMeal({required this.type, List<_SelectedFood>? foods}) : foods = foods ?? [];
}

class PlanBuilderScreen extends StatefulWidget {
  const PlanBuilderScreen({super.key});

  @override
  State<PlanBuilderScreen> createState() => _PlanBuilderScreenState();
}

class _PlanBuilderScreenState extends State<PlanBuilderScreen> {
  final _nameCtrl = TextEditingController(text: 'Моя программа');
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();

  int _durationDays = 7;
  DateTime _startDate = DateTime.now();
  late DateTime _selectedDate;
  bool _creating = false;

  final Map<String, List<_PlannedMeal>> _dailyMeals = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = _startDate;
    debugPrint('🔄 Инициализация PlanBuilderScreen: полный сброс состояния');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<NutritionProvider>().userProfile;
      final goals = context.read<NutritionProvider>().defaultGoals;

      if (goals != null) {
        _kcalCtrl.text = goals.calories.round().toString();
        _proteinCtrl.text = goals.protein.round().toString();
        _fatCtrl.text = goals.fat.round().toString();
        _carbsCtrl.text = goals.carbs.round().toString();
      } else if (profile != null) {
        _kcalCtrl.text = profile.targetCalories.round().toString();
        _proteinCtrl.text = profile.recommendedProtein.round().toString();
        _fatCtrl.text = profile.recommendedFat.round().toString();
        _carbsCtrl.text = profile.recommendedCarbs.round().toString();
      }

      _initDailyMeals(); // 🆕 Жесткий сброс при каждом открытии
      setState(() {});
    });
  }

  void _initDailyMeals() {
    debugPrint('🧹 Очистка _dailyMeals и создание новых пустых слотов');
    _dailyMeals.clear();
    for (int i = 0; i < _durationDays; i++) {
      final date = _startDate.add(Duration(days: i));
      final key = _dateKey(date);
      // Создаем пустые слоты. Еды в них нет, пользователь добавит сам.
      _dailyMeals[key] = [
        _PlannedMeal(type: MealType.breakfast),
        _PlannedMeal(type: MealType.lunch),
        _PlannedMeal(type: MealType.dinner),
      ];
    }
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _nameCtrl.dispose(); _kcalCtrl.dispose(); _proteinCtrl.dispose();
    _fatCtrl.dispose(); _carbsCtrl.dispose();
    super.dispose();
  }

  double get _kcal => double.tryParse(_kcalCtrl.text) ?? 0;
  double get _protein => double.tryParse(_proteinCtrl.text) ?? 0;
  double get _fat => double.tryParse(_fatCtrl.text) ?? 0;
  double get _carbs => double.tryParse(_carbsCtrl.text) ?? 0;

  List<DateTime> get _allDates => List.generate(_durationDays, (i) => _startDate.add(Duration(days: i)));

  Future<void> _create() async {
    if (_kcal <= 0 || _protein <= 0 || _fat <= 0 || _carbs <= 0) {
      _info('Заполни цели', 'Все значения КБЖУ должны быть больше нуля');
      return;
    }

    setState(() => _creating = true);
    try {
      final Map<String, List<({MealType type, String? templateId})>> dailyPlansMap = {};

      for (final date in _allDates) {
        final key = _dateKey(date);
        final mealsForDay = <({MealType type, String? templateId})>[];

        for (final plannedMeal in _dailyMeals[key] ?? []) {
          if (plannedMeal.foods.isEmpty) {
            mealsForDay.add((type: plannedMeal.type, templateId: null));
          } else {
            for (final food in plannedMeal.foods) {
              final templateId = food.isProduct ? 'PROD:${food.id}' : food.id;
              mealsForDay.add((type: plannedMeal.type, templateId: templateId));
            }
          }
        }
        dailyPlansMap[key] = mealsForDay;
      }

      await context.read<NutritionProvider>().createProgram(
        name: _nameCtrl.text.trim().isEmpty ? 'Моя программа' : _nameCtrl.text.trim(),
        startDate: _startDate,
        endDate: _startDate.add(Duration(days: _durationDays - 1)),
        targetCalories: _kcal,
        targetProtein: _protein,
        targetFat: _fat,
        targetCarbs: _carbs,
        dailyPlans: dailyPlansMap,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(t, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _P.text)),
      content: Text(m, style: GoogleFonts.inter(color: _P.muted)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ОК', style: TextStyle(fontWeight: FontWeight.w600)))],
    ),
  );

  Future<void> _addFoodToMeal(String dateKey, int mealIndex) async {
    final provider = context.read<NutritionProvider>();
    final selected = await showModalBottomSheet<_SelectedFood>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FoodPicker(provider: provider),
    );

    if (selected != null && mounted) {
      setState(() {
        _dailyMeals[dateKey]![mealIndex].foods.add(selected);
        debugPrint('✅ Добавлено: ${selected.name} (${selected.isProduct ? "Продукт" : "Рецепт"})');
      });
    }
  }

  Future<void> _addMealType() async {
    final currentMeals = _dailyMeals[_dateKey(_selectedDate)]!;
    final availableTypes = MealType.values.where((t) => !currentMeals.any((pm) => pm.type == t)).toList();

    if (availableTypes.isEmpty) {
      _info('Все приемы добавлены', 'Для этого дня уже выбраны все типы приемов пищи.');
      return;
    }

    final selectedType = await showModalBottomSheet<MealType>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 5, decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3)), margin: const EdgeInsets.only(bottom: 16)),
            Text('Добавить прием пищи', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _P.text)),
            const SizedBox(height: 16),
            ...availableTypes.map((t) => ListTile(
              leading: Text(t.emoji, style: const TextStyle(fontSize: 20)),
              title: Text(t.displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _P.text)),
              onTap: () => Navigator.pop(ctx, t),
            )),
          ],
        ),
      ),
    );

    if (selectedType != null && mounted) {
      setState(() => _dailyMeals[_dateKey(_selectedDate)]!.add(_PlannedMeal(type: selectedType)));
    }
  }

  void _applyCurrentDayToAll() {
    final currentDayMeals = _dailyMeals[_dateKey(_selectedDate)]!;
    // Глубокое копирование, чтобы дни не были связаны ссылками
    final copiedMeals = currentDayMeals.map((m) => _PlannedMeal(
      type: m.type,
      foods: List.from(m.foods),
    )).toList();

    setState(() {
      for (final date in _allDates) {
        _dailyMeals[_dateKey(date)] = copiedMeals.map((m) => _PlannedMeal(
          type: m.type,
          foods: List.from(m.foods),
        )).toList();
      }
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('✅ Применено ко всем дням'), backgroundColor: _P.greenDeep, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentKey = _dateKey(_selectedDate);
    final currentMeals = _dailyMeals[currentKey] ?? [];

    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.bg, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: _P.text), onPressed: () => Navigator.pop(context)),
        title: Text('Новая программа', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: _P.text)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _sectionTitle('Название и период'),
                _card(child: Column(
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _P.text),
                      decoration: InputDecoration(
                        filled: true, fillColor: _P.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        hintText: 'Например, «Сушка марта»',
                        hintStyle: GoogleFonts.inter(color: _P.muted),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      _periodChip('Неделя', 7),
                      const SizedBox(width: 8),
                      _periodChip('Месяц', 30),
                    ]),
                  ],
                )),

                _sectionTitle('Цели на день'),
                _card(
                  child: Column(
                    children: [
                      _numField('Калории', _kcalCtrl, 'ккал', Icons.local_fire_department_rounded, _P.peachDeep),
                      const Divider(height: 24, color: _P.divider),
                      Row(children: [
                        Expanded(child: _numField('Белки', _proteinCtrl, 'г', Icons.egg_alt_rounded, _P.greenDeep)),
                        const SizedBox(width: 8),
                        Expanded(child: _numField('Жиры', _fatCtrl, 'г', Icons.water_drop_rounded, _P.yellowDeep)),
                        const SizedBox(width: 8),
                        Expanded(child: _numField('Углеводы', _carbsCtrl, 'г', Icons.grain_rounded, _P.skyDeep)),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
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
                          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: const Text('Взять из профиля', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          style: TextButton.styleFrom(foregroundColor: _P.greenDeep, padding: const EdgeInsets.symmetric(vertical: 10), backgroundColor: _P.greenSoft, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                    ],
                  ),
                ),

                _sectionTitle('Расписание по дням'),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _allDates.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final date = _allDates[i];
                            final isSel = _sameDay(date, _selectedDate);
                            return GestureDetector(
                              onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedDate = date); },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 64,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? _P.greenDeep : _P.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isSel ? _P.greenDeep : _P.divider, width: isSel ? 2 : 1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_weekShort(date.weekday), style: GoogleFonts.inter(color: isSel ? Colors.white70 : _P.text.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text('${date.day}', style: GoogleFonts.inter(color: isSel ? Colors.white : _P.text, fontSize: 18, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(_monthRuShort(date.month), style: GoogleFonts.inter(color: isSel ? Colors.white70 : _P.text.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Text('Приемы пищи на ${_fmt(_selectedDate)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _P.text)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _applyCurrentDayToAll,
                            icon: const Icon(Icons.copy_all_rounded, size: 16),
                            label: const Text('На все дни', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(foregroundColor: _P.skyDeep, padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 🆕 Отрисовка приёмов пищи с идеальным темным фоном и бейджами
                      ...List.generate(currentMeals.length, (mealIndex) {
                        final meal = currentMeals[mealIndex];
                        final hasFoods = meal.foods.isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _P.mealCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(meal.type.emoji, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Text(meal.type.displayName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _P.mealCardText)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 22, color: _P.pinkDeep),
                                    onPressed: () => setState(() => currentMeals.removeAt(mealIndex)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              if (hasFoods) ...[
                                ...List.generate(meal.foods.length, (foodIndex) {
                                  final food = meal.foods[foodIndex];
                                  final isProd = food.isProduct;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _P.mealCardSurface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(isProd ? Icons.apple_rounded : Icons.restaurant_menu_rounded, size: 18, color: isProd ? _P.greenDeep : _P.skyDeep),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            food.name,
                                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (isProd ? _P.greenDeep : _P.skyDeep).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isProd ? 'Продукт' : 'Рецепт',
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isProd ? _P.greenDeep : _P.skyDeep),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${food.calories.round()}', style: GoogleFonts.inter(fontSize: 12, color: _P.mealCardMuted, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => setState(() => meal.foods.removeAt(foodIndex)),
                                          child: const Icon(Icons.close, size: 18, color: _P.pinkDeep),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],

                              InkWell(
                                onTap: () => _addFoodToMeal(currentKey, mealIndex),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                      color: _P.greenDeep.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _P.greenDeep.withOpacity(0.3))
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_rounded, size: 20, color: _P.greenDeep),
                                      const SizedBox(width: 8),
                                      Text(
                                        hasFoods ? 'Добавить ещё' : 'Выбрать рецепт или продукт',
                                        style: GoogleFonts.inter(fontSize: 14, color: _P.greenDeep, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addMealType,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Добавить прием пищи'),
                          style: OutlinedButton.styleFrom(foregroundColor: _P.greenDeep, side: const BorderSide(color: _P.greenDeep), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _creating ? null : _create,
                  style: FilledButton.styleFrom(backgroundColor: _P.greenDeep, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: _creating
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text('Создать программу на $_durationDays дн.', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
    child: Text(t.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _P.muted)),
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: _P.divider), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
    child: child,
  );

  Widget _periodChip(String label, int days) {
    final sel = _durationDays == days;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _durationDays = days;
            _initDailyMeals();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: sel ? _P.greenDeep : _P.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? _P.greenDeep : _P.divider, width: 1)),
          alignment: Alignment.center,
          child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: sel ? Colors.white : _P.text)),
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController c, String unit, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 6), Text(label, style: GoogleFonts.inter(fontSize: 11, color: _P.text, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextField(
              controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: _P.text),
              decoration: InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero, hintText: '0', hintStyle: GoogleFonts.inter(color: _P.divider, fontWeight: FontWeight.w700)),
            ),
          ),
          Text(unit, style: GoogleFonts.inter(fontSize: 13, color: _P.muted, fontWeight: FontWeight.w500)),
        ]),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _weekShort(int wd) => const ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'][wd - 1];
  String _monthRuShort(int m) => const ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'][m - 1];
  String _fmt(DateTime d) {
    const m = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${d.day} ${m[d.month - 1]}';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  МОДЕЛЬ ВЫБРАННОЙ ЕДЫ
// ═══════════════════════════════════════════════════════════════════
class _SelectedFood {
  final bool isProduct;
  final String id;
  final String name;
  final double calories;
  _SelectedFood({required this.isProduct, required this.id, required this.name, required this.calories});
}

// ═══════════════════════════════════════════════════════════════════
//  УНИВЕРСАЛЬНЫЙ ВЫБОР ЕДЫ (Рецепты + Продукты с поиском)
// ═══════════════════════════════════════════════════════════════════
class _FoodPicker extends StatefulWidget {
  final NutritionProvider provider;
  const _FoodPicker({required this.provider});

  @override
  State<_FoodPicker> createState() => _FoodPickerState();
}

class _FoodPickerState extends State<_FoodPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = widget.provider.templates.where((t) =>
    _query.isEmpty || t.name.toLowerCase().contains(_query.toLowerCase())
    ).take(15).toList();

    final products = widget.provider.products.where((p) =>
    _query.isEmpty || p.name.toLowerCase().contains(_query.toLowerCase())
    ).take(15).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Выберите еду', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _P.text)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: _P.text)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Поиск рецепта или продукта...',
                  prefixIcon: const Icon(Icons.search_rounded, color: _P.muted),
                  filled: true,
                  fillColor: _P.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (templates.isNotEmpty) ...[
                    Text('РЕЦЕПТЫ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _P.muted, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    ...templates.map((t) => _FoodItemTile(
                      emoji: '🍱', name: t.name, subtitle: '${t.caloriesPerPortion.round()} ккал',
                      badge: 'Рецепт', badgeColor: _P.skyDeep,
                      onTap: () => Navigator.pop(context, _SelectedFood(isProduct: false, id: t.id, name: t.name, calories: t.caloriesPerPortion)),
                    )),
                    const SizedBox(height: 20),
                  ],
                  if (products.isNotEmpty) ...[
                    Text('ПРОДУКТЫ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _P.muted, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    ...products.map((p) => _FoodItemTile(
                      emoji: p.categoryEmoji ?? '🍎', name: p.name, subtitle: '${p.calories.round()} ккал / 100г',
                      badge: 'Продукт', badgeColor: _P.greenDeep,
                      onTap: () => Navigator.pop(context, _SelectedFood(isProduct: true, id: p.id, name: p.name, calories: p.calories)),
                    )),
                  ],
                  if (templates.isEmpty && products.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Ничего не найдено', style: GoogleFonts.inter(color: _P.muted, fontSize: 14)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodItemTile extends StatelessWidget {
  final String emoji, name, subtitle, badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _FoodItemTile({required this.emoji, required this.name, required this.subtitle, required this.badge, required this.badgeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: _P.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _P.divider)),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(emoji, style: const TextStyle(fontSize: 20))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _P.text)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: _P.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(badge, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _P.muted),
          ],
        ),
      ),
    );
  }
}