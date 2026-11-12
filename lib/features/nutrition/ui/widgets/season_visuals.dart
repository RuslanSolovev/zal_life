// features/nutrition/ui/widgets/season_visuals.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════
//  SEASON TOKENS
// ═══════════════════════════════════════════════════════════════════
enum SeasonKind { spring, summer, autumn, winter }

class SeasonMeta {
  final SeasonKind kind;
  final String label;
  final String emoji;
  final Color accent;
  final Color soft;
  final Color deep;
  final List<int> months;
  final String tagline;
  const SeasonMeta({
    required this.kind,
    required this.label,
    required this.emoji,
    required this.accent,
    required this.soft,
    required this.deep,
    required this.months,
    required this.tagline,
  });
}

const kSeasonMetas = <SeasonKind, SeasonMeta>{
  SeasonKind.spring: SeasonMeta(
    kind: SeasonKind.spring,
    label: 'Весна',
    emoji: '🌿',
    accent: Color(0xFF6C9E88),
    soft: Color(0xFFE7F2ED),
    deep: Color(0xFF4E7D69),
    months: [3, 4, 5],
    tagline: 'Свежесть, зелень, лёгкость',
  ),
  SeasonKind.summer: SeasonMeta(
    kind: SeasonKind.summer,
    label: 'Лето',
    emoji: '☀️',
    accent: Color(0xFFEF9563),
    soft: Color(0xFFFBEDE4),
    deep: Color(0xFFD97845),
    months: [6, 7, 8],
    tagline: 'Ягоды, солнце, витамины',
  ),
  SeasonKind.autumn: SeasonMeta(
    kind: SeasonKind.autumn,
    label: 'Осень',
    emoji: '🍂',
    accent: Color(0xFFE0B054),
    soft: Color(0xFFFDF5E6),
    deep: Color(0xFFB98A34),
    months: [9, 10, 11],
    tagline: 'Урожай, тыква, иммунитет',
  ),
  SeasonKind.winter: SeasonMeta(
    kind: SeasonKind.winter,
    label: 'Зима',
    emoji: '❄️',
    accent: Color(0xFF7E9DC6),
    soft: Color(0xFFE8EFF8),
    deep: Color(0xFF587FAE),
    months: [12, 1, 2],
    tagline: 'Цитрусы, тепло, поддержка',
  ),
};

SeasonKind seasonForMonth(int m) {
  if (m >= 3 && m <= 5) return SeasonKind.spring;
  if (m >= 6 && m <= 8) return SeasonKind.summer;
  if (m >= 9 && m <= 11) return SeasonKind.autumn;
  return SeasonKind.winter;
}

SeasonMeta metaForMonth(int m) => kSeasonMetas[seasonForMonth(m)]!;

const kMonthShort = [
  '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
  'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
];
const kMonthFull = [
  '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];

int daysLeftInMonth(DateTime now) {
  final last = DateUtils.getDaysInMonth(now.year, now.month);
  return last - now.day;
}

int daysUntilNextMonth(DateTime now) {
  final next = now.month == 12
      ? DateTime(now.year + 1, 1, 1)
      : DateTime(now.year, now.month + 1, 1);
  return next.difference(DateTime(now.year, now.month, now.day)).inDays;
}

// ═══════════════════════════════════════════════════════════════════
//  SEASON MONTHS BAR — 12-месячная полоса
// ═══════════════════════════════════════════════════════════════════
class SeasonMonthsBar extends StatelessWidget {
  final List<int> months;
  final int currentMonth;
  final Color accent;
  final Color trackColor;
  final double height;
  final bool showLabels;

  const SeasonMonthsBar({
    super.key,
    required this.months,
    required this.currentMonth,
    required this.accent,
    this.trackColor = const Color(0xFFF0F1F4),
    this.height = 5,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(12, (i) {
            final m = i + 1;
            final inSeason = months.contains(m);
            final isNow = m == currentMonth;

            Color color;
            Border? border;
            if (inSeason) {
              color = isNow ? accent : accent.withOpacity(0.75);
            } else if (isNow) {
              color = accent.withOpacity(0.10);
              border = Border.all(color: accent.withOpacity(0.5), width: 1);
            } else {
              color = trackColor;
            }

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: i == 0 || i == 11 ? 0 : 0.5),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                    border: border,
                  ),
                ),
              ),
            );
          }),
        ),
        if (showLabels) ...[
          const SizedBox(height: 5),
          Row(
            children: List.generate(12, (i) {
              final m = i + 1;
              final isNow = m == currentMonth;
              final inSeason = months.contains(m);
              return Expanded(
                child: Text(
                  kMonthShort[m],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    height: 1,
                    fontWeight: isNow
                        ? FontWeight.w800
                        : inSeason
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isNow
                        ? accent
                        : inSeason
                        ? accent.withOpacity(0.85)
                        : const Color(0xFF7C818A).withOpacity(0.55),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SEASON PILL — «🍂 Осень · 12 дн»
// ═══════════════════════════════════════════════════════════════════
class SeasonPill extends StatelessWidget {
  final int month;
  final bool dark;
  final bool showDays;
  final VoidCallback? onTap;

  const SeasonPill({
    super.key,
    required this.month,
    this.dark = false,
    this.showDays = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = metaForMonth(month);
    final days = daysLeftInMonth(DateTime.now());
    final bg = dark ? Colors.white.withOpacity(0.06) : meta.soft;
    final fg = dark ? meta.accent : meta.deep;
    final border = dark
        ? Border.all(color: Colors.white.withOpacity(0.10), width: 1)
        : Border.all(color: meta.accent.withOpacity(0.20), width: 1);

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(meta.emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            meta.label.toLowerCase(),
            style: GoogleFonts.inter(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          if (showDays) ...[
            Container(
              width: 2,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: fg.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              days <= 1 ? 'финал' : '$days дн',
              style: GoogleFonts.inter(
                color: fg.withOpacity(0.85),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SEASON WHEEL — 12 секторов
// ═══════════════════════════════════════════════════════════════════
class SeasonWheelPainter extends CustomPainter {
  final int currentMonth;
  final List<int> months;
  final Color accent;
  final Color track;

  SeasonWheelPainter({
    required this.currentMonth,
    required this.months,
    required this.accent,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const start = -math.pi / 2;
    const sweep = (2 * math.pi) / 12;
    const gap = 0.06;

    for (int i = 0; i < 12; i++) {
      final m = i + 1;
      final inSeason = months.contains(m);
      final isNow = m == currentMonth;
      final rect = Rect.fromCircle(center: center, radius: radius);

      Color color;
      double stroke;
      if (inSeason && isNow) {
        color = accent;
        stroke = 14;
      } else if (inSeason) {
        color = accent.withOpacity(0.75);
        stroke = 10;
      } else if (isNow) {
        color = accent.withOpacity(0.25);
        stroke = 10;
      } else {
        color = track;
        stroke = 8;
      }

      canvas.drawArc(
        rect,
        start + i * sweep + gap,
        sweep - gap * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );

      if (inSeason && isNow) {
        canvas.drawArc(
          rect,
          start + i * sweep + gap,
          sweep - gap * 2,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke + 6
            ..strokeCap = StrokeCap.round
            ..color = accent.withOpacity(0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SeasonWheelPainter old) =>
      old.currentMonth != currentMonth ||
          old.months != months ||
          old.accent != accent;
}

class SeasonWheel extends StatelessWidget {
  final int currentMonth;
  final List<int> months;
  final Color accent;
  final double size;

  const SeasonWheel({
    super.key,
    required this.currentMonth,
    required this.months,
    required this.accent,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: SeasonWheelPainter(
              currentMonth: currentMonth,
              months: months,
              accent: accent,
              track: accent.withOpacity(0.12),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${months.length}',
                style: GoogleFonts.inter(
                  color: accent,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'мес',
                style: GoogleFonts.inter(
                  color: accent.withOpacity(0.7),
                  fontSize: size * 0.08,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}