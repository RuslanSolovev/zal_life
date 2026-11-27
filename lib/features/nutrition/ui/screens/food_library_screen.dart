// features/nutrition/ui/screens/food_library_screen.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/wellness_provider.dart';
import 'food_search_screen.dart';
import 'recipe_editor_screen.dart';

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
  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF6C9E88);
  static const skyDeep = Color(0xFF7E9DC6);
  static const yellowDeep = Color(0xFFE0B054);
  static const pinkSoft = Color(0xFFFCF0F2);
  static const pinkDeep = Color(0xFFD17A8F);
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF9381BB);
}

class _T {
  static final title2 = GoogleFonts.inter(
      fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: _P.text);
  static final headline = GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, color: _P.text);
  static final caption = GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
  static TextStyle get overline => GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _P.textMuted);
}

enum RecipeSortMode { name, caloriesDesc, caloriesAsc, proteinDesc, recent }

// ═══════════════════════════════════════════════════════════════════
//  ОБЪЕДИНЁННЫЙ ЭКРАН: Продукты + Блюда
// ═══════════════════════════════════════════════════════════════════
class FoodLibraryScreen extends StatefulWidget {
  final int initialTab; // 🆕 0 = Продукты, 1 = Блюда
  const FoodLibraryScreen({super.key, this.initialTab = 0});

  @override
  State<FoodLibraryScreen> createState() => _FoodLibraryScreenState();
}

class _FoodLibraryScreenState extends State<FoodLibraryScreen>
    with SingleTickerProviderStateMixin {

  // 🆕 Убрали 'final', чтобы можно было инициализировать в initState
  late TabController _tab;

  @override
  void initState() {
    super.initState();

    // Инициализируем контроллер с нужным начальным индексом
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );

    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose(); // Не забываем освобождать ресурсы контроллера
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildSegment(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                physics: const BouncingScrollPhysics(),
                children: const [
                  FoodSearchContent(),      // вкладка «Продукты»
                  _RecipeLibraryTab(),      // вкладка «Блюда»
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          _Press(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('БАЗА ЗНАНИЙ',
                    style: _T.overline.copyWith(color: _P.peachDeep, fontSize: 9)),
                Text('Продукты и блюда',
                    style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: _P.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Стильный сегмент-контрол с ползунком ──
  Widget _buildSegment() {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _P.elevated,
        borderRadius: BorderRadius.circular(15),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final idx = _tab.index;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: idx == 0 ? 0 : w / 2,
                top: 0,
                bottom: 0,
                width: w / 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: _P.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _segBtn('Продукты', 0, Icons.apple_rounded),
                  _segBtn('Блюда', 1, Icons.restaurant_menu_rounded),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _segBtn(String label, int index, IconData icon) {
    final selected = _tab.index == index;
    return Expanded(
      child: _Press(
        onTap: () {
          HapticFeedback.selectionClick();
          _tab.animateTo(index);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: selected ? _P.peachSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon,
                  size: 15,
                  color: selected ? _P.peachDeep : _P.textMuted),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? _P.text : _P.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ВКЛАДКА «БЛЮДА»
// ═══════════════════════════════════════════════════════════════════
class _RecipeLibraryTab extends StatefulWidget {
  const _RecipeLibraryTab();
  @override
  State<_RecipeLibraryTab> createState() => _RecipeLibraryTabState();
}

class _RecipeLibraryTabState extends State<_RecipeLibraryTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  RecipeSortMode _sort = RecipeSortMode.recent;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ({double cal, double pro, double fat, double carb}) _macros(
      NutritionProvider provider, MealTemplate t) {
    if (t.calories > 0 || t.protein > 0) {
      return (cal: t.calories, pro: t.protein, fat: t.fat, carb: t.carbs);
    }
    double cal = 0, pro = 0, fat = 0, carb = 0;
    for (final it in t.items) {
      final p = provider.products.where((x) => x.id == it.productId).firstOrNull;
      if (p == null) continue;
      final m = p.forGrams(it.grams);
      cal += m.calories;
      pro += m.protein;
      fat += m.fat;
      carb += m.carbs;
    }
    return (cal: cal, pro: pro, fat: fat, carb: carb);
  }

  List<MealTemplate> _filtered(NutritionProvider provider) {
    var list = List<MealTemplate>.from(provider.templates);
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((t) =>
      t.name.toLowerCase().contains(q) ||
          t.items.any((i) => i.name.toLowerCase().contains(q)))
          .toList();
    }
    switch (_sort) {
      case RecipeSortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case RecipeSortMode.caloriesDesc:
        list.sort((a, b) =>
            _macros(provider, b).cal.compareTo(_macros(provider, a).cal));
        break;
      case RecipeSortMode.caloriesAsc:
        list.sort((a, b) =>
            _macros(provider, a).cal.compareTo(_macros(provider, b).cal));
        break;
      case RecipeSortMode.proteinDesc:
        list.sort((a, b) =>
            _macros(provider, b).pro.compareTo(_macros(provider, a).pro));
        break;
      case RecipeSortMode.recent:
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final list = _filtered(provider);

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildSearch()),
            SliverToBoxAdapter(child: _buildSortRow(list.length)),
            if (list.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) => _recipeCard(provider, list[i]),
                  childCount: list.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildCreateBar(provider),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.divider),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
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
                onChanged: (v) => setState(() => _query = v),
                style: GoogleFonts.inter(
                    color: _P.text, fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Найти блюдо или ингредиент…',
                  hintStyle:
                  GoogleFonts.inter(color: _P.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              _Press(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child:
                  Icon(Icons.close_rounded, size: 18, color: _P.textMuted),
                ),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSortRow(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Text('${count} ${_dishesWord(count)}',
              style: GoogleFonts.inter(
                  color: _P.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [ui.FontFeature.tabularFigures()])),
          const Spacer(),
          _Press(
            onTap: _showSortSheet,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _P.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded,
                      size: 14, color: _P.peachDeep),
                  const SizedBox(width: 6),
                  Text(_sortLabel(_sort),
                      style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(RecipeSortMode m) {
    switch (m) {
      case RecipeSortMode.name:
        return 'По названию';
      case RecipeSortMode.caloriesDesc:
        return 'Калории ↓';
      case RecipeSortMode.caloriesAsc:
        return 'Калории ↑';
      case RecipeSortMode.proteinDesc:
        return 'Белок ↓';
      case RecipeSortMode.recent:
        return 'Недавние';
    }
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                      color: _P.divider,
                      borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Сортировка', style: _T.title2),
              const SizedBox(height: 8),
              ...RecipeSortMode.values.map((m) {
                final selected = _sort == m;
                return _Press(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _sort = m);
                  },
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: selected ? _P.peachDeep : _P.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(_sortLabel(m),
                            style: GoogleFonts.inter(
                                color: _P.text,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recipeCard(NutritionProvider provider, MealTemplate t) {
    final m = _macros(provider, t);
    final perPortion = t.portions > 0 ? m.cal / t.portions : m.cal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: _Press(
        onTap: () => _showRecipeDetail(t),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _P.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _P.peachSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('🍱', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: _P.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2)),
                    if ((t.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(t.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: _P.textMuted, fontSize: 12)),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _metaChip('${m.cal.round()} ккал', _P.peachDeep),
                        _metaChip('Б ${m.pro.round()}', _P.greenDeep),
                        _metaChip('${t.items.length} инг.', _P.skyDeep),
                        if (t.totalTimeMin != null)
                          _metaChip('${t.totalTimeMin} мин', _P.yellowDeep),
                        _metaChip(t.difficulty.emoji, null),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${perPortion.round()}',
                      style: GoogleFonts.inter(
                          color: _P.peachDeep,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [ui.FontFeature.tabularFigures()])),
                  Text('ккал/порц',
                      style: GoogleFonts.inter(
                          color: _P.textMuted, fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(String label, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? _P.textMuted).withOpacity(0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              color: color ?? _P.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFeatures: const [ui.FontFeature.tabularFigures()])),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
                color: _P.peachSoft, shape: BoxShape.circle),
            child: const Icon(Icons.restaurant_menu_rounded,
                size: 34, color: _P.peachDeep),
          ),
          const SizedBox(height: 16),
          Text(_query.isEmpty ? 'Пока нет блюд' : 'Ничего не найдено',
              textAlign: TextAlign.center, style: _T.headline),
          const SizedBox(height: 4),
          Text(
              _query.isEmpty
                  ? 'Создай первое блюдо — оно появится здесь'
                  : 'Попробуй другое слово',
              textAlign: TextAlign.center,
              style: _T.caption),
        ],
      ),
    );
  }

  Widget _buildCreateBar(NutritionProvider provider) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: _P.surface.withOpacity(0.92),
            border: const Border(
                top: BorderSide(color: _P.divider, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: _Press(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: const RecipeEditorScreen(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_P.peachDeep, Color(0xFFE0845A)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _P.peachDeep.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('СОЗДАТЬ БЛЮДО',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Просмотр блюда ──
  void _showRecipeDetail(MealTemplate t) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RecipeDetailSheet(template: t),
    );
  }

  String _dishesWord(int n) {
    if (n == 1) return 'блюдо';
    if (n >= 2 && n <= 4) return 'блюда';
    return 'блюд';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ШТОРКА ПРОСМОТРА БЛЮДА
// ═══════════════════════════════════════════════════════════════════
class _RecipeDetailSheet extends StatelessWidget {
  final MealTemplate template;
  const _RecipeDetailSheet({required this.template});

  ({double cal, double pro, double fat, double carb}) _macros(
      NutritionProvider provider) {
    if (template.calories > 0 || template.protein > 0) {
      return (
      cal: template.calories,
      pro: template.protein,
      fat: template.fat,
      carb: template.carbs
      );
    }
    double cal = 0, pro = 0, fat = 0, carb = 0;
    for (final it in template.items) {
      final p = provider.products.where((x) => x.id == it.productId).firstOrNull;
      if (p == null) continue;
      final m = p.forGrams(it.grams);
      cal += m.calories;
      pro += m.protein;
      fat += m.fat;
      carb += m.carbs;
    }
    return (cal: cal, pro: pro, fat: fat, carb: carb);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final m = _macros(provider);
    final perPortion =
    template.portions > 0 ? m.cal / template.portions : m.cal;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                  color: _P.divider, borderRadius: BorderRadius.circular(3)),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // Заголовок
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _P.peachSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🍱',
                            style: TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(template.name,
                                style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                    color: _P.text)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(template.difficulty.emoji,
                                    style:
                                    const TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(template.difficulty.displayName,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: _P.textMuted,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _Press(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                              color: _P.bg, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: _P.textMuted),
                        ),
                      ),
                    ],
                  ),
                  // Описание
                  if ((template.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(template.description!,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _P.textMuted,
                            height: 1.5)),
                  ],
                  const SizedBox(height: 16),
                  // Мета-чипы
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip('🍽️', '${template.portions} порц.'),
                      if (template.totalTimeMin != null)
                        _infoChip('⏱️', '${template.totalTimeMin} мин'),
                      _infoChip('🔥', '${perPortion.round()} ккал/порц'),
                      _infoChip('⚖️', '${template.totalGrams.round()} г'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // КБЖУ
                  Text('КБЖУ НА ВСЁ БЛЮДО', style: _T.overline),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _P.bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _macroMini('${m.cal.round()}', 'ккал', _P.peachDeep),
                        _macroMini(m.pro.toStringAsFixed(0), 'Б', _P.greenDeep),
                        _macroMini(m.fat.toStringAsFixed(0), 'Ж', _P.yellowDeep),
                        _macroMini(m.carb.toStringAsFixed(0), 'У', _P.skyDeep),
                      ],
                    ),
                  ),
                  // Теги
                  if (template.tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('ТЕГИ', style: _T.overline),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: template.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _P.lavenderSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(RecipeTags.emoji(tag),
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(RecipeTags.label(tag),
                                  style: GoogleFonts.inter(
                                      color: _P.lavenderDeep,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Ингредиенты
                  Text('ИНГРЕДИЕНТЫ', style: _T.overline),
                  const SizedBox(height: 10),
                  ...template.items.map((item) {
                    final p =
                        provider.products.where((x) => x.id == item.productId).firstOrNull;
                    final im = p?.forGrams(item.grams);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _P.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(p?.categoryEmoji ?? '🍽️',
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: GoogleFonts.inter(
                                        color: _P.text,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Text('${item.grams.round()} г',
                                    style: GoogleFonts.inter(
                                        color: _P.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text('${im?.calories.round() ?? 0} ккал',
                              style: GoogleFonts.inter(
                                  color: _P.peachDeep,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    ui.FontFeature.tabularFigures()
                                  ])),
                        ],
                      ),
                    );
                  }),
                  // Шаги
                  if (template.steps.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('ПРИГОТОВЛЕНИЕ', style: _T.overline),
                    const SizedBox(height: 10),
                    ...template.steps.map((s) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _P.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                                color: _P.peachDeep,
                                shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text('${s.order}',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(s.text,
                                style: GoogleFonts.inter(
                                    color: _P.text,
                                    fontSize: 13,
                                    height: 1.4)),
                          ),
                          if (s.timerSec != null) ...[
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined,
                                    size: 13, color: _P.textMuted),
                                const SizedBox(width: 3),
                                Text(_fmtTimer(s.timerSec!),
                                    style: GoogleFonts.inter(
                                        color: _P.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // Нижняя панель действий
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: _P.divider.withOpacity(0.8))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: _Press(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: provider,
                                  child: RecipeEditorScreen(existing: template),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _P.peachDeep,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.edit_rounded,
                                    size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('РЕДАКТИРОВАТЬ',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8)),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Widget _infoChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _P.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _P.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [ui.FontFeature.tabularFigures()])),
        ],
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  fontFeatures: const [ui.FontFeature.tabularFigures()])),
          const SizedBox(height: 2),
          Text(unit,
              style: GoogleFonts.inter(
                  color: _P.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _fmtTimer(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m == 0) return '${s}с';
    return s == 0 ? '${m}м' : '${m}м ${s}с';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  _Press — тактильная кнопка
// ═══════════════════════════════════════════════════════════════════
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Press({required this.child, this.onTap});
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
    final interactive = widget.onTap != null;
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