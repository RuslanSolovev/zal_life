// features/fitness/ui/screens/active_program_screen.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/enums.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/fitness_provider.dart';
import 'workout_execution_screen.dart';
import 'program_summary_screen.dart';
import 'program_builder_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  PREMIUM LIGHT DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════════
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
  static TextStyle title1 = GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: _P.text);
  static TextStyle title2 = GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: _P.text);
  static TextStyle headline = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _P.text);
  static TextStyle body = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: _P.text);
  static TextStyle caption = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
  static TextStyle overline = GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: _P.textMuted);
  static TextStyle number = GoogleFonts.inter(fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]);
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

// ═══════════════════════════════════════════════════════════════════
class ActiveProgramScreen extends StatefulWidget {
  final WorkoutProgram program;
  final bool isDark;

  const ActiveProgramScreen({
    super.key,
    required this.program,
    required this.isDark,
  });

  @override
  State<ActiveProgramScreen> createState() => _ActiveProgramScreenState();
}

class _ActiveProgramScreenState extends State<ActiveProgramScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressAnimController;
  Animation<double>? _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressAnimController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkIfCompleted();
      _animateProgress();
    });
  }

  void _animateProgress() {
    if (!mounted) return;
    final provider = context.read<FitnessProvider>();
    final session = provider.sessions
        .where((s) =>
    s.programId == widget.program.id &&
        (s.status == ProgramSessionStatus.active ||
            s.status == ProgramSessionStatus.completed ||
            s.status == ProgramSessionStatus.paused))
        .firstOrNull;

    if (session != null) {
      _progressAnimation = Tween<double>(begin: 0, end: session.progressPercent).animate(
        CurvedAnimation(parent: _progressAnimController, curve: Curves.easeOutCubic),
      );
      _progressAnimController.reset();
      _progressAnimController.forward();
      if (mounted) setState(() {});
    }
  }

  void _checkIfCompleted() {
    if (!mounted) return;
    final provider = context.read<FitnessProvider>();
    final session = provider.sessions.where((s) => s.programId == widget.program.id).firstOrNull;

    if (session != null && session.status == ProgramSessionStatus.completed) {
      debugPrint('🏆 Обнаружена завершённая программа, показываем сводку');
      _showCompletionScreen(session);
    }
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 Превью упражнения (поддержка assets)
  // ══════════════════════════════════════════════════════════
  Widget _buildExThumb(String? url, {required double size, required double radius, required Color accent, required String fallbackEmoji}) {
    final hasImage = url != null && url.isNotEmpty;
    final Widget fallback = Text(fallbackEmoji, style: TextStyle(fontSize: size * 0.55));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage
          ? (url!.startsWith('assets/')
          ? Image.asset(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
          : url.startsWith('http')
          ? CachedNetworkImage(imageUrl: url, width: size, height: size, fit: BoxFit.cover, placeholder: (_, __) => Container(color: accent.withOpacity(0.08)), errorWidget: (_, __, ___) => fallback)
          : Image.file(File(url), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback))
          : fallback,
    );
  }

  // ══════════════════════════════════════════════════════════
  //  Metric helpers
  // ══════════════════════════════════════════════════════════
  ({IconData icon, String value, String unit, String label, Color color, Color soft}) _dominantOfSession(ProgramSession session) {
    var m = session.totalByMetricCompleted;
    if (m.isEmpty && session.totalVolumeCompleted > 0) m = {'kg': session.totalVolumeCompleted};

    final km = m['km'] ?? 0;
    final rounds = m['rounds'] ?? 0;
    final kg = m['kg'] ?? 0;
    final sec = m['sec'] ?? 0;

    if (km > 0) return (icon: Icons.directions_run_rounded, value: km.toStringAsFixed(km >= 10 ? 1 : 2), unit: 'км', label: 'ДИСТАНЦИЯ', color: _P.skyDeep, soft: _P.skySoft);
    if (rounds > 0) return (icon: Icons.sports_mma_rounded, value: rounds.toStringAsFixed(0), unit: 'р.', label: 'РАУНДЫ', color: _P.peachDeep, soft: _P.peachSoft);
    if (kg > 0) return (icon: Icons.fitness_center_rounded, value: kg >= 1000 ? '${(kg / 1000).toStringAsFixed(1)}k' : kg.toStringAsFixed(0), unit: 'кг', label: 'ТОННАЖ', color: _P.lavenderDeep, soft: _P.lavenderSoft);
    if (sec > 0) {
      if (sec >= 3600) return (icon: Icons.timer_rounded, value: (sec / 3600).toStringAsFixed(1), unit: 'ч', label: 'ВРЕМЯ', color: _P.greenDeep, soft: _P.greenSoft);
      return (icon: Icons.timer_rounded, value: (sec / 60).toStringAsFixed(0), unit: 'м', label: 'ВРЕМЯ', color: _P.greenDeep, soft: _P.greenSoft);
    }
    return (icon: Icons.analytics_rounded, value: '0', unit: '', label: 'ОБЪЁМ', color: _P.textMuted, soft: _P.elevated);
  }

  ({String value, String unit, Color color}) _dominantOfLog(WorkoutLog log) {
    final m = log.totalByMetric ?? {};
    if ((m['km'] ?? 0) > 0) return (value: m['km']!.toStringAsFixed(m['km']! >= 10 ? 1 : 2), unit: 'км', color: _P.skyDeep);
    if ((m['rounds'] ?? 0) > 0) return (value: m['rounds']!.toStringAsFixed(0), unit: 'р.', color: _P.peachDeep);
    if ((m['kg'] ?? 0) > 0) return (value: m['kg']! >= 1000 ? '${(m['kg']! / 1000).toStringAsFixed(1)}k' : m['kg']!.toStringAsFixed(0), unit: 'кг', color: _P.lavenderDeep);
    if ((m['sec'] ?? 0) > 0) {
      final sec = m['sec']!;
      if (sec >= 3600) return (value: (sec / 3600).toStringAsFixed(1), unit: 'ч', color: _P.greenDeep);
      if (sec >= 60) return (value: (sec / 60).toStringAsFixed(0), unit: 'м', color: _P.greenDeep);
      return (value: sec.toStringAsFixed(0), unit: 'с', color: _P.greenDeep);
    }
    return (value: '—', unit: '', color: _P.textMuted);
  }

  WorkoutLog? _findLogForDay(ProgramSession session, DaySession daySession, FitnessProvider provider) {
    if (daySession.status != DaySessionStatus.completed || daySession.completedAt == null) return null;
    final target = daySession.completedAt!;
    WorkoutLog? best;
    int bestDiffSec = 60;
    for (final log in provider.logs) {
      if (log.status != WorkoutDayStatus.completed || log.programId != session.programId) continue;
      final ref = log.endTime ?? log.date;
      final diffSec = ref.difference(target).inSeconds.abs();
      if (diffSec < bestDiffSec) { best = log; bestDiffSec = diffSec; }
    }
    return best;
  }

  List<({String emoji, String label, String value, Color color})> _allMetricsOfSession(ProgramSession session) {
    var m = session.totalByMetricCompleted;
    if (m.isEmpty && session.totalVolumeCompleted > 0) m = {'kg': session.totalVolumeCompleted};
    final list = <({String emoji, String label, String value, Color color})>[];
    if ((m['kg'] ?? 0) > 0) list.add((emoji: '🏋️', label: 'Тоннаж', value: m['kg']! >= 1000 ? '${(m['kg']! / 1000).toStringAsFixed(2)} т' : '${m['kg']!.toStringAsFixed(0)} кг', color: _P.lavenderDeep));
    if ((m['km'] ?? 0) > 0) list.add((emoji: '📏', label: 'Дистанция', value: '${m['km']!.toStringAsFixed(2)} км', color: _P.skyDeep));
    if ((m['rounds'] ?? 0) > 0) list.add((emoji: '🥊', label: 'Раунды', value: '${m['rounds']!.toStringAsFixed(0)} р.', color: _P.peachDeep));
    if ((m['sec'] ?? 0) > 0) {
      final sec = m['sec']!;
      final v = sec >= 3600 ? '${(sec / 3600).floor()}ч ${((sec % 3600) / 60).round()}м' : '${(sec / 60).toStringAsFixed(0)} мин';
      list.add((emoji: '⏱️', label: 'Время', value: v, color: _P.greenDeep));
    }
    return list;
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final session = provider.sessions
        .where((s) =>
    s.programId == widget.program.id &&
        (s.status == ProgramSessionStatus.active ||
            s.status == ProgramSessionStatus.completed ||
            s.status == ProgramSessionStatus.paused))
        .firstOrNull;

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold(backgroundColor: _P.bg, body: Center(child: CircularProgressIndicator(color: _P.greenDeep)));
    }

    if (session.status == ProgramSessionStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCompletionScreen(session);
      });
    }

    final program = widget.program;
    final currentDayIndex = session.currentDayIndex;
    final currentDay = currentDayIndex < program.days.length ? program.days[currentDayIndex] : null;

    return Scaffold(
      backgroundColor: _P.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(program, session),
          SliverToBoxAdapter(child: _buildHeroProgress(session, program)),
          SliverToBoxAdapter(child: _buildStatsRow(session)),
          if (session.status == ProgramSessionStatus.paused) SliverToBoxAdapter(child: _buildPausedBanner()),
          if (currentDay != null && session.status == ProgramSessionStatus.active)
            SliverToBoxAdapter(child: _buildCurrentDaySection(currentDay, session, provider)),
          SliverToBoxAdapter(child: _buildDayMapSection(session, program, provider)),
          SliverToBoxAdapter(child: _buildActionButtons(session, provider)),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  APP BAR
  // ══════════════════════════════════════════════════════════
  Widget _buildSliverAppBar(WorkoutProgram program, ProgramSession session) {
    return SliverAppBar(
      pinned: true, backgroundColor: _P.bg.withOpacity(0.94), surfaceTintColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
        child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
          child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _P.divider)), child: const Icon(Icons.chevron_left_rounded, color: _P.text, size: 22)),
        ),
      ),
      title: Text(program.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _T.headline.copyWith(fontSize: 15)),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); _showEditDialog(context, program); },
            child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: _P.peachSoft, shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: _P.peachDeep, size: 17)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            icon: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _P.divider)), child: const Icon(Icons.more_horiz_rounded, color: _P.text, size: 19)),
            color: _P.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) => _handleMenuAction(value, session, program),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'pause', child: Row(children: [
                Icon(session.status == ProgramSessionStatus.paused ? Icons.play_arrow_rounded : Icons.pause_circle_outline_rounded, color: _P.peachDeep, size: 20),
                const SizedBox(width: 12),
                Text(session.status == ProgramSessionStatus.paused ? 'Возобновить' : 'Приостановить', style: _T.headline.copyWith(fontSize: 14)),
              ])),
              PopupMenuItem(value: 'edit', child: Row(children: [
                const Icon(Icons.edit_outlined, color: _P.peachDeep, size: 20),
                const SizedBox(width: 12),
                Text('Редактировать', style: _T.headline.copyWith(fontSize: 14)),
              ])),
              PopupMenuItem(value: 'abandon', child: Row(children: [
                const Icon(Icons.flag_outlined, color: _P.redDeep, size: 20),
                const SizedBox(width: 12),
                Text('Бросить', style: _T.headline.copyWith(color: _P.redDeep, fontSize: 14)),
              ])),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  HERO PROGRESS
  // ══════════════════════════════════════════════════════════
  Widget _buildHeroProgress(ProgramSession session, WorkoutProgram program) {
    final completedCount = session.daySessions.where((d) => d.status == DaySessionStatus.completed).length;
    final totalCount = session.daySessions.length;
    final daysRemaining = totalCount - completedCount;
    final isCompleted = session.status == ProgramSessionStatus.completed;
    final accent = isCompleted ? _P.greenDeep : _P.peachDeep;
    final soft = isCompleted ? _P.greenSoft : _P.peachSoft;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [soft, _P.surface]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withOpacity(0.18), width: 1),
          boxShadow: _P.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(7)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isCompleted ? Icons.emoji_events_rounded : Icons.local_fire_department_rounded, color: Colors.white, size: 11),
                    const SizedBox(width: 4),
                    Text(isCompleted ? 'ЗАВЕРШЕНО' : 'В ПРОЦЕССЕ', style: _T.caption.copyWith(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Spacer(),
                if (session.streak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7), border: Border.all(color: _P.border)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.bolt_rounded, color: _P.peachDeep, size: 11),
                      const SizedBox(width: 3),
                      Text('${session.streak} ${_getDaysWord(session.streak)}', style: _T.caption.copyWith(color: _P.peachDeep, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ДЕНЬ', style: _T.overline.copyWith(color: _P.textMuted, fontSize: 9)),
                      const SizedBox(height: 3),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text('${session.currentDayIndex + 1}', style: _T.number.copyWith(fontSize: 44, color: _P.text, height: 1, letterSpacing: -2)),
                        const SizedBox(width: 4),
                        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('из $totalCount', style: _T.caption.copyWith(color: _P.textMuted))),
                      ]),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _progressAnimController,
                  builder: (ctx, child) => Text('${((_progressAnimation?.value ?? 0) * 100).toInt()}%', style: _T.number.copyWith(color: accent, fontSize: 44, height: 1, letterSpacing: -2)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: AnimatedBuilder(
                animation: _progressAnimController,
                builder: (ctx, child) => LinearProgressIndicator(value: _progressAnimation?.value ?? 0, backgroundColor: Colors.white.withOpacity(0.7), valueColor: AlwaysStoppedAnimation(accent), minHeight: 7),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildHeroStat('ВЫПОЛНЕНО', '$completedCount', _P.greenDeep)),
                Container(width: 0.8, height: 28, color: _P.peachDeep.withOpacity(0.12)),
                Expanded(child: _buildHeroStat('ОСТАЛОСЬ', '$daysRemaining', _P.skyDeep, align: CrossAxisAlignment.end)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, Color color, {CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: _T.overline.copyWith(color: _P.textMuted, fontSize: 9)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.9, height: 1)),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STATS ROW
  // ══════════════════════════════════════════════════════════
  Widget _buildStatsRow(ProgramSession session) {
    final dominant = _dominantOfSession(session);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatBox(icon: dominant.icon, label: dominant.label, value: dominant.value, unit: dominant.unit, color: dominant.color, soft: dominant.soft)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatBox(icon: Icons.speed_rounded, label: 'СР. RPE', value: session.averageRpe > 0 ? session.averageRpe.toStringAsFixed(1) : '—', unit: '', color: _P.lavenderDeep, soft: _P.lavenderSoft)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatBox(icon: Icons.local_fire_department_rounded, label: 'РЕКОРД', value: '${session.longestStreak}', unit: 'дн.', color: _P.peachDeep, soft: _P.peachSoft)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatBox(icon: Icons.calendar_today_rounded, label: 'ДНЕЙ', value: '${session.durationDays}', unit: '', color: _P.skyDeep, soft: _P.skySoft)),
        ],
      ),
    );
  }

  Widget _buildStatBox({required IconData icon, required String label, required String value, required String unit, required Color color, required Color soft}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _P.divider), boxShadow: _P.cardShadow),
      child: Column(
        children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: color, size: 15)),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: _T.number.copyWith(fontSize: 17, color: _P.text))),
              if (unit.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 2, bottom: 1), child: Text(unit, style: _T.caption.copyWith(fontSize: 9))),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _T.overline.copyWith(fontSize: 8)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  PAUSED BANNER
  // ══════════════════════════════════════════════════════════
  Widget _buildPausedBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: _P.peachSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: _P.peachDeep.withOpacity(0.25))),
        child: Row(
          children: [
            Container(width: 38, height: 38, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(11))), child: const Icon(Icons.pause_circle_filled_rounded, color: _P.peachDeep, size: 20)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ПРОГРАММА НА ПАУЗЕ', style: _T.headline.copyWith(fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('Нажми «Продолжить»', style: _T.caption),
                ],
              ),
            ),
            GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); context.read<FitnessProvider>().resumeProgramSession(context.read<FitnessProvider>().activeSession!.id); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(color: _P.peachDeep, borderRadius: BorderRadius.circular(9)),
                child: Text('Продолжить', style: _T.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  CURRENT DAY SECTION
  // ══════════════════════════════════════════════════════════
  Widget _buildCurrentDaySection(WorkoutDay day, ProgramSession session, FitnessProvider provider) {
    if (day.isRestDay) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _P.divider)),
          child: Column(
            children: [
              Container(width: 66, height: 66, decoration: const BoxDecoration(color: _P.skySoft, shape: BoxShape.circle), child: const Icon(Icons.bedtime_rounded, size: 30, color: _P.skyDeep)),
              const SizedBox(height: 14),
              Text('ДЕНЬ ОТДЫХА', style: _T.overline.copyWith(fontSize: 10, color: _P.skyDeep)),
              const SizedBox(height: 4),
              Text('Восстановление важно', style: _T.title2.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Text('Мышцы растут, пока вы отдыхаете', textAlign: TextAlign.center, style: _T.caption),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () async { HapticFeedback.mediumImpact(); await provider.skipCurrentDay(reason: 'День отдыха'); if (mounted) { _animateProgress(); setState(() {}); } },
                  style: ElevatedButton.styleFrom(backgroundColor: _P.skyDeep, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.skip_next_rounded, size: 18), const SizedBox(width: 7), Text('К СЛЕДУЮЩЕМУ ДНЮ', style: _T.headline.copyWith(color: Colors.white, fontSize: 13))]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_P.greenSoft, _P.surface]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _P.greenDeep.withOpacity(0.2)),
          boxShadow: _P.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 42, height: 42, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(12))), child: const Icon(Icons.play_circle_filled_rounded, color: _P.greenDeep, size: 22)),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('СЕГОДНЯ', style: _T.overline.copyWith(fontSize: 9, color: _P.greenDeep)),
                      const SizedBox(height: 2),
                      Text('День ${session.currentDayIndex + 1}', style: _T.title2.copyWith(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text('${day.exercises.length} упражнений · ${_getEstimatedTime(day)}', style: _T.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(13), border: Border.all(color: _P.greenDeep.withOpacity(0.1))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('ПЛАН НА СЕГОДНЯ', style: _T.overline.copyWith(fontSize: 9)),
                      const Spacer(),
                      if (day.exercises.length > 3) Text('+ ${day.exercises.length - 3}', style: _T.caption.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ...day.exercises.take(3).toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ex = entry.value;
                    final exData = provider.exercises.firstWhere((e) => e.id == ex.exerciseId, orElse: () => Exercise(id: '', name: '???'));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          Container(width: 24, height: 24, decoration: BoxDecoration(color: _P.greenSoft, borderRadius: BorderRadius.circular(7)), alignment: Alignment.center, child: Text('${idx + 1}', style: _T.number.copyWith(fontSize: 10, color: _P.greenDeep))),
                          const SizedBox(width: 9),
                          _buildExThumb(exData.imageUrl, size: 24, radius: 7, accent: _P.greenDeep, fallbackEmoji: exData.exerciseType.emoji),
                          const SizedBox(width: 7),
                          Expanded(child: Text(exData.name, style: _T.caption.copyWith(fontWeight: FontWeight.w600, color: _P.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text('${ex.sets.length}×', style: _T.caption.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () => _startTodayWorkout(context, day),
                style: ElevatedButton.styleFrom(backgroundColor: _P.greenDeep, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.play_arrow_rounded, size: 22), const SizedBox(width: 7), Text('НАЧАТЬ ТРЕНИРОВКУ', style: _T.headline.copyWith(color: Colors.white, fontSize: 13))]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEstimatedTime(WorkoutDay day) {
    int totalSets = 0;
    for (final ex in day.exercises) { totalSets += ex.sets.length; }
    final minutes = totalSets * 3;
    if (minutes < 60) return '~$minutes мин';
    return '~${(minutes / 60).toStringAsFixed(1)} ч';
  }

  // ══════════════════════════════════════════════════════════
  //  DAY MAP
  // ══════════════════════════════════════════════════════════
  Widget _buildDayMapSection(ProgramSession session, WorkoutProgram program, FitnessProvider provider) {
    final completedCount = session.daySessions.where((d) => d.status == DaySessionStatus.completed).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _P.divider), boxShadow: _P.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 36, height: 36, decoration: const BoxDecoration(color: _P.peachSoft, borderRadius: BorderRadius.all(Radius.circular(11))), child: const Icon(Icons.map_rounded, color: _P.peachDeep, size: 18)),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('КАРТА ПРОГРАММЫ', style: _T.overline.copyWith(fontSize: 9)),
                      const SizedBox(height: 2),
                      Text('Прогресс по дням', style: _T.headline),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: _P.peachSoft, borderRadius: BorderRadius.circular(8)),
                  child: Text('$completedCount/${program.days.length}', style: _T.caption.copyWith(color: _P.peachDeep, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12, runSpacing: 6,
              children: [
                _buildLegendItem(Icons.check_circle_rounded, 'Выполнено', _P.greenDeep),
                _buildLegendItem(Icons.local_fire_department_rounded, 'Текущий', _P.peachDeep),
                _buildLegendItem(Icons.cancel_rounded, 'Пропущен', _P.redDeep),
                _buildLegendItem(Icons.lock_rounded, 'Закрыто', _P.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 0.8, color: _P.divider),
            const SizedBox(height: 12),
            ...program.days.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final daySession = index < session.daySessions.length ? session.daySessions[index] : null;
              return _buildDayTile(day, daySession, index, session.currentDayIndex, session, provider);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: _T.caption.copyWith(fontSize: 10)),
    ]);
  }

  Widget _buildDayTile(WorkoutDay day, DaySession? daySession, int index, int currentIndex, ProgramSession session, FitnessProvider provider) {
    Color accent, soft;
    IconData icon;
    String statusText;
    Color statusColor;
    bool isCurrent = index == currentIndex && daySession?.status == DaySessionStatus.current;

    if (daySession == null) {
      accent = _P.textMuted; soft = _P.elevated; icon = Icons.lock_rounded; statusText = 'Заблокировано'; statusColor = _P.textMuted;
    } else {
      switch (daySession.status) {
        case DaySessionStatus.completed:
          accent = _P.greenDeep; soft = _P.greenSoft; icon = Icons.check_circle_rounded;
          final log = _findLogForDay(session, daySession, provider);
          if (log != null && (log.totalByMetric?.isNotEmpty ?? false)) {
            final dominant = _dominantOfLog(log);
            statusText = dominant.unit.isNotEmpty ? '${dominant.value} ${dominant.unit}' : dominant.value;
            statusColor = dominant.color;
          } else if (daySession.volumeDone != null && daySession.volumeDone! > 0) {
            statusText = '${daySession.volumeDone!.toStringAsFixed(0)} кг'; statusColor = _P.greenDeep;
          } else {
            statusText = 'Выполнено'; statusColor = _P.greenDeep;
          }
          break;
        case DaySessionStatus.current:
          accent = _P.peachDeep; soft = _P.peachSoft; icon = Icons.local_fire_department_rounded; statusText = 'Текущий'; statusColor = _P.peachDeep;
          break;
        case DaySessionStatus.skipped:
          accent = _P.redDeep; soft = _P.redSoft; icon = Icons.cancel_rounded; statusText = 'Пропущен'; statusColor = _P.redDeep;
          break;
        default:
          accent = _P.textMuted; soft = _P.elevated; icon = Icons.lock_rounded; statusText = 'Ожидает'; statusColor = _P.textMuted;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isCurrent ? _P.peachSoft : soft.withOpacity(0.4),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: isCurrent ? _P.peachDeep.withOpacity(0.4) : accent.withOpacity(0.14), width: isCurrent ? 1.2 : 0.8),
      ),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: accent.withOpacity(0.18))), child: Icon(icon, color: accent, size: 18)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('День ${index + 1}${day.isRestDay ? " 😴" : ""}', style: _T.headline.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(day.isRestDay ? 'День отдыха' : '${day.exercises.length} упражнений', style: _T.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(statusText, style: _T.number.copyWith(fontSize: 11, color: statusColor)),
              if (daySession?.completedAt != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(_formatDate(daySession!.completedAt!), style: _T.caption.copyWith(fontSize: 9))),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';

  // ══════════════════════════════════════════════════════════
  //  ACTION BUTTONS
  // ══════════════════════════════════════════════════════════
  Widget _buildActionButtons(ProgramSession session, FitnessProvider provider) {
    if (session.status != ProgramSessionStatus.active) return const SizedBox.shrink();
    final currentDay = session.currentDayIndex < widget.program.days.length ? widget.program.days[session.currentDayIndex] : null;
    if (currentDay == null || currentDay.isRestDay) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); _confirmSkipDay(context, session); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: _P.divider)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.skip_next_rounded, size: 16, color: _P.textMuted),
            const SizedBox(width: 6),
            Text('ПРОПУСТИТЬ ДЕНЬ', style: _T.headline.copyWith(fontSize: 12, color: _P.textMuted)),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  DIALOGS
  // ══════════════════════════════════════════════════════════
  void _startTodayWorkout(BuildContext context, WorkoutDay day) {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: WorkoutExecutionScreen(day: day, isDark: false))))
        .then((_) { if (mounted) { _checkIfCompleted(); _animateProgress(); } });
  }

  void _confirmSkipDay(BuildContext context, ProgramSession session) {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(color: _P.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 5, decoration: BoxDecoration(color: _P.textSoft, borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 20),
            Text('Пропустить день?', style: _T.title2),
            const SizedBox(height: 6),
            Text('Серия из ${session.streak} ${_getDaysWord(session.streak)} сбросится', style: _T.caption),
            const SizedBox(height: 14),
            TextField(controller: reasonController, maxLines: 2, decoration: InputDecoration(hintText: 'Причина (необязательно)', filled: true, fillColor: _P.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена'))),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async { HapticFeedback.mediumImpact(); Navigator.pop(ctx); await context.read<FitnessProvider>().skipCurrentDay(reason: reasonController.text); if (mounted) _animateProgress(); },
                    style: ElevatedButton.styleFrom(backgroundColor: _P.peachDeep, foregroundColor: Colors.white, elevation: 0),
                    child: const Text('ПРОПУСТИТЬ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WorkoutProgram program) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: ProgramBuilderScreen(existingProgram: program, isDark: false))));
  }

  void _handleMenuAction(String action, ProgramSession session, WorkoutProgram program) async {
    final provider = context.read<FitnessProvider>();
    switch (action) {
      case 'pause':
        HapticFeedback.selectionClick();
        if (session.status == ProgramSessionStatus.paused) await provider.resumeProgramSession(session.id);
        else await provider.pauseProgramSession();
        break;
      case 'edit': _showEditDialog(context, program); break;
      case 'abandon': _confirmAbandonProgram(context, session, program); break;
    }
  }

  void _confirmAbandonProgram(BuildContext context, ProgramSession session, WorkoutProgram program) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(color: _P.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 5, decoration: BoxDecoration(color: _P.textSoft, borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 20),
              Text('Бросить программу?', style: _T.title2),
              const SizedBox(height: 6),
              Text('Весь прогресс будет остановлен.', style: _T.caption),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена'))),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async { HapticFeedback.mediumImpact(); Navigator.pop(ctx); await context.read<FitnessProvider>().abandonProgramSession(session.id); if (mounted && Navigator.canPop(context)) Navigator.pop(context); },
                      style: ElevatedButton.styleFrom(backgroundColor: _P.redDeep, foregroundColor: Colors.white, elevation: 0),
                      child: const Text('БРОСИТЬ'),
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

  void _showCompletionScreen(ProgramSession session) {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<FitnessProvider>(), child: ProgramSummaryScreen(session: session, program: widget.program, isDark: false))));
  }

  String _getDaysWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'день';
    if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) return 'дня';
    return 'дней';
  }
}