// features/fitness/ui/screens/completed_programs_screen.dart
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/fitness_models.dart';
import '../../../models/enums.dart';
import '../../../providers/fitness_provider.dart';
import 'program_summary_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  Design tokens — Premium Editorial
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const bg           = Color(0xFFF7F4EF);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFFAF7F2);

  static const text          = Color(0xFF1B1815);
  static const textSecondary = Color(0xFF6B655F);
  static const textTertiary  = Color(0xFFA39D96);

  static const border      = Color(0xFFE8E4DD);
  static const borderLight = Color(0xFFF0ECE6);

  static const accent     = Color(0xFFB0553B);
  static const accentSoft = Color(0xFFF5EAE3);

  static const sage       = Color(0xFF4E7059);
  static const sageSoft   = Color(0xFFEAF0EB);
  static const brick      = Color(0xFFA1555A);
  static const brickSoft  = Color(0xFFF3E7E8);
  static const amber      = Color(0xFFB08332);
  static const amberSoft  = Color(0xFFF5EEDE);
  static const slate      = Color(0xFF5B6A7B);
  static const slateSoft  = Color(0xFFEBEFF3);
  static const plum       = Color(0xFF6F5F7E);
  static const plumSoft   = Color(0xFFF0ECF2);
}

class _T {
  static const _feat = <FontFeature>[FontFeature.tabularFigures()];

  static const title = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    letterSpacing: -0.5, height: 1.2, color: _P.text,
  );
  static const subhead = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    letterSpacing: -0.2, height: 1.3, color: _P.text,
  );
  static const body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500,
    letterSpacing: -0.1, height: 1.4, color: _P.text,
  );
  static const caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500,
    letterSpacing: 0, height: 1.35, color: _P.textSecondary,
  );
  static const captionSm = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    letterSpacing: 0, height: 1.3, color: _P.textSecondary,
  );
  static const overline = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600,
    letterSpacing: 1.3, height: 1.2, color: _P.textTertiary,
  );

  static TextStyle num(TextStyle base) => base.copyWith(fontFeatures: _feat);
}

// ═══════════════════════════════════════════════════════════════════

class CompletedProgramsScreen extends StatefulWidget {
  final bool isDark;

  const CompletedProgramsScreen({super.key, required this.isDark});

  @override
  State<CompletedProgramsScreen> createState() =>
      _CompletedProgramsScreenState();
}

class _CompletedProgramsScreenState extends State<CompletedProgramsScreen> {
  String _filter = 'all';

  // ══════════════════════════════════════════════════════════
  //  Helpers
  // ══════════════════════════════════════════════════════════
  ({IconData icon, String label, Color color, Color soft}) _statusInfo(
      ProgramSessionStatus status) {
    switch (status) {
      case ProgramSessionStatus.completed:
        return (
        icon: Icons.check_circle_rounded,
        label: 'ЗАВЕРШЕНА',
        color: _P.sage,
        soft: _P.sageSoft,
        );
      case ProgramSessionStatus.abandoned:
        return (
        icon: Icons.flag_rounded,
        label: 'БРОШЕНА',
        color: _P.brick,
        soft: _P.brickSoft,
        );
      case ProgramSessionStatus.paused:
        return (
        icon: Icons.pause_circle_rounded,
        label: 'ПАУЗА',
        color: _P.amber,
        soft: _P.amberSoft,
        );
      case ProgramSessionStatus.active:
        return (
        icon: Icons.play_circle_rounded,
        label: 'АКТИВНА',
        color: _P.accent,
        soft: _P.accentSoft,
        );
    }
  }

  IconData _iconForMetric(String key) {
    switch (key) {
      case 'kg':
        return Icons.scale_rounded;
      case 'km':
        return Icons.route_rounded;
      case 'rounds':
        return Icons.sports_mma_rounded;
      case 'sec':
        return Icons.schedule_rounded;
      case 'punches':
        return Icons.front_hand_rounded;
      case 'kcal':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.insights_rounded;
    }
  }

  Color _colorForMetric(String key) {
    switch (key) {
      case 'kg':
        return _P.sage;
      case 'km':
        return _P.slate;
      case 'rounds':
        return _P.amber;
      case 'sec':
        return _P.plum;
      case 'punches':
        return _P.brick;
      case 'kcal':
        return _P.accent;
      default:
        return _P.textSecondary;
    }
  }

  String _formatMetricValue(String key, double v) {
    switch (key) {
      case 'kg':
        return v >= 1000
            ? '${(v / 1000).toStringAsFixed(1)} т'
            : '${v.toStringAsFixed(0)} кг';
      case 'km':
        return '${v.toStringAsFixed(v >= 10 ? 1 : 2)} км';
      case 'rounds':
        return '${v.toStringAsFixed(0)} р.';
      case 'sec':
        if (v >= 3600) {
          final h = (v / 3600).floor();
          final m = ((v % 3600) / 60).round();
          return '${h}ч ${m}м';
        }
        return '${(v / 60).toStringAsFixed(0)} мин';
      case 'punches':
        return v.toStringAsFixed(0);
      case 'kcal':
        return '${v.toStringAsFixed(0)} ккал';
      default:
        return v.toStringAsFixed(0);
    }
  }

  ({String value, String label, String key}) _dominantOfTotals(
      Map<String, double> m) {
    if ((m['km'] ?? 0) > 0) {
      return (value: m['km']!.toStringAsFixed(m['km']! >= 10 ? 1 : 2),
      label: 'КМ', key: 'km');
    }
    if ((m['rounds'] ?? 0) > 0) {
      return (value: m['rounds']!.toStringAsFixed(0),
      label: 'РАУНД', key: 'rounds');
    }
    if ((m['kg'] ?? 0) > 0) {
      final kg = m['kg']!;
      return (
      value: kg >= 1000
          ? '${(kg / 1000).toStringAsFixed(1)} т'
          : kg.toStringAsFixed(0),
      label: kg >= 1000 ? 'ТОННАЖ' : 'КГ',
      key: 'kg',
      );
    }
    if ((m['sec'] ?? 0) > 0) {
      final sec = m['sec']!;
      return (
      value: sec >= 3600
          ? (sec / 3600).toStringAsFixed(1)
          : (sec / 60).toStringAsFixed(0),
      label: sec >= 3600 ? 'ЧАС' : 'МИН',
      key: 'sec',
      );
    }
    return (value: '—', label: '—', key: 'other');
  }

  ({String value, String label, String key}) _dominantOfSession(
      ProgramSession session) {
    var m = session.totalByMetricCompleted;
    if (m.isEmpty && session.totalVolumeCompleted > 0) {
      m = {'kg': session.totalVolumeCompleted};
    }
    return _dominantOfTotals(m);
  }

  Map<String, double> _totalMetricAcrossSessions(
      List<ProgramSession> sessions) {
    final result = <String, double>{};
    for (final s in sessions) {
      final m = s.totalByMetricCompleted;
      if (m.isNotEmpty) {
        m.forEach((k, v) => result[k] = (result[k] ?? 0) + v);
      } else if (s.totalVolumeCompleted > 0) {
        result['kg'] = (result['kg'] ?? 0) + s.totalVolumeCompleted;
      }
    }
    return result;
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();

    final allSessions = provider.sessions
        .where((s) => s.status != ProgramSessionStatus.active)
        .toList();

    final filteredSessions = allSessions.where((s) {
      switch (_filter) {
        case 'completed':
          return s.status == ProgramSessionStatus.completed;
        case 'abandoned':
          return s.status == ProgramSessionStatus.abandoned;
        case 'paused':
          return s.status == ProgramSessionStatus.paused;
        default:
          return true;
      }
    }).toList();

    filteredSessions.sort((a, b) => b.startDate.compareTo(a.startDate));

    return Scaffold(
      backgroundColor: _P.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildStatsStrip(provider, allSessions),
          ),
          SliverToBoxAdapter(
            child: _buildFilters(allSessions),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (filteredSessions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                      _buildSessionCard(filteredSessions[index], provider),
                  childCount: filteredSessions.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  APP BAR
  // ══════════════════════════════════════════════════════════
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _P.bg.withOpacity(0.94),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leadingWidth: 56,
      leading: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pop(context);
        },
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.fromLTRB(16, 10, 6, 10),
          decoration: BoxDecoration(
            color: _P.surface,
            shape: BoxShape.circle,
            border: Border.all(color: _P.border, width: 1),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: _P.text,
            size: 22,
          ),
        ),
      ),
      title: Text(
        'История',
        style: _T.subhead.copyWith(fontSize: 16),
      ),
      centerTitle: true,
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STATS STRIP
  // ══════════════════════════════════════════════════════════
  Widget _buildStatsStrip(
      FitnessProvider provider, List<ProgramSession> allSessions) {
    final completedCount = allSessions
        .where((s) => s.status == ProgramSessionStatus.completed)
        .length;

    final totals = _totalMetricAcrossSessions(allSessions);
    final dominant = _dominantOfTotals(totals);

    final totalWorkouts = allSessions.fold<int>(
      0,
          (sum, s) => sum + s.totalWorkoutsCompleted,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _P.border, width: 1),
          bottom: BorderSide(color: _P.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildStatCell('$completedCount', 'ПРОГРАММ'),
          _vDivider(),
          _buildStatCell('$totalWorkouts', 'ТРЕНИРОВОК'),
          _vDivider(),
          _buildStatCell(dominant.value, dominant.label),
        ],
      ),
    );
  }

  Widget _buildStatCell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: _T.num(const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
              height: 1,
              color: _P.text,
            )),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: _T.overline.copyWith(
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 32,
    color: _P.border,
  );

  // ══════════════════════════════════════════════════════════
  //  FILTERS
  // ══════════════════════════════════════════════════════════
  Widget _buildFilters(List<ProgramSession> allSessions) {
    int countOf(String id) {
      switch (id) {
        case 'completed':
          return allSessions
              .where((s) => s.status == ProgramSessionStatus.completed)
              .length;
        case 'abandoned':
          return allSessions
              .where((s) => s.status == ProgramSessionStatus.abandoned)
              .length;
        case 'paused':
          return allSessions
              .where((s) => s.status == ProgramSessionStatus.paused)
              .length;
        default:
          return allSessions.length;
      }
    }

    final filters = [
      {'id': 'all', 'label': 'Все'},
      {'id': 'completed', 'label': 'Завершено'},
      {'id': 'abandoned', 'label': 'Брошено'},
      {'id': 'paused', 'label': 'Пауза'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final id = f['id'] as String;
          final isSelected = _filter == id;
          final count = countOf(id);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filter = id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? _P.text : _P.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? _P.text : _P.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: isSelected ? Colors.white : _P.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: _T.num(TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withOpacity(0.55)
                          : _P.textTertiary,
                    )),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  SESSION CARD  —  FULL-COVER EDITORIAL
  // ══════════════════════════════════════════════════════════
  Widget _buildSessionCard(ProgramSession session, FitnessProvider provider) {
    WorkoutProgram? program;
    try {
      program = provider.programs.firstWhere((p) => p.id == session.programId);
    } catch (_) {
      program = null;
    }

    final programName = program?.name ?? 'Удалённая программа';
    final status = _statusInfo(session.status);
    final duration = session.endDate != null
        ? session.endDate!.difference(session.startDate).inDays
        : DateTime.now().difference(session.startDate).inDays;

    final completedDays = session.daySessions
        .where((d) => d.status == DaySessionStatus.completed)
        .length;
    final totalDays = session.daySessions.length;

    final dominant = _dominantOfSession(session);

    final cover = program?.backgroundImage;
    final hasCover = cover != null && cover.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (session.status == ProgramSessionStatus.completed &&
            program != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: provider,
                child: ProgramSummaryScreen(
                  session: session,
                  program: program!,
                  isDark: false,
                ),
              ),
            ),
          );
        } else {
          _showSessionDetails(session, program);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: _P.text.withOpacity(0.03),
              blurRadius: 14,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───── COVER (full width) ─────
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Изображение / декоративный фон
                  _buildCoverImage(program, hasCover),

                  // 2. Градиент поверх (для читаемости текста)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: hasCover
                            ? [
                          Colors.transparent,
                          Colors.black.withOpacity(0.15),
                          Colors.black.withOpacity(0.72),
                        ]
                            : [
                          Colors.transparent,
                          Colors.transparent,
                        ],
                        stops: hasCover
                            ? const [0.0, 0.5, 1.0]
                            : const [0.0, 1.0],
                      ),
                    ),
                  ),

                  // 3. Бейдж статуса — верхний левый угол
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildStatusBadge(session.status, onCover: hasCover),
                  ),

                  // 4. Название + даты — нижний левый угол
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          programName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _T.subhead.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: hasCover ? Colors.white : _P.text,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatDate(session.startDate)} — '
                              '${session.endDate != null ? _formatDate(session.endDate!) : 'сейчас'}',
                          style: _T.captionSm.copyWith(
                            fontSize: 11,
                            color: hasCover
                                ? Colors.white.withOpacity(0.78)
                                : _P.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ───── BODY ─────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Прогресс — только для завершённых
                  if (session.status == ProgramSessionStatus.completed) ...[
                    Row(
                      children: [
                        Text(
                          'ВЫПОЛНЕНО',
                          style: _T.overline.copyWith(
                            fontSize: 9,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$completedDays / $totalDays',
                          style: _T.num(_T.captionSm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _P.text,
                          )),
                        ),
                        const Spacer(),
                        Text(
                          '${(session.progressPercent * 100).toInt()}%',
                          style: _T.num(TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: status.color,
                          )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: session.progressPercent,
                        backgroundColor: _P.borderLight,
                        valueColor: AlwaysStoppedAnimation(status.color),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Нижняя строка метрик
                  Row(
                    children: [
                      _buildInlineStat(
                        icon: Icons.schedule_rounded,
                        value: '$duration',
                        label: 'дн.',
                      ),
                      const SizedBox(width: 14),
                      _buildInlineStat(
                        icon: Icons.fitness_center_rounded,
                        value: '${session.totalWorkoutsCompleted}',
                        label: 'трен.',
                      ),
                      if (dominant.key != 'other') ...[
                        const SizedBox(width: 14),
                        _buildInlineStat(
                          icon: _iconForMetric(dominant.key),
                          value: dominant.value,
                          label: dominant.label.toLowerCase(),
                        ),
                      ],
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: _P.textTertiary,
                      ),
                    ],
                  ),

                  // Чипы дополнительных метрик
                  if (session.totalByMetricCompleted.length > 1) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: _P.borderLight),
                    const SizedBox(height: 12),
                    _buildMetricChips(session),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  COVER IMAGE
  // ══════════════════════════════════════════════════════════
  Widget _buildCoverImage(WorkoutProgram? program, bool hasCover) {
    if (!hasCover) {
      final emoji = program?.emoji;
      final hasEmoji = emoji != null && emoji.isNotEmpty;
      final initial = (program?.name.isNotEmpty ?? false)
          ? program!.name.trim()[0].toUpperCase()
          : '?';

      // Декоративный «псевдо-cover»: мягкий фон + большой watermark-эмодзи
      return Container(
        color: _P.surfaceMuted,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -50,
              child: hasEmoji
                  ? Text(
                emoji!,
                style: TextStyle(
                  fontSize: 180,
                  color: _P.text.withOpacity(0.035),
                ),
              )
                  : Text(
                initial,
                style: TextStyle(
                  fontSize: 180,
                  fontWeight: FontWeight.w900,
                  color: _P.text.withOpacity(0.035),
                ),
              ),
            ),
            // Маленький бейдж-эмодзи в правом верхнем углу
            if (hasEmoji)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _P.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _P.border, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji!, style: const TextStyle(fontSize: 20)),
                ),
              ),
          ],
        ),
      );
    }

    return _AppImage(
      path: program!.backgroundImage,
      fit: BoxFit.cover,
      fallback: Container(color: _P.surfaceMuted),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  THUMB (для bottom sheet)
  // ══════════════════════════════════════════════════════════
  Widget _buildProgramThumb(WorkoutProgram? program) {
    const size = 40.0;
    const radius = 10.0;

    final bg = program?.backgroundImage;
    final hasBg = bg != null && bg.isNotEmpty;
    final emoji = program?.emoji;
    final hasEmoji = emoji != null && emoji.isNotEmpty;
    final initial = (program?.name.isNotEmpty ?? false)
        ? program!.name.trim()[0].toUpperCase()
        : '?';

    Widget content;
    if (hasBg) {
      content = _AppImage(
        path: bg,
        fit: BoxFit.cover,
        fallback: _thumbFallback(initial),
      );
    } else if (hasEmoji) {
      content = Container(
        color: _P.surfaceMuted,
        alignment: Alignment.center,
        child: Text(emoji!, style: const TextStyle(fontSize: 18)),
      );
    } else {
      content = _thumbFallback(initial);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _P.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _thumbFallback(String initial) {
    return Container(
      color: _P.surfaceMuted,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: _T.num(TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _P.textSecondary,
        )),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  BADGE / STAT / CHIPS
  // ══════════════════════════════════════════════════════════
  Widget _buildStatusBadge(ProgramSessionStatus status,
      {bool onCover = false}) {
    final s = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.soft,
        borderRadius: BorderRadius.circular(6),
        boxShadow: onCover
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 11, color: s.color),
          const SizedBox(width: 4),
          Text(
            s.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: s.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _P.textTertiary),
        const SizedBox(width: 4),
        Text(
          value,
          style: _T.num(_T.captionSm.copyWith(
            fontWeight: FontWeight.w600,
            color: _P.text,
          )),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 3),
          Text(
            label,
            style: _T.captionSm.copyWith(
              fontSize: 10,
              color: _P.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricChips(ProgramSession session) {
    var m = session.totalByMetricCompleted;
    if (m.isEmpty && session.totalVolumeCompleted > 0) {
      m = {'kg': session.totalVolumeCompleted};
    }
    if (m.isEmpty) return const SizedBox.shrink();

    final chips = <Widget>[];

    void addChip(String key) {
      final v = m[key] ?? 0;
      if (v <= 0) return;
      final c = _colorForMetric(key);
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _P.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _P.borderLight, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconForMetric(key), size: 11, color: c),
            const SizedBox(width: 5),
            Text(
              _formatMetricValue(key, v),
              style: _T.num(_T.captionSm.copyWith(
                fontWeight: FontWeight.w600,
                color: _P.text,
              )),
            ),
          ],
        ),
      ));
    }

    addChip('kg');
    addChip('km');
    addChip('rounds');
    addChip('sec');
    addChip('punches');
    addChip('kcal');

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  // ══════════════════════════════════════════════════════════
  //  SESSION DETAILS SHEET
  // ══════════════════════════════════════════════════════════
  void _showSessionDetails(ProgramSession session, WorkoutProgram? program) {
    final s = _statusInfo(session.status);

    var metrics = session.totalByMetricCompleted;
    if (metrics.isEmpty && session.totalVolumeCompleted > 0) {
      metrics = {'kg': session.totalVolumeCompleted};
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _P.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    _buildProgramThumb(program),
                    const SizedBox(width: 12),
                    _buildStatusBadge(session.status),
                  ],
                ),
                const SizedBox(height: 14),

                Text(
                  program?.name ?? 'Удалённая программа',
                  style: _T.title,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(session.startDate)} — '
                      '${session.endDate != null ? _formatDate(session.endDate!) : 'сейчас'}',
                  style: _T.caption.copyWith(color: _P.textTertiary),
                ),

                const SizedBox(height: 22),
                Text('ДЕТАЛИ', style: _T.overline),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _P.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _P.borderLight, width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.calendar_today_rounded,
                        'Дата начала',
                        _formatDate(session.startDate),
                      ),
                      _rowDivider(),
                      _buildDetailRow(
                        Icons.flag_rounded,
                        'Дата конца',
                        session.endDate != null
                            ? _formatDate(session.endDate!)
                            : '—',
                      ),
                      _rowDivider(),
                      _buildDetailRow(
                        Icons.schedule_rounded,
                        'Длительность',
                        '${session.durationDays} дн.',
                      ),
                      _rowDivider(),
                      _buildDetailRow(
                        Icons.fitness_center_rounded,
                        'Тренировок',
                        '${session.totalWorkoutsCompleted}',
                      ),
                      _rowDivider(),
                      _buildDetailRow(
                        Icons.remove_circle_outline_rounded,
                        'Пропущено',
                        '${session.totalWorkoutsSkipped}',
                      ),
                      _rowDivider(),
                      _buildDetailRow(
                        Icons.speed_rounded,
                        'Средний RPE',
                        session.averageRpe > 0
                            ? session.averageRpe.toStringAsFixed(1)
                            : '—',
                      ),
                      _rowDivider(),
                      _buildDetailRow(
                        Icons.local_fire_department_rounded,
                        'Макс. серия',
                        '${session.longestStreak} дн.',
                      ),
                    ],
                  ),
                ),

                if (metrics.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('МЕТРИКИ', style: _T.overline),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _P.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _P.borderLight, width: 1),
                    ),
                    child: Column(
                      children: [
                        ...metrics.entries.map((e) => Column(
                          children: [
                            _buildDetailRow(
                              _iconForMetric(e.key),
                              _metricLabel(e.key),
                              _formatMetricValue(e.key, e.value),
                            ),
                            if (e != metrics.entries.last)
                              _rowDivider(),
                          ],
                        )),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                if (session.status == ProgramSessionStatus.paused)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                        await context
                            .read<FitnessProvider>()
                            .resumeProgramSession(session.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _P.text,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'ВОЗОБНОВИТЬ',
                            style: _T.num(TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            )),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (session.status == ProgramSessionStatus.abandoned)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: s.soft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: s.color,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Программа была брошена. Начните новую, чтобы продолжить.',
                            style: _T.captionSm.copyWith(
                              height: 1.4,
                              color: _P.textSecondary,
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

  String _metricLabel(String key) {
    switch (key) {
      case 'kg':
        return 'Тоннаж';
      case 'km':
        return 'Дистанция';
      case 'rounds':
        return 'Раунды';
      case 'sec':
        return 'Время';
      case 'punches':
        return 'Удары';
      case 'kcal':
        return 'Калории';
      default:
        return key;
    }
  }

  Widget _rowDivider() => Container(
    height: 1,
    color: _P.borderLight,
  );

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _P.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: _T.caption.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: _T.num(_T.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _P.text,
            )),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  EMPTY
  // ══════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _P.surfaceMuted,
              shape: BoxShape.circle,
              border: Border.all(color: _P.border, width: 1),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 24,
              color: _P.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Пока пусто',
            style: _T.subhead.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Завершённые программы появятся здесь',
            textAlign: TextAlign.center,
            style: _T.caption.copyWith(
              height: 1.5,
              color: _P.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  MISC HELPERS
  // ══════════════════════════════════════════════════════════
  String _formatDate(DateTime date) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  UNIFIED IMAGE HELPER
//  assets/ · http(s):// · локальный файл
// ═══════════════════════════════════════════════════════════════════
class _AppImage extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  final Widget? fallback;
  final double? width;
  final double? height;

  const _AppImage({
    this.path,
    this.fit = BoxFit.cover,
    this.fallback,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final p = path;
    final fb = fallback ?? const SizedBox.shrink();

    if (p == null || p.isEmpty) return fb;
    if (p.startsWith('assets/')) {
      return Image.asset(
        p, fit: fit, width: width, height: height,
        errorBuilder: (_, __, ___) => fb,
      );
    }
    if (p.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: p, fit: fit, width: width, height: height,
        placeholder: (_, __) => fb,
        errorWidget: (_, __, ___) => fb,
      );
    }
    return Image.file(
      File(p), fit: fit, width: width, height: height,
      errorBuilder: (_, __, ___) => fb,
    );
  }
}