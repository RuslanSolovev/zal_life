// features/nutrition/ui/screens/shopping_mode_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';

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
  static const divider = Color(0xFFE5E8E1);
}

class _Vibrant {
  static const neonGreen = Color(0xFF3DDC84);
  static const vividPeach = Color(0xFFFF8A65);
  static const electricBlue = Color(0xFF4A90E2);
  static const glowingPink = Color(0xFFFF6B8B);
  static const goldTop = Color(0xFFF4D06F);
  static const goldMid = Color(0xFFE8B858);
  static const goldBottom = Color(0xFFD4A04A);
  static const amber = Color(0xFFE8B858);
}

class _Dark {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF0F1419);
  static const surface = Color(0xFF1F262E);
  static const surfaceLight = Color(0xFF2A333D);
  static const border = Color(0xFF2D3640);
  static const text = Color(0xFFF5F5F7);
  static const textMuted = Color(0xFF8E949B);
}

class _R {
  final double scale;
  _R(BuildContext context)
      : scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

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
      top: Color(0xFF2B3A32), bottom: Color(0xFF1B2027), accent: Color(0xFF6C9E88)),
  _HeroTheme(id: 'forest', label: 'Лесной', emoji: '🌲',
      top: Color(0xFF2D4A3E), bottom: Color(0xFF1B3529), accent: Color(0xFF8CAB93)),
  _HeroTheme(id: 'sunset', label: 'Закат', emoji: '🌇',
      top: Color(0xFF5A2D3E), bottom: Color(0xFF2D1B2A), accent: Color(0xFFEF9563)),
  _HeroTheme(id: 'ocean', label: 'Морской', emoji: '🌊',
      top: Color(0xFF1B3A4F), bottom: Color(0xFF0F2537), accent: Color(0xFF7EA8C6)),
  _HeroTheme(id: 'desert', label: 'Пустыня', emoji: '🏜️',
      top: Color(0xFF4A3A28), bottom: Color(0xFF2A241B), accent: Color(0xFFE7D9B8)),
  _HeroTheme(id: 'taiga', label: 'Тайга', emoji: '🌲',
      top: Color(0xFF1E3530), bottom: Color(0xFF0E1F1B), accent: Color(0xFF6C9E88)),
  _HeroTheme(id: 'dawn', label: 'Рассвет', emoji: '🌅',
      top: Color(0xFF4A2D3A), bottom: Color(0xFF2D1B28), accent: Color(0xFFE899A8)),
];

const List<String> _heroBackgrounds = [
  'assets/images/nature_hero.jpg', 'assets/images/nature_hero2.jpg',
  'assets/images/nature_hero3.jpg', 'assets/images/nature_hero4.jpg',
  'assets/images/nature_hero5.jpg', 'assets/images/nature_hero6.jpg',
  'assets/images/nature_hero7.jpg', 'assets/images/nature_hero8.jpg',
  'assets/images/nature_hero9.jpg', 'assets/images/nature_hero10.jpg',
  'assets/images/nature_hero11.jpg', 'assets/images/nature_hero12.jpg',
  'assets/images/nature_hero13.jpg', 'assets/images/nature_hero14.jpg',
  'assets/images/nature_hero15.jpg', 'assets/images/nature_hero16.jpg',
  'assets/images/nature_hero17.jpg', 'assets/images/nature_hero18.jpg',
  'assets/images/nature_hero19.jpg', 'assets/images/nature_hero20.jpg',
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

String _fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final s = v.toStringAsFixed(2);
  if (s.endsWith('0')) return s.substring(0, s.length - 1);
  return s;
}

const List<String> _storeAisles = [
  'Овощи', 'Фрукты', 'Мясо', 'Рыба', 'Молочка', 'Хлеб',
  'Бакалея', 'Заморозка', 'Напитки', 'Сладости', 'Соусы', 'Другое',
];

String _categoryToAisle(String category) {
  switch (category) {
    case 'vegetables': return 'Овощи';
    case 'fruits': return 'Фрукты';
    case 'meat': return 'Мясо';
    case 'fish': return 'Рыба';
    case 'dairy': return 'Молочка';
    case 'bakery': case 'grains': return 'Бакалея';
    case 'drinks': return 'Напитки';
    case 'sweets': return 'Сладости';
    case 'sauces': return 'Соусы';
    default: return 'Другое';
  }
}

String _aisleEmoji(String aisle) {
  switch (aisle) {
    case 'Овощи': return '🥬'; case 'Фрукты': return '🍎';
    case 'Мясо': return '🥩'; case 'Рыба': return '🐟';
    case 'Молочка': return '🥛'; case 'Хлеб': return '🥐';
    case 'Бакалея': return '🌾'; case 'Заморозка': return '🧊';
    case 'Напитки': return '☕'; case 'Сладости': return '🍫';
    case 'Соусы': return '🧂'; default: return '🍽️';
  }
}

Color _aisleAccent(String aisle) {
  switch (aisle) {
    case 'Овощи': return const Color(0xFF6C9E88);
    case 'Фрукты': return const Color(0xFFFF8A65);
    case 'Мясо': return const Color(0xFFFF6B8B);
    case 'Рыба': return const Color(0xFF7EA8C6);
    case 'Молочка': return const Color(0xFFE8B858);
    case 'Хлеб': return const Color(0xFFD4A04A);
    case 'Бакалея': return const Color(0xFFA5C9AF);
    case 'Заморозка': return const Color(0xFF7EA8C6);
    case 'Напитки': return const Color(0xFF6C9E88);
    case 'Сладости': return const Color(0xFFFF6B8B);
    case 'Соусы': return const Color(0xFFEF9563);
    default: return const Color(0xFF8E949B);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class ShoppingModeScreen extends StatefulWidget {
  const ShoppingModeScreen({super.key});
  @override
  State<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends State<ShoppingModeScreen> with TickerProviderStateMixin {
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
    final value = prefs.getString('shopping_hero_bg') ?? 'current';
    if (mounted) setState(() => _heroBg = value);
  }

  Future<void> _saveBg(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopping_hero_bg', value);
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
    final allItems = provider.shoppingItems;
    final active = allItems.where((i) => !i.isBought).toList();
    final bought = allItems.where((i) => i.isBought).toList();

    final byAisle = <String, List<ShoppingItem>>{};
    for (final item in active) {
      final product = provider.products.where((p) => p.id == item.productId).firstOrNull;
      String aisle = 'Другое';
      if (item.category != null && item.category!.isNotEmpty) {
        aisle = item.category!;
      } else if (product != null) {
        aisle = _categoryToAisle(product.category);
      }
      byAisle.putIfAbsent(aisle, () => []).add(item);
    }
    final sortedAisles = _storeAisles.where((a) => byAisle.containsKey(a)).toList();
    final totalBudget = active.fold<double>(0, (s, i) => s + i.totalPrice);
    final progress = allItems.isEmpty ? 0.0 : bought.length / allItems.length;
    final recentBought = [...bought]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentPreview = recentBought.take(3).toList();

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _hero(allItems, active, bought, totalBudget, progress, provider)),
          SliverToBoxAdapter(child: _entranceAt(0.20, _statsBento(active, bought, totalBudget, sortedAisles, r))),
          if (recentPreview.isNotEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.25, _recentOperationsSection(recentBought, provider, r))),
          if (bought.isNotEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.28, _quickRebuy(allItems, provider, r))),
          if (sortedAisles.isNotEmpty) ...[
            SliverToBoxAdapter(child: _entranceAt(0.30, _sectionHeader('Отделы магазина', Icons.storefront_rounded, _Palette.green, r))),
            SliverToBoxAdapter(child: _entranceAt(0.35, _darkPremiumAislesBlock(sortedAisles, byAisle, provider, r))),
          ],
          if (sortedAisles.isEmpty && active.isEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.35, _emptyState(r))),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: _buildFab(provider, r),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color, _R r) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(28), r.s(20), r.s(12)),
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
  //  HERO
  // ═══════════════════════════════════════════════════════════════
  Widget _hero(List<ShoppingItem> all, List<ShoppingItem> active, List<ShoppingItem> bought,
      double totalBudget, double progress, NutritionProvider provider) {
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
                Image.asset(_heroBg, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [theme.top, theme.bottom],
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
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
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
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
                            Text('РЕЖИМ МАГАЗИНА',
                                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                            Text('Список покупок',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(18), fontWeight: FontWeight.w600, letterSpacing: -0.3,
                                    shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 6)])),
                          ],
                        ),
                      ),
                      _glassPill(Icons.share_rounded, () => _shareList(context), r),
                      SizedBox(width: r.s(8)),
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
                              boughtCount: bought.length,
                              totalCount: all.length,
                              totalBudget: totalBudget,
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
                      _heroLegendChip(accent, 'Прогресс', '${(progress * 100).round()}%', r),
                      _heroLegendChip(_Vibrant.neonGreen, 'Куплено', '${bought.length}', r),
                      _heroLegendChip(_Vibrant.vividPeach, 'Осталось', '${active.length}', r),
                      _heroLegendChip(_Palette.yellow, 'Бюджет', '${totalBudget.round()}₽', r),
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
          Container(width: r.s(6), height: r.s(6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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
                    decoration: BoxDecoration(color: _Palette.greenSoft, borderRadius: BorderRadius.circular(r.s(11))),
                    alignment: Alignment.center,
                    child: Icon(Icons.wallpaper_rounded, color: _Palette.green, size: r.s(19)),
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
                                  color: isSelected ? _Palette.green : Colors.white.withOpacity(0.9),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: _Palette.green.withOpacity(0.25), blurRadius: 10, spreadRadius: -2, offset: const Offset(0, 3))]
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
                                            child: Icon(Icons.check_rounded, color: _Palette.green, size: r.s(9)),
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
                                  color: isSelected ? _Palette.green : Colors.white.withOpacity(0.9),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: _Palette.green.withOpacity(0.25), blurRadius: 12, spreadRadius: -2, offset: const Offset(0, 4))]
                                    : null,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(path, fit: BoxFit.cover,
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
                                            child: Icon(Icons.check_rounded, color: _Palette.green, size: r.s(12)),
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
  //  STATS BENTO
  // ═══════════════════════════════════════════════════════════════
  Widget _statsBento(List<ShoppingItem> active, List<ShoppingItem> bought,
      double totalBudget, List<String> aisles, _R r) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: SizedBox(
        height: r.s(200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                padding: EdgeInsets.all(r.s(16)),
                decoration: BoxDecoration(
                  color: _Palette.peachSoft,
                  borderRadius: BorderRadius.circular(r.s(28)),
                  border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, color: _Palette.peach, size: r.s(16)),
                        SizedBox(width: r.s(6)),
                        Text('Бюджет',
                            style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(13), fontWeight: FontWeight.w500)),
                      ],
                    ),
                    SizedBox(height: r.s(12)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('${totalBudget.round()}',
                            style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(32), fontWeight: FontWeight.w400, letterSpacing: -1.3, fontFeatures: const [FontFeature.tabularFigures()])),
                        SizedBox(width: r.s(4)),
                        Text('₽', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(18), letterSpacing: -1)),
                      ],
                    ),
                    Text('на ${active.length} товаров',
                        style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(11))),
                    const Spacer(),
                    _GlossyProgress(
                      value: (totalBudget / 5000).clamp(0.0, 1.0),
                      height: r.s(6),
                      gradient: const [_Vibrant.vividPeach, _Palette.peach],
                      track: Colors.white.withOpacity(0.6),
                      radius: 100,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: r.s(12)),
            Expanded(
              flex: 4,
              child: Container(
                padding: EdgeInsets.all(r.s(16)),
                decoration: BoxDecoration(
                  color: _Palette.greenSoft,
                  borderRadius: BorderRadius.circular(r.s(28)),
                  border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.grid_view_rounded, color: _Palette.green, size: r.s(16)),
                        SizedBox(width: r.s(6)),
                        Text('Отделы',
                            style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(13), fontWeight: FontWeight.w500)),
                      ],
                    ),
                    SizedBox(height: r.s(12)),
                    Text('${aisles.length}',
                        style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(36), fontWeight: FontWeight.w400, letterSpacing: -1.5, fontFeatures: const [FontFeature.tabularFigures()])),
                    Text('отделов посетить',
                        style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(11))),
                    const Spacer(),
                    Wrap(
                      spacing: r.s(4), runSpacing: r.s(4),
                      children: aisles.take(6).map((a) {
                        return Container(
                          width: r.s(22), height: r.s(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(r.s(7)),
                          ),
                          alignment: Alignment.center,
                          child: Text(_aisleEmoji(a), style: TextStyle(fontSize: r.s(12))),
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
    );
  }

  Widget _recentOperationsSection(List<ShoppingItem> recentBought, NutritionProvider provider, _R r) {
    final totalSpent = recentBought.fold<double>(0, (s, i) => s + i.totalPrice);
    final preview = recentBought.take(3).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Container(
        padding: EdgeInsets.all(r.s(18)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Palette.green, Color(0xFF2D4A3E)],
          ),
          borderRadius: BorderRadius.circular(r.s(24)),
          boxShadow: [
            BoxShadow(color: _Palette.green.withOpacity(0.25), blurRadius: 18, spreadRadius: -4, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TapScale(
              onTap: () => _showAnalyticsSheet(recentBought, provider),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(r.s(8)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(r.s(10)),
                    ),
                    child: Icon(Icons.history_rounded, color: Colors.white, size: r.s(18)),
                  ),
                  SizedBox(width: r.s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ПОСЛЕДНИЕ ПОКУПКИ',
                            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.75), fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        Text('${preview.length} последних · ${totalSpent.round()} ₽',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(14), fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.6), size: r.s(12)),
                ],
              ),
            ),
            SizedBox(height: r.s(14)),
            ...preview.map((item) => _recentItemTile(item, provider, r)),
            SizedBox(height: r.s(8)),
            _TapScale(
              onTap: () => _showAnalyticsSheet(recentBought, provider),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: r.s(10)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(r.s(12)),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Открыть полную историю',
                        style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: r.fs(11), fontWeight: FontWeight.w600)),
                    SizedBox(width: r.s(4)),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.85), size: r.s(13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentItemTile(ShoppingItem item, NutritionProvider provider, _R r) {
    final product = provider.products.where((p) => p.id == item.productId).firstOrNull;
    final accent = _aisleAccent(_categoryToAisle(product?.category ?? 'other'));

    return Container(
      margin: EdgeInsets.only(bottom: r.s(6)),
      padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(10)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(r.s(12)),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: r.s(32), height: r.s(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(r.s(9)),
            ),
            alignment: Alignment.center,
            child: Text(product?.categoryEmoji ?? '📦', style: TextStyle(fontSize: r.s(16))),
          ),
          SizedBox(width: r.s(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displayName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(12), fontWeight: FontWeight.w600)),
                SizedBox(height: r.s(2)),
                Text('${_fmtNum(item.quantity)} ${item.unit} · ${_formatDate(item.createdAt)}',
                    style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: r.fs(10))),
              ],
            ),
          ),
          if (item.totalPrice > 0)
            Padding(
              padding: EdgeInsets.only(right: r.s(8)),
              child: Text('${item.totalPrice.round()} ₽',
                  style: GoogleFonts.inter(color: _Vibrant.neonGreen, fontSize: r.fs(11), fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          _TapScale(
            onTap: () => _confirmDeleteItem(item, provider),
            child: Container(
              width: r.s(28), height: r.s(28),
              decoration: BoxDecoration(
                color: _Palette.pink.withOpacity(0.25),
                borderRadius: BorderRadius.circular(r.s(8)),
              ),
              child: Icon(Icons.close_rounded, color: Colors.white, size: r.s(14)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteItem(ShoppingItem item, NutritionProvider provider) async {
    final r = _R(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(20))),
        title: Text('Удалить «${item.displayName}»?',
            style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(16), fontWeight: FontWeight.w600)),
        content: Text('Товар будет удалён из истории покупок.',
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
    if (confirm == true) {
      await provider.deleteShoppingItem(item.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🗑️ «${item.displayName}» удалён из истории'),
        backgroundColor: _Palette.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
      ));
    }
  }

  Widget _quickRebuy(List<ShoppingItem> allItems, NutritionProvider provider, _R r) {
    final bought = allItems.where((i) => i.isBought).toList();
    final Map<String, ShoppingItem> unique = {};
    for (final item in bought) {
      if (!unique.containsKey(item.displayName)) unique[item.displayName] = item;
    }
    final quickItems = unique.values.take(8).toList();
    if (quickItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(r.s(20), r.s(4), r.s(20), r.s(10)),
          child: Row(
            children: [
              Icon(Icons.flash_on_rounded, size: r.s(16), color: _Palette.peach),
              SizedBox(width: r.s(6)),
              Text('БЫСТРЫЙ ПОВТОР', style: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w700, color: _Palette.text, letterSpacing: 1.0)),
            ],
          ),
        ),
        SizedBox(
          height: r.s(100),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: r.s(20)),
            itemCount: quickItems.length,
            separatorBuilder: (_, __) => SizedBox(width: r.s(10)),
            itemBuilder: (context, index) {
              final item = quickItems[index];
              final product = provider.products.firstWhere((p) => p.id == item.productId,
                  orElse: () => FoodProduct(id: '', name: '', category: 'other', calories: 0, protein: 0, fat: 0, carbs: 0));
              final accent = product.category == 'other' ? _Palette.green : _aisleAccent(_categoryToAisle(product.category));
              return _TapScale(
                onTap: () {
                  provider.addShoppingItem(
                    customName: item.displayName,
                    quantity: item.quantity,
                    unit: item.unit,
                    estimatedPrice: item.estimatedPrice,
                    priceBasis: item.priceBasis,
                    category: item.category,
                  );
                  HapticFeedback.mediumImpact();
                },
                child: Container(
                  width: r.s(120),
                  padding: EdgeInsets.all(r.s(10)),
                  decoration: BoxDecoration(
                    color: _Palette.surface,
                    borderRadius: BorderRadius.circular(r.s(16)),
                    border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
                    boxShadow: [
                      BoxShadow(color: _Palette.green.withOpacity(0.05), blurRadius: 12, spreadRadius: -4, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: r.s(28), height: r.s(28),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(r.s(8)),
                            ),
                            alignment: Alignment.center,
                            child: Text(product.categoryEmoji.isEmpty ? '📦' : product.categoryEmoji, style: TextStyle(fontSize: r.s(14))),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.all(r.s(3)),
                            decoration: BoxDecoration(color: _Palette.greenSoft, borderRadius: BorderRadius.circular(r.s(6))),
                            child: Icon(Icons.add_rounded, size: r.s(12), color: _Palette.green),
                          ),
                        ],
                      ),
                      SizedBox(height: r.s(6)),
                      Expanded(
                        child: Text(item.displayName,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(11), fontWeight: FontWeight.w600, height: 1.2)),
                      ),
                      Text('${_fmtNum(item.quantity)} ${item.unit}',
                          style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(9), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  🌑 ТЁМНЫЙ ПРЕМИУМ БЛОК ОТДЕЛОВ (iPhone Dark Mode)
  // ═══════════════════════════════════════════════════════════════
  Widget _darkPremiumAislesBlock(List<String> sortedAisles, Map<String, List<ShoppingItem>> byAisle,
      NutritionProvider provider, _R r) {
    final totalItems = sortedAisles.fold<int>(0, (s, a) => s + byAisle[a]!.length);
    final totalBudget = sortedAisles.fold<double>(0, (s, a) {
      return s + byAisle[a]!.fold<double>(0, (ss, i) => ss + i.totalPrice);
    });

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Dark.bgTop, _Dark.bgBottom],
          ),
          borderRadius: BorderRadius.circular(r.s(26)),
          border: Border.all(color: _Dark.border.withOpacity(0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: -8,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: _Vibrant.neonGreen.withOpacity(0.08),
              blurRadius: 40,
              spreadRadius: -10,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎨 Премиальный header с glass-эффектом
            Container(
              padding: EdgeInsets.all(r.s(18)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _Dark.surface.withOpacity(0.8),
                    _Dark.bgTop,
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: _Dark.border.withOpacity(0.5), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: r.s(52), height: r.s(52),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _Vibrant.neonGreen.withOpacity(0.30),
                          _Palette.green.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(r.s(15)),
                      border: Border.all(color: _Vibrant.neonGreen.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: _Vibrant.neonGreen.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.storefront_rounded, color: Colors.white, size: r.s(26)),
                  ),
                  SizedBox(width: r.s(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Маршрут по магазину',
                            style: GoogleFonts.inter(
                              color: _Dark.text,
                              fontSize: r.fs(16),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            )),
                        SizedBox(height: r.s(3)),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(3)),
                              decoration: BoxDecoration(
                                color: _Vibrant.neonGreen.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(r.s(7)),
                                border: Border.all(color: _Vibrant.neonGreen.withOpacity(0.3)),
                              ),
                              child: Text('${sortedAisles.length} ${_aislesWord(sortedAisles.length)}',
                                  style: GoogleFonts.inter(
                                    color: _Vibrant.neonGreen,
                                    fontSize: r.fs(10),
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                            SizedBox(width: r.s(6)),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(3)),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(r.s(7)),
                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Text('$totalItems ${_itemsWord(totalItems)}',
                                  style: GoogleFonts.inter(
                                    color: _Dark.text,
                                    fontSize: r.fs(10),
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (totalBudget > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(8)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _Vibrant.amber.withOpacity(0.25),
                            _Vibrant.amber.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(r.s(12)),
                        border: Border.all(color: _Vibrant.amber.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: _Vibrant.amber.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('ИТОГО',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: r.fs(9),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              )),
                          Text('${totalBudget.toStringAsFixed(0)} ₽',
                              style: GoogleFonts.inter(
                                color: _Vibrant.amber,
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
            // 📋 Список отделов как секций
            ...sortedAisles.asMap().entries.map((entry) {
              final aisle = entry.value;
              final items = byAisle[aisle]!;
              final isFirst = entry.key == 0;
              final isLast = entry.key == sortedAisles.length - 1;
              return _darkAisleSection(aisle, items, provider, r, isFirst: isFirst, isLast: isLast);
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  🎯 СЕКЦИЯ ОТДЕЛА (тёмная тема с цветным акцентом)
  // ═══════════════════════════════════════════════════════════════
  Widget _darkAisleSection(String aisle, List<ShoppingItem> items, NutritionProvider provider, _R r,
      {required bool isFirst, required bool isLast}) {
    final accent = _aisleAccent(aisle);
    final aisleTotal = items.fold<double>(0, (s, i) => s + i.totalPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок отдела с толстым цветным бордером слева
        _TapScale(
          onTap: () => _showAisleFocusMode(aisle, items, provider),
          child: Container(
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(14), r.s(14), r.s(14)),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accent, width: r.s(4)),
                top: isFirst ? BorderSide.none : BorderSide(color: _Dark.border.withOpacity(0.4), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Эмодзи в круглом контейнере с градиентом
                Container(
                  width: r.s(44), height: r.s(44),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withOpacity(0.30),
                        accent.withOpacity(0.10),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(color: accent.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(_aisleEmoji(aisle), style: TextStyle(fontSize: r.s(22))),
                ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(aisle,
                          style: GoogleFonts.inter(
                            color: _Dark.text,
                            fontSize: r.fs(15),
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          )),
                      SizedBox(height: r.s(3)),
                      Row(
                        children: [
                          Text('${items.length} ${_itemsWord(items.length)}',
                              style: GoogleFonts.inter(
                                color: _Dark.textMuted,
                                fontSize: r.fs(11),
                                fontWeight: FontWeight.w500,
                              )),
                          if (aisleTotal > 0) ...[
                            SizedBox(width: r.s(6)),
                            Container(
                              width: r.s(3), height: r.s(3),
                              decoration: BoxDecoration(
                                color: _Dark.textMuted.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: r.s(6)),
                            Text('${aisleTotal.round()} ₽',
                                style: GoogleFonts.inter(
                                  color: accent,
                                  fontSize: r.fs(11),
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                )),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(r.s(6)),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(r.s(8)),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.chevron_right_rounded, color: accent, size: r.s(16)),
                ),
              ],
            ),
          ),
        ),
        // Товары внутри отдела
        ...items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLastItem = entry.key == items.length - 1;
          return _darkShoppingTileWithSwipe(item, provider, r, isLast: isLastItem && isLast);
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  🆕 TILE С ДВОЙНЫМ СВАЙПОМ (тёмная тема)
  //  → Свайп вправо = Купить (с подтверждением)
  //  ← Свайп влево = Удалить
  // ═══════════════════════════════════════════════════════════════
  Widget _darkShoppingTileWithSwipe(ShoppingItem item, NutritionProvider provider, _R r, {bool isLast = false}) {
    final product = provider.products.where((p) => p.id == item.productId).firstOrNull;
    final isUrgent = item.isUrgent;
    final fallbackName = item.fallbackName;
    final accent = product?.category == 'other' ? _Palette.green : _aisleAccent(_categoryToAisle(product?.category ?? ''));

    return Dismissible(
      key: Key('shopping_swipe_${item.id}'),
      direction: DismissDirection.horizontal,
      // 🟢 СВАЙП ВПРАВО = КУПИТЬ (с подтверждением)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: r.s(20)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _Vibrant.neonGreen.withOpacity(0.25),
              _Dark.surface,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(r.s(8)),
              decoration: BoxDecoration(
                color: _Vibrant.neonGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _Vibrant.neonGreen.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.check_rounded, color: Colors.white, size: r.s(20)),
            ),
            SizedBox(width: r.s(10)),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Купить',
                    style: GoogleFonts.inter(
                      color: _Vibrant.neonGreen,
                      fontSize: r.fs(12),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    )),
                Text('подтвердите',
                    style: GoogleFonts.inter(
                      color: _Vibrant.neonGreen.withOpacity(0.7),
                      fontSize: r.fs(9),
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ],
        ),
      ),
      // 🔴 СВАЙП ВЛЕВО = УДАЛИТЬ
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: r.s(20)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _Dark.surface,
              _Vibrant.glowingPink.withOpacity(0.25),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Удалить',
                    style: GoogleFonts.inter(
                      color: _Vibrant.glowingPink,
                      fontSize: r.fs(12),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    )),
                Text('из списка',
                    style: GoogleFonts.inter(
                      color: _Vibrant.glowingPink.withOpacity(0.7),
                      fontSize: r.fs(9),
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
            SizedBox(width: r.s(10)),
            Container(
              padding: EdgeInsets.all(r.s(8)),
              decoration: BoxDecoration(
                color: _Vibrant.glowingPink,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _Vibrant.glowingPink.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.delete_rounded, color: Colors.white, size: r.s(20)),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Свайп вправо = Купить → подтверждаем
          return await _confirmBuyItem(item);
        } else {
          // Свайп влево = Удалить → подтверждаем
          return await _confirmDeleteFromList(item);
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Помечаем как купленное
          await provider.toggleShoppingItem(item.id);
          if (!mounted) return;
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: r.s(8)),
                Text('✅ «${item.displayName}» куплен'),
              ],
            ),
            backgroundColor: _Palette.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
          ));
        } else {
          // Удаляем
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
        }
      },
      child: _TapScale(
        onTap: () => _confirmBuyItem(item).then((confirmed) {
          if (confirmed == true) {
            provider.toggleShoppingItem(item.id);
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: r.s(8)),
                  Text('✅ «${item.displayName}» куплен'),
                ],
              ),
              backgroundColor: _Palette.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
            ));
          }
        }),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(12)),
          decoration: BoxDecoration(
            border: isLast ? null : Border(bottom: BorderSide(color: _Dark.border.withOpacity(0.4), width: 0.5)),
          ),
          child: Row(
            children: [
              // Чекбокс (тёмная тема)
              GestureDetector(
                onTap: () => _confirmBuyItem(item).then((confirmed) {
                  if (confirmed == true) {
                    provider.toggleShoppingItem(item.id);
                    HapticFeedback.mediumImpact();
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: r.s(26), height: r.s(26),
                  decoration: BoxDecoration(
                    color: item.isBought ? _Vibrant.neonGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(r.s(7)),
                    border: item.isBought ? null : Border.all(color: _Dark.border, width: 2),
                    boxShadow: item.isBought
                        ? [BoxShadow(color: _Vibrant.neonGreen.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: item.isBought ? Icon(Icons.check_rounded, size: r.s(15), color: Colors.white) : const SizedBox(),
                ),
              ),
              SizedBox(width: r.s(12)),
              // Эмодзи
              Container(
                width: r.s(38), height: r.s(38),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(r.s(10)),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                child: Text(product?.categoryEmoji ?? '📦', style: TextStyle(fontSize: r.s(18))),
              ),
              SizedBox(width: r.s(12)),
              // Инфо
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
                                color: item.isBought ? _Dark.textMuted : _Dark.text,
                                fontSize: r.fs(13.5), fontWeight: FontWeight.w600,
                                decoration: item.isBought ? TextDecoration.lineThrough : null,
                                decorationColor: _Vibrant.neonGreen,
                                decorationThickness: 2,
                              )),
                        ),
                        if (isUrgent && !item.isBought)
                          Container(
                            margin: EdgeInsets.only(left: r.s(6)),
                            padding: EdgeInsets.symmetric(horizontal: r.s(6), vertical: r.s(2)),
                            decoration: BoxDecoration(
                              color: _Vibrant.glowingPink.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(r.s(5)),
                              border: Border.all(color: _Vibrant.glowingPink.withOpacity(0.5)),
                            ),
                            child: Text('СРОЧНО',
                                style: GoogleFonts.inter(
                                  color: _Vibrant.glowingPink,
                                  fontSize: r.fs(8),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                )),
                          ),
                      ],
                    ),
                    if (fallbackName != null && fallbackName.isNotEmpty && !item.isBought)
                      Padding(
                        padding: EdgeInsets.only(top: r.s(3)),
                        child: Row(
                          children: [
                            Icon(Icons.sync_alt_rounded, size: r.s(10), color: _Palette.sage),
                            SizedBox(width: r.s(4)),
                            Expanded(
                              child: Text('→ $fallbackName',
                                  style: GoogleFonts.inter(
                                    color: _Palette.sage,
                                    fontSize: r.fs(10),
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: r.s(8)),
              // Количество + цена
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_fmtNum(item.quantity)} ${item.unit}',
                      style: GoogleFonts.inter(
                        color: _Dark.textMuted,
                        fontSize: r.fs(11),
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                  if (item.estimatedPrice != null && item.estimatedPrice! > 0)
                    Text('${item.totalPrice.round()} ₽',
                        style: GoogleFonts.inter(
                          color: _Vibrant.amber,
                          fontSize: r.fs(12),
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

  // 🆕 Подтверждение покупки
  Future<bool?> _confirmBuyItem(ShoppingItem item) async {
    final r = _R(context);
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(20))),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(r.s(8)),
              decoration: BoxDecoration(
                color: _Palette.greenSoft,
                borderRadius: BorderRadius.circular(r.s(10)),
              ),
              child: const Icon(Icons.shopping_cart_rounded, color: _Palette.green, size: 18),
            ),
            SizedBox(width: r.s(10)),
            Expanded(
              child: Text('Купить?',
                  style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(16), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('«${item.displayName}»',
                style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(14), fontWeight: FontWeight.w600)),
            SizedBox(height: r.s(4)),
            Text('${_fmtNum(item.quantity)} ${item.unit}',
                style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13))),
            if (item.totalPrice > 0) ...[
              SizedBox(height: r.s(8)),
              Container(
                padding: EdgeInsets.all(r.s(10)),
                decoration: BoxDecoration(
                  color: _Palette.greenSoft,
                  borderRadius: BorderRadius.circular(r.s(10)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money_rounded, color: _Palette.green, size: r.s(16)),
                    SizedBox(width: r.s(6)),
                    Text('${item.totalPrice.round()} ₽',
                        style: GoogleFonts.inter(
                          color: _Palette.green,
                          fontSize: r.fs(15),
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Отмена', style: GoogleFonts.inter(color: _Palette.textMuted))),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Купить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Palette.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(10))),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 Подтверждение удаления из списка
  Future<bool?> _confirmDeleteFromList(ShoppingItem item) async {
    final r = _R(context);
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
  }

  Widget _emptyState(_R r) {
    return Padding(
      padding: EdgeInsets.all(r.s(40)),
      child: Column(
        children: [
          Container(
            width: r.s(80), height: r.s(80),
            decoration: BoxDecoration(
              color: _Palette.greenSoft,
              borderRadius: BorderRadius.circular(r.s(24)),
            ),
            alignment: Alignment.center,
            child: Text('🛒', style: TextStyle(fontSize: r.s(40))),
          ),
          SizedBox(height: r.s(16)),
          Text('Список пуст',
              style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(16), fontWeight: FontWeight.w600, letterSpacing: -0.3)),
          SizedBox(height: r.s(6)),
          Text('Добавьте товары вручную или из плана',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13), fontWeight: FontWeight.w400, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildFab(NutritionProvider provider, _R r) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Vibrant.neonGreen, _Palette.green],
        ),
        boxShadow: [
          BoxShadow(color: _Palette.green.withOpacity(0.4), blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 8)),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showAddItemSheet(provider),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        child: Icon(Icons.add_rounded, size: r.s(26)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  🆕 ШТОРКА ФОКУСА ОТДЕЛА (с кнопкой удаления)
  // ═══════════════════════════════════════════════════════════════
  void _showAisleFocusMode(String aisle, List<ShoppingItem> items, NutritionProvider provider) {
    final r = _R(context);
    final accent = _aisleAccent(aisle);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.98,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_Dark.bgTop, _Dark.bgBottom],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
            border: Border.all(color: _Dark.border.withOpacity(0.6)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: r.s(12)),
                child: Center(child: Container(width: r.s(38), height: r.s(5), decoration: BoxDecoration(color: _Dark.border, borderRadius: BorderRadius.circular(r.s(3))))),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(16)),
                child: Row(
                  children: [
                    Container(
                      width: r.s(56), height: r.s(56),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent.withOpacity(0.30), accent.withOpacity(0.10)],
                        ),
                        boxShadow: [
                          BoxShadow(color: accent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 3)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(_aisleEmoji(aisle), style: TextStyle(fontSize: r.s(28))),
                    ),
                    SizedBox(width: r.s(14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aisle, style: GoogleFonts.inter(color: _Dark.text, fontSize: r.fs(20), fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                          Text('${items.length} ${_itemsWord(items.length)}',
                              style: GoogleFonts.inter(color: _Dark.textMuted, fontSize: r.fs(13))),
                        ],
                      ),
                    ),
                    _TapScale(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: EdgeInsets.all(r.s(10)),
                        decoration: BoxDecoration(
                          color: _Dark.surface,
                          borderRadius: BorderRadius.circular(r.s(12)),
                          border: Border.all(color: _Dark.border),
                        ),
                        child: Icon(Icons.close_rounded, color: _Dark.text, size: r.s(20)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isLast = index == items.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(bottom: r.s(8)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _Dark.surface,
                          borderRadius: BorderRadius.circular(r.s(16)),
                          border: Border.all(color: _Dark.border.withOpacity(0.6)),
                        ),
                        child: _darkShoppingTileWithDelete(item, provider, r, isLast: isLast),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(r.s(16)),
                child: SizedBox(
                  width: double.infinity, height: r.s(52),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Vibrant.neonGreen, foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
                    ),
                    child: Text('ГОТОВО', style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  🆕 TILE С ЯВНОЙ КНОПКОЙ УДАЛЕНИЯ (для шторки)
  // ═══════════════════════════════════════════════════════════════
  Widget _darkShoppingTileWithDelete(ShoppingItem item, NutritionProvider provider, _R r, {bool isLast = false}) {
    final product = provider.products.where((p) => p.id == item.productId).firstOrNull;
    final accent = product?.category == 'other' ? _Palette.green : _aisleAccent(_categoryToAisle(product?.category ?? ''));

    return Dismissible(
      key: Key('aisle_focus_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: r.s(20)),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_Vibrant.glowingPink.withOpacity(0.25), _Dark.surface]),
          borderRadius: BorderRadius.circular(r.s(16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.delete_rounded, color: _Vibrant.glowingPink, size: r.s(22)),
            SizedBox(height: r.s(3)),
            Text('Удалить', style: GoogleFonts.inter(color: _Vibrant.glowingPink, fontSize: r.fs(10), fontWeight: FontWeight.w700)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
        ));
      },
      child: Padding(
        padding: EdgeInsets.all(r.s(14)),
        child: Row(
          children: [
            // Чекбокс (тоже с подтверждением)
            GestureDetector(
              onTap: () => _confirmBuyItem(item).then((confirmed) {
                if (confirmed == true) {
                  provider.toggleShoppingItem(item.id);
                  HapticFeedback.mediumImpact();
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: r.s(26), height: r.s(26),
                decoration: BoxDecoration(
                  color: item.isBought ? _Vibrant.neonGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(r.s(7)),
                  border: item.isBought ? null : Border.all(color: _Dark.border, width: 2),
                ),
                child: item.isBought ? Icon(Icons.check_rounded, size: r.s(15), color: Colors.white) : const SizedBox(),
              ),
            ),
            SizedBox(width: r.s(12)),
            Container(
              width: r.s(38), height: r.s(38),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(r.s(10)),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              alignment: Alignment.center,
              child: Text(product?.categoryEmoji ?? '📦', style: TextStyle(fontSize: r.s(18))),
            ),
            SizedBox(width: r.s(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.displayName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: item.isBought ? _Dark.textMuted : _Dark.text,
                        fontSize: r.fs(13), fontWeight: FontWeight.w600,
                        decoration: item.isBought ? TextDecoration.lineThrough : null,
                        decorationColor: _Vibrant.neonGreen,
                      )),
                  SizedBox(height: r.s(2)),
                  Text('${_fmtNum(item.quantity)} ${item.unit}',
                      style: GoogleFonts.inter(color: _Dark.textMuted, fontSize: r.fs(11), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (item.totalPrice > 0)
              Padding(
                padding: EdgeInsets.only(right: r.s(10)),
                child: Text('${item.totalPrice.round()} ₽',
                    style: GoogleFonts.inter(color: _Vibrant.amber, fontSize: r.fs(13), fontWeight: FontWeight.w700)),
              ),
            // 🆕 ЯВНАЯ КНОПКА УДАЛЕНИЯ
            _TapScale(
              onTap: () => _confirmDeleteFromSheet(item, provider),
              child: Container(
                width: r.s(32), height: r.s(32),
                decoration: BoxDecoration(
                  color: _Vibrant.glowingPink.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(r.s(9)),
                  border: Border.all(color: _Vibrant.glowingPink.withOpacity(0.4)),
                ),
                child: Icon(Icons.close_rounded, color: _Vibrant.glowingPink, size: r.s(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 Подтверждение удаления из шторки
  Future<void> _confirmDeleteFromSheet(ShoppingItem item, NutritionProvider provider) async {
    final r = _R(context);
    final confirm = await showDialog<bool>(
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
    if (confirm == true) {
      await provider.deleteShoppingItem(item.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🗑️ «${item.displayName}» удалён'),
        backgroundColor: _Palette.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
      ));
    }
  }

  Future<void> _showAddItemSheet(NutritionProvider provider) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AddItemBottomSheet(provider: provider),
    );
  }

  Future<void> _shareList(BuildContext context) async {
    final provider = context.read<NutritionProvider>();
    final active = provider.shoppingItems.where((i) => !i.isBought).toList();
    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Список пуст'), backgroundColor: _Palette.pink, behavior: SnackBarBehavior.floating));
      return;
    }
    final byAisle = <String, List<ShoppingItem>>{};
    for (final item in active) {
      final product = provider.products.where((p) => p.id == item.productId).firstOrNull;
      String aisle = 'Другое';
      if (item.category != null && item.category!.isNotEmpty)
        aisle = item.category!;
      else if (product != null) aisle = _categoryToAisle(product.category);
      byAisle.putIfAbsent(aisle, () => []).add(item);
    }
    final buffer = StringBuffer();
    buffer.writeln('🛒 Список покупок\n');
    for (final aisle in _storeAisles) {
      final items = byAisle[aisle];
      if (items == null || items.isEmpty) continue;
      buffer.writeln('${_aisleEmoji(aisle)} *$aisle*');
      for (final item in items) buffer.writeln('• ${item.displayName} — ${_fmtNum(item.quantity)} ${item.unit}');
      buffer.writeln();
    }
    final total = active.fold<double>(0, (s, i) => s + i.totalPrice);
    buffer.writeln('💰 *Итого: ~${total.toStringAsFixed(0)} ₽*');
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('✅ Скопировано'), backgroundColor: _Palette.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));
  }

  void _showAnalyticsSheet(List<ShoppingItem> initialBoughtItems, NutritionProvider provider) {
    final r = _R(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Пересчитываем данные при каждом обновлении шторки
          final boughtItems = provider.shoppingItems.where((i) => i.isBought).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final Map<String, List<ShoppingItem>> historyByDay = {};
          double totalSpent = 0;
          for (final item in boughtItems) {
            totalSpent += item.totalPrice;
            final dateKey = _formatDate(item.createdAt);
            if (!historyByDay.containsKey(dateKey)) historyByDay[dateKey] = [];
            historyByDay[dateKey]!.add(item);
          }
          final sortedDays = historyByDay.keys.toList()..sort((a, b) => b.compareTo(a));

          return DraggableScrollableSheet(
            initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: _Palette.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: r.s(12)),
                    child: Center(child: Container(width: r.s(38), height: r.s(5), decoration: BoxDecoration(color: _Palette.divider, borderRadius: BorderRadius.circular(r.s(3))))),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(16)),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(r.s(10)),
                          decoration: BoxDecoration(color: _Palette.greenSoft, borderRadius: BorderRadius.circular(r.s(12))),
                          child: Icon(Icons.history_rounded, color: _Palette.green, size: r.s(22)),
                        ),
                        SizedBox(width: r.s(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ИСТОРИЯ ПОКУПОК', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                              Text('Последние операции', style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(18), fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: r.s(20), vertical: r.s(8)),
                      children: [
                        Container(
                          padding: EdgeInsets.all(r.s(20)),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_Vibrant.vividPeach, _Palette.peach],
                            ),
                            borderRadius: BorderRadius.circular(r.s(20)),
                            boxShadow: [
                              BoxShadow(color: _Palette.peach.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ВСЕГО ПОТРАЧЕНО', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: r.fs(11), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                                  SizedBox(height: r.s(6)),
                                  Text('${totalSpent.round()} ₽',
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(32), fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()])),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('ПОЗИЦИЙ', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: r.fs(11), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                                  SizedBox(height: r.s(6)),
                                  Text('${boughtItems.length}',
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(32), fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()])),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: r.s(24)),
                        if (sortedDays.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(r.s(20)),
                              child: Text('Пока нет купленных товаров',
                                  style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(14))),
                            ),
                          )
                        else
                          ...sortedDays.map((day) {
                            final dayItems = historyByDay[day]!;
                            final dayTotal = dayItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
                            final date = dayItems.first.createdAt;
                            final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                            return Padding(
                              padding: EdgeInsets.only(bottom: r.s(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(6)),
                                        decoration: BoxDecoration(color: _Palette.peachSoft, borderRadius: BorderRadius.circular(r.s(8))),
                                        child: Text(day, style: GoogleFonts.inter(color: _Palette.peach, fontSize: r.fs(11), fontWeight: FontWeight.w700)),
                                      ),
                                      SizedBox(width: r.s(8)),
                                      Text(timeStr, style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(11))),
                                      const Spacer(),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(4)),
                                        decoration: BoxDecoration(color: _Palette.greenSoft, borderRadius: BorderRadius.circular(r.s(6))),
                                        child: Text('${dayTotal.round()} ₽',
                                            style: GoogleFonts.inter(color: _Palette.green, fontSize: r.fs(11), fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: r.s(8)),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _Palette.bg,
                                      borderRadius: BorderRadius.circular(r.s(16)),
                                    ),
                                    child: Column(
                                      children: dayItems.map((item) {
                                        final product = provider.products.firstWhere((p) => p.id == item.productId,
                                            orElse: () => FoodProduct(id: '', name: '', category: 'other', calories: 0, protein: 0, fat: 0, carbs: 0));
                                        return Padding(
                                          padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(10)),
                                          child: Row(
                                            children: [
                                              Text(product.categoryEmoji.isEmpty ? '📦' : product.categoryEmoji, style: TextStyle(fontSize: r.s(16))),
                                              SizedBox(width: r.s(12)),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(item.displayName,
                                                        style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(13), fontWeight: FontWeight.w600)),
                                                    Text('${_fmtNum(item.quantity)} ${item.unit}',
                                                        style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(11))),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(right: r.s(8)),
                                                child: Text('+${item.totalPrice.round()} ₽',
                                                    style: GoogleFonts.inter(color: _Palette.green, fontSize: r.fs(13), fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
                                              ),
                                              // 🆕 КНОПКА УДАЛЕНИЯ
                                              _TapScale(
                                                onTap: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: ctx,
                                                    builder: (dialogCtx) => AlertDialog(
                                                      backgroundColor: _Palette.surface,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(20))),
                                                      title: Text('Удалить «${item.displayName}»?',
                                                          style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(16), fontWeight: FontWeight.w600)),
                                                      content: Text('Товар будет удалён из истории покупок.',
                                                          style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13))),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(dialogCtx, false),
                                                            child: Text('Отмена', style: GoogleFonts.inter(color: _Palette.textMuted))),
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(dialogCtx, true),
                                                          style: TextButton.styleFrom(foregroundColor: _Palette.pink),
                                                          child: const Text('Удалить', style: TextStyle(fontWeight: FontWeight.w600)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) {
                                                    await provider.deleteShoppingItem(item.id);
                                                    if (!mounted) return;
                                                    HapticFeedback.mediumImpact();
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                      content: Text('🗑️ «${item.displayName}» удалён из истории'),
                                                      backgroundColor: _Palette.pink,
                                                      behavior: SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
                                                    ));
                                                    // Обновляем UI шторки
                                                    setSheetState(() {});
                                                  }
                                                },
                                                child: Container(
                                                  width: r.s(28),
                                                  height: r.s(28),
                                                  decoration: BoxDecoration(
                                                    color: _Palette.pinkSoft,
                                                    borderRadius: BorderRadius.circular(r.s(8)),
                                                  ),
                                                  child: Icon(Icons.close_rounded, color: _Palette.pink, size: r.s(14)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        SizedBox(height: r.s(40)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    if (diff < 7) return '$diff дн. назад';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _itemsWord(int n) => n == 1 ? 'позиция' : (n >= 2 && n <= 4 ? 'позиции' : 'позиций');
  String _aislesWord(int n) => n == 1 ? 'отдел' : (n >= 2 && n <= 4 ? 'отдела' : 'отделов');
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final int boughtCount;
  final int totalCount;
  final double totalBudget;
  final double scale;
  final Color accent;

  _ProgressRingPainter({
    required this.progress, required this.boughtCount,
    required this.totalCount, required this.totalBudget,
    required this.scale, required this.accent,
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
        final color = Color.lerp(_Vibrant.vividPeach, _Vibrant.neonGreen, t)!;
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
          Paint()..color = _Vibrant.neonGreen.withOpacity(0.55)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7));
      canvas.drawCircle(dotPos, stroke * 0.65, Paint()..color = _Vibrant.neonGreen);
      canvas.drawCircle(dotPos, stroke * 0.28, Paint()..color = Colors.white);
    }

    _drawCenterText(canvas, center, '${(progress * 100).round()}%', 36 * scale, Colors.white, FontWeight.w600, -20 * scale);
    _drawCenterText(canvas, center, 'куплено', 12 * scale, Colors.white.withOpacity(0.7), FontWeight.w500, 8 * scale);
    _drawCenterText(canvas, center, '$boughtCount / $totalCount', 14 * scale, _Vibrant.neonGreen, FontWeight.w700, 28 * scale);
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
      old.progress != progress || old.boughtCount != boughtCount || old.totalCount != totalCount;
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

class _AddItemBottomSheet extends StatefulWidget {
  final NutritionProvider provider;
  const _AddItemBottomSheet({required this.provider});
  @override
  State<_AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<_AddItemBottomSheet> with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _fallbackCtrl = TextEditingController();

  String _qtyUnit = 'шт';
  String _priceUnit = 'за шт';
  bool _hasFallback = false;
  String? _selectedCategory = 'Другое';
  final List<String> _availableAisles = ['Овощи', 'Фрукты', 'Мясо', 'Рыба', 'Молочка', 'Хлеб', 'Бакалея', 'Напитки', 'Другое'];
  List<ShoppingItem> _suggestions = [];

  late final AnimationController _snapController;
  late final Animation<double> _snapScale;

  @override
  void initState() {
    super.initState();
    if (_dimOfPrice(_priceUnit) != _dimOf(_qtyUnit)) _qtyUnit = _defaultQtyUnitFor(_dimOfPrice(_priceUnit));
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _snapScale = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOutBack));
    _snapController.addStatusListener((status) { if (status == AnimationStatus.completed) _snapController.reverse(); });
    _nameCtrl.addListener(_updateSuggestions);
  }

  void _updateSuggestions() {
    final query = _nameCtrl.text.trim().toLowerCase();
    if (query.length < 2) { setState(() => _suggestions = []); return; }
    final all = widget.provider.shoppingItems;
    final matches = all.where((item) => item.displayName.toLowerCase().contains(query)).toList();
    final Map<String, ShoppingItem> unique = {};
    for (var item in matches) unique[item.displayName] = item;
    setState(() { _suggestions = unique.values.take(3).toList(); });
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_updateSuggestions);
    _nameCtrl.dispose(); _qtyCtrl.dispose(); _priceCtrl.dispose(); _fallbackCtrl.dispose(); _snapController.dispose();
    super.dispose();
  }

  void _triggerSnap() { _snapController.forward(from: 0.0); HapticFeedback.lightImpact(); }

  double get _calculatedTotal {
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    if (qty <= 0 || price <= 0) return 0;
    return _qtyToBase(qty, _qtyUnit) * _priceToBase(price, _priceUnit);
  }

  String _getHumanFormula() {
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    if (qty <= 0 || price <= 0) return 'Введите количество и цену для расчёта';
    return '${_fmtNum(qty)} $_qtyUnit × ${_fmtNum(price)} ${_priceSuffixFor(_priceUnit)} = ${_fmtNum(_calculatedTotal)} ₽';
  }

  List<Map<String, dynamic>> _getQuickPresets() {
    final dim = _dimOf(_qtyUnit);
    if (dim == _Dim.mass) return [{'v': 100, 'u': 'г'}, {'v': 500, 'u': 'г'}, {'v': 1, 'u': 'кг'}];
    if (dim == _Dim.volume) return [{'v': 250, 'u': 'мл'}, {'v': 500, 'u': 'мл'}, {'v': 1, 'u': 'л'}];
    return [{'v': 1, 'u': 'шт'}, {'v': 2, 'u': 'шт'}, {'v': 3, 'u': 'шт'}];
  }

  void _onQtyUnitChanged(String newUnit) {
    setState(() {
      _qtyUnit = newUnit;
      if (_dimOfPrice(_priceUnit) != _dimOf(newUnit)) _priceUnit = _defaultPriceBasisFor(_dimOf(newUnit));
    });
  }

  void _onPriceBasisChanged(String newBasis) {
    setState(() {
      _priceUnit = newBasis;
      final dim = _dimOfPrice(newBasis);
      if (_dimOf(_qtyUnit) != dim) { _qtyUnit = _defaultQtyUnitFor(dim); _triggerSnap(); }
    });
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _qtyCtrl.text = preset['v'].toString();
      if (_qtyUnit != preset['u']) {
        _qtyUnit = preset['u'];
        if (_dimOfPrice(_priceUnit) != _dimOf(_qtyUnit)) _priceUnit = _defaultPriceBasisFor(_dimOf(_qtyUnit));
        _triggerSnap();
      }
    });
  }

  void _applySuggestion(ShoppingItem suggestion) {
    setState(() {
      _nameCtrl.text = suggestion.displayName;
      _qtyCtrl.text = suggestion.quantity.toString();
      _qtyUnit = suggestion.unit;
      _priceCtrl.text = suggestion.estimatedPrice?.toString() ?? '';
      _priceUnit = _labelFromBasis(suggestion.priceBasis);
      final fallback = suggestion.fallbackName;
      if (fallback != null && fallback.isNotEmpty) { _hasFallback = true; _fallbackCtrl.text = fallback; }
      else { _hasFallback = false; _fallbackCtrl.clear(); }
      if (suggestion.category != null && suggestion.category!.isNotEmpty) _selectedCategory = suggestion.category;
      else _selectedCategory = 'Другое';
      _suggestions = [];
      _triggerSnap();
    });
    HapticFeedback.mediumImpact();
  }

  void _saveItem() {
    final name = _nameCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final fallback = _hasFallback ? _fallbackCtrl.text.trim() : null;
    if (name.isEmpty || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Заполните название и количество'), backgroundColor: _Palette.pink, behavior: SnackBarBehavior.floating));
      return;
    }
    widget.provider.addShoppingItem(
      customName: name, quantity: qty, unit: _qtyUnit,
      estimatedPrice: price > 0 ? price : null,
      priceBasis: _basisFromLabel(_priceUnit),
      fallbackName: fallback,
      category: _selectedCategory == 'Другое' ? null : _selectedCategory,
    );
    if (!mounted) return;
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    final r = _R(context);
    return _TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: r.s(14), vertical: r.s(10)),
        decoration: BoxDecoration(
          color: isSelected ? _Palette.green : _Palette.bg,
          borderRadius: BorderRadius.circular(r.s(20)),
          border: Border.all(color: isSelected ? _Palette.green : _Palette.divider, width: isSelected ? 0 : 1),
          boxShadow: isSelected ? [BoxShadow(color: _Palette.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : _Palette.text,
              fontSize: r.fs(13),
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final total = _calculatedTotal;
    final hasResult = total > 0;
    final presets = _getQuickPresets();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: r.s(38), height: r.s(5), decoration: BoxDecoration(color: _Palette.divider, borderRadius: BorderRadius.circular(r.s(3))))),
                SizedBox(height: r.s(20)),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(r.s(10)),
                      decoration: BoxDecoration(color: _Palette.greenSoft, borderRadius: BorderRadius.circular(r.s(12))),
                      child: Icon(Icons.add_shopping_cart_rounded, color: _Palette.green, size: r.s(20)),
                    ),
                    SizedBox(width: r.s(12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('НОВЫЙ ПРОДУКТ', style: GoogleFonts.inter(color: _Palette.green, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        Text('Добавить вручную', style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(18), fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: r.s(20)),
                TextField(
                  controller: _nameCtrl, autofocus: true,
                  style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(15), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Название',
                    labelStyle: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13)),
                    filled: true, fillColor: _Palette.bg,
                    contentPadding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(16)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(r.s(16))), borderSide: BorderSide.none),
                  ),
                ),
                if (_suggestions.isNotEmpty) ...[
                  SizedBox(height: r.s(8)),
                  Container(
                    decoration: BoxDecoration(
                      color: _Palette.surface,
                      borderRadius: BorderRadius.circular(r.s(16)),
                      border: Border.all(color: _Palette.divider),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: _suggestions.map((s) {
                        final fallback = s.fallbackName;
                        return _TapScale(
                          onTap: () => _applySuggestion(s),
                          child: Padding(
                            padding: EdgeInsets.all(r.s(12)),
                            child: Row(
                              children: [
                                Icon(Icons.history_rounded, size: r.s(18), color: _Palette.green),
                                SizedBox(width: r.s(10)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.displayName, style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(14), fontWeight: FontWeight.w600)),
                                      if (fallback != null && fallback.isNotEmpty)
                                        Text('🔄 $fallback', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(11), fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(4)),
                                  decoration: BoxDecoration(color: _Palette.greenSoft, borderRadius: BorderRadius.circular(r.s(8))),
                                  child: Text('${_fmtNum(s.quantity)} ${s.unit} • ${s.estimatedPrice?.round() ?? 0} ₽',
                                      style: GoogleFonts.inter(color: _Palette.green, fontSize: r.fs(11), fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                SizedBox(height: r.s(16)),
                DropdownButtonFormField<String>(
                  value: _selectedCategory, isDense: true,
                  dropdownColor: _Palette.surface,
                  style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(14), fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Отдел магазина',
                    labelStyle: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13)),
                    filled: true, fillColor: _Palette.bg,
                    contentPadding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(14)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(r.s(16))), borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.storefront_rounded, color: _Palette.green, size: r.s(20)),
                  ),
                  items: _availableAisles.map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(14), fontWeight: FontWeight.w500)))).toList(),
                  onChanged: (String? newValue) => setState(() => _selectedCategory = newValue),
                ),
                SizedBox(height: r.s(20)),
                Container(
                  padding: EdgeInsets.all(r.s(16)),
                  decoration: BoxDecoration(
                    color: _Palette.bg,
                    borderRadius: BorderRadius.circular(r.s(20)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('СКОЛЬКО', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                                SizedBox(height: r.s(6)),
                                TextField(
                                  controller: _qtyCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(20), fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    filled: true, fillColor: _Palette.surface,
                                    contentPadding: EdgeInsets.symmetric(horizontal: r.s(14), vertical: r.s(10)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(r.s(12))), borderSide: BorderSide.none),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: r.s(12)),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ЕДИНИЦА', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                                SizedBox(height: r.s(6)),
                                ScaleTransition(
                                  scale: _snapScale,
                                  child: Wrap(
                                    spacing: r.s(6), runSpacing: r.s(6),
                                    children: _qtyUnitsFor(_dimOf(_qtyUnit)).map((unit) {
                                      final isSelected = _qtyUnit == unit;
                                      return _buildChip(unit, isSelected, () => _onQtyUnitChanged(unit));
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (presets.isNotEmpty) ...[
                        SizedBox(height: r.s(12)),
                        Row(
                          children: presets.map((p) {
                            final isCurrent = _qtyCtrl.text == p['v'].toString() && _qtyUnit == p['u'];
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: r.s(6)),
                                child: GestureDetector(
                                  onTap: () => _applyPreset(p),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(vertical: r.s(8)),
                                    decoration: BoxDecoration(
                                      color: isCurrent ? _Palette.greenSoft : _Palette.surface,
                                      borderRadius: BorderRadius.circular(r.s(10)),
                                      border: Border.all(color: isCurrent ? _Palette.green.withOpacity(0.3) : _Palette.divider),
                                    ),
                                    child: Center(
                                      child: Text('${p['v']} ${p['u']}',
                                          style: GoogleFonts.inter(
                                            color: isCurrent ? _Palette.green : _Palette.text,
                                            fontSize: r.fs(12), fontWeight: FontWeight.w600,
                                          )),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      SizedBox(height: r.s(16)),
                      Container(height: 1, color: _Palette.divider),
                      SizedBox(height: r.s(16)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ЦЕНА', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                                SizedBox(height: r.s(6)),
                                TextField(
                                  controller: _priceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(20), fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    suffixText: '₽',
                                    suffixStyle: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(16), fontWeight: FontWeight.w600),
                                    filled: true, fillColor: _Palette.surface,
                                    contentPadding: EdgeInsets.symmetric(horizontal: r.s(14), vertical: r.s(10)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(r.s(12))), borderSide: BorderSide.none),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r.s(12)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('БАЗИС ЦЕНЫ', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                      ),
                      SizedBox(height: r.s(6)),
                      Wrap(
                        spacing: r.s(6), runSpacing: r.s(6),
                        children: _allPriceUnits.map((unit) {
                          final isSelected = _priceUnit == unit;
                          return _buildChip(unit, isSelected, () => _onPriceBasisChanged(unit));
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: r.s(16)),
                Container(
                  padding: EdgeInsets.all(r.s(16)),
                  decoration: BoxDecoration(
                    color: _hasFallback ? _Palette.peachSoft : _Palette.bg,
                    borderRadius: BorderRadius.circular(r.s(16)),
                    border: Border.all(color: _hasFallback ? _Palette.peach.withOpacity(0.3) : _Palette.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.sync_alt_rounded, size: r.s(18), color: _Palette.peach),
                              SizedBox(width: r.s(8)),
                              Text('Есть вариант замены?',
                                  style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(13), fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Switch(
                            value: _hasFallback,
                            onChanged: (val) => setState(() => _hasFallback = val),
                            activeColor: _Palette.peach,
                          ),
                        ],
                      ),
                      if (_hasFallback) ...[
                        SizedBox(height: r.s(12)),
                        TextField(
                          controller: _fallbackCtrl,
                          style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(14)),
                          decoration: InputDecoration(
                            hintText: 'Например: Сметана 15%',
                            hintStyle: GoogleFonts.inter(color: _Palette.textMuted),
                            filled: true, fillColor: _Palette.surface,
                            contentPadding: EdgeInsets.symmetric(horizontal: r.s(14), vertical: r.s(12)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(r.s(12))), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: r.s(20)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(r.s(16)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasResult ? [_Vibrant.neonGreen, _Palette.green] : [_Palette.sage, _Palette.greenSoft],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(r.s(16)),
                    boxShadow: hasResult ? [BoxShadow(color: _Palette.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('ИТОГО', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: r.fs(12), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                          Text('${_fmtNum(total)} ₽',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(28), fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()], letterSpacing: -1)),
                        ],
                      ),
                      SizedBox(height: r.s(6)),
                      Text(_getHumanFormula(),
                          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: r.fs(12), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                SizedBox(height: r.s(24)),
                SizedBox(
                  width: double.infinity, height: r.s(56),
                  child: ElevatedButton(
                    onPressed: _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.text, foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(16))),
                    ),
                    child: Text('ДОБАВИТЬ В СПИСОК',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: r.fs(15), letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Dim { piece, mass, volume }

_Dim _dimOf(String qtyUnit) {
  switch (qtyUnit) {
    case 'шт': return _Dim.piece;
    case 'г': case 'кг': return _Dim.mass;
    case 'мл': case 'л': return _Dim.volume;
    default: return _Dim.piece;
  }
}

List<String> _qtyUnitsFor(_Dim d) {
  switch (d) {
    case _Dim.piece: return const ['шт'];
    case _Dim.mass: return const ['г', 'кг'];
    case _Dim.volume: return const ['мл', 'л'];
  }
}

const List<String> _allPriceUnits = ['за шт', 'за г', 'за 100 г', 'за кг', 'за мл', 'за 100 мл', 'за л'];

_Dim _dimOfPrice(String priceBasis) {
  switch (priceBasis) {
    case 'за шт': return _Dim.piece;
    case 'за г': case 'за 100 г': case 'за кг': return _Dim.mass;
    case 'за мл': case 'за 100 мл': case 'за л': return _Dim.volume;
    default: return _Dim.piece;
  }
}

String _defaultQtyUnitFor(_Dim d) {
  switch (d) { case _Dim.piece: return 'шт'; case _Dim.mass: return 'г'; case _Dim.volume: return 'мл'; }
}

String _defaultPriceBasisFor(_Dim d) {
  switch (d) { case _Dim.piece: return 'за шт'; case _Dim.mass: return 'за кг'; case _Dim.volume: return 'за л'; }
}

double _qtyToBase(double qty, String qtyUnit) {
  switch (qtyUnit) { case 'кг': return qty * 1000; case 'л': return qty * 1000; default: return qty; }
}

double _priceToBase(double price, String priceBasis) {
  switch (priceBasis) {
    case 'за кг': return price / 1000;
    case 'за л': return price / 1000;
    case 'за 100 г': return price / 100;
    case 'за 100 мл': return price / 100;
    default: return price;
  }
}

String _priceSuffixFor(String priceBasis) {
  switch (priceBasis) {
    case 'за шт': return '₽/шт'; case 'за г': return '₽/г'; case 'за 100 г': return '₽/100г';
    case 'за кг': return '₽/кг'; case 'за мл': return '₽/мл'; case 'за 100 мл': return '₽/100мл';
    case 'за л': return '₽/л'; default: return '₽';
  }
}

PriceBasis _basisFromLabel(String label) {
  switch (label) {
    case 'за шт': return PriceBasis.perPiece; case 'за г': return PriceBasis.perGram;
    case 'за 100 г': return PriceBasis.per100g; case 'за кг': return PriceBasis.perKg;
    case 'за мл': return PriceBasis.perMl; case 'за 100 мл': return PriceBasis.per100ml;
    case 'за л': return PriceBasis.perLiter; default: return PriceBasis.perKg;
  }
}

String _labelFromBasis(PriceBasis basis) {
  switch (basis) {
    case PriceBasis.perPiece: return 'за шт'; case PriceBasis.perGram: return 'за г';
    case PriceBasis.per100g: return 'за 100 г'; case PriceBasis.perKg: return 'за кг';
    case PriceBasis.perMl: return 'за мл'; case PriceBasis.per100ml: return 'за 100 мл';
    case PriceBasis.perLiter: return 'за л'; default: return 'за кг';
  }
}