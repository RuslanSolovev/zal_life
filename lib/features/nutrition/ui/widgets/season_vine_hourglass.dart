// lib/features/nutrition/ui/widgets/season_vine_hourglass.dart
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

class _HG {
  static const bg = Color(0xFF1A1208);
  static const bgDeep = Color(0xFF0A0704);
  static const wood = Color(0xFF3B2416);
  static const woodLight = Color(0xFF5A3A28);
  static const glass = Color(0xFFF5EDE0);
  static const sandLight = Color(0xFFE7D9B8);
  static const sand = Color(0xFFC79475);
  static const sandDeep = Color(0xFF8B6F47);
  static const gold = Color(0xFFD4A84B);
  static const current = Color(0xFFFF8A65);
  static const text = Color(0xFFF5EDE0);
  static const textMuted = Color(0xFFA89A82);
  static const textFaint = Color(0xFF5A4A38);
}

class _VS {
  final double scale;
  const _VS(this.scale);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

class SeasonVineCardHourglass extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCardHourglass({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  State<SeasonVineCardHourglass> createState() =>
      _SeasonVineCardHourglassState();
}

class _SeasonVineCardHourglassState extends State<SeasonVineCardHourglass>
    with TickerProviderStateMixin {
  late final AnimationController _stream;
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
    _stream = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _stream.dispose();
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
          center: Alignment(0, 0),
          radius: 1.2,
          colors: [_HG.bg, _HG.bgDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: r.s(28),
            offset: Offset(0, r.s(14)),
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
            _buildHourglass(r, cm, inSeason),
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
          Text('⏳', style: TextStyle(fontSize: r.fs(16))),
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
                  color: _HG.text,
                  fontSize: r.fs(18),
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.2,
                  height: 1.1,
                ),
              ),
            ),
          ),
          SeasonVineStyleButton(scale: widget.scale, color: _HG.sand),
          SizedBox(width: r.s(6)),
          GestureDetector(
            onTap: widget.onOpenKnowledge,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  r.s(10), r.s(6), r.s(8), r.s(6)),
              decoration: BoxDecoration(
                color: _HG.wood.withOpacity(0.6),
                borderRadius: BorderRadius.circular(r.s(6)),
                border: Border.all(
                  color: _HG.gold.withOpacity(0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Знания',
                    style: GoogleFonts.fraunces(
                      color: _HG.sandLight,
                      fontSize: r.fs(11),
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: r.s(4)),
                  Icon(Icons.arrow_forward_rounded,
                      color: _HG.gold, size: r.fs(11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourglass(_VS r, int cm, Set<int> inSeason) {
    final size = r.s(380);
    final cx = size / 2;

    // Compute positions for each month
    final monthPositions = <int, Offset>{};

    // Bottom bulb: months 1..current-1, piled
    final bottomMonths = List.generate(cm - 1, (i) => i + 1);
    final bottomRows = <int>[];
    int rem = bottomMonths.length;
    while (rem > 0) {
      final rc = rem >= 3 ? 3 : rem;
      bottomRows.add(rc);
      rem -= rc;
    }
    for (int idx = 0; idx < bottomMonths.length; idx++) {
      int row = 0;
      int inRow = idx;
      while (inRow >= bottomRows[row]) {
        inRow -= bottomRows[row];
        row++;
      }
      final col = inRow;
      final rowCount = bottomRows[row];
      final y = size * 0.90 - row * r.s(30.0);
      final x = cx + (col - (rowCount - 1) / 2) * r.s(50.0);
      monthPositions[bottomMonths[idx]] = Offset(x, y);
    }

    // Top bulb: months current+1..12, waiting
    final topMonths = List.generate(12 - cm, (i) => cm + i + 1);
    final topRows = <int>[];
    rem = topMonths.length;
    while (rem > 0) {
      final rc = rem >= 3 ? 3 : rem;
      topRows.add(rc);
      rem -= rc;
    }
    for (int idx = 0; idx < topMonths.length; idx++) {
      int row = 0;
      int inRow = idx;
      while (inRow >= topRows[row]) {
        inRow -= topRows[row];
        row++;
      }
      final col = inRow;
      final rowCount = topRows[row];
      final y = size * 0.10 + row * r.s(30.0);
      final x = cx + (col - (rowCount - 1) / 2) * r.s(50.0);
      monthPositions[topMonths[idx]] = Offset(x, y);
    }

    // Current: neck
    monthPositions[cm] = Offset(cx, size * 0.50);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Frame + glass + stream
          Positioned.fill(
            child: CustomPaint(
              painter: _HourglassPainter(
                streamAnimation: _stream,
                size: size,
              ),
            ),
          ),
          // Grains
          for (int m = 1; m <= 12; m++)
            if (monthPositions[m] != null)
              Positioned(
                left: monthPositions[m]!.dx - r.s(22),
                top: monthPositions[m]!.dy - r.s(22),
                width: r.s(44),
                height: r.s(44),
                child: _SandGrain(
                  month: m,
                  monthShort: _monthNames[m],
                  isCurrent: m == cm,
                  inSeason: inSeason.contains(m),
                  isExpanded: m == _expandedMonth,
                  r: r,
                  onTap: () => _toggleMonth(m),
                ),
              ),
        ],
      ),
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
          color: _HG.wood,
          borderRadius: BorderRadius.circular(r.s(14)),
          border: Border.all(
            color: _HG.gold.withOpacity(0.35),
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
                      color: _HG.sand.withOpacity(0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _HG.gold.withOpacity(0.55),
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
                            color: _HG.sandLight,
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
                            color: _HG.textMuted,
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
                        color: _HG.bg.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          color: _HG.sandLight, size: r.fs(14)),
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
                      color: _HG.textMuted,
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
          color: _HG.bg,
          borderRadius: BorderRadius.circular(r.s(6)),
          border: Border.all(
            color: _HG.gold.withOpacity(0.35),
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
                color: _HG.sandLight,
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

class _HourglassPainter extends CustomPainter {
  final Animation<double> streamAnimation;
  final double size;
  _HourglassPainter({
    required this.streamAnimation,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = canvasSize.width;
    final h = canvasSize.height;
    final cx = w / 2;

    // Wooden frame top
    _drawFrame(canvas, Rect.fromLTWH(w * 0.10, h * 0.03, w * 0.80, h * 0.04));
    // Wooden frame bottom
    _drawFrame(canvas, Rect.fromLTWH(w * 0.10, h * 0.93, w * 0.80, h * 0.04));

    // Glass bulbs
    _drawBulb(
      canvas,
      Rect.fromLTRB(w * 0.15, h * 0.07, w * 0.85, h * 0.48),
      isTop: true,
    );
    _drawBulb(
      canvas,
      Rect.fromLTRB(w * 0.15, h * 0.52, w * 0.85, h * 0.93),
      isTop: false,
    );

    // Sand stream in neck
    _drawStream(canvas, Offset(cx, h * 0.48), Offset(cx, h * 0.52));
  }

  void _drawFrame(Canvas canvas, Rect rect) {
    // Wood base
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          colors: [_HG.woodLight, _HG.wood],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..color = _HG.gold.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawBulb(Canvas canvas, Rect rect, {required bool isTop}) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;
    final cx = rect.center.dx;

    if (isTop) {
      // Top bulb: wide at top, narrow at bottom
      path.moveTo(rect.left + w * 0.05, rect.top);
      path.lineTo(rect.right - w * 0.05, rect.top);
      path.cubicTo(
        rect.right - w * 0.02, rect.top + h * 0.4,
        cx + w * 0.08, rect.bottom - h * 0.15,
        cx + w * 0.05, rect.bottom,
      );
      path.lineTo(cx - w * 0.05, rect.bottom);
      path.cubicTo(
        cx - w * 0.08, rect.bottom - h * 0.15,
        rect.left + w * 0.02, rect.top + h * 0.4,
        rect.left + w * 0.05, rect.top,
      );
      path.close();
    } else {
      // Bottom bulb: narrow at top, wide at bottom
      path.moveTo(cx - w * 0.05, rect.top);
      path.lineTo(cx + w * 0.05, rect.top);
      path.cubicTo(
        cx + w * 0.08, rect.top + h * 0.15,
        rect.right - w * 0.02, rect.bottom - h * 0.4,
        rect.right - w * 0.05, rect.bottom,
      );
      path.lineTo(rect.left + w * 0.05, rect.bottom);
      path.cubicTo(
        rect.left + w * 0.02, rect.bottom - h * 0.4,
        cx - w * 0.08, rect.top + h * 0.15,
        cx - w * 0.05, rect.top,
      );
      path.close();
    }

    // Glass fill (very subtle)
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
          end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            _HG.glass.withOpacity(0.04),
            _HG.glass.withOpacity(0.12),
          ],
        ).createShader(rect),
    );

    // Glass outline
    canvas.drawPath(
      path,
      Paint()
        ..color = _HG.glass.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawStream(Canvas canvas, Offset from, Offset to) {
    // Falling particles
    final t = streamAnimation.value;
    for (int i = 0; i < 6; i++) {
      final p = (t + i / 6) % 1.0;
      final y = from.dy + (to.dy - from.dy) * p;
      final opacity = (1 - p).clamp(0.2, 1.0) * 0.7;
      canvas.drawCircle(
        Offset(from.dx + (i.isEven ? -0.5 : 0.5), y),
        1.5,
        Paint()..color = _HG.sand.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter old) => true;
}

class _SandGrain extends StatelessWidget {
  final int month;
  final String monthShort;
  final bool isCurrent;
  final bool inSeason;
  final bool isExpanded;
  final _VS r;
  final VoidCallback onTap;

  const _SandGrain({
    required this.month,
    required this.monthShort,
    required this.isCurrent,
    required this.inSeason,
    required this.isExpanded,
    required this.r,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = isCurrent || isExpanded;

    final Color grainColor;
    final Color textColor;
    final double glow;
    if (highlighted) {
      grainColor = _HG.current;
      textColor = _HG.text;
      glow = 10;
    } else if (inSeason) {
      grainColor = _HG.sand;
      textColor = _HG.bg;
      glow = 4;
    } else {
      grainColor = _HG.sandDeep.withOpacity(0.65);
      textColor = _HG.textFaint;
      glow = 0;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: highlighted ? 1.10 : 1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                grainColor,
                grainColor.withOpacity(0.7),
              ],
              stops: const [0.6, 1.0],
            ),
            boxShadow: glow > 0
                ? [
              BoxShadow(
                color: grainColor.withOpacity(0.55),
                blurRadius: r.s(glow),
                spreadRadius: highlighted ? 2 : 0,
              ),
            ]
                : null,
            border: highlighted
                ? Border.all(
              color: _HG.sandLight.withOpacity(0.9),
              width: 1.5,
            )
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$month',
                style: GoogleFonts.fraunces(
                  color: textColor,
                  fontSize: r.fs(16),
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                monthShort,
                style: GoogleFonts.inter(
                  color: textColor.withOpacity(0.7),
                  fontSize: r.fs(6.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}