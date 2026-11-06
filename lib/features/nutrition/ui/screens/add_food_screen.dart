// features/nutrition/ui/screens/add_food_screen.dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static const greenDeep = Color(0xFF6C9E88);
  static const skyDeep = Color(0xFF7E9DC6);
  static const yellowDeep = Color(0xFFE0B054);
  static const pinkDeep = Color(0xFFD17A8F);
}

class _T {
  static final title2 = GoogleFonts.inter(
      fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: _P.text);
  static final headline = GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, color: _P.text);
  static final body = GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400, color: _P.textMuted);
  static final caption = GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
  static TextStyle get overline => GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _P.textMuted);
}

const _categoryKeys = <String>[
  'meat', 'fish', 'dairy', 'grains', 'vegetables', 'fruits', 'nuts', 'legumes', 'drinks',
];

String _catLabel(String c) {
  const m = {
    'meat': 'Мясо',
    'fish': 'Рыба',
    'dairy': 'Молочное',
    'grains': 'Крупы',
    'vegetables': 'Овощи',
    'fruits': 'Фрукты',
    'nuts': 'Орехи',
    'legumes': 'Бобовые',
    'drinks': 'Напитки',
  };
  return m[c] ?? c;
}

// ═══════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════
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
  final _searchCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController(text: '100');
  final _searchFocus = FocusNode();
  final _gramsFocus = FocusNode();
  final _scrollController = ScrollController();

  Timer? _debounceTimer;
  String _rawQuery = ''; // immediate (for rail visibility / focus state)
  String _query = '';    // debounced (used for filtering)
  String? _selectedCategory;
  FoodProduct? _selectedProduct;
  FoodProduct? _displayedProduct; // survives deselect for slide-out animation
  late MealType _selectedMeal;
  bool _reduceMotion = false;

  // §4 remember last-used grams per product for quick-add
  final Map<String, double> _lastGrams = {};

  // §13 memoize filter results
  List<FoodProduct>? _cacheFiltered;
  String _cacheQuery = '__';
  String? _cacheCategory = '__';
  int _cacheProductsId = -1;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.initialMeal ?? MealType.suggestForNow();
    if (widget.preselectedProduct != null) {
      _selectedProduct = widget.preselectedProduct;
      _displayedProduct = widget.preselectedProduct;
      _searchCtrl.text = widget.preselectedProduct!.name;
      _rawQuery = widget.preselectedProduct!.name;
      _query = widget.preselectedProduct!.name;
    }
    _searchFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchFocus.removeListener(_onFocusChanged);
    _searchFocus.dispose();
    _gramsFocus.dispose();
    _searchCtrl.dispose();
    _gramsCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Duration _dur(int ms) =>
      _reduceMotion ? Duration.zero : Duration(milliseconds: ms);

  // §2 debounced search
  void _onSearchChanged(String v) {
    setState(() {
      _rawQuery = v;
      if (v != _query) _selectedProduct = null;
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _query = v);
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchCtrl.clear();
    setState(() {
      _rawQuery = '';
      _query = '';
      _selectedProduct = null;
    });
  }

  void _clearAllFilters() {
    _debounceTimer?.cancel();
    _searchCtrl.clear();
    setState(() {
      _rawQuery = '';
      _query = '';
      _selectedCategory = null;
      _selectedProduct = null;
    });
  }

  void _onSelectProduct(FoodProduct p) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedProduct = p;
      _displayedProduct = p;
      _gramsCtrl.text = '100';
    });
  }

  void _onToggleCategory(String? cat) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory =
      (cat == null || _selectedCategory == cat) ? null : cat;
      _selectedProduct = null;
    });
  }

  // §3b meal picker
  Future<void> _showMealPicker() async {
    final entries = widget.nutritionProvider.getEntriesForDate(widget.date);
    final kcalByMeal = <MealType, double>{};
    for (final m in MealType.values) {
      kcalByMeal[m] =
          entries.where((e) => e.mealType == m).fold(0.0, (s, e) => s + e.calories);
    }

    final selected = await showModalBottomSheet<MealType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _grabber(),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Куда добавить', style: _T.title2),
                      const SizedBox(height: 3),
                      Text('Приём пищи', style: _T.caption),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...MealType.values.map((m) {
                final sel = m == _selectedMeal;
                final kcal = kcalByMeal[m] ?? 0;
                return _Press(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(ctx, m);
                  },
                  child: Container(
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: sel ? _P.peachSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: sel ? Colors.white : _P.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(m.emoji, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.displayName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _P.text,
                                  )),
                              const SizedBox(height: 2),
                              Text(
                                kcal > 0 ? '${kcal.round()} ккал' : 'Пока пусто',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: _P.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel ? _P.peachDeep : Colors.transparent,
                            border: Border.all(
                              color: sel ? _P.peachDeep : _P.divider,
                              width: 1.5,
                            ),
                          ),
                          child: sel
                              ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedMeal = selected);
    }
  }

  // §13 memoized filter
  List<FoodProduct> _filterProducts(NutritionProvider provider) {
    final products = provider.products;
    final id = identityHashCode(products);
    if (_cacheFiltered != null &&
        _cacheQuery == _query &&
        _cacheCategory == _selectedCategory &&
        _cacheProductsId == id) {
      return _cacheFiltered!;
    }
    var result = _query.isEmpty ? products : provider.searchProducts(_query);
    if (_selectedCategory != null) {
      result = result.where((p) => p.category == _selectedCategory).toList();
    }
    _cacheFiltered = result;
    _cacheQuery = _query;
    _cacheCategory = _selectedCategory;
    _cacheProductsId = id;
    return result;
  }

  // ── ADD ────────────────────────────────────────────────────────
  Future<void> _addProduct(FoodProduct p, double grams, {required bool close}) async {
    if (grams <= 0) return;
    HapticFeedback.mediumImpact();
    await widget.nutritionProvider.addEntry(
      product: p,
      grams: grams,
      mealType: _selectedMeal,
      date: widget.date,
    );
    _lastGrams[p.id] = grams;
    if (!mounted) return;
    if (close) {
      Navigator.pop(context);
    } else {
      setState(() => _gramsCtrl.text = '100');
      _snack('${p.name} · ${grams.round()} г добавлен');
    }
  }

  Future<void> _quickAdd(FoodProduct p) async {
    final grams = _lastGrams[p.id] ?? 100.0;
    final before = widget.nutritionProvider.getEntriesForDate(widget.date).length;
    await _addProduct(p, grams, close: false);
    if (!mounted) return;
    final after = widget.nutritionProvider.getEntriesForDate(widget.date);
    FoodDiaryEntry? newEntry;
    if (after.length > before) newEntry = after.last;
    if (newEntry != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${p.name} · ${grams.round()} г добавлен'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _P.greenDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        action: SnackBarAction(
          label: 'Отменить',
          textColor: Colors.white,
          onPressed: () {
            widget.nutritionProvider.removeEntry(newEntry!.id);
            if (mounted) setState(() {});
          },
        ),
      ));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _P.greenDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = widget.nutritionProvider;
    final filtered = _filterProducts(provider);
    final showQuick = _rawQuery.isEmpty && _selectedCategory == null;

    // §14 already-in-diary lookup, computed once per build
    final entries = provider.getEntriesForDate(widget.date);
    final addedByProduct = <String, double>{};
    for (final e in entries) {
      addedByProduct[e.productId] =
          (addedByProduct[e.productId] ?? 0) + e.grams;
    }

    // §1 header kcal preview
    int? kcalPreview;
    if (_selectedProduct != null) {
      final g = double.tryParse(_gramsCtrl.text) ?? 0;
      if (g > 0) {
        kcalPreview = _selectedProduct!.forGrams(g).calories.round();
      }
    }

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HeaderDelegate(
                    mealName: _selectedMeal.displayName,
                    kcalPreview: kcalPreview,
                    reduceMotion: _reduceMotion,
                    onBack: () => Navigator.pop(context),
                    onMealTap: _showMealPicker,
                  ),
                ),
                SliverToBoxAdapter(child: _buildSearchField()),
                SliverToBoxAdapter(child: _buildCategories()),
                SliverToBoxAdapter(child: _buildMealRow()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                if (showQuick && !_quickRailEmpty(provider))
                  SliverToBoxAdapter(child: _buildQuickRail(provider)),
                if (!showQuick)
                  SliverToBoxAdapter(
                      child: _buildAllProductsHeader(filtered.length)),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(child: _buildEmpty())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => _buildProductRow(filtered[i], addedByProduct),
                      childCount: filtered.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
            // §9 commit bar
            if (_displayedProduct != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: _selectedProduct == null,
                  child: AnimatedSlide(
                    offset: _selectedProduct == null
                        ? const Offset(0, 1)
                        : Offset.zero,
                    duration: _dur(200),
                    curve: Curves.easeOutCubic,
                    child: RepaintBoundary(
                      child: SafeArea(
                        top: false,
                        child: _buildBottomSummary(_displayedProduct!),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _quickRailEmpty(NutritionProvider provider) =>
      provider.favoriteProducts.isEmpty &&
          provider.getRecentProducts(limit: 8).isEmpty;

  // ═══════════════════════════════════════════════════════════════
  //  2. SEARCH — command bar
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSearchField() {
    final focused = _searchFocus.hasFocus;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AnimatedContainer(
        duration: _dur(160),
        height: 56,
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: focused ? _P.peachDeep : _P.divider,
            width: focused ? 1.2 : 1,
          ),
          boxShadow: focused
              ? [
            BoxShadow(
              color: _P.peachDeep.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 1,
            )
          ]
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _P.peachSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.search_rounded,
                  size: 16, color: _P.peachDeep),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                autofocus: widget.preselectedProduct == null,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Найти продукт или бренд…',
                  hintStyle:
                  GoogleFonts.inter(color: _P.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_rawQuery.isNotEmpty)
              _Press(
                onTap: _clearSearch,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.close_rounded,
                      size: 18, color: _P.textMuted),
                ),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  3A. CATEGORIES — compact pill strip, no emoji
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            _catChip(null, 'Все'),
            ..._categoryKeys.map((c) => _catChip(c, _catLabel(c))),
          ],
        ),
      ),
    );
  }

  Widget _catChip(String? cat, String label) {
    final isAll = cat == null;
    final selected = isAll ? _selectedCategory == null : _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _Press(
        onTap: () => _onToggleCategory(cat),
        child: AnimatedContainer(
          duration: _dur(160),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? _P.peachSoft : _P.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _P.peachDeep : _P.divider,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? _P.peachDeep : _P.textMuted,
                ),
              ),
              if (selected && !isAll) ...[
                const SizedBox(width: 4),
                const Icon(Icons.close_rounded,
                    size: 13, color: _P.peachDeep),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  3B. MEAL ROW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMealRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _Press(
        onTap: _showMealPicker,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _P.divider),
          ),
          child: Row(
            children: [
              Text(_selectedMeal.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(
                _selectedMeal.displayName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: _P.text,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '· нажми, чтобы изменить',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, color: _P.textMuted),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: _P.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  4. QUICK-PICK RAIL
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuickRail(NutritionProvider provider) {
    final favs = provider.favoriteProducts.take(3).toList();
    final recent = provider.getRecentProducts(limit: 6);
    final items = <Widget>[];
    for (final p in favs) {
      items.add(_quickChip(p));
    }
    if (favs.isNotEmpty && recent.isNotEmpty) {
      items.add(const SizedBox(width: 8));
      items.add(Container(width: 1, height: 56, color: _P.divider));
      items.add(const SizedBox(width: 8));
    }
    for (final p in recent) {
      items.add(_quickChip(p));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('БЫСТРЫЙ ВЫБОР', style: _T.overline),
                const Spacer(),
                _Press(
                  onTap: () => _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(children: [
                      Text('Все',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _P.peachDeep)),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 14, color: _P.peachDeep),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => items[i],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(FoodProduct p) {
    return _Press(
      onTap: () => _quickAdd(p),
      onLongPress: () => _onSelectProduct(p),
      child: Container(
        width: 220,
        height: 80,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _P.peachSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child:
              Text(p.categoryEmoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _P.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${p.calories.round()} ккал · ${p.categoryName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _P.textMuted,
                      fontSize: 11,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Press(
              onTap: () => _quickAdd(p),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _P.peachSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: _P.peachDeep.withOpacity(0.25)),
                ),
                child: const Icon(Icons.add_rounded,
                    size: 20, color: _P.peachDeep),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  7. ALL PRODUCTS HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAllProductsHeader(int count) {
    final filterActive =
        _rawQuery.isNotEmpty || _selectedCategory != null || _query.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Все продукты', style: _T.title2),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _P.elevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const Spacer(),
              if (filterActive)
                _Press(
                  onTap: _clearAllFilters,
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'Сбросить',
                      style: GoogleFonts.inter(
                        color: _P.peachDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: _P.divider),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  5. PRODUCT ROW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProductRow(
      FoodProduct p, Map<String, double> addedByProduct) {
    final selected = _selectedProduct?.id == p.id;
    final addedGrams = addedByProduct[p.id] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Semantics(
        label: '${p.name}, ${p.calories.round()} ккал на 100 г',
        child: AnimatedContainer(
          duration: _dur(180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? _P.peachSoft.withOpacity(0.35) : _P.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _P.peachDeep : _P.divider,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              _Press(
                onTap: () => selected
                    ? setState(() => _selectedProduct = null)
                    : _onSelectProduct(p),
                onLongPress: () =>
                    widget.nutritionProvider.toggleFavorite(p.id).then((_) {
                      if (mounted) setState(() {});
                    }),
                child: SizedBox(
                  height: 72,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _P.bg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(p.categoryEmoji,
                              style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: _P.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                p.categoryName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: _P.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${p.calories.round()}',
                              style: GoogleFonts.inter(
                                color: _P.peachDeep,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1,
                                fontFeatures: [
                                  ui.FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _dot(_P.greenDeep, p.protein),
                                const SizedBox(width: 6),
                                _dot(_P.yellowDeep, p.fat),
                                const SizedBox(width: 6),
                                _dot(_P.pinkDeep, p.carbs),
                              ],
                            ),
                          ],
                        ),
                        if (selected) ...[
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: 0.5,
                            duration: _dur(200),
                            child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: _P.peachDeep),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: _dur(220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: selected
                    ? _buildExpandedEditor(p, addedGrams)
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 2),
        Text(
          value.round().toString(),
          style: GoogleFonts.inter(
            color: _P.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFeatures: [ui.FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  6. EXPANDED EDITOR — the amount is the hero
  // ═══════════════════════════════════════════════════════════════
  Widget _buildExpandedEditor(FoodProduct p, double addedGrams) {
    final grams = double.tryParse(_gramsCtrl.text) ?? 0;
    final isValid = grams > 0;
    final isOverweight = grams > 2000;
    final macros = p.forGrams(grams > 0 ? grams : 0);
    final deltaPct = grams != 100
        ? ((grams - 100) / 100 * 100).round()
        : 0;

    return Container(
      decoration: const BoxDecoration(
        color: _P.bg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // §6 top row: label + big amount + input pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('КОЛИЧЕСТВО', style: _T.overline),
                    const SizedBox(height: 3),
                    Text('Укажи вес',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: _P.textMuted)),
                  ],
                ),
              ),
              _Press(
                onTap: () => _gramsFocus.requestFocus(),
                child: AnimatedSwitcher(
                  duration: _dur(180),
                  child: Row(
                    key: ValueKey(grams.round()),
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isValid ? grams.round().toString() : '—',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1.2,
                          height: 1,
                          color: isValid ? _P.text : _P.textMuted,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text('г',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _P.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 88,
                height: 44,
                decoration: BoxDecoration(
                  color: _P.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: _P.peachDeep.withOpacity(0.35), width: 1.2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gramsCtrl,
                        focusNode: _gramsFocus,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text('г',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _P.textMuted)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isOverweight) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 13, color: _P.yellowDeep),
              const SizedBox(width: 4),
              Text('Проверь вес',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _P.yellowDeep)),
            ]),
          ],
          const SizedBox(height: 12),
          // §6 preset chips (Wrap, packed)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in const [50, 100, 150, 200, 250])
                _pressChip(
                  label: '$v',
                  selected: grams.round() == v,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _gramsCtrl.text = '$v');
                  },
                ),
              _pressChip(
                label: '+ Своё',
                selected: !const [50, 100, 150, 200, 250]
                    .contains(grams.round()),
                onTap: () => _gramsFocus.requestFocus(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // §6 macro summary strip
          Container(
            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _P.divider),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _macroCell(
                      'ККАЛ',
                      macros.calories.round().toString(),
                      _P.peachDeep,
                      delta: deltaPct,
                    ),
                  ),
                  _vertDivider(),
                  Expanded(
                    child: _macroCell(
                      'Б',
                      macros.protein.toStringAsFixed(1),
                      _P.greenDeep,
                    ),
                  ),
                  _vertDivider(),
                  Expanded(
                    child: _macroCell(
                      'Ж',
                      macros.fat.toStringAsFixed(1),
                      _P.yellowDeep,
                    ),
                  ),
                  _vertDivider(),
                  Expanded(
                    child: _macroCell(
                      'У',
                      macros.carbs.toStringAsFixed(1),
                      _P.pinkDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (addedGrams > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _P.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 13, color: _P.greenDeep),
                  const SizedBox(width: 5),
                  Text(
                    'Уже в дневнике · ${addedGrams.round()} г',
                    style: GoogleFonts.inter(
                      color: _P.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // §6 CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _Press(
              onTap: isValid
                  ? () => _addProduct(p, grams, close: true)
                  : null,
              onLongPress: isValid
                  ? () => _addProduct(p, grams, close: false)
                  : null,
              child: Opacity(
                opacity: isValid ? 1 : 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    color: _P.peachDeep,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _P.peachDeep.withOpacity(0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isValid
                          ? 'ДОБАВИТЬ В ${_selectedMeal.displayName.toUpperCase()}'
                          : 'УКАЖИ ВЕС',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
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

  Widget _pressChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _dur(160),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _P.peachSoft : _P.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _P.peachDeep : _P.divider,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? _P.peachDeep : _P.text,
            fontFeatures: [ui.FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _macroCell(String label, String value, Color color, {int? delta}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(value),
            tween: Tween(begin: 0, end: 1),
            duration: _dur(240),
            curve: Curves.easeOutCubic,
            builder: (_, t, __) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 4),
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.3,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _P.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          if (delta != null && delta != 0) ...[
            const SizedBox(height: 2),
            Text(
              '${delta > 0 ? '+' : ''}$delta%',
              style: GoogleFonts.inter(
                color: _P.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vertDivider() => Container(width: 1, color: _P.divider);

  // ═══════════════════════════════════════════════════════════════
  //  9. COMMIT BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomSummary(FoodProduct p) {
    final grams = double.tryParse(_gramsCtrl.text) ?? 0;
    final kcal = p.forGrams(grams > 0 ? grams : 0).calories.round();
    final enabled = grams > 0;

    return Container(
      decoration: BoxDecoration(
        color: _P.surface,
        border: const Border(top: BorderSide(color: _P.divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: _P.peachDeep.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _P.peachSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(p.categoryEmoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _P.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${grams.round()} г · $kcal ккал',
                  style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Press(
            onTap: enabled ? () => _addProduct(p, grams, close: true) : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _P.peachDeep,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _P.peachDeep.withOpacity(0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    size: 24, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  8. EMPTY STATES
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEmpty() {
    final filterActive =
        _rawQuery.isNotEmpty || _query.isNotEmpty || _selectedCategory != null;
    final categoryOnly = _selectedCategory != null && _query.isEmpty;
    final icon =
    categoryOnly ? Icons.inventory_2_outlined : Icons.search_off_rounded;
    final title = categoryOnly
        ? 'В категории «${_catLabel(_selectedCategory!)}» пока ничего нет'
        : 'Ничего не найдено';
    final subtitle = categoryOnly
        ? 'Попробуй другую категорию'
        : 'Попробуй другое слово или очисти фильтры';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _P.peachSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: _P.peachDeep),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center, style: _T.headline),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center, style: _T.body),
          if (filterActive) ...[
            const SizedBox(height: 14),
            _Press(
              onTap: _clearAllFilters,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _P.divider),
                ),
                child: Text('Сбросить фильтры',
                    style: GoogleFonts.inter(
                      color: _P.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _grabber() => Container(
    width: 36,
    height: 5,
    decoration: BoxDecoration(
      color: _P.divider,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  1. STICKY HEADER DELEGATE
// ═══════════════════════════════════════════════════════════════════
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final String mealName;
  final int? kcalPreview;
  final bool reduceMotion;
  final VoidCallback onBack;
  final VoidCallback onMealTap;

  _HeaderDelegate({
    required this.mealName,
    required this.kcalPreview,
    required this.reduceMotion,
    required this.onBack,
    required this.onMealTap,
  });

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 80;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12 * t, sigmaY: 12 * t),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _P.bg.withOpacity(0.94 * t),
              border: Border(
                bottom: BorderSide(
                  color: _P.divider.withOpacity(t),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _Press(
                  onTap: onBack,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.chevron_left_rounded,
                        color: _P.text, size: 24),
                  ),
                ),
                Expanded(
                  child: _Press(
                    onTap: onMealTap,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Добавить в «$mealName»',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                              color: _P.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more_rounded,
                            size: 16, color: _P.textMuted),
                      ],
                    ),
                  ),
                ),
                if (kcalPreview != null)
                  AnimatedSwitcher(
                    duration: duration,
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Container(
                      key: ValueKey(kcalPreview),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: _P.peachSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+ $kcalPreview ккал',
                        style: GoogleFonts.inter(
                          color: _P.peachDeep,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 8),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate old) =>
      old.mealName != mealName ||
          old.kcalPreview != kcalPreview ||
          old.reduceMotion != reduceMotion;
}

// ═══════════════════════════════════════════════════════════════════
//  11. Press — physical switch feel
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
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: widget.child,
    );
    if (!interactive) return child;
    final reduce =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) return child;
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}