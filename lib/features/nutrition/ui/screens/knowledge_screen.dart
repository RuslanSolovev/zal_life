// features/nutrition/ui/screens/knowledge_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_models.dart' show FoodProduct;
import '../../models/wellness_models.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/wellness_provider.dart';
import '../widgets/product_knowledge_sheet.dart';
import '../widgets/season_visuals.dart';

// ═══════════════════════════════════════════════════════════════════
//  PALETTE
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const bg = Color(0xFFF6F4EF);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF14171A);
  static const textMuted = Color(0xFF6B7178);
  static const divider = Color(0xFFE5E1D9);
  static const elevated = Color(0xFFEFEBE3);

  static const coral = Color(0xFFD96C7A);
  static const coralSoft = Color(0xFFFDECEE);
  static const graphite = Color(0xFF1B1F24);

  static const springDeep = Color(0xFF7C9B7A);
  static const springSoft = Color(0xFFE8EFE6);
  static const summerDeep = Color(0xFFE8895C);
  static const summerSoft = Color(0xFFFBEDE2);
  static const autumnDeep = Color(0xFFC99444);
  static const autumnSoft = Color(0xFFF5EBD8);
  static const winterDeep = Color(0xFF6F8DAD);
  static const winterSoft = Color(0xFFE5EDF4);
}

class _Hero {
  static const bgTop = Color(0xFF1A1D22);
  static const bgBottom = Color(0xFF12141A);
  static const textHigh = Colors.white;
  static const textLow = Color(0xFFA8ACB2);
}

class _SeasonPalette {
  final Color deep;
  final Color soft;
  const _SeasonPalette({required this.deep, required this.soft});

  static _SeasonPalette forMonth(int m) {
    if (m >= 3 && m <= 5) {
      return const _SeasonPalette(deep: _P.springDeep, soft: _P.springSoft);
    }
    if (m >= 6 && m <= 8) {
      return const _SeasonPalette(deep: _P.summerDeep, soft: _P.summerSoft);
    }
    if (m >= 9 && m <= 11) {
      return const _SeasonPalette(deep: _P.autumnDeep, soft: _P.autumnSoft);
    }
    return const _SeasonPalette(deep: _P.winterDeep, soft: _P.winterSoft);
  }
}

class _T {
  static TextStyle display({double size = 40, Color? color, double tracking = -1.4}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: tracking,
        color: color ?? _P.ink,
        height: 1.05,
      );

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? tracking,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: tracking,
        color: color ?? _P.ink,
        height: height,
      );

  static TextStyle overline({Color? color}) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
    color: color ?? _P.textMuted,
  );

  static TextStyle numeric({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double tracking = -0.4,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: tracking,
        color: color ?? _P.ink,
        height: 1.0,
        fontFeatures: const [ui.FontFeature.tabularFigures()],
      );
}

// ═══════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════
class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  static const _labels = ['Сезон', 'Витамины', 'Польза', 'Осторожно'];

  late int _activeTab = widget.initialTab;
  late int _prevTab = widget.initialTab;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: _P.bg,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectTab(int i) {
    if (i == _activeTab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _prevTab = _activeTab;
      _activeTab = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wellness = context.watch<WellnessProvider>();
    final nutrition = context.watch<NutritionProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _P.bg,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -350 && _activeTab < 3) _selectTab(_activeTab + 1);
            if (v > 350 && _activeTab > 0) _selectTab(_activeTab - 1);
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _buildHero(wellness)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabHeaderDelegate(
                  activeIndex: _activeTab,
                  labels: _labels,
                  onTap: _selectTab,
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: RepaintBoundary(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          ...previous,
                          if (current != null) current,
                        ],
                      ),
                      transitionBuilder: _buildTabTransition,
                      child: KeyedSubtree(
                        key: ValueKey<int>(_activeTab),
                        child: Padding(
                          padding:
                          const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          child: _buildCurrentTab(wellness, nutrition),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabTransition(Widget child, Animation<double> anim) {
    final key = child.key;
    final childTab = key is ValueKey<int> ? key.value : _activeTab;
    final isIncoming = childTab == _activeTab;
    final dir = _activeTab >= _prevTab ? 1.0 : -1.0;
    final beginOffset = isIncoming
        ? Offset(0.08 * dir, 0)
        : Offset(-0.08 * dir, 0);

    return ClipRect(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Widget _buildCurrentTab(
      WellnessProvider wellness, NutritionProvider nutrition) {
    switch (_activeTab) {
      case 0:
        return _SeasonTab(wellness: wellness, nutrition: nutrition);
      case 1:
        return _NutrientsTab(wellness: wellness, nutrition: nutrition);
      case 2:
        return _BenefitsTab(wellness: wellness, nutrition: nutrition);
      case 3:
        return _ContraTab(wellness: wellness, nutrition: nutrition);
      default:
        return _SeasonTab(wellness: wellness, nutrition: nutrition);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  HERO — с прогрессом сезона
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHero(WellnessProvider wellness) {
    final seasonal = wellness.seasonalNow.length;
    final month = wellness.currentMonth;
    final palette = _SeasonPalette.forMonth(month);
    final topInset = MediaQuery.paddingOf(context).top;

    // Прогресс сезона
    final daysLeft = daysLeftInMonth(DateTime.now());
    final totalDays = DateUtils.getDaysInMonth(
        DateTime.now().year, DateTime.now().month);
    final passed = totalDays - daysLeft;
    final progress = (passed / totalDays).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: ClipPath(
        clipper: _OrganicHeroClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_Hero.bgTop, _Hero.bgBottom],
            ),
          ),
          child: Stack(
            children: [
              // Sun glow
              Positioned(
                top: -80,
                right: -80,
                child: IgnorePointer(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          palette.deep.withOpacity(0.22),
                          palette.deep.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Second glow
              Positioned(
                top: 200,
                left: -100,
                child: IgnorePointer(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          palette.deep.withOpacity(0.10),
                          palette.deep.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, topInset + 8, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Press(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                          },
                          child: _glassPill(
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.chevron_left_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                        const Spacer(),
                        _seasonPill(month, palette),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('ЗНАНИЯ О ПИТАНИИ',
                        style: _T.overline(color: palette.deep)),
                    const SizedBox(height: 10),
                    Text('Что едим.',
                        style: _T.display(
                            size: 40,
                            color: _Hero.textHigh,
                            tracking: -1.4)),
                    Text('И почему это важно.',
                        style: _T.display(
                            size: 40,
                            color: _Hero.textHigh,
                            tracking: -1.4)),
                    const SizedBox(height: 10),
                    Text('Живой гид по тому, что сейчас в сезоне.',
                        style: _T.sans(
                          size: 13,
                          color: _Hero.textLow,
                          height: 1.4,
                        )),
                    const SizedBox(height: 18),

                    // 🆕 Прогресс месяца
                    _seasonProgress(progress, daysLeft, palette),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        _statCapsule(
                          icon: Icons.eco_rounded,
                          value: '$seasonal',
                          label: 'в сезоне',
                          accent: palette.deep,
                        ),
                        const SizedBox(width: 8),
                        _statCapsule(
                          icon: Icons.bubble_chart_rounded,
                          value: '${wellness.nutrientCounts.length}',
                          label: 'нутриентов',
                          accent: _P.springDeep,
                        ),
                        const SizedBox(width: 8),
                        _statCapsule(
                          icon: Icons.warning_amber_rounded,
                          value: '${wellness.productsWithContra.length}',
                          label: 'нюансов',
                          accent: _P.coral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 Полоса прогресса сезона
  Widget _seasonProgress(double progress, int daysLeft, _SeasonPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Прогресс месяца',
                  style: _T.sans(
                    size: 10,
                    weight: FontWeight.w600,
                    color: _Hero.textLow,
                    tracking: 0.3,
                  )),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.deep.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  daysLeft <= 1 ? 'последний день' : 'ещё $daysLeft дн',
                  style: _T.numeric(
                    size: 10,
                    weight: FontWeight.w700,
                    color: palette.deep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Прогресс-бар
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: Colors.white.withOpacity(0.08),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          palette.deep.withOpacity(0.7),
                          palette.deep,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: palette.deep.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassPill({required Widget child, double? width}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _seasonPill(int month, _SeasonPalette palette) {
    final label = kMonthFull[month] ?? '';
    return _glassPill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: palette.deep,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: palette.deep.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_seasonLabel(month)} · ${label.substring(0, 3)}',
              style: _T.sans(
                size: 11,
                weight: FontWeight.w500,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _seasonLabel(int m) {
    if (m >= 3 && m <= 5) return 'Весна';
    if (m >= 6 && m <= 8) return 'Лето';
    if (m >= 9 && m <= 11) return 'Осень';
    return 'Зима';
  }

  Widget _statCapsule({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Expanded(
      child: _glassPill(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: _T.numeric(
                          size: 15,
                          weight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _T.sans(
                        size: 9.5,
                        weight: FontWeight.w500,
                        color: _Hero.textLow,
                      ),
                    ),
                  ],
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
//  TAB BAR
// ═══════════════════════════════════════════════════════════════════
class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int activeIndex;
  final List<String> labels;
  final ValueChanged<int> onTap;

  _TabHeaderDelegate({
    required this.activeIndex,
    required this.labels,
    required this.onTap,
  });

  static const _barHeight = 64.0;
  static const _padTop = 10.0;
  static const _padBottom = 12.0;
  static const _pillPad = 5.0;

  @override
  double get maxExtent => _padTop + _barHeight + _padBottom;

  @override
  double get minExtent => _padTop + _barHeight + _padBottom;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.only(top: topInset),
      color: _P.bg,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, _padTop, 12, _padBottom),
        height: _barHeight,
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final innerW = constraints.maxWidth - _pillPad * 2;
          final tabW = innerW / labels.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: _pillPad + tabW * activeIndex,
                top: _pillPad,
                bottom: _pillPad,
                width: tabW,
                child: Container(
                  decoration: BoxDecoration(
                    color: _P.ink,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _P.ink.withOpacity(0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final selected = activeIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Container(
                        alignment: Alignment.center,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 2),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          style: _T.sans(
                            size: 13,
                            weight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color:
                            selected ? Colors.white : _P.textMuted,
                            tracking: -0.3,
                          ),
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate old) =>
      old.activeIndex != activeIndex || old.labels != labels;
}

// ═══════════════════════════════════════════════════════════════════
//  ORGANIC HERO CLIPPER
// ═══════════════════════════════════════════════════════════════════
class _OrganicHeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 36);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 4,
      size.width,
      size.height - 36,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  TAB 1 — СЕЗОН
// ═══════════════════════════════════════════════════════════════════
class _SeasonTab extends StatefulWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  const _SeasonTab({required this.wellness, required this.nutrition});

  @override
  State<_SeasonTab> createState() => _SeasonTabState();
}

class _SeasonTabState extends State<_SeasonTab>
    with SingleTickerProviderStateMixin {
  // 🆕 Фильтр по категориям
  int _filter = 0; // 0=Все, 1=Фрукты, 2=Овощи, 3=Зелень
  final _filterLabels = ['Все', 'Фрукты', 'Овощи', 'Зелень'];

  late final AnimationController _entrance;
  late final Animation<double> _entranceCurve;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _entranceCurve = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  List<ProductKnowledge> _applyFilter(List<ProductKnowledge> items) {
    if (_filter == 0) return items;
    return items.where((k) {
      final key = k.key.toLowerCase();
      if (_filter == 1) {
        // Фрукты и ягоды
        return key.contains('apple') ||
            key.contains('pear') ||
            key.contains('plum') ||
            key.contains('cherry') ||
            key.contains('berry') ||
            key.contains('currant') ||
            key.contains('peach') ||
            key.contains('apricot') ||
            key.contains('grape') ||
            key.contains('melon') ||
            key.contains('citrus') ||
            key.contains('orange') ||
            key.contains('mandarin') ||
            key.contains('lemon') ||
            key.contains('fig') ||
            key.contains('persimmon') ||
            key.contains('pomegranate') ||
            key.contains('kiwi') ||
            key.contains('banana') ||
            key.contains('watermelon') ||
            key.contains('strawberr') ||
            key.contains('raspberr') ||
            key.contains('blueberr') ||
            key.contains('cranberr') ||
            key.contains('lingonberr') ||
            key.contains('feijoa') ||
            key.contains('quince') ||
            key.contains('chokeberr') ||
            key.contains('viburnum') ||
            key.contains('sea_buckthorn') ||
            key.contains('blackberry') ||
            key.contains('cowberry') ||
            key.contains('grapefruit') ||
            key.contains('pomelo') ||
            key.contains('avocado');
      }
      if (_filter == 2) {
        // Овощи и корнеплоды
        return key.contains('cucumber') ||
            key.contains('tomato') ||
            key.contains('pepper') ||
            key.contains('zucchini') ||
            key.contains('pumpkin') ||
            key.contains('carrot') ||
            key.contains('beet') ||
            key.contains('radish') ||
            key.contains('potato') ||
            key.contains('onion') ||
            key.contains('garlic') ||
            key.contains('mushroom') ||
            key.contains('cabbage') ||
            key.contains('broccoli') ||
            key.contains('cauliflower') ||
            key.contains('eggplant') ||
            key.contains('corn') ||
            key.contains('turnip') ||
            key.contains('rutabaga') ||
            key.contains('parsnip') ||
            key.contains('celery') ||
            key.contains('leek') ||
            key.contains('kohlrabi') ||
            key.contains('daikon') ||
            key.contains('sweet_potato') ||
            key.contains('artichoke') ||
            key.contains('asparagus');
      }
      if (_filter == 3) {
        // Зелень и травы
        return key.contains('spinach') ||
            key.contains('lettuce') ||
            key.contains('parsley') ||
            key.contains('dill') ||
            key.contains('basil') ||
            key.contains('cilantro') ||
            key.contains('sorrel') ||
            key.contains('ramson') ||
            key.contains('arugula') ||
            key.contains('mint') ||
            key.contains('rosemary') ||
            key.contains('thyme') ||
            key.contains('sage') ||
            key.contains('oregano') ||
            key.contains('chard') ||
            key.contains('green_onion');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final month = widget.wellness.currentMonth;
    final palette = _SeasonPalette.forMonth(month);
    final ending = widget.wellness.endingThisMonth;
    final starting = widget.wellness.startingNextMonth;
    final current = widget.wellness.seasonalNow;
    final filtered = _applyFilter(current);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: _entranceCurve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(_entranceCurve),
            child: _IdentityCard(
              wellness: widget.wellness,
              nutrition: widget.nutrition,
              palette: palette,
            ),
          ),
        ),

        if (ending.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.schedule_rounded,
            label: 'УХОДИТ ИЗ СЕЗОНА',
            accent: _P.coral,
            count: ending.length,
          ),
          const SizedBox(height: 12),
          _Rail(
            items: ending,
            month: month,
            palette: palette,
            nutrition: widget.nutrition,
            variant: _RailVariant.leaving,
          ),
        ],

        if (starting.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.upcoming_rounded,
            label: 'СКОРО В СЕЗОНЕ',
            accent: _P.springDeep,
            count: starting.length,
          ),
          const SizedBox(height: 12),
          _Rail(
            items: starting,
            month: month,
            palette: palette,
            nutrition: widget.nutrition,
            variant: _RailVariant.coming,
          ),
        ],

        const SizedBox(height: 24),

        _SectionHeader(
          icon: Icons.eco_rounded,
          label: 'СЕЙЧАС В СЕЗОНЕ',
          accent: palette.deep,
          count: filtered.length,
          trailing: 'Все',
        ),

        const SizedBox(height: 10),

        // 🆕 Фильтр-чипы
        _buildFilterChips(palette),

        const SizedBox(height: 14),

        if (filtered.isEmpty)
          _buildEmpty()
        else
          _BentoGrid(
            items: filtered,
            month: month,
            palette: palette,
            nutrition: widget.nutrition,
          ),

        const SizedBox(height: 24),
        _ExploreCTA(total: widget.nutrition.products.length),
      ],
    );
  }

  // 🆕 Фильтр-чипы
  Widget _buildFilterChips(_SeasonPalette palette) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = _filter == i;
          return _Press(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filter = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? palette.deep : _P.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? palette.deep
                      : _P.divider,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Text(
                _filterLabels[i],
                style: _T.sans(
                  size: 12,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : _P.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.eco_outlined, size: 34, color: _P.springDeep),
          const SizedBox(height: 12),
          Text(
              _filter == 0
                  ? 'В этом месяце нет сезонных продуктов'
                  : 'Нет продуктов в этой категории',
              style: _T.sans(
                size: 13,
                weight: FontWeight.w500,
                color: _P.textMuted,
              )),
        ],
      ),
    );
  }
}

enum _RailVariant { leaving, coming }

// ── Identity card ─────────────────────────────────────────────
class _IdentityCard extends StatelessWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final _SeasonPalette palette;

  const _IdentityCard({
    required this.wellness,
    required this.nutrition,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final month = wellness.currentMonth;
    final daysLeft = daysLeftInMonth(DateTime.now());
    final meta = metaForMonth(month);
    final count = wellness.seasonalNow.length;
    final ending = wellness.endingThisMonth.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.deep,
              palette.deep.withOpacity(0.82),
              palette.deep.withOpacity(0.65),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Topographic texture
            Positioned(
              right: -30,
              top: -20,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(160, 160),
                  painter: _TopoPainter(),
                ),
              ),
            ),
            // Second texture
            Positioned(
              left: -40,
              bottom: -30,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(120, 120),
                  painter: _TopoPainter(),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RepaintBoundary(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        curve: const Cubic(0.2, 0.8, 0.2, 1),
                        builder: (_, v, child) => Transform.rotate(
                          angle: (1 - v) * 0.4,
                          child: Opacity(opacity: v, child: child),
                        ),
                        child: _SeasonWheel(
                          currentMonth: month,
                          activeMonths: (meta.months).toSet(),
                          count: count,
                          size: 140,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${meta.emoji} ${meta.label.toUpperCase()} · ${(kMonthFull[month] ?? '').toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _T.overline(
                                color: Colors.white.withOpacity(0.9)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            meta.tagline,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: _T.sans(
                              size: 14,
                              weight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _miniPill(
                                '$count в сезоне',
                                bg: Colors.white,
                                fg: _P.ink,
                                icon: Icons.eco_rounded,
                              ),
                              _miniPill(
                                daysLeft <= 1
                                    ? 'финал'
                                    : '$daysLeft дн',
                                bg: Colors.white.withOpacity(0.22),
                                fg: Colors.white,
                                icon: Icons.schedule_rounded,
                              ),
                              if (ending > 0)
                                _miniPill(
                                  '$ending уходит',
                                  bg: _P.coral.withOpacity(0.30),
                                  fg: Colors.white,
                                  icon: Icons.trending_down_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 🆕 Мини-статы внизу
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _miniStat(
                        'Месяцев',
                        '${meta.months.length}/12',
                        Icons.calendar_month_rounded,
                      ),
                      Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withOpacity(0.15)),
                      _miniStat(
                        'Всего',
                        '${wellness.productsForMonth(month).length}',
                        Icons.restaurant_menu_rounded,
                      ),
                      Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withOpacity(0.15)),
                      _miniStat(
                        'Сезон',
                        meta.label.substring(0, 1),
                        Icons.local_florist_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.numeric(
                    size: 12,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.sans(
                    size: 8.5,
                    weight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPill(String text,
      {required Color bg, required Color fg, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: _T.numeric(
                size: 10,
                weight: FontWeight.w600,
                color: fg,
                tracking: 0.1),
          ),
        ],
      ),
    );
  }
}

// ── Rail ──────────────────────────────────────────────────────
class _Rail extends StatelessWidget {
  final List<ProductKnowledge> items;
  final int month;
  final _SeasonPalette palette;
  final NutritionProvider nutrition;
  final _RailVariant variant;

  const _Rail({
    required this.items,
    required this.month,
    required this.palette,
    required this.nutrition,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final k = items[i];
          final isLeaving = variant == _RailVariant.leaving;
          final accent = isLeaving ? _P.coral : _P.springDeep;
          return _Press(
            onTap: () => showProductKnowledgeSheet(
              context,
              product: _findProduct(nutrition, k),
              knowledge: k,
              nutrition: nutrition,
            ),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLeaving
                      ? _P.coral.withOpacity(0.25)
                      : _P.springDeep.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(k.emoji,
                            style: const TextStyle(fontSize: 20)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLeaving
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_up_rounded,
                              size: 9,
                              color: accent,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isLeaving ? 'уходит' : 'скоро',
                              style: _T.sans(
                                size: 8,
                                weight: FontWeight.w700,
                                color: accent,
                                tracking: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    k.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.sans(
                      size: 13,
                      weight: FontWeight.w600,
                      color: _P.ink,
                      tracking: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLeaving
                        ? '${_nextMonth(month) == 13 ? 'янв' : _monthShort(_nextMonth(month))} последний'
                        : 'с ${_monthShort(k.seasonMonths.first)}',
                    style: _T.sans(
                      size: 9,
                      weight: FontWeight.w500,
                      color: _P.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MicroMonthBar(
                    activeMonths: (k.seasonMonths).toSet(),
                    currentMonth: month,
                    accent: accent,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _nextMonth(int m) => m == 12 ? 1 : m + 1;
  String _monthShort(int m) {
    const arr = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return arr[m];
  }
}

// ── Bento grid ────────────────────────────────────────────────
class _BentoGrid extends StatelessWidget {
  final List<ProductKnowledge> items;
  final int month;
  final _SeasonPalette palette;
  final NutritionProvider nutrition;

  const _BentoGrid({
    required this.items,
    required this.month,
    required this.palette,
    required this.nutrition,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) {
        final k = items[i];
        final isLight = (i % 3 == 1);
        final isCurrent = k.seasonMonths.contains(month);
        final isEnding = !k.seasonMonths.contains(
            month == 12 ? 1 : month + 1);

        return _Press(
          onTap: () => showProductKnowledgeSheet(
            context,
            product: _findProduct(nutrition, k),
            knowledge: k,
            nutrition: nutrition,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLight ? Colors.white : _P.divider.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.deep.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: (isLight
                            ? palette.soft
                            : palette.deep.withOpacity(0.14)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(k.emoji,
                          style: const TextStyle(fontSize: 26)),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (k.contraindications.isNotEmpty)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: _P.coral,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (isCurrent && isEnding) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: _P.coral.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'уходит',
                              style: _T.sans(
                                size: 7.5,
                                weight: FontWeight.w700,
                                color: _P.coral,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Название
                Text(
                  k.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _P.ink,
                    tracking: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Бенефиты
                if (k.benefits.isNotEmpty)
                  Text(
                    k.benefits
                        .take(2)
                        .map((b) => kBenefitMetas[b]!.name.toLowerCase())
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.sans(
                      size: 10,
                      weight: FontWeight.w500,
                      color: _P.textMuted,
                    ),
                  ),
                const SizedBox(height: 8),
                _MicroMonthBar(
                  activeMonths: (k.seasonMonths).toSet(),
                  currentMonth: month,
                  accent: palette.deep,
                  height: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExploreCTA extends StatelessWidget {
  final int total;
  const _ExploreCTA({required this.total});

  @override
  Widget build(BuildContext context) {
    return _Press(
      onTap: () {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Открываем полную энциклопедию…'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _P.ink,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ));
      },
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _P.graphite,
              _P.graphite.withOpacity(0.92),
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _P.graphite.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _P.coral,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Все $total продуктов',
                    style: _T.sans(
                      size: 14,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      tracking: -0.2,
                    ),
                  ),
                  Text(
                    'Полная энциклопедия',
                    style: _T.sans(
                      size: 11,
                      weight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB 2 — ВИТАМИНЫ (обновлённый)
// ═══════════════════════════════════════════════════════════════════
class _NutrientsTab extends StatelessWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  const _NutrientsTab({required this.wellness, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final counts = wellness.nutrientCounts;
    final kinds = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final maxCount = counts.values.isEmpty
        ? 1
        : counts.values.reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🆕 Заголовок статистики
        _NutrientsOverview(
          totalNutrients: kinds.length,
          totalProducts: wellness.nutrientCounts.values.fold(
              0, (a, b) => a + b),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < kinds.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _NutrientTile(
            meta: kNutrientMetas[kinds[i]]!,
            products: wellness.productsRichIn(kinds[i]),
            count: counts[kinds[i]]!,
            maxCount: maxCount,
            nutrition: nutrition,
          ),
        ],
      ],
    );
  }
}

class _NutrientsOverview extends StatelessWidget {
  final int totalNutrients;
  final int totalProducts;
  const _NutrientsOverview({
    required this.totalNutrients,
    required this.totalProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _P.springSoft,
            _P.springSoft.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.springDeep.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _P.springDeep.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.bubble_chart_rounded,
                color: _P.springDeep, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Витаминный компас',
                  style: _T.sans(
                    size: 15,
                    weight: FontWeight.w700,
                    color: _P.ink,
                    tracking: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalNutrients нутриентов · $totalProducts связей с продуктами',
                  style: _T.sans(
                    size: 11,
                    color: _P.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientTile extends StatefulWidget {
  final NutrientMeta meta;
  final List<ProductKnowledge> products;
  final int count;
  final int maxCount;
  final NutritionProvider nutrition;
  const _NutrientTile({
    required this.meta,
    required this.products,
    required this.count,
    required this.maxCount,
    required this.nutrition,
  });

  @override
  State<_NutrientTile> createState() => _NutrientTileState();
}

class _NutrientTileState extends State<_NutrientTile>
    with AutomaticKeepAliveClientMixin {
  bool _expanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final progress = widget.maxCount > 0
        ? (widget.count / widget.maxCount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.divider),
      ),
      child: Column(
        children: [
          // 🆕 Цветная верхняя полоска
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.meta.color.withOpacity(0.6),
                  widget.meta.color,
                ],
              ),
            ),
          ),
          _Press(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: widget.meta.color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(widget.meta.emoji,
                            style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(widget.meta.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _T.sans(
                                        size: 14,
                                        weight: FontWeight.w600,
                                        color: _P.ink,
                                        tracking: -0.2,
                                      )),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: widget.meta.color
                                        .withOpacity(0.14),
                                    borderRadius:
                                    BorderRadius.circular(6),
                                  ),
                                  child: Text('${widget.count}',
                                      style: _T.numeric(
                                        size: 10,
                                        weight: FontWeight.w700,
                                        color: widget.meta.color,
                                      )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(widget.meta.benefit,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _T.sans(
                                    size: 11, color: _P.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _P.textMuted,
                            size: 18),
                      ),
                    ],
                  ),
                  // 🆕 Прогресс-бар
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(
                          height: 4,
                          color: widget.meta.color.withOpacity(0.10),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: widget.meta.color,
                              borderRadius: BorderRadius.circular(2),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.products.map((k) {
                  return _Press(
                    onTap: () => showProductKnowledgeSheet(
                      context,
                      product: _findProduct(widget.nutrition, k),
                      knowledge: k,
                      nutrition: widget.nutrition,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.meta.color.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.meta.color.withOpacity(0.20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(k.emoji,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(k.displayName,
                              style: _T.sans(
                                size: 12,
                                weight: FontWeight.w500,
                                color: _P.ink,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB 3 — ПОЛЬЗА
// ═══════════════════════════════════════════════════════════════════
class _BenefitsTab extends StatelessWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  const _BenefitsTab({required this.wellness, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final kinds = kBenefitMetas.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < kinds.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _BenefitTile(
            meta: kBenefitMetas[kinds[i]]!,
            products: wellness.productsForBenefit(kinds[i]),
            nutrition: nutrition,
          ),
        ],
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final BenefitMeta meta;
  final List<ProductKnowledge> products;
  final NutritionProvider nutrition;
  const _BenefitTile({
    required this.meta,
    required this.products,
    required this.nutrition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.divider),
      ),
      child: Column(
        children: [
          // 🆕 Цветная шапка с градиентом
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  meta.color.withOpacity(0.18),
                  meta.color.withOpacity(0.06),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: meta.color.withOpacity(0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(meta.emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta.name,
                          style: _T.sans(
                            size: 15,
                            weight: FontWeight.w700,
                            color: _P.ink,
                            tracking: -0.3,
                          )),
                      const SizedBox(height: 2),
                      Text(meta.tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _T.sans(
                              size: 11, color: _P.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: meta.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${products.length}',
                      style: _T.numeric(
                        size: 12,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      )),
                ),
              ],
            ),
          ),
          // Продукты
          Padding(
            padding: const EdgeInsets.all(12),
            child: products.isEmpty
                ? Text('Пока нет данных',
                style: _T.sans(size: 11, color: _P.textMuted))
                : SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final k = products[i];
                  return _Press(
                    onTap: () => showProductKnowledgeSheet(
                      context,
                      product: _findProduct(nutrition, k),
                      knowledge: k,
                      nutrition: nutrition,
                    ),
                    child: Container(
                      width: 78,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: meta.color.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: meta.color.withOpacity(0.14)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(k.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(k.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: _T.sans(
                                size: 10,
                                weight: FontWeight.w600,
                                color: _P.ink,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB 4 — ОСТОРОЖНО (сгруппировано по severity)
// ═══════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════
//  TAB 4 — ОСТОРОЖНО (сгруппировано по severity)
// ═══════════════════════════════════════════════════════════════════
class _ContraTab extends StatelessWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  const _ContraTab({required this.wellness, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final items = wellness.productsWithContra;

    // Группировка по max severity
    final warning = <ProductKnowledge>[];
    final caution = <ProductKnowledge>[];
    final info = <ProductKnowledge>[];

    for (final k in items) {
      final maxSeverity = k.contraindications
          .map((c) => c.severity.index)
          .reduce(math.max);
      if (maxSeverity == ContraSeverity.warning.index) {
        warning.add(k);
      } else if (maxSeverity == ContraSeverity.caution.index) {
        caution.add(k);
      } else {
        info.add(k);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Дисклеймер
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _P.autumnDeep.withOpacity(0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _P.autumnDeep,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Информация носит справочный характер и не заменяет '
                      'консультацию врача.',
                  style: _T.sans(size: 11, color: _P.ink, height: 1.4),
                ),
              ),
            ],
          ),
        ),

        // Группы
        if (warning.isNotEmpty) ...[
          const SizedBox(height: 20),
          _severityHeader(
            icon: Icons.warning_amber_rounded,
            label: 'ВНИМАНИЕ',
            count: warning.length,
            color: _P.coral,
          ),
          const SizedBox(height: 10),
          ...warning.map((k) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _contraCard(context, k), // ← context передан
          )),
        ],

        if (caution.isNotEmpty) ...[
          const SizedBox(height: 16),
          _severityHeader(
            icon: Icons.info_rounded,
            label: 'ОСТОРОЖНО',
            count: caution.length,
            color: _P.autumnDeep,
          ),
          const SizedBox(height: 10),
          ...caution.map((k) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _contraCard(context, k), // ← context передан
          )),
        ],

        if (info.isNotEmpty) ...[
          const SizedBox(height: 16),
          _severityHeader(
            icon: Icons.lightbulb_outline_rounded,
            label: 'ИНФО',
            count: info.length,
            color: _P.winterDeep,
          ),
          const SizedBox(height: 10),
          ...info.map((k) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _contraCard(context, k), // ← context передан
          )),
        ],
      ],
    );
  }

  Widget _severityHeader({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(label, style: _T.overline(color: color)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$count',
              style: _T.numeric(
                size: 9.5,
                weight: FontWeight.w700,
                color: color,
              )),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.30),
                  color.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🔧 ДОБАВЛЕН ПАРАМЕТР context
  Widget _contraCard(BuildContext context, ProductKnowledge k) {
    return _Press(
      onTap: () => showProductKnowledgeSheet(
        context,
        product: _findProduct(nutrition, k),
        knowledge: k,
        nutrition: nutrition,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _P.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(k.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(k.displayName,
                      style: _T.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: _P.ink,
                      )),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: _P.textMuted, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            ...k.contraindications.map((c) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _contraRow(c),
            )),
          ],
        ),
      ),
    );
  }

  Widget _contraRow(Contra c) {
    final color = switch (c.severity) {
      ContraSeverity.warning => _P.coral,
      ContraSeverity.caution => _P.autumnDeep,
      ContraSeverity.info => _P.winterDeep,
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                switch (c.severity) {
                  ContraSeverity.warning => Icons.warning_amber_rounded,
                  ContraSeverity.caution => Icons.info_rounded,
                  ContraSeverity.info => Icons.lightbulb_outline_rounded,
                },
                size: 11,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(c.title,
                    style: _T.sans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: color,
                      tracking: 0.2,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(c.message,
              style: _T.sans(size: 11, color: _P.ink, height: 1.35)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SEASON WHEEL
// ═══════════════════════════════════════════════════════════════════
class _SeasonWheel extends StatelessWidget {
  final int currentMonth;
  final Set<int> activeMonths;
  final int count;
  final double size;

  const _SeasonWheel({
    required this.currentMonth,
    required this.activeMonths,
    required this.count,
    this.size = 140,
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
            painter: _SeasonWheelPainter(
              currentMonth: currentMonth,
              activeMonths: activeMonths,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: _T.display(
                  size: size * 0.34,
                  color: Colors.white,
                  tracking: -1.0,
                ),
              ),
              Text(
                'мес',
                style: _T.sans(
                  size: size * 0.07,
                  weight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.7),
                  tracking: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeasonWheelPainter extends CustomPainter {
  final int currentMonth;
  final Set<int> activeMonths;
  const _SeasonWheelPainter({
    required this.currentMonth,
    required this.activeMonths,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const months = 12;
    final stepAngle = (2 * math.pi) / months;
    final gapAngle = stepAngle * 0.18;
    final arcSweep = stepAngle - gapAngle;

    for (var i = 0; i < months; i++) {
      final monthNum = i + 1;
      final startAngle = -math.pi / 2 + i * stepAngle + gapAngle / 2;
      final isActive = activeMonths.contains(monthNum);
      final isCurrent = monthNum == currentMonth;

      if (isActive) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          arcSweep,
          false,
          Paint()
            ..color = Colors.white.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 18
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          arcSweep,
          false,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          arcSweep,
          false,
          Paint()
            ..color = Colors.white.withOpacity(0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
      }

      if (isCurrent) {
        final dotAngle = startAngle + arcSweep / 2;
        final dotPos = Offset(
          center.dx + (radius - 20) * math.cos(dotAngle),
          center.dy + (radius - 20) * math.sin(dotAngle),
        );
        canvas.drawCircle(dotPos, 3.5, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SeasonWheelPainter old) =>
      old.currentMonth != currentMonth ||
          old.activeMonths != activeMonths;
}

// ═══════════════════════════════════════════════════════════════════
//  MICRO MONTH BAR
// ═══════════════════════════════════════════════════════════════════
class _MicroMonthBar extends StatelessWidget {
  final Set<int> activeMonths;
  final int currentMonth;
  final Color accent;
  final double height;

  const _MicroMonthBar({
    required this.activeMonths,
    required this.currentMonth,
    required this.accent,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(12, (i) {
        final m = i + 1;
        final isActive = activeMonths.contains(m);
        final isCurrent = m == currentMonth;

        Color fill;
        Color? border;
        if (isActive) {
          fill = accent;
          border = isCurrent ? Colors.white : null;
        } else {
          fill =
          isCurrent ? Colors.transparent : Colors.black.withOpacity(0.08);
          border = isCurrent ? accent : null;
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 11 ? 0 : 2),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(999),
                border: border != null
                    ? Border.all(color: border, width: 1)
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SECTION HEADER — с градиентной линией
// ═══════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final int count;
  final String? trailing;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.accent,
    required this.count,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 12, color: accent),
        ),
        const SizedBox(width: 8),
        Text(label, style: _T.overline(color: accent)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$count',
              style: _T.numeric(
                size: 9.5,
                weight: FontWeight.w700,
                color: accent,
              )),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(0.30),
                  accent.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Text(trailing!,
              style: _T.sans(
                size: 12,
                weight: FontWeight.w600,
                color: _P.ink,
              )),
          const Icon(Icons.arrow_forward_rounded,
              size: 14, color: _P.ink),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Topographic painter
// ═══════════════════════════════════════════════════════════════════
class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(center, i * 16.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED helpers
// ═══════════════════════════════════════════════════════════════════
FoodProduct? _findProduct(NutritionProvider nutrition, ProductKnowledge k) {
  for (final p in nutrition.products) {
    if (p.id == k.key) return p;
    final norm = p.name.toLowerCase().replaceAll('ё', 'е').replaceAll(' ', '_');
    if (norm.contains(k.key) || k.key.contains(norm)) return p;
  }
  return null;
}

// ═══════════════════════════════════════════════════════════════════
//  PRESS
// ═══════════════════════════════════════════════════════════════════
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Press({required this.child, this.onTap});
  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final inner = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap!();
      },
      onTapCancel: () => setState(() => _down = false),
      child: widget.child,
    );
    if (reduce) return inner;
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      child: inner,
    );
  }
}