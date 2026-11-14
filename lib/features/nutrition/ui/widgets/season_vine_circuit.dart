// lib/features/nutrition/ui/widgets/season_vine_circuit.dart
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

// ═══════════════════════════════════════════════════════════════════
//  Palette — deep PCB, brighter LEDs, warmer copper
// ═══════════════════════════════════════════════════════════════════
class _CB {
  static const bg = Color(0xFF08140C);
  static const bgDeep = Color(0xFF030906);
  static const traceInactive = Color(0xFF1E2E22);
  static const traceDim = Color(0xFF2A4030);

  static const traceGreen = Color(0xFF4AE896);
  static const traceGreenBright = Color(0xFF7DFFBC);
  static const traceGreenGlow = Color(0xFF3DDC84);

  static const currentLed = Color(0xFFFF9E70);
  static const currentBright = Color(0xFFFFC299);
  static const currentCore = Color(0xFFFFF0E0);

  static const chip = Color(0xFF16201A);
  static const chipLit = Color(0xFF2A3828);
  static const chipCurrent = Color(0xFF4A3028);
  static const chipEdge = Color(0xFF2E3A30);

  static const pin = Color(0xFFE0B860);
  static const pinBright = Color(0xFFFFD878);
  static const copper = Color(0xFFB88040);

  static const text = Color(0xFFE8F0EA);
  static const textMuted = Color(0xFF7A8A7E);
  static const textFaint = Color(0xFF40504A);
}

class _VS {
  final double scale;
  const _VS(this.scale);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

class SeasonVineCardCircuit extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCardCircuit({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  State<SeasonVineCardCircuit> createState() => _SeasonVineCardCircuitState();
}

class _SeasonVineCardCircuitState extends State<SeasonVineCardCircuit>
    with TickerProviderStateMixin {
  late final AnimationController _signal;
  late final AnimationController _pulse;
  int? _expandedMonth;

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
    _signal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _signal.dispose();
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
          center: Alignment(0, 0),
          radius: 1.2,
          colors: [_CB.bg, _CB.bgDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.65),
            blurRadius: r.s(28),
            offset: Offset(0, r.s(14)),
          ),
          BoxShadow(
            color: _CB.traceGreenGlow.withOpacity(0.10),
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
            _buildBoard(r, cm, inSeason),
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
          r.s(18), r.s(16), r.s(14), r.s(6)),
      child: Row(
        children: [
          Text('⚡', style: TextStyle(fontSize: r.fs(16))),
          SizedBox(width: r.s(6)),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'В СЕЗОНЕ · ${_monthNames[cm].toUpperCase()}',
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.jetBrainsMono(
                  color: _CB.traceGreen,
                  fontSize: r.fs(12),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: _CB.traceGreenGlow.withOpacity(0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SeasonVineStyleButton(
              scale: widget.scale, color: _CB.traceGreen),
          SizedBox(width: r.s(6)),
          GestureDetector(
            onTap: widget.onOpenKnowledge,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  r.s(10), r.s(6), r.s(8), r.s(6)),
              decoration: BoxDecoration(
                color: _CB.chip,
                borderRadius: BorderRadius.circular(r.s(4)),
                border: Border.all(color: _CB.chipEdge, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: _CB.traceGreen.withOpacity(0.15),
                    blurRadius: r.s(6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'INFO',
                    style: GoogleFonts.jetBrainsMono(
                      color: _CB.text,
                      fontSize: r.fs(9),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: r.s(4)),
                  Icon(Icons.arrow_forward_rounded,
                      color: _CB.traceGreen, size: r.fs(10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(_VS r, int cm, Set<int> inSeason) {
    final boardSize = r.s(340);
    final cx = boardSize / 2;
    final cy = boardSize / 2;
    final radius = r.s(122);
    final centerR = r.s(36);

    // 12 satellite positions in a circle
    final positions = <int, Offset>{};
    for (int m = 1; m <= 12; m++) {
      final angle = (m - 1) * (2 * math.pi / 12) - math.pi / 2;
      positions[m] = Offset(
        cx + math.cos(angle) * radius,
        cy + math.sin(angle) * radius,
      );
    }

    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Stack(
        children: [
          // PCB background
          Positioned.fill(
            child: CustomPaint(painter: _PcbBackgroundPainter()),
          ),
          // Traces + particles (from center to each satellite)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_signal, _pulse]),
                builder: (_, __) => CustomPaint(
                  painter: _RadialTracesPainter(
                    center: Offset(cx, cy),
                    positions: positions,
                    monthsWithSeason: inSeason,
                    currentMonth: cm,
                    expandedMonth: _expandedMonth,
                    signalProgress: _signal.value,
                    pulse: _pulse.value,
                    startInset: centerR,
                    endInset: r.s(28),
                    scale: widget.scale,
                  ),
                ),
              ),
            ),
          ),
          // Satellite chips
          for (int m = 1; m <= 12; m++)
            Positioned(
              left: positions[m]!.dx - r.s(30),
              top: positions[m]!.dy - r.s(26),
              width: r.s(60),
              height: r.s(52),
              child: _CircuitChip(
                month: m,
                monthShort: _monthNames[m],
                isCurrent: m == cm,
                inSeason: inSeason.contains(m),
                isExpanded: m == _expandedMonth,
                pulse: _pulse,
                r: r,
                onTap: () => _toggleMonth(m),
              ),
            ),
          // Center CPU (current month indicator)
          Positioned(
            left: cx - centerR,
            top: cy - centerR,
            width: centerR * 2,
            height: centerR * 2,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => _CenterCpu(
                currentMonth: cm,
                currentShort: _monthNames[cm],
                isExpanded: _expandedMonth == cm,
                pulse: _pulse.value,
                r: r,
                onTap: () => _toggleMonth(cm),
              ),
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
          color: _CB.chip,
          borderRadius: BorderRadius.circular(r.s(8)),
          border: Border.all(color: _CB.chipEdge, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _CB.traceGreen.withOpacity(0.15),
              blurRadius: r.s(16),
              offset: Offset(0, r.s(4)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                  r.s(12), r.s(10), r.s(10), r.s(10)),
              decoration: const BoxDecoration(
                border: Border(
                  bottom:
                  BorderSide(color: _CB.chipEdge, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: r.s(32),
                    height: r.s(32),
                    decoration: BoxDecoration(
                      color: _CB.traceGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(r.s(4)),
                      border: Border.all(
                        color: _CB.traceGreen.withOpacity(0.55),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _CB.traceGreen.withOpacity(0.20),
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
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          _monthFull[month].toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            color: _CB.text,
                            fontSize: r.fs(12),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: r.s(2)),
                        Text(
                          products.isEmpty
                              ? 'НЕТ ДАННЫХ'
                              : '${products.length} ${_productsWord(products.length).toUpperCase()} · ${isInSeason ? "ONLINE" : "OFFLINE"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            color: isInSeason
                                ? _CB.traceGreen
                                : _CB.textMuted,
                            fontSize: r.fs(9),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.6,
                            height: 1.0,
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
                        color: _CB.bg,
                        borderRadius: BorderRadius.circular(r.s(4)),
                        border: Border.all(
                            color: _CB.chipEdge, width: 0.8),
                      ),
                      child: Icon(Icons.close_rounded,
                          color: _CB.textMuted, size: r.fs(14)),
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
                    '// EMPTY',
                    style: GoogleFonts.jetBrainsMono(
                      color: _CB.textFaint,
                      fontSize: r.fs(10),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(r.s(8)),
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
          color: _CB.bg,
          borderRadius: BorderRadius.circular(r.s(4)),
          border: Border.all(
            color: _CB.traceGreen.withOpacity(0.45),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: _CB.traceGreen.withOpacity(0.15),
              blurRadius: r.s(4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(k.emoji, style: TextStyle(fontSize: r.fs(14))),
            SizedBox(width: r.s(6)),
            Text(
              k.displayName.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                color: _CB.text,
                fontSize: r.fs(10),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
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

  String _productsWord(int n) {
    if (n == 1) return 'продукт';
    if (n >= 2 && n <= 4) return 'продукта';
    return 'продуктов';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Center CPU — hexagonal "main chip" with current month
// ═══════════════════════════════════════════════════════════════════
class _CenterCpu extends StatelessWidget {
  final int currentMonth;
  final String currentShort;
  final bool isExpanded;
  final double pulse;
  final _VS r;
  final VoidCallback onTap;

  const _CenterCpu({
    required this.currentMonth,
    required this.currentShort,
    required this.isExpanded,
    required this.pulse,
    required this.r,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor =
    isExpanded ? _CB.currentLed : _CB.traceGreenGlow;
    final size = r.s(72);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow (pulsing)
            Container(
              width: size * (1.05 + 0.08 * pulse),
              height: size * (1.05 + 0.08 * pulse),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.45 + 0.35 * pulse),
                    blurRadius: r.s(20 + 10 * pulse),
                    spreadRadius: r.s(2 + 3 * pulse),
                  ),
                  BoxShadow(
                    color: glowColor.withOpacity(0.25),
                    blurRadius: r.s(36),
                    spreadRadius: r.s(6),
                  ),
                ],
              ),
            ),
            // Hexagon
            ClipPath(
              clipper: _HexClipper(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isExpanded
                        ? [_CB.chipCurrent, _CB.currentLed.withOpacity(0.5)]
                        : [_CB.chipLit, _CB.chip],
                  ),
                  border: Border.all(
                    color: glowColor,
                    width: 2.0,
                  ),
                ),
                child: Stack(
                  children: [
                    // Corner pins
                    for (final p in const [
                      Alignment.topLeft,
                      Alignment.topRight,
                      Alignment.bottomLeft,
                      Alignment.bottomRight,
                    ])
                      Align(
                        alignment: p,
                        child: Padding(
                          padding: EdgeInsets.all(r.s(4)),
                          child: Container(
                            width: r.s(3),
                            height: r.s(3),
                            decoration: BoxDecoration(
                              color: _CB.pinBright,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _CB.pinBright.withOpacity(0.7),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$currentMonth',
                            style: GoogleFonts.jetBrainsMono(
                              color: isExpanded
                                  ? _CB.currentCore
                                  : _CB.text,
                              fontSize: r.fs(24),
                              fontWeight: FontWeight.w800,
                              height: 1,
                              letterSpacing: -1,
                              shadows: [
                                Shadow(
                                  color:
                                  glowColor.withOpacity(0.9),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: r.s(2)),
                          Text(
                            currentShort.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              color: glowColor,
                              fontSize: r.fs(7),
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // LED dot (top)
            Positioned(
              top: r.s(4),
              child: Container(
                width: r.s(4),
                height: r.s(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glowColor,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withOpacity(0.9),
                      blurRadius: r.s(6),
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final radius = w / 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = cx + math.cos(angle) * radius;
      final y = cy + math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _HexClipper old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  Satellite chip
// ═══════════════════════════════════════════════════════════════════
class _CircuitChip extends StatelessWidget {
  final int month;
  final String monthShort;
  final bool isCurrent;
  final bool inSeason;
  final bool isExpanded;
  final AnimationController pulse;
  final _VS r;
  final VoidCallback onTap;

  const _CircuitChip({
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

    final Color chipColor;
    final Color borderColor;
    final Color textColor;
    final double borderW;
    if (isExpanded) {
      chipColor = _CB.chipCurrent;
      borderColor = _CB.currentBright;
      textColor = _CB.currentCore;
      borderW = 1.8;
    } else if (isCurrent) {
      chipColor = _CB.chipLit;
      borderColor = _CB.currentLed;
      textColor = _CB.text;
      borderW = 1.4;
    } else if (inSeason) {
      chipColor = _CB.chip;
      borderColor = _CB.traceGreen.withOpacity(0.85);
      textColor = _CB.text;
      borderW = 1.0;
    } else {
      chipColor = _CB.chip.withOpacity(0.55);
      borderColor = _CB.chipEdge.withOpacity(0.65);
      textColor = _CB.textFaint;
      borderW = 0.8;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(r.s(3)),
          border: Border.all(color: borderColor, width: borderW),
          boxShadow: isExpanded
              ? [
            BoxShadow(
              color: _CB.currentBright.withOpacity(0.75),
              blurRadius: r.s(18),
              spreadRadius: 3,
            ),
            BoxShadow(
              color: _CB.currentLed.withOpacity(0.35),
              blurRadius: r.s(28),
              spreadRadius: 6,
            ),
          ]
              : isCurrent
              ? [
            BoxShadow(
              color: _CB.currentLed.withOpacity(0.55),
              blurRadius: r.s(12),
              spreadRadius: 1,
            ),
          ]
              : inSeason
              ? [
            BoxShadow(
              color: _CB.traceGreen
                  .withOpacity(0.30),
              blurRadius: r.s(8),
            ),
          ]
              : null,
        ),
        child: Stack(
          children: [
            // 4 corner pins
            for (final pos in const [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ])
              Align(
                alignment: pos,
                child: Padding(
                  padding: EdgeInsets.all(r.s(2)),
                  child: Container(
                    width: r.s(2.5),
                    height: r.s(2.5),
                    decoration: BoxDecoration(
                      color: highlighted || inSeason
                          ? _CB.pinBright
                          : _CB.pin.withOpacity(0.5),
                      shape: BoxShape.circle,
                      boxShadow: highlighted || inSeason
                          ? [
                        BoxShadow(
                          color:
                          _CB.pinBright.withOpacity(0.6),
                          blurRadius: 2,
                        ),
                      ]
                          : null,
                    ),
                  ),
                ),
              ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$month',
                    style: GoogleFonts.jetBrainsMono(
                      color: textColor,
                      fontSize: r.fs(15),
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: 0.2,
                      shadows: isExpanded
                          ? [
                        Shadow(
                          color: _CB.currentBright,
                          blurRadius: 6,
                        ),
                      ]
                          : null,
                    ),
                  ),
                  SizedBox(height: r.s(2)),
                  Text(
                    monthShort.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      color: textColor.withOpacity(0.75),
                      fontSize: r.fs(6.5),
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            // LED pulse dot
            if (isExpanded)
              AnimatedBuilder(
                animation: pulse,
                builder: (_, __) {
                  final p = pulse.value;
                  return Positioned(
                    right: 3,
                    top: 3,
                    child: Container(
                      width: r.s(4 + 2 * p),
                      height: r.s(4 + 2 * p),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _CB.currentCore,
                        boxShadow: [
                          BoxShadow(
                            color: _CB.currentBright
                                .withOpacity(0.9),
                            blurRadius: r.s(4 + 4 * p),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else if (isCurrent)
              Positioned(
                right: 3,
                top: 3,
                child: Container(
                  width: r.s(3),
                  height: r.s(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _CB.currentLed,
                    boxShadow: [
                      BoxShadow(
                        color: _CB.currentLed.withOpacity(0.85),
                        blurRadius: r.s(3),
                      ),
                    ],
                  ),
                ),
              )
            else if (inSeason)
                Positioned(
                  right: 3,
                  top: 3,
                  child: Container(
                    width: r.s(3),
                    height: r.s(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _CB.traceGreen,
                      boxShadow: [
                        BoxShadow(
                          color: _CB.traceGreen.withOpacity(0.7),
                          blurRadius: r.s(3),
                        ),
                      ],
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
//  PCB background
// ═══════════════════════════════════════════════════════════════════
class _PcbBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _CB.bg,
    );

    // Via grid
    for (double x = 16; x < size.width; x += 20) {
      for (double y = 16; y < size.height; y += 20) {
        canvas.drawCircle(
          Offset(x, y),
          1.0,
          Paint()..color = _CB.chipEdge.withOpacity(0.30),
        );
      }
    }

    // Corner mounting holes with copper rings
    for (final h in [
      Offset(14, 14),
      Offset(size.width - 14, 14),
      Offset(14, size.height - 14),
      Offset(size.width - 14, size.height - 14),
    ]) {
      canvas.drawCircle(
        h,
        6,
        Paint()..color = _CB.copper.withOpacity(0.55),
      );
      canvas.drawCircle(
        h,
        3.5,
        Paint()..color = _CB.bgDeep,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PcbBackgroundPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  Radial traces — center → satellite, with flowing particles
// ═══════════════════════════════════════════════════════════════════
class _RadialTracesPainter extends CustomPainter {
  final Offset center;
  final Map<int, Offset> positions;
  final Set<int> monthsWithSeason;
  final int currentMonth;
  final int? expandedMonth;
  final double signalProgress;
  final double pulse;
  final double startInset;
  final double endInset;
  final double scale;

  _RadialTracesPainter({
    required this.center,
    required this.positions,
    required this.monthsWithSeason,
    required this.currentMonth,
    required this.expandedMonth,
    required this.signalProgress,
    required this.pulse,
    required this.startInset,
    required this.endInset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int m = 1; m <= 12; m++) {
      final target = positions[m]!;
      final isExpanded = m == expandedMonth;
      final isCurrent = m == currentMonth;
      final isInSeason = monthsWithSeason.contains(m);
      final isActive = isExpanded || isCurrent || isInSeason;

      // Compute path (from center to satellite, with 45° elbow)
      final path = _buildTracePath(center, target, startInset, endInset);

      // Determine color & width
      Color baseColor;
      double baseWidth;
      if (isExpanded) {
        baseColor = _CB.traceGreenBright;
        baseWidth = 3.0;
      } else if (isCurrent) {
        baseColor = _CB.traceGreen;
        baseWidth = 2.4;
      } else if (isInSeason) {
        baseColor = _CB.traceGreen.withOpacity(0.55);
        baseWidth = 1.8;
      } else {
        baseColor = _CB.traceInactive;
        baseWidth = 1.2;
      }

      // Glow pass
      if (isActive) {
        canvas.drawPath(
          path,
          Paint()
            ..color = (isExpanded ? _CB.traceGreenGlow : baseColor)
                .withOpacity(isExpanded ? 0.35 + 0.15 * pulse : 0.20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = baseWidth * 3.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = MaskFilter.blur(
                BlurStyle.normal, (isExpanded ? 6 : 4) * scale),
        );
      }

      // Core pass
      canvas.drawPath(
        path,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Bright inner white line for expanded
      if (isExpanded) {
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withOpacity(0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }

      // Flowing particles
      if (isExpanded || isCurrent) {
        for (final metric in path.computeMetrics()) {
          final particleCount = isExpanded ? 3 : 2;
          for (int i = 0; i < particleCount; i++) {
            final t = (signalProgress + i / particleCount) % 1.0;
            final tangent =
            metric.getTangentForOffset(t * metric.length);
            if (tangent == null) continue;
            final pos = tangent.position;

            // Glow
            canvas.drawCircle(
              pos,
              (isExpanded ? 5 : 3.5) * scale,
              Paint()
                ..color = baseColor.withOpacity(0.55)
                ..maskFilter = MaskFilter.blur(
                    BlurStyle.normal, 3 * scale),
            );
            // Core
            canvas.drawCircle(
              pos,
              (isExpanded ? 2.5 : 1.8) * scale,
              Paint()..color = Colors.white,
            );
          }
        }
      }

      // End cap dot at satellite side
      final dx = target.dx - center.dx;
      final dy = target.dy - center.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len > 0.01) {
        final ux = dx / len;
        final uy = dy / len;
        final endPoint = Offset(
          target.dx - ux * endInset,
          target.dy - uy * endInset,
        );
        canvas.drawCircle(
          endPoint,
          (isExpanded ? 3.5 : 2.0) * scale,
          Paint()
            ..color = (isExpanded ? _CB.currentBright : baseColor)
                .withOpacity(isExpanded ? 1.0 : 0.75),
        );
      }
    }
  }

  Path _buildTracePath(
      Offset from, Offset to, double startInset, double endInset) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final path = Path();
    if (len < 0.01) return path;
    final ux = dx / len;
    final uy = dy / len;
    final start = Offset(
      from.dx + ux * startInset,
      from.dy + uy * startInset,
    );
    final end = Offset(
      to.dx - ux * endInset,
      to.dy - uy * endInset,
    );

    // 45° elbow in the middle (circuit-style routing)
    // If horizontal distance is larger → go horizontal first
    // If vertical distance is larger → go vertical first
    path.moveTo(start.dx, start.dy);
    if (dx.abs() > dy.abs()) {
      final midX = (start.dx + end.dx) / 2;
      path.lineTo(midX, start.dy);
      path.lineTo(midX, end.dy);
    } else {
      final midY = (start.dy + end.dy) / 2;
      path.lineTo(start.dx, midY);
      path.lineTo(end.dx, midY);
    }
    path.lineTo(end.dx, end.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _RadialTracesPainter old) =>
      old.signalProgress != signalProgress ||
          old.pulse != pulse ||
          old.currentMonth != currentMonth ||
          old.expandedMonth != expandedMonth ||
          old.monthsWithSeason != monthsWithSeason;
}