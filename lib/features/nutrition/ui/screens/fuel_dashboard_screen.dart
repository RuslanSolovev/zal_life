// features/nutrition/ui/screens/fuel_dashboard_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/color_settings_provider.dart';
import 'add_food_screen.dart';
import 'profile_setup_screen.dart';

// ==================== POWER MODE TOKENS ====================

class _Power {
  static const Color heroBase = Color(0xFF050505);
  static const Color heroDeep = Color(0xFF120700);

  static const Color volt = Color(0xFFFF5500);
  static const Color voltBright = Color(0xFFFF7A1A);
  static const Color magma = Color(0xFFFF2D55);
  static const Color plasma = Color(0xFFFFCC00);
  static const Color ice = Color(0xFF00E5FF);
  static const Color lime = Color(0xFFB4FF39);
  static const Color green = Color(0xFF00C853);
  static const Color red = Color(0xFFFF3B30);
  static const Color violet = Color(0xFF9C82FF);

  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkCard2 = Color(0xFF2C2C2E);
  static const Color lightBg = Color(0xFFF2F2F7);
  static const Color lightCard = Color(0xFFFFFFFF);

  static Color bg(bool isDark) => isDark ? darkBg : lightBg;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color card2(bool isDark) => isDark ? darkCard2 : const Color(0xFFF9FAFB);
  static Color textPrimary(bool isDark) => isDark ? Colors.white : Colors.black;
  static Color textSecondary(bool isDark) => isDark
      ? Colors.white.withOpacity(0.6)
      : const Color(0xFF3C3C43).withOpacity(0.6);
  static Color textTertiary(bool isDark) => isDark
      ? Colors.white.withOpacity(0.3)
      : const Color(0xFF3C3C43).withOpacity(0.3);
  static Color separator(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

  static List<BoxShadow> softGlow(Color color, {double strength = 0.18}) => [
    BoxShadow(color: color.withOpacity(strength), blurRadius: 16),
  ];

  static List<BoxShadow> glow(Color color,
      {double strength = 0.4, double blur = 24}) =>
      [
        BoxShadow(
          color: color.withOpacity(strength),
          blurRadius: blur,
          offset: const Offset(0, 6),
        ),
      ];
}

class FuelDashboardScreen extends StatefulWidget {
  final bool isDark;

  const FuelDashboardScreen({
    super.key,
    this.isDark = true,
  });

  @override
  State<FuelDashboardScreen> createState() => _FuelDashboardScreenState();
}

class _FuelDashboardScreenState extends State<FuelDashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  bool _showTemplatesGrid = false;
  bool _templatesExpanded = false;
  String _templatesSearchQuery = '';
  TemplatesSortMode _templatesSortMode = TemplatesSortMode.name;

  // ============================================================
  // ДНЕВНОЙ ЦИКЛ — 5 цветов от «рассвета» до «ночи».
  // 5 приёмов пищи = 5 срезов этого цикла.
  // Внутри каждой карточки эти цвета плавно идут по диагонали
  // сверху-справа (раннее) → вниз-влево (позднее).
  // ============================================================
  static const List<Color> _dayCycle = [
    Color(0xFFE8B94E), // #1 рассвет — тёплый жёлтый
    Color(0xFFB8894A), // #2 утро — янтарный
    Color(0xFF7A5560), // #3 день — приглушённый пурпурно-коричневый
    Color(0xFF3A2B44), // #4 вечер — тёмная слива
    Color(0xFF15111C), // #5 ночь — почти чёрный фиолетовый
  ];

  // ================ Palette helpers ================
  Color get _background => _Power.bg(widget.isDark);
  Color get _surface => _Power.card(widget.isDark);
  Color get _surface2 => _Power.card2(widget.isDark);
  Color get _textPrimary => _Power.textPrimary(widget.isDark);
  Color get _textSecondary => _Power.textSecondary(widget.isDark);
  Color get _textMuted => _Power.textTertiary(widget.isDark);
  Color get _divider => _Power.separator(widget.isDark);
  Color get _softWhite => widget.isDark
      ? Colors.white.withOpacity(0.035)
      : Colors.black.withOpacity(0.025);
  Color get _lineBase => _Power.separator(widget.isDark);

  /// Акцент и цвет лучей — из ColorSettingsProvider (динамические).
  Color get _accent => context.read<ColorSettingsProvider>().accent;
  Color get _cyan => _accent;
  Color get _ray => context.read<ColorSettingsProvider>().ray;

  // Фиксированные семантические цвета
  static const Color _green = _Power.green;
  static const Color _pink = _Power.magma;
  static const Color _yellow = _Power.plasma;
  static const Color _orange = _Power.volt;
  static const Color _purple = _Power.violet;
  static const Color _blue = _Power.ice;

  // ============================================================
  // MEAL GRADIENT HELPERS — дневной цикл
  // ============================================================

  /// Позиция приёма пищи в дневном цикле.
  /// 5 приёмов = 5 равных срезов по 0.2.
  double _mealPosition(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return 0.0;
      case MealType.snack1:
        return 0.2;
      case MealType.lunch:
        return 0.4;
      case MealType.snack2:
        return 0.6;
      case MealType.dinner:
        return 0.8;
      case MealType.other:
        return 0.4;
    }
  }

  /// Интерполяция по 5-цветному дневному циклу.
  /// t = 0 → рассвет-жёлтый, t = 1 → ночь-почти-чёрный.
  Color _dayColorAt(double t) {
    final clamped = t.clamp(0.0, 1.0);
    final scaled = clamped * (_dayCycle.length - 1);
    final idx = scaled.floor();
    final frac = scaled - idx;
    if (idx >= _dayCycle.length - 1) return _dayCycle.last;
    return Color.lerp(_dayCycle[idx], _dayCycle[idx + 1], frac)!;
  }

  /// Базовый цвет приёма пищи (для иконок, рамок, кнопок)
  Color _mealColor(MealType meal) => _dayColorAt(_mealPosition(meal));

  /// 5 диагональных стопов карточки.
  /// Карточка покрывает 1/5 цикла (span = 0.2), внутри — 5 секций.
  List<Color> _cardGradientStops(MealType meal) {
    final base = _mealPosition(meal);
    const span = 0.2;
    // В тёмной теме показываем цвет ярче, в светлой — приглушённее
    final opacity = widget.isDark ? 0.55 : 0.32;

    return List.generate(5, (i) {
      final f = i / 4.0; // 0, 0.25, 0.5, 0.75, 1.0
      final t = base + f * span;
      final dayColor = _dayColorAt(t);
      // Смешиваем с фоном карточки, чтобы текст оставался читаемым
      return Color.lerp(_surface2, dayColor, opacity)!;
    });
  }

  // ============================================================

  @override
  Widget build(BuildContext context) {
    context.watch<ColorSettingsProvider>();

    final provider = context.watch<NutritionProvider>();

    final summary = provider.getSummaryForDate(_selectedDate);
    final goals = provider.getGoalsForDate(_selectedDate);
    final entries = provider.getEntriesForDate(_selectedDate);
    final recommendations = provider.getRecommendations(_selectedDate);

    final meals = _groupEntriesByMeal(entries);

    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final hasProfile = provider.userProfile != null;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildTopBar(isToday: isToday, hasProfile: hasProfile),
            SliverToBoxAdapter(child: _buildDateSelector()),
            SliverToBoxAdapter(
              child: _buildHero(summary, goals, hasProfile),
            ),
            SliverToBoxAdapter(
              child: _buildGlowRay(color: _ray, width: 0.88),
            ),
            SliverToBoxAdapter(child: _buildMacros(summary, goals)),
            SliverToBoxAdapter(child: _buildWater(provider, goals)),
            if (recommendations.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildGlowRay(color: _ray, width: 0.76),
              ),
              SliverToBoxAdapter(
                child: _buildRecommendations(recommendations),
              ),
            ],

            SliverToBoxAdapter(
              child: _buildGlowRay(color: _ray, width: 0.72),
            ),
            SliverToBoxAdapter(child: _buildQuickAdd(provider)),

            SliverToBoxAdapter(
              child: _buildGlowRay(color: _ray, width: 0.86),
            ),
            SliverToBoxAdapter(
              child: _buildMeals(provider, meals, summary),
            ),

            SliverToBoxAdapter(
              child: _buildGlowRay(color: _ray, width: 0.90),
            ),
            SliverToBoxAdapter(child: _buildTemplates(provider)),
            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context, provider),
    );
  }

  // =============================================================
  // DATA
  // =============================================================

  Map<MealType, List<FoodDiaryEntry>> _groupEntriesByMeal(
      List<FoodDiaryEntry> entries) {
    final result = <MealType, List<FoodDiaryEntry>>{};
    for (final meal in MealType.values) {
      result[meal] = entries.where((e) => e.mealType == meal).toList();
    }
    return result;
  }

  List<_MealItemGroup> _groupEntries(List<FoodDiaryEntry> entries) {
    final groups = <_MealItemGroup>[];
    final templates = <String, _MealItemGroup>{};

    for (final entry in entries) {
      final tid = entry.templateId;
      if (tid != null && tid.isNotEmpty) {
        final existing = templates[tid];
        if (existing != null) {
          existing.entries.add(entry);
          continue;
        }
        final group = _MealItemGroup(
          templateId: tid,
          templateName: entry.templateName ?? 'Блюдо',
          entries: [entry],
        );
        templates[tid] = group;
        groups.add(group);
      } else {
        groups.add(_MealItemGroup(entries: [entry]));
      }
    }
    return groups;
  }

  // =============================================================
  // TOP BAR
  // =============================================================

  Widget _buildTopBar({
    required bool isToday,
    required bool hasProfile,
  }) {
    return SliverAppBar(
      backgroundColor: _background.withOpacity(0.96),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: false,
      floating: true,
      snap: true,
      toolbarHeight: 76,
      titleSpacing: 16,
      title: Row(
        children: [
          _buildFuelMark(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isToday ? 'Питание' : 'История',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.9,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _buildTopAction(
          icon: hasProfile
              ? Icons.person_rounded
              : Icons.person_outline_rounded,
          color: hasProfile ? _green : _textSecondary,
          showDot: !hasProfile,
          onTap: () => _openProfileSetup(context),
        ),
        const SizedBox(width: 6),
        _buildTopAction(
          icon: Icons.tune_rounded,
          color: _textSecondary,
          onTap: () => _showGoalsEditor(context),
        ),
        const SizedBox(width: 6),
        _buildTopAction(
          icon: Icons.palette_rounded,
          color: _accent,
          onTap: () => _showColorPicker(context),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildFuelMark() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accent, _accent.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _Power.glow(_accent, strength: 0.35, blur: 22),
      ),
      child: const Icon(
        Icons.bolt_rounded,
        color: _Power.darkBg,
        size: 27,
      ),
    );
  }

  Widget _buildTopAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool showDot = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _divider, width: 0.5),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        if (showDot)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _pink,
                shape: BoxShape.circle,
                border: Border.all(color: _background, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  // =============================================================
  // COLOR PICKER SHEET
  // =============================================================

  void _showColorPicker(BuildContext context) {
    final settings = context.read<ColorSettingsProvider>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {

            Widget paletteRow({
              required Color selected,
              required ValueChanged<Color> onPick,
            }) {
              // Разбиваем 16 цветов на 2 ряда по 8
              final rows = <List<Color>>[
                kAppPalette.sublist(0, 8),
                kAppPalette.sublist(8, 16),
              ];

              return Column(
                children: rows.map((row) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: row.map((c) {
                        final isSel = c.value == selected.value;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onPick(c);
                                setSheetState(() {});
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                height: 42,
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: isSel
                                        ? _textPrimary
                                        : Colors.transparent,
                                    width: isSel ? 2.2 : 0,
                                  ),
                                  boxShadow: _Power.softGlow(c, strength: 0.30),
                                ),
                                child: isSel
                                    ? const Icon(
                                  Icons.check_rounded,
                                  color: _Power.darkBg,
                                  size: 18,
                                )
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              );
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _textMuted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: settings.accent.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: _Power.softGlow(settings.accent,
                                strength: 0.25),
                          ),
                          child: Icon(Icons.palette_rounded,
                              color: settings.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ЦВЕТА',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'ЛУЧИ',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    paletteRow(
                      selected: settings.ray,
                      onPick: (c) => settings.setRay(c),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'ОСНОВНОЙ АКЦЕНТ',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    paletteRow(
                      selected: settings.accent,
                      onPick: (c) => settings.setAccent(c),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =============================================================
  // GLOW RAY
  // =============================================================

  Widget _buildGlowRay({
    required Color color,
    double width = 0.86,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: SizedBox(
        height: 18,
        child: CustomPaint(
          painter: _GlowRayPainter(
            color: color,
            widthFactor: width,
            backgroundColor: _lineBase,
            coreWidth: 2.8,
            glowWidth: 9.5,
          ),
        ),
      ),
    );
  }

  // =============================================================
  // DATE
  // =============================================================

  Widget _buildDateSelector() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 17),
      child: Row(
        children: [
          _dateNavButton(
            icon: Icons.chevron_left_rounded,
            enabled: true,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedDate =
                    _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _divider, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _Power.softGlow(_accent, strength: 0.15),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: _accent,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        isToday
                            ? 'СЕГОДНЯ'
                            : _formatDateFull(_selectedDate).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.15,
                        ),
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: _green,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _dateNavButton(
            icon: Icons.chevron_right_rounded,
            enabled: !isToday,
            onTap: isToday
                ? null
                : () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedDate =
                    _selectedDate.add(const Duration(days: 1));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _dateNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          border: Border.all(color: _divider, width: 0.5),
        ),
        child: Icon(
          icon,
          color: enabled ? _textSecondary : _textMuted.withOpacity(0.35),
          size: 24,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final scheme = widget.isDark
            ? ColorScheme.dark(
          primary: _accent,
          surface: _Power.darkCard,
          onSurface: Colors.white,
        )
            : ColorScheme.light(
          primary: _accent,
          surface: Colors.white,
          onSurface: Colors.black,
        );
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: scheme,
            dialogTheme: DialogThemeData(backgroundColor: _surface),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  // =============================================================
  // HERO
  // =============================================================

  Widget _buildHero(
      DailyNutritionSummary summary,
      NutritionGoals goals,
      bool hasProfile,
      ) {
    final rawPercent =
    goals.calories > 0 ? summary.calories / goals.calories : 0.0;
    final percent = rawPercent.clamp(0.0, 1.0);
    final isOver = summary.calories > goals.calories;
    final remaining = goals.calories - summary.calories;

    final progressColor = isOver
        ? _pink
        : rawPercent >= 0.90
        ? _green
        : _accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 19),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_surface2, _surface],
          ),
          border: Border.all(
            color: progressColor.withOpacity(0.15),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(widget.isDark ? 0.23 : 0.05),
              blurRadius: 38,
              offset: const Offset(0, 17),
            ),
            BoxShadow(
              color: progressColor.withOpacity(0.05),
              blurRadius: 34,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -110,
              right: -90,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: progressColor.withOpacity(0.045),
                ),
              ),
            ),
            Positioned(
              bottom: -95,
              left: -90,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.025),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ДНЕВНОЙ БАЛАНС',
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.75,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Энергия',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasProfile) _profileBadge(),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 132,
                      height: 132,
                      child: CustomPaint(
                        painter: _HeroGaugePainter(
                          percent: percent,
                          color: progressColor,
                          backgroundColor:
                          _textPrimary.withOpacity(0.055),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(rawPercent * 100).round()}%',
                                style: TextStyle(
                                  color: progressColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 0.95,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'ЦЕЛИ',
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  '${summary.calories.round()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    height: 0.95,
                                    letterSpacing: -1.9,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding:
                                const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'ккал',
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'из ${goals.calories.round()} ккал',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: progressColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isOver
                                      ? Icons.warning_amber_rounded
                                      : Icons.local_fire_department_rounded,
                                  color: progressColor,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isOver
                                        ? 'ПРЕВЫШЕНИЕ ${remaining.abs().round()} ККАЛ'
                                        : 'ОСТАЛОСЬ ${remaining.round()} ККАЛ',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: progressColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                _buildProgressBar(
                  value: percent,
                  color: progressColor,
                  height: 7,
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    _heroMetric(
                        title: 'БЕЛОК',
                        value: '${summary.protein.round()} г',
                        color: _green),
                    _heroMetric(
                        title: 'ЖИРЫ',
                        value: '${summary.fat.round()} г',
                        color: _pink),
                    _heroMetric(
                        title: 'УГЛЕВ.',
                        value: '${summary.carbs.round()} г',
                        color: _yellow),
                    _heroMetric(
                        title: 'ВОДА',
                        value: '${summary.waterMl} мл',
                        color: _accent),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _green.withOpacity(0.18), width: 0.5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: _green, size: 13),
          SizedBox(width: 5),
          Text(
            'ПРОФИЛЬ',
            style: TextStyle(
              color: _green,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMetric({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _textMuted,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required double value,
    required Color color,
    double height = 6,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: height,
            color: _textPrimary.withOpacity(0.045),
          ),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.42), color],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // MACROS
  // =============================================================

  Widget _buildMacros(
      DailyNutritionSummary summary,
      NutritionGoals goals,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _macroCard(
                label: 'БЕЛОК',
                current: summary.protein,
                goal: goals.protein,
                color: _green,
                icon: Icons.fitness_center_rounded,
              ),
            ),
            _verticalMacroRay(color: _ray),
            Expanded(
              child: _macroCard(
                label: 'ЖИРЫ',
                current: summary.fat,
                goal: goals.fat,
                color: _pink,
                icon: Icons.water_drop_rounded,
              ),
            ),
            _verticalMacroRay(color: _ray),
            Expanded(
              child: _macroCard(
                label: 'УГЛЕВ.',
                current: summary.carbs,
                goal: goals.carbs,
                color: _yellow,
                icon: Icons.grain_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalMacroRay({required Color color}) {
    return SizedBox(
      width: 16,
      child: CustomPaint(
        painter: _VerticalGlowRayPainter(
          color: color,
          heightFactor: 0.9,
          backgroundColor: Colors.transparent,
          coreWidth: 2.2,
          glowWidth: 7,
        ),
      ),
    );
  }

  Widget _macroCard({
    required String label,
    required double current,
    required double goal,
    required Color color,
    required IconData icon,
  }) {
    final rawPercent = goal > 0 ? current / goal : 0.0;
    final percent = rawPercent.clamp(0.0, 1.0);
    final isOver = current > goal;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: color.withOpacity(0.12), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
              Text(
                '${(rawPercent * 100).round()}%',
                style: TextStyle(
                  color: isOver ? _pink : color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            label,
            style: TextStyle(
              color: _textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${current.round()}',
                style: TextStyle(
                  color: isOver ? _pink : _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '/ ${goal.round()}',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _buildProgressBar(
            value: percent,
            color: isOver ? _pink : color,
            height: 4,
          ),
        ],
      ),
    );
  }

  // =============================================================
  // WATER
  // =============================================================

  Widget _buildWater(
      NutritionProvider provider,
      NutritionGoals goals,
      ) {
    final currentMl = provider.getWaterForDate(_selectedDate);
    final rawPercent = goals.waterMl > 0 ? currentMl / goals.waterMl : 0.0;
    final percent = rawPercent.clamp(0.0, 1.0);

    const presets = [200, 250, 330, 500];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.isDark
                  ? _accent.withOpacity(0.06)
                  : _accent.withOpacity(0.04),
              _surface,
            ],
          ),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: _accent.withOpacity(0.12), width: 0.5),
          boxShadow: _Power.softGlow(_accent, strength: 0.05),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 41,
                  height: 41,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _Power.softGlow(_accent, strength: 0.15),
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: _accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ВОДНЫЙ БАЛАНС',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Поддерживай уровень жидкости',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currentMl',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  'мл',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildProgressBar(
                    value: percent,
                    color: _accent,
                    height: 6,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(rawPercent * 100).round()}%',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: presets.map((ml) {
                return Expanded(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await provider.addWater(
                          ml,
                          date: _selectedDate,
                        );
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _softWhite,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: _accent.withOpacity(0.10),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '+$ml',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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

  // =============================================================
  // RECOMMENDATIONS
  // =============================================================

  Widget _buildRecommendations(
      List<NutritionRecommendation> recommendations) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'РЕКОМЕНДАЦИИ',
            subtitle: 'Персональные подсказки на сегодня',
            color: _purple,
          ),
          const SizedBox(height: 12),
          ...recommendations.take(3).map((recommendation) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: recommendation.color.withOpacity(0.12),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: recommendation.color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: _Power.softGlow(
                        recommendation.color,
                        strength: 0.15,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      recommendation.emoji,
                      style: const TextStyle(fontSize: 19),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: TextStyle(
                            color: recommendation.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          recommendation.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 10,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  // =============================================================
  // MEALS — вертикальный таймлайн
  // =============================================================

  Widget _buildMeals(
      NutritionProvider provider,
      Map<MealType, List<FoodDiaryEntry>> meals,
      DailyNutritionSummary summary,
      ) {
    final mealList = MealType.values.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSectionTitle(
                    icon: Icons.restaurant_rounded,
                    title: 'ПРИЁМЫ ПИЩИ',
                    subtitle: 'Дневник по каждому приёму',
                    color: _orange,
                    compact: true,
                  ),
                ),
                if (summary.entriesCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${summary.entriesCount}',
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            ...List.generate(mealList.length, (index) {
              final meal = mealList[index];
              final isLast = index == mealList.length - 1;
              return _buildTimelineMeal(
                provider,
                meal,
                meals[meal] ?? const [],
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineMeal(
      NutritionProvider provider,
      MealType meal,
      List<FoodDiaryEntry> entries, {
        required bool isLast,
      }) {
    // Точка — того же цвета, что и луч
    final dotColor = _ray;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: _Power.softGlow(dotColor, strength: 0.6),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: CustomPaint(
                        painter: _VerticalGlowRayPainter(
                          color: _ray,
                          heightFactor: 0.92,
                          backgroundColor: Colors.transparent,
                          coreWidth: 2.4,
                          glowWidth: 8,
                        ),
                        size: const Size(22, double.infinity),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
              child: _buildMealCard(provider, meal, entries),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool compact = false,
  }) {
    return Row(
      children: [
        Container(
          width: compact ? 34 : 38,
          height: compact ? 34 : 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            boxShadow: _Power.softGlow(color, strength: 0.15),
          ),
          child: Icon(icon, color: color, size: compact ? 16 : 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(
      NutritionProvider provider,
      MealType meal,
      List<FoodDiaryEntry> entries,
      ) {
    final calories =
    entries.fold<double>(0, (sum, item) => sum + item.calories);
    final protein =
    entries.fold<double>(0, (sum, item) => sum + item.protein);
    final fat = entries.fold<double>(0, (sum, item) => sum + item.fat);
    final carbs = entries.fold<double>(0, (sum, item) => sum + item.carbs);
    final isEmpty = entries.isEmpty;

    final mealColor = _mealColor(meal);

    // 5 диагональных секций: от рассветного (сверху-справа)
    // к ночному (снизу-слева). Каждая карточка = 1/5 дневного цикла,
    // поэтому вместе карточки образуют непрерывный переход от
    // жёлтого завтрака к почти чёрному ужину.
    final stops = _cardGradientStops(meal);
    final borderColor = stops[2];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: stops,
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: borderColor.withOpacity(0.55),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: mealColor.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow:
                    _Power.softGlow(mealColor, strength: 0.25),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    meal.emoji,
                    style: const TextStyle(fontSize: 21),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.displayName.toUpperCase(),
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.75,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEmpty
                            ? 'Пока здесь пусто'
                            : '${entries.length} ${_foodWord(entries.length)}',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${calories.round()}',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'ККАЛ',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (!isEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _mealMacroBadge('Б', protein, _green),
                  const SizedBox(width: 5),
                  _mealMacroBadge('Ж', fat, _pink),
                  const SizedBox(width: 5),
                  _mealMacroBadge('У', carbs, _yellow),
                  const Spacer(),
                  Text(
                    '${entries.length} ПОЗ.',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._groupEntries(entries).map((group) {
                if (group.templateId != null) {
                  return _buildTemplateGroupRow(provider, group);
                }
                return _buildEntryRow(provider, group.entries.first);
              }),
            ],
            const SizedBox(height: 9),
            _buildAddMealButton(
              provider,
              meal,
              isEmpty,
              mealColor: mealColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateGroupRow(
      NutritionProvider provider, _MealItemGroup group) {
    final totalCal = group.entries
        .fold<double>(0, (sum, e) => sum + e.calories);
    final totalP =
    group.entries.fold<double>(0, (sum, e) => sum + e.protein);
    final totalF = group.entries.fold<double>(0, (sum, e) => sum + e.fat);
    final totalC = group.entries.fold<double>(0, (sum, e) => sum + e.carbs);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _purple.withOpacity(0.20),
          width: 0.6,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: const Text('🍱', style: TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.templateName ?? 'Блюдо',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'БЛЮДО • ${group.entries.length} ИНГРЕДИЕНТОВ',
                      style: TextStyle(
                        color: _purple,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${totalCal.round()}',
                style: TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'ККАЛ',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _entryMacro('Б', totalP, _green),
              const SizedBox(width: 3),
              _entryMacro('Ж', totalF, _pink),
              const SizedBox(width: 3),
              _entryMacro('У', totalC, _yellow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMealButton(
      NutritionProvider provider,
      MealType meal,
      bool isEmpty, {
        required Color mealColor,
      }) {
    final color = isEmpty ? _accent : _textSecondary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _openAddFood(context, provider, meal: meal);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isEmpty ? _accent.withOpacity(0.08) : _softWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEmpty ? _accent.withOpacity(0.15) : _divider,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEmpty ? Icons.add_rounded : Icons.add_circle_outline_rounded,
              color: color,
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              isEmpty ? 'ДОБАВИТЬ ПРОДУКТЫ' : 'ДОБАВИТЬ ЕЩЁ',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(NutritionProvider provider, FoodDiaryEntry entry) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 5),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: _pink.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: _pink,
          size: 20,
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        provider.removeEntry(entry.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: _surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _divider, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _textPrimary.withOpacity(0.035),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                _findProduct(provider, entry.productId)?.categoryEmoji ??
                    '🍽️',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${entry.grams.round()}Г',
              style: TextStyle(
                color: _textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 6),
            _entryMacro('Б', entry.protein, _green),
            const SizedBox(width: 2),
            _entryMacro('Ж', entry.fat, _pink),
            const SizedBox(width: 2),
            _entryMacro('У', entry.carbs, _yellow),
            const SizedBox(width: 7),
            SizedBox(
              width: 35,
              child: Text(
                '${entry.calories.round()}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: _accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryMacro(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label:${value.round()}',
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _mealMacroBadge(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$label ${value.round()} Г',
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  FoodProduct? _findProduct(NutritionProvider provider, String id) {
    try {
      return provider.products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  String _foodWord(int count) {
    if (count == 1) return 'продукт';
    if (count >= 2 && count <= 4) return 'продукта';
    return 'продуктов';
  }

  // =============================================================
  // TEMPLATES
  // =============================================================

  Widget _buildTemplates(NutritionProvider provider) {
    final templates = provider.templates;
    if (templates.isEmpty) return const SizedBox.shrink();

    var filteredTemplates = List<MealTemplate>.from(templates);

    if (_templatesSearchQuery.trim().isNotEmpty) {
      final query = _templatesSearchQuery.trim().toLowerCase();
      filteredTemplates = filteredTemplates
          .where((t) => t.name.toLowerCase().contains(query))
          .toList();
    }

    switch (_templatesSortMode) {
      case TemplatesSortMode.name:
        filteredTemplates.sort((a, b) => a.name.compareTo(b.name));
        break;
      case TemplatesSortMode.caloriesDesc:
        filteredTemplates.sort((a, b) => _getTemplateCalories(provider, b)
            .compareTo(_getTemplateCalories(provider, a)));
        break;
      case TemplatesSortMode.caloriesAsc:
        filteredTemplates.sort((a, b) => _getTemplateCalories(provider, a)
            .compareTo(_getTemplateCalories(provider, b)));
        break;
      case TemplatesSortMode.proteinDesc:
        filteredTemplates.sort((a, b) => _getTemplateProtein(provider, b)
            .compareTo(_getTemplateProtein(provider, a)));
        break;
      case TemplatesSortMode.fatDesc:
        filteredTemplates.sort((a, b) => _getTemplateFat(provider, b)
            .compareTo(_getTemplateFat(provider, a)));
        break;
      case TemplatesSortMode.carbsDesc:
        filteredTemplates.sort((a, b) => _getTemplateCarbs(provider, b)
            .compareTo(_getTemplateCarbs(provider, a)));
        break;
    }

    final collapsedLimit = 3;
    final isCollapsed = !_templatesExpanded;
    final visible = isCollapsed
        ? filteredTemplates.take(collapsedLimit).toList()
        : filteredTemplates;
    final hasMore = filteredTemplates.length > collapsedLimit;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_surface2, _surface],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: _divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSectionTitle(
                    icon: Icons.menu_book_rounded,
                    title: 'ГОТОВЫЕ БЛЮДА',
                    subtitle: 'Сохранил один раз — добавляй в один тап',
                    color: _accent,
                    compact: true,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${filteredTemplates.length}',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _templateSearchField()),
                const SizedBox(width: 8),
                _templateSortButton(),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _surface2,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _templateViewButton(
                            icon: Icons.view_list_rounded,
                            active: !_showTemplatesGrid,
                            label: 'СПИСОК',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _showTemplatesGrid = false);
                            },
                          ),
                        ),
                        Expanded(
                          child: _templateViewButton(
                            icon: Icons.grid_view_rounded,
                            active: _showTemplatesGrid,
                            label: 'СЕТКА',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _showTemplatesGrid = true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            if (filteredTemplates.isEmpty)
              _buildEmptyTemplates()
            else if (_showTemplatesGrid)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 9,
                  childAspectRatio: 0.98,
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  return _buildTemplateCard(provider, visible[index]);
                },
              )
            else
              Column(
                children: visible
                    .map((t) => _buildTemplateListCard(provider, t))
                    .toList(),
              ),
            if (hasMore) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _templatesExpanded = !_templatesExpanded);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _accent.withOpacity(0.20),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _templatesExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: _accent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _templatesExpanded
                            ? 'СВЕРНУТЬ'
                            : 'ПОКАЗАТЬ ВСЕ (${filteredTemplates.length})',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _templateSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _divider, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          Icon(Icons.search_rounded, color: _textMuted, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (value) =>
                  setState(() => _templatesSearchQuery = value),
              style: TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Найти блюдо…',
                hintStyle: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_templatesSearchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _templatesSearchQuery = '');
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.close_rounded,
                  color: _textMuted,
                  size: 16,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _templateSortButton() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _divider, width: 0.5),
      ),
      child: PopupMenuButton<TemplatesSortMode>(
        tooltip: 'Сортировка',
        offset: const Offset(0, 47),
        color: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(_getSortIcon(), color: _accent, size: 17),
              const SizedBox(width: 5),
              Text(
                _getSortLabel(),
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _textMuted,
                size: 16,
              ),
            ],
          ),
        ),
        onSelected: (mode) {
          HapticFeedback.selectionClick();
          setState(() => _templatesSortMode = mode);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: TemplatesSortMode.name,
            child: Text('📝  По названию'),
          ),
          PopupMenuItem(
            value: TemplatesSortMode.caloriesDesc,
            child: Text('🔥  Калории ↓'),
          ),
          PopupMenuItem(
            value: TemplatesSortMode.caloriesAsc,
            child: Text('🔥  Калории ↑'),
          ),
          PopupMenuItem(
            value: TemplatesSortMode.proteinDesc,
            child: Text('🥩  Белок ↓'),
          ),
          PopupMenuItem(
            value: TemplatesSortMode.fatDesc,
            child: Text('🧈  Жиры ↓'),
          ),
          PopupMenuItem(
            value: TemplatesSortMode.carbsDesc,
            child: Text('🍞  Углеводы ↓'),
          ),
        ],
      ),
    );
  }

  Widget _templateViewButton({
    required IconData icon,
    required bool active,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 7),
        decoration: BoxDecoration(
          color: active ? _accent.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? _accent : _textMuted, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? _accent : _textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTemplates() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 31),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _textPrimary.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🍽️', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 10),
          Text(
            'Ничего не найдено',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateListCard(
      NutritionProvider provider, MealTemplate template) {
    final calories = _getTemplateCalories(provider, template);
    final protein = _getTemplateProtein(provider, template);
    final fat = _getTemplateFat(provider, template);
    final carbs = _getTemplateCarbs(provider, template);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _showTemplateDetails(provider, template);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _divider, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _Power.softGlow(_accent, strength: 0.15),
                ),
                alignment: Alignment.center,
                child: const Text('🍱', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _templateSmallStat(
                            '🔥', '${calories.round()}', _accent),
                        const SizedBox(width: 7),
                        _templateSmallStat(
                            '🥩', '${protein.round()}Г', _green),
                        const SizedBox(width: 7),
                        _templateSmallStat('🧈', '${fat.round()}Г', _pink),
                        const SizedBox(width: 7),
                        _templateSmallStat(
                            '🍞', '${carbs.round()}Г', _yellow),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _surface2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _textMuted,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _templateSmallStat(String emoji, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 9)),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
      NutritionProvider provider, MealTemplate template) {
    final calories = _getTemplateCalories(provider, template);
    final protein = _getTemplateProtein(provider, template);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showTemplateDetails(provider, template);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_surface2, _surface],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child:
                  const Text('🍱', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    template.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${template.items.length} ИНГРЕДИЕНТОВ',
              style: TextStyle(
                color: _textMuted,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '🔥 ${calories.round()}',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '🥩 ${protein.round()}Г',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getTemplateCalories(
      NutritionProvider provider, MealTemplate template) {
    return template.items.fold<double>(0, (sum, item) {
      final product = _findProduct(provider, item.productId);
      if (product == null) return sum;
      return sum + product.forGrams(item.grams).calories;
    });
  }

  double _getTemplateProtein(
      NutritionProvider provider, MealTemplate template) {
    return template.items.fold<double>(0, (sum, item) {
      final product = _findProduct(provider, item.productId);
      if (product == null) return sum;
      return sum + product.forGrams(item.grams).protein;
    });
  }

  double _getTemplateFat(
      NutritionProvider provider, MealTemplate template) {
    return template.items.fold<double>(0, (sum, item) {
      final product = _findProduct(provider, item.productId);
      if (product == null) return sum;
      return sum + product.forGrams(item.grams).fat;
    });
  }

  double _getTemplateCarbs(
      NutritionProvider provider, MealTemplate template) {
    return template.items.fold<double>(0, (sum, item) {
      final product = _findProduct(provider, item.productId);
      if (product == null) return sum;
      return sum + product.forGrams(item.grams).carbs;
    });
  }

  IconData _getSortIcon() {
    switch (_templatesSortMode) {
      case TemplatesSortMode.name:
        return Icons.sort_by_alpha_rounded;
      case TemplatesSortMode.caloriesDesc:
      case TemplatesSortMode.caloriesAsc:
        return Icons.local_fire_department_rounded;
      case TemplatesSortMode.proteinDesc:
        return Icons.fitness_center_rounded;
      case TemplatesSortMode.fatDesc:
        return Icons.water_drop_rounded;
      case TemplatesSortMode.carbsDesc:
        return Icons.grain_rounded;
    }
  }

  String _getSortLabel() {
    switch (_templatesSortMode) {
      case TemplatesSortMode.name:
        return 'А-Я';
      case TemplatesSortMode.caloriesDesc:
        return '🔥 ↓';
      case TemplatesSortMode.caloriesAsc:
        return '🔥 ↑';
      case TemplatesSortMode.proteinDesc:
        return 'Б ↓';
      case TemplatesSortMode.fatDesc:
        return 'Ж ↓';
      case TemplatesSortMode.carbsDesc:
        return 'У ↓';
    }
  }

  // =============================================================
  // TEMPLATE DETAILS
  // =============================================================

  void _showTemplateDetails(
      NutritionProvider provider, MealTemplate template) {
    final totalCalories = _getTemplateCalories(provider, template);
    final totalProtein = _getTemplateProtein(provider, template);
    final totalFat = _getTemplateFat(provider, template);
    final totalCarbs = _getTemplateCarbs(provider, template);

    MealType selectedMeal = MealType.suggestForNow();
    final accent = _accent;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.84,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _textMuted,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: _Power.softGlow(accent,
                                        strength: 0.2),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('🍱',
                                      style: TextStyle(fontSize: 28)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        template.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${template.items.length} ИНГРЕДИЕНТОВ',
                                        style: TextStyle(
                                          color: _textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: _surface2,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  _templateMacro(
                                    '🔥',
                                    '${totalCalories.round()}',
                                    'ККАЛ',
                                    accent,
                                  ),
                                  _templateMacro(
                                    '🥩',
                                    totalProtein.toStringAsFixed(1),
                                    'Г',
                                    _green,
                                  ),
                                  _templateMacro(
                                    '🧈',
                                    totalFat.toStringAsFixed(1),
                                    'Г',
                                    _pink,
                                  ),
                                  _templateMacro(
                                    '🍞',
                                    totalCarbs.toStringAsFixed(1),
                                    'Г',
                                    _yellow,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 21),
                            Text(
                              'ИНГРЕДИЕНТЫ',
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 9),
                            ...template.items.map((item) {
                              final product =
                              _findProduct(provider, item.productId);
                              final macros = product != null
                                  ? product.forGrams(item.grams)
                                  : (
                              calories: 0.0,
                              protein: 0.0,
                              fat: 0.0,
                              carbs: 0.0,
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _surface2,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      product?.categoryEmoji ?? '🍽️',
                                      style:
                                      const TextStyle(fontSize: 17),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              color: _textPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${item.grams.round()} Г',
                                            style: TextStyle(
                                              color: _textMuted,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${macros.calories.round()}',
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 18),
                            Text(
                              'ДОБАВИТЬ КАК',
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: MealType.values.map((meal) {
                                final selected = selectedMeal == meal;
                                return ChoiceChip(
                                  label: Text(
                                    '${meal.emoji} ${meal.displayName}',
                                    style: TextStyle(
                                      color: selected
                                          ? _Power.darkBg
                                          : _textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  selected: selected,
                                  selectedColor: accent,
                                  backgroundColor: _surface2,
                                  side: BorderSide(
                                    color:
                                    selected ? accent : _divider,
                                    width: 0.5,
                                  ),
                                  onSelected: (_) {
                                    HapticFeedback.selectionClick();
                                    setModalState(() {
                                      selectedMeal = meal;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 53,
                              child: ElevatedButton(
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(sheetContext);

                                  await provider.addTemplateAsMeal(
                                    template,
                                    selectedMeal,
                                    date: _selectedDate,
                                  );

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${template.name} добавлен как блюдо'),
                                      backgroundColor: _green,
                                      behavior:
                                      SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(14),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: _Power.darkBg,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'ДОБАВИТЬ В ДНЕВНИК',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _templateMacro(
      String emoji, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: TextStyle(
              color: _textMuted,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // QUICK ADD
  // =============================================================

  Widget _buildQuickAdd(NutritionProvider provider) {
    final recent = provider.getRecentProducts(limit: 8);
    if (recent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.bolt_rounded,
            title: 'БЫСТРЫЙ ВВОД',
            subtitle: 'Добавляй часто используемые продукты',
            color: _yellow,
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return _quickChip(provider, recent[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(NutritionProvider provider, FoodProduct product) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _openAddFood(context, provider, preselected: product);
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _divider, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: _textPrimary.withOpacity(0.035),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                product.categoryEmoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.calories.round()} ККАЛ',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
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

  // =============================================================
  // FAB
  // =============================================================

  Widget _buildFab(BuildContext context, NutritionProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, right: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: _Power.glow(_accent, strength: 0.35, blur: 22),
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _openAddFood(context, provider);
        },
        backgroundColor: _accent,
        foregroundColor: _Power.darkBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        icon: const Icon(Icons.add_rounded, size: 23),
        label: const Text(
          'ДОБАВИТЬ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // =============================================================
  // NAVIGATION
  // =============================================================

  void _openAddFood(
      BuildContext context,
      NutritionProvider provider, {
        MealType? meal,
        FoodProduct? preselected,
      }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFoodScreen(
          isDark: widget.isDark,
          date: _selectedDate,
          initialMeal: meal,
          preselectedProduct: preselected,
          nutritionProvider: provider,
        ),
      ),
    );
  }

  void _openProfileSetup(BuildContext context) {
    final provider = context.read<NutritionProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(
          isDark: widget.isDark,
          provider: provider,
        ),
      ),
    );
  }

  // =============================================================
  // GOALS EDITOR
  // =============================================================

  void _showGoalsEditor(BuildContext context) {
    final provider = context.read<NutritionProvider>();
    final goals = provider.getGoalsForDate(_selectedDate);
    final accent = _accent;

    final caloriesController =
    TextEditingController(text: goals.calories.toStringAsFixed(0));
    final proteinController =
    TextEditingController(text: goals.protein.toStringAsFixed(0));
    final fatController =
    TextEditingController(text: goals.fat.toStringAsFixed(0));
    final carbsController =
    TextEditingController(text: goals.carbs.toStringAsFixed(0));
    final waterController =
    TextEditingController(text: goals.waterMl.toString());

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _Power.softGlow(accent, strength: 0.15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.track_changes_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'ЦЕЛИ НА ДЕНЬ',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _goalField('🔥 Калории (ккал)', caloriesController),
                const SizedBox(height: 8),
                _goalField('🥩 Белки (г)', proteinController),
                const SizedBox(height: 8),
                _goalField('🧈 Жиры (г)', fatController),
                const SizedBox(height: 8),
                _goalField('🍞 Углеводы (г)', carbsController),
                const SizedBox(height: 8),
                _goalField('💧 Вода (мл)', waterController),
              ],
            ),
          ),
          actionsPadding:
          const EdgeInsets.fromLTRB(18, 0, 18, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final updatedGoals = NutritionGoals(
                  id: goals.id,
                  date: goals.date,
                  calories:
                  double.tryParse(caloriesController.text) ??
                      goals.calories,
                  protein:
                  double.tryParse(proteinController.text) ??
                      goals.protein,
                  fat: double.tryParse(fatController.text) ?? goals.fat,
                  carbs: double.tryParse(carbsController.text) ??
                      goals.carbs,
                  waterMl: int.tryParse(waterController.text) ??
                      goals.waterMl,
                );

                Navigator.pop(dialogContext);
                await provider.updateGoals(updatedGoals);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Цели обновлены'),
                    backgroundColor: _green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: _Power.darkBg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 11),
              ),
              child: const Text(
                'СОХРАНИТЬ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _goalField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType:
      const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: _textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _textMuted,
          fontSize: 11,
        ),
        filled: true,
        fillColor: _surface2,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent.withOpacity(0.45)),
        ),
      ),
    );
  }

  // =============================================================
  // HELPERS
  // =============================================================

  String _formatDateFull(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

// =============================================================
// GROUP MODEL
// =============================================================

class _MealItemGroup {
  final String? templateId;
  final String? templateName;
  final List<FoodDiaryEntry> entries;

  _MealItemGroup({
    this.templateId,
    this.templateName,
    required this.entries,
  });
}

// =============================================================
// SORT
// =============================================================

enum TemplatesSortMode {
  name,
  caloriesDesc,
  caloriesAsc,
  proteinDesc,
  fatDesc,
  carbsDesc,
}

// =============================================================
// HORIZONTAL GLOW RAY
// =============================================================

class _GlowRayPainter extends CustomPainter {
  final Color color;
  final double widthFactor;
  final Color backgroundColor;
  final double coreWidth;
  final double glowWidth;

  _GlowRayPainter({
    required this.color,
    required this.widthFactor,
    required this.backgroundColor,
    this.coreWidth = 2.8,
    this.glowWidth = 9.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    if (backgroundColor != Colors.transparent) {
      final bgPaint = Paint()
        ..color = backgroundColor
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        bgPaint,
      );
    }

    final totalWidth = size.width * widthFactor;
    final left = (size.width - totalWidth) / 2;
    final right = left + totalWidth;

    final rect = Rect.fromLTRB(left, 0, right, size.height);

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withOpacity(0),
        color.withOpacity(0.05),
        color.withOpacity(0.35),
        color.withOpacity(0.92),
        color,
        color.withOpacity(0.92),
        color.withOpacity(0.35),
        color.withOpacity(0.05),
        color.withOpacity(0),
      ],
      stops: const [0, 0.16, 0.32, 0.43, 0.50, 0.57, 0.68, 0.84, 1],
    );

    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawLine(
      Offset(left, centerY),
      Offset(right, centerY),
      glowPaint,
    );

    final corePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = coreWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(left, centerY),
      Offset(right, centerY),
      corePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowRayPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.widthFactor != widthFactor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.coreWidth != coreWidth ||
        oldDelegate.glowWidth != glowWidth;
  }
}

// =============================================================
// VERTICAL GLOW RAY
// =============================================================

class _VerticalGlowRayPainter extends CustomPainter {
  final Color color;
  final double heightFactor;
  final Color backgroundColor;
  final double coreWidth;
  final double glowWidth;

  _VerticalGlowRayPainter({
    required this.color,
    required this.heightFactor,
    required this.backgroundColor,
    this.coreWidth = 2.4,
    this.glowWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final totalHeight = size.height * heightFactor;
    final top = (size.height - totalHeight) / 2;
    final bottom = top + totalHeight;

    final rect = Rect.fromLTRB(0, top, size.width, bottom);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0),
        color.withOpacity(0.05),
        color.withOpacity(0.35),
        color.withOpacity(0.92),
        color,
        color.withOpacity(0.92),
        color.withOpacity(0.35),
        color.withOpacity(0.05),
        color.withOpacity(0),
      ],
      stops: const [0, 0.16, 0.32, 0.43, 0.50, 0.57, 0.68, 0.84, 1],
    );

    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawLine(
      Offset(centerX, top),
      Offset(centerX, bottom),
      glowPaint,
    );

    final corePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = coreWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, top),
      Offset(centerX, bottom),
      corePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VerticalGlowRayPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.heightFactor != heightFactor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.coreWidth != coreWidth ||
        oldDelegate.glowWidth != glowWidth;
  }
}

// =============================================================
// HERO GAUGE
// =============================================================

class _HeroGaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color backgroundColor;

  _HeroGaugePainter({
    required this.percent,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 9;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi * 0.76;
    const totalSweep = math.pi * 1.52;

    final circleRect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    canvas.drawArc(
      circleRect,
      startAngle,
      totalSweep,
      false,
      backgroundPaint,
    );

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: totalSweep,
        colors: [color.withOpacity(0.20), color],
      ).createShader(circleRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final sweep = totalSweep * percent.clamp(0.0, 1.0);

    canvas.drawArc(
      circleRect,
      startAngle,
      sweep,
      false,
      progressPaint,
    );

    if (percent > 0 && percent < 1) {
      final angle = startAngle + sweep;
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawCircle(
        dotCenter,
        4,
        Paint()..color = color,
      );

      canvas.drawCircle(
        dotCenter,
        9,
        Paint()
          ..color = color.withOpacity(0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroGaugePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}