import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/nutrition_models.dart';

class BarcodeLookupService {
  BarcodeLookupService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _ua = 'ZalLife/1.0 (Flutter; personal nutrition app)';
  static const _timeout = Duration(seconds: 8);

  Map<String, String> get _headers => {
    'User-Agent': _ua,
    'Accept': 'application/json',
  };

  void dispose() => _client.close();

  static bool isInternalBarcode(String code) => code.length >= 8 && code.startsWith('2');

  static String? extractGtin(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll('\u001D', '|');
    final ai01 = RegExp(r'(?:^|\|)01(\d{14})').firstMatch(cleaned);
    if (ai01 != null) return _gtin14to13(ai01.group(1)!);
    final digits = RegExp(r'\d+').stringMatch(s) ?? '';
    if (digits.length == 14 && digits.startsWith('0')) return digits.substring(1);
    if (digits.length == 13 || digits.length == 12 || digits.length == 8) return digits;
    return null;
  }

  static String _gtin14to13(String g14) => g14.startsWith('0') ? g14.substring(1) : g14;

  static String? countryFromBarcode(String code) {
    if (code.length < 3) return null;
    if (isInternalBarcode(code)) return 'Внутренний код магазина';
    final p = int.tryParse(code.substring(0, 3));
    if (p == null) return null;
    if (p >= 460 && p <= 469) return 'Россия 🇷🇺';
    if (p >= 400 && p <= 440) return 'Германия 🇩🇪';
    if (p >= 300 && p <= 379) return 'Франция 🇫🇷';
    if (p >= 500 && p <= 509) return 'Великобритания 🇬🇧';
    if (p >= 0 && p <= 139) return 'США/Канада 🇺🇸';
    if (p >= 690 && p <= 699) return 'Китай 🇨🇳';
    if (p == 481) return 'Беларусь 🇧🇾';
    if (p == 487) return 'Казахстан 🇰🇿';
    if (p >= 480 && p <= 480) return 'Филиппины 🇵🇭';
    if (p == 471) return 'Тайвань';
    if (p >= 450 && p <= 459) return 'Япония 🇯🇵';
    if (p >= 490 && p <= 499) return 'Япония 🇯🇵';
    if (p >= 868 && p <= 869) return 'Турция 🇹🇷';
    if (p == 590) return 'Польша 🇵🇱';
    if (p >= 800 && p <= 839) return 'Италия 🇮🇹';
    if (p >= 840 && p <= 849) return 'Испания 🇪🇸';
    if (p >= 870 && p <= 879) return 'Нидерланды 🇳🇱';
    if (p >= 540 && p <= 549) return 'Бельгия 🇧🇪';
    if (p >= 570 && p <= 579) return 'Дания 🇩🇰';
    if (p >= 640 && p <= 649) return 'Финляндия 🇫🇮';
    if (p >= 730 && p <= 739) return 'Швеция 🇸🇪';
    if (p >= 700 && p <= 709) return 'Норвегия 🇳🇴';
    if (p >= 760 && p <= 769) return 'Швейцария 🇨🇭';
    if (p >= 900 && p <= 919) return 'Австрия 🇦🇹';
    if (p >= 930 && p <= 939) return 'Австралия 🇦🇺';
    if (p >= 940 && p <= 949) return 'Новая Зеландия 🇳🇿';
    if (p >= 474 && p <= 474) return 'Эстония 🇪🇪';
    if (p >= 475 && p <= 475) return 'Латвия 🇱🇻';
    if (p >= 477 && p <= 477) return 'Литва 🇱🇹';
    if (p >= 482 && p <= 482) return 'Украина 🇺🇦';
    return null;
  }

  static final String _offFields = [
    'code', 'product_name', 'product_name_ru', 'product_name_en',
    'generic_name', 'generic_name_ru', 'generic_name_en',
    'abbreviated_product_name', 'brands', 'categories_tags',
    'quantity', 'product_quantity', 'nutriments',
    'image_front_url', 'image_url', 'labels_tags',
  ].join(',');

  Future<BarcodeProduct?> fetchOpenFoodFacts(String barcode) async {
    final v2 = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode?fields=$_offFields&lc=ru',
    );
    var p = await _getProductJson(v2);
    if (p == null) {
      final v0 = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      p = await _getProductJson(v0);
    }
    if (p == null) return null;
    return _parseOffProduct(barcode, p);
  }

  Future<Map<String, dynamic>?> _getProductJson(Uri url) async {
    try {
      debugPrint('🌐 GET $url');
      final r = await _client.get(url, headers: _headers).timeout(_timeout);
      if (r.statusCode != 200) {
        debugPrint('⚠️ HTTP ${r.statusCode}');
        return null;
      }
      final data = jsonDecode(r.body);
      if (data is! Map) return null;
      final product = data['product'];
      if (product is Map && product.isNotEmpty) {
        debugPrint('✅ OFF: документ получен (status=${data['status']})');
        return Map<String, dynamic>.from(product);
      }
      debugPrint('⚠️ OFF: status=${data['status']} — товара нет');
    } catch (e) {
      debugPrint('❌ OFF ошибка: $e');
    }
    return null;
  }

  BarcodeProduct _parseOffProduct(String barcode, Map<String, dynamic> p) {
    final nutr = (p['nutriments'] as Map?)?.cast<String, dynamic>() ?? {};
    final cats = ((p['categories_tags'] as List?) ?? []).join(' ').toLowerCase();
    final name = _firstNonEmpty([
      p['product_name_ru'],
      p['abbreviated_product_name'],
      p['product_name'],
      p['generic_name_ru'],
      p['generic_name'],
      p['product_name_en'],
      p['generic_name_en'],
    ]);
    final brand = _firstNonEmpty([p['brands']]);
    double kcal = _num(nutr['energy-kcal_100g']);
    if (kcal <= 0) {
      final kj = _num(nutr['energy-kj_100g']);
      final generic = _num(nutr['energy_100g']);
      final source = kj > 0 ? kj : generic;
      if (source > 0) kcal = source / 4.184;
    }
    double? pack = _numOrNull(p['product_quantity']);
    pack ??= _parseQuantity(p['quantity'] as String?);
    return BarcodeProduct(
      barcode: barcode,
      name: name,
      brand: brand,
      category: guessCategory(cats),
      calories: kcal,
      protein: _num(nutr['proteins_100g']),
      fat: _num(nutr['fat_100g']),
      carbs: _num(nutr['carbohydrates_100g']),
      fiber: _num(nutr['fiber_100g']),
      packageGrams: pack,
      imageUrl: (p['image_front_url'] ?? p['image_url']) as String?,
      rawCategories: cats.isEmpty ? null : cats,
      source: BarcodeSource.openFoodFacts,
    );
  }

  Future<List<OnlineHit>> searchByName(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final url = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl'
          '?search_terms=${Uri.encodeQueryComponent(q)}'
          '&search_simple=1&action=process&json=1&page_size=25'
          '&fields=code,product_name,product_name_ru,brands,nutriments',
    );
    try {
      final r = await _client.get(url, headers: _headers).timeout(_timeout);
      if (r.statusCode != 200) return const [];
      final data = jsonDecode(r.body);
      final list = (data['products'] as List?) ?? const [];
      final out = <OnlineHit>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final n = _firstNonEmpty([m['product_name_ru'], m['product_name']]);
        if (n == null) continue;
        final nu = (m['nutriments'] as Map?)?.cast<String, dynamic>() ?? {};
        out.add(OnlineHit(
          barcode: m['code'] as String?,
          name: n,
          brand: _firstNonEmpty([m['brands']]),
          calories: _num(nu['energy-kcal_100g']),
          protein: _num(nu['proteins_100g']),
          fat: _num(nu['fat_100g']),
          carbs: _num(nu['carbohydrates_100g']),
        ));
      }
      return out;
    } catch (e) {
      debugPrint('❌ OFF search: $e');
      return const [];
    }
  }

  Future<BarcodeProduct?> fetchUpcItemDb(String barcode) async {
    final url = Uri.parse('https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode');
    try {
      final r = await _client.get(url, headers: _headers).timeout(_timeout);
      if (r.statusCode == 429) {
        debugPrint('⚠️ UPCitemdb: лимит запросов на сегодня');
        return null;
      }
      if (r.statusCode != 200) return null;
      final data = jsonDecode(r.body);
      final items = (data['items'] as List?) ?? const [];
      if (items.isEmpty) return null;
      final m = Map<String, dynamic>.from(items.first as Map);
      final title = _firstNonEmpty([m['title']]);
      if (title == null) return null;
      final images = (m['images'] as List?) ?? const [];
      return BarcodeProduct(
        barcode: barcode,
        name: title,
        brand: _firstNonEmpty([m['brand']]),
        category: guessCategory('${m['category'] ?? ''}'.toLowerCase()),
        imageUrl: images.isNotEmpty ? images.first as String? : null,
        source: BarcodeSource.upcItemDb,
      );
    } catch (e) {
      debugPrint('❌ UPCitemdb: $e');
      return null;
    }
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
      if (s.isEmpty || s.toLowerCase() == 'null') continue;
      return s[0].toUpperCase() + s.substring(1);
    }
    return null;
  }

  static double _num(dynamic v) => _numOrNull(v) ?? 0;

  static double? _numOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  static double? _parseQuantity(String? q) {
    if (q == null) return null;
    final m = RegExp(r'(\d+(?:[.,]\d+)?)\s*(кг|г|kg|g|мл|ml|л|l)\b', caseSensitive: false).firstMatch(q);
    if (m == null) return null;
    final v = double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0;
    final u = m.group(2)!.toLowerCase();
    if (u == 'кг' || u == 'kg' || u == 'л' || u == 'l') return v * 1000;
    return v;
  }

  static String guessCategory(String cats) {
    String has(List<String> k) => k.any((e) => cats.contains(e)) ? 'y' : '';
    if (has(['dairy', 'milk', 'cheese', 'yogurt', 'молоко', 'сыр']) == 'y') return 'dairy';
    if (has(['meat', 'poultry', 'beef', 'pork', 'мясо']) == 'y') return 'meat';
    if (has(['fish', 'seafood', 'рыба']) == 'y') return 'fish';
    if (has(['fruit', 'фрукт']) == 'y') return 'fruits';
    if (has(['vegetable', 'овощ']) == 'y') return 'vegetables';
    if (has(['beverage', 'drink', 'juice', 'coffee', 'tea', 'water', 'напит']) == 'y') return 'drinks';
    if (has(['bread', 'bakery', 'хлеб']) == 'y') return 'bakery';
    if (has(['cereal', 'grain', 'pasta', 'rice', 'круп', 'макарон']) == 'y') return 'grains';
    if (has(['sweet', 'chocolate', 'candy', 'confection', 'слад', 'шоколад']) == 'y') return 'sweets';
    if (has(['oil', 'fat', 'масло']) == 'y') return 'oils';
    if (has(['sauce', 'соус', 'spice', 'salt', 'соль', 'специ']) == 'y') return 'sauces';
    if (has(['nut', 'орех']) == 'y') return 'nuts';
    if (has(['legume', 'bean', 'бобов']) == 'y') return 'legumes';
    return 'other';
  }

  static const Map<String, List<String>> basicGoodsRu = {
    'salt': ['Соль'], 'соль': ['Соль'], 'sugar': ['Сахар'], 'сахар': ['Сахар'],
    'flour': ['Мука', 'Рисовая мука', 'Овсяная мука'], 'мука': ['Мука'],
    'milk': ['Молоко 2.5%', 'Молоко 3.2%'], 'молоко': ['Молоко'],
    'coffee': ['Кофе чёрный', 'Кофе латте'], 'кофе': ['Кофе'],
    'tea': ['Чай чёрный', 'Чай зелёный'], 'чай': ['Чай'],
    'water': ['Вода'], 'вода': ['Вода'],
    'rice': ['Рис белый варёный', 'Рис белый сухой'], 'рис': ['Рис'],
    'buckwheat': ['Гречка варёная', 'Гречка сухая'], 'греч': ['Гречка'],
    'pasta': ['Макароны варёные', 'Макароны сухие'], 'макарон': ['Макароны'],
    'butter': ['Масло сливочное 82.5%'], 'cheese': ['Сыр твёрдый'], 'сыр': ['Сыр'],
    'egg': ['Яйцо куриное'], 'яйц': ['Яйцо'],
    'bread': ['Хлеб цельнозерновой', 'Хлеб белый'], 'хлеб': ['Хлеб'],
    'oil': ['Масло подсолнечное', 'Масло оливковое'],
    'honey': ['Мёд'], 'мёд': ['Мёд'], 'мед ': ['Мёд'],
    'oat': ['Овсянка', 'Овсяные хлопья'], 'овся': ['Овсянка'],
    'cocoa': ['Какао'], 'какао': ['Какао'],
    'pepper': ['Чёрный перец молотый'], 'перец': ['Перец'],
    'cinnamon': ['Корица'], 'корица': ['Корица'],
    'cottage': ['Творог 5%'], 'творог': ['Творог'],
    'kefir': ['Кефир 1%'], 'кефир': ['Кефир'],
    'chicken': ['Куриная грудка'], 'кури': ['Куриная грудка'],
  };
}