// features/fitness/ui/screens/workout_log_screen.dart
// 🎨 Premium Light — унифицировано с fitness_dashboard
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../nutrition/providers/nutrition_provider.dart';
import '../../../../nutrition/models/nutrition_models.dart';
import '../../../../nutrition/ui/screens/fuel_dashboard_screen.dart';
import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';

// ==================== PREMIUM LIGHT TOKENS ====================
class _P {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF7C818A);
  static const textSoft = Color(0xFFA0A5AE);
  static const divider = Color(0xFFE9EBEF);
  static const border = Color(0xFFDCE0E5);
  static const elevated = Color(0xFFF0F1F4);

  static const greenDeep = Color(0xFF6C9E88);
  static const greenSoft = Color(0xFFEAF2ED);
  static const greenText = Color(0xFF47735F);

  static const peachDeep = Color(0xFFEF9563);
  static const peachSoft = Color(0xFFFCF0E8);

  static const lavenderDeep = Color(0xFF9381BB);
  static const lavenderSoft = Color(0xFFEEEAF5);

  static const skyDeep = Color(0xFF7E9DC6);
  static const skySoft = Color(0xFFEBF0F8);

  static const redDeep = Color(0xFFD97B8A);
  static const redSoft = Color(0xFFFCEBEE);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1D2530).withOpacity(0.02),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];
}

class _T {
  static TextStyle title1 = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: _P.text,
  );
  static TextStyle title2 = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
    color: _P.text,
  );
  static TextStyle headline = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: _P.text,
  );
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _P.text,
  );
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _P.textMuted,
  );
  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: _P.textMuted,
  );
  static TextStyle number = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

class _R {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 22.0;
  static const xxl = 28.0;
}

class _Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

// ==================== PRESSABLE ====================
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final bool haptic;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;
  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        if (widget.haptic) HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ==================== SCREEN ====================
class WorkoutLogScreen extends StatefulWidget {
  final bool isDark;

  const WorkoutLogScreen({super.key, this.isDark = false});

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

  // ============================================================
  //  EXERCISE THUMBNAIL — универсальная (assets / http / file)
  // ============================================================
  Widget _buildExThumb(
      String? url, {
        required double size,
        required double radius,
        required Color accent,
        required String fallbackEmoji,
      }) {
    final hasImage = url != null && url.isNotEmpty;
    final Widget fallback =
    Text(fallbackEmoji, style: TextStyle(fontSize: size * 0.46));

    Widget imageWidget() {
      if (!hasImage) return fallback;
      if (url!.startsWith('assets/')) {
        return Image.asset(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
      if (url.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: accent.withOpacity(0.08)),
          errorWidget: (_, __, ___) => fallback,
        );
      }
      return Image.file(
        File(url),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(radius),
        border: hasImage
            ? Border.all(color: accent.withOpacity(0.18), width: 0.6)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageWidget(),
    );
  }

  // ============================================================
  //  METRIC HELPERS
  // ============================================================
  ({String label, String value, IconData icon, Color color})
  _metricPrimaryBadge(WorkoutLog log) {
    final kg = log.metricValue('kg');
    final km = log.metricValue('km');
    final rounds = log.metricValue('rounds');
    final sec = log.metricValue('sec');

    if (km > 0) {
      return (
      label: 'км',
      value: km.toStringAsFixed(km >= 10 ? 0 : 2),
      icon: Icons.directions_run_rounded,
      color: _P.skyDeep,
      );
    }
    if (rounds > 0) {
      return (
      label: 'раунд',
      value: rounds.toStringAsFixed(0),
      icon: Icons.sports_mma_rounded,
      color: _P.peachDeep,
      );
    }
    if (kg > 0) {
      return (
      label: 'кг',
      value: kg.toStringAsFixed(0),
      icon: Icons.fitness_center_rounded,
      color: _P.lavenderDeep,
      );
    }
    if (sec > 0) {
      return (
      label: 'сек',
      value: sec.toStringAsFixed(0),
      icon: Icons.timer_rounded,
      color: _P.greenDeep,
      );
    }
    return (
    label: '—',
    value: '0',
    icon: Icons.remove_rounded,
    color: _P.textMuted,
    );
  }

  List<({String label, String value, IconData icon, Color color})>
  _metricBadges(WorkoutLog log) {
    final result =
    <({String label, String value, IconData icon, Color color})>[];
    final kg = log.metricValue('kg');
    final km = log.metricValue('km');
    final sec = log.metricValue('sec');
    final rounds = log.metricValue('rounds');
    final punches = log.metricValue('punches');
    final kcal = log.metricValue('kcal');
    final reps = log.metricValue('reps');

    if (kg > 0) {
      result.add((
      label: 'кг',
      value: kg.toStringAsFixed(0),
      icon: Icons.fitness_center_rounded,
      color: _P.lavenderDeep,
      ));
    }
    if (km > 0) {
      result.add((
      label: 'км',
      value: km.toStringAsFixed(km >= 10 ? 1 : 2),
      icon: Icons.directions_run_rounded,
      color: _P.skyDeep,
      ));
    }
    if (rounds > 0) {
      result.add((
      label: 'раунд',
      value: rounds.toStringAsFixed(0),
      icon: Icons.sports_mma_rounded,
      color: _P.peachDeep,
      ));
    }
    if (sec > 0) {
      result.add((
      label: 'сек',
      value: sec.toStringAsFixed(0),
      icon: Icons.timer_rounded,
      color: _P.greenDeep,
      ));
    }
    if (punches > 0) {
      result.add((
      label: 'удар',
      value: punches.toStringAsFixed(0),
      icon: Icons.sports_mma_rounded,
      color: _P.redDeep,
      ));
    }
    if (kcal > 0) {
      result.add((
      label: 'ккал',
      value: kcal.toStringAsFixed(0),
      icon: Icons.local_fire_department_rounded,
      color: _P.peachDeep,
      ));
    }
    if (reps > 0 && kg == 0) {
      result.add((
      label: 'повт',
      value: reps.toStringAsFixed(0),
      icon: Icons.repeat_rounded,
      color: _P.lavenderDeep,
      ));
    }
    return result;
  }

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
    final provider = context.watch<FitnessProvider>();
    final logs = _getLogsForMonth(provider);

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(provider),
                    _buildMonthNavigator(),
                    Expanded(child: _buildCalendarGrid(logs)),
                  ],
                ),
                if (_isSheetOpen)
                  GestureDetector(
                    onTap: _closeSheet,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ),
                _buildBottomSheet(provider),
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
  Widget _buildHeader(FitnessProvider provider) {
    final monthLogs = _getLogsForMonth(provider);
    final completedCount =
        monthLogs.where((l) => l.status == WorkoutDayStatus.completed).length;
    final totalWorkouts = monthLogs.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_Sp.lg, _Sp.md, _Sp.lg, _Sp.xs),
      child: Row(
        children: [
          _Pressable(
            onTap: () => Navigator.pop(context),
            scale: 0.9,
            haptic: false,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _P.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _P.divider),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: _P.text,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: _R.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ЖУРНАЛ', style: _T.overline),
                const SizedBox(height: 2),
                Text('Тренировки', style: _T.title2),
              ],
            ),
          ),
          if (totalWorkouts > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _P.greenSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$completedCount/$totalWorkouts',
                style: _T.number.copyWith(
                  fontSize: 12,
                  color: _P.greenDeep,
                ),
              ),
            ),
          const SizedBox(width: _Sp.sm),
          _Pressable(
            onTap: () async {
              final nutrition = await _getNutritionProvider();
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: nutrition,
                    child: const FuelDashboardScreen(isDark: false),
                  ),
                ),
              );
            },
            scale: 0.9,
            haptic: false,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _P.skySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: _P.skyDeep,
                size: 18,
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
  Widget _buildMonthNavigator() {
    const monthNames = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(_Sp.lg, _Sp.sm, _Sp.lg, _Sp.sm),
      child: Row(
        children: [
          _Pressable(
            onTap: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
            scale: 0.9,
            haptic: false,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _P.divider),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: _P.textMuted,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: _Pressable(
              onTap: () => _showMonthPicker(context),
              scale: 0.98,
              haptic: false,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: _R.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: _Sp.lg,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _P.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _P.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                      style: _T.number.copyWith(
                        fontSize: 14,
                        color: _P.text,
                      ),
                    ),
                    const SizedBox(width: _Sp.xs),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _P.textSoft,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _Pressable(
            onTap: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
            },
            scale: 0.9,
            haptic: false,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _P.divider),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: _P.textMuted,
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
  Widget _buildCalendarGrid(List<WorkoutLog> monthLogs) {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final firstWeekday =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;

    final Map<int, List<WorkoutLog>> logsByDay = {};
    for (final log in monthLogs) {
      logsByDay[log.date.day] = [...logsByDay[log.date.day] ?? [], log];
    }

    const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final today = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == today.year && _selectedMonth.month == today.month;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _Sp.lg,
        vertical: _Sp.xs,
      ),
      child: Column(
        children: [
          Row(
            children: dayNames.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: _T.overline.copyWith(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      color: _P.textSoft,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: _Sp.sm),
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
                if (index < firstWeekday - 1) return const SizedBox();

                final day = index - (firstWeekday - 2);
                final dayLogs = logsByDay[day] ?? [];
                final isToday = isCurrentMonth && day == today.day;
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == _selectedMonth.year &&
                    _selectedDate!.month == _selectedMonth.month &&
                    _selectedDate!.day == day;

                final hasCompleted =
                dayLogs.any((l) => l.status == WorkoutDayStatus.completed);
                final hasSkipped =
                dayLogs.any((l) => l.status == WorkoutDayStatus.skipped);
                final hasLogs = dayLogs.isNotEmpty;

                Color statusColor;
                if (hasCompleted && hasSkipped) {
                  statusColor = _P.peachDeep;
                } else if (hasCompleted) {
                  statusColor = _P.greenDeep;
                } else if (hasSkipped) {
                  statusColor = _P.redDeep;
                } else {
                  statusColor = _P.textSoft;
                }

                return _Pressable(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month,
                        day,
                      );
                      _openSheet();
                    });
                  },
                  scale: 0.92,
                  haptic: false,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _P.peachSoft
                          : hasLogs
                          ? statusColor.withOpacity(0.06)
                          : _P.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _P.peachDeep
                            : isToday
                            ? _P.peachDeep.withOpacity(0.55)
                            : hasLogs
                            ? statusColor.withOpacity(0.20)
                            : _P.divider,
                        width: isToday && !isSelected ? 1.2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '$day',
                            style: _T.number.copyWith(
                              fontSize: 13,
                              color: isSelected
                                  ? _P.peachDeep
                                  : hasLogs
                                  ? statusColor
                                  : _P.text,
                            ),
                          ),
                        ),
                        if (hasLogs)
                          Positioned(
                            bottom: 5,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _dot(
                                  isSelected
                                      ? _P.peachDeep
                                      : hasCompleted
                                      ? _P.greenDeep
                                      : hasSkipped
                                      ? _P.redDeep
                                      : _P.textSoft,
                                ),
                                if (dayLogs.length > 1) ...[
                                  const SizedBox(width: 3),
                                  _dot(isSelected
                                      ? _P.peachDeep.withOpacity(0.6)
                                      : _P.textSoft),
                                ],
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
          const SizedBox(height: _Sp.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(_P.greenDeep, 'Выполнено'),
              const SizedBox(width: _R.md),
              _buildLegendItem(_P.redDeep, 'Пропущено'),
              const SizedBox(width: _R.md),
              _buildLegendItem(_P.peachDeep, 'Смешанный'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: _T.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  // =====================================================================
  // BOTTOM SHEET
  // =====================================================================
  Widget _buildBottomSheet(FitnessProvider provider) {
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

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: animatedHeight,
            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_R.xxl),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDraggableHandle(),
                _buildSheetHeader(),
                Expanded(child: _buildSheetContent(provider)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableHandle() {
    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
        _dragOffset = 0;
        _isDragging = true;
        _isAnimating = false;
      },
      onVerticalDragUpdate: (details) {
        _dragOffset = details.globalPosition.dy - _dragStartY;
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

        final shouldOpen = velocity.abs() > 300
            ? velocity < 0
            : currentHeight > midPoint;

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
        padding: const EdgeInsets.symmetric(
          vertical: _Sp.md,
          horizontal: _Sp.xl,
        ),
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _P.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isSheetOpen ? 'Свернуть' : 'Потяните вверх',
              style: _T.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_Sp.xl, _Sp.xs, _Sp.xl, _Sp.sm),
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
            child: const Icon(
              Icons.calendar_today_rounded,
              color: _P.peachDeep,
              size: 18,
            ),
          ),
          const SizedBox(width: _R.md),
          Expanded(
            child: Text(
              _selectedDate != null
                  ? _formatDateFull(_selectedDate!)
                  : 'Выберите день',
              style: _T.headline,
            ),
          ),
          if (_isSheetOpen)
            _Pressable(
              onTap: _closeSheet,
              scale: 0.9,
              haptic: false,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _P.elevated,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: _P.text,
                  size: 16,
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

  Widget _buildSheetContent(FitnessProvider provider) {
    if (_selectedDate == null) {
      return Center(child: Text('Нажмите на день', style: _T.caption));
    }
    return _buildDayContent(provider, _selectedDate!);
  }

  // =====================================================================
  // DAY CONTENT
  // =====================================================================
  Widget _buildDayContent(FitnessProvider provider, DateTime date) {
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

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_getDaySteps(dayKey), _getNutritionProvider()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_P.peachDeep),
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
            dayWellbeing.isNotEmpty ||
            dayPhotos.isNotEmpty;

        if (!hasAnyData) return _buildEmptyDayState(date);

        final totalExercises =
        logs.fold(0, (sum, l) => sum + l.exercisesLog.length);
        final completedCount =
            logs.where((l) => l.status == WorkoutDayStatus.completed).length;

        final sections = <Widget>[];

        sections.add(_buildDaySummary(
          logs,
          completedCount,
          totalExercises,
          steps,
          distanceKm,
          stepsCalories,
          nutritionSummary,
          nutritionGoals,
          nutrition,
        ));

        if (dayWellbeing.isNotEmpty) {
          sections.add(const SizedBox(height: _R.md));
          sections.add(_buildDayWellbeingCard(dayWellbeing.first));
        }

        if (dayPhotos.isNotEmpty) {
          sections.add(const SizedBox(height: _R.md));
          sections.add(_buildDayPhotosGrid(dayPhotos));
        }

        if (logs.isNotEmpty) {
          sections.add(const SizedBox(height: _Sp.lg));
          sections.add(_buildSectionLabel('Тренировки', logs.length));
          sections.add(const SizedBox(height: _Sp.sm));
          for (final log in logs) {
            sections.add(_buildLogCard(log, provider));
          }
        }

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: _Sp.lg,
            vertical: _Sp.xs,
          ),
          physics: const BouncingScrollPhysics(),
          children: sections,
        );
      },
    );
  }

  Widget _buildSectionLabel(String label, int count) {
    return Row(
      children: [
        Text(label, style: _T.headline),
        const SizedBox(width: _Sp.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _P.elevated,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: _T.number.copyWith(fontSize: 11, color: _P.textMuted),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // EMPTY STATE
  // =====================================================================
  Widget _buildEmptyDayState(DateTime date) {
    final quote = _emptyStateQuotes[date.day % _emptyStateQuotes.length];
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _P.elevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                size: 28,
                color: _P.textSoft,
              ),
            ),
            const SizedBox(height: _R.lg),
            Text('Пустой день', style: _T.title2.copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              quote,
              textAlign: TextAlign.center,
              style: _T.caption.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // WELLBEING CARD
  // =====================================================================
  Widget _buildDayWellbeingCard(WellbeingNote note) {
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
      padding: const EdgeInsets.all(_Sp.lg),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider),
        boxShadow: _P.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _P.greenSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: _P.greenDeep,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Text('Самочувствие', style: _T.headline.copyWith(fontSize: 14)),
              const Spacer(),
              Text(
                '${note.date.hour}:${note.date.minute.toString().padLeft(2, '0')}',
                style: _T.number.copyWith(fontSize: 11, color: _P.textMuted),
              ),
            ],
          ),
          const SizedBox(height: _R.md),
          Row(
            children: [
              _buildMoodStat(energyEmoji, 'Энергия', note.energyLevel),
              _buildMoodStat(sleepEmoji, 'Сон', note.sleepQuality),
              _buildMoodStat(motivationEmoji, 'Мотив', note.motivationLevel),
            ],
          ),
          if (note.painAreas.isNotEmpty &&
              !note.painAreas.contains('Нет болей')) ...[
            const SizedBox(height: _R.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: _Sp.sm,
              ),
              decoration: BoxDecoration(
                color: _P.peachSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.healing_rounded,
                    color: _P.peachDeep,
                    size: 14,
                  ),
                  const SizedBox(width: _Sp.sm),
                  Expanded(
                    child: Text(
                      'Боли: ${note.painAreas.join(" · ")}',
                      style: _T.caption.copyWith(
                        color: _P.peachDeep,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (note.notes != null && note.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              note.notes!,
              style: _T.caption.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodStat(String emoji, String label, int value) {
    final color = _getMoodColor(value);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 6),
          Text(
            '$value/10',
            style: _T.number.copyWith(fontSize: 13, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: _T.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Color _getMoodColor(int value) {
    if (value <= 3) return _P.redDeep;
    if (value <= 5) return _P.peachDeep;
    if (value <= 7) return _P.lavenderDeep;
    return _P.greenDeep;
  }

  // =====================================================================
  // PHOTOS GRID
  // =====================================================================
  Widget _buildDayPhotosGrid(List<FitnessPhoto> photos) {
    final display = photos.take(4).toList();
    final remaining = photos.length - display.length;

    return Container(
      padding: const EdgeInsets.all(_Sp.lg),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider),
        boxShadow: _P.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _P.lavenderSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: _P.lavenderDeep,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Text('Фото дня', style: _T.headline.copyWith(fontSize: 14)),
              const Spacer(),
              Text(
                '${photos.length}',
                style: _T.number.copyWith(fontSize: 12, color: _P.textMuted),
              ),
            ],
          ),
          const SizedBox(height: _R.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: display.length == 1 ? 1 : 2,
              crossAxisSpacing: _Sp.sm,
              mainAxisSpacing: _Sp.sm,
              childAspectRatio: display.length == 1 ? 1.8 : 1.0,
            ),
            itemCount: display.length,
            itemBuilder: (context, index) =>
                _buildSmallPhotoTile(display[index]),
          ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: _Sp.sm),
              child: Center(
                child: Text(
                  '+ ещё $remaining',
                  style: _T.caption,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmallPhotoTile(FitnessPhoto photo) {
    final file = File(photo.imageUrl);
    final hasFile = file.existsSync();

    return _Pressable(
      onTap: () {
        if (hasFile) _showFullScreenPhoto(context, file);
      },
      scale: 0.96,
      haptic: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_R.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasFile
                ? Image.file(file, fit: BoxFit.cover)
                : Container(
              color: _P.elevated,
              child: const Icon(
                Icons.broken_image_rounded,
                color: _P.textSoft,
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
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    photo.label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // DAY SUMMARY
  // =====================================================================
  Widget _buildDaySummary(
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

    final totalKg = logs.fold<double>(0, (s, l) => s + l.metricValue('kg'));
    final totalKm = logs.fold<double>(0, (s, l) => s + l.metricValue('km'));
    final totalSec = logs.fold<double>(0, (s, l) => s + l.metricValue('sec'));
    final totalRounds =
    logs.fold<double>(0, (s, l) => s + l.metricValue('rounds'));
    final dominant = _dominantDayMetric(
      kg: totalKg,
      km: totalKm,
      sec: totalSec,
      rounds: totalRounds,
    );

    return Container(
      padding: const EdgeInsets.all(_Sp.lg),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider),
        boxShadow: _P.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _P.peachSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.insights_rounded,
                  color: _P.peachDeep,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Text('Сводка дня', style: _T.headline.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: _R.md),
          Row(
            children: [
              _buildSummaryItem(
                Icons.directions_walk_rounded,
                '$steps',
                'шагов',
                _P.skyDeep,
              ),
              _divider(),
              _buildSummaryItem(
                Icons.straighten_rounded,
                distanceKm.toStringAsFixed(1),
                'км',
                _P.greenDeep,
              ),
              _divider(),
              _buildSummaryItem(
                Icons.local_fire_department_rounded,
                '$calories',
                'ккал',
                _P.peachDeep,
              ),
            ],
          ),
          if (hasWorkouts) ...[
            const SizedBox(height: _R.md),
            Container(height: 0.5, color: _P.divider),
            const SizedBox(height: _R.md),
            Row(
              children: [
                _buildSummaryItem(
                  Icons.fitness_center_rounded,
                  '${logs.length}',
                  'трен.',
                  _P.lavenderDeep,
                ),
                _divider(),
                _buildSummaryItem(
                  Icons.check_circle_rounded,
                  '$completed',
                  'готово',
                  _P.greenDeep,
                ),
                _divider(),
                _buildSummaryItem(
                  dominant.icon,
                  dominant.value,
                  dominant.label,
                  dominant.color,
                ),
                _divider(),
                _buildSummaryItem(
                  Icons.repeat_rounded,
                  '$totalExercises',
                  'упр',
                  _P.peachDeep,
                ),
              ],
            ),
          ],
          if (hasNutrition) ...[
            const SizedBox(height: _R.md),
            Container(height: 0.5, color: _P.divider),
            const SizedBox(height: _R.md),
            _buildCompactNutrition(nutrition, goals),
            const SizedBox(height: 10),
            _Pressable(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: nutritionProvider,
                      child: const FuelDashboardScreen(isDark: false),
                    ),
                  ),
                );
              },
              scale: 0.98,
              haptic: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _P.skySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Подробнее о питании',
                      style: _T.caption.copyWith(
                        color: _P.skyDeep,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: _Sp.xs),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: _P.skyDeep,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  ({IconData icon, String value, String label, Color color})
  _dominantDayMetric({
    required double kg,
    required double km,
    required double sec,
    required double rounds,
  }) {
    if (km > 0) {
      return (
      icon: Icons.directions_run_rounded,
      value: km.toStringAsFixed(km >= 10 ? 0 : 2),
      label: 'км',
      color: _P.skyDeep,
      );
    }
    if (rounds > 0) {
      return (
      icon: Icons.sports_mma_rounded,
      value: rounds.toStringAsFixed(0),
      label: 'раунд',
      color: _P.peachDeep,
      );
    }
    if (kg > 0) {
      return (
      icon: Icons.fitness_center_rounded,
      value: kg.toStringAsFixed(0),
      label: 'кг',
      color: _P.lavenderDeep,
      );
    }
    if (sec > 0) {
      return (
      icon: Icons.timer_rounded,
      value: sec.toStringAsFixed(0),
      label: 'сек',
      color: _P.greenDeep,
      );
    }
    return (
    icon: Icons.fitness_center_rounded,
    value: '0',
    label: 'кг',
    color: _P.textMuted,
    );
  }

  Widget _divider() {
    return Container(width: 0.5, height: 36, color: _P.divider);
  }

  Widget _buildSummaryItem(
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: _T.number.copyWith(fontSize: 15, color: _P.text),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: _T.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNutrition(
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
                  backgroundColor: _P.elevated,
                  valueColor: AlwaysStoppedAnimation(
                    calPercent > 1 ? _P.peachDeep : _P.skyDeep,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${summary.calories.round()}',
                    style: _T.number.copyWith(fontSize: 14),
                  ),
                  Text(
                    'ккал',
                    style: _T.caption.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: _R.md),
        Expanded(
          child: Column(
            children: [
              _buildSmallMacro(
                  'Б', summary.protein, goals.protein, pPercent, _P.greenDeep),
              const SizedBox(height: 6),
              _buildSmallMacro(
                  'Ж', summary.fat, goals.fat, fPercent, _P.redDeep),
              const SizedBox(height: 6),
              _buildSmallMacro('У', summary.carbs, goals.carbs, cPercent,
                  _P.peachDeep),
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
                  color: _P.elevated,
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
          style: _T.number.copyWith(fontSize: 10, color: _P.textMuted),
        ),
      ],
    );
  }

  // =====================================================================
  // LOG CARD — с превью первого упражнения
  // =====================================================================
  Widget _buildLogCard(WorkoutLog log, FitnessProvider provider) {
    final isCompleted = log.status == WorkoutDayStatus.completed;
    final cardKey = log.id;
    final accent = isCompleted ? _P.greenDeep : _P.redDeep;

    _expandedCards.putIfAbsent(cardKey, () => false);
    final primary = _metricPrimaryBadge(log);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider),
        boxShadow: _P.cardShadow,
      ),
      child: Column(
        children: [
          _Pressable(
            onTap: () {
              setState(() {
                _expandedCards[cardKey] = !(_expandedCards[cardKey] ?? false);
              });
            },
            scale: 0.99,
            haptic: false,
            child: Padding(
              padding: const EdgeInsets.all(_R.md),
              child: Row(
                children: [
                  // 🆕 Превью первого упражнения (вместо generic-иконки)
                  _buildLogCardLeading(log, provider, accent, isCompleted),
                  const SizedBox(width: _R.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCompleted ? 'Тренировка' : 'Пропущено',
                          style: _T.headline.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${log.date.hour}:${log.date.minute.toString().padLeft(2, '0')}',
                              style: _T.number.copyWith(
                                fontSize: 12,
                                color: _P.textMuted,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.color.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(primary.icon,
                                        size: 10, color: primary.color),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${primary.value} ${primary.label}',
                                      style: _T.number.copyWith(
                                        fontSize: 10,
                                        color: primary.color,
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
                                  color: _P.skySoft,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '${log.exercisesLog.length} упр',
                                  style: _T.number.copyWith(
                                    fontSize: 10,
                                    color: _P.skyDeep,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (log.comment != null &&
                            log.comment!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            log.comment!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _T.caption.copyWith(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: (_expandedCards[cardKey] ?? false) ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _P.textSoft,
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
              padding: const EdgeInsets.fromLTRB(
                _R.md,
                0,
                _R.md,
                _R.md,
              ),
              child: _buildExpandedContent(log, provider),
            ),
            crossFadeState: (_expandedCards[cardKey] ?? false)
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }

  /// 🆕 Превью первого упражнения в заголовке карточки тренировки.
  /// Если у лога есть упражнения — показываем thumbnail первого.
  /// Иначе (пропущено / пусто) — иконку-заглушку.
  Widget _buildLogCardLeading(
      WorkoutLog log,
      FitnessProvider provider,
      Color accent,
      bool isCompleted,
      ) {
    if (isCompleted && log.exercisesLog.isNotEmpty) {
      final first = log.exercisesLog.first;
      final exData = provider.exercises.firstWhere(
            (e) => e.id == first.exerciseId,
        orElse: () => Exercise(id: '', name: ''),
      );
      if (exData.id.isNotEmpty) {
        return _buildExThumb(
          exData.imageUrl,
          size: 40,
          radius: 11,
          accent: accent,
          fallbackEmoji: exData.exerciseType.emoji,
        );
      }
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Icon(
        isCompleted ? Icons.fitness_center_rounded : Icons.cancel_rounded,
        color: accent,
        size: 18,
      ),
    );
  }

  Widget _buildExpandedContent(WorkoutLog log, FitnessProvider provider) {
    if (log.status != WorkoutDayStatus.completed) {
      return _buildSkippedContent(log, provider);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailedStats(log),
        const SizedBox(height: 10),
        _buildLogMetricsRow(log),
        const SizedBox(height: _R.md),
        if (log.moodEnergy != null || log.moodNotes != null) ...[
          _buildMoodSection(log),
          const SizedBox(height: _R.md),
        ],
        if (log.workoutPhotoPath != null &&
            File(log.workoutPhotoPath!).existsSync()) ...[
          _buildWorkoutPhoto(log),
          const SizedBox(height: _R.md),
        ],
        if (log.exercisesLog.isNotEmpty) ...[
          Text('Упражнения', style: _T.headline.copyWith(fontSize: 13)),
          const SizedBox(height: 10),
          ...log.exercisesLog.asMap().entries.map((entry) {
            final exercise = entry.value;
            final exerciseData = provider.exercises.firstWhere(
                  (e) => e.id == exercise.exerciseId,
              orElse: () => Exercise(id: '', name: 'Удалено'),
            );
            return _buildExerciseTile(exercise, exerciseData, provider);
          }),
        ],
        const SizedBox(height: 10),
        _buildCommentField(log, provider),
      ],
    );
  }

  Widget _buildSkippedContent(WorkoutLog log, FitnessProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(_R.md),
          decoration: BoxDecoration(
            color: _P.elevated,
            borderRadius: BorderRadius.circular(_R.sm),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: _P.textMuted,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(
                'Тренировка была пропущена',
                style: _T.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildCommentField(log, provider),
      ],
    );
  }

  // =====================================================================
  // DETAILED STATS
  // =====================================================================
  Widget _buildDetailedStats(WorkoutLog log) {
    final duration = log.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = duration?.inMinutes.remainder(60) ?? 0;
    final primary = _metricPrimaryBadge(log);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: _R.md),
      decoration: BoxDecoration(
        color: _P.elevated,
        borderRadius: BorderRadius.circular(_R.md),
      ),
      child: Row(
        children: [
          _buildDetailStat(
            Icons.timer_rounded,
            hours > 0 ? '${hours}ч ${minutes}м' : '${minutes}м',
            'время',
            _P.skyDeep,
          ),
          _statDivider(),
          _buildDetailStat(
            Icons.speed_rounded,
            log.avgRpe != null ? log.avgRpe!.toStringAsFixed(1) : '--',
            'RPE',
            _P.lavenderDeep,
          ),
          _statDivider(),
          _buildDetailStat(
            Icons.fitness_center_rounded,
            '${log.exercisesLog.length}',
            'упр',
            _P.greenDeep,
          ),
          _statDivider(),
          _buildDetailStat(
            primary.icon,
            primary.value,
            primary.label,
            primary.color,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 0.5, height: 34, color: _P.divider);
  }

  Widget _buildDetailStat(
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: _T.number.copyWith(fontSize: 13, color: _P.text),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: _T.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLogMetricsRow(WorkoutLog log) {
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
            color: b.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(b.icon, size: 12, color: b.color),
              const SizedBox(width: 5),
              Text(
                b.value,
                style: _T.number.copyWith(fontSize: 12, color: b.color),
              ),
              const SizedBox(width: 3),
              Text(
                b.label,
                style: _T.caption.copyWith(
                  fontSize: 10,
                  color: b.color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =====================================================================
  // EXERCISE TILE
  // =====================================================================
  Widget _buildExerciseTile(
      WorkoutExercise exercise,
      Exercise exerciseData,
      FitnessProvider provider,
      ) {
    final completedSets =
    exercise.sets.where((s) => s.status == SetStatus.completed).toList();
    final accent = exerciseData.muscleGroups.isNotEmpty
        ? exerciseData.muscleGroups.first.color
        : _P.peachDeep;
    final format = _resolveFormat(exercise, provider);

    return Container(
      margin: const EdgeInsets.only(bottom: _Sp.sm),
      padding: const EdgeInsets.all(_R.md),
      decoration: BoxDecoration(
        color: _P.elevated,
        borderRadius: BorderRadius.circular(_R.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildExThumb(
                exerciseData.imageUrl,
                size: 32,
                radius: 9,
                accent: accent,
                fallbackEmoji: exerciseData.exerciseType.emoji,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseData.name,
                      style: _T.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _P.surface,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${format.emoji} ${format.shortName}',
                        style: _T.caption.copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${completedSets.length} подх',
                style: _T.number.copyWith(
                  fontSize: 10,
                  color: _P.textMuted,
                ),
              ),
            ],
          ),
          if (completedSets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: completedSets.map((set) {
                final displayText =
                FitnessHelpers.formatSetForDisplay(set, format);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _Sp.sm,
                    vertical: _Sp.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _P.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayText,
                    style: _T.number.copyWith(
                      fontSize: 11,
                      color: _P.text,
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

  Widget _buildMoodSection(WorkoutLog log) {
    return Container(
      padding: const EdgeInsets.all(_R.md),
      decoration: BoxDecoration(
        color: _P.lavenderSoft.withOpacity(0.5),
        borderRadius: BorderRadius.circular(_R.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mood_rounded,
                color: _P.lavenderDeep,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Настроение',
                style: _T.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _P.lavenderDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: _R.md),
          Row(
            children: [
              if (log.moodEnergy != null)
                _buildMoodChip('⚡', 'энергия', log.moodEnergy!),
              if (log.moodSleep != null)
                _buildMoodChip('😴', 'сон', log.moodSleep!),
              if (log.moodMotivation != null)
                _buildMoodChip('🎯', 'мотив', log.moodMotivation!),
            ],
          ),
          if (log.moodNotes != null && log.moodNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              log.moodNotes!,
              style: _T.caption.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodChip(String emoji, String label, int value) {
    final color = _getMoodColor(value);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 5),
          Text(
            '$value/10',
            style: _T.number.copyWith(fontSize: 12, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: _T.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildWorkoutPhoto(WorkoutLog log) {
    final file = File(log.workoutPhotoPath!);

    return _Pressable(
      onTap: () {
        if (file.existsSync()) _showFullScreenPhoto(context, file);
      },
      scale: 0.98,
      haptic: false,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_R.md),
          border: Border.all(color: _P.divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_R.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                color: _P.elevated,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: _P.textSoft,
                    size: 32,
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
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
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
                        'Открыть',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
                  top: _Sp.sm,
                  left: _Sp.lg,
                  child: _Pressable(
                    onTap: () => Navigator.pop(ctx),
                    scale: 0.9,
                    haptic: false,
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

  Widget _buildCommentField(WorkoutLog log, FitnessProvider provider) {
    final isCompleted = log.status == WorkoutDayStatus.completed;

    return TextField(
      style: _T.body.copyWith(fontSize: 13),
      maxLines: 2,
      decoration: InputDecoration(
        hintText: isCompleted ? 'Добавить комментарий…' : 'Почему пропустили?',
        hintStyle: _T.caption.copyWith(fontSize: 12),
        filled: true,
        fillColor: _P.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_R.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_R.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_R.sm),
          borderSide: const BorderSide(color: _P.peachDeep, width: 1.2),
        ),
        contentPadding: const EdgeInsets.all(_R.md),
        prefixIcon: const Icon(
          Icons.comment_rounded,
          size: 16,
          color: _P.textSoft,
        ),
      ),
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          provider.updateLogComment(log.id, value);
          HapticFeedback.mediumImpact();
          _showSnack('Комментарий сохранён', success: true);
        }
      },
    );
  }

  // =====================================================================
  // MONTH PICKER
  // =====================================================================
  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(
            _Sp.xl,
            _R.md,
            _Sp.xl,
            _Sp.xxl,
          ),
          decoration: const BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(_R.xxl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _P.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: _Sp.xl),
                Row(
                  children: [
                    Text('Месяц и год', style: _T.title2),
                  ],
                ),
                const SizedBox(height: _R.lg),
                Row(
                  children: [
                    _Pressable(
                      onTap: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year - 1,
                            _selectedMonth.month,
                          );
                        });
                        setSheetState(() {});
                      },
                      scale: 0.9,
                      haptic: false,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _P.elevated,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: _P.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: _R.md,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _P.peachSoft,
                          borderRadius: BorderRadius.circular(_R.sm),
                        ),
                        child: Center(
                          child: Text(
                            '${_selectedMonth.year}',
                            style: _T.number.copyWith(
                              fontSize: 22,
                              color: _P.peachDeep,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _Pressable(
                      onTap: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year + 1,
                            _selectedMonth.month,
                          );
                        });
                        setSheetState(() {});
                      },
                      scale: 0.9,
                      haptic: false,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _P.elevated,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: _P.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _R.lg),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: _Sp.sm,
                    mainAxisSpacing: _Sp.sm,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    const monthNames = [
                      'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
                      'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек',
                    ];
                    final isSelected = _selectedMonth.month == month;
                    final isCurrent = DateTime.now().month == month &&
                        DateTime.now().year == _selectedMonth.year;

                    return _Pressable(
                      onTap: () {
                        setState(() {
                          _selectedMonth =
                              DateTime(_selectedMonth.year, month);
                        });
                        Navigator.pop(ctx);
                      },
                      scale: 0.94,
                      haptic: false,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _P.peachDeep
                              : isCurrent
                              ? _P.peachSoft
                              : _P.elevated,
                          borderRadius: BorderRadius.circular(_R.sm),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          monthNames[index],
                          style: _T.body.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : _P.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: _Sp.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime.now();
                      });
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _P.peachSoft,
                      foregroundColor: _P.peachDeep,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_R.md),
                      ),
                    ),
                    child: const Text(
                      'Сегодня',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

  // =====================================================================
  // HELPERS
  // =====================================================================
  void _showSnack(String text, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (success) ...[
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: _Sp.sm),
            ],
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: success ? _P.greenDeep : _P.redDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_R.md),
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
}