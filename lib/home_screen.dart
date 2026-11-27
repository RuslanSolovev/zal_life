import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
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
import 'home_screen_light.dart';

const int _weekGoal = 7;

String _enumKey(Object value) => value.toString().split('.').last.toLowerCase();

String _exerciseEmoji(ExerciseType type) {
  final key = _enumKey(type);
  if (key.contains('strength') || key.contains('weight') || key.contains('power')) return '🏋️';
  if (key.contains('cardio') || key.contains('run')) return '🏃';
  if (key.contains('stretch') || key.contains('flex')) return '🧘';
  if (key.contains('yoga')) return '🧘‍♀️';
  if (key.contains('swim')) return '🏊';
  if (key.contains('cycle') || key.contains('bike')) return '🚴';
  if (key.contains('box') || key.contains('fight')) return '🥊';
  if (key.contains('walk')) return '🚶';
  if (key.contains('team') || key.contains('sport')) return '⚽';
  return '💪';
}

String _targetEmoji(FitnessTargetType type) {
  final key = _enumKey(type);
  if (key.contains('weight') || key.contains('mass')) return '⚖️';
  if (key.contains('strength') || key.contains('lift')) return '🏋️';
  if (key.contains('workout') || key.contains('training')) return '💪';
  if (key.contains('run') || key.contains('cardio')) return '🏃';
  if (key.contains('body') || key.contains('composition')) return '🎯';
  return '🏆';
}

Color _muscleGroupColor(MuscleGroup group) {
  final key = _enumKey(group);
  if (key.contains('chest')) return const Color(0xFFE87979);
  if (key.contains('back') || key.contains('lat')) return const Color(0xFF6E9FE8);
  if (key.contains('leg') || key.contains('quad') || key.contains('glute')) return const Color(0xFF9B83D8);
  if (key.contains('shoulder') || key.contains('delt')) return const Color(0xFFE5A45F);
  if (key.contains('arm') || key.contains('bicep') || key.contains('tricep')) return const Color(0xFFDB83B5);
  if (key.contains('core') || key.contains('ab')) return const Color(0xFF62B9A0);
  return _Zal.limeDark;
}

class _Zal {
  static const canvas = Color(0xFF090C0B);
  static const paper = Color(0xFF141A17);
  static const ink = Color(0xFFF2F5EF);
  static const muted = Color(0xFF89938D);
  static const line = Color(0xFF27312B);
  static const forest = Color(0xFF17211A);
  static const forest2 = Color(0xFF202B22);
  static const lime = Color(0xFFD4FF83);
  static const limeDark = Color(0xFFB8E968);
  static const rose = Color(0xFFFF8F9B);
  static const roseSoft = Color(0xFF24191D);
  static const sage = Color(0xFF8CD9B4);
  static const sageSoft = Color(0xFF17231D);
  static const peach = Color(0xFFFFB17A);
  static const peachSoft = Color(0xFF251D17);
  static const blue = Color(0xFF8EB8FF);
  static const yellow = Color(0xFFF0D477);
  static const dark = Color(0xFF202923);
}

const List<String> _heroBackgrounds = [
  'assets/images/nature_hero.jpg', 'assets/images/nature_hero2.jpg', 'assets/images/nature_hero3.jpg',
  'assets/images/nature_hero4.jpg', 'assets/images/nature_hero5.jpg', 'assets/images/nature_hero6.jpg',
  'assets/images/nature_hero7.jpg', 'assets/images/nature_hero8.jpg', 'assets/images/nature_hero9.jpg',
  'assets/images/nature_hero10.jpg', 'assets/images/nature_hero11.jpg', 'assets/images/nature_hero12.jpg',
  'assets/images/nature_hero13.jpg', 'assets/images/nature_hero14.jpg', 'assets/images/nature_hero15.jpg',
  'assets/images/nature_hero16.jpg', 'assets/images/nature_hero17.jpg', 'assets/images/nature_hero18.jpg',
  'assets/images/nature_hero19.jpg', 'assets/images/nature_hero20.jpg', 'assets/images/nature_hero21.jpg',
];

const List<String> _backgroundNames = [
  'Тропа', 'Закат 1', 'Закат 2', 'Закат 3', 'Лес', 'Горы', 'Закат 4',
  'Рассвет', 'Поле', 'Река', 'Озеро', 'Море', 'Пляж', 'Пустыня',
  'Водопад', 'Каньон', 'Степь', 'Тайга', 'Луг', 'Дюны', 'Утёс',
];

DateTime? _logDate(dynamic log) {
  try {
    final value = log.date;
    if (value is DateTime) return value;
  } catch (_) {}
  try {
    final value = log.startedAt;
    if (value is DateTime) return value;
  } catch (_) {}
  try {
    final value = log.createdAt;
    if (value is DateTime) return value;
  } catch (_) {}
  try {
    final value = log.performedAt;
    if (value is DateTime) return value;
  } catch (_) {}
  try {
    final value = log.timestamp;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  } catch (_) {}
  return null;
}

double _logVolume(dynamic log) {
  try {
    final value = log.totalVolume;
    if (value is num) return value.toDouble();
  } catch (_) {}
  try {
    final value = log.volume;
    if (value is num) return value.toDouble();
  } catch (_) {}
  try {
    var total = 0.0;
    final exerciseLogs = log.exercisesLog;
    if (exerciseLogs is List) {
      for (final exercise in exerciseLogs) {
        final sets = exercise.sets;
        if (sets is List) {
          for (final set in sets) {
            final weight = set.weight;
            final reps = set.reps;
            if (weight is num && reps is num) {
              total += weight.toDouble() * reps.toDouble();
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

int _statInt(Map<String, dynamic> stats, String key) {
  final value = stats[key];
  return value is num ? value.toInt() : 0;
}

double _statDouble(Map<String, dynamic> stats, String key) {
  final value = stats[key];
  return value is num ? value.toDouble() : 0;
}

int _workoutsFromLogs(FitnessProvider fitness, DateTime today) {
  final monday = DateTime(today.year, today.month, today.day - today.weekday + 1);
  var count = 0;
  for (final log in fitness.logs) {
    final date = _logDate(log);
    if (date == null) continue;
    final day = DateTime(date.year, date.month, date.day);
    if (!day.isBefore(monday) && !day.isAfter(today)) count++;
  }
  return count;
}

int _workoutsThisWeek(FitnessProvider fitness, DateTime today) {
  final fromProvider = _statInt(fitness.getStats(), 'workoutsThisWeek');
  return fromProvider > 0 ? fromProvider : _workoutsFromLogs(fitness, today);
}

class _WeekDay {
  final DateTime date;
  final int workouts;
  final double volume;
  const _WeekDay(this.date, this.workouts, this.volume);
}

List<_WeekDay> _weekDays(FitnessProvider fitness, DateTime today) {
  final monday = DateTime(today.year, today.month, today.day - today.weekday + 1);
  return List.generate(7, (index) {
    final day = monday.add(Duration(days: index));
    if (day.isAfter(DateTime(today.year, today.month, today.day))) {
      return _WeekDay(day, 0, 0);
    }
    final logs = fitness.getLogsForDate(day);
    var volume = 0.0;
    for (final log in logs) {
      volume += _logVolume(log);
    }
    return _WeekDay(day, logs.length, volume);
  });
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
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}м';
  if (value >= 10000) return '${(value / 1000).toStringAsFixed(1)}к';
  return _number(value);
}

String _compactVolume(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}м';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}к';
  return value.round().toString();
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 6) return 'Доброй ночи';
  if (hour < 12) return 'Доброе утро';
  if (hour < 18) return 'Добрый день';
  return 'Добрый вечер';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _confettiController;
  late final ScrollController _scrollController;
  late final List<_ConfettiParticle> _confettiParticles;
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;

  bool? _weekGoalWasReached;
  String _profileName = 'Спортсмен'; // Убраны _avatarEmoji и _avatarImagePath
  String _heroBackground = _heroBackgrounds[1];
  int _heroStyle = 0;
  int _pedometerBackgroundIndex = 0;
  double _tiltX = 0;
  double _tiltY = 0;

  static const String _pedometerPrefsKey = 'pedometer_bg_index';

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250))..forward();
    _confettiController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _scrollController = ScrollController();
    _confettiParticles = _makeConfetti();
    _loadPreferences();
    _listenToMotion();
  }

  void _listenToMotion() {
    try {
      _sensorSubscription = accelerometerEventStream().listen((event) {
        if (!mounted) return;
        final nextX = (event.x / 48).clamp(-1.0, 1.0).toDouble();
        final nextY = (event.y / 48).clamp(-1.0, 1.0).toDouble();
        if ((nextX - _tiltX).abs() < 0.035 && (nextY - _tiltY).abs() < 0.035) return;
        setState(() {
          _tiltX = nextX;
          _tiltY = nextY;
        });
      }, onError: (_) {});
    } catch (_) {}
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _profileName = prefs.getString('profile_name') ?? 'Спортсмен';
      _heroBackground = prefs.getString('hero_bg_image') ?? _heroBackgrounds[1];
      _heroStyle = (prefs.getInt('hero_style') ?? 0).clamp(0, 11).toInt();
      _pedometerBackgroundIndex = (prefs.getInt(_pedometerPrefsKey) ?? 0).clamp(0, _heroBackgrounds.length - 1).toInt();
    });
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _entranceController.dispose();
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_ConfettiParticle> _makeConfetti() {
    final random = math.Random(73);
    const colors = [_Zal.lime, _Zal.peach, _Zal.rose, _Zal.blue, _Zal.yellow, _Zal.sage];
    return List.generate(70, (_) => _ConfettiParticle(
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

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final pedometer = context.watch<PedometerProvider>();
    final wellness = context.watch<WellnessProvider>();
    final now = DateTime.now();
    final stats = fitness.getStats();
    final weeklyWorkouts = _workoutsThisWeek(fitness, now);
    _checkWeekGoal(weeklyWorkouts);

    return Scaffold(
      backgroundColor: _Zal.canvas,
      body: Stack(
        children: [
          SafeArea(
            top: false, bottom: false,
            child: RefreshIndicator(
              color: _Zal.forest, backgroundColor: _Zal.paper, displacement: 48,
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _heroHeader(fitness, nutrition, pedometer, stats)),
                  SliverToBoxAdapter(child: _appear(0.12, _activitySection(fitness, pedometer, weeklyWorkouts, stats))),
                  SliverToBoxAdapter(child: _appear(0.30, _nutritionSection(nutrition))),
                  SliverToBoxAdapter(child: _appear(0.47, _wellnessSection(wellness, nutrition))),
                  SliverToBoxAdapter(child: _appear(0.62, _quickStartSection(fitness))),
                  const SliverToBoxAdapter(child: SizedBox(height: 42)),
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
      child: child,
      builder: (context, content) {
        final t = ((_entranceController.value - delay) / (1 - delay)).clamp(0.0, 1.0).toDouble();
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(offset: Offset(0, 25 * (1 - eased)), child: content),
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
        return CustomPaint(size: Size.infinite, painter: _ConfettiPainter(progress, _confettiParticles));
      },
    );
  }

  Widget _heroHeader(FitnessProvider fitness, NutritionProvider nutrition, PedometerProvider pedometer, Map<String, dynamic> stats) {
    final summary = nutrition.getSummaryForDate(DateTime.now());
    final weekly = _workoutsThisWeek(fitness, DateTime.now());

    Widget metric(String value, String label, Color accent) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 22, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.0)),
              const SizedBox(height: 7),
              Row(children: [
                Container(width: 5, height: 5, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(child: Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: _Zal.muted, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: .8))),
              ]),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _openProfileScreen,
          child: Stack(
            children: [
              SizedBox(
                height: 260,
                width: double.infinity,
                child: _AppImage(path: _heroBackground, fit: BoxFit.cover, fallback: const ColoredBox(color: Color(0xFF1A2820))),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.85)],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12, left: 18, right: 18,
                child: Row(
                  children: [
                    Text('Zal Life', style: GoogleFonts.manrope(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -1.8)),
                    const SizedBox(width: 5),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: _Zal.lime, shape: BoxShape.circle)),
                    const Spacer(),
                    Material(
                      color: Colors.black.withOpacity(0.3), shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(), onTap: _openSettings,
                        child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.tune_rounded, color: Colors.white, size: 17)),
                      ),
                    ),
                  ],
                ),
              ),
              // УБРАН БЛОК С АВАТАРОМ, оставлен только текст
              Positioned(
                left: 18, right: 18, bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_greeting().toUpperCase(), style: GoogleFonts.inter(color: Colors.white.withOpacity(0.72), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
                    const SizedBox(height: 4),
                    Text(_profileName, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(color: Colors.white, fontSize: 31, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.3)),
                    const SizedBox(height: 9),
                    Text('СОЗДАЙ СЕБЯ', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.76), fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: .8)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 19, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                metric('$weekly/7', 'Тренировки', _Zal.lime),
                Container(width: 1, height: 37, color: _Zal.line),
                metric('${summary.calories.round()}', 'Ккал сегодня', _Zal.rose),
                Container(width: 1, height: 37, color: _Zal.line),
                metric(_compactNumber(pedometer.steps), 'Шаги', _Zal.blue),
              ]),
              const SizedBox(height: 19),
              Row(children: [
                Expanded(child: _editorialAction(Icons.shopping_bag_outlined, 'ПОКУПКИ', () => _openShoppingMode(nutrition), false)),
                const SizedBox(width: 9),
                Expanded(child: _editorialAction(Icons.add_rounded, 'В КЛАДОВУЮ', () => _openAddPantry(nutrition), true)),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editorialAction(IconData icon, String label, VoidCallback onTap, bool filled) {
    final foreground = filled ? const Color(0xFF10160D) : _Zal.ink;
    return Material(
      color: filled ? _Zal.lime : _Zal.paper, borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: filled ? _Zal.lime : _Zal.line)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(color: foreground, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .65)),
          ]),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _SettingsSheet(
        profileName: _profileName,
        // Вместо styleName передаем текущую тему
        themeLabel: 'Тёмная тема',
        backgroundName: _backgroundNames[_heroBackgrounds.indexOf(_heroBackground).clamp(0, 20).toInt()],
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'profile': await _openProfileScreen(); break;
      case 'theme': _switchToLightTheme(); break; // <-- Переключение темы
      case 'background': await _chooseHeroBackground(); break;
    }
  }

  void _switchToLightTheme() {
    // Плавный переход через замену роута
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreenLight(
          onToggleTheme: _switchToDarkTheme, // Кнопка назад в светлом экране
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 400),
      ),
    );
  }

  void _switchToDarkTheme() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 400),
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
          initialEmoji: '💪', // Значение по умолчанию, так как аватар убран с главного экрана
          initialImagePath: '',
          level: 1 + (_statInt(stats, 'totalWorkouts') ~/ 3),
          streak: _statInt(stats, 'currentStreak'),
          totalWorkouts: _statInt(stats, 'totalWorkouts'),
          totalVolume: _statDouble(stats, 'totalVolume'),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _profileName = result.name;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', result.name);
    HapticFeedback.lightImpact();
  }

  Future<void> _chooseHeroStyle() async {
    final selected = await showModalBottomSheet<int>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (sheetContext) => _StylePickerSheet(selected: _heroStyle),
    );
    if (!mounted || selected == null || selected == _heroStyle) return;
    setState(() => _heroStyle = selected);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hero_style', selected);
    HapticFeedback.lightImpact();
  }

  Future<void> _chooseHeroBackground() async {
    final selected = await showModalBottomSheet<String>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (sheetContext) => _BackgroundPickerSheet(selected: _heroBackground, backgrounds: _heroBackgrounds, labels: _backgroundNames),
    );
    if (!mounted || selected == null || selected == _heroBackground) return;
    setState(() => _heroBackground = selected);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hero_bg_image', selected);
    HapticFeedback.lightImpact();
  }

  Future<void> _cyclePedometerBackground() async {
    HapticFeedback.selectionClick();
    final next = (_pedometerBackgroundIndex + 1) % _heroBackgrounds.length;
    setState(() => _pedometerBackgroundIndex = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pedometerPrefsKey, next);
  }

  Widget _activitySection(FitnessProvider fitness, PedometerProvider pedometer, int weeklyWorkouts, Map<String, dynamic> stats) {
    final week = _weekDays(fitness, DateTime.now());
    final badges = _earnedBadges(stats);
    final records = _personalRecords(fitness, stats);
    return _SectionBlock(
      number: '01', title: 'Активность', subtitle: 'Движение формирует результат', accent: _Zal.limeDark,
      action: 'Журнал', onAction: _openWorkoutLog,
      children: [
        _workoutFocusCard(fitness),
        const SizedBox(height: 13),
        SizedBox(
          height: 224,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _weekCard(fitness, week, weeklyWorkouts)),
              const SizedBox(width: 11),
              Expanded(child: _streakCard(stats)),
            ],
          ),
        ),
        const SizedBox(height: 13),
        _pedometerCard(pedometer),
        const SizedBox(height: 13),
        _weeklyAnalyticsCard(fitness, week, stats),
        if (badges.isNotEmpty) ...[const SizedBox(height: 17), _horizontalTagList('ДОСТИЖЕНИЯ', badges)],
        if (records.isNotEmpty) ...[const SizedBox(height: 17), _horizontalTagList('ЛИЧНЫЕ РЕКОРДЫ', records)],
        const SizedBox(height: 15),
        _targetsBlock(fitness),
      ],
    );
  }

  Widget _workoutFocusCard(FitnessProvider fitness) {
    final session = fitness.activeSession;
    final wellbeing = fitness.getTodayWellbeing();
    WorkoutProgram? activeProgram;
    if (session != null) {
      try { activeProgram = fitness.programs.firstWhere((program) => program.id == session.programId); } catch (_) {}
    }

    late final String eyebrow;
    late final String title;
    late final String description;
    late final String buttonLabel;
    late final IconData icon;
    late final VoidCallback onTap;

    if (session != null) {
      eyebrow = 'ПРОДОЛЖИТЬ ПУТЬ';
      title = activeProgram?.name ?? 'Активная тренировка';
      description = 'День ${session.currentDayIndex + 1}  ·  ${(session.progressPercent * 100).round()}% выполнено';
      buttonLabel = 'Продолжить';
      icon = Icons.play_arrow_rounded;
      onTap = () {
        HapticFeedback.lightImpact();
        if (activeProgram == null) { _quickStartWorkout(fitness); return; }
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: fitness, child: ActiveProgramScreen(program: activeProgram!, isDark: false))));
      };
    } else if (wellbeing == null) {
      eyebrow = 'ПЕРЕД СТАРТОМ';
      title = 'Как ты сегодня?';
      description = 'Отметь самочувствие — подберём подходящую нагрузку';
      buttonLabel = 'Отметить состояние';
      icon = Icons.spa_rounded;
      onTap = _openWellbeing;
    } else {
      eyebrow = 'ВРЕМЯ ДЛЯ СЕБЯ';
      title = 'Сделай сегодня сильнее';
      description = 'Собери короткую тренировку из любимых упражнений';
      buttonLabel = 'Начать тренировку';
      icon = Icons.bolt_rounded;
      onTap = () => _quickStartWorkout(fitness);
    }

    final progress = session == null ? 0.0 : session.progressPercent.clamp(0.0, 1.0).toDouble();

    final targetBg = activeProgram?.backgroundImage ?? _heroBackground;
    final hasBg = targetBg != null && targetBg.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: _Zal.forest.withOpacity(0.17), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasBg)
            Positioned.fill(child: _AppImage(path: targetBg, fit: BoxFit.cover, fallback: const ColoredBox(color: _Zal.forest))),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: hasBg ? [Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.85)] : [_Zal.forest, _Zal.forest2],
                ),
              ),
            ),
          ),
          if (!hasBg)
            Positioned(right: -14, top: -38, child: Icon(Icons.fitness_center_rounded, size: 176, color: Colors.white.withOpacity(0.045))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 33, height: 33,
                      decoration: BoxDecoration(color: _Zal.lime.withOpacity(0.16), borderRadius: BorderRadius.circular(11)),
                      child: Icon(icon, color: _Zal.lime, size: 19),
                    ),
                    const SizedBox(width: 10),
                    Text(eyebrow, style: GoogleFonts.inter(color: _Zal.lime, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    const Spacer(),
                    if (session != null) Text('${(progress * 100).round()}%', style: GoogleFonts.manrope(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 18),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: Colors.white, fontSize: 23, height: 1.08, fontWeight: FontWeight.w800, letterSpacing: -0.55)),
                const SizedBox(height: 7),
                Text(description, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.69), fontSize: 12, height: 1.45)),
                if (session != null) ...[
                  const SizedBox(height: 16),
                  _ProgressTrack(value: progress, color: _Zal.lime, trackColor: Colors.white.withOpacity(0.14), height: 6),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: FilledButton.icon(
                    onPressed: () { HapticFeedback.selectionClick(); onTap(); },
                    icon: Icon(icon, size: 19),
                    label: Text(buttonLabel, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800)),
                    style: FilledButton.styleFrom(
                      foregroundColor: _Zal.forest, backgroundColor: _Zal.lime,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  Widget _weekCard(FitnessProvider fitness, List<_WeekDay> week, int weeklyWorkouts) {
    final todayWeekday = DateTime.now().weekday - 1;
    final progress = (weeklyWorkouts / _weekGoal).clamp(0.0, 1.0).toDouble();
    const labels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    return _PressCard(
      onTap: _openFitness, padding: const EdgeInsets.fromLTRB(15, 15, 13, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const _TinyIcon(icon: Icons.calendar_month_rounded, color: _Zal.limeDark, background: _Zal.sageSoft), const Spacer(), Icon(Icons.north_east_rounded, color: _Zal.muted.withOpacity(0.8), size: 15)]),
          const SizedBox(height: 13),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$weeklyWorkouts', style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 31, fontWeight: FontWeight.w800, height: 1)),
            Padding(padding: const EdgeInsets.only(left: 4, bottom: 3), child: Text('/ 7', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 4),
          Text('тренировок за неделю', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 10.5)),
          const SizedBox(height: 12),
          _ProgressTrack(value: progress, color: _Zal.limeDark, trackColor: _Zal.line, height: 6),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final didTrain = week[i].workouts > 0;
              final isToday = i == todayWeekday;
              return Column(
                children: [
                  Container(
                    width: 21, height: 21,
                    decoration: BoxDecoration(
                      color: didTrain ? _Zal.limeDark : (isToday ? _Zal.ink : _Zal.canvas),
                      shape: BoxShape.circle,
                      border: isToday && !didTrain ? Border.all(color: _Zal.limeDark, width: 1.5) : null,
                    ),
                    child: Icon(didTrain ? Icons.check_rounded : (isToday ? Icons.circle : Icons.remove_rounded), size: didTrain ? 13 : 7, color: didTrain || isToday ? Colors.white : _Zal.muted.withOpacity(0.45)),
                  ),
                  const SizedBox(height: 5),
                  Text(labels[i], style: GoogleFonts.inter(color: isToday ? _Zal.limeDark : _Zal.muted, fontSize: 8, fontWeight: FontWeight.w800)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _streakCard(Map<String, dynamic> stats) {
    final streak = _statInt(stats, 'currentStreak');
    final progress = (streak / 30).clamp(0.0, 1.0).toDouble();
    return _PressCard(
      onTap: _openProgress, color: _Zal.peachSoft, padding: const EdgeInsets.fromLTRB(15, 15, 13, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const _TinyIcon(icon: Icons.local_fire_department_rounded, color: _Zal.peach, background: Color(0xFF3A261D)), const Spacer(), Icon(Icons.north_east_rounded, color: _Zal.muted.withOpacity(0.8), size: 15)]),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 103, height: 103,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(value: progress, strokeWidth: 7, strokeCap: StrokeCap.round, backgroundColor: _Zal.line, valueColor: const AlwaysStoppedAnimation(_Zal.peach)),
                    ),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('$streak', style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 34, fontWeight: FontWeight.w800, height: 1)),
                      Text('дней', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 10, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          Center(child: Text(streak >= 30 ? 'Легендарный ритм' : (streak >= 7 ? 'Отличная серия' : 'Начни свою серию'), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _Zal.peach, fontSize: 10, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Widget _pedometerCard(PedometerProvider pedometer) {
    final progress = pedometer.progress.clamp(0.0, 1.0).toDouble();
    final path = _heroBackgrounds[_pedometerBackgroundIndex];
    return GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: _openPedometer,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          height: 186,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _AppImage(path: path, fit: BoxFit.cover, fallback: const ColoredBox(color: _Zal.forest2)),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xE6102119), Color(0xA0102119), Color(0x33102119)]))),
              Padding(
                padding: const EdgeInsets.fromLTRB(19, 16, 18, 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_walk_rounded, color: _Zal.lime, size: 21),
                        const SizedBox(width: 9),
                        Text('ДНЕВНАЯ ДИСТАНЦИЯ', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
                        const Spacer(),
                        Material(
                          color: Colors.white.withOpacity(0.15), shape: const CircleBorder(),
                          child: InkWell(customBorder: const CircleBorder(), onTap: _cyclePedometerBackground, child: const Padding(padding: EdgeInsets.all(9), child: Icon(Icons.wallpaper_rounded, color: Colors.white, size: 17))),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_number(pedometer.steps), style: GoogleFonts.manrope(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1)),
                      const SizedBox(width: 8),
                      Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('/ ${_number(pedometer.goal)} шагов', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.69), fontSize: 11, fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 5),
                    Text('${pedometer.distanceKm.toStringAsFixed(1)} км  ·  осталось ${_number(pedometer.remaining)} шагов', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.82), fontSize: 11)),
                    const SizedBox(height: 13),
                    _ProgressTrack(value: progress, color: _Zal.lime, trackColor: Colors.white.withOpacity(0.22), height: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weeklyAnalyticsCard(FitnessProvider fitness, List<_WeekDay> week, Map<String, dynamic> stats) {
    final hasData = week.any((day) => day.workouts > 0);
    final totalVolume = week.fold<double>(0, (sum, day) => sum + day.volume);
    final activeDays = week.where((day) => day.workouts > 0).length;
    final average = totalVolume / 7;
    final streak = _statInt(stats, 'currentStreak');
    var bestIndex = -1;
    var bestVolume = 0.0;
    for (var i = 0; i < week.length; i++) {
      if (week[i].volume > bestVolume) { bestVolume = week[i].volume; bestIndex = i; }
    }
    const labels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_Zal.forest, _Zal.dark]),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _Zal.line.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: _Zal.lime.withOpacity(0.03), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_Zal.lime.withOpacity(0.08), Colors.transparent])),
            ),
          ),
          Positioned(
            left: -30, bottom: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_Zal.sage.withOpacity(0.06), Colors.transparent])),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _TinyIcon(icon: Icons.query_stats_rounded, color: _Zal.lime, background: Color(0x263DDC84)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('НЕДЕЛЬНЫЙ ОТЧЁТ', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.48), fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text('Объём и регулярность', style: GoogleFonts.manrope(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                      child: Text('🔥 $streak', style: GoogleFonts.inter(color: _Zal.peach, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
              const SizedBox(height: 17),
              if (!hasData)
                _analyticsEmpty()
              else ...[
                Row(
                  children: [
                    Expanded(child: _DarkMetric(value: '${_compactVolume(totalVolume)} кг', label: 'ТОННАЖ', icon: '↗', color: _Zal.lime)),
                    const SizedBox(width: 8),
                    Expanded(child: _DarkMetric(value: '${_compactVolume(average)} кг', label: 'СРЕДНЕЕ / ДЕНЬ', icon: '∿', color: _Zal.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _DarkMetric(value: '$activeDays / 7', label: 'АКТИВНЫЕ ДНИ', icon: '◷', color: _Zal.peach)),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(height: 128, width: double.infinity, child: CustomPaint(painter: _WeeklyChartPainter(week.map((day) => day.volume).toList()))),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) => Text(labels[i], style: GoogleFonts.inter(color: i == DateTime.now().weekday - 1 ? _Zal.lime : Colors.white.withOpacity(0.43), fontSize: 8, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(height: 15),
                Container(height: 1, color: Colors.white.withOpacity(0.09)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: _Zal.yellow, size: 16),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        bestIndex >= 0 ? 'Лучший день: ${labels[bestIndex]} · ${_compactVolume(bestVolume)} кг' : 'Продолжай — здесь появится твой лучший день',
                        style: GoogleFonts.inter(color: Colors.white.withOpacity(0.78), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('$streak дн. серия', style: GoogleFonts.inter(color: _Zal.peach, fontSize: 9, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _analyticsEmpty() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.045), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.07))),
      child: Column(
        children: [
          Icon(Icons.insights_rounded, color: _Zal.lime.withOpacity(0.8), size: 27),
          const SizedBox(height: 8),
          Text('Пока нет данных для графика', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Проведи первую тренировку — и мы покажем динамику', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.52), fontSize: 10, height: 1.4)),
        ],
      ),
    );
  }

  List<_AchievementData> _earnedBadges(Map<String, dynamic> stats) {
    final workouts = _statInt(stats, 'totalWorkouts');
    final streak = _statInt(stats, 'currentStreak');
    final volume = _statDouble(stats, 'totalVolume');
    final result = <_AchievementData>[];
    if (workouts >= 1) result.add(const _AchievementData('🏅', 'Первый шаг', 'Первая тренировка', _Zal.peach));
    if (streak >= 7) result.add(const _AchievementData('🔥', 'Неделя', '7 дней подряд', _Zal.rose));
    if (workouts >= 10) result.add(const _AchievementData('💪', 'Десятка', '10 тренировок', _Zal.limeDark));
    if (volume >= 1000) result.add(const _AchievementData('⚡', 'Тонна', '1 000 кг объёма', _Zal.yellow));
    if (streak >= 30) result.add(const _AchievementData('👑', 'Месяц', '30 дней подряд', _Zal.sage));
    return result;
  }

  List<_RecordData> _personalRecords(FitnessProvider fitness, Map<String, dynamic> stats) {
    final records = <_RecordData>[];
    var maxWorkoutVolume = 0.0;
    final byDay = <String, int>{};
    for (final log in fitness.logs) {
      maxWorkoutVolume = math.max(maxWorkoutVolume, _logVolume(log)).toDouble();
      final date = _logDate(log);
      if (date == null) continue;
      final key = '${date.year}-${date.month}-${date.day}';
      byDay[key] = (byDay[key] ?? 0) + 1;
    }
    if (maxWorkoutVolume > 0) records.add(_RecordData('⚡', _compactVolume(maxWorkoutVolume), 'кг за тренировку'));
    if (byDay.isNotEmpty) {
      final maxPerDay = byDay.values.reduce((a, b) => a > b ? a : b);
      if (maxPerDay > 0) records.add(_RecordData('🏋️', '$maxPerDay', 'тренировок за день'));
    }
    final totalWorkouts = _statInt(stats, 'totalWorkouts');
    final totalVolume = _statDouble(stats, 'totalVolume');
    if (totalWorkouts > 0) records.add(_RecordData('🎯', _compactNumber(totalWorkouts), 'всего тренировок'));
    if (totalVolume > 0) records.add(_RecordData('🔥', '${_compactVolume(totalVolume)} кг', 'общий тоннаж'));
    return records;
  }

  Widget _horizontalTagList(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 2, bottom: 9), child: Text(title, style: GoogleFonts.inter(color: _Zal.muted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4))),
        SizedBox(
          height: 83,
          child: ListView.separated(
            scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              if (item is _AchievementData) {
                return Container(
                  width: 142, padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(color: _Zal.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: _Zal.line)),
                  child: Row(
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 23)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _Zal.ink, fontSize: 11, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _Zal.muted, fontSize: 9, height: 1.25)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              final record = item as _RecordData;
              return Container(
                width: 142, padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: _Zal.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: _Zal.line)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [Text(record.emoji, style: const TextStyle(fontSize: 15)), const SizedBox(width: 6), Expanded(child: Text(record.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 17, fontWeight: FontWeight.w800))) ]),
                    const SizedBox(height: 3),
                    Text(record.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _Zal.muted, fontSize: 9, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _targetsBlock(FitnessProvider fitness) {
    final targets = fitness.activeTargets;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_Zal.paper, _Zal.canvas]),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _Zal.line),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10, top: -10,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_Zal.peach.withOpacity(0.08), Colors.transparent])),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Мои цели', style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 16, fontWeight: FontWeight.w800))),
                  TextButton(
                    onPressed: _openTargets,
                    style: TextButton.styleFrom(foregroundColor: _Zal.limeDark, padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: Text(targets.isEmpty ? 'Добавить' : 'Изменить', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              if (targets.isEmpty)
                InkWell(
                  onTap: _openTargets, borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: _Zal.canvas, borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      children: [
                        const _TinyIcon(icon: Icons.add_rounded, color: _Zal.limeDark, background: _Zal.sageSoft),
                        const SizedBox(width: 11),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Поставь первую цель', style: GoogleFonts.inter(color: _Zal.ink, fontSize: 12, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text('Например, новый личный рекорд', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 10)),
                        ])),
                        const Icon(Icons.chevron_right_rounded, color: _Zal.muted),
                      ],
                    ),
                  ),
                )
              else
                ...targets.take(3).map((target) => _targetRow(target, fitness)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _targetRow(FitnessTarget target, FitnessProvider fitness) {
    Exercise? exercise;
    final exerciseId = target.exerciseId;
    if (exerciseId != null && exerciseId.isNotEmpty) {
      try { exercise = fitness.exercises.firstWhere((item) => item.id == exerciseId); } catch (_) {}
    }
    final imagePath = exercise?.imageUrl;
    final emoji = exercise != null ? _exerciseEmoji(exercise.exerciseType) : _targetEmoji(target.type);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: fitness, child: FitnessTargetDetailsScreen(target: target, isDark: false))));
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 43, height: 43, clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: target.accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
                  child: imagePath != null && imagePath.isNotEmpty
                      ? _AppImage(path: imagePath, fit: BoxFit.cover, fallback: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))))
                      : Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(target.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _Zal.ink, fontSize: 12, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('Прогресс · ${(target.progressPercent * 100).round()}%', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 10)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_outward_rounded, color: _Zal.muted, size: 16),
              ],
            ),
            const SizedBox(height: 9),
            _ProgressTrack(value: target.progressPercent.clamp(0.0, 1.0).toDouble(), color: target.accentColor, trackColor: _Zal.line, height: 5),
          ],
        ),
      ),
    );
  }

  Widget _nutritionSection(NutritionProvider nutrition) {
    final today = DateTime.now();
    final summary = nutrition.getSummaryForDate(today);
    final goals = nutrition.getGoalsForDate(today);
    final kcalGoal = goals.calories.toDouble();
    final kcal = summary.calories.toDouble();
    final waterGoal = goals.waterMl.toDouble();
    final water = summary.waterMl.toDouble();
    final kcalProgress = kcalGoal <= 0 ? 0.0 : kcal / kcalGoal;
    final waterProgress = waterGoal <= 0 ? 0.0 : water / waterGoal;
    final program = nutrition.activeProgram;

    return _SectionBlock(
      number: '02', title: 'Питание', subtitle: 'Еда — тоже часть прогресса', accent: _Zal.rose,
      action: 'Подробнее', onAction: _openNutrition,
      children: [
        if (program == null)
          _PressCard(
            onTap: _openProgramsHub, color: _Zal.roseSoft, padding: const EdgeInsets.all(19),
            child: Row(
              children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(color: _Zal.rose.withOpacity(0.2), borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFB94E43), size: 25)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Создай программу питания', style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Настрой цели и следи за балансом дня', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 11, height: 1.35)),
                ])),
                const Icon(Icons.arrow_forward_rounded, color: _Zal.rose, size: 19),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: _openPlanTracker,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                children: [
                  if (program.backgroundImage != null && program.backgroundImage!.isNotEmpty)
                    Positioned.fill(
                      child: _AppImage(path: program.backgroundImage, fit: BoxFit.cover, fallback: const ColoredBox(color: _Zal.paper)),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: (program.backgroundImage != null && program.backgroundImage!.isNotEmpty)
                              ? [Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.85)]
                              : [_Zal.paper, _Zal.canvas],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(19),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12)
                              ),
                              child: const Icon(Icons.restaurant_rounded, color: _Zal.rose, size: 19),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ТВОЯ ПРОГРАММА', style: GoogleFonts.inter(color: _Zal.rose, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                                      Text(program.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                    ]
                                )
                            ),
                            const Icon(Icons.north_east_rounded, color: Colors.white70, size: 17),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${kcal.round()}', style: GoogleFonts.manrope(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1)),
                                  const SizedBox(height: 4),
                                  Text('из ${kcalGoal.round()} ккал', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 10),
                                  Text(
                                      kcal > kcalGoal ? 'Перебор на ${(kcal - kcalGoal).round()} ккал' : 'Осталось ${(kcalGoal - kcal).round().clamp(0, 999999)} ккал',
                                      style: GoogleFonts.inter(color: _Zal.rose, fontSize: 11, fontWeight: FontWeight.w800)
                                  ),
                                  const SizedBox(height: 10),
                                  _ProgressTrack(value: kcalProgress.clamp(0.0, 1.0).toDouble(), color: _Zal.rose, trackColor: Colors.white.withOpacity(0.2), height: 7),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            _ProgressRing(value: kcalProgress.clamp(0.0, 1.0).toDouble(), size: 84, color: _Zal.rose, track: Colors.white.withOpacity(0.2), label: '${(kcalProgress * 100).round()}%'),
                          ],
                        ),
                      ],
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
              child: _PressCard(
                onTap: _openNutrition, color: _Zal.roseSoft, padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Icon(Icons.local_fire_department_rounded, color: Color(0xFFB94E43), size: 19), const Spacer(), const Icon(Icons.arrow_outward_rounded, color: _Zal.muted, size: 14)]),
                    const SizedBox(height: 15),
                    Text('${kcal.round()}', style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 27, fontWeight: FontWeight.w800, height: 1)),
                    const SizedBox(height: 4),
                    Text('из ${kcalGoal.round()} ккал', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 13),
                    _ProgressTrack(value: kcalProgress.clamp(0.0, 1.0).toDouble(), color: _Zal.rose, trackColor: _Zal.line, height: 6),
                    const SizedBox(height: 8),
                    Text(kcal > kcalGoal ? 'Цель превышена' : 'Осталось ${(kcalGoal - kcal).round().clamp(0, 999999)} ккал', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 9, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _PressCard(
                onTap: _openNutrition, color: _Zal.paper, padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Icon(Icons.water_drop_rounded, color: _Zal.blue, size: 19), const Spacer(), const Icon(Icons.arrow_outward_rounded, color: _Zal.muted, size: 14)]),
                    const SizedBox(height: 15),
                    Text('${(water / 1000).toStringAsFixed(1)} л', style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 27, fontWeight: FontWeight.w800, height: 1)),
                    const SizedBox(height: 4),
                    Text('из ${(waterGoal / 1000).toStringAsFixed(1)} л воды', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 5, runSpacing: 5,
                      children: List.generate(8, (index) {
                        final filled = waterGoal > 0 && index < (waterProgress * 8).ceil();
                        return Icon(Icons.water_drop_rounded, size: 14, color: filled ? _Zal.blue : _Zal.line);
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(waterGoal > 0 && water >= waterGoal ? 'Норма выполнена' : 'Вода в течение дня', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 9, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _wellnessSection(WellnessProvider wellness, NutritionProvider nutrition) {
    return _SectionBlock(
      number: '03', title: 'Здоровье и знания', subtitle: 'Забота о себе — не только тренировки', accent: _Zal.sage,
      action: 'База знаний', onAction: _openKnowledge,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SeasonVineCard(
            wellness: wellness, nutrition: nutrition,
            scale: (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2).toDouble(),
            onOpenKnowledge: _openKnowledge,
          ),
        ),
      ],
    );
  }

  Widget _quickStartSection(FitnessProvider fitness) {
    final actions = <_QuickActionData>[
      _QuickActionData(Icons.bolt_rounded, 'Старт', _Zal.limeDark, () => _quickStartWorkout(fitness)),
      _QuickActionData(Icons.history_rounded, 'Журнал', _Zal.peach, _openWorkoutLog),
      _QuickActionData(Icons.fitness_center_rounded, 'База', _Zal.sage, _openExerciseLibrary),
      _QuickActionData(Icons.spa_rounded, 'Настрой', _Zal.rose, _openWellbeing),
      _QuickActionData(Icons.flag_rounded, 'Цели', _Zal.yellow, _openTargets),
    ];
    return _SectionBlock(
      number: '04', title: 'Быстрый старт', subtitle: 'Нужное — в одно касание', accent: _Zal.peach,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 14),
          decoration: BoxDecoration(color: _Zal.paper, borderRadius: BorderRadius.circular(23), border: Border.all(color: _Zal.line)),
          child: Row(
            children: actions.map((action) => Expanded(
              child: InkWell(
                onTap: () { HapticFeedback.selectionClick(); action.onTap(); },
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 46, height: 46, decoration: BoxDecoration(color: action.color.withOpacity(0.14), borderRadius: BorderRadius.circular(15)), child: Icon(action.icon, color: action.color, size: 21)),
                      const SizedBox(height: 7),
                      Text(action.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _Zal.ink, fontSize: 9, fontWeight: FontWeight.w800)),
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

  Future<void> _quickStartWorkout(FitnessProvider provider) async {
    HapticFeedback.mediumImpact();
    final searchController = TextEditingController();
    final selectedExercises = <Exercise>[];

    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = provider.exercises.where((exercise) => query.isEmpty || exercise.name.toLowerCase().contains(query)).toList();
            return Container(
              height: MediaQuery.sizeOf(sheetContext).height * 0.86,
              decoration: const BoxDecoration(color: _Zal.canvas, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 11, 18, 12),
                  child: Column(
                    children: [
                      Container(width: 38, height: 4, decoration: BoxDecoration(color: _Zal.line, borderRadius: BorderRadius.circular(5))),
                      const SizedBox(height: 17),
                      Row(
                        children: [
                          Container(width: 43, height: 43, decoration: BoxDecoration(color: _Zal.lime.withOpacity(0.35), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.bolt_rounded, color: _Zal.forest, size: 23)),
                          const SizedBox(width: 11),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Быстрая тренировка', style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('Выбери упражнения для своей сессии', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 10)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(color: _Zal.paper, borderRadius: BorderRadius.circular(20)),
                            child: Text('${selectedExercises.length} выбрано', style: GoogleFonts.inter(color: _Zal.forest, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: searchController, onChanged: (_) => setSheetState(() {}),
                        style: GoogleFonts.inter(color: _Zal.ink, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Найти упражнение…', hintStyle: GoogleFonts.inter(color: _Zal.muted, fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded, color: _Zal.muted, size: 20),
                          suffixIcon: searchController.text.isEmpty ? null : IconButton(
                            tooltip: 'Очистить поиск', onPressed: () { searchController.clear(); setSheetState(() {}); HapticFeedback.selectionClick(); },
                            icon: const Icon(Icons.close_rounded, color: _Zal.muted, size: 18),
                          ),
                          filled: true, fillColor: _Zal.paper, contentPadding: const EdgeInsets.symmetric(vertical: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _Zal.line)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: _Zal.limeDark, width: 1.3)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(child: Text('Упражнения не найдены', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 12)))
                            : ListView.separated(
                          physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(bottom: 105),
                          itemCount: filtered.length, separatorBuilder: (_, __) => const SizedBox(height: 7),
                          itemBuilder: (context, index) {
                            final exercise = filtered[index];
                            final isSelected = selectedExercises.any((item) => item.id == exercise.id);
                            final muscleColor = exercise.muscleGroups.isNotEmpty ? _muscleGroupColor(exercise.muscleGroups.first) : _Zal.limeDark;
                            final imagePath = exercise.imageUrl;
                            return Material(
                              color: _Zal.paper, borderRadius: BorderRadius.circular(16),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? _Zal.limeDark.withOpacity(0.6) : _Zal.line, width: isSelected ? 1.3 : 0.8)),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46, height: 46, clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(color: muscleColor.withOpacity(0.13), borderRadius: BorderRadius.circular(13)),
                                        child: imagePath != null && imagePath.isNotEmpty
                                            ? _AppImage(path: imagePath, fit: BoxFit.cover, fallback: Center(child: Text(_exerciseEmoji(exercise.exerciseType), style: const TextStyle(fontSize: 21))))
                                            : Center(child: Text(_exerciseEmoji(exercise.exerciseType), style: const TextStyle(fontSize: 21))),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(child: Text(exercise.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _Zal.ink, fontSize: 12, fontWeight: FontWeight.w700))),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 28, height: 28, decoration: BoxDecoration(color: isSelected ? _Zal.lime : _Zal.canvas, shape: BoxShape.circle),
                                        child: Icon(isSelected ? Icons.check_rounded : Icons.add_rounded, color: isSelected ? _Zal.lime : _Zal.muted, size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 9),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: FilledButton(
                          onPressed: selectedExercises.isEmpty ? null : () {
                            final timestamp = DateTime.now().millisecondsSinceEpoch;
                            final quickDay = WorkoutDay(
                              id: 'quick_$timestamp', programId: 'quick', dayNumber: 1,
                              exercises: List.generate(selectedExercises.length, (index) {
                                final exercise = selectedExercises[index];
                                return WorkoutExercise(id: 'quick_ex_${timestamp}_$index', exerciseId: exercise.id, order: index, sets: [ExerciseSet(setNumber: 1, reps: 10, weight: 0)]);
                              }),
                            );
                            Navigator.pop(sheetContext);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: provider, child: WorkoutExecutionScreen(day: quickDay, isDark: false))));
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _Zal.lime, disabledBackgroundColor: _Zal.dark, foregroundColor: _Zal.forest, disabledForegroundColor: _Zal.muted,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, size: 20),
                              const SizedBox(width: 7),
                              Text(selectedExercises.isEmpty ? 'Добавь упражнения' : 'НАЧАТЬ · ${selectedExercises.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.7)),
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

  void _openKnowledge() {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => MultiProvider(providers: [ChangeNotifierProvider.value(value: context.read<WellnessProvider>()), ChangeNotifierProvider.value(value: context.read<NutritionProvider>())], child: const KnowledgeScreen())));
  }

  void _openShoppingMode(NutritionProvider nutrition) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: nutrition, child: const ShoppingModeScreen())));
  }

  void _openAddPantry(NutritionProvider nutrition) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: nutrition, child: const AddPantryScreen())));
  }

  void _openFitness() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const FitnessDashboard(isDark: true))));
  void _openNutrition() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<NutritionProvider>(), child: const FuelDashboardScreen(isDark: true))));
  void _openWorkoutLog() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const WorkoutLogScreen(isDark: true))));
  void _openTargets() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const FitnessTargetsScreen(isDark: true))));
  void _openExerciseLibrary() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const ExerciseLibraryScreen(isDark: true))));
  void _openWellbeing() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const WellbeingScreen(isDark: true))));
  void _openProgress() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: const ProgressScreen(isDark: true))));
  void _openPedometer() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<PedometerProvider>(), child: const PedometerScreen(isDark: true))));
  void _openProgramsHub() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<NutritionProvider>(), child: const ProgramsHubScreen())));
  void _openPlanTracker() => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<NutritionProvider>(), child: const PlanTrackerScreen())));
}

class _SectionBlock extends StatelessWidget {
  final String number; final String title; final String subtitle; final Color accent;
  final String? action; final VoidCallback? onAction; final List<Widget> children;
  const _SectionBlock({required this.number, required this.title, required this.subtitle, required this.accent, this.action, this.onAction, required this.children});

  @override
  Widget build(BuildContext context) {
    final callback = onAction; final actionLabel = action;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(width: 3, height: 35, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Text(number, style: GoogleFonts.inter(color: accent, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                      const SizedBox(width: 8),
                      Text(title, style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 21, height: 1, fontWeight: FontWeight.w800, letterSpacing: -.7)),
                    ]),
                    const SizedBox(height: 5),
                    Text(subtitle, style: GoogleFonts.inter(color: _Zal.muted, fontSize: 10, height: 1.2)),
                  ],
                ),
              ),
              if (callback != null && actionLabel != null)
                Material(
                  color: _Zal.paper, borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30), onTap: () { HapticFeedback.selectionClick(); callback(); },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Text(actionLabel, style: GoogleFonts.inter(color: _Zal.ink, fontSize: 9, fontWeight: FontWeight.w700)), const SizedBox(width: 5), const Icon(Icons.arrow_outward_rounded, color: _Zal.muted, size: 12)]),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 17), ...children,
        ],
      ),
    );
  }
}

class _PressCard extends StatelessWidget {
  final Widget child; final VoidCallback? onTap; final Color color; final EdgeInsets padding;
  const _PressCard({required this.child, this.onTap, this.color = _Zal.paper, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color, borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap == null ? null : () { HapticFeedback.selectionClick(); onTap!(); },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), border: Border.all(color: _Zal.line, width: 1)),
          child: child,
        ),
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  final double value; final Color color; final Color trackColor; final double height;
  const _ProgressTrack({required this.value, required this.color, required this.trackColor, this.height = 6});

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: trackColor)),
              AnimatedContainer(
                duration: const Duration(milliseconds: 750), curve: Curves.easeOutCubic,
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
              ),
              if (progress > 0.025)
                Positioned(
                  left: (constraints.maxWidth * progress - height * 0.72).clamp(0.0, constraints.maxWidth).toDouble(),
                  top: height * 0.16,
                  child: Container(width: height * 0.68, height: height * 0.68, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double value; final double size; final Color color; final Color track; final String label;
  const _ProgressRing({required this.value, required this.size, required this.color, required this.track, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value), duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic,
              builder: (_, animated, __) => CircularProgressIndicator(value: animated, strokeWidth: 7, strokeCap: StrokeCap.round, backgroundColor: track, valueColor: AlwaysStoppedAnimation(color)),
            ),
          ),
          Text(label, style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 15, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _TinyIcon extends StatelessWidget {
  final IconData icon; final Color color; final Color background;
  const _TinyIcon({required this.icon, required this.color, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(.045))),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

class _DarkMetric extends StatelessWidget {
  final String value; final String label; final String icon; final Color color;
  const _DarkMetric({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 10, 7, 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.055), borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white.withOpacity(0.055))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: GoogleFonts.manrope(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.46), fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _AppImage extends StatelessWidget {
  final String? path; final BoxFit fit; final Widget? fallback;
  const _AppImage({this.path, this.fit = BoxFit.cover, this.fallback});

  @override
  Widget build(BuildContext context) {
    final source = path; final placeholder = fallback ?? const SizedBox.shrink();
    if (source == null || source.isEmpty) return placeholder;
    if (source.startsWith('assets/')) return Image.asset(source, fit: fit, errorBuilder: (_, __, ___) => placeholder);
    if (source.startsWith('http://') || source.startsWith('https://')) return CachedNetworkImage(imageUrl: source, fit: fit, placeholder: (_, __) => placeholder, errorWidget: (_, __, ___) => placeholder);
    return Image.file(File(source), fit: fit, errorBuilder: (_, __, ___) => placeholder);
  }
}

class _AchievementData {
  final String emoji; final String title; final String description; final Color color;
  const _AchievementData(this.emoji, this.title, this.description, this.color);
}

class _RecordData {
  final String emoji; final String value; final String label;
  const _RecordData(this.emoji, this.value, this.label);
}

class _QuickActionData {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QuickActionData(this.icon, this.label, this.color, this.onTap);
}

class _ConfettiParticle {
  final double x, y, drift, speed, rotation, spin, width, height; final Color color;
  const _ConfettiParticle({required this.x, required this.y, required this.drift, required this.speed, required this.rotation, required this.spin, required this.width, required this.height, required this.color});
}

class _ConfettiPainter extends CustomPainter {
  final double progress; final List<_ConfettiParticle> particles;
  const _ConfettiPainter(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final t = (progress * particle.speed).clamp(0.0, 1.15).toDouble();
      final x = particle.x * size.width + particle.drift * t + math.sin(t * 8 + particle.rotation) * 13;
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
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _WeeklyChartPainter extends CustomPainter {
  final List<double> values;
  const _WeeklyChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalPadding = 6.0; const gap = 12.0;
    final count = values.length; if (count == 0) return;
    final maxValue = values.fold<double>(0, (a, b) => math.max(a, b).toDouble());
    final barWidth = (size.width - horizontalPadding * 2 - gap * (count - 1)) / count;
    final baseline = size.height - 4;
    final linePaint = Paint()..color = Colors.white.withOpacity(0.10)..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), linePaint);
    for (var i = 0; i < count; i++) {
      final value = values[i];
      final normalized = maxValue <= 0 ? 0.035 : (value / maxValue).clamp(0.035, 1.0).toDouble();
      final barHeight = (size.height - 15) * normalized;
      final x = horizontalPadding + i * (barWidth + gap);
      final rect = Rect.fromLTWH(x, baseline - barHeight, barWidth, barHeight);
      final color = value <= 0 ? Colors.white.withOpacity(0.10) : (i == DateTime.now().weekday - 1 ? _Zal.peach : (value == maxValue ? _Zal.lime : _Zal.sage));
      final paint = Paint()..color = color;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(7)), paint);
      if (value > 0) {
        final dotPaint = Paint()..color = Colors.white.withOpacity(0.66);
        canvas.drawCircle(Offset(x + barWidth / 2, baseline - barHeight - 6), 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) => oldDelegate.values != values;
}

class _SettingsSheet extends StatelessWidget {
  final String profileName;
  final String themeLabel; // Было styleName
  final String backgroundName;

  const _SettingsSheet({
    required this.profileName,
    required this.themeLabel,
    required this.backgroundName,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      heightFactor: 0.52,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 18),
          Text('Настроить Zal Life',
              style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('Личный профиль и внешний вид',
              style: GoogleFonts.inter(color: _Zal.muted, fontSize: 11)),
          const SizedBox(height: 20),

          // Профиль
          _SettingsAction(
              icon: Icons.person_rounded,
              title: 'Профиль',
              subtitle: profileName,
              onTap: () => Navigator.pop(context, 'profile')
          ),
          const SizedBox(height: 9),

          // ТЕМА (Вместо стиля шапки)
          _SettingsAction(
              icon: Icons.light_mode_rounded,
              title: 'Светлая тема',
              subtitle: 'Переключить на Air & Paper',
              onTap: () => Navigator.pop(context, 'theme')
          ),
          const SizedBox(height: 9),

          // Фон
          _SettingsAction(
              icon: Icons.landscape_rounded,
              title: 'Фон главного экрана',
              subtitle: backgroundName,
              onTap: () => Navigator.pop(context, 'background')
          ),
        ],
      ),
    );
  }
}

class _StylePickerSheet extends StatelessWidget {
  final int selected;
  const _StylePickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      heightFactor: 0.84,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(), const SizedBox(height: 16),
          Text('Стиль шапки', style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('12 визуальных настроений · выбор сохранится', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 10.5)),
          const SizedBox(height: 15),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(bottom: 18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.43),
              itemCount: 12,
              itemBuilder: (context, index) {
                final isSelected = index == selected;
                return InkWell(
                  onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context, index); },
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: isSelected ? _Zal.lime : _Zal.line, width: isSelected ? 1.5 : 1), color: _Zal.paper),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_Zal.forest2, _Zal.dark])),
                            child: Stack(children: [
                              Positioned(right: 9, top: 8, child: Container(width: 22, height: 22, decoration: BoxDecoration(color: _Zal.lime, shape: BoxShape.circle))),
                              Positioned(left: 9, bottom: 9, child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.white.withOpacity(0.88), borderRadius: BorderRadius.circular(5)))),
                              Positioned(left: 9, bottom: 19, child: Container(width: 30, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.42), borderRadius: BorderRadius.circular(5)))),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(children: [Expanded(child: Text('Стиль ${index + 1}', style: GoogleFonts.inter(color: _Zal.ink, fontSize: 11, fontWeight: FontWeight.w900))), if (isSelected) const Icon(Icons.check_circle_rounded, color: _Zal.limeDark, size: 16)]),
                        const SizedBox(height: 2),
                        Text('Описание стиля', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _Zal.muted, fontSize: 8.5)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPickerSheet extends StatelessWidget {
  final String selected; final List<String> backgrounds; final List<String> labels;
  const _BackgroundPickerSheet({required this.selected, required this.backgrounds, required this.labels});

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      heightFactor: 0.84,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(), const SizedBox(height: 16),
          Text('Фон главного экрана', style: GoogleFonts.manrope(color: _Zal.ink, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${backgrounds.length} природных сюжетов', style: GoogleFonts.inter(color: _Zal.muted, fontSize: 10.5)),
          const SizedBox(height: 15),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(bottom: 18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 0.9),
              itemCount: backgrounds.length,
              itemBuilder: (context, index) {
                final path = backgrounds[index]; final isSelected = path == selected;
                return InkWell(
                  onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context, path); },
                  borderRadius: BorderRadius.circular(15),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _AppImage(path: path, fit: BoxFit.cover, fallback: const ColoredBox(color: _Zal.forest2)),
                        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xB9000000)]))),
                        Positioned(
                          left: 8, right: 6, bottom: 8,
                          child: Row(children: [Expanded(child: Text(labels[index], maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))), if (isSelected) const Icon(Icons.check_circle_rounded, color: _Zal.lime, size: 15)]),
                        ),
                        if (isSelected) Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: _Zal.lime, width: 3), borderRadius: BorderRadius.circular(15)))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  final Widget child; final double heightFactor;
  const _SheetFrame({required this.child, required this.heightFactor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * heightFactor,
      decoration: const BoxDecoration(color: _Zal.canvas, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(19, 10, 19, 10), child: child)),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: _Zal.line, borderRadius: BorderRadius.circular(5))));
}

class _SettingsAction extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  const _SettingsAction({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Zal.paper, borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Container(width: 39, height: 39, decoration: BoxDecoration(color: _Zal.canvas, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: _Zal.lime, size: 19)),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.inter(color: _Zal.ink, fontSize: 12, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, style: GoogleFonts.inter(color: _Zal.muted, fontSize: 10))])),
              const Icon(Icons.chevron_right_rounded, color: _Zal.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}