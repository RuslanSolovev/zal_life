// features/fitness/ui/screens/exercise_detail_screen.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:zal_life/features/fitness/data/exercise_image_presets.dart';

import '../../../models/enums.dart';
import '../../../models/fitness_models.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';
import '../widgets/image_picker_field.dart';

// ═══════════════════════════════════════════════════════════════════
//  Soft Pastel Light — Design System
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const peach     = Color(0xFFFFB5A7);
  static const pink      = Color(0xFFFFAFC8);
  static const mint      = Color(0xFFA8DADC);
  static const lavender  = Color(0xFFCDB4DB);
  static const yellow    = Color(0xFFFFD6A5);
  static const sky       = Color(0xFFA8D8EA);
  static const sage      = Color(0xFFB5CBB7);

  static const peachSoft    = Color(0xFFFFE9E1);
  static const pinkSoft     = Color(0xFFFFE5EF);
  static const mintSoft     = Color(0xFFE3F3F4);
  static const lavenderSoft = Color(0xFFF1E8F5);
  static const yellowSoft   = Color(0xFFFFF2E2);
  static const skySoft      = Color(0xFFE3F1F7);
  static const sageSoft     = Color(0xFFE8F1E6);

  static const peachDeep    = Color(0xFFE57154);
  static const pinkDeep     = Color(0xFFD95C84);
  static const mintDeep     = Color(0xFF398B95);
  static const lavenderDeep = Color(0xFF8A5DA5);
  static const yellowDeep   = Color(0xFFD39838);
  static const skyDeep      = Color(0xFF3E7A9C);
  static const sageDeep     = Color(0xFF5C7E5E);

  static const bg       = Color(0xFFFAF7F2);
  static const surface  = Color(0xFFFFFFFF);
  static const elevated = Color(0xFFF3EEE6);

  static const text      = Color(0xFF2B2823);
  static const textMuted = Color(0xFF8A8278);
  static const textSoft  = Color(0xFFBFB7AB);

  static const divider = Color(0xFFEAE4DA);
}

class _T {
  static const title1 = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w800,
    letterSpacing: -0.6, height: 1.15,
  );
  static const title2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w800,
    letterSpacing: -0.5, height: 1.2,
  );
  static const title3 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    letterSpacing: -0.4, height: 1.2,
  );
  static const headline = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700,
    letterSpacing: -0.2, height: 1.3,
  );
  static const caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600,
    letterSpacing: 0.05, height: 1.3,
  );
  static const caption2 = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700,
    letterSpacing: 0.1, height: 1.3,
  );
  static const overline = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w800,
    letterSpacing: 1.4, height: 1.1,
  );
}

// ═══════════════════════════════════════════════════════════════════

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

  ExerciseFormat get _format => widget.exercise.resolveFormat();

  ({Color deep, Color soft}) _formatColors(ExerciseFormat format) {
    switch (format) {
      case ExerciseFormat.setsReps:
        return (deep: _P.peachDeep, soft: _P.peachSoft);
      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        return (deep: _P.skyDeep, soft: _P.skySoft);
      case ExerciseFormat.rounds:
        return (deep: _P.yellowDeep, soft: _P.yellowSoft);
      case ExerciseFormat.hold:
        return (deep: _P.sageDeep, soft: _P.sageSoft);
      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        return (deep: _P.mintDeep, soft: _P.mintSoft);
    }
  }

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

  String _fmtSec(int sec) {
    if (sec <= 0) return '0с';
    if (sec < 60) return '${sec}с';
    final m = sec ~/ 60;
    final s = sec % 60;
    return s > 0 ? '${m}м ${s}с' : '${m}м';
  }

  String _formatRecordSummary(ProgressRecord r) {
    switch (_format) {
      case ExerciseFormat.setsReps:
        return '${r.bestWeight.toStringAsFixed(0)} кг × ${r.bestReps}';
      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        final parts = <String>[];
        if ((r.bestDistance ?? 0) > 0) {
          parts.add('${r.bestDistance!.toStringAsFixed(r.bestDistance! >= 10 ? 1 : 2)} км');
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

  String _formatRecordSubtitle(ProgressRecord r) {
    switch (_format) {
      case ExerciseFormat.setsReps:
        return '${r.totalSets} подх. · ${r.totalVolume.toStringAsFixed(0)} кг';
      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        if ((r.bestPace ?? 0) > 0) {
          return '${r.totalSets} подх. · темп ${FitnessHelpers.formatPace(r.bestPace!)}/км';
        }
        return '${r.totalSets} подх.';
      case ExerciseFormat.rounds:
      case ExerciseFormat.hold:
      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        return '${r.totalSets} подх.';
    }
  }

  ({String value, String label}) _formatRecordAccent(ProgressRecord r) {
    switch (_format) {
      case ExerciseFormat.setsReps:
        return (value: r.estimated1RM.toStringAsFixed(0), label: '1RM');
      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        return (value: (r.bestDistance ?? 0).toStringAsFixed(2), label: 'км');
      case ExerciseFormat.rounds:
        return (value: '${r.bestRounds ?? 0}', label: 'раунд');
      case ExerciseFormat.hold:
        return (value: _fmtSec(r.bestHoldSeconds ?? 0), label: 'удерж');
      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        return (value: _fmtSec(r.bestDuration ?? 0), label: 'время');
    }
  }

  // ═════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final progressRecords = provider.getExerciseProgress(widget.exercise.id);
    final lastRecord = provider.getLastProgress(widget.exercise.id);
    final format = _format;
    final fmtColors = _formatColors(format);

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
        : _P.peachDeep;

    return Scaffold(
      backgroundColor: _P.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: _P.bg.withOpacity(0.94),
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _P.divider, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _P.peachDeep.withOpacity(0.06),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.chevron_left_rounded, color: _P.text, size: 22),
                ),
              ),
            ),
            title: Text(
              widget.exercise.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _T.headline.copyWith(fontSize: 15, color: _P.text, letterSpacing: -0.2),
            ),
            centerTitle: true,
            actions: [
              if (widget.exercise.isCustom)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showEditDialog(context, provider);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _P.peachSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: _P.peachDeep.withOpacity(0.20), width: 0.7),
                      ),
                      child: const Icon(Icons.edit_rounded, color: _P.peachDeep, size: 17),
                    ),
                  ),
                ),
            ],
          ),

          // ═══ HERO — крупное изображение с оверлеем ═══
          SliverToBoxAdapter(
            child: _buildHeroSection(accent, fmtColors),
          ),

          if (widget.exercise.muscleGroups.isNotEmpty)
            SliverToBoxAdapter(child: _buildMuscleGroups()),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: _buildStatsCards(format, fmtColors, lastRecord, progressRecords, trendLine),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
          SliverToBoxAdapter(child: _buildTabs()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildProgressTab(provider, progressRecords, trendLine, fmtColors),
            _buildHistoryTab(progressRecords, fmtColors),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HERO SECTION — крупная обложка с оверлеем
  // ═════════════════════════════════════════════════════════
  Widget _buildHeroSection(Color accent, ({Color deep, Color soft}) fmtColors) {
    final hasImage = widget.exercise.imageUrl != null &&
        widget.exercise.imageUrl!.isNotEmpty;
    final isCustom = widget.exercise.isCustom;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.22),
            blurRadius: 40,
            spreadRadius: -12,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Изображение / fallback
          if (hasImage)
            _buildHeroImage(accent)
          else
            _buildHeroFallback(accent),

          // 2. Градиент для читаемости белого текста снизу
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.20),
                    Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.88),
                  ],
                  stops: const [0.0, 0.32, 0.58, 0.82, 1.0],
                ),
              ),
            ),
          ),

          // 3. Контент
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Верхние chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _glassChip(
                      '${widget.exercise.exerciseType.emoji} ${widget.exercise.exerciseType.displayName}',
                    ),
                    _glassChip(
                      '${_format.emoji} ${_format.shortName}',
                    ),
                    if (isCustom) _glassChip('✦ МОЁ'),
                  ],
                ),
                const Spacer(),
                // Overline
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCustom ? 'МОЁ УПРАЖНЕНИЕ' : 'УПРАЖНЕНИЕ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Название
                Text(
                  widget.exercise.name,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    height: 1.08,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero image (assets / http / file) ──
  Widget _buildHeroImage(Color accent) {
    final url = widget.exercise.imageUrl!;
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildHeroFallback(accent),
      );
    }
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildHeroFallback(accent),
        errorWidget: (_, __, ___) => _buildHeroFallback(accent),
      );
    }
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildHeroFallback(accent),
    );
  }

  // ── Hero fallback — насыщенный accent-градиент, крупная иконка ──
  Widget _buildHeroFallback(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent,
            Color.lerp(accent, Colors.black, 0.25) ?? accent,
            Color.lerp(accent, Colors.black, 0.45) ?? accent,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Большая полупрозрачная иконка справа
          Positioned(
            right: -50,
            bottom: -30,
            child: Icon(
              _getExerciseIcon(widget.exercise.exerciseType),
              size: 280,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          // Центральный эмодзи
          Center(
            child: Text(
              widget.exercise.exerciseType.emoji,
              style: TextStyle(
                fontSize: 110,
                color: Colors.white.withOpacity(0.14),
                height: 1,
              ),
            ),
          ),
          // Мягкий блик сверху слева
          Positioned(
            left: -80,
            top: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.14),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Glass chip ──
  Widget _glassChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withOpacity(0.32),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
          color: Colors.white,
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  MUSCLE GROUPS
  // ═════════════════════════════════════════════════════════
  Widget _buildMuscleGroups() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.exercise.muscleGroups.map((muscle) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: muscle.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: muscle.color.withOpacity(0.22),
                width: 0.7,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(muscle.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text(
                  muscle.displayName,
                  style: TextStyle(
                    fontSize: 11.5,
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

  // ═════════════════════════════════════════════════════════
  //  STATS CARDS
  // ═════════════════════════════════════════════════════════
  Widget _buildStatsCards(
      ExerciseFormat format,
      ({Color deep, Color soft}) fmtColors,
      ProgressRecord? lastRecord,
      List<ProgressRecord> progressRecords,
      TrendLine trendLine,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _statsForFormat(format, fmtColors, lastRecord, progressRecords, trendLine),
      ),
    );
  }

  List<Widget> _statsForFormat(
      ExerciseFormat format,
      ({Color deep, Color soft}) fmtColors,
      ProgressRecord? lastRecord,
      List<ProgressRecord> progressRecords,
      TrendLine trendLine,
      ) {
    switch (format) {
      case ExerciseFormat.setsReps:
        final best1RM = progressRecords.isNotEmpty
            ? progressRecords.map((r) => r.estimated1RM).reduce((a, b) => a > b ? a : b)
            : 0.0;
        return [
          _statCard(
            icon: Icons.trending_up_rounded,
            title: 'ЛУЧШИЙ 1RM',
            value: best1RM > 0 ? best1RM.toStringAsFixed(1) : '—',
            unit: best1RM > 0 ? 'кг' : '',
            accent: _P.sageDeep,
            soft: _P.sageSoft,
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.fitness_center_rounded,
            title: 'ПОСЛЕДНИЙ',
            value: lastRecord != null
                ? '${lastRecord.bestWeight.toStringAsFixed(0)}×${lastRecord.bestReps}'
                : '—',
            unit: lastRecord != null ? 'кг' : '',
            accent: _P.peachDeep,
            soft: _P.peachSoft,
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.trending_up_rounded,
            title: 'ПРОГНОЗ',
            value: trendLine.slope > 0 ? '+${(trendLine.slope * 30).toStringAsFixed(1)}' : '—',
            unit: trendLine.slope > 0 ? '/мес' : '',
            accent: _P.skyDeep,
            soft: _P.skySoft,
          ),
        ];

      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        final bestDistance = progressRecords.isNotEmpty
            ? progressRecords.map((r) => r.bestDistance ?? 0).reduce((a, b) => a > b ? a : b)
            : 0.0;
        final bestPace = progressRecords
            .where((r) => (r.bestPace ?? 0) > 0)
            .map((r) => r.bestPace!)
            .fold<double?>(null, (a, b) => a == null ? b : (b < a ? b : a));
        return [
          _statCard(
            icon: Icons.directions_run_rounded,
            title: 'ЛУЧШАЯ ДИСТ',
            value: bestDistance > 0 ? bestDistance.toStringAsFixed(bestDistance >= 10 ? 1 : 2) : '—',
            unit: bestDistance > 0 ? 'км' : '',
            accent: _P.skyDeep,
            soft: _P.skySoft,
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.speed_rounded,
            title: 'ЛУЧШИЙ ТЕМП',
            value: bestPace != null ? FitnessHelpers.formatPace(bestPace) : '—',
            unit: bestPace != null ? '/км' : '',
            accent: _P.yellowDeep,
            soft: _P.yellowSoft,
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.flag_rounded,
            title: 'ПОСЛЕДНЯЯ',
            value: lastRecord?.bestDistance != null
                ? lastRecord!.bestDistance!.toStringAsFixed(lastRecord.bestDistance! >= 10 ? 1 : 2)
                : '—',
            unit: lastRecord?.bestDistance != null ? 'км' : '',
            accent: _P.peachDeep,
            soft: _P.peachSoft,
          ),
        ];

      case ExerciseFormat.rounds:
        final totalRounds = progressRecords.fold<int>(0, (s, r) => s + (r.bestRounds ?? 0));
        final maxRoundsInSession = progressRecords.isNotEmpty
            ? progressRecords.map((r) => r.bestRounds ?? 0).reduce((a, b) => a > b ? a : b)
            : 0;
        final totalSec = progressRecords.fold<int>(0, (s, r) => s + (r.bestDuration ?? 0));
        return [
          _statCard(
            icon: Icons.sports_mma_rounded,
            title: 'ВСЕГО РАУНД',
            value: totalRounds > 0 ? '$totalRounds' : '—',
            unit: totalRounds > 0 ? 'р.' : '',
            accent: _P.yellowDeep,
            soft: _P.yellowSoft,
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.emoji_events_rounded,
            title: 'ЛУЧШАЯ',
            value: maxRoundsInSession > 0 ? '$maxRoundsInSession' : '—',
            unit: maxRoundsInSession > 0 ? 'р.' : '',
            accent: _P.peachDeep,
            soft: _P.peachSoft,
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.timer_rounded,
            title: 'ВРЕМЯ',
            value: totalSec > 0 ? _fmtSec(totalSec) : '—',
            unit: '',
            accent: _P.sageDeep,
            soft: _P.sageSoft,
          ),
        ];

      case ExerciseFormat.hold:
        final bestHold = progressRecords.isNotEmpty
            ? progressRecords.map((r) => r.bestHoldSeconds ?? 0).reduce((a, b) => a > b ? a : b)
            : 0;
        return [
          _statCard(
            icon: Icons.self_improvement_rounded,
            title: 'ЛУЧШЕЕ',
            value: bestHold > 0 ? _fmtSec(bestHold) : '—',
            unit: '',
            accent: _P.sageDeep,
            soft: _P.sageSoft,
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.history_rounded,
            title: 'ПОСЛЕДНЕЕ',
            value: lastRecord?.bestHoldSeconds != null ? _fmtSec(lastRecord!.bestHoldSeconds!) : '—',
            unit: '',
            accent: _P.peachDeep,
            soft: _P.peachSoft,
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.repeat_rounded,
            title: 'ТРЕНИРОВОК',
            value: '${progressRecords.length}',
            unit: '',
            accent: _P.skyDeep,
            soft: _P.skySoft,
          ),
        ];

      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        final totalSec = progressRecords.fold<int>(0, (s, r) => s + (r.bestDuration ?? 0));
        final bestInSession = progressRecords.isNotEmpty
            ? progressRecords.map((r) => r.bestDuration ?? 0).reduce((a, b) => a > b ? a : b)
            : 0;
        return [
          _statCard(
            icon: Icons.timer_rounded,
            title: 'ВСЕГО',
            value: totalSec > 0 ? _fmtSec(totalSec) : '—',
            unit: '',
            accent: _P.mintDeep,
            soft: _P.mintSoft,
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.emoji_events_rounded,
            title: 'ЛУЧШАЯ',
            value: bestInSession > 0 ? _fmtSec(bestInSession) : '—',
            unit: '',
            accent: _P.peachDeep,
            soft: _P.peachSoft,
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.repeat_rounded,
            title: 'ТРЕНИРОВОК',
            value: '${progressRecords.length}',
            unit: '',
            accent: _P.sageDeep,
            soft: _P.sageSoft,
          ),
        ];
    }
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color accent,
    required Color soft,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.14), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: -3,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                      height: 1,
                      color: _P.text,
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
                      style: _T.caption2.copyWith(fontSize: 9, color: _P.textMuted),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _T.caption2.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
                color: _P.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  TABS
  // ═════════════════════════════════════════════════════════
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _P.elevated,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: _P.textMuted,
          indicator: BoxDecoration(
            color: _P.peachDeep,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: _P.peachDeep.withOpacity(0.18),
                blurRadius: 8,
                spreadRadius: -2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          tabs: const [
            Tab(text: 'ИНФО'),
            Tab(text: 'ПРОГРЕСС'),
            Tab(text: 'ИСТОРИЯ'),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  INFO TAB
  // ═════════════════════════════════════════════════════════
  Widget _buildInfoTab() {
    final hasDescription = widget.exercise.description.isNotEmpty;
    final hasTips = widget.exercise.techniqueTips != null && widget.exercise.techniqueTips!.isNotEmpty;
    final hasMistakes = widget.exercise.commonMistakes != null && widget.exercise.commonMistakes!.isNotEmpty;
    final hasVideo = widget.exercise.videoUrl != null && widget.exercise.videoUrl!.isNotEmpty;

    if (!hasDescription && !hasTips && !hasMistakes && !hasVideo) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: _P.peachSoft, shape: BoxShape.circle),
                child: const Icon(Icons.info_outline_rounded, size: 36, color: _P.peachDeep),
              ),
              const SizedBox(height: 18),
              Text(
                'Нет описания',
                style: _T.title3.copyWith(fontSize: 17, color: _P.text, letterSpacing: -0.4),
              ),
              const SizedBox(height: 6),
              Text(
                'Добавь описание через редактирование',
                textAlign: TextAlign.center,
                style: _T.caption.copyWith(fontSize: 12, color: _P.textMuted),
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
            _infoSection(
              icon: Icons.description_rounded,
              title: 'ОПИСАНИЕ',
              content: widget.exercise.description,
              accent: _P.peachDeep,
            ),
          if (hasTips) ...[
            const SizedBox(height: 12),
            _infoSection(
              icon: Icons.lightbulb_rounded,
              title: 'СОВЕТЫ ПО ТЕХНИКЕ',
              content: widget.exercise.techniqueTips!,
              accent: _P.yellowDeep,
            ),
          ],
          if (hasMistakes) ...[
            const SizedBox(height: 12),
            _infoSection(
              icon: Icons.warning_rounded,
              title: 'ЧАСТЫЕ ОШИБКИ',
              content: widget.exercise.commonMistakes!,
              accent: _P.pinkDeep,
            ),
          ],
          if (hasVideo) ...[
            const SizedBox(height: 12),
            _buildVideoLink(),
          ],
        ],
      ),
    );
  }

  Widget _infoSection({
    required IconData icon,
    required String title,
    required String content,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _P.peachDeep.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: -3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 15),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: _T.caption2.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: _T.headline.copyWith(
              fontSize: 13.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: _P.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLink() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        // TODO: open video
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.divider, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _P.pinkSoft, borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.play_circle_rounded, color: _P.pinkDeep, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ВИДЕО-ИНСТРУКЦИЯ',
                    style: _T.caption2.copyWith(fontSize: 10, color: _P.text, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Открыть в браузере',
                    style: _T.caption2.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: _P.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: _P.textMuted, size: 17),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  PROGRESS TAB
  // ═════════════════════════════════════════════════════════
  Widget _buildProgressTab(
      FitnessProvider provider,
      List<ProgressRecord> records,
      TrendLine trendLine,
      ({Color deep, Color soft}) fmtColors,
      ) {
    if (records.isEmpty) {
      return _buildEmptyChart();
    }

    final format = _format;
    final String chartTitle;
    final String unit;
    final bool showPrediction;
    final double Function(ProgressRecord) extractor;

    switch (format) {
      case ExerciseFormat.setsReps:
        chartTitle = 'ДИНАМИКА 1RM';
        unit = 'кг';
        showPrediction = true;
        extractor = (r) => r.estimated1RM;
        break;
      case ExerciseFormat.continuous:
      case ExerciseFormat.intervals:
        chartTitle = 'ДИСТАНЦИЯ';
        unit = 'км';
        showPrediction = true;
        extractor = (r) => r.bestDistance ?? 0;
        break;
      case ExerciseFormat.rounds:
        chartTitle = 'РАУНДЫ';
        unit = 'раунд';
        showPrediction = true;
        extractor = (r) => (r.bestRounds ?? 0).toDouble();
        break;
      case ExerciseFormat.hold:
        chartTitle = 'УДЕРЖАНИЕ';
        unit = 'сек';
        showPrediction = true;
        extractor = (r) => (r.bestHoldSeconds ?? 0).toDouble();
        break;
      case ExerciseFormat.timedSets:
      case ExerciseFormat.freeform:
        chartTitle = 'ВРЕМЯ';
        unit = 'сек';
        showPrediction = false;
        extractor = (r) => (r.bestDuration ?? 0).toDouble();
        break;
    }

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
        predictionSpots.add(FlSpot(lastX + i, trendLine.predict((lastX + i).toInt())));
      }
    }

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
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _P.divider, width: 0.8),
              ),
              child: Center(
                child: Text(
                  'Нет данных по метрике «${chartTitle.toLowerCase()}»',
                  textAlign: TextAlign.center,
                  style: _T.caption.copyWith(fontSize: 13, color: _P.textMuted),
                ),
              ),
            )
          else
            Container(
              height: 280,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _P.divider, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: fmtColors.deep.withOpacity(0.05),
                    blurRadius: 14,
                    spreadRadius: -4,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) => FlLine(color: _P.divider, strokeWidth: 0.6),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) => Text(
                          _shortLabelFor(value, unit),
                          style: _T.caption2.copyWith(fontSize: 10, color: _P.textMuted),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (value, meta) {
                          final date = firstDate.add(Duration(days: value.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${date.day}.${date.month}',
                              style: _T.caption2.copyWith(fontSize: 9, color: _P.textMuted),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: fmtColors.deep,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: fmtColors.deep,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            fmtColors.deep.withOpacity(0.20),
                            fmtColors.deep.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    if (predictionSpots.isNotEmpty)
                      LineChartBarData(
                        spots: predictionSpots,
                        isCurved: true,
                        color: fmtColors.deep.withOpacity(0.35),
                        barWidth: 2,
                        dashArray: [5, 5],
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => _P.elevated,
                      tooltipRoundedRadius: 10,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            _formatChartValue(spot.y, unit),
                            TextStyle(
                              color: fmtColors.deep,
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
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _legendDot(fmtColors.deep, chartTitle),
                const SizedBox(width: 16),
                if (predictionSpots.isNotEmpty)
                  _legendDot(fmtColors.deep.withOpacity(0.35), 'Прогноз 30 дней'),
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
      return value.toStringAsFixed(0);
    }
    if (unit == 'кг' && value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: _T.caption2.copyWith(fontSize: 11, color: _P.textMuted),
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: _P.peachSoft, shape: BoxShape.circle),
            child: const Icon(Icons.show_chart_rounded, size: 34, color: _P.peachDeep),
          ),
          const SizedBox(height: 18),
          Text(
            'Нет данных',
            style: _T.title3.copyWith(fontSize: 17, color: _P.text, letterSpacing: -0.4),
          ),
          const SizedBox(height: 6),
          Text(
            'Прогресс появится после тренировок',
            textAlign: TextAlign.center,
            style: _T.caption.copyWith(fontSize: 12, color: _P.textMuted),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HISTORY TAB
  // ═════════════════════════════════════════════════════════
  Widget _buildHistoryTab(
      List<ProgressRecord> records,
      ({Color deep, Color soft}) fmtColors,
      ) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'История появится после тренировок',
            textAlign: TextAlign.center,
            style: _T.caption.copyWith(fontSize: 13, color: _P.textMuted),
          ),
        ),
      );
    }

    final sortedRecords = List<ProgressRecord>.from(records)..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      itemCount: sortedRecords.length,
      itemBuilder: (context, index) {
        final record = sortedRecords[index];
        return _historyRow(record, fmtColors);
      },
    );
  }

  Widget _historyRow(
      ProgressRecord record,
      ({Color deep, Color soft}) fmtColors,
      ) {
    final accent = _formatRecordAccent(record);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.divider, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: fmtColors.soft,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(_historyIcon(accent.label), color: fmtColors.deep, size: 17),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.date.day.toString().padLeft(2, '0')}.${record.date.month.toString().padLeft(2, '0')}.${record.date.year}',
                  style: _T.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: _P.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRecordSubtitle(record),
                  style: _T.caption2.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _P.textMuted,
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
                style: _T.caption.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: _P.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${accent.label} ${accent.value}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: fmtColors.deep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _historyIcon(String label) {
    switch (label) {
      case '1RM':
        return Icons.trending_up_rounded;
      case 'км':
        return Icons.directions_run_rounded;
      case 'раунд':
        return Icons.sports_mma_rounded;
      case 'удерж':
        return Icons.self_improvement_rounded;
      case 'время':
        return Icons.timer_rounded;
      default:
        return Icons.check_rounded;
    }
  }

  // ═════════════════════════════════════════════════════════
  //  EDIT DIALOG
  // ═════════════════════════════════════════════════════════
  void _showEditDialog(BuildContext context, FitnessProvider provider) {
    final nameController = TextEditingController(text: widget.exercise.name);
    final descController = TextEditingController(text: widget.exercise.description);
    final tipsController = TextEditingController(text: widget.exercise.techniqueTips ?? '');
    final mistakesController = TextEditingController(text: widget.exercise.commonMistakes ?? '');

    String? editImageUrl = widget.exercise.imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: _P.textSoft,
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
                        color: _P.peachSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_rounded, color: _P.peachDeep, size: 20),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'РЕДАКТИРОВАТЬ',
                            style: _T.overline.copyWith(
                              color: _P.peachDeep,
                              fontSize: 9,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Упражнение',
                            style: _T.title2.copyWith(
                              color: _P.text,
                              fontSize: 20,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildField(controller: nameController, label: 'НАЗВАНИЕ'),

                const SizedBox(height: 14),
                ImagePickerField(
                  label: 'ИЗОБРАЖЕНИЕ',
                  value: editImageUrl,
                  hint: widget.exercise.exerciseType == ExerciseType.cardio
                      ? ExerciseTypeHint.cardio
                      : widget.exercise.exerciseType == ExerciseType.boxing
                      ? ExerciseTypeHint.boxing
                      : widget.exercise.exerciseType == ExerciseType.yoga
                      ? ExerciseTypeHint.yoga
                      : ExerciseTypeHint.strength,
                  onChanged: (v) => setSheetState(() => editImageUrl = v),
                ),

                const SizedBox(height: 12),
                _buildField(controller: descController, label: 'ОПИСАНИЕ', maxLines: 4),
                const SizedBox(height: 12),
                _buildField(controller: tipsController, label: 'СОВЕТЫ', maxLines: 3),
                const SizedBox(height: 12),
                _buildField(controller: mistakesController, label: 'ОШИБКИ', maxLines: 3),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _P.text,
                            side: const BorderSide(color: _P.divider, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          ),
                          child: Text(
                            'Отмена',
                            style: _T.headline.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _P.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();

                            final updated = Exercise(
                              id: widget.exercise.id,
                              name: nameController.text.trim(),
                              description: descController.text.trim(),
                              muscleGroups: widget.exercise.muscleGroups,
                              imageUrl: editImageUrl,
                              exerciseType: widget.exercise.exerciseType,
                              isCustom: widget.exercise.isCustom,
                              videoUrl: widget.exercise.videoUrl,
                              techniqueTips: tipsController.text.trim().isNotEmpty
                                  ? tipsController.text.trim()
                                  : null,
                              commonMistakes: mistakesController.text.trim().isNotEmpty
                                  ? mistakesController.text.trim()
                                  : null,
                              createdAt: widget.exercise.createdAt,
                              updatedAt: DateTime.now(),
                              defaultFormat: widget.exercise.defaultFormat,
                            );

                            await provider.updateExercise(updated);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _P.peachDeep,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          ),
                          child: Text(
                            'СОХРАНИТЬ',
                            style: _T.caption2.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
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
                  height: 48,
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      _confirmDelete(context, provider);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _P.pinkDeep,
                      backgroundColor: _P.pinkSoft,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 17),
                        const SizedBox(width: 6),
                        Text(
                          'УДАЛИТЬ УПРАЖНЕНИЕ',
                          style: _T.caption2.copyWith(
                            color: _P.pinkDeep,
                            fontSize: 11,
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
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            label,
            style: _T.overline.copyWith(
              fontSize: 9,
              letterSpacing: 1.2,
              color: _P.textMuted,
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: _T.headline.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _P.text,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _P.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _P.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _P.peachDeep, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  DELETE CONFIRM
  // ═════════════════════════════════════════════════════════
  void _confirmDelete(BuildContext context, FitnessProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                      style: _T.headline.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _P.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '«${widget.exercise.name}» будет удалено безвозвратно',
                      textAlign: TextAlign.center,
                      style: _T.caption.copyWith(
                        fontSize: 12,
                        color: _P.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 0.8, color: _P.divider),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: Text(
                          'Отмена',
                          style: _T.headline.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _P.peachDeep,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 0.8, height: 50, color: _P.divider),
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
                        child: Text(
                          'Удалить',
                          style: _T.headline.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _P.pinkDeep,
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

  // ═════════════════════════════════════════════════════════
  //  HELPERS
  // ═════════════════════════════════════════════════════════
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