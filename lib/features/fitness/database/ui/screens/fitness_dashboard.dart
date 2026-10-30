// features/fitness/ui/screens/fitness_dashboard.dart
// 🆕 v16: доминирующая метрика недели в hero (сила / кардио / бокс / статика)
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../nutrition/providers/nutrition_provider.dart';
import '../../../../nutrition/ui/screens/fuel_dashboard_screen.dart';
import '../../../models/enums.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/fitness_provider.dart';
import 'active_program_screen.dart';
import 'completed_programs_screen.dart';
import 'exercise_library_screen.dart';
import 'fitness_targets_screen.dart';
import 'photo_comparison_screen.dart';
import 'program_builder_screen.dart';
import 'program_view_screen.dart';
import 'progress_screen.dart';
import 'wellbeing_screen.dart';
import 'workout_execution_screen.dart';
import 'workout_log_screen.dart';

// ==================== iOS DESIGN SYSTEM ====================

class _IOS {
  static const Color lightBg = Color(0xFFF2F2F7);
  static const Color darkBg = Color(0xFF000000);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCard2 = Color(0xFFF9FAFB);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkCard2 = Color(0xFF2C2C2E);

  static const Color blue = Color(0xFF007AFF);
  static const Color green = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF9500);
  static const Color yellow = Color(0xFFFFCC00);
  static const Color purple = Color(0xFFAF52DE);
  static const Color teal = Color(0xFF5AC8FA);
  static const Color indigo = Color(0xFF5856D6);
  static const Color pink = Color(0xFFFF2D55);
  static const Color red = Color(0xFFFF3B30);
  static const Color gray = Color(0xFF8E8E93);
  static const Color brown = Color(0xFFA2845E);

  static Color separator(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color card2(bool isDark) => isDark ? darkCard2 : lightCard2;
  static Color bg(bool isDark) => isDark ? darkBg : lightBg;
  static Color textPrimary(bool isDark) => isDark ? Colors.white : Colors.black;
  static Color textSecondary(bool isDark) => isDark
      ? Colors.white.withOpacity(0.6)
      : const Color(0xFF3C3C43).withOpacity(0.6);
  static Color textTertiary(bool isDark) => isDark
      ? Colors.white.withOpacity(0.3)
      : const Color(0xFF3C3C43).withOpacity(0.3);
}

// ==================== POWER MODE TOKENS ====================

class _Power {
  static const Color heroBase = Color(0xFF0A0A0A);
  static const Color heroDeep = Color(0xFF120700);

  static const Color volt = Color(0xFFFF5500);
  static const Color voltBright = Color(0xFFFF7A1A);
  static const Color voltDim = Color(0xFFB33C00);

  static const Color magma = Color(0xFFFF2D55);
  static const Color plasma = Color(0xFFFFCC00);
  static const Color ice = Color(0xFF00E5FF);
  static const Color lime = Color(0xFFB4FF39);

  static List<BoxShadow> glow(Color color,
      {double strength = 0.4, double blur = 24}) =>
      [
        BoxShadow(
          color: color.withOpacity(strength),
          blurRadius: blur,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> softGlow(Color color, {double strength = 0.18}) => [
    BoxShadow(
      color: color.withOpacity(strength),
      blurRadius: 16,
    ),
  ];
}

class Achievement {
  final String emoji;
  final String title;
  final String description;
  final String category;
  final Color color;
  final bool isUnlocked;
  final double progress;
  final String requirement;

  const Achievement(
      this.emoji,
      this.title,
      this.description,
      this.category,
      this.color,
      this.isUnlocked,
      this.progress,
      this.requirement,
      );
}

class FitnessDashboard extends StatefulWidget {
  final bool isDark;

  const FitnessDashboard({
    super.key,
    this.isDark = false,
  });

  @override
  State<FitnessDashboard> createState() => _FitnessDashboardState();
}

class _FitnessDashboardState extends State<FitnessDashboard>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  late AnimationController _pulseController;

  NutritionProvider? _nutritionProvider;
  Future<NutritionProvider>? _nutritionFuture;

  String _avatarEmoji = '💪';
  String _profileName = 'Атлет';

  Color get _background => _IOS.bg(widget.isDark);
  Color get _surface => _IOS.card(widget.isDark);
  Color get _surface2 => _IOS.card2(widget.isDark);
  Color get _text => _IOS.textPrimary(widget.isDark);
  Color get _subText => _IOS.textSecondary(widget.isDark);
  Color get _muted => _IOS.textTertiary(widget.isDark);
  Color get _border => _IOS.separator(widget.isDark);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _avatarEmoji = prefs.getString('avatar_emoji') ?? '💪';
      _profileName = prefs.getString('profile_name') ?? '';
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<NutritionProvider> _getNutritionProvider() {
    _nutritionFuture ??= _initNutritionProvider();
    return _nutritionFuture!;
  }

  Future<NutritionProvider> _initNutritionProvider() async {
    if (_nutritionProvider != null) return _nutritionProvider!;
    final provider = NutritionProvider();
    await provider.init();
    _nutritionProvider = provider;
    return provider;
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 ХЕЛПЕРЫ МЕТРИК НЕДЕЛИ
  // ══════════════════════════════════════════════════════════

  /// Собирает все метрики за последние 7 дней.
  Map<String, double> _aggregateWeekMetrics(
      FitnessProvider provider,
      List<DateTime> last7,
      ) {
    final result = <String, double>{};
    for (final day in last7) {
      for (final log in provider.getLogsForDate(day)) {
        if (log.totalByMetric != null) {
          log.totalByMetric!.forEach((k, v) {
            result[k] = (result[k] ?? 0) + v;
          });
        } else if (log.totalVolume != null) {
          result['kg'] = (result['kg'] ?? 0) + log.totalVolume!;
        }
      }
    }
    return result;
  }

  /// Доминирующая метрика недели: km → rounds → kg → sec.
  ({String emoji, String value, String unit, Color color}) _dominantOfWeek(
      Map<String, double> m) {
    final km = m['km'] ?? 0;
    final rounds = m['rounds'] ?? 0;
    final kg = m['kg'] ?? 0;
    final sec = m['sec'] ?? 0;

    if (km > 0) {
      return (
      emoji: '📏',
      value: km.toStringAsFixed(km >= 10 ? 1 : 2),
      unit: 'км',
      color: _Power.ice,
      );
    }
    if (rounds > 0) {
      return (
      emoji: '🥊',
      value: rounds.toStringAsFixed(0),
      unit: 'раунд',
      color: _Power.plasma,
      );
    }
    if (kg > 0) {
      return (
      emoji: '⚡',
      value: _formatVolume(kg),
      unit: 'кг',
      color: _Power.ice,
      );
    }
    if (sec > 0) {
      if (sec >= 3600) {
        return (
        emoji: '⏱️',
        value: (sec / 3600).toStringAsFixed(1),
        unit: 'ч',
        color: _Power.ice,
        );
      }
      return (
      emoji: '⏱️',
      value: (sec / 60).toStringAsFixed(0),
      unit: 'м',
      color: _Power.ice,
      );
    }
    return (emoji: '📊', value: '0', unit: 'кг', color: _Power.ice);
  }

  // =====================================================================
  // BUILD
  // =====================================================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final stats = provider.getStats();
    final profile = provider.profile;
    final activeSession = provider.activeSession;

    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildPowerHero(provider, profile, stats),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          SliverToBoxAdapter(child: _buildKpiStrip(provider, stats)),

          if (activeSession != null) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(
              child: _buildActiveProgramBanner(provider, activeSession),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          SliverToBoxAdapter(
            child: _buildSectionHeader('ДОСТИЖЕНИЯ', 'ACHIEVEMENTS'),
          ),
          SliverToBoxAdapter(child: _buildAchievementsStrip(provider)),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          SliverToBoxAdapter(child: _buildTargetsPreview(provider)),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          SliverToBoxAdapter(
            child: _buildSectionHeader('БЫСТРЫЙ СТАРТ', 'QUICK ACTIONS'),
          ),
          SliverToBoxAdapter(child: _buildQuickActionsGrid(provider, stats)),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'ПИТАНИЕ',
              'NUTRITION',
              onTap: () async {
                final nutritionProvider = await _getNutritionProvider();
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: nutritionProvider,
                      child: FuelDashboardScreen(isDark: widget.isDark),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: _buildFuelPreview()),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'МОИ ПРОГРАММЫ',
              'PROGRAMS',
              onTap: () => _showProgramsList(context, provider),
            ),
          ),
          SliverToBoxAdapter(child: _buildProgramsRow(provider)),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'ПРОГРЕСС',
              'PROGRESS',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: ProgressScreen(isDark: widget.isDark),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: _buildProgressCards(stats)),

          if (provider.templates.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
            SliverToBoxAdapter(
              child: _buildSectionHeader('ШАБЛОНЫ', 'READY MADE'),
            ),
            SliverToBoxAdapter(child: _buildTemplatesGrid(provider)),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          SliverToBoxAdapter(
            child: _buildSectionHeader('ЕЩЁ', 'MORE'),
          ),
          SliverToBoxAdapter(child: _buildExtraGrid(provider)),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 POWER HERO — доминирующая метрика недели
  // ══════════════════════════════════════════════════════════

  Widget _buildPowerHero(
      FitnessProvider provider,
      UserFitnessProfile? profile,
      Map<String, dynamic> stats,
      ) {
    final now = DateTime.now();
    final last7 = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    // 🆕 Собираем все метрики за неделю
    final weekByMetric = _aggregateWeekMetrics(provider, last7);
    final dominant = _dominantOfWeek(weekByMetric);

    final weekWorkouts = last7.fold<int>(
      0,
          (sum, day) =>
      sum +
          provider
              .getLogsForDate(day)
              .where((log) => log.status == WorkoutDayStatus.completed)
              .length,
    );

    final displayName =
    _profileName.isNotEmpty ? _profileName : (profile?.name ?? 'Атлет');

    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF050505),
            Color(0xFF0F0700),
            Color(0xFF1A0A00),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Transform.rotate(
              angle: math.pi / 6,
              child: Container(
                width: 240,
                height: 400,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _Power.volt.withOpacity(0.0),
                      _Power.volt.withOpacity(0.18),
                      _Power.volt.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _Power.volt.withOpacity(0.0),
                    _Power.volt,
                    _Power.magma,
                    _Power.volt,
                    _Power.volt.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildPowerAvatar(provider),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting().toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (profile?.currentWeight != null)
                      _buildWeightPill(profile!.currentWeight!),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 74),
                  child: Text(
                    _getTodayDate(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildStreakRing(streak),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroBigNumber(
                            label: 'ЭТА НЕДЕЛЯ',
                            value: '$weekWorkouts',
                            unit: 'тренировок',
                            accent: _Power.volt,
                          ),
                          const SizedBox(height: 16),
                          // 🆕 Доминирующая метрика недели
                          _buildHeroBigNumber(
                            label: 'ОБЪЁМ',
                            value: '${dominant.emoji} ${dominant.value}',
                            unit: dominant.unit,
                            accent: dominant.color,
                          ),
                          // 🆕 Чипы остальных метрик (если их больше одной)
                          if (_hasMultipleWeekMetrics(weekByMetric)) ...[
                            const SizedBox(height: 10),
                            _buildWeekMetricChips(weekByMetric),
                          ],
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
    );
  }

  bool _hasMultipleWeekMetrics(Map<String, double> m) {
    int count = 0;
    for (final k in ['kg', 'km', 'rounds', 'sec']) {
      if ((m[k] ?? 0) > 0) count++;
    }
    return count > 1;
  }

  /// 🆕 Мини-чипы с остальными метриками недели (кроме доминирующей).
  Widget _buildWeekMetricChips(Map<String, double> m) {
    final chips = <Widget>[];

    void addChip(String emoji, String value, String label, Color color) {
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 9)),
            const SizedBox(width: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                height: 1,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                height: 1,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ));
    }

    if ((m['kg'] ?? 0) > 0) {
      addChip('⚡', _formatVolume(m['kg']!), 'КГ', _Power.ice);
    }
    if ((m['km'] ?? 0) > 0) {
      addChip(
          '📏', m['km']!.toStringAsFixed(m['km']! >= 10 ? 1 : 2), 'КМ', _Power.ice);
    }
    if ((m['rounds'] ?? 0) > 0) {
      addChip('🥊', m['rounds']!.toStringAsFixed(0), 'Р.', _Power.plasma);
    }
    if ((m['sec'] ?? 0) > 0) {
      final sec = m['sec']!;
      final label = sec >= 3600
          ? '${(sec / 3600).toStringAsFixed(1)}ч'
          : '${(sec / 60).toStringAsFixed(0)}м';
      addChip('⏱️', label, '', _Power.ice);
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildPowerAvatar(FitnessProvider provider) {
    return GestureDetector(
      onTap: () => _showEditProfileDialog(context, provider),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.all(3 + _pulseController.value * 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_Power.volt, _Power.magma],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _Power.volt.withOpacity(
                        0.35 + _pulseController.value * 0.25,
                      ),
                      blurRadius: 20 + _pulseController.value * 10,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _avatarEmoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -1,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _Power.volt,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0A0A0A),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightPill(double weight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            weight.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'КГ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakRing(int streak) {
    const goal = 30;
    final progress = (streak / goal).clamp(0.0, 1.0);

    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _Power.softGlow(_Power.volt, strength: 0.25),
            ),
          ),
          SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(
                Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              valueColor: const AlwaysStoppedAnimation(_Power.volt),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🔥',
                style: TextStyle(
                  fontSize: 18,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: _Power.volt.withOpacity(0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$streak',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getDaysWord(streak).toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBigNumber({
    required String label,
    required String value,
    required String unit,
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(color: accent.withOpacity(0.8), blurRadius: 8),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =====================================================================
  // KPI STRIP (без изменений)
  // =====================================================================

  Widget _buildKpiStrip(
      FitnessProvider provider,
      Map<String, dynamic> stats,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiTile(
              Icons.flash_on_rounded,
              '${stats['workoutsThisWeek'] ?? 0}',
              'НЕДЕЛЯ',
              _Power.volt,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildKpiTile(
              Icons.fitness_center_rounded,
              '${stats['totalWorkouts'] ?? 0}',
              'ВСЕГО',
              _Power.ice,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildKpiTile(
              Icons.flag_rounded,
              '${provider.activeTargets.length}',
              'ЦЕЛИ',
              _Power.plasma,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildKpiTile(
              Icons.photo_camera_rounded,
              '${provider.photos.length}',
              'ФОТО',
              _Power.lime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiTile(
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.22),
          width: 0.8,
        ),
        boxShadow: _Power.softGlow(color, strength: 0.06),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: _text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // ACTIVE PROGRAM BANNER (без изменений)
  // =====================================================================

  Widget _buildActiveProgramBanner(
      FitnessProvider provider,
      ProgramSession session,
      ) {
    final program = provider.programs.firstWhere(
          (p) => p.id == session.programId,
      orElse: () => WorkoutProgram(id: '', name: 'Неизвестная программа'),
    );

    final progress = session.progressPercent;
    final completedDays = session.daySessions
        .where((d) => d.status == DaySessionStatus.completed)
        .length;
    final totalDays = session.daySessions.length;
    final currentDayIndex = session.currentDayIndex;
    final currentDay = currentDayIndex < program.days.length
        ? program.days[currentDayIndex]
        : null;
    final isRestDay = currentDay?.isRestDay ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: provider,
                child: ActiveProgramScreen(
                  program: program,
                  isDark: widget.isDark,
                ),
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0A00), Color(0xFF0A0A0A)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _Power.volt.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: _Power.glow(_Power.volt, strength: 0.2, blur: 32),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _Power.volt,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _Power.softGlow(_Power.volt, strength: 0.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'АКТИВНА',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (session.streak > 0)
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: _Power.plasma, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '${session.streak}',
                            style: const TextStyle(
                              color: _Power.plasma,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  program.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.9,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isRestDay
                      ? 'Сегодня день отдыха 😴'
                      : 'День ${currentDayIndex + 1} из $totalDays • ${currentDay?.exercises.length ?? 0} упражнений',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor:
                          const AlwaysStoppedAnimation(_Power.volt),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$completedDays / $totalDays дней пройдено',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: _Power.volt,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _Power.glow(_Power.volt, strength: 0.4, blur: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRestDay
                            ? Icons.arrow_forward_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRestDay ? 'Открыть программу' : 'Продолжить',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
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

  // =====================================================================
  // SECTION HEADER (без изменений)
  // =====================================================================

  Widget _buildSectionHeader(
      String title,
      String subtitle, {
        VoidCallback? onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _Power.volt,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: _text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.9,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _Power.volt.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Все',
                      style: TextStyle(
                        color: _Power.volt,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _Power.volt,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================================
  // ACHIEVEMENTS (без изменений)
  // =====================================================================

  List<Achievement> _getAchievements(FitnessProvider provider) {
    final stats = provider.getStats();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final total = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    final volume = ((stats['totalVolume'] ?? 0) as num).toDouble();
    final week = ((stats['workoutsThisWeek'] ?? 0) as num).toInt();
    final exercises = ((stats['totalExercises'] ?? 0) as num).toInt();
    final completedSessions = provider.completedSessions.length;
    final targetCount = provider.activeTargets.length;
    final photos = provider.photos.length;
    final programs = provider.programs.length;
    final wellbeing = provider.getTodayWellbeing();

    double progress(num current, num goal) {
      if (goal <= 0) return 0;
      return (current / goal).clamp(0.0, 1.0).toDouble();
    }

    return [
      Achievement('🏁', 'Первый шаг', 'Проведи первую тренировку',
          'Тренировки', _IOS.green, total >= 1, progress(total, 1), '1 тренировка'),
      Achievement('💪', 'Десятка', 'Проведи 10 полноценных тренировок',
          'Тренировки', _IOS.teal, total >= 10, progress(total, 10), '10 тренировок'),
      Achievement('🎖️', 'Полтинник', 'Пройди отметку в 50 тренировок',
          'Тренировки', _IOS.blue, total >= 50, progress(total, 50), '50 тренировок'),
      Achievement('💎', 'Сотня', '100 тренировок',
          'Тренировки', _IOS.purple, total >= 100, progress(total, 100), '100 тренировок'),
      Achievement('🔥', 'Серия 3', '3 дня тренировок подряд',
          'Серии', _Power.volt, streak >= 3, progress(streak, 3), '3 дня подряд'),
      Achievement('🚀', 'Неделя силы', '7 дней тренировок подряд',
          'Серии', _IOS.purple, streak >= 7, progress(streak, 7), '7 дней подряд'),
      Achievement('🏋️', 'Тонна', 'Набери 10 000 кг тоннажа',
          'Объёмы', _IOS.pink, volume >= 10000, progress(volume, 10000), '10 000 кг'),
      Achievement('🏆', 'Финишер', 'Заверши первую программу',
          'Цели', _Power.plasma, completedSessions > 0,
          completedSessions > 0 ? 1.0 : 0.0, '1 программа'),
      Achievement('🎯', 'Целеустремлённость', 'Поставь фитнес-цель',
          'Цели', _IOS.purple, targetCount > 0,
          targetCount > 0 ? 1.0 : 0.0, '1 цель'),
      Achievement('📸', 'Первое фото', 'Добавь фото прогресса',
          'Прогресс', _Power.volt, photos > 0,
          photos > 0 ? 1.0 : 0.0, '1 фото'),
      Achievement('🧠', 'Осознанность', 'Запиши самочувствие',
          'Прогресс', _IOS.green, wellbeing != null,
          wellbeing != null ? 1.0 : 0.0, '1 запись'),
      Achievement('📚', 'Знаток базы', 'Изучи 50 упражнений',
          'Прогресс', _IOS.brown, exercises >= 50, progress(exercises, 50), '50 упражнений'),
      Achievement('⚡', 'Неделя в ударе', '3 тренировки за неделю',
          'Тренировки', _Power.ice, week >= 3, progress(week, 3), '3 тренировки'),
      Achievement('🏗️', 'Архитектор', 'Создай 5 программ',
          'Цели', _IOS.purple, programs >= 5, progress(programs, 5), '5 программ'),
    ];
  }

  Widget _buildAchievementsStrip(FitnessProvider provider) {
    final achievements = _getAchievements(provider);
    achievements.sort((a, b) =>
        (b.isUnlocked ? 1 : 0).compareTo(a.isUnlocked ? 1 : 0));

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _showAchievementDetails(achievement);
            },
            child: _buildAchievementPreview(achievement),
          );
        },
      ),
    );
  }

  Widget _buildAchievementPreview(Achievement achievement) {
    final color = achievement.color;
    final unlocked = achievement.isUnlocked;

    return Container(
      width: 156,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked ? color.withOpacity(0.45) : _border,
          width: unlocked ? 1.2 : 0.6,
        ),
        boxShadow: unlocked
            ? _Power.softGlow(color, strength: 0.15)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(unlocked ? 0.16 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: unlocked
                      ? _Power.softGlow(color, strength: 0.3)
                      : null,
                ),
                child: Center(
                  child: Text(
                    achievement.emoji,
                    style: TextStyle(
                      fontSize: 22,
                      color: unlocked ? null : Colors.white24,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (unlocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '✓',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.lock_rounded,
                  color: _muted,
                  size: 14,
                ),
            ],
          ),
          const Spacer(),
          Text(
            achievement.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? _text : _muted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          if (!unlocked)
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: achievement.progress,
                minHeight: 4,
                backgroundColor: _surface2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Text(
              achievement.category.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
        ],
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: _muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: achievement.color.withOpacity(0.14),
                  shape: BoxShape.circle,
                  boxShadow: achievement.isUnlocked
                      ? _Power.glow(achievement.color, strength: 0.35)
                      : null,
                ),
                child: Center(
                  child: Text(
                    achievement.emoji,
                    style: const TextStyle(fontSize: 46),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                achievement.title,
                style: TextStyle(
                  color: _text,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _subText,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface2,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Требование',
                          style: TextStyle(color: _subText, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          achievement.requirement,
                          style: TextStyle(
                            color: _text,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: achievement.progress,
                        minHeight: 7,
                        backgroundColor: _border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          achievement.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      achievement.isUnlocked
                          ? 'ПОЛУЧЕНО ✓'
                          : '${(achievement.progress * 100).round()}% ВЫПОЛНЕНО',
                      style: TextStyle(
                        color: achievement.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================================
  // TARGETS (без изменений)
  // =====================================================================

  Widget _buildTargetsPreview(FitnessProvider provider) {
    final active = provider.activeTargets;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _Power.volt.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: _Power.softGlow(_Power.volt, strength: 0.15),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: _Power.volt,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'МОИ ЦЕЛИ',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        active.isEmpty
                            ? 'Ещё не добавлены'
                            : '${active.length} активных',
                        style: TextStyle(
                          color: _text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _openTargets(provider),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: _Power.volt,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (active.isEmpty)
              _buildEmptyTarget(provider)
            else
              ...active
                  .take(2)
                  .map((target) => _buildMiniTargetCard(target, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTarget(FitnessProvider provider) {
    return GestureDetector(
      onTap: () => _openTargets(provider),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _Power.volt.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _Power.volt.withOpacity(0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _Power.volt,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _Power.softGlow(_Power.volt, strength: 0.4),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Поставить первую цель',
                    style: TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Например, жим 100 кг',
                    style: TextStyle(color: _subText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _Power.volt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTargetCard(FitnessTarget target, FitnessProvider provider) {
    final progress = target.progressPercent;

    return GestureDetector(
      onTap: () => _openTargets(provider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: target.accentColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  target.type.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: _border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        target.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: target.accentColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTargets(FitnessProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: FitnessTargetsScreen(isDark: widget.isDark),
        ),
      ),
    );
  }

  // =====================================================================
  // QUICK ACTIONS (без изменений)
  // =====================================================================

  Widget _buildQuickActionsGrid(
      FitnessProvider provider,
      Map<String, dynamic> stats,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
        children: [
          _buildQuickCard(
            icon: Icons.play_arrow_rounded,
            title: 'Быстрый старт',
            subtitle: 'Свободная тренировка',
            accent: _Power.volt,
            onTap: () => _quickStartWorkout(provider),
          ),
          _buildQuickCard(
            icon: Icons.fitness_center_rounded,
            title: 'Упражнения',
            subtitle: '${stats['totalExercises'] ?? 0} в базе',
            accent: _Power.ice,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: ExerciseLibraryScreen(isDark: widget.isDark),
                  ),
                ),
              );
            },
          ),
          _buildQuickCard(
            icon: Icons.book_rounded,
            title: 'Журнал',
            subtitle: '${stats['totalWorkouts'] ?? 0} записей',
            accent: _Power.plasma,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: WorkoutLogScreen(isDark: widget.isDark),
                  ),
                ),
              );
            },
          ),
          _buildQuickCard(
            icon: Icons.mood_rounded,
            title: 'Самочувствие',
            subtitle: 'Записать состояние',
            accent: _Power.lime,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: WellbeingScreen(isDark: widget.isDark),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withOpacity(0.18),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _Power.softGlow(accent, strength: 0.18),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _subText, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // NUTRITION (без изменений)
  // =====================================================================

  Widget _buildFuelPreview() {
    return FutureBuilder<NutritionProvider>(
      future: _getNutritionProvider(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingCard();

        final nutritionProvider = snapshot.data!;

        return ChangeNotifierProvider.value(
          value: nutritionProvider,
          child: Consumer<NutritionProvider>(
            builder: (context, provider, _) {
              if (provider.defaultGoals == null) return _buildLoadingCard();

              final today = DateTime.now();
              final summary = provider.getSummaryForDate(today);
              final goals = provider.getGoalsForDate(today);
              final percent = summary.percentOf(goals);
              final water = summary.waterPercentOf(goals);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: FuelDashboardScreen(isDark: widget.isDark),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _Power.ice.withOpacity(0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _Power.ice.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(13),
                                boxShadow:
                                _Power.softGlow(_Power.ice, strength: 0.15),
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: _Power.ice,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ПИТАНИЕ',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${summary.entriesCount} приёмов',
                                    style: TextStyle(
                                      color: _text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${summary.calories.round()} / ${goals.calories.round()}',
                              style: TextStyle(
                                color: _text,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            SizedBox(
                              width: 88,
                              height: 88,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 88,
                                    height: 88,
                                    child: CircularProgressIndicator(
                                      value: 1,
                                      strokeWidth: 8,
                                      valueColor: AlwaysStoppedAnimation(
                                        _border,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 88,
                                    height: 88,
                                    child: CircularProgressIndicator(
                                      value: percent.clamp(0.0, 1.0),
                                      strokeWidth: 8,
                                      strokeCap: StrokeCap.round,
                                      valueColor: const AlwaysStoppedAnimation(
                                        _Power.ice,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${summary.calories.round()}',
                                        style: TextStyle(
                                          color: _text,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.6,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ККАЛ',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildFuelRow(
                                    'Б',
                                    summary.protein,
                                    goals.protein,
                                    _IOS.green,
                                  ),
                                  const SizedBox(height: 9),
                                  _buildFuelRow(
                                    'Ж',
                                    summary.fat,
                                    goals.fat,
                                    _IOS.pink,
                                  ),
                                  const SizedBox(height: 9),
                                  _buildFuelRow(
                                    'У',
                                    summary.carbs,
                                    goals.carbs,
                                    _Power.plasma,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop_rounded,
                              color: _Power.ice,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: water.clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor: _border,
                                  valueColor: const AlwaysStoppedAnimation(
                                    _Power.ice,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${summary.waterMl} / ${goals.waterMl} мл',
                              style: const TextStyle(
                                color: _Power.ice,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFuelRow(
      String label,
      double current,
      double goal,
      Color color,
      ) {
    final percent = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${current.round()} г',
                    style: TextStyle(
                      color: _text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${goal.round()} г',
                    style: TextStyle(color: _subText, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 4,
                  backgroundColor: _border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 165,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _Power.volt,
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // PROGRAMS (без изменений)
  // =====================================================================

  Widget _buildProgramsRow(FitnessProvider provider) {
    if (provider.programs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildCreateProgramCard(provider),
      );
    }

    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: provider.programs.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == provider.programs.length) {
            return _buildAddProgramCard(provider);
          }
          final program = provider.programs[index];
          final isActive = provider.activeSession?.programId == program.id;
          return _buildProgramCard(program, isActive, provider);
        },
      ),
    );
  }

  Widget _buildCreateProgramCard(FitnessProvider provider) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: ProgramBuilderScreen(isDark: widget.isDark),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _Power.volt,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _Power.softGlow(_Power.volt, strength: 0.4),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Создать программу',
                    style: TextStyle(
                      color: _text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Свой тренировочный план',
                    style: TextStyle(color: _subText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _IOS.gray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProgramCard(FitnessProvider provider) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: ProgramBuilderScreen(isDark: widget.isDark),
            ),
          ),
        );
      },
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _Power.volt.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _Power.volt.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _Power.softGlow(_Power.volt, strength: 0.2),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: _Power.volt,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Создать',
              style: TextStyle(
                color: _text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'новую программу',
              textAlign: TextAlign.center,
              style: TextStyle(color: _subText, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramCard(
      WorkoutProgram program,
      bool isActive,
      FitnessProvider provider,
      ) {
    final stats = _getProgramStats(program);
    final accent = program.accentColor;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: isActive
                  ? ActiveProgramScreen(
                program: program,
                isDark: widget.isDark,
              )
                  : ProgramViewScreen(
                program: program,
                isDark: widget.isDark,
              ),
            ),
          ),
        );
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showProgramOptions(context, program, provider);
      },
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? accent.withOpacity(0.6) : _border,
            width: isActive ? 1.5 : 0.8,
          ),
          boxShadow: isActive ? _Power.softGlow(accent, strength: 0.2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      program.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _Power.softGlow(accent, strength: 0.4),
                    ),
                    child: const Text(
                      'АКТИВНА',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                else
                  Text(
                    _difficultyEmoji(program.difficulty),
                    style: const TextStyle(fontSize: 14),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              program.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${program.days.length} дней • ${program.sessionDurationMinutes} мин',
              style: TextStyle(color: _subText, fontSize: 11),
            ),
            if (program.description != null &&
                program.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  program.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            const Spacer(),
            Row(
              children: [
                _buildSmallProgramStat('${stats['completed']}', _IOS.green),
                const SizedBox(width: 5),
                _buildSmallProgramStat('${stats['pending']}', _Power.plasma),
                const Spacer(),
                Text(
                  isActive
                      ? '${(provider.activeSession!.progressPercent * 100).round()}%'
                      : '${program.days.length} дн.',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallProgramStat(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Map<String, int> _getProgramStats(WorkoutProgram program) {
    int completed = 0;
    int pending = 0;
    int skipped = 0;

    for (final day in program.days) {
      switch (day.status) {
        case WorkoutDayStatus.completed:
          completed++;
          break;
        case WorkoutDayStatus.pending:
          pending++;
          break;
        case WorkoutDayStatus.skipped:
          skipped++;
          break;
        default:
          break;
      }
    }

    return {
      'completed': completed,
      'pending': pending,
      'skipped': skipped,
    };
  }

  // =====================================================================
  // PROGRAM LIST (без изменений)
  // =====================================================================

  void _showProgramsList(BuildContext context, FitnessProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: _muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROGRAMS',
                          style: TextStyle(
                            color: _Power.volt,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Мои программы',
                          style: TextStyle(
                            color: _text,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: provider,
                            child: ProgramBuilderScreen(isDark: widget.isDark),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _Power.volt,
                        shape: BoxShape.circle,
                        boxShadow: _Power.softGlow(_Power.volt, strength: 0.4),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: provider.programs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center_rounded,
                        size: 52,
                        color: _muted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Нет программ',
                        style: TextStyle(
                          color: _text,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: provider.programs.length,
                  itemBuilder: (context, index) {
                    final program = provider.programs[index];
                    final active =
                        provider.activeSession?.programId == program.id;
                    return _buildProgramFullRow(
                      program,
                      active,
                      provider,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgramFullRow(
      WorkoutProgram program,
      bool isActive,
      FitnessProvider provider,
      ) {
    final accent = program.accentColor;
    final stats = _getProgramStats(program);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: isActive
                  ? ActiveProgramScreen(
                program: program,
                isDark: widget.isDark,
              )
                  : ProgramViewScreen(
                program: program,
                isDark: widget.isDark,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? accent.withOpacity(0.5) : _border,
            width: isActive ? 1.2 : 0.6,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  program.emoji,
                  style: const TextStyle(fontSize: 24),
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
                      Expanded(
                        child: Text(
                          program.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _text,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            'АКТИВНА',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${program.days.length} дней • ${program.sessionDurationMinutes} мин',
                    style: TextStyle(color: _subText, fontSize: 11),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _buildSmallProgramStat(
                          '${stats['completed']}', _IOS.green),
                      const SizedBox(width: 5),
                      _buildSmallProgramStat(
                          '${stats['pending']}', _Power.plasma),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: _IOS.gray,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // PROGRAM OPTIONS (без изменений)
  // =====================================================================

  void _showProgramOptions(
      BuildContext context,
      WorkoutProgram program,
      FitnessProvider provider,
      ) {
    final isActive = provider.activeSession?.programId == program.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: _muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  program.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (!isActive)
                _buildActionTile(
                  icon: Icons.play_arrow_rounded,
                  color: _Power.volt,
                  title: 'Начать программу',
                  subtitle: 'Запустить прохождение',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showStartProgramDialog(program, provider);
                  },
                ),
              if (isActive)
                _buildActionTile(
                  icon: Icons.play_circle_fill_rounded,
                  color: _IOS.green,
                  title: 'Продолжить',
                  subtitle:
                  'День ${provider.activeSession!.currentDayIndex + 1}',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: ActiveProgramScreen(
                            program: program,
                            isDark: widget.isDark,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              _buildActionTile(
                icon: Icons.edit_rounded,
                color: _IOS.blue,
                title: 'Редактировать',
                subtitle: 'Изменить программу',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: ProgramBuilderScreen(
                          existingProgram: program,
                          isDark: widget.isDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (isActive)
                _buildActionTile(
                  icon: Icons.pause_circle_outline_rounded,
                  color: _Power.volt,
                  title: 'Приостановить',
                  subtitle: 'Поставить на паузу',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await provider.pauseProgramSession();
                  },
                ),
              _buildActionTile(
                icon: Icons.delete_outline_rounded,
                color: _IOS.red,
                title: 'Удалить',
                subtitle: 'Удалить программу',
                onTap: () async {
                  Navigator.pop(ctx);
                  if (isActive) {
                    await provider.abandonProgramSession(
                      provider.activeSession!.id,
                    );
                  }
                  await provider.deleteProgram(program.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: _subText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _IOS.gray,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // START PROGRAM DIALOG (без изменений)
  // =====================================================================

  void _showStartProgramDialog(
      WorkoutProgram program,
      FitnessProvider provider,
      ) {
    ProgramDifficulty difficulty = ProgramDifficulty.standard;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: _surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                'Начать программу',
                style: TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    program.name,
                    style: TextStyle(
                      color: _subText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildDifficultyOption(
                    emoji: '🟢',
                    title: 'Гибкий',
                    subtitle: 'Можно пропускать дни',
                    selected: difficulty == ProgramDifficulty.flexible,
                    onTap: () {
                      setState(() => difficulty = ProgramDifficulty.flexible);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDifficultyOption(
                    emoji: '🟡',
                    title: 'Стандартный',
                    subtitle: 'Пропуск сбрасывает серию',
                    selected: difficulty == ProgramDifficulty.standard,
                    onTap: () {
                      setState(() => difficulty = ProgramDifficulty.standard);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDifficultyOption(
                    emoji: '🔴',
                    title: 'Хардкор',
                    subtitle: 'Пропуск сбрасывает неделю',
                    selected: difficulty == ProgramDifficulty.hardcore,
                    onTap: () {
                      setState(() => difficulty = ProgramDifficulty.hardcore);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Отмена',
                    style: TextStyle(color: _IOS.blue, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await provider.startProgramSession(
                        program.id,
                        difficulty: difficulty,
                      );
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: provider,
                            child: ActiveProgramScreen(
                              program: program,
                              isDark: widget.isDark,
                            ),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: _IOS.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Power.volt,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Начать',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDifficultyOption({
    required String emoji,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _Power.volt.withOpacity(0.10) : _surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _Power.volt : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: _subText, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: _Power.volt,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // QUICK START WORKOUT (без изменений)
  // =====================================================================

  void _quickStartWorkout(FitnessProvider provider) {
    final quickDay = WorkoutDay(
      id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
      programId: 'quick',
      dayNumber: 1,
      exercises: [],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _muted.withOpacity(0.3),
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
                          color: _Power.volt.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow:
                          _Power.softGlow(_Power.volt, strength: 0.2),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: _Power.volt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Быстрая тренировка',
                              style: TextStyle(
                                color: _text,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            Text(
                              'Выберите упражнения',
                              style: TextStyle(
                                color: _subText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: provider.exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = provider.exercises[index];
                        final added = quickDay.exercises.any(
                              (item) => item.exerciseId == exercise.id,
                        );
                        final exerciseColor =
                        exercise.muscleGroups.isNotEmpty
                            ? exercise.muscleGroups.first.color
                            : _IOS.gray;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _surface2,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: exerciseColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(
                                  exercise.exerciseType.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            title: Text(
                              exercise.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            trailing: GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  if (added) {
                                    quickDay.exercises.removeWhere(
                                          (item) =>
                                      item.exerciseId == exercise.id,
                                    );
                                  } else {
                                    quickDay.exercises.add(
                                      WorkoutExercise(
                                        id:
                                        'quick_ex_${quickDay.exercises.length}',
                                        exerciseId: exercise.id,
                                        order: quickDay.exercises.length,
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
                                      ? _IOS.red.withOpacity(0.14)
                                      : _Power.volt.withOpacity(0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  added
                                      ? Icons.remove_rounded
                                      : Icons.add_rounded,
                                  color:
                                  added ? _IOS.red : _Power.volt,
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
                                        isDark: widget.isDark,
                                      ),
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Power.volt,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'НАЧАТЬ • ${quickDay.exercises.length} УПР.',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
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

  // =====================================================================
  // PROGRESS CARDS (без изменений)
  // =====================================================================

  Widget _buildProgressCards(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildProgressCard(
              '🔥',
              '${stats['currentStreak'] ?? 0}',
              'ДНЕЙ СЕРИЯ',
              _Power.volt,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProgressScreen(isDark: widget.isDark),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildProgressCard(
              '🏋️',
              '${stats['totalWorkouts'] ?? 0}',
              'ТРЕНИРОВОК',
              _Power.ice,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutLogScreen(isDark: widget.isDark),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildProgressCard(
              '⚡',
              '${stats['workoutsThisWeek'] ?? 0}',
              'ЗА НЕДЕЛЮ',
              _Power.plasma,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProgressScreen(isDark: widget.isDark),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
      String emoji,
      String value,
      String label,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.18),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(13),
                boxShadow: _Power.softGlow(color, strength: 0.15),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: _text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // TEMPLATES (без изменений)
  // =====================================================================

  Widget _buildTemplatesGrid(FitnessProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.18,
        ),
        itemCount: math.min(4, provider.templates.length),
        itemBuilder: (context, index) {
          final template = provider.templates[index];

          return GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              try {
                final program =
                await provider.createProgramFromTemplate(template.id);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: ProgramViewScreen(
                        program: program,
                        isDark: widget.isDark,
                      ),
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: _IOS.red,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _Power.volt.withOpacity(0.18),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _Power.volt.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: _Power.volt,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: _muted,
                        size: 16,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _subText,
                      fontSize: 11,
                      height: 1.3,
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

  // =====================================================================
  // EXTRA (без изменений)
  // =====================================================================

  Widget _buildExtraGrid(FitnessProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.32,
        children: [
          _buildExtraCard(
            icon: Icons.flag_rounded,
            title: 'Мои цели',
            subtitle: '${provider.activeTargets.length} активных',
            color: _Power.volt,
            onTap: () => _openTargets(provider),
          ),
          _buildExtraCard(
            icon: Icons.photo_camera_rounded,
            title: 'Фотоотчёты',
            subtitle: '${provider.photos.length} фото',
            color: _Power.plasma,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: PhotoComparisonScreen(isDark: widget.isDark),
                  ),
                ),
              );
            },
          ),
          _buildWellbeingCard(provider),
          _buildExtraCard(
            icon: Icons.history_rounded,
            title: 'История программ',
            subtitle:
            '${provider.sessions.where((s) => s.status != ProgramSessionStatus.active).length} завершено',
            color: _IOS.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: CompletedProgramsScreen(isDark: widget.isDark),
                  ),
                ),
              );
            },
          ),
          _buildExtraCard(
            icon: Icons.trending_up_rounded,
            title: 'Детальный прогресс',
            subtitle: 'По упражнениям',
            color: _Power.lime,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: ProgressScreen(isDark: widget.isDark),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExtraCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.16),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(13),
                boxShadow: _Power.softGlow(color, strength: 0.15),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _subText, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWellbeingCard(FitnessProvider provider) {
    final wellbeing = provider.getTodayWellbeing();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: WellbeingScreen(isDark: widget.isDark),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _Power.lime.withOpacity(0.16),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _Power.lime.withOpacity(0.14),
                borderRadius: BorderRadius.circular(13),
                boxShadow: _Power.softGlow(_Power.lime, strength: 0.15),
              ),
              child: const Icon(
                Icons.mood_rounded,
                color: _Power.lime,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              'Самочувствие',
              style: TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 5),
            if (wellbeing != null)
              Row(
                children: [
                  _buildWellbeingValue('⚡', '${wellbeing.energyLevel}'),
                  const SizedBox(width: 8),
                  _buildWellbeingValue('😴', '${wellbeing.sleepQuality}'),
                  const SizedBox(width: 8),
                  _buildWellbeingValue('🎯', '${wellbeing.motivationLevel}'),
                ],
              )
            else
              Text(
                'Записать сегодня',
                style: TextStyle(color: _subText, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWellbeingValue(String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            color: _Power.lime,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // PROFILE DIALOG (без изменений)
  // =====================================================================

  void _showEditProfileDialog(
      BuildContext context,
      FitnessProvider provider,
      ) {
    final controller = TextEditingController(
      text: _profileName.isNotEmpty
          ? _profileName
          : (provider.profile?.name ?? ''),
    );

    final emojis = [
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
              decoration: BoxDecoration(
                color: _surface,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _muted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ПРОФИЛЬ',
                    style: TextStyle(
                      color: _Power.volt,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Атлет',
                    style: TextStyle(
                      color: _text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    style: TextStyle(
                      color: _text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Введите имя',
                      hintStyle: TextStyle(color: _muted),
                      filled: true,
                      fillColor: _surface2,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'АВАТАР',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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
                                ? _Power.volt.withOpacity(0.14)
                                : _surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? _Power.volt
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: selected
                                ? _Power.softGlow(_Power.volt, strength: 0.3)
                                : null,
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
                        backgroundColor: _Power.volt,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor: _Power.volt.withOpacity(0.5),
                      ),
                      child: const Text(
                        'СОХРАНИТЬ',
                        style: TextStyle(
                          fontSize: 15,
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

  // =====================================================================
  // HELPERS
  // =====================================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Доброе утро';
    if (hour >= 12 && hour < 17) return 'Добрый день';
    if (hour >= 17 && hour < 23) return 'Добрый вечер';
    return 'Доброй ночи';
  }

  String _getTodayDate() {
    final now = DateTime.now();
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k';
    }
    return volume.toStringAsFixed(0);
  }

  String _getDaysWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'день';
    if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'дня';
    }
    return 'дней';
  }

  String _difficultyEmoji(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return '🟢';
      case 'hardcore':
        return '🔴';
      default:
        return '🟡';
    }
  }
}