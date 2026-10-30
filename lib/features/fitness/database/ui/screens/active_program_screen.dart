// features/fitness/ui/screens/active_program_screen.dart
// 🆕 v17.1: format-aware статистика + доминирующая метрика в карте дней
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/enums.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/fitness_provider.dart';
import 'workout_execution_screen.dart';
import 'program_summary_screen.dart';
import 'program_builder_screen.dart';

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
      CurvedAnimation(
        parent: _progressAnimController,
        curve: Curves.easeOutCubic,
      ),
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
      _progressAnimation = Tween<double>(
        begin: 0,
        end: session.progressPercent,
      ).animate(CurvedAnimation(
        parent: _progressAnimController,
        curve: Curves.easeOutCubic,
      ));

      _progressAnimController.reset();
      _progressAnimController.forward();

      if (mounted) setState(() {});
    }
  }

  void _checkIfCompleted() {
    if (!mounted) return;
    final provider = context.read<FitnessProvider>();

    final session = provider.sessions
        .where((s) => s.programId == widget.program.id)
        .firstOrNull;

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
  // 🆕 ХЕЛПЕРЫ МЕТРИК
  // ══════════════════════════════════════════════════════════

  /// Доминирующая метрика сессии: km → rounds → kg → sec.
  ({IconData icon, String value, String unit, String label, Color color})
  _dominantOfSession(ProgramSession session) {
    var m = session.totalByMetricCompleted;
    if (m.isEmpty && session.totalVolumeCompleted > 0) {
      m = {'kg': session.totalVolumeCompleted};
    }

    final km = m['km'] ?? 0;
    final rounds = m['rounds'] ?? 0;
    final kg = m['kg'] ?? 0;
    final sec = m['sec'] ?? 0;

    if (km > 0) {
      return (
      icon: Icons.directions_run_rounded,
      value: km.toStringAsFixed(km >= 10 ? 1 : 2),
      unit: 'км',
      label: 'ДИСТАНЦИЯ',
      color: _Power.ice,
      );
    }
    if (rounds > 0) {
      return (
      icon: Icons.sports_mma_rounded,
      value: rounds.toStringAsFixed(0),
      unit: 'р.',
      label: 'РАУНДЫ',
      color: _Power.plasma,
      );
    }
    if (kg > 0) {
      return (
      icon: Icons.fitness_center_rounded,
      value: kg >= 1000
          ? '${(kg / 1000).toStringAsFixed(1)}k'
          : kg.toStringAsFixed(0),
      unit: 'кг',
      label: 'ТОННАЖ',
      color: _Power.lime,
      );
    }
    if (sec > 0) {
      if (sec >= 3600) {
        return (
        icon: Icons.timer_rounded,
        value: (sec / 3600).toStringAsFixed(1),
        unit: 'ч',
        label: 'ВРЕМЯ',
        color: _Power.ice,
        );
      }
      return (
      icon: Icons.timer_rounded,
      value: (sec / 60).toStringAsFixed(0),
      unit: 'м',
      label: 'ВРЕМЯ',
      color: _Power.ice,
      );
    }
    return (
    icon: Icons.analytics_rounded,
    value: '0',
    unit: '',
    label: 'ОБЪЁМ',
    color: _Power.textTertiary(true),
    );
  }

  /// 🆕 Доминирующая метрика конкретного лога (для карточки дня).
  ({String value, String unit, Color color}) _dominantOfLog(WorkoutLog log) {
    final m = log.totalByMetric ?? {};

    if ((m['km'] ?? 0) > 0) {
      final km = m['km']!;
      return (
      value: km.toStringAsFixed(km >= 10 ? 1 : 2),
      unit: 'км',
      color: _Power.ice,
      );
    }
    if ((m['rounds'] ?? 0) > 0) {
      return (
      value: m['rounds']!.toStringAsFixed(0),
      unit: 'р.',
      color: _Power.plasma,
      );
    }
    if ((m['kg'] ?? 0) > 0) {
      final kg = m['kg']!;
      return (
      value: kg >= 1000
          ? '${(kg / 1000).toStringAsFixed(1)}k'
          : kg.toStringAsFixed(0),
      unit: 'кг',
      color: _Power.lime,
      );
    }
    if ((m['sec'] ?? 0) > 0) {
      final sec = m['sec']!;
      if (sec >= 3600) {
        return (
        value: (sec / 3600).toStringAsFixed(1),
        unit: 'ч',
        color: _Power.ice,
        );
      }
      if (sec >= 60) {
        return (
        value: (sec / 60).toStringAsFixed(0),
        unit: 'м',
        color: _Power.ice,
        );
      }
      return (
      value: sec.toStringAsFixed(0),
      unit: 'с',
      color: _Power.ice,
      );
    }
    return (value: '—', unit: '', color: _Power.textTertiary(true));
  }

  /// 🆕 Ищет `WorkoutLog`, соответствующий завершённому `DaySession`.
  ///
  /// Матчинг по `programId` + `endTime ≈ completedAt` (±60 сек).
  /// Так как `completedAt` выставляется в `_updateSessionFromLog`
  /// из `log.endTime`, разница должна быть нулевой; ±60 сек — запас.
  WorkoutLog? _findLogForDay(
      ProgramSession session,
      DaySession daySession,
      FitnessProvider provider,
      ) {
    if (daySession.status != DaySessionStatus.completed) return null;
    if (daySession.completedAt == null) return null;

    final target = daySession.completedAt!;
    WorkoutLog? best;
    int bestDiffSec = 60;

    for (final log in provider.logs) {
      if (log.status != WorkoutDayStatus.completed) continue;
      if (log.programId != session.programId) continue;

      final ref = log.endTime ?? log.date;
      final diffSec = ref.difference(target).inSeconds.abs();

      if (diffSec < bestDiffSec) {
        best = log;
        bestDiffSec = diffSec;
      }
    }

    return best;
  }

  /// Список всех ненулевых метрик сессии (для диалога бросания и др.).
  List<({String emoji, String label, String value, Color color})>
  _allMetricsOfSession(ProgramSession session) {
    var m = session.totalByMetricCompleted;
    if (m.isEmpty && session.totalVolumeCompleted > 0) {
      m = {'kg': session.totalVolumeCompleted};
    }

    final list = <({String emoji, String label, String value, Color color})>[];

    if ((m['kg'] ?? 0) > 0) {
      final kg = m['kg']!;
      list.add((
      emoji: '🏋️',
      label: 'Тоннаж',
      value: kg >= 1000
          ? '${(kg / 1000).toStringAsFixed(2)} т'
          : '${kg.toStringAsFixed(0)} кг',
      color: _Power.lime,
      ));
    }
    if ((m['km'] ?? 0) > 0) {
      list.add((
      emoji: '📏',
      label: 'Дистанция',
      value: '${m['km']!.toStringAsFixed(2)} км',
      color: _Power.ice,
      ));
    }
    if ((m['rounds'] ?? 0) > 0) {
      list.add((
      emoji: '🥊',
      label: 'Раунды',
      value: '${m['rounds']!.toStringAsFixed(0)} р.',
      color: _Power.plasma,
      ));
    }
    if ((m['sec'] ?? 0) > 0) {
      final sec = m['sec']!;
      final String value;
      if (sec >= 3600) {
        final h = (sec / 3600).floor();
        final min = ((sec % 3600) / 60).round();
        value = '${h}ч ${min}м';
      } else {
        value = '${(sec / 60).toStringAsFixed(0)} мин';
      }
      list.add((
      emoji: '⏱️',
      label: 'Время',
      value: value,
      color: _Power.ice,
      ));
    }
    if ((m['punches'] ?? 0) > 0) {
      list.add((
      emoji: '👊',
      label: 'Удары',
      value: '${m['punches']!.toStringAsFixed(0)}',
      color: _Power.magma,
      ));
    }
    if ((m['kcal'] ?? 0) > 0) {
      list.add((
      emoji: '🔥',
      label: 'Калории',
      value: '${m['kcal']!.toStringAsFixed(0)} ккал',
      color: _Power.magma,
      ));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
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
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return Scaffold(
        backgroundColor: _Power.bg(isDark),
        body: const Center(
          child: CircularProgressIndicator(color: _Power.volt),
        ),
      );
    }

    if (session.status == ProgramSessionStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCompletionScreen(session);
      });
    }

    final program = widget.program;
    final currentDayIndex = session.currentDayIndex;
    final currentDay = currentDayIndex < program.days.length
        ? program.days[currentDayIndex]
        : null;

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(isDark, program, session),
          SliverToBoxAdapter(
            child: _buildHeroProgress(isDark, session, program),
          ),
          SliverToBoxAdapter(child: _buildStatsRow(isDark, session)),
          if (session.status == ProgramSessionStatus.paused)
            SliverToBoxAdapter(child: _buildPausedBanner(isDark)),
          if (currentDay != null &&
              session.status == ProgramSessionStatus.active)
            SliverToBoxAdapter(
              child: _buildCurrentDaySection(
                isDark,
                currentDay,
                session,
                provider,
              ),
            ),
          SliverToBoxAdapter(
            // 🆕 передаём provider для format-aware карты дней
            child: _buildDayMapSection(isDark, session, program, provider),
          ),
          SliverToBoxAdapter(
            child: _buildActionButtons(isDark, session, provider),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  // =====================================================================
  // APP BAR
  // =====================================================================

  Widget _buildSliverAppBar(
      bool isDark,
      WorkoutProgram program,
      ProgramSession session,
      ) {
    return SliverAppBar(
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
        program.name,
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
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _showEditDialog(context, program);
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
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.more_horiz_rounded,
                color: _Power.textPrimary(isDark),
                size: 20,
              ),
            ),
            color: _Power.card(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) => _handleMenuAction(value, session, program),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'pause',
                child: Row(
                  children: [
                    Icon(
                      session.status == ProgramSessionStatus.paused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_circle_outline_rounded,
                      color: _Power.volt,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      session.status == ProgramSessionStatus.paused
                          ? 'Возобновить'
                          : 'Приостановить',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      color: _Power.volt,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Редактировать',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'abandon',
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      color: _Power.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Бросить',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _Power.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // HERO PROGRESS
  // =====================================================================

  Widget _buildHeroProgress(
      bool isDark,
      ProgramSession session,
      WorkoutProgram program,
      ) {
    final completedCount = session.daySessions
        .where((d) => d.status == DaySessionStatus.completed)
        .length;
    final totalCount = session.daySessions.length;
    final daysRemaining = totalCount - completedCount;
    final isCompleted =
        session.status == ProgramSessionStatus.completed;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF050505),
            Color(0xFF0F0700),
            Color(0xFF1A0A00),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _Power.volt.withOpacity(0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(26),
                ),
                gradient: LinearGradient(
                  colors: [
                    _Power.volt.withOpacity(0.0),
                    _Power.volt,
                    _Power.magma,
                    _Power.volt,
                    _Power.volt.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted ? _Power.green : _Power.volt,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _Power.softGlow(
                          isCompleted ? _Power.green : _Power.volt,
                          strength: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.emoji_events_rounded
                                : Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted ? 'ЗАВЕРШЕНО' : 'В ПРОЦЕССЕ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (session.streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              color: _Power.plasma,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${session.streak} ${_getDaysWord(session.streak)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ДЕНЬ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${session.currentDayIndex + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  letterSpacing: -2.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding:
                                const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'из $totalCount',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _progressAnimController,
                      builder: (ctx, child) {
                        final progressValue =
                            _progressAnimation?.value ?? 0;
                        return Text(
                          '${(progressValue * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -2.5,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedBuilder(
                    animation: _progressAnimController,
                    builder: (ctx, child) {
                      final progressValue =
                          _progressAnimation?.value ?? 0;
                      return LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor:
                        Colors.white.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation(
                          _Power.volt,
                        ),
                        minHeight: 8,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildHeroStat(
                        'ВЫПОЛНЕНО',
                        '$completedCount',
                        _Power.green,
                      ),
                    ),
                    Container(
                      width: 0.5,
                      height: 28,
                      color: Colors.white.withOpacity(0.08),
                    ),
                    Expanded(
                      child: _buildHeroStat(
                        'ОСТАЛОСЬ',
                        '$daysRemaining',
                        _Power.ice,
                        align: CrossAxisAlignment.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(
      String label,
      String value,
      Color color, {
        CrossAxisAlignment align = CrossAxisAlignment.start,
      }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            height: 1,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // STATS ROW — доминирующая метрика
  // ══════════════════════════════════════════════════════════

  Widget _buildStatsRow(bool isDark, ProgramSession session) {
    final dominant = _dominantOfSession(session);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatBox(
              isDark,
              icon: dominant.icon,
              label: dominant.label,
              value: dominant.value,
              unit: dominant.unit,
              color: dominant.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatBox(
              isDark,
              icon: Icons.speed_rounded,
              label: 'СР. RPE',
              value: session.averageRpe > 0
                  ? session.averageRpe.toStringAsFixed(1)
                  : '—',
              unit: '',
              color: _Power.lime,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatBox(
              isDark,
              icon: Icons.local_fire_department_rounded,
              label: 'РЕКОРД',
              value: '${session.longestStreak}',
              unit: 'дн.',
              color: _Power.plasma,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatBox(
              isDark,
              icon: Icons.calendar_today_rounded,
              label: 'ДНЕЙ',
              value: '${session.durationDays}',
              unit: '',
              color: _Power.magma,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
      bool isDark, {
        required IconData icon,
        required String label,
        required String value,
        required String unit,
        required Color color,
      }) {
    return Container(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1,
                    color: _Power.textPrimary(isDark),
                  ),
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
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: _Power.textTertiary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // PAUSED BANNER
  // =====================================================================

  Widget _buildPausedBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Power.plasma.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _Power.plasma.withOpacity(0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _Power.plasma.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _Power.softGlow(_Power.plasma, strength: 0.2),
            ),
            child: const Icon(
              Icons.pause_circle_filled_rounded,
              color: _Power.plasma,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ПРОГРАММА НА ПАУЗЕ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Нажмите «Возобновить» чтобы продолжить',
                  style: TextStyle(
                    fontSize: 11,
                    color: _Power.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<FitnessProvider>().resumeProgramSession(
                context.read<FitnessProvider>().activeSession!.id,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _Power.plasma,
                borderRadius: BorderRadius.circular(10),
                boxShadow: _Power.softGlow(_Power.plasma, strength: 0.4),
              ),
              child: const Text(
                'Продолжить',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // CURRENT DAY SECTION
  // =====================================================================

  Widget _buildCurrentDaySection(
      bool isDark,
      WorkoutDay day,
      ProgramSession session,
      FitnessProvider provider,
      ) {
    final isRestDay = day.isRestDay;

    if (isRestDay) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _Power.card(isDark),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _Power.separator(isDark), width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _Power.ice.withOpacity(0.14),
                shape: BoxShape.circle,
                boxShadow: _Power.softGlow(_Power.ice, strength: 0.2),
              ),
              child: const Icon(
                Icons.bedtime_rounded,
                size: 32,
                color: _Power.ice,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ДЕНЬ ОТДЫХА',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                color: _Power.ice,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Восстановление важно 😴',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: _Power.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Мышцы растут, пока вы отдыхаете',
              style: TextStyle(
                fontSize: 13,
                color: _Power.textSecondary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await provider.skipCurrentDay(reason: 'День отдыха');
                  if (mounted) {
                    _animateProgress();
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Power.ice,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.skip_next_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'К СЛЕДУЮЩЕМУ ДНЮ',
                      style: TextStyle(
                        fontSize: 14,
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
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _Power.green.withOpacity(0.14),
            _Power.volt.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _Power.green.withOpacity(0.35),
          width: 1,
        ),
        boxShadow: _Power.glow(_Power.green, strength: 0.15, blur: 20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _Power.green.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: _Power.softGlow(_Power.green, strength: 0.3),
                  ),
                  child: const Icon(
                    Icons.play_circle_filled_rounded,
                    color: _Power.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'СЕГОДНЯ',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                          color: _Power.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'День ${session.currentDayIndex + 1}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          height: 1.1,
                          color: _Power.textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${day.exercises.length} упражнений • ${_getEstimatedTime(day)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _Power.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ПЛАН НА СЕГОДНЯ',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                          color: _Power.textTertiary(isDark),
                        ),
                      ),
                      const Spacer(),
                      if (day.exercises.length > 3)
                        Text(
                          '+ ${day.exercises.length - 3}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _Power.textTertiary(isDark),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...day.exercises.take(3).toList().asMap().entries.map(
                        (entry) {
                      final idx = entry.key;
                      final ex = entry.value;
                      final exData = provider.exercises.firstWhere(
                            (e) => e.id == ex.exerciseId,
                        orElse: () => Exercise(id: '', name: '???'),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: _Power.volt.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  color: _Power.volt,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              exData.exerciseType.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                exData.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: _Power.textPrimary(isDark),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${ex.sets.length}×',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _Power.textTertiary(isDark),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _startTodayWorkout(context, day),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Power.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  shadowColor: _Power.green.withOpacity(0.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'НАЧАТЬ ТРЕНИРОВКУ',
                      style: TextStyle(
                        fontSize: 15,
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
  }

  String _getEstimatedTime(WorkoutDay day) {
    int totalSets = 0;
    for (final ex in day.exercises) {
      totalSets += ex.sets.length;
    }
    final minutes = totalSets * 3;
    if (minutes < 60) return '~$minutes мин';
    return '~${(minutes / 60).toStringAsFixed(1)} ч';
  }

  // =====================================================================
  // DAY MAP — 🆕 format-aware отображение доминирующей метрики
  // =====================================================================

  Widget _buildDayMapSection(
      bool isDark,
      ProgramSession session,
      WorkoutProgram program,
      FitnessProvider provider, // 🆕
      ) {
    final completedCount = session.daySessions
        .where((d) => d.status == DaySessionStatus.completed)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _Power.volt.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _Power.softGlow(_Power.volt, strength: 0.15),
                ),
                child: const Icon(
                  Icons.map_rounded,
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
                      'КАРТА ПРОГРАММЫ',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                        color: _Power.textTertiary(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Прогресс по дням',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _Power.volt.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$completedCount/${program.days.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: _Power.volt,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendItem(isDark, Icons.check_circle_rounded,
                  'Выполнено', _Power.green),
              _buildLegendItem(isDark, Icons.local_fire_department_rounded,
                  'Текущий', _Power.volt),
              _buildLegendItem(
                  isDark, Icons.cancel_rounded, 'Пропущен', _Power.red),
              _buildLegendItem(isDark, Icons.lock_rounded, 'Закрыто',
                  _Power.textTertiary(isDark)),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 0.5, color: _Power.separator(isDark)),
          const SizedBox(height: 14),
          ...program.days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final daySession = index < session.daySessions.length
                ? session.daySessions[index]
                : null;
            return _buildDayTile(
              isDark,
              day,
              daySession,
              index,
              session.currentDayIndex,
              session,   // 🆕
              provider,  // 🆕
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      bool isDark,
      IconData icon,
      String label,
      Color color,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _Power.textSecondary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildDayTile(
      bool isDark,
      WorkoutDay day,
      DaySession? daySession,
      int index,
      int currentIndex,
      ProgramSession session,    // 🆕
      FitnessProvider provider,  // 🆕
      ) {
    Color accent;
    IconData icon;
    String statusText;
    Color statusColor;
    bool isCurrent =
        index == currentIndex && daySession?.status == DaySessionStatus.current;

    if (daySession == null) {
      accent = _Power.textTertiary(isDark);
      icon = Icons.lock_rounded;
      statusText = 'Заблокировано';
      statusColor = _Power.textTertiary(isDark);
    } else {
      switch (daySession.status) {
        case DaySessionStatus.completed:
          accent = _Power.green;
          icon = Icons.check_circle_rounded;

          // 🆕 format-aware: показываем доминирующую метрику лога,
          //    а не всегда «кг» (для кардио/бокса это 0).
          final log = _findLogForDay(session, daySession, provider);
          if (log != null && (log.totalByMetric?.isNotEmpty ?? false)) {
            final dominant = _dominantOfLog(log);
            statusText = dominant.unit.isNotEmpty
                ? '${dominant.value} ${dominant.unit}'
                : dominant.value;
            statusColor = dominant.color;
          } else if (daySession.volumeDone != null &&
              daySession.volumeDone! > 0) {
            // Fallback: legacy-поле
            statusText = '${daySession.volumeDone!.toStringAsFixed(0)} кг';
            statusColor = _Power.lime;
          } else {
            statusText = 'Выполнено';
            statusColor = _Power.green;
          }
          break;
        case DaySessionStatus.current:
          accent = _Power.volt;
          icon = Icons.local_fire_department_rounded;
          statusText = 'Текущий';
          statusColor = _Power.volt;
          break;
        case DaySessionStatus.skipped:
          accent = _Power.red;
          icon = Icons.cancel_rounded;
          statusText = 'Пропущен';
          statusColor = _Power.red;
          break;
        case DaySessionStatus.locked:
        case DaySessionStatus.pending:
          accent = _Power.textTertiary(isDark);
          icon = Icons.lock_rounded;
          statusText = 'Ожидает';
          statusColor = _Power.textTertiary(isDark);
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? _Power.volt.withOpacity(0.10)
            : accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? _Power.volt.withOpacity(0.5)
              : accent.withOpacity(0.15),
          width: isCurrent ? 1.2 : 0.6,
        ),
        boxShadow:
        isCurrent ? _Power.softGlow(_Power.volt, strength: 0.15) : null,
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
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'День ${index + 1}${day.isRestDay ? " 😴" : ""}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.isRestDay
                      ? 'День отдыха'
                      : '${day.exercises.length} упражнений',
                  style: TextStyle(
                    fontSize: 11,
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
                statusText.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: statusColor,
                ),
              ),
              if (daySession?.completedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _formatDate(daySession!.completedAt!),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _Power.textTertiary(isDark),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  // =====================================================================
  // ACTION BUTTONS
  // =====================================================================

  Widget _buildActionButtons(
      bool isDark,
      ProgramSession session,
      FitnessProvider provider,
      ) {
    if (session.status != ProgramSessionStatus.active) {
      return const SizedBox.shrink();
    }

    final currentDay = session.currentDayIndex < widget.program.days.length
        ? widget.program.days[session.currentDayIndex]
        : null;

    if (currentDay == null || currentDay.isRestDay) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _confirmSkipDay(context, session);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _Power.card(isDark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _Power.separator(isDark),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.skip_next_rounded,
                size: 16,
                color: _Power.textSecondary(isDark),
              ),
              const SizedBox(width: 6),
              Text(
                'ПРОПУСТИТЬ ДЕНЬ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
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
  // DIALOGS
  // =====================================================================

  void _startTodayWorkout(BuildContext context, WorkoutDay day) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FitnessProvider>(),
          child: WorkoutExecutionScreen(day: day, isDark: widget.isDark),
        ),
      ),
    ).then((_) {
      if (mounted) {
        _checkIfCompleted();
        _animateProgress();
      }
    });
  }

  void _confirmSkipDay(BuildContext context, ProgramSession session) {
    final reasonController = TextEditingController();
    final isDark = widget.isDark;

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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
              'ПРОПУСТИТЬ ДЕНЬ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                color: _Power.volt,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Уверены?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: _Power.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _Power.volt.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _Power.volt.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: _Power.volt,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Серия из ${session.streak} ${_getDaysWord(session.streak)} сбросится',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: TextStyle(
                fontSize: 14,
                color: _Power.textPrimary(isDark),
              ),
              decoration: InputDecoration(
                hintText: 'Причина (необязательно)',
                hintStyle: TextStyle(
                  color: _Power.textTertiary(isDark),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: _Power.card2(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
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
                        side: BorderSide(
                          color: _Power.separator(isDark),
                        ),
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
                        Navigator.pop(ctx);
                        await context
                            .read<FitnessProvider>()
                            .skipCurrentDay(reason: reasonController.text);
                        if (mounted) _animateProgress();
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
                        'ПРОПУСТИТЬ',
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
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WorkoutProgram program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FitnessProvider>(),
          child: ProgramBuilderScreen(
            existingProgram: program,
            isDark: widget.isDark,
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(
      String action,
      ProgramSession session,
      WorkoutProgram program,
      ) async {
    final provider = context.read<FitnessProvider>();

    switch (action) {
      case 'pause':
        HapticFeedback.selectionClick();
        if (session.status == ProgramSessionStatus.paused) {
          await provider.resumeProgramSession(session.id);
        } else {
          await provider.pauseProgramSession();
        }
        break;
      case 'edit':
        _showEditDialog(context, program);
        break;
      case 'abandon':
        _confirmAbandonProgram(context, session, program);
        break;
    }
  }

  // ══════════════════════════════════════════════════════════
  // ABANDON DIALOG — мультиметрики
  // ══════════════════════════════════════════════════════════

  void _confirmAbandonProgram(
      BuildContext context,
      ProgramSession session,
      WorkoutProgram program,
      ) {
    final isDark = widget.isDark;
    final metrics = _allMetricsOfSession(session);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: _Power.card(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: _Power.textTertiary(isDark),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'БРОСИТЬ ПРОГРАММУ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  color: _Power.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Точно?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: _Power.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _Power.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _Power.red.withOpacity(0.25),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    _buildAbandonStat(
                      isDark,
                      '✅ Выполнено дней',
                      '${session.totalWorkoutsCompleted}',
                      _Power.green,
                    ),
                    const SizedBox(height: 8),
                    if (metrics.isEmpty)
                      _buildAbandonStat(
                        isDark,
                        '📊 Объём',
                        '—',
                        _Power.textTertiary(isDark),
                      )
                    else
                      ...metrics.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _buildAbandonStat(
                          isDark,
                          '${m.emoji} ${m.label}',
                          m.value,
                          m.color,
                        ),
                      )),
                    const SizedBox(height: 8),
                    _buildAbandonStat(
                      isDark,
                      '🔥 Макс. серия',
                      '${session.longestStreak} ${_getDaysWord(session.longestStreak)}',
                      _Power.plasma,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Весь прогресс будет остановлен. Вы сможете начать заново позже.',
                style: TextStyle(
                  fontSize: 12,
                  color: _Power.textSecondary(isDark),
                  height: 1.4,
                ),
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
                          side: BorderSide(
                            color: _Power.separator(isDark),
                          ),
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
                          Navigator.pop(ctx);
                          await context
                              .read<FitnessProvider>()
                              .abandonProgramSession(session.id);
                          if (mounted && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Power.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          shadowColor: _Power.red.withOpacity(0.5),
                        ),
                        child: const Text(
                          'БРОСИТЬ',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbandonStat(
      bool isDark,
      String label,
      String value,
      Color color,
      ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _Power.textSecondary(isDark),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showCompletionScreen(ProgramSession session) {
    debugPrint('🎬 Переход на экран сводки: ${widget.program.name}');

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FitnessProvider>(),
          child: ProgramSummaryScreen(
            session: session,
            program: widget.program,
            isDark: widget.isDark,
          ),
        ),
      ),
    );
  }

  String _getDaysWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'день';
    if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'дня';
    }
    return 'дней';
  }
}