import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import 'barcode_lookup_service.dart';
import 'barcode_sheets.dart';

// ═══════════════════════════════════════════════════════════════
//  Design tokens
// ═══════════════════════════════════════════════════════════════
class _P {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF7C818A);
  static const divider = Color(0xFFE9EBEF);
  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF6C9E88);
  static const skySoft = Color(0xFFE8EFF8);
  static const skyDeep = Color(0xFF7E9DC6);
  static const peachSoft = Color(0xFFFBEDE4);
  static const peachDeep = Color(0xFFEF9563);
  static const yellowDeep = Color(0xFFE0B054);
  static const pinkDeep = Color(0xFFD17A8F);
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF9381BB);
  static const brownSoft = Color(0xFFF3E9DC);
  static const brownDeep = Color(0xFFA87B4F);
}

enum ScanDestination { pantry, shopping, diary }

class AddPantryScreen extends StatefulWidget {
  const AddPantryScreen({super.key});
  @override
  State<AddPantryScreen> createState() => _AddPantryScreenState();
}

class _AddPantryScreenState extends State<AddPantryScreen> {
  bool _isScanning = false;
  String _scanMode = 'none';
  bool _isProcessingOCR = false;
  bool _cameraLoading = false;

  bool _isBatchMode = false;
  final List<BarcodeProduct> _batchItems = [];
  DateTime? _lastScanTime;

  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'г');
  final _barcodeCtrl = TextEditingController();
  DateTime? _expiresAt;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _scannerController.stop();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _barcodeCtrl.dispose();
    _textRecognizer.close();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _startScanner() async {
    final status = await Permission.camera.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final requested = await Permission.camera.request();
      if (!requested.isGranted) {
        if (!mounted) return;
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _scanMode = 'barcode';
      _isScanning = true;
      _cameraLoading = true;
    });

    try {
      await _scannerController.start();
      if (mounted) setState(() => _cameraLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _cameraLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Камера недоступна: ${e.toString()}'),
            backgroundColor: _P.peachDeep,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Нужен доступ к камере'),
        content: const Text(
            'Чтобы сканировать штрихкоды, разреши приложению использовать камеру в настройках.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text('Открыть настройки',
                style: GoogleFonts.inter(color: _P.skyDeep, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showOcrSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 16),
            Text('ОТКУДА ВЗЯТЬ ЭТИКЕТКУ?', style: _overline),
            const SizedBox(height: 16),
            _scanButton(
              icon: Icons.camera_alt_rounded,
              title: 'Сфотографировать',
              subtitle: 'Навести на этикетку',
              color: _P.skyDeep,
              softColor: _P.skySoft,
              onTap: () {
                Navigator.pop(context);
                _processImageOCR(source: ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            _scanButton(
              icon: Icons.photo_library_rounded,
              title: 'Выбрать из галереи',
              subtitle: 'Готовое фото',
              color: _P.lavenderDeep,
              softColor: _P.lavenderSoft,
              onTap: () {
                Navigator.pop(context);
                _processImageOCR(source: ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _processImageOCR({required ImageSource source}) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final requested = await Permission.camera.request();
        if (!requested.isGranted) {
          _showPermissionDeniedDialog();
          return;
        }
      }
    }

    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    if (!mounted) return;
    setState(() => _isProcessingOCR = true);

    final inputImage = InputImage.fromFilePath(image.path);
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final parsed = context.read<NutritionProvider>().parseOCRLabel(recognizedText.text);

      final firstLine = recognizedText.text
          .split('\n')
          .firstWhere((line) => line.trim().isNotEmpty && line.trim().length > 2, orElse: () => '');

      if (mounted) {
        setState(() {
          _nameCtrl.text =
          firstLine.isNotEmpty && !RegExp(r'^\d').hasMatch(firstLine) ? firstLine : '';
          if (parsed['quantity'] != null) _qtyCtrl.text = parsed['quantity'].toString();
          if (parsed['unit'] != null) _unitCtrl.text = parsed['unit'];
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(parsed['quantity'] != null
              ? 'Распознано: ${parsed['quantity']} ${parsed['unit']}. Проверь название!'
              : 'Текст распознан, но вес/ед. изм. не найдены. Заполни вручную.'),
          backgroundColor: _P.skyDeep,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Не удалось распознать текст. Попробуйте другое фото.'),
          backgroundColor: _P.peachDeep,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessingOCR = false);
    }
  }

  Future<void> _handleBarcode(String rawCode) async {
    final provider = context.read<NutritionProvider>();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔍 Ищем продукт...'),
          backgroundColor: _P.skyDeep,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }

    final result = await provider.lookupBarcode(rawCode);

    if (!mounted) return;

    if (_isBatchMode) {
      await _handleBatchScan(result, rawCode);
      return;
    }

    if (result.isSuccess) {
      final confirmed = await showBarcodeResultSheet(
        context,
        result.product!,
        hint: result.hint,
        provider: provider,
      );
      if (confirmed == null || !mounted) return;

      final saved = await provider.saveScannedProduct(confirmed);
      await provider.addToScanHistory(confirmed); // ИСПРАВЛЕНО: передаём BarcodeProduct

      final destination = await _showDestinationChoice(confirmed); // ИСПРАВЛЕНО: передаём BarcodeProduct
      if (destination == null || !mounted) return;

      await _sendToDestination(confirmed, destination, productId: saved.id); // ИСПРАВЛЕНО

      if (!mounted) return;
      Navigator.pop(context);
      HapticFeedback.mediumImpact();
    } else {
      final choice = await showBarcodeNotFoundSheet(
        context,
        provider: provider,
        barcode: rawCode,
        hint: result.hint,
      );
      if (choice == null || !mounted) return;

      await _handleNotFoundChoice(choice, rawCode);
    }
  }

  Future<void> _handleBatchScan(BarcodeLookupResult result, String rawCode) async {
    final provider = context.read<NutritionProvider>();

    BarcodeProduct? product = result.product;

    if (product == null) {
      final name = await _showQuickNameDialog(rawCode);
      if (name == null || !mounted) {
        await _scannerController.start();
        return;
      }
      product = BarcodeProduct(
        barcode: rawCode,
        name: name,
        category: 'other',
        source: BarcodeSource.manual,
      );
    }

    final saved = await provider.saveScannedProduct(product);
    await provider.addToScanHistory(product); // ИСПРАВЛЕНО: передаём BarcodeProduct

    await provider.addShoppingItem(
      productId: saved.id,
      customName: saved.name,
      quantity: 1,
      unit: 'шт',
    );

    setState(() {
      _batchItems.add(product!);
      _lastScanTime = DateTime.now();
    });

    HapticFeedback.mediumImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${saved.name} • В корзине ${_batchItems.length} шт'),
          backgroundColor: _P.greenDeep,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String?> _showQuickNameDialog(String barcode) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Не найдено: $barcode', style: GoogleFonts.inter(fontSize: 14)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Введи название продукта'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Пропустить')),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()),
            child: Text('Добавить',
                style: GoogleFonts.inter(color: _P.skyDeep, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotFoundChoice(NotFoundChoice choice, String barcode) async {
    final provider = context.read<NutritionProvider>();

    if (choice.local != null) {
      await provider.attachBarcodeToProduct(choice.local!.id, barcode);
      await provider.addToScanHistory(BarcodeProduct(
        barcode: barcode,
        name: choice.local!.name,
        category: choice.local!.category,
        calories: choice.local!.calories,
        protein: choice.local!.protein,
        fat: choice.local!.fat,
        carbs: choice.local!.carbs,
        fiber: choice.local!.fiber,
        source: BarcodeSource.localDb,
      ));

      final destination = await _showDestinationChoice(BarcodeProduct(
        barcode: barcode,
        name: choice.local!.name,
        category: choice.local!.category,
      ));
      if (destination != null && mounted) {
        await _sendToDestination(
          BarcodeProduct(barcode: barcode, name: choice.local!.name, category: choice.local!.category),
          destination,
          productId: choice.local!.id,
        );
      }
      if (mounted) Navigator.pop(context);
    } else if (choice.manualName != null) {
      final name = await _showManualNameDialog(choice.manualName!, barcode);
      if (name == null || !mounted) return;

      final product = BarcodeProduct(barcode: barcode, name: name, source: BarcodeSource.manual);
      await provider.saveScannedProduct(product);
      await provider.addToScanHistory(product); // ИСПРАВЛЕНО

      final destination = await _showDestinationChoice(product);
      if (destination != null && mounted) {
        await _sendToDestination(product, destination);
      }
      if (mounted) Navigator.pop(context);
    } else if (choice.retryOnline) {
      await provider.invalidateBarcodeCache(barcode);
      await _handleBarcode(barcode);
    }
  }

  Future<String?> _showManualNameDialog(String initial, String barcode) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Название продукта'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Отмена')),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()),
            child: Text('Сохранить',
                style: GoogleFonts.inter(color: _P.greenDeep, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<ScanDestination?> _showDestinationChoice(BarcodeProduct product) {
    return showModalBottomSheet<ScanDestination>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 16),
            Text('КУДА ДОБАВИТЬ?', style: _overline),
            const SizedBox(height: 8),
            Text(product.displayName,
                style: GoogleFonts.inter(color: _P.text, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _destinationTile(
              icon: Icons.kitchen_rounded,
              emoji: '🧺',
              title: 'В кладовую',
              subtitle: 'Уже есть дома — учту срок годности',
              color: _P.brownDeep,
              softColor: _P.brownSoft,
              onTap: () => Navigator.pop(context, ScanDestination.pantry),
            ),
            const SizedBox(height: 8),
            _destinationTile(
              icon: Icons.shopping_basket_rounded,
              emoji: '🛒',
              title: 'В список покупок',
              subtitle: 'Нужно купить — добавлю в корзину',
              color: _P.skyDeep,
              softColor: _P.skySoft,
              onTap: () => Navigator.pop(context, ScanDestination.shopping),
            ),
            const SizedBox(height: 8),
            _destinationTile(
              icon: Icons.restaurant_menu_rounded,
              emoji: '🍽️',
              title: 'Сразу в дневник',
              subtitle: 'Уже съел — запишу в приём пищи',
              color: _P.peachDeep,
              softColor: _P.peachSoft,
              onTap: () => Navigator.pop(context, ScanDestination.diary),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _destinationTile({
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required Color softColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: softColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(color: _P.text, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(color: _P.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _sendToDestination(BarcodeProduct product, ScanDestination dest,
      {String? productId}) async {
    final provider = context.read<NutritionProvider>();

    switch (dest) {
      case ScanDestination.pantry:
        await provider.addToPantry(
          productId: productId,
          customName: product.displayName,
          quantity: product.packageGrams ?? 1,
          unit: product.packageGrams != null ? 'г' : 'шт',
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('🧺 ${product.displayName} → в кладовой'),
            backgroundColor: _P.brownDeep,
            behavior: SnackBarBehavior.floating,
          ));
        }
        break;
      case ScanDestination.shopping:
        await provider.addShoppingItem(
          productId: productId,
          customName: product.displayName,
          quantity: 1,
          unit: 'шт',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('🛒 ${product.displayName} → в покупках'),
            backgroundColor: _P.skyDeep,
            behavior: SnackBarBehavior.floating,
          ));
        }
        break;
      case ScanDestination.diary:
        final p = provider.products.firstWhere(
              (p) => p.id == productId || p.barcode == product.barcode,
          orElse: () => provider.products.first,
        );
        await provider.addEntry(
          product: p,
          grams: product.packageGrams ?? 100,
          mealType: MealType.suggestForNow(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('🍽️ ${product.displayName} → в дневнике'),
            backgroundColor: _P.peachDeep,
            behavior: SnackBarBehavior.floating,
          ));
        }
        break;
    }
  }

  void _startBatchMode() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final requested = await Permission.camera.request();
      if (!requested.isGranted) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    setState(() {
      _isBatchMode = true;
      _batchItems.clear();
      _scanMode = 'barcode';
      _isScanning = true;
      _cameraLoading = true;
    });

    try {
      await _scannerController.start();
      if (mounted) setState(() => _cameraLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _cameraLoading = false;
          _isBatchMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Камера недоступна: ${e.toString()}'),
              backgroundColor: _P.peachDeep),
        );
      }
    }
  }

  void _finishBatchMode() {
    _scannerController.stop();
    final total = _batchItems.length;
    setState(() {
      _isScanning = false;
      _isBatchMode = false;
    });

    if (total == 0) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Закупка завершена'),
        content: Text('Добавлено $total ${_itemsWord(total)} в список покупок'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Готово',
                style: GoogleFonts.inter(color: _P.greenDeep, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _itemsWord(int n) => n == 1 ? 'позиция' : (n >= 2 && n <= 4 ? 'позиции' : 'позиций');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final recentScans = provider.recentScans;

    if (_isScanning && _scanMode == 'barcode') {
      return _buildScannerScreen(provider);
    }

    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _P.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isBatchMode ? 'ПАКЕТНАЯ ЗАКУПКА' : 'Добавить в кладовую',
          style: GoogleFonts.inter(color: _P.text, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _scanButton(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Штрихкод',
                    subtitle: 'Быстрый поиск',
                    color: _P.greenDeep,
                    softColor: _P.greenSoft,
                    onTap: _startScanner,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _scanButton(
                    icon: Icons.document_scanner_rounded,
                    title: 'Этикетка (OCR)',
                    subtitle: 'Распознать КБЖУ',
                    color: _P.skyDeep,
                    softColor: _P.skySoft,
                    onTap: _isProcessingOCR ? null : _showOcrSourcePicker,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _scanButton(
              icon: Icons.shopping_cart_rounded,
              title: 'Пакетная закупка',
              subtitle: 'Сканируй один за другим → всё в покупки',
              color: _P.lavenderDeep,
              softColor: _P.lavenderSoft,
              wide: true,
              onTap: _startBatchMode,
            ),

            if (recentScans.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('НЕДАВНО СКАНИРОВАЛИ', style: _overline),
              const SizedBox(height: 12),
              ...recentScans.take(5).map((scan) => _recentScanTile(scan, provider)),
            ],

            const SizedBox(height: 24),
            Text('ДЕТАЛИ ПРОДУКТА', style: _overline),
            const SizedBox(height: 12),
            _textField(_nameCtrl, 'Название продукта (обязательно)', Icons.shopping_basket_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _textField(_qtyCtrl, 'Количество', Icons.numbers_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _textField(_unitCtrl, 'Ед. изм.', Icons.straighten_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _textField(_barcodeCtrl, 'Штрихкод (если есть)', Icons.qr_code_rounded),
            const SizedBox(height: 24),
            Text('СРОК ГОДНОСТИ', style: _overline),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context)
                          .copyWith(colorScheme: const ColorScheme.light(primary: _P.peachDeep)),
                      child: child!,
                    );
                  },
                );
                if (date != null) setState(() => _expiresAt = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _P.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _P.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: _P.peachDeep, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _expiresAt != null
                          ? '${_expiresAt!.day}.${_expiresAt!.month.toString().padLeft(2, '0')}.${_expiresAt!.year}'
                          : 'Выберите дату',
                      style: TextStyle(
                        color: _expiresAt != null ? _P.text : _P.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_expiresAt != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: _P.textMuted),
                        onPressed: () => setState(() => _expiresAt = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameCtrl.text.trim().isEmpty || _qtyCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Введите название и количество'),
                      backgroundColor: _P.peachDeep,
                      behavior: SnackBarBehavior.floating,
                    ));
                    return;
                  }
                  await provider.addToPantry(
                    customName: _nameCtrl.text.trim(),
                    quantity: double.tryParse(_qtyCtrl.text) ?? 1,
                    unit: _unitCtrl.text.trim().isEmpty ? 'г' : _unitCtrl.text.trim(),
                    expiresAt: _expiresAt,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('✅ Добавлено в кладовую'),
                    backgroundColor: _P.greenDeep,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _P.greenDeep,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('СОХРАНИТЬ',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerScreen(NutritionProvider provider) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) async {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  if (!_isBatchMode) {
                    await _scannerController.stop();
                  } else {
                    if (_lastScanTime != null &&
                        DateTime.now().difference(_lastScanTime!).inSeconds < 3) {
                      return;
                    }
                  }
                  if (!mounted) return;
                  await _handleBarcode(barcode.rawValue!);
                  return;
                }
              }
            },
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withOpacity(0.6), width: 40),
              ),
              child: Center(
                child: Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isBatchMode ? _P.lavenderDeep : _P.greenDeep,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          if (_cameraLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                _iconButton(Icons.close_rounded, () async {
                  await _scannerController.stop();
                  if (_isBatchMode) {
                    _finishBatchMode();
                  } else {
                    setState(() => _isScanning = false);
                  }
                }),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    _isBatchMode
                        ? '🛒 ЗАКУПКА • ${_batchItems.length} шт'
                        : 'Наведите на штрихкод',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                if (_isBatchMode)
                  _iconButton(Icons.check_rounded, _finishBatchMode)
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentScanTile(ScanHistoryEntry scan, NutritionProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () async {
          final product = BarcodeProduct(
            barcode: scan.barcode,
            name: scan.name,
            category: scan.category,
            calories: scan.calories,
            protein: scan.protein,
            fat: scan.fat,
            carbs: scan.carbs,
            fiber: scan.fiber,
            source: BarcodeSource.localDb,
          );
          final destination = await _showDestinationChoice(product);
          if (destination != null && mounted) {
            await _sendToDestination(product, destination);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _P.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                BoxDecoration(color: _P.greenSoft, borderRadius: BorderRadius.circular(11)),
                alignment: Alignment.center,
                child: const Icon(Icons.qr_code_rounded, size: 18, color: _P.greenDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scan.name,
                        style: GoogleFonts.inter(color: _P.text, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(scan.barcode,
                        style: GoogleFonts.inter(color: _P.textMuted, fontSize: 10)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: _P.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color softColor,
    required VoidCallback? onTap,
    bool wide = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: softColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: _P.text, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center, style: TextStyle(color: _P.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.divider),
      ),
      child: Row(
        children: [
          Padding(padding: const EdgeInsets.only(left: 14), child: Icon(icon, color: _P.textMuted, size: 20)),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              style: const TextStyle(color: _P.text, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: _P.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _overline =>
      const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _P.textMuted);
}