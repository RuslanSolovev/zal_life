// features/fitness/ui/screens/progress_screen.dart
// 🆕 v16: format-aware аналитика (сила / кардио / бокс / статика)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';
import 'exercise_detail_screen.dart';

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

class ProgressScreen extends StatefulWidget {
  final bool isDark;
  final bool isCompact;

  const ProgressScreen({
    super.key,
    this.isDark = false,
    this.isCompact = false,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Exercise> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final provider = context.read<FitnessProvider>();
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = provider.exercises.where((e) =>
        e.name.toLowerCase().contains(query) ||
            e.description.toLowerCase().contains(query) ||
            e.muscleGroups
                .any((m) => m.displayName.toLowerCase().contains(query))).toList();
      }
    });
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 ХЕЛПЕРЫ
  // ══════════════════════════════════════════════════════════

  ExerciseFormat _formatFor(Exercise ex) => ex.resolveFormat();

  /// Форматирование значения в тултипе графика.
  String _formatChartValue(double v, String unit) {
    if (unit == 'сек') {
      if (v >= 60) return '${(v / 60).toStringAsFixed(1)} мин';
      return '${v.toStringAsFixed(0)} с';
    }
    if (unit == 'км') return '${v.toStringAsFixed(2)} км';
    if (unit == 'кг') return '${v.toStringAsFixed(0)} кг';
    if (unit == 'раунд') return '${v.toStringAsFixed(0)} р.';
    return '${v.toStringAsFixed(0)} $unit';
  }

  /// Человекочитаемое значение для stat box.
  String _fmtBoxValue(double v, String unit) {
    if (unit == 'сек') {
      if (v >= 3600) return '${(v / 3600).toStringAsFixed(1)} ч';
      if (v >= 60) return '${(v / 60).toStringAsFixed(0)} мин';
      return '${v.toStringAsFixed(0)} с';
    }
    if (unit == 'км') return '${v.toStringAsFixed(2)} км';
    if (unit == 'кг') return '${v.toStringAsFixed(0)} кг';
    if (unit == 'раунд') return '${v.toStringAsFixed(0)}';
    return v.toStringAsFixed(0);
  }

  /// Простой линейный тренд по экстрактору (для non-1RM метрик).
  TrendLine _computeTrend(
      List<ProgressRecord> progress,
      double Function(ProgressRecord) extractor,
      ) {
    if (progress.length < 2) {
      return TrendLine(slope: 0, intercept: 0, confidence: 0);
    }
    final n = progress.length;
    final firstDate = progress.first.date;
    final xs = <double>[];
    final ys = <double>[];
    for (final r in progress) {
      xs.add(r.date.difference(firstDate).inDays.toDouble());
      ys.add(extractor(r));
    }
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += xs[i];
      sumY += ys[i];
      sumXY += xs[i] * ys[i];
      sumX2 += xs[i] * xs[i];
    }
    final denom = n * sumX2 - sumX * sumX;
    if (denom == 0) {
      return TrendLine(
          slope: 0, intercept: sumY / n, confidence: 0);
    }
    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;
    final yMean = sumY / n;
    double ssRes = 0, ssTot = 0;
    for (int i = 0; i < n; i++) {
      final pred = slope * xs[i] + intercept;
      ssRes += (ys[i] - pred) * (ys[i] - pred);
      ssTot += (ys[i] - yMean) * (ys[i] - yMean);
    }
    final r2 = ssTot > 0 ? 1 - ssRes / ssTot : 0.0;
    return TrendLine(slope: slope, intercept: intercept, confidence: r2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = context.watch<FitnessProvider>();

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(isDark),
                _buildTabBar(isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildExerciseProgress(isDark, provider),
                      _buildVolumeProgress(isDark, provider),
                      _buildMuscleProgress(isDark, provider),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSearching)
              Positioned.fill(
                child: _buildSearchOverlay(isDark, provider),
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // HEADER (без изменений)
  // =====================================================================

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      'ПРОГРЕСС',
                      style: TextStyle(
                        color: _Power.volt,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Аналитика',
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
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: _Power.card(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _Power.separator(isDark),
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _Power.textPrimary(isDark),
              ),
              decoration: InputDecoration(
                hintText: 'Поиск упражнения…',
                hintStyle: TextStyle(
                  color: _Power.textTertiary(isDark),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _Power.textTertiary(isDark),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _searchController.clear();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _Power.textTertiary(isDark)
                          .withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: _Power.textSecondary(isDark),
                      size: 14,
                    ),
                  ),
                )
                    : null,
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // TAB BAR — переименован «ТОННАЖ» → «ОБЪЁМ»
  // =====================================================================

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _Power.card2(isDark),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: _Power.textSecondary(isDark),
          indicator: BoxDecoration(
            color: _Power.volt,
            borderRadius: BorderRadius.circular(11),
            boxShadow: _Power.softGlow(_Power.volt, strength: 0.35),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          tabs: const [
            Tab(text: 'УПРАЖНЕНИЯ'),
            Tab(text: 'ОБЪЁМ'),
            Tab(text: 'МЫШЦЫ'),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // SEARCH OVERLAY (без изменений)
  // =====================================================================

  Widget _buildSearchOverlay(bool isDark, FitnessProvider provider) {
    return Container(
      color: _Power.bg(isDark),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: _Power.card(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _Power.volt.withOpacity(0.4),
                    width: 0.8,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _Power.textPrimary(isDark),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Поиск…',
                    hintStyle: TextStyle(
                      color: _Power.textTertiary(isDark),
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _Power.volt,
                      size: 20,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _searchController.clear();
                      },
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _Power.textTertiary(isDark).withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: _Power.textSecondary(isDark),
                          size: 14,
                        ),
                      ),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _searchResults.isEmpty
                  ? _buildSearchEmpty(isDark)
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final ex = _searchResults[index];
                  final summary =
                  provider.getExerciseDetailedSummary(ex.id);
                  final format = _formatFor(ex);
                  final accent = ex.muscleGroups.isNotEmpty
                      ? ex.muscleGroups.first.color
                      : _Power.volt;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _searchController.clear();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExerciseDetailScreen(
                            exercise: ex,
                            isDark: isDark,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _Power.card(isDark),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _Power.separator(isDark),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              ex.exerciseType.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: _Power.textPrimary(isDark),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: _Power.ice
                                            .withOpacity(0.14),
                                        borderRadius:
                                        BorderRadius.circular(5),
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
                                    const SizedBox(width: 6),
                                    if (summary.totalWorkouts > 0)
                                      Text(
                                        '${summary.totalWorkouts} трен.',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _Power.textTertiary(
                                              isDark),
                                        ),
                                      )
                                    else
                                      Text(
                                        'НЕТ ДАННЫХ',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                          color: _Power.textTertiary(
                                              isDark),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (summary.totalWorkouts > 0)
                            _buildSearchPrimaryValue(
                                format, summary, isDark),
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

  /// 🆕 Главное число в поиске — по формату.
  Widget _buildSearchPrimaryValue(
      ExerciseFormat format, ExerciseDetailedSummary summary, bool isDark) {
    String value = '—';
    String label = '';
    Color color = _Power.volt;

    if (format == ExerciseFormat.setsReps && summary.maxWeight > 0) {
      value = '${summary.maxWeight.toStringAsFixed(0)} кг';
      label = 'МАКС';
      color = _Power.volt;
    } else if ((format == ExerciseFormat.continuous ||
        format == ExerciseFormat.intervals) &&
        (summary.bestDistance ?? 0) > 0) {
      value = '${(summary.bestDistance ?? 0).toStringAsFixed(1)} км';
      label = 'ВСЕГО';
      color = _Power.ice;
    } else if (format == ExerciseFormat.rounds &&
        (summary.bestRounds ?? 0) > 0) {
      value = '${(summary.bestRounds ?? 0)} р.';
      label = 'РАУНД';
      color = _Power.plasma;
    } else if (format == ExerciseFormat.hold &&
        (summary.bestHoldSeconds ?? 0) > 0) {
      value = _fmtBoxValue((summary.bestHoldSeconds ?? 0).toDouble(), 'сек');
      label = 'ЛУЧШ';
      color = _Power.lime;
    } else if ((summary.bestDuration ?? 0) > 0) {
      value = _fmtBoxValue((summary.bestDuration ?? 0).toDouble(), 'сек');
      label = 'ВСЕГО';
      color = _Power.ice;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            color: _Power.textTertiary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _Power.volt.withOpacity(0.10),
              shape: BoxShape.circle,
              boxShadow: _Power.softGlow(_Power.volt, strength: 0.15),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'ПОИСК',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ничего не найдено',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: _Power.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить запрос',
            style: TextStyle(
              fontSize: 13,
              color: _Power.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1: EXERCISE PROGRESS — format-aware
  // ══════════════════════════════════════════════════════════

  Widget _buildExerciseProgress(bool isDark, FitnessProvider provider) {
    final exercises = provider.exercises
        .where((e) => provider.getExerciseProgress(e.id).isNotEmpty)
        .toList();

    if (exercises.isEmpty) {
      return _buildEmptyState(
        isDark,
        'НЕТ ДАННЫХ',
        'Начните тренироваться',
        'Прогресс появится здесь',
      );
    }

    exercises.sort((a, b) {
      final aProgress = provider.getExerciseProgress(a.id).length;
      final bProgress = provider.getExerciseProgress(b.id).length;
      return bProgress.compareTo(aProgress);
    });

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final summary = provider.getExerciseDetailedSummary(exercise.id);
        final progress = provider.getExerciseProgress(exercise.id);
        final lastRecord = progress.last;
        final format = _formatFor(exercise);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _Power.card(isDark),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _Power.separator(isDark),
              width: 0.5,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              childrenPadding:
              const EdgeInsets.fromLTRB(12, 0, 12, 12),
              iconColor: _Power.volt,
              collapsedIconColor: _Power.textSecondary(isDark),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: exercise.muscleGroups.isNotEmpty
                      ? exercise.muscleGroups.first.color
                      .withOpacity(0.14)
                      : _Power.volt.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: _Power.softGlow(
                    exercise.muscleGroups.isNotEmpty
                        ? exercise.muscleGroups.first.color
                        : _Power.volt,
                    strength: 0.15,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  exercise.exerciseType.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              title: Text(
                exercise.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: _Power.textPrimary(isDark),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
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
                    const SizedBox(width: 6),
                    Text(
                      '${summary.totalWorkouts} ТРЕН. • ${summary.totalSets} ПОДХ.',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: _Power.textTertiary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              children: [
                // 🆕 Статы по формату
                _buildStatsGrid(
                    isDark, format, summary, lastRecord, progress),

                // 🆕 Графики по формату
                const SizedBox(height: 14),
                ..._buildChartsForFormat(
                    isDark, format, progress),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExerciseDetailScreen(
                            exercise: exercise,
                            isDark: isDark,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Power.volt,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      shadowColor: _Power.volt.withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'ПОДРОБНАЯ ИСТОРИЯ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
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
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 STATS GRID — dispatch по формату
  // ══════════════════════════════════════════════════════════

  Widget _buildStatsGrid(
      bool isDark,
      ExerciseFormat format,
      ExerciseDetailedSummary summary,
      ProgressRecord lastRecord,
      List<ProgressRecord> progress,
      ) {
    switch (format) {
      case ExerciseFormat.setsReps:
        return _buildStrengthStatsGrid(
            isDark, summary, lastRecord, progress);
      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        return _buildCardioStatsGrid(isDark, summary, lastRecord);
      case ExerciseFormat.rounds:
        return _buildRoundsStatsGrid(isDark, summary, lastRecord);
      case ExerciseFormat.hold:
        return _buildHoldStatsGrid(isDark, summary, lastRecord);
      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        return _buildTimedStatsGrid(isDark, summary, lastRecord);
    }
  }

  Widget _buildStrengthStatsGrid(
      bool isDark,
      ExerciseDetailedSummary summary,
      ProgressRecord lastRecord,
      List<ProgressRecord> progress,
      ) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatBox(
              isDark,
              'МИН',
              '${summary.minWeight.toStringAsFixed(0)} кг',
              summary.minDate != null
                  ? '${summary.minDate!.day}.${summary.minDate!.month}'
                  : '',
              _Power.ice,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              'МАКС',
              '${summary.maxWeight.toStringAsFixed(0)} кг',
              summary.maxDate != null
                  ? '${summary.maxDate!.day}.${summary.maxDate!.month}'
                  : '',
              _Power.green,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatBox(
              isDark,
              'СРЕДНЕЕ',
              '${summary.avgWeight.toStringAsFixed(0)} кг',
              '',
              _Power.plasma,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              '1RM',
              '${lastRecord.estimated1RM.toStringAsFixed(0)} кг',
              '${lastRecord.date.day}.${lastRecord.date.month}',
              _Power.volt,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatBox(
              isDark,
              'ТРЕНИРОВОК',
              '${summary.totalWorkouts}',
              '',
              _Power.magma,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              'ПОДХОДОВ',
              '${summary.totalSets}',
              '',
              _Power.lime,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardioStatsGrid(
      bool isDark,
      ExerciseDetailedSummary summary,
      ProgressRecord lastRecord,
      ) {
    final totalKm = summary.bestDistance ?? 0;
    final totalSec = (summary.bestDuration ?? 0).toDouble();
    final bestPace = summary.bestPace;

    return Column(
      children: [
        Row(
          children: [
            _buildStatBox(
              isDark,
              'ВСЕГО КМ',
              totalKm > 0 ? '${totalKm.toStringAsFixed(2)} км' : '—',
              '',
              _Power.ice,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              'ВСЕГО ВРЕМЯ',
              totalSec > 0 ? _fmtBoxValue(totalSec, 'сек') : '—',
              '',
              _Power.lime,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatBox(
              isDark,
              'ЛУЧШИЙ ТЕМП',
              bestPace != null && bestPace > 0
                  ? '${FitnessHelpers.formatPace(bestPace)}/км'
                  : '—',
              '',
              _Power.plasma,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              'ПОСЛЕДНЯЯ',
              lastRecord.date != null
                  ? '${lastRecord.date.day}.${lastRecord.date.month}'
                  : '',
              lastRecord.bestDistance != null
                  ? '${lastRecord.bestDistance!.toStringAsFixed(2)} км'
                  : '',
              _Power.volt,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatBox(
              isDark,
              'ТРЕНИРОВОК',
              '${summary.totalWorkouts}',
              '',
              _Power.magma,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              'ПОДХОДОВ',
              '${summary.totalSets}',
              '',
              _Power.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoundsStatsGrid(
      bool isDark,
      ExerciseDetailedSummary summary,
      ProgressRecord lastRecord,
      ) {
    final totalRounds = (summary.bestRounds ?? 0).toDouble();
    final totalSec = (summary.bestDuration ?? 0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            _buildStatBox(
              isDark,
              'ВСЕГО',
              totalRounds > 0 ? '${totalRounds.toInt()}' : '—',
              'раундов',
              _Power.plasma,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              'ВРЕМЯ',
              totalSec > 0 ? _fmtBoxValue(totalSec, 'сек') : '—',
              '',
              _Power.lime,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatBox(
              isDark,
              'ПОСЛЕДНЯЯ',
              lastRecord.date != null
                  ? '${lastRecord.date.day}.${lastRecord.date.month}'
                  : '',
              lastRecord.bestRounds != null
                  ? '${lastRecord.bestRounds} р.'
                  : '',
              _Power.volt,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              'ТРЕНИРОВОК',
              '${summary.totalWorkouts}',
              '',
              _Power.magma,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHoldStatsGrid(
      bool isDark,
      ExerciseDetailedSummary summary,
      ProgressRecord lastRecord,
      ) {
    final bestHold = (summary.bestHoldSeconds ?? 0).toDouble();
    final totalSec = (summary.bestDuration ?? 0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            _buildStatBox(
              isDark,
              'ЛУЧШЕЕ',
              bestHold > 0 ? _fmtBoxValue(bestHold, 'сек') : '—',
              '',
              _Power.lime,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              'ВСЕГО',
              totalSec > 0 ? _fmtBoxValue(totalSec, 'сек') : '—',
              '',
              _Power.ice,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatBox(
              isDark,
              'ПОСЛЕДНЯЯ',
              lastRecord.date != null
                  ? '${lastRecord.date.day}.${lastRecord.date.month}'
                  : '',
              lastRecord.bestHoldSeconds != null
                  ? _fmtBoxValue(
                  lastRecord.bestHoldSeconds!.toDouble(), 'сек')
                  : '',
              _Power.volt,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              'ТРЕНИРОВОК',
              '${summary.totalWorkouts}',
              '',
              _Power.magma,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimedStatsGrid(
      bool isDark,
      ExerciseDetailedSummary summary,
      ProgressRecord lastRecord,
      ) {
    final totalSec = (summary.bestDuration ?? 0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            _buildStatBox(
              isDark,
              'ВСЕГО',
              totalSec > 0 ? _fmtBoxValue(totalSec, 'сек') : '—',
              '',
              _Power.ice,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              'ПОСЛЕДНЯЯ',
              lastRecord.date != null
                  ? '${lastRecord.date.day}.${lastRecord.date.month}'
                  : '',
              lastRecord.bestDuration != null
                  ? _fmtBoxValue(
                  lastRecord.bestDuration!.toDouble(), 'сек')
                  : '',
              _Power.volt,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatBox(
              isDark,
              'ТРЕНИРОВОК',
              '${summary.totalWorkouts}',
              '',
              _Power.magma,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              isDark,
              'ПОДХОДОВ',
              '${summary.totalSets}',
              '',
              _Power.lime,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(
      bool isDark,
      String label,
      String value,
      String date,
      Color accentColor,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _Power.card2(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withOpacity(0.2),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: _Power.textTertiary(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1,
                color: accentColor,
              ),
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                date,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _Power.textTertiary(isDark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 ГРАФИКИ ПО ФОРМАТУ
  // ══════════════════════════════════════════════════════════

  List<Widget> _buildChartsForFormat(
      bool isDark,
      ExerciseFormat format,
      List<ProgressRecord> progress,
      ) {
    switch (format) {
      case ExerciseFormat.setsReps:
        return [
          _buildModernChart(
            isDark,
            title: 'ДИНАМИКА 1RM',
            progress: progress,
            extractor: (r) => r.estimated1RM,
            unit: 'кг',
            color: _Power.volt,
            showTrend: true,
          ),
          const SizedBox(height: 14),
          _buildModernChart(
            isDark,
            title: 'ОБЪЁМ ТРЕНИРОВКИ',
            progress: progress,
            extractor: (r) => r.totalVolume,
            unit: 'кг',
            color: _Power.ice,
            showTrend: false,
          ),
        ];

      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        return [
          _buildModernChart(
            isDark,
            title: 'ДИСТАНЦИЯ',
            progress: progress,
            extractor: (r) => r.bestDistance ?? 0,
            unit: 'км',
            color: _Power.ice,
            showTrend: true,
          ),
          const SizedBox(height: 14),
          _buildModernChart(
            isDark,
            title: 'ВРЕМЯ',
            progress: progress,
            extractor: (r) => (r.bestDuration ?? 0).toDouble(),
            unit: 'сек',
            color: _Power.lime,
            showTrend: false,
          ),
        ];

      case ExerciseFormat.rounds:
        return [
          _buildModernChart(
            isDark,
            title: 'РАУНДЫ ЗА ТРЕНИРОВКУ',
            progress: progress,
            extractor: (r) => (r.bestRounds ?? 0).toDouble(),
            unit: 'раунд',
            color: _Power.plasma,
            showTrend: true,
          ),
        ];

      case ExerciseFormat.hold:
        return [
          _buildModernChart(
            isDark,
            title: 'УДЕРЖАНИЕ',
            progress: progress,
            extractor: (r) => (r.bestHoldSeconds ?? 0).toDouble(),
            unit: 'сек',
            color: _Power.lime,
            showTrend: true,
          ),
        ];

      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        return [
          _buildModernChart(
            isDark,
            title: 'ВРЕМЯ',
            progress: progress,
            extractor: (r) => (r.bestDuration ?? 0).toDouble(),
            unit: 'сек',
            color: _Power.ice,
            showTrend: false,
          ),
        ];
    }
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 УНИВЕРСАЛЬНЫЙ ГРАФИК
  // ══════════════════════════════════════════════════════════

  Widget _buildModernChart(
      bool isDark, {
        required String title,
        required List<ProgressRecord> progress,
        required double Function(ProgressRecord) extractor,
        required String unit,
        required Color color,
        required bool showTrend,
      }) {
    if (progress.length < 2) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _Power.card2(isDark),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: _Power.textTertiary(isDark),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Недостаточно данных',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _Power.textSecondary(isDark),
              ),
            ),
          ],
        ),
      );
    }

    final spots = <FlSpot>[];
    final firstDate = progress.first.date;
    double maxY = 0;
    double minY = double.infinity;

    for (final record in progress) {
      final x = record.date.difference(firstDate).inDays.toDouble();
      final y = extractor(record);
      spots.add(FlSpot(x, y));
      if (y > maxY) maxY = y;
      if (y < minY) minY = y;
    }

    // Если все значения 0 — показываем пустое сообщение
    if (maxY == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _Power.card2(isDark),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: _Power.textTertiary(isDark),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Нет данных по этой метрике',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _Power.textSecondary(isDark),
              ),
            ),
          ],
        ),
      );
    }

    // Тренд/прогноз
    TrendLine? trendLine;
    if (showTrend && spots.length >= 2) {
      trendLine = _computeTrend(progress, extractor);
    }

    final predictionSpots = <FlSpot>[];
    if (trendLine != null && trendLine.slope != 0) {
      final lastX = spots.last.x;
      for (int i = 1; i <= 14; i++) {
        final predictedY = trendLine.predict((lastX + i).toInt());
        predictionSpots.add(FlSpot(lastX + i, predictedY));
        if (predictedY > maxY) maxY = predictedY;
      }
    }

    final yRange = maxY - minY;
    final padding = yRange * 0.1;
    final adjustedMaxY = maxY + padding;
    final adjustedMinY = minY > padding ? minY - padding : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Power.card2(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _Power.separator(isDark),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: _Power.textPrimary(isDark),
                ),
              ),
              const Spacer(),
              if (trendLine != null && trendLine.slope != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (trendLine.slope > 0
                        ? _Power.green
                        : _Power.red)
                        .withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendLine.slope > 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: trendLine.slope > 0
                            ? _Power.green
                            : _Power.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trendLine.slope > 0 ? "+" : ""}${(trendLine.slope * 30).toStringAsFixed(1)}/мес',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          height: 1,
                          color: trendLine.slope > 0
                              ? _Power.green
                              : _Power.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minY: adjustedMinY,
                maxY: adjustedMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: _Power.separator(isDark),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) => Text(
                        _shortLabelFor(value, unit),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _Power.textTertiary(isDark),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (spots.last.x / 5).clamp(1, 30).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final date =
                        firstDate.add(Duration(days: value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${date.day}.${date.month}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _Power.textTertiary(isDark),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length < 15,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: _Power.bg(isDark),
                            strokeWidth: 2,
                            strokeColor: color,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  if (predictionSpots.isNotEmpty)
                    LineChartBarData(
                      spots: predictionSpots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: color.withOpacity(0.4),
                      barWidth: 2,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipColor: (spot) => _Power.card(isDark),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          _formatChartValue(spot.y, unit),
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🆕 Короткий лейбл для оси Y.
  String _shortLabelFor(double value, String unit) {
    if (unit == 'сек') {
      if (value >= 3600) return '${(value / 3600).toStringAsFixed(1)}ч';
      if (value >= 60) return '${(value / 60).toStringAsFixed(0)}м';
      return '${value.toStringAsFixed(0)}';
    }
    if (unit == 'кг' && value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    if (unit == 'км') return value.toStringAsFixed(1);
    return value.toStringAsFixed(0);
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2: VOLUME PROGRESS — мультиметрики
  // ══════════════════════════════════════════════════════════

  Widget _buildVolumeProgress(bool isDark, FitnessProvider provider) {
    final tonnageMap = provider.getTonnageByExercise();

    if (tonnageMap.isEmpty) {
      return _buildEmptyState(
        isDark,
        'ОБЪЁМ',
        'Нет данных',
        'Завершите первую тренировку',
      );
    }

    final entries = tonnageMap.entries.toList()
      ..sort((a, b) {
        final exA = provider.exercises.firstWhere(
              (e) => e.id == a.key,
          orElse: () => Exercise(id: '', name: ''),
        );
        final exB = provider.exercises.firstWhere(
              (e) => e.id == b.key,
          orElse: () => Exercise(id: '', name: ''),
        );
        final pA = _groupPriority(exA);
        final pB = _groupPriority(exB);
        if (pA != pB) return pA.compareTo(pB);
        double vA, vB;
        switch (pA) {
          case 0:
            vA = a.value.totalVolume;
            vB = b.value.totalVolume;
            break;
          case 1:
            vA = a.value.byMetric['km'] ?? 0;
            vB = b.value.byMetric['km'] ?? 0;
            break;
          case 2:
            vA = a.value.byMetric['rounds'] ?? 0;
            vB = b.value.byMetric['rounds'] ?? 0;
            break;
          default:
            vA = a.value.byMetric['sec'] ?? 0;
            vB = b.value.byMetric['sec'] ?? 0;
            break;
        }
        return vB.compareTo(vA);
      });

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final exData = provider.exercises.firstWhere(
              (e) => e.id == entry.key,
          orElse: () => Exercise(id: '', name: 'Удалено'),
        );
        final info = entry.value;
        final format = exData.id.isEmpty
            ? ExerciseFormat.setsReps
            : _formatFor(exData);
        final accent = exData.muscleGroups.isNotEmpty
            ? exData.muscleGroups.first.color
            : _Power.volt;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _Power.card(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _Power.separator(isDark),
              width: 0.5,
            ),
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
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow:
                      _Power.softGlow(accent, strength: 0.15),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      exData.exerciseType.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exData.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: _Power.textPrimary(isDark),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
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
                            const SizedBox(width: 6),
                            Text(
                              '${info.totalWorkouts} ТРЕНИРОВОК',
                              style: TextStyle(
                                fontSize: 9,
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
                  _buildVolumePrimaryBadge(info, format, isDark),
                ],
              ),
              const SizedBox(height: 12),
              // 🆕 Мультиметрики (kg / km / rounds / sec / punches / kcal / reps)
              _buildVolumeMetricChips(info, isDark),
            ],
          ),
        );
      },
    );
  }

  /// 🆕 Приоритет для сортировки по типу.
  int _groupPriority(Exercise ex) {
    switch (ex.exerciseType) {
      case ExerciseType.strength:
      case ExerciseType.bodyweight:
        return 0;
      case ExerciseType.cardio:
        return 1;
      case ExerciseType.boxing:
        return 2;
      case ExerciseType.yoga:
        return 3;
      case ExerciseType.other:
        return 4;
    }
  }

  /// 🆕 Правая «главная цифра» в карточке — по формату.
  Widget _buildVolumePrimaryBadge(
      ExerciseTonnageInfo info, ExerciseFormat format, bool isDark) {
    String value = '—';
    String label = '';
    Color color = _Power.volt;

    if (format == ExerciseFormat.setsReps && info.totalVolume > 0) {
      value = info.totalVolume >= 1000
          ? '${(info.totalVolume / 1000).toStringAsFixed(1)}k'
          : info.totalVolume.toStringAsFixed(0);
      label = 'КГ';
      color = _Power.volt;
    } else if ((format == ExerciseFormat.continuous ||
        format == ExerciseFormat.intervals) &&
        (info.byMetric['km'] ?? 0) > 0) {
      final km = info.byMetric['km']!;
      value = km.toStringAsFixed(km >= 10 ? 1 : 2);
      label = 'КМ';
      color = _Power.ice;
    } else if (format == ExerciseFormat.rounds &&
        (info.byMetric['rounds'] ?? 0) > 0) {
      value = (info.byMetric['rounds']!).toStringAsFixed(0);
      label = 'РАУНД';
      color = _Power.plasma;
    } else if ((info.byMetric['sec'] ?? 0) > 0) {
      final sec = info.byMetric['sec']!;
      if (sec >= 3600) {
        value = '${(sec / 3600).toStringAsFixed(1)}';
        label = 'ЧАС';
      } else if (sec >= 60) {
        value = '${(sec / 60).toStringAsFixed(0)}';
        label = 'МИН';
      } else {
        value = sec.toStringAsFixed(0);
        label = 'СЕК';
      }
      color = _Power.lime;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            height: 1,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: _Power.textTertiary(isDark),
          ),
        ),
      ],
    );
  }

  /// 🆕 Все непустые метрики упражнения в виде чипов.
  Widget _buildVolumeMetricChips(ExerciseTonnageInfo info, bool isDark) {
    final chips = <Widget>[];

    if (info.totalVolume > 0) {
      chips.add(_buildVolumeChip(
        icon: '📊',
        value: info.totalVolume >= 1000
            ? '${(info.totalVolume / 1000).toStringAsFixed(1)}k'
            : info.totalVolume.toStringAsFixed(0),
        label: 'КГ',
        color: _Power.volt,
        isDark: isDark,
      ));
    }
    if ((info.byMetric['km'] ?? 0) > 0) {
      final km = info.byMetric['km']!;
      chips.add(_buildVolumeChip(
        icon: '📏',
        value: km.toStringAsFixed(km >= 10 ? 1 : 2),
        label: 'КМ',
        color: _Power.ice,
        isDark: isDark,
      ));
    }
    if ((info.byMetric['sec'] ?? 0) > 0) {
      final sec = info.byMetric['sec']!;
      chips.add(_buildVolumeChip(
        icon: '⏱️',
        value: sec >= 3600
            ? '${(sec / 3600).toStringAsFixed(1)}ч'
            : '${(sec / 60).toStringAsFixed(0)}м',
        label: 'ВРЕМЯ',
        color: _Power.lime,
        isDark: isDark,
      ));
    }
    if ((info.byMetric['rounds'] ?? 0) > 0) {
      chips.add(_buildVolumeChip(
        icon: '🥊',
        value: info.byMetric['rounds']!.toStringAsFixed(0),
        label: 'РАУНД',
        color: _Power.plasma,
        isDark: isDark,
      ));
    }
    if ((info.byMetric['punches'] ?? 0) > 0) {
      chips.add(_buildVolumeChip(
        icon: '👊',
        value: info.byMetric['punches']!.toStringAsFixed(0),
        label: 'УДАР',
        color: _Power.magma,
        isDark: isDark,
      ));
    }
    if ((info.byMetric['kcal'] ?? 0) > 0) {
      chips.add(_buildVolumeChip(
        icon: '🔥',
        value: info.byMetric['kcal']!.toStringAsFixed(0),
        label: 'ККАЛ',
        color: _Power.magma,
        isDark: isDark,
      ));
    }
    if ((info.byMetric['reps'] ?? 0) > 0 && info.totalVolume == 0) {
      chips.add(_buildVolumeChip(
        icon: '🔢',
        value: info.byMetric['reps']!.toStringAsFixed(0),
        label: 'ПОВТ',
        color: _Power.volt,
        isDark: isDark,
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }

  Widget _buildVolumeChip({
    required String icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              height: 1,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              height: 1,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 3: MUSCLE PROGRESS — кг + чипы (км / раунды / сек)
  // ══════════════════════════════════════════════════════════

  Widget _buildMuscleProgress(bool isDark, FitnessProvider provider) {
    final muscleMap = provider.getTonnageByMuscle();

    if (muscleMap.isEmpty) {
      return _buildEmptyState(
        isDark,
        'МЫШЦЫ',
        'Нет данных',
        'Завершите первую тренировку',
      );
    }

    // 🆕 «Главная метрика» мышцы (кг → км → раунд → сек)
    double primaryOf(MuscleTonnageInfo? s) {
      if (s == null) return 0;
      if (s.totalVolume > 0) return s.totalVolume;
      if ((s.byMetric['km'] ?? 0) > 0) return s.byMetric['km']! * 1000;
      if ((s.byMetric['rounds'] ?? 0) > 0) {
        return s.byMetric['rounds']! * 100;
      }
      return s.byMetric['sec'] ?? 0;
    }

    final maxVolume = muscleMap.values.fold<double>(
      0,
          (max, s) => primaryOf(s) > max ? primaryOf(s) : max,
    );

    // 🆕 Фильтр: показываем, если есть хоть одна метрика
    final visibleMuscles = MuscleGroup.values
        .where((m) => m != MuscleGroup.fullBody)
        .where((m) {
      final s = muscleMap[m];
      if (s == null) return false;
      return s.totalVolume > 0 ||
          (s.byMetric['km'] ?? 0) > 0 ||
          (s.byMetric['sec'] ?? 0) > 0 ||
          (s.byMetric['rounds'] ?? 0) > 0;
    }).toList();

    if (visibleMuscles.isEmpty) {
      return _buildEmptyState(
        isDark,
        'МЫШЦЫ',
        'Нет данных',
        'Завершите первую тренировку',
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _Power.volt.withOpacity(0.10),
                  _Power.volt.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _Power.volt.withOpacity(0.2),
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
                        color: _Power.volt.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: _Power.volt,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'ОБЪЁМ ПО ГРУППАМ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                        color: _Power.volt,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'За всё время тренировок',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _Power.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...visibleMuscles.map((muscle) {
            final stats = muscleMap[muscle];
            final primary = primaryOf(stats);
            final progress = maxVolume > 0 ? primary / maxVolume : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
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
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: muscle.color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(11),
                          boxShadow:
                          _Power.softGlow(muscle.color, strength: 0.2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          muscle.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              muscle.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: _Power.textPrimary(isDark),
                              ),
                            ),
                            if (stats != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                '${stats.totalWorkouts} ТРЕН. • ${stats.totalSets} ПОДХ.',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: _Power.textTertiary(isDark),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 🆕 Мультиметрики справа
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if ((stats?.totalVolume ?? 0) > 0)
                            Text(
                              '${((stats?.totalVolume ?? 0) / 1000).toStringAsFixed(1)}k',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                height: 1,
                                color: muscle.color,
                              ),
                            ),
                          if ((stats?.byMetric['km'] ?? 0) > 0)
                            Text(
                              '${(stats!.byMetric['km']!).toStringAsFixed(1)} км',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                color: _Power.ice,
                              ),
                            ),
                          if ((stats?.byMetric['rounds'] ?? 0) > 0)
                            Text(
                              '${stats!.byMetric['rounds']!.toStringAsFixed(0)} р.',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                color: _Power.plasma,
                              ),
                            ),
                          if ((stats?.byMetric['sec'] ?? 0) > 0 &&
                              (stats?.totalVolume ?? 0) == 0 &&
                              (stats?.byMetric['km'] ?? 0) == 0 &&
                              (stats?.byMetric['rounds'] ?? 0) == 0)
                            Text(
                              _fmtBoxValue(stats!.byMetric['sec']!, 'сек'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                color: _Power.lime,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.05, 1.0),
                      backgroundColor: _Power.separator(isDark),
                      valueColor:
                      AlwaysStoppedAnimation<Color>(muscle.color),
                      minHeight: 6,
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

  // =====================================================================
  // EMPTY STATE
  // =====================================================================

  Widget _buildEmptyState(
      bool isDark,
      String caps,
      String title,
      String subtitle,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _Power.volt.withOpacity(0.10),
                shape: BoxShape.circle,
                boxShadow: _Power.softGlow(_Power.volt, strength: 0.15),
              ),
              child: const Icon(
                Icons.show_chart_rounded,
                size: 40,
                color: _Power.volt,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              caps,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                color: _Power.volt,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: _Power.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _Power.textSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}