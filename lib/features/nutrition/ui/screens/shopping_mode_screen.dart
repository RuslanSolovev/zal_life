// features/nutrition/ui/screens/shopping_mode_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM (в стиле home_screen — природная палитра)
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
  static const glowingPink = Color(0xFFFF6B8B);
}

class _R {
  final double scale;
  _R(BuildContext context)
      : scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

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
    case 'Овощи': return _Palette.green;
    case 'Фрукты': return _Vibrant.vividPeach;
    case 'Мясо': return _Palette.pink;
    case 'Рыба': return _Palette.sage;
    case 'Молочка': return _Palette.peach;
    case 'Хлеб': return _Palette.peach;
    case 'Бакалея': return _Palette.green;
    case 'Заморозка': return _Palette.sage;
    case 'Напитки': return _Palette.sage;
    case 'Сладости': return _Vibrant.glowingPink;
    case 'Соусы': return _Palette.peach;
    default: return _Palette.textMuted;
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
  bool _showBought = false;

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

    // Группировка по отделам
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

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _hero(allItems, active, bought, totalBudget, progress, provider)),
          SliverToBoxAdapter(child: _entranceAt(0.20, _statsBento(active, bought, totalBudget, sortedAisles, r))),
          if (bought.isNotEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.25, _quickRebuy(allItems, provider, r))),
          if (sortedAisles.isNotEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.30, _sectionHeader('Отделы магазина', Icons.storefront_rounded, _Palette.green, r))),
          ...sortedAisles.asMap().entries.map((e) => SliverToBoxAdapter(
            child: _entranceAt(0.35 + e.key * 0.03, _aisleSection(e.value, byAisle[e.value]!, provider, r)),
          )),
          if (sortedAisles.isEmpty && active.isEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.35, _emptyState(r))),
          if (bought.isNotEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.60, _boughtSummaryCard(bought, r))),
          if (_showBought && bought.isNotEmpty)
            SliverToBoxAdapter(child: _entranceAt(0.65, _boughtSection(bought, provider, r))),
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
  //  HERO (с кольцом прогресса и фото-фоном)
  // ═══════════════════════════════════════════════════════════════
  Widget _hero(List<ShoppingItem> all, List<ShoppingItem> active, List<ShoppingItem> bought,
      double totalBudget, double progress, NutritionProvider provider) {
    final r = _R(context);
    final ringSize = r.s(240);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(r.s(32)),
        bottomRight: Radius.circular(r.s(32)),
      ),
      child: Stack(
        children: [
          // Градиентный фон в тёплых тонах (вместо фото — мягкий градиент)
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2B3A32), Color(0xFF1B2027)],
                ),
              ),
            ),
          ),
          // Декоративное свечение
          Positioned(
            top: r.s(40), right: -r.s(60),
            child: IgnorePointer(
              child: Container(
                width: r.s(260), height: r.s(260),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_Vibrant.vividPeach.withOpacity(0.25), _Vibrant.vividPeach.withOpacity(0)],
                  ),
                ),
              ),
            ),
          ),
          // Плавный переход в основной фон
          Positioned(
            left: 0, right: 0, bottom: 0, height: r.s(70),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_Palette.bg.withOpacity(0.0), _Palette.bg],
                  ),
                ),
              ),
            ),
          ),
          // Контент
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
                      _glassPill(Icons.bar_chart_rounded, () => _showAnalyticsSheet(bought, provider), r),
                    ],
                  ),
                  SizedBox(height: r.s(24)),
                  // Кольцо прогресса
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
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: r.s(22)),
                  // Чипы-легенда
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: r.s(8), runSpacing: r.s(8),
                    children: [
                      _heroLegendChip(_Vibrant.vividPeach, 'Прогресс', '${(progress * 100).round()}%', r),
                      _heroLegendChip(_Palette.sage, 'Куплено', '${bought.length}', r),
                      _heroLegendChip(_Palette.peach, 'Осталось', '${active.length}', r),
                      _heroLegendChip(_Vibrant.neonGreen, 'Бюджет', '${totalBudget.round()}₽', r),
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

  // ═══════════════════════════════════════════════════════════════
  //  STATS BENTO (статистика в bento-grid стиле)
  // ═══════════════════════════════════════════════════════════════
  Widget _statsBento(List<ShoppingItem> active, List<ShoppingItem> bought,
      double totalBudget, List<String> aisles, _R r) {
    final avgPrice = active.isEmpty ? 0.0 : totalBudget / active.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: SizedBox(
        height: r.s(200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Бюджет
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
            // Отделы
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

  // ═══════════════════════════════════════════════════════════════
  //  QUICK REBUY (быстрый повтор)
  // ═══════════════════════════════════════════════════════════════
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
          padding: EdgeInsets.fromLTRB(r.s(20), r.s(16), r.s(20), r.s(10)),
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
  //  AISLE SECTION (отдел магазина)
  // ═══════════════════════════════════════════════════════════════
  Widget _aisleSection(String aisle, List<ShoppingItem> items, NutritionProvider provider, _R r) {
    final aisleTotal = items.fold<double>(0, (s, i) => s + i.totalPrice);
    final accent = _aisleAccent(aisle);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(12)),
      child: Container(
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(r.s(24)),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
          boxShadow: [
            BoxShadow(color: _Palette.green.withOpacity(0.05), blurRadius: 18, spreadRadius: -4, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок отдела
            _TapScale(
              onTap: () => _showAisleFocusMode(aisle, items, provider),
              child: Padding(
                padding: EdgeInsets.all(r.s(16)),
                child: Row(
                  children: [
                    Container(
                      width: r.s(44), height: r.s(44),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(r.s(13)),
                      ),
                      alignment: Alignment.center,
                      child: Text(_aisleEmoji(aisle), style: TextStyle(fontSize: r.s(22))),
                    ),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aisle, style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(15), fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                          SizedBox(height: r.s(2)),
                          Text('${items.length} ${_itemsWord(items.length)}',
                              style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(11))),
                        ],
                      ),
                    ),
                    if (aisleTotal > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(6)),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(r.s(10)),
                        ),
                        child: Text('${aisleTotal.round()} ₽',
                            style: GoogleFonts.inter(color: accent, fontSize: r.fs(12), fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                    SizedBox(width: r.s(8)),
                    Icon(Icons.chevron_right_rounded, color: _Palette.textMuted, size: r.s(18)),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: _Palette.divider),
            // Товары
            ...items.map((item) => _shoppingTile(item, provider, r)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHOPPING TILE (с Swipe-to-Delete)
  // ═══════════════════════════════════════════════════════════════
  Widget _shoppingTile(ShoppingItem item, NutritionProvider provider, _R r) {
    final product = provider.products.where((p) => p.id == item.productId).firstOrNull;
    final isUrgent = item.isUrgent;
    final fallbackName = item.fallbackName;
    final accent = product?.category == 'other' ? _Palette.green : _aisleAccent(_categoryToAisle(product?.category ?? ''));

    return Dismissible(
      key: Key('shopping_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: r.s(20)),
        margin: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(6)),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_Palette.pink.withOpacity(0.15), _Palette.pinkSoft]),
          borderRadius: BorderRadius.circular(r.s(16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.delete_rounded, color: _Palette.pink, size: r.s(22)),
            SizedBox(height: r.s(4)),
            Text('Удалить', style: GoogleFonts.inter(color: _Palette.pink, fontSize: r.fs(10), fontWeight: FontWeight.w600)),
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(6)),
          child: Container(
            padding: EdgeInsets.all(r.s(12)),
            decoration: BoxDecoration(
              color: isUrgent ? _Palette.pinkSoft.withOpacity(0.4) : Colors.transparent,
              borderRadius: BorderRadius.circular(r.s(14)),
              border: isUrgent ? Border.all(color: _Palette.pink.withOpacity(0.25)) : null,
            ),
            child: Row(
              children: [
                // Чекбокс
                GestureDetector(
                  onTap: () => provider.toggleShoppingItem(item.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: r.s(28), height: r.s(28),
                    decoration: BoxDecoration(
                      color: item.isBought ? _Palette.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(r.s(8)),
                      border: item.isBought ? null : Border.all(color: _Palette.divider, width: 1.5),
                    ),
                    child: item.isBought ? Icon(Icons.check_rounded, size: r.s(16), color: Colors.white) : const SizedBox(),
                  ),
                ),
                SizedBox(width: r.s(12)),
                // Иконка продукта
                Container(
                  width: r.s(40), height: r.s(40),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(r.s(11)),
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
                                  color: item.isBought ? _Palette.textMuted : _Palette.text,
                                  fontSize: r.fs(14), fontWeight: FontWeight.w600,
                                  decoration: item.isBought ? TextDecoration.lineThrough : null,
                                  decorationColor: _Palette.green,
                                  decorationThickness: 2,
                                )),
                          ),
                          if (isUrgent && !item.isBought)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: r.s(6), vertical: r.s(2)),
                              decoration: BoxDecoration(
                                color: _Palette.pink.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(r.s(5)),
                              ),
                              child: Text('СРОЧНО', style: GoogleFonts.inter(color: _Palette.pink, fontSize: r.fs(8), fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                            ),
                        ],
                      ),
                      SizedBox(height: r.s(4)),
                      Row(
                        children: [
                          Text('${_fmtNum(item.quantity)} ${item.unit}',
                              style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(11), fontWeight: FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()])),
                          if (item.estimatedPrice != null && item.estimatedPrice! > 0) ...[
                            const Spacer(),
                            Text('${item.totalPrice.round()} ₽',
                                style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(13), fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
                          ],
                        ],
                      ),
                      if (fallbackName != null && fallbackName.isNotEmpty && !item.isBought) ...[
                        SizedBox(height: r.s(6)),
                        Row(
                          children: [
                            Icon(Icons.sync_alt_rounded, size: r.s(11), color: _Palette.sage),
                            SizedBox(width: r.s(4)),
                            Expanded(
                              child: Text('Замена: $fallbackName',
                                  style: GoogleFonts.inter(color: _Palette.sage, fontSize: r.fs(10), fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: r.s(8)),
                Icon(Icons.swipe_left_rounded, size: r.s(14), color: _Palette.pink.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOUGHT SUMMARY
  // ═══════════════════════════════════════════════════════════════
  Widget _boughtSummaryCard(List<ShoppingItem> bought, _R r) {
    final total = bought.fold<double>(0, (s, i) => s + i.totalPrice);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), r.s(12)),
      child: _TapScale(
        onTap: () => setState(() => _showBought = !_showBought),
        child: Container(
          padding: EdgeInsets.all(r.s(16)),
          decoration: BoxDecoration(
            color: _Palette.surface,
            borderRadius: BorderRadius.circular(r.s(20)),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
            boxShadow: [
              BoxShadow(color: _Palette.green.withOpacity(0.05), blurRadius: 12, spreadRadius: -4, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(r.s(8)),
                decoration: BoxDecoration(color: _Palette.greenSoft, borderRadius: BorderRadius.circular(r.s(10))),
                child: Icon(Icons.receipt_long_rounded, color: _Palette.green, size: r.s(20)),
              ),
              SizedBox(width: r.s(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('КУПЛЕНО', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                    SizedBox(height: r.s(2)),
                    Text('${bought.length} товаров на ${total.round()} ₽',
                        style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(15), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _showBought ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down, size: r.s(20), color: _Palette.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boughtSection(List<ShoppingItem> items, NutritionProvider provider, _R r) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(12)),
      child: Container(
        decoration: BoxDecoration(
          color: _Palette.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(r.s(20)),
          border: Border.all(color: Colors.white.withOpacity(0.9)),
        ),
        child: Column(
          children: items.map((item) {
            final product = provider.products.firstWhere((p) => p.id == item.productId,
                orElse: () => FoodProduct(id: '', name: '', category: 'other', calories: 0, protein: 0, fat: 0, carbs: 0));
            final accent = _aisleAccent(_categoryToAisle(product.category));
            return _TapScale(
              onTap: () => provider.toggleShoppingItem(item.id),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: r.s(14), vertical: r.s(10)),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: r.s(18), color: _Palette.green),
                    SizedBox(width: r.s(12)),
                    Container(
                      width: r.s(28), height: r.s(28),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(r.s(8)),
                      ),
                      alignment: Alignment.center,
                      child: Text(product.categoryEmoji.isEmpty ? '📦' : product.categoryEmoji, style: TextStyle(fontSize: r.s(14))),
                    ),
                    SizedBox(width: r.s(10)),
                    Expanded(
                      child: Text(item.displayName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13), fontWeight: FontWeight.w500, decoration: TextDecoration.lineThrough)),
                    ),
                    Text('${_fmtNum(item.quantity)} ${item.unit}',
                        style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(11), fontWeight: FontWeight.w500)),
                    SizedBox(width: r.s(8)),
                    // Кнопка удаления
                    _TapScale(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: _Palette.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(20))),
                            title: Text('Удалить «${item.displayName}»?',
                                style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(16), fontWeight: FontWeight.w600)),
                            content: Text('Удалить из истории покупок?',
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
                            content: Text('🗑️ Удалено'),
                            backgroundColor: _Palette.pink,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
                          ));
                        }
                      },
                      child: Container(
                        width: r.s(28), height: r.s(28),
                        decoration: BoxDecoration(
                          color: _Palette.pinkSoft,
                          borderRadius: BorderRadius.circular(r.s(8)),
                        ),
                        child: Icon(Icons.close_rounded, size: r.s(14), color: _Palette.pink),
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
  //  EMPTY STATE
  // ═══════════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════════
  //  FAB
  // ═══════════════════════════════════════════════════════════════
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
  //  AISLE FOCUS MODE
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
                      width: r.s(48), height: r.s(48),
                      decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(r.s(14))),
                      alignment: Alignment.center,
                      child: Text(_aisleEmoji(aisle), style: TextStyle(fontSize: r.s(24))),
                    ),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aisle, style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(18), fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                          Text('${items.length} ${_itemsWord(items.length)}',
                              style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(12))),
                        ],
                      ),
                    ),
                    _TapScale(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: EdgeInsets.all(r.s(8)),
                        decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(10))),
                        child: Icon(Icons.close_rounded, color: _Palette.text, size: r.s(18)),
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
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(bottom: r.s(8)),
                    child: GestureDetector(
                      onLongPress: () => _showPriceHistory(context, items[index], provider),
                      child: _shoppingTile(items[index], provider, r),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(r.s(16)),
                child: SizedBox(
                  width: double.infinity, height: r.s(52),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.green, foregroundColor: Colors.white,
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
  //  ADD ITEM SHEET
  // ═══════════════════════════════════════════════════════════════
  Future<void> _showAddItemSheet(NutritionProvider provider) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AddItemBottomSheet(provider: provider),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHARE
  // ═══════════════════════════════════════════════════════════════
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
      if (item.category != null && item.category!.isNotEmpty) aisle = item.category!;
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

  // ═══════════════════════════════════════════════════════════════
  //  ANALYTICS
  // ═══════════════════════════════════════════════════════════════
  void _showAnalyticsSheet(List<ShoppingItem> boughtItems, NutritionProvider provider) {
    final r = _R(context);
    final Map<String, List<ShoppingItem>> historyByDay = {};
    double totalSpent = 0;
    for (final item in boughtItems) {
      totalSpent += item.totalPrice;
      final dateKey = _formatDate(item.createdAt);
      if (!historyByDay.containsKey(dateKey)) historyByDay[dateKey] = [];
      historyByDay[dateKey]!.add(item);
    }
    final sortedDays = historyByDay.keys.toList()..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
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
                                          Text('+${item.totalPrice.round()} ₽',
                                              style: GoogleFonts.inter(color: _Palette.green, fontSize: r.fs(13), fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRICE HISTORY
  // ═══════════════════════════════════════════════════════════════
  void _showPriceHistory(BuildContext context, ShoppingItem currentItem, NutritionProvider provider) {
    final r = _R(context);
    final history = provider.getPriceHistory(currentItem.displayName, currentItem.id);
    final avgBasePrice = provider.getAverageHistoricalBasePrice(history);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45, minChildSize: 0.2, maxChildSize: 0.75,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: _Palette.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(24))),
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
                      decoration: BoxDecoration(color: _Palette.yellow, borderRadius: BorderRadius.circular(r.s(12))),
                      child: Icon(Icons.show_chart_rounded, color: _Palette.peach, size: r.s(20)),
                    ),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ИСТОРИЯ ЦЕН', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                          Text(currentItem.displayName,
                              style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(16), fontWeight: FontWeight.w700, letterSpacing: -0.3),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: history.isEmpty
                    ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(r.s(20)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: r.s(40), color: _Palette.divider),
                        SizedBox(height: r.s(12)),
                        Text('Это первая покупка',
                            style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(14), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(8)),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final isLast = index == history.length - 1;
                    String suffix = '₽';
                    switch (item.priceBasis) {
                      case PriceBasis.perPiece: suffix = '₽/шт'; break;
                      case PriceBasis.perGram: suffix = '₽/г'; break;
                      case PriceBasis.per100g: suffix = '₽/100г'; break;
                      case PriceBasis.perKg: suffix = '₽/кг'; break;
                      case PriceBasis.perMl: suffix = '₽/мл'; break;
                      case PriceBasis.per100ml: suffix = '₽/100мл'; break;
                      case PriceBasis.perLiter: suffix = '₽/л'; break;
                      case PriceBasis.perPackage: suffix = '₽/уп'; break;
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: r.s(8)),
                          child: Row(
                            children: [
                              Text(_formatDate(item.createdAt),
                                  style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(12), fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Text('${_fmtNum(item.quantity)} ${item.unit}',
                                  style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(13), fontWeight: FontWeight.w600)),
                              SizedBox(width: r.s(12)),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(6)),
                                decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(8))),
                                child: Text('${_fmtNum(item.estimatedPrice ?? 0)} $suffix',
                                    style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(13), fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast) Container(height: 1, color: _Palette.divider),
                      ],
                    );
                  },
                ),
              ),
              if (history.isNotEmpty && avgBasePrice != null)
                Container(
                  padding: EdgeInsets.all(r.s(16)),
                  decoration: BoxDecoration(
                    color: _Palette.greenSoft,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(20))),
                    border: Border(top: BorderSide(color: _Palette.green.withOpacity(0.2))),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.analytics_rounded, color: _Palette.green, size: r.s(20)),
                      SizedBox(width: r.s(10)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('СРЕДНЯЯ ЦЕНА', style: GoogleFonts.inter(color: _Palette.green, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            Text('${_fmtNum(avgBasePrice)} ₽ / ед. (на основе ${history.length} пок.)',
                                style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(14), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
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
}

// ═══════════════════════════════════════════════════════════════════
//  PROGRESS RING PAINTER (в стиле home_screen)
// ═══════════════════════════════════════════════════════════════════
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final int boughtCount;
  final int totalCount;
  final double totalBudget;
  final double scale;

  _ProgressRingPainter({
    required this.progress,
    required this.boughtCount,
    required this.totalCount,
    required this.totalBudget,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20 * scale;
    final stroke = 14.0 * scale;

    // Фоновое кольцо
    canvas.drawCircle(
      center, radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.75
        ..color = Colors.white.withOpacity(0.15),
    );

    // Кольцо прогресса с glow
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      const start = -math.pi / 2;
      final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

      // Glow
      canvas.drawArc(
        rect, start, sweep, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.6
          ..strokeCap = StrokeCap.round
          ..color = _Vibrant.neonGreen.withOpacity(0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      // Основной градиент через сегменты
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

      // Точка на конце
      final endAngle = start + sweep;
      final dotPos = Offset(
        center.dx + math.cos(endAngle) * radius,
        center.dy + math.sin(endAngle) * radius,
      );
      canvas.drawCircle(dotPos, stroke * 1.0,
          Paint()..color = _Vibrant.neonGreen.withOpacity(0.55)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      canvas.drawCircle(dotPos, stroke * 0.65, Paint()..color = _Vibrant.neonGreen);
      canvas.drawCircle(dotPos, stroke * 0.28, Paint()..color = Colors.white);
    }

    // Центральный текст
    _drawCenterText(canvas, center, '${(progress * 100).round()}%', 36 * scale, Colors.white, FontWeight.w600, -20 * scale);
    _drawCenterText(canvas, center, 'куплено', 12 * scale, Colors.white.withOpacity(0.7), FontWeight.w500, 8 * scale);
    _drawCenterText(canvas, center, '$boughtCount / $totalCount', 14 * scale, _Vibrant.neonGreen, FontWeight.w700, 28 * scale);
  }

  void _drawCenterText(Canvas canvas, Offset center, String text, double fontSize, Color color, FontWeight weight, double offsetY) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: -0.5,
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

// ═══════════════════════════════════════════════════════════════════
//  TAP SCALE (в стиле home_screen)
// ═══════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════
//  GLOSSY PROGRESS (в стиле home_screen)
// ═══════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════
//  ADD ITEM BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════
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
    if (qty <= 0 || price <= 0) return 'Введите количество и цену';
    return '${_fmtNum(qty)} $_qtyUnit × ${_fmtNum(price)} ${_priceSuffixFor(_priceUnit)} = ${_fmtNum(_calculatedTotal)} ₽';
  }

  List<Map<String, dynamic>> _getQuickPresets() {
    final dim = _dimOf(_qtyUnit);
    if (dim == _Dim.mass) return [{'v': 100, 'u': 'г'}, {'v': 500, 'u': 'г'}, {'v': 1, 'u': 'кг'}];
    if (dim == _Dim.volume) return [{'v': 250, 'u': 'мл'}, {'v': 500, 'u': 'мл'}, {'v': 1, 'u': 'л'}];
    return [{'v': 1, 'u': 'шт'}, {'v': 2, 'u': 'шт'}, {'v': 3, 'u': 'шт'}];
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
    final r = _R(context);
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
            style: GoogleFonts.inter(color: isSelected ? Colors.white : _Palette.text, fontSize: r.fs(13), fontWeight: FontWeight.w600)),
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
                    labelText: 'Название', filled: true, fillColor: _Palette.bg,
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
                  style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(14), fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Отдел магазина', filled: true, fillColor: _Palette.bg,
                    contentPadding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(14)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(r.s(16))), borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.storefront_rounded, color: _Palette.green, size: r.s(20)),
                  ),
                  items: _availableAisles.map((String value) => DropdownMenuItem<String>(
                      value: value, child: Text(value, style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w500)))).toList(),
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
                                    hintText: '0', filled: true, fillColor: _Palette.surface,
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
                                      return _buildChip(unit, isSelected, () => setState(() => _qtyUnit = unit));
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
                                  onTap: () => setState(() {
                                    _qtyCtrl.text = p['v'].toString();
                                    _qtyUnit = p['u'];
                                    _triggerSnap();
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(vertical: r.s(8)),
                                    decoration: BoxDecoration(
                                      color: isCurrent ? _Palette.greenSoft : Colors.transparent,
                                      borderRadius: BorderRadius.circular(r.s(10)),
                                      border: Border.all(color: isCurrent ? _Palette.green.withOpacity(0.3) : _Palette.divider),
                                    ),
                                    child: Center(
                                      child: Text('${p['v']} ${p['u']}',
                                          style: GoogleFonts.inter(
                                            color: isCurrent ? _Palette.green : _Palette.textMuted,
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
                          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: r.fs(12), fontWeight: FontWeight.w500)),
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

// ═══════════════════════════════════════════════════════════════════
//  UTILITIES (единицы измерения)
// ═══════════════════════════════════════════════════════════════════
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