// features/nutrition/ui/screens/add_food_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/color_settings_provider.dart';

// ==================== POWER MODE TOKENS ====================

class _Power {
  static const Color heroBase = Color(0xFF050505);
  static const Color heroDeep = Color(0xFF120700);

  static const Color volt = Color(0xFFFF5500);
  static const Color voltBright = Color(0xFFFF7A1A);
  static const Color magma = Color(0xFFFF2D55);
  static const Color plasma = Color(0xFFFFCC00);
  static const Color ice = Color(0xFF00E5FF);
  static const Color lime = Color(0xFFB4FF39);
  static const Color green = Color(0xFF00C853);
  static const Color red = Color(0xFFFF3B30);
  static const Color violet = Color(0xFF9C82FF);

  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkCard2 = Color(0xFF2C2C2E);
  static const Color lightBg = Color(0xFFF2F2F7);
  static const Color lightCard = Color(0xFFFFFFFF);

  static Color bg(bool isDark) => isDark ? darkBg : lightBg;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color card2(bool isDark) => isDark ? darkCard2 : const Color(0xFFF9FAFB);
  static Color textPrimary(bool isDark) => isDark ? Colors.white : Colors.black;
  static Color textSecondary(bool isDark) => isDark
      ? Colors.white.withOpacity(0.6)
      : const Color(0xFF3C3C43).withOpacity(0.6);
  static Color textTertiary(bool isDark) => isDark
      ? Colors.white.withOpacity(0.3)
      : const Color(0xFF3C3C43).withOpacity(0.3);
  static Color separator(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

  static List<BoxShadow> softGlow(Color color, {double strength = 0.18}) => [
    BoxShadow(color: color.withOpacity(strength), blurRadius: 16),
  ];

  static List<BoxShadow> glow(Color color,
      {double strength = 0.4, double blur = 24}) =>
      [
        BoxShadow(
          color: color.withOpacity(strength),
          blurRadius: blur,
          offset: const Offset(0, 6),
        ),
      ];
}

class AddFoodScreen extends StatefulWidget {
  final bool isDark;
  final DateTime date;
  final MealType? initialMeal;
  final FoodProduct? preselectedProduct;
  final NutritionProvider nutritionProvider;

  const AddFoodScreen({
    super.key,
    required this.isDark,
    required this.date,
    required this.nutritionProvider,
    this.initialMeal,
    this.preselectedProduct,
  });

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  // ============================================================
  // PALETTE
  // ============================================================

  Color get _background => _Power.bg(widget.isDark);
  Color get _surface => _Power.card(widget.isDark);
  Color get _surface2 => _Power.card2(widget.isDark);
  Color get _textPrimary => _Power.textPrimary(widget.isDark);
  Color get _textSecondary => _Power.textSecondary(widget.isDark);
  Color get _textMuted => _Power.textTertiary(widget.isDark);
  Color get _divider => _Power.separator(widget.isDark);
  Color get _softWhite => widget.isDark
      ? Colors.white.withOpacity(0.035)
      : Colors.black.withOpacity(0.025);
  Color get _lineBase => _Power.separator(widget.isDark);

  /// Акцент — динамический, из ColorSettingsProvider
  Color get _cyan => context.watch<ColorSettingsProvider>().accent;

  // Семантические — фиксированные
  static const Color _green = _Power.green;
  static const Color _pink = _Power.magma;
  static const Color _yellow = _Power.plasma;
  static const Color _orange = _Power.volt;
  static const Color _purple = _Power.violet;

  // ============================================================
  // STATE
  // ============================================================

  final _searchController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');

  String _query = '';
  String? _selectedCategory;
  FoodProduct? _selectedProduct;
  MealType _selectedMeal = MealType.suggestForNow();

  @override
  void initState() {
    super.initState();

    if (widget.initialMeal != null) {
      _selectedMeal = widget.initialMeal!;
    }

    if (widget.preselectedProduct != null) {
      _selectedProduct = widget.preselectedProduct;
      _query = widget.preselectedProduct!.name;
      _searchController.text = widget.preselectedProduct!.name;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final provider = widget.nutritionProvider;

    final baseList = _query.trim().isEmpty
        ? provider.products
        : provider.searchProducts(_query);

    final filtered = _selectedCategory == null
        ? baseList
        : baseList.where((p) => p.category == _selectedCategory).toList();

    final showQuickSections =
        _query.trim().isEmpty && _selectedCategory == null;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
                children: [
                  _buildSearch(),
                  const SizedBox(height: 13),
                  _buildCategorySection(),
                  _buildGlowRay(color: _cyan, widthFactor: 0.84),
                  _buildMealSelector(),
                  const SizedBox(height: 13),
                  if (showQuickSections)
                    ..._buildQuickSections(provider),
                  if (!showQuickSections)
                    _buildResultsHeader(filtered.length),
                  if (filtered.isEmpty)
                    _buildEmptySearch()
                  else
                    ...filtered.map(
                          (product) => _buildProductCard(provider, product),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomSummary(provider),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
      decoration: BoxDecoration(
        color: _background.withOpacity(0.96),
        border: Border(bottom: BorderSide(color: _divider, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _divider, width: 0.5),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ДОБАВИТЬ',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Продукт',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _cyan.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _Power.softGlow(_cyan, strength: 0.25),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.restaurant_rounded,
              color: _cyan,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_surface2, _surface]),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _divider, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _cyan.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.search_rounded,
              color: _cyan,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: widget.preselectedProduct == null,
              onChanged: (value) {
                setState(() {
                  _query = value;
                  _selectedProduct = null;
                });
              },
              style: TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: 'Поиск продукта…',
                hintStyle: TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _searchController.clear();
                setState(() {
                  _query = '';
                  _selectedProduct = null;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.close_rounded,
                  color: _textMuted,
                  size: 18,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategorySection() {
    const categories = [
      'meat',
      'fish',
      'dairy',
      'grains',
      'vegetables',
      'fruits',
      'nuts',
      'legumes',
      'drinks',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            children: [
              Text(
                'КАТЕГОРИИ',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(),
              if (_selectedCategory != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                  child: Text(
                    'СБРОСИТЬ',
                    style: TextStyle(
                      color: _cyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildCategoryChip('Все', null),
              ...categories.map(
                    (category) => _buildCategoryChip(
                  _categoryName(category),
                  category,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final selected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedCategory = category;
            _selectedProduct = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? _cyan.withOpacity(0.14) : _surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? _cyan : _divider,
              width: selected ? 1 : 0.5,
            ),
            boxShadow:
            selected ? _Power.softGlow(_cyan, strength: 0.25) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _cyan : _textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MEAL
  // ============================================================

  Widget _buildMealSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow:
                  _Power.softGlow(_Power.volt, strength: 0.2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: _orange,
                  size: 17,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ПРИЁМ ПИЩИ',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Куда добавить продукт',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedMeal.displayName.toUpperCase(),
                  style: const TextStyle(
                    color: _orange,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 43,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: MealType.values.map((meal) {
                final selected = _selectedMeal == meal;

                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedMeal = meal;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        color: selected
                            ? _orange.withOpacity(0.14)
                            : _surface2,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: selected ? _orange : _divider,
                          width: selected ? 1 : 0.5,
                        ),
                        boxShadow: selected
                            ? _Power.softGlow(_Power.volt,
                            strength: 0.25)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${meal.emoji} ${meal.displayName}',
                        style: TextStyle(
                          color: selected ? _orange : _textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK SECTIONS
  // ============================================================

  List<Widget> _buildQuickSections(NutritionProvider provider) {
    final recent = provider.getRecentProducts(limit: 8);
    final favorites = provider.favoriteProducts.take(8).toList();

    final widgets = <Widget>[];

    if (recent.isNotEmpty) {
      widgets.add(_buildSectionTitle(
        '⚡',
        'НЕДАВНИЕ',
        'Добавляй то, что ел недавно',
        _yellow,
      ));
      widgets.add(const SizedBox(height: 10));
      widgets.add(_buildHorizontalProducts(provider, recent));
      widgets.add(_buildGlowRay(color: _yellow, widthFactor: 0.72));
    }

    if (favorites.isNotEmpty) {
      widgets.add(_buildSectionTitle(
        '★',
        'ИЗБРАННОЕ',
        'Твои любимые продукты',
        _pink,
      ));
      widgets.add(const SizedBox(height: 10));
      widgets.add(_buildHorizontalProducts(provider, favorites));
      widgets.add(_buildGlowRay(color: _pink, widthFactor: 0.72));
    }

    widgets.add(_buildSectionTitle(
      '◉',
      'ВСЕ ПРОДУКТЫ',
      'Выбери продукт из базы',
      _cyan,
    ));
    widgets.add(const SizedBox(height: 10));

    return widgets;
  }

  Widget _buildSectionTitle(
      String icon,
      String title,
      String subtitle,
      Color color,
      ) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(11),
            boxShadow: _Power.softGlow(color, strength: 0.15),
          ),
          alignment: Alignment.center,
          child: Text(
            icon,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalProducts(
      NutritionProvider provider,
      List<FoodProduct> items,
      ) {
    return SizedBox(
      height: 119,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final product = items[index];

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedProduct = product;
                _query = product.name;
                _searchController.text = product.name;
                _selectedCategory = null;
              });
            },
            child: Container(
              width: 135,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_surface2, _surface],
                ),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _divider, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _textPrimary.withOpacity(0.035),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      product.categoryEmoji,
                      style: const TextStyle(fontSize: 19),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 9)),
                      const SizedBox(width: 3),
                      Text(
                        '${product.calories.round()} ККАЛ',
                        style: TextStyle(
                          color: _cyan,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // RESULTS HEADER
  // ============================================================

  Widget _buildResultsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 5, 2, 10),
      child: Row(
        children: [
          Text(
            _query.isNotEmpty ? 'РЕЗУЛЬТАТЫ ПОИСКА' : 'ПРОДУКТЫ',
            style: TextStyle(
              color: _textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const Spacer(),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: _cyan,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard(
      NutritionProvider provider,
      FoodProduct product,
      ) {
    final selected = _selectedProduct?.id == product.id;
    final grams = double.tryParse(_gramsController.text) ?? 100;
    final macros = product.forGrams(grams);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: selected ? _cyan.withOpacity(0.06) : _surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: selected ? _cyan.withOpacity(0.5) : _divider,
              width: selected ? 1.2 : 0.5,
            ),
            boxShadow: selected
                ? _Power.softGlow(_cyan, strength: 0.15)
                : null,
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (selected) {
                      _selectedProduct = null;
                    } else {
                      _selectedProduct = product;
                      _gramsController.text = '100';
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 49,
                        height: 49,
                        decoration: BoxDecoration(
                          color: selected
                              ? _cyan.withOpacity(0.14)
                              : _textPrimary.withOpacity(0.035),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          product.categoryEmoji,
                          style: const TextStyle(fontSize: 23),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.categoryName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 5),
                        decoration: BoxDecoration(
                          color: _cyan.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${product.calories.round()}',
                          style: TextStyle(
                            color: _cyan,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          provider.toggleFavorite(product.id);
                          setState(() {});
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: product.isFavorite
                                ? _yellow.withOpacity(0.14)
                                : Colors.transparent,
                          ),
                          child: Icon(
                            product.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: product.isFavorite
                                ? _yellow
                                : _textMuted.withOpacity(0.55),
                            size: 20,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: selected ? _cyan : _textMuted.withOpacity(0.6),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    _macroMini('🔥', '${product.calories.round()}', 'ккал',
                        _cyan),
                    _macroMini('Б', product.protein.toStringAsFixed(1), 'г',
                        _green),
                    _macroMini('Ж', product.fat.toStringAsFixed(1), 'г', _pink),
                    _macroMini('У', product.carbs.toStringAsFixed(1), 'г',
                        _yellow),
                  ],
                ),
              ),
              if (selected)
                _buildExpandedProductEditor(provider, product, macros),
            ],
          ),
        ),
        if (selected)
          _buildGlowRay(color: _cyan, widthFactor: 0.58),
      ],
    );
  }

  Widget _macroMini(
      String label,
      String value,
      String unit,
      Color color,
      ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                '$value$unit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EXPANDED EDITOR
  // ============================================================

  Widget _buildExpandedProductEditor(
      NutritionProvider provider,
      FoodProduct product,
      dynamic macros,
      ) {
    final grams = double.tryParse(_gramsController.text) ?? 100;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withOpacity(0.15), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'КОЛИЧЕСТВО',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Укажи вес продукта',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 112,
                height: 48,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(13),
                  border:
                  Border.all(color: _cyan.withOpacity(0.25), width: 0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gramsController,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        'г',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              for (final value in [50, 100, 150, 200, 250])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: _gramPreset(value),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                _expandedMacro('🔥', '${macros.calories.round()}', 'ккал',
                    _cyan),
                _expandedMacro(
                    'Б', macros.protein.toStringAsFixed(1), 'г', _green),
                _expandedMacro(
                    'Ж', macros.fat.toStringAsFixed(1), 'г', _pink),
                _expandedMacro(
                    'У', macros.carbs.toStringAsFixed(1), 'г', _yellow),
              ],
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _addProduct(provider, product, grams);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: _Power.darkBg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, size: 20),
                  const SizedBox(width: 7),
                  Text(
                    'ДОБАВИТЬ • ${grams.round()} Г',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.65,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gramPreset(int grams) {
    final current = double.tryParse(_gramsController.text) ?? 100;
    final selected = current.round() == grams;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _gramsController.text = '$grams';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _cyan.withOpacity(0.14) : _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _cyan : _divider,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Text(
          '$grams',
          style: TextStyle(
            color: selected ? _cyan : _textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _expandedMacro(
      String label,
      String value,
      String unit,
      Color color,
      ) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            unit.toUpperCase(),
            style: TextStyle(
              color: _textMuted,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM SUMMARY
  // ============================================================

  Widget _buildBottomSummary(NutritionProvider provider) {
    if (_selectedProduct == null) {
      return const SizedBox.shrink();
    }

    final grams = double.tryParse(_gramsController.text) ?? 100;
    final macros = _selectedProduct!.forGrams(grams);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: _background.withOpacity(0.97),
          border: Border(top: BorderSide(color: _divider, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 25,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _Power.softGlow(_cyan, strength: 0.2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _selectedProduct!.categoryEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedProduct!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${grams.round()} Г • ${macros.calories.round()} ККАЛ',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _addProduct(provider, _selectedProduct!, grams);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: _Power.darkBg,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Icon(Icons.add_rounded, size: 21),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptySearch() {
    return Padding(
      padding: const EdgeInsets.only(top: 55),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _textPrimary.withOpacity(0.035),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🔍', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 16),
          Text(
            'Ничего не найдено',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Попробуй другой запрос',
            style: TextStyle(
              color: _textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GLOW RAY
  // ============================================================

  Widget _buildGlowRay({
    required Color color,
    double widthFactor = 0.85,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: SizedBox(
        height: 18,
        child: CustomPaint(
          painter: _GlowRayPainter(
            color: color,
            widthFactor: widthFactor,
            backgroundColor: _lineBase,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD PRODUCT
  // ============================================================

  Future<void> _addProduct(
      NutritionProvider provider,
      FoodProduct product,
      double grams,
      ) async {
    if (grams <= 0) return;

    await provider.addEntry(
      product: product,
      grams: grams,
      mealType: _selectedMeal,
      date: widget.date,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  // ============================================================
  // CATEGORY NAMES
  // ============================================================

  String _categoryName(String category) {
    const names = {
      'meat': '🥩 Мясо',
      'fish': '🐟 Рыба',
      'dairy': '🥛 Молочка',
      'grains': '🌾 Крупы',
      'vegetables': '🥬 Овощи',
      'fruits': '🍎 Фрукты',
      'nuts': '🥜 Орехи',
      'legumes': '🫘 Бобовые',
      'drinks': '☕ Напитки',
    };
    return names[category] ?? category;
  }
}

// ============================================================
// GLOW RAY PAINTER
// ============================================================

class _GlowRayPainter extends CustomPainter {
  final Color color;
  final double widthFactor;
  final Color backgroundColor;

  _GlowRayPainter({
    required this.color,
    required this.widthFactor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    if (backgroundColor != Colors.transparent) {
      final basePaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        basePaint,
      );
    }

    final lineWidth = size.width * widthFactor;
    final left = (size.width - lineWidth) / 2;
    final right = left + lineWidth;

    final rect = Rect.fromLTRB(left, 0, right, size.height);

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withOpacity(0),
        color.withOpacity(0.035),
        color.withOpacity(0.12),
        color.withOpacity(0.36),
        color.withOpacity(0.90),
        color,
        color.withOpacity(0.90),
        color.withOpacity(0.36),
        color.withOpacity(0.12),
        color.withOpacity(0.035),
        color.withOpacity(0),
      ],
      stops: const [
        0.00,
        0.10,
        0.22,
        0.36,
        0.46,
        0.50,
        0.54,
        0.64,
        0.78,
        0.90,
        1.00,
      ],
    );

    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawLine(
      Offset(left, centerY),
      Offset(right, centerY),
      glowPaint,
    );

    final corePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    canvas.drawLine(
      Offset(left, centerY),
      Offset(right, centerY),
      corePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowRayPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.widthFactor != widthFactor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}