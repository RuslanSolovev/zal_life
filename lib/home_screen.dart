// lib/home_screen.dart
//
// Главный экран Zal Life.
// Зависимости: provider, google_fonts, shared_preferences,
// cached_network_image, sensors_plus (используется внутри PedometerProvider).

import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ⬇️ РЕАЛЬНЫЕ ПРОВАЙДЕРЫ ПРОЕКТА
import 'features/fitness/providers/fitness_provider.dart';
import 'features/fitness/providers/pedometer_provider.dart';
import 'features/nutrition/providers/nutrition_provider.dart';
import 'features/nutrition/providers/wellness_provider.dart';

// ============================================================================
// ПАЛИТРА, ТИПОГРАФИКА И ОБЩИЕ ХЕЛПЕРЫ
// ============================================================================

class _P {
  static const bg = Color(0xFFF7F5F0);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1E2A24);
  static const muted = Color(0xFF7A857E);
  static const green = Color(0xFF2F7D5B);
  static const pink = Color(0xFFE06A8B);
  static const sage = Color(0xFF8FA98A);
  static const peach = Color(0xFFF0A05A);
  static const blue = Color(0xFF5B8DEF);
  static const line = Color(0xFFEAE7DF);
}

TextStyle _t({
  double size = 14,
  FontWeight weight = FontWeight.w600,
  Color color = _P.ink,
  double height = 1.25,
  double letter = 0,
}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letter,
    );

/// Универсальная «мягкая» карточка bento-стиля.
Widget _card({
  required Color color,
  required Widget child,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      boxShadow: color == _P.card
          ? [
        BoxShadow(
          color: _P.ink.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ]
          : null,
    ),
    child: child,
  );
}

// ============================================================================
// HOME SCREEN
// ============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // --- анимации ---
  late final AnimationController _stagger;
  late final AnimationController _confetti;

  // --- prefs ---
  SharedPreferences? _prefs;
  String _name = 'Атлет';
  String _emoji = '🏃';
  String? _avatarImagePath;
  int _heroBg = 0;
  int _heroStyle = 0;
  int _pedometerBg = 0;

  // --- конфетти ---
  List<_Particle> _particles = const [];
  bool _weekGoalWasMet = false;

  bool _loading = true;

  static const _weekdayShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _particles = const []);
      }
    });
    _loadPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _stagger.forward();
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = p;
      _name = p.getString('profile_name') ?? 'Атлет';
      _emoji = p.getString('avatar_emoji') ?? '🏃';
      _avatarImagePath = p.getString('avatar_image_path');
      _heroBg = (p.getInt('hero_bg_image') ?? 0).clamp(0, _heroBgs.length - 1);
      _heroStyle = (p.getInt('hero_style') ?? 0).clamp(0, _heroStyles.length - 1);
      _pedometerBg =
          (p.getInt('pedometer_bg_index') ?? 0).clamp(0, _pedometerBgs.length - 1);
      _loading = false;
    });
  }

  // --------------------------------------------------------------------------
  // ВЫЧИСЛЯЕМЫЕ ПОКАЗАТЕЛИ
  // --------------------------------------------------------------------------

  DateTime get _today => DateTime.now();

  DateTime get _monday {
    final t = DateTime(_today.year, _today.month, _today.day);
    return t.subtract(Duration(days: t.weekday - 1));
  }

  int _workoutsThisWeek(FitnessProvider f) {
    final stats = f.getStats();
    final fromStats = (stats['workoutsThisWeek'] as int?) ?? 0;
    if (fromStats > 0) return fromStats;
    var count = 0;
    for (var i = 0; i < 7; i++) {
      final d = _monday.add(Duration(days: i));
      if (d.isAfter(_today)) break;
      count += f.getLogsForDate(d).length;
    }
    return count;
  }

  List<bool> _weekMarks(FitnessProvider f) {
    return List.generate(7, (i) {
      final d = _monday.add(Duration(days: i));
      if (d.isAfter(_today)) return false;
      return f.getLogsForDate(d).isNotEmpty;
    });
  }

  List<double> _weekVolumes(FitnessProvider f) {
    return List.generate(7, (i) {
      final d = _monday.add(Duration(days: i));
      if (d.isAfter(_today)) return 0;
      return f.getLogsForDate(d).fold<double>(0, (a, l) => a + l.volume);
    });
  }

  int _streak(FitnessProvider f) => (f.getStats()['streak'] as int?) ?? 0;

  int _totalWorkouts(FitnessProvider f) =>
      (f.getStats()['totalWorkouts'] as int?) ?? f.logs.length;

  double _totalVolume(FitnessProvider f) {
    final v = f.getStats()['totalVolume'];
    if (v is num) return v.toDouble();
    return f.logs.fold<double>(0, (a, l) => a + l.volume);
  }

  int _level(int totalWorkouts) => 1 + (totalWorkouts ~/ 3);

  // --------------------------------------------------------------------------
  // КОНФЕТТИ
  // --------------------------------------------------------------------------

  void _runConfetti() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final rnd = math.Random(DateTime.now().microsecondsSinceEpoch);
    setState(() {
      _particles = List.generate(70, (_) => _Particle.random(rnd));
    });
    _confetti.forward(from: 0);
  }

  // --------------------------------------------------------------------------
  // REFRESH
  // --------------------------------------------------------------------------

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    final f = context.read<FitnessProvider>();
    final n = context.read<NutritionProvider>();
    final p = context.read<PedometerProvider>();
    // Реальные провайдеры используют init(). Если добавите отдельный
    // refresh() — замените вызовы ниже.
    await Future.wait<void>([
      f.init(),
      n.init(),
      p.init(),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() {});
  }

  // --------------------------------------------------------------------------
  // НАВИГАЦИЯ
  // --------------------------------------------------------------------------

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openProfile({
    required int level,
    required int streak,
    required int totalWorkouts,
    required double totalVolume,
  }) async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push<ProfileResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          initialName: _name,
          initialEmoji: _emoji,
          initialImagePath: _avatarImagePath,
          level: level,
          streak: streak,
          totalWorkouts: totalWorkouts,
          totalVolume: totalVolume,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _name = result.name;
      _emoji = result.emoji;
      _avatarImagePath = result.imagePath;
    });
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString('profile_name', result.name);
      await prefs.setString('avatar_emoji', result.emoji);
      if (result.imagePath == null || result.imagePath!.isEmpty) {
        await prefs.remove('avatar_image_path');
      } else {
        await prefs.setString('avatar_image_path', result.imagePath!);
      }
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _showSettingsSheet({
    required int level,
    required int streak,
    required int totalWorkouts,
    required double totalVolume,
  }) async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SettingsSheet(
        onProfile: () {
          Navigator.pop(context);
          _openProfile(
            level: level,
            streak: streak,
            totalWorkouts: totalWorkouts,
            totalVolume: totalVolume,
          );
        },
        onStyle: () {
          Navigator.pop(context);
          _showStyleSheet();
        },
        onBackground: () {
          Navigator.pop(context);
          _showBackgroundSheet();
        },
      ),
    );
  }

  Future<void> _showStyleSheet() async {
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PickerSheet(
        title: 'Стиль шапки',
        subtitle: 'Выберите вариант оформления Hero-блока',
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: List.generate(_heroStyles.length, (i) {
            final s = _heroStyles[i];
            final active = i == _heroStyle;
            return _PickTile(
              active: active,
              label: s.name,
              colors: [_P.green, const Color(0xFF1B4D38)],
              onTap: () => Navigator.pop(context, i),
              preview: Row(
                mainAxisAlignment: s.centerText
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: s.circleAvatar
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius:
                      s.circleAvatar ? null : BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: s.centerText
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 34, height: 5, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(
                        width: 22,
                        height: 4,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _heroStyle = picked);
    await _prefs?.setInt('hero_style', picked);
    HapticFeedback.lightImpact();
  }

  Future<void> _showBackgroundSheet() async {
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PickerSheet(
        title: 'Фон главного экрана',
        subtitle: 'Настройте атмосферу под себя',
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
          children: List.generate(_heroBgs.length, (i) {
            final bg = _heroBgs[i];
            final active = i == _heroBg;
            return _PickTile(
              active: active,
              label: bg.name,
              colors: bg.colors,
              onTap: () => Navigator.pop(context, i),
              preview: Center(
                child: Text(bg.emoji, style: const TextStyle(fontSize: 26)),
              ),
            );
          }),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _heroBg = picked);
    await _prefs?.setInt('hero_bg_image', picked);
    HapticFeedback.lightImpact();
  }

  Future<void> _cyclePedometerBg() async {
    HapticFeedback.selectionClick();
    final next = (_pedometerBg + 1) % _pedometerBgs.length;
    setState(() => _pedometerBg = next);
    await _prefs?.setInt('pedometer_bg_index', next);
  }

  void _showShoppingMode(NutritionProvider n) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _P.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text(
            'Режим покупок включён · ${n.pantry.length} поз. в кладовой',
            style: _t(color: Colors.white, size: 13),
          ),
        ),
      );
  }

  Future<void> _showAddPantrySheet() async {
    HapticFeedback.selectionClick();
    final ctrl = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: _P.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Добавить в кладовую',
                  style: _t(size: 18, weight: FontWeight.w800)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: _t(size: 15),
                decoration: InputDecoration(
                  hintText: 'Например: гречка',
                  hintStyle: _t(color: _P.muted, weight: FontWeight.w500),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _P.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  child: Text('Добавить', style: _t(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    context.read<NutritionProvider>().addPantryItem(name);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _P.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          '«$name» добавлено в кладовую',
          style: _t(color: Colors.white, size: 13),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // БЫСТРАЯ ТРЕНИРОВКА
  // --------------------------------------------------------------------------

  Future<void> _showQuickWorkoutSheet() async {
    HapticFeedback.selectionClick();
    final fitness = context.read<FitnessProvider>();
    final selected = await showModalBottomSheet<List<Exercise>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _QuickWorkoutSheet(exercises: fitness.exercises),
      ),
    );
    if (selected == null || selected.isEmpty || !mounted) return;

    final day = WorkoutDay(
      id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
      programId: 'quick',
      dayNumber: 1,
      exercises: selected,
    );
    // Если в FitnessProvider метод называется иначе — поправьте здесь.
    fitness.startQuickWorkout(day);
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: fitness,
          child: WorkoutExecutionScreen(day: day),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final pedometer = context.watch<PedometerProvider>();
    final wellness = context.watch<WellnessProvider>();

    final totalWorkouts = _totalWorkouts(fitness);
    final totalVolume = _totalVolume(fitness);
    final streak = _streak(fitness);
    final weekCount = _workoutsThisWeek(fitness);
    final weekGoalMet = weekCount >= 7;
    final level = _level(totalWorkouts);

    if (weekGoalMet && !_weekGoalWasMet) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runConfetti());
    }
    _weekGoalWasMet = weekGoalMet;

    final summary = nutrition.getSummaryForDate(_today);
    final goals = nutrition.getGoalsForDate(_today);

    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          RefreshIndicator(
            color: _P.green,
            backgroundColor: Colors.white,
            edgeOffset: 40,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _reveal(
                    start: 0.0,
                    child: _HeroHeader(
                      name: _name,
                      emoji: _emoji,
                      avatarImagePath: _avatarImagePath,
                      background: _heroBgs[_heroBg],
                      style: _heroStyles[_heroStyle],
                      level: level,
                      activeProgramName: nutrition.activeProgram?.name,
                      calories: summary.calories,
                      calorieGoal: goals.calories,
                      steps: pedometer.steps,
                      stepGoal: pedometer.goal,
                      activeSessionName: fitness.activeSession?.programName,
                      onSettings: () => _showSettingsSheet(
                        level: level,
                        streak: streak,
                        totalWorkouts: totalWorkouts,
                        totalVolume: totalVolume,
                      ),
                      onShopping: () => _showShoppingMode(nutrition),
                      onAddPantry: _showAddPantrySheet,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _reveal(
                    start: 0.12,
                    child: _section(
                      title: 'Активность',
                      accent: _P.green,
                      actionLabel: 'Журнал',
                      onAction: () => _push(const WorkoutLogScreen()),
                      child: _ActivityBody(
                        fitness: fitness,
                        pedometer: pedometer,
                        weekCount: weekCount,
                        weekMarks: _weekMarks(fitness),
                        weekVolumes: _weekVolumes(fitness),
                        streak: streak,
                        totalWorkouts: totalWorkouts,
                        totalVolume: totalVolume,
                        pedometerBg: _pedometerBg,
                        onCyclePedometerBg: _cyclePedometerBg,
                        onOpenJournal: () => _push(const WorkoutLogScreen()),
                        onOpenDashboard: () => _push(const FitnessDashboard()),
                        onOpenProgress: () => _push(const ProgressScreen()),
                        onOpenPedometer: () => _push(const PedometerScreen()),
                        onContinueSession: () {
                          final active = fitness.activeSession;
                          if (active == null) return;
                          _push(
                            ChangeNotifierProvider.value(
                              value: fitness,
                              child: const ActiveProgramScreen(),
                            ),
                          );
                        },
                        onOpenWellbeing: () => _push(const WellbeingScreen()),
                        onQuickWorkout: _showQuickWorkoutSheet,
                        onOpenTargets: () => _push(const FitnessTargetsScreen()),
                        onOpenTarget: (t) => _push(
                          FitnessTargetDetailsScreen(target: t),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _reveal(
                    start: 0.24,
                    child: _section(
                      title: 'Питание',
                      accent: _P.pink,
                      actionLabel: 'Подробнее',
                      onAction: () => _push(const FuelDashboardScreen()),
                      child: _NutritionBody(
                        nutrition: nutrition,
                        summary: summary,
                        goals: goals,
                        onCreateProgram: () => _push(const ProgramsHubScreen()),
                        onOpenProgram: () => _push(const PlanTrackerScreen()),
                        onOpenFuel: () => _push(const FuelDashboardScreen()),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _reveal(
                    start: 0.36,
                    child: _section(
                      title: 'Здоровье и знания',
                      accent: _P.sage,
                      actionLabel: 'База знаний',
                      onAction: () => _push(
                        MultiProvider(
                          providers: [
                            ChangeNotifierProvider<WellnessProvider>.value(
                              value: wellness,
                            ),
                            ChangeNotifierProvider<NutritionProvider>.value(
                              value: nutrition,
                            ),
                          ],
                          child: const KnowledgeScreen(),
                        ),
                      ),
                      child: SeasonVineCard(
                        wellness: wellness,
                        nutrition: nutrition,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _reveal(
                    start: 0.48,
                    child: _section(
                      title: 'Быстрый старт',
                      accent: _P.peach,
                      child: _QuickStartRow(
                        onStart: _showQuickWorkoutSheet,
                        onJournal: () => _push(const WorkoutLogScreen()),
                        onBase: () => _push(const ExerciseLibraryScreen()),
                        onWellbeing: () => _push(const WellbeingScreen()),
                        onTargets: () => _push(const FitnessTargetsScreen()),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, __) {
                  if (_particles.isEmpty || _confetti.value == 0) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    painter: _ConfettiPainter(_confetti.value, _particles),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: _P.bg,
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: _P.green,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reveal({required double start, required Widget child}) {
    final curve = CurvedAnimation(
      parent: _stagger,
      curve: Interval(
        start,
        math.min(start + 0.5, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  Widget _section({
    required String title,
    required Color accent,
    required Widget child,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 22,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: _t(size: 20, weight: FontWeight.w800),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onAction();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    actionLabel,
                    style:
                    _t(size: 13, weight: FontWeight.w700, color: accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// HERO HEADER
// ============================================================================

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.name,
    required this.emoji,
    required this.avatarImagePath,
    required this.background,
    required this.style,
    required this.level,
    required this.activeProgramName,
    required this.calories,
    required this.calorieGoal,
    required this.steps,
    required this.stepGoal,
    required this.activeSessionName,
    required this.onSettings,
    required this.onShopping,
    required this.onAddPantry,
  });

  final String name;
  final String emoji;
  final String? avatarImagePath;
  final _HeroBg background;
  final _HeroStyle style;
  final int level;
  final String? activeProgramName;
  final double calories;
  final double calorieGoal;
  final int steps;
  final int stepGoal;
  final String? activeSessionName;
  final VoidCallback onSettings;
  final VoidCallback onShopping;
  final VoidCallback onAddPantry;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 6) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  IconData get _greetingIcon {
    final h = DateTime.now().hour;
    if (h < 6) return Icons.nightlight_round;
    if (h < 12) return Icons.wb_sunny_rounded;
    if (h < 18) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final avatar = _buildAvatar();

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 18, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: background.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: background.colors.last.withOpacity(0.28),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -10,
            child: Text(
              background.emoji,
              style: TextStyle(
                fontSize: 130,
                color: Colors.white.withOpacity(style.emojiOpacity),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: style.centerText
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: style.centerText
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _greetingIcon,
                              size: 16,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _greeting,
                              style: _t(
                                size: 13,
                                weight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: _t(
                            size: 26,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Уровень $level',
                            style: _t(
                              size: 12,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: onSettings,
                        icon: const Icon(Icons.tune_rounded,
                            color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      const SizedBox(height: 8),
                      avatar,
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (activeSessionName != null)
                    _heroChip(
                        Icons.bolt_rounded, 'Тренировка: $activeSessionName'),
                  if (activeProgramName != null)
                    _heroChip(Icons.restaurant_rounded, activeProgramName!),
                  _heroChip(
                    Icons.local_fire_department_rounded,
                    '${calories.round()} / ${calorieGoal.round()} ккал',
                  ),
                  _heroChip(
                      Icons.directions_walk_rounded, '$steps шагов'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _heroAction(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Режим покупок',
                      onTap: onShopping,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _heroAction(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'В кладовую',
                      onTap: onAddPantry,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final path = avatarImagePath;
    final image = (path != null && path.isNotEmpty)
        ? ClipRRect(
      borderRadius:
      BorderRadius.circular(style.circleAvatar ? 100 : 16),
      child: CachedNetworkImage(
        imageUrl: path,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        placeholder: (_, __) => _emojiAvatar(),
        errorWidget: (_, __, ___) => _emojiAvatar(),
      ),
    )
        : _emojiAvatar();

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: style.circleAvatar ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: style.circleAvatar ? null : BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.35),
      ),
      child: image,
    );
  }

  Widget _emojiAvatar() {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        shape: style.circleAvatar ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: style.circleAvatar ? null : BorderRadius.circular(16),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 26)),
    );
  }

  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style:
              _t(size: 12, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: _t(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// СЕКЦИЯ «АКТИВНОСТЬ»
// ============================================================================

class _ActivityBody extends StatelessWidget {
  const _ActivityBody({
    required this.fitness,
    required this.pedometer,
    required this.weekCount,
    required this.weekMarks,
    required this.weekVolumes,
    required this.streak,
    required this.totalWorkouts,
    required this.totalVolume,
    required this.pedometerBg,
    required this.onCyclePedometerBg,
    required this.onOpenJournal,
    required this.onOpenDashboard,
    required this.onOpenProgress,
    required this.onOpenPedometer,
    required this.onContinueSession,
    required this.onOpenWellbeing,
    required this.onQuickWorkout,
    required this.onOpenTargets,
    required this.onOpenTarget,
  });

  final FitnessProvider fitness;
  final PedometerProvider pedometer;
  final int weekCount;
  final List<bool> weekMarks;
  final List<double> weekVolumes;
  final int streak;
  final int totalWorkouts;
  final double totalVolume;
  final int pedometerBg;
  final VoidCallback onCyclePedometerBg;
  final VoidCallback onOpenJournal;
  final VoidCallback onOpenDashboard;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenPedometer;
  final VoidCallback onContinueSession;
  final VoidCallback onOpenWellbeing;
  final VoidCallback onQuickWorkout;
  final VoidCallback onOpenTargets;
  final void Function(FitnessTarget) onOpenTarget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _focusCard(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _weekCard(context)),
            const SizedBox(width: 12),
            Expanded(child: _streakCard(context)),
          ],
        ),
        const SizedBox(height: 12),
        _pedometerCard(context),
        const SizedBox(height: 12),
        _analyticsCard(context),
        const SizedBox(height: 12),
        _achievementsCard(context),
        const SizedBox(height: 12),
        _targetsCard(context),
      ],
    );
  }

  Widget _focusCard() {
    final session = fitness.activeSession;
    if (session != null) {
      return _card(
        color: _P.green,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _pill('Активная сессия', Colors.white.withOpacity(0.2),
                    Colors.white),
                const Spacer(),
                Text(
                  '${(session.percent * 100).round()}%',
                  style: _t(
                      size: 22,
                      weight: FontWeight.w800,
                      color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.programName,
              style: _t(
                  size: 19, weight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'День ${session.dayNumber}',
              style:
              _t(size: 13, weight: FontWeight.w600, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: session.percent.clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onContinueSession();
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Продолжить', style: _t(weight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _P.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!fitness.wellbeingChecked) {
      return _card(
        color: _P.card,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _P.sage.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.favorite_rounded, color: _P.sage),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Как самочувствие?',
                      style: _t(size: 15, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    'Отметьте состояние — подберём нагрузку',
                    style: _t(
                        size: 12, color: _P.muted, weight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onOpenWellbeing();
              },
              style: FilledButton.styleFrom(
                backgroundColor: _P.sage,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Отметить',
                  style: _t(size: 12, color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return _card(
      color: _P.card,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _P.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bolt_rounded, color: _P.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Готовы к тренировке?',
                    style: _t(size: 15, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  'Соберите быструю сессию за пару тапов',
                  style: _t(
                      size: 12, color: _P.muted, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onQuickWorkout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: _P.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Старт', style: _t(size: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _weekCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onOpenDashboard();
      },
      child: _card(
        color: _P.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Неделя',
                    style:
                    _t(size: 13, weight: FontWeight.w700, color: _P.muted)),
                const Spacer(),
                Text(
                  '$weekCount/7',
                  style:
                  _t(size: 13, weight: FontWeight.w800, color: _P.green),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: weekCount / 7,
                minHeight: 6,
                backgroundColor: _P.line,
                valueColor: const AlwaysStoppedAnimation(_P.green),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final done = weekMarks[i];
                return Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: done ? _P.green : _P.line,
                        shape: BoxShape.circle,
                      ),
                      child: done
                          ? const Icon(Icons.check,
                          size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _HomeScreenState._weekdayShort[i],
                      style: _t(
                        size: 9.5,
                        weight: FontWeight.w600,
                        color: _P.muted,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _streakCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onOpenProgress();
      },
      child: _card(
        color: _P.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Серия',
                style:
                _t(size: 13, weight: FontWeight.w700, color: _P.muted)),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                          value: (streak % 30) / 30,
                          strokeWidth: 6,
                          backgroundColor: _P.line,
                          valueColor:
                          const AlwaysStoppedAnimation(_P.peach),
                        ),
                      ),
                      Text(
                        '$streak',
                        style: _t(size: 16, weight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    streak == 0 ? 'Начните серию\nсегодня' : 'дней подряд',
                    style:
                    _t(size: 12, color: _P.muted, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pedometerCard(BuildContext context) {
    final bg = _pedometerBgs[pedometerBg % _pedometerBgs.length];
    final remaining = math.max(0, pedometer.goal - pedometer.steps);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onOpenPedometer();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bg.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_walk_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text('Шаги',
                    style: _t(
                        size: 13, weight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                IconButton(
                  onPressed: onCyclePedometerBg,
                  icon: const Icon(Icons.palette_outlined,
                      color: Colors.white, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.16),
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${pedometer.steps}',
                  style: _t(
                      size: 28, weight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ ${pedometer.goal}',
                    style: _t(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Colors.white70),
                  ),
                ),
                const Spacer(),
                Text(
                  '${pedometer.distanceKm.toStringAsFixed(1)} км',
                  style: _t(
                      size: 13, weight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: (pedometer.steps / pedometer.goal).clamp(0, 1),
                minHeight: 7,
                backgroundColor: Colors.white.withOpacity(0.22),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Осталось $remaining шагов',
              style: _t(
                  size: 11.5, weight: FontWeight.w600, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _analyticsCard(BuildContext context) {
    final hasData = weekVolumes.any((v) => v > 0);
    final maxV = weekVolumes.fold<double>(0, math.max);
    final total = weekVolumes.fold<double>(0, (a, b) => a + b);
    final activeDays = weekVolumes.where((v) => v > 0).length;
    final bestIndex = weekVolumes.indexOf(maxV);
    final bestDay = maxV > 0
        ? '${_HomeScreenState._weekdayShort[bestIndex]} · ${maxV.round()} кг'
        : '—';

    return _card(
      color: _P.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Аналитика недели',
                  style: _t(size: 15, weight: FontWeight.w800)),
              const Spacer(),
              if (hasData)
                Text(
                  '${total.round()} кг',
                  style:
                  _t(size: 13, weight: FontWeight.w800, color: _P.green),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasData)
            _empty(
              icon: Icons.bar_chart_rounded,
              title: 'Пока нет тренировок',
              subtitle:
              'Выполните первую тренировку, чтобы увидеть график.',
            )
          else ...[
            SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final h = maxV == 0 ? 0.0 : (weekVolumes[i] / maxV) * 80;
                  final isBest = i == bestIndex && maxV > 0;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          weekVolumes[i].round().toString(),
                          style: _t(
                            size: 9,
                            color: isBest ? _P.green : _P.muted,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: math.max(h, 4),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: isBest
                                ? _P.green
                                : _P.green.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _HomeScreenState._weekdayShort[i],
                          style: _t(
                              size: 9.5,
                              color: _P.muted,
                              weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metric('Тоннаж', '${total.round()} кг'),
                _metric('В среднем', '${(total / 7).round()} кг/д'),
                _metric('Активных дней', '$activeDays/7'),
                _metric('Лучший день', bestDay),
                _metric('Серия', '$streak дн.'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _achievementsCard(BuildContext context) {
    final badges = <_Badge>[];
    if (totalWorkouts >= 1) {
      badges.add(const _Badge('🥇', 'Первая\nтренировка'));
    }
    if (totalWorkouts >= 7 || streak >= 7) {
      badges.add(const _Badge('🔥', '7 дней\nсерии'));
    }
    if (totalWorkouts >= 10) {
      badges.add(const _Badge('💪', '10\nтренировок'));
    }
    if (totalVolume >= 1000) {
      badges.add(const _Badge('🏋️', 'Тонна\nобъёма'));
    }
    if (streak >= 30) {
      badges.add(const _Badge('⭐', '30 дней\nсерии'));
    }

    final maxSingle = fitness.logs.isEmpty
        ? 0.0
        : fitness.logs.map((l) => l.volume).reduce(math.max);
    final maxPerDay = <String, int>{};
    for (final l in fitness.logs) {
      final key = '${l.date.year}-${l.date.month}-${l.date.day}';
      maxPerDay[key] = (maxPerDay[key] ?? 0) + 1;
    }
    final maxDayCount =
    maxPerDay.values.isEmpty ? 0 : maxPerDay.values.reduce(math.max);

    final records = <_Record>[
      if (maxSingle > 0)
        _Record('Макс. объём', '${maxSingle.round()} кг',
            Icons.fitness_center_rounded),
      if (maxDayCount > 0)
        _Record('Тренировок в день', '$maxDayCount',
            Icons.event_available_rounded),
      if (totalWorkouts > 0)
        _Record('Всего тренировок', '$totalWorkouts', Icons.repeat_rounded),
      if (totalVolume > 0)
        _Record('Общий тоннаж', '${totalVolume.round()} кг',
            Icons.stacked_bar_chart_rounded),
    ];

    if (badges.isEmpty && records.isEmpty) return const SizedBox.shrink();

    return _card(
      color: _P.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Достижения и рекорды',
              style: _t(size: 15, weight: FontWeight.w800)),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final b = badges[i];
                  return Container(
                    width: 78,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: _P.peach.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(b.emoji,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          b.label,
                          textAlign: TextAlign.center,
                          style: _t(size: 10, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (records.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: records.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final r = records[i];
                  return Container(
                    width: 132,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _P.bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(r.icon, size: 16, color: _P.green),
                        const Spacer(),
                        Text(r.value,
                            style:
                            _t(size: 14, weight: FontWeight.w800)),
                        Text(
                          r.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(
                              size: 10,
                              color: _P.muted,
                              weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _targetsCard(BuildContext context) {
    final goals = fitness.goals.take(3).toList();
    return _card(
      color: _P.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Цели', style: _t(size: 15, weight: FontWeight.w800)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onOpenTargets();
                },
                child: Text(
                  goals.isEmpty ? 'Добавить' : 'Изменить',
                  style:
                  _t(size: 12.5, weight: FontWeight.w700, color: _P.green),
                ),
              ),
            ],
          ),
          if (goals.isEmpty)
            _empty(
              icon: Icons.flag_rounded,
              title: 'Целей пока нет',
              subtitle: 'Поставьте цель и следите за прогрессом.',
            )
          else
            ...goals.map((g) {
              final progress =
              g.target == 0 ? 0.0 : (g.current / g.target).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onOpenTarget(g);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              g.title,
                              style: _t(size: 13, weight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${g.current.round()}/${g.target.round()} ${g.unit}',
                            style: _t(
                              size: 11.5,
                              weight: FontWeight.w700,
                              color: _P.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: _P.line,
                          valueColor: const AlwaysStoppedAnimation(_P.green),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child:
      Text(text, style: _t(size: 11, weight: FontWeight.w700, color: fg)),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _P.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
              _t(size: 9.5, color: _P.muted, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: _t(size: 12, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _empty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: _P.muted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _t(size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: _t(
                      size: 11.5, color: _P.muted, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// СЕКЦИЯ «ПИТАНИЕ»
// ============================================================================

class _NutritionBody extends StatelessWidget {
  const _NutritionBody({
    required this.nutrition,
    required this.summary,
    required this.goals,
    required this.onCreateProgram,
    required this.onOpenProgram,
    required this.onOpenFuel,
  });

  final NutritionProvider nutrition;
  final NutritionSummary summary;
  final NutritionGoals goals;
  final VoidCallback onCreateProgram;
  final VoidCallback onOpenProgram;
  final VoidCallback onOpenFuel;

  @override
  Widget build(BuildContext context) {
    final program = nutrition.activeProgram;
    final remaining = goals.calories - summary.calories;
    final progress = goals.calories == 0
        ? 0.0
        : (summary.calories / goals.calories).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (program == null)
          _card(
            color: _P.card,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _P.pink.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded,
                      color: _P.pink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Нет активной программы',
                          style: _t(size: 15, weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        'Подберите питание под ваши цели',
                        style: _t(
                            size: 12,
                            color: _P.muted,
                            weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onCreateProgram();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _P.pink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                  Text('Создать', style: _t(size: 12, color: Colors.white)),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onOpenProgram();
            },
            child: _card(
              color: _P.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          program.name,
                          style: _t(size: 16, weight: FontWeight.w800),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 5,
                                backgroundColor: _P.line,
                                valueColor:
                                const AlwaysStoppedAnimation(_P.pink),
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style:
                              _t(size: 10.5, weight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${summary.calories.round()} / ${goals.calories.round()} ккал',
                    style: _t(
                        size: 12.5,
                        color: _P.muted,
                        weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: _P.line,
                      valueColor: const AlwaysStoppedAnimation(_P.pink),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    remaining >= 0
                        ? 'Осталось ${remaining.round()} ккал'
                        : 'Перебор ${(-remaining).round()} ккал',
                    style: _t(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: remaining >= 0 ? _P.pink : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onOpenFuel();
                },
                child: _card(
                  color: _P.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Калории',
                          style: _t(
                              size: 12,
                              color: _P.muted,
                              weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        '${summary.calories.round()}',
                        style: _t(size: 22, weight: FontWeight.w800),
                      ),
                      Text(
                        'из ${goals.calories.round()} ккал',
                        style: _t(
                            size: 11,
                            color: _P.muted,
                            weight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: _P.line,
                          valueColor:
                          const AlwaysStoppedAnimation(_P.pink),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Остаток ${math.max(0, remaining).round()} ккал',
                        style: _t(
                            size: 10.5,
                            weight: FontWeight.w700,
                            color: _P.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onOpenFuel();
                },
                child: _card(
                  color: _P.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Вода',
                          style: _t(
                              size: 12,
                              color: _P.muted,
                              weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        '${summary.water.toStringAsFixed(1)} л',
                        style: _t(size: 22, weight: FontWeight.w800),
                      ),
                      Text(
                        'из ${goals.water.toStringAsFixed(1)} л',
                        style: _t(
                            size: 11,
                            color: _P.muted,
                            weight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(5, (i) {
                          final filled = summary.water >=
                              (goals.water * (i + 1) / 5).clamp(0, goals.water);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Icon(
                                Icons.local_drink_rounded,
                                size: 16,
                                color: filled ? _P.blue : _P.line,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// SEASON VINE CARD
// ============================================================================

class SeasonVineCard extends StatelessWidget {
  const SeasonVineCard({
    super.key,
    required this.wellness,
    required this.nutrition,
  });

  final WellnessProvider wellness;
  final NutritionProvider nutrition;

  @override
  Widget build(BuildContext context) {
    final tips = wellness.seasonalTips;
    final tip = tips.isNotEmpty
        ? tips.first
        : 'Следите за водным балансом и добавляйте сезонные овощи в рацион.';
    final program = nutrition.activeProgram;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.sage.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.sage.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _P.sage.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.spa_rounded, color: _P.sage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Сезонный совет',
                    style: _t(size: 14, weight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: _t(
                      size: 12.5, color: _P.ink, weight: FontWeight.w500),
                ),
                if (program != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Рекомендация по программе «${program.name}» доступна в базе знаний.',
                    style: _t(
                        size: 11, color: _P.muted, weight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// БЫСТРЫЙ СТАРТ
// ============================================================================

class _QuickStartRow extends StatelessWidget {
  const _QuickStartRow({
    required this.onStart,
    required this.onJournal,
    required this.onBase,
    required this.onWellbeing,
    required this.onTargets,
  });

  final VoidCallback onStart;
  final VoidCallback onJournal;
  final VoidCallback onBase;
  final VoidCallback onWellbeing;
  final VoidCallback onTargets;

  @override
  Widget build(BuildContext context) {
    final items = <_QuickItem>[
      _QuickItem(Icons.play_arrow_rounded, 'Старт', onStart),
      _QuickItem(Icons.receipt_long_rounded, 'Журнал', onJournal),
      _QuickItem(Icons.menu_book_rounded, 'База', onBase),
      _QuickItem(Icons.favorite_rounded, 'Настрой', onWellbeing),
      _QuickItem(Icons.flag_rounded, 'Цели', onTargets),
    ];
    return Row(
      children: List.generate(items.length, (i) {
        final it = items[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
            child: Material(
              color: _P.card,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  it.onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _P.peach.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(it.icon, size: 18, color: _P.peach),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        it.label,
                        style: _t(size: 10.5, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================================
// ШТОРКА «БЫСТРАЯ ТРЕНИРОВКА»
// ============================================================================

class _QuickWorkoutSheet extends StatefulWidget {
  const _QuickWorkoutSheet({required this.exercises});

  final List<Exercise> exercises;

  @override
  State<_QuickWorkoutSheet> createState() => _QuickWorkoutSheetState();
}

class _QuickWorkoutSheetState extends State<_QuickWorkoutSheet> {
  final _search = TextEditingController();
  final _selected = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Exercise> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return widget.exercises;
    return widget.exercises
        .where((e) => e.name.toLowerCase().contains(q))
        .toList();
  }

  List<Exercise> get _selectedExercises =>
      widget.exercises.where((e) => _selected.contains(e.id)).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Container(
      decoration: const BoxDecoration(
        color: _P.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: _P.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Быстрая тренировка',
                      style: _t(size: 18, weight: FontWeight.w800)),
                ),
                Text(
                  '${_selected.length} выбрано',
                  style: _t(
                      size: 12, weight: FontWeight.w700, color: _P.green),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: _t(size: 14),
              decoration: InputDecoration(
                hintText: 'Поиск упражнения…',
                hintStyle: _t(color: _P.muted, weight: FontWeight.w500),
                prefixIcon: const Icon(Icons.search_rounded, color: _P.muted),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _search.clear();
                    setState(() {});
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                filtered.isEmpty
                    ? Center(
                  child: Text(
                    'Ничего не найдено',
                    style:
                    _t(color: _P.muted, weight: FontWeight.w600),
                  ),
                )
                    : ListView.separated(
                  padding:
                  const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = filtered[i];
                    final active = _selected.contains(e.id);
                    return Material(
                      color: active
                          ? _P.green.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (active) {
                              _selected.remove(e.id);
                            } else {
                              _selected.add(e.id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: active
                                      ? _P.green
                                      : _P.green.withOpacity(0.12),
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  active
                                      ? Icons.check
                                      : Icons.fitness_center,
                                  size: 18,
                                  color: active
                                      ? Colors.white
                                      : _P.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.name,
                                  style: _t(
                                      size: 14,
                                      weight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: FilledButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, _selectedExercises);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _P.green,
                        disabledBackgroundColor: _P.line,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _selected.isEmpty
                            ? 'Выберите упражнения'
                            : 'Начать тренировку · ${_selected.length}',
                        style: _t(
                          size: 14,
                          weight: FontWeight.w800,
                          color: _selected.isEmpty ? _P.muted : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ШТОРКИ НАСТРОЕК
// ============================================================================

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({
    required this.onProfile,
    required this.onStyle,
    required this.onBackground,
  });

  final VoidCallback onProfile;
  final VoidCallback onStyle;
  final VoidCallback onBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: _P.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: _P.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Настройки', style: _t(size: 18, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          _tile(Icons.person_outline_rounded, 'Профиль', onProfile),
          _tile(Icons.style_outlined, 'Стиль шапки', onStyle),
          _tile(Icons.wallpaper_rounded, 'Фон главного экрана', onBackground),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _P.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _P.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style: _t(size: 14, weight: FontWeight.w700))),
              const Icon(Icons.chevron_right_rounded, color: _P.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: _P.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: _P.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: _t(size: 18, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
              style:
              _t(size: 12, color: _P.muted, weight: FontWeight.w500)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.active,
    required this.label,
    required this.colors,
    required this.onTap,
    required this.preview,
  });

  final bool active;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? _P.green : _P.line,
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: preview,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(size: 10.5, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// КОНФЕТТИ
// ============================================================================

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.vr,
    required this.sway,
    required this.phase,
    required this.color,
  });

  final double x;
  final double y;
  final double vy;
  final double size;
  final double rotation;
  final double vr;
  final double sway;
  final double phase;
  final Color color;

  factory _Particle.random(math.Random r) {
    const palette = [
      Color(0xFF2F7D5B),
      Color(0xFFE06A8B),
      Color(0xFFF0A05A),
      Color(0xFF8FA98A),
      Color(0xFF5B8DEF),
      Color(0xFFF2D06B),
      Color(0xFFB983FF),
    ];
    return _Particle(
      x: r.nextDouble(),
      y: -0.1 - r.nextDouble() * 0.25,
      vy: 0.75 + r.nextDouble() * 0.95,
      size: 5 + r.nextDouble() * 7,
      rotation: r.nextDouble() * math.pi,
      vr: (r.nextDouble() - 0.5) * 7,
      sway: 2 + r.nextDouble() * 3,
      phase: r.nextDouble() * math.pi * 2,
      color: palette[r.nextInt(palette.length)],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.particles);

  final double t;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final fade = (1 - (t - 0.7).clamp(0, 0.3) / 0.3).clamp(0.0, 1.0);
    for (final p in particles) {
      final dx = (p.x + math.sin(t * p.sway + p.phase) * 0.05) * size.width;
      final dy = (p.y + p.vy * t) * size.height;
      if (dy < -30 || dy > size.height + 30) continue;
      paint.color = p.color.withOpacity(fade);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation + p.vr * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.t != t || old.particles != particles;
}

// ============================================================================
// МЕЛКИЕ МОДЕЛИ ДЛЯ UI
// ============================================================================

class _HeroBg {
  const _HeroBg(this.name, this.colors, this.emoji);
  final String name;
  final List<Color> colors;
  final String emoji;
}

class _HeroStyle {
  const _HeroStyle({
    required this.name,
    this.circleAvatar = true,
    this.centerText = false,
    this.emojiOpacity = 0.10,
  });
  final String name;
  final bool circleAvatar;
  final bool centerText;
  final double emojiOpacity;
}

class _Badge {
  const _Badge(this.emoji, this.label);
  final String emoji;
  final String label;
}

class _Record {
  const _Record(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _QuickItem {
  const _QuickItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

const List<_HeroBg> _heroBgs = [
  _HeroBg('Лес', [Color(0xFF2F7D5B), Color(0xFF1B4D38)], '🌲'),
  _HeroBg('Океан', [Color(0xFF2D6CDF), Color(0xFF163A7A)], '🌊'),
  _HeroBg('Закат', [Color(0xFFF08A5D), Color(0xFFB83B5E)], '🌅'),
  _HeroBg('Лаванда', [Color(0xFF9B7EDE), Color(0xFF5E4B8B)], '💜'),
  _HeroBg('Мята', [Color(0xFF4DB6AC), Color(0xFF1E6B63)], '🌿'),
  _HeroBg('Песок', [Color(0xFFD9A566), Color(0xFF9C6B3F)], '🏜️'),
  _HeroBg('Ночь', [Color(0xFF2B2D42), Color(0xFF141522)], '🌙'),
  _HeroBg('Роза', [Color(0xFFE06A8B), Color(0xFF8E2A52)], '🌹'),
  _HeroBg('Небо', [Color(0xFF6FB1FC), Color(0xFF2B5FA8)], '☁️'),
  _HeroBg('Осень', [Color(0xFFD97A3A), Color(0xFF8A3F1D)], '🍁'),
  _HeroBg('Хвоя', [Color(0xFF3F6B57), Color(0xFF20382D)], '🌲'),
  _HeroBg('Коралл', [Color(0xFFFF8A80), Color(0xFFB23A48)], '🪸'),
  _HeroBg('Ирис', [Color(0xFF6C5CE7), Color(0xFF3B2E8C)], '💠'),
  _HeroBg('Туман', [Color(0xFF8FA98A), Color(0xFF4F6650)], '🌫️'),
  _HeroBg('Золото', [Color(0xFFE8B84B), Color(0xFF9A6B12)], '🌞'),
  _HeroBg('Лёд', [Color(0xFF8FD3E8), Color(0xFF3F8CA8)], '❄️'),
  _HeroBg('Гранат', [Color(0xFFB23A48), Color(0xFF5C1220)], '🍎'),
  _HeroBg('Бамбук', [Color(0xFF7CB342), Color(0xFF33691E)], '🎋'),
  _HeroBg('Море', [Color(0xFF1D7874), Color(0xFF0B3C3A)], '🐚'),
  _HeroBg('Сакура', [Color(0xFFF8BBD0), Color(0xFFC2185B)], '🌸'),
  _HeroBg('Вулкан', [Color(0xFFE64A19), Color(0xFF5D1A0A)], '🌋'),
];

const List<_HeroStyle> _heroStyles = [
  _HeroStyle(name: 'Классика'),
  _HeroStyle(name: 'Прямоугольник', circleAvatar: false),
  _HeroStyle(name: 'По центру', centerText: true, emojiOpacity: 0.08),
  _HeroStyle(name: 'Минимал', emojiOpacity: 0.03),
  _HeroStyle(name: 'Крупный эмодзи', emojiOpacity: 0.22),
  _HeroStyle(name: 'Центр + квадрат', circleAvatar: false, centerText: true),
  _HeroStyle(name: 'Тихий фон', emojiOpacity: 0.0),
  _HeroStyle(name: 'Мягкий', emojiOpacity: 0.12),
  _HeroStyle(name: 'Контраст', emojiOpacity: 0.16),
  _HeroStyle(name: 'Плавный', centerText: true, emojiOpacity: 0.05),
  _HeroStyle(name: 'Строгий', circleAvatar: false, emojiOpacity: 0.02),
  _HeroStyle(name: 'Воздушный', emojiOpacity: 0.14),
];

const List<_HeroBg> _pedometerBgs = [
  _HeroBg('Зелёный', [Color(0xFF2F7D5B), Color(0xFF1B4D38)], ''),
  _HeroBg('Синий', [Color(0xFF3A7BD5), Color(0xFF1B3F7A)], ''),
  _HeroBg('Персик', [Color(0xFFF0A05A), Color(0xFFB85C2E)], ''),
  _HeroBg('Роза', [Color(0xFFE06A8B), Color(0xFF8E2A52)], ''),
  _HeroBg('Графит', [Color(0xFF3E4A46), Color(0xFF1E2A24)], ''),
];

// ============================================================================
// ЗАГЛУШКИ: МОДЕЛИ И ЭКРАНЫ
// ============================================================================
//
// ⚠️ Эти классы нужны только пока нет реальных файлов. Как только
// появятся настоящие модели/экраны — удалите соответствующий стаб
// и добавьте импорт, иначе получите конфликт имён.
//
// ПРОВАЙДЕРЫ (FitnessProvider, NutritionProvider, PedometerProvider,
// WellnessProvider) больше НЕ стабируются — используются реальные
// из features/*/providers/*.

class WorkoutLog {
  WorkoutLog({required this.date, this.volume = 0, this.programName});
  final DateTime date;
  final double volume;
  final String? programName;
}

class Exercise {
  Exercise({required this.id, required this.name});
  final String id;
  final String name;
}

class ActiveSession {
  ActiveSession({
    required this.programName,
    required this.dayNumber,
    required this.percent,
  });
  final String programName;
  final int dayNumber;
  final double percent;
}

class FitnessTarget {
  FitnessTarget({
    required this.id,
    required this.title,
    required this.current,
    required this.target,
    required this.unit,
  });
  final String id;
  final String title;
  final double current;
  final double target;
  final String unit;
}

class WorkoutDay {
  WorkoutDay({
    required this.id,
    required this.programId,
    required this.dayNumber,
    this.exercises = const [],
  });
  final String id;
  final String programId;
  final int dayNumber;
  final List<Exercise> exercises;
}

class NutritionProgram {
  NutritionProgram({required this.id, required this.name});
  final String id;
  final String name;
}

class NutritionSummary {
  NutritionSummary({this.calories = 0, this.water = 0});
  final double calories;
  final double water;
}

class NutritionGoals {
  NutritionGoals({this.calories = 2200, this.water = 2.5});
  final double calories;
  final double water;
}

class ProfileResult {
  ProfileResult({
    required this.name,
    required this.emoji,
    this.imagePath,
  });
  final String name;
  final String emoji;
  final String? imagePath;
}

// --- Экраны-заглушки (замените реальными) ---

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmoji,
    required this.initialImagePath,
    required this.level,
    required this.streak,
    required this.totalWorkouts,
    required this.totalVolume,
  });

  final String initialName;
  final String initialEmoji;
  final String? initialImagePath;
  final int level;
  final int streak;
  final int totalWorkouts;
  final double totalVolume;

  @override
  Widget build(BuildContext context) => _StubScaffold(
    title: 'Профиль',
    body:
    'Имя: $initialName\nУровень: $level\nСерия: $streak\nТренировок: $totalWorkouts\nТоннаж: ${totalVolume.round()} кг',
  );
}

class WorkoutLogScreen extends StatelessWidget {
  const WorkoutLogScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _StubScaffold(title: 'Журнал тренировок');
}

class ActiveProgramScreen extends StatelessWidget {
  const ActiveProgramScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _StubScaffold(title: 'Активная программа');
}

class WellbeingScreen extends StatelessWidget {
  const WellbeingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _StubScaffold(title: 'Самочувствие');
}

class FitnessDashboard extends StatelessWidget {
  const FitnessDashboard({super.key});
  @override
  Widget build(BuildContext context) =>
      const _StubScaffold(title: 'Fitness Dashboard');
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) => const _StubScaffold(title: 'Прогресс');
}

class PedometerScreen extends StatelessWidget {
  const PedometerScreen({super.key});
  @override
  Widget build(BuildContext context) => const _StubScaffold(title: 'Шагомер');
}

class FitnessTargetsScreen extends StatelessWidget {
  const FitnessTargetsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _StubScaffold(title: 'Цели');
}

class FitnessTargetDetailsScreen extends StatelessWidget {
  const FitnessTargetDetailsScreen({super.key, required this.target});
  final FitnessTarget target;
  @override
  Widget build(BuildContext context) =>
      _StubScaffold(title: 'Цель: ${target.title}');
}

class FuelDashboardScreen extends StatelessWidget {
  const FuelDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => const _StubScaffold(title: 'Питание');
}

class ProgramsHubScreen extends StatelessWidget {
  const ProgramsHubScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _StubScaffold(title: 'Программы питания');
}

class PlanTrackerScreen extends StatelessWidget {
  const PlanTrackerScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _StubScaffold(title: 'План питания');
}

class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _StubScaffold(title: 'База знаний');
}

class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _StubScaffold(title: 'База упражнений');
}

class WorkoutExecutionScreen extends StatelessWidget {
  const WorkoutExecutionScreen({super.key, required this.day});
  final WorkoutDay day;
  @override
  Widget build(BuildContext context) =>
      _StubScaffold(title: 'Тренировка · ${day.id}');
}

class _StubScaffold extends StatelessWidget {
  const _StubScaffold({required this.title, this.body});
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.bg,
        elevation: 0,
        foregroundColor: _P.ink,
        title: Text(title, style: _t(size: 16, weight: FontWeight.w800)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            body ?? 'Экран-заглушка.\nЗамените реальной реализацией.',
            textAlign: TextAlign.center,
            style: _t(color: _P.muted, weight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}