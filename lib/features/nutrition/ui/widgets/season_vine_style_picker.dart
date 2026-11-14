// lib/features/nutrition/ui/widgets/season_vine_style_picker.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'season_vine_style.dart';

class SeasonVineStylePicker {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => const _PickerSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHEET
// ═══════════════════════════════════════════════════════════════════
class _PickerSheet extends StatelessWidget {
  const _PickerSheet();

  static const _meta = <SeasonVineStyle, _StyleMeta>{
    SeasonVineStyle.postage: _StyleMeta(
      title: 'Postage',
      subtitle: 'Альбом марок',
    ),
    SeasonVineStyle.botanica: _StyleMeta(
      title: 'Botanica',
      subtitle: 'Ботанический гербарий',
    ),
    SeasonVineStyle.aurora: _StyleMeta(
      title: 'Aurora',
      subtitle: 'Северное сияние',
    ),
    SeasonVineStyle.flipboard: _StyleMeta(
      title: 'Flipboard',
      subtitle: 'Механическое табло',
    ),
    SeasonVineStyle.metro: _StyleMeta(
      title: 'Metro',
      subtitle: 'Схема метро',
    ),
    SeasonVineStyle.kintsugi: _StyleMeta(
      title: 'Kintsugi',
      subtitle: 'Золотой ремонт',
    ),
    SeasonVineStyle.hourglass: _StyleMeta(
      title: 'Hourglass',
      subtitle: 'Песочные часы',
    ),
    SeasonVineStyle.circuit: _StyleMeta(
      title: 'Circuit',
      subtitle: 'Материнская плата',
    ),
    SeasonVineStyle.conveyor: _StyleMeta(
      title: 'Conveyor',
      subtitle: 'Суши-конвейер',
    ),
    SeasonVineStyle.clock: _StyleMeta(
      title: 'Clock',
      subtitle: 'Астрономические часы',
    ),
    SeasonVineStyle.lighthouse: _StyleMeta(
      title: 'Lighthouse',
      subtitle: 'Луч маяка',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ValueListenableBuilder<SeasonVineStyle>(
      valueListenable: SeasonVineStyleController.current,
      builder: (context, currentStyle, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F5F1),
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Стиль карточки',
                            style: GoogleFonts.fraunces(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF263D36),
                              letterSpacing: -0.4,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Сейчас: ${_meta[currentStyle]!.title}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7C8982),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF7C8982),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Grid — scrollable so 11 items fit comfortably
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.68,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.02,
                    children: [
                      for (final style in SeasonVineStyle.values)
                        _StylePreviewCard(
                          style: style,
                          meta: _meta[style]!,
                          selected: currentStyle == style,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            SeasonVineStyleController.select(style);
                            Future.delayed(
                                const Duration(milliseconds: 180),
                                    () {
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StyleMeta {
  final String title;
  final String subtitle;
  const _StyleMeta({required this.title, required this.subtitle});
}

// ═══════════════════════════════════════════════════════════════════
//  PREVIEW CARD
// ═══════════════════════════════════════════════════════════════════
class _StylePreviewCard extends StatelessWidget {
  final SeasonVineStyle style;
  final _StyleMeta meta;
  final bool selected;
  final VoidCallback onTap;

  const _StylePreviewCard({
    required this.style,
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF3DDC84)
                : Colors.black.withOpacity(0.06),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: const Color(0xFF3DDC84).withOpacity(0.20),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: _StyleThumbnail(style: style),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          meta.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF263D36),
                            letterSpacing: -0.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7C8982),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3DDC84),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                          const Color(0xFF3DDC84).withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
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
}

// ═══════════════════════════════════════════════════════════════════
//  THUMBNAIL DISPATCHER
// ═══════════════════════════════════════════════════════════════════
class _StyleThumbnail extends StatelessWidget {
  final SeasonVineStyle style;
  const _StyleThumbnail({required this.style});

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case SeasonVineStyle.postage:
        return const _PostageThumbnail();
      case SeasonVineStyle.botanica:
        return const _BotanicaThumbnail();
      case SeasonVineStyle.aurora:
        return const _AuroraThumbnail();
      case SeasonVineStyle.flipboard:
        return const _FlipboardThumbnail();
      case SeasonVineStyle.metro:
        return const _MetroThumbnail();
      case SeasonVineStyle.kintsugi:
        return const _KintsugiThumbnail();
      case SeasonVineStyle.hourglass:
        return const _HourglassThumbnail();
      case SeasonVineStyle.circuit:
        return const _CircuitThumbnail();
      case SeasonVineStyle.conveyor:
        return const _ConveyorThumbnail();
      case SeasonVineStyle.clock:
        return const _ClockThumbnail();
      case SeasonVineStyle.lighthouse:
        return const _LighthouseThumbnail();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  POSTAGE THUMBNAIL — perforated stamp on leather
// ═══════════════════════════════════════════════════════════════════
class _PostageThumbnail extends StatelessWidget {
  const _PostageThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF3F2818),
      child: Center(
        child: Transform.rotate(
          angle: -0.05,
          child: Container(
            width: 68,
            height: 88,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipPath(
              clipper: const _MiniPerforatedClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8E5A2A), Color(0xFFB8785A)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 1.5),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.45),
                            width: 0.6,
                          ),
                        ),
                      ),
                      child: const Text(
                        'ЯБЛОНИЯ',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text('🍎',
                            style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.symmetric(vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: const Text(
                        'НОЯ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B3A2A),
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BOTANICA THUMBNAIL — torn paper + watercolor
// ═══════════════════════════════════════════════════════════════════
class _BotanicaThumbnail extends StatelessWidget {
  const _BotanicaThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4EDE0),
      child: Center(
        child: Transform.rotate(
          angle: 0.04,
          child: Container(
            width: 62,
            height: 82,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipPath(
              clipper: const _MiniTornClipper(seed: 11),
              child: Container(
                color: const Color(0xFFFCF8EE),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MiniWatercolorPainter(),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      top: 4,
                      child: Text(
                        'ноя',
                        style: GoogleFonts.fraunces(
                          fontSize: 7,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF2C3E3A),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '11',
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF2C3E3A),
                          height: 1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 6,
                      child: Center(
                        child: Text('🍂',
                            style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniWatercolorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.55);
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi * 0.55;
      final dist = size.width * 0.12 * i;
      final c = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist,
      );
      canvas.drawCircle(
        c,
        size.width * 0.30,
        Paint()
          ..color = const Color(0xFFC79475).withOpacity(0.16)
          ..maskFilter = const MaskFilter.blur(
              BlurStyle.normal, 10),
      );
    }
    canvas.drawCircle(
      center,
      size.width * 0.28,
      Paint()
        ..color = const Color(0xFFC79475).withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniWatercolorPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  AURORA THUMBNAIL — mini northern lights
// ═══════════════════════════════════════════════════════════════════
class _AuroraThumbnail extends StatelessWidget {
  const _AuroraThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      child: CustomPaint(
        painter: _MiniAuroraPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _MiniAuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paths = <_AuroraWave>[
      _AuroraWave(
        color: const Color(0xFF3DDC84),
        strokeW: 14,
        blur: 8,
        opacity: 0.18,
        amp: 10,
        yFrac: 0.55,
        phase: 0.0,
      ),
      _AuroraWave(
        color: const Color(0xFF4A90E2),
        strokeW: 8,
        blur: 4,
        opacity: 0.30,
        amp: 8,
        yFrac: 0.52,
        phase: 1.1,
      ),
      _AuroraWave(
        color: const Color(0xFFFF6B8B),
        strokeW: 4,
        blur: 0,
        opacity: 0.55,
        amp: 6,
        yFrac: 0.50,
        phase: 2.2,
      ),
      _AuroraWave(
        color: Colors.white,
        strokeW: 1.5,
        blur: 0,
        opacity: 0.40,
        amp: 5,
        yFrac: 0.49,
        phase: 3.1,
      ),
    ];

    for (final w in paths) {
      final path = Path();
      const steps = 40;
      for (int i = 0; i <= steps; i++) {
        final x = size.width * i / steps;
        final y = size.height * w.yFrac +
            math.sin(x * 0.05 + w.phase) * w.amp;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..color = w.color.withOpacity(w.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w.strokeW
        ..strokeCap = StrokeCap.round;
      if (w.blur > 0) {
        paint.maskFilter =
            MaskFilter.blur(BlurStyle.normal, w.blur);
      }
      canvas.drawPath(path, paint);
    }

    final markerX = size.width * 0.62;
    final markerY = size.height * 0.50 +
        math.sin(markerX * 0.05 + 2.2) * 6;
    canvas.drawCircle(
      Offset(markerX, markerY),
      10,
      Paint()
        ..color = const Color(0xFFFF8A65).withOpacity(0.25)
        ..maskFilter =
        const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      Offset(markerX, markerY),
      3.5,
      Paint()..color = const Color(0xFFFF8A65),
    );
    canvas.drawCircle(
      Offset(markerX, markerY),
      1.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniAuroraPainter old) => false;
}

class _AuroraWave {
  final Color color;
  final double strokeW;
  final double blur;
  final double opacity;
  final double amp;
  final double yFrac;
  final double phase;
  const _AuroraWave({
    required this.color,
    required this.strokeW,
    required this.blur,
    required this.opacity,
    required this.amp,
    required this.yFrac,
    required this.phase,
  });
}

// ═══════════════════════════════════════════════════════════════════
//  FLIPBOARD THUMBNAIL — one split-flap tile
// ═══════════════════════════════════════════════════════════════════
class _FlipboardThumbnail extends StatelessWidget {
  const _FlipboardThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Container(
          width: 90,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            border: Border.all(
              color: const Color(0xFF3A3A3A),
              width: 0.6,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 30,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1F1F1F),
                        Color(0xFF2A2A2A),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'НОЯ',
                      style: TextStyle(
                        color: Color(0xFFFF8A65),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 30,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF2A2A2A),
                        Color(0xFF1F1F1F),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3DDC84),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '03 ПРОД',
                        style: TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 29.5,
                child: Container(
                  height: 1,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  METRO THUMBNAIL — mini subway line
// ═══════════════════════════════════════════════════════════════════
class _MetroThumbnail extends StatelessWidget {
  const _MetroThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F5F1),
      child: CustomPaint(
        painter: _MiniMetroPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _MiniMetroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height * 0.52;
    final pad = size.width * 0.14;
    final trackColor = const Color(0xFF3DDC84);
    final inactiveColor = const Color(0xFFC8CFC8);
    final stationBorder = const Color(0xFF111311);

    final trackPath = Path()
      ..moveTo(pad, trackY)
      ..lineTo(size.width - pad, trackY);
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = inactiveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    final activePath = Path()
      ..moveTo(pad, trackY)
      ..lineTo(size.width * 0.60, trackY);
    canvas.drawPath(
      activePath,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    final positions = [
      pad,
      size.width * 0.32,
      size.width * 0.56,
      size.width - pad,
    ];
    final types = [
      _MiniStationType.small,
      _MiniStationType.medium,
      _MiniStationType.current,
      _MiniStationType.small,
    ];

    for (int i = 0; i < 4; i++) {
      final pos = Offset(positions[i], trackY);
      _drawStation(canvas, pos, types[i],
          trackColor, stationBorder);
    }

    for (int i = 0; i < 4; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: ['янв', 'мар', 'ноя', 'дек'][i],
          style: const TextStyle(
            color: Color(0xFF0F1210),
            fontSize: 6.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(positions[i] - tp.width / 2, trackY + 12),
      );
    }
  }

  void _drawStation(
      Canvas canvas,
      Offset pos,
      _MiniStationType type,
      Color green,
      Color border,
      ) {
    switch (type) {
      case _MiniStationType.small:
        canvas.drawCircle(
          pos,
          4,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          pos,
          4,
          Paint()
            ..color = border.withOpacity(0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        break;
      case _MiniStationType.medium:
        canvas.drawCircle(
          pos,
          4.5,
          Paint()..color = const Color(0xFFD4F4E1),
        );
        canvas.drawCircle(
          pos,
          4.5,
          Paint()
            ..color = green
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        break;
      case _MiniStationType.current:
        canvas.drawCircle(
          pos,
          6,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          pos,
          6,
          Paint()
            ..color = const Color(0xFFFF8A65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
        canvas.drawCircle(
          pos,
          2.6,
          Paint()..color = const Color(0xFFFF8A65),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniMetroPainter old) => false;
}

enum _MiniStationType { small, medium, current }

// ═══════════════════════════════════════════════════════════════════
//  KINTSUGI THUMBNAIL — ceramic disc with golden cracks
// ═══════════════════════════════════════════════════════════════════
class _KintsugiThumbnail extends StatelessWidget {
  const _KintsugiThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1410),
      child: CustomPaint(
        painter: _MiniKintsugiPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _MiniKintsugiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.shortestSide * 0.42;

    canvas.drawCircle(
      Offset(cx, cy),
      outerR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF4A423A),
            const Color(0xFF2A2420),
            const Color(0xFF1A1410),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: outerR)),
    );

    canvas.drawCircle(
      Offset(cx, cy),
      outerR,
      Paint()
        ..color = const Color(0xFF5A5045).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final rng = math.Random(42);
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 + 15) * math.pi / 180 - math.pi / 2;
      final start = Offset(
        cx + math.cos(angle) * outerR * 0.15,
        cy + math.sin(angle) * outerR * 0.15,
      );
      final end = Offset(
        cx + math.cos(angle) * outerR * 0.95,
        cy + math.sin(angle) * outerR * 0.95,
      );
      final path = Path()..moveTo(start.dx, start.dy);
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      final nx = -dy / len;
      final ny = dx / len;
      for (int s = 1; s <= 6; s++) {
        final t = s / 6;
        final j = (rng.nextDouble() - 0.5) * 3.0;
        path.lineTo(
          start.dx + dx * t + nx * j,
          start.dy + dy * t + ny * j,
        );
      }
      final isActive = i % 3 != 1;
      final color = isActive
          ? const Color(0xFFD4A84B)
          : const Color(0xFF6B5428);
      if (isActive) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withOpacity(0.30)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(isActive ? 0.9 : 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }

    for (int i = 0; i < 3; i++) {
      final angle = i * 2 * math.pi / 3 - math.pi / 2;
      final bx = cx + math.cos(angle) * outerR * 0.55;
      final by = cy + math.sin(angle) * outerR * 0.55;
      canvas.drawCircle(
        Offset(bx, by),
        7,
        Paint()
          ..color = const Color(0xFFD4A84B).withOpacity(0.35)
          ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(bx, by),
        5,
        Paint()..color = const Color(0xFFD4A84B),
      );
      canvas.drawCircle(
        Offset(bx, by),
        2.5,
        Paint()..color = const Color(0xFF1A1410),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniKintsugiPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  HOURGLASS THUMBNAIL — wood + glass + sand
// ═══════════════════════════════════════════════════════════════════
class _HourglassThumbnail extends StatelessWidget {
  const _HourglassThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1208),
      child: CustomPaint(
        painter: _MiniHourglassPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _MiniHourglassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final w = size.width * 0.55;

    final frameTop = Rect.fromLTWH(
        cx - w / 2 - 8, size.height * 0.08, w + 16, 8);
    final frameBot = Rect.fromLTWH(
        cx - w / 2 - 8, size.height * 0.84, w + 16, 8);
    for (final r in [frameTop, frameBot]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(2)),
        Paint()..color = const Color(0xFF5A3A28),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(2)),
        Paint()
          ..color = const Color(0xFFD4A84B).withOpacity(0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    final glassPath = Path()
      ..moveTo(cx - w / 2, size.height * 0.13)
      ..lineTo(cx + w / 2, size.height * 0.13)
      ..cubicTo(
        cx + w * 0.4, size.height * 0.40,
        cx + w * 0.08, size.height * 0.46,
        cx + w * 0.08, size.height * 0.50,
      )
      ..cubicTo(
        cx + w * 0.08, size.height * 0.54,
        cx + w * 0.4, size.height * 0.60,
        cx + w / 2, size.height * 0.87,
      )
      ..lineTo(cx - w / 2, size.height * 0.87)
      ..cubicTo(
        cx - w * 0.4, size.height * 0.60,
        cx - w * 0.08, size.height * 0.54,
        cx - w * 0.08, size.height * 0.50,
      )
      ..cubicTo(
        cx - w * 0.08, size.height * 0.46,
        cx - w * 0.4, size.height * 0.40,
        cx - w / 2, size.height * 0.13,
      )
      ..close();

    canvas.drawPath(
      glassPath,
      Paint()
        ..color = const Color(0xFFF5EDE0).withOpacity(0.06)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      glassPath,
      Paint()
        ..color = const Color(0xFFF5EDE0).withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(cx + (i - 1.5) * 8, size.height * 0.22 + i.abs() * 2),
        3.5,
        Paint()..color = const Color(0xFFE7D9B8),
      );
    }

    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(cx, size.height * (0.50 + i * 0.015)),
        1.2,
        Paint()..color = const Color(0xFFC79475),
      );
    }

    canvas.drawCircle(
      Offset(cx, size.height * 0.50),
      5,
      Paint()..color = const Color(0xFFFF8A65),
    );
    canvas.drawCircle(
      Offset(cx, size.height * 0.50),
      9,
      Paint()
        ..color = const Color(0xFFFF8A65).withOpacity(0.35)
        ..maskFilter =
        const MaskFilter.blur(BlurStyle.normal, 4),
    );

    for (int i = 0; i < 5; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      canvas.drawCircle(
        Offset(cx + (col - 1) * 9, size.height * 0.82 - row * 7),
        3.5,
        Paint()..color = const Color(0xFFC79475),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniHourglassPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  CIRCUIT THUMBNAIL — PCB with chips + traces
// ═══════════════════════════════════════════════════════════════════
class _CircuitThumbnail extends StatelessWidget {
  const _CircuitThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1A0F),
      child: CustomPaint(
        painter: _MiniCircuitPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _MiniCircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final viaPaint =
    Paint()..color = const Color(0xFF3A4038).withOpacity(0.5);
    for (double x = 10; x < size.width; x += 16) {
      for (double y = 10; y < size.height; y += 16) {
        canvas.drawCircle(Offset(x, y), 0.8, viaPaint);
      }
    }

    final positions = [
      Offset(size.width * 0.25, size.height * 0.35),
      Offset(size.width * 0.50, size.height * 0.50),
      Offset(size.width * 0.75, size.height * 0.65),
    ];
    final chipSizes = [18.0, 22.0, 18.0];
    final chipColors = [
      const Color(0xFF2A3828),
      const Color(0xFF1A1F1A),
      const Color(0xFF1A1F1A),
    ];
    final borderColors = [
      const Color(0xFF3DDC84),
      const Color(0xFFFF8A65),
      const Color(0xFF3A4038),
    ];

    for (int i = 0; i < 2; i++) {
      final from = positions[i];
      final to = positions[i + 1];
      final midX = (from.dx + to.dx) / 2;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(midX, from.dy)
        ..lineTo(midX, to.dy)
        ..lineTo(to.dx, to.dy);
      final isActive = i == 0;
      if (isActive) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF3DDC84).withOpacity(0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = (isActive
              ? const Color(0xFF3DDC84)
              : const Color(0xFF2A3A2E))
              .withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (int i = 0; i < 3; i++) {
      final rect = Rect.fromCenter(
        center: positions[i],
        width: chipSizes[i],
        height: chipSizes[i] * 0.8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = chipColors[i],
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()
          ..color = borderColors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      if (i < 2) {
        canvas.drawCircle(
          Offset(rect.right - 3, rect.top + 3),
          1.2,
          Paint()..color = borderColors[i],
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniCircuitPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  CONVEYOR THUMBNAIL — wooden belt with plates
// ═══════════════════════════════════════════════════════════════════
class _ConveyorThumbnail extends StatelessWidget {
  const _ConveyorThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A1F17),
      child: Stack(
        children: [
          // Belt strip at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 22,
            child: Container(color: const Color(0xFF0F0F0F)),
          ),
          // Belt teeth line
          Positioned(
            left: 0,
            right: 0,
            bottom: 9,
            child: Container(
              height: 4,
              color: const Color(0xFF3A3A3A),
            ),
          ),
          // Plates
          ...List.generate(3, (i) {
            final isCenter = i == 1;
            return Positioned(
              left: 14.0 + i * 32,
              bottom: 26,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCenter
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFF5EDE0),
                  border: Border.all(
                    color: isCenter
                        ? const Color(0xFFFF8A65)
                        : const Color(0xFFD4A84B),
                    width: 1.5,
                  ),
                  boxShadow: isCenter
                      ? [
                    BoxShadow(
                      color: const Color(0xFFFF8A65)
                          .withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  ['🍣', '🍱', '🍜'][i],
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CLOCK THUMBNAIL — astronomical brass clock
// ═══════════════════════════════════════════════════════════════════
class _ClockThumbnail extends StatelessWidget {
  const _ClockThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0A05),
      child: CustomPaint(painter: _MiniClockPainter()),
    );
  }
}

class _MiniClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.shortestSide * 0.42;

    canvas.drawCircle(
      Offset(cx, cy), outerR,
      Paint()..color = const Color(0xFF2A1F0F),
    );
    canvas.drawCircle(
      Offset(cx, cy), outerR,
      Paint()
        ..color = const Color(0xFFD4A84B).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(cx, cy), outerR * 0.6,
      Paint()
        ..color = const Color(0xFFD4A84B).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    canvas.drawCircle(
      Offset(cx, cy), outerR * 0.35,
      Paint()..color = const Color(0xFF0F0A05),
    );

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180 - math.pi / 2;
      final x1 = cx + math.cos(angle) * outerR * 0.35;
      final y1 = cy + math.sin(angle) * outerR * 0.35;
      final x2 = cx + math.cos(angle) * outerR * 0.92;
      final y2 = cy + math.sin(angle) * outerR * 0.92;
      canvas.drawLine(
        Offset(x1, y1), Offset(x2, y2),
        Paint()
          ..color = const Color(0xFFD4A84B).withOpacity(0.4)
          ..strokeWidth = 0.5,
      );
    }

    final handAngle = -math.pi / 3;
    final handEnd = Offset(
      cx + math.cos(handAngle) * outerR * 0.7,
      cy + math.sin(handAngle) * outerR * 0.7,
    );
    canvas.drawLine(
      Offset(cx, cy), handEnd,
      Paint()
        ..color = const Color(0xFFF5C842)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
        handEnd, 3, Paint()..color = const Color(0xFFF5C842));
    canvas.drawCircle(
        Offset(cx, cy), 3, Paint()..color = const Color(0xFFD4A84B));
  }

  @override
  bool shouldRepaint(covariant _MiniClockPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  LIGHTHOUSE THUMBNAIL — night sea with beam
// ═══════════════════════════════════════════════════════════════════
class _LighthouseThumbnail extends StatelessWidget {
  const _LighthouseThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1420),
            Color(0xFF152535),
            Color(0xFF0A1622),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: CustomPaint(painter: _MiniLighthousePainter()),
    );
  }
}

class _MiniLighthousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.62;

    for (int i = 0; i < 8; i++) {
      final x = 8.0 + i * 14 + (i % 2) * 5;
      final y = 8.0 + (i % 3) * 6;
      canvas.drawCircle(
        Offset(x, y), 0.6,
        Paint()..color = const Color(0xFFE8EEF5).withOpacity(0.6),
      );
    }

    for (int i = 0; i < 3; i++) {
      final ix = 18.0 + i * 32;
      final islandPath = Path()
        ..moveTo(ix - 10, horizonY)
        ..quadraticBezierTo(ix, horizonY - 12, ix + 10, horizonY);
      canvas.drawPath(
        islandPath,
        Paint()
          ..color = i == 1
              ? const Color(0xFF3A4A5A)
              : const Color(0xFF1A2530),
      );
    }

    final lx = size.width - 22;
    const lampY = 28.0;

    final towerPath = Path()
      ..moveTo(lx - 5, horizonY)
      ..lineTo(lx - 3, lampY)
      ..lineTo(lx + 3, lampY)
      ..lineTo(lx + 5, horizonY)
      ..close();
    canvas.drawPath(
        towerPath, Paint()..color = const Color(0xFFF5EDE0));

    canvas.drawCircle(
      Offset(lx, lampY),
      3,
      Paint()..color = const Color(0xFFF5C842),
    );

    final beamPath = Path()
      ..moveTo(lx, lampY)
      ..lineTo(0, horizonY - 30)
      ..lineTo(0, horizonY + 30)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            const Color(0xFFF5EDE0).withOpacity(0.4),
            const Color(0xFFF5EDE0).withOpacity(0.0),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniLighthousePainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  MINI PERFORATED CLIPPER
// ═══════════════════════════════════════════════════════════════════
class _MiniPerforatedClipper extends CustomClipper<Path> {
  const _MiniPerforatedClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(0, 0);
    const nTop = 8;
    final nSide = (8 * (h / w)).round().clamp(6, 14);
    _edge(path, Offset(0, 0), Offset(w, 0), nTop,
        w / nTop * 0.22 * 0.9);
    _edge(path, Offset(w, 0), Offset(w, h), nSide,
        h / nSide * 0.22 * 0.9);
    _edge(path, Offset(w, h), Offset(0, h), nTop,
        w / nTop * 0.22 * 0.9);
    _edge(path, Offset(0, h), Offset(0, 0), nSide,
        h / nSide * 0.22 * 0.9);
    path.close();
    return path;
  }

  void _edge(Path path, Offset from, Offset to, int n, double depth) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 0.001) return;
    final px = dy / len;
    final py = -dx / len;
    for (int i = 0; i < n; i++) {
      final t0 = i / n;
      final t1 = (i + 1) / n;
      final midT = (t0 + t1) / 2;
      final endX = from.dx + dx * t1;
      final endY = from.dy + dy * t1;
      final midX = from.dx + dx * midT + px * depth * 2;
      final midY = from.dy + dy * midT + py * depth * 2;
      path.quadraticBezierTo(midX, midY, endX, endY);
    }
  }

  @override
  bool shouldReclip(covariant _MiniPerforatedClipper old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  MINI TORN CLIPPER
// ═══════════════════════════════════════════════════════════════════
class _MiniTornClipper extends CustomClipper<Path> {
  final int seed;
  const _MiniTornClipper({required this.seed});

  @override
  Path getClip(Size size) {
    final rng = math.Random(seed);
    final path = Path();
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    path.moveTo(corners[0].dx, corners[0].dy);
    for (int i = 0; i < 4; i++) {
      _tornEdge(path, corners[i], corners[(i + 1) % 4], rng);
    }
    path.close();
    return path;
  }

  void _tornEdge(Path path, Offset from, Offset to, math.Random rng) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 0.001) return;
    final nx = -dy / len;
    final ny = dx / len;
    final segments = (len / 3).round().clamp(10, 20);
    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final baseX = from.dx + dx * t;
      final baseY = from.dy + dy * t;
      if (i == segments) {
        path.lineTo(baseX, baseY);
        return;
      }
      final r = rng.nextDouble();
      double offset;
      if (r < 0.12) {
        offset = (rng.nextBool() ? 1 : -1) * 2.0;
      } else if (r < 0.30) {
        offset = (rng.nextDouble() - 0.5) * 0.8;
      } else {
        offset = 0;
      }
      path.lineTo(baseX + nx * offset, baseY + ny * offset);
    }
  }

  @override
  bool shouldReclip(covariant _MiniTornClipper old) =>
      old.seed != seed;
}