// features/nutrition/ui/screens/fuel_dashboard_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/nutrition_models.dart';
import '../../models/wellness_models.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/wellness_provider.dart';
import '../widgets/product_knowledge_sheet.dart';
import '../widgets/season_visuals.dart';
import '../widgets/water_tap_card.dart';
import 'add_food_screen.dart';
import 'food_library_screen.dart';
import 'kitchen_hub_screen.dart';
import 'knowledge_screen.dart';
import 'profile_setup_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  Design tokens
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
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF9381BB);
  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF6C9E88);
  static const skySoft = Color(0xFFE8EFF8);
  static const skyDeep = Color(0xFF7E9DC6);
  static const yellowSoft = Color(0xFFFDF5E6);
  static const yellowDeep = Color(0xFFE0B054);
  static const pinkSoft = Color(0xFFFCF0F2);
  static const pinkDeep = Color(0xFFD17A8F);
}

class _Hero {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const accent = Color(0xFFEF9563);
  static const textHigh = Colors.white;
  static const textLow = Color(0xFFA4A6AA);
}

class _T {
  static final title2 = GoogleFonts.inter(
      fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: _P.text);
  static final headline = GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w600, color: _P.text);
  static final body = GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400, color: _P.textMuted);
  static final caption = GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
}

const double _padH = 14;

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class FuelDashboardScreen extends StatefulWidget {
  final bool isDark;
  const FuelDashboardScreen({super.key, this.isDark = true});
  @override
  State<FuelDashboardScreen> createState() => _FuelDashboardScreenState();
}

class _FuelDashboardScreenState extends State<FuelDashboardScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  bool _profileBannerDismissed = false;
  MealType? _expandedMeal;
  bool _didAutoExpand = false;
  bool _reduceMotion = false;
  bool _pulseStarted = false;

  // 🆕 раскрытие групп-блюд
  final Set<String> _expandedDishes = {};

  // Фон hero
  String _heroBgImage = 'assets/images/nature_hero3.jpg';
  static const _heroBackgrounds = [
    'assets/images/nature_hero.jpg',  'assets/images/nature_hero2.jpg',
    'assets/images/nature_hero3.jpg', 'assets/images/nature_hero4.jpg',
    'assets/images/nature_hero5.jpg', 'assets/images/nature_hero6.jpg',
    'assets/images/nature_hero7.jpg', 'assets/images/nature_hero8.jpg',
    'assets/images/nature_hero9.jpg', 'assets/images/nature_hero10.jpg',
    'assets/images/nature_hero11.jpg','assets/images/nature_hero12.jpg',
    'assets/images/nature_hero13.jpg','assets/images/nature_hero14.jpg',
    'assets/images/nature_hero15.jpg','assets/images/nature_hero16.jpg',
    'assets/images/nature_hero17.jpg','assets/images/nature_hero18.jpg',
    'assets/images/nature_hero19.jpg','assets/images/nature_hero20.jpg',
    'assets/images/nature_hero21.jpg',
  ];
  static const _heroBgLabels = {
    'assets/images/nature_hero.jpg':  'Тропа',
    'assets/images/nature_hero2.jpg': 'Закат 1',
    'assets/images/nature_hero3.jpg': 'Закат 2',
    'assets/images/nature_hero4.jpg': 'Закат 3',
    'assets/images/nature_hero5.jpg': 'Лес',
    'assets/images/nature_hero6.jpg': 'Горы',
    'assets/images/nature_hero7.jpg': 'Закат 4',
    'assets/images/nature_hero8.jpg': 'Рассвет',
    'assets/images/nature_hero9.jpg': 'Поле',
    'assets/images/nature_hero10.jpg':'Река',
    'assets/images/nature_hero11.jpg':'Озеро',
    'assets/images/nature_hero12.jpg':'Море',
    'assets/images/nature_hero13.jpg':'Пляж',
    'assets/images/nature_hero14.jpg':'Пустыня',
    'assets/images/nature_hero15.jpg':'Водопад',
    'assets/images/nature_hero16.jpg':'Каньон',
    'assets/images/nature_hero17.jpg':'Степь',
    'assets/images/nature_hero18.jpg':'Тайга',
    'assets/images/nature_hero19.jpg':'Луг',
    'assets/images/nature_hero20.jpg':'Дюны',
    'assets/images/nature_hero21.jpg':'Утёс',
  };

  // Фон карточки «Кухня»
  static const _kitchenBgPrefsKey = 'kitchen_hub_bg_index';
  static const _kitchenBackgrounds = [
    'assets/images/kitchen_hub.jpg',
    'assets/images/kitchen_hub2.jpg',
    'assets/images/kitchen_hub3.jpg',
  ];
  int _kitchenBgIndex = 0;

  static final Map<String, Set<String>> _dismissedRecs = {};

  final _scrollController = ScrollController();
  final _stickyVisible = ValueNotifier<bool>(false);

  late final AnimationController _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<double> _entranceCurve =
  CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
  late final AnimationController _pulse =
  AnimationController(vsync: this, duration: const Duration(seconds: 3));
  late final AnimationController _bars = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _entrance.forward();
    _bars.forward();
    _loadHeroBg();
    _loadKitchenBg();
  }

  Future<void> _loadHeroBg() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _heroBgImage =
          prefs.getString('fuel_hero_bg') ?? 'assets/images/nature_hero3.jpg';
    });
  }

  Future<void> _loadKitchenBg() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _kitchenBgIndex = prefs.getInt(_kitchenBgPrefsKey) ?? 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _reduceMotion = reduce;
    if (!reduce && !_pulseStarted) {
      _pulseStarted = true;
      _pulse.repeat(reverse: true);
    }
    if (!_didAutoExpand) {
      _didAutoExpand = true;
      _autoExpandCurrentMeal();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _stickyVisible.dispose();
    _entrance.dispose();
    _pulse.dispose();
    _bars.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    _stickyVisible.value = _scrollController.position.pixels > 140;
  }

  void _autoExpandCurrentMeal() {
    try {
      final p = context.read<NutritionProvider>();
      final entries = p.getEntriesForDate(_selectedDate);
      final suggested = MealType.suggestForNow();
      if (entries.any((e) => e.mealType == suggested)) {
        _expandedMeal = suggested;
      }
    } catch (_) {}
  }

  TextStyle _num({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double tracking = -0.4,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? _P.text,
        letterSpacing: tracking,
        height: 1.0,
        fontFeatures: [ui.FontFeature.tabularFigures()],
      );

  TextStyle get _overline => GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _P.textMuted);

  Widget _sectionLabel(String text, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_padH, 26, _padH, 10),
        child: Row(
          children: [
            Icon(icon, size: 13, color: _P.textMuted),
            const SizedBox(width: 6),
            Text(text,
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _P.text, letterSpacing: 1.0)),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 1, color: _P.divider)),
          ],
        ),
      ),
    );
  }

  ({int diff, bool positive}) _yesterdayDiff(
      NutritionProvider provider, DailyNutritionSummary today) {
    try {
      final y = DateTime.now().subtract(const Duration(days: 1));
      final ySum = provider.getSummaryForDate(y);
      final diff = today.calories.round() - ySum.calories.round();
      return (diff: diff.abs(), positive: diff >= 0);
    } catch (_) {
      return (diff: 0, positive: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final summary = provider.getSummaryForDate(_selectedDate);
    final goals = provider.getGoalsForDate(_selectedDate);
    final recs = provider.getRecommendations(_selectedDate);
    final hasProfile = provider.userProfile != null;
    final dayKey = _dayKey(_selectedDate);
    final dismissed = _dismissedRecs[dayKey] ?? const <String>{};
    final visibleRecs = recs.where((r) => !dismissed.contains(r.title)).toList();

    return Scaffold(
      backgroundColor: _P.bg,
      floatingActionButton: _buildFab(provider),
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                  child: _buildHero(summary, goals, hasProfile, provider)),
              if (!hasProfile && !_profileBannerDismissed)
                SliverToBoxAdapter(child: _buildProfileBanner()),
              _sectionLabel('СЕГОДНЯ', Icons.wb_sunny_outlined),
              SliverToBoxAdapter(child: _buildMacroCard(summary, goals)),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              // 🆕 КАРТОЧКА БАЗЫ ЗНАНИЙ (переход на FoodLibraryScreen)
              // SliverToBoxAdapter(child: _buildKnowledgeBaseCard(provider)), // 🆕 перенесено в KitchenHub → Рецепты
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              // Карточка кухни
              SliverToBoxAdapter(child: _buildKitchenHubCard(provider)),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              // 🆕 ЕДИНАЯ ТЁМНАЯ ПАНЕЛЬ ДНЕВНИКА
              SliverToBoxAdapter(
                  child: _buildDiaryPanel(provider, summary, goals, visibleRecs)),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              // Вода
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _padH),
                  child: WaterTapCard(
                    totalMl: provider.getWaterForDate(_selectedDate).round(),
                    goalMl: goals.waterMl,
                    onAdd: (ml) => provider.addWater(ml, date: _selectedDate),
                  ),
                ),
              ),
              // Здоровье и сезон
              SliverToBoxAdapter(child: _buildHealthSection(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildStickyOverlay(summary, goals),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(NutritionProvider provider) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _P.peachDeep.withOpacity(0.35),
            blurRadius: 20, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _openAddFood(context, provider);
        },
        backgroundColor: _P.peachDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HERO (без аватара, один заголовок, крупная настройка, тёмные кольца)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHero(DailyNutritionSummary s, NutritionGoals g, bool hasProfile,
      NutritionProvider provider) {
    final rawPct = g.calories > 0 ? s.calories / g.calories : 0.0;
    final pct = rawPct.clamp(0.0, 1.0);
    final isOver = s.calories > g.calories;
    final remaining = g.calories - s.calories;
    final accent =
    isOver ? _P.pinkDeep : (rawPct >= 0.9 ? _P.greenDeep : _Hero.accent);
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final noMeals = s.entriesCount == 0;
    final yDiff = _yesterdayDiff(provider, s);

    final content = ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _heroBgImage,
              key: ValueKey(_heroBgImage),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [_Hero.bgTop, _Hero.bgBottom],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.65),
                    _P.bg.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.3, 0.8, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0, height: 60,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [_P.bg.withOpacity(0.0), _P.bg],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 60, left: 60,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  final o = _reduceMotion ? 0.18 : (0.14 + 0.08 * _pulse.value);
                  return Container(
                    width: 320, height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [accent.withOpacity(o), accent.withOpacity(0)],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Ряд 1: заголовок + счётчик приёмов + календарь ──
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Питание',
                        style: GoogleFonts.inter(
                          color: _Hero.textHigh,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          shadows: [
                            Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)
                          ],
                        ),
                      ),
                    ),
                    if (s.entriesCount > 0) ...[
                      _glassPill(
                          icon: Icons.restaurant_menu_rounded,
                          label: '${s.entriesCount}'),
                      const SizedBox(width: 6),
                    ],
                    _iconPill(icon: Icons.calendar_today_rounded, onTap: _pickDate),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Ряд 2: дата слева + крупная кнопка настроек справа ──
                Row(
                  children: [
                    Text(
                      isToday ? 'Сегодня' : _formatDateShort(_selectedDate),
                      style: GoogleFonts.inter(
                        color: _Hero.textHigh.withOpacity(0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)
                        ],
                      ),
                    ),
                    const Spacer(),
                    _settingsButton(),
                  ],
                ),
                const SizedBox(height: 18),
                // ── Кольцо + баланс ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label:
                          '${s.calories.round()} из ${g.calories.round()} килокалорий, ${(rawPct * 100).round()} процентов',
                          child: _Press(
                            onLongPress: () => _showGoalsEditor(context),
                            child: RepaintBoundary(
                              child: SizedBox(
                                width: 140, height: 140,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _animBars(
                                          (t) => CustomPaint(
                                        size: const Size(140, 140),
                                        painter: _HeroGaugePainter(
                                          percent: pct * t,
                                          color: accent,
                                          glowColor: accent.withOpacity(0.55),
                                          background: Colors.white.withOpacity(0.15),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          noMeals ? '—' : '${(rawPct * 100).round()}%',
                                          style: GoogleFonts.inter(
                                            color: _Hero.textHigh,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -1.6,
                                            height: 1,
                                            fontFeatures: [ui.FontFeature.tabularFigures()],
                                            shadows: [
                                              Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 6)
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text('ЦЕЛИ',
                                            style: GoogleFonts.inter(
                                              color: _Hero.textLow,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.2,
                                              shadows: [
                                                Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)
                                              ],
                                            )),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _remainingChip(remaining, isOver, accent),
                        const SizedBox(height: 6),
                        _yesterdayChip(yDiff),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('ДНЕВНОЙ БАЛАНС',
                              style: GoogleFonts.inter(
                                color: _Hero.textLow,
                                fontSize: 10, fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)
                                ],
                              )),
                          const SizedBox(height: 6),
                          Text('${s.calories.round()}',
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                color: _Hero.textHigh,
                                fontSize: 42,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.8,
                                height: 1,
                                fontFeatures: [ui.FontFeature.tabularFigures()],
                                shadows: [
                                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)
                                ],
                              )),
                          const SizedBox(height: 3),
                          Text('/ ${g.calories.round()} ккал',
                              style: GoogleFonts.inter(
                                color: _Hero.textLow,
                                fontSize: 13, fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)
                                ],
                              )),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 130,
                            child: _animBars(
                                  (t) => ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: pct * t,
                                  minHeight: 2,
                                  backgroundColor: Colors.white.withOpacity(0.15),
                                  valueColor: AlwaysStoppedAnimation(accent),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // ── ТЁМНЫЙ контейнер колец Б/Ж/У/В ──
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.34),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      _ringlet('Б', s.protein, g.protein, _P.greenDeep),
                      _ringlet('Ж', s.fat, g.fat, _P.peachDeep),
                      _ringlet('У', s.carbs, g.carbs, _P.yellowDeep),
                      _ringlet('В', s.waterMl.toDouble(), g.waterMl.toDouble(), _P.skyDeep),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (_reduceMotion) return content;
    return AnimatedBuilder(
      animation: _entranceCurve,
      builder: (_, child) => Opacity(
        opacity: _entranceCurve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _entranceCurve.value) * 12),
          child: child,
        ),
      ),
      child: content,
    );
  }

  Widget _settingsButton() {
    return _Press(
      onTap: _openBackgroundPicker,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.16),
          border: Border.all(color: Colors.white.withOpacity(0.28)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _remainingChip(double remaining, bool isOver, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOver ? Icons.warning_amber_rounded : Icons.local_fire_department_rounded,
            color: accent, size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            isOver
                ? 'Превышено на ${remaining.abs().round()} ккал'
                : '${remaining.round()} ккал осталось',
            style: GoogleFonts.inter(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _yesterdayChip(({int diff, bool positive}) d) {
    if (d.diff == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('как вчера',
            style: GoogleFonts.inter(
                color: _Hero.textLow, fontSize: 9, fontWeight: FontWeight.w500)),
      );
    }
    final color = d.positive ? _P.greenDeep : _P.skyDeep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            d.positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 9, color: color,
          ),
          const SizedBox(width: 3),
          Text('${d.diff} ккал vs вчера',
              style: GoogleFonts.inter(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600,
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }

  Widget _ringlet(String label, double cur, double goal, Color color) {
    final pct = goal > 0 ? (cur / goal).clamp(0.0, 1.0) : 0.0;
    final pctLabel = goal > 0 ? '${(cur / goal * 100).round()}%' : '—';
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            width: 20, height: 20,
            child: _animBars(
                  (t) => CustomPaint(
                painter: _RingletPainter(
                  percent: pct * t,
                  color: color,
                  background: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(cur.round().toString(),
              style: GoogleFonts.inter(
                color: _Hero.textHigh, fontSize: 12, fontWeight: FontWeight.w600, height: 1,
                fontFeatures: [ui.FontFeature.tabularFigures()],
                shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
              )),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                    color: _Hero.textLow, fontSize: 9, fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
                  )),
              const SizedBox(width: 3),
              Text(pctLabel,
                  style: GoogleFonts.inter(
                    color: _Hero.textLow.withOpacity(0.8), fontSize: 8, fontWeight: FontWeight.w500,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }

  Widget _iconPill({required IconData icon, required VoidCallback onTap}) {
    return _Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.20)),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MACRO CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMacroCard(DailyNutritionSummary s, NutritionGoals g) {
    final cols = [
      _MacroCol('Белки', s.protein, g.protein, _P.greenDeep),
      _MacroCol('Жиры', s.fat, g.fat, _P.peachDeep),
      _MacroCol('Углеводы', s.carbs, g.carbs, _P.yellowDeep),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: _Press(
        onTap: () => _showGoalsEditor(context),
        child: Container(
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _P.divider),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Text('МАКРОСЫ', style: _overline),
                    const Spacer(),
                    Icon(Icons.tune_rounded, size: 13, color: _P.peachDeep),
                    const SizedBox(width: 4),
                    Text('изменить',
                        style: GoogleFonts.inter(
                            color: _P.peachDeep, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IntrinsicHeight(
                child: Row(
                  children: [
                    for (var i = 0; i < cols.length; i++) ...[
                      Expanded(child: _macroColumn(cols[i])),
                      if (i < cols.length - 1) Container(width: 1, color: _P.divider),
                    ]
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: _animBars(
                      (t) => Row(
                    children: cols.map((c) {
                      final p = (c.pct * t).clamp(0.0, 1.0);
                      return Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: p,
                            minHeight: 3,
                            backgroundColor: _P.elevated,
                            valueColor: AlwaysStoppedAnimation(c.color),
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
    );
  }

  Widget _macroColumn(_MacroCol c) {
    final over = c.cur > c.goal;
    final remaining = (c.goal - c.cur).clamp(0.0, 9999.0);
    final pct = c.pct;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.label,
                  style: GoogleFonts.inter(
                      color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Text('${(pct * 100).round()}%',
                  style: GoogleFonts.inter(
                    color: over ? _P.pinkDeep : c.color,
                    fontSize: 10, fontWeight: FontWeight.w600,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.cur.round().toString(),
              style: _num(size: 24, color: over ? _P.pinkDeep : _P.text, tracking: -1.0)),
          const SizedBox(height: 3),
          Text(
            over
                ? 'на ${(c.cur - c.goal).round()} г сверх'
                : '${remaining.round()} г до цели',
            style: GoogleFonts.inter(
              color: over ? _P.pinkDeep : _P.textMuted,
              fontSize: 10, fontWeight: FontWeight.w500,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  🆕 КАРТОЧКА БАЗЫ ЗНАНИЙ (переход на FoodLibraryScreen)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildKnowledgeBaseCard(NutritionProvider provider) {
    final productsCount = provider.products.length;
    final recipesCount = provider.templates.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: _Press(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: provider,
                child: const FoodLibraryScreen(),
              ),
            ),
          );
        },
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A2A5C), Color(0xFF1E3A31)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _P.lavenderDeep.withOpacity(0.25),
                blurRadius: 24, spreadRadius: -8, offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Декоративные круги
              Positioned(
                top: -20, right: -20,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _P.peachDeep.withOpacity(0.25),
                        _P.peachDeep.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -15, left: 30,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _P.greenDeep.withOpacity(0.20),
                        _P.greenDeep.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              // Контент
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('БАЗА ЗНАНИЙ',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4,
                                  )),
                              const SizedBox(height: 2),
                              Text('Продукты и блюда',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3,
                                  )),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.7), size: 20),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_rounded, size: 12, color: Colors.white), SizedBox(width: 4),
                              Text('$productsCount',
                                  style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                                  )),
                              const SizedBox(width: 2),
                              Text('продуктов',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.7), fontSize: 10,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🍱', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text('$recipesCount',
                                  style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                                  )),
                              const SizedBox(width: 2),
                              Text('блюд',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.7), fontSize: 10,
                                  )),
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

  // ═══════════════════════════════════════════════════════════════
  //  KITCHEN HUB CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildKitchenHubCard(NutritionProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: provider,
                child: const KitchenHubScreen(),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 182,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft, end: Alignment.centerRight,
                colors: [Color(0xFF2A3A32), Color(0xFF4A6B58)],
              ),
              borderRadius: BorderRadius.circular(24),
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [...previousChildren, if (currentChild != null) currentChild],
                  ),
                  child: SizedBox.expand(
                    child: Image.asset(
                      _kitchenBackgrounds[_kitchenBgIndex],
                      key: ValueKey(_kitchenBgIndex),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.72),
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.05),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
                            ),
                            child: const Icon(Icons.kitchen_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('КУХНЯ',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white, fontSize: 12,
                                  fontWeight: FontWeight.w700, letterSpacing: 2.0,
                                )),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _cycleKitchenBg,
                            child: Container(
                              padding: const EdgeInsets.all(8),
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
                      const Spacer(),
                      Text('Кладовая, рецепты и план питания',
                          style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 20, height: 1.2,
                            fontWeight: FontWeight.w800, letterSpacing: -0.4,
                          )),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Открыть',
                                style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                          ],
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

  Future<void> _cycleKitchenBg() async {
    HapticFeedback.selectionClick();
    final next = (_kitchenBgIndex + 1) % _kitchenBackgrounds.length;
    setState(() => _kitchenBgIndex = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kitchenBgPrefsKey, next);
  }

  // ═══════════════════════════════════════════════════════════════
  //  🆕 ЕДИНАЯ ТЁМНАЯ ПАНЕЛЬ ДНЕВНИКА
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDiaryPanel(
      NutritionProvider provider,
      DailyNutritionSummary summary,
      NutritionGoals goals,
      List<NutritionRecommendation> recs,
      ) {
    final entries = provider.getEntriesForDate(_selectedDate);
    final meals = _groupEntriesByMeal(entries);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1D3A31), Color(0xFF14242C), Color(0xFF27203A)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60, right: -40,
            child: IgnorePointer(
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_P.peachDeep.withOpacity(0.16), _P.peachDeep.withOpacity(0)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80, left: -50,
            child: IgnorePointer(
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_P.greenDeep.withOpacity(0.14), _P.greenDeep.withOpacity(0)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _panelHeader('БЫСТРЫЙ ВВОД', Icons.bolt_rounded),
                const SizedBox(height: 10),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: provider.getRecentProducts(limit: 8).length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      if (i == 0) return _createChipDark(provider);
                      final p = provider.getRecentProducts(limit: 8)[i - 1];
                      return _recentChipDark(provider, p);
                    },
                  ),
                ),
                const SizedBox(height: 22),
                _panelHeader('ПРИЁМЫ ПИЩИ', Icons.restaurant_rounded,
                    trailing: '${summary.entriesCount}'),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Positioned(
                      left: 11, top: 28, bottom: 28,
                      child: Container(width: 2, color: Colors.white.withOpacity(0.10)),
                    ),
                    Column(
                      children: MealType.values.map((meal) {
                        final mealEntries = meals[meal] ?? const <FoodDiaryEntry>[];
                        return _mealRowDark(
                          provider: provider,
                          meal: meal,
                          entries: mealEntries,
                          isCurrent: meal == _currentMeal(),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _mealsFooterDark(meals, summary, goals),
                if (recs.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _panelHeader('СОВЕТЫ', Icons.auto_awesome_rounded),
                  const SizedBox(height: 10),
                  ...recs.map((r) => _recCardDark(r, _dayKey(_selectedDate))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelHeader(String text, IconData icon, {String? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white.withOpacity(0.5)),
        const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2,
            )),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(trailing,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11, fontWeight: FontWeight.w600,
                  fontFeatures: [ui.FontFeature.tabularFigures()],
                )),
          ),
        ],
      ],
    );
  }

  Widget _createChipDark(NutritionProvider provider) {
    return _Press(
      onTap: () => _openAddFood(context, provider),
      child: Container(
        width: 96, height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: _P.peachSoft),
            const SizedBox(width: 4),
            Text('Создать',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  Widget _recentChipDark(NutritionProvider provider, FoodProduct p) {
    return _Press(
      onTap: () => _openAddFood(context, provider, preselected: p),
      onLongPress: () => _showProductSheet(p, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(p.categoryEmoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      )),
                ),
                const SizedBox(height: 3),
                Text('${p.calories.round()} ккал',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.55), fontSize: 10, fontWeight: FontWeight.w500,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Приём пищи (тёмный, с группировкой блюд) ──
  Widget _mealRowDark({
    required NutritionProvider provider,
    required MealType meal,
    required List<FoodDiaryEntry> entries,
    required bool isCurrent,
  }) {
    final accent = _mealAccent(meal);
    final isEmpty = entries.isEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 17),
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? accent.withOpacity(0.22) : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: !isEmpty ? 10 : 8,
                  height: !isEmpty ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !isEmpty ? accent : accent.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: isEmpty
                ? _ghostMealRowDark(provider, meal, accent)
                : _mealContentDark(provider, meal, entries, accent, isCurrent: isCurrent),
          ),
        ),
      ],
    );
  }

  Widget _ghostMealRowDark(NutritionProvider provider, MealType meal, Color accent) {
    return _Press(
      onTap: () => _openAddFood(context, provider, meal: meal),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.4)),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(color: accent.withOpacity(0.5), radius: 14),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.add_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Text('Добавить ${meal.displayName.toLowerCase()}',
                  style: GoogleFonts.inter(
                      color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mealContentDark(NutritionProvider provider, MealType meal,
      List<FoodDiaryEntry> entries, Color accent, {bool isCurrent = false}) {
    final expanded = _expandedMeal == meal;
    final kcal = entries.fold<double>(0, (s, e) => s + e.calories);
    final protein = entries.fold<double>(0, (s, e) => s + e.protein);
    final fat = entries.fold<double>(0, (s, e) => s + e.fat);
    final carbs = entries.fold<double>(0, (s, e) => s + e.carbs);

    // Группировка: блюда по templateId, остальное по одному
    final tplGroups = <String, List<FoodDiaryEntry>>{};
    for (final e in entries) {
      final tid = e.templateId;
      if (tid != null && tid.isNotEmpty) {
        tplGroups.putIfAbsent(tid, () => []).add(e);
      }
    }
    final rows = <Object>[];
    final seen = <String>{};
    for (final e in entries) {
      final tid = e.templateId;
      if (tid != null && tid.isNotEmpty) {
        if (!seen.contains(tid)) { seen.add(tid); rows.add(tid); }
      } else {
        rows.add(e);
      }
    }

    return Column(
      children: [
        _Press(
          onTap: () => setState(() => _expandedMeal = expanded ? null : meal),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  alignment: Alignment.center,
                  child: Text(_mealEmoji(meal), style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(meal.displayName,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                )),
                          ),
                          const SizedBox(width: 6),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('сейчас',
                                  style: GoogleFonts.inter(
                                    color: accent, fontSize: 8, fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  )),
                            )
                          else if (entries.isNotEmpty)
                            Icon(Icons.check_circle_rounded,
                                size: 13, color: _P.greenSoft.withOpacity(0.8)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${entries.length} ${_foodWord(entries.length)}',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.55), fontSize: 11,
                          )),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${kcal.round()} ккал',
                        style: GoogleFonts.inter(
                          color: accent, fontSize: 13, fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        )),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _miniMacroDark('Б', protein, _P.greenSoft),
                        const SizedBox(width: 5),
                        _miniMacroDark('Ж', fat, _P.peachSoft),
                        const SizedBox(width: 5),
                        _miniMacroDark('У', carbs, _P.yellowSoft),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: _dur(200),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: _dur(200),
          alignment: Alignment.topCenter,
          curve: Curves.easeOutCubic,
          child: expanded
              ? Column(
            children: [
              const SizedBox(height: 2),
              ...rows.map((row) {
                if (row is String) {
                  return _dishGroupDark(provider, meal, row, tplGroups[row]!);
                }
                return _entryRowDark(provider, row as FoodDiaryEntry);
              }),
              const SizedBox(height: 6),
              _addMealButtonDark(provider, meal, accent),
              const SizedBox(height: 8),
            ],
          )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _miniMacroDark(String l, double v, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 5, height: 5,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text('$l${v.round()}',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w600,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            )),
      ],
    );
  }

  // ── 🍱 БЛЮДО: одна строка + раскрытие ингредиентов ──
  Widget _dishGroupDark(NutritionProvider provider, MealType meal,
      String tplId, List<FoodDiaryEntry> items) {
    final key = '${meal.name}_$tplId';
    final expanded = _expandedDishes.contains(key);
    final kcal = items.fold<double>(0, (s, e) => s + e.calories);
    final protein = items.fold<double>(0, (s, e) => s + e.protein);
    final fat = items.fold<double>(0, (s, e) => s + e.fat);
    final carbs = items.fold<double>(0, (s, e) => s + e.carbs);
    final name = items.first.templateName ?? 'Блюдо';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 52, bottom: 4),
          child: _Press(
            onTap: () => setState(() {
              if (expanded) { _expandedDishes.remove(key); }
              else { _expandedDishes.add(key); }
            }),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🍱', style: TextStyle(fontSize: 17)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 2),
                        Text('${items.length} инг. · Б${protein.round()} Ж${fat.round()} У${carbs.round()}',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.55), fontSize: 10,
                              fontFeatures: [ui.FontFeature.tabularFigures()],
                            )),
                      ],
                    ),
                  ),
                  Text('${kcal.round()}',
                      style: GoogleFonts.inter(
                        color: _P.peachSoft, fontSize: 14, fontWeight: FontWeight.w700,
                        fontFeatures: [ui.FontFeature.tabularFigures()],
                      )),
                  const SizedBox(width: 2),
                  Text('ккал',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5), fontSize: 9,
                      )),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: _dur(200),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 16, color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: _dur(200),
          alignment: Alignment.topCenter,
          curve: Curves.easeOutCubic,
          child: expanded
              ? Column(
            children: [
              ...items.map((e) => _entryRowDark(provider, e, indent: 64)),
              Padding(
                padding: const EdgeInsets.only(left: 64, bottom: 4),
                child: _Press(
                  onTap: () => _removeDishGroup(provider, items),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: _P.pinkDeep.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _P.pinkDeep.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 14, color: _P.pinkSoft),
                        const SizedBox(width: 6),
                        Text('Убрать блюдо',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 11, fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Future<void> _removeDishGroup(
      NutritionProvider provider, List<FoodDiaryEntry> items) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Убрать блюдо?', style: _T.headline),
        content: Text('${items.first.templateName ?? 'Блюдо'} — '
            '${items.length} записей будут удалены',
            style: _T.caption),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Отмена', style: _T.body)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _P.pinkDeep),
            child: const Text('Убрать', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    HapticFeedback.mediumImpact();
    for (final e in items) {
      await provider.removeEntry(e.id);
    }
  }

  // ── Одиночная запись (тёмная) ──
  Widget _entryRowDark(NutritionProvider provider, FoodDiaryEntry entry,
      {double indent = 52}) {
    final product = _findProduct(provider, entry.productId);
    return Dismissible(
      key: ValueKey('dark_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 4, left: indent),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: _P.pinkDeep.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: _P.pinkSoft, size: 18),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Удалить запись?', style: _T.headline),
            content: Text(entry.productName, style: _T.caption),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Отмена', style: _T.body)),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: _P.pinkDeep),
                child: const Text('Удалить',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        provider.removeEntry(entry.id);
      },
      child: Container(
        margin: EdgeInsets.only(left: indent, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(product?.categoryEmoji ?? '🍽️', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(entry.productName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: -0.1,
                  )),
            ),
            const SizedBox(width: 6),
            Text('${entry.grams.round()} г',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.55), fontSize: 11, fontWeight: FontWeight.w500,
                )),
            const SizedBox(width: 8),
            Text('${entry.calories.round()}',
                style: GoogleFonts.inter(
                  color: _P.peachSoft, fontSize: 13, fontWeight: FontWeight.w600,
                  fontFeatures: [ui.FontFeature.tabularFigures()],
                )),
            const SizedBox(width: 2),
            Text('ккал',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.5), fontSize: 10,
                )),
          ],
        ),
      ),
    );
  }

  Widget _addMealButtonDark(NutritionProvider provider, MealType meal, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: _Press(
        onTap: () => _openAddFood(context, provider, meal: meal),
        child: Container(
          width: double.infinity, height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, color: accent, size: 16),
              const SizedBox(width: 6),
              Text('ДОБАВИТЬ ЕЩЁ',
                  style: GoogleFonts.inter(
                    color: accent, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mealsFooterDark(
      Map<MealType, List<FoodDiaryEntry>> meals,
      DailyNutritionSummary summary,
      NutritionGoals goals,
      ) {
    final missing = <String>[];
    for (final m in MealType.values) {
      if ((meals[m] ?? const []).isEmpty && m != MealType.other) {
        missing.add(m.displayName.toLowerCase());
      }
    }
    final filledCount =
        MealType.values.where((m) => (meals[m] ?? const []).isNotEmpty).length;
    final totalMeals = MealType.values.length;
    final over = summary.calories > goals.calories;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                over ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                size: 13, color: over ? _P.pinkSoft : _P.greenSoft,
              ),
              const SizedBox(width: 6),
              Text('Заполнено $filledCount из $totalMeals',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11, fontWeight: FontWeight.w600,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  )),
              const Spacer(),
              Text('${summary.calories.round()} / ${goals.calories.round()} ккал',
                  style: GoogleFonts.inter(
                    color: over ? _P.pinkSoft : Colors.white.withOpacity(0.6),
                    fontSize: 11, fontWeight: FontWeight.w600,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  )),
            ],
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Не заполнено: ${missing.join(', ')}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.45), fontSize: 10, fontWeight: FontWeight.w500,
                )),
          ],
        ],
      ),
    );
  }

  Widget _recCardDark(NutritionRecommendation r, String dayKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: r.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: r.color.withOpacity(0.18), shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(r.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: r.color, fontSize: 12.5, fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 3),
                Text(r.message, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.65), fontSize: 11, height: 1.3,
                    )),
              ],
            ),
          ),
          _Press(
            onTap: () {
              setState(() {
                (_dismissedRecs[dayKey] ??= <String>{}).add(r.title);
              });
            },
            child: SizedBox(
              width: 36, height: 36,
              child: Icon(Icons.close_rounded, size: 15, color: Colors.white.withOpacity(0.45)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEALTH SECTION
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHealthSection(BuildContext context) {
    final wellness = context.watch<WellnessProvider>();
    final seasonCount = wellness.seasonalNow.length;
    final dailyProduct = wellness.productOfDay;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 26, _padH, 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28), topRight: Radius.circular(28),
          bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_Hero.bgTop, _Hero.bgBottom],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40, right: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [_P.greenDeep.withOpacity(0.22), _P.greenDeep.withOpacity(0.0)],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.10)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.eco_rounded, color: _P.greenSoft, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ЗДОРОВЬЕ И СЕЗОН',
                                  style: GoogleFonts.inter(
                                    color: _P.greenSoft, fontSize: 10,
                                    fontWeight: FontWeight.w700, letterSpacing: 1.4,
                                  )),
                              const SizedBox(height: 2),
                              Text(
                                seasonCount > 0
                                    ? '$seasonCount продуктов в сезоне'
                                    : 'Сезонные продукты',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: _Hero.textHigh, fontSize: 15,
                                  fontWeight: FontWeight.w600, letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Press(
                          onTap: () => _openKnowledge(context, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.white.withOpacity(0.10)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Знания',
                                    style: GoogleFonts.inter(
                                      color: _Hero.textHigh, fontSize: 11, fontWeight: FontWeight.w600,
                                    )),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (dailyProduct != null) ...[
                      _Press(
                        onTap: () {
                          final k = dailyProduct;
                          final product = _findProductByName(context, k.displayName);
                          showProductKnowledgeSheet(
                            context,
                            product: product,
                            knowledge: k,
                            nutrition: context.read<NutritionProvider>(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: _P.greenDeep.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _P.greenDeep.withOpacity(0.30)),
                                ),
                                alignment: Alignment.center,
                                child: Text(dailyProduct.emoji, style: const TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _P.greenDeep.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('✨', style: TextStyle(fontSize: 9)),
                                              const SizedBox(width: 3),
                                              Text('ПРОДУКТ ДНЯ',
                                                  style: GoogleFonts.inter(
                                                    color: _P.greenSoft, fontSize: 9,
                                                    fontWeight: FontWeight.w700, letterSpacing: 0.8,
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(dailyProduct.displayName,
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: _Hero.textHigh, fontSize: 16,
                                          fontWeight: FontWeight.w600, letterSpacing: -0.3,
                                        )),
                                    if (dailyProduct.benefits.isNotEmpty)
                                      Text(
                                        dailyProduct.benefits.take(2).map((b) => _benefitRu(b)).join(' · '),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: _Hero.textLow, fontSize: 11, fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.eco_rounded, color: _P.greenSoft, size: 13),
                        const SizedBox(width: 6),
                        Text('СЕЗОН СЕЙЧАС',
                            style: GoogleFonts.inter(
                              color: _P.greenSoft, fontSize: 10,
                              fontWeight: FontWeight.w700, letterSpacing: 1.2,
                            )),
                        const SizedBox(width: 6),
                        SeasonPill(month: wellness.currentMonth, dark: true),
                        const Spacer(),
                        _Press(
                          onTap: () => _openKnowledge(context, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Все',
                                  style: GoogleFonts.inter(
                                    color: _Hero.textLow, fontSize: 11, fontWeight: FontWeight.w500,
                                  )),
                              const Icon(Icons.chevron_right_rounded, color: _Hero.textLow, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _darkSeasonalStrip(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _benefitRu(HealthBenefit b) {
    switch (b) {
      case HealthBenefit.immunity:   return 'иммунитет';
      case HealthBenefit.skin:       return 'кожа';
      case HealthBenefit.heart:      return 'сердце';
      case HealthBenefit.digestion:  return 'пищеварение';
      case HealthBenefit.energy:     return 'энергия';
      case HealthBenefit.bones:      return 'кости';
      case HealthBenefit.brain:      return 'мозг';
      case HealthBenefit.eyes:       return 'зрение';
      case HealthBenefit.sleep:      return 'сон';
      case HealthBenefit.weight:     return 'вес';
    }
  }

  FoodProduct? _findProductByName(BuildContext context, String name) {
    final provider = context.read<NutritionProvider>();
    try {
      return provider.products.firstWhere((p) =>
      p.name.toLowerCase() == name.toLowerCase() ||
          p.name.toLowerCase().contains(name.toLowerCase()));
    } catch (_) {
      return null;
    }
  }

  Widget _darkSeasonalStrip(BuildContext context) {
    final wellness = context.watch<WellnessProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final ending = wellness.endingThisMonth.take(6).toList();
    final starting = wellness.startingNextMonth.take(6).toList();
    final seasonal = wellness.seasonalNow.take(8).toList();
    final month = wellness.currentMonth;

    if (seasonal.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('В этом месяце нет сезонных продуктов',
            style: GoogleFonts.inter(
              color: _Hero.textLow, fontSize: 11, fontStyle: FontStyle.italic,
            )),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SeasonMonthsBar(
          months: metaForMonth(month).months,
          currentMonth: month,
          accent: metaForMonth(month).accent,
          trackColor: Colors.white.withOpacity(0.08),
          height: 4,
          showLabels: true,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: seasonal.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final k = seasonal[i];
              FoodProduct? product;
              try {
                product = nutrition.products.firstWhere((p) =>
                p.id == k.key ||
                    p.name.toLowerCase().contains(k.displayName.toLowerCase()));
              } catch (_) {}
              final nextMonth = month == 12 ? 1 : month + 1;
              final isEnding = !k.seasonMonths.contains(nextMonth);
              return _Press(
                onTap: () {
                  showProductKnowledgeSheet(
                    context, product: product, knowledge: k, nutrition: nutrition,
                  );
                },
                child: Container(
                  width: 112,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isEnding
                          ? _P.peachDeep.withOpacity(0.35)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: _P.greenDeep.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(k.emoji, style: const TextStyle(fontSize: 16)),
                          ),
                          const Spacer(),
                          if (isEnding)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: _P.peachDeep.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('уходит',
                                  style: GoogleFonts.inter(
                                    color: _P.peachSoft, fontSize: 7,
                                    fontWeight: FontWeight.w800, letterSpacing: 0.4,
                                  )),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(k.displayName, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _Hero.textHigh, fontSize: 11, fontWeight: FontWeight.w600,
                            height: 1.2, letterSpacing: -0.1,
                          )),
                      const SizedBox(height: 5),
                      SeasonMonthsBar(
                        months: k.seasonMonths,
                        currentMonth: month,
                        accent: _P.greenDeep,
                        trackColor: Colors.white.withOpacity(0.10),
                        height: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (ending.isNotEmpty || starting.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              if (ending.isNotEmpty)
                _seasonNote(
                  icon: Icons.schedule_rounded, color: _P.peachDeep,
                  label: '${ending.length} уходит: ${ending.first.displayName}',
                ),
              if (starting.isNotEmpty)
                _seasonNote(
                  icon: Icons.upcoming_rounded, color: _P.greenDeep,
                  label: '${starting.length} скоро: ${starting.first.displayName}',
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _seasonNote({required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STICKY CONTEXT BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStickyOverlay(DailyNutritionSummary s, NutritionGoals g) {
    return ValueListenableBuilder<bool>(
      valueListenable: _stickyVisible,
      builder: (_, visible, __) {
        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, -1),
            duration: _dur(200),
            curve: Curves.easeOutCubic,
            child: RepaintBoundary(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _P.bg.withOpacity(0.72),
                      border: const Border(bottom: BorderSide(color: _P.divider, width: 1)),
                    ),
                    child: SafeArea(
                      top: true, bottom: false,
                      child: SizedBox(
                        height: 56,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _Press(
                                onTap: _pickDate,
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: _P.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _P.divider),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 12, color: _P.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isSameDay(_selectedDate, DateTime.now())
                                          ? 'Сегодня'
                                          : _formatDateShort(_selectedDate),
                                      style: GoogleFonts.inter(
                                        color: _P.text, fontSize: 12, fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${s.calories.round()}',
                                          style: GoogleFonts.inter(
                                            color: _P.text, fontSize: 14, fontWeight: FontWeight.w700,
                                            fontFeatures: [ui.FontFeature.tabularFigures()],
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' / ${g.calories.round()}',
                                          style: GoogleFonts.inter(
                                            color: _P.textMuted, fontSize: 12, fontWeight: FontWeight.w500,
                                            fontFeatures: [ui.FontFeature.tabularFigures()],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _stickyMacro(_P.greenDeep, s.protein),
                                  const SizedBox(width: 6),
                                  _stickyMacro(_P.peachDeep, s.fat),
                                  const SizedBox(width: 6),
                                  _stickyMacro(_P.yellowDeep, s.carbs),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stickyMacro(Color color, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text('${value.round()}',
            style: GoogleFonts.inter(
              color: _P.text, fontSize: 10, fontWeight: FontWeight.w600,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            )),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PROFILE BANNER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProfileBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 16, _padH, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: _P.peachSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _P.peachDeep.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, color: _P.peachDeep, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Настрой профиль, чтобы видеть точные цели',
                  style: GoogleFonts.inter(
                    color: _P.text, fontSize: 12, fontWeight: FontWeight.w500,
                  )),
            ),
            _Press(
              onTap: () => _openProfileSetup(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _P.peachDeep,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Настроить',
                    style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
                    )),
              ),
            ),
            _Press(
              onTap: () => setState(() => _profileBannerDismissed = true),
              child: const SizedBox(
                width: 36, height: 36,
                child: Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BACKGROUND PICKER
  // ═══════════════════════════════════════════════════════════════
  Future<void> _openBackgroundPicker() async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: _P.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 38, height: 5,
                    decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: _P.peachSoft, borderRadius: BorderRadius.circular(11)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.wallpaper_rounded, color: _P.peachDeep, size: 19)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Фон экрана питания',
                          style: GoogleFonts.inter(
                              color: _P.text, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                      const SizedBox(height: 2),
                      Text('${_heroBackgrounds.length} вариантов на выбор',
                          style: GoogleFonts.inter(color: _P.textMuted, fontSize: 12)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 18),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: GridView.count(
                      crossAxisCount: 3, shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10, crossAxisSpacing: 10,
                      childAspectRatio: 0.82,
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
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? _P.peachDeep : Colors.white,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(
                                  color: _P.peachDeep.withOpacity(0.25),
                                  blurRadius: 12, spreadRadius: -2,
                                  offset: const Offset(0, 4))]
                                  : null,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(path, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                                        colors: [_Hero.bgTop, _Hero.bgBottom],
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.image_not_supported_rounded,
                                        color: Colors.white.withOpacity(0.5), size: 22),
                                  ),
                                ),
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
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
                                  left: 8, right: 8, bottom: 8,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                                color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700,
                                                shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)])),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 18, height: 18,
                                          decoration: const BoxDecoration(
                                            color: Colors.white, shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.check_rounded, color: _P.peachDeep, size: 12),
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
      await prefs.setString('fuel_hero_bg', result);
      if (mounted) setState(() => _heroBgImage = result);
      HapticFeedback.lightImpact();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  NAVIGATION & MODALS
  // ═══════════════════════════════════════════════════════════════
  void _openKnowledge(BuildContext ctx, int tab) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: context.read<WellnessProvider>()),
            ChangeNotifierProvider.value(value: context.read<NutritionProvider>()),
          ],
          child: KnowledgeScreen(initialTab: tab),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _P.peachDeep, surface: Colors.white, onSurface: _P.text,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _expandedMeal = null;
      _expandedDishes.clear();
      _didAutoExpand = false;
    });
    _bars.reset();
    if (!_reduceMotion) _bars.forward();
    _autoExpandCurrentMeal();
    _didAutoExpand = true;
  }

  void _openAddFood(BuildContext ctx, NutritionProvider provider,
      {MealType? meal, FoodProduct? preselected}) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => AddFoodScreen(
          isDark: false,
          date: _selectedDate,
          nutritionProvider: provider,
          initialMeal: meal,
          preselectedProduct: preselected,
        ),
      ),
    );
  }

  void _openProfileSetup(BuildContext ctx) {
    final p = context.read<NutritionProvider>();
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(isDark: false, provider: p),
      ),
    );
  }

  void _showProductSheet(FoodProduct p, NutritionProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _grabber()),
              const SizedBox(height: 16),
              Row(children: [
                Container(width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: _P.peachSoft, borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.center,
                    child: Text(p.categoryEmoji, style: const TextStyle(fontSize: 22))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _T.title2),
                      const SizedBox(height: 3),
                      Text('${p.calories.round()} ккал / 100 г', style: _T.caption),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              if (context.read<WellnessProvider>().knowledgeFor(p) != null) ...[
                _Press(
                  onTap: () {
                    final k = context.read<WellnessProvider>().knowledgeFor(p);
                    if (k == null) return;
                    showProductKnowledgeSheet(context, product: p, knowledge: k, nutrition: provider);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _P.greenDeep.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _P.greenDeep.withOpacity(0.22)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 32, height: 32,
                            decoration: BoxDecoration(
                                color: Colors.white, borderRadius: BorderRadius.circular(9)),
                            alignment: Alignment.center,
                            child: const Icon(Icons.eco_rounded, color: _P.greenDeep, size: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Богат, полезен, осторожно',
                                  style: GoogleFonts.inter(
                                      color: _P.greenDeep, fontSize: 12, fontWeight: FontWeight.w600,
                                      letterSpacing: -0.1)),
                              const SizedBox(height: 2),
                              Text('Витамины · польза · противопоказания',
                                  style: GoogleFonts.inter(color: _P.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _P.greenDeep, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openAddFood(context, provider, preselected: p);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _P.peachDeep,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('ДОБАВИТЬ В ДНЕВНИК',
                      style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalsEditor(BuildContext ctx) {
    final provider = context.read<NutritionProvider>();
    final goals = provider.getGoalsForDate(_selectedDate);
    final ctrl = {
      'cal': TextEditingController(text: goals.calories.toStringAsFixed(0)),
      'pro': TextEditingController(text: goals.protein.toStringAsFixed(0)),
      'fat': TextEditingController(text: goals.fat.toStringAsFixed(0)),
      'carb': TextEditingController(text: goals.carbs.toStringAsFixed(0)),
      'water': TextEditingController(text: goals.waterMl.toString()),
    };
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _grabber()),
                  const SizedBox(height: 20),
                  Text('ЦЕЛИ НА ДЕНЬ',
                      style: _overline.copyWith(color: _P.peachDeep)),
                  const SizedBox(height: 4),
                  Text('Настроить нормы', style: _T.title2),
                  const SizedBox(height: 20),
                  _goalField('Калории (ккал)', ctrl['cal']!),
                  const SizedBox(height: 10),
                  _goalField('Белки (г)', ctrl['pro']!),
                  const SizedBox(height: 10),
                  _goalField('Жиры (г)', ctrl['fat']!),
                  const SizedBox(height: 10),
                  _goalField('Углеводы (г)', ctrl['carb']!),
                  const SizedBox(height: 10),
                  _goalField('Вода (мл)', ctrl['water']!),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final updated = NutritionGoals(
                          id: goals.id,
                          date: goals.date,
                          calories: double.tryParse(ctrl['cal']!.text) ?? goals.calories,
                          protein: double.tryParse(ctrl['pro']!.text) ?? goals.protein,
                          fat: double.tryParse(ctrl['fat']!.text) ?? goals.fat,
                          carbs: double.tryParse(ctrl['carb']!.text) ?? goals.carbs,
                          waterMl: int.tryParse(ctrl['water']!.text) ?? goals.waterMl,
                        );
                        Navigator.pop(sheetCtx);
                        await provider.updateGoals(updated);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Цели обновлены'),
                          backgroundColor: _P.greenDeep,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _P.peachDeep,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('СОХРАНИТЬ',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 1.0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _goalField(String label, TextEditingController c) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.inter(color: _P.text, fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: _P.textMuted, fontSize: 12),
        filled: true,
        fillColor: _P.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _P.peachDeep.withOpacity(0.4), width: 1.2),
        ),
      ),
    );
  }

  Widget _grabber() => Container(
    width: 36, height: 5,
    decoration: BoxDecoration(
      color: _P.divider, borderRadius: BorderRadius.circular(3),
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════
  Map<MealType, List<FoodDiaryEntry>> _groupEntriesByMeal(
      List<FoodDiaryEntry> entries) {
    return {
      for (final m in MealType.values)
        m: entries.where((e) => e.mealType == m).toList(),
    };
  }

  FoodProduct? _findProduct(NutritionProvider provider, String id) {
    try {
      return provider.products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  String _foodWord(int count) {
    if (count == 1) return 'продукт';
    if (count >= 2 && count <= 4) return 'продукта';
    return 'продуктов';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateShort(DateTime d) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Color _mealAccent(MealType meal) {
    switch (meal) {
      case MealType.breakfast: return _P.peachDeep;
      case MealType.snack1:    return _P.yellowDeep;
      case MealType.lunch:     return _P.greenDeep;
      case MealType.snack2:    return _P.skyDeep;
      case MealType.dinner:    return _P.lavenderDeep;
      case MealType.other:     return _P.pinkDeep;
    }
  }

  String _mealEmoji(MealType meal) {
    switch (meal) {
      case MealType.breakfast: return '🍳';
      case MealType.snack1:    return '🍎';
      case MealType.lunch:     return '🍲';
      case MealType.snack2:    return '🥤';
      case MealType.dinner:    return '🍽️';
      case MealType.other:     return '🍴';
    }
  }

  MealType _currentMeal() {
    final h = DateTime.now().hour;
    if (h < 11) return MealType.breakfast;
    if (h < 15) return MealType.lunch;
    if (h < 18) return MealType.snack2;
    if (h < 22) return MealType.dinner;
    return MealType.other;
  }

  Duration _dur(int ms) =>
      _reduceMotion ? Duration.zero : Duration(milliseconds: ms);

  Widget _animBars(Widget Function(double t) builder) {
    if (_reduceMotion) return builder(1.0);
    return AnimatedBuilder(
        animation: _bars, builder: (_, __) => builder(_bars.value));
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Supporting widgets / painters
// ═══════════════════════════════════════════════════════════════════
class _MacroCol {
  final String label;
  final double cur;
  final double goal;
  final Color color;
  _MacroCol(this.label, this.cur, this.goal, this.color);
  double get pct => goal > 0 ? (cur / goal).clamp(0.0, 1.0) : 0.0;
}

class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool disable;
  const _Press({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.disable = false,
  });
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
      onTap: widget.onTap == null
          ? null
          : () {
        HapticFeedback.selectionClick();
        widget.onTap!();
      },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
        HapticFeedback.mediumImpact();
        widget.onLongPress!();
      },
      child: widget.child,
    );
    if (widget.disable || !interactive) return child;
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}

class _HeroGaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color glowColor;
  final Color background;
  const _HeroGaugePainter({
    required this.percent,
    required this.color,
    required this.glowColor,
    required this.background,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi * 0.75;
    const sweep = math.pi * 1.5;
    canvas.drawArc(
      rect, start, sweep, false,
      Paint()
        ..color = background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    final p = percent.clamp(0.0, 1.0);
    if (p <= 0) return;
    canvas.drawArc(
      rect, start, sweep * p, false,
      Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
    );
    canvas.drawArc(
      rect, start, sweep * p, false,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0, endAngle: sweep,
          colors: [color.withOpacity(0.35), color],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroGaugePainter old) =>
      old.percent != percent || old.color != color || old.glowColor != glowColor;
}

class _RingletPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color background;
  const _RingletPainter({
    required this.percent,
    required this.color,
    required this.background,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final p = percent.clamp(0.0, 1.0);
    if (p <= 0) return;
    canvas.drawArc(
      rect, -math.pi / 2, 2 * math.pi * p, false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingletPainter old) =>
      old.percent != percent || old.color != color;
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double stroke;
  const _DashedBorderPainter({
    required this.color,
    this.radius = 14,
    this.dash = 5,
    this.gap = 4,
    this.stroke = 1,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final len = math.min(dash, metric.length - dist);
        canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}