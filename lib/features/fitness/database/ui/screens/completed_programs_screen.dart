// features/fitness/ui/screens/completed_programs_screen.dart
// 🆕 v16: format-aware итоги и сессии (сила / кардио / бокс / статика)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../providers/fitness_provider.dart';
import 'program_summary_screen.dart';

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

class CompletedProgramsScreen extends StatefulWidget {
  final bool isDark;

  const CompletedProgramsScreen({
    super.key,
    required this.isDark,
  });

  @override
  State<CompletedProgramsScreen> createState() =>
      _CompletedProgramsScreenState();
}

class _CompletedProgramsScreenState extends State<CompletedProgramsScreen> {
  String _filter = 'all';

  // ══════════════════════════════════════════════════════════
  // 🆕 ХЕЛПЕРЫ МЕТРИК
  // ══════════════════════════════════════════════════════════

  /// Сумма метрик по всем сессиям: {kg, km, rounds, sec, punches, kcal}.
  Map<String, double> _totalMetricAcrossSessions(List<ProgramSession> sessions) {
    final result = <String, double>{};
    for (final s in sessions) {
      final m = s.totalByMetricCompleted;
      if (m.isNotEmpty) {
        m.forEach((k, v) {
          result[k] = (result[k] ?? 0) + v;
        });
      } else if (s.totalVolumeCompleted > 0) {
        result['kg'] = (result['kg'] ?? 0) + s.totalVolumeCompleted;
      }
    }
    return result;
  }

  /// Доминирующая метрика по всем сессиям: km → rounds → kg → sec.
  ({String emoji, String value, String label, Color color}) _dominantOfTotals(
      Map<String, double> m) {
    final km = m['km'] ?? 0;
    final rounds = m['rounds'] ?? 0;
    final kg = m['kg'] ?? 0;
    final sec = m['sec'] ?? 0;

    if (km > 0) {
      return (
      emoji: '📏',
      value: km.toStringAsFixed(km >= 10 ? 1 : 2),
      label: 'КМ',
      color: _Power.ice,
      );
    }
    if (rounds > 0) {
      return (
      emoji: '🥊',
      value: rounds.toStringAsFixed(0),
      label: 'РАУНД',
      color: _Power.plasma,
      );
    }
    if (kg > 0) {
      return (
      emoji: '🏋️',
      value: kg >= 1000
          ? '${(kg / 1000).toStringAsFixed(1)}k'
          : kg.toStringAsFixed(0),
      label: 'КГ',
      color: _Power.lime,
      );
    }
    if (sec > 0) {
      if (sec >= 3600) {
        return (
        emoji: '⏱️',
        value: (sec / 3600).toStringAsFixed(1),
        label: 'ЧАС',
        color: _Power.ice,
        );
      }
      return (
      emoji: '⏱️',
      value: (sec / 60).toStringAsFixed(0),
      label: 'МИН',
      color: _Power.ice,
      );
    }
    return (
    emoji: '📊',
    value: '0',
    label: '—',
    color: _Power.textTertiary(true),
    );
  }

  /// Доминирующая метрика конкретной сессии.
  ({String emoji, String value, String label, Color color}) _dominantOfSession(
      ProgramSession session) {
    var m = session.totalByMetricCompleted;
    if (m.isEmpty && session.totalVolumeCompleted > 0) {
      m = {'kg': session.totalVolumeCompleted};
    }
    return _dominantOfTotals(m);
  }

  /// Чипы всех ненулевых метрик сессии.
  Widget _sessionMetricBadges(ProgramSession session, bool isDark) {
    var m = session.totalByMetricCompleted;
    if (m.isEmpty && session.totalVolumeCompleted > 0) {
      m = {'kg': session.totalVolumeCompleted};
    }
    if (m.isEmpty) return const SizedBox.shrink();

    final chips = <Widget>[];

    void addChip(String emoji, String value, String label, Color color) {
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
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
                letterSpacing: 0.4,
                height: 1,
                color: color.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ));
    }

    if ((m['kg'] ?? 0) > 0) {
      final kg = m['kg']!;
      addChip(
        '🏋️',
        kg >= 1000
            ? '${(kg / 1000).toStringAsFixed(1)}k'
            : kg.toStringAsFixed(0),
        'КГ',
        _Power.lime,
      );
    }
    if ((m['km'] ?? 0) > 0) {
      final km = m['km']!;
      addChip('📏', km.toStringAsFixed(km >= 10 ? 1 : 2), 'КМ', _Power.ice);
    }
    if ((m['rounds'] ?? 0) > 0) {
      addChip('🥊', m['rounds']!.toStringAsFixed(0), 'РАУНД', _Power.plasma);
    }
    if ((m['sec'] ?? 0) > 0) {
      final sec = m['sec']!;
      final label = sec >= 3600
          ? '${(sec / 3600).toStringAsFixed(1)}ч'
          : '${(sec / 60).toStringAsFixed(0)}м';
      addChip('⏱️', label, 'ВРЕМЯ', _Power.ice);
    }
    if ((m['punches'] ?? 0) > 0) {
      addChip('👊', m['punches']!.toStringAsFixed(0), 'УДАР', _Power.magma);
    }
    if ((m['kcal'] ?? 0) > 0) {
      addChip('🔥', m['kcal']!.toStringAsFixed(0), 'ККАЛ', _Power.magma);
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: chips,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = context.watch<FitnessProvider>();

    final allSessions = provider.sessions
        .where((s) => s.status != ProgramSessionStatus.active)
        .toList();

    final filteredSessions = allSessions.where((s) {
      switch (_filter) {
        case 'completed':
          return s.status == ProgramSessionStatus.completed;
        case 'abandoned':
          return s.status == ProgramSessionStatus.abandoned;
        case 'paused':
          return s.status == ProgramSessionStatus.paused;
        default:
          return true;
      }
    }).toList();

    filteredSessions.sort((a, b) => b.startDate.compareTo(a.startDate));

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
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
              'История',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: _Power.textPrimary(isDark),
              ),
            ),
            centerTitle: true,
          ),

          // Large title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ПРОГРАММЫ',
                    style: TextStyle(
                      color: _Power.volt,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'История',
                    style: TextStyle(
                      color: _Power.textPrimary(isDark),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${allSessions.length} ${_plural(allSessions.length, "программа", "программы", "программ")}',
                    style: TextStyle(
                      color: _Power.textSecondary(isDark),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Total stats
          SliverToBoxAdapter(
            child: _buildTotalStats(isDark, provider),
          ),

          // Filters
          SliverToBoxAdapter(
            child: _buildFilters(isDark),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // List
          if (filteredSessions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(isDark),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final session = filteredSessions[index];
                    return _buildSessionCard(isDark, session, provider);
                  },
                  childCount: filteredSessions.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 TOTAL STATS — мультиметрика
  // ══════════════════════════════════════════════════════════

  Widget _buildTotalStats(bool isDark, FitnessProvider provider) {
    final completedCount = provider.sessions
        .where((s) => s.status == ProgramSessionStatus.completed)
        .length;

    final totals = _totalMetricAcrossSessions(provider.sessions);
    final dominant = _dominantOfTotals(totals);

    final totalWorkouts = provider.sessions.fold<int>(
      0,
          (sum, s) => sum + s.totalWorkoutsCompleted,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
        borderRadius: BorderRadius.circular(24),
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
          // Bottom accent
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _Power.volt.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow:
                        _Power.softGlow(_Power.volt, strength: 0.3),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: _Power.volt,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ИТОГО',
                            style: TextStyle(
                              color: _Power.volt,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Ваша история',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildTotalStat(
                      '🏆',
                      '$completedCount',
                      'ПРОГРАММ',
                      _Power.plasma,
                    ),
                    _buildTotalDivider(),
                    // 🆕 Доминирующая метрика (км / раунды / кг / сек)
                    _buildTotalStat(
                      dominant.emoji,
                      dominant.value,
                      dominant.label,
                      dominant.color,
                    ),
                    _buildTotalDivider(),
                    _buildTotalStat(
                      '💪',
                      '$totalWorkouts',
                      'ТРЕНИРОВОК',
                      _Power.volt,
                    ),
                  ],
                ),
                // 🆕 Все метрики — если их больше одной
                if (totals.isNotEmpty && _hasMultipleMetrics(totals)) ...[
                  const SizedBox(height: 14),
                  Container(
                    height: 0.5,
                    color: Colors.white.withOpacity(0.08),
                  ),
                  const SizedBox(height: 12),
                  _buildAllTotalsRow(totals),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasMultipleMetrics(Map<String, double> m) {
    int count = 0;
    for (final k in ['kg', 'km', 'rounds', 'sec']) {
      if ((m[k] ?? 0) > 0) count++;
    }
    return count > 1;
  }

  /// 🆕 Строка всех ненулевых метрик за всю историю.
  Widget _buildAllTotalsRow(Map<String, double> m) {
    final chips = <Widget>[];

    void addChip(String emoji, String value, String label, Color color) {
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
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
      ));
    }

    if ((m['kg'] ?? 0) > 0) {
      final kg = m['kg']!;
      addChip(
        '🏋️',
        kg >= 1000
            ? '${(kg / 1000).toStringAsFixed(1)}k'
            : kg.toStringAsFixed(0),
        'КГ',
        _Power.lime,
      );
    }
    if ((m['km'] ?? 0) > 0) {
      final km = m['km']!;
      addChip('📏', km.toStringAsFixed(km >= 10 ? 1 : 2), 'КМ', _Power.ice);
    }
    if ((m['rounds'] ?? 0) > 0) {
      addChip('🥊', m['rounds']!.toStringAsFixed(0), 'РАУНД', _Power.plasma);
    }
    if ((m['sec'] ?? 0) > 0) {
      final sec = m['sec']!;
      final label = sec >= 3600
          ? '${(sec / 3600).toStringAsFixed(1)}ч'
          : '${(sec / 60).toStringAsFixed(0)}м';
      addChip('⏱️', label, 'ВРЕМЯ', _Power.ice);
    }
    if ((m['punches'] ?? 0) > 0) {
      addChip('👊', m['punches']!.toStringAsFixed(0), 'УДАР', _Power.magma);
    }
    if ((m['kcal'] ?? 0) > 0) {
      addChip('🔥', m['kcal']!.toStringAsFixed(0), 'ККАЛ', _Power.magma);
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: chips,
    );
  }

  Widget _buildTotalDivider() {
    return Container(
      width: 0.5,
      height: 40,
      color: Colors.white.withOpacity(0.08),
    );
  }

  Widget _buildTotalStat(
      String emoji,
      String value,
      String label,
      Color accent,
      ) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // FILTERS (без изменений)
  // =====================================================================

  Widget _buildFilters(bool isDark) {
    final filters = [
      {'id': 'all', 'label': 'ВСЕ', 'icon': Icons.list_rounded},
      {
        'id': 'completed',
        'label': 'ЗАВЕРШЕНО',
        'icon': Icons.check_circle_rounded
      },
      {
        'id': 'abandoned',
        'label': 'БРОШЕНО',
        'icon': Icons.flag_rounded
      },
      {'id': 'paused', 'label': 'ПАУЗА', 'icon': Icons.pause_circle_rounded},
    ];

    return Container(
      height: 42,
      margin: const EdgeInsets.only(top: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filter == filter['id'];

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filter = filter['id'] as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _Power.volt : _Power.card(isDark),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isSelected
                      ? _Power.volt
                      : _Power.separator(isDark),
                  width: 0.8,
                ),
                boxShadow: isSelected
                    ? _Power.softGlow(_Power.volt, strength: 0.35)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : _Power.textSecondary(isDark),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: isSelected
                          ? Colors.white
                          : _Power.textPrimary(isDark),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 SESSION CARD — доминирующая метрика вместо «кг»
  // ══════════════════════════════════════════════════════════

  Widget _buildSessionCard(
      bool isDark,
      ProgramSession session,
      FitnessProvider provider,
      ) {
    WorkoutProgram? program;
    try {
      program = provider.programs.firstWhere((p) => p.id == session.programId);
    } catch (_) {
      program = null;
    }

    final programName = program?.name ?? 'Удалённая программа';
    final statusInfo = _getStatusInfo(session.status);
    final accent = statusInfo['color'] as Color;
    final duration = session.endDate != null
        ? session.endDate!.difference(session.startDate).inDays
        : DateTime.now().difference(session.startDate).inDays;

    final completedDays = session.daySessions
        .where((d) => d.status == DaySessionStatus.completed)
        .length;
    final totalDays = session.daySessions.length;

    final dominant = _dominantOfSession(session);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (session.status == ProgramSessionStatus.completed &&
            program != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: provider,
                child: ProgramSummaryScreen(
                  session: session,
                  program: program!,
                  isDark: isDark,
                ),
              ),
            ),
          );
        } else {
          _showSessionDetails(context, session, program);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _Power.card(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withOpacity(0.25),
            width: 0.8,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _Power.softGlow(accent, strength: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        statusInfo['emoji'] as String,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          programName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: _Power.textPrimary(isDark),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatDate(session.startDate)} — ${session.endDate != null ? _formatDate(session.endDate!) : 'сейчас'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _Power.textTertiary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusInfo['label'] as String,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),

              // Progress (для завершённых)
              if (session.status == ProgramSessionStatus.completed) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 13,
                      color: _Power.textTertiary(isDark),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ВЫПОЛНЕНО $completedDays / $totalDays',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: _Power.textSecondary(isDark),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(session.progressPercent * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: _Power.volt,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: session.progressPercent,
                    backgroundColor: _Power.separator(isDark),
                    valueColor: const AlwaysStoppedAnimation(
                      _Power.volt,
                    ),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Stats
              Row(
                children: [
                  _buildSessionStat(
                    isDark,
                    Icons.calendar_month_rounded,
                    '$duration',
                    'дн.',
                    _Power.ice,
                  ),
                  const SizedBox(width: 6),
                  _buildSessionStat(
                    isDark,
                    Icons.fitness_center_rounded,
                    '${session.totalWorkoutsCompleted}',
                    'трен.',
                    _Power.volt,
                  ),
                  const SizedBox(width: 6),
                  // 🆕 Доминирующая метрика
                  _buildSessionStat(
                    isDark,
                    _iconForDominant(dominant.label),
                    dominant.value,
                    dominant.label.toLowerCase(),
                    dominant.color,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _Power.textTertiary(isDark),
                    size: 22,
                  ),
                ],
              ),

              // 🆕 Чипы всех метрик (если их больше одной)
              if (session.totalByMetricCompleted.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(height: 0.5, color: _Power.separator(isDark)),
                const SizedBox(height: 10),
                _sessionMetricBadges(session, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForDominant(String label) {
    switch (label) {
      case 'КМ':
        return Icons.directions_run_rounded;
      case 'РАУНД':
        return Icons.sports_mma_rounded;
      case 'КГ':
        return Icons.monitor_weight_rounded;
      case 'ЧАС':
      case 'МИН':
        return Icons.timer_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  Widget _buildSessionStat(
      bool isDark,
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: _Power.textTertiary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(ProgramSessionStatus status) {
    switch (status) {
      case ProgramSessionStatus.completed:
        return {
          'emoji': '🏆',
          'label': 'ЗАВЕРШЕНА',
          'color': _Power.green,
        };
      case ProgramSessionStatus.abandoned:
        return {
          'emoji': '🚫',
          'label': 'БРОШЕНА',
          'color': _Power.red,
        };
      case ProgramSessionStatus.paused:
        return {
          'emoji': '⏸️',
          'label': 'НА ПАУЗЕ',
          'color': _Power.plasma,
        };
      default:
        return {
          'emoji': '🔥',
          'label': 'АКТИВНА',
          'color': _Power.volt,
        };
    }
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 SESSION DETAILS — мультиметрики вместо одной «Тоннаж»
  // ══════════════════════════════════════════════════════════

  void _showSessionDetails(
      BuildContext context,
      ProgramSession session,
      WorkoutProgram? program,
      ) {
    final isDark = widget.isDark;
    final statusInfo = _getStatusInfo(session.status);
    final accent = statusInfo['color'] as Color;

    var metrics = session.totalByMetricCompleted;
    if (metrics.isEmpty && session.totalVolumeCompleted > 0) {
      metrics = {'kg': session.totalVolumeCompleted};
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: _Power.card(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
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
                const SizedBox(height: 22),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusInfo['label'] as String,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  program?.name ?? 'Удалённая программа',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.1,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatDate(session.startDate)} — ${session.endDate != null ? _formatDate(session.endDate!) : 'сейчас'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _Power.textSecondary(isDark),
                  ),
                ),

                const SizedBox(height: 22),

                // Details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _Power.card2(isDark),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        isDark,
                        Icons.calendar_today_rounded,
                        'Дата начала',
                        _formatDate(session.startDate),
                        _Power.ice,
                      ),
                      _buildDetailDivider(isDark),
                      _buildDetailRow(
                        isDark,
                        Icons.flag_rounded,
                        'Дата конца',
                        session.endDate != null
                            ? _formatDate(session.endDate!)
                            : '—',
                        _Power.ice,
                      ),
                      _buildDetailDivider(isDark),
                      _buildDetailRow(
                        isDark,
                        Icons.timer_rounded,
                        'Длительность',
                        '${session.durationDays} дн.',
                        _Power.plasma,
                      ),
                      _buildDetailDivider(isDark),
                      _buildDetailRow(
                        isDark,
                        Icons.fitness_center_rounded,
                        'Тренировок',
                        '${session.totalWorkoutsCompleted}',
                        _Power.volt,
                      ),
                      _buildDetailDivider(isDark),
                      _buildDetailRow(
                        isDark,
                        Icons.cancel_rounded,
                        'Пропущено',
                        '${session.totalWorkoutsSkipped}',
                        _Power.red,
                      ),
                      _buildDetailDivider(isDark),
                      // 🆕 Мультиметрики вместо одной строки «Тоннаж»
                      if (metrics.isEmpty)
                        _buildDetailRow(
                          isDark,
                          Icons.monitor_weight_rounded,
                          'Объём',
                          '—',
                          _Power.lime,
                        )
                      else
                        ...metrics.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: _buildMetricRow(isDark, e.key, e.value),
                        )),
                      _buildDetailDivider(isDark),
                      _buildDetailRow(
                        isDark,
                        Icons.speed_rounded,
                        'Средний RPE',
                        session.averageRpe > 0
                            ? session.averageRpe.toStringAsFixed(1)
                            : '—',
                        _Power.ice,
                      ),
                      _buildDetailDivider(isDark),
                      _buildDetailRow(
                        isDark,
                        Icons.local_fire_department_rounded,
                        'Макс. серия',
                        '${session.longestStreak} дн.',
                        _Power.volt,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Actions
                if (session.status == ProgramSessionStatus.paused)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                        await context
                            .read<FitnessProvider>()
                            .resumeProgramSession(session.id);
                      },
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
                          Icon(Icons.play_arrow_rounded, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'ВОЗОБНОВИТЬ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (session.status == ProgramSessionStatus.abandoned)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _Power.red.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _Power.red.withOpacity(0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _Power.red.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: _Power.red,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Программа была брошена. Начните новую для продолжения.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _Power.textSecondary(isDark),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 0.5,
        color: _Power.separator(isDark),
      ),
    );
  }

  Widget _buildDetailRow(
      bool isDark,
      IconData icon,
      String label,
      String value,
      Color color,
      ) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Power.textSecondary(isDark),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            color: _Power.textPrimary(isDark),
          ),
        ),
      ],
    );
  }

  /// 🆕 Строка для конкретной метрики (кг / км / раунды / сек / удары / ккал).
  Widget _buildMetricRow(bool isDark, String key, double value) {
    String label;
    String formattedValue;
    IconData icon;
    Color color;

    switch (key) {
      case 'kg':
        label = 'Тоннаж';
        formattedValue = value >= 1000
            ? '${(value / 1000).toStringAsFixed(2)} т'
            : '${value.toStringAsFixed(0)} кг';
        icon = Icons.fitness_center_rounded;
        color = _Power.lime;
        break;
      case 'km':
        label = 'Дистанция';
        formattedValue = '${value.toStringAsFixed(2)} км';
        icon = Icons.directions_run_rounded;
        color = _Power.ice;
        break;
      case 'rounds':
        label = 'Раунды';
        formattedValue = '${value.toStringAsFixed(0)} р.';
        icon = Icons.sports_mma_rounded;
        color = _Power.plasma;
        break;
      case 'sec':
        label = 'Время';
        if (value >= 3600) {
          final h = (value / 3600).floor();
          final m = ((value % 3600) / 60).round();
          formattedValue = '${h}ч ${m}м';
        } else {
          formattedValue = '${(value / 60).toStringAsFixed(0)} мин';
        }
        icon = Icons.timer_rounded;
        color = _Power.ice;
        break;
      case 'punches':
        label = 'Удары';
        formattedValue = '${value.toStringAsFixed(0)}';
        icon = Icons.sports_mma_rounded;
        color = _Power.magma;
        break;
      case 'kcal':
        label = 'Калории';
        formattedValue = '${value.toStringAsFixed(0)} ккал';
        icon = Icons.local_fire_department_rounded;
        color = _Power.magma;
        break;
      default:
        label = key;
        formattedValue = value.toStringAsFixed(0);
        icon = Icons.analytics_rounded;
        color = _Power.volt;
    }

    return _buildDetailRow(isDark, icon, label, formattedValue, color);
  }

  // =====================================================================
  // EMPTY STATE (без изменений)
  // =====================================================================

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _Power.volt.withOpacity(0.10),
              shape: BoxShape.circle,
              boxShadow: _Power.softGlow(_Power.volt, strength: 0.15),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 42,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'ИСТОРИЯ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Пока пусто',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
              color: _Power.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Завершите первую программу — она появится здесь со всеми подробностями',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: _Power.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  String _formatDate(DateTime date) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _plural(int n, String one, String few, String many) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return one;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
    return many;
  }
}