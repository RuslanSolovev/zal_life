// features/nutrition/ui/screens/kitchen_hub_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zal_life/features/nutrition/ui/screens/plan_week_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/recipe_editor_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/shopping_mode_screen.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import '../widgets/seasonal_strip.dart';
import '../../providers/wellness_provider.dart';
import 'add_pantry_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  Design tokens (единый стиль с FuelDashboard)
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
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF9381BB);
  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF6C9E88);
  static const skySoft = Color(0xFFE8EFF8);
  static const skyDeep = Color(0xFF7E9DC6);
  static const yellowSoft = Color(0xFFFDF5E6);
  static const yellowDeep = Color(0xFFE0B054);
  static const pinkSoft = Color(0xFFFCF0F2);
  static const pinkDeep = Color(0xFFD17A8F);
  static const brownSoft = Color(0xFFF3E9DC);
  static const brownDeep = Color(0xFFA87B4F);
}

class _Hero {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const accent = Color(0xFFA87B4F);
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

const double _padH = 14;

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class KitchenHubScreen extends StatefulWidget {
  const KitchenHubScreen({super.key});

  @override
  State<KitchenHubScreen> createState() => _KitchenHubScreenState();
}

class _KitchenHubScreenState extends State<KitchenHubScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<double> _entranceCurve =
  CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
  late final AnimationController _bars = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    _bars.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void dispose() {
    _entrance.dispose();
    _bars.dispose();
    super.dispose();
  }

  Widget _sectionLabel(String text, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_padH, 26, _padH, 10),
        child: Row(
          children: [
            Icon(icon, size: 13, color: _P.textMuted),
            const SizedBox(width: 6),
            Text(text.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _P.text,
                  letterSpacing: 1.0,
                )),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 1, color: _P.divider)),
          ],
        ),
      ),
    );
  }

  Widget _animBars(Widget Function(double t) builder) {
    if (_reduceMotion) return builder(1.0);
    return AnimatedBuilder(animation: _bars, builder: (_, __) => builder(_bars.value));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final pantry = provider.pantryItems;
    final shopping = provider.activeShoppingList;
    final planDays = provider.planDays;
    final expiring = provider.expiringSoonItems;

    final totalBudget = shopping.fold<double>(0, (s, i) => s + i.totalPrice);
    final boughtCount = provider.shoppingItems.where((i) => i.isBought).length;

    return Scaffold(
      backgroundColor: _P.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildHero(provider, pantry, shopping, totalBudget)),

          if (expiring.isNotEmpty) ...[
            _sectionLabel('СРОЧНО', Icons.warning_amber_rounded),
            SliverToBoxAdapter(child: _buildExpiringSection(expiring, provider)),
          ],

          _sectionLabel('ЗОНЫ КУХНИ', Icons.grid_view_rounded),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _padH),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _zoneCard(
                      icon: Icons.kitchen_rounded,
                      emoji: '🧺',
                      title: 'Кладовая',
                      subtitle: '${pantry.length} продуктов',
                      color: _P.brownDeep,
                      softColor: _P.brownSoft,
                      onTap: () => _showPantrySheet(provider),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _zoneCard(
                      icon: Icons.restaurant_menu_rounded,
                      emoji: '📖',
                      title: 'Рецепты',
                      subtitle: '${provider.templates.length} блюд',
                      color: _P.peachDeep,
                      softColor: _P.peachSoft,
                      onTap: () => _showRecipesSheet(provider),
                    )),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _zoneCard(
                      icon: Icons.calendar_month_rounded,
                      emoji: '📅',
                      title: 'План',
                      subtitle: '${planDays.length} дней',
                      color: _P.greenDeep,
                      softColor: _P.greenSoft,
                      onTap: () => _showPlanSheet(provider),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _zoneCard(
                      icon: Icons.shopping_basket_rounded,
                      emoji: '🛒',
                      title: 'Покупки',
                      subtitle: '$boughtCount / ${provider.shoppingItems.length}',
                      color: _P.skyDeep,
                      softColor: _P.skySoft,
                      badge: shopping.isNotEmpty ? '${shopping.length}' : null,
                      onTap: () => _showShoppingSheet(provider),
                    )),
                  ]),
                  const SizedBox(height: 8),
                  _zoneCard(
                    icon: Icons.account_balance_wallet_rounded,
                    emoji: '💰',
                    title: 'Бюджет недели',
                    subtitle: totalBudget > 0
                        ? '${totalBudget.toStringAsFixed(0)} ₽ нужно'
                        : 'Пока пусто',
                    color: _P.yellowDeep,
                    softColor: _P.yellowSoft,
                    wide: true,
                    onTap: () => _showBudgetSheet(provider),
                  ),
                ],
              ),
            ),
          ),

          if (shopping.isNotEmpty) ...[
            _sectionLabel('СПИСОК ПОКУПОК', Icons.shopping_cart_rounded),
            SliverToBoxAdapter(child: _buildShoppingPreview(shopping, provider)),
          ],

          _sectionLabel('БЫСТРЫЕ ДЕЙСТВИЯ', Icons.auto_awesome_rounded),
          SliverToBoxAdapter(child: _buildQuickActions(provider)),

          _sectionLabel('СЕЗОН СЕЙЧАС', Icons.eco_rounded),
          SliverToBoxAdapter(child: _buildSeasonalSection()),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HERO
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHero(NutritionProvider provider, List<PantryItem> pantry,
      List<ShoppingItem> shopping, double budget) {
    final content = ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_Hero.bgTop, _Hero.bgBottom],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _Hero.accent.withOpacity(0.25),
                      _Hero.accent.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0, height: 60,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_P.bg.withOpacity(0), _P.bg],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🏠', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('КУХНЯ',
                              style: GoogleFonts.inter(
                                  color: _Hero.textLow,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                  shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)])),
                          const SizedBox(height: 2),
                          Text('Твоя кулинарная база',
                              style: GoogleFonts.inter(
                                  color: _Hero.textHigh,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                  shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 6)])),
                        ],
                      ),
                    ),
                    _iconPill(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _heroMetric(
                      value: '${pantry.length}',
                      label: 'в кладовой',
                      emoji: '🧺',
                      color: _P.brownDeep,
                    ),
                    const SizedBox(width: 10),
                    _heroMetric(
                      value: '${provider.templates.length}',
                      label: 'рецептов',
                      emoji: '📖',
                      color: _P.peachDeep,
                    ),
                    const SizedBox(width: 10),
                    _heroMetric(
                      value: budget > 0 ? '${budget.round()}₽' : '—',
                      label: 'бюджет',
                      emoji: '💰',
                      color: _P.yellowDeep,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (provider.shoppingItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🛒', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text('Покупки',
                                style: GoogleFonts.inter(
                                    color: _Hero.textHigh,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              '${provider.shoppingItems.where((i) => i.isBought).length} / ${provider.shoppingItems.length}',
                              style: GoogleFonts.inter(
                                  color: _Hero.textLow,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [ui.FontFeature.tabularFigures()]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _animBars((t) {
                          final pct = provider.shoppingItems.isEmpty
                              ? 0.0
                              : (provider.shoppingItems.where((i) => i.isBought).length / provider.shoppingItems.length).clamp(0.0, 1.0);
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: pct * t,
                              minHeight: 3,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation(_Hero.accent),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (_reduceMotion) return content;
    return AnimatedBuilder(
      animation: _entranceCurve,
      builder: (_, child) => Opacity(
        opacity: _entranceCurve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _entranceCurve.value) * 12),
          child: child,
        ),
      ),
      child: content,
    );
  }

  Widget _heroMetric({
    required String value,
    required String label,
    required String emoji,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(
                    color: _Hero.textHigh,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                    shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 6)])),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    color: _Hero.textLow,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

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

  // ═══════════════════════════════════════════════════════════════
  //  EXPIRING SECTION
  // ═══════════════════════════════════════════════════════════════
  Widget _buildExpiringSection(List<PantryItem> items, NutritionProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Column(
        children: items.take(3).map((item) {
          final urgent = item.daysUntilExpiry <= 1;
          final expired = item.daysUntilExpiry <= 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: expired ? _P.pinkSoft : (urgent ? _P.yellowSoft : _P.greenSoft),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (expired ? _P.pinkDeep : (urgent ? _P.yellowDeep : _P.greenDeep)).withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      expired ? Icons.error_outline_rounded
                          : (urgent ? Icons.schedule_rounded : Icons.inventory_2_outlined),
                      color: expired ? _P.pinkDeep : (urgent ? _P.yellowDeep : _P.greenDeep),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                color: _P.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          _expiryText(item),
                          style: GoogleFonts.inter(
                              color: expired ? _P.pinkDeep : (urgent ? _P.yellowDeep : _P.greenDeep),
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  _Press(
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
                        content: Text('✅ ${item.displayName} добавлено в покупки'),
                        backgroundColor: _P.greenDeep,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ));
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: (expired ? _P.pinkDeep : (urgent ? _P.yellowDeep : _P.greenDeep)).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.add_shopping_cart_rounded,
                          size: 15,
                          color: expired ? _P.pinkDeep : (urgent ? _P.yellowDeep : _P.greenDeep)),
                    ),
                  ),
                  _Press(
                    onTap: () => provider.removeFromPantry(item.id),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 15, color: _P.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _expiryText(PantryItem item) {
    final qty = '${item.quantity.toStringAsFixed(0)} ${item.unit}';

    if (item.daysUntilExpiry <= 0) {
      return '⚠️ Срок истёк • $qty';
    }
    if (item.daysUntilExpiry == 1) {
      return '🔥 Завтра испортится • $qty';
    }
    if (item.daysUntilExpiry <= 3) {
      return '⏳ Ещё ${item.daysUntilExpiry} дн. • $qty';
    }
    return '✓ ${item.daysUntilExpiry} дн. до срока • $qty';
  }

  // ═══════════════════════════════════════════════════════════════
  //  ZONE CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _zoneCard({
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required Color softColor,
    required VoidCallback onTap,
    String? badge,
    bool wide = false,
  }) {
    return _Press(
      onTap: onTap,
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badge,
                        style: GoogleFonts.inter(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [ui.FontFeature.tabularFigures()])),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: GoogleFonts.inter(
                    color: _P.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHOPPING PREVIEW (с группировкой и swipe-to-delete)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildShoppingPreview(List<ShoppingItem> items, NutritionProvider provider) {
    // Умная группировка по категориям
    final byCategory = <String, List<ShoppingItem>>{};
    for (final item in items) {
      final cat = item.category ?? 'Другое';
      byCategory.putIfAbsent(cat, () => []).add(item);
    }

    final preview = items.take(5).toList();
    final remaining = items.length - preview.length;

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
            // Статистика по категориям
            if (byCategory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    _categoryChip(
                      emoji: _getCategoryEmoji(byCategory.keys.first),
                      label: byCategory.keys.first,
                      count: byCategory.values.first.length,
                      color: _P.skyDeep,
                    ),
                    if (byCategory.length > 1) ...[
                      const SizedBox(width: 6),
                      _categoryChip(
                        emoji: _getCategoryEmoji(byCategory.keys.elementAt(1)),
                        label: byCategory.keys.elementAt(1),
                        count: byCategory.values.elementAt(1).length,
                        color: _P.peachDeep,
                      ),
                    ],
                    if (byCategory.length > 2) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _P.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('+${byCategory.length - 2}',
                            style: GoogleFonts.inter(
                                color: _P.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
            // Список товаров со swipe-to-delete
            ...preview.map((item) => _shoppingRow(item, provider)),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _Press(
                  onTap: () => _showShoppingSheet(provider),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ещё $remaining ${_itemsWord(remaining)}',
                          style: GoogleFonts.inter(
                              color: _P.skyDeep,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 14, color: _P.skyDeep),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip({
    required String emoji,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$count',
                style: GoogleFonts.inter(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'молочка':
      case 'dairy':
        return '🥛';
      case 'мясо':
      case 'meat':
        return '🥩';
      case 'овощи':
      case 'vegetables':
        return '🥬';
      case 'фрукты':
      case 'fruits':
        return '🍎';
      case 'крупы':
      case 'grains':
        return '🌾';
      case 'хлеб':
      case 'bakery':
        return '🍞';
      default:
        return '📦';
    }
  }

  Widget _shoppingRow(ShoppingItem item, NutritionProvider provider) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _P.pinkSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: _P.pinkDeep, size: 20),
            const SizedBox(height: 2),
            Text('Удалить',
                style: GoogleFonts.inter(
                    color: _P.pinkDeep,
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (direction) async {
        await provider.deleteShoppingItem(item.id);
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🗑️ ${item.displayName} удалён из списка'),
          backgroundColor: _P.pinkDeep,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Checkbox(
                value: item.isBought,
                onChanged: (_) => provider.toggleShoppingItem(item.id),
                activeColor: _P.skyDeep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    color: item.isBought ? _P.textMuted : _P.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: item.isBought ? TextDecoration.lineThrough : null),
              ),
            ),
            Text('${item.quantity.toStringAsFixed(0)} ${item.unit}',
                style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [ui.FontFeature.tabularFigures()])),
            const SizedBox(width: 8),
            Icon(Icons.swipe_left_rounded, size: 14, color: _P.pinkDeep.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  String _itemsWord(int n) {
    if (n == 1) return 'позиция';
    if (n >= 2 && n <= 4) return 'позиции';
    return 'позиций';
  }

  // ═══════════════════════════════════════════════════════════════
  //  QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuickActions(NutritionProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Column(
        children: [
          _quickActionTile(
            icon: Icons.auto_awesome_rounded,
            emoji: '🎲',
            title: 'Случайный рецепт',
            subtitle: 'Не знаешь, что приготовить?',
            color: _P.lavenderDeep,
            softColor: _P.lavenderSoft,
            onTap: () => _pickRandomRecipe(provider),
          ),
          const SizedBox(height: 8),
          _quickActionTile(
            icon: Icons.shopping_cart_rounded,
            emoji: '🧾',
            title: 'Собрать покупки из плана',
            subtitle: 'Автоматически по рецептам недели',
            color: _P.skyDeep,
            softColor: _P.skySoft,
            onTap: () => _generateShoppingList(provider),
          ),
          const SizedBox(height: 8),
          _quickActionTile(
            icon: Icons.add_shopping_cart_rounded,
            emoji: '➕',
            title: 'Добавить в кладовую',
            subtitle: 'Что есть дома прямо сейчас',
            color: _P.brownDeep,
            softColor: _P.brownSoft,
            onTap: () => _showAddToPantrySheet(provider),
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
  }) {
    return _Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SEASONAL
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSeasonalSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: SeasonalStrip(onViewAll: () {}),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════════
  void _pickRandomRecipe(NutritionProvider provider) {
    if (provider.templates.isEmpty) {
      _showInfo('Нет рецептов', 'Сначала добавь хотя бы один рецепт в книгу.');
      return;
    }
    final random = provider.templates[(math.Random().nextInt(provider.templates.length))];
    _showTemplateDetails(provider, random);
  }

  Future<void> _generateShoppingList(NutritionProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Собрать покупки?', style: _T.headline),
        content: Text(
          'Просуммируем ингредиенты из плана на неделю и создадим список. То, что есть в кладовой, будет вычтено.',
          style: _T.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Собрать',
                style: GoogleFonts.inter(color: _P.peachDeep, fontWeight: FontWeight.w600)),
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
      backgroundColor: _P.greenDeep,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  void _showInfo(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: _T.headline),
        content: Text(message, style: _T.body),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const PlanWeekScreen(),
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

// ═══════════════════════════════════════════════════════════════════
//  ОБЩИЕ ПРИВАТНЫЕ ВИДЖЕТЫ
// ═══════════════════════════════════════════════════════════════════
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const _Press({required this.child, this.onTap, this.onLongPress});

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
    final interactive = widget.onTap != null || widget.onLongPress != null;
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
      onLongPress: widget.onLongPress == null
          ? null
          : () {
        HapticFeedback.mediumImpact();
        widget.onLongPress!();
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

Widget _grabber() => Container(
  width: 36,
  height: 5,
  decoration: BoxDecoration(
    color: _P.divider,
    borderRadius: BorderRadius.circular(3),
  ),
);

// ═══════════════════════════════════════════════════════════════════
//  SHEET: КЛАДОВАЯ
// ═══════════════════════════════════════════════════════════════════
class _PantrySheet extends StatelessWidget {
  final NutritionProvider provider;
  final VoidCallback onAddProduct;

  const _PantrySheet({
    required this.provider,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    final items = provider.pantryItems;
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            _grabber(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Кладовая', style: _T.title2),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _P.brownSoft, borderRadius: BorderRadius.circular(8)),
                    child: Text('${items.length}',
                        style: GoogleFonts.inter(
                            color: _P.brownDeep,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [ui.FontFeature.tabularFigures()])),
                  ),
                  const Spacer(),
                  _Press(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: _P.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🧺', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text('Кладовая пуста', style: _T.body),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: onAddProduct,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Добавить продукт'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _P.brownDeep,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final urgent = item.daysUntilExpiry <= 3;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: urgent ? _P.pinkSoft : _P.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: urgent ? _P.pinkDeep.withOpacity(0.25) : _P.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: const Text('📦', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.displayName,
                                  style: GoogleFonts.inter(
                                      color: _P.text,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${item.quantity.toStringAsFixed(0)} ${item.unit}' +
                                    (item.expiresAt != null
                                        ? ' • до ${item.expiresAt!.day}.${item.expiresAt!.month}'
                                        : ''),
                                style: GoogleFonts.inter(
                                    color: urgent ? _P.pinkDeep : _P.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        _Press(
                          onTap: () => provider.removeFromPantry(item.id),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 15, color: _P.pinkDeep),
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

// ═══════════════════════════════════════════════════════════════════
//  SHEET: РЕЦЕПТЫ
// ═══════════════════════════════════════════════════════════════════
class _RecipesSheet extends StatelessWidget {
  final NutritionProvider provider;
  const _RecipesSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final templates = provider.templates;
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
            _grabber(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Книга рецептов', style: _T.title2),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _P.peachSoft, borderRadius: BorderRadius.circular(8)),
                    child: Text('${templates.length}',
                        style: GoogleFonts.inter(
                            color: _P.peachDeep,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [ui.FontFeature.tabularFigures()])),
                  ),
                  const Spacer(),
                  _Press(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: _P.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: templates.isEmpty
                  ? Center(child: Text('Пока нет рецептов', style: _T.body))
                  : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.82,
                ),
                itemCount: templates.length,
                itemBuilder: (_, i) {
                  final t = templates[i];
                  return _Press(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _P.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _P.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _P.peachSoft,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: const Text('🍱', style: TextStyle(fontSize: 14)),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(t.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    color: _P.text,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2)),
                          ),
                          Text('${t.calories.round()} ккал',
                              style: GoogleFonts.inter(
                                  color: _P.peachDeep,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [ui.FontFeature.tabularFigures()])),
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
//  SHEET: ПЛАН
// ═══════════════════════════════════════════════════════════════════
class _PlanSheet extends StatelessWidget {
  final NutritionProvider provider;
  const _PlanSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final days = provider.planDays;
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            _grabber(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('План недели', style: _T.title2),
                  const Spacer(),
                  _Press(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: _P.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: days.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text('План пока пуст', style: _T.body),
                    const SizedBox(height: 4),
                    Text('Добавь блюда из книги рецептов', style: _T.caption),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final day = days[i];
                  final meals = provider.getMealsForDay(day.date);
                  final weekday = _weekdayRu(day.date.weekday);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _P.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('$weekday, ${day.date.day}.${day.date.month.toString().padLeft(2, '0')}',
                                style: GoogleFonts.inter(
                                    color: _P.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${meals.length} ${_mealsWord(meals.length)}',
                                style: GoogleFonts.inter(
                                    color: _P.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        if (meals.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: meals.map((m) {
                              final template = provider.templates
                                  .where((t) => t.id == m.templateId)
                                  .firstOrNull;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${m.mealType.emoji} ${template?.name ?? 'Блюдо'}',
                                  style: GoogleFonts.inter(
                                      color: _P.text,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
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

  String _weekdayRu(int wd) {
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return names[wd - 1];
  }

  String _mealsWord(int n) {
    if (n == 1) return 'приём';
    if (n >= 2 && n <= 4) return 'приёма';
    return 'приёмов';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHEET: ПОКУПКИ (с возможностью удаления)
// ═══════════════════════════════════════════════════════════════════
class _ShoppingSheet extends StatelessWidget {
  final NutritionProvider provider;
  const _ShoppingSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final items = provider.shoppingItems;
    final active = items.where((i) => !i.isBought).toList();
    final bought = items.where((i) => i.isBought).toList();
    final total = active.fold<double>(0, (s, i) => s + i.totalPrice);

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
            _grabber(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Список покупок', style: _T.title2),
                  const Spacer(),
                  if (total > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _P.skySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${total.toStringAsFixed(0)} ₽',
                          style: GoogleFonts.inter(
                              color: _P.skyDeep,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [ui.FontFeature.tabularFigures()])),
                    ),
                  const SizedBox(width: 8),
                  _Press(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: _P.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text('Список пуст', style: _T.body))
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  if (active.isNotEmpty) ...[
                    Text('Нужно купить',
                        style: GoogleFonts.inter(
                            color: _P.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    ...active.map((item) => _shoppingTile(item, provider)),
                    const SizedBox(height: 16),
                  ],
                  if (bought.isNotEmpty) ...[
                    Text('Куплено',
                        style: GoogleFonts.inter(
                            color: _P.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    ...bought.map((item) => _shoppingTile(item, provider)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shoppingTile(ShoppingItem item, NutritionProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: _P.pinkSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_rounded, color: _P.pinkDeep, size: 20),
        ),
        onDismissed: (direction) async {
          await provider.deleteShoppingItem(item.id);
          HapticFeedback.mediumImpact();
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: item.isBought ? _P.elevated : _P.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: Checkbox(
                  value: item.isBought,
                  onChanged: (_) => provider.toggleShoppingItem(item.id),
                  activeColor: _P.skyDeep,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.displayName,
                  style: GoogleFonts.inter(
                      color: item.isBought ? _P.textMuted : _P.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: item.isBought ? TextDecoration.lineThrough : null),
                ),
              ),
              Text('${item.quantity.toStringAsFixed(0)} ${item.unit}',
                  style: GoogleFonts.inter(
                      color: _P.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [ui.FontFeature.tabularFigures()])),
              const SizedBox(width: 8),
              Icon(Icons.swipe_left_rounded, size: 12, color: _P.pinkDeep.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHEET: БЮДЖЕТ
// ═══════════════════════════════════════════════════════════════════
class _BudgetSheet extends StatelessWidget {
  final NutritionProvider provider;
  const _BudgetSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final items = provider.shoppingItems;
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            _grabber(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Бюджет', style: _T.title2),
                  const Spacer(),
                  _Press(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: _P.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                    Text('ИТОГО НА НЕДЕЛЮ',
                        style: GoogleFonts.inter(
                            color: _Hero.textLow,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4)),
                    const SizedBox(height: 8),
                    Text('${total.toStringAsFixed(0)} ₽',
                        style: GoogleFonts.inter(
                            color: _Hero.textHigh,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.5,
                            fontFeatures: const [ui.FontFeature.tabularFigures()])),
                    const SizedBox(height: 4),
                    Text('${items.length} позиций',
                        style: GoogleFonts.inter(
                            color: _Hero.textLow,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (sorted.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final entry = sorted[i];
                    final pct = total > 0 ? (entry.value / total).clamp(0.0, 1.0) : 0.0;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _P.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(entry.key,
                                  style: GoogleFonts.inter(
                                      color: _P.text,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text('${entry.value.toStringAsFixed(0)} ₽',
                                  style: GoogleFonts.inter(
                                      color: _P.yellowDeep,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [ui.FontFeature.tabularFigures()])),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 3,
                              backgroundColor: _P.divider,
                              valueColor: const AlwaysStoppedAnimation(_P.yellowDeep),
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
                child: Center(child: Text('Добавь цены в список покупок', style: _T.body)),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHEET: ДЕТАЛИ РЕЦЕПТА
// ═══════════════════════════════════════════════════════════════════
class _TemplateDetailsSheet extends StatelessWidget {
  final NutritionProvider provider;
  final MealTemplate template;
  const _TemplateDetailsSheet({required this.provider, required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            _grabber(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _P.peachSoft,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🍱', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.name, style: _T.title2),
                        const SizedBox(height: 3),
                        Text('${template.items.length} ингредиентов', style: _T.caption),
                      ],
                    ),
                  ),
                  _Press(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: _P.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _P.bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _macroMini('${template.calories.round()}', 'ккал', _P.peachDeep),
                    _macroMini(template.protein.toStringAsFixed(0), 'Б', _P.greenDeep),
                    _macroMini(template.fat.toStringAsFixed(0), 'Ж', _P.peachDeep),
                    _macroMini(template.carbs.toStringAsFixed(0), 'У', _P.yellowDeep),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Text('ИНГРЕДИЕНТЫ',
                      style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  ...template.items.map((item) {
                    final p = provider.products.where((x) => x.id == item.productId).firstOrNull;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _P.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(p?.categoryEmoji ?? '🍽️', style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: GoogleFonts.inter(
                                        color: _P.text,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Text('${item.grams.round()} г',
                                    style: GoogleFonts.inter(
                                        color: _P.textMuted, fontSize: 10)),
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

  Widget _macroMini(String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  fontFeatures: const [ui.FontFeature.tabularFigures()])),
          const SizedBox(height: 2),
          Text(unit,
              style: GoogleFonts.inter(
                  color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}