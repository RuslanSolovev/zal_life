// features/nutrition/ui/screens/plan_week_screen.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  Design tokens (единый стиль)
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
  static const brownSoft = Color(0xFFF3E9DC);
  static const brownDeep = Color(0xFFA87B4F);
}

class _Hero {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const accent = Color(0xFF6C9E88);
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
//  РЕЖИМЫ ПЛАНА
// ═══════════════════════════════════════════════════════════════════
enum PlanMode {
  orientir,
  byMeal,
  flexible,
}

extension PlanModeX on PlanMode {
  String get label {
    switch (this) {
      case PlanMode.orientir: return 'Ориентир';
      case PlanMode.byMeal: return 'По приёмам';
      case PlanMode.flexible: return 'Гибкий';
    }
  }
  String get letter {
    switch (this) {
      case PlanMode.orientir: return 'A';
      case PlanMode.byMeal: return 'B';
      case PlanMode.flexible: return 'C';
    }
  }
  String get emoji {
    switch (this) {
      case PlanMode.orientir: return '🎯';
      case PlanMode.byMeal: return '📋';
      case PlanMode.flexible: return '🏦';
    }
  }
  String get description {
    switch (this) {
      case PlanMode.orientir: return 'Цели на день, без деталей';
      case PlanMode.byMeal: return 'Каждый приём расписан';
      case PlanMode.flexible: return 'Банк калорий на неделю';
    }
  }
  Color get color {
    switch (this) {
      case PlanMode.orientir: return _P.yellowDeep;
      case PlanMode.byMeal: return _P.skyDeep;
      case PlanMode.flexible: return _P.greenDeep;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class PlanWeekScreen extends StatefulWidget {
  const PlanWeekScreen({super.key});

  @override
  State<PlanWeekScreen> createState() => _PlanWeekScreenState();
}

class _PlanWeekScreenState extends State<PlanWeekScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  PlanMode _mode = PlanMode.byMeal;
  late final AnimationController _bars = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  late final ScrollController _weekScroll = ScrollController();
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _bars.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void dispose() {
    _bars.dispose();
    _weekScroll.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (_weekScroll.hasClients) {
      _weekScroll.animateTo(
        160.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final day = _findOrCreateDay(provider);
    final meals = provider.getMealsForDay(_selectedDate);
    final summary = provider.getSummaryForDate(_selectedDate);
    final goals = provider.getGoalsForDate(_selectedDate);

    return Scaffold(
      backgroundColor: _P.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildHero(provider, day, summary, goals)),
          SliverToBoxAdapter(child: _buildModeSwitcher()),
          SliverToBoxAdapter(child: _buildWeekCalendar(provider)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          if (_mode == PlanMode.orientir)
            SliverToBoxAdapter(child: _buildModeAOrientir(provider, summary, goals))
          else if (_mode == PlanMode.byMeal)
            SliverToBoxAdapter(child: _buildModeBByMeal(provider, day, meals, goals, summary))
          else
            SliverToBoxAdapter(child: _buildModeCFlexible(provider, summary, goals)),

          SliverToBoxAdapter(child: _buildDayActions(provider, day)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: _buildFab(provider, day),
    );
  }

  PlanDay _findOrCreateDay(NutritionProvider provider) {
    try {
      return provider.planDays.firstWhere((d) => _isSameDay(d.date, _selectedDate));
    } catch (_) {
      return PlanDay(id: '', date: _selectedDate);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  HERO
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHero(NutritionProvider provider, PlanDay day,
      DailyNutritionSummary summary, NutritionGoals goals) {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final weekdayRu = _weekdayRu(_selectedDate.weekday);
    final meals = provider.getMealsForDay(_selectedDate);
    final weekMeals = provider.planMeals.length;
    final weekCompleted = provider.planMeals.where((m) => m.isCompleted).length;

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
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _iconPill(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ПЛАН НЕДЕЛИ',
                              style: GoogleFonts.inter(
                                  color: _Hero.textLow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4)),
                          const SizedBox(height: 2),
                          Text(
                            isToday ? 'Сегодня' : '$weekdayRu, ${_selectedDate.day} ${_monthRu(_selectedDate.month)}',
                            style: GoogleFonts.inter(
                                color: _Hero.textHigh,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3),
                          ),
                        ],
                      ),
                    ),
                    _glassPill(
                      icon: Icons.check_circle_outline_rounded,
                      label: '$weekCompleted/$weekMeals',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _heroMetric(
                      value: '${summary.calories.round()}',
                      label: 'съедено',
                      emoji: '🔥',
                      color: _P.peachDeep,
                    ),
                    const SizedBox(width: 10),
                    _heroMetric(
                      value: '${goals.calories.round()}',
                      label: 'цель',
                      emoji: '🎯',
                      color: _P.yellowDeep,
                    ),
                    const SizedBox(width: 10),
                    _heroMetric(
                      value: '${meals.length}',
                      label: 'приёмов',
                      emoji: '🍽️',
                      color: _P.skyDeep,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroMetric({
    required String value,
    required String label,
    required String emoji,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(
                    color: _Hero.textHigh,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                    fontFeatures: const [ui.FontFeature.tabularFigures()])),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    color: _Hero.textLow,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _iconPill({required IconData icon, required VoidCallback onTap}) {
    return _Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [ui.FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MODE SWITCHER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildModeSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.divider),
        ),
        child: Row(
          children: PlanMode.values.map((mode) {
            final selected = _mode == mode;
            return Expanded(
              child: _Press(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _mode = mode);
                },
                child: AnimatedContainer(
                  duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? mode.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(mode.emoji, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(mode.letter,
                              style: GoogleFonts.inter(
                                  color: selected ? Colors.white : _P.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(mode.label,
                          style: GoogleFonts.inter(
                              color: selected ? Colors.white : _P.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  WEEK CALENDAR (с визуальной деградацией прошедших дней)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildWeekCalendar(NutritionProvider provider) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          controller: _weekScroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: _padH),
          physics: const BouncingScrollPhysics(),
          itemCount: days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final day = days[i];
            final isToday = _isSameDay(day, today);
            final isSelected = _isSameDay(day, _selectedDate);
            final isPast = day.isBefore(today) && !isToday;
            final meals = provider.getMealsForDay(day);
            final hasPlan = meals.isNotEmpty;
            final dayData = provider.planDays.where((d) => _isSameDay(d.date, day)).firstOrNull;
            final isCheat = dayData?.isCheatDay ?? false;
            final isVacation = dayData?.isVacation ?? false;

            return _Press(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedDate = day);
              },
              child: AnimatedOpacity(
                opacity: isPast && !isSelected ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedContainer(
                  duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                  width: isSelected ? 70 : 64,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _P.greenDeep : _P.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _P.greenDeep : (isToday ? _P.greenDeep.withOpacity(0.4) : _P.divider),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: _P.greenDeep.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_weekdayShort(day.weekday),
                          style: GoogleFonts.inter(
                              color: isSelected ? Colors.white.withOpacity(0.8) : _P.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4)),
                      const SizedBox(height: 4),
                      Text('${day.day}',
                          style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : _P.text,
                              fontSize: isSelected ? 20 : 18,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [ui.FontFeature.tabularFigures()])),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isCheat)
                            const Text('🍕', style: TextStyle(fontSize: 9))
                          else if (isVacation)
                            const Text('🏖️', style: TextStyle(fontSize: 9))
                          else if (hasPlan)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : _P.greenDeep,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: _P.divider,
                                  shape: BoxShape.circle,
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MODE A: ОРИЕНТИР
  // ═══════════════════════════════════════════════════════════════
  Widget _buildModeAOrientir(NutritionProvider provider,
      DailyNutritionSummary summary, NutritionGoals goals) {
    final pct = goals.calories > 0 ? (summary.calories / goals.calories).clamp(0.0, 1.5) : 0.0;
    final hit = pct >= 0.85 && pct <= 1.15;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _P.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _P.yellowSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🎯', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('РЕЖИМ ОРИЕНТИР',
                          style: GoogleFonts.inter(
                              color: _P.yellowDeep,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text('Просто цель на день',
                          style: GoogleFonts.inter(
                              color: _P.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text('${summary.calories.round()}',
                      style: GoogleFonts.inter(
                          color: hit ? _P.greenDeep : _P.text,
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -2,
                          fontFeatures: const [ui.FontFeature.tabularFigures()])),
                  Text('/ ${goals.calories.round()} ккал',
                      style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hit ? _P.greenSoft : _P.yellowSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hit ? '✓ В ЦЕЛИ' : '${(pct * 100).round()}%',
                      style: GoogleFonts.inter(
                          color: hit ? _P.greenDeep : _P.yellowDeep,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _animBars((t) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (pct * t).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: _P.elevated,
                valueColor: AlwaysStoppedAnimation(hit ? _P.greenDeep : _P.yellowDeep),
              ),
            )),
            const SizedBox(height: 16),
            Text('💡 Вечером автоматически отметится "выполнено", если попадёшь в ±10%',
                style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MODE B: ПО ПРИЁМАМ (с водой, анимациями, ghost)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildModeBByMeal(NutritionProvider provider, PlanDay day,
      List<PlanMeal> meals, NutritionGoals goals, DailyNutritionSummary summary) {
    final sortedMeals = List<PlanMeal>.from(meals);
    sortedMeals.sort((a, b) => a.mealType.index.compareTo(b.mealType.index));

    // Идея 9: "Остаток на вечер"
    final remaining = goals.calories - summary.calories;
    final remainingProtein = goals.protein - summary.protein;
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate, now);
    final showEveningHint = isToday && now.hour >= 15 && remaining > 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок режима
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _P.skySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _P.skyDeep.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('РЕЖИМ: ПО ПРИЁМАМ',
                          style: GoogleFonts.inter(
                              color: _P.skyDeep,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text('Вычёркивай, когда поел',
                          style: GoogleFonts.inter(
                              color: _P.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Идея 9: Плашка "Остаток на вечер"
          if (showEveningHint)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_P.lavenderSoft, _P.lavenderSoft.withOpacity(0.5)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _P.lavenderDeep.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Остаток на вечер',
                              style: GoogleFonts.inter(
                                  color: _P.lavenderDeep,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            '~${remaining.round()} ккал и ${remainingProtein.round()} г белка',
                            style: GoogleFonts.inter(
                                color: _P.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _P.lavenderDeep.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('💡', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

          // Пустое состояние
          if (sortedMeals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _P.divider),
              ),
              child: Column(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text('Нет запланированных приёмов',
                      style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Нажми + чтобы добавить блюдо',
                      style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w400)),
                ],
              ),
            )
          else
            ..._buildMealListWithWater(provider, sortedMeals, goals, summary),
        ],
      ),
    );
  }

  // Идея 3: Вода прямо в ленте приёмов пищи
  List<Widget> _buildMealListWithWater(NutritionProvider provider,
      List<PlanMeal> meals, NutritionGoals goals, DailyNutritionSummary summary) {
    final widgets = <Widget>[];
    bool waterInserted = false;

    for (int i = 0; i < meals.length; i++) {
      widgets.add(_mealTile(provider, meals[i], goals));

      // Вставляем трекер воды после завтрака или первого приёма
      if (!waterInserted &&
          (meals[i].mealType == MealType.breakfast || i == 0)) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(_waterTrackerInline(provider, summary, goals));
        widgets.add(const SizedBox(height: 8));
        waterInserted = true;
      }
    }

    // Если приёмов нет, вода всё равно показывается (но тут мы в else-ветке)
    return widgets;
  }

  // Идея 3: Компактный трекер воды
  Widget _waterTrackerInline(NutritionProvider provider,
      DailyNutritionSummary summary, NutritionGoals goals) {
    final pct = goals.waterMl > 0 ? (summary.waterMl / goals.waterMl).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.skySoft),
        boxShadow: [
          BoxShadow(color: _P.skyDeep.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('Вода',
                  style: GoogleFonts.inter(
                      color: _P.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${summary.waterMl} / ${goals.waterMl} мл',
                  style: GoogleFonts.inter(
                      color: _P.skyDeep,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [ui.FontFeature.tabularFigures()])),
            ],
          ),
          const SizedBox(height: 8),
          _animBars((t) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct * t,
              minHeight: 6,
              backgroundColor: _P.skySoft,
              valueColor: const AlwaysStoppedAnimation(_P.skyDeep),
            ),
          )),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Press(
                  onTap: () async {
                    await provider.addWater(250, date: _selectedDate);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _P.skySoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _P.skyDeep.withOpacity(0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Text('+250 мл',
                        style: GoogleFonts.inter(
                            color: _P.skyDeep,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Press(
                  onTap: () async {
                    await provider.addWater(500, date: _selectedDate);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _P.skySoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _P.skyDeep.withOpacity(0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Text('+500 мл',
                        style: GoogleFonts.inter(
                            color: _P.skyDeep,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MEAL TILE (с анимацией, ghost, макро-полосками)
  // ═══════════════════════════════════════════════════════════════
  Widget _mealTile(NutritionProvider provider, PlanMeal meal, NutritionGoals goals) {
    final template = provider.templates.where((t) => t.id == meal.templateId).firstOrNull;
    final mealEmoji = meal.mealType.emoji;
    final mealName = meal.mealType.displayName;

    final isCompleted = meal.isCompleted;
    final isSkipped = meal.note == 'Пропущено';
    final isEaten = isCompleted && !isSkipped;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isEaten
              ? _P.greenSoft.withOpacity(0.4)
              : (isSkipped ? _P.pinkSoft.withOpacity(0.3) : _P.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEaten
                ? _P.greenDeep.withOpacity(0.25)
                : (isSkipped ? _P.pinkDeep.withOpacity(0.2) : _P.divider),
          ),
          boxShadow: isCompleted ? null : [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Иконка приёма
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isEaten
                        ? _P.greenDeep.withOpacity(0.12)
                        : (isSkipped ? _P.pinkDeep.withOpacity(0.1) : _P.bg),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(mealEmoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mealName,
                          style: GoogleFonts.inter(
                              color: isCompleted ? _P.textMuted : _P.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              decorationColor: isEaten ? _P.greenDeep : _P.pinkDeep,
                              decorationThickness: 2)),
                      if (template != null) ...[
                        const SizedBox(height: 2),
                        Text(template.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                color: isCompleted ? _P.textMuted.withOpacity(0.6) : _P.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ),

                // Статус или действия
                if (isEaten)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _P.greenDeep,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, color: Colors.white, size: 10),
                            const SizedBox(width: 3),
                            Text('СЪЕДЕНО',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _actionButton(
                        icon: Icons.undo_rounded,
                        color: _P.textMuted,
                        onTap: () async {
                          await provider.unmarkMealAsCompleted(meal.id);
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ],
                  )
                else if (isSkipped)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _P.pinkDeep.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('ПРОПУЩЕНО',
                            style: GoogleFonts.inter(
                                color: _P.pinkDeep,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 6),
                      _actionButton(
                        icon: Icons.undo_rounded,
                        color: _P.textMuted,
                        onTap: () async {
                          await provider.unmarkMealAsCompleted(meal.id);
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionButton(
                        icon: Icons.check_rounded,
                        color: _P.greenDeep,
                        onTap: () => _showPortionDialog(provider, meal, template),
                      ),
                      const SizedBox(width: 6),
                      _actionButton(
                        icon: Icons.swap_horiz_rounded,
                        color: _P.skyDeep,
                        onTap: () => _replaceMeal(provider, meal),
                      ),
                      const SizedBox(width: 6),
                      _actionButton(
                        icon: Icons.close_rounded,
                        color: _P.pinkDeep,
                        onTap: () => _skipMeal(provider, meal),
                      ),
                    ],
                  ),
              ],
            ),

            // Макро-полоски (Идея 7)
            if (template != null && !isCompleted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _P.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(child: _macroBar('Б', template.protein, 50, _P.greenDeep, _P.greenSoft)),
                    const SizedBox(width: 8),
                    Expanded(child: _macroBar('Ж', template.fat, 40, _P.yellowDeep, _P.yellowSoft)),
                    const SizedBox(width: 8),
                    Expanded(child: _macroBar('У', template.carbs, 80, _P.skyDeep, _P.skySoft)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _P.peachSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${template.calories.round()}',
                          style: GoogleFonts.inter(
                              color: _P.peachDeep,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [ui.FontFeature.tabularFigures()])),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Идея 7: Макро-полоска
  Widget _macroBar(String label, double value, double max, Color deep, Color soft) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: GoogleFonts.inter(color: deep, fontSize: 9, fontWeight: FontWeight.w700)),
            const SizedBox(width: 3),
            Text('${value.toStringAsFixed(0)}г',
                style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [ui.FontFeature.tabularFigures()])),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: soft,
            valueColor: AlwaysStoppedAnimation(deep),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _Press(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MODE C: ГИБКИЙ БАНК КАЛОРИЙ
  // ═══════════════════════════════════════════════════════════════
  Widget _buildModeCFlexible(NutritionProvider provider,
      DailyNutritionSummary summary, NutritionGoals goals) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    double weekTarget = 0;
    double weekEaten = 0;

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayGoals = provider.getGoalsForDate(day);
      final daySummary = provider.getSummaryForDate(day);
      weekTarget += dayGoals.calories;
      weekEaten += daySummary.calories;
    }

    final weekBalance = weekTarget - weekEaten;
    final isDebt = weekBalance < 0;
    final pct = weekTarget > 0 ? (weekEaten / weekTarget).clamp(0.0, 1.5) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padH),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Hero.bgTop, _Hero.bgBottom],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🏦', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ГИБКИЙ РЕЖИМ',
                          style: GoogleFonts.inter(
                              color: _P.greenSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4)),
                      const SizedBox(height: 2),
                      Text('Банк калорий на неделю',
                          style: GoogleFonts.inter(
                              color: _Hero.textHigh,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(isDebt ? 'ДОЛГ' : 'ОСТАТОК',
                      style: GoogleFonts.inter(
                          color: _Hero.textLow,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4)),
                  const SizedBox(height: 8),
                  Text('${weekBalance.abs().round()}',
                      style: GoogleFonts.inter(
                          color: isDebt ? _P.pinkDeep : _P.greenSoft,
                          fontSize: 56,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -2.5,
                          fontFeatures: const [ui.FontFeature.tabularFigures()])),
                  Text('ккал',
                      style: GoogleFonts.inter(
                          color: _Hero.textLow,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _animBars((t) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct * t).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(isDebt ? _P.pinkDeep : _P.greenDeep),
              ),
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('СЪЕДЕНО',
                          style: GoogleFonts.inter(
                              color: _Hero.textLow,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 2),
                      Text('${weekEaten.round()}',
                          style: GoogleFonts.inter(
                              color: _Hero.textHigh,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [ui.FontFeature.tabularFigures()])),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('БАНК',
                          style: GoogleFonts.inter(
                              color: _Hero.textLow,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 2),
                      Text('${weekTarget.round()}',
                          style: GoogleFonts.inter(
                              color: _Hero.textHigh,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [ui.FontFeature.tabularFigures()])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Text(isDebt ? '⚠️' : '💡', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isDebt
                          ? 'Переели на этой неделе. Постарайтесь меньше есть до воскресенья'
                          : 'Можете позволить себе ещё ${weekBalance.round()} ккал до конца недели',
                      style: GoogleFonts.inter(
                          color: _Hero.textLow,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DAY ACTIONS (Читмил / Отпуск)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDayActions(NutritionProvider provider, PlanDay day) {
    final isCheat = day.id.isNotEmpty && day.isCheatDay;
    final isVacation = day.id.isNotEmpty && day.isVacation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 20, _padH, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ДЕНЬ',
                style: GoogleFonts.inter(
                    color: _P.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _toggleChip(
                    emoji: '🍕',
                    label: 'Читмил',
                    active: isCheat,
                    color: _P.peachDeep,
                    onTap: () => _toggleCheatDay(provider, day),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _toggleChip(
                    emoji: '🏖️',
                    label: 'Отпуск',
                    active: isVacation,
                    color: _P.skyDeep,
                    onTap: () => _toggleVacation(provider, day),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleChip({
    required String emoji,
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : _P.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color : _P.divider,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    color: active ? color : _P.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  FAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFab(NutritionProvider provider, PlanDay day) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _P.greenDeep.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showAddMealSheet(provider, day),
        backgroundColor: _P.greenDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════════
  Future<void> _showAddMealSheet(NutritionProvider provider, PlanDay day) async {
    final template = await showModalBottomSheet<MealTemplate>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RecipePickerSheet(provider: provider),
    );

    if (template != null) {
      await provider.addToPlan(
        date: _selectedDate,
        mealType: MealType.suggestForNow(),
        templateId: template.id,
      );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${template.name} добавлен в план'),
        backgroundColor: _P.greenDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  // Идея 2: Диалог корректировки порции
  Future<void> _showPortionDialog(NutritionProvider provider, PlanMeal meal, MealTemplate? template) async {
    double multiplier = 1.0;

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: _P.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Сколько съел?', style: _T.headline),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (template != null)
                Text(template.name,
                    style: _T.body,
                    textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _portionBtn('½', 0.5, multiplier, (v) => setStateDialog(() => multiplier = v)),
                  _portionBtn('1', 1.0, multiplier, (v) => setStateDialog(() => multiplier = v)),
                  _portionBtn('1½', 1.5, multiplier, (v) => setStateDialog(() => multiplier = v)),
                  _portionBtn('2', 2.0, multiplier, (v) => setStateDialog(() => multiplier = v)),
                ],
              ),
              const SizedBox(height: 16),
              if (template != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _P.peachSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '🔥 ${(template.calories * multiplier).round()} ккал  •  💪 ${(template.protein * multiplier).round()}г',
                    style: GoogleFonts.inter(
                        color: _P.peachDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [ui.FontFeature.tabularFigures()]),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text('Отмена',
                  style: GoogleFonts.inter(color: _P.textMuted, fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, multiplier),
              style: ElevatedButton.styleFrom(
                backgroundColor: _P.greenDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Отметить ✓'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result > 0) {
      await provider.markMealAsCompleted(meal.id, portions: result, date: _selectedDate);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ Съедено ${(result * 100).round()}% порции'),
        backgroundColor: _P.greenDeep,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  Widget _portionBtn(String label, double val, double current, ValueChanged<double> onTap) {
    final isSelected = current == val;
    return _Press(
      onTap: () => onTap(val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? _P.greenDeep : _P.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _P.greenDeep : _P.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: _P.greenDeep.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: GoogleFonts.inter(
                color: isSelected ? Colors.white : _P.text,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  // Идея 4: Умная замена (Smart Swap)
  Future<void> _replaceMeal(NutritionProvider provider, PlanMeal meal) async {
    if (meal.templateId == null) return;

    final currentTemplate = provider.templates
        .where((t) => t.id == meal.templateId)
        .firstOrNull;
    if (currentTemplate == null) return;

    final alternatives = provider.getAlternativeMeals(currentTemplate, limit: 3);

    if (alternatives.isEmpty) {
      _showInfo('Нет замен', 'Не удалось найти блюда с похожим КБЖУ. Добавь больше рецептов.');
      return;
    }

    final chosen = await showModalBottomSheet<MealTemplate>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SwapMealSheet(
        provider: provider,
        current: currentTemplate,
        alternatives: alternatives,
      ),
    );

    if (chosen != null) {
      // Удаляем старый, добавляем новый
      await provider.removeFromPlan(meal.id);
      await provider.addToPlan(
        date: _selectedDate,
        mealType: meal.mealType,
        templateId: chosen.id,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🔄 Заменено на «${chosen.name}»'),
        backgroundColor: _P.skyDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  // Идея 6: Режим Призрак (Пропустить)
  Future<void> _skipMeal(NutritionProvider provider, PlanMeal meal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _P.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Пропустить приём?', style: _T.headline),
        content: Text(
          'Калории этого приёма не будут учтены. Приём останется в плане как «Пропущенный».',
          style: _T.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Нет', style: GoogleFonts.inter(color: _P.textMuted, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _P.pinkDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Пропустить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.skipMeal(meal.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('⊘ Приём пропущен'),
        backgroundColor: _P.pinkDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  Future<void> _toggleCheatDay(NutritionProvider provider, PlanDay day) async {
    _showInfo('Читмил', 'Этот день не будет учитываться в статистике');
  }

  Future<void> _toggleVacation(NutritionProvider provider, PlanDay day) async {
    _showInfo('Отпуск', 'План приостановлен, streak не сбивается');
  }

  void _showInfo(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: _T.headline),
        content: Text(message, style: _T.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ОК')),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekdayRu(int wd) {
    const names = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    return names[wd - 1];
  }

  String _weekdayShort(int wd) {
    const names = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    return names[wd - 1];
  }

  String _monthRu(int m) {
    const names = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return names[m - 1];
  }

  Widget _animBars(Widget Function(double t) builder) {
    if (_reduceMotion) return builder(1.0);
    return AnimatedBuilder(animation: _bars, builder: (_, __) => builder(_bars.value));
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SWAP MEAL SHEET (Идея 4: Умная замена)
// ═══════════════════════════════════════════════════════════════════
class _SwapMealSheet extends StatelessWidget {
  final NutritionProvider provider;
  final MealTemplate current;
  final List<MealTemplate> alternatives;

  const _SwapMealSheet({
    required this.provider,
    required this.current,
    required this.alternatives,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36, height: 5,
              decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Заменить блюдо', style: _T.title2),
                        const SizedBox(height: 2),
                        Text('Похожие по КБЖУ варианты',
                            style: _T.caption),
                      ],
                    ),
                  ),
                  _Press(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: _P.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Текущее блюдо
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _P.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _P.divider),
                ),
                child: Row(
                  children: [
                    const Text('Сейчас: ',
                        style: TextStyle(fontSize: 11, color: _P.textMuted)),
                    Expanded(
                      child: Text(current.name,
                          style: GoogleFonts.inter(
                              color: _P.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('${current.calories.round()} ккал',
                        style: GoogleFonts.inter(
                            color: _P.peachDeep,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: alternatives.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final alt = alternatives[i];
                  return _Press(
                    onTap: () => Navigator.pop(context, alt),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _P.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _P.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _P.skySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text('🍱', style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alt.name,
                                    style: GoogleFonts.inter(
                                        color: _P.text,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _swapMacro('🔥', '${alt.calories.round()}', _P.peachDeep),
                                    const SizedBox(width: 8),
                                    _swapMacro('💪', '${alt.protein.round()}г', _P.greenDeep),
                                    const SizedBox(width: 8),
                                    _swapMacro('🧈', '${alt.fat.round()}г', _P.yellowDeep),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.swap_horiz_rounded, size: 18, color: _P.skyDeep),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swapMacro(String emoji, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 9)),
        const SizedBox(width: 2),
        Text(value,
            style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFeatures: const [ui.FontFeature.tabularFigures()])),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  RECIPE PICKER SHEET
// ═══════════════════════════════════════════════════════════════════
class _RecipePickerSheet extends StatefulWidget {
  final NutritionProvider provider;
  const _RecipePickerSheet({required this.provider});

  @override
  State<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<_RecipePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final templates = _query.isEmpty
        ? widget.provider.templates.take(50).toList()
        : widget.provider.templates
        .where((t) => t.name.toLowerCase().contains(_query.toLowerCase()))
        .take(50)
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 36, height: 5, decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Добавить в план', style: _T.title2),
                  const Spacer(),
                  _Press(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: _P.bg, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: GoogleFonts.inter(color: _P.text, fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Поиск рецепта...',
                  hintStyle: GoogleFonts.inter(color: _P.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: _P.textMuted, size: 18),
                  filled: true,
                  fillColor: _P.bg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: templates.isEmpty
                  ? Center(child: Text('Нет рецептов', style: _T.body))
                  : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.82,
                ),
                itemCount: templates.length,
                itemBuilder: (_, i) {
                  final t = templates[i];
                  return _Press(
                    onTap: () => Navigator.pop(context, t),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _P.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _P.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _P.peachSoft,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: const Text('🍱', style: TextStyle(fontSize: 14)),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(t.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    color: _P.text,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2)),
                          ),
                          Text('${t.calories.round()} ккал',
                              style: GoogleFonts.inter(
                                  color: _P.peachDeep,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [ui.FontFeature.tabularFigures()])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PRESS HELPER
// ═══════════════════════════════════════════════════════════════════
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Press({required this.child, this.onTap});

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
    final interactive = widget.onTap != null;
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
      child: widget.child,
    );
    if (!interactive) return child;
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}