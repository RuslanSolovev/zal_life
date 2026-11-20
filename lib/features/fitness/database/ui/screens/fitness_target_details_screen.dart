// features/fitness/ui/screens/fitness_target_details_screen.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../providers/fitness_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM (Синхронизировано с HomeScreen)
// ═══════════════════════════════════════════════════════════════════
class _Palette {
  static const bg = Color(0xFFF6F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF263D36);
  static const textMuted = Color(0xFF7C8982);
  static const green = Color(0xFF426C59);
  static const greenSoft = Color(0xFFE7EFE5);
  static const sage = Color(0xFF8CAB93);
  static const peach = Color(0xFFC79475);
  static const peachSoft = Color(0xFFF5E6DC);
  static const pink = Color(0xFFBB8F9D);
  static const pinkSoft = Color(0xFFF2E4E7);
  static const yellow = Color(0xFFE7D9B8);
  static const divider = Color(0xFFE5E8E1);
}

class _R {
  final double scale;
  _R(BuildContext context) : scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

class _AppImg extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  final Widget? fallback;
  const _AppImg({this.path, this.fit = BoxFit.cover, this.fallback});

  @override
  Widget build(BuildContext context) {
    final p = path;
    final fb = fallback ?? const SizedBox.shrink();
    if (p == null || p.isEmpty) return fb;
    if (p.startsWith('assets/')) {
      return Image.asset(p, fit: fit, errorBuilder: (_, __, ___) => fb);
    }
    if (p.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: p, fit: fit,
        placeholder: (_, __) => fb,
        errorWidget: (_, __, ___) => fb,
      );
    }
    return Image.file(File(p), fit: fit, errorBuilder: (_, __, ___) => fb);
  }
}

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double scale;
  const _TapScale({required this.child, required this.onTap, this.onLongPress, this.scale = 0.96});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _GlossyProgress extends StatelessWidget {
  final double value;
  final double height;
  final List<Color> gradient;
  final Color track;
  final double radius;
  const _GlossyProgress({required this.value, required this.gradient, this.height = 8, this.track = const Color(0x33FFFFFF), this.radius = 100});

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          Container(height: height, decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(radius))),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(colors: gradient, begin: Alignment.centerLeft, end: Alignment.centerRight),
                  boxShadow: [BoxShadow(color: gradient.last.withOpacity(0.35), blurRadius: 6, spreadRadius: -1)],
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.42,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(radius), bottom: Radius.circular(radius * 0.4)),
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withOpacity(0.55), Colors.white.withOpacity(0.0)]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EXERCISE COVER (для Hero)
// ═══════════════════════════════════════════════════════════════════
class _ExerciseCover extends StatelessWidget {
  final Exercise? exercise;
  final String fallbackEmoji;
  final Color accent;
  final WidgetBuilder contentBuilder;

  const _ExerciseCover({this.exercise, required this.fallbackEmoji, required this.accent, required this.contentBuilder});

  @override
  Widget build(BuildContext context) {
    final url = exercise?.imageUrl;
    final hasImage = url != null && url.isNotEmpty;

    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent, accent.withOpacity(0.55), _Palette.text.withOpacity(0.8)], stops: const [0.0, 0.6, 1.0]),
      ),
      child: Stack(
        children: [
          Positioned(right: -30, bottom: -30, child: Text(fallbackEmoji, style: TextStyle(fontSize: 140, color: Colors.white.withOpacity(0.10), height: 1))),
          Positioned(left: -40, top: -40, child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x29FFFFFF), Color(0x00FFFFFF)])))),
        ],
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        hasImage ? _AppImg(path: url!, fit: BoxFit.cover, fallback: fallback) : fallback,
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.30), Colors.black.withOpacity(0.78)], stops: const [0.0, 0.35, 0.70, 1.0]),
          ),
        ),
        contentBuilder(context),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class FitnessTargetDetailsScreen extends StatefulWidget {
  final FitnessTarget target;
  final bool isDark; // Оставлен для совместимости, но стилизация теперь светлая
  const FitnessTargetDetailsScreen({super.key, required this.target, required this.isDark});

  @override
  State<FitnessTargetDetailsScreen> createState() => _FitnessTargetDetailsScreenState();
}

class _FitnessTargetDetailsScreenState extends State<FitnessTargetDetailsScreen> {
  Exercise? _resolveExercise(FitnessProvider provider, String? exerciseId) {
    if (exerciseId == null || exerciseId.isEmpty) return null;
    try { return provider.exercises.firstWhere((e) => e.id == exerciseId); } catch (_) { return null; }
  }

  String _plural(int n, String one, String few, String many) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return one;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
    return many;
  }

  String _formatDate(DateTime date) {
    const months = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final r = _R(context);

    final target = provider.targets.firstWhere((t) => t.id == widget.target.id, orElse: () => widget.target);
    final entries = provider.getTargetEntries(target.id);
    final forecast = provider.calculateForecast(target);
    final exercise = _resolveExercise(provider, target.exerciseId);

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: _Palette.bg.withOpacity(0.94),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 60,
            leading: Padding(
              padding: EdgeInsets.only(left: r.s(16), top: r.s(10), bottom: r.s(10)),
              child: _TapScale(
                onTap: () => Navigator.pop(context),
                scale: 0.9,
                child: Container(
                  width: r.s(36), height: r.s(36),
                  decoration: BoxDecoration(
                    color: _Palette.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: _Palette.divider, width: 1),
                    boxShadow: [BoxShadow(color: _Palette.peach.withOpacity(0.06), blurRadius: 10, spreadRadius: -2, offset: const Offset(0, 3))],
                  ),
                  child: Icon(Icons.chevron_left_rounded, color: _Palette.text, size: r.s(22)),
                ),
              ),
            ),
            title: Text(target.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: r.fs(16), fontWeight: FontWeight.w600, letterSpacing: -0.3, color: _Palette.text)),
            centerTitle: true,
            actions: [
              Padding(
                padding: EdgeInsets.only(right: r.s(16)),
                child: PopupMenuButton<String>(
                  icon: Container(
                    width: r.s(36), height: r.s(36),
                    decoration: BoxDecoration(color: _Palette.divider.withOpacity(0.3), shape: BoxShape.circle),
                    child: Icon(Icons.more_horiz_rounded, color: _Palette.text, size: r.s(20)),
                  ),
                  color: _Palette.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))),
                  onSelected: (value) => _handleMenuAction(value, target, provider),
                  itemBuilder: (ctx) => [
                    if (target.status == FitnessTargetStatus.active) _buildMenuItem(Icons.edit_rounded, target.accentColor, 'Изменить значение', 'edit_value'),
                    if (target.status == FitnessTargetStatus.active) _buildMenuItem(Icons.emoji_events_rounded, _Palette.green, 'Отметить достигнутой', 'complete'),
                    if (target.status == FitnessTargetStatus.active) _buildMenuItem(Icons.pause_circle_outline_rounded, _Palette.peach, 'Приостановить', 'pause'),
                    if (target.status == FitnessTargetStatus.paused) _buildMenuItem(Icons.play_circle_outline_rounded, _Palette.green, 'Возобновить', 'resume'),
                    _buildMenuItem(Icons.delete_outline_rounded, _Palette.pink, 'Удалить', 'delete', destructive: true),
                  ],
                ),
              ),
            ],
          ),

          // ═══ HERO CARD ═══
          SliverToBoxAdapter(child: _buildHeroCard(r, target, exercise)),
          SliverToBoxAdapter(child: _buildForecastCard(r, target, forecast)),

          if (entries.isNotEmpty) SliverToBoxAdapter(child: _buildChartCard(r, target, entries)),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(24), r.s(20), r.s(12)),
              child: Row(
                children: [
                  Container(width: 3, height: 14, decoration: BoxDecoration(color: _Palette.peach, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: _Palette.peach.withOpacity(0.4), blurRadius: 6)])),
                  SizedBox(width: r.s(10)),
                  Text('ИСТОРИЯ', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(12), fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                  SizedBox(width: r.s(8)),
                  Container(padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(3)), decoration: BoxDecoration(color: _Palette.peachSoft, borderRadius: BorderRadius.circular(r.s(6))), child: Text('${entries.length}', style: GoogleFonts.inter(color: _Palette.peach, fontSize: r.fs(11), fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          ),

          if (entries.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyHistory(r))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final entry = entries[index];
                  final prev = index < entries.length - 1 ? entries[index + 1] : null;
                  return Padding(padding: EdgeInsets.symmetric(horizontal: r.s(20)), child: _buildEntryCard(r, entry, prev, target));
                },
                childCount: entries.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: target.status == FitnessTargetStatus.active
          ? Padding(
        padding: EdgeInsets.only(bottom: r.s(8)),
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: target.accentColor.withOpacity(0.35), blurRadius: 12)]),
          child: FloatingActionButton.extended(
            backgroundColor: target.accentColor,
            foregroundColor: Colors.white,
            elevation: 0,
            onPressed: () => _showAddEntrySheet(context, target, provider, r),
            icon: Icon(Icons.add_rounded, size: r.s(20)),
            label: Text('ЗАПИСАТЬ', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 0.8, fontSize: r.fs(12))),
          ),
        ),
      )
          : null,
    );
  }

  PopupMenuItem<String> _buildMenuItem(IconData icon, Color color, String label, String value, {bool destructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: destructive ? _Palette.pink : _Palette.text)),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, FitnessTarget target, FitnessProvider provider) async {
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

  void _confirmDeleteTarget(FitnessTarget target, FitnessProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _IosDialog(title: 'Удалить цель?', message: '«${target.name}» и вся история будут удалены', onDestructive: () async {
        HapticFeedback.mediumImpact();
        await provider.deleteTarget(target.id);
        if (ctx.mounted) Navigator.pop(ctx);
        if (mounted) Navigator.pop(context);
      }),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HERO CARD
  // ═════════════════════════════════════════════════════════
  Widget _buildHeroCard(_R r, FitnessTarget target, Exercise? exercise) {
    final progress = target.progressPercent;
    final improvement = target.lastImprovement;
    final bool isImprovement = target.isAscending ? improvement > 0 : improvement < 0;

    return Container(
      margin: EdgeInsets.fromLTRB(r.s(20), r.s(4), r.s(20), r.s(20)),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(r.s(24)),
        border: Border.all(color: _Palette.divider, width: 1),
        boxShadow: [BoxShadow(color: target.accentColor.withOpacity(0.08), blurRadius: 22, spreadRadius: -6, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: r.s(240),
            child: _ExerciseCover(
              exercise: exercise,
              fallbackEmoji: target.type.emoji,
              accent: target.accentColor,
              contentBuilder: (context) => Padding(
                padding: EdgeInsets.all(r.s(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(6)),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.94), borderRadius: BorderRadius.circular(r.s(8))),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [Text(target.type.emoji, style: TextStyle(fontSize: r.fs(11))), SizedBox(width: r.s(5)), Text(target.type.displayName.toUpperCase(), style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(9), fontWeight: FontWeight.w900, letterSpacing: 1.0, height: 1))],
                          ),
                        ),
                        const Spacer(),
                        if (target.deadline != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(5)),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(r.s(8)), border: Border.all(color: Colors.white.withOpacity(0.20), width: 0.6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded, color: target.isOverdue ? const Color(0xFFFFD0D0) : Colors.white.withOpacity(0.9), size: r.s(11)),
                                SizedBox(width: r.s(4)),
                                Text(_formatDeadline(target.deadline!), style: GoogleFonts.inter(color: target.isOverdue ? const Color(0xFFFFD0D0) : Colors.white, fontSize: r.fs(11), fontWeight: FontWeight.w800, letterSpacing: -0.2, height: 1, fontFeatures: const [FontFeature.tabularFigures()])),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(target.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(28), fontWeight: FontWeight.w600, letterSpacing: -1.0, height: 1.1)),
                    SizedBox(height: r.s(6)),
                    Text(target.isAscending ? 'из ${target.formattedTarget} ${target.unit}' : 'до ${target.formattedTarget} ${target.unit}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: r.fs(14), fontWeight: FontWeight.w500, letterSpacing: -0.2)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(r.s(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(target.formattedCurrent, style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(46), fontWeight: FontWeight.w600, height: 1, letterSpacing: -2.5, fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                    ),
                    SizedBox(width: r.s(8)),
                    Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(target.unit, style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(15), fontWeight: FontWeight.w600, letterSpacing: -0.3))),
                    const Spacer(),
                    if (improvement != 0 && target.entries.length >= 2)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.s(6)),
                        decoration: BoxDecoration(color: (isImprovement ? _Palette.green : _Palette.pink).withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isImprovement ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: isImprovement ? _Palette.green : _Palette.pink, size: r.s(14)),
                            SizedBox(width: r.s(4)),
                            Text('${improvement > 0 ? '+' : ''}${improvement.toStringAsFixed(1)}', style: GoogleFonts.inter(color: isImprovement ? _Palette.green : _Palette.pink, fontSize: r.fs(13), fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1, fontFeatures: const [FontFeature.tabularFigures()])),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: r.s(16)),
                _GlossyProgress(
                  value: progress,
                  height: r.s(8),
                  gradient: [target.accentColor.withOpacity(0.75), target.accentColor],
                  track: _Palette.divider.withOpacity(0.5),
                  radius: r.s(5),
                ),
                SizedBox(height: r.s(10)),
                Row(
                  children: [
                    Text('${(progress * 100).toInt()}% ВЫПОЛНЕНО', style: GoogleFonts.inter(color: target.accentColor, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0, fontFeatures: const [FontFeature.tabularFigures()])),
                    const Spacer(),
                    Text('ОСТАЛОСЬ ${target.formattedRemaining} ${target.unit}', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0, fontFeatures: const [FontFeature.tabularFigures()])),
                  ],
                ),
                if (target.startValue > 0 && target.startValue != target.currentValue) ...[
                  SizedBox(height: r.s(12)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(8)),
                    decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, size: r.s(12), color: _Palette.textMuted),
                        SizedBox(width: r.s(6)),
                        Text('СТАРТ', style: GoogleFonts.inter(fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.2, color: _Palette.textMuted)),
                        SizedBox(width: r.s(6)),
                        Text(_fmt(target.startValue), style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w600, letterSpacing: -0.2, color: _Palette.text, fontFeatures: const [FontFeature.tabularFigures()])),
                        const Spacer(),
                        Text('ЦЕЛЬ', style: GoogleFonts.inter(fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.2, color: _Palette.textMuted)),
                        SizedBox(width: r.s(6)),
                        Text(_fmt(target.targetValue), style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w600, letterSpacing: -0.2, color: target.accentColor, fontFeatures: const [FontFeature.tabularFigures()])),
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

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  String _formatDeadline(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return 'ПРОСРОЧЕНО';
    if (days == 0) return 'СЕГОДНЯ';
    if (days == 1) return 'ЗАВТРА';
    if (days <= 7) return '$days ДН.';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}';
  }

  // ═════════════════════════════════════════════════════════
  //  FORECAST & CHART
  // ═════════════════════════════════════════════════════════
  Widget _buildForecastCard(_R r, FitnessTarget target, Map<String, dynamic> forecast) {
    final isRealistic = forecast['isRealistic'] as bool? ?? false;
    final days = forecast['days'] as int?;

    Color accent = _Palette.textMuted;
    IconData icon = Icons.analytics_outlined;
    String title = 'Прогноз недоступен';
    String subtitle = 'Недостаточно данных';

    if (isRealistic && days != null) {
      if (days <= 7) { accent = _Palette.green; icon = Icons.bolt_rounded; title = 'Совсем скоро!'; subtitle = 'Осталось $days ${_daysWord(days)}'; }
      else if (days <= 30) { accent = _Palette.sage; icon = Icons.trending_up_rounded; title = 'Отличный темп'; subtitle = 'Примерно через $days ${_daysWord(days)}'; }
      else { accent = _Palette.peach; icon = Icons.schedule_rounded; title = 'Стабильный прогресс'; subtitle = '~${(days / 30).ceil()} месяцев'; }
    }

    return Container(
      margin: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(20)), border: Border.all(color: accent.withOpacity(0.25), width: 0.8), boxShadow: [BoxShadow(color: accent.withOpacity(0.06), blurRadius: 12, spreadRadius: -3, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(width: r.s(48), height: r.s(48), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent.withOpacity(0.22), accent.withOpacity(0.08)]), borderRadius: BorderRadius.circular(r.s(12)))),
          SizedBox(width: r.s(12)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ПРОГНОЗ', style: GoogleFonts.inter(fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _Palette.textMuted)), SizedBox(height: r.s(3)), Text(title, style: GoogleFonts.inter(fontSize: r.fs(16), fontWeight: FontWeight.w600, letterSpacing: -0.4, height: 1.1, color: _Palette.text)), SizedBox(height: r.s(2)), Text(subtitle, style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w500, color: _Palette.textMuted))])),
        ],
      ),
    );
  }

  Widget _buildChartCard(_R r, FitnessTarget target, List<FitnessTargetEntry> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final sorted = List<FitnessTargetEntry>.from(entries)..sort((a, b) => a.date.compareTo(b.date));
    final values = sorted.map((e) => e.value).toList();
    final maxVal = values.reduce(math.max);
    final minVal = values.reduce(math.min);
    final chartRange = (maxVal - minVal).abs() == 0 ? 1.0 : (maxVal - minVal).abs();

    return Container(
      margin: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(20)),
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(20)), border: Border.all(color: _Palette.divider, width: 0.5), boxShadow: [BoxShadow(color: target.accentColor.withOpacity(0.06), blurRadius: 12, spreadRadius: -3, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: r.s(32), height: r.s(32), decoration: BoxDecoration(color: target.accentColor.withOpacity(0.14), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.show_chart_rounded, color: target.accentColor, size: r.s(17))), SizedBox(width: r.s(10)), Text('ДИНАМИКА', style: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _Palette.text))]),
          SizedBox(height: r.s(16)),
          SizedBox(height: r.s(160), child: CustomPaint(size: Size(double.infinity, r.s(160)), painter: _TargetChartPainter(points: sorted.map((e) => (value: e.value, date: e.date)).toList(), targetValue: target.targetValue, startValue: target.startValue, accentColor: target.accentColor, chartMin: minVal, chartRange: chartRange))),
          SizedBox(height: r.s(12)),
          Container(height: 0.5, color: _Palette.divider),
          SizedBox(height: r.s(12)),
          Row(children: [_buildChartStat(r, 'МИН', minVal.toStringAsFixed(1), _Palette.textMuted), _buildChartStat(r, 'МАКС', maxVal.toStringAsFixed(1), target.accentColor), _buildChartStat(r, 'ЦЕЛЬ', target.targetValue.toStringAsFixed(1), _Palette.green)]),
        ],
      ),
    );
  }

  Widget _buildChartStat(_R r, String label, String value, Color color) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text(value, style: GoogleFonts.inter(fontSize: r.fs(17), fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1, color: color, fontFeatures: const [FontFeature.tabularFigures()])), SizedBox(height: r.s(4)), Text(label, style: GoogleFonts.inter(fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _Palette.textMuted))]));
  }

  String _daysWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) return 'дня';
    return 'дней';
  }

  // ═════════════════════════════════════════════════════════
  //  HISTORY LIST
  // ═════════════════════════════════════════════════════════
  Widget _buildEntryCard(_R r, FitnessTargetEntry entry, FitnessTargetEntry? prev, FitnessTarget target) {
    final diff = prev != null ? entry.value - prev.value : 0.0;
    final isImprovement = target.isAscending ? diff > 0 : diff < 0;
    final hasChange = diff != 0 && prev != null;

    return Container(
      margin: EdgeInsets.only(bottom: r.s(10)),
      padding: EdgeInsets.all(r.s(12)),
      decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(16)), border: Border.all(color: _Palette.divider, width: 0.5), boxShadow: [BoxShadow(color: target.accentColor.withOpacity(0.04), blurRadius: 8, spreadRadius: -2, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: r.s(48), height: r.s(48), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [target.accentColor.withOpacity(0.20), target.accentColor.withOpacity(0.08)]), borderRadius: BorderRadius.circular(r.s(10))), alignment: Alignment.center, child: Text(_fmt(entry.value), style: GoogleFonts.inter(color: target.accentColor, fontSize: r.fs(16), fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1, fontFeatures: const [FontFeature.tabularFigures()]))),
          SizedBox(width: r.s(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(_formatDate(entry.date), style: GoogleFonts.inter(fontSize: r.fs(13), fontWeight: FontWeight.w600, letterSpacing: -0.2, color: _Palette.text, fontFeatures: const [FontFeature.tabularFigures()]))),
                    if (hasChange) Container(padding: EdgeInsets.symmetric(horizontal: r.s(6), vertical: r.s(3)), decoration: BoxDecoration(color: (isImprovement ? _Palette.green : _Palette.pink).withOpacity(0.14), borderRadius: BorderRadius.circular(7)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isImprovement ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: r.s(11), color: isImprovement ? _Palette.green : _Palette.pink), SizedBox(width: r.s(3)), Text('${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}', style: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1, color: isImprovement ? _Palette.green : _Palette.pink, fontFeatures: const [FontFeature.tabularFigures()]))])),
                  ],
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[SizedBox(height: r.s(5)), Text(entry.note!, style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w500, color: _Palette.textMuted, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)],
              ],
            ),
          ),
          SizedBox(width: r.s(8)),
          _TapScale(onTap: () => _confirmDeleteEntry(entry, target), scale: 0.88, child: Container(width: r.s(32), height: r.s(32), decoration: BoxDecoration(color: _Palette.pinkSoft, shape: BoxShape.circle), child: Icon(Icons.delete_outline_rounded, color: _Palette.pink, size: r.s(16)))),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory(_R r) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: r.s(20)),
      padding: EdgeInsets.all(r.s(24)),
      decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(20)), border: Border.all(color: _Palette.divider, width: 0.5)),
      child: Column(children: [Container(width: r.s(72), height: r.s(72), decoration: BoxDecoration(gradient: RadialGradient(colors: [_Palette.peach.withOpacity(0.20), _Palette.peach.withOpacity(0.05)]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: _Palette.peach.withOpacity(0.18), blurRadius: 16)]), child: Icon(Icons.history_rounded, size: r.s(30), color: _Palette.peach)), SizedBox(height: r.s(16)), Text('ИСТОРИЯ', style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w800, letterSpacing: 2.2, color: _Palette.peach)), SizedBox(height: r.s(4)), Text('Пока пусто', style: GoogleFonts.inter(fontSize: r.fs(18), fontWeight: FontWeight.w600, letterSpacing: -0.5, color: _Palette.text)), SizedBox(height: r.s(8)), Text('Добавьте первую запись, чтобы отслеживать прогресс', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: r.fs(12), height: 1.4, color: _Palette.textMuted))]),
    );
  }

  Future<void> _confirmDeleteEntry(FitnessTargetEntry entry, FitnessTarget target) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => _IosDialog(title: 'Удалить запись?', message: 'Запись за ${_formatDate(entry.date)} будет удалена', onDestructive: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, true); }));
    if (confirm == true) await context.read<FitnessProvider>().removeTargetEntry(target.id, entry.date);
  }

  // ═════════════════════════════════════════════════════════
  //  ADD ENTRY SHEET
  // ═════════════════════════════════════════════════════════
  void _showAddEntrySheet(BuildContext context, FitnessTarget target, FitnessProvider provider, _R r) {
    final controller = TextEditingController(text: target.currentValue.toStringAsFixed(1));
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), r.s(24)),
          decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28)))),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: r.s(36), height: r.s(5), decoration: BoxDecoration(color: _Palette.divider, borderRadius: BorderRadius.circular(r.s(3))))),
                SizedBox(height: r.s(20)),
                Row(children: [Container(width: r.s(42), height: r.s(42), decoration: BoxDecoration(color: target.accentColor.withOpacity(0.14), borderRadius: BorderRadius.circular(11)), alignment: Alignment.center, child: Text(target.type.emoji, style: TextStyle(fontSize: r.fs(20)))), SizedBox(width: r.s(12)), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('НОВАЯ ЗАПИСЬ', style: GoogleFonts.inter(color: _Palette.peach, fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.4)), SizedBox(height: r.s(2)), Text(target.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: r.fs(18), fontWeight: FontWeight.w600, letterSpacing: -0.5, color: _Palette.text))]))]),
                SizedBox(height: r.s(20)),
                Text('ТЕКУЩИЙ РЕЗУЛЬТАТ', style: GoogleFonts.inter(fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _Palette.textMuted)),
                SizedBox(height: r.s(6)),
                TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true, style: GoogleFonts.inter(fontSize: r.fs(32), fontWeight: FontWeight.w600, letterSpacing: -1.2, color: _Palette.text, fontFeatures: const [FontFeature.tabularFigures()]), decoration: InputDecoration(hintText: '0.0', hintStyle: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(32), fontWeight: FontWeight.w600, letterSpacing: -1.2), suffixText: target.unit, suffixStyle: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, color: _Palette.textMuted), filled: true, fillColor: _Palette.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(12)), borderSide: BorderSide.none), contentPadding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(16)))),
                SizedBox(height: r.s(16)),
                Text('ЗАМЕТКА', style: GoogleFonts.inter(fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _Palette.textMuted)),
                SizedBox(height: r.s(6)),
                TextField(controller: noteController, maxLines: 2, style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w500, color: _Palette.text), decoration: InputDecoration(hintText: 'Опционально', hintStyle: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13)), filled: true, fillColor: _Palette.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(12)), borderSide: BorderSide.none), contentPadding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(12)))),
                SizedBox(height: r.s(24)),
                SizedBox(width: double.infinity, height: r.s(54), child: ElevatedButton(onPressed: () { final value = double.tryParse(controller.text); if (value == null) return; HapticFeedback.mediumImpact(); Navigator.pop(ctx); provider.addTargetEntry(target.id, value, note: noteController.text.trim().isEmpty ? null : noteController.text.trim()); }, style: ElevatedButton.styleFrom(backgroundColor: target.accentColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))), shadowColor: target.accentColor.withOpacity(0.4)), child: Text('СОХРАНИТЬ', style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w900, letterSpacing: 1.2)))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editCurrentValue(BuildContext context, FitnessTarget target, FitnessProvider provider) {
    final controller = TextEditingController(text: target.currentValue.toStringAsFixed(1));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 36, height: 5, decoration: BoxDecoration(color: _Palette.divider, borderRadius: BorderRadius.circular(3)))), const SizedBox(height: 20), Text('РУЧНАЯ КОРРЕКТИРОВКА', style: GoogleFonts.inter(color: _Palette.peach, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4)), const SizedBox(height: 4), Text('Текущее значение', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.7, color: _Palette.text)), const SizedBox(height: 20), TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -1.2, color: _Palette.text, fontFeatures: const [FontFeature.tabularFigures()]), decoration: InputDecoration(hintText: '0.0', suffixText: target.unit, filled: true, fillColor: _Palette.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16))), const SizedBox(height: 24), Row(children: [Expanded(child: SizedBox(height: 52, child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(foregroundColor: _Palette.textMuted, side: const BorderSide(color: _Palette.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Отмена', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15))))), const SizedBox(width: 10), Expanded(flex: 2, child: SizedBox(height: 52, child: ElevatedButton(onPressed: () { final value = double.tryParse(controller.text) ?? target.currentValue; HapticFeedback.mediumImpact(); Navigator.pop(ctx); provider.addTargetEntry(target.id, value, note: 'Ручная корректировка'); }, style: ElevatedButton.styleFrom(backgroundColor: target.accentColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('СОХРАНИТЬ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0)))))])])),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DIALOGS & PAINTERS
// ═══════════════════════════════════════════════════════════════════
class _IosDialog extends StatelessWidget {
  const _IosDialog({required this.title, required this.message, required this.onDestructive, this.cancelLabel = 'Отмена', this.destructiveLabel = 'Удалить'});
  final String title; final String message; final VoidCallback onDestructive; final String cancelLabel; final String destructiveLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60),
      child: Container(
        decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(20), child: Column(children: [Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: _Palette.text)), const SizedBox(height: 6), Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: _Palette.textMuted, height: 1.4))])),
            Container(height: 0.5, color: _Palette.divider),
            Row(
              children: [
                Expanded(child: _TapScale(onTap: () => Navigator.pop(context), scale: 0.96, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), alignment: Alignment.center, child: Text(cancelLabel, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w500, color: _Palette.peach))))),
                Container(width: 0.5, height: 50, color: _Palette.divider),
                Expanded(child: _TapScale(onTap: onDestructive, scale: 0.96, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), alignment: Alignment.center, child: Text(destructiveLabel, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: _Palette.pink))))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetChartPainter extends CustomPainter {
  final List<({double value, DateTime date})> points;
  final double targetValue;
  final double startValue;
  final Color accentColor;
  final double chartMin;
  final double chartRange;

  _TargetChartPainter({required this.points, required this.targetValue, required this.startValue, required this.accentColor, required this.chartMin, required this.chartRange});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final linePaint = Paint()..color = accentColor..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [accentColor.withOpacity(0.32), accentColor.withOpacity(0.0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))..style = PaintingStyle.fill;
    final targetPaint = Paint()..color = _Palette.green.withOpacity(0.55)..style = PaintingStyle.stroke..strokeWidth = 1.5;

    _drawDashedLine(canvas, size, targetValue, targetPaint);

    final coords = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final px = points.length == 1 ? size.width / 2 : (i / (points.length - 1)) * size.width;
      final normalized = ((points[i].value - chartMin) / chartRange).clamp(0.0, 1.0);
      final py = size.height - normalized * size.height;
      coords.add(Offset(px, py));
    }

    if (coords.isEmpty) return;
    final path = _smoothPath(coords);
    final fillPath = Path.from(path)..lineTo(coords.last.dx, size.height)..lineTo(coords.first.dx, size.height)..close();
    canvas.drawPath(fillPath, fillPaint);
    if (coords.length > 1) canvas.drawPath(path, linePaint);
    for (final c in coords) {
      canvas.drawCircle(c, 6, Paint()..color = _Palette.surface..style = PaintingStyle.stroke..strokeWidth = 2);
      canvas.drawCircle(c, 4, Paint()..color = accentColor);
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

  void _drawDashedLine(Canvas canvas, Size size, double value, Paint paint) {
    final y = size.height - ((value - chartMin) / chartRange).clamp(0.0, 1.0) * size.height;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y.clamp(0.0, size.height)), Offset((x + 6).clamp(0.0, size.width), y.clamp(0.0, size.height)), paint);
      x += 10;
    }
  }

  @override
  bool shouldRepaint(covariant _TargetChartPainter oldDelegate) => true;
}