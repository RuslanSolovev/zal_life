// lib/features/nutrition/ui/widgets/season_vine_kintsugi.dart
import 'dart:math' as math;
import 'dart:ui' show MaskFilter, BlurStyle, FontFeature;

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

class _KG {
  static const bg = Color(0xFF1A1410);
  static const bgDeep = Color(0xFF0F0B08);
  static const ceramic = Color(0xFF2A2420);
  static const ceramicLight = Color(0xFF3F3832);
  static const ceramicEdge = Color(0xFF5A5045);
  static const cream = Color(0xFFE8DFD0);
  static const gold = Color(0xFFD4A84B);
  static const goldBright = Color(0xFFF5C842);
  static const goldDim = Color(0xFF6B5428);
  static const textMuted = Color(0xFF9C8F7B);
  static const textFaint = Color(0xFF5A5045);
}

class _VS {
  final double scale;
  const _VS(this.scale);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

class SeasonVineCardKintsugi extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCardKintsugi({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  State<SeasonVineCardKintsugi> createState() =>
      _SeasonVineCardKintsugiState();
}

class _SeasonVineCardKintsugiState extends State<SeasonVineCardKintsugi>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  int? _expandedMonth;

  static const _monthNames = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
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
      duration: const Duration(milliseconds: 2400),
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
        borderRadius: BorderRadius.circular(r.s(20)),
        gradient: const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [_KG.ceramic, _KG.bg, _KG.bgDeep],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: r.s(28),
            offset: Offset(0, r.s(14)),
          ),
          BoxShadow(
            color: _KG.gold.withOpacity(0.05),
            blurRadius: r.s(50),
            spreadRadius: r.s(-10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.s(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(r, cm),
            SizedBox(height: r.s(4)),
            _buildDisc(r, cm, inSeason),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expandedMonth == null
                  ? const SizedBox(width: double.infinity, height: 0)
                  : _buildPanel(_expandedMonth!, r),
            ),
            SizedBox(height: r.s(12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(_VS r, int cm) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          r.s(18), r.s(16), r.s(14), r.s(4)),
      child: Row(
        children: [
          Text('🌸', style: TextStyle(fontSize: r.fs(16))),
          SizedBox(width: r.s(6)),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'В сезоне · ${_monthNames[cm]}',
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.fraunces(
                  color: _KG.cream,
                  fontSize: r.fs(18),
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.2,
                  height: 1.1,
                ),
              ),
            ),
          ),
          SeasonVineStyleButton(scale: widget.scale, color: _KG.gold),
          SizedBox(width: r.s(6)),
          GestureDetector(
            onTap: widget.onOpenKnowledge,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  r.s(10), r.s(6), r.s(8), r.s(6)),
              decoration: BoxDecoration(
                color: _KG.gold.withOpacity(0.10),
                borderRadius: BorderRadius.circular(r.s(6)),
                border: Border.all(
                  color: _KG.gold.withOpacity(0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Знания',
                    style: GoogleFonts.fraunces(
                      color: _KG.gold,
                      fontSize: r.fs(11),
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: r.s(4)),
                  Icon(Icons.arrow_forward_rounded,
                      color: _KG.gold, size: r.fs(11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisc(_VS r, int cm, Set<int> monthsWithSeason) {
    final size = r.s(360);
    final cx = size / 2;
    final cy = size / 2;
    final outerR = size * 0.44;
    final innerR = size * 0.12;
    final badgeRingR = size * 0.30;

    final badges = <Widget>[];
    for (int m = 1; m <= 12; m++) {
      final angle = (m - 1) * (math.pi * 2 / 12) - math.pi / 2;
      final bx = cx + math.cos(angle) * badgeRingR;
      final by = cy + math.sin(angle) * badgeRingR;
      badges.add(Positioned(
        left: bx - r.s(22),
        top: by - r.s(22),
        width: r.s(44),
        height: r.s(44),
        child: _KintsugiBadge(
          month: m,
          monthShort: _monthNames[m],
          isCurrent: m == cm,
          inSeason: monthsWithSeason.contains(m),
          isExpanded: m == _expandedMonth,
          pulse: _pulse,
          r: r,
          onTap: () => _toggleMonth(m),
        ),
      ));
    }

    final cracks = <Widget>[];
    for (int i = 0; i < 12; i++) {
      final midAngle = (i * 30 + 15) * math.pi / 180 - math.pi / 2;
      final m1 = i + 1;
      final m2 = i == 11 ? 1 : i + 2;
      final active = monthsWithSeason.contains(m1) ||
          monthsWithSeason.contains(m2) ||
          m1 == cm || m2 == cm;
      final highlighted = m1 == cm || m2 == cm ||
          m1 == _expandedMonth || m2 == _expandedMonth;

      cracks.add(Positioned.fill(
        child: CustomPaint(
          painter: _KintsugiCrackPainter(
            center: Offset(cx, cy),
            innerR: innerR,
            outerR: outerR,
            angle: midAngle,
            seed: i,
            active: active,
            highlighted: highlighted,
          ),
        ),
      ));
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(children: [
        Positioned.fill(
          child: CustomPaint(painter: _KintsugiDiscPainter()),
        ),
        ...cracks,
        ...badges,
      ]),
    );
  }

  Widget _buildPanel(int month, _VS r) {
    final meta = metaForMonth(month);
    final products = widget.wellness.productsForMonth(month);
    final isInSeason = widget.wellness.monthsWithSeason.contains(month);

    return TweenAnimationBuilder<double>(
      key: ValueKey(month),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 16),
          child: child,
        ),
      ),
      child: Container(
        margin: EdgeInsets.fromLTRB(
            r.s(16), r.s(8), r.s(16), r.s(0)),
        decoration: BoxDecoration(
          color: _KG.ceramic,
          borderRadius: BorderRadius.circular(r.s(14)),
          border: Border.all(
            color: _KG.gold.withOpacity(0.35),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  r.s(14), r.s(12), r.s(10), r.s(8)),
              child: Row(
                children: [
                  Container(
                    width: r.s(36),
                    height: r.s(36),
                    decoration: BoxDecoration(
                      color: _KG.gold.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _KG.gold.withOpacity(0.55),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(meta.emoji,
                        style: TextStyle(fontSize: r.fs(18))),
                  ),
                  SizedBox(width: r.s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _monthFull[month],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fraunces(
                            color: _KG.cream,
                            fontSize: r.fs(16),
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.2,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          products.isEmpty
                              ? 'нет продуктов'
                              : '${products.length} ${_productsWord(products.length)} · ${isInSeason ? "в сезоне" : "вне сезона"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _KG.textMuted,
                            fontSize: r.fs(10),
                            fontWeight: FontWeight.w500,
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
                      width: r.s(26),
                      height: r.s(26),
                      decoration: BoxDecoration(
                        color: _KG.gold.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          color: _KG.gold, size: r.fs(14)),
                    ),
                  ),
                ],
              ),
            ),
            if (products.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: r.s(18)),
                child: Center(
                  child: Text(
                    '— пусто —',
                    style: GoogleFonts.fraunces(
                      color: _KG.textMuted,
                      fontSize: r.fs(11),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.fromLTRB(
                    r.s(10), 0, r.s(10), r.s(10)),
                child: Wrap(
                  spacing: r.s(6),
                  runSpacing: r.s(6),
                  children: [
                    for (final p in products)
                      _buildProductChip(p, r),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductChip(ProductKnowledge k, _VS r) {
    return GestureDetector(
      onTap: () => _openProductSheet(k),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: r.s(8), vertical: r.s(6)),
        decoration: BoxDecoration(
          color: _KG.bg,
          borderRadius: BorderRadius.circular(r.s(6)),
          border: Border.all(
            color: _KG.gold.withOpacity(0.35),
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
              style: GoogleFonts.fraunces(
                color: _KG.cream,
                fontSize: r.fs(11),
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
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
      if (p.id == k.key) { product = p; break; }
      final norm = p.name.toLowerCase()
          .replaceAll('ё', 'е').replaceAll(' ', '_');
      if (norm.contains(k.key) || k.key.contains(norm)) {
        product = p; break;
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

class _KintsugiDiscPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.46;

    canvas.drawCircle(
      Offset(cx, cy),
      outerR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _KG.ceramic.withOpacity(0.85),
            _KG.ceramicLight.withOpacity(0.55),
            _KG.ceramic.withOpacity(0.20),
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(
            center: Offset(cx, cy), radius: outerR)),
    );

    canvas.drawCircle(
      Offset(cx, cy), outerR,
      Paint()
        ..color = _KG.ceramicEdge.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(cx, cy), outerR * 0.82,
      Paint()
        ..color = _KG.gold.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _KintsugiDiscPainter old) => false;
}

class _KintsugiCrackPainter extends CustomPainter {
  final Offset center;
  final double innerR;
  final double outerR;
  final double angle;
  final int seed;
  final bool active;
  final bool highlighted;

  _KintsugiCrackPainter({
    required this.center,
    required this.innerR,
    required this.outerR,
    required this.angle,
    required this.seed,
    required this.active,
    required this.highlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(
      center.dx + math.cos(angle) * innerR,
      center.dy + math.sin(angle) * innerR,
    );
    final end = Offset(
      center.dx + math.cos(angle) * outerR,
      center.dy + math.sin(angle) * outerR,
    );

    final path = _jagged(start, end, seed);

    Color color;
    double width;
    double blur;
    if (highlighted) {
      color = _KG.goldBright; width = 2.8; blur = 6;
    } else if (active) {
      color = _KG.gold; width = 2.2; blur = 3;
    } else {
      color = _KG.goldDim; width = 1.4; blur = 0;
    }

    if (blur > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(
            highlighted ? 0.95 : (active ? 0.75 : 0.45))
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _jagged(Offset from, Offset to, int seed) {
    final rng = math.Random(seed);
    final path = Path();
    path.moveTo(from.dx, from.dy);
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final nx = -dy / len;
    final ny = dx / len;
    final segments = (len / 12).round().clamp(5, 10);
    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final baseX = from.dx + dx * t;
      final baseY = from.dy + dy * t;
      if (i == segments) {
        path.lineTo(baseX, baseY);
      } else {
        final j = (rng.nextDouble() - 0.5) * 4.0;
        path.lineTo(baseX + nx * j, baseY + ny * j);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _KintsugiCrackPainter old) =>
      old.active != active || old.highlighted != highlighted;
}

class _KintsugiBadge extends StatelessWidget {
  final int month;
  final String monthShort;
  final bool isCurrent;
  final bool inSeason;
  final bool isExpanded;
  final Animation<double> pulse;
  final _VS r;
  final VoidCallback onTap;

  const _KintsugiBadge({
    required this.month,
    required this.monthShort,
    required this.isCurrent,
    required this.inSeason,
    required this.isExpanded,
    required this.pulse,
    required this.r,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = isCurrent || isExpanded;

    Widget badge = AnimatedScale(
      scale: highlighted ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: highlighted
              ? const RadialGradient(colors: [
            _KG.goldBright, _KG.gold,
          ])
              : inSeason
              ? RadialGradient(colors: [
            _KG.gold.withOpacity(0.55),
            _KG.gold.withOpacity(0.25),
          ])
              : const RadialGradient(colors: [
            _KG.ceramicLight, _KG.ceramic,
          ]),
          boxShadow: highlighted
              ? [
            BoxShadow(
              color: _KG.goldBright.withOpacity(0.55),
              blurRadius: r.s(14),
              spreadRadius: 2,
            ),
          ]
              : inSeason
              ? [
            BoxShadow(
              color: _KG.gold.withOpacity(0.25),
              blurRadius: r.s(6),
            ),
          ]
              : null,
          border: Border.all(
            color: highlighted
                ? _KG.goldBright
                : inSeason
                ? _KG.gold
                : _KG.ceramicEdge.withOpacity(0.6),
            width: highlighted ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$month',
              style: GoogleFonts.fraunces(
                color: highlighted
                    ? _KG.bg
                    : inSeason ? _KG.cream : _KG.textFaint,
                fontSize: r.fs(18),
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                height: 1,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              monthShort,
              style: GoogleFonts.inter(
                color: highlighted
                    ? _KG.bg.withOpacity(0.7)
                    : inSeason
                    ? _KG.gold
                    : _KG.textFaint.withOpacity(0.7),
                fontSize: r.fs(7),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );

    if (isCurrent && !isExpanded) {
      badge = AnimatedBuilder(
        animation: pulse,
        builder: (_, child) {
          final p = pulse.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: r.s(44) * (1.0 + p * 0.35),
                height: r.s(44) * (1.0 + p * 0.35),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _KG.goldBright.withOpacity(0.25 * (1 - p)),
                ),
              ),
              child!,
            ],
          );
        },
        child: badge,
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: badge,
    );
  }
}