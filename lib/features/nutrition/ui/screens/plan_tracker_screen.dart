// features/nutrition/ui/screens/plan_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_models.dart';
import '../../models/nutrition_program.dart';
import '../../providers/nutrition_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM — «Терракота» (warm editorial)
// ═══════════════════════════════════════════════════════════════════
class _T {
  static const bg          = Color(0xFFF9F5EE);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF2ECE2);

  static const ink         = Color(0xFF2B2420);
  static const inkSoft     = Color(0xFF5C544C);
  static const muted       = Color(0xFF9A8F82);
  static const faint       = Color(0xFFCFC5B8);

  static const terracotta      = Color(0xFFCA6D4E);
  static const terracottaDark  = Color(0xFFA5502F);
  static const terracottaLight = Color(0xFFF7E4DB);

  static const sage        = Color(0xFF7A9678);
  static const sageLight   = Color(0xFFE6EDE2);

  static const mustard     = Color(0xFFD9A83F);
  static const mustardLight= Color(0xFFFCF0D4);

  static const sky         = Color(0xFF6E96B8);
  static const skyLight    = Color(0xFFE3EBF2);

  static const rose        = Color(0xFFC86B7A);
  static const roseLight   = Color(0xFFF7E1E5);

  static const border      = Color(0xFFE8DFD2);
  static const borderStrong= Color(0xFFD9CCB8);
}

TextStyle _display({
  double size = 22,
  FontWeight weight = FontWeight.w600,
  Color color = _T.ink,
  double height = 1.15,
}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: -0.3,
    );

TextStyle _body({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _T.ink,
  double height = 1.4,
}) =>
    GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

TextStyle _mono({
  double size = 11,
  FontWeight weight = FontWeight.w600,
  Color color = _T.muted,
  double letterSpacing = 0.6,
}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );

// ═══════════════════════════════════════════════════════════════════
//  PLAN TRACKER SCREEN
// ═══════════════════════════════════════════════════════════════════
class PlanTrackerScreen extends StatefulWidget {
  const PlanTrackerScreen({super.key});

  @override
  State<PlanTrackerScreen> createState() => _PlanTrackerScreenState();
}

class _PlanTrackerScreenState extends State<PlanTrackerScreen> {
  late DateTime _selectedDate;
  final GlobalKey _heroKey = GlobalKey();
  bool _pastHero = false;

  // Допуски («люфт») для оценки недели
  static const double _kcalTol = 0.15;  // ±15% по калориям
  static const double _macroTol = 0.10; // ±10% по БЖУ и воде

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  bool _onScroll(ScrollNotification n) {
    final heroH = _heroKey.currentContext?.size?.height ?? 0;
    final past = heroH > 0 && n.metrics.pixels > heroH - 60;
    if (past != _pastHero) {
      setState(() => _pastHero = past);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final program = provider.activeProgram;
    if (program == null) return _emptyState(context);

    final hasBg = (program.backgroundImage ?? '').isNotEmpty;

    final days = provider.planDays
        .where((d) => d.programId == program.id)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (days.isNotEmpty) {
      if (_selectedDate.isBefore(days.first.date)) {
        _selectedDate = days.first.date;
      }
      if (_selectedDate.isAfter(days.last.date)) {
        _selectedDate = days.last.date;
      }
    }

    final day = days
        .where((d) => _sameDay(d.date, _selectedDate))
        .firstOrNull;

    // Пустые приёмы (без продукта/блюда) не показываем
    final allMeals = day == null
        ? <PlanMeal>[]
        : provider
        .getMealsForDay(_selectedDate)
        .where((m) => (m.templateId ?? '').isNotEmpty)
        .toList();

    final groupedMeals = <MealType, List<PlanMeal>>{};
    for (final meal in allMeals) {
      groupedMeals.putIfAbsent(meal.mealType, () => []).add(meal);
    }

    final summary = provider.getSummaryForDate(_selectedDate);
    final dayGoals = provider.getGoalsForDate(_selectedDate);
    final completedDays = _countCompletedDays(provider, program, days);

    final overlay = (hasBg && !_pastHero)
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: _hero(
                    context, provider, program, days, completedDays),
              ),
              SliverToBoxAdapter(
                child: _weekStrip(context, program, days),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: _weekOverview(context, provider, days),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: _dayContent(context, provider, program, day,
                    groupedMeals, summary, dayGoals),
              ),
              SliverToBoxAdapter(
                child: _statsAndHeatmap(context, provider, program, days),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        floatingActionButton: _fab(context, provider, program, day),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HERO — во всю ширину, до верхнего края экрана
  // ═══════════════════════════════════════════════════════════════════
  Widget _hero(BuildContext context, NutritionProvider provider,
      NutritionProgram program, List<PlanDay> days, int completed) {
    final total = days.length;
    final pct = total > 0 ? completed / total : 0.0;
    final dayIndex =
    days.indexWhere((d) => _sameDay(d.date, _selectedDate));
    final hasBg = (program.backgroundImage ?? '').isNotEmpty;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _circleBtn(
                Icons.arrow_back_rounded,
                    () => Navigator.pop(context),
                onImage: hasBg),
            const Spacer(),
            Text(
              'ТВОЙ ПЛАН',
              style: _mono(
                  size: 10,
                  weight: FontWeight.w700,
                  color: hasBg
                      ? Colors.white.withOpacity(0.9)
                      : _T.terracotta,
                  letterSpacing: 2.4),
            ),
            const Spacer(),
            _circleBtn(
                Icons.flag_rounded,
                    () => _showProgramOptions(context, provider, program),
                onImage: hasBg),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _weekdayRu(_selectedDate.weekday).toUpperCase(),
                    style: _mono(
                        size: 10,
                        weight: FontWeight.w700,
                        color: hasBg
                            ? Colors.white.withOpacity(0.85)
                            : _T.terracotta,
                        letterSpacing: 2),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_selectedDate.day}',
                        style: _display(
                          size: 56,
                          weight: FontWeight.w600,
                          color: hasBg ? Colors.white : _T.ink,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _monthRu(_selectedDate.month),
                          style: _display(
                            size: 22,
                            weight: FontWeight.w400,
                            color: hasBg
                                ? Colors.white.withOpacity(0.75)
                                : _T.muted,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    program.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _display(
                      size: 18,
                      weight: FontWeight.w500,
                      color: hasBg
                          ? Colors.white.withOpacity(0.95)
                          : _T.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chipOnImage(
                          '🎯 ${program.targetCalories.round()} ккал',
                          hasBg),
                      if (program.mode == ProgramMode.byMeals)
                        _chipOnImage('🍽 По расписанию', hasBg),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _progressRing(pct, completed, total, hasBg),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: hasBg
                    ? Colors.white.withOpacity(0.2)
                    : _T.border,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'День ${dayIndex + 1} из $total',
                style: _body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: hasBg
                        ? Colors.white.withOpacity(0.95)
                        : _T.inkSoft),
              ),
              const Spacer(),
              Text(
                '${_fmtDate(program.startDate)} — ${_fmtDate(program.endDate)}',
                style: _mono(
                    size: 10,
                    weight: FontWeight.w500,
                    color: hasBg
                        ? Colors.white.withOpacity(0.7)
                        : _T.muted),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      key: _heroKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _T.surfaceAlt,
        image: hasBg
            ? DecorationImage(
          image: AssetImage(program.backgroundImage!),
          fit: BoxFit.cover,
          onError: (_, __) {},
        )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: hasBg
              ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.65),
            ],
          )
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SafeArea(bottom: false, child: content),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap,
      {bool onImage = false}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onImage
              ? Colors.white.withOpacity(0.15)
              : _T.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: onImage
                ? Colors.white.withOpacity(0.3)
                : _T.border,
            width: 1.2,
          ),
        ),
        child: Icon(icon,
            size: 18, color: onImage ? Colors.white : _T.ink),
      ),
    );
  }

  Widget _chipOnImage(String s, bool onImage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.white.withOpacity(0.15)
            : _T.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: onImage
              ? Colors.white.withOpacity(0.3)
              : _T.border,
          width: 1,
        ),
      ),
      child: Text(s,
          style: _body(
              size: 11,
              weight: FontWeight.w600,
              color: onImage ? Colors.white : _T.ink)),
    );
  }

  Widget _progressRing(double pct, int done, int total, bool onImage) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: CircularProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              strokeWidth: 6,
              backgroundColor:
              (onImage ? Colors.white : _T.ink).withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(
                  onImage ? Colors.white : _T.terracotta),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$done',
                style: _display(
                  size: 26,
                  weight: FontWeight.w600,
                  color: onImage ? Colors.white : _T.ink,
                  height: 1,
                ),
              ),
              Text(
                'из $total',
                style: _body(
                  size: 10,
                  weight: FontWeight.w500,
                  color: onImage
                      ? Colors.white.withOpacity(0.7)
                      : _T.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WEEK STRIP
  // ═══════════════════════════════════════════════════════════════════
  Widget _weekStrip(BuildContext context, NutritionProgram program,
      List<PlanDay> days) {
    final today = DateTime.now();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = days[i];
          final isSel = _sameDay(d.date, _selectedDate);
          final isToday = _sameDay(d.date, today);
          final isPast = d.date.isBefore(today) && !isToday;
          final summary =
          context.read<NutritionProvider>().getSummaryForDate(d.date);
          final goal = d.targetCalories ?? program.targetCalories;
          final hit = goal > 0 &&
              summary.calories >= goal * 0.85 &&
              summary.calories <= goal * 1.15;
          final isCheat = d.dayType == PlanDayType.cheat;
          final isVac = d.dayType == PlanDayType.vacation;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDate = d.date);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSel ? 60 : 54,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? _T.terracotta : _T.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSel
                      ? _T.terracotta
                      : (isToday
                      ? _T.terracotta.withOpacity(0.4)
                      : _T.border),
                  width: 1,
                ),
              ),
              child: Opacity(
                opacity: (isPast || (d.date.isAfter(today) && !isSel))
                    ? 0.6
                    : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weekShort(d.date.weekday),
                      style: _mono(
                        size: 9,
                        weight: FontWeight.w700,
                        color: isSel
                            ? Colors.white.withOpacity(0.85)
                            : _T.muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${d.date.day}',
                      style: _display(
                        size: 18,
                        weight: FontWeight.w600,
                        color: isSel ? Colors.white : _T.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 14,
                      child: isCheat
                          ? const Text('🍕',
                          style: TextStyle(fontSize: 11))
                          : isVac
                          ? const Text('🏖',
                          style: TextStyle(fontSize: 11))
                          : (isPast && hit)
                          ? Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: isSel
                            ? Colors.white
                            : _T.sage,
                      )
                          : Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSel
                              ? Colors.white.withOpacity(0.5)
                              : _T.faint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WEEK OVERVIEW — общая статистика за неделю + разбор
  // ═══════════════════════════════════════════════════════════════════
  DateTime _donly(DateTime d) => DateTime(d.year, d.month, d.day);

  // -1 = недобор, 0 = в норме, 1 = перебор
  int _statusOf(double actual, double goal, double tol) {
    if (goal <= 0) return 0;
    if (actual < goal * (1 - tol)) return -1;
    if (actual > goal * (1 + tol)) return 1;
    return 0;
  }

  Color _statusColor(int s) =>
      s == 0 ? _T.sage : (s < 0 ? _T.sky : _T.terracotta);

  _WeekStats _computeWeekStats(
      NutritionProvider p, List<PlanDay> days) {
    final today = _donly(DateTime.now());
    final sel = _donly(_selectedDate);
    final weekStart = sel.subtract(Duration(days: sel.weekday - 1));

    final byDate = <DateTime, PlanDay>{};
    for (final d in days) {
      byDate[_donly(d.date)] = d;
    }

    final week = <_WeekDayStat>[];
    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final planDay = byDate[date];
      final isFuture = date.isAfter(today);
      final s = p.getSummaryForDate(date);
      final g = p.getGoalsForDate(date);
      final hasData = s.calories > 0 || s.waterMl > 0;
      final counts = planDay != null &&
          planDay.dayType.countsForStats &&
          !isFuture;
      week.add(_WeekDayStat(
        date: date,
        planDay: planDay,
        isFuture: isFuture,
        hasData: hasData,
        counts: counts,
        calories: s.calories,
        protein: s.protein,
        fat: s.fat,
        carbs: s.carbs,
        waterMl: s.waterMl.toDouble(),
        goalCalories: g.calories,
        goalProtein: g.protein,
        goalFat: g.fat,
        goalCarbs: g.carbs,
        goalWaterMl: g.waterMl.toDouble(),
      ));
    }

    final counted = week.where((d) => d.counts).toList();
    final tracked = counted.where((d) => d.hasData).toList();
    final n = tracked.length;

    double sum(Iterable<double> v) => v.fold(0.0, (a, b) => a + b);
    double avg(Iterable<double> v) => n == 0 ? 0.0 : sum(v) / n;

    // Цели усредняем по прошедшим дням программы (даже если нет записей)
    final goalDays = counted.isNotEmpty
        ? counted
        : week.where((d) => d.planDay != null).toList();
    final gn = goalDays.length;
    final fallback = p.getGoalsForDate(_selectedDate);
    double gAvg(Iterable<double> v, double fb) =>
        gn == 0 ? fb : sum(v) / gn;

    int hit = 0, over = 0, under = 0;
    for (final d in tracked) {
      final st = _statusOf(d.calories, d.goalCalories, _kcalTol);
      if (st == 0) hit++;
      if (st == 1) over++;
      if (st == -1) under++;
    }

    return _WeekStats(
      start: weekStart,
      end: weekStart.add(const Duration(days: 6)),
      week: week,
      elapsed: counted.length,
      tracked: n,
      missed: counted.length - n,
      hitDays: hit,
      overDays: over,
      underDays: under,
      avgCalories: avg(tracked.map((d) => d.calories)),
      avgProtein: avg(tracked.map((d) => d.protein)),
      avgFat: avg(tracked.map((d) => d.fat)),
      avgCarbs: avg(tracked.map((d) => d.carbs)),
      avgWater: avg(tracked.map((d) => d.waterMl)),
      goalCalories: gAvg(
          goalDays.map((d) => d.goalCalories), fallback.calories),
      goalProtein: gAvg(
          goalDays.map((d) => d.goalProtein), fallback.protein),
      goalFat:
      gAvg(goalDays.map((d) => d.goalFat), fallback.fat),
      goalCarbs: gAvg(
          goalDays.map((d) => d.goalCarbs), fallback.carbs),
      goalWater: gAvg(
          goalDays.map((d) => d.goalWaterMl),
          fallback.waterMl.toDouble()),
    );
  }

  Widget _weekOverview(BuildContext context,
      NutritionProvider provider, List<PlanDay> days) {
    final stats = _computeWeekStats(provider, days);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ОБЗОР НЕДЕЛИ',
                  style: _mono(
                      size: 11,
                      weight: FontWeight.w700,
                      color: _T.inkSoft,
                      letterSpacing: 1.8)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _T.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _T.border),
                ),
                child: Text(
                  '${stats.start.day} ${_monthRu(stats.start.month)} — ${stats.end.day} ${_monthRu(stats.end.month)}',
                  style: _mono(size: 10, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _weekSummaryCard(stats),
          const SizedBox(height: 14),
          _weekMacroCard(stats),
          const SizedBox(height: 14),
          _weekInsightsCard(stats),
        ],
      ),
    );
  }

  // ─── Карточка: средние ккал + график недели ───
  Widget _weekSummaryCard(_WeekStats s) {
    final status =
    _statusOf(s.avgCalories, s.goalCalories, _kcalTol);
    final color = _statusColor(status);
    final diff = (s.avgCalories - s.goalCalories).round();
    final pct = s.goalCalories > 0
        ? ((s.avgCalories - s.goalCalories) /
        s.goalCalories *
        100)
        .round()
        : 0;
    final label = s.tracked == 0
        ? 'НЕТ ДАННЫХ'
        : (status == 0
        ? 'В НОРМЕ'
        : (status < 0 ? 'НЕДОБОР' : 'ПЕРЕБОР'));
    final advice = s.tracked == 0
        ? 'Пока нет записей за эту неделю'
        : status == 0
        ? 'Держишь баланс — отклонение в пределах ±15%'
        : status < 0
        ? 'Недобор ≈ ${diff.abs()} ккал/день — можно добавить перекус'
        : 'Перебор ≈ ${diff.abs()} ккал/день — постарайся полегче';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('СРЕДНЕЕ ЗА ДЕНЬ',
                  style: _mono(
                      size: 10,
                      weight: FontWeight.w700,
                      letterSpacing: 1.8)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label,
                    style: _mono(
                        size: 10,
                        weight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${s.avgCalories.round()}',
                  style: _display(
                      size: 40, weight: FontWeight.w600, height: 1)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ ${s.goalCalories.round()} ккал',
                    style:
                    _body(size: 13, color: _T.muted)),
              ),
              const Spacer(),
              if (s.tracked > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${pct > 0 ? "+" : ""}$pct%',
                    style: _mono(
                        size: 13,
                        weight: FontWeight.w700,
                        color: color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(advice, style: _body(size: 13, color: _T.inkSoft)),
          const SizedBox(height: 4),
          Text(
            'за ${s.tracked} ${_plural(s.tracked, "день", "дня", "дней")} с записями · допуск ±15%',
            style: _mono(size: 10, color: _T.muted),
          ),
          const SizedBox(height: 18),
          _weekBarChart(s.week),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _miniStat('${s.hitDays}', 'в цели',
                      _T.sage, _T.sageLight)),
              const SizedBox(width: 10),
              Expanded(
                  child: _miniStat('${s.overDays}', 'перебор',
                      _T.terracotta, _T.terracottaLight)),
              const SizedBox(width: 10),
              Expanded(
                  child: _miniStat('${s.underDays}', 'недобор',
                      _T.sky, _T.skyLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
      String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: _display(
                  size: 20,
                  weight: FontWeight.w600,
                  color: color,
                  height: 1)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: _mono(
                  size: 8,
                  weight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  // ─── График Пн–Вс с линией цели ───
  Widget _weekBarChart(List<_WeekDayStat> week) {
    const maxH = 72.0;
    const cap = 1.3; // 130% цели = полный столбец
    const labelZone = 24.0;
    final goalY = labelZone + maxH / cap;

    return SizedBox(
      height: maxH + labelZone,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: goalY,
            child: Container(height: 1, color: _T.borderStrong),
          ),
          Positioned(
            right: 0,
            bottom: goalY + 3,
            child: Text('цель',
                style: _mono(
                    size: 8, color: _T.faint, letterSpacing: 0.8)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: week
                .map((d) =>
                Expanded(child: _weekBarColumn(d, maxH, cap)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _weekBarColumn(_WeekDayStat d, double maxH, double cap) {
    final ratio =
    d.goalCalories > 0 ? d.calories / d.goalCalories : 0.0;
    final hasBar = d.planDay != null && !d.isFuture && d.hasData;
    double h = 4;
    if (hasBar) {
      final r = ratio < 0 ? 0.0 : (ratio > cap ? cap : ratio);
      h = r / cap * maxH;
      if (h < 4) h = 4;
    }
    Color c;
    if (!hasBar) {
      c = _T.surfaceAlt;
    } else if (!d.counts) {
      c = _T.mustard.withOpacity(0.45); // чит/отпуск — не в счёт
    } else {
      c = _statusColor(
          _statusOf(d.calories, d.goalCalories, _kcalTol));
    }
    final isToday = _sameDay(d.date, DateTime.now());
    final isSel = _sameDay(d.date, _selectedDate);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: d.planDay == null
          ? null
          : () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDate = d.date);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: maxH,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 18,
                height: h,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 18,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSel ? _T.terracotta : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _weekShort(d.date.weekday),
                  style: _mono(
                    size: 9,
                    weight: FontWeight.w700,
                    color: isSel
                        ? Colors.white
                        : (isToday ? _T.terracotta : _T.muted),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Карточка: средние БЖУ и вода ───
  Widget _weekMacroCard(_WeekStats s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('БЖУ И ВОДА · СРЕДНЕЕ/ДЕНЬ',
                  style: _mono(
                      size: 10,
                      weight: FontWeight.w700,
                      letterSpacing: 1.6)),
              const Spacer(),
              Text('люфт ±10%',
                  style: _mono(size: 9, color: _T.muted)),
            ],
          ),
          const SizedBox(height: 16),
          _weekMacroRow(
              'Белки', s.avgProtein, s.goalProtein, _T.sage, 'г'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _T.border),
          ),
          _weekMacroRow(
              'Жиры', s.avgFat, s.goalFat, _T.mustard, 'г'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _T.border),
          ),
          _weekMacroRow(
              'Углеводы', s.avgCarbs, s.goalCarbs, _T.sky, 'г'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _T.border),
          ),
          _weekMacroRow(
              'Вода', s.avgWater, s.goalWater, _T.sky, 'мл'),
        ],
      ),
    );
  }

  Widget _weekMacroRow(String label, double avg, double goal,
      Color color, String unit) {
    final status = _statusOf(avg, goal, _macroTol);
    final sc = _statusColor(status);
    final pct = goal > 0
        ? ((avg - goal) / goal * 100).round()
        : 0;
    final diff = (avg - goal).abs().round();
    final progress =
    goal > 0 ? (avg / goal).clamp(0.0, 1.0) : 0.0;
    final badge =
    status == 0 ? 'норма' : '${pct > 0 ? "+" : ""}$pct%';
    final hint = status == 0
        ? 'в пределах допуска ±10%'
        : status < 0
        ? 'не хватает ≈ $diff $unit/день'
        : 'выше цели на ≈ $diff $unit/день';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: _body(size: 13, weight: FontWeight.w700)),
            const Spacer(),
            Text('${avg.round()} / ${goal.round()} $unit',
                style: _mono(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _T.ink)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge,
                  style: _mono(
                      size: 9,
                      weight: FontWeight.w700,
                      color: sc,
                      letterSpacing: 0.4)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(sc),
          ),
        ),
        const SizedBox(height: 6),
        Text(hint, style: _body(size: 11, color: _T.muted)),
      ],
    );
  }

  // ─── Карточка: понятный разбор недели ───
  Widget _weekInsightsCard(_WeekStats s) {
    final insights = _buildInsights(s);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('РАЗБОР НЕДЕЛИ',
              style: _mono(
                  size: 10,
                  weight: FontWeight.w700,
                  letterSpacing: 1.8)),
          const SizedBox(height: 14),
          ...insights.asMap().entries.map((e) {
            final i = e.key;
            final ins = e.value;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i == insights.length - 1 ? 0 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ins.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(ins.icon, size: 18, color: ins.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ins.title,
                            style: _body(
                                size: 13, weight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(ins.detail,
                            style: _body(
                                size: 12,
                                color: _T.inkSoft,
                                height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<_Insight> _buildInsights(_WeekStats s) {
    final list = <_Insight>[];

    if (s.tracked == 0) {
      list.add(const _Insight(
        Icons.edit_note_rounded,
        _T.sky,
        'Пока нет записей',
        'Отмечай съеденное в приёмах пищи — и здесь появится подробный разбор недели: что в норме, чего не хватает и что в избытке.',
      ));
      return list;
    }

    // Калории
    final kcalStatus =
    _statusOf(s.avgCalories, s.goalCalories, _kcalTol);
    final kcalDiff = (s.avgCalories - s.goalCalories).round();
    final kcalPct = s.goalCalories > 0
        ? ((s.avgCalories - s.goalCalories) /
        s.goalCalories *
        100)
        .round()
        : 0;
    if (kcalStatus == 1) {
      list.add(_Insight(
        Icons.trending_up_rounded,
        _T.terracotta,
        'Калории: перебор +${kcalPct.abs()}%',
        'В среднем +${kcalDiff.abs()} ккал/день сверх цели. За неделю набежало ≈ ${(kcalDiff * s.tracked).abs()} ккал. Уменьши порции или замени калорийные перекусы на более лёгкие.',
      ));
    } else if (kcalStatus == -1) {
      list.add(_Insight(
        Icons.trending_down_rounded,
        _T.sky,
        'Калории: недобор −${kcalPct.abs()}%',
        'Не хватает ≈ ${kcalDiff.abs()} ккал/день. Добавь лёгкий перекус: йогурт, орехи, фрукт — или немного увеличь основные порции.',
      ));
    }

    // Белок
    final pStatus =
    _statusOf(s.avgProtein, s.goalProtein, _macroTol);
    final pDiff = (s.avgProtein - s.goalProtein).round();
    if (pStatus == -1) {
      list.add(_Insight(
        Icons.eco_rounded,
        _T.sage,
        'Белок: недобор',
        'Не хватает ≈ ${pDiff.abs()} г/день. Добавь творог, яйца, курицу, рыбу или бобовые — белок помогает дольше оставаться сытым.',
      ));
    } else if (pStatus == 1) {
      list.add(_Insight(
        Icons.eco_rounded,
        _T.sage,
        'Белок: выше цели',
        '+${pDiff.abs()} г/день. Обычно это не страшно, но учитывай белок в общей калорийности дня.',
      ));
    }

    // Жиры
    final fStatus = _statusOf(s.avgFat, s.goalFat, _macroTol);
    final fDiff = (s.avgFat - s.goalFat).round();
    if (fStatus == 1) {
      list.add(_Insight(
        Icons.opacity_rounded,
        _T.mustard,
        'Жиры: перебор',
        'Лишние ≈ ${fDiff.abs()} г/день. Чаще всего виноваты масло, соусы, орехи и сыр — попробуй немного уменьшить их.',
      ));
    } else if (fStatus == -1) {
      list.add(_Insight(
        Icons.opacity_rounded,
        _T.mustard,
        'Жиры: недобор',
        'Не хватает ≈ ${fDiff.abs()} г/день. Добавь оливковое масло, авокадо, орехи или жирную рыбу — жиры важны для гормонов и сытости.',
      ));
    }

    // Углеводы
    final cStatus =
    _statusOf(s.avgCarbs, s.goalCarbs, _macroTol);
    final cDiff = (s.avgCarbs - s.goalCarbs).round();
    if (cStatus == 1) {
      list.add(_Insight(
        Icons.grain_rounded,
        _T.sky,
        'Углеводы: перебор',
        '+${cDiff.abs()} г/день. Проверь сладкое, выпечку и соусы — часть можно заменить на крупы, овощи и фрукты.',
      ));
    } else if (cStatus == -1) {
      list.add(_Insight(
        Icons.grain_rounded,
        _T.sky,
        'Углеводы: недобор',
        'Не хватает ≈ ${cDiff.abs()} г/день. Добавь крупы, цельнозерновой хлеб, фрукты — будет больше энергии на день.',
      ));
    }

    // Вода
    final wStatus = _statusOf(s.avgWater, s.goalWater, _macroTol);
    if (wStatus == -1) {
      final wDiff = (s.goalWater - s.avgWater).round();
      list.add(_Insight(
        Icons.water_drop_rounded,
        _T.sky,
        'Вода: недобор',
        'В среднем ${s.avgWater.round()} мл из ${s.goalWater.round()} мл. Не хватает ≈ $wDiff мл — это 1–2 стакана в день. Поставь бутылку воды на видное место.',
      ));
    }

    // Дни без записей
    if (s.missed > 0) {
      list.add(_Insight(
        Icons.event_busy_rounded,
        _T.mustard,
        'Без записей: ${s.missed} ${_plural(s.missed, "день", "дня", "дней")}',
        'Статистика считается только по дням с записями. Отмечай приёмы пищи каждый день, чтобы разбор был точнее.',
      ));
    }

    if (list.isEmpty) {
      list.add(const _Insight(
        Icons.emoji_events_rounded,
        _T.sage,
        'Отличная неделя!',
        'Все метрики в пределах допуска: калории ±15%, БЖУ и вода ±10%. Баланс на месте — так держать.',
      ));
    }

    return list;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DAY CONTENT
  // ═══════════════════════════════════════════════════════════════════
  Widget _dayContent(
      BuildContext context,
      NutritionProvider provider,
      NutritionProgram program,
      PlanDay? day,
      Map<MealType, List<PlanMeal>> groupedMeals,
      DailyNutritionSummary summary,
      NutritionGoals dayGoals,
      ) {
    if (day == null) return const SizedBox.shrink();
    final isPast =
    day.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    final sortedTypes =
    MealType.values.where((t) => groupedMeals.containsKey(t)).toList();
    final hasMeals = groupedMeals.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ОБЗОР ДНЯ',
                  style: _mono(
                      size: 11,
                      weight: FontWeight.w700,
                      color: _T.inkSoft,
                      letterSpacing: 1.8)),
              const Spacer(),
              if (!isPast) _dayTypeChip(provider, day),
            ],
          ),
          const SizedBox(height: 12),
          _balanceCard(summary, dayGoals),
          const SizedBox(height: 24),
          if (hasMeals)
            ...sortedTypes.map((type) => _groupedMealCard(
                context, provider, type, groupedMeals[type]!, isPast))
          else if (program.mode == ProgramMode.byMeals)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'На этот день пока ничего не запланировано',
                style: _body(size: 13, color: _T.muted),
              ),
            ),
          if (!isPast) ...[
            const SizedBox(height: 4),
            _addMealTypeButton(context, provider, groupedMeals),
          ],
          const SizedBox(height: 20),
          _waterCard(context, provider, summary, dayGoals),
        ],
      ),
    );
  }

  // ─── Balance card ───
  Widget _balanceCard(DailyNutritionSummary summary, NutritionGoals goals) {
    final diffKcal = goals.calories - summary.calories;
    final isOver = diffKcal < -50;
    final isUnder = diffKcal > 50;
    final isOnTrack = !isOver && !isUnder;
    Color statusColor = isOnTrack
        ? _T.sage
        : (isUnder ? _T.sky : _T.terracotta);
    String statusText = isOnTrack
        ? 'В цели'
        : (isUnder ? 'Недобор' : 'Перебор');
    String advice = isOnTrack
        ? 'Отлично держишь баланс'
        : (isUnder
        ? 'Можно добавить лёгкий перекус'
        : 'Завтра постарайся полегче');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('СЪЕДЕНО',
                  style: _mono(
                      size: 10,
                      weight: FontWeight.w700,
                      letterSpacing: 1.8)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusText,
                    style: _mono(
                        size: 10,
                        weight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${summary.calories.round()}',
                style: _display(
                    size: 46, weight: FontWeight.w600, height: 1),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ ${goals.calories.round()} ккал',
                  style: _body(
                      size: 14,
                      weight: FontWeight.w500,
                      color: _T.muted),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${diffKcal > 0 ? "+" : ""}${diffKcal.abs().round()}',
                  style: _mono(
                      size: 14,
                      weight: FontWeight.w700,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(advice,
              style: _body(size: 13, color: _T.inkSoft)),
          const SizedBox(height: 20),
          const Divider(height: 1, color: _T.border),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _macroBar('Белки', summary.protein,
                      goals.protein, _T.sage, 'г')),
              const SizedBox(width: 12),
              Expanded(
                  child: _macroBar('Жиры', summary.fat, goals.fat,
                      _T.mustard, 'г')),
              const SizedBox(width: 12),
              Expanded(
                  child: _macroBar('Углев.', summary.carbs,
                      goals.carbs, _T.sky, 'г')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroBar(
      String label, double actual, double target, Color color, String unit) {
    final pct = target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            _body(size: 11, weight: FontWeight.w600, color: _T.inkSoft)),
        const SizedBox(height: 4),
        Text('${actual.round()}/${target.round()}$unit',
            style: _mono(size: 11, weight: FontWeight.w700, color: _T.ink)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _dayTypeChip(NutritionProvider provider, PlanDay day) {
    return PopupMenuButton<PlanDayType>(
      initialValue: day.dayType,
      color: _T.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      onSelected: (t) {
        HapticFeedback.selectionClick();
        provider.setPlanDayType(day.id, t);
      },
      itemBuilder: (_) => PlanDayType.values
          .map((t) => PopupMenuItem(
        value: t,
        child: Row(
          children: [
            if (t.emoji.isNotEmpty) ...[
              Text(t.emoji),
              const SizedBox(width: 8),
            ],
            Text(t.label,
                style: _body(
                    size: 14, weight: FontWeight.w600)),
          ],
        ),
      ))
          .toList(),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: day.dayType == PlanDayType.regular
              ? _T.surface
              : _T.mustardLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: day.dayType == PlanDayType.regular
                ? _T.border
                : _T.mustard.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (day.dayType.emoji.isNotEmpty) ...[
              Text(day.dayType.emoji,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
            ],
            Text(
              day.dayType.label,
              style: _body(
                size: 11,
                weight: FontWeight.w600,
                color: day.dayType == PlanDayType.regular
                    ? _T.muted
                    : _T.mustard,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.expand_more_rounded,
                size: 14, color: _T.muted),
          ],
        ),
      ),
    );
  }

  // ─── Add meal type ───
  Widget _addMealTypeButton(BuildContext context,
      NutritionProvider provider, Map<MealType, List<PlanMeal>> groupedMeals) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAddMealTypeSheet(
            context, provider, groupedMeals.keys.toSet()),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('Добавить приём пищи',
            style: _body(size: 13, weight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _T.ink,
          side: const BorderSide(color: _T.borderStrong, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddMealTypeSheet(BuildContext context,
      NutritionProvider provider, Set<MealType> present) async {
    final available =
    MealType.values.where((t) => !present.contains(t)).toList();

    if (available.isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _T.surface,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Все приёмы добавлены',
              style: _display(size: 20, weight: FontWeight.w600)),
          content: Text(
            'В этот день уже есть все типы приёмов пищи. Добавь позиции через «+» в нужном приёме.',
            style: _body(size: 14, color: _T.inkSoft),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ОК',
                  style: _body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: _T.terracotta)),
            ),
          ],
        ),
      );
      return;
    }

    final type = await showModalBottomSheet<MealType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: _T.bg,
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _T.faint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Добавить приём пищи',
                  style: _display(size: 24, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Выбери тип — затем добавишь позиции',
                  style: _body(size: 13, color: _T.muted)),
              const SizedBox(height: 20),
              ...available.map(
                    (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(ctx, t),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _T.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _T.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _T.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(t.emoji,
                                style: const TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(t.displayName,
                                style: _body(
                                    size: 15, weight: FontWeight.w700)),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: _T.faint),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (type != null && mounted) {
      HapticFeedback.selectionClick();
      await _showAddFoodSheet(context, provider, _selectedDate, type);
    }
  }

  // ─── Meal group card ───
  Widget _groupedMealCard(BuildContext context,
      NutritionProvider provider, MealType type, List<PlanMeal> meals,
      bool isPast) {
    double groupActualKcal = 0;
    double groupTargetKcal = 0;
    for (final m in meals) {
      final entries = provider
          .getEntriesForDate(_selectedDate)
          .where((e) =>
      e.mealType == m.mealType && e.templateId == m.templateId)
          .toList();
      groupActualKcal +=
          entries.fold<double>(0, (s, e) => s + e.calories);
      groupTargetKcal += (m.targetCalories ?? 0);
    }
    final pct = groupTargetKcal > 0
        ? (groupActualKcal / groupTargetKcal).clamp(0.0, 1.2)
        : 0.0;
    final allCompleted = meals.every((m) => m.isCompleted);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
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
                  color: allCompleted
                      ? _T.sageLight
                      : _T.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(type.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.displayName,
                        style:
                        _display(size: 18, weight: FontWeight.w600)),
                    Text(
                      '${meals.length} ${_plural(meals.length, "позиция", "позиции", "позиций")}',
                      style: _body(size: 11, color: _T.muted),
                    ),
                  ],
                ),
              ),
              if (!isPast)
                GestureDetector(
                  onTap: () => _showAddFoodSheet(
                      context, provider, _selectedDate, type),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _T.terracottaLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded,
                        size: 18, color: _T.terracotta),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...meals.asMap().entries.map((entry) {
            final index = entry.key;
            final meal = entry.value;
            final isLast = index == meals.length - 1;
            return _mealItemRow(context, provider, meal, isLast, isPast);
          }),
          if (groupTargetKcal > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: _T.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation(
                        pct >= 0.85 && pct <= 1.15
                            ? _T.sage
                            : _T.sky,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${groupActualKcal.round()} / ${groupTargetKcal.round()}',
                  style: _mono(
                      size: 10,
                      weight: FontWeight.w700,
                      color: _T.inkSoft),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _mealItemRow(BuildContext context, NutritionProvider provider,
      PlanMeal meal, bool isLast, bool isPast) {
    final isProduct = meal.templateId?.startsWith('PROD:') ?? false;
    final cleanId = isProduct
        ? meal.templateId!.replaceFirst('PROD:', '')
        : meal.templateId;

    final template = !isProduct && cleanId != null
        ? provider.templates.where((t) => t.id == cleanId).firstOrNull
        : null;
    final product = isProduct && cleanId != null
        ? provider.products.where((p) => p.id == cleanId).firstOrNull
        : null;

    final displayName = template?.name ?? product?.name ?? 'Неизвестно';
    final kcal = (template?.caloriesPerPortion ?? product?.calories ?? 0) *
        (meal.portions ?? 1.0);

    final isEaten = meal.isCompleted && meal.note != 'Пропущено';
    final isSkipped = meal.note == 'Пропущено';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: !isLast
          ? const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: _T.border, width: 1)))
          : null,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _T.surfaceAlt,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(
              isProduct
                  ? Icons.apple_rounded
                  : Icons.restaurant_menu_rounded,
              size: 16,
              color: isEaten ? _T.sage : _T.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: _body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: isSkipped ? _T.faint : _T.ink,
                    height: 1.25,
                  ).copyWith(
                    decoration:
                    isSkipped ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                if (isSkipped)
                  Text('Пропущено',
                      style: _body(
                          size: 11,
                          weight: FontWeight.w600,
                          color: _T.rose))
                else
                  Row(
                    children: [
                      Text('${kcal.round()} ккал',
                          style: _mono(
                              size: 11, weight: FontWeight.w500)),
                      if ((meal.portions ?? 1.0) != 1.0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _T.skyLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isProduct
                                ? '${((meal.portions ?? 1.0) * 100).round()} г'
                                : '${meal.portions}x',
                            style: _mono(
                                size: 9,
                                weight: FontWeight.w700,
                                color: _T.sky),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          if (!isPast) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded,
                  color: _T.muted, size: 20),
              color: _T.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              itemBuilder: (ctx) => [
                if (!isEaten && !isSkipped)
                  PopupMenuItem(
                    value: 'eat',
                    child: _popupRow(Icons.check_circle_outline_rounded,
                        _T.sage, 'Съел'),
                  ),
                if (!isEaten && !isSkipped)
                  PopupMenuItem(
                    value: 'skip',
                    child: _popupRow(Icons.block_outlined,
                        _T.mustard, 'Пропустить'),
                  ),
                if (!isSkipped)
                  PopupMenuItem(
                    value: 'replace',
                    child: _popupRow(Icons.swap_horiz_rounded,
                        _T.sky, 'Заменить'),
                  ),
                const PopupMenuDivider(height: 1),
                PopupMenuItem(
                  value: 'delete',
                  child: _popupRow(Icons.delete_outline_rounded,
                      _T.rose, 'Удалить'),
                ),
              ],
              onSelected: (value) async {
                HapticFeedback.selectionClick();
                if (value == 'eat') {
                  await provider.markMealAsCompleted(meal.id,
                      portions: meal.portions ?? 1.0,
                      date: _selectedDate);
                } else if (value == 'skip') {
                  await provider.skipMeal(meal.id);
                } else if (value == 'replace') {
                  _showReplaceFoodSheet(context, provider, meal);
                } else if (value == 'delete') {
                  await provider.removeMealItem(meal.id);
                }
              },
            ),
            const SizedBox(width: 4),
            _checkButton(isEaten, isSkipped, () async {
              if (isEaten) {
                await provider.unmarkMealAsCompleted(meal.id);
              } else if (!isSkipped) {
                await provider.markMealAsCompleted(meal.id,
                    portions: meal.portions ?? 1.0, date: _selectedDate);
              }
              HapticFeedback.lightImpact();
            }),
          ] else ...[
            if (isEaten)
              const Icon(Icons.check_circle_rounded,
                  size: 22, color: _T.sage)
            else if (isSkipped)
              const Icon(Icons.block_rounded,
                  size: 22, color: _T.mustard),
          ],
        ],
      ),
    );
  }

  Widget _popupRow(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(label,
            style: _body(size: 14, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _checkButton(
      bool isEaten, bool isSkipped, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isEaten
              ? _T.sage
              : (isSkipped ? _T.mustardLight : _T.surfaceAlt),
          shape: BoxShape.circle,
          border: Border.all(
            color: isEaten
                ? _T.sage
                : (isSkipped ? _T.mustard : _T.border),
            width: 1.2,
          ),
        ),
        child: Icon(
          isEaten
              ? Icons.check_rounded
              : (isSkipped ? Icons.block_rounded : Icons.add_rounded),
          size: 18,
          color: isEaten
              ? Colors.white
              : (isSkipped ? _T.mustard : _T.muted),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  REPLACE / ADD — вся база + настройка порций/граммов/ингредиентов
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _showReplaceFoodSheet(BuildContext context,
      NutritionProvider provider, PlanMeal mealToReplace) async {
    final pick = await showModalBottomSheet<_FoodConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FoodLibrarySheet(
        provider: provider,
        title: 'На что заменить?',
        subtitle: 'Вся база рецептов и продуктов',
        allowConfig: false,
      ),
    );
    if (pick != null && mounted) {
      await provider.replaceMealItem(mealToReplace.id, pick.templateId);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _showAddFoodSheet(BuildContext context,
      NutritionProvider provider, DateTime date, MealType type) async {
    final pick = await showModalBottomSheet<_FoodConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FoodLibrarySheet(
        provider: provider,
        title: 'Добавить в приём',
        subtitle: '${type.emoji} ${type.displayName}',
        allowConfig: true,
      ),
    );
    if (pick != null && mounted) {
      await provider.addToPlan(
        date: date,
        mealType: type,
        templateId: pick.templateId,
        portions: pick.isProduct ? pick.grams / 100.0 : pick.portions,
      );
      HapticFeedback.mediumImpact();
    }
  }

  // ─── Water ───
  Widget _waterCard(BuildContext context, NutritionProvider provider,
      DailyNutritionSummary s, NutritionGoals g) {
    final pct = g.waterMl > 0 ? (s.waterMl / g.waterMl).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.skyLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ВОДА',
                  style: _mono(
                      size: 10,
                      weight: FontWeight.w700,
                      color: _T.sky,
                      letterSpacing: 1.8)),
              const Spacer(),
              Text(
                '${s.waterMl} / ${g.waterMl} мл',
                style: _display(
                    size: 16, weight: FontWeight.w600, color: _T.sky),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: _T.sky.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(_T.sky),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _waterBtn('+250 мл', 250, provider)),
              const SizedBox(width: 10),
              Expanded(child: _waterBtn('+500 мл', 500, provider)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _waterBtn(String label, int ml, NutritionProvider provider) {
    return GestureDetector(
      onTap: () async {
        await provider.addWater(ml, date: _selectedDate);
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: _body(
                size: 13, weight: FontWeight.w700, color: _T.sky)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  STATS + HEATMAP
  // ═══════════════════════════════════════════════════════════════════
  Widget _statsAndHeatmap(BuildContext context,
      NutritionProvider provider, NutritionProgram program,
      List<PlanDay> days) {
    final streak = _calcStreak(provider, days, program);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statPill('🔥', '$streak', 'дней подряд'),
              const SizedBox(width: 12),
              _statPill('📊', '${days.length}', 'дней в плане'),
            ],
          ),
          const SizedBox(height: 24),
          Text('АКТИВНОСТЬ · 30 ДНЕЙ',
              style: _mono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: _T.inkSoft,
                  letterSpacing: 1.8)),
          const SizedBox(height: 12),
          _heatmap(provider, program),
        ],
      ),
    );
  }

  Widget _statPill(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _T.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: _display(
                        size: 22, weight: FontWeight.w600, height: 1)),
                Text(label,
                    style:
                    _body(size: 11, color: _T.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heatmap(NutritionProvider provider, NutritionProgram program) {
    final days = List.generate(30, (i) {
      final d = DateTime.now().subtract(Duration(days: 29 - i));
      final s = provider.getSummaryForDate(d);
      final goal = provider.getGoalsForDate(d).calories;
      double ratio = goal > 0 ? s.calories / goal : 0;
      if (s.calories == 0) ratio = -1;
      return ratio;
    });
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: days.map((r) {
          Color c;
          if (r < 0) {
            c = _T.surfaceAlt;
          } else if (r < 0.6) {
            c = _T.rose.withOpacity(0.25);
          } else if (r < 0.85) {
            c = _T.mustard.withOpacity(0.35);
          } else if (r <= 1.15) {
            c = _T.sage.withOpacity(0.5);
          } else {
            c = _T.terracotta.withOpacity(0.35);
          }
          return Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FAB
  // ═══════════════════════════════════════════════════════════════════
  Widget _fab(BuildContext context, NutritionProvider provider,
      NutritionProgram program, PlanDay? day) {
    if (day == null || day.date.isAfter(DateTime.now())) {
      return const SizedBox.shrink();
    }
    return FloatingActionButton(
      onPressed: () =>
          _showAddFoodSheet(context, provider, _selectedDate, MealType.other),
      backgroundColor: _T.terracotta,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.add_rounded, size: 26),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════════════
  void _showProgramOptions(BuildContext context,
      NutritionProvider provider, NutritionProgram program) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _T.faint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Управление программой',
                    style: _display(size: 24, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('«${program.name}»',
                    style: _body(size: 14, color: _T.muted)),
                const SizedBox(height: 24),
                _actionOption(
                  Icons.check_circle_rounded,
                  _T.sage,
                  'Завершить программу',
                  'Сохранить в историю как успешную',
                      () {
                    Navigator.pop(ctx);
                    _confirmAndExecute(
                      provider,
                      program.id,
                      'Завершить программу?',
                      'Поздравляем! Программа будет сохранена в истории.',
                      provider.finishProgram,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _actionOption(
                  Icons.cancel_rounded,
                  _T.rose,
                  'Отменить программу',
                  'Прервать прохождение',
                      () {
                    Navigator.pop(ctx);
                    _confirmAndExecute(
                      provider,
                      program.id,
                      'Отменить программу?',
                      'Программа будет деактивирована и перемещена в историю.',
                      provider.cancelProgram,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionOption(IconData icon, Color color, String title,
      String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border),
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
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                      _body(size: 15, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: _body(size: 12, color: _T.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: _T.faint),
          ],
        ),
      ),
    );
  }

  void _confirmAndExecute(NutritionProvider provider, String programId,
      String title, String message,
      Future<void> Function(String) action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _T.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: _display(size: 20, weight: FontWeight.w600)),
        content: Text(message,
            style: _body(size: 14, color: _T.inkSoft)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена',
                style: _body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _T.muted)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await action(programId);
              if (mounted) {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: _T.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Подтвердить',
                style: _body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════
  Widget _emptyState(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _T.bg,
        appBar: AppBar(
          backgroundColor: _T.bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: _T.ink),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: _T.surfaceAlt,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: const Text('📓',
                      style: TextStyle(fontSize: 42)),
                ),
                const SizedBox(height: 28),
                Text('Нет активной программы',
                    style: _display(size: 24, weight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(
                  'Создай план питания, чтобы начать отслеживать свой прогресс',
                  textAlign: TextAlign.center,
                  style: _body(size: 14, color: _T.muted),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _T.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Вернуться к программам',
                      style: _body(
                          size: 15,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════
  int _countCompletedDays(NutritionProvider p,
      NutritionProgram program, List<PlanDay> days) {
    int count = 0;
    for (final d in days) {
      if (!d.dayType.countsForStats) continue;
      final s = p.getSummaryForDate(d.date);
      final goal = d.targetCalories ?? program.targetCalories;
      if (goal > 0 &&
          s.calories >= goal * 0.85 &&
          s.calories <= goal * 1.15) {
        count++;
      }
    }
    return count;
  }

  int _calcStreak(NutritionProvider p, List<PlanDay> days,
      NutritionProgram program) {
    int streak = 0;
    for (int i = days.length - 1; i >= 0; i--) {
      final d = days[i];
      if (d.date.isAfter(DateTime.now())) continue;
      if (!d.dayType.countsForStats) continue;
      final s = p.getSummaryForDate(d.date);
      final goal = d.targetCalories ?? program.targetCalories;
      final hit = goal > 0 &&
          s.calories >= goal * 0.85 &&
          s.calories <= goal * 1.15;
      if (hit) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String _plural(int n, String one, String few, String many) {
    if (n % 10 == 1 && n % 100 != 11) return one;
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return few;
    }
    return many;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekShort(int wd) =>
      const ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'][wd - 1];

  String _weekdayRu(int wd) => const [
    'Понедельник', 'Вторник', 'Среда', 'Четверг',
    'Пятница', 'Суббота', 'Воскресенье'
  ][wd - 1];

  String _monthRu(int m) => const [
    'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
  ][m - 1];

  String _fmtDate(DateTime d) => '${d.day} ${_monthRu(d.month)}';
}

// ═══════════════════════════════════════════════════════════════════
//  WEEK STATS — модели для обзора недели
// ═══════════════════════════════════════════════════════════════════
class _WeekDayStat {
  final DateTime date;
  final PlanDay? planDay;
  final bool isFuture;
  final bool hasData;
  final bool counts;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double waterMl;
  final double goalCalories;
  final double goalProtein;
  final double goalFat;
  final double goalCarbs;
  final double goalWaterMl;

  const _WeekDayStat({
    required this.date,
    required this.planDay,
    required this.isFuture,
    required this.hasData,
    required this.counts,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.waterMl,
    required this.goalCalories,
    required this.goalProtein,
    required this.goalFat,
    required this.goalCarbs,
    required this.goalWaterMl,
  });
}

class _WeekStats {
  final DateTime start;
  final DateTime end;
  final List<_WeekDayStat> week;
  final int elapsed;
  final int tracked;
  final int missed;
  final int hitDays;
  final int overDays;
  final int underDays;
  final double avgCalories;
  final double avgProtein;
  final double avgFat;
  final double avgCarbs;
  final double avgWater;
  final double goalCalories;
  final double goalProtein;
  final double goalFat;
  final double goalCarbs;
  final double goalWater;

  const _WeekStats({
    required this.start,
    required this.end,
    required this.week,
    required this.elapsed,
    required this.tracked,
    required this.missed,
    required this.hitDays,
    required this.overDays,
    required this.underDays,
    required this.avgCalories,
    required this.avgProtein,
    required this.avgFat,
    required this.avgCarbs,
    required this.avgWater,
    required this.goalCalories,
    required this.goalProtein,
    required this.goalFat,
    required this.goalCarbs,
    required this.goalWater,
  });
}

class _Insight {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  const _Insight(this.icon, this.color, this.title, this.detail);
}

// ═══════════════════════════════════════════════════════════════════
//  FOOD CONFIG — выбранная еда с настройками (как в билдере)
// ═══════════════════════════════════════════════════════════════════
class _FoodConfig {
  final bool isProduct;
  final String id;
  final String name;
  final String emoji;
  final double baseCalories;
  final double portions;
  final double grams;

  /// Калории исключённых ингредиентов на 1 порцию рецепта
  final double excludedCaloriesPerPortion;
  final Set<String> excludedIngredientIds;

  _FoodConfig({
    required this.isProduct,
    required this.id,
    required this.name,
    required this.baseCalories,
    String? emoji,
    this.portions = 1.0,
    this.grams = 100.0,
    this.excludedCaloriesPerPortion = 0.0,
    Set<String>? excludedIngredientIds,
  })  : emoji = emoji ?? (isProduct ? '🍎' : '🍱'),
        excludedIngredientIds = excludedIngredientIds ?? {};

  String get templateId => isProduct ? 'PROD:$id' : id;

  double get netCaloriesPerPortion {
    final v = baseCalories - excludedCaloriesPerPortion;
    return v < 0 ? 0 : v;
  }

  double get totalCalories => isProduct
      ? baseCalories * (grams / 100.0)
      : netCaloriesPerPortion * portions;

  _FoodConfig copyWith({
    double? portions,
    double? grams,
    double? excludedCaloriesPerPortion,
    Set<String>? excludedIngredientIds,
  }) {
    return _FoodConfig(
      isProduct: isProduct,
      id: id,
      name: name,
      emoji: emoji,
      baseCalories: baseCalories,
      portions: portions ?? this.portions,
      grams: grams ?? this.grams,
      excludedCaloriesPerPortion:
      excludedCaloriesPerPortion ?? this.excludedCaloriesPerPortion,
      excludedIngredientIds:
      excludedIngredientIds ?? this.excludedIngredientIds,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FOOD LIBRARY SHEET — вся база, поиск, фильтр + конфигуратор
// ═══════════════════════════════════════════════════════════════════
class _FoodLibrarySheet extends StatefulWidget {
  final NutritionProvider provider;
  final String title;
  final String? subtitle;
  final bool allowConfig;

  const _FoodLibrarySheet({
    required this.provider,
    required this.title,
    this.subtitle,
    this.allowConfig = true,
  });

  @override
  State<_FoodLibrarySheet> createState() => _FoodLibrarySheetState();
}

class _FoodLibrarySheetState extends State<_FoodLibrarySheet> {
  final _searchCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController(text: '100');
  String _query = '';
  int _filter = 0; // 0 = все, 1 = рецепты, 2 = продукты
  _FoodConfig? _configuring;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  void _onPick(_FoodConfig food) {
    HapticFeedback.lightImpact();
    if (widget.allowConfig) {
      _gramsCtrl.text = food.grams.toInt().toString();
      setState(() => _configuring = food);
    } else {
      Navigator.pop(context, food);
    }
  }

  // ─── Калорийность ингредиента: ищем продукт по имени ───
  double _itemKcal(dynamic item) {
    final name = (item.name as String).trim().toLowerCase();
    final grams = (item.grams as num).toDouble();
    final product = widget.provider.products
        .where((p) => p.name.trim().toLowerCase() == name)
        .firstOrNull;
    if (product == null) return 0;
    return product.calories * grams / 100.0;
  }

  double _excludedCaloriesFor(_FoodConfig food) {
    if (food.isProduct || food.excludedIngredientIds.isEmpty) return 0;
    final template = widget.provider.templates
        .where((t) => t.id == food.id)
        .firstOrNull;
    if (template == null) return 0;
    double sum = 0;
    for (var i = 0; i < template.items.length; i++) {
      if (food.excludedIngredientIds.contains('idx_$i')) {
        sum += _itemKcal(template.items[i]);
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final templates = widget.provider.templates
        .where((t) => q.isEmpty || t.name.toLowerCase().contains(q))
        .toList();
    final products = widget.provider.products
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
        .toList();

    final showTemplates = _filter != 2 && templates.isNotEmpty;
    final showProducts = _filter != 1 && products.isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isConfig = _configuring != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _T.faint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isConfig ? 'Настройка' : widget.title,
                            style: _display(
                                size: 26, weight: FontWeight.w600)),
                        if (!isConfig && widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(widget.subtitle!,
                              style:
                              _body(size: 13, color: _T.muted)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isConfig)
                    TextButton(
                      onPressed: () =>
                          setState(() => _configuring = null),
                      child: Text('Назад',
                          style: _body(
                              size: 14,
                              weight: FontWeight.w700,
                              color: _T.terracotta)),
                    )
                  else
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _T.surface,
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: _T.border, width: 1.2),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: _T.ink),
                      ),
                    ),
                ],
              ),
            ),
            if (!isConfig) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: _T.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _T.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: _body(size: 14, weight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Найти рецепт или продукт...',
                      hintStyle: _body(size: 14, color: _T.muted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _T.muted, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _filterChip('Все', 0),
                    const SizedBox(width: 8),
                    _filterChip('Рецепты', 1),
                    const SizedBox(width: 8),
                    _filterChip('Продукты', 2),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: isConfig
                  ? _configPanel()
                  : (showTemplates || showProducts)
                  ? ListView(
                padding:
                const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  if (showTemplates) ...[
                    _sectionTag(
                        'РЕЦЕПТЫ · ${templates.length}',
                        _T.sky),
                    const SizedBox(height: 10),
                    ...templates.map(
                          (t) => _tile(
                        emoji: '🍱',
                        name: t.name,
                        subtitle:
                        '${t.caloriesPerPortion.round()} ккал / порция',
                        badge: 'Рецепт',
                        badgeColor: _T.sky,
                        onTap: () => _onPick(_FoodConfig(
                          isProduct: false,
                          id: t.id,
                          name: t.name,
                          baseCalories:
                          t.caloriesPerPortion,
                        )),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  if (showProducts) ...[
                    _sectionTag(
                        'ПРОДУКТЫ · ${products.length}',
                        _T.sage),
                    const SizedBox(height: 10),
                    ...products.map(
                          (p) => _tile(
                        emoji: p.categoryEmoji ?? '🍎',
                        name: p.name,
                        subtitle:
                        '${p.calories.round()} ккал / 100 г',
                        badge: 'Продукт',
                        badgeColor: _T.sage,
                        onTap: () => _onPick(_FoodConfig(
                          isProduct: true,
                          id: p.id,
                          name: p.name,
                          emoji: p.categoryEmoji,
                          baseCalories: p.calories,
                        )),
                      ),
                    ),
                  ],
                ],
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔍',
                        style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 16),
                    Text('Ничего не найдено',
                        style: _body(
                            size: 15,
                            weight: FontWeight.w600,
                            color: _T.muted)),
                    const SizedBox(height: 6),
                    Text('Попробуй другой запрос',
                        style:
                        _body(size: 13, color: _T.faint)),
                  ],
                ),
              ),
            ),
            if (isConfig)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                decoration: const BoxDecoration(
                  color: _T.bg,
                  border: Border(top: BorderSide(color: _T.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context, _configuring);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.terracotta,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Добавить · ${_configuring!.totalCalories.round()} ккал',
                          style: _body(
                              size: 15,
                              weight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(height: bottomInset),
          ],
        ),
      ),
    );
  }

  // ─── Конфигуратор: порции / граммы / ингредиенты ───
  Widget _configPanel() {
    final food = _configuring!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _T.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(food.emoji,
                  style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      style:
                      _display(size: 22, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(food.isProduct ? 'ПРОДУКТ' : 'РЕЦЕПТ',
                      style: _mono(
                          size: 9,
                          weight: FontWeight.w700,
                          letterSpacing: 1.4)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        if (food.isProduct) ...[
          Text('ВЕС',
              style: _mono(
                  size: 10,
                  weight: FontWeight.w700,
                  letterSpacing: 1.8)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: _gramsCtrl,
                    style:
                    _display(size: 32, weight: FontWeight.w600),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '0',
                    ),
                    onChanged: (val) {
                      final grams = double.tryParse(val) ?? 0;
                      if (grams >= 0) {
                        setState(() => _configuring =
                            food.copyWith(grams: grams));
                      }
                    },
                  ),
                ),
                Text('г',
                    style: _body(
                        size: 16,
                        weight: FontWeight.w600,
                        color: _T.muted)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [50, 100, 150, 200, 250, 300]
                .map((g) => _chip('$g г', food.grams == g, () {
              _gramsCtrl.text = '$g';
              setState(() => _configuring =
                  food.copyWith(grams: g.toDouble()));
            }))
                .toList(),
          ),
        ] else ...[
          Text('ПОРЦИИ',
              style: _mono(
                  size: 10,
                  weight: FontWeight.w700,
                  letterSpacing: 1.8)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
                .map((p) => _chip('${p}×', food.portions == p,
                    () => setState(() => _configuring =
                    food.copyWith(portions: p))))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text('ИНГРЕДИЕНТЫ',
              style: _mono(
                  size: 10,
                  weight: FontWeight.w700,
                  letterSpacing: 1.8)),
          const SizedBox(height: 6),
          Text('Нажми, чтобы исключить или вернуть — калории пересчитаются',
              style: _body(size: 12, color: _T.muted)),
          const SizedBox(height: 10),
          ..._ingredientTiles(food),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _T.terracottaLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroStat('Ккал', food.totalCalories.round(),
                  _T.terracotta),
              _macroStat('Б',
                  (food.totalCalories * 0.3 / 4).round(), _T.sage),
              _macroStat('Ж',
                  (food.totalCalories * 0.3 / 9).round(), _T.mustard),
              _macroStat('У',
                  (food.totalCalories * 0.4 / 4).round(), _T.sky),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _ingredientTiles(_FoodConfig food) {
    final template = widget.provider.templates
        .where((t) => t.id == food.id)
        .firstOrNull;
    if (template == null) {
      return [
        Text('Данные рецепта не найдены',
            style: _body(size: 13, color: _T.muted))
      ];
    }
    return template.items.asMap().entries.map((e) {
      final idx = e.key;
      final item = e.value;
      final isExcluded =
      food.excludedIngredientIds.contains('idx_$idx');
      final scaledGrams = item.grams * food.portions;
      final kcal = _itemKcal(item) * food.portions;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            final newExcluded =
            Set<String>.from(food.excludedIngredientIds);
            if (isExcluded) {
              newExcluded.remove('idx_$idx');
            } else {
              newExcluded.add('idx_$idx');
            }
            final updated =
            food.copyWith(excludedIngredientIds: newExcluded);
            setState(() => _configuring = updated.copyWith(
              excludedCaloriesPerPortion:
              _excludedCaloriesFor(updated),
            ));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isExcluded ? _T.roseLight : _T.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExcluded
                    ? _T.rose.withOpacity(0.3)
                    : _T.border,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isExcluded ? _T.rose : _T.sage,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExcluded
                        ? Icons.close_rounded
                        : Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: _body(
                              size: 14,
                              weight: FontWeight.w600,
                              color: isExcluded
                                  ? _T.muted
                                  : _T.ink)
                              .copyWith(
                            decoration: isExcluded
                                ? TextDecoration.lineThrough
                                : null,
                          )),
                      Text(
                        kcal > 0
                            ? '${scaledGrams.toInt()} г · ${kcal.round()} ккал'
                            : '${scaledGrams.toInt()} г',
                        style: _mono(
                            size: 11, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _T.ink : _T.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _T.ink : _T.border,
            width: 1.2,
          ),
        ),
        child: Text(label,
            style: _body(
                size: 13,
                weight: FontWeight.w700,
                color: selected ? Colors.white : _T.ink)),
      ),
    );
  }

  Widget _macroStat(String label, int value, Color color) {
    return Column(
      children: [
        Text('$value',
            style: _display(
                size: 20, weight: FontWeight.w600, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: _mono(
                size: 10, weight: FontWeight.w700, color: _T.inkSoft)),
      ],
    );
  }

  Widget _filterChip(String label, int index) {
    final sel = _filter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filter = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? _T.ink : _T.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? _T.ink : _T.border,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: _body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: sel ? Colors.white : _T.inkSoft)),
        ),
      ),
    );
  }

  Widget _sectionTag(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: _mono(
                size: 11,
                weight: FontWeight.w700,
                color: _T.inkSoft,
                letterSpacing: 1.8)),
      ],
    );
  }

  Widget _tile({
    required String emoji,
    required String name,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _T.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child:
              Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                      _display(size: 16, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                      _mono(size: 11, weight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge,
                  style: _mono(
                      size: 9,
                      weight: FontWeight.w700,
                      color: badgeColor,
                      letterSpacing: 0.8)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: _T.faint),
          ],
        ),
      ),
    );
  }
}