// features/nutrition/ui/screens/profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  Premium Design System (matches Fitness / Fuel screens)
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const bg         = Color(0xFFF6F7F9);
  static const surface    = Color(0xFFFFFFFF);
  static const text       = Color(0xFF1C2026);
  static const textMuted  = Color(0xFF7C818A);
  static const divider    = Color(0xFFE9EBEF);
  static const elevated   = Color(0xFFF0F1F4);

  static const peachSoft    = Color(0xFFFBEDE4);
  static const peachDeep    = Color(0xFFEF9563);
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF9381BB);
  static const greenSoft    = Color(0xFFE7F2ED);
  static const greenDeep    = Color(0xFF6C9E88);
  static const skySoft      = Color(0xFFE8EFF8);
  static const skyDeep      = Color(0xFF7E9DC6);
  static const yellowSoft   = Color(0xFFFDF5E6);
  static const yellowDeep   = Color(0xFFE0B054);
  static const pinkSoft     = Color(0xFFFCF0F2);
  static const pinkDeep     = Color(0xFFD17A8F);
}

class _Hero {
  static const bgTop    = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const accent   = Color(0xFFEF9563);
  static const textHigh = Colors.white;
  static const textLow  = Color(0xFFA4A6AA);
}

class _T {
  static final title1   = GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: _P.text);
  static final title2   = GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: _P.text);
  static final headline = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _P.text);
  static final body     = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: _P.textMuted);
  static final caption  = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
  static final overline = GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _P.textMuted);
  static final number   = GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: -0.5);
}

// ═══════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════
class ProfileSetupScreen extends StatefulWidget {
  final bool isDark;
  final NutritionProvider? provider;

  const ProfileSetupScreen({super.key, this.isDark = true, this.provider});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _ageController          = TextEditingController();
  final _weightController       = TextEditingController();
  final _heightController       = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _targetDaysController   = TextEditingController();
  final _stepsController        = TextEditingController();
  final _workoutsController     = TextEditingController();
  final _bodyFatController      = TextEditingController();

  Gender _gender                = Gender.male;
  ActivityLevel _activityLevel  = ActivityLevel.moderate;
  GoalType _goalType            = GoalType.maintain;
  GoalPace _goalPace            = GoalPace.moderate;

  int _currentStep  = 0;
  bool _isLoading   = true;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _targetDaysController.dispose();
    _stepsController.dispose();
    _workoutsController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════
  //  Provider
  // ═════════════════════════════════════════════════════════
  NutritionProvider get _provider {
    if (widget.provider != null) return widget.provider!;
    try {
      return Provider.of<NutritionProvider>(context, listen: false);
    } catch (e) {
      debugPrint('Ошибка получения NutritionProvider: $e');
      throw Exception('NutritionProvider не найден');
    }
  }

  void _loadProfile() {
    try {
      final profile = _provider.userProfile;
      if (profile != null) {
        _gender = profile.gender;
        _ageController.text    = profile.age.toString();
        _weightController.text = profile.weight.toString();
        _heightController.text = profile.height.toString();
        _activityLevel         = profile.activityLevel;
        _goalType              = profile.goalType;
        _goalPace              = profile.goalPace;
        if (profile.targetWeight != null) _targetWeightController.text = profile.targetWeight!.toString();
        if (profile.targetDays   != null) _targetDaysController.text   = profile.targetDays!.toString();
        _stepsController.text    = profile.stepsPerDay.toString();
        _workoutsController.text = profile.workoutsPerWeek.toString();
        if (profile.bodyFatPercentage > 0) _bodyFatController.text = profile.bodyFatPercentage.toString();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки профиля: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ═════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _P.bg,
        body: Center(
          child: SizedBox(
            width: 26, height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(_P.peachDeep),
            ),
          ),
        ),
      );
    }

    final provider = widget.provider ?? context.watch<NutritionProvider>();
    final profile = provider.userProfile;

    if (profile != null && _showResults) {
      return _buildResultsScreen(provider, profile);
    }

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(hasProfile: profile != null),
            _stepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 135),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroHeading(),
                    const SizedBox(height: 20),
                    _stepContent(provider),
                    const SizedBox(height: 16),
                    if (_currentStep == 1) _goalInsight(provider),
                    if (_currentStep == 2) _lifestyleInsight(provider),
                    const SizedBox(height: 24),
                    _navigationButtons(provider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──
  Widget _topBar({required bool hasProfile}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _P.surface, shape: BoxShape.circle,
                border: Border.all(color: _P.divider, width: 1),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: _P.text, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasProfile ? 'ПРОФИЛЬ' : 'НАСТРОЙКА',
                  style: _T.overline.copyWith(color: _P.peachDeep, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  hasProfile ? 'Настройки' : 'Профиль',
                  style: _T.title2.copyWith(fontSize: 22),
                ),
              ],
            ),
          ),
          if (hasProfile)
            GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); _showRecommendations(_provider); },
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _P.lavenderSoft, borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: _P.lavenderDeep, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  // ── Step indicator ──
  Widget _stepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: i == _currentStep ? 4 : 3,
                decoration: BoxDecoration(
                  color: i <= _currentStep ? _P.peachDeep : _P.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Hero heading ──
  Widget _heroHeading() {
    final titles = ['О тебе', 'Твоя цель', 'Твой ритм'];
    final subtitles = [
      'Рассчитаем твои персональные потребности.',
      'Выбери направление — остальное посчитаем сами.',
      'Чем точнее данные, тем точнее рекомендации.',
    ];
    final icons = [Icons.person_rounded, Icons.flag_rounded, Icons.directions_run_rounded];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            color: _P.peachSoft, borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icons[_currentStep], color: _P.peachDeep, size: 26),
        ),
        const SizedBox(height: 16),
        Text(titles[_currentStep], style: _T.title1.copyWith(fontSize: 28, letterSpacing: -1.0)),
        const SizedBox(height: 6),
        Text(
          subtitles[_currentStep],
          style: _T.body.copyWith(fontSize: 14, height: 1.45),
        ),
      ],
    );
  }

  // ── Step content ──
  Widget _stepContent(NutritionProvider provider) {
    switch (_currentStep) {
      case 0: return _personalStep(provider);
      case 1: return _goalsStep(provider);
      case 2: return _lifestyleStep(provider);
      default: return const SizedBox.shrink();
    }
  }

  // ═════════════════════════════════════════════════════════
  //  STEP 1: PERSONAL
  // ═════════════════════════════════════════════════════════
  Widget _personalStep(NutritionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('ПОЛ'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _genderCard(Gender.male,   'Мужской', '♂', _P.skyDeep,  _P.skySoft)),
            const SizedBox(width: 10),
            Expanded(child: _genderCard(Gender.female, 'Женский', '♀', _P.pinkDeep, _P.pinkSoft)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _inputField(
              title: 'ВОЗРАСТ', subtitle: 'Полных лет',
              controller: _ageController, suffix: 'лет', icon: Icons.cake_rounded,
            )),
            const SizedBox(width: 10),
            Expanded(child: _inputField(
              title: 'ВЕС', subtitle: 'Текущий',
              controller: _weightController, suffix: 'кг', icon: Icons.monitor_weight_rounded,
              onChanged: (_) => setState(() {}),
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _inputField(
              title: 'РОСТ', subtitle: 'Твой рост',
              controller: _heightController, suffix: 'см', icon: Icons.height_rounded,
              onChanged: (_) => setState(() {}),
            )),
            const SizedBox(width: 10),
            Expanded(child: _inputField(
              title: '% ЖИРА', subtitle: 'Опционально',
              controller: _bodyFatController, suffix: '%', icon: Icons.percent_rounded,
            )),
          ],
        ),
        const SizedBox(height: 16),
        _infoCard(
          icon: Icons.auto_awesome_rounded, color: _P.peachDeep,
          title: 'Не знаешь процент жира?',
          message: 'Оставь поле пустым — продолжим расчёт без него.',
        ),
      ],
    );
  }

  Widget _genderCard(Gender gender, String label, String symbol, Color accent, Color soft) {
    final selected = _gender == gender;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _gender = gender); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? soft : _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : _P.divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: selected ? Colors.white : soft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(symbol, style: TextStyle(
                color: accent, fontSize: 24, fontWeight: FontWeight.w600,
              )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(
                    color: _P.text, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2,
                  )),
                  const SizedBox(height: 2),
                  Text(selected ? 'ВЫБРАНО' : 'ВЫБРАТЬ', style: GoogleFonts.inter(
                    color: selected ? accent : _P.textMuted,
                    fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6,
                  )),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  STEP 2: GOALS
  // ═════════════════════════════════════════════════════════
  Widget _goalsStep(NutritionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('ЦЕЛЬ'),
        const SizedBox(height: 10),
        ...GoalType.values.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _goalCard(g),
        )),
        const SizedBox(height: 14),
        _label('СКОРОСТЬ'),
        const SizedBox(height: 10),
        Row(
          children: List.generate(GoalPace.values.length, (i) {
            final pace = GoalPace.values[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == GoalPace.values.length - 1 ? 0 : 8),
                child: _paceCard(pace),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _inputField(
              title: 'ЦЕЛЕВОЙ ВЕС', subtitle: 'Опционально',
              controller: _targetWeightController, suffix: 'кг', icon: Icons.flag_rounded,
            )),
            const SizedBox(width: 10),
            Expanded(child: _inputField(
              title: 'СРОК', subtitle: 'Опционально',
              controller: _targetDaysController, suffix: 'дней', icon: Icons.timelapse_rounded,
            )),
          ],
        ),
      ],
    );
  }

  Widget _goalCard(GoalType goal) {
    final selected = _goalType == goal;
    final info = _goalInfo(goal);
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _goalType = goal); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? info.soft : _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? info.color : _P.divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: selected ? Colors.white : info.soft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(info.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.title, style: GoogleFonts.inter(
                    color: _P.text, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2,
                  )),
                  const SizedBox(height: 2),
                  Text(info.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _P.textMuted, fontSize: 12, fontWeight: FontWeight.w400,
                      )),
                ],
              ),
            ),
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: selected ? info.color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? info.color : _P.divider,
                  width: selected ? 0 : 1.4,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paceCard(GoalPace pace) {
    final selected = _goalPace == pace;
    final info = _paceInfo(pace);
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _goalPace = pace); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? info.soft : _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? info.color : _P.divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(info.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(info.title, style: GoogleFonts.inter(
              color: selected ? info.color : _P.text,
              fontSize: 12, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  STEP 3: LIFESTYLE
  // ═════════════════════════════════════════════════════════
  Widget _lifestyleStep(NutritionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('АКТИВНОСТЬ'),
        const SizedBox(height: 10),
        ...ActivityLevel.values.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _activityCard(l),
        )),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _inputField(
              title: 'ШАГОВ В ДЕНЬ', subtitle: 'Среднее',
              controller: _stepsController, suffix: 'шагов', icon: Icons.directions_walk_rounded,
            )),
            const SizedBox(width: 10),
            Expanded(child: _inputField(
              title: 'ТРЕНИРОВОК', subtitle: 'В неделю',
              controller: _workoutsController, suffix: 'раз', icon: Icons.fitness_center_rounded,
            )),
          ],
        ),
        const SizedBox(height: 16),
        _profileLiveCard(provider),
      ],
    );
  }

  Widget _activityCard(ActivityLevel level) {
    final selected = _activityLevel == level;
    final info = _activityInfo(level);
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _activityLevel = level); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? info.soft : _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? info.color : _P.divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: selected ? Colors.white : info.soft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(info.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.title, style: GoogleFonts.inter(
                    color: _P.text, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2,
                  )),
                  const SizedBox(height: 2),
                  Text(info.subtitle, style: GoogleFonts.inter(
                    color: _P.textMuted, fontSize: 12, fontWeight: FontWeight.w400,
                  )),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: info.color, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  INPUT FIELD
  // ═════════════════════════════════════════════════════════
  Widget _inputField({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String suffix,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: _P.peachSoft, borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: _P.peachDeep, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(
                      color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                    )),
                    const SizedBox(height: 1),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w400,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: onChanged,
                  style: GoogleFonts.inter(
                    color: _P.text, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.8,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(suffix, style: GoogleFonts.inter(
                  color: _P.textMuted, fontSize: 12, fontWeight: FontWeight.w500,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  INSIGHTS
  // ═════════════════════════════════════════════════════════
  Widget _goalInsight(NutritionProvider provider) {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    if (weight <= 0 || height <= 0) return const SizedBox.shrink();

    final profile = _buildTempProfile();
    if (profile == null) return const SizedBox.shrink();

    return _calcCard(
      title: 'ПРЕДВАРИТЕЛЬНЫЙ РАСЧЁТ',
      subtitle: 'Ориентиры уже готовы',
      accent: _P.peachDeep,
      child: Column(
        children: [
          Row(
            children: [
              _calcStat('BMR', '${profile.bmr.round()}', 'ккал', _P.peachDeep),
              _calcStat('TDEE', '${profile.tdee.round()}', 'ккал', _P.yellowDeep),
              _calcStat('ИМТ', profile.bmi.toStringAsFixed(1), '', _P.greenDeep),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _P.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text('ЦЕЛЕВАЯ КАЛОРИЙНОСТЬ', style: GoogleFonts.inter(
                  color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6,
                )),
              ),
              Text('${profile.targetCalories.round()} ккал', style: GoogleFonts.inter(
                color: _P.peachDeep, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lifestyleInsight(NutritionProvider provider) {
    final profile = _buildTempProfile();
    if (profile == null) {
      return _infoCard(
        icon: Icons.info_outline_rounded, color: _P.peachDeep,
        title: 'Почти готово',
        message: 'Заполни основные данные выше — и здесь появится твой расчёт.',
      );
    }

    return _calcCard(
      title: 'ПЕРСОНАЛЬНЫЙ ПЛАН',
      subtitle: 'Проверь перед сохранением',
      accent: _P.greenDeep,
      child: Column(
        children: [
          Row(
            children: [
              _calcStat('ЦЕЛЬ',  '${profile.targetCalories.round()}',      'ккал', _P.peachDeep),
              _calcStat('БЕЛОК', '${profile.recommendedProtein.round()}',  'г',    _P.greenDeep),
              _calcStat('ВОДА',  '${profile.recommendedWater}',            'мл',   _P.skyDeep),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _P.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _summaryMini('🎯', _goalTypeDisplay(profile.goalType))),
              Expanded(child: _summaryMini('⚡', _goalPaceDisplay(profile.goalPace))),
              Expanded(child: _summaryMini('🏃', _activityDisplay(profile.activityLevel))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileLiveCard(NutritionProvider provider) {
    final profile = _buildTempProfile();
    if (profile == null) return const SizedBox.shrink();

    return _calcCard(
      title: 'ПРЕДПРОСМОТР',
      subtitle: 'Обновляется прямо во время настройки',
      accent: _P.lavenderDeep,
      child: Column(
        children: [
          Row(
            children: [
              _calcStat('BMR',  '${profile.bmr.round()}', 'ккал', _P.peachDeep),
              _calcStat('TDEE', '${profile.tdee.round()}', 'ккал', _P.yellowDeep),
              _calcStat('ИМТ',  profile.bmi.toStringAsFixed(1), '', _P.greenDeep),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _P.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(_goalTypeDisplay(profile.goalType).toUpperCase(),
                    style: GoogleFonts.inter(
                      color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6,
                    )),
              ),
              Text('${profile.targetCalories.round()} ккал/день', style: GoogleFonts.inter(
                color: _P.lavenderDeep, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.3,
              )),
            ],
          ),
        ],
      ),
    );
  }

  UserProfile? _buildTempProfile() {
    final age    = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (age == null || weight == null || height == null || age <= 0 || weight <= 0 || height <= 0) {
      return null;
    }

    return UserProfile(
      id: 'preview',
      gender: _gender,
      age: age,
      weight: weight,
      height: height,
      activityLevel: _activityLevel,
      goalType: _goalType,
      goalPace: _goalPace,
      targetWeight: double.tryParse(_targetWeightController.text),
      targetDays: int.tryParse(_targetDaysController.text),
      stepsPerDay: int.tryParse(_stepsController.text) ?? 5000,
      workoutsPerWeek: int.tryParse(_workoutsController.text) ?? 0,
      bodyFatPercentage: double.tryParse(_bodyFatController.text) ?? 0,
    );
  }

  Widget _calcCard({
    required String title,
    required String subtitle,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.auto_graph_rounded, color: accent, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(
                      color: _P.text, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                    )),
                    const SizedBox(height: 1),
                    Text(subtitle, style: GoogleFonts.inter(
                      color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w400,
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _calcStat(String title, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(
            color: color, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.4, height: 1,
          )),
          const SizedBox(height: 4),
          Text(unit.isEmpty ? title : '$title · $unit', style: GoogleFonts.inter(
            color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.4,
          )),
        ],
      ),
    );
  }

  Widget _summaryMini(String emoji, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w500,
              )),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  NAVIGATION
  // ═════════════════════════════════════════════════════════
  Widget _navigationButtons(NutritionProvider provider) {
    final isLast = _currentStep == 2;
    return Column(
      children: [
        Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentStep--);
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: _P.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _P.divider, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chevron_left_rounded, color: _P.text, size: 20),
                        const SizedBox(width: 4),
                        Text('НАЗАД', style: GoogleFonts.inter(
                          color: _P.text, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.6,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () async {
                  if (isLast) {
                    await _saveProfile(provider);
                  } else {
                    HapticFeedback.mediumImpact();
                    setState(() => _currentStep++);
                  }
                },
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: _P.peachDeep,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                      color: _P.peachDeep.withOpacity(0.30),
                      blurRadius: 16, offset: const Offset(0, 6),
                    )],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLast ? 'СОХРАНИТЬ' : 'ПРОДОЛЖИТЬ', style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.8,
                      )),
                      const SizedBox(width: 6),
                      Icon(
                        isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('ШАГ ${_currentStep + 1} ИЗ 3', style: GoogleFonts.inter(
          color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.0,
        )),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  RESULTS
  // ═════════════════════════════════════════════════════════
  Widget _buildResultsScreen(NutritionProvider provider, UserProfile profile) {
    final prediction = profile.goalPrediction;

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _resultTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 125),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _resultHero(profile),
                    const SizedBox(height: 16),
                    _mainMetrics(profile),
                    const SizedBox(height: 16),
                    _dailyTargets(profile),
                    if (prediction['canPredict'] == true) ...[
                      const SizedBox(height: 16),
                      _predictionCard(prediction),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _showResults = false);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _P.peachDeep, foregroundColor: Colors.white, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('ПОНЯТНО, ПОЕХАЛИ', style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.8,
                            )),
                          ],
                        ),
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

  Widget _resultTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _showResults = false); },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _P.surface, shape: BoxShape.circle,
                border: Border.all(color: _P.divider, width: 1),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: _P.text, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ПРОФИЛЬ', style: _T.overline.copyWith(color: _P.greenDeep, fontSize: 10)),
                const SizedBox(height: 2),
                Text('Готово', style: _T.title2.copyWith(fontSize: 22)),
              ],
            ),
          ),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _P.greenSoft, borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_rounded, color: _P.greenDeep, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _resultHero(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_P.greenSoft, Color(0xFFE0EFE6)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.verified_rounded, color: _P.greenDeep, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ПРОФИЛЬ ГОТОВ', style: GoogleFonts.inter(
                  color: _P.greenDeep, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                )),
                const SizedBox(height: 3),
                Text('Расчёты готовы', style: GoogleFonts.inter(
                  color: _P.text, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.4,
                )),
                const SizedBox(height: 3),
                Text('Дневник будет учитывать твои параметры.',
                    style: GoogleFonts.inter(
                      color: _P.textMuted, fontSize: 12, height: 1.35,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainMetrics(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _P.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.divider, width: 1),
      ),
      child: Column(
        children: [
          _metricRow('BMR',  '${profile.bmr.round()}',  'ККАЛ', _P.peachDeep),
          _metricDivider(),
          _metricRow('TDEE', '${profile.tdee.round()}', 'ККАЛ', _P.yellowDeep),
          _metricDivider(),
          _metricRow('ИМТ', profile.bmi.toStringAsFixed(1), profile.bmiCategory, _P.greenDeep),
          _metricDivider(),
          _metricRow('ЦЕЛЬ', _goalTypeDisplay(profile.goalType), _goalPaceDisplay(profile.goalPace), _P.lavenderDeep),
        ],
      ),
    );
  }

  Widget _metricRow(String title, String value, String subtitle, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(title, style: GoogleFonts.inter(
            color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6,
          )),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.inter(
            color: _P.text, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2,
          )),
        ),
        Text(subtitle, style: GoogleFonts.inter(
          color: color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2,
        )),
      ],
    );
  }

  Widget _metricDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Container(height: 1, color: _P.divider),
  );

  Widget _dailyTargets(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _P.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ТВОЯ ДНЕВНАЯ ЦЕЛЬ', style: GoogleFonts.inter(
            color: _P.peachDeep, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2,
          )),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${profile.targetCalories.round()}', style: GoogleFonts.inter(
                color: _P.peachDeep, fontSize: 36, fontWeight: FontWeight.w600,
                letterSpacing: -1.4, height: 1,
              )),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('ккал / день', style: GoogleFonts.inter(
                  color: _P.textMuted, fontSize: 12, fontWeight: FontWeight.w500,
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _targetPill('🥩', '${profile.recommendedProtein.round()}', 'г белка',    _P.greenDeep),
              const SizedBox(width: 8),
              _targetPill('🧈', '${profile.recommendedFat.round()}',     'г жиров',    _P.yellowDeep),
              const SizedBox(width: 8),
              _targetPill('🍞', '${profile.recommendedCarbs.round()}',   'г углевод.', _P.pinkDeep),
              const SizedBox(width: 8),
              _targetPill('💧', '${profile.recommendedWater}',           'мл воды',    _P.skyDeep),
            ],
          ),
        ],
      ),
    );
  }

  Widget _targetPill(String emoji, String value, String title, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.15), width: 0.8),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: GoogleFonts.inter(
                color: accent, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1,
              )),
            ),
            const SizedBox(height: 4),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _P.textMuted, fontSize: 9, fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  Widget _predictionCard(Map<String, dynamic> prediction) {
    final isLose = prediction['isLose'] == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.yellowSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.yellowDeep.withOpacity(0.20), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(isLose ? '📉' : '📈', style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ПРОГНОЗ', style: GoogleFonts.inter(
                  color: _P.yellowDeep, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                )),
                const SizedBox(height: 3),
                Text('${prediction['days']} дней', style: GoogleFonts.inter(
                  color: _P.text, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3,
                )),
                const SizedBox(height: 2),
                Text(
                  '${prediction['absDiff'].toStringAsFixed(1)} кг ${isLose ? 'сбросить' : 'набрать'}',
                  style: GoogleFonts.inter(
                    color: _P.textMuted, fontSize: 12, fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  INFO CARD
  // ═════════════════════════════════════════════════════════
  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _P.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(
                  color: _P.text, fontSize: 13, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 2),
                Text(message, style: GoogleFonts.inter(
                  color: _P.textMuted, fontSize: 12, height: 1.35,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: GoogleFonts.inter(
      color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2,
    ));
  }

  // ═════════════════════════════════════════════════════════
  //  SAVE
  // ═════════════════════════════════════════════════════════
  Future<void> _saveProfile(NutritionProvider provider) async {
    final age    = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (age == null || age <= 0 || weight == null || weight <= 0 || height == null || height <= 0) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Заполни возраст, вес и рост'),
        backgroundColor: _P.pinkDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }

    final profile = UserProfile(
      id: provider.userProfile?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      gender: _gender,
      age: age,
      weight: weight,
      height: height,
      activityLevel: _activityLevel,
      goalType: _goalType,
      goalPace: _goalPace,
      targetWeight: double.tryParse(_targetWeightController.text),
      targetDays: int.tryParse(_targetDaysController.text),
      stepsPerDay: int.tryParse(_stepsController.text) ?? 5000,
      workoutsPerWeek: int.tryParse(_workoutsController.text) ?? 0,
      bodyFatPercentage: double.tryParse(_bodyFatController.text) ?? 0,
    );

    HapticFeedback.mediumImpact();
    await provider.saveUserProfile(profile);

    if (!mounted) return;
    setState(() => _showResults = true);
  }

  // ═════════════════════════════════════════════════════════
  //  RECOMMENDATIONS SHEET
  // ═════════════════════════════════════════════════════════
  void _showRecommendations(NutritionProvider provider) {
    final profile = provider.userProfile;
    if (profile == null) return;
    HapticFeedback.selectionClick();

    final prediction  = profile.goalPrediction;
    final weekSummary = provider.getLast7DaysSummaries();
    final extras = <Map<String, dynamic>>[];

    if (profile.bmiCategory != 'Норма') {
      extras.add({
        'emoji': '⚖️',
        'title': 'Индекс массы тела',
        'message': 'ИМТ: ${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})',
        'color': _P.yellowDeep,
      });
    }

    final proteinPct = profile.targetCalories > 0
        ? (profile.recommendedProtein * 4 / profile.targetCalories * 100).round() : 0;
    final fatPct = profile.targetCalories > 0
        ? (profile.recommendedFat * 9 / profile.targetCalories * 100).round() : 0;
    final carbsPct = profile.targetCalories > 0
        ? (profile.recommendedCarbs * 4 / profile.targetCalories * 100).round() : 0;

    extras.add({
      'emoji': '📊',
      'title': 'Распределение БЖУ',
      'message': 'Белки $proteinPct% · Жиры $fatPct% · Углеводы $carbsPct%',
      'color': _P.peachDeep,
    });

    if (profile.recommendedWater > 2000) {
      extras.add({
        'emoji': '💧',
        'title': 'Водный баланс',
        'message': 'Рекомендуется ${profile.recommendedWater} мл воды в день.',
        'color': _P.skyDeep,
      });
    }

    const activityMessages = {
      ActivityLevel.sedentary:    'Добавь немного ежедневного движения.',
      ActivityLevel.light:        'Хороший старт. Постепенно увеличивай активность.',
      ActivityLevel.moderate:     'Отличный уровень активности.',
      ActivityLevel.active:       'Хороший темп. Следи за восстановлением.',
      ActivityLevel.veryActive:   'Высокая нагрузка — питание особенно важно.',
      ActivityLevel.professional: 'Очень высокая нагрузка. Поддерживай питание.',
    };

    extras.add({
      'emoji': '🏃',
      'title': 'Активность',
      'message': activityMessages[profile.activityLevel] ?? 'Продолжай в том же духе.',
      'color': _P.greenDeep,
    });

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        height: MediaQuery.of(sheetCtx).size.height * 0.86,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              _grabber(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: _P.lavenderSoft, borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.auto_awesome_rounded, color: _P.lavenderDeep, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('УМНЫЕ РЕКОМЕНДАЦИИ', style: GoogleFonts.inter(
                                  color: _P.lavenderDeep, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                                )),
                                const SizedBox(height: 2),
                                Text('На основе твоего профиля', style: GoogleFonts.inter(
                                  color: _P.textMuted, fontSize: 12,
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      _recCard('🎯', 'Целевая калорийность',
                          '${profile.targetCalories.round()} ккал/день',
                          'TDEE: ${profile.tdee.round()} ккал', _P.peachDeep),
                      _recCard('🥩', 'Белок',
                          '${profile.recommendedProtein.round()} г',
                          '${(profile.recommendedProtein / profile.weight).toStringAsFixed(1)} г/кг', _P.greenDeep),
                      _recCard('🧈', 'Жиры',
                          '${profile.recommendedFat.round()} г',
                          '$fatPct% от калорий', _P.yellowDeep),
                      _recCard('🍞', 'Углеводы',
                          '${profile.recommendedCarbs.round()} г',
                          '$carbsPct% от калорий', _P.pinkDeep),
                      _recCard('💧', 'Вода',
                          '${profile.recommendedWater} мл',
                          '${(profile.recommendedWater / profile.weight).round()} мл/кг', _P.skyDeep),

                      if (extras.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...extras.map((e) => _recExtra(e)),
                      ],

                      if (prediction['canPredict'] == true) ...[
                        const SizedBox(height: 8),
                        _recPrediction(prediction),
                      ],

                      if (weekSummary.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('НЕДЕЛЬНАЯ СТАТИСТИКА', style: GoogleFonts.inter(
                          color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                        )),
                        const SizedBox(height: 10),
                        ...weekSummary.take(7).map((d) => _weekRow(d)),
                      ],
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

  Widget _grabber() => Container(
    width: 36, height: 5,
    decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3)),
  );

  Widget _recCard(String emoji, String title, String value, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _P.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(
                  color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w500,
                )),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(
                  color: color, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.3,
                )),
              ],
            ),
          ),
          Text(subtitle, textAlign: TextAlign.right, style: GoogleFonts.inter(
            color: _P.textMuted, fontSize: 11, fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }

  Widget _recExtra(Map<String, dynamic> data) {
    final color = data['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _P.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['emoji'] as String, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((data['title'] as String).toUpperCase(), style: GoogleFonts.inter(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                )),
                const SizedBox(height: 3),
                Text(data['message'] as String, style: GoogleFonts.inter(
                  color: _P.textMuted, fontSize: 12, height: 1.4,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recPrediction(Map<String, dynamic> prediction) {
    final isLose = prediction['isLose'] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _P.yellowSoft, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.yellowDeep.withOpacity(0.20), width: 1),
      ),
      child: Row(
        children: [
          Text(isLose ? '📉' : '📈', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ПРОГНОЗ', style: GoogleFonts.inter(
                  color: _P.yellowDeep, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0,
                )),
                const SizedBox(height: 3),
                Text(
                  '${prediction['days']} дней · ${prediction['absDiff'].toStringAsFixed(1)} кг ${isLose ? 'сбросить' : 'набрать'}',
                  style: GoogleFonts.inter(
                    color: _P.text, fontSize: 13, fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekRow(dynamic data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _P.bg, borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('${data.calories.round()} ккал', style: GoogleFonts.inter(
              color: _P.text, fontSize: 12, fontWeight: FontWeight.w600,
            )),
          ),
          Text('Б ${data.protein.round()}', style: TextStyle(
            color: _P.greenDeep, fontSize: 11, fontWeight: FontWeight.w600,
          )),
          const SizedBox(width: 8),
          Text('Ж ${data.fat.round()}', style: TextStyle(
            color: _P.yellowDeep, fontSize: 11, fontWeight: FontWeight.w600,
          )),
          const SizedBox(width: 8),
          Text('У ${data.carbs.round()}', style: TextStyle(
            color: _P.pinkDeep, fontSize: 11, fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  INFO STRUCTS
  // ═════════════════════════════════════════════════════════
  _GoalInfo _goalInfo(GoalType goal) {
    switch (goal) {
      case GoalType.maintain:
        return _GoalInfo(
          emoji: '⚖️', title: 'Поддержание', subtitle: 'Сохранять текущий вес',
          color: _P.skyDeep, soft: _P.skySoft,
        );
      case GoalType.lose:
        return _GoalInfo(
          emoji: '🔥', title: 'Похудение', subtitle: 'Снизить вес',
          color: _P.peachDeep, soft: _P.peachSoft,
        );
      case GoalType.gain:
        return _GoalInfo(
          emoji: '📈', title: 'Набор веса', subtitle: 'Постепенно увеличить массу',
          color: _P.greenDeep, soft: _P.greenSoft,
        );
      case GoalType.muscleGain:
        return _GoalInfo(
          emoji: '💪', title: 'Набор мышц', subtitle: 'Фокус на мышечном росте',
          color: _P.lavenderDeep, soft: _P.lavenderSoft,
        );
      case GoalType.recomposition:
        return _GoalInfo(
          emoji: '🔄', title: 'Рекомпозиция', subtitle: 'Мышцы вверх, жир вниз',
          color: _P.yellowDeep, soft: _P.yellowSoft,
        );
    }
  }

  _PaceInfo _paceInfo(GoalPace pace) {
    switch (pace) {
      case GoalPace.slow:
        return _PaceInfo(emoji: '🐢', title: 'Медленно', color: _P.greenDeep, soft: _P.greenSoft);
      case GoalPace.moderate:
        return _PaceInfo(emoji: '⚡', title: 'Умеренно', color: _P.yellowDeep, soft: _P.yellowSoft);
      case GoalPace.fast:
        return _PaceInfo(emoji: '🚀', title: 'Быстро',   color: _P.pinkDeep,   soft: _P.pinkSoft);
    }
  }

  _ActivityInfo _activityInfo(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return _ActivityInfo(
          emoji: '🪑', title: 'Сидячий', subtitle: 'Минимум движения',
          color: _P.skyDeep, soft: _P.skySoft,
        );
      case ActivityLevel.light:
        return _ActivityInfo(
          emoji: '🚶', title: 'Лёгкий', subtitle: 'Немного прогулок',
          color: _P.greenDeep, soft: _P.greenSoft,
        );
      case ActivityLevel.moderate:
        return _ActivityInfo(
          emoji: '🏃', title: 'Умеренный', subtitle: 'Регулярная активность',
          color: _P.greenDeep, soft: _P.greenSoft,
        );
      case ActivityLevel.active:
        return _ActivityInfo(
          emoji: '💪', title: 'Активный', subtitle: 'Много движения',
          color: _P.yellowDeep, soft: _P.yellowSoft,
        );
      case ActivityLevel.veryActive:
        return _ActivityInfo(
          emoji: '🔥', title: 'Очень активный', subtitle: 'Высокая нагрузка',
          color: _P.peachDeep, soft: _P.peachSoft,
        );
      case ActivityLevel.professional:
        return _ActivityInfo(
          emoji: '🏆', title: 'Профессиональный', subtitle: 'Интенсивные тренировки',
          color: _P.lavenderDeep, soft: _P.lavenderSoft,
        );
    }
  }

  String _goalTypeDisplay(GoalType type) {
    switch (type) {
      case GoalType.maintain:       return 'Поддержание';
      case GoalType.lose:           return 'Похудение';
      case GoalType.gain:           return 'Набор веса';
      case GoalType.muscleGain:     return 'Набор мышц';
      case GoalType.recomposition:  return 'Рекомпозиция';
    }
  }

  String _goalPaceDisplay(GoalPace pace) {
    switch (pace) {
      case GoalPace.slow:     return 'Медленно';
      case GoalPace.moderate: return 'Умеренно';
      case GoalPace.fast:     return 'Быстро';
    }
  }

  String _activityDisplay(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:    return 'Сидячий';
      case ActivityLevel.light:        return 'Лёгкий';
      case ActivityLevel.moderate:     return 'Умеренный';
      case ActivityLevel.active:       return 'Активный';
      case ActivityLevel.veryActive:   return 'Очень активный';
      case ActivityLevel.professional: return 'Профи';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Info structs
// ═══════════════════════════════════════════════════════════════════
class _GoalInfo {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color soft;
  const _GoalInfo({
    required this.emoji, required this.title, required this.subtitle,
    required this.color, required this.soft,
  });
}

class _PaceInfo {
  final String emoji;
  final String title;
  final Color color;
  final Color soft;
  const _PaceInfo({
    required this.emoji, required this.title, required this.color, required this.soft,
  });
}

class _ActivityInfo {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color soft;
  const _ActivityInfo({
    required this.emoji, required this.title, required this.subtitle,
    required this.color, required this.soft,
  });
}