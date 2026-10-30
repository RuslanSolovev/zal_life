// features/fitness/ui/screens/exercise_detail_screen.dart
// 🆕 v16: format-aware детальная аналитика (сила / кардио / бокс / статика)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/enums.dart';
import '../../../models/fitness_models.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';
import 'package:fl_chart/fl_chart.dart';

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

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final bool isDark;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    this.isDark = false,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 ХЕЛПЕРЫ
  // ══════════════════════════════════════════════════════════

  ExerciseFormat get _format => widget.exercise.resolveFormat();

  /// Универсальный тренд по экстрактору.
  TrendLine _computeTrendFor(
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
      return TrendLine(slope: 0, intercept: sumY / n, confidence: 0);
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

  /// Форматирование времени в читаемый вид.
  String _fmtSec(int sec) {
    if (sec <= 0) return '0с';
    if (sec < 60) return '${sec}с';
    final m = sec ~/ 60;
    final s = sec % 60;
    return s > 0 ? '${m}м ${s}с' : '${m}м';
  }

  /// 🆕 Строка-сводка записи для истории.
  String _formatRecordSummary(ProgressRecord r) {
    switch (_format) {
      case ExerciseFormat.setsReps:
        return '${r.bestWeight.toStringAsFixed(0)} кг × ${r.bestReps}';
      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        final parts = <String>[];
        if ((r.bestDistance ?? 0) > 0) {
          parts.add(
              '${r.bestDistance!.toStringAsFixed(r.bestDistance! >= 10 ? 1 : 2)} км');
        }
        if ((r.bestDuration ?? 0) > 0) {
          parts.add(_fmtSec(r.bestDuration!));
        }
        return parts.isEmpty ? '—' : parts.join(' · ');
      case ExerciseFormat.rounds:
        final parts = <String>[];
        if ((r.bestRounds ?? 0) > 0) parts.add('${r.bestRounds} р.');
        if ((r.bestDuration ?? 0) > 0) parts.add(_fmtSec(r.bestDuration!));
        return parts.isEmpty ? '—' : parts.join(' · ');
      case ExerciseFormat.hold:
        return _fmtSec(r.bestHoldSeconds ?? r.bestDuration ?? 0);
      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        return _fmtSec(r.bestDuration ?? 0);
    }
  }

  /// 🆕 Подпись под основной строкой в истории.
  String _formatRecordSubtitle(ProgressRecord r) {
    switch (_format) {
      case ExerciseFormat.setsReps:
        return '${r.totalSets} подх. • ${r.totalVolume.toStringAsFixed(0)} кг';
      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        if ((r.bestPace ?? 0) > 0) {
          return '${r.totalSets} подх. • темп ${FitnessHelpers.formatPace(r.bestPace!)}/км';
        }
        return '${r.totalSets} подх.';
      case ExerciseFormat.rounds:
        return '${r.totalSets} подх.';
      case ExerciseFormat.hold:
        return '${r.totalSets} подх.';
      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        return '${r.totalSets} подх.';
    }
  }

  /// 🆕 Правая часть записи в истории (акцентная метрика).
  ({String value, String label, Color color}) _formatRecordAccent(
      ProgressRecord r) {
    switch (_format) {
      case ExerciseFormat.setsReps:
        return (
        value: r.estimated1RM.toStringAsFixed(0),
        label: '1RM',
        color: _Power.volt,
        );
      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        return (
        value: (r.bestDistance ?? 0).toStringAsFixed(2),
        label: 'КМ',
        color: _Power.ice,
        );
      case ExerciseFormat.rounds:
        return (
        value: '${r.bestRounds ?? 0}',
        label: 'РАУНД',
        color: _Power.plasma,
        );
      case ExerciseFormat.hold:
        return (
        value: _fmtSec(r.bestHoldSeconds ?? 0),
        label: 'УДЕРЖ',
        color: _Power.lime,
        );
      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        return (
        value: _fmtSec(r.bestDuration ?? 0),
        label: 'ВРЕМЯ',
        color: _Power.ice,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = context.watch<FitnessProvider>();
    final progressRecords = provider.getExerciseProgress(widget.exercise.id);
    final lastRecord = provider.getLastProgress(widget.exercise.id);
    final format = _format;

    final trendLine = format == ExerciseFormat.setsReps
        ? FitnessHelpers.calculateTrendLine(progressRecords)
        : _computeTrendFor(
      progressRecords,
          (r) {
        switch (format) {
          case ExerciseFormat.continuous:
          case ExerciseFormat.intervals:
            return r.bestDistance ?? 0;
          case ExerciseFormat.rounds:
            return (r.bestRounds ?? 0).toDouble();
          case ExerciseFormat.hold:
            return (r.bestHoldSeconds ?? 0).toDouble();
          case ExerciseFormat.timedSets:
          case ExerciseFormat.freeform:
            return (r.bestDuration ?? 0).toDouble();
          case ExerciseFormat.setsReps:
            return r.estimated1RM;
        }
      },
    );

    final accent = widget.exercise.muscleGroups.isNotEmpty
        ? widget.exercise.muscleGroups.first.color
        : _Power.volt;

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: _Power.bg(isDark).withOpacity(0.85),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 60,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
              child: GestureDetector(
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
            ),
            title: Text(
              widget.exercise.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: _Power.textPrimary(isDark),
              ),
            ),
            centerTitle: true,
            actions: [
              if (widget.exercise.isCustom)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showEditDialog(context, isDark, provider);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _Power.volt.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: _Power.volt,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exercise.isCustom
                        ? 'МОЁ УПРАЖНЕНИЕ'
                        : 'УПРАЖНЕНИЕ',
                    style: const TextStyle(
                      color: _Power.volt,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.exercise.name,
                    style: TextStyle(
                      color: _Power.textPrimary(isDark),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1.08,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildHeroCard(isDark, accent),
          ),
          if (widget.exercise.muscleGroups.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildMuscleGroups(isDark),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // 🆕 Статы по формату
          SliverToBoxAdapter(
            child: _buildStatsCards(
              isDark,
              format,
              lastRecord,
              progressRecords,
              trendLine,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _buildTabs(isDark)),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(isDark),
            _buildProgressTab(isDark, provider, progressRecords, trendLine),
            _buildHistoryTab(isDark, progressRecords),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // HERO CARD (без изменений)
  // =====================================================================

  Widget _buildHeroCard(bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.18),
            accent.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 0.8,
        ),
        boxShadow: _Power.softGlow(accent, strength: 0.12),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(24),
              boxShadow: _Power.softGlow(accent, strength: 0.25),
            ),
            child: Icon(
              _getExerciseIcon(widget.exercise.exerciseType),
              size: 42,
              color: accent,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildHeroChip(
                isDark,
                '${widget.exercise.exerciseType.emoji} ${widget.exercise.exerciseType.displayName}',
                accent,
              ),
              // 🆕 Бейдж формата
              _buildHeroChip(
                isDark,
                '${_format.emoji} ${_format.shortName}',
                _Power.ice,
              ),
              if (widget.exercise.isCustom)
                _buildHeroChip(isDark, 'МОЁ', _Power.volt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(bool isDark, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: accent,
        ),
      ),
    );
  }

  // =====================================================================
  // MUSCLE GROUPS (без изменений)
  // =====================================================================

  Widget _buildMuscleGroups(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.exercise.muscleGroups.map((muscle) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: muscle.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: muscle.color.withOpacity(0.28),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(muscle.emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  muscle.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                    color: muscle.color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 STATS CARDS — dispatch по формату
  // ══════════════════════════════════════════════════════════

  Widget _buildStatsCards(
      bool isDark,
      ExerciseFormat format,
      ProgressRecord? lastRecord,
      List<ProgressRecord> progressRecords,
      TrendLine trendLine,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _statsForFormat(
          isDark,
          format,
          lastRecord,
          progressRecords,
          trendLine,
        ),
      ),
    );
  }

  /// 🆕 Возвращает 3 stat-карточки, зависящие от формата.
  List<Widget> _statsForFormat(
      bool isDark,
      ExerciseFormat format,
      ProgressRecord? lastRecord,
      List<ProgressRecord> progressRecords,
      TrendLine trendLine,
      ) {
    switch (format) {
    // ─────────────────────────────────────────────────
    // СИЛА: 1RM / Последний / Прогноз
    // ─────────────────────────────────────────────────
      case ExerciseFormat.setsReps:
        final best1RM = progressRecords.isNotEmpty
            ? progressRecords
            .map((r) => r.estimated1RM)
            .reduce((a, b) => a > b ? a : b)
            : 0.0;
        return [
          _buildStatCard(
            isDark,
            icon: Icons.trending_up_rounded,
            title: 'ЛУЧШИЙ 1RM',
            value: best1RM > 0 ? best1RM.toStringAsFixed(1) : '—',
            unit: best1RM > 0 ? 'кг' : '',
            color: _Power.green,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            isDark,
            icon: Icons.fitness_center_rounded,
            title: 'ПОСЛЕДНИЙ',
            value: lastRecord != null
                ? '${lastRecord.bestWeight.toStringAsFixed(0)}×${lastRecord.bestReps}'
                : '—',
            unit: lastRecord != null ? 'кг' : '',
            color: _Power.volt,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            isDark,
            icon: Icons.trending_up_rounded,
            title: 'ПРОГНОЗ',
            value: trendLine.slope > 0
                ? '+${(trendLine.slope * 30).toStringAsFixed(1)}'
                : '—',
            unit: trendLine.slope > 0 ? '/мес' : '',
            color: _Power.ice,
          ),
        ];

    // ─────────────────────────────────────────────────
    // КАРДИО: Лучшая дистанция / Лучший темп / Последняя
    // ─────────────────────────────────────────────────
      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        final bestDistance = progressRecords.isNotEmpty
            ? progressRecords
            .map((r) => r.bestDistance ?? 0)
            .reduce((a, b) => a > b ? a : b)
            : 0.0;
        final bestPace = progressRecords
            .where((r) => (r.bestPace ?? 0) > 0)
            .map((r) => r.bestPace!)
            .fold<double?>(null, (a, b) => a == null ? b : (b < a ? b : a));
        return [
          _buildStatCard(
            isDark,
            icon: Icons.directions_run_rounded,
            title: 'ЛУЧШАЯ ДИСТ',
            value: bestDistance > 0
                ? bestDistance.toStringAsFixed(bestDistance >= 10 ? 1 : 2)
                : '—',
            unit: bestDistance > 0 ? 'км' : '',
            color: _Power.ice,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            isDark,
            icon: Icons.speed_rounded,
            title: 'ЛУЧШИЙ ТЕМП',
            value: bestPace != null
                ? FitnessHelpers.formatPace(bestPace)
                : '—',
            unit: bestPace != null ? '/км' : '',
            color: _Power.plasma,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            isDark,
            icon: Icons.flag_rounded,
            title: 'ПОСЛЕДНЯЯ',
            value: lastRecord?.bestDistance != null
                ? lastRecord!.bestDistance!
                .toStringAsFixed(lastRecord.bestDistance! >= 10 ? 1 : 2)
                : '—',
            unit: lastRecord?.bestDistance != null ? 'км' : '',
            color: _Power.volt,
          ),
        ];

    // ─────────────────────────────────────────────────
    // БОКС: Всего раундов / Лучшая тренировка / Время
    // ─────────────────────────────────────────────────
      case ExerciseFormat.rounds:
        final totalRounds = progressRecords.fold<int>(
            0, (s, r) => s + (r.bestRounds ?? 0));
        final maxRoundsInSession = progressRecords.isNotEmpty
            ? progressRecords
            .map((r) => r.bestRounds ?? 0)
            .reduce((a, b) => a > b ? a : b)
            : 0;
        final totalSec = progressRecords.fold<int>(
            0, (s, r) => s + (r.bestDuration ?? 0));
        return [
          _buildStatCard(
            isDark,
            icon: Icons.sports_mma_rounded,
            title: 'ВСЕГО РАУНД',
            value: totalRounds > 0 ? '$totalRounds' : '—',
            unit: totalRounds > 0 ? 'р.' : '',
            color: _Power.plasma,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            isDark,
            icon: Icons.emoji_events_rounded,
            title: 'ЛУЧШАЯ',
            value: maxRoundsInSession > 0 ? '$maxRoundsInSession' : '—',
            unit: maxRoundsInSession > 0 ? 'р.' : '',
            color: _Power.volt,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            isDark,
            icon: Icons.timer_rounded,
            title: 'ВРЕМЯ',
            value: totalSec > 0 ? _fmtSec(totalSec) : '—',
            unit: '',
            color: _Power.lime,
          ),
        ];

    // ─────────────────────────────────────────────────
    // СТАТИКА (планка): Лучшее удержание / Последнее / Сессий
    // ─────────────────────────────────────────────────
      case ExerciseFormat.hold:
        final bestHold = progressRecords.isNotEmpty
            ? progressRecords
            .map((r) => r.bestHoldSeconds ?? 0)
            .reduce((a, b) => a > b ? a : b)
            : 0;
        return [
          _buildStatCard(
            isDark,
            icon: Icons.self_improvement_rounded,
            title: 'ЛУЧШЕЕ',
            value: bestHold > 0 ? _fmtSec(bestHold) : '—',
            unit: '',
            color: _Power.lime,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            isDark,
            icon: Icons.history_rounded,
            title: 'ПОСЛЕДНЕЕ',
            value: lastRecord?.bestHoldSeconds != null
                ? _fmtSec(lastRecord!.bestHoldSeconds!)
                : '—',
            unit: '',
            color: _Power.volt,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            isDark,
            icon: Icons.repeat_rounded,
            title: 'ТРЕНИРОВОК',
            value: '${progressRecords.length}',
            unit: '',
            color: _Power.ice,
          ),
        ];

    // ─────────────────────────────────────────────────
    // ВРЕМЯ / СВОБОДНО: Всего времени / Лучшая / Сессий
    // ─────────────────────────────────────────────────
      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        final totalSec = progressRecords.fold<int>(
            0, (s, r) => s + (r.bestDuration ?? 0));
        final bestInSession = progressRecords.isNotEmpty
            ? progressRecords
            .map((r) => r.bestDuration ?? 0)
            .reduce((a, b) => a > b ? a : b)
            : 0;
        return [
          _buildStatCard(
            isDark,
            icon: Icons.timer_rounded,
            title: 'ВСЕГО',
            value: totalSec > 0 ? _fmtSec(totalSec) : '—',
            unit: '',
            color: _Power.ice,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            isDark,
            icon: Icons.emoji_events_rounded,
            title: 'ЛУЧШАЯ',
            value: bestInSession > 0 ? _fmtSec(bestInSession) : '—',
            unit: '',
            color: _Power.volt,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            isDark,
            icon: Icons.repeat_rounded,
            title: 'ТРЕНИРОВОК',
            value: '${progressRecords.length}',
            unit: '',
            color: _Power.lime,
          ),
        ];
    }
  }

  Widget _buildStatCard(
      bool isDark, {
        required IconData icon,
        required String title,
        required String value,
        required String unit,
        required Color color,
      }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _Power.card(isDark),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.18),
            width: 0.8,
          ),
          boxShadow: _Power.softGlow(color, strength: 0.06),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1,
                      color: _Power.textPrimary(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 1),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _Power.textTertiary(isDark),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: _Power.textTertiary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // TABS (без изменений)
  // =====================================================================

  Widget _buildTabs(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
            boxShadow: _Power.softGlow(_Power.volt, strength: 0.3),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          tabs: const [
            Tab(text: 'ИНФО'),
            Tab(text: 'ПРОГРЕСС'),
            Tab(text: 'ИСТОРИЯ'),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // INFO TAB (без изменений)
  // =====================================================================

  Widget _buildInfoTab(bool isDark) {
    final hasDescription = widget.exercise.description.isNotEmpty;
    final hasTips = widget.exercise.techniqueTips != null &&
        widget.exercise.techniqueTips!.isNotEmpty;
    final hasMistakes = widget.exercise.commonMistakes != null &&
        widget.exercise.commonMistakes!.isNotEmpty;
    final hasVideo = widget.exercise.videoUrl != null &&
        widget.exercise.videoUrl!.isNotEmpty;

    if (!hasDescription && !hasTips && !hasMistakes && !hasVideo) {
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
                  Icons.info_outline_rounded,
                  size: 40,
                  color: _Power.volt,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'НЕТ ОПИСАНИЯ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  color: _Power.textTertiary(isDark),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Описание отсутствует',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: _Power.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Добавьте описание через редактирование',
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDescription)
            _buildInfoSection(
              isDark,
              icon: Icons.description_rounded,
              title: 'ОПИСАНИЕ',
              content: widget.exercise.description,
              color: _Power.volt,
            ),
          if (hasTips) ...[
            const SizedBox(height: 12),
            _buildInfoSection(
              isDark,
              icon: Icons.lightbulb_rounded,
              title: 'СОВЕТЫ ПО ТЕХНИКЕ',
              content: widget.exercise.techniqueTips!,
              color: _Power.plasma,
            ),
          ],
          if (hasMistakes) ...[
            const SizedBox(height: 12),
            _buildInfoSection(
              isDark,
              icon: Icons.warning_rounded,
              title: 'ЧАСТЫЕ ОШИБКИ',
              content: widget.exercise.commonMistakes!,
              color: _Power.red,
            ),
          ],
          if (hasVideo) ...[
            const SizedBox(height: 12),
            _buildVideoLink(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      bool isDark, {
        required IconData icon,
        required String title,
        required String content,
        Color? color,
      }) {
    final accent = color ?? _Power.volt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
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
                child: Icon(icon, color: accent, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: _Power.textPrimary(isDark).withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLink(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        // TODO: открыть видео в браузере
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _Power.card(isDark),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _Power.separator(isDark), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _Power.red.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _Power.softGlow(_Power.red, strength: 0.2),
              ),
              child: const Icon(
                Icons.play_circle_rounded,
                color: _Power.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ВИДЕО-ИНСТРУКЦИЯ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: _Power.textPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Открыть в браузере',
                    style: TextStyle(
                      fontSize: 12,
                      color: _Power.textSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: _Power.textTertiary(isDark),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 PROGRESS TAB — график по правильной метрике
  // ══════════════════════════════════════════════════════════

  Widget _buildProgressTab(
      bool isDark,
      FitnessProvider provider,
      List<ProgressRecord> records,
      TrendLine trendLine,
      ) {
    if (records.isEmpty) {
      return _buildEmptyChart(isDark);
    }

    final format = _format;

    // 🆕 Заголовок графика и способ извлечения значения
    final String chartTitle;
    final String unit;
    final Color accent;
    final bool showPrediction;
    final double Function(ProgressRecord) extractor;

    switch (format) {
      case ExerciseFormat.setsReps:
        chartTitle = 'ДИНАМИКА 1RM';
        unit = 'кг';
        accent = _Power.volt;
        showPrediction = true;
        extractor = (r) => r.estimated1RM;
        break;
      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        chartTitle = 'ДИСТАНЦИЯ';
        unit = 'км';
        accent = _Power.ice;
        showPrediction = true;
        extractor = (r) => r.bestDistance ?? 0;
        break;
      case ExerciseFormat.rounds:
        chartTitle = 'РАУНДЫ';
        unit = 'раунд';
        accent = _Power.plasma;
        showPrediction = true;
        extractor = (r) => (r.bestRounds ?? 0).toDouble();
        break;
      case ExerciseFormat.hold:
        chartTitle = 'УДЕРЖАНИЕ';
        unit = 'сек';
        accent = _Power.lime;
        showPrediction = true;
        extractor = (r) => (r.bestHoldSeconds ?? 0).toDouble();
        break;
      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        chartTitle = 'ВРЕМЯ';
        unit = 'сек';
        accent = _Power.ice;
        showPrediction = false;
        extractor = (r) => (r.bestDuration ?? 0).toDouble();
        break;
    }

    // Собираем точки
    final spots = <FlSpot>[];
    final firstDate = records.first.date;
    for (int i = 0; i < records.length; i++) {
      final x = records[i].date.difference(firstDate).inDays.toDouble();
      final y = extractor(records[i]);
      spots.add(FlSpot(x, y));
    }

    final predictionSpots = <FlSpot>[];
    if (showPrediction && trendLine.slope > 0 && spots.isNotEmpty) {
      final lastX = spots.last.x;
      for (int i = 1; i <= 30; i++) {
        predictionSpots.add(FlSpot(
          lastX + i,
          trendLine.predict((lastX + i).toInt()),
        ));
      }
    }

    // Проверка «все нули»
    final allZero = spots.every((s) => s.y == 0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (allZero)
            Container(
              height: 180,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _Power.card(isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _Power.separator(isDark), width: 0.5),
              ),
              child: Center(
                child: Text(
                  'Нет данных по метрике «${chartTitle.toLowerCase()}»',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _Power.textSecondary(isDark),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 280,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
              decoration: BoxDecoration(
                color: _Power.card(isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _Power.separator(isDark), width: 0.5),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: _Power.separator(isDark),
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) => Text(
                          _shortLabelFor(value, unit),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _Power.textTertiary(isDark),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
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
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: accent,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: accent,
                              strokeWidth: 2,
                              strokeColor: _Power.bg(isDark),
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent.withOpacity(0.25),
                            accent.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    if (predictionSpots.isNotEmpty)
                      LineChartBarData(
                        spots: predictionSpots,
                        isCurved: true,
                        color: accent.withOpacity(0.35),
                        barWidth: 2,
                        dashArray: [5, 5],
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => _Power.card2(isDark),
                      tooltipRoundedRadius: 12,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            _formatChartValue(spot.y, unit),
                            TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildLegendDot(isDark, accent, chartTitle),
                const SizedBox(width: 16),
                if (predictionSpots.isNotEmpty)
                  _buildLegendDot(
                      isDark, accent.withOpacity(0.35), 'Прогноз 30 дней'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatChartValue(double v, String unit) {
    if (unit == 'сек') {
      if (v >= 60) return '${(v / 60).toStringAsFixed(1)} мин';
      return '${v.toStringAsFixed(0)} с';
    }
    if (unit == 'км') return '${v.toStringAsFixed(2)} км';
    if (unit == 'кг') return '${v.toStringAsFixed(1)} кг';
    if (unit == 'раунд') return '${v.toStringAsFixed(0)} р.';
    return '${v.toStringAsFixed(0)} $unit';
  }

  String _shortLabelFor(double value, String unit) {
    if (unit == 'сек') {
      if (value >= 3600) return '${(value / 3600).toStringAsFixed(1)}ч';
      if (value >= 60) return '${(value / 60).toStringAsFixed(0)}м';
      return '${value.toStringAsFixed(0)}';
    }
    if (unit == 'кг' && value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildLegendDot(bool isDark, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _Power.textSecondary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _Power.volt.withOpacity(0.10),
              shape: BoxShape.circle,
              boxShadow: _Power.softGlow(_Power.volt, strength: 0.15),
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              size: 36,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'НЕТ ДАННЫХ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Прогресс появится здесь',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: _Power.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Начните тренироваться!',
            textAlign: TextAlign.center,
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
  // 🆕 HISTORY TAB — запись по формату
  // ══════════════════════════════════════════════════════════

  Widget _buildHistoryTab(bool isDark, List<ProgressRecord> records) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'История появится после тренировок',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _Power.textSecondary(isDark),
            ),
          ),
        ),
      );
    }

    final sortedRecords = List<ProgressRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      itemCount: sortedRecords.length,
      itemBuilder: (context, index) {
        final record = sortedRecords[index];
        return _buildHistoryRow(isDark, record, index);
      },
    );
  }

  Widget _buildHistoryRow(
      bool isDark,
      ProgressRecord record,
      int index,
      ) {
    final accent = _formatRecordAccent(record);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              boxShadow:
              _Power.softGlow(accent.color, strength: 0.15),
            ),
            alignment: Alignment.center,
            child: Icon(
              _getHistoryIcon(accent.label),
              color: accent.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.date.day.toString().padLeft(2, '0')}.${record.date.month.toString().padLeft(2, '0')}.${record.date.year}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatRecordSubtitle(record),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _Power.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatRecordSummary(record),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: _Power.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${accent.label} ${accent.value}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accent.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getHistoryIcon(String label) {
    switch (label) {
      case '1RM':
        return Icons.trending_up_rounded;
      case 'КМ':
        return Icons.directions_run_rounded;
      case 'РАУНД':
        return Icons.sports_mma_rounded;
      case 'УДЕРЖ':
        return Icons.self_improvement_rounded;
      case 'ВРЕМЯ':
        return Icons.timer_rounded;
      default:
        return Icons.check_rounded;
    }
  }

  // =====================================================================
  // EDIT DIALOG (без изменений)
  // =====================================================================

  void _showEditDialog(
      BuildContext context,
      bool isDark,
      FitnessProvider provider,
      ) {
    final nameController = TextEditingController(text: widget.exercise.name);
    final descController =
    TextEditingController(text: widget.exercise.description);
    final tipsController =
    TextEditingController(text: widget.exercise.techniqueTips ?? '');
    final mistakesController =
    TextEditingController(text: widget.exercise.commonMistakes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: _Power.card(isDark),
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _Power.textTertiary(isDark),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'РЕДАКТИРОВАТЬ',
                style: TextStyle(
                  color: _Power.volt,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Упражнение',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: _Power.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: nameController,
                label: 'НАЗВАНИЕ',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: descController,
                label: 'ОПИСАНИЕ',
                isDark: isDark,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: tipsController,
                label: 'СОВЕТЫ',
                isDark: isDark,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: mistakesController,
                label: 'ОШИБКИ',
                isDark: isDark,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _Power.textSecondary(isDark),
                          side: BorderSide(color: _Power.separator(isDark)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Отмена',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          final updated = widget.exercise.copyWith(
                            name: nameController.text.trim(),
                            description: descController.text.trim(),
                            techniqueTips:
                            tipsController.text.trim().isNotEmpty
                                ? tipsController.text.trim()
                                : null,
                            commonMistakes:
                            mistakesController.text.trim().isNotEmpty
                                ? mistakesController.text.trim()
                                : null,
                          );
                          await provider.updateExercise(updated);
                          if (ctx.mounted) Navigator.pop(ctx);
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
                        child: const Text(
                          'СОХРАНИТЬ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(ctx);
                    _confirmDelete(context, isDark, provider);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _Power.red,
                    backgroundColor: _Power.red.withOpacity(0.10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'УДАЛИТЬ УПРАЖНЕНИЕ',
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
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: _Power.textTertiary(isDark),
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _Power.textPrimary(isDark),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _Power.card2(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // DELETE CONFIRM (без изменений)
  // =====================================================================

  void _confirmDelete(
      BuildContext context,
      bool isDark,
      FitnessProvider provider,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? _Power.darkCard2 : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  children: [
                    Text(
                      'Удалить упражнение?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '«${widget.exercise.name}» будет удалено безвозвратно',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _Power.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 0.5, color: _Power.separator(isDark)),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: const Text(
                          'Отмена',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: _Power.volt,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 50,
                    color: _Power.separator(isDark),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await provider.deleteExercise(widget.exercise.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: const Text(
                          'Удалить',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _Power.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  IconData _getExerciseIcon(ExerciseType type) {
    switch (type) {
      case ExerciseType.strength:
        return Icons.fitness_center_rounded;
      case ExerciseType.cardio:
        return Icons.directions_run_rounded;
      case ExerciseType.bodyweight:
        return Icons.accessibility_new_rounded;
      case ExerciseType.boxing:
        return Icons.sports_mma_rounded;
      case ExerciseType.yoga:
        return Icons.self_improvement_rounded;
      case ExerciseType.other:
        return Icons.more_horiz_rounded;
    }
  }
}