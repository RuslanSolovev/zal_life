// features/nutrition/ui/widgets/transfer_to_shopping_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';

class _T {
  static const bg = Color(0xFFF7F6F2);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF243A32);
  static const muted = Color(0xFF7C8982);
  static const green = Color(0xFF3E6A55);
  static const greenSoft = Color(0xFFE7EFE5);
  static const peach = Color(0xFFC4886A);
  static const amber = Color(0xFFE0A93F);
  static const divider = Color(0xFFE7EAE3);
}

class _R {
  final double scale;
  _R(BuildContext context)
      : scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
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
    case 'Овощи': return const Color(0xFF6C9E88);
    case 'Фрукты': return const Color(0xFFFF8A65);
    case 'Мясо': return const Color(0xFFFF6B8B);
    case 'Рыба': return const Color(0xFF7EA8C6);
    case 'Молочка': return const Color(0xFFE8B858);
    case 'Хлеб': return const Color(0xFFD4A04A);
    case 'Бакалея': return const Color(0xFFA5C9AF);
    case 'Заморозка': return const Color(0xFF7EA8C6);
    case 'Напитки': return const Color(0xFF6C9E88);
    case 'Сладости': return const Color(0xFFFF6B8B);
    case 'Соусы': return const Color(0xFFEF9563);
    default: return const Color(0xFF8E949B);
  }
}

const List<String> _allUnits = ['шт', 'г', 'кг', 'мл', 'л'];
const List<String> _allPriceBases = [
  'за шт', 'за г', 'за 100 г', 'за кг', 'за мл', 'за 100 мл', 'за л',
];

enum _Dim { piece, mass, volume }

_Dim _dimOf(String unit) {
  switch (unit) {
    case 'шт': return _Dim.piece;
    case 'г': case 'кг': return _Dim.mass;
    case 'мл': case 'л': return _Dim.volume;
    default: return _Dim.piece;
  }
}

_Dim _dimOfPrice(String basis) {
  switch (basis) {
    case 'за шт': return _Dim.piece;
    case 'за г': case 'за 100 г': case 'за кг': return _Dim.mass;
    case 'за мл': case 'за 100 мл': case 'за л': return _Dim.volume;
    default: return _Dim.piece;
  }
}

PriceBasis _defaultBasisFor(_Dim d) {
  switch (d) {
    case _Dim.piece: return PriceBasis.perPiece;
    case _Dim.mass: return PriceBasis.perKg;
    case _Dim.volume: return PriceBasis.perLiter;
  }
}

String _defaultUnitFor(_Dim d) {
  switch (d) {
    case _Dim.piece: return 'шт';
    case _Dim.mass: return 'г';
    case _Dim.volume: return 'мл';
  }
}

double _qtyToBase(double q, String unit) {
  switch (unit) {
    case 'кг': case 'л': return q * 1000;
    default: return q;
  }
}

double _priceToBase(double p, String basis) {
  switch (basis) {
    case 'за кг': case 'за л': return p / 1000;
    case 'за 100 г': case 'за 100 мл': return p / 100;
    default: return p;
  }
}

PriceBasis _basisFromLabel(String label) {
  switch (label) {
    case 'за шт': return PriceBasis.perPiece;
    case 'за г': return PriceBasis.perGram;
    case 'за 100 г': return PriceBasis.per100g;
    case 'за кг': return PriceBasis.perKg;
    case 'за мл': return PriceBasis.perMl;
    case 'за 100 мл': return PriceBasis.per100ml;
    case 'за л': return PriceBasis.perLiter;
    default: return PriceBasis.perKg;
  }
}

String _labelFromBasis(PriceBasis basis) {
  switch (basis) {
    case PriceBasis.perPiece: return 'за шт';
    case PriceBasis.perGram: return 'за г';
    case PriceBasis.per100g: return 'за 100 г';
    case PriceBasis.perKg: return 'за кг';
    case PriceBasis.perMl: return 'за мл';
    case PriceBasis.per100ml: return 'за 100 мл';
    case PriceBasis.perLiter: return 'за л';
    default: return 'за кг';
  }
}

String _fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final s = v.toStringAsFixed(2);
  return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
}

Future<void> showTransferToShoppingSheet(
    BuildContext context,
    NutritionProvider provider, {
      required String name,
      String? productId,
      double quantity = 1,
      String unit = 'шт',
      bool isUrgent = false,
    }) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TransferSheet(
      provider: provider,
      name: name,
      productId: productId,
      quantity: quantity,
      unit: unit,
      isUrgent: isUrgent,
    ),
  );
}

class _TransferSheet extends StatefulWidget {
  final NutritionProvider provider;
  final String name;
  final String? productId;
  final double quantity;
  final String unit;
  final bool isUrgent;
  const _TransferSheet({
    required this.provider,
    required this.name,
    required this.productId,
    required this.quantity,
    required this.unit,
    required this.isUrgent,
  });
  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late String _aisle;
  late String _unit;
  late String _priceBasisLabel;
  late String _emoji;
  bool _aisleAuto = true;
  bool _pricePrefilled = false;
  double? _lastPrice;

  @override
  void initState() {
    super.initState();
    final p = widget.productId != null
        ? widget.provider.products
        .where((x) => x.id == widget.productId).firstOrNull
        : null;
    _emoji = (p?.categoryEmoji ?? '').isEmpty ? '📦' : p!.categoryEmoji;
    _aisle = _categoryToAisle(p?.category ?? 'other');
    _unit = widget.unit;
    _qtyCtrl = TextEditingController(text: _fmtNum(widget.quantity));

    final last = _findLastPrice();
    _lastPrice = last.$1;
    _pricePrefilled = last.$1 != null;
    _priceCtrl =
        TextEditingController(text: last.$1 != null ? _fmtNum(last.$1!) : '');

    var basis = last.$2 ?? _defaultBasisFor(_dimOf(_unit));
    if (_dimOfPrice(_labelFromBasis(basis)) != _dimOf(_unit)) {
      basis = _defaultBasisFor(_dimOf(_unit));
    }
    _priceBasisLabel = _labelFromBasis(basis);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  (double?, PriceBasis?) _findLastPrice() {
    final bought = widget.provider.shoppingItems.where((i) => i.isBought).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final item in bought) {
      final match = (widget.productId != null && item.productId == widget.productId) ||
          item.displayName.toLowerCase().trim() == widget.name.toLowerCase().trim();
      if (match && item.estimatedPrice != null && item.estimatedPrice! > 0) {
        return (item.estimatedPrice, item.priceBasis);
      }
    }
    return (null, null);
  }

  void _setUnit(String u) {
    setState(() {
      _unit = u;
      final d = _dimOf(u);
      if (_dimOfPrice(_priceBasisLabel) != d) {
        _priceBasisLabel = _labelFromBasis(_defaultBasisFor(d));
      }
    });
  }

  void _setBasis(String label) {
    setState(() {
      _priceBasisLabel = label;
      final d = _dimOfPrice(label);
      if (_dimOf(_unit) != d) _unit = _defaultUnitFor(d);
    });
  }

  void _confirm() {
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? widget.quantity;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    final messenger = ScaffoldMessenger.of(context);
    widget.provider.addShoppingItem(
      productId: widget.productId,
      customName: widget.name,
      quantity: qty <= 0 ? 1 : qty,
      unit: _unit,
      estimatedPrice: (price != null && price > 0) ? price : null,
      priceBasis: _basisFromLabel(_priceBasisLabel),
      category: _aisle,
      isUrgent: widget.isUrgent,
    );
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    messenger.showSnackBar(SnackBar(
      content: Text('🛒 «${widget.name}» добавлен в список ($_aisle)'),
      backgroundColor: _T.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final total = (qty > 0 && price > 0)
        ? _qtyToBase(qty, _unit) * _priceToBase(price, _priceBasisLabel)
        : 0.0;
    final accent = _aisleAccent(_aisle);

    return Container(
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(top: r.s(12)),
              child: Center(
                child: Container(
                  width: r.s(38), height: r.s(5),
                  decoration: BoxDecoration(
                    color: _T.divider,
                    borderRadius: BorderRadius.circular(r.s(3)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(16), r.s(20), r.s(8)),
              child: Row(
                children: [
                  Container(
                    width: r.s(52), height: r.s(52),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(r.s(16)),
                    ),
                    alignment: Alignment.center,
                    child: Text(_emoji, style: TextStyle(fontSize: r.s(26))),
                  ),
                  SizedBox(width: r.s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                color: _T.text, fontSize: r.fs(16),
                                fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                        SizedBox(height: r.s(2)),
                        Text('→ Список покупок',
                            style: GoogleFonts.inter(
                                color: accent, fontSize: r.fs(11),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: r.s(36), height: r.s(36),
                      decoration: BoxDecoration(
                          color: _T.surface, shape: BoxShape.circle,
                          border: Border.all(color: _T.divider)),
                      child: Icon(Icons.close_rounded,
                          size: r.s(16), color: _T.muted),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: r.s(20)),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(r, 'ОТДЕЛ',
                        badge: _aisleAuto ? 'определён автоматически' : null),
                    SizedBox(height: r.s(10)),
                    Wrap(
                      spacing: r.s(6), runSpacing: r.s(6),
                      children: _storeAisles.map((a) {
                        final selected = _aisle == a;
                        final c = _aisleAccent(a);
                        return GestureDetector(
                          onTap: () => setState(() {
                            _aisle = a;
                            _aisleAuto = false;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(
                                horizontal: r.s(12), vertical: r.s(8)),
                            decoration: BoxDecoration(
                              color: selected ? c : _T.surface,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                  color: selected ? c : _T.divider,
                                  width: selected ? 0 : 1),
                              boxShadow: selected
                                  ? [BoxShadow(
                                  color: c.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_aisleEmoji(a),
                                    style: TextStyle(fontSize: r.fs(13))),
                                SizedBox(width: r.s(5)),
                                Text(a,
                                    style: GoogleFonts.inter(
                                        color: selected ? Colors.white : _T.text,
                                        fontSize: r.fs(12),
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: r.s(20)),
                    _sectionLabel(r, 'КОЛИЧЕСТВО'),
                    SizedBox(height: r.s(10)),
                    _field(_qtyCtrl, r, hint: '0', keyboard: true),
                    SizedBox(height: r.s(8)),
                    Wrap(
                      spacing: r.s(6), runSpacing: r.s(6),
                      children: _allUnits.map((u) {
                        final selected = _unit == u;
                        return GestureDetector(
                          onTap: () => _setUnit(u),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(
                                horizontal: r.s(14), vertical: r.s(8)),
                            decoration: BoxDecoration(
                                color: selected ? _T.green : _T.surface,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                    color: selected ? _T.green : _T.divider,
                                    width: selected ? 0 : 1)),
                            child: Text(u,
                                style: GoogleFonts.inter(
                                    color: selected ? Colors.white : _T.text,
                                    fontSize: r.fs(12),
                                    fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: r.s(20)),
                    _sectionLabel(r, 'ЦЕНА',
                        badge: _pricePrefilled && _lastPrice != null
                            ? 'последняя: ${_fmtNum(_lastPrice!)} ₽'
                            : null),
                    SizedBox(height: r.s(10)),
                    _field(_priceCtrl, r,
                        hint: '0', keyboard: true, suffix: '₽'),
                    SizedBox(height: r.s(8)),
                    Wrap(
                      spacing: r.s(6), runSpacing: r.s(6),
                      children: _allPriceBases.map((b) {
                        final selected = _priceBasisLabel == b;
                        return GestureDetector(
                          onTap: () => _setBasis(b),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(
                                horizontal: r.s(12), vertical: r.s(8)),
                            decoration: BoxDecoration(
                                color: selected ? _T.peach : _T.surface,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                    color: selected ? _T.peach : _T.divider,
                                    width: selected ? 0 : 1)),
                            child: Text(b,
                                style: GoogleFonts.inter(
                                    color: selected ? Colors.white : _T.text,
                                    fontSize: r.fs(12),
                                    fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: r.s(20)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(r.s(16)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: total > 0
                              ? [_T.green, const Color(0xFF2D4A3E)]
                              : [_T.divider, _T.divider],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(r.s(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ИТОГО',
                              style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: r.fs(11),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0)),
                          Text(total > 0 ? '~ ${_fmtNum(total)} ₽' : '—',
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: r.fs(24),
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ])),
                        ],
                      ),
                    ),
                    SizedBox(height: r.s(20)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
              child: SizedBox(
                width: double.infinity, height: r.s(56),
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: _T.green.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(r.s(16))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      SizedBox(width: r.s(8)),
                      Text('ДОБАВИТЬ В СПИСОК',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: r.fs(14),
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(_R r, String text, {String? badge}) {
    return Row(
      children: [
        Container(
            width: 3, height: 12,
            decoration: BoxDecoration(
                color: _T.green, borderRadius: BorderRadius.circular(2))),
        SizedBox(width: r.s(8)),
        Text(text,
            style: GoogleFonts.inter(
                color: _T.muted, fontSize: r.fs(10),
                fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        if (badge != null) ...[
          SizedBox(width: r.s(8)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(3)),
            decoration: BoxDecoration(
                color: _T.greenSoft,
                borderRadius: BorderRadius.circular(100)),
            child: Text(badge,
                style: GoogleFonts.inter(
                    color: _T.green, fontSize: r.fs(9),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  Widget _field(TextEditingController ctrl, _R r,
      {required String hint, bool keyboard = false, String? suffix}) {
    return Container(
      decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(r.s(16)),
          border: Border.all(color: _T.divider)),
      padding: EdgeInsets.symmetric(horizontal: r.s(16)),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(
            color: _T.text, fontSize: r.fs(18), fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()]),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: _T.muted, fontSize: r.fs(16)),
          suffixText: suffix,
          suffixStyle:
          GoogleFonts.inter(color: _T.muted, fontSize: r.fs(15)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: r.s(16)),
        ),
      ),
    );
  }
}