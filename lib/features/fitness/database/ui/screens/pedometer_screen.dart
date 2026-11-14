// features/fitness/database/ui/screens/pedometer_screen.dart
//
// NATURE PREMIUM REDESIGN
// — Сохранена вся функциональность исходного экрана.
// — Полностью переработана визуальная композиция и все карточки.
// — Фотографический Hero-блок + glassmorphism.
// — 🆕 Настраиваемый фон hero + меню настроек.
// ═══════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zal_life/features/fitness/providers/pedometer_provider.dart';
import 'package:zal_life/features/nutrition/providers/nutrition_provider.dart';
import 'package:zal_life/features/fitness/database/ui/screens/journey_view.dart'
    show JourneyView;
import 'package:zal_life/features/fitness/database/ui/screens/activity_log_screen.dart'
    show ActivityLogScreen;

// ═══════════════════════════════════════════════════════════════════
//  NATURE PREMIUM — Design tokens
// ═══════════════════════════════════════════════════════════════════
class _N {
  // Backgrounds
  static const bg = Color(0xFFF8FAF7);
  static const bgAlt = Color(0xFFEEF3EC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF2F6F0);

  // Text
  static const text = Color(0xFF1E2B24);
  static const textMuted = Color(0xFF78847C);
  static const textLight = Color(0xFFA9B3AD);
  static const divider = Color(0xFFE3EADF);

  // Greens
  static const green = Color(0xFF527D61);
  static const greenDeep = Color(0xFF315B45);
  static const greenSoft = Color(0xFFE5EFE6);

  // Accents
  static const orange = Color(0xFFFF9D35);
  static const orangeSoft = Color(0xFFFFF1E0);
  static const gold = Color(0xFFF5C45E);
  static const goldSoft = Color(0xFFFDF4E1);
  static const sky = Color(0xFF83C5DF);
  static const skySoft = Color(0xFFE7F3F8);
  static const lavender = Color(0xFFB5A4E8);
  static const lavenderSoft = Color(0xFFF0ECFA);
  static const pink = Color(0xFFD17A8F);
  static const pinkSoft = Color(0xFFFBEFF2);

  // Hero overlay
  static const heroTextHigh = Color(0xFFFFFFFF);
  static const heroTextLow = Color(0xCCFFFFFF);
}

class _T {
  static final display = GoogleFonts.inter(
    fontSize: 44,
    fontWeight: FontWeight.w600,
    letterSpacing: -2.0,
    color: _N.text,
    height: 1,
  );
  static final title3 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: _N.text,
  );
  static final headline = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: _N.text,
  );
  static final body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _N.textMuted,
  );
  static final caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _N.textMuted,
  );
  static final caption2 = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: _N.textMuted,
  );
  static final overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: _N.textMuted,
  );
}

const double _padH = 16;

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

  // 🆕 Настраиваемый фон hero
  String _heroBgImage = 'assets/images/nature_hero.jpg';

  static const _heroBackgrounds = [
    'assets/images/nature_hero.jpg',
    'assets/images/nature_hero2.jpg',
    'assets/images/nature_hero3.jpg',
    'assets/images/nature_hero4.jpg',
    'assets/images/nature_hero5.jpg',
    'assets/images/nature_hero6.jpg',
    'assets/images/nature_hero7.jpg',
  ];

  static const _heroBgLabels = {
    'assets/images/nature_hero.jpg': 'Тропа',
    'assets/images/nature_hero5.jpg': 'Лес',
    'assets/images/nature_hero6.jpg': 'Горы',
    'assets/images/nature_hero7.jpg': 'Закат1',
    'assets/images/nature_hero2.jpg': 'Закат2',
    'assets/images/nature_hero3.jpg': 'Закат3',
    'assets/images/nature_hero4.jpg': 'Закат4',
  };

  Color get _timeAccent {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return _N.gold;
    if (hour >= 12 && hour < 17) return _N.orange;
    if (hour >= 17 && hour < 21) return _N.lavender;
    return _N.sky;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 17) return 'Добрый день';
    return 'Добрый вечер';
  }

  String get _dateLabel {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    const days = [
      'Понедельник', 'Вторник', 'Среда', 'Четверг',
      'Пятница', 'Суббота', 'Воскресенье',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
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

    _loadHeroBg();

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

  Future<void> _loadHeroBg() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _heroBgImage = prefs.getString('pedometer_hero_bg') ??
          'assets/images/nature_hero.jpg';
    });
  }

  // ═════════════════════════════════════════════════════════
  //  SETTINGS + BACKGROUND PICKER
  // ═════════════════════════════════════════════════════════
  Future<void> _openSettings() async {
    HapticFeedback.selectionClick();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: _N.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _N.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'НАСТРОЙКИ ЭКРАНА',
                style: GoogleFonts.inter(
                  color: _N.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _settingsTile(
                icon: Icons.wallpaper_rounded,
                iconColor: _N.sky,
                iconBg: _N.skySoft,
                title: 'Фон шапки',
                subtitle:
                'Текущий: ${_heroBgLabels[_heroBgImage] ?? 'Тропа'}',
                onTap: () => Navigator.pop(ctx, 'background'),
                trailingThumb: _heroBgImage,
              ),
              const SizedBox(height: 10),
              _settingsTile(
                icon: Icons.straighten_rounded,
                iconColor: _N.lavender,
                iconBg: _N.lavenderSoft,
                title: 'Калибровка',
                subtitle: 'Рост и вес для расчётов',
                onTap: () => Navigator.pop(ctx, 'calibration'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'background') {
      await _openBackgroundPicker();
    } else if (action == 'calibration') {
      final p = _provider;
      if (p != null) _showCalibration(p);
    }
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingThumb,
  }) {
    return _Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _N.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _N.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: _N.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _N.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailingThumb != null) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  trailingThumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _N.divider,
                    child: const Icon(Icons.image_rounded,
                        color: _N.textMuted, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded,
                color: _N.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _openBackgroundPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: _N.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _N.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _N.skySoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.wallpaper_rounded,
                        color: _N.sky, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Фон экрана шагов',
                          style: GoogleFonts.inter(
                            color: _N.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Выберите картинку для шапки',
                          style: GoogleFonts.inter(
                            color: _N.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: _heroBackgrounds.map((path) {
                  final isSelected = path == _heroBgImage;
                  final label = _heroBgLabels[path] ?? '';
                  return _Press(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx, path);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? _N.green : Colors.white,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: _N.green.withOpacity(0.25),
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
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF83C5DF), Color(0xFF315B45)],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                  Icons.image_not_supported_rounded,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 28),
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
                            left: 10,
                            bottom: 10,
                            right: 10,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.check_rounded,
                                        color: _N.green, size: 14),
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
            ],
          ),
        ),
      ),
    );
    if (result != null && result != _heroBgImage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pedometer_hero_bg', result);
      if (mounted) setState(() => _heroBgImage = result);
      HapticFeedback.lightImpact();
    }
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
  //  BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final pedo = context.watch<PedometerProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final accent = pedo.goalReached ? _N.green : _timeAccent;
    final waterToday = nutrition.getWaterForDate(DateTime.now());

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _N.bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _hero(pedo, accent)),
              if (pedo.isContinuousWalk)
                SliverToBoxAdapter(child: _activeWalkBanner(pedo)),

              // СЕГОДНЯ
              _sectionLabel('СЕГОДНЯ', Icons.wb_sunny_outlined),
              SliverToBoxAdapter(child: _statTiles(pedo, accent)),
              SliverToBoxAdapter(child: _activityTimeCard(pedo)),
              SliverToBoxAdapter(child: _goalCard(pedo)),
              if (pedo.steps > 3000 && waterToday < 1000)
                SliverToBoxAdapter(child: _waterPrompt(nutrition)),

              // ПРОГРЕСС
              _sectionLabel('ПРОГРЕСС', Icons.trending_up_rounded),
              SliverToBoxAdapter(child: _levelCard(pedo)),
              SliverToBoxAdapter(child: _achievementsMini(pedo)),
              SliverToBoxAdapter(child: _comparisonCard(pedo)),
              SliverToBoxAdapter(child: _monthlyForecastCard(pedo)),
              SliverToBoxAdapter(child: _personalRecordCard(pedo)),
              SliverToBoxAdapter(child: _weeklySummary(pedo)),
              SliverToBoxAdapter(child: _activityScoreCard(pedo)),

              // ПУТЬ
              _sectionLabel('ПУТЬ', Icons.route_rounded),
              SliverToBoxAdapter(child: _virtualWalkProgress(pedo)),

              // ДЕТАЛИ
              _sectionLabel('ДЕТАЛИ', Icons.insights_rounded),
              SliverToBoxAdapter(child: _cadenceZones(pedo)),
              SliverToBoxAdapter(child: _calendarHeatmap(pedo)),
              SliverToBoxAdapter(child: _hourlyScroll(pedo)),
              SliverToBoxAdapter(child: _chartCard(pedo)),

              // НАГРАДЫ
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
                _N.green,
                _N.orange,
                _N.gold,
                _N.sky,
                _N.lavender,
                _N.pink,
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  SECTION LABEL
  // ═════════════════════════════════════════════════════════
  Widget _sectionLabel(String text, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_padH, 26, _padH, 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _N.greenSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 14, color: _N.green),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _N.text,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _N.divider,
                      _N.divider.withOpacity(0.0),
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
  //  HERO — фото природы + glassmorphism
  // ═════════════════════════════════════════════════════════
  Widget _hero(PedometerProvider pedo, Color accent) {
    final goalPct = (pedo.progress * 100).round();
    final screenH = MediaQuery.of(context).size.height;
    final heroMinH = screenH * 0.66;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: heroMinH),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          children: [
            // Photo (динамический фон)
            Positioned.fill(
              child: Image.asset(
                _heroBgImage,
                key: ValueKey(_heroBgImage),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF83C5DF), Color(0xFF315B45)],
                    ),
                  ),
                ),
              ),
            ),
            // Overlay for text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.20),
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.55),
                    ],
                    stops: const [0.0, 0.35, 0.72, 1.0],
                  ),
                ),
              ),
            ),
            // Bottom fade into page background
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 90,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _N.bg.withOpacity(0.0),
                        _N.bg.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heroTopRow(),
                    const SizedBox(height: 22),
                    _heroGreeting(),
                    const SizedBox(height: 24),
                    Center(child: _heroRing(pedo, accent, goalPct)),
                    const SizedBox(height: 16),
                    _heroStatusPills(pedo),
                    const SizedBox(height: 20),
                    _heroQuickStats(pedo),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroTopRow() {
    return Row(
      children: [
        _glassCircleBtn(
          Icons.arrow_back_ios_new_rounded,
              () => Navigator.pop(context),
        ),
        const Spacer(),
        _glassPillText('ТРЕКЕР АКТИВНОСТИ'),
        const Spacer(),
        _glassCircleBtn(
          Icons.tune_rounded,
          _openSettings,
        ),
      ],
    );
  }

  Widget _heroGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting,
          style: GoogleFonts.inter(
            color: _N.heroTextHigh,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dateLabel,
          style: GoogleFonts.inter(
            color: _N.heroTextLow,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _heroRing(PedometerProvider pedo, Color accent, int goalPct) {
    const size = 260.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // glass disc
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1.2,
              ),
            ),
          ),
          // rings
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: _dur(1400),
            curve: Curves.easeOutExpo,
            builder: (_, v, __) => CustomPaint(
              size: const Size(size, size),
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
          // center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_walk_rounded, color: accent, size: 20),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: pedo.steps.toDouble()),
                duration: _dur(1000),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(
                  v.round().toString(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -2.2,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'из ${_fmt(pedo.goal)} · $goalPct%',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStatusPills(PedometerProvider pedo) {
    final active = pedo.isWalking;
    final goalReached = pedo.goalReached;
    final remaining = (pedo.goal - pedo.steps).clamp(0, pedo.goal);

    return Wrap(
      alignment: WrapAlignment.center,
      runSpacing: 8,
      spacing: 8,
      children: [
        // status
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return _glassPill(
              leading: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? _N.green : Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [
                    BoxShadow(
                      color: _N.green.withOpacity(
                          0.4 + _pulseController.value * 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                      : null,
                ),
              ),
              text: active
                  ? 'В ДВИЖЕНИИ'
                  : (goalReached ? 'ЦЕЛЬ ДОСТИГНУТА' : 'СЕГОДНЯ'),
            );
          },
        ),
        // streak
        if (pedo.currentStreak > 0)
          _glassPill(
            leading: const Text('🔥', style: TextStyle(fontSize: 12)),
            text: '${pedo.currentStreak} дн.',
          ),
        // remaining
        _glassPill(
          leading: Icon(
            goalReached
                ? Icons.check_circle_rounded
                : Icons.flag_outlined,
            size: 12,
            color: goalReached ? _N.greenSoft : Colors.white,
          ),
          text: goalReached
              ? 'Цель дня'
              : 'Ещё ${_fmt(remaining)}',
        ),
      ],
    );
  }

  Widget _heroQuickStats(PedometerProvider pedo) {
    return Row(
      children: [
        Expanded(
          child: _quickStat(
            Icons.straighten_rounded,
            pedo.distanceKm.toStringAsFixed(2),
            'км',
            _N.sky,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickStat(
            Icons.local_fire_department_rounded,
            '${pedo.calories.round()}',
            'ккал',
            _N.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickStat(
            Icons.timer_rounded,
            '${pedo.activeMinutes}',
            'мин',
            _N.lavender,
          ),
        ),
      ],
    );
  }

  Widget _quickStat(IconData icon, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.85),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCircleBtn(IconData icon, VoidCallback onTap) {
    return _Press(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
          border: Border.all(
            color: Colors.white.withOpacity(0.22),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _glassPillText(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _glassPill({Widget? leading, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Soft card — базовый контейнер
  // ═════════════════════════════════════════════════════════
  Widget _softCard({
    required Widget child,
    Color? accent,
    EdgeInsets? padding,
    double radius = 24,
    Color? background,
    bool shadow = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: background ?? _N.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _N.divider, width: 1),
        boxShadow: shadow
            ? [
          BoxShadow(
            color: _N.greenDeep.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(18),
        child: child,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Active walk banner
  // ═════════════════════════════════════════════════════════
  Widget _activeWalkBanner(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 16, _padH, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_N.green, _N.greenDeep],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _N.greenDeep.withOpacity(0.20),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Transform.scale(
                scale: 1.0 + _pulseController.value * 0.15,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_walk_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Активная прогулка',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Не забудь про воду',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${pedo.walkDuration.inMinutes.toString().padLeft(2, '0')}:${(pedo.walkDuration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
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
  //  STAT TILES
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
              'км',
              _N.sky,
              _N.skySoft,
              hint: '${((pedo.distanceKm / 8) * 100).clamp(0, 999).round()}%',
              onTap: () => _openJournal(pedo),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statTile(
              Icons.speed_rounded,
              '${pedo.cadence}',
              'шаг/мин',
              _N.pink,
              _N.pinkSoft,
              hint: pedo.cadence >= 100 ? 'темп ✓' : 'спокойно',
              onTap: () => _openJournal(pedo),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statTile(
              Icons.local_fire_department_rounded,
              '${pedo.currentStreak}',
              'стрик',
              _N.orange,
              _N.orangeSoft,
              hint: pedo.currentStreak > 0 ? 'дней' : '—',
              onTap: () => _openJournal(pedo, initialTab: 1),
            ),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: _N.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _N.divider, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              color: _N.text,
              fontSize: 20,
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
              color: _N.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(
              hint,
              style: GoogleFonts.inter(
                color: accent,
                fontSize: 10,
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
  //  Activity time card
  // ═════════════════════════════════════════════════════════
  Widget _activityTimeCard(PedometerProvider pedo) {
    final rate = pedo.steps > 0
        ? (pedo.activeMinutes / (pedo.steps / 1000)).toStringAsFixed(1)
        : '—';
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
      child: _Press(
        onTap: () => _openJournal(pedo, initialTab: 0),
        child: _softCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _N.greenSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.timer_rounded,
                    color: _N.green, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'АКТИВНОЕ ВРЕМЯ',
                      style: GoogleFonts.inter(
                        color: _N.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${pedo.activeMinutes} мин',
                          style: GoogleFonts.inter(
                            color: _N.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· $rate мин/1000',
                          style: GoogleFonts.inter(
                            color: _N.textMuted,
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
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _N.greenSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'История',
                  style: GoogleFonts.inter(
                    color: _N.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
  //  Goal card
  // ═════════════════════════════════════════════════════════
  Widget _goalCard(PedometerProvider pedo) {
    const presets = [5000, 8000, 10000, 12000];
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
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
                    color: _N.orangeSoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child:
                  const Icon(Icons.flag_rounded, color: _N.orange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ДНЕВНАЯ ЦЕЛЬ',
                        style: GoogleFonts.inter(
                          color: _N.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_fmt(pedo.goal)} шагов',
                        style: GoogleFonts.inter(
                          color: _N.text,
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
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _N.orangeSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Изменить',
                      style: GoogleFonts.inter(
                        color: _N.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
                      color: selected ? _N.orange : _N.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? _N.orange : _N.divider,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      _fmt(p),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? Colors.white : _N.textMuted,
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

  // ═════════════════════════════════════════════════════════
  //  Level card
  // ═════════════════════════════════════════════════════════
  Widget _levelCard(PedometerProvider pedo) {
    final rank = _rankForLevel(pedo.level);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
      child: _Press(
        onTap: () => _openJournal(pedo, initialTab: 1),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _N.lavenderSoft,
                _N.surface,
                _N.lavenderSoft.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _N.divider),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_N.lavender, _N.lavender],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _N.lavender.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              rank.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: _N.lavender,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '· ур. ${pedo.level}',
                              style: GoogleFonts.inter(
                                color: _N.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_fmt(pedo.stepsToNextLevel)} шагов до ${pedo.level + 1}',
                          style: GoogleFonts.inter(
                            color: _N.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _N.goldSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 12, color: _N.gold),
                        const SizedBox(width: 3),
                        Text(
                          '${pedo.achievementPoints} AP',
                          style: GoogleFonts.inter(
                            color: _N.gold,
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
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: LinearProgressIndicator(
                  value: pedo.levelProgress,
                  minHeight: 6,
                  backgroundColor: _N.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation(_N.lavender),
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
    final pct = total > 0 ? unlocked / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
      child: _Press(
        onTap: () => _openJournal(pedo, initialTab: 1),
        child: _softCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _N.goldSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: _N.gold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ДОСТИЖЕНИЯ',
                          style: GoogleFonts.inter(
                            color: _N.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Открыто $unlocked из $total',
                          style: GoogleFonts.inter(
                            color: _N.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: CircularProgressIndicator(
                            value: pct,
                            strokeWidth: 3,
                            backgroundColor: _N.surfaceAlt,
                            valueColor:
                            const AlwaysStoppedAnimation(_N.gold),
                          ),
                        ),
                        Text(
                          '${(pct * 100).round()}',
                          style: GoogleFonts.inter(
                            color: _N.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      color: _N.textMuted, size: 20),
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
          color: unlocked ? _N.goldSoft : _N.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unlocked ? _N.gold.withOpacity(0.25) : _N.divider,
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: unlocked ? _N.gold : _N.textMuted, size: 18),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: unlocked ? _N.text : _N.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.inter(
                color: _N.textMuted,
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
  //  Comparison
  // ═════════════════════════════════════════════════════════
  Widget _comparisonCard(PedometerProvider pedo) {
    final diff = pedo.weekDiffPercent;
    final positive = diff >= 0;
    final color = positive ? _N.green : _N.pink;
    final thisWeek = pedo.weeklySteps;
    final lastWeek = pedo.lastWeekSteps;
    final maxVal = math.max(thisWeek, lastWeek).clamp(1, 1 << 30);
    final thisPct = thisWeek / maxVal;
    final lastPct = lastWeek / maxVal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
      child: _softCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
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
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Сравнение активности',
                        style: GoogleFonts.inter(
                          color: _N.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
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
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _comparisonValue(
                      'Эта', '${thisWeek}', _N.orange, thisPct),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _N.surfaceAlt,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'vs',
                      style: GoogleFonts.inter(
                        color: _N.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _comparisonValue(
                      'Прошлая', '${lastWeek}', _N.textMuted, lastPct),
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
            color: _N.text,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: barPct,
            minHeight: 5,
            backgroundColor: _N.surfaceAlt,
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
  //  Monthly forecast
  // ═════════════════════════════════════════════════════════
  Widget _monthlyForecastCard(PedometerProvider pedo) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
      child: _softCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _N.skySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insights_rounded,
                  color: _N.sky, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ПРОГНОЗ НА МЕСЯЦ',
                    style: GoogleFonts.inter(
                      color: _N.sky,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pedo.monthlyProjection.toStringAsFixed(0),
                        style: GoogleFonts.inter(
                          color: _N.text,
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
                            color: _N.textMuted,
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
                      color: _N.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
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
                          ? _N.sky.withOpacity(0.55)
                          : _N.surfaceAlt,
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
  //  Personal record
  // ═════════════════════════════════════════════════════════
  Widget _personalRecordCard(PedometerProvider pedo) {
    if (pedo.bestDaySteps == 0) return const SizedBox.shrink();

    String dateStr = '';
    try {
      final best =
      pedo.history.where((h) => h.steps == pedo.bestDaySteps).toList();
      if (best.isNotEmpty) {
        final d = best.first.date;
        dateStr = '${d.day}.${d.month.toString().padLeft(2, '0')}';
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
      child: _Press(
        onTap: () => _openJournal(pedo, initialTab: 2),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _N.goldSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _N.gold.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _N.gold,
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
                        color: _N.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_fmt(pedo.bestDaySteps)} шагов за день',
                      style: GoogleFonts.inter(
                        color: _N.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        'установлен $dateStr',
                        style: GoogleFonts.inter(
                          color: _N.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _N.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Weekly summary
  // ═════════════════════════════════════════════════════════
  Widget _weeklySummary(PedometerProvider pedo) {
    final last7 = pedo.history.length >= 7
        ? pedo.history.sublist(pedo.history.length - 7)
        : pedo.history;
    final maxSteps =
    last7.map((d) => d.steps).fold<int>(0, (m, v) => math.max(m, v));
    const days = ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
      child: _softCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: _N.lavenderSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.date_range_rounded,
                      color: _N.lavender, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ИТОГИ ЗА 7 ДНЕЙ',
                        style: GoogleFonts.inter(
                          color: _N.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${pedo.weeklySteps} шагов',
                            style: GoogleFonts.inter(
                              color: _N.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('·',
                              style: TextStyle(
                                  color: _N.textMuted,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Text(
                            '${pedo.weeklyDistance.toStringAsFixed(1)} км',
                            style: GoogleFonts.inter(
                              color: _N.lavender,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
              ],
            ),
            if (last7.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
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
                              height: 28 * frac + 3,
                              decoration: BoxDecoration(
                                color: reached
                                    ? _N.lavender
                                    : _N.lavender.withOpacity(0.30),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              days[d.date.weekday - 1],
                              style: GoogleFonts.inter(
                                color: _N.textMuted,
                                fontSize: 9,
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
  //  Activity score
  // ═════════════════════════════════════════════════════════
  Widget _activityScoreCard(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
      child: _softCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 46,
                        height: 46,
                        child: CircularProgressIndicator(
                          value: pedo.activityScore / 100,
                          strokeWidth: 4,
                          backgroundColor: _N.surfaceAlt,
                          valueColor: AlwaysStoppedAnimation(_timeAccent),
                        ),
                      ),
                      Text(
                        '${pedo.activityScore}',
                        style: GoogleFonts.inter(
                          color: _timeAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ИНДЕКС АКТИВНОСТИ',
                        style: GoogleFonts.inter(
                          color: _N.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'из 100 · сегодня',
                        style: GoogleFonts.inter(
                          color: _N.text,
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
                _miniStat(
                    '🔥', '${pedo.calories.round()}', 'ККАЛ', _N.orange),
                _miniStat(
                    '⏱', '${pedo.activeMinutes}', 'МИН', _N.lavender),
                _miniStat('🚀', pedo.averageSpeed.toStringAsFixed(1), 'КМ/Ч',
                    _N.sky),
                _miniStat(
                    '🏆', '${pedo.bestDaySteps}', 'РЕКОРД', _N.gold),
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
            color: _N.text,
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
            color: _N.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Water prompt
  // ═════════════════════════════════════════════════════════
  Widget _waterPrompt(NutritionProvider nutrition) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
      child: _softCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _N.skySoft,
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
                  color: _N.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            _Press(
              onTap: () {
                HapticFeedback.mediumImpact();
                nutrition.addWater(250);
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _N.sky,
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
  //  Virtual walk
  // ═════════════════════════════════════════════════════════
  Widget _virtualWalkProgress(PedometerProvider pedo) {
    const double totalRoute = 9300;
    final walked = pedo.totalDistanceKmAllTime;
    final progress = (walked / totalRoute).clamp(0.0, 1.0);
    final remaining = (totalRoute - walked).clamp(0.0, totalRoute);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
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
              colors: [_N.greenDeep, _N.green],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _N.greenDeep.withOpacity(0.20),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
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
                          Colors.white.withOpacity(0.10),
                          Colors.white.withOpacity(0.0),
                        ],
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
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
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
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.75),
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
                                  color: Colors.white,
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
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              color: Colors.white,
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
                          color: Colors.white.withOpacity(0.75),
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
                                    color: Colors.white.withOpacity(0.15),
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
                                        Colors.white,
                                        Color(0xFFE5EFE6),
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
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${remaining.toStringAsFixed(0)} км до цели',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.65),
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
  //  Cadence zones
  // ═════════════════════════════════════════════════════════
  Widget _cadenceZones(PedometerProvider pedo) {
    final z1 = pedo.zone1Minutes;
    final z2 = pedo.zone2Minutes;
    final z3 = pedo.zone3Minutes;
    final total = z1 + z2 + z3;
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
      child: _softCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ЗОНЫ ИНТЕНСИВНОСТИ',
                  style: GoogleFonts.inter(
                    color: _N.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const Spacer(),
                Text(
                  '${total.round()} мин',
                  style: GoogleFonts.inter(
                    color: _N.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _zoneRow('🐢 Прогулочная', '< 100 шаг/мин', z1, _N.sky,
                _N.skySoft),
            const SizedBox(height: 11),
            _zoneRow('🚶 Активная', '100-120 шаг/мин', z2, _N.gold,
                _N.goldSoft),
            const SizedBox(height: 11),
            _zoneRow('🏃 Быстрая', '> 120 шаг/мин', z3, _N.pink,
                _N.pinkSoft),
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
                  color: _N.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: _N.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(8),
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

    final daysWithGoal = data.where((d) => d.steps >= pedo.goal).length;
    final now = DateTime.now();
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    const daysOfWeek = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
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
                    color: _N.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _N.greenSoft,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$daysWithGoal из 28 с целью',
                    style: GoogleFonts.inter(
                      color: _N.green,
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
                color: _N.text,
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
                  color: _N.textMuted,
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
                  cellColor = _N.pink.withOpacity(0.65);
                } else if (ratio >= 1.0) {
                  cellColor = _N.green.withOpacity(0.75);
                } else if (ratio >= 0.5) {
                  cellColor = _N.green.withOpacity(0.40);
                } else if (ratio > 0) {
                  cellColor = _N.green.withOpacity(0.18);
                } else {
                  cellColor = _N.surfaceAlt;
                }

                if (index == 27) borderColor = _N.text;

                return Tooltip(
                  message:
                  '${day.date.day}.${day.date.month} — ${day.steps} шагов',
                  triggerMode: TooltipTriggerMode.tap,
                  decoration: BoxDecoration(
                    color: _N.text,
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
                _legendBox(_N.surfaceAlt, '0'),
                _legendBox(_N.green.withOpacity(0.18), 'Мало'),
                _legendBox(_N.green.withOpacity(0.40), '50%'),
                _legendBox(_N.green.withOpacity(0.75), '100%'),
                _legendBox(_N.pink.withOpacity(0.65), '150%+'),
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
              color: _N.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  Hourly
  // ═════════════════════════════════════════════════════════
  Widget _hourlyScroll(PedometerProvider pedo) {
    final sortedHours = pedo.hourlySteps.keys.toList()..sort();
    if (sortedHours.isEmpty) return const SizedBox.shrink();

    final maxSteps =
    sortedHours.map((h) => pedo.hourlySteps[h] ?? 0).reduce(math.max);

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
                    color: _N.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                if (peakHour >= 0) ...[
                  const Spacer(),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _timeAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(7),
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
            height: 104,
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
                    color: _N.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPeak ? _timeAccent : _N.divider,
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
                          color: _N.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$steps',
                        style: GoogleFonts.inter(
                          color: _N.text,
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
        0, (m, d) => d.steps > m ? d.steps.toDouble() : m);
    final maxY = math.max(maxData, pedo.goal.toDouble()) * 1.2;
    final avg = safeData.isEmpty
        ? 0.0
        : safeData.fold<int>(0, (s, d) => s + d.steps) / safeData.length;
    final spots = List.generate(
      safeData.length,
          (i) => FlSpot(i.toDouble(), safeData[i].steps.toDouble()),
    );
    final bestIdx = safeData.indexWhere((d) => d.steps == maxData.round());

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
      child: _softCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _timeAccent.withOpacity(0.12),
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
                            color: _N.textMuted,
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
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _N.surfaceAlt,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      _isMonthlyChart ? '7 дней' : '30 дней',
                      style: GoogleFonts.inter(
                        color: _N.text,
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
                      getTooltipColor: (_) => _N.text,
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
                        color: _N.green.withOpacity(0.35),
                        strokeWidth: 1.4,
                        dashArray: [6, 6],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: GoogleFonts.inter(
                            color: _N.green,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          labelResolver: (_) => 'ЦЕЛЬ',
                        ),
                      ),
                      if (avg > 0)
                        HorizontalLine(
                          y: avg,
                          color: _N.textMuted.withOpacity(0.30),
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
                                color:
                                isLast ? _timeAccent : _N.textMuted,
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
                      color: _N.divider,
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
                                : (isBest ? _N.green : Colors.white),
                            strokeWidth: 2,
                            strokeColor: isBest && !isLast
                                ? _N.green
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
  //  Quests
  // ═════════════════════════════════════════════════════════
  Widget _questsSection(PedometerProvider pedo) {
    final quests = pedo.quests;
    if (quests.isEmpty) return const SizedBox.shrink();

    final allDone = quests.every((q) => q.isCompleted);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 0),
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
                    color: _N.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const Spacer(),
                if (allDone)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _N.greenSoft,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'ВСЕ ✓',
                      style: GoogleFonts.inter(
                        color: _N.green,
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
                  color: _N.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: q.isCompleted
                        ? _N.green.withOpacity(0.25)
                        : _N.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: q.isCompleted
                            ? _N.greenSoft
                            : _N.surfaceAlt,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        q.isCompleted
                            ? Icons.check_rounded
                            : Icons.flag_rounded,
                        color: q.isCompleted ? _N.green : _N.textMuted,
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
                              q.isCompleted ? _N.textMuted : _N.text,
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
                              color: _N.textMuted,
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
                                backgroundColor: _N.surfaceAlt,
                                valueColor:
                                AlwaysStoppedAnimation(_timeAccent),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(q.progress * 100).round()}%',
                      style: GoogleFonts.inter(
                        color: q.isCompleted ? _N.green : _timeAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        fontFeatures: const [FontFeature.tabularFigures()],
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
  //  Achievements horizontal
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
                    color: _N.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _N.surfaceAlt,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '${achievements.where((a) => a.unlocked).length}/${achievements.length}',
                    style: GoogleFonts.inter(
                      color: _N.textMuted,
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
            height: 132,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _padH),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final a = achievements[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: a.unlocked ? _N.goldSoft : _N.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: a.unlocked
                          ? _N.gold.withOpacity(0.35)
                          : _N.divider,
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
                              color: a.unlocked ? null : _N.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: a.unlocked ? _N.text : _N.textMuted,
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
                                color: _N.surfaceAlt,
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
  //  Permission card
  // ═════════════════════════════════════════════════════════
  Widget _permissionCard(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 12, _padH, 16),
      child: _softCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _N.pinkSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.shield_outlined,
                      color: _N.pink, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Нет доступа к датчику движения',
                    style: GoogleFonts.inter(
                      color: _N.text,
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
                        color: _N.pinkSoft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'НАСТРОЙКИ',
                        style: GoogleFonts.inter(
                          color: _N.pink,
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
                        color: _N.goldSoft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'БАТАРЕЯ',
                        style: GoogleFonts.inter(
                          color: _N.gold,
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
                        color: _N.surfaceAlt,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ПОВТОРИТЬ',
                        style: GoogleFonts.inter(
                          color: _N.text,
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
              color: _N.gold.withOpacity(0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: _N.gold, size: 22),
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
                    color: _N.goldSoft,
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
      backgroundColor: _N.greenDeep,
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
              color: _N.gold.withOpacity(0.20),
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
                    color: _N.goldSoft,
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
      backgroundColor: _N.greenDeep,
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
                  colors: [_N.lavender, Color(0xFF8B7AC7)],
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
                      border:
                      Border.all(color: Colors.white.withOpacity(0.25)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Дневная цель',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _N.text,
            letterSpacing: -0.5,
          ),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(
              color: _N.text, fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            suffixText: 'шагов',
            suffixStyle:
            GoogleFonts.inter(color: _N.textMuted, fontSize: 13),
            filled: true,
            fillColor: _N.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _N.divider, width: 1),
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
                  color: _N.textMuted,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Калибровка',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _N.text,
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
                  color: _N.text, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Рост (см)',
                labelStyle:
                GoogleFonts.inter(color: _N.textMuted, fontSize: 12),
                filled: true,
                fillColor: _N.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _N.divider, width: 1),
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
                  color: _N.text, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Вес (кг)',
                labelStyle:
                GoogleFonts.inter(color: _N.textMuted, fontSize: 12),
                filled: true,
                fillColor: _N.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _N.divider, width: 1),
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
                  color: _N.textMuted,
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
//  MULTI-RING PAINTER — сохранён и адаптирован под Nature Premium
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
    _drawRing(canvas, center, 112, 11, stepProgress, stepColor, 0.10);
    _drawRing(canvas, center, 90, 11, distanceProgress, _N.sky, 0.12);
    _drawRing(canvas, center, 68, 11, calorieProgress, _N.orange, 0.14);
    _drawRing(canvas, center, 46, 11, activeProgress, _N.lavender, 0.16);
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
        ..strokeWidth = stroke * 1.7
        ..strokeCap = StrokeCap.round
        ..color = color.withOpacity(0.22)
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
        ..strokeWidth = stroke * 0.40
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.60),
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
//  PRESS — сохранён
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