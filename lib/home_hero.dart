// lib/home_hero.dart
part of 'home_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  HERO — 11 ПЕРЕКЛЮЧАЕМЫХ СТИЛЕЙ
// ═══════════════════════════════════════════════════════════════════
const _heroStyleNames = [
'Классика', 'Палуба', 'Кокпит', 'Сплит', 'Остров', 'Карусель',
'Радар', 'Сияние', 'Тахо', 'Поп-арт', 'Параллакс',
'Винил', 'Терминал', 'Орбита', 'Синтвейв', 'Гравитация',
// 🆕 НОВЫЕ КРЕАТИВНЫЕ ВАРИАНТЫ:
  'Таймлайн', 'Стопка', 'Бенто', 'Пульс', 'Чек',
  'Киберпанк', 'Стекло', 'Минимализм', 'Пиксель', 'Жидкий',
];

const _heroStyleDescriptions = [
'Исходный вид: кнопки по углам, чипы под кольцами',
'Кнопки в капсуле, метрики — ровная панель внизу',
'Метрики по бортам колец, все кнопки снизу',
'Приветствие слева, кольца и прогрессы справа',
'Светлый остров метрик поверх границы шапки',
'Кнопка-веер и свайповые карточки метрик',
'HUD-сканер: луч, блипы контактов, моно-readout',
'Живое северное сияние и парящие стеклянные пилюли',
'Гоночный тахометр: стрелка, одометр, лампы готовности',
'Комикс-стикеры, halftone и звезда уровня',
'Стеклянные осколки глубины — тяни пальцем',
'Пластинка с тонармом, трек-лист метрик и эквалайзер',
'CRT-терминал: печать команд, ASCII-прогрессы, курсор',
'Метрики-спутники на живых орбитах вокруг планеты',
'Неон 80-х: сетка, закатное солнце, хром-типографика',
'Шары на столе: наклоняй телефон — они катятся',

  'Неделя как путь: светящаяся точка на горизонтальной линии',
  '3D-глубина: статистика в виде стопки наклоненных карт',
  'Модульная сетка: асимметричные прямоугольные виджеты',
  'Живая волна активности на фоне с линейным прогрессом',
  'Брутализм: моноширинный шрифт, пунктир и структура чека',

  'Неоновые границы, сетка и high-tech интерфейс',
  'Полупрозрачные карточки с мягким свечением и размытием',
  'Огромные цифры, чистота и швейцарский стиль',
  'Ретро-гейминг: блочные прогресс-бары и 8-битная эстетика',
  'Анимированные переливающиеся градиенты и парящие элементы',
];

class _HeroData {
final DateTime today;
final int streak, level, thisWeek, kcal, kcalGoal, daysPassed;
final double pWorkouts, pStreak, pCalories, levelProgress;
final List<bool> daysActive;
const _HeroData({
required this.today, required this.streak, required this.level,
required this.thisWeek, required this.kcal, required this.kcalGoal,
required this.daysPassed, required this.pWorkouts, required this.pStreak,
required this.pCalories, required this.levelProgress,
required this.daysActive,
});
}

class _HomeHero extends StatefulWidget {
final int style;
final FitnessProvider fitness;
final NutritionProvider nutrition;
final String avatarEmoji;
final String? avatarImagePath;
final String profileName;
final String bgImage;
final VoidCallback onSettings, onShopping, onPantry;
const _HomeHero({
required this.style, required this.fitness, required this.nutrition,
required this.avatarEmoji, required this.avatarImagePath,
required this.profileName, required this.bgImage,
required this.onSettings, required this.onShopping, required this.onPantry,
});
@override
State<_HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<_HomeHero> {
bool _isFlipped = false;
Timer? _clockTimer;
final ValueNotifier<DateTime> _now = ValueNotifier(DateTime.now());

@override
void initState() {
super.initState();
_clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
if (mounted) _now.value = DateTime.now();
});
}

@override
void dispose() {
_clockTimer?.cancel();
_now.dispose();
super.dispose();
}

void _toggleCoin() {
HapticFeedback.mediumImpact();
setState(() => _isFlipped = !_isFlipped);
}

_HeroData _data() {
final stats = widget.fitness.getStats();
final today = DateTime.now();
final total = ((stats['totalWorkouts'] ?? 0) as num).toInt();
final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
final thisWeek = _getThisWeek(widget.fitness, today);
final summary = widget.nutrition.getSummaryForDate(today);
final goals = widget.nutrition.getGoalsForDate(today);
final weekData = _buildWeekData(widget.fitness, today, today.weekday - 1);
return _HeroData(
today: today,
streak: streak,
level: _levelFromStats(stats),
levelProgress: ((total % 3) / 3).clamp(0.0, 1.0).toDouble(),
thisWeek: thisWeek,
kcal: summary.calories.round(),
kcalGoal: goals.calories.round(),
pWorkouts: (thisWeek / kWeekGoal).clamp(0.0, 1.0).toDouble(),
pStreak: (streak / 30).clamp(0.0, 1.0).toDouble(),
pCalories: goals.calories > 0
? (summary.calories / goals.calories).clamp(0.0, 1.0).toDouble()
    : 0.0,
daysActive: List<bool>.generate(
7, (i) => i < weekData.length && weekData[i].workouts > 0),
daysPassed: today.weekday,
);
}

@override
Widget build(BuildContext context) {
final d = _data();
return AnimatedSwitcher(
duration: const Duration(milliseconds: 320),
switchInCurve: Curves.easeOutCubic,
switchOutCurve: Curves.easeInCubic,
child: KeyedSubtree(
key: ValueKey(widget.style),
child: _variant(d),
),
);
}

Widget _variant(_HeroData d) {
  switch (widget.style) {
    case 1: return _deck(d);
    case 2: return _cockpit(d);
    case 3: return _split(d);
    case 4: return _island(d);
    case 5: return _carousel(d);
    case 6: return _radar(d);
    case 7: return _aurora(d);
    case 8: return _tacho(d);
    case 9: return _pop(d);
    case 10: return _parallax(d);
    default:
    // 🛡️ Готовим контекст один раз для всех сложных стилей (11+)
      final ctx = _XHeroCtx(
        d: d,
        coin: (s) => _coin(s, d),
        bgLayers: _bgLayers(),
        name: widget.profileName.isEmpty ? 'атлет' : widget.profileName,
        now: _now,
        onCart: widget.onShopping,
        onPantry: widget.onPantry,
        onSettings: widget.onSettings,
      );

      // 🆕 СТИЛИ 16–20 (Креативные: Таймлайн, Стопка, Бенто, Пульс, Чек)
      if (widget.style >= 16 && widget.style <= 20) {
        return buildCreativeHeroStyle(style: widget.style, x: ctx);
      }

      // СТИЛИ 11–15 (Экстра: Винил, Терминал, Орбита, Синтвейв, Гравитация)
      if (widget.style >= 11 && widget.style <= 15) {
        return buildExtraHeroStyle(style: widget.style, x: ctx);
      }

      // СТИЛЬ 0 (Классика)
      return _classic(d);
  }
}

// ── Общие слои фона ──
List<Widget> _bgLayers() => [
Positioned.fill(
child: Image.asset(
widget.bgImage,
key: ValueKey(widget.bgImage),
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft, end: Alignment.bottomRight,
colors: [_Hero.bgTop, _Hero.bgBottom],
),
),
),
),
),
Positioned.fill(
child: DecoratedBox(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter, end: Alignment.bottomCenter,
colors: [
const Color(0xFF07110F).withOpacity(0.38),
Colors.black.withOpacity(0.08),
const Color(0xFF07110F).withOpacity(0.48),
_Palette.bg.withOpacity(0.02),
],
stops: const [0.0, 0.28, 0.72, 1.0],
),
),
),
),
Positioned(
left: 0, right: 0, bottom: 0, height: 184,
child: IgnorePointer(
child: DecoratedBox(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter, end: Alignment.bottomCenter,
colors: [
Colors.transparent,
_Palette.bg.withOpacity(0.10),
_Palette.bg.withOpacity(0.42),
_Palette.bg.withOpacity(0.82),
_Palette.bg,
],
stops: const [0.0, 0.24, 0.52, 0.82, 1.0],
),
),
),
),
),
];

Widget _cap(Widget child, _R r) => Center(
child: ConstrainedBox(
constraints: BoxConstraints(maxWidth: r.s(460)),
child: child,
),
);

// ── Монетка: кольца ⇄ аватар ──
Widget _coin(double size, _HeroData d) {
return GestureDetector(
onTap: _toggleCoin,
child: _CoinFlipWidget(
isFlipped: _isFlipped,
size: size,
front: Container(
width: size, height: size,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: Colors.black.withOpacity(0.15),
border: Border.all(color: Colors.white.withOpacity(0.1)),
),
child: TweenAnimationBuilder<double>(
tween: Tween(begin: 0.0, end: 1.0),
duration: const Duration(milliseconds: 1500),
curve: Curves.easeOutCubic,
builder: (_, anim, __) => ValueListenableBuilder<DateTime>(
valueListenable: _now,
builder: (_, now, ___) => CustomPaint(
size: Size(size, size),
painter: _HeroRingsPainter(
anim: anim,
daysActive: d.daysActive,
daysPassed: d.daysPassed,
caloriesProgress: d.pCalories,
workoutsProgress: d.pWorkouts,
streakProgress: d.pStreak,
time: now,
),
),
),
),
),
back: _avatarBack(size),
),
);
}

Widget _avatarBack(double size) {
final path = widget.avatarImagePath;
final hasPhoto = path != null && path.isNotEmpty;
return SizedBox(
width: size, height: size,
child: Container(
decoration: BoxDecoration(
shape: BoxShape.circle,
border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.2),
blurRadius: 16, spreadRadius: -2,
),
],
),
clipBehavior: Clip.antiAlias,
child: hasPhoto
? Image.file(
File(path),
width: size, height: size, fit: BoxFit.cover,
errorBuilder: (_, __, ___) => Container(
color: _Hero.bgBottom,
child: Center(
child: Text(widget.avatarEmoji,
style: TextStyle(fontSize: size * 0.45)),
),
),
)
    : Container(
color: _Hero.bgBottom,
child: Center(
child: Text(widget.avatarEmoji,
style: TextStyle(fontSize: size * 0.45)),
),
),
),
);
}


// ═══ СТИЛЬ 0 — IOS FITNESS ═══
// Главный экран: спокойная типографика, стеклянные действия,
// центральный циферблат и единая панель метрик.
Widget _classic(_HeroData d) {
final r = _R(context);
final name = widget.profileName.trim().isEmpty
? 'Твой прогресс'
    : widget.profileName.trim();

return ClipRRect(
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(34),
bottomRight: Radius.circular(34),
),
child: Stack(
children: [
..._bgLayers(),
SafeArea(
bottom: false,
left: false,
right: false,
child: Padding(
padding: EdgeInsets.fromLTRB(r.s(20), r.s(8), r.s(20), r.s(18)),
child: _cap(
Column(
mainAxisSize: MainAxisSize.min,
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(
'${_greetingIcon()} ${_greeting()}',
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.72),
fontSize: r.fs(11),
fontWeight: FontWeight.w600,
letterSpacing: 0.2,
),
),
SizedBox(height: r.s(3)),
Text(
name,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.inter(
color: Colors.white,
fontSize: r.fs(23),
fontWeight: FontWeight.w800,
letterSpacing: -0.8,
height: 1.08,
),
),
SizedBox(height: r.s(7)),
_LevelBadge(level: d.level, scale: r.scale),
],
),
),
SizedBox(width: r.s(5)),
_heroIconBtn(
Icons.shopping_bag_outlined,
widget.onShopping,
r,
size: 40,
),
SizedBox(width: r.s(7)),
_heroIconBtn(
Icons.kitchen_outlined,
widget.onPantry,
r,
size: 40,
),
SizedBox(width: r.s(7)),
_heroIconBtn(
Icons.tune_rounded,
widget.onSettings,
r,
size: 40,
),
],
),
SizedBox(height: r.s(8)),
_coin(r.s(270), d),
SizedBox(height: r.s(9)),
_heroDeckBar(d, r),
],
),
r,
),
),
),
],
),
);
}

// ═══ СТИЛЬ 1 — ПАЛУБА ═══
Widget _deck(_HeroData d) {
final r = _R(context);
return ClipRRect(
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48),
),
child: Stack(
children: [
..._bgLayers(),
SafeArea(
bottom: false, left: false, right: false,
child: Padding(
padding: EdgeInsets.fromLTRB(r.s(20), r.s(4), r.s(20), r.s(18)),
child: _cap(
Column(
children: [
Row(
children: [
_heroGlassPill(r, [
(Icons.shopping_cart_rounded, widget.onShopping),
(Icons.kitchen_rounded, widget.onPantry),
]),
const Spacer(),
_heroIconBtn(Icons.tune_rounded, widget.onSettings, r),
],
),
SizedBox(height: r.s(6)),
_coin(r.s(300), d),
SizedBox(height: r.s(14)),
_heroDeckBar(d, r),
],
),
r,
),
),
),
],
),
);
}

// ═══ СТИЛЬ 2 — КОКПИТ ═══
Widget _cockpit(_HeroData d) {
final r = _R(context);
final name = widget.profileName.isEmpty ? 'атлет' : widget.profileName;
return ClipRRect(
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48),
),
child: Stack(
children: [
..._bgLayers(),
SafeArea(
bottom: false, left: false, right: false,
child: Padding(
padding: EdgeInsets.fromLTRB(r.s(20), r.s(6), r.s(20), r.s(18)),
child: _cap(
Column(
children: [
Text('${_greetingIcon()} ${_greeting()}, $name',
maxLines: 1, overflow: TextOverflow.ellipsis,
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.85),
fontSize: r.fs(12), fontWeight: FontWeight.w600,
)),
SizedBox(height: r.s(12)),
_LevelBadge(level: d.level, scale: r.scale),
SizedBox(height: r.s(12)),
Row(
children: [
Expanded(
child: Column(
children: [
_heroCockpitTile(
icon: Icons.calendar_view_week_rounded,
color: _HeroAccents.amber,
value: '${d.thisWeek}/7', label: 'Неделя',
frac: d.pWorkouts, r: r,
),
SizedBox(height: r.s(10)),
_heroCockpitTile(
icon: Icons.local_fire_department_rounded,
color: _HeroAccents.sage,
value: '${d.kcal}', label: 'Ккал',
frac: d.pCalories, r: r,
),
],
),
),
SizedBox(width: r.s(8)),
_coin(r.s(184), d),
SizedBox(width: r.s(8)),
Expanded(
child: Column(
children: [
_heroCockpitTile(
icon: Icons.fitness_center_rounded,
color: _HeroAccents.pink,
value: '${(d.pWorkouts * 100).round()}%',
label: 'Трен.', frac: d.pWorkouts, r: r,
),
SizedBox(height: r.s(10)),
_heroCockpitTile(
icon: Icons.bolt_rounded,
color: _HeroAccents.sky,
value: '${d.streak} д', label: 'Серия',
frac: d.pStreak, r: r,
),
],
),
),
],
),
SizedBox(height: r.s(16)),
_heroGlassPill(r, [
(Icons.shopping_cart_rounded, widget.onShopping),
(Icons.kitchen_rounded, widget.onPantry),
(Icons.tune_rounded, widget.onSettings),
]),
],
),
r,
),
),
),
],
),
);
}

// ═══ СТИЛЬ 3 — СПЛИТ ═══
Widget _split(_HeroData d) {
final r = _R(context);
final name = widget.profileName.isEmpty ? 'Атлет' : widget.profileName;
return ClipRRect(
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48),
),
child: Stack(
children: [
..._bgLayers(),
SafeArea(
bottom: false, left: false, right: false,
child: Padding(
padding: EdgeInsets.fromLTRB(r.s(20), r.s(6), r.s(20), r.s(20)),
child: _cap(
Column(
children: [
Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text('${_greetingIcon()} ${_greeting()}',
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.7),
fontSize: r.fs(11),
fontWeight: FontWeight.w600,
)),
SizedBox(height: r.s(2)),
Text(name,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.inter(
color: Colors.white, fontSize: r.fs(20),
fontWeight: FontWeight.w700,
letterSpacing: -0.5,
)),
],
),
),
_heroIconBtn(Icons.shopping_cart_rounded,
widget.onShopping, r, size: 40),
SizedBox(width: r.s(8)),
_heroIconBtn(Icons.kitchen_rounded,
widget.onPantry, r, size: 40),
SizedBox(width: r.s(8)),
_heroIconBtn(Icons.tune_rounded,
widget.onSettings, r, size: 40),
],
),
SizedBox(height: r.s(18)),
Row(
children: [
Column(
mainAxisSize: MainAxisSize.min,
children: [
_coin(r.s(168), d),
SizedBox(height: r.s(10)),
_LevelBadge(level: d.level, scale: r.scale),
],
),
SizedBox(width: r.s(14)),
Expanded(child: _heroSplitCard(d, r)),
],
),
],
),
r,
),
),
),
],
),
);
}

// ═══ СТИЛЬ 4 — ОСТРОВ ═══
Widget _island(_HeroData d) {
final r = _R(context);
return Column(
children: [
Stack(
clipBehavior: Clip.none,
children: [
ClipRRect(
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(48),
bottomRight: Radius.circular(48),
),
child: Stack(
children: [
..._bgLayers(),
SafeArea(
bottom: false, left: false, right: false,
child: Padding(
padding: EdgeInsets.fromLTRB(
r.s(20), r.s(4), r.s(20), r.s(56)),
child: _cap(
Column(
children: [
Center(
child: _heroGlassPill(r, [
(Icons.shopping_cart_rounded, widget.onShopping),
(Icons.kitchen_rounded, widget.onPantry),
(Icons.tune_rounded, widget.onSettings),
]),
),
SizedBox(height: r.s(10)),
_coin(r.s(300), d),
],
),
r,
),
),
),
],
),
),
Positioned(
left: r.s(20), right: r.s(20), bottom: -r.s(46),
child: _cap(_heroDockCard(d, r), r),
),
],
),
SizedBox(height: r.s(58)),
],
);
}

// ═══ СТИЛЬ 5 — КАРУСЕЛЬ ═══
Widget _carousel(_HeroData d) {
final r = _R(context);
return ClipRRect(
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48),
),
child: Stack(
children: [
..._bgLayers(),
SafeArea(
bottom: false, left: false, right: false,
child: Padding(
padding: EdgeInsets.fromLTRB(r.s(20), r.s(6), r.s(20), r.s(18)),
child: _cap(
Column(
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text('${_greetingIcon()} ${_greeting()}',
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.75),
fontSize: r.fs(11),
fontWeight: FontWeight.w600,
)),
SizedBox(height: r.s(6)),
_LevelBadge(level: d.level, scale: r.scale),
],
),
const Spacer(),
_HeroSpeedDial(
r: r,
onCart: widget.onShopping,
onPantry: widget.onPantry,
onSettings: widget.onSettings,
),
],
),
SizedBox(height: r.s(8)),
_coin(r.s(290), d),
SizedBox(height: r.s(14)),
_HeroMetricCarousel(d: d, scale: r.scale),
],
),
r,
),
),
),
],
),
);
}

// ═══ СТИЛЬ 6 — РАДАР ═══
Widget _radar(_HeroData d) {
final r = _R(context);
return ClipRRect(
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48),
),
child: Stack(
children: [
..._bgLayers(),
SafeArea(
bottom: false, left: false, right: false,
child: Padding(
padding: EdgeInsets.fromLTRB(r.s(18), r.s(6), r.s(18), r.s(18)),
child: _cap(
Column(
children: [
Row(
children: [
_RadarStatusChip(level: d.level, scale: r.scale),
const Spacer(),
ValueListenableBuilder<DateTime>(
valueListenable: _now,
builder: (_, n, __) => Text(
'${n.hour.toString().padLeft(2, '0')}:'
'${n.minute.toString().padLeft(2, '0')}:'
'${n.second.toString().padLeft(2, '0')}',
style: GoogleFonts.jetBrainsMono(
color: _Vibrant.neonGreen.withOpacity(0.9),
fontSize: r.fs(11), fontWeight: FontWeight.w700,
letterSpacing: 1,
fontFeatures: const [FontFeature.tabularFigures()],
),
),
),
],
),
SizedBox(height: r.s(10)),
_RadarScope(
size: r.s(264),
coinSize: r.s(240),
daysActive: d.daysActive,
child: _coin(r.s(240), d),
),
SizedBox(height: r.s(12)),
Row(
children: [
Expanded(child: _radarCell('НЕДЕЛЯ', '${d.thisWeek}/7',
d.pWorkouts, _HeroAccents.amber, r)),
SizedBox(width: r.s(8)),
Expanded(child: _radarCell('ККАЛ', '${d.kcal}',
d.pCalories, _Vibrant.neonGreen, r)),
],
),
SizedBox(height: r.s(8)),
Row(
children: [
Expanded(child: _radarCell(
'ТРЕН.', '${(d.pWorkouts * 100).round()}%',
d.pWorkouts, _HeroAccents.pink, r)),
SizedBox(width: r.s(8)),
Expanded(child: _radarCell('СЕРИЯ', '${d.streak} д',
d.pStreak, _HeroAccents.sky, r)),
],
),
SizedBox(height: r.s(12)),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
_radarKey(Icons.shopping_cart_rounded, 'МАРКЕТ',
widget.onShopping, r),
SizedBox(width: r.s(10)),
_radarKey(Icons.kitchen_rounded, 'СКЛАД',
widget.onPantry, r),
SizedBox(width: r.s(10)),
_radarKey(Icons.tune_rounded, 'СИСТЕМА',
widget.onSettings, r),
],
),
],
),
r,
),
),
),
],
),
);
}

// ═══ СТИЛЬ 7 — СИЯНИЕ ═══
Widget _aurora(_HeroData d) {
final r = _R(context);
final name = widget.profileName.isEmpty ? 'атлет' : widget.profileName;
return ClipRRect(
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48),
),
child: Stack(
children: [
..._bgLayers(),
const Positioned.fill(
child: IgnorePointer(child: _AuroraLayer()),
),
SafeArea(
bottom: false, left: false, right: false,
child: Padding(
padding: EdgeInsets.fromLTRB(r.s(22), r.s(8), r.s(22), r.s(20)),
child: _cap(
Column(
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text('${_greeting()},',
style: GoogleFonts.playfairDisplay(
color: Colors.white.withOpacity(0.75),
fontSize: r.fs(15),
fontStyle: FontStyle.italic,
)),
Text(name,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.playfairDisplay(
color: Colors.white, fontSize: r.fs(30),
fontWeight: FontWeight.w600, height: 1.05,
)),
],
),
),
_heroIconBtn(Icons.shopping_cart_rounded,
widget.onShopping, r, size: 38),
SizedBox(width: r.s(6)),
_heroIconBtn(Icons.kitchen_rounded,
widget.onPantry, r, size: 38),
SizedBox(width: r.s(6)),
_heroIconBtn(Icons.tune_rounded,
widget.onSettings, r, size: 38),
],
),
SizedBox(height: r.s(12)),
_Breathing(child: _coin(r.s(250), d)),
SizedBox(height: r.s(16)),
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
_auroraPill(Icons.star_rounded, 'Lv ${d.level}',
'уровень', _Vibrant.goldMid, r),
Transform.translate(
offset: Offset(0, r.s(10)),
child: _auroraPill(Icons.calendar_view_week_rounded,
'${d.thisWeek}/7', 'неделя', _HeroAccents.amber, r),
),
],
),
SizedBox(height: r.s(10)),
Center(
child: _auroraPill(Icons.local_fire_department_rounded,
'${d.kcal}', 'ккал', _Aurora.teal, r),
),
SizedBox(height: r.s(10)),
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Transform.translate(
offset: Offset(0, -r.s(4)),
child: _auroraPill(Icons.fitness_center_rounded,
'${(d.pWorkouts * 100).round()}%', 'трен.',
_Aurora.pink, r),
),
Transform.translate(
offset: Offset(0, r.s(6)),
child: _auroraPill(Icons.bolt_rounded,
'${d.streak} д', 'серия', _Aurora.violet, r),
),
],
),
],
),
r,
),
),
),
],
),
);
}

// ═══ СТИЛЬ 8 — ТАХО ═══
Widget _tacho(_HeroData d) {
final r = _R(context);
final ready = d.pWorkouts >= 1.0;
return ClipRRect(
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48),
),
child: Stack(
children: [
..._bgLayers(),
SafeArea(
bottom: false, left: false, right: false,
child: Padding(
padding: EdgeInsets.fromLTRB(r.s(20), r.s(6), r.s(20), r.s(18)),
child: _cap(
Column(
children: [
Row(
children: [
_tachoLamp(ready ? 'WEEK READY' : 'WARMING UP',
ready ? _Vibrant.neonGreen : _HeroAccents.amber, r),
const Spacer(),
_tachoLamp('GEAR ${d.level}', _HeroAccents.peach, r),
],
),
SizedBox(height: r.s(10)),
TweenAnimationBuilder<double>(
tween: Tween(begin: 0.0, end: d.pWorkouts),
duration: const Duration(milliseconds: 1400),
curve: Curves.easeOutCubic,
builder: (_, v, __) => _TachoBezel(
size: r.s(300),
progress: v,
child: _coin(r.s(238), d),
),
),
SizedBox(height: r.s(14)),
Container(
padding: EdgeInsets.symmetric(
horizontal: r.s(16), vertical: r.s(13)),
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
Colors.black.withOpacity(0.55),
Colors.black.withOpacity(0.32),
],
),
borderRadius: BorderRadius.circular(r.s(18)),
border: Border.all(
color: Colors.white.withOpacity(0.14)),
),
child: Row(
children: [
Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text('ККАЛ',
style: GoogleFonts.jetBrainsMono(
color: Colors.white.withOpacity(0.5),
fontSize: r.fs(8), letterSpacing: 1.5,
fontWeight: FontWeight.w700,
)),
SizedBox(height: r.s(4)),
_Odometer(value: d.kcal, scale: r.scale),
],
),
const Spacer(),
_tachoReadout('СЕРИЯ', '${d.streak} д',
_HeroAccents.sky, r),
SizedBox(width: r.s(12)),
Container(width: 1, height: r.s(34),
color: Colors.white.withOpacity(0.12)),
SizedBox(width: r.s(12)),
_tachoReadout('НЕДЕЛЯ', '${d.thisWeek}/7',
_HeroAccents.amber, r),
],
),
),
SizedBox(height: r.s(14)),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
_tachoBtn(Icons.shopping_cart_rounded,
widget.onShopping, r),
SizedBox(width: r.s(14)),
_tachoBtn(Icons.kitchen_rounded,
widget.onPantry, r),
SizedBox(width: r.s(14)),
_tachoBtn(Icons.tune_rounded,
widget.onSettings, r),
],
),
],
),
r,
),
),
),
],
),
);
}

// ═══ СТИЛЬ 9 — ПОП-АРТ ═══
Widget _pop(_HeroData d) {
final r = _R(context);
return ClipRRect(
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48),
),
child: Stack(
children: [
..._bgLayers(),
Positioned.fill(
child: IgnorePointer(
child: CustomPaint(painter: _HalftonePainter()),
),
),
SafeArea(
bottom: false, left: false, right: false,
child: Padding(
padding: EdgeInsets.fromLTRB(r.s(20), r.s(8), r.s(20), r.s(20)),
child: _cap(
Column(
children: [
Row(
children: [
Transform.rotate(
angle: -0.035,
child: Container(
padding: EdgeInsets.symmetric(
horizontal: r.s(10), vertical: r.s(8)),
decoration: BoxDecoration(
color: _Pop.yellow,
borderRadius: BorderRadius.circular(r.s(10)),
border: Border.all(color: _Pop.ink, width: 2.5),
boxShadow: const [
BoxShadow(
color: _Pop.ink,
offset: Offset(3, 3), blurRadius: 0),
],
),
child: Text('${_greeting().toUpperCase()}!',
style: GoogleFonts.archivoBlack(
color: _Pop.ink, fontSize: r.fs(12),
height: 1,
)),
),
),
const Spacer(),
_popBtn(Icons.shopping_cart_rounded,
widget.onShopping, _Pop.blue, r),
SizedBox(width: r.s(8)),
_popBtn(Icons.kitchen_rounded,
widget.onPantry, _Pop.magenta, r),
SizedBox(width: r.s(8)),
_popBtn(Icons.tune_rounded,
widget.onSettings, _Pop.green, r),
],
),
SizedBox(height: r.s(16)),
Stack(
clipBehavior: Clip.none,
children: [
Center(
child: Container(
padding: EdgeInsets.all(r.s(7)),
decoration: BoxDecoration(
color: Colors.white,
shape: BoxShape.circle,
border: Border.all(color: _Pop.ink, width: 3),
boxShadow: const [
BoxShadow(
color: _Pop.ink,
offset: Offset(5, 6), blurRadius: 0),
],
),
child: _coin(r.s(236), d),
),
),
Positioned(
left: r.s(2), top: -r.s(22),
child: _PopStar(level: d.level, size: r.s(62)),
),
],
),
SizedBox(height: r.s(18)),
SizedBox(
height: r.s(128),
child: Stack(
clipBehavior: Clip.none,
children: [
Positioned(
left: 0, top: 0,
child: _popSticker(
Icons.calendar_view_week_rounded, 'НЕДЕЛЯ',
'${d.thisWeek}/7', _Pop.yellow, -0.07, r),
),
Positioned(
right: 0, top: r.s(6),
child: _popSticker(
Icons.local_fire_department_rounded, 'ККАЛ',
'${d.kcal}', _Pop.magenta, 0.06, r),
),
Positioned(
left: r.s(26), top: r.s(60),
child: _popSticker(
Icons.fitness_center_rounded, 'ТРЕН.',
'${(d.pWorkouts * 100).round()}%',
_Pop.blue, 0.045, r),
),
Positioned(
right: r.s(20), top: r.s(66),
child: _popSticker(Icons.bolt_rounded, 'СЕРИЯ',
'${d.streak} д', _Pop.green, -0.06, r),
),
],
),
),
],
),
r,
),
),
),
],
),
);
}

// ═══ СТИЛЬ 10 — ПАРАЛЛАКС ═══
Widget _parallax(_HeroData d) {
final r = _R(context);
return ClipRRect(
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48),
),
child: Stack(
children: [
..._bgLayers(),
SafeArea(
bottom: false, left: false, right: false,
child: Padding(
padding: EdgeInsets.fromLTRB(r.s(20), r.s(8), r.s(20), r.s(20)),
child: _cap(
SizedBox(
height: r.s(444),
child: _ParallaxHero(
d: d,
scale: r.scale,
coin: _coin(r.s(240), d),
coinSize: r.s(240),
name: widget.profileName.isEmpty
? 'атлет' : widget.profileName,
onCart: widget.onShopping,
onPantry: widget.onPantry,
onSettings: widget.onSettings,
),
),
r,
),
),
),
],
),
);
}
}

// ═══════════════════════════════════════════════════════════════════
//  HERO — ОБЩИЕ КИРПИЧИКИ
// ═══════════════════════════════════════════════════════════════════

Widget _heroIconBtn(IconData icon, VoidCallback onTap, _R r,
{double size = 46}) {
return _TapScale(
onTap: onTap,
child: Container(
width: r.s(size),
height: r.s(size),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.17),
shape: BoxShape.circle,
border: Border.all(
color: Colors.white.withOpacity(0.30),
width: 1,
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.16),
blurRadius: 16,
offset: const Offset(0, 5),
),
BoxShadow(
color: Colors.white.withOpacity(0.08),
blurRadius: 1,
offset: const Offset(0, -1),
),
],
),
child: Icon(icon, color: Colors.white, size: r.s(19)),
),
);
}


Widget _heroGlassPill(_R r, List<(IconData, VoidCallback)> items) {
return Container(
height: r.s(46),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.16),
borderRadius: BorderRadius.circular(100),
border: Border.all(color: Colors.white.withOpacity(0.28)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.16),
blurRadius: 18,
offset: const Offset(0, 5),
),
],
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
for (int i = 0; i < items.length; i++) ...[
if (i > 0)
Container(
width: 1,
height: r.s(19),
color: Colors.white.withOpacity(0.22),
),
_TapScale(
onTap: items[i].$2,
child: Padding(
padding: EdgeInsets.symmetric(
horizontal: r.s(16),
vertical: r.s(12),
),
child: Icon(
items[i].$1,
color: Colors.white,
size: r.s(19),
),
),
),
],
],
),
);
}


Widget _heroMiniBar(double v, Color c, _R r, {double h = 4}) {
final progress = v.clamp(0.0, 1.0).toDouble();
return ClipRRect(
borderRadius: BorderRadius.circular(100),
child: SizedBox(
height: r.s(h),
child: LayoutBuilder(
builder: (_, constraints) => Stack(
fit: StackFit.expand,
children: [
DecoratedBox(
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.14),
borderRadius: BorderRadius.circular(100),
),
),
Align(
alignment: Alignment.centerLeft,
child: FractionallySizedBox(
widthFactor: progress,
heightFactor: 1,
child: DecoratedBox(
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
c.withOpacity(0.72),
c,
Color.lerp(c, Colors.white, 0.28)!,
],
),
borderRadius: BorderRadius.circular(100),
boxShadow: [
BoxShadow(
color: c.withOpacity(0.45),
blurRadius: 7,
spreadRadius: -1,
),
],
),
),
),
),
if (progress > 0.03)
Align(
alignment: Alignment.centerLeft,
child: FractionallySizedBox(
widthFactor: progress,
child: Align(
alignment: Alignment.centerRight,
child: Container(
width: r.s(3),
height: r.s(h + 1),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.88),
borderRadius: BorderRadius.circular(100),
),
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

Widget _heroLegendChip(Color color, String label, String value, _R r) {
return Container(
padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(4)),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.12),
borderRadius: BorderRadius.circular(100),
border: Border.all(color: Colors.white.withOpacity(0.15)),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Container(width: 6, height: 6,
decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
SizedBox(width: r.s(5)),
Text(label,
style: TextStyle(
color: Colors.white.withOpacity(0.8),
fontSize: r.fs(10), fontWeight: FontWeight.w500,
)),
SizedBox(width: r.s(3)),
Text(value,
style: TextStyle(
color: Colors.white, fontSize: r.fs(11),
fontWeight: FontWeight.w700,
)),
],
),
);
}


Widget _heroDeckBar(_HeroData d, _R r) {
final items = [
(Icons.star_rounded, _Vibrant.goldMid, 'Lv ${d.level}', 'Уровень',
d.levelProgress),
(Icons.calendar_view_week_rounded, _HeroAccents.amber,
'${d.thisWeek}/7', 'Неделя', d.pWorkouts),
(Icons.local_fire_department_rounded, _HeroAccents.sage,
'${d.kcal}', 'Ккал', d.pCalories),
(Icons.fitness_center_rounded, _HeroAccents.pink,
'${(d.pWorkouts * 100).round()}%', 'Трен.', d.pWorkouts),
(Icons.bolt_rounded, _HeroAccents.sky,
'${d.streak} д', 'Серия', d.pStreak),
];

return Container(
padding: EdgeInsets.fromLTRB(r.s(8), r.s(12), r.s(8), r.s(11)),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.30),
borderRadius: BorderRadius.circular(r.s(22)),
border: Border.all(color: Colors.white.withOpacity(0.19)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.12),
blurRadius: 22,
offset: const Offset(0, 8),
),
],
),
child: Row(
children: [
for (int i = 0; i < items.length; i++) ...[
if (i > 0)
Container(
width: 1,
height: r.s(48),
margin: EdgeInsets.symmetric(horizontal: r.s(2)),
color: Colors.white.withOpacity(0.12),
),
Expanded(
child: Padding(
padding: EdgeInsets.symmetric(horizontal: r.s(3)),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(items[i].$1, color: items[i].$2, size: r.s(14)),
SizedBox(height: r.s(5)),
FittedBox(
fit: BoxFit.scaleDown,
child: Text(
items[i].$3,
style: GoogleFonts.inter(
color: Colors.white,
fontSize: r.fs(12),
fontWeight: FontWeight.w800,
letterSpacing: -0.2,
fontFeatures: const [FontFeature.tabularFigures()],
),
),
),
SizedBox(height: r.s(3)),
Text(
items[i].$4,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.62),
fontSize: r.fs(8),
fontWeight: FontWeight.w600,
),
),
SizedBox(height: r.s(7)),
_heroMiniBar(items[i].$5, items[i].$2, r, h: 3.5),
],
),
),
),
],
],
),
);
}

Widget _heroCockpitTile({
required IconData icon, required Color color,
required String value, required String label,
required double frac, required _R r,
}) {
return Container(
width: double.infinity,
padding: EdgeInsets.symmetric(vertical: r.s(10), horizontal: r.s(8)),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.32),
borderRadius: BorderRadius.circular(r.s(16)),
border: Border.all(color: Colors.white.withOpacity(0.12)),
),
child: Column(
children: [
Icon(icon, color: color, size: r.s(14)),
SizedBox(height: r.s(5)),
FittedBox(
fit: BoxFit.scaleDown,
child: Text(value,
style: GoogleFonts.inter(
color: Colors.white, fontSize: r.fs(15),
fontWeight: FontWeight.w800,
fontFeatures: const [FontFeature.tabularFigures()],
)),
),
SizedBox(height: r.s(2)),
Text(label,
maxLines: 1, overflow: TextOverflow.ellipsis,
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.6),
fontSize: r.fs(8.5), fontWeight: FontWeight.w600,
)),
SizedBox(height: r.s(6)),
_heroMiniBar(frac, color, r),
],
),
);
}

Widget _heroSplitCard(_HeroData d, _R r) {
final rows = [
('Неделя', '${d.thisWeek}/7', d.pWorkouts, _HeroAccents.amber),
('Ккал', '${d.kcal}', d.pCalories, _HeroAccents.sage),
('Трен.', '${(d.pWorkouts * 100).round()}%', d.pWorkouts, _HeroAccents.pink),
('Серия', '${d.streak} д', d.pStreak, _HeroAccents.sky),
];
return Container(
padding: EdgeInsets.all(r.s(14)),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.32),
borderRadius: BorderRadius.circular(r.s(20)),
border: Border.all(color: Colors.white.withOpacity(0.12)),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
for (int i = 0; i < rows.length; i++) ...[
if (i > 0) SizedBox(height: r.s(11)),
Row(
children: [
Container(width: r.s(7), height: r.s(7),
decoration: BoxDecoration(
color: rows[i].$4, shape: BoxShape.circle)),
SizedBox(width: r.s(6)),
Text(rows[i].$1,
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.75),
fontSize: r.fs(11), fontWeight: FontWeight.w600,
)),
const Spacer(),
Flexible(
child: FittedBox(
fit: BoxFit.scaleDown,
child: Text(rows[i].$2,
style: GoogleFonts.inter(
color: Colors.white, fontSize: r.fs(12),
fontWeight: FontWeight.w800,
fontFeatures: const [FontFeature.tabularFigures()],
)),
),
),
],
),
SizedBox(height: r.s(5)),
_heroMiniBar(rows[i].$3, rows[i].$4, r),
],
],
),
);
}

Widget _heroDockCard(_HeroData d, _R r) {
final items = [
(Icons.star_rounded, _Vibrant.goldMid, 'Lv ${d.level}', 'Уровень',
d.levelProgress),
(Icons.calendar_view_week_rounded, _HeroAccents.amber,
'${d.thisWeek}/7', 'Неделя', d.pWorkouts),
(Icons.local_fire_department_rounded, _Palette.green,
'${d.kcal}', 'Ккал', d.pCalories),
(Icons.fitness_center_rounded, _HeroAccents.pink,
'${(d.pWorkouts * 100).round()}%', 'Трен.', d.pWorkouts),
(Icons.bolt_rounded, _HeroAccents.sky, '${d.streak} д', 'Серия', d.pStreak),
];
return Container(
padding: EdgeInsets.symmetric(vertical: r.s(14), horizontal: r.s(8)),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.97),
borderRadius: BorderRadius.circular(r.s(24)),
border: Border.all(color: Colors.white),
boxShadow: [
BoxShadow(
color: _Palette.green.withOpacity(0.18),
blurRadius: 24, spreadRadius: -6, offset: const Offset(0, 10),
),
BoxShadow(
color: Colors.black.withOpacity(0.08),
blurRadius: 12, offset: const Offset(0, 4),
),
],
),
child: Row(
children: items.map((it) {
return Expanded(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
SizedBox(
width: r.s(30), height: r.s(30),
child: Stack(
alignment: Alignment.center,
children: [
SizedBox.expand(
child: CircularProgressIndicator(
value: it.$5.clamp(0.0, 1.0),
strokeWidth: r.s(3),
backgroundColor: _Palette.divider,
valueColor: AlwaysStoppedAnimation(it.$2),
),
),
Icon(it.$1, size: r.s(12), color: it.$2),
],
),
),
SizedBox(height: r.s(6)),
FittedBox(
fit: BoxFit.scaleDown,
child: Text(it.$3,
style: GoogleFonts.inter(
color: _Palette.text, fontSize: r.fs(12),
fontWeight: FontWeight.w800,
fontFeatures: const [FontFeature.tabularFigures()],
)),
),
SizedBox(height: r.s(2)),
Text(it.$4,
style: GoogleFonts.inter(
color: _Palette.textMuted, fontSize: r.fs(8.5),
fontWeight: FontWeight.w600,
)),
],
),
);
}).toList(),
),
);
}

// ═══════════════════════════════════════════════════════════════════
//  КНОПКА-ВЕЕР (стиль 5)
// ═══════════════════════════════════════════════════════════════════
class _HeroSpeedDial extends StatefulWidget {
final _R r;
final VoidCallback onCart, onPantry, onSettings;
const _HeroSpeedDial({
required this.r, required this.onCart,
required this.onPantry, required this.onSettings,
});
@override
State<_HeroSpeedDial> createState() => _HeroSpeedDialState();
}

class _HeroSpeedDialState extends State<_HeroSpeedDial> {
bool _open = false;

void _fire(VoidCallback action) {
setState(() => _open = false);
action();
}

@override
Widget build(BuildContext context) {
final r = widget.r;
return Row(
mainAxisSize: MainAxisSize.min,
children: [
AnimatedSize(
duration: const Duration(milliseconds: 280),
curve: Curves.easeOutCubic,
alignment: Alignment.centerRight,
child: _open
? Row(
mainAxisSize: MainAxisSize.min,
children: [
_heroIconBtn(Icons.shopping_cart_rounded,
() => _fire(widget.onCart), r, size: 44),
SizedBox(width: r.s(8)),
_heroIconBtn(Icons.kitchen_rounded,
() => _fire(widget.onPantry), r, size: 44),
SizedBox(width: r.s(8)),
_heroIconBtn(Icons.tune_rounded,
() => _fire(widget.onSettings), r, size: 44),
SizedBox(width: r.s(8)),
],
)
    : const SizedBox.shrink(),
),
_TapScale(
onTap: () {
HapticFeedback.selectionClick();
setState(() => _open = !_open);
},
child: Container(
width: r.s(46), height: r.s(46),
decoration: BoxDecoration(
color: _open
? _Hero.accent.withOpacity(0.85)
    : Colors.white.withOpacity(0.15),
shape: BoxShape.circle,
border: Border.all(
color: Colors.white.withOpacity(0.25), width: 1),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.15), blurRadius: 10),
],
),
child: AnimatedSwitcher(
duration: const Duration(milliseconds: 200),
child: Icon(
_open ? Icons.close_rounded : Icons.more_horiz_rounded,
key: ValueKey(_open),
color: Colors.white, size: r.s(22),
),
),
),
),
],
);
}
}

// ═══════════════════════════════════════════════════════════════════
//  КАРУСЕЛЬ МЕТРИК (стиль 5)
// ═══════════════════════════════════════════════════════════════════
class _HeroMetricCarousel extends StatefulWidget {
final _HeroData d;
final double scale;
const _HeroMetricCarousel({required this.d, required this.scale});
@override
State<_HeroMetricCarousel> createState() => _HeroMetricCarouselState();
}

class _HeroMetricCarouselState extends State<_HeroMetricCarousel> {
late final PageController _pc =
PageController(viewportFraction: 0.44, initialPage: 1);
int _page = 1;

@override
void dispose() {
_pc.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final s = widget.scale;
final d = widget.d;
final items = [
(Icons.star_rounded, _Vibrant.goldMid, 'Lv ${d.level}',
'Уровень', d.levelProgress),
(Icons.calendar_view_week_rounded, _HeroAccents.amber,
'${d.thisWeek}/7', 'Тренировок', d.pWorkouts),
(Icons.local_fire_department_rounded, _HeroAccents.sage,
'${d.kcal}', 'из ${d.kcalGoal} ккал', d.pCalories),
(Icons.fitness_center_rounded, _HeroAccents.pink,
'${(d.pWorkouts * 100).round()}%', 'Готовность недели', d.pWorkouts),
(Icons.bolt_rounded, _HeroAccents.sky, '${d.streak} д', 'Серия', d.pStreak),
];
return Column(
children: [
SizedBox(
height: 118 * s,
child: PageView.builder(
controller: _pc,
physics: const BouncingScrollPhysics(),
itemCount: items.length,
onPageChanged: (i) {
HapticFeedback.selectionClick();
setState(() => _page = i);
},
itemBuilder: (_, i) {
final it = items[i];
final active = i == _page;
return Padding(
padding: EdgeInsets.symmetric(horizontal: 5 * s),
child: AnimatedScale(
scale: active ? 1.0 : 0.92,
duration: const Duration(milliseconds: 220),
curve: Curves.easeOutCubic,
child: AnimatedOpacity(
opacity: active ? 1.0 : 0.72,
duration: const Duration(milliseconds: 220),
child: AnimatedContainer(
duration: const Duration(milliseconds: 220),
padding: EdgeInsets.all(14 * s),
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
it.$2.withOpacity(active ? 0.34 : 0.20),
Colors.black.withOpacity(0.38),
],
),
borderRadius: BorderRadius.circular(20 * s),
border: Border.all(
color: active
? it.$2.withOpacity(0.55)
    : Colors.white.withOpacity(0.14),
width: active ? 1.4 : 1,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(it.$1, color: it.$2, size: 16 * s),
const Spacer(),
FittedBox(
fit: BoxFit.scaleDown,
child: Text(it.$3,
style: GoogleFonts.inter(
color: Colors.white, fontSize: 24 * s,
fontWeight: FontWeight.w800,
letterSpacing: -0.8, height: 1,
fontFeatures: const [FontFeature.tabularFigures()],
)),
),
SizedBox(height: 3 * s),
Text(it.$4,
maxLines: 1, overflow: TextOverflow.ellipsis,
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.7),
fontSize: 10 * s, fontWeight: FontWeight.w600,
)),
SizedBox(height: 8 * s),
ClipRRect(
borderRadius: BorderRadius.circular(100),
child: LinearProgressIndicator(
value: it.$5.clamp(0.0, 1.0),
minHeight: 4 * s,
backgroundColor: Colors.white.withOpacity(0.14),
valueColor: AlwaysStoppedAnimation(it.$2),
),
),
],
),
),
),
),
);
},
),
),
SizedBox(height: 10 * s),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: List.generate(items.length, (i) {
final active = i == _page;
return GestureDetector(
onTap: () => _pc.animateToPage(i,
duration: const Duration(milliseconds: 300),
curve: Curves.easeOutCubic),
child: AnimatedContainer(
duration: const Duration(milliseconds: 220),
margin: EdgeInsets.symmetric(horizontal: 2.5 * s),
width: (active ? 18 : 6) * s,
height: 6 * s,
decoration: BoxDecoration(
color: active ? items[i].$2 : Colors.white.withOpacity(0.25),
borderRadius: BorderRadius.circular(100),
),
),
);
}),
),
],
);
}
}

// ═══════════════════════════════════════════════════════════════════
//  СТИЛЬ 6 — РАДАР
// ═══════════════════════════════════════════════════════════════════
class _RadarStatusChip extends StatefulWidget {
final int level;
final double scale;
const _RadarStatusChip({required this.level, required this.scale});
@override
State<_RadarStatusChip> createState() => _RadarStatusChipState();
}

class _RadarStatusChipState extends State<_RadarStatusChip>
with SingleTickerProviderStateMixin {
late final AnimationController _pulse = AnimationController(
vsync: this, duration: const Duration(milliseconds: 1500),
)..repeat(reverse: true);

@override
void dispose() {
_pulse.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final s = widget.scale;
return Container(
padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 6 * s),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.35),
borderRadius: BorderRadius.circular(8 * s),
border: Border.all(color: _Vibrant.neonGreen.withOpacity(0.35)),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
AnimatedBuilder(
animation: _pulse,
builder: (_, __) {
final v = _pulse.value;
return Container(
width: 7 * s, height: 7 * s,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: _Vibrant.neonGreen.withOpacity(0.5 + 0.5 * v),
boxShadow: [
BoxShadow(
color: _Vibrant.neonGreen.withOpacity(0.6 * v),
blurRadius: 8, spreadRadius: 1,
),
],
),
);
},
),
SizedBox(width: 7 * s),
Text('LV ${widget.level} · ONLINE',
style: GoogleFonts.jetBrainsMono(
color: _Vibrant.neonGreen, fontSize: 9.5 * s,
fontWeight: FontWeight.w700, letterSpacing: 1.2,
)),
],
),
);
}
}

class _RadarScope extends StatefulWidget {
final double size, coinSize;
final List<bool> daysActive;
final Widget child;
const _RadarScope({
required this.size, required this.coinSize,
required this.daysActive, required this.child,
});
@override
State<_RadarScope> createState() => _RadarScopeState();
}

class _RadarScopeState extends State<_RadarScope>
with SingleTickerProviderStateMixin {
late final AnimationController _sweep = AnimationController(
vsync: this, duration: const Duration(seconds: 4),
)..repeat();

@override
void dispose() {
_sweep.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
Widget bracket({bool left = true, bool top = true}) {
final c = _Vibrant.neonGreen.withOpacity(0.7);
return Container(
width: 16, height: 16,
decoration: BoxDecoration(
border: Border(
top: top ? BorderSide(color: c, width: 1.5) : BorderSide.none,
bottom: !top ? BorderSide(color: c, width: 1.5) : BorderSide.none,
left: left ? BorderSide(color: c, width: 1.5) : BorderSide.none,
right: !left ? BorderSide(color: c, width: 1.5) : BorderSide.none,
),
),
);
}

return SizedBox(
width: widget.size, height: widget.size,
child: AnimatedBuilder(
animation: _sweep,
builder: (_, __) => Stack(
alignment: Alignment.center,
children: [
Positioned.fill(
child: CustomPaint(
painter: _RadarHudPainter(
t: _sweep.value,
daysActive: widget.daysActive,
coinSize: widget.coinSize,
),
),
),
widget.child,
Positioned(left: 0, top: 0, child: bracket()),
Positioned(right: 0, top: 0, child: bracket(left: false)),
Positioned(left: 0, bottom: 0, child: bracket(top: false)),
Positioned(right: 0, bottom: 0,
child: bracket(left: false, top: false)),
],
),
),
);
}
}

class _RadarHudPainter extends CustomPainter {
final double t, coinSize;
final List<bool> daysActive;
_RadarHudPainter({
required this.t, required this.daysActive, required this.coinSize,
});

@override
void paint(Canvas canvas, Size size) {
final center = Offset(size.width / 2, size.height / 2);
final outerR = size.width / 2 - 1;
const green = _Vibrant.neonGreen;

final gridPaint = Paint()
..style = PaintingStyle.stroke
..strokeWidth = 0.7
..color = green.withOpacity(0.14);
for (final f in [144, 108, 82, 56]) {
canvas.drawCircle(center, coinSize * (f / 340.0), gridPaint);
}
canvas.drawLine(Offset(center.dx - outerR, center.dy),
Offset(center.dx + outerR, center.dy), gridPaint);
canvas.drawLine(Offset(center.dx, center.dy - outerR),
Offset(center.dx, center.dy + outerR), gridPaint);

final a = t * 2 * math.pi - math.pi / 2;
final rect = Rect.fromCircle(center: center, radius: outerR);
canvas.drawCircle(
center, outerR,
Paint()
..shader = SweepGradient(
colors: [green.withOpacity(0.30), green.withOpacity(0.0)],
stops: const [0.0, 0.22],
transform: GradientRotation(a),
).createShader(rect),
);
final edge = Offset(center.dx + math.cos(a) * outerR,
center.dy + math.sin(a) * outerR);
canvas.drawLine(center, edge, Paint()
..color = green.withOpacity(0.85)
..strokeWidth = 1.4
..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

final blipR = coinSize * (108 / 340.0);
for (int i = 0; i < 7; i++) {
if (i >= daysActive.length || !daysActive[i]) continue;
final ba = -math.pi / 2 + (i / 7.0 + 1.0 / 14.0) * 2 * math.pi;
double delta = (a - ba) % (2 * math.pi);
if (delta < 0) delta += 2 * math.pi;
final flash = delta < 1.1 ? (1 - delta / 1.1) : 0.0;
final pos = Offset(center.dx + math.cos(ba) * blipR,
center.dy + math.sin(ba) * blipR);
canvas.drawCircle(pos, 4 + 4 * flash, Paint()
..color = green.withOpacity(0.25 + 0.45 * flash)
..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
canvas.drawCircle(pos, 2.4, Paint()
..color = green.withOpacity(0.45 + 0.55 * flash));
}
}

@override
bool shouldRepaint(covariant _RadarHudPainter old) =>
old.t != t || !_sameDaysList(old.daysActive, daysActive);
}

Widget _radarCell(String label, String value, double frac, Color color, _R r) {
final filled = (frac.clamp(0.0, 1.0) * 5).round();
return Container(
padding: EdgeInsets.all(r.s(10)),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.35),
borderRadius: BorderRadius.circular(r.s(12)),
border: Border.all(color: color.withOpacity(0.3)),
),
child: Row(
children: [
Container(width: 3, height: r.s(36),
decoration: BoxDecoration(
color: color, borderRadius: BorderRadius.circular(2),
)),
SizedBox(width: r.s(9)),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(label,
style: GoogleFonts.jetBrainsMono(
color: color.withOpacity(0.85), fontSize: r.fs(8.5),
fontWeight: FontWeight.w700, letterSpacing: 1.2,
)),
SizedBox(height: r.s(4)),
Row(
children: [
Expanded(
child: FittedBox(
fit: BoxFit.scaleDown,
alignment: Alignment.centerLeft,
child: Text(value,
style: GoogleFonts.jetBrainsMono(
color: Colors.white, fontSize: r.fs(16),
fontWeight: FontWeight.w800,
fontFeatures: const [FontFeature.tabularFigures()],
)),
),
),
Row(
crossAxisAlignment: CrossAxisAlignment.end,
children: List.generate(5, (i) => Container(
width: 3, height: 5 + i * 2.5,
margin: const EdgeInsets.only(left: 2),
decoration: BoxDecoration(
color: i < filled
? color : Colors.white.withOpacity(0.15),
borderRadius: BorderRadius.circular(1),
),
)),
),
],
),
],
),
),
],
),
);
}

Widget _radarKey(IconData icon, String label, VoidCallback onTap, _R r) {
return _TapScale(
onTap: onTap,
child: Container(
width: r.s(92),
padding: EdgeInsets.symmetric(vertical: r.s(10)),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.35),
borderRadius: BorderRadius.circular(r.s(12)),
border: Border.all(color: Colors.white.withOpacity(0.18)),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, color: Colors.white, size: r.s(18)),
SizedBox(height: r.s(5)),
Text(label,
style: GoogleFonts.jetBrainsMono(
color: Colors.white.withOpacity(0.7), fontSize: r.fs(8),
fontWeight: FontWeight.w700, letterSpacing: 1,
)),
],
),
),
);
}

// ═══════════════════════════════════════════════════════════════════
//  СТИЛЬ 7 — СИЯНИЕ
// ═══════════════════════════════════════════════════════════════════
class _Aurora {
static const green = Color(0xFF46E5A3);
static const teal = Color(0xFF3ED6D0);
static const violet = Color(0xFF8B7BFF);
static const pink = Color(0xFFFF7BD5);
}

class _AuroraLayer extends StatefulWidget {
const _AuroraLayer();
@override
State<_AuroraLayer> createState() => _AuroraLayerState();
}

class _AuroraLayerState extends State<_AuroraLayer>
with SingleTickerProviderStateMixin {
late final AnimationController _c = AnimationController(
vsync: this, duration: const Duration(seconds: 16),
)..repeat();

@override
void dispose() {
_c.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return AnimatedBuilder(
animation: _c,
builder: (_, __) {
final ph = _c.value * 2 * math.pi;
Widget ribbon(double base, double amp, double freq, double thick,
Color c0, Color c1, double seed, double dx, double dy) {
return Positioned.fill(
child: Transform.translate(
offset: Offset(math.sin(ph + seed) * dx,
math.cos(ph * 0.7 + seed) * dy),
child: CustomPaint(
painter: _AuroraRibbonPainter(
baseFrac: base, amp: amp, freq: freq, thick: thick,
c0: c0, c1: c1, seed: seed,
),
),
),
);
}

return Stack(
children: [
Positioned.fill(
child: Opacity(
opacity: 0.55 + 0.35 * (0.5 + 0.5 * math.sin(ph * 2)),
child: CustomPaint(painter: _AuroraStarsPainter()),
),
),
ribbon(0.16, 20, 2.1, 46, _Aurora.teal, _Aurora.green, 4.2, 14, 5),
ribbon(0.26, 28, 1.5, 64, _Aurora.green, _Aurora.teal, 0.0, 20, 7),
ribbon(0.38, 34, 1.1, 82, _Aurora.violet, _Aurora.pink, 2.1, 26, 9),
],
);
},
);
}
}

class _AuroraRibbonPainter extends CustomPainter {
final double baseFrac, amp, freq, thick, seed;
final Color c0, c1;
_AuroraRibbonPainter({
required this.baseFrac, required this.amp, required this.freq,
required this.thick, required this.c0, required this.c1,
required this.seed,
});

@override
void paint(Canvas canvas, Size size) {
final w = size.width, h = size.height;
final baseY = h * baseFrac;
double topAt(double x) =>
baseY +
math.sin(x / w * freq * 2 * math.pi + seed) * amp +
math.sin(x / w * freq * 4 * math.pi + seed * 1.7) * amp * 0.3;
double botAt(double x) =>
topAt(x) + thick * (0.6 + 0.4 * math.sin(x / w * 3 * math.pi + seed));

final path = Path()..moveTo(0, topAt(0));
for (double x = 6; x <= w; x += 6) { path.lineTo(x, topAt(x)); }
for (double x = w; x >= 0; x -= 6) { path.lineTo(x, botAt(x)); }
path.close();

canvas.drawPath(
path,
Paint()
..shader = LinearGradient(
begin: Alignment.topCenter, end: Alignment.bottomCenter,
colors: [
c0.withOpacity(0.0), c0.withOpacity(0.30),
c1.withOpacity(0.22), c1.withOpacity(0.0),
],
stops: const [0.0, 0.35, 0.7, 1.0],
).createShader(Rect.fromLTWH(0, baseY - amp, w, thick + amp * 2.4))
..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
);
}

@override
bool shouldRepaint(covariant _AuroraRibbonPainter old) => false;
}

class _AuroraStarsPainter extends CustomPainter {
@override
void paint(Canvas canvas, Size size) {
final rng = math.Random(7);
for (int i = 0; i < 64; i++) {
final x = rng.nextDouble() * size.width;
final y = rng.nextDouble() * size.height * 0.72;
final r = 0.6 + rng.nextDouble() * 1.1;
canvas.drawCircle(Offset(x, y), r,
Paint()..color = Colors.white.withOpacity(0.25 + rng.nextDouble() * 0.5));
}
}

@override
bool shouldRepaint(covariant _AuroraStarsPainter old) => false;
}

class _Breathing extends StatefulWidget {
final Widget child;
const _Breathing({required this.child});
@override
State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
with SingleTickerProviderStateMixin {
late final AnimationController _c = AnimationController(
vsync: this, duration: const Duration(milliseconds: 3400),
)..repeat(reverse: true);

@override
void dispose() {
_c.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return AnimatedBuilder(
animation: _c,
builder: (_, child) {
final v = Curves.easeInOut.transform(_c.value);
return Transform.translate(
offset: Offset(0, -5 * v),
child: Transform.scale(scale: 1 + 0.02 * v, child: child),
);
},
child: widget.child,
);
}
}

Widget _auroraPill(
IconData icon, String value, String label, Color color, _R r) {
return Container(
padding: EdgeInsets.symmetric(horizontal: r.s(14), vertical: r.s(10)),
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft, end: Alignment.bottomRight,
colors: [
Colors.white.withOpacity(0.16),
Colors.white.withOpacity(0.06),
],
),
borderRadius: BorderRadius.circular(100),
border: Border.all(color: color.withOpacity(0.45)),
boxShadow: [
BoxShadow(
color: color.withOpacity(0.22),
blurRadius: 18, spreadRadius: -2, offset: const Offset(0, 6),
),
],
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, color: color, size: r.s(15)),
SizedBox(width: r.s(8)),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(value,
style: GoogleFonts.inter(
color: Colors.white, fontSize: r.fs(15),
fontWeight: FontWeight.w800, height: 1,
fontFeatures: const [FontFeature.tabularFigures()],
)),
SizedBox(height: r.s(2)),
Text(label,
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.6),
fontSize: r.fs(8.5), fontWeight: FontWeight.w600,
letterSpacing: 0.4,
)),
],
),
],
),
);
}

// ═══════════════════════════════════════════════════════════════════
//  СТИЛЬ 8 — ТАХО
// ═══════════════════════════════════════════════════════════════════
class _TachoBezel extends StatelessWidget {
final double size, progress;
final Widget child;
const _TachoBezel({
required this.size, required this.progress, required this.child,
});
@override
Widget build(BuildContext context) {
return SizedBox(
width: size, height: size,
child: Stack(
alignment: Alignment.center,
children: [
Positioned.fill(
child: CustomPaint(painter: _TachoBezelPainter(progress)),
),
child,
],
),
);
}
}

class _TachoBezelPainter extends CustomPainter {
final double progress;
_TachoBezelPainter(this.progress);

@override
void paint(Canvas canvas, Size size) {
final center = Offset(size.width / 2, size.height / 2);
final r = size.width / 2 - 8;
const start = 150 * math.pi / 180;
const sweep = 240 * math.pi / 180;
final rect = Rect.fromCircle(center: center, radius: r);
final p = progress.clamp(0.0, 1.0);

canvas.drawArc(rect, start, sweep, false, Paint()
..style = PaintingStyle.stroke
..strokeWidth = 5..strokeCap = StrokeCap.round
..color = Colors.white.withOpacity(0.12));

canvas.drawArc(rect, start + sweep * (6 / 7), sweep / 7, false, Paint()
..style = PaintingStyle.stroke
..strokeWidth = 5..strokeCap = StrokeCap.round
..color = _Vibrant.vividPeach.withOpacity(0.45));

if (p > 0) {
final col = Color.lerp(_Vibrant.neonGreen, _Vibrant.vividPeach, p)!;
canvas.drawArc(rect, start, sweep * p, false, Paint()
..style = PaintingStyle.stroke
..strokeWidth = 8..strokeCap = StrokeCap.round
..color = col.withOpacity(0.3)
..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
canvas.drawArc(rect, start, sweep * p, false, Paint()
..style = PaintingStyle.stroke
..strokeWidth = 5..strokeCap = StrokeCap.round..color = col);
}

for (int i = 0; i <= 7; i++) {
final a = start + sweep * (i / 7);
final dir = Offset(math.cos(a), math.sin(a));
final p1 = center + dir * (r - 10);
final p2 = center + dir * (r - 2);
canvas.drawLine(p1, p2, Paint()
..color = Colors.white.withOpacity(i / 7 <= p ? 0.95 : 0.4)
..strokeWidth = 1.6..strokeCap = StrokeCap.round);
final tp = TextPainter(
text: TextSpan(
text: '$i',
style: GoogleFonts.jetBrainsMono(
color: i >= 6
? _Vibrant.vividPeach
    : Colors.white.withOpacity(0.75),
fontSize: 9, fontWeight: FontWeight.w800, height: 1,
),
),
textDirection: TextDirection.ltr,
)..layout();
final pos = center + dir * (r - 21);
tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
}

final a = start + sweep * p;
final dir = Offset(math.cos(a), math.sin(a));
final perp = Offset(-dir.dy, dir.dx);
final tip = center + dir * (r + 6);
final b1 = center + dir * (r - 7) + perp * 4.5;
final b2 = center + dir * (r - 7) - perp * 4.5;
canvas.drawPath(Path()..moveTo(tip.dx, tip.dy)
..lineTo(b1.dx, b1.dy)..lineTo(b2.dx, b2.dy)..close(),
Paint()..color = _Vibrant.vividPeach);
canvas.drawCircle(tip, 5, Paint()
..color = _Vibrant.vividPeach.withOpacity(0.5)
..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
}

@override
bool shouldRepaint(covariant _TachoBezelPainter old) =>
old.progress != progress;
}

class _Odometer extends StatelessWidget {
final int value;
final double scale;
const _Odometer({required this.value, required this.scale});
@override
Widget build(BuildContext context) {
return TweenAnimationBuilder<double>(
tween: Tween(begin: 0.0, end: value.toDouble()),
duration: const Duration(milliseconds: 1600),
curve: Curves.easeOutCubic,
builder: (_, anim, __) {
final n = anim.round();
final str = n.toString().padLeft(4, '0');
return Row(
mainAxisSize: MainAxisSize.min,
children: str.split('').map((ch) =>
_OdometerDigit(digit: ch, scale: scale)).toList(),
);
},
);
}
}

class _OdometerDigit extends StatelessWidget {
final String digit;
final double scale;
const _OdometerDigit({required this.digit, required this.scale});
@override
Widget build(BuildContext context) {
return SizedBox(
width: 13 * scale,
child: AnimatedSwitcher(
duration: const Duration(milliseconds: 240),
transitionBuilder: (child, anim) => SlideTransition(
position: Tween(begin: const Offset(0, 0.6), end: Offset.zero)
    .animate(anim),
child: FadeTransition(opacity: anim, child: child),
),
child: Text(
digit,
key: ValueKey(digit),
textAlign: TextAlign.center,
style: GoogleFonts.jetBrainsMono(
color: Colors.white, fontSize: 20 * scale,
fontWeight: FontWeight.w800, height: 1.1,
fontFeatures: const [FontFeature.tabularFigures()],
),
),
),
);
}
}

Widget _tachoLamp(String text, Color color, _R r) {
return Container(
padding: EdgeInsets.symmetric(horizontal: r.s(9), vertical: r.s(6)),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.35),
borderRadius: BorderRadius.circular(r.s(8)),
border: Border.all(color: color.withOpacity(0.4)),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Container(width: 6, height: 6,
decoration: BoxDecoration(
color: color, shape: BoxShape.circle,
boxShadow: [
BoxShadow(color: color.withOpacity(0.7), blurRadius: 6),
],
)),
SizedBox(width: r.s(6)),
Text(text,
style: GoogleFonts.jetBrainsMono(
color: color, fontSize: r.fs(9.5),
fontWeight: FontWeight.w700, letterSpacing: 1.2,
)),
],
),
);
}

Widget _tachoReadout(String label, String value, Color color, _R r) {
return Column(
crossAxisAlignment: CrossAxisAlignment.end,
mainAxisSize: MainAxisSize.min,
children: [
Text(label,
style: GoogleFonts.jetBrainsMono(
color: Colors.white.withOpacity(0.5), fontSize: r.fs(8),
fontWeight: FontWeight.w700, letterSpacing: 1.5,
)),
SizedBox(height: r.s(4)),
Text(value,
style: GoogleFonts.jetBrainsMono(
color: color, fontSize: r.fs(15), fontWeight: FontWeight.w800,
fontFeatures: const [FontFeature.tabularFigures()],
)),
],
);
}

Widget _tachoBtn(IconData icon, VoidCallback onTap, _R r) {
return _TapScale(
onTap: onTap,
child: Container(
width: r.s(52), height: r.s(52),
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: RadialGradient(
center: const Alignment(-0.4, -0.5),
colors: [
Colors.white.withOpacity(0.24),
Colors.black.withOpacity(0.38),
],
),
border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.3),
blurRadius: 12, offset: const Offset(0, 5),
),
],
),
child: Icon(icon, color: _HeroAccents.peach, size: r.s(20)),
),
);
}

// ═══════════════════════════════════════════════════════════════════
//  СТИЛЬ 9 — ПОП-АРТ
// ═══════════════════════════════════════════════════════════════════
class _Pop {
static const ink = Color(0xFF161616);
static const yellow = Color(0xFFFFD93D);
static const magenta = Color(0xFFFF4FA3);
static const blue = Color(0xFF3D8BFF);
static const green = Color(0xFF3DDC84);
}

class _HalftonePainter extends CustomPainter {
@override
void paint(Canvas canvas, Size size) {
final paint = Paint()..color = Colors.white.withOpacity(0.055);
const step = 14.0;
for (double y = 0; y < size.height; y += step) {
for (double x = 0; x < size.width; x += step) {
final r = 1.0 + 1.1 * (0.5 + 0.5 * math.sin((x + y) * 0.02));
canvas.drawCircle(Offset(x, y), r, paint);
}
}
}

@override
bool shouldRepaint(covariant _HalftonePainter old) => false;
}

class _PopStar extends StatelessWidget {
final int level;
final double size;
const _PopStar({required this.level, required this.size});
@override
Widget build(BuildContext context) {
return SizedBox(
width: size, height: size,
child: Stack(
alignment: Alignment.center,
children: [
Positioned.fill(child: CustomPaint(painter: _PopStarPainter())),
Column(
mainAxisSize: MainAxisSize.min,
children: [
Text('LV',
style: GoogleFonts.archivoBlack(
color: _Pop.ink, fontSize: size * 0.14, height: 1)),
Text('$level',
style: GoogleFonts.archivoBlack(
color: _Pop.ink, fontSize: size * 0.26, height: 1)),
],
),
],
),
);
}
}

class _PopStarPainter extends CustomPainter {
@override
void paint(Canvas canvas, Size size) {
final center = Offset(size.width / 2, size.height / 2);
final outerR = size.width / 2 - 3;
final innerR = outerR * 0.74;
Path star(Offset c) {
final p = Path();
for (int i = 0; i < 24; i++) {
final a = -math.pi / 2 + i * math.pi / 12;
final r = i.isEven ? outerR : innerR;
final pt = c + Offset(math.cos(a) * r, math.sin(a) * r);
if (i == 0) {
p.moveTo(pt.dx, pt.dy);
} else {
p.lineTo(pt.dx, pt.dy);
}
}
p.close();
return p;
}
canvas.drawPath(star(center + const Offset(3, 3)),
Paint()..color = _Pop.ink);
canvas.drawPath(star(center), Paint()..color = _Pop.yellow);
canvas.drawPath(star(center), Paint()
..color = _Pop.ink..style = PaintingStyle.stroke..strokeWidth = 2.2);
}

@override
bool shouldRepaint(covariant _PopStarPainter old) => false;
}

Widget _popBtn(IconData icon, VoidCallback onTap, Color color, _R r) {
return _TapScale(
onTap: onTap,
child: Container(
width: r.s(44), height: r.s(44),
decoration: BoxDecoration(
color: color, shape: BoxShape.circle,
border: Border.all(color: _Pop.ink, width: 2.5),
boxShadow: const [
BoxShadow(color: _Pop.ink, offset: Offset(3, 3), blurRadius: 0),
],
),
child: Icon(icon, color: _Pop.ink, size: r.s(19)),
),
);
}

Widget _popSticker(IconData icon, String label, String value,
Color color, double angle, _R r) {
return Transform.rotate(
angle: angle,
child: Container(
padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(10)),
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(r.s(12)),
border: Border.all(color: _Pop.ink, width: 2.5),
boxShadow: const [
BoxShadow(color: _Pop.ink, offset: Offset(4, 4), blurRadius: 0),
],
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, color: _Pop.ink, size: r.s(16)),
SizedBox(width: r.s(7)),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(value,
style: GoogleFonts.archivoBlack(
color: _Pop.ink, fontSize: r.fs(15), height: 1)),
SizedBox(height: r.s(3)),
Text(label,
style: GoogleFonts.inter(
color: _Pop.ink.withOpacity(0.75), fontSize: r.fs(8),
fontWeight: FontWeight.w800, letterSpacing: 0.8,
)),
],
),
],
),
),
);
}

// ═══════════════════════════════════════════════════════════════════
//  СТИЛЬ 10 — ПАРАЛЛАКС
// ═══════════════════════════════════════════════════════════════════
class _ParallaxHero extends StatefulWidget {
final _HeroData d;
final double scale, coinSize;
final Widget coin;
final String name;
final VoidCallback onCart, onPantry, onSettings;
const _ParallaxHero({
required this.d, required this.scale, required this.coinSize,
required this.coin, required this.name,
required this.onCart, required this.onPantry, required this.onSettings,
});
@override
State<_ParallaxHero> createState() => _ParallaxHeroState();
}

class _ParallaxHeroState extends State<_ParallaxHero>
with SingleTickerProviderStateMixin {
Offset _offset = Offset.zero;
bool _dragging = false, _touched = false;
late final AnimationController _drift = AnimationController(
vsync: this, duration: const Duration(seconds: 7),
)..repeat();

@override
void dispose() {
_drift.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final s = widget.scale;
final d = widget.d;
final shardW = 112 * s;
return LayoutBuilder(builder: (_, c) {
final w = c.maxWidth, h = c.maxHeight;
return GestureDetector(
behavior: HitTestBehavior.translucent,
onPanStart: (_) =>
setState(() { _dragging = true; _touched = true; }),
onPanUpdate: (e) => setState(() {
_offset = Offset(
(_offset.dx + e.delta.dx).clamp(-34.0, 34.0),
(_offset.dy + e.delta.dy).clamp(-26.0, 26.0),
);
}),
onPanEnd: (_) =>
setState(() { _dragging = false; _offset = Offset.zero; }),
onPanCancel: () =>
setState(() { _dragging = false; _offset = Offset.zero; }),
child: TweenAnimationBuilder<Offset>(
tween: Tween<Offset>(end: _offset),
duration: _dragging
? Duration.zero
    : const Duration(milliseconds: 560),
curve: Curves.easeOutCubic,
builder: (_, o, __) => AnimatedBuilder(
animation: _drift,
builder: (_, ___) {
final ph = _drift.value * 2 * math.pi;
final idle = Offset(math.sin(ph) * 4, math.cos(ph * 0.8) * 3);

Widget orb(double x, double y, double r, Color col) =>
Positioned(
left: x - r, top: y - r,
child: IgnorePointer(
child: Container(
width: r * 2, height: r * 2,
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: RadialGradient(
colors: [col, col.withOpacity(0)],
),
),
),
),
);

Widget shard(String label, String value, IconData icon,
Color color, double left, double top, double angle,
double depth) {
return Positioned(
left: left + o.dx * depth,
top: top + o.dy * depth,
child: Transform.rotate(
angle: angle,
child: Container(
width: shardW,
padding: EdgeInsets.symmetric(
horizontal: 12 * s, vertical: 10 * s),
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
Colors.white.withOpacity(0.17),
Colors.white.withOpacity(0.06),
],
),
borderRadius: BorderRadius.circular(16 * s),
border: Border.all(
color: Colors.white.withOpacity(0.28)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.28),
blurRadius: 16, offset: const Offset(0, 8),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, color: color, size: 13 * s),
SizedBox(width: 5 * s),
Text(label,
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.6),
fontSize: 8 * s,
fontWeight: FontWeight.w700,
letterSpacing: 0.6,
)),
],
),
SizedBox(height: 5 * s),
FittedBox(
fit: BoxFit.scaleDown,
child: Text(value,
style: GoogleFonts.inter(
color: Colors.white, fontSize: 16 * s,
fontWeight: FontWeight.w800, height: 1,
fontFeatures: const [
FontFeature.tabularFigures()
],
)),
),
],
),
),
),
);
}

return Stack(
clipBehavior: Clip.none,
children: [
orb(w * 0.2 + o.dx * 0.3 + idle.dx,
h * 0.3 + o.dy * 0.3, 60 * s,
_Aurora.teal.withOpacity(0.16)),
orb(w * 0.8 + o.dx * 0.45 - idle.dx,
h * 0.55 + o.dy * 0.4, 75 * s,
_Aurora.violet.withOpacity(0.14)),
orb(w * 0.5 + o.dx * 0.2, h * 0.8 + o.dy * 0.25,
55 * s, _HeroAccents.peach.withOpacity(0.12)),
Positioned(
top: 0, left: 0, right: 0,
child: Transform.translate(
offset: o * 0.5,
child: Center(
child: Text(
'${_greetingIcon()} ${_greeting()}, ${widget.name}',
maxLines: 1, overflow: TextOverflow.ellipsis,
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.8),
fontSize: 11 * s, fontWeight: FontWeight.w600,
),
),
),
),
),
Positioned(
left: (w - widget.coinSize) / 2 + o.dx * 0.7,
top: (h - widget.coinSize) / 2 - 10 * s + o.dy * 0.7,
child: Transform(
alignment: Alignment.center,
transform: Matrix4.identity()
..setEntry(3, 2, 0.0012)
..rotateY(o.dx * 0.004)
..rotateX(-o.dy * 0.004),
child: widget.coin,
),
),
Positioned(
right: -o.dx * 0.9,
top: h * 0.32 + o.dy * 0.9,
child: Container(
padding: EdgeInsets.all(8 * s),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.12),
borderRadius: BorderRadius.circular(24 * s),
border: Border.all(
color: Colors.white.withOpacity(0.22)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.25),
blurRadius: 16, offset: const Offset(0, 6),
),
],
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
_TapScale(
onTap: widget.onCart,
child: SizedBox(
width: 40 * s, height: 40 * s,
child: Icon(Icons.shopping_cart_rounded,
color: Colors.white, size: 20 * s),
),
),
SizedBox(height: 8 * s),
_TapScale(
onTap: widget.onPantry,
child: SizedBox(
width: 40 * s, height: 40 * s,
child: Icon(Icons.kitchen_rounded,
color: Colors.white, size: 20 * s),
),
),
SizedBox(height: 8 * s),
_TapScale(
onTap: widget.onSettings,
child: SizedBox(
width: 40 * s, height: 40 * s,
child: Icon(Icons.tune_rounded,
color: Colors.white, size: 20 * s),
),
),
],
),
),
),
shard('УРОВЕНЬ', 'Lv ${d.level}', Icons.star_rounded,
_Vibrant.goldMid, -4, 22 * s, -0.09, 1.05),
shard('НЕДЕЛЯ', '${d.thisWeek}/7',
Icons.calendar_view_week_rounded, _HeroAccents.amber,
w - shardW + 4, 36 * s, 0.08, 1.15),
shard('ККАЛ', '${d.kcal}',
Icons.local_fire_department_rounded, _Aurora.teal,
-6, h - 128 * s, 0.07, 1.25),
shard('ТРЕН.', '${(d.pWorkouts * 100).round()}%',
Icons.fitness_center_rounded, _HeroAccents.pink,
w - shardW + 6, h - 122 * s, -0.08, 1.35),
Positioned(
left: (w - 130 * s) / 2 + o.dx * 1.5,
top: h - 58 * s + o.dy * 1.5,
child: Transform.rotate(
angle: 0.03,
child: Container(
width: 130 * s,
padding: EdgeInsets.symmetric(
horizontal: 14 * s, vertical: 9 * s),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
_HeroAccents.sky.withOpacity(0.3),
Colors.white.withOpacity(0.08),
],
),
borderRadius: BorderRadius.circular(100),
border: Border.all(
color: _HeroAccents.sky.withOpacity(0.5)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.28),
blurRadius: 16, offset: const Offset(0, 8),
),
],
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
mainAxisSize: MainAxisSize.min,
children: [
Icon(Icons.bolt_rounded,
color: _HeroAccents.sky, size: 14 * s),
SizedBox(width: 6 * s),
Text('${d.streak} д',
style: GoogleFonts.inter(
color: Colors.white, fontSize: 14 * s,
fontWeight: FontWeight.w800,
fontFeatures: const [
FontFeature.tabularFigures()
],
)),
SizedBox(width: 6 * s),
Text('серия',
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.6),
fontSize: 9 * s,
fontWeight: FontWeight.w600,
)),
],
),
),
),
),
Positioned(
left: 0, right: 0, top: h - 100 * s,
child: IgnorePointer(
child: AnimatedOpacity(
opacity: _touched ? 0 : 0.85,
duration: const Duration(milliseconds: 400),
child: Center(
child: Container(
padding: EdgeInsets.symmetric(
horizontal: 10 * s, vertical: 5 * s),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.3),
borderRadius: BorderRadius.circular(100),
border: Border.all(
color: Colors.white.withOpacity(0.2)),
),
child: Text('↔ потяни — глубина',
style: GoogleFonts.inter(
color: Colors.white.withOpacity(0.85),
fontSize: 9 * s,
fontWeight: FontWeight.w600,
)),
),
),
),
),
),
],
);
},
),
),
);
});
}
}

// ═══════════════════════════════════════════════════════════════════
//  СХЕМЫ-ПРЕВЬЮ ДЛЯ ВЫБОРА СТИЛЯ (11 штук)
// ═══════════════════════════════════════════════════════════════════
class _HeroStylePreview extends StatelessWidget {
final int style;
const _HeroStylePreview({required this.style});

@override
Widget build(BuildContext context) {
return LayoutBuilder(builder: (_, c) {
final w = c.maxWidth;
final h = c.maxHeight;
final u = h / 110;

if (style >= 11) return _HeroExtraStylePreview(style: style);

Widget circle(double s, Color color) => Container(
width: s, height: s,
decoration: BoxDecoration(
shape: BoxShape.circle,
border: Border.all(color: color, width: 1.4),
),
);

Widget rings(double s) => SizedBox(
width: s, height: s,
child: Stack(alignment: Alignment.center, children: [
circle(s, _HeroAccents.peach.withOpacity(0.85)),
circle(s * 0.68, _HeroAccents.amber.withOpacity(0.8)),
circle(s * 0.40, _HeroAccents.sage.withOpacity(0.8)),
Container(
width: s * 0.14, height: s * 0.14,
decoration: const BoxDecoration(
color: Colors.white, shape: BoxShape.circle),
),
]),
);

Widget dot(double s, {Color? fill}) => Container(
width: s, height: s,
decoration: BoxDecoration(
color: fill ?? Colors.white.withOpacity(0.22),
shape: BoxShape.circle,
border: Border.all(color: Colors.white.withOpacity(0.45), width: 0.8),
),
);

Widget pill(double pw, double ph, {Color? fill}) => Container(
width: pw, height: ph,
decoration: BoxDecoration(
color: fill ?? Colors.white.withOpacity(0.22),
borderRadius: BorderRadius.circular(100),
border: Border.all(color: Colors.white.withOpacity(0.4), width: 0.8),
),
);

Widget line(double lw, {Color? color}) => Container(
width: lw, height: 3 * u,
decoration: BoxDecoration(
color: color ?? Colors.white.withOpacity(0.5),
borderRadius: BorderRadius.circular(100),
),
);

Widget tile(double tw, double th, {bool bright = false}) => Container(
width: tw, height: th,
decoration: BoxDecoration(
color: Colors.black.withOpacity(bright ? 0.45 : 0.3),
borderRadius: BorderRadius.circular(4 * u),
border: Border.all(
color: bright
? _HeroAccents.peach.withOpacity(0.8)
    : Colors.white.withOpacity(0.3),
width: bright ? 1.2 : 0.7,
),
),
);

Widget row(Widget child) =>
Row(mainAxisAlignment: MainAxisAlignment.center, children: [child]);

final items = <Widget>[];
switch (style) {
case 0:
items.addAll([
Positioned(left: 8 * u, top: 8 * u, child: dot(10 * u)),
Positioned(left: 8 * u, top: 22 * u, child: dot(10 * u)),
Positioned(right: 8 * u, top: 8 * u, child: dot(10 * u)),
Positioned(left: 0, right: 0, top: 16 * u,
child: row(rings(52 * u))),
Positioned(left: 0, right: 0, bottom: 16 * u,
child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
pill(20 * u, 7 * u), SizedBox(width: 4 * u),
pill(24 * u, 7 * u), SizedBox(width: 4 * u),
pill(20 * u, 7 * u),
])),
Positioned(left: 0, right: 0, bottom: 6 * u,
child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
pill(22 * u, 7 * u), SizedBox(width: 4 * u),
pill(20 * u, 7 * u),
])),
]);
break;
case 1:
items.addAll([
Positioned(left: 8 * u, top: 8 * u, child: pill(28 * u, 10 * u)),
Positioned(right: 8 * u, top: 8 * u, child: dot(10 * u)),
Positioned(left: 0, right: 0, top: 16 * u,
child: row(rings(52 * u))),
Positioned(left: 8 * u, right: 8 * u, bottom: 6 * u,
child: Container(
height: 16 * u,
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.35),
borderRadius: BorderRadius.circular(5 * u),
border: Border.all(
color: Colors.white.withOpacity(0.3), width: 0.7),
),
child: Row(
children: List.generate(9, (i) => i.isOdd
? Container(width: 0.7, height: 10 * u,
color: Colors.white.withOpacity(0.2))
    : Expanded(child: Center(child: dot(4 * u)))),
),
)),
]);
break;
case 2:
items.addAll([
Positioned(left: 0, right: 0, top: 6 * u, child: row(line(30 * u))),
Positioned(left: 0, right: 0, top: 14 * u,
child: row(pill(22 * u, 7 * u,
fill: _Vibrant.goldMid.withOpacity(0.8)))),
Positioned(left: 0, right: 0, top: 28 * u,
child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
Column(children: [
tile(18 * u, 22 * u), SizedBox(height: 5 * u),
tile(18 * u, 22 * u),
]),
SizedBox(width: 6 * u),
rings(46 * u),
SizedBox(width: 6 * u),
Column(children: [
tile(18 * u, 22 * u), SizedBox(height: 5 * u),
tile(18 * u, 22 * u),
]),
])),
Positioned(left: 0, right: 0, bottom: 6 * u,
child: row(pill(36 * u, 9 * u))),
]);
break;
case 3:
items.addAll([
Positioned(left: 8 * u, top: 8 * u, child: line(30 * u)),
Positioned(left: 8 * u, top: 15 * u,
child: line(20 * u, color: Colors.white.withOpacity(0.3))),
Positioned(right: 8 * u, top: 8 * u,
child: Row(children: [
dot(8 * u), SizedBox(width: 3 * u),
dot(8 * u), SizedBox(width: 3 * u),
dot(8 * u),
])),
Positioned(left: 10 * u, top: 30 * u, child: rings(40 * u)),
Positioned(left: 16 * u, top: 74 * u,
child: pill(28 * u, 7 * u,
fill: _Vibrant.goldMid.withOpacity(0.8))),
Positioned(right: 8 * u, top: 30 * u,
child: Container(
width: w * 0.44, height: 52 * u,
padding: EdgeInsets.symmetric(horizontal: 6 * u),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.3),
borderRadius: BorderRadius.circular(5 * u),
border: Border.all(
color: Colors.white.withOpacity(0.3), width: 0.7),
),
child: Column(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
line(w * 0.30), line(w * 0.22), line(w * 0.26),
],
),
)),
]);
break;
case 4:
items.addAll([
Positioned(left: 0, right: 0, top: 7 * u,
child: row(pill(40 * u, 10 * u))),
Positioned(left: 0, right: 0, top: 22 * u,
child: row(rings(54 * u))),
Positioned(left: 10 * u, right: 10 * u, bottom: -6 * u,
child: Container(
height: 20 * u,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.92),
borderRadius: BorderRadius.circular(6 * u),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
dot(5 * u, fill: _Vibrant.goldMid),
dot(5 * u, fill: _HeroAccents.amber),
dot(5 * u, fill: _Palette.green),
dot(5 * u, fill: _HeroAccents.pink),
dot(5 * u, fill: _HeroAccents.sky),
],
),
)),
]);
break;
case 5:
items.addAll([
Positioned(left: 8 * u, top: 8 * u,
child: pill(20 * u, 8 * u,
fill: _Vibrant.goldMid.withOpacity(0.8))),
Positioned(right: 8 * u, top: 8 * u, child: dot(10 * u)),
Positioned(left: 0, right: 0, top: 18 * u,
child: row(rings(50 * u))),
Positioned(left: 0, right: 0, bottom: 12 * u,
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
crossAxisAlignment: CrossAxisAlignment.end,
children: [
tile(24 * u, 18 * u), SizedBox(width: 4 * u),
tile(26 * u, 24 * u, bright: true), SizedBox(width: 4 * u),
tile(24 * u, 18 * u),
],
)),
Positioned(left: 0, right: 0, bottom: 5 * u,
child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
dot(3 * u), SizedBox(width: 3 * u),
pill(8 * u, 3 * u, fill: _HeroAccents.peach),
SizedBox(width: 3 * u),
dot(3 * u),
])),
]);
break;
case 6:
items.addAll([
Positioned(left: 8 * u, top: 7 * u,
child: pill(26 * u, 6 * u,
fill: _Vibrant.neonGreen.withOpacity(0.5))),
Positioned(right: 8 * u, top: 7 * u,
child: line(16 * u,
color: _Vibrant.neonGreen.withOpacity(0.8))),
Positioned(left: 0, right: 0, top: 17 * u,
child: row(Stack(alignment: Alignment.center, children: [
rings(48 * u),
Transform.rotate(angle: 0.7,
child: Container(width: 1.2, height: 24 * u,
color: _Vibrant.neonGreen.withOpacity(0.9))),
Transform.translate(offset: Offset(14 * u, -10 * u),
child: dot(4 * u, fill: _Vibrant.neonGreen)),
Transform.translate(offset: Offset(-16 * u, 8 * u),
child: dot(4 * u, fill: _Vibrant.neonGreen)),
]))),
Positioned(left: 24 * u, top: 15 * u,
child: Container(width: 7 * u, height: 7 * u,
decoration: BoxDecoration(border: Border(
top: BorderSide(
color: _Vibrant.neonGreen.withOpacity(0.8), width: 1.2),
left: BorderSide(
color: _Vibrant.neonGreen.withOpacity(0.8), width: 1.2),
)))),
Positioned(right: 24 * u, bottom: 40 * u,
child: Container(width: 7 * u, height: 7 * u,
decoration: BoxDecoration(border: Border(
bottom: BorderSide(
color: _Vibrant.neonGreen.withOpacity(0.8), width: 1.2),
right: BorderSide(
color: _Vibrant.neonGreen.withOpacity(0.8), width: 1.2),
)))),
Positioned(left: 0, right: 0, bottom: 18 * u,
child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
tile(58 * u, 9 * u), SizedBox(width: 6 * u), tile(58 * u, 9 * u),
])),
Positioned(left: 0, right: 0, bottom: 6 * u,
child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
tile(58 * u, 9 * u), SizedBox(width: 6 * u), tile(58 * u, 9 * u),
])),
]);
break;
case 7:
items.addAll([
Positioned(left: -10 * u, right: -10 * u, top: 12 * u,
child: Transform.rotate(angle: -0.06,
child: Container(height: 14 * u,
decoration: BoxDecoration(
gradient: LinearGradient(colors: [
_Aurora.green.withOpacity(0.5),
_Aurora.teal.withOpacity(0.4),
_Aurora.violet.withOpacity(0.4),
]),
borderRadius: BorderRadius.circular(100),
)))),
Positioned(left: -10 * u, right: -10 * u, top: 26 * u,
child: Transform.rotate(angle: 0.05,
child: Container(height: 10 * u,
decoration: BoxDecoration(
gradient: LinearGradient(colors: [
_Aurora.violet.withOpacity(0.35),
_Aurora.pink.withOpacity(0.35),
]),
borderRadius: BorderRadius.circular(100),
)))),
Positioned(left: 8 * u, top: 6 * u, child: line(24 * u)),
Positioned(right: 8 * u, top: 6 * u,
child: Row(children: [
dot(6 * u), SizedBox(width: 3 * u),
dot(6 * u), SizedBox(width: 3 * u), dot(6 * u),
])),
Positioned(left: 0, right: 0, top: 32 * u, child: row(rings(44 * u))),
Positioned(left: 10 * u, bottom: 22 * u, child: pill(34 * u, 9 * u)),
Positioned(right: 12 * u, bottom: 16 * u, child: pill(34 * u, 9 * u)),
Positioned(left: 0, right: 0, bottom: 6 * u,
child: row(pill(30 * u, 8 * u))),
]);
break;
case 8:
items.addAll([
Positioned(left: 8 * u, top: 7 * u,
child: pill(24 * u, 6 * u,
fill: _Vibrant.neonGreen.withOpacity(0.5))),
Positioned(right: 8 * u, top: 7 * u,
child: pill(18 * u, 6 * u,
fill: _HeroAccents.peach.withOpacity(0.5))),
Positioned(left: 0, right: 0, top: 16 * u,
child: row(Stack(alignment: Alignment.center, children: [
Container(width: 62 * u, height: 62 * u,
decoration: BoxDecoration(shape: BoxShape.circle,
border: Border.all(
color: _HeroAccents.amber.withOpacity(0.6),
width: 1.6))),
rings(44 * u),
Transform.rotate(angle: 0.9,
child: Transform.translate(offset: Offset(0, -26 * u),
child: Container(width: 2, height: 8 * u,
color: _Vibrant.vividPeach))),
]))),
Positioned(left: 10 * u, right: 10 * u, bottom: 18 * u,
child: Container(height: 14 * u,
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.4),
borderRadius: BorderRadius.circular(4 * u),
border: Border.all(
color: Colors.white.withOpacity(0.25), width: 0.7),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
line(14 * u, color: Colors.white.withOpacity(0.85)),
line(10 * u, color: _HeroAccents.sky),
line(12 * u, color: _HeroAccents.amber),
]))),
Positioned(left: 0, right: 0, bottom: 7 * u,
child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
dot(8 * u), SizedBox(width: 8 * u),
dot(8 * u), SizedBox(width: 8 * u), dot(8 * u),
])),
]);
break;
case 9:
items.addAll([
Positioned(left: 7 * u, top: 7 * u,
child: Transform.rotate(angle: -0.05,
child: Container(width: 30 * u, height: 9 * u,
decoration: BoxDecoration(
color: _Pop.yellow,
border: Border.all(color: _Pop.ink, width: 1.2),
borderRadius: BorderRadius.circular(2 * u),
)))),
Positioned(right: 7 * u, top: 7 * u,
child: Row(children: [
dot(8 * u, fill: _Pop.blue), SizedBox(width: 3 * u),
dot(8 * u, fill: _Pop.magenta), SizedBox(width: 3 * u),
dot(8 * u, fill: _Pop.green),
])),
Positioned(left: 0, right: 0, top: 20 * u,
child: row(Container(width: 52 * u, height: 52 * u,
decoration: BoxDecoration(
color: Colors.white, shape: BoxShape.circle,
border: Border.all(color: _Pop.ink, width: 2),
),
child: Center(child: rings(44 * u))))),
Positioned(left: 26 * u, top: 14 * u,
child: Icon(Icons.star_rounded, color: _Pop.yellow, size: 16 * u)),
Positioned(left: 12 * u, bottom: 20 * u,
child: Transform.rotate(angle: -0.08,
child: Container(width: 40 * u, height: 12 * u,
decoration: BoxDecoration(
color: _Pop.magenta,
border: Border.all(color: _Pop.ink, width: 1.2),
borderRadius: BorderRadius.circular(3 * u),
)))),
Positioned(right: 12 * u, bottom: 22 * u,
child: Transform.rotate(angle: 0.07,
child: Container(width: 40 * u, height: 12 * u,
decoration: BoxDecoration(
color: _Pop.blue,
border: Border.all(color: _Pop.ink, width: 1.2),
borderRadius: BorderRadius.circular(3 * u),
)))),
Positioned(left: 0, right: 0, bottom: 7 * u,
child: row(Transform.rotate(angle: 0.04,
child: Container(width: 44 * u, height: 12 * u,
decoration: BoxDecoration(
color: _Pop.green,
border: Border.all(color: _Pop.ink, width: 1.2),
borderRadius: BorderRadius.circular(3 * u),
))))),
]);
break;
case 10:
items.addAll([
Positioned(left: 0, right: 0, top: 6 * u,
child: row(line(30 * u, color: Colors.white.withOpacity(0.6)))),
Positioned(left: 0, right: 0, top: 26 * u, child: row(rings(46 * u))),
Positioned(left: 6 * u, top: 16 * u,
child: Transform.rotate(angle: -0.1,
child: tile(30 * u, 14 * u, bright: true))),
Positioned(right: 6 * u, top: 22 * u,
child: Transform.rotate(angle: 0.09, child: tile(30 * u, 14 * u))),
Positioned(left: 8 * u, bottom: 26 * u,
child: Transform.rotate(angle: 0.08, child: tile(30 * u, 14 * u))),
Positioned(right: 8 * u, bottom: 30 * u,
child: Transform.rotate(angle: -0.09, child: tile(30 * u, 14 * u))),
Positioned(left: 0, right: 0, bottom: 8 * u,
child: row(pill(36 * u, 8 * u))),
Positioned(right: 4 * u, top: 44 * u,
child: Container(width: 7 * u, height: 26 * u,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.2),
borderRadius: BorderRadius.circular(100),
border: Border.all(
color: Colors.white.withOpacity(0.35), width: 0.7),
))),
]);
break;
}

return ClipRRect(
borderRadius: BorderRadius.circular(12 * u),
child: Container(
width: w, height: h,
decoration: const BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft, end: Alignment.bottomRight,
colors: [_Hero.bgTop, _Hero.bgBottom],
),
),
child: Stack(children: items),
),
);
});
}
}

// ═══════════════════════════════════════════════════════════════════
//  HERO RINGS PAINTER
// ═══════════════════════════════════════════════════════════════════
bool _sameDaysList(List<bool> a, List<bool> b) {
if (identical(a, b)) return true;
if (a.length != b.length) return false;
for (int i = 0; i < a.length; i++) {
if (a[i] != b[i]) return false;
}
return true;
}

class _HeroRingsPainter extends CustomPainter {
final double anim;
final List<bool> daysActive;
final int daysPassed;
final double caloriesProgress, workoutsProgress, streakProgress;
final DateTime time;
_HeroRingsPainter({
required this.anim, required this.daysActive,
required this.daysPassed, required this.caloriesProgress,
required this.workoutsProgress, required this.streakProgress,
required this.time,
});

@override
void paint(Canvas canvas, Size size) {
final center = Offset(size.width / 2, size.height / 2);
final scale = size.width / 340.0;
const rDigits = 160.0;
const r1 = 144.0;
const rDayLabels = 126.0;
const r2 = 108.0;
const r3 = 82.0;
const r4 = 56.0;
const r5 = 30.0;
const stroke = 10.0;
_drawHourNumbers(canvas, center, rDigits * scale, _HeroAccents.sage, scale);
_drawTimeDial(canvas, center, r1 * scale, stroke * scale, time,
_HeroAccents.peach, anim);
_drawDayLabels(canvas, center, rDayLabels * scale, daysActive,
_HeroAccents.amber, scale);
_drawDaysRing(canvas, center, r2 * scale, stroke * scale, daysActive,
_HeroAccents.amber);
_drawProgressRing(canvas, center, r3 * scale, stroke * scale,
caloriesProgress * anim, _HeroAccents.sage);
_drawProgressRing(canvas, center, r4 * scale, stroke * scale,
workoutsProgress * anim, _HeroAccents.pink);
_drawProgressRing(canvas, center, r5 * scale, stroke * scale,
streakProgress * anim, _HeroAccents.sky);
_drawCenterClock(canvas, center, r5 * scale, stroke * scale, time);
}

void _drawHourNumbers(
Canvas canvas, Offset center, double radius, Color color, double scale) {
const hours = [0, 3, 6, 9, 12, 15, 18, 21];
final fontSize = 9.0 * scale;
for (final h in hours) {
final angle = -math.pi / 2 + (h / 24.0) * 2 * math.pi;
final pos = Offset(center.dx + math.cos(angle) * radius,
center.dy + math.sin(angle) * radius);
final tp = TextPainter(
text: TextSpan(
text: h.toString().padLeft(2, '0'),
style: TextStyle(
color: color.withOpacity(0.9),
fontSize: fontSize, fontWeight: FontWeight.w900, height: 1,
shadows: [
Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4)
])),
textDirection: TextDirection.ltr,
)..layout();
tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
}
}

void _drawDayLabels(Canvas canvas, Offset center, double radius,
List<bool> daysActive, Color color, double scale) {
const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
final fontSize = 10.5 * scale;
for (int i = 0; i < 7; i++) {
final angle = -math.pi / 2 + (i / 7.0 + 1.0 / 14.0) * 2 * math.pi;
final pos = Offset(center.dx + math.cos(angle) * radius,
center.dy + math.sin(angle) * radius);
final isPast = i < daysPassed;
final isToday = i == daysPassed - 1;
Color textColor;
FontWeight weight;
if (isToday) {
textColor = _Vibrant.vividPeach;
weight = FontWeight.w900;
} else if (isPast) {
textColor = _Vibrant.neonGreen;
weight = FontWeight.w900;
} else {
textColor = Colors.white.withOpacity(0.8);
weight = FontWeight.w700;
}
final tp = TextPainter(
text: TextSpan(
text: names[i],
style: TextStyle(
color: textColor, fontSize: fontSize,
fontWeight: weight, height: 1,
shadows: [
Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4)
])),
textDirection: TextDirection.ltr,
)..layout();
tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
}
}

void _drawTimeDial(Canvas canvas, Offset center, double radius, double stroke,
DateTime time, Color color, double anim) {
final hoursNow = time.hour + time.minute / 60.0;
final progress = (hoursNow / 24.0) * anim;
const segments = 24;
final rect = Rect.fromCircle(center: center, radius: radius);
const segGap = 0.018;
for (int i = 0; i < segments; i++) {
final segStart = i / segments;
final segEnd = (i + 1) / segments;
final startAngle = -math.pi / 2 + segStart * 2 * math.pi;
final sweep = (segEnd - segStart) * 2 * math.pi;
final filled = progress >= segEnd;
final partial = !filled && progress > segStart;
if (filled) {
canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color);
} else if (partial) {
final partialSweep = (progress * 2 * math.pi) - (segStart * 2 * math.pi);
canvas.drawArc(rect, startAngle + segGap, partialSweep - segGap, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color);
} else {
canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke * 0.75..strokeCap = StrokeCap.round
..color = Colors.white.withOpacity(0.2));
}
}
final timeAngle = -math.pi / 2 + progress * 2 * math.pi;
final dotPos = Offset(center.dx + math.cos(timeAngle) * radius,
center.dy + math.sin(timeAngle) * radius);
canvas.drawCircle(dotPos, stroke * 1.0,
Paint()..color = color.withOpacity(0.55)
..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
canvas.drawCircle(dotPos, stroke * 0.65, Paint()..color = color);
canvas.drawCircle(dotPos, stroke * 0.28, Paint()..color = Colors.white);
}

void _drawDaysRing(Canvas canvas, Offset center, double radius, double stroke,
List<bool> daysActive, Color color) {
const segments = 7;
final rect = Rect.fromCircle(center: center, radius: radius);
const segGap = 0.035;
for (int i = 0; i < segments; i++) {
final segStart = i / segments;
final segEnd = (i + 1) / segments;
final startAngle = -math.pi / 2 + segStart * 2 * math.pi;
final sweep = (segEnd - segStart) * 2 * math.pi;
final isPast = i < daysPassed;
final isToday = i == daysPassed - 1;
if (isToday) {
canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke * 1.9..strokeCap = StrokeCap.round
..color = _HeroAccents.peach.withOpacity(0.55)
..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke * 1.15..strokeCap = StrokeCap.round
..color = _Vibrant.vividPeach);
} else if (isPast) {
canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke * 1.7..strokeCap = StrokeCap.round
..color = _Vibrant.neonGreen.withOpacity(0.30)
..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke * 1.05..strokeCap = StrokeCap.round
..color = _Vibrant.neonGreen);
canvas.drawArc(rect, startAngle + segGap,
(sweep - segGap * 2) * 0.18, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke * 0.35..strokeCap = StrokeCap.round
..color = Colors.white.withOpacity(0.55));
} else {
canvas.drawArc(rect, startAngle + segGap, sweep - segGap * 2, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke * 0.75..strokeCap = StrokeCap.round
..color = Colors.white.withOpacity(0.2));
}
}
}

void _drawProgressRing(Canvas canvas, Offset center, double radius,
double stroke, double progress, Color color) {
canvas.drawCircle(center, radius,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke * 0.75..color = Colors.white.withOpacity(0.15));
if (progress <= 0) return;
final rect = Rect.fromCircle(center: center, radius: radius);
const start = -math.pi / 2;
final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
canvas.drawArc(rect, start, sweep, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke * 1.6..strokeCap = StrokeCap.round
..color = color.withOpacity(0.28)
..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
canvas.drawArc(rect, start, sweep, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color);
canvas.drawArc(rect, start, sweep * 0.08, false,
Paint()..style = PaintingStyle.stroke
..strokeWidth = stroke * 0.4..strokeCap = StrokeCap.round
..color = Colors.white.withOpacity(0.65));
}

void _drawCenterClock(
Canvas canvas, Offset center, double r5, double stroke, DateTime time) {
final maxClockR = r5 - (stroke * 0.5);
final clockR = maxClockR * 0.80;
canvas.drawCircle(
center, clockR,
Paint()
..shader = RadialGradient(
colors: [
const Color(0xFF2B3A32).withOpacity(0.98),
const Color(0xFF0D0F12),
],
stops: const [0.0, 1.0],
).createShader(Rect.fromCircle(center: center, radius: clockR))
..style = PaintingStyle.fill,
);
canvas.drawCircle(
center, clockR,
Paint()
..color = Colors.white.withOpacity(0.25)
..style = PaintingStyle.stroke
..strokeWidth = 1.2,
);
canvas.drawCircle(
center, clockR - 2,
Paint()
..color = Colors.white.withOpacity(0.08)
..style = PaintingStyle.stroke
..strokeWidth = 0.8,
);
for (int i = 0; i < 12; i++) {
final angle = (i * 30 - 90) * (math.pi / 180);
final isMain = i % 3 == 0;
final startR = clockR - (isMain ? 4.0 : 2.0);
final endR = clockR - 0.8;
final p1 = Offset(center.dx + math.cos(angle) * startR,
center.dy + math.sin(angle) * startR);
final p2 = Offset(center.dx + math.cos(angle) * endR,
center.dy + math.sin(angle) * endR);
canvas.drawLine(p1, p2, Paint()
..color = Colors.white.withOpacity(isMain ? 0.95 : 0.55)
..strokeWidth = isMain ? 1.4 : 0.7
..strokeCap = StrokeCap.round);
}
final hours = time.hour % 12;
final minutes = time.minute;
final seconds = time.second;
final hourAngle = ((hours + minutes / 60) * 30 - 90) * (math.pi / 180);
_drawClockHand(canvas, center, hourAngle,
length: clockR * 0.45, width: 1.8, color: Colors.white.withOpacity(0.98));
final minuteAngle = ((minutes + seconds / 60) * 6 - 90) * (math.pi / 180);
_drawClockHand(canvas, center, minuteAngle,
length: clockR * 0.70, width: 1.2, color: Colors.white.withOpacity(0.92));
final secondAngle = (seconds * 6 - 90) * (math.pi / 180);
_drawClockHand(canvas, center, secondAngle,
length: clockR * 0.82, width: 0.7, color: _HeroAccents.peach);
canvas.drawCircle(center, 2.0, Paint()..color = Colors.black.withOpacity(0.6));
canvas.drawCircle(center, 1.5, Paint()..color = _HeroAccents.peach);
canvas.drawCircle(center, 0.7, Paint()..color = Colors.white);
}

void _drawClockHand(Canvas canvas, Offset center, double angle,
{required double length, required double width, required Color color}) {
final end = Offset(center.dx + math.cos(angle) * length,
center.dy + math.sin(angle) * length);
const shadowOffset = Offset(0.5, 0.8);
canvas.drawLine(center + shadowOffset, end + shadowOffset, Paint()
..color = Colors.black.withOpacity(0.35)
..strokeWidth = width
..strokeCap = StrokeCap.round);
canvas.drawLine(center, end, Paint()
..color = color
..strokeWidth = width
..strokeCap = StrokeCap.round);
}

@override
bool shouldRepaint(covariant _HeroRingsPainter old) =>
old.anim != anim ||
old.caloriesProgress != caloriesProgress ||
old.workoutsProgress != workoutsProgress ||
old.streakProgress != streakProgress ||
old.daysPassed != daysPassed ||
old.time.hour != time.hour ||
old.time.minute != time.minute ||
old.time.second != time.second ||
!_sameDaysList(old.daysActive, daysActive);
}

// ═══════════════════════════════════════════════════════════════════
//  3D COIN FLIP WIDGET
// ═══════════════════════════════════════════════════════════════════
class _CoinFlipWidget extends StatefulWidget {
final Widget front;
final Widget back;
final bool isFlipped;
final double size;
const _CoinFlipWidget({
required this.front, required this.back,
required this.isFlipped, required this.size,
});
@override
State<_CoinFlipWidget> createState() => _CoinFlipWidgetState();
}

class _CoinFlipWidgetState extends State<_CoinFlipWidget>
with SingleTickerProviderStateMixin {
late AnimationController _controller;
late Animation<double> _animation;

@override
void initState() {
super.initState();
_controller = AnimationController(
duration: const Duration(milliseconds: 900),
vsync: this,
);
_animation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);
if (widget.isFlipped) {
_controller.value = 1.0;
}
}

@override
void didUpdateWidget(_CoinFlipWidget oldWidget) {
super.didUpdateWidget(oldWidget);
if (widget.isFlipped != oldWidget.isFlipped) {
if (widget.isFlipped) {
_controller.forward();
} else {
_controller.reverse();
}
}
}

@override
void dispose() {
_controller.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return AnimatedBuilder(
animation: _animation,
builder: (context, child) {
final angle = _animation.value * math.pi;
final matrix = Matrix4.identity()
..setEntry(3, 2, 0.0015)
..rotateY(angle);
final isBack = _animation.value > 0.5;
return Transform(
alignment: Alignment.center,
transform: matrix,
child: SizedBox(
width: widget.size,
height: widget.size,
child: Stack(
children: [
if (!isBack)
SizedBox(
width: widget.size, height: widget.size,
child: widget.front,
),
if (isBack)
Transform(
alignment: Alignment.center,
transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
child: SizedBox(
width: widget.size, height: widget.size,
child: widget.back,
),
),
],
),
),
);
},
);
}
}

// ═══════════════════════════════════════════════════════════════════
//  GOLD LEVEL BADGE
// ═══════════════════════════════════════════════════════════════════

class _LevelBadge extends StatelessWidget {
final int level;
final double scale;
const _LevelBadge({required this.level, required this.scale});

@override
Widget build(BuildContext context) {
return Container(
padding: EdgeInsets.symmetric(
horizontal: 10 * scale,
vertical: 5.5 * scale,
),
decoration: BoxDecoration(
gradient: const LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
Color(0xFFFFE8AD),
Color(0xFFE8B95E),
],
),
borderRadius: BorderRadius.circular(100),
border: Border.all(color: Colors.white.withOpacity(0.52)),
boxShadow: [
BoxShadow(
color: const Color(0xFFE8B95E).withOpacity(0.28),
blurRadius: 12,
offset: const Offset(0, 3),
),
],
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.auto_awesome_rounded,
color: const Color(0xFF62451A),
size: 11 * scale,
),
SizedBox(width: 5 * scale),
Text(
'УРОВЕНЬ $level',
style: GoogleFonts.inter(
color: const Color(0xFF62451A),
fontSize: 9.5 * scale,
fontWeight: FontWeight.w800,
letterSpacing: 0.45,
fontFeatures: const [FontFeature.tabularFigures()],
),
),
],
),
);
}
}
