import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════
//  WATER TAP CARD — Премиальная карточка воды с анимацией наливания
// ═══════════════════════════════════════════════════════════════════

// ─── Токены дизайна ───
class WP {
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF7C818A);
  static const elevated = Color(0xFFF0F1F4);
  static const divider = Color(0xFFE9EBEF);

  static const skySoft = Color(0xFFDCE7F5);
  static const skyMid = Color(0xFFA8C3E8);
  static const skyDeep = Color(0xFF5E84B8);
  static const skyAccent = Color(0xFF3E6BA8);

  static const chrome = Color(0xFFB8C4D0);
  static const chromeDark = Color(0xFF7A8492);
  static const chromeLight = Color(0xFFE8EEF5);
  static const chromeHighlight = Color(0xFFF5F8FC);

  static const success = Color(0xFF3DDC84);
  static const warm = Color(0xFFEF9563);
}

class WT {
  static final headline = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600, color: WP.text,
    letterSpacing: -0.2,
  );
  static final caption = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: WP.textMuted,
  );
  static final label = GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w700, color: WP.skyDeep,
    letterSpacing: 1.4,
  );
}

extension _SafeOpacity on Color {
  Color safe(double opacity) {
    final clamped = opacity.clamp(0.0, 1.0);
    if (clamped.isNaN) return withValues(alpha: 0);
    return withValues(alpha: clamped);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ОСНОВНОЙ ВИДЖЕТ
// ═══════════════════════════════════════════════════════════════════
class WaterTapCard extends StatefulWidget {
  const WaterTapCard({
    super.key,
    required this.totalMl,
    required this.goalMl,
    required this.onAdd,
  });

  final int totalMl;
  final int goalMl;
  final Future<void> Function(int ml) onAdd;

  @override
  State<WaterTapCard> createState() => _WaterTapCardState();
}

class _WaterTapCardState extends State<WaterTapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pour;
  int _shownMl = 0;
  int _lastMl = 250;
  int? _popMl;
  double _from = 0, _to = 0;
  bool _pouring = false;

  @override
  void initState() {
    super.initState();
    _shownMl = widget.totalMl;
    _pour = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pour.addListener(_onPourTick);
    _pour.addStatusListener(_onPourStatus);
  }

  void _onPourTick() {
    if (_pouring) setState(() {});
  }

  void _onPourStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _pouring) {
      _pouring = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant WaterTapCard old) {
    super.didUpdateWidget(old);
    if (widget.totalMl != old.totalMl && !_pouring) {
      _shownMl = widget.totalMl;
    }
  }

  @override
  void dispose() {
    _pour.removeListener(_onPourTick);
    _pour.removeStatusListener(_onPourStatus);
    _pour.dispose();
    super.dispose();
  }

  void _startPour(int ml) {
    if (_pouring) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pouring = true;
      _lastMl = ml;
      _popMl = ml;
      _from = (_shownMl / widget.goalMl).clamp(0.0, 1.0);
      _to = ((_shownMl + ml) / widget.goalMl).clamp(0.0, 1.0);
    });
    _pour.duration = Duration(milliseconds: 1000 + (ml * 0.8).round());
    _pour.forward(from: 0).whenComplete(() async {
      HapticFeedback.mediumImpact();
      await widget.onAdd(ml);
      if (mounted) {
        setState(() => _shownMl += ml);
      }
    });
  }

  double get _fill {
    if (!_pouring) return (_shownMl / widget.goalMl).clamp(0.0, 1.0);
    final f = ((_pour.value - 0.12) / 0.83).clamp(0.0, 1.0);
    return (_from + (_to - _from) * f).clamp(0.0, 1.0);
  }

  Future<void> _pickCustom() async {
    final ctrl = TextEditingController(text: '$_lastMl');
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [WP.surface, Color(0xFFF4F8FC)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: WP.skyDeep.safe(0.15),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: _Grabber()),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [WP.skySoft, WP.skyMid],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: WP.skyDeep.safe(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.water_drop_rounded,
                          color: WP.skyAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ДОБАВИТЬ ВОДУ', style: WT.label),
                        const SizedBox(height: 2),
                        Text('Выбери объём или введи свой',
                            style: GoogleFonts.inter(
                                color: WP.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [200, 250, 330, 500].map((ml) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _Tap(
                          onTap: () => Navigator.pop(sheetCtx, ml),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFE8F0FA), Color(0xFFDCE9F7)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: WP.skyMid.safe(0.25)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('+$ml',
                                    style: GoogleFonts.inter(
                                      color: WP.skyDeep,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    )),
                                const SizedBox(height: 2),
                                Text('мл',
                                    style: GoogleFonts.inter(
                                      color: WP.skyDeep.safe(0.55),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  autofocus: false,
                  style: WT.headline,
                  decoration: InputDecoration(
                    hintText: 'Другой объём (мл)',
                    hintStyle: WT.caption,
                    filled: true,
                    fillColor: WP.elevated,
                    prefixIcon:
                    Icon(Icons.edit_rounded, color: WP.textMuted, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: WP.skyMid.safe(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      const BorderSide(color: WP.skyDeep, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: WP.skyDeep.safe(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      final v = int.tryParse(ctrl.text.trim());
                      if (v != null && v > 0) Navigator.pop(sheetCtx, v);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WP.skyDeep,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.water_drop_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('ДОБАВИТЬ',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    ctrl.dispose();
    if (amount != null && amount > 0) _startPour(amount);
  }

  @override
  Widget build(BuildContext context) {
    final t = _pour.value;
    final fill = _fill;
    final pct = (_shownMl / widget.goalMl).clamp(0.0, 1.0);
    final reachedGoal = _to >= 1.0 || pct >= 1.0;

    final double popOp;
    if (_pouring) {
      popOp = math.min(t * 8, 1) *
          (1 - ((t - 0.78) / 0.22).clamp(0.0, 1.0));
    } else {
      popOp = 0;
    }
    final popScale = 0.7 + 0.5 * math.min(t * 8, 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WP.surface, Color(0xFFF4F8FC)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: WP.skyMid.safe(0.15)),
        boxShadow: [
          BoxShadow(
            color: WP.skyDeep.safe(0.08),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.safe(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [WP.skySoft, Color(0xFFC9DCF0)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop_rounded,
                        size: 12, color: WP.skyDeep),
                    const SizedBox(width: 4),
                    Text('ВОДА',
                        style: GoogleFonts.inter(
                          color: WP.skyDeep,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        )),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                  reachedGoal ? WP.success.safe(0.12) : WP.skySoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: reachedGoal
                        ? WP.success.safe(0.25)
                        : WP.skyMid.safe(0.15),
                  ),
                ),
                child: Text(
                  reachedGoal ? '✓ цель' : '${(pct * 100).round()}%',
                  style: GoogleFonts.inter(
                    color: reachedGoal ? WP.success : WP.skyDeep,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$_shownMl',
                  style: GoogleFonts.inter(
                    color: WP.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.2,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
              const SizedBox(width: 4),
              Text('/ ${widget.goalMl}',
                  style: GoogleFonts.inter(
                    color: WP.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
              const SizedBox(width: 4),
              Text('мл',
                  style: GoogleFonts.inter(
                    color: WP.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  )),
              const Spacer(),
              _Tap(
                onTap: _pickCustom,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: WP.elevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: WP.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.straighten_rounded,
                          size: 14, color: WP.skyDeep),
                      const SizedBox(width: 4),
                      Text('Другой',
                          style: GoogleFonts.inter(
                            color: WP.skyDeep,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _GlossyProgress(
            value: pct,
            height: 6,
            gradient: reachedGoal
                ? const [Color(0xFF3DDC84), Color(0xFF2BA868)]
                : const [WP.skyMid, WP.skyDeep],
            track: WP.divider,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _startPour(_lastMl),
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: Stack(
                children: [
                  CustomPaint(
                    painter: _ScenePainter(
                      t: t,
                      fill: fill,
                      pouring: _pouring,
                    ),
                    child: const SizedBox.expand(),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        alignment: const Alignment(-0.25, 0.05),
                        child: Opacity(
                          opacity: popOp.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: popScale,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF3E6BA8),
                                    Color(0xFF5E84B8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: WP.skyDeep.safe(0.4),
                                    blurRadius: 16,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.water_drop_rounded,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    reachedGoal
                                        ? '🎉 Норма воды выпита!'
                                        : '+${_popMl ?? 0} мл',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text('коснись стакана — нальёшь $_lastMl мл',
                style: GoogleFonts.inter(
                  color: WP.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                )),
          ),
          const SizedBox(height: 14),
          Row(
            children: [200, 250, 330, 500].map((ml) {
              final isSelected = ml == _lastMl;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _Tap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _lastMl = ml);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF3E6BA8),
                              Color(0xFF5E84B8),
                            ])
                            : null,
                        color: isSelected ? null : WP.skySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : WP.skyMid.safe(0.25),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: WP.skyDeep.safe(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('+$ml',
                              style: GoogleFonts.inter(
                                color:
                                isSelected ? Colors.white : WP.skyDeep,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              )),
                          Text('мл',
                              style: GoogleFonts.inter(
                                color: isSelected
                                    ? Colors.white.safe(0.75)
                                    : WP.skyDeep.safe(0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
// ═══════════════════════════════════════════════════════════════════
class _Grabber extends StatelessWidget {
  const _Grabber();
  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 4,
    decoration: BoxDecoration(
      color: WP.divider,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _Tap extends StatelessWidget {
  const _Tap({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _GlossyProgress extends StatelessWidget {
  final double value;
  final double height;
  final List<Color> gradient;
  final Color track;

  const _GlossyProgress({
    required this.value,
    required this.gradient,
    this.height = 6,
    this.track = const Color(0xFFE9EBEF),
  });

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: Stack(
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.last.safe(0.35),
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.42,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(100),
                          bottom: Radius.circular(100 * 0.4),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.safe(0.55),
                            Colors.white.safe(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SCENE PAINTER — ПРОФИЛЬНЫЙ КРАН + Стакан с водой
// ═══════════════════════════════════════════════════════════════════
class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.t,
    required this.fill,
    required this.pouring,
  });

  final double t;
  final double fill;
  final bool pouring;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // ─── Стакан: по центру, нижняя часть сцены ───
    final glassW = size.width * 0.30;
    final glassH = size.height * 0.48;
    final glassTop = size.height * 0.44;
    final glassBottom = glassTop + glassH;

    // ─── Тень под стаканом ───
    _drawShadow(canvas, cx, glassBottom, glassW);

    // ─── Профильный кран (крепление к стене СПРАВА, изгиб к центру) ───
    _drawProfileFaucet(canvas, cx, glassTop, size);

    // ─── Струя воды от носика крана к поверхности воды ───
    if (pouring && t > 0.08) {
      // Носик крана — по центру стакана
      final spoutTipX = cx;
      final spoutTipY = size.height * 0.32;
      final waterSurfaceY = glassBottom - 8 - fill * (glassH - 20);
      _drawStream(canvas, spoutTipX, spoutTipY + 2, waterSurfaceY);
    }

    // ─── Стакан ───
    _drawGlass(canvas, cx, glassW, glassTop, glassBottom);
  }

  // ═══ ТЕНЬ ПОД СТАКАНОМ ═══
  void _drawShadow(Canvas canvas, double cx, double bottom, double glassW) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, bottom + 6),
        width: glassW * 1.05,
        height: 8,
      ),
      Paint()
        ..color = Colors.black.safe(0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ПРОФИЛЬНЫЙ КРАН
  //  Крепится к стене СПРАВА → труба идёт влево → изгиб вниз →
  //  носик точно над центром стакана → струя падает вертикально
  // ═══════════════════════════════════════════════════════════════════
  void _drawProfileFaucet(Canvas canvas, double cx, double glassTop, Size size) {
    final pipeW = 9.0;       // толщина трубы
    final halfPipe = pipeW / 2;

    // ─── Хромовый градиент (для горизонтальных труб) ───
    final chromeH = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        WP.chromeHighlight,
        WP.chromeLight,
        WP.chrome,
        WP.chromeDark,
        WP.chrome,
        WP.chromeLight,
      ],
      stops: const [0.0, 0.2, 0.45, 0.6, 0.8, 1.0],
    );

    // ─── Хромовый градиент (для вертикальных труб) ───
    final chromeV = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        WP.chromeDark,
        WP.chrome,
        WP.chromeLight,
        WP.chromeHighlight,
        WP.chromeLight,
        WP.chrome,
        WP.chromeDark,
      ],
      stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
    );

    // ─── Ключевые точки крана ───
    final wallX = size.width - 20;          // Правый край (стена)
    final wallY = size.height * 0.06;       // Высота крепления к стене
    final horizY = wallY + 14;              // Горизонтальная труба
    final bendX = cx;                       // X-координата изгиба (= центр стакана)
    final bendTopY = horizY;               // Верх изгиба
    final spoutTipY = size.height * 0.32;   // Кончик носика

    // ════════════════════════════════════════
    //  ① НАСТЕННОЕ КРЕПЛЕНИЕ (фланец справа)
    // ════════════════════════════════════════
    final flangeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(wallX - 4, wallY - 2, 16, 36),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      flangeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            WP.chromeDark,
            WP.chrome,
            WP.chromeLight,
            WP.chrome,
            WP.chromeDark,
          ],
        ).createShader(flangeRect.outerRect),
    );
    // Винты на фланце
    canvas.drawCircle(Offset(wallX + 4, wallY + 4), 1.5,
        Paint()..color = const Color(0xFF3A4555));
    canvas.drawCircle(Offset(wallX + 4, wallY + 28), 1.5,
        Paint()..color = const Color(0xFF3A4555));

    // ════════════════════════════════════════
    //  ② ГОРИЗОНТАЛЬНАЯ ТРУБА (от стены к центру)
    // ════════════════════════════════════════
    final horizPipeRect = Rect.fromLTWH(
      bendX + 10, horizY - halfPipe,
      wallX - 4 - (bendX + 10), pipeW,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(horizPipeRect, const Radius.circular(2)),
      Paint()..shader = chromeH.createShader(horizPipeRect),
    );

    // Блик на горизонтальной трубе
    canvas.drawLine(
      Offset(bendX + 14, horizY - halfPipe + 1.5),
      Offset(wallX - 8, horizY - halfPipe + 1.5),
      Paint()
        ..color = Colors.white.safe(0.35)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    // ════════════════════════════════════════
    //  ③ ВЕНТИЛЬ (сверху на горизонтальной трубе)
    // ════════════════════════════════════════
    final knobCenterX = (bendX + wallX) / 2 + 20;
    final knobCenterY = horizY - 18;
    final knobR = 10.0;
    final knobAngle = pouring ? t * math.pi * 4 : 0.0;

    // Шток вентиля (от трубы вверх)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(knobCenterX - 2.5, horizY - 12, 5, 12),
        const Radius.circular(1.5),
      ),
      Paint()..shader = chromeV.createShader(
        Rect.fromLTWH(knobCenterX - 2.5, horizY - 12, 5, 12),
      ),
    );

    // Сам вентиль (поворачивается)
    canvas.save();
    canvas.translate(knobCenterX, knobCenterY);
    canvas.rotate(knobAngle);

    // Тело вентиля
    canvas.drawCircle(
      Offset.zero, knobR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            WP.chromeHighlight,
            WP.chromeLight,
            WP.chrome,
            WP.chromeDark,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: knobR)),
    );
    // Ободок
    canvas.drawCircle(
      Offset.zero, knobR,
      Paint()
        ..color = WP.chromeDark.safe(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Крестовина
    final crossPaint = Paint()
      ..color = const Color(0xFF3A4555)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(-knobR * 0.6, 0), Offset(knobR * 0.6, 0), crossPaint);
    canvas.drawLine(
        Offset(0, -knobR * 0.6), Offset(0, knobR * 0.6), crossPaint);
    // Центральная заклёпка
    canvas.drawCircle(Offset.zero, 2.2,
        Paint()..color = const Color(0xFF2D3748));
    canvas.drawCircle(Offset.zero, 1.0,
        Paint()..color = WP.chromeHighlight);

    canvas.restore();

    // ════════════════════════════════════════
    //  ④ ИЗГИБ (гусак) — плавный поворот от горизонтальной трубы вниз
    //  От точки (bendX + 10, horizY) → изгиб → вертикальная часть → носик в (cx, spoutTipY)
    // ════════════════════════════════════════
    final bendRadius = 22.0;
    final vertStartY = horizY + bendRadius;
    final vertEndY = spoutTipY - 8;

    // Изгиб: скруглённый угол
    final bendPath = Path()
    // Верхняя часть изгиба (горизонтальный вход)
      ..moveTo(bendX + 10, horizY - halfPipe)
    // Внешний радиус изгиба
      ..arcToPoint(
        Offset(bendX - halfPipe, vertStartY),
        radius: Radius.circular(bendRadius + halfPipe),
        clockwise: false,
      )
    // Вертикальная часть (внешняя сторона)
      ..lineTo(bendX - halfPipe, vertEndY)
    // Носик (нижний край)
      ..lineTo(bendX + halfPipe, vertEndY)
    // Вертикальная часть (внутренняя сторона)
      ..lineTo(bendX + halfPipe, vertStartY)
    // Внутренний радиус изгиба
      ..arcToPoint(
        Offset(bendX + 10, horizY + halfPipe),
        radius: Radius.circular(bendRadius - halfPipe),
        clockwise: false,
      )
      ..close();

    // Градиент для изгиба (слева направо — хром)
    canvas.drawPath(
      bendPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            WP.chromeDark,
            WP.chrome,
            WP.chromeLight,
            WP.chromeHighlight,
            WP.chromeLight,
            WP.chrome,
            WP.chromeDark,
          ],
          stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
        ).createShader(bendPath.getBounds()),
    );

    // Блик на изгибе
    canvas.drawLine(
      Offset(bendX + 1, vertStartY + 4),
      Offset(bendX + 1, vertEndY - 4),
      Paint()
        ..color = Colors.white.safe(0.35)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // ════════════════════════════════════════
    //  ⑤ НОСИК (аэратор) — на конце вертикальной части
    // ════════════════════════════════════════
    final nozzleW = pipeW * 1.4;
    final nozzleH = 7.0;
    final nozzleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(bendX, vertEndY + nozzleH / 2),
        width: nozzleW,
        height: nozzleH,
      ),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(
      nozzleRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WP.chromeLight, WP.chrome, WP.chromeDark],
        ).createShader(nozzleRect.outerRect),
    );

    // Тёмное выходное отверстие (откуда течёт вода)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bendX, vertEndY + nozzleH - 1),
        width: nozzleW * 0.55,
        height: 3.0,
      ),
      Paint()..color = const Color(0xFF1A2535),
    );

    // ════════════════════════════════════════
    //  ⑥ ДЕКОРАТИВНОЕ КОЛЬЦО на горизонтальной трубе
    // ════════════════════════════════════════
    final ringX = bendX + 30;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(ringX - 2, horizY - halfPipe - 1.5, 4, pipeW + 3),
        const Radius.circular(1),
      ),
      Paint()..color = WP.chromeDark.safe(0.5),
    );
  }

  // ═══ СТРУЯ ВОДЫ ═══
  void _drawStream(
      Canvas canvas, double spoutX, double spoutY, double waterTop) {
    final len = ((t - 0.08) / 0.15).clamp(0.0, 1.0);
    final endY = spoutY + (waterTop - spoutY) * len;
    if (endY <= spoutY + 2) return;

    // Внешняя струя
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = WP.skyDeep.safe(0.20);

    // Внутренняя струя
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = WP.skyMid.safe(0.85);

    // Блик
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.safe(0.55);

    for (final p in [outerPaint, corePaint, highlightPaint]) {
      final path = Path()..moveTo(spoutX, spoutY);
      for (double y = spoutY; y <= endY; y += 2) {
        final progress = (y - spoutY) / math.max(endY - spoutY, 1);
        final wobble =
            math.sin(t * 12 * math.pi + y * 0.08) * (1.2 - progress);
        path.lineTo(spoutX + wobble, y);
      }
      canvas.drawPath(path, p);
    }

    // Капли
    for (int i = 0; i < 5; i++) {
      final fy = ((t * 3 + i / 5) % 1);
      if (fy > len) continue;
      final y = spoutY + (endY - spoutY) * fy;
      final x = spoutX + math.sin(i * 2.5 + t * 15) * (2.5 + 1.5 * fy);
      final dropSize = 1.0 + 0.4 * (i % 2);
      canvas.drawCircle(
        Offset(x, y), dropSize,
        Paint()..color = WP.skyDeep.safe(0.35),
      );
    }

    // Брызги
    if (len > 0.9) {
      final splashIntensity = ((t - 0.3) * 2).clamp(0.0, 1.0);
      final baseOpacity = (0.35 * (1.0 - splashIntensity)).clamp(0.0, 1.0);
      if (baseOpacity > 0.01) {
        for (int i = 0; i < 4; i++) {
          final angle = (i / 4) * math.pi + t * 8;
          final dist = 5 + splashIntensity * 8;
          final sx = spoutX + math.cos(angle) * dist;
          final sy = waterTop - math.sin(angle).abs() * dist * 0.4;
          canvas.drawCircle(
            Offset(sx, sy),
            1.3 - splashIntensity * 0.4,
            Paint()..color = WP.skyDeep.safe(baseOpacity),
          );
        }
      }
    }
  }

  // ═══ СТЕКЛЯННЫЙ СТАКАН С ВОДОЙ ═══
  void _drawGlass(
      Canvas canvas, double cx, double glassW, double top, double bottom) {
    final topW = glassW;
    final bottomW = glassW * 0.88;
    final leftTop = cx - topW / 2;
    final rightTop = cx + topW / 2;
    final leftBottom = cx - bottomW / 2;
    final rightBottom = cx + bottomW / 2;

    final glassPath = Path()
      ..moveTo(leftTop, top)
      ..lineTo(leftBottom, bottom - 10)
      ..quadraticBezierTo(leftBottom, bottom, leftBottom + 7, bottom)
      ..lineTo(rightBottom - 7, bottom)
      ..quadraticBezierTo(rightBottom, bottom, rightBottom, bottom - 10)
      ..lineTo(rightTop, top)
      ..close();

    canvas.save();
    canvas.clipPath(glassPath);

    // Фон стекла
    final glassBg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.safe(0.30),
          Colors.white.safe(0.50),
          Colors.white.safe(0.65),
          Colors.white.safe(0.45),
          Colors.white.safe(0.35),
          Colors.white.safe(0.50),
          Colors.white.safe(0.25),
        ],
        stops: const [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
      ).createShader(Rect.fromLTRB(leftTop, top, rightTop, bottom));
    canvas.drawPath(glassPath, glassBg);

    // ─── ВОДА ───
    if (fill > 0.001) {
      final waterTop = bottom - 10 - fill * (bottom - top - 18);

      final waterGrad = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            WP.skyMid.safe(0.70),
            WP.skyDeep.safe(0.85),
          ],
        ).createShader(
            Rect.fromLTRB(leftBottom, waterTop, rightBottom, bottom));

      final waveAmp = pouring ? 2.5 : 1.0;
      final wavePath = Path()..moveTo(leftBottom, waterTop);
      for (double x = leftBottom; x <= rightBottom; x += 3) {
        final wave = math.sin(x * 0.15 + t * math.pi * 5) * waveAmp +
            math.sin(x * 0.08 - t * math.pi * 3) * waveAmp * 0.5;
        wavePath.lineTo(x, waterTop + wave);
      }
      wavePath.lineTo(rightBottom, bottom);
      wavePath.lineTo(leftBottom, bottom);
      wavePath.close();
      canvas.drawPath(wavePath, waterGrad);

      // Блик на поверхности воды
      canvas.drawLine(
        Offset(leftBottom + 8, waterTop + 2),
        Offset(rightBottom - 8, waterTop + 2),
        Paint()
          ..color = Colors.white.safe(0.30)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round,
      );

      // Пузырьки при наливе
      if (pouring && t > 0.2) {
        for (int i = 0; i < 7; i++) {
          final fy = ((t * 2 + i / 7) % 1);
          final bx = leftBottom + 8 +
              ((i * 47) % 80) / 80 * (rightBottom - leftBottom - 16);
          final by = bottom - 8 - fy * (bottom - waterTop - 12);
          final bSize = 0.8 + (i % 3) * 0.5;
          final bubbleOp = (0.45 * math.sin(fy * math.pi)).clamp(0.0, 1.0);
          canvas.drawCircle(
            Offset(bx, by), bSize,
            Paint()..color = Colors.white.safe(bubbleOp),
          );
        }
      }

      // Круги на воде от струи
      if (pouring && t > 0.2) {
        for (int i = 0; i < 3; i++) {
          final fy = ((t * 1.8 + i / 3) % 1);
          final ringSize = 3 + fy * 16;
          final ringOp = ((1 - fy) * 0.45).clamp(0.0, 1.0);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx, waterTop + 2),
              width: ringSize,
              height: ringSize * 0.3,
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0
              ..color = Colors.white.safe(ringOp),
          );
        }
      }
    }

    canvas.restore();

    // ─── Контур стакана ───
    canvas.drawPath(
      glassPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = WP.skyMid.safe(0.25)
        ..strokeJoin = StrokeJoin.round,
    );

    // ─── Блики на стенках ───
    canvas.drawLine(
      Offset(leftTop + 4, top + 8),
      Offset(leftBottom + 6, bottom - 14),
      Paint()
        ..color = Colors.white.safe(0.55)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(leftTop + 10, top + 14),
      Offset(leftBottom + 12, bottom - 20),
      Paint()
        ..color = Colors.white.safe(0.25)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(rightTop - 6, top + 14),
      Offset(rightBottom - 8, bottom - 22),
      Paint()
        ..color = Colors.white.safe(0.20)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // ─── Ободок сверху (хром) ───
    canvas.drawLine(
      Offset(leftTop - 2, top),
      Offset(rightTop + 2, top),
      Paint()
        ..color = WP.chrome.safe(0.45)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.t != t || old.fill != fill || old.pouring != pouring;
}