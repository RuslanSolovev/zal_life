// features/nutrition/ui/screens/food_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import 'add_food_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  Premium Design System
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const bg         = Color(0xFFF6F7F9);
  static const surface    = Color(0xFFFFFFFF);
  static const text       = Color(0xFF1C2026);
  static const textMuted  = Color(0xFF7C818A);
  static const divider    = Color(0xFFE9EBEF);
  static const elevated   = Color(0xFFF0F1F4);

  static const peachSoft    = Color(0xFFFBEDE4);
  static const peachDeep    = Color(0xFFEF9563);
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF9381BB);
  static const greenSoft    = Color(0xFFE7F2ED);
  static const greenDeep    = Color(0xFF6C9E88);
  static const skySoft      = Color(0xFFE8EFF8);
  static const skyDeep      = Color(0xFF7E9DC6);
  static const yellowSoft   = Color(0xFFFDF5E6);
  static const yellowDeep   = Color(0xFFE0B054);
  static const pinkSoft     = Color(0xFFFCF0F2);
  static const pinkDeep     = Color(0xFFD17A8F);
}

class _T {
  static final title1   = GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: _P.text);
  static final title2   = GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: _P.text);
  static final headline = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _P.text);
  static final body     = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: _P.textMuted);
  static final caption  = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
  static final overline = GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _P.textMuted);
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
  late final TextEditingController _searchCtrl;
  String _query = '';
  String? _selectedCategory;
  bool _favoritesOnly = false;
  FoodSortMode _sortMode = FoodSortMode.name;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() {
      if (!mounted) return;
      setState(() => _query = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final products = _filtered(provider);
    final categories = _categories(provider.products);

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(provider),
            _searchField(),
            const SizedBox(height: 12),
            _filters(categories),
            const SizedBox(height: 10),
            _countRow(products.length),
            Expanded(
              child: products.isEmpty
                  ? _empty()
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                itemCount: products.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _productRow(products[i], provider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _header(NutritionProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _iconBtn(Icons.chevron_left_rounded, () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          }),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ПРОДУКТЫ', style: _T.overline.copyWith(color: _P.peachDeep, fontSize: 9)),
                const SizedBox(height: 2),
                Text('База', style: _T.title2.copyWith(fontSize: 22)),
              ],
            ),
          ),
          _sortBtn(),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () { HapticFeedback.mediumImpact(); _customProductDialog(provider); },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _P.peachDeep, shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: _P.peachDeep.withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 4),
                )],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _P.surface, shape: BoxShape.circle,
          border: Border.all(color: _P.divider, width: 1),
        ),
        child: Icon(icon, color: _P.text, size: 20),
      ),
    );
  }

  Widget _sortBtn() {
    return PopupMenuButton<FoodSortMode>(
      tooltip: 'Сортировка',
      offset: const Offset(0, 46),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) { HapticFeedback.selectionClick(); setState(() => _sortMode = v); },
      itemBuilder: (_) => [
        _sortItem(FoodSortMode.name,         'По названию',     Icons.sort_by_alpha_rounded),
        _sortItem(FoodSortMode.caloriesAsc,  'Меньше калорий',  Icons.south_rounded),
        _sortItem(FoodSortMode.caloriesDesc, 'Больше калорий',  Icons.north_rounded),
        _sortItem(FoodSortMode.proteinDesc,  'Больше белка',    Icons.fitness_center_rounded),
      ],
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _P.surface, shape: BoxShape.circle,
          border: Border.all(color: _P.divider, width: 1),
        ),
        child: const Icon(Icons.tune_rounded, color: _P.text, size: 18),
      ),
    );
  }

  PopupMenuItem<FoodSortMode> _sortItem(FoodSortMode mode, String title, IconData icon) {
    final selected = _sortMode == mode;
    return PopupMenuItem<FoodSortMode>(
      value: mode,
      child: Row(
        children: [
          Icon(icon, color: selected ? _P.peachDeep : _P.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(
              color: selected ? _P.peachDeep : _P.text,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
          ),
          if (selected) const Icon(Icons.check_rounded, color: _P.peachDeep, size: 16),
        ],
      ),
    );
  }

  // ── Search ──
  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.divider, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: _P.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.inter(
                  color: _P.text, fontSize: 14, fontWeight: FontWeight.w500,
                ),
                cursorColor: _P.peachDeep,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Найти продукт…',
                  hintStyle: GoogleFonts.inter(
                    color: _P.textMuted, fontSize: 14,
                  ),
                  contentPadding: EdgeInsets.zero, isDense: true,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); _searchCtrl.clear(); },
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.close_rounded, color: _P.textMuted, size: 18),
                ),
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  // ── Filters ──
  Widget _filters(List<String> categories) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip('ВСЕ', Icons.grid_view_rounded,
              selected: _selectedCategory == null && !_favoritesOnly,
              onTap: () { HapticFeedback.selectionClick(); setState(() { _selectedCategory = null; _favoritesOnly = false; }); }),
          const SizedBox(width: 8),
          _chip('ИЗБРАННОЕ', Icons.favorite_rounded,
              accent: _P.pinkDeep,
              selected: _favoritesOnly,
              onTap: () { HapticFeedback.selectionClick(); setState(() { _favoritesOnly = !_favoritesOnly; if (_favoritesOnly) _selectedCategory = null; }); }),
          ...categories.map((c) {
            final selected = _selectedCategory == c;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _chip(_catName(c).toUpperCase(), _catIcon(c),
                  selected: selected,
                  onTap: () { HapticFeedback.selectionClick(); setState(() { _selectedCategory = selected ? null : c; _favoritesOnly = false; }); }),
            );
          }),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _chip(String title, IconData icon, {required bool selected, required VoidCallback onTap, Color? accent}) {
    final c = accent ?? _P.peachDeep;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.10) : _P.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c : _P.divider,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? c : _P.textMuted),
            const SizedBox(width: 6),
            Text(title, style: GoogleFonts.inter(
              color: selected ? c : _P.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            )),
          ],
        ),
      ),
    );
  }

  // ── Count row ──
  Widget _countRow(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
      child: Row(
        children: [
          Text(
            _query.isNotEmpty ? 'РЕЗУЛЬТАТЫ'
                : _favoritesOnly ? 'ИЗБРАННОЕ'
                : _selectedCategory != null ? _catName(_selectedCategory!).toUpperCase()
                : 'ВСЕ ПРОДУКТЫ',
            style: _T.overline.copyWith(color: _P.textMuted, fontSize: 9),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _P.peachSoft, borderRadius: BorderRadius.circular(7),
            ),
            child: Text('$count', style: GoogleFonts.inter(
              color: _P.peachDeep, fontSize: 11, fontWeight: FontWeight.w600,
            )),
          ),
        ],
      ),
    );
  }

  // ── Product row ──
  Widget _productRow(FoodProduct p, NutritionProvider provider) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); _productSheet(p, provider); },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.divider, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: _P.peachSoft, borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                p.categoryEmoji.isNotEmpty ? p.categoryEmoji : '🍽️',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: _P.text, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2,
                            )),
                      ),
                      if (p.isCustom) ...[
                        const SizedBox(width: 6),
                        _badge('МОЙ', _P.lavenderDeep),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _pill('🔥', '${p.calories.round()}', _P.peachDeep),
                      const SizedBox(width: 5),
                      _pill('Б', p.protein.round().toString(), _P.greenDeep),
                      const SizedBox(width: 5),
                      _pill('Ж', p.fat.round().toString(), _P.yellowDeep),
                      const SizedBox(width: 5),
                      _pill('У', p.carbs.round().toString(), _P.pinkDeep),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); provider.toggleFavorite(p.id); },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.isFavorite ? _P.pinkSoft : Colors.transparent,
                ),
                child: Icon(
                  p.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: p.isFavorite ? _P.pinkDeep : _P.textMuted,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600, height: 1)),
          const SizedBox(width: 3),
          Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1)),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text, style: TextStyle(
        color: color, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.6, height: 1,
      )),
    );
  }

  // ── Empty ──
  Widget _empty() {
    String title = 'Ничего не найдено';
    String sub = 'Попробуй изменить поиск';
    IconData icon = Icons.search_off_rounded;

    if (_favoritesOnly) {
      title = 'Избранное пусто'; sub = 'Добавляй продукты в избранное'; icon = Icons.favorite_border_rounded;
    } else if (_query.isEmpty && _selectedCategory != null) {
      title = 'Нет продуктов'; sub = 'В этой категории пока ничего нет'; icon = Icons.inventory_2_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84, height: 84,
              decoration: const BoxDecoration(color: _P.peachSoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, color: _P.peachDeep, size: 36),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: _T.headline.copyWith(fontSize: 17)),
            const SizedBox(height: 6),
            Text(sub, textAlign: TextAlign.center, style: _T.body.copyWith(fontSize: 13)),
            if (_query.isNotEmpty || _selectedCategory != null || _favoritesOnly) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() { _query = ''; _selectedCategory = null; _favoritesOnly = false; });
                  _searchCtrl.clear();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _P.peachSoft, borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('СБРОСИТЬ ФИЛЬТРЫ', style: GoogleFonts.inter(
                    color: _P.peachDeep, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
                  )),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Product sheet ──
  void _productSheet(FoodProduct p, NutritionProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 36, height: 5,
                  decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3)),
                )),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 58, height: 58,
                      decoration: BoxDecoration(
                        color: _P.peachSoft, borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(p.categoryEmoji.isNotEmpty ? p.categoryEmoji : '🍽️',
                          style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: _T.title2.copyWith(fontSize: 19)),
                          const SizedBox(height: 3),
                          Text(_catName(p.category).toUpperCase(),
                              style: _T.overline.copyWith(fontSize: 9, color: _P.textMuted)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider.toggleFavorite(p.id);
                        Navigator.pop(sheetCtx);
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.isFavorite ? _P.pinkSoft : _P.bg,
                        ),
                        child: Icon(
                          p.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: p.isFavorite ? _P.pinkDeep : _P.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('НА 100 Г', style: _T.overline.copyWith(color: _P.textMuted, fontSize: 9)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _macroBox('ККАЛ', '${p.calories.round()}', _P.peachDeep, Icons.local_fire_department_rounded),
                    const SizedBox(width: 8),
                    _macroBox('БЕЛОК', p.protein.toStringAsFixed(1), _P.greenDeep, Icons.fitness_center_rounded),
                    const SizedBox(width: 8),
                    _macroBox('ЖИРЫ', p.fat.toStringAsFixed(1), _P.yellowDeep, Icons.water_drop_rounded),
                    const SizedBox(width: 8),
                    _macroBox('УГЛЕВ.', p.carbs.toStringAsFixed(1), _P.pinkDeep, Icons.grain_rounded),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(sheetCtx);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddFoodScreen(
                          isDark: false,
                          date: DateTime.now(),
                          preselectedProduct: p,
                          nutritionProvider: provider,
                        ),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _P.peachDeep, foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('ДОБАВИТЬ В ДНЕВНИК', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.8,
                    )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _macroBox(String title, String value, Color accent, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.15), width: 0.8),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 16),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: GoogleFonts.inter(
                color: _P.text, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.4,
              )),
            ),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(
              color: accent, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.6, height: 1,
            )),
          ],
        ),
      ),
    );
  }

  // ── Custom product dialog ──
  Future<void> _customProductDialog(NutritionProvider provider) async {
    final name = TextEditingController();
    final cal  = TextEditingController();
    final pro  = TextEditingController();
    final fat  = TextEditingController();
    final carb = TextEditingController();
    String category = 'other';

    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (sheetCtx, setSheetState) => Container(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 12,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(
                      width: 36, height: 5,
                      decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3)),
                    )),
                    const SizedBox(height: 20),
                    Text('НОВЫЙ ПРОДУКТ', style: _T.overline.copyWith(color: _P.peachDeep, fontSize: 9)),
                    const SizedBox(height: 4),
                    Text('Создать', style: _T.title2),
                    const SizedBox(height: 18),
                    _field('НАЗВАНИЕ', name, Icons.edit_rounded, _P.peachDeep, keyboard: TextInputType.text),
                    const SizedBox(height: 10),
                    _field('КАЛОРИИ НА 100 Г', cal, Icons.local_fire_department_rounded, _P.peachDeep),
                    const SizedBox(height: 10),
                    _field('БЕЛКИ, Г', pro, Icons.fitness_center_rounded, _P.greenDeep),
                    const SizedBox(height: 10),
                    _field('ЖИРЫ, Г', fat, Icons.water_drop_rounded, _P.yellowDeep),
                    const SizedBox(height: 10),
                    _field('УГЛЕВОДЫ, Г', carb, Icons.grain_rounded, _P.pinkDeep),
                    const SizedBox(height: 14),
                    _categoryDropdown(category, (v) { HapticFeedback.selectionClick(); setSheetState(() => category = v); }),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(sheetCtx); },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _P.text,
                                side: const BorderSide(color: _P.divider, width: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Отмена', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                final n = name.text.trim();
                                final c = double.tryParse(cal.text.replaceAll(',', '.')) ?? 0;
                                final p = double.tryParse(pro.text.replaceAll(',', '.')) ?? 0;
                                final f = double.tryParse(fat.text.replaceAll(',', '.')) ?? 0;
                                final cb = double.tryParse(carb.text.replaceAll(',', '.')) ?? 0;
                                if (n.isEmpty) { _snack('Введите название'); return; }
                                if (c <= 0) { _snack('Укажите калории'); return; }
                                HapticFeedback.mediumImpact();
                                await provider.addCustomProduct(
                                  name: n, category: category,
                                  calories: c, protein: p, fat: f, carbs: cb,
                                );
                                if (!sheetCtx.mounted) return;
                                Navigator.pop(sheetCtx);
                                if (!mounted) return;
                                _snack('Продукт добавлен');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _P.peachDeep, foregroundColor: Colors.white, elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('СОХРАНИТЬ', style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.8,
                              )),
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
        ),
      );
    } finally {
      name.dispose(); cal.dispose(); pro.dispose(); fat.dispose(); carb.dispose();
    }
  }

  Widget _field(String label, TextEditingController c, IconData icon, Color accent, {TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(label, style: _T.overline.copyWith(color: _P.textMuted, fontSize: 9)),
        ),
        TextField(
          controller: c,
          keyboardType: keyboard ?? const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(color: _P.text, fontSize: 14, fontWeight: FontWeight.w500),
          cursorColor: accent,
          decoration: InputDecoration(
            hintText: label.toLowerCase(),
            hintStyle: GoogleFonts.inter(color: _P.textMuted, fontSize: 14),
            filled: true, fillColor: _P.bg,
            prefixIcon: Icon(icon, color: accent, size: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _P.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _categoryDropdown(String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text('КАТЕГОРИЯ', style: _T.overline.copyWith(color: _P.textMuted, fontSize: 9)),
        ),
        Container(
          decoration: BoxDecoration(
            color: _P.bg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _P.divider, width: 1),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            dropdownColor: Colors.white,
            iconEnabledColor: _P.textMuted,
            style: GoogleFonts.inter(color: _P.text, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            items: const [
              DropdownMenuItem(value: 'other',      child: Text('Другое')),
              DropdownMenuItem(value: 'meat',       child: Text('Мясо')),
              DropdownMenuItem(value: 'fish',       child: Text('Рыба')),
              DropdownMenuItem(value: 'dairy',      child: Text('Молочное')),
              DropdownMenuItem(value: 'grains',     child: Text('Крупы')),
              DropdownMenuItem(value: 'vegetables', child: Text('Овощи')),
              DropdownMenuItem(value: 'fruits',     child: Text('Фрукты')),
              DropdownMenuItem(value: 'nuts',       child: Text('Орехи')),
              DropdownMenuItem(value: 'sweets',     child: Text('Сладкое')),
              DropdownMenuItem(value: 'drinks',     child: Text('Напитки')),
            ],
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      ],
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _P.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
  }

  // ── Filtering & helpers ──
  List<FoodProduct> _filtered(NutritionProvider provider) {
    List<FoodProduct> r = _query.isEmpty
        ? List<FoodProduct>.from(provider.products)
        : List<FoodProduct>.from(provider.searchProducts(_query));
    if (_favoritesOnly) r = r.where((p) => p.isFavorite).toList();
    if (_selectedCategory != null) r = r.where((p) => p.category == _selectedCategory).toList();
    switch (_sortMode) {
      case FoodSortMode.name:         r.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); break;
      case FoodSortMode.caloriesAsc:  r.sort((a, b) => a.calories.compareTo(b.calories)); break;
      case FoodSortMode.caloriesDesc: r.sort((a, b) => b.calories.compareTo(a.calories)); break;
      case FoodSortMode.proteinDesc:  r.sort((a, b) => b.protein.compareTo(a.protein)); break;
    }
    return r;
  }

  List<String> _categories(List<FoodProduct> products) {
    final cats = products.map((p) => p.category).where((c) => c.isNotEmpty).toSet().toList();
    cats.sort((a, b) => _catName(a).compareTo(_catName(b)));
    return cats;
  }

  String _catName(String c) {
    const m = {
      'meat': 'Мясо', 'fish': 'Рыба', 'dairy': 'Молочное', 'grains': 'Крупы',
      'vegetables': 'Овощи', 'fruits': 'Фрукты', 'nuts': 'Орехи', 'seeds': 'Семена',
      'legumes': 'Бобовые', 'oils': 'Масла', 'sweets': 'Сладкое', 'drinks': 'Напитки',
      'bakery': 'Выпечка', 'fastfood': 'Фастфуд', 'supplements': 'Добавки',
      'sauces': 'Соусы', 'other': 'Другое',
    };
    return m[c] ?? c;
  }

  IconData _catIcon(String c) {
    switch (c) {
      case 'meat': return Icons.restaurant_rounded;
      case 'fish': return Icons.set_meal_rounded;
      case 'dairy': return Icons.local_drink_rounded;
      case 'grains': return Icons.grain_rounded;
      case 'vegetables': return Icons.eco_rounded;
      case 'fruits': return Icons.apple_rounded;
      case 'nuts': return Icons.energy_savings_leaf_rounded;
      case 'seeds': return Icons.grass_rounded;
      case 'legumes': return Icons.scatter_plot_rounded;
      case 'oils': return Icons.opacity_rounded;
      case 'sweets': return Icons.cake_rounded;
      case 'drinks': return Icons.local_bar_rounded;
      case 'bakery': return Icons.bakery_dining_rounded;
      case 'fastfood': return Icons.fastfood_rounded;
      case 'supplements': return Icons.medication_rounded;
      case 'sauces': return Icons.water_drop_rounded;
      default: return Icons.lunch_dining_rounded;
    }
  }
}