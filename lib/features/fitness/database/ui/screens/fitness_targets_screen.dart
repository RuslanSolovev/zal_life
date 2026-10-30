// features/fitness/ui/screens/fitness_targets_screen.dart
// 🆕 v16: добавлены типы целей boxingRounds и holdTime
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../providers/fitness_provider.dart';
import 'fitness_target_details_screen.dart';

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

class FitnessTargetsScreen extends StatefulWidget {
  final bool isDark;
  const FitnessTargetsScreen({super.key, required this.isDark});

  @override
  State<FitnessTargetsScreen> createState() => _FitnessTargetsScreenState();
}

class _FitnessTargetsScreenState extends State<FitnessTargetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = context.watch<FitnessProvider>();

    final active = provider.targets
        .where((t) => t.status == FitnessTargetStatus.active)
        .toList();
    final completed = provider.targets
        .where((t) => t.status == FitnessTargetStatus.completed)
        .toList();
    final other = provider.targets
        .where((t) =>
    t.status == FitnessTargetStatus.paused ||
        t.status == FitnessTargetStatus.abandoned)
        .toList();

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
              'Цели',
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
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _showCreateTargetSheet(context, isDark, provider);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _Power.volt,
                      shape: BoxShape.circle,
                      boxShadow: _Power.softGlow(_Power.volt, strength: 0.5),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'МОИ ЦЕЛИ',
                    style: TextStyle(
                      color: _Power.volt,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Цели',
                    style: TextStyle(
                      color: _Power.textPrimary(isDark),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.targets.length} ${_plural(provider.targets.length, "цель", "цели", "целей")}',
                    style: TextStyle(
                      color: _Power.textSecondary(isDark),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _Power.card2(isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: _Power.textSecondary(isDark),
                  indicator: BoxDecoration(
                    color: _Power.volt,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow:
                    _Power.softGlow(_Power.volt, strength: 0.35),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                  tabs: [
                    Tab(text: 'АКТИВНЫЕ ${active.length}'),
                    Tab(text: 'ГОТОВО ${completed.length}'),
                    Tab(text: 'АРХИВ ${other.length}'),
                  ],
                ),
              ),
            ),
          ),

          SliverFillRemaining(
            hasScrollBody: true,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTargetsList(
                  isDark,
                  active,
                  provider,
                  emptyMessage: 'НЕТ АКТИВНЫХ',
                  emptyHint: 'Поставьте первую цель',
                ),
                _buildTargetsList(
                  isDark,
                  completed,
                  provider,
                  emptyMessage: 'НИЧЕГО НЕ ДОСТИГНУТО',
                  emptyHint: 'Продолжайте тренироваться',
                ),
                _buildTargetsList(
                  isDark,
                  other,
                  provider,
                  emptyMessage: 'АРХИВ ПУСТ',
                  emptyHint: 'Приостановленные цели появятся здесь',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // TARGETS LIST
  // =====================================================================

  Widget _buildTargetsList(
      bool isDark,
      List<FitnessTarget> targets,
      FitnessProvider provider, {
        required String emptyMessage,
        required String emptyHint,
      }) {
    if (targets.isEmpty) {
      return _buildEmptyState(isDark, emptyMessage, emptyHint);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      itemCount: targets.length,
      itemBuilder: (context, index) {
        return _buildTargetCard(isDark, targets[index], provider);
      },
    );
  }

  Widget _buildEmptyState(
      bool isDark,
      String title,
      String hint,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _Power.volt.withOpacity(0.10),
              shape: BoxShape.circle,
              boxShadow: _Power.softGlow(_Power.volt, strength: 0.15),
            ),
            child: const Icon(
              Icons.flag_rounded,
              size: 40,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'ЦЕЛИ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: _Power.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: _Power.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // TARGET CARD (без изменений)
  // =====================================================================

  Widget _buildTargetCard(
      bool isDark,
      FitnessTarget target,
      FitnessProvider provider,
      ) {
    final progress = target.progressPercent;
    final isCompleted = target.status == FitnessTargetStatus.completed;
    final isPaused = target.status == FitnessTargetStatus.paused;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: FitnessTargetDetailsScreen(
                target: target,
                isDark: isDark,
              ),
            ),
          ),
        );
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showTargetOptions(context, target, provider);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isCompleted
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _Power.green.withOpacity(0.15),
              _Power.green.withOpacity(0.04),
            ],
          )
              : isPaused
              ? null
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              target.accentColor.withOpacity(0.12),
              target.accentColor.withOpacity(0.03),
            ],
          ),
          color: isPaused
              ? _Power.card2(isDark)
              : (isCompleted ? null : _Power.card(isDark)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? _Power.green.withOpacity(0.3)
                : isPaused
                ? _Power.separator(isDark)
                : target.accentColor.withOpacity(0.3),
            width: 0.8,
          ),
          boxShadow: isCompleted
              ? _Power.softGlow(_Power.green, strength: 0.12)
              : isPaused
              ? null
              : _Power.softGlow(target.accentColor, strength: 0.08),
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
                    color: isCompleted
                        ? _Power.green.withOpacity(0.16)
                        : isPaused
                        ? _Power.textTertiary(isDark).withOpacity(0.15)
                        : target.accentColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: isCompleted
                        ? _Power.softGlow(_Power.green, strength: 0.25)
                        : isPaused
                        ? null
                        : _Power.softGlow(target.accentColor,
                        strength: 0.2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    target.type.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          height: 1.15,
                          color: _Power.textPrimary(isDark),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (target.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          target.description,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _Power.textSecondary(isDark),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _Power.green,
                      shape: BoxShape.circle,
                      boxShadow:
                      _Power.softGlow(_Power.green, strength: 0.5),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                else if (target.deadline != null)
                  _buildDeadlineChip(isDark, target),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    target.formattedCurrent,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.4,
                      height: 1,
                      color: isCompleted
                          ? _Power.green
                          : isPaused
                          ? _Power.textSecondary(isDark)
                          : target.accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    target.unit,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: _Power.textSecondary(isDark),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'ИЗ ${target.formattedTarget}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: _Power.textTertiary(isDark),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: _Power.separator(isDark),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted
                      ? _Power.green
                      : isPaused
                      ? _Power.textTertiary(isDark)
                      : target.accentColor,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${(progress * 100).toInt()}% ВЫПОЛНЕНО',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: isCompleted
                        ? _Power.green
                        : _Power.textSecondary(isDark),
                  ),
                ),
                const Spacer(),
                Text(
                  'ОСТАЛОСЬ ${target.formattedRemaining}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: _Power.textTertiary(isDark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineChip(bool isDark, FitnessTarget target) {
    final days = target.daysUntilDeadline ?? 0;
    final isOverdue = target.isOverdue;
    final accent = isOverdue ? _Power.red : _Power.plasma;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
            size: 11,
            color: accent,
          ),
          const SizedBox(width: 4),
          Text(
            isOverdue ? 'ПРОСРОЧЕНО' : '$days ДН.',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              height: 1,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // CREATE TARGET SHEET
  // =====================================================================

  void _showCreateTargetSheet(
      BuildContext context,
      bool isDark,
      FitnessProvider provider,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: _Power.bg(isDark),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: _TargetBuilderSheet(isDark: isDark, provider: provider),
        ),
      ),
    );
  }

  // =====================================================================
  // TARGET OPTIONS (без изменений)
  // =====================================================================

  void _showTargetOptions(
      BuildContext context,
      FitnessTarget target,
      FitnessProvider provider,
      ) {
    final isDark = widget.isDark;
    final isActive = target.status == FitnessTargetStatus.active;
    final isPaused = target.status == FitnessTargetStatus.paused;
    final isCompleted = target.status == FitnessTargetStatus.completed;

    showModalBottomSheet(
      context: context,
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
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: target.accentColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: _Power.softGlow(target.accentColor,
                          strength: 0.25),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      target.type.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                          '${target.formattedCurrent} / ${target.formattedTarget} ${target.unit}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: target.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _buildMenuItem(
                isDark,
                icon: Icons.analytics_rounded,
                iconColor: target.accentColor,
                title: 'Открыть детали',
                subtitle: 'График, история, прогноз',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: FitnessTargetDetailsScreen(
                          target: target,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (isActive)
                _buildMenuItem(
                  isDark,
                  icon: Icons.emoji_events_rounded,
                  iconColor: _Power.green,
                  title: 'Отметить достигнутой',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(ctx);
                    provider.completeTarget(target.id);
                  },
                ),
              if (isActive)
                _buildMenuItem(
                  isDark,
                  icon: Icons.pause_circle_outline_rounded,
                  iconColor: _Power.plasma,
                  title: 'Приостановить',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx);
                    provider.pauseTarget(target.id);
                  },
                ),
              if (isPaused)
                _buildMenuItem(
                  isDark,
                  icon: Icons.play_circle_outline_rounded,
                  iconColor: _Power.green,
                  title: 'Возобновить',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx);
                    provider.resumeTarget(target.id);
                  },
                ),
              if (!isCompleted)
                _buildMenuItem(
                  isDark,
                  icon: Icons.delete_outline_rounded,
                  iconColor: _Power.red,
                  title: 'Удалить',
                  destructive: true,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(ctx);
                    _confirmDeleteTarget(context, target, provider);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTarget(
      BuildContext context,
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
                      '«${target.name}» будет удалена',
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
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx, true);
                        provider.deleteTarget(target.id);
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

  Widget _buildMenuItem(
      bool isDark, {
        required IconData icon,
        required Color iconColor,
        required String title,
        String? subtitle,
        bool destructive = false,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _Power.card2(isDark),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: destructive
                          ? _Power.red
                          : _Power.textPrimary(isDark),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _Power.textSecondary(isDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _Power.textTertiary(isDark),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  String _plural(int n, String one, String few, String many) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return one;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
    return many;
  }
}

// ══════════════════════════════════════════════════════════════════════
// 🆕 TARGET BUILDER SHEET — использует геттеры requiresExercise/Measurement
// ══════════════════════════════════════════════════════════════════════

class _TargetBuilderSheet extends StatefulWidget {
  final bool isDark;
  final FitnessProvider provider;
  const _TargetBuilderSheet({required this.isDark, required this.provider});

  @override
  State<_TargetBuilderSheet> createState() => _TargetBuilderSheetState();
}

class _TargetBuilderSheetState extends State<_TargetBuilderSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  final _repsController = TextEditingController(text: '10');

  FitnessTargetType _type = FitnessTargetType.strengthMax;
  Exercise? _selectedExercise;
  DateTime? _deadline;
  Color _selectedColor = _Power.volt;
  String? _measurement;

  static const _colors = [
    _Power.volt,
    _Power.green,
    _Power.ice,
    _Power.magma,
    _Power.plasma,
    _Power.lime,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _valueController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = widget.provider;
    final templates = provider.getTargetTemplates();
    final showRepsField = _type == FitnessTargetType.strengthReps;
    // 🆕 Используем геттеры из enums.dart вместо хардкода
    final showExercisePicker = _type.requiresExercise;
    final showMeasurementPicker = _type.requiresMeasurement;

    return Column(
      children: [
        Container(
          width: 36,
          height: 5,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: _Power.textTertiary(isDark),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'НОВАЯ ЦЕЛЬ',
                      style: TextStyle(
                        color: _Power.volt,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Создать',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                        height: 1.1,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
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
                    Icons.close_rounded,
                    color: _Power.textPrimary(isDark),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              // Шаблоны (включая новый "100 раундов")
              if (templates.isNotEmpty) ...[
                _buildSectionLabel('ШАБЛОНЫ', isDark),
                const SizedBox(height: 10),
                SizedBox(
                  height: 118,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: templates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                      return _buildTemplateChip(templates[i]);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 🆕 Все типы целей (включая boxingRounds и holdTime)
              _buildSectionLabel('ТИП ЦЕЛИ', isDark),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: FitnessTargetType.values.map((type) {
                  final isSelected = type == _type;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _type = type;
                        // Если новый тип не требует упражнения — сбрасываем
                        if (!type.requiresExercise) _selectedExercise = null;
                        if (!type.requiresMeasurement) _measurement = null;
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
                            ? _selectedColor.withOpacity(0.14)
                            : _Power.card2(isDark),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: isSelected
                              ? _selectedColor
                              : Colors.transparent,
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? _Power.softGlow(_selectedColor,
                            strength: 0.25)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(type.emoji,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.1,
                              color: isSelected
                                  ? _selectedColor
                                  : _Power.textPrimary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              _buildField(
                controller: _nameController,
                label: 'НАЗВАНИЕ',
                hint: _hintName(_type),
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              _buildField(
                controller: _descController,
                label: 'ОПИСАНИЕ',
                hint: 'Опционально',
                isDark: isDark,
                maxLines: 2,
              ),

              // 🆕 Упражнение — для boxingRounds, holdTime, strengthMax и др.
              if (showExercisePicker) ...[
                const SizedBox(height: 20),
                _buildSectionLabel('УПРАЖНЕНИЕ', isDark),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _pickExercise(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _Power.card2(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _Power.separator(isDark),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _selectedColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _selectedExercise?.exerciseType.emoji ??
                                _defaultExerciseEmoji(_type),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedExercise?.name ??
                                    'Выбрать упражнение',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: _selectedExercise != null
                                      ? _Power.textPrimary(isDark)
                                      : _Power.textSecondary(isDark),
                                ),
                              ),
                              if (_selectedExercise != null)
                                Text(
                                  _selectedExercise!.muscleGroups
                                      .map((m) => m.displayName)
                                      .join(' • '),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _Power.textTertiary(isDark),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: _Power.textTertiary(isDark),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (showMeasurementPicker) ...[
                const SizedBox(height: 20),
                _buildSectionLabel('ОБХВАТ', isDark),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ('chest', 'Грудь'),
                    ('waist', 'Талия'),
                    ('hips', 'Бёдра'),
                    ('biceps', 'Бицепс'),
                    ('thigh', 'Бедро'),
                    ('calf', 'Икра'),
                    ('neck', 'Шея'),
                    ('forearm', 'Предплечье'),
                  ].map((m) {
                    final isSelected = _measurement == m.$1;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _measurement = m.$1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withOpacity(0.14)
                              : _Power.card2(isDark),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: isSelected
                                ? _selectedColor
                                : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          m.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                            color: isSelected
                                ? _selectedColor
                                : _Power.textPrimary(isDark),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),

              _buildSectionLabel('ЦЕЛЕВОЕ ЗНАЧЕНИЕ', isDark),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildValueField(
                      controller: _valueController,
                      suffix: _type.defaultUnit,
                      isDark: isDark,
                    ),
                  ),
                  if (showRepsField) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: _buildValueField(
                        controller: _repsController,
                        suffix: 'повт',
                        isDark: isDark,
                        hint: '10',
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              _buildSectionLabel('ДЕДЛАЙН', isDark),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _pickDeadline();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _Power.card2(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _Power.separator(isDark),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: _Power.textTertiary(isDark),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _deadline != null
                                  ? '${_deadline!.day.toString().padLeft(2, '0')}.${_deadline!.month.toString().padLeft(2, '0')}.${_deadline!.year}'
                                  : 'Опционально',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _deadline != null
                                    ? _Power.textPrimary(isDark)
                                    : _Power.textTertiary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_deadline != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _deadline = null);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _Power.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: _Power.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              _buildSectionLabel('АКЦЕНТНЫЙ ЦВЕТ', isDark),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((c) {
                  final isSelected = c.value == _selectedColor.value;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedColor = c);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                          color: _Power.textPrimary(isDark),
                          width: 2.5,
                        )
                            : null,
                        boxShadow: _Power.softGlow(c,
                            strength: isSelected ? 0.5 : 0.25),
                      ),
                      child: isSelected
                          ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _createTarget(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    shadowColor: _selectedColor.withOpacity(0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'СОЗДАТЬ ЦЕЛЬ',
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
      ],
    );
  }

  /// 🆕 Подсказка названия по типу.
  String _hintName(FitnessTargetType type) {
    switch (type) {
      case FitnessTargetType.strengthMax:
        return 'Например: Жим 100 кг';
      case FitnessTargetType.strengthReps:
        return 'Например: Жим 50×50';
      case FitnessTargetType.bodyweightReps:
        return 'Например: 10 подтягиваний';
      case FitnessTargetType.cardioDistance:
        return 'Например: Пробежать 10 км';
      case FitnessTargetType.cardioTime:
        return 'Например: 5 км за 25 мин';
      case FitnessTargetType.endurance:
        return 'Например: Планка 3 мин';
      case FitnessTargetType.bodyMeasurement:
        return 'Например: Бицепс 40 см';
      case FitnessTargetType.bodyWeight:
        return 'Например: Похудеть до 75 кг';
      case FitnessTargetType.volume:
        return 'Например: 10 тонн за тренировку';
      case FitnessTargetType.custom:
        return 'Своя цель';
      case FitnessTargetType.boxingRounds:
        return 'Например: 100 раундов';
      case FitnessTargetType.holdTime:
        return 'Например: Планка 3 минуты';
    }
  }

  /// 🆕 Эмодзи дефолтного упражнения по типу цели.
  String _defaultExerciseEmoji(FitnessTargetType type) {
    switch (type) {
      case FitnessTargetType.boxingRounds:
        return '🥊';
      case FitnessTargetType.holdTime:
        return '🧘';
      case FitnessTargetType.bodyweightReps:
        return '🤸';
      case FitnessTargetType.endurance:
        return '⚡';
      default:
        return '🏋️';
    }
  }

  /// 🆕 Допустимые типы упражнений для цели (для фильтра в picker).
  List<ExerciseType> _allowedExerciseTypes(FitnessTargetType type) {
    switch (type) {
      case FitnessTargetType.boxingRounds:
        return [ExerciseType.boxing];
      case FitnessTargetType.holdTime:
        return [ExerciseType.yoga, ExerciseType.bodyweight];
      case FitnessTargetType.bodyweightReps:
        return [ExerciseType.bodyweight];
      case FitnessTargetType.endurance:
        return [
          ExerciseType.bodyweight,
          ExerciseType.cardio,
          ExerciseType.yoga,
        ];
      case FitnessTargetType.strengthMax:
      case FitnessTargetType.strengthReps:
        return [ExerciseType.strength];
      case FitnessTargetType.cardioDistance:
      case FitnessTargetType.cardioTime:
        return [ExerciseType.cardio];
      default:
        return ExerciseType.values;
    }
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
          color: _Power.textTertiary(isDark),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, isDark),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueField({
    required TextEditingController controller,
    required String suffix,
    required bool isDark,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
        color: _Power.textPrimary(isDark),
      ),
      decoration: InputDecoration(
        hintText: hint ?? '0',
        hintStyle: TextStyle(
          color: _Power.textTertiary(isDark),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        suffixText: suffix,
        suffixStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _Power.textSecondary(isDark),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildTemplateChip(FitnessTarget t) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _nameController.text = t.name;
        _descController.text = t.description;
        _valueController.text = t.targetValue.toString();
        setState(() {
          _type = t.type;
          _selectedColor = _nearestPowerColor(t.accentColor);
          if (t.exerciseId != null) {
            try {
              _selectedExercise = widget.provider.exercises
                  .firstWhere((e) => e.id == t.exerciseId);
            } catch (_) {
              _selectedExercise = null;
            }
          } else {
            _selectedExercise = null;
          }
          if (t.extra.containsKey('measurement')) {
            _measurement = t.extra['measurement'] as String?;
          } else {
            _measurement = null;
          }
          if (t.extra.containsKey('reps')) {
            _repsController.text = (t.extra['reps'] as int).toString();
          } else {
            _repsController.text = '10';
          }
        });
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _Power.card2(widget.isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _Power.separator(widget.isDark),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: t.accentColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                t.type.emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Spacer(),
            Text(
              t.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.2,
                color: _Power.textPrimary(widget.isDark),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${t.formattedTarget} ${t.unit}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                color: t.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _nearestPowerColor(Color original) {
    final hsv = HSVColor.fromColor(original);
    if (hsv.hue >= 20 && hsv.hue < 45) return _Power.volt;
    if (hsv.hue >= 45 && hsv.hue < 90) return _Power.plasma;
    if (hsv.hue >= 90 && hsv.hue < 170) return _Power.lime;
    if (hsv.hue >= 170 && hsv.hue < 220) return _Power.ice;
    if (hsv.hue >= 220 && hsv.hue < 300) return _Power.magma;
    if (hsv.hue >= 300 && hsv.hue < 360) return _Power.magma;
    return _Power.volt;
  }

  /// 🆕 Открывает picker с фильтром по допустимым типам.
  Future<void> _pickExercise(BuildContext context) async {
    final allowedTypes = _allowedExerciseTypes(_type);
    final filtered = widget.provider.exercises
        .where((e) => allowedTypes.contains(e.exerciseType))
        .toList();

    final result = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: _Power.bg(widget.isDark),
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: _ExercisePickerSheet(
          isDark: widget.isDark,
          exercises: filtered.isEmpty
              ? widget.provider.exercises
              : filtered,
        ),
      ),
    );
    if (result != null) setState(() => _selectedExercise = result);
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
      _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date != null) setState(() => _deadline = date);
  }

  void _createTarget(FitnessProvider provider) {
    final name = _nameController.text.trim();
    final value = double.tryParse(_valueController.text) ?? 0;

    if (name.isEmpty) {
      HapticFeedback.mediumImpact();
      _snack('Введите название цели', _Power.red);
      return;
    }
    if (value <= 0) {
      HapticFeedback.mediumImpact();
      _snack('Введите целевое значение', _Power.red);
      return;
    }
    // 🆕 Для requiresExercise типов — обязательный выбор упражнения
    if (_type.requiresExercise && _selectedExercise == null) {
      HapticFeedback.mediumImpact();
      _snack('Выберите упражнение', _Power.red);
      return;
    }
    if (_type.requiresMeasurement && _measurement == null) {
      HapticFeedback.mediumImpact();
      _snack('Выберите обхват', _Power.red);
      return;
    }

    final extra = <String, dynamic>{};
    if (_type == FitnessTargetType.strengthReps) {
      extra['reps'] = int.tryParse(_repsController.text) ?? 10;
    }
    if (_measurement != null) {
      extra['measurement'] = _measurement;
    }

    double startValue = 0;
    if (_type == FitnessTargetType.bodyWeight) {
      startValue = provider.profile?.currentWeight ?? 0;
    }

    final target = FitnessTarget(
      id: const Uuid().v4(),
      name: name,
      description: _descController.text.trim(),
      type: _type,
      exerciseId: _selectedExercise?.id,
      targetValue: value,
      startValue: startValue,
      currentValue: startValue,
      unit: _type.defaultUnit,
      deadline: _deadline,
      accentColor: _selectedColor,
      extra: extra,
    );

    provider.addTarget(target);
    HapticFeedback.mediumImpact();
    Navigator.pop(context);

    _snack('Цель «$name» создана', _selectedColor);
  }

  void _snack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
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
// EXERCISE PICKER SHEET (без изменений)
// =====================================================================

class _ExercisePickerSheet extends StatefulWidget {
  final bool isDark;
  final List<Exercise> exercises;
  final ExerciseType? filterType;
  const _ExercisePickerSheet({
    required this.isDark,
    required this.exercises,
    this.filterType,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.exercises.where((e) {
      if (widget.filterType != null && e.exerciseType != widget.filterType) {
        return false;
      }
      if (_query.isNotEmpty &&
          !e.name.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Column(
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
                'ВЫБОР УПРАЖНЕНИЯ',
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
              onChanged: (v) => setState(() => _query = v),
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
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final ex = filtered[i];
              final accent = ex.muscleGroups.isNotEmpty
                  ? ex.muscleGroups.first.color
                  : _Power.volt;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context, ex);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _Power.card(widget.isDark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _Power.separator(widget.isDark),
                      width: 0.5,
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _Power.textSecondary(widget.isDark),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: _Power.textTertiary(widget.isDark),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}