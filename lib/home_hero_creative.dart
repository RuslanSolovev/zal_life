part of 'home_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  CREATIVE HERO STYLES (16–25) — ПОЛНОЦЕННЫЕ И ПРОДУМАННЫЕ
// ═══════════════════════════════════════════════════════════════════

Widget buildCreativeHeroStyle({required int style, required _XHeroCtx x}) {
  switch (style) {
    case 16: return _HeroTimeline(x: x);
    case 17: return _HeroStackedCards(x: x);
    case 18: return _HeroBentoGrid(x: x);
    case 19: return _HeroPulseWave(x: x);
    case 20: return _HeroReceipt(x: x);
    case 21: return _HeroCyberpunk(x: x);
    case 22: return _HeroGlassmorphism(x: x);
    case 23: return _HeroSwissMinimal(x: x);
    case 24: return _HeroRetroPixel(x: x);
    case 25: return _HeroLiquidMesh(x: x);
    default: return _HeroTimeline(x: x);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  16. ТАЙМЛАЙН (The Journey)
// ═══════════════════════════════════════════════════════════════════
class _HeroTimeline extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroTimeline({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;
    const days = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      child: Stack(
        children: [
          ...x.bgLayers,
          SafeArea(
            bottom: false, left: false, right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_greetingIcon()} ${_greeting()}',
                                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: r.fs(12), fontWeight: FontWeight.w600)),
                            SizedBox(height: r.s(4)),
                            Text(x.name.isEmpty ? 'Атлет' : x.name,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(24), fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                          ],
                        ),
                      ),
                      _heroIconBtn(Icons.shopping_cart_rounded, x.onCart, r, size: 38),
                      SizedBox(width: r.s(8)),
                      _heroIconBtn(Icons.tune_rounded, x.onSettings, r, size: 38),
                    ],
                  ),
                  SizedBox(height: r.s(28)),
                  SizedBox(
                    height: r.s(60),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(left: r.s(20), right: r.s(20), child: Container(height: 2, color: Colors.white.withOpacity(0.15))),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (i) {
                            final isToday = i == (d.daysPassed - 1);
                            final isPast = i < (d.daysPassed - 1);
                            final isActive = d.daysActive[i];
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isActive || isToday)
                                  Container(
                                    width: r.s(8), height: r.s(8),
                                    decoration: BoxDecoration(
                                      color: isToday ? _Vibrant.vividPeach : (isActive ? _Vibrant.neonGreen : Colors.white.withOpacity(0.3)),
                                      shape: BoxShape.circle,
                                      boxShadow: isToday ? [BoxShadow(color: _Vibrant.vividPeach.withOpacity(0.6), blurRadius: 12, spreadRadius: 2)] : [],
                                    ),
                                  )
                                else
                                  Container(width: r.s(6), height: r.s(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle)),
                                SizedBox(height: r.s(8)),
                                Text(days[i], style: GoogleFonts.inter(
                                  color: isToday ? Colors.white : Colors.white.withOpacity(0.5),
                                  fontSize: r.fs(10), fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                                )),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: r.s(24)),
                  Container(
                    padding: EdgeInsets.all(r.s(16)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(r.s(20)),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        _miniStat('🔥', '${d.streak}', 'дней', r),
                        Container(width: 1, height: r.s(32), color: Colors.white.withOpacity(0.15)),
                        _miniStat('🏋️', '${d.thisWeek}/7', 'цель', r),
                        Container(width: 1, height: r.s(32), color: Colors.white.withOpacity(0.15)),
                        _miniStat('⚡', '${(d.pWorkouts * 100).round()}%', 'тоннаж', r),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String emoji, String value, String label, _R r) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: r.fs(16))),
          SizedBox(height: r.s(4)),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(16), fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()])),
          Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: r.fs(9), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  17. СТОПКА КАРТ (The Deck)
// ═══════════════════════════════════════════════════════════════════
class _HeroStackedCards extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroStackedCards({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      child: Stack(
        children: [
          ...x.bgLayers,
          SafeArea(
            bottom: false, left: false, right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(32)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${_greetingIcon()} ${_greeting()}', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: r.fs(12), fontWeight: FontWeight.w600)),
                      const Spacer(),
                      _heroIconBtn(Icons.tune_rounded, x.onSettings, r, size: 36),
                    ],
                  ),
                  SizedBox(height: r.s(16)),
                  Text(x.name.isEmpty ? 'Твой прогресс' : x.name, style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(26), fontWeight: FontWeight.w800, letterSpacing: -1)),
                  SizedBox(height: r.s(24)),
                  SizedBox(
                    height: r.s(260),
                    child: Stack(
                      children: [
                        Positioned(
                          top: r.s(40), left: r.s(20), right: r.s(20),
                          child: Transform.rotate(
                            angle: -0.04,
                            child: _stackCard(r, _Palette.peach, '🔥', 'СЕРИЯ', '${d.streak} ДНЕЙ', 'Без пропусков'),
                          ),
                        ),
                        Positioned(
                          top: r.s(20), left: r.s(10), right: r.s(10),
                          child: Transform.rotate(
                            angle: 0.02,
                            child: _stackCard(r, _Palette.pink, '🥗', 'КАЛОРИИ', '${d.kcal} / ${d.kcalGoal}', 'ккал сегодня'),
                          ),
                        ),
                        Positioned(
                          top: 0, left: 0, right: 0,
                          child: _stackCard(r, _Palette.green, '💪', 'ТРЕНИРОВКИ', '${d.thisWeek} из 7', 'на этой неделе', isFront: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stackCard(_R r, Color color, String emoji, String title, String value, String subtitle, {bool isFront = false}) {
    return Container(
      padding: EdgeInsets.all(r.s(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.s(24)),
        border: Border.all(color: color.withOpacity(0.3), width: isFront ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isFront ? 0.15 : 0.05),
            blurRadius: isFront ? 20 : 10,
            offset: Offset(0, isFront ? 10 : 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(r.s(8)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(r.s(12)),
                ),
                child: Text(emoji, style: TextStyle(fontSize: r.s(20))),
              ),
              SizedBox(width: r.s(12)),
              Text(title, style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
          SizedBox(height: r.s(16)),
          Text(value, style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(28), fontWeight: FontWeight.w800, letterSpacing: -1)),
          SizedBox(height: r.s(4)),
          Text(subtitle, style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(12))),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  18. BENTO GRID (Модульная сетка)
// ═══════════════════════════════════════════════════════════════════
class _HeroBentoGrid extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroBentoGrid({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      child: Stack(
        children: [
          ...x.bgLayers,
          SafeArea(
            bottom: false, left: false, right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_greetingIcon()} ${_greeting()}', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: r.fs(12), fontWeight: FontWeight.w600)),
                            SizedBox(height: r.s(4)),
                            Text(x.name.isEmpty ? 'Атлет' : x.name, style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(24), fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                          ],
                        ),
                      ),
                      _heroIconBtn(Icons.tune_rounded, x.onSettings, r, size: 38),
                    ],
                  ),
                  SizedBox(height: r.s(20)),
                  SizedBox(
                    height: r.s(280),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: r.s(12),
                      crossAxisSpacing: r.s(12),
                      childAspectRatio: 1.1,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _bentoItem(r, 'Уровень', 'Lv ${d.level}', Icons.star_rounded, _Vibrant.goldMid),
                        _bentoItem(r, 'Неделя', '${d.thisWeek}/7', Icons.calendar_today_rounded, _HeroAccents.amber),
                        _bentoItem(r, 'Калории', '${d.kcal}', Icons.local_fire_department_rounded, _HeroAccents.pink),
                        _bentoItem(r, 'Серия', '${d.streak} д', Icons.bolt_rounded, _HeroAccents.sky),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bentoItem(_R r, String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(r.s(20)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: r.s(24)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: r.fs(10), fontWeight: FontWeight.w600)),
              Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(22), fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  19. PULSE WAVE (Пульс активности)
// ═══════════════════════════════════════════════════════════════════
class _HeroPulseWave extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroPulseWave({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      child: Stack(
        children: [
          ...x.bgLayers,
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _PulsePainter(progress: d.pWorkouts)))),
          SafeArea(
            bottom: false, left: false, right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_greetingIcon()} ${_greeting()}', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: r.fs(12), fontWeight: FontWeight.w600)),
                            SizedBox(height: r.s(4)),
                            Text(x.name.isEmpty ? 'Атлет' : x.name, style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(24), fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                          ],
                        ),
                      ),
                      _heroIconBtn(Icons.tune_rounded, x.onSettings, r, size: 38),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.all(r.s(20)),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(r.s(24)),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Прогресс недели', style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(16), fontWeight: FontWeight.w600)),
                            Text('${(d.pWorkouts * 100).round()}%', style: GoogleFonts.inter(color: _Vibrant.neonGreen, fontSize: r.fs(16), fontWeight: FontWeight.w800)),
                          ],
                        ),
                        SizedBox(height: r.s(12)),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(r.s(6)),
                          child: LinearProgressIndicator(
                            value: d.pWorkouts,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation(_Vibrant.neonGreen),
                            minHeight: r.s(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress;
  _PulsePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _Vibrant.neonGreen.withOpacity(0.1)..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, size.height);
    for (double i = 0; i <= size.width; i += 10) {
      final x = i / size.width;
      final y = math.sin(x * math.pi * 4 + progress * 10) * 20 + size.height * 0.6;
      path.lineTo(i, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
//  20. RECEIPT (Чек / Билет)
// ═══════════════════════════════════════════════════════════════════
class _HeroReceipt extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroReceipt({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      child: Stack(
        children: [
          ...x.bgLayers,
          SafeArea(
            bottom: false, left: false, right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_greetingIcon()} ${_greeting()}', style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.7), fontSize: r.fs(12))),
                            SizedBox(height: r.s(4)),
                            Text(x.name.isEmpty ? 'АТЛЕТ' : x.name.toUpperCase(), style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: r.fs(24), fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      _heroIconBtn(Icons.tune_rounded, x.onSettings, r, size: 38),
                    ],
                  ),
                  SizedBox(height: r.s(24)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(r.s(20)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(r.s(4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Text('ZAL LIFE FITNESS', style: GoogleFonts.jetBrainsMono(color: _Palette.text, fontSize: r.fs(14), fontWeight: FontWeight.w800))),
                        SizedBox(height: r.s(12)),
                        _dashedDivider(r),
                        SizedBox(height: r.s(12)),
                        _receiptRow(r, 'УРОВЕНЬ', 'Lv ${d.level}'),
                        _receiptRow(r, 'НЕДЕЛЯ', '${d.thisWeek}/7'),
                        _receiptRow(r, 'КАЛОРИИ', '${d.kcal}'),
                        _receiptRow(r, 'СЕРИЯ', '${d.streak} Д'),
                        SizedBox(height: r.s(12)),
                        _dashedDivider(r),
                        SizedBox(height: r.s(12)),
                        Center(
                          child: Text('СПАСИБО ЗА ТРЕНИРОВКУ!', style: GoogleFonts.jetBrainsMono(color: _Palette.textMuted, fontSize: r.fs(10))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedDivider(_R r) {
    return CustomPaint(
      size: Size(double.infinity, 1),
      painter: _DashedLinePainter(color: _Palette.divider),
    );
  }

  Widget _receiptRow(_R r, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.jetBrainsMono(color: _Palette.textMuted, fontSize: r.fs(12))),
          Text(value, style: GoogleFonts.jetBrainsMono(color: _Palette.text, fontSize: r.fs(12), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  21. CYBERPUNK HUD
// ═══════════════════════════════════════════════════════════════════
class _HeroCyberpunk extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroCyberpunk({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      child: Stack(
        children: [
          ...x.bgLayers,
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _CyberGridPainter()))),
          SafeArea(
            bottom: false, left: false, right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('SYS.ONLINE', style: GoogleFonts.jetBrainsMono(color: _Vibrant.neonGreen, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 2)),
                      const Spacer(),
                      _cyberBtn(Icons.tune_rounded, x.onSettings, r),
                    ],
                  ),
                  SizedBox(height: r.s(16)),
                  Text(x.name.isEmpty ? 'USER_01' : x.name.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: r.fs(28), fontWeight: FontWeight.w900, letterSpacing: -1)),
                  SizedBox(height: r.s(24)),
                  Row(
                    children: [
                      _cyberStatBox(r, 'WKLY', '${d.thisWeek}/7', _Vibrant.neonGreen),
                      SizedBox(width: r.s(12)),
                      _cyberStatBox(r, 'KCAL', '${d.kcal}', _Vibrant.vividPeach),
                      SizedBox(width: r.s(12)),
                      _cyberStatBox(r, 'STRK', '${d.streak}D', _Vibrant.electricBlue),
                    ],
                  ),
                  SizedBox(height: r.s(20)),
                  Container(
                    padding: EdgeInsets.all(r.s(16)),
                    decoration: BoxDecoration(
                      border: Border.all(color: _Vibrant.neonGreen.withOpacity(0.4), width: 1),
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('PROGRESS::', style: GoogleFonts.jetBrainsMono(color: _Vibrant.neonGreen, fontSize: r.fs(10))),
                            Text('${(d.pWorkouts * 100).round()}%', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: r.fs(14), fontWeight: FontWeight.w700)),
                          ],
                        ),
                        SizedBox(height: r.s(8)),
                        ClipRect(
                          child: SizedBox(
                            height: r.s(8),
                            child: Stack(
                              children: [
                                Container(color: Colors.white.withOpacity(0.1)),
                                FractionallySizedBox(
                                  widthFactor: d.pWorkouts.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _Vibrant.neonGreen,
                                      boxShadow: [BoxShadow(color: _Vibrant.neonGreen, blurRadius: 8)],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cyberStatBox(_R r, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: r.s(12)),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5), width: 1),
          color: Colors.black.withOpacity(0.3),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.jetBrainsMono(color: color.withOpacity(0.7), fontSize: r.fs(9), letterSpacing: 1)),
            SizedBox(height: r.s(4)),
            Text(value, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: r.fs(18), fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _cyberBtn(IconData icon, VoidCallback onTap, _R r) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(
        padding: EdgeInsets.all(r.s(10)),
        decoration: BoxDecoration(
          border: Border.all(color: _Vibrant.neonGreen.withOpacity(0.5), width: 1),
          color: Colors.black.withOpacity(0.4),
        ),
        child: Icon(icon, color: _Vibrant.neonGreen, size: r.s(18)),
      ),
    );
  }
}

class _CyberGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _Vibrant.neonGreen.withOpacity(0.05)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _CyberGridPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  22. GLASSMORPHISM (Стеклянный морфизм)
// ═══════════════════════════════════════════════════════════════════
class _HeroGlassmorphism extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroGlassmorphism({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      child: Stack(
        children: [
          ...x.bgLayers,
          SafeArea(
            bottom: false, left: false, right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('${_greetingIcon()} ${_greeting()}', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: r.fs(14), fontWeight: FontWeight.w500))),
                      _glassBtn(Icons.tune_rounded, x.onSettings, r),
                    ],
                  ),
                  SizedBox(height: r.s(20)),
                  _glassCard(
                    r: r,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Недельный ритм', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: r.fs(12), fontWeight: FontWeight.w500)),
                        SizedBox(height: r.s(8)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${d.thisWeek}', style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(48), fontWeight: FontWeight.w800, letterSpacing: -2)),
                            SizedBox(width: r.s(8)),
                            Padding(padding: EdgeInsets.only(bottom: r.s(8)), child: Text('/ 7', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: r.fs(20)))),
                          ],
                        ),
                        SizedBox(height: r.s(16)),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(r.s(8)),
                          child: LinearProgressIndicator(value: d.pWorkouts, backgroundColor: Colors.white.withOpacity(0.1), valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: r.s(6)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: r.s(16)),
                  Row(
                    children: [
                      Expanded(child: _glassCard(r: r, height: r.s(120), child: _glassStat('🔥', 'Серия', '${d.streak} дн', r))),
                      SizedBox(width: r.s(16)),
                      Expanded(child: _glassCard(r: r, height: r.s(120), child: _glassStat('⚡', 'Калории', '${d.kcal}', r))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required _R r, required Widget child, double? height}) {
    return Container(
      height: height,
      padding: EdgeInsets.all(r.s(20)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(r.s(24)),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: child,
    );
  }

  Widget _glassStat(String emoji, String label, String value, _R r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(emoji, style: TextStyle(fontSize: r.s(28))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: r.fs(12))),
            Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(22), fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap, _R r) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(
        padding: EdgeInsets.all(r.s(10)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(r.s(12)),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: r.s(20)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  23. SWISS MINIMAL (Швейцарский минимализм)
// ═══════════════════════════════════════════════════════════════════
class _HeroSwissMinimal extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroSwissMinimal({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      child: Stack(
        children: [
          ...x.bgLayers,
          SafeArea(
            bottom: false, left: false, right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(24), r.s(16), r.s(24), r.s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DASHBOARD', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: r.fs(10), fontWeight: FontWeight.w600, letterSpacing: 3)),
                      GestureDetector(onTap: x.onSettings, child: Icon(Icons.menu_rounded, color: Colors.white, size: r.s(24))),
                    ],
                  ),
                  SizedBox(height: r.s(40)),
                  Text(x.name.isEmpty ? 'АТЛЕТ' : x.name.toUpperCase(),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(42), fontWeight: FontWeight.w900, height: 0.9, letterSpacing: -2)),
                  SizedBox(height: r.s(8)),
                  Text('ПРОГРЕСС ЗА НЕДЕЛЮ', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: r.fs(12), fontWeight: FontWeight.w500, letterSpacing: 1)),
                  SizedBox(height: r.s(32)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${d.thisWeek}', style: GoogleFonts.inter(color: _Vibrant.vividPeach, fontSize: r.fs(96), fontWeight: FontWeight.w900, height: 0.8, letterSpacing: -4)),
                      SizedBox(width: r.s(12)),
                      Padding(
                        padding: EdgeInsets.only(bottom: r.s(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ИЗ', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: r.fs(14), fontWeight: FontWeight.w600)),
                            Text('7', style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(32), fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.s(32)),
                  Container(height: 2, color: Colors.white.withOpacity(0.2)),
                  SizedBox(height: r.s(24)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _minStat('КАЛ', '${d.kcal}', r),
                      _minStat('СЕРИЯ', '${d.streak} Д', r),
                      _minStat('УРОВЕНЬ', '${d.level}', r),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _minStat(String label, String value, _R r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: r.fs(10), fontWeight: FontWeight.w600, letterSpacing: 1)),
        SizedBox(height: r.s(6)),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(24), fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  24. RETRO PIXEL (8-бит ретро)
// ═══════════════════════════════════════════════════════════════════
class _HeroRetroPixel extends StatelessWidget {
  final _XHeroCtx x;
  const _HeroRetroPixel({required this.x});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = x.d;
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(0), bottomRight: Radius.circular(0)),
      child: Stack(
        children: [
          Container(color: const Color(0xFF2D2D2D)),
          SafeArea(
            bottom: false, left: false, right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(16), r.s(20), r.s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(padding: EdgeInsets.all(r.s(6)), color: _Vibrant.neonGreen, child: Text('HP', style: GoogleFonts.jetBrainsMono(color: Colors.black, fontSize: r.fs(10), fontWeight: FontWeight.w900))),
                      SizedBox(width: r.s(8)),
                      Expanded(
                        child: Container(
                          height: r.s(16),
                          color: Colors.black,
                          child: Row(
                            children: List.generate(10, (i) => Expanded(
                              child: Container(
                                margin: EdgeInsets.all(2),
                                color: i < (d.pWorkouts * 10) ? _Vibrant.neonGreen : const Color(0xFF4A4A4A),
                              ),
                            )),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.s(24)),
                  Text(x.name.isEmpty ? 'PLAYER 1' : x.name.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(color: _Vibrant.neonGreen, fontSize: r.fs(24), fontWeight: FontWeight.w900)),
                  SizedBox(height: r.s(4)),
                  Text('READY FOR ACTION?', style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.6), fontSize: r.fs(12))),
                  SizedBox(height: r.s(32)),
                  _pixelBox(r, 'SCORE', '${d.kcal} PTS', _Vibrant.vividPeach),
                  SizedBox(height: r.s(12)),
                  _pixelBox(r, 'STREAK', '${d.streak} DAYS', _Vibrant.electricBlue),
                  SizedBox(height: r.s(24)),
                  GestureDetector(
                    onTap: x.onSettings,
                    child: Container(
                      padding: EdgeInsets.all(r.s(12)),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings, color: Colors.black, size: r.s(20)),
                          SizedBox(width: r.s(8)),
                          Text('OPTIONS', style: GoogleFonts.jetBrainsMono(color: Colors.black, fontSize: r.fs(14), fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pixelBox(_R r, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(r.s(12)),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.jetBrainsMono(color: color, fontSize: r.fs(12), fontWeight: FontWeight.w700)),
          Text(value, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: r.fs(16), fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  25. LIQUID MESH (Жидкий градиент)
// ═══════════════════════════════════════════════════════════════════
class _HeroLiquidMesh extends StatefulWidget {
  final _XHeroCtx x;
  const _HeroLiquidMesh({required this.x});

  @override
  State<_HeroLiquidMesh> createState() => _HeroLiquidMeshState();
}

class _HeroLiquidMeshState extends State<_HeroLiquidMesh> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final d = widget.x.d;

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: _LiquidPainter(progress: _controller.value),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            bottom: false, left: false, right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(24), r.s(16), r.s(24), r.s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_greetingIcon()} ${_greeting()}', style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(16), fontWeight: FontWeight.w600)),
                      GestureDetector(
                          onTap: widget.x.onSettings,
                          child: Container(
                              padding: EdgeInsets.all(r.s(8)),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: Icon(Icons.tune_rounded, color: Colors.white, size: r.s(20))
                          )
                      ),
                    ],
                  ),
                  SizedBox(height: r.s(32)),
                  Container(
                    padding: EdgeInsets.all(r.s(24)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(r.s(32)),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Прогресс', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: r.fs(14), fontWeight: FontWeight.w500)),
                            Text('${(d.pWorkouts * 100).round()}%', style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(14), fontWeight: FontWeight.w700)),
                          ],
                        ),
                        SizedBox(height: r.s(16)),
                        Stack(
                          children: [
                            Container(height: r.s(12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(r.s(6)))),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(r.s(6)),
                              child: SizedBox(
                                height: r.s(12),
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: FractionallySizedBox(
                                  widthFactor: d.pWorkouts.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE0E0E0)]),
                                      borderRadius: BorderRadius.circular(r.s(6)),
                                      boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 8)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: r.s(24)),
                  Row(
                    children: [
                      _liquidPill(r, '🔥 ${d.streak}', 'Серия'),
                      SizedBox(width: r.s(12)),
                      _liquidPill(r, '⚡ ${d.kcal}', 'Ккал'),
                      const Spacer(),
                      _liquidPill(r, 'Lv.${d.level}', 'Уровень'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liquidPill(_R r, String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(10)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(r.s(100)),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(16), fontWeight: FontWeight.w700)),
          Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: r.fs(10))),
        ],
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double progress;
  _LiquidPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final gradient1 = RadialGradient(
      center: Alignment(progress * 2 - 0.5, progress * 2 - 0.5),
      radius: 1.5,
      colors: [const Color(0xFF6C5CE7).withOpacity(0.8), Colors.transparent],
    );

    final gradient2 = RadialGradient(
      center: Alignment(1.5 - progress * 2, 1.5 - progress * 2),
      radius: 1.5,
      colors: [const Color(0xFF00CEC9).withOpacity(0.8), Colors.transparent],
    );

    final paint1 = Paint()..shader = gradient1.createShader(rect);
    final paint2 = Paint()..shader = gradient2.createShader(rect);

    canvas.drawRect(rect, paint1);
    canvas.drawRect(rect, paint2);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) => old.progress != progress;
}