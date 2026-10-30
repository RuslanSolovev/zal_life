// features/fitness/database/ui/screens/workout_execution_screen.dart
// 🆕 v17.1: 6 категорий (сила / свой вес / статика / на время / кардио / раунды)
// Формат — главный источник истины. Эвристика по имени удалена.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../models/helpers.dart';
import '../../../providers/fitness_provider.dart';
import '../widgets/timer_widget.dart';

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

// ==================== КАТЕГОРИЯ УПРАЖНЕНИЯ ====================

enum _ExCategory { strength, bodyweight, hold, timedSets, cardio, combat }

/// 🆕 Формат — главный источник истины. Эвристика по ключевым словам удалена.
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

// ==================== MAIN WIDGET ====================

class WorkoutExecutionScreen extends StatefulWidget {
  final WorkoutDay day;
  final bool isDark;

  const WorkoutExecutionScreen({
    super.key,
    required this.day,
    this.isDark = false,
  });

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

final Map<String, TextEditingController> _weightControllers = {};
final Map<String, TextEditingController> _repsControllers = {};
final Map<String, TextEditingController> _metricControllers = {};

int? _moodEnergy;
int? _moodSleep;
int? _moodMotivation;
String? _moodNotes;
String? _workoutPhotoPath;
final ImagePicker _imagePicker = ImagePicker();

bool _isFinishing = false;
String? _savedLogId;

// ══════════════════════════════════════════════════════════
// ИНИЦИАЛИЗАЦИЯ
// ══════════════════════════════════════════════════════════

@override
void initState() {
super.initState();
_config = widget.day.exercises.map((ex) {
return ConfiguredExercise(
exercise: ex,
sets: ex.sets.map((s) => SetConfig.fromExerciseSet(s)).toList(),
);
}).toList();

_initControllers();
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

@override
void dispose() {
for (final c in _weightControllers.values) {
c.dispose();
}
for (final c in _repsControllers.values) {
c.dispose();
}
for (final c in _metricControllers.values) {
c.dispose();
}
super.dispose();
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
final format = FitnessHelpers.resolveFormat(
we,
exData.id.isEmpty ? null : exData,
);
return _detectCategory(exData, format);
} catch (_) {
return _ExCategory.strength;
}
}

Color _accentForCategory(_ExCategory c) {
switch (c) {
case _ExCategory.strength:
return _Power.volt;
case _ExCategory.bodyweight:
return _Power.lime;
case _ExCategory.hold:
return _Power.plasma;
case _ExCategory.timedSets:
return _Power.green;
case _ExCategory.cardio:
return _Power.ice;
case _ExCategory.combat:
return _Power.magma;
}
}

String _categoryLabel(_ExCategory c) {
switch (c) {
case _ExCategory.strength:
return 'СИЛА';
case _ExCategory.bodyweight:
return 'СВОЙ ВЕС';
case _ExCategory.hold:
return 'СТАТИКА';
case _ExCategory.timedSets:
return 'НА ВРЕМЯ';
case _ExCategory.cardio:
return 'КАРДИО';
case _ExCategory.combat:
return 'РАУНДЫ';
}
}

String _emojiForCategory(_ExCategory c) {
switch (c) {
case _ExCategory.strength:
return '🏋️';
case _ExCategory.bodyweight:
return '🤸';
case _ExCategory.hold:
return '🧘';
case _ExCategory.timedSets:
return '⏱️';
case _ExCategory.cardio:
return '🏃';
case _ExCategory.combat:
return '🥊';
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
return '$wStrкг × ${s.reps}';
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
return '${s.rounds ?? 0} × ${_formatSeconds(s.roundDuration ?? 0)}';
}
}

void _initControllers() {
for (final c in _weightControllers.values) {
c.dispose();
}
for (final c in _repsControllers.values) {
c.dispose();
}
for (final c in _metricControllers.values) {
c.dispose();
}
_weightControllers.clear();
_repsControllers.clear();
_metricControllers.clear();

for (int i = 0; i < _config.length; i++) {
final format = _resolveFormatOf(i);
for (int j = 0; j < _config[i].sets.length; j++) {
final set = _config[i].sets[j];
final baseKey = '${i}_$j';

_weightControllers[baseKey] = TextEditingController(
text: set.weight > 0 ? set.weight.toStringAsFixed(1) : '',
);
_repsControllers[baseKey] = TextEditingController(
text: set.reps > 0 ? '${set.reps}' : '',
);

for (final m in format.metrics) {
if (m == ExerciseMetric.weight) continue;
if (m == ExerciseMetric.reps) continue;
if (m == ExerciseMetric.intensity) continue;
if (m == ExerciseMetric.tempo) continue;
final key = '${baseKey}_${m.name}';
final v = set.metricValue(m);
_metricControllers[key] = TextEditingController(
text: v != null && v != 0 ? _formatNum(v, m) : '',
);
}
}
}
}

String _formatNum(double v, ExerciseMetric m) {
if (m.isDecimal) {
return v.toStringAsFixed(m == ExerciseMetric.distance ? 2 : 1);
}
return v.toStringAsFixed(0);
}

// ══════════════════════════════════════════════════════════
// BUILD STEPS
// ══════════════════════════════════════════════════════════

void _buildSteps() {
_steps = [];
_currentStepIndex = 0;

if (!_isCircuitMode) {
for (int e = 0; e < _config.length; e++) {
final cat = _catOf(e);
if (cat == _ExCategory.combat) {
_steps.add(_WorkoutStep(
exerciseIndex: e,
setIndex: 0,
circuitNumber: 0,
));
} else {
for (int s = 0; s < _config[e].sets.length; s++) {
_steps.add(_WorkoutStep(
exerciseIndex: e,
setIndex: s,
circuitNumber: 0,
));
}
}
}
} else {
final maxSets = _config.fold<int>(
0, (m, c) => c.sets.length > m ? c.sets.length : m);
final circuits = _totalCircuits.clamp(1, math.max(1, maxSets)).toInt();
_totalCircuits = circuits;

for (int circuit = 0; circuit < circuits; circuit++) {
for (int e = 0; e < _config.length; e++) {
final cat = _catOf(e);
if (cat == _ExCategory.combat) {
_steps.add(_WorkoutStep(
exerciseIndex: e,
setIndex: 0,
circuitNumber: circuit + 1,
));
} else if (circuit < _config[e].sets.length) {
_steps.add(_WorkoutStep(
exerciseIndex: e,
setIndex: circuit,
circuitNumber: circuit + 1,
));
}
}
}
}

debugPrint(
'🔥 Построено шагов: ${_steps.length}, режим: ${_isCircuitMode ? "круговой ($_totalCircuits)" : "обычный"}');
}

_WorkoutStep? get _currentStep {
if (_currentStepIndex < 0 || _currentStepIndex >= _steps.length) {
return null;
}
return _steps[_currentStepIndex];
}

@override
Widget build(BuildContext context) {
final isDark = widget.isDark;
final provider = context.watch<FitnessProvider>();

switch (_phase) {
case WorkoutPhase.setup:
return _buildSetupScreen(isDark, provider);
case WorkoutPhase.active:
return _buildActiveScreen(isDark, provider);
case WorkoutPhase.rest:
return _buildRestScreen(isDark, provider);
case WorkoutPhase.completed:
return _buildCompletedScreen(isDark);
}
}

// ══════════════════════════════════════════════════════════
// ВАЛИДАЦИЯ ПО КАТЕГОРИИ
// ══════════════════════════════════════════════════════════

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
// SETUP SCREEN
// ══════════════════════════════════════════════════════════

Widget _buildSetupScreen(bool isDark, FitnessProvider provider) {
return Scaffold(
backgroundColor: _Power.bg(isDark),
body: CustomScrollView(
physics: const BouncingScrollPhysics(),
slivers: [
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
'Настройка',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
letterSpacing: -0.4,
color: _Power.textPrimary(isDark),
),
),
centerTitle: true,
actions: [
if (_config.length > 1)
Padding(
padding: const EdgeInsets.only(right: 16),
child: Row(
children: [
Text(
'КРУГ',
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w900,
letterSpacing: 1.4,
color: _isCircuitMode
? _Power.plasma
: _Power.textTertiary(isDark),
),
),
const SizedBox(width: 4),
Transform.scale(
scale: 0.85,
child: Switch(
value: _isCircuitMode,
onChanged: (v) {
HapticFeedback.selectionClick();
setState(() {
_isCircuitMode = v;
if (v) {
final maxSets = _config.fold<int>(0,
(m, c) => c.sets.length > m ? c.sets.length : m);
_totalCircuits =
math.max(1, math.min(10, maxSets));
}
});
},
activeColor: _Power.plasma,
activeTrackColor: _Power.plasma.withOpacity(0.3),
),
),
],
),
),
],
),
SliverToBoxAdapter(child: _buildSetupHero(isDark, provider)),
if (_isCircuitMode)
SliverToBoxAdapter(child: _buildCircuitSettingsCard(isDark)),
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
return _buildProfessionalExerciseCard(
isDark,
index,
config,
exData,
provider,
);
},
childCount: _config.length,
),
),
),
const SliverToBoxAdapter(child: SizedBox(height: 120)),
],
),
bottomSheet: _buildStartButton(isDark, provider),
);
}

Widget _buildCircuitSettingsCard(bool isDark) {
final maxSets = _config.fold<int>(
0, (m, c) => c.sets.length > m ? c.sets.length : m);
final clampedMax = math.max(1, maxSets);

return Padding(
padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
_Power.plasma.withOpacity(0.12),
_Power.plasma.withOpacity(0.02),
],
),
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: _Power.plasma.withOpacity(0.35),
width: 1,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 36,
height: 36,
decoration: BoxDecoration(
color: _Power.plasma.withOpacity(0.18),
borderRadius: BorderRadius.circular(11),
),
alignment: Alignment.center,
child: const Icon(
Icons.refresh_rounded,
color: _Power.plasma,
size: 20,
),
),
const SizedBox(width: 10),
const Expanded(
child: Text(
'КРУГОВАЯ ТРЕНИРОВКА',
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w900,
letterSpacing: 1.4,
color: _Power.plasma,
),
),
),
],
),
const SizedBox(height: 12),
Text(
'Все упражнения по одному подходу подряд. После круга — отдых. Кругов: $_totalCircuits.',
style: TextStyle(
fontSize: 12,
height: 1.4,
color: _Power.textSecondary(isDark),
),
),
const SizedBox(height: 14),
Row(
children: [
Text(
'КОЛИЧЕСТВО КРУГОВ',
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w900,
letterSpacing: 1.2,
color: _Power.textTertiary(isDark),
),
),
const Spacer(),
Container(
height: 40,
decoration: BoxDecoration(
color: _Power.card(isDark),
borderRadius: BorderRadius.circular(11),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
GestureDetector(
onTap: _totalCircuits > 1
? () {
HapticFeedback.selectionClick();
setState(() => _totalCircuits--);
}
: null,
child: Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: _totalCircuits > 1
? _Power.textTertiary(isDark).withOpacity(0.1)
: Colors.transparent,
borderRadius: const BorderRadius.horizontal(
left: Radius.circular(11)),
),
child: Icon(
Icons.remove_rounded,
size: 16,
color: _totalCircuits > 1
? _Power.textPrimary(isDark)
: _Power.textTertiary(isDark),
),
),
),
SizedBox(
width: 48,
child: Center(
child: Text(
'$_totalCircuits',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w900,
letterSpacing: -0.5,
color: _Power.textPrimary(isDark),
),
),
),
),
GestureDetector(
onTap: _totalCircuits < clampedMax
? () {
HapticFeedback.selectionClick();
setState(() => _totalCircuits++);
}
: null,
child: Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: _totalCircuits < clampedMax
? _Power.plasma.withOpacity(0.14)
: Colors.transparent,
borderRadius: const BorderRadius.horizontal(
right: Radius.circular(11)),
),
child: Icon(
Icons.add_rounded,
size: 16,
color: _totalCircuits < clampedMax
? _Power.plasma
: _Power.textTertiary(isDark),
),
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

Widget _buildSetupHero(bool isDark, FitnessProvider provider) {
final totalSets = _config.fold<int>(0, (s, c) => s + c.sets.length);
int configuredSets = 0;
for (int i = 0; i < _config.length; i++) {
final cat = _catOf(i);
configuredSets += _config[i]
.sets
.where((x) => _isSetConfiguredByCategory(x, cat))
.length;
}
final totalExercises = _config.length;
final readyExercises =
_config.where((c) => _isExerciseConfigured(c, provider)).length;
final progress = totalSets > 0 ? configuredSets / totalSets : 0.0;
final isReady =
readyExercises == totalExercises && configuredSets == totalSets;

return Padding(
padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
child: Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: isReady
? [
_Power.green.withOpacity(0.18),
_Power.green.withOpacity(0.04),
]
: [
_Power.volt.withOpacity(0.14),
_Power.volt.withOpacity(0.02),
],
),
borderRadius: BorderRadius.circular(22),
border: Border.all(
color: isReady
? _Power.green.withOpacity(0.35)
: _Power.volt.withOpacity(0.25),
width: 1,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: (isReady ? _Power.green : _Power.volt)
.withOpacity(0.18),
borderRadius: BorderRadius.circular(13),
),
alignment: Alignment.center,
child: Icon(
isReady ? Icons.check_rounded : Icons.tune_rounded,
color: isReady ? _Power.green : _Power.volt,
size: 22,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
isReady ? 'ВСЁ ГОТОВО' : 'НАСТРОЙКА',
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w900,
letterSpacing: 1.8,
color: isReady ? _Power.green : _Power.volt,
),
),
const SizedBox(height: 3),
Text(
_isCircuitMode
? 'Круговая тренировка'
: 'Свободная тренировка',
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
],
),
const SizedBox(height: 16),
Row(
children: [
_buildHeroStat(
isDark, '$readyExercises/$totalExercises', 'УПРАЖНЕНИЙ'),
Container(
width: 0.5,
height: 32,
color: _Power.separator(isDark),
),
_buildHeroStat(
isDark, '$configuredSets/$totalSets', 'ПОДХОДОВ'),
],
),
const SizedBox(height: 14),
ClipRRect(
borderRadius: BorderRadius.circular(5),
child: LinearProgressIndicator(
value: progress,
minHeight: 6,
backgroundColor: _Power.separator(isDark),
valueColor: AlwaysStoppedAnimation(
isReady ? _Power.green : _Power.volt,
),
),
),
if (!isReady && readyExercises < totalExercises) ...[
const SizedBox(height: 10),
Row(
children: [
const Icon(Icons.info_outline_rounded,
color: _Power.plasma, size: 14),
const SizedBox(width: 6),
Expanded(
child: Text(
'Заполните поля по формату каждого упражнения',
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.w600,
color: _Power.textSecondary(isDark),
),
),
),
],
),
],
],
),
),
);
}

Widget _buildHeroStat(bool isDark, String value, String label) {
return Expanded(
child: Column(
children: [
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

Widget _buildProfessionalExerciseCard(
bool isDark,
int exIndex,
ConfiguredExercise config,
Exercise exData,
FitnessProvider provider,
) {
final cat = _catOf(exIndex);
final accent = _accentForCategory(cat);
final isReady = _isExerciseConfigured(config, provider);
final categoryLabel = _categoryLabel(cat);
final categoryEmoji = _emojiForCategory(cat);
final lastRecord = provider.getLastProgress(exData.id);

return Container(
margin: const EdgeInsets.only(bottom: 12),
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
isDark ? _Power.darkCard : _Power.lightCard,
(isDark ? _Power.darkCard : _Power.lightCard)
.withOpacity(isDark ? 0.85 : 0.95),
],
),
borderRadius: BorderRadius.circular(22),
border: Border.all(
color: isReady
? _Power.green.withOpacity(0.35)
: accent.withOpacity(0.18),
width: isReady ? 1.2 : 0.8,
),
boxShadow: isReady
? [
BoxShadow(
color: _Power.green.withOpacity(0.15),
blurRadius: 16,
offset: const Offset(0, 4),
),
]
: null,
),
child: Theme(
data: Theme.of(context).copyWith(
dividerColor: Colors.transparent,
splashColor: Colors.transparent,
highlightColor: Colors.transparent,
),
child: ExpansionTile(
tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
initiallyExpanded: !isReady && exIndex == 0,
iconColor: accent,
collapsedIconColor: _Power.textSecondary(isDark),
leading: Container(
width: 48,
height: 48,
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [accent.withOpacity(0.24), accent.withOpacity(0.08)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(14),
border: Border.all(color: accent.withOpacity(0.30), width: 0.8),
),
alignment: Alignment.center,
child: Text(
exData.exerciseType.emoji,
style: const TextStyle(fontSize: 22),
),
),
title: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
exData.name,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w800,
letterSpacing: -0.4,
color: _Power.textPrimary(isDark),
),
),
const SizedBox(height: 4),
Row(
children: [
Container(
padding:
const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
decoration: BoxDecoration(
color: accent.withOpacity(0.15),
borderRadius: BorderRadius.circular(6),
),
child: Text(
'$categoryEmoji $categoryLabel',
style: TextStyle(
fontSize: 8.5,
fontWeight: FontWeight.w900,
letterSpacing: 0.8,
color: accent,
),
),
),
const SizedBox(width: 6),
Flexible(
child: Text(
_summaryTextForCategory(config, cat),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.w600,
color: _Power.textTertiary(isDark),
),
),
),
if (lastRecord != null) ...[
const SizedBox(width: 6),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 6, vertical: 2),
decoration: BoxDecoration(
color: _Power.ice.withOpacity(0.12),
borderRadius: BorderRadius.circular(6),
),
child: Text(
_lastRecordLabel(lastRecord),
style: const TextStyle(
fontSize: 9,
fontWeight: FontWeight.w800,
color: _Power.ice,
),
),
),
],
],
),
],
),
subtitle: isReady
? null
: Padding(
padding: const EdgeInsets.only(top: 6),
child: Row(
children: [
const Icon(
Icons.warning_amber_rounded,
size: 12,
color: _Power.plasma,
),
const SizedBox(width: 4),
Expanded(
child: Text(
'Заполните поля «$categoryLabel»',
style: const TextStyle(
fontSize: 10.5,
fontWeight: FontWeight.w700,
color: _Power.plasma,
),
),
),
],
),
),
children: [
..._buildCategoryInputs(isDark, exIndex, config, cat),
const SizedBox(height: 10),
GestureDetector(
onTap: () {
HapticFeedback.selectionClick();
_addSetForCategory(exIndex, cat);
},
child: Container(
padding: const EdgeInsets.symmetric(vertical: 11),
decoration: BoxDecoration(
color: accent.withOpacity(0.10),
borderRadius: BorderRadius.circular(11),
border: Border.all(
color: accent.withOpacity(0.20),
width: 0.6,
),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.add_rounded, size: 14, color: accent),
const SizedBox(width: 6),
Text(
cat == _ExCategory.combat
? 'ДОБАВИТЬ БЛОК'
: cat == _ExCategory.cardio
? 'ДОБАВИТЬ ОТРЕЗОК'
: 'ДОБАВИТЬ ПОДХОД',
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w900,
letterSpacing: 1.0,
color: accent,
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

String _lastRecordLabel(dynamic lastRecord) {
if (lastRecord == null) return '';
if (lastRecord.bestWeight > 0) {
return '${lastRecord.bestWeight.toStringAsFixed(0)}×${lastRecord.bestReps}';
}
if (lastRecord.bestDistance != null) {
return '${lastRecord.bestDistance!.toStringAsFixed(1)}км';
}
if (lastRecord.bestRounds != null) {
return '${lastRecord.bestRounds}р';
}
if (lastRecord.bestDuration != null) {
return FitnessHelpers.formatHold(lastRecord.bestDuration!);
}
if (lastRecord.bestHoldSeconds != null) {
return FitnessHelpers.formatHold(lastRecord.bestHoldSeconds!);
}
return '';
}

List<Widget> _buildCategoryInputs(
bool isDark,
int exIndex,
ConfiguredExercise config,
_ExCategory cat,
) {
final accent = _accentForCategory(cat);
final sets = config.sets;

return sets.asMap().entries.map((e) {
final i = e.key;
final s = e.value;

switch (cat) {
case _ExCategory.strength:
return _setRowPair(
isDark: isDark,
accent: accent,
title: s.isWarmup ? 'РАЗМИНКА' : 'ПОДХОД ${i + 1}',
isWarmup: s.isWarmup,
onToggleWarmup: () {
HapticFeedback.selectionClick();
setState(() => s.isWarmup = !s.isWarmup);
},
left: _StepperCompact(
label: 'ВЕС',
unit: 'кг',
value: s.weight,
step: 2.5,
min: 0,
max: 500,
isDecimal: true,
accent: _Power.volt,
onChanged: (v) => setState(() => s.weight = v),
),
right: _StepperCompact(
label: 'ПОВТОРЫ',
unit: 'раз',
value: s.reps.toDouble(),
step: 1,
min: 0,
max: 200,
isDecimal: false,
accent: _Power.volt,
onChanged: (v) => setState(() => s.reps = v.round()),
),
onRemove: sets.length > 1 ? () => _removeSet(exIndex, i) : null,
);

case _ExCategory.bodyweight:
return _setRowPair(
isDark: isDark,
accent: accent,
title: s.isWarmup ? 'РАЗМИНКА' : 'ПОДХОД ${i + 1}',
isWarmup: s.isWarmup,
onToggleWarmup: () {
HapticFeedback.selectionClick();
setState(() => s.isWarmup = !s.isWarmup);
},
left: _StepperCompact(
label: 'ПОВТОРЫ',
unit: 'раз',
value: s.reps.toDouble(),
step: 1,
min: 0,
max: 500,
isDecimal: false,
accent: _Power.lime,
onChanged: (v) => setState(() => s.reps = v.round()),
),
right: null,
onRemove: sets.length > 1 ? () => _removeSet(exIndex, i) : null,
);

case _ExCategory.hold:
return _setRowPair(
isDark: isDark,
accent: accent,
title: 'УДЕРЖАНИЕ ${i + 1}',
isWarmup: false,
left: _StepperCompact(
label: 'УДЕРЖАНИЕ',
unit: 'сек',
value: (s.holdSeconds ?? 0).toDouble(),
step: 5,
min: 0,
max: 3600,
isDecimal: false,
accent: _Power.plasma,
formatValue: (v) => _formatSeconds(v.round()),
onChanged: (v) => setState(() => s.holdSeconds = v.round()),
),
right: null,
onRemove: sets.length > 1 ? () => _removeSet(exIndex, i) : null,
);

case _ExCategory.timedSets:
return _setRowPair(
isDark: isDark,
accent: accent,
title: 'ОТРЕЗОК ${i + 1}',
isWarmup: false,
left: _StepperCompact(
label: 'ВРЕМЯ',
unit: 'сек',
value: s.duration.toDouble(),
step: 15,
min: 0,
max: 7200,
isDecimal: false,
accent: _Power.green,
formatValue: (v) => _formatSeconds(v.round()),
onChanged: (v) => setState(() => s.duration = v.round()),
),
right: _StepperCompact(
label: 'ПОВТОРЫ',
unit: 'раз',
value: s.reps.toDouble(),
step: 1,
min: 0,
max: 500,
isDecimal: false,
accent: _Power.green,
onChanged: (v) => setState(() => s.reps = v.round()),
),
onRemove: sets.length > 1 ? () => _removeSet(exIndex, i) : null,
);

case _ExCategory.cardio:
return _setRowPair(
isDark: isDark,
accent: accent,
title: 'ОТРЕЗОК ${i + 1}',
isWarmup: false,
left: _StepperCompact(
label: 'ДИСТАНЦИЯ',
unit: 'км',
value: (s.distance ?? 0),
step: 0.1,
min: 0,
max: 100,
isDecimal: true,
accent: _Power.ice,
onChanged: (v) => setState(() => s.distance = v),
),
right: _StepperCompact(
label: 'ВРЕМЯ',
unit: 'мин:сек',
value: s.duration.toDouble(),
step: 15,
min: 0,
max: 7200,
isDecimal: false,
accent: _Power.ice,
formatValue: (v) => _formatSeconds(v.round()),
onChanged: (v) => setState(() => s.duration = v.round()),
),
onRemove: sets.length > 1 ? () => _removeSet(exIndex, i) : null,
);

case _ExCategory.combat:
return _combatSetupBlock(isDark, s, accent);
}
}).toList();
}

Widget _setRowPair({
required bool isDark,
required Color accent,
required String title,
required bool isWarmup,
VoidCallback? onToggleWarmup,
required Widget left,
Widget? right,
VoidCallback? onRemove,
}) {
return Container(
margin: const EdgeInsets.only(bottom: 8),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: _Power.card2(isDark),
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: isWarmup
? _Power.volt.withOpacity(0.45)
: (isDark
? Colors.white.withOpacity(0.05)
: Colors.black.withOpacity(0.04)),
width: isWarmup ? 1.0 : 0.5,
),
),
child: Column(
children: [
Row(
children: [
Container(
padding:
const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
decoration: BoxDecoration(
color: isWarmup
? _Power.volt.withOpacity(0.20)
: accent.withOpacity(0.14),
borderRadius: BorderRadius.circular(6),
),
child: Text(
title,
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w900,
letterSpacing: 0.8,
color: isWarmup ? _Power.volt : accent,
),
),
),
const Spacer(),
if (onToggleWarmup != null)
GestureDetector(
onTap: onToggleWarmup,
child: Container(
width: 26,
height: 26,
margin: const EdgeInsets.only(right: 6),
decoration: BoxDecoration(
color: isWarmup
? _Power.volt.withOpacity(0.18)
: Colors.white.withOpacity(0.05),
shape: BoxShape.circle,
),
child: Icon(
Icons.whatshot_rounded,
size: 14,
color:
isWarmup ? _Power.volt : _Power.textTertiary(isDark),
),
),
),
if (onRemove != null)
GestureDetector(
onTap: () {
HapticFeedback.mediumImpact();
onRemove();
},
child: Container(
width: 26,
height: 26,
decoration: BoxDecoration(
color: _Power.red.withOpacity(0.14),
shape: BoxShape.circle,
),
child: const Icon(Icons.close_rounded,
color: _Power.red, size: 14),
),
),
],
),
const SizedBox(height: 10),
if (right == null)
left
else
Row(
children: [
Expanded(child: left),
const SizedBox(width: 10),
Expanded(child: right),
],
),
],
),
);
}

Widget _combatSetupBlock(bool isDark, SetConfig s, Color accent) {
return Container(
margin: const EdgeInsets.only(bottom: 10),
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: _Power.card2(isDark),
borderRadius: BorderRadius.circular(14),
border: Border.all(color: accent.withOpacity(0.22), width: 0.7),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const Text('🥊', style: TextStyle(fontSize: 14)),
const SizedBox(width: 6),
Text(
'НАСТРОЙКА РАУНДОВ',
style: TextStyle(
fontSize: 9.5,
fontWeight: FontWeight.w900,
letterSpacing: 1.4,
color: accent,
),
),
],
),
const SizedBox(height: 12),
_settingRow(
isDark,
'🔔',
'Раундов',
'${s.rounds ?? 5}',
accent,
onDec: () => setState(
() => s.rounds = ((s.rounds ?? 5) - 1).clamp(1, 30)),
onInc: () => setState(
() => s.rounds = ((s.rounds ?? 5) + 1).clamp(1, 30)),
),
const SizedBox(height: 8),
_settingRow(
isDark,
'⏱',
'Длит. раунда',
_formatSeconds(s.roundDuration ?? 180),
accent,
onDec: () => setState(() => s.roundDuration =
((s.roundDuration ?? 180) - 15).clamp(15, 900)),
onInc: () => setState(() => s.roundDuration =
((s.roundDuration ?? 180) + 15).clamp(15, 900)),
),
const SizedBox(height: 8),
_settingRow(
isDark,
'😮‍💨',
'Отдых',
_formatSeconds(s.restBetweenRounds ?? 60),
accent,
onDec: () => setState(() => s.restBetweenRounds =
((s.restBetweenRounds ?? 60) - 15).clamp(0, 600)),
onInc: () => setState(() => s.restBetweenRounds =
((s.restBetweenRounds ?? 60) + 15).clamp(0, 600)),
),
],
),
);
}

Widget _settingRow(
bool isDark,
String emoji,
String label,
String value,
Color accent, {
required VoidCallback onDec,
required VoidCallback onInc,
}) {
return Container(
padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
decoration: BoxDecoration(
color: Colors.white.withOpacity(isDark ? 0.04 : 0.6),
borderRadius: BorderRadius.circular(11),
),
child: Row(
children: [
Text(emoji, style: const TextStyle(fontSize: 13)),
const SizedBox(width: 8),
Expanded(
child: Text(
label,
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
color: _Power.textPrimary(isDark),
),
),
),
Text(
value,
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w800,
color: accent,
fontFeatures: const [FontFeature.tabularFigures()],
),
),
const SizedBox(width: 4),
_miniBtn(Icons.remove_rounded, onDec, accent),
_miniBtn(Icons.add_rounded, onInc, accent),
],
),
);
}

Widget _miniBtn(IconData icon, VoidCallback onTap, Color color) {
return GestureDetector(
onTap: () {
HapticFeedback.selectionClick();
onTap();
},
child: Container(
width: 30,
height: 30,
decoration: BoxDecoration(
color: color.withOpacity(0.14),
borderRadius: BorderRadius.circular(8),
),
child: Icon(icon, color: color, size: 16),
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
newSet = SetConfig(
reps: last?.reps ?? 10,
weight: last?.weight ?? 0,
restSeconds: last?.restSeconds,
);
break;
case _ExCategory.bodyweight:
newSet = SetConfig(
reps: last?.reps ?? 10,
restSeconds: last?.restSeconds,
);
break;
case _ExCategory.hold:
newSet = SetConfig(
reps: 0,
holdSeconds: last?.holdSeconds ?? 30,
intensity: last?.intensity ?? 5,
);
break;
case _ExCategory.timedSets:
newSet = SetConfig(
reps: last?.reps ?? 10,
duration: last?.duration ?? 60,
intensity: last?.intensity ?? 5,
);
break;
case _ExCategory.cardio:
newSet = SetConfig(
reps: 0,
duration: last?.duration ?? 60,
distance: last?.distance ?? 0,
);
break;
case _ExCategory.combat:
newSet = SetConfig(
reps: 0,
rounds: last?.rounds ?? 5,
roundDuration: last?.roundDuration ?? 180,
restBetweenRounds: last?.restBetweenRounds ?? 60,
);
break;
}
config.sets.add(newSet);
});
}

void _removeSet(int exIndex, int setIndex) {
setState(() {
final config = _config[exIndex];
if (config.sets.length <= 1) return;
config.sets.removeAt(setIndex);

final key = '${exIndex}_$setIndex';
_weightControllers[key]?.dispose();
_repsControllers[key]?.dispose();
_weightControllers.remove(key);
_repsControllers.remove(key);
for (final m in ExerciseMetric.values) {
final k = '${key}_${m.name}';
_metricControllers[k]?.dispose();
_metricControllers.remove(k);
}
});
}

Widget _buildStartButton(bool isDark, FitnessProvider provider) {
final allReady = _config.isNotEmpty &&
_config.every((c) => _isExerciseConfigured(c, provider));
int totalConfigured = 0;
for (int i = 0; i < _config.length; i++) {
final cat = _catOf(i);
totalConfigured += _config[i]
.sets
.where((x) => _isSetConfiguredByCategory(x, cat))
.length;
}
final totalSets = _config.fold<int>(0, (s, c) => s + c.sets.length);

return Container(
color: _Power.bg(isDark),
padding: EdgeInsets.fromLTRB(
16,
12,
16,
12 + MediaQuery.of(context).padding.bottom,
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
if (!allReady)
Padding(
padding: const EdgeInsets.only(bottom: 10),
child: Container(
padding:
const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
decoration: BoxDecoration(
color: _Power.plasma.withOpacity(0.10),
borderRadius: BorderRadius.circular(10),
border: Border.all(
color: _Power.plasma.withOpacity(0.25),
width: 0.8,
),
),
child: Row(
children: [
const Icon(Icons.warning_amber_rounded,
color: _Power.plasma, size: 14),
const SizedBox(width: 8),
Expanded(
child: Text(
'Заполните все поля: $totalConfigured из $totalSets',
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.w700,
color: _Power.textSecondary(isDark),
),
),
),
],
),
),
),
SizedBox(
width: double.infinity,
height: 56,
child: ElevatedButton(
onPressed: !allReady
? () {
HapticFeedback.mediumImpact();
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: const Text(
'Заполните все поля для всех упражнений'),
backgroundColor: _Power.plasma,
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
);
}
: () async {
HapticFeedback.mediumImpact();
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
backgroundColor: allReady
? _Power.green
: _Power.textTertiary(isDark).withOpacity(0.4),
foregroundColor: Colors.white,
disabledBackgroundColor:
_Power.textTertiary(isDark).withOpacity(0.5),
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
shadowColor: allReady ? _Power.green.withOpacity(0.5) : null,
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
allReady ? Icons.play_arrow_rounded : Icons.lock_rounded,
size: 24,
),
const SizedBox(width: 8),
Text(
!allReady
? 'ЗАПОЛНИТЕ ПОЛЯ'
: _isCircuitMode
? 'НАЧАТЬ • $_totalCircuits КРУГ.'
: 'НАЧАТЬ ТРЕНИРОВКУ',
style: const TextStyle(
fontSize: 15,
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

// ══════════════════════════════════════════════════════════
// ACTIVE SCREEN — ветвление по категории
// ══════════════════════════════════════════════════════════

Widget _buildActiveScreen(bool isDark, FitnessProvider provider) {
final step = _currentStep;
if (step == null) return _buildCompletedScreen(isDark);
final cat = _catOf(step.exerciseIndex);

switch (cat) {
case _ExCategory.cardio:
return _buildCardioExecution(isDark, provider, step);
case _ExCategory.combat:
return _buildCombatExecution(isDark, provider, step);
case _ExCategory.hold:
return _buildHoldExecution(isDark, provider, step);
case _ExCategory.timedSets:
return _buildTimedSetsExecution(isDark, provider, step);
case _ExCategory.strength:
case _ExCategory.bodyweight:
return _buildStrengthActiveScreen(isDark, provider, step, cat);
}
}

Widget _buildStrengthActiveScreen(
bool isDark,
FitnessProvider provider,
_WorkoutStep step,
_ExCategory cat,
) {
final currentConfig = _config[step.exerciseIndex];
final exData = provider.exercises.firstWhere(
(e) => e.id == currentConfig.exercise.exerciseId,
orElse: () => Exercise(id: '', name: '???'),
);
final format = FitnessHelpers.resolveFormat(
currentConfig.exercise, exData.id.isEmpty ? null : exData);
final set = currentConfig.sets[step.setIndex];
final accent = _accentForCategory(cat);
final totalSteps = _steps.length;
final progress = totalSteps > 0 ? _currentStepIndex / totalSteps : 0.0;

return Scaffold(
backgroundColor: _Power.bg(isDark),
body: SafeArea(
child: Column(
children: [
_buildActiveTopBar(isDark, step),
_buildExercisesStrip(isDark, provider, step),
Expanded(
child: SingleChildScrollView(
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
child: Column(
children: [
_buildSetProgressRing(isDark, accent, step, currentConfig),
const SizedBox(height: 20),
Text(
exData.name,
textAlign: TextAlign.center,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.w900,
letterSpacing: -0.7,
height: 1.15,
color: _Power.textPrimary(isDark),
),
),
const SizedBox(height: 6),
if (exData.muscleGroups.isNotEmpty)
Text(
exData.muscleGroups
.map((m) => m.displayName)
.join(' • '),
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.w600,
color: _Power.textTertiary(isDark),
),
),
const SizedBox(height: 22),
_buildPrimaryMetrics(isDark, cat, format, set),
if (set.isWarmup) ...[
const SizedBox(height: 16),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 14, vertical: 7),
decoration: BoxDecoration(
color: _Power.volt,
borderRadius: BorderRadius.circular(10),
boxShadow:
_Power.softGlow(_Power.volt, strength: 0.5),
),
child: const Row(
mainAxisSize: MainAxisSize.min,
children: [
Text('🔥', style: TextStyle(fontSize: 12)),
SizedBox(width: 6),
Text(
'РАЗМИНОЧНЫЙ ПОДХОД',
style: TextStyle(
color: Colors.white,
fontSize: 10,
fontWeight: FontWeight.w900,
letterSpacing: 1.0,
),
),
],
),
),
],
const SizedBox(height: 24),
_buildOverallProgress(isDark, progress),
],
),
),
),
_buildActiveBottomButtons(isDark, step, format, cat),
],
),
),
);
}

Widget _buildPrimaryMetrics(
bool isDark, _ExCategory cat, ExerciseFormat format, SetConfig set) {
switch (cat) {
case _ExCategory.strength:
final w = set.weight;
final wStr = w == w.roundToDouble()
? w.toStringAsFixed(0)
: w.toStringAsFixed(1);
return _buildBigMetrics(
isDark,
emoji1: '⚖️',
value1: wStr,
label1: 'КГ',
emoji2: '🔁',
value2: '${set.reps}',
label2: 'ПОВТОРЫ',
accent: _Power.volt,
);
case _ExCategory.bodyweight:
return _buildSingleMetric(
isDark,
emoji: '🔁',
value: '${set.reps}',
label: 'ПОВТОРЫ',
accent: _Power.lime,
);
case _ExCategory.hold:
return _buildBigMetrics(
isDark,
emoji1: '🧘',
value1: _formatSeconds(set.holdSeconds ?? 0),
label1: 'УДЕРЖАНИЕ',
emoji2: '💪',
value2: '${set.intensity}',
label2: 'ИНТЕНС.',
accent: _Power.plasma,
);
case _ExCategory.timedSets:
return _buildBigMetrics(
isDark,
emoji1: '⏱️',
value1: _formatSeconds(set.duration),
label1: 'ВРЕМЯ',
emoji2: '🔁',
value2: '${set.reps}',
label2: 'ПОВТОРЫ',
accent: _Power.green,
);
case _ExCategory.cardio:
case _ExCategory.combat:
return const SizedBox.shrink();
}
}

Widget _buildActiveTopBar(bool isDark, _WorkoutStep step) {
return Padding(
padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
child: Row(
children: [
GestureDetector(
onTap: () => _showExitDialog(context, isDark),
child: Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: _Power.red.withOpacity(0.12),
shape: BoxShape.circle,
),
child: const Icon(Icons.close_rounded,
color: _Power.red, size: 20),
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
_isCircuitMode
? 'КРУГ ${step.circuitNumber} ИЗ $_totalCircuits'
: 'ТРЕНИРОВКА',
style: const TextStyle(
fontSize: 9,
fontWeight: FontWeight.w900,
letterSpacing: 1.8,
color: _Power.volt,
),
),
const SizedBox(height: 2),
Text(
'Шаг ${_currentStepIndex + 1} из ${_steps.length}',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
color: _Power.textSecondary(isDark),
),
),
],
),
),
GestureDetector(
onTap: () {
HapticFeedback.mediumImpact();
_skipExercise();
},
child: Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: _Power.volt.withOpacity(0.12),
shape: BoxShape.circle,
),
child: const Icon(Icons.skip_next_rounded,
color: _Power.volt, size: 20),
),
),
],
),
);
}

Widget _buildExercisesStrip(
bool isDark, FitnessProvider provider, _WorkoutStep current) {
final uniqueIndices = <int>{};
final list = <int>[];
for (final s in _steps) {
if (!uniqueIndices.contains(s.exerciseIndex)) {
uniqueIndices.add(s.exerciseIndex);
list.add(s.exerciseIndex);
}
}

return SizedBox(
height: 68,
child: ListView.builder(
scrollDirection: Axis.horizontal,
padding: const EdgeInsets.symmetric(horizontal: 16),
itemCount: list.length,
itemBuilder: (context, i) {
final exIdx = list[i];
final exData = provider.exercises.firstWhere(
(e) => e.id == _config[exIdx].exercise.exerciseId,
orElse: () => Exercise(id: '', name: '???'),
);
final isCurrent = exIdx == current.exerciseIndex;

final stepsForEx =
_steps.where((s) => s.exerciseIndex == exIdx).toList();
final doneSteps = stepsForEx.where((s) {
final exId = _config[exIdx].exercise.exerciseId;
final completed = _completedData[exId] ?? [];
return completed.any((c) => c.setIndex == s.setIndex);
}).length;
final isDone = doneSteps == stepsForEx.length;

final color = exData.muscleGroups.isNotEmpty
? exData.muscleGroups.first.color
: _Power.volt;

return AnimatedContainer(
duration: const Duration(milliseconds: 200),
width: 56,
margin: const EdgeInsets.only(right: 8),
decoration: BoxDecoration(
color: isCurrent
? color.withOpacity(0.18)
: isDone
? _Power.green.withOpacity(0.14)
: _Power.card(isDark),
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: isCurrent
? color
: isDone
? _Power.green
: _Power.separator(isDark),
width: isCurrent ? 1.5 : 0.8,
),
boxShadow:
isCurrent ? _Power.softGlow(color, strength: 0.3) : null,
),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(exData.exerciseType.emoji,
style: const TextStyle(fontSize: 22)),
const SizedBox(height: 4),
if (isDone)
const Icon(Icons.check_rounded,
color: _Power.green, size: 14)
else
Text(
'$doneSteps/${stepsForEx.length}',
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w900,
color: isCurrent ? color : _Power.textTertiary(isDark),
),
),
],
),
);
},
),
);
}

Widget _buildSetProgressRing(
bool isDark,
Color accent,
_WorkoutStep step,
ConfiguredExercise config,
) {
final totalSets = config.sets.length;
final currentSet = step.setIndex + 1;
final progress = currentSet / totalSets;

return SizedBox(
width: 180,
height: 180,
child: Stack(
alignment: Alignment.center,
children: [
Container(
width: 180,
height: 180,
decoration: BoxDecoration(
shape: BoxShape.circle,
boxShadow: _Power.softGlow(accent, strength: 0.3),
),
),
SizedBox(
width: 180,
height: 180,
child: CircularProgressIndicator(
value: 1,
strokeWidth: 8,
valueColor: AlwaysStoppedAnimation(_Power.separator(isDark)),
),
),
SizedBox(
width: 180,
height: 180,
child: CircularProgressIndicator(
value: progress,
strokeWidth: 8,
strokeCap: StrokeCap.round,
valueColor: AlwaysStoppedAnimation(accent),
),
),
Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
'ПОДХОД',
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w900,
letterSpacing: 2.0,
color: _Power.textTertiary(isDark),
),
),
const SizedBox(height: 4),
Row(
crossAxisAlignment: CrossAxisAlignment.end,
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
'$currentSet',
style: TextStyle(
fontSize: 56,
fontWeight: FontWeight.w900,
letterSpacing: -3,
height: 1,
color: _Power.textPrimary(isDark),
),
),
Padding(
padding: const EdgeInsets.only(bottom: 8, left: 4),
child: Text(
'/ $totalSets',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w800,
letterSpacing: -0.5,
color: _Power.textTertiary(isDark),
),
),
),
],
),
const SizedBox(height: 4),
Container(
padding:
const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
decoration: BoxDecoration(
color: accent.withOpacity(0.14),
borderRadius: BorderRadius.circular(8),
),
child: Text(
(progress * 100).round().toString() + '%',
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w900,
color: accent,
),
),
),
],
),
],
),
);
}

Widget _buildBigMetrics(
bool isDark, {
required String emoji1,
required String value1,
required String label1,
required String emoji2,
required String value2,
required String label2,
required Color accent,
}) {
return Row(
children: [
Expanded(
child: _buildMetricCard(
isDark,
emoji: emoji1,
value: value1,
label: label1,
accent: accent,
),
),
const SizedBox(width: 12),
Expanded(
child: _buildMetricCard(
isDark,
emoji: emoji2,
value: value2,
label: label2,
accent: accent,
),
),
],
);
}

Widget _buildSingleMetric(
bool isDark, {
required String emoji,
required String value,
required String label,
required Color accent,
}) {
return Container(
padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 14),
decoration: BoxDecoration(
color: _Power.card(isDark),
borderRadius: BorderRadius.circular(20),
border: Border.all(color: accent.withOpacity(0.15), width: 0.8),
),
child: Column(
children: [
Text(emoji, style: const TextStyle(fontSize: 28)),
const SizedBox(height: 12),
Text(
value,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 52,
fontWeight: FontWeight.w900,
letterSpacing: -2,
height: 1,
color: _Power.textPrimary(isDark),
),
),
const SizedBox(height: 8),
Text(
label,
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w900,
letterSpacing: 1.4,
color: _Power.textTertiary(isDark),
),
),
],
),
);
}

Widget _buildMetricCard(
bool isDark, {
required String emoji,
required String value,
required String label,
required Color accent,
}) {
return Container(
padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
decoration: BoxDecoration(
color: _Power.card(isDark),
borderRadius: BorderRadius.circular(20),
border: Border.all(color: accent.withOpacity(0.15), width: 0.8),
),
child: Column(
children: [
Text(emoji, style: const TextStyle(fontSize: 22)),
const SizedBox(height: 10),
FittedBox(
fit: BoxFit.scaleDown,
child: Text(
value,
maxLines: 1,
style: TextStyle(
fontSize: 34,
fontWeight: FontWeight.w900,
letterSpacing: -1.4,
height: 1,
color: _Power.textPrimary(isDark),
),
),
),
const SizedBox(height: 6),
Text(
label,
style: TextStyle(
fontSize: 8,
fontWeight: FontWeight.w900,
letterSpacing: 1.4,
color: _Power.textTertiary(isDark),
),
),
],
),
);
}

Widget _buildOverallProgress(bool isDark, double progress) {
return Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: _Power.card(isDark),
borderRadius: BorderRadius.circular(16),
),
child: Column(
children: [
Row(
children: [
Text(
'ПРОГРЕСС ТРЕНИРОВКИ',
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w900,
letterSpacing: 1.4,
color: _Power.textTertiary(isDark),
),
),
const Spacer(),
Text(
'${(progress * 100).round()}%',
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w900,
color: _Power.volt,
),
),
],
),
const SizedBox(height: 10),
ClipRRect(
borderRadius: BorderRadius
    .circular(4),
  child: LinearProgressIndicator(
    value: progress,
    minHeight: 5,
    backgroundColor: _Power.separator(isDark),
    valueColor: const AlwaysStoppedAnimation(_Power.volt),
  ),
),
],
),
);
}

  Widget _buildActiveBottomButtons(
      bool isDark,
      _WorkoutStep step,
      ExerciseFormat format,
      _ExCategory cat,
      ) {
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
          Expanded(
            child: SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _skipSet();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _Power.textSecondary(isDark),
                  side: BorderSide(color: _Power.separator(isDark)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.skip_next_rounded, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'ПРОПУСТИТЬ',
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
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => _showSetCompletionSheet(isDark, format, cat),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Power.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: _Power.green.withOpacity(0.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'ВЫПОЛНЕНО',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
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

  // ── CARDIO execution ─────────────────────────────────────

  Widget _buildCardioExecution(
      bool isDark,
      FitnessProvider provider,
      _WorkoutStep step,
      ) {
    final ex = provider.exercises.firstWhere(
          (e) => e.id == _config[step.exerciseIndex].exercise.exerciseId,
      orElse: () => Exercise(id: '', name: ''),
    );
    final set = _config[step.exerciseIndex].sets[step.setIndex];

    return _CardioTimerScreen(
      isDark: isDark,
      exerciseName: ex.name,
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
      onExit: () => _showExitDialog(context, isDark),
    );
  }

  // ── COMBAT execution ─────────────────────────────────────

  Widget _buildCombatExecution(
      bool isDark,
      FitnessProvider provider,
      _WorkoutStep step,
      ) {
    final ex = provider.exercises.firstWhere(
          (e) => e.id == _config[step.exerciseIndex].exercise.exerciseId,
      orElse: () => Exercise(id: '', name: ''),
    );
    final set = _config[step.exerciseIndex].sets[0];

    return _CombatTimerScreen(
      isDark: isDark,
      exerciseName: ex.name,
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
      onExit: () => _showExitDialog(context, isDark),
    );
  }

  // ── HOLD execution (планка, статика, йога) ───────────────

  Widget _buildHoldExecution(
      bool isDark,
      FitnessProvider provider,
      _WorkoutStep step,
      ) {
    final ex = provider.exercises.firstWhere(
          (e) => e.id == _config[step.exerciseIndex].exercise.exerciseId,
      orElse: () => Exercise(id: '', name: ''),
    );
    final set = _config[step.exerciseIndex].sets[step.setIndex];

    return _HoldTimerScreen(
      isDark: isDark,
      exerciseName: ex.name,
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
          intensity: set.intensity.toDouble(),
          format: ExerciseFormat.hold,
        ));
        _moveToNext();
      },
      onSkip: _skipSet,
      onExit: () => _showExitDialog(context, isDark),
    );
  }

  // ── TIMED SETS execution (берпи, скакалка, альпинист) ────

  Widget _buildTimedSetsExecution(
      bool isDark,
      FitnessProvider provider,
      _WorkoutStep step,
      ) {
    final ex = provider.exercises.firstWhere(
          (e) => e.id == _config[step.exerciseIndex].exercise.exerciseId,
      orElse: () => Exercise(id: '', name: ''),
    );
    final set = _config[step.exerciseIndex].sets[step.setIndex];

    return _TimedSetsTimerScreen(
      isDark: isDark,
      exerciseName: ex.name,
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
          intensity: set.intensity.toDouble(),
          format: ExerciseFormat.timedSets,
        ));
        _moveToNext();
      },
      onSkip: _skipSet,
      onExit: () => _showExitDialog(context, isDark),
    );
  }

  Future<void> _showSetCompletionSheet(
      bool isDark,
      ExerciseFormat format,
      _ExCategory cat,
      ) async {
    final step = _currentStep;
    if (step == null) return;

    final config = _config[step.exerciseIndex];
    final set = config.sets[step.setIndex];

    final result = await showModalBottomSheet<_SetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SetCompletionSheet(
        isDark: isDark,
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

  Widget _buildRestScreen(bool isDark, FitnessProvider provider) {
    final step = _currentStep;
    final nextConfig = step != null ? _config[step.exerciseIndex] : null;
    final nextExData = step != null
        ? provider.exercises.firstWhere(
          (e) => e.id == nextConfig!.exercise.exerciseId,
      orElse: () => Exercise(id: '', name: '???'),
    )
        : null;

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _Power.glow(_Power.volt,
                              strength: 0.15, blur: 60),
                        ),
                      ),
                    ),
                  ),
                  TimerWidget(
                    isDark: isDark,
                    restSeconds: _restSeconds,
                    onTimerComplete: () =>
                        setState(() => _phase = WorkoutPhase.active),
                    onSkip: () =>
                        setState(() => _phase = WorkoutPhase.active),
                  ),
                ],
              ),
            ),
            if (nextExData != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _Power.card(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _Power.separator(isDark),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _Power.volt.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          nextExData.exerciseType.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ДАЛЕЕ',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                                color: _Power.volt,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nextExData.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                color: _Power.textPrimary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () =>
                      setState(() => _phase = WorkoutPhase.active),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Power.volt,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'ПРОПУСТИТЬ ОТДЫХ',
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
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // COMPLETED SCREEN
  // ══════════════════════════════════════════════════════════

  Widget _buildCompletedScreen(bool isDark) {
    final provider = context.read<FitnessProvider>();
    final grouped = <String, List<CompletedSetData>>{};

    for (final config in _config) {
      final exData = provider.exercises.firstWhere(
            (e) => e.id == config.exercise.exerciseId,
        orElse: () => Exercise(id: '', name: '???'),
      );
      final list = _completedData[config.exercise.exerciseId] ?? [];
      if (list.isNotEmpty) {
        grouped[exData.name] = list;
      }
    }

    final totalExercises = grouped.length;
    final totalSets = _totalCompletedSets();
    final duration =
        DateTime.now().difference(_startTime ?? DateTime.now()).inMinutes;

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
          child: Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_Power.green, Color(0xFF008B00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow:
                    _Power.glow(_Power.green, strength: 0.45, blur: 40),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 70),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'ТРЕНИРОВКА ЗАВЕРШЕНА',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  color: _Power.volt,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Красава 💪',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  height: 1.05,
                  color: _Power.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _Power.card(isDark),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: _Power.separator(isDark), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _Power.volt.withOpacity(0.12),
                            _Power.volt.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildSummaryItem('🏋️', '$totalExercises', 'УПР'),
                          Container(
                            width: 0.5,
                            height: 32,
                            color: _Power.separator(isDark),
                          ),
                          _buildSummaryItem('💪', '$totalSets', 'ПОДХ'),
                          Container(
                            width: 0.5,
                            height: 32,
                            color: _Power.separator(isDark),
                          ),
                          _buildSummaryItem('⏱️', '$duration', 'МИН'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'ПОДРОБНОСТИ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                        color: _Power.volt,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...grouped.entries.map((entry) {
                      final sets =
                      entry.value.where((s) => !s.isWarmup).toList();
                      if (sets.isEmpty) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _Power.card2(isDark),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _Power.textPrimary(isDark),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _Power.volt.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${sets.length} ПОДХ',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: _Power.volt,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: sets.map((s) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    s.displaySummary,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _Power.textPrimary(isDark),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Power.volt,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ВЕРНУТЬСЯ',
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
      ),
    );
  }

  Widget _buildSummaryItem(String emoji, String value, String label) {
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
              color: _Power.textPrimary(widget.isDark),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: _Power.textTertiary(widget.isDark),
            ),
          ),
        ],
      ),
    );
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
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: _Power.card(widget.isDark),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: _Power.textTertiary(widget.isDark),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ПЕРЕД ТРЕНИРОВКОЙ',
                  style: TextStyle(
                    color: _Power.volt,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Как настроение?',
                  style: TextStyle(
                    color: _Power.textPrimary(widget.isDark),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 20),
                _buildMoodSliderRow('⚡', 'Энергия', energy,
                        (v) => setSheetState(() => energy = v)),
                const SizedBox(height: 10),
                _buildMoodSliderRow('😴', 'Сон', sleep,
                        (v) => setSheetState(() => sleep = v)),
                const SizedBox(height: 10),
                _buildMoodSliderRow('🎯', 'Мотивация', motivation,
                        (v) => setSheetState(() => motivation = v)),
                const SizedBox(height: 20),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: TextStyle(
                    color: _Power.textPrimary(widget.isDark),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Заметки о самочувствии…',
                    hintStyle: TextStyle(
                      color: _Power.textTertiary(widget.isDark),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: _Power.card2(widget.isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      setSheetState(() => selectedPhoto = File(image.path));
                    }
                  },
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _Power.card2(widget.isDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _Power.separator(widget.isDark),
                        width: 0.5,
                      ),
                    ),
                    child: selectedPhoto != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        selectedPhoto!,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _Power.volt.withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            color: _Power.volt,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Добавить фото тренировки',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            _Power.textSecondary(widget.isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
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
                            _Power.textSecondary(widget.isDark),
                            side: BorderSide(
                                color: _Power.separator(widget.isDark)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Пропустить',
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
                          onPressed: () {
                            HapticFeedback.mediumImpact();
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
                            backgroundColor: _Power.volt,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'НАЧАТЬ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  fontSize: 15,
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

  Widget _buildMoodSliderRow(
      String emoji, String label, double value, Function(double) onChanged) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _Power.textSecondary(widget.isDark),
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _Power.volt,
              inactiveTrackColor: _Power.volt.withOpacity(0.15),
              thumbColor: _Power.volt,
              overlayColor: _Power.volt.withOpacity(0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '${value.toInt()}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _Power.textPrimary(widget.isDark),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // ЛОГИКА
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
    debugPrint(
        '✅ Сохранён подход: ex ${step.exerciseIndex}, set ${step.setIndex}, '
            'круг ${step.circuitNumber}');
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
    HapticFeedback.lightImpact();
    setState(() {
      _currentStepIndex++;
    });
    if (_currentStepIndex >= _steps.length) {
      _finishWorkout();
    }
  }

  void _skipExercise() {
    HapticFeedback.mediumImpact();
    final step = _currentStep;
    if (step == null) return;
    setState(() {
      int next = _currentStepIndex + 1;
      if (_isCircuitMode) {
        while (next < _steps.length &&
            _steps[next].exerciseIndex == step.exerciseIndex &&
            _steps[next].circuitNumber == step.circuitNumber) {
          next++;
        }
      } else {
        while (next < _steps.length &&
            _steps[next].exerciseIndex == step.exerciseIndex) {
          next++;
        }
      }
      _currentStepIndex = next;
    });
    if (_currentStepIndex >= _steps.length) {
      _finishWorkout();
    }
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
    if (_isFinishing) return;
    if (_phase == WorkoutPhase.completed) return;
    if (_savedLogId != null) return;

    if (_completedData.isEmpty) {
      if (mounted) setState(() => _phase = WorkoutPhase.completed);
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
        final format =
        _formatToSaveForCategory(cat, _resolveFormatOf(idx));
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

      if (mounted) {
        setState(() => _phase = WorkoutPhase.completed);
      }
    } catch (e) {
      debugPrint('❌ Ошибка сохранения: $e');
      if (mounted) setState(() => _phase = WorkoutPhase.completed);
    }
  }

  Future<bool> _showExitDialog(BuildContext context, bool isDark) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60),
        child: Container(
          decoration: BoxDecoration(
            color: _Power.card(isDark),
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
                      'Прервать тренировку?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Прогресс не будет сохранён',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _Power.textSecondary(isDark),
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
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: const Text(
                          'Продолжить',
                          style: TextStyle(
                            fontSize: 17,
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
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: const Text(
                          'Прервать',
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

// ==================== МОДЕЛИ ====================

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
          ? '${weight.toStringAsFixed(0)}кг×$reps'
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
// STEPPER COMPACT — числовое поле с ± кнопками
// ══════════════════════════════════════════════════════════

class _StepperCompact extends StatefulWidget {
  final String label;
  final String unit;
  final double value;
  final double step;
  final double min;
  final double max;
  final bool isDecimal;
  final Color accent;
  final String Function(double)? formatValue;
  final ValueChanged<double> onChanged;

  const _StepperCompact({
    required this.label,
    required this.unit,
    required this.value,
    required this.step,
    required this.min,
    required this.max,
    required this.isDecimal,
    required this.accent,
    this.formatValue,
    required this.onChanged,
  });

  @override
  State<_StepperCompact> createState() => _StepperCompactState();
}

class _StepperCompactState extends State<_StepperCompact> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant _StepperCompact old) {
    super.didUpdateWidget(old);
    final expected = _format(widget.value);
    if (_ctrl.text != expected) {
      _ctrl.text = expected;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _format(double v) {
    if (widget.formatValue != null) return widget.formatValue!(v);
    if (widget.isDecimal) return v.toStringAsFixed(1);
    return v.toStringAsFixed(0);
  }

  void _bump(double delta) {
    HapticFeedback.selectionClick();
    final nv = (widget.value + delta).clamp(widget.min, widget.max);
    widget.onChanged(nv);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.accent.withOpacity(0.20),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: widget.accent.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                widget.unit,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.isDecimal,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) {
              if (v.isEmpty) return;
              final parsed = widget.isDecimal
                  ? double.tryParse(v.replaceAll(',', '.'))
                  : int.tryParse(v)?.toDouble();
              if (parsed != null) {
                widget.onChanged(
                  parsed.clamp(widget.min, widget.max),
                );
              }
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _bump(-widget.step),
                  child: Container(
                    height: 30,
                    margin: const EdgeInsets.only(left: 6, right: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.remove_rounded,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _bump(widget.step),
                  child: Container(
                    height: 30,
                    margin: const EdgeInsets.only(left: 3, right: 6),
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: widget.accent,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// DIALOG ЗАВЕРШЕНИЯ ПОДХОДА (strength / bodyweight)
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
  final bool isDark;
  final ExerciseFormat format;
  final _ExCategory category;
  final SetConfig plannedSet;
  final bool isWarmup;

  const _SetCompletionSheet({
    required this.isDark,
    required this.format,
    required this.category,
    required this.plannedSet,
    required this.isWarmup,
  });

  @override
  State<_SetCompletionSheet> createState() => _SetCompletionSheetState();
}

class _SetCompletionSheetState extends State<_SetCompletionSheet> {
  late SetConfig _planned;
  late SetConfig _actual;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _planned = widget.plannedSet;
    _actual = SetConfig.fromExerciseSet(_planned.toExerciseSet(1));
    _initControllers();
  }

  void _initControllers() {
    for (final m in _metricsToShow()) {
      if (m == ExerciseMetric.intensity) continue;
      if (m == ExerciseMetric.tempo) continue;
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
        return [ExerciseMetric.holdSeconds, ExerciseMetric.intensity];
      case _ExCategory.timedSets:
        return [
          ExerciseMetric.duration,
          ExerciseMetric.reps,
          ExerciseMetric.intensity,
        ];
      case _ExCategory.cardio:
        return [ExerciseMetric.distance, ExerciseMetric.duration];
      case _ExCategory.combat:
        return [
          ExerciseMetric.rounds,
          ExerciseMetric.roundDuration,
          ExerciseMetric.restBetweenRounds,
        ];
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Color _accentForCategory() {
    switch (widget.category) {
      case _ExCategory.strength:
        return _Power.volt;
      case _ExCategory.bodyweight:
        return _Power.lime;
      case _ExCategory.hold:
        return _Power.plasma;
      case _ExCategory.timedSets:
        return _Power.green;
      case _ExCategory.cardio:
        return _Power.ice;
      case _ExCategory.combat:
        return _Power.magma;
    }
  }

  String _categoryTitle() {
    switch (widget.category) {
      case _ExCategory.strength:
        return 'СИЛОВОЕ';
      case _ExCategory.bodyweight:
        return 'СВОЙ ВЕС';
      case _ExCategory.hold:
        return 'СТАТИКА';
      case _ExCategory.timedSets:
        return 'НА ВРЕМЯ';
      case _ExCategory.cardio:
        return 'КАРДИО';
      case _ExCategory.combat:
        return 'РАУНДЫ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = _accentForCategory();

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: _Power.textTertiary(isDark),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withOpacity(0.24),
                      accent.withOpacity(0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _categoryTitle().split(' ').first,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ПОДХОД ВЫПОЛНЕН?',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _categoryTitle(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: _Power.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, color: accent, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'ПЛАН:',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _planSummary(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _Power.textPrimary(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ..._metricsToShow().map((m) {
                if (m == ExerciseMetric.intensity) {
                  return _buildIntensitySlider(isDark);
                }
                return _buildNumericField(isDark, m, accent);
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
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
                          foregroundColor: _Power.textSecondary(isDark),
                          side: BorderSide(color: _Power.separator(isDark)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.replay_rounded, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'ПОВТОРИТЬ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          _SetResult(
                            action: _SetAction.skip,
                            reps: _actual.reps,
                            weight: _actual.weight,
                            isWarmup: _actual.isWarmup,
                            format: widget.format,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _Power.volt,
                          side: BorderSide(
                              color: _Power.volt.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.skip_next_rounded, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'ПРОПУСТИТЬ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 56,
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
                    backgroundColor: _Power.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: _Power.green.withOpacity(0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'ВЫПОЛНЕНО',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
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
    );
  }

  String _planSummary() {
    switch (widget.category) {
      case _ExCategory.strength:
        return '${_planned.weight.toStringAsFixed(0)}кг × ${_planned.reps}';
      case _ExCategory.bodyweight:
        return '${_planned.reps} повт.';
      case _ExCategory.hold:
        return '${_planned.holdSeconds ?? 0}с';
      case _ExCategory.timedSets:
        return '${_planned.duration}с · ${_planned.reps} повт.';
      case _ExCategory.cardio:
        return '${(_planned.distance ?? 0).toStringAsFixed(1)}км · ${_planned.duration}с';
      case _ExCategory.combat:
        return '${_planned.rounds ?? 0} × ${_planned.roundDuration ?? 0}с';
    }
  }

  Widget _buildNumericField(bool isDark, ExerciseMetric m, Color accent) {
    final controller = _controllers[m.name];
    final step = _stepForMetric(m);
    final max = _maxForMetric(m);
    final value = _actual.metricValue(m) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Text(m.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  '${m.displayName.toUpperCase()} (${m.unit})',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: _Power.textTertiary(isDark),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final nv = (value - step).clamp(0, max).toDouble();
                  _updateMetric(m, nv);
                  controller?.text = nv > 0 ? _fmt(nv, m) : '';
                },
                child: Container(
                  width: 42,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _Power.textTertiary(isDark).withOpacity(0.08),
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12)),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: _Power.textSecondary(isDark),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: m.isDecimal,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: _Power.textPrimary(isDark),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: _Power.card2(isDark),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintStyle: TextStyle(
                        color: _Power.textTertiary(isDark),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
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
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final nv = (value + step).clamp(0, max).toDouble();
                  _updateMetric(m, nv);
                  controller?.text = nv > 0 ? _fmt(nv, m) : '';
                },
                child: Container(
                  width: 42,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(12)),
                  ),
                  child: Icon(Icons.add_rounded, size: 18, color: accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntensitySlider(bool isDark) {
    final v = _actual.intensity.clamp(1, 10).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Text('💪', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            'ИНТЕНС.',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: _Power.textTertiary(isDark),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 10),
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
                  setState(() => _actual.intensity = nv.toInt());
                },
              ),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${v.toInt()}/10',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _Power.volt,
              ),
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
        case ExerciseMetric.rpe:
          _actual.rpe = v;
          break;
        case ExerciseMetric.restSeconds:
          _actual.restSeconds = v.toInt();
          break;
        case ExerciseMetric.duration:
          _actual.duration = v.toInt();
          break;
        case ExerciseMetric.distance:
          _actual.distance = v;
          break;
        case ExerciseMetric.pace:
          _actual.pace = v;
          break;
        case ExerciseMetric.heartRate:
          _actual.heartRate = v.toInt();
          break;
        case ExerciseMetric.calories:
          _actual.calories = v.toInt();
          break;
        case ExerciseMetric.incline:
          _actual.incline = v;
          break;
        case ExerciseMetric.resistance:
          _actual.resistance = v;
          break;
        case ExerciseMetric.rounds:
          _actual.rounds = v.toInt();
          break;
        case ExerciseMetric.roundDuration:
          _actual.roundDuration = v.toInt();
          break;
        case ExerciseMetric.restBetweenRounds:
          _actual.restBetweenRounds = v.toInt();
          break;
        case ExerciseMetric.punches:
          _actual.punches = v.toInt();
          break;
        case ExerciseMetric.holdSeconds:
          _actual.holdSeconds = v.toInt();
          break;
        case ExerciseMetric.tempo:
          _actual.tempo = v.toString();
          break;
        case ExerciseMetric.intensity:
          _actual.intensity = v.toInt();
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
      case ExerciseMetric.rpe:
        return 0.5;
      case ExerciseMetric.restSeconds:
        return 15;
      case ExerciseMetric.duration:
        return 15;
      case ExerciseMetric.distance:
        return 0.1;
      case ExerciseMetric.pace:
        return 0.1;
      case ExerciseMetric.heartRate:
        return 5;
      case ExerciseMetric.calories:
        return 10;
      case ExerciseMetric.incline:
        return 1;
      case ExerciseMetric.resistance:
        return 1;
      case ExerciseMetric.rounds:
        return 1;
      case ExerciseMetric.roundDuration:
        return 30;
      case ExerciseMetric.restBetweenRounds:
        return 15;
      case ExerciseMetric.punches:
        return 10;
      case ExerciseMetric.holdSeconds:
        return 15;
      case ExerciseMetric.tempo:
      case ExerciseMetric.intensity:
        return 1;
    }
  }

  double _maxForMetric(ExerciseMetric m) {
    switch (m) {
      case ExerciseMetric.reps:
        return 200;
      case ExerciseMetric.weight:
        return 500;
      case ExerciseMetric.rpe:
        return 10;
      case ExerciseMetric.restSeconds:
        return 600;
      case ExerciseMetric.duration:
        return 3600;
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
      case ExerciseMetric.tempo:
      case ExerciseMetric.intensity:
        return 10;
    }
  }
}

// ══════════════════════════════════════════════════════════
// HOLD TIMER SCREEN — секундомер для статики
// (планка, вакуум, йога, растяжка)
// ══════════════════════════════════════════════════════════

class _HoldTimerScreen extends StatefulWidget {
  final bool isDark;
  final String exerciseName;
  final int plannedSeconds;
  final int setNumber;
  final int totalSets;
  final void Function(int actualSeconds) onComplete;
  final VoidCallback onSkip;
  final VoidCallback onExit;

  const _HoldTimerScreen({
    required this.isDark,
    required this.exerciseName,
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

class _HoldTimerScreenState extends State<_HoldTimerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  bool _running = false;
  bool _targetReached = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _watch.start();
    _ticker = Timer.periodic(
        const Duration(milliseconds: 200), (_) => _onTick());
    _running = true;
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {
      if (_watch.elapsed.inSeconds >= widget.plannedSeconds &&
          !_targetReached) {
        _targetReached = true;
        HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ticker?.cancel();
    _watch.stop();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_running) {
      _watch.stop();
      _ticker?.cancel();
    } else {
      _watch.start();
      _ticker = Timer.periodic(
          const Duration(milliseconds: 200), (_) => _onTick());
    }
    setState(() => _running = !_running);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _watch.stop();
    _watch.reset();
    _ticker?.cancel();
    setState(() {
      _running = false;
      _targetReached = false;
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const accent = _Power.plasma;
    final isDark = widget.isDark;
    final elapsed = _watch.elapsed.inSeconds;
    final progress = widget.plannedSeconds > 0
        ? (elapsed / widget.plannedSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _roundBtn(Icons.close_rounded, _Power.red, widget.onExit),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'СТАТИКА • ПОДХОД ${widget.setNumber}/${widget.totalSets}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.exerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  _roundBtn(
                      Icons.skip_next_rounded, accent, widget.onSkip),
                ],
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final glow = _running
                    ? (_targetReached
                    ? 0.45 + _pulse.value * 0.35
                    : 0.35 + _pulse.value * 0.35)
                    : 0.12;
                final color = _targetReached ? _Power.green : accent;
                return SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 12,
                          valueColor: AlwaysStoppedAnimation(
                              color.withOpacity(0.10)),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(glow * 0.5),
                              blurRadius: 40,
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _fmt(_watch.elapsed),
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2.5,
                              height: 1,
                              color: _targetReached ? _Power.green : Colors.white,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'цель: ${widget.plannedSeconds}с',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: _Power.textTertiary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            if (_targetReached)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _Power.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _Power.green.withOpacity(0.35),
                        width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: _Power.green, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Цель достигнута! Продолжай или сохраняй.',
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
              ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _ctrlBtn(
                      _running
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      _running ? 'ПАУЗА' : 'СТАРТ',
                      _running ? _Power.plasma : _Power.green,
                      _toggle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ctrlBtn(
                        Icons.refresh_rounded, 'СБРОС', _Power.red, _reset),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onComplete(_watch.elapsed.inSeconds);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Power.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: _Power.green.withOpacity(0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'ЗАПИСАТЬ УДЕРЖАНИЕ',
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
      ),
    );
  }

  Widget _roundBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _ctrlBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.24), color.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.32), width: 0.7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// TIMED SETS TIMER SCREEN — секундомер + поле повторов
// (берпи, скакалка, альпинист, джампинг джек, ножницы)
// ══════════════════════════════════════════════════════════

class _TimedSetsTimerScreen extends StatefulWidget {
  final bool isDark;
  final String exerciseName;
  final int plannedDuration;
  final int plannedReps;
  final int setNumber;
  final int totalSets;
  final void Function(int duration, int reps) onComplete;
  final VoidCallback onSkip;
  final VoidCallback onExit;

  const _TimedSetsTimerScreen({
    required this.isDark,
    required this.exerciseName,
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

class _TimedSetsTimerScreenState extends State<_TimedSetsTimerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  bool _running = false;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _watch.start();
    _ticker = Timer.periodic(
        const Duration(milliseconds: 200), (_) => setState(() {}));
    _running = true;
    _repsController = TextEditingController(
      text: widget.plannedReps > 0 ? '${widget.plannedReps}' : '',
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ticker?.cancel();
    _watch.stop();
    _repsController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_running) {
      _watch.stop();
      _ticker?.cancel();
    } else {
      _watch.start();
      _ticker = Timer.periodic(
          const Duration(milliseconds: 200), (_) => setState(() {}));
    }
    setState(() => _running = !_running);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _watch.stop();
    _watch.reset();
    _ticker?.cancel();
    setState(() {
      _running = false;
      _repsController.text = '';
    });
  }

  int get _reps {
    final parsed = int.tryParse(_repsController.text);
    return parsed ?? 0;
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const accent = _Power.green;
    final isDark = widget.isDark;

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _roundBtn(Icons.close_rounded, _Power.red, widget.onExit),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'НА ВРЕМЯ • ПОДХОД ${widget.setNumber}/${widget.totalSets}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.exerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  _roundBtn(
                      Icons.skip_next_rounded, accent, widget.onSkip),
                ],
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final glow = _running ? 0.35 + _pulse.value * 0.35 : 0.12;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 34, vertical: 22),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: accent.withOpacity(0.28),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(glow * 0.5),
                        blurRadius: 40,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: Text(
                    _fmt(_watch.elapsed),
                    style: TextStyle(
                      fontSize: 68,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -3.0,
                      height: 1,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      shadows: _running
                          ? [
                        Shadow(
                          color: accent.withOpacity(0.6),
                          blurRadius: 24,
                        ),
                      ]
                          : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ЦЕЛЬ: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: _Power.textTertiary(isDark),
                    ),
                  ),
                  Text(
                    '${widget.plannedDuration}с',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  if (widget.plannedReps > 0) ...[
                    Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 11,
                        color: _Power.textTertiary(isDark),
                      ),
                    ),
                    Text(
                      '${widget.plannedReps} повт.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                color: _Power.card(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.04),
                  width: 0.6,
                ),
              ),
              child: Row(
                children: [
                  const Text('🔁', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Повторы',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: accent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: _Power.textTertiary(isDark),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'раз',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _Power.textTertiary(isDark),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _miniRoundBtn(
                    Icons.remove_rounded,
                        () {
                      HapticFeedback.selectionClick();
                      final v = (_reps - 1).clamp(0, 999);
                      _repsController.text = v > 0 ? '$v' : '';
                      setState(() {});
                    },
                    accent,
                  ),
                  _miniRoundBtn(
                    Icons.add_rounded,
                        () {
                      HapticFeedback.selectionClick();
                      final v = (_reps + 1).clamp(0, 999);
                      _repsController.text = '$v';
                      setState(() {});
                    },
                    accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _ctrlBtn(
                      _running
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      _running ? 'ПАУЗА' : 'СТАРТ',
                      _running ? _Power.plasma : _Power.green,
                      _toggle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ctrlBtn(
                        Icons.refresh_rounded, 'СБРОС', _Power.red, _reset),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onComplete(
                        _watch.elapsed.inSeconds, _reps);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Power.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: _Power.green.withOpacity(0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'ЗАПИСАТЬ',
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
      ),
    );
  }

  Widget _roundBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _miniRoundBtn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _ctrlBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.24), color.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.32), width: 0.7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// CARDIO — живой секундомер (бег, вело, плавание)
// ══════════════════════════════════════════════════════════

class _CardioTimerScreen extends StatefulWidget {
  final bool isDark;
  final String exerciseName;
  final double plannedDistance;
  final int plannedDuration;
  final int setNumber;
  final int totalSets;
  final void Function(double distance, int duration) onComplete;
  final VoidCallback onSkip;
  final VoidCallback onExit;

  const _CardioTimerScreen({
    required this.isDark,
    required this.exerciseName,
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

class _CardioTimerScreenState extends State<_CardioTimerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  double _distance = 0;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _distance = widget.plannedDistance;
    _watch.start();
    _ticker = Timer.periodic(
        const Duration(milliseconds: 200), (_) => setState(() {}));
    _running = true;
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ticker?.cancel();
    _watch.stop();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_running) {
      _watch.stop();
      _ticker?.cancel();
    } else {
      _watch.start();
      _ticker = Timer.periodic(
          const Duration(milliseconds: 200), (_) => setState(() {}));
    }
    setState(() => _running = !_running);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _watch.stop();
    _watch.reset();
    _ticker?.cancel();
    setState(() {
      _running = false;
      _distance = 0;
    });
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const accent = _Power.ice;
    final isDark = widget.isDark;

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _roundBtn(Icons.close_rounded, _Power.red, widget.onExit),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'КАРДИО • ОТРЕЗОК ${widget.setNumber}/${widget.totalSets}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.exerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  _roundBtn(Icons.skip_next_rounded, accent, widget.onSkip),
                ],
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final glow = _running ? 0.35 + _pulse.value * 0.35 : 0.12;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 34, vertical: 22),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: accent.withOpacity(0.28),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(glow * 0.5),
                        blurRadius: 40,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: Text(
                    _fmt(_watch.elapsed),
                    style: TextStyle(
                      fontSize: 68,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -3.0,
                      height: 1,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      shadows: _running
                          ? [
                        Shadow(
                          color: accent.withOpacity(0.6),
                          blurRadius: 24,
                        ),
                      ]
                          : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                color: _Power.card(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.04),
                  width: 0.6,
                ),
              ),
              child: Row(
                children: [
                  const Text('📏', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Дистанция',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _Power.textPrimary(isDark),
                        )),
                  ),
                  Text(
                    _distance.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: accent,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('км',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _Power.textTertiary(isDark),
                      )),
                  const SizedBox(width: 4),
                  _miniRoundBtn(
                    Icons.remove_rounded,
                        () {
                      HapticFeedback.selectionClick();
                      setState(() =>
                      _distance = (_distance - 0.1).clamp(0.0, 999.0));
                    },
                    accent,
                  ),
                  _miniRoundBtn(
                    Icons.add_rounded,
                        () {
                      HapticFeedback.selectionClick();
                      setState(() =>
                      _distance = (_distance + 0.1).clamp(0.0, 999.0));
                    },
                    accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _ctrlBtn(
                      _running
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      _running ? 'ПАУЗА' : 'СТАРТ',
                      _running ? _Power.plasma : _Power.green,
                      _toggle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ctrlBtn(
                        Icons.refresh_rounded, 'СБРОС', _Power.red, _reset),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onComplete(
                        _distance, _watch.elapsed.inSeconds);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Power.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: _Power.green.withOpacity(0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'ЗАПИСАТЬ ОТРЕЗОК',
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
      ),
    );
  }

  Widget _roundBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _miniRoundBtn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _ctrlBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.24), color.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.32), width: 0.7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// COMBAT — раунд-таймер с авто-переходом
// ══════════════════════════════════════════════════════════

enum _CombatPhase { idle, round, rest, done }

class _CombatTimerScreen extends StatefulWidget {
  final bool isDark;
  final String exerciseName;
  final int totalRounds;
  final int roundDurationSec;
  final int restBetweenSec;
  final void Function(int completedRounds) onComplete;
  final VoidCallback onSkip;
  final VoidCallback onExit;

  const _CombatTimerScreen({
    required this.isDark,
    required this.exerciseName,
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
  _CombatPhase _phase = _CombatPhase.idle;
  int _currentRound = 1;
  int _remaining = 0;
  Timer? _timer;
  bool _paused = false;
  int _completed = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _CombatPhase.round;
      _currentRound = 1;
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
          if (_remaining == 3 || _remaining == 2 || _remaining == 1) {
            HapticFeedback.selectionClick();
          }
        } else {
          HapticFeedback.heavyImpact();
          _advance();
        }
      });
    });
  }

  void _advance() {
    if (_phase == _CombatPhase.round) {
      _completed = _currentRound;
      if (_currentRound >= widget.totalRounds) {
        _phase = _CombatPhase.done;
        _remaining = 0;
        _timer?.cancel();
      } else {
        if (widget.restBetweenSec > 0) {
          _phase = _CombatPhase.rest;
          _remaining = widget.restBetweenSec;
        } else {
          _currentRound++;
          _phase = _CombatPhase.round;
          _remaining = widget.roundDurationSec;
        }
      }
    } else if (_phase == _CombatPhase.rest) {
      _currentRound++;
      _phase = _CombatPhase.round;
      _remaining = widget.roundDurationSec;
      HapticFeedback.mediumImpact();
    }
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() => _paused = !_paused);
  }

  void _skipPhase() {
    HapticFeedback.mediumImpact();
    setState(_advance);
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  Color get _phaseColor {
    switch (_phase) {
      case _CombatPhase.round:
        return _Power.magma;
      case _CombatPhase.rest:
        return _Power.green;
      case _CombatPhase.done:
        return _Power.plasma;
      case _CombatPhase.idle:
        return _Power.plasma;
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case _CombatPhase.round:
        return 'РАУНД';
      case _CombatPhase.rest:
        return 'ОТДЫХ';
      case _CombatPhase.done:
        return 'ГОТОВО';
      case _CombatPhase.idle:
        return 'ГОТОВ К СТАРТУ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = _phaseColor;
    final totalForPhase = _phase == _CombatPhase.rest
        ? widget.restBetweenSec
        : widget.roundDurationSec;
    final progress = totalForPhase > 0
        ? (1 - _remaining / totalForPhase).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _roundBtn(Icons.close_rounded, _Power.red, widget.onExit),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('РАУНДЫ',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                              color: _Power.plasma,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          widget.exerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  _roundBtn(
                      Icons.skip_next_rounded, _Power.plasma, widget.onSkip),
                ],
              ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: accent.withOpacity(0.32), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.7),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _phaseLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_phase == _CombatPhase.round || _phase == _CombatPhase.rest)
              Text(
                'РАУНД $_currentRound / ${widget.totalRounds}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: _Power.textSecondary(isDark),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 12,
                      valueColor:
                      AlwaysStoppedAnimation(accent.withOpacity(0.10)),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fmt(_remaining),
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -3.0,
                          height: 1,
                          color: Colors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          shadows: _remaining <= 10 &&
                              (_phase == _CombatPhase.round ||
                                  _phase == _CombatPhase.rest)
                              ? [
                            Shadow(
                              color: accent.withOpacity(0.8),
                              blurRadius: 24,
                            ),
                          ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _phase == _CombatPhase.rest
                            ? 'отдых'
                            : _phase == _CombatPhase.done
                            ? 'завершено'
                            : 'до конца',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: _Power.textTertiary(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (_phase == _CombatPhase.idle)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Power.plasma,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: _Power.plasma.withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'НАЧАТЬ РАУНДЫ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_phase == _CombatPhase.done)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onComplete(_completed);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Power.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'СОХРАНИТЬ РЕЗУЛЬТАТ',
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
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ctrlBtn(
                        _paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        _paused ? 'ДАЛЬШЕ' : 'ПАУЗА',
                        _paused ? _Power.green : _Power.plasma,
                        _togglePause,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ctrlBtn(Icons.skip_next_rounded,
                          'ПРОПУСТИТЬ', _Power.ice, _skipPhase),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _ctrlBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.24), color.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.32), width: 0.7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}