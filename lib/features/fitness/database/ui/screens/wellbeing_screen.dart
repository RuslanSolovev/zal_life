// features/fitness/ui/screens/wellbeing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/fitness_provider.dart';

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

class WellbeingScreen extends StatefulWidget {
  final bool isDark;

  const WellbeingScreen({
    super.key,
    this.isDark = false,
  });

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen>
    with TickerProviderStateMixin {
  int _energy = 7;
  int _sleep = 7;
  int _motivation = 7;
  String? _notes;
  List<String> _painAreas = [];
  bool _isSubmitting = false;
  bool _showStats = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _statsController;
  late Animation<double> _statsAnimation;

  final List<String> _moodEmojis = [
    '😫', '😩', '😐', '🙂', '😊', '😁', '🤩', '🔥', '💪', '🚀'
  ];
  final List<String> _moodLabels = [
    'Ужасно', 'Плохо', 'Средне', 'Нормально', 'Хорошо',
    'Отлично', 'Замечательно', 'Супер', 'Великолепно', 'Невероятно'
  ];

  final List<String> _motivationQuotes = [
    'Каждый день — шанс стать лучше',
    'Ты сильнее, чем думаешь',
    'Продолжай в том же духе',
    'Маленькие шаги — большие результаты',
    'Забота о себе — это сила',
    'После дождя выходит солнце',
    'Твой потенциал безграничен',
    'Слушай своё тело',
    'Ты стал сильнее, чем вчера',
    'Ты — герой своей истории',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _statsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _statsController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = context.watch<FitnessProvider>();
    final todayWellbeing = provider.getTodayWellbeing();
    final notes = provider.wellbeingNotes;

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(isDark, provider)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(isDark, todayWellbeing),
                        const SizedBox(height: 16),
                        if (notes.isNotEmpty) _buildStatsToggle(isDark, provider),
                        if (todayWellbeing != null) ...[
                          const SizedBox(height: 16),
                          _buildTodayCard(isDark, todayWellbeing),
                        ],
                        const SizedBox(height: 16),
                        _buildFormCard(isDark, provider),
                        const SizedBox(height: 24),
                        if (notes.isNotEmpty) ...[
                          _buildHistoryHeader(isDark, notes),
                          const SizedBox(height: 12),
                          ...notes.take(10).map((note) =>
                              _buildHistoryCard(isDark, note, provider)),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // HEADER
  // =====================================================================

  Widget _buildHeader(bool isDark, FitnessProvider provider) {
    final stats = provider.getWellbeingStats();
    final avgMood = stats['avgEnergy'] ?? 0;
    final hasNotes = provider.wellbeingNotes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    const Text(
                      'ЗДОРОВЬЕ',
                      style: TextStyle(
                        color: _Power.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Самочувствие',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        height: 1.1,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              // Info button
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showInfoDialog(context, isDark);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _Power.ice.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: _Power.ice,
                    size: 18,
                  ),
                ),
              ),
              if (hasNotes) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _getColorForValue(avgMood.toInt())
                        .withOpacity(0.14),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: _Power.softGlow(
                      _getColorForValue(avgMood.toInt()),
                      strength: 0.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getEmojiForValue(avgMood.toInt()),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        avgMood.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          height: 1,
                          color: _getColorForValue(avgMood.toInt()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // GREETING
  // =====================================================================

  Widget _buildGreeting(bool isDark, WellbeingNote? todayWellbeing) {
    final timeOfDay = DateTime.now().hour;
    String greeting;
    String emoji;

    if (timeOfDay < 6) {
      greeting = 'Доброй ночи';
      emoji = '🌙';
    } else if (timeOfDay < 12) {
      greeting = 'Доброе утро';
      emoji = '🌅';
    } else if (timeOfDay < 18) {
      greeting = 'Добрый день';
      emoji = '☀️';
    } else {
      greeting = 'Добрый вечер';
      emoji = '🌆';
    }

    final hasRecord = todayWellbeing != null;
    final randomQuote =
    _motivationQuotes[DateTime.now().day % _motivationQuotes.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _Power.green.withOpacity(0.10),
            _Power.green.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _Power.green.withOpacity(0.2),
          width: 0.8,
        ),
        boxShadow: _Power.softGlow(_Power.green, strength: 0.1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _Power.green.withOpacity(0.14),
              shape: BoxShape.circle,
              boxShadow: _Power.softGlow(_Power.green, strength: 0.25),
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    height: 1.1,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasRecord ? 'Сегодня уже записано' : randomQuote,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    hasRecord ? FontWeight.w800 : FontWeight.w500,
                    color: hasRecord
                        ? _Power.green
                        : _Power.textSecondary(isDark),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (hasRecord)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _Power.green,
                borderRadius: BorderRadius.circular(10),
                boxShadow:
                _Power.softGlow(_Power.green, strength: 0.4),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================================
  // STATS TOGGLE
  // =====================================================================

  Widget _buildStatsToggle(bool isDark, FitnessProvider provider) {
    final stats = provider.getWellbeingStats();
    final total = stats['total']?.toInt() ?? 0;
    final avgEnergy = stats['avgEnergy'] ?? 0;
    final avgSleep = stats['avgSleep'] ?? 0;
    final avgMotivation = stats['avgMotivation'] ?? 0;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _showStats = !_showStats;
              if (_showStats) {
                _statsController.forward(from: 0);
              }
            });
          },
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _Power.ice.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: _Power.ice,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'СТАТИСТИКА',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      color: _Power.textPrimary(isDark),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _Power.ice.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      height: 1,
                      color: _Power.ice,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: _showStats ? 0.5 : 0,
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: _Power.textTertiary(isDark),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Stats content
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _showStats
              ? Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FadeTransition(
              opacity: _statsAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
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
                    _buildAvgStat(
                      isDark,
                      '⚡',
                      'ЭНЕРГИЯ',
                      avgEnergy,
                    ),
                    Container(
                      width: 0.5,
                      height: 44,
                      color: _Power.separator(isDark),
                    ),
                    _buildAvgStat(
                      isDark,
                      '😴',
                      'СОН',
                      avgSleep,
                    ),
                    Container(
                      width: 0.5,
                      height: 44,
                      color: _Power.separator(isDark),
                    ),
                    _buildAvgStat(
                      isDark,
                      '🎯',
                      'МОТИВ',
                      avgMotivation,
                    ),
                  ],
                ),
              ),
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildAvgStat(
      bool isDark,
      String emoji,
      String label,
      double value,
      ) {
    final color = _getColorForValue(value.round());
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              height: 1,
              color: color,
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
  // TODAY CARD
  // =====================================================================

  Widget _buildTodayCard(bool isDark, WellbeingNote note) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _Power.green.withOpacity(0.12),
            _Power.green.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _Power.green.withOpacity(0.25),
          width: 0.8,
        ),
        boxShadow: _Power.softGlow(_Power.green, strength: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _Power.green.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow:
                  _Power.softGlow(_Power.green, strength: 0.2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.today_rounded,
                  color: _Power.green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'СЕГОДНЯ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: _Power.green,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _Power.card2(isDark),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  _formatDate(note.date),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: _Power.textSecondary(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildMoodStat(isDark, '⚡', 'ЭНЕРГИЯ', note.energyLevel),
              _buildMoodStat(isDark, '😴', 'СОН', note.sleepQuality),
              _buildMoodStat(
                  isDark, '🎯', 'МОТИВ', note.motivationLevel),
            ],
          ),
          if (note.painAreas.isNotEmpty &&
              !note.painAreas.contains('Нет болей')) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _Power.volt.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _Power.volt.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.healing_rounded,
                    color: _Power.volt,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'БОЛИ: ${note.painAreas.join(" • ").toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: _Power.volt,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (note.notes != null && note.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _Power.card(isDark).withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💭', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '«${note.notes!}»',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: _Power.textSecondary(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodStat(
      bool isDark,
      String emoji,
      String label,
      int value,
      ) {
    final color = _getColorForValue(value);
    final moodEmoji = _moodEmojis[value.clamp(1, 10) - 1];
    final moodLabel = _moodLabels[value.clamp(1, 10) - 1];

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: _Power.softGlow(color, strength: 0.25),
            ),
            alignment: Alignment.center,
            child: Text(
              moodEmoji,
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  height: 1,
                  color: color,
                ),
              ),
              Text(
                '/10',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _Power.textTertiary(isDark),   // ← теперь с аргументом
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            moodLabel.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: _Power.textTertiary(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // FORM CARD
  // =====================================================================

  Widget _buildFormCard(bool isDark, FitnessProvider provider) {
    final hasTodayRecord = provider.getTodayWellbeing() != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _Power.separator(isDark),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _Power.volt.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow:
                  _Power.softGlow(_Power.volt, strength: 0.2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: _Power.volt,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasTodayRecord
                          ? 'ОБНОВИТЬ'
                          : 'ЗАПИСАТЬ САМОЧУВСТВИЕ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Оцените состояние от 1 до 10',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _Power.textTertiary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildAnimatedSlider(
            isDark,
            'ЭНЕРГИЯ',
            Icons.flash_on_rounded,
            _energy.toDouble(),
                (v) => setState(() => _energy = v.toInt()),
          ),
          const SizedBox(height: 4),
          _buildAnimatedSlider(
            isDark,
            'СОН',
            Icons.bed_rounded,
            _sleep.toDouble(),
                (v) => setState(() => _sleep = v.toInt()),
          ),
          const SizedBox(height: 4),
          _buildAnimatedSlider(
            isDark,
            'МОТИВАЦИЯ',
            Icons.rocket_launch_rounded,
            _motivation.toDouble(),
                (v) => setState(() => _motivation = v.toInt()),
          ),

          const SizedBox(height: 20),
          _buildPainSelector(isDark),
          const SizedBox(height: 20),
          _buildNotesField(isDark),
          const SizedBox(height: 22),
          _buildSubmitButton(isDark, provider, hasTodayRecord),
        ],
      ),
    );
  }

  // =====================================================================
  // ANIMATED SLIDER
  // =====================================================================

  Widget _buildAnimatedSlider(
      bool isDark,
      String label,
      IconData icon,
      double value,
      Function(double) onChanged,
      ) {
    final intValue = value.toInt();
    final emoji = _moodEmojis[intValue.clamp(1, 10) - 1];
    final color = _getColorForValue(intValue);
    final moodLabel = _moodLabels[intValue.clamp(1, 10) - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: _Power.textPrimary(isDark),
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(intValue),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withOpacity(0.35),
                    width: 0.8,
                  ),
                  boxShadow: _Power.softGlow(color, strength: 0.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$intValue/10',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: -0.3,
                            height: 1,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          moodLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            height: 1,
                            color: color.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 11,
              pressedElevation: 8,
            ),
            thumbColor: color,
            activeTrackColor: color,
            inactiveTrackColor: _Power.separator(isDark),
            overlayColor: color.withOpacity(0.2),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 22,
            ),
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
            valueIndicatorColor: color,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
            label: '$intValue',
          ),
        ),
      ],
    );
  }

  Color _getColorForValue(int value) {
    if (value <= 3) return _Power.red;
    if (value <= 5) return _Power.volt;
    if (value <= 7) return _Power.plasma;
    return _Power.green;
  }

  String _getEmojiForValue(int value) {
    return _moodEmojis[value.clamp(1, 10) - 1];
  }

  // =====================================================================
  // PAIN SELECTOR
  // =====================================================================

  Widget _buildPainSelector(bool isDark) {
    final painOptions = [
      'Спина', 'Плечи', 'Колени', 'Шея',
      'Голова', 'Ноги', 'Руки', 'Нет болей',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _Power.volt.withOpacity(0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.healing_rounded,
                color: _Power.volt,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'БОЛЕВЫЕ ТОЧКИ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: _Power.textPrimary(isDark),
              ),
            ),
            if (_painAreas.isNotEmpty) ...[
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _painAreas.clear());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _Power.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text(
                    'ОЧИСТИТЬ',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      height: 1,
                      color: _Power.red,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: painOptions.map((area) {
            final isSelected = _painAreas.contains(area);
            final isNoPain = area == 'Нет болей';
            final accent = isNoPain ? _Power.green : _Power.volt;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _painAreas.remove(area);
                  } else {
                    if (isNoPain) {
                      _painAreas.clear();
                      _painAreas.add(area);
                    } else {
                      _painAreas.remove('Нет болей');
                      _painAreas.add(area);
                    }
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withOpacity(0.14)
                      : _Power.card2(isDark),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: isSelected ? accent : Colors.transparent,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? _Power.softGlow(accent, strength: 0.25)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        isNoPain
                            ? Icons.check_rounded
                            : Icons.warning_rounded,
                        color: accent,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      area,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        letterSpacing: -0.1,
                        color: isSelected
                            ? accent
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

  // =====================================================================
  // NOTES FIELD
  // =====================================================================

  Widget _buildNotesField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _Power.ice.withOpacity(0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.note_rounded,
                color: _Power.ice,
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'ЗАМЕТКИ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: _Power.textPrimary(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          maxLines: 3,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _Power.textPrimary(isDark),
          ),
          decoration: InputDecoration(
            hintText: 'Как вы себя чувствуете?',
            hintStyle: TextStyle(
              color: _Power.textTertiary(isDark),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: _Power.card2(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _Power.separator(isDark),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _Power.volt,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
          onChanged: (v) => _notes = v.isEmpty ? null : v,
        ),
      ],
    );
  }

  // =====================================================================
  // SUBMIT
  // =====================================================================

  Widget _buildSubmitButton(
      bool isDark,
      FitnessProvider provider,
      bool hasTodayRecord,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting
            ? null
            : () async {
          if (!hasTodayRecord) {
            if (_energy == 0 || _sleep == 0 || _motivation == 0) {
              HapticFeedback.mediumImpact();
              _showSnack('Оцените все показатели', _Power.plasma);
              return;
            }
          }

          HapticFeedback.mediumImpact();
          setState(() => _isSubmitting = true);

          try {
            await provider.addWellbeingNote(
              energyLevel: _energy,
              sleepQuality: _sleep,
              motivationLevel: _motivation,
              painAreas: _painAreas,
              notes: _notes,
            );

            if (!mounted) return;

            _showSnack(
              hasTodayRecord
                  ? 'Самочувствие обновлено'
                  : 'Самочувствие записано',
              _Power.green,
              success: true,
            );

            setState(() {
              _notes = null;
              _painAreas = [];
              _energy = 7;
              _sleep = 7;
              _motivation = 7;
            });
          } catch (e) {
            if (!mounted) return;
            _showSnack('Ошибка: $e', _Power.red);
          } finally {
            if (mounted) setState(() => _isSubmitting = false);
          }
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSubmitting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                hasTodayRecord
                    ? Icons.refresh_rounded
                    : Icons.check_rounded,
                size: 20,
              ),
            const SizedBox(width: 8),
            Text(
              _isSubmitting
                  ? 'СОХРАНЕНИЕ…'
                  : (hasTodayRecord ? 'ОБНОВИТЬ' : 'СОХРАНИТЬ'),
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

  // =====================================================================
  // HISTORY HEADER
  // =====================================================================

  Widget _buildHistoryHeader(bool isDark, List<WellbeingNote> notes) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: _Power.volt,
              borderRadius: BorderRadius.circular(2),
              boxShadow: _Power.softGlow(_Power.volt, strength: 0.6),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'ИСТОРИЯ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
              color: _Power.textPrimary(isDark),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _Power.volt.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${notes.length}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                height: 1,
                color: _Power.volt,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // HISTORY CARD
  // =====================================================================

  Widget _buildHistoryCard(
      bool isDark,
      WellbeingNote note,
      FitnessProvider provider,
      ) {
    final avg = ((note.energyLevel +
        note.sleepQuality +
        note.motivationLevel) /
        3)
        .toStringAsFixed(1);

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        HapticFeedback.mediumImpact();
        await provider.deleteWellbeingNote(note.id);
        if (!mounted) return;
        _showSnack('Запись удалена', _Power.red);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _Power.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _Power.card(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _Power.separator(isDark),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + mood chips
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _Power.card2(isDark),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDate(note.date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: _Power.textPrimary(isDark),
                    ),
                  ),
                ),
                const Spacer(),
                _buildMoodChip(isDark, note.energyLevel),
                const SizedBox(width: 4),
                _buildMoodChip(isDark, note.sleepQuality),
                const SizedBox(width: 4),
                _buildMoodChip(isDark, note.motivationLevel),
              ],
            ),

            // Pain
            if (note.painAreas.isNotEmpty &&
                !note.painAreas.contains('Нет болей')) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: note.painAreas.map((area) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _Power.volt.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      area.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        height: 1,
                        color: _Power.volt,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Notes
            if (note.notes != null && note.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💭', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: _Power.textSecondary(isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Average
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: _Power.card2(isDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    size: 11,
                    color: _Power.textTertiary(isDark),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'СРЕДНЕЕ: $avg',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      height: 1,
                      color: _Power.textTertiary(isDark),
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

  Widget _buildMoodChip(bool isDark, int value) {
    final color = _getColorForValue(value);
    final emoji = _moodEmojis[value.clamp(1, 10) - 1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              height: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // INFO DIALOG
  // =====================================================================

  void _showInfoDialog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                'О САМОЧУВСТВИИ',
                style: TextStyle(
                  color: _Power.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Как это работает',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: _Power.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 18),
              _buildInfoItem(isDark, '⚡', 'ЭНЕРГИЯ',
                  'Уровень бодрости и активности'),
              const SizedBox(height: 10),
              _buildInfoItem(isDark, '😴', 'СОН',
                  'Качество и продолжительность сна'),
              const SizedBox(height: 10),
              _buildInfoItem(isDark, '🎯', 'МОТИВАЦИЯ',
                  'Желание тренироваться'),
              const SizedBox(height: 10),
              _buildInfoItem(isDark, '🔴', 'БОЛИ',
                  'Отметьте зоны дискомфорта'),
              const SizedBox(height: 10),
              _buildInfoItem(
                  isDark, '💭', 'ЗАМЕТКИ', 'Детали и наблюдения'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _Power.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _Power.green.withOpacity(0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _Power.green.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: _Power.green,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Записывайте самочувствие ежедневно, чтобы отслеживать прогресс и вовремя замечать изменения',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: _Power.textSecondary(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Power.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'ПОНЯТНО',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      bool isDark,
      String emoji,
      String label,
      String description,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Power.card2(isDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _Power.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  void _showSnack(String text, Color color, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (success)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
            if (success) const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    final now = DateTime.now();
    final isToday = date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;

    if (isToday) return 'Сегодня';

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year;

    if (isYesterday) return 'Вчера';

    return '${date.day} ${months[date.month - 1]}';
  }
}

// ==================== EXTENSION ====================

extension WellbeingStats on FitnessProvider {
  Map<String, double> getWellbeingStats() {
    if (wellbeingNotes.isEmpty) {
      return {
        'avgEnergy': 0,
        'avgSleep': 0,
        'avgMotivation': 0,
        'total': 0,
      };
    }

    final total = wellbeingNotes.length.toDouble();
    final avgEnergy = wellbeingNotes
        .map((n) => n.energyLevel)
        .reduce((a, b) => a + b) /
        total;
    final avgSleep = wellbeingNotes
        .map((n) => n.sleepQuality)
        .reduce((a, b) => a + b) /
        total;
    final avgMotivation = wellbeingNotes
        .map((n) => n.motivationLevel)
        .reduce((a, b) => a + b) /
        total;

    return {
      'avgEnergy': double.parse(avgEnergy.toStringAsFixed(1)),
      'avgSleep': double.parse(avgSleep.toStringAsFixed(1)),
      'avgMotivation': double.parse(avgMotivation.toStringAsFixed(1)),
      'total': total,
    };
  }
}