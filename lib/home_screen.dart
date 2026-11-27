// lib/home_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show MaskFilter, BlurStyle, FontFeature;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Fitness Imports
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
// Nutrition Imports
import 'features/nutrition/models/nutrition_models.dart' show FoodProduct;
import 'features/nutrition/models/wellness_models.dart';
import 'features/nutrition/models/nutrition_program.dart';
import 'features/nutrition/providers/nutrition_provider.dart';
import 'features/nutrition/providers/wellness_provider.dart';
import 'features/nutrition/ui/screens/add_pantry_screen.dart';
import 'features/nutrition/ui/screens/fuel_dashboard_screen.dart';
import 'features/nutrition/ui/screens/knowledge_screen.dart';
import 'features/nutrition/ui/screens/profile_screen.dart';
import 'features/nutrition/ui/screens/shopping_mode_screen.dart';
import 'features/nutrition/ui/widgets/season_vine_card.dart';
import 'features/nutrition/ui/screens/programs_hub_screen.dart';
import 'features/nutrition/ui/screens/plan_tracker_screen.dart';

part 'home_hero_creative.dart';
part 'home_hero.dart';
part 'home_widgets.dart';
part 'home_hero_extra.dart';

const int kWeekGoal = 7;

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

String _fmtNum(int n) {
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
  if (n >= 1000) {
    final s = n.toString();
    return '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}';
  }
  return '$n';
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
//  🆕 SECTION CONTAINER — обёртка для группировки карточек
// ═══════════════════════════════════════════════════════════════════
class _SectionContainer extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> children;
  final EdgeInsets? padding;

  const _SectionContainer({
    required this.emoji,
    required this.title,
    this.subtitle,
    required this.accentColor,
    this.actionLabel,
    this.onAction,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final r = _R(context);

    // 🛡️ Локальные переменные для корректного smart cast (null safety)
    final action = onAction;
    final label = actionLabel;

    return Padding(
      padding: padding ?? EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок секции
          Padding(
            padding: EdgeInsets.only(bottom: r.s(14)),
            child: Row(
              children: [
                Container(
                  width: r.s(32), height: r.s(32),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(r.s(10)),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: TextStyle(fontSize: r.s(16))),
                ),
                SizedBox(width: r.s(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                        style: GoogleFonts.inter(
                          color: _Palette.text,
                          fontSize: r.fs(17),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (subtitle != null)
                        Text(subtitle!,
                          style: GoogleFonts.inter(
                            color: _Palette.textMuted,
                            fontSize: r.fs(11),
                          ),
                        ),
                    ],
                  ),
                ),
                // ✅ Здесь smart cast гарантированно сработает
                if (label != null && action != null)
                  _TapScale(
                    onTap: action,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: r.s(4)),
                      child: Text(label, // восклицательный знак не нужен, Dart уже знает, что это не null
                        style: GoogleFonts.inter(
                          color: accentColor,
                          fontSize: r.fs(12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Контент секции
          ...children,
        ],
      ),
    );
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
  int _heroStyle = 0;
  int _pedometerBgIndex = 0;
  static const _pedometerBgPrefsKey = 'pedometer_bg_index';
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
      _profileName = prefs.getString('profile_name') ?? 'Спортсмен';
      _heroBgImage = prefs.getString('hero_bg_image') ?? 'assets/images/nature_hero2.jpg';
      _heroStyle = (prefs.getInt('hero_style') ?? 0).clamp(0, _heroStyleNames.length - 1);
      _pedometerBgIndex = prefs.getInt(_pedometerBgPrefsKey) ?? 0;
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

  Future<void> _openSettings() async {
    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SettingsSheet(
        currentBg: _heroBgImage,
        bgLabel: _heroBgLabels[_heroBgImage] ?? 'Природа',
        styleLabel: _heroStyleNames[_heroStyle],
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'profile') {
      await _openProfileScreen();
    } else if (action == 'style') {
      await _openStylePicker();
    } else if (action == 'background') {
      await _openBackgroundPicker();
    }
  }

  Future<void> _openStylePicker() async {
    final r = _R(context);
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ConstrainedBox(
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
                Center(
                  child: Container(
                    width: r.s(38), height: r.s(5),
                    decoration: BoxDecoration(
                      color: _Palette.divider,
                      borderRadius: BorderRadius.circular(r.s(3)),
                    ),
                  ),
                ),
                SizedBox(height: r.s(20)),
                Row(
                  children: [
                    Container(
                      width: r.s(38), height: r.s(38),
                      decoration: BoxDecoration(
                        color: _Palette.pinkSoft,
                        borderRadius: BorderRadius.circular(r.s(11)),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.dashboard_customize_rounded,
                          color: _Palette.pink, size: r.s(19)),
                    ),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Стиль шапки',
                            style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(18),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: r.s(2)),
                          Text('${_heroStyleNames.length} вариантов · сохраняется на устройстве',
                            style: GoogleFonts.inter(
                              color: _Palette.textMuted, fontSize: r.fs(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.s(18)),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: r.s(10),
                      crossAxisSpacing: r.s(10),
                      childAspectRatio: 0.86,
                      children: List.generate(_heroStyleNames.length, (i) {
                        final isSelected = i == _heroStyle;
                        return _TapScale(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(ctx, i);
                          },
                          child: Container(
                            padding: EdgeInsets.all(r.s(10)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(r.s(18)),
                              border: Border.all(
                                color: isSelected ? _Palette.green : Colors.white,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: _Palette.green.withOpacity(0.22),
                                  blurRadius: 14, spreadRadius: -2,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                                  : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _HeroStylePreview(style: i)),
                                SizedBox(height: r.s(8)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(_heroStyleNames[i],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: _Palette.text,
                                          fontSize: r.fs(13),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded,
                                          color: _Palette.green, size: r.s(16)),
                                  ],
                                ),
                                SizedBox(height: r.s(2)),
                                Text(_heroStyleDescriptions[i],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: _Palette.textMuted,
                                    fontSize: r.fs(9.5), height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && result != _heroStyle) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('hero_style', result);
      if (mounted) setState(() => _heroStyle = result);
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _openBackgroundPicker() async {
    final r = _R(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ConstrainedBox(
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
                Center(
                  child: Container(
                    width: r.s(38), height: r.s(5),
                    decoration: BoxDecoration(
                      color: _Palette.divider,
                      borderRadius: BorderRadius.circular(r.s(3)),
                    ),
                  ),
                ),
                SizedBox(height: r.s(20)),
                Row(
                  children: [
                    Container(
                      width: r.s(38), height: r.s(38),
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
                              color: _Palette.text, fontSize: r.fs(18),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: r.s(2)),
                          Text('${_heroBackgrounds.length} вариантов на выбор',
                            style: GoogleFonts.inter(
                              color: _Palette.textMuted, fontSize: r.fs(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.s(18)),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: r.s(10),
                      crossAxisSpacing: r.s(10),
                      childAspectRatio: 0.82,
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
                                  blurRadius: 12, spreadRadius: -2,
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
                                    child: Icon(Icons.image_not_supported_rounded,
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
                                Positioned(
                                  left: r.s(8), right: r.s(8), bottom: r.s(8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: r.fs(10.5),
                                            fontWeight: FontWeight.w700,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.5),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: r.s(18), height: r.s(18),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(Icons.check_rounded,
                                              color: _Palette.green, size: r.s(12)),
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

  Future<void> _cyclePedometerBg() async {
    HapticFeedback.selectionClick();
    final next = (_pedometerBgIndex + 1) % _heroBackgrounds.length;
    setState(() => _pedometerBgIndex = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pedometerBgPrefsKey, next);
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
                  // Шапка
                  SliverToBoxAdapter(
                    child: _HomeHero(
                      style: _heroStyle,
                      fitness: fitness,
                      nutrition: nutrition,
                      avatarEmoji: _avatarEmoji,
                      avatarImagePath: _avatarImagePath,
                      profileName: _profileName,
                      bgImage: _heroBgImage,
                      onSettings: _openSettings,
                      onShopping: () => _openShoppingMode(context, nutrition),
                      onPantry: () => _openAddPantry(context, nutrition),
                    ),
                  ),
                  // 🆕 СЕКЦИЯ 1: 💪 АКТИВНОСТЬ (фитнес + шагомер + аналитика + достижения + цели)
                  SliverToBoxAdapter(child: _entranceAt(0.20, _sectionFitness(fitness, pedometer))),
                  // 🆕 СЕКЦИЯ 2: 🥗 ПИТАНИЕ (план + калории + вода)
                  SliverToBoxAdapter(child: _entranceAt(0.45, _sectionNutrition(nutrition))),
                  // 🆕 СЕКЦИЯ 3: 🌿 ЗДОРОВЬЕ (сезонное)
                  SliverToBoxAdapter(child: _entranceAt(0.60, _sectionWellness(context))),
                  // 🆕 СЕКЦИЯ 4: ⚡ БЫСТРЫЕ ДЕЙСТВИЯ
                  SliverToBoxAdapter(child: _entranceAt(0.70, _sectionQuickDock(fitness))),
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
  //  🆕 СЕКЦИЯ 1: 💪 АКТИВНОСТЬ
  // ═════════════════════════════════════════════════════════
  Widget _sectionFitness(FitnessProvider fitness, PedometerProvider pedometer) {
    final r = _R(context);
    final stats = fitness.getStats();
    final badges = _getBadges(stats);
    final prs = _getPRs(fitness);
    final active = fitness.activeTargets;

    return _SectionContainer(
      emoji: '💪',
      title: 'Активность',
      subtitle: 'Тренировки, шаги и прогресс',
      accentColor: _Palette.green,
      actionLabel: 'Журнал',
      onAction: () => _openWorkoutLog(context),
      children: [
        // Фокус-карточка тренировки (на всю ширину)
        _focusCard(fitness, inner: true),
        SizedBox(height: r.s(14)),
        // Bento: неделя + серия
        _bentoTop(fitness, inner: true),
        SizedBox(height: r.s(14)),
        // Шагомер
        _stepsCard(pedometer, inner: true),
        SizedBox(height: r.s(14)),
        // Аналитика недели
        _unifiedRhythmVolumeCard(fitness, inner: true),
        // Достижения + рекорды (если есть)
        if (badges.isNotEmpty || prs.isNotEmpty) ...[
          SizedBox(height: r.s(14)),
          _achievementsAndPRs(fitness, r),
        ],
        // Цели
        SizedBox(height: r.s(14)),
        _targetsSection(fitness, inner: true),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  🆕 СЕКЦИЯ 2: 🥗 ПИТАНИЕ
  // ═════════════════════════════════════════════════════════
  Widget _sectionNutrition(NutritionProvider nutrition) {
    final r = _R(context);
    return _SectionContainer(
      emoji: '🥗',
      title: 'Питание',
      subtitle: 'Калории, вода и программа',
      accentColor: _Palette.pink,
      actionLabel: 'Подробнее',
      onAction: () => _openNutrition(context),
      children: [
        // Фокус-карточка питания (на всю ширину)
        _nutritionFocusCard(nutrition, inner: true),
        SizedBox(height: r.s(14)),
        // Bento: калории + вода
        _bentoMid(nutrition, inner: true),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  🆕 СЕКЦИЯ 3: 🌿 ЗДОРОВЬЕ
  // ═════════════════════════════════════════════════════════
  Widget _sectionWellness(BuildContext context) {
    final r = _R(context);
    final wellness = context.watch<WellnessProvider>();
    final nutrition = context.watch<NutritionProvider>();
    return _SectionContainer(
      emoji: '🌿',
      title: 'Здоровье и знания',
      subtitle: 'Сезонные советы и самочувствие',
      accentColor: _Palette.sage,
      actionLabel: 'База знаний',
      onAction: () => _openKnowledge(context),
      children: [
        SeasonVineCard(
          wellness: wellness,
          nutrition: nutrition,
          scale: r.scale,
          onOpenKnowledge: () => _openKnowledge(context),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  🆕 СЕКЦИЯ 4: ⚡ БЫСТРЫЕ ДЕЙСТВИЯ
  // ═════════════════════════════════════════════════════════
  Widget _sectionQuickDock(FitnessProvider fitness) {
    return _SectionContainer(
      emoji: '⚡',
      title: 'Быстрый старт',
      accentColor: _Palette.peach,
      children: [
        _quickDock(fitness, inner: true),
      ],
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
  //  FOCUS CARD (Тренировки) — с флагом inner
  // ═════════════════════════════════════════════════════════
  Widget _focusCard(FitnessProvider fitness, {bool inner = false}) {
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
    // 🆕 Отступы зависят от того, внутри ли секции карточка
    final outerPadding = inner
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), r.s(20));
    if (hasCover) {
      return Padding(
        padding: outerPadding,
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
                                    color: _Palette.green, fontSize: r.fs(9),
                                    fontWeight: FontWeight.w700, letterSpacing: 0.6,
                                  ),
                                ),
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
                          letterSpacing: -0.6, height: 1.15,
                        ),
                      ),
                      SizedBox(height: r.s(4)),
                      Text(subtitle,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: r.fs(12),
                        ),
                      ),
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
                                  color: _Palette.text,
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
      );
    }
    return Padding(
      padding: outerPadding,
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
                          fontWeight: FontWeight.w600, letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Text('25 мин · Дома',
                    style: GoogleFonts.inter(
                      color: _Palette.textMuted, fontSize: r.fs(11),
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.s(16)),
              Text(title,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: _Palette.text, fontSize: r.fs(22),
                  fontWeight: FontWeight.w400, letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: r.s(6)),
              Text(subtitle,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: _Palette.textMuted, fontSize: r.fs(12), height: 1.4,
                ),
              ),
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
                          fontSize: r.fs(13), fontWeight: FontWeight.w500,
                        ),
                      ),
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

  // ═════════════════════════════════
  //  NUTRITION FOCUS CARD — с флагом inner
  // ═════════════════════════════════
  Widget _nutritionFocusCard(NutritionProvider nutrition, {bool inner = false}) {
    final r = _R(context);
    final program = nutrition.activeProgram;
    final today = DateTime.now();
    final summary = nutrition.getSummaryForDate(today);
    final goals = nutrition.getGoalsForDate(today);
    final hasBg = program != null && program.backgroundImage != null && program.backgroundImage!.isNotEmpty;
    final bgImage = program?.backgroundImage;
    final outerPadding = inner
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20));
    if (program == null) {
      return Padding(
        padding: outerPadding,
        child: _TapScale(
          onTap: () => _openProgramsHub(context),
          child: Container(
            padding: EdgeInsets.all(r.s(20)),
            decoration: BoxDecoration(
              color: _Palette.pinkSoft,
              borderRadius: BorderRadius.circular(r.s(28)),
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
              boxShadow: [
                BoxShadow(
                  color: _Palette.pink.withOpacity(0.08),
                  blurRadius: 20, spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: r.s(52), height: r.s(52),
                  decoration: BoxDecoration(
                    color: _Palette.pink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(r.s(16)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.restaurant_menu_rounded,
                      color: _Palette.pink, size: 26),
                ),
                SizedBox(width: r.s(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('План питания',
                        style: GoogleFonts.inter(
                          color: _Palette.text, fontSize: r.fs(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: r.s(4)),
                      Text('Создай программу для отслеживания КБЖУ',
                        style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(12),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: _Palette.textMuted, size: r.s(20)),
              ],
            ),
          ),
        ),
      );
    }
    final kcalPct = goals.calories > 0
        ? (summary.calories / goals.calories).clamp(0.0, 1.2) : 0.0;
    final isOver = kcalPct > 1.05;
    final accentColor = isOver ? _Palette.pink : _Palette.green;
    final textColor = hasBg ? Colors.white : _Palette.text;
    final mutedColor = hasBg ? Colors.white.withOpacity(0.7) : _Palette.textMuted;
    final trackColor = hasBg ? Colors.white.withOpacity(0.2) : _Palette.divider;
    return Padding(
      padding: outerPadding,
      child: _TapScale(
        onTap: () => _openPlanTracker(context),
        child: Container(
          height: r.s(200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r.s(28)),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.08),
                blurRadius: 20, spreadRadius: -6,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (hasBg)
                Positioned.fill(
                  child: _AppImg(
                    path: bgImage,
                    fit: BoxFit.cover,
                    fallback: Container(color: _Palette.surface),
                  ),
                ),
              if (hasBg)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.75),
                        ],
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: r.s(42), height: r.s(42),
                                decoration: BoxDecoration(
                                  color: hasBg
                                      ? Colors.white.withOpacity(0.2)
                                      : (isOver ? _Palette.pinkSoft : _Palette.greenSoft),
                                  borderRadius: BorderRadius.circular(r.s(12)),
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.checklist_rtl_rounded,
                                    color: hasBg ? Colors.white : accentColor, size: r.s(22)),
                              ),
                              SizedBox(width: r.s(12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ПРОГРАММА',
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: mutedColor, fontSize: r.fs(10),
                                        fontWeight: FontWeight.w700, letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(program.name,
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: textColor, fontSize: r.fs(16),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: r.s(8)),
                        Icon(Icons.arrow_outward_rounded,
                            color: mutedColor, size: r.s(18)),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                  text: '${summary.calories.round()}',
                                  style: GoogleFonts.inter(
                                    color: textColor, fontSize: r.fs(28),
                                    fontWeight: FontWeight.w600, letterSpacing: -1.3,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${goals.calories.round()} ккал',
                                  style: GoogleFonts.inter(
                                    color: mutedColor, fontSize: r.fs(14),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ])),
                              SizedBox(height: r.s(6)),
                              Text(
                                isOver
                                    ? 'Перебор на ${(-summary.calories + goals.calories).abs().round()} ккал'
                                    : 'Осталось ${(goals.calories - summary.calories).round().clamp(0, 9999)} ккал',
                                style: GoogleFonts.inter(
                                  color: hasBg ? Colors.white : accentColor,
                                  fontSize: r.fs(12),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: r.s(12)),
                              _GlossyProgress(
                                value: kcalPct.clamp(0.0, 1.0),
                                height: r.s(6),
                                gradient: isOver
                                    ? const [_Vibrant.glowingPink, _Vibrant.vividPeach]
                                    : const [_Vibrant.neonGreen, _Palette.green],
                                track: hasBg ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.55),
                                radius: 100,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: r.s(16)),
                        SizedBox(
                          width: r.s(72), height: r.s(72),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: r.s(72), height: r.s(72),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: kcalPct.clamp(0.0, 1.0)),
                                  duration: const Duration(milliseconds: 1200),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, anim, __) => CircularProgressIndicator(
                                    value: anim,
                                    strokeWidth: r.s(6),
                                    backgroundColor: trackColor,
                                    valueColor: AlwaysStoppedAnimation(hasBg ? Colors.white : accentColor),
                                  ),
                                ),
                              ),
                              Text('${(kcalPct * 100).round()}%',
                                style: GoogleFonts.inter(
                                  color: textColor, fontSize: r.fs(15),
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [FontFeature.tabularFigures()],
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
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  BENTO TOP — с флагом inner
  // ═════════════════════════════════════════════════════════
  Widget _bentoTop(FitnessProvider fitness, {bool inner = false}) {
    final r = _R(context);
    final stats = fitness.getStats();
    final thisWeek = _getThisWeek(fitness, DateTime.now());
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final today = DateTime.now();
    final weekData = _buildWeekData(fitness, today, today.weekday - 1);
    final todayIdx = today.weekday - 1;
    final passedDays = todayIdx + 1;
    final weekProgress = (passedDays / 7).clamp(0.0, 1.0);
    final outerPadding = inner
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20));
    return Padding(
      padding: outerPadding,
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
                    border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                              fontWeight: FontWeight.w400, letterSpacing: -1.3,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          SizedBox(width: r.s(4)),
                          Text('/ 7',
                            style: GoogleFonts.inter(
                              color: _Palette.textMuted, fontSize: r.fs(15),
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      Text('тренировок на этой неделе',
                        style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(11),
                        ),
                      ),
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
                    border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Серия',
                            style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(13),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                                valueColor: const AlwaysStoppedAnimation(_Palette.peach),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$streak',
                                  style: GoogleFonts.inter(
                                    color: _Palette.text, fontSize: r.fs(36),
                                    fontWeight: FontWeight.w500, letterSpacing: -1.5,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                                Text('дней',
                                  style: GoogleFonts.inter(
                                    color: _Palette.textMuted, fontSize: r.fs(11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: r.s(6)),
                      Text('До рекорда — 2 дня',
                        style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(10),
                        ),
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
  //  BENTO MID — с флагом inner
  // ═════════════════════════════════════════════════════════
  Widget _bentoMid(NutritionProvider nutrition, {bool inner = false}) {
    final r = _R(context);
    final today = DateTime.now();
    final summary = nutrition.getSummaryForDate(today);
    final goals = nutrition.getGoalsForDate(today);
    final kcalPct = goals.calories > 0
        ? (summary.calories / goals.calories).clamp(0.0, 1.0) : 0.0;
    final waterPct = goals.waterMl > 0
        ? (summary.waterMl / goals.waterMl).clamp(0.0, 1.0) : 0.0;
    final outerPadding = inner
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20));
    return Padding(
      padding: outerPadding,
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
                    border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(Icons.arrow_outward_rounded,
                              color: _Palette.textMuted, size: r.s(16)),
                        ],
                      ),
                      SizedBox(height: r.s(14)),
                      Text('${summary.calories.round()}',
                        style: GoogleFonts.inter(
                          color: _Palette.text, fontSize: r.fs(28),
                          fontWeight: FontWeight.w400, letterSpacing: -1.3,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text('из ${goals.calories.round()} ккал',
                        style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(11),
                        ),
                      ),
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
                          color: _Palette.textMuted, fontSize: r.fs(10),
                        ),
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
                onTap: () => _openNutrition(context),
                child: Container(
                  padding: EdgeInsets.all(r.s(16)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(r.s(28)),
                    border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                            fontWeight: FontWeight.w400, letterSpacing: -1.3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        TextSpan(
                          text: '/ ${(goals.waterMl / 1000).toStringAsFixed(0)} л',
                          style: GoogleFonts.inter(
                            color: _Palette.textMuted, fontSize: r.fs(14),
                            letterSpacing: -1,
                          ),
                        ),
                      ])),
                      Text('Хороший темп',
                        style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(11),
                        ),
                      ),
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
  //  STEPS CARD — с флагом inner
  // ═════════════════════════════════════════════════════════
  Widget _stepsCard(PedometerProvider pedo, {bool inner = false}) {
    final r = _R(context);
    final pct = pedo.progress;
    final outerPadding = inner
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20));
    return Padding(
      padding: outerPadding,
      child: GestureDetector(
        onTap: () => _openPedometer(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r.s(28)),
          child: Container(
            height: r.s(180),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18, offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _heroBackgrounds[_pedometerBgIndex],
                  key: ValueKey(_pedometerBgIndex),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: _Palette.green),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.1),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(r.s(20), r.s(16), r.s(20), r.s(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(r.s(8)),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(r.s(12)),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
                            ),
                            child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 20),
                          ),
                          SizedBox(width: r.s(12)),
                          Expanded(
                            child: Text('ШАГОМЕР',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white, fontSize: r.s(12),
                                fontWeight: FontWeight.w700, letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          SizedBox(width: r.s(8)),
                          GestureDetector(
                            onTap: _cyclePedometerBg,
                            child: Container(
                              padding: EdgeInsets.all(r.s(8)),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
                              ),
                              child: const Icon(Icons.wallpaper_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${_fmtNum(pedo.steps)}',
                            style: GoogleFonts.inter(
                              color: Colors.white, fontSize: r.s(36),
                              fontWeight: FontWeight.w800, letterSpacing: -1.5,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          SizedBox(width: r.s(8)),
                          Padding(
                            padding: EdgeInsets.only(bottom: r.s(6)),
                            child: Text('/ ${_fmtNum(pedo.goal)} шагов',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.7), fontSize: r.s(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r.s(8)),
                      Text('${pedo.distanceKm.toStringAsFixed(1)} км · Ещё ${_fmtNum(pedo.remaining)} до цели',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.8), fontSize: r.s(12),
                        ),
                      ),
                      SizedBox(height: r.s(12)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: r.s(6),
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation(_Vibrant.neonGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  🆕 ОБЪЕДИНЁННЫЕ ДОСТИЖЕНИЯ + РЕКОРДЫ
  // ═════════════════════════════════════════════════════════
  Widget _achievementsAndPRs(FitnessProvider fitness, _R r) {
    final stats = fitness.getStats();
    final badges = _getBadges(stats);
    final prs = _getPRs(fitness);
    return Container(
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(r.s(24)),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Бейджи
          if (badges.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Маленькие победы',
                  style: GoogleFonts.inter(
                    color: _Palette.text, fontSize: r.fs(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('${badges.length}',
                  style: GoogleFonts.inter(
                    color: _Palette.green, fontSize: r.fs(11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: r.s(10)),
            SizedBox(
              height: r.s(120),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: badges.length,
                separatorBuilder: (_, __) => SizedBox(width: r.s(8)),
                itemBuilder: (_, i) {
                  final b = badges[i];
                  return Container(
                    width: r.s(115),
                    padding: EdgeInsets.all(r.s(12)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(r.s(18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: r.s(36), height: r.s(36),
                          decoration: BoxDecoration(
                            color: b.color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(b.emoji, style: TextStyle(fontSize: r.fs(18))),
                        ),
                        const Spacer(),
                        Text(b.label,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _Palette.text, fontSize: r.fs(11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: r.s(2)),
                        Text(b.subtitle,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _Palette.textMuted, fontSize: r.fs(9),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (prs.isNotEmpty) SizedBox(height: r.s(16)),
            if (prs.isNotEmpty) Container(height: 1, color: _Palette.divider.withOpacity(0.5)),
            if (prs.isNotEmpty) SizedBox(height: r.s(16)),
          ],
          // Рекорды
          if (prs.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Рекорды',
                  style: GoogleFonts.inter(
                    color: _Palette.text, fontSize: r.fs(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('${prs.length}',
                  style: GoogleFonts.inter(
                    color: _Palette.peach, fontSize: r.fs(11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: r.s(10)),
            SizedBox(
              height: r.s(96),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: prs.length,
                separatorBuilder: (_, __) => SizedBox(width: r.s(8)),
                itemBuilder: (_, i) {
                  final pr = prs[i];
                  return Container(
                    width: r.s(100),
                    padding: EdgeInsets.all(r.s(10)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(r.s(16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: r.s(26), height: r.s(26),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: pr.color.withOpacity(0.12),
                          ),
                          alignment: Alignment.center,
                          child: Text(pr.emoji, style: TextStyle(fontSize: r.fs(13))),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(pr.value,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: _Palette.text, fontSize: r.fs(18),
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8, height: 1,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            SizedBox(height: r.s(2)),
                            Text(pr.label,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: _Palette.textMuted, fontSize: r.fs(9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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

  // ═════════════════════════════════════════════════════════
  //  UNIFIED RHYTHM & VOLUME CARD — с флагом inner
  // ═════════════════════════════════════════════════════════
  Widget _unifiedRhythmVolumeCard(FitnessProvider fitness, {bool inner = false}) {
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
    final stats = fitness.getStats();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final totalWorkouts = weekData.fold<int>(0, (sum, d) => sum + d.workouts);
    final consistencyScore = (activeDays / 7 * 100).round();

    final outerPadding = inner
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20));
    return Padding(
      padding: outerPadding,
      child: Container(
        padding: EdgeInsets.all(r.s(20)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2027), Color(0xFF2A3A32)],
          ),
          borderRadius: BorderRadius.circular(r.s(28)),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
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
                  padding: EdgeInsets.all(r.s(9)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(r.s(11)),
                  ),
                  child: const Icon(Icons.insights_rounded, color: _Vibrant.neonGreen, size: 20),
                ),
                SizedBox(width: r.s(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('АНАЛИТИКА НЕДЕЛИ',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6), fontSize: r.s(10),
                          fontWeight: FontWeight.w700, letterSpacing: 1.2,
                        ),
                      ),
                      Text('Детальный обзор',
                        style: GoogleFonts.inter(
                          color: Colors.white, fontSize: r.fs(16),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (streak > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(6)),
                    decoration: BoxDecoration(
                      color: _Palette.peach.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(r.s(10)),
                    ),
                    child: Text('🔥 $streak',
                      style: GoogleFonts.inter(
                        color: _Palette.peach, fontSize: r.s(12),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: r.s(16)),
            // Метрики
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    r: r,
                    icon: '🏋️',
                    value: _formatKg(totalVol),
                    label: 'Тоннаж',
                    color: _Vibrant.neonGreen,
                  ),
                ),
                SizedBox(width: r.s(8)),
                Expanded(
                  child: _metricCard(
                    r: r,
                    icon: '📊',
                    value: _formatKg(avgPerDay),
                    label: 'Среднее',
                    color: _Vibrant.electricBlue,
                  ),
                ),
                SizedBox(width: r.s(8)),
                Expanded(
                  child: _metricCard(
                    r: r,
                    icon: '📅',
                    value: '$activeDays/7',
                    label: 'Дней',
                    color: _Vibrant.vividPeach,
                  ),
                ),
              ],
            ),
            SizedBox(height: r.s(16)),
            // График
            if (!hasAnyData)
              _rhythmEmptyDark(r)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: r.s(150),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: r.s(36),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: r.s(24)),
                                child: Text(_shortKg(maxVol),
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.5), fontSize: r.s(8.5),
                                    fontWeight: FontWeight.w500,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: r.s(24)),
                                child: Text(_shortKg(maxVol / 2),
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.5), fontSize: r.s(8.5),
                                    fontWeight: FontWeight.w500,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: r.s(24)),
                                child: Text('0',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.5), fontSize: r.s(8.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: r.s(6)),
                        Expanded(
                          child: Stack(
                            children: [
                              if (avgPerDay > 0 && maxVol > 0)
                                Positioned(
                                  left: 0, right: 0,
                                  bottom: r.s(36) + (r.s(100) * (avgPerDay / maxVol)),
                                  child: CustomPaint(
                                    painter: _DashedLinePainter(
                                      color: Colors.white.withOpacity(0.2),
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
                                  final hFrac = maxVol > 0 ? (vol / maxVol).clamp(0.0, 1.0) : 0.0;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: r.s(2.5)),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            height: r.s(16),
                                            child: vol > 0
                                                ? Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(_shortKg(vol),
                                                  style: GoogleFonts.inter(
                                                    fontSize: r.s(8),
                                                    fontWeight: isBest ? FontWeight.w800 : FontWeight.w500,
                                                    color: isBest ? _Palette.peach : Colors.white.withOpacity(0.7),
                                                    fontFeatures: const [FontFeature.tabularFigures()],
                                                  ),
                                                ),
                                              ),
                                            )
                                                : null,
                                          ),
                                          SizedBox(height: r.s(2)),
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0.0, end: hFrac),
                                            duration: Duration(milliseconds: 600 + i * 80),
                                            curve: Curves.easeOutCubic,
                                            builder: (_, anim, __) {
                                              final isEmpty = !hasWorkout && !isToday;
                                              return Container(
                                                height: r.s(100) * anim,
                                                constraints: BoxConstraints(
                                                  minHeight: hasWorkout ? r.s(4) : 0,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: isToday
                                                      ? const LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [_Vibrant.vividPeach, _Palette.peach],
                                                  )
                                                      : (isBest
                                                      ? const LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [_Vibrant.neonGreen, _Palette.green],
                                                  )
                                                      : null),
                                                  color: !isToday && !isBest
                                                      ? (isEmpty
                                                      ? Colors.white.withOpacity(0.1)
                                                      : Colors.white.withOpacity(0.25))
                                                      : null,
                                                  borderRadius: BorderRadius.vertical(
                                                    top: Radius.circular(r.s(5)),
                                                    bottom: Radius.circular(r.s(2)),
                                                  ),
                                                  border: isFuture
                                                      ? Border.all(color: Colors.white.withOpacity(0.1), width: 1)
                                                      : null,
                                                  boxShadow: isToday
                                                      ? [
                                                    BoxShadow(
                                                      color: _Vibrant.vividPeach.withOpacity(0.4),
                                                      blurRadius: r.s(8),
                                                      spreadRadius: 0,
                                                      offset: Offset(0, r.s(2)),
                                                    ),
                                                  ]
                                                      : (isBest
                                                      ? [
                                                    BoxShadow(
                                                      color: _Vibrant.neonGreen.withOpacity(0.3),
                                                      blurRadius: r.s(6),
                                                      offset: Offset(0, r.s(2)),
                                                    ),
                                                  ]
                                                      : null),
                                                ),
                                              );
                                            },
                                          ),
                                          SizedBox(height: r.s(6)),
                                          Text(dayNames[i],
                                            style: GoogleFonts.inter(
                                              color: isToday
                                                  ? _Palette.peach
                                                  : isFuture
                                                  ? Colors.white.withOpacity(0.4)
                                                  : Colors.white.withOpacity(0.7),
                                              fontSize: r.s(9),
                                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                                            ),
                                          ),
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
                  SizedBox(height: r.s(12)),
                  Container(
                    padding: EdgeInsets.all(r.s(10)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(r.s(12)),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.trending_up_rounded, color: _Vibrant.neonGreen, size: r.s(14)),
                        SizedBox(width: r.s(8)),
                        Expanded(
                          child: Text(
                            bestIdx >= 0
                                ? 'Лучший день: ${dayNames[bestIdx]} · ${_shortKg(bestVol)} кг'
                                : 'Тренировок за неделю: $totalWorkouts · Постоянство $consistencyScore%',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: r.s(10.5),
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }

  Widget _metricCard({
    required _R r,
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(r.s(10)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(r.s(14)),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: TextStyle(fontSize: r.s(13))),
              SizedBox(width: r.s(4)),
              Expanded(
                child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: r.s(14),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r.s(2)),
          Text(label,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.55),
              fontSize: r.s(9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rhythmEmptyDark(_R r) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.s(20)),
      child: Center(
        child: Column(
          children: [
            Text('🌱', style: TextStyle(fontSize: r.s(28))),
            SizedBox(height: r.s(8)),
            Text('Пока нет тренировок',
              style: GoogleFonts.inter(
                color: Colors.white, fontSize: r.s(13),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: r.s(3)),
            Text('Начни первую — статистика появится здесь',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.6), fontSize: r.s(10), height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  QUICK DOCK — с флагом inner
  // ═════════════════════════════════════════════════════════
  Widget _quickDock(FitnessProvider fitness, {bool inner = false}) {
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
    final outerPadding = inner
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(24));
    return Padding(
      padding: outerPadding,
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
  //  TARGETS — с флагом inner
  // ═════════════════════════════════════════════════════════
  Widget _targetsSection(FitnessProvider fitness, {bool inner = false}) {
    final r = _R(context);
    final active = fitness.activeTargets;
    final outerPadding = inner
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20));
    return Padding(
      padding: outerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!inner)
            Padding(
              padding: EdgeInsets.only(bottom: r.s(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Мои ориентиры',
                    style: GoogleFonts.inter(
                      color: _Palette.text, fontSize: r.fs(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _TapScale(
                    onTap: () => _openTargets(context),
                    child: Text('Изменить',
                      style: GoogleFonts.inter(
                        color: _Palette.green, fontSize: r.fs(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (active.isEmpty)
            _emptyTarget(r)
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(4)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(r.s(24)),
                border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
              ),
              child: Column(
                children: active.take(3).map((t) => _targetRow(t, fitness, r)).toList(),
              ),
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
        padding: EdgeInsets.symmetric(vertical: r.s(12)),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: r.s(48), height: r.s(48),
                  decoration: BoxDecoration(
                    color: target.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(r.s(14)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: hasImage
                      ? _AppImg(
                      path: imageUrl,
                      fallback: Text(emoji, style: TextStyle(fontSize: r.fs(22))))
                      : Text(emoji, style: TextStyle(fontSize: r.fs(22))),
                ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(target.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: _Palette.text, fontSize: r.fs(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text('Прогресс · ${(target.progressPercent * 100).round()}%',
                        style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(10),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: _Palette.textMuted, size: r.s(18)),
              ],
            ),
            SizedBox(height: r.s(8)),
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
          borderRadius: BorderRadius.circular(r.s(24)),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: r.s(48), height: r.s(48),
              decoration: BoxDecoration(
                color: _Palette.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: _Palette.green, size: r.s(22)),
            ),
            SizedBox(width: r.s(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Поставить первую цель',
                    style: GoogleFonts.inter(
                      color: _Palette.text, fontSize: r.fs(13),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text('Например, жим 100 кг',
                    style: GoogleFonts.inter(
                      color: _Palette.textMuted, fontSize: r.fs(11),
                    ),
                  ),
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final query = searchCtrl.text.trim().toLowerCase();
          final filtered = provider.exercises
              .where((e) => query.isEmpty || e.name.toLowerCase().contains(query))
              .toList();
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(20)),
            child: Column(
              children: [
                Container(
                  width: r.s(36),
                  height: r.s(4),
                  decoration: BoxDecoration(
                    color: _Palette.divider,
                    borderRadius: BorderRadius.circular(r.s(2)),
                  ),
                ),
                SizedBox(height: r.s(16)),
                Row(
                  children: [
                    Container(
                      width: r.s(36),
                      height: r.s(36),
                      decoration: BoxDecoration(
                        color: _Palette.greenSoft,
                        borderRadius: BorderRadius.circular(r.s(10)),
                      ),
                      child: Icon(Icons.bolt_rounded, color: _Palette.green, size: r.s(20)),
                    ),
                    SizedBox(width: r.s(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Быстрая тренировка',
                            style: GoogleFonts.inter(
                              color: _Palette.text,
                              fontSize: r.fs(17),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: r.s(1)),
                          Text('Выберите упражнения',
                            style: GoogleFonts.inter(
                              color: _Palette.textMuted,
                              fontSize: r.fs(11),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.s(14)),
                TextField(
                  controller: searchCtrl,
                  onChanged: (_) => setSheetState(() {}),
                  style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(14)),
                  decoration: InputDecoration(
                    hintText: 'Поиск...',
                    hintStyle: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13)),
                    prefixIcon: const Icon(Icons.search_rounded, color: _Palette.textMuted, size: 20),
                    filled: true,
                    fillColor: _Palette.bg,
                    contentPadding: EdgeInsets.symmetric(horizontal: r.s(14), vertical: r.s(10)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(r.s(12)),
                      borderSide: BorderSide(color: _Palette.divider, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(r.s(12)),
                      borderSide: BorderSide(color: _Palette.divider, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(r.s(12)),
                      borderSide: BorderSide(color: _Palette.green.withOpacity(0.4), width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: r.s(10)),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                      child: Text('Ничего не найдено',
                          style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13))))
                      : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: r.s(80)),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => SizedBox(height: r.s(8)),
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      final added = quickDay.exercises.any((item) => item.exerciseId == exercise.id);
                      final color = exercise.muscleGroups.isNotEmpty
                          ? exercise.muscleGroups.first.color
                          : _Palette.green;
                      final hasImage = exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty;
                      return Container(
                        decoration: BoxDecoration(
                          color: _Palette.bg,
                          borderRadius: BorderRadius.circular(r.s(14)),
                          border: Border.all(
                            color: added ? _Palette.green.withOpacity(0.3) : _Palette.divider,
                            width: added ? 1.2 : 0.6,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(4)),
                          leading: Container(
                            width: r.s(40),
                            height: r.s(40),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(r.s(11)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasImage
                                ? _AppImg(
                                path: exercise.imageUrl,
                                fallback: Center(
                                    child: Text(exercise.exerciseType.emoji, style: TextStyle(fontSize: r.fs(18)))))
                                : Center(
                                child: Text(exercise.exerciseType.emoji, style: TextStyle(fontSize: r.fs(18)))),
                          ),
                          title: Text(exercise.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: _Palette.text,
                              fontWeight: FontWeight.w600,
                              fontSize: r.fs(14),
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setSheetState(() {
                                if (added) {
                                  quickDay.exercises.removeWhere((item) => item.exerciseId == exercise.id);
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
                              width: r.s(30),
                              height: r.s(30),
                              decoration: BoxDecoration(
                                color: added ? _Palette.greenSoft : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                added ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                color: added ? _Palette.green : _Palette.divider,
                                size: r.s(26),
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
                    padding: EdgeInsets.only(top: r.s(12)),
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(ctx).size.width * 0.35,
                        height: r.s(50),
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
                            elevation: 4,
                            shadowColor: _Palette.green.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(r.s(16))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, size: 20),
                              SizedBox(width: r.s(6)),
                              Text(
                                'НАЧАТЬ · ${quickDay.exercises.length}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: r.fs(13),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
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
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: nutrition,
        child: const ShoppingModeScreen(),
      ),
    ));
  }

  void _openAddPantry(BuildContext context, NutritionProvider nutrition) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: nutrition,
        child: const AddPantryScreen(),
      ),
    ));
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

  void _openProgramsHub(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<NutritionProvider>(),
        child: const ProgramsHubScreen(),
      ),
    ));
  }

  void _openPlanTracker(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<NutritionProvider>(),
        child: const PlanTrackerScreen(),
      ),
    ));
  }
}