// features/nutrition/ui/screens/food_search_screen.dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import 'add_food_screen.dart'; // kept — still reachable from the dashboard

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
  static const pinkSoft = Color(0xFFFCF0F2);
  static const pinkDeep = Color(0xFFD17A8F);
  static const lavenderDeep = Color(0xFF9381BB);
}

class _T {
  static final title2 = GoogleFonts.inter(
      fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: _P.text);
  static final headline = GoogleFonts.inter(
      fontSize: 17, fontWeight: FontWeight.w600, color: _P.text);
  static final body = GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400, color: _P.textMuted);
  static final caption = GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
  static TextStyle get overline => GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _P.textMuted);
}

// ═══════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════
enum FoodSortMode { name, caloriesAsc, caloriesDesc, proteinDesc }

class FoodSearchScreen extends StatefulWidget {
  final bool isDark;
  const FoodSearchScreen({super.key, this.isDark = true});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  String _rawQuery = ''; // immediate — used for clear button
  String _query = '';    // debounced — used for filtering
  String? _selectedCategory;
  bool _favoritesOnly = false;
  FoodSortMode _sortMode = FoodSortMode.name;
  bool _reduceMotion = false;
  bool _initialLoad = true;

  // §13 memoized filter cache
  List<FoodProduct>? _cacheFiltered;
  String _cacheQuery = '__';
  String? _cacheCategory = '__';
  bool _cacheFavorites = false;
  FoodSortMode _cacheSort = FoodSortMode.name;
  int _cacheProductsId = -1;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
    // §14 lightweight "loading" heuristic since provider has no loading flag
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _initialLoad = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchFocus.dispose();
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Duration _dur(int ms) =>
      _reduceMotion ? Duration.zero : Duration(milliseconds: ms);

  // §2 debounce
  void _onSearchChanged(String v) {
    setState(() => _rawQuery = v);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _query = v.trim());
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchCtrl.clear();
    setState(() {
      _rawQuery = '';
      _query = '';
    });
  }

  void _clearAllFilters() {
    _debounceTimer?.cancel();
    _searchCtrl.clear();
    setState(() {
      _rawQuery = '';
      _query = '';
      _selectedCategory = null;
      _favoritesOnly = false;
    });
  }

  void _focusSearch() {
    _searchFocus.requestFocus();
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final products = _filtered(provider);
    final categories = _categories(provider.products);
    final hasFavorites = provider.products.any((p) => p.isFavorite);

    // §13 compute "already in diary" once per build
    final nowEntries = provider.getEntriesForDate(DateTime.now());
    final inDiary = <String, double>{};
    for (final e in nowEntries) {
      inDiary[e.productId] = (inDiary[e.productId] ?? 0) + e.grams;
    }

    final showShimmer =
        _initialLoad && products.isEmpty && _query.isEmpty &&
            _selectedCategory == null && !_favoritesOnly;

    final sortActive = _sortMode != FoodSortMode.name;

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
                // §1 sticky header
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyHeaderDelegate(
                    count: products.length,
                    sortActive: sortActive,
                    reduceMotion: _reduceMotion,
                    onBack: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
                    onSearchFocus: _focusSearch,
                    onSort: _showSortSheet,
                  ),
                ),
                SliverToBoxAdapter(child: _buildSearchField()),
                SliverToBoxAdapter(child: _buildFilters(categories, hasFavorites)),
                SliverToBoxAdapter(
                  child: _buildSectionHeader(products.length),
                ),
                if (showShimmer)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: SizedBox(height: 72, child: _ShimmerBox()),
                      ),
                      childCount: 4,
                    ),
                  )
                else if (products.isEmpty)
                  SliverToBoxAdapter(child: _buildEmpty(provider))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) {
                        final p = products[i];
                        return KeyedSubtree(
                          key: ValueKey('row_${p.id}'),
                          child: _staggered(i, _buildProductRow(p, inDiary)),
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
            // §8 bottom action bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(child: _buildActionBar(provider)),
            ),
          ],
        ),
      ),
    );
  }

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
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: _P.peachDeep,
                decoration: InputDecoration(
                  hintText: 'Найти продукт…',
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
  //  4. FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFilters(List<String> categories, bool hasFavorites) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ShaderMask(
        // §4 subtle horizontal fade-out on trailing edge
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.88, 1.0],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _filterChip(
                label: 'Все',
                selected: _selectedCategory == null && !_favoritesOnly,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategory = null;
                    _favoritesOnly = false;
                  });
                },
              ),
              if (hasFavorites) ...[
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Избранное',
                  selected: _favoritesOnly,
                  accent: _P.pinkDeep,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _favoritesOnly = !_favoritesOnly;
                      if (_favoritesOnly) _selectedCategory = null;
                    });
                  },
                ),
              ],
              ...categories.map((c) {
                final selected = _selectedCategory == c;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _filterChip(
                    label: _catName(c),
                    selected: selected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategory = selected ? null : c;
                        _favoritesOnly = false;
                      });
                    },
                  ),
                );
              }),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color accent = _P.peachDeep,
  }) {
    return _Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _dur(160),
        height: 44, // §13 ≥ 44 hit target, visually padded via alignment
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? _P.peachSoft.withOpacity(accent == _P.pinkDeep ? 0.55 : 0.55)
              : _P.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : _P.divider,
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
                color: selected ? accent : _P.textMuted,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(Icons.close_rounded, size: 13, color: accent),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  5. SECTION HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(int count) {
    final filterActive =
        _query.isNotEmpty || _selectedCategory != null || _favoritesOnly;
    final title = _query.isNotEmpty
        ? 'Результаты'
        : _favoritesOnly
        ? 'Избранное'
        : _selectedCategory != null
        ? _catName(_selectedCategory!)
        : 'Все продукты';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _T.title2),
                    if (filterActive) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Найдено: $count ${_productWord(count)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _P.textMuted,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (filterActive)
                _Press(
                  onTap: _clearAllFilters,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
  //  6. PRODUCT ROW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProductRow(FoodProduct p, Map<String, double> inDiary) {
    final addedGrams = inDiary[p.id] ?? 0;
    final isLight = p.calories < 100;
    final muted = p.calories <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Semantics(
        label:
        '${p.name}, ${p.calories.round()} ккал на 100 г, ${_catName(p.category).toLowerCase()}',
        child: Opacity(
          opacity: muted ? 0.7 : 1.0,
          child: _Press(
            onTap: () => _showProductSheet(p),
            onLongPress: () => _toggleFavorite(p),
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _P.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isLight ? _P.peachSoft : _P.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      p.categoryEmoji.isNotEmpty ? p.categoryEmoji : '🍽️',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
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
                            ),
                            if (addedGrams > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _P.greenDeep.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_rounded,
                                        size: 10, color: _P.greenDeep),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${addedGrams.round()} г',
                                      style: GoogleFonts.inter(
                                        color: _P.greenDeep,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: [
                                          ui.FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.isCustom
                              ? '${_catName(p.category).toUpperCase()} · МОЙ'
                              : _catName(p.category).toUpperCase(),
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
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 96,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${p.calories.round()}',
                              style: GoogleFonts.inter(
                                color: _P.peachDeep,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                                height: 1,
                                fontFeatures: [ui.FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'ккал',
                              style: GoogleFonts.inter(
                                color: _P.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
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
                  ),
                ],
              ),
            ),
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

  // §6 long-press to favorite
  void _toggleFavorite(FoodProduct p) {
    HapticFeedback.mediumImpact();
    widget.isDark; // no-op, kept for API
    context.read<NutritionProvider>().toggleFavorite(p.id);
    final wasFav = p.isFavorite;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(wasFav ? 'Убрано из избранного' : 'Добавлено в избранное'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _P.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      action: SnackBarAction(
        label: 'Отменить',
        textColor: Colors.white,
        onPressed: () {
          HapticFeedback.heavyImpact();
          context.read<NutritionProvider>().toggleFavorite(p.id);
        },
      ),
    ));
  }

  // §11 staggered enter
  Widget _staggered(int index, Widget child) {
    if (_reduceMotion || index >= 8) return child;
    final start = (index * 40).clamp(0, 320) / 400.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: c),
      ),
      child: child,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  10. EMPTY STATES
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEmpty(NutritionProvider provider) {
    final filterActive =
        _query.isNotEmpty || _selectedCategory != null || _favoritesOnly;

    final isFavEmpty = _favoritesOnly;
    final IconData icon;
    final String title;
    final String subtitle;
    final Color accent;
    if (isFavEmpty) {
      icon = Icons.favorite_border_rounded;
      title = 'Избранное пусто';
      subtitle = 'Нажми и удерживай продукт, чтобы добавить в избранное';
      accent = _P.pinkDeep;
    } else if (_selectedCategory != null && _query.isEmpty) {
      icon = Icons.inventory_2_outlined;
      title = 'Ничего не найдено';
      subtitle = 'Попробуй другую категорию';
      accent = _P.peachDeep;
    } else {
      icon = Icons.search_off_rounded;
      title = 'Ничего не найдено';
      subtitle = 'Попробуй другое слово или категорию';
      accent = _P.peachDeep;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 36),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: _T.headline),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: _T.body),
          const SizedBox(height: 20),
          if (filterActive)
            _Press(
              onTap: _clearAllFilters,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _P.peachDeep,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isFavEmpty ? 'Открыть все продукты' : 'Сбросить фильтры',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (!isFavEmpty) ...[
            const SizedBox(height: 10),
            _Press(
              onTap: () => _showCustomProductSheet(),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _P.divider),
                ),
                child: Text(
                  'Создать продукт',
                  style: GoogleFonts.inter(
                    color: _P.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  8. BOTTOM ACTION BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildActionBar(NutritionProvider provider) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: _P.surface.withOpacity(0.92),
            border: const Border(top: BorderSide(color: _P.divider, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _Press(
                      onTap: () => _showCustomProductSheet(),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: _P.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _P.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded,
                                size: 18, color: _P.text),
                            const SizedBox(width: 6),
                            Text(
                              'Создать продукт',
                              style: GoogleFonts.inter(
                                color: _P.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _Press(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
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
                      child: const Icon(Icons.check_rounded,
                          size: 24, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  3. SORT SHEET
  // ═══════════════════════════════════════════════════════════════
  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
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
                      Text('Сортировка', style: _T.title2),
                      const SizedBox(height: 3),
                      Text('Как показать продукты', style: _T.caption),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _sortRow(ctx, FoodSortMode.name, 'По названию',
                  Icons.sort_by_alpha_rounded),
              _sortRow(ctx, FoodSortMode.caloriesAsc, 'Меньше калорий',
                  Icons.south_rounded),
              _sortRow(ctx, FoodSortMode.caloriesDesc, 'Больше калорий',
                  Icons.north_rounded),
              _sortRow(ctx, FoodSortMode.proteinDesc, 'Больше белка',
                  Icons.fitness_center_rounded),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortRow(BuildContext sheetCtx, FoodSortMode mode, String label, IconData icon) {
    final selected = _sortMode == mode;
    return _Press(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(sheetCtx);
        setState(() => _sortMode = mode);
      },
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _P.peachSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? Colors.white : _P.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18,
                  color: selected ? _P.peachDeep : _P.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: _P.text,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _P.peachDeep : Colors.transparent,
                border: Border.all(
                  color: selected ? _P.peachDeep : _P.divider,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                  size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  7. PRODUCT DETAIL SHEET
  // ═══════════════════════════════════════════════════════════════
  void _showProductSheet(FoodProduct p) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProductDetailSheet(
        product: p,
        provider: context.read<NutritionProvider>(),
        date: DateTime.now(),
        reduceMotion: _reduceMotion,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  9. CUSTOM PRODUCT SHEET
  // ═══════════════════════════════════════════════════════════════
  Future<void> _showCustomProductSheet() async {
    final createdName = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CustomProductSheet(
        provider: context.read<NutritionProvider>(),
        reduceMotion: _reduceMotion,
      ),
    );
    if (createdName == null || !mounted) return;
    final provider = context.read<NutritionProvider>();
    FoodProduct? created;
    for (final p in provider.products) {
      if (p.isCustom && p.name == createdName) {
        created = p;
        break;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Продукт добавлен в базу'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _P.greenDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      action: created != null
          ? SnackBarAction(
        label: 'Открыть',
        textColor: Colors.white,
        onPressed: () => _showProductSheet(created!),
      )
          : null,
    ));
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════
  List<FoodProduct> _filtered(NutritionProvider provider) {
    final productsId = identityHashCode(provider.products);
    if (_cacheFiltered != null &&
        _cacheQuery == _query &&
        _cacheCategory == _selectedCategory &&
        _cacheFavorites == _favoritesOnly &&
        _cacheSort == _sortMode &&
        _cacheProductsId == productsId) {
      return _cacheFiltered!;
    }
    List<FoodProduct> r = _query.isEmpty
        ? List<FoodProduct>.from(provider.products)
        : List<FoodProduct>.from(provider.searchProducts(_query));
    if (_favoritesOnly) r = r.where((p) => p.isFavorite).toList();
    if (_selectedCategory != null) {
      r = r.where((p) => p.category == _selectedCategory).toList();
    }
    switch (_sortMode) {
      case FoodSortMode.name:
        r.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case FoodSortMode.caloriesAsc:
        r.sort((a, b) => a.calories.compareTo(b.calories));
        break;
      case FoodSortMode.caloriesDesc:
        r.sort((a, b) => b.calories.compareTo(a.calories));
        break;
      case FoodSortMode.proteinDesc:
        r.sort((a, b) => b.protein.compareTo(a.protein));
        break;
    }
    _cacheFiltered = r;
    _cacheQuery = _query;
    _cacheCategory = _selectedCategory;
    _cacheFavorites = _favoritesOnly;
    _cacheSort = _sortMode;
    _cacheProductsId = productsId;
    return r;
  }

  List<String> _categories(List<FoodProduct> products) {
    final cats =
    products.map((p) => p.category).where((c) => c.isNotEmpty).toSet().toList();
    cats.sort((a, b) => _catName(a).compareTo(_catName(b)));
    return cats;
  }

  String _catName(String c) {
    const m = {
      'meat': 'Мясо', 'fish': 'Рыба', 'dairy': 'Молочное', 'grains': 'Крупы',
      'vegetables': 'Овощи', 'fruits': 'Фрукты', 'nuts': 'Орехи',
      'seeds': 'Семена', 'legumes': 'Бобовые', 'oils': 'Масла',
      'sweets': 'Сладкое', 'drinks': 'Напитки', 'bakery': 'Выпечка',
      'fastfood': 'Фастфуд', 'supplements': 'Добавки', 'sauces': 'Соусы',
      'other': 'Другое',
    };
    return m[c] ?? c;
  }

  String _productWord(int count) {
    if (count == 1) return 'продукт';
    if (count >= 2 && count <= 4) return 'продукта';
    return 'продуктов';
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
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int count;
  final bool sortActive;
  final bool reduceMotion;
  final VoidCallback onBack;
  final VoidCallback onSearchFocus;
  final VoidCallback onSort;

  _StickyHeaderDelegate({
    required this.count,
    required this.sortActive,
    required this.reduceMotion,
    required this.onBack,
    required this.onSearchFocus,
    required this.onSort,
  });

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 80;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final showOverline = t < 0.5;

    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12 * t, sigmaY: 12 * t),
          child: Container(
            decoration: BoxDecoration(
              color: _P.bg.withOpacity(0.94 * t),
              border: Border(
                bottom: BorderSide(color: _P.divider.withOpacity(t), width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _Press(
                  onTap: onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: _P.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _P.divider),
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: _P.text, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showOverline)
                        Opacity(
                          opacity: 1 - t * 2,
                          child: Text('ПРОДУКТЫ',
                              style: _T.overline.copyWith(
                                  color: _P.peachDeep, fontSize: 9)),
                        ),
                      Text(
                        'База',
                        style: GoogleFonts.inter(
                          fontSize: 22 - t * 4, // 22 → 18 when collapsed
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                          color: _P.text,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                // sort button (peach-tinted when non-default)
                _Press(
                  onTap: onSort,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: sortActive ? _P.peachSoft : _P.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sortActive
                            ? _P.peachDeep.withOpacity(0.30)
                            : _P.divider,
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: sortActive ? _P.peachDeep : _P.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // cross-fade: "Найти" (expanded) → count chip (collapsed)
                AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: t < 0.5
                      ? _Press(
                    key: const ValueKey('hdr_search'),
                    onTap: onSearchFocus,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _P.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _P.divider),
                      ),
                      child: Row(children: [
                        const Icon(Icons.search_rounded,
                            size: 14, color: _P.textMuted),
                        const SizedBox(width: 5),
                        Text('Найти',
                            style: GoogleFonts.inter(
                              color: _P.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ]),
                    ),
                  )
                      : Container(
                    key: const ValueKey('hdr_count'),
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _P.elevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.inter(
                        color: _P.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate old) =>
      old.count != count ||
          old.sortActive != sortActive ||
          old.reduceMotion != reduceMotion;
}

// ═══════════════════════════════════════════════════════════════════
//  7. PRODUCT DETAIL SHEET (add-to-diary in one sheet)
// ═══════════════════════════════════════════════════════════════════
class _ProductDetailSheet extends StatefulWidget {
  final FoodProduct product;
  final NutritionProvider provider;
  final DateTime date;
  final bool reduceMotion;
  const _ProductDetailSheet({
    required this.product,
    required this.provider,
    required this.date,
    required this.reduceMotion,
  });

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  late final TextEditingController _gramsCtrl;
  late MealType _meal;

  @override
  void initState() {
    super.initState();
    _gramsCtrl = TextEditingController(text: '100');
    _meal = MealType.suggestForNow();
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    super.dispose();
  }

  Duration _dur(int ms) =>
      widget.reduceMotion ? Duration.zero : Duration(milliseconds: ms);

  FoodProduct get _current {
    try {
      return widget.provider.products
          .firstWhere((p) => p.id == widget.product.id);
    } catch (_) {
      return widget.product;
    }
  }

  Future<void> _add() async {
    final grams = double.tryParse(_gramsCtrl.text) ?? 0;
    if (grams <= 0) return;
    HapticFeedback.mediumImpact();

    final beforeIds =
    widget.provider.getEntriesForDate(widget.date).map((e) => e.id).toSet();
    await widget.provider.addEntry(
      product: _current,
      grams: grams,
      mealType: _meal,
      date: widget.date,
    );
    if (!mounted) return;

    final after = widget.provider.getEntriesForDate(widget.date);
    FoodDiaryEntry? newEntry;
    for (final e in after) {
      if (!beforeIds.contains(e.id)) {
        newEntry = e;
        break;
      }
    }

    final messenger = ScaffoldMessenger.of(context);
    final mealName = _meal.displayName.toLowerCase();
    final productId = _current.id;
    Navigator.pop(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text('Добавлено в $mealName · ${grams.round()} г'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _P.greenDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      action: newEntry != null
          ? SnackBarAction(
        label: 'Отменить',
        textColor: Colors.white,
        onPressed: () {
          HapticFeedback.heavyImpact();
          widget.provider.removeEntry(newEntry!.id);
        },
      )
          : null,
    ));
    // Reference productId to silence unused-variable in some analyzers.
    productId;
  }

  @override
  Widget build(BuildContext context) {
    final product = _current;
    final grams = double.tryParse(_gramsCtrl.text) ?? 0;
    final liveMacros = product.forGrams(grams > 0 ? grams : 0);
    final canAdd = grams > 0;

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _grabber()),
                const SizedBox(height: 18),

                // header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _P.peachSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        product.categoryEmoji.isNotEmpty
                            ? product.categoryEmoji
                            : '🍽️',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                              color: _P.text,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_catName(product.category).toUpperCase(),
                              style: _T.overline),
                        ],
                      ),
                    ),
                    _Press(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.provider.toggleFavorite(product.id);
                        setState(() {});
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                          product.isFavorite ? _P.pinkSoft : _P.bg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          product.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: product.isFavorite
                              ? _P.pinkDeep
                              : _P.textMuted,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // §7 НА 100 Г — 4 macro boxes
                Text('НА 100 Г', style: _T.overline),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _staticMacroBox('ККАЛ',
                        '${product.calories.round()}', _P.peachDeep),
                    const SizedBox(width: 8),
                    _staticMacroBox('БЕЛОК',
                        product.protein.toStringAsFixed(1), _P.greenDeep),
                    const SizedBox(width: 8),
                    _staticMacroBox('ЖИРЫ',
                        product.fat.toStringAsFixed(1), _P.yellowDeep),
                    const SizedBox(width: 8),
                    _staticMacroBox('УГЛЕВ.',
                        product.carbs.toStringAsFixed(1), _P.pinkDeep),
                  ],
                ),
                const SizedBox(height: 22),

                Container(height: 1, color: _P.divider),
                const SizedBox(height: 18),

                // §7 КОЛИЧЕСТВО
                Text('КОЛИЧЕСТВО', style: _T.overline),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                grams > 0 ? grams.round().toString() : '—',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -1.2,
                                  color: grams > 0 ? _P.text : _P.textMuted,
                                  height: 1,
                                  fontFeatures: [
                                    ui.FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text('г',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _P.textMuted,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text('Укажи вес',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: _P.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 88,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _P.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _P.peachDeep.withOpacity(0.35), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _gramsCtrl,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                              onChanged: (_) => setState(() {}),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: _P.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                                fontFeatures: [
                                  ui.FontFeature.tabularFigures()
                                ],
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
                                  color: _P.textMuted,
                                )),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // presets
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final v in const [50, 100, 150, 200, 250])
                      _presetChip(
                        label: '$v',
                        selected: grams.round() == v,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _gramsCtrl.text = '$v');
                        },
                      ),
                    _presetChip(
                      label: 'Своё',
                      selected: !const [50, 100, 150, 200, 250]
                          .contains(grams.round()),
                      onTap: () {
                        // focus by popping + reopening on the field is overkill;
                        // opening the keyboard via FocusScope works.
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // live macros
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
                          child: _liveMacroCell(
                            'ККАЛ',
                            liveMacros.calories.round().toString(),
                            _P.peachDeep,
                          ),
                        ),
                        _vertDivider(),
                        Expanded(
                          child: _liveMacroCell(
                            'Б',
                            liveMacros.protein.toStringAsFixed(1),
                            _P.greenDeep,
                          ),
                        ),
                        _vertDivider(),
                        Expanded(
                          child: _liveMacroCell(
                            'Ж',
                            liveMacros.fat.toStringAsFixed(1),
                            _P.yellowDeep,
                          ),
                        ),
                        _vertDivider(),
                        Expanded(
                          child: _liveMacroCell(
                            'У',
                            liveMacros.carbs.toStringAsFixed(1),
                            _P.pinkDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // §7 ПРИЁМ ПИЩИ
                Text('ПРИЁМ ПИЩИ', style: _T.overline),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: MealType.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final m = MealType.values[i];
                      final sel = m == _meal;
                      return _Press(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _meal = m);
                        },
                        child: AnimatedContainer(
                          duration: _dur(160),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sel ? _P.peachSoft : _P.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? _P.peachDeep : _P.divider,
                              width: sel ? 1.2 : 1,
                            ),
                          ),
                          child: Text(
                            '${m.emoji} ${m.displayName}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w500,
                              color: sel ? _P.peachDeep : _P.textMuted,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),

                // CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _Press(
                    onTap: canAdd ? _add : null,
                    child: Opacity(
                      opacity: canAdd ? 1 : 0.4,
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
                            canAdd
                                ? 'ДОБАВИТЬ · ${grams.round()} Г'
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
          ),
        ),
      ),
    );
  }

  Widget _staticMacroBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: _P.elevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          height: 1,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        )),
                  ),
                  const SizedBox(height: 3),
                  Text(label,
                      style: GoogleFonts.inter(
                        color: _P.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip({
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

  Widget _liveMacroCell(String label, String value, Color color) {
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
                child: Text(value,
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.3,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    )),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.inter(
                color: _P.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }

  Widget _vertDivider() => Container(width: 1, color: _P.divider);

  Widget _grabber() => Container(
    width: 36,
    height: 5,
    decoration: BoxDecoration(
      color: _P.divider,
      borderRadius: BorderRadius.circular(3),
    ),
  );

  String _catName(String c) {
    const m = {
      'meat': 'Мясо', 'fish': 'Рыба', 'dairy': 'Молочное', 'grains': 'Крупы',
      'vegetables': 'Овощи', 'fruits': 'Фрукты', 'nuts': 'Орехи',
      'seeds': 'Семена', 'legumes': 'Бобовые', 'oils': 'Масла',
      'sweets': 'Сладкое', 'drinks': 'Напитки', 'bakery': 'Выпечка',
      'fastfood': 'Фастфуд', 'supplements': 'Добавки', 'sauces': 'Соусы',
      'other': 'Другое',
    };
    return m[c] ?? c;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  9. CUSTOM PRODUCT SHEET
// ═══════════════════════════════════════════════════════════════════
class _CustomProductSheet extends StatefulWidget {
  final NutritionProvider provider;
  final bool reduceMotion;
  const _CustomProductSheet({
    required this.provider,
    required this.reduceMotion,
  });

  @override
  State<_CustomProductSheet> createState() => _CustomProductSheetState();
}

class _CustomProductSheetState extends State<_CustomProductSheet> {
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();

  String _category = 'other';
  String? _nameError;
  String? _calError;
  bool _saving = false;

  static const _cats = [
    'meat', 'fish', 'dairy', 'grains', 'vegetables', 'fruits', 'nuts', 'other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _fatCtrl.dispose();
    _carbCtrl.dispose();
    super.dispose();
  }

  Duration _dur(int ms) =>
      widget.reduceMotion ? Duration.zero : Duration(milliseconds: ms);

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final cal = _num(_calCtrl);
    final nameErr = name.isEmpty ? 'Введите название' : null;
    final calErr = cal <= 0 ? 'Укажите калории' : null;
    if (nameErr != null || calErr != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _nameError = nameErr;
        _calError = calErr;
      });
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      await widget.provider.addCustomProduct(
        name: name,
        category: _category,
        calories: cal,
        protein: _num(_proCtrl),
        fat: _num(_fatCtrl),
        carbs: _num(_carbCtrl),
      );
      if (!mounted) return;
      Navigator.pop(context, name);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cal = _num(_calCtrl);
    final pro = _num(_proCtrl);
    final fat = _num(_fatCtrl);
    final carb = _num(_carbCtrl);
    final canCreate = _nameCtrl.text.trim().isNotEmpty && cal > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _grabber()),
                const SizedBox(height: 16),
                Text('НОВЫЙ ПРОДУКТ',
                    style: _T.overline.copyWith(color: _P.peachDeep)),
                const SizedBox(height: 4),
                Text('Создать', style: _T.title2),
                const SizedBox(height: 20),

                // ОСНОВНОЕ
                Text('ОСНОВНОЕ', style: _T.overline),
                const SizedBox(height: 8),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _P.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _nameError != null ? _P.pinkDeep : _P.divider,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_rounded,
                          size: 16, color: _P.peachDeep),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          onChanged: (_) {
                            if (_nameError != null) {
                              setState(() => _nameError = null);
                            } else {
                              setState(() {});
                            }
                          },
                          style: GoogleFonts.inter(
                            color: _P.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Название продукта',
                            hintStyle: GoogleFonts.inter(
                                color: _P.textMuted, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_nameError != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(_nameError!,
                        style: GoogleFonts.inter(
                          color: _P.pinkDeep,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _cats)
                      _categoryChip(
                        label: _catName(c),
                        selected: _category == c,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _category = c);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 22),

                // НА 100 Г 2×2 grid
                Text('НА 100 Г', style: _T.overline),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _macroField('КАЛОРИИ', 'ккал', _P.peachDeep,
                          _calCtrl, error: _calError),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _macroField('БЕЛКИ', 'г', _P.greenDeep, _proCtrl),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _macroField('ЖИРЫ', 'г', _P.yellowDeep, _fatCtrl),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _macroField('УГЛЕВОДЫ', 'г', _P.pinkDeep, _carbCtrl),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // live preview
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _P.peachSoft.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: _P.peachDeep),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'В 100 г: ${cal.round()} ккал · Б ${pro.round()} · Ж ${fat.round()} · У ${carb.round()}',
                          style: GoogleFonts.inter(
                            color: _P.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFeatures: [ui.FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: _Press(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _P.divider),
                            ),
                            alignment: Alignment.center,
                            child: Text('Отмена',
                                style: GoogleFonts.inter(
                                  color: _P.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: _Press(
                          onTap: canCreate && !_saving ? _save : null,
                          child: Opacity(
                            opacity: canCreate && !_saving ? 1 : 0.5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _P.peachDeep,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _P.peachDeep.withOpacity(0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: _saving
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Text('Создать',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  )),
                            ),
                          ),
                        ),
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

  Widget _categoryChip({
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
          color: selected ? _P.peachSoft : _P.bg,
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
          ),
        ),
      ),
    );
  }

  Widget _macroField(
      String label,
      String unit,
      Color color,
      TextEditingController ctrl, {
        String? error,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _T.overline),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: _P.elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null ? _P.pinkDeep : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _P.text,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: '0',
                    hintStyle: GoogleFonts.inter(
                        color: _P.textMuted, fontSize: 13),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(unit,
                    style: GoogleFonts.inter(
                      color: _P.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    )),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error,
              style: GoogleFonts.inter(
                color: _P.pinkDeep,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
        ],
      ],
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

  String _catName(String c) {
    const m = {
      'meat': 'Мясо', 'fish': 'Рыба', 'dairy': 'Молочное', 'grains': 'Крупы',
      'vegetables': 'Овощи', 'fruits': 'Фрукты', 'nuts': 'Орехи', 'other': 'Другое',
    };
    return m[c] ?? c;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  14. SHIMMER placeholder
// ═══════════════════════════════════════════════════════════════════
class _ShimmerBox extends StatefulWidget {
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final x = _ctrl.value * 2 - 1;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(x - 0.6, 0),
              end: Alignment(x + 0.6, 0),
              colors: [_P.elevated, _P.divider, _P.elevated],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  11. _Press — scale-on-tap wrapper
// ═══════════════════════════════════════════════════════════════════
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const _Press({super.key, required this.child, this.onTap, this.onLongPress});

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
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) return child;
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}