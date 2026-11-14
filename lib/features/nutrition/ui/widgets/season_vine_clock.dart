// lib/features/nutrition/ui/widgets/season_vine_clock.dart
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

class _CK {
  static const bg = Color(0xFF0F0A05);
  static const bgDeep = Color(0xFF030201);
  static const brass = Color(0xFF2A1F0F);
  static const brassLight = Color(0xFF5A4A28);
  static const brassBright = Color(0xFF8A6A3A);
  static const gold = Color(0xFFE8BC52);
  static const goldBright = Color(0xFFFFDC68);
  static const goldWhite = Color(0xFFFFF4CC);
  static const text = Color(0xFFF0DCB8);
  static const textMuted = Color(0xFF9A7C50);
  static const textFaint = Color(0xFF4A3820);
  static const star = Color(0xFFFFFFFF);
  static const current = Color(0xFFFF9E70);
  static const currentBright = Color(0xFFFFC299);
  static const sunGlow = Color(0xFFFFE8A0);
  static const sunCore = Color(0xFFFFF8D8);
}

class _VS {
  final double scale;
  const _VS(this.scale);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

class SeasonVineCardClock extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCardClock({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  State<SeasonVineCardClock> createState() => _SeasonVineCardClockState();
}

class _SeasonVineCardClockState extends State<SeasonVineCardClock>
    with TickerProviderStateMixin {
  late final AnimationController _star;
  late final AnimationController _pulse;

  int? _expandedMonth;
  late double _displayedTurns;

  static const _monthNames = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];
  static const _monthFull = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  @override
  void initState() {
    super.initState();
    _star = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _displayedTurns = (widget.wellness.currentMonth - 1) / 12.0;
  }

  @override
  void dispose() {
    _star.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // Shortest path rotation — никогда не крутится «назад через пол-круга»
  double _shortestPath(double from, double to) {
    double delta = to - from;
    while (delta > 0.5) delta -= 1.0;
    while (delta < -0.5) delta += 1.0;
    return from + delta;
  }

  void _toggleMonth(int month) {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    final newExpanded = _expandedMonth == month ? null : month;
    final newTarget = newExpanded ?? widget.wellness.currentMonth;
    final newTurns =
    _shortestPath(_displayedTurns, (newTarget - 1) / 12.0);

    setState(() {
      _expandedMonth = newExpanded;
      _displayedTurns = newTurns;
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
          center: Alignment(0, -0.3),
          radius: 1.4,
          colors: [
            _CK.brassBright,
            _CK.brass,
            _CK.bg,
            _CK.bgDeep,
          ],
          stops: [0.0, 0.25, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.65),
            blurRadius: r.s(32),
            offset: Offset(0, r.s(16)),
          ),
          BoxShadow(
            color: _CK.gold.withOpacity(0.15),
            blurRadius: r.s(60),
            spreadRadius: r.s(-8),
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
            _buildClock(r, cm, inSeason),
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
          Text('🕰', style: TextStyle(fontSize: r.fs(18))),
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
                  color: _CK.text,
                  fontSize: r.fs(18),
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.2,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: _CK.goldBright.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SeasonVineStyleButton(
              scale: widget.scale, color: _CK.goldBright),
          SizedBox(width: r.s(6)),
          GestureDetector(
            onTap: widget.onOpenKnowledge,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  r.s(10), r.s(6), r.s(8), r.s(6)),
              decoration: BoxDecoration(
                color: _CK.brassLight.withOpacity(0.75),
                borderRadius: BorderRadius.circular(r.s(6)),
                border: Border.all(
                  color: _CK.goldBright.withOpacity(0.55),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _CK.goldBright.withOpacity(0.20),
                    blurRadius: r.s(6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Знания',
                    style: GoogleFonts.fraunces(
                      color: _CK.goldWhite,
                      fontSize: r.fs(11),
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: r.s(4)),
                  Icon(Icons.arrow_forward_rounded,
                      color: _CK.goldBright, size: r.fs(11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  CLOCK — clean, with correctly-aimed rotating hand
  // ═════════════════════════════════════════════════════════════════
  Widget _buildClock(_VS r, int cm, Set<int> inSeason) {
    final size = r.s(360);
    final cx = size / 2;
    final cy = size / 2;
    final outerR = size * 0.46;
    final badgeRingR = outerR * 0.78;
    final badgeSize = r.s(50);
    final handLen = outerR * 0.60;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Stars
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _star,
                  builder: (_, __) => CustomPaint(
                    painter: _ClockStarsPainter(
                        time: _star.value, scale: widget.scale),
                  ),
                ),
              ),
            ),
          ),
          // Base rings
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ClockBasePainter(
                  outerR: outerR,
                  brassColor: _CK.brass,
                  brassLight: _CK.brassLight,
                  brassBright: _CK.brassBright,
                  goldColor: _CK.gold,
                  goldBright: _CK.goldBright,
                ),
              ),
            ),
          ),
          // Sun hand — rotates to point at expanded / current month
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedRotation(
                turns: _displayedTurns,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutCubic,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => CustomPaint(
                    painter: _ClockHandPainter(
                      len: handLen,
                      goldColor: _CK.goldBright,
                      goldWhite: _CK.goldWhite,
                      glowColor: _CK.sunGlow,
                      coreColor: _CK.sunCore,
                      pulse: _pulse.value,
                      scale: widget.scale,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 12 month badges
          for (int m = 1; m <= 12; m++)
            Positioned(
              left: cx +
                  math.cos(_angleFor(m)) * badgeRingR -
                  badgeSize / 2,
              top: cy +
                  math.sin(_angleFor(m)) * badgeRingR -
                  badgeSize / 2,
              width: badgeSize,
              height: badgeSize,
              child: _buildMonthBadge(
                r: r,
                month: m,
                isCurrent: m == cm,
                inSeason: inSeason.contains(m),
                isExpanded: m == _expandedMonth,
              ),
            ),
          // Center hub — tap to open current month
          Positioned(
            left: cx - r.s(34),
            top: cy - r.s(34),
            width: r.s(68),
            height: r.s(68),
            child: _buildCenterHub(r, cm, _expandedMonth == cm),
          ),
        ],
      ),
    );
  }

  double _angleFor(int month) =>
      (month - 1) * (math.pi * 2 / 12) - math.pi / 2;

  Widget _buildMonthBadge({
    required _VS r,
    required int month,
    required bool isCurrent,
    required bool inSeason,
    required bool isExpanded,
  }) {
    final highlighted = isCurrent || isExpanded;
    final dim = !isCurrent && !inSeason && !isExpanded;

    final Color accent;
    final Color bgColor;
    final Color textColor;
    final double glowStrength;
    final double borderW;

    if (isExpanded) {
      accent = _CK.currentBright;
      bgColor = _CK.current.withOpacity(0.30);
      textColor = _CK.goldWhite;
      glowStrength = 1.0;
      borderW = 2.2;
    } else if (isCurrent) {
      accent = _CK.goldBright;
      bgColor = _CK.goldBright.withOpacity(0.18);
      textColor = _CK.goldWhite;
      glowStrength = 0.75;
      borderW = 1.8;
    } else if (inSeason) {
      accent = _CK.gold;
      bgColor = _CK.gold.withOpacity(0.08);
      textColor = _CK.gold;
      glowStrength = 0.35;
      borderW = 1.2;
    } else {
      accent = _CK.textFaint;
      bgColor = Colors.transparent;
      textColor = _CK.textFaint;
      glowStrength = 0;
      borderW = 0.8;
    }

    Widget inner = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: accent, width: borderW),
        boxShadow: glowStrength > 0
            ? [
          BoxShadow(
            color: accent.withOpacity(0.55 * glowStrength),
            blurRadius: r.s(10 + 8 * glowStrength),
            spreadRadius: r.s(0.5 + 1.5 * glowStrength),
          ),
        ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$month',
            style: GoogleFonts.fraunces(
              color: textColor,
              fontSize: r.fs(highlighted ? 18 : 16),
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              height: 1,
              letterSpacing: -0.5,
              shadows: highlighted
                  ? [
                Shadow(
                  color: accent.withOpacity(0.9),
                  blurRadius: 6,
                ),
              ]
                  : null,
            ),
          ),
          SizedBox(height: r.s(1)),
          Text(
            _monthNames[month],
            style: GoogleFonts.inter(
              color: textColor.withOpacity(highlighted ? 0.85 : 0.55),
              fontSize: r.fs(7),
              fontWeight:
              highlighted ? FontWeight.w700 : FontWeight.w500,
              height: 1,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    // Current month — heartbeat pulse
    if (isCurrent && !isExpanded) {
      inner = AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) {
          final p = _pulse.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + 0.45 * p,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                    _CK.currentBright.withOpacity(0.28 * (1 - p)),
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: inner,
      );
    }

    return GestureDetector(
      onTap: () => _toggleMonth(month),
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: dim ? 0.55 : 1.0,
        child: inner,
      ),
    );
  }

  Widget _buildCenterHub(_VS r, int cm, bool isCurrentExpanded) {
    return GestureDetector(
      onTap: () => _toggleMonth(cm),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) {
          final p = _pulse.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isCurrentExpanded
                    ? [
                  _CK.currentBright,
                  _CK.current,
                  _CK.brass,
                ]
                    : [
                  _CK.goldWhite,
                  _CK.goldBright,
                  _CK.gold,
                  _CK.brass,
                ],
                stops: isCurrentExpanded
                    ? const [0.0, 0.55, 1.0]
                    : const [0.0, 0.35, 0.7, 1.0],
              ),
              border: Border.all(
                color: isCurrentExpanded
                    ? _CK.currentBright
                    : _CK.brass,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isCurrentExpanded
                      ? _CK.current
                      : _CK.goldBright)
                      .withOpacity(0.55 + 0.35 * p),
                  blurRadius: r.s(14 + 8 * p),
                  spreadRadius: r.s(1 + 2 * p),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$cm',
                  style: GoogleFonts.fraunces(
                    color: _CK.bgDeep,
                    fontSize: r.fs(26),
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: r.s(2)),
                Text(
                  _monthNames[cm].toUpperCase(),
                  style: GoogleFonts.inter(
                    color: _CK.bgDeep.withOpacity(0.75),
                    fontSize: r.fs(8),
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  PANEL
  // ═════════════════════════════════════════════════════════════════
  Widget _buildPanel(int month, _VS r) {
    final meta = metaForMonth(month);
    final products = widget.wellness.productsForMonth(month);
    final monthName = _monthFull[month];
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
            r.s(16), r.s(4), r.s(16), r.s(0)),
        padding: EdgeInsets.all(r.s(12)),
        decoration: BoxDecoration(
          color: _CK.brassLight.withOpacity(0.65),
          borderRadius: BorderRadius.circular(r.s(14)),
          border: Border.all(
            color: _CK.goldBright.withOpacity(0.55),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _CK.goldBright.withOpacity(0.20),
              blurRadius: r.s(16),
              offset: Offset(0, r.s(4)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: r.s(34),
                  height: r.s(34),
                  decoration: BoxDecoration(
                    color: _CK.gold.withOpacity(0.20),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _CK.goldBright.withOpacity(0.75),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _CK.goldBright.withOpacity(0.35),
                        blurRadius: r.s(8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(meta.emoji,
                      style: TextStyle(fontSize: r.fs(16))),
                ),
                SizedBox(width: r.s(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fraunces(
                          color: _CK.goldWhite,
                          fontSize: r.fs(15),
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
                          color: _CK.goldBright.withOpacity(0.75),
                          fontSize: r.fs(10),
                          fontWeight: FontWeight.w600,
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
                    width: r.s(24),
                    height: r.s(24),
                    decoration: BoxDecoration(
                      color: _CK.bg.withOpacity(0.75),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _CK.goldBright.withOpacity(0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: _CK.goldBright, size: r.fs(13)),
                  ),
                ),
              ],
            ),
            if (products.isNotEmpty) ...[
              SizedBox(height: r.s(10)),
              Wrap(
                spacing: r.s(6),
                runSpacing: r.s(6),
                children: [
                  for (final p in products)
                    _buildProductChip(p, r),
                ],
              ),
            ],
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
          color: _CK.bg,
          borderRadius: BorderRadius.circular(r.s(6)),
          border: Border.all(
            color: _CK.goldBright.withOpacity(0.55),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: _CK.gold.withOpacity(0.20),
              blurRadius: r.s(6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(k.emoji, style: TextStyle(fontSize: r.fs(14))),
            SizedBox(width: r.s(6)),
            Text(
              k.displayName,
              style: GoogleFonts.fraunces(
                color: _CK.goldWhite,
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
//  BASE — decorative rings, no labels
// ═══════════════════════════════════════════════════════════════════
class _ClockBasePainter extends CustomPainter {
  final double outerR;
  final Color brassColor;
  final Color brassLight;
  final Color brassBright;
  final Color goldColor;
  final Color goldBright;

  _ClockBasePainter({
    required this.outerR,
    required this.brassColor,
    required this.brassLight,
    required this.brassBright,
    required this.goldColor,
    required this.goldBright,
  });

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;

    // Outer brass body
    canvas.drawCircle(
      Offset(cx, cy),
      outerR,
      Paint()
        ..shader = RadialGradient(
          colors: [brassBright, brassLight, brassColor],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: outerR)),
    );

    // Outer gold rim
    canvas.drawCircle(
      Offset(cx, cy),
      outerR,
      Paint()
        ..color = goldBright.withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      outerR * 0.97,
      Paint()
        ..color = goldColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Decorative inner rings (subtle)
    for (final frac in [0.65, 0.48, 0.32]) {
      canvas.drawCircle(
        Offset(cx, cy),
        outerR * frac,
        Paint()
          ..color = goldColor.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6,
      );
    }

    // Inner brass disc (behind center hub)
    canvas.drawCircle(
      Offset(cx, cy),
      outerR * 0.26,
      Paint()..color = brassColor.withOpacity(0.85),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      outerR * 0.26,
      Paint()
        ..color = goldColor.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // Warm inner glow behind center
    canvas.drawCircle(
      Offset(cx, cy),
      outerR * 0.20,
      Paint()
        ..color = goldBright.withOpacity(0.12)
        ..maskFilter =
        const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  @override
  bool shouldRepaint(covariant _ClockBasePainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  HAND — points straight up (rotated by AnimatedRotation)
// ═══════════════════════════════════════════════════════════════════
class _ClockHandPainter extends CustomPainter {
  final double len;
  final Color goldColor;
  final Color goldWhite;
  final Color glowColor;
  final Color coreColor;
  final double pulse;
  final double scale;

  _ClockHandPainter({
    required this.len,
    required this.goldColor,
    required this.goldWhite,
    required this.glowColor,
    required this.coreColor,
    required this.pulse,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sunR = 8 + 3 * pulse;
    final tipY = cy - len;

    // Sun glow (outer)
    canvas.drawCircle(
      Offset(cx, tipY),
      (len * 0.55) * (1.0 + 0.15 * pulse),
      Paint()
        ..color = glowColor.withOpacity(0.28 + 0.10 * pulse)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, 32 * scale),
    );
    canvas.drawCircle(
      Offset(cx, tipY),
      (len * 0.30) * (1.0 + 0.10 * pulse),
      Paint()
        ..color = glowColor.withOpacity(0.55)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, 18 * scale),
    );

    // Shaft (elegant, narrow)
    final shaft = Path()
      ..moveTo(cx - 3, cy)
      ..lineTo(cx, tipY)
      ..lineTo(cx + 3, cy)
      ..close();
    canvas.drawPath(
      shaft,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            goldWhite,
            goldColor,
            goldColor.withOpacity(0.4),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(
            Rect.fromLTWH(cx - 4, tipY, 8, len)),
    );

    // Bright core line
    canvas.drawLine(
      Offset(cx, cy - len * 0.15),
      Offset(cx, cy - len * 0.92),
      Paint()
        ..color = goldWhite.withOpacity(0.8)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );

    // Sun tip — big glowing orb
    canvas.drawCircle(
      Offset(cx, tipY),
      sunR * 2.2,
      Paint()
        ..color = glowColor.withOpacity(0.40)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, 12 * scale),
    );
    canvas.drawCircle(
      Offset(cx, tipY),
      sunR,
      Paint()
        ..shader = RadialGradient(
          colors: [coreColor, goldWhite, goldColor],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(cx, tipY),
          radius: sunR,
        )),
    );
    // White-hot center
    canvas.drawCircle(
      Offset(cx, tipY),
      sunR * 0.45,
      Paint()..color = Colors.white,
    );

    // Rays around sun
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + pulse * math.pi / 8;
      final r1 = sunR + 2;
      final r2 = sunR + 6 + 3 * pulse;
      canvas.drawLine(
        Offset(
          cx + math.cos(a) * r1,
          tipY + math.sin(a) * r1,
        ),
        Offset(
          cx + math.cos(a) * r2,
          tipY + math.sin(a) * r2,
        ),
        Paint()
          ..color = goldWhite.withOpacity(0.65)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClockHandPainter old) =>
      old.pulse != pulse;
}

// ═══════════════════════════════════════════════════════════════════
//  STARS
// ═══════════════════════════════════════════════════════════════════
class _ClockStarsPainter extends CustomPainter {
  final double time;
  final double scale;
  _ClockStarsPainter({required this.time, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final baseOpacity = 0.35 + rng.nextDouble() * 0.4;
      final phase = rng.nextDouble() * math.pi * 2;
      final freq = 0.5 + rng.nextDouble() * 1.5;
      final opacity = baseOpacity *
          (0.5 +
              0.5 * math.sin(time * math.pi * 2 * freq + phase));
      final radius = (0.9 + rng.nextDouble() * 1.6) * scale;

      canvas.drawCircle(
        Offset(x, y),
        radius * 2.5,
        Paint()
          ..color = _CK.star.withOpacity(opacity * 0.30)
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, radius * 1.5),
      );
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = _CK.star.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClockStarsPainter old) =>
      old.time != time;
}