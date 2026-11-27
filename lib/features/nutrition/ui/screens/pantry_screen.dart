// features/nutrition/ui/screens/pantry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import '../widgets/transfer_to_shopping_sheet.dart';
import 'add_pantry_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════
class _Palette {
  static const bg = Color(0xFFF7F6F2);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF243A32);
  static const textMuted = Color(0xFF7C8982);
  static const green = Color(0xFF3E6A55);
  static const greenSoft = Color(0xFFE7EFE5);
  static const peach = Color(0xFFC4886A);
  static const peachSoft = Color(0xFFF6E8DF);
  static const pink = Color(0xFFBB8F9D);
  static const pinkSoft = Color(0xFFF3E6EA);
  static const brown = Color(0xFFA0764C);
  static const brownSoft = Color(0xFFF4EBDF);
  static const sky = Color(0xFF7E9DC6);
  static const skySoft = Color(0xFFE9F0F8);
  static const amber = Color(0xFFE0A93F);
  static const divider = Color(0xFFE7EAE3);
}

class _Dark {
  static const top = Color(0xFF2B3A32);
  static const bottom = Color(0xFF1B2027);
}

class _R {
  final double scale;
  _R(BuildContext context)
      : scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

// ═══════════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════════
String _fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final s = v.toStringAsFixed(2);
  return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
}

String _itemsWord(int n) =>
    n == 1 ? 'позиция' : (n >= 2 && n <= 4 ? 'позиции' : 'позиций');

String _timesWord(int n) =>
    n == 1 ? 'раз' : (n >= 2 && n <= 4 ? 'раза' : 'раз');

String _categoryToAisle(String category) {
  switch (category) {
    case 'vegetables': return 'Овощи';
    case 'fruits': return 'Фрукты';
    case 'meat': return 'Мясо';
    case 'fish': return 'Рыба';
    case 'dairy': return 'Молочка';
    case 'bakery': case 'grains': return 'Бакалея';
    case 'drinks': return 'Напитки';
    case 'sweets': return 'Сладости';
    case 'sauces': return 'Соусы';
    default: return 'Другое';
  }
}

String _aisleEmoji(String aisle) {
  switch (aisle) {
    case 'Овощи': return '🥬'; case 'Фрукты': return '🍎';
    case 'Мясо': return '🥩'; case 'Рыба': return '🐟';
    case 'Молочка': return '🥛'; case 'Хлеб': return '🥐';
    case 'Бакалея': return '🌾'; case 'Заморозка': return '🧊';
    case 'Напитки': return '☕'; case 'Сладости': return '🍫';
    case 'Соусы': return '🧂'; default: return '🍽️';
  }
}

Color _aisleAccent(String aisle) {
  switch (aisle) {
    case 'Овощи': return const Color(0xFF6C9E88);
    case 'Фрукты': return const Color(0xFFFF8A65);
    case 'Мясо': return const Color(0xFFFF6B8B);
    case 'Рыба': return const Color(0xFF7EA8C6);
    case 'Молочка': return const Color(0xFFE8B858);
    case 'Хлеб': return const Color(0xFFD4A04A);
    case 'Бакалея': return const Color(0xFFA5C9AF);
    case 'Напитки': return const Color(0xFF6C9E88);
    case 'Сладости': return const Color(0xFFFF6B8B);
    case 'Соусы': return const Color(0xFFEF9563);
    default: return const Color(0xFF8E949B);
  }
}

String _dayLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Сегодня';
  if (diff == 1) return 'Вчера';
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

String _shortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

// ═══════════════════════════════════════════════════════════════════
//  АГРЕГАТЫ
// ═══════════════════════════════════════════════════════════════════
class _CatalogEntry {
  final String key, name, emoji;
  final String? productId;
  int count = 0;
  double totalSpent = 0;
  double lastQty = 1;
  String unit = 'шт';
  double? lastPrice;
  PriceBasis? lastBasis;
  String? category;
  String? fallback;
  DateTime lastAt = DateTime(2000);
  _CatalogEntry({
    required this.key, required this.name,
    required this.emoji, required this.productId,
  });
}

class _ProductStat {
  final String name, emoji;
  int count = 0;
  double spent = 0;
  double lastQty = 0;
  String unit = '';
  DateTime lastAt = DateTime(2000);
  _ProductStat({required this.name, required this.emoji});
}

class _AisleStat {
  final String aisle;
  int count = 0;
  double spent = 0;
  String topProduct = '';
  double topSpent = 0;
  _AisleStat(this.aisle);
}

// ═══════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════
class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});
  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen>
    with TickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  // кладовая
  final _stockSearch = TextEditingController();
  int _stockFilter = 0; // 0 все · 1 скоро · 2 испорчено

  // история
  int _period = 2;      // 0 неделя · 1 месяц · 2 всё
  int _historyMode = 0; // 0 дни · 1 продукты · 2 отделы

  // база
  final _catalogSearch = TextEditingController();
  int _catalogSort = 0; // 0 чаще · 1 недавние · 2 а-я

  @override
  void dispose() {
    _tab.dispose();
    _stockSearch.dispose();
    _catalogSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _R(context);
    final provider = context.watch<NutritionProvider>();
    final pantry = provider.pantryItems;
    final bought =
    provider.shoppingItems.where((i) => i.isBought).toList();
    final expiring = pantry
        .where((i) => i.daysUntilExpiry >= 0 && i.daysUntilExpiry <= 3)
        .length;

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: Column(
        children: [
          // ── ШАПКА ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_Dark.top, _Dark.bottom],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.s(16), r.s(8), r.s(16), r.s(10)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _glassBtn(Icons.arrow_back_rounded,
                                () => Navigator.pop(context), r),
                        SizedBox(width: r.s(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('КЛАДОВАЯ',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: r.fs(10),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                  )),
                              Text('Полки · история · база',
                                  style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: r.fs(17),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.4,
                                  )),
                            ],
                          ),
                        ),
                        _glassBtn(Icons.add_rounded,
                                () => _openAdd(provider), r),
                      ],
                    ),
                    SizedBox(height: r.s(12)),
                    Row(
                      children: [
                        _headChip('🧺', '${pantry.length}', 'на полках',
                            Colors.white, r),
                        SizedBox(width: r.s(8)),
                        _headChip('⏳', '$expiring', 'скоро испортятся',
                            expiring > 0
                                ? const Color(0xFFFF8A65)
                                : Colors.white, r),
                        SizedBox(width: r.s(8)),
                        _headChip('🛒', '${bought.length}', 'куплено всего',
                            const Color(0xFF3DDC84), r),
                      ],
                    ),
                    SizedBox(height: r.s(12)),
                    TabBar(
                      controller: _tab,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding:
                      EdgeInsets.symmetric(horizontal: r.s(3), vertical: r.s(5)),
                      indicator: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.22)),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.55),
                      labelStyle: GoogleFonts.inter(
                          fontSize: r.fs(12), fontWeight: FontWeight.w700),
                      unselectedLabelStyle: GoogleFonts.inter(
                          fontSize: r.fs(12), fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Кладовая'),
                        Tab(text: 'История'),
                        Tab(text: 'База'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── ВКЛАДКИ ──
          Expanded(
            child: TabBarView(
              controller: _tab,
              physics: const BouncingScrollPhysics(),
              children: [
                _stockTab(provider, r),
                _historyTab(provider, r),
                _catalogTab(provider, r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headChip(
      String emoji, String value, String label, Color color, _R r) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: r.s(8), horizontal: r.s(8)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(r.s(12)),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: r.fs(11))),
                SizedBox(width: r.s(4)),
                Text(value,
                    style: GoogleFonts.inter(
                      color: color, fontSize: r.fs(15),
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ],
            ),
            SizedBox(height: r.s(2)),
            Text(label,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: r.fs(8), fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap, _R r) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        width: r.s(40), height: r.s(40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: r.s(18)),
      ),
    );
  }

  void _openAdd(NutritionProvider provider) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const AddPantryScreen(),
      ),
    ));
  }

  void _snack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text,
          style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ═══════════════════════════════════════════════════════════════
  //  ВКЛАДКА 1 — КЛАДОВАЯ
  // ═══════════════════════════════════════════════════════════════
  Widget _stockTab(NutritionProvider provider, _R r) {
    final all = provider.pantryItems;
    final query = _stockSearch.text.trim().toLowerCase();
    var items = all.where((i) {
      if (query.isNotEmpty &&
          !i.displayName.toLowerCase().contains(query)) return false;
      if (_stockFilter == 1) {
        return i.daysUntilExpiry >= 0 && i.daysUntilExpiry <= 3;
      }
      if (_stockFilter == 2) return i.daysUntilExpiry < 0;
      return true;
    }).toList()
      ..sort((a, b) {
        final ae = a.expiresAt, be = b.expiresAt;
        if (ae == null && be == null) return 0;
        if (ae == null) return 1;
        if (be == null) return -1;
        return ae.compareTo(be);
      });

    final expiredCount = all.where((i) => i.daysUntilExpiry < 0).length;
    final soonCount = all
        .where((i) => i.daysUntilExpiry >= 0 && i.daysUntilExpiry <= 3)
        .length;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(r.s(16), r.s(14), r.s(16), 0),
          child: _searchField(_stockSearch, 'Поиск на полках…', r),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(r.s(16), r.s(10), r.s(16), r.s(6)),
          child: Row(
            children: [
              _filterChip('Все ${all.length}', _stockFilter == 0,
                  _Palette.green, () => setState(() => _stockFilter = 0), r),
              SizedBox(width: r.s(6)),
              _filterChip('Скоро $soonCount', _stockFilter == 1,
                  _Palette.peach, () => setState(() => _stockFilter = 1), r),
              SizedBox(width: r.s(6)),
              _filterChip('Испорчено $expiredCount', _stockFilter == 2,
                  _Palette.pink, () => setState(() => _stockFilter = 2), r),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _empty('🧺', 'Полки пусты',
              'Покупки из списка попадают сюда автоматически', r)
              : ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(6), r.s(16), r.s(100)),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: r.s(8)),
            itemBuilder: (_, i) => _stockTile(items[i], provider, r),
          ),
        ),
      ],
    );
  }

  // pantry_screen.dart — замени метод _stockTile целиком
  Widget _stockTile(PantryItem item, NutritionProvider provider, _R r) {
    final product =
        provider.products.where((p) => p.id == item.productId).firstOrNull;
    final emoji = product?.categoryEmoji ?? '📦';
    final days = item.daysUntilExpiry;
    final expired = days < 0;
    final urgent = days >= 0 && days <= 1;
    final soon = days >= 0 && days <= 3;
    final accent = expired
        ? _Palette.pink
        : urgent
        ? const Color(0xFFFF8A65)
        : soon
        ? _Palette.amber
        : _Palette.green;
    final expiryText = item.expiresAt == null
        ? 'без срока'
        : expired
        ? '⚠️ срок истёк'
        : days == 0
        ? '🔥 сегодня последний день'
        : '⏳ ещё $days дн. · до ${_shortDate(item.expiresAt!)}';

    return Dismissible(
      key: Key('stock_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: r.s(20)),
        decoration: BoxDecoration(
          color: _Palette.pinkSoft,
          borderRadius: BorderRadius.circular(r.s(18)),
        ),
        child:
        Icon(Icons.delete_rounded, color: _Palette.pink, size: r.s(22)),
      ),
      confirmDismiss: (_) => _confirm(
        'Убрать «${item.displayName}»?',
        'Позиция исчезнет с полок (съел / выбросил).',
        'Убрать',
      ),
      onDismissed: (_) {
        provider.removeFromPantry(item.id);
        HapticFeedback.mediumImpact();
        _snack('🗑️ «${item.displayName}» убран с полок', _Palette.pink);
      },
      child: Container(
        padding: EdgeInsets.all(r.s(12)),
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(r.s(18)),
          border: Border.all(
              color: expired || soon
                  ? accent.withOpacity(0.35)
                  : Colors.white.withOpacity(0.95),
              width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.07),
              blurRadius: 14, spreadRadius: -4, offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: r.s(42), height: r.s(42),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(r.s(12)),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: TextStyle(fontSize: r.s(20))),
            ),
            SizedBox(width: r.s(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.displayName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _Palette.text, fontSize: r.fs(13),
                        fontWeight: FontWeight.w600,
                      )),
                  SizedBox(height: r.s(2)),
                  Text('${_fmtNum(item.quantity)} ${item.unit}',
                      style: GoogleFonts.inter(
                        color: _Palette.textMuted, fontSize: r.fs(11),
                        fontWeight: FontWeight.w600,
                      )),
                  SizedBox(height: r.s(3)),
                  Text(expiryText,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: accent, fontSize: r.fs(10),
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
            SizedBox(width: r.s(8)),
            _TapScale(
              onTap: () => showTransferToShoppingSheet(
                context,
                provider,
                name: item.customName ?? item.displayName,
                productId: item.productId,
                quantity: item.quantity,
                unit: item.unit,
                isUrgent: expired || urgent,
              ),
              child: Container(
                width: r.s(34), height: r.s(34),
                decoration: BoxDecoration(
                  color: _Palette.skySoft,
                  borderRadius: BorderRadius.circular(r.s(10)),
                ),
                child: Icon(Icons.add_shopping_cart_rounded,
                    color: _Palette.sky, size: r.s(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ВКЛАДКА 2 — ИСТОРИЯ
  // ═══════════════════════════════════════════════════════════════
  Widget _historyTab(NutritionProvider provider, _R r) {
    final now = DateTime.now();
    final cutoff = _period == 0
        ? now.subtract(const Duration(days: 7))
        : _period == 1
        ? now.subtract(const Duration(days: 30))
        : null;
    final bought = provider.shoppingItems
        .where((i) =>
    i.isBought && (cutoff == null || i.createdAt.isAfter(cutoff)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalSpent = bought.fold<double>(0, (s, i) => s + i.totalPrice);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(r.s(16), r.s(14), r.s(16), 0),
          child: Row(
            children: [
              _filterChip('7 дней', _period == 0, _Palette.green,
                      () => setState(() => _period = 0), r),
              SizedBox(width: r.s(6)),
              _filterChip('30 дней', _period == 1, _Palette.green,
                      () => setState(() => _period = 1), r),
              SizedBox(width: r.s(6)),
              _filterChip('Всё время', _period == 2, _Palette.green,
                      () => setState(() => _period = 2), r),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(r.s(16), r.s(10), r.s(16), 0),
          child: Container(
            padding: EdgeInsets.all(r.s(16)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_Palette.green, Color(0xFF2D4A3E)],
              ),
              borderRadius: BorderRadius.circular(r.s(20)),
              boxShadow: [
                BoxShadow(
                  color: _Palette.green.withOpacity(0.25),
                  blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ПОТРАЧЕНО',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: r.fs(9), fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          )),
                      SizedBox(height: r.s(4)),
                      Text('${totalSpent.round()} ₽',
                          style: GoogleFonts.inter(
                            color: Colors.white, fontSize: r.fs(26),
                            fontWeight: FontWeight.w800, letterSpacing: -1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${bought.length} ${_itemsWord(bought.length)}',
                        style: GoogleFonts.inter(
                          color: Colors.white, fontSize: r.fs(13),
                          fontWeight: FontWeight.w700,
                        )),
                    SizedBox(height: r.s(2)),
                    Text('за период',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: r.fs(10),
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(r.s(16), r.s(10), r.s(16), r.s(6)),
          child: Row(
            children: [
              _filterChip('📅 По дням', _historyMode == 0, _Palette.peach,
                      () => setState(() => _historyMode = 0), r),
              SizedBox(width: r.s(6)),
              _filterChip('🧀 Продукты', _historyMode == 1, _Palette.peach,
                      () => setState(() => _historyMode = 1), r),
              SizedBox(width: r.s(6)),
              _filterChip('🏬 Отделы', _historyMode == 2, _Palette.peach,
                      () => setState(() => _historyMode = 2), r),
            ],
          ),
        ),
        Expanded(
          child: bought.isEmpty
              ? _empty('🧾', 'Пока нет покупок',
              'Отмечай купленное в списке — история соберётся здесь', r)
              : _historyMode == 0
              ? _historyByDays(bought, provider, r)
              : _historyMode == 1
              ? _historyByProducts(bought, provider, r)
              : _historyByAisles(bought, provider, r),
        ),
      ],
    );
  }

  Widget _historyByDays(
      List<ShoppingItem> bought, NutritionProvider provider, _R r) {
    final groups = <String, List<ShoppingItem>>{};
    for (final item in bought) {
      groups.putIfAbsent(_dayLabel(item.createdAt), () => []).add(item);
    }
    final keys = groups.keys.toList();
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(100)),
      itemCount: keys.length,
      separatorBuilder: (_, __) => SizedBox(height: r.s(12)),
      itemBuilder: (_, i) {
        final day = keys[i];
        final items = groups[day]!;
        final dayTotal = items.fold<double>(0, (s, x) => s + x.totalPrice);
        return Container(
          decoration: BoxDecoration(
            color: _Palette.surface,
            borderRadius: BorderRadius.circular(r.s(18)),
            border: Border.all(color: Colors.white.withOpacity(0.95)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12, spreadRadius: -4, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(r.s(14), r.s(12), r.s(14), r.s(8)),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: r.s(10), vertical: r.s(5)),
                      decoration: BoxDecoration(
                        color: _Palette.peachSoft,
                        borderRadius: BorderRadius.circular(r.s(8)),
                      ),
                      child: Text(day,
                          style: GoogleFonts.inter(
                            color: _Palette.peach, fontSize: r.fs(11),
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                    SizedBox(width: r.s(8)),
                    Text('${items.length} ${_itemsWord(items.length)}',
                        style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(11),
                        )),
                    const Spacer(),
                    if (dayTotal > 0)
                      Text('${dayTotal.round()} ₽',
                          style: GoogleFonts.inter(
                            color: _Palette.green, fontSize: r.fs(13),
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                  ],
                ),
              ),
              ...items.map((item) {
                final product = provider.products
                    .where((p) => p.id == item.productId).firstOrNull;
                return Padding(
                  padding: EdgeInsets.fromLTRB(r.s(14), 0, r.s(14), r.s(10)),
                  child: Row(
                    children: [
                      Text(product?.categoryEmoji ?? '📦',
                          style: TextStyle(fontSize: r.fs(15))),
                      SizedBox(width: r.s(10)),
                      Expanded(
                        child: Text(item.displayName,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(12.5),
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      SizedBox(width: r.s(8)),
                      Text(
                        '${_fmtNum(item.quantity)} ${item.unit} · '
                            '${item.createdAt.hour.toString().padLeft(2, '0')}:'
                            '${item.createdAt.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(10.5),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (item.totalPrice > 0) ...[
                        SizedBox(width: r.s(8)),
                        Text('${item.totalPrice.round()} ₽',
                            style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(11.5),
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            )),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _historyByProducts(
      List<ShoppingItem> bought, NutritionProvider provider, _R r) {
    final map = <String, _ProductStat>{};
    for (final item in bought) {
      final key = item.displayName.toLowerCase().trim();
      final product =
          provider.products.where((p) => p.id == item.productId).firstOrNull;
      final stat = map.putIfAbsent(
          key,
              () => _ProductStat(
              name: item.displayName,
              emoji: product?.categoryEmoji ?? '📦'));
      stat.count++;
      stat.spent += item.totalPrice;
      if (item.createdAt.isAfter(stat.lastAt)) {
        stat.lastAt = item.createdAt;
        stat.lastQty = item.quantity;
        stat.unit = item.unit;
      }
    }
    final stats = map.values.toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));
    final maxSpent =
    stats.isEmpty ? 0.0 : stats.first.spent.clamp(1, double.infinity);

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(100)),
      itemCount: stats.length,
      separatorBuilder: (_, __) => SizedBox(height: r.s(8)),
      itemBuilder: (_, i) {
        final s = stats[i];
        return Container(
          padding: EdgeInsets.all(r.s(12)),
          decoration: BoxDecoration(
            color: _Palette.surface,
            borderRadius: BorderRadius.circular(r.s(16)),
            border: Border.all(color: Colors.white.withOpacity(0.95)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: r.s(22),
                child: Text('${i + 1}',
                    style: GoogleFonts.inter(
                      color: _Palette.textMuted, fontSize: r.fs(11),
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ),
              Text(s.emoji, style: TextStyle(fontSize: r.fs(18))),
              SizedBox(width: r.s(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: _Palette.text, fontSize: r.fs(12.5),
                          fontWeight: FontWeight.w600,
                        )),
                    SizedBox(height: r.s(2)),
                    Text(
                        '${s.count} ${_timesWord(s.count)} · '
                            'последний ${_fmtNum(s.lastQty)} ${s.unit}',
                        style: GoogleFonts.inter(
                          color: _Palette.textMuted, fontSize: r.fs(10),
                        )),
                    SizedBox(height: r.s(5)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: (s.spent / maxSpent).clamp(0.0, 1.0),
                        minHeight: r.s(4),
                        backgroundColor: _Palette.divider,
                        valueColor:
                        const AlwaysStoppedAnimation(_Palette.peach),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: r.s(10)),
              Text('${s.spent.round()} ₽',
                  style: GoogleFonts.inter(
                    color: _Palette.text, fontSize: r.fs(13),
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _historyByAisles(
      List<ShoppingItem> bought, NutritionProvider provider, _R r) {
    final map = <String, _AisleStat>{};
    for (final item in bought) {
      final product =
          provider.products.where((p) => p.id == item.productId).firstOrNull;
      final aisle = (item.category != null && item.category!.isNotEmpty)
          ? item.category!
          : _categoryToAisle(product?.category ?? 'other');
      final stat = map.putIfAbsent(aisle, () => _AisleStat(aisle));
      stat.count++;
      stat.spent += item.totalPrice;
      if (item.totalPrice > stat.topSpent) {
        stat.topSpent = item.totalPrice;
        stat.topProduct = item.displayName;
      }
    }
    final stats = map.values.toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));
    final total = stats.fold<double>(0, (s, x) => s + x.spent);

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(100)),
      itemCount: stats.length,
      separatorBuilder: (_, __) => SizedBox(height: r.s(8)),
      itemBuilder: (_, i) {
        final s = stats[i];
        final accent = _aisleAccent(s.aisle);
        final pct = total > 0 ? s.spent / total : 0.0;
        return Container(
          padding: EdgeInsets.all(r.s(14)),
          decoration: BoxDecoration(
            color: _Palette.surface,
            borderRadius: BorderRadius.circular(r.s(18)),
            border: Border.all(color: accent.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: r.s(40), height: r.s(40),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(r.s(12)),
                    ),
                    alignment: Alignment.center,
                    child: Text(_aisleEmoji(s.aisle),
                        style: TextStyle(fontSize: r.fs(18))),
                  ),
                  SizedBox(width: r.s(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.aisle,
                            style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(13.5),
                              fontWeight: FontWeight.w700,
                            )),
                        Text(
                            '${s.count} ${_itemsWord(s.count)}'
                                '${s.topProduct.isNotEmpty ? ' · топ: ${s.topProduct}' : ''}',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: _Palette.textMuted, fontSize: r.fs(10),
                            )),
                      ],
                    ),
                  ),
                  SizedBox(width: r.s(8)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${s.spent.round()} ₽',
                          style: GoogleFonts.inter(
                            color: _Palette.text, fontSize: r.fs(13),
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                      Text('${(pct * 100).round()}%',
                          style: GoogleFonts.inter(
                            color: accent, fontSize: r.fs(10),
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ],
              ),
              SizedBox(height: r.s(8)),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: r.s(5),
                  backgroundColor: _Palette.divider,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ВКЛАДКА 3 — БАЗА ПОКУПОК (без повторов)
  // ═══════════════════════════════════════════════════════════════
  Widget _catalogTab(NutritionProvider provider, _R r) {
    final bought =
    provider.shoppingItems.where((i) => i.isBought).toList();
    final map = <String, _CatalogEntry>{};
    for (final item in bought) {
      final pid = item.productId;
      final hasPid = pid != null && pid.isNotEmpty;
      final key =
      hasPid ? 'p:$pid' : 'n:${item.displayName.toLowerCase().trim()}';
      final product =
          provider.products.where((p) => p.id == pid).firstOrNull;
      final e = map.putIfAbsent(
          key,
              () => _CatalogEntry(
            key: key,
            name: item.displayName,
            emoji: product?.categoryEmoji ?? '📦',
            productId: pid,
          ));
      e.count++;
      e.totalSpent += item.totalPrice;
      if (item.createdAt.isAfter(e.lastAt)) {
        e.lastAt = item.createdAt;
        e.lastQty = item.quantity;
        e.unit = item.unit;
        e.lastPrice = item.estimatedPrice;
        e.lastBasis = item.priceBasis;
        e.category = item.category ?? e.category;
        e.fallback = item.fallbackName ?? e.fallback;
      }
    }

    final query = _catalogSearch.text.trim().toLowerCase();
    final entries = map.values
        .where((e) => query.isEmpty || e.name.toLowerCase().contains(query))
        .toList();
    switch (_catalogSort) {
      case 0:
        entries.sort((a, b) => b.count.compareTo(a.count));
        break;
      case 1:
        entries.sort((a, b) => b.lastAt.compareTo(a.lastAt));
        break;
      default:
        entries.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    final active = provider.activeShoppingList;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(r.s(16), r.s(14), r.s(16), 0),
          child: _searchField(_catalogSearch, 'Поиск в базе…', r),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(r.s(16), r.s(10), r.s(16), r.s(6)),
          child: Row(
            children: [
              _filterChip('🔥 Чаще', _catalogSort == 0, _Palette.brown,
                      () => setState(() => _catalogSort = 0), r),
              SizedBox(width: r.s(6)),
              _filterChip('🕐 Недавние', _catalogSort == 1, _Palette.brown,
                      () => setState(() => _catalogSort = 1), r),
              SizedBox(width: r.s(6)),
              _filterChip('А–Я', _catalogSort == 2, _Palette.brown,
                      () => setState(() => _catalogSort = 2), r),
              const Spacer(),
              Text('${entries.length}',
                  style: GoogleFonts.inter(
                    color: _Palette.textMuted, fontSize: r.fs(11),
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? _empty('📚', 'База пуста',
              'Каждый купленный продукт появится здесь один раз — для быстрого повтора', r)
              : ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(100)),
            itemCount: entries.length,
            separatorBuilder: (_, __) => SizedBox(height: r.s(8)),
            itemBuilder: (_, i) {
              final e = entries[i];
              final inList = active
                  .where((s) =>
              s.displayName.toLowerCase().trim() ==
                  e.name.toLowerCase().trim())
                  .length;
              return _catalogTile(e, inList, provider, r);
            },
          ),
        ),
      ],
    );
  }

  Widget _catalogTile(_CatalogEntry e, int inList,
      NutritionProvider provider, _R r) {
    return _TapScale(
      onTap: () => _quickAdd(e, provider),
      child: Container(
        padding: EdgeInsets.all(r.s(12)),
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(r.s(18)),
          border: Border.all(color: Colors.white.withOpacity(0.95)),
          boxShadow: [
            BoxShadow(
              color: _Palette.brown.withOpacity(0.06),
              blurRadius: 12, spreadRadius: -4, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: r.s(44), height: r.s(44),
              decoration: BoxDecoration(
                color: _Palette.brownSoft,
                borderRadius: BorderRadius.circular(r.s(13)),
              ),
              alignment: Alignment.center,
              child: Text(e.emoji, style: TextStyle(fontSize: r.s(20))),
            ),
            SizedBox(width: r.s(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(e.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: _Palette.text, fontSize: r.fs(13),
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      if (inList > 0)
                        Container(
                          margin: EdgeInsets.only(left: r.s(6)),
                          padding: EdgeInsets.symmetric(
                              horizontal: r.s(6), vertical: r.s(2)),
                          decoration: BoxDecoration(
                            color: _Palette.greenSoft,
                            borderRadius: BorderRadius.circular(r.s(6)),
                          ),
                          child: Text('в списке${inList > 1 ? ' ×$inList' : ''}',
                              style: GoogleFonts.inter(
                                color: _Palette.green, fontSize: r.fs(8.5),
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                    ],
                  ),
                  SizedBox(height: r.s(3)),
                  Text(
                    'куплен ${e.count} ${_timesWord(e.count)} · '
                        '${_fmtNum(e.lastQty)} ${e.unit} · ${_shortDate(e.lastAt)}'
                        '${e.lastPrice != null && e.lastPrice! > 0 ? ' · ${e.lastPrice!.round()} ₽' : ''}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _Palette.textMuted, fontSize: r.fs(10.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: r.s(8)),
            Container(
              width: r.s(36), height: r.s(36),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF3DDC84), _Palette.green],
                ),
                borderRadius: BorderRadius.circular(r.s(11)),
                boxShadow: [
                  BoxShadow(
                    color: _Palette.green.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.add_rounded, color: Colors.white, size: r.s(18)),
            ),
          ],
        ),
      ),
    );
  }

  void _quickAdd(_CatalogEntry e, NutritionProvider provider) {
    provider.addShoppingItem(
      productId: e.productId,
      customName: e.name,
      quantity: e.lastQty,
      unit: e.unit,
      estimatedPrice: e.lastPrice,
      priceBasis: e.lastBasis ?? PriceBasis.perKg,
      fallbackName: e.fallback,
      category: e.category,
    );
    HapticFeedback.mediumImpact();
    _snack('🛒 «${e.name}» → в список покупок', _Palette.green);
  }

  // ═══════════════════════════════════════════════════════════════
  //  ОБЩИЕ ЭЛЕМЕНТЫ
  // ═══════════════════════════════════════════════════════════════
  Widget _searchField(TextEditingController ctrl, String hint, _R r) {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(r.s(14)),
        border: Border.all(color: _Palette.divider),
      ),
      padding: EdgeInsets.symmetric(horizontal: r.s(14)),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: _Palette.textMuted, size: r.s(18)),
          SizedBox(width: r.s(10)),
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(
                  color: _Palette.text, fontSize: r.fs(13.5)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                    color: _Palette.textMuted, fontSize: r.fs(13)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: r.s(13)),
              ),
            ),
          ),
          if (ctrl.text.isNotEmpty)
            _TapScale(
              onTap: () => setState(() => ctrl.clear()),
              child: Icon(Icons.close_rounded,
                  color: _Palette.textMuted, size: r.s(16)),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, Color color,
      VoidCallback onTap, _R r) {
    return _TapScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: r.s(11), vertical: r.s(7)),
        decoration: BoxDecoration(
          color: selected ? color : _Palette.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: selected ? color : _Palette.divider, width: 1),
          boxShadow: selected
              ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : _Palette.text,
              fontSize: r.fs(11), fontWeight: FontWeight.w700,
            )),
      ),
    );
  }

  Widget _empty(String emoji, String title, String subtitle, _R r) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(r.s(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: r.fs(40))),
            SizedBox(height: r.s(12)),
            Text(title,
                style: GoogleFonts.inter(
                  color: _Palette.text, fontSize: r.fs(16),
                  fontWeight: FontWeight.w600,
                )),
            SizedBox(height: r.s(6)),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _Palette.textMuted, fontSize: r.fs(12), height: 1.4,
                )),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(String title, String text, String action) async {
    final r = _R(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.s(20))),
        title: Text(title,
            style: GoogleFonts.inter(
              color: _Palette.text, fontSize: r.fs(16),
              fontWeight: FontWeight.w600,
            )),
        content: Text(text,
            style: GoogleFonts.inter(
                color: _Palette.textMuted, fontSize: r.fs(13))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Отмена',
                style: GoogleFonts.inter(color: _Palette.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _Palette.pink),
            child: Text(action,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result == true;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAP SCALE
// ═══════════════════════════════════════════════════════════════════
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScale({required this.child, required this.onTap});
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
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}