// features/fitness/ui/screens/workout_log_screen.dart
// 🆕 v16: format-aware отображение логов (сила / кардио / бокс / статика)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../nutrition/providers/nutrition_provider.dart';
import '../../../../nutrition/models/nutrition_models.dart';
import '../../../../nutrition/ui/screens/fuel_dashboard_screen.dart';
import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';

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

class WorkoutLogScreen extends StatefulWidget {
  final bool isDark;

  const WorkoutLogScreen({
    super.key,
    this.isDark = false,
  });

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen>
    with TickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  NutritionProvider? _nutritionProvider;
  Future<NutritionProvider>? _nutritionFuture;

  final List<String> _moodEmojis = [
    '😫', '😩', '😐', '🙂', '😊', '😁', '🤩', '🔥', '💪', '🚀'
  ];

  final List<String> _emptyStateQuotes = [
    'Каждый день — новая возможность',
    'Сегодня ты можешь всё',
    'Начни с малого',
    'Прогресс начинается с шага',
    'Верь в себя',
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _sheetController;
  late Animation<double> _sheetAnimation;

  bool _isSheetOpen = false;
  final double _sheetCollapsedHeight = 0.45;
  final double _sheetExpandedHeight = 0.85;

  double _dragOffset = 0;
  bool _isDragging = false;
  double _dragStartY = 0;
  double _currentSheetHeight = 0;
  bool _isAnimating = false;

  final Map<String, bool> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();

    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _sheetAnimation = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOutQuart,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<NutritionProvider> _getNutritionProvider() {
    _nutritionFuture ??= _initNutritionProvider();
    return _nutritionFuture!;
  }

  Future<NutritionProvider> _initNutritionProvider() async {
    if (_nutritionProvider != null) return _nutritionProvider!;
    _nutritionProvider = NutritionProvider();
    await _nutritionProvider!.init();
    return _nutritionProvider!;
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 ХЕЛПЕРЫ МЕТРИК
  // ══════════════════════════════════════════════════════════

  /// Доминирующая метрика лога для показа «главной цифры».
  ({String label, String value, IconData icon, Color color}) _metricPrimaryBadge(
      WorkoutLog log) {
    final kg = log.metricValue('kg');
    final km = log.metricValue('km');
    final rounds = log.metricValue('rounds');
    final sec = log.metricValue('sec');

    if (km > 0) {
      return (
      label: 'КМ',
      value: km.toStringAsFixed(km >= 10 ? 0 : 2),
      icon: Icons.directions_run_rounded,
      color: _Power.ice,
      );
    }
    if (rounds > 0) {
      return (
      label: 'РАУНД',
      value: rounds.toStringAsFixed(0),
      icon: Icons.sports_mma_rounded,
      color: _Power.volt,
      );
    }
    if (kg > 0) {
      return (
      label: 'КГ',
      value: kg.toStringAsFixed(0),
      icon: Icons.fitness_center_rounded,
      color: _Power.plasma,
      );
    }
    if (sec > 0) {
      return (
      label: 'СЕК',
      value: sec.toStringAsFixed(0),
      icon: Icons.timer_rounded,
      color: _Power.lime,
      );
    }
    return (
    label: '—',
    value: '0',
    icon: Icons.remove_rounded,
    color: _Power.textTertiary(true),
    );
  }

  /// Все непустые метрики лога для детального отображения.
  List<({String label, String value, IconData icon, Color color})> _metricBadges(
      WorkoutLog log) {
    final result = <({String label, String value, IconData icon, Color color})>[];
    final kg = log.metricValue('kg');
    final km = log.metricValue('km');
    final sec = log.metricValue('sec');
    final rounds = log.metricValue('rounds');
    final punches = log.metricValue('punches');
    final kcal = log.metricValue('kcal');
    final reps = log.metricValue('reps');

    if (kg > 0) {
      result.add((
      label: 'КГ',
      value: kg.toStringAsFixed(0),
      icon: Icons.fitness_center_rounded,
      color: _Power.plasma,
      ));
    }
    if (km > 0) {
      result.add((
      label: 'КМ',
      value: km.toStringAsFixed(km >= 10 ? 1 : 2),
      icon: Icons.directions_run_rounded,
      color: _Power.ice,
      ));
    }
    if (rounds > 0) {
      result.add((
      label: 'РАУНД',
      value: rounds.toStringAsFixed(0),
      icon: Icons.sports_mma_rounded,
      color: _Power.volt,
      ));
    }
    if (sec > 0) {
      result.add((
      label: 'СЕК',
      value: sec.toStringAsFixed(0),
      icon: Icons.timer_rounded,
      color: _Power.lime,
      ));
    }
    if (punches > 0) {
      result.add((
      label: 'УДАР',
      value: punches.toStringAsFixed(0),
      icon: Icons.sports_mma_rounded,
      color: _Power.magma,
      ));
    }
    if (kcal > 0) {
      result.add((
      label: 'ККАЛ',
      value: kcal.toStringAsFixed(0),
      icon: Icons.local_fire_department_rounded,
      color: _Power.magma,
      ));
    }
    if (reps > 0 && kg == 0) {
      result.add((
      label: 'ПОВТ',
      value: reps.toStringAsFixed(0),
      icon: Icons.repeat_rounded,
      color: _Power.volt,
      ));
    }
    return result;
  }

  /// Резолвит формат WorkoutExercise, используя exercises из provider.
  ExerciseFormat _resolveFormat(
      WorkoutExercise we,
      FitnessProvider provider,
      ) {
    final ex = provider.exercises.firstWhere(
          (e) => e.id == we.exerciseId,
      orElse: () => Exercise(id: '', name: ''),
    );
    return FitnessHelpers.resolveFormat(we, ex.id.isEmpty ? null : ex);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = context.watch<FitnessProvider>();
    final logs = _getLogsForMonth(provider);

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(isDark, provider),
                    _buildMonthNavigator(isDark),
                    Expanded(child: _buildCalendarGrid(isDark, logs)),
                  ],
                ),
                if (_isSheetOpen)
                  GestureDetector(
                    onTap: _closeSheet,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                _buildBottomSheet(isDark, provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // HEADER
  // =====================================================================

  Widget _buildHeader(bool isDark, FitnessProvider provider) {
    final monthLogs = _getLogsForMonth(provider);
    final completedCount =
        monthLogs.where((l) => l.status == WorkoutDayStatus.completed).length;
    final totalWorkouts = monthLogs.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: _Power.textPrimary(isDark),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ЖУРНАЛ',
                  style: TextStyle(
                    color: _Power.volt,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Тренировки',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.1,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
              ],
            ),
          ),
          if (totalWorkouts > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: _Power.volt.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$completedCount/$totalWorkouts',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  height: 1,
                  color: _Power.volt,
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              HapticFeedback.selectionClick();
              final nutrition = await _getNutritionProvider();
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: nutrition,
                    child: const FuelDashboardScreen(isDark: true),
                  ),
                ),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _Power.ice.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: _Power.softGlow(_Power.ice, strength: 0.2),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: _Power.ice,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _showMonthPicker(context);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: _Power.textPrimary(isDark),
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // MONTH NAVIGATOR
  // =====================================================================

  Widget _buildMonthNavigator(bool isDark) {
    const monthNames = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _Power.card(isDark),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: _Power.separator(isDark),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: _Power.textSecondary(isDark),
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _showMonthPicker(context);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _Power.card(isDark),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: _Power.separator(isDark),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: _Power.textTertiary(isDark),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _Power.card(isDark),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: _Power.separator(isDark),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: _Power.textSecondary(isDark),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // CALENDAR GRID
  // =====================================================================

  Widget _buildCalendarGrid(bool isDark, List<WorkoutLog> monthLogs) {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    ).weekday;

    final Map<int, List<WorkoutLog>> logsByDay = {};
    for (final log in monthLogs) {
      final day = log.date.day;
      logsByDay[day] = [...logsByDay[day] ?? [], log];
    }

    const dayNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    final today = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == today.year &&
        _selectedMonth.month == today.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            children: dayNames.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: _Power.textTertiary(isDark),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1.0,
              ),
              itemCount: firstWeekday - 1 + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) {
                  return const SizedBox();
                }

                final day = index - (firstWeekday - 2);
                final dayLogs = logsByDay[day] ?? [];
                final isToday = isCurrentMonth && day == today.day;
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == _selectedMonth.year &&
                    _selectedDate!.month == _selectedMonth.month &&
                    _selectedDate!.day == day;

                final hasCompleted = dayLogs
                    .any((l) => l.status == WorkoutDayStatus.completed);
                final hasSkipped =
                dayLogs.any((l) => l.status == WorkoutDayStatus.skipped);

                Color accent;
                if (isSelected) {
                  accent = _Power.volt;
                } else if (isToday) {
                  accent = _Power.volt;
                } else if (hasCompleted && hasSkipped) {
                  accent = _Power.magma;
                } else if (hasCompleted) {
                  accent = _Power.green;
                } else if (hasSkipped) {
                  accent = _Power.red;
                } else {
                  accent = _Power.textTertiary(isDark);
                }

                final hasLogs = dayLogs.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month,
                        day,
                      );
                      _openSheet();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _Power.volt
                          : hasLogs
                          ? accent.withOpacity(0.12)
                          : _Power.card(isDark),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: isSelected
                            ? _Power.volt
                            : isToday
                            ? _Power.volt.withOpacity(0.6)
                            : hasLogs
                            ? accent.withOpacity(0.3)
                            : _Power.separator(isDark),
                        width: isToday && !isSelected ? 1.2 : 0.5,
                      ),
                      boxShadow: isSelected
                          ? _Power.softGlow(_Power.volt, strength: 0.4)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isToday || isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1,
                              color: isSelected
                                  ? Colors.white
                                  : hasLogs
                                  ? accent
                                  : _Power.textPrimary(isDark),
                            ),
                          ),
                        ),
                        if (hasLogs)
                          Positioned(
                            bottom: 4,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : hasCompleted
                                        ? _Power.green
                                        : hasSkipped
                                        ? _Power.red
                                        : _Power.textTertiary(isDark),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (dayLogs.length > 1)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.7)
                                          : dayLogs.length > 2
                                          ? _Power.volt
                                          : _Power.textTertiary(isDark),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (dayLogs.length > 2)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.7)
                                          : _Power.ice,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(isDark, _Power.green, 'ВЫПОЛНЕНО'),
              const SizedBox(width: 12),
              _buildLegendItem(isDark, _Power.red, 'ПРОПУЩЕНО'),
              const SizedBox(width: 12),
              _buildLegendItem(isDark, _Power.volt, 'НЕСКОЛЬКО'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(bool isDark, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: _Power.softGlow(color, strength: 0.4),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: _Power.textTertiary(isDark),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // BOTTOM SHEET
  // =====================================================================

  Widget _buildBottomSheet(bool isDark, FitnessProvider provider) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        double targetHeight;
        if (_isDragging) {
          final baseHeight = _isSheetOpen
              ? screenHeight * _sheetExpandedHeight
              : screenHeight * _sheetCollapsedHeight;
          targetHeight = (baseHeight - _dragOffset).clamp(
            screenHeight * _sheetCollapsedHeight,
            screenHeight * _sheetExpandedHeight,
          );
        } else {
          targetHeight = _isSheetOpen
              ? screenHeight * _sheetExpandedHeight
              : screenHeight * _sheetCollapsedHeight;
        }

        final animatedHeight = _isDragging || _isAnimating
            ? targetHeight
            : _sheetAnimation.value * targetHeight +
            (1 - _sheetAnimation.value) *
                (_isSheetOpen
                    ? screenHeight * _sheetExpandedHeight
                    : screenHeight * _sheetCollapsedHeight);

        _currentSheetHeight = animatedHeight;

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: animatedHeight,
            decoration: BoxDecoration(
              color: _Power.card(isDark),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDraggableHandle(isDark),
                _buildSheetHeader(isDark),
                Expanded(
                  child: _buildSheetContent(isDark, provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableHandle(bool isDark) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
        _dragOffset = 0;
        _isDragging = true;
        _isAnimating = false;
      },
      onVerticalDragUpdate: (details) {
        final delta = details.globalPosition.dy - _dragStartY;
        _dragOffset = delta;
        setState(() {});
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        _isDragging = false;

        final screenHeight = MediaQuery.of(context).size.height;
        final currentHeight = _isSheetOpen
            ? screenHeight * _sheetExpandedHeight - _dragOffset
            : screenHeight * _sheetCollapsedHeight - _dragOffset;

        final midPoint = (screenHeight * _sheetCollapsedHeight +
            screenHeight * _sheetExpandedHeight) /
            2;

        bool shouldOpen;
        if (velocity.abs() > 300) {
          shouldOpen = velocity < 0;
        } else {
          shouldOpen = currentHeight > midPoint;
        }

        if (shouldOpen) {
          _openSheet();
        } else {
          _closeSheet();
        }

        _dragOffset = 0;
        Future.delayed(const Duration(milliseconds: 500), () {
          _isAnimating = false;
        });
        setState(() {});
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: _Power.textTertiary(isDark),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _isSheetOpen ? 'СВЕРНУТЬ' : 'ПОТЯНИТЕ ВВЕРХ',
                key: ValueKey(_isSheetOpen),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: _Power.textTertiary(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _Power.volt.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _Power.softGlow(_Power.volt, strength: 0.25),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.calendar_today_rounded,
              color: _Power.volt,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDate != null
                      ? _formatDateFull(_selectedDate!).toUpperCase()
                      : 'ВЫБЕРИТЕ ДЕНЬ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    height: 1.1,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
              ],
            ),
          ),
          if (_isSheetOpen)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _closeSheet();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: _Power.textPrimary(isDark),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openSheet() {
    if (!_isSheetOpen) {
      setState(() {
        _isSheetOpen = true;
        _isAnimating = true;
        _sheetController.forward(from: 0);
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        _isAnimating = false;
      });
    }
  }

  void _closeSheet() {
    if (_isSheetOpen) {
      setState(() {
        _isSheetOpen = false;
        _isAnimating = true;
        _sheetController.reverse(from: 1);
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        _isAnimating = false;
      });
    }
  }

  Widget _buildSheetContent(bool isDark, FitnessProvider provider) {
    if (_selectedDate == null) {
      return Center(
        child: Text(
          'Нажмите на день',
          style: TextStyle(
            color: _Power.textTertiary(isDark),
            fontSize: 13,
          ),
        ),
      );
    }

    return _buildDayContent(isDark, provider, _selectedDate!);
  }

  // =====================================================================
  // DAY CONTENT
  // =====================================================================

  Widget _buildDayContent(
      bool isDark, FitnessProvider provider, DateTime date) {
    final logs = provider.getLogsForDate(date);
    final dayKey = 'stats_${date.year}_${date.month}_${date.day}';

    final dayWellbeing = provider.wellbeingNotes
        .where((n) =>
    n.date.year == date.year &&
        n.date.month == date.month &&
        n.date.day == date.day)
        .toList();

    final dayPhotos = provider.photos
        .where((p) =>
    p.date.year == date.year &&
        p.date.month == date.month &&
        p.date.day == date.day)
        .toList();

    final hasWellbeing = dayWellbeing.isNotEmpty;
    final hasPhotos = dayPhotos.isNotEmpty;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _getDaySteps(dayKey),
        _getNutritionProvider(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_Power.volt),
            ),
          );
        }

        final stepsData = snapshot.data![0] as Map<String, int>;
        final nutrition = snapshot.data![1] as NutritionProvider;

        final steps = stepsData['steps'] ?? 0;
        final distanceKm = (steps * 0.75) / 1000.0;
        final stepsCalories = (steps * 0.04).round();

        final nutritionSummary = nutrition.getSummaryForDate(date);
        final nutritionGoals = nutrition.getGoalsForDate(date);

        final hasAnyData = logs.isNotEmpty ||
            steps > 0 ||
            nutritionSummary.entriesCount > 0 ||
            hasWellbeing ||
            hasPhotos;

        if (!hasAnyData) {
          return _buildEmptyDayState(isDark, date);
        }

        final totalExercises =
        logs.fold(0, (sum, l) => sum + l.exercisesLog.length);
        final completedCount =
            logs.where((l) => l.status == WorkoutDayStatus.completed).length;

        final sections = <Widget>[];

        sections.add(
          _buildDaySummary(
            isDark,
            logs,
            completedCount,
            totalExercises,
            steps,
            distanceKm,
            stepsCalories,
            nutritionSummary,
            nutritionGoals,
            nutrition,
          ),
        );

        if (hasWellbeing) {
          sections.add(const SizedBox(height: 12));
          sections.add(_buildDayWellbeingCard(isDark, dayWellbeing.first));
        }

        if (hasPhotos) {
          sections.add(const SizedBox(height: 12));
          sections.add(_buildDayPhotosGrid(isDark, dayPhotos));
        }

        if (logs.isNotEmpty) {
          sections.add(const SizedBox(height: 16));
          sections.add(_buildSectionLabel(isDark, 'ТРЕНИРОВКИ', logs.length));
          sections.add(const SizedBox(height: 8));
          for (final log in logs) {
            sections.add(_buildExpansionLogCard(isDark, log, provider));
          }
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          physics: const BouncingScrollPhysics(),
          children: sections,
        );
      },
    );
  }

  Widget _buildSectionLabel(bool isDark, String label, int count) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _Power.volt,
            borderRadius: BorderRadius.circular(2),
            boxShadow: _Power.softGlow(_Power.volt, strength: 0.6),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
            color: _Power.textPrimary(isDark),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _Power.volt.withOpacity(0.14),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              height: 1,
              color: _Power.volt,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // EMPTY STATE
  // =====================================================================

  Widget _buildEmptyDayState(bool isDark, DateTime date) {
    final randomQuote = _emptyStateQuotes[date.day % _emptyStateQuotes.length];

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _Power.volt.withOpacity(0.10),
                  shape: BoxShape.circle,
                  boxShadow: _Power.softGlow(_Power.volt, strength: 0.15),
                ),
                child: Center(
                  child: Text(
                    ['🌟', '💪', '🔥', '🏆', '⭐'][date.day % 5],
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'НЕТ ДАННЫХ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  color: _Power.volt,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Пустой день',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: _Power.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                randomQuote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: _Power.textSecondary(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // WELLBEING CARD (без изменений)
  // =====================================================================

  Widget _buildDayWellbeingCard(bool isDark, WellbeingNote note) {
    final energyEmoji = note.energyLevel >= 1 && note.energyLevel <= 10
        ? _moodEmojis[note.energyLevel - 1]
        : '🙂';
    final sleepEmoji = note.sleepQuality >= 1 && note.sleepQuality <= 10
        ? _moodEmojis[note.sleepQuality - 1]
        : '🙂';
    final motivationEmoji =
    note.motivationLevel >= 1 && note.motivationLevel <= 10
        ? _moodEmojis[note.motivationLevel - 1]
        : '🙂';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _Power.green.withOpacity(0.10),
            _Power.green.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _Power.green.withOpacity(0.25),
          width: 0.8,
        ),
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
                  color: _Power.green.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow:
                  _Power.softGlow(_Power.green, strength: 0.2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: _Power.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'САМОЧУВСТВИЕ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: _Power.green,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _Power.card2(isDark),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${note.date.hour}:${note.date.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: _Power.textSecondary(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSmallMoodStat(
                  energyEmoji, 'ЭНЕРГИЯ', note.energyLevel, isDark),
              _buildSmallMoodStat(sleepEmoji, 'СОН', note.sleepQuality, isDark),
              _buildSmallMoodStat(
                  motivationEmoji, 'МОТИВ', note.motivationLevel, isDark),
            ],
          ),
          if (note.painAreas.isNotEmpty &&
              !note.painAreas.contains('Нет болей')) ...[
            const SizedBox(height: 12),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _Power.volt.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _Power.volt.withOpacity(0.25),
                  width: 0.6,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.healing_rounded,
                    color: _Power.volt,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'БОЛИ: ${note.painAreas.join(" • ").toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: _Power.volt,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (note.notes != null && note.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _Power.card(isDark).withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💭', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: _Power.textSecondary(isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallMoodStat(
      String emoji, String label, int value, bool isDark) {
    final color = _getMoodColor(value);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: _Power.softGlow(color, strength: 0.2),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 6),
          Text(
            '$value/10',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              height: 1,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: _Power.textTertiary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(int value) {
    if (value <= 3) return _Power.red;
    if (value <= 5) return _Power.volt;
    if (value <= 7) return _Power.plasma;
    return _Power.green;
  }

  // =====================================================================
  // PHOTOS GRID (без изменений)
  // =====================================================================

  Widget _buildDayPhotosGrid(bool isDark, List<FitnessPhoto> photos) {
    final displayPhotos = photos.take(4).toList();
    final remainingCount = photos.length - displayPhotos.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _Power.plasma.withOpacity(0.10),
            _Power.plasma.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _Power.plasma.withOpacity(0.25),
          width: 0.8,
        ),
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
                  color: _Power.plasma.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow:
                  _Power.softGlow(_Power.plasma, strength: 0.2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: _Power.plasma,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'ФОТО ДНЯ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: _Power.plasma,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _Power.plasma.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${photos.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: _Power.plasma,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: displayPhotos.length == 1 ? 1 : 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: displayPhotos.length == 1 ? 1.8 : 1.0,
            ),
            itemCount: displayPhotos.length,
            itemBuilder: (context, index) {
              final photo = displayPhotos[index];
              return _buildSmallPhotoTile(isDark, photo);
            },
          ),
          if (remainingCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+ ЕЩЁ $remainingCount',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: _Power.textTertiary(isDark),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmallPhotoTile(bool isDark, FitnessPhoto photo) {
    final file = File(photo.imageUrl);
    final hasFile = file.existsSync();

    return GestureDetector(
      onTap: () {
        if (hasFile) {
          _showFullScreenPhoto(context, file);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _Power.separator(isDark),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              hasFile
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                color: _Power.card2(isDark),
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.grey,
                  size: 24,
                ),
              ),
              if (photo.label != null && photo.label!.isNotEmpty)
                Positioned(
                  bottom: 6,
                  left: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      photo.label!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 🆕 DAY SUMMARY — мультиметрики (кг / км / раунды / сек)
  // ══════════════════════════════════════════════════════════════════

  Widget _buildDaySummary(
      bool isDark,
      List<WorkoutLog> logs,
      int completed,
      int totalExercises,
      int steps,
      double distanceKm,
      int calories,
      DailyNutritionSummary nutrition,
      NutritionGoals goals,
      NutritionProvider nutritionProvider,
      ) {
    final hasNutrition = nutrition.entriesCount > 0;
    final hasWorkouts = logs.isNotEmpty;

    // 🆕 Суммируем все метрики по логам дня
    final totalKg = logs.fold<double>(0, (s, l) => s + l.metricValue('kg'));
    final totalKm = logs.fold<double>(0, (s, l) => s + l.metricValue('km'));
    final totalSec = logs.fold<double>(0, (s, l) => s + l.metricValue('sec'));
    final totalRounds =
    logs.fold<double>(0, (s, l) => s + l.metricValue('rounds'));

    // 🆕 Выбираем «главную» метрику дня для замены единого «КГ»
    final dominant = _dominantDayMetric(
        kg: totalKg, km: totalKm, sec: totalSec, rounds: totalRounds);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _Power.volt.withOpacity(0.10),
            _Power.volt.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _Power.volt.withOpacity(0.25),
          width: 0.8,
        ),
        boxShadow: _Power.softGlow(_Power.volt, strength: 0.08),
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
                  color: _Power.volt.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow:
                  _Power.softGlow(_Power.volt, strength: 0.2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.insights_rounded,
                  color: _Power.volt,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'СВОДКА ДНЯ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: _Power.volt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSummaryItem(isDark, '👟', '$steps', 'ШАГОВ', _Power.ice),
              _summaryDivider(isDark),
              _buildSummaryItem(
                  isDark, '📏', distanceKm.toStringAsFixed(1), 'КМ', _Power.lime),
              _summaryDivider(isDark),
              _buildSummaryItem(
                  isDark, '🔥', '$calories', 'ККАЛ', _Power.volt),
            ],
          ),
          if (hasWorkouts) ...[
            const SizedBox(height: 14),
            Container(height: 0.5, color: _Power.separator(isDark)),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildSummaryItem(
                    isDark, '🏋️', '${logs.length}', 'ТРЕН.', _Power.volt),
                _summaryDivider(isDark),
                _buildSummaryItem(
                    isDark, '✅', '$completed', 'ГОТОВО', _Power.green),
                _summaryDivider(isDark),
                // 🆕 Мультиметрика вместо жёсткого «КГ»
                _buildSummaryItem(
                  isDark,
                  dominant.icon,
                  dominant.value,
                  dominant.label,
                  dominant.color,
                ),
                _summaryDivider(isDark),
                _buildSummaryItem(
                    isDark, '💪', '$totalExercises', 'УПР', _Power.magma),
              ],
            ),
          ],
          if (hasNutrition) ...[
            const SizedBox(height: 14),
            Container(height: 0.5, color: _Power.separator(isDark)),
            const SizedBox(height: 14),
            _buildCompactNutrition(isDark, nutrition, goals),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: nutritionProvider,
                      child: const FuelDashboardScreen(isDark: true),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _Power.ice.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ПОДРОБНЕЕ О ПИТАНИИ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: _Power.ice,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 14, color: _Power.ice),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🆕 Выбор доминирующей метрики дня (для замены единого «КГ»).
  ({String icon, String value, String label, Color color}) _dominantDayMetric({
    required double kg,
    required double km,
    required double sec,
    required double rounds,
  }) {
    if (km > 0) {
      return (
      icon: '📏',
      value: km.toStringAsFixed(km >= 10 ? 0 : 2),
      label: 'КМ',
      color: _Power.ice,
      );
    }
    if (rounds > 0) {
      return (
      icon: '🥊',
      value: rounds.toStringAsFixed(0),
      label: 'РАУНД',
      color: _Power.volt,
      );
    }
    if (kg > 0) {
      return (
      icon: '📊',
      value: kg.toStringAsFixed(0),
      label: 'КГ',
      color: _Power.plasma,
      );
    }
    if (sec > 0) {
      return (
      icon: '⏱️',
      value: sec.toStringAsFixed(0),
      label: 'СЕК',
      color: _Power.lime,
      );
    }
    return (
    icon: '📊',
    value: '0',
    label: 'КГ',
    color: _Power.plasma,
    );
  }

  Widget _summaryDivider(bool isDark) {
    return Container(
      width: 0.5,
      height: 36,
      color: _Power.separator(isDark),
    );
  }

  Widget _buildSummaryItem(
      bool isDark,
      String emoji,
      String value,
      String label,
      Color color,
      ) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              height: 1,
              color: _Power.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNutrition(
      bool isDark,
      DailyNutritionSummary summary,
      NutritionGoals goals,
      ) {
    final calPercent = summary.percentOf(goals);
    final pPercent = summary.proteinPercentOf(goals);
    final fPercent = summary.fatPercentOf(goals);
    final cPercent = summary.carbsPercentOf(goals);

    return Row(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: calPercent.clamp(0, 1),
                  strokeWidth: 6,
                  backgroundColor: _Power.separator(isDark),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    calPercent > 1 ? _Power.magma : _Power.ice,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${summary.calories.round()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1,
                      color: _Power.textPrimary(isDark),
                    ),
                  ),
                  Text(
                    'ККАЛ',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: _Power.textTertiary(isDark),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              _buildSmallMacro(
                  'Б', summary.protein, goals.protein, pPercent, _Power.lime),
              const SizedBox(height: 6),
              _buildSmallMacro(
                  'Ж', summary.fat, goals.fat, fPercent, _Power.magma),
              const SizedBox(height: 6),
              _buildSmallMacro(
                  'У', summary.carbs, goals.carbs, cPercent, _Power.plasma),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMacro(
      String label,
      double current,
      double goal,
      double percent,
      Color color,
      ) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _Power.separator(false),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${current.round()}/${goal.round()}',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 🆕 EXPANSION LOG CARD — бейдж активности вместо «КГ»
  // ══════════════════════════════════════════════════════════════════

  Widget _buildExpansionLogCard(
      bool isDark, WorkoutLog log, FitnessProvider provider) {
    final isCompleted = log.status == WorkoutDayStatus.completed;
    final cardKey = log.id;
    final accent = isCompleted ? _Power.green : _Power.red;

    _expandedCards.putIfAbsent(cardKey, () => false);

    // 🆕 Бейдж главной метрики (кг / км / раунды)
    final primaryBadge = _metricPrimaryBadge(log);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _Power.separator(isDark),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _expandedCards[cardKey] = !(_expandedCards[cardKey] ?? false);
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow:
                      _Power.softGlow(accent, strength: 0.2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isCompleted
                          ? Icons.fitness_center_rounded
                          : Icons.cancel_rounded,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCompleted ? 'ТРЕНИРОВКА' : 'ПРОПУЩЕНО',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            height: 1,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${log.date.hour}:${log.date.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                height: 1,
                                color: _Power.textPrimary(isDark),
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              // 🆕 Бейдж главной метрики
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryBadge.color
                                      .withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      primaryBadge.icon,
                                      size: 9,
                                      color: primaryBadge.color,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${primaryBadge.value} ${primaryBadge.label}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                        height: 1,
                                        color: primaryBadge.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (log.exercisesLog.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _Power.ice.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${log.exercisesLog.length} УПР',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                    height: 1,
                                    color: _Power.ice,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (log.comment != null &&
                            log.comment!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            log.comment!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: _Power.textSecondary(isDark),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: (_expandedCards[cardKey] ?? false) ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _Power.textTertiary(isDark),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _buildExpandedContent(isDark, log, provider),
            ),
            crossFadeState: (_expandedCards[cardKey] ?? false)
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
      bool isDark, WorkoutLog log, FitnessProvider provider) {
    if (log.status != WorkoutDayStatus.completed) {
      return _buildSkippedContent(isDark, log, provider);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailedStats(isDark, log),
        const SizedBox(height: 10),
        // 🆕 Мультиметрики лога
        _buildLogMetricsRow(isDark, log),
        const SizedBox(height: 12),
        if (log.moodEnergy != null || log.moodNotes != null) ...[
          _buildMoodSection(isDark, log),
          const SizedBox(height: 12),
        ],
        if (log.workoutPhotoPath != null &&
            File(log.workoutPhotoPath!).existsSync()) ...[
          _buildWorkoutPhoto(isDark, log),
          const SizedBox(height: 12),
        ],
        if (log.exercisesLog.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: _Power.volt,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow:
                  _Power.softGlow(_Power.volt, strength: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'УПРАЖНЕНИЯ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: _Power.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...log.exercisesLog.asMap().entries.map((entry) {
            final exercise = entry.value;
            final exerciseData = provider.exercises.firstWhere(
                  (e) => e.id == exercise.exerciseId,
              orElse: () => Exercise(id: '', name: 'Удалено'),
            );
            return _buildDetailedExerciseTile(
                isDark, exercise, exerciseData, provider);
          }),
        ],
        const SizedBox(height: 10),
        _buildCommentField(isDark, log, provider),
      ],
    );
  }

  Widget _buildSkippedContent(
      bool isDark, WorkoutLog log, FitnessProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _Power.plasma.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _Power.plasma.withOpacity(0.25),
              width: 0.6,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _Power.plasma.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.info_rounded,
                  color: _Power.plasma,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Тренировка была пропущена',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildCommentField(isDark, log, provider),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 🆕 DETAILED STATS — 4-я карточка «АКТИВНОСТЬ» (динамическая)
  // ══════════════════════════════════════════════════════════════════

  Widget _buildDetailedStats(bool isDark, WorkoutLog log) {
    final duration = log.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = duration?.inMinutes.remainder(60) ?? 0;

    // 🆕 4-я карточка: доминирующая метрика лога
    final primary = _metricPrimaryBadge(log);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _Power.card2(isDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildDetailStat(
            isDark,
            '⏱️',
            hours > 0 ? '${hours}ч ${minutes}м' : '${minutes}м',
            'ВРЕМЯ',
            _Power.ice,
          ),
          _statDivider(isDark),
          _buildDetailStat(
            isDark,
            '📊',
            log.avgRpe != null ? log.avgRpe!.toStringAsFixed(1) : '--',
            'RPE',
            _Power.plasma,
          ),
          _statDivider(isDark),
          _buildDetailStat(
            isDark,
            '💪',
            '${log.exercisesLog.length}',
            'УПР',
            _Power.lime,
          ),
          _statDivider(isDark),
          // 🆕 Доминирующая метрика (кг / км / раунды / сек)
          _buildDetailStat(
            isDark,
            primary.icon == Icons.fitness_center_rounded
                ? '🏋️'
                : primary.icon == Icons.directions_run_rounded
                ? '🏃'
                : primary.icon == Icons.sports_mma_rounded
                ? '🥊'
                : '⏱️',
            primary.value,
            primary.label,
            primary.color,
          ),
        ],
      ),
    );
  }

  Widget _statDivider(bool isDark) {
    return Container(
      width: 0.5,
      height: 34,
      color: _Power.separator(isDark),
    );
  }

  Widget _buildDetailStat(
      bool isDark,
      String emoji,
      String value,
      String label,
      Color color,
      ) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              height: 1,
              color: _Power.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 🆕 Ряд со ВСЕМИ непустыми метриками лога (кг / км / сек / раунды / удары / ккал / повторы).
  Widget _buildLogMetricsRow(bool isDark, WorkoutLog log) {
    final badges = _metricBadges(log);
    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badges.map((b) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: b.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: b.color.withOpacity(0.25),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(b.icon, size: 12, color: b.color),
              const SizedBox(width: 5),
              Text(
                b.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  height: 1,
                  color: b.color,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                b.label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  height: 1,
                  color: b.color.withOpacity(0.85),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 🆕 DETAILED EXERCISE TILE — format-aware чипы подходов
  // ══════════════════════════════════════════════════════════════════

  Widget _buildDetailedExerciseTile(
      bool isDark,
      WorkoutExercise exercise,
      Exercise exerciseData,
      FitnessProvider provider,
      ) {
    final completedSets = exercise.sets
        .where((s) => s.status == SetStatus.completed)
        .toList();
    final accent = exerciseData.muscleGroups.isNotEmpty
        ? exerciseData.muscleGroups.first.color
        : _Power.volt;

    // 🆕 Резолвим формат для корректного отображения
    final format = _resolveFormat(exercise, provider);

    // 🆕 Чипы подходов — через formatSetForDisplay
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Power.card2(isDark),
        borderRadius: BorderRadius.circular(12),
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
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  exerciseData.exerciseType.emoji,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseData.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: _Power.textPrimary(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // 🆕 Бейдж формата
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _Power.ice.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${format.emoji} ${format.shortName}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          height: 1,
                          color: _Power.ice,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${completedSets.length} ПОДХ',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      height: 1,
                      color: _Power.textTertiary(isDark),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (completedSets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: completedSets.map((set) {
                // 🆕 Единый формат-зависимый рендер
                final displayText = FitnessHelpers.formatSetForDisplay(
                  set,
                  format,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _Power.card(isDark),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _Power.separator(isDark),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      height: 1,
                      color: _Power.textPrimary(isDark),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodSection(bool isDark, WorkoutLog log) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Power.plasma.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _Power.plasma.withOpacity(0.25),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _Power.plasma.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.mood_rounded,
                  color: _Power.plasma,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'НАСТРОЕНИЕ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: _Power.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (log.moodEnergy != null)
                _buildMoodChip(
                    '⚡', 'ЭНЕРГИЯ', log.moodEnergy!, isDark),
              if (log.moodSleep != null)
                _buildMoodChip('😴', 'СОН', log.moodSleep!, isDark),
              if (log.moodMotivation != null)
                _buildMoodChip(
                    '🎯', 'МОТИВ', log.moodMotivation!, isDark),
            ],
          ),
          if (log.moodNotes != null && log.moodNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _Power.card(isDark).withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💭', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      log.moodNotes!,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: _Power.textSecondary(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodChip(
      String emoji, String label, int value, bool isDark) {
    final color = _getMoodColor(value);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 5),
          Text(
            '$value/10',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              height: 1,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: _Power.textTertiary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutPhoto(bool isDark, WorkoutLog log) {
    final file = File(log.workoutPhotoPath!);

    return GestureDetector(
      onTap: () {
        if (file.existsSync()) {
          _showFullScreenPhoto(context, file);
        }
      },
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _Power.separator(isDark),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                color: _Power.card2(isDark),
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ОТКРЫТЬ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
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

  void _showFullScreenPhoto(BuildContext context, File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(file, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentField(
      bool isDark, WorkoutLog log, FitnessProvider provider) {
    final isCompleted = log.status == WorkoutDayStatus.completed;

    return TextField(
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _Power.textPrimary(isDark),
      ),
      maxLines: 2,
      decoration: InputDecoration(
        hintText: isCompleted
            ? 'Добавить комментарий…'
            : 'Почему пропустили?',
        hintStyle: TextStyle(
          color: _Power.textTertiary(isDark),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _Power.card2(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _Power.separator(isDark),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _Power.volt,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(12),
        prefixIcon: Icon(
          Icons.comment_rounded,
          size: 16,
          color: _Power.textTertiary(isDark),
        ),
      ),
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          provider.updateLogComment(log.id, value);
          HapticFeedback.mediumImpact();
          _showSnack('Комментарий сохранён', _Power.green, success: true);
        }
      },
    );
  }

  // =====================================================================
  // MONTH PICKER
  // =====================================================================

  void _showMonthPicker(BuildContext context) {
    final isDark = widget.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: _Power.card(isDark),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _Power.textTertiary(isDark),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _Power.volt.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow:
                        _Power.softGlow(_Power.volt, strength: 0.25),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: _Power.volt,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ВЫБОР',
                            style: TextStyle(
                              color: _Power.volt,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Месяц и год',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              height: 1.1,
                              color: _Power.textPrimary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year - 1,
                            _selectedMonth.month,
                          );
                        });
                        setSheetState(() {});
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _Power.card2(isDark),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: _Power.textSecondary(isDark),
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _Power.volt.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _Power.volt.withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${_selectedMonth.year}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              height: 1,
                              color: _Power.volt,
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year + 1,
                            _selectedMonth.month,
                          );
                        });
                        setSheetState(() {});
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _Power.card2(isDark),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: _Power.textSecondary(isDark),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final monthNames = [
                      'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
                      'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек',
                    ];
                    final isSelected = _selectedMonth.month == month;
                    final isCurrent = DateTime.now().month == month &&
                        DateTime.now().year == _selectedMonth.year;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedMonth =
                              DateTime(_selectedMonth.year, month);
                        });
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _Power.volt
                              : isCurrent
                              ? _Power.volt.withOpacity(0.12)
                              : _Power.card2(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? _Power.volt
                                : _Power.separator(isDark),
                            width: 0.6,
                          ),
                          boxShadow: isSelected
                              ? _Power.softGlow(_Power.volt,
                              strength: 0.35)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              monthNames[index].toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: isSelected
                                    ? Colors.white
                                    : _Power.textPrimary(isDark),
                              ),
                            ),
                            if (isCurrent && !isSelected) ...[
                              const SizedBox(height: 3),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: _Power.volt,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedMonth = DateTime.now();
                    });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _Power.volt.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.today_rounded,
                          size: 16,
                          color: _Power.volt,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'СЕГОДНЯ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: _Power.volt,
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
      ),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  void _showSnack(String text, Color color, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (success) ...[
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<Map<String, int>> _getDaySteps(String dayKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'steps': prefs.getInt(dayKey) ?? 0,
        'minutes': prefs.getInt('${dayKey}_minutes') ?? 0,
      };
    } catch (_) {
      return {'steps': 0, 'minutes': 0};
    }
  }

  List<WorkoutLog> _getLogsForMonth(FitnessProvider provider) {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    return provider.logs
        .where((log) =>
    log.date.isAfter(start.subtract(const Duration(days: 1))) &&
        log.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  String _formatDateFull(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    final now = DateTime.now();
    final isToday = date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;

    if (isToday) return 'Сегодня';

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year;

    if (isYesterday) return 'Вчера';

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}