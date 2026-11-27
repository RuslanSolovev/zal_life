import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ─── ИМПОРТЫ ТВОЕГО ПРОЕКТА (проверь пути, если они отличаются) ───
import '../../../models/enums.dart';
import '../../../models/fitness_models.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/exercise_image_selector.dart';

class _Palette {
  static const Color bg = Color(0xFFF6F5F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF263D36);
  static const Color textMuted = Color(0xFF7C8982);
  static const Color green = Color(0xFF426C59);
  static const Color greenSoft = Color(0xFFE7EFE5);
  static const Color sage = Color(0xFF8CAB93);
  static const Color peach = Color(0xFFC79475);
  static const Color peachSoft = Color(0xFFF5E6DC);
  static const Color pink = Color(0xFFBB8F9D);
  static const Color blue = Color(0xFF3B82F6);
  static const Color pinkSoft = Color(0xFFF2E4E7);
  static const Color yellow = Color(0xFFE7D9B8);
  static const Color divider = Color(0xFFE5E8E1);
}

class _Hero {
  static const Color bgTop = Color(0xFF1B2027);
  static const Color bgBottom = Color(0xFF161719);
  static const Color accent = Color(0xFFEF9563);
  static const Color textHigh = Colors.white;
  static const Color textLow = Color(0xFFA4A6AA);
}

class _HeroAccents {
  static const Color peach = Color(0xFFEF9563);
  static const Color amber = Color(0xFFE8B858);
  static const Color sage = Color(0xFFA5C9AF);
  static const Color pink = Color(0xFFE899A8);
  static const Color sky = Color(0xFF7EA8C6);
}

class _Vibrant {
  static const Color neonGreen = Color(0xFF3DDC84);
  static const Color vividPeach = Color(0xFFFF8A65);
  static const Color electricBlue = Color(0xFF4A90E2);
  static const Color glowingPink = Color(0xFFFF6B8B);
  static const Color goldTop = Color(0xFFF4D06F);
  static const Color goldMid = Color(0xFFE8B858);
  static const Color goldBottom = Color(0xFFD4A04A);
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

// ═══════════════════════════════════════════════════════════════════
//  EXERCISE DETAIL SCREEN
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

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> with SingleTickerProviderStateMixin {
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

  // ═════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final r = _R(context);

    final accentColor = widget.exercise.muscleGroups.isNotEmpty
        ? widget.exercise.muscleGroups.first.color
        : _Palette.peach;

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ═══ 1. ПОЛНОЭКРАННОЕ ИЗОБРАЖЕНИЕ СО СКРУГЛЕНИЕМ СНИЗУ ═══
          SliverToBoxAdapter(
            child: _buildFullBleedHeroSection(accentColor, r),
          ),

          // ═══ 2. APP BAR (Прилипает при скролле) ═══
          SliverAppBar(
            pinned: true,
            backgroundColor: _Palette.bg.withOpacity(0.95),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 60,
            leading: Padding(
              padding: EdgeInsets.only(left: r.s(16), top: r.s(10), bottom: r.s(10)),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                child: Container(
                  width: r.s(36),
                  height: r.s(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _Palette.divider, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.chevron_left_rounded, color: _Palette.text, size: r.s(22)),
                ),
              ),
            ),
            title: Text(
              widget.exercise.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: r.fs(16),
                fontWeight: FontWeight.w600,
                color: _Palette.text,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: EdgeInsets.only(right: r.s(16)),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showEditDialog(context, provider, r);
                  },
                  child: Container(
                    width: r.s(36),
                    height: r.s(36),
                    decoration: BoxDecoration(
                      color: _Palette.peachSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: _Palette.peach.withOpacity(0.20), width: 0.7),
                    ),
                    child: Icon(Icons.edit_rounded, color: _Palette.peach, size: r.s(17)),
                  ),
                ),
              ),
            ],
          ),

          if (widget.exercise.muscleGroups.isNotEmpty)
            SliverToBoxAdapter(child: _buildMuscleGroups(r)),

          SliverToBoxAdapter(child: SizedBox(height: r.s(18))),

          SliverToBoxAdapter(
            child: _buildStatsCards(accentColor, r),
          ),

          SliverToBoxAdapter(child: SizedBox(height: r.s(22))),
          SliverToBoxAdapter(child: _buildTabs(r)),
          SliverToBoxAdapter(child: SizedBox(height: r.s(12))),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(r),
            _buildProgressTab(provider, r),
            _buildHistoryTab(provider, r),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  FULL BLEED HERO SECTION — ГЛАВНОЕ ИЗМЕНЕНИЕ ЗДЕСЬ
  // ═════════════════════════════════════════════════════════
  Widget _buildFullBleedHeroSection(Color accent, _R r) {
    final hasImage = widget.exercise.imageUrl != null && widget.exercise.imageUrl!.isNotEmpty;

    return Container(
      height: r.s(380),
      width: double.infinity,
      // 🎯 СКРУГЛЕНИЕ ТОЛЬКО СНИЗУ
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(r.s(32))),
        color: _Palette.surface,
      ),
      // 🚨 КРИТИЧЕСКИ ВАЖНО: обрезает картинку и градиент по форме скругления
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Изображение или Fallback
          if (hasImage)
            _buildHeroImage(accent, r)
          else
            _buildHeroFallback(accent, r),

          // 2. Градиент для читаемости текста
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.4, 0.6, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // 3. Контент внизу (Chips и Название)
          Positioned(
            bottom: r.s(24),
            left: r.s(20),
            right: r.s(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: r.s(6),
                  runSpacing: r.s(6),
                  children: [
                    _glassChip('${widget.exercise.exerciseType.emoji} ${widget.exercise.exerciseType.displayName}', r),
                    _glassChip('${_format.emoji} ${_format.shortName}', r),
                    if (widget.exercise.isCustom) _glassChip('✦ МОЁ', r),
                  ],
                ),
                SizedBox(height: r.s(12)),
                Text(
                  widget.exercise.name,
                  style: GoogleFonts.inter(
                    fontSize: r.fs(32),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    height: 1.05,
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

  Widget _buildHeroImage(Color accent, _R r) {
    final url = widget.exercise.imageUrl!;
    return _AppImg(
      path: url,
      fit: BoxFit.cover,
      fallback: _buildHeroFallback(accent, r),
    );
  }

  Widget _buildHeroFallback(Color accent, _R r) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Colors.black, 0.4) ?? accent],
        ),
      ),
      child: Center(
        child: Text(
          widget.exercise.exerciseType.emoji,
          style: TextStyle(fontSize: r.fs(100), color: Colors.white.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _glassChip(String label, _R r) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(7)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(r.s(100)),
        border: Border.all(color: Colors.white.withOpacity(0.32), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: r.fs(11),
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
  Widget _buildMuscleGroups(_R r) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(16), r.s(16), 0),
      child: Wrap(
        spacing: r.s(8),
        runSpacing: r.s(8),
        children: widget.exercise.muscleGroups.map((muscle) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: r.s(11), vertical: r.s(6)),
            decoration: BoxDecoration(
              color: muscle.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(r.s(10)),
              border: Border.all(color: muscle.color.withOpacity(0.22), width: 0.7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(muscle.emoji, style: TextStyle(fontSize: r.fs(12))),
                SizedBox(width: r.s(5)),
                Text(
                  muscle.displayName,
                  style: GoogleFonts.inter(
                    fontSize: r.fs(11.5),
                    fontWeight: FontWeight.w800,
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
  //  STATS CARDS (Упрощенная адаптивная версия)
  // ═════════════════════════════════════════════════════════
  Widget _buildStatsCards(Color accent, _R r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(16)),
      child: Container(
        padding: EdgeInsets.all(r.s(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.s(16)),
          border: Border.all(color: _Palette.divider, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Лучший вес', '80 кг', _Palette.green, r),
            Container(width: 1, height: r.s(40), color: _Palette.divider),
            _statItem('Подходов', '124', _Palette.sage, r),
            Container(width: 1, height: r.s(40), color: _Palette.divider),
            _statItem('Тоннаж', '12т', _Palette.peach, r),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color, _R r) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: r.fs(18),
            fontWeight: FontWeight.w800,
            color: _Palette.text,
          ),
        ),
        SizedBox(height: r.s(4)),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: r.fs(10),
            color: _Palette.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  TABS
  // ═════════════════════════════════════════════════════════
  Widget _buildTabs(_R r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(16)),
      child: Container(
        padding: EdgeInsets.all(r.s(4)),
        decoration: BoxDecoration(
          color: _Palette.divider.withOpacity(0.3),
          borderRadius: BorderRadius.circular(r.s(14)),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: _Palette.textMuted,
          indicator: BoxDecoration(
            color: _Palette.peach,
            borderRadius: BorderRadius.circular(r.s(10)),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w800),
          tabs: const [Tab(text: 'ИНФО'), Tab(text: 'ПРОГРЕСС'), Tab(text: 'ИСТОРИЯ')],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  INFO TAB
  // ═════════════════════════════════════════════════════════
  Widget _buildInfoTab(_R r) {
    final hasDescription = widget.exercise.description.isNotEmpty;
    final hasTips = widget.exercise.techniqueTips != null && widget.exercise.techniqueTips!.isNotEmpty;
    final hasMistakes = widget.exercise.commonMistakes != null && widget.exercise.commonMistakes!.isNotEmpty;

    if (!hasDescription && !hasTips && !hasMistakes) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(r.s(40)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: r.s(84),
                height: r.s(84),
                decoration: const BoxDecoration(color: _Palette.peachSoft, shape: BoxShape.circle),
                child: Icon(Icons.info_outline_rounded, size: r.s(36), color: _Palette.peach),
              ),
              SizedBox(height: r.s(18)),
              Text(
                'Нет описания',
                style: GoogleFonts.inter(fontSize: r.fs(17), fontWeight: FontWeight.w700, color: _Palette.text),
              ),
              SizedBox(height: r.s(6)),
              Text(
                'Добавь описание через редактирование',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: r.fs(12), color: _Palette.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(40)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDescription) _infoSection(Icons.description_rounded, 'ОПИСАНИЕ', widget.exercise.description, _Palette.peach, r),
          if (hasTips) ...[
            SizedBox(height: r.s(12)),
            _infoSection(Icons.lightbulb_rounded, 'СОВЕТЫ ПО ТЕХНИКЕ', widget.exercise.techniqueTips!, _Palette.yellow, r),
          ],
          if (hasMistakes) ...[
            SizedBox(height: r.s(12)),
            _infoSection(Icons.warning_rounded, 'ЧАСТЫЕ ОШИБКИ', widget.exercise.commonMistakes!, _Palette.pink, r),
          ],
        ],
      ),
    );
  }

  Widget _infoSection(IconData icon, String title, String content, Color accent, _R r) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.s(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.s(16)),
        border: Border.all(color: _Palette.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _Palette.peach.withOpacity(0.03),
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
                width: r.s(30),
                height: r.s(30),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(r.s(9)),
                ),
                child: Icon(icon, color: accent, size: r.s(15)),
              ),
              SizedBox(width: r.s(9)),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: r.fs(10),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r.s(10)),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: r.fs(13.5),
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: _Palette.text,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  PROGRESS TAB (Заглушка с графиком для примера)
  // ═════════════════════════════════════════════════════════
  Widget _buildProgressTab(FitnessProvider provider, _R r) {
    final progressRecords = provider.getExerciseProgress(widget.exercise.id);

    if (progressRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(r.s(40)),
          child: Column(
            children: [
              Container(
                width: r.s(80),
                height: r.s(80),
                decoration: const BoxDecoration(color: _Palette.peachSoft, shape: BoxShape.circle),
                child: Icon(Icons.show_chart_rounded, size: r.s(34), color: _Palette.peach),
              ),
              SizedBox(height: r.s(18)),
              Text(
                'Нет данных',
                style: GoogleFonts.inter(fontSize: r.fs(17), fontWeight: FontWeight.w700, color: _Palette.text),
              ),
              SizedBox(height: r.s(6)),
              Text(
                'Прогресс появится после тренировок',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: r.fs(12), color: _Palette.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    // Простой график для демонстрации
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(40)),
      child: Container(
        height: r.s(280),
        padding: EdgeInsets.all(r.s(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.s(18)),
          border: Border.all(color: _Palette.divider, width: 0.8),
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20, getDrawingHorizontalLine: (value) => FlLine(color: _Palette.divider, strokeWidth: 0.6)),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20, reservedSize: 40, getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: GoogleFonts.inter(fontSize: r.fs(10), color: _Palette.textMuted)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 2, getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: GoogleFonts.inter(fontSize: r.fs(9), color: _Palette.textMuted)))),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: progressRecords.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.bestWeight ?? 0)).toList(),
                isCurved: true,
                color: _Palette.peach,
                barWidth: 3,
                dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: _Palette.peach, strokeWidth: 2, strokeColor: Colors.white)),
                belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_Palette.peach.withOpacity(0.20), _Palette.peach.withOpacity(0.0)])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HISTORY TAB
  // ═════════════════════════════════════════════════════════
  Widget _buildHistoryTab(FitnessProvider provider, _R r) {
    final progressRecords = provider.getExerciseProgress(widget.exercise.id);

    if (progressRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(r.s(40)),
          child: Text(
            'История появится после тренировок',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: r.fs(13), color: _Palette.textMuted),
          ),
        ),
      );
    }

    final sortedRecords = List<ProgressRecord>.from(progressRecords)..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(40)),
      itemCount: sortedRecords.length,
      itemBuilder: (context, index) {
        final record = sortedRecords[index];
        return Container(
          margin: EdgeInsets.only(bottom: r.s(8)),
          padding: EdgeInsets.all(r.s(12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r.s(14)),
            border: Border.all(color: _Palette.divider, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: r.s(38),
                height: r.s(38),
                decoration: BoxDecoration(
                  color: _Palette.peachSoft,
                  borderRadius: BorderRadius.circular(r.s(11)),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.fitness_center_rounded, color: _Palette.peach, size: r.s(17)),
              ),
              SizedBox(width: r.s(11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.date.day.toString().padLeft(2, '0')}.${record.date.month.toString().padLeft(2, '0')}.${record.date.year}',
                      style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w800, color: _Palette.text),
                    ),
                    SizedBox(height: r.s(2)),
                    Text(
                      '${record.totalSets} подх. · ${(record.totalVolume ?? 0).toStringAsFixed(0)} кг',
                      style: GoogleFonts.inter(fontSize: r.fs(10.5), fontWeight: FontWeight.w600, color: _Palette.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${record.bestWeight?.toStringAsFixed(0) ?? 0} × ${record.bestReps ?? 0}',
                    style: GoogleFonts.inter(fontSize: r.fs(13), fontWeight: FontWeight.w900, color: _Palette.text),
                  ),
                  SizedBox(height: r.s(2)),
                  Text(
                    '1RM: ${(record.estimated1RM ?? 0).toStringAsFixed(0)}',
                    style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w700, color: _Palette.peach),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════
  //  EDIT DIALOG
  // ═════════════════════════════════════════════════════════
  void _showEditDialog(BuildContext context, FitnessProvider provider, _R r) {
    final nameController = TextEditingController(text: widget.exercise.name);
    final descController = TextEditingController(text: widget.exercise.description);
    final tipsController = TextEditingController(text: widget.exercise.techniqueTips ?? '');
    final mistakesController = TextEditingController(text: widget.exercise.commonMistakes ?? '');

    String? editImageUrl = widget.exercise.imageUrl;
    String? defaultImg;

    if (!widget.exercise.isCustom) {
      final currentUrl = widget.exercise.imageUrl;
      if (currentUrl != null && currentUrl.startsWith('assets/exercise_presets/')) {
        defaultImg = currentUrl;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: r.s(20),
            right: r.s(20),
            top: r.s(12),
            bottom: MediaQuery.of(ctx).viewInsets.bottom + r.s(24),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: r.s(36),
                    height: r.s(5),
                    decoration: BoxDecoration(
                      color: _Palette.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(r.s(3)),
                    ),
                  ),
                ),
                SizedBox(height: r.s(20)),
                Row(
                  children: [
                    Container(
                      width: r.s(42),
                      height: r.s(42),
                      decoration: BoxDecoration(
                        color: _Palette.peachSoft,
                        borderRadius: BorderRadius.circular(r.s(12)),
                      ),
                      child: Icon(Icons.edit_rounded, color: _Palette.peach, size: r.s(20)),
                    ),
                    SizedBox(width: r.s(11)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'РЕДАКТИРОВАТЬ',
                            style: GoogleFonts.inter(color: _Palette.peach, fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.4),
                          ),
                          SizedBox(height: r.s(2)),
                          Text(
                            'Упражнение',
                            style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(20), fontWeight: FontWeight.w600, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.s(18)),
                _buildField(nameController, 'НАЗВАНИЕ', r),
                SizedBox(height: r.s(14)),

                // Селектор изображений
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final newUrl = await showExerciseImageSelector(
                      context: context,
                      currentImageUrl: editImageUrl,
                      isCustom: widget.exercise.isCustom,
                      defaultImageUrl: defaultImg,
                    );
                    if (newUrl != null) {
                      setSheetState(() => editImageUrl = newUrl.isEmpty ? null : newUrl);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(r.s(14)),
                    decoration: BoxDecoration(
                      color: _Palette.bg,
                      borderRadius: BorderRadius.circular(r.s(13)),
                      border: Border.all(color: _Palette.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: r.s(40),
                          height: r.s(40),
                          decoration: BoxDecoration(
                            color: _Palette.peachSoft,
                            borderRadius: BorderRadius.circular(r.s(10)),
                          ),
                          child: Icon(Icons.image_rounded, color: _Palette.peach, size: r.s(20)),
                        ),
                        SizedBox(width: r.s(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ИЗОБРАЖЕНИЕ',
                                style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.2),
                              ),
                              SizedBox(height: r.s(2)),
                              Text(
                                editImageUrl != null && editImageUrl!.isNotEmpty ? 'Изменено' : 'Нажмите, чтобы выбрать',
                                style: GoogleFonts.inter(fontSize: r.fs(13), color: editImageUrl != null && editImageUrl!.isNotEmpty ? _Palette.text : _Palette.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: _Palette.textMuted, size: r.s(20)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: r.s(12)),
                _buildField(descController, 'ОПИСАНИЕ', r, maxLines: 4),
                SizedBox(height: r.s(12)),
                _buildField(tipsController, 'СОВЕТЫ', r, maxLines: 3),
                SizedBox(height: r.s(12)),
                _buildField(mistakesController, 'ОШИБКИ', r, maxLines: 3),
                SizedBox(height: r.s(18)),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: r.s(50),
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _Palette.text,
                            side: const BorderSide(color: _Palette.divider, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(13))),
                          ),
                          child: Text('Отмена', style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w700, color: _Palette.text)),
                        ),
                      ),
                    ),
                    SizedBox(width: r.s(10)),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: r.s(50),
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
                              techniqueTips: tipsController.text.trim().isNotEmpty ? tipsController.text.trim() : null,
                              commonMistakes: mistakesController.text.trim().isNotEmpty ? mistakesController.text.trim() : null,
                              createdAt: widget.exercise.createdAt,
                              updatedAt: DateTime.now(),
                              defaultFormat: widget.exercise.defaultFormat,
                            );
                            await provider.updateExercise(updated);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Palette.peach,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(13))),
                          ),
                          child: Text('СОХРАНИТЬ', style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(13), fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.exercise.isCustom) ...[
                  SizedBox(height: r.s(10)),
                  SizedBox(
                    width: double.infinity,
                    height: r.s(48),
                    child: TextButton(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        await provider.deleteExercise(widget.exercise.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: _Palette.pink,
                        backgroundColor: _Palette.pinkSoft,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(13))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded, size: r.s(17)),
                          SizedBox(width: r.s(6)),
                          Text('УДАЛИТЬ УПРАЖНЕНИЕ', style: GoogleFonts.inter(color: _Palette.pink, fontSize: r.fs(11), fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, _R r, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: r.s(2), bottom: r.s(5)),
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: r.fs(9), letterSpacing: 1.2, color: _Palette.textMuted, fontWeight: FontWeight.w800),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, color: _Palette.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: _Palette.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(13)), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(13)), borderSide: const BorderSide(color: _Palette.divider, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(13)), borderSide: const BorderSide(color: _Palette.peach, width: 1.4)),
            contentPadding: EdgeInsets.symmetric(horizontal: r.s(13), vertical: r.s(13)),
          ),
        ),
      ],
    );
  }
}