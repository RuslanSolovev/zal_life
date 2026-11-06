// features/fitness/ui/screens/program_builder_screen.dart
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';
import '../widgets/muscle_map_widget.dart';

// ═══════════════════════════════════════════════════════════════════
//  PREMIUM LIGHT DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF7C818A);
  static const divider = Color(0xFFE9EBEF);
  static const border = Color(0xFFDCE0E5);

  static const greenDeep = Color(0xFF6C9E88);
  static const greenSoft = Color(0xFFEAF2ED);
  static const greenText = Color(0xFF47735F);

  static const peachDeep = Color(0xFFEF9563);
  static const peachSoft = Color(0xFFFCF0E8);

  static const lavenderDeep = Color(0xFF9381BB);
  static const lavenderSoft = Color(0xFFEEEAF5);

  static const skyDeep = Color(0xFF7E9DC6);
  static const skySoft = Color(0xFFEBF0F8);

  static const redDeep = Color(0xFFE7708A);
  static const redSoft = Color(0xFFFCE9EC);
}

class _T {
  static TextStyle title1 = GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: _P.text);
  static TextStyle title2 = GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: _P.text);
  static TextStyle headline = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _P.text);
  static TextStyle body = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: _P.textMuted);
  static TextStyle caption = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
  static TextStyle overline = GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: _P.textMuted);
  static TextStyle number = GoogleFonts.inter(fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]);
}

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
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
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

// ==================== PROGRAM BUILDER ====================

class ProgramBuilderScreen extends StatefulWidget {
  final WorkoutProgram? existingProgram;
  final bool isDark;
  const ProgramBuilderScreen({super.key, this.existingProgram, this.isDark = false});

  @override
  State<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends State<ProgramBuilderScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _stepController;
  late Animation<double> _stepAnimation;

  ProgramType _programType = ProgramType.weekly;
  List<WorkoutDay> _days = [];
  int _editingDayIndex = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '60');
  String _selectedEmoji = '💪';
  Color _accentColor = _P.greenDeep;
  String _difficulty = 'medium';
  String _goal = 'general';

  // НОВОЕ ПОЛЕ ДЛЯ ФОНА
  String? _backgroundImage;
  final ImagePicker _imagePicker = ImagePicker();

  String? _expandedSection;

  final Map<String, TextEditingController> _repsControllers = {};
  final Map<String, TextEditingController> _weightControllers = {};
  final Map<String, TextEditingController> _metricControllers = {};

  final List<String> _steps = ['ОСНОВЫ', 'ДНИ', 'ПОДХОДЫ', 'ИТОГ'];

  // База готовых обоев (наши локальные картинки 1-45)
  final List<String> _presetBackgrounds = List.generate(
    45,
        (i) => 'assets/exercise_presets/${i + 1}.jpg',
  );

  @override
  void initState() {
    super.initState();
    _stepController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _stepAnimation = CurvedAnimation(parent: _stepController, curve: Curves.easeOutCubic);
    _stepController.forward();

    if (widget.existingProgram != null) {
      _loadExistingProgram();
    } else {
      _initDays(_programType);
    }

    _initControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<FitnessProvider>();
      setState(() {
        _initControllers(provider);
      });
    });
  }

  ExerciseFormat _resolveFormat(WorkoutExercise we, [FitnessProvider? provider]) {
    if (provider != null) {
      final ex = provider.exercises.firstWhere((e) => e.id == we.exerciseId, orElse: () => Exercise(id: '', name: ''));
      return FitnessHelpers.resolveFormat(we, ex.id.isEmpty ? null : ex);
    }
    return we.format ?? ExerciseFormat.setsReps;
  }

  void _loadExistingProgram() {
    final p = widget.existingProgram!;
    _programType = p.type;
    _days = p.days.map((d) => WorkoutDay(
      id: d.id,
      programId: d.programId,
      dayNumber: d.dayNumber,
      isRestDay: d.isRestDay,
      notes: d.notes,
      exercises: d.exercises.map((e) => WorkoutExercise(
        id: e.id,
        exerciseId: e.exerciseId,
        order: e.order,
        sets: e.sets.map((s) => ExerciseSet(
          setNumber: s.setNumber, reps: s.reps, weight: s.weight, isWarmup: s.isWarmup, status: s.status,
          rpe: s.rpe, restSeconds: s.restSeconds, duration: s.duration, distance: s.distance, pace: s.pace,
          heartRate: s.heartRate, calories: s.calories, incline: s.incline, resistance: s.resistance,
          rounds: s.rounds, roundDuration: s.roundDuration, restBetweenRounds: s.restBetweenRounds,
          punches: s.punches, holdSeconds: s.holdSeconds, tempo: s.tempo, intensity: s.intensity,
        )).toList(),
        groupType: e.groupType,
        restBetweenSeconds: e.restBetweenSeconds,
        format: e.format,
      )).toList(),
    )).toList();

    _nameController.text = p.name;
    _descriptionController.text = p.description ?? '';
    _durationController.text = (p.sessionDurationMinutes ?? 60).toString();
    _selectedEmoji = p.emoji;
    _accentColor = _nearestColor(p.accentColor);
    _difficulty = p.difficulty;
    _goal = p.goal;
    _backgroundImage = p.backgroundImage;
  }

  Color _nearestColor(Color original) {
    return _P.greenDeep;
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

  void _initControllers([FitnessProvider? provider]) {
    _disposeControllers();
    for (int d = 0; d < _days.length; d++) {
      for (int e = 0; e < _days[d].exercises.length; e++) {
        final we = _days[d].exercises[e];
        final format = _resolveFormat(we, provider);
        for (int s = 0; s < we.sets.length; s++) {
          final key = '${d}_${e}_$s';
          final set = we.sets[s];
          _repsControllers[key] = TextEditingController(text: set.reps > 0 ? '${set.reps}' : '');
          _weightControllers[key] = TextEditingController(text: set.weight > 0 ? set.weight.toStringAsFixed(1) : '');
          for (final m in format.metrics) {
            if (m == ExerciseMetric.weight || m == ExerciseMetric.reps || m == ExerciseMetric.intensity || m == ExerciseMetric.tempo) continue;
            final mKey = '${key}_${m.name}';
            final v = FitnessHelpers.metricValue(set, m);
            _metricControllers[mKey] = TextEditingController(
              text: v != null && v != 0 ? (m.isDecimal ? v.toStringAsFixed(m == ExerciseMetric.distance ? 2 : 1) : v.toStringAsFixed(0)) : '',
            );
          }
        }
      }
    }
  }

  void _disposeControllers() {
    for (final c in _repsControllers.values) { c.dispose(); }
    for (final c in _weightControllers.values) { c.dispose(); }
    for (final c in _metricControllers.values) { c.dispose(); }
    _repsControllers.clear();
    _weightControllers.clear();
    _metricControllers.clear();
  }

  void _initDays(ProgramType type) {
    int count = type == ProgramType.daily ? 1 : (type == ProgramType.weekly ? 7 : 30);
    _days = List.generate(count, (i) => WorkoutDay(
      id: 'temp_${i}_${DateTime.now().millisecondsSinceEpoch}',
      programId: 'new',
      dayNumber: i + 1,
      isRestDay: (type == ProgramType.weekly && (i == 5 || i == 6)),
      exercises: [],
    ));
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: return _nameController.text.trim().isNotEmpty;
      case 1: return _days.any((d) => !d.isRestDay && d.exercises.isNotEmpty);
      case 2: return true;
      case 3: return true;
      default: return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildStepHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _stepAnimation,
                child: _buildStepContent(),
              ),
            ),
            _buildBottomNavButtons(),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // HEADER & NAV
  // =====================================================================

  Widget _buildStepHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_currentStep > 0) {
                    _stepController.forward(from: 0.0);
                    setState(() => _currentStep--);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _P.divider)),
                  child: Icon(_currentStep > 0 ? Icons.chevron_left_rounded : Icons.close_rounded, color: _P.text, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.existingProgram != null ? 'РЕДАКТИРОВАТЬ' : 'СОЗДАТЬ ПРОГРАММУ', style: _T.overline.copyWith(color: _P.textMuted)),
                    const SizedBox(height: 2),
                    Text(_steps[_currentStep], style: _T.title2),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _P.greenSoft, borderRadius: BorderRadius.circular(10)),
                child: Text('${_currentStep + 1}/${_steps.length}', style: _T.number.copyWith(fontSize: 12, color: _P.greenDeep)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(_steps.length, (i) {
              final isActive = i == _currentStep;
              final isPast = i < _currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _steps.length - 1 ? 6 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? _P.greenDeep : (isPast ? _P.greenDeep.withOpacity(0.4) : _P.border),
                      borderRadius: BorderRadius.circular(2),
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

  Widget _buildBottomNavButtons() {
    final canProceed = _canProceed();
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: _P.bg, border: Border(top: BorderSide(color: _P.divider, width: 1))),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    _stepController.forward(from: 0.0);
                    setState(() => _currentStep--);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: _P.text, side: const BorderSide(color: _P.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Назад', style: _T.headline),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentStep == 3 ? 1 : 2,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _currentStep == 3 ? _saveProgram : (canProceed ? () {
                  HapticFeedback.mediumImpact();
                  _stepController.forward(from: 0.0);
                  setState(() => _currentStep++);
                } : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == 3 ? _P.greenDeep : (canProceed ? _P.greenDeep : _P.border),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_currentStep == 3 ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _currentStep == 3 ? 'СОХРАНИТЬ' : (_currentStep == 2 ? 'ПРОПУСТИТЬ' : 'ДАЛЕЕ'),
                      style: _T.headline.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildStep0_Basics();
      case 1: return _buildStep1_Days();
      case 2: return _buildStep2_Sets();
      case 3: return _buildStep3_Summary();
      default: return const SizedBox.shrink();
    }
  }

  // =====================================================================
  // STEP 0: BASICS
  // =====================================================================

  Widget _buildStep0_Basics() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('НАЗВАНИЕ'),
          const SizedBox(height: 8),
          _buildTextField(controller: _nameController, hint: 'Например: Силовая 3 дня', onChanged: (_) => setState(() {})),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildAccordionIcon(icon: Text(_selectedEmoji, style: const TextStyle(fontSize: 22)), label: 'ИКОНКА', isExpanded: _expandedSection == 'emoji', onTap: () => setState(() => _expandedSection = _expandedSection == 'emoji' ? null : 'emoji'))),
              const SizedBox(width: 10),
              Expanded(child: _buildAccordionIcon(icon: Container(width: 22, height: 22, decoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle)), label: 'ЦВЕТ', isExpanded: _expandedSection == 'color', onTap: () => setState(() => _expandedSection = _expandedSection == 'color' ? null : 'color'))),
              const SizedBox(width: 10),
              Expanded(child: _buildAccordionIcon(icon: Text(_difficultyEmoji, style: const TextStyle(fontSize: 20)), label: 'СЛОЖНОСТЬ', isExpanded: _expandedSection == 'difficulty', onTap: () => setState(() => _expandedSection = _expandedSection == 'difficulty' ? null : 'difficulty'))),
              const SizedBox(width: 10),
              Expanded(child: _buildAccordionIcon(icon: Text(_goalEmoji, style: const TextStyle(fontSize: 20)), label: 'ЦЕЛЬ', isExpanded: _expandedSection == 'goal', onTap: () => setState(() => _expandedSection = _expandedSection == 'goal' ? null : 'goal'))),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _buildExpandedBasicSection(),
          ),

          const SizedBox(height: 24),
          _buildSectionLabel('ФОН ПРОГРАММЫ'),
          const SizedBox(height: 8),
          _buildBackgroundPicker(),

          const SizedBox(height: 24),
          _buildSectionLabel('ТИП ПРОГРАММЫ'),
          const SizedBox(height: 8),
          _buildTypeSelector(),

          const SizedBox(height: 24),
          _buildSectionLabel('ДЛИТЕЛЬНОСТЬ (МИН)'),
          const SizedBox(height: 8),
          _buildTextField(controller: _durationController, hint: '60', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], onChanged: (_) => setState(() {})),

          const SizedBox(height: 24),
          _buildSectionLabel('ОПИСАНИЕ'),
          const SizedBox(height: 8),
          _buildTextField(controller: _descriptionController, hint: 'Опишите программу…', maxLines: 3),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBackgroundPicker() {
    final hasImage = _backgroundImage != null && _backgroundImage!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.divider),
      ),
      child: Column(
        children: [
          if (hasImage)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _AppImage(
                  path: _backgroundImage,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fallback: Container(
                    color: _P.bg,
                    height: 120,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: _P.textMuted),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _buildBgButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Галерея',
                  onTap: _pickImageFromGallery,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBgButton(
                  icon: Icons.link_rounded,
                  label: 'Ссылка',
                  onTap: _showUrlDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBgButton(
                  icon: Icons.grid_view_rounded,
                  label: 'База',
                  onTap: _showPresetBackgrounds,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBgButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _P.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _P.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: _P.greenDeep, size: 20),
            const SizedBox(height: 4),
            Text(label, style: _T.caption.copyWith(color: _P.text, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _backgroundImage = image.path);
    }
  }

  void _showUrlDialog() {
    final controller = TextEditingController(text: _backgroundImage?.startsWith('http') == true ? _backgroundImage : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ссылка на фото', style: _T.headline),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                setState(() => _backgroundImage = url);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showPresetBackgrounds() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: _P.border, borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 24),
            Text('Готовые обои', style: _T.title2),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 16 / 9,
                ),
                itemCount: _presetBackgrounds.length,
                itemBuilder: (context, index) {
                  final url = _presetBackgrounds[index];
                  final isSelected = _backgroundImage == url;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _backgroundImage = url);
                      Navigator.pop(ctx);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _AppImage(
                            path: url,
                            fit: BoxFit.cover,
                            fallback: Container(
                              color: _P.bg,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image, color: _P.textMuted),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _P.greenDeep, width: 2.5),
                            ),
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: _P.greenDeep,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                      ],
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

  // --- ОСТАЛЬНЫЕ ВИДЖЕТЫ ---

  String get _difficultyEmoji => _difficulty == 'easy' ? '🟢' : (_difficulty == 'hardcore' ? '🔴' : '🟡');
  String get _goalEmoji => _goal == 'lose' ? '🔥' : (_goal == 'gain' ? '💪' : (_goal == 'strength' ? '🏋️' : '🎯'));

  String get _difficultyLabel {
    switch (_difficulty) {
      case 'easy':
        return 'Лёгкая';
      case 'hardcore':
        return 'Хардкор';
      default:
        return 'Средняя';
    }
  }

  String get _goalLabel {
    switch (_goal) {
      case 'lose':
        return 'Похудение';
      case 'gain':
        return 'Масса';
      case 'strength':
        return 'Сила';
      default:
        return 'ОФП';
    }
  }

  Widget _buildAccordionIcon({required Widget icon, required String label, required bool isExpanded, required VoidCallback onTap}) {
    return _Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isExpanded ? _P.greenSoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isExpanded ? _P.greenDeep : _P.divider, width: isExpanded ? 1.5 : 1),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 8),
            Text(label, style: _T.overline.copyWith(fontSize: 8, color: isExpanded ? _P.greenText : _P.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedBasicSection() {
    if (_expandedSection == null) return const SizedBox.shrink();
    Widget content;
    switch (_expandedSection) {
      case 'emoji': content = _buildEmojiSelector(); break;
      case 'color': content = _buildColorSelector(); break;
      case 'difficulty': content = _buildDifficultySelector(); break;
      case 'goal': content = _buildGoalSelector(); break;
      default: content = const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _P.divider)),
      child: content,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(padding: const EdgeInsets.only(left: 4), child: Text(label, style: _T.overline));
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, int maxLines = 1, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller, maxLines: maxLines, keyboardType: keyboardType, inputFormatters: inputFormatters, onChanged: onChanged,
      style: _T.headline,
      decoration: InputDecoration(
        hintText: hint, hintStyle: _T.caption, filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _P.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _P.greenDeep, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = [{'type': ProgramType.daily, 'label': '1 ДЕНЬ'}, {'type': ProgramType.weekly, 'label': 'НЕДЕЛЯ'}, {'type': ProgramType.monthly, 'label': 'МЕСЯЦ'}];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: _P.divider.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: types.map((t) {
          final type = t['type'] as ProgramType;
          final isSelected = _programType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _programType = type; _initDays(type); _editingDayIndex = 0; _initControllers(context.read<FitnessProvider>()); }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(t['label'] as String, style: _T.caption.copyWith(color: isSelected ? _P.text : _P.textMuted, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmojiSelector() {
    final emojis = ['💪', '🏋️', '🔥', '🏃', '🧘', '🚴', '🥊', '⚡', '🏆', '💎', '🎯', '⚔️', '🛡️', '🌀', '🌟', '🌊', '🌋', '🪐', '🚀', '💥'];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: emojis.map((e) {
        final isSelected = _selectedEmoji == e;
        return GestureDetector(
          onTap: () => setState(() => _selectedEmoji = e),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: isSelected ? _P.greenSoft : _P.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? _P.greenDeep : Colors.transparent, width: 1.5)),
            alignment: Alignment.center,
            child: Text(e, style: const TextStyle(fontSize: 22)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector() {
    final colors = [_P.greenDeep, _P.peachDeep, _P.lavenderDeep, _P.skyDeep, _P.redDeep, const Color(0xFFE0B054)];
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: colors.map((c) {
        final isSelected = _accentColor == c;
        return GestureDetector(
          onTap: () => setState(() => _accentColor = c),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: isSelected ? Border.all(color: _P.text, width: 2) : null),
            child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultySelector() {
    final difficulties = [{'v': 'easy', 'l': 'ЛЁГКАЯ'}, {'v': 'medium', 'l': 'СРЕДНЯЯ'}, {'v': 'hardcore', 'l': 'ХАРДКОР'}];
    return Row(
      children: difficulties.map((d) {
        final isSelected = _difficulty == d['v'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _difficulty = d['v']!),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: isSelected ? _P.greenSoft : _P.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? _P.greenDeep : Colors.transparent)),
                alignment: Alignment.center,
                child: Text(d['l']!, style: _T.caption.copyWith(color: isSelected ? _P.greenText : _P.textMuted, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalSelector() {
    final goals = [{'v': 'lose', 'l': 'ПОХУДЕНИЕ'}, {'v': 'gain', 'l': 'МАССА'}, {'v': 'strength', 'l': 'СИЛА'}, {'v': 'general', 'l': 'ОФП'}];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: goals.map((g) {
        final isSelected = _goal == g['v'];
        return GestureDetector(
          onTap: () => setState(() => _goal = g['v']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: isSelected ? _P.greenSoft : _P.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? _P.greenDeep : Colors.transparent)),
            child: Text(g['l']!, style: _T.caption.copyWith(color: isSelected ? _P.greenText : _P.textMuted, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  // =====================================================================
  // STEP 1: DAYS
  // =====================================================================

  Widget _buildStep1_Days() {
    final provider = context.watch<FitnessProvider>();
    final day = _days[_editingDayIndex];

    return Column(
      children: [
        _buildDaysRow(),
        _buildDayControlBar(day),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                if (!day.isRestDay) _buildAddExerciseButton(),
                if (!day.isRestDay && day.exercises.isNotEmpty) _buildExercisesList(day, provider),
                if (day.isRestDay) _buildRestDayMessage(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddExerciseButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: GestureDetector(
        onTap: () => _showExerciseList(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _P.greenSoft, borderRadius: BorderRadius.circular(20), border: Border.all(color: _P.greenDeep.withOpacity(0.3))),
          child: Row(
            children: [
              Container(width: 40, height: 40, decoration: const BoxDecoration(color: _P.greenDeep, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white)),
              const SizedBox(width: 16),
              Text('ДОБАВИТЬ УПРАЖНЕНИЯ', style: _T.headline.copyWith(color: _P.greenText)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: _P.greenText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestDayMessage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.bedtime_rounded, size: 48, color: _P.skyDeep),
          const SizedBox(height: 16),
          Text('ДЕНЬ ОТДЫХА', style: _T.overline.copyWith(color: _P.skyDeep)),
          const SizedBox(height: 4),
          Text('Восстановление', style: _T.title2),
          const SizedBox(height: 8),
          Text('Мышцы растут, пока вы отдыхаете', style: _T.body),
        ],
      ),
    );
  }

  Widget _buildDaysRow() {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _days.length,
          itemBuilder: (context, index) {
            final day = _days[index];
            final isSelected = index == _editingDayIndex;
            final hasExercises = day.exercises.isNotEmpty;
            final label = _programType == ProgramType.weekly ? dayNames[index % 7] : 'Д${index + 1}';

            return GestureDetector(
              onTap: () => setState(() => _editingDayIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56, margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _P.greenDeep : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? _P.greenDeep : _P.divider),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: _T.caption.copyWith(color: isSelected ? Colors.white : _P.text)),
                    const SizedBox(height: 4),
                    if (day.isRestDay)
                      Icon(Icons.bedtime_rounded, size: 14, color: isSelected ? Colors.white70 : _P.textMuted)
                    else
                      Text('${day.exercises.length}', style: _T.number.copyWith(fontSize: 14, color: hasExercises ? (isSelected ? Colors.white : _P.greenDeep) : _P.textMuted)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayControlBar(WorkoutDay day) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Text('День ${day.dayNumber}', style: _T.headline),
          if (!day.isRestDay && day.exercises.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _P.greenSoft, borderRadius: BorderRadius.circular(8)), child: Text('${day.exercises.length} УПР.', style: _T.overline.copyWith(color: _P.greenText, fontSize: 9))),
          ],
          const Spacer(),
          Text('ОТДЫХ', style: _T.caption),
          Switch(
            value: day.isRestDay,
            onChanged: (v) => setState(() => _days[_editingDayIndex] = day.copyWith(isRestDay: v)),
            activeColor: Colors.white, activeTrackColor: _P.greenDeep, inactiveTrackColor: _P.border,
          ),
          if (!day.isRestDay) ...[
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.search_rounded, size: 20), onPressed: () => _showExerciseSearch(context)),
            IconButton(icon: const Icon(Icons.list_alt_rounded, size: 20), onPressed: () => _showExerciseList(context)),
          ],
        ],
      ),
    );
  }

  Widget _buildExercisesList(WorkoutDay day, FitnessProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 165,
        child: ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final exs = List<WorkoutExercise>.from(day.exercises);
              final item = exs.removeAt(oldIndex);
              exs.insert(newIndex, item);
              for (int i = 0; i < exs.length; i++) {
                exs[i] = exs[i].copyWith(order: i);
              }
              _days[_editingDayIndex] = day.copyWith(exercises: exs);
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
            final hasImage =
                exData.imageUrl != null && exData.imageUrl!.isNotEmpty;

            return Container(
              key: ValueKey(we.id),
              width: 145,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _P.divider),
                boxShadow: [
                  BoxShadow(
                    color: _P.text.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 90,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _AppImage(
                            path: exData.imageUrl,
                            fit: BoxFit.cover,
                            fallback: Container(
                              color: _P.greenSoft,
                              alignment: Alignment.center,
                              child: Text(
                                exData.exerciseType.emoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                          if (hasImage)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.4),
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => _removeExerciseFromDay(exData),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: _P.redDeep,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exData.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _T.caption.copyWith(
                              color: _P.text,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${we.sets.length} ПОДХ',
                            style: _T.overline.copyWith(
                              fontSize: 8,
                              color: _P.greenDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =====================================================================
  // EXERCISE ACTIONS
  // =====================================================================

  void _showExerciseSearch(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => _ExerciseSearchSheet(onAdd: _addExerciseToDay, onRemove: _removeExerciseFromDay, addedIds: _days[_editingDayIndex].exercises.map((e) => e.exerciseId).toList()));
  }

  void _showExerciseList(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => _ExerciseListSheet(onAdd: _addExerciseToDay, onRemove: _removeExerciseFromDay, addedIds: _days[_editingDayIndex].exercises.map((e) => e.exerciseId).toList()));
  }

  void _addExerciseToDay(Exercise exercise) {
    setState(() {
      final day = _days[_editingDayIndex];
      if (day.exercises.any((e) => e.exerciseId == exercise.id)) return;
      final format = exercise.resolveFormat();
      final initialSet = ExerciseSet(setNumber: 1, reps: format == ExerciseFormat.setsReps ? 10 : 0, weight: 0, duration: (format == ExerciseFormat.timedSets || format == ExerciseFormat.freeform) ? 60 : null, roundDuration: format == ExerciseFormat.rounds ? 180 : null, rounds: format == ExerciseFormat.rounds ? 3 : null, holdSeconds: format == ExerciseFormat.hold ? 30 : null, restSeconds: format.usesRest ? FitnessHelpers.getRecommendedRestSeconds(format) : null);
      _days[_editingDayIndex] = day.copyWith(exercises: [...day.exercises, WorkoutExercise(id: 'temp_${DateTime.now().millisecondsSinceEpoch}', exerciseId: exercise.id, order: day.exercises.length, sets: [initialSet], format: format)]);
      _initControllers(context.read<FitnessProvider>());
    });
  }

  void _removeExerciseFromDay(Exercise exercise) {
    setState(() {
      final day = _days[_editingDayIndex];
      _days[_editingDayIndex] = day.copyWith(exercises: day.exercises.where((e) => e.exerciseId != exercise.id).toList());
      _initControllers(context.read<FitnessProvider>());
    });
  }

  // =====================================================================
  // STEP 2: SETS
  // =====================================================================

  Widget _buildStep2_Sets() {
    final provider = context.watch<FitnessProvider>();
    final day = _days[_editingDayIndex];

    return Column(
      children: [
        _buildDaysRow(),
        if (day.isRestDay || day.exercises.isEmpty)
          Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(day.isRestDay ? 'ДЕНЬ ОТДЫХА' : 'НЕТ УПРАЖНЕНИЙ', style: _T.overline), const SizedBox(height: 8), Text(day.isRestDay ? 'Ничего не нужно' : 'Добавьте упражнения', style: _T.title2)])))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              physics: const BouncingScrollPhysics(),
              itemCount: day.exercises.length,
              itemBuilder: (context, exIndex) {
                final we = day.exercises[exIndex];
                final exData = provider.exercises.firstWhere((e) => e.id == we.exerciseId, orElse: () => Exercise(id: '', name: '???'));
                return _buildExerciseConfigCard(exIndex, we, exData, provider);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildExerciseConfigCard(int exIndex, WorkoutExercise we, Exercise exData, FitnessProvider provider) {
    final format = _resolveFormat(we, provider);
    final availableFormats = exData.exerciseType.availableFormats;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _P.divider)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: _ExerciseThumb(exercise: exData, size: 44, radius: 14),
          title: Text(exData.name, style: _T.headline),
          subtitle: Text('${we.sets.length} ПОДХОДОВ · ${format.shortName}', style: _T.caption),
          children: [
            if (availableFormats.length > 1) _buildFormatSelector(exIndex, format, availableFormats),
            _buildPresetsRow(exIndex, format),
            const SizedBox(height: 12),
            ...we.sets.asMap().entries.map((e) => _buildSetConfigRow(exIndex, e.key, e.value, format)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => _addSet(exIndex, format), style: OutlinedButton.styleFrom(foregroundColor: _P.greenDeep, side: const BorderSide(color: _P.greenDeep), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('+ ДОБАВИТЬ ПОДХОД'))),
                if (we.sets.length > 1) ...[
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: () => _applyFirstToAll(exIndex), style: OutlinedButton.styleFrom(foregroundColor: _P.textMuted, side: const BorderSide(color: _P.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('КОПИРОВАТЬ'))),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector(int exIndex, ExerciseFormat current, List<ExerciseFormat> available) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: available.map((f) {
        final isSelected = f == current;
        return GestureDetector(
          onTap: () => _changeFormat(exIndex, f),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: isSelected ? _P.greenSoft : _P.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? _P.greenDeep : Colors.transparent)),
            child: Text(f.shortName, style: _T.caption.copyWith(color: isSelected ? _P.greenText : _P.textMuted, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPresetsRow(int exIndex, ExerciseFormat format) {
    final presets = _presetsForFormat(format);
    if (presets.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: presets.map((p) => GestureDetector(
          onTap: () => _applyPreset(exIndex, format, p['id']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _P.bg, borderRadius: BorderRadius.circular(8)),
            child: Text(p['label']!, style: _T.caption.copyWith(color: _P.text)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSetConfigRow(int exIndex, int setIndex, ExerciseSet set, ExerciseFormat format) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: _P.bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Text('ПОДХОД ${setIndex + 1}', style: _T.overline.copyWith(color: _P.textMuted)),
              const Spacer(),
              if (_days[_editingDayIndex].exercises[exIndex].sets.length > 1)
                GestureDetector(onTap: () => _removeSet(exIndex, setIndex), child: const Icon(Icons.close_rounded, size: 16, color: _P.redDeep)),
            ],
          ),
          const SizedBox(height: 8),
          if (format == ExerciseFormat.setsReps) _buildLegacySetsRepsRow(exIndex, setIndex, set) else _buildUniversalMetricRows(exIndex, setIndex, set, format),
        ],
      ),
    );
  }

  Widget _buildLegacySetsRepsRow(int exIndex, int setIndex, ExerciseSet set) {
    final key = '${_editingDayIndex}_${exIndex}_$setIndex';
    final repsController = _repsControllers[key];
    final weightController = _weightControllers[key];
    return Row(
      children: [
        Expanded(child: _FigmaStepper(label: 'ВЕС', value: set.weight, step: 2.5, isDecimal: true, controller: weightController, onChanged: (v) => _updateSet(exIndex, setIndex, weight: v))),
        const SizedBox(width: 12),
        Expanded(child: _FigmaStepper(label: 'ПОВТ', value: set.reps.toDouble(), step: 1, isDecimal: false, controller: repsController, onChanged: (v) => _updateSet(exIndex, setIndex, reps: v.toInt()))),
      ],
    );
  }

  Widget _buildUniversalMetricRows(int exIndex, int setIndex, ExerciseSet set, ExerciseFormat format) {
    return Column(
      children: format.metrics.map((m) {
        if (m == ExerciseMetric.intensity) {
          final v = (set.intensity ?? 5).clamp(1, 10).toDouble();
          return Row(
            children: [
              Text(m.shortLabel, style: _T.caption),
              Expanded(child: Slider(value: v, min: 1, max: 10, divisions: 9, activeColor: _P.greenDeep, onChanged: (nv) => _updateSetMetric(exIndex, setIndex, m, nv))),
              Text('${v.toInt()}', style: _T.number),
            ],
          );
        }
        if (m == ExerciseMetric.tempo) return const SizedBox.shrink();
        final mKey = '${_editingDayIndex}_${exIndex}_${setIndex}_${m.name}';
        final controller = _metricControllers[mKey];
        final value = FitnessHelpers.metricValue(set, m) ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _FigmaStepper(label: m.shortLabel, value: value, step: _stepForMetric(m), isDecimal: m.isDecimal, controller: controller, onChanged: (v) => _updateSetMetric(exIndex, setIndex, m, v)),
        );
      }).toList(),
    );
  }

  // =====================================================================
  // STEP 3: SUMMARY
  // =====================================================================

  Widget _buildStep3_Summary() {
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryHero(
            totalExercises: totalExercises,
            totalSets: totalSets,
            trainingDays: trainingDays,
            restDays: restDays,
          ),
          const SizedBox(height: 28),
          _buildSectionLabel('ДНИ'),
          const SizedBox(height: 12),
          ..._days.map((day) => _buildDaySummaryRow(day)),
        ],
      ),
    );
  }

  Widget _buildSummaryHero({
    required int totalExercises,
    required int totalSets,
    required int trainingDays,
    required int restDays,
  }) {
    final hasCover = _backgroundImage != null && _backgroundImage!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(hasCover ? 0.10 : 0.18),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            if (hasCover)
              Positioned.fill(
                child: _AppImage(
                  path: _backgroundImage,
                  fit: BoxFit.cover,
                  fallback: Container(color: _P.greenSoft),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: hasCover
                        ? [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.55),
                      Colors.black.withOpacity(0.88),
                    ]
                        : [
                      _accentColor.withOpacity(0.06),
                      _accentColor.withOpacity(0.14),
                      Colors.white.withOpacity(0.6),
                    ],
                    stops: const [0.0, 0.55, 1.0],
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: hasCover
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _selectedEmoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _programType.displayName.toUpperCase(),
                              style: _T.overline.copyWith(
                                color: hasCover
                                    ? Colors.white.withOpacity(0.75)
                                    : _P.greenText,
                                fontSize: 9,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _nameController.text.isEmpty
                                  ? 'Без названия'
                                  : _nameController.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _T.title1.copyWith(
                                fontSize: 24,
                                color: hasCover ? Colors.white : _P.text,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildHeroChip('$_difficultyEmoji $_difficultyLabel', hasCover),
                      _buildHeroChip('$_goalEmoji $_goalLabel', hasCover),
                      _buildHeroChip('⏱ ${_durationController.text} мин', hasCover),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: hasCover
                          ? Colors.white.withOpacity(0.14)
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(18),
                      border: hasCover
                          ? Border.all(color: Colors.white.withOpacity(0.15))
                          : null,
                    ),
                    child: Row(
                      children: [
                        _buildHeroStat('${_days.length}', 'ДНЕЙ', hasCover),
                        _buildHeroDivider(hasCover),
                        _buildHeroStat('$totalExercises', 'УПР', hasCover),
                        _buildHeroDivider(hasCover),
                        _buildHeroStat('$totalSets', 'ПОДХ', hasCover),
                        _buildHeroDivider(hasCover),
                        _buildHeroStat('$restDays', 'ОТДЫХ', hasCover),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroChip(String label, bool onDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withOpacity(0.16) : Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
        border: onDark ? Border.all(color: Colors.white.withOpacity(0.12)) : null,
      ),
      child: Text(
        label,
        style: _T.overline.copyWith(
          color: onDark ? Colors.white : _P.greenText,
          fontSize: 9,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildHeroStat(String value, String label, bool onDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: _T.number.copyWith(
              fontSize: 22,
              color: onDark ? Colors.white : _P.text,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: _T.overline.copyWith(
              fontSize: 8,
              color: onDark ? Colors.white.withOpacity(0.6) : _P.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroDivider(bool onDark) {
    return Container(
      width: 1,
      height: 28,
      color: onDark
          ? Colors.white.withOpacity(0.15)
          : _P.divider,
    );
  }

  Widget _buildDaySummaryRow(WorkoutDay day) {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final label = _programType == ProgramType.weekly
        ? dayNames[(day.dayNumber - 1) % 7]
        : 'День ${day.dayNumber}';
    final provider = context.read<FitnessProvider>();

    final previews = day.exercises.take(3).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(label, style: _T.headline.copyWith(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          if (!day.isRestDay && previews.isNotEmpty)
            Expanded(
              child: Row(
                children: [
                  ...previews.map((we) {
                    final exData = provider.exercises.firstWhere(
                          (e) => e.id == we.exerciseId,
                      orElse: () => Exercise(id: '', name: '???'),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _ExerciseThumb(exercise: exData, size: 28, radius: 8),
                    );
                  }),
                  if (day.exercises.length > 3)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _P.bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+${day.exercises.length - 3}',
                        style: _T.overline.copyWith(
                          fontSize: 8,
                          color: _P.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Expanded(
              child: Text(
                day.isRestDay ? 'Отдых' : 'Пусто',
                style: _T.caption,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: day.isRestDay ? _P.skySoft : _P.greenSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day.isRestDay
                  ? '—'
                  : '${day.exercises.fold<int>(0, (s, e) => s + e.sets.length)} ПОДХ',
              style: _T.overline.copyWith(
                fontSize: 9,
                color: day.isRestDay ? _P.skyDeep : _P.greenText,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // LOGIC & HELPERS
  // =====================================================================

  double _stepForMetric(ExerciseMetric m) {
    switch (m) {
      case ExerciseMetric.weight: return 2.5;
      case ExerciseMetric.distance: return 0.1;
      case ExerciseMetric.pace: return 0.1;
      case ExerciseMetric.incline: return 1;
      case ExerciseMetric.resistance: return 1;
      case ExerciseMetric.heartRate: return 5;
      case ExerciseMetric.calories: return 10;
      case ExerciseMetric.roundDuration: return 30;
      case ExerciseMetric.restBetweenRounds: return 15;
      case ExerciseMetric.holdSeconds: return 15;
      case ExerciseMetric.duration: return 15;
      case ExerciseMetric.restSeconds: return 15;
      case ExerciseMetric.rpe: return 0.5;
      default: return 1;
    }
  }

  List<Map<String, String>> _presetsForFormat(ExerciseFormat format) {
    switch (format) {
      case ExerciseFormat.setsReps: return const [{'id': '3x10', 'label': '3×10'}, {'id': '4x8', 'label': '4×8'}, {'id': '5x5', 'label': '5×5'}];
      case ExerciseFormat.timedSets: return const [{'id': '3x45s', 'label': '3×45с'}, {'id': '3x60s', 'label': '3×60с'}, {'id': '3x90s', 'label': '3×90с'}];
      case ExerciseFormat.intervals: return const [{'id': '8x400m', 'label': '8×400м'}, {'id': '6x800m', 'label': '6×800м'}, {'id': '4x1000m', 'label': '4×1км'}];
      case ExerciseFormat.rounds: return const [{'id': '3x3m', 'label': '3×3м'}, {'id': '5x2m', 'label': '5×2м'}, {'id': '3x5m', 'label': '3×5м'}];
      case ExerciseFormat.continuous: return const [{'id': '5km', 'label': '5 км'}, {'id': '10km', 'label': '10 км'}, {'id': '30m', 'label': '30 мин'}];
      case ExerciseFormat.hold: return const [{'id': '30s', 'label': '30с'}, {'id': '60s', 'label': '1 мин'}, {'id': '3m', 'label': '3 мин'}];
      case ExerciseFormat.freeform: return const [{'id': '10m', 'label': '10 мин'}, {'id': '20m', 'label': '20 мин'}, {'id': '30m', 'label': '30 мин'}];
    }
  }

  void _changeFormat(int exIndex, ExerciseFormat newFormat) {
    final day = _days[_editingDayIndex];
    final we = day.exercises[exIndex];
    final hasData = _hasAnySetData(we.sets);

    void apply() {
      setState(() {
        final exercises = List<WorkoutExercise>.from(day.exercises);
        final newSet = ExerciseSet(setNumber: 1, reps: newFormat == ExerciseFormat.setsReps ? 10 : 0, weight: 0, duration: (newFormat == ExerciseFormat.timedSets || newFormat == ExerciseFormat.freeform) ? 60 : null, roundDuration: newFormat == ExerciseFormat.rounds ? 180 : null, rounds: newFormat == ExerciseFormat.rounds ? 3 : null, holdSeconds: newFormat == ExerciseFormat.hold ? 30 : null, restSeconds: newFormat.usesRest ? FitnessHelpers.getRecommendedRestSeconds(newFormat) : null);
        exercises[exIndex] = we.copyWith(format: newFormat, sets: [newSet]);
        _days[_editingDayIndex] = day.copyWith(exercises: exercises);
        _initControllers(context.read<FitnessProvider>());
      });
    }

    if (!hasData) { apply(); return; }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Сменить формат?', style: _T.headline),
        content: Text('Заполненные подходы будут сброшены.', style: _T.caption),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена', style: _T.caption)),
          TextButton(onPressed: () { Navigator.pop(ctx); apply(); }, child: Text('Сбросить', style: _T.headline.copyWith(color: _P.redDeep))),
        ],
      ),
    );
  }

  void _applyPreset(int exIndex, ExerciseFormat format, String presetId) {
    setState(() {
      final day = _days[_editingDayIndex];
      final config = day.exercises[exIndex];
      final oldLength = config.sets.length;
      for (int j = 0; j < oldLength; j++) {
        final key = '${_editingDayIndex}_${exIndex}_$j';
        _repsControllers[key]?.dispose(); _repsControllers.remove(key);
        _weightControllers[key]?.dispose(); _weightControllers.remove(key);
        for (final m in ExerciseMetric.values) { final mKey = '${key}_${m.name}'; _metricControllers[mKey]?.dispose(); _metricControllers.remove(mKey); }
      }
      final newSets = _buildPresetSets(format, presetId, config.sets);
      final exercises = List<WorkoutExercise>.from(_days[_editingDayIndex].exercises);
      exercises[exIndex] = config.copyWith(sets: newSets);
      _days[_editingDayIndex] = _days[_editingDayIndex].copyWith(exercises: exercises);
      _initControllers(context.read<FitnessProvider>());
    });
  }

  List<ExerciseSet> _buildPresetSets(ExerciseFormat format, String presetId, List<ExerciseSet> currentSets) {
    switch (format) {
      case ExerciseFormat.setsReps:
        final w = currentSets.isNotEmpty ? currentSets.first.weight : 0.0;
        final r = presetId == '3x10' ? 10 : (presetId == '4x8' ? 8 : 5);
        final c = presetId == '3x10' ? 3 : (presetId == '4x8' ? 4 : 5);
        return List.generate(c, (i) => ExerciseSet(setNumber: i + 1, reps: r, weight: w, isWarmup: i == 0, restSeconds: i == 0 ? 60 : 90));
      case ExerciseFormat.timedSets:
        final s = presetId == '3x45s' ? 45 : (presetId == '3x60s' ? 60 : 90);
        return List.generate(3, (i) => ExerciseSet(setNumber: i + 1, duration: s, intensity: 5, restSeconds: 60));
      case ExerciseFormat.intervals:
        final d = presetId == '8x400m' ? 0.4 : (presetId == '4x1000m' ? 1.0 : 0.8);
        final c = presetId == '8x400m' ? 8 : (presetId == '4x1000m' ? 4 : 6);
        return List.generate(c, (i) => ExerciseSet(setNumber: i + 1, distance: d, restSeconds: 90));
      case ExerciseFormat.rounds:
        final rd = presetId == '3x3m' ? 180 : (presetId == '5x2m' ? 120 : 300);
        final c = presetId == '3x3m' ? 3 : (presetId == '5x2m' ? 5 : 3);
        return List.generate(c, (i) => ExerciseSet(setNumber: i + 1, rounds: 1, roundDuration: rd, restBetweenRounds: 60, intensity: 7));
      case ExerciseFormat.continuous:
        return [ExerciseSet(setNumber: 1, distance: presetId == '5km' ? 5 : (presetId == '10km' ? 10 : null), duration: presetId == '30m' ? 1800 : null, restSeconds: 0)];
      case ExerciseFormat.hold:
        final s = presetId == '30s' ? 30 : (presetId == '60s' ? 60 : 180);
        return [ExerciseSet(setNumber: 1, holdSeconds: s, intensity: 6)];
      case ExerciseFormat.freeform:
        final s = presetId == '10m' ? 600 : (presetId == '20m' ? 1200 : 1800);
        return [ExerciseSet(setNumber: 1, duration: s, intensity: 5)];
    }
  }

  void _applyFirstToAll(int exIndex) {
    setState(() {
      final config = _days[_editingDayIndex].exercises[exIndex];
      if (config.sets.isEmpty) return;
      final first = config.sets.first;
      for (int i = 1; i < config.sets.length; i++) {
        config.sets[i] = ExerciseSet(setNumber: i + 1, reps: first.reps, weight: first.weight, rpe: first.rpe, restSeconds: first.restSeconds, isWarmup: false, duration: first.duration, distance: first.distance, pace: first.pace, heartRate: first.heartRate, calories: first.calories, incline: first.incline, resistance: first.resistance, rounds: first.rounds, roundDuration: first.roundDuration, restBetweenRounds: first.restBetweenRounds, punches: first.punches, holdSeconds: first.holdSeconds, tempo: first.tempo, intensity: first.intensity);
      }
      _initControllers(context.read<FitnessProvider>());
    });
  }

  void _addSet(int exIndex, ExerciseFormat format) {
    setState(() {
      final config = _days[_editingDayIndex].exercises[exIndex];
      final newIndex = config.sets.length;
      final lastSet = config.sets.isNotEmpty ? config.sets.last : null;
      final newSet = ExerciseSet(setNumber: newIndex + 1, reps: format == ExerciseFormat.setsReps ? (lastSet?.reps ?? 10) : 0, weight: format == ExerciseFormat.setsReps ? (lastSet?.weight ?? 0) : 0, duration: lastSet?.duration ?? ((format == ExerciseFormat.timedSets || format == ExerciseFormat.freeform) ? 60 : null), distance: lastSet?.distance, pace: lastSet?.pace, heartRate: lastSet?.heartRate, calories: lastSet?.calories, incline: lastSet?.incline, resistance: lastSet?.resistance, rounds: lastSet?.rounds, roundDuration: lastSet?.roundDuration, restBetweenRounds: lastSet?.restBetweenRounds, punches: lastSet?.punches, holdSeconds: lastSet?.holdSeconds, tempo: lastSet?.tempo, intensity: lastSet?.intensity, restSeconds: lastSet?.restSeconds);
      config.sets.add(newSet);
      final key = '${_editingDayIndex}_${exIndex}_$newIndex';
      _repsControllers[key] = TextEditingController(text: newSet.reps > 0 ? '${newSet.reps}' : '');
      _weightControllers[key] = TextEditingController(text: newSet.weight > 0 ? newSet.weight.toStringAsFixed(1) : '');
      for (final m in format.metrics) {
        if (m == ExerciseMetric.weight || m == ExerciseMetric.reps || m == ExerciseMetric.intensity || m == ExerciseMetric.tempo) continue;
        final mKey = '${key}_${m.name}';
        final v = FitnessHelpers.metricValue(newSet, m);
        _metricControllers[mKey] = TextEditingController(text: v != null && v != 0 ? (m.isDecimal ? v.toStringAsFixed(m == ExerciseMetric.distance ? 2 : 1) : v.toStringAsFixed(0)) : '');
      }
    });
  }

  void _removeSet(int exIndex, int setIndex) {
    setState(() {
      final config = _days[_editingDayIndex].exercises[exIndex];
      if (config.sets.length <= 1) return;
      config.sets.removeAt(setIndex);
      final key = '${_editingDayIndex}_${exIndex}_$setIndex';
      _repsControllers[key]?.dispose(); _repsControllers.remove(key);
      _weightControllers[key]?.dispose(); _weightControllers.remove(key);
      for (final m in ExerciseMetric.values) { final mKey = '${key}_${m.name}'; _metricControllers[mKey]?.dispose(); _metricControllers.remove(mKey); }
      for (int i = setIndex; i < config.sets.length; i++) {
        final oldKey = '${_editingDayIndex}_${exIndex}_${i + 1}';
        final newKey = '${_editingDayIndex}_${exIndex}_$i';
        if (_repsControllers.containsKey(oldKey)) _repsControllers[newKey] = _repsControllers.remove(oldKey)!;
        if (_weightControllers.containsKey(oldKey)) _weightControllers[newKey] = _weightControllers.remove(oldKey)!;
        for (final m in ExerciseMetric.values) { final o = '${oldKey}_${m.name}'; final n = '${newKey}_${m.name}'; if (_metricControllers.containsKey(o)) _metricControllers[n] = _metricControllers.remove(o)!; }
      }
    });
  }

  void _updateSet(int exIndex, int setIndex, {int? reps, double? weight}) {
    setState(() {
      final day = _days[_editingDayIndex];
      final exercises = List<WorkoutExercise>.from(day.exercises);
      final sets = List<ExerciseSet>.from(exercises[exIndex].sets);
      final old = sets[setIndex];
      sets[setIndex] = old.copyWith(reps: reps ?? old.reps, weight: weight ?? old.weight);
      exercises[exIndex] = exercises[exIndex].copyWith(sets: sets);
      _days[_editingDayIndex] = day.copyWith(exercises: exercises);
    });
  }

  void _updateSetMetric(int exIndex, int setIndex, ExerciseMetric metric, double value) {
    setState(() {
      final day = _days[_editingDayIndex];
      final exercises = List<WorkoutExercise>.from(day.exercises);
      final sets = List<ExerciseSet>.from(exercises[exIndex].sets);
      final old = sets[setIndex];
      ExerciseSet updated;
      switch (metric) {
        case ExerciseMetric.reps: updated = old.copyWith(reps: value.toInt()); break;
        case ExerciseMetric.weight: updated = old.copyWith(weight: value); break;
        case ExerciseMetric.rpe: updated = old.copyWith(rpe: value); break;
        case ExerciseMetric.restSeconds: updated = old.copyWith(restSeconds: value.toInt()); break;
        case ExerciseMetric.duration: updated = old.copyWith(duration: value.toInt()); break;
        case ExerciseMetric.distance: updated = old.copyWith(distance: value); break;
        case ExerciseMetric.pace: updated = old.copyWith(pace: value); break;
        case ExerciseMetric.heartRate: updated = old.copyWith(heartRate: value.toInt()); break;
        case ExerciseMetric.calories: updated = old.copyWith(calories: value.toInt()); break;
        case ExerciseMetric.incline: updated = old.copyWith(incline: value); break;
        case ExerciseMetric.resistance: updated = old.copyWith(resistance: value); break;
        case ExerciseMetric.rounds: updated = old.copyWith(rounds: value.toInt()); break;
        case ExerciseMetric.roundDuration: updated = old.copyWith(roundDuration: value.toInt()); break;
        case ExerciseMetric.restBetweenRounds: updated = old.copyWith(restBetweenRounds: value.toInt()); break;
        case ExerciseMetric.punches: updated = old.copyWith(punches: value.toInt()); break;
        case ExerciseMetric.holdSeconds: updated = old.copyWith(holdSeconds: value.toInt()); break;
        case ExerciseMetric.tempo: updated = old; break;
        case ExerciseMetric.intensity: updated = old.copyWith(intensity: value); break;
      }
      sets[setIndex] = updated;
      exercises[exIndex] = exercises[exIndex].copyWith(sets: sets);
      _days[_editingDayIndex] = day.copyWith(exercises: exercises);
    });
  }

  bool _hasSetConfigured(ExerciseSet s, ExerciseFormat format) {
    switch (format) {
      case ExerciseFormat.setsReps: return s.reps > 0 && s.weight > 0;
      case ExerciseFormat.timedSets: return (s.duration ?? 0) > 0;
      case ExerciseFormat.intervals: return (s.distance ?? 0) > 0 || (s.duration ?? 0) > 0;
      case ExerciseFormat.rounds: return (s.rounds ?? 0) > 0 && (s.roundDuration ?? 0) > 0;
      case ExerciseFormat.continuous: return (s.distance ?? 0) > 0 || (s.duration ?? 0) > 0;
      case ExerciseFormat.hold: return (s.holdSeconds ?? 0) > 0;
      case ExerciseFormat.freeform: return (s.duration ?? 0) > 0;
    }
  }

  bool _hasAnySetData(List<ExerciseSet> sets) {
    for (final s in sets) { if (s.reps > 0) return true; if (s.weight > 0) return true; if (s.hasAnyMetricData) return true; }
    return false;
  }

  Future<void> _saveProgram() async {
    HapticFeedback.mediumImpact();
    final name = _nameController.text.trim();
    if (name.isEmpty) { _showSnack('Введите название программы', _P.redDeep); return; }
    final activeDays = _days.where((d) => !d.isRestDay).toList();
    if (activeDays.isNotEmpty && activeDays.every((d) => d.exercises.isEmpty)) { _showSnack('Добавьте хотя бы одно упражнение', _P.redDeep); return; }

    final provider = context.read<FitnessProvider>();
    final daysData = _days.map((d) => {
      'dayNumber': d.dayNumber, 'isRestDay': d.isRestDay, 'notes': d.notes,
      'exercises': d.exercises.map((e) => WorkoutExercise(id: 'ex_${DateTime.now().microsecondsSinceEpoch}_${e.order}', exerciseId: e.exerciseId, order: e.order, sets: e.sets.map((s) => ExerciseSet(setNumber: s.setNumber, reps: s.reps, weight: s.weight, isWarmup: s.isWarmup, status: SetStatus.pending, rpe: s.rpe, restSeconds: s.restSeconds, duration: s.duration, distance: s.distance, pace: s.pace, heartRate: s.heartRate, calories: s.calories, incline: s.incline, resistance: s.resistance, rounds: s.rounds, roundDuration: s.roundDuration, restBetweenRounds: s.restBetweenRounds, punches: s.punches, holdSeconds: s.holdSeconds, tempo: s.tempo, intensity: s.intensity)).toList(), groupType: e.groupType, restBetweenSeconds: e.restBetweenSeconds, notes: e.notes, format: e.format)).toList(),
    }).toList();

    try {
      if (widget.existingProgram != null) {
        await provider.updateProgram(widget.existingProgram!.copyWith(name: name, type: _programType, days: _days, description: _descriptionController.text, emoji: _selectedEmoji, accentColorValue: _accentColor.value, difficulty: _difficulty, goal: _goal, sessionDurationMinutes: int.tryParse(_durationController.text) ?? 60, backgroundImage: _backgroundImage));
      } else {
        await provider.addFullProgram(name: name, type: _programType, daysData: daysData, description: _descriptionController.text, emoji: _selectedEmoji, accentColorValue: _accentColor.value, difficulty: _difficulty, goal: _goal, sessionDurationMinutes: int.tryParse(_durationController.text) ?? 60, backgroundImage: _backgroundImage);
      }
      if (mounted) { _showSnack('Программа «$name» сохранена', _P.greenDeep, success: true); Navigator.pop(context); }
    } catch (e) {
      if (mounted) _showSnack('Ошибка: $e', _P.redDeep);
    }
  }

  void _showSnack(String text, Color color, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [if (success) ...[const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18), const SizedBox(width: 8)], Expanded(child: Text(text))]), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));
  }
}

// =====================================================================
// FIGMA STEPPER
// =====================================================================
class _FigmaStepper extends StatelessWidget {
  final String label;
  final double value;
  final double step;
  final bool isDecimal;
  final String Function(double)? formatValue;
  final TextEditingController? controller;
  final ValueChanged<double> onChanged;

  const _FigmaStepper({required this.label, required this.value, required this.step, required this.isDecimal, this.formatValue, this.controller, required this.onChanged});

  String _fmt(double v) {
    if (formatValue != null) return formatValue!(v);
    return isDecimal ? v.toStringAsFixed(1) : v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _P.divider)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { final nv = (value - step).clamp(0.0, 9999.0); onChanged(nv); if(controller != null) controller!.text = _fmt(nv); },
            child: Container(width: 36, height: 44, alignment: Alignment.center, child: const Icon(Icons.remove, size: 14, color: _P.textMuted)),
          ),
          Expanded(
            child: TextField(
              controller: controller, textAlign: TextAlign.center, keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
              style: _T.number.copyWith(fontSize: 14, color: _P.text),
              decoration: InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero, hintText: _fmt(value), hintStyle: _T.number.copyWith(fontSize: 14, color: _P.textMuted)),
              onChanged: (v) {
                if (v.isEmpty) { onChanged(0); return; }
                final p = isDecimal ? double.tryParse(v.replaceAll(',', '.')) : int.tryParse(v)?.toDouble();
                if (p != null) onChanged(p);
              },
            ),
          ),
          GestureDetector(
            onTap: () { final nv = (value + step).clamp(0.0, 9999.0); onChanged(nv); if(controller != null) controller!.text = _fmt(nv); },
            child: Container(width: 36, height: 44, alignment: Alignment.center, child: const Icon(Icons.add, size: 14, color: _P.greenDeep)),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// BOTTOM SHEETS (SEARCH & LIST)
// =====================================================================
class _ExerciseSearchSheet extends StatefulWidget {
  final Function(Exercise) onAdd;
  final Function(Exercise) onRemove;
  final List<String> addedIds;
  const _ExerciseSearchSheet({required this.onAdd, required this.onRemove, required this.addedIds});

  @override
  State<_ExerciseSearchSheet> createState() => _ExerciseSearchSheetState();
}

class _ExerciseSearchSheetState extends State<_ExerciseSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late Set<String> _addedIdsSet;

  @override
  void initState() { super.initState(); _addedIdsSet = widget.addedIds.toSet(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final exercises = _query.isEmpty ? provider.exercises : provider.searchExercises(_query);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(color: _P.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        children: [
          Container(width: 40, height: 5, margin: const EdgeInsets.only(top: 16), decoration: BoxDecoration(color: _P.border, borderRadius: BorderRadius.circular(3))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('БЫСТРЫЙ ПОИСК', style: _T.overline),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController, onChanged: (v) => setState(() => _query = v), autofocus: true,
                  style: _T.headline,
                  decoration: InputDecoration(hintText: 'Поиск…', prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final ex = exercises[index];
                final isAdded = _addedIdsSet.contains(ex.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _P.divider)),
                  child: ListTile(
                    leading: _ExerciseThumb(exercise: ex, size: 42, radius: 12, bg: _P.bg),
                    title: Text(ex.name, style: _T.headline),
                    subtitle: Text(ex.muscleGroups.map((m) => m.displayName).join(' • '), style: _T.caption),
                    trailing: GestureDetector(
                      onTap: () => setState(() { if (isAdded) { _addedIdsSet.remove(ex.id); widget.onRemove(ex); } else { _addedIdsSet.add(ex.id); widget.onAdd(ex); } }),
                      child: Container(width: 34, height: 34, decoration: BoxDecoration(color: isAdded ? _P.greenSoft : _P.bg, shape: BoxShape.circle), child: Icon(isAdded ? Icons.check_rounded : Icons.add_rounded, color: isAdded ? _P.greenDeep : _P.text, size: 18)),
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

class _ExerciseListSheet extends StatefulWidget {
  final Function(Exercise) onAdd;
  final Function(Exercise) onRemove;
  final List<String> addedIds;
  final MuscleGroup? filterMuscle;
  const _ExerciseListSheet({required this.onAdd, required this.onRemove, required this.addedIds, this.filterMuscle});

  @override
  State<_ExerciseListSheet> createState() => _ExerciseListSheetState();
}

class _ExerciseListSheetState extends State<_ExerciseListSheet> {
  MuscleGroup? _selectedGroup;
  late Set<String> _addedIdsSet;

  @override
  void initState() { super.initState(); _selectedGroup = widget.filterMuscle; _addedIdsSet = widget.addedIds.toSet(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    var exercises = provider.exercises.toList();
    if (_selectedGroup != null) exercises = exercises.where((e) => e.muscleGroups.contains(_selectedGroup)).toList();
    final groups = MuscleGroup.values.where((g) => g != MuscleGroup.fullBody).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: _P.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 40, height: 5, margin: const EdgeInsets.only(top: 16), decoration: BoxDecoration(color: _P.border, borderRadius: BorderRadius.circular(3))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Упражнения', style: _T.title2),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: groups.length + 1,
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final group = isAll ? null : groups[index - 1];
                final isSelected = (isAll && _selectedGroup == null) || (!isAll && _selectedGroup == group);
                return GestureDetector(
                  onTap: () => setState(() => _selectedGroup = group),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: isSelected ? _P.greenDeep : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? _P.greenDeep : _P.divider)),
                    child: Text(isAll ? 'Все' : group!.displayName, style: _T.caption.copyWith(color: isSelected ? Colors.white : _P.text)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final ex = exercises[index];
                final isAdded = _addedIdsSet.contains(ex.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _P.divider)),
                  child: ListTile(
                    leading: _ExerciseThumb(exercise: ex, size: 42, radius: 12, bg: _P.bg),
                    title: Text(ex.name, style: _T.headline),
                    trailing: GestureDetector(
                      onTap: () => setState(() { if (isAdded) { _addedIdsSet.remove(ex.id); widget.onRemove(ex); } else { _addedIdsSet.add(ex.id); widget.onAdd(ex); } }),
                      child: Container(width: 34, height: 34, decoration: BoxDecoration(color: isAdded ? _P.greenSoft : _P.bg, shape: BoxShape.circle), child: Icon(isAdded ? Icons.check_rounded : Icons.add_rounded, color: isAdded ? _P.greenDeep : _P.text, size: 18)),
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

// ═══════════════════════════════════════════════════════════════════
//  UNIFIED IMAGE HELPERS
//  Поддерживает: assets/ , http(s):// , локальный файл
// ═══════════════════════════════════════════════════════════════════
class _AppImage extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  final Widget? fallback;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const _AppImage({
    this.path,
    this.fit = BoxFit.cover,
    this.fallback,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final p = path;
    final fb = fallback ?? const SizedBox.shrink();
    Widget child;

    if (p == null || p.isEmpty) {
      child = fb;
    } else if (p.startsWith('assets/')) {
      child = Image.asset(
        p, fit: fit, width: width, height: height,
        errorBuilder: (_, __, ___) => fb,
      );
    } else if (p.startsWith('http')) {
      child = CachedNetworkImage(
        imageUrl: p, fit: fit, width: width, height: height,
        placeholder: (_, __) => fb,
        errorWidget: (_, __, ___) => fb,
      );
    } else {
      child = Image.file(
        File(p), fit: fit, width: width, height: height,
        errorBuilder: (_, __, ___) => fb,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

/// Круглая / скруглённая миниатюра упражнения с fallback на emoji.
/// Используется ВЕЗДЕ: карточки дней, шиты, search, summary.
class _ExerciseThumb extends StatelessWidget {
  final Exercise exercise;
  final double size;
  final double radius;
  final Color? bg;

  const _ExerciseThumb({
    required this.exercise,
    this.size = 44,
    this.radius = 14,
    this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty;
    final emoji = Text(
      exercise.exerciseType.emoji,
      style: TextStyle(fontSize: size * 0.45),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg ?? _P.greenSoft,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _P.greenDeep.withOpacity(0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage
          ? _AppImage(path: exercise.imageUrl, fit: BoxFit.cover, fallback: emoji)
          : emoji,
    );
  }
}