// features/fitness/ui/screens/program_view_screen.dart
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';
import 'workout_execution_screen.dart';
import 'program_builder_screen.dart';
import 'active_program_screen.dart';

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

// ==================== PRESSABLE ====================
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap, this.scale = 0.97, this.haptic = true});
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final bool haptic;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;
  void _set(bool v) { if (_pressed != v) setState(() => _pressed = v); }

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

  // Универсальное превью упражнения (изображение с fallback)
  Widget _buildExThumb(String? url, {required double size, required double radius, required Color accent, required String fallbackEmoji}) {
    final hasImage = url != null && url.isNotEmpty;

    final Widget fallback = Text(fallbackEmoji, style: TextStyle(fontSize: size * 0.50));

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();

    WorkoutProgram program;
    try {
      program = provider.programs.firstWhere((p) => p.id == widget.program.id);
    } catch (_) {
      program = widget.program;
    }

    final sessionForProgram = provider.sessions.where((s) => s.programId == program.id).toList();
    final activeSession = sessionForProgram.where((s) => s.status == ProgramSessionStatus.active).firstOrNull;
    final isProgramActive = activeSession != null;

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(program, provider, isProgramActive),
            if (program.days.isEmpty)
              Expanded(child: _buildEmptyProgram())
            else ...[
              _buildProgramHeader(program, activeSession),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDayView(program, activeSession),
                    _buildOverviewView(program, activeSession),
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
  Widget _buildAppBar(WorkoutProgram program, FitnessProvider provider, bool isProgramActive) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_Sp.lg, _Sp.sm, _Sp.lg, _Sp.xs),
      child: Row(
        children: [
          _Pressable(
            onTap: () => Navigator.pop(context),
            scale: 0.9,
            haptic: false,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _P.divider)),
              child: const Icon(Icons.chevron_left_rounded, color: _P.text, size: 22),
            ),
          ),
          const SizedBox(width: _R.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12, height: 2,
                      decoration: BoxDecoration(color: isProgramActive ? _P.greenDeep : _P.textMuted, borderRadius: BorderRadius.circular(1)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isProgramActive ? 'АКТИВНАЯ ПРОГРАММА' : 'ПРОГРАММА',
                      style: _T.overline.copyWith(color: isProgramActive ? _P.greenDeep : _P.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(program.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _T.title2),
              ],
            ),
          ),
          _Pressable(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: provider,
                  child: ProgramBuilderScreen(existingProgram: program),
                ),
              ));
            },
            scale: 0.9, haptic: false,
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: _P.peachSoft, shape: BoxShape.circle),
              child: const Icon(Icons.edit_rounded, color: _P.peachDeep, size: 17),
            ),
          ),
          const SizedBox(width: 6),
          _Pressable(
            onTap: () => _confirmDelete(program, provider),
            scale: 0.9, haptic: false,
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: _P.redSoft, shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded, color: _P.redDeep, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // PROGRAM HEADER (С ФОНОМ)
  // =====================================================================
  Widget _buildProgramHeader(WorkoutProgram program, ProgramSession? activeSession) {
    final hasBg = program.backgroundImage != null && program.backgroundImage!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(_Sp.lg, _Sp.sm, _Sp.lg, _Sp.sm),
      height: 160,
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(_R.xl),
        border: Border.all(color: _P.divider),
        boxShadow: _P.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 🆕 Фон
          if (hasBg)
            program.backgroundImage!.startsWith('assets/')
                ? Image.asset(program.backgroundImage!, fit: BoxFit.cover)
                : CachedNetworkImage(imageUrl: program.backgroundImage!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container()),

          // 🆕 Градиент для читаемости текста
          if (hasBg)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),

          // Контент
          Padding(
            padding: const EdgeInsets.all(_Sp.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildInfoPill(program.type.displayName, hasBg ? Colors.white : _P.text, hasBg ? Colors.white.withOpacity(0.2) : _P.elevated),
                    const SizedBox(width: 6),
                    _buildInfoPill('${program.days.length} дней', hasBg ? Colors.white : _P.text, hasBg ? Colors.white.withOpacity(0.2) : _P.elevated),
                    const Spacer(),
                    if (activeSession != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: _P.greenDeep, borderRadius: BorderRadius.circular(9)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text('${(activeSession.progressPercent * 100).toInt()}%', style: _T.number.copyWith(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                  ],
                ),
                if (program.description != null && program.description!.isNotEmpty)
                  Text(
                    program.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _T.body.copyWith(color: hasBg ? Colors.white : _P.textMuted, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(9)),
      child: Text(label, style: _T.caption.copyWith(color: textColor, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  // =====================================================================
  // TAB BAR
  // =====================================================================
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_Sp.lg, _Sp.xs, _Sp.lg, _Sp.sm),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: _P.elevated, borderRadius: BorderRadius.circular(_R.md)),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: _P.textMuted,
          indicator: BoxDecoration(color: _P.greenDeep, borderRadius: BorderRadius.circular(_R.sm - 1)),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: _T.caption.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: _T.caption.copyWith(fontWeight: FontWeight.w500),
          tabs: const [Tab(text: 'ДЕНЬ'), Tab(text: 'ОБЗОР')],
        ),
      ),
    );
  }

  // =====================================================================
  // DAY VIEW
  // =====================================================================
  Widget _buildDayView(WorkoutProgram program, ProgramSession? activeSession) {
    if (program.days.isEmpty) return _buildEmptyProgram();
    final day = program.days[_selectedDayIndex.clamp(0, program.days.length - 1)];

    return Column(
      children: [
        _buildDaySelector(program),
        const SizedBox(height: _Sp.sm),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(_Sp.lg, _Sp.xs, _Sp.lg, _Sp.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDayCard(day),
                if (!day.isRestDay && day.exercises.isNotEmpty) ...[
                  const SizedBox(height: _R.xl),
                  Row(
                    children: [
                      Text('Упражнения', style: _T.headline),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _P.elevated, borderRadius: BorderRadius.circular(6)),
                        child: Text('${day.exercises.length}', style: _T.number.copyWith(fontSize: 11, color: _P.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: _Sp.md),
                  ...day.exercises.asMap().entries.map((e) => _buildExerciseCard(e.value, e.key)),
                ],
                if (day.notes != null && day.notes!.isNotEmpty) ...[
                  const SizedBox(height: _Sp.xl),
                  _buildNotesCard(day.notes!),
                ],
              ],
            ),
          ),
        ),
        if (!day.isRestDay && day.exercises.isNotEmpty)
          _buildActionButtons(program, day, activeSession),
      ],
    );
  }

  // =====================================================================
  // DAY SELECTOR
  // =====================================================================
  Widget _buildDaySelector(WorkoutProgram program) {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final today = DateTime.now().weekday - 1;

    return SizedBox(
      height: 68,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _R.md),
        itemCount: program.days.length,
        itemBuilder: (context, index) {
          final day = program.days[index];
          final isSelected = index == _selectedDayIndex;
          final isToday = index == today && program.type == ProgramType.weekly;
          final hasExercises = day.exercises.isNotEmpty;
          final label = program.type == ProgramType.weekly ? dayNames[index % 7] : 'Д${index + 1}';

          return _Pressable(
            onTap: () => setState(() => _selectedDayIndex = index),
            scale: 0.94, haptic: false,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected ? _P.greenSoft : _P.surface,
                borderRadius: BorderRadius.circular(_R.md),
                border: Border.all(color: isSelected ? _P.greenDeep : (isToday ? _P.peachDeep.withOpacity(0.4) : _P.divider), width: isSelected ? 1.2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: _T.number.copyWith(fontSize: 11, color: isSelected ? _P.greenText : _P.text)),
                  const SizedBox(height: _Sp.xs),
                  if (day.isRestDay)
                    Icon(Icons.bedtime_rounded, size: 16, color: isSelected ? _P.greenDeep : _P.textMuted)
                  else
                    Text('${day.exercises.length}', style: _T.number.copyWith(fontSize: 16, color: hasExercises ? (isSelected ? _P.greenDeep : _P.greenDeep) : _P.textMuted)),
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
  Widget _buildDayCard(WorkoutDay day) {
    final isRest = day.isRestDay;
    final accent = isRest ? _P.skyDeep : _P.greenDeep;
    final bg = isRest ? _P.skySoft : _P.greenSoft;
    final icon = isRest ? Icons.bedtime_rounded : Icons.fitness_center_rounded;
    final title = isRest ? 'Отдых' : 'Тренировка';

    return Container(
      padding: const EdgeInsets.all(_Sp.lg),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(_R.xl),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_R.md)),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: _R.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('День ${day.dayNumber}', style: _T.number.copyWith(fontSize: 18)),
                const SizedBox(height: 3),
                Text(title, style: _T.caption.copyWith(color: accent, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (!isRest && day.exercises.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
              child: Text('${day.exercises.length} упр.', style: _T.number.copyWith(fontSize: 11, color: _P.text)),
            ),
        ],
      ),
    );
  }

  // =====================================================================
  // EXERCISE CARD
  // =====================================================================
  Widget _buildExerciseCard(WorkoutExercise exercise, int index) {
    final provider = context.read<FitnessProvider>();
    final exerciseData = provider.exercises.firstWhere((e) => e.id == exercise.exerciseId, orElse: () => Exercise(id: '', name: 'Удалено'));
    final accent = exerciseData.muscleGroups.isNotEmpty ? exerciseData.muscleGroups.first.color : _P.peachDeep;
    final format = FitnessHelpers.resolveFormat(exercise, exerciseData.id.isEmpty ? null : exerciseData);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(_R.md),
      decoration: BoxDecoration(
        color: _P.surface, borderRadius: BorderRadius.circular(_R.lg - 2), border: Border.all(color: _P.divider), boxShadow: _P.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${index + 1}', style: _T.number.copyWith(fontSize: 14, color: _P.textMuted)),
              const SizedBox(width: 12),
              _buildExThumb(exerciseData.imageUrl, size: 36, radius: 10, accent: accent, fallbackEmoji: exerciseData.exerciseType.emoji),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exerciseData.name, style: _T.headline.copyWith(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: _P.elevated, borderRadius: BorderRadius.circular(6)),
                          child: Text('${format.emoji} ${format.shortName}', style: _T.caption.copyWith(fontSize: 10)),
                        ),
                        if (exerciseData.muscleGroups.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(exerciseData.muscleGroups.map((m) => m.displayName).join(' • '), style: _T.caption.copyWith(fontSize: 10)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: _R.md),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: exercise.sets.map((set) {
              final displayText = FitnessHelpers.formatSetForDisplay(set, format);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: set.isWarmup ? _P.peachSoft : _P.elevated,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('П${set.setNumber}', style: _T.number.copyWith(fontSize: 10, color: set.isWarmup ? _P.peachDeep : _P.textMuted)),
                    const SizedBox(width: 6),
                    Text(displayText, style: _T.number.copyWith(fontSize: 12)),
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
  Widget _buildNotesCard(String notes) {
    return Container(
      padding: const EdgeInsets.all(_R.md),
      decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(_R.lg - 2), border: Border.all(color: _P.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_rounded, size: 16, color: _P.peachDeep),
              const SizedBox(width: 8),
              Text('Заметки', style: _T.headline.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Text(notes, style: _T.body.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  // =====================================================================
  // ACTION BUTTONS
  // =====================================================================
  Widget _buildActionButtons(WorkoutProgram program, WorkoutDay day, ProgramSession? activeSession) {
    final provider = context.read<FitnessProvider>();
    final hasActiveSession = provider.activeSession != null;
    final isThisProgramActive = activeSession != null;

    return Container(
      padding: EdgeInsets.fromLTRB(_Sp.lg, _R.md, _Sp.lg, _R.md + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: _P.bg, border: Border(top: BorderSide(color: _P.divider))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isThisProgramActive && activeSession.currentDayIndex == _selectedDayIndex)
            _buildPrimaryButton(label: 'НАЧАТЬ ДЕНЬ', icon: Icons.play_arrow_rounded, color: _P.greenDeep, onTap: () => _startWorkout(day))
          else if (!hasActiveSession && !isThisProgramActive) ...[
            _buildPrimaryButton(label: 'НАЧАТЬ ПРОХОЖДЕНИЕ', icon: Icons.flag_rounded, color: _P.peachDeep, onTap: () => _showStartProgramDialog(program, provider)),
            const SizedBox(height: _Sp.sm),
            _buildSecondaryButton(label: 'ПРОСТО ТРЕНИРОВКА', icon: Icons.play_arrow_rounded, onTap: () => _startWorkout(day)),
          ] else if (hasActiveSession && !isThisProgramActive)
            _buildPrimaryButton(label: 'НАЧАТЬ ТРЕНИРОВКУ', icon: Icons.play_arrow_rounded, color: _P.peachDeep, onTap: () => _startWorkout(day))
          else if (isThisProgramActive)
              _buildPrimaryButton(
                label: 'К ПРОХОЖДЕНИЮ',
                icon: Icons.map_rounded,
                color: _P.skyDeep,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: ActiveProgramScreen(
                          program: program,
                          isDark: false, // <--- ДОБАВЛЕНО ВОТ ЭТО
                        ),
                      ),
                    ),
                  );
                },
                textColor: Colors.white,
              ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required IconData icon, required Color color, required VoidCallback onTap, Color textColor = Colors.white}) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: _Pressable(
        onTap: () { HapticFeedback.mediumImpact(); onTap(); },
        scale: 0.97, haptic: false,
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(_R.md)),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 8),
              Text(label, style: _T.headline.copyWith(color: textColor, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: _Pressable(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        scale: 0.97, haptic: false,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(_R.md), border: Border.all(color: _P.border)),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: _P.textMuted),
              const SizedBox(width: 6),
              Text(label, style: _T.headline.copyWith(color: _P.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // START PROGRAM SHEET
  // =====================================================================
  void _showStartProgramDialog(WorkoutProgram program, FitnessProvider provider) {
    ProgramDifficulty selectedDifficulty = ProgramDifficulty.standard;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(_Sp.xl, _R.md, _Sp.xl, _Sp.xxl),
          decoration: const BoxDecoration(color: _P.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(_R.xxl))),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: _Sp.xl),
                Text('Режим прохождения', style: _T.title2),
                const SizedBox(height: 6),
                Text('Выберите, насколько строго вы будете следовать программе', style: _T.caption),
                const SizedBox(height: _Sp.xl),
                _buildDifficultyOption('🟢', 'Гибкий', 'Можно пропускать без штрафов', selectedDifficulty == ProgramDifficulty.flexible, () => setSheetState(() => selectedDifficulty = ProgramDifficulty.flexible)),
                const SizedBox(height: _Sp.sm),
                _buildDifficultyOption('🟡', 'Стандарт', 'Пропуск сбрасывает серию', selectedDifficulty == ProgramDifficulty.standard, () => setSheetState(() => selectedDifficulty = ProgramDifficulty.standard)),
                const SizedBox(height: _Sp.sm),
                _buildDifficultyOption('🔴', 'Хардкор', 'Пропуск = сброс недели', selectedDifficulty == ProgramDifficulty.hardcore, () => setSheetState(() => selectedDifficulty = ProgramDifficulty.hardcore)),
                const SizedBox(height: _Sp.xl),
                Row(
                  children: [
                    Expanded(child: SizedBox(height: 52, child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(foregroundColor: _P.text, side: const BorderSide(color: _P.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_R.md))), child: const Text('Отмена')))),
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
                              await provider.startProgramSession(program.id, difficulty: selectedDifficulty);
                              if (context.mounted) {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: provider, child: ActiveProgramScreen(program: program, isDark: false))));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: _P.redDeep, behavior: SnackBarBehavior.floating));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: _P.greenDeep, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_R.md))),
                          child: const Text('НАЧАТЬ'),
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

  Widget _buildDifficultyOption(String emoji, String title, String desc, bool isSelected, VoidCallback onTap) {
    return _Pressable(
      onTap: onTap, scale: 0.98, haptic: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(_R.md),
        decoration: BoxDecoration(
          color: isSelected ? _P.greenSoft : _P.bg,
          borderRadius: BorderRadius.circular(_R.md),
          border: Border.all(color: isSelected ? _P.greenDeep : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: _R.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _T.headline.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(desc, style: _T.caption),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: _P.greenDeep, size: 22),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // OVERVIEW VIEW
  // =====================================================================
  Widget _buildOverviewView(WorkoutProgram program, ProgramSession? activeSession) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(_Sp.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: program.type == ProgramType.monthly ? 7 : 4,
              crossAxisSpacing: _Sp.sm,
              mainAxisSpacing: _Sp.sm,
              childAspectRatio: 0.9,
            ),
            itemCount: program.days.length,
            itemBuilder: (context, index) {
              final day = program.days[index];
              final isCurrentDay = activeSession != null && activeSession.currentDayIndex == index;
              return _buildOverviewDayCard(day, index, isCurrentDay);
            },
          ),
          const SizedBox(height: _Sp.xxl),
          _buildOverviewSummary(program),
        ],
      ),
    );
  }

  Widget _buildOverviewDayCard(WorkoutDay day, int index, bool isCurrentDay) {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final today = DateTime.now().weekday - 1;
    final isToday = index == today && widget.program.type == ProgramType.weekly;
    final label = widget.program.type == ProgramType.weekly ? dayNames[index % 7] : '${index + 1}';

    Color accent = isCurrentDay ? _P.greenDeep : (day.isRestDay ? _P.skyDeep : (isToday ? _P.peachDeep : _P.textMuted));
    final hasExercises = day.exercises.isNotEmpty;

    return _Pressable(
      onTap: () { setState(() { _selectedDayIndex = index; _tabController.animateTo(0); }); },
      scale: 0.94, haptic: false,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentDay ? _P.greenSoft : _P.surface,
          borderRadius: BorderRadius.circular(_R.md),
          border: Border.all(color: isCurrentDay ? _P.greenDeep : _P.divider, width: isCurrentDay ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCurrentDay) const Text('🔥', style: TextStyle(fontSize: 10)),
            Text(label, style: _T.number.copyWith(fontSize: 12, color: accent)),
            const SizedBox(height: 6),
            if (day.isRestDay)
              Icon(Icons.bedtime_rounded, size: 18, color: accent)
            else if (!hasExercises)
              Text('—', style: _T.number.copyWith(fontSize: 16, color: _P.textMuted))
            else
              Column(
                children: [
                  Text('${day.exercises.length}', style: _T.number.copyWith(fontSize: 20, color: accent)),
                  const SizedBox(height: 2),
                  Text('УПР', style: _T.overline.copyWith(fontSize: 8)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSummary(WorkoutProgram program) {
    int totalExercises = 0, totalSets = 0, restDays = 0;
    for (final day in program.days) {
      if (day.isRestDay) { restDays++; } else {
        totalExercises += day.exercises.length;
        for (final ex in day.exercises) { totalSets += ex.sets.length; }
      }
    }

    return Container(
      padding: const EdgeInsets.all(_R.lg),
      decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(_R.xl), border: Border.all(color: _P.divider)),
      child: Row(
        children: [
          _buildSummaryItem('📅', '${program.days.length}', 'ДНЕЙ'),
          _summaryDivider(),
          _buildSummaryItem('💪', '$totalExercises', 'УПР'),
          _summaryDivider(),
          _buildSummaryItem('🔄', '$totalSets', 'ПОДХ'),
          _summaryDivider(),
          _buildSummaryItem('😴', '$restDays', 'ОТДЫХ'),
        ],
      ),
    );
  }

  Widget _summaryDivider() => Container(width: 0.5, height: 40, color: _P.divider);

  Widget _buildSummaryItem(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value, style: _T.number.copyWith(fontSize: 20)),
          const SizedBox(height: _Sp.xs),
          Text(label, style: _T.overline.copyWith(fontSize: 8)),
        ],
      ),
    );
  }

  // =====================================================================
  // EMPTY PROGRAM
  // =====================================================================
  Widget _buildEmptyProgram() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96, height: 96,
            decoration: const BoxDecoration(color: _P.elevated, shape: BoxShape.circle),
            child: const Icon(Icons.fitness_center_rounded, size: 42, color: _P.textMuted),
          ),
          const SizedBox(height: _Sp.xl),
          Text('Программа пуста', style: _T.title2),
          const SizedBox(height: 6),
          Text('Добавьте упражнения через редактирование', style: _T.caption),
        ],
      ),
    );
  }

  // =====================================================================
  // ACTIONS
  // =====================================================================
  void _startWorkout(WorkoutDay day) {
    final provider = context.read<FitnessProvider>();
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeNotifierProvider.value(value: provider, child: WorkoutExecutionScreen(day: day))));
  }

  void _confirmDelete(WorkoutProgram program, FitnessProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60),
        child: Container(
          decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(_R.md)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(_Sp.xl, _Sp.xl, _Sp.xl, _Sp.lg),
                child: Column(
                  children: [
                    Text('Удалить программу?', textAlign: TextAlign.center, style: _T.title2.copyWith(fontSize: 18)),
                    const SizedBox(height: 6),
                    Text('«${program.name}» будет удалена безвозвратно', textAlign: TextAlign.center, style: _T.caption),
                  ],
                ),
              ),
              Container(height: 0.5, color: _P.divider),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена', style: _T.headline.copyWith(color: _P.textMuted)))),
                  Container(width: 0.5, height: 50, color: _P.divider),
                  Expanded(child: TextButton(onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await provider.deleteProgram(program.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) Navigator.pop(context);
                  }, child: Text('Удалить', style: _T.headline.copyWith(color: _P.redDeep)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}