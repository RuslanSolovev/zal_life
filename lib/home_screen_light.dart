// lib/home_screen_light.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
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
import 'package:zal_life/features/fitness/models/fitness_models.dart';
import 'package:zal_life/features/fitness/providers/fitness_provider.dart';
import 'package:zal_life/features/fitness/providers/pedometer_provider.dart';
import 'package:zal_life/features/nutrition/providers/nutrition_provider.dart';
import 'package:zal_life/features/nutrition/providers/wellness_provider.dart';
import 'package:zal_life/features/nutrition/ui/screens/add_pantry_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/fuel_dashboard_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/knowledge_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/plan_tracker_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/profile_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/programs_hub_screen.dart';
import 'package:zal_life/features/nutrition/ui/screens/shopping_mode_screen.dart';
import 'package:zal_life/features/nutrition/ui/widgets/season_vine_card.dart';
import 'features/fitness/models/enums.dart';

// ═══════════════════════════════════════════════════════════════════
//  LIGHT THEME DESIGN SYSTEM ("Air & Paper")
// ═══════════════════════════════════════════════════════════════════
class _LightZal {
  static const bg = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const accentOrange = Color(0xFFF97316);
  static const accentBlue = Color(0xFF0EA5E9);
  static const accentGreen = Color(0xFF10B981);
  static const accentPurple = Color(0xFF8B5CF6);
  static const accentPink = Color(0xFFEC4899);
  static const divider = Color(0xFFE5E7EB);
  static const shadow = Color(0x0A000000);
}

const List<String> _lightHeroBackgrounds = [
  'assets/images/nature_hero.jpg', 'assets/images/nature_hero2.jpg', 'assets/images/nature_hero3.jpg',
  'assets/images/nature_hero4.jpg', 'assets/images/nature_hero5.jpg', 'assets/images/nature_hero6.jpg',
];

class HomeScreenLight extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreenLight({super.key, required this.onToggleTheme});

  @override
  State<HomeScreenLight> createState() => _HomeScreenLightState();
}

class _HomeScreenLightState extends State<HomeScreenLight> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _confettiController;
  late final ScrollController _scrollController;
  late final List<_ConfettiParticleLight> _confettiParticles;

  bool? _weekGoalWasReached;
  String _profileName = 'Спортсмен';
  String _heroBackground = _lightHeroBackgrounds[1];
  int _pedometerBackgroundIndex = 0;

  static const String _pedometerPrefsKey = 'pedometer_bg_index';
  static const int _weekGoal = 7;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _confettiController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _scrollController = ScrollController();
    _confettiParticles = _makeConfetti();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _profileName = prefs.getString('profile_name') ?? 'Спортсмен';
      final bg = prefs.getString('hero_bg_image');
      if (bg != null && _lightHeroBackgrounds.contains(bg)) {
        _heroBackground = bg;
      }
      _pedometerBackgroundIndex = (prefs.getInt(_pedometerPrefsKey) ?? 0).clamp(0, _lightHeroBackgrounds.length - 1);
    });
    // Задержка для безопасного чтения контекста после инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) _checkWeekGoal(_workoutsThisWeek(context.read<FitnessProvider>()));
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkWeekGoal(int workouts) {
    final reached = workouts >= _weekGoal;
    if (_weekGoalWasReached == null) {
      _weekGoalWasReached = reached;
      return;
    }
    if (reached && _weekGoalWasReached == false) {
      _weekGoalWasReached = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confettiController.forward(from: 0);
      });
    } else if (!reached) {
      _weekGoalWasReached = false;
    }
  }

  List<_ConfettiParticleLight> _makeConfetti() {
    final random = math.Random(73);
    const colors = [_LightZal.accentGreen, _LightZal.accentOrange, _LightZal.accentPink, _LightZal.accentBlue, _LightZal.accentPurple];
    return List.generate(70, (_) => _ConfettiParticleLight(
      x: random.nextDouble(), y: -random.nextDouble() * 0.7, drift: (random.nextDouble() - 0.5) * 330,
      speed: 0.65 + random.nextDouble() * 0.75, rotation: random.nextDouble() * math.pi * 2,
      spin: (random.nextDouble() - 0.5) * 10, width: 3 + random.nextDouble() * 6,
      height: 5 + random.nextDouble() * 9, color: colors[random.nextInt(colors.length)],
    ));
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    if (mounted) setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 350));
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final pedometer = context.watch<PedometerProvider>();
    final wellness = context.watch<WellnessProvider>();
    final now = DateTime.now();
    final weeklyWorkouts = _workoutsThisWeek(fitness);
    _checkWeekGoal(weeklyWorkouts);

    return Scaffold(
      backgroundColor: _LightZal.bg,
      body: Stack(
        children: [
          SafeArea(
            top: false, bottom: false,
            child: RefreshIndicator(
              color: _LightZal.accentGreen,
              backgroundColor: _LightZal.surface,
              displacement: 48,
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _appear(0.0, _lightHeader(fitness, nutrition, pedometer))),
                  SliverToBoxAdapter(child: _appear(0.1, _lightActivitySection(fitness, pedometer, weeklyWorkouts))),
                  SliverToBoxAdapter(child: _appear(0.25, _lightNutritionSection(nutrition))),
                  SliverToBoxAdapter(child: _appear(0.4, _lightWellnessSection(wellness, nutrition))),
                  SliverToBoxAdapter(child: _appear(0.5, _lightQuickStartSection(fitness))),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
          Positioned.fill(child: IgnorePointer(child: _confettiLayer())),
        ],
      ),
    );
  }

  Widget _appear(double delay, Widget child) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        final t = ((_entranceController.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        return Opacity(
          opacity: Curves.easeOut.transform(t),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _confettiLayer() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, _) {
        final progress = _confettiController.value;
        if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
        return CustomPaint(size: Size.infinite, painter: _ConfettiPainterLight(progress, _confettiParticles));
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _lightHeader(FitnessProvider fitness, NutritionProvider nutrition, PedometerProvider pedometer) {
    final summary = nutrition.getSummaryForDate(DateTime.now());
    final weekly = _workoutsThisWeek(fitness);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(), style: GoogleFonts.lora(fontSize: 18, color: _LightZal.textSecondary, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 4),
                  Text(_profileName, style: GoogleFonts.lora(fontSize: 34, fontWeight: FontWeight.bold, color: _LightZal.textPrimary, height: 1.1)),
                ],
              ),
              _lightThemeToggle(),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _LightZal.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: _LightZal.shadow, blurRadius: 24, offset: const Offset(0, 12))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: _LightZal.accentOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.local_fire_department_rounded, color: _LightZal.accentOrange, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Активность сегодня', style: GoogleFonts.inter(fontSize: 12, color: _LightZal.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          Text('$weekly / $_weekGoal тренировок', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: _LightZal.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: _LightZal.divider, height: 1),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _lightMiniMetric('🔥', '${summary.calories.round()}', 'ккал'),
                    Container(width: 1, height: 32, color: _LightZal.divider),
                    _lightMiniMetric('👟', _compactNumber(pedometer.steps), 'шагов'),
                    Container(width: 1, height: 32, color: _LightZal.divider),
                    _lightMiniMetric('💧', '${(summary.waterMl / 1000).toStringAsFixed(1)}', 'литра'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lightThemeToggle() {
    return Material(
      color: _LightZal.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: _LightZal.shadow,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onToggleTheme();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: const Icon(Icons.dark_mode_rounded, color: _LightZal.textPrimary, size: 24),
        ),
      ),
    );
  }

  Widget _lightMiniMetric(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _LightZal.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: _LightZal.textSecondary)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ACTIVITY SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _lightActivitySection(FitnessProvider fitness, PedometerProvider pedometer, int weeklyWorkouts) {
    final stats = fitness.getStats();
    final badges = _earnedBadges(stats);
    final records = _personalRecords(fitness, stats);
    final weekData = _weekDays(fitness, DateTime.now());

    return _LightSectionBlock(
      title: 'Твой прогресс',
      children: [
        _lightWorkoutFocusCard(fitness),
        const SizedBox(height: 16),
        _lightWeekAndStreakBento(fitness, weekData, weeklyWorkouts, stats),
        const SizedBox(height: 16),
        _lightPedometerCard(pedometer),
        const SizedBox(height: 16),
        _lightVolumeCard(fitness),
        if (badges.isNotEmpty || records.isNotEmpty) ...[
          const SizedBox(height: 16),
          _lightAchievementsAndRecords(badges, records),
        ],
        const SizedBox(height: 16),
        _lightTargetsBlock(fitness),
      ],
    );
  }

  Widget _lightWorkoutFocusCard(FitnessProvider fitness) {
    final session = fitness.activeSession;
    final wellbeing = fitness.getTodayWellbeing();
    WorkoutProgram? activeProgram;
    if (session != null) {
      try { activeProgram = fitness.programs.firstWhere((p) => p.id == session.programId); } catch (_) {}
    }

    final targetBg = activeProgram?.backgroundImage ?? _heroBackground;
    final hasBg = targetBg != null && targetBg.isNotEmpty;
    final progress = session == null ? 0.0 : session.progressPercent.clamp(0.0, 1.0);

    String title = 'Сила в мягком темпе';
    String subtitle = 'Ещё одна тренировка — и цель недели ближе.';
    String tag = 'ФОКУС ДНЯ';
    IconData icon = Icons.play_circle_fill_rounded;
    VoidCallback onTap = () => _quickStartWorkout(fitness);

    if (session != null) {
      title = activeProgram?.name ?? 'Продолжить тренировку';
      subtitle = 'День ${session.currentDayIndex + 1} · ${(session.progressPercent * 100).round()}%';
      tag = 'АКТИВНАЯ ПРОГРАММА';
      icon = Icons.play_arrow_rounded;
      onTap = () {
        HapticFeedback.lightImpact();
        if (activeProgram != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: fitness, child: ActiveProgramScreen(program: activeProgram!, isDark: false))));
        }
      };
    } else if (wellbeing == null) {
      title = 'Как самочувствие?';
      subtitle = 'Отметь состояние — подберём подходящую нагрузку';
      tag = 'СЕГОДНЯ';
      icon = Icons.spa_rounded;
      onTap = () => _openWellbeing();
    }

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: _LightZal.shadow, blurRadius: 24, offset: const Offset(0, 12))]),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasBg) Positioned.fill(child: Image.asset(targetBg, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _LightZal.divider))),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: hasBg ? [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.7)] : [_LightZal.surface, _LightZal.bg])))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: _LightZal.accentGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: _LightZal.accentGreen, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(tag, style: GoogleFonts.inter(color: _LightZal.accentGreen, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2))),
                    if (session != null) Text('${(progress * 100).round()}%', style: GoogleFonts.inter(color: _LightZal.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.lora(color: _LightZal.textPrimary, fontSize: 26, fontWeight: FontWeight.bold, height: 1.1)),
                const SizedBox(height: 8),
                Text(subtitle, style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 14, height: 1.4)),
                if (session != null) ...[
                  const SizedBox(height: 20),
                  ClipRRect(borderRadius: BorderRadius.circular(100), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation(_LightZal.accentGreen), minHeight: 8)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () { HapticFeedback.selectionClick(); onTap(); },
                    style: ElevatedButton.styleFrom(backgroundColor: _LightZal.accentGreen, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(session != null ? 'Продолжить' : 'Начать тренировку', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700))]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lightWeekAndStreakBento(FitnessProvider fitness, List<_WeekDayLight> week, int weeklyWorkouts, Map<String, dynamic> stats) {
    final todayIdx = DateTime.now().weekday - 1;
    const labels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    // ИСПРАВЛЕНИЕ: Правильный cast для streak
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final streakProgress = (streak / 30).clamp(0.0, 1.0);

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _LightPressCard(
              onTap: _openFitness,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Неделя', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)), const Icon(Icons.arrow_outward_rounded, color: _LightZal.textSecondary, size: 18)]),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$weeklyWorkouts', style: GoogleFonts.lora(color: _LightZal.textPrimary, fontSize: 36, fontWeight: FontWeight.bold, height: 1)),
                    Padding(padding: const EdgeInsets.only(left: 4, bottom: 4), child: Text('/ $_weekGoal', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 16))),
                  ]),
                  const SizedBox(height: 16),
                  ClipRRect(borderRadius: BorderRadius.circular(100), child: LinearProgressIndicator(value: (weeklyWorkouts / _weekGoal).clamp(0.0, 1.0), backgroundColor: _LightZal.divider, valueColor: const AlwaysStoppedAnimation(_LightZal.accentGreen), minHeight: 8)),
                  const Spacer(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i) {
                    final didTrain = week[i].workouts > 0;
                    final isToday = i == todayIdx;
                    return Column(children: [
                      Container(width: 22, height: 22, decoration: BoxDecoration(color: didTrain ? _LightZal.accentGreen : (isToday ? _LightZal.accentOrange : _LightZal.divider), shape: BoxShape.circle), child: didTrain ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null),
                      const SizedBox(height: 6),
                      Text(labels[i], style: GoogleFonts.inter(color: isToday ? _LightZal.accentOrange : _LightZal.textSecondary, fontSize: 10, fontWeight: isToday ? FontWeight.w800 : FontWeight.w600)),
                    ]);
                  })),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: _LightPressCard(
              onTap: _openProgress,
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Серия', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)), const Icon(Icons.arrow_outward_rounded, color: _LightZal.textSecondary, size: 18)]),
                  const SizedBox(height: 12),
                  Expanded(child: Center(child: SizedBox(width: 100, height: 100, child: Stack(alignment: Alignment.center, children: [
                    SizedBox.expand(child: CircularProgressIndicator(value: streakProgress, strokeWidth: 8, strokeCap: StrokeCap.round, backgroundColor: _LightZal.divider, valueColor: const AlwaysStoppedAnimation(_LightZal.accentOrange))),
                    Column(mainAxisSize: MainAxisSize.min, children: [Text('$streak', style: GoogleFonts.lora(color: _LightZal.textPrimary, fontSize: 32, fontWeight: FontWeight.bold, height: 1)), Text('дней', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 12))]),
                  ])))),
                  const SizedBox(height: 8),
                  // ИСПРАВЛЕНИЕ: maxLines вместо maxLines1
                  Text(streak >= 30 ? 'Легендарный ритм' : (streak >= 7 ? 'Отличная серия' : 'Начни свою серию'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: _LightZal.accentOrange, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lightPedometerCard(PedometerProvider pedo) {
    final progress = pedo.progress.clamp(0.0, 1.0);
    final path = _lightHeroBackgrounds[_pedometerBackgroundIndex];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openPedometer,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _LightZal.divider)),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xE6102119), Color(0x33102119)]))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_walk_rounded, color: _LightZal.accentGreen, size: 24),
                        const SizedBox(width: 12),
                        Text('ДНЕВНАЯ ДИСТАНЦИЯ', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            final next = (_pedometerBackgroundIndex + 1) % _lightHeroBackgrounds.length;
                            setState(() => _pedometerBackgroundIndex = next);
                            SharedPreferences.getInstance().then((p) => p.setInt(_pedometerPrefsKey, next));
                          },
                          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.wallpaper_rounded, color: Colors.white, size: 18)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_number(pedo.steps), style: GoogleFonts.lora(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, height: 1)),
                      const SizedBox(width: 8),
                      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('/ ${_number(pedo.goal)} шагов', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 14))),
                    ]),
                    const SizedBox(height: 8),
                    Text('${pedo.distanceKm.toStringAsFixed(1)} км · осталось ${_number(pedo.remaining)} шагов', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                    const SizedBox(height: 16),
                    ClipRRect(borderRadius: BorderRadius.circular(100), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation(_LightZal.accentGreen), minHeight: 8)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lightVolumeCard(FitnessProvider fitness) {
    final stats = fitness.getStats();
    // ИСПРАВЛЕНИЕ: Правильные cast для volume и workouts
    final totalVolume = ((stats['totalVolume'] ?? 0.0) as num).toDouble();
    final totalWorkouts = ((stats['totalWorkouts'] ?? 0) as num).toInt();

    return _LightPressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: _LightZal.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.query_stats_rounded, color: _LightZal.accentBlue, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ОБЪЁМ ТРЕНИРОВОК', style: GoogleFonts.inter(color: _LightZal.textPrimary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text('Твой силовой прогресс', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 12)),
              ])),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _lightStatChip('🏋️', _formatKg(totalVolume), 'Тоннаж', _LightZal.accentBlue)),
              const SizedBox(width: 12),
              Expanded(child: _lightStatChip('📅', '$totalWorkouts', 'Тренировки', _LightZal.accentOrange)),
              const SizedBox(width: 12),
              Expanded(child: _lightStatChip('🔥', totalWorkouts > 0 ? _formatKg(totalVolume / totalWorkouts) : '0 кг', 'Среднее', _LightZal.accentPink)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lightStatChip(String icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _LightZal.bg, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(color: _LightZal.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 11)),
      ]),
    );
  }

  Widget _lightAchievementsAndRecords(List<_AchievementDataLight> badges, List<_RecordDataLight> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badges.isNotEmpty) ...[
          Text('Достижения', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: badges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final b = badges[i];
                return Container(
                  width: 130, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _LightZal.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _LightZal.divider)),
                  child: Row(children: [
                    Text(b.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _LightZal.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(b.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 10)),
                    ])),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (records.isNotEmpty) ...[
          Text('Рекорды', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final r = records[i];
                return Container(
                  width: 130, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _LightZal.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _LightZal.divider)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Row(children: [Text(r.emoji, style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Expanded(child: Text(r.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.lora(color: _LightZal.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))) ]),
                    const SizedBox(height: 4),
                    Text(r.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 11)),
                  ]),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _lightTargetsBlock(FitnessProvider fitness) {
    final targets = fitness.activeTargets;
    return _LightPressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Мои цели', style: GoogleFonts.lora(color: _LightZal.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(onPressed: _openTargets, child: Text(targets.isEmpty ? 'Добавить' : 'Изменить', style: GoogleFonts.inter(color: _LightZal.accentGreen, fontSize: 13, fontWeight: FontWeight.w700))),
            ],
          ),
          if (targets.isEmpty)
            InkWell(
              onTap: _openTargets,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _LightZal.bg, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: _LightZal.accentGreen.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: _LightZal.accentGreen, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Поставь первую цель', style: GoogleFonts.inter(color: _LightZal.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Например, новый личный рекорд', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 12)),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: _LightZal.textSecondary),
                ]),
              ),
            )
          else
            ...targets.take(3).map((target) => _lightTargetRow(target, fitness)).toList(),
        ],
      ),
    );
  }

  Widget _lightTargetRow(FitnessTarget target, FitnessProvider fitness) {
    Exercise? exercise;
    if (target.exerciseId != null && target.exerciseId!.isNotEmpty) {
      try { exercise = fitness.exercises.firstWhere((item) => item.id == target.exerciseId); } catch (_) {}
    }
    final imagePath = exercise?.imageUrl;
    final emoji = exercise != null ? _exerciseEmojiLight(exercise.exerciseType) : _targetEmojiLight(target.type);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: fitness, child: FitnessTargetDetailsScreen(target: target, isDark: false))));
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48, clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: target.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: imagePath != null && imagePath.isNotEmpty
                      ? Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(emoji, style: const TextStyle(fontSize: 22))))
                      : Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(target.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _LightZal.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Прогресс · ${(target.progressPercent * 100).round()}%', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_outward_rounded, color: _LightZal.textSecondary, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(value: target.progressPercent.clamp(0.0, 1.0), backgroundColor: _LightZal.divider, valueColor: AlwaysStoppedAnimation(target.accentColor), minHeight: 6),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  NUTRITION SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _lightNutritionSection(NutritionProvider nutrition) {
    final today = DateTime.now();
    final summary = nutrition.getSummaryForDate(today);
    final goals = nutrition.getGoalsForDate(today);
    final program = nutrition.activeProgram;
    final kcalProgress = goals.calories > 0 ? (summary.calories / goals.calories).clamp(0.0, 1.0) : 0.0;
    final waterProgress = goals.waterMl > 0 ? (summary.waterMl / goals.waterMl).clamp(0.0, 1.0) : 0.0;

    return _LightSectionBlock(
      title: 'Питание',
      children: [
        if (program == null)
          _LightPressCard(
            onTap: _openProgramsHub,
            child: Row(
              children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: _LightZal.accentPink.withOpacity(0.1), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.restaurant_menu_rounded, color: _LightZal.accentPink, size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Создай программу питания', style: GoogleFonts.lora(color: _LightZal.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Настрой цели и следи за балансом дня', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 13)),
                ])),
                const Icon(Icons.arrow_forward_rounded, color: _LightZal.accentPink, size: 22),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: _openPlanTracker,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  if (program.backgroundImage != null && program.backgroundImage!.isNotEmpty)
                    Positioned.fill(child: Image.network(program.backgroundImage!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _LightZal.divider))),
                  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.8)])))),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.restaurant_rounded, color: _LightZal.accentPink, size: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('ТВОЯ ПРОГРАММА', style: GoogleFonts.inter(color: _LightZal.accentPink, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                              Text(program.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.lora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ])),
                            const Icon(Icons.arrow_outward_rounded, color: Colors.white70, size: 20),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${summary.calories.round()}', style: GoogleFonts.lora(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1)),
                                  const SizedBox(height: 4),
                                  Text('из ${goals.calories.round()} ккал', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 12),
                                  Text(summary.calories > goals.calories ? 'Перебор на ${(summary.calories - goals.calories).round()} ккал' : 'Осталось ${(goals.calories - summary.calories).round().clamp(0, 999999)} ккал', style: GoogleFonts.inter(color: _LightZal.accentPink, fontSize: 13, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 12),
                                  ClipRRect(borderRadius: BorderRadius.circular(100), child: LinearProgressIndicator(value: kcalProgress, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation(_LightZal.accentPink), minHeight: 8)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 80, height: 80,
                              child: Stack(alignment: Alignment.center, children: [
                                SizedBox.expand(child: CircularProgressIndicator(value: kcalProgress, strokeWidth: 8, strokeCap: StrokeCap.round, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation(_LightZal.accentPink))),
                                Text('${(kcalProgress * 100).round()}%', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ]),
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
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LightPressCard(
                onTap: _openNutrition,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Icon(Icons.local_fire_department_rounded, color: _LightZal.accentPink, size: 22), const Icon(Icons.arrow_outward_rounded, color: _LightZal.textSecondary, size: 18)]),
                  const SizedBox(height: 16),
                  Text('${summary.calories.round()}', style: GoogleFonts.lora(color: _LightZal.textPrimary, fontSize: 28, fontWeight: FontWeight.bold, height: 1)),
                  const SizedBox(height: 4),
                  Text('из ${goals.calories.round()} ккал', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),
                  ClipRRect(borderRadius: BorderRadius.circular(100), child: LinearProgressIndicator(value: kcalProgress, backgroundColor: _LightZal.divider, valueColor: const AlwaysStoppedAnimation(_LightZal.accentPink), minHeight: 8)),
                  const SizedBox(height: 8),
                  Text(summary.calories > goals.calories ? 'Цель превышена' : 'Осталось ${(goals.calories - summary.calories).round().clamp(0, 999999)} ккал', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 11)),
                ]),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _LightPressCard(
                onTap: _openNutrition,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Icon(Icons.water_drop_rounded, color: _LightZal.accentBlue, size: 22), const Icon(Icons.arrow_outward_rounded, color: _LightZal.textSecondary, size: 18)]),
                  const SizedBox(height: 16),
                  Text('${(summary.waterMl / 1000).toStringAsFixed(1)} л', style: GoogleFonts.lora(color: _LightZal.textPrimary, fontSize: 28, fontWeight: FontWeight.bold, height: 1)),
                  const SizedBox(height: 4),
                  Text('из ${(goals.waterMl / 1000).toStringAsFixed(1)} л воды', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: List.generate(8, (index) {
                      final filled = goals.waterMl > 0 && index < (waterProgress * 8).ceil();
                      return Icon(Icons.water_drop_rounded, size: 16, color: filled ? _LightZal.accentBlue : _LightZal.divider);
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(goals.waterMl > 0 && summary.waterMl >= goals.waterMl ? 'Норма выполнена' : 'Вода в течение дня', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 11)),
                ]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WELLNESS & QUICK START
  // ═══════════════════════════════════════════════════════════════════
  Widget _lightWellnessSection(WellnessProvider wellness, NutritionProvider nutrition) {
    return _LightSectionBlock(
      title: 'Здоровье и знания',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(color: _LightZal.surface, border: Border.all(color: _LightZal.divider), boxShadow: [BoxShadow(color: _LightZal.shadow, blurRadius: 12, offset: const Offset(0, 4))]),
            child: SeasonVineCard(wellness: wellness, nutrition: nutrition, scale: 1.0, onOpenKnowledge: _openKnowledge),
          ),
        ),
      ],
    );
  }

  Widget _lightQuickStartSection(FitnessProvider fitness) {
    final actions = <_QuickActionDataLight>[
      _QuickActionDataLight(Icons.bolt_rounded, 'Старт', _LightZal.accentGreen, () => _quickStartWorkout(fitness)),
      _QuickActionDataLight(Icons.history_rounded, 'Журнал', _LightZal.accentOrange, _openWorkoutLog),
      _QuickActionDataLight(Icons.fitness_center_rounded, 'База', _LightZal.accentBlue, _openExerciseLibrary),
      _QuickActionDataLight(Icons.spa_rounded, 'Настрой', _LightZal.accentPink, _openWellbeing),
      _QuickActionDataLight(Icons.flag_rounded, 'Цели', _LightZal.accentPurple, _openTargets),
    ];
    return _LightSectionBlock(
      title: 'Быстрый старт',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(color: _LightZal.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: _LightZal.divider), boxShadow: [BoxShadow(color: _LightZal.shadow, blurRadius: 12, offset: const Offset(0, 4))]),
          child: Row(
            children: actions.map((action) => Expanded(
              child: InkWell(
                onTap: () { HapticFeedback.selectionClick(); action.onTap(); },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 48, height: 48, decoration: BoxDecoration(color: action.color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(action.icon, color: action.color, size: 24)),
                      const SizedBox(height: 8),
                      Text(action.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _LightZal.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  MODALS & NAVIGATION
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _quickStartWorkout(FitnessProvider provider) async {
    HapticFeedback.mediumImpact();
    final searchController = TextEditingController();
    final selectedExercises = <Exercise>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = provider.exercises.where((exercise) => query.isEmpty || exercise.name.toLowerCase().contains(query)).toList();
            return Container(
              height: MediaQuery.sizeOf(sheetContext).height * 0.85,
              decoration: const BoxDecoration(color: _LightZal.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _LightZal.divider, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(width: 48, height: 48, decoration: BoxDecoration(color: _LightZal.accentGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.bolt_rounded, color: _LightZal.accentGreen, size: 26)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Быстрая тренировка', style: GoogleFonts.lora(color: _LightZal.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Выбери упражнения для своей сессии', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 13)),
                          ])),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: _LightZal.bg, borderRadius: BorderRadius.circular(20)), child: Text('${selectedExercises.length} выбрано', style: GoogleFonts.inter(color: _LightZal.textPrimary, fontSize: 12, fontWeight: FontWeight.w700))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: searchController,
                        onChanged: (_) => setSheetState(() {}),
                        style: GoogleFonts.inter(color: _LightZal.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Найти упражнение…',
                          hintStyle: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: _LightZal.textSecondary, size: 22),
                          suffixIcon: searchController.text.isEmpty ? null : IconButton(tooltip: 'Очистить', onPressed: () { searchController.clear(); setSheetState(() {}); HapticFeedback.selectionClick(); }, icon: const Icon(Icons.close_rounded, color: _LightZal.textSecondary, size: 20)),
                          filled: true,
                          fillColor: _LightZal.bg,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _LightZal.accentGreen, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(child: Text('Упражнения не найдены', style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 14)))
                            : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final exercise = filtered[index];
                            final isSelected = selectedExercises.any((item) => item.id == exercise.id);
                            final muscleColor = exercise.muscleGroups.isNotEmpty ? _muscleGroupColorLight(exercise.muscleGroups.first) : _LightZal.accentGreen;
                            final imagePath = exercise.imageUrl;
                            return Material(
                              color: _LightZal.bg,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setSheetState(() {
                                    if (isSelected) {
                                      selectedExercises.removeWhere((item) => item.id == exercise.id);
                                    } else {
                                      selectedExercises.add(exercise);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? _LightZal.accentGreen.withOpacity(0.4) : _LightZal.divider, width: isSelected ? 1.5 : 1)),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50, height: 50, clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(color: muscleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                        child: imagePath != null && imagePath.isNotEmpty
                                            ? Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(_exerciseEmojiLight(exercise.exerciseType), style: const TextStyle(fontSize: 24))))
                                            : Center(child: Text(_exerciseEmojiLight(exercise.exerciseType), style: const TextStyle(fontSize: 24))),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(child: Text(exercise.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _LightZal.textPrimary, fontSize: 14, fontWeight: FontWeight.w700))),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 30, height: 30,
                                        decoration: BoxDecoration(color: isSelected ? _LightZal.accentGreen : _LightZal.surface, shape: BoxShape.circle, border: Border.all(color: isSelected ? _LightZal.accentGreen : _LightZal.divider)),
                                        child: Icon(isSelected ? Icons.check_rounded : Icons.add_rounded, color: isSelected ? Colors.white : _LightZal.textSecondary, size: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: selectedExercises.isEmpty
                              ? null
                              : () {
                            final timestamp = DateTime.now().millisecondsSinceEpoch;
                            final quickDay = WorkoutDay(
                              id: 'quick_$timestamp',
                              programId: 'quick',
                              dayNumber: 1,
                              exercises: List.generate(selectedExercises.length, (index) {
                                final exercise = selectedExercises[index];
                                return WorkoutExercise(id: 'quick_ex_${timestamp}_$index', exerciseId: exercise.id, order: index, sets: [ExerciseSet(setNumber: 1, reps: 10, weight: 0)]);
                              }),
                            );
                            Navigator.pop(sheetContext);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: provider, child: WorkoutExecutionScreen(day: quickDay, isDark: false))));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _LightZal.accentGreen,
                            disabledBackgroundColor: _LightZal.divider,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: _LightZal.textSecondary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, size: 22),
                              const SizedBox(width: 8),
                              Text(selectedExercises.isEmpty ? 'Добавь упражнения' : 'НАЧАТЬ · ${selectedExercises.length}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            ],
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
      },
    );
    searchController.dispose();
  }

  Future<void> _openSettings() async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(color: _LightZal.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _LightZal.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('Настройки', style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.bold, color: _LightZal.textPrimary)),
              const SizedBox(height: 20),
              _lightSettingsTile(Icons.person_rounded, 'Профиль', _profileName, _openProfileScreen),
              const SizedBox(height: 12),
              _lightSettingsTile(Icons.dark_mode_rounded, 'Тёмная тема', 'Переключить на Forest', () {
                Navigator.pop(ctx);
                widget.onToggleTheme();
              }),
              const SizedBox(height: 12),
              _lightSettingsTile(Icons.landscape_rounded, 'Фон', 'Сменить изображение', _chooseHeroBackground),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lightSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: _LightZal.bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: _LightZal.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: _LightZal.shadow, blurRadius: 8)]), child: Icon(icon, color: _LightZal.textPrimary, size: 22)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.inter(color: _LightZal.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(color: _LightZal.textSecondary, fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right_rounded, color: _LightZal.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openProfileScreen() async {
    HapticFeedback.mediumImpact();
    final fitness = context.read<FitnessProvider>();
    final stats = fitness.getStats();
    final result = await Navigator.push<ProfileResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          initialName: _profileName,
          initialEmoji: '💪',
          initialImagePath: '',
          level: 1 + ((stats['totalWorkouts'] ?? 0) as num).toInt() ~/ 3,
          streak: ((stats['currentStreak'] ?? 0) as num).toInt(),
          totalWorkouts: ((stats['totalWorkouts'] ?? 0) as num).toInt(),
          totalVolume: ((stats['totalVolume'] ?? 0.0) as num).toDouble(),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _profileName = result.name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', result.name);
  }

  Future<void> _chooseHeroBackground() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(color: _LightZal.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _LightZal.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('Выберите фон', style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.bold, color: _LightZal.textPrimary)),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _lightHeroBackgrounds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (ctx, i) {
                    final path = _lightHeroBackgrounds[i];
                    final isSelected = path == _heroBackground;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _heroBackground = path);
                        SharedPreferences.getInstance().then((p) => p.setString('hero_bg_image', path));
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 140,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? _LightZal.accentBlue : Colors.transparent, width: 3)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _LightZal.divider)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openKnowledge() {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => MultiProvider(providers: [ChangeNotifierProvider.value(value: context.read<WellnessProvider>()), ChangeNotifierProvider.value(value: context.read<NutritionProvider>())], child: const KnowledgeScreen())));
  }

  void _openWorkoutLog() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const WorkoutLogScreen(isDark: false))));
  void _openExerciseLibrary() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const ExerciseLibraryScreen(isDark: false))));
  void _openWellbeing() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const WellbeingScreen(isDark: false))));
  void _openTargets() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const FitnessTargetsScreen(isDark: false))));
  void _openFitness() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const FitnessDashboard(isDark: false))));
  void _openNutrition() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<NutritionProvider>(), child: const FuelDashboardScreen(isDark: false))));
  void _openProgramsHub() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<NutritionProvider>(), child: const ProgramsHubScreen())));
  void _openPlanTracker() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<NutritionProvider>(), child: const PlanTrackerScreen())));
  void _openPedometer() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<PedometerProvider>(), child: const PedometerScreen(isDark: false))));
  void _openProgress() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const ProgressScreen(isDark: false))));

  // ═══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════
  int _workoutsThisWeek(FitnessProvider fitness) {
    return ((fitness.getStats()['workoutsThisWeek'] ?? 0) as num).toInt();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  String _number(int value) {
    final source = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < source.length; i++) {
      if (i > 0 && (source.length - i) % 3 == 0) out.write(' ');
      out.write(source[i]);
    }
    return out.toString();
  }

  String _compactNumber(int value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }

  String _formatKg(double v) {
    if (v < 1) return '0 кг';
    return '${v.round()} кг';
  }

  String _exerciseEmojiLight(ExerciseType type) {
    final key = type.toString().split('.').last.toLowerCase();
    if (key.contains('strength') || key.contains('weight')) return '🏋️';
    if (key.contains('cardio') || key.contains('run')) return '🏃';
    if (key.contains('stretch') || key.contains('flex') || key.contains('yoga')) return '🧘';
    return '💪';
  }

  String _targetEmojiLight(FitnessTargetType type) {
    final key = type.toString().split('.').last.toLowerCase();
    if (key.contains('weight') || key.contains('mass')) return '⚖️';
    if (key.contains('strength') || key.contains('lift')) return '🏋️';
    return '🎯';
  }

  Color _muscleGroupColorLight(MuscleGroup group) {
    final key = group.toString().split('.').last.toLowerCase();
    if (key.contains('chest')) return const Color(0xFFE87979);
    if (key.contains('back')) return const Color(0xFF6E9FE8);
    if (key.contains('leg')) return const Color(0xFF9B83D8);
    return _LightZal.accentGreen;
  }

  List<_WeekDayLight> _weekDays(FitnessProvider fitness, DateTime today) {
    // Упрощенная заглушка для совместимости, в реальном проекте использовать логику из оригинала
    return List.generate(7, (index) => _WeekDayLight(today.subtract(Duration(days: today.weekday - 1 - index)), 0, 0));
  }

  List<_AchievementDataLight> _earnedBadges(Map<String, dynamic> stats) {
    final workouts = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final result = <_AchievementDataLight>[];
    if (workouts >= 1) result.add(const _AchievementDataLight('🏅', 'Первый шаг', 'Первая тренировка', _LightZal.accentOrange));
    if (streak >= 7) result.add(const _AchievementDataLight('🔥', 'Неделя', '7 дней подряд', _LightZal.accentPink));
    if (workouts >= 10) result.add(const _AchievementDataLight('💪', 'Десятка', '10 тренировок', _LightZal.accentGreen));
    return result;
  }

  List<_RecordDataLight> _personalRecords(FitnessProvider fitness, Map<String, dynamic> stats) {
    final records = <_RecordDataLight>[];
    final totalWorkouts = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    final totalVolume = ((stats['totalVolume'] ?? 0.0) as num).toDouble();
    if (totalWorkouts > 0) records.add(_RecordDataLight('🎯', '$totalWorkouts', 'всего тренировок'));
    if (totalVolume > 0) records.add(_RecordDataLight('🔥', '${totalVolume.round()} кг', 'общий тоннаж'));
    return records;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LIGHT THEME WIDGETS
// ═══════════════════════════════════════════════════════════════════
class _LightSectionBlock extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _LightSectionBlock({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.lora(color: _LightZal.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _LightPressCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _LightPressCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _LightZal.surface,
      borderRadius: BorderRadius.circular(24),
      elevation: 1,
      shadowColor: _LightZal.shadow,
      child: InkWell(
        onTap: onTap == null ? null : () { HapticFeedback.selectionClick(); onTap!(); },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _LightZal.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: _LightZal.divider)),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════
class _WeekDayLight {
  final DateTime date;
  final int workouts;
  final double volume;
  const _WeekDayLight(this.date, this.workouts, this.volume);
}

class _AchievementDataLight {
  final String emoji, title, description;
  final Color color;
  const _AchievementDataLight(this.emoji, this.title, this.description, this.color);
}

class _RecordDataLight {
  final String emoji, value, label;
  const _RecordDataLight(this.emoji, this.value, this.label);
}

class _QuickActionDataLight {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionDataLight(this.icon, this.label, this.color, this.onTap);
}

class _ConfettiParticleLight {
  final double x, y, drift, speed, rotation, spin, width, height;
  final Color color;
  const _ConfettiParticleLight({required this.x, required this.y, required this.drift, required this.speed, required this.rotation, required this.spin, required this.width, required this.height, required this.color});
}

class _ConfettiPainterLight extends CustomPainter {
  final double progress;
  final List<_ConfettiParticleLight> particles;
  const _ConfettiPainterLight(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final t = (progress * particle.speed).clamp(0.0, 1.15).toDouble();
      final x = particle.x * size.width + particle.drift * t;
      final y = particle.y * size.height + t * size.height * 1.12;
      if (y < -30 || y > size.height + 30) continue;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + particle.spin * t);
      final paint = Paint()..color = particle.color.withOpacity((1 - (progress * 0.75)).clamp(0.0, 1.0).toDouble());
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: particle.width, height: particle.height), const Radius.circular(2)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainterLight oldDelegate) => oldDelegate.progress != progress;
}