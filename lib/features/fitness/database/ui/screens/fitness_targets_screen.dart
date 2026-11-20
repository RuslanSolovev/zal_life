// features/fitness/ui/screens/fitness_targets_screen.dart
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../providers/fitness_provider.dart';
import 'fitness_target_details_screen.dart';

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
//  EXERCISE THUMB & COVER
// ═══════════════════════════════════════════════════════════════════
class _ExerciseThumb extends StatelessWidget {
  final Exercise? exercise;
  final String fallbackEmoji;
  final double size;
  final double radius;
  final Color accent;

  const _ExerciseThumb({this.exercise, required this.fallbackEmoji, required this.size, required this.radius, required this.accent});

  Widget _fallback() => Text(fallbackEmoji, style: TextStyle(fontSize: size * 0.45, height: 1));

  @override
  Widget build(BuildContext context) {
    final hasImage = exercise?.imageUrl != null && exercise!.imageUrl!.isNotEmpty;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: hasImage ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent.withOpacity(0.22), accent.withOpacity(0.08)]),
        color: hasImage ? _Palette.surface : null,
        borderRadius: BorderRadius.circular(radius),
        border: hasImage ? Border.all(color: accent.withOpacity(0.18), width: 0.6) : null,
        boxShadow: [BoxShadow(color: accent.withOpacity(hasImage ? 0.15 : 0.22), blurRadius: 16)],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage ? _AppImg(path: exercise!.imageUrl, fit: BoxFit.cover, fallback: _fallback()) : _fallback(),
    );
  }
}

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
class FitnessTargetsScreen extends StatefulWidget {
  final bool isDark; // Оставлен для совместимости, но стилизация теперь светлая (Soft Pastel)
  const FitnessTargetsScreen({super.key, required this.isDark});

  @override
  State<FitnessTargetsScreen> createState() => _FitnessTargetsScreenState();
}

class _FitnessTargetsScreenState extends State<FitnessTargetsScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final r = _R(context);

    final active = provider.targets.where((t) => t.status == FitnessTargetStatus.active).toList();
    final completed = provider.targets.where((t) => t.status == FitnessTargetStatus.completed).toList();
    final other = provider.targets.where((t) => t.status == FitnessTargetStatus.paused || t.status == FitnessTargetStatus.abandoned).toList();

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
            title: Text('Цели', style: GoogleFonts.inter(fontSize: r.fs(15), fontWeight: FontWeight.w600, color: _Palette.text, letterSpacing: -0.2)),
            centerTitle: true,
            actions: [
              Padding(
                padding: EdgeInsets.only(right: r.s(16)),
                child: _TapScale(
                  onTap: () => _showCreateTargetSheet(context, provider, r),
                  scale: 0.9,
                  child: Container(
                    width: r.s(36), height: r.s(36),
                    decoration: BoxDecoration(
                      color: _Palette.peach,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _Palette.peach.withOpacity(0.35), blurRadius: 12)],
                    ),
                    child: Icon(Icons.add_rounded, color: Colors.white, size: r.s(20)),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(8), r.s(20), r.s(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 14, height: 2, decoration: BoxDecoration(color: _Palette.peach, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: _Palette.peach.withOpacity(0.4), blurRadius: 6)])),
                      SizedBox(width: r.s(8)),
                      Text('МОИ ЦЕЛИ', style: GoogleFonts.inter(color: _Palette.peach, fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                    ],
                  ),
                  SizedBox(height: r.s(4)),
                  Text('Цели', style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(28), fontWeight: FontWeight.w600, letterSpacing: -0.7)),
                  SizedBox(height: r.s(2)),
                  Text('${provider.targets.length} ${_plural(provider.targets.length, "цель", "цели", "целей")}', style: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(13))),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(12)),
              child: Container(
                padding: EdgeInsets.all(r.s(3)),
                decoration: BoxDecoration(color: _Palette.divider.withOpacity(0.3), borderRadius: BorderRadius.circular(r.s(14))),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: _Palette.textMuted,
                  indicator: BoxDecoration(color: _Palette.peach, borderRadius: BorderRadius.circular(r.s(11)), boxShadow: [BoxShadow(color: _Palette.peach.withOpacity(0.20), blurRadius: 8, spreadRadius: -2, offset: const Offset(0, 2))]),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w900, letterSpacing: 0.6),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  tabs: [Tab(text: 'АКТИВНЫЕ ${active.length}'), Tab(text: 'ГОТОВО ${completed.length}'), Tab(text: 'АРХИВ ${other.length}')],
                ),
              ),
            ),
          ),

          SliverFillRemaining(
            hasScrollBody: true,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTargetsList(r, active, provider, emptyMessage: 'НЕТ АКТИВНЫХ', emptyHint: 'Поставьте первую цель'),
                _buildTargetsList(r, completed, provider, emptyMessage: 'НИЧЕГО НЕ ДОСТИГНУТО', emptyHint: 'Продолжайте тренироваться'),
                _buildTargetsList(r, other, provider, emptyMessage: 'АРХИВ ПУСТ', emptyHint: 'Приостановленные цели появятся здесь'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetsList(_R r, List<FitnessTarget> targets, FitnessProvider provider, {required String emptyMessage, required String emptyHint}) {
    if (targets.isEmpty) return _buildEmptyState(r, emptyMessage, emptyHint);
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), 40),
      itemCount: targets.length,
      itemBuilder: (context, index) => _buildTargetCard(r, targets[index], provider),
    );
  }

  Widget _buildEmptyState(_R r, String title, String hint) {
    return Padding(
      padding: EdgeInsets.all(r.s(40)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: r.s(96), height: r.s(96),
            decoration: BoxDecoration(gradient: RadialGradient(colors: [_Palette.peach.withOpacity(0.20), _Palette.peach.withOpacity(0.05)]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: _Palette.peach.withOpacity(0.18), blurRadius: 16)]),
            child: Icon(Icons.flag_rounded, size: r.s(42), color: _Palette.peach),
          ),
          SizedBox(height: r.s(20)),
          Text('ЦЕЛИ', style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w900, letterSpacing: 2.2, color: _Palette.peach)),
          SizedBox(height: r.s(4)),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: r.fs(20), fontWeight: FontWeight.w600, letterSpacing: -0.6, color: _Palette.text)),
          SizedBox(height: r.s(8)),
          Text(hint, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: r.fs(13), height: 1.4, color: _Palette.textMuted)),
        ],
      ),
    );
  }

  Widget _buildTargetCard(_R r, FitnessTarget target, FitnessProvider provider) {
    final progress = target.progressPercent;
    final isCompleted = target.status == FitnessTargetStatus.completed;
    final isPaused = target.status == FitnessTargetStatus.paused;
    final exercise = _resolveExercise(provider, target.exerciseId);
    final accent = isCompleted ? _Palette.green : target.accentColor;
    final coverAccent = isPaused ? _Palette.textMuted : accent;

    return _TapScale(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: provider, child: FitnessTargetDetailsScreen(target: target, isDark: false))));
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showTargetOptions(context, target, provider, r);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: r.s(12)),
        decoration: BoxDecoration(
          color: isPaused ? _Palette.divider.withOpacity(0.2) : _Palette.surface,
          borderRadius: BorderRadius.circular(r.s(20)),
          border: Border.all(color: _Palette.divider, width: 1),
          boxShadow: isPaused ? null : [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 22, spreadRadius: -6, offset: const Offset(0, 10))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: r.s(170),
              child: _ExerciseCover(
                exercise: exercise,
                fallbackEmoji: target.type.emoji,
                accent: coverAccent,
                contentBuilder: (context) => Padding(
                  padding: EdgeInsets.all(r.s(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: r.s(9), vertical: r.s(5)),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.94), borderRadius: BorderRadius.circular(r.s(8))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [Text(target.type.emoji, style: TextStyle(fontSize: r.fs(10))), SizedBox(width: r.s(4)), Text(target.type.displayName.toUpperCase(), style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(8), fontWeight: FontWeight.w900, letterSpacing: 1.0, height: 1))],
                            ),
                          ),
                          const Spacer(),
                          if (isCompleted)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: r.s(9), vertical: r.s(5)),
                              decoration: BoxDecoration(color: _Palette.green, borderRadius: BorderRadius.circular(r.s(8)), boxShadow: [BoxShadow(color: _Palette.green.withOpacity(0.4), blurRadius: 8)]),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.emoji_events_rounded, color: Colors.white, size: 11), SizedBox(width: 4), Text('ГОТОВО', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0, height: 1))]),
                            )
                          else if (target.deadline != null)
                            _buildDeadlineChipOnCover(r, target),
                        ],
                      ),
                      const Spacer(),
                      Text(target.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontSize: r.fs(20), fontWeight: FontWeight.w600, letterSpacing: -0.6, height: 1.15)),
                      if (target.description.isNotEmpty) ...[
                        SizedBox(height: r.s(4)),
                        Text(target.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: r.fs(11), fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(r.s(16)),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(target.formattedCurrent, style: GoogleFonts.inter(fontSize: r.fs(30), fontWeight: FontWeight.w600, letterSpacing: -1.2, height: 1, color: isCompleted ? _Palette.green : isPaused ? _Palette.textMuted : target.accentColor, fontFeatures: const [FontFeature.tabularFigures()]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(width: r.s(4)),
                      Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(target.unit, style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w600, letterSpacing: -0.3, color: _Palette.textMuted))),
                      const Spacer(),
                      Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('ИЗ ${target.formattedTarget}', style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0, color: _Palette.textMuted, fontFeatures: const [FontFeature.tabularFigures()]))),
                    ],
                  ),
                  SizedBox(height: r.s(12)),
                  _GlossyProgress(
                    value: progress,
                    height: r.s(6),
                    gradient: [isCompleted ? _Palette.green.withOpacity(0.75) : (isPaused ? _Palette.textMuted.withOpacity(0.75) : target.accentColor.withOpacity(0.75)), isCompleted ? _Palette.green : (isPaused ? _Palette.textMuted : target.accentColor)],
                    track: _Palette.divider.withOpacity(0.5),
                    radius: r.s(5),
                  ),
                  SizedBox(height: r.s(8)),
                  Row(
                    children: [
                      Text('${(progress * 100).toInt()}% ВЫПОЛНЕНО', style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 1.0, color: isCompleted ? _Palette.green : _Palette.textMuted, fontFeatures: const [FontFeature.tabularFigures()])),
                      const Spacer(),
                      Text('ОСТАЛОСЬ ${target.formattedRemaining}', style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w700, letterSpacing: 0.8, color: _Palette.textMuted, fontFeatures: const [FontFeature.tabularFigures()])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineChipOnCover(_R r, FitnessTarget target) {
    final days = target.daysUntilDeadline ?? 0;
    final isOverdue = target.isOverdue;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(9), vertical: r.s(5)),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(r.s(9)), border: Border.all(color: Colors.white.withOpacity(0.20), width: 0.6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOverdue ? Icons.warning_rounded : Icons.schedule_rounded, size: r.s(11), color: isOverdue ? const Color(0xFFFFD0D0) : Colors.white.withOpacity(0.9)),
          SizedBox(width: r.s(4)),
          Text(isOverdue ? 'ПРОСРОЧЕНО' : '$days ДН.', style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w900, letterSpacing: 0.6, height: 1, color: isOverdue ? const Color(0xFFFFD0D0) : Colors.white, fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  void _showCreateTargetSheet(BuildContext context, FitnessProvider provider, _R r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28)))),
          child: _TargetBuilderSheet(provider: provider, r: r),
        ),
      ),
    );
  }

  void _showTargetOptions(BuildContext context, FitnessTarget target, FitnessProvider provider, _R r) {
    final isActive = target.status == FitnessTargetStatus.active;
    final isPaused = target.status == FitnessTargetStatus.paused;
    final isCompleted = target.status == FitnessTargetStatus.completed;
    final exercise = _resolveExercise(provider, target.exerciseId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              Row(
                children: [
                  _ExerciseThumb(exercise: exercise, fallbackEmoji: target.type.emoji, size: r.s(48), radius: r.s(12), accent: target.accentColor),
                  SizedBox(width: r.s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(target.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: r.fs(17), fontWeight: FontWeight.w600, letterSpacing: -0.4, height: 1.1, color: _Palette.text)),
                        SizedBox(height: r.s(3)),
                        Text('${target.formattedCurrent} / ${target.formattedTarget} ${target.unit}', style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w600, letterSpacing: -0.2, color: target.accentColor, fontFeatures: const [FontFeature.tabularFigures()])),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.s(20)),
              _buildMenuItem(r, icon: Icons.analytics_rounded, iconColor: target.accentColor, iconBg: target.accentColor.withOpacity(0.12), title: 'Открыть детали', subtitle: 'График, история, прогноз', onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: provider, child: FitnessTargetDetailsScreen(target: target, isDark: false))));
              }),
              if (isActive) _buildMenuItem(r, icon: Icons.emoji_events_rounded, iconColor: _Palette.green, iconBg: _Palette.greenSoft, title: 'Отметить достигнутой', onTap: () { Navigator.pop(ctx); provider.completeTarget(target.id); }),
              if (isActive) _buildMenuItem(r, icon: Icons.pause_circle_outline_rounded, iconColor: _Palette.peach, iconBg: _Palette.peachSoft, title: 'Приостановить', onTap: () { Navigator.pop(ctx); provider.pauseTarget(target.id); }),
              if (isPaused) _buildMenuItem(r, icon: Icons.play_circle_outline_rounded, iconColor: _Palette.green, iconBg: _Palette.greenSoft, title: 'Возобновить', onTap: () { Navigator.pop(ctx); provider.resumeTarget(target.id); }),
              if (!isCompleted) _buildMenuItem(r, icon: Icons.delete_outline_rounded, iconColor: _Palette.pink, iconBg: _Palette.pinkSoft, title: 'Удалить', destructive: true, onTap: () { Navigator.pop(ctx); _confirmDeleteTarget(context, target, provider, r); }),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTarget(BuildContext context, FitnessTarget target, FitnessProvider provider, _R r) {
    showDialog(
      context: context,
      builder: (ctx) => _IosDialog(r: r, title: 'Удалить цель?', message: '«${target.name}» будет удалена', onDestructive: () {
        HapticFeedback.mediumImpact();
        Navigator.pop(ctx, true);
        provider.deleteTarget(target.id);
      }),
    );
  }

  Widget _buildMenuItem(_R r, {required IconData icon, required Color iconColor, required Color iconBg, required String title, String? subtitle, bool destructive = false, required VoidCallback onTap}) {
    return _TapScale(
      onTap: onTap, scale: 0.98,
      child: Container(
        margin: EdgeInsets.only(bottom: r.s(8)),
        padding: EdgeInsets.all(r.s(12)),
        decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(14))),
        child: Row(
          children: [
            Container(width: r.s(40), height: r.s(40), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(r.s(10))), child: Icon(icon, color: iconColor, size: r.s(19))),
            SizedBox(width: r.s(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, letterSpacing: -0.2, color: destructive ? _Palette.pink : _Palette.text)),
                  if (subtitle != null) ...[SizedBox(height: r.s(2)), Text(subtitle, style: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w500, color: _Palette.textMuted))],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _Palette.textMuted, size: r.s(20)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DIALOGS & SHEETS
// ═══════════════════════════════════════════════════════════════════
class _IosDialog extends StatelessWidget {
  const _IosDialog({required this.r, required this.title, required this.message, required this.onDestructive, this.cancelLabel = 'Отмена', this.destructiveLabel = 'Удалить'});
  final _R r; final String title; final String message; final VoidCallback onDestructive; final String cancelLabel; final String destructiveLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: r.s(60)),
      child: Container(
        decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(14))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: EdgeInsets.all(r.s(20)), child: Column(children: [Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: r.fs(17), fontWeight: FontWeight.w600, color: _Palette.text)), SizedBox(height: r.s(6)), Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: r.fs(13), color: _Palette.textMuted, height: 1.4))])),
            Container(height: 0.5, color: _Palette.divider),
            Row(
              children: [
                Expanded(child: _TapScale(onTap: () => Navigator.pop(context), scale: 0.96, child: Container(padding: EdgeInsets.symmetric(vertical: r.s(14)), alignment: Alignment.center, child: Text(cancelLabel, style: GoogleFonts.inter(fontSize: r.fs(17), fontWeight: FontWeight.w500, color: _Palette.peach))))),
                Container(width: 0.5, height: 50, color: _Palette.divider),
                Expanded(child: _TapScale(onTap: onDestructive, scale: 0.96, child: Container(padding: EdgeInsets.symmetric(vertical: r.s(14)), alignment: Alignment.center, child: Text(destructiveLabel, style: GoogleFonts.inter(fontSize: r.fs(17), fontWeight: FontWeight.w600, color: _Palette.pink))))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetBuilderSheet extends StatefulWidget {
  final FitnessProvider provider;
  final _R r;
  const _TargetBuilderSheet({required this.provider, required this.r});

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
  Color _selectedColor = _Palette.peach;
  String? _measurement;

  static const _colors = [_Palette.peach, _Palette.green, _Palette.sage, _Palette.pink, _Palette.yellow];

  @override
  void dispose() {
    _nameController.dispose(); _descController.dispose(); _valueController.dispose(); _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final r = widget.r;
    final templates = provider.getTargetTemplates();
    final showRepsField = _type == FitnessTargetType.strengthReps;
    final showExercisePicker = _type.requiresExercise;
    final showMeasurementPicker = _type.requiresMeasurement;

    return Column(
      children: [
        Container(width: r.s(36), height: r.s(5), margin: EdgeInsets.only(top: r.s(12)), decoration: BoxDecoration(color: _Palette.divider, borderRadius: BorderRadius.circular(r.s(3)))),
        Padding(
          padding: EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), 0),
          child: Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('НОВАЯ ЦЕЛЬ', style: GoogleFonts.inter(color: _Palette.peach, fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.4)), SizedBox(height: r.s(2)), Text('Создать', style: GoogleFonts.inter(fontSize: r.fs(26), fontWeight: FontWeight.w600, letterSpacing: -0.9, height: 1.1, color: _Palette.text))])),
              _TapScale(onTap: () => Navigator.pop(context), scale: 0.9, child: Container(width: r.s(36), height: r.s(36), decoration: BoxDecoration(color: _Palette.divider.withOpacity(0.3), shape: BoxShape.circle), child: Icon(Icons.close_rounded, color: _Palette.text, size: r.s(20)))),
            ],
          ),
        ),
        SizedBox(height: r.s(20)),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(32)),
            children: [
              if (templates.isNotEmpty) ...[
                _buildSectionLabel(r, 'ШАБЛОНЫ'), SizedBox(height: r.s(10)),
                SizedBox(height: r.s(168), child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: templates.length, separatorBuilder: (_, __) => SizedBox(width: r.s(10)), itemBuilder: (ctx, i) => _buildTemplateChip(r, templates[i]))),
                SizedBox(height: r.s(24)),
              ],
              _buildSectionLabel(r, 'ТИП ЦЕЛИ'), SizedBox(height: r.s(10)),
              Wrap(spacing: r.s(6), runSpacing: r.s(6), children: FitnessTargetType.values.map((type) {
                final isSelected = type == _type;
                return _TapScale(
                  onTap: () { setState(() { _type = type; if (!type.requiresExercise) _selectedExercise = null; if (!type.requiresMeasurement) _measurement = null; }); },
                  scale: 0.96,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(8)),
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedColor.withOpacity(0.14) : _Palette.bg,
                      borderRadius: BorderRadius.circular(r.s(10)),
                      border: Border.all(color: isSelected ? _selectedColor : _Palette.divider, width: 1.2),
                      boxShadow: isSelected ? [BoxShadow(color: _selectedColor.withOpacity(0.25), blurRadius: 8)] : null,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Text(type.emoji, style: TextStyle(fontSize: r.fs(13))), SizedBox(width: r.s(4)), Text(type.displayName, style: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w800, letterSpacing: -0.1, color: isSelected ? _selectedColor : _Palette.text))]),
                  ),
                );
              }).toList()),
              SizedBox(height: r.s(20)),
              _buildField(r, controller: _nameController, label: 'НАЗВАНИЕ', hint: _hintName(_type)),
              SizedBox(height: r.s(12)),
              _buildField(r, controller: _descController, label: 'ОПИСАНИЕ', hint: 'Опционально', maxLines: 2),
              if (showExercisePicker) ...[
                SizedBox(height: r.s(20)), _buildSectionLabel(r, 'УПРАЖНЕНИЕ'), SizedBox(height: r.s(10)),
                _TapScale(
                  onTap: () => _pickExercise(context, r), scale: 0.98,
                  child: Container(
                    padding: EdgeInsets.all(r.s(12)),
                    decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(12)), border: Border.all(color: _Palette.divider, width: 0.5)),
                    child: Row(
                      children: [
                        _ExerciseThumb(exercise: _selectedExercise, fallbackEmoji: _defaultExerciseEmoji(_type), size: r.s(36), radius: r.s(10), accent: _selectedColor),
                        SizedBox(width: r.s(10)),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_selectedExercise?.name ?? 'Выбрать упражнение', style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, letterSpacing: -0.2, color: _selectedExercise != null ? _Palette.text : _Palette.textMuted)), if (_selectedExercise != null) Text(_selectedExercise!.muscleGroups.map((m) => m.displayName).join(' • '), style: GoogleFonts.inter(fontSize: r.fs(10), fontWeight: FontWeight.w500, color: _Palette.textMuted))])),
                        Icon(Icons.chevron_right_rounded, color: _Palette.textMuted, size: r.s(20)),
                      ],
                    ),
                  ),
                ),
              ],
              if (showMeasurementPicker) ...[
                SizedBox(height: r.s(20)), _buildSectionLabel(r, 'ОБХВАТ'), SizedBox(height: r.s(10)),
                Wrap(spacing: r.s(6), runSpacing: r.s(6), children: [('chest', 'Грудь'), ('waist', 'Талия'), ('hips', 'Бёдра'), ('biceps', 'Бицепс'), ('thigh', 'Бедро'), ('calf', 'Икра'), ('neck', 'Шея'), ('forearm', 'Предплечье')].map((m) {
                  final isSelected = _measurement == m.$1;
                  return _TapScale(
                    onTap: () => setState(() => _measurement = m.$1), scale: 0.96,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(8)),
                      decoration: BoxDecoration(color: isSelected ? _selectedColor.withOpacity(0.14) : _Palette.bg, borderRadius: BorderRadius.circular(r.s(10)), border: Border.all(color: isSelected ? _selectedColor : _Palette.divider, width: 1.2)),
                      child: Text(m.$2, style: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w800, letterSpacing: -0.1, color: isSelected ? _selectedColor : _Palette.text)),
                    ),
                  );
                }).toList()),
              ],
              SizedBox(height: r.s(20)),
              _buildSectionLabel(r, 'ЦЕЛЕВОЕ ЗНАЧЕНИЕ'), SizedBox(height: r.s(10)),
              Row(children: [Expanded(child: _buildValueField(r, controller: _valueController, suffix: _type.defaultUnit)), if (showRepsField) ...[SizedBox(width: r.s(10)), SizedBox(width: r.s(100), child: _buildValueField(r, controller: _repsController, suffix: 'повт', hint: '10'))]]),
              SizedBox(height: r.s(20)),
              _buildSectionLabel(r, 'ДЕДЛАЙН'), SizedBox(height: r.s(10)),
              Row(
                children: [
                  Expanded(child: _TapScale(onTap: _pickDeadline, scale: 0.98, child: Container(padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(12)), decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(12)), border: Border.all(color: _Palette.divider, width: 0.5)), child: Row(children: [Icon(Icons.calendar_today_rounded, size: r.s(16), color: _Palette.textMuted), SizedBox(width: r.s(10)), Text(_deadline != null ? '${_deadline!.day.toString().padLeft(2, '0')}.${_deadline!.month.toString().padLeft(2, '0')}.${_deadline!.year}' : 'Опционально', style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, color: _deadline != null ? _Palette.text : _Palette.textMuted, fontFeatures: const [FontFeature.tabularFigures()]))])))),
                  if (_deadline != null) ...[SizedBox(width: r.s(8)), _TapScale(onTap: () => setState(() => _deadline = null), scale: 0.9, child: Container(width: r.s(44), height: r.s(44), decoration: BoxDecoration(color: _Palette.pinkSoft, borderRadius: BorderRadius.circular(r.s(10))), child: const Icon(Icons.close_rounded, color: _Palette.pink, size: 18)))],
                ],
              ),
              SizedBox(height: r.s(20)),
              _buildSectionLabel(r, 'АКЦЕНТНЫЙ ЦВЕТ'), SizedBox(height: r.s(10)),
              Wrap(spacing: r.s(10), runSpacing: r.s(10), children: _colors.map((c) {
                final isSelected = c.value == _selectedColor.value;
                return _TapScale(
                  onTap: () => setState(() => _selectedColor = c), scale: 0.9,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180), width: r.s(40), height: r.s(40),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: isSelected ? Border.all(color: _Palette.surface, width: 2.5) : null, boxShadow: [BoxShadow(color: c.withOpacity(isSelected ? 0.5 : 0.25), blurRadius: 8)]),
                    child: isSelected ? Icon(Icons.check_rounded, color: Colors.white, size: r.s(20)) : null,
                  ),
                );
              }).toList()),
              SizedBox(height: r.s(32)),
              SizedBox(
                width: double.infinity, height: r.s(56),
                child: ElevatedButton(
                  onPressed: () => _createTarget(provider, r),
                  style: ElevatedButton.styleFrom(backgroundColor: _selectedColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(14))), shadowColor: _selectedColor.withOpacity(0.4)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.flag_rounded, size: r.s(22)), SizedBox(width: r.s(8)), Text('СОЗДАТЬ ЦЕЛЬ', style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w900, letterSpacing: 1.2))]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _hintName(FitnessTargetType type) {
    switch (type) {
      case FitnessTargetType.strengthMax: return 'Например: Жим 100 кг';
      case FitnessTargetType.strengthReps: return 'Например: Жим 50×50';
      case FitnessTargetType.bodyweightReps: return 'Например: 10 подтягиваний';
      case FitnessTargetType.cardioDistance: return 'Например: Пробежать 10 км';
      case FitnessTargetType.cardioTime: return 'Например: 5 км за 25 мин';
      case FitnessTargetType.endurance: return 'Например: Планка 3 мин';
      case FitnessTargetType.bodyMeasurement: return 'Например: Бицепс 40 см';
      case FitnessTargetType.bodyWeight: return 'Например: Похудеть до 75 кг';
      case FitnessTargetType.volume: return 'Например: 10 тонн за тренировку';
      case FitnessTargetType.custom: return 'Своя цель';
      case FitnessTargetType.boxingRounds: return 'Например: 100 раундов';
      case FitnessTargetType.holdTime: return 'Например: Планка 3 минуты';
    }
  }

  String _defaultExerciseEmoji(FitnessTargetType type) {
    switch (type) {
      case FitnessTargetType.boxingRounds: return '🥊';
      case FitnessTargetType.holdTime: return '🧘';
      case FitnessTargetType.bodyweightReps: return '🤸';
      case FitnessTargetType.endurance: return '⚡';
      default: return '🏋️';
    }
  }

  List<ExerciseType> _allowedExerciseTypes(FitnessTargetType type) {
    switch (type) {
      case FitnessTargetType.boxingRounds: return [ExerciseType.boxing];
      case FitnessTargetType.holdTime: return [ExerciseType.yoga, ExerciseType.bodyweight];
      case FitnessTargetType.bodyweightReps: return [ExerciseType.bodyweight];
      case FitnessTargetType.endurance: return [ExerciseType.bodyweight, ExerciseType.cardio, ExerciseType.yoga];
      case FitnessTargetType.strengthMax: case FitnessTargetType.strengthReps: return [ExerciseType.strength];
      case FitnessTargetType.cardioDistance: case FitnessTargetType.cardioTime: return [ExerciseType.cardio];
      default: return ExerciseType.values;
    }
  }

  Widget _buildSectionLabel(_R r, String text) {
    return Padding(padding: EdgeInsets.only(left: r.s(2)), child: Text(text, style: GoogleFonts.inter(fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _Palette.textMuted)));
  }

  Widget _buildField(_R r, {required TextEditingController controller, required String label, required String hint, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionLabel(r, label), SizedBox(height: r.s(6)),
      TextField(controller: controller, maxLines: maxLines, style: GoogleFonts.inter(fontSize: r.fs(15), fontWeight: FontWeight.w600, color: _Palette.text), decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(14), fontWeight: FontWeight.w500), filled: true, fillColor: _Palette.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(12)), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(12)), borderSide: BorderSide(color: _Palette.divider, width: 0.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(12)), borderSide: BorderSide(color: _Palette.peach, width: 1.5)), contentPadding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(12)))),
    ]);
  }

  Widget _buildValueField(_R r, {required TextEditingController controller, required String suffix, String? hint}) {
    return TextField(
      controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.inter(fontSize: r.fs(22), fontWeight: FontWeight.w600, letterSpacing: -0.8, color: _Palette.text, fontFeatures: const [FontFeature.tabularFigures()]),
      decoration: InputDecoration(hintText: hint ?? '0', hintStyle: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(22), fontWeight: FontWeight.w600, letterSpacing: -0.8), suffixText: suffix, suffixStyle: GoogleFonts.inter(fontSize: r.fs(12), fontWeight: FontWeight.w600, color: _Palette.textMuted), filled: true, fillColor: _Palette.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(12)), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(12)), borderSide: BorderSide(color: _Palette.divider, width: 0.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r.s(12)), borderSide: BorderSide(color: _Palette.peach, width: 1.5)), contentPadding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(16))),
    );
  }

  Widget _buildTemplateChip(_R r, FitnessTarget t) {
    Exercise? exercise;
    if (t.exerciseId != null && t.exerciseId!.isNotEmpty) { try { exercise = widget.provider.exercises.firstWhere((e) => e.id == t.exerciseId); } catch (_) {} }
    return _TapScale(
      onTap: () {
        _nameController.text = t.name; _descController.text = t.description; _valueController.text = t.targetValue.toString();
        setState(() {
          _type = t.type; _selectedColor = _nearestPowerColor(t.accentColor);
          if (t.exerciseId != null) { try { _selectedExercise = widget.provider.exercises.firstWhere((e) => e.id == t.exerciseId); } catch (_) { _selectedExercise = null; } } else { _selectedExercise = null; }
          if (t.extra.containsKey('measurement')) { _measurement = t.extra['measurement'] as String?; } else { _measurement = null; }
          if (t.extra.containsKey('reps')) { _repsController.text = (t.extra['reps'] as int).toString(); } else { _repsController.text = '10'; }
        });
      }, scale: 0.97,
      child: Container(
        width: r.s(155),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(r.s(14)), boxShadow: [BoxShadow(color: t.accentColor.withOpacity(0.15), blurRadius: 14, spreadRadius: -3, offset: const Offset(0, 6))]),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: r.s(168),
          child: _ExerciseCover(
            exercise: exercise, fallbackEmoji: t.type.emoji, accent: t.accentColor,
            contentBuilder: (context) => Padding(
              padding: EdgeInsets.all(r.s(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: EdgeInsets.symmetric(horizontal: r.s(7), vertical: r.s(4)), decoration: BoxDecoration(color: Colors.white.withOpacity(0.94), borderRadius: BorderRadius.circular(r.s(6))), child: Text(t.type.displayName.toUpperCase(), style: GoogleFonts.inter(color: _Palette.text, fontSize: r.fs(8), fontWeight: FontWeight.w900, letterSpacing: 0.8, height: 1))),
                const Spacer(),
                Text(t.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: r.fs(13), fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.2, color: Colors.white)),
                SizedBox(height: r.s(4)),
                Text('${t.formattedTarget} ${t.unit}', style: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w700, letterSpacing: 0.2, color: Colors.white.withOpacity(0.85), fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Color _nearestPowerColor(Color original) {
    final hsv = HSVColor.fromColor(original);
    if (hsv.hue >= 20 && hsv.hue < 60) return _Palette.peach;
    if (hsv.hue >= 60 && hsv.hue < 150) return _Palette.green;
    if (hsv.hue >= 150 && hsv.hue < 200) return _Palette.sage;
    if (hsv.hue >= 200 && hsv.hue < 280) return _Palette.pink;
    return _Palette.peach;
  }

  Future<void> _pickExercise(BuildContext context, _R r) async {
    final allowedTypes = _allowedExerciseTypes(_type);
    final filtered = widget.provider.exercises.where((e) => allowedTypes.contains(e.exerciseType)).toList();
    final result = await showModalBottomSheet<Exercise>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(height: MediaQuery.of(context).size.height * 0.75, decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28)))), child: _ExercisePickerSheet(exercises: filtered.isEmpty ? widget.provider.exercises : filtered, r: r)),
    );
    if (result != null) setState(() => _selectedExercise = result);
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(context: context, initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 3)));
    if (date != null) setState(() => _deadline = date);
  }

  void _createTarget(FitnessProvider provider, _R r) {
    final name = _nameController.text.trim();
    final value = double.tryParse(_valueController.text) ?? 0;
    if (name.isEmpty) { HapticFeedback.mediumImpact(); _snack(r, 'Введите название цели', _Palette.pink); return; }
    if (value <= 0) { HapticFeedback.mediumImpact(); _snack(r, 'Введите целевое значение', _Palette.pink); return; }
    if (_type.requiresExercise && _selectedExercise == null) { HapticFeedback.mediumImpact(); _snack(r, 'Выберите упражнение', _Palette.pink); return; }
    if (_type.requiresMeasurement && _measurement == null) { HapticFeedback.mediumImpact(); _snack(r, 'Выберите обхват', _Palette.pink); return; }

    final extra = <String, dynamic>{};
    if (_type == FitnessTargetType.strengthReps) extra['reps'] = int.tryParse(_repsController.text) ?? 10;
    if (_measurement != null) extra['measurement'] = _measurement;

    double startValue = 0;
    if (_type == FitnessTargetType.bodyWeight) startValue = provider.profile?.currentWeight ?? 0;

    final target = FitnessTarget(id: const Uuid().v4(), name: name, description: _descController.text.trim(), type: _type, exerciseId: _selectedExercise?.id, targetValue: value, startValue: startValue, currentValue: startValue, unit: _type.defaultUnit, deadline: _deadline, accentColor: _selectedColor, extra: extra);
    provider.addTarget(target);
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    _snack(r, 'Цель «$name» создана', _selectedColor);
  }

  void _snack(_R r, String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(12)))));
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  final List<Exercise> exercises;
  final _R r;
  const _ExercisePickerSheet({required this.exercises, required this.r});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final filtered = widget.exercises.where((e) => _query.isEmpty || e.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      children: [
        Container(width: r.s(36), height: r.s(5), margin: EdgeInsets.only(top: r.s(12)), decoration: BoxDecoration(color: _Palette.divider, borderRadius: BorderRadius.circular(r.s(3)))),
        Padding(padding: EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), r.s(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ВЫБОР УПРАЖНЕНИЯ', style: GoogleFonts.inter(color: _Palette.peach, fontSize: r.fs(9), fontWeight: FontWeight.w800, letterSpacing: 1.4)), SizedBox(height: r.s(2)), Text('Упражнения', style: GoogleFonts.inter(fontSize: r.fs(22), fontWeight: FontWeight.w600, letterSpacing: -0.7, color: _Palette.text))])),
        Padding(padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(12)), child: Container(decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(r.s(12)), border: Border.all(color: _Palette.divider, width: 0.5)), child: TextField(onChanged: (v) => setState(() => _query = v), style: GoogleFonts.inter(fontSize: r.fs(15), fontWeight: FontWeight.w600, color: _Palette.text), decoration: InputDecoration(hintText: 'Поиск…', hintStyle: GoogleFonts.inter(color: _Palette.textMuted, fontSize: r.fs(15), fontWeight: FontWeight.w500), prefixIcon: Icon(Icons.search_rounded, color: _Palette.textMuted, size: r.s(20)), filled: false, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(12)))))),
        Expanded(child: ListView.builder(physics: const BouncingScrollPhysics(), padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(24)), itemCount: filtered.length, itemBuilder: (ctx, i) {
          final ex = filtered[i];
          final accent = ex.muscleGroups.isNotEmpty ? ex.muscleGroups.first.color : _Palette.peach;
          return _TapScale(
            onTap: () => Navigator.pop(context, ex), scale: 0.98,
            child: Container(
              margin: EdgeInsets.only(bottom: r.s(8)), padding: EdgeInsets.all(r.s(12)),
              decoration: BoxDecoration(color: _Palette.surface, borderRadius: BorderRadius.circular(r.s(14)), border: Border.all(color: _Palette.divider, width: 0.5), boxShadow: [BoxShadow(color: accent.withOpacity(0.06), blurRadius: 12, spreadRadius: -3, offset: const Offset(0, 4))]),
              child: Row(
                children: [
                  _ExerciseThumb(exercise: ex, fallbackEmoji: ex.exerciseType.emoji, size: r.s(44), radius: r.s(10), accent: accent),
                  SizedBox(width: r.s(12)),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(ex.name, style: GoogleFonts.inter(fontSize: r.fs(14), fontWeight: FontWeight.w600, letterSpacing: -0.2, color: _Palette.text), maxLines: 1, overflow: TextOverflow.ellipsis), if (ex.muscleGroups.isNotEmpty) ...[SizedBox(height: r.s(3)), Text(ex.muscleGroups.map((m) => m.displayName).join(' • '), style: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w500, color: _Palette.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)]])),
                  Icon(Icons.chevron_right_rounded, color: _Palette.textMuted, size: r.s(20)),
                ],
              ),
            ),
          );
        })),
      ],
    );
  }
}