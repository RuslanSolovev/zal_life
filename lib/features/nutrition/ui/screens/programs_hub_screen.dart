// features/nutrition/ui/screens/programs_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_program.dart';
import '../../providers/nutrition_provider.dart';
import 'plan_builder_screen.dart';
import 'plan_tracker_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM — «Терракота» (warm editorial)
// ═══════════════════════════════════════════════════════════════════
class _T {
  static const bg          = Color(0xFFF9F5EE);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF2ECE2);
  static const ink         = Color(0xFF2B2420);
  static const inkSoft     = Color(0xFF5C544C);
  static const muted       = Color(0xFF9A8F82);
  static const faint       = Color(0xFFCFC5B8);
  static const terracotta      = Color(0xFFCA6D4E);
  static const terracottaDark  = Color(0xFFA5502F);
  static const terracottaLight = Color(0xFFF7E4DB);
  static const sage        = Color(0xFF7A9678);
  static const sageLight   = Color(0xFFE6EDE2);
  static const mustard     = Color(0xFFD9A83F);
  static const mustardLight= Color(0xFFFCF0D4);
  static const sky         = Color(0xFF6E96B8);
  static const skyLight    = Color(0xFFE3EBF2);
  static const rose        = Color(0xFFC86B7A);
  static const roseLight   = Color(0xFFF7E1E5);
  static const border      = Color(0xFFE8DFD2);
  static const borderStrong= Color(0xFFD9CCB8);
}

TextStyle _display({
  double size = 22,
  FontWeight weight = FontWeight.w600,
  Color color = _T.ink,
  double height = 1.15,
}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: -0.3,
    );

TextStyle _body({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _T.ink,
  double height = 1.4,
}) =>
    GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

TextStyle _mono({
  double size = 11,
  FontWeight weight = FontWeight.w600,
  Color color = _T.muted,
  double letterSpacing = 0.6,
}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );

// ═══════════════════════════════════════════════════════════════════
//  PROGRAMS HUB
// ═══════════════════════════════════════════════════════════════════
class ProgramsHubScreen extends StatefulWidget {
  const ProgramsHubScreen({super.key});

  @override
  State<ProgramsHubScreen> createState() => _ProgramsHubScreenState();
}

class _ProgramsHubScreenState extends State<ProgramsHubScreen> {
  int _selectedIndex = 0; // 0 = Активные, 1 = История

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final activePrograms =
    provider.programs.where((p) => p.isActive).toList();
    final historyPrograms = provider.programs
        .where((p) => !p.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(activePrograms.length,
                      historyPrograms.length),
                  const SizedBox(height: 20),
                  _buildSegmentedControl(
                      activePrograms.length, historyPrograms.length),
                  const SizedBox(height: 20),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _selectedIndex == 0
                          ? _buildList(activePrograms, provider,
                          isActiveTab: true,
                          key: const ValueKey('active'))
                          : _buildList(historyPrograms, provider,
                          isActiveTab: false,
                          key: const ValueKey('history')),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 24,
              child: _FloatingCreateButton(onTap: _openBuilder),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBuilder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanBuilderScreen()),
    );
    if (result == true && mounted) {
      setState(() => _selectedIndex = 0);
      HapticFeedback.lightImpact();
    }
  }

  // ───────────────────────────────────────────────────────────────────
  //  HERO
  // ───────────────────────────────────────────────────────────────────
  Widget _buildHero(int activeCount, int historyCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _circleBtn(Icons.arrow_back_ios_new_rounded,
                      () => Navigator.pop(context)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _T.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _T.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: activeCount > 0
                            ? _T.sage
                            : _T.faint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activeCount > 0
                          ? '$activeCount активн.'
                          : 'нет активных',
                      style: _mono(
                        size: 10,
                        weight: FontWeight.w700,
                        color: activeCount > 0
                            ? _T.sage
                            : _T.muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Программы',
            style: _display(size: 40, weight: FontWeight.w600, height: 1),
          ),
          const SizedBox(height: 10),
          Text(
            'Твой путь к цели',
            style: _body(size: 15, color: _T.muted),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _T.surface,
          shape: BoxShape.circle,
          border: Border.all(color: _T.border, width: 1.2),
        ),
        child: Icon(icon, size: 18, color: _T.ink),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  //  SEGMENTED CONTROL
  // ───────────────────────────────────────────────────────────────────
  Widget _buildSegmentedControl(int activeCount, int historyCount) {
    final width = MediaQuery.of(context).size.width;
    const hPadding = 24.0;
    final segmentWidth = (width - hPadding * 2) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: hPadding),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              left: 4 + _selectedIndex * segmentWidth,
              top: 4,
              bottom: 4,
              width: segmentWidth - 8,
              child: Container(
                decoration: BoxDecoration(
                  color: _T.terracotta,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Row(
              children: [
                _SegmentTab(
                  label: 'Активные',
                  count: activeCount,
                  selected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                  width: segmentWidth,
                ),
                _SegmentTab(
                  label: 'История',
                  count: historyCount,
                  selected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                  width: segmentWidth,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  //  LISTS — карточки во всю ширину экрана (edge-to-edge)
  // ───────────────────────────────────────────────────────────────────
  Widget _buildList(
      List<NutritionProgram> programs,
      NutritionProvider provider, {
        required bool isActiveTab,
        required Key key,
      }) {
    if (programs.isEmpty) {
      return _EmptyState(
          isActiveTab: isActiveTab, onCreate: _openBuilder, key: key);
    }

    return ListView.separated(
      key: key,
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 120),
      itemCount: programs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) {
        final p = programs[i];
        final totalDays = p.endDate.difference(p.startDate).inDays + 1;
        final now = DateTime.now();
        final daysPassed = now.difference(p.startDate).inDays + 1;
        final progress =
        isActiveTab ? (daysPassed / totalDays).clamp(0.0, 1.0) : 1.0;
        final isFinished = now.isAfter(p.endDate);

        return _ProgramCard(
          program: p,
          provider: provider,
          isActiveTab: isActiveTab,
          totalDays: totalDays,
          progress: progress,
          isFinished: isFinished,
          index: i,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SEGMENT TAB
// ═══════════════════════════════════════════════════════════════════
class _SegmentTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final double width;

  const _SegmentTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!selected) HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 52,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: _body(
              size: 14,
              weight: FontWeight.w700,
              color: selected ? Colors.white : _T.muted,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.2)
                        : _T.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$count',
                    style: _mono(
                      size: 10,
                      weight: FontWeight.w700,
                      color: selected ? Colors.white : _T.muted,
                      letterSpacing: 0.4,
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
}

// ═══════════════════════════════════════════════════════════════════
//  PROGRAM CARD — full-bleed панель с сильным скруглением
// ═══════════════════════════════════════════════════════════════════
class _ProgramCard extends StatefulWidget {
  final NutritionProgram program;
  final NutritionProvider provider;
  final bool isActiveTab;
  final int totalDays;
  final double progress;
  final bool isFinished;
  final int index;

  const _ProgramCard({
    required this.program,
    required this.provider,
    required this.isActiveTab,
    required this.totalDays,
    required this.progress,
    required this.isFinished,
    required this.index,
  });

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  bool get isActive => widget.program.isActive;
  bool get isHistory => !widget.isActiveTab;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    const m = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${d.day} ${m[d.month - 1]}';
  }

  Color get _accent =>
      isActive ? _T.sage : (widget.isFinished ? _T.sky : _T.rose);

  String get _statusLabel => isActive
      ? 'АКТИВНАЯ'
      : widget.isFinished
      ? 'ЗАВЕРШЕНА'
      : 'ОТМЕНЕНА';

  @override
  Widget build(BuildContext context) {
    final daysPassed = (widget.progress * widget.totalDays).round();
    final hasBg = (widget.program.backgroundImage ?? '').isNotEmpty;
    final bgImage = widget.program.backgroundImage;

    final card = GestureDetector(
      onTap: isActive ? _openTracker : null,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: hasBg ? _T.surfaceAlt : _T.surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: isActive
                ? _T.terracotta.withOpacity(0.55)
                : _T.border,
            width: isActive ? 1.6 : 1,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: _T.terracotta.withOpacity(0.14),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ]
              : [
            BoxShadow(
              color: _T.ink.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (hasBg)
              Positioned.fill(
                child: Image.asset(
                  bgImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (hasBg)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
            if (isActive)
              Positioned(
                left: 0,
                top: 26,
                bottom: 26,
                child: Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: _T.terracotta,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(hasBg: hasBg),
                  const SizedBox(height: 18),
                  _SegmentedProgressBar(
                    totalDays: widget.totalDays,
                    progress: widget.progress,
                    accent: hasBg ? Colors.white : _accent,
                    pulse: isHistory ? null : _pulse,
                  ),
                  const SizedBox(height: 10),
                  _buildMetaLine(hasBg: hasBg, daysPassed: daysPassed),
                  const SizedBox(height: 18),
                  widget.isActiveTab
                      ? _buildActiveActions(hasBg: hasBg)
                      : _buildHistoryActions(hasBg: hasBg),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isHistory ? 0.72 : 1.0,
      child: card,
    );
  }

  Widget _buildHeader({required bool hasBg}) {
    final p = widget.program;
    final textColor = hasBg ? Colors.white : _T.ink;
    final mutedColor = hasBg ? Colors.white.withOpacity(0.75) : _T.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _statusDot(hasBg: hasBg),
            const SizedBox(width: 10),
            Text(
              _statusLabel,
              style: _mono(
                size: 10,
                weight: FontWeight.w700,
                color: hasBg ? Colors.white : _accent,
                letterSpacing: 1.6,
              ),
            ),
            const Spacer(),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hasBg
                    ? Colors.white.withOpacity(0.18)
                    : _T.surfaceAlt,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#${(widget.index + 1).toString().padLeft(2, '0')}',
                style: _mono(
                  size: 10,
                  weight: FontWeight.w700,
                  color: hasBg ? Colors.white : _T.inkSoft,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          p.name,
          style: _display(
            size: 24,
            weight: FontWeight.w600,
            color: textColor,
            height: 1.15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.local_fire_department_rounded,
                size: 13,
                color: hasBg ? Colors.white.withOpacity(0.85) : _T.terracotta),
            const SizedBox(width: 5),
            Text(
              '${p.targetCalories.round()} ккал/день',
              style: _body(size: 12, color: mutedColor, weight: FontWeight.w600),
            ),
            const SizedBox(width: 14),
            Icon(
              p.mode == ProgramMode.byMeals
                  ? Icons.restaurant_rounded
                  : Icons.all_inclusive_rounded,
              size: 13,
              color: hasBg ? Colors.white.withOpacity(0.85) : _T.sky,
            ),
            const SizedBox(width: 5),
            Text(
              p.mode == ProgramMode.byMeals ? 'По слотам' : 'Свободный',
              style: _body(size: 12, color: mutedColor, weight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusDot({required bool hasBg}) {
    if (isActive) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasBg
                ? Colors.white.withOpacity(0.9)
                : _T.sage,
            boxShadow: [
              BoxShadow(
                color: (hasBg ? Colors.white : _T.sage)
                    .withOpacity(0.5 * (1 - _pulse.value) + 0.2),
                blurRadius: 8 * (1 - _pulse.value) + 4,
              ),
            ],
          ),
        ),
      );
    }
    return Icon(
      widget.isFinished
          ? Icons.check_circle_rounded
          : Icons.cancel_rounded,
      size: 14,
      color: hasBg ? Colors.white : _accent,
    );
  }

  Widget _buildMetaLine({required bool hasBg, required int daysPassed}) {
    final mutedColor = hasBg ? Colors.white.withOpacity(0.75) : _T.muted;

    return Row(
      children: [
        Text(
          isHistory
              ? '${_fmtDate(widget.program.startDate)} — ${_fmtDate(widget.program.endDate)}'
              : 'День $daysPassed',
          style: _mono(
            size: 11,
            weight: FontWeight.w600,
            color: mutedColor,
            letterSpacing: 0.6,
          ),
        ),
        if (isHistory) ...[
          const SizedBox(width: 6),
          Text('·', style: _mono(size: 11, color: mutedColor)),
          const SizedBox(width: 6),
          Text(
            '${widget.totalDays} дней',
            style: _mono(
              size: 11,
              weight: FontWeight.w600,
              color: mutedColor,
              letterSpacing: 0.6,
            ),
          ),
        ] else ...[
          const Spacer(),
          Text(
            'из ${widget.totalDays}',
            style: _mono(
              size: 11,
              weight: FontWeight.w600,
              color: mutedColor,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveActions({required bool hasBg}) {
    return Row(
      children: [
        Expanded(
          child: _PrimaryButton(
            label: 'Открыть',
            icon: Icons.arrow_forward_rounded,
            onTap: _openTracker,
          ),
        ),
        const SizedBox(width: 10),
        _ActionMenu(program: widget.program, provider: widget.provider),
      ],
    );
  }

  Widget _buildHistoryActions({required bool hasBg}) {
    return SizedBox(
      width: double.infinity,
      child: _GhostButton(
        label: 'Возобновить',
        icon: Icons.refresh_rounded,
        onTap: () => _confirmAction(
          context,
          'Возобновить?',
          'Эта программа станет активной, а текущая (если есть) будет автоматически перемещена в историю.',
              () => widget.provider.startProgram(widget.program.id),
        ),
      ),
    );
  }

  void _openTracker() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanTrackerScreen()),
    );
  }

  void _confirmAction(BuildContext context, String title, String message,
      VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _T.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
        Text(title, style: _display(size: 20, weight: FontWeight.w600)),
        content:
        Text(message, style: _body(size: 14, color: _T.inkSoft)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена',
                style: _body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _T.muted)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
              HapticFeedback.mediumImpact();
            },
            style: FilledButton.styleFrom(
              backgroundColor: _T.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            child: Text('Подтвердить',
                style: _body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SEGMENTED PROGRESS BAR
// ═══════════════════════════════════════════════════════════════════
class _SegmentedProgressBar extends StatelessWidget {
  final int totalDays;
  final double progress;
  final Color accent;
  final AnimationController? pulse;

  const _SegmentedProgressBar({
    required this.totalDays,
    required this.progress,
    required this.accent,
    this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final segmentCount = totalDays <= 42 ? totalDays : 42;
    final filled = (progress * segmentCount).round().clamp(0, segmentCount);
    final current = (progress * segmentCount).ceil().clamp(1, segmentCount);

    return Row(
      children: List.generate(segmentCount, (i) {
        final isFilled = i < filled;
        final isCurrent = pulse != null && i == current - 1 && progress < 1.0;

        if (isCurrent) {
          return Expanded(
            child: AnimatedBuilder(
              animation: pulse!,
              builder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Opacity(
                  opacity: 0.55 + 0.45 * pulse!.value,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.4 * pulse!.value),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: isFilled ? accent : accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BUTTONS
// ═══════════════════════════════════════════════════════════════════
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: _T.terracotta,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: _body(
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(width: 8),
                Icon(icon, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GhostButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _T.borderStrong, width: 1.2),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: _T.ink),
                const SizedBox(width: 8),
                Text(label,
                    style: _body(
                        size: 14,
                        weight: FontWeight.w700,
                        color: _T.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FLOATING CREATE BUTTON
// ═══════════════════════════════════════════════════════════════════
class _FloatingCreateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingCreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _T.terracotta,
          boxShadow: [
            BoxShadow(
              color: _T.terracotta.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded,
            color: Colors.white, size: 28),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ACTION MENU
// ═══════════════════════════════════════════════════════════════════
class _ActionMenu extends StatelessWidget {
  final NutritionProgram program;
  final NutritionProvider provider;

  const _ActionMenu({required this.program, required this.provider});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _T.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.more_horiz_rounded,
            color: _T.inkSoft, size: 22),
      ),
      color: _T.surface,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'finish',
          child: _menuRow(Icons.flag_rounded, _T.sage, 'Завершить'),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'cancel',
          child: _menuRow(Icons.close_rounded, _T.rose, 'Отменить',
              color: _T.rose),
        ),
      ],
      onSelected: (value) {
        if (value == 'finish') {
          _confirmAction(
              context,
              'Завершить программу?',
              'Поздравляем! Программа будет перемещена в историю как успешная, а все данные сохранятся.',
                  () => provider.finishProgram(program.id));
        } else if (value == 'cancel') {
          _confirmAction(
              context,
              'Отменить программу?',
              'Программа будет деактивирована и перемещена в историю. Вы сможете возобновить её позже.',
                  () => provider.cancelProgram(program.id));
        }
      },
    );
  }

  Widget _menuRow(IconData icon, Color iconColor, String label,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 12),
        Text(label,
            style: _body(
                size: 14,
                weight: FontWeight.w600,
                color: color ?? _T.ink)),
      ],
    );
  }

  void _confirmAction(BuildContext context, String title, String message,
      VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _T.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
        Text(title, style: _display(size: 20, weight: FontWeight.w600)),
        content:
        Text(message, style: _body(size: 14, color: _T.inkSoft)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена',
                style: _body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _T.muted)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
              HapticFeedback.mediumImpact();
            },
            style: FilledButton.styleFrom(
              backgroundColor: _T.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            child: Text('Подтвердить',
                style: _body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool isActiveTab;
  final VoidCallback onCreate;

  const _EmptyState({
    required this.isActiveTab,
    required this.onCreate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isActiveTab ? _T.terracottaLight : _T.skyLight,
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.center,
              child: Text(
                isActiveTab ? '📓' : '📜',
                style: const TextStyle(fontSize: 44),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              isActiveTab ? 'Пока пусто' : 'История пуста',
              style: _display(size: 24, weight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isActiveTab
                  ? 'Здесь будет жить твой первый план питания. Создай программу — и путь к цели начнётся отсюда.'
                  : 'Завершённые и отменённые программы будут оседать здесь — со всеми своими результатами.',
              style: _body(size: 14, color: _T.muted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (isActiveTab) ...[
              const SizedBox(height: 28),
              _PrimaryButton(
                label: 'Создать программу',
                icon: Icons.add_rounded,
                onTap: onCreate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}