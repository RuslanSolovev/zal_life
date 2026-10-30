// features/fitness/ui/screens/program_builder_screen.dart
// 🆕 v17.1: format-aware резолвинг для контроллеров (fallback через Exercise.defaultFormat)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';
import '../widgets/muscle_map_widget.dart';

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

// ==================== PROGRAM BUILDER ====================

class ProgramBuilderScreen extends StatefulWidget {
  final WorkoutProgram? existingProgram;
  final bool isDark;
  const ProgramBuilderScreen(
      {super.key, this.existingProgram, this.isDark = false});

  @override
  State<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends State<ProgramBuilderScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _stepController;
  late Animation<double> _stepAnimation;

  ProgramType _programType = ProgramType.weekly;
  List<WorkoutDay> _days = [];
  int _editingDayIndex = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController =
  TextEditingController(text: '60');
  String _selectedEmoji = '💪';
  Color _accentColor = _Power.volt;
  String _difficulty = 'medium';
  String _goal = 'general';

  bool _showManekin = false;
  String? _expandedSection;

  final Map<String, TextEditingController> _repsControllers = {};
  final Map<String, TextEditingController> _weightControllers = {};
  // 🆕 Контроллеры для остальных метрик (key: "d_e_s_metricName")
  final Map<String, TextEditingController> _metricControllers = {};

  final List<String> _steps = ['ОСНОВЫ', 'ДНИ', 'ПОДХОДЫ', 'ИТОГ'];

  @override
  void initState() {
    super.initState();
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _stepAnimation = CurvedAnimation(
      parent: _stepController,
      curve: Curves.easeOutCubic,
    );
    _stepController.forward();

    if (widget.existingProgram != null) {
      _loadExistingProgram();
    } else {
      _initDays(_programType);
    }

    // Первичная инициализация без provider (fallback на we.format)
    _initControllers();

    // 🆕 После первого кадра пересоздаём контроллеры с provider,
    //    чтобы резолвить формат через Exercise.defaultFormat.
    //    Нужно для старых программ, где we.format == null.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<FitnessProvider>();
      setState(() {
        _initControllers(provider);
      });
    });
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 РЕЗОЛВИНГ ФОРМАТА (единый метод)
  // ══════════════════════════════════════════════════════════

  /// Резолвит формат упражнения:
  /// `we.format` → `Exercise.defaultFormat` → `defaultFormatByType[type]`.
  ///
  /// Если `provider` не передан (например, из `initState`),
  /// используется только `we.format ?? setsReps` — fallback.
  /// Post-frame в `initState` гарантирует пересоздание с provider.
  ExerciseFormat _resolveFormat(
      WorkoutExercise we, [FitnessProvider? provider]) {
    if (provider != null) {
      final ex = provider.exercises.firstWhere(
            (e) => e.id == we.exerciseId,
        orElse: () => Exercise(id: '', name: ''),
      );
      return FitnessHelpers.resolveFormat(we, ex.id.isEmpty ? null : ex);
    }
    return we.format ?? ExerciseFormat.setsReps;
  }

  void _loadExistingProgram() {
    final p = widget.existingProgram!;
    _programType = p.type;
    _days = p.days
        .map((d) => WorkoutDay(
      id: d.id,
      programId: d.programId,
      dayNumber: d.dayNumber,
      isRestDay: d.isRestDay,
      notes: d.notes,
      exercises: d.exercises
          .map((e) => WorkoutExercise(
        id: e.id,
        exerciseId: e.exerciseId,
        order: e.order,
        sets: e.sets
            .map((s) => ExerciseSet(
          setNumber: s.setNumber,
          reps: s.reps,
          weight: s.weight,
          isWarmup: s.isWarmup,
          status: s.status,
          rpe: s.rpe,
          restSeconds: s.restSeconds,
          // 🆕 метрики
          duration: s.duration,
          distance: s.distance,
          pace: s.pace,
          heartRate: s.heartRate,
          calories: s.calories,
          incline: s.incline,
          resistance: s.resistance,
          rounds: s.rounds,
          roundDuration: s.roundDuration,
          restBetweenRounds: s.restBetweenRounds,
          punches: s.punches,
          holdSeconds: s.holdSeconds,
          tempo: s.tempo,
          intensity: s.intensity,
        ))
            .toList(),
        groupType: e.groupType,
        restBetweenSeconds: e.restBetweenSeconds,
        format: e.format, // 🆕
      ))
          .toList(),
    ))
        .toList();
    _nameController.text = p.name;
    _descriptionController.text = p.description ?? '';
    _durationController.text =
        (p.sessionDurationMinutes ?? 60).toString();
    _selectedEmoji = p.emoji;
    _accentColor = _nearestPowerColor(p.accentColor);
    _difficulty = p.difficulty;
    _goal = p.goal;
  }

  Color _nearestPowerColor(Color original) {
    final hsv = HSVColor.fromColor(original);
    if (hsv.hue >= 20 && hsv.hue < 45) return _Power.volt;
    if (hsv.hue >= 45 && hsv.hue < 90) return _Power.plasma;
    if (hsv.hue >= 90 && hsv.hue < 170) return _Power.lime;
    if (hsv.hue >= 170 && hsv.hue < 220) return _Power.ice;
    if (hsv.hue >= 220 && hsv.hue < 360) return _Power.magma;
    return _Power.volt;
  }

  @override
  void dispose() {
    _stepController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _disposeControllers();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 КОНТРОЛЛЕРЫ
  // ══════════════════════════════════════════════════════════

  /// Пересоздаёт все `TextEditingController` для подходов.
  /// Если передан `provider` — формат резолвится через `Exercise.defaultFormat`,
  /// иначе используется `we.format ?? setsReps` (fallback).
  void _initControllers([FitnessProvider? provider]) {
    _disposeControllers();
    for (int d = 0; d < _days.length; d++) {
      for (int e = 0; e < _days[d].exercises.length; e++) {
        final we = _days[d].exercises[e];
        final format = _resolveFormat(we, provider);
        for (int s = 0; s < we.sets.length; s++) {
          final key = '${d}_${e}_$s';
          final set = we.sets[s];
          _repsControllers[key] = TextEditingController(
            text: set.reps > 0 ? '${set.reps}' : '',
          );
          _weightControllers[key] = TextEditingController(
            text: set.weight > 0 ? set.weight.toStringAsFixed(1) : '',
          );
          // 🆕 контроллеры для всех числовых метрик формата
          for (final m in format.metrics) {
            if (m == ExerciseMetric.weight) continue;
            if (m == ExerciseMetric.reps) continue;
            if (m == ExerciseMetric.intensity) continue; // слайдер
            if (m == ExerciseMetric.tempo) continue; // текстовое
            final mKey = '${key}_${m.name}';
            final v = FitnessHelpers.metricValue(set, m);
            _metricControllers[mKey] = TextEditingController(
              text: v != null && v != 0
                  ? (m.isDecimal
                  ? v.toStringAsFixed(
                  m == ExerciseMetric.distance ? 2 : 1)
                  : v.toStringAsFixed(0))
                  : '',
            );
          }
        }
      }
    }
  }

  void _disposeControllers() {
    for (final c in _repsControllers.values) {
      c.dispose();
    }
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    for (final c in _metricControllers.values) {
      c.dispose();
    }
    _repsControllers.clear();
    _weightControllers.clear();
    _metricControllers.clear();
  }

  void _initDays(ProgramType type) {
    int count;
    switch (type) {
      case ProgramType.daily:
        count = 1;
        break;
      case ProgramType.weekly:
        count = 7;
        break;
      case ProgramType.monthly:
        count = 30;
        break;
      default:
        count = 7;
    }
    _days = List.generate(
      count,
          (i) => WorkoutDay(
        id: 'temp_${i}_${DateTime.now().millisecondsSinceEpoch}',
        programId: 'new',
        dayNumber: i + 1,
        isRestDay: (type == ProgramType.weekly && (i == 5 || i == 6)),
        exercises: [],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _days.any((d) => !d.isRestDay && d.exercises.isNotEmpty);
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepHeader(isDark),
            Expanded(
              child: FadeTransition(
                opacity: _stepAnimation,
                child: _buildStepContent(isDark),
              ),
            ),
            _buildBottomNavButtons(isDark),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // STEP HEADER
  // =====================================================================

  Widget _buildStepHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: _Power.bg(isDark).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: _Power.separator(isDark), width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (_currentStep > 0) {
                    _stepController.forward(from: 0.0);
                    setState(() => _currentStep--);
                  } else {
                    Navigator.pop(context);
                  }
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
                    _currentStep > 0
                        ? Icons.chevron_left_rounded
                        : Icons.close_rounded,
                    color: _Power.textPrimary(isDark),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.existingProgram != null
                          ? 'РЕДАКТИРОВАТЬ'
                          : 'СОЗДАТЬ ПРОГРАММУ',
                      style: const TextStyle(
                        color: _Power.volt,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _steps[_currentStep],
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
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _Power.volt.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_currentStep + 1}/${_steps.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    height: 1,
                    color: _Power.volt,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_steps.length, (i) {
              final isActive = i == _currentStep;
              final isPast = i < _currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i < _steps.length - 1 ? 6 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive
                          ? _Power.volt
                          : isPast
                          ? _Power.volt.withOpacity(0.5)
                          : _Power.separator(isDark),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: isActive
                          ? _Power.softGlow(_Power.volt, strength: 0.5)
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // BOTTOM NAV
  // =====================================================================

  Widget _buildBottomNavButtons(bool isDark) {
    final canProceed = _canProceed();
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
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _stepController.forward(from: 0.0);
                    setState(() => _currentStep--);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _Power.textSecondary(isDark),
                    side: BorderSide(color: _Power.separator(isDark)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Назад',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 10),
          Expanded(
            flex: _currentStep == 3 ? 1 : 2,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _currentStep == 3
                    ? _saveProgram
                    : canProceed
                    ? () {
                  HapticFeedback.mediumImpact();
                  _stepController.forward(from: 0.0);
                  setState(() => _currentStep++);
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == 3
                      ? _Power.green
                      : (canProceed
                      ? _Power.volt
                      : _Power.textTertiary(isDark)),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  _Power.textTertiary(isDark).withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  shadowColor: (_currentStep == 3
                      ? _Power.green
                      : _Power.volt)
                      .withOpacity(0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentStep == 3)
                      const Icon(Icons.check_rounded, size: 20)
                    else
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _currentStep == 3
                          ? 'СОХРАНИТЬ'
                          : _currentStep == 2
                          ? 'ПРОПУСТИТЬ'
                          : 'ДАЛЕЕ',
                      style: const TextStyle(
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
    );
  }

  // =====================================================================
  // STEP CONTENT
  // =====================================================================

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep0_Basics(isDark);
      case 1:
        return _buildStep1_Days(isDark);
      case 2:
        return _buildStep2_Sets(isDark);
      case 3:
        return _buildStep3_Summary(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // =====================================================================
  // STEP 0: BASICS
  // =====================================================================

  Widget _buildStep0_Basics(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('НАЗВАНИЕ', isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'Например: Силовая 3 дня',
            isDark: isDark,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAccordionIcon(
                  isDark: isDark,
                  iconWidget: Text(_selectedEmoji,
                      style: const TextStyle(fontSize: 22)),
                  label: 'ИКОНКА',
                  accent: _Power.volt,
                  isExpanded: _expandedSection == 'emoji',
                  onTap: () => setState(() => _expandedSection =
                  _expandedSection == 'emoji' ? null : 'emoji'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAccordionIcon(
                  isDark: isDark,
                  iconWidget: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                      boxShadow:
                      _Power.softGlow(_accentColor, strength: 0.5),
                    ),
                  ),
                  label: 'ЦВЕТ',
                  accent: _accentColor,
                  isExpanded: _expandedSection == 'color',
                  onTap: () => setState(() => _expandedSection =
                  _expandedSection == 'color' ? null : 'color'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAccordionIcon(
                  isDark: isDark,
                  iconWidget: Text(_difficultyEmoji,
                      style: const TextStyle(fontSize: 20)),
                  label: 'СЛОЖНОСТЬ',
                  accent: _Power.plasma,
                  isExpanded: _expandedSection == 'difficulty',
                  onTap: () => setState(() => _expandedSection =
                  _expandedSection == 'difficulty' ? null : 'difficulty'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAccordionIcon(
                  isDark: isDark,
                  iconWidget: Text(_goalEmoji,
                      style: const TextStyle(fontSize: 20)),
                  label: 'ЦЕЛЬ',
                  accent: _Power.ice,
                  isExpanded: _expandedSection == 'goal',
                  onTap: () => setState(() => _expandedSection =
                  _expandedSection == 'goal' ? null : 'goal'),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _buildExpandedBasicSection(isDark),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('ТИП ПРОГРАММЫ', isDark),
          const SizedBox(height: 8),
          _buildTypeSelector(isDark),
          const SizedBox(height: 20),
          _buildSectionLabel('ДЛИТЕЛЬНОСТЬ (МИН)', isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _durationController,
            hint: '60',
            isDark: isDark,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('ОПИСАНИЕ', isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _descriptionController,
            hint: 'Опишите программу…',
            isDark: isDark,
            maxLines: 3,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String get _difficultyEmoji {
    switch (_difficulty) {
      case 'easy':
        return '🟢';
      case 'hardcore':
        return '🔴';
      default:
        return '🟡';
    }
  }

  String get _goalEmoji {
    switch (_goal) {
      case 'lose':
        return '🔥';
      case 'gain':
        return '💪';
      case 'strength':
        return '🏋️';
      default:
        return '🎯';
    }
  }

  Widget _buildAccordionIcon({
    required bool isDark,
    required Widget iconWidget,
    required String label,
    required Color accent,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isExpanded ? accent.withOpacity(0.12) : _Power.card2(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded ? accent : _Power.separator(isDark),
            width: isExpanded ? 1.4 : 0.5,
          ),
          boxShadow:
          isExpanded ? _Power.softGlow(accent, strength: 0.25) : null,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(isExpanded ? 0.18 : 0.10),
                shape: BoxShape.circle,
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: isExpanded ? accent : _Power.textTertiary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedBasicSection(bool isDark) {
    if (_expandedSection == null) return const SizedBox.shrink();

    final Widget content;
    switch (_expandedSection) {
      case 'emoji':
        content = _buildEmojiSelector(isDark);
        break;
      case 'color':
        content = _buildColorSelector(isDark);
        break;
      case 'difficulty':
        content = _buildDifficultySelector(isDark);
        break;
      case 'goal':
        content = _buildGoalSelector(isDark);
        break;
      default:
        content = const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Power.card2(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
      ),
      child: content,
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
          color: _Power.textTertiary(isDark),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _Power.textPrimary(isDark),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: _Power.textTertiary(isDark),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _Power.card2(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _Power.separator(isDark),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _Power.volt,
            width: 1.5,
          ),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    final types = [
      {'type': ProgramType.daily, 'emoji': '☀️', 'label': '1 ДЕНЬ'},
      {'type': ProgramType.weekly, 'emoji': '📅', 'label': 'НЕДЕЛЯ'},
      {'type': ProgramType.monthly, 'emoji': '🗓️', 'label': 'МЕСЯЦ'},
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _Power.card2(isDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: types.map((t) {
          final type = t['type'] as ProgramType;
          final isSelected = _programType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _programType = type;
                  _initDays(type);
                  _editingDayIndex = 0;
                  _initControllers(context.read<FitnessProvider>());
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _Power.volt : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? _Power.softGlow(_Power.volt, strength: 0.35)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t['emoji'] as String,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: isSelected
                            ? Colors.white
                            : _Power.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmojiSelector(bool isDark) {
    final emojis = [
      '💪', '🏋️', '🔥', '🏃', '🧘', '🚴', '🥊', '⚡',
      '🏆', '💎', '🎯', '⚔️', '🛡️', '🌀', '🌟', '🌊',
      '🌋', '🪐', '🚀', '💥',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: emojis.map((e) {
        final isSelected = _selectedEmoji == e;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedEmoji = e);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? _Power.volt.withOpacity(0.16)
                  : _Power.card(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _Power.volt : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? _Power.softGlow(_Power.volt, strength: 0.3)
                  : null,
            ),
            child: Center(
              child: Text(e, style: const TextStyle(fontSize: 22)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector(bool isDark) {
    final colors = [
      _Power.volt,
      _Power.green,
      _Power.ice,
      _Power.plasma,
      _Power.magma,
      _Power.lime,
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((c) {
        final isSelected = _accentColor.value == c.value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _accentColor = c);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                color: _Power.textPrimary(isDark),
                width: 2.5,
              )
                  : null,
              boxShadow:
              _Power.softGlow(c, strength: isSelected ? 0.5 : 0.25),
            ),
            child: isSelected
                ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 22,
            )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultySelector(bool isDark) {
    final difficulties = [
      {'value': 'easy', 'emoji': '🟢', 'label': 'ЛЁГКАЯ'},
      {'value': 'medium', 'emoji': '🟡', 'label': 'СРЕДНЯЯ'},
      {'value': 'hardcore', 'emoji': '🔴', 'label': 'ХАРДКОР'},
    ];
    return Row(
      children: difficulties.asMap().entries.map((entry) {
        final d = entry.value;
        final isSelected = _difficulty == d['value'];
        final isLast = entry.key == difficulties.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _difficulty = d['value'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _Power.volt.withOpacity(0.14)
                      : _Power.card(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _Power.volt : Colors.transparent,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? _Power.softGlow(_Power.volt, strength: 0.25)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d['emoji'] as String,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      d['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: isSelected
                            ? _Power.volt
                            : _Power.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalSelector(bool isDark) {
    final goals = [
      {'value': 'lose', 'emoji': '🔥', 'label': 'ПОХУДЕНИЕ'},
      {'value': 'gain', 'emoji': '💪', 'label': 'МАССА'},
      {'value': 'strength', 'emoji': '🏋️', 'label': 'СИЛА'},
      {'value': 'general', 'emoji': '🎯', 'label': 'ОФП'},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: goals.map((g) {
        final isSelected = _goal == g['value'];
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _goal = g['value'] as String);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? _Power.volt.withOpacity(0.14)
                  : _Power.card(isDark),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isSelected ? _Power.volt : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? _Power.softGlow(_Power.volt, strength: 0.25)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(g['emoji'] as String,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  g['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: isSelected
                        ? _Power.volt
                        : _Power.textPrimary(isDark),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // =====================================================================
  // STEP 1: DAYS
  // =====================================================================

  Widget _buildStep1_Days(bool isDark) {
    final provider = context.watch<FitnessProvider>();
    final day = _days[_editingDayIndex];

    return Column(
      children: [
        _buildDaysRow(isDark),
        _buildDayControlBar(isDark, day),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                if (!day.isRestDay) _buildAddExerciseButton(isDark),
                if (!day.isRestDay && day.exercises.isNotEmpty)
                  _buildExercisesList(isDark, day, provider),
                if (day.isRestDay) _buildRestDayMessage(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddExerciseButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _showExerciseList(context);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _Power.volt.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _Power.volt.withOpacity(0.3),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _Power.volt,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _Power.softGlow(_Power.volt, strength: 0.4),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ДОБАВИТЬ УПРАЖНЕНИЯ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: _Power.volt,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _Power.volt, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestDayMessage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _Power.ice.withOpacity(0.10),
              shape: BoxShape.circle,
              boxShadow: _Power.softGlow(_Power.ice, strength: 0.15),
            ),
            child: const Icon(
              Icons.bedtime_rounded,
              size: 40,
              color: _Power.ice,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ДЕНЬ ОТДЫХА',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: _Power.ice,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Восстановление',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: _Power.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Мышцы растут, пока вы отдыхаете',
            style: TextStyle(
              fontSize: 13,
              color: _Power.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysRow(bool isDark) {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final total = _days.where((d) => !d.isRestDay).length;
    final filled =
        _days.where((d) => !d.isRestDay && d.exercises.isNotEmpty).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'ПРОГРЕСС',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: _Power.textTertiary(isDark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total > 0 ? filled / total : 0.0,
                    minHeight: 4,
                    backgroundColor: _Power.separator(isDark),
                    valueColor:
                    const AlwaysStoppedAnimation(_Power.volt),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$filled/$total',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: _Power.volt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                final isSelected = index == _editingDayIndex;
                final hasExercises = day.exercises.isNotEmpty;
                final label = _programType == ProgramType.weekly
                    ? dayNames[index % 7]
                    : 'Д${index + 1}';

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _editingDayIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color:
                      isSelected ? _Power.volt : _Power.card(isDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? _Power.volt
                            : hasExercises
                            ? _Power.green.withOpacity(0.4)
                            : _Power.separator(isDark),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            color: isSelected
                                ? Colors.white
                                : _Power.textPrimary(isDark),
                          ),
                        ),
                        const SizedBox(height: 3),
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
                                  ? (isSelected
                                  ? Colors.white
                                  : _Power.green)
                                  : _Power.textTertiary(isDark),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayControlBar(bool isDark, WorkoutDay day) {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final dayLabel = _programType == ProgramType.weekly
        ? " • ${dayNames[_editingDayIndex % 7]}"
        : "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'День ${day.dayNumber}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: _Power.textPrimary(isDark),
            ),
          ),
          Text(
            dayLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _Power.textTertiary(isDark),
            ),
          ),
          if (!day.isRestDay && day.exercises.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _Power.green.withOpacity(0.14),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '${day.exercises.length} УПР.',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: _Power.green,
                  height: 1,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            'ОТДЫХ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: _Power.textTertiary(isDark),
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: day.isRestDay,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() {
                  _days[_editingDayIndex] = day.copyWith(isRestDay: v);
                });
              },
              activeColor: _Power.volt,
            ),
          ),
          if (!day.isRestDay) ...[
            const SizedBox(width: 4),
            _buildSmallIconButton(
              Icons.search_rounded,
                  () => _showExerciseSearch(context),
              _Power.ice,
              isDark,
            ),
            const SizedBox(width: 6),
            _buildSmallIconButton(
              Icons.list_alt_rounded,
                  () => _showExerciseList(context),
              _Power.volt,
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallIconButton(
      IconData icon,
      VoidCallback onTap,
      Color color,
      bool isDark,
      ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildExercisesList(
      bool isDark,
      WorkoutDay day,
      FitnessProvider provider,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'УПРАЖНЕНИЯ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: _Power.textTertiary(isDark),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${day.exercises.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: _Power.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 108,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final exercises =
                  List<WorkoutExercise>.from(day.exercises);
                  final item = exercises.removeAt(oldIndex);
                  exercises.insert(newIndex, item);
                  for (int i = 0; i < exercises.length; i++) {
                    exercises[i] = exercises[i].copyWith(order: i);
                  }
                  _days[_editingDayIndex] =
                      day.copyWith(exercises: exercises);
                  _initControllers(context.read<FitnessProvider>());
                });
              },
              itemCount: day.exercises.length,
              itemBuilder: (context, index) {
                final we = day.exercises[index];
                final exData = provider.exercises.firstWhere(
                      (e) => e.id == we.exerciseId,
                  orElse: () => Exercise(id: '', name: '???'),
                );
                final muscleColor = exData.muscleGroups.isNotEmpty
                    ? exData.muscleGroups.first.color
                    : _Power.volt;

                return Container(
                  key: ValueKey(we.id),
                  width: 110,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _Power.card(isDark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: muscleColor.withOpacity(0.35),
                      width: 0.8,
                    ),
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
                              color: muscleColor.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              exData.exerciseType.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _removeExerciseFromDay(exData);
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _Power.green.withOpacity(0.16),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: _Power.green,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          exData.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                            height: 1.2,
                            color: _Power.textPrimary(isDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _Power.volt.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${we.sets.length} ПОДХ',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: _Power.volt,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '← ЗАЖМИТЕ ДЛЯ ПЕРЕСТАНОВКИ →',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: _Power.textTertiary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // EXERCISE ACTIONS
  // =====================================================================

  void _showExerciseSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExerciseSearchSheet(
        isDark: widget.isDark,
        onAdd: _addExerciseToDay,
        onRemove: _removeExerciseFromDay,
        addedIds: _days[_editingDayIndex]
            .exercises
            .map((e) => e.exerciseId)
            .toList(),
      ),
    );
  }

  void _showExerciseList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExerciseListSheet(
        isDark: widget.isDark,
        onAdd: _addExerciseToDay,
        onRemove: _removeExerciseFromDay,
        addedIds: _days[_editingDayIndex]
            .exercises
            .map((e) => e.exerciseId)
            .toList(),
      ),
    );
  }

  void _showFilteredExercises(BuildContext context, MuscleGroup muscle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExerciseListSheet(
        isDark: widget.isDark,
        onAdd: _addExerciseToDay,
        onRemove: _removeExerciseFromDay,
        addedIds: _days[_editingDayIndex]
            .exercises
            .map((e) => e.exerciseId)
            .toList(),
        filterMuscle: muscle,
      ),
    );
  }

  /// 🆕 При добавлении упражнения сразу создаём сет с полями
  /// соответствующего формата (duration / rounds / holdSeconds и т.д.)
  void _addExerciseToDay(Exercise exercise) {
    setState(() {
      final day = _days[_editingDayIndex];
      if (day.exercises.any((e) => e.exerciseId == exercise.id)) return;

      final format = exercise.resolveFormat();

      final initialSet = ExerciseSet(
        setNumber: 1,
        reps: format == ExerciseFormat.setsReps ? 10 : 0,
        weight: 0,
        duration: (format == ExerciseFormat.timedSets ||
            format == ExerciseFormat.freeform)
            ? 60
            : null,
        roundDuration: format == ExerciseFormat.rounds ? 180 : null,
        rounds: format == ExerciseFormat.rounds ? 3 : null,
        holdSeconds: format == ExerciseFormat.hold ? 30 : null,
        restSeconds: format.usesRest
            ? FitnessHelpers.getRecommendedRestSeconds(format)
            : null,
      );

      _days[_editingDayIndex] = day.copyWith(
        exercises: [
          ...day.exercises,
          WorkoutExercise(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            exerciseId: exercise.id,
            order: day.exercises.length,
            sets: [initialSet],
            format: format,
          ),
        ],
      );
      _initControllers(context.read<FitnessProvider>());
    });
  }

  void _removeExerciseFromDay(Exercise exercise) {
    setState(() {
      final day = _days[_editingDayIndex];
      _days[_editingDayIndex] = day.copyWith(
        exercises: day.exercises
            .where((e) => e.exerciseId != exercise.id)
            .toList(),
      );
      _initControllers(context.read<FitnessProvider>());
    });
  }

  // =====================================================================
  // STEP 2: SETS
  // =====================================================================

  Widget _buildStep2_Sets(bool isDark) {
    final provider = context.watch<FitnessProvider>();
    final day = _days[_editingDayIndex];

    return Column(
      children: [
        _buildDaysRow(isDark),
        if (day.isRestDay || day.exercises.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: (day.isRestDay ? _Power.ice : _Power.plasma)
                            .withOpacity(0.10),
                        shape: BoxShape.circle,
                        boxShadow: _Power.softGlow(
                          day.isRestDay ? _Power.ice : _Power.plasma,
                          strength: 0.15,
                        ),
                      ),
                      child: Icon(
                        day.isRestDay
                            ? Icons.bedtime_rounded
                            : Icons.warning_amber_rounded,
                        size: 40,
                        color:
                        day.isRestDay ? _Power.ice : _Power.plasma,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      day.isRestDay ? 'ДЕНЬ ОТДЫХА' : 'НЕТ УПРАЖНЕНИЙ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        color: day.isRestDay
                            ? _Power.ice
                            : _Power.plasma,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day.isRestDay
                          ? 'Ничего не нужно'
                          : 'Добавьте упражнения',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                    if (!day.isRestDay) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 220,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _stepController.forward(from: 0.0);
                            setState(() => _currentStep = 1);
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'ВЕРНУТЬСЯ',
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
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              physics: const BouncingScrollPhysics(),
              itemCount: day.exercises.length,
              itemBuilder: (context, exIndex) {
                final we = day.exercises[exIndex];
                final exData = provider.exercises.firstWhere(
                      (e) => e.id == we.exerciseId,
                  orElse: () => Exercise(id: '', name: '???'),
                );
                return _buildExerciseConfigCard(
                    isDark, exIndex, we, exData, provider);
              },
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 КАРТОЧКА УПРАЖНЕНИЯ С СЕЛЕКТОРОМ ФОРМАТА
  // ══════════════════════════════════════════════════════════

  Widget _buildExerciseConfigCard(
      bool isDark,
      int exIndex,
      WorkoutExercise we,
      Exercise exData,
      FitnessProvider provider,
      ) {
    final format = _resolveFormat(we, provider);
    final muscleColor = exData.muscleGroups.isNotEmpty
        ? exData.muscleGroups.first.color
        : _Power.volt;
    final configuredCount =
        we.sets.where((s) => _hasSetConfigured(s, format)).length;
    final availableFormats = exData.exerciseType.availableFormats;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding:
          const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: _Power.volt,
          collapsedIconColor: _Power.textSecondary(isDark),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: muscleColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(11),
              boxShadow: _Power.softGlow(muscleColor, strength: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              exData.exerciseType.emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          title: Text(
            exData.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: _Power.textPrimary(isDark),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _Power.ice.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${format.emoji} ${format.shortName}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      height: 1,
                      color: _Power.ice,
                    ),
                  ),
                ),
                Text(
                  '${we.sets.length} ПОДХ',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: _Power.textTertiary(isDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (configuredCount == we.sets.length
                        ? _Power.green
                        : _Power.plasma)
                        .withOpacity(0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    configuredCount == we.sets.length
                        ? '✓ ГОТОВО'
                        : '$configuredCount/${we.sets.length}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      height: 1,
                      color: configuredCount == we.sets.length
                          ? _Power.green
                          : _Power.plasma,
                    ),
                  ),
                ),
              ],
            ),
          ),
          children: [
            if (availableFormats.length > 1) ...[
              _buildFormatSelector(
                  isDark, exIndex, format, availableFormats),
              const SizedBox(height: 10),
            ],
            _buildPresetsRow(isDark, exIndex, format),
            const SizedBox(height: 10),
            ...we.sets.asMap().entries.map((setEntry) {
              final setIndex = setEntry.key;
              final set = setEntry.value;
              return _buildSetConfigRow(
                isDark,
                exIndex,
                setIndex,
                set,
                format,
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _addSet(exIndex, format);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _Power.volt.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 14, color: _Power.volt),
                          SizedBox(width: 6),
                          Text(
                            'ПОДХОД',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: _Power.volt,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (we.sets.length > 1) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _applyFirstToAll(exIndex);
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _Power.ice.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy_rounded,
                                size: 12, color: _Power.ice),
                            SizedBox(width: 6),
                            Text(
                              'КОПИРОВАТЬ',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: _Power.ice,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 СЕЛЕКТОР ФОРМАТА
  // ══════════════════════════════════════════════════════════

  Widget _buildFormatSelector(
      bool isDark,
      int exIndex,
      ExerciseFormat current,
      List<ExerciseFormat> available,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'ФОРМАТ',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: _Power.textTertiary(isDark),
            ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: available.map((f) {
            final isSelected = f == current;
            return GestureDetector(
              onTap: () {
                if (isSelected) return;
                HapticFeedback.selectionClick();
                _changeFormat(exIndex, f);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _Power.ice.withOpacity(0.16)
                      : _Power.card2(isDark),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isSelected ? _Power.ice : Colors.transparent,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? _Power.softGlow(_Power.ice, strength: 0.25)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f.emoji,
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      f.shortName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: isSelected
                            ? _Power.ice
                            : _Power.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 🆕 Смена формата с подтверждением при наличии данных.
  void _changeFormat(int exIndex, ExerciseFormat newFormat) {
    final isDark = widget.isDark;

    final day = _days[_editingDayIndex];
    final we = day.exercises[exIndex];
    final hasData = _hasAnySetData(we.sets);

    void apply() {
      setState(() {
        final exercises = List<WorkoutExercise>.from(day.exercises);
        final newSet = ExerciseSet(
          setNumber: 1,
          reps: newFormat == ExerciseFormat.setsReps ? 10 : 0,
          weight: 0,
          duration: (newFormat == ExerciseFormat.timedSets ||
              newFormat == ExerciseFormat.freeform)
              ? 60
              : null,
          roundDuration:
          newFormat == ExerciseFormat.rounds ? 180 : null,
          rounds: newFormat == ExerciseFormat.rounds ? 3 : null,
          holdSeconds: newFormat == ExerciseFormat.hold ? 30 : null,
          restSeconds: newFormat.usesRest
              ? FitnessHelpers.getRecommendedRestSeconds(newFormat)
              : null,
        );
        exercises[exIndex] = we.copyWith(
          format: newFormat,
          sets: [newSet],
        );
        _days[_editingDayIndex] = day.copyWith(exercises: exercises);
        _initControllers(context.read<FitnessProvider>());
      });
    }

    if (!hasData) {
      apply();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Power.card(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          'Сменить формат?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _Power.textPrimary(isDark),
          ),
        ),
        content: Text(
          'В упражнении уже есть заполненные подходы. При смене формата они будут сброшены.',
          style: TextStyle(color: _Power.textSecondary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Отмена',
              style: TextStyle(color: _Power.textSecondary(isDark)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              apply();
            },
            child: const Text(
              'Сбросить и сменить',
              style: TextStyle(
                color: _Power.red,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 ПРЕСЕТЫ ПО ФОРМАТУ
  // ══════════════════════════════════════════════════════════

  Widget _buildPresetsRow(
      bool isDark,
      int exIndex,
      ExerciseFormat format,
      ) {
    final presets = _presetsForFormat(format);
    if (presets.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Text(
          'БЫСТРО',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: _Power.textTertiary(isDark),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: presets.map((p) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _applyPreset(exIndex, format, p['id'] as String);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _Power.volt.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: _Power.volt.withOpacity(0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    p['label'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      color: _Power.volt,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _presetsForFormat(ExerciseFormat format) {
    switch (format) {
      case ExerciseFormat.setsReps:
        return const [
          {'id': '3x10', 'label': '3×10'},
          {'id': '4x8', 'label': '4×8'},
          {'id': '5x5', 'label': '5×5'},
        ];
      case ExerciseFormat.timedSets:
        return const [
          {'id': '3x45s', 'label': '3×45с'},
          {'id': '3x60s', 'label': '3×60с'},
          {'id': '3x90s', 'label': '3×90с'},
        ];
      case ExerciseFormat.intervals:
        return const [
          {'id': '8x400m', 'label': '8×400м'},
          {'id': '6x800m', 'label': '6×800м'},
          {'id': '4x1000m', 'label': '4×1км'},
        ];
      case ExerciseFormat.rounds:
        return const [
          {'id': '3x3m', 'label': '3×3м'},
          {'id': '5x2m', 'label': '5×2м'},
          {'id': '3x5m', 'label': '3×5м'},
        ];
      case ExerciseFormat.continuous:
        return const [
          {'id': '5km', 'label': '5 км'},
          {'id': '10km', 'label': '10 км'},
          {'id': '30m', 'label': '30 мин'},
        ];
      case ExerciseFormat.hold:
        return const [
          {'id': '30s', 'label': '30с'},
          {'id': '60s', 'label': '1 мин'},
          {'id': '3m', 'label': '3 мин'},
        ];
      case ExerciseFormat.freeform:
        return const [
          {'id': '10m', 'label': '10 мин'},
          {'id': '20m', 'label': '20 мин'},
          {'id': '30m', 'label': '30 мин'},
        ];
    }
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 SET ROW — разветвление по формату
  // ══════════════════════════════════════════════════════════

  Widget _buildSetConfigRow(
      bool isDark,
      int exIndex,
      int setIndex,
      ExerciseSet set,
      ExerciseFormat format,
      ) {
    final day = _days[_editingDayIndex];
    final we = day.exercises[exIndex];
    final isConfigured = _hasSetConfigured(set, format);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _Power.card2(isDark),
        borderRadius: BorderRadius.circular(12),
        border: set.isWarmup
            ? Border.all(color: _Power.volt.withOpacity(0.4), width: 0.8)
            : isConfigured
            ? Border.all(
            color: _Power.green.withOpacity(0.25), width: 0.5)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: set.isWarmup
                      ? _Power.volt.withOpacity(0.18)
                      : _Power.volt.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  'П${setIndex + 1}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    height: 1,
                    color: set.isWarmup
                        ? _Power.volt
                        : _Power.textPrimary(isDark),
                  ),
                ),
              ),
              if (set.isWarmup) ...[
                const SizedBox(width: 5),
                const Text('🔥', style: TextStyle(fontSize: 10)),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    final d = _days[_editingDayIndex];
                    final exs =
                    List<WorkoutExercise>.from(d.exercises);
                    final sets =
                    List<ExerciseSet>.from(exs[exIndex].sets);
                    sets[setIndex] =
                        sets[setIndex].copyWith(isWarmup: !set.isWarmup);
                    exs[exIndex] = exs[exIndex].copyWith(sets: sets);
                    _days[_editingDayIndex] = d.copyWith(exercises: exs);
                  });
                },
                child: Icon(
                  Icons.whatshot_rounded,
                  size: 14,
                  color: set.isWarmup
                      ? _Power.volt
                      : _Power.textTertiary(isDark),
                ),
              ),
              if (we.sets.length > 1) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _removeSet(exIndex, setIndex);
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: _Power.red,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (format == ExerciseFormat.setsReps)
            _buildLegacySetsRepsRow(isDark, exIndex, setIndex, set)
          else
            _buildUniversalMetricRows(
                isDark, exIndex, setIndex, set, format),
        ],
      ),
    );
  }

  /// 🆕 Старый UI (setsReps): два compact-stepper-а — reps + weight.
  Widget _buildLegacySetsRepsRow(
      bool isDark,
      int exIndex,
      int setIndex,
      ExerciseSet set,
      ) {
    final key = '${_editingDayIndex}_${exIndex}_$setIndex';
    final repsController = _repsControllers[key];
    final weightController = _weightControllers[key];
    return Column(
      children: [
        _buildCompactStepper(
          isDark: isDark,
          label: 'ПОВТ',
          value: set.reps,
          min: 1,
          max: 100,
          step: 1,
          controller: repsController,
          onChanged: (v) {
            _updateSet(exIndex, setIndex, reps: v.toInt());
            if (repsController != null) {
              repsController.text = v > 0 ? '${v.toInt()}' : '';
            }
          },
        ),
        const SizedBox(height: 6),
        _buildCompactStepper(
          isDark: isDark,
          label: 'ВЕС',
          value: set.weight,
          min: 0,
          max: 500,
          step: 2.5,
          isDouble: true,
          controller: weightController,
          onChanged: (v) {
            _updateSet(exIndex, setIndex, weight: v.toDouble());
            if (weightController != null) {
              weightController.text =
              v > 0 ? v.toDouble().toStringAsFixed(1) : '';
            }
          },
        ),
      ],
    );
  }

  /// 🆕 Универсальная генерация полей по format.metrics.
  Widget _buildUniversalMetricRows(
      bool isDark,
      int exIndex,
      int setIndex,
      ExerciseSet set,
      ExerciseFormat format,
      ) {
    return Column(
      children: format.metrics.map((m) {
        // intensity — слайдер
        if (m == ExerciseMetric.intensity) {
          final v = (set.intensity ?? 5).clamp(1, 10).toDouble();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(m.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 52,
                  child: Text(
                    m.shortLabel,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: _Power.textTertiary(isDark),
                    ),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8),
                      activeTrackColor: _Power.volt,
                      inactiveTrackColor: _Power.separator(isDark),
                      thumbColor: _Power.volt,
                      overlayColor: _Power.volt.withOpacity(0.15),
                    ),
                    child: Slider(
                      value: v,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (nv) {
                        _updateSetMetric(exIndex, setIndex, m, nv);
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${v.toInt()}/10',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _Power.volt,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // tempo — пропускаем (это строка, отдельный UI не нужен)
        if (m == ExerciseMetric.tempo) return const SizedBox.shrink();

        // Остальные числовые — compact-stepper
        final mKey =
            '${_editingDayIndex}_${exIndex}_${setIndex}_${m.name}';
        final controller = _metricControllers[mKey];

        final value = FitnessHelpers.metricValue(set, m) ?? 0;
        final step = _stepForMetric(m);
        final max = _maxForMetric(m);

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildCompactStepper(
            isDark: isDark,
            label: m.shortLabel,
            value: value,
            min: 0,
            max: max,
            step: step,
            isDouble: m.isDecimal,
            controller: controller,
            onChanged: (v) {
              _updateSetMetric(exIndex, setIndex, m, v.toDouble());
              if (controller != null) {
                controller.text = v > 0
                    ? (m.isDecimal
                    ? v.toDouble().toStringAsFixed(
                    m == ExerciseMetric.distance ? 2 : 1)
                    : v.toInt().toString())
                    : '';
              }
            },
          ),
        );
      }).toList(),
    );
  }

  double _stepForMetric(ExerciseMetric m) {
    switch (m) {
      case ExerciseMetric.weight:
        return 2.5;
      case ExerciseMetric.distance:
        return 0.1;
      case ExerciseMetric.pace:
        return 0.1;
      case ExerciseMetric.incline:
        return 1;
      case ExerciseMetric.resistance:
        return 1;
      case ExerciseMetric.heartRate:
        return 5;
      case ExerciseMetric.calories:
        return 10;
      case ExerciseMetric.roundDuration:
        return 30;
      case ExerciseMetric.restBetweenRounds:
        return 15;
      case ExerciseMetric.holdSeconds:
        return 15;
      case ExerciseMetric.duration:
        return 15;
      case ExerciseMetric.restSeconds:
        return 15;
      case ExerciseMetric.rpe:
        return 0.5;
      default:
        return 1;
    }
  }

  double _maxForMetric(ExerciseMetric m) {
    switch (m) {
      case ExerciseMetric.weight:
        return 500;
      case ExerciseMetric.reps:
        return 200;
      case ExerciseMetric.distance:
        return 100;
      case ExerciseMetric.pace:
        return 20;
      case ExerciseMetric.heartRate:
        return 220;
      case ExerciseMetric.calories:
        return 5000;
      case ExerciseMetric.incline:
        return 30;
      case ExerciseMetric.resistance:
        return 20;
      case ExerciseMetric.rounds:
        return 50;
      case ExerciseMetric.roundDuration:
        return 900;
      case ExerciseMetric.restBetweenRounds:
        return 300;
      case ExerciseMetric.punches:
        return 5000;
      case ExerciseMetric.holdSeconds:
        return 600;
      case ExerciseMetric.duration:
        return 3600;
      case ExerciseMetric.restSeconds:
        return 600;
      case ExerciseMetric.rpe:
        return 10;
      default:
        return 999;
    }
  }

  // ══════════════════════════════════════════════════════════
  // 🆕 CRUD СЕТОВ
  // ══════════════════════════════════════════════════════════

  void _applyPreset(
      int exIndex, ExerciseFormat format, String presetId) {
    setState(() {
      final day = _days[_editingDayIndex];
      final config = day.exercises[exIndex];
      final oldLength = config.sets.length;

      for (int j = 0; j < oldLength; j++) {
        final key = '${_editingDayIndex}_${exIndex}_$j';
        _repsControllers[key]?.dispose();
        _repsControllers.remove(key);
        _weightControllers[key]?.dispose();
        _weightControllers.remove(key);
        for (final m in ExerciseMetric.values) {
          final mKey = '${key}_${m.name}';
          _metricControllers[mKey]?.dispose();
          _metricControllers.remove(mKey);
        }
      }

      final newSets = _buildPresetSets(format, presetId, config.sets);
      final exercises =
      List<WorkoutExercise>.from(_days[_editingDayIndex].exercises);
      exercises[exIndex] = config.copyWith(sets: newSets);
      _days[_editingDayIndex] =
          _days[_editingDayIndex].copyWith(exercises: exercises);
      _initControllers(context.read<FitnessProvider>());
    });
  }

  List<ExerciseSet> _buildPresetSets(
      ExerciseFormat format,
      String presetId,
      List<ExerciseSet> currentSets,
      ) {
    switch (format) {
      case ExerciseFormat.setsReps:
        final existingWeight =
        currentSets.isNotEmpty ? currentSets.first.weight : 0.0;
        final reps =
        presetId == '3x10' ? 10 : (presetId == '4x8' ? 8 : 5);
        final count =
        presetId == '3x10' ? 3 : (presetId == '4x8' ? 4 : 5);
        return List.generate(count, (i) {
          return ExerciseSet(
            setNumber: i + 1,
            reps: reps,
            weight: existingWeight,
            isWarmup: i == 0,
            restSeconds: i == 0 ? 60 : 90,
          );
        });
      case ExerciseFormat.timedSets:
        final sec = presetId == '3x45s'
            ? 45
            : (presetId == '3x60s' ? 60 : 90);
        return List.generate(3, (i) {
          return ExerciseSet(
            setNumber: i + 1,
            duration: sec,
            intensity: 5,
            restSeconds: 60,
          );
        });
      case ExerciseFormat.intervals:
        final dist = presetId == '8x400m'
            ? 0.4
            : (presetId == '4x1000m' ? 1.0 : 0.8);
        final count = presetId == '8x400m'
            ? 8
            : (presetId == '4x1000m' ? 4 : 6);
        return List.generate(count, (i) {
          return ExerciseSet(
            setNumber: i + 1,
            distance: dist,
            restSeconds: 90,
          );
        });
      case ExerciseFormat.rounds:
        final rd = presetId == '3x3m'
            ? 180
            : (presetId == '5x2m' ? 120 : 300);
        final count = presetId == '3x3m'
            ? 3
            : (presetId == '5x2m' ? 5 : 3);
        return List.generate(count, (i) {
          return ExerciseSet(
            setNumber: i + 1,
            rounds: 1,
            roundDuration: rd,
            restBetweenRounds: 60,
            intensity: 7,
          );
        });
      case ExerciseFormat.continuous:
        return [
          ExerciseSet(
            setNumber: 1,
            distance:
            presetId == '5km' ? 5 : (presetId == '10km' ? 10 : null),
            duration: presetId == '30m' ? 1800 : null,
            restSeconds: 0,
          ),
        ];
      case ExerciseFormat.hold:
        final sec =
        presetId == '30s' ? 30 : (presetId == '60s' ? 60 : 180);
        return [
          ExerciseSet(
            setNumber: 1,
            holdSeconds: sec,
            intensity: 6,
          ),
        ];
      case ExerciseFormat.freeform:
        final sec =
        presetId == '10m' ? 600 : (presetId == '20m' ? 1200 : 1800);
        return [
          ExerciseSet(
            setNumber: 1,
            duration: sec,
            intensity: 5,
          ),
        ];
    }
  }

  void _applyFirstToAll(int exIndex) {
    setState(() {
      final config = _days[_editingDayIndex].exercises[exIndex];
      if (config.sets.isEmpty) return;
      final first = config.sets.first;
      for (int i = 1; i < config.sets.length; i++) {
        config.sets[i] = ExerciseSet(
          setNumber: i + 1,
          reps: first.reps,
          weight: first.weight,
          rpe: first.rpe,
          restSeconds: first.restSeconds,
          isWarmup: false,
          duration: first.duration,
          distance: first.distance,
          pace: first.pace,
          heartRate: first.heartRate,
          calories: first.calories,
          incline: first.incline,
          resistance: first.resistance,
          rounds: first.rounds,
          roundDuration: first.roundDuration,
          restBetweenRounds: first.restBetweenRounds,
          punches: first.punches,
          holdSeconds: first.holdSeconds,
          tempo: first.tempo,
          intensity: first.intensity,
        );
      }
      _initControllers(context.read<FitnessProvider>());
    });
  }

  void _addSet(int exIndex, ExerciseFormat format) {
    setState(() {
      final config = _days[_editingDayIndex].exercises[exIndex];
      final newIndex = config.sets.length;
      final lastSet = config.sets.isNotEmpty ? config.sets.last : null;

      final newSet = ExerciseSet(
        setNumber: newIndex + 1,
        reps: format == ExerciseFormat.setsReps
            ? (lastSet?.reps ?? 10)
            : 0,
        weight: format == ExerciseFormat.setsReps
            ? (lastSet?.weight ?? 0)
            : 0,
        duration: lastSet?.duration ??
            (format == ExerciseFormat.timedSets ||
                format == ExerciseFormat.freeform
                ? 60
                : null),
        distance: lastSet?.distance,
        pace: lastSet?.pace,
        heartRate: lastSet?.heartRate,
        calories: lastSet?.calories,
        incline: lastSet?.incline,
        resistance: lastSet?.resistance,
        rounds: lastSet?.rounds,
        roundDuration: lastSet?.roundDuration,
        restBetweenRounds: lastSet?.restBetweenRounds,
        punches: lastSet?.punches,
        holdSeconds: lastSet?.holdSeconds,
        tempo: lastSet?.tempo,
        intensity: lastSet?.intensity,
        restSeconds: lastSet?.restSeconds,
      );

      config.sets.add(newSet);

      final key = '${_editingDayIndex}_${exIndex}_$newIndex';
      _repsControllers[key] = TextEditingController(
        text: newSet.reps > 0 ? '${newSet.reps}' : '',
      );
      _weightControllers[key] = TextEditingController(
        text: newSet.weight > 0
            ? newSet.weight.toStringAsFixed(1)
            : '',
      );
      for (final m in format.metrics) {
        if (m == ExerciseMetric.weight) continue;
        if (m == ExerciseMetric.reps) continue;
        if (m == ExerciseMetric.intensity) continue;
        if (m == ExerciseMetric.tempo) continue;
        final mKey = '${key}_${m.name}';
        final v = FitnessHelpers.metricValue(newSet, m);
        _metricControllers[mKey] = TextEditingController(
          text: v != null && v != 0
              ? (m.isDecimal
              ? v.toStringAsFixed(
              m == ExerciseMetric.distance ? 2 : 1)
              : v.toStringAsFixed(0))
              : '',
        );
      }
    });
  }

  void _removeSet(int exIndex, int setIndex) {
    setState(() {
      final config = _days[_editingDayIndex].exercises[exIndex];
      if (config.sets.length <= 1) return;
      config.sets.removeAt(setIndex);

      final key = '${_editingDayIndex}_${exIndex}_$setIndex';
      _repsControllers[key]?.dispose();
      _repsControllers.remove(key);
      _weightControllers[key]?.dispose();
      _weightControllers.remove(key);
      for (final m in ExerciseMetric.values) {
        final mKey = '${key}_${m.name}';
        _metricControllers[mKey]?.dispose();
        _metricControllers.remove(mKey);
      }

      // переиндексация
      for (int i = setIndex; i < config.sets.length; i++) {
        final oldKey = '${_editingDayIndex}_${exIndex}_${i + 1}';
        final newKey = '${_editingDayIndex}_${exIndex}_$i';

        if (_repsControllers.containsKey(oldKey)) {
          _repsControllers[newKey] = _repsControllers.remove(oldKey)!;
        }
        if (_weightControllers.containsKey(oldKey)) {
          _weightControllers[newKey] =
          _weightControllers.remove(oldKey)!;
        }
        for (final m in ExerciseMetric.values) {
          final o = '${oldKey}_${m.name}';
          final n = '${newKey}_${m.name}';
          if (_metricControllers.containsKey(o)) {
            _metricControllers[n] = _metricControllers.remove(o)!;
          }
        }
      }
    });
  }

  /// 🆕 Legacy-обновление (только для setsReps: reps/weight).
  void _updateSet(
      int exIndex,
      int setIndex, {
        int? reps,
        double? weight,
      }) {
    setState(() {
      final day = _days[_editingDayIndex];
      final exercises = List<WorkoutExercise>.from(day.exercises);
      final sets = List<ExerciseSet>.from(exercises[exIndex].sets);
      final old = sets[setIndex];
      sets[setIndex] = old.copyWith(
        reps: reps ?? old.reps,
        weight: weight ?? old.weight,
      );
      exercises[exIndex] = exercises[exIndex].copyWith(sets: sets);
      _days[_editingDayIndex] = day.copyWith(exercises: exercises);
    });
  }

  /// 🆕 Универсальное обновление любой метрики.
  void _updateSetMetric(
      int exIndex,
      int setIndex,
      ExerciseMetric metric,
      double value,
      ) {
    setState(() {
      final day = _days[_editingDayIndex];
      final exercises = List<WorkoutExercise>.from(day.exercises);
      final sets = List<ExerciseSet>.from(exercises[exIndex].sets);
      final old = sets[setIndex];

      ExerciseSet updated;
      switch (metric) {
        case ExerciseMetric.reps:
          updated = old.copyWith(reps: value.toInt());
          break;
        case ExerciseMetric.weight:
          updated = old.copyWith(weight: value);
          break;
        case ExerciseMetric.rpe:
          updated = old.copyWith(rpe: value);
          break;
        case ExerciseMetric.restSeconds:
          updated = old.copyWith(restSeconds: value.toInt());
          break;
        case ExerciseMetric.duration:
          updated = old.copyWith(duration: value.toInt());
          break;
        case ExerciseMetric.distance:
          updated = old.copyWith(distance: value);
          break;
        case ExerciseMetric.pace:
          updated = old.copyWith(pace: value);
          break;
        case ExerciseMetric.heartRate:
          updated = old.copyWith(heartRate: value.toInt());
          break;
        case ExerciseMetric.calories:
          updated = old.copyWith(calories: value.toInt());
          break;
        case ExerciseMetric.incline:
          updated = old.copyWith(incline: value);
          break;
        case ExerciseMetric.resistance:
          updated = old.copyWith(resistance: value);
          break;
        case ExerciseMetric.rounds:
          updated = old.copyWith(rounds: value.toInt());
          break;
        case ExerciseMetric.roundDuration:
          updated = old.copyWith(roundDuration: value.toInt());
          break;
        case ExerciseMetric.restBetweenRounds:
          updated = old.copyWith(restBetweenRounds: value.toInt());
          break;
        case ExerciseMetric.punches:
          updated = old.copyWith(punches: value.toInt());
          break;
        case ExerciseMetric.holdSeconds:
          updated = old.copyWith(holdSeconds: value.toInt());
          break;
        case ExerciseMetric.tempo:
          updated = old;
          break;
        case ExerciseMetric.intensity:
          updated = old.copyWith(intensity: value);
          break;
      }

      sets[setIndex] = updated;
      exercises[exIndex] = exercises[exIndex].copyWith(sets: sets);
      _days[_editingDayIndex] = day.copyWith(exercises: exercises);
    });
  }

  /// 🆕 Валидация по формату.
  bool _hasSetConfigured(ExerciseSet s, ExerciseFormat format) {
    switch (format) {
      case ExerciseFormat.setsReps:
        return s.reps > 0 && s.weight > 0;
      case ExerciseFormat.timedSets:
        return (s.duration ?? 0) > 0;
      case ExerciseFormat.intervals:
        return (s.distance ?? 0) > 0 || (s.duration ?? 0) > 0;
      case ExerciseFormat.rounds:
        return (s.rounds ?? 0) > 0 && (s.roundDuration ?? 0) > 0;
      case ExerciseFormat.continuous:
        return (s.distance ?? 0) > 0 || (s.duration ?? 0) > 0;
      case ExerciseFormat.hold:
        return (s.holdSeconds ?? 0) > 0;
      case ExerciseFormat.freeform:
        return (s.duration ?? 0) > 0;
    }
  }

  bool _hasAnySetData(List<ExerciseSet> sets) {
    for (final s in sets) {
      if (s.reps > 0) return true;
      if (s.weight > 0) return true;
      if (s.hasAnyMetricData) return true;
    }
    return false;
  }

  // ══════════════════════════════════════════════════════════
  // COMPACT STEPPER (общий для legacy и universal)
  // ══════════════════════════════════════════════════════════

  Widget _buildCompactStepper({
    required bool isDark,
    required String label,
    required num value,
    required num min,
    required num max,
    required num step,
    required TextEditingController? controller,
    required Function(num) onChanged,
    bool isDouble = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: _Power.textTertiary(isDark),
            ),
          ),
        ),
        _buildCompactButton(
          Icons.remove_rounded,
          value > min
              ? () {
            HapticFeedback.selectionClick();
            final nv = (value - step).clamp(min, max);
            onChanged(nv);
            if (controller != null) {
              controller.text = isDouble
                  ? nv.toDouble().toStringAsFixed(1)
                  : '${nv.toInt()}';
            }
          }
              : null,
          _Power.textSecondary(isDark),
          isDark,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 32,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _Power.textPrimary(isDark),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
              decoration: InputDecoration(
                hintText: isDouble
                    ? value.toDouble().toStringAsFixed(1)
                    : '${value.toInt()}',
                hintStyle: TextStyle(
                  color: _Power.textTertiary(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: _Power.card(isDark),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                isDense: true,
              ),
              onChanged: (v) {
                if (v.isEmpty) {
                  onChanged(0);
                  return;
                }
                final parsed = isDouble
                    ? double.tryParse(v.replaceAll(',', '.'))
                    : int.tryParse(v);
                if (parsed != null) {
                  final clamped = parsed.clamp(min, max);
                  onChanged(clamped);
                  if (controller != null) {
                    final formatted = isDouble
                        ? clamped.toDouble().toStringAsFixed(1)
                        : '${clamped.toInt()}';
                    if (controller.text != formatted) {
                      controller.text = formatted;
                      controller.selection =
                          TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                    }
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 6),
        _buildCompactButton(
          Icons.add_rounded,
          value < max
              ? () {
            HapticFeedback.selectionClick();
            final nv = (value + step).clamp(min, max);
            onChanged(nv);
            if (controller != null) {
              controller.text = isDouble
                  ? nv.toDouble().toStringAsFixed(1)
                  : '${nv.toInt()}';
            }
          }
              : null,
          _Power.volt,
          isDark,
        ),
      ],
    );
  }

  Widget _buildCompactButton(
      IconData icon,
      VoidCallback? onTap,
      Color color,
      bool isDark,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withOpacity(0.14)
              : _Power.textTertiary(isDark).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onTap != null ? color : _Power.textTertiary(isDark),
          size: 14,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STEP 3: SUMMARY
  // ══════════════════════════════════════════════════════════

  Widget _buildStep3_Summary(bool isDark) {
    final totalExercises = _days.fold<int>(
      0,
          (sum, d) => sum + (d.isRestDay ? 0 : d.exercises.length),
    );
    final trainingDays = _days.where((d) => !d.isRestDay).length;
    final restDays = _days.length - trainingDays;
    final totalSets = _days.fold<int>(
      0,
          (sum, d) =>
      sum +
          (d.isRestDay
              ? 0
              : d.exercises.fold<int>(0, (s, e) => s + e.sets.length)),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _accentColor.withOpacity(0.15),
                  _accentColor.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _accentColor.withOpacity(0.3),
                width: 0.8,
              ),
              boxShadow: _Power.softGlow(_accentColor, strength: 0.12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _Power.softGlow(_accentColor,
                            strength: 0.25),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _selectedEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty
                                ? 'Без названия'
                                : _nameController.text,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              height: 1.1,
                              color: _Power.textPrimary(isDark),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _programType.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                              color: _Power.textTertiary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildInfoChip(
                      _difficulty == 'easy'
                          ? '🟢 ЛЁГКАЯ'
                          : _difficulty == 'medium'
                          ? '🟡 СРЕДНЯЯ'
                          : '🔴 ХАРДКОР',
                      isDark,
                    ),
                    _buildInfoChip(
                      _goal == 'lose'
                          ? '🔥 ПОХУДЕНИЕ'
                          : _goal == 'gain'
                          ? '💪 МАССА'
                          : _goal == 'strength'
                          ? '🏋️ СИЛА'
                          : '🎯 ОФП',
                      isDark,
                    ),
                    _buildInfoChip(
                      '⏱ ${_durationController.text} МИН',
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.04 : 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildSummaryItem('📅', '${_days.length}', 'ДНЕЙ'),
                      _summaryDivider(isDark),
                      _buildSummaryItem(
                          '💪', '$totalExercises', 'УПР'),
                      _summaryDivider(isDark),
                      _buildSummaryItem('🔄', '$totalSets', 'ПОДХ'),
                      _summaryDivider(isDark),
                      _buildSummaryItem('😴', '$restDays', 'ОТДЫХ'),
                    ],
                  ),
                ),
                if (_descriptionController.text.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _Power.card2(isDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _descriptionController.text,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: _Power.textSecondary(isDark),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionLabel('ДНИ', isDark),
          const SizedBox(height: 10),
          ..._days.map((day) => _buildDaySummaryRow(isDark, day)),
          if (_days
              .any((d) => !d.isRestDay && d.exercises.isEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _Power.plasma.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _Power.plasma.withOpacity(0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: _Power.plasma,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Есть дни без упражнений. Проверьте перед сохранением.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: _Power.textSecondary(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _Power.card2(isDark),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          height: 1,
          color: _Power.textPrimary(isDark),
        ),
      ),
    );
  }

  Widget _summaryDivider(bool isDark) {
    return Container(
      width: 0.5,
      height: 32,
      color: _Power.separator(isDark),
    );
  }

  Widget _buildSummaryItem(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              height: 1,
              color: _Power.textPrimary(
                  Theme.of(context).brightness == Brightness.dark),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: _Power.textTertiary(
                  Theme.of(context).brightness == Brightness.dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummaryRow(bool isDark, WorkoutDay day) {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final label = _programType == ProgramType.weekly
        ? dayNames[(day.dayNumber - 1) % 7]
        : 'День ${day.dayNumber}';
    final accent = day.isRestDay ? _Power.ice : _Power.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              day.isRestDay
                  ? Icons.bedtime_rounded
                  : Icons.fitness_center_rounded,
              size: 17,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    height: 1.1,
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
                    fontWeight: FontWeight.w600,
                    color: _Power.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          if (!day.isRestDay)
            Text(
              '${day.exercises.fold<int>(0, (sum, e) => sum + e.sets.length)} ПОДХ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: _Power.textTertiary(isDark),
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================================
  // SAVE
  // =====================================================================

  Future<void> _saveProgram() async {
    HapticFeedback.mediumImpact();

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Введите название программы', _Power.plasma);
      return;
    }

    final activeDays = _days.where((d) => !d.isRestDay).toList();
    if (activeDays.isNotEmpty &&
        activeDays.every((d) => d.exercises.isEmpty)) {
      _showSnack('Добавьте хотя бы одно упражнение', _Power.plasma);
      return;
    }

    final provider = context.read<FitnessProvider>();
    final daysData = _days
        .map((d) => {
      'dayNumber': d.dayNumber,
      'isRestDay': d.isRestDay,
      'notes': d.notes,
      'exercises': d.exercises
          .map((e) => WorkoutExercise(
        id: 'ex_${DateTime.now().microsecondsSinceEpoch}_${e.order}',
        exerciseId: e.exerciseId,
        order: e.order,
        sets: e.sets
            .map((s) => ExerciseSet(
          setNumber: s.setNumber,
          reps: s.reps,
          weight: s.weight,
          isWarmup: s.isWarmup,
          status: SetStatus.pending,
          rpe: s.rpe,
          restSeconds: s.restSeconds,
          // 🆕 метрики
          duration: s.duration,
          distance: s.distance,
          pace: s.pace,
          heartRate: s.heartRate,
          calories: s.calories,
          incline: s.incline,
          resistance: s.resistance,
          rounds: s.rounds,
          roundDuration: s.roundDuration,
          restBetweenRounds: s.restBetweenRounds,
          punches: s.punches,
          holdSeconds: s.holdSeconds,
          tempo: s.tempo,
          intensity: s.intensity,
        ))
            .toList(),
        groupType: e.groupType,
        restBetweenSeconds: e.restBetweenSeconds,
        notes: e.notes,
        format: e.format, // 🆕
      ))
          .toList(),
    })
        .toList();

    try {
      if (widget.existingProgram != null) {
        await provider.updateProgram(
          widget.existingProgram!.copyWith(
            name: name,
            type: _programType,
            days: _days,
            description: _descriptionController.text,
            emoji: _selectedEmoji,
            accentColorValue: _accentColor.value,
            difficulty: _difficulty,
            goal: _goal,
            sessionDurationMinutes:
            int.tryParse(_durationController.text) ?? 60,
          ),
        );
      } else {
        await provider.addFullProgram(
          name: name,
          type: _programType,
          daysData: daysData,
          description: _descriptionController.text,
          emoji: _selectedEmoji,
          accentColorValue: _accentColor.value,
          difficulty: _difficulty,
          goal: _goal,
          sessionDurationMinutes:
          int.tryParse(_durationController.text) ?? 60,
        );
      }

      if (mounted) {
        _showSnack('Программа «$name» сохранена', _Power.green,
            success: true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Ошибка: $e', _Power.red);
      }
    }
  }

  void _showSnack(String text, Color color, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (success) ...[
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// =====================================================================
// EXERCISE SEARCH SHEET
// =====================================================================

class _ExerciseSearchSheet extends StatefulWidget {
  final bool isDark;
  final Function(Exercise) onAdd;
  final Function(Exercise) onRemove;
  final List<String> addedIds;
  const _ExerciseSearchSheet({
    required this.isDark,
    required this.onAdd,
    required this.onRemove,
    required this.addedIds,
  });

  @override
  State<_ExerciseSearchSheet> createState() =>
      _ExerciseSearchSheetState();
}

class _ExerciseSearchSheetState extends State<_ExerciseSearchSheet> {
final TextEditingController _searchController = TextEditingController();
String _query = '';
late Set<String> _addedIdsSet;

@override
void initState() {
super.initState();
_addedIdsSet = widget.addedIds.toSet();
}

@override
void didUpdateWidget(covariant _ExerciseSearchSheet oldWidget) {
super.didUpdateWidget(oldWidget);
if (oldWidget.addedIds.length != widget.addedIds.length ||
oldWidget.addedIds.toSet() != widget.addedIds.toSet()) {
_addedIdsSet = widget.addedIds.toSet();
}
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final provider = context.watch<FitnessProvider>();
final exercises = _query.isEmpty
? provider.exercises
: provider.searchExercises(_query);

return Container(
height: MediaQuery.of(context).size.height * 0.75,
decoration: BoxDecoration(
color: _Power.bg(widget.isDark),
borderRadius:
const BorderRadius.vertical(top: Radius.circular(28)),
),
child: Column(
children: [
Container(
width: 36,
height: 5,
margin: const EdgeInsets.only(top: 12),
decoration: BoxDecoration(
color: _Power.textTertiary(widget.isDark),
borderRadius: BorderRadius.circular(3),
),
),
Padding(
padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'БЫСТРЫЙ ПОИСК',
style: TextStyle(
color: _Power.volt,
fontSize: 10,
fontWeight: FontWeight.w900,
letterSpacing: 2.2,
),
),
const SizedBox(height: 4),
Text(
'Поиск упражнений',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.w900,
letterSpacing: -0.7,
color: _Power.textPrimary(widget.isDark),
),
),
],
),
),
Padding(
padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
child: Container(
decoration: BoxDecoration(
color: _Power.card2(widget.isDark),
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: _Power.separator(widget.isDark),
width: 0.5,
),
),
child: TextField(
controller: _searchController,
onChanged: (v) => setState(() => _query = v),
autofocus: true,
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w600,
color: _Power.textPrimary(widget.isDark),
),
decoration: InputDecoration(
hintText: 'Поиск…',
hintStyle: TextStyle(
color: _Power.textTertiary(widget.isDark),
fontSize: 15,
fontWeight: FontWeight.w500,
),
prefixIcon: Icon(
Icons.search_rounded,
color: _Power.textTertiary(widget.isDark),
size: 20,
),
suffixIcon: _query.isNotEmpty
? GestureDetector(
onTap: () {
_searchController.clear();
setState(() => _query = '');
},
child: Container(
margin: const EdgeInsets.all(10),
width: 24,
height: 24,
decoration: BoxDecoration(
color: _Power.textTertiary(widget.isDark)
.withOpacity(0.5),
shape: BoxShape.circle,
),
child: Icon(
Icons.close_rounded,
color:
_Power.textSecondary(widget.isDark),
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
),
Expanded(
child: ListView.builder(
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
itemCount: exercises.length,
itemBuilder: (context, index) {
final ex = exercises[index];
final isAdded = _addedIdsSet.contains(ex.id);
final accent = ex.muscleGroups.isNotEmpty
? ex.muscleGroups.first.color
: _Power.volt;

return GestureDetector(
onTap: () {
HapticFeedback.selectionClick();
setState(() {
if (isAdded) {
_addedIdsSet.remove(ex.id);
widget.onRemove(ex);
} else {
_addedIdsSet.add(ex.id);
widget.onAdd(ex);
}
});
},
child: Container(
margin: const EdgeInsets.only(bottom: 8),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: _Power.card(widget.isDark),
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: isAdded
? _Power.green.withOpacity(0.4)
: _Power.separator(widget.isDark),
width: isAdded ? 1.2 : 0.5,
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
crossAxisAlignment: CrossAxisAlignment.start,
children: [
  Text(
    ex.name,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
      color: _Power.textPrimary(widget.isDark),
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
  if (ex.muscleGroups.isNotEmpty) ...[
    const SizedBox(height: 3),
    Text(
      ex.muscleGroups
          .map((m) => m.displayName)
          .join(' • '),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: _Power.textSecondary(
            widget.isDark),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  ],
],
),
),
  Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: isAdded
          ? _Power.green.withOpacity(0.14)
          : _Power.volt.withOpacity(0.14),
      shape: BoxShape.circle,
    ),
    child: Icon(
      isAdded
          ? Icons.check_rounded
          : Icons.add_rounded,
      color: isAdded
          ? _Power.green
          : _Power.volt,
      size: 18,
    ),
  ),
],
),
),
);
},
),
),
],
),
);
}
}

// =====================================================================
// EXERCISE LIST SHEET
// =====================================================================

class _ExerciseListSheet extends StatefulWidget {
  final bool isDark;
  final Function(Exercise) onAdd;
  final Function(Exercise) onRemove;
  final List<String> addedIds;
  final MuscleGroup? filterMuscle;
  const _ExerciseListSheet({
    required this.isDark,
    required this.onAdd,
    required this.onRemove,
    required this.addedIds,
    this.filterMuscle,
  });

  @override
  State<_ExerciseListSheet> createState() => _ExerciseListSheetState();
}

class _ExerciseListSheetState extends State<_ExerciseListSheet> {
  MuscleGroup? _selectedGroup;
  late Set<String> _addedIdsSet;

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.filterMuscle;
    _addedIdsSet = widget.addedIds.toSet();
  }

  @override
  void didUpdateWidget(covariant _ExerciseListSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.addedIds.length != widget.addedIds.length ||
        oldWidget.addedIds.toSet() != widget.addedIds.toSet()) {
      _addedIdsSet = widget.addedIds.toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    var exercises = provider.exercises.toList();
    if (_selectedGroup != null) {
      exercises = exercises
          .where((e) => e.muscleGroups.contains(_selectedGroup))
          .toList();
    }
    final groups = MuscleGroup.values
        .where((g) => g != MuscleGroup.fullBody)
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: _Power.bg(widget.isDark),
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: _Power.textTertiary(widget.isDark),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'БИБЛИОТЕКА',
                  style: TextStyle(
                    color: _Power.volt,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Упражнения',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    color: _Power.textPrimary(widget.isDark),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: groups.length + 1,
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final group = isAll ? null : groups[index - 1];
                final isSelected = (isAll && _selectedGroup == null) ||
                    (!isAll && _selectedGroup == group);
                final accent =
                isAll ? _Power.volt : (group?.color ?? _Power.volt);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedGroup = group);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                      isSelected ? accent : _Power.card(widget.isDark),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? accent
                            : _Power.separator(widget.isDark),
                        width: 0.8,
                      ),
                      boxShadow: isSelected
                          ? _Power.softGlow(accent, strength: 0.3)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isAll ? '🌐' : group!.emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAll ? 'Все' : group!.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            color: isSelected
                                ? Colors.white
                                : _Power.textPrimary(widget.isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final ex = exercises[index];
                final isAdded = _addedIdsSet.contains(ex.id);
                final accent = ex.muscleGroups.isNotEmpty
                    ? ex.muscleGroups.first.color
                    : _Power.volt;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isAdded) {
                        _addedIdsSet.remove(ex.id);
                        widget.onRemove(ex);
                      } else {
                        _addedIdsSet.add(ex.id);
                        widget.onAdd(ex);
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _Power.card(widget.isDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isAdded
                            ? _Power.green.withOpacity(0.4)
                            : _Power.separator(widget.isDark),
                        width: isAdded ? 1.2 : 0.5,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: _Power.textPrimary(widget.isDark),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (ex.muscleGroups.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  ex.muscleGroups
                                      .map((m) => m.displayName)
                                      .join(' • '),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _Power.textSecondary(
                                        widget.isDark),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isAdded
                                ? _Power.green.withOpacity(0.14)
                                : _Power.volt.withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAdded
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            color: isAdded
                                ? _Power.green
                                : _Power.volt,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}