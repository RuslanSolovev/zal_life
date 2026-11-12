// features/nutrition/ui/screens/profile_setup_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  Design tokens
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF7C818A);
  static const divider = Color(0xFFE9EBEF);
  static const elevated = Color(0xFFF0F1F4);

  static const peachSoft = Color(0xFFFBEDE4);
  static const peachDeep = Color(0xFFEF9563);
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF9381BB);
  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF6C9E88);
  static const skySoft = Color(0xFFE8EFF8);
  static const skyDeep = Color(0xFF7E9DC6);
  static const yellowSoft = Color(0xFFFDF5E6);
  static const yellowDeep = Color(0xFFE0B054);
  static const pinkSoft = Color(0xFFFCF0F2);
  static const pinkDeep = Color(0xFFD17A8F);
}

class _Hero {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const accent = Color(0xFFEF9563);
  static const textHigh = Colors.white;
  static const textLow = Color(0xFFA4A6AA);
}

class _T {
  static final title2 = GoogleFonts.inter(
      fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: _P.text);
  static final headline = GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, color: _P.text);
  static final body = GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400, color: _P.textMuted);
  static final caption = GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
  static TextStyle get overline => GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _P.textMuted);
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

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _targetDaysController = TextEditingController();
  final _stepsController = TextEditingController();
  final _workoutsController = TextEditingController();
  final _bodyFatController = TextEditingController();

  final _pageController = PageController();
  final _scrollControllers = List.generate(3, (_) => ScrollController());

  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  GoalType _goalType = GoalType.maintain;
  GoalPace _goalPace = GoalPace.moderate;

  int _currentStep = 0;
  bool _isLoading = true;
  bool _showResults = false;
  bool _isFirstSave = true;
  bool _reduceMotion = false;

  // Field inline error keys
  final Map<String, String> _errors = {};

  // Cached temp profile (recomputed only when relevant fields change)
  UserProfile? _tempProfile;
  String _tempProfileKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
    // Listen for text changes to invalidate the temp profile / insight pill
    for (final c in [
      _ageController, _weightController, _heightController,
      _targetWeightController, _targetDaysController,
      _stepsController, _workoutsController, _bodyFatController,
    ]) {
      c.addListener(_onFieldChanged);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _ageController, _weightController, _heightController,
      _targetWeightController, _targetDaysController,
      _stepsController, _workoutsController, _bodyFatController,
    ]) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    _pageController.dispose();
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Duration _dur(int ms) =>
      _reduceMotion ? Duration.zero : Duration(milliseconds: ms);

  // §13 recompute temp profile at most once per text change
  void _onFieldChanged() {
    if (!mounted) return;
    _tempProfile = null;
    _tempProfileKey = '';
    setState(() {});
  }

  // ═════════════════════════════════════════════════════════
  //  Provider (preserved)
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

  // §14 detect first-save so confetti only plays once
  void _loadProfile() {
    try {
      final profile = _provider.userProfile;
      _isFirstSave = profile == null;
      if (profile != null) {
        _gender = profile.gender;
        _ageController.text = profile.age.toString();
        _weightController.text = profile.weight.toString();
        _heightController.text = profile.height.toString();
        _activityLevel = profile.activityLevel;
        _goalType = profile.goalType;
        _goalPace = profile.goalPace;
        if (profile.targetWeight != null) {
          _targetWeightController.text = profile.targetWeight!.toString();
        }
        if (profile.targetDays != null) {
          _targetDaysController.text = profile.targetDays!.toString();
        }
        _stepsController.text = profile.stepsPerDay.toString();
        _workoutsController.text = profile.workoutsPerWeek.toString();
        if (profile.bodyFatPercentage > 0) {
          _bodyFatController.text = profile.bodyFatPercentage.toString();
        }
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
            width: 26,
            height: 26,
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            children: [
              _buildDarkHero(hasProfile: profile != null),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentStep = i),
                  children: [
                    _StepView(
                      scrollController: _scrollControllers[0],
                      child: _personalStep(provider),
                    ),
                    _StepView(
                      scrollController: _scrollControllers[1],
                      child: _goalsStep(provider),
                    ),
                    _StepView(
                      scrollController: _scrollControllers[2],
                      child: _lifestyleStep(provider),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // §7 floating insight pill
          Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: _buildInsightPill(provider),
          ),
          // §3 bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildActionBar(provider),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  §2 DARK HERO
  // ═════════════════════════════════════════════════════════
  Widget _buildDarkHero({required bool hasProfile}) {
    final titles = ['О тебе', 'Твоя цель', 'Твой ритм'];
    final subtitles = [
      'Рассчитаем твои персональные потребности.',
      'Выбери направление — остальное посчитаем сами.',
      'Чем точнее данные, тем точнее рекомендации.',
    ];

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_Hero.bgTop, _Hero.bgBottom],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned(
                  top: -60,
                  right: -60,
                  child: IgnorePointer(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _Hero.accent.withOpacity(0.20),
                            _Hero.accent.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Press(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.08)),
                              ),
                              child: const Icon(Icons.chevron_left_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                          const Spacer(),
                          if (hasProfile) ...[
                            _Press(
                              onTap: () =>
                                  _showRecommendations(_provider),
                              child: Container(
                                height: 36,
                                padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.08)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.auto_awesome_rounded,
                                      color: _P.lavenderDeep, size: 14),
                                  const SizedBox(width: 6),
                                  Text('Советы',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          _stepPills(),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text('ШАГ ${_currentStep + 1} · ${_stepTitle(_currentStep)}',
                          style: GoogleFonts.inter(
                            color: _Hero.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          )),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: _dur(200),
                        child: Text(
                          titles[_currentStep],
                          key: ValueKey('title_$_currentStep'),
                          style: GoogleFonts.inter(
                            color: _Hero.textHigh,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: _dur(200),
                        child: Text(
                          subtitles[_currentStep],
                          key: ValueKey('sub_$_currentStep'),
                          style: GoogleFonts.inter(
                            color: _Hero.textLow,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
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

  String _stepTitle(int i) {
    switch (i) {
      case 0:
        return 'О ТЕБЕ';
      case 1:
        return 'ТВОЯ ЦЕЛЬ';
      default:
        return 'ТВОЙ РИТМ';
    }
  }

  Widget _stepPills() {
    return Row(
      children: List.generate(3, (i) {
        final isCurrent = i == _currentStep;
        final isPast = i < _currentStep;
        final bg = isCurrent
            ? _Hero.accent
            : isPast
            ? Colors.white.withOpacity(0.18)
            : Colors.white.withOpacity(0.06);
        final fg = isCurrent ? _Hero.bgTop : Colors.white;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
          child: AnimatedContainer(
            duration: _dur(200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${i + 1}',
                style: GoogleFonts.inter(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
          ),
        );
      }),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  §3 BOTTOM ACTION BAR
  // ═════════════════════════════════════════════════════════
  Widget _buildActionBar(NutritionProvider provider) {
    final isLast = _currentStep == 2;
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: _P.surface.withOpacity(0.92),
            border: const Border(top: BorderSide(color: _P.divider, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3-segment progress line
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                          child: AnimatedContainer(
                            duration: _dur(200),
                            height: 2,
                            decoration: BoxDecoration(
                              color: i <= _currentStep
                                  ? _P.peachDeep
                                  : _P.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      if (_currentStep > 0) ...[
                        _Press(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _goToStep(_currentStep - 1);
                          },
                          child: Container(
                            height: 54,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: _P.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _P.divider),
                            ),
                            child: Row(children: [
                              const Icon(Icons.chevron_left_rounded,
                                  size: 18, color: _P.text),
                              const SizedBox(width: 4),
                              Text('Назад',
                                  style: GoogleFonts.inter(
                                    color: _P.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: _Press(
                          onTap: () => _onPrimaryTap(provider, isLast),
                          child: AnimatedOpacity(
                            duration: _dur(160),
                            opacity: _canAdvance() ? 1 : 0.4,
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: _P.peachDeep,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _P.peachDeep.withOpacity(0.28),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: AnimatedSwitcher(
                                duration: _dur(180),
                                transitionBuilder: (child, anim) {
                                  final offset = Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(anim);
                                  return FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                        position: offset, child: child),
                                  );
                                },
                                child: Row(
                                  key: ValueKey('cta_$isLast'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isLast
                                          ? 'Сохранить профиль'
                                          : 'Продолжить',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      isLast
                                          ? Icons.check_rounded
                                          : Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  // §14 required-field check for CTA opacity
  bool _canAdvance() {
    if (_currentStep == 0) {
      return _ageController.text.trim().isNotEmpty &&
          _weightController.text.trim().isNotEmpty &&
          _heightController.text.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _onPrimaryTap(NutritionProvider provider, bool isLast) async {
    if (isLast) {
      await _saveProfile(provider);
    } else {
      if (!_validateCurrentStep()) return;
      HapticFeedback.lightImpact();
      _goToStep(_currentStep + 1);
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep != 0) return true;
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final errors = <String, String>{};
    if (age == null || age < 14 || age > 100) {
      errors['age'] = 'Введи корректный возраст';
    }
    if (weight == null || weight < 30 || weight > 250) {
      errors['weight'] = 'Введи корректный вес';
    }
    if (height == null || height < 120 || height > 230) {
      errors['height'] = 'Введи корректный рост';
    }
    if (errors.isEmpty) {
      setState(() => _errors.clear());
      return true;
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    HapticFeedback.lightImpact();
    return false;
  }

  void _goToStep(int i) {
    if (i < 0 || i > 2) return;
    setState(() => _currentStep = i);
    _pageController.animateToPage(
      i,
      duration: _dur(280),
      curve: Curves.easeOutCubic,
    );
  }

  // ═════════════════════════════════════════════════════════
  //  §7 FLOATING INSIGHT PILL
  // ═════════════════════════════════════════════════════════
  Widget _buildInsightPill(NutritionProvider provider) {
    if (_currentStep == 0) return const SizedBox.shrink();
    final profile = _getTempProfile();
    if (profile == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Semantics(
        label:
        'Предварительный расчёт, ${profile.targetCalories.round()} килокалорий в день',
        child: _Press(
          onTap: () => _showInsightSheet(profile),
          child: Container(
            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _P.divider),
              boxShadow: [
                BoxShadow(
                  color: _P.elevated.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _P.peachSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded,
                      color: _P.peachDeep, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ПРЕДВАРИТЕЛЬНО', style: _T.overline),
                      const SizedBox(height: 2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: profile.targetCalories,
                        ),
                        duration: _dur(400),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Text(
                          '≈ ${v.round()} ккал / день',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                            color: _P.text,
                            fontFeatures: [ui.FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: _P.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // §13 cached temp profile
  UserProfile? _getTempProfile() {
    final key =
        '${_ageController.text}|${_weightController.text}|${_heightController.text}'
        '|${_gender.name}|${_activityLevel.name}|${_goalType.name}|${_goalPace.name}'
        '|${_targetWeightController.text}|${_targetDaysController.text}'
        '|${_stepsController.text}|${_workoutsController.text}|${_bodyFatController.text}';
    if (_tempProfile != null && _tempProfileKey == key) return _tempProfile;
    _tempProfile = _buildTempProfile();
    _tempProfileKey = key;
    return _tempProfile;
  }

  // §9 insight detail sheet
  void _showInsightSheet(UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _grabber()),
                const SizedBox(height: 18),
                Text('ПРЕДВАРИТЕЛЬНЫЙ РАСЧЁТ',
                    style: _T.overline.copyWith(color: _P.peachDeep)),
                const SizedBox(height: 4),
                Text('Твои цифры', style: _T.title2),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${profile.targetCalories.round()}',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1.4,
                          height: 1,
                          color: _P.peachDeep,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        )),
                    const SizedBox(width: 6),
                    Text('ккал / день',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _P.textMuted,
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: _P.divider),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statCell('BMR', '${profile.bmr.round()}',
                        'ккал', _P.peachDeep),
                    _statCell('TDEE', '${profile.tdee.round()}',
                        'ккал', _P.yellowDeep),
                    _statCell('ИМТ', profile.bmi.toStringAsFixed(1),
                        profile.bmiCategory, _P.greenDeep),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: _P.divider),
                const SizedBox(height: 14),
                Text('БЖУ', style: _T.overline),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _macroPill('Б', profile.recommendedProtein.round(),
                        'г', _P.greenDeep),
                    const SizedBox(width: 8),
                    _macroPill('Ж', profile.recommendedFat.round(),
                        'г', _P.yellowDeep),
                    const SizedBox(width: 8),
                    _macroPill('У', profile.recommendedCarbs.round(),
                        'г', _P.pinkDeep),
                    const SizedBox(width: 8),
                    _macroPill('В', profile.recommendedWater, 'мл',
                        _P.skyDeep),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Это предварительно. Мы пересчитаем после сохранения.',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: _P.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCell(String label, String value, String sub, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: -0.4,
                height: 1,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              )),
          const SizedBox(height: 4),
          Text('$label · $sub',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _P.textMuted,
              )),
        ],
      ),
    );
  }

  Widget _macroPill(String l, num v, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text('$l ${v.round()}',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              )),
          const SizedBox(height: 2),
          Text(unit,
              style: GoogleFonts.inter(
                color: _P.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )),
        ]),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  §4 STEP 1 — PERSONAL
  // ═════════════════════════════════════════════════════════
  Widget _personalStep(NutritionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overline('ПОЛ'),
        const SizedBox(height: 8),
        _genderSegment(),
        const SizedBox(height: 20),
        _stepperField(
          label: 'ВОЗРАСТ',
          unit: 'лет',
          controller: _ageController,
          min: 14,
          max: 100,
          step: 1,
          precision: 0,
          errorKey: 'age',
        ),
        const SizedBox(height: 14),
        _stepperField(
          label: 'ВЕС',
          unit: 'кг',
          controller: _weightController,
          min: 30,
          max: 250,
          step: 0.5,
          precision: 1,
          errorKey: 'weight',
        ),
        const SizedBox(height: 14),
        _stepperField(
          label: 'РОСТ',
          unit: 'см',
          controller: _heightController,
          min: 120,
          max: 230,
          step: 1,
          precision: 0,
          errorKey: 'height',
        ),
        const SizedBox(height: 14),
        _stepperField(
          label: '% ЖИРА (ОПЦИОНАЛЬНО)',
          unit: '%',
          controller: _bodyFatController,
          min: 3,
          max: 60,
          step: 0.5,
          precision: 1,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 14, color: _P.peachDeep),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Не знаешь процент жира? Оставь пустым.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: _P.textMuted, height: 1.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _genderSegment() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _genderSegmentBtn(Gender.male, 'Мужской', Icons.male_rounded),
          const SizedBox(width: 4),
          _genderSegmentBtn(Gender.female, 'Женский', Icons.female_rounded),
        ],
      ),
    );
  }

  Widget _genderSegmentBtn(Gender g, String label, IconData icon) {
    final selected = _gender == g;
    return Expanded(
      child: _Press(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _gender = g);
        },
        child: AnimatedContainer(
          duration: _dur(160),
          decoration: BoxDecoration(
            color: selected ? _P.peachSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _P.peachDeep : Colors.transparent,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? _P.peachDeep : _P.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? _P.peachDeep : _P.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // §4 stepper field with optional +/- buttons
  Widget _stepperField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required double min,
    required double max,
    required double step,
    required int precision,
    String? errorKey,
  }) {
    final error = errorKey != null ? _errors[errorKey] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overline(label),
        const SizedBox(height: 6),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error != null ? _P.pinkDeep : _P.divider,
              width: error != null ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              _Press(
                onTap: () => _stepValue(controller, -step, min, max, precision),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.remove_rounded,
                      size: 18, color: _P.textMuted),
                ),
              ),
              Expanded(
                child: _Press(
                  onLongPress: () {},
                  onTap: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        controller.text.isEmpty
                            ? '—'
                            : _formatNumber(controller.text, precision),
                        style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                          height: 1,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(unit,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _P.textMuted,
                          )),
                    ],
                  ),
                ),
              ),
              _Press(
                onTap: () => _stepValue(controller, step, min, max, precision),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.add_rounded,
                      size: 18, color: _P.peachDeep),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(error,
                style: GoogleFonts.inter(
                  color: _P.pinkDeep,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ],
      ],
    );
  }

  String _formatNumber(String raw, int precision) {
    final v = double.tryParse(raw);
    if (v == null) return raw;
    return precision == 0 ? v.round().toString() : v.toStringAsFixed(precision);
  }

  void _stepValue(TextEditingController c, double delta, double min,
      double max, int precision) {
    final cur = double.tryParse(c.text) ?? (delta > 0 ? min - delta : max + delta);
    final next = (cur + delta).clamp(min, max);
    HapticFeedback.selectionClick();
    c.text = precision == 0
        ? next.round().toString()
        : next.toStringAsFixed(precision);
  }

  // ═════════════════════════════════════════════════════════
  //  §5 STEP 2 — GOALS
  // ═════════════════════════════════════════════════════════
  Widget _goalsStep(NutritionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overline('ЦЕЛЬ'),
        const SizedBox(height: 8),
        ...GoalType.values.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _goalCard(g),
        )),
        const SizedBox(height: 16),
        _overline('СКОРОСТЬ'),
        const SizedBox(height: 8),
        _paceSegment(),
        const SizedBox(height: 8),
        Text(_paceExplanation(),
            style: GoogleFonts.inter(
                fontSize: 11, color: _P.textMuted)),
        const SizedBox(height: 20),
        _overline('ЦЕЛЕВОЙ ВЕС (ОПЦИОНАЛЬНО)'),
        const SizedBox(height: 6),
        _plainNumberField(_targetWeightController, 'кг'),
        const SizedBox(height: 14),
        _overline('СРОК (ОПЦИОНАЛЬНО)'),
        const SizedBox(height: 6),
        _plainNumberField(_targetDaysController, 'дней'),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _plainNumberField(TextEditingController c, String unit) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: c,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                color: _P.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '—',
              ),
            ),
          ),
          Text(unit,
              style: GoogleFonts.inter(
                  color: _P.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _goalCard(GoalType goal) {
    final selected = _goalType == goal;
    final info = _goalInfo(goal);
    final icon = _goalIcon(goal);
    return Semantics(
      label: '${info.title}, ${info.subtitle}',
      child: _Press(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _goalType = goal);
        },
        child: AnimatedContainer(
          duration: _dur(180),
          height: 76,
          decoration: BoxDecoration(
            color: selected ? info.soft.withOpacity(0.55) : _P.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? info.color : _P.divider,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selected)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: info.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 10),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: info.soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: info.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.title,
                        style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        )),
                    const SizedBox(height: 2),
                    Text(info.subtitle,
                        style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _radioCircle(selected, info.color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radioCircle(bool selected, Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? color : Colors.transparent,
        border: Border.all(
          color: selected ? color : _P.textMuted.withOpacity(0.4),
          width: 1.4,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }

  Widget _paceSegment() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.divider),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: GoalPace.values.map((p) {
          final info = _paceInfo(p);
          final selected = _goalPace == p;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _Press(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _goalPace = p);
                },
                child: AnimatedContainer(
                  duration: _dur(160),
                  decoration: BoxDecoration(
                    color: selected ? info.soft : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? info.color : Colors.transparent,
                      width: selected ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(info.emoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        info.title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? info.color : _P.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _paceExplanation() {
    switch (_goalPace) {
      case GoalPace.slow:
        return '≈ 0,25 кг в неделю';
      case GoalPace.moderate:
        return '≈ 0,5 кг в неделю';
      case GoalPace.fast:
        return '≈ 0,75 кг в неделю';
    }
  }

  IconData _goalIcon(GoalType goal) {
    switch (goal) {
      case GoalType.maintain:
        return Icons.balance_rounded;
      case GoalType.lose:
        return Icons.trending_down_rounded;
      case GoalType.gain:
        return Icons.trending_up_rounded;
      case GoalType.muscleGain:
        return Icons.fitness_center_rounded;
      case GoalType.recomposition:
        return Icons.swap_horiz_rounded;
    }
  }

  // ═════════════════════════════════════════════════════════
  //  §6 STEP 3 — LIFESTYLE
  // ═════════════════════════════════════════════════════════
  Widget _lifestyleStep(NutritionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overline('АКТИВНОСТЬ'),
        const SizedBox(height: 8),
        ...ActivityLevel.values.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _activityCard(l),
        )),
        const SizedBox(height: 16),
        _stepperField(
          label: 'ШАГОВ В ДЕНЬ',
          unit: 'шагов',
          controller: _stepsController,
          min: 0,
          max: 30000,
          step: 500,
          precision: 0,
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in const [5000, 8000, 10000, 12000])
            _quickChip('${v ~/ 1000}k', () {
              HapticFeedback.selectionClick();
              setState(() => _stepsController.text = '$v');
            }, selected: _stepsController.text == '$v'),
        ]),
        const SizedBox(height: 16),
        _stepperField(
          label: 'ТРЕНИРОВОК',
          unit: 'в неделю',
          controller: _workoutsController,
          min: 0,
          max: 14,
          step: 1,
          precision: 0,
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in const [0, 2, 3, 4, 5])
            _quickChip('$v', () {
              HapticFeedback.selectionClick();
              setState(() => _workoutsController.text = '$v');
            }, selected: _workoutsController.text == '$v'),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _quickChip(String label, VoidCallback onTap, {required bool selected}) {
    return _Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _dur(160),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _P.peachSoft : _P.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _P.peachDeep : _P.divider,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? _P.peachDeep : _P.textMuted,
            )),
      ),
    );
  }

  Widget _activityCard(ActivityLevel level) {
    final selected = _activityLevel == level;
    final info = _activityInfo(level);
    final icon = _activityIcon(level);
    return Semantics(
      label: '${info.title}, ${info.subtitle}',
      child: _Press(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activityLevel = level);
        },
        child: AnimatedContainer(
          duration: _dur(180),
          height: 76,
          decoration: BoxDecoration(
            color: selected ? info.soft.withOpacity(0.55) : _P.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? info.color : _P.divider,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selected)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: info.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 10),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: info.soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: info.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.title,
                        style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        )),
                    const SizedBox(height: 2),
                    Text(info.subtitle,
                        style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _radioCircle(selected, info.color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _activityIcon(ActivityLevel l) {
    switch (l) {
      case ActivityLevel.sedentary:
        return Icons.chair_rounded;
      case ActivityLevel.light:
        return Icons.directions_walk_rounded;
      case ActivityLevel.moderate:
        return Icons.directions_run_rounded;
      case ActivityLevel.active:
        return Icons.fitness_center_rounded;
      case ActivityLevel.veryActive:
        return Icons.local_fire_department_rounded;
      case ActivityLevel.professional:
        return Icons.emoji_events_rounded;
    }
  }

  // ═════════════════════════════════════════════════════════
  //  §10 RESULTS SCREEN — REVEAL
  // ═════════════════════════════════════════════════════════
  Widget _buildResultsScreen(NutritionProvider provider, UserProfile profile) {
    final prediction = profile.goalPrediction;
    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          Column(
            children: [
              _buildDarkHero(hasProfile: true),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReveal(profile),
                      const SizedBox(height: 20),
                      _buildDarkTargetCard(profile),
                      const SizedBox(height: 16),
                      _buildMetricsGrid(profile),
                      if (prediction['canPredict'] == true) ...[
                        const SizedBox(height: 16),
                        _buildPrediction(prediction),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildResultsBar(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildReveal(UserProfile profile) {
    final animate = _isFirstSave && !_reduceMotion;
    return Column(
      children: [
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: animate ? 0 : 1, end: 1),
            duration: animate
                ? const Duration(milliseconds: 400)
                : Duration.zero,
            curve: Curves.elasticOut,
            builder: (_, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _P.peachSoft,
                border: Border.all(color: _P.peachDeep.withOpacity(0.2)),
              ),
              child: const Icon(Icons.check_rounded,
                  color: _P.peachDeep, size: 52),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text('Готово',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.0,
                color: _P.text,
                height: 1.1,
              )),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Твоя персональная цель —\n${profile.targetCalories.round()} ккал в день.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 14, color: _P.textMuted, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildDarkTargetCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Hero.bgTop, _Hero.bgBottom],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ДНЕВНАЯ ЦЕЛЬ',
              style: GoogleFonts.inter(
                color: _Hero.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              )),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${profile.targetCalories.round()}',
                  style: GoogleFonts.inter(
                    color: _Hero.textHigh,
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.8,
                    height: 1,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  )),
              const SizedBox(width: 6),
              Text('ккал',
                  style: GoogleFonts.inter(
                    color: _Hero.textLow,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _darkMacroChip('Б', profile.recommendedProtein.round(), 'г',
                  _P.greenDeep),
              const SizedBox(width: 6),
              _darkMacroChip('Ж', profile.recommendedFat.round(), 'г',
                  _P.yellowDeep),
              const SizedBox(width: 6),
              _darkMacroChip('У', profile.recommendedCarbs.round(), 'г',
                  _P.pinkDeep),
              const SizedBox(width: 6),
              _darkMacroChip('В', profile.recommendedWater, 'мл',
                  _P.skyDeep),
            ],
          ),
        ],
      ),
    );
  }

  Widget _darkMacroChip(String l, num v, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 4),
          Text('$l ${v.round()}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              )),
          const SizedBox(height: 1),
          Text(unit,
              style: GoogleFonts.inter(
                color: _Hero.textLow,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              )),
        ]),
      ),
    );
  }

  Widget _buildMetricsGrid(UserProfile profile) {
    final cells = [
      _MetricCell('BMR', '${profile.bmr.round()}', 'ккал', _P.peachDeep, 0),
      _MetricCell('TDEE', '${profile.tdee.round()}', 'ккал', _P.yellowDeep, 0),
      _MetricCell('ИМТ', profile.bmi.toStringAsFixed(1),
          profile.bmiCategory, _P.greenDeep, 0),
      _MetricCell('ЦЕЛЬ', _goalTypeDisplay(profile.goalType),
          _goalPaceDisplay(profile.goalPace), _P.lavenderDeep, 1),
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricTile(cells[0])),
            const SizedBox(width: 10),
            Expanded(child: _metricTile(cells[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _metricTile(cells[2])),
            const SizedBox(width: 10),
            Expanded(child: _metricTile(cells[3])),
          ],
        ),
      ],
    );
  }

  Widget _metricTile(_MetricCell cell) {
    return _Press(
      onTap: () => setState(() => _showResults = false),
      child: Container(
        height: 96,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _P.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                  BoxDecoration(color: cell.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(cell.label,
                    style: GoogleFonts.inter(
                      color: _P.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    )),
              ],
            ),
            const Spacer(),
            Text(cell.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  height: 1,
                  fontFeatures: [ui.FontFeature.tabularFigures()],
                )),
            const SizedBox(height: 3),
            Text(cell.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 11, color: _P.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrediction(Map<String, dynamic> prediction) {
    final isLose = prediction['isLose'] == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.yellowSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.yellowDeep.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(isLose ? '📉' : '📈',
                style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ПРОГНОЗ',
                    style: GoogleFonts.inter(
                      color: _P.yellowDeep,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 3),
                Text('≈ ${prediction['days']} дней',
                    style: GoogleFonts.inter(
                      color: _P.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      height: 1,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    )),
                const SizedBox(height: 3),
                Text(
                  '${prediction['absDiff'].toStringAsFixed(1)} кг ${isLose ? 'сбросить' : 'набрать'}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: _P.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsBar(NutritionProvider provider) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: _P.surface.withOpacity(0.92),
            border: const Border(top: BorderSide(color: _P.divider, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _Press(
                      onTap: () => _showRecommendations(provider),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: _P.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _P.divider),
                        ),
                        alignment: Alignment.center,
                        child: Text('Рекомендации',
                            style: GoogleFonts.inter(
                              color: _P.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _Press(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _showResults = false);
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: _P.peachDeep,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _P.peachDeep.withOpacity(0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Готово',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                )),
                            const SizedBox(width: 6),
                            const Icon(Icons.check_rounded,
                                color: Colors.white, size: 18),
                          ],
                        ),
                      ),
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

  // ═════════════════════════════════════════════════════════
  //  §11 RECOMMENDATIONS SHEET (preserved + tabbed)
  // ═════════════════════════════════════════════════════════
  void _showRecommendations(NutritionProvider provider) {
    final profile = provider.userProfile;
    if (profile == null) return;
    HapticFeedback.selectionClick();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RecommendationsSheet(
        profile: profile,
        provider: provider,
        reduceMotion: _reduceMotion,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  SAVE (preserved logic)
  // ═════════════════════════════════════════════════════════
  Future<void> _saveProfile(NutritionProvider provider) async {
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (age == null ||
        age <= 0 ||
        weight == null ||
        weight <= 0 ||
        height == null ||
        height <= 0) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Заполни возраст, вес и рост'),
        backgroundColor: _P.pinkDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }

    final profile = UserProfile(
      id: provider.userProfile?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
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
    try {
      await provider.saveUserProfile(profile);
      if (!mounted) return;
      setState(() {
        _showResults = true;
        _currentStep = 2;
      });
      if (!_reduceMotion) {
        Future.delayed(const Duration(milliseconds: 300), () {
          HapticFeedback.lightImpact();
        });
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Не удалось сохранить профиль'),
        backgroundColor: _P.pinkDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        action: SnackBarAction(
          label: 'Повторить',
          textColor: Colors.white,
          onPressed: () => _saveProfile(provider),
        ),
      ));
    }
  }

  // ═════════════════════════════════════════════════════════
  //  TEMP PROFILE (preserved logic)
  // ═════════════════════════════════════════════════════════
  UserProfile? _buildTempProfile() {
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (age == null ||
        weight == null ||
        height == null ||
        age <= 0 ||
        weight <= 0 ||
        height <= 0) {
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

  // ── shared bits ──
  Widget _overline(String text) =>
      Text(text, style: _T.overline);

  Widget _grabber() => Container(
    width: 36,
    height: 5,
    decoration: BoxDecoration(
      color: _P.divider,
      borderRadius: BorderRadius.circular(3),
    ),
  );

  // ═════════════════════════════════════════════════════════
  //  Info structs (preserved)
  // ═════════════════════════════════════════════════════════
  _GoalInfo _goalInfo(GoalType goal) {
    switch (goal) {
      case GoalType.maintain:
        return const _GoalInfo(
          emoji: '⚖️',
          title: 'Поддержание',
          subtitle: 'Сохранять текущий вес',
          color: _P.skyDeep,
          soft: _P.skySoft,
        );
      case GoalType.lose:
        return const _GoalInfo(
          emoji: '🔥',
          title: 'Похудение',
          subtitle: 'Снизить вес',
          color: _P.peachDeep,
          soft: _P.peachSoft,
        );
      case GoalType.gain:
        return const _GoalInfo(
          emoji: '📈',
          title: 'Набор веса',
          subtitle: 'Постепенно увеличить массу',
          color: _P.greenDeep,
          soft: _P.greenSoft,
        );
      case GoalType.muscleGain:
        return const _GoalInfo(
          emoji: '💪',
          title: 'Набор мышц',
          subtitle: 'Фокус на мышечном росте',
          color: _P.lavenderDeep,
          soft: _P.lavenderSoft,
        );
      case GoalType.recomposition:
        return const _GoalInfo(
          emoji: '🔄',
          title: 'Рекомпозиция',
          subtitle: 'Мышцы вверх, жир вниз',
          color: _P.yellowDeep,
          soft: _P.yellowSoft,
        );
    }
  }

  _PaceInfo _paceInfo(GoalPace pace) {
    switch (pace) {
      case GoalPace.slow:
        return const _PaceInfo(
            emoji: '🐢', title: 'Медленно', color: _P.greenDeep, soft: _P.greenSoft);
      case GoalPace.moderate:
        return const _PaceInfo(
            emoji: '⚡', title: 'Умеренно', color: _P.yellowDeep, soft: _P.yellowSoft);
      case GoalPace.fast:
        return const _PaceInfo(
            emoji: '🚀', title: 'Быстро', color: _P.pinkDeep, soft: _P.pinkSoft);
    }
  }

  _ActivityInfo _activityInfo(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return const _ActivityInfo(
            emoji: '🪑',
            title: 'Сидячий',
            subtitle: 'Минимум движения',
            color: _P.skyDeep,
            soft: _P.skySoft);
      case ActivityLevel.light:
        return const _ActivityInfo(
            emoji: '🚶',
            title: 'Лёгкий',
            subtitle: 'Немного прогулок',
            color: _P.greenDeep,
            soft: _P.greenSoft);
      case ActivityLevel.moderate:
        return const _ActivityInfo(
            emoji: '🏃',
            title: 'Умеренный',
            subtitle: 'Регулярная активность',
            color: _P.greenDeep,
            soft: _P.greenSoft);
      case ActivityLevel.active:
        return const _ActivityInfo(
            emoji: '💪',
            title: 'Активный',
            subtitle: 'Много движения',
            color: _P.yellowDeep,
            soft: _P.yellowSoft);
      case ActivityLevel.veryActive:
        return const _ActivityInfo(
            emoji: '🔥',
            title: 'Очень активный',
            subtitle: 'Высокая нагрузка',
            color: _P.peachDeep,
            soft: _P.peachSoft);
      case ActivityLevel.professional:
        return const _ActivityInfo(
            emoji: '🏆',
            title: 'Профессиональный',
            subtitle: 'Интенсивные тренировки',
            color: _P.lavenderDeep,
            soft: _P.lavenderSoft);
    }
  }

  String _goalTypeDisplay(GoalType type) {
    switch (type) {
      case GoalType.maintain:
        return 'Поддержание';
      case GoalType.lose:
        return 'Похудение';
      case GoalType.gain:
        return 'Набор веса';
      case GoalType.muscleGain:
        return 'Набор мышц';
      case GoalType.recomposition:
        return 'Рекомпозиция';
    }
  }

  String _goalPaceDisplay(GoalPace pace) {
    switch (pace) {
      case GoalPace.slow:
        return 'Медленно';
      case GoalPace.moderate:
        return 'Умеренно';
      case GoalPace.fast:
        return 'Быстро';
    }
  }

  String _activityDisplay(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Сидячий';
      case ActivityLevel.light:
        return 'Лёгкий';
      case ActivityLevel.moderate:
        return 'Умеренный';
      case ActivityLevel.active:
        return 'Активный';
      case ActivityLevel.veryActive:
        return 'Очень активный';
      case ActivityLevel.professional:
        return 'Профи';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  §1 _StepView — PageView transition
// ═══════════════════════════════════════════════════════════════════
class _StepView extends StatelessWidget {
  final Widget child;
  final ScrollController scrollController;
  const _StepView({required this.child, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  §10 _MetricCell
// ═══════════════════════════════════════════════════════════════════
class _MetricCell {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final int tapTarget;
  const _MetricCell(
      this.label, this.value, this.subtitle, this.color, this.tapTarget);
}

// ═══════════════════════════════════════════════════════════════════
//  §11 Recommendations sheet with tabs
// ═══════════════════════════════════════════════════════════════════
class _RecommendationsSheet extends StatefulWidget {
  final UserProfile profile;
  final NutritionProvider provider;
  final bool reduceMotion;
  const _RecommendationsSheet({
    required this.profile,
    required this.provider,
    required this.reduceMotion,
  });

  @override
  State<_RecommendationsSheet> createState() => _RecommendationsSheetState();
}

class _RecommendationsSheetState extends State<_RecommendationsSheet> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final prediction = profile.goalPrediction;
    final weekSummary = widget.provider.getLast7DaysSummaries();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: _P.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _P.lavenderSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: _P.lavenderDeep, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('УМНЫЕ РЕКОМЕНДАЦИИ',
                            style: GoogleFonts.inter(
                              color: _P.lavenderDeep,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            )),
                        const SizedBox(height: 2),
                        Text('На основе твоего профиля',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: _P.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _tabs(),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: AnimatedSwitcher(
                  duration: widget.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  child: _tabContent(profile, prediction, weekSummary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    const labels = ['Цели', 'Советы', 'Неделя'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _Press(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _tab = i);
                },
                child: AnimatedContainer(
                  duration: widget.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tab == i ? _P.peachSoft : _P.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _tab == i ? _P.peachDeep : _P.divider,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                      _tab == i ? FontWeight.w600 : FontWeight.w500,
                      color: _tab == i ? _P.peachDeep : _P.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabContent(UserProfile profile, Map<String, dynamic> prediction,
      List<dynamic> weekSummary) {
    switch (_tab) {
      case 0:
        return _goalsTab(profile);
      case 1:
        return _tipsTab(profile, prediction);
      default:
        return _weekTab(weekSummary);
    }
  }

  Widget _goalsTab(UserProfile profile) {
    return Column(
      key: const ValueKey('goals'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kcalHeroTile(profile),
        const SizedBox(height: 10),
        Row(
          children: [
            _macroTile('Б', profile.recommendedProtein.round(), 'г',
                _P.greenDeep),
            const SizedBox(width: 8),
            _macroTile('Ж', profile.recommendedFat.round(), 'г',
                _P.yellowDeep),
            const SizedBox(width: 8),
            _macroTile('У', profile.recommendedCarbs.round(), 'г',
                _P.pinkDeep),
          ],
        ),
        const SizedBox(height: 10),
        _waterTile(profile),
      ],
    );
  }

  Widget _kcalHeroTile(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 96,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Hero.bgTop, _Hero.bgBottom],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ЦЕЛЬ ПО КАЛОРИЯМ',
                    style: GoogleFonts.inter(
                      color: _Hero.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${profile.targetCalories.round()}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1.2,
                          height: 1,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        )),
                    const SizedBox(width: 5),
                    Text('ккал/день',
                        style: GoogleFonts.inter(
                          color: _Hero.textLow,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: _Hero.accent, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _macroTile(String l, num value, String unit, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.divider),
        ),
        child: Column(
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(children: [
                Text('$l ${value.round()}',
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    )),
                const SizedBox(height: 3),
                Text(unit,
                    style: GoogleFonts.inter(
                      color: _P.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    )),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waterTile(UserProfile profile) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_P.skySoft, _P.skySoft.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.water_drop_rounded,
                color: _P.skyDeep, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ВОДА',
                    style: GoogleFonts.inter(
                      color: _P.skyDeep,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 3),
                Text('${profile.recommendedWater} мл',
                    style: GoogleFonts.inter(
                      color: _P.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      height: 1,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipsTab(UserProfile profile, Map<String, dynamic> prediction) {
    final tips = <Widget>[];
    if (profile.bmiCategory != 'Норма') {
      tips.add(_tipCard(
        Icons.balance_rounded,
        _P.yellowDeep,
        'Индекс массы тела',
        'ИМТ: ${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})',
      ));
    }
    final proteinPct = profile.targetCalories > 0
        ? (profile.recommendedProtein * 4 / profile.targetCalories * 100)
        .round()
        : 0;
    final fatPct = profile.targetCalories > 0
        ? (profile.recommendedFat * 9 / profile.targetCalories * 100).round()
        : 0;
    final carbsPct = profile.targetCalories > 0
        ? (profile.recommendedCarbs * 4 / profile.targetCalories * 100)
        .round()
        : 0;
    tips.add(_tipCard(
      Icons.pie_chart_rounded,
      _P.peachDeep,
      'Распределение БЖУ',
      'Белки $proteinPct% · Жиры $fatPct% · Углеводы $carbsPct%',
    ));
    if (profile.recommendedWater > 2000) {
      tips.add(_tipCard(
        Icons.water_drop_rounded,
        _P.skyDeep,
        'Водный баланс',
        'Рекомендуется ${profile.recommendedWater} мл воды в день.',
      ));
    }
    const activityMessages = {
      ActivityLevel.sedentary: 'Добавь немного ежедневного движения.',
      ActivityLevel.light: 'Хороший старт. Постепенно увеличивай активность.',
      ActivityLevel.moderate: 'Отличный уровень активности.',
      ActivityLevel.active: 'Хороший темп. Следи за восстановлением.',
      ActivityLevel.veryActive: 'Высокая нагрузка — питание особенно важно.',
      ActivityLevel.professional:
      'Очень высокая нагрузка. Поддерживай питание.',
    };
    tips.add(_tipCard(
      Icons.directions_run_rounded,
      _P.greenDeep,
      'Активность',
      activityMessages[profile.activityLevel] ??
          'Продолжай в том же духе.',
    ));
    if (prediction['canPredict'] == true) {
      final isLose = prediction['isLose'] == true;
      tips.add(_tipCard(
        isLose ? Icons.trending_down_rounded : Icons.trending_up_rounded,
        _P.yellowDeep,
        'Прогноз',
        '${prediction['days']} дней · ${prediction['absDiff'].toStringAsFixed(1)} кг ${isLose ? 'сбросить' : 'набрать'}',
      ));
    }
    return Column(
      key: const ValueKey('tips'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips,
    );
  }

  Widget _tipCard(IconData icon, Color color, String title, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      height: 72,
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                      color: _P.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: _P.textMuted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekTab(List<dynamic> week) {
    if (week.isEmpty) {
      return Container(
        key: const ValueKey('week_empty'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.divider),
        ),
        child: Center(
          child: Text('Пока нет данных',
              style: GoogleFonts.inter(fontSize: 12, color: _P.textMuted)),
        ),
      );
    }
    final maxKcal = week.fold<double>(
        1, (m, d) => math.max(m, d.calories as double));
    final avgKcal =
        week.fold<double>(0, (s, d) => s + (d.calories as double)) /
            week.length;
    final avgProtein =
        week.fold<double>(0, (s, d) => s + (d.protein as double)) /
            week.length;

    return Column(
      key: const ValueKey('week'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _P.divider),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(week.length, (i) {
                    final d = week[i];
                    final h = ((d.calories as double) / maxKcal * 120)
                        .clamp(6.0, 120.0);
                    final isLast = i == week.length - 1;
                    return Expanded(
                      child: Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: h,
                              decoration: BoxDecoration(
                                color: isLast
                                    ? _P.peachDeep
                                    : _P.divider,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _weekStat('Ср. ккал', '${avgKcal.round()}', _P.peachDeep),
            const SizedBox(width: 8),
            _weekStat('Ср. белок', '${avgProtein.round()} г', _P.greenDeep),
            const SizedBox(width: 8),
            _weekStat('Дней', '${week.length}', _P.skyDeep),
          ],
        ),
      ],
    );
  }

  Widget _weekStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _P.divider),
        ),
        child: Column(children: [
          Text(value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              )),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: _P.textMuted)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  §8 _Press — scale-on-tap wrapper
// ═══════════════════════════════════════════════════════════════════
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const _Press({required this.child, this.onTap, this.onLongPress});

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onLongPress != null;
    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: interactive ? (_) => _set(true) : null,
      onTapUp: interactive ? (_) => _set(false) : null,
      onTapCancel: interactive ? () => _set(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: widget.child,
    );
    if (!interactive) return child;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) return child;
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Info structs (preserved, refactored to const)
// ═══════════════════════════════════════════════════════════════════
class _GoalInfo {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color soft;
  const _GoalInfo({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.soft,
  });
}

class _PaceInfo {
  final String emoji;
  final String title;
  final Color color;
  final Color soft;
  const _PaceInfo({
    required this.emoji,
    required this.title,
    required this.color,
    required this.soft,
  });
}

class _ActivityInfo {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color soft;
  const _ActivityInfo({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.soft,
  });
}