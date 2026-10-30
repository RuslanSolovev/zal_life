// features/fitness/ui/screens/program_view_screen.dart
// 🆕 v16: format-aware отображение подходов (сила / кардио / бокс / статика)
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';
import 'workout_execution_screen.dart';
import 'program_builder_screen.dart';
import 'active_program_screen.dart';

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

class ProgramViewScreen extends StatefulWidget {
  final WorkoutProgram program;
  final bool isDark;

  const ProgramViewScreen({
    super.key,
    required this.program,
    this.isDark = false,
  });

  @override
  State<ProgramViewScreen> createState() => _ProgramViewScreenState();
}

class _ProgramViewScreenState extends State<ProgramViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.program.type == ProgramType.weekly) {
      _selectedDayIndex = DateTime.now().weekday - 1;
      if (_selectedDayIndex < 0) _selectedDayIndex = 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = context.watch<FitnessProvider>();

    WorkoutProgram program;
    try {
      program = provider.programs.firstWhere((p) => p.id == widget.program.id);
    } catch (_) {
      program = widget.program;
    }

    final sessionForProgram =
    provider.sessions.where((s) => s.programId == program.id).toList();
    final activeSession = sessionForProgram
        .where((s) => s.status == ProgramSessionStatus.active)
        .firstOrNull;
    final isProgramActive = activeSession != null;

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark, program, provider, isProgramActive),
            if (program.days.isEmpty)
              Expanded(child: _buildEmptyProgram(isDark))
            else ...[
              _buildProgramHeader(isDark, program, activeSession),
              _buildTabBar(isDark),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDayView(isDark, program, activeSession),
                    _buildOverviewView(isDark, program, activeSession),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // APP BAR
  // =====================================================================

  Widget _buildAppBar(
      bool isDark,
      WorkoutProgram program,
      FitnessProvider provider,
      bool isProgramActive,
      ) {
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
                Text(
                  isProgramActive
                      ? '🔥 АКТИВНАЯ ПРОГРАММА'
                      : 'ПРОГРАММА',
                  style: TextStyle(
                    color: isProgramActive
                        ? _Power.volt
                        : _Power.textTertiary(isDark),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  program.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: provider,
                    child: ProgramBuilderScreen(
                      existingProgram: program,
                      isDark: isDark,
                    ),
                  ),
                ),
              );
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
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _confirmDelete(context, isDark, program, provider);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _Power.red.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: _Power.red,
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // PROGRAM HEADER
  // =====================================================================

  Widget _buildProgramHeader(
      bool isDark,
      WorkoutProgram program,
      ProgramSession? activeSession,
      ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
        borderRadius: BorderRadius.circular(20),
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
              _buildInfoPill(
                isDark,
                program.type.displayName.toUpperCase(),
                _Power.volt,
              ),
              const SizedBox(width: 6),
              _buildInfoPill(
                isDark,
                '${program.days.length} ${_getDaysWord(program.days.length).toUpperCase()}',
                _Power.textSecondary(isDark),
              ),
              const Spacer(),
              if (activeSession != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _Power.volt,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow:
                    _Power.softGlow(_Power.volt, strength: 0.4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(activeSession.progressPercent * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: -0.2,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (activeSession != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: activeSession.progressPercent,
                backgroundColor: _Power.separator(isDark),
                valueColor:
                const AlwaysStoppedAnimation(_Power.volt),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'ДЕНЬ ${activeSession.currentDayIndex + 1} ИЗ ${program.days.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: _Power.textSecondary(isDark),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _Power.plasma.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: _Power.plasma,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${activeSession.streak}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          height: 1,
                          color: _Power.plasma,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (program.description != null &&
              program.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              program.description!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: _Power.textSecondary(isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoPill(bool isDark, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          height: 1,
        ),
      ),
    );
  }

  // =====================================================================
  // TAB BAR
  // =====================================================================

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
            letterSpacing: 0.8,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          tabs: const [
            Tab(text: 'ДЕНЬ'),
            Tab(text: 'ОБЗОР'),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // DAY VIEW
  // =====================================================================

  Widget _buildDayView(
      bool isDark,
      WorkoutProgram program,
      ProgramSession? activeSession,
      ) {
    if (program.days.isEmpty) return _buildEmptyProgram(isDark);

    final day = program.days[
    _selectedDayIndex.clamp(0, program.days.length - 1)];

    return Column(
      children: [
        _buildDaySelector(isDark, program),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDayCard(isDark, day),
                if (!day.isRestDay && day.exercises.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Padding(
                    padding:
                    const EdgeInsets.only(left: 4, bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _Power.volt,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: _Power.softGlow(_Power.volt,
                                strength: 0.6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'УПРАЖНЕНИЯ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                            color: _Power.textPrimary(isDark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _Power.volt.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '${day.exercises.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _Power.volt,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...day.exercises.asMap().entries.map((entry) {
                    return _buildExerciseCard(
                        isDark, entry.value, entry.key);
                  }),
                ],
                if (day.notes != null && day.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildNotesCard(isDark, day.notes!),
                ],
              ],
            ),
          ),
        ),
        if (!day.isRestDay && day.exercises.isNotEmpty)
          _buildActionButtons(isDark, program, day, activeSession),
      ],
    );
  }

  // =====================================================================
  // DAY SELECTOR
  // =====================================================================

  Widget _buildDaySelector(bool isDark, WorkoutProgram program) {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final today = DateTime.now().weekday - 1;

    return SizedBox(
      height: 68,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: program.days.length,
        itemBuilder: (context, index) {
          final day = program.days[index];
          final isSelected = index == _selectedDayIndex;
          final isToday =
              index == today && program.type == ProgramType.weekly;
          final hasExercises = day.exercises.isNotEmpty;

          final label = program.type == ProgramType.weekly
              ? dayNames[index % 7]
              : 'Д${index + 1}';

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDayIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected ? _Power.volt : _Power.card(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? _Power.volt
                      : (isToday
                      ? _Power.plasma.withOpacity(0.4)
                      : (hasExercises
                      ? _Power.green.withOpacity(0.3)
                      : _Power.separator(isDark))),
                  width: isSelected ? 0 : 0.8,
                ),
                boxShadow: isSelected
                    ? _Power.softGlow(_Power.volt, strength: 0.4)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      color: isSelected
                          ? Colors.white
                          : _Power.textPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (day.isRestDay)
                    Icon(
                      Icons.bedtime_rounded,
                      size: 16,
                      color: isSelected
                          ? Colors.white70
                          : _Power.textTertiary(isDark),
                    )
                  else
                    Text(
                      '${day.exercises.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1,
                        color: hasExercises
                            ? (isSelected ? Colors.white : _Power.green)
                            : _Power.textTertiary(isDark),
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

  // =====================================================================
  // DAY CARD
  // =====================================================================

  Widget _buildDayCard(bool isDark, WorkoutDay day) {
    final accent = _statusAccent(day.status, isDark);
    final statusIcon = _statusIcon(day.status);
    final statusText = _statusText(day.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.14),
            accent.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 0.8,
        ),
        boxShadow: _Power.softGlow(accent, strength: 0.1),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _Power.softGlow(accent, strength: 0.25),
            ),
            alignment: Alignment.center,
            child: Icon(statusIcon, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'День ${day.dayNumber}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.1,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  day.isRestDay ? 'День отдыха' : statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          if (!day.isRestDay && day.exercises.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _Power.card2(isDark),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${day.exercises.length} УПР.',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  height: 1,
                  color: _Power.textSecondary(isDark),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusAccent(WorkoutDayStatus status, bool isDark) {
    switch (status) {
      case WorkoutDayStatus.completed:
        return _Power.green;
      case WorkoutDayStatus.skipped:
        return _Power.red;
      case WorkoutDayStatus.pending:
        return _Power.volt;
      default:
        return _Power.textTertiary(isDark);
    }
  }

  IconData _statusIcon(WorkoutDayStatus status) {
    switch (status) {
      case WorkoutDayStatus.completed:
        return Icons.check_circle_rounded;
      case WorkoutDayStatus.skipped:
        return Icons.cancel_rounded;
      case WorkoutDayStatus.pending:
        return Icons.flag_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  String _statusText(WorkoutDayStatus status) {
    switch (status) {
      case WorkoutDayStatus.completed:
        return 'ВЫПОЛНЕНО';
      case WorkoutDayStatus.skipped:
        return 'ПРОПУЩЕНО';
      case WorkoutDayStatus.pending:
        return 'ОЖИДАЕТ';
      default:
        return 'НЕ НАЧАТО';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // 🆕 EXERCISE CARD — format-aware чипы подходов
  // ══════════════════════════════════════════════════════════════════

  Widget _buildExerciseCard(
      bool isDark,
      WorkoutExercise exercise,
      int index,
      ) {
    final provider = context.read<FitnessProvider>();
    final exerciseData = provider.exercises.firstWhere(
          (e) => e.id == exercise.exerciseId,
      orElse: () => Exercise(id: '', name: 'Упражнение удалено'),
    );
    final accent = exerciseData.muscleGroups.isNotEmpty
        ? exerciseData.muscleGroups.first.color
        : _Power.volt;

    // 🆕 Резолвим формат с fallback (we.format → ex.defaultFormat → тип)
    final format = FitnessHelpers.resolveFormat(
      exercise,
      exerciseData.id.isEmpty ? null : exerciseData,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
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
                  color: _Power.volt.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _Power.volt,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  exerciseData.exerciseType.emoji,
                  style: const TextStyle(fontSize: 18),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.2,
                        color: _Power.textPrimary(isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // 🆕 Бейдж формата
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
                            '${format.emoji} ${format.shortName}',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              height: 1,
                              color: _Power.ice,
                            ),
                          ),
                        ),
                        if (exerciseData.muscleGroups.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              exerciseData.muscleGroups
                                  .map((m) => m.displayName)
                                  .join(' • '),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _Power.textTertiary(isDark),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: exercise.sets.map((set) {
              // 🆕 Единый формат-зависимый рендер
              final displayText = FitnessHelpers.formatSetForDisplay(
                set,
                format,
              );
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: set.isWarmup
                      ? _Power.volt.withOpacity(0.10)
                      : _Power.card2(isDark),
                  borderRadius: BorderRadius.circular(9),
                  border: set.isWarmup
                      ? Border.all(
                    color: _Power.volt.withOpacity(0.3),
                    width: 0.6,
                  )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'П${set.setNumber}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: set.isWarmup
                            ? _Power.volt
                            : _Power.textTertiary(isDark),
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                    if (set.isWarmup) ...[
                      const SizedBox(width: 4),
                      const Text('🔥', style: TextStyle(fontSize: 10)),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // NOTES CARD
  // =====================================================================

  Widget _buildNotesCard(bool isDark, String notes) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
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
                  color: _Power.plasma.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.notes_rounded,
                  size: 14,
                  color: _Power.plasma,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ЗАМЕТКИ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: _Power.textTertiary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: _Power.textPrimary(isDark).withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // ACTION BUTTONS
  // =====================================================================

  Widget _buildActionButtons(
      bool isDark,
      WorkoutProgram program,
      WorkoutDay day,
      ProgramSession? activeSession,
      ) {
    final provider = context.read<FitnessProvider>();
    final hasActiveSession = provider.activeSession != null;
    final isThisProgramActive = activeSession != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: _Power.bg(isDark),
        border: Border(
          top: BorderSide(color: _Power.separator(isDark), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isThisProgramActive &&
              activeSession.currentDayIndex == _selectedDayIndex)
            _buildPrimaryButton(
              label: 'НАЧАТЬ ДЕНЬ',
              icon: Icons.play_arrow_rounded,
              color: _Power.green,
              onTap: () => _startWorkout(context, day),
            )
          else if (!hasActiveSession && !isThisProgramActive) ...[
            _buildPrimaryButton(
              label: 'НАЧАТЬ ПРОХОЖДЕНИЕ',
              icon: Icons.flag_rounded,
              color: _Power.volt,
              onTap: () =>
                  _showStartProgramDialog(context, isDark, program, provider),
            ),
            const SizedBox(height: 8),
            _buildSecondaryButton(
              label: 'ПРОСТО ТРЕНИРОВКА',
              icon: Icons.play_arrow_rounded,
              onTap: () => _startWorkout(context, day),
            ),
          ] else if (hasActiveSession && !isThisProgramActive)
            _buildPrimaryButton(
              label: 'НАЧАТЬ ТРЕНИРОВКУ',
              icon: Icons.play_arrow_rounded,
              color: _Power.volt,
              onTap: () => _startWorkout(context, day),
            )
          else if (isThisProgramActive)
              _buildPrimaryButton(
                label: 'К ПРОХОЖДЕНИЮ',
                icon: Icons.map_rounded,
                color: _Power.ice,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: ActiveProgramScreen(
                          program: program,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  );
                },
                textColor: Colors.black,
              ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color textColor = Colors.white,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          shadowColor: color.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = widget.isDark;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: _Power.textSecondary(isDark),
          side: BorderSide(color: _Power.separator(isDark)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // START PROGRAM DIALOG
  // =====================================================================

  void _showStartProgramDialog(
      BuildContext context,
      bool isDark,
      WorkoutProgram program,
      FitnessProvider provider,
      ) {
    ProgramDifficulty selectedDifficulty = ProgramDifficulty.standard;

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
                  'НАЧАТЬ ПРОГРАММУ',
                  style: TextStyle(
                    color: _Power.volt,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  program.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    height: 1.1,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${program.days.length} ${_getDaysWord(program.days.length)} · выберите режим',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _Power.textSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDifficultyOption(
                  isDark,
                  '🟢',
                  'Гибкий',
                  'Можно пропускать без штрафов',
                  selectedDifficulty == ProgramDifficulty.flexible,
                      () => setSheetState(() =>
                  selectedDifficulty = ProgramDifficulty.flexible),
                ),
                const SizedBox(height: 8),
                _buildDifficultyOption(
                  isDark,
                  '🟡',
                  'Стандарт',
                  'Пропуск сбрасывает серию',
                  selectedDifficulty == ProgramDifficulty.standard,
                      () => setSheetState(() =>
                  selectedDifficulty = ProgramDifficulty.standard),
                ),
                const SizedBox(height: 8),
                _buildDifficultyOption(
                  isDark,
                  '🔴',
                  'Хардкор',
                  'Пропуск = сброс недели',
                  selectedDifficulty == ProgramDifficulty.hardcore,
                      () => setSheetState(() =>
                  selectedDifficulty = ProgramDifficulty.hardcore),
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
                            foregroundColor:
                            _Power.textSecondary(isDark),
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
                            try {
                              await provider.startProgramSession(
                                program.id,
                                difficulty: selectedDifficulty,
                              );
                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChangeNotifierProvider.value(
                                          value: provider,
                                          child: ActiveProgramScreen(
                                            program: program,
                                            isDark: isDark,
                                          ),
                                        ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: _Power.red,
                                    behavior:
                                    SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(14),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Power.volt,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            shadowColor:
                            _Power.volt.withOpacity(0.5),
                          ),
                          child: const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'НАЧАТЬ',
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
      bool isDark,
      String emoji,
      String title,
      String desc,
      bool isSelected,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? _Power.volt.withOpacity(0.10)
              : _Power.card2(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _Power.volt : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? _Power.softGlow(_Power.volt, strength: 0.25)
              : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: _Power.textPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _Power.textSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: _Power.volt,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // OVERVIEW VIEW
  // =====================================================================

  Widget _buildOverviewView(
      bool isDark,
      WorkoutProgram program,
      ProgramSession? activeSession,
      ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
              program.type == ProgramType.monthly ? 7 : 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemCount: program.days.length,
            itemBuilder: (context, index) {
              final day = program.days[index];
              final isCurrentDay = activeSession != null &&
                  activeSession.currentDayIndex == index;
              return _buildOverviewDayCard(
                  isDark, day, index, isCurrentDay);
            },
          ),
          const SizedBox(height: 24),
          _buildOverviewSummary(isDark, program),
        ],
      ),
    );
  }

  Widget _buildOverviewDayCard(
      bool isDark,
      WorkoutDay day,
      int index,
      bool isCurrentDay,
      ) {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final today = DateTime.now().weekday - 1;
    final isToday =
        index == today && widget.program.type == ProgramType.weekly;
    final label = widget.program.type == ProgramType.weekly
        ? dayNames[index % 7]
        : '${index + 1}';

    Color accent;
    if (isCurrentDay) {
      accent = _Power.volt;
    } else if (day.isRestDay) {
      accent = _Power.ice;
    } else if (day.status == WorkoutDayStatus.completed) {
      accent = _Power.green;
    } else if (day.status == WorkoutDayStatus.skipped) {
      accent = _Power.red;
    } else if (isToday) {
      accent = _Power.plasma;
    } else {
      accent = _Power.textTertiary(isDark);
    }

    final hasExercises = day.exercises.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedDayIndex = index;
          _tabController.animateTo(0);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: accent.withOpacity(isCurrentDay ? 0.14 : 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withOpacity(isCurrentDay ? 0.6 : 0.2),
            width: isCurrentDay ? 1.5 : 0.6,
          ),
          boxShadow: isCurrentDay
              ? _Power.softGlow(_Power.volt, strength: 0.3)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCurrentDay)
              const Text('🔥', style: TextStyle(fontSize: 10)),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrentDay || isToday
                    ? FontWeight.w900
                    : FontWeight.w700,
                letterSpacing: 0.2,
                color: accent == _Power.textTertiary(isDark)
                    ? _Power.textPrimary(isDark)
                    : accent,
              ),
            ),
            const SizedBox(height: 6),
            if (day.isRestDay)
              Icon(Icons.bedtime_rounded, size: 18, color: accent)
            else if (!hasExercises)
              Text(
                '—',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _Power.textTertiary(isDark),
                ),
              )
            else
              Column(
                children: [
                  Text(
                    '${day.exercises.length}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1,
                      color: accent == _Power.textTertiary(isDark)
                          ? _Power.textPrimary(isDark)
                          : accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'УПР',
                    style: TextStyle(
                      fontSize: 8,
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
    );
  }

  Widget _buildOverviewSummary(bool isDark, WorkoutProgram program) {
    int totalExercises = 0, totalSets = 0, restDays = 0;
    for (final day in program.days) {
      if (day.isRestDay) {
        restDays++;
      } else {
        totalExercises += day.exercises.length;
        for (final ex in day.exercises) {
          totalSets += ex.sets.length;
        }
      }
    }

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _Power.volt.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          _buildSummaryItem(isDark, '📅', '${program.days.length}', 'ДНЕЙ'),
          _summaryDivider(isDark),
          _buildSummaryItem(isDark, '💪', '$totalExercises', 'УПР'),
          _summaryDivider(isDark),
          _buildSummaryItem(isDark, '🔄', '$totalSets', 'ПОДХ'),
          _summaryDivider(isDark),
          _buildSummaryItem(isDark, '😴', '$restDays', 'ОТДЫХ'),
        ],
      ),
    );
  }

  Widget _summaryDivider(bool isDark) {
    return Container(
      width: 0.5,
      height: 40,
      color: _Power.separator(isDark),
    );
  }

  Widget _buildSummaryItem(
      bool isDark,
      String emoji,
      String value,
      String label,
      ) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
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
              letterSpacing: 1.2,
              color: _Power.textTertiary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // EMPTY PROGRAM
  // =====================================================================

  Widget _buildEmptyProgram(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
      child: Center(
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
                Icons.fitness_center_rounded,
                size: 40,
                color: _Power.volt,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'ПРОГРАММА',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                color: _Power.volt,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Пока пусто',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
                color: _Power.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте упражнения через редактирование',
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

  // =====================================================================
  // ACTIONS
  // =====================================================================

  void _startWorkout(BuildContext context, WorkoutDay day) {
    final provider = context.read<FitnessProvider>();
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: WorkoutExecutionScreen(
            day: day,
            isDark: widget.isDark,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context,
      bool isDark,
      WorkoutProgram program,
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
                      'Удалить программу?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '«${program.name}» будет удалена безвозвратно',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _Power.textSecondary(isDark),
                        height: 1.4,
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
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
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
                        await provider.deleteProgram(program.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
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

  String _getDaysWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'день';
    if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'дня';
    }
    return 'дней';
  }
}