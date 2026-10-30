// features/fitness/ui/screens/fitness_target_details_screen.dart
// 🆕 v16: добавлены хинты для boxingRounds и holdTime
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
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

class FitnessTargetDetailsScreen extends StatefulWidget {
  final FitnessTarget target;
  final bool isDark;

  const FitnessTargetDetailsScreen({
    super.key,
    required this.target,
    required this.isDark,
  });

  @override
  State<FitnessTargetDetailsScreen> createState() =>
      _FitnessTargetDetailsScreenState();
}

class _FitnessTargetDetailsScreenState
    extends State<FitnessTargetDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = context.watch<FitnessProvider>();

    final target = provider.targets.firstWhere(
          (t) => t.id == widget.target.id,
      orElse: () => widget.target,
    );

    final entries = provider.getTargetEntries(target.id);
    final forecast = provider.calculateForecast(target);

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(isDark, target, provider),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.type.displayName.toUpperCase(),
                    style: const TextStyle(
                      color: _Power.volt,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    target.name,
                    style: TextStyle(
                      color: _Power.textPrimary(isDark),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _buildHeroCard(isDark, target),
          ),
          SliverToBoxAdapter(
            child: _buildForecastCard(isDark, target, forecast),
          ),
          SliverToBoxAdapter(
            child: _buildChartCard(isDark, target, entries),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
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
                      color: _Power.textPrimary(isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _Power.volt.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entries.length}',
                      style: const TextStyle(
                        color: _Power.volt,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (entries.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyHistory(isDark))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final entry = entries[index];
                  final prev = index < entries.length - 1
                      ? entries[index + 1]
                      : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildEntryCard(isDark, entry, prev, target),
                  );
                },
                childCount: entries.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: target.status == FitnessTargetStatus.active
          ? Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow:
            _Power.glow(target.accentColor, strength: 0.4, blur: 20),
          ),
          child: FloatingActionButton.extended(
            backgroundColor: target.accentColor,
            foregroundColor: Colors.white,
            elevation: 0,
            onPressed: () =>
                _showAddEntrySheet(context, target, provider),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'ЗАПИСАТЬ',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontSize: 12,
              ),
            ),
          ),
        ),
      )
          : null,
    );
  }

  // =====================================================================
  // APP BAR (без изменений)
  // =====================================================================

  Widget _buildSliverAppBar(
      bool isDark,
      FitnessTarget target,
      FitnessProvider provider,
      ) {
    return SliverAppBar(
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
        target.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: _Power.textPrimary(isDark),
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.more_horiz_rounded,
                color: _Power.textPrimary(isDark),
                size: 20,
              ),
            ),
            color: _Power.card(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) => _handleMenuAction(value, target, provider),
            itemBuilder: (ctx) => [
              if (target.status == FitnessTargetStatus.active)
                _buildMenuItem(
                  isDark,
                  value: 'edit_value',
                  icon: Icons.edit_rounded,
                  color: target.accentColor,
                  label: 'Изменить значение',
                ),
              if (target.status == FitnessTargetStatus.active)
                _buildMenuItem(
                  isDark,
                  value: 'complete',
                  icon: Icons.emoji_events_rounded,
                  color: _Power.green,
                  label: 'Отметить достигнутой',
                ),
              if (target.status == FitnessTargetStatus.active)
                _buildMenuItem(
                  isDark,
                  value: 'pause',
                  icon: Icons.pause_circle_outline_rounded,
                  color: _Power.plasma,
                  label: 'Приостановить',
                ),
              if (target.status == FitnessTargetStatus.paused)
                _buildMenuItem(
                  isDark,
                  value: 'resume',
                  icon: Icons.play_circle_outline_rounded,
                  color: _Power.green,
                  label: 'Возобновить',
                ),
              _buildMenuItem(
                isDark,
                value: 'delete',
                icon: Icons.delete_outline_rounded,
                color: _Power.red,
                label: 'Удалить',
                destructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      bool isDark, {
        required String value,
        required IconData icon,
        required Color color,
        required String label,
        bool destructive = false,
      }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: destructive
                  ? _Power.red
                  : _Power.textPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // MENU ACTIONS (без изменений)
  // =====================================================================

  void _handleMenuAction(
      String action,
      FitnessTarget target,
      FitnessProvider provider,
      ) async {
    switch (action) {
      case 'edit_value':
        HapticFeedback.selectionClick();
        _editCurrentValue(context, target, provider);
        break;
      case 'complete':
        HapticFeedback.mediumImpact();
        await provider.completeTarget(target.id);
        break;
      case 'pause':
        HapticFeedback.selectionClick();
        await provider.pauseTarget(target.id);
        break;
      case 'resume':
        HapticFeedback.selectionClick();
        await provider.resumeTarget(target.id);
        break;
      case 'delete':
        _confirmDeleteTarget(target, provider);
        break;
    }
  }

  void _confirmDeleteTarget(
      FitnessTarget target,
      FitnessProvider provider,
      ) {
    final isDark = widget.isDark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? _Power.darkCard2 : Colors.white,
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
                      'Удалить цель?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '«${target.name}» и вся история будут удалены',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _Power.textSecondary(isDark),
                        height: 1.4,
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
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: const Text(
                          'Отмена',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
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
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await provider.deleteTarget(target.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: const Text(
                          'Удалить',
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
  }

  // =====================================================================
  // HERO CARD (без изменений)
  // =====================================================================

  Widget _buildHeroCard(bool isDark, FitnessTarget target) {
    final progress = target.progressPercent;
    final improvement = target.lastImprovement;
    final bool isImprovement = target.isAscending
        ? improvement > 0
        : improvement < 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            target.accentColor,
            target.accentColor.withOpacity(0.75),
            _Power.heroDeep,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: target.accentColor.withOpacity(0.35),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white,
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            target.type.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            target.type.displayName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (target.deadline != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: target.isOverdue
                                  ? const Color(0xFFFFD0D0)
                                  : Colors.white.withOpacity(0.9),
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDeadline(target.deadline!),
                              style: TextStyle(
                                color: target.isOverdue
                                    ? const Color(0xFFFFD0D0)
                                    : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        target.formattedCurrent,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        target.unit,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (improvement != 0 && target.entries.length >= 2)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isImprovement
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${improvement > 0 ? '+' : ''}${improvement.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        target.isAscending
                            ? 'из ${target.formattedTarget} ${target.unit}'
                            : 'до ${target.formattedTarget} ${target.unit}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (target.startValue > 0 &&
                        target.startValue != target.currentValue)
                      Text(
                        'СТАРТ ${_fmt(target.startValue)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${(progress * 100).toInt()}% ВЫПОЛНЕНО',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ОСТАЛОСЬ ${target.formattedRemaining} ${target.unit}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    return v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);
  }

  // =====================================================================
  // FORECAST CARD (без изменений)
  // =====================================================================

  Widget _buildForecastCard(
      bool isDark,
      FitnessTarget target,
      Map<String, dynamic> forecast,
      ) {
    final isRealistic = forecast['isRealistic'] as bool? ?? false;
    final days = forecast['days'] as int?;
    final date = forecast['date'] as DateTime?;
    final speed = (forecast['speed'] as double?) ?? 0;
    final reason = forecast['reason'] as String? ?? '';
    final trendDays = forecast['trendDays'] as int? ?? 0;

    Color accent;
    IconData icon;
    String title;
    String subtitle;

    if (!isRealistic || days == null) {
      accent = _Power.textTertiary(isDark);
      icon = Icons.analytics_outlined;
      title = 'Прогноз недоступен';
      subtitle = reason.isNotEmpty ? reason : 'Недостаточно данных';
    } else if (days <= 7) {
      accent = _Power.green;
      icon = Icons.bolt_rounded;
      title = 'Совсем скоро!';
      subtitle = 'Осталось $days ${_daysWord(days)}';
    } else if (days <= 30) {
      accent = _Power.ice;
      icon = Icons.trending_up_rounded;
      title = 'Отличный темп';
      subtitle = 'Примерно через $days ${_daysWord(days)}';
    } else if (days <= 180) {
      accent = _Power.plasma;
      icon = Icons.schedule_rounded;
      title = 'Стабильный прогресс';
      subtitle = 'Ориентировочно ${_formatDate(date!)}';
    } else {
      accent = _Power.volt;
      icon = Icons.explore_rounded;
      title = 'Долгий путь';
      subtitle = '~${(days / 30).ceil()} месяцев';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withOpacity(0.25),
          width: 0.8,
        ),
        boxShadow: _Power.softGlow(accent, strength: 0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _Power.softGlow(accent, strength: 0.2),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ПРОГНОЗ',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                        color: _Power.textTertiary(isDark),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        height: 1.1,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _Power.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              if (isRealistic && speed > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${speed.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: accent,
                      height: 1,
                    ),
                  ),
                ),
            ],
          ),
          if (trendDays > 0 && isRealistic) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _Power.card2(isDark),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: _Power.textTertiary(isDark),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ПРОГНОЗ НА ОСНОВЕ $trendDays ${_daysWord(trendDays).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: _Power.textTertiary(isDark),
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

  // =====================================================================
  // CHART CARD (без изменений)
  // =====================================================================

  Widget _buildChartCard(
      bool isDark,
      FitnessTarget target,
      List<FitnessTargetEntry> entries,
      ) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final sorted = List<FitnessTargetEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final values = sorted.map((e) => e.value).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);

    final chartValues = [
      minVal,
      maxVal,
      target.targetValue,
      if (target.startValue > 0) target.startValue,
    ];
    final chartMin = chartValues.reduce((a, b) => a < b ? a : b);
    final chartMax = chartValues.reduce((a, b) => a > b ? a : b);
    final chartRange =
    (chartMax - chartMin).abs() == 0 ? 1.0 : (chartMax - chartMin).abs();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: target.accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  color: target.accentColor,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ДИНАМИКА',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: _Power.textPrimary(isDark),
                ),
              ),
              const Spacer(),
              if (sorted.length >= 2)
                Text(
                  '${sorted.first.date.day}.${sorted.first.date.month} — ${sorted.last.date.day}.${sorted.last.date.month}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: _Power.textTertiary(isDark),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _TargetChartPainter(
                points: sorted
                    .map((e) => (value: e.value, date: e.date))
                    .toList(),
                targetValue: target.targetValue,
                startValue: target.startValue,
                accentColor: target.accentColor,
                isDark: isDark,
                chartMin: chartMin,
                chartRange: chartRange,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 0.5,
            color: _Power.separator(isDark),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildChartStat(
                  isDark,
                  'МИН',
                  minVal.toStringAsFixed(1),
                  _Power.textSecondary(isDark),
                ),
              ),
              Expanded(
                child: _buildChartStat(
                  isDark,
                  'МАКС',
                  maxVal.toStringAsFixed(1),
                  target.accentColor,
                ),
              ),
              Expanded(
                child: _buildChartStat(
                  isDark,
                  'ЦЕЛЬ',
                  target.targetValue.toStringAsFixed(1),
                  _Power.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartStat(
      bool isDark,
      String label,
      String value,
      Color color,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
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
    );
  }

  // =====================================================================
  // ENTRY CARD (без изменений)
  // =====================================================================

  Widget _buildEntryCard(
      bool isDark,
      FitnessTargetEntry entry,
      FitnessTargetEntry? prev,
      FitnessTarget target,
      ) {
    final diff = prev != null ? entry.value - prev.value : 0.0;
    final isImprovement = target.isAscending ? diff > 0 : diff < 0;
    final hasChange = diff != 0 && prev != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: target.accentColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              boxShadow:
              _Power.softGlow(target.accentColor, strength: 0.2),
            ),
            alignment: Alignment.center,
            child: Text(
              _fmt(entry.value),
              style: TextStyle(
                color: target.accentColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(entry.date),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: _Power.textPrimary(isDark),
                        ),
                      ),
                    ),
                    if (hasChange)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (isImprovement
                              ? _Power.green
                              : _Power.red)
                              .withOpacity(0.14),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isImprovement
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 11,
                              color: isImprovement
                                  ? _Power.green
                                  : _Power.red,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                height: 1,
                                color: isImprovement
                                    ? _Power.green
                                    : _Power.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    entry.note!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _Power.textSecondary(isDark),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (entry.bodyWeight != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.monitor_weight_rounded,
                        size: 10,
                        color: _Power.textTertiary(isDark),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'ВЕС ${entry.bodyWeight!.toStringAsFixed(1)} КГ',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: _Power.textTertiary(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _confirmDeleteEntry(entry, target);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _Power.red.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: _Power.red,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteEntry(
      FitnessTargetEntry entry,
      FitnessTarget target,
      ) async {
    final isDark = widget.isDark;
    final provider = context.read<FitnessProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? _Power.darkCard2 : Colors.white,
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
                      'Удалить запись?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Запись за ${_formatDate(entry.date)} будет удалена',
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
                          'Отмена',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
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
                          'Удалить',
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
    if (confirm == true) {
      await provider.removeTargetEntry(target.id, entry.date);
    }
  }

  // =====================================================================
  // EDIT CURRENT VALUE (без изменений)
  // =====================================================================

  void _editCurrentValue(
      BuildContext context,
      FitnessTarget target,
      FitnessProvider provider,
      ) {
    final isDark = widget.isDark;
    final controller = TextEditingController(
      text: target.currentValue.toStringAsFixed(1),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: _Power.card(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
              'РУЧНАЯ КОРРЕКТИРОВКА',
              style: TextStyle(
                color: _Power.volt,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Текущее значение',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
                color: _Power.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: _Power.textPrimary(isDark),
              ),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: TextStyle(
                  color: _Power.textTertiary(isDark),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
                suffixText: target.unit,
                suffixStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _Power.textSecondary(isDark),
                ),
                filled: true,
                fillColor: _Power.card2(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                        foregroundColor: _Power.textSecondary(isDark),
                        side: BorderSide(color: _Power.separator(isDark)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Отмена',
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
                      onPressed: () async {
                        final value = double.tryParse(controller.text) ??
                            target.currentValue;
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                        await provider.addTargetEntry(
                          target.id,
                          value,
                          note: 'Ручная корректировка',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: target.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor:
                        target.accentColor.withOpacity(0.5),
                      ),
                      child: const Text(
                        'СОХРАНИТЬ',
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
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // EMPTY HISTORY (без изменений)
  // =====================================================================

  Widget _buildEmptyHistory(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: _Power.volt.withOpacity(0.10),
              shape: BoxShape.circle,
              boxShadow: _Power.softGlow(_Power.volt, strength: 0.15),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 28,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ИСТОРИЯ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Пока пусто',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: _Power.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте первую запись, чтобы отслеживать прогресс',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: _Power.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // ADD ENTRY SHEET (без изменений)
  // =====================================================================

  void _showAddEntrySheet(
      BuildContext context,
      FitnessTarget target,
      FitnessProvider provider,
      ) {
    final isDark = widget.isDark;
    final controller = TextEditingController(
      text: target.currentValue.toStringAsFixed(1),
    );
    final noteController = TextEditingController();
    final hintText = _getHintForType(target);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
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
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: target.accentColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _Power.softGlow(
                          target.accentColor,
                          strength: 0.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        target.type.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'НОВАЯ ЗАПИСЬ',
                            style: TextStyle(
                              color: _Power.volt,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            target.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: _Power.textPrimary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'ТЕКУЩИЙ РЕЗУЛЬТАТ (${target.unit.toUpperCase()})',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      color: _Power.textTertiary(isDark),
                    ),
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                    color: _Power.textPrimary(isDark),
                  ),
                  decoration: InputDecoration(
                    hintText: '0.0',
                    hintStyle: TextStyle(
                      color: _Power.textTertiary(isDark),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                    suffixText: target.unit,
                    suffixStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _Power.textSecondary(isDark),
                    ),
                    filled: true,
                    fillColor: _Power.card2(isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'ЗАМЕТКА (ОПЦИОНАЛЬНО)',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      color: _Power.textTertiary(isDark),
                    ),
                  ),
                ),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _Power.textPrimary(isDark),
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: _Power.textTertiary(isDark),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: _Power.card2(isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      final value = double.tryParse(controller.text);
                      if (value == null || value < 0) {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                            const Text('Введите корректное значение'),
                            backgroundColor: _Power.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        );
                        return;
                      }
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      provider.addTargetEntry(
                        target.id,
                        value,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Запись добавлена: $value ${target.unit}',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: target.accentColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: target.accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      shadowColor: target.accentColor.withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'СОХРАНИТЬ',
                          style: TextStyle(
                            fontSize: 14,
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
      ),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  /// 🆕 Хинты для новых типов boxingRounds и holdTime.
  String _getHintForType(FitnessTarget target) {
    switch (target.type) {
      case FitnessTargetType.strengthMax:
        return 'Например: «удалось пожать 90, осталось 10 кг»';
      case FitnessTargetType.strengthReps:
        return 'Например: «сделал 8 повторов с 60 кг»';
      case FitnessTargetType.bodyweightReps:
        return 'Например: «подтянулся 7 раз без раскачки»';
      case FitnessTargetType.cardioDistance:
        return 'Например: «пробежал 3 км в парке»';
      case FitnessTargetType.cardioTime:
        return 'Например: «5 км за 28 минут»';
      case FitnessTargetType.endurance:
        return 'Например: «планка 90 секунд»';
      case FitnessTargetType.bodyMeasurement:
        return 'Например: «замер утром после душа»';
      case FitnessTargetType.bodyWeight:
        return 'Например: «взвесился утром натощак»';
      case FitnessTargetType.volume:
        return 'Например: «тяжёлая тренировка»';
      case FitnessTargetType.custom:
        return 'Любая заметка о прогрессе…';
      case FitnessTargetType.boxingRounds:
        return 'Например: «12 раундов на груше, 3 минуты каждый»';
      case FitnessTargetType.holdTime:
        return 'Например: «планка 2 минуты 30 секунд»';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDeadline(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return 'ПРОСРОЧЕНО';
    if (days == 0) return 'СЕГОДНЯ';
    if (days == 1) return 'ЗАВТРА';
    if (days <= 7) return '$days ДН.';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}';
  }

  String _daysWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return 'дня';
    }
    return 'дней';
  }
}

// ==================== CUSTOM PAINTER (без изменений) ====================

class _TargetChartPainter extends CustomPainter {
  final List<({double value, DateTime date})> points;
  final double targetValue;
  final double startValue;
  final Color accentColor;
  final bool isDark;
  final double chartMin;
  final double chartRange;

  _TargetChartPainter({
    required this.points,
    required this.targetValue,
    required this.startValue,
    required this.accentColor,
    required this.isDark,
    required this.chartMin,
    required this.chartRange,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final linePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withOpacity(0.32),
          accentColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final targetPaint = Paint()
      ..color = const Color(0xFF00C853).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final startPaint = Paint()
      ..color = const Color(0xFFFF9500).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final pointPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final pointBorder = Paint()
      ..color = isDark ? const Color(0xFF1C1C1E) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    _drawDashedLine(
      canvas,
      size,
      targetValue,
      targetPaint,
      dashWidth: 6.0,
      dashSpace: 4.0,
    );

    if (startValue > 0 && (startValue - targetValue).abs() > 0.01) {
      _drawDashedLine(
        canvas,
        size,
        startValue,
        startPaint,
        dashWidth: 3.0,
        dashSpace: 3.0,
      );
    }

    final path = Path();
    final fillPath = Path();
    final coords = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final px = points.length == 1
          ? size.width / 2
          : (i / (points.length - 1)) * size.width;
      final normalized =
      ((points[i].value - chartMin) / chartRange).clamp(0.0, 1.0);
      final py = size.height - normalized * size.height;
      final point = Offset(px, py);
      coords.add(point);

      if (i == 0) {
        path.moveTo(px, py);
        fillPath.moveTo(px, size.height);
        fillPath.lineTo(px, py);
      } else {
        path.lineTo(px, py);
        fillPath.lineTo(px, py);
      }
    }

    if (coords.isNotEmpty) {
      fillPath.lineTo(coords.last.dx, size.height);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);

      if (coords.length > 1) {
        canvas.drawPath(path, linePaint);
      }

      for (final c in coords) {
        canvas.drawCircle(c, 6, pointBorder);
        canvas.drawCircle(c, 4, pointPaint);
      }
    }
  }

  void _drawDashedLine(
      Canvas canvas,
      Size size,
      double value,
      Paint paint, {
        required double dashWidth,
        required double dashSpace,
      }) {
    final y = size.height -
        ((value - chartMin) / chartRange).clamp(0.0, 1.0) * size.height;
    final clampedY = y.clamp(0.0, size.height);
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, clampedY),
        Offset((x + dashWidth).clamp(0.0, size.width), clampedY),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TargetChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.targetValue != targetValue ||
        oldDelegate.chartMin != chartMin ||
        oldDelegate.chartRange != chartRange;
  }
}