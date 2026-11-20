// features/nutrition/ui/screens/plan_tracker_screen.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zal_life/features/nutrition/ui/screens/plan_builder_screen.dart';
import '../../models/nutrition_models.dart';
import '../../models/nutrition_program.dart';
import '../../providers/nutrition_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Colors.white;
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);
  static const elevated = Color(0xFFF0F1F4);

  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF5A8A73);
  static const skySoft = Color(0xFFE8EFF8);
  static const skyDeep = Color(0xFF6A8AB5);
  static const peachSoft = Color(0xFFFBEDE4);
  static const peachDeep = Color(0xFFE08550);
  static const yellowSoft = Color(0xFFFDF5E6);
  static const yellowDeep = Color(0xFFD0A040);
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF8371AB);
  static const pinkSoft = Color(0xFFFCF0F2);
  static const pinkDeep = Color(0xFFC16A7F);
}

class _Hero {
  static const top = Color(0xFF1B2027);
  static const bottom = Color(0xFF161719);
  static const hi = Colors.white;
  static const lo = Color(0xFFA4A6AA);
}

class PlanTrackerScreen extends StatefulWidget {
  const PlanTrackerScreen({super.key});

  @override
  State<PlanTrackerScreen> createState() => _PlanTrackerScreenState();
}

class _PlanTrackerScreenState extends State<PlanTrackerScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final program = provider.activeProgram;
    if (program == null) return _emptyState(context);

    final days = provider.planDays.where((d) => d.programId == program.id).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final today = _dateOnly(DateTime.now());
    if (days.isNotEmpty) {
      if (_selectedDate.isBefore(days.first.date)) _selectedDate = days.first.date;
      if (_selectedDate.isAfter(days.last.date)) _selectedDate = days.last.date;
    }

    final day = days.where((d) => _sameDay(d.date, _selectedDate)).firstOrNull;

    // 🆕 Получаем все слоты и группируем их по типам (Завтрак, Обед и т.д.)
    final allMeals = day == null ? <PlanMeal>[] : provider.getMealsForDay(_selectedDate);
    final groupedMeals = <MealType, List<PlanMeal>>{};
    for (final meal in allMeals) {
      groupedMeals.putIfAbsent(meal.mealType, () => []).add(meal);
    }

    final summary = provider.getSummaryForDate(_selectedDate);
    final dayGoals = provider.getGoalsForDate(_selectedDate);
    final completedDays = _countCompletedDays(provider, program, days);

    return Scaffold(
      backgroundColor: _P.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _hero(context, provider, program, days, completedDays)),
          SliverToBoxAdapter(child: _weekStrip(context, program, days)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _dayContent(context, provider, program, day, groupedMeals, summary, dayGoals)),
          SliverToBoxAdapter(child: _statsAndHeatmap(context, provider, program, days)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: _fab(context, provider, program, day),
    );
  }

  // ═══════════════ HERO ═══════════════
  Widget _hero(BuildContext context, NutritionProvider provider, NutritionProgram program, List<PlanDay> days, int completed) {
    final total = days.length;
    final pct = total > 0 ? completed / total : 0.0;
    final isFinished = DateTime.now().isAfter(program.endDate);
    final dayIndex = days.indexWhere((d) => _sameDay(d.date, _selectedDate));

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      child: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_Hero.top, _Hero.bottom])),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _iconBtn(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ПРОГРАММА', style: GoogleFonts.inter(color: _Hero.lo, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                          const SizedBox(height: 2),
                          Text(program.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: _Hero.hi, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                        ],
                      ),
                    ),
                    _iconBtn(Icons.settings_rounded, () => _openBuilder(context)),
                    const SizedBox(width: 8),
                    _iconBtn(Icons.flag_rounded, () => _showProgramOptions(context, provider, program)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _bigRing(pct, '$completed', 'из $total'),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isFinished ? 'Программа завершена' : 'День ${dayIndex + 1} из $total', style: GoogleFonts.inter(color: _Hero.hi, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.6)),
                          const SizedBox(height: 6),
                          Text(isFinished ? 'Отличная работа!' : '${_fmtDate(program.startDate)} — ${_fmtDate(program.endDate)}', style: GoogleFonts.inter(color: _Hero.lo, fontSize: 12)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: [
                              _miniChip('🎯 ${program.targetCalories.round()} ккал'),
                              if (program.mode == ProgramMode.byMeals) _miniChip('🍽 По расписанию'),
                            ],
                          ),
                        ],
                      ),
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

  Widget _bigRing(double pct, String big, String small) {
    return SizedBox(
      width: 88, height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 88, height: 88,
            child: CircularProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              strokeWidth: 7,
              backgroundColor: Colors.white.withOpacity(0.10),
              valueColor: const AlwaysStoppedAnimation(_P.greenDeep),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(big, style: GoogleFonts.inter(color: _Hero.hi, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -1, fontFeatures: const [ui.FontFeature.tabularFigures()])),
              Text(small, style: GoogleFonts.inter(color: _Hero.lo, fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withOpacity(0.15))),
    child: Text(s, style: GoogleFonts.inter(color: _Hero.hi, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _iconBtn(IconData i, VoidCallback tap) => GestureDetector(
    onTap: () { HapticFeedback.selectionClick(); tap(); },
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Icon(i, color: Colors.white, size: 16),
    ),
  );

  // ═══════════════ WEEK STRIP ═══════════════
  Widget _weekStrip(BuildContext context, NutritionProgram program, List<PlanDay> days) {
    final today = _dateOnly(DateTime.now());
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final d = days[i];
          final isSel = _sameDay(d.date, _selectedDate);
          final isToday = _sameDay(d.date, today);
          final isPast = d.date.isBefore(today) && !isToday;
          final summary = context.read<NutritionProvider>().getSummaryForDate(d.date);
          final goal = d.targetCalories ?? program.targetCalories;
          final hit = goal > 0 && summary.calories >= goal * 0.85 && summary.calories <= goal * 1.15;
          final isCheat = d.dayType == PlanDayType.cheat;
          final isVac = d.dayType == PlanDayType.vacation;

          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedDate = d.date); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSel ? 60 : 52,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? _P.greenDeep : _P.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSel ? _P.greenDeep : (isToday ? _P.greenDeep.withOpacity(0.4) : _P.divider), width: isSel ? 2 : 1),
                boxShadow: isSel ? [BoxShadow(color: _P.greenDeep.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))] : null,
              ),
              child: Opacity(
                opacity: (isPast || (d.date.isAfter(today) && !isSel)) ? 0.6 : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_weekShort(d.date.weekday), style: GoogleFonts.inter(color: isSel ? Colors.white70 : _P.text.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Text('${d.date.day}', style: GoogleFonts.inter(color: isSel ? Colors.white : _P.text, fontSize: 18, fontWeight: FontWeight.w700, fontFeatures: const [ui.FontFeature.tabularFigures()])),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 14,
                      child: isCheat ? const Text('🍕', style: TextStyle(fontSize: 12))
                          : isVac ? const Text('🏖', style: TextStyle(fontSize: 12))
                          : (isPast && hit) ? Icon(Icons.check_circle_rounded, size: 14, color: isSel ? Colors.white : _P.greenDeep)
                          : Container(width: 5, height: 5, decoration: BoxDecoration(color: isSel ? Colors.white.withOpacity(0.7) : _P.divider, shape: BoxShape.circle)),
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

  // ═══════════════ DAY CONTENT ═══════════════
  Widget _dayContent(BuildContext context, NutritionProvider provider, NutritionProgram program, PlanDay? day, Map<MealType, List<PlanMeal>> groupedMeals, DailyNutritionSummary summary, NutritionGoals dayGoals) {
    if (day == null) return const SizedBox.shrink();
    final isToday = _sameDay(day.date, DateTime.now());
    final isPast = day.date.isBefore(_dateOnly(DateTime.now()));

    final sortedTypes = MealType.values.where((t) => groupedMeals.containsKey(t)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isToday ? 'Сегодня' : '${_weekdayRu(day.date.weekday)}, ${day.date.day} ${_monthRu(day.date.month)}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _P.text)),
              const Spacer(),
              if (!isPast) _dayTypeChip(provider, day),
            ],
          ),
          const SizedBox(height: 16),
          _balanceCard(summary, dayGoals),
          const SizedBox(height: 20),

          if (program.mode == ProgramMode.byMeals)
            ...sortedTypes.map((type) => _groupedMealCard(context, provider, type, groupedMeals[type]!, isPast)),

          const SizedBox(height: 20),
          _waterCard(context, provider, summary, dayGoals),
        ],
      ),
    );
  }

  // 🆕 Карточка группы приемов пищи (объединяет несколько продуктов одного типа)
  Widget _groupedMealCard(BuildContext context, NutritionProvider provider, MealType type, List<PlanMeal> meals, bool isPast) {
    double groupActualKcal = 0;
    double groupTargetKcal = 0;

    for (final m in meals) {
      final entries = provider.getEntriesForDate(_selectedDate).where((e) => e.mealType == m.mealType).toList();
      groupActualKcal += entries.fold<double>(0, (s, e) => s + e.calories);
      groupTargetKcal += (m.targetCalories ?? 0);
    }

    final pct = groupTargetKcal > 0 ? (groupActualKcal / groupTargetKcal).clamp(0.0, 1.2) : 0.0;
    final allCompleted = meals.every((m) => m.isCompleted);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.divider, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: allCompleted ? _P.greenSoft : _P.bg, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(type.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.displayName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _P.text)),
                      Text('${meals.length} ${meals.length == 1 ? 'позиция' : 'позиции'}', style: GoogleFonts.inter(fontSize: 12, color: _P.muted)),
                    ],
                  ),
                ),
                if (!isPast)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 28, color: _P.greenDeep),
                    onPressed: () => _showAddFoodSheet(context, provider, _selectedDate, type),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: meals.asMap().entries.map((entry) {
                final index = entry.key;
                final meal = entry.value;
                final isLast = index == meals.length - 1;
                return _mealItemRow(context, provider, meal, isLast, isPast);
              }).toList(),
            ),
          ),

          if (groupTargetKcal > 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: _P.elevated,
                        valueColor: AlwaysStoppedAnimation(pct >= 0.85 && pct <= 1.15 ? _P.greenDeep : _P.skyDeep),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${groupActualKcal.round()} / ${groupTargetKcal.round()} ккал', style: GoogleFonts.inter(fontSize: 12, color: _P.muted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 🆕 Строка конкретного продукта/рецепта внутри группы с кнопкой "Съел"
  Widget _mealItemRow(BuildContext context, NutritionProvider provider, PlanMeal meal, bool isLast, bool isPast) {
    final isProduct = meal.templateId?.startsWith('PROD:') ?? false;
    final productId = isProduct ? meal.templateId!.substring(6) : null;

    final template = !isProduct && meal.templateId != null
        ? provider.templates.where((t) => t.id == meal.templateId).firstOrNull
        : null;

    final product = isProduct
        ? provider.products.where((p) => p.id == productId).firstOrNull
        : null;

    final displayName = template?.name ?? product?.name ?? 'Неизвестно';
    final isEaten = meal.isCompleted && meal.note != 'Пропущено';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: !isLast ? BoxDecoration(border: Border(bottom: BorderSide(color: _P.divider))) : null,
      child: Row(
        children: [
          Icon(isProduct ? Icons.apple_rounded : Icons.restaurant_menu_rounded, size: 18, color: _P.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayName,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isEaten ? _P.muted : _P.text,
                fontWeight: FontWeight.w500,
                decoration: isEaten ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isPast)
            GestureDetector(
              onTap: () async {
                if (isEaten) {
                  await provider.unmarkMealAsCompleted(meal.id);
                } else {
                  await provider.markMealAsCompleted(meal.id, portions: 1, date: _selectedDate);
                }
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isEaten ? _P.greenDeep : _P.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isEaten ? _P.greenDeep : _P.divider),
                ),
                child: Icon(
                  isEaten ? Icons.check_rounded : Icons.add_rounded,
                  size: 18,
                  color: isEaten ? Colors.white : _P.muted,
                ),
              ),
            )
          else if (isEaten)
            const Icon(Icons.check_circle_rounded, size: 20, color: _P.greenDeep)
        ],
      ),
    );
  }

  // ═══════════════ BALANCE CARD ═══════════════
  Widget _balanceCard(DailyNutritionSummary summary, NutritionGoals goals) {
    final diffKcal = goals.calories - summary.calories;
    final isOver = diffKcal < -50;
    final isUnder = diffKcal > 50;
    final isOnTrack = !isOver && !isUnder;

    Color statusColor = isOnTrack ? _P.greenDeep : (isUnder ? _P.skyDeep : _P.peachDeep);
    String statusText = isOnTrack ? 'Отлично! В цели' : (isUnder ? 'Недобор' : 'Перебор');
    String advice = isOnTrack ? 'Так держать!' : (isUnder ? 'Можно добавить легкий перекус.' : 'Завтра постарайся быть чуть легче.');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isOnTrack ? Icons.check_circle_rounded : (isUnder ? Icons.trending_up_rounded : Icons.warning_rounded), color: statusColor, size: 22),
              const SizedBox(width: 10),
              Text(statusText, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: statusColor)),
              const Spacer(),
              Text('${diffKcal.abs().round()} ккал', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: statusColor, fontFeatures: const [ui.FontFeature.tabularFigures()])),
            ],
          ),
          const SizedBox(height: 8),
          Text(advice, style: GoogleFonts.inter(fontSize: 13, color: _P.muted, height: 1.4)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniBalance('Белки', summary.protein, goals.protein, 'г', _P.greenDeep),
              _miniBalance('Жиры', summary.fat, goals.fat, 'г', _P.yellowDeep),
              _miniBalance('Углев.', summary.carbs, goals.carbs, 'г', _P.skyDeep),
            ],
          )
        ],
      ),
    );
  }

  Widget _miniBalance(String label, double actual, double target, String unit, Color color) {
    final diff = target - actual;
    final diffColor = diff.abs() < 5 ? _P.greenDeep : (diff > 0 ? _P.skyDeep : _P.peachDeep);
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: _P.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('${actual.round()} / ${target.round()}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: _P.text, fontFeatures: const [ui.FontFeature.tabularFigures()])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: diffColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text('${diff > 0 ? "+" : ""}${diff.round()} $unit', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: diffColor)),
        ),
      ],
    );
  }

  Widget _dayTypeChip(NutritionProvider provider, PlanDay day) {
    return PopupMenuButton<PlanDayType>(
      initialValue: day.dayType,
      onSelected: (t) { HapticFeedback.selectionClick(); provider.setPlanDayType(day.id, t); },
      itemBuilder: (_) => PlanDayType.values.map((t) => PopupMenuItem(value: t, child: Row(children: [if (t.emoji.isNotEmpty) ...[Text(t.emoji), const SizedBox(width: 8)], Text(t.label)]))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: day.dayType == PlanDayType.regular ? _P.bg : _P.lavenderSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: _P.divider)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (day.dayType.emoji.isNotEmpty) ...[Text(day.dayType.emoji, style: const TextStyle(fontSize: 14)), const SizedBox(width: 6)],
          Text(day.dayType.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: day.dayType == PlanDayType.regular ? _P.muted : _P.lavenderDeep)),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more_rounded, size: 16, color: _P.muted),
        ]),
      ),
    );
  }

  Widget _waterCard(BuildContext context, NutritionProvider provider, DailyNutritionSummary s, NutritionGoals g) {
    final pct = g.waterMl > 0 ? (s.waterMl / g.waterMl).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _P.divider, width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: _P.skySoft, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Text('💧', style: TextStyle(fontSize: 20))),
              const SizedBox(width: 12),
              Text('Вода', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _P.text)),
              const Spacer(),
              Text('${s.waterMl} / ${g.waterMl} мл', style: GoogleFonts.inter(fontSize: 14, color: _P.skyDeep, fontWeight: FontWeight.w700, fontFeatures: const [ui.FontFeature.tabularFigures()])),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: _P.skySoft, valueColor: const AlwaysStoppedAnimation(_P.skyDeep)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _waterBtn('+250 мл', 250, provider)),
              const SizedBox(width: 12),
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
        decoration: BoxDecoration(color: _P.skySoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: _P.skyDeep.withOpacity(0.2))),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _P.skyDeep)),
      ),
    );
  }

  // ═══════════════ STATS + HEATMAP ═══════════════
  Widget _statsAndHeatmap(BuildContext context, NutritionProvider provider, NutritionProgram program, List<PlanDay> days) {
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
              _statPill('📊', '${days.where((d) => d.dayType.countsForStats).length}', 'дней в плане'),
            ],
          ),
          const SizedBox(height: 20),
          Text('АКТИВНОСТЬ (30 ДНЕЙ)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _P.muted)),
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
        decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: _P.divider, width: 1.5)),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: _P.text)),
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: _P.muted, fontWeight: FontWeight.w500)),
            ]),
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
      decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _P.divider, width: 1.5)),
      child: Wrap(
        spacing: 6, runSpacing: 6,
        children: days.map((r) {
          Color c;
          if (r < 0) c = _P.elevated;
          else if (r < 0.6) c = _P.pinkSoft;
          else if (r < 0.85) c = _P.yellowSoft;
          else if (r <= 1.15) c = _P.greenSoft;
          else c = _P.peachSoft;
          return Container(width: 22, height: 22, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)));
        }).toList(),
      ),
    );
  }

  // ═══════════════ FAB ═══════════════
  Widget _fab(BuildContext context, NutritionProvider provider, NutritionProgram program, PlanDay? day) {
    if (day == null) return const SizedBox.shrink();
    if (day.date.isAfter(_dateOnly(DateTime.now()))) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: _P.greenDeep.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
      child: FloatingActionButton(
        // 🆕 Добавляем в "Другое" по умолчанию, пользователь сможет изменить это при желании,
        // либо мы можем сделать выбор типа. Для простоты используем other.
        onPressed: () => _showAddFoodSheet(context, provider, _selectedDate, MealType.other),
        backgroundColor: _P.greenDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // ═══════════════ ACTIONS ═══════════════
  Future<void> _showAddFoodSheet(BuildContext context, NutritionProvider provider, DateTime date, MealType type) async {
    final selected = await showModalBottomSheet<_SelectedFood>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FoodPicker(provider: provider),
    );

    if (selected != null && mounted) {
      final templateId = selected.isProduct ? 'PROD:${selected.id}' : selected.id;
      await provider.addToPlan(date: date, mealType: type, templateId: templateId);
      HapticFeedback.mediumImpact();
    }
  }

  void _openBuilder(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanBuilderScreen()));
  }

  void _showProgramOptions(BuildContext context, NutritionProvider provider, NutritionProgram program) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 24),
                Text('Управление программой', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: _P.text)),
                const SizedBox(height: 8),
                Text('«${program.name}»', style: GoogleFonts.inter(fontSize: 14, color: _P.muted)),
                const SizedBox(height: 24),
                _actionOption(Icons.check_circle_rounded, _P.greenDeep, 'Завершить программу', 'Переместить в историю как успешную', () {
                  Navigator.pop(ctx);
                  _confirmAndExecute(provider, program.id, 'Завершить программу?', 'Поздравляем! Программа будет сохранена в истории.', provider.finishProgram);
                }),
                const Divider(height: 32),
                _actionOption(Icons.cancel_rounded, _P.pinkDeep, 'Отменить программу', 'Прервать прохождение, данные сохранятся', () {
                  Navigator.pop(ctx);
                  _confirmAndExecute(provider, program.id, 'Отменить программу?', 'Программа будет деактивирована и перемещена в историю.', provider.cancelProgram);
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionOption(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), alignment: Alignment.center, child: Icon(icon, size: 22, color: color)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _P.text)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: _P.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 22, color: _P.muted),
          ],
        ),
      ),
    );
  }

  void _confirmAndExecute(NutritionProvider provider, String programId, String title, String message, Future<void> Function(String) action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: _P.text)),
        content: Text(message, style: GoogleFonts.inter(color: _P.muted, height: 1.4)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена', style: TextStyle(color: _P.muted, fontWeight: FontWeight.w600))),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await action(programId);
              if (mounted) {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: _P.pinkDeep, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
            child: const Text('Подтвердить', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(backgroundColor: _P.bg, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _P.text), onPressed: () => Navigator.pop(context))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: _P.greenSoft, shape: BoxShape.circle), alignment: Alignment.center, child: const Text('📋', style: TextStyle(fontSize: 36))),
              const SizedBox(height: 24),
              Text('Нет активной программы', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: _P.text)),
              const SizedBox(height: 8),
              Text('Создай план питания, чтобы начать отслеживать свой прогресс', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: _P.muted, height: 1.4)),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanBuilderScreen())),
                style: FilledButton.styleFrom(backgroundColor: _P.greenDeep, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Создать программу', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════ HELPERS ═══════════════
  int _countCompletedDays(NutritionProvider p, NutritionProgram program, List<PlanDay> days) {
    int count = 0;
    for (final d in days) {
      if (!d.dayType.countsForStats) continue;
      final s = p.getSummaryForDate(d.date);
      final goal = d.targetCalories ?? program.targetCalories;
      if (goal > 0 && s.calories >= goal * 0.85 && s.calories <= goal * 1.15) count++;
    }
    return count;
  }

  int _calcStreak(NutritionProvider p, List<PlanDay> days, NutritionProgram program) {
    int streak = 0;
    for (int i = days.length - 1; i >= 0; i--) {
      final d = days[i];
      if (d.date.isAfter(DateTime.now())) continue;
      if (!d.dayType.countsForStats) continue;
      final s = p.getSummaryForDate(d.date);
      final goal = d.targetCalories ?? program.targetCalories;
      final hit = goal > 0 && s.calories >= goal * 0.85 && s.calories <= goal * 1.15;
      if (hit) streak++; else break;
    }
    return streak;
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  String _weekShort(int wd) => const ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'][wd - 1];
  String _weekdayRu(int wd) => const ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'][wd - 1];
  String _monthRu(int m) => const ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'][m - 1];
  String _fmtDate(DateTime d) => '${d.day} ${_monthRu(d.month)}';
}

// ═══════════════════════════════════════════════════════════════════
//  🆕 МОДЕЛЬ ВЫБРАННОЙ ЕДЫ (Локальная копия для трекера)
// ═══════════════════════════════════════════════════════════════════
class _SelectedFood {
  final bool isProduct;
  final String id;
  final String name;
  final double calories;
  _SelectedFood({required this.isProduct, required this.id, required this.name, required this.calories});
}

// ═══════════════════════════════════════════════════════════════════
//  🆕 УНИВЕРСАЛЬНЫЙ ВЫБОР ЕДЫ (Локальная копия для трекера)
// ═══════════════════════════════════════════════════════════════════
class _FoodPicker extends StatefulWidget {
  final NutritionProvider provider;
  const _FoodPicker({required this.provider});

  @override
  State<_FoodPicker> createState() => _FoodPickerState();
}

class _FoodPickerState extends State<_FoodPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = widget.provider.templates.where((t) =>
    _query.isEmpty || t.name.toLowerCase().contains(_query.toLowerCase())
    ).take(15).toList();

    final products = widget.provider.products.where((p) =>
    _query.isEmpty || p.name.toLowerCase().contains(_query.toLowerCase())
    ).take(15).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Выберите еду', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _P.text)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: _P.text)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Поиск рецепта или продукта...',
                  prefixIcon: const Icon(Icons.search_rounded, color: _P.muted),
                  filled: true,
                  fillColor: _P.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (templates.isNotEmpty) ...[
                    Text('РЕЦЕПТЫ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _P.muted, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    ...templates.map((t) => _FoodItemTile(
                      emoji: '🍱', name: t.name, subtitle: '${t.caloriesPerPortion.round()} ккал',
                      badge: 'Рецепт', badgeColor: _P.skyDeep,
                      onTap: () => Navigator.pop(context, _SelectedFood(isProduct: false, id: t.id, name: t.name, calories: t.caloriesPerPortion)),
                    )),
                    const SizedBox(height: 20),
                  ],
                  if (products.isNotEmpty) ...[
                    Text('ПРОДУКТЫ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _P.muted, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    ...products.map((p) => _FoodItemTile(
                      emoji: p.categoryEmoji ?? '🍎', name: p.name, subtitle: '${p.calories.round()} ккал / 100г',
                      badge: 'Продукт', badgeColor: _P.greenDeep,
                      onTap: () => Navigator.pop(context, _SelectedFood(isProduct: true, id: p.id, name: p.name, calories: p.calories)),
                    )),
                  ],
                  if (templates.isEmpty && products.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Ничего не найдено', style: GoogleFonts.inter(color: _P.muted, fontSize: 14)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodItemTile extends StatelessWidget {
  final String emoji, name, subtitle, badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _FoodItemTile({required this.emoji, required this.name, required this.subtitle, required this.badge, required this.badgeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: _P.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _P.divider)),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(emoji, style: const TextStyle(fontSize: 20))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _P.text)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: _P.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(badge, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _P.muted),
          ],
        ),
      ),
    );
  }
}