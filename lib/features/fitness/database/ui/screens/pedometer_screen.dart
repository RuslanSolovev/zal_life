import 'dart:math' as math;
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:zal_life/features/fitness/providers/pedometer_provider.dart';
import 'package:zal_life/features/nutrition/providers/nutrition_provider.dart';
import 'package:zal_life/features/fitness/database/ui/screens/journey_view.dart'
    show JourneyView;
import 'package:zal_life/features/fitness/database/ui/screens/activity_log_screen.dart'
    show ActivityLogScreen;

// ═══════════════════════════════════════════════════════════════════
//  Soft Pastel Light — Design System
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const peach = Color(0xFFFFB5A7);
  static const pink = Color(0xFFFFAFC8);
  static const mint = Color(0xFFA8DADC);
  static const lavender = Color(0xFFCDB4DB);
  static const yellow = Color(0xFFFFD6A5);
  static const sky = Color(0xFFA8D8EA);
  static const sage = Color(0xFFB5CBB7);

  static const peachSoft = Color(0xFFFFE9E1);
  static const pinkSoft = Color(0xFFFFE5EF);
  static const mintSoft = Color(0xFFE3F3F4);
  static const lavenderSoft = Color(0xFFF1E8F5);
  static const yellowSoft = Color(0xFFFFF2E2);
  static const skySoft = Color(0xFFE3F1F7);
  static const sageSoft = Color(0xFFE8F1E6);

  static const peachDeep = Color(0xFFE57154);
  static const pinkDeep = Color(0xFFD95C84);
  static const mintDeep = Color(0xFF398B95);
  static const lavenderDeep = Color(0xFF8A5DA5);
  static const yellowDeep = Color(0xFFD39838);
  static const skyDeep = Color(0xFF3E7A9C);
  static const sageDeep = Color(0xFF5C7E5E);

  static const bg = Color(0xFFFAF7F2);
  static const surface = Color(0xFFFFFFFF);
  static const elevated = Color(0xFFF3EEE6);

  static const text = Color(0xFF2B2823);
  static const textMuted = Color(0xFF8A8278);
  static const textSoft = Color(0xFFBFB7AB);

  static const divider = Color(0xFFEAE4DA);
}

class _Dark {
  static const bgTop = Color(0xFF1A1730);
  static const bgBottom = Color(0xFF0E0C1C);
  static const accent = Color(0xFFB69CFF);
  static const accentSoft = Color(0xFFD7C9FF);
  static const textHigh = Colors.white;
  static const textMid = Color(0xB3FFFFFF);
  static const textDim = Color(0x66FFFFFF);
}

class _T {
  static const title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );
  static const title3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
  );
  static const headline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05,
    height: 1.3,
  );
  static const caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.3,
  );
  static const overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
    height: 1.1,
  );
}

// ═══════════════════════════════════════════════════════════════════

class PedometerScreen extends StatefulWidget {
  final bool isDark;
  const PedometerScreen({super.key, this.isDark = true});

  @override
  State<PedometerScreen> createState() => _PedometerScreenState();
}

class _PedometerScreenState extends State<PedometerScreen>
    with TickerProviderStateMixin {
  bool _isMonthlyChart = false;

  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late ConfettiController _confettiController;

  int _knownLevel = 0;
  bool _levelBaselineSet = false;
  PedometerProvider? _provider;

  Color get _timeAccent {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return _P.yellowDeep;
    if (hour >= 12 && hour < 17) return _P.peachDeep;
    if (hour >= 17 && hour < 21) return _P.lavenderDeep;
    return _P.skyDeep;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<PedometerProvider>();
      _provider = p;
      _knownLevel = p.level;
      _levelBaselineSet = true;
      p.addListener(_onProviderUpdate);
      p.checkPermissionStatus();
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderUpdate);
    _pulseController.dispose();
    _shimmerController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onProviderUpdate() {
    if (!mounted || !_levelBaselineSet) return;
    final p = _provider;
    if (p == null) return;

    if (p.level > _knownLevel) {
      _knownLevel = p.level;
      _showLevelUpDialog(p.level);
      _confettiController.play();
    }

    final m = p.pendingMilestone;
    if (m != null) {
      _showMilestoneSnackbar(m);
      p.acknowledgeMilestone(m);
    }

    final newA = p.newAchievements;
    if (newA.isNotEmpty) {
      _showAchievementSnackbar(newA.last);
      p.acknowledgeAchievements();
    }
  }

  // ═════════════════════════════════════════════════════════
  //  JOURNAL NAVIGATION
  // ═════════════════════════════════════════════════════════
  void _openJournal(PedometerProvider pedo, {int initialTab = 0}) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityLogScreen(
          history: pedo.history,
          achievements: pedo.achievements,
          goal: pedo.goal,
          currentStreak: pedo.currentStreak,
          level: pedo.level,
          achievementPoints: pedo.achievementPoints,
          levelProgress: pedo.levelProgress,
          heightCm: pedo.heightCm,
          weightKg: pedo.weightKg,
          accentColor: _timeAccent,
          initialTab: initialTab,
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final pedo = context.watch<PedometerProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final accent = pedo.goalReached ? _P.sageDeep : _timeAccent;
    final waterToday = nutrition.getWaterForDate(DateTime.now());

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _P.bg,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _appBar(pedo)),
                if (pedo.isContinuousWalk)
                  SliverToBoxAdapter(child: _activeWalkBanner(pedo)),
                SliverToBoxAdapter(child: _heroMultiRings(pedo, accent)),
                SliverToBoxAdapter(child: _statTiles(pedo, accent)),
                SliverToBoxAdapter(child: _levelCard(pedo)),
                SliverToBoxAdapter(child: _achievementsMini(pedo)),
                SliverToBoxAdapter(child: _activityTimeCard(pedo)),
                SliverToBoxAdapter(child: _comparisonCard(pedo)),
                SliverToBoxAdapter(child: _monthlyForecastCard(pedo)),
                SliverToBoxAdapter(child: _personalRecordCard(pedo)),
                SliverToBoxAdapter(child: _weeklySummary(pedo)),
                SliverToBoxAdapter(child: _activityScoreCard(pedo)),
                if (pedo.steps > 3000 && waterToday < 1000)
                  SliverToBoxAdapter(child: _waterPrompt(nutrition)),
                SliverToBoxAdapter(child: _virtualWalkProgress(pedo)),
                SliverToBoxAdapter(child: _cadenceZones(pedo)),
                SliverToBoxAdapter(child: _calendarHeatmap(pedo)),
                SliverToBoxAdapter(child: _hourlyScroll(pedo)),
                SliverToBoxAdapter(child: _chartCard(pedo)),
                SliverToBoxAdapter(child: _questsSection(pedo)),
                SliverToBoxAdapter(child: _achievementsSection(pedo)),
                SliverToBoxAdapter(child: _goalCard(pedo)),
                if (pedo.permissionDenied)
                  SliverToBoxAdapter(child: _permissionCard(pedo)),
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 24,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                _P.peachDeep,
                _P.yellowDeep,
                _P.pinkDeep,
                _P.sageDeep,
                _P.skyDeep,
                _P.lavenderDeep,
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Soft card
  // ═════════════════════════════════════════════════════════
  Widget _softCard({
    required Widget child,
    Color? accent,
    EdgeInsets? padding,
    double radius = 22,
  }) {
    final a = accent ?? _P.peachDeep;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: a.withOpacity(0.14), width: 1),
        boxShadow: [
          BoxShadow(
            color: a.withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: -5,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  App bar
  // ═════════════════════════════════════════════════════════
  Widget _appBar(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _circleBtn(
            Icons.arrow_back_ios_new_rounded,
                () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'ТРЕКЕР АКТИВНОСТИ',
            style: _T.overline.copyWith(
              color: _P.textMuted,
              fontSize: 9,
              letterSpacing: 1.6,
            ),
          ),
          const Spacer(),
          _circleBtn(Icons.tune_rounded, () => _showCalibration(pedo)),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _P.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: _P.peachDeep.withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: _P.text, size: 17),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Active walk banner
  // ═════════════════════════════════════════════════════════
  Widget _activeWalkBanner(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_P.sageSoft, _P.mintSoft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.sageDeep.withOpacity(0.20), width: 1),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Transform.scale(
                scale: 1.0 + _pulseController.value * 0.15,
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: _P.sageDeep,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Активная прогулка',
              style: _T.caption.copyWith(
                color: _P.text,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: -0.1,
              ),
            ),
            const Spacer(),
            Text(
              '${pedo.walkDuration.inMinutes.toString().padLeft(2, '0')}:${(pedo.walkDuration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: _T.title3.copyWith(
                color: _P.sageDeep,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HERO — multi-ring + status pill
  // ═════════════════════════════════════════════════════════
  Widget _heroMultiRings(PedometerProvider pedo, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      child: _softCard(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        accent: accent,
        radius: 26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _walkingStatusPill(pedo, accent),
                const Spacer(),
                if (pedo.goalReached)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _P.sageSoft,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _P.sageDeep.withOpacity(0.25),
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 9)),
                        const SizedBox(width: 3),
                        Text(
                          'ЦЕЛЬ',
                          style: _T.caption2.copyWith(
                            color: _P.sageDeep,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutExpo,
                      builder: (_, v, __) => CustomPaint(
                        size: const Size(240, 240),
                        painter: _MultiRingPainter(
                          stepProgress: pedo.progress * v,
                          distanceProgress:
                          (pedo.distanceKm / 8.0).clamp(0.0, 1.0) * v,
                          calorieProgress:
                          (pedo.calories / 500.0).clamp(0.0, 1.0) * v,
                          activeProgress:
                          (pedo.activeMinutes / 30.0).clamp(0.0, 1.0) * v,
                          stepColor: accent,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_walk_rounded,
                            color: accent, size: 22),
                        const SizedBox(height: 6),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: pedo.steps.toDouble()),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Text(
                            v.round().toString(),
                            style: const TextStyle(
                              color: _P.text,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2.0,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'из ${pedo.goal}',
                          style: _T.caption2.copyWith(
                            color: _P.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _ringLegend(_P.peachDeep, '${pedo.steps}', 'шаги'),
                const SizedBox(width: 8),
                _ringLegend(
                  _P.skyDeep,
                  pedo.distanceKm.toStringAsFixed(2),
                  'км',
                ),
                const SizedBox(width: 8),
                _ringLegend(
                  _P.pinkDeep,
                  '${pedo.calories.round()}',
                  'ккал',
                ),
                const SizedBox(width: 8),
                _ringLegend(_P.lavenderDeep, '${pedo.activeMinutes}', 'мин'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _walkingStatusPill(PedometerProvider pedo, Color accent) {
    final active = pedo.isWalking;
    final color = active ? _P.sageDeep : _P.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: (active ? _P.sageSoft : _P.elevated),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? _P.sageDeep.withOpacity(0.20) : _P.divider,
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 6 + (active ? _pulseController.value * 2 : 0),
                height: 6 + (active ? _pulseController.value * 2 : 0),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'В ДВИЖЕНИИ' : 'СЕГОДНЯ',
            style: _T.overline.copyWith(
              color: color,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ringLegend(Color color, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15), width: 0.6),
        ),
        child: Column(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _T.caption.copyWith(
                color: _P.text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _T.caption2.copyWith(
                color: _P.textMuted,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Stat tiles
  // ═════════════════════════════════════════════════════════
  Widget _statTiles(PedometerProvider pedo, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _statTile(
              Icons.straighten_rounded,
              pedo.distanceKm.toStringAsFixed(2),
              'КМ',
              _P.skyDeep,
              _P.skySoft,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statTile(
              Icons.speed_rounded,
              '${pedo.cadence}',
              'ШАГ/МИН',
              _P.pinkDeep,
              _P.pinkSoft,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statTile(
              Icons.local_fire_department,
              '${pedo.currentStreak}',
              'СТРИК',
              accent,
              _softForDeep(accent),
            ),
          ),
        ],
      ),
    );
  }

  Color _softForDeep(Color deep) {
    if (deep == _P.skyDeep) return _P.skySoft;
    if (deep == _P.pinkDeep) return _P.pinkSoft;
    if (deep == _P.yellowDeep) return _P.yellowSoft;
    if (deep == _P.sageDeep) return _P.sageSoft;
    if (deep == _P.mintDeep) return _P.mintSoft;
    if (deep == _P.lavenderDeep) return _P.lavenderSoft;
    if (deep == _P.peachDeep) return _P.peachSoft;
    return _P.elevated;
  }

  Widget _statTile(
      IconData icon,
      String value,
      String label,
      Color accent,
      Color soft,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.14), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: -3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              color: _P.text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: _T.caption2.copyWith(
              color: _P.textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Level card
  // ═════════════════════════════════════════════════════════
  Widget _levelCard(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: () => _openJournal(pedo, initialTab: 1),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _P.lavenderDeep.withOpacity(0.14),
                Colors.white,
                _P.lavenderSoft.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _P.lavenderDeep.withOpacity(0.20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _P.lavenderDeep.withOpacity(0.10),
                blurRadius: 22,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.30),
                          blurRadius: 12,
                          spreadRadius: -4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${pedo.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'УРОВЕНЬ ${pedo.level}',
                          style: _T.overline.copyWith(
                            color: _P.lavenderDeep,
                            fontSize: 9,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${pedo.stepsToNextLevel} шагов до уровня ${pedo.level + 1}',
                          style: _T.caption.copyWith(
                            color: _P.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: _P.yellowDeep.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _P.yellowDeep.withOpacity(0.20),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      '${pedo.achievementPoints} AP',
                      style: _T.caption2.copyWith(
                        color: _P.yellowDeep,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: LinearProgressIndicator(
                  value: pedo.levelProgress,
                  minHeight: 7,
                  backgroundColor: _P.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF8B5CF6),
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
  //  Achievements mini
  // ═════════════════════════════════════════════════════════
  Widget _achievementsMini(PedometerProvider pedo) {
    final unlocked = pedo.achievements.where((a) => a.unlocked).length;
    final total = pedo.achievements.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () => _openJournal(pedo, initialTab: 1),
        child: _softCard(
          accent: _P.yellowDeep,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _P.yellowSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: _P.yellowDeep,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ДОСТИЖЕНИЯ',
                          style: _T.overline.copyWith(
                            color: _P.yellowDeep,
                            fontSize: 9,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Открыто $unlocked из $total',
                          style: _T.caption.copyWith(
                            color: _P.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _P.textMuted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _miniAchievement(
                    Icons.local_fire_department_rounded,
                    '${pedo.currentStreak}',
                    'Серия',
                    pedo.currentStreak >= 3,
                  ),
                  const SizedBox(width: 8),
                  _miniAchievement(
                    Icons.emoji_events_rounded,
                    _fmt(pedo.bestDaySteps),
                    'Рекорд',
                    pedo.bestDaySteps >= pedo.goal,
                  ),
                  const SizedBox(width: 8),
                  _miniAchievement(
                    Icons.flag_rounded,
                    '${pedo.history.where((h) => h.steps >= pedo.goal).length}',
                    'Цели',
                    pedo.history.where((h) => h.steps >= pedo.goal).length >= 3,
                  ),
                  const SizedBox(width: 8),
                  _miniAchievement(
                    Icons.map_rounded,
                    pedo.totalDistanceKmAllTime.toStringAsFixed(0),
                    'Км',
                    pedo.totalDistanceKmAllTime >= 5,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniAchievement(
      IconData icon, String value, String label, bool unlocked) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
        decoration: BoxDecoration(
          color: unlocked ? _P.yellowSoft.withOpacity(0.7) : _P.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unlocked ? _P.yellowDeep.withOpacity(0.20) : _P.divider,
            width: 0.6,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: unlocked ? _P.yellowDeep : _P.textSoft,
              size: 18,
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unlocked ? _P.text : _P.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: _T.caption2.copyWith(
                color: _P.textMuted,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Activity time card
  // ═════════════════════════════════════════════════════════
  Widget _activityTimeCard(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () => _openJournal(pedo, initialTab: 0),
        child: _softCard(
          accent: _P.sageDeep,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _P.sageSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timer_rounded,
                  color: _P.sageDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'АКТИВНОЕ ВРЕМЯ',
                      style: _T.overline.copyWith(
                        color: _P.sageDeep,
                        fontSize: 9,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pedo.activeMinutes} мин сегодня',
                      style: _T.caption.copyWith(
                        color: _P.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _P.sageSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'История',
                  style: _T.caption2.copyWith(
                    color: _P.sageDeep,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: _P.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Comparison card
  // ═════════════════════════════════════════════════════════
  Widget _comparisonCard(PedometerProvider pedo) {
    final diff = pedo.weekDiffPercent;
    final positive = diff >= 0;
    final color = positive ? _P.sageDeep : _P.pinkDeep;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: _softCard(
        accent: color,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    positive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'НЕДЕЛЯ VS ПРОШЛАЯ',
                        style: _T.overline.copyWith(
                          color: color,
                          fontSize: 9,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Сравнение активности',
                        style: _T.caption2.copyWith(
                          color: _P.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${positive ? '+' : ''}$diff%',
                    style: _T.caption2.copyWith(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _comparisonValue(
                    'Эта неделя',
                    '${pedo.weeklySteps}',
                    _P.peachDeep,
                  ),
                ),
                Container(width: 1, height: 40, color: _P.divider),
                Expanded(
                  child: _comparisonValue(
                    'Прошлая',
                    '${pedo.lastWeekSteps}',
                    _P.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonValue(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _P.text,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: _T.caption2.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Monthly forecast
  // ═════════════════════════════════════════════════════════
  Widget _monthlyForecastCard(PedometerProvider pedo) {
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: _softCard(
        accent: _P.skyDeep,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _P.skySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: _P.skyDeep,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ПРОГНОЗ НА МЕСЯЦ',
                    style: _T.overline.copyWith(
                      color: _P.skyDeep,
                      fontSize: 9,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pedo.monthlyProjection.toStringAsFixed(0),
                        style: const TextStyle(
                          color: _P.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'км',
                          style: _T.caption2.copyWith(
                            color: _P.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'при текущем темпе · $daysLeft дн. осталось',
                    style: _T.caption2.copyWith(
                      color: _P.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Personal record
  // ═════════════════════════════════════════════════════════
  Widget _personalRecordCard(PedometerProvider pedo) {
    if (pedo.bestDaySteps == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () => _openJournal(pedo, initialTab: 2),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _P.yellowSoft,
                Colors.white,
                _P.yellowSoft.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _P.yellowDeep.withOpacity(0.20),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_P.yellow, _P.yellowDeep],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ЛИЧНЫЙ РЕКОРД',
                      style: _T.overline.copyWith(
                        color: _P.yellowDeep,
                        fontSize: 9,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_fmt(pedo.bestDaySteps)} шагов за день',
                      style: _T.caption.copyWith(
                        color: _P.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _P.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Activity score
  // ═════════════════════════════════════════════════════════
  Widget _activityScoreCard(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: _softCard(
        accent: _timeAccent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ИНДЕКС АКТИВНОСТИ',
                  style: _T.overline.copyWith(
                    color: _P.textMuted,
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${pedo.activityScore}/100',
                  style: _T.caption.copyWith(
                    color: _timeAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pedo.activityScore / 100,
                minHeight: 7,
                backgroundColor: _P.divider,
                valueColor: AlwaysStoppedAnimation(_timeAccent),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat(
                    '🔥', '${pedo.calories.round()}', 'ККАЛ', _P.pinkDeep),
                _miniStat(
                    '⏱', '${pedo.activeMinutes}', 'МИН', _P.lavenderDeep),
                _miniStat(
                  '🚀',
                  pedo.averageSpeed.toStringAsFixed(1),
                  'КМ/Ч',
                  _P.skyDeep,
                ),
                _miniStat(
                  '🏆',
                  '${pedo.bestDaySteps}',
                  'РЕКОРД',
                  _P.yellowDeep,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: _P.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: _T.caption2.copyWith(
            color: _P.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Weekly summary
  // ═════════════════════════════════════════════════════════
  Widget _weeklySummary(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: _softCard(
        accent: _P.lavenderDeep,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _P.lavenderSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.date_range_rounded,
                color: _P.lavenderDeep,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ИТОГИ ЗА 7 ДНЕЙ',
                    style: _T.overline.copyWith(
                      color: _P.textMuted,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${pedo.weeklySteps} шагов',
                        style: _T.caption.copyWith(
                          color: _P.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '·',
                        style: TextStyle(
                          color: _P.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${pedo.weeklyDistance.toStringAsFixed(1)} км',
                        style: _T.caption.copyWith(
                          color: _P.lavenderDeep,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Water prompt
  // ═════════════════════════════════════════════════════════
  Widget _waterPrompt(NutritionProvider nutrition) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: _softCard(
        accent: _P.skyDeep,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _P.skySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('💧', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ты прошёл 3000 шагов.\nПора выпить стакан воды!',
                style: _T.caption.copyWith(
                  color: _P.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                nutrition.addWater(250);
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: _P.skyDeep,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '+250',
                  style: _T.caption2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
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
  //  Virtual walk — DARK CARD
  // ═════════════════════════════════════════════════════════
  Widget _virtualWalkProgress(PedometerProvider pedo) {
    const double totalRoute = 9300;
    final walked = pedo.totalDistanceKmAllTime;
    final progress = (walked / totalRoute).clamp(0.0, 1.0);
    final remaining = (totalRoute - walked).clamp(0.0, totalRoute);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JourneyView(
                walkedKm: walked,
                totalSteps: pedo.totalStepsAllTime,
                onBack: () => Navigator.pop(context),
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_Dark.bgTop, _Dark.bgBottom],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _Dark.accent.withOpacity(0.20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _Dark.accent.withOpacity(0.18),
                blurRadius: 26,
                spreadRadius: -8,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _Dark.accent.withOpacity(0.18),
                        _Dark.accent.withOpacity(0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _Dark.accent.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: _Dark.accent.withOpacity(0.30),
                              width: 0.8,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🚂',
                              style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ТРАНССИБ',
                                style: _T.overline.copyWith(
                                  color: _Dark.accent,
                                  fontSize: 9,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Москва → Владивосток',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _T.caption.copyWith(
                                  color: _Dark.textHigh,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _Dark.accent.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _Dark.accent.withOpacity(0.30),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: _T.caption2.copyWith(
                              color: _Dark.accentSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Text(
                        'Исследуй 30 городов России',
                        style: _T.caption2.copyWith(
                          color: _Dark.textMid,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 32,
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          final w = constraints.maxWidth;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 14,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _Dark.accent.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: 14,
                                width: w * progress,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        _Dark.accent,
                                        _Dark.accentSoft
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                        _Dark.accent.withOpacity(0.5),
                                        blurRadius: 10,
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: (w * progress).clamp(0.0, w - 28),
                                top: -2,
                                child: Text(
                                  '🚂',
                                  style: TextStyle(
                                    fontSize: 22,
                                    shadows: [
                                      Shadow(
                                        color:
                                        _Dark.accent.withOpacity(0.6),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${walked.toStringAsFixed(1)} км пройдено',
                          style: _T.caption2.copyWith(
                            color: _Dark.textHigh,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${remaining.toStringAsFixed(0)} км до цели',
                          style: _T.caption2.copyWith(
                            color: _Dark.textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  // ═════════════════════════════════════════════════════════
  //  Cadence zones
  // ═════════════════════════════════════════════════════════
  Widget _cadenceZones(PedometerProvider pedo) {
    final z1 = pedo.zone1Minutes;
    final z2 = pedo.zone2Minutes;
    final z3 = pedo.zone3Minutes;
    final total = z1 + z2 + z3;
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: _softCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ЗОНЫ ИНТЕНСИВНОСТИ',
              style: _T.overline.copyWith(
                color: _P.textMuted,
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            _zoneRow('🐢 Прогулочная', '< 100 шаг/мин', z1, _P.skyDeep,
                _P.skySoft),
            const SizedBox(height: 11),
            _zoneRow('🚶 Активная', '100-120 шаг/мин', z2, _P.yellowDeep,
                _P.yellowSoft),
            const SizedBox(height: 11),
            _zoneRow('🏃 Быстрая', '> 120 шаг/мин', z3, _P.pinkDeep,
                _P.pinkSoft),
          ],
        ),
      ),
    );
  }

  Widget _zoneRow(
      String title,
      String subtitle,
      double minutes,
      Color accent,
      Color soft,
      ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: _T.caption.copyWith(
                  color: _P.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: _T.caption2.copyWith(
                  color: _P.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '${minutes.round()} мин',
            style: _T.caption2.copyWith(
              color: accent,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Calendar heatmap
  // ═════════════════════════════════════════════════════════
  Widget _calendarHeatmap(PedometerProvider pedo) {
    List<StepDay> data;
    if (pedo.history.length >= 28) {
      data = pedo.history.sublist(pedo.history.length - 28);
    } else {
      data = List.generate(28, (i) {
        final d = DateTime.now().subtract(Duration(days: 27 - i));
        final existing = pedo.history.firstWhere(
              (h) =>
          h.date.year == d.year &&
              h.date.month == d.month &&
              h.date.day == d.day,
          orElse: () => StepDay(date: d, steps: 0),
        );
        return existing;
      });
    }

    const daysOfWeek = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: _softCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Text(
                  'КАЛЕНДАРЬ АКТИВНОСТИ',
                  style: _T.overline.copyWith(
                    color: _P.textMuted,
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: daysOfWeek
                  .map(
                    (day) => Text(
                  day,
                  style: _T.caption2.copyWith(
                    color: _P.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 7,
                mainAxisSpacing: 7,
                childAspectRatio: 1,
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final day = data[index];
                final ratio = day.steps / pedo.goal;
                Color cellColor;
                Color borderColor = Colors.transparent;

                if (ratio >= 1.5) {
                  cellColor = _P.pink;
                } else if (ratio >= 1.0) {
                  cellColor = _P.sage;
                } else if (ratio >= 0.5) {
                  cellColor = _P.sage.withOpacity(0.5);
                } else if (ratio > 0) {
                  cellColor = _P.sage.withOpacity(0.20);
                } else {
                  cellColor = _P.elevated;
                }

                if (index == 27) borderColor = _P.text;

                return Tooltip(
                  message:
                  '${day.date.day}.${day.date.month} — ${day.steps} шагов',
                  triggerMode: TooltipTriggerMode.tap,
                  decoration: BoxDecoration(
                    color: _P.text,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _legendBox(_P.elevated, '0'),
                _legendBox(_P.sage.withOpacity(0.20), 'Мало'),
                _legendBox(_P.sage.withOpacity(0.5), '50%'),
                _legendBox(_P.sage, '100%'),
                _legendBox(_P.pink, '150%+'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendBox(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: _T.caption2.copyWith(
              color: _P.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Hourly scroll
  // ═════════════════════════════════════════════════════════
  Widget _hourlyScroll(PedometerProvider pedo) {
    final sortedHours = pedo.hourlySteps.keys.toList()..sort();
    if (sortedHours.isEmpty) return const SizedBox.shrink();

    final maxSteps =
    sortedHours.map((h) => pedo.hourlySteps[h] ?? 0).reduce(math.max);

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 0),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: sortedHours.length,
          itemBuilder: (context, index) {
            final hour = sortedHours[index];
            final steps = pedo.hourlySteps[hour] ?? 0;
            final heightFactor = maxSteps > 0 ? steps / maxSteps : 0.0;

            return Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _P.divider, width: 0.8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 24,
                    height: 40 * heightFactor + 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          _timeAccent.withOpacity(0.85),
                          _timeAccent.withOpacity(0.35),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '$hour:00',
                    style: _T.caption2.copyWith(
                      color: _P.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$steps',
                    style: const TextStyle(
                      color: _P.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Chart
  // ═════════════════════════════════════════════════════════
  Widget _chartCard(PedometerProvider pedo) {
    final data = _isMonthlyChart
        ? pedo.history
        : (pedo.history.length >= 7
        ? pedo.history.sublist(pedo.history.length - 7)
        : pedo.history);

    final safeData = data.isEmpty
        ? List.generate(
      7,
          (i) => StepDay(
        date: DateTime.now().subtract(Duration(days: 6 - i)),
        steps: 0,
      ),
    )
        : data;

    final maxData = safeData.fold<double>(
      0,
          (m, d) => d.steps > m ? d.steps.toDouble() : m,
    );
    final maxY = math.max(maxData, pedo.goal.toDouble()) * 1.2;
    final spots = List.generate(
      safeData.length,
          (i) => FlSpot(i.toDouble(), safeData[i].steps.toDouble()),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: _softCard(
        accent: _timeAccent,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _timeAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: const Text('📈', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Text(
                  'ПУЛЬС НЕДЕЛИ',
                  style: _T.overline.copyWith(
                    color: _timeAccent,
                    fontSize: 10,
                    letterSpacing: 1.3,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      setState(() => _isMonthlyChart = !_isMonthlyChart),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _P.elevated,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _P.divider, width: 0.6),
                    ),
                    child: Text(
                      _isMonthlyChart ? '7 дней' : '30 дней',
                      style: _T.caption2.copyWith(
                        color: _P.text,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 170,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (safeData.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => _P.text,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final d = safeData[spot.x.toInt()];
                          return LineTooltipItem(
                            '${d.steps} шагов\n${d.date.day}.${d.date.month}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: pedo.goal.toDouble(),
                        color: _P.sageDeep.withOpacity(0.35),
                        strokeWidth: 1.4,
                        dashArray: [6, 6],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: _T.caption2.copyWith(
                            color: _P.sageDeep,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                          labelResolver: (_) => 'ЦЕЛЬ',
                        ),
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: _isMonthlyChart ? 5 : 1,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= safeData.length) {
                            return const SizedBox.shrink();
                          }
                          final d = safeData[i].date;
                          final text = _isMonthlyChart
                              ? '${d.day}'
                              : [
                            'ПН',
                            'ВТ',
                            'СР',
                            'ЧТ',
                            'ПТ',
                            'СБ',
                            'ВС'
                          ][d.weekday - 1];
                          final isLast = i == safeData.length - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              text,
                              style: TextStyle(
                                color:
                                isLast ? _timeAccent : _P.textMuted,
                                fontSize: 9.5,
                                fontWeight: isLast
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: _P.divider,
                      strokeWidth: 0.6,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.4,
                      barWidth: 3.2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter:
                            (spot, percent, barData, index) {
                          final isLast = index == safeData.length - 1;
                          return FlDotCirclePainter(
                            radius: isLast ? 4.5 : 3.5,
                            color: isLast ? _timeAccent : Colors.white,
                            strokeWidth: 2,
                            strokeColor: _timeAccent,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _timeAccent.withOpacity(0.22),
                            _timeAccent.withOpacity(0.0),
                          ],
                        ),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          _timeAccent.withOpacity(0.55),
                          _timeAccent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
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

  // ═════════════════════════════════════════════════════════
  //  Quests
  // ═════════════════════════════════════════════════════════
  Widget _questsSection(PedometerProvider pedo) {
    final quests = pedo.quests;
    if (quests.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'ЕЖЕДНЕВНЫЕ КВЕСТЫ',
                  style: _T.overline.copyWith(
                    color: _P.textMuted,
                    fontSize: 9,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...quests.map(
                (q) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: q.isCompleted
                        ? _P.sageDeep.withOpacity(0.25)
                        : _P.divider,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: q.isCompleted
                          ? _P.sageDeep.withOpacity(0.10)
                          : _P.peachDeep.withOpacity(0.03),
                      blurRadius: 12,
                      spreadRadius: -4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: q.isCompleted ? _P.sageSoft : _P.elevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        q.isCompleted
                            ? Icons.check_rounded
                            : Icons.flag_rounded,
                        color: q.isCompleted ? _P.sageDeep : _P.textMuted,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.title,
                            style: _T.caption.copyWith(
                              color: q.isCompleted
                                  ? _P.textMuted
                                  : _P.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              decoration: q.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            q.subtitle,
                            style: _T.caption2.copyWith(
                              color: _P.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!q.isCompleted) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: q.progress,
                                minHeight: 5,
                                backgroundColor: _P.divider,
                                valueColor:
                                AlwaysStoppedAnimation(_timeAccent),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!q.isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          '${(q.progress * 100).round()}%',
                          style: TextStyle(
                            color: _timeAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Achievements — shimmer row
  // ═════════════════════════════════════════════════════════
  Widget _achievementsSection(PedometerProvider pedo) {
    final achievements = pedo.achievements;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'ДОСТИЖЕНИЯ',
                  style: _T.overline.copyWith(
                    color: _P.textMuted,
                    fontSize: 9,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 118,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final a = achievements[index];
                return Container(
                  width: 96,
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: a.unlocked
                        ? const LinearGradient(
                      colors: [_P.yellowSoft, _P.peachSoft],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: a.unlocked ? null : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: a.unlocked
                          ? _P.yellowDeep.withOpacity(0.30)
                          : _P.divider,
                      width: 1,
                    ),
                    boxShadow: a.unlocked
                        ? [
                      BoxShadow(
                        color: _P.yellowDeep.withOpacity(0.15),
                        blurRadius: 14,
                        spreadRadius: -4,
                        offset: const Offset(0, 5),
                      ),
                    ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            a.emoji,
                            style: TextStyle(
                              fontSize: 28,
                              color: a.unlocked ? null : _P.textSoft,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            a.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _T.caption2.copyWith(
                              color: a.unlocked ? _P.text : _P.textSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.1,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      if (a.unlocked)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedBuilder(
                              animation: _shimmerController,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  widthFactor: 0.5,
                                  child: Transform.translate(
                                    offset: Offset(
                                      (_shimmerController.value * 3 - 1.5) *
                                          100,
                                      0,
                                    ),
                                    child: Transform.rotate(
                                      angle: math.pi / 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withOpacity(0.0),
                                              Colors.white.withOpacity(0.35),
                                              Colors.white.withOpacity(0.0),
                                            ],
                                          ),
                                        ),
                                      ),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Goal card
  // ═════════════════════════════════════════════════════════
  Widget _goalCard(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: _softCard(
        accent: _timeAccent,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _timeAccent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.flag_rounded, color: _timeAccent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ДНЕВНАЯ ЦЕЛЬ',
                    style: _T.overline.copyWith(
                      color: _P.textMuted,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pedo.goal} шагов',
                    style: _T.title3.copyWith(
                      color: _P.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _editGoal(pedo),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: _timeAccent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: _timeAccent.withOpacity(0.20),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  'ИЗМЕНИТЬ',
                  style: _T.caption2.copyWith(
                    color: _timeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionCard(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _softCard(
        accent: _P.pinkDeep,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _P.pinkSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.shield_outlined,
                    color: _P.pinkDeep,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Нет доступа к датчику движения',
                    style: _T.caption.copyWith(
                      color: _P.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => pedo.openSystemSettings(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _P.pinkSoft,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: _P.pinkDeep.withOpacity(0.20),
                          width: 0.6,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'НАСТРОЙКИ',
                        style: _T.caption2.copyWith(
                          color: _P.pinkDeep,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => pedo.requestBatteryOptimization(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _P.yellowSoft,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: _P.yellowDeep.withOpacity(0.20),
                          width: 0.6,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'БАТАРЕЯ',
                        style: _T.caption2.copyWith(
                          color: _P.yellowDeep,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => pedo.retryPermission(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _P.elevated,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ПОВТОРИТЬ',
                        style: _T.caption2.copyWith(
                          color: _P.text,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
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
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Snackbars / Dialogs
  // ═════════════════════════════════════════════════════════
  void _showMilestoneSnackbar(int milestone) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _P.yellowDeep.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: _P.yellowDeep,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ВЕХА ДНЯ',
                    style: _T.overline.copyWith(
                      color: _P.yellow,
                      fontSize: 9,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Достигнуто ${_fmt(milestone)} шагов 🎉',
                    style: _T.caption.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _P.text,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  void _showAchievementSnackbar(Achievement a) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _P.yellowDeep.withOpacity(0.18),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(a.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ДОСТИЖЕНИЕ',
                    style: _T.overline.copyWith(
                      color: _P.yellow,
                      fontSize: 9,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    a.title,
                    style: _T.caption.copyWith(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    a.description,
                    style: _T.caption2.copyWith(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _P.text,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  void _showLevelUpDialog(int level) {
    HapticFeedback.heavyImpact();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.45),
                    blurRadius: 35,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'УРОВЕНЬ ПОВЫШЕН',
                    style: _T.overline.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 68,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Продолжить',
                      style: _T.caption.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Dialogs
  // ═════════════════════════════════════════════════════════
  Future<void> _editGoal(PedometerProvider pedo) async {
    final ctrl = TextEditingController(text: pedo.goal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Дневная цель',
          style: _T.title3.copyWith(color: _P.text, letterSpacing: -0.5),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: _T.headline.copyWith(
            color: _P.text,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            suffixText: 'шагов',
            suffixStyle:
            _T.caption.copyWith(color: _P.textMuted, fontSize: 13),
            filled: true,
            fillColor: _P.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _P.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _timeAccent, width: 1.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Отмена',
              style: _T.caption.copyWith(
                color: _P.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v >= 100) Navigator.pop(ctx, v);
            },
            child: Text(
              'Сохранить',
              style: _T.caption.copyWith(
                color: _timeAccent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
    if (result != null) await pedo.setGoal(result);
  }

  Future<void> _showCalibration(PedometerProvider pedo) async {
    final hCtrl =
    TextEditingController(text: pedo.heightCm.round().toString());
    final wCtrl =
    TextEditingController(text: pedo.weightKg.round().toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Калибровка',
          style: _T.title3.copyWith(color: _P.text, letterSpacing: -0.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hCtrl,
              keyboardType: TextInputType.number,
              style: _T.headline.copyWith(
                color: _P.text,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: 'Рост (см)',
                labelStyle:
                _T.caption.copyWith(color: _P.textMuted, fontSize: 12),
                filled: true,
                fillColor: _P.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _P.divider, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _timeAccent, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: wCtrl,
              keyboardType: TextInputType.number,
              style: _T.headline.copyWith(
                color: _P.text,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: 'Вес (кг)',
                labelStyle:
                _T.caption.copyWith(color: _P.textMuted, fontSize: 12),
                filled: true,
                fillColor: _P.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _P.divider, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _timeAccent, width: 1.4),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Отмена',
              style: _T.caption.copyWith(
                color: _P.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final h = double.tryParse(hCtrl.text);
              final w = double.tryParse(wCtrl.text);
              if (h != null && w != null && h > 50 && w > 20) {
                pedo.setCalibration(h, w);
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'Сохранить',
              style: _T.caption.copyWith(
                color: _timeAccent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Utility
  // ═════════════════════════════════════════════════════════
  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MULTI-RING PAINTER
// ═══════════════════════════════════════════════════════════════════
class _MultiRingPainter extends CustomPainter {
  final double stepProgress;
  final double distanceProgress;
  final double calorieProgress;
  final double activeProgress;
  final Color stepColor;

  _MultiRingPainter({
    required this.stepProgress,
    required this.distanceProgress,
    required this.calorieProgress,
    required this.activeProgress,
    required this.stepColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    _drawRing(canvas, center, 104, 11, stepProgress, stepColor, 0.10);
    _drawRing(
      canvas,
      center,
      84,
      11,
      distanceProgress,
      const Color(0xFF3E7A9C),
      0.12,
    );
    _drawRing(
      canvas,
      center,
      64,
      11,
      calorieProgress,
      const Color(0xFFD95C84),
      0.14,
    );
    _drawRing(
      canvas,
      center,
      44,
      11,
      activeProgress,
      const Color(0xFF8A5DA5),
      0.16,
    );
  }

  void _drawRing(
      Canvas canvas,
      Offset center,
      double radius,
      double stroke,
      double progress,
      Color color,
      double trackOpacity,
      ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withOpacity(trackOpacity),
    );

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.6
        ..strokeCap = StrokeCap.round
        ..color = color.withOpacity(0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * 0.08,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.38
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _MultiRingPainter old) =>
      old.stepProgress != stepProgress ||
          old.distanceProgress != distanceProgress ||
          old.calorieProgress != calorieProgress ||
          old.activeProgress != activeProgress;
}