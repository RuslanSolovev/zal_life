// features/nutrition/ui/screens/profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/color_settings_provider.dart';

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
  static const Color violet = Color(0xFF9C82FF);

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

class ProfileSetupScreen extends StatefulWidget {
  final bool isDark;
  final NutritionProvider? provider;

  const ProfileSetupScreen({
    super.key,
    this.isDark = true,
    this.provider,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // ============================================================
  // PALETTE
  // ============================================================

  Color get _background => _Power.bg(widget.isDark);
  Color get _surface => _Power.card(widget.isDark);
  Color get _surface2 => _Power.card2(widget.isDark);
  Color get _textPrimary => _Power.textPrimary(widget.isDark);
  Color get _textSecondary => _Power.textSecondary(widget.isDark);
  Color get _textMuted => _Power.textTertiary(widget.isDark);
  Color get _divider => _Power.separator(widget.isDark);
  Color get _lineBase => _Power.separator(widget.isDark);

  /// Акцент — динамический. Используем read, т.к. геттер
  /// вызывается и в обработчиках нажатий (вне build-фазы).
  /// Подписка на изменения сделана через context.watch в build().
  Color get _cyan => context.read<ColorSettingsProvider>().accent;

  // Семантические — фиксированные
  static const Color _green = _Power.green;
  static const Color _pink = _Power.magma;
  static const Color _yellow = _Power.plasma;
  static const Color _orange = _Power.volt;
  static const Color _purple = _Power.violet;
  static const Color _blue = _Power.ice;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _targetDaysController = TextEditingController();
  final _stepsController = TextEditingController();
  final _workoutsController = TextEditingController();
  final _bodyFatController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  GoalType _goalType = GoalType.maintain;
  GoalPace _goalPace = GoalPace.moderate;

  int _currentStep = 0;

  bool _isLoading = true;
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

  // ============================================================
  // PROVIDER
  // ============================================================

  NutritionProvider get _provider {
    if (widget.provider != null) return widget.provider!;
    try {
      return Provider.of<NutritionProvider>(context, listen: false);
    } catch (e) {
      debugPrint('Ошибка получения NutritionProvider: $e');
      throw Exception('NutritionProvider не найден');
    }
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  void _loadProfile() {
    try {
      final provider = _provider;
      final profile = provider.userProfile;

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Подписка на изменение акцента — вызывает перестройку экрана
    context.watch<ColorSettingsProvider>();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(child: _buildLoading()),
      );
    }

    final provider = widget.provider ?? context.watch<NutritionProvider>();
    final profile = provider.userProfile;

    if (profile != null && _showResults) {
      return _buildResultsScreen(provider, profile);
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(hasProfile: profile != null),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 135),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeading(),
                    const SizedBox(height: 19),
                    _buildStepContent(provider),
                    const SizedBox(height: 20),
                    if (_currentStep == 1) _buildGoalInsight(provider),
                    if (_currentStep == 2) _buildLifestyleInsight(provider),
                    const SizedBox(height: 24),
                    _buildNavigationButtons(provider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar({required bool hasProfile}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _divider, width: 0.5),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasProfile ? 'ПРОФИЛЬ' : 'НАСТРОЙКА',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasProfile ? 'Настройки' : 'Профиль',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          if (hasProfile)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _showRecommendations(_provider);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _Power.softGlow(_Power.violet, strength: 0.2),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _purple,
                  size: 19,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: _cyan.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        boxShadow: _Power.glow(_cyan, strength: 0.35, blur: 22),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(_cyan),
        ),
      ),
    );
  }

  // ============================================================
  // HERO HEADING
  // ============================================================

  Widget _buildHeroHeading() {
    final titles = [
      'О тебе',
      'Твоя цель',
      'Твой ритм',
    ];

    final subtitles = [
      'Нужно, чтобы FUEL рассчитал твои потребности.',
      'Выбери направление — остальное FUEL посчитает сам.',
      'Чем точнее данные, тем точнее рекомендации.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _cyan.withOpacity(0.14),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _Power.glow(_cyan, strength: 0.35, blur: 22),
          ),
          alignment: Alignment.center,
          child: Icon(
            _currentStep == 0
                ? Icons.person_rounded
                : _currentStep == 1
                ? Icons.track_changes_rounded
                : Icons.directions_run_rounded,
            color: _cyan,
            size: 24,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          titles[_currentStep].toUpperCase(),
          style: TextStyle(
            color: _textPrimary,
            fontSize: 27,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitles[_currentStep],
          style: TextStyle(
            color: _textSecondary,
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP INDICATOR
  // ============================================================

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 7),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: i == _currentStep ? 5 : 3,
                  decoration: BoxDecoration(
                    color: i <= _currentStep
                        ? _cyan
                        : _textPrimary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: i == _currentStep
                        ? _Power.softGlow(_cyan, strength: 0.5)
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP CONTENT
  // ============================================================

  Widget _buildStepContent(NutritionProvider provider) {
    switch (_currentStep) {
      case 0:
        return _buildPersonalDataStep(provider);
      case 1:
        return _buildGoalsStep(provider);
      case 2:
        return _buildLifestyleStep(provider);
      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // PERSONAL STEP
  // ============================================================

  Widget _buildPersonalDataStep(NutritionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('ПОЛ'),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _genderCard(Gender.male, 'Мужской', '♂', _cyan),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _genderCard(Gender.female, 'Женский', '♀', _pink),
            ),
          ],
        ),
        const SizedBox(height: 21),
        Row(
          children: [
            Expanded(
              child: _profileInput(
                title: 'ВОЗРАСТ',
                subtitle: 'Полных лет',
                controller: _ageController,
                suffix: 'лет',
                icon: Icons.cake_rounded,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _profileInput(
                title: 'ВЕС',
                subtitle: 'Текущий',
                controller: _weightController,
                suffix: 'кг',
                icon: Icons.monitor_weight_rounded,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _profileInput(
                title: 'РОСТ',
                subtitle: 'Твой рост',
                controller: _heightController,
                suffix: 'см',
                icon: Icons.height_rounded,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _profileInput(
                title: '% ЖИРА',
                subtitle: 'Опционально',
                controller: _bodyFatController,
                suffix: '%',
                icon: Icons.percent_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _infoCard(
          icon: Icons.auto_awesome_rounded,
          color: _cyan,
          title: 'Не знаешь процент жира?',
          message: 'Оставь поле пустым. FUEL продолжит расчёт без него.',
        ),
      ],
    );
  }

  Widget _genderCard(
      Gender gender,
      String label,
      String symbol,
      Color color,
      ) {
    final selected = _gender == gender;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _gender = gender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.10) : _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : _divider,
            width: selected ? 1.2 : 0.5,
          ),
          boxShadow: selected ? _Power.softGlow(color, strength: 0.3) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                symbol,
                style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: selected ? _textPrimary : _textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected ? 'ВЫБРАНО' : 'ВЫБРАТЬ',
                    style: TextStyle(
                      color: selected ? color : _textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: _Power.darkBg,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GOALS STEP
  // ============================================================

  Widget _buildGoalsStep(NutritionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('ЦЕЛЬ'),
        const SizedBox(height: 9),
        ...GoalType.values.map(
              (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _goalCard(goal),
          ),
        ),
        const SizedBox(height: 15),
        _buildLabel('СКОРОСТЬ'),
        const SizedBox(height: 9),
        Row(
          children: [
            for (final pace in GoalPace.values)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: pace == GoalPace.fast ? 0 : 6,
                  ),
                  child: _paceCard(pace),
                ),
              ),
          ],
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: _profileInput(
                title: 'ЦЕЛЕВОЙ ВЕС',
                subtitle: 'Опционально',
                controller: _targetWeightController,
                suffix: 'кг',
                icon: Icons.track_changes_rounded,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _profileInput(
                title: 'СРОК',
                subtitle: 'Опционально',
                controller: _targetDaysController,
                suffix: 'дней',
                icon: Icons.timelapse_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _goalCard(GoalType goal) {
    final selected = _goalType == goal;
    final info = _goalInfo(goal);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _goalType = goal);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? info.color.withOpacity(0.10) : _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? info.color : _divider,
            width: selected ? 1.2 : 0.5,
          ),
          boxShadow:
          selected ? _Power.softGlow(info.color, strength: 0.3) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: info.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(info.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.title.toUpperCase(),
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    info.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? info.color : _surface2,
                shape: BoxShape.circle,
              ),
              child: selected
                  ? const Icon(
                Icons.check_rounded,
                color: _Power.darkBg,
                size: 14,
              )
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
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _goalPace = pace);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 7),
        decoration: BoxDecoration(
          color: selected ? info.color.withOpacity(0.10) : _surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? info.color : _divider,
            width: selected ? 1.2 : 0.5,
          ),
          boxShadow:
          selected ? _Power.softGlow(info.color, strength: 0.3) : null,
        ),
        child: Column(
          children: [
            Text(info.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 5),
            Text(
              info.title.toUpperCase(),
              style: TextStyle(
                color: selected ? info.color : _textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LIFESTYLE STEP
  // ============================================================

  Widget _buildLifestyleStep(NutritionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('АКТИВНОСТЬ'),
        const SizedBox(height: 9),
        ...ActivityLevel.values.map(
              (level) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _activityCard(level),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _profileInput(
                title: 'ШАГОВ В ДЕНЬ',
                subtitle: 'Среднее',
                controller: _stepsController,
                suffix: 'шагов',
                icon: Icons.directions_walk_rounded,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _profileInput(
                title: 'ТРЕНИРОВОК',
                subtitle: 'В неделю',
                controller: _workoutsController,
                suffix: 'раз',
                icon: Icons.fitness_center_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildProfileLiveCard(provider),
      ],
    );
  }

  Widget _activityCard(ActivityLevel level) {
    final selected = _activityLevel == level;
    final info = _activityInfo(level);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activityLevel = level);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? info.color.withOpacity(0.10) : _surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? info.color : _divider,
            width: selected ? 1.2 : 0.5,
          ),
          boxShadow:
          selected ? _Power.softGlow(info.color, strength: 0.3) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: info.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(info.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.title.toUpperCase(),
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    info.subtitle,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _cyan,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: _Power.darkBg,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE INPUT
  // ============================================================

  Widget _profileInput({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String suffix,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: _cyan, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  onChanged: onChanged,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  suffix,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INSIGHTS
  // ============================================================

  Widget _buildGoalInsight(NutritionProvider provider) {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;

    if (weight <= 0 || height <= 0) return const SizedBox.shrink();

    final profile = _buildTemporaryProfile();
    if (profile == null) return const SizedBox.shrink();

    return _buildCalculationCard(
      title: 'ПРЕДВАРИТЕЛЬНЫЙ РАСЧЁТ',
      subtitle: 'FUEL уже может показать ориентиры',
      color: _cyan,
      children: [
        Row(
          children: [
            _calcStat('BMR', '${profile.bmr.round()}', 'ККАЛ', _cyan),
            _calcStat('TDEE', '${profile.tdee.round()}', 'ККАЛ', _yellow),
            _calcStat('ИМТ', profile.bmi.toStringAsFixed(1), '', _green),
          ],
        ),
        _buildInnerRay(_cyan),
        Row(
          children: [
            Expanded(
              child: Text(
                'ЦЕЛЕВАЯ КАЛОРИЙНОСТЬ',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Text(
              '${profile.targetCalories.round()} ККАЛ',
              style: TextStyle(
                color: _cyan,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLifestyleInsight(NutritionProvider provider) {
    final profile = _buildTemporaryProfile();

    if (profile == null) {
      return _infoCard(
        icon: Icons.info_outline_rounded,
        color: _cyan,
        title: 'Почти готово',
        message:
        'Заполни основные данные выше — и здесь появится твой расчёт.',
      );
    }

    return _buildCalculationCard(
      title: 'ПЕРСОНАЛЬНЫЙ ПЛАН',
      subtitle: 'Проверь перед сохранением',
      color: _green,
      children: [
        Row(
          children: [
            _calcStat(
                'ЦЕЛЬ', '${profile.targetCalories.round()}', 'ККАЛ', _cyan),
            _calcStat(
                'БЕЛОК', '${profile.recommendedProtein.round()}', 'Г', _green),
            _calcStat('ВОДА', '${profile.recommendedWater}', 'МЛ', _blue),
          ],
        ),
        const SizedBox(height: 12),
        _buildInnerRay(_green),
        Row(
          children: [
            Expanded(
              child:
              _summaryMini('🎯', _goalTypeDisplay(profile.goalType)),
            ),
            Expanded(
              child:
              _summaryMini('⚡', _goalPaceDisplay(profile.goalPace)),
            ),
            Expanded(
              child:
              _summaryMini('🏃', _activityDisplay(profile.activityLevel)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileLiveCard(NutritionProvider provider) {
    final profile = _buildTemporaryProfile();
    if (profile == null) return const SizedBox.shrink();

    return _buildCalculationCard(
      title: 'ПРЕДПРОСМОТР',
      subtitle: 'Обновляется прямо во время настройки',
      color: _purple,
      children: [
        Row(
          children: [
            _calcStat('BMR', '${profile.bmr.round()}', 'ККАЛ', _cyan),
            _calcStat('TDEE', '${profile.tdee.round()}', 'ККАЛ', _yellow),
            _calcStat('ИМТ', profile.bmi.toStringAsFixed(1), '', _green),
          ],
        ),
        const SizedBox(height: 12),
        _buildInnerRay(_purple),
        Text(
          '${_goalTypeDisplay(profile.goalType).toUpperCase()} → ${profile.targetCalories.round()} ККАЛ/ДЕНЬ',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  UserProfile? _buildTemporaryProfile() {
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

  Widget _buildCalculationCard({
    required String title,
    required String subtitle,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _Power.softGlow(color, strength: 0.15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: color,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }

  Widget _calcStat(String title, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$title${unit.isEmpty ? '' : ' • $unit'}',
            style: TextStyle(
              color: _textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
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
          child: Text(
            value.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInnerRay(Color color) {
    return SizedBox(
      height: 13,
      child: CustomPaint(
        painter: _GlowRayPainter(
          color: color,
          widthFactor: 0.76,
          backgroundColor: Colors.transparent,
          coreWidth: 1.8,
          glowWidth: 6,
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Widget _buildNavigationButtons(NutritionProvider provider) {
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
                      color: _surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _divider, width: 0.5),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chevron_left_rounded,
                          color: _textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'НАЗАД',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
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
                    color: _cyan,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: _Power.glow(_cyan,
                        strength: 0.4, blur: 16),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'СОХРАНИТЬ' : 'ПРОДОЛЖИТЬ',
                        style: const TextStyle(
                          color: _Power.darkBg,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Icon(
                        isLast
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: _Power.darkBg,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          'ШАГ ${_currentStep + 1} ИЗ 3',
          style: TextStyle(
            color: _textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESULTS
  // ============================================================

  Widget _buildResultsScreen(
      NutritionProvider provider, UserProfile profile) {
    final prediction = profile.goalPrediction;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildResultTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 125),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResultHero(profile),
                    _buildGlowRay(_green),
                    _buildMainMetrics(profile),
                    _buildGlowRay(_cyan),
                    _buildDailyTargets(profile),
                    if (prediction['canPredict'] == true) ...[
                      _buildGlowRay(_yellow),
                      _buildPrediction(prediction),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _showResults = false);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cyan,
                          foregroundColor: _Power.darkBg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ПОНЯТНО, ПОЕХАЛИ',
                              style: TextStyle(
                                fontSize: 13,
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
          ],
        ),
      ),
    );
  }

  Widget _buildResultTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 7),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showResults = false);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _divider, width: 0.5),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FUEL ПРОФИЛЬ',
                  style: TextStyle(
                    color: _green,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Готово',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _Power.softGlow(_Power.green, strength: 0.3),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              color: _green,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHero(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _green.withOpacity(0.20), width: 0.8),
        boxShadow: _Power.softGlow(_Power.green, strength: 0.12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              boxShadow: _Power.softGlow(_Power.green, strength: 0.3),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.verified_rounded,
              color: _green,
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ПРОФИЛЬ ГОТОВ',
                  style: TextStyle(
                    color: _green,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Расчёты готовы',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Дневник питания будет учитывать твои параметры.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMetrics(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _divider, width: 0.5),
      ),
      child: Column(
        children: [
          _resultMetricRow('BMR', '${profile.bmr.round()}', 'ККАЛ', _cyan),
          _resultSeparator(),
          _resultMetricRow('TDEE', '${profile.tdee.round()}', 'ККАЛ', _yellow),
          _resultSeparator(),
          _resultMetricRow(
            'ИМТ',
            profile.bmi.toStringAsFixed(1),
            profile.bmiCategory.toUpperCase(),
            _green,
          ),
          _resultSeparator(),
          _resultMetricRow(
            'ЦЕЛЬ',
            _goalTypeDisplay(profile.goalType),
            _goalPaceDisplay(profile.goalPace),
            _orange,
          ),
        ],
      ),
    );
  }

  Widget _resultMetricRow(
      String title, String value, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: _Power.softGlow(color, strength: 0.4),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            title,
            style: TextStyle(
              color: _textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _resultSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(height: 0.5, color: _divider),
    );
  }

  Widget _buildDailyTargets(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cyan.withOpacity(0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ТВОЯ ДНЕВНАЯ ЦЕЛЬ',
            style: TextStyle(
              color: _cyan,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${profile.targetCalories.round()}',
                style: TextStyle(
                  color: _cyan,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                  height: 1,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'ККАЛ / ДЕНЬ',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _targetCard('🥩', '${profile.recommendedProtein.round()}',
                  'Г БЕЛКА', _green),
              _targetCard('🧈', '${profile.recommendedFat.round()}',
                  'Г ЖИРОВ', _pink),
              _targetCard('🍞', '${profile.recommendedCarbs.round()}',
                  'Г УГЛЕВ.', _yellow),
              _targetCard('💧', '${profile.recommendedWater}',
                  'МЛ ВОДЫ', _blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _targetCard(
      String emoji, String value, String title, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMuted,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrediction(Map<String, dynamic> prediction) {
    final isLose = prediction['isLose'] == true;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _yellow.withOpacity(0.08),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _yellow.withOpacity(0.20), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _yellow.withOpacity(0.14),
              borderRadius: BorderRadius.circular(15),
              boxShadow: _Power.softGlow(_Power.plasma, strength: 0.25),
            ),
            alignment: Alignment.center,
            child: Text(
              isLose ? '📉' : '📈',
              style: const TextStyle(fontSize: 23),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ПРОГНОЗ',
                  style: TextStyle(
                    color: _yellow,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${prediction['days']} ДНЕЙ',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${prediction['absDiff'].toStringAsFixed(1)} КГ ${isLose ? 'СБРОСИТЬ' : 'НАБРАТЬ'}',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.15), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 9,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _buildGlowRay(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        height: 16,
        child: CustomPaint(
          painter: _GlowRayPainter(
            color: color,
            widthFactor: 0.86,
            backgroundColor: _lineBase,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Заполни возраст, вес и рост'),
          backgroundColor: _pink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
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
    await provider.saveUserProfile(profile);

    if (!mounted) return;
    setState(() => _showResults = true);
  }

  // ============================================================
  // RECOMMENDATIONS SHEET
  // ============================================================

  void _showRecommendations(NutritionProvider provider) {
    final profile = provider.userProfile;
    if (profile == null) return;

    HapticFeedback.selectionClick();

    // Кэшируем текущий акцент (вне build-фазы)
    final accent = context.read<ColorSettingsProvider>().accent;

    final prediction = profile.goalPrediction;
    final weekSummary = provider.getLast7DaysSummaries();
    final extras = <Map<String, dynamic>>[];

    if (profile.bmiCategory != 'Норма') {
      extras.add({
        'emoji': '⚖️',
        'title': 'ИНДЕКС МАССЫ ТЕЛА',
        'message':
        'ИМТ: ${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})',
        'color': _yellow,
      });
    }

    final proteinPercent = profile.targetCalories > 0
        ? (profile.recommendedProtein * 4 / profile.targetCalories * 100)
        .round()
        : 0;
    final fatPercent = profile.targetCalories > 0
        ? (profile.recommendedFat * 9 / profile.targetCalories * 100).round()
        : 0;
    final carbsPercent = profile.targetCalories > 0
        ? (profile.recommendedCarbs * 4 / profile.targetCalories * 100)
        .round()
        : 0;

    extras.add({
      'emoji': '📊',
      'title': 'РАСПРЕДЕЛЕНИЕ БЖУ',
      'message':
      'Белки $proteinPercent% • Жиры $fatPercent% • Углеводы $carbsPercent%',
      'color': accent,
    });

    if (profile.recommendedWater > 2000) {
      extras.add({
        'emoji': '💧',
        'title': 'ВОДНЫЙ БАЛАНС',
        'message': 'Рекомендуется ${profile.recommendedWater} мл воды в день.',
        'color': _blue,
      });
    }

    final activityMessages = {
      ActivityLevel.sedentary: 'Добавь немного ежедневного движения.',
      ActivityLevel.light: 'Хороший старт. Постепенно увеличивай активность.',
      ActivityLevel.moderate: 'Отличный уровень активности.',
      ActivityLevel.active: 'Хороший темп. Следи за восстановлением.',
      ActivityLevel.veryActive:
      'Высокая нагрузка — питание становится особенно важным.',
      ActivityLevel.professional:
      'Очень высокая нагрузка. Поддерживай достаточное питание.',
    };

    extras.add({
      'emoji': '🏃',
      'title': 'АКТИВНОСТЬ',
      'message': activityMessages[profile.activityLevel] ??
          'Продолжай в том же духе.',
      'color': _green,
    });

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.86,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(29),
            ),
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
                    color: _textMuted,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(17, 18, 17, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: _purple.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _Power.softGlow(_Power.violet,
                                    strength: 0.2),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: _purple,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'УМНЫЕ РЕКОМЕНДАЦИИ',
                                    style: TextStyle(
                                      color: _purple,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'На основе твоего профиля',
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        _recommendationCard(
                          '🎯',
                          'ЦЕЛЕВАЯ КАЛОРИЙНОСТЬ',
                          '${profile.targetCalories.round()} ккал/день',
                          'TDEE: ${profile.tdee.round()} ккал',
                          accent,
                        ),
                        _recommendationCard(
                          '🥩',
                          'БЕЛОК',
                          '${profile.recommendedProtein.round()} г',
                          '${(profile.recommendedProtein / profile.weight).toStringAsFixed(1)} г/кг',
                          _green,
                        ),
                        _recommendationCard(
                          '🧈',
                          'ЖИРЫ',
                          '${profile.recommendedFat.round()} г',
                          '$fatPercent% от калорий',
                          _pink,
                        ),
                        _recommendationCard(
                          '🍞',
                          'УГЛЕВОДЫ',
                          '${profile.recommendedCarbs.round()} г',
                          '$carbsPercent% от калорий',
                          _yellow,
                        ),
                        _recommendationCard(
                          '💧',
                          'ВОДА',
                          '${profile.recommendedWater} мл',
                          '${(profile.recommendedWater / profile.weight).round()} мл/кг',
                          _blue,
                        ),

                        if (extras.isNotEmpty) ...[
                          _buildGlowRay(_purple),
                          ...extras.map(
                                (item) => _extraRecommendation(item),
                          ),
                        ],

                        if (prediction['canPredict'] == true) ...[
                          _buildGlowRay(_yellow),
                          _recommendationPrediction(prediction),
                        ],

                        if (weekSummary.isNotEmpty) ...[
                          _buildGlowRay(accent),
                          Text(
                            'НЕДЕЛЬНАЯ СТАТИСТИКА',
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 9),
                          ...weekSummary
                              .take(7)
                              .map((data) => _weekRow(data)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _recommendationCard(
      String emoji,
      String title,
      String value,
      String subtitle,
      Color color,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.15), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _extraRecommendation(Map<String, dynamic> data) {
    final color = data['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.15), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['emoji'] as String,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (data['title'] as String).toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data['message'] as String,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 9,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendationPrediction(Map<String, dynamic> prediction) {
    final isLose = prediction['isLose'] == true;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _yellow.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _yellow.withOpacity(0.20), width: 0.5),
      ),
      child: Row(
        children: [
          Text(isLose ? '📉' : '📈', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ПРОГНОЗ',
                  style: TextStyle(
                    color: _yellow,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${prediction['days']} ДНЕЙ • ${prediction['absDiff'].toStringAsFixed(1)} КГ ${isLose ? 'СБРОСИТЬ' : 'НАБРАТЬ'}',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${data.calories.round()} ККАЛ',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Text(
            'Б ${data.protein.round()}',
            style: const TextStyle(
              color: _green,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'Ж ${data.fat.round()}',
            style: const TextStyle(
              color: _pink,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'У ${data.carbs.round()}',
            style: const TextStyle(
              color: _yellow,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATA INFO
  // ============================================================

  _GoalInfo _goalInfo(GoalType goal) {
    switch (goal) {
      case GoalType.maintain:
        return _GoalInfo(
          emoji: '⚖️',
          title: 'Поддержание',
          subtitle: 'Сохранять текущий вес',
          color: _cyan,
        );
      case GoalType.lose:
        return const _GoalInfo(
          emoji: '🔥',
          title: 'Похудение',
          subtitle: 'Снизить вес',
          color: _orange,
        );
      case GoalType.gain:
        return const _GoalInfo(
          emoji: '📈',
          title: 'Набор веса',
          subtitle: 'Постепенно увеличить массу',
          color: _green,
        );
      case GoalType.muscleGain:
        return const _GoalInfo(
          emoji: '💪',
          title: 'Набор мышц',
          subtitle: 'Фокус на мышечном росте',
          color: _purple,
        );
      case GoalType.recomposition:
        return _GoalInfo(
          emoji: '🔄',
          title: 'Рекомпозиция',
          subtitle: 'Мышцы вверх, жир вниз',
          color: _cyan,
        );
    }
  }

  _PaceInfo _paceInfo(GoalPace pace) {
    switch (pace) {
      case GoalPace.slow:
        return const _PaceInfo(
          emoji: '🐢',
          title: 'Медленно',
          color: _green,
        );
      case GoalPace.moderate:
        return const _PaceInfo(
          emoji: '⚡',
          title: 'Умеренно',
          color: _yellow,
        );
      case GoalPace.fast:
        return const _PaceInfo(
          emoji: '🚀',
          title: 'Быстро',
          color: _pink,
        );
    }
  }

  _ActivityInfo _activityInfo(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return const _ActivityInfo(
          emoji: '🪑',
          title: 'Сидячий',
          subtitle: 'Минимум движения',
          color: _blue,
        );
      case ActivityLevel.light:
        return _ActivityInfo(
          emoji: '🚶',
          title: 'Лёгкий',
          subtitle: 'Немного прогулок',
          color: _cyan,
        );
      case ActivityLevel.moderate:
        return const _ActivityInfo(
          emoji: '🏃',
          title: 'Умеренный',
          subtitle: 'Регулярная активность',
          color: _green,
        );
      case ActivityLevel.active:
        return const _ActivityInfo(
          emoji: '💪',
          title: 'Активный',
          subtitle: 'Много движения',
          color: _yellow,
        );
      case ActivityLevel.veryActive:
        return const _ActivityInfo(
          emoji: '🔥',
          title: 'Очень активный',
          subtitle: 'Высокая нагрузка',
          color: _orange,
        );
      case ActivityLevel.professional:
        return const _ActivityInfo(
          emoji: '🏆',
          title: 'Профессиональный',
          subtitle: 'Интенсивные тренировки',
          color: _purple,
        );
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

// ============================================================
// SMALL DATA CLASSES
// ============================================================

class _GoalInfo {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _GoalInfo({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _PaceInfo {
  final String emoji;
  final String title;
  final Color color;

  const _PaceInfo({
    required this.emoji,
    required this.title,
    required this.color,
  });
}

class _ActivityInfo {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityInfo({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

// ============================================================
// GLOW RAY PAINTER
// ============================================================

class _GlowRayPainter extends CustomPainter {
  final Color color;
  final double widthFactor;
  final Color backgroundColor;
  final double coreWidth;
  final double glowWidth;

  _GlowRayPainter({
    required this.color,
    required this.widthFactor,
    required this.backgroundColor,
    this.coreWidth = 2.2,
    this.glowWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    if (backgroundColor != Colors.transparent) {
      final basePaint = Paint()
        ..color = backgroundColor
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        basePaint,
      );
    }

    final totalWidth = size.width * widthFactor;
    final left = (size.width - totalWidth) / 2;
    final right = left + totalWidth;

    final rect = Rect.fromLTRB(left, 0, right, size.height);

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withOpacity(0),
        color.withOpacity(0.035),
        color.withOpacity(0.12),
        color.withOpacity(0.35),
        color.withOpacity(0.88),
        color,
        color.withOpacity(0.88),
        color.withOpacity(0.35),
        color.withOpacity(0.12),
        color.withOpacity(0.035),
        color.withOpacity(0),
      ],
      stops: const [
        0,
        0.10,
        0.22,
        0.36,
        0.46,
        0.50,
        0.54,
        0.64,
        0.78,
        0.90,
        1,
      ],
    );

    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawLine(Offset(left, centerY), Offset(right, centerY), glowPaint);

    final corePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = coreWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(left, centerY), Offset(right, centerY), corePaint);
  }

  @override
  bool shouldRepaint(covariant _GlowRayPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.widthFactor != widthFactor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.coreWidth != coreWidth ||
        oldDelegate.glowWidth != glowWidth;
  }
}