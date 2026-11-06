// features/fitness/ui/screens/wellbeing_screen.dart
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/fitness_models.dart';
import '../../../providers/fitness_provider.dart';

// ==================== DESIGN TOKENS ====================

class _C {
  // Surfaces
  static const lightBg = Color(0xFFF5F5F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFFAFAFB);
  static const lightBorder = Color(0xFFE5E5EA);

  static const darkBg = Color(0xFF0F1012);
  static const darkSurface = Color(0xFF1A1B1E);
  static const darkSurface2 = Color(0xFF232427);
  static const darkBorder = Color(0xFF2C2D31);

  // Text
  static const lightText = Color(0xFF1A1A1C);
  static const lightMuted = Color(0xFF6E6F73);
  static const lightSubtle = Color(0xFFA0A1A6);
  static const darkText = Color(0xFFF2F2F5);
  static const darkMuted = Color(0xFF9B9CA1);
  static const darkSubtle = Color(0xFF63646A);

  // Single slate accent
  static const accent = Color(0xFF4B5B76);
  static const accentLight = Color(0xFFE8ECF3);
  static const accentDark = Color(0xFF7D8BB0);

  // Muted mood scale
  static const low = Color(0xFFB5564E);   // red muted
  static const mid = Color(0xFFB8884E);   // amber muted
  static const high = Color(0xFF5B8F72);  // green muted
}

class _R {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 22.0;
}

class _Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

class _T {
  static const _feat = <FontFeature>[FontFeature.tabularFigures()];

  static TextStyle overline(bool isDark) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    color: isDark ? _C.darkSubtle : _C.lightSubtle,
  );

  static TextStyle title(bool isDark) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: isDark ? _C.darkText : _C.lightText,
  );

  static TextStyle section(bool isDark) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: isDark ? _C.darkText : _C.lightText,
  );

  static TextStyle body(bool isDark) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: isDark ? _C.darkText : _C.lightText,
  );

  static TextStyle muted(bool isDark) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: isDark ? _C.darkMuted : _C.lightMuted,
  );

  static TextStyle number(bool isDark, {double size = 20, FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -0.4,
        fontFeatures: _feat,
        height: 1,
        color: isDark ? _C.darkText : _C.lightText,
      );
}

// ==================== PRESSABLE ====================

class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.scale = 0.98,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;
  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ==================== SCREEN ====================

class WellbeingScreen extends StatefulWidget {
  final bool isDark;

  const WellbeingScreen({
    super.key,
    this.isDark = false,
  });

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen> {
  int _energy = 7;
  int _sleep = 7;
  int _motivation = 7;
  String? _notes;
  final List<String> _painAreas = [];
  bool _isSubmitting = false;
  bool _showStats = false;

  final List<String> _moodEmojis = [
    '😫', '😩', '😐', '🙂', '😊', '😁', '🤩', '🔥', '💪', '🚀'
  ];
  final List<String> _moodLabels = [
    'Ужасно', 'Плохо', 'Средне', 'Нормально', 'Хорошо',
    'Отлично', 'Замечательно', 'Супер', 'Великолепно', 'Невероятно'
  ];
  final List<String> _quotes = [
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
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = context.watch<FitnessProvider>();
    final todayWellbeing = provider.getTodayWellbeing();
    final notes = provider.wellbeingNotes;

    return Scaffold(
      backgroundColor: isDark ? _C.darkBg : _C.lightBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(isDark, provider)),

            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(_Sp.xl, _Sp.xl, _Sp.xl, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildGreeting(isDark, todayWellbeing),
                  const SizedBox(height: _Sp.xxl),

                  if (todayWellbeing != null) ...[
                    _buildTodayCard(isDark, todayWellbeing),
                    const SizedBox(height: _Sp.xxl),
                  ],

                  _buildFormCard(isDark, provider),
                  const SizedBox(height: _Sp.xxl),

                  if (notes.isNotEmpty) ...[
                    _buildStatsSection(isDark, provider),
                    const SizedBox(height: _Sp.xxl),
                    _buildHistorySection(isDark, notes, provider),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // HEADER
  // =====================================================================

  Widget _buildHeader(bool isDark, FitnessProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_Sp.xl, _Sp.md, _Sp.xl, 0),
      child: Row(
        children: [
          _Pressable(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? _C.darkSurface : _C.lightSurface,
                borderRadius: BorderRadius.circular(_R.sm),
                border: Border.all(
                  color: isDark ? _C.darkBorder : _C.lightBorder,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? _C.darkText : _C.lightText,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: _Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WELLBEING', style: _T.overline(isDark)),
                const SizedBox(height: 2),
                Text('Самочувствие', style: _T.title(isDark)),
              ],
            ),
          ),
          _Pressable(
            onTap: () => _showInfoDialog(context, isDark),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? _C.darkSurface : _C.lightSurface,
                borderRadius: BorderRadius.circular(_R.sm),
                border: Border.all(
                  color: isDark ? _C.darkBorder : _C.lightBorder,
                ),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: isDark ? _C.darkMuted : _C.lightMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // GREETING
  // =====================================================================

  Widget _buildGreeting(bool isDark, WellbeingNote? todayWellbeing) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 6) {
      greeting = 'Доброй ночи';
    } else if (hour < 12) {
      greeting = 'Доброе утро';
    } else if (hour < 18) {
      greeting = 'Добрый день';
    } else {
      greeting = 'Добрый вечер';
    }

    final hasRecord = todayWellbeing != null;
    final quote = _quotes[DateTime.now().day % _quotes.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: isDark ? _C.darkText : _C.lightText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasRecord ? 'Сегодня уже записано' : quote,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontStyle: hasRecord ? FontStyle.normal : FontStyle.italic,
            height: 1.4,
            color: hasRecord
                ? (isDark ? _C.accentDark : _C.accent)
                : (isDark ? _C.darkMuted : _C.lightMuted),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // TODAY CARD
  // =====================================================================

  Widget _buildTodayCard(bool isDark, WellbeingNote note) {
    return Container(
      padding: const EdgeInsets.all(_Sp.lg),
      decoration: BoxDecoration(
        color: isDark ? _C.darkSurface : _C.lightSurface,
        borderRadius: BorderRadius.circular(_R.md),
        border: Border.all(color: isDark ? _C.darkBorder : _C.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('СЕГОДНЯ', style: _T.overline(isDark)),
              const Spacer(),
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: isDark ? _C.accentDark : _C.accent,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(note.date),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? _C.darkMuted : _C.lightMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: _Sp.lg),
          Row(
            children: [
              _buildTodayMetric(
                isDark,
                'Энергия',
                note.energyLevel,
              ),
              _buildTodayMetric(
                isDark,
                'Сон',
                note.sleepQuality,
              ),
              _buildTodayMetric(
                isDark,
                'Мотивация',
                note.motivationLevel,
              ),
            ],
          ),
          if (note.painAreas.isNotEmpty &&
              !note.painAreas.contains('Нет болей')) ...[
            const SizedBox(height: _Sp.lg),
            Container(height: 1, color: isDark ? _C.darkBorder : _C.lightBorder),
            const SizedBox(height: _Sp.md),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: note.painAreas.map((area) {
                return _buildPainChip(isDark, area);
              }).toList(),
            ),
          ],
          if (note.notes != null && note.notes!.isNotEmpty) ...[
            const SizedBox(height: _Sp.md),
            Text(
              '«${note.notes!}»',
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: isDark ? _C.darkMuted : _C.lightMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayMetric(bool isDark, String label, int value) {
    final color = _colorForValue(value);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? _C.darkMuted : _C.lightMuted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$value',
                style: _T.number(isDark, size: 28, weight: FontWeight.w600)
                    .copyWith(color: color),
              ),
              const SizedBox(width: 2),
              Text(
                '/10',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isDark ? _C.darkSubtle : _C.lightSubtle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPainChip(bool isDark, String area) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? _C.darkSurface2 : _C.lightSurface2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? _C.low.withOpacity(0.30)
              : _C.low.withOpacity(0.20),
        ),
      ),
      child: Text(
        area,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _C.low,
        ),
      ),
    );
  }

  // =====================================================================
  // STATS SECTION
  // =====================================================================

  Widget _buildStatsSection(bool isDark, FitnessProvider provider) {
    final stats = provider.getWellbeingStats();
    final total = stats['total']?.toInt() ?? 0;
    final avgEnergy = stats['avgEnergy'] ?? 0;
    final avgSleep = stats['avgSleep'] ?? 0;
    final avgMotivation = stats['avgMotivation'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Pressable(
          onTap: () => setState(() => _showStats = !_showStats),
          child: Container(
            padding: const EdgeInsets.all(_Sp.lg),
            decoration: BoxDecoration(
              color: isDark ? _C.darkSurface : _C.lightSurface,
              borderRadius: BorderRadius.circular(_R.md),
              border:
              Border.all(color: isDark ? _C.darkBorder : _C.lightBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  size: 16,
                  color: isDark ? _C.darkMuted : _C.lightMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  'Средние показатели',
                  style: _T.section(isDark),
                ),
                const SizedBox(width: _Sp.sm),
                Text(
                  '$total записей',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isDark ? _C.darkSubtle : _C.lightSubtle,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _showStats ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDark ? _C.darkMuted : _C.lightMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: _Sp.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: _Sp.lg),
              decoration: BoxDecoration(
                color: isDark ? _C.darkSurface : _C.lightSurface,
                borderRadius: BorderRadius.circular(_R.md),
                border:
                Border.all(color: isDark ? _C.darkBorder : _C.lightBorder),
              ),
              child: Row(
                children: [
                  _buildAvgStat(isDark, 'Энергия', avgEnergy),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark ? _C.darkBorder : _C.lightBorder,
                  ),
                  _buildAvgStat(isDark, 'Сон', avgSleep),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark ? _C.darkBorder : _C.lightBorder,
                  ),
                  _buildAvgStat(isDark, 'Мотивация', avgMotivation),
                ],
              ),
            ),
          ),
          crossFadeState: _showStats
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
      ],
    );
  }

  Widget _buildAvgStat(bool isDark, String label, double value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toStringAsFixed(1),
            style: _T.number(isDark, size: 22, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: isDark ? _C.darkMuted : _C.lightMuted,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // FORM CARD
  // =====================================================================

  Widget _buildFormCard(bool isDark, FitnessProvider provider) {
    final hasToday = provider.getTodayWellbeing() != null;

    return Container(
      padding: const EdgeInsets.all(_Sp.lg),
      decoration: BoxDecoration(
        color: isDark ? _C.darkSurface : _C.lightSurface,
        borderRadius: BorderRadius.circular(_R.md),
        border: Border.all(color: isDark ? _C.darkBorder : _C.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                hasToday ? 'ОБНОВИТЬ' : 'НОВАЯ ЗАПИСЬ',
                style: _T.overline(isDark),
              ),
            ],
          ),
          const SizedBox(height: _Sp.lg),

          _buildSlider(isDark, 'Энергия', _energy, (v) => setState(() => _energy = v)),
          const SizedBox(height: _Sp.lg),
          _buildSlider(isDark, 'Сон', _sleep, (v) => setState(() => _sleep = v)),
          const SizedBox(height: _Sp.lg),
          _buildSlider(isDark, 'Мотивация', _motivation, (v) => setState(() => _motivation = v)),

          const SizedBox(height: _Sp.xxl),
          _buildPainSelector(isDark),
          const SizedBox(height: _Sp.xxl),
          _buildNotesField(isDark),
          const SizedBox(height: _Sp.xl),
          _buildSubmitButton(isDark, provider, hasToday),
        ],
      ),
    );
  }

  // =====================================================================
  // SLIDER
  // =====================================================================

  Widget _buildSlider(
      bool isDark,
      String label,
      int value,
      ValueChanged<int> onChanged,
      ) {
    final color = _colorForValue(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: _T.section(isDark)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '$value',
                style: _T.number(isDark, size: 14, weight: FontWeight.w600)
                    .copyWith(color: color),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 68,
              child: Text(
                _moodLabels[value.clamp(1, 10) - 1].toLowerCase(),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isDark ? _C.darkSubtle : _C.lightSubtle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
              pressedElevation: 0,
              elevation: 0,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            overlayColor: color.withOpacity(0.10),
            thumbColor: color,
            activeTrackColor: color,
            inactiveTrackColor: isDark ? _C.darkBorder : _C.lightBorder,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$value',
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
      ],
    );
  }

  Color _colorForValue(int value) {
    if (value <= 3) return _C.low;
    if (value <= 6) return _C.mid;
    return _C.high;
  }

  String _getEmojiForValue(int value) {
    return _moodEmojis[value.clamp(1, 10) - 1];
  }

  // =====================================================================
  // PAIN SELECTOR
  // =====================================================================

  Widget _buildPainSelector(bool isDark) {
    final options = [
      'Спина', 'Плечи', 'Колени', 'Шея',
      'Голова', 'Ноги', 'Руки', 'Нет болей',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('БОЛЕВЫЕ ТОЧКИ', style: _T.overline(isDark)),
            const Spacer(),
            if (_painAreas.isNotEmpty)
              _Pressable(
                onTap: () => setState(() => _painAreas.clear()),
                child: Text(
                  'Очистить',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? _C.accentDark : _C.accent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: _Sp.md),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((area) {
            final isSelected = _painAreas.contains(area);
            final isNoPain = area == 'Нет болей';
            final accent = isNoPain
                ? _C.high
                : (isSelected ? _C.low : null);

            return _Pressable(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _painAreas.remove(area);
                  } else {
                    if (isNoPain) {
                      _painAreas
                        ..clear()
                        ..add(area);
                    } else {
                      _painAreas
                        ..remove('Нет болей')
                        ..add(area);
                    }
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (accent!.withOpacity(0.10))
                      : (isDark ? _C.darkSurface2 : _C.lightSurface2),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isSelected
                        ? accent!.withOpacity(0.45)
                        : (isDark ? _C.darkBorder : _C.lightBorder),
                  ),
                ),
                child: Text(
                  area,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? accent!
                        : (isDark ? _C.darkText : _C.lightText),
                  ),
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
        Text('ЗАМЕТКИ', style: _T.overline(isDark)),
        const SizedBox(height: _Sp.md),
        TextField(
          maxLines: 3,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.4,
            color: isDark ? _C.darkText : _C.lightText,
          ),
          decoration: InputDecoration(
            hintText: 'Как вы себя чувствуете?',
            hintStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? _C.darkSubtle : _C.lightSubtle,
            ),
            filled: true,
            fillColor: isDark ? _C.darkSurface2 : _C.lightSurface2,
            contentPadding: const EdgeInsets.all(_Sp.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_R.sm),
              borderSide: BorderSide(
                color: isDark ? _C.darkBorder : _C.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_R.sm),
              borderSide: BorderSide(
                color: isDark ? _C.darkBorder : _C.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_R.sm),
              borderSide: BorderSide(
                color: isDark ? _C.accentDark : _C.accent,
                width: 1.2,
              ),
            ),
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
      bool hasToday,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: _isSubmitting
            ? null
            : () async {
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
              hasToday
                  ? 'Самочувствие обновлено'
                  : 'Самочувствие записано',
              success: true,
            );
            setState(() {
              _notes = null;
              _painAreas.clear();
              _energy = 7;
              _sleep = 7;
              _motivation = 7;
            });
          } catch (e) {
            if (!mounted) return;
            _showSnack('Ошибка: $e');
          } finally {
            if (mounted) setState(() => _isSubmitting = false);
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? _C.accentDark : _C.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
          (isDark ? _C.accentDark : _C.accent).withOpacity(0.5),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_R.sm),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          hasToday ? 'Обновить' : 'Сохранить',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // HISTORY
  // =====================================================================

  Widget _buildHistorySection(
      bool isDark,
      List<WellbeingNote> notes,
      FitnessProvider provider,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('ИСТОРИЯ', style: _T.overline(isDark)),
            const Spacer(),
            Text(
              '${notes.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? _C.darkSubtle : _C.lightSubtle,
              ),
            ),
          ],
        ),
        const SizedBox(height: _Sp.md),
        ...notes.take(10).map((note) => _buildHistoryRow(isDark, note, provider)),
      ],
    );
  }

  Widget _buildHistoryRow(
      bool isDark,
      WellbeingNote note,
      FitnessProvider provider,
      ) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        HapticFeedback.mediumImpact();
        await provider.deleteWellbeingNote(note.id);
        if (!mounted) return;
        _showSnack('Запись удалена');
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: _Sp.sm),
        padding: const EdgeInsets.only(right: _Sp.xl),
        decoration: BoxDecoration(
          color: _C.low,
          borderRadius: BorderRadius.circular(_R.sm),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: _Sp.sm),
        padding: const EdgeInsets.all(_Sp.md),
        decoration: BoxDecoration(
          color: isDark ? _C.darkSurface : _C.lightSurface,
          borderRadius: BorderRadius.circular(_R.sm),
          border: Border.all(color: isDark ? _C.darkBorder : _C.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _formatDate(note.date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? _C.darkText : _C.lightText,
                  ),
                ),
                const Spacer(),
                _buildMiniMetric(isDark, note.energyLevel),
                const SizedBox(width: 4),
                _buildMiniMetric(isDark, note.sleepQuality),
                const SizedBox(width: 4),
                _buildMiniMetric(isDark, note.motivationLevel),
              ],
            ),
            if (note.painAreas.isNotEmpty &&
                !note.painAreas.contains('Нет болей')) ...[
              const SizedBox(height: 6),
              Text(
                note.painAreas.join(' · '),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: _C.low,
                ),
              ),
            ],
            if (note.notes != null && note.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note.notes!,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                  color: isDark ? _C.darkMuted : _C.lightMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(bool isDark, int value) {
    final color = _colorForValue(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: color,
        ),
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
        padding: const EdgeInsets.fromLTRB(
          _Sp.xl, _Sp.md, _Sp.xl, _Sp.xxl,
        ),
        decoration: BoxDecoration(
          color: isDark ? _C.darkSurface : _C.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(_R.lg),
          ),
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
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? _C.darkBorder : _C.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: _Sp.xl),
              Text('О САМОЧУВСТВИИ', style: _T.overline(isDark)),
              const SizedBox(height: 4),
              Text('Как это работает', style: _T.title(isDark)),
              const SizedBox(height: _Sp.xl),
              _buildInfoRow(isDark, 'Энергия', 'Уровень бодрости и активности'),
              _buildInfoRow(isDark, 'Сон', 'Качество и продолжительность сна'),
              _buildInfoRow(isDark, 'Мотивация', 'Желание тренироваться'),
              _buildInfoRow(isDark, 'Болевые точки', 'Отметьте зоны дискомфорта'),
              _buildInfoRow(isDark, 'Заметки', 'Детали и наблюдения'),
              const SizedBox(height: _Sp.xl),
              Container(
                padding: const EdgeInsets.all(_Sp.md),
                decoration: BoxDecoration(
                  color: isDark ? _C.darkSurface2 : _C.lightSurface2,
                  borderRadius: BorderRadius.circular(_R.sm),
                ),
                child: Text(
                  'Записывайте самочувствие ежедневно, чтобы отслеживать прогресс и вовремя замечать изменения.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: isDark ? _C.darkMuted : _C.lightMuted,
                  ),
                ),
              ),
              const SizedBox(height: _Sp.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? _C.accentDark : _C.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_R.sm),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Понятно',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildInfoRow(bool isDark, String label, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _Sp.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? _C.darkSubtle : _C.lightSubtle,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? _C.darkText : _C.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark ? _C.darkMuted : _C.lightMuted,
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

  void _showSnack(String text, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (success) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              const SizedBox(width: _Sp.sm),
            ],
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: success ? _C.high : _C.low,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_R.sm),
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
    final avgEnergy =
        wellbeingNotes.map((n) => n.energyLevel).reduce((a, b) => a + b) / total;
    final avgSleep =
        wellbeingNotes.map((n) => n.sleepQuality).reduce((a, b) => a + b) / total;
    final avgMotivation =
        wellbeingNotes.map((n) => n.motivationLevel).reduce((a, b) => a + b) / total;

    return {
      'avgEnergy': double.parse(avgEnergy.toStringAsFixed(1)),
      'avgSleep': double.parse(avgSleep.toStringAsFixed(1)),
      'avgMotivation': double.parse(avgMotivation.toStringAsFixed(1)),
      'total': total,
    };
  }
}