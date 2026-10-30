import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/enums.dart';

class MuscleMapWidget extends StatefulWidget {
  final MuscleGroup? selectedMuscle;
  final Function(MuscleGroup)? onMuscleTap;
  final bool isInteractive;
  final Map<MuscleGroup, double>? volumeData;
  final bool showBack;

  const MuscleMapWidget({
    super.key,
    this.selectedMuscle,
    this.onMuscleTap,
    this.isInteractive = true,
    this.volumeData,
    this.showBack = false,
  });

  @override
  State<MuscleMapWidget> createState() => _MuscleMapWidgetState();
}

class _MuscleMapWidgetState extends State<MuscleMapWidget> {
  MuscleGroup? _hoveredMuscle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 450,
            child: InteractiveViewer(
              minScale: 0.7,
              maxScale: 3.0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    size: Size(
                      constraints.maxWidth > 0 ? constraints.maxWidth : 280,
                      constraints.maxHeight > 0 ? constraints.maxHeight : 450,
                    ),
                    painter: MuscleMapPainter(
                      selectedMuscle: widget.selectedMuscle,
                      hoveredMuscle: _hoveredMuscle,
                      volumeData: widget.volumeData,
                      isDark: isDark,
                      showBack: widget.showBack,
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.isInteractive) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (_hoveredMuscle != null || widget.selectedMuscle != null)
                    ? const Color(0xFFFF6B35).withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_hoveredMuscle != null || widget.selectedMuscle != null)
                      ? const Color(0xFFFF6B35).withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                _hoveredMuscle?.displayName ??
                    widget.selectedMuscle?.displayName ??
                    '👆 Нажмите на зону',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hoveredMuscle != null || widget.selectedMuscle != null
                      ? const Color(0xFFFF6B35)
                      : (isDark ? Colors.white54 : Colors.grey.shade600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MuscleMapPainter extends CustomPainter {
  final MuscleGroup? selectedMuscle;
  final MuscleGroup? hoveredMuscle;
  final Map<MuscleGroup, double>? volumeData;
  final bool isDark;
  final bool showBack;

  MuscleMapPainter({
    this.selectedMuscle,
    this.hoveredMuscle,
    this.volumeData,
    this.isDark = false,
    this.showBack = false,
  });

  static const double baseWidth = 300;
  static const double baseHeight = 460;

  @override
  void paint(Canvas canvas, Size size) {
    final double sx = size.width / baseWidth;
    final double sy = size.height / baseHeight;

    canvas.save();
    canvas.translate(size.width / 2, 0);
    canvas.scale(1.0, 1.0);
    canvas.translate(-baseWidth / 2 * sx, 0);

    // Фоновое свечение
    _drawBackgroundGlow(canvas, sx, sy);

    // Тень под фигурой
    _drawGroundShadow(canvas, sx, sy);

    // Основной силуэт тела с рельефом
    _drawBodySilhouette(canvas, sx, sy);

    // Мышцы (слои)
    if (showBack) {
      _drawBackMuscles(canvas, sx, sy);
    } else {
      _drawFrontMuscles(canvas, sx, sy);
    }

    // Анатомические линии
    _drawAnatomicalLines(canvas, sx, sy);

    // Свечение для выбранной мышцы
    if (selectedMuscle != null) {
      _drawSelectionGlow(canvas, sx, sy);
    }

    canvas.restore();
  }

  // ==================== ФОНОВОЕ СВЕЧЕНИЕ ====================
  void _drawBackgroundGlow(Canvas canvas, double sx, double sy) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0, -0.2),
        radius: 1.8,
        colors: [
          (isDark ? const Color(0x15FFFFFF) : const Color(0x08FFFFFF)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, baseWidth * sx, baseHeight * sy));
    canvas.drawRect(Rect.fromLTWH(0, 0, baseWidth * sx, baseHeight * sy), paint);
  }

  // ==================== ТЕНЬ ПОД ФИГУРОЙ ====================
  void _drawGroundShadow(Canvas canvas, double sx, double sy) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withOpacity(isDark ? 0.4 : 0.25),
          Colors.black.withOpacity(isDark ? 0.15 : 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCenter(
        center: Offset(baseWidth / 2 * sx, (baseHeight - 20) * sy),
        width: 220 * sx,
        height: 40 * sy,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(baseWidth / 2 * sx, (baseHeight - 20) * sy),
        width: 200 * sx,
        height: 30 * sy,
      ),
      paint,
    );
  }

  // ==================== СИЛУЭТ ТЕЛА ====================
  void _drawBodySilhouette(Canvas canvas, double sx, double sy) {
    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [const Color(0x33FFFFFF), const Color(0x11FFFFFF), const Color(0x08FFFFFF)]
          : [const Color(0x0A000000), const Color(0x06000000), const Color(0x03000000)],
    );

    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(Rect.fromLTWH(0, 0, baseWidth * sx, baseHeight * sy))
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _createBodyPath(sx, sy);

    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, outlinePaint);

    // Внутренний контур для объема
    final innerOutline = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final innerPath = _createBodyPath(sx, sy, inset: true);
    canvas.drawPath(innerPath, innerOutline);
  }

  Path _createBodyPath(double sx, double sy, {bool inset = false}) {
    final i = inset ? 2.0 : 0.0;
    final path = Path();

    // === ГОЛОВА ===
    path.moveTo((150 - i) * sx, (15 + i) * sy);
    path.cubicTo(
        (135 - i) * sx, (10 + i) * sy,
        (115 - i) * sx, (10 + i) * sy,
        (100 - i) * sx, (18 + i) * sy
    );
    path.cubicTo(
        (88 - i) * sx, (24 + i) * sy,
        (82 - i) * sx, (36 + i) * sy,
        (82 - i) * sx, (48 + i) * sy
    );
    path.cubicTo(
        (82 - i) * sx, (60 + i) * sy,
        (88 - i) * sx, (70 + i) * sy,
        (96 - i) * sx, (76 + i) * sy
    );
    // Скулы
    path.cubicTo(
        (100 - i) * sx, (80 + i) * sy,
        (106 - i) * sx, (84 + i) * sy,
        (114 - i) * sx, (86 + i) * sy
    );
    // Подбородок
    path.cubicTo(
        (120 - i) * sx, (90 + i) * sy,
        (130 - i) * sx, (90 + i) * sy,
        (136 - i) * sx, (86 + i) * sy
    );
    path.cubicTo(
        (144 - i) * sx, (84 + i) * sy,
        (150 - i) * sx, (80 + i) * sy,
        (154 - i) * sx, (76 + i) * sy
    );
    path.cubicTo(
        (162 - i) * sx, (70 + i) * sy,
        (168 - i) * sx, (60 + i) * sy,
        (168 - i) * sx, (48 + i) * sy
    );
    path.cubicTo(
        (168 - i) * sx, (36 + i) * sy,
        (162 - i) * sx, (24 + i) * sy,
        (150 - i) * sx, (15 + i) * sy
    );
    path.close();

    // === ШЕЯ ===
    path.moveTo((108 - i) * sx, (82 + i) * sy);
    path.cubicTo(
        (104 - i) * sx, (92 + i) * sy,
        (100 - i) * sx, (100 + i) * sy,
        (96 - i) * sx, (108 + i) * sy
    );
    path.cubicTo(
        (92 - i) * sx, (114 + i) * sy,
        (88 - i) * sx, (118 + i) * sy,
        (84 - i) * sx, (120 + i) * sy
    );

    path.moveTo((142 - i) * sx, (82 + i) * sy);
    path.cubicTo(
        (146 - i) * sx, (92 + i) * sy,
        (150 - i) * sx, (100 + i) * sy,
        (154 - i) * sx, (108 + i) * sy
    );
    path.cubicTo(
        (158 - i) * sx, (114 + i) * sy,
        (162 - i) * sx, (118 + i) * sy,
        (166 - i) * sx, (120 + i) * sy
    );

    // === ТОРС ===
    // Левый плечевой пояс
    path.moveTo((84 - i) * sx, (120 + i) * sy);
    path.cubicTo(
        (72 - i) * sx, (118 + i) * sy,
        (60 - i) * sx, (122 + i) * sy,
        (50 - i) * sx, (134 + i) * sy
    );
    path.cubicTo(
        (42 - i) * sx, (142 + i) * sy,
        (38 - i) * sx, (154 + i) * sy,
        (40 - i) * sx, (166 + i) * sy
    );
    path.cubicTo(
        (42 - i) * sx, (174 + i) * sy,
        (46 - i) * sx, (180 + i) * sy,
        (52 - i) * sx, (184 + i) * sy
    );

    // Левая сторона торса
    path.cubicTo(
        (54 - i) * sx, (200 + i) * sy,
        (58 - i) * sx, (220 + i) * sy,
        (62 - i) * sx, (240 + i) * sy
    );
    path.cubicTo(
        (64 - i) * sx, (260 + i) * sy,
        (66 - i) * sx, (278 + i) * sy,
        (70 - i) * sx, (292 + i) * sy
    );
    path.cubicTo(
        (72 - i) * sx, (302 + i) * sy,
        (76 - i) * sx, (308 + i) * sy,
        (82 - i) * sx, (312 + i) * sy
    );

    path.lineTo((168 + i) * sx, (312 + i) * sy);

    // Правая сторона торса
    path.cubicTo(
        (174 + i) * sx, (308 + i) * sy,
        (178 + i) * sx, (302 + i) * sy,
        (180 + i) * sx, (292 + i) * sy
    );
    path.cubicTo(
        (184 + i) * sx, (278 + i) * sy,
        (186 + i) * sx, (260 + i) * sy,
        (188 + i) * sx, (240 + i) * sy
    );
    path.cubicTo(
        (192 + i) * sx, (220 + i) * sy,
        (196 + i) * sx, (200 + i) * sy,
        (198 + i) * sx, (184 + i) * sy
    );

    // Правое плечо
    path.cubicTo(
        (204 + i) * sx, (180 + i) * sy,
        (208 + i) * sx, (174 + i) * sy,
        (210 + i) * sx, (166 + i) * sy
    );
    path.cubicTo(
        (212 + i) * sx, (154 + i) * sy,
        (208 + i) * sx, (142 + i) * sy,
        (200 + i) * sx, (134 + i) * sy
    );
    path.cubicTo(
        (190 + i) * sx, (122 + i) * sy,
        (178 + i) * sx, (118 + i) * sy,
        (166 + i) * sx, (120 + i) * sy
    );

    // === ЛЕВАЯ РУКА ===
    path.moveTo((52 - i) * sx, (184 + i) * sy);
    // Дельтовидная
    path.cubicTo(
        (40 - i) * sx, (188 + i) * sy,
        (30 - i) * sx, (198 + i) * sy,
        (26 - i) * sx, (214 + i) * sy
    );
    // Бицепс
    path.cubicTo(
        (22 - i) * sx, (232 + i) * sy,
        (20 - i) * sx, (256 + i) * sy,
        (22 - i) * sx, (278 + i) * sy
    );
    path.cubicTo(
        (24 - i) * sx, (294 + i) * sy,
        (28 - i) * sx, (306 + i) * sy,
        (34 - i) * sx, (314 + i) * sy
    );
    // Локоть
    path.cubicTo(
        (38 - i) * sx, (320 + i) * sy,
        (40 - i) * sx, (326 + i) * sy,
        (40 - i) * sx, (332 + i) * sy
    );
    // Предплечье
    path.cubicTo(
        (42 - i) * sx, (356 + i) * sy,
        (44 - i) * sx, (382 + i) * sy,
        (44 - i) * sx, (404 + i) * sy
    );
    // Запястье
    path.cubicTo(
        (44 - i) * sx, (412 + i) * sy,
        (46 - i) * sx, (420 + i) * sy,
        (50 - i) * sx, (426 + i) * sy
    );
    // Кисть
    path.cubicTo(
        (56 - i) * sx, (432 + i) * sy,
        (60 - i) * sx, (442 + i) * sy,
        (58 - i) * sx, (450 + i) * sy
    );
    path.cubicTo(
        (56 - i) * sx, (456 + i) * sy,
        (50 - i) * sx, (460 + i) * sy,
        (48 - i) * sx, (458 + i) * sy
    );
    // Внутренняя сторона
    path.cubicTo(
        (58 - i) * sx, (456 + i) * sy,
        (64 - i) * sx, (448 + i) * sy,
        (66 - i) * sx, (436 + i) * sy
    );
    path.cubicTo(
        (68 - i) * sx, (420 + i) * sy,
        (64 - i) * sx, (406 + i) * sy,
        (62 - i) * sx, (392 + i) * sy
    );
    path.cubicTo(
        (60 - i) * sx, (368 + i) * sy,
        (66 - i) * sx, (340 + i) * sy,
        (68 - i) * sx, (320 + i) * sy
    );
    // Трицепс
    path.cubicTo(
        (70 - i) * sx, (308 + i) * sy,
        (74 - i) * sx, (294 + i) * sy,
        (76 - i) * sx, (278 + i) * sy
    );
    path.cubicTo(
        (78 - i) * sx, (256 + i) * sy,
        (76 - i) * sx, (232 + i) * sy,
        (72 - i) * sx, (214 + i) * sy
    );
    path.cubicTo(
        (70 - i) * sx, (200 + i) * sy,
        (66 - i) * sx, (190 + i) * sy,
        (60 - i) * sx, (184 + i) * sy
    );
    path.cubicTo(
        (58 - i) * sx, (182 + i) * sy,
        (56 - i) * sx, (182 + i) * sy,
        (52 - i) * sx, (184 + i) * sy
    );

    // === ПРАВАЯ РУКА ===
    path.moveTo((198 + i) * sx, (184 + i) * sy);
    path.cubicTo(
        (210 + i) * sx, (188 + i) * sy,
        (220 + i) * sx, (198 + i) * sy,
        (224 + i) * sx, (214 + i) * sy
    );
    path.cubicTo(
        (228 + i) * sx, (232 + i) * sy,
        (230 + i) * sx, (256 + i) * sy,
        (228 + i) * sx, (278 + i) * sy
    );
    path.cubicTo(
        (226 + i) * sx, (294 + i) * sy,
        (222 + i) * sx, (306 + i) * sy,
        (216 + i) * sx, (314 + i) * sy
    );
    path.cubicTo(
        (212 + i) * sx, (320 + i) * sy,
        (210 + i) * sx, (326 + i) * sy,
        (210 + i) * sx, (332 + i) * sy
    );
    path.cubicTo(
        (208 + i) * sx, (356 + i) * sy,
        (206 + i) * sx, (382 + i) * sy,
        (206 + i) * sx, (404 + i) * sy
    );
    path.cubicTo(
        (206 + i) * sx, (412 + i) * sy,
        (204 + i) * sx, (420 + i) * sy,
        (200 + i) * sx, (426 + i) * sy
    );
    path.cubicTo(
        (194 + i) * sx, (432 + i) * sy,
        (190 + i) * sx, (442 + i) * sy,
        (192 + i) * sx, (450 + i) * sy
    );
    path.cubicTo(
        (194 + i) * sx, (456 + i) * sy,
        (200 + i) * sx, (460 + i) * sy,
        (202 + i) * sx, (458 + i) * sy
    );
    path.cubicTo(
        (192 + i) * sx, (456 + i) * sy,
        (186 + i) * sx, (448 + i) * sy,
        (184 + i) * sx, (436 + i) * sy
    );
    path.cubicTo(
        (182 + i) * sx, (420 + i) * sy,
        (186 + i) * sx, (406 + i) * sy,
        (188 + i) * sx, (392 + i) * sy
    );
    path.cubicTo(
        (190 + i) * sx, (368 + i) * sy,
        (184 + i) * sx, (340 + i) * sy,
        (182 + i) * sx, (320 + i) * sy
    );
    path.cubicTo(
        (180 + i) * sx, (308 + i) * sy,
        (176 + i) * sx, (294 + i) * sy,
        (174 + i) * sx, (278 + i) * sy
    );
    path.cubicTo(
        (172 + i) * sx, (256 + i) * sy,
        (174 + i) * sx, (232 + i) * sy,
        (178 + i) * sx, (214 + i) * sy
    );
    path.cubicTo(
        (180 + i) * sx, (200 + i) * sy,
        (184 + i) * sx, (190 + i) * sy,
        (190 + i) * sx, (184 + i) * sy
    );
    path.cubicTo(
        (192 + i) * sx, (182 + i) * sy,
        (194 + i) * sx, (182 + i) * sy,
        (198 + i) * sx, (184 + i) * sy
    );

    // === ЛЕВАЯ НОГА ===
    path.moveTo((82 - i) * sx, (312 + i) * sy);
    // Бедро
    path.cubicTo(
        (78 - i) * sx, (332 + i) * sy,
        (74 - i) * sx, (358 + i) * sy,
        (74 - i) * sx, (386 + i) * sy
    );
    // Колено
    path.cubicTo(
        (74 - i) * sx, (398 + i) * sy,
        (78 - i) * sx, (408 + i) * sy,
        (84 - i) * sx, (416 + i) * sy
    );
    // Икра
    path.cubicTo(
        (84 - i) * sx, (434 + i) * sy,
        (82 - i) * sx, (452 + i) * sy,
        (80 - i) * sx, (466 + i) * sy
    );
    // Лодыжка
    path.cubicTo(
        (80 - i) * sx, (474 + i) * sy,
        (82 - i) * sx, (480 + i) * sy,
        (86 - i) * sx, (484 + i) * sy
    );
    // Стопа
    path.cubicTo(
        (92 - i) * sx, (488 + i) * sy,
        (104 - i) * sx, (488 + i) * sy,
        (112 - i) * sx, (484 + i) * sy
    );
    path.cubicTo(
        (118 - i) * sx, (480 + i) * sy,
        (118 - i) * sx, (474 + i) * sy,
        (114 - i) * sx, (468 + i) * sy
    );
    // Внутренняя сторона
    path.cubicTo(
        (110 - i) * sx, (456 + i) * sy,
        (110 - i) * sx, (442 + i) * sy,
        (112 - i) * sx, (428 + i) * sy
    );
    path.cubicTo(
        (114 - i) * sx, (410 + i) * sy,
        (114 - i) * sx, (392 + i) * sy,
        (112 - i) * sx, (378 + i) * sy
    );
    path.cubicTo(
        (110 - i) * sx, (352 + i) * sy,
        (114 - i) * sx, (332 + i) * sy,
        (118 - i) * sx, (312 + i) * sy
    );

    // === ПРАВАЯ НОГА ===
    path.moveTo((168 + i) * sx, (312 + i) * sy);
    path.cubicTo(
        (172 + i) * sx, (332 + i) * sy,
        (176 + i) * sx, (358 + i) * sy,
        (176 + i) * sx, (386 + i) * sy
    );
    path.cubicTo(
        (176 + i) * sx, (398 + i) * sy,
        (172 + i) * sx, (408 + i) * sy,
        (166 + i) * sx, (416 + i) * sy
    );
    path.cubicTo(
        (166 + i) * sx, (434 + i) * sy,
        (168 + i) * sx, (452 + i) * sy,
        (170 + i) * sx, (466 + i) * sy
    );
    path.cubicTo(
        (170 + i) * sx, (474 + i) * sy,
        (168 + i) * sx, (480 + i) * sy,
        (164 + i) * sx, (484 + i) * sy
    );
    path.cubicTo(
        (158 + i) * sx, (488 + i) * sy,
        (146 + i) * sx, (488 + i) * sy,
        (138 + i) * sx, (484 + i) * sy
    );
    path.cubicTo(
        (132 + i) * sx, (480 + i) * sy,
        (132 + i) * sx, (474 + i) * sy,
        (136 + i) * sx, (468 + i) * sy
    );
    path.cubicTo(
        (140 + i) * sx, (456 + i) * sy,
        (140 + i) * sx, (442 + i) * sy,
        (138 + i) * sx, (428 + i) * sy
    );
    path.cubicTo(
        (136 + i) * sx, (410 + i) * sy,
        (136 + i) * sx, (392 + i) * sy,
        (138 + i) * sx, (378 + i) * sy
    );
    path.cubicTo(
        (140 + i) * sx, (352 + i) * sy,
        (136 + i) * sx, (332 + i) * sy,
        (132 + i) * sx, (312 + i) * sy
    );

    return path;
  }

  // ==================== АНАТОМИЧЕСКИЕ ЛИНИИ ====================
  void _drawAnatomicalLines(Canvas canvas, double sx, double sy) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    if (!showBack) {
      // Линия грудины
      final chestLine = Path()
        ..moveTo(baseWidth / 2 * sx, (110 + 12) * sy)
        ..cubicTo(
            baseWidth / 2 * sx, (130 + 12) * sy,
            baseWidth / 2 * sx, (150 + 12) * sy,
            baseWidth / 2 * sx, (170 + 12) * sy
        );
      canvas.drawPath(chestLine, paint);

      // Линия живота (Linea Alba)
      final absLine = Path()
        ..moveTo(baseWidth / 2 * sx, (174 + 12) * sy)
        ..cubicTo(
            baseWidth / 2 * sx, (200 + 12) * sy,
            baseWidth / 2 * sx, (226 + 12) * sy,
            baseWidth / 2 * sx, (260 + 12) * sy
        );
      canvas.drawPath(absLine, paint);

      // Сухожильные перемычки пресса
      for (int i = 0; i < 3; i++) {
        final y = (184 + i * 26 + 12) * sy;
        final line = Path()
          ..moveTo((110 + 10) * sx, y)
          ..cubicTo(
              (125 + 10) * sx, (y - 2),
              (155 + 10) * sx, (y - 2),
              (170 + 10) * sx, y
          );
        canvas.drawPath(line, paint);
      }
    } else {
      // Линия позвоночника
      final spine = Path()
        ..moveTo(baseWidth / 2 * sx, (100 + 12) * sy)
        ..cubicTo(
            baseWidth / 2 * sx, (140 + 12) * sy,
            baseWidth / 2 * sx, (180 + 12) * sy,
            baseWidth / 2 * sx, (230 + 12) * sy
        );
      canvas.drawPath(spine, paint);

      // Линия между ягодицами
      final gluteLine = Path()
        ..moveTo(baseWidth / 2 * sx, (260 + 12) * sy)
        ..cubicTo(
            baseWidth / 2 * sx, (280 + 12) * sy,
            baseWidth / 2 * sx, (300 + 12) * sy,
            baseWidth / 2 * sx, (315 + 12) * sy
        );
      canvas.drawPath(gluteLine, paint);
    }
  }

  // ==================== СВЕЧЕНИЕ ВЫБРАННОЙ МЫШЦЫ ====================
  void _drawSelectionGlow(Canvas canvas, double sx, double sy) {
    final muscle = selectedMuscle!;
    final paths = _getMusclePaths(muscle, sx, sy);
    final color = muscle.color;

    for (final path in paths) {
      final bounds = path.getBounds();
      final center = bounds.center;

      // Внешнее свечение
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.4),
            color.withOpacity(0.2),
            color.withOpacity(0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ).createShader(Rect.fromCenter(
          center: center,
          width: bounds.width * 2.8,
          height: bounds.height * 2.8,
        ))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawPath(path, glowPaint);

      // Внутреннее свечение
      final innerGlow = Paint()
        ..color = color.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawPath(path, innerGlow);
    }
  }

  // ==================== ОТРИСОВКА МЫШЦЫ ====================
  void _drawMuscle(Canvas canvas, MuscleGroup muscle, Path path) {
    final isSelected = selectedMuscle == muscle;
    final isHovered = hoveredMuscle == muscle;
    final volume = volumeData?[muscle] ?? 0;
    final volumes = volumeData?.values;
    double maxVolume = 1.0;
    if (volumes != null && volumes.isNotEmpty) {
      maxVolume = volumes.reduce((a, b) => a > b ? a : b);
    }

    Color baseColor = muscle.color;
    double opacity = 0.35;

    if (isSelected) {
      opacity = 0.85;
    } else if (isHovered) {
      opacity = 0.7;
    } else if (volumeData != null && volume > 0 && maxVolume > 0) {
      final intensity = volume / maxVolume;
      opacity = 0.25 + (intensity * 0.45);
    }

    final bounds = path.getBounds();

    // Слой 1: Базовый цвет
    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor.withOpacity(opacity * 1.3),
          baseColor.withOpacity(opacity * 0.85),
          baseColor.withOpacity(opacity * 1.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint1);

    // Слой 2: Тень (верхний левый угол)
    final paint2 = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.8,
        colors: [
          Colors.black.withOpacity(opacity * 0.5),
          Colors.black.withOpacity(opacity * 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint2);

    // Слой 3: Подсветка (нижний правый угол)
    final paint3 = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 1.5,
        colors: [
          Colors.white.withOpacity(opacity * 0.3),
          Colors.white.withOpacity(opacity * 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(bounds)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint3);

    // Слой 4: Обводка
    final paint4 = Paint()
      ..color = baseColor.withOpacity(
          isSelected ? 0.9 : isHovered ? 0.7 : 0.35
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : isHovered ? 1.5 : 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint4);

    // Слой 5: Блик (для выбранной)
    if (isSelected) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(path, highlightPaint);
    }
  }

  // ==================== ПЕРЕДНИЕ МЫШЦЫ ====================
  void _drawFrontMuscles(Canvas canvas, double sx, double sy) {
    _drawMuscle(canvas, MuscleGroup.traps, _getTrapsFrontPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.shoulders, _getShouldersFrontPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.chest, _getChestPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.biceps, _getBicepsFrontPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.triceps, _getTricepsFrontPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.forearms, _getForearmsFrontPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.abs, _getAbsPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.obliques, _getObliquesPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.quadriceps, _getQuadricepsPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.calves, _getCalvesFrontPath(sx, sy));
  }

  // ==================== ЗАДНИЕ МЫШЦЫ ====================
  void _drawBackMuscles(Canvas canvas, double sx, double sy) {
    _drawMuscle(canvas, MuscleGroup.traps, _getTrapsBackPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.shoulders, _getShouldersBackPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.back, _getBackPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.lats, _getLatsPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.triceps, _getTricepsBackPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.forearms, _getForearmsBackPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.lowerBack, _getLowerBackPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.glutes, _getGlutesPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.hamstrings, _getHamstringsPath(sx, sy));
    _drawMuscle(canvas, MuscleGroup.calves, _getCalvesBackPath(sx, sy));
  }

  // ==================== ПУТИ МЫШЦ (ПЕРЕД) ====================

  Path _getTrapsFrontPath(double sx, double sy) {
    return Path()
      ..moveTo((120) * sx, (80 + 12) * sy)
      ..cubicTo(
          (130) * sx, (76 + 12) * sy,
          (145) * sx, (76 + 12) * sy,
          (155) * sx, (80 + 12) * sy
      )
      ..cubicTo(
          (160) * sx, (86 + 12) * sy,
          (162) * sx, (94 + 12) * sy,
          (158) * sx, (102 + 12) * sy
      )
      ..cubicTo(
          (148) * sx, (98 + 12) * sy,
          (138) * sx, (96 + 12) * sy,
          (130) * sx, (96 + 12) * sy
      )
      ..cubicTo(
          (122) * sx, (96 + 12) * sy,
          (112) * sx, (98 + 12) * sy,
          (102) * sx, (102 + 12) * sy
      )
      ..cubicTo(
          (98) * sx, (94 + 12) * sy,
          (100) * sx, (86 + 12) * sy,
          (105) * sx, (80 + 12) * sy
      )
      ..cubicTo(
          (108) * sx, (78 + 12) * sy,
          (115) * sx, (78 + 12) * sy,
          (120) * sx, (80 + 12) * sy
      )
      ..close();
  }

  Path _getShouldersFrontPath(double sx, double sy) {
    final path = Path();

    // Левое плечо
    path.moveTo((80) * sx, (108 + 12) * sy);
    path.cubicTo(
        (70) * sx, (108 + 12) * sy,
        (62) * sx, (114 + 12) * sy,
        (58) * sx, (124 + 12) * sy
    );
    path.cubicTo(
        (54) * sx, (134 + 12) * sy,
        (56) * sx, (148 + 12) * sy,
        (64) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (72) * sx, (150 + 12) * sy,
        (80) * sx, (142 + 12) * sy,
        (84) * sx, (132 + 12) * sy
    );
    path.cubicTo(
        (88) * sx, (122 + 12) * sy,
        (86) * sx, (112 + 12) * sy,
        (80) * sx, (108 + 12) * sy
    );
    path.close();

    // Правое плечо
    path.moveTo((180) * sx, (108 + 12) * sy);
    path.cubicTo(
        (190) * sx, (108 + 12) * sy,
        (198) * sx, (114 + 12) * sy,
        (202) * sx, (124 + 12) * sy
    );
    path.cubicTo(
        (206) * sx, (134 + 12) * sy,
        (204) * sx, (148 + 12) * sy,
        (196) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (188) * sx, (150 + 12) * sy,
        (180) * sx, (142 + 12) * sy,
        (176) * sx, (132 + 12) * sy
    );
    path.cubicTo(
        (172) * sx, (122 + 12) * sy,
        (174) * sx, (112 + 12) * sy,
        (180) * sx, (108 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getChestPath(double sx, double sy) {
    final path = Path();

    // Левая грудь
    path.moveTo((88) * sx, (114 + 12) * sy);
    path.cubicTo(
        (96) * sx, (110 + 12) * sy,
        (112) * sx, (110 + 12) * sy,
        (128) * sx, (114 + 12) * sy
    );
    path.cubicTo(
        (128) * sx, (124 + 12) * sy,
        (126) * sx, (136 + 12) * sy,
        (122) * sx, (146 + 12) * sy
    );
    path.cubicTo(
        (114) * sx, (152 + 12) * sy,
        (102) * sx, (152 + 12) * sy,
        (94) * sx, (150 + 12) * sy
    );
    path.cubicTo(
        (86) * sx, (146 + 12) * sy,
        (82) * sx, (136 + 12) * sy,
        (82) * sx, (126 + 12) * sy
    );
    path.cubicTo(
        (82) * sx, (120 + 12) * sy,
        (84) * sx, (116 + 12) * sy,
        (88) * sx, (114 + 12) * sy
    );
    path.close();

    // Правая грудь
    path.moveTo((172) * sx, (114 + 12) * sy);
    path.cubicTo(
        (164) * sx, (110 + 12) * sy,
        (148) * sx, (110 + 12) * sy,
        (132) * sx, (114 + 12) * sy
    );
    path.cubicTo(
        (132) * sx, (124 + 12) * sy,
        (134) * sx, (136 + 12) * sy,
        (138) * sx, (146 + 12) * sy
    );
    path.cubicTo(
        (146) * sx, (152 + 12) * sy,
        (158) * sx, (152 + 12) * sy,
        (166) * sx, (150 + 12) * sy
    );
    path.cubicTo(
        (174) * sx, (146 + 12) * sy,
        (178) * sx, (136 + 12) * sy,
        (178) * sx, (126 + 12) * sy
    );
    path.cubicTo(
        (178) * sx, (120 + 12) * sy,
        (176) * sx, (116 + 12) * sy,
        (172) * sx, (114 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getBicepsFrontPath(double sx, double sy) {
    final path = Path();

    // Левый бицепс
    path.moveTo((68) * sx, (144 + 12) * sy);
    path.cubicTo(
        (62) * sx, (154 + 12) * sy,
        (56) * sx, (166 + 12) * sy,
        (54) * sx, (180 + 12) * sy
    );
    path.cubicTo(
        (52) * sx, (194 + 12) * sy,
        (56) * sx, (206 + 12) * sy,
        (64) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (72) * sx, (212 + 12) * sy,
        (78) * sx, (204 + 12) * sy,
        (82) * sx, (192 + 12) * sy
    );
    path.cubicTo(
        (86) * sx, (178 + 12) * sy,
        (84) * sx, (160 + 12) * sy,
        (80) * sx, (150 + 12) * sy
    );
    path.cubicTo(
        (78) * sx, (146 + 12) * sy,
        (74) * sx, (144 + 12) * sy,
        (68) * sx, (144 + 12) * sy
    );
    path.close();

    // Правый бицепс
    path.moveTo((192) * sx, (144 + 12) * sy);
    path.cubicTo(
        (198) * sx, (154 + 12) * sy,
        (204) * sx, (166 + 12) * sy,
        (206) * sx, (180 + 12) * sy
    );
    path.cubicTo(
        (208) * sx, (194 + 12) * sy,
        (204) * sx, (206 + 12) * sy,
        (196) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (188) * sx, (212 + 12) * sy,
        (182) * sx, (204 + 12) * sy,
        (178) * sx, (192 + 12) * sy
    );
    path.cubicTo(
        (174) * sx, (178 + 12) * sy,
        (176) * sx, (160 + 12) * sy,
        (180) * sx, (150 + 12) * sy
    );
    path.cubicTo(
        (182) * sx, (146 + 12) * sy,
        (186) * sx, (144 + 12) * sy,
        (192) * sx, (144 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getTricepsFrontPath(double sx, double sy) {
    final path = Path();

    path.moveTo((78) * sx, (142 + 12) * sy);
    path.cubicTo(
        (82) * sx, (154 + 12) * sy,
        (86) * sx, (170 + 12) * sy,
        (84) * sx, (186 + 12) * sy
    );
    path.cubicTo(
        (82) * sx, (196 + 12) * sy,
        (78) * sx, (202 + 12) * sy,
        (74) * sx, (202 + 12) * sy
    );
    path.cubicTo(
        (82) * sx, (198 + 12) * sy,
        (88) * sx, (190 + 12) * sy,
        (90) * sx, (178 + 12) * sy
    );
    path.cubicTo(
        (92) * sx, (162 + 12) * sy,
        (90) * sx, (148 + 12) * sy,
        (86) * sx, (138 + 12) * sy
    );
    path.cubicTo(
        (84) * sx, (138 + 12) * sy,
        (80) * sx, (140 + 12) * sy,
        (78) * sx, (142 + 12) * sy
    );
    path.close();

    path.moveTo((182) * sx, (142 + 12) * sy);
    path.cubicTo(
        (178) * sx, (154 + 12) * sy,
        (174) * sx, (170 + 12) * sy,
        (176) * sx, (186 + 12) * sy
    );
    path.cubicTo(
        (178) * sx, (196 + 12) * sy,
        (182) * sx, (202 + 12) * sy,
        (186) * sx, (202 + 12) * sy
    );
    path.cubicTo(
        (178) * sx, (198 + 12) * sy,
        (172) * sx, (190 + 12) * sy,
        (170) * sx, (178 + 12) * sy
    );
    path.cubicTo(
        (168) * sx, (162 + 12) * sy,
        (170) * sx, (148 + 12) * sy,
        (174) * sx, (138 + 12) * sy
    );
    path.cubicTo(
        (176) * sx, (138 + 12) * sy,
        (180) * sx, (140 + 12) * sy,
        (182) * sx, (142 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getForearmsFrontPath(double sx, double sy) {
    final path = Path();

    path.moveTo((58) * sx, (206 + 12) * sy);
    path.cubicTo(
        (52) * sx, (222 + 12) * sy,
        (50) * sx, (242 + 12) * sy,
        (50) * sx, (264 + 12) * sy
    );
    path.cubicTo(
        (50) * sx, (282 + 12) * sy,
        (52) * sx, (296 + 12) * sy,
        (60) * sx, (302 + 12) * sy
    );
    path.cubicTo(
        (68) * sx, (298 + 12) * sy,
        (74) * sx, (288 + 12) * sy,
        (74) * sx, (274 + 12) * sy
    );
    path.cubicTo(
        (74) * sx, (250 + 12) * sy,
        (70) * sx, (226 + 12) * sy,
        (66) * sx, (214 + 12) * sy
    );
    path.cubicTo(
        (64) * sx, (210 + 12) * sy,
        (62) * sx, (206 + 12) * sy,
        (58) * sx, (206 + 12) * sy
    );
    path.close();

    path.moveTo((202) * sx, (206 + 12) * sy);
    path.cubicTo(
        (208) * sx, (222 + 12) * sy,
        (210) * sx, (242 + 12) * sy,
        (210) * sx, (264 + 12) * sy
    );
    path.cubicTo(
        (210) * sx, (282 + 12) * sy,
        (208) * sx, (296 + 12) * sy,
        (200) * sx, (302 + 12) * sy
    );
    path.cubicTo(
        (192) * sx, (298 + 12) * sy,
        (186) * sx, (288 + 12) * sy,
        (186) * sx, (274 + 12) * sy
    );
    path.cubicTo(
        (186) * sx, (250 + 12) * sy,
        (190) * sx, (226 + 12) * sy,
        (194) * sx, (214 + 12) * sy
    );
    path.cubicTo(
        (196) * sx, (210 + 12) * sy,
        (198) * sx, (206 + 12) * sy,
        (202) * sx, (206 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getAbsPath(double sx, double sy) {
    return Path()
      ..moveTo((110) * sx, (154 + 12) * sy)
      ..cubicTo(
          (118) * sx, (152 + 12) * sy,
          (142) * sx, (152 + 12) * sy,
          (150) * sx, (154 + 12) * sy
      )
      ..cubicTo(
          (152) * sx, (178 + 12) * sy,
          (152) * sx, (204 + 12) * sy,
          (150) * sx, (230 + 12) * sy
      )
      ..cubicTo(
          (148) * sx, (248 + 12) * sy,
          (144) * sx, (262 + 12) * sy,
          (138) * sx, (268 + 12) * sy
      )
      ..cubicTo(
          (130) * sx, (272 + 12) * sy,
          (118) * sx, (272 + 12) * sy,
          (110) * sx, (268 + 12) * sy
      )
      ..cubicTo(
          (104) * sx, (262 + 12) * sy,
          (102) * sx, (248 + 12) * sy,
          (102) * sx, (230 + 12) * sy
      )
      ..cubicTo(
          (102) * sx, (204 + 12) * sy,
          (104) * sx, (178 + 12) * sy,
          (106) * sx, (154 + 12) * sy
      )
      ..close();
  }

  Path _getObliquesPath(double sx, double sy) {
    final path = Path();

    // Левые косые
    path.moveTo((90) * sx, (158 + 12) * sy);
    path.cubicTo(
        (94) * sx, (154 + 12) * sy,
        (104) * sx, (154 + 12) * sy,
        (110) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (108) * sx, (184 + 12) * sy,
        (106) * sx, (214 + 12) * sy,
        (102) * sx, (244 + 12) * sy
    );
    path.cubicTo(
        (96) * sx, (252 + 12) * sy,
        (90) * sx, (258 + 12) * sy,
        (84) * sx, (256 + 12) * sy
    );
    path.cubicTo(
        (80) * sx, (246 + 12) * sy,
        (80) * sx, (228 + 12) * sy,
        (82) * sx, (202 + 12) * sy
    );
    path.cubicTo(
        (84) * sx, (180 + 12) * sy,
        (86) * sx, (166 + 12) * sy,
        (90) * sx, (158 + 12) * sy
    );
    path.close();

    // Правые косые
    path.moveTo((170) * sx, (158 + 12) * sy);
    path.cubicTo(
        (166) * sx, (154 + 12) * sy,
        (156) * sx, (154 + 12) * sy,
        (150) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (152) * sx, (184 + 12) * sy,
        (154) * sx, (214 + 12) * sy,
        (158) * sx, (244 + 12) * sy
    );
    path.cubicTo(
        (164) * sx, (252 + 12) * sy,
        (170) * sx, (258 + 12) * sy,
        (176) * sx, (256 + 12) * sy
    );
    path.cubicTo(
        (180) * sx, (246 + 12) * sy,
        (180) * sx, (228 + 12) * sy,
        (178) * sx, (202 + 12) * sy
    );
    path.cubicTo(
        (176) * sx, (180 + 12) * sy,
        (174) * sx, (166 + 12) * sy,
        (170) * sx, (158 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getQuadricepsPath(double sx, double sy) {
    final path = Path();

    // Левый квадрицепс
    path.moveTo((96) * sx, (286 + 12) * sy);
    path.cubicTo(
        (106) * sx, (284 + 12) * sy,
        (116) * sx, (286 + 12) * sy,
        (122) * sx, (292 + 12) * sy
    );
    path.cubicTo(
        (124) * sx, (316 + 12) * sy,
        (122) * sx, (344 + 12) * sy,
        (118) * sx, (372 + 12) * sy
    );
    path.cubicTo(
        (112) * sx, (380 + 12) * sy,
        (102) * sx, (380 + 12) * sy,
        (94) * sx, (376 + 12) * sy
    );
    path.cubicTo(
        (90) * sx, (350 + 12) * sy,
        (90) * sx, (320 + 12) * sy,
        (96) * sx, (286 + 12) * sy
    );
    path.close();

    // Правый квадрицепс
    path.moveTo((164) * sx, (286 + 12) * sy);
    path.cubicTo(
        (154) * sx, (284 + 12) * sy,
        (144) * sx, (286 + 12) * sy,
        (138) * sx, (292 + 12) * sy
    );
    path.cubicTo(
        (136) * sx, (316 + 12) * sy,
        (138) * sx, (344 + 12) * sy,
        (142) * sx, (372 + 12) * sy
    );
    path.cubicTo(
        (148) * sx, (380 + 12) * sy,
        (158) * sx, (380 + 12) * sy,
        (166) * sx, (376 + 12) * sy
    );
    path.cubicTo(
        (170) * sx, (350 + 12) * sy,
        (170) * sx, (320 + 12) * sy,
        (164) * sx, (286 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getCalvesFrontPath(double sx, double sy) {
    final path = Path();

    // Левая икра
    path.moveTo((94) * sx, (376 + 12) * sy);
    path.cubicTo(
        (102) * sx, (374 + 12) * sy,
        (112) * sx, (376 + 12) * sy,
        (118) * sx, (382 + 12) * sy
    );
    path.cubicTo(
        (120) * sx, (400 + 12) * sy,
        (116) * sx, (416 + 12) * sy,
        (110) * sx, (428 + 12) * sy
    );
    path.cubicTo(
        (104) * sx, (432 + 12) * sy,
        (96) * sx, (432 + 12) * sy,
        (90) * sx, (428 + 12) * sy
    );
    path.cubicTo(
        (88) * sx, (414 + 12) * sy,
        (88) * sx, (396 + 12) * sy,
        (94) * sx, (376 + 12) * sy
    );
    path.close();

    // Правая икра
    path.moveTo((166) * sx, (376 + 12) * sy);
    path.cubicTo(
        (158) * sx, (374 + 12) * sy,
        (148) * sx, (376 + 12) * sy,
        (142) * sx, (382 + 12) * sy
    );
    path.cubicTo(
        (140) * sx, (400 + 12) * sy,
        (144) * sx, (416 + 12) * sy,
        (150) * sx, (428 + 12) * sy
    );
    path.cubicTo(
        (156) * sx, (432 + 12) * sy,
        (164) * sx, (432 + 12) * sy,
        (170) * sx, (428 + 12) * sy
    );
    path.cubicTo(
        (172) * sx, (414 + 12) * sy,
        (172) * sx, (396 + 12) * sy,
        (166) * sx, (376 + 12) * sy
    );
    path.close();

    return path;
  }

  // ==================== ПУТИ МЫШЦ (СПИНА) ====================

  Path _getTrapsBackPath(double sx, double sy) {
    return Path()
      ..moveTo((105) * sx, (80 + 12) * sy)
      ..cubicTo(
          (115) * sx, (76 + 12) * sy,
          (128) * sx, (74 + 12) * sy,
          (138) * sx, (76 + 12) * sy
      )
      ..cubicTo(
          (148) * sx, (78 + 12) * sy,
          (155) * sx, (82 + 12) * sy,
          (160) * sx, (88 + 12) * sy
      )
      ..cubicTo(
          (165) * sx, (96 + 12) * sy,
          (166) * sx, (106 + 12) * sy,
          (162) * sx, (116 + 12) * sy
      )
      ..cubicTo(
          (154) * sx, (110 + 12) * sy,
          (144) * sx, (106 + 12) * sy,
          (132) * sx, (106 + 12) * sy
      )
      ..cubicTo(
          (120) * sx, (106 + 12) * sy,
          (110) * sx, (110 + 12) * sy,
          (102) * sx, (116 + 12) * sy
      )
      ..cubicTo(
          (98) * sx, (106 + 12) * sy,
          (96) * sx, (96 + 12) * sy,
          (100) * sx, (86 + 12) * sy
      )
      ..cubicTo(
          (102) * sx, (82 + 12) * sy,
          (104) * sx, (80 + 12) * sy,
          (105) * sx, (80 + 12) * sy
      )
      ..close();
  }

  Path _getShouldersBackPath(double sx, double sy) {
    final path = Path();

    path.moveTo((80) * sx, (108 + 12) * sy);
    path.cubicTo(
        (68) * sx, (108 + 12) * sy,
        (58) * sx, (114 + 12) * sy,
        (52) * sx, (124 + 12) * sy
    );
    path.cubicTo(
        (48) * sx, (136 + 12) * sy,
        (52) * sx, (150 + 12) * sy,
        (62) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (72) * sx, (150 + 12) * sy,
        (80) * sx, (140 + 12) * sy,
        (84) * sx, (128 + 12) * sy
    );
    path.cubicTo(
        (86) * sx, (118 + 12) * sy,
        (84) * sx, (112 + 12) * sy,
        (80) * sx, (108 + 12) * sy
    );
    path.close();

    path.moveTo((180) * sx, (108 + 12) * sy);
    path.cubicTo(
        (192) * sx, (108 + 12) * sy,
        (202) * sx, (114 + 12) * sy,
        (208) * sx, (124 + 12) * sy
    );
    path.cubicTo(
        (212) * sx, (136 + 12) * sy,
        (208) * sx, (150 + 12) * sy,
        (198) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (188) * sx, (150 + 12) * sy,
        (180) * sx, (140 + 12) * sy,
        (176) * sx, (128 + 12) * sy
    );
    path.cubicTo(
        (174) * sx, (118 + 12) * sy,
        (176) * sx, (112 + 12) * sy,
        (180) * sx, (108 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getBackPath(double sx, double sy) {
    return Path()
      ..moveTo((98) * sx, (122 + 12) * sy)
      ..cubicTo(
          (108) * sx, (118 + 12) * sy,
          (122) * sx, (116 + 12) * sy,
          (132) * sx, (116 + 12) * sy
      )
      ..cubicTo(
          (142) * sx, (116 + 12) * sy,
          (156) * sx, (118 + 12) * sy,
          (166) * sx, (122 + 12) * sy
      )
      ..cubicTo(
          (172) * sx, (134 + 12) * sy,
          (174) * sx, (148 + 12) * sy,
          (170) * sx, (162 + 12) * sy
      )
      ..cubicTo(
          (160) * sx, (158 + 12) * sy,
          (148) * sx, (154 + 12) * sy,
          (136) * sx, (154 + 12) * sy
      )
      ..cubicTo(
          (124) * sx, (154 + 12) * sy,
          (112) * sx, (158 + 12) * sy,
          (102) * sx, (162 + 12) * sy
      )
      ..cubicTo(
          (98) * sx, (148 + 12) * sy,
          (96) * sx, (134 + 12) * sy,
          (98) * sx, (122 + 12) * sy
      )
      ..close();
  }

  Path _getLatsPath(double sx, double sy) {
    final path = Path();

    path.moveTo((90) * sx, (150 + 12) * sy);
    path.cubicTo(
        (86) * sx, (168 + 12) * sy,
        (86) * sx, (190 + 12) * sy,
        (90) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (96) * sx, (224 + 12) * sy,
        (106) * sx, (228 + 12) * sy,
        (118) * sx, (224 + 12) * sy
    );
    path.cubicTo(
        (126) * sx, (212 + 12) * sy,
        (130) * sx, (192 + 12) * sy,
        (128) * sx, (168 + 12) * sy
    );
    path.cubicTo(
        (120) * sx, (154 + 12) * sy,
        (108) * sx, (148 + 12) * sy,
        (90) * sx, (150 + 12) * sy
    );
    path.close();

    path.moveTo((170) * sx, (150 + 12) * sy);
    path.cubicTo(
        (174) * sx, (168 + 12) * sy,
        (174) * sx, (190 + 12) * sy,
        (170) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (164) * sx, (224 + 12) * sy,
        (154) * sx, (228 + 12) * sy,
        (142) * sx, (224 + 12) * sy
    );
    path.cubicTo(
        (134) * sx, (212 + 12) * sy,
        (130) * sx, (192 + 12) * sy,
        (132) * sx, (168 + 12) * sy
    );
    path.cubicTo(
        (140) * sx, (154 + 12) * sy,
        (152) * sx, (148 + 12) * sy,
        (170) * sx, (150 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getTricepsBackPath(double sx, double sy) {
    final path = Path();

    path.moveTo((72) * sx, (146 + 12) * sy);
    path.cubicTo(
        (64) * sx, (158 + 12) * sy,
        (60) * sx, (176 + 12) * sy,
        (62) * sx, (196 + 12) * sy
    );
    path.cubicTo(
        (64) * sx, (208 + 12) * sy,
        (70) * sx, (214 + 12) * sy,
        (78) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (84) * sx, (202 + 12) * sy,
        (86) * sx, (184 + 12) * sy,
        (84) * sx, (166 + 12) * sy
    );
    path.cubicTo(
        (82) * sx, (156 + 12) * sy,
        (78) * sx, (148 + 12) * sy,
        (72) * sx, (146 + 12) * sy
    );
    path.close();

    path.moveTo((188) * sx, (146 + 12) * sy);
    path.cubicTo(
        (196) * sx, (158 + 12) * sy,
        (200) * sx, (176 + 12) * sy,
        (198) * sx, (196 + 12) * sy
    );
    path.cubicTo(
        (196) * sx, (208 + 12) * sy,
        (190) * sx, (214 + 12) * sy,
        (182) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (176) * sx, (202 + 12) * sy,
        (174) * sx, (184 + 12) * sy,
        (176) * sx, (166 + 12) * sy
    );
    path.cubicTo(
        (178) * sx, (156 + 12) * sy,
        (182) * sx, (148 + 12) * sy,
        (188) * sx, (146 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getForearmsBackPath(double sx, double sy) {
    final path = Path();

    path.moveTo((62) * sx, (210 + 12) * sy);
    path.cubicTo(
        (56) * sx, (228 + 12) * sy,
        (52) * sx, (250 + 12) * sy,
        (54) * sx, (274 + 12) * sy
    );
    path.cubicTo(
        (56) * sx, (290 + 12) * sy,
        (62) * sx, (302 + 12) * sy,
        (72) * sx, (304 + 12) * sy
    );
    path.cubicTo(
        (78) * sx, (294 + 12) * sy,
        (80) * sx, (278 + 12) * sy,
        (78) * sx, (258 + 12) * sy
    );
    path.cubicTo(
        (76) * sx, (234 + 12) * sy,
        (72) * sx, (218 + 12) * sy,
        (68) * sx, (210 + 12) * sy
    );
    path.cubicTo(
        (66) * sx, (208 + 12) * sy,
        (64) * sx, (208 + 12) * sy,
        (62) * sx, (210 + 12) * sy
    );
    path.close();

    path.moveTo((198) * sx, (210 + 12) * sy);
    path.cubicTo(
        (204) * sx, (228 + 12) * sy,
        (208) * sx, (250 + 12) * sy,
        (206) * sx, (274 + 12) * sy
    );
    path.cubicTo(
        (204) * sx, (290 + 12) * sy,
        (198) * sx, (302 + 12) * sy,
        (188) * sx, (304 + 12) * sy
    );
    path.cubicTo(
        (182) * sx, (294 + 12) * sy,
        (180) * sx, (278 + 12) * sy,
        (182) * sx, (258 + 12) * sy
    );
    path.cubicTo(
        (184) * sx, (234 + 12) * sy,
        (188) * sx, (218 + 12) * sy,
        (192) * sx, (210 + 12) * sy
    );
    path.cubicTo(
        (194) * sx, (208 + 12) * sy,
        (196) * sx, (208 + 12) * sy,
        (198) * sx, (210 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getLowerBackPath(double sx, double sy) {
    return Path()
      ..moveTo((104) * sx, (232 + 12) * sy)
      ..cubicTo(
          (114) * sx, (230 + 12) * sy,
          (146) * sx, (230 + 12) * sy,
          (156) * sx, (232 + 12) * sy
      )
      ..cubicTo(
          (158) * sx, (248 + 12) * sy,
          (158) * sx, (266 + 12) * sy,
          (154) * sx, (280 + 12) * sy
      )
      ..cubicTo(
          (146) * sx, (286 + 12) * sy,
          (114) * sx, (286 + 12) * sy,
          (106) * sx, (280 + 12) * sy
      )
      ..cubicTo(
          (102) * sx, (266 + 12) * sy,
          (102) * sx, (248 + 12) * sy,
          (104) * sx, (232 + 12) * sy
      )
      ..close();
  }

  Path _getGlutesPath(double sx, double sy) {
    final path = Path();

    path.moveTo((96) * sx, (268 + 12) * sy);
    path.cubicTo(
        (104) * sx, (266 + 12) * sy,
        (120) * sx, (266 + 12) * sy,
        (130) * sx, (268 + 12) * sy
    );
    path.cubicTo(
        (130) * sx, (290 + 12) * sy,
        (126) * sx, (308 + 12) * sy,
        (116) * sx, (314 + 12) * sy
    );
    path.cubicTo(
        (104) * sx, (314 + 12) * sy,
        (92) * sx, (306 + 12) * sy,
        (86) * sx, (294 + 12) * sy
    );
    path.cubicTo(
        (86) * sx, (284 + 12) * sy,
        (88) * sx, (276 + 12) * sy,
        (96) * sx, (268 + 12) * sy
    );
    path.close();

    path.moveTo((164) * sx, (268 + 12) * sy);
    path.cubicTo(
        (156) * sx, (266 + 12) * sy,
        (140) * sx, (266 + 12) * sy,
        (130) * sx, (268 + 12) * sy
    );
    path.cubicTo(
        (130) * sx, (290 + 12) * sy,
        (134) * sx, (308 + 12) * sy,
        (144) * sx, (314 + 12) * sy
    );
    path.cubicTo(
        (156) * sx, (314 + 12) * sy,
        (168) * sx, (306 + 12) * sy,
        (174) * sx, (294 + 12) * sy
    );
    path.cubicTo(
        (174) * sx, (284 + 12) * sy,
        (172) * sx, (276 + 12) * sy,
        (164) * sx, (268 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getHamstringsPath(double sx, double sy) {
    final path = Path();

    path.moveTo((96) * sx, (302 + 12) * sy);
    path.cubicTo(
        (104) * sx, (300 + 12) * sy,
        (114) * sx, (302 + 12) * sy,
        (120) * sx, (308 + 12) * sy
    );
    path.cubicTo(
        (122) * sx, (332 + 12) * sy,
        (120) * sx, (358 + 12) * sy,
        (116) * sx, (380 + 12) * sy
    );
    path.cubicTo(
        (110) * sx, (386 + 12) * sy,
        (100) * sx, (386 + 12) * sy,
        (92) * sx, (382 + 12) * sy
    );
    path.cubicTo(
        (88) * sx, (358 + 12) * sy,
        (88) * sx, (330 + 12) * sy,
        (96) * sx, (302 + 12) * sy
    );
    path.close();

    path.moveTo((164) * sx, (302 + 12) * sy);
    path.cubicTo(
        (156) * sx, (300 + 12) * sy,
        (146) * sx, (302 + 12) * sy,
        (140) * sx, (308 + 12) * sy
    );
    path.cubicTo(
        (138) * sx, (332 + 12) * sy,
        (140) * sx, (358 + 12) * sy,
        (144) * sx, (380 + 12) * sy
    );
    path.cubicTo(
        (150) * sx, (386 + 12) * sy,
        (160) * sx, (386 + 12) * sy,
        (168) * sx, (382 + 12) * sy
    );
    path.cubicTo(
        (172) * sx, (358 + 12) * sy,
        (172) * sx, (330 + 12) * sy,
        (164) * sx, (302 + 12) * sy
    );
    path.close();

    return path;
  }

  Path _getCalvesBackPath(double sx, double sy) {
    final path = Path();

    path.moveTo((94) * sx, (382 + 12) * sy);
    path.cubicTo(
        (102) * sx, (380 + 12) * sy,
        (114) * sx, (382 + 12) * sy,
        (120) * sx, (388 + 12) * sy
    );
    path.cubicTo(
        (122) * sx, (408 + 12) * sy,
        (118) * sx, (426 + 12) * sy,
        (112) * sx, (434 + 12) * sy
    );
    path.cubicTo(
        (106) * sx, (438 + 12) * sy,
        (98) * sx, (438 + 12) * sy,
        (92) * sx, (434 + 12) * sy
    );
    path.cubicTo(
        (90) * sx, (422 + 12) * sy,
        (90) * sx, (402 + 12) * sy,
        (94) * sx, (382 + 12) * sy
    );
    path.close();

    path.moveTo((166) * sx, (382 + 12) * sy);
    path.cubicTo(
        (158) * sx, (380 + 12) * sy,
        (146) * sx, (382 + 12) * sy,
        (140) * sx, (388 + 12) * sy
    );
    path.cubicTo(
        (138) * sx, (408 + 12) * sy,
        (142) * sx, (426 + 12) * sy,
        (148) * sx, (434 + 12) * sy
    );
    path.cubicTo(
        (154) * sx, (438 + 12) * sy,
        (162) * sx, (438 + 12) * sy,
        (168) * sx, (434 + 12) * sy
    );
    path.cubicTo(
        (170) * sx, (422 + 12) * sy,
        (170) * sx, (402 + 12) * sy,
        (166) * sx, (382 + 12) * sy
    );
    path.close();

    return path;
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  List<Path> _getMusclePaths(MuscleGroup muscle, double sx, double sy) {
    if (showBack) {
      switch (muscle) {
        case MuscleGroup.traps:
          return [_getTrapsBackPath(sx, sy)];
        case MuscleGroup.shoulders:
          return [_getShouldersBackPath(sx, sy)];
        case MuscleGroup.back:
          return [_getBackPath(sx, sy)];
        case MuscleGroup.lats:
          return [_getLatsPath(sx, sy)];
        case MuscleGroup.triceps:
          return [_getTricepsBackPath(sx, sy)];
        case MuscleGroup.forearms:
          return [_getForearmsBackPath(sx, sy)];
        case MuscleGroup.lowerBack:
          return [_getLowerBackPath(sx, sy)];
        case MuscleGroup.glutes:
          return [_getGlutesPath(sx, sy)];
        case MuscleGroup.hamstrings:
          return [_getHamstringsPath(sx, sy)];
        case MuscleGroup.calves:
          return [_getCalvesBackPath(sx, sy)];
        default:
          return [];
      }
    } else {
      switch (muscle) {
        case MuscleGroup.traps:
          return [_getTrapsFrontPath(sx, sy)];
        case MuscleGroup.shoulders:
          return [_getShouldersFrontPath(sx, sy)];
        case MuscleGroup.chest:
          return [_getChestPath(sx, sy)];
        case MuscleGroup.biceps:
          return [_getBicepsFrontPath(sx, sy)];
        case MuscleGroup.triceps:
          return [_getTricepsFrontPath(sx, sy)];
        case MuscleGroup.forearms:
          return [_getForearmsFrontPath(sx, sy)];
        case MuscleGroup.abs:
          return [_getAbsPath(sx, sy)];
        case MuscleGroup.obliques:
          return [_getObliquesPath(sx, sy)];
        case MuscleGroup.quadriceps:
          return [_getQuadricepsPath(sx, sy)];
        case MuscleGroup.calves:
          return [_getCalvesFrontPath(sx, sy)];
        default:
          return [];
      }
    }
  }

  @override
  bool shouldRepaint(covariant MuscleMapPainter oldDelegate) {
    return oldDelegate.selectedMuscle != selectedMuscle ||
        oldDelegate.hoveredMuscle != hoveredMuscle ||
        oldDelegate.volumeData != volumeData ||
        oldDelegate.showBack != showBack;
  }
}

// ==================== ИНТЕРАКТИВНАЯ ВЕРСИЯ ====================

class InteractiveMuscleMap extends StatefulWidget {
  final Function(MuscleGroup)? onMuscleSelected;
  final MuscleGroup? initialSelected;
  final Map<MuscleGroup, double>? volumeData;

  const InteractiveMuscleMap({
    super.key,
    this.onMuscleSelected,
    this.initialSelected,
    this.volumeData,
  });

  @override
  State<InteractiveMuscleMap> createState() => _InteractiveMuscleMapState();
}

class _InteractiveMuscleMapState extends State<InteractiveMuscleMap> {
  MuscleGroup? _selected;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D24) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewButton('👤 Перед', !_showBack, () {
                setState(() => _showBack = false);
              }, isDark),
              const SizedBox(width: 4),
              _buildViewButton('🔙 Спина', _showBack, () {
                setState(() => _showBack = true);
              }, isDark),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (details) {
                  final muscle = _hitTestMuscle(
                    details.localPosition,
                    Size(constraints.maxWidth, constraints.maxHeight),
                  );
                  if (muscle != null) {
                    HapticFeedback.lightImpact();
                    setState(() => _selected = muscle);
                    widget.onMuscleSelected?.call(muscle);
                  }
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: MuscleMapPainter(
                    selectedMuscle: _selected,
                    hoveredMuscle: null,
                    volumeData: widget.volumeData,
                    isDark: isDark,
                    showBack: _showBack,
                  ),
                ),
              );
            },
          ),
        ),
        if (_selected != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _selected!.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _selected!.color.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _selected!.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _selected!.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _selected!.color,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildViewButton(String label, bool isActive, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF6B35) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  MuscleGroup? _hitTestMuscle(Offset position, Size size) {
    final sx = size.width / MuscleMapPainter.baseWidth;
    final sy = size.height / MuscleMapPainter.baseHeight;

    final paths = <MapEntry<MuscleGroup, Path>>[];

    if (_showBack) {
      paths.addAll([
        MapEntry(MuscleGroup.shoulders, _getShouldersBackPathStatic(sx, sy)),
        MapEntry(MuscleGroup.traps, _getTrapsBackPathStatic(sx, sy)),
        MapEntry(MuscleGroup.triceps, _getTricepsBackPathStatic(sx, sy)),
        MapEntry(MuscleGroup.forearms, _getForearmsBackPathStatic(sx, sy)),
        MapEntry(MuscleGroup.back, _getBackPathStatic(sx, sy)),
        MapEntry(MuscleGroup.lats, _getLatsPathStatic(sx, sy)),
        MapEntry(MuscleGroup.lowerBack, _getLowerBackPathStatic(sx, sy)),
        MapEntry(MuscleGroup.glutes, _getGlutesPathStatic(sx, sy)),
        MapEntry(MuscleGroup.hamstrings, _getHamstringsPathStatic(sx, sy)),
        MapEntry(MuscleGroup.calves, _getCalvesBackPathStatic(sx, sy)),
      ]);
    } else {
      paths.addAll([
        MapEntry(MuscleGroup.shoulders, _getShouldersFrontPathStatic(sx, sy)),
        MapEntry(MuscleGroup.traps, _getTrapsFrontPathStatic(sx, sy)),
        MapEntry(MuscleGroup.chest, _getChestPathStatic(sx, sy)),
        MapEntry(MuscleGroup.biceps, _getBicepsFrontPathStatic(sx, sy)),
        MapEntry(MuscleGroup.triceps, _getTricepsFrontPathStatic(sx, sy)),
        MapEntry(MuscleGroup.forearms, _getForearmsFrontPathStatic(sx, sy)),
        MapEntry(MuscleGroup.abs, _getAbsPathStatic(sx, sy)),
        MapEntry(MuscleGroup.obliques, _getObliquesPathStatic(sx, sy)),
        MapEntry(MuscleGroup.quadriceps, _getQuadricepsPathStatic(sx, sy)),
        MapEntry(MuscleGroup.calves, _getCalvesFrontPathStatic(sx, sy)),
      ]);
    }

    for (final entry in paths) {
      if (entry.value.contains(position)) {
        return entry.key;
      }
    }
    return null;
  }

  // Статические методы для hit test
  static Path _getTrapsFrontPathStatic(double sx, double sy) {
    return Path()
      ..moveTo((120) * sx, (80 + 12) * sy)
      ..cubicTo(
          (130) * sx, (76 + 12) * sy,
          (145) * sx, (76 + 12) * sy,
          (155) * sx, (80 + 12) * sy
      )
      ..cubicTo(
          (160) * sx, (86 + 12) * sy,
          (162) * sx, (94 + 12) * sy,
          (158) * sx, (102 + 12) * sy
      )
      ..cubicTo(
          (148) * sx, (98 + 12) * sy,
          (138) * sx, (96 + 12) * sy,
          (130) * sx, (96 + 12) * sy
      )
      ..cubicTo(
          (122) * sx, (96 + 12) * sy,
          (112) * sx, (98 + 12) * sy,
          (102) * sx, (102 + 12) * sy
      )
      ..cubicTo(
          (98) * sx, (94 + 12) * sy,
          (100) * sx, (86 + 12) * sy,
          (105) * sx, (80 + 12) * sy
      )
      ..cubicTo(
          (108) * sx, (78 + 12) * sy,
          (115) * sx, (78 + 12) * sy,
          (120) * sx, (80 + 12) * sy
      )
      ..close();
  }

  static Path _getShouldersFrontPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((80) * sx, (108 + 12) * sy);
    path.cubicTo(
        (70) * sx, (108 + 12) * sy,
        (62) * sx, (114 + 12) * sy,
        (58) * sx, (124 + 12) * sy
    );
    path.cubicTo(
        (54) * sx, (134 + 12) * sy,
        (56) * sx, (148 + 12) * sy,
        (64) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (72) * sx, (150 + 12) * sy,
        (80) * sx, (142 + 12) * sy,
        (84) * sx, (132 + 12) * sy
    );
    path.cubicTo(
        (88) * sx, (122 + 12) * sy,
        (86) * sx, (112 + 12) * sy,
        (80) * sx, (108 + 12) * sy
    );
    path.close();
    path.moveTo((180) * sx, (108 + 12) * sy);
    path.cubicTo(
        (190) * sx, (108 + 12) * sy,
        (198) * sx, (114 + 12) * sy,
        (202) * sx, (124 + 12) * sy
    );
    path.cubicTo(
        (206) * sx, (134 + 12) * sy,
        (204) * sx, (148 + 12) * sy,
        (196) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (188) * sx, (150 + 12) * sy,
        (180) * sx, (142 + 12) * sy,
        (176) * sx, (132 + 12) * sy
    );
    path.cubicTo(
        (172) * sx, (122 + 12) * sy,
        (174) * sx, (112 + 12) * sy,
        (180) * sx, (108 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getChestPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((88) * sx, (114 + 12) * sy);
    path.cubicTo(
        (96) * sx, (110 + 12) * sy,
        (112) * sx, (110 + 12) * sy,
        (128) * sx, (114 + 12) * sy
    );
    path.cubicTo(
        (128) * sx, (124 + 12) * sy,
        (126) * sx, (136 + 12) * sy,
        (122) * sx, (146 + 12) * sy
    );
    path.cubicTo(
        (114) * sx, (152 + 12) * sy,
        (102) * sx, (152 + 12) * sy,
        (94) * sx, (150 + 12) * sy
    );
    path.cubicTo(
        (86) * sx, (146 + 12) * sy,
        (82) * sx, (136 + 12) * sy,
        (82) * sx, (126 + 12) * sy
    );
    path.cubicTo(
        (82) * sx, (120 + 12) * sy,
        (84) * sx, (116 + 12) * sy,
        (88) * sx, (114 + 12) * sy
    );
    path.close();
    path.moveTo((172) * sx, (114 + 12) * sy);
    path.cubicTo(
        (164) * sx, (110 + 12) * sy,
        (148) * sx, (110 + 12) * sy,
        (132) * sx, (114 + 12) * sy
    );
    path.cubicTo(
        (132) * sx, (124 + 12) * sy,
        (134) * sx, (136 + 12) * sy,
        (138) * sx, (146 + 12) * sy
    );
    path.cubicTo(
        (146) * sx, (152 + 12) * sy,
        (158) * sx, (152 + 12) * sy,
        (166) * sx, (150 + 12) * sy
    );
    path.cubicTo(
        (174) * sx, (146 + 12) * sy,
        (178) * sx, (136 + 12) * sy,
        (178) * sx, (126 + 12) * sy
    );
    path.cubicTo(
        (178) * sx, (120 + 12) * sy,
        (176) * sx, (116 + 12) * sy,
        (172) * sx, (114 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getBicepsFrontPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((68) * sx, (144 + 12) * sy);
    path.cubicTo(
        (62) * sx, (154 + 12) * sy,
        (56) * sx, (166 + 12) * sy,
        (54) * sx, (180 + 12) * sy
    );
    path.cubicTo(
        (52) * sx, (194 + 12) * sy,
        (56) * sx, (206 + 12) * sy,
        (64) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (72) * sx, (212 + 12) * sy,
        (78) * sx, (204 + 12) * sy,
        (82) * sx, (192 + 12) * sy
    );
    path.cubicTo(
        (86) * sx, (178 + 12) * sy,
        (84) * sx, (160 + 12) * sy,
        (80) * sx, (150 + 12) * sy
    );
    path.cubicTo(
        (78) * sx, (146 + 12) * sy,
        (74) * sx, (144 + 12) * sy,
        (68) * sx, (144 + 12) * sy
    );
    path.close();
    path.moveTo((192) * sx, (144 + 12) * sy);
    path.cubicTo(
        (198) * sx, (154 + 12) * sy,
        (204) * sx, (166 + 12) * sy,
        (206) * sx, (180 + 12) * sy
    );
    path.cubicTo(
        (208) * sx, (194 + 12) * sy,
        (204) * sx, (206 + 12) * sy,
        (196) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (188) * sx, (212 + 12) * sy,
        (182) * sx, (204 + 12) * sy,
        (178) * sx, (192 + 12) * sy
    );
    path.cubicTo(
        (174) * sx, (178 + 12) * sy,
        (176) * sx, (160 + 12) * sy,
        (180) * sx, (150 + 12) * sy
    );
    path.cubicTo(
        (182) * sx, (146 + 12) * sy,
        (186) * sx, (144 + 12) * sy,
        (192) * sx, (144 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getTricepsFrontPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((78) * sx, (142 + 12) * sy);
    path.cubicTo(
        (82) * sx, (154 + 12) * sy,
        (86) * sx, (170 + 12) * sy,
        (84) * sx, (186 + 12) * sy
    );
    path.cubicTo(
        (82) * sx, (196 + 12) * sy,
        (78) * sx, (202 + 12) * sy,
        (74) * sx, (202 + 12) * sy
    );
    path.cubicTo(
        (82) * sx, (198 + 12) * sy,
        (88) * sx, (190 + 12) * sy,
        (90) * sx, (178 + 12) * sy
    );
    path.cubicTo(
        (92) * sx, (162 + 12) * sy,
        (90) * sx, (148 + 12) * sy,
        (86) * sx, (138 + 12) * sy
    );
    path.cubicTo(
        (84) * sx, (138 + 12) * sy,
        (80) * sx, (140 + 12) * sy,
        (78) * sx, (142 + 12) * sy
    );
    path.close();
    path.moveTo((182) * sx, (142 + 12) * sy);
    path.cubicTo(
        (178) * sx, (154 + 12) * sy,
        (174) * sx, (170 + 12) * sy,
        (176) * sx, (186 + 12) * sy
    );
    path.cubicTo(
        (178) * sx, (196 + 12) * sy,
        (182) * sx, (202 + 12) * sy,
        (186) * sx, (202 + 12) * sy
    );
    path.cubicTo(
        (178) * sx, (198 + 12) * sy,
        (172) * sx, (190 + 12) * sy,
        (170) * sx, (178 + 12) * sy
    );
    path.cubicTo(
        (168) * sx, (162 + 12) * sy,
        (170) * sx, (148 + 12) * sy,
        (174) * sx, (138 + 12) * sy
    );
    path.cubicTo(
        (176) * sx, (138 + 12) * sy,
        (180) * sx, (140 + 12) * sy,
        (182) * sx, (142 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getForearmsFrontPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((58) * sx, (206 + 12) * sy);
    path.cubicTo(
        (52) * sx, (222 + 12) * sy,
        (50) * sx, (242 + 12) * sy,
        (50) * sx, (264 + 12) * sy
    );
    path.cubicTo(
        (50) * sx, (282 + 12) * sy,
        (52) * sx, (296 + 12) * sy,
        (60) * sx, (302 + 12) * sy
    );
    path.cubicTo(
        (68) * sx, (298 + 12) * sy,
        (74) * sx, (288 + 12) * sy,
        (74) * sx, (274 + 12) * sy
    );
    path.cubicTo(
        (74) * sx, (250 + 12) * sy,
        (70) * sx, (226 + 12) * sy,
        (66) * sx, (214 + 12) * sy
    );
    path.cubicTo(
        (64) * sx, (210 + 12) * sy,
        (62) * sx, (206 + 12) * sy,
        (58) * sx, (206 + 12) * sy
    );
    path.close();
    path.moveTo((202) * sx, (206 + 12) * sy);
    path.cubicTo(
        (208) * sx, (222 + 12) * sy,
        (210) * sx, (242 + 12) * sy,
        (210) * sx, (264 + 12) * sy
    );
    path.cubicTo(
        (210) * sx, (282 + 12) * sy,
        (208) * sx, (296 + 12) * sy,
        (200) * sx, (302 + 12) * sy
    );
    path.cubicTo(
        (192) * sx, (298 + 12) * sy,
        (186) * sx, (288 + 12) * sy,
        (186) * sx, (274 + 12) * sy
    );
    path.cubicTo(
        (186) * sx, (250 + 12) * sy,
        (190) * sx, (226 + 12) * sy,
        (194) * sx, (214 + 12) * sy
    );
    path.cubicTo(
        (196) * sx, (210 + 12) * sy,
        (198) * sx, (206 + 12) * sy,
        (202) * sx, (206 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getAbsPathStatic(double sx, double sy) {
    return Path()
      ..moveTo((110) * sx, (154 + 12) * sy)
      ..cubicTo(
          (118) * sx, (152 + 12) * sy,
          (142) * sx, (152 + 12) * sy,
          (150) * sx, (154 + 12) * sy
      )
      ..cubicTo(
          (152) * sx, (178 + 12) * sy,
          (152) * sx, (204 + 12) * sy,
          (150) * sx, (230 + 12) * sy
      )
      ..cubicTo(
          (148) * sx, (248 + 12) * sy,
          (144) * sx, (262 + 12) * sy,
          (138) * sx, (268 + 12) * sy
      )
      ..cubicTo(
          (130) * sx, (272 + 12) * sy,
          (118) * sx, (272 + 12) * sy,
          (110) * sx, (268 + 12) * sy
      )
      ..cubicTo(
          (104) * sx, (262 + 12) * sy,
          (102) * sx, (248 + 12) * sy,
          (102) * sx, (230 + 12) * sy
      )
      ..cubicTo(
          (102) * sx, (204 + 12) * sy,
          (104) * sx, (178 + 12) * sy,
          (106) * sx, (154 + 12) * sy
      )
      ..close();
  }

  static Path _getObliquesPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((90) * sx, (158 + 12) * sy);
    path.cubicTo(
        (94) * sx, (154 + 12) * sy,
        (104) * sx, (154 + 12) * sy,
        (110) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (108) * sx, (184 + 12) * sy,
        (106) * sx, (214 + 12) * sy,
        (102) * sx, (244 + 12) * sy
    );
    path.cubicTo(
        (96) * sx, (252 + 12) * sy,
        (90) * sx, (258 + 12) * sy,
        (84) * sx, (256 + 12) * sy
    );
    path.cubicTo(
        (80) * sx, (246 + 12) * sy,
        (80) * sx, (228 + 12) * sy,
        (82) * sx, (202 + 12) * sy
    );
    path.cubicTo(
        (84) * sx, (180 + 12) * sy,
        (86) * sx, (166 + 12) * sy,
        (90) * sx, (158 + 12) * sy
    );
    path.close();
    path.moveTo((170) * sx, (158 + 12) * sy);
    path.cubicTo(
        (166) * sx, (154 + 12) * sy,
        (156) * sx, (154 + 12) * sy,
        (150) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (152) * sx, (184 + 12) * sy,
        (154) * sx, (214 + 12) * sy,
        (158) * sx, (244 + 12) * sy
    );
    path.cubicTo(
        (164) * sx, (252 + 12) * sy,
        (170) * sx, (258 + 12) * sy,
        (176) * sx, (256 + 12) * sy
    );
    path.cubicTo(
        (180) * sx, (246 + 12) * sy,
        (180) * sx, (228 + 12) * sy,
        (178) * sx, (202 + 12) * sy
    );
    path.cubicTo(
        (176) * sx, (180 + 12) * sy,
        (174) * sx, (166 + 12) * sy,
        (170) * sx, (158 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getQuadricepsPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((96) * sx, (286 + 12) * sy);
    path.cubicTo(
        (106) * sx, (284 + 12) * sy,
        (116) * sx, (286 + 12) * sy,
        (122) * sx, (292 + 12) * sy
    );
    path.cubicTo(
        (124) * sx, (316 + 12) * sy,
        (122) * sx, (344 + 12) * sy,
        (118) * sx, (372 + 12) * sy
    );
    path.cubicTo(
        (112) * sx, (380 + 12) * sy,
        (102) * sx, (380 + 12) * sy,
        (94) * sx, (376 + 12) * sy
    );
    path.cubicTo(
        (90) * sx, (350 + 12) * sy,
        (90) * sx, (320 + 12) * sy,
        (96) * sx, (286 + 12) * sy
    );
    path.close();
    path.moveTo((164) * sx, (286 + 12) * sy);
    path.cubicTo(
        (154) * sx, (284 + 12) * sy,
        (144) * sx, (286 + 12) * sy,
        (138) * sx, (292 + 12) * sy
    );
    path.cubicTo(
        (136) * sx, (316 + 12) * sy,
        (138) * sx, (344 + 12) * sy,
        (142) * sx, (372 + 12) * sy
    );
    path.cubicTo(
        (148) * sx, (380 + 12) * sy,
        (158) * sx, (380 + 12) * sy,
        (166) * sx, (376 + 12) * sy
    );
    path.cubicTo(
        (170) * sx, (350 + 12) * sy,
        (170) * sx, (320 + 12) * sy,
        (164) * sx, (286 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getCalvesFrontPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((94) * sx, (376 + 12) * sy);
    path.cubicTo(
        (102) * sx, (374 + 12) * sy,
        (112) * sx, (376 + 12) * sy,
        (118) * sx, (382 + 12) * sy
    );
    path.cubicTo(
        (120) * sx, (400 + 12) * sy,
        (116) * sx, (416 + 12) * sy,
        (110) * sx, (428 + 12) * sy
    );
    path.cubicTo(
        (104) * sx, (432 + 12) * sy,
        (96) * sx, (432 + 12) * sy,
        (90) * sx, (428 + 12) * sy
    );
    path.cubicTo(
        (88) * sx, (414 + 12) * sy,
        (88) * sx, (396 + 12) * sy,
        (94) * sx, (376 + 12) * sy
    );
    path.close();
    path.moveTo((166) * sx, (376 + 12) * sy);
    path.cubicTo(
        (158) * sx, (374 + 12) * sy,
        (148) * sx, (376 + 12) * sy,
        (142) * sx, (382 + 12) * sy
    );
    path.cubicTo(
        (140) * sx, (400 + 12) * sy,
        (144) * sx, (416 + 12) * sy,
        (150) * sx, (428 + 12) * sy
    );
    path.cubicTo(
        (156) * sx, (432 + 12) * sy,
        (164) * sx, (432 + 12) * sy,
        (170) * sx, (428 + 12) * sy
    );
    path.cubicTo(
        (172) * sx, (414 + 12) * sy,
        (172) * sx, (396 + 12) * sy,
        (166) * sx, (376 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getTrapsBackPathStatic(double sx, double sy) {
    return Path()
      ..moveTo((105) * sx, (80 + 12) * sy)
      ..cubicTo(
          (115) * sx, (76 + 12) * sy,
          (128) * sx, (74 + 12) * sy,
          (138) * sx, (76 + 12) * sy
      )
      ..cubicTo(
          (148) * sx, (78 + 12) * sy,
          (155) * sx, (82 + 12) * sy,
          (160) * sx, (88 + 12) * sy
      )
      ..cubicTo(
          (165) * sx, (96 + 12) * sy,
          (166) * sx, (106 + 12) * sy,
          (162) * sx, (116 + 12) * sy
      )
      ..cubicTo(
          (154) * sx, (110 + 12) * sy,
          (144) * sx, (106 + 12) * sy,
          (132) * sx, (106 + 12) * sy
      )
      ..cubicTo(
          (120) * sx, (106 + 12) * sy,
          (110) * sx, (110 + 12) * sy,
          (102) * sx, (116 + 12) * sy
      )
      ..cubicTo(
          (98) * sx, (106 + 12) * sy,
          (96) * sx, (96 + 12) * sy,
          (100) * sx, (86 + 12) * sy
      )
      ..cubicTo(
          (102) * sx, (82 + 12) * sy,
          (104) * sx, (80 + 12) * sy,
          (105) * sx, (80 + 12) * sy
      )
      ..close();
  }

  static Path _getShouldersBackPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((80) * sx, (108 + 12) * sy);
    path.cubicTo(
        (68) * sx, (108 + 12) * sy,
        (58) * sx, (114 + 12) * sy,
        (52) * sx, (124 + 12) * sy
    );
    path.cubicTo(
        (48) * sx, (136 + 12) * sy,
        (52) * sx, (150 + 12) * sy,
        (62) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (72) * sx, (150 + 12) * sy,
        (80) * sx, (140 + 12) * sy,
        (84) * sx, (128 + 12) * sy
    );
    path.cubicTo(
        (86) * sx, (118 + 12) * sy,
        (84) * sx, (112 + 12) * sy,
        (80) * sx, (108 + 12) * sy
    );
    path.close();
    path.moveTo((180) * sx, (108 + 12) * sy);
    path.cubicTo(
        (192) * sx, (108 + 12) * sy,
        (202) * sx, (114 + 12) * sy,
        (208) * sx, (124 + 12) * sy
    );
    path.cubicTo(
        (212) * sx, (136 + 12) * sy,
        (208) * sx, (150 + 12) * sy,
        (198) * sx, (156 + 12) * sy
    );
    path.cubicTo(
        (188) * sx, (150 + 12) * sy,
        (180) * sx, (140 + 12) * sy,
        (176) * sx, (128 + 12) * sy
    );
    path.cubicTo(
        (174) * sx, (118 + 12) * sy,
        (176) * sx, (112 + 12) * sy,
        (180) * sx, (108 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getBackPathStatic(double sx, double sy) {
    return Path()
      ..moveTo((98) * sx, (122 + 12) * sy)
      ..cubicTo(
          (108) * sx, (118 + 12) * sy,
          (122) * sx, (116 + 12) * sy,
          (132) * sx, (116 + 12) * sy
      )
      ..cubicTo(
          (142) * sx, (116 + 12) * sy,
          (156) * sx, (118 + 12) * sy,
          (166) * sx, (122 + 12) * sy
      )
      ..cubicTo(
          (172) * sx, (134 + 12) * sy,
          (174) * sx, (148 + 12) * sy,
          (170) * sx, (162 + 12) * sy
      )
      ..cubicTo(
          (160) * sx, (158 + 12) * sy,
          (148) * sx, (154 + 12) * sy,
          (136) * sx, (154 + 12) * sy
      )
      ..cubicTo(
          (124) * sx, (154 + 12) * sy,
          (112) * sx, (158 + 12) * sy,
          (102) * sx, (162 + 12) * sy
      )
      ..cubicTo(
          (98) * sx, (148 + 12) * sy,
          (96) * sx, (134 + 12) * sy,
          (98) * sx, (122 + 12) * sy
      )
      ..close();
  }

  static Path _getLatsPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((90) * sx, (150 + 12) * sy);
    path.cubicTo(
        (86) * sx, (168 + 12) * sy,
        (86) * sx, (190 + 12) * sy,
        (90) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (96) * sx, (224 + 12) * sy,
        (106) * sx, (228 + 12) * sy,
        (118) * sx, (224 + 12) * sy
    );
    path.cubicTo(
        (126) * sx, (212 + 12) * sy,
        (130) * sx, (192 + 12) * sy,
        (128) * sx, (168 + 12) * sy
    );
    path.cubicTo(
        (120) * sx, (154 + 12) * sy,
        (108) * sx, (148 + 12) * sy,
        (90) * sx, (150 + 12) * sy
    );
    path.close();
    path.moveTo((170) * sx, (150 + 12) * sy);
    path.cubicTo(
        (174) * sx, (168 + 12) * sy,
        (174) * sx, (190 + 12) * sy,
        (170) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (164) * sx, (224 + 12) * sy,
        (154) * sx, (228 + 12) * sy,
        (142) * sx, (224 + 12) * sy
    );
    path.cubicTo(
        (134) * sx, (212 + 12) * sy,
        (130) * sx, (192 + 12) * sy,
        (132) * sx, (168 + 12) * sy
    );
    path.cubicTo(
        (140) * sx, (154 + 12) * sy,
        (152) * sx, (148 + 12) * sy,
        (170) * sx, (150 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getTricepsBackPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((72) * sx, (146 + 12) * sy);
    path.cubicTo(
        (64) * sx, (158 + 12) * sy,
        (60) * sx, (176 + 12) * sy,
        (62) * sx, (196 + 12) * sy
    );
    path.cubicTo(
        (64) * sx, (208 + 12) * sy,
        (70) * sx, (214 + 12) * sy,
        (78) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (84) * sx, (202 + 12) * sy,
        (86) * sx, (184 + 12) * sy,
        (84) * sx, (166 + 12) * sy
    );
    path.cubicTo(
        (82) * sx, (156 + 12) * sy,
        (78) * sx, (148 + 12) * sy,
        (72) * sx, (146 + 12) * sy
    );
    path.close();
    path.moveTo((188) * sx, (146 + 12) * sy);
    path.cubicTo(
        (196) * sx, (158 + 12) * sy,
        (200) * sx, (176 + 12) * sy,
        (198) * sx, (196 + 12) * sy
    );
    path.cubicTo(
        (196) * sx, (208 + 12) * sy,
        (190) * sx, (214 + 12) * sy,
        (182) * sx, (212 + 12) * sy
    );
    path.cubicTo(
        (176) * sx, (202 + 12) * sy,
        (174) * sx, (184 + 12) * sy,
        (176) * sx, (166 + 12) * sy
    );
    path.cubicTo(
        (178) * sx, (156 + 12) * sy,
        (182) * sx, (148 + 12) * sy,
        (188) * sx, (146 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getForearmsBackPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((62) * sx, (210 + 12) * sy);
    path.cubicTo(
        (56) * sx, (228 + 12) * sy,
        (52) * sx, (250 + 12) * sy,
        (54) * sx, (274 + 12) * sy
    );
    path.cubicTo(
        (56) * sx, (290 + 12) * sy,
        (62) * sx, (302 + 12) * sy,
        (72) * sx, (304 + 12) * sy
    );
    path.cubicTo(
        (78) * sx, (294 + 12) * sy,
        (80) * sx, (278 + 12) * sy,
        (78) * sx, (258 + 12) * sy
    );
    path.cubicTo(
        (76) * sx, (234 + 12) * sy,
        (72) * sx, (218 + 12) * sy,
        (68) * sx, (210 + 12) * sy
    );
    path.cubicTo(
        (66) * sx, (208 + 12) * sy,
        (64) * sx, (208 + 12) * sy,
        (62) * sx, (210 + 12) * sy
    );
    path.close();
    path.moveTo((198) * sx, (210 + 12) * sy);
    path.cubicTo(
        (204) * sx, (228 + 12) * sy,
        (208) * sx, (250 + 12) * sy,
        (206) * sx, (274 + 12) * sy
    );
    path.cubicTo(
        (204) * sx, (290 + 12) * sy,
        (198) * sx, (302 + 12) * sy,
        (188) * sx, (304 + 12) * sy
    );
    path.cubicTo(
        (182) * sx, (294 + 12) * sy,
        (180) * sx, (278 + 12) * sy,
        (182) * sx, (258 + 12) * sy
    );
    path.cubicTo(
        (184) * sx, (234 + 12) * sy,
        (188) * sx, (218 + 12) * sy,
        (192) * sx, (210 + 12) * sy
    );
    path.cubicTo(
        (194) * sx, (208 + 12) * sy,
        (196) * sx, (208 + 12) * sy,
        (198) * sx, (210 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getLowerBackPathStatic(double sx, double sy) {
    return Path()
      ..moveTo((104) * sx, (232 + 12) * sy)
      ..cubicTo(
          (114) * sx, (230 + 12) * sy,
          (146) * sx, (230 + 12) * sy,
          (156) * sx, (232 + 12) * sy
      )
      ..cubicTo(
          (158) * sx, (248 + 12) * sy,
          (158) * sx, (266 + 12) * sy,
          (154) * sx, (280 + 12) * sy
      )
      ..cubicTo(
          (146) * sx, (286 + 12) * sy,
          (114) * sx, (286 + 12) * sy,
          (106) * sx, (280 + 12) * sy
      )
      ..cubicTo(
          (102) * sx, (266 + 12) * sy,
          (102) * sx, (248 + 12) * sy,
          (104) * sx, (232 + 12) * sy
      )
      ..close();
  }

  static Path _getGlutesPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((96) * sx, (268 + 12) * sy);
    path.cubicTo(
        (104) * sx, (266 + 12) * sy,
        (120) * sx, (266 + 12) * sy,
        (130) * sx, (268 + 12) * sy
    );
    path.cubicTo(
        (130) * sx, (290 + 12) * sy,
        (126) * sx, (308 + 12) * sy,
        (116) * sx, (314 + 12) * sy
    );
    path.cubicTo(
        (104) * sx, (314 + 12) * sy,
        (92) * sx, (306 + 12) * sy,
        (86) * sx, (294 + 12) * sy
    );
    path.cubicTo(
        (86) * sx, (284 + 12) * sy,
        (88) * sx, (276 + 12) * sy,
        (96) * sx, (268 + 12) * sy
    );
    path.close();
    path.moveTo((164) * sx, (268 + 12) * sy);
    path.cubicTo(
        (156) * sx, (266 + 12) * sy,
        (140) * sx, (266 + 12) * sy,
        (130) * sx, (268 + 12) * sy
    );
    path.cubicTo(
        (130) * sx, (290 + 12) * sy,
        (134) * sx, (308 + 12) * sy,
        (144) * sx, (314 + 12) * sy
    );
    path.cubicTo(
        (156) * sx, (314 + 12) * sy,
        (168) * sx, (306 + 12) * sy,
        (174) * sx, (294 + 12) * sy
    );
    path.cubicTo(
        (174) * sx, (284 + 12) * sy,
        (172) * sx, (276 + 12) * sy,
        (164) * sx, (268 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getHamstringsPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((96) * sx, (302 + 12) * sy);
    path.cubicTo(
        (104) * sx, (300 + 12) * sy,
        (114) * sx, (302 + 12) * sy,
        (120) * sx, (308 + 12) * sy
    );
    path.cubicTo(
        (122) * sx, (332 + 12) * sy,
        (120) * sx, (358 + 12) * sy,
        (116) * sx, (380 + 12) * sy
    );
    path.cubicTo(
        (110) * sx, (386 + 12) * sy,
        (100) * sx, (386 + 12) * sy,
        (92) * sx, (382 + 12) * sy
    );
    path.cubicTo(
        (88) * sx, (358 + 12) * sy,
        (88) * sx, (330 + 12) * sy,
        (96) * sx, (302 + 12) * sy
    );
    path.close();
    path.moveTo((164) * sx, (302 + 12) * sy);
    path.cubicTo(
        (156) * sx, (300 + 12) * sy,
        (146) * sx, (302 + 12) * sy,
        (140) * sx, (308 + 12) * sy
    );
    path.cubicTo(
        (138) * sx, (332 + 12) * sy,
        (140) * sx, (358 + 12) * sy,
        (144) * sx, (380 + 12) * sy
    );
    path.cubicTo(
        (150) * sx, (386 + 12) * sy,
        (160) * sx, (386 + 12) * sy,
        (168) * sx, (382 + 12) * sy
    );
    path.cubicTo(
        (172) * sx, (358 + 12) * sy,
        (172) * sx, (330 + 12) * sy,
        (164) * sx, (302 + 12) * sy
    );
    path.close();
    return path;
  }

  static Path _getCalvesBackPathStatic(double sx, double sy) {
    final path = Path();
    path.moveTo((94) * sx, (382 + 12) * sy);
    path.cubicTo(
        (102) * sx, (380 + 12) * sy,
        (114) * sx, (382 + 12) * sy,
        (120) * sx, (388 + 12) * sy
    );
    path.cubicTo(
        (122) * sx, (408 + 12) * sy,
        (118) * sx, (426 + 12) * sy,
        (112) * sx, (434 + 12) * sy
    );
    path.cubicTo(
        (106) * sx, (438 + 12) * sy,
        (98) * sx, (438 + 12) * sy,
        (92) * sx, (434 + 12) * sy
    );
    path.cubicTo(
        (90) * sx, (422 + 12) * sy,
        (90) * sx, (402 + 12) * sy,
        (94) * sx, (382 + 12) * sy
    );
    path.close();
    path.moveTo((166) * sx, (382 + 12) * sy);
    path.cubicTo(
        (158) * sx, (380 + 12) * sy,
        (146) * sx, (382 + 12) * sy,
        (140) * sx, (388 + 12) * sy
    );
    path.cubicTo(
        (138) * sx, (408 + 12) * sy,
        (142) * sx, (426 + 12) * sy,
        (148) * sx, (434 + 12) * sy
    );
    path.cubicTo(
        (154) * sx, (438 + 12) * sy,
        (162) * sx, (438 + 12) * sy,
        (168) * sx, (434 + 12) * sy
    );
    path.cubicTo(
        (170) * sx, (422 + 12) * sy,
        (170) * sx, (402 + 12) * sy,
        (166) * sx, (382 + 12) * sy
    );
    path.close();
    return path;
  }
}