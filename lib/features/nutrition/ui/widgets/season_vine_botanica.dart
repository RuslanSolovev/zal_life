// lib/features/nutrition/ui/widgets/season_vine_botanica.dart
// ═══════════════════════════════════════════════════════════════════
//  PAPER BOTANICA edition — botanical album / herbarium concept
//  Replaces glass/neon with torn paper, watercolor & pencil ink.
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
//  Palette — aged paper, ink, watercolor
// ═══════════════════════════════════════════════════════════════════
class _PB {
  static const paper = Color(0xFFF4EDE0);
  static const paperDeep = Color(0xFFE8DCC8);
  static const cream = Color(0xFFFCF8EE);
  static const ink = Color(0xFF2C3E3A);
  static const inkMuted = Color(0xFF6B7268);
  static const inkFaint = Color(0xFFAFAA9E);
  static const peach = Color(0xFFC79475);
  static const vividPeach = Color(0xFFD68B65);
  static const sage = Color(0xFF8CAB93);
  static const sageDeep = Color(0xFF426C59);
  static const gold = Color(0xFFE7D9B8);
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
class SeasonVineCardBotanica extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCardBotanica({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  State<SeasonVineCardBotanica> createState() =>
      _SeasonVineCardBotanicaState();
}

class _SeasonVineCardBotanicaState extends State<SeasonVineCardBotanica>
    with TickerProviderStateMixin {
  late final AnimationController _sway;
  int? _expandedMonth;

  static const _monthNames = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  @override
  void initState() {
    super.initState();
    _sway = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat(reverse: true);
    _expandedMonth = null; // tap-to-open for the demo
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  void _toggleMonth(int month) {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    setState(() {
      _expandedMonth = _expandedMonth == month ? null : month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _VS(widget.scale);
    final currentMonth = widget.wellness.currentMonth;
    final monthsWithSeason = widget.wellness.monthsWithSeason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─────────────── HEADER ───────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: r.s(20)),
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
                    style: GoogleFonts.fraunces(
                      color: _PB.ink,
                      fontSize: r.fs(22),
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              SeasonVineStyleButton(
                scale: widget.scale,
                color: _PB.ink,
              ),
              SizedBox(width: r.s(6)),
              _press(
                onTap: widget.onOpenKnowledge,
                child: _knowledgePill(r),
              ),
            ],
          ),
        ),
        SizedBox(height: r.s(24)),

        // ─────────────── VINE (botanical album page) ───────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: r.s(6)),
          child: LayoutBuilder(
            builder: (context, constraints) => _buildVine(
              constraints: constraints,
              currentMonth: currentMonth,
              monthsWithSeason: monthsWithSeason,
              r: r,
            ),
          ),
        ),

        // ─────────────── EXPANDED ALBUM SPREAD ───────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expandedMonth == null
              ? const SizedBox(width: double.infinity, height: 0)
              : TweenAnimationBuilder<double>(
            key: ValueKey(_expandedMonth),
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
            child: _buildAlbumSpread(_expandedMonth!, r),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  "ЗНАНИЯ" — paper pill
  // ═══════════════════════════════════════════════════════════════
  Widget _knowledgePill(_VS r) {
    return Container(
      padding: EdgeInsets.fromLTRB(r.s(12), r.s(7), r.s(9), r.s(7)),
      decoration: BoxDecoration(
        color: _PB.cream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _PB.inkFaint.withOpacity(0.40),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Знания',
            style: GoogleFonts.fraunces(
              color: _PB.ink,
              fontSize: r.fs(12),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          SizedBox(width: r.s(4)),
          Icon(
            Icons.arrow_forward_rounded,
            color: _PB.ink.withOpacity(0.75),
            size: r.fs(13),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  VINE LAYOUT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildVine({
    required BoxConstraints constraints,
    required int currentMonth,
    required Set<int> monthsWithSeason,
    required _VS r,
  }) {
    final w = constraints.maxWidth;
    final pageW = r.s(60);
    final pageH = r.s(78);
    final rowH = r.s(174);
    final topY = r.s(80);
    final waveAmp = r.s(28);
    final bulge = r.s(52);
    final leftX = pageW / 2 + r.s(12);
    final rightX = w - pageW / 2 - r.s(12);

    final points = <Offset>[];
    for (int row = 0; row < 3; row++) {
      final isEven = row.isEven;
      final baseY = topY + row * rowH;
      for (int col = 0; col < 4; col++) {
        final realCol = isEven ? col : (3 - col);
        final xFrac = realCol / 3;
        final x = leftX + xFrac * (rightX - leftX);
        final wave = math.sin(xFrac * math.pi * 2 + (isEven ? 0 : math.pi));
        final y = baseY + wave * waveAmp;
        points.add(Offset(x, y));
      }
    }

    final totalH = topY + 2 * rowH + pageH + r.s(40);

    return SizedBox(
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ..._buildInkSplatters(w, totalH, r),
          // Pencil-dotted connecting line (static)
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PencilLinePainter(
                  points: points,
                  monthsWithSeason: monthsWithSeason,
                  currentMonth: currentMonth,
                  bulge: bulge,
                ),
              ),
            ),
          ),
          // Torn paper pages
          for (int i = 0; i < 12; i++)
            Positioned(
              left: points[i].dx - (pageW + r.s(32)) / 2,
              top: points[i].dy - (pageH + r.s(32)) / 2,
              child: _MonthPage(
                month: i + 1,
                monthName: _monthNames[i + 1],
                width: pageW,
                height: pageH,
                isCurrent: i + 1 == currentMonth,
                inSeason: monthsWithSeason.contains(i + 1),
                isExpanded: i + 1 == _expandedMonth,
                products: widget.wellness.productsForMonth(i + 1),
                sway: _sway,
                swayPhase: i,
                r: r,
                onTap: () => _toggleMonth(i + 1),
              ),
            ),
        ],
      ),
    );
  }

  // Static ink splatters — subtle paper decoration
  List<Widget> _buildInkSplatters(double w, double h, _VS r) {
    final dots = <Widget>[];
    final rng = math.Random(2024);
    for (int i = 0; i < 14; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      final size = r.s(1.5 + rng.nextDouble() * 3);
      final color = i.isEven
          ? _PB.ink.withOpacity(0.04 + rng.nextDouble() * 0.04)
          : _PB.peach.withOpacity(0.06 + rng.nextDouble() * 0.04);
      dots.add(Positioned(
        left: x, top: y,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ));
    }
    return dots;
  }

  // ═══════════════════════════════════════════════════════════════
  //  EXPANDED ALBUM SPREAD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAlbumSpread(int month, _VS r) {
    final meta = metaForMonth(month);
    final products = widget.wellness.productsForMonth(month);
    final monthName = _monthNames[month];

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(0)),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: r.s(24),
              offset: Offset(0, r.s(12)),
            ),
          ],
        ),
        child: ClipPath(
          clipper: _TornPaperClipper(seed: month * 71, roughness: 3.0),
          child: Container(
            color: _PB.cream,
            child: Stack(
              children: [
                // Inner top shadow (book depth)
                Positioned.fill(
                  child: CustomPaint(painter: const _AlbumShadowPainter()),
                ),
                // Book spine (center vertical rule)
                Positioned(
                  left: 0, right: 0, top: 0, bottom: 0,
                  child: Center(
                    child: Container(
                      width: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            _PB.inkFaint.withOpacity(0.35),
                            _PB.inkFaint.withOpacity(0.35),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.2, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(r.s(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Album header
                      Row(
                        children: [
                          Container(
                            width: r.s(36), height: r.s(36),
                            decoration: BoxDecoration(
                              color: _PB.paper,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _PB.inkFaint.withOpacity(0.3),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(meta.emoji,
                                style: TextStyle(fontSize: r.fs(18))),
                          ),
                          SizedBox(width: r.s(10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${meta.label} · $monthName',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.fraunces(
                                    color: _PB.ink,
                                    fontSize: r.fs(17),
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    height: 1.15,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  products.isEmpty
                                      ? 'Нет сезонных продуктов'
                                      : '${products.length} ${_productsWord(products.length)} в сезоне',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.fraunces(
                                    color: _PB.inkMuted,
                                    fontSize: r.fs(11),
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _expandedMonth = null),
                            child: Container(
                              width: r.s(28), height: r.s(28),
                              decoration: BoxDecoration(
                                color: _PB.paper,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _PB.inkFaint.withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: _PB.inkMuted,
                                size: r.fs(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r.s(14)),
                      if (products.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: r.s(20)),
                          child: Center(
                            child: Text(
                              '🌾  Пусто в этом месяце',
                              style: GoogleFonts.fraunces(
                                color: _PB.inkMuted,
                                fontSize: r.fs(12),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                      else
                        _buildProductGrid(products, meta, r),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(
      List<ProductKnowledge> products, SeasonMeta meta, _VS r) {
    final rows = <Widget>[];
    for (int i = 0; i < products.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: r.s(3)),
          child: Row(
            children: [
              Expanded(child: _botanicalCard(products[i], meta, r)),
              SizedBox(width: r.s(10)),
              Expanded(
                child: i + 1 < products.length
                    ? _botanicalCard(products[i + 1], meta, r)
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _botanicalCard(ProductKnowledge k, SeasonMeta meta, _VS r) {
    return GestureDetector(
      onTap: () => _openProductSheet(k),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: r.s(9), horizontal: r.s(9)),
        decoration: BoxDecoration(
          color: _PB.paper,
          border: Border.all(
            color: _PB.inkFaint.withOpacity(0.30),
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(r.s(2)),
        ),
        child: Row(
          children: [
            Text(k.emoji, style: TextStyle(fontSize: r.fs(20))),
            SizedBox(width: r.s(8)),
            Expanded(
              child: Text(
                k.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fraunces(
                  color: _PB.ink,
                  fontSize: r.fs(12),
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
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

  Widget _press({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }

  String _productsWord(int n) {
    if (n == 1) return 'продукт';
    if (n >= 2 && n <= 4) return 'продукта';
    return 'продуктов';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MONTH PAGE — torn paper card
// ═══════════════════════════════════════════════════════════════════
class _MonthPage extends StatelessWidget {
  final int month;
  final String monthName;
  final double width;
  final double height;
  final bool isCurrent;
  final bool inSeason;
  final bool isExpanded;
  final List<ProductKnowledge> products;
  final Animation<double> sway;
  final int swayPhase;
  final _VS r;
  final VoidCallback onTap;

  const _MonthPage({
    required this.month,
    required this.monthName,
    required this.width,
    required this.height,
    required this.isCurrent,
    required this.inSeason,
    required this.isExpanded,
    required this.products,
    required this.sway,
    required this.swayPhase,
    required this.r,
    required this.onTap,
  });

  double get _baseTilt {
    final rng = math.Random(month * 17);
    return (rng.nextDouble() - 0.5) * 0.10; // ±0.05 rad ≈ ±2.9°
  }

  @override
  Widget build(BuildContext context) {
    final meta = metaForMonth(month);
    final isHighlighted = isCurrent || isExpanded;
    final hasFruit = products.isNotEmpty;
    final fruitEmoji = hasFruit ? products.first.emoji : null;
    final extraCount =
    products.length > 1 ? '+${products.length - 1}' : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: sway,
        builder: (_, child) {
          final phase = swayPhase * 0.6;
          final swayAngle =
              math.sin(sway.value * math.pi * 2 + phase) * 0.008;
          return Transform.rotate(
            angle: _baseTilt + swayAngle,
            alignment: Alignment.bottomCenter,
            child: child,
          );
        },
        child: AnimatedScale(
          scale: isExpanded ? 1.15 : (isCurrent ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: width + r.s(32),
                height: height + r.s(32),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient paper shadow under the page
                    Positioned(
                      left: r.s(14), top: r.s(18),
                      right: r.s(14), bottom: r.s(10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(r.s(4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: r.s(10),
                              offset: Offset(0, r.s(4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Page (with 3D flip on expand)
                    TweenAnimationBuilder<double>(
                      key: ValueKey('flip_${isExpanded}_$month'),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, child) {
                        if (!isExpanded) return child!;
                        final swing = math.sin(t * math.pi) * 0.22;
                        final lift = math.sin(t * math.pi) * 3.5;
                        return Transform(
                          alignment: Alignment.centerLeft,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(-swing)
                            ..translate(0.0, -lift),
                          child: child,
                        );
                      },
                      child: _buildPage(
                          meta, isHighlighted, fruitEmoji, extraCount),
                    ),
                  ],
                ),
              ),
              SizedBox(height: r.s(7)),
              Text(
                monthName,
                style: GoogleFonts.fraunces(
                  color: isHighlighted
                      ? _PB.ink
                      : (inSeason
                      ? _PB.ink
                      : _PB.inkMuted.withOpacity(0.70)),
                  fontSize: r.fs(11),
                  fontWeight:
                  isHighlighted ? FontWeight.w700 : FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(SeasonMeta meta, bool isHighlighted,
      String? fruitEmoji, String? extraCount) {
    final paperColor = (!inSeason && !isCurrent) ? _PB.paper : _PB.cream;
    final Color? watercolor = isExpanded
        ? meta.accent
        : isCurrent
        ? _PB.vividPeach
        : inSeason
        ? _PB.sage
        : null;
    final double wIntensity =
    isExpanded ? 1.0 : (isCurrent ? 0.95 : 0.75);

    return Container(
      width: width,
      height: height,
      child: ClipPath(
        clipper: _TornPaperClipper(seed: month * 31),
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: paperColor)),

            // Watercolor bleed
            if (watercolor != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _WatercolorPainter(
                    color: watercolor,
                    seed: month,
                    intensity: wIntensity,
                  ),
                ),
              ),

            // Paper grain
            Positioned.fill(
              child: CustomPaint(painter: _PaperGrainPainter(seed: month)),
            ),

            // Handwritten month name in corner
            Positioned(
              left: r.s(7), top: r.s(5),
              child: Text(
                monthName,
                style: GoogleFonts.fraunces(
                  color: isHighlighted ? _PB.ink : _PB.inkMuted,
                  fontSize: r.fs(8),
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            // Hand-drawn checkmark for in-season
            if (inSeason && !isExpanded)
              Positioned(
                right: r.s(6), top: r.s(6),
                child: CustomPaint(
                  size: Size(r.s(11), r.s(9)),
                  painter: const _HandCheckPainter(),
                ),
              ),

            // Month number — large Fraunces italic
            Align(
              alignment: const Alignment(0, -0.05),
              child: Text(
                '$month',
                style: GoogleFonts.fraunces(
                  color: isHighlighted
                      ? _PB.ink
                      : (inSeason
                      ? _PB.ink
                      : _PB.inkMuted.withOpacity(0.55)),
                  fontSize: r.fs(26),
                  fontWeight:
                  isHighlighted ? FontWeight.w700 : FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Pencil circle around the current month number
            if (isCurrent && !isExpanded)
              Positioned.fill(
                child: CustomPaint(
                  painter: _PencilCirclePainter(
                    color: _PB.vividPeach.withOpacity(0.55),
                  ),
                ),
              ),

            // Product emoji
            if (fruitEmoji != null)
              Positioned(
                left: 0, right: 0, bottom: r.s(8),
                child: Center(
                  child: Text(fruitEmoji,
                      style: TextStyle(fontSize: r.fs(18))),
                ),
              ),

            // "+N" handwritten badge
            if (extraCount != null)
              Positioned(
                right: r.s(6), bottom: r.s(6),
                child: Text(
                  extraCount,
                  style: GoogleFonts.fraunces(
                    color: _PB.ink,
                    fontSize: r.fs(9),
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TORN PAPER CLIPPER
// ═══════════════════════════════════════════════════════════════════
class _TornPaperClipper extends CustomClipper<Path> {
  final int seed;
  final double roughness;
  const _TornPaperClipper({required this.seed, this.roughness = 2.5});

  @override
  Path getClip(Size size) {
    final rng = math.Random(seed);
    final path = Path();
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    path.moveTo(corners[0].dx, corners[0].dy);
    for (int i = 0; i < 4; i++) {
      _tornEdge(path, corners[i], corners[(i + 1) % 4], rng, roughness);
    }
    path.close();
    return path;
  }

  void _tornEdge(
      Path path, Offset from, Offset to, math.Random rng, double roughness) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 0.001) return;
    final nx = -dy / len;
    final ny = dx / len;

    final segments = (len / 4).round().clamp(8, 30);
    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final baseX = from.dx + dx * t;
      final baseY = from.dy + dy * t;
      if (i == segments) {
        path.lineTo(baseX, baseY);
        return;
      }
      final r = rng.nextDouble();
      double offset;
      if (r < 0.08) {
        offset = (rng.nextBool() ? 1 : -1) * roughness * 1.8;
      } else if (r < 0.25) {
        offset = (rng.nextDouble() - 0.5) * roughness * 0.6;
      } else {
        offset = 0;
      }
      path.lineTo(baseX + nx * offset, baseY + ny * offset);
    }
  }

  @override
  bool shouldReclip(covariant _TornPaperClipper old) =>
      old.seed != seed || old.roughness != roughness;
}

// ═══════════════════════════════════════════════════════════════════
//  PAPER GRAIN
// ═══════════════════════════════════════════════════════════════════
class _PaperGrainPainter extends CustomPainter {
  final int seed;
  const _PaperGrainPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed + 7);
    final paint = Paint()
      ..color = _PB.ink.withOpacity(0.03)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 30; i++) {
      final y = rng.nextDouble() * size.height;
      final x1 = rng.nextDouble() * size.width * 0.75;
      final x2 = x1 + rng.nextDouble() * size.width * 0.25;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter old) => old.seed != seed;
}

// ═══════════════════════════════════════════════════════════════════
//  WATERCOLOR BLEED
// ═══════════════════════════════════════════════════════════════════
class _WatercolorPainter extends CustomPainter {
  final Color color;
  final int seed;
  final double intensity;
  const _WatercolorPainter({
    required this.color,
    required this.seed,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final center = Offset(size.width * 0.5, size.height * 0.55);

    // Soft overlapping bleeds (watercolor feel)
    for (int i = 0; i < 7; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = rng.nextDouble() * size.width * 0.30;
      final rad = size.width * (0.14 + rng.nextDouble() * 0.30);
      final c = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist,
      );
      final opacity = intensity * (0.06 + rng.nextDouble() * 0.10);
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * 0.5),
      );
    }

    // Core wash
    canvas.drawCircle(
      center,
      size.width * 0.35,
      Paint()
        ..color = color.withOpacity(intensity * 0.42)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.13),
    );
  }

  @override
  bool shouldRepaint(covariant _WatercolorPainter old) =>
      old.intensity != intensity ||
          old.color != color ||
          old.seed != seed;
}

// ═══════════════════════════════════════════════════════════════════
//  HAND-DRAWN CHECKMARK
// ═══════════════════════════════════════════════════════════════════
class _HandCheckPainter extends CustomPainter {
  const _HandCheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width * 0.10, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.32, size.height * 0.55,
      size.width * 0.42, size.height * 0.85,
    );
    path.quadraticBezierTo(
      size.width * 0.60, size.height * 0.30,
      size.width * 0.95, size.height * 0.08,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _PB.sageDeep.withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HandCheckPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  PENCIL CIRCLE (marks the current month number)
// ═══════════════════════════════════════════════════════════════════
class _PencilCirclePainter extends CustomPainter {
  final Color color;
  const _PencilCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final rx = size.width * 0.26;
    final ry = size.height * 0.10;
    final rng = math.Random(42);
    final path = Path();
    const steps = 36;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = -math.pi / 2 + t * math.pi * 2;
      final jitter = 1.0 + (rng.nextDouble() - 0.5) * 0.15;
      final x = center.dx + math.cos(angle) * rx * jitter;
      final y = center.dy + math.sin(angle) * ry * jitter;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PencilCirclePainter old) =>
      old.color != color;
}

// ═══════════════════════════════════════════════════════════════════
//  PENCIL DOTTED LINE (replaces the neon vine)
// ═══════════════════════════════════════════════════════════════════
class _PencilLinePainter extends CustomPainter {
  final List<Offset> points;
  final Set<int> monthsWithSeason;
  final int currentMonth;
  final double bulge;

  _PencilLinePainter({
    required this.points,
    required this.monthsWithSeason,
    required this.currentMonth,
    required this.bulge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final isTransition = (i + 1) % 4 == 0 && i < points.length - 2;
      final isActive = monthsWithSeason.contains(i + 1) ||
          monthsWithSeason.contains(i + 2);

      final path = Path();
      path.moveTo(p1.dx, p1.dy);

      if (isTransition) {
        final rowIdx = i ~/ 4;
        final dir = rowIdx.isEven ? 1.0 : -1.0;
        final cx = p1.dx + dir * bulge;
        final cy = (p1.dy + p2.dy) / 2;
        path.quadraticBezierTo(cx, cy, p2.dx, p2.dy);
      } else {
        final midX = (p1.dx + p2.dx) / 2;
        final midY = (p1.dy + p2.dy) / 2 + 4;
        path.quadraticBezierTo(midX, midY, p2.dx, p2.dy);
      }

      final paint = Paint()
        ..color = isActive
            ? _PB.sageDeep.withOpacity(0.60)
            : _PB.inkFaint.withOpacity(0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 1.5 : 1.2
        ..strokeCap = StrokeCap.round;

      _drawDotted(canvas, path, paint);
    }
  }

  void _drawDotted(Canvas canvas, Path path, Paint paint,
      {double dash = 2.5, double gap = 3.5}) {
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final end = math.min(dist + dash, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PencilLinePainter old) =>
      old.monthsWithSeason != monthsWithSeason ||
          old.currentMonth != currentMonth ||
          !identical(old.points, points);
}

// ═══════════════════════════════════════════════════════════════════
//  ALBUM INNER SHADOW
// ═══════════════════════════════════════════════════════════════════
class _AlbumShadowPainter extends CustomPainter {
  const _AlbumShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.08],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _AlbumShadowPainter old) => false;
}