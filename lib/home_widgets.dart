// lib/home_widgets.dart
part of 'home_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════
class _Badge {
  final String emoji, label, subtitle;
  final Color color;
  const _Badge(this.emoji, this.label, this.subtitle, this.color);
}

class _PR {
  final String emoji, value, label;
  final Color color;
  const _PR(this.emoji, this.value, this.label, this.color);
}

class _DayData {
  final DateTime date;
  final int workouts;
  final double volume;
  final bool isToday, isFuture;
  _DayData({
    required this.date,
    required this.workouts,
    required this.volume,
    required this.isToday,
    required this.isFuture,
  });
}

class _ConfettiParticle {
  final double xFrac, startY, vx, vy, rot0, rotV, size;
  final Color color;
  _ConfettiParticle({
    required this.xFrac,
    required this.startY,
    required this.vx,
    required this.vy,
    required this.rot0,
    required this.rotV,
    required this.color,
    required this.size,
  });
}

// ═══════════════════════════════════════════════════════════════════
// TACTILE PRESS FEEDBACK
// ═══════════════════════════════════════════════════════════════════
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScale({required this.child, required this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DASHED LINE
// ═══════════════════════════════════════════════════════════════════
class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    for (double x = 0; x < size.width; x += dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dashWidth, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════════════════════
// CONFETTI
// ═══════════════════════════════════════════════════════════════════
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;
  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    for (final p in particles) {
      final x = p.xFrac * size.width + p.vx * t;
      final y = p.startY + p.vy * t + 500 * t * t;
      if (y > size.height + 50) continue;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot0 + p.rotV * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * .5,
          ),
          const Radius.circular(1.5),
        ),
        Paint()..color = p.color.withOpacity((1 - t * .9).clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress || old.particles != particles;
}

// ═══════════════════════════════════════════════════════════════════
// WEEKLY ACTIVITY STRIP
// ═══════════════════════════════════════════════════════════════════
class _WeekDaysRow extends StatefulWidget {
  final List<_DayData> weekData;
  final int todayIdx;
  final double scale;
  const _WeekDaysRow({
    required this.weekData,
    required this.todayIdx,
    required this.scale,
  });

  @override
  State<_WeekDaysRow> createState() => _WeekDaysRowState();
}

class _WeekDaysRowState extends State<_WeekDaysRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    const dayNames = ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'];
    return Row(
      children: List.generate(7, (i) {
        final isToday = i == widget.todayIdx;
        final isFuture = i > widget.todayIdx;
        final isPast = !isToday && !isFuture;
        final dotSize = (isToday ? 17.0 : 12.0) * s;
        final activeColor = isToday ? _Vibrant.vividPeach : _Vibrant.neonGreen;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: dotSize + 14 * s,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isToday)
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) {
                          final p = _pulseCtrl.value;
                          return Container(
                            width: dotSize + 12 * s * p,
                            height: dotSize + 12 * s * p,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: activeColor.withOpacity(.42 * (1 - p)),
                                width: 1.5,
                              ),
                            ),
                          );
                        },
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFuture
                            ? _Palette.divider.withOpacity(.55)
                            : activeColor,
                        border: Border.all(
                          color: isFuture
                              ? _Palette.textMuted.withOpacity(.18)
                              : activeColor,
                          width: 1,
                        ),
                        boxShadow: isFuture
                            ? const []
                            : [
                          BoxShadow(
                            color: activeColor.withOpacity(isToday ? .3 : .2),
                            blurRadius: isToday ? 10 : 7,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: isFuture
                          ? null
                          : Center(
                        child: Container(
                          width: dotSize * .32,
                          height: dotSize * .32,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5 * s),
              Text(
                dayNames[i],
                style: GoogleFonts.inter(
                  fontSize: 10.5 * s,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: isToday
                      ? _Vibrant.vividPeach
                      : isPast
                      ? _Palette.text
                      : _Palette.textMuted,
                  height: 1,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CUSTOM GLOSSY PROGRESS
// ═══════════════════════════════════════════════════════════════════
class _GlossyProgress extends StatelessWidget {
  final double value;
  final double height;
  final List<Color> gradient;
  final Color track;
  final double radius;

  const _GlossyProgress({
    required this.value,
    required this.gradient,
    this.height = 8,
    this.track = const Color(0x1A000000),
    this.radius = 100,
  });

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeOutCubic,
              builder: (_, progress, __) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.last.withOpacity(.28),
                          blurRadius: 7,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FractionallySizedBox(
                        heightFactor: .4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(.5),
                                Colors.white.withOpacity(0),
                              ],
                            ),
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TRAINING VOLUME — APPLE FITNESS INSPIRED
// ═══════════════════════════════════════════════════════════════════
class _VolumeCard extends StatefulWidget {
  final FitnessProvider fitness;
  const _VolumeCard({required this.fitness});

  @override
  State<_VolumeCard> createState() => _VolumeCardState();
}

class _VolumeCardState extends State<_VolumeCard> {
  int _selectedPeriod = 0;
  double _weeklyGoal = 10000;
  bool _loaded = false;

  static const _periodLabels = ['Неделя', 'Месяц', 'Год', 'Всё'];

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _weeklyGoal = prefs.getDouble('weekly_volume_goal') ?? 10000;
      _loaded = true;
    });
  }

  Future<void> _saveGoal(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weekly_volume_goal', value);
  }

  double _goalForPeriod(int period) {
    switch (period) {
      case 0:
        return _weeklyGoal;
      case 1:
        return _weeklyGoal * 4.3;
      case 2:
        return _weeklyGoal * 52;
      default:
        return 0;
    }
  }

  String _periodHeaderLabel(int period) {
    switch (period) {
      case 0:
        return 'НА ЭТОЙ НЕДЕЛЕ';
      case 1:
        return 'В ЭТОМ МЕСЯЦЕ';
      case 2:
        return 'В ЭТОМ ГОДУ';
      default:
        return 'ЗА ВСЁ ВРЕМЯ';
    }
  }

  String _goalPeriodWord(int period) {
    switch (period) {
      case 0:
        return 'недели';
      case 1:
        return 'месяца';
      case 2:
        return 'года';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));

    double weekVol = 0, monthVol = 0, yearVol = 0, allVol = 0, lastWeekVol = 0;
    int weekSets = 0, monthSets = 0, yearSets = 0, allSets = 0;
    int weekEx = 0, monthEx = 0, yearEx = 0, allEx = 0;
    int weekWk = 0, monthWk = 0, yearWk = 0, allWk = 0;
    final last4Weeks = List<double>.filled(4, 0);

    try {
      for (final log in widget.fitness.logs) {
        final date = _extractLogDate(log);
        if (date == null) continue;
        final volume = _extractLogVolume(log);
        var sets = 0;
        var exercises = 0;
        try {
          final exerciseLogs = log.exercisesLog;
          if (exerciseLogs is List) {
            exercises = exerciseLogs.length;
            for (final exercise in exerciseLogs) {
              final exerciseSets = exercise.sets;
              if (exerciseSets is List) sets += exerciseSets.length;
            }
          }
        } catch (_) {}

        allVol += volume;
        allSets += sets;
        allEx += exercises;
        allWk += 1;

        final isThisWeek = !date.isBefore(weekStart);
        final isThisMonth = !date.isBefore(monthStart);
        final isThisYear = !date.isBefore(yearStart);
        final isLastWeek = !date.isBefore(lastWeekStart) && date.isBefore(weekStart);

        if (isThisWeek) {
          weekVol += volume;
          weekSets += sets;
          weekEx += exercises;
          weekWk += 1;
        }
        if (isThisMonth) {
          monthVol += volume;
          monthSets += sets;
          monthEx += exercises;
          monthWk += 1;
        }
        if (isThisYear) {
          yearVol += volume;
          yearSets += sets;
          yearEx += exercises;
          yearWk += 1;
        }
        if (isLastWeek) lastWeekVol += volume;

        final day = DateTime(date.year, date.month, date.day);
        for (var i = 0; i < 4; i++) {
          final start = weekStart.subtract(Duration(days: (3 - i) * 7));
          final end = start.add(const Duration(days: 7));
          if (!day.isBefore(start) && day.isBefore(end)) {
            last4Weeks[i] += volume;
            break;
          }
        }
      }
    } catch (_) {}

    final values = [weekVol, monthVol, yearVol, allVol];
    final setsList = [weekSets, monthSets, yearSets, allSets];
    final exercisesList = [weekEx, monthEx, yearEx, allEx];
    final workoutsList = [weekWk, monthWk, yearWk, allWk];
    final currentVol = values[_selectedPeriod];
    final currentSets = setsList[_selectedPeriod];
    final currentExercises = exercisesList[_selectedPeriod];
    final currentWorkouts = workoutsList[_selectedPeriod];
    final hasGoal = _selectedPeriod < 3;
    final goalForPeriod = hasGoal ? _goalForPeriod(_selectedPeriod) : 0.0;
    final goalPct = hasGoal && goalForPeriod > 0
        ? (currentVol / goalForPeriod).clamp(0.0, 1.0)
        : 0.0;
    final goalReached = hasGoal && currentVol >= goalForPeriod;
    final accent = goalReached ? _Palette.green : _Palette.sage;
    final displayValue = _formatKg(currentVol);
    final tonsSubtitle = _formatTons(currentVol);
    final avgPerWorkout = currentWorkouts > 0 ? currentVol / currentWorkouts : 0.0;
    final showWeekTrend = _selectedPeriod == 0;
    final weekDiff = weekVol - lastWeekVol;
    final weekPct = lastWeekVol > 0
        ? ((weekDiff / lastWeekVol) * 100).round()
        : (weekVol > 0 ? 100 : 0);
    final maxWeek = last4Weeks.reduce(math.max);

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Container(
        padding: EdgeInsets.all(r.s(19)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.s(26)),
          border: Border.all(color: const Color(0xFFECEFF0), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF17251D).withOpacity(.045),
              blurRadius: 24,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(r, accent, hasGoal, goalForPeriod),
            SizedBox(height: r.s(17)),
            _buildPeriodPicker(r),
            SizedBox(height: r.s(20)),
            Text(
              _periodHeaderLabel(_selectedPeriod),
              style: GoogleFonts.inter(
                color: _Palette.textMuted,
                fontSize: r.fs(9.5),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.25,
              ),
            ),
            SizedBox(height: r.s(5)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          displayValue,
                          style: GoogleFonts.inter(
                            color: _Palette.text,
                            fontSize: r.fs(38),
                            fontWeight: FontWeight.w700,
                            letterSpacing: -2.1,
                            height: 1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      SizedBox(height: r.s(6)),
                      Row(
                        children: [
                          if (tonsSubtitle != null) ...[
                            Text(
                              tonsSubtitle,
                              style: GoogleFonts.inter(
                                color: _Palette.textMuted,
                                fontSize: r.fs(10.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: r.s(7)),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: _Palette.textMuted.withOpacity(.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: r.s(7)),
                          ],
                          if (avgPerWorkout > 0)
                            Flexible(
                              child: Text(
                                '${_formatKg(avgPerWorkout)} / тренировку',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: _Palette.textMuted,
                                  fontSize: r.fs(10.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showWeekTrend && lastWeekVol > 0)
                  _buildTrendBadge(r, weekDiff, weekPct),
              ],
            ),
            SizedBox(height: r.s(14)),
            Row(
              children: [
                _countChip('$currentWorkouts', 'тренировки', r),
                SizedBox(width: r.s(6)),
                _countChip('$currentExercises', 'упражнения', r),
                SizedBox(width: r.s(6)),
                _countChip('$currentSets', 'подходы', r),
              ],
            ),
            if (showWeekTrend && maxWeek > 0) ...[
              SizedBox(height: r.s(20)),
              _buildWeeklyChart(r, last4Weeks, maxWeek),
            ],
            if (hasGoal) ...[
              SizedBox(height: r.s(19)),
              _buildGoalProgress(r, accent, goalPct, goalReached, goalForPeriod),
            ],
            SizedBox(height: r.s(15)),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: r.s(12), color: _Palette.textMuted),
                SizedBox(width: r.s(5)),
                Expanded(
                  child: Text(
                    'Тоннаж = вес × повторения × подходы',
                    style: GoogleFonts.inter(
                      color: _Palette.textMuted,
                      fontSize: r.fs(9.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(_R r, Color accent, bool hasGoal, double goal) {
    return Row(
      children: [
        Container(
          width: r.s(38),
          height: r.s(38),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7F2),
            borderRadius: BorderRadius.circular(r.s(12)),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.fitness_center_rounded,
              color: _Palette.green, size: r.s(19)),
        ),
        SizedBox(width: r.s(11)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ОБЪЁМ ТРЕНИРОВОК',
                style: GoogleFonts.inter(
                  color: _Palette.text,
                  fontSize: r.fs(10),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.05,
                ),
              ),
              SizedBox(height: r.s(2)),
              Text(
                'Твой силовой прогресс',
                style: GoogleFonts.inter(
                  color: _Palette.textMuted,
                  fontSize: r.fs(10),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (hasGoal && _loaded)
          _TapScale(
            onTap: _editGoal,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.s(10),
                vertical: r.s(8),
              ),
              decoration: BoxDecoration(
                color: accent.withOpacity(.09),
                borderRadius: BorderRadius.circular(r.s(12)),
                border: Border.all(color: accent.withOpacity(.13)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_rounded, color: accent, size: r.s(13)),
                  SizedBox(width: r.s(5)),
                  Text(
                    _formatKg(goal),
                    style: GoogleFonts.inter(
                      color: accent,
                      fontSize: r.fs(10),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodPicker(_R r) {
    return Container(
      padding: EdgeInsets.all(r.s(4)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F4),
        borderRadius: BorderRadius.circular(r.s(14)),
      ),
      child: Row(
        children: List.generate(4, (i) {
          final selected = _selectedPeriod == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPeriod = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(vertical: r.s(9)),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(r.s(10)),
                  boxShadow: selected
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(.055),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _periodLabels[i],
                    style: GoogleFonts.inter(
                      color: selected ? _Palette.text : _Palette.textMuted,
                      fontSize: r.fs(10),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTrendBadge(_R r, double diff, int pct) {
    final positive = diff >= 0;
    final color = positive ? _Palette.green : _Palette.pink;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.s(10),
        vertical: r.s(8),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.085),
        borderRadius: BorderRadius.circular(r.s(13)),
      ),
      child: Column(
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
            size: r.s(16),
          ),
          SizedBox(height: r.s(2)),
          Text(
            '${positive ? '+' : '−'}${pct.abs()}%',
            style: GoogleFonts.inter(
              color: color,
              fontSize: r.fs(12),
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'к прошлой',
            style: GoogleFonts.inter(
              color: color.withOpacity(.8),
              fontSize: r.fs(8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countChip(String value, String label, _R r) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: r.s(5),
          vertical: r.s(9),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F6),
          borderRadius: BorderRadius.circular(r.s(11)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: _Palette.text,
                fontSize: r.fs(13),
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(height: r.s(2)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _Palette.textMuted,
                fontSize: r.fs(8.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(_R r, List<double> values, double maxValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ДИНАМИКА ЗА 4 НЕДЕЛИ',
              style: GoogleFonts.inter(
                color: _Palette.textMuted,
                fontSize: r.fs(9),
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
            const Spacer(),
            Container(
              width: r.s(6),
              height: r.s(6),
              decoration: const BoxDecoration(
                color: _Palette.green,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: r.s(4)),
            Text(
              'текущая',
              style: GoogleFonts.inter(
                color: _Palette.textMuted,
                fontSize: r.fs(9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: r.s(12)),
        SizedBox(
          height: r.s(96),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (i) {
              final value = values[i];
              final fraction = value > 0
                  ? (value / maxValue).clamp(.08, 1.0)
                  : .035;
              final isCurrent = i == 3;
              final isPeak = value > 0 && value == maxValue && !isCurrent;
              final barColor = isCurrent
                  ? _Palette.green
                  : isPeak
                  ? _Palette.peach
                  : _Palette.sage.withOpacity(.65);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? r.s(9) : 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        value > 0 ? _shortKg(value) : '—',
                        style: GoogleFonts.inter(
                          color: isCurrent
                              ? _Palette.green
                              : isPeak
                              ? _Palette.peach
                              : _Palette.textMuted,
                          fontSize: r.fs(9),
                          fontWeight: isCurrent || isPeak
                              ? FontWeight.w800
                              : FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      SizedBox(height: r.s(5)),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: fraction),
                            duration: Duration(milliseconds: 550 + i * 90),
                            curve: Curves.easeOutCubic,
                            builder: (_, animated, __) => FractionallySizedBox(
                              heightFactor: animated,
                              widthFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(r.s(7)),
                                  boxShadow: isCurrent
                                      ? [
                                    BoxShadow(
                                      color: _Palette.green.withOpacity(.2),
                                      blurRadius: 9,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: r.s(7)),
                      Text(
                        isCurrent ? 'сейчас' : '−${3 - i} нед.',
                        style: GoogleFonts.inter(
                          color: isCurrent
                              ? _Palette.green
                              : _Palette.textMuted,
                          fontSize: r.fs(8.5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalProgress(
      _R r,
      Color accent,
      double progress,
      bool reached,
      double goal,
      ) {
    final remaining = math.max(0.0, goal - _currentPeriodVolume()).toDouble();
    return Container(
      padding: EdgeInsets.all(r.s(13)),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(r.s(15)),
        border: Border.all(color: const Color(0xFFEDF1ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                reached ? Icons.check_circle_rounded : Icons.flag_rounded,
                color: accent,
                size: r.s(15),
              ),
              SizedBox(width: r.s(6)),
              Expanded(
                child: Text(
                  reached ? 'ЦЕЛЬ ВЫПОЛНЕНА' : 'ПРОГРЕСС К ЦЕЛИ',
                  style: GoogleFonts.inter(
                    color: _Palette.text,
                    fontSize: r.fs(9),
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.inter(
                  color: accent,
                  fontSize: r.fs(13),
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SizedBox(height: r.s(10)),
          _GlossyProgress(
            value: progress,
            height: r.s(11),
            gradient: [
              accent.withOpacity(.72),
              accent,
              const Color(0xFFB7E8C7),
            ],
            track: const Color(0xFFE4EAE5),
            radius: r.s(8),
          ),
          SizedBox(height: r.s(8)),
          Text(
            reached
                ? 'Отличная работа — цель ${_goalPeriodWord(_selectedPeriod)} достигнута'
                : 'Осталось ${_formatKg(remaining)} до цели ${_goalPeriodWord(_selectedPeriod)}',
            style: GoogleFonts.inter(
              color: _Palette.textMuted,
              fontSize: r.fs(9.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  double _currentPeriodVolume() {
    // Recalculated from the same source to keep the goal caption in sync.
    final now = DateTime.now();
    final start = _selectedPeriod == 0
        ? DateTime(now.year, now.month, now.day - now.weekday + 1)
        : _selectedPeriod == 1
        ? DateTime(now.year, now.month, 1)
        : DateTime(now.year, 1, 1);
    var total = 0.0;
    try {
      for (final log in widget.fitness.logs) {
        final date = _extractLogDate(log);
        if (date != null && !date.isBefore(start)) {
          total += _extractLogVolume(log);
        }
      }
    } catch (_) {}
    return total;
  }

  Future<void> _editGoal() async {
    final r = _R(context);
    final controller = TextEditingController(
      text: _weeklyGoal.toStringAsFixed(0),
    );
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: r.s(16),
          right: r.s(16),
          top: r.s(16),
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(r.s(21), r.s(12), r.s(21), r.s(22)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(r.s(28)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: r.s(38),
                    height: r.s(5),
                    decoration: BoxDecoration(
                      color: _Palette.divider,
                      borderRadius: BorderRadius.circular(r.s(4)),
                    ),
                  ),
                ),
                SizedBox(height: r.s(22)),
                Text(
                  'ЦЕЛЬ ТОННАЖА',
                  style: GoogleFonts.inter(
                    color: _Palette.green,
                    fontSize: r.fs(10),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: r.s(5)),
                Text(
                  'Сколько кг за неделю?',
                  style: GoogleFonts.inter(
                    color: _Palette.text,
                    fontSize: r.fs(21),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.5,
                  ),
                ),
                SizedBox(height: r.s(4)),
                Text(
                  'Цель месяца и года рассчитается автоматически',
                  style: GoogleFonts.inter(
                    color: _Palette.textMuted,
                    fontSize: r.fs(11),
                  ),
                ),
                SizedBox(height: r.s(17)),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.inter(
                    color: _Palette.text,
                    fontSize: r.fs(23),
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: '10000',
                    suffixText: 'кг',
                    filled: true,
                    fillColor: const Color(0xFFF4F6F5),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: r.s(16),
                      vertical: r.s(16),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(r.s(15)),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(r.s(15)),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(r.s(15)),
                      borderSide: BorderSide(
                        color: _Palette.green.withOpacity(.45),
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: r.s(17)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      ctx,
                      double.tryParse(
                        controller.text.trim().replaceAll(',', '.'),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: r.s(16)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(r.s(15)),
                      ),
                    ),
                    child: Text(
                      'СОХРАНИТЬ ЦЕЛЬ',
                      style: GoogleFonts.inter(
                        fontSize: r.fs(11),
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null && result > 0) {
      setState(() => _weeklyGoal = result);
      await _saveGoal(result);
    }
    controller.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════
// SETTINGS SHEET
// ═══════════════════════════════════════════════════════════════════
class _SettingsSheet extends StatelessWidget {
  final String currentBg;
  final String bgLabel;
  final String styleLabel;

  const _SettingsSheet({
    required this.currentBg,
    required this.bgLabel,
    required this.styleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    return Container(
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(22)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(r.s(29)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: r.s(38),
                height: r.s(5),
                decoration: BoxDecoration(
                  color: _Palette.divider,
                  borderRadius: BorderRadius.circular(r.s(4)),
                ),
              ),
            ),
            SizedBox(height: r.s(21)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Настройки главного экрана',
                    style: GoogleFonts.inter(
                      color: _Palette.text,
                      fontSize: r.fs(18),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.45,
                    ),
                  ),
                ),
                Container(
                  width: r.s(34),
                  height: r.s(34),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: _Palette.textMuted,
                      size: r.s(17),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: r.s(16)),
            _SettingsTile(
              icon: Icons.person_rounded,
              iconColor: _Palette.green,
              iconBg: const Color(0xFFEAF4ED),
              title: 'Профиль',
              subtitle: 'Имя, аватар и статистика',
              onTap: () => Navigator.pop(context, 'profile'),
            ),
            SizedBox(height: r.s(9)),
            _SettingsTile(
              icon: Icons.dashboard_customize_rounded,
              iconColor: _Palette.pink,
              iconBg: const Color(0xFFF9EDF2),
              title: 'Стиль шапки',
              subtitle: 'Текущий: $styleLabel · ${_heroStyleNames.length} вариантов',
              onTap: () => Navigator.pop(context, 'style'),
            ),
            SizedBox(height: r.s(9)),
            _SettingsTile(
              icon: Icons.wallpaper_rounded,
              iconColor: _Palette.peach,
              iconBg: const Color(0xFFFFF1E9),
              title: 'Фон главного экрана',
              subtitle: 'Текущий: $bgLabel',
              trailing: Container(
                width: r.s(48),
                height: r.s(48),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r.s(12)),
                  border: Border.all(color: const Color(0xFFE9ECEA)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  currentBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF0F2F1),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_rounded,
                      color: _Palette.textMuted,
                      size: r.s(20),
                    ),
                  ),
                ),
              ),
              onTap: () => Navigator.pop(context, 'background'),
            ),
            SizedBox(height: r.s(4)),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    return _TapScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(r.s(13)),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F7),
          borderRadius: BorderRadius.circular(r.s(17)),
          border: Border.all(color: const Color(0xFFEEF0EF)),
        ),
        child: Row(
          children: [
            Container(
              width: r.s(43),
              height: r.s(43),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(r.s(13)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: r.s(21)),
            ),
            SizedBox(width: r.s(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: _Palette.text,
                      fontSize: r.fs(13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: r.s(3)),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _Palette.textMuted,
                      fontSize: r.fs(10),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: r.s(8)),
              trailing!,
            ],
            SizedBox(width: r.s(4)),
            Icon(
              Icons.chevron_right_rounded,
              color: _Palette.textMuted.withOpacity(.65),
              size: r.s(20),
            ),
          ],
        ),
      ),
    );
  }
}
