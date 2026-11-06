// features/fitness/database/ui/screens/workout_execution_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/enums.dart';
import '../../../models/fitness_models.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';
import '../widgets/timer_widget.dart';

// ═══════════════════════════════════════════════════════════════════
//  PREMIUM DESIGN SYSTEM — compact
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

  static const lavenderDeep = Color(0xFF9381BB);
  static const lavenderSoft = Color(0xFFEEEAF5);

  static const peachDeep = Color(0xFFEF9563);
  static const peachSoft = Color(0xFFFCF0E8);

  static const skyDeep = Color(0xFF7E9DC6);
  static const skySoft = Color(0xFFEBF0F8);

  static const yellowDeep = Color(0xFFE0B054);
  static const yellowSoft = Color(0xFFFDF5E6);

  static const pinkDeep = Color(0xFFD17A8F);
  static const pinkSoft = Color(0xFFFCF0F2);
}

class _T {
  static TextStyle title1 = GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.7,
      color: _P.text);
  static TextStyle title2 = GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: _P.text);
  static TextStyle headline = GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w600, color: _P.text);
  static TextStyle body = GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400, color: _P.textMuted);
  static TextStyle caption = GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w400, color: _P.textMuted);
  static TextStyle overline = GoogleFonts.inter(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      color: _P.textMuted);
  static TextStyle number = GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()]);
}

// ═══════════════════════════════════════════════════════════════════
//  CATEGORY HELPERS
// ═══════════════════════════════════════════════════════════════════
enum _ExCategory { strength, bodyweight, hold, timedSets, cardio, combat }

_ExCategory _detectCategory(Exercise ex, ExerciseFormat format) {
  switch (format) {
    case ExerciseFormat.hold:
      return _ExCategory.hold;
    case ExerciseFormat.timedSets:
      return _ExCategory.timedSets;
    case ExerciseFormat.rounds:
      return _ExCategory.combat;
    case ExerciseFormat.continuous:
    case ExerciseFormat.intervals:
      return _ExCategory.cardio;
    case ExerciseFormat.setsReps:
      if (ex.exerciseType == ExerciseType.bodyweight ||
          ex.exerciseType == ExerciseType.yoga) {
        return _ExCategory.bodyweight;
      }
      return _ExCategory.strength;
    case ExerciseFormat.freeform:
      return _ExCategory.timedSets;
  }
}

Color _accentFor(_ExCategory c) {
  switch (c) {
    case _ExCategory.strength:
      return _P.peachDeep;
    case _ExCategory.bodyweight:
      return _P.greenDeep;
    case _ExCategory.hold:
      return _P.yellowDeep;
    case _ExCategory.timedSets:
      return _P.lavenderDeep;
    case _ExCategory.cardio:
      return _P.skyDeep;
    case _ExCategory.combat:
      return _P.pinkDeep;
  }
}

Color _softFor(_ExCategory c) {
  switch (c) {
    case _ExCategory.strength:
      return _P.peachSoft;
    case _ExCategory.bodyweight:
      return _P.greenSoft;
    case _ExCategory.hold:
      return _P.yellowSoft;
    case _ExCategory.timedSets:
      return _P.lavenderSoft;
    case _ExCategory.cardio:
      return _P.skySoft;
    case _ExCategory.combat:
      return _P.pinkSoft;
  }
}

String _categoryLabel(_ExCategory c) {
  switch (c) {
    case _ExCategory.strength:
      return 'Сила';
    case _ExCategory.bodyweight:
      return 'Свой вес';
    case _ExCategory.hold:
      return 'Статика';
    case _ExCategory.timedSets:
      return 'На время';
    case _ExCategory.cardio:
      return 'Кардио';
    case _ExCategory.combat:
      return 'Раунды';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  UNIFIED IMAGE HELPER
// ═══════════════════════════════════════════════════════════════════
class _ExImage extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;
  final Color? bg;
  final Color? border;
  final String? fallbackEmoji;
  final IconData? fallbackIcon;
  final Color? fallbackColor;

  const _ExImage({
    this.url,
    required this.size,
    this.radius = 12,
    this.bg,
    this.border,
    this.fallbackEmoji,
    this.fallbackIcon,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.isNotEmpty;

    final Widget fallback = fallbackIcon != null
        ? Icon(fallbackIcon,
        size: size * 0.42, color: fallbackColor ?? _P.textMuted)
        : Text(fallbackEmoji ?? '🏋️',
        style: TextStyle(fontSize: size * 0.42));

    Widget content = fallback;
    if (hasImage) {
      if (url!.startsWith('assets/')) {
        content = Image.asset(url!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback);
      } else if (url!.startsWith('http')) {
        content = CachedNetworkImage(
            imageUrl: url!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: bg ?? _P.bg),
            errorWidget: (_, __, ___) => fallback);
      } else {
        content = Image.file(File(url!),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback);
      }
    }

    final b = border;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg ?? _P.bg,
        borderRadius: BorderRadius.circular(radius),
        border: b != null ? Border.all(color: b) : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: content,
    );
  }
}

class _ExCover extends StatelessWidget {
  final String? url;
  final double? height;
  final double radius;
  final String? fallbackEmoji;

  const _ExCover({
    this.url,
    this.height,
    this.radius = 0,
    this.fallbackEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.isNotEmpty;

    Widget img;
    if (!hasImage) {
      img = Container(
        color: _P.greenSoft,
        alignment: Alignment.center,
        child: Text(fallbackEmoji ?? '🏋️',
            style: const TextStyle(fontSize: 44)),
      );
    } else if (url!.startsWith('assets/')) {
      img = Image.asset(url!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: _P.greenSoft));
    } else if (url!.startsWith('http')) {
      img = CachedNetworkImage(
          imageUrl: url!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: _P.bg),
          errorWidget: (_, __, ___) => Container(color: _P.greenSoft));
    } else {
      img = Image.file(File(url!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: _P.greenSoft));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(height: height, width: double.infinity, child: img),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class WorkoutExecutionScreen extends StatefulWidget {
  final WorkoutDay day;
  final bool isDark;
  const WorkoutExecutionScreen(
      {super.key, required this.day, this.isDark = false});

  @override
  State<WorkoutExecutionScreen> createState() =>
      _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  WorkoutPhase _phase = WorkoutPhase.setup;
  late List<ConfiguredExercise> _config;
  List<_WorkoutStep> _steps = [];
  int _currentStepIndex = 0;

  bool _isCircuitMode = false;
  int _totalCircuits = 3;
  final Map<String, List<CompletedSetData>> _completedData = {};
  DateTime? _startTime;
  int _restSeconds = 90;

  int? _moodEnergy;
  int? _moodSleep;
  int? _moodMotivation;
  String? _moodNotes;
  String? _workoutPhotoPath;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isFinishing = false;
  String? _savedLogId;

  @override
  void initState() {
    super.initState();
    _config = widget.day.exercises.map((ex) {
      return ConfiguredExercise(
        exercise: ex,
        sets: ex.sets.map((s) => SetConfig.fromExerciseSet(s)).toList(),
      );
    }).toList();

    _startTime = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (int i = 0; i < _config.length; i++) {
        if (_catOf(i) == _ExCategory.combat) {
          for (final s in _config[i].sets) {
            s.rounds ??= 5;
            s.roundDuration ??= 180;
            s.restBetweenRounds ??= 60;
          }
        }
      }
      setState(() {});
    });
  }

  ExerciseFormat _resolveFormatOf(int exIndex) {
    final provider = context.read<FitnessProvider>();
    final we = _config[exIndex].exercise;
    final exData = provider.exercises.firstWhere(
          (e) => e.id == we.exerciseId,
      orElse: () => Exercise(id: '', name: ''),
    );
    return FitnessHelpers.resolveFormat(we, exData.id.isEmpty ? null : exData);
  }

  _ExCategory _catOf(int exIndex) {
    try {
      final provider = context.read<FitnessProvider>();
      final we = _config[exIndex].exercise;
      final exData = provider.exercises.firstWhere(
            (e) => e.id == we.exerciseId,
        orElse: () => Exercise(id: '', name: ''),
      );
      final format =
      FitnessHelpers.resolveFormat(we, exData.id.isEmpty ? null : exData);
      return _detectCategory(exData, format);
    } catch (_) {
      return _ExCategory.strength;
    }
  }

  String _summaryTextForCategory(ConfiguredExercise c, _ExCategory cat) {
    if (c.sets.isEmpty) return 'Нет данных';
    final s = c.sets.first;
    switch (cat) {
      case _ExCategory.strength:
        final w = s.weight;
        final wStr =
        w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);
        return '${s.reps} × $wStr кг';
      case _ExCategory.bodyweight:
        return '${s.reps} повт.';
      case _ExCategory.hold:
        return _formatSeconds(s.holdSeconds ?? 0);
      case _ExCategory.timedSets:
        return '${_formatSeconds(s.duration)} · ${s.reps} повт.';
      case _ExCategory.cardio:
        final d = (s.distance ?? 0).toStringAsFixed(1);
        return '$d км · ${_formatSeconds(s.duration)}';
      case _ExCategory.combat:
        final r = s.rounds ?? 0;
        return '$r × ${_formatSeconds(s.roundDuration ?? 0)}';
    }
  }

  void _buildSteps() {
    _steps = [];
    _currentStepIndex = 0;
    if (!_isCircuitMode) {
      for (int e = 0; e < _config.length; e++) {
        final cat = _catOf(e);
        if (cat == _ExCategory.combat) {
          _steps.add(_WorkoutStep(exerciseIndex: e, setIndex: 0, circuitNumber: 0));
        } else {
          for (int s = 0; s < _config[e].sets.length; s++) {
            _steps.add(
                _WorkoutStep(exerciseIndex: e, setIndex: s, circuitNumber: 0));
          }
        }
      }
    } else {
      final maxSets =
      _config.fold<int>(0, (m, c) => c.sets.length > m ? c.sets.length : m);
      final circuits = _totalCircuits.clamp(1, math.max(1, maxSets)).toInt();
      _totalCircuits = circuits;
      for (int circuit = 0; circuit < circuits; circuit++) {
        for (int e = 0; e < _config.length; e++) {
          final cat = _catOf(e);
          if (cat == _ExCategory.combat) {
            _steps.add(_WorkoutStep(
                exerciseIndex: e, setIndex: 0, circuitNumber: circuit + 1));
          } else if (circuit < _config[e].sets.length) {
            _steps.add(_WorkoutStep(
                exerciseIndex: e,
                setIndex: circuit,
                circuitNumber: circuit + 1));
          }
        }
      }
    }
  }

  _WorkoutStep? get _currentStep {
    if (_currentStepIndex < 0 || _currentStepIndex >= _steps.length) {
      return null;
    }
    return _steps[_currentStepIndex];
  }

  Widget _buildExImage(
      String? url, {
        required double size,
        double radius = 12,
        Color? bg,
        Color? border,
        String? fallbackEmoji,
        IconData? fallbackIcon,
        Color? fallbackColor,
      }) {
    return _ExImage(
      url: url,
      size: size,
      radius: radius,
      bg: bg,
      border: border,
      fallbackEmoji: fallbackEmoji,
      fallbackIcon: fallbackIcon,
      fallbackColor: fallbackColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(key: ValueKey(_phase), child: _buildPhase(provider)),
    );
  }

  Widget _buildPhase(FitnessProvider provider) {
    switch (_phase) {
      case WorkoutPhase.setup:
        return _buildSetupScreen(provider);
      case WorkoutPhase.active:
        return _buildActiveScreen(provider);
      case WorkoutPhase.rest:
        return _buildRestScreen(provider);
      case WorkoutPhase.completed:
        return _buildCompletedScreen();
    }
  }

  bool _isSetConfiguredByCategory(SetConfig s, _ExCategory cat) {
    switch (cat) {
      case _ExCategory.strength:
        return s.reps > 0 && s.weight > 0;
      case _ExCategory.bodyweight:
        return s.reps > 0;
      case _ExCategory.hold:
        return (s.holdSeconds ?? 0) > 0;
      case _ExCategory.timedSets:
        return s.duration > 0;
      case _ExCategory.cardio:
        return (s.distance ?? 0) > 0 || s.duration > 0;
      case _ExCategory.combat:
        return (s.rounds ?? 0) > 0 && (s.roundDuration ?? 0) > 0;
    }
  }

  bool _isExerciseConfigured(ConfiguredExercise c, FitnessProvider provider) {
    if (c.sets.isEmpty) return false;
    final cat = _catOf(_config.indexOf(c));
    return c.sets.every((s) => _isSetConfiguredByCategory(s, cat));
  }

  // ══════════════════════════════════════════════════════════
  //  SETUP SCREEN
  // ══════════════════════════════════════════════════════════
  Widget _buildSetupScreen(FitnessProvider provider) {
    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.bg,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 56,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child:
            const Icon(Icons.chevron_left_rounded, color: _P.text, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Настройка',
            style: _T.headline.copyWith(
                fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          if (_config.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Text('Круг', style: _T.caption),
                  const SizedBox(width: 6),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: _isCircuitMode,
                      onChanged: (v) {
                        setState(() {
                          _isCircuitMode = v;
                          if (v) {
                            final maxSets = _config.fold<int>(
                                0,
                                    (m, c) =>
                                c.sets.length > m ? c.sets.length : m);
                            _totalCircuits =
                                math.max(1, math.min(10, maxSets));
                          }
                        });
                      },
                      activeColor: Colors.white,
                      activeTrackColor: _P.greenDeep,
                      inactiveTrackColor: _P.border,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildSetupHero(provider)),
          if (_isCircuitMode)
            SliverToBoxAdapter(child: _buildCircuitSettingsCard()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final config = _config[index];
                  final exData = provider.exercises.firstWhere(
                        (e) => e.id == config.exercise.exerciseId,
                    orElse: () => Exercise(id: '', name: '???'),
                  );
                  return _buildExerciseCard(index, config, exData, provider);
                },
                childCount: _config.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomSheet: _buildStartButton(provider),
    );
  }

  Widget _buildSetupHero(FitnessProvider provider) {
    final totalSets = _config.fold<int>(0, (s, c) => s + c.sets.length);
    int configuredSets = 0;
    for (int i = 0; i < _config.length; i++) {
      final cat = _catOf(i);
      configuredSets += _config[i]
          .sets
          .where((x) => _isSetConfiguredByCategory(x, cat))
          .length;
    }
    final readyExercises =
        _config.where((c) => _isExerciseConfigured(c, provider)).length;
    final progress = totalSets > 0 ? configuredSets / totalSets : 0.0;
    final allReady = _config.isNotEmpty && readyExercises == _config.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: allReady
                ? [const Color(0xFFE4F0E8), _P.greenSoft, const Color(0xFFF4F8F5)]
                : [Colors.white, _P.greenSoft, const Color(0xFFF4F8F5)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: _P.greenDeep.withOpacity(0.06),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 5,
                          valueColor: AlwaysStoppedAnimation(
                              _P.greenDeep.withOpacity(0.12)),
                        ),
                      ),
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                          valueColor:
                          const AlwaysStoppedAnimation(_P.greenDeep),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$readyExercises',
                              style: _T.number.copyWith(
                                  fontSize: 20,
                                  color: _P.greenText,
                                  letterSpacing: -0.6,
                                  height: 1)),
                          Text('/ ${_config.length}',
                              style: _T.caption
                                  .copyWith(fontSize: 9, color: _P.greenText)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allReady ? 'ВСЁ ГОТОВО' : 'ПОДГОТОВКА',
                        style: _T.overline
                            .copyWith(color: _P.greenText, letterSpacing: 1.4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        allReady ? 'Можно начинать' : 'Заполни подходы',
                        style: _T.title2.copyWith(fontSize: 17, color: _P.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$configuredSets из $totalSets подходов',
                        style: _T.caption.copyWith(color: _P.greenText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(_config.length, (i) {
                final isDone = i < readyExercises;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin:
                    EdgeInsets.only(right: i < _config.length - 1 ? 3 : 0),
                    decoration: BoxDecoration(
                      color: isDone ? _P.greenDeep : _P.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircuitSettingsCard() {
    final maxSets =
    _config.fold<int>(0, (m, c) => c.sets.length > m ? c.sets.length : m);
    final clampedMax = math.max(1, maxSets);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _P.yellowSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.yellowDeep.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.refresh_rounded,
                    color: _P.yellowDeep, size: 16),
                const SizedBox(width: 6),
                Text('КРУГОВАЯ ТРЕНИРОВКА',
                    style: _T.overline.copyWith(color: _P.yellowDeep)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Количество кругов', style: _T.body),
                const Spacer(),
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _totalCircuits > 1
                            ? () => setState(() => _totalCircuits--)
                            : null,
                        child: SizedBox(
                          width: 40,
                          height: 36,
                          child: Icon(Icons.remove,
                              size: 16,
                              color: _totalCircuits > 1
                                  ? _P.text
                                  : _P.textMuted),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Center(
                            child: Text('$_totalCircuits',
                                style: _T.headline)),
                      ),
                      InkWell(
                        onTap: _totalCircuits < clampedMax
                            ? () => setState(() => _totalCircuits++)
                            : null,
                        child: SizedBox(
                          width: 40,
                          height: 36,
                          child: Icon(Icons.add,
                              size: 16,
                              color: _totalCircuits < clampedMax
                                  ? _P.greenDeep
                                  : _P.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(int exIndex, ConfiguredExercise config,
      Exercise exData, FitnessProvider provider) {
    final cat = _catOf(exIndex);
    final accent = _accentFor(cat);
    final soft = _softFor(cat);
    final isReady = _isExerciseConfigured(config, provider);
    final hasImage = exData.imageUrl != null && exData.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isReady ? _P.greenDeep.withOpacity(0.3) : _P.divider,
            width: isReady ? 1.4 : 1),
        boxShadow: [
          BoxShadow(
            color: _P.text.withOpacity(0.02),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: !isReady && exIndex == 0,
          iconColor: _P.textMuted,
          collapsedIconColor: _P.textMuted,
          leading: Stack(
            children: [
              _ExImage(
                url: exData.imageUrl,
                size: 42,
                radius: 12,
                bg: soft,
                fallbackEmoji: exData.exerciseType.emoji,
              ),
              if (isReady)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _P.greenDeep,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.8),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 9),
                  ),
                ),
            ],
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exData.name,
                  style: _T.headline.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: soft, borderRadius: BorderRadius.circular(5)),
                    child: Text(_categoryLabel(cat),
                        style:
                        _T.overline.copyWith(color: accent, fontSize: 8)),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _summaryTextForCategory(config, cat),
                      style: _T.caption.copyWith(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (hasImage)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: _ExCover(
                        url: exData.imageUrl,
                        height: 100,
                        fallbackEmoji: exData.exerciseType.emoji),
                  ),
                ),
              ),
            ..._buildCategoryInputs(exIndex, config, cat),
            const SizedBox(height: 10),
            _buildAddSetButton(accent, () => _addSetForCategory(exIndex, cat)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSetButton(Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 15, color: accent),
            const SizedBox(width: 6),
            Text('ДОБАВИТЬ ПОДХОД',
                style: _T.caption.copyWith(
                    color: accent, fontWeight: FontWeight.w600, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryInputs(
      int exIndex, ConfiguredExercise config, _ExCategory cat) {
    final sets = config.sets;

    Widget headerRow;
    if (cat == _ExCategory.strength) {
      headerRow = Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: const [
            SizedBox(
                width: 28,
                child: Text('ПОДХОД',
                    style: TextStyle(fontSize: 9, color: _P.textMuted))),
            Expanded(
                child: Center(
                    child: Text('Вес (кг)',
                        style: TextStyle(
                            fontSize: 9, color: _P.textMuted)))),
            Expanded(
                child: Center(
                    child: Text('Повторы',
                        style: TextStyle(
                            fontSize: 9, color: _P.textMuted)))),
          ],
        ),
      );
    } else {
      headerRow = const SizedBox.shrink();
    }

    return [
      headerRow,
      ...sets.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;

        late Widget left;
        Widget? right;

        switch (cat) {
          case _ExCategory.strength:
            left = _FigmaStepper(
                value: s.weight,
                step: 2.5,
                isDecimal: true,
                quickPicks: const [40, 60, 80, 100],
                onChanged: (v) => setState(() => s.weight = v));
            right = _FigmaStepper(
                value: s.reps.toDouble(),
                step: 1,
                isDecimal: false,
                quickPicks: const [8, 10, 12, 15],
                onChanged: (v) => setState(() => s.reps = v.round()));
            break;
          case _ExCategory.bodyweight:
            left = _FigmaStepper(
                value: s.reps.toDouble(),
                step: 1,
                isDecimal: false,
                quickPicks: const [10, 15, 20, 25],
                onChanged: (v) => setState(() => s.reps = v.round()));
            right = null;
            break;
          case _ExCategory.hold:
            left = _FigmaStepper(
                value: (s.holdSeconds ?? 0).toDouble(),
                step: 5,
                isDecimal: false,
                formatValue: (v) => '${v.round()}с',
                quickPicks: const [30, 45, 60, 90],
                onChanged: (v) =>
                    setState(() => s.holdSeconds = v.round()));
            right = null;
            break;
          case _ExCategory.timedSets:
            left = _FigmaStepper(
                value: s.duration.toDouble(),
                step: 15,
                isDecimal: false,
                formatValue: (v) => '${v.round()}с',
                quickPicks: const [30, 45, 60, 90],
                onChanged: (v) => setState(() => s.duration = v.round()));
            right = _FigmaStepper(
                value: s.reps.toDouble(),
                step: 1,
                isDecimal: false,
                quickPicks: const [10, 15, 20, 25],
                onChanged: (v) => setState(() => s.reps = v.round()));
            break;
          case _ExCategory.cardio:
            left = _FigmaStepper(
                value: (s.distance ?? 0),
                step: 0.1,
                isDecimal: true,
                formatValue: (v) => '${v.toStringAsFixed(1)}км',
                quickPicks: const [1, 3, 5, 10],
                onChanged: (v) => setState(() => s.distance = v));
            right = _FigmaStepper(
                value: s.duration.toDouble(),
                step: 60,
                isDecimal: false,
                formatValue: (v) => '${v.round()}с',
                quickPicks: const [600, 900, 1800, 2700],
                onChanged: (v) => setState(() => s.duration = v.round()));
            break;
          case _ExCategory.combat:
            return _combatSetupBlock(s, _P.pinkDeep);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${(i + 1).toString().padLeft(2, '0')}',
                      style: _T.caption.copyWith(fontSize: 10)),
                ),
              ),
              Expanded(child: left),
              if (right != null) ...[
                const SizedBox(width: 8),
                Expanded(child: right),
              ] else if (cat != _ExCategory.bodyweight &&
                  cat != _ExCategory.hold) ...[
                const SizedBox(width: 8),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        );
      }).toList(),
    ];
  }

  Widget _combatSetupBlock(SetConfig s, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _P.bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🥊', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text('РАУНДЫ', style: _T.overline.copyWith(color: accent)),
            ],
          ),
          const SizedBox(height: 10),
          _settingRow('Раундов', '${s.rounds ?? 5}', accent,
              onDec: () => setState(
                      () => s.rounds = ((s.rounds ?? 5) - 1).clamp(1, 30)),
              onInc: () => setState(
                      () => s.rounds = ((s.rounds ?? 5) + 1).clamp(1, 30))),
          const SizedBox(height: 6),
          _settingRow('Длит. раунда', _formatSeconds(s.roundDuration ?? 180),
              accent,
              onDec: () => setState(() => s.roundDuration =
                  ((s.roundDuration ?? 180) - 15).clamp(15, 900)),
              onInc: () => setState(() => s.roundDuration =
                  ((s.roundDuration ?? 180) + 15).clamp(15, 900))),
          const SizedBox(height: 6),
          _settingRow(
              'Отдых между раундами', _formatSeconds(s.restBetweenRounds ?? 60),
              accent,
              onDec: () => setState(() => s.restBetweenRounds =
                  ((s.restBetweenRounds ?? 60) - 15).clamp(0, 600)),
              onInc: () => setState(() => s.restBetweenRounds =
                  ((s.restBetweenRounds ?? 60) + 15).clamp(0, 600))),
        ],
      ),
    );
  }

  Widget _settingRow(String label, String value, Color accent,
      {required VoidCallback onDec, required VoidCallback onInc}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: _T.body.copyWith(fontSize: 12))),
          Text(value,
              style: _T.number.copyWith(fontSize: 13, color: accent)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onDec,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.remove, color: accent, size: 14),
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onInc,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.add, color: accent, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _addSetForCategory(int exIndex, _ExCategory cat) {
    setState(() {
      final config = _config[exIndex];
      final last = config.sets.isNotEmpty ? config.sets.last : null;
      SetConfig newSet;
      switch (cat) {
        case _ExCategory.strength:
          newSet =
              SetConfig(reps: last?.reps ?? 10, weight: last?.weight ?? 0);
          break;
        case _ExCategory.bodyweight:
          newSet = SetConfig(reps: last?.reps ?? 10);
          break;
        case _ExCategory.hold:
          newSet =
              SetConfig(reps: 0, holdSeconds: last?.holdSeconds ?? 30);
          break;
        case _ExCategory.timedSets:
          newSet =
              SetConfig(reps: last?.reps ?? 10, duration: last?.duration ?? 60);
          break;
        case _ExCategory.cardio:
          newSet = SetConfig(
              reps: 0,
              duration: last?.duration ?? 60,
              distance: last?.distance ?? 0);
          break;
        case _ExCategory.combat:
          newSet = SetConfig(
              reps: 0,
              rounds: last?.rounds ?? 5,
              roundDuration: last?.roundDuration ?? 180,
              restBetweenRounds: last?.restBetweenRounds ?? 60);
          break;
      }
      config.sets.add(newSet);
    });
  }

  Widget _buildStartButton(FitnessProvider provider) {
    final allReady = _config.isNotEmpty &&
        _config.every((c) => _isExerciseConfigured(c, provider));

    return Container(
      color: _P.bg,
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: !allReady
              ? null
              : () async {
            await _showPreWorkoutDialog();
            if (!mounted) return;
            setState(() {
              _buildSteps();
              _currentStepIndex = 0;
              _startTime = DateTime.now();
              _completedData.clear();
              _savedLogId = null;
              _isFinishing = false;
              _phase = WorkoutPhase.active;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: allReady ? _P.greenDeep : _P.border,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            allReady ? 'Начать тренировку' : 'Заполните все поля',
            style: _T.headline
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  ACTIVE SCREEN
  // ══════════════════════════════════════════════════════════
  Widget _buildActiveScreen(FitnessProvider provider) {
    final step = _currentStep;
    if (step == null) return _buildCompletedScreen();
    final cat = _catOf(step.exerciseIndex);

    switch (cat) {
      case _ExCategory.cardio:
        return _buildCardioExecution(provider, step);
      case _ExCategory.combat:
        return _buildCombatExecution(provider, step);
      case _ExCategory.hold:
        return _buildHoldExecution(provider, step);
      case _ExCategory.timedSets:
        return _buildTimedSetsExecution(provider, step);
      case _ExCategory.strength:
      case _ExCategory.bodyweight:
        return _buildStrengthActiveScreen(provider, step, cat);
    }
  }

  Widget _buildStrengthActiveScreen(
      FitnessProvider provider, _WorkoutStep step, _ExCategory cat) {
    final currentConfig = _config[step.exerciseIndex];
    final exData = provider.exercises.firstWhere(
          (e) => e.id == currentConfig.exercise.exerciseId,
      orElse: () => Exercise(id: '', name: '???'),
    );
    final set = currentConfig.sets[step.setIndex];
    final format = _resolveFormatOf(step.exerciseIndex);

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildActiveTopBar(step),
            _buildExercisesStrip(provider, step),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                        flex: 3,
                        child: _buildHeroSetRing(step, currentConfig)),
                    Flexible(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ExImage(
                            url: exData.imageUrl,
                            size: 52,
                            radius: 14,
                            bg: _P.greenSoft,
                            border: _P.greenDeep.withOpacity(0.20),
                            fallbackEmoji: exData.exerciseType.emoji,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  exData.name,
                                  style: _T.title1.copyWith(fontSize: 20),
                                  textAlign: TextAlign.start,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                if (exData.muscleGroups.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: _P.greenSoft,
                                        borderRadius:
                                        BorderRadius.circular(16)),
                                    child: Text(
                                      '${_categoryLabel(cat)} · ${exData.muscleGroups.first.displayName}',
                                      style: _T.overline.copyWith(
                                          color: _P.greenText, fontSize: 9),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(flex: 3, child: _buildPrimaryMetrics(cat, set)),
                    Flexible(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 13, color: _P.textMuted),
                          const SizedBox(width: 5),
                          Text('${_formatSeconds(_restSeconds)} отдых после подхода',
                              style: _T.caption.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildActiveBottomButtons(step, format, cat),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSetRing(_WorkoutStep step, ConfiguredExercise config) {
    final totalSets = config.sets.length;
    final currentSet = step.setIndex + 1;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 7,
              valueColor:
              AlwaysStoppedAnimation(_P.border.withOpacity(0.5)),
            ),
          ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: currentSet / totalSets,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              valueColor: const AlwaysStoppedAnimation(_P.greenDeep),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ТЕКУЩИЙ ПОДХОД', style: _T.overline),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  '$currentSet/$totalSets',
                  style: _T.number.copyWith(
                      fontSize: 52,
                      letterSpacing: -2,
                      color: _P.text),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'из $totalSets',
                style: _T.caption
                    .copyWith(color: _P.greenText, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryMetrics(_ExCategory cat, SetConfig set) {
    String v1, l1, u1, v2, l2, u2;
    switch (cat) {
      case _ExCategory.strength:
        v1 = set.weight.toStringAsFixed(0);
        l1 = 'Вес';
        u1 = 'кг';
        v2 = '${set.reps}';
        l2 = 'Повторы';
        u2 = 'раз';
        break;
      case _ExCategory.bodyweight:
        v1 = '${set.reps}';
        l1 = 'Повторы';
        u1 = 'раз';
        v2 = '';
        l2 = '';
        u2 = '';
        break;
      case _ExCategory.hold:
        v1 = _formatSeconds(set.holdSeconds ?? 0);
        l1 = 'Удержание';
        u1 = '';
        v2 = '';
        l2 = '';
        u2 = '';
        break;
      case _ExCategory.timedSets:
        v1 = _formatSeconds(set.duration);
        l1 = 'Время';
        u1 = '';
        v2 = '${set.reps}';
        l2 = 'Повторы';
        u2 = 'раз';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
            child: _buildMetricCard(v1, u1, l1, _P.greenSoft, _P.greenText,
                Icons.fitness_center_rounded)),
        if (v2.isNotEmpty) ...[
          const SizedBox(width: 10),
          Expanded(
              child: _buildMetricCard(v2, u2, l2, _P.lavenderSoft,
                  _P.lavenderDeep, Icons.repeat_rounded)),
        ],
      ],
    );
  }

  Widget _buildMetricCard(String value, String unit, String label, Color bg,
      Color iconColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(7)),
                child: Icon(icon, size: 12, color: iconColor),
              ),
              const SizedBox(width: 6),
              Text(label, style: _T.caption.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: _T.number
                        .copyWith(fontSize: 36, color: _P.text)),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(unit, style: _T.caption.copyWith(fontSize: 10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTopBar(_WorkoutStep step) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showExitDialog(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _P.divider),
              ),
              child: const Icon(Icons.close_rounded, color: _P.text, size: 18),
            ),
          ),
          const Spacer(),
          Text('Шаг ${_currentStepIndex + 1} из ${_steps.length}',
              style: _T.headline.copyWith(fontSize: 14)),
          const Spacer(),
          GestureDetector(
            onTap: _skipExercise,
            child: Container(
              width: 40,
              height: 36,
              alignment: Alignment.center,
              child: Text('Пропуск',
                  style: _T.headline
                      .copyWith(color: _P.textMuted, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesStrip(
      FitnessProvider provider, _WorkoutStep current) {
    final uniqueIndices = <int>[];
    for (final s in _steps) {
      if (!uniqueIndices.contains(s.exerciseIndex)) {
        uniqueIndices.add(s.exerciseIndex);
      }
    }

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: uniqueIndices.length,
        itemBuilder: (context, i) {
          final exIdx = uniqueIndices[i];
          final exData = provider.exercises.firstWhere(
                (e) => e.id == _config[exIdx].exercise.exerciseId,
            orElse: () => Exercise(id: '', name: '???'),
          );
          final isCurrent = exIdx == current.exerciseIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isCurrent ? _P.greenSoft : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? _P.greenDeep : _P.border,
                  width: isCurrent ? 2.2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: _ExImage(
                url: exData.imageUrl,
                size: 52,
                radius: 26,
                bg: Colors.transparent,
                fallbackEmoji: exData.exerciseType.emoji,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveBottomButtons(
      _WorkoutStep step, ExerciseFormat format, _ExCategory cat) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 10, 20, 10 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _skipSet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _P.text,
                  side: const BorderSide(color: _P.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child:
                Text('Пропустить', style: _T.headline.copyWith(fontSize: 13)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => _showSetCompletionSheet(format, cat),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _P.greenDeep,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text('Готово',
                        style: _T.headline
                            .copyWith(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TIMERS ────────────────────────────────────────
  Widget _buildCardioExecution(FitnessProvider provider, _WorkoutStep step) {
    final ex = provider.exercises.firstWhere(
          (e) => e.id == _config[step.exerciseIndex].exercise.exerciseId,
      orElse: () => Exercise(id: '', name: ''),
    );
    final set = _config[step.exerciseIndex].sets[step.setIndex];
    return _CardioTimerScreen(
      exerciseName: ex.name,
      exerciseImageUrl: ex.imageUrl,
      plannedDistance: set.distance ?? 0,
      plannedDuration: set.duration,
      setNumber: step.setIndex + 1,
      totalSets: _config[step.exerciseIndex].sets.length,
      onComplete: (distance, duration) {
        set.distance = distance;
        set.duration = duration;
        _saveCompletedSet(_SetResult(
          action: _SetAction.done,
          reps: 0,
          weight: 0,
          isWarmup: false,
          distance: distance,
          duration: duration,
          format: ExerciseFormat.continuous,
        ));
        _moveToNext();
      },
      onSkip: _skipSet,
      onExit: () => _showExitDialog(context),
    );
  }

  Widget _buildCombatExecution(FitnessProvider provider, _WorkoutStep step) {
    final ex = provider.exercises.firstWhere(
          (e) => e.id == _config[step.exerciseIndex].exercise.exerciseId,
      orElse: () => Exercise(id: '', name: ''),
    );
    final set = _config[step.exerciseIndex].sets[0];
    return _CombatTimerScreen(
      exerciseName: ex.name,
      exerciseImageUrl: ex.imageUrl,
      totalRounds: set.rounds ?? 5,
      roundDurationSec: set.roundDuration ?? 180,
      restBetweenSec: set.restBetweenRounds ?? 60,
      onComplete: (completedRounds) {
        set.rounds = completedRounds;
        _saveCompletedSet(_SetResult(
          action: _SetAction.done,
          reps: 0,
          weight: 0,
          isWarmup: false,
          rounds: completedRounds,
          roundDuration: set.roundDuration,
          restBetweenRounds: set.restBetweenRounds,
          format: ExerciseFormat.rounds,
        ));
        _moveToNext();
      },
      onSkip: _skipSet,
      onExit: () => _showExitDialog(context),
    );
  }

  Widget _buildHoldExecution(FitnessProvider provider, _WorkoutStep step) {
    final ex = provider.exercises.firstWhere(
          (e) => e.id == _config[step.exerciseIndex].exercise.exerciseId,
      orElse: () => Exercise(id: '', name: ''),
    );
    final set = _config[step.exerciseIndex].sets[step.setIndex];
    return _HoldTimerScreen(
      exerciseName: ex.name,
      exerciseImageUrl: ex.imageUrl,
      plannedSeconds: set.holdSeconds ?? 30,
      setNumber: step.setIndex + 1,
      totalSets: _config[step.exerciseIndex].sets.length,
      onComplete: (actualSeconds) {
        set.holdSeconds = actualSeconds;
        _saveCompletedSet(_SetResult(
          action: _SetAction.done,
          reps: 0,
          weight: 0,
          isWarmup: false,
          holdSeconds: actualSeconds,
          format: ExerciseFormat.hold,
        ));
        _moveToNext();
      },
      onSkip: _skipSet,
      onExit: () => _showExitDialog(context),
    );
  }

  Widget _buildTimedSetsExecution(
      FitnessProvider provider, _WorkoutStep step) {
    final ex = provider.exercises.firstWhere(
          (e) => e.id == _config[step.exerciseIndex].exercise.exerciseId,
      orElse: () => Exercise(id: '', name: ''),
    );
    final set = _config[step.exerciseIndex].sets[step.setIndex];
    return _TimedSetsTimerScreen(
      exerciseName: ex.name,
      exerciseImageUrl: ex.imageUrl,
      plannedDuration: set.duration,
      plannedReps: set.reps,
      setNumber: step.setIndex + 1,
      totalSets: _config[step.exerciseIndex].sets.length,
      onComplete: (duration, reps) {
        set.duration = duration;
        set.reps = reps;
        _saveCompletedSet(_SetResult(
          action: _SetAction.done,
          reps: reps,
          weight: 0,
          isWarmup: false,
          duration: duration,
          format: ExerciseFormat.timedSets,
        ));
        _moveToNext();
      },
      onSkip: _skipSet,
      onExit: () => _showExitDialog(context),
    );
  }

  Future<void> _showSetCompletionSheet(
      ExerciseFormat format, _ExCategory cat) async {
    final step = _currentStep;
    if (step == null) return;
    final config = _config[step.exerciseIndex];
    final set = config.sets[step.setIndex];

    final result = await showModalBottomSheet<_SetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SetCompletionSheet(
        format: format,
        category: cat,
        plannedSet: set,
        isWarmup: set.isWarmup,
      ),
    );

    if (result == null) return;
    switch (result.action) {
      case _SetAction.done:
        _saveCompletedSet(result);
        _moveToNext();
        break;
      case _SetAction.skip:
        _skipSet();
        break;
      case _SetAction.repeat:
        break;
    }
  }

  // ══════════════════════════════════════════════════════════
  // REST SCREEN
  // ══════════════════════════════════════════════════════════
  Widget _buildRestScreen(FitnessProvider provider) {
    final step = _currentStep;
    final nextConfig = step != null ? _config[step.exerciseIndex] : null;
    final nextExData = step != null
        ? provider.exercises.firstWhere(
          (e) => e.id == nextConfig!.exercise.exerciseId,
      orElse: () => Exercise(id: '', name: '???'),
    )
        : null;

    return _RestTimerScreen(
      seconds: _restSeconds,
      nextExerciseName: nextExData?.name ?? 'Следующее упражнение',
      nextExerciseEmoji: nextExData?.exerciseType.emoji ?? '🏋️',
      nextExerciseImageUrl: nextExData?.imageUrl,
      onComplete: () => setState(() => _phase = WorkoutPhase.active),
      onSkip: () => setState(() => _phase = WorkoutPhase.active),
      onExit: () => _showExitDialog(context),
    );
  }

  // ══════════════════════════════════════════════════════════
  // COMPLETED SCREEN
  // ══════════════════════════════════════════════════════════
  Widget _buildCompletedScreen() {
    final provider = context.read<FitnessProvider>();
    final grouped = <Exercise, List<CompletedSetData>>{};

    for (final config in _config) {
      final exData = provider.exercises.firstWhere(
            (e) => e.id == config.exercise.exerciseId,
        orElse: () => Exercise(id: '', name: '???'),
      );
      final list = _completedData[config.exercise.exerciseId] ?? [];
      if (list.isNotEmpty) grouped[exData] = list;
    }

    final totalExercises = grouped.length;
    final totalSets = _totalCompletedSets();
    final duration =
        DateTime.now().difference(_startTime ?? DateTime.now()).inMinutes;

    double totalVolume = 0;
    for (final entry in grouped.entries) {
      final list = entry.value;
      for (final s in list) {
        if (s.weight > 0 && s.reps > 0) totalVolume += s.weight * s.reps;
      }
    }

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: _P.greenSoft,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _P.greenDeep.withOpacity(0.22),
                        blurRadius: 40,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: _P.greenDeep, size: 42),
                ),
              ),
              const SizedBox(height: 18),
              Text('Тренировка завершена',
                  style: _T.title1.copyWith(fontSize: 22),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                'Чуть сильнее. Чуть ближе к цели.',
                style: _T.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE4F0E8),
                      Color(0xFFF4F8F5),
                      Color(0xFFEEEBF7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Row(
                  children: [
                    _buildHeroStat('$totalExercises', 'УПРАЖНЕНИЙ', _P.greenDeep),
                    _heroStatDivider(),
                    _buildHeroStat('$totalSets', 'ПОДХОДОВ', _P.lavenderDeep),
                    _heroStatDivider(),
                    _buildHeroStat('$duration', 'МИНУТ', _P.peachDeep),
                  ],
                ),
              ),

              if (totalVolume > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _P.peachSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center_rounded,
                          color: _P.peachDeep, size: 16),
                      const SizedBox(width: 8),
                      Text('Общий объём',
                          style: _T.caption.copyWith(color: _P.text)),
                      const Spacer(),
                      Text(
                        '${_formatVolume(totalVolume)} кг',
                        style: _T.number
                            .copyWith(fontSize: 15, color: _P.peachDeep),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ваша тренировка',
                      style: _T.headline.copyWith(fontSize: 14)),
                  Text('${grouped.length} упр.', style: _T.caption),
                ],
              ),
              const SizedBox(height: 10),

              ...grouped.entries.map((entry) {
                final exercise = entry.key;
                final sets = entry.value.where((s) => !s.isWarmup).toList();
                if (sets.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _P.divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ExImage(
                        url: exercise.imageUrl,
                        size: 40,
                        radius: 10,
                        bg: _P.greenSoft,
                        fallbackEmoji: exercise.exerciseType.emoji,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: _T.headline.copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: sets.map((s) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _P.bg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s.displaySummary,
                                    style: _T.caption.copyWith(fontSize: 9),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.check_rounded,
                            color: _P.greenDeep, size: 16),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 12, color: _P.textMuted),
                  const SizedBox(width: 5),
                  Text('Тренировка сохранена', style: _T.caption),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _P.greenDeep,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('На главную',
                      style:
                      _T.headline.copyWith(color: Colors.white, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStat(String value, String label, Color accent) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: _T.number.copyWith(
              fontSize: 22,
              color: _P.text,
              letterSpacing: -0.7,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: _T.overline.copyWith(
                fontSize: 8, color: accent, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _heroStatDivider() {
    return Container(width: 1, height: 28, color: _P.divider);
  }

  String _formatVolume(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  // ══════════════════════════════════════════════════════════
  // PRE-WORKOUT DIALOG
  // ══════════════════════════════════════════════════════════
  Future<void> _showPreWorkoutDialog() async {
    var energy = 5.0;
    var sleep = 5.0;
    var motivation = 5.0;
    final notesController = TextEditingController();
    File? selectedPhoto;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                      height: 4,
                      decoration: BoxDecoration(
                          color: _P.border,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('ПЕРЕД ТРЕНИРОВКОЙ', style: _T.overline),
                  const SizedBox(height: 3),
                  Text('Как настроение?',
                      style: _T.title2.copyWith(fontSize: 18)),
                  const SizedBox(height: 20),
                  _buildMoodSliderRow(
                      '⚡', 'Энергия', energy, (v) => setSheetState(() => energy = v)),
                  const SizedBox(height: 10),
                  _buildMoodSliderRow(
                      '😴', 'Сон', sleep, (v) => setSheetState(() => sleep = v)),
                  const SizedBox(height: 10),
                  _buildMoodSliderRow('🎯', 'Мотивация', motivation,
                          (v) => setSheetState(() => motivation = v)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Заметки...',
                      hintStyle: _T.caption,
                      filled: true,
                      fillColor: _P.bg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.gallery, imageQuality: 80);
                      if (image != null) {
                        setSheetState(() => selectedPhoto = File(image.path));
                      }
                    },
                    child: Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _P.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _P.divider),
                      ),
                      child: selectedPhoto != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(selectedPhoto!,
                            fit: BoxFit.cover),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_rounded,
                              color: _P.textMuted, size: 24),
                          const SizedBox(height: 6),
                          Text('Добавить фото', style: _T.caption),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _moodEnergy = energy.toInt();
                        _moodSleep = sleep.toInt();
                        _moodMotivation = motivation.toInt();
                        _moodNotes = notesController.text.isNotEmpty
                            ? notesController.text
                            : null;
                        _workoutPhotoPath = selectedPhoto?.path;
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _P.greenDeep,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('НАЧАТЬ',
                          style: _T.headline
                              .copyWith(color: Colors.white, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSliderRow(
      String emoji, String label, double value, Function(double) onChanged) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        SizedBox(
            width: 72, child: Text(label, style: _T.body.copyWith(fontSize: 12))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _P.greenDeep,
              inactiveTrackColor: _P.greenSoft,
              thumbColor: _P.greenDeep,
              trackHeight: 3,
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
                value: value,
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: onChanged),
          ),
        ),
        Text('${value.toInt()}',
            style: _T.headline.copyWith(fontSize: 13)),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // LOGIC & HELPERS
  // ══════════════════════════════════════════════════════════
  void _saveCompletedSet(_SetResult result) {
    final step = _currentStep;
    if (step == null) return;
    final config = _config[step.exerciseIndex];
    final key = config.exercise.exerciseId;
    _completedData.putIfAbsent(key, () => []);
    _completedData[key]!.add(CompletedSetData(
      exerciseIndex: step.exerciseIndex,
      setIndex: step.setIndex,
      reps: result.reps,
      weight: result.weight,
      duration: result.duration ?? 0,
      intensity: (result.intensity ?? 0).toInt(),
      rpe: 0,
      isWarmup: result.isWarmup,
      distance: result.distance,
      pace: result.pace,
      heartRate: result.heartRate,
      calories: result.calories,
      incline: result.incline,
      resistance: result.resistance,
      rounds: result.rounds,
      roundDuration: result.roundDuration,
      restBetweenRounds: result.restBetweenRounds,
      punches: result.punches,
      holdSeconds: result.holdSeconds,
      tempo: result.tempo,
      format: result.format,
    ));
  }

  void _moveToNext() {
    setState(() {
      _currentStepIndex++;
      if (_currentStepIndex >= _steps.length) {
        _finishWorkout();
      } else {
        _phase = WorkoutPhase.rest;
      }
    });
  }

  void _skipSet() {
    setState(() => _currentStepIndex++);
    if (_currentStepIndex >= _steps.length) _finishWorkout();
  }

  void _skipExercise() {
    final step = _currentStep;
    if (step == null) return;
    setState(() {
      int next = _currentStepIndex + 1;
      while (next < _steps.length &&
          _steps[next].exerciseIndex == step.exerciseIndex &&
          _steps[next].circuitNumber == step.circuitNumber) {
        next++;
      }
      _currentStepIndex = next;
    });
    if (_currentStepIndex >= _steps.length) _finishWorkout();
  }

  int _totalCompletedSets() {
    int total = 0;
    for (final list in _completedData.values) {
      total += list.where((s) => !s.isWarmup).length;
    }
    return total;
  }

  ExerciseFormat _formatToSaveForCategory(
      _ExCategory cat, ExerciseFormat fallback) {
    switch (cat) {
      case _ExCategory.cardio:
        return ExerciseFormat.continuous;
      case _ExCategory.combat:
        return ExerciseFormat.rounds;
      case _ExCategory.hold:
        return ExerciseFormat.hold;
      case _ExCategory.timedSets:
        return ExerciseFormat.timedSets;
      case _ExCategory.strength:
      case _ExCategory.bodyweight:
        return ExerciseFormat.setsReps;
    }
  }

  Future<void> _finishWorkout() async {
    if (_isFinishing ||
        _phase == WorkoutPhase.completed ||
        _savedLogId != null) {
      return;
    }
    if (_completedData.isEmpty) {
      setState(() => _phase = WorkoutPhase.completed);
      return;
    }
    _isFinishing = true;

    try {
      final provider = context.read<FitnessProvider>();
      final exercisesLog = <WorkoutExercise>[];

      for (final config in _config) {
        final exerciseId = config.exercise.exerciseId;
        final completedSets = _completedData[exerciseId] ?? [];
        final idx = _config.indexOf(config);
        final cat = _catOf(idx);
        final format = _formatToSaveForCategory(cat, _resolveFormatOf(idx));
        final sets = <ExerciseSet>[];

        for (int i = 0; i < config.sets.length; i++) {
          final planned = config.sets[i];
          final actual = completedSets.firstWhere(
                (cs) => cs.setIndex == i,
            orElse: () => CompletedSetData(
              exerciseIndex: 0,
              setIndex: i,
              reps: planned.reps,
              weight: planned.weight,
              duration: planned.duration,
              intensity: planned.intensity,
              rpe: 0,
              isWarmup: planned.isWarmup,
              format: format,
              holdSeconds: planned.holdSeconds,
              distance: planned.distance,
              rounds: planned.rounds,
              roundDuration: planned.roundDuration,
              restBetweenRounds: planned.restBetweenRounds,
            ),
          );

          sets.add(ExerciseSet(
            setNumber: i + 1,
            reps: actual.reps,
            weight: actual.weight,
            rpe: actual.rpe == 0 ? null : actual.rpe,
            isWarmup: actual.isWarmup,
            status: completedSets.any((cs) => cs.setIndex == i)
                ? SetStatus.completed
                : SetStatus.skipped,
            duration: actual.duration > 0 ? actual.duration : null,
            distance: actual.distance,
            pace: actual.pace,
            heartRate: actual.heartRate,
            calories: actual.calories,
            incline: actual.incline,
            resistance: actual.resistance,
            rounds: actual.rounds,
            roundDuration: actual.roundDuration,
            restBetweenRounds: actual.restBetweenRounds,
            punches: actual.punches,
            holdSeconds: actual.holdSeconds,
            tempo: actual.tempo,
            intensity:
            actual.intensity > 0 ? actual.intensity.toDouble() : null,
          ));
        }

        exercisesLog.add(WorkoutExercise(
          id: config.exercise.id,
          exerciseId: exerciseId,
          order: config.exercise.order,
          sets: sets,
          groupType: config.exercise.groupType,
          restBetweenSeconds: config.exercise.restBetweenSeconds,
          format: format,
        ));
      }

      final totalByMetric = FitnessHelpers.calculateTotalByMetric(
        exercisesLog,
        findExercise: (id) => provider.exercises.firstWhere(
              (e) => e.id == id,
          orElse: () => Exercise(id: '', name: ''),
        ),
      );
      final totalVolume = totalByMetric['kg'] ?? 0.0;
      final avgRpe = FitnessHelpers.calculateAverageRpe(exercisesLog);

      final logId = DateTime.now().millisecondsSinceEpoch.toString();
      final log = WorkoutLog(
        id: logId,
        date: DateTime.now(),
        programId: widget.day.programId,
        dayNumber: widget.day.dayNumber,
        status: WorkoutDayStatus.completed,
        startTime: _startTime,
        endTime: DateTime.now(),
        exercisesLog: exercisesLog,
        totalRestTime: null,
        totalVolume: totalVolume,
        totalByMetric: totalByMetric,
        avgRpe: avgRpe,
        bodyWeight: null,
        moodEnergy: _moodEnergy,
        moodSleep: _moodSleep,
        moodMotivation: _moodMotivation,
        moodNotes: _moodNotes,
        workoutPhotoPath: _workoutPhotoPath,
      );

      await provider.saveWorkoutLogDirect(log);
      _savedLogId = logId;
      if (mounted) setState(() => _phase = WorkoutPhase.completed);
    } catch (e) {
      _isFinishing = false;
      if (mounted) setState(() => _phase = WorkoutPhase.completed);
    }
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Прервать тренировку?',
            style: _T.title2.copyWith(fontSize: 16)),
        content: Text('Прогресс не будет сохранён', style: _T.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Продолжить',
                  style: _T.headline.copyWith(fontSize: 13))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Прервать',
                style: _T.headline
                    .copyWith(color: _P.pinkDeep, fontSize: 13)),
          ),
        ],
      ),
    );
    if (result == true && mounted) Navigator.pop(context);
    return result ?? false;
  }

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '0с';
    if (seconds < 60) return '${seconds}с';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0 ? '${m}м ${s}с' : '${m}м';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════
enum WorkoutPhase { setup, active, rest, completed }

class ConfiguredExercise {
  final WorkoutExercise exercise;
  final List<SetConfig> sets;
  ConfiguredExercise({required this.exercise, required this.sets});
}

class SetConfig {
  int reps;
  double weight;
  int duration;
  int intensity;
  bool isWarmup;

  double? rpe;
  int? restSeconds;
  double? distance;
  double? pace;
  int? heartRate;
  int? calories;
  double? incline;
  double? resistance;
  int? rounds;
  int? roundDuration;
  int? restBetweenRounds;
  int? punches;
  int? holdSeconds;
  String? tempo;

  SetConfig({
    this.reps = 10,
    this.weight = 0,
    this.duration = 60,
    this.intensity = 5,
    this.isWarmup = false,
    this.rpe,
    this.restSeconds,
    this.distance,
    this.pace,
    this.heartRate,
    this.calories,
    this.incline,
    this.resistance,
    this.rounds,
    this.roundDuration,
    this.restBetweenRounds,
    this.punches,
    this.holdSeconds,
    this.tempo,
  });

  factory SetConfig.fromExerciseSet(ExerciseSet s) {
    return SetConfig(
      reps: s.reps,
      weight: s.weight,
      duration: s.effectiveDuration ?? 60,
      intensity: (s.intensity ?? 5).toInt(),
      isWarmup: s.isWarmup,
      rpe: s.rpe,
      restSeconds: s.restSeconds,
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
    );
  }

  double? metricValue(ExerciseMetric m) {
    switch (m) {
      case ExerciseMetric.reps:
        return reps > 0 ? reps.toDouble() : null;
      case ExerciseMetric.weight:
        return weight > 0 ? weight : null;
      case ExerciseMetric.rpe:
        return rpe;
      case ExerciseMetric.restSeconds:
        return restSeconds?.toDouble();
      case ExerciseMetric.duration:
        return duration > 0 ? duration.toDouble() : null;
      case ExerciseMetric.distance:
        return distance;
      case ExerciseMetric.pace:
        return pace;
      case ExerciseMetric.heartRate:
        return heartRate?.toDouble();
      case ExerciseMetric.calories:
        return calories?.toDouble();
      case ExerciseMetric.incline:
        return incline;
      case ExerciseMetric.resistance:
        return resistance;
      case ExerciseMetric.rounds:
        return rounds?.toDouble();
      case ExerciseMetric.roundDuration:
        return roundDuration?.toDouble();
      case ExerciseMetric.restBetweenRounds:
        return restBetweenRounds?.toDouble();
      case ExerciseMetric.punches:
        return punches?.toDouble();
      case ExerciseMetric.holdSeconds:
        return holdSeconds?.toDouble();
      case ExerciseMetric.tempo:
        return null;
      case ExerciseMetric.intensity:
        return intensity.toDouble();
    }
  }

  ExerciseSet toExerciseSet(int setNumber) {
    return ExerciseSet(
      setNumber: setNumber,
      reps: reps,
      weight: weight,
      rpe: rpe,
      restSeconds: restSeconds,
      isWarmup: isWarmup,
      status: SetStatus.pending,
      duration: duration > 0 ? duration : null,
      distance: distance,
      pace: pace,
      heartRate: heartRate,
      calories: calories,
      incline: incline,
      resistance: resistance,
      rounds: rounds,
      roundDuration: roundDuration,
      restBetweenRounds: restBetweenRounds,
      punches: punches,
      holdSeconds: holdSeconds,
      tempo: tempo,
      intensity: intensity.toDouble(),
    );
  }
}

class CompletedSetData {
  final int exerciseIndex;
  final int setIndex;
  final int reps;
  final double weight;
  final int duration;
  final int intensity;
  final double rpe;
  final bool isWarmup;
  final double? distance;
  final double? pace;
  final int? heartRate;
  final int? calories;
  final double? incline;
  final double? resistance;
  final int? rounds;
  final int? roundDuration;
  final int? restBetweenRounds;
  final int? punches;
  final int? holdSeconds;
  final String? tempo;
  final ExerciseFormat? format;

  CompletedSetData({
    required this.exerciseIndex,
    required this.setIndex,
    required this.reps,
    required this.weight,
    required this.duration,
    required this.intensity,
    required this.rpe,
    required this.isWarmup,
    this.distance,
    this.pace,
    this.heartRate,
    this.calories,
    this.incline,
    this.resistance,
    this.rounds,
    this.roundDuration,
    this.restBetweenRounds,
    this.punches,
    this.holdSeconds,
    this.tempo,
    this.format,
  });

  String get displaySummary {
    if (format == null) {
      return weight > 0
          ? '${weight.toStringAsFixed(0)}кг x $reps'
          : '$reps';
    }
    return FitnessHelpers.formatSetForDisplay(
      ExerciseSet(
        setNumber: 1,
        reps: reps,
        weight: weight,
        duration: duration > 0 ? duration : null,
        distance: distance,
        rounds: rounds,
        roundDuration: roundDuration,
        holdSeconds: holdSeconds,
        intensity: intensity > 0 ? intensity.toDouble() : null,
      ),
      format!,
    );
  }
}

class _WorkoutStep {
  final int exerciseIndex;
  final int setIndex;
  final int circuitNumber;
  const _WorkoutStep({
    required this.exerciseIndex,
    required this.setIndex,
    this.circuitNumber = 0,
  });
}

// ══════════════════════════════════════════════════════════
// FIGMA STEPPER
// ══════════════════════════════════════════════════════════
class _FigmaStepper extends StatefulWidget {
  final double value;
  final double step;
  final bool isDecimal;
  final List<num>? quickPicks;
  final String Function(double)? formatValue;
  final ValueChanged<double> onChanged;

  const _FigmaStepper({
    required this.value,
    required this.step,
    required this.isDecimal,
    this.quickPicks,
    this.formatValue,
    required this.onChanged,
  });

  @override
  State<_FigmaStepper> createState() => _FigmaStepperState();
}

class _FigmaStepperState extends State<_FigmaStepper> {
  late TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.value));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _FigmaStepper old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_focus.hasFocus) {
      final expected = _fmt(widget.value);
      if (_ctrl.text != expected) _ctrl.text = expected;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (widget.formatValue != null) return widget.formatValue!(v);
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  void _bump(double dir) {
    HapticFeedback.selectionClick();
    final nv = (widget.value + dir * widget.step).clamp(0.0, 9999.0);
    widget.onChanged(nv);
    _ctrl.text = _fmt(nv);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          decoration: BoxDecoration(
              color: _P.bg, borderRadius: BorderRadius.circular(9)),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _bump(-1),
                child: Container(
                  width: 34,
                  height: 38,
                  alignment: Alignment.center,
                  child: const Icon(Icons.remove,
                      size: 14, color: _P.textMuted),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  textAlign: TextAlign.center,
                  keyboardType:
                  TextInputType.numberWithOptions(decimal: widget.isDecimal),
                  style: _T.number.copyWith(fontSize: 14, color: _P.text),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    if (v.isEmpty) {
                      widget.onChanged(0);
                      return;
                    }
                    final parsed = widget.isDecimal
                        ? double.tryParse(v.replaceAll(',', '.'))
                        : int.tryParse(v)?.toDouble();
                    if (parsed != null) {
                      widget.onChanged(parsed.clamp(0.0, 9999.0));
                    }
                  },
                ),
              ),
              GestureDetector(
                onTap: () => _bump(1),
                child: Container(
                  width: 34,
                  height: 38,
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, size: 14, color: _P.greenDeep),
                ),
              ),
            ],
          ),
        ),
        if (widget.quickPicks != null && widget.quickPicks!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: widget.quickPicks!.map((p) {
                final nv = p.toDouble();
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onChanged(nv);
                    _ctrl.text = _fmt(nv);
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: _P.bg,
                        borderRadius: BorderRadius.circular(5)),
                    child: Text(_fmt(nv),
                        style:
                        _T.caption.copyWith(fontSize: 9, color: _P.text)),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
// SET COMPLETION SHEET
// ══════════════════════════════════════════════════════════
enum _SetAction { done, skip, repeat }

class _SetResult {
  final _SetAction action;
  final int reps;
  final double weight;
  final int? duration;
  final double? intensity;
  final bool isWarmup;
  final ExerciseFormat? format;
  final double? distance;
  final double? pace;
  final double? incline;
  final double? resistance;
  final int? heartRate;
  final int? calories;
  final int? rounds;
  final int? roundDuration;
  final int? restBetweenRounds;
  final int? punches;
  final int? holdSeconds;
  final String? tempo;

  _SetResult({
    required this.action,
    required this.reps,
    required this.weight,
    required this.isWarmup,
    this.duration,
    this.intensity,
    this.format,
    this.distance,
    this.pace,
    this.heartRate,
    this.calories,
    this.incline,
    this.resistance,
    this.rounds,
    this.roundDuration,
    this.restBetweenRounds,
    this.punches,
    this.holdSeconds,
    this.tempo,
  });
}

class _SetCompletionSheet extends StatefulWidget {
  final ExerciseFormat format;
  final _ExCategory category;
  final SetConfig plannedSet;
  final bool isWarmup;

  const _SetCompletionSheet({
    required this.format,
    required this.category,
    required this.plannedSet,
    required this.isWarmup,
  });

  @override
  State<_SetCompletionSheet> createState() => _SetCompletionSheetState();
}

class _SetCompletionSheetState extends State<_SetCompletionSheet> {
  late SetConfig _actual;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _actual = SetConfig.fromExerciseSet(widget.plannedSet.toExerciseSet(1));
    _initControllers();
  }

  void _initControllers() {
    for (final m in _metricsToShow()) {
      if (m == ExerciseMetric.intensity || m == ExerciseMetric.tempo) continue;
      final v = _actual.metricValue(m);
      _controllers[m.name] = TextEditingController(
        text: v != null && v != 0
            ? (m.isDecimal
            ? v.toStringAsFixed(m == ExerciseMetric.distance ? 2 : 1)
            : v.toStringAsFixed(0))
            : '',
      );
    }
  }

  List<ExerciseMetric> _metricsToShow() {
    switch (widget.category) {
      case _ExCategory.strength:
        return [ExerciseMetric.weight, ExerciseMetric.reps];
      case _ExCategory.bodyweight:
        return [ExerciseMetric.reps];
      case _ExCategory.hold:
        return [ExerciseMetric.holdSeconds];
      case _ExCategory.timedSets:
        return [ExerciseMetric.duration, ExerciseMetric.reps];
      case _ExCategory.cardio:
        return [ExerciseMetric.distance, ExerciseMetric.duration];
      case _ExCategory.combat:
        return [ExerciseMetric.rounds, ExerciseMetric.roundDuration];
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(widget.category);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: _P.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('ПОДХОД ВЫПОЛНЕН?',
                style: _T.overline.copyWith(color: accent)),
            const SizedBox(height: 6),
            Text(_categoryLabel(widget.category),
                style: _T.title2.copyWith(fontSize: 17)),
            const SizedBox(height: 20),
            ..._metricsToShow().map((m) => _buildNumericField(m, accent)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _SetResult(
                          action: _SetAction.repeat,
                          reps: _actual.reps,
                          weight: _actual.weight,
                          isWarmup: _actual.isWarmup,
                          format: widget.format,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _P.text,
                        side: const BorderSide(color: _P.divider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('ПОВТОРИТЬ',
                          style: _T.headline.copyWith(fontSize: 12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _SetResult(
                          action: _SetAction.done,
                          reps: _actual.reps,
                          weight: _actual.weight,
                          isWarmup: _actual.isWarmup,
                          format: widget.format,
                          duration:
                          _actual.duration > 0 ? _actual.duration : null,
                          intensity: _actual.intensity.toDouble(),
                          distance: _actual.distance,
                          pace: _actual.pace,
                          heartRate: _actual.heartRate,
                          calories: _actual.calories,
                          incline: _actual.incline,
                          resistance: _actual.resistance,
                          rounds: _actual.rounds,
                          roundDuration: _actual.roundDuration,
                          restBetweenRounds: _actual.restBetweenRounds,
                          punches: _actual.punches,
                          holdSeconds: _actual.holdSeconds,
                          tempo: _actual.tempo,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _P.greenDeep,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('ВЫПОЛНЕНО',
                          style: _T.headline
                              .copyWith(color: Colors.white, fontSize: 12)),
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

  Widget _buildNumericField(ExerciseMetric m, Color accent) {
    final controller = _controllers[m.name];
    final step = _stepForMetric(m);
    final max = _maxForMetric(m);
    final value = _actual.metricValue(m) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(m.displayName.toUpperCase(),
                  style: _T.overline.copyWith(fontSize: 10))),
          Container(
            height: 42,
            decoration: BoxDecoration(
                color: _P.bg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    final nv = (value - step).clamp(0, max).toDouble();
                    _updateMetric(m, nv);
                    controller?.text = nv > 0 ? _fmt(nv, m) : '';
                  },
                  child: const SizedBox(
                      width: 36,
                      height: 42,
                      child: Icon(Icons.remove_rounded, size: 16)),
                ),
                SizedBox(
                  width: 56,
                  child: TextField(
                    controller: controller,
                    keyboardType:
                    TextInputType.numberWithOptions(decimal: m.isDecimal),
                    textAlign: TextAlign.center,
                    style: _T.headline.copyWith(fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) {
                      if (v.isEmpty) {
                        _updateMetric(m, 0);
                        return;
                      }
                      final parsed = m.isDecimal
                          ? double.tryParse(v.replaceAll(',', '.'))
                          : int.tryParse(v)?.toDouble();
                      if (parsed != null) {
                        _updateMetric(m, parsed.clamp(0, max).toDouble());
                      }
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final nv = (value + step).clamp(0, max).toDouble();
                    _updateMetric(m, nv);
                    controller?.text = _fmt(nv, m);
                  },
                  child: SizedBox(
                    width: 36,
                    height: 42,
                    child: Icon(Icons.add_rounded, size: 16, color: accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateMetric(ExerciseMetric m, double v) {
    setState(() {
      switch (m) {
        case ExerciseMetric.reps:
          _actual.reps = v.toInt();
          break;
        case ExerciseMetric.weight:
          _actual.weight = v;
          break;
        case ExerciseMetric.duration:
          _actual.duration = v.toInt();
          break;
        case ExerciseMetric.distance:
          _actual.distance = v;
          break;
        case ExerciseMetric.rounds:
          _actual.rounds = v.toInt();
          break;
        case ExerciseMetric.roundDuration:
          _actual.roundDuration = v.toInt();
          break;
        case ExerciseMetric.holdSeconds:
          _actual.holdSeconds = v.toInt();
          break;
        default:
          break;
      }
    });
  }

  String _fmt(double v, ExerciseMetric m) {
    if (m.isDecimal) {
      return v.toStringAsFixed(m == ExerciseMetric.distance ? 2 : 1);
    }
    return v.toStringAsFixed(0);
  }

  double _stepForMetric(ExerciseMetric m) {
    switch (m) {
      case ExerciseMetric.reps:
        return 1;
      case ExerciseMetric.weight:
        return 2.5;
      case ExerciseMetric.duration:
        return 15;
      case ExerciseMetric.distance:
        return 0.1;
      case ExerciseMetric.rounds:
        return 1;
      case ExerciseMetric.roundDuration:
        return 30;
      case ExerciseMetric.holdSeconds:
        return 15;
      default:
        return 1;
    }
  }

  double _maxForMetric(ExerciseMetric m) {
    switch (m) {
      case ExerciseMetric.reps:
        return 200;
      case ExerciseMetric.weight:
        return 500;
      case ExerciseMetric.duration:
        return 3600;
      case ExerciseMetric.distance:
        return 100;
      case ExerciseMetric.rounds:
        return 50;
      case ExerciseMetric.roundDuration:
        return 900;
      case ExerciseMetric.holdSeconds:
        return 600;
      default:
        return 10;
    }
  }
}

// ══════════════════════════════════════════════════════════
// REST TIMER SCREEN
// ══════════════════════════════════════════════════════════
class _RestTimerScreen extends StatefulWidget {
  final int seconds;
  final String nextExerciseName;
  final String nextExerciseEmoji;
  final String? nextExerciseImageUrl;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onExit;

  const _RestTimerScreen({
    required this.seconds,
    required this.nextExerciseName,
    required this.nextExerciseEmoji,
    this.nextExerciseImageUrl,
    required this.onComplete,
    required this.onSkip,
    required this.onExit,
  });

  @override
  State<_RestTimerScreen> createState() => _RestTimerScreenState();
}

class _RestTimerScreenState extends State<_RestTimerScreen> {
  late int _remaining;
  Timer? _timer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining > 0) {
        setState(() => _remaining--);
      } else if (!_completed) {
        timer.cancel();
        _completed = true;
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.seconds > 0
        ? (1 - _remaining / widget.seconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onExit,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _P.divider),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: _P.text, size: 18),
                    ),
                  ),
                  Text('Время отдыха',
                      style: _T.headline.copyWith(fontSize: 15)),
                  const Icon(Icons.volume_up_outlined,
                      color: _P.textMuted, size: 22),
                ],
              ),
            ),

            const Spacer(),

            Text('Сделай вдох.',
                style: _T.title1.copyWith(fontSize: 22),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('Отдых между подходами.',
                style: _T.body, textAlign: TextAlign.center),
            const SizedBox(height: 24),

            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 184,
                    height: 184,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 5,
                      valueColor:
                      AlwaysStoppedAnimation(_P.lavenderSoft),
                    ),
                  ),
                  SizedBox(
                    width: 184,
                    height: 184,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      valueColor:
                      const AlwaysStoppedAnimation(_P.lavenderDeep),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ВОССТАНОВЛЕНИЕ', style: _T.overline),
                      const SizedBox(height: 4),
                      Text(
                        _fmt(_remaining),
                        style: _T.number.copyWith(
                            fontSize: 44,
                            letterSpacing: -1.5,
                            color: _P.text),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'из ${_fmt(widget.seconds)}',
                        style: _T.caption
                            .copyWith(color: _P.lavenderDeep),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.waves_rounded, color: _P.textMuted, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Дыши ровно · восстанавливай силы',
                  style: _T.caption,
                ),
              ],
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _P.divider),
                  boxShadow: [
                    BoxShadow(
                      color: _P.greenDeep.withOpacity(0.05),
                      blurRadius: 16,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('ДАЛЕЕ', style: _T.overline),
                        const Spacer(),
                        Icon(Icons.arrow_forward_rounded,
                            size: 12, color: _P.textMuted),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _ExImage(
                          url: widget.nextExerciseImageUrl,
                          size: 52,
                          radius: 13,
                          bg: _P.greenSoft,
                          fallbackEmoji: widget.nextExerciseEmoji,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.nextExerciseName,
                                style:
                                _T.headline.copyWith(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text('Готовься',
                                  style: _T.caption
                                      .copyWith(color: _P.greenText)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: widget.onSkip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _P.text,
                    side: const BorderSide(color: _P.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Пропустить отдых',
                      style: _T.headline.copyWith(fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// IMMERSIVE TIMERS
// ══════════════════════════════════════════════════════════
class _HoldTimerScreen extends StatefulWidget {
  final String exerciseName;
  final String? exerciseImageUrl;
  final int plannedSeconds;
  final int setNumber;
  final int totalSets;
  final void Function(int) onComplete;
  final VoidCallback onSkip;
  final VoidCallback onExit;

  const _HoldTimerScreen({
    required this.exerciseName,
    this.exerciseImageUrl,
    required this.plannedSeconds,
    required this.setNumber,
    required this.totalSets,
    required this.onComplete,
    required this.onSkip,
    required this.onExit,
  });

  @override
  State<_HoldTimerScreen> createState() => _HoldTimerScreenState();
}

class _HoldTimerScreenState extends State<_HoldTimerScreen> {
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _watch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200),
            (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _watch.stop();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _P.yellowDeep;
    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onExit,
                    child: const Icon(Icons.close_rounded, size: 22),
                  ),
                  const Spacer(),
                  Text('СТАТИКА',
                      style: _T.overline.copyWith(color: accent)),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onSkip,
                    child: Text('Пропуск',
                        style: _T.caption.copyWith(color: _P.textMuted)),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _ExImage(
              url: widget.exerciseImageUrl,
              size: 80,
              radius: 20,
              bg: _P.yellowSoft,
              fallbackEmoji: '🧘',
            ),
            const SizedBox(height: 16),
            Text(widget.exerciseName,
                style: _T.title2.copyWith(fontSize: 17),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              _fmt(_watch.elapsed),
              style: _T.number
                  .copyWith(fontSize: 56, letterSpacing: -2.5),
            ),
            const SizedBox(height: 6),
            Text('ЦЕЛЬ ${widget.plannedSeconds}с', style: _T.caption),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      widget.onComplete(_watch.elapsed.inSeconds),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('ЗАПИСАТЬ',
                      style: _T.headline
                          .copyWith(color: Colors.white, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimedSetsTimerScreen extends StatefulWidget {
  final String exerciseName;
  final String? exerciseImageUrl;
  final int plannedDuration;
  final int plannedReps;
  final int setNumber;
  final int totalSets;
  final void Function(int, int) onComplete;
  final VoidCallback onSkip;
  final VoidCallback onExit;

  const _TimedSetsTimerScreen({
    required this.exerciseName,
    this.exerciseImageUrl,
    required this.plannedDuration,
    required this.plannedReps,
    required this.setNumber,
    required this.totalSets,
    required this.onComplete,
    required this.onSkip,
    required this.onExit,
  });

  @override
  State<_TimedSetsTimerScreen> createState() =>
      _TimedSetsTimerScreenState();
}

class _TimedSetsTimerScreenState extends State<_TimedSetsTimerScreen> {
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  late TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _watch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200),
            (_) => setState(() {}));
    _repsCtrl = TextEditingController(text: '${widget.plannedReps}');
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _watch.stop();
    _repsCtrl.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _P.lavenderDeep;
    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onExit,
                    child: const Icon(Icons.close_rounded, size: 22),
                  ),
                  const Spacer(),
                  Text('НА ВРЕМЯ',
                      style: _T.overline.copyWith(color: accent)),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onSkip,
                    child: Text('Пропуск',
                        style: _T.caption.copyWith(color: _P.textMuted)),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _ExImage(
              url: widget.exerciseImageUrl,
              size: 80,
              radius: 20,
              bg: _P.lavenderSoft,
              fallbackEmoji: '⏱️',
            ),
            const SizedBox(height: 16),
            Text(widget.exerciseName,
                style: _T.title2.copyWith(fontSize: 17),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              _fmt(_watch.elapsed),
              style: _T.number
                  .copyWith(fontSize: 56, letterSpacing: -2.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('ПОВТОРЫ:', style: _T.caption),
                  SizedBox(
                    width: 52,
                    child: TextField(
                      controller: _repsCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: _T.headline.copyWith(fontSize: 14),
                      decoration:
                      const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => widget.onComplete(
                    _watch.elapsed.inSeconds,
                    int.tryParse(_repsCtrl.text) ?? 0,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('ЗАПИСАТЬ',
                      style: _T.headline
                          .copyWith(color: Colors.white, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardioTimerScreen extends StatefulWidget {
  final String exerciseName;
  final String? exerciseImageUrl;
  final double plannedDistance;
  final int plannedDuration;
  final int setNumber;
  final int totalSets;
  final void Function(double, int) onComplete;
  final VoidCallback onSkip;
  final VoidCallback onExit;

  const _CardioTimerScreen({
    required this.exerciseName,
    this.exerciseImageUrl,
    required this.plannedDistance,
    required this.plannedDuration,
    required this.setNumber,
    required this.totalSets,
    required this.onComplete,
    required this.onSkip,
    required this.onExit,
  });

  @override
  State<_CardioTimerScreen> createState() => _CardioTimerScreenState();
}

class _CardioTimerScreenState extends State<_CardioTimerScreen> {
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  double _distance = 0;

  @override
  void initState() {
    super.initState();
    _distance = widget.plannedDistance;
    _watch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200),
            (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _watch.stop();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _P.skyDeep;
    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onExit,
                    child: const Icon(Icons.close_rounded, size: 22),
                  ),
                  const Spacer(),
                  Text('КАРДИО',
                      style: _T.overline.copyWith(color: accent)),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onSkip,
                    child: Text('Пропуск',
                        style: _T.caption.copyWith(color: _P.textMuted)),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _ExImage(
              url: widget.exerciseImageUrl,
              size: 80,
              radius: 20,
              bg: _P.skySoft,
              fallbackEmoji: '🏃',
            ),
            const SizedBox(height: 16),
            Text(widget.exerciseName,
                style: _T.title2.copyWith(fontSize: 17),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              _fmt(_watch.elapsed),
              style: _T.number
                  .copyWith(fontSize: 56, letterSpacing: -2.5),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('ДИСТАНЦИЯ: ', style: _T.caption),
                Text(
                  _distance.toStringAsFixed(2),
                  style: _T.headline.copyWith(color: accent, fontSize: 14),
                ),
                Text(' КМ', style: _T.caption),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      widget.onComplete(_distance, _watch.elapsed.inSeconds),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('ЗАПИСАТЬ',
                      style: _T.headline
                          .copyWith(color: Colors.white, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CombatTimerScreen extends StatefulWidget {
  final String exerciseName;
  final String? exerciseImageUrl;
  final int totalRounds;
  final int roundDurationSec;
  final int restBetweenSec;
  final void Function(int) onComplete;
  final VoidCallback onSkip;
  final VoidCallback onExit;

  const _CombatTimerScreen({
    required this.exerciseName,
    this.exerciseImageUrl,
    required this.totalRounds,
    required this.roundDurationSec,
    required this.restBetweenSec,
    required this.onComplete,
    required this.onSkip,
    required this.onExit,
  });

  @override
  State<_CombatTimerScreen> createState() => _CombatTimerScreenState();
}

class _CombatTimerScreenState extends State<_CombatTimerScreen> {
  int _currentRound = 1;
  int _remaining = 0;
  int _completed = 0;
  Timer? _timer;
  bool _paused = false;
  bool _isRest = false;
  late int _restSeconds;

  @override
  void initState() {
    super.initState();
    _restSeconds = widget.restBetweenSec;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _remaining = widget.roundDurationSec;
      _paused = false;
    });
    _tick();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused) return;
      setState(() {
        if (_remaining > 1) {
          _remaining--;
        } else {
          if (!_isRest && _currentRound < widget.totalRounds) {
            _isRest = true;
            _remaining = _restSeconds;
          } else if (_isRest) {
            _isRest = false;
            _currentRound++;
            _remaining = widget.roundDurationSec;
          } else {
            _completed = _currentRound;
            _timer?.cancel();
          }
        }
      });
    });
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isRest ? _P.greenDeep : _P.pinkDeep;
    final isDone = _completed > 0;

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onExit,
                    child: const Icon(Icons.close_rounded, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    _isRest ? 'ОТДЫХ' : 'РАУНД $_currentRound',
                    style: _T.overline.copyWith(color: accent),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onSkip,
                    child: Text('Пропуск',
                        style: _T.caption.copyWith(color: _P.textMuted)),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _ExImage(
              url: widget.exerciseImageUrl,
              size: 80,
              radius: 20,
              bg: _P.pinkSoft,
              fallbackEmoji: '🥊',
            ),
            const SizedBox(height: 16),
            Text(widget.exerciseName,
                style: _T.title2.copyWith(fontSize: 17),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              isDone ? 'ГОТОВО' : _fmt(_remaining),
              style: _T.number
                  .copyWith(fontSize: 56, letterSpacing: -2.5),
            ),
            const SizedBox(height: 12),
            if (!isDone && _remaining == 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Отдых: ', style: _T.caption),
                  GestureDetector(
                    onTap: () => setState(
                            () => _restSeconds = (_restSeconds - 15).clamp(0, 600)),
                    child:
                    const Icon(Icons.remove_circle_outline, size: 18),
                  ),
                  const SizedBox(width: 6),
                  Text('${_restSeconds}с',
                      style: _T.headline.copyWith(fontSize: 14)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(
                            () => _restSeconds = (_restSeconds + 15).clamp(0, 600)),
                    child: const Icon(Icons.add_circle_outline, size: 18),
                  ),
                ],
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isDone
                      ? () => widget.onComplete(_completed)
                      : (_remaining == 0
                      ? _start
                      : () => setState(() => _paused = !_paused)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isDone
                        ? 'СОХРАНИТЬ'
                        : (_remaining == 0
                        ? 'НАЧАТЬ'
                        : (_paused ? 'ПРОДОЛЖИТЬ' : 'ПАУЗА')),
                    style: _T.headline
                        .copyWith(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}