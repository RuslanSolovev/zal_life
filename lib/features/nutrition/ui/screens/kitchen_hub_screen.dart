// features/nutrition/ui/screens/kitchen_hub_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zal_life/features/nutrition/ui/screens/plan_builder_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/plan_tracker_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/programs_hub_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/recipe_editor_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/shopping_mode_screen.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import '../widgets/seasonal_strip.dart';
import 'add_pantry_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════════
class _Palette {
  static const bg = Color(0xFFF6F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF263D36);
  static const textMuted = Color(0xFF7C8982);
  static const green = Color(0xFF426C59);
  static const greenSoft = Color(0xFFE7EFE5);
  static const sage = Color(0xFF8CAB93);
  static const peach = Color(0xFFC79475);
  static const peachSoft = Color(0xFFF5E6DC);
  static const pink = Color(0xFFBB8F9D);
  static const pinkSoft = Color(0xFFF2E4E7);
  static const yellow = Color(0xFFE7D9B8);
  static const brown = Color(0xFFA87B4F);
  static const brownSoft = Color(0xFFF3E9DC);
  static const lavender = Color(0xFF9381BB);
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const sky = Color(0xFF7E9DC6);
  static const skySoft = Color(0xFFE8EFF8);
  static const divider = Color(0xFFE5E8E1);
}

class _Vibrant {
  static const neonGreen = Color(0xFF3DDC84);
  static const vividPeach = Color(0xFFFF8A65);
  static const glowingPink = Color(0xFFFF6B8B);
  static const amber = Color(0xFFE8B858);
}

class _R {
  final double scale;
  _R(BuildContext context)
      : scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

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
  _HeroTheme(id: 'current', label: 'Текущий', emoji: '✨',
      top: Color(0xFF2B3A32), bottom: Color(0xFF1B2027), accent: Color(0xFFA87B4F)),
  _HeroTheme(id: 'provence', label: 'Прованс', emoji: '🌿',
      top: Color(0xFF2D3A4A), bottom: Color(0xFF1B2437), accent: Color(0xFFB5A4D1)),
  _HeroTheme(id: 'tuscany', label: 'Тоскана', emoji: '🍅',
      top: Color(0xFF4A2D1B), bottom: Color(0xFF2A1B0F), accent: Color(0xFFEF9563)),
  _HeroTheme(id: 'forest', label: 'Лес', emoji: '🌲',
      top: Color(0xFF1E3530), bottom: Color(0xFF0E1F1B), accent: Color(0xFF6C9E88)),
  _HeroTheme(id: 'spices', label: 'Пряности', emoji: '🌶️',
      top: Color(0xFF4A3520), bottom: Color(0xFF2A1F10), accent: Color(0xFFE8B858)),
  _HeroTheme(id: 'nordic', label: 'Скандинавия', emoji: '❄️',
      top: Color(0xFF3A3A3F), bottom: Color(0xFF1F1F24), accent: Color(0xFF7E9DC6)),
  _HeroTheme(id: 'wine', label: 'Вино', emoji: '🍷',
      top: Color(0xFF3A1F28), bottom: Color(0xFF1F0F18), accent: Color(0xFFBB8F9D)),
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
//  HELPERS
// ═══════════════════════════════════════════════════════════════════
String _itemsWord(int n) {
  if (n == 1) return 'позиция';
  if (n >= 2 && n <= 4) return 'позиции';
  return 'позиций';
}

String _productsWord(int n) {
  if (n == 1) return 'продукт';
  if (n >= 2 && n <= 4) return 'продукта';
  return 'продуктов';
}

String _daysWord(int n) {
  if (n == 1) return 'день';
  if (n >= 2 && n <= 4) return 'дня';
  return 'дней';
}

String _dishesWord(int n) {
  if (n == 1) return 'блюдо';
  if (n >= 2 && n <= 4) return 'блюда';
  return 'блюд';
}

String _getCategoryEmoji(String category) {
  switch (category.toLowerCase()) {
    case 'молочка': case 'dairy': return '🥛';
    case 'мясо': case 'meat': return '🥩';
    case 'овощи': case 'vegetables': return '🥬';
    case 'фрукты': case 'fruits': return '🍎';
    case 'крупы': case 'grains': return '🌾';
    case 'хлеб': case 'bakery': return '🍞';
    default: return '📦';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class KitchenHubScreen extends StatefulWidget {
  const KitchenHubScreen({super.key});

  @override
  State<KitchenHubScreen> createState() => _KitchenHubScreenState();
}

class _KitchenHubScreenState extends State<KitchenHubScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController _ringAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  String _heroBg = 'current';

  @override
  void initState() {
    super.initState();
    _loadBg();
  }

  Future<void> _loadBg() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('kitchen_hero_bg') ?? 'current';
    if (mounted) setState(() => _heroBg = value);
  }

  Future<void> _saveBg(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kitchen_hero_bg', value);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ringAnim.dispose();
    super.dispose();
  }

  Widget _entranceAt(double delay, Widget child) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (_, __) {
        final span = (1.0 - delay).clamp(0.01, 1.0);
        final t = ((_entrance.value - delay) / span).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased.clamp(0.0, 1.0),
          child: Transform.translate(
              offset: Offset(0, 24 * (1 - eased)), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final provider = context.watch<NutritionProvider>();
    final pantry = provider.pantryItems;
    final allShopping = provider.shoppingItems;
    final activeShopping = provider.activeShoppingList;
    final templates = provider.templates;
    final planDays = provider.planDays;
    final expiring = provider.expiringSoonItems;

    final activeBudget = activeShopping.fold<double>(0, (s, i) => s + i.totalPrice);
    final boughtCount = allShopping.where((i) => i.isBought).length;
    final shoppingProgress = allShopping.isEmpty ? 0.0 : boughtCount / allShopping.length;

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _hero(provider, pantry, templates, planDays, activeShopping, shoppingProgress, activeBudget)),
          SliverToBoxAdapter(child: SizedBox(height: r.s(20))),
          SliverToBoxAdapter(child: _entranceAt(0.20, _mainGrid(provider, pantry, templates, planDays, activeShopping, boughtCount, activeBudget, r))),
          if (expiring.isNotEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.25, _sectionHeader('Срочно использовать', Icons.warning_amber_rounded, _Vibrant.vividPeach, r))),
          if (expiring.isNotEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.28, _expiringSection(expiring, provider, r))),
          if (activeShopping.isNotEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.35, _sectionHeader('Список покупок', Icons.shopping_basket_rounded, _Palette.sky, r))),
          if (activeShopping.isNotEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.38, _monolithicShoppingPreview(activeShopping, provider, r))),
          SliverToBoxAdapter(child: _entranceAt(0.45, _sectionHeader('Быстрые действия', Icons.auto_awesome_rounded, _Palette.lavender, r))),
          SliverToBoxAdapter(child: _entranceAt(0.48, _quickActions(provider, r))),
          SliverToBoxAdapter(child: _entranceAt(0.55, _seasonalSection(r))),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color, _R r) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(24), r.s(20), r.s(12)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(r.s(6)),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(r.s(8))),
            child: Icon(icon, size: r.s(16), color: color),
          ),
          SizedBox(width: r.s(10)),
          Text(title.toUpperCase(),
              style: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w700, color: _Palette.text, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HERO (с плавным переходом фона)
  // ═══════════════════════════════════════════════════════════════
  Widget _hero(NutritionProvider provider, List<PantryItem> pantry, List<MealTemplate> templates,
      List<PlanDay> planDays, List<ShoppingItem> shopping, double progress, double budget) {
    final r = _R(context);
    final ringSize = r.s(240);
    final isImage = _isImagePath(_heroBg);
    final theme = isImage ? _heroThemes.first : _findTheme(_heroBg);
    final accent = theme.accent;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(r.s(32)),
        bottomRight: Radius.circular(r.s(32)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: isImage
                ? Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _heroBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [theme.top, theme.bottom],
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
          if (!isImage)
            Positioned(
              top: r.s(40), right: -r.s(60),
              child: IgnorePointer(
                child: Container(
                  width: r.s(260), height: r.s(260),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [accent.withOpacity(0.25), accent.withOpacity(0)],
                    ),
                  ),
                ),
              ),
            ),
          // 🆕 ПЛАВНЫЙ ПЕРЕХОД ФОНА (150px с 7 stops)
          Positioned(
            left: 0, right: 0, bottom: 0, height: r.s(150),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _Palette.bg.withOpacity(0.0),
                      _Palette.bg.withOpacity(0.05),
                      _Palette.bg.withOpacity(0.15),
                      _Palette.bg.withOpacity(0.35),
                      _Palette.bg.withOpacity(0.65),
                      _Palette.bg.withOpacity(0.90),
                      _Palette.bg,
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
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _glassPill(Icons.arrow_back_rounded, () => Navigator.pop(context), r),
                      SizedBox(width: r.s(10)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('КУХНЯ',
                                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                            Text('Твоя кулинарная база',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(18), fontWeight: FontWeight.w600, letterSpacing: -0.3,
                                    shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 6)])),
                          ],
                        ),
                      ),
                      _glassPill(Icons.palette_rounded, () => _openThemePicker(), r),
                    ],
                  ),
                  SizedBox(height: r.s(24)),
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(r.s(8)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.15),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: SizedBox(
                        width: ringSize, height: ringSize,
                        child: AnimatedBuilder(
                          animation: _ringAnim,
                          builder: (_, __) => CustomPaint(
                            painter: _ProgressRingPainter(
                              progress: progress * _ringAnim.value,
                              pantryCount: pantry.length,
                              templatesCount: templates.length,
                              planDaysCount: planDays.length,
                              shoppingCount: shopping.length,
                              scale: r.scale,
                              accent: accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: r.s(22)),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: r.s(8), runSpacing: r.s(8),
                    children: [
                      _heroLegendChip(_Palette.brown, 'Кладовая', '${pantry.length}', r),
                      _heroLegendChip(_Palette.peach, 'Рецепты', '${templates.length}', r),
                      _heroLegendChip(_Palette.green, 'План', '${planDays.length}', r),
                      _heroLegendChip(_Vibrant.vividPeach, 'Покупки', '${shopping.length}', r),
                      if (budget > 0) _heroLegendChip(_Vibrant.amber, 'Бюджет', '${budget.round()}₽', r),
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

  Widget _heroLegendChip(Color color, String label, String value, _R r) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(6)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: r.s(6), height: r.s(6), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: r.s(6)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: r.fs(10), fontWeight: FontWeight.w500)),
          SizedBox(width: r.s(4)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: r.fs(11), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _glassPill(IconData icon, VoidCallback onTap, _R r) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(r.s(10)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: r.s(16)),
      ),
    );
  }

  Future<void> _openThemePicker() async {
    final r = _R(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
        padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
        decoration: BoxDecoration(
          color: _Palette.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: r.s(38), height: r.s(5),
                  decoration: BoxDecoration(color: _Palette.divider, borderRadius: BorderRadius.circular(r.s(3))),
                ),
              ),
              SizedBox(height: r.s(20)),
              Row(
                children: [
                  Container(
                    width: r.s(38), height: r.s(38),
                    decoration: BoxDecoration(color: _Palette.peachSoft, borderRadius: BorderRadius.circular(r.s(11))),
                    alignment: Alignment.center,
                    child: Icon(Icons.wallpaper_rounded, color: _Palette.peach, size: r.s(19)),
                  ),
                  SizedBox(width: r.s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Фон экрана',
                            style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(18), fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                        SizedBox(height: r.s(2)),
                        Text('Цветовые темы и фотографии природы',
                            style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(12))),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.s(18)),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_outlined, size: r.s(13), color: _Palette.textMuted),
                          SizedBox(width: r.s(6)),
                          Text('ЦВЕТОВЫЕ ТЕМЫ',
                              style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                        ],
                      ),
                      SizedBox(height: r.s(10)),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: r.s(8),
                        crossAxisSpacing: r.s(8),
                        childAspectRatio: 0.9,
                        children: _heroThemes.map((theme) {
                          final isSelected = !_isImagePath(_heroBg) && theme.id == _heroBg;
                          return _TapScale(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(ctx, theme.id);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(r.s(14)),
                                border: Border.all(
                                  color: isSelected ? _Palette.peach : Colors.white.withOpacity(0.9),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: _Palette.peach.withOpacity(0.25), blurRadius: 10, spreadRadius: -2, offset: const Offset(0, 3))]
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
                                    top: r.s(8), right: r.s(8),
                                    child: Container(
                                      width: r.s(18), height: r.s(18),
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
                                          colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.5)],
                                          stops: const [0.4, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: r.s(6), top: r.s(6),
                                    child: Text(theme.emoji, style: TextStyle(fontSize: r.s(16))),
                                  ),
                                  Positioned(
                                    left: r.s(6), right: r.s(6), bottom: r.s(6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(theme.label,
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                  color: Colors.white, fontSize: r.fs(9.5), fontWeight: FontWeight.w700,
                                                  shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 3)])),
                                        ),
                                        if (isSelected)
                                          Container(
                                            width: r.s(14), height: r.s(14),
                                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                            alignment: Alignment.center,
                                            child: Icon(Icons.check_rounded, color: _Palette.peach, size: r.s(9)),
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
                      SizedBox(height: r.s(20)),
                      Row(
                        children: [
                          Icon(Icons.landscape_rounded, size: r.s(13), color: _Palette.textMuted),
                          SizedBox(width: r.s(6)),
                          Text('ФОТО ПРИРОДЫ',
                              style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                          const Spacer(),
                          Text('${_heroBackgrounds.length}',
                              style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w600)),
                        ],
                      ),
                      SizedBox(height: r.s(10)),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: r.s(10),
                        crossAxisSpacing: r.s(10),
                        childAspectRatio: 0.82,
                        children: _heroBackgrounds.map((path) {
                          final isSelected = _isImagePath(_heroBg) && _heroBg == path;
                          final label = _heroBgLabels[path] ?? '';
                          return _TapScale(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(ctx, path);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(r.s(16)),
                                border: Border.all(
                                  color: isSelected ? _Palette.peach : Colors.white.withOpacity(0.9),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: _Palette.peach.withOpacity(0.25), blurRadius: 12, spreadRadius: -2, offset: const Offset(0, 4))]
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
                                          colors: [Color(0xFF2B3A32), Color(0xFF1B2027)],
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(Icons.image_not_supported_rounded, color: Colors.white.withOpacity(0.5), size: r.s(22)),
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
                                    left: r.s(8), right: r.s(8), bottom: r.s(8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(label,
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                  color: Colors.white, fontSize: r.fs(10.5), fontWeight: FontWeight.w700,
                                                  shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)])),
                                        ),
                                        if (isSelected)
                                          Container(
                                            width: r.s(18), height: r.s(18),
                                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                            alignment: Alignment.center,
                                            child: Icon(Icons.check_rounded, color: _Palette.peach, size: r.s(12)),
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
  //  🆕 ЕДИНАЯ СЕТКА (улучшенная структура)
  // ═══════════════════════════════════════════════════════════════
  Widget _mainGrid(NutritionProvider provider, List<PantryItem> pantry, List<MealTemplate> templates,
      List<PlanDay> planDays, List<ShoppingItem> shopping, int boughtCount, double activeBudget, _R r) {
    final expiringCount = pantry.where((i) => i.daysUntilExpiry <= 3 && i.daysUntilExpiry >= 0).length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(20)),
      child: Column(
        children: [
          // Верхний ряд
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _zoneCard(
                  emoji: '🧺',
                  title: 'Кладовая',
                  bigValue: '${pantry.length}',
                  bigSubtitle: _productsWord(pantry.length),
                  badge: expiringCount > 0 ? '⚠️ $expiringCount' : null,
                  color: _Palette.brown,
                  softColor: _Palette.brownSoft,
                  icon: Icons.kitchen_rounded,
                  onTap: () => _showPantrySheet(provider),
                  r: r,
                ),
              ),
              SizedBox(width: r.s(12)),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _zoneCardSmall(
                      emoji: '📖',
                      title: 'Рецепты',
                      value: '${templates.length}',
                      subtitle: _dishesWord(templates.length),
                      color: _Palette.peach,
                      softColor: _Palette.peachSoft,
                      onTap: () => _showRecipesSheet(provider),
                      r: r,
                    ),
                    SizedBox(height: r.s(12)),
                    _zoneCardSmall(
                      emoji: '📅',
                      title: 'План',
                      value: '${planDays.length}',
                      subtitle: _daysWord(planDays.length),
                      color: _Palette.green,
                      softColor: _Palette.greenSoft,
                      onTap: () => _showPlanSheet(provider),
                      r: r,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r.s(12)),
          // Нижний ряд
          Row(
            children: [
              Expanded(child: _zoneCard(
                emoji: '🛒',
                title: 'Покупки',
                bigValue: '$boughtCount',
                bigSubtitle: '/ ${shopping.length + boughtCount} ${_itemsWord(shopping.length + boughtCount)}',
                badge: shopping.isNotEmpty ? '${shopping.length}' : null,
                color: _Palette.sky,
                softColor: _Palette.skySoft,
                icon: Icons.shopping_basket_rounded,
                onTap: () => _showShoppingSheet(provider),
                r: r,
              )),
              SizedBox(width: r.s(12)),
              Expanded(child: _zoneCard(
                emoji: '💰',
                title: 'Бюджет',
                bigValue: activeBudget > 0 ? '${activeBudget.round()}' : '—',
                bigSubtitle: activeBudget > 0 ? '₽' : 'пусто',
                color: _Vibrant.amber,
                softColor: const Color(0xFFFDF5E6),
                icon: Icons.account_balance_wallet_rounded,
                onTap: () => _showBudgetSheet(provider),
                r: r,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _zoneCard({
    required String emoji,
    required String title,
    required String bigValue,
    required String bigSubtitle,
    required Color color,
    required Color softColor,
    required IconData icon,
    required VoidCallback onTap,
    required _R r,
    String? badge,
  }) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(r.s(16)),
        decoration: BoxDecoration(
          color: softColor,
          borderRadius: BorderRadius.circular(r.s(22)),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: r.s(40), height: r.s(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(r.s(12)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: TextStyle(fontSize: r.s(20))),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(4)),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(r.s(8)),
                    ),
                    child: Text(badge,
                        style: GoogleFonts.inter(
                            color: color,
                            fontSize: r.fs(10),
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                  ),
              ],
            ),
            SizedBox(height: r.s(14)),
            Text(title,
                style: GoogleFonts.inter(
                    color: _Palette.textMuted,
                    fontSize: r.fs(12),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
            SizedBox(height: r.s(6)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(bigValue,
                    style: GoogleFonts.inter(
                        color: _Palette.text,
                        fontSize: r.fs(28),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                if (bigSubtitle.isNotEmpty) ...[
                  SizedBox(width: r.s(6)),
                  Flexible(
                    child: Text(bigSubtitle,
                        style: GoogleFonts.inter(
                            color: _Palette.textMuted,
                            fontSize: r.fs(11),
                            fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoneCardSmall({
    required String emoji,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color softColor,
    required VoidCallback onTap,
    required _R r,
  }) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(r.s(14)),
        decoration: BoxDecoration(
          color: softColor,
          borderRadius: BorderRadius.circular(r.s(18)),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.06), blurRadius: 12, spreadRadius: -3, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: r.s(32), height: r.s(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(r.s(10)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: TextStyle(fontSize: r.s(16))),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.6), size: r.s(16)),
              ],
            ),
            SizedBox(height: r.s(10)),
            Text(title,
                style: GoogleFonts.inter(
                    color: _Palette.textMuted,
                    fontSize: r.fs(11),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2)),
            SizedBox(height: r.s(4)),
            Text(value,
                style: GoogleFonts.inter(
                    color: _Palette.text,
                    fontSize: r.fs(22),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            Text(subtitle,
                style: GoogleFonts.inter(
                    color: _Palette.textMuted,
                    fontSize: r.fs(10),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EXPIRING SECTION
  // ═══════════════════════════════════════════════════════════════
  Widget _expiringSection(List<PantryItem> items, NutritionProvider provider, _R r) {
    final shown = items.take(3).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Container(
        padding: EdgeInsets.all(r.s(16)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Vibrant.vividPeach.withOpacity(0.15), _Palette.pinkSoft],
          ),
          borderRadius: BorderRadius.circular(r.s(24)),
          border: Border.all(color: _Vibrant.vividPeach.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(r.s(6)),
                  decoration: BoxDecoration(color: _Vibrant.vividPeach.withOpacity(0.2), borderRadius: BorderRadius.circular(r.s(8))),
                  child: Icon(Icons.schedule_rounded, color: _Vibrant.vividPeach, size: r.s(14)),
                ),
                SizedBox(width: r.s(8)),
                Text('ТРЕБУЕТ ВНИМАНИЯ',
                    style: GoogleFonts.inter(color: _Vibrant.vividPeach, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                const Spacer(),
                Text('${items.length}',
                    style: GoogleFonts.inter(color: _Vibrant.vividPeach, fontSize: r.fs(11), fontWeight: FontWeight.w700)),
              ],
            ),
            SizedBox(height: r.s(14)),
            ...shown.map((item) => _expiringItem(item, provider, r)),
          ],
        ),
      ),
    );
  }

  Widget _expiringItem(PantryItem item, NutritionProvider provider, _R r) {
    final urgent = item.daysUntilExpiry <= 1;
    final expired = item.daysUntilExpiry <= 0;
    final accent = expired ? _Palette.pink : (urgent ? _Vibrant.vividPeach : _Palette.peach);

    return Container(
      margin: EdgeInsets.only(bottom: r.s(8)),
      padding: EdgeInsets.all(r.s(10)),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(r.s(14)),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: r.s(36), height: r.s(36),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(r.s(10)),
            ),
            alignment: Alignment.center,
            child: Icon(
              expired ? Icons.error_outline_rounded
                  : (urgent ? Icons.schedule_rounded : Icons.inventory_2_outlined),
              color: accent, size: r.s(18),
            ),
          ),
          SizedBox(width: r.s(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displayName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(12), fontWeight: FontWeight.w600)),
                SizedBox(height: r.s(2)),
                Text(_expiryText(item),
                    style: GoogleFonts.inter(color: accent, fontSize: r.fs(10), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _TapScale(
            onTap: () async {
              await provider.addShoppingItem(
                productId: item.productId,
                customName: item.customName ?? item.displayName,
                quantity: item.quantity,
                unit: item.unit,
                isUrgent: expired || urgent,
              );
              if (!mounted) return;
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('✅ ${item.displayName} в покупках'),
                backgroundColor: _Palette.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
              ));
            },
            child: Container(
              width: r.s(32), height: r.s(32),
              margin: EdgeInsets.only(right: r.s(6)),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(r.s(9)),
              ),
              child: Icon(Icons.add_shopping_cart_rounded, size: r.s(15), color: accent),
            ),
          ),
          _TapScale(
            onTap: () => provider.removeFromPantry(item.id),
            child: Container(
              width: r.s(32), height: r.s(32),
              decoration: BoxDecoration(
                color: _Palette.bg,
                borderRadius: BorderRadius.circular(r.s(9)),
              ),
              child: Icon(Icons.delete_outline_rounded, size: r.s(15), color: _Palette.pink),
            ),
          ),
        ],
      ),
    );
  }

  String _expiryText(PantryItem item) {
    final qty = '${item.quantity.toStringAsFixed(0)} ${item.unit}';
    if (item.daysUntilExpiry <= 0) return '⚠️ Срок истёк • $qty';
    if (item.daysUntilExpiry == 1) return '🔥 Завтра испортится • $qty';
    if (item.daysUntilExpiry <= 3) return '⏳ Ещё ${item.daysUntilExpiry} дн. • $qty';
    return '✓ ${item.daysUntilExpiry} дн. до срока • $qty';
  }

  // ═══════════════════════════════════════════════════════════════
  //  🆕 СТИЛЬНЫЙ МОНОЛИТНЫЙ СПИСОК ПОКУПОК
  // ═══════════════════════════════════════════════════════════════
  Widget _monolithicShoppingPreview(List<ShoppingItem> items, NutritionProvider provider, _R r) {
    final preview = items.take(5).toList();
    final remaining = items.length - preview.length;
    final total = items.fold<double>(0, (s, i) => s + i.totalPrice);

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Container(
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(r.s(26)),
          border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.5),
          boxShadow: [
            BoxShadow(color: _Palette.sky.withOpacity(0.08), blurRadius: 24, spreadRadius: -6, offset: const Offset(0, 10)),
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🆕 Премиальный header
            _TapScale(
              onTap: () => _showShoppingSheet(provider),
              child: Container(
                padding: EdgeInsets.all(r.s(18)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _Palette.skySoft.withOpacity(0.7),
                      Colors.white,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(color: _Palette.divider.withOpacity(0.5), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: r.s(48), height: r.s(48),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _Palette.sky.withOpacity(0.25),
                            _Palette.sky.withOpacity(0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(r.s(14)),
                        border: Border.all(color: _Palette.sky.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: _Palette.sky.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.shopping_basket_rounded, color: _Palette.sky, size: r.s(24)),
                    ),
                    SizedBox(width: r.s(14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${items.length} ${_itemsWord(items.length)}',
                              style: GoogleFonts.inter(
                                color: _Palette.text,
                                fontSize: r.fs(16),
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              )),
                          SizedBox(height: r.s(3)),
                          Text('Активный список покупок',
                              style: GoogleFonts.inter(
                                color: _Palette.textMuted,
                                fontSize: r.fs(12),
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                    if (total > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(8)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _Vibrant.amber.withOpacity(0.20),
                              _Vibrant.amber.withOpacity(0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(r.s(12)),
                          border: Border.all(color: _Vibrant.amber.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: _Vibrant.amber.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('ИТОГО',
                                style: GoogleFonts.inter(
                                  color: _Palette.textMuted,
                                  fontSize: r.fs(9),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                )),
                            Text('${total.toStringAsFixed(0)} ₽',
                                style: GoogleFonts.inter(
                                  color: Color(0xFFB8892F),
                                  fontSize: r.fs(14),
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 🆕 Стильные товары
            ...preview.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == preview.length - 1;
              return _shoppingTilePremium(item, provider, r, isLast: isLast);
            }),
            if (remaining > 0)
              _TapScale(
                onTap: () => _showShoppingSheet(provider),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: r.s(14)),
                  decoration: BoxDecoration(
                    color: _Palette.bg.withOpacity(0.3),
                    border: Border(top: BorderSide(color: _Palette.divider.withOpacity(0.4), width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(6)),
                        decoration: BoxDecoration(
                          color: _Palette.sky.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(r.s(10)),
                        ),
                        child: Text('Ещё $remaining ${_itemsWord(remaining)}',
                            style: GoogleFonts.inter(
                              color: _Palette.sky,
                              fontSize: r.fs(12),
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                      SizedBox(width: r.s(8)),
                      Icon(Icons.arrow_forward_rounded, size: r.s(16), color: _Palette.sky),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🆕 Премиальный tile для товаров
  Widget _shoppingTilePremium(ShoppingItem item, NutritionProvider provider, _R r, {bool isLast = false}) {
    final product = provider.products.where((p) => p.id == item.productId).firstOrNull;
    final accent = product?.category == 'other' ? _Palette.sky : _Palette.sky;
    final isUrgent = item.isUrgent;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: r.s(24)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_Palette.pink.withOpacity(0.20), _Palette.pinkSoft],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.all(r.s(8)),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _Palette.pink.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.delete_rounded, color: _Palette.pink, size: r.s(20)),
            ),
            SizedBox(height: r.s(4)),
            Text('Удалить',
                style: GoogleFonts.inter(
                  color: _Palette.pink,
                  fontSize: r.fs(10),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                )),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _Palette.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(20))),
            title: Text('Удалить «${item.displayName}»?',
                style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(16), fontWeight: FontWeight.w600)),
            content: Text('Товар будет удалён из списка покупок.',
                style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Отмена', style: GoogleFonts.inter(color: _Palette.textMuted))),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: _Palette.pink),
                child: const Text('Удалить', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await provider.deleteShoppingItem(item.id);
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🗑️ «${item.displayName}» удалён'),
          backgroundColor: _Palette.pink,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
        ));
      },
      child: _TapScale(
        onTap: () => provider.toggleShoppingItem(item.id),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(12)),
          decoration: BoxDecoration(
            border: isLast ? null : Border(bottom: BorderSide(color: _Palette.divider.withOpacity(0.4), width: 0.5)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => provider.toggleShoppingItem(item.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: r.s(26), height: r.s(26),
                  decoration: BoxDecoration(
                    color: item.isBought ? _Palette.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(r.s(7)),
                    border: item.isBought ? null : Border.all(color: _Palette.divider, width: 2),
                    boxShadow: item.isBought
                        ? [BoxShadow(color: _Palette.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: item.isBought ? Icon(Icons.check_rounded, size: r.s(15), color: Colors.white) : const SizedBox(),
                ),
              ),
              SizedBox(width: r.s(12)),
              Container(
                width: r.s(38), height: r.s(38),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(r.s(11)),
                ),
                alignment: Alignment.center,
                child: Text(product?.categoryEmoji ?? '📦', style: TextStyle(fontSize: r.s(18))),
              ),
              SizedBox(width: r.s(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.displayName,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: item.isBought ? _Palette.textMuted : _Palette.text,
                                fontSize: r.fs(14), fontWeight: FontWeight.w600,
                                decoration: item.isBought ? TextDecoration.lineThrough : null,
                                decorationColor: _Palette.green,
                                decorationThickness: 2,
                              )),
                        ),
                        if (isUrgent && !item.isBought)
                          Container(
                            margin: EdgeInsets.only(left: r.s(8)),
                            padding: EdgeInsets.symmetric(horizontal: r.s(6), vertical: r.s(2)),
                            decoration: BoxDecoration(
                              color: _Palette.pink.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(r.s(5)),
                              border: Border.all(color: _Palette.pink.withOpacity(0.3)),
                            ),
                            child: Text('СРОЧНО',
                                style: GoogleFonts.inter(
                                  color: _Palette.pink,
                                  fontSize: r.fs(8),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                )),
                          ),
                      ],
                    ),
                    if (item.category != null && item.category!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: r.s(3)),
                        child: Text(item.category!,
                            style: GoogleFonts.inter(
                              color: _Palette.textMuted,
                              fontSize: r.fs(11),
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                  ],
                ),
              ),
              SizedBox(width: r.s(8)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.quantity.toStringAsFixed(0)} ${item.unit}',
                      style: GoogleFonts.inter(
                        color: _Palette.textMuted,
                        fontSize: r.fs(12),
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                  if (item.totalPrice > 0)
                    Text('${item.totalPrice.round()} ₽',
                        style: GoogleFonts.inter(
                          color: _Palette.text,
                          fontSize: r.fs(13),
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions(NutritionProvider provider, _R r) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Column(
        children: [
          _quickActionTile(
            icon: Icons.auto_awesome_rounded,
            emoji: '🎲',
            title: 'Случайный рецепт',
            subtitle: 'Не знаешь, что приготовить?',
            color: _Palette.lavender,
            softColor: _Palette.lavenderSoft,
            onTap: () => _pickRandomRecipe(provider),
            r: r,
          ),
          SizedBox(height: r.s(10)),
          _quickActionTile(
            icon: Icons.shopping_cart_rounded,
            emoji: '🧾',
            title: 'Собрать покупки из плана',
            subtitle: 'Автоматически по рецептам недели',
            color: _Palette.sky,
            softColor: _Palette.skySoft,
            onTap: () => _generateShoppingList(provider),
            r: r,
          ),
          SizedBox(height: r.s(10)),
          _quickActionTile(
            icon: Icons.add_shopping_cart_rounded,
            emoji: '➕',
            title: 'Добавить в кладовую',
            subtitle: 'Что есть дома прямо сейчас',
            color: _Palette.brown,
            softColor: _Palette.brownSoft,
            onTap: () => _showAddToPantrySheet(provider),
            r: r,
          ),
        ],
      ),
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required Color softColor,
    required VoidCallback onTap,
    required _R r,
  }) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(r.s(16)),
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(r.s(20)),
          border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.06), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: r.s(48), height: r.s(48),
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(r.s(14)),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: TextStyle(fontSize: r.s(22))),
            ),
            SizedBox(width: r.s(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(14), fontWeight: FontWeight.w600)),
                  SizedBox(height: r.s(3)),
                  Text(subtitle,
                      style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(12), fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(r.s(10)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(r.s(12)),
              ),
              child: Icon(Icons.chevron_right_rounded, size: r.s(18), color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seasonalSection(_R r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(20)),
      child: SeasonalStrip(onViewAll: () {}),
    );
  }

  void _pickRandomRecipe(NutritionProvider provider) {
    if (provider.templates.isEmpty) {
      _showInfo('Нет рецептов', 'Сначала добавь хотя бы один рецепт в книгу.');
      return;
    }
    final random = provider.templates[(math.Random().nextInt(provider.templates.length))];
    _showTemplateDetails(provider, random);
  }

  Future<void> _generateShoppingList(NutritionProvider provider) async {
    final r = _R(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(20))),
        title: Text('Собрать покупки?',
            style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(16), fontWeight: FontWeight.w600)),
        content: Text('Просуммируем ингредиенты из плана на неделю и создадим список. То, что есть в кладовой, будет вычтено.',
            style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Отмена', style: GoogleFonts.inter(color: _Palette.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Собрать', style: GoogleFonts.inter(color: _Palette.peach, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    await provider.generateShoppingListFromPlan(start, end);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('✅ Список покупок обновлён'),
      backgroundColor: _Palette.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
    ));
  }

  void _showInfo(String title, String message) {
    final r = _R(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(20))),
        title: Text(title, style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(16), fontWeight: FontWeight.w600)),
        content: Text(message, style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ОК')),
        ],
      ),
    );
  }

  void _showPantrySheet(NutritionProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PantrySheet(
        provider: provider,
        onAddProduct: () => _showAddToPantrySheet(provider),
      ),
    );
  }

  void _showRecipesSheet(NutritionProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const RecipeEditorScreen(),
        ),
      ),
    );
  }

  void _showPlanSheet(NutritionProvider provider) {
    // 🆕 ИСПРАВЛЕНО: Всегда ведем в Хаб управления программами.
    // А уже внутри Хаба пользователь увидит список, историю и кнопку "Создать".
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const ProgramsHubScreen(),
        ),
      ),
    );
  }

  void _showShoppingSheet(NutritionProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const ShoppingModeScreen(),
        ),
      ),
    );
  }

  void _showBudgetSheet(NutritionProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _BudgetSheet(provider: provider),
    );
  }

  void _showAddToPantrySheet(NutritionProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const AddPantryScreen(),
        ),
      ),
    );
  }

  void _showTemplateDetails(NutritionProvider provider, MealTemplate t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TemplateDetailsSheet(provider: provider, template: t),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final int pantryCount;
  final int templatesCount;
  final int planDaysCount;
  final int shoppingCount;
  final double scale;
  final Color accent;

  _ProgressRingPainter({
    required this.progress, required this.pantryCount,
    required this.templatesCount, required this.planDaysCount,
    required this.shoppingCount, required this.scale, required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20 * scale;
    final stroke = 14.0 * scale;

    canvas.drawCircle(
      center, radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.75
        ..color = Colors.white.withOpacity(0.15),
    );

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      const start = -math.pi / 2;
      final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

      canvas.drawArc(
        rect, start, sweep, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.6
          ..strokeCap = StrokeCap.round
          ..color = accent.withOpacity(0.28)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7),
      );

      final segments = 60;
      for (int i = 0; i < segments; i++) {
        final segStart = i / segments;
        final segEnd = (i + 1) / segments;
        if (segEnd > progress) break;
        final a1 = start + segStart * sweep;
        final a2 = start + segEnd * sweep;
        final t = i / segments;
        final color = Color.lerp(_Vibrant.vividPeach, _Vibrant.amber, t)!;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          a1, a2 - a1, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.butt
            ..color = color,
        );
      }

      final endAngle = start + sweep;
      final dotPos = Offset(
        center.dx + math.cos(endAngle) * radius,
        center.dy + math.sin(endAngle) * radius,
      );
      canvas.drawCircle(dotPos, stroke * 1.0,
          Paint()..color = accent.withOpacity(0.55)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7));
      canvas.drawCircle(dotPos, stroke * 0.65, Paint()..color = accent);
      canvas.drawCircle(dotPos, stroke * 0.28, Paint()..color = Colors.white);
    }

    _drawCenterText(canvas, center, '${(progress * 100).round()}%', 36 * scale, Colors.white, FontWeight.w600, -20 * scale);
    _drawCenterText(canvas, center, 'покупок', 12 * scale, Colors.white.withOpacity(0.7), FontWeight.w500, 8 * scale);
    _drawCenterText(canvas, center, '🍱 $templatesCount · 📅 $planDaysCount', 11 * scale, Colors.white.withOpacity(0.85), FontWeight.w600, 28 * scale);
  }

  void _drawCenterText(Canvas canvas, Offset center, String text, double fontSize, Color color, FontWeight weight, double offsetY) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color, fontSize: fontSize, fontWeight: weight, letterSpacing: -0.5,
          fontFeatures: const [FontFeature.tabularFigures()],
          shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + offsetY - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress ||
          old.pantryCount != pantryCount ||
          old.templatesCount != templatesCount ||
          old.planDaysCount != planDaysCount ||
          old.shoppingCount != shoppingCount;
}

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScale({required this.child, required this.onTap});
  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

class _GlossyProgress extends StatelessWidget {
  final double value;
  final double height;
  final List<Color> gradient;
  final Color track;
  final double radius;
  const _GlossyProgress({
    required this.value, required this.gradient,
    this.height = 8, this.track = const Color(0x33FFFFFF),
    this.radius = 100,
  });
  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(radius)),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: gradient.last.withOpacity(0.35), blurRadius: 6, spreadRadius: -1),
                  ],
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.42,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(radius),
                          bottom: Radius.circular(radius * 0.4),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withOpacity(0.55), Colors.white.withOpacity(0.0)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _grabber(_R r) => Container(
  width: r.s(38),
  height: r.s(5),
  decoration: BoxDecoration(color: _Palette.divider, borderRadius: BorderRadius.circular(r.s(3))),
);

class _PantrySheet extends StatelessWidget {
  final NutritionProvider provider;
  final VoidCallback onAddProduct;

  const _PantrySheet({required this.provider, required this.onAddProduct});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final items = provider.pantryItems;
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: r.s(10)),
            Center(child: _grabber(r)),
            SizedBox(height: r.s(16)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.s(20)),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(r.s(8)),
                    decoration: BoxDecoration(color: _Palette.brownSoft, borderRadius: BorderRadius.circular(r.s(10))),
                    child: Icon(Icons.kitchen_rounded, color: _Palette.brown, size: r.s(18)),
                  ),
                  SizedBox(width: r.s(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Кладовая',
                            style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(18), fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                        Text('${items.length} ${_productsWord(items.length)}',
                            style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(12))),
                      ],
                    ),
                  ),
                  _TapScale(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: r.s(36), height: r.s(36),
                      decoration: BoxDecoration(color: _Palette.bg, shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: r.s(16), color: _Palette.text),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: r.s(12)),
            Expanded(
              child: items.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🧺', style: TextStyle(fontSize: r.s(40))),
                    SizedBox(height: r.s(12)),
                    Text('Кладовая пуста',
                        style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(16), fontWeight: FontWeight.w600)),
                    SizedBox(height: r.s(6)),
                    Text('Добавьте продукты, чтобы видеть сроки',
                        style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(12))),
                    SizedBox(height: r.s(16)),
                    ElevatedButton.icon(
                      onPressed: onAddProduct,
                      icon: Icon(Icons.add_rounded, size: r.s(16)),
                      label: const Text('Добавить продукт'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.brown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(12))),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(16)),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: r.s(6)),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final urgent = item.daysUntilExpiry <= 3;
                  return Container(
                    padding: EdgeInsets.all(r.s(12)),
                    decoration: BoxDecoration(
                      color: urgent ? _Palette.pinkSoft : _Palette.bg,
                      borderRadius: BorderRadius.circular(r.s(14)),
                      border: Border.all(color: urgent ? _Palette.pink.withOpacity(0.25) : _Palette.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: r.s(40), height: r.s(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(r.s(11)),
                          ),
                          alignment: Alignment.center,
                          child: const Text('📦', style: TextStyle(fontSize: 18)),
                        ),
                        SizedBox(width: r.s(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.displayName,
                                  style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(13), fontWeight: FontWeight.w600)),
                              SizedBox(height: r.s(2)),
                              Text(
                                '${item.quantity.toStringAsFixed(0)} ${item.unit}' +
                                    (item.expiresAt != null ? ' • до ${item.expiresAt!.day}.${item.expiresAt!.month}' : ''),
                                style: GoogleFonts.inter(color: urgent ? _Palette.pink : _Palette.textMuted, fontSize: r.fs(11), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        _TapScale(
                          onTap: () => provider.removeFromPantry(item.id),
                          child: Container(
                            width: r.s(32), height: r.s(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(r.s(9)),
                            ),
                            child: Icon(Icons.delete_outline_rounded, size: r.s(15), color: _Palette.pink),
                          ),
                        ),
                      ],
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

class _BudgetSheet extends StatelessWidget {
  final NutritionProvider provider;
  const _BudgetSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final items = provider.activeShoppingList;
    final total = items.fold<double>(0, (s, i) => s + i.totalPrice);
    final byCategory = <String, double>{};
    for (final item in items) {
      final product = provider.products.where((p) => p.id == item.productId).firstOrNull;
      final cat = product?.categoryName ?? item.category ?? 'Другое';
      byCategory[cat] = (byCategory[cat] ?? 0) + item.totalPrice;
    }
    final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: r.s(10)),
            Center(child: _grabber(r)),
            SizedBox(height: r.s(16)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.s(20)),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(r.s(8)),
                    decoration: BoxDecoration(color: Color(0xFFFDF5E6), borderRadius: BorderRadius.circular(r.s(10))),
                    child: Icon(Icons.account_balance_wallet_rounded, color: _Vibrant.amber, size: r.s(18)),
                  ),
                  SizedBox(width: r.s(10)),
                  Text('Бюджет',
                      style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(18), fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                  const Spacer(),
                  _TapScale(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: r.s(36), height: r.s(36),
                      decoration: BoxDecoration(color: _Palette.bg, shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: r.s(16), color: _Palette.text),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: r.s(20)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.s(20)),
              child: Container(
                padding: EdgeInsets.all(r.s(20)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2B3A32), Color(0xFF1B2027)],
                  ),
                  borderRadius: BorderRadius.circular(r.s(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ИТОГО К ПОКУПКЕ',
                        style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                    SizedBox(height: r.s(8)),
                    Text('${total.toStringAsFixed(0)} ₽',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(36), fontWeight: FontWeight.w600, letterSpacing: -1.5,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                    SizedBox(height: r.s(4)),
                    Text('${items.length} ${_itemsWord(items.length)} в активном списке',
                        style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: r.fs(12), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            SizedBox(height: r.s(20)),
            if (sorted.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(16)),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => SizedBox(height: r.s(6)),
                  itemBuilder: (_, i) {
                    final entry = sorted[i];
                    final pct = total > 0 ? (entry.value / total).clamp(0.0, 1.0) : 0.0;
                    return Container(
                      padding: EdgeInsets.all(r.s(12)),
                      decoration: BoxDecoration(
                        color: _Palette.bg,
                        borderRadius: BorderRadius.circular(r.s(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(entry.key,
                                  style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(13), fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text('${entry.value.toStringAsFixed(0)} ₽',
                                  style: GoogleFonts.inter(color: _Vibrant.amber, fontSize: r.fs(13), fontWeight: FontWeight.w700,
                                      fontFeatures: const [FontFeature.tabularFigures()])),
                            ],
                          ),
                          SizedBox(height: r.s(6)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(r.s(2)),
                            child: _GlossyProgress(
                              value: pct,
                              height: r.s(4),
                              gradient: const [_Vibrant.amber, Color(0xFFD4A04A)],
                              track: _Palette.divider,
                              radius: 100,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Center(child: Text('Добавь товары с ценами в список',
                    style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13)))),
              ),
          ],
        ),
      ),
    );
  }
}

class _TemplateDetailsSheet extends StatelessWidget {
  final NutritionProvider provider;
  final MealTemplate template;
  const _TemplateDetailsSheet({required this.provider, required this.template});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: r.s(10)),
            Center(child: _grabber(r)),
            SizedBox(height: r.s(16)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.s(20)),
              child: Row(
                children: [
                  Container(
                    width: r.s(52), height: r.s(52),
                    decoration: BoxDecoration(color: _Palette.peachSoft, borderRadius: BorderRadius.circular(r.s(15))),
                    alignment: Alignment.center,
                    child: const Text('🍱', style: TextStyle(fontSize: 24)),
                  ),
                  SizedBox(width: r.s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.name,
                            style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(18), fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                        SizedBox(height: r.s(3)),
                        Text('${template.items.length} ингредиентов',
                            style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(12))),
                      ],
                    ),
                  ),
                  _TapScale(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: r.s(36), height: r.s(36),
                      decoration: BoxDecoration(color: _Palette.bg, shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: r.s(16), color: _Palette.text),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: r.s(16)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.s(20)),
              child: Container(
                padding: EdgeInsets.all(r.s(14)),
                decoration: BoxDecoration(
                  color: _Palette.bg,
                  borderRadius: BorderRadius.circular(r.s(16)),
                ),
                child: Row(
                  children: [
                    _macroMini('${template.calories.round()}', 'ккал', _Palette.peach, r),
                    _macroMini(template.protein.toStringAsFixed(0), 'Б', _Palette.green, r),
                    _macroMini(template.fat.toStringAsFixed(0), 'Ж', _Palette.peach, r),
                    _macroMini(template.carbs.toStringAsFixed(0), 'У', _Vibrant.amber, r),
                  ],
                ),
              ),
            ),
            SizedBox(height: r.s(20)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
                children: [
                  Text('ИНГРЕДИЕНТЫ',
                      style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  SizedBox(height: r.s(10)),
                  ...template.items.map((item) {
                    final p = provider.products.where((x) => x.id == item.productId).firstOrNull;
                    return Container(
                      margin: EdgeInsets.only(bottom: r.s(6)),
                      padding: EdgeInsets.all(r.s(12)),
                      decoration: BoxDecoration(
                        color: _Palette.bg,
                        borderRadius: BorderRadius.circular(r.s(12)),
                      ),
                      child: Row(
                        children: [
                          Text(p?.categoryEmoji ?? '🍽️', style: TextStyle(fontSize: r.s(18))),
                          SizedBox(width: r.s(10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(12), fontWeight: FontWeight.w600)),
                                Text('${item.grams.round()} г',
                                    style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroMini(String value, String unit, Color color, _R r) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(color: color, fontSize: r.fs(15), fontWeight: FontWeight.w600, letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          SizedBox(height: r.s(2)),
          Text(unit,
              style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}