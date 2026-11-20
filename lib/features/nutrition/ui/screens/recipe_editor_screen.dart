// features/nutrition/ui/screens/recipe_editor_screen.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  Design tokens (единый стиль)
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF7C818A);
  static const divider = Color(0xFFE9EBEF);
  static const elevated = Color(0xFFF0F1F4);

  static const peachSoft = Color(0xFFFBEDE4);
  static const peachDeep = Color(0xFFEF9563);
  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF6C9E88);
  static const yellowSoft = Color(0xFFFDF5E6);
  static const yellowDeep = Color(0xFFE0B054);
  static const skySoft = Color(0xFFE8EFF8);
  static const skyDeep = Color(0xFF7E9DC6);
  static const pinkSoft = Color(0xFFFCF0F2);
  static const pinkDeep = Color(0xFFD17A8F);
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF9381BB);
}

class _Hero {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const accent = Color(0xFFEF9563);
  static const textHigh = Colors.white;
  static const textLow = Color(0xFFA4A6AA);
}

class _T {
  static final title2 = GoogleFonts.inter(
      fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: _P.text);
  static final headline = GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w600, color: _P.text);
  static final body = GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400, color: _P.textMuted);
  static final caption = GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
}

const double _padH = 16;

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class RecipeEditorScreen extends StatefulWidget {
  final MealTemplate? existing; // null = создание нового
  const RecipeEditorScreen({super.key, this.existing});

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _uuid = const Uuid();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _portionsCtrl = TextEditingController(text: '1');
  final _cookedWeightCtrl = TextEditingController();
  final _prepTimeCtrl = TextEditingController();
  final _cookTimeCtrl = TextEditingController();

  List<_IngredientRow> _ingredients = [];
  RecipeDifficulty _difficulty = RecipeDifficulty.easy;
  final Set<String> _tags = {};

  // Целевые макросы для "Лаборатории"
  double _targetCalories = 500;
  double _targetProtein = 30;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _loadExisting(widget.existing!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _portionsCtrl.dispose();
    _cookedWeightCtrl.dispose();
    _prepTimeCtrl.dispose();
    _cookTimeCtrl.dispose();
    super.dispose();
  }

  void _loadExisting(MealTemplate t) {
    _nameCtrl.text = t.name;
    _descCtrl.text = t.description ?? '';
    _portionsCtrl.text = t.portions.toString();
    _cookedWeightCtrl.text = t.cookedWeight?.toStringAsFixed(0) ?? '';
    _prepTimeCtrl.text = t.prepTimeMin?.toString() ?? '';
    _cookTimeCtrl.text = t.cookTimeMin?.toString() ?? '';
    _difficulty = t.difficulty;
    _tags.addAll(t.tags);
    _ingredients = t.items
        .map((i) => _IngredientRow(
      id: _uuid.v4(),
      productId: i.productId,
      name: i.name,
      grams: i.grams,
    ))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIVE CALCULATION (ЛАБОРАТОРИЯ)
  // ═══════════════════════════════════════════════════════════════
  ({double cal, double pro, double fat, double carb, double grams}) _calcTotals(
      NutritionProvider provider) {
    double cal = 0, pro = 0, fat = 0, carb = 0, grams = 0;
    for (final row in _ingredients) {
      final p = provider.products.where((x) => x.id == row.productId).firstOrNull;
      if (p == null) continue;
      final m = p.forGrams(row.grams);
      cal += m.calories;
      pro += m.protein;
      fat += m.fat;
      carb += m.carbs;
      grams += row.grams;
    }
    return (cal: cal, pro: pro, fat: fat, carb: carb, grams: grams);
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final totals = _calcTotals(provider);
    final portions = int.tryParse(_portionsCtrl.text) ?? 1;
    final perPortion = portions > 0 ? totals.cal / portions : totals.cal;

    return Scaffold(
      backgroundColor: _P.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildHero(totals, perPortion)),
          _sectionLabel('ОСНОВА', Icons.info_outline_rounded),
          SliverToBoxAdapter(child: _buildBasicsCard()),
          _sectionLabel('ИНГРЕДИЕНТЫ', Icons.restaurant_menu_rounded),
          SliverToBoxAdapter(child: _buildIngredientsCard(provider)),
          _sectionLabel('ЛАБОРАТОРИЯ', Icons.science_rounded),
          SliverToBoxAdapter(child: _buildLabCard(totals, provider)),
          _sectionLabel('ДЕТАЛИ', Icons.tune_rounded),
          SliverToBoxAdapter(child: _buildDetailsCard()),
          _sectionLabel('ТЕГИ', Icons.label_outline_rounded),
          SliverToBoxAdapter(child: _buildTagsCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(provider),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HERO
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHero(
      ({double cal, double pro, double fat, double carb, double grams}) totals,
      double perPortion) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Hero.bgTop, _Hero.bgBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _iconPill(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.existing == null ? 'НОВЫЙ РЕЦЕПТ' : 'РЕДАКТИРОВАНИЕ',
                        style: GoogleFonts.inter(
                          color: _Hero.textLow,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    _difficultyPill(),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtrl,
                  style: GoogleFonts.inter(
                    color: _Hero.textHigh,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Название блюда',
                    hintStyle: GoogleFonts.inter(
                      color: _Hero.textLow.withOpacity(0.6),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 18),
                // 4 метрики КБЖУ
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      _heroMacro('🔥', '${totals.cal.round()}', 'ккал', _P.peachDeep),
                      _divider(),
                      _heroMacro('💪', totals.pro.toStringAsFixed(0), 'Б', _P.greenDeep),
                      _divider(),
                      _heroMacro('🧈', totals.fat.toStringAsFixed(0), 'Ж', _P.yellowDeep),
                      _divider(),
                      _heroMacro('🌾', totals.carb.toStringAsFixed(0), 'У', _P.skyDeep),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 12, color: _Hero.textLow),
                    const SizedBox(width: 4),
                    Text(
                      'На порцию: ${perPortion.round()} ккал',
                      style: GoogleFonts.inter(
                        color: _Hero.textLow,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${totals.grams.round()} г всего',
                      style: GoogleFonts.inter(
                        color: _Hero.textLow,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroMacro(String emoji, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: GoogleFonts.inter(
              color: _Hero.textLow,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 32,
    color: Colors.white.withOpacity(0.12),
  );

  Widget _iconPill({required IconData icon, required VoidCallback onTap}) {
    return _Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _difficultyPill() {
    return _Press(
      onTap: _showDifficultyPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_difficulty.emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 5),
            Text(
              _difficulty.displayName.toUpperCase(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BASICS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBasicsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              minLines: 1,
              style: GoogleFonts.inter(color: _P.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Описание (необязательно)',
                hintStyle: GoogleFonts.inter(color: _P.textMuted, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _numField(
                    label: 'Порций',
                    ctrl: _portionsCtrl,
                    icon: Icons.people_outline_rounded,
                    color: _P.lavenderDeep,
                    softColor: _P.lavenderSoft,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _numField(
                    label: 'Подготовка, мин',
                    ctrl: _prepTimeCtrl,
                    icon: Icons.timer_outlined,
                    color: _P.skyDeep,
                    softColor: _P.skySoft,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _numField(
                    label: 'Готовка, мин',
                    ctrl: _cookTimeCtrl,
                    icon: Icons.local_fire_department_outlined,
                    color: _P.peachDeep,
                    softColor: _P.peachSoft,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    required Color color,
    required Color softColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: softColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(
              color: _P.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  INGREDIENTS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildIngredientsCard(NutritionProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Container(
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.divider),
        ),
        child: Column(
          children: [
            ..._ingredients.asMap().entries.map((e) => _ingredientTile(
              provider: provider,
              row: e.value,
              index: e.key,
            )),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _Press(
                onTap: () => _showAddIngredientSheet(provider),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _P.peachSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _P.peachDeep.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 16, color: _P.peachDeep),
                      const SizedBox(width: 6),
                      Text(
                        'ДОБАВИТЬ ИНГРЕДИЕНТ',
                        style: GoogleFonts.inter(
                          color: _P.peachDeep,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ingredientTile({
    required NutritionProvider provider,
    required _IngredientRow row,
    required int index,
  }) {
    final product = provider.products.where((p) => p.id == row.productId).firstOrNull;
    final macros = product?.forGrams(row.grams);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _P.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(product?.categoryEmoji ?? '🍽️',
                      style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${macros?.calories.round() ?? 0} ккал',
                        style: GoogleFonts.inter(
                          color: _P.peachDeep,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                _Press(
                  onTap: () {
                    setState(() => _ingredients.removeAt(index));
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded, size: 13, color: _P.pinkDeep),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Слайдер граммов — "Лаборатория" в действии
            Row(
              children: [
                Text(
                  '${row.grams.round()} г',
                  style: GoogleFonts.inter(
                    color: _P.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      activeTrackColor: _P.peachDeep,
                      inactiveTrackColor: _P.divider,
                      thumbColor: _P.peachDeep,
                      overlayColor: _P.peachDeep.withOpacity(0.15),
                    ),
                    child: Slider(
                      value: row.grams.clamp(1.0, 1000.0),
                      min: 1,
                      max: 1000,
                      onChanged: (v) {
                        setState(() {
                          _ingredients[index] = row.copyWith(grams: v);
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: TextEditingController(text: row.grams.toStringAsFixed(0)),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    onChanged: (v) {
                      final n = double.tryParse(v);
                      if (n != null && n > 0) {
                        setState(() {
                          _ingredients[index] = row.copyWith(grams: n);
                        });
                      }
                    },
                    style: GoogleFonts.inter(
                      color: _P.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LAB (ЛАБОРАТОРИЯ)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLabCard(
      ({double cal, double pro, double fat, double carb, double grams}) totals,
      NutritionProvider provider) {
    final calPct = _targetCalories > 0 ? (totals.cal / _targetCalories).clamp(0.0, 1.5) : 0.0;
    final proPct = _targetProtein > 0 ? (totals.pro / _targetProtein).clamp(0.0, 1.5) : 0.0;
    final calHit = calPct >= 0.85 && calPct <= 1.15;
    final proHit = proPct >= 0.85 && proPct <= 1.15;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Hero.bgTop, _Hero.bgBottom],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🧪', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ЛАБОРАТОРИЯ',
                          style: GoogleFonts.inter(
                              color: _P.peachSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4)),
                      const SizedBox(height: 2),
                      Text('Попадание в цель',
                          style: GoogleFonts.inter(
                              color: _Hero.textHigh,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (calHit && proHit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _P.greenDeep.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('✓ ИДЕАЛЬНО',
                        style: GoogleFonts.inter(
                            color: _P.greenSoft,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _labSlider(
              label: 'Калории',
              value: totals.cal,
              target: _targetCalories,
              unit: 'ккал',
              color: _P.peachDeep,
              pct: calPct,
              hit: calHit,
              onChanged: (v) => setState(() => _targetCalories = v),
            ),
            const SizedBox(height: 14),
            _labSlider(
              label: 'Белок',
              value: totals.pro,
              target: _targetProtein,
              unit: 'г',
              color: _P.greenDeep,
              pct: proPct,
              hit: proHit,
              onChanged: (v) => setState(() => _targetProtein = v),
            ),
            const SizedBox(height: 14),
            Text(
              '💡 Двигай граммы ингредиентов выше — КБЖУ пересчитается вживую',
              style: GoogleFonts.inter(
                color: _Hero.textLow,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labSlider({
    required String label,
    required double value,
    required double target,
    required String unit,
    required Color color,
    required double pct,
    required bool hit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: _Hero.textHigh, fontSize: 11, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${value.round()} / ${target.round()} $unit',
              style: GoogleFonts.inter(
                color: hit ? _P.greenSoft : _Hero.textLow,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            activeTrackColor: color,
            inactiveTrackColor: Colors.white.withOpacity(0.15),
            thumbColor: Colors.white,
            overlayColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: target.clamp(50.0, 2000.0),
            min: 50,
            max: 2000,
            onChanged: onChanged,
          ),
        ),
        // Индикатор попадания
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(hit ? _P.greenDeep : color),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DETAILS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDetailsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _P.yellowSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: const Text('⚖️', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ужарка / уварка',
                          style: GoogleFonts.inter(
                              color: _P.text, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Вес готового блюда (необязательно)',
                          style: GoogleFonts.inter(
                              color: _P.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _cookedWeightCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                        color: _P.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [ui.FontFeature.tabularFigures()]),
                    decoration: InputDecoration(
                      hintText: 'г',
                      hintStyle: GoogleFonts.inter(color: _P.textMuted, fontSize: 12),
                      isDense: true,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: _P.bg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAGS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTagsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.divider),
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: RecipeTags.all.map((tag) {
            final selected = _tags.contains(tag);
            return _Press(
              onTap: () {
                setState(() {
                  if (selected) {
                    _tags.remove(tag);
                  } else {
                    _tags.add(tag);
                  }
                });
              },
              child: AnimatedContainer(
                duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? _P.peachDeep : _P.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? _P.peachDeep : _P.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(RecipeTags.emoji(tag), style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Text(
                      RecipeTags.label(tag),
                      style: GoogleFonts.inter(
                        color: selected ? Colors.white : _P.text,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOTTOM BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomBar(NutritionProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _P.surface,
        border: Border(top: BorderSide(color: _P.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _save(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: _P.peachDeep,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              widget.existing == null ? 'СОХРАНИТЬ РЕЦЕПТ' : 'ОБНОВИТЬ',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════════
  Future<void> _showAddIngredientSheet(NutritionProvider provider) async {
    final selected = await showModalBottomSheet<FoodProduct>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _IngredientPickerSheet(provider: provider),
    );
    if (selected != null) {
      setState(() {
        _ingredients.add(_IngredientRow(
          id: _uuid.v4(),
          productId: selected.id,
          name: selected.name,
          grams: 100,
        ));
      });
    }
  }

  Future<void> _showDifficultyPicker() async {
    final picked = await showModalBottomSheet<RecipeDifficulty>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: RecipeDifficulty.values.map((d) {
              final selected = d == _difficulty;
              return _Press(
                onTap: () {
                  setState(() => _difficulty = d);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(d.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Text(d.displayName,
                          style: GoogleFonts.inter(
                              color: _P.text,
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                      const Spacer(),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: _P.peachDeep),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _save(NutritionProvider provider) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Введи название рецепта'),
        backgroundColor: _P.pinkDeep,
      ));
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Добавь хотя бы один ингредиент'),
        backgroundColor: _P.pinkDeep,
      ));
      return;
    }

    final template = MealTemplate(
      id: widget.existing?.id ?? _uuid.v4(),
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      items: _ingredients
          .map((r) => MealTemplateItem(
        productId: r.productId,
        grams: r.grams,
        name: r.name,
      ))
          .toList(),
      portions: int.tryParse(_portionsCtrl.text) ?? 1,
      cookedWeight: double.tryParse(_cookedWeightCtrl.text),
      prepTimeMin: int.tryParse(_prepTimeCtrl.text),
      cookTimeMin: int.tryParse(_cookTimeCtrl.text),
      difficulty: _difficulty,
      tags: _tags.toList(),
    );

    await provider.saveTemplate(template);

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.existing == null ? '✅ Рецепт сохранён' : '✅ Рецепт обновлён'),
      backgroundColor: _P.greenDeep,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  INGREDIENT ROW MODEL
// ═══════════════════════════════════════════════════════════════════
class _IngredientRow {
  final String id;
  final String productId;
  final String name;
  final double grams;

  _IngredientRow({
    required this.id,
    required this.productId,
    required this.name,
    required this.grams,
  });

  _IngredientRow copyWith({double? grams}) => _IngredientRow(
    id: id,
    productId: productId,
    name: name,
    grams: grams ?? this.grams,
  );
}

// ═══════════════════════════════════════════════════════════════════
//  INGREDIENT PICKER SHEET
// ═══════════════════════════════════════════════════════════════════
class _IngredientPickerSheet extends StatefulWidget {
  final NutritionProvider provider;
  const _IngredientPickerSheet({required this.provider});

  @override
  State<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<_IngredientPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final products = _query.isEmpty
        ? widget.provider.products.take(50).toList()
        : widget.provider.searchProducts(_query).take(50).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 36, height: 5, decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Выбери продукт', style: _T.title2),
                  const Spacer(),
                  _Press(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: _P.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: GoogleFonts.inter(color: _P.text, fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Поиск продукта...',
                  hintStyle: GoogleFonts.inter(color: _P.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: _P.textMuted, size: 18),
                  filled: true,
                  fillColor: _P.bg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final p = products[i];
                  return _Press(
                    onTap: () => Navigator.pop(context, p),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _P.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(p.categoryEmoji, style: const TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        color: _P.text, fontSize: 12, fontWeight: FontWeight.w600)),
                                Text('${p.calories.round()} ккал / 100г',
                                    style: GoogleFonts.inter(
                                        color: _P.textMuted,
                                        fontSize: 10,
                                        fontFeatures: const [ui.FontFeature.tabularFigures()])),
                              ],
                            ),
                          ),
                          const Icon(Icons.add_rounded, size: 16, color: _P.peachDeep),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════════
Widget _sectionLabel(String text, IconData icon) {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 22, _padH, 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _P.textMuted),
          const SizedBox(width: 6),
          Text(text.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _P.text, letterSpacing: 1.0)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: _P.divider)),
        ],
      ),
    ),
  );
}

class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Press({required this.child, this.onTap});

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: interactive ? (_) => _set(true) : null,
      onTapUp: interactive ? (_) => _set(false) : null,
      onTapCancel: interactive ? () => _set(false) : null,
      onTap: widget.onTap == null
          ? null
          : () {
        HapticFeedback.selectionClick();
        widget.onTap!();
      },
      child: widget.child,
    );
    if (!interactive) return child;
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}