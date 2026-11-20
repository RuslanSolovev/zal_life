// features/nutrition/ui/screens/barcode_sheets.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import 'barcode_lookup_service.dart' hide BarcodeSource, BarcodeProduct, OnlineHit;

// ═══════════════════════════════════════════════════════════════
//  Design tokens
// ═══════════════════════════════════════════════════════════════
class _C {
  static const bg = Color(0xFFF6F7F9);
  static const text = Color(0xFF1C2026);
  static const muted = Color(0xFF7C818A);
  static const divider = Color(0xFFE9EBEF);
  static const green = Color(0xFF6C9E88);
  static const greenSoft = Color(0xFFE7F2ED);
  static const sky = Color(0xFF7E9DC6);
  static const skySoft = Color(0xFFE8EFF8);
  static const peach = Color(0xFFEF9563);
  static const peachSoft = Color(0xFFFBEDE4);
  static const yellow = Color(0xFFE0B054);
  static const yellowSoft = Color(0xFFFDF5E6);
  static const pink = Color(0xFFD17A8F);
  static const pinkSoft = Color(0xFFFCF0F2);
  static const lavender = Color(0xFF9381BB);
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const brown = Color(0xFFA87B4F);
  static const brownSoft = Color(0xFFF3E9DC);
}

Widget _grabber() => Container(
  width: 36,
  height: 5,
  decoration: BoxDecoration(
      color: _C.divider, borderRadius: BorderRadius.circular(3)),
);

TextStyle get _overline => GoogleFonts.inter(
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.2,
  color: _C.muted,
);

InputDecoration _dec(String label, {String? hint, String? suffix}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      labelStyle: GoogleFonts.inter(color: _C.muted, fontSize: 12),
      filled: true,
      fillColor: _C.bg,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none),
    );

// ═══════════════════════════════════════════════════════════════
//  1. РЕЗУЛЬТАТ НАЙДЕН — с фото, источником и альтернативами
// ═══════════════════════════════════════════════════════════════
Future<BarcodeProduct?> showBarcodeResultSheet(
    BuildContext context,
    BarcodeProduct product, {
      String? hint,
      NutritionProvider? provider,
    }) {
  return showModalBottomSheet<BarcodeProduct>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ResultSheet(
      product: product,
      hint: hint,
      provider: provider,
    ),
  );
}

class _ResultSheet extends StatefulWidget {
  final BarcodeProduct product;
  final String? hint;
  final NutritionProvider? provider;

  const _ResultSheet({
    required this.product,
    this.hint,
    this.provider,
  });

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet> {
  late final TextEditingController _name;
  late final TextEditingController _cal;
  late final TextEditingController _pro;
  late final TextEditingController _fat;
  late final TextEditingController _carb;
  late final TextEditingController _fiber;
  late final TextEditingController _packGrams;

  bool _showAlternatives = false;
  List<FoodProduct> _alternatives = const [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p.displayName);
    _cal = TextEditingController(
        text: p.calories > 0 ? p.calories.toStringAsFixed(0) : '');
    _pro = TextEditingController(
        text: p.protein > 0 ? p.protein.toStringAsFixed(1) : '');
    _fat =
        TextEditingController(text: p.fat > 0 ? p.fat.toStringAsFixed(1) : '');
    _carb = TextEditingController(
        text: p.carbs > 0 ? p.carbs.toStringAsFixed(1) : '');
    _fiber = TextEditingController(
        text: p.fiber > 0 ? p.fiber.toStringAsFixed(1) : '');
    _packGrams = TextEditingController(
        text: p.packageGrams != null ? p.packageGrams!.toStringAsFixed(0) : '');

    // 🆕 ИДЕЯ 5: ищем альтернативы из локальной базы
    _loadAlternatives();
  }

  void _loadAlternatives() {
    final provider = widget.provider;
    if (provider == null) return;
    final category = widget.product.category;
    if (category.isEmpty || category == 'other') return;

    final currentName = widget.product.displayName.toLowerCase().trim();
    final candidates = provider.products.where((p) {
      if (p.category != category) return false;
      if (p.barcode == widget.product.barcode) return false;
      if (p.name.toLowerCase().trim() == currentName) return false;
      return true;
    }).toList();

    // Сортируем: сначала те, у кого есть КБЖУ, потом по имени
    candidates.sort((a, b) {
      final aHasNutrition = a.calories > 0 || a.protein > 0;
      final bHasNutrition = b.calories > 0 || b.protein > 0;
      if (aHasNutrition != bHasNutrition) {
        return aHasNutrition ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    setState(() {
      _alternatives = candidates.take(4).toList();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _cal.dispose();
    _pro.dispose();
    _fat.dispose();
    _carb.dispose();
    _fiber.dispose();
    _packGrams.dispose();
    super.dispose();
  }

  double _v(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final srcLabel = switch (p.source) {
      BarcodeSource.localDb => '📦 Твоя база',
      BarcodeSource.cache => '⚡ Кэш',
      BarcodeSource.openFoodFacts => '🌐 OpenFoodFacts',
      BarcodeSource.upcItemDb => '🌐 UPCitemdb',
      BarcodeSource.manual => '✍️ Вручную',
    };
    final srcColor = switch (p.source) {
      BarcodeSource.localDb => _C.brown,
      BarcodeSource.cache => _C.lavender,
      BarcodeSource.openFoodFacts => _C.green,
      BarcodeSource.upcItemDb => _C.sky,
      BarcodeSource.manual => _C.peach,
    };

    final needsName = _name.text.trim().isEmpty;
    final needsNutrition = !p.hasNutrition;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                Center(child: _grabber()),
                const SizedBox(height: 16),

                // ─── Фото продукта ───
                if (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        p.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: _C.bg,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_rounded,
                                color: _C.muted, size: 40),
                          ),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: _C.bg,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _C.sky),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // ─── Источник + Страна ───
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: srcColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: srcColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(srcLabel,
                              style: GoogleFonts.inter(
                                  color: srcColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    if (widget.hint != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(widget.hint!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                color: _C.muted, fontSize: 11)),
                      ),
                    ] else
                      const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _C.bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.barcode,
                        style: GoogleFonts.inter(
                          color: _C.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [
                            ui.FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ─── Заголовок ───
                Text('ПРОВЕРЬ ДАННЫЕ', style: _overline),
                const SizedBox(height: 4),
                Text(
                  p.hasName ? 'Нашли товар' : 'Название не заполнено',
                  style: GoogleFonts.inter(
                    color: _C.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Предупреждение о КБЖУ ───
                if (needsNutrition)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _C.yellowSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _C.yellow.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: _C.yellow),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'В базе нет КБЖУ. Впиши с этикетки — сохраним навсегда.',
                            style: GoogleFonts.inter(
                              color: _C.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ─── Название ───
                TextField(
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(
                    color: _C.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _dec('Название продукта'),
                ),
                const SizedBox(height: 12),

                // ─── КБЖУ ───
                Text('КБЖУ НА 100 Г', style: _overline),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: _cal,
                            keyboardType: TextInputType.number,
                            decoration: _dec('Ккал'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: _pro,
                            keyboardType: TextInputType.number,
                            decoration: _dec('Б'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: _fat,
                            keyboardType: TextInputType.number,
                            decoration: _dec('Ж'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: _carb,
                            keyboardType: TextInputType.number,
                            decoration: _dec('У'))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fiber,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: _dec('Клетчатка (опционально)'),
                ),
                const SizedBox(height: 12),

                // ─── Вес упаковки ───
                TextField(
                  controller: _packGrams,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: _dec('Вес упаковки, г (опционально)',
                      suffix: 'г'),
                ),
                const SizedBox(height: 16),

                // ─── ИДЕЯ 5: СРАВНЕНИЕ С АЛЬТЕРНАТИВАМИ ───
                if (_alternatives.isNotEmpty)
                  _AlternativesSection(
                    alternatives: _alternatives,
                    currentName: _name.text,
                    expanded: _showAlternatives,
                    onToggle: () => setState(
                            () => _showAlternatives = !_showAlternatives),
                    onSelect: (alt) {
                      setState(() {
                        _name.text = alt.name;
                        _cal.text = alt.calories > 0
                            ? alt.calories.toStringAsFixed(0)
                            : _cal.text;
                        _pro.text = alt.protein > 0
                            ? alt.protein.toStringAsFixed(1)
                            : _pro.text;
                        _fat.text = alt.fat > 0
                            ? alt.fat.toStringAsFixed(1)
                            : _fat.text;
                        _carb.text = alt.carbs > 0
                            ? alt.carbs.toStringAsFixed(1)
                            : _carb.text;
                        _fiber.text = alt.fiber > 0
                            ? alt.fiber.toStringAsFixed(1)
                            : _fiber.text;
                      });
                      HapticFeedback.mediumImpact();
                    },
                  ),

                const SizedBox(height: 20),

                // ─── Кнопка подтверждения ───
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: needsName
                        ? null
                        : () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(
                        context,
                        BarcodeProduct(
                          barcode: p.barcode,
                          name: _name.text.trim(),
                          brand: p.brand,
                          category: p.category,
                          calories: _v(_cal),
                          protein: _v(_pro),
                          fat: _v(_fat),
                          carbs: _v(_carb),
                          fiber: _v(_fiber),
                          packageGrams:
                          double.tryParse(_packGrams.text),
                          imageUrl: p.imageUrl,
                          source: p.source,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.green,
                      disabledBackgroundColor: _C.divider,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('ПОДТВЕРДИТЬ',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
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

// ═══════════════════════════════════════════════════════════════
//  ИДЕЯ 5: СРАВНЕНИЕ С АЛЬТЕРНАТИВАМИ ИЗ БАЗЫ
// ═══════════════════════════════════════════════════════════════
class _AlternativesSection extends StatelessWidget {
  final List<FoodProduct> alternatives;
  final String currentName;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(FoodProduct) onSelect;

  const _AlternativesSection({
    required this.alternatives,
    required this.currentName,
    required this.expanded,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: _C.lavenderSoft.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.lavender.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _C.lavender.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.compare_arrows_rounded,
                        size: 16, color: _C.lavender),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ПОХОЖИЕ ИЗ ТВОЕЙ БАЗЫ',
                            style: GoogleFonts.inter(
                              color: _C.lavender,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          '${alternatives.length} альтернатив${alternatives.length == 1 ? 'а' : ''} · сравни КБЖУ',
                          style: GoogleFonts.inter(
                            color: _C.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: _C.lavender),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: _C.divider),
            ...alternatives.map((alt) => _alternativeTile(alt)),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _alternativeTile(FoodProduct alt) {
    return InkWell(
      onTap: () => onSelect(alt),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(alt.categoryEmoji,
                style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alt.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _C.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _macroChip('${alt.calories.round()}', 'ккал', _C.peach),
                      const SizedBox(width: 4),
                      _macroChip(alt.protein.toStringAsFixed(0), 'Б', _C.green),
                      const SizedBox(width: 4),
                      _macroChip(alt.fat.toStringAsFixed(0), 'Ж', _C.peach),
                      const SizedBox(width: 4),
                      _macroChip(alt.carbs.toStringAsFixed(0), 'У', _C.yellow),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.north_east_rounded,
                size: 14, color: _C.lavender),
          ],
        ),
      ),
    );
  }

  Widget _macroChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$value $label',
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFeatures: const [ui.FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  2. НЕ НАЙДЕН — 3 пути решения
// ═══════════════════════════════════════════════════════════════
class NotFoundChoice {
  final FoodProduct? local;
  final String? manualName;
  final bool retryOnline;

  const NotFoundChoice({
    this.local,
    this.manualName,
    this.retryOnline = false,
  });
}

Future<NotFoundChoice?> showBarcodeNotFoundSheet(
    BuildContext context, {
      required NutritionProvider provider,
      required String barcode,
      String? hint,
    }) {
  return showModalBottomSheet<NotFoundChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _NotFoundSheet(
      provider: provider,
      barcode: barcode,
      hint: hint,
    ),
  );
}

class _NotFoundSheet extends StatelessWidget {
  final NutritionProvider provider;
  final String barcode;
  final String? hint;

  const _NotFoundSheet({
    required this.provider,
    required this.barcode,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Center(child: _grabber()),
            const SizedBox(height: 16),
            Text('ТОВАР НЕ НАЙДЕН',
                style: _overline.copyWith(color: _C.peach)),
            const SizedBox(height: 4),
            Text(
              'Что делаем?',
              style: GoogleFonts.inter(
                color: _C.text,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Код $barcode${hint != null ? ' · $hint' : ''}',
              style: GoogleFonts.inter(color: _C.muted, fontSize: 11),
            ),
            const SizedBox(height: 18),
            _tile(
              context,
              icon: Icons.travel_explore_rounded,
              color: _C.sky,
              soft: _C.skySoft,
              title: 'Найти по названию онлайн',
              subtitle: 'Поиск в OpenFoodFacts по словам',
              onTap: () async {
                final hit = await showModalBottomSheet<OnlineHit>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) =>
                      _OnlineSearchSheet(provider: provider),
                );
                if (hit == null || !context.mounted) return;
                Navigator.pop(
                  context,
                  NotFoundChoice(
                    manualName: [
                      hit.name,
                      if (hit.brand != null) hit.brand!
                    ].join(' ('),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _tile(
              context,
              icon: Icons.inventory_2_outlined,
              color: _C.green,
              soft: _C.greenSoft,
              title: 'Выбрать из моей базы',
              subtitle:
              '${provider.products.length} продуктов · штрихкод привяжется',
              onTap: () async {
                final p = await showModalBottomSheet<FoodProduct>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => _LocalPickSheet(provider: provider),
                );
                if (p == null || !context.mounted) return;
                Navigator.pop(context, NotFoundChoice(local: p));
              },
            ),
            const SizedBox(height: 8),
            _tile(
              context,
              icon: Icons.edit_rounded,
              color: _C.peach,
              soft: _C.peachSoft,
              title: 'Ввести название вручную',
              subtitle: '10 секунд — и товар запомнится навсегда',
              onTap: () => Navigator.pop(
                  context, const NotFoundChoice(manualName: '')),
            ),
            const SizedBox(height: 8),
            _tile(
              context,
              icon: Icons.refresh_rounded,
              color: _C.muted,
              soft: _C.bg,
              title: 'Проверить в интернете ещё раз',
              subtitle: 'Сбросить кэш отказа',
              onTap: () => Navigator.pop(
                  context, const NotFoundChoice(retryOnline: true)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required Color soft,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: _C.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: _C.muted, fontSize: 10.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

// ─────────── Поиск онлайн по названию ───────────
class _OnlineSearchSheet extends StatefulWidget {
  final NutritionProvider provider;
  const _OnlineSearchSheet({required this.provider});
  @override
  State<_OnlineSearchSheet> createState() => _OnlineSearchSheetState();
}

class _OnlineSearchSheetState extends State<_OnlineSearchSheet> {
  final _ctrl = TextEditingController();
  List<OnlineHit> _hits = const [];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_ctrl.text.trim().length < 2) return;
    setState(() => _loading = true);
    final r = await widget.provider.searchProductsOnline(_ctrl.text);
    if (!mounted) return;
    setState(() {
      _hits = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _grabber(),
              const SizedBox(height: 14),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ПОИСК ОНЛАЙН', style: _overline)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onSubmitted: (_) => _search(),
                      decoration:
                      _dec('Например: молоко простоквашино'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.sky,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _hits.isEmpty
                    ? Center(
                    child: Text(
                        _loading
                            ? 'Ищем…'
                            : 'Введи название и нажми 🔍',
                        style: GoogleFonts.inter(
                            color: _C.muted, fontSize: 12)))
                    : ListView.separated(
                  itemCount: _hits.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final h = _hits[i];
                    return InkWell(
                      onTap: () =>
                          Navigator.pop(context, h),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: _C.bg,
                            borderRadius:
                            BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(h.name,
                                      maxLines: 2,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          color: _C.text,
                                          fontSize: 12.5,
                                          fontWeight:
                                          FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${h.brand ?? '—'} · ${h.calories.round()} ккал/100г',
                                      style: GoogleFonts.inter(
                                          color: _C.muted,
                                          fontSize: 10)),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_rounded,
                                size: 16, color: _C.sky),
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
      ),
    );
  }
}

// ─────────── Выбор из локальной базы ───────────
class _LocalPickSheet extends StatefulWidget {
  final NutritionProvider provider;
  const _LocalPickSheet({required this.provider});
  @override
  State<_LocalPickSheet> createState() => _LocalPickSheetState();
}

class _LocalPickSheetState extends State<_LocalPickSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = _q.isEmpty
        ? widget.provider.products.take(80).toList()
        : widget.provider.searchProducts(_q).take(80).toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _grabber(),
            const SizedBox(height: 14),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('МОЯ БАЗА', style: _overline)),
            const SizedBox(height: 10),
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: _dec('Найти продукт'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final p = list[i];
                  return InkWell(
                    onTap: () => Navigator.pop(context, p),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Text(p.categoryEmoji,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        color: _C.text,
                                        fontSize: 12.5,
                                        fontWeight:
                                        FontWeight.w600)),
                                Text(
                                    '${p.calories.round()} ккал / 100 г',
                                    style: GoogleFonts.inter(
                                        color: _C.muted,
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                          const Icon(Icons.link_rounded,
                              size: 16, color: _C.green),
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