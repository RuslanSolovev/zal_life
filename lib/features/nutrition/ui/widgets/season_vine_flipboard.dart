// lib/features/nutrition/ui/widgets/season_vine_flipboard.dart
// ═══════════════════════════════════════════════════════════════════
//  FLIPBOARD edition — mechanical split-flap departure board
//  3×4 grid of split-flap cells. Tap → mechanical flip through
//  fake values → panel slides down with product list.
// ═══════════════════════════════════════════════════════════════════
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zal_life/features/nutrition/ui/widgets/season_vine_style_button.dart';

import '../../models/nutrition_models.dart' show FoodProduct;
import '../../models/wellness_models.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/wellness_provider.dart';
import 'product_knowledge_sheet.dart';
import 'season_visuals.dart';

// ═══════════════════════════════════════════════════════════════════
//  Palette — industrial dark, mechanical ridges, LED accents
// ═══════════════════════════════════════════════════════════════════
class _PB {
  static const bg = Color(0xFF1A1A1A);
  static const bgDeep = Color(0xFF0F0F0F);
  static const tileBg = Color(0xFF2A2A2A);
  static const tileBgDark = Color(0xFF1F1F1F);
  static const tileEdge = Color(0xFF3A3A3A);
  static const divider = Color(0xFF0A0A0A);
  static const text = Color(0xFFF5F5F5);
  static const textDim = Color(0xFF8A8A8A);
  static const textFaint = Color(0xFF4A4A4A);
  static const ledGreen = Color(0xFF3DDC84);
  static const ledAmber = Color(0xFFFF8A65);
  static const ledOff = Color(0xFF1A3A28);
  static const panelBg = Color(0xFF151515);
  static const panelBorder = Color(0xFF2A2A2A);
}

class _VS {
  final double scale;
  const _VS(this.scale);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

// ═══════════════════════════════════════════════════════════════════
//  PUBLIC
// ═══════════════════════════════════════════════════════════════════
class SeasonVineCardFlipboard extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCardFlipboard({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  State<SeasonVineCardFlipboard> createState() =>
      _SeasonVineCardFlipboardState();
}

class _SeasonVineCardFlipboardState extends State<SeasonVineCardFlipboard>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  int? _expandedMonth;
  final Map<int, String> _topOverrides = {};
  final Map<int, String> _bottomOverrides = {};

  static const _monthNames = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Initial "flip-in" of the current month (loading → value)
    final cm = widget.wellness.currentMonth;
    _topOverrides[cm] = '--';
    _bottomOverrides[cm] = '--';
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _topOverrides.remove(cm);
        _bottomOverrides.remove(cm);
      });
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAP — mechanical cycling flip, then panel
  // ═══════════════════════════════════════════════════════════════
  Future<void> _handleTap(int month) async {
    if (_expandedMonth == month) {
      HapticFeedback.selectionClick();
      setState(() => _expandedMonth = null);
      return;
    }

    HapticFeedback.mediumImpact();

    if (_expandedMonth != null) {
      setState(() => _expandedMonth = null);
      await Future.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
    }

    final products = widget.wellness.productsForMonth(month);
    final seq = <String>[
      '···',
      '··',
      '·',
      '01',
      '02',
      '03',
      products.length.toString().padLeft(2, '0'),
    ];

    for (final v in seq) {
      if (!mounted) return;
      setState(() {
        _topOverrides[month] = v;
        _bottomOverrides[month] = '...';
      });
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 130));
    }

    if (!mounted) return;
    setState(() {
      _topOverrides.remove(month);
      _bottomOverrides.remove(month);
      _expandedMonth = month;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final r = _VS(widget.scale);
    final cm = widget.wellness.currentMonth;
    final inSeason = widget.wellness.monthsWithSeason;

    return Container(
      decoration: BoxDecoration(
        color: _PB.bg,
        borderRadius: BorderRadius.circular(r.s(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: r.s(28),
            offset: Offset(0, r.s(12)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.s(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(r, cm),
            _buildBoard(r, cm, inSeason),
            AnimatedSize(
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expandedMonth == null
                  ? const SizedBox(width: double.infinity, height: 0)
                  : _buildPanel(_expandedMonth!, r),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER — industrial title bar
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader(_VS r, int cm) {
    return Container(
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(14), r.s(16), r.s(10)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _PB.tileEdge.withOpacity(0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          Text('🌱', style: TextStyle(fontSize: r.fs(14))),
          SizedBox(width: r.s(6)),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'В СЕЗОНЕ · ${_monthNames[cm].toUpperCase()}',
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.inter(
                  color: _PB.text,
                  fontSize: r.fs(11),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  height: 1.0,
                ),
              ),
            ),
          ),

          SeasonVineStyleButton(
            scale: widget.scale,
            color: _PB.textDim,
          ),
          SizedBox(width: r.s(6)),

          GestureDetector(
            onTap: widget.onOpenKnowledge,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
              EdgeInsets.symmetric(horizontal: r.s(9), vertical: r.s(5)),
              decoration: BoxDecoration(
                border: Border.all(color: _PB.tileEdge, width: 1),
                borderRadius: BorderRadius.circular(r.s(4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ЗНАНИЯ',
                    style: GoogleFonts.inter(
                      color: _PB.textDim,
                      fontSize: r.fs(9),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: r.s(4)),
                  Icon(Icons.arrow_forward_rounded,
                      color: _PB.textDim, size: r.fs(10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOARD — 3×4 split-flap grid
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBoard(_VS r, int cm, Set<int> inSeason) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = r.s(5);
        final cellW = (constraints.maxWidth - r.s(20) - 3 * gap) / 4;
        final cellH = cellW * 0.72;

        return Padding(
          padding: EdgeInsets.all(r.s(10)),
          child: Column(
            children: [
              for (int row = 0; row < 3; row++)
                Padding(
                  padding: EdgeInsets.only(bottom: row < 2 ? gap : 0),
                  child: Row(
                    children: [
                      for (int col = 0; col < 4; col++) ...[
                        if (col > 0) SizedBox(width: gap),
                        SizedBox(
                          width: cellW,
                          child: _buildCell(
                            month: row * 4 + col + 1,
                            width: cellW,
                            height: cellH,
                            isCurrent: row * 4 + col + 1 == cm,
                            inSeason:
                            inSeason.contains(row * 4 + col + 1),
                            r: r,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCell({
    required int month,
    required double width,
    required double height,
    required bool isCurrent,
    required bool inSeason,
    required _VS r,
  }) {
    final isExpanded = month == _expandedMonth;
    final products = widget.wellness.productsForMonth(month);
    final topText = _topOverrides[month] ?? _monthNames[month].toUpperCase();
    final bottomOverride = _bottomOverrides[month];

    final Color topColor;
    if (isExpanded || isCurrent) {
      topColor = _PB.ledAmber;
    } else if (inSeason) {
      topColor = _PB.text;
    } else {
      topColor = _PB.textFaint;
    }

    final String bottomText;
    final Color bottomColor;
    final Color ledColor;

    if (isExpanded) {
      bottomText = bottomOverride ??
          '${products.length.toString().padLeft(2, '0')} ПРОД';
      bottomColor = _PB.ledAmber;
      ledColor = _PB.ledAmber;
    } else if (isCurrent) {
      bottomText = bottomOverride ?? 'СЕЙЧАС';
      bottomColor = _PB.ledAmber;
      ledColor = _PB.ledAmber;
    } else if (inSeason) {
      bottomText = bottomOverride ??
          '${products.length.toString().padLeft(2, '0')} ПРОД';
      bottomColor = _PB.textDim;
      ledColor = _PB.ledGreen;
    } else {
      bottomText = bottomOverride ?? '--';
      bottomColor = _PB.textFaint;
      ledColor = _PB.ledOff;
    }

    return _FlipCell(
      width: width,
      height: height,
      topText: topText,
      bottomText: bottomText,
      topColor: topColor,
      bottomColor: bottomColor,
      ledColor: ledColor,
      pulseEnabled: isCurrent || isExpanded,
      pulseController: _pulse,
      onTap: () => _handleTap(month),
      r: r,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EXPANDED PANEL — departure-board product list
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPanel(int month, _VS r) {
    final meta = metaForMonth(month);
    final products = widget.wellness.productsForMonth(month);
    final monthName = _monthNames[month];

    return TweenAnimationBuilder<double>(
      key: ValueKey(month),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 16),
          child: child,
        ),
      ),
      child: Container(
        margin: EdgeInsets.fromLTRB(r.s(10), r.s(2), r.s(10), r.s(10)),
        decoration: BoxDecoration(
          color: _PB.panelBg,
          border: Border.all(color: _PB.panelBorder, width: 1),
          borderRadius: BorderRadius.circular(r.s(6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                  r.s(12), r.s(10), r.s(10), r.s(10)),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _PB.panelBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(meta.emoji, style: TextStyle(fontSize: r.fs(18))),
                  SizedBox(width: r.s(8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${meta.label.toUpperCase()} · ${monthName.toUpperCase()}',
                          style: GoogleFonts.inter(
                            color: _PB.text,
                            fontSize: r.fs(12),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: r.s(2)),
                        Text(
                          products.isEmpty
                              ? 'НЕТ ПРОДУКТОВ'
                              : '${products.length} ${_productsWord(products.length).toUpperCase()} В СЕЗОНЕ',
                          style: GoogleFonts.inter(
                            color: _PB.textDim,
                            fontSize: r.fs(9),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _expandedMonth = null);
                    },
                    child: Container(
                      width: r.s(26),
                      height: r.s(26),
                      decoration: BoxDecoration(
                        border:
                        Border.all(color: _PB.tileEdge, width: 1),
                        borderRadius: BorderRadius.circular(r.s(4)),
                      ),
                      child: Icon(Icons.close_rounded,
                          color: _PB.textDim, size: r.fs(14)),
                    ),
                  ),
                ],
              ),
            ),
            if (products.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: r.s(20)),
                child: Center(
                  child: Text(
                    '// EMPTY',
                    style: GoogleFonts.inter(
                      color: _PB.textFaint,
                      fontSize: r.fs(10),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.4,
                    ),
                  ),
                ),
              )
            else
              ...products.asMap().entries.map((e) =>
                  _buildProductRow(e.key, e.value, r, isFirst: e.key == 0)),
            SizedBox(height: r.s(4)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(
      int index, ProductKnowledge k, _VS r,
      {required bool isFirst}) {
    final num = (index + 1).toString().padLeft(2, '0');
    return GestureDetector(
      onTap: () => _openProductSheet(k),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding:
        EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(9)),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isFirst ? Colors.transparent : _PB.panelBorder,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: r.s(22),
              child: Text(
                num,
                style: GoogleFonts.inter(
                  color: _PB.ledGreen,
                  fontSize: r.fs(10),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  height: 1.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Text(k.emoji, style: TextStyle(fontSize: r.fs(15))),
            SizedBox(width: r.s(10)),
            Expanded(
              child: Text(
                k.displayName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: _PB.text,
                  fontSize: r.fs(10),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.3,
                  height: 1.0,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: _PB.textFaint, size: r.fs(9)),
          ],
        ),
      ),
    );
  }

  void _openProductSheet(ProductKnowledge k) {
    HapticFeedback.selectionClick();
    FoodProduct? product;
    for (final p in widget.nutrition.products) {
      if (p.id == k.key) {
        product = p;
        break;
      }
      final norm =
      p.name.toLowerCase().replaceAll('ё', 'е').replaceAll(' ', '_');
      if (norm.contains(k.key) || k.key.contains(norm)) {
        product = p;
        break;
      }
    }
    showProductKnowledgeSheet(context,
        product: product, knowledge: k, nutrition: widget.nutrition);
  }

  String _productsWord(int n) {
    if (n == 1) return 'продукт';
    if (n >= 2 && n <= 4) return 'продукта';
    return 'продуктов';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FLIP CELL — split-flap tile with mechanical animation
// ═══════════════════════════════════════════════════════════════════
class _FlipCell extends StatefulWidget {
  final double width;
  final double height;
  final String topText;
  final String bottomText;
  final Color topColor;
  final Color bottomColor;
  final Color ledColor;
  final bool pulseEnabled;
  final AnimationController? pulseController;
  final VoidCallback? onTap;
  final _VS r;

  const _FlipCell({
    required this.width,
    required this.height,
    required this.topText,
    required this.bottomText,
    required this.topColor,
    required this.bottomColor,
    required this.ledColor,
    required this.pulseEnabled,
    required this.pulseController,
    required this.onTap,
    required this.r,
  });

  @override
  State<_FlipCell> createState() => _FlipCellState();
}

class _FlipCellState extends State<_FlipCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  late String _prevTop;
  late String _prevBottom;
  late Color _prevTopColor;
  late Color _prevBottomColor;
  late Color _prevLedColor;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _prevTop = widget.topText;
    _prevBottom = widget.bottomText;
    _prevTopColor = widget.topColor;
    _prevBottomColor = widget.bottomColor;
    _prevLedColor = widget.ledColor;
  }

  @override
  void didUpdateWidget(_FlipCell old) {
    super.didUpdateWidget(old);
    if (old.topText != widget.topText ||
        old.bottomText != widget.bottomText) {
      _prevTop = old.topText;
      _prevBottom = old.bottomText;
      _prevTopColor = old.topColor;
      _prevBottomColor = old.bottomColor;
      _prevLedColor = old.ledColor;
      _flip.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mid = widget.height / 2;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (_, __) {
          final t = _flip.value;
          final showingOld = _flip.isAnimating && t < 0.5;

          // Top half rotates: 0 → +π/2 (old flaps down)
          //                    then -π/2 → 0 (new flaps up)
          final topAngle = t < 0.5 ? t * math.pi : (t - 1) * math.pi;

          final topText = showingOld ? _prevTop : widget.topText;
          final topColor = showingOld ? _prevTopColor : widget.topColor;
          final bottomText = showingOld ? _prevBottom : widget.bottomText;
          final bottomColor =
          showingOld ? _prevBottomColor : widget.bottomColor;
          final ledColor = showingOld ? _prevLedColor : widget.ledColor;

          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: _PB.tileBgDark,
              border: Border.all(color: _PB.tileEdge, width: 0.5),
              borderRadius: BorderRadius.circular(widget.r.s(3)),
            ),
            child: Stack(
              children: [
                // Top half — flips away / in
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: mid,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.004)
                      ..rotateX(topAngle),
                    child: _buildTopHalf(topText, topColor),
                  ),
                ),
                // Bottom half — static, swaps at midpoint
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: mid,
                  child: _buildBottomHalf(bottomText, bottomColor, ledColor),
                ),
                // Divider — the mechanical hinge
                Positioned(
                  left: 0,
                  right: 0,
                  top: mid - 0.5,
                  child: Container(height: 1, color: _PB.divider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopHalf(String text, Color color) {
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_PB.tileBgDark, _PB.tileBg],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(widget.r.s(3)),
            topRight: Radius.circular(widget.r.s(3)),
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.r.s(2)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: widget.r.fs(13),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  height: 1.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomHalf(String text, Color color, Color ledColor) {
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_PB.tileBg, _PB.tileBgDark],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(widget.r.s(3)),
            bottomRight: Radius.circular(widget.r.s(3)),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.r.s(4)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLed(ledColor),
              SizedBox(width: widget.r.s(3)),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: widget.r.fs(8),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      height: 1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLed(Color color) {
    final dot = Container(
      width: widget.r.s(4),
      height: widget.r.s(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.7),
            blurRadius: widget.r.s(4),
            spreadRadius: 0.5,
          ),
        ],
      ),
    );

    if (!widget.pulseEnabled || widget.pulseController == null) {
      return dot;
    }

    return AnimatedBuilder(
      animation: widget.pulseController!,
      builder: (_, __) {
        final p = 0.55 +
            0.45 * math.sin(widget.pulseController!.value * math.pi);
        return Opacity(opacity: p.clamp(0.0, 1.0), child: dot);
      },
    );
  }
}