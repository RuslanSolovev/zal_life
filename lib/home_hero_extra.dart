// lib/home_hero_extra.dart
part of 'home_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  HERO EXTRA — СТИЛИ 11–15
// ═══════════════════════════════════════════════════════════════════
class _XHeroCtx {
  final _HeroData d;
  final Widget Function(double size) coin;
  final List<Widget> bgLayers;
  final String name;
  final ValueNotifier<DateTime> now;
  final VoidCallback onCart, onPantry, onSettings;
  const _XHeroCtx({
    required this.d, required this.coin, required this.bgLayers,
    required this.name, required this.now,
    required this.onCart, required this.onPantry, required this.onSettings,
  });
}

Widget buildExtraHeroStyle({required int style, required _XHeroCtx x}) {
  switch (style) {
    case 11: return _HeroVinyl(x: x);
    case 12: return _HeroTerminal(x: x);
    case 13: return _HeroOrbit(x: x);
    case 14: return _HeroSynth(x: x);
    case 15: return _HeroGravity(x: x);
    default: return _HeroVinyl(x: x);
  }
}

// ── Общая оболочка: фон + оверлеи + контент с ограничением ширины ──
Widget _xShell({
  required List<Widget> bgLayers,
  required _R r,
  required EdgeInsets padding,
  required Widget child,
  List<Widget> overlays = const [],
}) {
  return ClipRRect(
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48),
    ),
    child: Stack(
      children: [
        ...bgLayers,
        ...overlays,
        SafeArea(
          bottom: false, left: false, right: false,
          child: Padding(
            padding: padding,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.s(460)),
                child: child,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  СТИЛЬ 11 — ВИНИЛ
// ═══════════════════════════════════════════════════════════════════
class _HeroVinyl extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroVinyl({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;
    final tracks = [
      ('01', 'Уровень', 'Lv ${d.level}', _Vibrant.goldMid, false),
      ('02', 'Неделя', '${d.thisWeek}/7', _HeroAccents.amber, true),
      ('03', 'Ккал', '${d.kcal}', _HeroAccents.sage, false),
      ('04', 'Трен.', '${(d.pWorkouts * 100).round()}%', _HeroAccents.pink, false),
      ('05', 'Серия', '${d.streak} д', _HeroAccents.sky, false),
    ];
    return _xShell(
      bgLayers: x.bgLayers, r: r,
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(6), r.s(20), r.s(18)),
      child: Column(
        children: [
          Row(
            children: [
              Text('SIDE A · 33⅓ RPM',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: r.fs(9), fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  )),
              const Spacer(),
              const _EqBars(),
            ],
          ),
          SizedBox(height: r.s(10)),
          SizedBox(
            height: r.s(280),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: _VinylGrooves(coinSize: r.s(180)),
                ),
                x.coin(r.s(180)),
                Positioned(
                  right: 0, top: r.s(8),
                  child: IgnorePointer(
                    child: CustomPaint(
                      size: Size(r.s(110), r.s(150)),
                      painter: _TonearmPainter(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: r.s(12)),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: r.s(14), vertical: r.s(11)),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.42),
              borderRadius: BorderRadius.circular(r.s(18)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < tracks.length; i++) ...[
                  if (i > 0) SizedBox(height: r.s(8)),
                  Row(
                    children: [
                      SizedBox(
                        width: r.s(20),
                        child: Text(tracks[i].$1,
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: r.fs(9.5),
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                      Text(tracks[i].$2,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: r.fs(11),
                            fontWeight: FontWeight.w600,
                          )),
                      SizedBox(width: r.s(8)),
                      Expanded(
                        child: Container(height: 1,
                            color: Colors.white.withOpacity(0.08)),
                      ),
                      SizedBox(width: r.s(8)),
                      if (tracks[i].$5) ...[
                        const _EqBars(),
                        SizedBox(width: r.s(7)),
                      ],
                      Text(tracks[i].$3,
                          style: GoogleFonts.jetBrainsMono(
                            color: tracks[i].$4, fontSize: r.fs(12),
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: r.s(12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _xRoundBtn(Icons.shopping_cart_rounded, x.onCart,
                  Colors.white.withOpacity(0.14), Colors.white, r, 44),
              SizedBox(width: r.s(14)),
              _xRoundBtn(Icons.kitchen_rounded, x.onPantry,
                  _HeroAccents.peach, Colors.white, r, 54),
              SizedBox(width: r.s(14)),
              _xRoundBtn(Icons.tune_rounded, x.onSettings,
                  Colors.white.withOpacity(0.14), Colors.white, r, 44),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _xRoundBtn(IconData icon, VoidCallback onTap,
    Color fill, Color iconColor, _R r, double size) {
  return _TapScale(
    onTap: onTap,
    child: Container(
      width: r.s(size), height: r.s(size),
      decoration: BoxDecoration(
        color: fill, shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25),
              blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: Icon(icon, color: iconColor, size: r.s(size * 0.42)),
    ),
  );
}

class _VinylGrooves extends StatefulWidget {
  final double coinSize;
  const _VinylGrooves({required this.coinSize});
  @override
  State<_VinylGrooves> createState() => _VinylGroovesState();
}

class _VinylGroovesState extends State<_VinylGrooves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        painter: _VinylPainter(phase: _c.value, coinSize: widget.coinSize),
      ),
    );
  }
}

class _VinylPainter extends CustomPainter {
  final double phase, coinSize;
  _VinylPainter({required this.phase, required this.coinSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = math.min(size.width, size.height) / 2 - 2;
    final labelR = coinSize / 2;

    canvas.drawCircle(center, R, Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF1C1C1F), const Color(0xFF0B0B0D)],
      ).createShader(Rect.fromCircle(center: center, radius: R)));

    int n = 0;
    for (double rr = labelR + 6; rr < R - 3; rr += 3.2) {
      n++;
      canvas.drawCircle(center, rr, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withOpacity(n % 6 == 0 ? 0.09 : 0.04));
    }

    final rect = Rect.fromCircle(center: center, radius: R);
    canvas.drawCircle(center, R, Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.09),
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.06),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.08, 0.16, 0.5, 0.58, 0.66],
        transform: GradientRotation(phase * 2 * math.pi),
      ).createShader(rect));

    canvas.drawCircle(center, R, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withOpacity(0.14));

    final a = phase * 2 * math.pi - math.pi / 2;
    final dot = center + Offset(math.cos(a), math.sin(a)) * (R - 7);
    canvas.drawCircle(dot, 2.4, Paint()..color = _HeroAccents.peach);
    canvas.drawCircle(dot, 5, Paint()
      ..color = _HeroAccents.peach.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  @override
  bool shouldRepaint(covariant _VinylPainter old) =>
      old.phase != phase || old.coinSize != coinSize;
}

class _TonearmPainter extends CustomPainter {
  // Единичный вектор (аналог normalize) с защитой от нулевой длины
  Offset _unit(Offset v) {
    final d = v.distance;
    return d < 0.0001 ? Offset.zero : v / d;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width * 0.8, size.height * 0.11);
    final end = Offset(size.width * 0.27, size.height * 0.64);

    canvas.drawCircle(pivot + const Offset(1.5, 2), 13,
        Paint()..color = Colors.black.withOpacity(0.4));
    canvas.drawCircle(pivot, 12, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.black.withOpacity(0.5),
        ],
      ).createShader(Rect.fromCircle(center: pivot, radius: 12)));
    canvas.drawCircle(pivot, 4, Paint()..color = Colors.black.withOpacity(0.6));

    final cw = pivot + _unit(pivot - end) * 16;
    canvas.drawCircle(cw, 7, Paint()..color = Colors.white.withOpacity(0.35));

    canvas.drawLine(pivot + const Offset(1.5, 2), end + const Offset(1.5, 2),
        Paint()..color = Colors.black.withOpacity(0.4)..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(pivot, end, Paint()
      ..color = Colors.white.withOpacity(0.8)..strokeWidth = 3
      ..strokeCap = StrokeCap.round);

    final dir = _unit(end - pivot);
    final head = end + dir * 8;
    canvas.drawLine(end, head, Paint()
      ..color = _HeroAccents.peach..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    canvas.drawCircle(head, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TonearmPainter old) => false;
}

class _EqBars extends StatefulWidget {
  const _EqBars();
  @override
  State<_EqBars> createState() => _EqBarsState();
}

class _EqBarsState extends State<_EqBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final ph = _c.value * 2 * math.pi;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final h = 4 + 9 * (0.5 + 0.5 * math.sin(ph + i * 1.3));
            return Container(
              width: 2.5, height: h,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: _Vibrant.neonGreen,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  СТИЛЬ 12 — ТЕРМИНАЛ
// ═══════════════════════════════════════════════════════════════════
class _HeroTerminal extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroTerminal({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;
    const g = _Vibrant.neonGreen;

    Widget line(String label, double frac, String value) {
      final filled = (frac.clamp(0.0, 1.0) * 7).round();
      return Padding(
        padding: EdgeInsets.only(bottom: r.s(6)),
        child: Row(
          children: [
            SizedBox(
              width: r.s(86),
              child: Text('> $label',
                  style: GoogleFonts.jetBrainsMono(
                    color: g.withOpacity(0.85), fontSize: r.fs(10.5),
                    fontWeight: FontWeight.w600,
                  )),
            ),
            Text.rich(TextSpan(children: [
              TextSpan(text: '█' * filled,
                  style: GoogleFonts.jetBrainsMono(
                      color: g, fontSize: r.fs(10.5), height: 1)),
              TextSpan(text: '░' * (7 - filled),
                  style: GoogleFonts.jetBrainsMono(
                      color: g.withOpacity(0.25),
                      fontSize: r.fs(10.5), height: 1)),
            ])),
            const Spacer(),
            Text(value,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white, fontSize: r.fs(10.5),
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
          ],
        ),
      );
    }

    Widget bracket({bool left = true, bool top = true}) => Container(
      width: 14, height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: g.withOpacity(0.8), width: 1.4) : BorderSide.none,
          bottom: !top ? BorderSide(color: g.withOpacity(0.8), width: 1.4) : BorderSide.none,
          left: left ? BorderSide(color: g.withOpacity(0.8), width: 1.4) : BorderSide.none,
          right: !left ? BorderSide(color: g.withOpacity(0.8), width: 1.4) : BorderSide.none,
        ),
      ),
    );

    return _xShell(
      bgLayers: x.bgLayers, r: r,
      padding: EdgeInsets.fromLTRB(r.s(18), r.s(8), r.s(18), r.s(18)),
      overlays: [
        Positioned.fill(child: IgnorePointer(
            child: CustomPaint(painter: _ScanlinesPainter()))),
        Positioned.fill(child: IgnorePointer(child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.1,
              colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
              stops: const [0.55, 1.0],
            ),
          ),
        ))),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: r.s(8), vertical: r.s(4)),
                decoration: BoxDecoration(
                  border: Border.all(color: g.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(r.s(4)),
                ),
                child: Text('TTY-1 · ONLINE',
                    style: GoogleFonts.jetBrainsMono(
                      color: g, fontSize: r.fs(9),
                      fontWeight: FontWeight.w700, letterSpacing: 1,
                    )),
              ),
              const Spacer(),
              ValueListenableBuilder<DateTime>(
                valueListenable: x.now,
                builder: (_, n, __) => Text(
                  '${n.hour.toString().padLeft(2, '0')}:'
                      '${n.minute.toString().padLeft(2, '0')}:'
                      '${n.second.toString().padLeft(2, '0')}',
                  style: GoogleFonts.jetBrainsMono(
                    color: g.withOpacity(0.9), fontSize: r.fs(11),
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r.s(10)),
          Row(
            children: [
              _Typewriter(
                text: '${x.name}@zalife:~\$ status --today',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: r.fs(11), fontWeight: FontWeight.w600,
                ),
              ),
              const _BlinkCursor(),
            ],
          ),
          SizedBox(height: r.s(10)),
          Center(
            child: SizedBox(
              width: r.s(262), height: r.s(262),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  x.coin(r.s(240)),
                  Positioned(left: 0, top: 0, child: bracket()),
                  Positioned(right: 0, top: 0, child: bracket(left: false)),
                  Positioned(left: 0, bottom: 0, child: bracket(top: false)),
                  Positioned(right: 0, bottom: 0,
                      child: bracket(left: false, top: false)),
                ],
              ),
            ),
          ),
          SizedBox(height: r.s(12)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(r.s(12)),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(r.s(12)),
              border: Border.all(color: g.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line('level', d.levelProgress, 'LV ${d.level}'),
                line('week', d.pWorkouts, '${d.thisWeek}/7'),
                line('kcal', d.pCalories, '${d.kcal}'),
                line('train', d.pWorkouts,
                    '${(d.pWorkouts * 100).round()}%'),
                line('streak', d.pStreak, '${d.streak}d'),
                Row(
                  children: [
                    Text('> ready',
                        style: GoogleFonts.jetBrainsMono(
                          color: g, fontSize: r.fs(10.5),
                          fontWeight: FontWeight.w700,
                        )),
                    const _BlinkCursor(),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: r.s(12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _xTermKey('[cart]', x.onCart, r),
              SizedBox(width: r.s(10)),
              _xTermKey('[pantry]', x.onPantry, r),
              SizedBox(width: r.s(10)),
              _xTermKey('[cfg]', x.onSettings, r),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _xTermKey(String label, VoidCallback onTap, _R r) {
  return _TapScale(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(14), vertical: r.s(9)),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(r.s(6)),
        border: Border.all(color: _Vibrant.neonGreen.withOpacity(0.5)),
      ),
      child: Text(label,
          style: GoogleFonts.jetBrainsMono(
            color: _Vibrant.neonGreen, fontSize: r.fs(11),
            fontWeight: FontWeight.w700,
          )),
    ),
  );
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter old) => false;
}

class _Typewriter extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _Typewriter({required this.text, required this.style});
  @override
  State<_Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<_Typewriter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final n = (_c.value * widget.text.length).round();
        return Text(widget.text.substring(0, n), style: widget.style);
      },
    );
  }
}

class _BlinkCursor extends StatefulWidget {
  const _BlinkCursor();
  @override
  State<_BlinkCursor> createState() => _BlinkCursorState();
}

class _BlinkCursorState extends State<_BlinkCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 550),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: _c.value > 0.5 ? 1 : 0,
        child: Container(
          width: 7, height: 13,
          margin: const EdgeInsets.only(left: 3),
          color: _Vibrant.neonGreen,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  СТИЛЬ 13 — ОРБИТА
// ═══════════════════════════════════════════════════════════════════
class _HeroOrbit extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroOrbit({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    return _xShell(
      bgLayers: x.bgLayers, r: r,
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(6), r.s(20), r.s(18)),
      overlays: [
        Positioned.fill(child: IgnorePointer(
            child: CustomPaint(painter: _StarfieldPainter()))),
      ],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('MISSION LOG · ${_greeting().toUpperCase()}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: r.fs(9), fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    )),
              ),
              ValueListenableBuilder<DateTime>(
                valueListenable: x.now,
                builder: (_, n, __) => Text(
                  '${n.hour.toString().padLeft(2, '0')}:'
                      '${n.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.jetBrainsMono(
                    color: _HeroAccents.sky, fontSize: r.fs(11),
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r.s(8)),
          SizedBox(
            height: r.s(300),
            child: _OrbitSystem(d: x.d, coin: x.coin(r.s(160)), scale: r.scale),
          ),
          SizedBox(height: r.s(10)),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: r.s(8), vertical: r.s(9)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.38),
                ],
              ),
              borderRadius: BorderRadius.circular(r.s(18)),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _xMissionKey(Icons.shopping_cart_rounded, 'SUPPLY',
                    x.onCart, r),
                _xMissionKey(Icons.kitchen_rounded, 'CARGO',
                    x.onPantry, r),
                _xMissionKey(Icons.tune_rounded, 'SYSTEM',
                    x.onSettings, r),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _xMissionKey(IconData icon, String label, VoidCallback onTap, _R r) {
  return Expanded(
    child: _TapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: r.s(18)),
          SizedBox(height: r.s(4)),
          Text(label,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white.withOpacity(0.75),
                fontSize: r.fs(7.5), fontWeight: FontWeight.w700,
                letterSpacing: 1,
              )),
        ],
      ),
    ),
  );
}

class _OrbitSystem extends StatefulWidget {
  final _HeroData d;
  final Widget coin;
  final double scale;
  const _OrbitSystem({
    required this.d, required this.coin, required this.scale,
  });
  @override
  State<_OrbitSystem> createState() => _OrbitSystemState();
}

class _OrbitSystemState extends State<_OrbitSystem>
    with TickerProviderStateMixin {
  late final AnimationController _inner = AnimationController(
    vsync: this, duration: const Duration(seconds: 22),
  )..repeat();
  late final AnimationController _outer = AnimationController(
    vsync: this, duration: const Duration(seconds: 34),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _inner.dispose();
    _outer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final d = widget.d;
    final chips = [
      (Icons.star_rounded, _Vibrant.goldMid, 'Lv ${d.level}', 'LVL', 0),
      (Icons.calendar_view_week_rounded, _HeroAccents.amber,
      '${d.thisWeek}/7', 'WK', 1),
      (Icons.local_fire_department_rounded, _HeroAccents.sage,
      '${d.kcal}', 'KCAL', 2),
      (Icons.fitness_center_rounded, _HeroAccents.pink,
      '${(d.pWorkouts * 100).round()}%', 'TRN', 3),
      (Icons.bolt_rounded, _HeroAccents.sky, '${d.streak} д', 'STR', 4),
    ];
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth, h = c.maxHeight;
      final center = Offset(w / 2, h / 2);
      return AnimatedBuilder(
        animation: Listenable.merge([_inner, _outer]),
        builder: (_, __) {
          final behind = <Widget>[];
          final front = <Widget>[];
          for (int i = 0; i < chips.length; i++) {
            final isInner = i < 3;
            final rx = (isInner ? 112 : 134) * s;
            final ry = (isInner ? 84 : 112) * s;
            final phase = isInner ? _inner.value : (1 - _outer.value);
            final offset = isInner
                ? i * 2 * math.pi / 3
                : (i == 3 ? math.pi / 2 : 3 * math.pi / 2);
            final a = phase * 2 * math.pi + offset;
            final pos = center + Offset(math.cos(a) * rx, math.sin(a) * ry);
            final depth = (math.sin(a) + 1) / 2; // 0 = далеко, 1 = близко
            final sc = 0.86 + 0.14 * depth;
            final cw = 74 * s, ch = 36 * s;
            final chip = Positioned(
              left: pos.dx - cw / 2, top: pos.dy - ch / 2,
              child: Transform.scale(
                scale: sc,
                child: Opacity(
                  opacity: 0.7 + 0.3 * depth,
                  child: Container(
                    width: cw, height: ch,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(12 * s),
                      border: Border.all(
                          color: chips[i].$2.withOpacity(0.55)),
                      boxShadow: [
                        BoxShadow(
                          color: chips[i].$2.withOpacity(0.25 * depth),
                          blurRadius: 12, spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(chips[i].$1, color: chips[i].$2,
                                size: 10 * s),
                            SizedBox(width: 4 * s),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(chips[i].$3,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.white,
                                      fontSize: 10.5 * s,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    )),
                              ),
                            ),
                          ],
                        ),
                        Text(chips[i].$4,
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 6.5 * s, letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            );
            (math.sin(a) < 0 ? behind : front).add(chip);
          }
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrbitPathsPainter(
                    innerRx: 112 * s, innerRy: 84 * s,
                    outerRx: 134 * s, outerRy: 112 * s,
                    shootT: _outer.value,
                  ),
                ),
              ),
              ...behind,
              Center(child: widget.coin),
              ...front,
            ],
          );
        },
      );
    });
  }
}

class _OrbitPathsPainter extends CustomPainter {
  final double innerRx, innerRy, outerRx, outerRy, shootT;
  _OrbitPathsPainter({
    required this.innerRx, required this.innerRy,
    required this.outerRx, required this.outerRy, required this.shootT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withOpacity(0.12);
    canvas.drawOval(Rect.fromCenter(center: center,
        width: innerRx * 2, height: innerRy * 2), p);
    canvas.drawOval(Rect.fromCenter(center: center,
        width: outerRx * 2, height: outerRy * 2),
        p..color = Colors.white.withOpacity(0.08));

    // падающая звезда в начале цикла
    if (shootT < 0.1) {
      final t = shootT / 0.1;
      final start = Offset(size.width * (0.1 + 0.7 * t), 12 + 40 * t);
      final tail = start - const Offset(26, 10);
      canvas.drawLine(tail, start, Paint()
        ..color = Colors.white.withOpacity(0.7 * (1 - t))
        ..strokeWidth = 1.4..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPathsPainter old) =>
      old.shootT != shootT;
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(11);
    for (int i = 0; i < 70; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5 + rng.nextDouble() * 1.1,
          Paint()..color = Colors.white.withOpacity(0.2 + rng.nextDouble() * 0.5));
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  СТИЛЬ 14 — СИНТВЕЙВ
// ═══════════════════════════════════════════════════════════════════
class _Synth {
  static const pink = Color(0xFFFF2E97);
  static const cyan = Color(0xFF00E5FF);
  static const purple = Color(0xFF8B5CFF);
  static const orange = Color(0xFFFF9E4A);
}

class _HeroSynth extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroSynth({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;
    final cards = [
      ('LV ${d.level}', 'УРОВЕНЬ', _Vibrant.goldMid),
      ('${d.thisWeek}/7', 'НЕДЕЛЯ', _Synth.pink),
      ('${d.kcal}', 'ККАЛ', _Synth.cyan),
      ('${(d.pWorkouts * 100).round()}%', 'ТРЕН.', _Synth.purple),
      ('${d.streak}д', 'СЕРИЯ', _Synth.orange),
    ];
    return _xShell(
      bgLayers: x.bgLayers, r: r,
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(8), r.s(20), r.s(18)),
      overlays: [
        Positioned(
          left: 0, right: 0, bottom: 0, height: r.s(210),
          child: IgnorePointer(child: _SynthGrid()),
        ),
      ],
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_Synth.cyan, Colors.white, _Synth.pink],
            ).createShader(rect),
            child: Text(_greeting().toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white, fontSize: r.fs(17),
                  fontWeight: FontWeight.w800, letterSpacing: 2,
                )),
          ),
          SizedBox(height: r.s(4)),
          Text(x.name.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white.withOpacity(0.6),
                fontSize: r.fs(9.5), letterSpacing: 3,
                fontWeight: FontWeight.w700,
              )),
          SizedBox(height: r.s(8)),
          SizedBox(
            height: r.s(240),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: -r.s(18),
                  child: IgnorePointer(
                    child: CustomPaint(
                      size: Size(r.s(240), r.s(240)),
                      painter: _SynthSunPainter(),
                    ),
                  ),
                ),
                Positioned(top: r.s(52), child: x.coin(r.s(190))),
              ],
            ),
          ),
          SizedBox(height: r.s(10)),
          Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) SizedBox(width: r.s(7)),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.s(6), vertical: r.s(9)),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(r.s(12)),
                      border: Border.all(
                          color: cards[i].$3.withOpacity(0.8), width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: cards[i].$3.withOpacity(0.4),
                          blurRadius: 12, spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(cards[i].$1,
                              style: GoogleFonts.orbitron(
                                color: Colors.white, fontSize: r.fs(12.5),
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              )),
                        ),
                        SizedBox(height: r.s(4)),
                        Text(cards[i].$2,
                            style: GoogleFonts.jetBrainsMono(
                              color: cards[i].$3.withOpacity(0.9),
                              fontSize: r.fs(7), letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: r.s(12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _xNeonBtn(Icons.shopping_cart_rounded, x.onCart, _Synth.cyan, r),
              SizedBox(width: r.s(14)),
              _xNeonBtn(Icons.kitchen_rounded, x.onPantry, _Synth.pink, r),
              SizedBox(width: r.s(14)),
              _xNeonBtn(Icons.tune_rounded, x.onSettings, _Synth.purple, r),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _xNeonBtn(IconData icon, VoidCallback onTap, Color color, _R r) {
  return _TapScale(
    onTap: onTap,
    child: Container(
      width: r.s(46), height: r.s(46),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.6),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5),
              blurRadius: 14, spreadRadius: -2),
        ],
      ),
      child: Icon(icon, color: color, size: r.s(19)),
    ),
  );
}

class _SynthGrid extends StatefulWidget {
  @override
  State<_SynthGrid> createState() => _SynthGridState();
}

class _SynthGridState extends State<_SynthGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        painter: _SynthGridPainter(phase: _c.value),
        size: Size.infinite,
      ),
    );
  }
}

class _SynthGridPainter extends CustomPainter {
  final double phase;
  _SynthGridPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final vp = Offset(size.width / 2, 0);
    final paint = Paint()
      ..color = _Synth.pink.withOpacity(0.4)
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    for (int i = -7; i <= 7; i++) {
      final bottom = Offset(size.width / 2 + i * size.width * 0.16, size.height);
      canvas.drawLine(vp, bottom, paint);
    }
    for (int i = 0; i < 9; i++) {
      final t = (i + phase) / 9;
      final y = size.height * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          paint..color = _Synth.pink.withOpacity(0.15 + 0.35 * t));
    }
    canvas.drawLine(Offset(0, 0.5), Offset(size.width, 0.5), Paint()
      ..color = _Synth.cyan.withOpacity(0.7)
      ..strokeWidth = 1.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
  }

  @override
  bool shouldRepaint(covariant _SynthGridPainter old) => old.phase != phase;
}

class _SynthSunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2 - 4;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawCircle(center, R, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD166), _Synth.orange, _Synth.pink],
      ).createShader(Rect.fromCircle(center: center, radius: R)));
    final clear = Paint()..blendMode = BlendMode.clear;
    for (int i = 0; i < 6; i++) {
      final y = center.dy + R * 0.1 + i * R * 0.15;
      canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, 2.5 + i * 1.6), clear);
    }
    canvas.restore();
    canvas.drawCircle(center, R, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _Synth.pink.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  @override
  bool shouldRepaint(covariant _SynthSunPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  СТИЛЬ 15 — ГРАВИТАЦИЯ: ШАРЫ НА СТОЛЕ (НАКЛОН ТЕЛЕФОНА)
// ═══════════════════════════════════════════════════════════════════
class _Ball {
  Offset pos, vel;
  double spin;
  final double r;
  final Color color;
  final IconData icon;
  final String value, label;
  _Ball({
    required this.pos, required this.vel, required this.r,
    required this.color, required this.icon,
    required this.value, required this.label, this.spin = 0,
  });
}

enum _TiltMode { sensor, finger }

class _HeroGravity extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroGravity({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    return _xShell(
      bgLayers: x.bgLayers, r: r,
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(6), r.s(20), r.s(18)),
      child: Column(
        children: [
          Row(
            children: [
              _heroIconBtn(Icons.shopping_cart_rounded, x.onCart, r, size: 38),
              SizedBox(width: r.s(8)),
              _heroIconBtn(Icons.kitchen_rounded, x.onPantry, r, size: 38),
              SizedBox(width: r.s(8)),
              _heroIconBtn(Icons.tune_rounded, x.onSettings, r, size: 38),
              const Spacer(),
              Text('TILT TABLE',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: r.fs(9), fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  )),
            ],
          ),
          SizedBox(height: r.s(8)),
          SizedBox(
            height: r.s(400),
            child: _GravityArena(
              d: x.d, coin: x.coin(r.s(190)), scale: r.scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _GravityArena extends StatefulWidget {
  final _HeroData d;
  final Widget coin;
  final double scale;
  const _GravityArena({
    required this.d, required this.coin, required this.scale,
  });
  @override
  State<_GravityArena> createState() => _GravityArenaState();
}

class _GravityArenaState extends State<_GravityArena>
    with SingleTickerProviderStateMixin {
  List<_Ball>? _balls;
  Size _size = Size.zero;
  int _grab = -1;
  bool _touched = false;
  Duration _last = Duration.zero;
  late final _ticker = createTicker(_onTick);

  StreamSubscription<AccelerometerEvent>? _sub;
  Timer? _probe;
  _TiltMode _mode = _TiltMode.sensor;
  bool _sensorOk = false;
  bool _heard = false;

  Offset _raw = Offset.zero;    // сглаженный наклон, экранные координаты
  Offset _zero = Offset.zero;   // калибровка «уровня»
  Offset _g = Offset.zero;      // гравитация, px/s²
  Offset _finger = Offset.zero; // виртуальный наклон пальцем (-1..1)
  bool _fingerDrag = false;

  @override
  void initState() {
    super.initState();
    _ticker.start(); // первое обращение к полю → оно создаётся и запускается
    _initSensor();
  }

  void _initSensor() {
    _sub?.cancel();
    _heard = false;
    try {
      _sub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
            (e) {
          final first = !_heard;
          _heard = true;
          _sensorOk = true;
          // экранные координаты: x вправо, y вниз
          _raw = Offset.lerp(_raw, Offset(-e.x, e.y), 0.18)!;
          if (first && mounted) setState(() {});
        },
        onError: (_) {
          _sensorOk = false;
          if (mounted) setState(() => _mode = _TiltMode.finger);
        },
        cancelOnError: true,
      );
    } catch (_) {
      _sensorOk = false;
      _mode = _TiltMode.finger;
    }
    _probe?.cancel();
    _probe = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        if (!_heard) {
          _sensorOk = false;
          _mode = _TiltMode.finger;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _probe?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  List<_Ball> _spawn(double w, double h) {
    final s = widget.scale;
    final d = widget.d;
    final rng = math.Random(3);
    final specs = [
      (Icons.star_rounded, _Vibrant.goldMid, 'Lv ${d.level}', 'LVL'),
      (Icons.calendar_view_week_rounded, _HeroAccents.amber,
      '${d.thisWeek}/7', 'WK'),
      (Icons.local_fire_department_rounded, _HeroAccents.sage,
      '${d.kcal}', 'KCAL'),
      (Icons.fitness_center_rounded, _HeroAccents.pink,
      '${(d.pWorkouts * 100).round()}%', 'TRN'),
      (Icons.bolt_rounded, _HeroAccents.sky, '${d.streak}д', 'STR'),
    ];
    return List.generate(5, (i) => _Ball(
      pos: Offset(w * (0.14 + 0.18 * i), 34 * s + (i.isOdd ? 26 * s : 0)),
      vel: Offset((rng.nextDouble() - 0.5) * 140, 0),
      r: 32 * s,
      color: specs[i].$2, icon: specs[i].$1,
      value: specs[i].$3, label: specs[i].$4,
      spin: rng.nextDouble() * math.pi * 2,
    ));
  }

  void _shake() {
    final balls = _balls;
    if (balls == null) return;
    HapticFeedback.mediumImpact();
    final rng = math.Random();
    setState(() {
      _touched = true;
      for (final b in balls) {
        b.vel = Offset((rng.nextDouble() - 0.5) * 500,
            -420 - rng.nextDouble() * 420);
      }
    });
  }

  void _calibrate() {
    HapticFeedback.selectionClick();
    setState(() {
      _zero = _raw;
      _finger = Offset.zero;
      _touched = true;
    });
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    if (_sensorOk) {
      setState(() {
        _mode = _mode == _TiltMode.sensor ? _TiltMode.finger : _TiltMode.sensor;
        _finger = Offset.zero;
        _touched = true;
      });
    } else {
      setState(() => _mode = _TiltMode.sensor);
      _initSensor();
    }
  }

  void _updateFinger(Offset p) {
    final w = _size.width, h = _size.height;
    var f = Offset((p.dx - w / 2) / (w / 2), (p.dy - h / 2) / (h / 2));
    final m = f.distance;
    if (m > 1) f = f / m;
    _finger = f;
  }

  void _onTick(Duration elapsed) {
    final balls = _balls;
    if (balls == null || _size == Size.zero) { _last = elapsed; return; }
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.033);
    _last = elapsed;
    if (dt == 0) return;

    final s = widget.scale;
    final w = _size.width, h = _size.height;
    final coinC = Offset(w / 2, 118 * s);
    final coinR = 95 * s;

    // ── целевая гравитация ──
    Offset target;
    if (_mode == _TiltMode.sensor && _sensorOk) {
      var t = _raw - _zero;
      final m = t.distance;
      if (m > 14) t = t / m * 14;
      target = t * 95.0;
    } else {
      if (!_fingerDrag) {
        _finger = Offset.lerp(_finger, Offset.zero, 1 - math.exp(-dt * 6))!;
      }
      target = _finger * 950.0;
    }
    final prevG = _g;
    _g = Offset.lerp(_g, target, 1 - math.exp(-dt * 9))!;
    final gMag = _g.distance;
    bool moved = (_g - prevG).distance > 0.4;

    // ── интеграция ──
    for (int i = 0; i < balls.length; i++) {
      final b = balls[i];
      if (i == _grab) continue;
      final old = b.pos;

      b.vel = (b.vel + _g * dt) * math.exp(-dt * 1.1); // трение качения
      if (gMag < 22 && b.vel.distance < 10) b.vel = Offset.zero;
      b.pos = b.pos + b.vel * dt;

      if (b.pos.dx - b.r < 0) {
        b.pos = Offset(b.r, b.pos.dy);
        if (b.vel.dx < 0) {
          var v = -b.vel.dx * 0.55;
          if (v < 45) v = 0;
          b.vel = Offset(v, b.vel.dy * 0.985);
        }
      }
      if (b.pos.dx + b.r > w) {
        b.pos = Offset(w - b.r, b.pos.dy);
        if (b.vel.dx > 0) {
          var v = -b.vel.dx * 0.55;
          if (v.abs() < 45) v = 0;
          b.vel = Offset(v, b.vel.dy * 0.985);
        }
      }
      if (b.pos.dy - b.r < 0) {
        b.pos = Offset(b.pos.dx, b.r);
        if (b.vel.dy < 0) {
          var v = -b.vel.dy * 0.55;
          if (v.abs() < 45) v = 0;
          b.vel = Offset(b.vel.dx * 0.985, v);
        }
      }
      if (b.pos.dy + b.r > h) {
        b.pos = Offset(b.pos.dx, h - b.r);
        if (b.vel.dy > 0) {
          var v = -b.vel.dy * 0.55;
          if (v.abs() < 45) v = 0;
          b.vel = Offset(b.vel.dx * 0.985, v);
        }
      }

      // кольца — препятствие
      final delta = b.pos - coinC;
      final dist = delta.distance;
      final minD = b.r + coinR;
      if (dist < minD && dist > 0.001) {
        final n = delta / dist;
        b.pos = coinC + n * minD;
        final vn = b.vel.dx * n.dx + b.vel.dy * n.dy;
        if (vn < 0) {
          b.vel = (b.vel - n * vn * 1.55) * 0.85;
          if (b.vel.distance < 18 && gMag < 30) b.vel = Offset.zero;
        }
      }

      b.spin += b.vel.distance / b.r * dt * (b.vel.dx >= 0 ? 1 : -1);
      if ((b.pos - old).distance > 0.15) moved = true;
    }

    // ── шар ↔ шар ──
    for (int i = 0; i < balls.length; i++) {
      for (int j = i + 1; j < balls.length; j++) {
        final a = balls[i], b = balls[j];
        final delta = b.pos - a.pos;
        final dist = delta.distance;
        final minD = a.r + b.r;
        if (dist < minD && dist > 0.001) {
          final n = delta / dist;
          final push = (minD - dist) / 2;
          if (i != _grab) a.pos = a.pos - n * push;
          if (j != _grab) b.pos = b.pos + n * push;
          final rel = b.vel - a.vel;
          final vn = rel.dx * n.dx + rel.dy * n.dy;
          if (vn < 0) {
            final imp = n * vn * 0.85;
            if (i != _grab) a.vel = a.vel + imp;
            if (j != _grab) b.vel = b.vel - imp;
          }
          moved = true;
        }
      }
    }

    if (moved || _grab >= 0 || _fingerDrag) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return LayoutBuilder(builder: (_, c) {
      _size = Size(c.maxWidth, c.maxHeight);
      final w = _size.width, h = _size.height;
      final balls = _balls ??= _spawn(w, h);
      final gMag = _g.distance;
      final gDir = gMag > 1 ? _g / gMag : Offset.zero;

      final tiltVec = (_mode == _TiltMode.sensor && _sensorOk)
          ? (_raw - _zero) / 9.81
          : _finger;
      final tm = tiltVec.distance;
      final tilt = tm > 1 ? tiltVec / tm : tiltVec;
      final deg = (math.asin(tm.clamp(0.0, 1.0)) * 180 / math.pi).round();

      final String modeLabel;
      if (_mode == _TiltMode.sensor) {
        modeLabel = _sensorOk ? '📱 ГИРО · $deg°' : '📱 ПОИСК…';
      } else {
        modeLabel = _sensorOk ? '👆 ПАЛЕЦ' : '👆 НЕТ ДАТЧИКА';
      }

      Widget chip(Widget child, VoidCallback onTap) => _TapScale(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: 9 * s, vertical: 6 * s),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      );

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: _shake,
        onPanStart: (e) {
          for (int i = balls.length - 1; i >= 0; i--) {
            if ((balls[i].pos - e.localPosition).distance <
                balls[i].r + 14) {
              setState(() { _grab = i; _touched = true; });
              HapticFeedback.selectionClick();
              return;
            }
          }
          if (_mode == _TiltMode.finger || !_sensorOk) {
            setState(() {
              _fingerDrag = true;
              _touched = true;
              _updateFinger(e.localPosition);
            });
          }
        },
        onPanUpdate: (e) {
          if (_grab >= 0) {
            final b = balls[_grab];
            setState(() {
              b.pos = Offset(
                e.localPosition.dx.clamp(b.r, w - b.r),
                e.localPosition.dy.clamp(b.r, h - b.r),
              );
              final v = e.delta / 0.016;
              final speed = v.distance.clamp(0.0, 1600.0);
              b.vel = v.distance > 0 ? v / v.distance * speed : Offset.zero;
            });
          } else if (_fingerDrag) {
            setState(() => _updateFinger(e.localPosition));
          }
        },
        onPanEnd: (_) => setState(() { _grab = -1; _fingerDrag = false; }),
        onPanCancel: () => setState(() { _grab = -1; _fingerDrag = false; }),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── столешница ──
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26 * s),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.09), width: 1.2),
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2), radius: 1.15,
                      colors: [
                        Colors.white.withOpacity(0.045),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            for (final corner in const [
              Alignment.topLeft, Alignment.topRight,
              Alignment.bottomLeft, Alignment.bottomRight,
            ])
              Positioned(
                left: corner.x < 0 ? 9 * s : null,
                right: corner.x > 0 ? 9 * s : null,
                top: corner.y < 0 ? 9 * s : null,
                bottom: corner.y > 0 ? 9 * s : null,
                child: IgnorePointer(
                  child: Container(
                    width: 4 * s, height: 4 * s,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            // ── кольца-препятствие ──
            Positioned(
              left: w / 2 - 95 * s, top: 23 * s,
              child: widget.coin,
            ),
            // ── шары ──
            for (final b in balls)
              Positioned(
                left: b.pos.dx - b.r, top: b.pos.dy - b.r,
                child: Container(
                  width: b.r * 2, height: b.r * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment(
                          -0.5 - gDir.dx * 0.5, -0.5 - gDir.dy * 0.5),
                      end: Alignment(
                          0.5 + gDir.dx * 0.5, 0.5 + gDir.dy * 0.5),
                      colors: [
                        b.color.withOpacity(0.38),
                        Colors.black.withOpacity(0.52),
                      ],
                    ),
                    border: Border.all(
                        color: b.color.withOpacity(0.7), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 10, offset: gDir * 4,
                      ),
                      BoxShadow(
                        color: b.color.withOpacity(0.3),
                        blurRadius: 14, spreadRadius: -3,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Transform.rotate(
                        angle: b.spin,
                        child: SizedBox.expand(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 3.5 * s, height: 3.5 * s,
                              margin: EdgeInsets.only(top: 3 * s),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(b.icon, color: b.color, size: 12 * s),
                            SizedBox(height: 2 * s),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding:
                                EdgeInsets.symmetric(horizontal: 4 * s),
                                child: Text(b.value,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 11 * s,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    )),
                              ),
                            ),
                            Text(b.label,
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 6 * s, letterSpacing: 1,
                                  fontWeight: FontWeight.w700,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // ── управление ──
            Positioned(
              left: 10 * s, top: 10 * s,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  chip(
                    Text(modeLabel,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 8.5 * s, fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        )),
                    _toggleMode,
                  ),
                  SizedBox(width: 6 * s),
                  chip(
                    Icon(Icons.center_focus_strong_rounded,
                        color: Colors.white.withOpacity(0.85),
                        size: 13 * s),
                    _calibrate,
                  ),
                  SizedBox(width: 6 * s),
                  chip(
                    Icon(Icons.vibration_rounded,
                        color: Colors.white.withOpacity(0.85),
                        size: 13 * s),
                    _shake,
                  ),
                ],
              ),
            ),
            // ── пузырьковый уровень ──
            Positioned(
              right: 10 * s, top: 10 * s,
              child: IgnorePointer(
                child: CustomPaint(
                  size: Size(40 * s, 40 * s),
                  painter: _LevelBubblePainter(tilt: tilt),
                ),
              ),
            ),
            // ── подсказка ──
            Positioned(
              left: 0, right: 0, bottom: 10 * s,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _touched ? 0 : 0.9,
                  duration: const Duration(milliseconds: 400),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10 * s, vertical: 5 * s),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        _mode == _TiltMode.sensor && _sensorOk
                            ? 'наклоняй телефон · 2×тап — встряска'
                            : 'тяни по столу — наклон · 2×тап — встряска',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 9 * s, fontWeight: FontWeight.w600,
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
    });
  }
}

class _LevelBubblePainter extends CustomPainter {
  final Offset tilt; // -1..1 по каждой оси
  _LevelBubblePainter({required this.tilt});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2 - 1;
    canvas.drawCircle(c, R, Paint()
      ..color = Colors.black.withOpacity(0.4));
    canvas.drawCircle(c, R, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.3));
    canvas.drawCircle(c, R * 0.45, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = Colors.white.withOpacity(0.14));
    final line = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 0.7;
    canvas.drawLine(Offset(c.dx - R, c.dy), Offset(c.dx + R, c.dy), line);
    canvas.drawLine(Offset(c.dx, c.dy - R), Offset(c.dx, c.dy + R), line);
    final b = c + tilt * (R - 5);
    canvas.drawCircle(b, 5, Paint()
      ..color = _HeroAccents.peach.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(b, 3.4, Paint()..color = _HeroAccents.peach);
    canvas.drawCircle(b - const Offset(0.8, 0.8), 1.1,
        Paint()..color = Colors.white.withOpacity(0.8));
  }

  @override
  bool shouldRepaint(covariant _LevelBubblePainter old) => old.tilt != tilt;
}

// ═══════════════════════════════════════════════════════════════════
//  ПРЕВЬЮ ДЛЯ СТИЛЕЙ 11–15
// ═══════════════════════════════════════════════════════════════════
class _HeroExtraStylePreview extends StatelessWidget {
  final int style;
  const _HeroExtraStylePreview({required this.style});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth, h = c.maxHeight;
      final u = h / 110;

      Widget circle(double s, Color color, {double bw = 1.3}) => Container(
        width: s, height: s,
        decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: color, width: bw)),
      );
      Widget rings(double s) => SizedBox(
        width: s, height: s,
        child: Stack(alignment: Alignment.center, children: [
          circle(s, _HeroAccents.peach.withOpacity(0.85)),
          circle(s * 0.66, _HeroAccents.amber.withOpacity(0.8)),
          circle(s * 0.38, _HeroAccents.sage.withOpacity(0.8)),
          Container(width: s * 0.13, height: s * 0.13,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle)),
        ]),
      );
      Widget dot(double s, {Color? fill}) => Container(
        width: s, height: s,
        decoration: BoxDecoration(
          color: fill ?? Colors.white.withOpacity(0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 0.7),
        ),
      );
      Widget pill(double pw, double ph, {Color? fill}) => Container(
        width: pw, height: ph,
        decoration: BoxDecoration(
          color: fill ?? Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 0.7),
        ),
      );
      Widget line(double lw, {Color? color, double lh = 3}) => Container(
        width: lw, height: lh * u,
        decoration: BoxDecoration(
          color: color ?? Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(100),
        ),
      );
      Widget row(Widget child) =>
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [child]);

      final items = <Widget>[];
      switch (style) {
        case 11: // Винил
          items.addAll([
            Positioned(left: 0, right: 0, top: 8 * u,
                child: row(SizedBox(
                  width: 62 * u, height: 62 * u,
                  child: Stack(alignment: Alignment.center, children: [
                    circle(62 * u, Colors.white.withOpacity(0.25)),
                    circle(52 * u, Colors.white.withOpacity(0.15)),
                    circle(42 * u, Colors.white.withOpacity(0.15)),
                    rings(30 * u),
                    Transform.rotate(angle: 0.6,
                        child: Transform.translate(
                            offset: Offset(20 * u, -14 * u),
                            child: Container(width: 1.6, height: 26 * u,
                                color: Colors.white.withOpacity(0.7)))),
                  ]),
                ))),
            Positioned(left: 14 * u, bottom: 26 * u, child: line(46 * u)),
            Positioned(left: 14 * u, bottom: 19 * u, child: line(38 * u)),
            Positioned(left: 14 * u, bottom: 12 * u, child: line(42 * u)),
            Positioned(left: 0, right: 0, bottom: 4 * u,
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      dot(6 * u), SizedBox(width: 6 * u),
                      dot(8 * u, fill: _HeroAccents.peach),
                      SizedBox(width: 6 * u), dot(6 * u),
                    ])),
          ]);
          break;
        case 12: // Терминал
          const g = _Vibrant.neonGreen;
          items.addAll([
            Positioned(left: 8 * u, top: 7 * u,
                child: line(34 * u, color: g.withOpacity(0.8))),
            Positioned(right: 8 * u, top: 7 * u,
                child: line(14 * u, color: g.withOpacity(0.6))),
            Positioned(left: 0, right: 0, top: 18 * u, child: row(rings(42 * u))),
            Positioned(left: 30 * u, top: 16 * u,
                child: Container(width: 6 * u, height: 6 * u,
                    decoration: BoxDecoration(border: Border(
                      top: BorderSide(color: g.withOpacity(0.8), width: 1.1),
                      left: BorderSide(color: g.withOpacity(0.8), width: 1.1),
                    )))),
            Positioned(right: 30 * u, top: 56 * u,
                child: Container(width: 6 * u, height: 6 * u,
                    decoration: BoxDecoration(border: Border(
                      bottom: BorderSide(color: g.withOpacity(0.8), width: 1.1),
                      right: BorderSide(color: g.withOpacity(0.8), width: 1.1),
                    )))),
            for (int l = 0; l < 2; l++)
              Positioned(left: 14 * u, bottom: (24 - l * 8) * u,
                  child: Row(children: [
                    line(16 * u, color: g.withOpacity(0.7)),
                    SizedBox(width: 4 * u),
                    for (int i = 0; i < 7; i++)
                      Container(width: 4 * u, height: 4 * u,
                          margin: EdgeInsets.only(right: 1.5 * u),
                          color: i < (l == 0 ? 4 : 2)
                              ? g : g.withOpacity(0.22)),
                  ])),
            Positioned(left: 0, right: 0, bottom: 5 * u,
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      pill(18 * u, 7 * u, fill: g.withOpacity(0.25)),
                      SizedBox(width: 4 * u),
                      pill(22 * u, 7 * u, fill: g.withOpacity(0.25)),
                      SizedBox(width: 4 * u),
                      pill(16 * u, 7 * u, fill: g.withOpacity(0.25)),
                    ])),
          ]);
          break;
        case 13: // Орбита
          items.addAll([
            Positioned(left: 0, right: 0, top: 20 * u,
                child: row(SizedBox(
                  width: 100 * u, height: 64 * u,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.18), width: 0.8),
                      ),
                    ),
                    rings(34 * u),
                    Transform.translate(offset: Offset(-44 * u, -8 * u),
                        child: dot(7 * u, fill: _Vibrant.goldMid)),
                    Transform.translate(offset: Offset(40 * u, 12 * u),
                        child: dot(7 * u, fill: _HeroAccents.amber)),
                    Transform.translate(offset: Offset(8 * u, -28 * u),
                        child: dot(7 * u, fill: _HeroAccents.sage)),
                    Transform.translate(offset: Offset(-24 * u, 26 * u),
                        child: dot(7 * u, fill: _HeroAccents.pink)),
                    Transform.translate(offset: Offset(30 * u, -24 * u),
                        child: dot(7 * u, fill: _HeroAccents.sky)),
                  ]),
                ))),
            Positioned(left: 10 * u, top: 8 * u, child: dot(2 * u)),
            Positioned(right: 16 * u, top: 12 * u, child: dot(2 * u)),
            Positioned(left: 24 * u, top: 88 * u, child: dot(2 * u)),
            Positioned(left: 0, right: 0, bottom: 6 * u,
                child: row(pill(70 * u, 10 * u))),
          ]);
          break;
        case 14: // Синтвейв
          items.addAll([
            Positioned(left: 0, right: 0, top: 8 * u,
                child: row(Container(width: 46 * u, height: 46 * u,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFD166), _Synth.pink],
                      ),
                    )))),
            Positioned(left: 0, right: 0, top: 26 * u, child: row(rings(36 * u))),
            for (int i = -2; i <= 2; i++)
              Positioned(left: w / 2 + i * 18 * u - 0.6, bottom: 22 * u,
                  child: Transform.rotate(angle: i * 0.22,
                      alignment: Alignment.bottomCenter,
                      child: Container(width: 1.2, height: 22 * u,
                          color: _Synth.pink.withOpacity(0.5)))),
            Positioned(left: 8 * u, right: 8 * u, bottom: 30 * u,
                child: line(w, color: _Synth.cyan.withOpacity(0.6), lh: 1)),
            Positioned(left: 8 * u, right: 8 * u, bottom: 14 * u,
                child: Row(children: [
                  for (int i = 0; i < 4; i++) ...[
                    if (i > 0) SizedBox(width: 4 * u),
                    Expanded(child: Container(height: 10 * u,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3 * u),
                          border: Border.all(
                              color: [_Synth.pink, _Synth.cyan,
                                _Synth.purple, _Synth.orange][i]
                                  .withOpacity(0.8), width: 1),
                        ))),
                  ],
                ])),
            Positioned(left: 0, right: 0, bottom: 4 * u,
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      dot(6 * u, fill: _Synth.cyan), SizedBox(width: 5 * u),
                      dot(6 * u, fill: _Synth.pink), SizedBox(width: 5 * u),
                      dot(6 * u, fill: _Synth.purple),
                    ])),
          ]);
          break;
        case 15: // Стол / наклон
          items.addAll([
            Positioned(left: 8 * u, top: 7 * u,
                child: Row(children: [
                  dot(7 * u), SizedBox(width: 3 * u),
                  dot(7 * u), SizedBox(width: 3 * u), dot(7 * u),
                ])),
            Positioned(right: 8 * u, top: 6 * u,
                child: Container(width: 15 * u, height: 15 * u,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35), width: 0.8)),
                    child: Align(alignment: const Alignment(0.55, 0.55),
                        child: dot(4 * u, fill: _HeroAccents.peach)))),
            Positioned(left: 0, right: 0, top: 14 * u, child: row(rings(40 * u))),
            Positioned(left: 14 * u, top: 58 * u,
                child: Transform.rotate(angle: -0.7,
                    child: Icon(Icons.arrow_downward_rounded,
                        color: Colors.white.withOpacity(0.5), size: 12 * u))),
            Positioned(right: 16 * u, top: 64 * u,
                child: dot(13 * u, fill: _Vibrant.goldMid.withOpacity(0.7))),
            Positioned(right: 38 * u, top: 76 * u,
                child: dot(13 * u, fill: _HeroAccents.amber.withOpacity(0.7))),
            Positioned(right: 60 * u, top: 80 * u,
                child: dot(13 * u, fill: _HeroAccents.pink.withOpacity(0.7))),
            Positioned(right: 82 * u, top: 74 * u,
                child: dot(13 * u, fill: _HeroAccents.sky.withOpacity(0.7))),
            Positioned(left: 10 * u, right: 10 * u, bottom: 8 * u,
                child: line(w, color: Colors.white.withOpacity(0.22), lh: 1.2)),
          ]);
          break;
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12 * u),
        child: Container(
          width: w, height: h,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_Hero.bgTop, _Hero.bgBottom],
            ),
          ),
          child: Stack(children: items),
        ),
      );
    });
  }
}