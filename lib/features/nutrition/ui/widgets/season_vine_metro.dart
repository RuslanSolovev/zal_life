// lib/features/nutrition/ui/widgets/season_vine_metro.dart
// ═══════════════════════════════════════════════════════════════════
//  METRO edition — London-style subway map
//  12 months as stations on a 3-row line. 90° corners, 45° kinks,
//  green "train" dot runs along the line, tap → branch panel below.
// ═══════════════════════════════════════════════════════════════════
import 'dart:math' as math;
import 'dart:ui' show MaskFilter, BlurStyle, FontFeature;

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
//  Palette — minimal Swiss-metro
// ═══════════════════════════════════════════════════════════════════
class _MF {
  static const bg = Color(0xFFF6F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF0F1210);
  static const textMuted = Color(0xFF6B7268);
  static const textDim = Color(0xFFB8BFB8);

  static const trackInactive = Color(0xFFC8CFC8);
  static const trackActive = Color(0xFF3DDC84);

  static const stationBorder = Color(0xFF111311);
  static const stationGreen = Color(0xFF3DDC84);
  static const stationGreenTint = Color(0xFFD4F4E1);
  static const stationPeach = Color(0xFFFF8A65);
  static const stationPink = Color(0xFFFF6B8B);
  static const deepForest = Color(0xFF426C59);
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
class SeasonVineCardMetro extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCardMetro({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  State<SeasonVineCardMetro> createState() =>
      _SeasonVineCardMetroState();
}

class _SeasonVineCardMetroState extends State<SeasonVineCardMetro>
    with TickerProviderStateMixin {
  late final AnimationController _train;
  int? _expandedMonth;

  static const _monthNames = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  @override
  void initState() {
    super.initState();
    _train = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _train.dispose();
    super.dispose();
  }

  void _toggleMonth(int month) {
    HapticFeedback.selectionClick();
    setState(() {
      _expandedMonth = _expandedMonth == month ? null : month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _VS(widget.scale);
    final cm = widget.wellness.currentMonth;
    final inSeason = widget.wellness.monthsWithSeason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(r, cm),
        SizedBox(height: r.s(18)),
        LayoutBuilder(
          builder: (context, constraints) => _buildBoard(
            constraints: constraints,
            cm: cm,
            inSeason: inSeason,
            r: r,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expandedMonth == null
              ? const SizedBox(width: double.infinity, height: 0)
              : _buildBranchPanel(_expandedMonth!, r),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER — Swiss typographic bar
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader(_VS r, int cm) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(20)),
      child: Row(
        children: [
          Container(
            width: r.s(28),
            height: r.s(28),
            decoration: BoxDecoration(
              color: _MF.trackActive,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '🌱',
              style: TextStyle(fontSize: r.fs(14)),
            ),
          ),
          SizedBox(width: r.s(10)),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'СЕЗОННАЯ ЛИНИЯ',
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.inter(
                      color: _MF.textMuted,
                      fontSize: r.fs(9),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: r.s(3)),
                  Text(
                    '${_monthNames[cm][0].toUpperCase()}${_monthNames[cm].substring(1)} · линия M${cm.toString().padLeft(2, '0')}',
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.inter(
                      color: _MF.text,
                      fontSize: r.fs(16),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SeasonVineStyleButton(
            scale: widget.scale,
            color: _MF.text,
          ),
          SizedBox(width: r.s(6)),

          GestureDetector(
            onTap: widget.onOpenKnowledge,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  r.s(11), r.s(7), r.s(9), r.s(7)),
              decoration: BoxDecoration(
                color: _MF.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _MF.stationBorder.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ЗНАНИЯ',
                    style: GoogleFonts.inter(
                      color: _MF.text,
                      fontSize: r.fs(9),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: r.s(4)),
                  Icon(Icons.arrow_forward_rounded,
                      color: _MF.text, size: r.fs(11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOARD — 3-row metro line
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBoard({
    required BoxConstraints constraints,
    required int cm,
    required Set<int> inSeason,
    required _VS r,
  }) {
    final w = constraints.maxWidth;
    final pad = r.s(22);
    final available = w - pad * 2;

    final d = r.s(14); // 45° diagonal offset
    final y1 = r.s(58);
    final y2 = r.s(178);
    final y3 = r.s(298);
    final rowGap = y2 - y1;

    final step = available / 3;
    final step2 = step - 2 * d / 3;

    // Row 1: months 1-4 going →
    final r1x = [
      pad,
      pad + step,
      pad + 2 * step,
      pad + 3 * step,
    ];
    // Row 2: months 5-8 going ←
    final r2x = [
      pad + 3 * step - d,
      pad + 3 * step - d - step2,
      pad + 3 * step - d - 2 * step2,
      pad + d,
    ];
    // Row 3: months 9-12 going →
    final r3x = [
      pad,
      pad + step,
      pad + 2 * step,
      pad + 3 * step,
    ];

    final stations = <Offset>[
      Offset(r1x[0], y1), Offset(r1x[1], y1),
      Offset(r1x[2], y1), Offset(r1x[3], y1),
      Offset(r2x[0], y2), Offset(r2x[1], y2),
      Offset(r2x[2], y2), Offset(r2x[3], y2),
      Offset(r3x[0], y3), Offset(r3x[1], y3),
      Offset(r3x[2], y3), Offset(r3x[3], y3),
    ];

    // Build polyline segments between consecutive stations
    final segments = <List<Offset>>[];
    for (int i = 0; i < 11; i++) {
      final from = stations[i];
      final to = stations[i + 1];

      if (i == 3) {
        // Month 4 → Month 5 (S-bend down-left)
        segments.add([
          from,
          Offset(from.dx, from.dy + d),
          Offset(from.dx - d, from.dy + 2 * d),
          Offset(from.dx - d, to.dy),
        ]);
      } else if (i == 7) {
        // Month 8 → Month 9 (S-bend down-left)
        segments.add([
          from,
          Offset(from.dx, from.dy + d),
          Offset(from.dx - d, from.dy + 2 * d),
          Offset(from.dx - d, to.dy),
        ]);
      } else {
        segments.add([from, to]);
      }
    }

    // Precompute per-station t along the full path (for train stop)
    final stationTs = _computeStationTs(stations, segments);

    final labelAbove = <bool>[
      true, true, true, true, // 1-4
      false, true, true, true, // 5 (below), 6-8 above
      false, true, true, true, // 9 (below), 10-12 above
    ];

    final boardHeight = y3 + r.s(50);

    return SizedBox(
      height: boardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Track + train (painter)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _train,
                builder: (_, __) {
                  final trainT = _expandedMonth != null
                      ? stationTs[_expandedMonth! - 1]
                      : _train.value;
                  return CustomPaint(
                    painter: _MetroPainter(
                      stations: stations,
                      segments: segments,
                      monthsWithSeason: inSeason,
                      currentMonth: cm,
                      expandedMonth: _expandedMonth,
                      trainT: trainT,
                      scale: widget.scale,
                    ),
                  );
                },
              ),
            ),
          ),
          // Stations + labels
          for (int m = 1; m <= 12; m++)
            ..._buildStationWidgets(
              month: m,
              position: stations[m - 1],
              isCurrent: m == cm,
              inSeason: inSeason.contains(m),
              isExpanded: m == _expandedMonth,
              labelAbove: labelAbove[m - 1],
              r: r,
              constraints: constraints,
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STATION WIDGETS
  // ═══════════════════════════════════════════════════════════════
  List<Widget> _buildStationWidgets({
    required int month,
    required Offset position,
    required bool isCurrent,
    required bool inSeason,
    required bool isExpanded,
    required bool labelAbove,
    required _VS r,
    required BoxConstraints constraints,
  }) {
    final hit = r.s(36);
    final labelW = r.s(64);
    final labelH = r.s(14);

    // Station hit-target
    final stationWidget = Positioned(
      left: position.dx - hit / 2,
      top: position.dy - hit / 2,
      width: hit,
      height: hit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggleMonth(month),
        child: Center(
          child: _StationDot(
            size: r.s(18),
            isCurrent: isCurrent,
            inSeason: inSeason,
            isExpanded: isExpanded,
            r: r,
          ),
        ),
      ),
    );

    // Label
    final labelTop = labelAbove
        ? position.dy - hit / 2 - labelH
        : position.dy + hit / 2;

    final labelColor = isCurrent || isExpanded
        ? _MF.text
        : inSeason
        ? _MF.text
        : _MF.textMuted;

    final label = Positioned(
      left: (position.dx - labelW / 2)
          .clamp(0.0, constraints.maxWidth - labelW),
      top: labelTop,
      width: labelW,
      height: labelH,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding:
            EdgeInsets.symmetric(horizontal: r.s(4), vertical: r.s(1)),
            decoration: BoxDecoration(
              color: _MF.bg,
              borderRadius: BorderRadius.circular(r.s(2)),
            ),
            child: Text(
              _monthNames[month],
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: GoogleFonts.inter(
                color: labelColor,
                fontSize: r.fs(9),
                fontWeight: isCurrent || isExpanded
                    ? FontWeight.w800
                    : FontWeight.w600,
                letterSpacing: 0.4,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );

    return [stationWidget, label];
  }

  // ═══════════════════════════════════════════════════════════════
  //  BRANCH PANEL — product list as metro stations
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBranchPanel(int month, _VS r) {
    final meta = metaForMonth(month);
    final products = widget.wellness.productsForMonth(month);
    final monthName = _monthNames[month];

    return TweenAnimationBuilder<double>(
      key: ValueKey(month),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 12),
          child: child,
        ),
      ),
      child: Container(
        margin: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(0)),
        decoration: BoxDecoration(
          color: _MF.surface,
          borderRadius: BorderRadius.circular(r.s(18)),
          border: Border.all(
            color: _MF.stationBorder.withOpacity(0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: r.s(24),
              offset: Offset(0, r.s(8)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                  r.s(14), r.s(14), r.s(12), r.s(10)),
              child: Row(
                children: [
                  _LineBadge(
                    color: isInSeasonFor(month) ? _MF.trackActive : _MF.stationPeach,
                    number: month,
                    r: r,
                  ),
                  SizedBox(width: r.s(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${meta.label} · $monthName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _MF.text,
                            fontSize: r.fs(14),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: r.s(2)),
                        Text(
                          products.isEmpty
                              ? 'конечная · без остановок'
                              : '${products.length} ${_productsWord(products.length)} · '
                              'до конца линии',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _MF.textMuted,
                            fontSize: r.fs(10),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _expandedMonth = null),
                    child: Container(
                      width: r.s(28),
                      height: r.s(28),
                      decoration: BoxDecoration(
                        color: _MF.bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          color: _MF.textMuted, size: r.fs(14)),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: _MF.stationBorder.withOpacity(0.06),
            ),
            if (products.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: r.s(20)),
                child: Center(
                  child: Text(
                    '— КОНЕЧНАЯ —',
                    style: GoogleFonts.inter(
                      color: _MF.textDim,
                      fontSize: r.fs(10),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(vertical: r.s(4)),
                child: Column(
                  children: [
                    for (int i = 0; i < products.length; i++)
                      _buildBranchRow(
                        index: i,
                        product: products[i],
                        isFirst: i == 0,
                        isLast: i == products.length - 1,
                        lineColor: isInSeasonFor(month)
                            ? _MF.trackActive
                            : _MF.stationPeach,
                        r: r,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchRow({
    required int index,
    required ProductKnowledge product,
    required bool isFirst,
    required bool isLast,
    required Color lineColor,
    required _VS r,
  }) {
    final num = (index + 1).toString().padLeft(2, '0');
    final lineW = r.s(2);
    final dotS = r.s(8);

    return GestureDetector(
      onTap: () => _openProductSheet(product),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: r.s(14), vertical: r.s(10)),
        child: Row(
          children: [
            // Left: mini station marker on vertical branch
            SizedBox(
              width: r.s(16),
              height: r.s(26),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Line above (not for first)
                  if (!isFirst)
                    Positioned(
                      top: 0,
                      bottom: r.s(13),
                      child: Container(
                        width: lineW,
                        color: lineColor.withOpacity(0.55),
                      ),
                    ),
                  // Line below (not for last)
                  if (!isLast)
                    Positioned(
                      top: r.s(13),
                      bottom: 0,
                      child: Container(
                        width: lineW,
                        color: lineColor.withOpacity(0.55),
                      ),
                    ),
                  // Station dot
                  Container(
                    width: dotS,
                    height: dotS,
                    decoration: BoxDecoration(
                      color: _MF.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: lineColor, width: 1.8),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: r.s(6)),
            // Number
            SizedBox(
              width: r.s(26),
              child: Text(
                num,
                style: GoogleFonts.inter(
                  color: _MF.textMuted,
                  fontSize: r.fs(10),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  height: 1.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            // Emoji
            Text(product.emoji, style: TextStyle(fontSize: r.fs(20))),
            SizedBox(width: r.s(10)),
            // Name
            Expanded(
              child: Text(
                product.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: _MF.text,
                  fontSize: r.fs(12),
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  height: 1.15,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: _MF.textDim, size: r.fs(10)),
          ],
        ),
      ),
    );
  }

  bool isInSeasonFor(int month) =>
      widget.wellness.monthsWithSeason.contains(month);

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

  // ═══════════════════════════════════════════════════════════════
  //  COMPUTE t FOR EACH STATION ALONG THE FULL PATH
  // ═══════════════════════════════════════════════════════════════
  List<double> _computeStationTs(
      List<Offset> stations, List<List<Offset>> segments) {
    final lengths = <double>[];
    double total = 0;
    for (final seg in segments) {
      double segLen = 0;
      for (int i = 1; i < seg.length; i++) {
        final dx = seg[i].dx - seg[i - 1].dx;
        final dy = seg[i].dy - seg[i - 1].dy;
        segLen += math.sqrt(dx * dx + dy * dy);
      }
      lengths.add(segLen);
      total += segLen;
    }
    final ts = <double>[0.0];
    double acc = 0;
    for (int i = 0; i < lengths.length; i++) {
      acc += lengths[i];
      ts.add(acc / total);
    }
    return ts; // 12 entries
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STATION DOT
// ═══════════════════════════════════════════════════════════════════
class _StationDot extends StatelessWidget {
  final double size;
  final bool isCurrent;
  final bool inSeason;
  final bool isExpanded;
  final _VS r;

  const _StationDot({
    required this.size,
    required this.isCurrent,
    required this.inSeason,
    required this.isExpanded,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    // Out-of-season: white fill, black border
    if (!isCurrent && !inSeason && !isExpanded) {
      return _circle(
        diameter: size * 0.85,
        fill: _MF.surface,
        border: _MF.stationBorder.withOpacity(0.55),
        borderW: 1.4,
        opacity: 0.55,
      );
    }

    // In-season: green-tinted fill, green border + 4pt downward tick
    if (inSeason && !isCurrent && !isExpanded) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.85,
            child: Container(
              width: 2,
              height: r.s(6),
              color: _MF.trackActive,
            ),
          ),
          _circle(
            diameter: size * 0.85,
            fill: _MF.stationGreenTint,
            border: _MF.trackActive,
            borderW: 2.0,
          ),
        ],
      );
    }

    // Current: solid peach, double ring (transfer)
    if (isCurrent && !isExpanded) {
      return Container(
        width: size * 1.35,
        height: size * 1.35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _MF.surface,
          border: Border.all(
            color: _MF.stationPeach,
            width: 2.4,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: size * 0.60,
          height: size * 0.60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _MF.stationPeach,
          ),
        ),
      );
    }

    // Expanded: pink-filled transfer hub, pulsing halo
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (_, t, __) => Container(
        width: size * (1.35 + 0.2 * t),
        height: size * (1.35 + 0.2 * t),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _MF.surface,
          border: Border.all(
            color: _MF.stationPink,
            width: 2.4,
          ),
          boxShadow: [
            BoxShadow(
              color: _MF.stationPink.withOpacity(0.30),
              blurRadius: r.s(12),
              spreadRadius: r.s(1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: size * 0.55,
          height: size * 0.55,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _MF.stationPink,
          ),
        ),
      ),
    );
  }

  Widget _circle({
    required double diameter,
    required Color fill,
    required Color border,
    required double borderW,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: border, width: borderW),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LINE BADGE — like a London tube line label
// ═══════════════════════════════════════════════════════════════════
class _LineBadge extends StatelessWidget {
  final Color color;
  final int number;
  final _VS r;

  const _LineBadge({
    required this.color,
    required this.number,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: r.s(6),
          height: r.s(28),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(r.s(3)),
          ),
        ),
        SizedBox(width: r.s(6)),
        Text(
          'M${number.toString().padLeft(2, '0')}',
          style: GoogleFonts.inter(
            color: _MF.text,
            fontSize: r.fs(12),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  METRO PAINTER — track + train
// ═══════════════════════════════════════════════════════════════════
class _MetroPainter extends CustomPainter {
  final List<Offset> stations;
  final List<List<Offset>> segments;
  final Set<int> monthsWithSeason;
  final int currentMonth;
  final int? expandedMonth;
  final double trainT;
  final double scale;

  _MetroPainter({
    required this.stations,
    required this.segments,
    required this.monthsWithSeason,
    required this.currentMonth,
    required this.expandedMonth,
    required this.trainT,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackW = 4.5 * scale;

    // Build full path
    final fullPath = Path();
    if (segments.isEmpty) return;
    fullPath.moveTo(segments[0][0].dx, segments[0][0].dy);
    for (final seg in segments) {
      for (int i = 1; i < seg.length; i++) {
        fullPath.lineTo(seg[i].dx, seg[i].dy);
      }
    }

    // 1. Inactive track (gray)
    canvas.drawPath(
      fullPath,
      Paint()
        ..color = _MF.trackInactive
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackW
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 2. Active segments (green)
    for (int i = 0; i < segments.length; i++) {
      final m1 = i + 1;
      final m2 = i + 2;
      final active = monthsWithSeason.contains(m1) ||
          monthsWithSeason.contains(m2) ||
          m1 == currentMonth ||
          m2 == currentMonth ||
          m1 == expandedMonth ||
          m2 == expandedMonth;
      if (!active) continue;

      final segPath = Path();
      final seg = segments[i];
      segPath.moveTo(seg[0].dx, seg[0].dy);
      for (int j = 1; j < seg.length; j++) {
        segPath.lineTo(seg[j].dx, seg[j].dy);
      }

      canvas.drawPath(
        segPath,
        Paint()
          ..color = _MF.trackActive
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackW
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // 3. Train dot — glowing, along the whole path
    if (trainT > 0 && trainT < 1) {
      for (final metric in fullPath.computeMetrics()) {
        final tangent = metric.getTangentForOffset(metric.length * trainT);
        if (tangent == null) continue;
        final pos = tangent.position;

        // Outer glow
        canvas.drawCircle(
          pos,
          12 * scale,
          Paint()
            ..color = _MF.trackActive.withOpacity(0.30)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale),
        );
        // White ring
        canvas.drawCircle(
          pos,
          6.5 * scale,
          Paint()..color = _MF.surface,
        );
        // Green core
        canvas.drawCircle(
          pos,
          4.5 * scale,
          Paint()..color = _MF.trackActive,
        );
      }
    }

    // 4. Expanded: vertical branch going down from station
    if (expandedMonth != null &&
        expandedMonth! >= 1 &&
        expandedMonth! <= 12) {
      final expPos = stations[expandedMonth! - 1];
      final branchTop = expPos.dy + 8 * scale;
      final branchBottom = expPos.dy + 40 * scale;
      final branchColor = monthsWithSeason.contains(expandedMonth!)
          ? _MF.trackActive
          : _MF.stationPink;

      canvas.drawLine(
        Offset(expPos.dx, branchTop),
        Offset(expPos.dx, branchBottom),
        Paint()
          ..color = branchColor.withOpacity(0.55)
          ..strokeWidth = 2 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MetroPainter old) =>
      old.trainT != trainT ||
          old.currentMonth != currentMonth ||
          old.expandedMonth != expandedMonth ||
          old.monthsWithSeason != monthsWithSeason;
}