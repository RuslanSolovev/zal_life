// features/nutrition/ui/screens/food_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/color_settings_provider.dart';
import 'add_food_screen.dart';

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

class FoodSearchScreen extends StatefulWidget {
  final bool isDark;

  const FoodSearchScreen({
    super.key,
    this.isDark = true,
  });

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

enum FoodSortMode {
  name,
  caloriesAsc,
  caloriesDesc,
  proteinDesc,
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  late final TextEditingController _searchController;

  String _query = '';
  String? _selectedCategory;
  bool _favoritesOnly = false;
  FoodSortMode _sortMode = FoodSortMode.name;

  // Palette
  Color get _background => _Power.bg(widget.isDark);
  Color get _surface => _Power.card(widget.isDark);
  Color get _surface2 => _Power.card2(widget.isDark);
  Color get _text => _Power.textPrimary(widget.isDark);
  Color get _muted => _Power.textTertiary(widget.isDark);
  Color get _textSecondary => _Power.textSecondary(widget.isDark);
  Color get _line => _Power.separator(widget.isDark);

  /// Акцент — динамический, из ColorSettingsProvider
  Color get _cyan => context.watch<ColorSettingsProvider>().accent;

  // Семантические — фиксированные
  static const Color _green = _Power.green;
  static const Color _purple = _Power.violet;
  static const Color _pink = _Power.magma;
  static const Color _orange = _Power.volt;
  static const Color _yellow = _Power.plasma;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();

    final products = _getFilteredProducts(provider);
    final categories = _getCategories(provider.products);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(provider),
            _buildTopSection(provider, categories),
            const SizedBox(height: 4),
            Expanded(
              child: products.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 120),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildProductRow(
                      products[index],
                      provider,
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(NutritionProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: _text,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ПРОДУКТЫ',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'База',
                  style: TextStyle(
                    color: _text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // Sort
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: PopupMenuButton<FoodSortMode>(
              tooltip: 'Сортировка',
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _line, width: 0.5),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: _textSecondary,
                  size: 18,
                ),
              ),
              color: _surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (mode) {
                HapticFeedback.selectionClick();
                setState(() => _sortMode = mode);
              },
              itemBuilder: (context) => [
                _sortItem(FoodSortMode.name, 'По названию',
                    Icons.sort_by_alpha_rounded),
                _sortItem(FoodSortMode.caloriesAsc, 'Меньше калорий',
                    Icons.south_rounded),
                _sortItem(FoodSortMode.caloriesDesc, 'Больше калорий',
                    Icons.north_rounded),
                _sortItem(FoodSortMode.proteinDesc, 'Больше белка',
                    Icons.fitness_center_rounded),
              ],
            ),
          ),
          // Add
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _showCustomProductDialog(provider);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _cyan,
                shape: BoxShape.circle,
                boxShadow: _Power.glow(_cyan,
                    strength: 0.4, blur: 16),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: _Power.darkBg,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP SECTION
  // ============================================================

  Widget _buildTopSection(
      NutritionProvider provider,
      List<String> categories,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildFilterBar(categories),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _line, width: 0.5),
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
              style: TextStyle(
                color: _text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              cursorColor: _cyan,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Найти продукт…',
                hintStyle: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _searchController.clear();
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.close_rounded,
                  color: _muted,
                  size: 18,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFilterBar(List<String> categories) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _categoryChip(
            title: 'ВСЕ',
            icon: Icons.grid_view_rounded,
            selected: _selectedCategory == null && !_favoritesOnly,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = null;
                _favoritesOnly = false;
              });
            },
          ),
          const SizedBox(width: 8),
          _categoryChip(
            title: 'ИЗБРАННОЕ',
            icon: Icons.favorite_rounded,
            selected: _favoritesOnly,
            accent: _pink,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _favoritesOnly = !_favoritesOnly;
                if (_favoritesOnly) _selectedCategory = null;
              });
            },
          ),
          const SizedBox(width: 8),
          ...categories.map((category) {
            final selected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _categoryChip(
                title: _catName(category).toUpperCase(),
                icon: _categoryIcon(category),
                selected: selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategory = selected ? null : category;
                    _favoritesOnly = false;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    Color? accent,
  }) {
    final chipAccent = accent ?? _cyan;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? chipAccent.withOpacity(0.14)
              : _surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? chipAccent
                : _line,
            width: selected ? 1 : 0.5,
          ),
          boxShadow: selected
              ? _Power.softGlow(chipAccent, strength: 0.3)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? chipAccent : _muted,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: selected ? chipAccent : _text,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTER LOGIC
  // ============================================================

  List<FoodProduct> _getFilteredProducts(NutritionProvider provider) {
    List<FoodProduct> result;

    if (_query.isEmpty) {
      result = List<FoodProduct>.from(provider.products);
    } else {
      result =
      List<FoodProduct>.from(provider.searchProducts(_query));
    }

    if (_favoritesOnly) {
      result = result.where((product) => product.isFavorite).toList();
    }

    if (_selectedCategory != null) {
      result = result
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    switch (_sortMode) {
      case FoodSortMode.name:
        result.sort(
              (a, b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case FoodSortMode.caloriesAsc:
        result.sort((a, b) => a.calories.compareTo(b.calories));
        break;
      case FoodSortMode.caloriesDesc:
        result.sort((a, b) => b.calories.compareTo(a.calories));
        break;
      case FoodSortMode.proteinDesc:
        result.sort((a, b) => b.protein.compareTo(a.protein));
        break;
    }

    return result;
  }

  List<String> _getCategories(List<FoodProduct> products) {
    final categories = products
        .map<String>((product) => product.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    categories.sort((a, b) => _catName(a).compareTo(_catName(b)));
    return categories;
  }

  // ============================================================
  // PRODUCT ROW
  // ============================================================

  Widget _buildProductRow(
      FoodProduct product,
      NutritionProvider provider,
      ) {
    final calories = product.calories.round();
    final protein = product.protein.round();
    final fat = product.fat.round();
    final carbs = product.carbs.round();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showProductSheet(product, provider);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line, width: 0.5),
        ),
        child: Row(
          children: [
            _buildProductIcon(product),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _text,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (product.isCustom)
                        _badge('МОЙ', _purple),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      _macroBadge('$calories ККАЛ', _cyan),
                      _macroBadge('Б $protein', _green),
                      _macroBadge('Ж $fat', _orange),
                      _macroBadge('У $carbs', _purple),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              children: [
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
                      color: product.isFavorite
                          ? _pink.withOpacity(0.14)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      product.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: product.isFavorite ? _pink : _muted,
                      size: 19,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _muted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductIcon(FoodProduct product) {
    final emoji =
    product.categoryEmoji.isNotEmpty ? product.categoryEmoji : '🍽️';

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _cyan.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _macroBadge(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          height: 1,
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          height: 1,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    String title = 'НИЧЕГО НЕ НАЙДЕНО';
    String subtitle = 'Попробуй изменить поиск';
    IconData icon = Icons.search_off_rounded;

    if (_favoritesOnly) {
      title = 'ИЗБРАННОЕ ПУСТО';
      subtitle = 'Добавляй продукты в избранное';
      icon = Icons.favorite_border_rounded;
    } else if (_query.isEmpty && _selectedCategory != null) {
      title = 'НЕТ ПРОДУКТОВ';
      subtitle = 'В этой категории пока ничего нет';
      icon = Icons.inventory_2_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _cyan.withOpacity(0.10),
                shape: BoxShape.circle,
                boxShadow: _Power.softGlow(_cyan, strength: 0.15),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: _cyan,
                size: 40,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            if (_query.isNotEmpty ||
                _selectedCategory != null ||
                _favoritesOnly)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _query = '';
                    _selectedCategory = null;
                    _favoritesOnly = false;
                  });
                  _searchController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _cyan.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'СБРОСИТЬ ФИЛЬТРЫ',
                    style: TextStyle(
                      color: _cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SORT MENU
  // ============================================================

  PopupMenuItem<FoodSortMode> _sortItem(
      FoodSortMode mode,
      String title,
      IconData icon,
      ) {
    final selected = _sortMode == mode;

    return PopupMenuItem<FoodSortMode>(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            color: selected ? _cyan : _muted,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: selected ? _cyan : _text,
                fontSize: 13,
                fontWeight:
                selected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          if (selected)
            Icon(
              Icons.check_rounded,
              color: _cyan,
              size: 18,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY HELPERS
  // ============================================================

  String _catName(String category) {
    const names = <String, String>{
      'meat': 'Мясо',
      'fish': 'Рыба',
      'dairy': 'Молочное',
      'grains': 'Крупы',
      'vegetables': 'Овощи',
      'fruits': 'Фрукты',
      'nuts': 'Орехи',
      'seeds': 'Семена',
      'legumes': 'Бобовые',
      'oils': 'Масла',
      'sweets': 'Сладкое',
      'drinks': 'Напитки',
      'bakery': 'Выпечка',
      'fastfood': 'Фастфуд',
      'supplements': 'Добавки',
      'sauces': 'Соусы',
      'other': 'Другое',
    };
    return names[category] ?? category;
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'meat':
        return Icons.restaurant_rounded;
      case 'fish':
        return Icons.set_meal_rounded;
      case 'dairy':
        return Icons.local_drink_rounded;
      case 'grains':
        return Icons.grain_rounded;
      case 'vegetables':
        return Icons.eco_rounded;
      case 'fruits':
        return Icons.apple_rounded;
      case 'nuts':
        return Icons.energy_savings_leaf_rounded;
      case 'seeds':
        return Icons.grass_rounded;
      case 'legumes':
        return Icons.scatter_plot_rounded;
      case 'oils':
        return Icons.opacity_rounded;
      case 'sweets':
        return Icons.cake_rounded;
      case 'drinks':
        return Icons.local_bar_rounded;
      case 'bakery':
        return Icons.bakery_dining_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;
      case 'supplements':
        return Icons.medication_rounded;
      case 'sauces':
        return Icons.water_drop_rounded;
      default:
        return Icons.lunch_dining_rounded;
    }
  }

  // ============================================================
  // PRODUCT SHEET
  // ============================================================

  void _showProductSheet(
      FoodProduct product, NutritionProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _muted,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _buildProductIcon(product),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                color: _text,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _catName(product.category).toUpperCase(),
                              style: TextStyle(
                                color: _muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          provider.toggleFavorite(product.id);
                          Navigator.pop(sheetContext);
                          setState(() {});
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: product.isFavorite
                                ? _pink.withOpacity(0.14)
                                : _surface2,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            product.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: product.isFavorite ? _pink : _muted,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildGlowRay(color: _cyan, widthFactor: 0.88),
                  const SizedBox(height: 22),
                  Text(
                    'НА 100 Г',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _macroCard(
                          'ККАЛ',
                          '${product.calories.round()}',
                          _cyan,
                          Icons.local_fire_department_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _macroCard(
                          'Б',
                          product.protein.toStringAsFixed(1),
                          _green,
                          Icons.fitness_center_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _macroCard(
                          'Ж',
                          product.fat.toStringAsFixed(1),
                          _orange,
                          Icons.water_drop_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _macroCard(
                          'У',
                          product.carbs.toStringAsFixed(1),
                          _purple,
                          Icons.bolt_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildGlowRay(color: _cyan, widthFactor: 0.72),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddFoodScreen(
                              isDark: widget.isDark,
                              date: DateTime.now(),
                              preselectedProduct: product,
                              nutritionProvider: provider,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyan,
                        foregroundColor: _Power.darkBg,
                        elevation: 0,
                        shadowColor:
                        _cyan.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'ДОБАВИТЬ В ДНЕВНИК',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
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
      },
    );
  }

  Widget _macroCard(
      String title,
      String value,
      Color accent,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.20), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowRay({
    required Color color,
    double widthFactor = 0.8,
  }) {
    return SizedBox(
      height: 12,
      width: double.infinity,
      child: CustomPaint(
        painter: _GlowRayPainter(
          color: color,
          widthFactor: widthFactor,
          backgroundColor: _line,
        ),
      ),
    );
  }

  // ============================================================
  // CUSTOM PRODUCT DIALOG
  // ============================================================

  Future<void> _showCustomProductDialog(
      NutritionProvider provider) async {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final fatController = TextEditingController();
    final carbsController = TextEditingController();

    String category = 'other';

    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom:
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _muted,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _cyan.withOpacity(0.14),
                                borderRadius:
                                BorderRadius.circular(13),
                                boxShadow: _Power.softGlow(
                                    _cyan,
                                    strength: 0.25),
                              ),
                              child: Icon(
                                Icons.restaurant_menu_rounded,
                                color: _cyan,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'НОВЫЙ ПРОДУКТ',
                                    style: TextStyle(
                                      color: _cyan,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Создать',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                      color: _text,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _customField(
                          'НАЗВАНИЕ',
                          nameController,
                          Icons.edit_rounded,
                          keyboard: TextInputType.text,
                        ),
                        const SizedBox(height: 10),
                        _customField(
                          'КАЛОРИИ НА 100 Г',
                          caloriesController,
                          Icons.local_fire_department_rounded,
                          accent: _cyan,
                        ),
                        const SizedBox(height: 10),
                        _customField(
                          'БЕЛКИ, Г',
                          proteinController,
                          Icons.fitness_center_rounded,
                          accent: _green,
                        ),
                        const SizedBox(height: 10),
                        _customField(
                          'ЖИРЫ, Г',
                          fatController,
                          Icons.water_drop_rounded,
                          accent: _orange,
                        ),
                        const SizedBox(height: 10),
                        _customField(
                          'УГЛЕВОДЫ, Г',
                          carbsController,
                          Icons.bolt_rounded,
                          accent: _purple,
                        ),
                        const SizedBox(height: 14),
                        _categoryDropdown(
                          category,
                              (value) {
                            HapticFeedback.selectionClick();
                            setSheetState(() => category = value);
                          },
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.pop(sheetContext);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _textSecondary,
                                    side: BorderSide(color: _line),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Отмена',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final name =
                                    nameController.text.trim();
                                    final calories =
                                        double.tryParse(
                                          caloriesController.text
                                              .trim()
                                              .replaceAll(
                                              ',', '.'),
                                        ) ??
                                            0;
                                    final protein =
                                        double.tryParse(
                                          proteinController.text
                                              .trim()
                                              .replaceAll(
                                              ',', '.'),
                                        ) ??
                                            0;
                                    final fat = double.tryParse(
                                      fatController.text
                                          .trim()
                                          .replaceAll(',', '.'),
                                    ) ??
                                        0;
                                    final carbs = double.tryParse(
                                      carbsController.text
                                          .trim()
                                          .replaceAll(',', '.'),
                                    ) ??
                                        0;

                                    if (name.isEmpty) {
                                      _showSnackBar(
                                          'Введите название');
                                      return;
                                    }
                                    if (calories <= 0) {
                                      _showSnackBar(
                                          'Укажите калории');
                                      return;
                                    }

                                    HapticFeedback.mediumImpact();

                                    await provider.addCustomProduct(
                                      name: name,
                                      category: category,
                                      calories: calories,
                                      protein: protein,
                                      fat: fat,
                                      carbs: carbs,
                                    );

                                    if (!context.mounted) return;
                                    Navigator.pop(sheetContext);

                                    if (!mounted) return;
                                    _showSnackBar(
                                        'Продукт добавлен');
                                    setState(() {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _cyan,
                                    foregroundColor: _Power.darkBg,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'СОХРАНИТЬ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      caloriesController.dispose();
      proteinController.dispose();
      fatController.dispose();
      carbsController.dispose();
    }
  }

  Widget _customField(
      String label,
      TextEditingController controller,
      IconData icon, {
        Color? accent,
        TextInputType? keyboard,
      }) {
    final fieldAccent = accent ?? _cyan;
    final inputType = keyboard ??
        const TextInputType.numberWithOptions(decimal: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: inputType,
          style: TextStyle(
            color: _text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          cursorColor: fieldAccent,
          decoration: InputDecoration(
            hintText: label.toLowerCase(),
            hintStyle: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: _surface2,
            prefixIcon: Icon(
              icon,
              color: fieldAccent,
              size: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _line, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: fieldAccent,
                width: 1.4,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _categoryDropdown(
      String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'КАТЕГОРИЯ',
            style: TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line, width: 0.5),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            dropdownColor: _surface,
            iconEnabledColor: _muted,
            style: TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
            ),
            items: const [
              DropdownMenuItem(value: 'other', child: Text('Другое')),
              DropdownMenuItem(value: 'meat', child: Text('Мясо')),
              DropdownMenuItem(value: 'fish', child: Text('Рыба')),
              DropdownMenuItem(value: 'dairy', child: Text('Молочное')),
              DropdownMenuItem(value: 'grains', child: Text('Крупы')),
              DropdownMenuItem(value: 'vegetables', child: Text('Овощи')),
              DropdownMenuItem(value: 'fruits', child: Text('Фрукты')),
              DropdownMenuItem(value: 'nuts', child: Text('Орехи')),
              DropdownMenuItem(value: 'sweets', child: Text('Сладкое')),
              DropdownMenuItem(value: 'drinks', child: Text('Напитки')),
            ],
            onChanged: (v) {
              if (v == null) return;
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
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

    final totalWidth = size.width * widthFactor;
    final left = (size.width - totalWidth) / 2;
    final right = left + totalWidth;

    final rect = Rect.fromLTRB(left, 0, right, size.height);

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withOpacity(0),
        color.withOpacity(0.025),
        color.withOpacity(0.08),
        color.withOpacity(0.24),
        color.withOpacity(0.62),
        color,
        color.withOpacity(0.62),
        color.withOpacity(0.24),
        color.withOpacity(0.08),
        color.withOpacity(0.025),
        color.withOpacity(0),
      ],
      stops: const [
        0.0,
        0.10,
        0.20,
        0.34,
        0.45,
        0.50,
        0.55,
        0.66,
        0.80,
        0.90,
        1.0,
      ],
    );

    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter =
      const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawLine(
      Offset(left, centerY),
      Offset(right, centerY),
      glowPaint,
    );

    final corePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

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