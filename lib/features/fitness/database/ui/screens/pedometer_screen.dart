// features/fitness/database/ui/screens/pedometer_screen.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:zal_life/features/fitness/providers/pedometer_provider.dart';
import 'package:zal_life/features/nutrition/providers/nutrition_provider.dart';
import 'package:zal_life/features/fitness/database/ui/screens/journey_view.dart'
    show JourneyView;
import 'package:zal_life/features/fitness/database/ui/screens/activity_log_screen.dart'
    show ActivityLogScreen;

// ═══════════════════════════════════════════════════════════════════
//  Unified design tokens
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF7C818A);
  static const divider = Color(0xFFE9EBEF);
  static const elevated = Color(0xFFF0F1F4);

  static const peachSoft = Color(0xFFFBEDE4);
  static const peachDeep = Color(0xFFEF9563);
  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF6C9E88);
  static const skySoft = Color(0xFFE8EFF8);
  static const skyDeep = Color(0xFF7E9DC6);
  static const yellowSoft = Color(0xFFFDF5E6);
  static const yellowDeep = Color(0xFFE0B054);
  static const pinkSoft = Color(0xFFFCF0F2);
  static const pinkDeep = Color(0xFFD17A8F);
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF9381BB);
}

class _Hero {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const accent = Color(0xFFEF9563);
  static const textHigh = Colors.white;
  static const textLow = Color(0xFFA4A6AA);
}

class _Dark {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const accent = Color(0xFF9381BB);
  static const accentSoft = Color(0xFFB5A5D5);
  static const textHigh = Colors.white;
  static const textMid = Color(0xB3FFFFFF);
  static const textDim = Color(0x66FFFFFF);
}

class _T {
  static final title2 = GoogleFonts.inter(
      fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: _P.text);
  static final title3 = GoogleFonts.inter(
      fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.4, color: _P.text);
  static final headline = GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, color: _P.text);
  static final body = GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, color: _P.textMuted);
  static final caption = GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
  static final caption2 = GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w500, color: _P.textMuted);
  static final overline = GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _P.textMuted);
}

const double _padH = 14;

/// Rank titles by level
String _rankForLevel(int level) {
  if (level <= 1) return 'Новичок';
  if (level <= 3) return 'Ходок';
  if (level <= 6) return 'Атлет';
  if (level <= 10) return 'Спортсмен';
  if (level <= 20) return 'Профи';
  return 'Легенда';
}

// ═══════════════════════════════════════════════════════════════════
//  SCREEN
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
  bool _reduceMotion = false;

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
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderUpdate);
    _pulseController.dispose();
    _shimmerController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Duration _dur(int ms) =>
      _reduceMotion ? Duration.zero : Duration(milliseconds: ms);

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
  //  BUILD — grouped into 5 visual sections
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final pedo = context.watch<PedometerProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final accent = pedo.goalReached ? _P.greenDeep : _timeAccent;
    final waterToday = nutrition.getWaterForDate(DateTime.now());

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _P.bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _hero(pedo, accent)),
              if (pedo.isContinuousWalk)
                SliverToBoxAdapter(child: _activeWalkBanner(pedo)),

              // ─── СЕГОДНЯ ───
              _sectionLabel('СЕГОДНЯ', Icons.wb_sunny_outlined),
              SliverToBoxAdapter(child: _statTiles(pedo, accent)),
              SliverToBoxAdapter(child: _activityTimeCard(pedo)),
              SliverToBoxAdapter(child: _goalCard(pedo)),
              if (pedo.steps > 3000 && waterToday < 1000)
                SliverToBoxAdapter(child: _waterPrompt(nutrition)),

              // ─── ПРОГРЕСС ───
              _sectionLabel('ПРОГРЕСС', Icons.trending_up_rounded),
              SliverToBoxAdapter(child: _levelCard(pedo)),
              SliverToBoxAdapter(child: _achievementsMini(pedo)),
              SliverToBoxAdapter(child: _comparisonCard(pedo)),
              SliverToBoxAdapter(child: _monthlyForecastCard(pedo)),
              SliverToBoxAdapter(child: _personalRecordCard(pedo)),
              SliverToBoxAdapter(child: _weeklySummary(pedo)),
              SliverToBoxAdapter(child: _activityScoreCard(pedo)),

              // ─── ПУТЬ ───
              _sectionLabel('ПУТЬ', Icons.route_rounded),
              SliverToBoxAdapter(child: _virtualWalkProgress(pedo)),

              // ─── ДЕТАЛИ ───
              _sectionLabel('ДЕТАЛИ', Icons.insights_rounded),
              SliverToBoxAdapter(child: _cadenceZones(pedo)),
              SliverToBoxAdapter(child: _calendarHeatmap(pedo)),
              SliverToBoxAdapter(child: _hourlyScroll(pedo)),
              SliverToBoxAdapter(child: _chartCard(pedo)),

              // ─── НАГРАДЫ ───
              _sectionLabel('НАГРАДЫ', Icons.emoji_events_outlined),
              SliverToBoxAdapter(child: _questsSection(pedo)),
              SliverToBoxAdapter(child: _achievementsSection(pedo)),

              if (pedo.permissionDenied)
                SliverToBoxAdapter(child: _permissionCard(pedo)),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
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
                _P.greenDeep,
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
  //  SECTION LABEL — compact divider between groups
  // ═════════════════════════════════════════════════════════
  Widget _sectionLabel(String text, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_padH, 26, _padH, 10),
        child: Row(
          children: [
            Icon(icon, size: 13, color: _P.textMuted),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _P.text,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 1, color: _P.divider)),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  DARK HERO
  // ═════════════════════════════════════════════════════════
  Widget _hero(PedometerProvider pedo, Color accent) {
    final remaining = (pedo.goal - pedo.steps).clamp(0, pedo.goal);
    final goalPct = (pedo.progress * 100).round();

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Hero.bgTop, _Hero.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 40,
              left: -20,
              child: IgnorePointer(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withOpacity(0.20),
                        accent.withOpacity(0.0)
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _darkCircleBtn(Icons.arrow_back_ios_new_rounded,
                                () => Navigator.pop(context)),
                        const Spacer(),
                        Text(
                          'ТРЕКЕР АКТИВНОСТИ',
                          style: GoogleFonts.inter(
                            color: _Hero.textLow,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const Spacer(),
                        _darkCircleBtn(
                            Icons.tune_rounded, () => _showCalibration(pedo)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _darkStatusPill(pedo),
                        const Spacer(),
                        if (pedo.currentStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _Hero.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 5),
                                Text(
                                  '${pedo.currentStreak}',
                                  style: GoogleFonts.inter(
                                    color: _Hero.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: _dur(1400),
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
                                  tween: Tween(
                                      begin: 0.0, end: pedo.steps.toDouble()),
                                  duration: _dur(1000),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, v, __) => Text(
                                    v.round().toString(),
                                    style: GoogleFonts.inter(
                                      color: _Hero.textHigh,
                                      fontSize: 44,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -2.0,
                                      height: 1,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'из ${pedo.goal} · $goalPct%',
                                  style: GoogleFonts.inter(
                                    color: _Hero.textLow,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Remaining chip
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(100),
                        border:
                        Border.all(color: Colors.white.withOpacity(0.10)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pedo.goalReached
                                ? Icons.check_circle_rounded
                                : Icons.flag_outlined,
                            size: 12,
                            color: pedo.goalReached ? _P.greenDeep : _Hero.textLow,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pedo.goalReached
                                ? 'Цель дня достигнута'
                                : 'Ещё ${_fmt(remaining)} шагов до цели',
                            style: GoogleFonts.inter(
                              color: pedo.goalReached ? _P.greenSoft : _Hero.textLow,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _darkLegend(_P.peachDeep, '${pedo.steps}', 'шаги'),
                        const SizedBox(width: 8),
                        _darkLegend(_P.skyDeep,
                            pedo.distanceKm.toStringAsFixed(2), 'км'),
                        const SizedBox(width: 8),
                        _darkLegend(_P.pinkDeep, '${pedo.calories.round()}',
                            'ккал'),
                        const SizedBox(width: 8),
                        _darkLegend(_P.lavenderDeep,
                            '${pedo.activeMinutes}', 'мин'),
                      ],
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

  Widget _darkCircleBtn(IconData icon, VoidCallback onTap) {
    return _Press(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _darkStatusPill(PedometerProvider pedo) {
    final active = pedo.isWalking;
    final color = active ? _Hero.accent : _Hero.textLow;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6 + (active ? _pulseController.value * 2 : 0),
              height: 6 + (active ? _pulseController.value * 2 : 0),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: active
                    ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              active ? 'В ДВИЖЕНИИ' : 'СЕГОДНЯ',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _darkLegend(Color color, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _Hero.textHigh,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                height: 1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _Hero.textLow,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Soft card
  // ═════════════════════════════════════════════════════════
  Widget _softCard({
    required Widget child,
    Color? accent,
    EdgeInsets? padding,
    double radius = 20,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _P.divider),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Active walk banner
  // ═════════════════════════════════════════════════════════
  Widget _activeWalkBanner(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 14, _padH, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _P.greenSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.greenDeep.withOpacity(0.20)),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Transform.scale(
                scale: 1.0 + _pulseController.value * 0.15,
                child: const Icon(Icons.directions_walk_rounded,
                    color: _P.greenDeep, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Активная прогулка',
              style: GoogleFonts.inter(
                color: _P.text,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: -0.1,
              ),
            ),
            const Spacer(),
            Text(
              '${pedo.walkDuration.inMinutes.toString().padLeft(2, '0')}:${(pedo.walkDuration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(
                color: _P.greenDeep,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  STAT TILES — with progress hint
  // ═════════════════════════════════════════════════════════
  Widget _statTiles(PedometerProvider pedo, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Row(
        children: [
          Expanded(
            child: _statTile(
              Icons.straighten_rounded,
              pedo.distanceKm.toStringAsFixed(2),
              'КМ',
              _P.skyDeep,
              _P.skySoft,
              hint: '${((pedo.distanceKm / 8) * 100).clamp(0, 999).round()}%',
              onTap: () => _openJournal(pedo),
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
              hint: pedo.cadence >= 100 ? 'ТЕМП ✓' : 'спокойный',
              onTap: () => _openJournal(pedo),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statTile(
              Icons.local_fire_department_rounded,
              '${pedo.currentStreak}',
              'СТРИК',
              accent,
              _softForDeep(accent),
              hint: pedo.currentStreak > 0 ? 'дней' : '—',
              onTap: () => _openJournal(pedo, initialTab: 1),
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
    if (deep == _P.greenDeep) return _P.greenSoft;
    if (deep == _P.lavenderDeep) return _P.lavenderSoft;
    if (deep == _P.peachDeep) return _P.peachSoft;
    return _P.elevated;
  }

  Widget _statTile(
      IconData icon,
      String value,
      String label,
      Color accent,
      Color soft, {
        String? hint,
        VoidCallback? onTap,
      }) {
    final body = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider),
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
            style: GoogleFonts.inter(
              color: _P.text,
              fontSize: 19,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _P.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint,
              style: GoogleFonts.inter(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
    return onTap != null ? _Press(onTap: onTap, child: body) : body;
  }

  // ═════════════════════════════════════════════════════════
  //  LEVEL CARD — with rank title + streak flame
  // ═════════════════════════════════════════════════════════
  Widget _levelCard(PedometerProvider pedo) {
    final rank = _rankForLevel(pedo.level);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 0),
      child: _Press(
        onTap: () => _openJournal(pedo, initialTab: 1),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _P.lavenderSoft,
                _P.surface,
                _P.lavenderSoft.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _P.divider),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _P.lavenderDeep,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${pedo.level}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              rank.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: _P.lavenderDeep,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '· ур. ${pedo.level}',
                              style: GoogleFonts.inter(
                                color: _P.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${pedo.stepsToNextLevel} шагов до ${pedo.level + 1}',
                          style: GoogleFonts.inter(
                            color: _P.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: _P.yellowSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 11, color: _P.yellowDeep),
                        const SizedBox(width: 3),
                        Text(
                          '${pedo.achievementPoints} AP',
                          style: GoogleFonts.inter(
                            color: _P.yellowDeep,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: LinearProgressIndicator(
                  value: pedo.levelProgress,
                  minHeight: 6,
                  backgroundColor: _P.elevated,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(_P.lavenderDeep),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  ACHIEVEMENTS MINI — with progress hint
  // ═════════════════════════════════════════════════════════
  Widget _achievementsMini(PedometerProvider pedo) {
    final unlocked = pedo.achievements.where((a) => a.unlocked).length;
    final total = pedo.achievements.length;
    final pct = total > 0 ? unlocked / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 14, _padH, 0),
      child: _Press(
        onTap: () => _openJournal(pedo, initialTab: 1),
        child: _softCard(
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
                    child: const Icon(Icons.emoji_events_rounded,
                        color: _P.yellowDeep, size: 20),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ДОСТИЖЕНИЯ',
                          style: GoogleFonts.inter(
                            color: _P.yellowDeep,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Открыто $unlocked из $total',
                          style: GoogleFonts.inter(
                            color: _P.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(
                            value: pct,
                            strokeWidth: 3,
                            backgroundColor: _P.elevated,
                            valueColor: const AlwaysStoppedAnimation(
                                _P.yellowDeep),
                          ),
                        ),
                        Text(
                          '${(pct * 100).round()}',
                          style: GoogleFonts.inter(
                            color: _P.yellowDeep,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: _P.textMuted, size: 20),
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
          color: unlocked ? _P.yellowSoft : _P.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unlocked ? _P.yellowDeep.withOpacity(0.20) : _P.divider,
            width: 0.6,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: unlocked ? _P.yellowDeep : _P.textMuted, size: 18),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: unlocked ? _P.text : _P.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.inter(
                color: _P.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  ACTIVITY TIME — with rate
  // ═════════════════════════════════════════════════════════
  Widget _activityTimeCard(PedometerProvider pedo) {
    final rate = pedo.steps > 0
        ? (pedo.activeMinutes / (pedo.steps / 1000)).toStringAsFixed(1)
        : '—';
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 14, _padH, 0),
      child: _Press(
        onTap: () => _openJournal(pedo, initialTab: 0),
        child: _softCard(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _P.greenSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer_rounded,
                    color: _P.greenDeep, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'АКТИВНОЕ ВРЕМЯ',
                      style: GoogleFonts.inter(
                        color: _P.greenDeep,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${pedo.activeMinutes} мин',
                          style: GoogleFonts.inter(
                            color: _P.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· $rate мин/1000',
                          style: GoogleFonts.inter(
                            color: _P.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _P.greenSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'История',
                  style: GoogleFonts.inter(
                    color: _P.greenDeep,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: _P.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  COMPARISON — with "vs" + relative bar
  // ═════════════════════════════════════════════════════════
  Widget _comparisonCard(PedometerProvider pedo) {
    final diff = pedo.weekDiffPercent;
    final positive = diff >= 0;
    final color = positive ? _P.greenDeep : _P.pinkDeep;
    final thisWeek = pedo.weeklySteps;
    final lastWeek = pedo.lastWeekSteps;
    final maxVal = math.max(thisWeek, lastWeek).clamp(1, 1 << 30);
    final thisPct = thisWeek / maxVal;
    final lastPct = lastWeek / maxVal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 14, _padH, 0),
      child: _softCard(
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
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Сравнение активности',
                        style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 11,
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
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _comparisonValue(
                      'Эта', '${thisWeek}', _P.peachDeep, thisPct),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _P.elevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'vs',
                      style: GoogleFonts.inter(
                        color: _P.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _comparisonValue(
                      'Прошлая', '${lastWeek}', _P.textMuted, lastPct),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonValue(
      String title, String value, Color color, double barPct) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: _P.text,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: barPct,
            minHeight: 4,
            backgroundColor: _P.elevated,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  MONTHLY FORECAST — with mini day dots
  // ═════════════════════════════════════════════════════════
  Widget _monthlyForecastCard(PedometerProvider pedo) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 14, _padH, 0),
      child: _softCard(
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _P.skySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insights_rounded,
                  color: _P.skyDeep, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ПРОГНОЗ НА МЕСЯЦ',
                    style: GoogleFonts.inter(
                      color: _P.skyDeep,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pedo.monthlyProjection.toStringAsFixed(0),
                        style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                          height: 1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'км',
                          style: GoogleFonts.inter(
                            color: _P.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'при текущем темпе · $daysLeft дн. осталось',
                    style: GoogleFonts.inter(
                      color: _P.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Day dots
            SizedBox(
              width: 60,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 3,
                runSpacing: 3,
                children: List.generate(
                  daysInMonth,
                      (i) => Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < now.day
                          ? _P.skyDeep.withOpacity(0.5)
                          : _P.elevated,
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

  // ═════════════════════════════════════════════════════════
  //  PERSONAL RECORD — with date
  // ═════════════════════════════════════════════════════════
  Widget _personalRecordCard(PedometerProvider pedo) {
    if (pedo.bestDaySteps == 0) return const SizedBox.shrink();

    // Find the date of the best day
    String dateStr = '';
    try {
      final best = pedo.history
          .where((h) => h.steps == pedo.bestDaySteps)
          .toList();
      if (best.isNotEmpty) {
        final d = best.first.date;
        dateStr = '${d.day}.${d.month.toString().padLeft(2, '0')}';
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 14, _padH, 0),
      child: _Press(
        onTap: () => _openJournal(pedo, initialTab: 2),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _P.yellowSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _P.yellowDeep.withOpacity(0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _P.yellowDeep,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ЛИЧНЫЙ РЕКОРД',
                      style: GoogleFonts.inter(
                        color: _P.yellowDeep,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_fmt(pedo.bestDaySteps)} шагов за день',
                      style: GoogleFonts.inter(
                        color: _P.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        'установлен $dateStr',
                        style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _P.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  WEEKLY SUMMARY — with mini bars
  // ═════════════════════════════════════════════════════════
  Widget _weeklySummary(PedometerProvider pedo) {
    final last7 = pedo.history.length >= 7
        ? pedo.history.sublist(pedo.history.length - 7)
        : pedo.history;
    final maxSteps =
    last7.map((d) => d.steps).fold<int>(0, (m, v) => math.max(m, v));
    const days = ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 0),
      child: _softCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: _P.lavenderSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.date_range_rounded,
                      color: _P.lavenderDeep, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ИТОГИ ЗА 7 ДНЕЙ',
                        style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${pedo.weeklySteps} шагов',
                            style: GoogleFonts.inter(
                              color: _P.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('·',
                              style: TextStyle(
                                  color: _P.textMuted,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Text(
                            '${pedo.weeklyDistance.toStringAsFixed(1)} км',
                            style: GoogleFonts.inter(
                              color: _P.lavenderDeep,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (last7.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(last7.length, (i) {
                    final d = last7[i];
                    final frac = maxSteps > 0 ? d.steps / maxSteps : 0.0;
                    final reached = d.steps >= pedo.goal;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: i < last7.length - 1 ? 4 : 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 26 * frac + 3,
                              decoration: BoxDecoration(
                                color: reached
                                    ? _P.lavenderDeep
                                    : _P.lavenderDeep.withOpacity(0.30),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              days[d.date.weekday - 1],
                              style: GoogleFonts.inter(
                                color: _P.textMuted,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  ACTIVITY SCORE — with mini arc
  // ═════════════════════════════════════════════════════════
  Widget _activityScoreCard(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 0),
      child: _softCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          value: pedo.activityScore / 100,
                          strokeWidth: 4,
                          backgroundColor: _P.elevated,
                          valueColor: AlwaysStoppedAnimation(_timeAccent),
                        ),
                      ),
                      Text(
                        '${pedo.activityScore}',
                        style: GoogleFonts.inter(
                          color: _timeAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ИНДЕКС АКТИВНОСТИ',
                        style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'из 100 · сегодня',
                        style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat('🔥', '${pedo.calories.round()}', 'ККАЛ', _P.pinkDeep),
                _miniStat('⏱', '${pedo.activeMinutes}', 'МИН', _P.lavenderDeep),
                _miniStat('🚀', pedo.averageSpeed.toStringAsFixed(1), 'КМ/Ч',
                    _P.skyDeep),
                _miniStat(
                    '🏆', '${pedo.bestDaySteps}', 'РЕКОРД', _P.yellowDeep),
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
          style: GoogleFonts.inter(
            color: _P.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: _P.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  WATER PROMPT
  // ═════════════════════════════════════════════════════════
  Widget _waterPrompt(NutritionProvider nutrition) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 0),
      child: _softCard(
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
                style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
            _Press(
              onTap: () {
                HapticFeedback.mediumImpact();
                nutrition.addWater(250);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: _P.skyDeep,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '+250',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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
  //  VIRTUAL WALK
  // ═════════════════════════════════════════════════════════
  Widget _virtualWalkProgress(PedometerProvider pedo) {
    const double totalRoute = 9300;
    final walked = pedo.totalDistanceKmAllTime;
    final progress = (walked / totalRoute).clamp(0.0, 1.0);
    final remaining = (totalRoute - walked).clamp(0.0, totalRoute);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 0),
      child: _Press(
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
          ),
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -60,
                child: IgnorePointer(
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
                          child:
                          const Text('🚂', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ТРАНССИБ',
                                style: GoogleFonts.inter(
                                  color: _Dark.accentSoft,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Москва → Владивосток',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: _Dark.textHigh,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
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
                            style: GoogleFonts.inter(
                              color: _Dark.accentSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
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
                        style: GoogleFonts.inter(
                          color: _Dark.textMid,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
                                  ),
                                ),
                              ),
                              Positioned(
                                left: (w * progress).clamp(0.0, w - 28),
                                top: -2,
                                child: const Text(
                                  '🚂',
                                  style: TextStyle(fontSize: 22),
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
                          style: GoogleFonts.inter(
                            color: _Dark.textHigh,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${remaining.toStringAsFixed(0)} км до цели',
                          style: GoogleFonts.inter(
                            color: _Dark.textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
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
  //  CADENCE ZONES — with total
  // ═════════════════════════════════════════════════════════
  Widget _cadenceZones(PedometerProvider pedo) {
    final z1 = pedo.zone1Minutes;
    final z2 = pedo.zone2Minutes;
    final z3 = pedo.zone3Minutes;
    final total = z1 + z2 + z3;
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 0),
      child: _softCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ЗОНЫ ИНТЕНСИВНОСТИ',
                  style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${total.round()} мин',
                  style: GoogleFonts.inter(
                    color: _P.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
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

  Widget _zoneRow(String title, String subtitle, double minutes, Color accent,
      Color soft) {
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
                style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: _P.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
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
            style: GoogleFonts.inter(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  CALENDAR — with month + summary
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

    final daysWithGoal = data.where((d) => d.steps >= pedo.goal).length;
    final now = DateTime.now();
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    const daysOfWeek = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 0),
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
                  style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _P.greenSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$daysWithGoal из 28 с целью',
                    style: GoogleFonts.inter(
                      color: _P.greenDeep,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${months[now.month]} ${now.year}',
              style: GoogleFonts.inter(
                color: _P.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: daysOfWeek
                  .map((day) => Text(
                day,
                style: GoogleFonts.inter(
                  color: _P.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ))
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
                  cellColor = _P.pinkDeep.withOpacity(0.7);
                } else if (ratio >= 1.0) {
                  cellColor = _P.greenDeep.withOpacity(0.7);
                } else if (ratio >= 0.5) {
                  cellColor = _P.greenDeep.withOpacity(0.35);
                } else if (ratio > 0) {
                  cellColor = _P.greenDeep.withOpacity(0.15);
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
                  textStyle: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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
                _legendBox(_P.greenDeep.withOpacity(0.15), 'Мало'),
                _legendBox(_P.greenDeep.withOpacity(0.35), '50%'),
                _legendBox(_P.greenDeep.withOpacity(0.7), '100%'),
                _legendBox(_P.pinkDeep.withOpacity(0.7), '150%+'),
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
            style: GoogleFonts.inter(
              color: _P.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HOURLY — bottom-aligned + peak callout
  // ═════════════════════════════════════════════════════════
  Widget _hourlyScroll(PedometerProvider pedo) {
    final sortedHours = pedo.hourlySteps.keys.toList()..sort();
    if (sortedHours.isEmpty) return const SizedBox.shrink();

    final maxSteps =
    sortedHours.map((h) => pedo.hourlySteps[h] ?? 0).reduce(math.max);

    // Peak hour
    int peakHour = -1;
    for (final h in sortedHours) {
      if ((pedo.hourlySteps[h] ?? 0) == maxSteps && maxSteps > 0) {
        peakHour = h;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _padH),
            child: Row(
              children: [
                const Text('⏱', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  'ПО ЧАСАМ',
                  style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                if (peakHour >= 0) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _timeAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'пик · $peakHour:00',
                      style: GoogleFonts.inter(
                        color: _timeAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _padH),
              itemCount: sortedHours.length,
              itemBuilder: (context, index) {
                final hour = sortedHours[index];
                final steps = pedo.hourlySteps[hour] ?? 0;
                final heightFactor = maxSteps > 0 ? steps / maxSteps : 0.0;
                final isPeak = hour == peakHour;

                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _P.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                      isPeak ? _timeAccent : _P.divider,
                      width: isPeak ? 1.4 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: 40 * heightFactor + 4,
                        decoration: BoxDecoration(
                          color: _timeAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '$hour:00',
                        style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$steps',
                        style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          fontFeatures: const [FontFeature.tabularFigures()],
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
  //  CHART — with avg line + best day
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
        0, (m, d) => d.steps > m ? d.steps.toDouble() : m);
    final maxY = math.max(maxData, pedo.goal.toDouble()) * 1.2;
    final avg = safeData.isEmpty
        ? 0.0
        : safeData.fold<int>(0, (s, d) => s + d.steps) / safeData.length;
    final spots = List.generate(
      safeData.length,
          (i) => FlSpot(i.toDouble(), safeData[i].steps.toDouble()),
    );
    final bestIdx =
    safeData.indexWhere((d) => d.steps == maxData.round());

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 0),
      child: _softCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ПУЛЬС НЕДЕЛИ',
                        style: GoogleFonts.inter(
                          color: _timeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                      if (avg > 0)
                        Text(
                          'среднее ${_fmt(avg.round())}',
                          style: GoogleFonts.inter(
                            color: _P.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
                _Press(
                  onTap: () =>
                      setState(() => _isMonthlyChart = !_isMonthlyChart),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: _P.elevated,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      _isMonthlyChart ? '7 дней' : '30 дней',
                      style: GoogleFonts.inter(
                        color: _P.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        final d = safeData[s.x.toInt()];
                        return LineTooltipItem(
                          '${d.steps} шагов\n${d.date.day}.${d.date.month}',
                          GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: pedo.goal.toDouble(),
                        color: _P.greenDeep.withOpacity(0.35),
                        strokeWidth: 1.4,
                        dashArray: [6, 6],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: GoogleFonts.inter(
                            color: _P.greenDeep,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          labelResolver: (_) => 'ЦЕЛЬ',
                        ),
                      ),
                      if (avg > 0)
                        HorizontalLine(
                          y: avg,
                          color: _P.textMuted.withOpacity(0.30),
                          strokeWidth: 1,
                          dashArray: [3, 5],
                        ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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
                              : ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС']
                          [d.weekday - 1];
                          final isLast = i == safeData.length - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              text,
                              style: GoogleFonts.inter(
                                color: isLast
                                    ? _timeAccent
                                    : _P.textMuted,
                                fontSize: 10,
                                fontWeight: isLast
                                    ? FontWeight.w600
                                    : FontWeight.w500,
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
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isLast = index == safeData.length - 1;
                          final isBest = index == bestIdx && maxData > 0;
                          return FlDotCirclePainter(
                            radius: isLast ? 4.5 : (isBest ? 4.5 : 3.5),
                            color: isLast
                                ? _timeAccent
                                : (isBest ? _P.greenDeep : Colors.white),
                            strokeWidth: 2,
                            strokeColor: isBest && !isLast
                                ? _P.greenDeep
                                : _timeAccent,
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
  //  QUESTS — with XP + all-done state
  // ═════════════════════════════════════════════════════════
  Widget _questsSection(PedometerProvider pedo) {
    final quests = pedo.quests;
    if (quests.isEmpty) return const SizedBox.shrink();

    final allDone = quests.every((q) => q.isCompleted);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 0),
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
                  style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const Spacer(),
                if (allDone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _P.greenSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ВСЕ ✓',
                      style: GoogleFonts.inter(
                        color: _P.greenDeep,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
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
                  color: _P.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: q.isCompleted
                        ? _P.greenDeep.withOpacity(0.25)
                        : _P.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: q.isCompleted
                            ? _P.greenSoft
                            : _P.elevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        q.isCompleted
                            ? Icons.check_rounded
                            : Icons.flag_rounded,
                        color:
                        q.isCompleted ? _P.greenDeep : _P.textMuted,
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
                            style: GoogleFonts.inter(
                              color:
                              q.isCompleted ? _P.textMuted : _P.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              decoration: q.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            q.subtitle,
                            style: GoogleFonts.inter(
                              color: _P.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (!q.isCompleted) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: q.progress,
                                minHeight: 5,
                                backgroundColor: _P.elevated,
                                valueColor:
                                AlwaysStoppedAnimation(_timeAccent),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(q.progress * 100).round()}%',
                          style: GoogleFonts.inter(
                            color: q.isCompleted
                                ? _P.greenDeep
                                : _timeAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(q.progress * 100).round()}%',
                          style: GoogleFonts.inter(
                            color: q.isCompleted ? _P.greenDeep : _timeAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
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
  //  ACHIEVEMENTS HORIZONTAL — with progress for locked
  // ═════════════════════════════════════════════════════════
  Widget _achievementsSection(PedometerProvider pedo) {
    final achievements = pedo.achievements;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _padH),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'ДОСТИЖЕНИЯ',
                  style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _P.elevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${achievements.where((a) => a.unlocked).length}/${achievements.length}',
                    style: GoogleFonts.inter(
                      color: _P.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _padH),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final a = achievements[index];
                return Container(
                  width: 96,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: a.unlocked ? _P.yellowSoft : _P.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: a.unlocked
                          ? _P.yellowDeep.withOpacity(0.30)
                          : _P.divider,
                    ),
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
                              fontSize: 26,
                              color: a.unlocked ? null : _P.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color:
                              a.unlocked ? _P.text : _P.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          if (!a.unlocked) ...[
                            const SizedBox(height: 4),
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: _P.elevated,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
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
  //  GOAL CARD — with quick presets
  // ═════════════════════════════════════════════════════════
  Widget _goalCard(PedometerProvider pedo) {
    const presets = [5000, 8000, 10000, 12000];
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 20),
      child: _softCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _timeAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child:
                  Icon(Icons.flag_rounded, color: _timeAccent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ДНЕВНАЯ ЦЕЛЬ',
                        style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pedo.goal} шагов',
                        style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                _Press(
                  onTap: () => _editGoal(pedo),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: _timeAccent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      'ИЗМЕНИТЬ',
                      style: GoogleFonts.inter(
                        color: _timeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((p) {
                final selected = pedo.goal == p;
                return _Press(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    pedo.setGoal(p);
                  },
                  child: AnimatedContainer(
                    duration: _dur(160),
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? _timeAccent.withOpacity(0.10)
                          : _P.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? _timeAccent : _P.divider,
                        width: selected ? 1.2 : 1,
                      ),
                    ),
                    child: Text(
                      _fmt(p),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                        color:
                        selected ? _timeAccent : _P.textMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionCard(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 0, _padH, 16),
      child: _softCard(
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
                  child: const Icon(Icons.shield_outlined,
                      color: _P.pinkDeep, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Нет доступа к датчику движения',
                    style: GoogleFonts.inter(
                      color: _P.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                  child: _Press(
                    onTap: () => pedo.openSystemSettings(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _P.pinkSoft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'НАСТРОЙКИ',
                        style: GoogleFonts.inter(
                          color: _P.pinkDeep,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Press(
                    onTap: () => pedo.requestBatteryOptimization(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _P.yellowSoft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'БАТАРЕЯ',
                        style: GoogleFonts.inter(
                          color: _P.yellowDeep,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Press(
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
                        style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _P.yellowDeep.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: _P.yellowDeep, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ВЕХА ДНЯ',
                  style: GoogleFonts.inter(
                    color: _P.yellowSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Достигнуто ${_fmt(milestone)} шагов 🎉',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ));
  }

  void _showAchievementSnackbar(Achievement a) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
                  style: GoogleFonts.inter(
                    color: _P.yellowSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  a.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  a.description,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ));
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
            duration: _dur(600),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_P.lavenderDeep, Color(0xFF7B6BA5)],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_upward_rounded,
                      color: Colors.white, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    'УРОВЕНЬ ПОВЫШЕН',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$level',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 68,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rankForLevel(level),
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Продолжить',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _P.text,
            letterSpacing: -0.5,
          ),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(
              color: _P.text, fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            suffixText: 'шагов',
            suffixStyle:
            GoogleFonts.inter(color: _P.textMuted, fontSize: 13),
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
              style: GoogleFonts.inter(
                  color: _P.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v >= 100) Navigator.pop(ctx, v);
            },
            child: Text(
              'Сохранить',
              style: GoogleFonts.inter(
                  color: _timeAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (result != null) await pedo.setGoal(result);
  }

  Future<void> _showCalibration(PedometerProvider pedo) async {
    final hCtrl = TextEditingController(text: pedo.heightCm.round().toString());
    final wCtrl = TextEditingController(text: pedo.weightKg.round().toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Калибровка',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _P.text,
            letterSpacing: -0.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                  color: _P.text, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Рост (см)',
                labelStyle:
                GoogleFonts.inter(color: _P.textMuted, fontSize: 12),
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
              style: GoogleFonts.inter(
                  color: _P.text, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Вес (кг)',
                labelStyle:
                GoogleFonts.inter(color: _P.textMuted, fontSize: 12),
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
              style: GoogleFonts.inter(
                  color: _P.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
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
              style: GoogleFonts.inter(
                  color: _timeAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

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
    _drawRing(canvas, center, 84, 11, distanceProgress, _P.skyDeep, 0.12);
    _drawRing(canvas, center, 64, 11, calorieProgress, _P.pinkDeep, 0.14);
    _drawRing(canvas, center, 44, 11, activeProgress, _P.lavenderDeep, 0.16);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double stroke,
      double progress, Color color, double trackOpacity) {
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

// ═══════════════════════════════════════════════════════════════════
//  PRESS
// ═══════════════════════════════════════════════════════════════════
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _Press({required this.child, this.onTap, this.onLongPress});

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onLongPress != null;
    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: interactive ? (_) => _set(true) : null,
      onTapUp: interactive ? (_) => _set(false) : null,
      onTapCancel: interactive ? () => _set(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: widget.child,
    );
    if (!interactive) return child;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) return child;
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}