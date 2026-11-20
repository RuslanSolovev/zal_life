// features/fitness/ui/screens/workout_log_screen.dart
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

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM (Синхронизировано с HomeScreen)
// ═══════════════════════════════════════════════════════════════════
class _Palette {
  static const bg = Color(0xFFF6F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF263D36);
  static const textMuted = Color(0xFF7C8982);
  static const green = Color(0xFF426C59);
  static const greenSoft = Color(0xFFE7EFE5);
  static const sage = Color(0xFF8CAB93);
  static const peach = Color(0xFFC79475);
  static const peachSoft = Color(0xFFF5E6DC);
  static const pink = Color(0xFFBB8F9D);
  static const pinkSoft = Color(0xFFF2E4E7);
  static const yellow = Color(0xFFE7D9B8);
  static const divider = Color(0xFFE5E8E1);
}

class _R {
  final double scale;
  _R(BuildContext context) : scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

class _AppImg extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  final Widget? fallback;
  const _AppImg({this.path, this.fit = BoxFit.cover, this.fallback});

  @override
  Widget build(BuildContext context) {
    final p = path;
    final fb = fallback ?? const SizedBox.shrink();
    if (p == null || p.isEmpty) return fb;
    if (p.startsWith('assets/')) {
      return Image.asset(p, fit: fit, errorBuilder: (_, __, ___) => fb);
    }
    if (p.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: p, fit: fit,
        placeholder: (_, __) => fb,
        errorWidget: (_, __, ___) => fb,
      );
    }
    return Image.file(File(p), fit: fit, errorBuilder: (_, __, ___) => fb);
  }
}

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;

  const _TapScale({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.haptic = true,
  });

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (widget.haptic) HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════
class WorkoutLogScreen extends StatefulWidget {
  final bool isDark;
  const WorkoutLogScreen({super.key, this.isDark = false});

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> with TickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  NutritionProvider? _nutritionProvider;
  Future<NutritionProvider>? _nutritionFuture;

  final List<String> _moodEmojis = ['😫', '😩', '😐', '🙂', '😊', '😁', '🤩', '🔥', '💪', '🚀'];
  final List<String> _emptyStateQuotes = [
    'Каждый день — новая возможность', 'Сегодня ты можешь всё', 'Начни с малого',
    'Прогресс начинается с шага', 'Верь в себя',
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final Map<String, bool> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
  //  EXERCISE THUMBNAIL
  // ============================================================
  Widget _buildExThumb(String? url, {required double size, required double radius, required Color accent, required String fallbackEmoji}) {
    final hasImage = url != null && url.isNotEmpty;
    final Widget fallback = Text(fallbackEmoji, style: TextStyle(fontSize: size * 0.46));

    Widget imageWidget() {
      if (!hasImage) return fallback;
      if (url!.startsWith('assets/')) {
        return Image.asset(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
      }
      if (url.startsWith('http')) {
        return CachedNetworkImage(imageUrl: url, width: size, height: size, fit: BoxFit.cover, placeholder: (_, __) => Container(color: accent.withOpacity(0.08)), errorWidget: (_, __, ___) => fallback);
      }
      return Image.file(File(url), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    }

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(radius),
        border: hasImage ? Border.all(color: accent.withOpacity(0.18), width: 0.6) : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageWidget(),
    );
  }

  // ============================================================
  //  METRIC HELPERS
  // ============================================================
  ({String label, String value, IconData icon, Color color}) _metricPrimaryBadge(WorkoutLog log) {
    final kg = log.metricValue('kg');
    final km = log.metricValue('km');
    final rounds = log.metricValue('rounds');
    final sec = log.metricValue('sec');

    if (km > 0) return (label: 'км', value: km.toStringAsFixed(km >= 10 ? 0 : 2), icon: Icons.directions_run_rounded, color: _Palette.sage);
    if (rounds > 0) return (label: 'раунд', value: rounds.toStringAsFixed(0), icon: Icons.sports_mma_rounded, color: _Palette.peach);
    if (kg > 0) return (label: 'кг', value: kg.toStringAsFixed(0), icon: Icons.fitness_center_rounded, color: _Palette.pink);
    if (sec > 0) return (label: 'сек', value: sec.toStringAsFixed(0), icon: Icons.timer_rounded, color: _Palette.green);
    return (label: '—', value: '0', icon: Icons.remove_rounded, color: _Palette.textMuted);
  }

  List<({String label, String value, IconData icon, Color color})> _metricBadges(WorkoutLog log) {
    final result = <({String label, String value, IconData icon, Color color})>[];
    final kg = log.metricValue('kg');
    final km = log.metricValue('km');
    final sec = log.metricValue('sec');
    final rounds = log.metricValue('rounds');
    final punches = log.metricValue('punches');
    final kcal = log.metricValue('kcal');
    final reps = log.metricValue('reps');

    if (kg > 0) result.add((label: 'кг', value: kg.toStringAsFixed(0), icon: Icons.fitness_center_rounded, color: _Palette.pink));
    if (km > 0) result.add((label: 'км', value: km.toStringAsFixed(km >= 10 ? 1 : 2), icon: Icons.directions_run_rounded, color: _Palette.sage));
    if (rounds > 0) result.add((label: 'раунд', value: rounds.toStringAsFixed(0), icon: Icons.sports_mma_rounded, color: _Palette.peach));
    if (sec > 0) result.add((label: 'сек', value: sec.toStringAsFixed(0), icon: Icons.timer_rounded, color: _Palette.green));
    if (punches > 0) result.add((label: 'удар', value: punches.toStringAsFixed(0), icon: Icons.sports_mma_rounded, color: _Palette.pink));
    if (kcal > 0) result.add((label: 'ккал', value: kcal.toStringAsFixed(0), icon: Icons.local_fire_department_rounded, color: _Palette.peach));
    if (reps > 0 && kg == 0) result.add((label: 'повт', value: reps.toStringAsFixed(0), icon: Icons.repeat_rounded, color: _Palette.pink));
    return result;
  }

  ExerciseFormat _resolveFormat(WorkoutExercise we, FitnessProvider provider) {
    final ex = provider.exercises.firstWhere((e) => e.id == we.exerciseId, orElse: () => Exercise(id: '', name: ''));
    return FitnessHelpers.resolveFormat(we, ex.id.isEmpty ? null : ex);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final logs = _getLogsForMonth(provider);

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(provider),
              _buildMonthNavigator(),
              Expanded(child: _buildCalendarGrid(logs)),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // HEADER
  // =====================================================================
  Widget _buildHeader(FitnessProvider provider) {
    final r = _R(context);
    final monthLogs = _getLogsForMonth(provider);
    final completedCount = monthLogs.where((l) => l.status == WorkoutDayStatus.completed).length;
    final totalWorkouts = monthLogs.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(4)),
      child: Row(
        children: [
          _TapScale(
            onTap: () => Navigator.pop(context), scale: 0.9, haptic: false,
            child: Container(
              width: r.s(40), height: r.s(40),
              decoration: BoxDecoration(color: _Palette.surface, shape: BoxShape.circle, border: Border.all(color: _Palette.divider)),
              child: Icon(Icons.chevron_left_rounded, color: _Palette.text, size: r.s(20)),
            ),
          ),
          SizedBox(width: r.s(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ЖУРНАЛ', style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _Palette.textMuted)),
                SizedBox(height: r.s(2)),
                Text('Тренировки', style: GoogleFonts.inter(fontSize: r.fs(22), fontWeight: FontWeight.w600, letterSpacing: -0.6, color: _Palette.text)),
              ],
            ),
          ),
          if (totalWorkouts > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(6)),
              decoration: BoxDecoration(color: _Palette.greenSoft, borderRadius: BorderRadius.circular(r.s(10))),
              child: Text('$completedCount/$totalWorkouts', style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w700, color: _Palette.green, fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          SizedBox(width: r.s(8)),
          _TapScale(
            onTap: () async {
              final nutrition = await _getNutritionProvider();
              if (!mounted) return;
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: nutrition, child: const FuelDashboardScreen(isDark: false))));
            },
            scale: 0.9, haptic: false,
            child: Container(
              width: r.s(40), height: r.s(40),
              decoration: BoxDecoration(color: _Palette.sage.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(Icons.restaurant_rounded, color: _Palette.sage, size: r.s(18)),
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
    final r = _R(context);
    const monthNames = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(8), r.s(20), r.s(8)),
      child: Row(
        children: [
          _TapScale(
            onTap: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
            scale: 0.9, haptic: false,
            child: Container(
              width: r.s(36), height: r.s(36),
              decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(12)), border: Border.all(color: _Palette.divider)),
              child: Icon(Icons.chevron_left_rounded, color: _Palette.textMuted, size: r.s(20)),
            ),
          ),
          Expanded(
            child: _TapScale(
              onTap: () => _showMonthPicker(context), scale: 0.98, haptic: false,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: r.s(14)),
                padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(10)),
                decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(12)), border: Border.all(color: _Palette.divider)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}', style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, color: _Palette.text, fontFeatures: const [FontFeature.tabularFigures()])),
                    SizedBox(width: r.s(4)),
                    Icon(Icons.keyboard_arrow_down_rounded, color: _Palette.textMuted, size: r.s(18)),
                  ],
                ),
              ),
            ),
          ),
          _TapScale(
            onTap: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
            scale: 0.9, haptic: false,
            child: Container(
              width: r.s(36), height: r.s(36),
              decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(12)), border: Border.all(color: _Palette.divider)),
              child: Icon(Icons.chevron_right_rounded, color: _Palette.textMuted, size: r.s(20)),
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
    final r = _R(context);
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;

    final Map<int, List<WorkoutLog>> logsByDay = {};
    for (final log in monthLogs) {
      logsByDay[log.date.day] = [...logsByDay[log.date.day] ?? [], log];
    }

    const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final today = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == today.year && _selectedMonth.month == today.month;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(20), vertical: r.s(4)),
      child: Column(
        children: [
          Row(
            children: dayNames.map((day) => Expanded(child: Center(child: Text(day, style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 0.8, color: _Palette.textMuted))))).toList(),
          ),
          SizedBox(height: r.s(8)),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: r.s(4), mainAxisSpacing: r.s(4), childAspectRatio: 1.0),
              itemCount: firstWeekday - 1 + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) return const SizedBox();
                final day = index - (firstWeekday - 2);
                final dayLogs = logsByDay[day] ?? [];
                final isToday = isCurrentMonth && day == today.day;
                final isSelected = _selectedDate != null && _selectedDate!.year == _selectedMonth.year && _selectedDate!.month == _selectedMonth.month && _selectedDate!.day == day;

                final hasCompleted = dayLogs.any((l) => l.status == WorkoutDayStatus.completed);
                final hasSkipped = dayLogs.any((l) => l.status == WorkoutDayStatus.skipped);
                final hasLogs = dayLogs.isNotEmpty;

                Color statusColor;
                if (hasCompleted && hasSkipped) statusColor = _Palette.peach;
                else if (hasCompleted) statusColor = _Palette.green;
                else if (hasSkipped) statusColor = _Palette.pink;
                else statusColor = _Palette.textMuted;

                return _TapScale(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                      _openSheet();
                    });
                  },
                  scale: 0.92, haptic: false,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? _Palette.peachSoft : (hasLogs ? statusColor.withOpacity(0.06) : _Palette.surface),
                      borderRadius: BorderRadius.circular(r.s(12)),
                      border: Border.all(color: isSelected ? _Palette.peach : (isToday ? _Palette.peach.withOpacity(0.55) : (hasLogs ? statusColor.withOpacity(0.20) : _Palette.divider)), width: isToday && !isSelected ? 1.2 : 1),
                    ),
                    child: Stack(
                      children: [
                        Center(child: Text('$day', style: GoogleFonts.inter(fontSize: r.fs(13), fontWeight: isSelected || hasLogs ? FontWeight.w700 : FontWeight.w500, color: isSelected ? _Palette.peach : (hasLogs ? statusColor : _Palette.text), fontFeatures: const [FontFeature.tabularFigures()]))),
                        if (hasLogs)
                          Positioned(
                            bottom: r.s(5), left: 0, right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _dot(isSelected ? _Palette.peach : (hasCompleted ? _Palette.green : (hasSkipped ? _Palette.pink : _Palette.textMuted))),
                                if (dayLogs.length > 1) ...[SizedBox(width: r.s(3)), _dot(isSelected ? _Palette.peach.withOpacity(0.6) : _Palette.textMuted)],
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
          SizedBox(height: r.s(8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(_Palette.green, 'Выполнено', r),
              SizedBox(width: r.s(14)),
              _buildLegendItem(_Palette.pink, 'Пропущено', r),
              SizedBox(width: r.s(14)),
              _buildLegendItem(_Palette.peach, 'Смешанный', r),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  Widget _buildLegendItem(Color color, String label, _R r) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), SizedBox(width: r.s(6)), Text(label, style: GoogleFonts.inter(fontSize: r.fs(11), color: _Palette.textMuted))],
  );

  // =====================================================================
  // 🚀 ULTRA-RESPONSIVE BOTTOM SHEET
  // =====================================================================
  void _openSheet() {
    final r = _R(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.50, // Старт на половине экрана
        minChildSize: 0.50,     // Минимум половина
        maxChildSize: 0.85,     // Максимум 85% (оставляет красивый зазор до верха/календаря на любом экране)
        snap: true,
        snapSizes: const [0.50, 0.85],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: _Palette.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, -6))],
            ),
            child: Column(
              children: [
                // Drag Handle
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // Если свернуто - развернуть, если развернуто - свернуть
                    // Примечание: DraggableScrollableSheet не имеет прямого API для toggle,
                    // но свайп вверх/вниз работает нативно и идеально.
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: r.s(12)),
                    width: double.infinity,
                    child: Column(
                      children: [
                        Container(width: r.s(40), height: r.s(4), decoration: BoxDecoration(color: _Palette.divider, borderRadius: BorderRadius.circular(r.s(2)))),
                        SizedBox(height: r.s(6)),
                        Text('Потяните вверх', style: GoogleFonts.inter(fontSize: r.fs(11), color: _Palette.textMuted)),
                      ],
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(r.s(20), r.s(4), r.s(20), r.s(12)),
                  child: Row(
                    children: [
                      Container(
                        width: r.s(40), height: r.s(40),
                        decoration: BoxDecoration(color: _Palette.peachSoft, borderRadius: BorderRadius.circular(r.s(12))),
                        alignment: Alignment.center,
                        child: Icon(Icons.calendar_today_rounded, color: _Palette.peach, size: r.s(18)),
                      ),
                      SizedBox(width: r.s(14)),
                      Expanded(
                        child: Text(
                          _selectedDate != null ? _formatDateFull(_selectedDate!) : 'Выберите день',
                          style: GoogleFonts.inter(fontSize: r.fs(16), fontWeight: FontWeight.w600, color: _Palette.text),
                        ),
                      ),
                      _TapScale(
                        onTap: () => Navigator.pop(context), scale: 0.9, haptic: false,
                        child: Container(
                          width: r.s(32), height: r.s(32),
                          decoration: BoxDecoration(color: _Palette.bg, shape: BoxShape.circle),
                          child: Icon(Icons.close_rounded, color: _Palette.text, size: r.s(16)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _Palette.divider),
                // Scrollable Content
                Expanded(child: _buildSheetContent(scrollController)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetContent(ScrollController scrollController) {
    if (_selectedDate == null) return Center(child: Text('Нажмите на день', style: GoogleFonts.inter(color: _Palette.textMuted)));

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_getDaySteps('stats_${_selectedDate!.year}_${_selectedDate!.month}_${_selectedDate!.day}'), _getNutritionProvider()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_Palette.peach)));
        }
        final stepsData = snapshot.data![0] as Map<String, int>;
        final nutrition = snapshot.data![1] as NutritionProvider;
        final provider = context.read<FitnessProvider>();

        final steps = stepsData['steps'] ?? 0;
        final distanceKm = (steps * 0.75) / 1000.0;
        final stepsCalories = (steps * 0.04).round();
        final nutritionSummary = nutrition.getSummaryForDate(_selectedDate!);
        final nutritionGoals = nutrition.getGoalsForDate(_selectedDate!);
        final logs = provider.getLogsForDate(_selectedDate!);

        final dayWellbeing = provider.wellbeingNotes.where((n) => n.date.year == _selectedDate!.year && n.date.month == _selectedDate!.month && n.date.day == _selectedDate!.day).toList();
        final dayPhotos = provider.photos.where((p) => p.date.year == _selectedDate!.year && p.date.month == _selectedDate!.month && p.date.day == _selectedDate!.day).toList();

        final hasAnyData = logs.isNotEmpty || steps > 0 || nutritionSummary.entriesCount > 0 || dayWellbeing.isNotEmpty || dayPhotos.isNotEmpty;
        if (!hasAnyData) return _buildEmptyDayState(_selectedDate!);

        final totalExercises = logs.fold(0, (sum, l) => sum + l.exercisesLog.length);
        final completedCount = logs.where((l) => l.status == WorkoutDayStatus.completed).length;

        return ListView(
          controller: scrollController, // 🚀 Ключевой момент для отзывчивости
          padding: EdgeInsets.symmetric(horizontal: _R(context).s(20), vertical: _R(context).s(12)),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildDaySummary(logs, completedCount, totalExercises, steps, distanceKm, stepsCalories, nutritionSummary, nutritionGoals, nutrition),
            if (dayWellbeing.isNotEmpty) ...[SizedBox(height: _R(context).s(12)), _buildDayWellbeingCard(dayWellbeing.first)],
            if (dayPhotos.isNotEmpty) ...[SizedBox(height: _R(context).s(12)), _buildDayPhotosGrid(dayPhotos)],
            if (logs.isNotEmpty) ...[
              SizedBox(height: _R(context).s(20)),
              _buildSectionLabel('Тренировки', logs.length),
              SizedBox(height: _R(context).s(8)),
              ...logs.map((log) => _buildLogCard(log, provider)),
            ],
            SizedBox(height: _R(context).s(40)), // Отступ снизу для удобства скролла
          ],
        );
      },
    );
  }

  // =====================================================================
  // DAY CONTENT WIDGETS
  // =====================================================================
  Widget _buildSectionLabel(String label, int count) {
    final r = _R(context);
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: r.fs(16), fontWeight: FontWeight.w600, color: _Palette.text)),
        SizedBox(width: r.s(8)),
        Container(padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(2)), decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(6))), child: Text('$count', style: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w600, color: _Palette.textMuted, fontFeatures: const [FontFeature.tabularFigures()]))),
      ],
    );
  }

  Widget _buildEmptyDayState(DateTime date) {
    final r = _R(context);
    final quote = _emptyStateQuotes[date.day % _emptyStateQuotes.length];
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.s(32), vertical: r.s(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: r.s(64), height: r.s(64), decoration: BoxDecoration(color: _Palette.bg, shape: BoxShape.circle), child: Icon(Icons.self_improvement_rounded, size: r.s(28), color: _Palette.textMuted)),
            SizedBox(height: r.s(16)),
            Text('Пустой день', style: GoogleFonts.inter(fontSize: r.fs(18), fontWeight: FontWeight.w600, color: _Palette.text)),
            SizedBox(height: r.s(6)),
            Text(quote, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: r.fs(12), color: _Palette.textMuted, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayWellbeingCard(WellbeingNote note) {
    final r = _R(context);
    final energyEmoji = note.energyLevel >= 1 && note.energyLevel <= 10 ? _moodEmojis[note.energyLevel - 1] : '🙂';
    final sleepEmoji = note.sleepQuality >= 1 && note.sleepQuality <= 10 ? _moodEmojis[note.sleepQuality - 1] : '🙂';
    final motivationEmoji = note.motivationLevel >= 1 && note.motivationLevel <= 10 ? _moodEmojis[note.motivationLevel - 1] : '🙂';

    return Container(
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(16)), border: Border.all(color: _Palette.divider), boxShadow: [BoxShadow(color: const Color(0xFF1D2530).withOpacity(0.02), blurRadius: 14, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: r.s(28), height: r.s(28), decoration: BoxDecoration(color: _Palette.greenSoft, borderRadius: BorderRadius.circular(r.s(8))), alignment: Alignment.center, child: Icon(Icons.favorite_rounded, color: _Palette.green, size: r.s(14))),
              SizedBox(width: r.s(10)),
              Text('Самочувствие', style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, color: _Palette.text)),
              const Spacer(),
              Text('${note.date.hour}:${note.date.minute.toString().padLeft(2, '0')}', style: GoogleFonts.inter(fontSize: r.fs(11), color: _Palette.textMuted, fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
          SizedBox(height: r.s(14)),
          Row(children: [_buildMoodStat(energyEmoji, 'Энергия', note.energyLevel, r), _buildMoodStat(sleepEmoji, 'Сон', note.sleepQuality, r), _buildMoodStat(motivationEmoji, 'Мотив', note.motivationLevel, r)]),
          if (note.painAreas.isNotEmpty && !note.painAreas.contains('Нет болей')) ...[
            SizedBox(height: r.s(14)),
            Container(padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(8)), decoration: BoxDecoration(color: _Palette.peachSoft, borderRadius: BorderRadius.circular(r.s(10))), child: Row(children: [Icon(Icons.healing_rounded, color: _Palette.peach, size: r.s(14)), SizedBox(width: r.s(8)), Expanded(child: Text('Боли: ${note.painAreas.join(" · ")}', style: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w500, color: _Palette.peach)))])),
          ],
          if (note.notes != null && note.notes!.isNotEmpty) ...[
            SizedBox(height: r.s(10)),
            Text(note.notes!, style: GoogleFonts.inter(fontSize: r.fs(12), fontStyle: FontStyle.italic, color: _Palette.textMuted, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodStat(String emoji, String label, int value, _R r) {
    final color = value <= 3 ? _Palette.pink : (value <= 5 ? _Palette.peach : (value <= 7 ? _Palette.sage : _Palette.green));
    return Expanded(
      child: Column(
        children: [
          Container(width: r.s(44), height: r.s(44), decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle), alignment: Alignment.center, child: Text(emoji, style: TextStyle(fontSize: r.fs(20)))),
          SizedBox(height: r.s(6)),
          Text('$value/10', style: GoogleFonts.inter(fontSize: r.fs(13), fontWeight: FontWeight.w600, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
          SizedBox(height: r.s(2)),
          Text(label, style: GoogleFonts.inter(fontSize: r.fs(11), color: _Palette.textMuted)),
        ],
      ),
    );
  }

  Widget _buildDayPhotosGrid(List<FitnessPhoto> photos) {
    final r = _R(context);
    final display = photos.take(4).toList();
    final remaining = photos.length - display.length;

    return Container(
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(16)), border: Border.all(color: _Palette.divider), boxShadow: [BoxShadow(color: const Color(0xFF1D2530).withOpacity(0.02), blurRadius: 14, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: r.s(28), height: r.s(28), decoration: BoxDecoration(color: _Palette.pinkSoft, borderRadius: BorderRadius.circular(r.s(8))), alignment: Alignment.center, child: Icon(Icons.photo_camera_rounded, color: _Palette.pink, size: r.s(14))),
              SizedBox(width: r.s(10)),
              Text('Фото дня', style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, color: _Palette.text)),
              const Spacer(),
              Text('${photos.length}', style: GoogleFonts.inter(fontSize: r.fs(12), color: _Palette.textMuted, fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
          SizedBox(height: r.s(14)),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: display.length == 1 ? 1 : 2, crossAxisSpacing: r.s(8), mainAxisSpacing: r.s(8), childAspectRatio: display.length == 1 ? 1.8 : 1.0),
            itemCount: display.length,
            itemBuilder: (context, index) => _buildSmallPhotoTile(display[index], r),
          ),
          if (remaining > 0) Padding(padding: EdgeInsets.only(top: r.s(8)), child: Center(child: Text('+ ещё $remaining', style: GoogleFonts.inter(fontSize: r.fs(11), color: _Palette.textMuted)))),
        ],
      ),
    );
  }

  Widget _buildSmallPhotoTile(FitnessPhoto photo, _R r) {
    final file = File(photo.imageUrl);
    final hasFile = file.existsSync();
    return _TapScale(
      onTap: () { if (hasFile) _showFullScreenPhoto(context, file); }, scale: 0.96, haptic: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.s(12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasFile ? Image.file(file, fit: BoxFit.cover) : Container(color: _Palette.bg, child: Icon(Icons.broken_image_rounded, color: _Palette.textMuted, size: r.s(24))),
            if (photo.label != null && photo.label!.isNotEmpty)
              Positioned(
                bottom: r.s(6), left: r.s(6), right: r.s(6),
                child: Container(padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(4)), decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(r.s(6))), child: Text(photo.label!, style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(10), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySummary(List<WorkoutLog> logs, int completed, int totalExercises, int steps, double distanceKm, int calories, DailyNutritionSummary nutrition, NutritionGoals goals, NutritionProvider nutritionProvider) {
    final r = _R(context);
    final hasNutrition = nutrition.entriesCount > 0;
    final hasWorkouts = logs.isNotEmpty;
    final totalKg = logs.fold<double>(0, (s, l) => s + l.metricValue('kg'));
    final totalKm = logs.fold<double>(0, (s, l) => s + l.metricValue('km'));
    final totalSec = logs.fold<double>(0, (s, l) => s + l.metricValue('sec'));
    final totalRounds = logs.fold<double>(0, (s, l) => s + l.metricValue('rounds'));
    final dominant = _dominantDayMetric(kg: totalKg, km: totalKm, sec: totalSec, rounds: totalRounds);

    return Container(
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(16)), border: Border.all(color: _Palette.divider), boxShadow: [BoxShadow(color: const Color(0xFF1D2530).withOpacity(0.02), blurRadius: 14, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: r.s(28), height: r.s(28), decoration: BoxDecoration(color: _Palette.peachSoft, borderRadius: BorderRadius.circular(r.s(8))), alignment: Alignment.center, child: Icon(Icons.insights_rounded, color: _Palette.peach, size: r.s(14))), SizedBox(width: r.s(10)), Text('Сводка дня', style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, color: _Palette.text))]),
          SizedBox(height: r.s(14)),
          Row(children: [_buildSummaryItem(Icons.directions_walk_rounded, '$steps', 'шагов', _Palette.sage, r), _divider(r), _buildSummaryItem(Icons.straighten_rounded, distanceKm.toStringAsFixed(1), 'км', _Palette.green, r), _divider(r), _buildSummaryItem(Icons.local_fire_department_rounded, '$calories', 'ккал', _Palette.peach, r)]),
          if (hasWorkouts) ...[
            SizedBox(height: r.s(14)), Container(height: 0.5, color: _Palette.divider), SizedBox(height: r.s(14)),
            Row(children: [_buildSummaryItem(Icons.fitness_center_rounded, '${logs.length}', 'трен.', _Palette.pink, r), _divider(r), _buildSummaryItem(Icons.check_circle_rounded, '$completed', 'готово', _Palette.green, r), _divider(r), _buildSummaryItem(dominant.icon, dominant.value, dominant.label, dominant.color, r), _divider(r), _buildSummaryItem(Icons.repeat_rounded, '$totalExercises', 'упр', _Palette.peach, r)]),
          ],
          if (hasNutrition) ...[
            SizedBox(height: r.s(14)), Container(height: 0.5, color: _Palette.divider), SizedBox(height: r.s(14)),
            _buildCompactNutrition(nutrition, goals, r),
            SizedBox(height: r.s(10)),
            _TapScale(
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: nutritionProvider, child: const FuelDashboardScreen(isDark: false)))); }, scale: 0.98, haptic: false,
              child: Container(padding: EdgeInsets.symmetric(vertical: r.s(10)), decoration: BoxDecoration(color: _Palette.sage.withOpacity(0.2), borderRadius: BorderRadius.circular(r.s(10))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Подробнее о питании', style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w500, color: _Palette.sage)), SizedBox(width: r.s(4)), Icon(Icons.arrow_forward_rounded, size: r.s(14), color: _Palette.sage)])),
            ),
          ],
        ],
      ),
    );
  }

  ({IconData icon, String value, String label, Color color}) _dominantDayMetric({required double kg, required double km, required double sec, required double rounds}) {
    if (km > 0) return (icon: Icons.directions_run_rounded, value: km.toStringAsFixed(km >= 10 ? 0 : 2), label: 'км', color: _Palette.sage);
    if (rounds > 0) return (icon: Icons.sports_mma_rounded, value: rounds.toStringAsFixed(0), label: 'раунд', color: _Palette.peach);
    if (kg > 0) return (icon: Icons.fitness_center_rounded, value: kg.toStringAsFixed(0), label: 'кг', color: _Palette.pink);
    if (sec > 0) return (icon: Icons.timer_rounded, value: sec.toStringAsFixed(0), label: 'сек', color: _Palette.green);
    return (icon: Icons.fitness_center_rounded, value: '0', label: 'кг', color: _Palette.textMuted);
  }

  Widget _divider(_R r) => Container(width: 0.5, height: r.s(36), color: _Palette.divider);

  Widget _buildSummaryItem(IconData icon, String value, String label, Color color, _R r) {
    return Expanded(child: Column(children: [Icon(icon, size: r.s(18), color: color), SizedBox(height: r.s(6)), Text(value, style: GoogleFonts.inter(fontSize: r.fs(15), fontWeight: FontWeight.w600, color: _Palette.text, fontFeatures: const [FontFeature.tabularFigures()])), SizedBox(height: r.s(2)), Text(label, style: GoogleFonts.inter(fontSize: r.fs(10), color: _Palette.textMuted))]));
  }

  Widget _buildCompactNutrition(DailyNutritionSummary summary, NutritionGoals goals, _R r) {
    final calPercent = summary.percentOf(goals);
    final pPercent = summary.proteinPercentOf(goals);
    final fPercent = summary.fatPercentOf(goals);
    final cPercent = summary.carbsPercentOf(goals);

    return Row(
      children: [
        SizedBox(
          width: r.s(60), height: r.s(60),
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: r.s(60), height: r.s(60), child: CircularProgressIndicator(value: calPercent.clamp(0, 1), strokeWidth: r.s(6), backgroundColor: _Palette.bg, valueColor: AlwaysStoppedAnimation(calPercent > 1 ? _Palette.peach : _Palette.sage))),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${summary.calories.round()}', style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])), Text('ккал', style: GoogleFonts.inter(fontSize: r.fs(9), color: _Palette.textMuted))]),
          ]),
        ),
        SizedBox(width: r.s(14)),
        Expanded(child: Column(children: [_buildSmallMacro('Б', summary.protein, goals.protein, pPercent, _Palette.green, r), SizedBox(height: r.s(6)), _buildSmallMacro('Ж', summary.fat, goals.fat, fPercent, _Palette.pink, r), SizedBox(height: r.s(6)), _buildSmallMacro('У', summary.carbs, goals.carbs, cPercent, _Palette.peach, r)])),
      ],
    );
  }

  Widget _buildSmallMacro(String label, double current, double goal, double percent, Color color, _R r) {
    return Row(
      children: [
        SizedBox(
          width: r.s(16),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: r.fs(12),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: r.s(4),
                decoration: BoxDecoration(
                  color: _Palette.bg,
                  borderRadius: BorderRadius.circular(r.s(2)),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  height: r.s(4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(r.s(2)),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: r.s(6)),
        Text(
          '${current.round()}/${goal.round()}',
          style: GoogleFonts.inter(
            fontSize: r.fs(10),
            color: _Palette.textMuted,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // LOG CARD
  // =====================================================================
  Widget _buildLogCard(WorkoutLog log, FitnessProvider provider) {
    final r = _R(context);
    final isCompleted = log.status == WorkoutDayStatus.completed;
    final cardKey = log.id;
    final accent = isCompleted ? _Palette.green : _Palette.pink;
    _expandedCards.putIfAbsent(cardKey, () => false);
    final primary = _metricPrimaryBadge(log);

    return Container(
      margin: EdgeInsets.only(bottom: r.s(10)),
      decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(16)), border: Border.all(color: _Palette.divider), boxShadow: [BoxShadow(color: const Color(0xFF1D2530).withOpacity(0.02), blurRadius: 14, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          _TapScale(
            onTap: () => setState(() => _expandedCards[cardKey] = !(_expandedCards[cardKey] ?? false)), scale: 0.99, haptic: false,
            child: Padding(
              padding: EdgeInsets.all(r.s(14)),
              child: Row(
                children: [
                  _buildLogCardLeading(log, provider, accent, isCompleted, r),
                  SizedBox(width: r.s(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isCompleted ? 'Тренировка' : 'Пропущено', style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, color: _Palette.text)),
                        SizedBox(height: r.s(4)),
                        Row(
                          children: [
                            Text('${log.date.hour}:${log.date.minute.toString().padLeft(2, '0')}', style: GoogleFonts.inter(fontSize: r.fs(12), color: _Palette.textMuted, fontFeatures: const [FontFeature.tabularFigures()])),
                            if (isCompleted) ...[
                              SizedBox(width: r.s(6)),
                              Container(padding: EdgeInsets.symmetric(horizontal: r.s(6), vertical: r.s(2)), decoration: BoxDecoration(color: primary.color.withOpacity(0.10), borderRadius: BorderRadius.circular(r.s(5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(primary.icon, size: r.s(10), color: primary.color), SizedBox(width: r.s(3)), Text('${primary.value} ${primary.label}', style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w600, color: primary.color, fontFeatures: const [FontFeature.tabularFigures()]))])),
                            ],
                            if (log.exercisesLog.isNotEmpty) ...[
                              SizedBox(width: r.s(6)),
                              Container(padding: EdgeInsets.symmetric(horizontal: r.s(6), vertical: r.s(2)), decoration: BoxDecoration(color: _Palette.sage.withOpacity(0.2), borderRadius: BorderRadius.circular(r.s(5))), child: Text('${log.exercisesLog.length} упр', style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w600, color: _Palette.sage))),
                            ],
                          ],
                        ),
                        if (log.comment != null && log.comment!.isNotEmpty) ...[SizedBox(height: r.s(4)), Text(log.comment!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: r.fs(11), fontStyle: FontStyle.italic, color: _Palette.textMuted))],
                      ],
                    ),
                  ),
                  AnimatedRotation(duration: const Duration(milliseconds: 300), turns: (_expandedCards[cardKey] ?? false) ? 0.5 : 0, child: Icon(Icons.keyboard_arrow_down_rounded, color: _Palette.textMuted, size: r.s(20))),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(padding: EdgeInsets.fromLTRB(r.s(14), 0, r.s(14), r.s(14)), child: _buildExpandedContent(log, provider, r)),
            crossFadeState: (_expandedCards[cardKey] ?? false) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }

  Widget _buildLogCardLeading(WorkoutLog log, FitnessProvider provider, Color accent, bool isCompleted, _R r) {
    if (isCompleted && log.exercisesLog.isNotEmpty) {
      final first = log.exercisesLog.first;
      final exData = provider.exercises.firstWhere((e) => e.id == first.exerciseId, orElse: () => Exercise(id: '', name: ''));
      if (exData.id.isNotEmpty) {
        return _buildExThumb(exData.imageUrl, size: r.s(40), radius: r.s(11), accent: accent, fallbackEmoji: exData.exerciseType.emoji);
      }
    }
    return Container(width: r.s(40), height: r.s(40), decoration: BoxDecoration(color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(r.s(11))), alignment: Alignment.center, child: Icon(isCompleted ? Icons.fitness_center_rounded : Icons.cancel_rounded, color: accent, size: r.s(18)));
  }

  Widget _buildExpandedContent(WorkoutLog log, FitnessProvider provider, _R r) {
    if (log.status != WorkoutDayStatus.completed) return _buildSkippedContent(log, provider, r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailedStats(log, r),
        SizedBox(height: r.s(10)),
        _buildLogMetricsRow(log, r),
        SizedBox(height: r.s(14)),
        if (log.moodEnergy != null || log.moodNotes != null) ...[_buildMoodSection(log, r), SizedBox(height: r.s(14))],
        if (log.workoutPhotoPath != null && File(log.workoutPhotoPath!).existsSync()) ...[_buildWorkoutPhoto(log, r), SizedBox(height: r.s(14))],
        if (log.exercisesLog.isNotEmpty) ...[
          Text('Упражнения', style: GoogleFonts.inter(fontSize: r.fs(13), fontWeight: FontWeight.w600, color: _Palette.text)),
          SizedBox(height: r.s(10)),
          ...log.exercisesLog.asMap().entries.map((entry) {
            final exercise = entry.value;
            final exerciseData = provider.exercises.firstWhere((e) => e.id == exercise.exerciseId, orElse: () => Exercise(id: '', name: 'Удалено'));
            return _buildExerciseTile(exercise, exerciseData, provider, r);
          }),
        ],
        SizedBox(height: r.s(10)),
        _buildCommentField(log, provider, r),
      ],
    );
  }

  Widget _buildSkippedContent(WorkoutLog log, FitnessProvider provider, _R r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(padding: EdgeInsets.all(r.s(14)), decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(12))), child: Row(children: [Icon(Icons.info_outline_rounded, color: _Palette.textMuted, size: r.s(16)), SizedBox(width: r.s(10)), Text('Тренировка была пропущена', style: GoogleFonts.inter(fontSize: r.fs(13), fontWeight: FontWeight.w500, color: _Palette.text))])),
        SizedBox(height: r.s(10)),
        _buildCommentField(log, provider, r),
      ],
    );
  }

  Widget _buildDetailedStats(WorkoutLog log, _R r) {
    final duration = log.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = duration?.inMinutes.remainder(60) ?? 0;
    final primary = _metricPrimaryBadge(log);

    return Container(
      padding: EdgeInsets.symmetric(vertical: r.s(14)),
      decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(12))),
      child: Row(children: [_buildDetailStat(Icons.timer_rounded, hours > 0 ? '${hours}ч ${minutes}м' : '${minutes}м', 'время', _Palette.sage, r), _statDivider(r), _buildDetailStat(Icons.speed_rounded, log.avgRpe != null ? log.avgRpe!.toStringAsFixed(1) : '--', 'RPE', _Palette.pink, r), _statDivider(r), _buildDetailStat(Icons.fitness_center_rounded, '${log.exercisesLog.length}', 'упр', _Palette.green, r), _statDivider(r), _buildDetailStat(primary.icon, primary.value, primary.label, primary.color, r)]),
    );
  }

  Widget _statDivider(_R r) => Container(width: 0.5, height: r.s(34), color: _Palette.divider);

  Widget _buildDetailStat(IconData icon, String value, String label, Color color, _R r) {
    return Expanded(child: Column(children: [Icon(icon, size: r.s(16), color: color), SizedBox(height: r.s(6)), Text(value, style: GoogleFonts.inter(fontSize: r.fs(13), fontWeight: FontWeight.w600, color: _Palette.text, fontFeatures: const [FontFeature.tabularFigures()])), SizedBox(height: r.s(2)), Text(label, style: GoogleFonts.inter(fontSize: r.fs(10), color: _Palette.textMuted))]));
  }

  Widget _buildLogMetricsRow(WorkoutLog log, _R r) {
    final badges = _metricBadges(log);
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: r.s(6), runSpacing: r.s(6), children: badges.map((b) => Container(padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(6)), decoration: BoxDecoration(color: b.color.withOpacity(0.08), borderRadius: BorderRadius.circular(r.s(9))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(b.icon, size: r.s(12), color: b.color), SizedBox(width: r.s(5)), Text(b.value, style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w600, color: b.color, fontFeatures: const [FontFeature.tabularFigures()])), SizedBox(width: r.s(3)), Text(b.label, style: GoogleFonts.inter(fontSize: r.fs(10), color: b.color.withOpacity(0.8)))]))).toList());
  }

  Widget _buildExerciseTile(WorkoutExercise exercise, Exercise exerciseData, FitnessProvider provider, _R r) {
    final completedSets = exercise.sets.where((s) => s.status == SetStatus.completed).toList();
    final accent = exerciseData.muscleGroups.isNotEmpty ? exerciseData.muscleGroups.first.color : _Palette.peach;
    final format = _resolveFormat(exercise, provider);

    return Container(
      margin: EdgeInsets.only(bottom: r.s(8)),
      padding: EdgeInsets.all(r.s(14)),
      decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildExThumb(exerciseData.imageUrl, size: r.s(32), radius: r.s(9), accent: accent, fallbackEmoji: exerciseData.exerciseType.emoji),
              SizedBox(width: r.s(10)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(exerciseData.name, style: GoogleFonts.inter(fontSize: r.fs(13), fontWeight: FontWeight.w600, color: _Palette.text), maxLines: 1, overflow: TextOverflow.ellipsis), SizedBox(height: r.s(3)), Container(padding: EdgeInsets.symmetric(horizontal: r.s(6), vertical: r.s(2)), decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(5))), child: Text('${format.emoji} ${format.shortName}', style: GoogleFonts.inter(fontSize: r.fs(10), color: _Palette.textMuted)))])),
              Text('${completedSets.length} подх', style: GoogleFonts.inter(fontSize: r.fs(10), color: _Palette.textMuted, fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
          if (completedSets.isNotEmpty) ...[
            SizedBox(height: r.s(10)),
            Wrap(spacing: r.s(6), runSpacing: r.s(6), children: completedSets.map((set) {
              final displayText = FitnessHelpers.formatSetForDisplay(set, format);
              return Container(padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(4)), decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(6))), child: Text(displayText, style: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w600, color: _Palette.text, fontFeatures: const [FontFeature.tabularFigures()])));
            }).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodSection(WorkoutLog log, _R r) {
    return Container(
      padding: EdgeInsets.all(r.s(14)),
      decoration: BoxDecoration(color: _Palette.pinkSoft.withOpacity(0.5), borderRadius: BorderRadius.circular(r.s(12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.mood_rounded, color: _Palette.pink, size: r.s(14)), SizedBox(width: r.s(6)), Text('Настроение', style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w600, color: _Palette.pink))]),
          SizedBox(height: r.s(14)),
          Row(children: [if (log.moodEnergy != null) _buildMoodChip('⚡', 'энергия', log.moodEnergy!, r), if (log.moodSleep != null) _buildMoodChip('😴', 'сон', log.moodSleep!, r), if (log.moodMotivation != null) _buildMoodChip('🎯', 'мотив', log.moodMotivation!, r)]),
          if (log.moodNotes != null && log.moodNotes!.isNotEmpty) ...[SizedBox(height: r.s(10)), Text(log.moodNotes!, style: GoogleFonts.inter(fontSize: r.fs(12), fontStyle: FontStyle.italic, color: _Palette.textMuted, height: 1.4))],
        ],
      ),
    );
  }

  Widget _buildMoodChip(String emoji, String label, int value, _R r) {
    final color = value <= 3 ? _Palette.pink : (value <= 5 ? _Palette.peach : (value <= 7 ? _Palette.sage : _Palette.green));
    return Expanded(child: Column(children: [Container(width: r.s(36), height: r.s(36), decoration: BoxDecoration(color: color.withOpacity(0.10), shape: BoxShape.circle), alignment: Alignment.center, child: Text(emoji, style: TextStyle(fontSize: r.fs(16)))), SizedBox(height: r.s(5)), Text('$value/10', style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w600, color: color, fontFeatures: const [FontFeature.tabularFigures()])), SizedBox(height: r.s(2)), Text(label, style: GoogleFonts.inter(fontSize: r.fs(10), color: _Palette.textMuted))]));
  }

  Widget _buildWorkoutPhoto(WorkoutLog log, _R r) {
    final file = File(log.workoutPhotoPath!);
    return _TapScale(
      onTap: () { if (file.existsSync()) _showFullScreenPhoto(context, file); }, scale: 0.98, haptic: false,
      child: Container(
        height: r.s(170),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(r.s(12)), border: Border.all(color: _Palette.divider)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r.s(12)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              file.existsSync() ? Image.file(file, fit: BoxFit.cover) : Container(color: _Palette.bg, child: Center(child: Icon(Icons.broken_image_rounded, color: _Palette.textMuted, size: r.s(32)))),
              Positioned(bottom: r.s(10), right: r.s(10), child: Container(padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(5)), decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(r.s(8))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.fullscreen_rounded, color: Colors.white, size: r.s(14)), SizedBox(width: r.s(4)), Text('Открыть', style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(11), fontWeight: FontWeight.w500))]))),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenPhoto(BuildContext context, File file) {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => Scaffold(backgroundColor: Colors.black, body: SafeArea(child: Stack(children: [Center(child: InteractiveViewer(minScale: 0.5, maxScale: 4.0, child: Image.file(file, fit: BoxFit.contain))), Positioned(top: 8, left: 16, child: _TapScale(onTap: () => Navigator.pop(ctx), scale: 0.9, haptic: false, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 20))))])))));
  }

  Widget _buildCommentField(WorkoutLog log, FitnessProvider provider, _R r) {
    final isCompleted = log.status == WorkoutDayStatus.completed;
    return TextField(
      style: GoogleFonts.inter(fontSize: r.fs(13), color: _Palette.text),
      maxLines: 2,
      decoration: InputDecoration(
        hintText: isCompleted ? 'Добавить комментарий…' : 'Почему пропустили?',
        hintStyle: GoogleFonts.inter(fontSize: r.fs(12), color: _Palette.textMuted),
        filled: true, fillColor: _Palette.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(12)), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(12)), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(12)), borderSide: const BorderSide(color: _Palette.peach, width: 1.2)),
        contentPadding: EdgeInsets.all(r.s(14)),
        prefixIcon: Icon(Icons.comment_rounded, size: r.s(16), color: _Palette.textMuted),
      ),
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          provider.updateLogComment(log.id, value);
          HapticFeedback.mediumImpact();
          _showSnack('Комментарий сохранён', success: true, r: r);
        }
      },
    );
  }

  // =====================================================================
  // MONTH PICKER
  // =====================================================================
  void _showMonthPicker(BuildContext context) {
    final r = _R(context);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
          decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28)))),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: r.s(36), height: r.s(4), decoration: BoxDecoration(color: _Palette.divider, borderRadius: BorderRadius.circular(r.s(2))))),
                SizedBox(height: r.s(20)),
                Row(children: [Text('Месяц и год', style: GoogleFonts.inter(fontSize: r.fs(22), fontWeight: FontWeight.w600, color: _Palette.text))]),
                SizedBox(height: r.s(18)),
                Row(
                  children: [
                    _TapScale(onTap: () { setState(() => _selectedMonth = DateTime(_selectedMonth.year - 1, _selectedMonth.month)); setSheetState(() {}); }, scale: 0.9, haptic: false, child: Container(width: r.s(38), height: r.s(38), decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(11))), child: Icon(Icons.chevron_left_rounded, color: _Palette.textMuted, size: r.s(20)))),
                    Expanded(child: Container(margin: EdgeInsets.symmetric(horizontal: r.s(14)), padding: EdgeInsets.symmetric(vertical: r.s(10)), decoration: BoxDecoration(color: _Palette.peachSoft, borderRadius: BorderRadius.circular(r.s(12))), child: Center(child: Text('${_selectedMonth.year}', style: GoogleFonts.inter(fontSize: r.fs(22), fontWeight: FontWeight.w600, color: _Palette.peach, fontFeatures: const [FontFeature.tabularFigures()]))))),
                    _TapScale(onTap: () { setState(() => _selectedMonth = DateTime(_selectedMonth.year + 1, _selectedMonth.month)); setSheetState(() {}); }, scale: 0.9, haptic: false, child: Container(width: r.s(38), height: r.s(38), decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(11))), child: Icon(Icons.chevron_right_rounded, color: _Palette.textMuted, size: r.s(20)))),
                  ],
                ),
                SizedBox(height: r.s(18)),
                GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: r.s(8), mainAxisSpacing: r.s(8), childAspectRatio: 1.4),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    const monthNames = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
                    final isSelected = _selectedMonth.month == month;
                    final isCurrent = DateTime.now().month == month && DateTime.now().year == _selectedMonth.year;
                    return _TapScale(
                      onTap: () { setState(() => _selectedMonth = DateTime(_selectedMonth.year, month)); Navigator.pop(ctx); }, scale: 0.94, haptic: false,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(color: isSelected ? _Palette.peach : (isCurrent ? _Palette.peachSoft : _Palette.bg), borderRadius: BorderRadius.circular(r.s(12))),
                        alignment: Alignment.center,
                        child: Text(monthNames[index], style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w600, color: isSelected ? Colors.white : _Palette.text)),
                      ),
                    );
                  },
                ),
                SizedBox(height: r.s(16)),
                SizedBox(
                  width: double.infinity, height: r.s(48),
                  child: FilledButton(
                    onPressed: () { setState(() => _selectedMonth = DateTime.now()); Navigator.pop(ctx); },
                    style: FilledButton.styleFrom(backgroundColor: _Palette.peachSoft, foregroundColor: _Palette.peach, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(12)))),
                    child: Text('Сегодня', style: GoogleFonts.inter(fontSize: r.fs(13), fontWeight: FontWeight.w600)),
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
  void _showSnack(String text, {bool success = false, required _R r}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [if (success) ...[Icon(Icons.check_circle_rounded, color: Colors.white, size: r.s(18)), SizedBox(width: r.s(8))], Expanded(child: Text(text))]),
        backgroundColor: success ? _Palette.green : _Palette.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(12))),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<Map<String, int>> _getDaySteps(String dayKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {'steps': prefs.getInt(dayKey) ?? 0, 'minutes': prefs.getInt('${dayKey}_minutes') ?? 0};
    } catch (_) {
      return {'steps': 0, 'minutes': 0};
    }
  }

  List<WorkoutLog> _getLogsForMonth(FitnessProvider provider) {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    return provider.logs.where((log) => log.date.isAfter(start.subtract(const Duration(days: 1))) && log.date.isBefore(end.add(const Duration(days: 1)))).toList();
  }

  String _formatDateFull(DateTime date) {
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) return 'Сегодня';
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day && date.month == yesterday.month && date.year == yesterday.year) return 'Вчера';
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}