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

import 'features/nutrition/models/nutrition_models.dart' show FoodProduct;
import 'features/nutrition/models/wellness_models.dart';
import 'features/nutrition/providers/nutrition_provider.dart';
import 'features/nutrition/providers/wellness_provider.dart';
import 'features/nutrition/ui/screens/add_pantry_screen.dart';
import 'features/nutrition/ui/screens/fuel_dashboard_screen.dart';
import 'features/nutrition/ui/screens/knowledge_screen.dart';
import 'features/nutrition/ui/screens/profile_screen.dart';
import 'features/nutrition/ui/screens/shopping_mode_screen.dart';
import 'features/nutrition/ui/widgets/season_vine_card.dart';


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
    final exList = log.exercisesLog;
    if (exList is List) {
      for (final ex in exList) {
        final sList = ex.sets;
        if (sList is List) {
          for (final s in sList) {
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

String _groupNum(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}
String _formatKg(double v) {
  if (v < 1) return '0 кг';
  return '${_groupNum(v.round())} кг';
}
String? _formatTons(double v) {
  if (v < 1000) return null;
  final t = v / 1000;
  final s = t >= 10 ? t.toStringAsFixed(0) : t.toStringAsFixed(1);
  return '≈ ${s.replaceAll('.', ',')} т';
}
String _shortKg(double v) {
  if (v >= 1000) {
    final k = v / 1000;
    return k >= 10 ? '${k.toStringAsFixed(0)}k' : '${k.toStringAsFixed(1)}k';
  }
  return v.round().toString();
}

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════════
class _Palette {
  static const bg = Color(0xFFF6F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF263D36);
  static const textMuted = Color(0xFF7C8982);
  static const green = Color(0xFF426C59);
  static const greenSoft = Color(0xFFE7EFE5);
  static const sage = Color(0xFF8CAB93);
  static const peach = Color(0xFFC79475);
  static const peachSoft = Color(0xFFF5E6DC);
  static const pink = Color(0xFFBB8F9D);
  static const pinkSoft = Color(0xFFF2E4E7);
  static const yellow = Color(0xFFE7D9B8);
  static const divider = Color(0xFFE5E8E1);
}

class _Hero {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const accent = Color(0xFFEF9563);
  static const textHigh = Colors.white;
  static const textLow = Color(0xFFA4A6AA);
}

class _HeroAccents {
  static const peach = Color(0xFFEF9563);
  static const amber = Color(0xFFE8B858);
  static const sage = Color(0xFFA5C9AF);
  static const pink = Color(0xFFE899A8);
  static const sky = Color(0xFF7EA8C6);
}

class _Vibrant {
  static const neonGreen = Color(0xFF3DDC84);
  static const vividPeach = Color(0xFFFF8A65);
  static const electricBlue = Color(0xFF4A90E2);
  static const glowingPink = Color(0xFFFF6B8B);
  static const goldTop = Color(0xFFF4D06F);
  static const goldMid = Color(0xFFE8B858);
  static const goldBottom = Color(0xFFD4A04A);
}

class _R {
  final double scale;
  _R(BuildContext context)
      : scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

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
        imageUrl: p, fit: fit,
        placeholder: (_, __) => fb,
        errorWidget: (_, __, ___) => fb,
      );
    }
    return Image.file(File(p), fit: fit, errorBuilder: (_, __, ___) => fb);
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
  late final AnimationController _entrance;
  late final AnimationController _confetti;
  late final ScrollController _scroll;

  late List<_ConfettiParticle> _confettiParticles;
  bool? _wasCompleted;

  String _avatarEmoji = '💪';
  String? _avatarImagePath;
  String _profileName = '';

  String _heroBgImage = 'assets/images/nature_hero2.jpg';

  static const _heroBackgrounds = [
    'assets/images/nature_hero.jpg',
    'assets/images/nature_hero2.jpg',
    'assets/images/nature_hero3.jpg',
    'assets/images/nature_hero4.jpg',
    'assets/images/nature_hero5.jpg',
    'assets/images/nature_hero6.jpg',
    'assets/images/nature_hero7.jpg',
    'assets/images/nature_hero8.jpg',
    'assets/images/nature_hero9.jpg',
    'assets/images/nature_hero10.jpg',
    'assets/images/nature_hero11.jpg',
    'assets/images/nature_hero12.jpg',
    'assets/images/nature_hero13.jpg',
    'assets/images/nature_hero14.jpg',
    'assets/images/nature_hero15.jpg',
    'assets/images/nature_hero16.jpg',
    'assets/images/nature_hero17.jpg',
    'assets/images/nature_hero18.jpg',
    'assets/images/nature_hero19.jpg',
    'assets/images/nature_hero20.jpg',
    'assets/images/nature_hero21.jpg',
  ];

  static const _heroBgLabels = {
    'assets/images/nature_hero.jpg': 'Тропа',
    'assets/images/nature_hero2.jpg': 'Закат 1',
    'assets/images/nature_hero3.jpg': 'Закат 2',
    'assets/images/nature_hero4.jpg': 'Закат 3',
    'assets/images/nature_hero5.jpg': 'Лес',
    'assets/images/nature_hero6.jpg': 'Горы',
    'assets/images/nature_hero7.jpg': 'Закат 4',
    'assets/images/nature_hero8.jpg': 'Рассвет',
    'assets/images/nature_hero9.jpg': 'Поле',
    'assets/images/nature_hero10.jpg': 'Река',
    'assets/images/nature_hero11.jpg': 'Озеро',
    'assets/images/nature_hero12.jpg': 'Море',
    'assets/images/nature_hero13.jpg': 'Пляж',
    'assets/images/nature_hero14.jpg': 'Пустыня',
    'assets/images/nature_hero15.jpg': 'Водопад',
    'assets/images/nature_hero16.jpg': 'Каньон',
    'assets/images/nature_hero17.jpg': 'Степь',
    'assets/images/nature_hero18.jpg': 'Тайга',
    'assets/images/nature_hero19.jpg': 'Луг',
    'assets/images/nature_hero20.jpg': 'Дюны',
    'assets/images/nature_hero21.jpg': 'Утёс',
  };

  static const int kWeekGoal = 7;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))..forward();
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
      _avatarImagePath = prefs.getString('avatar_image_path');
      _profileName = prefs.getString('profile_name') ?? 'Анна';
      _heroBgImage = prefs.getString('hero_bg_image') ??
          'assets/images/nature_hero2.jpg';
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _confetti.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<_ConfettiParticle> _generateConfetti() {
    final rng = math.Random(42);
    const colors = [_Palette.green, _Palette.peach, _Palette.sage, _Palette.pink, _Palette.yellow];
    return List.generate(70, (i) => _ConfettiParticle(
      xFrac: rng.nextDouble(),
      startY: -20 - rng.nextDouble() * 80,
      vx: (rng.nextDouble() - 0.5) * 300,
      vy: 500 + rng.nextDouble() * 400,
      rot0: rng.nextDouble() * math.pi * 2,
      rotV: (rng.nextDouble() - 0.5) * math.pi * 6,
      color: colors[rng.nextInt(colors.length)],
      size: 4 + rng.nextDouble() * 8,
    ));
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

  Future<void> _openProfileScreen() async {
    HapticFeedback.mediumImpact();
    final fitness = context.read<FitnessProvider>();
    final stats = fitness.getStats();
    final level = _levelFromStats(stats);
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final totalWorkouts = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    final totalVolume = ((stats['totalVolume'] ?? 0.0) as num).toDouble();

    final result = await Navigator.push<ProfileResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          initialName: _profileName,
          initialEmoji: _avatarEmoji,
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
      _profileName = result.name;
      _avatarEmoji = result.emoji;
      _avatarImagePath = result.imagePath;
    });
  }

  // ═════════════════════════════════════════════════════════
  //  SETTINGS + BACKGROUND PICKER
  // ═════════════════════════════════════════════════════════
  Future<void> _openSettings() async {
    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SettingsSheet(
        currentBg: _heroBgImage,
        bgLabel: _heroBgLabels[_heroBgImage] ?? 'Природа',
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'profile') {
      await _openProfileScreen();
    } else if (action == 'background') {
      await _openBackgroundPicker();
    }
  }

  Future<void> _openBackgroundPicker() async {
    final r = _R(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ConstrainedBox(
        // ⬇️ Ограничиваем высоту шторки до 85% экрана
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
          decoration: BoxDecoration(
            color: _Palette.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Граббер ──
                Center(
                  child: Container(
                    width: r.s(38),
                    height: r.s(5),
                    decoration: BoxDecoration(
                      color: _Palette.divider,
                      borderRadius: BorderRadius.circular(r.s(3)),
                    ),
                  ),
                ),
                SizedBox(height: r.s(20)),

                // ── Заголовок ──
                Row(
                  children: [
                    Container(
                      width: r.s(38),
                      height: r.s(38),
                      decoration: BoxDecoration(
                        color: _Palette.greenSoft,
                        borderRadius: BorderRadius.circular(r.s(11)),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.wallpaper_rounded,
                          color: _Palette.green, size: r.s(19)),
                    ),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Фон главного экрана',
                              style: GoogleFonts.inter(
                                  color: _Palette.text,
                                  fontSize: r.fs(18),
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: r.s(2)),
                          Text('${_heroBackgrounds.length} вариантов на выбор',
                              style: GoogleFonts.inter(
                                  color: _Palette.textMuted,
                                  fontSize: r.fs(12))),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.s(18)),

                // ⬇️⬇️ СКРОЛЛ ЗДЕСЬ ⬇️⬇️
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: GridView.count(
                      crossAxisCount: 3,                 // 3 колонки — для 21 шт. идеально
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: r.s(10),
                      crossAxisSpacing: r.s(10),
                      childAspectRatio: 0.82,            // чуть выше, чем шире
                      children: _heroBackgrounds.map((path) {
                        final isSelected = path == _heroBgImage;
                        final label = _heroBgLabels[path] ?? '';
                        return _TapScale(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(ctx, path);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(r.s(16)),
                              border: Border.all(
                                color: isSelected
                                    ? _Palette.green
                                    : Colors.white.withOpacity(0.9),
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: _Palette.green.withOpacity(0.25),
                                  blurRadius: 12,
                                  spreadRadius: -2,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                                  : null,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  path,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [_Hero.bgTop, _Hero.bgBottom],
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                        Icons.image_not_supported_rounded,
                                        color: Colors.white.withOpacity(0.5),
                                        size: r.s(22)),
                                  ),
                                ),
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.0),
                                          Colors.black.withOpacity(0.55),
                                        ],
                                        stops: const [0.4, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                // Метка внизу
                                Positioned(
                                  left: r.s(8),
                                  right: r.s(8),
                                  bottom: r.s(8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: r.fs(10.5),
                                              fontWeight: FontWeight.w700,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  blurRadius: 4,
                                                ),
                                              ]),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: r.s(18),
                                          height: r.s(18),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(Icons.check_rounded,
                                              color: _Palette.green,
                                              size: r.s(12)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && result != _heroBgImage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hero_bg_image', result);
      if (mounted) setState(() => _heroBgImage = result);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final pedometer = context.watch<PedometerProvider>();
    context.watch<WellnessProvider>();

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
            top: false, bottom: false,
            child: RefreshIndicator(
              color: _Hero.accent,
              backgroundColor: _Hero.bgTop,
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
                  SliverToBoxAdapter(child: _hero(fitness, nutrition)),
                  SliverToBoxAdapter(child: _entranceAt(0.20, _focusCard(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.30, _bentoTop(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.40, _bentoMid(nutrition))),
                  SliverToBoxAdapter(child: _entranceAt(0.45, _seasonalRail(context))),
                  SliverToBoxAdapter(child: _entranceAt(0.50, _stepsCard(pedometer))),
                  SliverToBoxAdapter(child: _entranceAt(0.55, _achievements(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.60, _VolumeCard(fitness: fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.65, _prStrip(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.70, _rhythm(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.80, _quickDock(fitness))),
                  SliverToBoxAdapter(child: _entranceAt(0.85, _targetsSection(fitness))),
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
          size: Size.infinite,
        );
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
  //  SEASONAL RAIL
  // ═════════════════════════════════════════════════════════
  Widget _seasonalRail(BuildContext context) {
    final r = _R(context);
    final wellness = context.watch<WellnessProvider>();
    final nutrition = context.watch<NutritionProvider>();
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(20)),
      child: SeasonVineCard(
        wellness: wellness,
        nutrition: nutrition,
        scale: r.scale,
        onOpenKnowledge: () => _openKnowledge(context),
      ),
    );
  }

  void _openKnowledge(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<WellnessProvider>()),
          ChangeNotifierProvider.value(value: context.read<NutritionProvider>()),
        ],
        child: const KnowledgeScreen(),
      ),
    ));
  }

// ═════════════════════════════════════════════════════════
//  HERO (Nature Premium with Photo) — ОБНОВЛЁННЫЙ
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
        ? (summary.calories / goals.calories).clamp(0.0, 1.0) : 0.0;
    final weekData = _buildWeekData(fitness, today, today.weekday - 1);
    final daysActive = List<bool>.generate(
        7, (i) => i < weekData.length && weekData[i].workouts > 0);
    final todayIdx = today.weekday - 1;
    final daysPassed = todayIdx + 1;
    final ringSize = r.s(300);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Stack(
        children: [
          // 1. ФОТОГРАФИЯ ПРИРОДЫ (динамический фон)
          Positioned.fill(
            child: Image.asset(
              _heroBgImage,
              key: ValueKey(_heroBgImage),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_Hero.bgTop, _Hero.bgBottom],
                  ),
                ),
              ),
            ),
          ),
          // 2. ГРАДИЕНТНЫЙ OVERLAY ДЛЯ ЧИТАЕМОСТИ
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.55),
                    _Palette.bg.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.3, 0.75, 1.0],
                ),
              ),
            ),
          ),
          // 3. ПЛАВНЫЙ ПЕРЕХОД В ОСНОВНОЙ ФОН СТРАНИЦЫ
          Positioned(
            left: 0, right: 0, bottom: 0, height: 70,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _Palette.bg.withOpacity(0.0),
                      _Palette.bg,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 4. КОНТЕНТ
          SafeArea(
            bottom: false, left: false, right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(24), r.s(12), r.s(24), r.s(24)),
              child: Column(
                children: [
                  // ═══ 1. ВЕРХНИЙ РЯД: Иконки слева + Настройки справа ═══
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🛒 + 🧺 в столбик, только иконки в кругах
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TapScale(
                            onTap: () => _openShoppingMode(context, nutrition),
                            child: Container(
                              width: r.s(46), height: r.s(46),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
                              ),
                              child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          SizedBox(height: r.s(10)),
                          _TapScale(
                            onTap: () => _openAddPantry(context, nutrition),
                            child: Container(
                              width: r.s(46), height: r.s(46),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
                              ),
                              child: const Icon(Icons.kitchen_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // ⚙️ Настройки
                      _TapScale(
                        onTap: _openSettings,
                        child: Container(
                          width: r.s(46), height: r.s(46),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
                          ),
                          child: Icon(Icons.tune_rounded, color: Colors.white, size: r.s(20)),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: r.s(18)),

// ═══ 🆕 КОЛЬЦА ПРОГРЕССА С ЧАСАМИ ВНУТРИ ═══
                  Container(
                    padding: EdgeInsets.all(r.s(8)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.15),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: SizedBox(
                      width: ringSize, height: ringSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Кольца прогресса (задний план)
                          TweenAnimationBuilder<double>(
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
                          // 2. Ретро-часы (точно в центре, со своим фоном)
                          SizedBox(
                            width: r.s(90), // Оптимальный размер для центра колец
                            height: r.s(90),
                            child: CustomPaint(
                              painter: _RetroClockPainter(time: today),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: r.s(22)),

                  // ═══ 3. ЧИПЫ-ЛЕГЕНДА (Level + 4 метрики) ═══
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: r.s(10), runSpacing: r.s(10),
                    children: [
                      _LevelBadge(level: level, scale: r.scale),
                      _heroLegendChip(_HeroAccents.amber, 'Неделя', '$thisWeek/7', r),
                      _heroLegendChip(_HeroAccents.sage, 'Ккал', '${summary.calories.round()}', r),
                      _heroLegendChip(_HeroAccents.pink, 'Трен.', '$thisWeek/7', r),
                      _heroLegendChip(_HeroAccents.sky, 'Серия', '$streak д', r),
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

  Widget _heroLegendChip(Color color, String label, String value, _R r) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(4)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: r.s(5)),
          Text(label, style: TextStyle(
              color: Colors.white.withOpacity(0.8), fontSize: r.fs(10), fontWeight: FontWeight.w500)),
          SizedBox(width: r.s(3)),
          Text(value, style: TextStyle(
              color: Colors.white, fontSize: r.fs(11), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  FOCUS CARD
  // ═════════════════════════════════════════════════════════
  Widget _focusCard(FitnessProvider fitness) {
    final r = _R(context);
    final session = fitness.activeSession;
    final wellbeing = fitness.getTodayWellbeing();

    WorkoutProgram? activeProgram;
    if (session != null) {
      try {
        activeProgram = fitness.programs.firstWhere((p) => p.id == session.programId);
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
      subtitle = 'День ${session.currentDayIndex + 1} · ${(session.progressPercent * 100).round()}%';
      tag = 'АКТИВНАЯ ПРОГРАММА';
      icon = Icons.play_arrow_rounded;
      onTap = () {
        HapticFeedback.lightImpact();
        if (activeProgram != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: fitness,
              child: ActiveProgramScreen(program: activeProgram!, isDark: false),
            ),
          ));
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
        padding: EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), r.s(20)),
        child: _TapScale(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r.s(28)),
              boxShadow: [
                BoxShadow(
                  color: _Palette.green.withOpacity(0.10),
                  blurRadius: 24, spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                SizedBox(
                  height: r.s(220), width: double.infinity,
                  child: _AppImg(
                    path: coverUrl, fit: BoxFit.cover,
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
                                Icon(icon, color: _Palette.green, size: r.s(12)),
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
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: r.fs(22),
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.6, height: 1.15)),
                      SizedBox(height: r.s(4)),
                      Text(subtitle,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: r.fs(12))),
                      SizedBox(height: r.s(14)),
                      SizedBox(
                        width: double.infinity, height: r.s(46),
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
                              Icon(icon, size: r.s(18), color: _Palette.text),
                              SizedBox(width: r.s(8)),
                              Text(session != null ? 'Продолжить' : 'Начать',
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
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), r.s(20)),
      child: _TapScale(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(r.s(20)),
          decoration: BoxDecoration(
            color: _Palette.greenSoft,
            borderRadius: BorderRadius.circular(r.s(28)),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
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
                              color: _Palette.green, fontSize: r.fs(10),
                              fontWeight: FontWeight.w600, letterSpacing: 1)),
                    ],
                  ),
                  Text('25 мин · Дома',
                      style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(11))),
                ],
              ),
              SizedBox(height: r.s(16)),
              Text(title,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: _Palette.text, fontSize: r.fs(22),
                      fontWeight: FontWeight.w400, letterSpacing: -0.8)),
              SizedBox(height: r.s(6)),
              Text(subtitle,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: _Palette.textMuted, fontSize: r.fs(12), height: 1.4)),
              SizedBox(height: r.s(20)),
              SizedBox(
                width: double.infinity, height: r.s(48),
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
                      Text(session != null ? 'Продолжить' : 'Начать тренировку',
                          style: GoogleFonts.inter(
                              fontSize: r.fs(13), fontWeight: FontWeight.w500)),
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
  //  BENTO TOP
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
                                  color: _Palette.text, fontSize: r.fs(13),
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
                                  color: _Palette.text, fontSize: r.fs(32),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -1.3,
                                  fontFeatures: const [FontFeature.tabularFigures()])),
                          SizedBox(width: r.s(4)),
                          Text('/ 7',
                              style: GoogleFonts.inter(
                                  color: _Palette.textMuted, fontSize: r.fs(15),
                                  letterSpacing: -1)),
                        ],
                      ),
                      Text('тренировок на этой неделе',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted, fontSize: r.fs(11))),
                      SizedBox(height: r.s(14)),
                      _GlossyProgress(
                        value: weekProgress,
                        height: r.s(8),
                        gradient: const [_Vibrant.neonGreen, _Palette.green],
                        track: Colors.white.withOpacity(0.55),
                        radius: r.s(6),
                      ),
                      SizedBox(height: r.s(10)),
                      _WeekDaysRow(
                        weekData: weekData,
                        todayIdx: todayIdx,
                        scale: r.scale,
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
                                  color: _Palette.text, fontSize: r.fs(13),
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
                                backgroundColor: Colors.white.withOpacity(0.5),
                                valueColor: const AlwaysStoppedAnimation(
                                    _Palette.peach),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$streak',
                                    style: GoogleFonts.inter(
                                        color: _Palette.text, fontSize: r.fs(36),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -1.5,
                                        fontFeatures: const [FontFeature.tabularFigures()])),
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
                              color: _Palette.textMuted, fontSize: r.fs(10))),
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
  //  BENTO MID
  // ═════════════════════════════════════════════════════════
  Widget _bentoMid(NutritionProvider nutrition) {
    final r = _R(context);
    final today = DateTime.now();
    final summary = nutrition.getSummaryForDate(today);
    final goals = nutrition.getGoalsForDate(today);
    final kcalPct = goals.calories > 0
        ? (summary.calories / goals.calories).clamp(0.0, 1.0) : 0.0;
    final waterPct = goals.waterMl > 0
        ? (summary.waterMl / goals.waterMl).clamp(0.0, 1.0) : 0.0;

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
                                  color: _Palette.text, fontSize: r.fs(13),
                                  fontWeight: FontWeight.w500)),
                          Icon(Icons.arrow_outward_rounded,
                              color: _Palette.textMuted, size: r.s(16)),
                        ],
                      ),
                      SizedBox(height: r.s(14)),
                      Text('${summary.calories.round()}',
                          style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(28),
                              fontWeight: FontWeight.w400,
                              letterSpacing: -1.3,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                      Text('из ${goals.calories.round()} ккал',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted, fontSize: r.fs(11))),
                      SizedBox(height: r.s(14)),
                      _GlossyProgress(
                        value: kcalPct,
                        height: r.s(6),
                        gradient: const [_Vibrant.glowingPink, _Vibrant.vividPeach],
                        track: Colors.white.withOpacity(0.55),
                        radius: 100,
                      ),
                      SizedBox(height: r.s(10)),
                      Text(
                          'Осталось ${(goals.calories - summary.calories).round().clamp(0, 9999)} ккал',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted, fontSize: r.fs(10))),
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
                                  color: _Palette.text, fontSize: r.fs(13),
                                  fontWeight: FontWeight.w500)),
                          Icon(Icons.arrow_outward_rounded,
                              color: _Palette.textMuted, size: r.s(16)),
                        ],
                      ),
                      SizedBox(height: r.s(14)),
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: '${(summary.waterMl / 1000).toStringAsFixed(1)} ',
                            style: GoogleFonts.inter(
                                color: _Palette.text, fontSize: r.fs(28),
                                fontWeight: FontWeight.w400,
                                letterSpacing: -1.3,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                        TextSpan(
                            text: '/ ${(goals.waterMl / 1000).toStringAsFixed(0)} л',
                            style: GoogleFonts.inter(
                                color: _Palette.textMuted, fontSize: r.fs(14),
                                letterSpacing: -1)),
                      ])),
                      Text('Хороший темп',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted, fontSize: r.fs(11))),
                      SizedBox(height: r.s(14)),
                      Wrap(
                        spacing: r.s(4), runSpacing: r.s(4),
                        children: List.generate(8, (i) {
                          final filled = (i / 8) < waterPct;
                          return Icon(Icons.water_drop_rounded,
                              size: r.s(14),
                              color: filled ? _Palette.green : _Palette.divider);
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
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
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
                                color: _Palette.text, fontSize: r.fs(13))),
                      ],
                    ),
                    SizedBox(height: r.s(10)),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: '${_fmtNum(pedo.steps)} ',
                          style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(30),
                              fontWeight: FontWeight.w400, letterSpacing: -1,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                      TextSpan(
                          text: '/ ${_fmtNum(pedo.goal)}',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted, fontSize: r.fs(12),
                              letterSpacing: -1)),
                    ])),
                    SizedBox(height: r.s(6)),
                    Text(
                        '${pedo.distanceKm.toStringAsFixed(1)} км · Ещё ${_fmtNum(pedo.remaining)} до цели',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: _Palette.textMuted, fontSize: r.fs(11))),
                  ],
                ),
              ),
              SizedBox(width: r.s(12)),
              SizedBox(
                width: r.s(74), height: r.s(74),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: r.s(74), height: r.s(74),
                      child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: r.s(4),
                        backgroundColor: _Palette.divider,
                        valueColor: const AlwaysStoppedAnimation(_Palette.green),
                      ),
                    ),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: '${(pct * 100).round()}',
                          style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(18),
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                      TextSpan(
                          text: '%',
                          style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(11))),
                    ])),
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
                        color: _Palette.text, fontSize: r.fs(20),
                        fontWeight: FontWeight.w500, letterSpacing: -0.6)),
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
                        width: r.s(42), height: r.s(42),
                        decoration: BoxDecoration(
                          color: b.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(b.emoji, style: TextStyle(fontSize: r.fs(20))),
                      ),
                      const Spacer(),
                      Text(b.label,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(12),
                              fontWeight: FontWeight.w500)),
                      SizedBox(height: r.s(4)),
                      Text(b.subtitle,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted, fontSize: r.fs(10))),
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
  //  PR STRIP
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
                        color: _Palette.text, fontSize: r.fs(20),
                        fontWeight: FontWeight.w500, letterSpacing: -0.6)),
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
                        width: r.s(30), height: r.s(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pr.color.withOpacity(0.12),
                        ),
                        alignment: Alignment.center,
                        child: Text(pr.emoji, style: TextStyle(fontSize: r.fs(14))),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(pr.value,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  color: _Palette.text, fontSize: r.fs(22),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -1.0, height: 1,
                                  fontFeatures: const [FontFeature.tabularFigures()])),
                          SizedBox(height: r.s(3)),
                          Text(pr.label,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  color: _Palette.textMuted, fontSize: r.fs(9.5),
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
  //  RHYTHM
  // ═════════════════════════════════════════════════════════
  Widget _rhythm(FitnessProvider fitness) {
    final r = _R(context);
    final today = DateTime.now();
    final todayIdx = today.weekday - 1;
    final weekData = _buildWeekData(fitness, today, todayIdx);
    final volumes = weekData.map((d) => d.volume).toList();
    final hasAnyData = weekData.any((d) => d.workouts > 0);
    final totalVol = volumes.fold<double>(0, (s, v) => s + v);
    final activeDays = weekData.where((d) => d.workouts > 0).length;
    final maxVol = volumes.fold<double>(0, (a, b) => math.max(a, b));
    final avgPerDay = totalVol / 7;

    int bestIdx = -1;
    double bestVol = 0;
    for (int i = 0; i < volumes.length; i++) {
      if (volumes[i] > bestVol) { bestVol = volumes[i]; bestIdx = i; }
    }
    const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final bestDayName = bestIdx >= 0 ? dayNames[bestIdx] : '—';
    final stats = fitness.getStats();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Container(
        padding: EdgeInsets.all(r.s(20)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(r.s(28)),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: _Palette.green.withOpacity(0.06),
              blurRadius: 20, spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: _Palette.green, size: r.s(18)),
                SizedBox(width: r.s(8)),
                Text('ПУЛЬС НЕДЕЛИ',
                    style: GoogleFonts.inter(
                        color: _Palette.green, fontSize: r.fs(10),
                        fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const Spacer(),
                if (streak > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.s(9), vertical: r.s(5)),
                    decoration: BoxDecoration(
                        color: _Palette.peachSoft,
                        borderRadius: BorderRadius.circular(r.s(8))),
                    child: Text('🔥 $streak',
                        style: GoogleFonts.inter(
                            color: _Palette.peach, fontSize: r.fs(11),
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            SizedBox(height: r.s(20)),
            if (!hasAnyData)
              _rhythmEmpty(r)
            else ...[
              SizedBox(
                height: r.s(196),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Y-axis
                    SizedBox(
                      width: r.s(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: r.s(28)),
                            child: Text(_shortKg(maxVol),
                                style: GoogleFonts.inter(
                                    color: _Palette.textMuted, fontSize: r.fs(9),
                                    fontWeight: FontWeight.w500,
                                    fontFeatures: const [FontFeature.tabularFigures()])),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: r.s(28)),
                            child: Text(_shortKg(maxVol / 2),
                                style: GoogleFonts.inter(
                                    color: _Palette.textMuted, fontSize: r.fs(9),
                                    fontWeight: FontWeight.w500,
                                    fontFeatures: const [FontFeature.tabularFigures()])),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: r.s(28)),
                            child: Text('0',
                                style: GoogleFonts.inter(
                                    color: _Palette.textMuted, fontSize: r.fs(9),
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: r.s(6)),
                    // Bars
                    Expanded(
                      child: Stack(
                        children: [
                          // Average dotted line
                          if (avgPerDay > 0 && maxVol > 0)
                            Positioned(
                              left: 0, right: 0,
                              bottom: r.s(40) + (r.s(130) * (avgPerDay / maxVol)),
                              child: CustomPaint(
                                painter: _DashedLinePainter(
                                  color: _Palette.peach.withOpacity(0.55),
                                ),
                                size: Size.infinite,
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (i) {
                              final vol = volumes[i];
                              final isToday = i == todayIdx;
                              final isFuture = i > todayIdx;
                              final hasWorkout = weekData[i].workouts > 0;
                              final isBest = i == bestIdx && bestVol > 0;
                              final hFrac = maxVol > 0
                                  ? (vol / maxVol).clamp(0.0, 1.0) : 0.0;

                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: r.s(3)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        height: r.s(22),
                                        child: vol > 0
                                            ? Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isBest) ...[
                                              Icon(
                                                Icons.workspace_premium_rounded,
                                                size: r.s(11),
                                                color: _Palette.peach,
                                              ),
                                              SizedBox(width: r.s(2)),
                                            ],
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  _shortKg(vol),
                                                  style: GoogleFonts.inter(
                                                    fontSize: r.fs(9.5),
                                                    fontWeight: isBest
                                                        ? FontWeight.w800
                                                        : FontWeight.w500,
                                                    color: isBest
                                                        ? _Palette.peach
                                                        : _Palette.textMuted,
                                                    fontFeatures: const [
                                                      FontFeature.tabularFigures()
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                            : null,
                                      ),
                                      SizedBox(height: r.s(3)),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: hFrac),
                                        duration:
                                        Duration(milliseconds: 600 + i * 80),
                                        curve: Curves.easeOutCubic,
                                        builder: (_, anim, __) {
                                          final isEmpty = !hasWorkout && !isToday;
                                          return Container(
                                            height: r.s(130) * anim,
                                            constraints: BoxConstraints(
                                              minHeight: hasWorkout ? r.s(5) : 0,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: isToday
                                                  ? const LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  _Vibrant.vividPeach,
                                                  _Palette.peach,
                                                ],
                                              )
                                                  : (isBest
                                                  ? LinearGradient(
                                                begin:
                                                Alignment.topCenter,
                                                end: Alignment
                                                    .bottomCenter,
                                                colors: [
                                                  _Palette.green,
                                                  _Palette.green
                                                      .withOpacity(0.7),
                                                ],
                                              )
                                                  : null),
                                              color: !isToday && !isBest
                                                  ? (isEmpty
                                                  ? _Palette.divider
                                                  .withOpacity(0.3)
                                                  : _Palette.sage
                                                  .withOpacity(0.7))
                                                  : null,
                                              borderRadius:
                                              BorderRadius.vertical(
                                                top: Radius.circular(r.s(8)),
                                                bottom: Radius.circular(r.s(2)),
                                              ),
                                              border: isFuture
                                                  ? Border.all(
                                                color: _Palette.divider,
                                                width: 1,
                                              )
                                                  : null,
                                              boxShadow: isToday
                                                  ? [
                                                BoxShadow(
                                                  color: _Vibrant.vividPeach
                                                      .withOpacity(0.4),
                                                  blurRadius: r.s(8),
                                                  spreadRadius: 0,
                                                  offset: Offset(0, r.s(2)),
                                                ),
                                              ]
                                                  : (isBest
                                                  ? [
                                                BoxShadow(
                                                  color: _Palette.green
                                                      .withOpacity(0.3),
                                                  blurRadius: r.s(6),
                                                  offset: Offset(
                                                      0, r.s(2)),
                                                ),
                                              ]
                                                  : null),
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: r.s(8)),
                                      Text(dayNames[i],
                                          style: GoogleFonts.inter(
                                            color: isToday
                                                ? _Palette.peach
                                                : isFuture
                                                ? _Palette.textMuted
                                                : _Palette.text,
                                            fontSize: r.fs(10),
                                            fontWeight: isToday
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                          )),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: r.s(18)),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: r.s(12), vertical: r.s(12)),
                decoration: BoxDecoration(
                  color: _Palette.bg,
                  borderRadius: BorderRadius.circular(r.s(14)),
                ),
                child: Row(
                  children: [
                    _rhythmStat('📅', '$activeDays/7', 'дней актив.', r),
                    _rhythmDivider(r),
                    _rhythmStat('📊', _formatKg(avgPerDay), 'средне/день', r),
                    _rhythmDivider(r),
                    _rhythmStat('⭐',
                        bestVol > 0 ? '$bestDayName' : '—',
                        bestVol > 0 ? _formatKg(bestVol) : 'лучший', r),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rhythmEmpty(_R r) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.s(24)),
      child: Center(
        child: Column(
          children: [
            Text('🌱', style: TextStyle(fontSize: r.fs(32))),
            SizedBox(height: r.s(10)),
            Text('Пока нет тренировок',
                style: GoogleFonts.inter(
                    color: _Palette.text, fontSize: r.fs(14),
                    fontWeight: FontWeight.w500)),
            SizedBox(height: r.s(4)),
            Text('Начни первую — статистика появится здесь',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: _Palette.textMuted, fontSize: r.fs(11), height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _rhythmDivider(_R r) =>
      Container(width: 1, height: r.s(26), color: _Palette.divider);

  Widget _rhythmStat(String emoji, String value, String label, _R r) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: TextStyle(fontSize: r.fs(11))),
              SizedBox(width: r.s(4)),
              Flexible(
                child: Text(value,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: _Palette.text, fontSize: r.fs(14),
                        fontWeight: FontWeight.w600, letterSpacing: -0.4,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ],
          ),
          SizedBox(height: r.s(2)),
          Text(label,
              style: GoogleFonts.inter(
                  color: _Palette.textMuted, fontSize: r.fs(8.5),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  QUICK DOCK
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
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
          boxShadow: [
            BoxShadow(
              color: _Palette.green.withOpacity(0.05),
              blurRadius: 18, spreadRadius: -4,
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
                      width: r.s(48), height: r.s(48),
                      decoration: BoxDecoration(
                        color: it.$3.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(r.s(16)),
                      ),
                      child: Icon(it.$1, color: it.$3, size: r.s(22)),
                    ),
                    SizedBox(height: r.s(6)),
                    Text(it.$2,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: _Palette.text, fontSize: r.fs(10),
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
  //  TARGETS
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
                      color: _Palette.text, fontSize: r.fs(20),
                      fontWeight: FontWeight.w500, letterSpacing: -0.6)),
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
              padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(4)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(r.s(28)),
                border: Border.all(
                    color: Colors.white.withOpacity(0.9), width: 1),
              ),
              child: Column(children: active
                  .take(3).map((t) => _targetRow(t, fitness, r)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _targetRow(FitnessTarget target, FitnessProvider fitness, _R r) {
    Exercise? exercise;
    if (target.exerciseId != null && target.exerciseId!.isNotEmpty) {
      try {
        exercise = fitness.exercises.firstWhere((e) => e.id == target.exerciseId);
      } catch (_) {}
    }
    final imageUrl = exercise?.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final emoji = exercise?.exerciseType.emoji ?? target.type.emoji;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: fitness,
            child: FitnessTargetDetailsScreen(target: target, isDark: false),
          ),
        ));
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: r.s(14)),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: r.s(54), height: r.s(54),
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
                          style: TextStyle(fontSize: r.fs(24))))
                      : Text(emoji, style: TextStyle(fontSize: r.fs(24))),
                ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(target.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(13),
                              fontWeight: FontWeight.w500)),
                      Text('Прогресс · ${(target.progressPercent * 100).round()}%',
                          style: GoogleFonts.inter(
                              color: _Palette.textMuted, fontSize: r.fs(10))),
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
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: r.s(52), height: r.s(52),
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
                          color: _Palette.text, fontSize: r.fs(14),
                          fontWeight: FontWeight.w500)),
                  Text('Например, жим 100 кг',
                      style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(12))),
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
  String _fmtNum(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    if (n >= 1000) {
      final s = n.toString();
      return '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}';
    }
    return '$n';
  }

  List<_Badge> _getBadges(Map<String, dynamic> stats) {
    final total = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final volume = ((stats['totalVolume'] ?? 0.0) as num).toDouble();

    final list = <_Badge>[];
    if (total >= 1) list.add(_Badge('🏅', 'Первая', 'Начало пути', _Palette.peach));
    if (streak >= 7) list.add(_Badge('🔥', '7 дней', 'В ритме', _Palette.pink));
    if (total >= 10) list.add(_Badge('💪', '10 тренировок', 'Сильная неделя', _Palette.green));
    if (volume >= 1000) list.add(_Badge('⚡', 'Тонна', '50км за месяц', _Palette.yellow));
    if (streak >= 30) list.add(_Badge('👑', '30 дней', 'Железная воля', _Palette.sage));
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
          for (final log in logs) { volume += _extractLogVolume(log); }
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
      if (bestVol > 0) prs.add(_PR('⚡', _shortKg(bestVol), 'за тренировку', _Palette.yellow));
    }
    if (dailyWorkouts.isNotEmpty) {
      final bestDay = dailyWorkouts.values.reduce(math.max);
      if (bestDay > 0) prs.add(_PR('🏋️', '$bestDay', 'за день', _Palette.peach));
    }
    if (total > 0) prs.add(_PR('🎯', '$total', 'всего', _Palette.green));
    if (volume > 0) prs.add(_PR('🔥', _shortKg(volume), 'общий тоннаж', _Palette.pink));
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
      programId: 'quick', dayNumber: 1, exercises: [],
    );
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final query = searchCtrl.text.trim().toLowerCase();
          final filtered = provider.exercises
              .where((e) => query.isEmpty || e.name.toLowerCase().contains(query))
              .toList();
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(32))),
            ),
            padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(20)),
            child: Column(
              children: [
                Container(width: r.s(38), height: r.s(5),
                    decoration: BoxDecoration(
                        color: _Palette.divider,
                        borderRadius: BorderRadius.circular(r.s(3)))),
                SizedBox(height: r.s(20)),
                Row(
                  children: [
                    Container(width: r.s(46), height: r.s(46),
                        decoration: BoxDecoration(
                            color: _Palette.greenSoft,
                            borderRadius: BorderRadius.circular(r.s(13))),
                        child: Icon(Icons.bolt_rounded,
                            color: _Palette.green, size: r.s(24))),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Быстрая тренировка',
                              style: GoogleFonts.inter(
                                  color: _Palette.text, fontSize: r.fs(20),
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: r.s(2)),
                          Text('Выберите упражнения',
                              style: GoogleFonts.inter(
                                  color: _Palette.textMuted, fontSize: r.fs(12))),
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
                    filled: true, fillColor: _Palette.bg,
                    contentPadding: EdgeInsets.symmetric(vertical: r.s(14)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(r.s(14)),
                        borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: r.s(14)),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text('Ничего не найдено',
                      style: GoogleFonts.inter(color: _Palette.textMuted)))
                      : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => SizedBox(height: r.s(8)),
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      final added = quickDay.exercises
                          .any((item) => item.exerciseId == exercise.id);
                      final color = exercise.muscleGroups.isNotEmpty
                          ? exercise.muscleGroups.first.color
                          : _Palette.green;
                      final hasImage = exercise.imageUrl != null &&
                          exercise.imageUrl!.isNotEmpty;
                      return Container(
                        decoration: BoxDecoration(
                          color: _Palette.bg,
                          borderRadius: BorderRadius.circular(r.s(14)),
                          border: Border.all(
                              color: _Palette.divider, width: 0.6),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: r.s(12), vertical: r.s(4)),
                          leading: Container(
                            width: r.s(40), height: r.s(40),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(r.s(11)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasImage
                                ? _AppImg(
                                path: exercise.imageUrl,
                                fallback: Center(child: Text(
                                    exercise.exerciseType.emoji,
                                    style: TextStyle(fontSize: r.fs(18)))))
                                : Center(child: Text(exercise.exerciseType.emoji,
                                style: TextStyle(fontSize: r.fs(18)))),
                          ),
                          title: Text(exercise.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  color: _Palette.text,
                                  fontWeight: FontWeight.w500)),
                          trailing: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setSheetState(() {
                                if (added) {
                                  quickDay.exercises.removeWhere(
                                          (item) => item.exerciseId == exercise.id);
                                } else {
                                  quickDay.exercises.add(WorkoutExercise(
                                    id: 'quick_ex_${quickDay.exercises.length}',
                                    exerciseId: exercise.id,
                                    order: quickDay.exercises.length,
                                    sets: [ExerciseSet(setNumber: 1, reps: 10, weight: 0)],
                                  ));
                                }
                              });
                            },
                            child: Container(
                              width: r.s(34), height: r.s(34),
                              decoration: BoxDecoration(
                                color: added ? _Palette.pinkSoft : _Palette.greenSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                  added ? Icons.remove_rounded : Icons.add_rounded,
                                  color: added ? _Palette.pink : _Palette.green,
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
                      width: double.infinity, height: r.s(54),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: provider,
                              child: WorkoutExecutionScreen(day: quickDay, isDark: false),
                            ),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Palette.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(r.s(14))),
                        ),
                        child: Text('НАЧАТЬ · ${quickDay.exercises.length} УПР.',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  NAVIGATION
  // ═════════════════════════════════════════════════════════


  void _openShoppingMode(BuildContext context, NutritionProvider nutrition) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: nutrition,
          child: const ShoppingModeScreen(),
        ),
      ),
    );
  }

  void _openAddPantry(BuildContext context, NutritionProvider nutrition) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: nutrition,
          child: const AddPantryScreen(),
        ),
      ),
    );
  }

  void _openFitness(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FitnessProvider>(),
          child: const FitnessDashboard(isDark: true))));
  void _openNutrition(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
          value: context.read<NutritionProvider>(),
          child: const FuelDashboardScreen(isDark: true))));
  void _openWorkoutLog(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FitnessProvider>(),
          child: const WorkoutLogScreen(isDark: true))));
  void _openTargets(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FitnessProvider>(),
          child: const FitnessTargetsScreen(isDark: true))));
  void _openExerciseLibrary(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FitnessProvider>(),
          child: const ExerciseLibraryScreen(isDark: true))));
  void _openWellbeing(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FitnessProvider>(),
          child: const WellbeingScreen(isDark: true))));
  void _openProgress(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FitnessProvider>(),
          child: const ProgressScreen(isDark: true))));
  void _openPedometer(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
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

  double _goalForPeriod(int period) {
    switch (period) {
      case 0: return _weeklyGoal;
      case 1: return _weeklyGoal * 4.3;
      case 2: return _weeklyGoal * 52;
      default: return 0;
    }
  }

  String _periodHeaderLabel(int period) {
    switch (period) {
      case 0: return 'НА ЭТОЙ НЕДЕЛЕ';
      case 1: return 'В ЭТОМ МЕСЯЦЕ';
      case 2: return 'В ЭТОМ ГОДУ';
      default: return 'ЗА ВСЁ ВРЕМЯ';
    }
  }

  String _goalPeriodWord(int period) {
    switch (period) {
      case 0: return 'недели';
      case 1: return 'месяца';
      case 2: return 'года';
      default: return '';
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
        final d = _extractLogDate(log);
        if (d == null) continue;
        final v = _extractLogVolume(log);
        int sets = 0;
        int exercises = 0;
        try {
          final exList = log.exercisesLog;
          if (exList is List) {
            exercises = exList.length;
            for (final ex in exList) {
              final sList = ex.sets;
              if (sList is List) sets += sList.length;
            }
          }
        } catch (_) {}

        allVol += v; allSets += sets; allEx += exercises; allWk += 1;
        final isThisWeek = !d.isBefore(weekStart);
        final isThisMonth = !d.isBefore(monthStart);
        final isThisYear = !d.isBefore(yearStart);
        final isLastWeek = !d.isBefore(lastWeekStart) && d.isBefore(weekStart);
        if (isThisWeek) { weekVol += v; weekSets += sets; weekEx += exercises; weekWk += 1; }
        if (isThisMonth) { monthVol += v; monthSets += sets; monthEx += exercises; monthWk += 1; }
        if (isThisYear) { yearVol += v; yearSets += sets; yearEx += exercises; yearWk += 1; }
        if (isLastWeek) lastWeekVol += v;
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
        ? (currentVol / goalForPeriod).clamp(0.0, 1.0) : 0.0;
    final goalReached = hasGoal && currentVol >= goalForPeriod;
    final accent = goalReached ? _Palette.green : _Palette.sage;
    final displayValue = _formatKg(currentVol);
    final tonsSubtitle = _formatTons(currentVol);
    final avgPerWorkout = currentWorkouts > 0
        ? currentVol / currentWorkouts : 0.0;
    final showWeekTrend = _selectedPeriod == 0;
    final weekDiff = weekVol - lastWeekVol;
    final weekPct = lastWeekVol > 0
        ? ((weekDiff / lastWeekVol) * 100).round() : (weekVol > 0 ? 100 : 0);
    final maxWeek = last4Weeks.reduce(math.max);

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Container(
        padding: EdgeInsets.all(r.s(20)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Colors.white, _Palette.greenSoft.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(r.s(28)),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
          boxShadow: [
            BoxShadow(
              color: _Palette.green.withOpacity(0.06),
              blurRadius: 20, spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: r.s(34), height: r.s(34),
                  decoration: BoxDecoration(
                    color: _Palette.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(r.s(10)),
                  ),
                  alignment: Alignment.center,
                  child: Text('🏋️', style: TextStyle(fontSize: r.fs(15))),
                ),
                SizedBox(width: r.s(10)),
                Text('ОБЪЁМ ТРЕНИРОВОК',
                    style: GoogleFonts.inter(
                        color: _Palette.green, fontSize: r.fs(10),
                        fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                const Spacer(),
                if (hasGoal && _loaded)
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
                          Icon(Icons.flag_rounded, color: accent, size: r.s(11)),
                          SizedBox(width: r.s(4)),
                          Text(_formatKg(goalForPeriod),
                              style: GoogleFonts.inter(
                                  color: accent, fontSize: r.fs(10.5),
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
                    padding: EdgeInsets.only(right: i < 3 ? r.s(6) : 0),
                    child: _TapScale(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPeriod = i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: EdgeInsets.symmetric(vertical: r.s(9)),
                        decoration: BoxDecoration(
                          color: selected
                              ? _Palette.green
                              : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(r.s(10)),
                        ),
                        child: Center(child: Text(_periodLabels[i],
                            style: GoogleFonts.inter(
                                color: selected
                                    ? Colors.white
                                    : _Palette.textMuted,
                                fontSize: r.fs(11.5),
                                fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: r.s(18)),
            Text(_periodHeaderLabel(_selectedPeriod),
                style: GoogleFonts.inter(
                    color: _Palette.textMuted, fontSize: r.fs(10),
                    fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            SizedBox(height: r.s(6)),
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
                        child: Text(displayValue,
                            style: GoogleFonts.inter(
                                color: _Palette.text, fontSize: r.fs(36),
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.8, height: 1,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                      SizedBox(height: r.s(4)),
                      Row(
                        children: [
                          if (tonsSubtitle != null) ...[
                            Text(tonsSubtitle,
                                style: GoogleFonts.inter(
                                    color: _Palette.textMuted, fontSize: r.fs(11),
                                    fontWeight: FontWeight.w500)),
                            SizedBox(width: r.s(6)),
                            Container(width: 3, height: 3,
                                decoration: BoxDecoration(
                                    color: _Palette.textMuted.withOpacity(0.5),
                                    shape: BoxShape.circle)),
                            SizedBox(width: r.s(6)),
                          ],
                          if (avgPerWorkout > 0)
                            Text('${_formatKg(avgPerWorkout)} / тренировку',
                                style: GoogleFonts.inter(
                                    color: _Palette.textMuted, fontSize: r.fs(11),
                                    fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showWeekTrend && lastWeekVol > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.s(10), vertical: r.s(8)),
                    decoration: BoxDecoration(
                      color: (weekDiff >= 0 ? _Palette.green : _Palette.pink)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(r.s(10)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          weekDiff >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: weekDiff >= 0 ? _Palette.green : _Palette.pink,
                          size: r.s(14),
                        ),
                        SizedBox(height: r.s(2)),
                        Text('${weekPct.abs()}%',
                            style: GoogleFonts.inter(
                                color: weekDiff >= 0
                                    ? _Palette.green
                                    : _Palette.pink,
                                fontSize: r.fs(13),
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ])),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: r.s(12)),
            Row(
              children: [
                _countChip('$currentWorkouts', 'трен.', r),
                SizedBox(width: r.s(6)),
                _countChip('$currentExercises', 'упр.', r),
                SizedBox(width: r.s(6)),
                _countChip('$currentSets', 'подх.', r),
              ],
            ),
            if (showWeekTrend && maxWeek > 0) ...[
              SizedBox(height: r.s(18)),
              SizedBox(
                height: r.s(96),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(4, (i) {
                    final v = last4Weeks[i];
                    final hFrac =
                    maxWeek > 0 ? (v / maxWeek).clamp(0.10, 1.0) : 0.10;
                    final isNow = i == 3;
                    final isPeak = v > 0 && v == maxWeek && !isNow;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 3 ? r.s(6) : 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(v > 0 ? _shortKg(v) : '—',
                                style: GoogleFonts.inter(
                                    color: isNow
                                        ? _Palette.green
                                        : (isPeak
                                        ? _Palette.peach
                                        : _Palette.textMuted),
                                    fontSize: r.fs(10),
                                    fontWeight: isNow || isPeak
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ])),
                            SizedBox(height: r.s(3)),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: hFrac),
                              duration:
                              Duration(milliseconds: 500 + i * 100),
                              curve: Curves.easeOutCubic,
                              builder: (_, anim, __) {
                                return Container(
                                  height: r.s(56) * anim,
                                  decoration: BoxDecoration(
                                    gradient: isNow
                                        ? const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        _Vibrant.neonGreen,
                                        _Palette.green,
                                      ],
                                    )
                                        : (isPeak
                                        ? LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        _Palette.peach,
                                        _Palette.peach
                                            .withOpacity(0.7),
                                      ],
                                    )
                                        : null),
                                    color: !isNow && !isPeak
                                        ? _Palette.sage.withOpacity(0.55)
                                        : null,
                                    borderRadius:
                                    BorderRadius.circular(r.s(8)),
                                    boxShadow: isNow
                                        ? [
                                      BoxShadow(
                                        color: _Vibrant.neonGreen
                                            .withOpacity(0.4),
                                        blurRadius: r.s(8),
                                        spreadRadius: 0,
                                        offset: Offset(0, r.s(2)),
                                      ),
                                    ]
                                        : null,
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: r.s(6)),
                            Text(isNow ? 'сейчас' : '-${3 - i}н',
                                style: GoogleFonts.inter(
                                    color: isNow
                                        ? _Palette.green
                                        : _Palette.textMuted,
                                    fontSize: r.fs(9),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
            if (hasGoal) ...[
              SizedBox(height: r.s(18)),
              Row(
                children: [
                  Expanded(
                    child: _GlossyProgress(
                      value: goalPct,
                      height: r.s(10),
                      gradient: [accent.withOpacity(0.75), accent],
                      track: Colors.white.withOpacity(0.7),
                      radius: r.s(5),
                    ),
                  ),
                  SizedBox(width: r.s(10)),
                  Text('${(goalPct * 100).round()}%',
                      style: GoogleFonts.inter(
                          color: accent, fontSize: r.fs(12),
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
              SizedBox(height: r.s(8)),
              Text(
                  goalReached
                      ? 'Цель достигнута · ${_goalPeriodWord(_selectedPeriod)}'
                      : 'До цели ${_goalPeriodWord(_selectedPeriod)}: ${_formatKg(goalForPeriod - currentVol)}',
                  style: GoogleFonts.inter(
                      color: _Palette.textMuted, fontSize: r.fs(11))),
            ],
            SizedBox(height: r.s(14)),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: r.s(12), color: _Palette.textMuted),
                SizedBox(width: r.s(4)),
                Expanded(child: Text('Тоннаж = вес × повторения × подходы',
                    style: GoogleFonts.inter(
                        color: _Palette.textMuted, fontSize: r.fs(10)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _countChip(String value, String label, _R r) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(6)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(r.s(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  color: _Palette.text, fontSize: r.fs(12),
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          SizedBox(width: r.s(4)),
          Text(label, style: GoogleFonts.inter(
              color: _Palette.textMuted, fontSize: r.fs(10),
              fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _editGoal() async {
    final r = _R(context);
    final ctrl = TextEditingController(text: _weeklyGoal.toStringAsFixed(0));
    final result = await showModalBottomSheet<double>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: r.s(16), right: r.s(16), top: r.s(16),
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(r.s(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: r.s(38), height: r.s(5),
                  decoration: BoxDecoration(
                      color: _Palette.divider,
                      borderRadius: BorderRadius.circular(r.s(3))))),
              SizedBox(height: r.s(20)),
              Text('ЦЕЛЬ ТОННАЖА',
                  style: GoogleFonts.inter(
                      color: _Palette.green, fontSize: r.fs(10),
                      fontWeight: FontWeight.w800, letterSpacing: 2.0)),
              SizedBox(height: r.s(4)),
              Text('Сколько кг за неделю?',
                  style: GoogleFonts.inter(
                      color: _Palette.text, fontSize: r.fs(20),
                      fontWeight: FontWeight.w600)),
              SizedBox(height: r.s(4)),
              Text('Цель месяца и года рассчитается автоматически',
                  style: GoogleFonts.inter(
                      color: _Palette.textMuted, fontSize: r.fs(11))),
              SizedBox(height: r.s(16)),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(
                    color: _Palette.text, fontSize: r.fs(22),
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '10000', suffixText: 'кг',
                  filled: true, fillColor: _Palette.bg,
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
                          fontWeight: FontWeight.w900, letterSpacing: 1.0)),
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
//  DASHED LINE PAINTER
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
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS
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
    required this.date, required this.workouts,
    required this.volume, required this.isToday, required this.isFuture,
  });
}

class _ConfettiParticle {
  final double xFrac, startY, vx, vy, rot0, rotV, size;
  final Color color;
  _ConfettiParticle({
    required this.xFrac, required this.startY,
    required this.vx, required this.vy,
    required this.rot0, required this.rotV,
    required this.color, required this.size,
  });
}

// ═══════════════════════════════════════════════════════════════════
//  CONFETTI PAINTER
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
            Rect.fromCenter(center: Offset.zero,
                width: p.size, height: p.size * 0.5),
            const Radius.circular(1.5)),
        Paint()..color = p.color.withOpacity((1 - t * 0.9).clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
//  HERO RINGS PAINTER
// ═══════════════════════════════════════════════════════════════════
class _HeroRingsPainter extends CustomPainter {
  final double anim;
  final List<bool> daysActive;
  final int daysPassed;
  final double caloriesProgress, workoutsProgress, streakProgress;
  final DateTime time;

  _HeroRingsPainter({
    required this.anim, required this.daysActive,
    required this.daysPassed, required this.caloriesProgress,
    required this.workoutsProgress, required this.streakProgress,
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

    _drawHourNumbers(canvas, center, rDigits * scale, _HeroAccents.sage, scale);
    _drawTimeDial(canvas, center, r1 * scale, stroke * scale, time,
        _HeroAccents.peach, anim);
    _drawDayLabels(canvas, center, rDayLabels * scale, daysActive,
        _HeroAccents.amber, scale);
    _drawDaysRing(canvas, center, r2 * scale, stroke * scale, daysActive,
        _HeroAccents.amber);
    _drawProgressRing(canvas, center, r3 * scale, stroke * scale,
        caloriesProgress * anim, _HeroAccents.sage);
    _drawProgressRing(canvas, center, r4 * scale, stroke * scale,
        workoutsProgress * anim, _HeroAccents.pink);
    _drawProgressRing(canvas, center, r5 * scale, stroke * scale,
        streakProgress * anim, _HeroAccents.sky);

    // 🆕 ЧАСЫ ВНУТРИ САМОГО ВНУТРЕННЕГО КОЛЬЦА r5
    _drawCenterClock(canvas, center, r5 * scale, stroke * scale, time);
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
        text: TextSpan(text: h.toString().padLeft(2, '0'),
            style: TextStyle(color: color.withOpacity(0.9),
                fontSize: fontSize, fontWeight: FontWeight.w900, height: 1,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4)
                ])),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawDayLabels(Canvas canvas, Offset center, double radius,
      List<bool> daysActive, Color color, double scale) {
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final fontSize = 10.5 * scale;
    for (int i = 0; i < 7; i++) {
      final angle = -math.pi / 2 + (i / 7.0 + 1.0 / 14.0) * 2 * math.pi;
      final pos = Offset(center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius);
      final isPast = i < daysPassed;
      final isToday = i == daysPassed - 1;

      Color textColor;
      FontWeight weight;
      if (isToday) {
        textColor = _Vibrant.vividPeach;
        weight = FontWeight.w900;
      } else if (isPast) {
        textColor = _Vibrant.neonGreen;
        weight = FontWeight.w900;
      } else {
        textColor = Colors.white.withOpacity(0.8);
        weight = FontWeight.w700;
      }

      final tp = TextPainter(
        text: TextSpan(text: names[i],
            style: TextStyle(color: textColor,
                fontSize: fontSize, fontWeight: weight, height: 1,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4)
                ])),
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
        canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
            Paint()..style = PaintingStyle.stroke
              ..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color);
      } else if (partial) {
        final partialSweep = (progress * 2 * math.pi) - (segStart * 2 * math.pi);
        canvas.drawArc(rect, startAngle + segGap, partialSweep - segGap, false,
            Paint()..style = PaintingStyle.stroke
              ..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color);
      } else {
        canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
            Paint()..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 0.75..strokeCap = StrokeCap.round
              ..color = Colors.white.withOpacity(0.2));
      }
    }
    final timeAngle = -math.pi / 2 + progress * 2 * math.pi;
    final dotPos = Offset(center.dx + math.cos(timeAngle) * radius,
        center.dy + math.sin(timeAngle) * radius);
    canvas.drawCircle(dotPos, stroke * 1.0,
        Paint()..color = color.withOpacity(0.55)
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
      final isPast = i < daysPassed;
      final isToday = i == daysPassed - 1;

      if (isToday) {
        canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
            Paint()..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 1.9..strokeCap = StrokeCap.round
              ..color = _HeroAccents.peach.withOpacity(0.55)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
            Paint()..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 1.15..strokeCap = StrokeCap.round
              ..color = _Vibrant.vividPeach);
      } else if (isPast) {
        canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
            Paint()..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 1.7..strokeCap = StrokeCap.round
              ..color = _Vibrant.neonGreen.withOpacity(0.30)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
            Paint()..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 1.05..strokeCap = StrokeCap.round
              ..color = _Vibrant.neonGreen);
        canvas.drawArc(rect, startAngle + segGap,
            (sweep - segGap * 2) * 0.18, false,
            Paint()..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 0.35..strokeCap = StrokeCap.round
              ..color = Colors.white.withOpacity(0.55));
      } else {
        canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
            Paint()..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 0.75..strokeCap = StrokeCap.round
              ..color = Colors.white.withOpacity(0.2));
      }
    }
  }

  void _drawProgressRing(Canvas canvas, Offset center, double radius,
      double stroke, double progress, Color color) {
    canvas.drawCircle(center, radius,
        Paint()..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.75..color = Colors.white.withOpacity(0.15));
    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, start, sweep, false,
        Paint()..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.6..strokeCap = StrokeCap.round
          ..color = color.withOpacity(0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawArc(rect, start, sweep, false,
        Paint()..style = PaintingStyle.stroke
          ..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color);
    canvas.drawArc(rect, start, sweep * 0.08, false,
        Paint()..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.4..strokeCap = StrokeCap.round
          ..color = Colors.white.withOpacity(0.65));
  }


  // 🆕 ЧАСЫ ВНУТРИ САМОГО ВНУТРЕННЕГО КОЛЬЦА r5
// r5 = 30, stroke = 10 → свободный радиус внутри кольца = r5 - stroke/2 = 25
  void _drawCenterClock(Canvas canvas, Offset center, double r5, double stroke, DateTime time) {
    // Часы занимают ~75% от свободного пространства внутри r5
    final clockR = (r5 - stroke * 0.5) * 0.78; // ≈ 19.5

    // 1. Тонкий ободок часов (чтобы визуально отделить от кольца r5)
    canvas.drawCircle(
      center, clockR + 1.5,
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // 2. 12 часовых меток
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * (math.pi / 180);
      final isMain = i % 3 == 0; // 12, 3, 6, 9
      final startR = clockR - (isMain ? 3.2 : 1.8);
      final endR = clockR - 0.3;
      final p1 = Offset(
        center.dx + math.cos(angle) * startR,
        center.dy + math.sin(angle) * startR,
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * endR,
        center.dy + math.sin(angle) * endR,
      );
      canvas.drawLine(
        p1, p2,
        Paint()
          ..color = Colors.white.withOpacity(isMain ? 0.9 : 0.5)
          ..strokeWidth = isMain ? 1.3 : 0.7
          ..strokeCap = StrokeCap.round,
      );
    }

    // 3. Расчёт углов стрелок
    final hours = time.hour % 12;
    final minutes = time.minute;
    final seconds = time.second;

    // 4. Часовая стрелка (короткая)
    final hourAngle = ((hours + minutes / 60) * 30 - 90) * (math.pi / 180);
    _drawClockHand(
      canvas, center, hourAngle,
      length: clockR * 0.48,
      width: 1.6,
      color: Colors.white.withOpacity(0.95),
    );

    // 5. Минутная стрелка (длинная)
    final minuteAngle = ((minutes + seconds / 60) * 6 - 90) * (math.pi / 180);
    _drawClockHand(
      canvas, center, minuteAngle,
      length: clockR * 0.72,
      width: 1.1,
      color: Colors.white.withOpacity(0.85),
    );

    // 6. Секундная стрелка (акцентный персиковый цвет)
    final secondAngle = (seconds * 6 - 90) * (math.pi / 180);
    _drawClockHand(
      canvas, center, secondAngle,
      length: clockR * 0.82,
      width: 0.5,
      color: _HeroAccents.peach,
    );

    // 7. Центральная заклёпка
    canvas.drawCircle(center, 1.8, Paint()..color = _HeroAccents.peach);
    canvas.drawCircle(center, 0.8, Paint()..color = Colors.white);
  }

// 🆕 Вспомогательный метод для отрисовки одной стрелки часов
  void _drawClockHand(
      Canvas canvas,
      Offset center,
      double angle, {
        required double length,
        required double width,
        required Color color,
      }) {
    final end = Offset(
      center.dx + math.cos(angle) * length,
      center.dy + math.sin(angle) * length,
    );
    // Лёгкая тень для эффекта "приподнятости" над кольцами
    final shadowOffset = const Offset(0.6, 0.9);
    canvas.drawLine(
      center + shadowOffset, end + shadowOffset,
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    // Основная стрелка
    canvas.drawLine(
      center, end,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroRingsPainter old) =>
      old.anim != anim ||
          old.caloriesProgress != caloriesProgress ||
          old.workoutsProgress != workoutsProgress ||
          old.streakProgress != streakProgress;
}

// ═══════════════════════════════════════════════════════════════════
//  TAP SCALE
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
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HERO AVATAR
// ═══════════════════════════════════════════════════════════════════
class _HeroAvatar extends StatelessWidget {
  final String emoji;
  final String? imagePath;
  final double size;
  final VoidCallback onTap;
  const _HeroAvatar({
    required this.emoji, required this.imagePath,
    required this.size, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = imagePath != null && imagePath!.isNotEmpty;
    final badgeSize = size * 0.32;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + badgeSize * 0.55,
        height: size + badgeSize * 0.55,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0, top: 0,
              child: Container(
                width: size, height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _Hero.bgBottom,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2),
                        blurRadius: 8, spreadRadius: -1),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: hasPhoto
                    ? Image.file(
                  File(imagePath!),
                  width: size, height: size, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _emojiFace(emoji, size * 0.45),
                )
                    : _emojiFace(emoji, size * 0.45),
              ),
            ),
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: badgeSize, height: badgeSize,
                decoration: BoxDecoration(
                  color: _Vibrant.vividPeach,
                  shape: BoxShape.circle,
                  border: Border.all(color: _Hero.bgTop, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: _Vibrant.vividPeach.withOpacity(0.55),
                        blurRadius: 8, spreadRadius: 1),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(Icons.edit_rounded,
                    color: Colors.white, size: badgeSize * 0.50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiFace(String e, double fs) {
    return Center(child: Text(e, style: TextStyle(fontSize: fs)));
  }
}

// ═══════════════════════════════════════════════════════════════════
//  GOLD LEVEL BADGE
// ═══════════════════════════════════════════════════════════════════
class _LevelBadge extends StatelessWidget {
  final int level;
  final double scale;
  const _LevelBadge({required this.level, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_Vibrant.goldTop, _Vibrant.goldMid, _Vibrant.goldBottom],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(color: _Vibrant.goldMid.withOpacity(0.45),
              blurRadius: 10, spreadRadius: 0.5, offset: const Offset(0, 3)),
          BoxShadow(color: Colors.white.withOpacity(0.45),
              blurRadius: 4, spreadRadius: -1, offset: const Offset(0, -1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 12 * scale,
              shadows: [
                Shadow(color: _Vibrant.goldBottom.withOpacity(0.6), blurRadius: 2),
              ]),
          SizedBox(width: 5 * scale),
          Text('Level $level',
              style: GoogleFonts.inter(
                color: Colors.white, fontSize: 11 * scale,
                fontWeight: FontWeight.w800, letterSpacing: 0.2,
                fontFeatures: const [FontFeature.tabularFigures()],
                shadows: [
                  Shadow(color: _Vibrant.goldBottom.withOpacity(0.6),
                      blurRadius: 2, offset: const Offset(0, 1)),
                ],
              )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  WEEK DAYS ROW
// ═══════════════════════════════════════════════════════════════════
class _WeekDaysRow extends StatefulWidget {
  final List<_DayData> weekData;
  final int todayIdx;
  final double scale;
  const _WeekDaysRow({
    required this.weekData, required this.todayIdx, required this.scale,
  });
  @override
  State<_WeekDaysRow> createState() => _WeekDaysRowState();
}

class _WeekDaysRowState extends State<_WeekDaysRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
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

        final double dotSize = isToday ? 16 * s : 12 * s;
        Color fill;
        Color border;
        List<BoxShadow> glow = const [];

        if (isToday) {
          fill = _Vibrant.vividPeach;
          border = _Vibrant.vividPeach;
          glow = [
            BoxShadow(color: _Vibrant.vividPeach.withOpacity(0.55),
                blurRadius: 10, spreadRadius: 1),
          ];
        } else if (isFuture) {
          fill = Colors.white.withOpacity(0.55);
          border = _Palette.textMuted.withOpacity(0.35);
        } else {
          fill = _Vibrant.neonGreen;
          border = _Vibrant.neonGreen;
          glow = [
            BoxShadow(color: _Vibrant.neonGreen.withOpacity(0.55),
                blurRadius: 8, spreadRadius: 0.5),
          ];
        }

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: dotSize + 12 * s,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isToday)
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) {
                          final p = _pulseCtrl.value;
                          return Container(
                            width: dotSize + 10 * s * p,
                            height: dotSize + 10 * s * p,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _Vibrant.vividPeach
                                    .withOpacity(0.45 * (1 - p)),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: dotSize, height: dotSize,
                      decoration: BoxDecoration(
                        color: fill,
                        shape: BoxShape.circle,
                        border: Border.all(color: border, width: 1.2),
                        boxShadow: glow,
                      ),
                      child: isToday || isPast
                          ? Center(
                        child: Container(
                          width: dotSize * 0.35,
                          height: dotSize * 0.35,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                          : null,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4 * s),
              Text(dayNames[i],
                  style: GoogleFonts.inter(
                    fontSize: 11 * s,
                    fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                    color: isToday
                        ? _Vibrant.vividPeach
                        : isPast
                        ? _Palette.text
                        : _Palette.textMuted,
                    height: 1,
                  )),
            ],
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  GLOSSY PROGRESS
// ═══════════════════════════════════════════════════════════════════
class _GlossyProgress extends StatelessWidget {
  final double value;
  final double height;
  final List<Color> gradient;
  final Color track;
  final double radius;
  const _GlossyProgress({
    required this.value, required this.gradient,
    this.height = 8, this.track = const Color(0x33FFFFFF),
    this.radius = 100,
  });

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: gradient.last.withOpacity(0.35),
                        blurRadius: 6, spreadRadius: -1),
                  ],
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.42,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(radius),
                          bottom: Radius.circular(radius * 0.4),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.55),
                            Colors.white.withOpacity(0.0),
                          ],
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
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
//  RETRO ANALOG CLOCK PAINTER (С ФОНОМ)
// ═══════════════════════════════════════════════════════════════════
class _RetroClockPainter extends CustomPainter {
  final DateTime time;
  _RetroClockPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Внешний металлический ободок
    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0);

    // 2. Внутренний тёмный циферблат (радиальный градиент)
    canvas.drawCircle(center, radius - 2, Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2B3A32).withOpacity(0.95), // Темно-зеленый/серый
          const Color(0xFF1B2027).withOpacity(0.98), // Почти черный
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 2))
      ..style = PaintingStyle.fill);

    // 3. Тонкая внутренняя рамка для глубины
    canvas.drawCircle(center, radius - 4, Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);

    // 4. Часовые метки (12 штук)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * (math.pi / 180);
      final isMain = i % 3 == 0; // 12, 3, 6, 9
      final startR = radius - (isMain ? 14 : 8);
      final endR = radius - 4;
      final p1 = Offset(center.dx + math.cos(angle) * startR, center.dy + math.sin(angle) * startR);
      final p2 = Offset(center.dx + math.cos(angle) * endR, center.dy + math.sin(angle) * endR);
      canvas.drawLine(p1, p2, Paint()
        ..color = Colors.white.withOpacity(isMain ? 0.9 : 0.5)
        ..strokeWidth = isMain ? 2.0 : 1.0
        ..strokeCap = StrokeCap.round);
    }

    // 5. Расчёт углов стрелок
    final hours = time.hour % 12;
    final minutes = time.minute;
    final seconds = time.second;

    // 6. Часовая стрелка
    final hourAngle = ((hours + minutes / 60) * 30 - 90) * (math.pi / 180);
    _drawHand(canvas, center, hourAngle, length: radius * 0.45, width: 3.0, color: Colors.white.withOpacity(0.95));

    // 7. Минутная стрелка
    final minuteAngle = ((minutes + seconds / 60) * 6 - 90) * (math.pi / 180);
    _drawHand(canvas, center, minuteAngle, length: radius * 0.7, width: 2.0, color: Colors.white.withOpacity(0.85));

    // 8. Секундная стрелка (акцентный ретро-цвет)
    final secondAngle = (seconds * 6 - 90) * (math.pi / 180);
    _drawHand(canvas, center, secondAngle, length: radius * 0.8, width: 1.0, color: _HeroAccents.peach);

    // 9. Центральная заклёпка
    canvas.drawCircle(center, 4.0, Paint()..color = Colors.black.withOpacity(0.5));
    canvas.drawCircle(center, 3.0, Paint()..color = _HeroAccents.peach);
    canvas.drawCircle(center, 1.5, Paint()..color = Colors.white);
  }

  void _drawHand(Canvas canvas, Offset center, double angle, {required double length, required double width, required Color color}) {
    final end = Offset(center.dx + math.cos(angle) * length, center.dy + math.sin(angle) * length);

    // Тень под стрелкой для эффекта 3D
    final shadowOffset = const Offset(1.0, 1.5);
    canvas.drawLine(center + shadowOffset, end + shadowOffset, Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // Основная стрелка
    canvas.drawLine(center, end, Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _RetroClockPainter old) =>
      old.time.minute != time.minute || old.time.second != time.second;
}

// ═══════════════════════════════════════════════════════════════════
//  SETTINGS SHEET
// ═══════════════════════════════════════════════════════════════════
class _SettingsSheet extends StatelessWidget {
  final String currentBg;
  final String bgLabel;
  const _SettingsSheet({required this.currentBg, required this.bgLabel});

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    return Container(
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
      decoration: BoxDecoration(
        color: _Palette.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
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
                  borderRadius: BorderRadius.circular(r.s(3)),
                ),
              ),
            ),
            SizedBox(height: r.s(20)),
            _SettingsTile(
              icon: Icons.person_rounded,
              iconColor: _Palette.green,
              iconBg: _Palette.greenSoft,
              title: 'Профиль',
              subtitle: 'Имя, аватар, статистика',
              onTap: () => Navigator.pop(context, 'profile'),
            ),
            SizedBox(height: r.s(10)),
            _SettingsTile(
              icon: Icons.wallpaper_rounded,
              iconColor: _Palette.peach,
              iconBg: _Palette.peachSoft,
              title: 'Фон главного экрана',
              subtitle: 'Текущий: $bgLabel',
              trailing: Container(
                width: r.s(48),
                height: r.s(48),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r.s(10)),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  currentBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _Palette.divider,
                    child: Icon(Icons.image_rounded,
                        color: _Palette.textMuted, size: r.s(20)),
                  ),
                ),
              ),
              onTap: () => Navigator.pop(context, 'background'),
            ),
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
        padding: EdgeInsets.all(r.s(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.s(18)),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: r.s(44),
              height: r.s(44),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(r.s(12)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: r.s(22)),
            ),
            SizedBox(width: r.s(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: _Palette.text,
                          fontSize: r.fs(14),
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: r.s(2)),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: _Palette.textMuted,
                          fontSize: r.fs(11))),
                ],
              ),
            ),
            SizedBox(width: r.s(8)),
            if (trailing != null) ...[
              trailing!,
              SizedBox(width: r.s(8)),
            ],
            Icon(Icons.chevron_right_rounded,
                color: _Palette.textMuted, size: r.s(20)),
          ],
        ),
      ),
    );
  }
}