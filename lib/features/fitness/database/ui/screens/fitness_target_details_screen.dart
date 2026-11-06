// features/fitness/ui/screens/fitness_target_details_screen.dart
// 🎨 design refinement: hero-card с полноэкранным cover + Power Mode tokens
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:cached_network_image/cached_network_image.dart';
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
  static const Color lightCard2 = Color(0xFFF9FAFB);

  static Color bg(bool isDark) => isDark ? darkBg : lightBg;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color card2(bool isDark) => isDark ? darkCard2 : lightCard2;
  static Color textPrimary(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF0A0A0A);
  static Color textSecondary(bool isDark) => isDark
      ? Colors.white.withOpacity(0.62)
      : const Color(0xFF3C3C43).withOpacity(0.62);
  static Color textTertiary(bool isDark) => isDark
      ? Colors.white.withOpacity(0.32)
      : const Color(0xFF3C3C43).withOpacity(0.32);
  static Color separator(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

  static List<BoxShadow> softGlow(Color color, {double strength = 0.18}) => [
    BoxShadow(color: color.withOpacity(strength), blurRadius: 16),
  ];

  static List<BoxShadow> glow(
      Color color, {
        double strength = 0.4,
        double blur = 24,
      }) =>
      [
        BoxShadow(
          color: color.withOpacity(strength),
          blurRadius: blur,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> cardShadow(bool isDark, Color tint) => isDark
      ? [
    BoxShadow(
      color: Colors.black.withOpacity(0.45),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ]
      : [
    BoxShadow(
      color: tint.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: tint.withOpacity(0.08),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

class _R {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 22.0;
  static const xxl = 28.0;
}

class _Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

class _Num {
  static const _feat = <FontFeature>[FontFeature.tabularFigures()];
  static TextStyle t(TextStyle base) => base.copyWith(fontFeatures: _feat);
}

// ==================== PRESSABLE ====================

class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        if (widget.haptic) HapticFeedback.lightImpact();
        widget.onTap();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ==================== SCREEN ====================

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
  // ─────────────────────────────────────────────────────────
  //  Image helpers
  // ─────────────────────────────────────────────────────────
  String? _resolveExerciseImageUrl(String? exerciseId) {
    if (exerciseId == null || exerciseId.isEmpty) return null;
    try {
      final provider = context.read<FitnessProvider>();
      final ex = provider.exercises.firstWhere((e) => e.id == exerciseId);
      return ex.imageUrl;
    } catch (_) {
      return null;
    }
  }

  Widget _coverImage(String url, Widget fallback) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
    }
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  /// Компактный thumb (используется в bottom-sheets)
  Widget _buildExerciseThumb({
    required String? exerciseId,
    required double size,
    required double radius,
    required Color accent,
    required String fallbackEmoji,
    bool onDark = false,
  }) {
    Exercise? ex;
    if (exerciseId != null && exerciseId.isNotEmpty) {
      final provider = context.read<FitnessProvider>();
      try {
        ex = provider.exercises.firstWhere((e) => e.id == exerciseId);
      } catch (_) {
        ex = null;
      }
    }

    final url = ex?.imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    final emoji = (ex != null) ? ex.exerciseType.emoji : fallbackEmoji;

    final Widget fallback = Text(
      emoji,
      style: TextStyle(fontSize: size * 0.5),
    );

    Widget imageWidget() {
      if (!hasImage) return fallback;
      if (url!.startsWith('assets/')) {
        return Image.asset(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
      if (url.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: onDark
                ? Colors.white.withOpacity(0.10)
                : accent.withOpacity(0.08),
          ),
          errorWidget: (_, __, ___) => fallback,
        );
      }
      return Image.file(
        File(url),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withOpacity(0.22)
            : accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: _Power.softGlow(accent, strength: 0.20),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageWidget(),
    );
  }

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

          // ═══ HERO — full-cover image ═══
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
              padding:
              const EdgeInsets.fromLTRB(_Sp.xl, _Sp.xxl, _Sp.xl, _Sp.md),
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
                  const SizedBox(width: _Sp.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _Sp.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _Power.volt.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(_R.xs),
                    ),
                    child: Text(
                      '${entries.length}',
                      style: _Num.t(
                        const TextStyle(
                          color: _Power.volt,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          height: 1,
                        ),
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
                  final prev =
                  index < entries.length - 1 ? entries[index + 1] : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _Sp.lg),
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
        padding: const EdgeInsets.only(bottom: _Sp.sm),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow:
            _Power.glow(target.accentColor, strength: 0.45, blur: 24),
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
  // SLIVER APP BAR
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
        padding: const EdgeInsets.only(
          left: _Sp.lg,
          top: 10,
          bottom: 10,
        ),
        child: _Pressable(
          onTap: () => Navigator.pop(context),
          scale: 0.9,
          haptic: false,
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
          padding: const EdgeInsets.only(right: _Sp.lg),
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
              borderRadius: BorderRadius.circular(_R.lg),
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
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(_R.xs),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: destructive ? _Power.red : _Power.textPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // MENU ACTIONS
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
      builder: (ctx) => _buildIOSDialog(
        isDark,
        title: 'Удалить цель?',
        message: '«${target.name}» и вся история будут удалены',
        destructive: 'Удалить',
        onDestructive: () async {
          HapticFeedback.mediumImpact();
          await provider.deleteTarget(target.id);
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildIOSDialog(
      bool isDark, {
        required String title,
        required String message,
        required String destructive,
        required VoidCallback onDestructive,
        String cancelLabel = 'Отмена',
      }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? _Power.darkCard2 : Colors.white,
          borderRadius: BorderRadius.circular(_R.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _Sp.xl,
                _Sp.xl,
                _Sp.xl,
                _Sp.lg,
              ),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _Power.textPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
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
                  child: _Pressable(
                    onTap: () => Navigator.pop(context),
                    scale: 0.96,
                    haptic: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: _Sp.md),
                      alignment: Alignment.center,
                      child: Text(
                        cancelLabel,
                        style: const TextStyle(
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
                  child: _Pressable(
                    onTap: onDestructive,
                    scale: 0.96,
                    haptic: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: _Sp.md),
                      alignment: Alignment.center,
                      child: Text(
                        destructive,
                        style: const TextStyle(
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
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // HERO CARD — full-cover image (dashboard style)
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildHeroCard(bool isDark, FitnessTarget target) {
    final progress = target.progressPercent;
    final improvement = target.lastImprovement;
    final bool isImprovement =
    target.isAscending ? improvement > 0 : improvement < 0;
    final imageUrl = _resolveExerciseImageUrl(target.exerciseId);
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    // Fallback: градиент в цветах цели + крупный эмодзи
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            target.accentColor,
            target.accentColor.withOpacity(0.6),
            _Power.heroDeep,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.14),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: -30,
            child: Text(
              target.type.emoji,
              style: TextStyle(
                fontSize: 180,
                color: Colors.white.withOpacity(0.10),
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(_Sp.lg, _Sp.xs, _Sp.lg, _Sp.lg),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(_R.xxl - 4),
        boxShadow: [
          BoxShadow(
            color: target.accentColor.withOpacity(0.28),
            blurRadius: 30,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ═══ COVER ═══
          SizedBox(
            height: 240,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Изображение / gradient fallback
                if (hasImage) _coverImage(imageUrl!, fallback) else fallback,

                // 2. Тёмный градиент поверх (чтобы белый текст читался)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0x44000000),
                        Color(0xCC000000),
                      ],
                      stops: [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),

                // 3. Контент на обложке
                Padding(
                  padding: const EdgeInsets.all(_Sp.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.94),
                              borderRadius: BorderRadius.circular(_R.xs),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  target.type.emoji,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  target.type.displayName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF0A0A0A),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
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
                                horizontal: _Sp.sm,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(_R.xs),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.20),
                                  width: 0.6,
                                ),
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
                                  const SizedBox(width: _Sp.xs),
                                  Text(
                                    _formatDeadline(target.deadline!),
                                    style: _Num.t(
                                      TextStyle(
                                        color: target.isOverdue
                                            ? const Color(0xFFFFD0D0)
                                            : Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Название цели
                      Text(
                        target.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _Num.t(
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ═══ BODY ═══
          Padding(
            padding: const EdgeInsets.fromLTRB(_Sp.xl, _Sp.lg, _Sp.xl, _Sp.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big number + unit + improvement
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          target.formattedCurrent,
                          style: _Num.t(
                            TextStyle(
                              color: _Power.textPrimary(isDark),
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -2.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        target.unit,
                        style: TextStyle(
                          color: _Power.textSecondary(isDark),
                          fontSize: 15,
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
                          color: (isImprovement ? _Power.green : _Power.red)
                              .withOpacity(0.14),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isImprovement
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: isImprovement
                                  ? _Power.green
                                  : _Power.red,
                              size: 14,
                            ),
                            const SizedBox(width: _Sp.xs),
                            Text(
                              '${improvement > 0 ? '+' : ''}${improvement.toStringAsFixed(1)}',
                              style: _Num.t(
                                TextStyle(
                                  color: isImprovement
                                      ? _Power.green
                                      : _Power.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: _Sp.lg),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: _Power.separator(isDark),
                    valueColor: AlwaysStoppedAnimation(target.accentColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${(progress * 100).toInt()}% ВЫПОЛНЕНО',
                      style: _Num.t(
                        TextStyle(
                          color: target.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ОСТАЛОСЬ ${target.formattedRemaining} ${target.unit}',
                      style: _Num.t(
                        TextStyle(
                          color: _Power.textTertiary(isDark),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),

                if (target.startValue > 0 &&
                    target.startValue != target.currentValue) ...[
                  const SizedBox(height: _Sp.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _Sp.md,
                      vertical: _Sp.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _Power.card2(isDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 12,
                          color: _Power.textTertiary(isDark),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'СТАРТ',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: _Power.textTertiary(isDark),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _fmt(target.startValue),
                          style: _Num.t(
                            TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: _Power.textPrimary(isDark),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'ЦЕЛЬ',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: _Power.textTertiary(isDark),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _fmt(target.targetValue),
                          style: _Num.t(
                            TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: target.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
  // FORECAST CARD
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
      margin: const EdgeInsets.fromLTRB(_Sp.lg, 0, _Sp.lg, _Sp.lg),
      padding: const EdgeInsets.all(_Sp.lg),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(_R.xl - 2),
        border: Border.all(color: accent.withOpacity(0.25), width: 0.8),
        boxShadow: _Power.cardShadow(isDark, accent),
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withOpacity(0.22),
                      accent.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(_R.md),
                  boxShadow: _Power.softGlow(accent, strength: 0.22),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: _Sp.md),
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
                    style: _Num.t(
                      TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: accent,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (trendDays > 0 && isRealistic) ...[
            const SizedBox(height: _Sp.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: _Sp.md,
                vertical: _Sp.sm,
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
  // CHART CARD
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
      margin: const EdgeInsets.fromLTRB(_Sp.lg, 0, _Sp.lg, 0),
      padding: const EdgeInsets.all(_Sp.lg),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(_R.xl - 2),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
        boxShadow: _Power.cardShadow(isDark, target.accentColor),
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
                  style: _Num.t(
                    TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: _Power.textTertiary(isDark),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: _Sp.lg),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _TargetChartPainter(
                points:
                sorted.map((e) => (value: e.value, date: e.date)).toList(),
                targetValue: target.targetValue,
                startValue: target.startValue,
                accentColor: target.accentColor,
                isDark: isDark,
                chartMin: chartMin,
                chartRange: chartRange,
              ),
            ),
          ),
          const SizedBox(height: _Sp.md),
          Container(height: 0.5, color: _Power.separator(isDark)),
          const SizedBox(height: _Sp.md),
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
          style: _Num.t(
            TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: _Sp.xs),
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
  // ENTRY CARD
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
      padding: const EdgeInsets.all(_Sp.md),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(_R.lg - 2),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
        boxShadow: _Power.cardShadow(isDark, target.accentColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  target.accentColor.withOpacity(0.20),
                  target.accentColor.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(_R.sm),
              boxShadow: _Power.softGlow(target.accentColor, strength: 0.22),
            ),
            alignment: Alignment.center,
            child: Text(
              _fmt(entry.value),
              style: _Num.t(
                TextStyle(
                  color: target.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: _Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(entry.date),
                        style: _Num.t(
                          TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: _Power.textPrimary(isDark),
                          ),
                        ),
                      ),
                    ),
                    if (hasChange)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _Sp.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (isImprovement ? _Power.green : _Power.red)
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
                              style: _Num.t(
                                TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                  height: 1,
                                  color: isImprovement
                                      ? _Power.green
                                      : _Power.red,
                                ),
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
                  const SizedBox(height: _Sp.xs),
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
                        style: _Num.t(
                          TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: _Power.textTertiary(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: _Sp.sm),
          _Pressable(
            onTap: () => _confirmDeleteEntry(entry, target),
            scale: 0.88,
            haptic: false,
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
      builder: (ctx) => _buildIOSDialog(
        isDark,
        title: 'Удалить запись?',
        message: 'Запись за ${_formatDate(entry.date)} будет удалена',
        destructive: 'Удалить',
        onDestructive: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(ctx, true);
        },
      ),
    );
    if (confirm == true) {
      await provider.removeTargetEntry(target.id, entry.date);
    }
  }

  // =====================================================================
  // EDIT CURRENT VALUE
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
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            _Sp.xl,
            _Sp.md,
            _Sp.xl,
            _Sp.xxl,
          ),
          decoration: BoxDecoration(
            color: _Power.card(isDark),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(_R.xxl)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSheetHandle(isDark),
                const SizedBox(height: _Sp.xl),
                const Text(
                  'РУЧНАЯ КОРРЕКТИРОВКА',
                  style: TextStyle(
                    color: _Power.volt,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: _Sp.xs),
                Text(
                  'Текущее значение',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: _Sp.xl),
                _buildBigNumberField(
                  isDark,
                  controller,
                  target.unit,
                  autofocus: true,
                ),
                const SizedBox(height: _Sp.xl),
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
                              borderRadius: BorderRadius.circular(_R.md),
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
                              borderRadius: BorderRadius.circular(_R.md),
                            ),
                            shadowColor: target.accentColor.withOpacity(0.5),
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
        ),
      ),
    );
  }

  // =====================================================================
  // EMPTY HISTORY
  // =====================================================================

  Widget _buildEmptyHistory(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _Sp.lg),
      padding: const EdgeInsets.all(_R.xxl - 2),
      decoration: BoxDecoration(
        color: _Power.card(isDark),
        borderRadius: BorderRadius.circular(_R.xl - 2),
        border: Border.all(color: _Power.separator(isDark), width: 0.5),
        boxShadow: _Power.cardShadow(isDark, _Power.volt),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _Power.volt.withOpacity(0.20),
                  _Power.volt.withOpacity(0.06),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: _Power.softGlow(_Power.volt, strength: 0.18),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 30,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: _Sp.lg),
          const Text(
            'ИСТОРИЯ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: _Sp.xs),
          Text(
            'Пока пусто',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: _Power.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: _Sp.sm),
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
  // ADD ENTRY SHEET
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
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            _Sp.xl,
            _Sp.md,
            _Sp.xl,
            _Sp.xxl,
          ),
          decoration: BoxDecoration(
            color: _Power.card(isDark),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(_R.xxl)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSheetHandle(isDark),
                const SizedBox(height: _Sp.xl),
                Row(
                  children: [
                    _buildExerciseThumb(
                      exerciseId: target.exerciseId,
                      size: 42,
                      radius: 11,
                      accent: target.accentColor,
                      fallbackEmoji: target.type.emoji,
                    ),
                    const SizedBox(width: _Sp.md),
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
                const SizedBox(height: _Sp.xxl - 2),
                Padding(
                  padding: const EdgeInsets.only(left: _Sp.xs, bottom: _Sp.sm),
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
                _buildBigNumberField(
                  isDark,
                  controller,
                  target.unit,
                  autofocus: true,
                ),
                const SizedBox(height: _Sp.lg),
                Padding(
                  padding: const EdgeInsets.only(left: _Sp.xs, bottom: _Sp.sm),
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
                      borderRadius: BorderRadius.circular(_R.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: _Sp.lg,
                      vertical: _R.md,
                    ),
                  ),
                ),
                const SizedBox(height: _Sp.xxl - 2),
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
                            content: const Text('Введите корректное значение'),
                            backgroundColor: _Power.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_R.md),
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
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: _Sp.sm),
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
                            borderRadius: BorderRadius.circular(_R.md),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: target.accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_R.md),
                      ),
                      shadowColor: target.accentColor.withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 22),
                        SizedBox(width: _Sp.sm),
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
  // SHARED WIDGETS
  // =====================================================================

  Widget _buildSheetHandle(bool isDark) {
    return Center(
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: _Power.textTertiary(isDark),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildBigNumberField(
      bool isDark,
      TextEditingController controller,
      String unit, {
        bool autofocus = false,
      }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autofocus: autofocus,
      style: _Num.t(
        TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
          color: _Power.textPrimary(isDark),
        ),
      ),
      decoration: InputDecoration(
        hintText: '0.0',
        hintStyle: TextStyle(
          color: _Power.textTertiary(isDark),
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
        suffixText: unit,
        suffixStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: _Power.textSecondary(isDark),
        ),
        filled: true,
        fillColor: _Power.card2(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_R.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _Sp.lg,
          vertical: _R.lg,
        ),
      ),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

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

// ==================== CUSTOM PAINTER ====================

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
      ..color = const Color(0xFF00C853).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final startPaint = Paint()
      ..color = const Color(0xFFFF9500).withOpacity(0.45)
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

    final coords = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final px = points.length == 1
          ? size.width / 2
          : (i / (points.length - 1)) * size.width;
      final normalized =
      ((points[i].value - chartMin) / chartRange).clamp(0.0, 1.0);
      final py = size.height - normalized * size.height;
      coords.add(Offset(px, py));
    }

    if (coords.isEmpty) return;

    final path = _smoothPath(coords);
    final fillPath = Path.from(path)
      ..lineTo(coords.last.dx, size.height)
      ..lineTo(coords.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    if (coords.length > 1) canvas.drawPath(path, linePaint);

    for (final c in coords) {
      canvas.drawCircle(c, 6, pointBorder);
      canvas.drawCircle(c, 4, pointPaint);
    }
  }

  Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length < 2) return path;
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : pts[i + 1];

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }
    return path;
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