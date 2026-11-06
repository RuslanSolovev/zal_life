// features/nutrition/ui/screens/fuel_dashboard_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zal_life/features/nutrition/ui/screens/food_search_screen.dart';

import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import 'add_food_screen.dart';
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

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class FuelDashboardScreen extends StatefulWidget {
  final bool isDark; // kept for API compatibility
  const FuelDashboardScreen({super.key, this.isDark = true});

  @override
  State<FuelDashboardScreen> createState() => _FuelDashboardScreenState();
}

class _FuelDashboardScreenState extends State<FuelDashboardScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  bool _templatesExpanded = false;
  String _templatesSearchQuery = '';
  TemplatesSortMode _templatesSortMode = TemplatesSortMode.name;
  bool _searchExpanded = false;
  bool _profileBannerDismissed = false;
  MealType? _expandedMeal;
  bool _didAutoExpand = false;
  bool _reduceMotion = false;
  bool _pulseStarted = false;

  // Lightweight in-memory persistence (swap to SharedPreferences when the
  // dependency is available — see tradeoffs).
  static int _lastWaterAmount = 250;
  static final Map<String, Set<String>> _dismissedRecs = {};

  // Template memoization
  List<MealTemplate>? _cachedTemplates;
  String _cacheQuery = '';
  TemplatesSortMode _cacheSort = TemplatesSortMode.name;
  List<MealTemplate>? _cacheTemplatesRef;

  final _scrollController = ScrollController();
  final _stickyVisible = ValueNotifier<bool>(false);
  final _actionBarVisible = ValueNotifier<bool>(true);
  final _recsPage = PageController(viewportFraction: 0.9);

  late final AnimationController _entrance =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<double> _entranceCurve =
  CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
  late final AnimationController _pulse =
  AnimationController(vsync: this, duration: const Duration(seconds: 3));
  late final AnimationController _bars =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _chips =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _entrance.forward();
    _bars.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chips.forward();
    });
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
    _actionBarVisible.dispose();
    _recsPage.dispose();
    _entrance.dispose();
    _pulse.dispose();
    _bars.dispose();
    _chips.dispose();
    super.dispose();
  }

  // ── scroll driven chrome ────────────────────────────────────────
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final p = _scrollController.position;
    _stickyVisible.value = p.pixels > 140;
    final nearBottom = p.maxScrollExtent > 400 && p.pixels > p.maxScrollExtent - 320;
    _actionBarVisible.value = !nearBottom;
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

  // ── style helpers ───────────────────────────────────────────────
  TextStyle _num({double size = 14, FontWeight weight = FontWeight.w600, Color? color, double tracking = -0.4}) =>
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

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final summary = provider.getSummaryForDate(_selectedDate);
    final goals = provider.getGoalsForDate(_selectedDate);
    final entries = provider.getEntriesForDate(_selectedDate);
    final recs = provider.getRecommendations(_selectedDate);
    final meals = _groupEntriesByMeal(entries);
    final hasProfile = provider.userProfile != null;
    final dayKey = _dayKey(_selectedDate);
    final dismissed = _dismissedRecs[dayKey] ?? const <String>{};
    final visibleRecs = recs.where((r) => !dismissed.contains(r.title)).toList();

    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHero(summary, goals, hasProfile),
              ),
              if (!hasProfile && !_profileBannerDismissed)
                SliverToBoxAdapter(child: _buildProfileBanner()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildMacroCard(summary, goals)),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _buildWaterCard(provider, goals)),
              if (visibleRecs.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: _buildRecommendations(visibleRecs, dayKey),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: _buildMealsSection(provider, meals, summary.entriesCount),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: _buildRecent(provider)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: _buildTemplates(provider)),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
          // Sticky context bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildStickyOverlay(summary, goals),
          ),
          // Docked action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildActionBar(provider),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  1. HERO
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHero(DailyNutritionSummary s, NutritionGoals g, bool hasProfile) {
    final rawPct = g.calories > 0 ? s.calories / g.calories : 0.0;
    final pct = rawPct.clamp(0.0, 1.0);
    final isOver = s.calories > g.calories;
    final remaining = g.calories - s.calories;
    final accent = isOver ? _P.pinkDeep : (rawPct >= 0.9 ? _P.greenDeep : _Hero.accent);
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final noMeals = s.entriesCount == 0;

    final content = ClipRRect(
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
            // Looping radial pulse
            Positioned(
              top: 60,
              left: 60,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) {
                    final o = _reduceMotion ? 0.18 : (0.14 + 0.08 * _pulse.value);
                    return Container(
                      width: 320,
                      height: 320,
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
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header
                  Row(
                    children: [
                      _buildAvatar(hasProfile),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Питание',
                                style: GoogleFonts.inter(
                                    color: _Hero.textLow, fontSize: 12)),
                            Text(
                              isToday ? 'Сегодня' : _formatDateShort(_selectedDate),
                              style: GoogleFonts.inter(
                                color: _Hero.textHigh,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _darkPill(
                        icon: Icons.calendar_today_rounded,
                        label: isToday ? 'ДАТА' : '→',
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ring + stats
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // left column : ring + remaining chip
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
                                  width: 140,
                                  height: 140,
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
                                            background: Colors.white.withOpacity(0.08),
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
                                              fontFeatures: [
                                                ui.FontFeature.tabularFigures()
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
                        ],
                      ),
                      const SizedBox(width: 16),
                      // right column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('ДНЕВНОЙ БАЛАНС',
                                style: GoogleFonts.inter(
                                  color: _Hero.textLow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                )),
                            const SizedBox(height: 6),
                            Text(
                              '${s.calories.round()}',
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                color: _Hero.textHigh,
                                fontSize: 42,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.8,
                                height: 1,
                                fontFeatures: [ui.FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text('/ ${g.calories.round()} ккал',
                                style: GoogleFonts.inter(
                                  color: _Hero.textLow,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
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
                                    backgroundColor: Colors.white.withOpacity(0.08),
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

                  // 4 ringlets
                  Row(
                    children: [
                      _ringlet('Б', s.protein, g.protein, _P.greenDeep),
                      _ringlet('Ж', s.fat, g.fat, _P.peachDeep),
                      _ringlet('У', s.carbs, g.carbs, _P.yellowDeep),
                      _ringlet('В', s.waterMl.toDouble(), g.waterMl.toDouble(), _P.skyDeep),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _remainingChip(double remaining, bool isOver, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOver ? Icons.warning_amber_rounded : Icons.local_fire_department_rounded,
            color: accent,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            isOver
                ? 'Превышено на ${remaining.abs().round()} ккал'
                : '${remaining.round()} ккал осталось',
            style: GoogleFonts.inter(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ringlet(String label, double cur, double goal, Color color) {
    final pct = goal > 0 ? (cur / goal).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: _animBars(
                  (t) => CustomPaint(
                painter: _RingletPainter(
                  percent: pct * t,
                  color: color,
                  background: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            cur.round().toString(),
            style: GoogleFonts.inter(
              color: _Hero.textHigh,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 1),
          Text(label,
              style: GoogleFonts.inter(
                color: _Hero.textLow,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              )),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool hasProfile) {
    return _Press(
      onTap: () => _openProfileSetup(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _Hero.bgBottom,
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        alignment: Alignment.center,
        child: Icon(
          hasProfile ? Icons.person_rounded : Icons.person_outline_rounded,
          color: hasProfile ? _Hero.accent : _Hero.textLow,
          size: 22,
        ),
      ),
    );
  }

  Widget _darkPill({required IconData icon, required String label, required VoidCallback onTap}) {
    return _Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                )),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  3. MACRO SEGMENTED CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMacroCard(DailyNutritionSummary s, NutritionGoals g) {
    final cols = [
      _MacroCol('Белки', s.protein, g.protein, _P.greenDeep),
      _MacroCol('Жиры', s.fat, g.fat, _P.peachDeep),
      _MacroCol('Углеводы', s.carbs, g.carbs, _P.yellowDeep),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          color: _P.peachDeep,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              IntrinsicHeight(
                child: Row(
                  children: [
                    for (var i = 0; i < cols.length; i++) ...[
                      Expanded(child: _macroColumn(cols[i])),
                      if (i < cols.length - 1)
                        Container(width: 1, color: _P.divider),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.label,
              style: GoogleFonts.inter(
                color: _P.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 6),
          Text(
            c.cur.round().toString(),
            style: _num(
              size: 24,
              color: over ? _P.pinkDeep : _P.text,
              tracking: -1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text('из ${c.goal.round()} г',
              style: GoogleFonts.inter(
                color: _P.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  4. WATER CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildWaterCard(NutritionProvider provider, NutritionGoals g) {
    final cur = provider.getWaterForDate(_selectedDate);
    final raw = g.waterMl > 0 ? cur / g.waterMl : 0.0;
    final pct = raw.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.divider),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _P.skySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.water_drop_rounded, color: _P.skyDeep, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ВОДА',
                      style: GoogleFonts.inter(
                        color: _P.skyDeep,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      )),
                  const SizedBox(height: 3),
                  Text(
                    '${(cur / 1000).toStringAsFixed(1)} / ${(g.waterMl / 1000).toStringAsFixed(1)} л',
                    style: GoogleFonts.inter(
                      color: _P.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      height: 1,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _animBars(
                        (t) => ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: pct * t,
                        minHeight: 4,
                        backgroundColor: _P.elevated,
                        valueColor: const AlwaysStoppedAnimation(_P.skyDeep),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _Press(
                onTap: () => _addWaterFlow(provider, pick: false),
                onLongPress: () => _addWaterFlow(provider, pick: true),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _P.skySoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: _P.skyDeep.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.add_rounded, color: _P.skyDeep, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addWaterFlow(NutritionProvider provider, {required bool pick}) async {
    if (!pick) {
      await provider.addWater(_lastWaterAmount, date: _selectedDate);
      return;
    }
    final ctrl = TextEditingController(text: '$_lastWaterAmount');
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
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
                Text('ДОБАВИТЬ ВОДУ',
                    style: GoogleFonts.inter(
                      color: _P.skyDeep,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 12),
                Row(
                  children: [200, 250, 330, 500].map((ml) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _Press(
                          onTap: () => Navigator.pop(sheetCtx, ml),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _P.skySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text('+$ml',
                                style: GoogleFonts.inter(
                                  color: _P.skyDeep,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                      color: _P.text, fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Другой объём (мл)',
                    hintStyle: GoogleFonts.inter(color: _P.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: _P.bg,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final v = int.tryParse(ctrl.text.trim());
                      if (v != null && v > 0) Navigator.pop(sheetCtx, v);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _P.skyDeep,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('ДОБАВИТЬ',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    ctrl.dispose();
    if (amount != null && amount > 0) {
      _lastWaterAmount = amount;
      await provider.addWater(amount, date: _selectedDate);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  6. RECOMMENDATIONS CAROUSEL
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRecommendations(List<NutritionRecommendation> recs, String dayKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Рекомендации'),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: PageView.builder(
            controller: _recsPage,
            padEnds: false,
            itemCount: recs.length,
            itemBuilder: (_, i) {
              final r = recs[i];
              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 24 : 5,
                  right: i == recs.length - 1 ? 24 : 5,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _P.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _P.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: r.color.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(r.emoji, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: r.color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 3),
                            Text(r.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: _P.textMuted,
                                  fontSize: 11,
                                  height: 1.3,
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
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.close_rounded,
                              size: 16, color: _P.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  5. MEALS TIMELINE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMealsSection(
      NutritionProvider provider, Map<MealType, List<FoodDiaryEntry>> meals, int count) {
    final currentMeal = _currentMeal();
    final rows = <Widget>[];
    for (var i = 0; i < MealType.values.length; i++) {
      final meal = MealType.values[i];
      final entries = meals[meal] ?? const <FoodDiaryEntry>[];
      rows.add(_mealRow(
        provider: provider,
        meal: meal,
        entries: entries,
        isCurrent: meal == currentMeal,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Приёмы пищи', pill: '$count'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            children: [
              Positioned(
                left: 11,
                top: 28,
                bottom: 28,
                child: Container(width: 2, color: _P.divider),
              ),
              Column(children: rows),
            ],
          ),
        ),
      ],
    );
  }

  MealType _currentMeal() {
    final h = DateTime.now().hour;
    if (h < 11) return MealType.breakfast;
    if (h < 15) return MealType.lunch;
    if (h < 18) return MealType.snack2;
    if (h < 22) return MealType.dinner;
    return MealType.other;
  }

  Widget _mealRow({
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
              child: _timelineDot(accent, isCurrent, !isEmpty),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: isEmpty
                ? _ghostMealRow(provider, meal, accent)
                : _mealContent(provider, meal, entries, accent),
          ),
        ),
      ],
    );
  }

  Widget _timelineDot(Color accent, bool isCurrent, bool hasEntries) {
    final inner = hasEntries ? 10.0 : 8.0;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent ? accent.withOpacity(0.18) : Colors.transparent,
      ),
      alignment: Alignment.center,
      child: Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasEntries ? accent : accent.withOpacity(0.35),
        ),
      ),
    );
  }

  Widget _mealContent(NutritionProvider provider, MealType meal,
      List<FoodDiaryEntry> entries, Color accent) {
    final expanded = _expandedMeal == meal;
    final kcal = entries.fold<double>(0, (s, e) => s + e.calories);
    final protein = entries.fold<double>(0, (s, e) => s + e.protein);
    final fat = entries.fold<double>(0, (s, e) => s + e.fat);
    final carbs = entries.fold<double>(0, (s, e) => s + e.carbs);

    return Column(
      children: [
        _Press(
          onTap: () => setState(() => _expandedMeal = expanded ? null : meal),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _mealSoft(meal),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withOpacity(0.18)),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: _P.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                )),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle_rounded,
                              size: 13, color: _P.greenDeep),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entries.length} ${_foodWord(entries.length)}',
                        style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${kcal.round()} ккал',
                        style: GoogleFonts.inter(
                          color: accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        )),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _miniMacro('Б', protein, _P.greenDeep),
                        const SizedBox(width: 5),
                        _miniMacro('Ж', fat, _P.peachDeep),
                        const SizedBox(width: 5),
                        _miniMacro('У', carbs, _P.yellowDeep),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: _dur(200),
                  child: const Icon(Icons.chevron_right_rounded,
                      size: 18, color: _P.textMuted),
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
              ...entries.map((e) => _entryRow(provider, e)),
              const SizedBox(height: 6),
              _addMealButton(provider, meal, accent),
              const SizedBox(height: 8),
            ],
          )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _miniMacro(String l, double v, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text('$l${v.round()}',
            style: GoogleFonts.inter(
              color: _P.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            )),
      ],
    );
  }

  Widget _ghostMealRow(NutritionProvider provider, MealType meal, Color accent) {
    return _Press(
      onTap: () => _openAddFood(context, provider, meal: meal),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.35)),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: accent.withOpacity(0.45),
            radius: 14,
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.add_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Text('Добавить ${meal.displayName.toLowerCase()}',
                  style: GoogleFonts.inter(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entryRow(NutritionProvider provider, FoodDiaryEntry entry) {
    final product = _findProduct(provider, entry.productId);
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 4, left: 52),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: _P.pinkSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: _P.pinkDeep, size: 18),
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
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Отмена', style: _T.body),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Удалить',
                    style: _T.body.copyWith(
                        color: _P.pinkDeep, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        provider.removeEntry(entry.id);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 52, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _P.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(product?.categoryEmoji ?? '🍽️', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(entry.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _P.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  )),
            ),
            const SizedBox(width: 6),
            Text('${entry.grams.round()} г',
                style: GoogleFonts.inter(
                    color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Text('${entry.calories.round()}',
                style: GoogleFonts.inter(
                  color: _P.peachDeep,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [ui.FontFeature.tabularFigures()],
                )),
            const SizedBox(width: 2),
            Text('ккал',
                style: GoogleFonts.inter(
                    color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _addMealButton(NutritionProvider provider, MealType meal, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: _Press(
        onTap: () => _openAddFood(context, provider, meal: meal),
        child: Container(
          width: double.infinity,
          height: 42,
          decoration: BoxDecoration(
            color: _P.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _P.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, color: accent, size: 16),
              const SizedBox(width: 6),
              Text('ДОБАВИТЬ ЕЩЁ',
                  style: GoogleFonts.inter(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  7. RECENT PRODUCTS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRecent(NutritionProvider provider) {
    final recent = provider.getRecentProducts(limit: 8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Быстрый ввод', trailing: _Press(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: provider,
                  child: const FoodSearchScreen(isDark: false),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(children: [
              Text('Все', style: _T.caption),
              const Icon(Icons.chevron_right_rounded, color: _P.textMuted, size: 14),
            ]),
          ),
        )),
        const SizedBox(height: 12),
        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: recent.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) return _staggered(i, _createChip(provider));
              final p = recent[i - 1];
              return _staggered(i, _recentChip(provider, p));
            },
          ),
        ),
      ],
    );
  }

  Widget _createChip(NutritionProvider provider) {
    return _Press(
      onTap: () => _openAddFood(context, provider),
      child: Container(
        width: 96,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.divider),
          color: _P.surface,
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(color: _P.divider, radius: 16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 16, color: _P.peachDeep),
                const SizedBox(width: 4),
                Text('Создать',
                    style: GoogleFonts.inter(
                      color: _P.peachDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recentChip(NutritionProvider provider, FoodProduct p) {
    return _Press(
      onTap: () => _openAddFood(context, provider, preselected: p),
      onLongPress: () => _showProductSheet(p, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _P.peachSoft,
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
                  child: Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _P.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      )),
                ),
                const SizedBox(height: 3),
                Text('${p.calories.round()} ккал',
                    style: GoogleFonts.inter(
                      color: _P.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _staggered(int i, Widget child) {
    if (_reduceMotion) return child;
    final start = (i * 60).clamp(0, 540) / 600.0;
    final end = ((i * 60) + 300).clamp(0, 600) / 600.0;
    final anim = CurvedAnimation(
      parent: _chips,
      curve: Interval(start, end <= start ? start + 0.02 : end, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 6),
          child: c,
        ),
      ),
      child: child,
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _P.peachSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(p.categoryEmoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _T.title2),
                      const SizedBox(height: 3),
                      Text('${p.calories.round()} ккал / 100 г', style: _T.caption),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openAddFood(context, provider, preselected: p);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _P.peachDeep,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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

  // ═══════════════════════════════════════════════════════════════
  //  8. TEMPLATES
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTemplates(NutritionProvider provider) {
    final templates = provider.templates;
    if (templates.isEmpty) return const SizedBox.shrink();

    final filtered = _filteredTemplates(provider, templates);
    const limit = 3;
    final visible = _templatesExpanded ? filtered : filtered.take(limit).toList();
    final hasMore = filtered.length > limit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _templatesHeader(filtered.length),
          const SizedBox(height: 12),
          if (_searchExpanded) ...[
            _inlineSearch(),
            const SizedBox(height: 12),
          ],
          if (filtered.isEmpty)
            _emptyTemplates()
          else
            ...visible.map((t) => _templateCard(provider, t)),
          if (hasMore) ...[
            const SizedBox(height: 4),
            _Press(
              onTap: () => setState(() => _templatesExpanded = !_templatesExpanded),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: Center(
                  child: Text(
                    _templatesExpanded
                        ? 'Свернуть'
                        : 'Показать все (${filtered.length})',
                    style: GoogleFonts.inter(
                      color: _P.peachDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _templatesHeader(int count) {
    return Row(
      children: [
        if (!_searchExpanded) ...[
          Text('Готовые блюда', style: _T.title2),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _P.peachSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: GoogleFonts.inter(
                  color: _P.peachDeep,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [ui.FontFeature.tabularFigures()],
                )),
          ),
        ] else
          Expanded(
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _templatesSearchQuery = v),
              style: GoogleFonts.inter(
                  color: _P.text, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Найти блюдо…',
                hintStyle: GoogleFonts.inter(color: _P.textMuted, fontSize: 13),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
            ),
          ),
        const Spacer(),
        _iconButton(
          icon: _searchExpanded ? Icons.close_rounded : Icons.search_rounded,
          onTap: () => setState(() {
            _searchExpanded = !_searchExpanded;
            if (!_searchExpanded) _templatesSearchQuery = '';
          }),
        ),
        const SizedBox(width: 6),
        _iconButton(
          icon: Icons.sort_rounded,
          onTap: _showSortSheet,
        ),
      ],
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return _Press(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _P.divider),
        ),
        child: Icon(icon, size: 18, color: _P.peachDeep),
      ),
    );
  }

  Widget _inlineSearch() {
    // The inline TextField is rendered inside _templatesHeader when expanded;
    // this placeholder keeps layout spacing predictable.
    return const SizedBox.shrink();
  }

  void _showSortSheet() {
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
              Text('СОРТИРОВКА', style: _overline),
              const SizedBox(height: 8),
              ..._sortOptions.map((o) {
                final selected = _templatesSortMode == o.mode;
                return _Press(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _templatesSortMode = o.mode);
                  },
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: selected ? _P.peachDeep : _P.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(o.label,
                            style: GoogleFonts.inter(
                              color: _P.text,
                              fontSize: 14,
                              fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyTemplates() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.divider),
      ),
      child: Column(
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Text('Ничего не найдено', style: _T.caption),
        ],
      ),
    );
  }

  Widget _templateCard(NutritionProvider provider, MealTemplate t) {
    final cal = _templateCal(provider, t);
    final pro = _templateProtein(provider, t);
    final fat = _templateFat(provider, t);
    final carb = _templateCarbs(provider, t);

    return _Press(
      onTap: () => _showTemplateDetails(provider, t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _P.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      )),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _macroDotValue(_P.greenDeep, 'Б', pro),
                      const SizedBox(width: 10),
                      _macroDotValue(_P.peachDeep, 'Ж', fat),
                      const SizedBox(width: 10),
                      _macroDotValue(_P.yellowDeep, 'У', carb),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${cal.round()} ккал',
                style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  fontFeatures: [ui.FontFeature.tabularFigures()],
                )),
          ],
        ),
      ),
    );
  }

  Widget _macroDotValue(Color color, String l, double v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$l ${v.round()}',
            style: GoogleFonts.inter(
              color: _P.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            )),
      ],
    );
  }

  List<MealTemplate> _filteredTemplates(
      NutritionProvider provider, List<MealTemplate> templates) {
    if (_cachedTemplates != null &&
        _cacheQuery == _templatesSearchQuery &&
        _cacheSort == _templatesSortMode &&
        identical(_cacheTemplatesRef, templates)) {
      return _cachedTemplates!;
    }
    var filtered = List<MealTemplate>.from(templates);
    if (_templatesSearchQuery.trim().isNotEmpty) {
      final q = _templatesSearchQuery.toLowerCase();
      filtered = filtered.where((t) => t.name.toLowerCase().contains(q)).toList();
    }
    switch (_templatesSortMode) {
      case TemplatesSortMode.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case TemplatesSortMode.caloriesDesc:
        filtered.sort((a, b) => _templateCal(provider, b).compareTo(_templateCal(provider, a)));
        break;
      case TemplatesSortMode.caloriesAsc:
        filtered.sort((a, b) => _templateCal(provider, a).compareTo(_templateCal(provider, b)));
        break;
      case TemplatesSortMode.proteinDesc:
        filtered.sort((a, b) => _templateProtein(provider, b).compareTo(_templateProtein(provider, a)));
        break;
      case TemplatesSortMode.fatDesc:
        filtered.sort((a, b) => _templateFat(provider, b).compareTo(_templateFat(provider, a)));
        break;
      case TemplatesSortMode.carbsDesc:
        filtered.sort((a, b) => _templateCarbs(provider, b).compareTo(_templateCarbs(provider, a)));
        break;
    }
    _cachedTemplates = filtered;
    _cacheQuery = _templatesSearchQuery;
    _cacheSort = _templatesSortMode;
    _cacheTemplatesRef = templates;
    return filtered;
  }

  double _templateCal(NutritionProvider p, MealTemplate t) => t.items.fold<double>(
      0, (s, i) => s + (_findProduct(p, i.productId)?.forGrams(i.grams).calories ?? 0));
  double _templateProtein(NutritionProvider p, MealTemplate t) => t.items.fold<double>(
      0, (s, i) => s + (_findProduct(p, i.productId)?.forGrams(i.grams).protein ?? 0));
  double _templateFat(NutritionProvider p, MealTemplate t) => t.items.fold<double>(
      0, (s, i) => s + (_findProduct(p, i.productId)?.forGrams(i.grams).fat ?? 0));
  double _templateCarbs(NutritionProvider p, MealTemplate t) => t.items.fold<double>(
      0, (s, i) => s + (_findProduct(p, i.productId)?.forGrams(i.grams).carbs ?? 0));

  // ═══════════════════════════════════════════════════════════════
  //  2. STICKY CONTEXT BAR
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
                      border: const Border(
                        bottom: BorderSide(color: _P.divider, width: 1),
                      ),
                    ),
                    child: SafeArea(
                      top: true,
                      bottom: false,
                      child: SizedBox(
                        height: 56,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              // left: date chip
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
                                        color: _P.text,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                              // center: calories
                              Expanded(
                                child: Center(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${s.calories.round()}',
                                          style: GoogleFonts.inter(
                                            color: _P.text,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontFeatures: [
                                              ui.FontFeature.tabularFigures()
                                            ],
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' / ${g.calories.round()}',
                                          style: GoogleFonts.inter(
                                            color: _P.textMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            fontFeatures: [
                                              ui.FontFeature.tabularFigures()
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // right: macro dots
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
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text('${value.round()}',
            style: GoogleFonts.inter(
              color: _P.text,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            )),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  9. DOCKED ACTION BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildActionBar(NutritionProvider provider) {
    return ValueListenableBuilder<bool>(
      valueListenable: _actionBarVisible,
      builder: (_, visible, __) {
        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, 1),
            duration: _dur(220),
            curve: Curves.easeOutCubic,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: _P.surface.withOpacity(0.86),
                    border: const Border(
                      top: BorderSide(color: _P.divider, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _primaryAction(
                              icon: Icons.add_rounded,
                              label: 'Продукт',
                              onTap: () => _openAddFood(context, provider),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: _ghostAction(
                              icon: Icons.restaurant_menu_rounded,
                              label: 'Шаблон',
                              onTap: () {
                                if (_scrollController.hasClients) {
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 56,
                            child: _ghostAction(
                              icon: Icons.water_drop_rounded,
                              onTap: () => _addWaterFlow(provider, pick: true),
                            ),
                          ),
                        ],
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

  Widget _primaryAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return _Press(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _P.peachDeep,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _P.peachDeep.withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  Widget _ghostAction({required IconData icon, String? label, required VoidCallback onTap}) {
    return _Press(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _P.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _P.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _P.text, size: 18),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.inter(
                    color: _P.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  13. PROFILE BANNER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProfileBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
              child: Text(
                'Настрой профиль, чтобы видеть точные цели',
                style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
            _Press(
              onTap: () => setState(() => _profileBannerDismissed = true),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _sectionHeader(String title, {String? pill, Widget? trailing}) {
    return _Reveal(
      disable: _reduceMotion,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Text(title, style: _T.title2),
            if (pill != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _P.peachSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(pill,
                    style: GoogleFonts.inter(
                      color: _P.peachDeep,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    )),
              ),
            ],
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  NAVIGATION & MODALS
  // ═══════════════════════════════════════════════════════════════
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _P.peachDeep,
            surface: Colors.white,
            onSurface: _P.text,
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
      _didAutoExpand = false;
      _searchExpanded = false;
      _templatesSearchQuery = '';
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

  void _showTemplateDetails(NutritionProvider provider, MealTemplate t) {
    final cal = _templateCal(provider, t);
    final pro = _templateProtein(provider, t);
    final fat = _templateFat(provider, t);
    final carb = _templateCarbs(provider, t);
    var selectedMeal = MealType.suggestForNow();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) => Container(
            height: MediaQuery.of(sheetCtx).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _grabber(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _P.peachSoft,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: const Text('🍱', style: TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: _T.title2),
                                    const SizedBox(height: 3),
                                    Text('${t.items.length} ингредиентов',
                                        style: _T.caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _P.bg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                _macroMini('${cal.round()}', 'ккал', _P.peachDeep),
                                _macroMini(pro.toStringAsFixed(1), 'Б', _P.greenDeep),
                                _macroMini(fat.toStringAsFixed(1), 'Ж', _P.peachDeep),
                                _macroMini(carb.toStringAsFixed(1), 'У', _P.yellowDeep),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('ИНГРЕДИЕНТЫ', style: _overline),
                          const SizedBox(height: 10),
                          ...t.items.map((item) {
                            final p = _findProduct(provider, item.productId);
                            final m = p?.forGrams(item.grams);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _P.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(p?.categoryEmoji ?? '🍽️',
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: _P.text,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            )),
                                        Text('${item.grams.round()} г',
                                            style: GoogleFonts.inter(
                                              color: _P.textMuted,
                                              fontSize: 10,
                                            )),
                                      ],
                                    ),
                                  ),
                                  Text('${m?.calories.round() ?? 0}',
                                      style: GoogleFonts.inter(
                                        color: _P.peachDeep,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: [ui.FontFeature.tabularFigures()],
                                      )),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                          Text('ДОБАВИТЬ КАК', style: _overline),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: MealType.values.map((m) {
                              final selected = m == selectedMeal;
                              return _Press(
                                onTap: () => setSheetState(() => selectedMeal = m),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? _P.peachDeep : _P.bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? _P.peachDeep : _P.divider,
                                    ),
                                  ),
                                  child: Text('${m.emoji} ${m.displayName}',
                                      style: GoogleFonts.inter(
                                        color: selected ? Colors.white : _P.text,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(sheetCtx);
                                await provider.addTemplateAsMeal(t, selectedMeal,
                                    date: _selectedDate);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('${t.name} добавлен'),
                                  backgroundColor: _P.greenDeep,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _P.peachDeep,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('ДОБАВИТЬ В ДНЕВНИК',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      letterSpacing: 0.5)),
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
      },
    );
  }

  Widget _macroMini(String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              )),
          const SizedBox(height: 2),
          Text(unit,
              style: GoogleFonts.inter(
                color: _P.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  // ── goals editor ──────────────────────────────────────────────
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
                  Text('ЦЕЛИ НА ДЕНЬ', style: _overline.copyWith(color: _P.peachDeep)),
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
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final updated = NutritionGoals(
                          id: goals.id,
                          date: goals.date,
                          calories:
                          double.tryParse(ctrl['cal']!.text) ?? goals.calories,
                          protein:
                          double.tryParse(ctrl['pro']!.text) ?? goals.protein,
                          fat: double.tryParse(ctrl['fat']!.text) ?? goals.fat,
                          carbs:
                          double.tryParse(ctrl['carb']!.text) ?? goals.carbs,
                          waterMl:
                          int.tryParse(ctrl['water']!.text) ?? goals.waterMl,
                        );
                        Navigator.pop(sheetCtx);
                        await provider.updateGoals(updated);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Цели обновлены'),
                          backgroundColor: _P.greenDeep,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _P.peachDeep,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('СОХРАНИТЬ',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 1.0)),
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
      style: GoogleFonts.inter(
          color: _P.text, fontSize: 15, fontWeight: FontWeight.w600),
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
    width: 36,
    height: 5,
    decoration: BoxDecoration(
      color: _P.divider,
      borderRadius: BorderRadius.circular(3),
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════
  Map<MealType, List<FoodDiaryEntry>> _groupEntriesByMeal(List<FoodDiaryEntry> entries) {
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
    const months = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Color _mealAccent(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return _P.peachDeep;
      case MealType.snack1:
        return _P.yellowDeep;
      case MealType.lunch:
        return _P.greenDeep;
      case MealType.snack2:
        return _P.skyDeep;
      case MealType.dinner:
        return _P.lavenderDeep;
      case MealType.other:
        return _P.pinkDeep;
    }
  }

  Color _mealSoft(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return _P.peachSoft;
      case MealType.snack1:
        return _P.yellowSoft;
      case MealType.lunch:
        return _P.greenSoft;
      case MealType.snack2:
        return _P.skySoft;
      case MealType.dinner:
        return _P.lavenderSoft;
      case MealType.other:
        return _P.pinkSoft;
    }
  }

  String _mealEmoji(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return '🍳';
      case MealType.snack1:
        return '🍎';
      case MealType.lunch:
        return '🍲';
      case MealType.snack2:
        return '🥤';
      case MealType.dinner:
        return '🍽️';
      case MealType.other:
        return '🍴';
    }
  }

  Duration _dur(int ms) =>
      _reduceMotion ? Duration.zero : Duration(milliseconds: ms);

  Widget _animBars(Widget Function(double t) builder) {
    if (_reduceMotion) return builder(1.0);
    return AnimatedBuilder(animation: _bars, builder: (_, __) => builder(_bars.value));
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

class _SortOption {
  final TemplatesSortMode mode;
  final String label;
  const _SortOption(this.mode, this.label);
}

const _sortOptions = <_SortOption>[
  _SortOption(TemplatesSortMode.name, 'По названию'),
  _SortOption(TemplatesSortMode.caloriesDesc, 'Калории ↓'),
  _SortOption(TemplatesSortMode.caloriesAsc, 'Калории ↑'),
  _SortOption(TemplatesSortMode.proteinDesc, 'Белок ↓'),
  _SortOption(TemplatesSortMode.fatDesc, 'Жиры ↓'),
  _SortOption(TemplatesSortMode.carbsDesc, 'Углеводы ↓'),
];

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

class _Reveal extends StatefulWidget {
  final Widget child;
  final bool disable;
  const _Reveal({required this.child, required this.disable});
  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

  @override
  void initState() {
    super.initState();
    if (widget.disable) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.disable) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 6), child: child),
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Painters
// ═══════════════════════════════════════════════════════════════════
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
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    final p = percent.clamp(0.0, 1.0);
    if (p <= 0) return;

    // soft outer glow on the progress arc only
    canvas.drawArc(
      rect,
      start,
      sweep * p,
      false,
      Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
    );

    canvas.drawArc(
      rect,
      start,
      sweep * p,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: sweep,
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
      center,
      radius,
      Paint()
        ..color = background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final p = percent.clamp(0.0, 1.0);
    if (p <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * p,
      false,
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
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
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

// ═══════════════════════════════════════════════════════════════════
//  ENUM (preserved)
// ═══════════════════════════════════════════════════════════════════
enum TemplatesSortMode { name, caloriesDesc, caloriesAsc, proteinDesc, fatDesc, carbsDesc }

