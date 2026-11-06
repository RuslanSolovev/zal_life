// lib/home_screen.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show MaskFilter, BlurStyle;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zal_life/features/fitness/database/ui/screens/active_program_screen.dart';
import 'package:zal_life/features/fitness/database/ui/screens/exercise_library_screen.dart';
import 'package:zal_life/features/fitness/database/ui/screens/fitness_dashboard.dart';
import 'package:zal_life/features/fitness/database/ui/screens/fitness_target_details_screen.dart';
import 'package:zal_life/features/fitness/database/ui/screens/fitness_targets_screen.dart';
import 'package:zal_life/features/fitness/database/ui/screens/pedometer_screen.dart';
import 'package:zal_life/features/fitness/database/ui/screens/progress_screen.dart';
import 'package:zal_life/features/fitness/database/ui/screens/wellbeing_screen.dart';
import 'package:zal_life/features/fitness/database/ui/screens/workout_execution_screen.dart';
import 'package:zal_life/features/fitness/database/ui/screens/workout_log_screen.dart';
import 'package:zal_life/features/fitness/providers/pedometer_provider.dart';

import 'features/fitness/models/enums.dart';
import 'features/fitness/models/fitness_models.dart';
import 'features/fitness/providers/fitness_provider.dart';

import 'features/nutrition/providers/nutrition_provider.dart';
import 'features/nutrition/ui/screens/fuel_dashboard_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════════
DateTime? _extractLogDate(dynamic log) {
  try { final d = log.date; if (d is DateTime) return d; } catch (_) {}
  try { final d = log.startedAt; if (d is DateTime) return d; } catch (_) {}
  try { final d = log.createdAt; if (d is DateTime) return d; } catch (_) {}
  try { final d = log.performedAt; if (d is DateTime) return d; } catch (_) {}
  try {
    final d = log.timestamp;
    if (d is DateTime) return d;
    if (d is int) return DateTime.fromMillisecondsSinceEpoch(d);
  } catch (_) {}
  return null;
}

double _extractLogVolume(dynamic log) {
  try { final v = log.totalVolume; if (v is num) return v.toDouble(); } catch (_) {}
  try { final v = log.volume; if (v is num) return v.toDouble(); } catch (_) {}
  try {
    double total = 0;
    final exercises = log.exercises;
    if (exercises is List) {
      for (final ex in exercises) {
        final sets = ex.sets;
        if (sets is List) {
          for (final s in sets) {
            final w = s.weight;
            final r = s.reps;
            if (w is num && r is num) total += w.toDouble() * r.toDouble();
          }
        }
      }
    }
    return total;
  } catch (_) { return 0; }
}

String _formatVolume(double volume) {
  if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(1)}k';
  return volume.toStringAsFixed(0);
}

String _fmtNum(int n) {
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
  if (n >= 1000) {
    final s = n.toString();
    return '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}';
  }
  return '$n';
}

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════════
class _Palette {
  static const bg         = Color(0xFFF6F5F1);
  static const surface    = Color(0xFFFFFFFF);
  static const text       = Color(0xFF263D36);
  static const textMuted  = Color(0xFF7C8982);

  static const green      = Color(0xFF426C59);
  static const greenSoft  = Color(0xFFE7EFE5);
  static const sage       = Color(0xFF8CAB93);

  static const peach      = Color(0xFFC79475);
  static const peachSoft  = Color(0xFFF5E6DC);

  static const pink       = Color(0xFFBB8F9D);
  static const pinkSoft   = Color(0xFFF2E4E7);

  static const yellow     = Color(0xFFE7D9B8);

  static const divider    = Color(0xFFE5E8E1);
}

// ═══════════════════════════════════════════════════════════════════
//  RESPONSIVE HELPERS
// ═══════════════════════════════════════════════════════════════════
class _R {
  final double scale;
  _R(BuildContext context)
      : scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);

  double s(double v) => v * scale;
  double fs(double v) => v * scale;
  EdgeInsets padH(double base) => EdgeInsets.symmetric(horizontal: s(base));
}

// ═══════════════════════════════════════════════════════════════════
//  UNIVERSAL IMAGE WIDGET
// ═══════════════════════════════════════════════════════════════════
class _AppImg extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  final Widget? fallback;
  const _AppImg({this.path, this.fit = BoxFit.cover, this.fallback});

  @override
  Widget build(BuildContext context) {
    final p = path;
    final fb = fallback ?? const SizedBox.shrink();
    if (p == null || p.isEmpty) return fb;
    if (p.startsWith('assets/')) {
      return Image.asset(p, fit: fit, errorBuilder: (_, __, ___) => fb);
    }
    if (p.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: p,
        fit: fit,
        placeholder: (_, __) => fb,
        errorWidget: (_, __, ___) => fb,
      );
    }
    return Image.file(File(p), fit: fit,
        errorBuilder: (_, __, ___) => fb);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _drift;
  late final AnimationController _entrance;
  late final AnimationController _confetti;
  late final ScrollController _scroll;

  late List<_ConfettiParticle> _confettiParticles;
  bool? _wasCompleted;

  String _avatarEmoji = '💪';
  String _profileName = '';

  static const int kWeekGoal = 7;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    _drift = AnimationController(
        vsync: this, duration: const Duration(seconds: 28))
      ..repeat(reverse: true);
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
    _confetti = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));

    _confettiParticles = _generateConfetti();
    _scroll = ScrollController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _avatarEmoji = prefs.getString('avatar_emoji') ?? '💪';
      _profileName = prefs.getString('profile_name') ?? 'Анна';
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _drift.dispose();
    _entrance.dispose();
    _confetti.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<_ConfettiParticle> _generateConfetti() {
    final rng = math.Random(42);
    const colors = [
      _Palette.green, _Palette.peach, _Palette.sage,
      _Palette.pink, _Palette.yellow
    ];
    return List.generate(70, (i) {
      return _ConfettiParticle(
        xFrac: rng.nextDouble(),
        startY: -20 - rng.nextDouble() * 80,
        vx: (rng.nextDouble() - 0.5) * 300,
        vy: 500 + rng.nextDouble() * 400,
        rot0: rng.nextDouble() * math.pi * 2,
        rotV: (rng.nextDouble() - 0.5) * math.pi * 6,
        color: colors[rng.nextInt(colors.length)],
        size: 4 + rng.nextDouble() * 8,
      );
    });
  }

  int _calcWorkoutsThisWeek(FitnessProvider fitness, DateTime today) {
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    int count = 0;
    try {
      for (final log in fitness.logs) {
        final d = _extractLogDate(log);
        if (d == null) continue;
        final justDate = DateTime(d.year, d.month, d.day);
        if (!justDate.isBefore(monday)) count++;
      }
    } catch (_) {}
    return count;
  }

  int _getThisWeek(FitnessProvider fitness, DateTime today) {
    final stats = fitness.getStats();
    final provider = ((stats['workoutsThisWeek'] ?? 0) as num).toInt();
    if (provider > 0) return provider;
    return _calcWorkoutsThisWeek(fitness, today);
  }

  @override
  Widget build(BuildContext context) {
    final fitness   = context.watch<FitnessProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final pedometer = context.watch<PedometerProvider>();

    final now = DateTime.now();
    final thisWeek0 = _getThisWeek(fitness, now);
    final completed = thisWeek0 >= kWeekGoal;

    if (_wasCompleted == null) {
      _wasCompleted = completed;
    } else if (completed && _wasCompleted == false) {
      _wasCompleted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confetti.forward(from: 0);
      });
    } else if (!completed) {
      _wasCompleted = false;
    }

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: _Palette.green,
              backgroundColor: Colors.white,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 400));
                HapticFeedback.lightImpact();
              },
              child: CustomScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                      child: _entranceAt(0.00, _hero(fitness, nutrition))),
                  SliverToBoxAdapter(
                      child: _entranceAt(0.20, _focusCard(fitness))),
                  SliverToBoxAdapter(
                      child: _entranceAt(0.30, _bentoTop(fitness))),
                  SliverToBoxAdapter(
                      child: _entranceAt(0.40, _bentoMid(nutrition))),
                  SliverToBoxAdapter(
                      child: _entranceAt(0.50, _stepsCard(pedometer))),
                  SliverToBoxAdapter(
                      child: _entranceAt(0.55, _achievements(fitness))),
                  SliverToBoxAdapter(
                      child: _entranceAt(0.60, _VolumeCard(fitness: fitness))),
                  SliverToBoxAdapter(
                      child: _entranceAt(0.65, _prStrip(fitness))),
                  SliverToBoxAdapter(
                      child: _entranceAt(0.70, _rhythm(fitness))),
                  SliverToBoxAdapter(
                      child: _entranceAt(0.80, _quickDock(fitness))),
                  SliverToBoxAdapter(
                      child: _entranceAt(0.85, _targetsSection(fitness))),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
          ),
          Positioned.fill(child: IgnorePointer(child: _confettiLayer())),
        ],
      ),
    );
  }

  Widget _confettiLayer() {
    return AnimatedBuilder(
      animation: _confetti,
      builder: (_, __) {
        if (_confetti.value == 0 || _confetti.value == 1) {
          return const SizedBox.shrink();
        }
        return CustomPaint(
            painter: _ConfettiPainter(
                progress: _confetti.value, particles: _confettiParticles),
            size: Size.infinite);
      },
    );
  }

  Widget _entranceAt(double delay, Widget child) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (_, __) {
        final span = (1.0 - delay).clamp(0.01, 1.0);
        final t = ((_entrance.value - delay) / span).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased.clamp(0.0, 1.0),
          child: Transform.translate(
              offset: Offset(0, 24 * (1 - eased)), child: child),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HERO — объединённая карточка (topBar + rings)
  // ═════════════════════════════════════════════════════════
  Widget _hero(FitnessProvider fitness, NutritionProvider nutrition) {
    final r = _R(context);
    final stats = fitness.getStats();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final level = _levelFromStats(stats);
    final today = DateTime.now();
    final thisWeek = _getThisWeek(fitness, today);

    final summary = nutrition.getSummaryForDate(today);
    final goals = nutrition.getGoalsForDate(today);

    final pWorkouts = (thisWeek / kWeekGoal).clamp(0.0, 1.0);
    final pStreak = (streak / 30).clamp(0.0, 1.0);
    final pCalories = goals.calories > 0
        ? (summary.calories / goals.calories).clamp(0.0, 1.0)
        : 0.0;

    final weekData = _buildWeekData(fitness, today, today.weekday - 1);
    final daysActive = List<bool>.generate(
        7, (i) => i < weekData.length && weekData[i].workouts > 0);
    final todayIdx = today.weekday - 1;
    final daysPassed = todayIdx + 1;

    final hh = today.hour.toString().padLeft(2, '0');
    final mm = today.minute.toString().padLeft(2, '0');
    final ringSize = r.s(300);

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(16), r.s(20), r.s(20)),
      child: Container(
        padding: EdgeInsets.all(r.s(20)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, _Palette.greenSoft, _Palette.peachSoft],
          ),
          borderRadius: BorderRadius.circular(r.s(28)),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: _Palette.green.withOpacity(0.06),
              blurRadius: 22,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── TOP: avatar + name + level + insights ──
            Row(
              children: [
                _TapScale(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _showEditProfileDialog(fitness);
                  },
                  child: Container(
                    width: r.s(46),
                    height: r.s(46),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: _Palette.peachSoft),
                    alignment: Alignment.center,
                    child: Text(_avatarEmoji,
                        style: TextStyle(fontSize: r.fs(22))),
                  ),
                ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${_greetingIcon()} ${_greeting().toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted,
                              fontSize: r.fs(10),
                              letterSpacing: 0.5)),
                      Text(_profileName.isNotEmpty ? _profileName : 'Атлет',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: _Palette.text,
                              fontSize: r.fs(22),
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.8)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: r.s(10), vertical: r.s(7)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(r.s(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          color: _Palette.green, size: r.s(14)),
                      SizedBox(width: r.s(4)),
                      Text('$level',
                          style: GoogleFonts.inter(
                              color: _Palette.green,
                              fontSize: r.fs(12),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                SizedBox(width: r.s(8)),
                _TapScale(
                  onTap: () => _openProgress(context),
                  child: Container(
                    width: r.s(40),
                    height: r.s(40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.insights_rounded,
                        color: _Palette.text, size: r.s(18)),
                  ),
                ),
              ],
            ),
            SizedBox(height: r.s(14)),
            // ── STREAK + TIME ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: r.s(10), vertical: r.s(7)),
                  decoration: BoxDecoration(
                      color: _Palette.peachSoft,
                      borderRadius: BorderRadius.circular(100)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔥', style: TextStyle(fontSize: r.fs(14))),
                      SizedBox(width: r.s(6)),
                      Text('$streak дней подряд',
                          style: GoogleFonts.inter(
                              color: _Palette.text,
                              fontSize: r.fs(11),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                            color: _Palette.sage, shape: BoxShape.circle)),
                    SizedBox(width: r.s(4)),
                    Text('$hh:$mm',
                        style: GoogleFonts.inter(
                            color: _Palette.textMuted, fontSize: r.fs(10))),
                  ],
                ),
              ],
            ),
            SizedBox(height: r.s(20)),
            // ── BIG RINGS ──
            Container(
              padding: EdgeInsets.all(r.s(8)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0),
                  ],
                  stops: const [0.75, 1.0],
                ),
              ),
              child: SizedBox(
                width: ringSize,
                height: ringSize,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (_, anim, __) => CustomPaint(
                    size: Size(ringSize, ringSize),
                    painter: _HeroRingsPainter(
                      anim: anim,
                      daysActive: daysActive,
                      daysPassed: daysPassed,
                      caloriesProgress: pCalories,
                      workoutsProgress: pWorkouts,
                      streakProgress: pStreak,
                      time: today,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: r.s(20)),
            // ── LEGEND ──
            Wrap(
              alignment: WrapAlignment.center,
              spacing: r.s(12),
              runSpacing: r.s(8),
              children: [
                _legendItem(_Palette.green, 'Время', '$hh:$mm'),
                _legendItem(_Palette.sage, 'Неделя', '$thisWeek/7'),
                _legendItem(
                    _Palette.peach, 'Ккал', '${summary.calories.round()}'),
                _legendItem(_Palette.pink, 'Трен.', '$thisWeek/7'),
                _legendItem(_Palette.yellow, 'Серия', '$streak д'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String title, String value) {
    final r = _R(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: r.s(4)),
        Text('$title · ',
            style: GoogleFonts.inter(
                color: _Palette.textMuted, fontSize: r.fs(9))),
        Text(value,
            style: GoogleFonts.inter(
                color: _Palette.text,
                fontSize: r.fs(10),
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  FOCUS CARD — с обложкой активной программы
  // ═════════════════════════════════════════════════════════
  Widget _focusCard(FitnessProvider fitness) {
    final r = _R(context);
    final session = fitness.activeSession;
    final wellbeing = fitness.getTodayWellbeing();

    WorkoutProgram? activeProgram;
    if (session != null) {
      try {
        activeProgram =
            fitness.programs.firstWhere((p) => p.id == session.programId);
      } catch (_) {}
    }
    final coverUrl = activeProgram?.backgroundImage;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;

    String title = 'Сила в мягком темпе';
    String subtitle = 'Ещё одна тренировка — и цель недели ближе.';
    String tag = 'ФОКУС ДНЯ';
    IconData icon = Icons.play_circle_fill_rounded;
    VoidCallback onTap = () => _quickStartWorkout(context, fitness);

    if (session != null) {
      title = activeProgram?.name ?? 'Продолжить тренировку';
      subtitle =
      'День ${session.currentDayIndex + 1} · ${(session.progressPercent * 100).round()}%';
      tag = 'АКТИВНАЯ ПРОГРАММА';
      icon = Icons.play_arrow_rounded;
      onTap = () {
        HapticFeedback.lightImpact();
        if (activeProgram != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: fitness,
                child: ActiveProgramScreen(
                    program: activeProgram!, isDark: false),
              ),
            ),
          );
        }
      };
    } else if (wellbeing == null) {
      title = 'Как самочувствие?';
      subtitle = 'Отметь состояние — влияет на готовность';
      tag = 'СЕГОДНЯ';
      icon = Icons.mood_rounded;
      onTap = () => _openWellbeing(context);
    }

    if (hasCover) {
      return Padding(
        padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
        child: _TapScale(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r.s(28)),
              boxShadow: [
                BoxShadow(
                  color: _Palette.green.withOpacity(0.10),
                  blurRadius: 24,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                SizedBox(
                  height: r.s(220),
                  width: double.infinity,
                  child: _AppImg(
                    path: coverUrl,
                    fit: BoxFit.cover,
                    fallback: Container(color: _Palette.greenSoft),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.82),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(r.s(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: r.s(9), vertical: r.s(5)),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.94),
                              borderRadius: BorderRadius.circular(r.s(8)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon,
                                    color: _Palette.green, size: r.s(12)),
                                SizedBox(width: r.s(4)),
                                Text(tag,
                                    style: GoogleFonts.inter(
                                        color: _Palette.green,
                                        fontSize: r.fs(9),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r.s(90)),
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: r.fs(22),
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.6,
                              height: 1.15)),
                      SizedBox(height: r.s(4)),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: r.fs(12))),
                      SizedBox(height: r.s(14)),
                      SizedBox(
                        width: double.infinity,
                        height: r.s(46),
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _Palette.text,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(r.s(24))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon,
                                  size: r.s(18), color: _Palette.text),
                              SizedBox(width: r.s(8)),
                              Text(
                                  session != null
                                      ? 'Продолжить'
                                      : 'Начать',
                                  style: GoogleFonts.inter(
                                      fontSize: r.fs(13),
                                      fontWeight: FontWeight.w600,
                                      color: _Palette.text)),
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
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: _TapScale(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(r.s(20)),
          decoration: BoxDecoration(
            color: _Palette.greenSoft,
            borderRadius: BorderRadius.circular(r.s(28)),
            border: Border.all(
                color: Colors.white.withOpacity(0.9), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: _Palette.green, size: r.s(16)),
                      SizedBox(width: r.s(6)),
                      Text(tag,
                          style: GoogleFonts.inter(
                              color: _Palette.green,
                              fontSize: r.fs(10),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                    ],
                  ),
                  Text('25 мин · Дома',
                      style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(11))),
                ],
              ),
              SizedBox(height: r.s(16)),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: _Palette.text,
                      fontSize: r.fs(22),
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.8)),
              SizedBox(height: r.s(6)),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: _Palette.textMuted,
                      fontSize: r.fs(12),
                      height: 1.4)),
              SizedBox(height: r.s(20)),
              SizedBox(
                width: double.infinity,
                height: r.s(48),
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(r.s(24))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: r.s(18)),
                      SizedBox(width: r.s(8)),
                      Text(
                          session != null
                              ? 'Продолжить'
                              : 'Начать тренировку',
                          style: GoogleFonts.inter(
                              fontSize: r.fs(13),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  BENTO ROW 1 (Fitness + Streak)
  // ═════════════════════════════════════════════════════════
  Widget _bentoTop(FitnessProvider fitness) {
    final r = _R(context);
    final stats = fitness.getStats();
    final thisWeek = _getThisWeek(fitness, DateTime.now());
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final today = DateTime.now();

    final weekData = _buildWeekData(fitness, today, today.weekday - 1);
    final todayIdx = today.weekday - 1;
    final passedDays = todayIdx + 1;
    final weekProgress = (passedDays / 7).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: SizedBox(
        height: r.s(240),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: _TapScale(
                onTap: () => _openFitness(context),
                child: Container(
                  padding: EdgeInsets.all(r.s(16)),
                  decoration: BoxDecoration(
                    color: _Palette.greenSoft,
                    borderRadius: BorderRadius.circular(r.s(28)),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.9), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Фитнес',
                              style: GoogleFonts.inter(
                                  color: _Palette.text,
                                  fontSize: r.fs(13),
                                  fontWeight: FontWeight.w500)),
                          Icon(Icons.arrow_outward_rounded,
                              color: _Palette.textMuted, size: r.s(16)),
                        ],
                      ),
                      SizedBox(height: r.s(10)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('$thisWeek',
                              style: GoogleFonts.inter(
                                  color: _Palette.text,
                                  fontSize: r.fs(32),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -1.3)),
                          SizedBox(width: r.s(4)),
                          Text('/ 7',
                              style: GoogleFonts.inter(
                                  color: _Palette.textMuted,
                                  fontSize: r.fs(15),
                                  letterSpacing: -1)),
                        ],
                      ),
                      Text('тренировок на этой неделе',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted,
                              fontSize: r.fs(11))),
                      SizedBox(height: r.s(14)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(r.s(6)),
                        child: Stack(
                          children: [
                            Container(
                                height: r.s(8),
                                color: Colors.white.withOpacity(0.6)),
                            FractionallySizedBox(
                              widthFactor: weekProgress,
                              child: Container(
                                height: r.s(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      _Palette.sage,
                                      _Palette.green
                                    ],
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(r.s(6)),
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(7, (i) {
                                return Expanded(
                                  child: Container(
                                    height: r.s(8),
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 1,
                                      height: r.s(8),
                                      color: i == 6
                                          ? Colors.transparent
                                          : Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: r.s(8)),
                      Row(
                        children: List.generate(7, (i) {
                          final isToday = i == todayIdx;
                          final isFuture = i > todayIdx;
                          final hasWorkout = i < weekData.length &&
                              weekData[i].workouts > 0;
                          return Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: r.s(6),
                                  height: r.s(6),
                                  decoration: BoxDecoration(
                                    color: hasWorkout
                                        ? _Palette.green
                                        : isToday
                                        ? _Palette.peach
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: hasWorkout
                                          ? _Palette.green
                                          : isToday
                                          ? _Palette.peach
                                          : _Palette.divider,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                SizedBox(height: r.s(4)),
                                Text(
                                  ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'][i],
                                  style: GoogleFonts.inter(
                                    color: isToday
                                        ? _Palette.green
                                        : isFuture
                                        ? _Palette.textMuted
                                        : _Palette.text,
                                    fontSize: r.fs(9),
                                    fontWeight: isToday
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: r.s(12)),
            Expanded(
              flex: 4,
              child: _TapScale(
                onTap: () => _openProgress(context),
                child: Container(
                  padding: EdgeInsets.all(r.s(16)),
                  decoration: BoxDecoration(
                    color: _Palette.peachSoft,
                    borderRadius: BorderRadius.circular(r.s(28)),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.9), width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Серия',
                              style: GoogleFonts.inter(
                                  color: _Palette.text,
                                  fontSize: r.fs(13),
                                  fontWeight: FontWeight.w500)),
                          Icon(Icons.arrow_outward_rounded,
                              color: _Palette.textMuted, size: r.s(16)),
                        ],
                      ),
                      SizedBox(height: r.s(8)),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: CircularProgressIndicator(
                                value: (streak / 14).clamp(0.0, 1.0),
                                strokeWidth: r.s(6),
                                backgroundColor:
                                Colors.white.withOpacity(0.5),
                                valueColor: const AlwaysStoppedAnimation(
                                    _Palette.peach),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$streak',
                                    style: GoogleFonts.inter(
                                        color: _Palette.text,
                                        fontSize: r.fs(36),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -1.5)),
                                Text('дней',
                                    style: GoogleFonts.inter(
                                        color: _Palette.textMuted,
                                        fontSize: r.fs(11))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: r.s(6)),
                      Text('До рекорда — 2 дня',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted,
                              fontSize: r.fs(10))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  BENTO ROW 2 (Nutrition + Water)
  // ═════════════════════════════════════════════════════════
  Widget _bentoMid(NutritionProvider nutrition) {
    final r = _R(context);
    final today = DateTime.now();
    final summary = nutrition.getSummaryForDate(today);
    final goals = nutrition.getGoalsForDate(today);
    final kcalPct = goals.calories > 0
        ? (summary.calories / goals.calories).clamp(0.0, 1.0)
        : 0.0;
    final waterPct = goals.waterMl > 0
        ? (summary.waterMl / goals.waterMl).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: SizedBox(
        height: r.s(206),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: _TapScale(
                onTap: () => _openNutrition(context),
                child: Container(
                  padding: EdgeInsets.all(r.s(16)),
                  decoration: BoxDecoration(
                    color: _Palette.pinkSoft,
                    borderRadius: BorderRadius.circular(r.s(28)),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.9), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Питание',
                              style: GoogleFonts.inter(
                                  color: _Palette.text,
                                  fontSize: r.fs(13),
                                  fontWeight: FontWeight.w500)),
                          Icon(Icons.arrow_outward_rounded,
                              color: _Palette.textMuted, size: r.s(16)),
                        ],
                      ),
                      SizedBox(height: r.s(14)),
                      Text('${summary.calories.round()}',
                          style: GoogleFonts.inter(
                              color: _Palette.text,
                              fontSize: r.fs(28),
                              fontWeight: FontWeight.w400,
                              letterSpacing: -1.3)),
                      Text('из ${goals.calories.round()} ккал',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted,
                              fontSize: r.fs(11))),
                      SizedBox(height: r.s(14)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: kcalPct,
                          minHeight: r.s(4),
                          backgroundColor: _Palette.divider,
                          valueColor: const AlwaysStoppedAnimation(
                              _Palette.pink),
                        ),
                      ),
                      SizedBox(height: r.s(10)),
                      Text(
                          'Осталось ${(goals.calories - summary.calories).round().clamp(0, 9999)} ккал',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted,
                              fontSize: r.fs(10))),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: r.s(12)),
            Expanded(
              flex: 4,
              child: _TapScale(
                onTap: () => _openNutrition(context),
                child: Container(
                  padding: EdgeInsets.all(r.s(16)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(r.s(28)),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.9), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Вода',
                              style: GoogleFonts.inter(
                                  color: _Palette.text,
                                  fontSize: r.fs(13),
                                  fontWeight: FontWeight.w500)),
                          Icon(Icons.arrow_outward_rounded,
                              color: _Palette.textMuted, size: r.s(16)),
                        ],
                      ),
                      SizedBox(height: r.s(14)),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text:
                              '${(summary.waterMl / 1000).toStringAsFixed(1)} ',
                              style: GoogleFonts.inter(
                                  color: _Palette.text,
                                  fontSize: r.fs(28),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -1.3)),
                          TextSpan(
                              text:
                              '/ ${(goals.waterMl / 1000).toStringAsFixed(0)} л',
                              style: GoogleFonts.inter(
                                  color: _Palette.textMuted,
                                  fontSize: r.fs(14),
                                  letterSpacing: -1)),
                        ]),
                      ),
                      Text('Хороший темп',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted,
                              fontSize: r.fs(11))),
                      SizedBox(height: r.s(14)),
                      Wrap(
                        spacing: r.s(4),
                        runSpacing: r.s(4),
                        children: List.generate(8, (i) {
                          final filled = (i / 8) < waterPct;
                          return Icon(Icons.water_drop_rounded,
                              size: r.s(14),
                              color: filled
                                  ? _Palette.green
                                  : _Palette.divider);
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  STEPS CARD
  // ═════════════════════════════════════════════════════════
  Widget _stepsCard(PedometerProvider pedo) {
    final r = _R(context);
    final pct = pedo.progress;
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: _TapScale(
        onTap: () => _openPedometer(context),
        child: Container(
          padding: EdgeInsets.all(r.s(20)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(r.s(28)),
            border: Border.all(
                color: Colors.white.withOpacity(0.9), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_walk_rounded,
                            color: _Palette.green, size: r.s(16)),
                        SizedBox(width: r.s(6)),
                        Text('Шаги',
                            style: GoogleFonts.inter(
                                color: _Palette.text,
                                fontSize: r.fs(13))),
                      ],
                    ),
                    SizedBox(height: r.s(10)),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: '${_fmtNum(pedo.steps)} ',
                            style: GoogleFonts.inter(
                                color: _Palette.text,
                                fontSize: r.fs(30),
                                fontWeight: FontWeight.w400,
                                letterSpacing: -1)),
                        TextSpan(
                            text: '/ ${_fmtNum(pedo.goal)}',
                            style: GoogleFonts.inter(
                                color: _Palette.textMuted,
                                fontSize: r.fs(12),
                                letterSpacing: -1)),
                      ]),
                    ),
                    SizedBox(height: r.s(6)),
                    Text(
                        '${pedo.distanceKm.toStringAsFixed(1)} км · Ещё ${_fmtNum(pedo.remaining)} до цели',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: _Palette.textMuted,
                            fontSize: r.fs(11))),
                  ],
                ),
              ),
              SizedBox(width: r.s(12)),
              SizedBox(
                width: r.s(74),
                height: r.s(74),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: r.s(74),
                      height: r.s(74),
                      child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: r.s(4),
                        backgroundColor: _Palette.divider,
                        valueColor: const AlwaysStoppedAnimation(
                            _Palette.green),
                      ),
                    ),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: '${(pct * 100).round()}',
                            style: GoogleFonts.inter(
                                color: _Palette.text,
                                fontSize: r.fs(18),
                                fontWeight: FontWeight.w500)),
                        TextSpan(
                            text: '%',
                            style: GoogleFonts.inter(
                                color: _Palette.text,
                                fontSize: r.fs(11))),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  ACHIEVEMENTS
  // ═════════════════════════════════════════════════════════
  Widget _achievements(FitnessProvider fitness) {
    final r = _R(context);
    final stats = fitness.getStats();
    final badges = _getBadges(stats);
    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: r.s(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.s(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Маленькие победы',
                    style: GoogleFonts.inter(
                        color: _Palette.text,
                        fontSize: r.fs(20),
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.6)),
                Text('Все ${badges.length}',
                    style: GoogleFonts.inter(
                        color: _Palette.green, fontSize: r.fs(12))),
              ],
            ),
          ),
          SizedBox(height: r.s(16)),
          SizedBox(
            height: r.s(140),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: r.s(20)),
              itemCount: badges.length,
              separatorBuilder: (_, __) => SizedBox(width: r.s(10)),
              itemBuilder: (_, i) {
                final b = badges[i];
                return Container(
                  width: r.s(135),
                  padding: EdgeInsets.all(r.s(14)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(r.s(24)),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.9), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: r.s(42),
                        height: r.s(42),
                        decoration: BoxDecoration(
                          color: b.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(b.emoji,
                            style: TextStyle(fontSize: r.fs(20))),
                      ),
                      const Spacer(),
                      Text(b.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: _Palette.text,
                              fontSize: r.fs(12),
                              fontWeight: FontWeight.w500)),
                      SizedBox(height: r.s(4)),
                      Text(b.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted,
                              fontSize: r.fs(10))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  PR RECORDS
  // ═════════════════════════════════════════════════════════
  Widget _prStrip(FitnessProvider fitness) {
    final r = _R(context);
    final prs = _getPRs(fitness);
    if (prs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: r.s(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.s(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Рекорды',
                    style: GoogleFonts.inter(
                        color: _Palette.text,
                        fontSize: r.fs(20),
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.6)),
                Text('Все',
                    style: GoogleFonts.inter(
                        color: _Palette.green, fontSize: r.fs(12))),
              ],
            ),
          ),
          SizedBox(height: r.s(16)),
          SizedBox(
            height: r.s(108),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: r.s(20)),
              itemCount: prs.length,
              separatorBuilder: (_, __) => SizedBox(width: r.s(10)),
              itemBuilder: (_, i) {
                final pr = prs[i];
                return Container(
                  width: r.s(115),
                  padding: EdgeInsets.all(r.s(12)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(r.s(20)),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.9), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: r.s(30),
                        height: r.s(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pr.color.withOpacity(0.12),
                        ),
                        alignment: Alignment.center,
                        child: Text(pr.emoji,
                            style: TextStyle(fontSize: r.fs(14))),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(pr.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  color: _Palette.text,
                                  fontSize: r.fs(22),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -1.0,
                                  height: 1)),
                          SizedBox(height: r.s(3)),
                          Text(pr.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  color: _Palette.textMuted,
                                  fontSize: r.fs(9.5),
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  RHYTHM (Пульс недели)
  // ═════════════════════════════════════════════════════════
  Widget _rhythm(FitnessProvider fitness) {
    final r = _R(context);
    final today = DateTime.now();
    final stats = fitness.getStats();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final thisWeek = _getThisWeek(fitness, today);
    final todayIndex = today.weekday - 1;

    final allDays = _buildWeekData(fitness, today, todayIndex);
    final days = allDays.sublist(0, 5);

    final maxVal = math.max(
        1.0,
        days.fold<double>(
            0.0, (m, d) => math.max(m, d.workouts.toDouble())));
    final weekVol = allDays.fold<double>(0.0, (s, d) => s + d.volume);
    final activeDays = allDays.where((d) => d.workouts > 0).length;

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Container(
        padding: EdgeInsets.all(r.s(20)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.72),
          borderRadius: BorderRadius.circular(r.s(28)),
          border: Border.all(
              color: Colors.white.withOpacity(0.9), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        color: _Palette.yellow, size: r.s(18)),
                    SizedBox(width: r.s(8)),
                    Text('ПУЛЬС НЕДЕЛИ',
                        style: GoogleFonts.inter(
                            color: _Palette.yellow,
                            fontSize: r.fs(10),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1)),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: r.s(8), vertical: r.s(4)),
                  decoration: BoxDecoration(
                      color: _Palette.peachSoft,
                      borderRadius: BorderRadius.circular(r.s(8))),
                  child: Text('🔥 $streak',
                      style: GoogleFonts.inter(
                          color: _Palette.peach,
                          fontSize: r.fs(11),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            SizedBox(height: r.s(20)),
            SizedBox(
              height: r.s(100),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (i) {
                  final h = days[i].workouts > 0
                      ? (days[i].workouts / maxVal).clamp(0.2, 1.0)
                      : 0.05;
                  final isToday = i == todayIndex;
                  final color = isToday ? _Palette.green : _Palette.sage;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: r.s(4)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: h),
                            duration:
                            Duration(milliseconds: 800 + i * 100),
                            curve: Curves.easeOutCubic,
                            builder: (_, anim, __) => Container(
                              height: r.s(82) * anim,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(r.s(8)),
                              ),
                            ),
                          ),
                          SizedBox(height: r.s(8)),
                          Text(['П', 'В', 'С', 'Ч', 'П'][i],
                              style: GoogleFonts.inter(
                                  color: isToday
                                      ? _Palette.green
                                      : _Palette.textMuted,
                                  fontSize: r.fs(10),
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: r.s(18)),
            Container(
              padding:
              EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(12)),
              decoration: BoxDecoration(
                  color: _Palette.bg,
                  borderRadius: BorderRadius.circular(r.s(14))),
              child: Row(
                children: [
                  Expanded(
                      child: _footerStat('⚡', _formatVolume(weekVol),
                          'тоннаж', _Palette.peach, r)),
                  Container(width: 1, height: r.s(26), color: _Palette.divider),
                  Expanded(
                      child: _footerStat('🏋️', '$thisWeek', 'тренировок',
                          _Palette.green, r)),
                  Container(width: 1, height: r.s(26), color: _Palette.divider),
                  Expanded(
                      child: _footerStat('📅', '$activeDays/7', 'дней',
                          _Palette.sage, r)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerStat(
      String emoji, String value, String label, Color color, _R r) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: r.fs(11))),
            SizedBox(width: r.s(4)),
            Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: _Palette.text,
                      fontSize: r.fs(14),
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4)),
            ),
          ],
        ),
        SizedBox(height: r.s(2)),
        Text(label,
            style: GoogleFonts.inter(
                color: _Palette.textMuted,
                fontSize: r.fs(8.5),
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  QUICK DOCK — единый контейнер
  // ═════════════════════════════════════════════════════════
  Widget _quickDock(FitnessProvider fitness) {
    final r = _R(context);
    final items = [
      (Icons.play_arrow_rounded, 'Старт', _Palette.green,
          () => _quickStartWorkout(context, fitness)),
      (Icons.history_rounded, 'Журнал', _Palette.peach,
          () => _openWorkoutLog(context)),
      (Icons.fitness_center_rounded, 'База', _Palette.sage,
          () => _openExerciseLibrary(context)),
      (Icons.self_improvement_rounded, 'Настрой', _Palette.pink,
          () => _openWellbeing(context)),
      (Icons.flag_rounded, 'Цели', _Palette.yellow,
          () => _openTargets(context)),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(24)),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: r.s(14), horizontal: r.s(8)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.72),
          borderRadius: BorderRadius.circular(r.s(24)),
          border: Border.all(
              color: Colors.white.withOpacity(0.9), width: 1),
          boxShadow: [
            BoxShadow(
              color: _Palette.green.withOpacity(0.05),
              blurRadius: 18,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: items.map((it) {
            return Expanded(
              child: _TapScale(
                onTap: it.$4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: r.s(48),
                      height: r.s(48),
                      decoration: BoxDecoration(
                        color: it.$3.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(r.s(16)),
                      ),
                      child: Icon(it.$1, color: it.$3, size: r.s(22)),
                    ),
                    SizedBox(height: r.s(6)),
                    Text(it.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: _Palette.text,
                            fontSize: r.fs(10),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  TARGETS — с крупными иконками без рамок
  // ═════════════════════════════════════════════════════════
  Widget _targetsSection(FitnessProvider fitness) {
    final r = _R(context);
    final active = fitness.activeTargets;
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Мои ориентиры',
                  style: GoogleFonts.inter(
                      color: _Palette.text,
                      fontSize: r.fs(20),
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.6)),
              _TapScale(
                onTap: () => _openTargets(context),
                child: Text('Изменить',
                    style: GoogleFonts.inter(
                        color: _Palette.green, fontSize: r.fs(12))),
              ),
            ],
          ),
          SizedBox(height: r.s(16)),
          if (active.isEmpty)
            _emptyTarget(r)
          else
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: r.s(12), vertical: r.s(4)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(r.s(28)),
                border: Border.all(
                    color: Colors.white.withOpacity(0.9), width: 1),
              ),
              child: Column(
                  children: active
                      .take(3)
                      .map((t) => _targetRow(t, fitness, r))
                      .toList()),
            ),
        ],
      ),
    );
  }

  Widget _targetRow(FitnessTarget target, FitnessProvider fitness, _R r) {
    Exercise? exercise;
    if (target.exerciseId != null && target.exerciseId!.isNotEmpty) {
      try {
        exercise =
            fitness.exercises.firstWhere((e) => e.id == target.exerciseId);
      } catch (_) {}
    }
    final imageUrl = exercise?.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final emoji = exercise?.exerciseType.emoji ?? target.type.emoji;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: fitness,
              child:
              FitnessTargetDetailsScreen(target: target, isDark: false),
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: r.s(14)),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: r.s(54),
                  height: r.s(54),
                  decoration: BoxDecoration(
                    color: target.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(r.s(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: hasImage
                      ? _AppImg(
                    path: imageUrl,
                    fallback: Text(emoji,
                        style: TextStyle(fontSize: r.fs(24))),
                  )
                      : Text(emoji, style: TextStyle(fontSize: r.fs(24))),
                ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(target.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: _Palette.text,
                              fontSize: r.fs(13),
                              fontWeight: FontWeight.w500)),
                      Text(
                          'Прогресс · ${(target.progressPercent * 100).round()}%',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted,
                              fontSize: r.fs(10))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: _Palette.textMuted, size: r.s(18)),
              ],
            ),
            SizedBox(height: r.s(10)),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: target.progressPercent.clamp(0.0, 1.0),
                minHeight: r.s(3),
                backgroundColor: _Palette.divider,
                valueColor: AlwaysStoppedAnimation(target.accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTarget(_R r) {
    return _TapScale(
      onTap: () => _openTargets(context),
      child: Container(
        padding: EdgeInsets.all(r.s(16)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.72),
          borderRadius: BorderRadius.circular(r.s(28)),
          border: Border.all(
              color: Colors.white.withOpacity(0.9), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: r.s(52),
              height: r.s(52),
              decoration: BoxDecoration(
                color: _Palette.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded,
                  color: _Palette.green, size: r.s(24)),
            ),
            SizedBox(width: r.s(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Поставить первую цель',
                      style: GoogleFonts.inter(
                          color: _Palette.text,
                          fontSize: r.fs(14),
                          fontWeight: FontWeight.w500)),
                  Text('Например, жим 100 кг',
                      style: GoogleFonts.inter(
                          color: _Palette.textMuted,
                          fontSize: r.fs(12))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _Palette.textMuted, size: r.s(20)),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HELPERS
  // ═════════════════════════════════════════════════════════
  List<_Badge> _getBadges(Map<String, dynamic> stats) {
    final total = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final volume = ((stats['totalVolume'] ?? 0.0) as num).toDouble();

    final list = <_Badge>[];
    if (total >= 1) list.add(_Badge('🏅', 'Первая', 'Начало пути', _Palette.peach));
    if (streak >= 7) list.add(_Badge('🔥', '7 дней', 'В ритме', _Palette.pink));
    if (total >= 10) {
      list.add(_Badge('💪', '10 тренировок', 'Сильная неделя', _Palette.green));
    }
    if (volume >= 1000) {
      list.add(_Badge('⚡', 'Тонна', '50км за месяц', _Palette.yellow));
    }
    if (streak >= 30) {
      list.add(_Badge('👑', '30 дней', 'Железная воля', _Palette.sage));
    }
    return list;
  }

  List<_DayData> _buildWeekData(
      FitnessProvider fitness, DateTime today, int todayIndex) {
    final result = <_DayData>[];
    for (int i = 0; i < 7; i++) {
      final targetDay = today.subtract(Duration(days: todayIndex - i));
      final isFuture = i > todayIndex;

      int workoutCount = 0;
      double volume = 0;

      if (!isFuture) {
        try {
          final logs = fitness.getLogsForDate(targetDay);
          workoutCount = logs.length;
          for (final log in logs) {
            volume += _extractLogVolume(log);
          }
        } catch (_) {}
      }

      result.add(_DayData(
        date: targetDay,
        workouts: workoutCount,
        volume: volume,
        isToday: i == todayIndex,
        isFuture: isFuture,
      ));
    }
    return result;
  }

  int _levelFromStats(Map<String, dynamic> stats) {
    final total = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    return 1 + (total ~/ 3);
  }

  List<_PR> _getPRs(FitnessProvider fitness) {
    final prs = <_PR>[];
    final stats = fitness.getStats();
    final total = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    final volume = ((stats['totalVolume'] ?? 0.0) as num).toDouble();

    final dailyVolumes = <String, double>{};
    final dailyWorkouts = <String, int>{};
    try {
      for (final log in fitness.logs) {
        final d = _extractLogDate(log);
        if (d == null) continue;
        final key = '${d.year}-${d.month}-${d.day}';
        dailyVolumes[key] = (dailyVolumes[key] ?? 0) + _extractLogVolume(log);
        dailyWorkouts[key] = (dailyWorkouts[key] ?? 0) + 1;
      }
    } catch (_) {}

    if (dailyVolumes.isNotEmpty) {
      final bestVol = dailyVolumes.values.reduce(math.max);
      if (bestVol > 0) {
        prs.add(_PR('⚡', _formatVolume(bestVol), 'за тренировку',
            _Palette.yellow));
      }
    }
    if (dailyWorkouts.isNotEmpty) {
      final bestDay = dailyWorkouts.values.reduce(math.max);
      if (bestDay > 0) prs.add(_PR('🏋️', '$bestDay', 'за день', _Palette.peach));
    }
    if (total > 0) prs.add(_PR('🎯', '$total', 'всего', _Palette.green));
    if (volume > 0) {
      prs.add(_PR('🔥', _formatVolume(volume), 'общий тоннаж', _Palette.pink));
    }

    return prs;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  String _greetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '🌙';
    if (hour < 12) return '☀️';
    if (hour < 18) return '🌤';
    return '🌆';
  }

  // ═════════════════════════════════════════════════════════
  //  QUICK START WORKOUT
  // ═════════════════════════════════════════════════════════
  void _quickStartWorkout(BuildContext context, FitnessProvider provider) {
    final r = _R(context);
    HapticFeedback.mediumImpact();
    final quickDay = WorkoutDay(
      id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
      programId: 'quick',
      dayNumber: 1,
      exercises: [],
    );
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = provider.exercises
                .where((e) =>
            query.isEmpty || e.name.toLowerCase().contains(query))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(r.s(32))),
              ),
              padding:
              EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(20)),
              child: Column(
                children: [
                  Container(
                      width: r.s(38),
                      height: r.s(5),
                      decoration: BoxDecoration(
                          color: _Palette.divider,
                          borderRadius: BorderRadius.circular(r.s(3)))),
                  SizedBox(height: r.s(20)),
                  Row(
                    children: [
                      Container(
                        width: r.s(46),
                        height: r.s(46),
                        decoration: BoxDecoration(
                            color: _Palette.greenSoft,
                            borderRadius: BorderRadius.circular(r.s(13))),
                        child: Icon(Icons.bolt_rounded,
                            color: _Palette.green, size: r.s(24)),
                      ),
                      SizedBox(width: r.s(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Быстрая тренировка',
                                style: GoogleFonts.inter(
                                    color: _Palette.text,
                                    fontSize: r.fs(20),
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: r.s(2)),
                            Text('Выберите упражнения',
                                style: GoogleFonts.inter(
                                    color: _Palette.textMuted,
                                    fontSize: r.fs(12))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.s(16)),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (_) => setSheetState(() {}),
                    style: GoogleFonts.inter(color: _Palette.text),
                    decoration: InputDecoration(
                      hintText: 'Поиск упражнений',
                      hintStyle: GoogleFonts.inter(color: _Palette.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _Palette.textMuted, size: 20),
                      filled: true,
                      fillColor: _Palette.bg,
                      contentPadding:
                      EdgeInsets.symmetric(vertical: r.s(14)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(r.s(14)),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  SizedBox(height: r.s(14)),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                        child: Text('Ничего не найдено',
                            style: GoogleFonts.inter(
                                color: _Palette.textMuted)))
                        : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: r.s(8)),
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        final added = quickDay.exercises.any((item) =>
                        item.exerciseId == exercise.id);
                        final color = exercise.muscleGroups.isNotEmpty
                            ? exercise.muscleGroups.first.color
                            : _Palette.green;
                        final hasImage = exercise.imageUrl != null &&
                            exercise.imageUrl!.isNotEmpty;

                        return Container(
                          decoration: BoxDecoration(
                            color: _Palette.bg,
                            borderRadius:
                            BorderRadius.circular(r.s(14)),
                            border: Border.all(
                                color: _Palette.divider, width: 0.6),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: r.s(12),
                                vertical: r.s(4)),
                            leading: Container(
                              width: r.s(40),
                              height: r.s(40),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius:
                                BorderRadius.circular(r.s(11)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: hasImage
                                  ? _AppImg(
                                path: exercise.imageUrl,
                                fallback: Center(
                                    child: Text(
                                        exercise.exerciseType
                                            .emoji,
                                        style: TextStyle(
                                            fontSize:
                                            r.fs(18)))),
                              )
                                  : Center(
                                  child: Text(
                                      exercise.exerciseType.emoji,
                                      style: TextStyle(
                                          fontSize: r.fs(18)))),
                            ),
                            title: Text(exercise.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    color: _Palette.text,
                                    fontWeight: FontWeight.w500)),
                            trailing: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setSheetState(() {
                                  if (added) {
                                    quickDay.exercises.removeWhere(
                                            (item) =>
                                        item.exerciseId ==
                                            exercise.id);
                                  } else {
                                    quickDay.exercises
                                        .add(WorkoutExercise(
                                      id:
                                      'quick_ex_${quickDay.exercises.length}',
                                      exerciseId: exercise.id,
                                      order: quickDay.exercises.length,
                                      sets: [
                                        ExerciseSet(
                                            setNumber: 1,
                                            reps: 10,
                                            weight: 0)
                                      ],
                                    ));
                                  }
                                });
                              },
                              child: Container(
                                width: r.s(34),
                                height: r.s(34),
                                decoration: BoxDecoration(
                                  color: added
                                      ? _Palette.pinkSoft
                                      : _Palette.greenSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                    added
                                        ? Icons.remove_rounded
                                        : Icons.add_rounded,
                                    color: added
                                        ? _Palette.pink
                                        : _Palette.green,
                                    size: r.s(20)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (quickDay.exercises.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: r.s(12)),
                      child: SizedBox(
                        width: double.infinity,
                        height: r.s(54),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChangeNotifierProvider.value(
                                      value: provider,
                                      child: WorkoutExecutionScreen(
                                          day: quickDay, isDark: false),
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Palette.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(r.s(14))),
                          ),
                          child: Text(
                              'НАЧАТЬ · ${quickDay.exercises.length} УПР.',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════
  //  PROFILE DIALOG
  // ═════════════════════════════════════════════════════════
  void _showEditProfileDialog(FitnessProvider provider) {
    final r = _R(context);
    final controller = TextEditingController(
        text: _profileName.isNotEmpty
            ? _profileName
            : (provider.profile?.name ?? ''));
    const emojis = [
      '💪', '🏋️', '🏃', '🧘', '🚴', '🤸', '🥊',
      '🔥', '⚡', '🦁', '🐺', '🦅', '👑', '🎯'
    ];
    String selectedEmoji = _avatarEmoji;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                left: r.s(16),
                right: r.s(16),
                top: r.s(16),
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              padding: EdgeInsets.all(r.s(20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(r.s(32))),
              ),
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
                            borderRadius: BorderRadius.circular(r.s(3)))),
                  ),
                  SizedBox(height: r.s(20)),
                  Text('ПРОФИЛЬ',
                      style: GoogleFonts.inter(
                          color: _Palette.green,
                          fontSize: r.fs(10),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0)),
                  SizedBox(height: r.s(4)),
                  Text('Атлет',
                      style: GoogleFonts.inter(
                          color: _Palette.text,
                          fontSize: r.fs(22),
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.8)),
                  SizedBox(height: r.s(20)),
                  TextField(
                    controller: controller,
                    style: GoogleFonts.inter(
                        color: _Palette.text,
                        fontSize: r.fs(17),
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Введите имя',
                      hintStyle: GoogleFonts.inter(color: _Palette.textMuted),
                      filled: true,
                      fillColor: _Palette.bg,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: r.s(16), vertical: r.s(16)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(r.s(14)),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  SizedBox(height: r.s(20)),
                  Text('АВАТАР',
                      style: GoogleFonts.inter(
                          color: _Palette.textMuted,
                          fontSize: r.fs(10),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4)),
                  SizedBox(height: r.s(10)),
                  Wrap(
                    spacing: r.s(8),
                    runSpacing: r.s(8),
                    children: emojis.map((emoji) {
                      final selected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => selectedEmoji = emoji);
                        },
                        child: Container(
                          width: r.s(46),
                          height: r.s(46),
                          decoration: BoxDecoration(
                            color: selected
                                ? _Palette.greenSoft
                                : _Palette.bg,
                            borderRadius: BorderRadius.circular(r.s(12)),
                            border: Border.all(
                                color: selected
                                    ? _Palette.green
                                    : Colors.transparent,
                                width: 1.5),
                          ),
                          child: Center(
                              child: Text(emoji,
                                  style: TextStyle(fontSize: r.fs(24)))),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: r.s(22)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newName = controller.text.trim();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('avatar_emoji', selectedEmoji);
                        if (newName.isNotEmpty) {
                          await prefs.setString('profile_name', newName);
                        }
                        if (!mounted) return;
                        setState(() {
                          _avatarEmoji = selectedEmoji;
                          if (newName.isNotEmpty) _profileName = newName;
                        });
                        Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: r.s(16)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(r.s(14))),
                      ),
                      child: Text('СОХРАНИТЬ',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFitness(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
              value: context.read<FitnessProvider>(),
              child: const FitnessDashboard(isDark: true))));
  void _openNutrition(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
              value: context.read<NutritionProvider>(),
              child: const FuelDashboardScreen(isDark: true))));
  void _openWorkoutLog(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
              value: context.read<FitnessProvider>(),
              child: const WorkoutLogScreen(isDark: true))));
  void _openTargets(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
              value: context.read<FitnessProvider>(),
              child: const FitnessTargetsScreen(isDark: true))));
  void _openExerciseLibrary(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
              value: context.read<FitnessProvider>(),
              child: const ExerciseLibraryScreen(isDark: true))));
  void _openWellbeing(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
              value: context.read<FitnessProvider>(),
              child: const WellbeingScreen(isDark: true))));
  void _openProgress(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
              value: context.read<FitnessProvider>(),
              child: const ProgressScreen(isDark: true))));
  void _openPedometer(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
              value: context.read<PedometerProvider>(),
              child: const PedometerScreen(isDark: true))));
}

// ═══════════════════════════════════════════════════════════════════
//  VOLUME CARD
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

  static const _periodLabels = ['Нед', 'Мес', 'Год', 'Все'];

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

  Future<void> _saveGoal(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weekly_volume_goal', v);
  }

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));

    double weekVol = 0, monthVol = 0, yearVol = 0, allVol = 0;
    double lastWeekVol = 0;
    final last4Weeks = List<double>.filled(4, 0);

    try {
      for (final log in widget.fitness.logs) {
        final d = _extractLogDate(log);
        if (d == null) continue;
        final v = _extractLogVolume(log);
        if (v <= 0) continue;

        allVol += v;
        if (!d.isBefore(yearStart)) yearVol += v;
        if (!d.isBefore(monthStart)) monthVol += v;
        if (!d.isBefore(weekStart)) weekVol += v;
        if (!d.isBefore(lastWeekStart) && d.isBefore(weekStart)) {
          lastWeekVol += v;
        }

        final day = DateTime(d.year, d.month, d.day);
        for (int i = 0; i < 4; i++) {
          final wStart = weekStart.subtract(Duration(days: (3 - i) * 7));
          final wEnd = wStart.add(const Duration(days: 7));
          if (!day.isBefore(wStart) && day.isBefore(wEnd)) {
            last4Weeks[i] += v;
            break;
          }
        }
      }
    } catch (_) {}

    final values = [weekVol, monthVol, yearVol, allVol];
    final currentVal = values[_selectedPeriod];
    final diff = weekVol - lastWeekVol;
    final pctChange = lastWeekVol > 0
        ? ((diff / lastWeekVol) * 100).round()
        : (weekVol > 0 ? 100 : 0);
    final goalPct =
    _weeklyGoal > 0 ? (weekVol / _weeklyGoal).clamp(0.0, 1.0) : 0.0;
    final goalReached = weekVol >= _weeklyGoal;
    final accent = goalReached ? _Palette.green : _Palette.sage;
    final maxWeek = last4Weeks.reduce(math.max);

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _Palette.greenSoft.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(r.s(28)),
          border: Border.all(
              color: Colors.white.withOpacity(0.9), width: 1),
          boxShadow: [
            BoxShadow(
              color: _Palette.green.withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r.s(28)),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: IgnorePointer(
                  child: Container(
                    width: r.s(160),
                    height: r.s(160),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _Palette.green.withOpacity(0.10),
                          _Palette.green.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(r.s(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: r.s(34),
                          height: r.s(34),
                          decoration: BoxDecoration(
                            color: _Palette.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(r.s(10)),
                          ),
                          alignment: Alignment.center,
                          child: Text('🏋️',
                              style: TextStyle(fontSize: r.fs(15))),
                        ),
                        SizedBox(width: r.s(10)),
                        Text('ОБЪЁМ',
                            style: GoogleFonts.inter(
                                color: _Palette.green,
                                fontSize: r.fs(10),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6)),
                        const Spacer(),
                        _TapScale(
                          onTap: _editGoal,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: r.s(10), vertical: r.s(6)),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(r.s(10)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag_rounded,
                                    color: accent, size: r.s(11)),
                                SizedBox(width: r.s(4)),
                                Text('${_fmtNum(_weeklyGoal.round())} кг',
                                    style: GoogleFonts.inter(
                                        color: accent,
                                        fontSize: r.fs(10.5),
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.s(16)),
                    Row(
                      children: List.generate(4, (i) {
                        final selected = _selectedPeriod == i;
                        return Expanded(
                          child: Padding(
                            padding:
                            EdgeInsets.only(right: i < 3 ? r.s(6) : 0),
                            child: _TapScale(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedPeriod = i);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding:
                                EdgeInsets.symmetric(vertical: r.s(8)),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _Palette.green
                                      : Colors.white.withOpacity(0.6),
                                  borderRadius:
                                  BorderRadius.circular(r.s(10)),
                                ),
                                child: Center(
                                  child: Text(_periodLabels[i],
                                      style: GoogleFonts.inter(
                                          color: selected
                                              ? Colors.white
                                              : _Palette.textMuted,
                                          fontSize: r.fs(11),
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: r.s(16)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatVolume(currentVal),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      color: _Palette.text,
                                      fontSize: r.fs(34),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -1.6,
                                      height: 1)),
                              SizedBox(height: r.s(6)),
                              Text(
                                _selectedPeriod == 0
                                    ? 'к прошлой неделе: ${_formatVolume(lastWeekVol)} кг'
                                    : _selectedPeriod == 1
                                    ? 'за текущий месяц'
                                    : _selectedPeriod == 2
                                    ? 'за ${now.year} год'
                                    : 'за всё время',
                                style: GoogleFonts.inter(
                                    color: _Palette.textMuted,
                                    fontSize: r.fs(11)),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedPeriod == 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: r.s(9), vertical: r.s(6)),
                            decoration: BoxDecoration(
                              color: (diff >= 0
                                  ? _Palette.green
                                  : _Palette.pink)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(r.s(9)),
                            ),
                            child: Text(
                                '${diff >= 0 ? '↑' : '↓'} ${pctChange.abs()}%',
                                style: GoogleFonts.inter(
                                    color: diff >= 0
                                        ? _Palette.green
                                        : _Palette.pink,
                                    fontSize: r.fs(12),
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    if (_selectedPeriod == 0) ...[
                      SizedBox(height: r.s(18)),
                      SizedBox(
                        height: r.s(58),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(4, (i) {
                            final v = last4Weeks[i];
                            final h = maxWeek > 0
                                ? (v / maxWeek).clamp(0.15, 1.0)
                                : 0.15;
                            final isNow = i == 3;
                            final barColor =
                            isNow ? _Palette.green : _Palette.sage;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: i < 3 ? r.s(6) : 0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: h),
                                      duration:
                                      Duration(milliseconds: 500 + i * 100),
                                      curve: Curves.easeOutCubic,
                                      builder: (_, anim, __) => Container(
                                        height: r.s(36) * anim,
                                        decoration: BoxDecoration(
                                          color: barColor,
                                          borderRadius:
                                          BorderRadius.circular(r.s(6)),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: r.s(6)),
                                    Text(isNow ? 'сейчас' : '-${3 - i}н',
                                        style: GoogleFonts.inter(
                                            color: isNow
                                                ? _Palette.green
                                                : _Palette.textMuted,
                                            fontSize: r.fs(8.5),
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                    SizedBox(height: r.s(16)),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(r.s(5)),
                            child: Stack(
                              children: [
                                Container(
                                    height: r.s(10),
                                    color: Colors.white.withOpacity(0.7)),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: goalPct),
                                  duration: const Duration(milliseconds: 900),
                                  builder: (_, v, __) => FractionallySizedBox(
                                    widthFactor: v,
                                    child: Container(
                                      height: r.s(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            accent.withOpacity(0.7),
                                            accent
                                          ],
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(r.s(5)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: r.s(10)),
                        Text('${(goalPct * 100).round()}%',
                            style: GoogleFonts.inter(
                                color: accent,
                                fontSize: r.fs(12),
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editGoal() async {
    final r = _R(context);
    final ctrl = TextEditingController(text: _weeklyGoal.toStringAsFixed(0));
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: r.s(16),
            right: r.s(16),
            top: r.s(16),
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(r.s(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(r.s(28))),
          ),
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
                        borderRadius: BorderRadius.circular(r.s(3)))),
              ),
              SizedBox(height: r.s(20)),
              Text('ЦЕЛЬ ТОННАЖА',
                  style: GoogleFonts.inter(
                      color: _Palette.green,
                      fontSize: r.fs(10),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0)),
              SizedBox(height: r.s(4)),
              Text('Сколько кг за неделю?',
                  style: GoogleFonts.inter(
                      color: _Palette.text,
                      fontSize: r.fs(20),
                      fontWeight: FontWeight.w600)),
              SizedBox(height: r.s(16)),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(
                    color: _Palette.text,
                    fontSize: r.fs(22),
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '10000',
                  suffixText: 'кг',
                  filled: true,
                  fillColor: _Palette.bg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(r.s(14)),
                      borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: r.s(16)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                      ctx, double.tryParse(ctrl.text.replaceAll(',', '.'))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: r.s(16)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(r.s(14))),
                  ),
                  child: Text('СОХРАНИТЬ',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && result > 0) {
      setState(() => _weeklyGoal = result);
      await _saveGoal(result);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS & PAINTERS
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
                height: p.size * 0.5),
            const Radius.circular(1.5)),
        Paint()..color = p.color.withOpacity((1 - t * 0.9).clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

class _HeroRingsPainter extends CustomPainter {
  final double anim;
  final List<bool> daysActive;
  final int daysPassed;
  final double caloriesProgress, workoutsProgress, streakProgress;
  final DateTime time;

  _HeroRingsPainter({
    required this.anim,
    required this.daysActive,
    required this.daysPassed,
    required this.caloriesProgress,
    required this.workoutsProgress,
    required this.streakProgress,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 340.0;

    const rDigits = 160.0;
    const r1 = 144.0;
    const rDayLabels = 126.0;
    const r2 = 108.0;
    const r3 = 82.0;
    const r4 = 56.0;
    const r5 = 30.0;
    const stroke = 10.0;

    _drawHourNumbers(canvas, center, rDigits * scale, _Palette.green, scale);
    _drawTimeDial(canvas, center, r1 * scale, stroke * scale, time,
        _Palette.green, anim);
    _drawDayLabels(
        canvas, center, rDayLabels * scale, daysActive, _Palette.yellow, scale);
    _drawDaysRing(
        canvas, center, r2 * scale, stroke * scale, daysActive, _Palette.yellow);
    _drawProgressRing(canvas, center, r3 * scale, stroke * scale,
        caloriesProgress * anim, _Palette.sage);
    _drawProgressRing(canvas, center, r4 * scale, stroke * scale,
        workoutsProgress * anim, _Palette.peach);
    _drawProgressRing(canvas, center, r5 * scale, stroke * scale,
        streakProgress * anim, _Palette.pink);
  }

  void _drawHourNumbers(
      Canvas canvas, Offset center, double radius, Color color, double scale) {
    const hours = [0, 3, 6, 9, 12, 15, 18, 21];
    final fontSize = 9.0 * scale;
    for (final h in hours) {
      final angle = -math.pi / 2 + (h / 24.0) * 2 * math.pi;
      final pos = Offset(center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius);
      final tp = TextPainter(
        text: TextSpan(
          text: h.toString().padLeft(2, '0'),
          style: TextStyle(
              color: color.withOpacity(0.75),
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawDayLabels(Canvas canvas, Offset center, double radius,
      List<bool> daysActive, Color color, double scale) {
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final fontSize = 9.0 * scale;
    for (int i = 0; i < 7; i++) {
      final angle = -math.pi / 2 + (i / 7.0 + 1.0 / 14.0) * 2 * math.pi;
      final pos = Offset(center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius);
      final hasWorkout = i < daysActive.length && daysActive[i];
      final isPast = i < daysPassed;
      final isToday = i == daysPassed - 1;

      Color textColor;
      FontWeight weight;
      if (isToday) {
        textColor = _Palette.peach;
        weight = FontWeight.w900;
      } else if (hasWorkout) {
        textColor = color;
        weight = FontWeight.w900;
      } else if (isPast) {
        textColor = _Palette.peach.withOpacity(0.65);
        weight = FontWeight.w700;
      } else {
        textColor = color.withOpacity(0.35);
        weight = FontWeight.w700;
      }

      final tp = TextPainter(
        text: TextSpan(
          text: names[i],
          style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: weight,
              height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawTimeDial(Canvas canvas, Offset center, double radius, double stroke,
      DateTime time, Color color, double anim) {
    final hoursNow = time.hour + time.minute / 60.0;
    final progress = (hoursNow / 24.0) * anim;
    const segments = 24;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const segGap = 0.018;

    for (int i = 0; i < segments; i++) {
      final segStart = i / segments;
      final segEnd = (i + 1) / segments;
      final startAngle = -math.pi / 2 + segStart * 2 * math.pi;
      final sweep = (segEnd - segStart) * 2 * math.pi;
      final filled = progress >= segEnd;
      final partial = !filled && progress > segStart;

      if (filled) {
        canvas.drawArc(
            rect,
            startAngle + segGap,
            sweep - segGap * 2,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..strokeCap = StrokeCap.round
              ..color = color);
      } else if (partial) {
        final partialSweep =
            (progress * 2 * math.pi) - (segStart * 2 * math.pi);
        canvas.drawArc(
            rect,
            startAngle + segGap,
            partialSweep - segGap,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..strokeCap = StrokeCap.round
              ..color = color);
      } else {
        canvas.drawArc(
            rect,
            startAngle + segGap,
            sweep - segGap * 2,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 0.75
              ..strokeCap = StrokeCap.round
              ..color = color.withOpacity(0.13));
      }
    }
    final timeAngle = -math.pi / 2 + progress * 2 * math.pi;
    final dotPos = Offset(center.dx + math.cos(timeAngle) * radius,
        center.dy + math.sin(timeAngle) * radius);
    canvas.drawCircle(
        dotPos,
        stroke * 1.0,
        Paint()
          ..color = color.withOpacity(0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawCircle(dotPos, stroke * 0.65, Paint()..color = color);
    canvas.drawCircle(dotPos, stroke * 0.28, Paint()..color = Colors.white);
  }

  void _drawDaysRing(Canvas canvas, Offset center, double radius, double stroke,
      List<bool> daysActive, Color color) {
    const segments = 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const segGap = 0.035;

    for (int i = 0; i < segments; i++) {
      final segStart = i / segments;
      final segEnd = (i + 1) / segments;
      final startAngle = -math.pi / 2 + segStart * 2 * math.pi;
      final sweep = (segEnd - segStart) * 2 * math.pi;
      final hasWorkout = i < daysActive.length && daysActive[i];
      final isPast = i < daysPassed;
      final isToday = i == daysPassed - 1;

      if (hasWorkout) {
        canvas.drawArc(
            rect,
            startAngle + segGap,
            sweep - segGap * 2,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 1.6
              ..strokeCap = StrokeCap.round
              ..color = color.withOpacity(0.20)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawArc(
            rect,
            startAngle + segGap,
            sweep - segGap * 2,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..strokeCap = StrokeCap.round
              ..color = color);
        canvas.drawArc(
            rect,
            startAngle + segGap,
            (sweep - segGap * 2) * 0.18,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 0.35
              ..strokeCap = StrokeCap.round
              ..color = Colors.white.withOpacity(0.6));
      } else if (isToday) {
        canvas.drawArc(
            rect,
            startAngle + segGap,
            sweep - segGap * 2,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..strokeCap = StrokeCap.round
              ..color = _Palette.peach);
      } else if (isPast) {
        canvas.drawArc(
            rect,
            startAngle + segGap,
            sweep - segGap * 2,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 0.75
              ..strokeCap = StrokeCap.round
              ..color = _Palette.peach.withOpacity(0.35));
      } else {
        canvas.drawArc(
            rect,
            startAngle + segGap,
            sweep - segGap * 2,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 0.75
              ..strokeCap = StrokeCap.round
              ..color = color.withOpacity(0.13));
      }
    }
  }

  void _drawProgressRing(Canvas canvas, Offset center, double radius,
      double stroke, double progress, Color color) {
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.75
          ..color = color.withOpacity(0.13));
    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.6
          ..strokeCap = StrokeCap.round
          ..color = color.withOpacity(0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color);
    canvas.drawArc(
        rect,
        start,
        sweep * 0.08,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.4
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withOpacity(0.65));
  }

  @override
  bool shouldRepaint(covariant _HeroRingsPainter old) => true;
}

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
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}