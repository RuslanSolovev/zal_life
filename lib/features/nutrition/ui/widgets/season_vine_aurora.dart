// lib/features/nutrition/ui/widgets/season_vine_aurora.dart
// ═══════════════════════════════════════════════════════════════════
//  AURORA FLOW edition — Northern lights ribbon concept
//  12 months live as peaks on a flowing aurora. Tap → flash → panel.
//  Dark cosmic surface inside an otherwise light app.
// ═══════════════════════════════════════════════════════════════════
import 'dart:math' as math;
import 'dart:ui' show MaskFilter, BlurStyle, FontFeature, ImageFilter;

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
//  Palette — deep space + aurora borealis
// ═══════════════════════════════════════════════════════════════════
class _AF {
  static const bg = Color(0xFF0D1117);
  static const bgDeep = Color(0xFF05070B);
  static const surface = Color(0xFF151A22);
  static const cardBg = Color(0xFF1A2029);
  static const cardBorder = Color(0xFF2A3242);

  static const auroraGreen = Color(0xFF3DDC84);
  static const auroraBlue = Color(0xFF4A90E2);
  static const auroraPink = Color(0xFFFF6B8B);
  static const auroraPeach = Color(0xFFFF8A65);

  static const textPrimary = Color(0xFFE8EEF5);
  static const textMuted = Color(0xFF8A94A6);
  static const textFaint = Color(0xFF4A5466);
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
class SeasonVineCardAurora extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCardAurora({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  State<SeasonVineCardAurora> createState() =>
      _SeasonVineCardAuroraState();
}

class _SeasonVineCardAuroraState extends State<SeasonVineCardAurora>
    with TickerProviderStateMixin {
  late final AnimationController _flow;
  late final ScrollController _scroll;
  int? _expandedMonth;

  static const _monthNames = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  // geometry (unscaled — multiplied by widget.scale at use site)
  static const double _monthSpacing = 76.0;
  static const double _sideMargin = 60.0;
  static const double _auroraHeight = 210.0;
  static const double _peakHeight = 65.0;
  static const double _baselineFactor = 0.72;

  // ─── scaled getters ───
  double get _monthSpacingScaled => _monthSpacing * widget.scale;
  double get _sideMarginScaled => _sideMargin * widget.scale;
  double get _totalWidthScaled =>
      (_sideMargin * 2 + 11 * _monthSpacing) * widget.scale;
  double _monthX(int month) =>
      (_sideMargin + (month - 1) * _monthSpacing) * widget.scale;

  double get _baselineY => _auroraHeight * _baselineFactor * widget.scale;
  double get _peakHeightScaled => _peakHeight * widget.scale;

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _scroll = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnMonth(widget.wellness.currentMonth, animate: false);
    });
  }

  @override
  void dispose() {
    _flow.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _centerOnMonth(int month, {bool animate = true}) {
    if (!_scroll.hasClients) return;
    final viewport = _scroll.position.viewportDimension;
    final target = (_monthX(month) - viewport / 2)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    if (animate) {
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic);
    } else {
      _scroll.jumpTo(target);
    }
  }

  void _toggleMonth(int month) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedMonth == month) {
        _expandedMonth = null;
      } else {
        _expandedMonth = month;
        _centerOnMonth(month);
      }
    });
  }

  double _brightnessFor(int month) {
    if (month == _expandedMonth) return 1.10;
    if (month == widget.wellness.currentMonth) return 1.00;
    if (widget.wellness.monthsWithSeason.contains(month)) return 0.60;
    return 0.18;
  }

  double _peakApexY(int month) =>
      _baselineY - _peakHeightScaled * _brightnessFor(month);

  @override
  Widget build(BuildContext context) {
    final r = _VS(widget.scale);
    final currentMonth = widget.wellness.currentMonth;
    final monthsWithSeason = widget.wellness.monthsWithSeason;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.s(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: r.s(40),
            offset: Offset(0, r.s(20)),
          ),
          BoxShadow(
            color: _AF.auroraGreen.withOpacity(0.06),
            blurRadius: r.s(60),
            spreadRadius: r.s(-12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.s(28)),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_AF.bgDeep, _AF.bg],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(r, currentMonth),
              SizedBox(height: r.s(18)),
              _buildAurora(r, currentMonth, monthsWithSeason),
              AnimatedSize(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _expandedMonth == null
                    ? const SizedBox(width: double.infinity, height: 0)
                    : _buildAnimatedPanel(_expandedMonth!, r),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader(_VS r, int currentMonth) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), 0),
      child: Row(
        children: [
          Text('🌱', style: TextStyle(fontSize: r.fs(16))),
          SizedBox(width: r.s(6)),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'В сезоне · ${_monthNames[currentMonth]}',
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.inter(
                  color: _AF.textPrimary,
                  fontSize: r.fs(20),
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
            ),
          ),

          SeasonVineStyleButton(
            scale: widget.scale,
            color: _AF.auroraGreen,
          ),
          SizedBox(width: r.s(6)),

          GestureDetector(
            onTap: widget.onOpenKnowledge,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.fromLTRB(r.s(13), r.s(8), r.s(10), r.s(8)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: _AF.auroraGreen.withOpacity(0.10),
                border: Border.all(
                  color: _AF.auroraGreen.withOpacity(0.28),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Знания',
                    style: GoogleFonts.inter(
                      color: _AF.auroraGreen,
                      fontSize: r.fs(12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: r.s(4)),
                  Icon(Icons.arrow_forward_rounded,
                      color: _AF.auroraGreen, size: r.fs(13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  AURORA RIBBON + MONTH PEAKS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAurora(
      _VS r, int currentMonth, Set<int> monthsWithSeason) {
    final auroraH = r.s(_auroraHeight);
    final positions =
    List<double>.generate(12, (i) => _monthX(i + 1));

    return SizedBox(
      height: auroraH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Scrollable aurora canvas
          SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: _totalWidthScaled,
              height: auroraH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Aurora ribbon
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _flow,
                        builder: (_, __) => CustomPaint(
                          painter: _AuroraPainter(
                            time: _flow.value,
                            currentMonth: currentMonth,
                            monthsWithSeason: monthsWithSeason,
                            expandedMonth: _expandedMonth,
                            monthPositions: positions,
                            peakHeight: _peakHeightScaled,
                            baselineY: _baselineY,
                            brightnessFor: _brightnessFor,
                            scale: widget.scale,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Month labels above peaks
                  for (int m = 1; m <= 12; m++)
                    _buildMonthMarker(m, r, currentMonth, monthsWithSeason),
                ],
              ),
            ),
          ),
          // Edge fade
          _edgeFade(r, isLeft: true),
          _edgeFade(r, isLeft: false),
        ],
      ),
    );
  }

  Widget _edgeFade(_VS r, {required bool isLeft}) {
    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 0,
      width: r.s(28),
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:
              isLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: [_AF.bg, _AF.bg.withOpacity(0.0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthMarker(int month, _VS r, int currentMonth,
      Set<int> monthsWithSeason) {
    final x = _monthX(month);
    final inSeason = monthsWithSeason.contains(month);
    final isCurrent = month == currentMonth;
    final isExpanded = month == _expandedMonth;

    // marker geometry
    final markerW = r.s(46);
    final markerH = r.s(48);
    final peakTop = _peakApexY(month);
    final left = x - markerW / 2;
    final top = peakTop - markerH - r.s(4);

    final numberColor = isCurrent
        ? _AF.auroraPeach
        : isExpanded
        ? _AF.auroraPink
        : inSeason
        ? _AF.textPrimary
        : _AF.textFaint;

    return Positioned(
      left: left,
      top: top,
      width: markerW,
      height: markerH,
      child: GestureDetector(
        onTap: () => _toggleMonth(month),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: isExpanded ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isCurrent || isExpanded)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: r.s(6), vertical: r.s(1)),
                  decoration: BoxDecoration(
                    color: numberColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(r.s(6)),
                  ),
                  child: Text(
                    _monthNames[month],
                    style: GoogleFonts.inter(
                      color: numberColor,
                      fontSize: r.fs(8),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                  ),
                ),
              SizedBox(height: r.s(3)),
              Text(
                '$month',
                style: GoogleFonts.inter(
                  color: numberColor,
                  fontSize: r.fs(isCurrent || isExpanded ? 18 : 14),
                  fontWeight:
                  isCurrent || isExpanded ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: -0.5,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  shadows: isExpanded
                      ? [
                    Shadow(
                      color: _AF.auroraPink.withOpacity(0.8),
                      blurRadius: r.s(12),
                    ),
                  ]
                      : null,
                ),
              ),
              if (!isCurrent && !isExpanded) ...[
                SizedBox(height: r.s(2)),
                Text(
                  _monthNames[month],
                  style: GoogleFonts.inter(
                    color:
                    inSeason ? _AF.textMuted : _AF.textFaint,
                    fontSize: r.fs(9),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EXPANDED PRODUCT PANEL
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAnimatedPanel(int month, _VS r) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(month),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 20),
          child: child,
        ),
      ),
      child: _buildPanel(month, r),
    );
  }

  Widget _buildPanel(int month, _VS r) {
    final meta = metaForMonth(month);
    final products = widget.wellness.productsForMonth(month);
    final monthName = _monthNames[month];

    return Container(
      margin: EdgeInsets.fromLTRB(r.s(16), r.s(14), r.s(16), r.s(16)),
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.s(22)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _AF.auroraPink.withOpacity(0.16),
            _AF.auroraBlue.withOpacity(0.08),
            _AF.surface,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
        border: Border.all(
          color: _AF.auroraPink.withOpacity(0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _AF.auroraPink.withOpacity(0.14),
            blurRadius: r.s(30),
            offset: Offset(0, r.s(-10)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: r.s(40),
                height: r.s(40),
                decoration: BoxDecoration(
                  color: _AF.auroraPink.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _AF.auroraPink.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child:
                Text(meta.emoji, style: TextStyle(fontSize: r.fs(18))),
              ),
              SizedBox(width: r.s(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${meta.label} · $monthName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _AF.textPrimary,
                        fontSize: r.fs(15),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    Text(
                      products.isEmpty
                          ? 'Нет сезонных продуктов'
                          : '${products.length} ${_productsWord(products.length)} в сезоне',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _AF.textMuted,
                        fontSize: r.fs(11),
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _expandedMonth = null),
                child: Container(
                  width: r.s(30),
                  height: r.s(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      color: _AF.textMuted, size: r.fs(16)),
                ),
              ),
            ],
          ),
          SizedBox(height: r.s(14)),
          if (products.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: r.s(18)),
              child: Center(
                child: Text(
                  '🌌  Пусто в этом месяце',
                  style: GoogleFonts.inter(
                    color: _AF.textMuted,
                    fontSize: r.fs(12),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: r.s(96),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (_, __) => SizedBox(width: r.s(8)),
                itemBuilder: (_, i) =>
                    _buildProductCard(products[i], r, i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductKnowledge k, _VS r, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${_expandedMonth}_$index'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 45),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(
          scale: 0.82 + t * 0.18,
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => _openProductSheet(k),
        child: Container(
          width: r.s(82),
          padding:
          EdgeInsets.symmetric(vertical: r.s(12), horizontal: r.s(6)),
          decoration: BoxDecoration(
            color: _AF.cardBg,
            borderRadius: BorderRadius.circular(r.s(16)),
            border: Border.all(color: _AF.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: _AF.auroraPink.withOpacity(0.10),
                blurRadius: r.s(14),
                offset: Offset(0, r.s(4)),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(k.emoji, style: TextStyle(fontSize: r.fs(26))),
              SizedBox(height: r.s(8)),
              Text(
                k.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _AF.textPrimary,
                  fontSize: r.fs(10),
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════════
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
//  AURORA PAINTER
//  Single-pass aurora ribbon with 5 layered strokes + expanded glow
//  + drifting bioluminescent particles.
// ═══════════════════════════════════════════════════════════════════
class _AuroraPainter extends CustomPainter {
  final double time;
  final int currentMonth;
  final Set<int> monthsWithSeason;
  final int? expandedMonth;
  final List<double> monthPositions;
  final double peakHeight;
  final double baselineY;
  final double Function(int) brightnessFor;
  final double scale;

  _AuroraPainter({
    required this.time,
    required this.currentMonth,
    required this.monthsWithSeason,
    required this.expandedMonth,
    required this.monthPositions,
    required this.peakHeight,
    required this.baselineY,
    required this.brightnessFor,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ─── atmospheric glow (widest, blurriest) ───
    _drawLayer(canvas, size,
        strokeW: 46 * scale,
        blur: 22 * scale,
        opacity: 0.10,
        waveAmp: 22 * scale,
        layerPhase: 0.0);
    // ─── outer glow ───
    _drawLayer(canvas, size,
        strokeW: 26 * scale,
        blur: 12 * scale,
        opacity: 0.18,
        waveAmp: 16 * scale,
        layerPhase: 0.7);
    // ─── soft edge ───
    _drawLayer(canvas, size,
        strokeW: 16 * scale,
        blur: 5 * scale,
        opacity: 0.32,
        waveAmp: 10 * scale,
        layerPhase: 1.4);
    // ─── core ribbon ───
    _drawLayer(canvas, size,
        strokeW: 8 * scale,
        blur: 0,
        opacity: 0.55,
        waveAmp: 5 * scale,
        layerPhase: 2.1);
    // ─── inner white-hot streak ───
    _drawLayer(canvas, size,
        strokeW: 2 * scale,
        blur: 0,
        opacity: 0.35,
        waveAmp: 4 * scale,
        layerPhase: 2.8,
        isWhite: true);

    // ─── expanded peak: radial flare + vertical light stream ───
    if (expandedMonth != null) _drawExpandedGlow(canvas, size);

    // ─── drifting particles ───
    _drawParticles(canvas, size);
  }

  void _drawLayer(
      Canvas canvas,
      Size size, {
        required double strokeW,
        required double blur,
        required double opacity,
        required double waveAmp,
        required double layerPhase,
        bool isWhite = false,
      }) {
    final path = Path();
    final step = 4.0 * scale;
    final phase = time * 2 * math.pi * (0.4 + layerPhase * 0.08) + layerPhase;

    for (double x = 0; x <= size.width; x += step) {
      final y = _ribbonY(x, waveAmp, phase);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (blur > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    }

    if (isWhite) {
      paint.color = Colors.white.withOpacity(opacity);
    } else {
      paint.shader = LinearGradient(
        colors: [
          _AF.auroraGreen.withOpacity(opacity),
          _AF.auroraBlue.withOpacity(opacity),
          _AF.auroraPink.withOpacity(opacity),
          _AF.auroraPeach.withOpacity(opacity),
          _AF.auroraPink.withOpacity(opacity),
          _AF.auroraBlue.withOpacity(opacity),
          _AF.auroraGreen.withOpacity(opacity),
        ],
        stops: const [0.0, 0.16, 0.34, 0.5, 0.66, 0.84, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    canvas.drawPath(path, paint);
  }

  double _ribbonY(double x, double waveAmp, double phase) {
    double y = baselineY;

    // peaks from months (stable apex, only brightness varies)
    for (int m = 0; m < 12; m++) {
      final monthX = monthPositions[m];
      final dist = (x - monthX).abs();
      final peakWidth = 55 * scale;
      if (dist > peakWidth) continue;

      final peakNorm = 1 - (dist / peakWidth);
      final peakCurve = peakNorm * peakNorm;

      final monthNum = m + 1;
      final b = brightnessFor(monthNum);

      // current month pulses subtly
      final pulse = monthNum == currentMonth
          ? 1.0 + 0.10 * math.sin(time * 2 * math.pi * 3)
          : 1.0;

      y -= peakCurve * peakHeight * b * pulse;
    }

    // ambient wave texture
    final waveFreq = 0.012 / scale;
    y += math.sin(x * waveFreq + phase) * waveAmp;

    return y;
  }

  void _drawExpandedGlow(Canvas canvas, Size size) {
    final m = expandedMonth!;
    final monthX = monthPositions[m - 1];
    final b = brightnessFor(m);
    final peakY = baselineY - peakHeight * b;

    // radial flare at apex
    final flareRadius = 90 * scale;
    canvas.drawCircle(
      Offset(monthX, peakY),
      flareRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _AF.auroraPink.withOpacity(0.60),
            _AF.auroraPink.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(monthX, peakY),
          radius: flareRadius,
        )),
    );

    // vertical light stream — connects the peak to the product panel
    final streamTop = peakY + 4 * scale;
    final streamBottom = size.height;
    final streamPath = Path()
      ..moveTo(monthX - 14 * scale, streamTop)
      ..lineTo(monthX + 14 * scale, streamTop)
      ..lineTo(monthX + 26 * scale, streamBottom)
      ..lineTo(monthX - 26 * scale, streamBottom)
      ..close();

    canvas.drawPath(
      streamPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _AF.auroraPink.withOpacity(0.45),
            _AF.auroraPink.withOpacity(0.10),
            _AF.auroraPink.withOpacity(0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(monthX - 26 * scale, streamTop,
            52 * scale, streamBottom - streamTop)),
    );

    // bright white core at apex
    canvas.drawCircle(
      Offset(monthX, peakY),
      5 * scale,
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    canvas.drawCircle(
      Offset(monthX, peakY),
      14 * scale,
      Paint()
        ..color = _AF.auroraPink.withOpacity(0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale),
    );
  }

  void _drawParticles(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final colors = [
      _AF.auroraGreen,
      _AF.auroraPink,
      _AF.auroraBlue,
      _AF.auroraPeach,
    ];

    for (int i = 0; i < 40; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.1 + rng.nextDouble() * 0.25;
      final driftX = math.sin(time * 2 * math.pi * speed + i) * 20 * scale;
      final driftY = math.cos(time * 2 * math.pi * speed + i * 1.3) * 9 * scale;
      final x = (baseX + driftX) % size.width;
      final y = (baseY + driftY).clamp(0.0, size.height);
      final rad = (0.7 + rng.nextDouble() * 1.4) * scale;
      final color = colors[i % colors.length];

      canvas.drawCircle(
        Offset(x, y),
        rad,
        Paint()..color = color.withOpacity(0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.time != time ||
          old.currentMonth != currentMonth ||
          old.expandedMonth != expandedMonth ||
          old.monthsWithSeason != monthsWithSeason;
}