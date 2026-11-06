// features/nutrition/ui/screens/add_food_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';

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
  final _gramsCtrl  = TextEditingController(text: '100');

  String _query = '';
  String? _selectedCategory;
  FoodProduct? _selectedProduct;
  late MealType _selectedMeal;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.initialMeal ?? MealType.suggestForNow();
    if (widget.preselectedProduct != null) {
      _selectedProduct = widget.preselectedProduct;
      _query = widget.preselectedProduct!.name;
      _searchCtrl.text = widget.preselectedProduct!.name;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.nutritionProvider;

    final base = _query.trim().isEmpty
        ? provider.products
        : provider.searchProducts(_query);
    final filtered = _selectedCategory == null
        ? base
        : base.where((p) => p.category == _selectedCategory).toList();
    final showQuick = _query.trim().isEmpty && _selectedCategory == null;

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16, 8, 16,
                  _selectedProduct == null ? 24 : 130,
                ),
                children: [
                  _searchField(),
                  const SizedBox(height: 14),
                  _categories(),
                  const SizedBox(height: 14),
                  _mealSelector(),
                  const SizedBox(height: 18),
                  if (showQuick)
                    ..._quickSections(provider)
                  else
                    _resultsHeader(filtered.length),
                  if (filtered.isEmpty)
                    _empty()
                  else
                    ...filtered.map((p) => _productCard(provider, p)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _selectedProduct == null ? null : _bottomSummary(provider),
    );
  }

  // ── Header ──
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _P.surface, shape: BoxShape.circle,
                border: Border.all(color: _P.divider, width: 1),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: _P.text, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ДОБАВИТЬ', style: _T.overline.copyWith(color: _P.peachDeep, fontSize: 9)),
                const SizedBox(height: 2),
                Text('Продукт', style: _T.title2.copyWith(fontSize: 22)),
              ],
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _P.peachSoft, borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _P.peachDeep.withOpacity(0.15), width: 0.8),
            ),
            child: const Icon(Icons.restaurant_rounded, color: _P.peachDeep, size: 19),
          ),
        ],
      ),
    );
  }

  // ── Search ──
  Widget _searchField() {
    return Container(
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
              autofocus: widget.preselectedProduct == null,
              onChanged: (v) {
                setState(() { _query = v; _selectedProduct = null; });
              },
              style: GoogleFonts.inter(
                color: _P.text, fontSize: 14, fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Найти продукт…',
                hintStyle: GoogleFonts.inter(color: _P.textMuted, fontSize: 14),
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _searchCtrl.clear();
                setState(() { _query = ''; _selectedProduct = null; });
              },
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.close_rounded, color: _P.textMuted, size: 18),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Categories ──
  Widget _categories() {
    const cats = ['meat', 'fish', 'dairy', 'grains', 'vegetables', 'fruits', 'nuts', 'legumes', 'drinks'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            children: [
              Text('КАТЕГОРИИ', style: _T.overline.copyWith(color: _P.textMuted, fontSize: 9)),
              const Spacer(),
              if (_selectedCategory != null)
                GestureDetector(
                  onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = null); },
                  child: Text('СБРОСИТЬ', style: GoogleFonts.inter(
                    color: _P.peachDeep, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5,
                  )),
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
              _catChip('Все', null),
              ...cats.map((c) => _catChip(_catName(c), c)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _catChip(String label, String? cat) {
    final selected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() { _selectedCategory = cat; _selectedProduct = null; });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
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
          child: Text(label, style: GoogleFonts.inter(
            color: selected ? _P.peachDeep : _P.textMuted,
            fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: -0.1,
          )),
        ),
      ),
    );
  }

  // ── Meal selector ──
  Widget _mealSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: _P.peachSoft, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.restaurant_menu_rounded, color: _P.peachDeep, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ПРИЁМ ПИЩИ', style: GoogleFonts.inter(
                      color: _P.text, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0,
                    )),
                    const SizedBox(height: 1),
                    Text('Куда добавить продукт', style: _T.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _P.peachSoft, borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedMeal.emoji} ${_selectedMeal.displayName}',
                  style: GoogleFonts.inter(
                    color: _P.peachDeep, fontSize: 11, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: MealType.values.map((m) {
                final selected = _selectedMeal == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMeal = m);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? _P.peachSoft : _P.bg,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: selected ? _P.peachDeep : _P.divider,
                          width: selected ? 1.2 : 0.8,
                        ),
                      ),
                      child: Text('${m.emoji} ${m.displayName}', style: GoogleFonts.inter(
                        color: selected ? _P.peachDeep : _P.textMuted,
                        fontSize: 11.5, fontWeight: FontWeight.w600,
                      )),
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

  // ── Quick sections ──
  List<Widget> _quickSections(NutritionProvider provider) {
    final recent = provider.getRecentProducts(limit: 8);
    final favs = provider.favoriteProducts.take(8).toList();
    final widgets = <Widget>[];

    if (recent.isNotEmpty) {
      widgets.add(_sectionTitle('⚡', 'НЕДАВНИЕ', 'Добавляй быстрым доступом', _P.yellowDeep));
      widgets.add(const SizedBox(height: 10));
      widgets.add(_horizontalProducts(provider, recent));
      widgets.add(const SizedBox(height: 18));
    }
    if (favs.isNotEmpty) {
      widgets.add(_sectionTitle('⭐', 'ИЗБРАННОЕ', 'Твои любимые продукты', _P.pinkDeep));
      widgets.add(const SizedBox(height: 10));
      widgets.add(_horizontalProducts(provider, favs));
      widgets.add(const SizedBox(height: 18));
    }
    widgets.add(_sectionTitle('📚', 'ВСЕ ПРОДУКТЫ', 'Выбери из базы', _P.peachDeep));
    widgets.add(const SizedBox(height: 10));
    return widgets;
  }

  Widget _sectionTitle(String emoji, String title, String sub, Color color) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.20), width: 0.6),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(
                color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0,
              )),
              const SizedBox(height: 2),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: _T.caption.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _horizontalProducts(NutritionProvider provider, List<FoodProduct> items) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = items[i];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedProduct = p;
                _query = p.name;
                _searchCtrl.text = p.name;
                _selectedCategory = null;
              });
            },
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _P.divider, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _P.bg, borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(p.categoryEmoji, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 8),
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _P.text, fontSize: 12, fontWeight: FontWeight.w600, height: 1.25,
                      )),
                  const Spacer(),
                  Text('${p.calories.round()} ккал', style: GoogleFonts.inter(
                    color: _P.peachDeep, fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _resultsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Row(
        children: [
          Text(_query.isNotEmpty ? 'РЕЗУЛЬТАТЫ ПОИСКА' : 'ПРОДУКТЫ',
              style: _T.overline.copyWith(color: _P.textMuted, fontSize: 9)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _P.peachSoft, borderRadius: BorderRadius.circular(7)),
            child: Text('$count', style: GoogleFonts.inter(
              color: _P.peachDeep, fontSize: 11, fontWeight: FontWeight.w600,
            )),
          ),
        ],
      ),
    );
  }

  // ── Product card ──
  Widget _productCard(NutritionProvider provider, FoodProduct p) {
    final selected = _selectedProduct?.id == p.id;
    final grams = double.tryParse(_gramsCtrl.text) ?? 100;
    final macros = p.forGrams(grams);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? _P.peachDeep.withOpacity(0.5) : _P.divider,
          width: selected ? 1.4 : 1,
        ),
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
                  _selectedProduct = p;
                  _gramsCtrl.text = '100';
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: selected ? _P.peachSoft : _P.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(p.categoryEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: _P.text, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.2,
                            )),
                        const SizedBox(height: 3),
                        Text(p.categoryName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.4,
                            )),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); provider.toggleFavorite(p.id); setState(() {}); },
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.isFavorite ? _P.yellowSoft : Colors.transparent,
                      ),
                      child: Icon(
                        p.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: p.isFavorite ? _P.yellowDeep : _P.textMuted,
                        size: 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    selected ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: selected ? _P.peachDeep : _P.textMuted,
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
                _pill('🔥', '${p.calories.round()}', _P.peachDeep),
                const SizedBox(width: 5),
                _pill('Б', p.protein.toStringAsFixed(1), _P.greenDeep),
                const SizedBox(width: 5),
                _pill('Ж', p.fat.toStringAsFixed(1), _P.yellowDeep),
                const SizedBox(width: 5),
                _pill('У', p.carbs.toStringAsFixed(1), _P.pinkDeep),
              ],
            ),
          ),
          if (selected) _expandedEditor(provider, p, grams, macros),
        ],
      ),
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600, height: 1)),
            const SizedBox(width: 3),
            Flexible(
              child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandedEditor(NutritionProvider provider, FoodProduct p, double grams, dynamic macros) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: const BoxDecoration(
        color: _P.bg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(17)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('КОЛИЧЕСТВО', style: _T.overline.copyWith(color: _P.textMuted, fontSize: 9)),
                    const SizedBox(height: 3),
                    Text('Укажи вес продукта', style: _T.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Container(
                width: 110, height: 46,
                decoration: BoxDecoration(
                  color: _P.surface, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _P.peachDeep.withOpacity(0.35), width: 1.2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gramsCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: _P.text, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.5,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text('г', style: GoogleFonts.inter(
                        color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w600,
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [50, 100, 150, 200, 250].map((v) {
              final sel = grams.round() == v;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _gramsCtrl.text = '$v');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 36, alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? _P.peachSoft : _P.surface,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: sel ? _P.peachDeep : _P.divider,
                          width: sel ? 1.1 : 0.8,
                        ),
                      ),
                      child: Text('$v', style: GoogleFonts.inter(
                        color: sel ? _P.peachDeep : _P.textMuted,
                        fontSize: 11.5, fontWeight: FontWeight.w600,
                      )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: _P.surface, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _P.divider, width: 0.6),
            ),
            child: Row(
              children: [
                _expandedMacro('🔥', '${macros.calories.round()}', 'ККАЛ', _P.peachDeep),
                _vDiv(),
                _expandedMacro('Б', macros.protein.toStringAsFixed(1), 'Г', _P.greenDeep),
                _vDiv(),
                _expandedMacro('Ж', macros.fat.toStringAsFixed(1), 'Г', _P.yellowDeep),
                _vDiv(),
                _expandedMacro('У', macros.carbs.toStringAsFixed(1), 'Г', _P.pinkDeep),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _addProduct(provider, p, grams);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _P.peachDeep, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('ДОБАВИТЬ · ${grams.round()} Г', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDiv() => Container(
    width: 1, height: 28, color: _P.divider, margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  Widget _expandedMacro(String label, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, height: 1)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1,
          )),
          const SizedBox(height: 3),
          Text(unit, style: GoogleFonts.inter(
            color: _P.textMuted, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5,
          )),
        ],
      ),
    );
  }

  // ── Bottom summary ──
  Widget _bottomSummary(NutritionProvider provider) {
    final p = _selectedProduct;
    if (p == null) return const SizedBox.shrink();
    final grams = double.tryParse(_gramsCtrl.text) ?? 100;
    final macros = p.forGrams(grams);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: _P.surface,
          border: Border(top: BorderSide(color: _P.divider, width: 1)),
          boxShadow: [BoxShadow(
            color: _P.peachDeep.withOpacity(0.12),
            blurRadius: 24, offset: const Offset(0, -8),
          )],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _P.peachSoft, borderRadius: BorderRadius.circular(12),
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
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: _P.text, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.1,
                        )),
                    const SizedBox(height: 2),
                    Text('${grams.round()} г · ${macros.calories.round()} ккал',
                        style: GoogleFonts.inter(
                          color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _addProduct(provider, p, grams);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _P.peachDeep, foregroundColor: Colors.white, elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.add_rounded, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty ──
  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.only(top: 55),
      child: Column(
        children: [
          Container(
            width: 76, height: 76,
            decoration: const BoxDecoration(color: _P.peachSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('🔍', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 16),
          Text('Ничего не найдено', style: _T.headline.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text('Попробуй другой запрос', style: _T.body.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  // ── Add product ──
  Future<void> _addProduct(NutritionProvider provider, FoodProduct product, double grams) async {
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

  // ── Helpers ──
  String _catName(String c) {
    const m = {
      'meat': '🥩 Мясо', 'fish': '🐟 Рыба', 'dairy': '🥛 Молочка',
      'grains': '🌾 Крупы', 'vegetables': '🥬 Овощи', 'fruits': '🍎 Фрукты',
      'nuts': '🥜 Орехи', 'legumes': '🫘 Бобовые', 'drinks': '☕ Напитки',
    };
    return m[c] ?? c;
  }
}