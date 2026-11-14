// lib/features/nutrition/ui/widgets/season_vine_postage.dart
// ═══════════════════════════════════════════════════════════════════
//  POSTAGE STAMP ALBUM edition
//  · Month names in a solid high-contrast banner (obvious, clean)
//  · Country on the stamp derived from the month's main product
//  · Main motif is the product emoji (falls back to seasonal emoji)
//  · Slightly richer stamp composition: ribbon, vignette, ornaments
// ═══════════════════════════════════════════════════════════════════
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zal_life/features/nutrition/ui/widgets/season_vine_style_button.dart';

import '../../models/nutrition_models.dart' show FoodProduct;
import '../../models/wellness_models.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/wellness_provider.dart';
import 'product_knowledge_sheet.dart';
import 'season_visuals.dart';

// ═══════════════════════════════════════════════════════════════════
//  Palette — leather album, aged paper, stamp inks
// ═══════════════════════════════════════════════════════════════════
class _SA {
  static const leatherLight = Color(0xFF5A3A28);
  static const leatherMid = Color(0xFF3F2818);
  static const leatherDark = Color(0xFF26170D);
  static const leatherInset = Color(0xFF1F120A);
  static const pagePaper = Color(0xFFF0E4CC);
  static const pagePaperDeep = Color(0xFFE0D0B3);
  static const pageRule = Color(0xFFC8B89A);

  static const ink = Color(0xFF2A1810);
  static const inkMuted = Color(0xFF6B5030);
  static const inkDim = Color(0xFF9C8866);

  static const photoCorner = Color(0xFF1A0F08);
  static const gold = Color(0xFFD4A84B);
  static const neon = Color(0xFF3DDC84);

  static const postmarkInk = Color(0xFF6B1E14);
  static const postmarkFaint = Color(0xFFA83A2A);
}

class _StampPalette {
  final Color bg;
  final Color accent;
  final Color fg;
  const _StampPalette({
    required this.bg,
    required this.accent,
    required this.fg,
  });
}

class _VS {
  final double scale;
  const _VS(this.scale);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

// ═══════════════════════════════════════════════════════════════════
//  PUBLIC
// ═══════════════════════════════════════════════════════════════════
class SeasonVineCardPostage extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCardPostage({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  State<SeasonVineCardPostage> createState() =>
      _SeasonVineCardPostageState();
}

class _SeasonVineCardPostageState extends State<SeasonVineCardPostage>
    with TickerProviderStateMixin {
  int? _expandedMonth;

  static const _monthShort = [
    '', 'ЯНВ', 'ФЕВ', 'МАР', 'АПР', 'МАЙ', 'ИЮН',
    'ИЮЛ', 'АВГ', 'СЕН', 'ОКТ', 'НОЯ', 'ДЕК',
  ];

  static const _monthFull = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  static const _monthEmoji = [
    '', '❄️', '🌨️', '🌱', '🌷', '🌸', '☀️',
    '🌻', '🌾', '🍂', '🍁', '🌧️', '🎄',
  ];

  static const _countryByEmoji = <String, String>{
    '🍎': 'ЯБЛОНИЯ',   '🍏': 'ЯБЛОНИЯ',
    '🍌': 'БАНАНИЯ',   '🍇': 'ВИНОГРАДИЯ',
    '🍓': 'ЗЕМЛЯНИЯ',  '🍊': 'АПЕЛЬСИНИЯ',
    '🍋': 'ЛИМОНИЯ',   '🍉': 'АРБУЗИЯ',
    '🍑': 'ПЕРСИЯ',    '🍒': 'ЧЕРЕШНИЯ',
    '🥕': 'МОРКОВИЯ',  '🥔': 'КАРТОФЕЛИЯ',
    '🥒': 'ОГУРЕЦИЯ',  '🍅': 'ТОМАТИЯ',
    '🥦': 'БРОККОЛИЯ', '🥬': 'САЛАТИЯ',
    '🍄': 'ГРИБИЯ',    '🌰': 'КАШТАНИЯ',
    '🥜': 'АРАХИСИЯ',  '🌽': 'КУКУРУЗИЯ',
    '🎃': 'ТЫКВИЯ',    '🥑': 'АВОКАДИЯ',
    '🍐': 'ГРУШИЯ',    '🫐': 'ЧЕРНИКИЯ',
    '🍍': 'АНАНАСИЯ',  '🥝': 'КИВИЯ',
    '🥭': 'МАНГИЯ',    '🌶': 'ПЕРЧИЯ',
    '🍈': 'ДЫНИЯ',     '🍆': 'БАКЛАЖАНИЯ',
    '🥖': 'ХЛЕБИЯ',    '🍞': 'ХЛЕБИЯ',
    '🧀': 'СЫРИЯ',     '🍯': 'МЕДИЯ',
    '🐟': 'РЫБИЯ',     '🦐': 'КРЕВЕТИЯ',
    '🦀': 'КРАБИЯ',    '🥚': 'ЯИЧИЯ',
    '🥛': 'МОЛОКИЯ',   '🌿': 'ТРАВИЯ',
    '🌾': 'ПШЕНИЯ',
  };

  static const _seasonalCountries = [
    '', 'СНЕЖИЯ', 'МОРОЗИЯ', 'ПРОТАЛИЯ', 'ЦВЕТИЯ', 'СИРЕНИЯ', 'ЛЕТИЯ',
    'ЗНОЙСК', 'УРОЖАЙСК', 'ЛИСТОПАДИЯ', 'ТУМАНИЯ', 'ДОЖДИЯ', 'ЗИМИЯ',
  ];

  static const _palette = <int, _StampPalette>{
    1: _StampPalette(bg: Color(0xFF3A4A5E), accent: Color(0xFF8AB5D9), fg: Color(0xFFE8EEF5)),
    2: _StampPalette(bg: Color(0xFF5A4A6E), accent: Color(0xFFB8A0D9), fg: Color(0xFFF0E8F8)),
    3: _StampPalette(bg: Color(0xFF4A6B4E), accent: Color(0xFF8AB893), fg: Color(0xFFE5F4E8)),
    4: _StampPalette(bg: Color(0xFFA86B8E), accent: Color(0xFFE8A0C0), fg: Color(0xFFF8E8F0)),
    5: _StampPalette(bg: Color(0xFF6B8E4A), accent: Color(0xFFA8D878), fg: Color(0xFFF0F8E0)),
    6: _StampPalette(bg: Color(0xFFD9A84A), accent: Color(0xFFF8D878), fg: Color(0xFFFFF5E0)),
    7: _StampPalette(bg: Color(0xFFD9784A), accent: Color(0xFFF8B878), fg: Color(0xFFFFF0E0)),
    8: _StampPalette(bg: Color(0xFFB85A3A), accent: Color(0xFFE89B5A), fg: Color(0xFFFFE8D0)),
    9: _StampPalette(bg: Color(0xFF8E5A2A), accent: Color(0xFFD9A84A), fg: Color(0xFFFFF0D8)),
    10: _StampPalette(bg: Color(0xFF6B3A2A), accent: Color(0xFFB8785A), fg: Color(0xFFFFE0D0)),
    11: _StampPalette(bg: Color(0xFF4A3A3A), accent: Color(0xFF8E7A6B), fg: Color(0xFFE8DDD0)),
    12: _StampPalette(bg: Color(0xFF2A3A5E), accent: Color(0xFF6B9BD9), fg: Color(0xFFE0EAF8)),
  };

  @override
  void initState() {
    super.initState();
    _expandedMonth = null;
  }

  void _toggleMonth(int month) {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    setState(() {
      _expandedMonth = _expandedMonth == month ? null : month;
    });
  }

  String _countryFor(int month, List<ProductKnowledge> products) {
    if (products.isNotEmpty) {
      final emoji = products.first.emoji;
      final known = _countryByEmoji[emoji];
      if (known != null) return known;
    }
    return _seasonalCountries[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final r = _VS(widget.scale);
    final cm = widget.wellness.currentMonth;
    final inSeason = widget.wellness.monthsWithSeason;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.s(20)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_SA.leatherLight, _SA.leatherMid, _SA.leatherDark],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.42),
            blurRadius: r.s(30),
            offset: Offset(0, r.s(14)),
          ),
          BoxShadow(
            color: _SA.gold.withOpacity(0.06),
            blurRadius: r.s(60),
            spreadRadius: r.s(-10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.s(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(r, cm),
            _buildSpread(r, cm, inSeason),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expandedMonth == null
                  ? const SizedBox(width: double.infinity, height: 0)
                  : _buildBackPanel(_expandedMonth!, r),
            ),
            SizedBox(height: r.s(10)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader(_VS r, int cm) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          r.s(18), r.s(16), r.s(14), r.s(10)),
      child: Row(
        children: [
          Container(
            width: r.s(28),
            height: r.s(28),
            decoration: BoxDecoration(
              color: _SA.leatherInset,
              borderRadius: BorderRadius.circular(r.s(4)),
              border: Border.all(
                color: _SA.gold.withOpacity(0.55),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _SA.gold.withOpacity(0.10),
                  blurRadius: r.s(8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '🌱',
              style: TextStyle(fontSize: r.fs(14)),
            ),
          ),
          SizedBox(width: r.s(10)),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'АЛЬБОМ · СЕЗОН',
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.inter(
                      color: _SA.gold.withOpacity(0.75),
                      fontSize: r.fs(9),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: r.s(3)),
                  Text(
                    'Коллекция · ${_monthFull[cm]}',
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.fraunces(
                      color: _SA.pagePaper,
                      fontSize: r.fs(17),
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.2,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SeasonVineStyleButton(
            scale: widget.scale,
            color: _SA.gold,
          ),
          SizedBox(width: r.s(6)),

          GestureDetector(
            onTap: widget.onOpenKnowledge,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  r.s(10), r.s(6), r.s(8), r.s(6)),
              decoration: BoxDecoration(
                color: _SA.leatherInset,
                borderRadius: BorderRadius.circular(r.s(4)),
                border: Border.all(
                  color: _SA.gold.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ЗНАНИЯ',
                    style: GoogleFonts.inter(
                      color: _SA.pagePaper.withOpacity(0.85),
                      fontSize: r.fs(9),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: r.s(4)),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: _SA.gold,
                    size: r.fs(11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SPREAD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSpread(_VS r, int cm, Set<int> inSeason) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(10)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildPage(
                r: r,
                cm: cm,
                inSeason: inSeason,
                pageIndex: 0,
                isLeft: true,
              ),
            ),
            _buildSpine(r),
            Expanded(
              child: _buildPage(
                r: r,
                cm: cm,
                inSeason: inSeason,
                pageIndex: 1,
                isLeft: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpine(_VS r) {
    return Container(
      width: r.s(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A0D06),
            _SA.leatherInset,
            Color(0xFF1A0D06),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: r.s(6),
            offset: Offset(r.s(-2), 0),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: r.s(6),
            offset: Offset(r.s(2), 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (i) {
          return Container(
            width: r.s(4),
            height: r.s(4),
            decoration: BoxDecoration(
              color: _SA.gold.withOpacity(0.45),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _SA.gold.withOpacity(0.25),
                  blurRadius: r.s(3),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPage({
    required _VS r,
    required int cm,
    required Set<int> inSeason,
    required int pageIndex,
    required bool isLeft,
  }) {
    final startMonth = pageIndex * 6 + 1;
    final months = List.generate(6, (i) => startMonth + i);

    return Container(
      padding: EdgeInsets.all(r.s(8)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            _SA.pagePaperDeep,
            _SA.pagePaper,
            _SA.pagePaper,
          ],
          stops: const [0.0, 0.15, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: r.s(6),
            offset: isLeft ? Offset(r.s(2), 0) : Offset(-r.s(2), 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _PageRulePainter()),
          ),
          Column(
            children: [
              for (int row = 0; row < 3; row++)
                Padding(
                  padding: EdgeInsets.only(bottom: row < 2 ? r.s(6) : 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: _buildStampSlot(
                            r: r,
                            month: months[row * 2],
                            cm: cm,
                            inSeason: inSeason,
                          ),
                        ),
                      ),
                      SizedBox(width: r.s(6)),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: _buildStampSlot(
                            r: r,
                            month: months[row * 2 + 1],
                            cm: cm,
                            inSeason: inSeason,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STAMP SLOT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStampSlot({
    required _VS r,
    required int month,
    required int cm,
    required Set<int> inSeason,
  }) {
    final isCurrent = month == cm;
    final isExpanded = month == _expandedMonth;
    final isInSeason = inSeason.contains(month);
    final isLandscape = month.isEven;
    final aspect = isLandscape ? 1.22 : 0.82;
    final products = widget.wellness.productsForMonth(month);

    final rotation = _baseRotation(month);
    final scale = isExpanded ? 1.10 : (isCurrent ? 1.03 : 1.0);
    final lift = isExpanded ? -3.0 : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _PhotoCornersPainter(
              inset: isExpanded ? 10.0 : 4.0,
              cornerSize: 7.0 * widget.scale,
              color: _SA.photoCorner,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, lift),
          child: Transform.rotate(
            angle: rotation + (isLandscape ? math.pi / 2 : 0),
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Center(
                child: AspectRatio(
                  aspectRatio: aspect,
                  child: GestureDetector(
                    onTap: () => _toggleMonth(month),
                    behavior: HitTestBehavior.opaque,
                    child: _buildStamp(
                      r: r,
                      month: month,
                      products: products,
                      isCurrent: isCurrent,
                      isInSeason: isInSeason,
                      isExpanded: isExpanded,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _baseRotation(int month) {
    final rng = math.Random(month * 31);
    return (rng.nextDouble() - 0.5) * 0.08;
  }

  double _postmarkRotation(int month) {
    final rng = math.Random(month * 7 + 1);
    return (rng.nextDouble() - 0.5) * 0.28;
  }

  // ═══════════════════════════════════════════════════════════════
  //  STAMP
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStamp({
    required _VS r,
    required int month,
    required List<ProductKnowledge> products,
    required bool isCurrent,
    required bool isInSeason,
    required bool isExpanded,
  }) {
    final pal = _palette[month]!;
    final dimmed = !isInSeason && !isCurrent && !isExpanded;
    final country = _countryFor(month, products);
    final mainEmoji = products.isNotEmpty
        ? products.first.emoji
        : _monthEmoji[month];

    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: (isCurrent || isExpanded)
              ? [
            BoxShadow(
              color: _SA.gold.withOpacity(0.45),
              blurRadius: 14 * widget.scale,
              spreadRadius: 1.5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 6 * widget.scale,
              offset: Offset(0, 2 * widget.scale),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 4 * widget.scale,
              offset: Offset(
                  0.5 * widget.scale, 1.5 * widget.scale),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const _PerforatedStampClipper(
              perforations: 11, depth: 0.9),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _StampArtPainter(
                    month: month,
                    bg: pal.bg,
                    accent: pal.accent,
                    fg: pal.fg,
                  ),
                ),
              ),
              Positioned.fill(
                child: _buildStampContent(
                    r, month, pal, country, mainEmoji),
              ),
              if (isInSeason && !isExpanded)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: _postmarkRotation(month),
                      child: CustomPaint(
                        painter: _PostmarkPainter(
                          month: month,
                          monthShort: _monthShort[month],
                          country: country,
                          color: _SA.postmarkInk,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isCurrent && !isExpanded)
                Positioned(
                  top: 0,
                  right: 0,
                  width: r.s(18),
                  height: r.s(18),
                  child: CustomPaint(
                    painter: const _BentCornerPainter(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStampContent(
      _VS r,
      int month,
      _StampPalette pal,
      String country,
      String mainEmoji,
      ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          r.s(5), r.s(4.5), r.s(5), r.s(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: r.s(1.5)),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: pal.fg.withOpacity(0.45),
                  width: 0.6,
                ),
              ),
            ),
            child: Text(
              country,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: GoogleFonts.inter(
                color: pal.fg,
                fontSize: r.fs(5.5),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
                height: 1.0,
              ),
            ),
          ),
          SizedBox(height: r.s(2)),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: r.s(28),
                    height: r.s(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: pal.fg.withOpacity(0.35),
                        width: 0.7,
                      ),
                    ),
                  ),
                  Text(
                    mainEmoji,
                    style: TextStyle(
                      fontSize: r.fs(20),
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: pal.fg.withOpacity(0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: r.s(2)),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: r.s(4), vertical: r.s(2)),
            decoration: BoxDecoration(
              color: pal.fg,
              borderRadius: BorderRadius.circular(r.s(1.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 1.5,
                  offset: const Offset(0, 0.5),
                ),
              ],
            ),
            child: Text(
              _monthShort[month],
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.inter(
                color: pal.bg,
                fontSize: r.fs(9),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BACK PANEL
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBackPanel(int month, _VS r) {
    final meta = metaForMonth(month);
    final products = widget.wellness.productsForMonth(month);
    final isInSeason = widget.wellness.monthsWithSeason.contains(month);
    final pal = _palette[month]!;
    final country = _countryFor(month, products);

    return TweenAnimationBuilder<double>(
      key: ValueKey(month),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 16),
          child: Transform.scale(
            scale: 0.94 + t * 0.06,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.fromLTRB(
            r.s(16), r.s(12), r.s(16), r.s(0)),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: r.s(20),
              offset: Offset(0, r.s(8)),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const _PerforatedStampClipper(
              perforations: 15, depth: 0.9),
          child: Container(
            color: _SA.pagePaper,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PaperGrainPainter(seed: month * 13),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StampBackMarksPainter(
                      palette: pal,
                      month: month,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      r.s(16), r.s(14), r.s(14), r.s(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBackStampPreview(
                              r, month, pal, country),
                          SizedBox(width: r.s(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${country.toUpperCase()} · ЛОТ ${month.toString().padLeft(2, '0')}',
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: _SA.inkMuted,
                                    fontSize: r.fs(8),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                    height: 1.0,
                                  ),
                                ),
                                SizedBox(height: r.s(3)),
                                Text(
                                  _monthFull[month],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.fraunces(
                                    color: _SA.ink,
                                    fontSize: r.fs(18),
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: -0.2,
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: r.s(4)),
                                _buildCatalogLine(r,
                                  isInSeason
                                      ? '✓ В обороте · ${products.length} ${_productsWord(products.length)}'
                                      : '· Изъят из обращения',
                                  isInSeason ? _SA.neon : _SA.inkDim,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(
                                    () => _expandedMonth = null),
                            child: Container(
                              width: r.s(26),
                              height: r.s(26),
                              decoration: BoxDecoration(
                                color: _SA.pagePaperDeep,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _SA.inkDim.withOpacity(0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: _SA.inkMuted,
                                size: r.fs(13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r.s(10)),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: _SA.inkDim.withOpacity(0.35),
                      ),
                      SizedBox(height: r.s(8)),
                      if (products.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: r.s(16)),
                          child: Center(
                            child: Text(
                              '— ЛОТ ПУСТ · НЕТ ПРЕДМЕТОВ —',
                              style: GoogleFonts.inter(
                                color: _SA.inkDim,
                                fontSize: r.fs(9),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.2,
                              ),
                            ),
                          ),
                        )
                      else
                        ...products.asMap().entries.map((e) =>
                            _buildCatalogEntry(
                              r: r,
                              index: e.key,
                              product: e.value,
                              pal: pal,
                            )),
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

  Widget _buildBackStampPreview(
      _VS r, int month, _StampPalette pal, String country) {
    return Container(
      width: r.s(38),
      height: r.s(46),
      decoration: BoxDecoration(
        color: pal.bg,
        border: Border.all(
          color: _SA.inkDim.withOpacity(0.5),
          width: 0.6,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: r.s(3)),
        child: Column(
          children: [
            Text(
              country,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: GoogleFonts.inter(
                color: pal.fg,
                fontSize: r.fs(4.5),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                height: 1.0,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _monthEmoji[month],
                  style: TextStyle(fontSize: r.fs(16)),
                ),
              ),
            ),
            Text(
              _monthShort[month],
              style: GoogleFonts.inter(
                color: pal.fg,
                fontSize: r.fs(6),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogLine(_VS r, String text, Color color) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: color,
        fontSize: r.fs(10),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.15,
      ),
    );
  }

  Widget _buildCatalogEntry({
    required _VS r,
    required int index,
    required ProductKnowledge product,
    required _StampPalette pal,
  }) {
    final num = (index + 1).toString().padLeft(2, '0');
    final year = 1960 + (index * 3) % 60;
    final rarity = _rarityFor(index, product.displayName);

    return GestureDetector(
      onTap: () => _openProductSheet(product),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: r.s(8)),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _SA.inkDim.withOpacity(0.20),
              width: 0.6,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: r.s(28),
              height: r.s(34),
              decoration: BoxDecoration(
                color: pal.bg,
                border: Border.all(
                  color: _SA.inkDim.withOpacity(0.35),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                product.emoji,
                style: TextStyle(fontSize: r.fs(14)),
              ),
            ),
            SizedBox(width: r.s(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '№ $num · ',
                        style: GoogleFonts.inter(
                          color: _SA.inkMuted,
                          fontSize: r.fs(8),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                      Text(
                        '$year',
                        style: GoogleFonts.inter(
                          color: _SA.inkMuted,
                          fontSize: r.fs(8),
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.s(2)),
                  Text(
                    product.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fraunces(
                      color: _SA.ink,
                      fontSize: r.fs(13),
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.1,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: r.s(2)),
                  Text(
                    rarity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _SA.inkMuted,
                      fontSize: r.fs(9),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: r.s(6)),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: _SA.inkDim,
              size: r.fs(9),
            ),
          ],
        ),
      ),
    );
  }

  String _rarityFor(int index, String name) {
    const rarities = [
      'гашёная · сохранность отличная',
      'чистая · с клеем',
      'редкий оттенок · без повреждений',
      'с полями · коллекционная',
      'штемпель чёткий · уникум',
      'с водяным знаком · архивная',
    ];
    return rarities[index % rarities.length];
  }

  void _openProductSheet(ProductKnowledge k) {
    HapticFeedback.selectionClick();
    FoodProduct? product;
    for (final p in widget.nutrition.products) {
      if (p.id == k.key) {
        product = p;
        break;
      }
      final norm =
      p.name.toLowerCase().replaceAll('ё', 'е').replaceAll(' ', '_');
      if (norm.contains(k.key) || k.key.contains(norm)) {
        product = p;
        break;
      }
    }
    showProductKnowledgeSheet(context,
        product: product, knowledge: k, nutrition: widget.nutrition);
  }

  String _productsWord(int n) {
    if (n == 1) return 'предмет';
    if (n >= 2 && n <= 4) return 'предмета';
    return 'предметов';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PERFORATED STAMP CLIPPER
// ═══════════════════════════════════════════════════════════════════
class _PerforatedStampClipper extends CustomClipper<Path> {
  final int perforations;
  final double depth;
  const _PerforatedStampClipper({
    this.perforations = 11,
    this.depth = 0.9,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(0, 0);

    final nTop = perforations;
    final nSide = (perforations * (h / w)).round().clamp(6, 24);

    _addScallopedEdge(
        path, Offset(0, 0), Offset(w, 0), nTop, w / nTop * 0.22 * depth);
    _addScallopedEdge(path, Offset(w, 0), Offset(w, h), nSide,
        h / nSide * 0.22 * depth);
    _addScallopedEdge(
        path, Offset(w, h), Offset(0, h), nTop, w / nTop * 0.22 * depth);
    _addScallopedEdge(
        path, Offset(0, h), Offset(0, 0), nSide, h / nSide * 0.22 * depth);

    path.close();
    return path;
  }

  void _addScallopedEdge(
      Path path, Offset from, Offset to, int n, double depth) {
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
  bool shouldReclip(covariant _PerforatedStampClipper old) =>
      old.perforations != perforations || old.depth != depth;
}

// ═══════════════════════════════════════════════════════════════════
//  PHOTO CORNERS
// ═══════════════════════════════════════════════════════════════════
class _PhotoCornersPainter extends CustomPainter {
  final double inset;
  final double cornerSize;
  final Color color;
  const _PhotoCornersPainter({
    required this.inset,
    required this.cornerSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    _corner(canvas, Offset(inset, inset), cornerSize, paint,
        flipX: false, flipY: false);
    _corner(canvas, Offset(size.width - inset - cornerSize, inset),
        cornerSize, paint,
        flipX: true, flipY: false);
    _corner(canvas, Offset(inset, size.height - inset - cornerSize),
        cornerSize, paint,
        flipX: false, flipY: true);
    _corner(
        canvas,
        Offset(size.width - inset - cornerSize,
            size.height - inset - cornerSize),
        cornerSize,
        paint,
        flipX: true,
        flipY: true);
  }

  void _corner(Canvas canvas, Offset pos, double s, Paint paint,
      {required bool flipX, required bool flipY}) {
    final path = Path();
    final x0 = flipX ? pos.dx + s : pos.dx;
    final x1 = flipX ? pos.dx : pos.dx + s;
    final y0 = flipY ? pos.dy + s : pos.dy;
    final y1 = flipY ? pos.dy : pos.dy + s;
    path.moveTo(x0, y0);
    path.lineTo(x1, y0);
    path.lineTo(x0, y1);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PhotoCornersPainter old) =>
      old.inset != inset ||
          old.cornerSize != cornerSize ||
          old.color != color;
}

// ═══════════════════════════════════════════════════════════════════
//  STAMP ART PAINTER
// ═══════════════════════════════════════════════════════════════════
class _StampArtPainter extends CustomPainter {
  final int month;
  final Color bg;
  final Color accent;
  final Color fg;

  _StampArtPainter({
    required this.month,
    required this.bg,
    required this.accent,
    required this.fg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = bg);

    switch (month % 6) {
      case 0:
        _drawRays(canvas, size);
        break;
      case 1:
        _drawDiagonalBars(canvas, size);
        break;
      case 2:
        _drawWaves(canvas, size);
        break;
      case 3:
        _drawConcentric(canvas, size);
        break;
      case 4:
        _drawDiamonds(canvas, size);
        break;
      case 5:
        _drawOrnament(canvas, size);
        break;
    }

    canvas.drawRect(
      rect.deflate(3),
      Paint()
        ..color = fg.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    canvas.drawRect(
      rect.deflate(4.5),
      Paint()
        ..color = fg.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.4,
    );

    final cornerPaint = Paint()..color = fg.withOpacity(0.55);
    for (final c in [
      Offset(3, 3),
      Offset(size.width - 3, 3),
      Offset(3, size.height - 3),
      Offset(size.width - 3, size.height - 3),
    ]) {
      canvas.drawCircle(c, 0.9, cornerPaint);
    }
  }

  void _drawRays(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.72);
    final paint = Paint()
      ..color = accent.withOpacity(0.30)
      ..strokeWidth = 1.0;
    final paintAlt = Paint()
      ..color = accent.withOpacity(0.15)
      ..strokeWidth = 0.7;
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * math.pi * 2;
      canvas.drawLine(
        center +
            Offset(math.cos(angle) * size.width * 0.18,
                math.sin(angle) * size.width * 0.18),
        center +
            Offset(math.cos(angle) * size.width * 0.85,
                math.sin(angle) * size.width * 0.85),
        i.isEven ? paint : paintAlt,
      );
    }
    canvas.drawCircle(
        center, size.width * 0.16,
        Paint()..color = accent.withOpacity(0.55));
  }

  void _drawDiagonalBars(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withOpacity(0.22)
      ..strokeWidth = 3.5;
    for (int i = -8; i < 14; i++) {
      final x = i * size.width * 0.14;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  void _drawWaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < 8; i++) {
      final path = Path();
      final y = size.height * (i + 0.5) / 8;
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 3) {
        final yy = y + math.sin(x * 0.15 + i) * size.height * 0.04;
        path.lineTo(x, yy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawConcentric(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final paint = Paint()
      ..color = accent.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (int i = 1; i <= 6; i++) {
      canvas.drawCircle(center, size.width * i * 0.08, paint);
    }
    canvas.drawCircle(
        center, size.width * 0.09,
        Paint()..color = accent.withOpacity(0.35));
  }

  void _drawDiamonds(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final step = size.width * 0.16;
    for (double y = -size.width; y < size.height + size.width; y += step) {
      for (double x = -size.width; x < size.width + size.width; x += step) {
        final path = Path()
          ..moveTo(x, y - step * 0.5)
          ..lineTo(x + step * 0.5, y)
          ..lineTo(x, y + step * 0.5)
          ..lineTo(x - step * 0.5, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawOrnament(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withOpacity(0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final center = Offset(size.width * 0.5, size.height * 0.5);
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2;
      final rad = size.width * 0.35;
      canvas.drawCircle(
        center + Offset(math.cos(angle) * rad, math.sin(angle) * rad),
        size.width * 0.05,
        paint,
      );
    }
    canvas.drawCircle(center, size.width * 0.14, paint);
    canvas.drawCircle(center, size.width * 0.05, paint);
  }

  @override
  bool shouldRepaint(covariant _StampArtPainter old) =>
      old.month != month || old.bg != bg;
}

// ═══════════════════════════════════════════════════════════════════
//  POSTMARK PAINTER
// ═══════════════════════════════════════════════════════════════════
class _PostmarkPainter extends CustomPainter {
  final int month;
  final String monthShort;
  final String country;
  final Color color;

  _PostmarkPainter({
    required this.month,
    required this.monthShort,
    required this.country,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.55);
    final radius = math.min(size.width, size.height) * 0.40;

    final paint = Paint()
      ..color = color.withOpacity(0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final paintThin = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.72, paintThin);

    _drawArcText(
      canvas,
      'ПОЧТА · СЕЗОН',
      center,
      radius * 0.87,
      TextStyle(
        color: color.withOpacity(0.70),
        fontSize: size.width * 0.055,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
      startAngle: -math.pi * 0.85,
      endAngle: -math.pi * 0.15,
    );

    _drawArcText(
      canvas,
      monthShort,
      center,
      radius * 0.87,
      TextStyle(
        color: color.withOpacity(0.70),
        fontSize: size.width * 0.062,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
      startAngle: math.pi * 0.85,
      endAngle: math.pi * 0.15,
    );

    final markPaint = Paint()
      ..color = color.withOpacity(0.30)
      ..strokeWidth = 0.6;
    for (int i = -2; i <= 2; i++) {
      final y = center.dy + i * 1.7;
      canvas.drawLine(
        Offset(center.dx - radius * 0.55, y),
        Offset(center.dx + radius * 0.55, y),
        markPaint,
      );
    }
  }

  void _drawArcText(
      Canvas canvas,
      String text,
      Offset center,
      double radius,
      TextStyle style, {
        required double startAngle,
        required double endAngle,
      }) {
    if (text.isEmpty) return;
    final charCount = text.length;
    final totalAngle = endAngle - startAngle;
    for (int i = 0; i < charCount; i++) {
      final t = charCount == 1 ? 0.5 : i / (charCount - 1);
      final angle = startAngle + totalAngle * t;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      final tp = TextPainter(
        text: TextSpan(text: text[i], style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PostmarkPainter old) =>
      old.month != month ||
          old.color != color ||
          old.country != country;
}

// ═══════════════════════════════════════════════════════════════════
//  BENT CORNER
// ═══════════════════════════════════════════════════════════════════
class _BentCornerPainter extends CustomPainter {
  const _BentCornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.72),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(covariant _BentCornerPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  PAGE RULE LINES
// ═══════════════════════════════════════════════════════════════════
class _PageRulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _SA.pageRule.withOpacity(0.35)
      ..strokeWidth = 0.4;
    for (double y = 8; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PageRulePainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  PAPER GRAIN
// ═══════════════════════════════════════════════════════════════════
class _PaperGrainPainter extends CustomPainter {
  final int seed;
  const _PaperGrainPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed + 7);
    final paint = Paint()
      ..color = _SA.ink.withOpacity(0.025)
      ..strokeWidth = 0.4;
    for (int i = 0; i < 40; i++) {
      final y = rng.nextDouble() * size.height;
      final x1 = rng.nextDouble() * size.width * 0.7;
      final x2 = x1 + rng.nextDouble() * size.width * 0.3;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter old) =>
      old.seed != seed;
}

// ═══════════════════════════════════════════════════════════════════
//  STAMP BACK MARKS
// ═══════════════════════════════════════════════════════════════════
class _StampBackMarksPainter extends CustomPainter {
  final _StampPalette palette;
  final int month;
  const _StampBackMarksPainter({
    required this.palette,
    required this.month,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.75, size.height * 0.35);
    canvas.drawCircle(
      center,
      size.width * 0.18,
      Paint()
        ..color = palette.accent.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    canvas.drawCircle(
      center,
      size.width * 0.10,
      Paint()
        ..color = palette.accent.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final paint = Paint()
      ..color = _SA.ink.withOpacity(0.04)
      ..strokeWidth = 0.6;
    canvas.drawLine(
      Offset(0, size.height * 0.85),
      Offset(size.width, size.height * 0.15),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StampBackMarksPainter old) =>
      old.month != month;
}