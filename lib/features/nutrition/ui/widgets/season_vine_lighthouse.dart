// lib/features/nutrition/ui/widgets/season_vine_lighthouse.dart
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

class _LH {
  static const bg = Color(0xFF0A1420);
  static const bgDeep = Color(0xFF050810);
  static const skyTop = Color(0xFF0A1420);
  static const skyBottom = Color(0xFF152535);
  static const water = Color(0xFF0A1622);
  static const waterDeep = Color(0xFF050D15);
  static const horizon = Color(0xFF2A3A4A);
  static const tower = Color(0xFFF5EDE0);
  static const towerShade = Color(0xFF8A7A6A);
  static const lamp = Color(0xFFF5C842);
  static const lampGlow = Color(0xFFFFE8A8);
  static const beam = Color(0xFFF5EDE0);
  static const star = Color(0xFFE8EEF5);
  static const text = Color(0xFFE8EEF5);
  static const textMuted = Color(0xFF5A6A7A);
  static const textFaint = Color(0xFF2A3542);
  static const current = Color(0xFFFF8A65);
  static const island = Color(0xFF1A2530);
  static const islandLit = Color(0xFF3A4A5A);
}

class _VS {
  final double scale;
  const _VS(this.scale);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

class SeasonVineCardLighthouse extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCardLighthouse({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  State<SeasonVineCardLighthouse> createState() =>
      _SeasonVineCardLighthouseState();
}

class _SeasonVineCardLighthouseState extends State<SeasonVineCardLighthouse>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _waves;
  late final ScrollController _scroll;
  int? _expandedMonth;

  static const _monthNames = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];
  static const _monthFull = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];
  static const _monthEmoji = [
    '', '❄️', '🌨️', '🌱', '🌷', '🌸', '☀️',
    '🌻', '🌾', '🍂', '🍁', '🌧️', '🎄',
  ];

  // geometry
  static const _islandSpacing = 78.0;
  static const _sideMargin = 100.0;

  double get _totalWidth =>
      (_sideMargin * 2 + 11 * _islandSpacing) * widget.scale;

  double _islandCenterX(int month) =>
      (_sideMargin + (month - 1) * _islandSpacing) * widget.scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _waves = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _scroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnMonth(widget.wellness.currentMonth, animate: false);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _waves.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _centerOnMonth(int month, {bool animate = true}) {
    if (!_scroll.hasClients) return;
    final viewport = _scroll.position.viewportDimension;
    // Lighthouse is fixed on right; beam aims at center-ish of viewport
    final target = (_islandCenterX(month) - viewport * 0.45)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    if (animate) {
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic);
    } else {
      _scroll.jumpTo(target);
    }
  }

  void _toggleMonth(int month) {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    setState(() {
      if (_expandedMonth == month) {
        _expandedMonth = null;
      } else {
        _expandedMonth = month;
        _centerOnMonth(month);
      }
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
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_LH.skyTop, _LH.skyBottom],
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
            _buildScene(r, cm, inSeason),
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
          Text('🗼', style: TextStyle(fontSize: r.fs(16))),
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
                  color: _LH.text,
                  fontSize: r.fs(18),
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.2,
                  height: 1.1,
                ),
              ),
            ),
          ),
          SeasonVineStyleButton(
              scale: widget.scale, color: _LH.lamp),
          SizedBox(width: r.s(6)),
          GestureDetector(
            onTap: widget.onOpenKnowledge,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  r.s(10), r.s(6), r.s(8), r.s(6)),
              decoration: BoxDecoration(
                color: _LH.water.withOpacity(0.6),
                borderRadius: BorderRadius.circular(r.s(6)),
                border: Border.all(
                  color: _LH.lamp.withOpacity(0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Знания',
                    style: GoogleFonts.fraunces(
                      color: _LH.text,
                      fontSize: r.fs(11),
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: r.s(4)),
                  Icon(Icons.arrow_forward_rounded,
                      color: _LH.lamp, size: r.fs(11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScene(_VS r, int cm, Set<int> inSeason) {
    final sceneH = r.s(260);
    final horizonY = sceneH * 0.68;
    final viewportW = MediaQuery.of(context).size.width;
    final lampX = viewportW - r.s(46);
    final lampY = r.s(72);

    return SizedBox(
      height: sceneH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sky gradient (fixed background)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _LH.skyTop,
                    _LH.skyBottom,
                    _LH.water,
                    _LH.waterDeep,
                  ],
                  stops: [0.0, 0.5, 0.68, 1.0],
                ),
              ),
            ),
          ),
          // Stars
          Positioned.fill(
            top: 0,
            bottom: sceneH * 0.4,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => CustomPaint(
                  painter: _StarsPainter(
                    time: _pulse.value,
                    scale: widget.scale,
                    color: _LH.star,
                  ),
                ),
              ),
            ),
          ),
          // Water waves
          Positioned(
            left: 0,
            right: 0,
            top: horizonY,
            bottom: 0,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _waves,
                builder: (_, __) => CustomPaint(
                  painter: _WavesPainter(
                    time: _waves.value,
                    scale: widget.scale,
                  ),
                ),
              ),
            ),
          ),
          // Horizon line
          Positioned(
            left: 0,
            right: 0,
            top: horizonY,
            child: Container(
              height: 1,
              color: _LH.horizon.withOpacity(0.4),
            ),
          ),
          // Scrollable islands
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: _totalWidth,
                height: sceneH,
                child: Stack(
                  children: [
                    for (int m = 1; m <= 12; m++)
                      _buildIsland(
                        r: r,
                        month: m,
                        horizonY: horizonY,
                        viewportW: viewportW,
                        isCurrent: m == cm,
                        inSeason: inSeason.contains(m),
                        isExpanded: m == _expandedMonth,
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Lighthouse tower (fixed, right)
          Positioned(
            right: r.s(20),
            bottom: sceneH - horizonY + r.s(8),
            width: r.s(44),
            height: r.s(150),
            child: CustomPaint(
              painter: _TowerPainter(
                towerColor: _LH.tower,
                shadeColor: _LH.towerShade,
                lampColor: _LH.lamp,
              ),
            ),
          ),
          // Beam
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => CustomPaint(
                    painter: _BeamPainter(
                      lamp: Offset(lampX, lampY),
                      horizonY: horizonY,
                      pulse: _pulse.value,
                      expanded: _expandedMonth != null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Lamp glow
          Positioned(
            left: lampX - r.s(20),
            top: lampY - r.s(20),
            width: r.s(40),
            height: r.s(40),
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  final p = 0.6 + 0.4 * _pulse.value;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _LH.lampGlow.withOpacity(0.85 * p),
                          _LH.lampGlow.withOpacity(0.0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIsland({
    required _VS r,
    required int month,
    required double horizonY,
    required double viewportW,
    required bool isCurrent,
    required bool inSeason,
    required bool isExpanded,
  }) {
    final cx = _islandCenterX(month);
    final highlighted = isCurrent || isExpanded;
    final dim = !isCurrent && !inSeason && !isExpanded;

    final islandW = r.s(64);
    final islandH = r.s(34);

    final islandColor = highlighted
        ? _LH.current.withOpacity(0.7)
        : inSeason
        ? _LH.islandLit
        : _LH.island;

    final textColor = highlighted
        ? _LH.current
        : inSeason
        ? _LH.text
        : _LH.textFaint;

    return Positioned(
      left: cx - islandW / 2,
      top: horizonY - islandH * 0.5,
      width: islandW,
      height: islandH + r.s(30),
      child: GestureDetector(
        onTap: () => _toggleMonth(month),
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: dim ? 0.5 : 1.0,
          child: Column(
            children: [
              // Emoji on top of island
              Text(
                _monthEmoji[month],
                style: TextStyle(
                  fontSize: r.fs(16),
                  shadows: highlighted
                      ? [
                    Shadow(
                      color: _LH.lampGlow.withOpacity(0.8),
                      blurRadius: r.s(8),
                    ),
                  ]
                      : null,
                ),
              ),
              SizedBox(height: r.s(2)),
              // Island silhouette
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: islandW,
                height: islandH * 0.6,
                decoration: BoxDecoration(
                  color: islandColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(islandW * 0.5),
                  ),
                  boxShadow: highlighted
                      ? [
                    BoxShadow(
                      color: _LH.current.withOpacity(0.6),
                      blurRadius: r.s(14),
                      spreadRadius: 1,
                    ),
                  ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$month',
                  style: GoogleFonts.fraunces(
                    color: textColor,
                    fontSize: r.fs(11),
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    height: 1,
                  ),
                ),
              ),
              // Month label
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: r.s(3), vertical: r.s(1)),
                decoration: BoxDecoration(
                  color: _LH.bgDeep.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(r.s(2)),
                ),
                child: Text(
                  _monthNames[month],
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: r.fs(8),
                    fontWeight: highlighted
                        ? FontWeight.w700
                        : FontWeight.w500,
                    letterSpacing: 0.2,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(int month, _VS r) {
    final meta = metaForMonth(month);
    final products = widget.wellness.productsForMonth(month);
    final monthName = _monthFull[month];
    final isInSeason = widget.wellness.monthsWithSeason.contains(month);

    return TweenAnimationBuilder<double>(
      key: ValueKey(month),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
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
          color: _LH.water.withOpacity(0.55),
          borderRadius: BorderRadius.circular(r.s(14)),
          border: Border.all(
            color: _LH.lamp.withOpacity(0.30),
            width: 0.8,
          ),
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
                    color: _LH.lamp.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _LH.lamp.withOpacity(0.55),
                      width: 1,
                    ),
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
                          color: _LH.text,
                          fontSize: r.fs(15),
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.2,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        products.isEmpty
                            ? 'остров пуст'
                            : '${products.length} ${_productsWord(products.length)} · ${isInSeason ? "в сезоне" : "вне сезона"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: _LH.textMuted,
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
                    width: r.s(24),
                    height: r.s(24),
                    decoration: BoxDecoration(
                      color: _LH.bgDeep.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        color: _LH.lamp, size: r.fs(13)),
                  ),
                ),
              ],
            ),
            if (products.isNotEmpty) ...[
              SizedBox(height: r.s(10)),
              SizedBox(
                height: r.s(70),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: products.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: r.s(8)),
                  itemBuilder: (_, i) =>
                      _buildProductTile(products[i], r),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(ProductKnowledge k, _VS r) {
    return GestureDetector(
      onTap: () => _openProductSheet(k),
      child: Container(
        width: r.s(72),
        padding: EdgeInsets.symmetric(
            vertical: r.s(8), horizontal: r.s(6)),
        decoration: BoxDecoration(
          color: _LH.skyBottom,
          borderRadius: BorderRadius.circular(r.s(10)),
          border: Border.all(
            color: _LH.lamp.withOpacity(0.30),
            width: 0.6,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(k.emoji, style: TextStyle(fontSize: r.fs(22))),
            SizedBox(height: r.s(4)),
            Text(
              k.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _LH.text,
                fontSize: r.fs(9),
                fontWeight: FontWeight.w600,
                height: 1.1,
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

// ─── Painters ───

class _StarsPainter extends CustomPainter {
  final double time;
  final double scale;
  final Color color;
  _StarsPainter({
    required this.time,
    required this.scale,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (int i = 0; i < 24; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final baseOpacity = 0.3 + rng.nextDouble() * 0.5;
      final phase = rng.nextDouble() * math.pi * 2;
      final opacity =
          baseOpacity * (0.5 + 0.5 * math.sin(time * math.pi * 2 + phase));
      canvas.drawCircle(
        Offset(x, y),
        (0.7 + rng.nextDouble() * 1.0) * scale,
        Paint()..color = color.withOpacity(opacity * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) => old.time != time;
}

class _WavesPainter extends CustomPainter {
  final double time;
  final double scale;
  _WavesPainter({required this.time, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    for (int layer = 0; layer < 3; layer++) {
      final path = Path();
      final baseY = size.height * (0.15 + layer * 0.25);
      final amp = (3 + layer * 2) * scale;
      final phase = time * math.pi * 2 + layer * 1.2;
      path.moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 6) {
        final y = baseY + math.sin(x * 0.04 + phase) * amp;
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = _LH.horizon.withOpacity(0.4 - layer * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter old) => old.time != time;
}

class _TowerPainter extends CustomPainter {
  final Color towerColor;
  final Color shadeColor;
  final Color lampColor;
  _TowerPainter({
    required this.towerColor,
    required this.shadeColor,
    required this.lampColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Tower base (wider)
    final baseRect = Rect.fromLTWH(0, h * 0.55, w, h * 0.45);
    // Tower body (narrower top)
    final topRect = Rect.fromLTWH(w * 0.25, h * 0.2, w * 0.5, h * 0.35);

    // Draw base
    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [towerColor, shadeColor],
        ).createShader(baseRect),
    );

    // Draw body (trapezoid)
    final bodyPath = Path()
      ..moveTo(w * 0.25, h * 0.55)
      ..lineTo(w * 0.35, h * 0.20)
      ..lineTo(w * 0.65, h * 0.20)
      ..lineTo(w * 0.75, h * 0.55)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [towerColor, shadeColor],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.55)),
    );

    // Red stripes
    final stripePaint = Paint()
      ..color = const Color(0xFFA8453A).withOpacity(0.65);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.30, h * 0.35, w * 0.40, h * 0.05),
      stripePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.20, h * 0.65, w * 0.60, h * 0.05),
      stripePaint,
    );

    // Lamp room (top)
    final lampRect = Rect.fromLTWH(w * 0.30, h * 0.08, w * 0.40, h * 0.14);
    canvas.drawRect(lampRect, Paint()..color = lampColor);

    // Cap
    final capPath = Path()
      ..moveTo(w * 0.25, h * 0.08)
      ..lineTo(w * 0.5, h * 0.0)
      ..lineTo(w * 0.75, h * 0.08)
      ..close();
    canvas.drawPath(capPath, Paint()..color = shadeColor);
  }

  @override
  bool shouldRepaint(covariant _TowerPainter old) => false;
}

class _BeamPainter extends CustomPainter {
  final Offset lamp;
  final double horizonY;
  final double pulse;
  final bool expanded;

  _BeamPainter({
    required this.lamp,
    required this.horizonY,
    required this.pulse,
    required this.expanded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (expanded ? 0.55 : 0.35) * (0.85 + 0.15 * pulse);
    final spread = 60.0 + 10.0 * pulse;

    final path = Path()
      ..moveTo(lamp.dx, lamp.dy)
      ..lineTo(0, horizonY - spread)
      ..lineTo(0, horizonY + spread)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            _LH.beam.withOpacity(opacity),
            _LH.beam.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Narrow inner core
    final corePath = Path()
      ..moveTo(lamp.dx, lamp.dy)
      ..lineTo(0, horizonY - 20)
      ..lineTo(0, horizonY + 20)
      ..close();

    canvas.drawPath(
      corePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            _LH.beam.withOpacity(opacity * 0.7),
            _LH.beam.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _BeamPainter old) =>
      old.pulse != pulse || old.expanded != expanded;
}