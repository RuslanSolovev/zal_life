// features/nutrition/ui/screens/recipe_editor_screen.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  Design tokens
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
//  HERO THEMES + ФОТО ПРИРОДЫ
// ═══════════════════════════════════════════════════════════════════
class _HeroTheme {
  final String id;
  final String label;
  final String emoji;
  final Color top;
  final Color bottom;
  final Color accent;
  const _HeroTheme({
    required this.id, required this.label, required this.emoji,
    required this.top, required this.bottom, required this.accent,
  });
}

const List<_HeroTheme> _heroThemes = [
  _HeroTheme(id: 'recipe', label: 'Кулинарный', emoji: '🍳',
      top: Color(0xFF4A2D1B), bottom: Color(0xFF2A1B0F), accent: Color(0xFFEF9563)),
  _HeroTheme(id: 'tuscany', label: 'Тоскана', emoji: '🍅',
      top: Color(0xFF4A2D1B), bottom: Color(0xFF2A1B0F), accent: Color(0xFFEF9563)),
  _HeroTheme(id: 'forest', label: 'Лес', emoji: '🌲',
      top: Color(0xFF1E3530), bottom: Color(0xFF0E1F1B), accent: Color(0xFF6C9E88)),
  _HeroTheme(id: 'spices', label: 'Пряности', emoji: '🌶️',
      top: Color(0xFF4A3520), bottom: Color(0xFF2A1F10), accent: Color(0xFFE8B858)),
  _HeroTheme(id: 'wine', label: 'Вино', emoji: '🍷',
      top: Color(0xFF3A1F28), bottom: Color(0xFF1F0F18), accent: Color(0xFFBB8F9D)),
  _HeroTheme(id: 'nordic', label: 'Скандинавия', emoji: '❄️',
      top: Color(0xFF3A3A3F), bottom: Color(0xFF1F1F24), accent: Color(0xFF7E9DC6)),
  _HeroTheme(id: 'current', label: 'Тёмный', emoji: '✨',
      top: Color(0xFF1B2027), bottom: Color(0xFF161719), accent: Color(0xFFEF9563)),
];

const List<String> _heroBackgrounds = [
  'assets/images/nature_hero.jpg',
  'assets/images/nature_hero2.jpg',
  'assets/images/nature_hero3.jpg',
  'assets/images/nature_hero4.jpg',
  'assets/images/nature_hero5.jpg',
  'assets/images/nature_hero6.jpg',
  'assets/images/nature_hero7.jpg',
  'assets/images/nature_hero8.jpg',
  'assets/images/nature_hero9.jpg',
  'assets/images/nature_hero10.jpg',
  'assets/images/nature_hero11.jpg',
  'assets/images/nature_hero12.jpg',
  'assets/images/nature_hero13.jpg',
  'assets/images/nature_hero14.jpg',
  'assets/images/nature_hero15.jpg',
  'assets/images/nature_hero16.jpg',
  'assets/images/nature_hero17.jpg',
  'assets/images/nature_hero18.jpg',
  'assets/images/nature_hero19.jpg',
  'assets/images/nature_hero20.jpg',
  'assets/images/nature_hero21.jpg',
];

const Map<String, String> _heroBgLabels = {
  'assets/images/nature_hero.jpg': 'Тропа',
  'assets/images/nature_hero2.jpg': 'Закат 1',
  'assets/images/nature_hero3.jpg': 'Закат 2',
  'assets/images/nature_hero4.jpg': 'Закат 3',
  'assets/images/nature_hero5.jpg': 'Лес',
  'assets/images/nature_hero6.jpg': 'Горы',
  'assets/images/nature_hero7.jpg': 'Закат 4',
  'assets/images/nature_hero8.jpg': 'Рассвет',
  'assets/images/nature_hero9.jpg': 'Поле',
  'assets/images/nature_hero10.jpg': 'Река',
  'assets/images/nature_hero11.jpg': 'Озеро',
  'assets/images/nature_hero12.jpg': 'Море',
  'assets/images/nature_hero13.jpg': 'Пляж',
  'assets/images/nature_hero14.jpg': 'Пустыня',
  'assets/images/nature_hero15.jpg': 'Водопад',
  'assets/images/nature_hero16.jpg': 'Каньон',
  'assets/images/nature_hero17.jpg': 'Степь',
  'assets/images/nature_hero18.jpg': 'Тайга',
  'assets/images/nature_hero19.jpg': 'Луг',
  'assets/images/nature_hero20.jpg': 'Дюны',
  'assets/images/nature_hero21.jpg': 'Утёс',
};

_HeroTheme _findTheme(String id) =>
    _heroThemes.firstWhere((t) => t.id == id, orElse: () => _heroThemes.first);

bool _isImagePath(String value) => value.startsWith('assets/');

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class RecipeEditorScreen extends StatefulWidget {
  final MealTemplate? existing;
  const RecipeEditorScreen({super.key, this.existing});

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

String _difficultyDescription(RecipeDifficulty d) {
  switch (d) {
    case RecipeDifficulty.easy:
      return 'Быстро и просто, до 30 минут';
    case RecipeDifficulty.medium:
      return 'Потребует внимания, 30-60 минут';
    case RecipeDifficulty.hard:
      return 'Для особых случаев, 60+ минут';
    default:
      return '';
  }
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

  double _targetCalories = 500;
  double _targetProtein = 30;

  bool _reduceMotion = false;
  String _heroBg = 'recipe';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _loadExisting(widget.existing!);
    }
    _loadBg();
  }

  Future<void> _loadBg() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('recipe_hero_bg') ?? 'recipe';
    if (mounted) setState(() => _heroBg = value);
  }

  Future<void> _saveBg(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recipe_hero_bg', value);
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
          SliverToBoxAdapter(child: const SizedBox(height: 20)),
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
  //  HERO (с фото + темы + плавный переход)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHero(
      ({double cal, double pro, double fat, double carb, double grams}) totals,
      double perPortion) {
    final isImage = _isImagePath(_heroBg);
    final theme = isImage ? _heroThemes.first : _findTheme(_heroBg);
    final accent = theme.accent;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Stack(
        children: [
          // 🆕 ФОН: фото или градиент
          Positioned.fill(
            child: isImage
                ? Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _heroBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_Hero.bgTop, _Hero.bgBottom],
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.55),
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
              ],
            )
                : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.top, theme.bottom],
                ),
              ),
            ),
          ),
          // Декоративное свечение (для градиентных тем)
          if (!isImage)
            Positioned(
              top: 40, right: -60,
              child: IgnorePointer(
                child: Container(
                  width: 260, height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [accent.withOpacity(0.25), accent.withOpacity(0)],
                    ),
                  ),
                ),
              ),
            ),
          // 🆕 ПЛАВНЫЙ ПЕРЕХОД В ФОН (150px, 7 stops)
          Positioned(
            left: 0, right: 0, bottom: 0, height: 150,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _P.bg.withOpacity(0.0),
                      _P.bg.withOpacity(0.05),
                      _P.bg.withOpacity(0.15),
                      _P.bg.withOpacity(0.35),
                      _P.bg.withOpacity(0.65),
                      _P.bg.withOpacity(0.90),
                      _P.bg,
                    ],
                    stops: const [0.0, 0.15, 0.30, 0.50, 0.70, 0.85, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
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
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            shadows: [Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 4)],
                          ),
                        ),
                      ),
                      _iconPill(
                        icon: Icons.wallpaper_rounded,
                        onTap: _openThemePicker,
                      ),
                      const SizedBox(width: 8),
                      _difficultyPill(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
                    ),
                    decoration: InputDecoration(
                      hintText: 'Название блюда',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
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
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.20)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              '${perPortion.round()} ккал/порц',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Text(
                          '${totals.grams.round()} г всего',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [ui.FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
              shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.75),
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
    color: Colors.white.withOpacity(0.18),
  );

  Widget _iconPill({required IconData icon, required VoidCallback onTap}) {
    return _Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _difficultyPill() {
    return _Press(
      onTap: _showDifficultyPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
          ],
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
  //  🆕 THEME + IMAGE PICKER
  // ═══════════════════════════════════════════════════════════════
  Future<void> _openThemePicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: _P.bg,
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
                  width: 38, height: 5,
                  decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: _P.peachSoft, borderRadius: BorderRadius.circular(11)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.wallpaper_rounded, color: _P.peachDeep, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Фон рецепта',
                            style: GoogleFonts.inter(color: _P.text, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text('Цветовые темы и фотографии природы',
                            style: GoogleFonts.inter(color: _P.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.palette_outlined, size: 13, color: _P.textMuted),
                          const SizedBox(width: 6),
                          Text('ЦВЕТОВЫЕ ТЕМЫ',
                              style: GoogleFonts.inter(color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.9,
                        children: _heroThemes.map((theme) {
                          final isSelected = !_isImagePath(_heroBg) && theme.id == _heroBg;
                          return _Press(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(ctx, theme.id);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? _P.peachDeep : Colors.white.withOpacity(0.9),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: _P.peachDeep.withOpacity(0.3), blurRadius: 10, spreadRadius: -2, offset: const Offset(0, 3))]
                                    : null,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [theme.top, theme.bottom],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: Container(
                                      width: 18, height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [theme.accent.withOpacity(0.7), theme.accent.withOpacity(0)],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.55)],
                                          stops: const [0.4, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 6, top: 6,
                                    child: Text(theme.emoji, style: const TextStyle(fontSize: 16)),
                                  ),
                                  Positioned(
                                    left: 6, right: 6, bottom: 6,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(theme.label,
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                  color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700,
                                                  shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 3)])),
                                        ),
                                        if (isSelected)
                                          Container(
                                            width: 14, height: 14,
                                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.check_rounded, color: _P.peachDeep, size: 9),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.landscape_rounded, size: 13, color: _P.textMuted),
                          const SizedBox(width: 6),
                          Text('ФОТО ПРИРОДЫ',
                              style: GoogleFonts.inter(color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                          const Spacer(),
                          Text('${_heroBackgrounds.length}',
                              style: GoogleFonts.inter(color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                        children: _heroBackgrounds.map((path) {
                          final isSelected = _isImagePath(_heroBg) && _heroBg == path;
                          final label = _heroBgLabels[path] ?? '';
                          return _Press(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(ctx, path);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? _P.peachDeep : Colors.white.withOpacity(0.9),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: _P.peachDeep.withOpacity(0.3), blurRadius: 12, spreadRadius: -2, offset: const Offset(0, 4))]
                                    : null,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    path, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [_Hero.bgTop, _Hero.bgBottom],
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(Icons.image_not_supported_rounded, color: Colors.white.withOpacity(0.5), size: 22),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.55)],
                                          stops: const [0.4, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 8, right: 8, bottom: 8,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(label,
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                  color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700,
                                                  shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)])),
                                        ),
                                        if (isSelected)
                                          Container(
                                            width: 18, height: 18,
                                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.check_rounded, color: _P.peachDeep, size: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && result != _heroBg) {
      await _saveBg(result);
      if (mounted) {
        setState(() => _heroBg = result);
        HapticFeedback.lightImpact();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BASICS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBasicsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.5),
          boxShadow: [
            BoxShadow(color: _P.text.withOpacity(0.04), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
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
            const SizedBox(height: 14),
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
                    label: 'Подготовка',
                    ctrl: _prepTimeCtrl,
                    icon: Icons.timer_outlined,
                    color: _P.skyDeep,
                    softColor: _P.skySoft,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _numField(
                    label: 'Готовка',
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(
              color: _P.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.5),
          boxShadow: [
            BoxShadow(color: _P.text.withOpacity(0.04), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ..._ingredients.asMap().entries.map((e) => _ingredientTile(
              provider: provider,
              row: e.value,
              index: e.key,
            )),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _Press(
                onTap: () => _showAddIngredientSheet(provider),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_P.peachDeep, Color(0xFFE0845A)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: _P.peachDeep.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'ДОБАВИТЬ ИНГРЕДИЕНТ',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _P.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _P.divider.withOpacity(0.7)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(product?.categoryEmoji ?? '🍽️',
                      style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _P.peachSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${macros?.calories.round() ?? 0} ккал',
                              style: GoogleFonts.inter(
                                color: _P.peachDeep,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [ui.FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Б${macros?.protein.toStringAsFixed(0) ?? 0} Ж${macros?.fat.toStringAsFixed(0) ?? 0} У${macros?.carbs.toStringAsFixed(0) ?? 0}',
                            style: GoogleFonts.inter(
                              color: _P.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [ui.FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _Press(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _ingredients.removeAt(index));
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _P.pinkSoft,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: _P.pinkDeep),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${row.grams.round()} г',
                    style: GoogleFonts.inter(
                      color: _P.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
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
                  width: 64,
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
  //  LAB
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Hero.bgTop, _Hero.bgBottom],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(color: _P.text.withOpacity(0.15), blurRadius: 24, spreadRadius: -6, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🧪', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (calHit && proHit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _P.greenDeep.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _P.greenDeep.withOpacity(0.4)),
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
            const SizedBox(height: 18),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Двигай граммы ингредиентов — КБЖУ пересчитается вживую',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
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
                    color: _Hero.textHigh, fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hit ? _P.greenDeep.withOpacity(0.25) : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()} / ${target.round()} $unit',
                style: GoogleFonts.inter(
                  color: hit ? _P.greenSoft : Colors.white.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 4,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.5),
          boxShadow: [
            BoxShadow(color: _P.text.withOpacity(0.04), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 6)),
          ],
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
                    color: _P.yellowSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: const Text('⚖️', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ужарка / уварка',
                          style: GoogleFonts.inter(
                              color: _P.text, fontSize: 13, fontWeight: FontWeight.w600)),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.5),
          boxShadow: [
            BoxShadow(color: _P.text.withOpacity(0.04), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 6)),
          ],
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RecipeTags.all.map((tag) {
            final selected = _tags.contains(tag);
            return _Press(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (selected) {
                    _tags.remove(tag);
                  } else {
                    _tags.add(tag);
                  }
                });
              },
              child: AnimatedContainer(
                duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _P.peachDeep : _P.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? _P.peachDeep : _P.divider,
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: _P.peachDeep.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(RecipeTags.emoji(tag), style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      RecipeTags.label(tag),
                      style: GoogleFonts.inter(
                        color: selected ? Colors.white : _P.text,
                        fontSize: 11,
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
        border: Border(top: BorderSide(color: _P.divider.withOpacity(0.8))),
        boxShadow: [
          BoxShadow(color: _P.text.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => _save(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: _P.peachDeep,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              shadowColor: _P.peachDeep.withOpacity(0.4),
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
            children: [
              Center(
                child: Container(
                  width: 38, height: 5,
                  decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('Сложность', style: _T.title2),
                    const Spacer(),
                    _Press(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: _P.bg, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 14, color: _P.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...RecipeDifficulty.values.map((d) {
                final selected = d == _difficulty;
                return _Press(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _difficulty = d);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? _P.peachSoft : _P.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? _P.peachDeep : _P.divider,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(d.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.displayName,
                                  style: GoogleFonts.inter(
                                      color: _P.text,
                                      fontSize: 14,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(_difficultyDescription(d),
                                  style: GoogleFonts.inter(
                                      color: _P.textMuted,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              size: 20, color: _P.peachDeep),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(NutritionProvider provider) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Введи название рецепта'),
        backgroundColor: _P.pinkDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Добавь хотя бы один ингредиент'),
        backgroundColor: _P.pinkDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 38, height: 5, decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: _P.peachSoft, borderRadius: BorderRadius.circular(11)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.restaurant_menu_rounded, color: _P.peachDeep, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Выбери продукт', style: GoogleFonts.inter(color: _P.text, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                        Text('${products.length} в базе',
                            style: GoogleFonts.inter(color: _P.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  _Press(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34, height: 34,
                      decoration: const BoxDecoration(color: _P.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final p = products[i];
                  return _Press(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context, p);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _P.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _P.divider.withOpacity(0.7)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(p.categoryEmoji, style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        color: _P.text, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _P.peachSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('${p.calories.round()} ккал / 100г',
                                      style: GoogleFonts.inter(
                                          color: _P.peachDeep,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          fontFeatures: const [ui.FontFeature.tabularFigures()])),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: _P.peachDeep.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.add_rounded, size: 16, color: _P.peachDeep),
                          ),
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
      padding: const EdgeInsets.fromLTRB(_padH, 24, _padH, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _P.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: _P.textMuted),
          ),
          const SizedBox(width: 8),
          Text(text.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _P.text, letterSpacing: 1.2)),
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
      scale: _down ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}