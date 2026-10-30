// lib/home_screen.dart
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, MaskFilter, BlurStyle;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zal_life/features/fitness/database/ui/screens/active_program_screen.dart';
import 'package:zal_life/features/fitness/database/ui/screens/exercise_library_screen.dart';
import 'package:zal_life/features/fitness/database/ui/screens/fitness_dashboard.dart';
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
//  DESIGN SYSTEM — современный iOS
// ═══════════════════════════════════════════════════════════════════
class _Palette {
  static const orange = Color(0xFFFF9F0A);
  static const red    = Color(0xFFFF453A);
  static const pink   = Color(0xFFFF375F);
  static const blue   = Color(0xFF0A84FF);
  static const green  = Color(0xFF32D74B);
  static const teal   = Color(0xFF64D2FF);
  static const purple = Color(0xFFBF5AF2);
  static const indigo = Color(0xFF5E5CE6);
  static const yellow = Color(0xFFFFD60A);
  static const gold   = Color(0xFFFFD60A);

  static const bg       = Color(0xFF000000);
  static const surface  = Color(0xFF0A0A0D);
  static const elevated = Color(0xFF16161B);
}

// Apple SF Pro-inspired type scale
class _T {
  static const largeTitle = TextStyle(
    fontSize: 34, fontWeight: FontWeight.w700,
    letterSpacing: 0.37, height: 1.15,
  );
  static const title1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    letterSpacing: 0.36, height: 1.15,
  );
  static const title2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    letterSpacing: -0.26, height: 1.2,
  );
  static const title3 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600,
    letterSpacing: -0.45, height: 1.2,
  );
  static const headline = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600,
    letterSpacing: -0.43, height: 1.3,
  );
  static const body = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w400,
    letterSpacing: -0.43, height: 1.3,
  );
  static const callout = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w500,
    letterSpacing: -0.32, height: 1.3,
  );
  static const subhead = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w500,
    letterSpacing: -0.24, height: 1.3,
  );
  static const footnote = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500,
    letterSpacing: -0.08, height: 1.3,
  );
  static const caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500,
    letterSpacing: 0, height: 1.3,
  );
  static const caption2 = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    letterSpacing: 0.07, height: 1.3,
  );
  static const overline = TextStyle(
    fontSize: 10.5, fontWeight: FontWeight.w800,
    letterSpacing: 1.5, height: 1.1,
  );
}

// Spring curves — то, что делает iOS «живым»
class _Spring {
  static const snappy = Cubic(0.2, 0.9, 0.25, 1.1);
  static const gentle = Cubic(0.15, 0.85, 0.2, 1.0);
  static const bouncy = Cubic(0.34, 1.56, 0.64, 1.0);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _drift;
  late final AnimationController _aurora;
  late final AnimationController _entrance;
  late final AnimationController _confetti;
  late final ScrollController _scroll;

  late List<_ConfettiParticle> _confettiParticles;
  bool? _wasCompleted;

  String _avatarEmoji = '💪';
  String _profileName = '';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat(reverse: true);

    _aurora = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _confettiParticles = _generateConfetti();
    _scroll = ScrollController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _avatarEmoji = prefs.getString('avatar_emoji') ?? '💪';
      _profileName = prefs.getString('profile_name') ?? '';
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _drift.dispose();
    _aurora.dispose();
    _entrance.dispose();
    _confetti.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<_ConfettiParticle> _generateConfetti() {
    final rng = math.Random(42);
    const colors = [
      _Palette.orange, _Palette.pink, _Palette.blue,
      _Palette.green, _Palette.purple, _Palette.yellow, _Palette.teal,
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

  // ═════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final fitness   = context.watch<FitnessProvider>();

    final nutrition = context.watch<NutritionProvider>();

    final pedometer  = context.watch<PedometerProvider>();

    final stats0 = fitness.getStats();
    final thisWeek0 = ((stats0['workoutsThisWeek'] ?? 0) as num).toInt();
    final completed = thisWeek0 >= 5;

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
          _ambient(),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: _Palette.orange,
              backgroundColor: _Palette.elevated,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 400));
                HapticFeedback.lightImpact();
              },
              child: CustomScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _entranceAt(0.00, _topBar(fitness))),
                  SliverToBoxAdapter(child: _parallax(
                    _entranceAt(0.06, _hero(fitness, nutrition)),
                  )),
                  SliverToBoxAdapter(child: _entranceAt(0.16, _focusCard(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.24, _insightsCard(fitness, nutrition))),
                  SliverToBoxAdapter(child: _entranceAt(0.32, _bentoTop(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.40, _bentoMid(nutrition))),
                  SliverToBoxAdapter(child: _entranceAt(0.46, _stepsCard(pedometer))),
                  SliverToBoxAdapter(child: _entranceAt(0.48, _achievements(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.54, _prStrip(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.60, _rhythm(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.68, _quickDock(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.76, _targetsSection(fitness))),
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
            progress: _confetti.value,
            particles: _confettiParticles,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════
  //  ENTRANCE / PARALLAX — spring physics
  // ═════════════════════════════════════════════════════════
  Widget _entranceAt(double delay, Widget child) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (_, __) {
        final span = (1.0 - delay).clamp(0.01, 1.0);
        final t = ((_entrance.value - delay) / span).clamp(0.0, 1.0);
        final eased = _Spring.gentle.transform(t);
        return Opacity(
          opacity: eased.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - eased)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _parallax(Widget child) {
    return ListenableBuilder(
      listenable: _scroll,
      builder: (_, inner) {
        final offset = _scroll.hasClients
            ? _scroll.offset.clamp(0.0, 240.0)
            : 0.0;
        final scale = 1 - offset / 240 * 0.055;
        return Transform.translate(
          offset: Offset(0, offset * 0.16),
          child: Transform.scale(
            scale: scale.clamp(0.945, 1.0),
            alignment: Alignment.topCenter,
            child: inner,
          ),
        );
      },
      child: child,
    );
  }

  // ═════════════════════════════════════════════════════════
  //  AMBIENT
  // ═════════════════════════════════════════════════════════
  Widget _ambient() {
    Widget orb(Color c, double size, double opacity) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [c.withOpacity(opacity), Colors.transparent],
          stops: const [0.0, 0.85],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _drift,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_drift.value);
        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  top: -280 + t * 30,
                  left: -200 - t * 40,
                  child: orb(_Palette.orange, 600, 0.15),
                ),
                Positioned(
                  top: 80 + t * 20,
                  right: -230 + t * 30,
                  child: orb(_Palette.purple, 540, 0.09),
                ),
                Positioned(
                  bottom: -300 - t * 20,
                  left: -140 + t * 30,
                  child: orb(_Palette.blue, 600, 0.08),
                ),
                Positioned(
                  bottom: 200,
                  right: -200 - t * 20,
                  child: orb(_Palette.pink, 460, 0.06),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════
  //  LIQUID GLASS — с внутренними тенями и спекуляром
  // ═════════════════════════════════════════════════════════
  Widget _liquidGlass({
    required Widget child,
    EdgeInsets? padding,
    double radius = 28,
    double blur = 30,
    Color? tint,
    Color? strokeTop,
  }) {
    final accent = tint ?? Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(0.085),
                Colors.white.withOpacity(0.025),
                Colors.black.withOpacity(0.08),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.085),
              width: 0.7,
            ),
          ),
          child: Stack(
            children: [
              // Спекулярный блик сверху
              Positioned(
                top: 0,
                left: radius * 0.7,
                right: radius * 0.7,
                child: Container(
                  height: 1.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        (strokeTop ?? Colors.white).withOpacity(0.55),
                        Colors.white.withOpacity(0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 0.65, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (strokeTop ?? Colors.white).withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              // Радиальный блик в верхнем левом углу (как в iOS 26)
              Positioned(
                top: radius * 0.18,
                left: radius * 0.22,
                child: IgnorePointer(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.10),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
              // Внутренняя тень снизу — «утопленность»
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 42,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(radius),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  TOP BAR
  // ═════════════════════════════════════════════════════════
  Widget _topBar(FitnessProvider fitness) {
    final stats  = fitness.getStats();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final level  = _levelFromStats(stats);
    final displayName = _profileName.isNotEmpty
        ? _profileName
        : (fitness.profile?.name ?? 'Атлет');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(
        children: [
          _avatar(fitness),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _breathingDot(_Palette.green),
                    const SizedBox(width: 6),
                    Text(
                      '${_greetingIcon()} ${_greeting().toUpperCase()}',
                      style: _T.overline.copyWith(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _levelBadge(level),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.largeTitle.copyWith(
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),
          _streakPill(streak),
          const SizedBox(width: 8),
          _circleButton(
            icon: Icons.insights_rounded,
            onTap: () => _openProgress(context),
          ),
        ],
      ),
    );
  }

  Widget _levelBadge(int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _Palette.purple.withOpacity(0.30),
            _Palette.indigo.withOpacity(0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _Palette.purple.withOpacity(0.32),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 8, height: 1)),
          const SizedBox(width: 3),
          Text(
            'LV $level',
            style: _T.caption2.copyWith(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _breathingDot(Color color) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final o = 0.5 + _pulse.value * 0.5;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(o), blurRadius: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _avatar(FitnessProvider fitness) {
    return _TapScale(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showEditProfileDialog(fitness);
      },
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final glow = 0.30 + _pulse.value * 0.22;
          return Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_Palette.orange, _Palette.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _Palette.orange.withOpacity(glow),
                  blurRadius: 26,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              alignment: Alignment.center,
              child: Text(_avatarEmoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }

  Widget _streakPill(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _Palette.orange.withOpacity(0.22),
            _Palette.pink.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _Palette.orange.withOpacity(0.32),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12, height: 1)),
          const SizedBox(width: 5),
          Text(
            '$streak',
            style: _T.footnote.copyWith(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _TapScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.09),
            width: 0.7,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.80),
          size: 19,
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HERO
  // ═════════════════════════════════════════════════════════
  Widget _hero(FitnessProvider fitness, NutritionProvider nutrition) {
    final stats     = fitness.getStats();
    final streak    = ((stats['currentStreak'] ?? 0) as num).toInt();
    final thisWeek  = ((stats['workoutsThisWeek'] ?? 0) as num).toInt();
    final volume    = ((stats['totalVolume'] ?? 0.0) as num).toDouble();
    const weekGoal  = 5;

    final today     = DateTime.now();
    final summary   = nutrition.getSummaryForDate(today);
    final goals     = nutrition.getGoalsForDate(today);
    final wellbeing = fitness.getTodayWellbeing();

    final p1 = (thisWeek / weekGoal).clamp(0.0, 1.0);
    final p2 = (streak / 30).clamp(0.0, 1.0);
    final p3 = goals.calories > 0
        ? (summary.calories / goals.calories).clamp(0.0, 1.0)
        : 0.0;

    final trend = _deriveTrend(thisWeek, streak);
    final readiness = _readinessScore(streak, thisWeek, wellbeing);
    final rc = _readinessColor(readiness);
    final completed = thisWeek >= weekGoal;
    final comparison = _comparisonText(fitness, today);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Stack(
        children: [
          _liquidGlass(
            radius: 32,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            strokeTop: completed ? _Palette.gold : rc,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: rc.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        completed ? 'ЦЕЛЬ ДОСТИГНУТА' : 'ЭТА НЕДЕЛЯ',
                        style: _T.overline.copyWith(
                          color: completed ? _Palette.gold : rc,
                          fontSize: 9.5,
                          letterSpacing: 1.7,
                        ),
                      ),
                    ),
                    if (completed) ...[
                      const SizedBox(width: 6),
                      const Text('🏆',
                          style: TextStyle(fontSize: 12, height: 1)),
                    ],
                    const Spacer(),
                    Text(
                      _formatFullDate(today),
                      style: _T.caption.copyWith(
                        color: Colors.white.withOpacity(0.42),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Aurora glow
                        AnimatedBuilder(
                          animation: _aurora,
                          builder: (_, __) {
                            final t = _aurora.value;
                            return Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  transform:
                                  GradientRotation(t * 2 * math.pi),
                                  colors: [
                                    rc.withOpacity(0.0),
                                    rc.withOpacity(0.18),
                                    _Palette.pink.withOpacity(0.12),
                                    _Palette.purple.withOpacity(0.06),
                                    rc.withOpacity(0.0),
                                  ],
                                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                                ),
                              ),
                            );
                          },
                        ),
                        // Sparkles
                        AnimatedBuilder(
                          animation: _aurora,
                          builder: (_, __) => CustomPaint(
                            size: const Size(280, 280),
                            painter: _SparklesPainter(
                              progress: _aurora.value,
                              color: completed ? _Palette.gold : rc,
                            ),
                          ),
                        ),
                        // Inner core
                        Container(
                          width: 156,
                          height: 156,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _Palette.bg.withOpacity(0.55),
                            border: Border.all(
                              color: rc.withOpacity(0.15),
                              width: 0.7,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: rc.withOpacity(0.10),
                                blurRadius: 30,
                                spreadRadius: -8,
                              ),
                            ],
                          ),
                        ),
                        // Tick ring
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1400),
                          curve: _Spring.gentle,
                          builder: (_, anim, __) => CustomPaint(
                            size: const Size(252, 252),
                            painter: _TickRingPainter(
                              progress: (readiness / 100) * anim,
                              tickColor: completed ? _Palette.gold : rc,
                              tickCount: 60,
                            ),
                          ),
                        ),
                        // Triple ring
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1400),
                          curve: _Spring.gentle,
                          builder: (_, anim, __) => CustomPaint(
                            size: const Size(200, 200),
                            painter: _TriRingPainter(
                              p1: p1 * anim,
                              p2: p2 * anim,
                              p3: p3 * anim,
                              c1: _Palette.orange,
                              c2: _Palette.pink,
                              c3: _Palette.green,
                            ),
                          ),
                        ),
                        // Center column
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _CountUp(
                              value: thisWeek.toDouble(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 58,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -3.2,
                                height: 0.95,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'из $weekGoal',
                              style: _T.footnote.copyWith(
                                color: Colors.white.withOpacity(0.45),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: rc.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: rc.withOpacity(0.25),
                                  width: 0.6,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: rc,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: rc.withOpacity(0.7),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${readiness.round()}%',
                                    style: _T.caption2.copyWith(
                                      color: rc,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'готовность',
                                    style: _T.caption2.copyWith(
                                      color: Colors.white.withOpacity(0.55),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _legendChip(
                        color: _Palette.orange,
                        label: 'Тренировки',
                        value: '$thisWeek/$weekGoal',
                        progress: p1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _legendChip(
                        color: _Palette.pink,
                        label: 'Серия',
                        value: '$streak ${_daysWord(streak)}',
                        progress: p2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _legendChip(
                        color: _Palette.green,
                        label: 'Калории',
                        value: '${summary.calories.round()}',
                        progress: p3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 0.5, color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _heroMessage(thisWeek, weekGoal),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _T.footnote.copyWith(
                          color: completed
                              ? _Palette.gold
                              : Colors.white.withOpacity(0.78),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _trendSpark(trend),
                    if (comparison != null) ...[
                      const SizedBox(width: 8),
                      _comparisonChip(comparison),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatVolume(volume)} кг',
                            style: _T.caption2.copyWith(
                              color: Colors.white.withOpacity(0.70),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Rotating conic border
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _aurora,
                builder: (_, __) => CustomPaint(
                  painter: _ConicBorderPainter(
                    progress: _aurora.value,
                    color: completed ? _Palette.gold : rc,
                    radius: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonChip(_Comparison c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: c.color.withOpacity(0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            c.symbol,
            style: TextStyle(
              color: c.color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            c.value,
            style: _T.caption2.copyWith(
              color: c.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendChip({
    required Color color,
    required String label,
    required String value,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.6), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.caption2.copyWith(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 9.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _T.footnote.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 2.5,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendSpark(List<double> data) {
    return SizedBox(
      width: 54,
      height: 24,
      child: CustomPaint(
        painter: _SparkPainter(data: data, color: _Palette.orange),
      ),
    );
  }

  String _heroMessage(int thisWeek, int goal) {
    if (thisWeek == 0) return 'Пора начать неделю 💪';
    if (thisWeek >= goal) return 'Цель недели достигнута! 🎉';
    final remaining = goal - thisWeek;
    if (remaining == 1) return 'Ещё одна тренировка до цели 🔥';
    return 'Ещё $remaining тренировки до цели 🔥';
  }

  // ═════════════════════════════════════════════════════════
  //  FOCUS
  // ═════════════════════════════════════════════════════════
  Widget _focusCard(FitnessProvider fitness) {
    final session   = fitness.activeSession;
    final wellbeing = fitness.getTodayWellbeing();

    if (session != null) {
      WorkoutProgram? program;
      try {
        program = fitness.programs.firstWhere((p) => p.id == session.programId);
      } catch (_) {
        program = null;
      }

      return _focusTile(
        accent: _Palette.purple,
        icon: Icons.play_arrow_rounded,
        label: 'ПРОДОЛЖИТЬ',
        title: program?.name ?? 'Активная тренировка',
        subtitle:
        'День ${session.currentDayIndex + 1} · ${(session.progressPercent * 100).round()}%',
        ctaIcon: Icons.arrow_forward_rounded,
        glow: true,
        onTap: () {
          HapticFeedback.lightImpact();
          final p = program;
          if (p != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: fitness,
                  child: ActiveProgramScreen(program: p, isDark: true),
                ),
              ),
            );
          }
        },
      );
    }

    if (wellbeing == null) {
      return _focusTile(
        accent: _Palette.green,
        icon: Icons.mood_rounded,
        label: 'СЕГОДНЯ',
        title: 'Как самочувствие?',
        subtitle: 'Отметь состояние — влияет на готовность',
        ctaIcon: Icons.arrow_forward_rounded,
        onTap: () => _openWellbeing(context),
      );
    }

    return _focusTile(
      accent: _Palette.orange,
      icon: Icons.bolt_rounded,
      label: 'СЕГОДНЯ',
      title: 'Готов к тренировке?',
      subtitle: 'Старт в один тап',
      ctaIcon: Icons.play_arrow_rounded,
      onTap: () => _quickStartWorkout(context, fitness),
    );
  }

  Widget _focusTile({
    required Color accent,
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
    required IconData ctaIcon,
    required VoidCallback onTap,
    bool glow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: _TapScale(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            final breathing = glow ? 0.10 + _pulse.value * 0.12 : 0.0;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: glow
                    ? [
                  BoxShadow(
                    color: accent.withOpacity(breathing),
                    blurRadius: 32,
                    spreadRadius: -4,
                  ),
                ]
                    : null,
              ),
              child: _liquidGlass(
                radius: 26,
                padding: const EdgeInsets.all(16),
                strokeTop: accent,
                tint: accent,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withOpacity(0.32),
                            accent.withOpacity(0.14),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withOpacity(0.30),
                          width: 0.7,
                        ),
                      ),
                      child: Icon(icon, color: accent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: _T.overline.copyWith(
                              color: accent,
                              fontSize: 9.5,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _T.callout.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _T.caption.copyWith(
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(ctaIcon, color: accent, size: 20),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  INSIGHTS
  // ═════════════════════════════════════════════════════════
  Widget _insightsCard(
      FitnessProvider fitness, NutritionProvider nutrition) {
    final insights = _buildInsights(fitness, nutrition);
    if (insights.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sectionHeader('Инсайты', badge: '${insights.length}'),
          ),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: insights.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _insightTile(insights[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightTile(_Insight ins) {
    return Container(
      width: 220,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ins.color.withOpacity(0.16),
            ins.color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ins.color.withOpacity(0.28),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: ins.color.withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: -6,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ins.color.withOpacity(0.16),
              border: Border.all(
                color: ins.color.withOpacity(0.35),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Text(ins.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ins.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.footnote.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ins.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _T.caption2.copyWith(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
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
    final prs = _getPRs(fitness);
    if (prs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sectionHeader('Рекорды', badge: '${prs.length}'),
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: prs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _prTile(prs[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prTile(_PR pr) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pr.color.withOpacity(0.18),
            pr.color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pr.color.withOpacity(0.28),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: pr.color.withOpacity(0.14),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pr.color.withOpacity(0.16),
              border: Border.all(
                color: pr.color.withOpacity(0.35),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Text(pr.emoji, style: const TextStyle(fontSize: 14)),
          ),
          const Spacer(),
          Text(
            pr.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            pr.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _T.caption2.copyWith(
              color: Colors.white.withOpacity(0.55),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  BENTO ROW 1
  // ═════════════════════════════════════════════════════════
  Widget _bentoTop(FitnessProvider fitness) {
    final stats = fitness.getStats();
    final thisWeek = ((stats['workoutsThisWeek'] ?? 0) as num).toInt();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final trend = _deriveTrend(thisWeek, streak);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: _fitnessCard(fitness, thisWeek, trend)),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: _streakCard(streak)),
          ],
        ),
      ),
    );
  }

  Widget _fitnessCard(
      FitnessProvider fitness, int thisWeek, List<double> trend) {
    const goal = 5;
    final pct = (thisWeek / goal).clamp(0.0, 1.0);

    return _TapScale(
      onTap: () => _openFitness(context),
      child: _liquidGlass(
        radius: 26,
        padding: const EdgeInsets.all(18),
        strokeTop: _Palette.orange,
        tint: _Palette.orange,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _Palette.orange.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.fitness_center_rounded,
                      color: _Palette.orange, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Фитнес',
                    style: _T.callout.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(Icons.arrow_outward_rounded,
                    color: Colors.white.withOpacity(0.35), size: 14),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CountUp(
                  value: thisWeek.toDouble(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2.4,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/ $goal',
                    style: _T.title3.copyWith(
                      color: Colors.white.withOpacity(0.38),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 54,
                  height: 30,
                  child: CustomPaint(
                    painter: _SparkPainter(data: trend, color: _Palette.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'тренировок на этой неделе',
              style: _T.caption.copyWith(
                color: Colors.white.withOpacity(0.48),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation(_Palette.orange),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _miniTag(
                  icon: Icons.flag_rounded,
                  label: '${fitness.activeTargets.length} целей',
                  color: _Palette.pink,
                ),
                const SizedBox(width: 6),
                _miniTag(
                  icon: Icons.menu_book_rounded,
                  label: '${fitness.exercises.length} упр.',
                  color: _Palette.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: _T.caption2.copyWith(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakCard(int streak) {
    const goal = 30;
    final pct = (streak / goal).clamp(0.0, 1.0);

    return _TapScale(
      onTap: () => _openProgress(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1200), Color(0xFF120800)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: _Palette.orange.withOpacity(0.28),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: _Palette.orange.withOpacity(0.14),
              blurRadius: 24,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + _pulse.value * 0.15,
                    child: const Text('🔥', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(pct * 100).round()}%',
                  style: _T.caption2.copyWith(
                    color: _Palette.orange.withOpacity(0.8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 5.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withOpacity(0.07),
                        valueColor:
                        const AlwaysStoppedAnimation(_Palette.orange),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CountUp(
                          value: streak.toDouble(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            height: 1,
                          ),
                        ),
                        Text(
                          '/ $goal',
                          style: _T.caption2.copyWith(
                            color: Colors.white.withOpacity(0.40),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                _daysWord(streak),
                style: _T.caption2.copyWith(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  BENTO ROW 2
  // ═════════════════════════════════════════════════════════
  Widget _bentoMid(NutritionProvider nutrition) {
    final today   = DateTime.now();
    final summary = nutrition.getSummaryForDate(today);
    final goals   = nutrition.getGoalsForDate(today);
    final kcalPct = goals.calories > 0
        ? (summary.calories / goals.calories).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: _nutritionCard(summary, goals, kcalPct)),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: _waterCard(summary, goals)),
          ],
        ),
      ),
    );
  }

  Widget _nutritionCard(dynamic summary, dynamic goals, double pct) {
    return _TapScale(
      onTap: () => _openNutrition(context),
      child: _liquidGlass(
        radius: 26,
        padding: const EdgeInsets.all(18),
        strokeTop: _Palette.green,
        tint: _Palette.green,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _Palette.green.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.restaurant_rounded,
                      color: _Palette.green, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Питание',
                    style: _T.callout.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(Icons.arrow_outward_rounded,
                    color: Colors.white.withOpacity(0.35), size: 14),
              ],
            ),
            const SizedBox(height: 16),
            _CountUp(
              value: summary.calories,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.4,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'из ${goals.calories.round()} ккал',
              style: _T.caption.copyWith(
                color: Colors.white.withOpacity(0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation(_Palette.green),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _macro('Б', summary.protein, _Palette.green),
                const SizedBox(width: 5),
                _macro('Ж', summary.fat, _Palette.orange),
                const SizedBox(width: 5),
                _macro('У', summary.carbs, _Palette.yellow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macro(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label ${value.round()}',
        style: _T.caption2.copyWith(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _waterCard(dynamic summary, dynamic goals) {
    final pct = goals.waterMl > 0
        ? (summary.waterMl / goals.waterMl).clamp(0.0, 1.0)
        : 0.0;
    final liters = summary.waterMl / 1000.0;

    return _TapScale(
      onTap: () => _openNutrition(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF001F2A), Color(0xFF000A12)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _Palette.teal.withOpacity(0.28), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _Palette.teal.withOpacity(0.12),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_rounded,
                    color: _Palette.teal, size: 15),
                const Spacer(),
                Text(
                  '${(pct * 100).round()}%',
                  style: _T.caption2.copyWith(
                    color: _Palette.teal.withOpacity(0.8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 5.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withOpacity(0.07),
                        valueColor:
                        const AlwaysStoppedAnimation(_Palette.teal),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CountUp(
                          value: liters,
                          decimals: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1,
                          ),
                        ),
                        Text(
                          'л',
                          style: _T.caption2.copyWith(
                            color: Colors.white.withOpacity(0.40),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                'из ${(goals.waterMl / 1000).toStringAsFixed(1)} л',
                style: _T.caption2.copyWith(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  ACHIEVEMENTS
  // ═════════════════════════════════════════════════════════
  Widget _achievements(FitnessProvider fitness) {
    final stats  = fitness.getStats();
    final badges = _getBadges(stats);
    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sectionHeader('Достижения', badge: '${badges.length}'),
          ),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: badges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _badgeTile(badges[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeTile(_Badge b) {
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            b.color.withOpacity(0.16),
            b.color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: b.color.withOpacity(0.25),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: b.color.withOpacity(0.12),
            blurRadius: 18,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: b.color.withOpacity(0.14),
              border: Border.all(
                color: b.color.withOpacity(0.35),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: b.color.withOpacity(0.3),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(b.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 8),
          Text(
            b.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _T.caption2.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  RHYTHM
  // ═════════════════════════════════════════════════════════
  Widget _rhythm(FitnessProvider fitness) {
    final stats  = fitness.getStats();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final thisWeek = ((stats['workoutsThisWeek'] ?? 0) as num).toInt();
    final today  = DateTime.now();
    final todayIndex = today.weekday - 1;

    final days = _buildWeekData(fitness, today, todayIndex, streak);
    final useVolume = days.any((d) => d.volume > 0);
    final maxVal = math.max(
      1.0,
      days.fold<double>(0.0, (m, d) {
        final v = useVolume ? d.volume : d.workouts.toDouble();
        return math.max(m, v);
      }),
    );
    final weekVol = days.fold<double>(0.0, (s, d) => s + d.volume);
    final activeDays = days.where((d) => d.workouts > 0).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: _liquidGlass(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        strokeTop: _Palette.yellow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _Palette.yellow.withOpacity(0.28),
                        _Palette.orange.withOpacity(0.14),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _Palette.yellow.withOpacity(0.28),
                      width: 0.6,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('📊', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Text(
                  'ПУЛЬС НЕДЕЛИ',
                  style: _T.overline.copyWith(
                    color: _Palette.yellow,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) {
                    final glow = 0.10 + _pulse.value * 0.10;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _Palette.orange.withOpacity(0.24),
                            _Palette.pink.withOpacity(0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _Palette.orange.withOpacity(0.30),
                          width: 0.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _Palette.orange.withOpacity(glow),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥',
                              style: TextStyle(fontSize: 10, height: 1)),
                          const SizedBox(width: 4),
                          Text(
                            '$streak',
                            style: _T.caption2.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 130,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      return Expanded(
                        child: Padding(
                          padding:
                          EdgeInsets.symmetric(horizontal: i == 6 ? 2 : 3),
                          child: _bar(
                            data: days[i],
                            maxVal: maxVal,
                            useVolume: useVolume,
                            index: i,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(7, (i) {
                final isToday = i == todayIndex;
                const names = ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'];
                return Expanded(
                  child: Center(
                    child: Text(
                      names[i],
                      style: _T.caption2.copyWith(
                        color: isToday
                            ? _Palette.yellow
                            : Colors.white.withOpacity(0.40),
                        fontSize: 10,
                        fontWeight:
                        isToday ? FontWeight.w900 : FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.035),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _footerStat(
                      '⚡',
                      useVolume ? _formatVolume(weekVol) : '—',
                      'тоннаж',
                      _Palette.orange,
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 26,
                    color: Colors.white.withOpacity(0.10),
                  ),
                  Expanded(
                    child: _footerStat(
                        '🏋️', '$thisWeek', 'тренировок', _Palette.blue),
                  ),
                  Container(
                    width: 0.5,
                    height: 26,
                    color: Colors.white.withOpacity(0.10),
                  ),
                  Expanded(
                    child: _footerStat(
                        '📅', '$activeDays/7', 'дней', _Palette.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({
    required _DayData data,
    required double maxVal,
    required bool useVolume,
    required int index,
  }) {
    final rawVal = useVolume ? data.volume : data.workouts.toDouble();
    final targetH =
    rawVal <= 0 ? 0.06 : (rawVal / maxVal).clamp(0.10, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.isToday && data.workouts > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _Palette.yellow.withOpacity(0.18),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _Palette.yellow.withOpacity(0.35),
                  width: 0.6,
                ),
              ),
              child: Text(
                '${data.workouts}',
                style: _T.caption2.copyWith(
                  color: _Palette.yellow,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: targetH),
          duration: Duration(milliseconds: 700 + index * 80),
          curve: _Spring.gentle,
          builder: (_, anim, __) {
            return Container(
              height: 105 * anim,
              margin: const EdgeInsets.symmetric(vertical: 1),
              decoration: BoxDecoration(
                gradient: _barGradient(data),
                borderRadius: BorderRadius.circular(6),
                boxShadow: data.isToday && data.workouts > 0
                    ? [
                  BoxShadow(
                    color: _Palette.orange.withOpacity(0.45),
                    blurRadius: 14,
                    spreadRadius: -2,
                  ),
                ]
                    : data.workouts > 0
                    ? [
                  BoxShadow(
                    color: _Palette.orange.withOpacity(0.14),
                    blurRadius: 8,
                    spreadRadius: -4,
                  ),
                ]
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  LinearGradient _barGradient(_DayData d) {
    if (d.isFuture) {
      return LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.white.withOpacity(0.06),
          Colors.white.withOpacity(0.025),
        ],
      );
    }
    if (d.workouts == 0) {
      return LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.white.withOpacity(0.09),
          Colors.white.withOpacity(0.04),
        ],
      );
    }
    if (d.isToday) {
      return LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          _Palette.orange,
          _Palette.pink,
          _Palette.purple.withOpacity(0.9),
        ],
        stops: const [0.0, 0.65, 1.0],
      );
    }
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        _Palette.orange.withOpacity(0.85),
        _Palette.pink.withOpacity(0.55),
      ],
    );
  }

  Widget _footerStat(
      String emoji, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: _T.caption2.copyWith(
            color: Colors.white.withOpacity(0.42),
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  QUICK DOCK
  // ═════════════════════════════════════════════════════════
  Widget _quickDock(FitnessProvider fitness) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SizedBox(
        height: 98,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _dockButton(
              icon: Icons.play_arrow_rounded,
              label: 'Старт',
              color: _Palette.orange,
              onTap: () => _quickStartWorkout(context, fitness),
            ),
            _dockButton(
              icon: Icons.history_rounded,
              label: 'Журнал',
              color: _Palette.blue,
              onTap: () => _openWorkoutLog(context),
            ),
            _dockButton(
              icon: Icons.fitness_center_rounded,
              label: 'База',
              color: _Palette.purple,
              onTap: () => _openExerciseLibrary(context),
            ),
            _dockButton(
              icon: Icons.self_improvement_rounded,
              label: 'Настрой',
              color: _Palette.green,
              onTap: () => _openWellbeing(context),
            ),
            _dockButton(
              icon: Icons.flag_rounded,
              label: 'Цели',
              color: _Palette.pink,
              onTap: () => _openTargets(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dockButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: _TapScale(
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.26),
                      color.withOpacity(0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withOpacity(0.28),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.10),
                      blurRadius: 16,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _T.caption2.copyWith(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  TARGETS
  // ═════════════════════════════════════════════════════════
  Widget _targetsSection(FitnessProvider fitness) {
    final active = fitness.activeTargets;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Цели',
            badge: active.isEmpty ? null : '${active.length}',
            action: 'Все',
            onAction: () => _openTargets(context),
          ),
          if (active.isEmpty) _emptyTarget() else ...active.take(3).map(_targetCard),
        ],
      ),
    );
  }

  Widget _emptyTarget() {
    return _TapScale(
      onTap: () => _openTargets(context),
      child: _liquidGlass(
        radius: 20,
        padding: const EdgeInsets.all(16),
        tint: _Palette.orange,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _Palette.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded,
                  color: _Palette.orange, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Поставить первую цель',
                    style: _T.footnote.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Например, жим 100 кг',
                    style: _T.caption.copyWith(
                      color: Colors.white.withOpacity(0.42),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.30), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _targetCard(FitnessTarget target) {
    final progress = target.progressPercent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _TapScale(
        onTap: () => _openTargets(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _Palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 0.6,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: target.accentColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(target.type.emoji,
                    style: const TextStyle(fontSize: 19)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            target.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _T.footnote.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: _T.caption.copyWith(
                            color: target.accentColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.white.withOpacity(0.07),
                        valueColor:
                        AlwaysStoppedAnimation(target.accentColor),
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

  Widget _sectionHeader(
      String title, {
        String? badge,
        String? action,
        VoidCallback? onAction,
      }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: _T.title2.copyWith(
              color: Colors.white,
              letterSpacing: -0.8,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: _T.caption2.copyWith(
                  color: Colors.white.withOpacity(0.60),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (action != null)
            _TapScale(
              onTap: () => onAction?.call(),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _Palette.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  action,
                  style: _T.caption.copyWith(
                    color: _Palette.blue,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  QUICK START WORKOUT
  // ═════════════════════════════════════════════════════════
  void _quickStartWorkout(BuildContext context, FitnessProvider provider) {
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
            final filtered = provider.exercises.where((e) {
              if (query.isEmpty) return true;
              return e.name.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: _Palette.surface,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _Palette.orange.withOpacity(0.28),
                              _Palette.pink.withOpacity(0.14),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            color: _Palette.orange, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Быстрая тренировка',
                              style: _T.title3.copyWith(
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Выберите упражнения',
                              style: _T.caption.copyWith(
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (_) => setSheetState(() {}),
                    style: _T.subhead.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Поиск упражнений',
                      hintStyle: _T.subhead.copyWith(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withOpacity(0.4), size: 20),
                      filled: true,
                      fillColor: _Palette.elevated,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                      child: Text(
                        'Ничего не найдено',
                        style: _T.subhead.copyWith(
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    )
                        : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        final added = quickDay.exercises.any(
                              (item) => item.exerciseId == exercise.id,
                        );
                        final color = exercise.muscleGroups.isNotEmpty
                            ? exercise.muscleGroups.first.color
                            : _Palette.orange;

                        return Container(
                          decoration: BoxDecoration(
                            color: _Palette.elevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.04),
                              width: 0.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius:
                                BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(
                                  exercise.exerciseType.emoji,
                                  style:
                                  const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            title: Text(
                              exercise.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _T.footnote.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setSheetState(() {
                                  if (added) {
                                    quickDay.exercises.removeWhere(
                                          (item) =>
                                      item.exerciseId ==
                                          exercise.id,
                                    );
                                  } else {
                                    quickDay.exercises.add(
                                      WorkoutExercise(
                                        id:
                                        'quick_ex_${quickDay.exercises.length}',
                                        exerciseId: exercise.id,
                                        order: quickDay
                                            .exercises.length,
                                        sets: [
                                          ExerciseSet(
                                            setNumber: 1,
                                            reps: 10,
                                            weight: 0,
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                });
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: added
                                      ? _Palette.red.withOpacity(0.14)
                                      : _Palette.orange
                                      .withOpacity(0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  added
                                      ? Icons.remove_rounded
                                      : Icons.add_rounded,
                                  color: added
                                      ? _Palette.red
                                      : _Palette.orange,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (quickDay.exercises.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
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
                                        day: quickDay,
                                        isDark: true,
                                      ),
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Palette.orange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'НАЧАТЬ · ${quickDay.exercises.length} УПР.',
                            style: _T.subhead.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
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
    final controller = TextEditingController(
      text: _profileName.isNotEmpty
          ? _profileName
          : (provider.profile?.name ?? ''),
    );

    const emojis = [
      '💪', '🏋️', '🏃', '🧘', '🚴', '🤸', '🥊',
      '🔥', '⚡', '🦁', '🐺', '🦅', '👑', '🎯',
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
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: _Palette.surface,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ПРОФИЛЬ',
                    style: _T.overline.copyWith(
                      color: _Palette.orange,
                      fontSize: 10,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Атлет',
                    style: _T.title2.copyWith(
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    style: _T.headline.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Введите имя',
                      hintStyle: _T.headline.copyWith(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      filled: true,
                      fillColor: _Palette.elevated,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'АВАТАР',
                    style: _T.overline.copyWith(
                      color: Colors.white.withOpacity(0.30),
                      fontSize: 10,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emojis.map((emoji) {
                      final selected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => selectedEmoji = emoji);
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: selected
                                ? _Palette.orange.withOpacity(0.16)
                                : _Palette.elevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? _Palette.orange
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
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
                        backgroundColor: _Palette.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'СОХРАНИТЬ',
                        style: _T.subhead.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
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

  // ═════════════════════════════════════════════════════════
  //  NAVIGATION
  // ═════════════════════════════════════════════════════════
  void _openFitness(BuildContext context) {
    HapticFeedback.lightImpact();
    final fitness = context.read<FitnessProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: fitness,
          child: const FitnessDashboard(isDark: true),
        ),
      ),
    );
  }

  void _openNutrition(BuildContext context) {
    HapticFeedback.lightImpact();
    final nutrition = context.read<NutritionProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: nutrition,
          child: const FuelDashboardScreen(isDark: true),
        ),
      ),
    );
  }

  void _openWorkoutLog(BuildContext context) {
    HapticFeedback.selectionClick();
    final fitness = context.read<FitnessProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: fitness,
          child: const WorkoutLogScreen(isDark: true),
        ),
      ),
    );
  }

  void _openTargets(BuildContext context) {
    HapticFeedback.lightImpact();
    final fitness = context.read<FitnessProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: fitness,
          child: const FitnessTargetsScreen(isDark: true),
        ),
      ),
    );
  }

  void _openExerciseLibrary(BuildContext context) {
    HapticFeedback.selectionClick();
    final fitness = context.read<FitnessProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: fitness,
          child: const ExerciseLibraryScreen(isDark: true),
        ),
      ),
    );
  }

  void _openWellbeing(BuildContext context) {
    HapticFeedback.selectionClick();
    final fitness = context.read<FitnessProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: fitness,
          child: const WellbeingScreen(isDark: true),
        ),
      ),
    );
  }

  void _openProgress(BuildContext context) {
    HapticFeedback.lightImpact();
    final fitness = context.read<FitnessProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: fitness,
          child: const ProgressScreen(isDark: true),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  BUILDERS
  // ═════════════════════════════════════════════════════════
  List<_Insight> _buildInsights(
      FitnessProvider fitness, NutritionProvider nutrition) {
    final insights = <_Insight>[];
    final stats = fitness.getStats();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final thisWeek = ((stats['workoutsThisWeek'] ?? 0) as num).toInt();
    final wellbeing = fitness.getTodayWellbeing();
    final today = DateTime.now();
    final summary = nutrition.getSummaryForDate(today);
    final goals = nutrition.getGoalsForDate(today);

    if (thisWeek >= 5) {
      insights.add(const _Insight(
        '🏆', 'Цель недели', 'Ты справился! Отличная работа', _Palette.gold,
      ));
    } else if (thisWeek > 0) {
      final left = 5 - thisWeek;
      insights.add(_Insight(
        '⚡',
        'Ещё $left ${_daysWord(left)}',
        'до недельной цели',
        _Palette.orange,
      ));
    }

    if (streak >= 7) {
      insights.add(_Insight(
        '🔥',
        '$streak дней подряд',
        'Ты в огне — продолжай!',
        _Palette.pink,
      ));
    } else if (streak >= 3) {
      insights.add(_Insight(
        '🔥',
        'Серия $streak ${_daysWord(streak)}',
        'Хороший ритм',
        _Palette.orange,
      ));
    }

    final waterPct = goals.waterMl > 0
        ? (summary.waterMl / goals.waterMl * 100).round()
        : 0;
    if (goals.waterMl > 0 && waterPct < 60) {
      final remaining = goals.waterMl - summary.waterMl;
      insights.add(_Insight(
        '💧',
        'Вода: $waterPct%',
        'Ещё ${remaining}мл до цели',
        _Palette.teal,
      ));
    }

    if (wellbeing == null) {
      insights.add(const _Insight(
        '😴', 'Как самочувствие?', 'Отметь — влияет на готовность', _Palette.green,
      ));
    }

    if (streak >= 6 && streak < 10) {
      insights.add(_Insight(
        '💤',
        '$streak дней подряд',
        'Не забудь про отдых и сон',
        _Palette.indigo,
      ));
    }

    return insights;
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
        dailyVolumes[key] =
            (dailyVolumes[key] ?? 0) + _extractLogVolume(log);
        dailyWorkouts[key] = (dailyWorkouts[key] ?? 0) + 1;
      }
    } catch (_) {}

    if (dailyVolumes.isNotEmpty) {
      final bestVol = dailyVolumes.values.reduce(math.max);
      if (bestVol > 0) {
        prs.add(_PR('⚡', _formatVolume(bestVol), 'за тренировку', _Palette.yellow));
      }
    }
    if (dailyWorkouts.isNotEmpty) {
      final bestDay = dailyWorkouts.values.reduce(math.max);
      if (bestDay > 0) {
        prs.add(_PR('🏋️', '$bestDay', 'за день', _Palette.orange));
      }
    }
    if (total > 0) {
      prs.add(_PR('🎯', '$total', 'всего', _Palette.blue));
    }
    if (volume > 0) {
      prs.add(_PR('🔥', _formatVolume(volume), 'общий тоннаж', _Palette.pink));
    }

    return prs;
  }

  _Comparison? _comparisonText(FitnessProvider fitness, DateTime today) {
    try {
      final stats = fitness.getStats();
      final thisWeek = ((stats['workoutsThisWeek'] ?? 0) as num).toInt();

      final lastWeekStart = DateTime(
          today.year, today.month, today.day - today.weekday - 6);
      final lastWeekEnd = DateTime(
          today.year, today.month, today.day - today.weekday + 1);

      int lastWeekCount = 0;
      try {
        for (final log in fitness.logs) {
          final d = _extractLogDate(log);
          if (d == null) continue;
          if (!d.isBefore(lastWeekStart) && d.isBefore(lastWeekEnd)) {
            lastWeekCount++;
          }
        }
      } catch (_) {}

      if (lastWeekCount == 0 && thisWeek == 0) return null;
      if (lastWeekCount == 0) {
        return _Comparison('↑', '$thisWeek', _Palette.green);
      }
      final pct =
      ((thisWeek - lastWeekCount) / lastWeekCount * 100).round();
      if (pct > 0) return _Comparison('↑', '$pct%', _Palette.green);
      if (pct < 0) return _Comparison('↓', '${-pct}%', _Palette.red);
      return _Comparison('=', '0%', _Palette.yellow);
    } catch (_) {
      return null;
    }
  }

  // ═════════════════════════════════════════════════════════
  //  WEEK DATA
  // ═════════════════════════════════════════════════════════
  List<_DayData> _buildWeekData(
      FitnessProvider fitness,
      DateTime today,
      int todayIndex,
      int streak,
      ) {
    List<dynamic> logs = [];
    try {
      final raw = fitness.logs;
      if (raw is List) logs = raw;
    } catch (_) {}

    final result = <_DayData>[];
    for (int i = 0; i < 7; i++) {
      final targetDay = today.subtract(Duration(days: todayIndex - i));
      final dayStart =
      DateTime(targetDay.year, targetDay.month, targetDay.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final isFuture = i > todayIndex;

      int workoutCount = 0;
      double volume = 0;

      if (!isFuture) {
        for (final log in logs) {
          final logDate = _extractLogDate(log);
          if (logDate != null &&
              !logDate.isBefore(dayStart) &&
              logDate.isBefore(dayEnd)) {
            workoutCount++;
            volume += _extractLogVolume(log);
          }
        }
      }

      bool activeByStreak = false;
      if (!isFuture && workoutCount == 0) {
        final daysAgo = todayIndex - i;
        if (daysAgo >= 0 && daysAgo < streak) activeByStreak = true;
      }

      final effectiveWorkouts =
      workoutCount > 0 ? workoutCount : (activeByStreak ? 1 : 0);

      result.add(_DayData(
        date: targetDay,
        workouts: effectiveWorkouts,
        volume: volume,
        isToday: i == todayIndex,
        isFuture: isFuture,
      ));
    }
    return result;
  }

  DateTime? _extractLogDate(dynamic log) {
    try {
      final d = log.date;
      if (d is DateTime) return d;
    } catch (_) {}
    try {
      final d = log.startedAt;
      if (d is DateTime) return d;
    } catch (_) {}
    try {
      final d = log.createdAt;
      if (d is DateTime) return d;
    } catch (_) {}
    try {
      final d = log.performedAt;
      if (d is DateTime) return d;
    } catch (_) {}
    try {
      final d = log.timestamp;
      if (d is DateTime) return d;
      if (d is int) return DateTime.fromMillisecondsSinceEpoch(d);
    } catch (_) {}
    return null;
  }

  double _extractLogVolume(dynamic log) {
    try {
      final v = log.totalVolume;
      if (v is num) return v.toDouble();
    } catch (_) {}
    try {
      final v = log.volume;
      if (v is num) return v.toDouble();
    } catch (_) {}
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
              if (w is num && r is num) {
                total += w.toDouble() * r.toDouble();
              }
            }
          }
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  // ═════════════════════════════════════════════════════════
  //  HELPERS
  // ═════════════════════════════════════════════════════════
  List<double> _deriveTrend(int thisWeek, int streak) {
    final result = List<double>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final daysAgo = 6 - i;
      if (daysAgo < streak) result[i] = 1.0;
    }
    if (thisWeek > 0 && streak == 0) result[6] = 1.0;
    return result;
  }

  double _readinessScore(int streak, int thisWeek, dynamic wellbeing) {
    double score = 0;
    score += (streak / 7).clamp(0.0, 1.0) * 30;
    score += (thisWeek / 5).clamp(0.0, 1.0) * 30;
    score += streak > 0 ? 20 : 0;
    score += wellbeing != null ? 20 : 10;
    return score.clamp(0.0, 100.0);
  }

  Color _readinessColor(double score) {
    if (score >= 65) return _Palette.orange;
    if (score >= 45) return _Palette.yellow;
    return _Palette.blue;
  }

  int _levelFromStats(Map<String, dynamic> stats) {
    final total = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    return 1 + (total ~/ 3);
  }

  List<_Badge> _getBadges(Map<String, dynamic> stats) {
    final total = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final volume = ((stats['totalVolume'] ?? 0.0) as num).toDouble();

    final list = <_Badge>[];
    if (total >= 1) list.add(const _Badge('🏅', 'Первая', _Palette.orange));
    if (streak >= 7) list.add(const _Badge('🔥', '7 дней', _Palette.pink));
    if (total >= 10) list.add(const _Badge('💪', '10', _Palette.blue));
    if (volume >= 1000) list.add(const _Badge('⚡', 'Тонна', _Palette.yellow));
    if (streak >= 30) list.add(const _Badge('👑', '30 дней', _Palette.purple));
    return list;
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

  String _formatFullDate(DateTime date) {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(1)}k';
    return volume.toStringAsFixed(0);
  }

  String _daysWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'день';
    if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'дня';
    }
    return 'дней';
  }

  // ═════════════════════════════════════════════════════════
  //  STEPS CARD
  // ═════════════════════════════════════════════════════════
  Widget _stepsCard(PedometerProvider pedo) {
    final pct = pedo.progress;
    final reached = pedo.goalReached;
    final accent = reached ? _Palette.green : _Palette.orange;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: _TapScale(
        onTap: () => _openPedometer(context),
        child: _liquidGlass(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          strokeTop: accent,
          tint: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.directions_walk_rounded,
                        color: accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ШАГИ СЕГОДНЯ',
                      style: _T.overline.copyWith(
                        color: accent,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (pedo.isWalking)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _Palette.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _breathingDot(_Palette.green),
                          const SizedBox(width: 4),
                          Text(
                            'ИДЁШЬ',
                            style: _T.caption2.copyWith(
                              color: _Palette.green,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_outward_rounded,
                      color: Colors.white.withOpacity(0.35), size: 14),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _CountUp(
                              value: pedo.steps.toDouble(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -2.0,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                'шагов',
                                style: _T.caption.copyWith(
                                  color: Colors.white.withOpacity(0.40),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reached
                              ? 'Цель ${pedo.goal} достигнута 🎉'
                              : 'ещё ${_fmtNum(pedo.remaining)} до цели · ${(pct * 100).round()}%',
                          style: _T.caption.copyWith(
                            color: reached
                                ? _Palette.green
                                : Colors.white.withOpacity(0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation(accent),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _miniTag(
                              icon: Icons.straighten_rounded,
                              label: '${pedo.distanceKm.toStringAsFixed(2)} км',
                              color: _Palette.teal,
                            ),
                            const SizedBox(width: 6),
                            _miniTag(
                              icon: Icons.local_fire_department_rounded,
                              label: '${pedo.calories.round()} ккал',
                              color: _Palette.pink,
                            ),
                            const SizedBox(width: 6),
                            _miniTag(
                              icon: Icons.timer_outlined,
                              label: '${pedo.activeMinutes} мин',
                              color: _Palette.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _stepsRing(pct, accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepsRing(double pct, Color accent) {
    return SizedBox(
      width: 86, height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 86, height: 86,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: pct),
              duration: const Duration(milliseconds: 900),
              curve: _Spring.gentle,
              builder: (_, v, __) => CircularProgressIndicator(
                value: v,
                strokeWidth: 7,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_walk_rounded, color: accent, size: 16),
              const SizedBox(height: 2),
              Text(
                '${(pct * 100).round()}%',
                style: _T.caption2.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtNum(int n) {
    if (n >= 10000) {
      return '${(n / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    if (n >= 1000) {
      final s = n.toString();
      return '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}';
    }
    return '$n';
  }

  void _openPedometer(BuildContext context) {
    HapticFeedback.lightImpact();
    final pedo = context.read<PedometerProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: pedo,
          child: const PedometerScreen(isDark: true),
        ),
      ),
    );
  }


}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════
class _Badge {
  final String emoji;
  final String label;
  final Color color;
  const _Badge(this.emoji, this.label, this.color);
}

class _Insight {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  const _Insight(this.emoji, this.title, this.subtitle, this.color);
}

class _PR {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  const _PR(this.emoji, this.value, this.label, this.color);
}

class _Comparison {
  final String symbol;
  final String value;
  final Color color;
  const _Comparison(this.symbol, this.value, this.color);
}

class _DayData {
  final DateTime date;
  final int workouts;
  final double volume;
  final bool isToday;
  final bool isFuture;

  _DayData({
    required this.date,
    required this.workouts,
    required this.volume,
    required this.isToday,
    required this.isFuture,
  });
}

class _ConfettiParticle {
  final double xFrac;
  final double startY;
  final double vx;
  final double vy;
  final double rot0;
  final double rotV;
  final Color color;
  final double size;

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

// ═════════════════════════════════════════════════════════
//  PAINTERS (без изменений — они уже идеальны)
// ═════════════════════════════════════════════════════════
class _ConicBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double radius;
  _ConicBorderPainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(radius),
    );

    final shader = SweepGradient(
      transform: GradientRotation(progress * 2 * math.pi),
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(0.55),
        color.withOpacity(0.0),
        color.withOpacity(0.55),
        color.withOpacity(0.0),
      ],
      stops: const [0.0, 0.20, 0.5, 0.80, 1.0],
    ).createShader(rect);

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant _ConicBorderPainter old) =>
      old.progress != progress || old.color != color;
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

      final rot = p.rot0 + p.rotV * t;
      final alpha = (1 - t * 0.9).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          const Radius.circular(1.5),
        ),
        Paint()..color = p.color.withOpacity(alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..strokeWidth = 0.5;

    for (int i = 1; i <= 4; i++) {
      final y = size.height - (size.height * i / 4);
      double x = 0;
      const dash = 3.0;
      const gap = 5.0;
      while (x < size.width) {
        final endX = math.min(x + dash, size.width);
        canvas.drawLine(Offset(x, y), Offset(endX, y), paint);
        x += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}

class _TickRingPainter extends CustomPainter {
final double progress;
final Color tickColor;
final int tickCount;
_TickRingPainter({
required this.progress,
required this.tickColor,
this.tickCount = 60,
});

@override
void paint(Canvas canvas, Size size) {
final center = Offset(size.width / 2, size.height / 2);
final outer = size.width / 2;
final inner = outer - 10;
final step = 2 * math.pi / tickCount;
final filled = (tickCount * progress.clamp(0.0, 1.0)).round();

for (int i = 0; i < tickCount; i++) {
  final angle = -math.pi / 2 + step * i;
  final active = i < filled;
  final long = i % 5 == 0;

  final paint = Paint()
    ..color = active ? tickColor : tickColor.withOpacity(0.10)
    ..strokeWidth = long ? 2.2 : 1.2
    ..strokeCap = StrokeCap.round;

  canvas.drawLine(
    center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
    center +
        Offset(
          math.cos(angle) * (outer - (long ? 0 : 3)),
          math.sin(angle) * (outer - (long ? 0 : 3)),
        ),
    paint,
  );
}
}

@override
bool shouldRepaint(covariant _TickRingPainter old) =>
    old.progress != progress || old.tickColor != tickColor;
}

// ═════════════════════════════════════════════════════════
//  TRI RING
// ═════════════════════════════════════════════════════════
class _TriRingPainter extends CustomPainter {
  final double p1, p2, p3;
  final Color c1, c2, c3;
  _TriRingPainter({
    required this.p1,
    required this.p2,
    required this.p3,
    required this.c1,
    required this.c2,
    required this.c3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 13.0;
    const gap = 8.0;
    final r1 = size.width / 2 - stroke / 2 - 4;
    final r2 = r1 - stroke - gap;
    final r3 = r2 - stroke - gap;

    _drawRing(canvas, center, r1, p1, c1, stroke);
    _drawRing(canvas, center, r2, p2, c2, stroke);
    _drawRing(canvas, center, r3, p3, c3, stroke);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double progress,
      Color color, double stroke) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withOpacity(0.10),
    );

    if (progress <= 0) return;

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 2.4
        ..strokeCap = StrokeCap.round
        ..color = color.withOpacity(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    canvas.drawArc(
      rect,
      start,
      sweep * 0.12,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.35
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _TriRingPainter old) =>
      old.p1 != p1 || old.p2 != p2 || old.p3 != p3;
}

// ═════════════════════════════════════════════════════════
//  SPARKLES
// ═════════════════════════════════════════════════════════
class _SparklesPainter extends CustomPainter {
  final double progress;
  final Color color;
  _SparklesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const count = 10;

    for (int i = 0; i < count; i++) {
      final baseAngle = i * 2 * math.pi / count;
      final angle = baseAngle + progress * math.pi / 3;
      final rJitter = ((i * 37) % 100) / 100;
      final r = 128 + rJitter * 12;
      final pos = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      final phase = (progress * 2 * math.pi + i * 1.3) % (2 * math.pi);
      final pulse = (math.sin(phase) + 1) / 2;
      final radius = 0.9 + pulse * 1.6;
      final alpha = 0.20 + pulse * 0.55;

      canvas.drawCircle(
        pos,
        radius,
        Paint()..color = color.withOpacity(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter old) =>
      old.progress != progress || old.color != color;
}

// ═════════════════════════════════════════════════════════
//  SPARK PAINTER
// ═════════════════════════════════════════════════════════
class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparkPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxV = data.reduce(math.max);
    final minV = data.reduce(math.min);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    final stepX = size.width / (data.length - 1);
    final pts = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = stepX * i;
      final y =
          size.height - ((data[i] - minV) / range) * (size.height - 6) - 3;
      pts.add(Offset(x, y));
    }

    final fill = Path()..moveTo(0, size.height);
    for (final p in pts) {
      fill.lineTo(p.dx, p.dy);
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final cx = (prev.dx + cur.dx) / 2;
      line.cubicTo(cx, prev.dy, cx, cur.dy, cur.dx, cur.dy);
    }

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    canvas.drawCircle(pts.last, 2.5, Paint()..color = color);
    canvas.drawCircle(
      pts.last,
      5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withOpacity(0.4),
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.data != data || old.color != color;
}

// ═════════════════════════════════════════════════════════
//  COUNT-UP
// ═════════════════════════════════════════════════════════
class _CountUp extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final int decimals;
  const _CountUp({
    required this.value,
    this.style,
    this.decimals = 0,
  });

  @override
  State<_CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<_CountUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late double _from;
  late double _to;

  @override
  void initState() {
    super.initState();
    _from = 0;
    _to = widget.value;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _CountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = old.value;
      _to = widget.value;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // Мягкий spring вместо чистого easeOutCubic
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        final val = _from + (_to - _from) * t;
        final text = widget.decimals > 0
            ? val.toStringAsFixed(widget.decimals)
            : val.round().toString();
        return Text(text, style: widget.style);
      },
    );
  }
}

// ═════════════════════════════════════════════════════════
//  TAP SCALE — spring-физика нажатия, как в iOS
// ═════════════════════════════════════════════════════════
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
        // Немного глубже, чем было — 0.965 → 0.96, ощущение «пружины»
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: _Spring.bouncy,
        child: widget.child,
      ),
    );
  }
}