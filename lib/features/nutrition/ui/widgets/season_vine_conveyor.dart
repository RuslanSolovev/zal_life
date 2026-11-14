// lib/features/nutrition/ui/widgets/season_vine_conveyor.dart
import 'dart:math' as math;
import 'dart:ui' show MaskFilter, BlurStyle, FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/nutrition_models.dart' show FoodProduct;
import '../../models/wellness_models.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/wellness_provider.dart';
import 'product_knowledge_sheet.dart';
import 'season_visuals.dart';
import 'season_vine_style_button.dart';

// ═══════════════════════════════════════════════════════════════════
//  Palette — Midnight Glass · Bio-Luminescent Orbit
// ═══════════════════════════════════════════════════════════════════
class _CV {
  static const bg = Color(0xFF0B0805);
  static const bgDeep = Color(0xFF050302);
  static const blobWarm = Color(0xFF4A2C10);
  static const blobCool = Color(0xFF241A12);

  static const glass = Color(0xFF241E17);
  static const glassHi = Color(0xFF3A3226);
  static const glassEdge = Color(0xFF5A4E3C);

  static const cream = Color(0xFFEDE4D3);
  static const textMuted = Color(0xFF9A8B74);
  static const textFaint = Color(0xFF57493A);

  static const gold = Color(0xFFD4A84B);
  static const goldBright = Color(0xFFF7CE6B);
  static const goldDim = Color(0xFF6B5428);

  static const amber = Color(0xFFFFB84D);
  static const amberHot = Color(0xFFFFD98A);

  static const green = Color(0xFF7BE08A);
  static const greenSoft = Color(0xFF4FA85E);
}

class _VS {
  final double scale;
  const _VS(this.scale);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

class SeasonVineCardConveyor extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCardConveyor({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  State<SeasonVineCardConveyor> createState() =>
      _SeasonVineCardConveyorState();
}

class _SeasonVineCardConveyorState extends State<SeasonVineCardConveyor>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  int? _expandedMonth;

  static const _monthShort = [
    '', 'ЯНВ', 'ФЕВ', 'МАР', 'АПР', 'МАЙ', 'ИЮН',
    'ИЮЛ', 'АВГ', 'СЕН', 'ОКТ', 'НОЯ', 'ДЕК',
  ];
  static const _monthFull = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
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
    final cm = widget.wellness.currentMonth;
    final inSeason = widget.wellness.monthsWithSeason;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.s(24)),
        color: _CV.bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: r.s(34),
            offset: Offset(0, r.s(16)),
          ),
          BoxShadow(
            color: _CV.gold.withOpacity(0.06),
            blurRadius: r.s(60),
            spreadRadius: r.s(-12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.s(24)),
        child: Stack(
          children: [
            // Warm atmospheric blobs
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _BackdropBlobPainter()),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.1),
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        _CV.bgDeep.withOpacity(0.55),
                      ],
                      stops: const [0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(r, cm),
                SizedBox(height: r.s(6)),
                _buildOrbit(r, cm, inSeason),
                AnimatedSize(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _expandedMonth == null
                      ? const SizedBox(width: double.infinity, height: 0)
                      : _buildPanel(_expandedMonth!, r),
                ),
                SizedBox(height: r.s(14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader(_VS r, int cm) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(18), r.s(16), r.s(14), r.s(2)),
      child: Row(
        children: [
          Text('🌱', style: TextStyle(fontSize: r.fs(17))),
          SizedBox(width: r.s(8)),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'В сезоне · ${_monthFull[cm]}',
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.fraunces(
                  color: _CV.cream,
                  fontSize: r.fs(19),
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.2,
                  height: 1.1,
                ),
              ),
            ),
          ),
          SeasonVineStyleButton(scale: widget.scale, color: _CV.gold),
          SizedBox(width: r.s(8)),
          GestureDetector(
            onTap: widget.onOpenKnowledge,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  r.s(12), r.s(7), r.s(10), r.s(7)),
              decoration: BoxDecoration(
                color: _CV.gold.withOpacity(0.10),
                borderRadius: BorderRadius.circular(r.s(20)),
                border: Border.all(
                  color: _CV.gold.withOpacity(0.40),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Знания',
                    style: GoogleFonts.fraunces(
                      color: _CV.goldBright,
                      fontSize: r.fs(12),
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: r.s(5)),
                  Icon(Icons.arrow_forward_rounded,
                      color: _CV.goldBright, size: r.fs(12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ORBIT — 12 glass spheres on a glowing ring
  // ═══════════════════════════════════════════════════════════════
  Widget _buildOrbit(_VS r, int cm, Set<int> monthsWithSeason) {
    final size = r.s(330);
    final cx = size / 2;
    final cy = size / 2;
    final node = r.s(62);
    final ringR = (size / 2) - node / 2 - r.s(6);

    final nodes = <Widget>[];
    for (int m = 1; m <= 12; m++) {
      final angle = (m - 1) * (math.pi * 2 / 12) - math.pi / 2;
      final bx = cx + math.cos(angle) * ringR;
      final by = cy + math.sin(angle) * ringR;

      final products = widget.wellness.productsForMonth(m);
      final emojis = products.take(3).map((p) => p.emoji).join(' ');

      nodes.add(Positioned(
        left: bx - node / 2,
        top: by - node / 2,
        width: node,
        height: node,
        child: _OrbitNode(
          month: m,
          monthShort: _monthShort[m],
          emojis: emojis,
          hasProducts: products.isNotEmpty,
          isCurrent: m == cm,
          inSeason: monthsWithSeason.contains(m),
          isExpanded: m == _expandedMonth,
          pulse: _pulse,
          r: r,
          onTap: () => _toggleMonth(m),
        ),
      ));
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _OrbitRingPainter()),
              ),
            ),
          ),
          ...nodes,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PANEL — glass HUD with product chips
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPanel(int month, _VS r) {
    final meta = metaForMonth(month);
    final products = widget.wellness.productsForMonth(month);
    final isInSeason = widget.wellness.monthsWithSeason.contains(month);

    return TweenAnimationBuilder<double>(
      key: ValueKey(month),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(r.s(16), r.s(10), r.s(16), 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r.s(18)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: _CV.glass.withOpacity(0.55),
                borderRadius: BorderRadius.circular(r.s(18)),
                border: Border.all(
                  color: _CV.gold.withOpacity(0.28),
                  width: 0.8,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  r.s(12), r.s(12), r.s(12), r.s(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Month emblem
                      Container(
                        width: r.s(44),
                        height: r.s(44),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _CV.amber.withOpacity(0.30),
                              _CV.amber.withOpacity(0.06),
                            ],
                          ),
                          border: Border.all(
                            color: _CV.amber.withOpacity(0.55),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _CV.amber.withOpacity(0.25),
                              blurRadius: r.s(14),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(meta.emoji,
                            style: TextStyle(fontSize: r.fs(20))),
                      ),
                      SizedBox(width: r.s(12)),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (final p in products)
                                Padding(
                                  padding:
                                  EdgeInsets.only(right: r.s(8)),
                                  child: _buildProductChip(p, r),
                                ),
                              if (products.isEmpty)
                                Text(
                                  '— пусто —',
                                  style: GoogleFonts.fraunces(
                                    color: _CV.textMuted,
                                    fontSize: r.fs(12),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: r.s(6)),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _expandedMonth = null),
                        child: Container(
                          width: r.s(26),
                          height: r.s(26),
                          decoration: BoxDecoration(
                            color: _CV.gold.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded,
                              color: _CV.goldBright, size: r.fs(14)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.s(10)),
                  Padding(
                    padding: EdgeInsets.only(left: r.s(56)),
                    child: Text(
                      products.isEmpty
                          ? 'нет продуктов'
                          : '${products.length} ${_productsWord(products.length)} · ${isInSeason ? "в сезоне" : "вне сезона"}',
                      style: GoogleFonts.inter(
                        color: _CV.textMuted,
                        fontSize: r.fs(10),
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [
                          FontFeature.tabularFigures()
                        ],
                      ),
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

  Widget _buildProductChip(ProductKnowledge k, _VS r) {
    return GestureDetector(
      onTap: () => _openProductSheet(k),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: r.s(10), vertical: r.s(7)),
        decoration: BoxDecoration(
          color: _CV.bgDeep.withOpacity(0.55),
          borderRadius: BorderRadius.circular(r.s(20)),
          border: Border.all(
            color: _CV.gold.withOpacity(0.30),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(k.emoji, style: TextStyle(fontSize: r.fs(14))),
            SizedBox(width: r.s(6)),
            Text(
              k.displayName,
              style: GoogleFonts.inter(
                color: _CV.cream,
                fontSize: r.fs(11),
                fontWeight: FontWeight.w600,
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
      final norm = p.name.toLowerCase()
          .replaceAll('ё', 'е').replaceAll(' ', '_');
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
//  ORBIT NODE — glass sphere with halo
// ═══════════════════════════════════════════════════════════════════
class _OrbitNode extends StatelessWidget {
  final int month;
  final String monthShort;
  final String emojis;
  final bool hasProducts;
  final bool isCurrent;
  final bool inSeason;
  final bool isExpanded;
  final Animation<double> pulse;
  final _VS r;
  final VoidCallback onTap;

  const _OrbitNode({
    required this.month,
    required this.monthShort,
    required this.emojis,
    required this.hasProducts,
    required this.isCurrent,
    required this.inSeason,
    required this.isExpanded,
    required this.pulse,
    required this.r,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hero = isCurrent || isExpanded;

    // Rim / glow color per state
    final Color rim;
    final Color glow;
    final double glowOp;
    if (hero) {
      rim = _CV.amber;
      glow = _CV.amber;
      glowOp = 1.0;
    } else if (inSeason) {
      rim = _CV.green.withOpacity(0.85);
      glow = _CV.green;
      glowOp = 0.55;
    } else {
      rim = _CV.glassEdge.withOpacity(0.5);
      glow = _CV.gold;
      glowOp = 0.0;
    }

    final numberColor = hero
        ? _CV.amberHot
        : inSeason
        ? _CV.cream
        : _CV.textFaint;
    final labelColor = hero
        ? _CV.amber.withOpacity(0.85)
        : inSeason
        ? _CV.greenSoft
        : _CV.textFaint.withOpacity(0.7);

    Widget sphere = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: rim, width: hero ? 1.6 : 1.0),
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  radius: 1.1,
                  colors: [
                    _CV.glassHi.withOpacity(hero ? 0.85 : 0.55),
                    _CV.glass.withOpacity(0.45),
                    _CV.bgDeep.withOpacity(0.35),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Top glass highlight
                  Positioned(
                    top: r.s(4),
                    left: r.s(10),
                    right: r.s(14),
                    height: r.s(14),
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(r.s(14)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(
                                  hero ? 0.22 : 0.10),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$month',
                        style: GoogleFonts.inter(
                          color: numberColor,
                          fontSize: r.fs(hero ? 22 : 19),
                          fontWeight: FontWeight.w200,
                          height: 1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: r.s(2)),
                      Text(
                        monthShort,
                        style: GoogleFonts.inter(
                          color: labelColor,
                          fontSize: r.fs(7),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          height: 1,
                        ),
                      ),
                      if (hasProducts) ...[
                        SizedBox(height: r.s(3)),
                        Text(
                          emojis,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(fontSize: r.fs(7)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Breathing halo — only for the hero month
    if (hero) {
      sphere = AnimatedBuilder(
        animation: pulse,
        builder: (_, child) {
          final p = pulse.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glow.withOpacity(
                      (0.30 + 0.25 * p) * glowOp),
                  blurRadius: r.s(26 + 14 * p),
                  spreadRadius: r.s(2 + 4 * p),
                ),
                BoxShadow(
                  color: glow.withOpacity(0.12 * glowOp),
                  blurRadius: r.s(40),
                  spreadRadius: r.s(8),
                ),
              ],
            ),
            child: child,
          );
        },
        child: sphere,
      );
    } else if (inSeason) {
      sphere = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glow.withOpacity(0.18 * glowOp),
              blurRadius: r.s(14),
              spreadRadius: r.s(1),
            ),
          ],
        ),
        child: sphere,
      );
    }

    return AnimatedScale(
      scale: hero ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      child: sphere,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ORBIT RING — glowing circle + soft core
// ═══════════════════════════════════════════════════════════════════
class _OrbitRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final node = size.width * (62 / 330);
    final ringR = (size.width / 2) - node / 2 - size.width * (6 / 330);
    final center = Offset(cx, cy);

    // Soft core glow
    canvas.drawCircle(
      center,
      ringR * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _CV.amber.withOpacity(0.05),
            _CV.gold.withOpacity(0.02),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: ringR * 0.55)),
    );

    // Wide dim halo of the ring
    canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = _CV.gold.withOpacity(0.16)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Crisp hairline ring
    canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = _CV.gold.withOpacity(0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  BACKDROP BLOBS — warm atmospheric pools
// ═══════════════════════════════════════════════════════════════════
class _BackdropBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      _Blob(Offset(size.width * 0.88, size.height * 0.10),
          size.width * 0.38, _CV.blobWarm, 0.55),
      _Blob(Offset(size.width * 0.06, size.height * 0.86),
          size.width * 0.42, _CV.blobWarm, 0.40),
      _Blob(Offset(size.width * 0.12, size.height * 0.16),
          size.width * 0.30, _CV.blobCool, 0.50),
    ];
    for (final b in blobs) {
      canvas.drawCircle(
        b.center,
        b.radius,
        Paint()
          ..color = b.color.withOpacity(b.opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.radius * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropBlobPainter old) => false;
}

class _Blob {
  final Offset center;
  final double radius;
  final Color color;
  final double opacity;
  const _Blob(this.center, this.radius, this.color, this.opacity);
}