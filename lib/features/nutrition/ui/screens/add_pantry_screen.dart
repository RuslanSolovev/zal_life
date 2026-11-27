// features/nutrition/ui/screens/add_pantry_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/nutrition_models.dart';
import '../../providers/nutrition_provider.dart';
import 'barcode_lookup_service.dart';
import 'barcode_sheets.dart';

// ═══════════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════
class _C {
  static const bg = Color(0xFFF7F6F2);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0E1116);
  static const muted = Color(0xFF8C9096);
  static const hairline = Color(0xFFEBEAE4);

  static const primary = Color(0xFF2F5D50);
  static const primarySoft = Color(0xFFE6F0EB);
  static const primaryDeep = Color(0xFF1B3B32);

  static const warm = Color(0xFFC97555);
  static const warmSoft = Color(0xFFFAEDE6);

  static const cool = Color(0xFF6F86A8);
  static const coolSoft = Color(0xFFEAF0F7);

  static const plum = Color(0xFF6B5A7E);
  static const plumSoft = Color(0xFFF1ECF4);

  static const gold = Color(0xFFB4884A);
  static const goldSoft = Color(0xFFF6EFE0);

  static const danger = Color(0xFFB65258);
  static const dangerSoft = Color(0xFFF8E7E8);
}

class _T {
  static TextStyle display(Color c) => GoogleFonts.inter(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.1,
    height: 1.08,
    color: c,
  );
  static TextStyle h1(Color c) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: c,
  );
  static TextStyle h2(Color c) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: c,
  );
  static TextStyle body(Color c) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: c,
  );
  static TextStyle bodySm(Color c) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: c,
  );
  static TextStyle overline(Color c) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: c,
  );
}

const _cardShadow = [
  BoxShadow(
      color: Color(0x0A0E1116),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -6),
  BoxShadow(color: Color(0x050E1116), blurRadius: 4, offset: Offset(0, 1)),
];

// ═══════════════════════════════════════════════════════════════════
//  HERO THEMES + PHOTOS
// ═══════════════════════════════════════════════════════════════════
class _HeroTheme {
  final String id;
  final String label;
  final String emoji;
  final Color top;
  final Color bottom;
  final Color accent;
  const _HeroTheme({
    required this.id,
    required this.label,
    required this.emoji,
    required this.top,
    required this.bottom,
    required this.accent,
  });
}

const List<_HeroTheme> _heroThemes = [
  _HeroTheme(
      id: 'forest',
      label: 'Лес',
      emoji: '🌲',
      top: Color(0xFF1E3B33),
      bottom: Color(0xFF0F201B),
      accent: Color(0xFF7BAE9A)),
  _HeroTheme(
      id: 'clay',
      label: 'Глина',
      emoji: '🏺',
      top: Color(0xFF6E3A2A),
      bottom: Color(0xFF3E1F14),
      accent: Color(0xFFE0A080)),
  _HeroTheme(
      id: 'dusk',
      label: 'Сумерки',
      emoji: '🌆',
      top: Color(0xFF2D3550),
      bottom: Color(0xFF161B2A),
      accent: Color(0xFF9BAAD0)),
  _HeroTheme(
      id: 'ink',
      label: 'Тушь',
      emoji: '🖋️',
      top: Color(0xFF1A1A1E),
      bottom: Color(0xFF0A0A0C),
      accent: Color(0xFFA87B4F)),
];

const List<String> _heroBackgrounds = [
  'assets/images/nature_hero.jpg',
  'assets/images/nature_hero2.jpg',
  'assets/images/nature_hero3.jpg',
  'assets/images/nature_hero4.jpg',
  'assets/images/nature_hero5.jpg',
  'assets/images/nature_hero6.jpg',
  'assets/images/nature_hero7.jpg',
];

const Map<String, String> _heroBgLabels = {
  'assets/images/nature_hero.jpg': 'Тропа',
  'assets/images/nature_hero2.jpg': 'Закат 1',
  'assets/images/nature_hero3.jpg': 'Закат 2',
  'assets/images/nature_hero4.jpg': 'Закат 3',
  'assets/images/nature_hero5.jpg': 'Лес',
  'assets/images/nature_hero6.jpg': 'Горы',
  'assets/images/nature_hero7.jpg': 'Закат 4',
};

_HeroTheme _findTheme(String id) =>
    _heroThemes.firstWhere((t) => t.id == id, orElse: () => _heroThemes.first);

bool _isImagePath(String value) => value.startsWith('assets/');

enum ScanDestination { pantry, shopping, diary }

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class AddPantryScreen extends StatefulWidget {
  const AddPantryScreen({super.key});
  @override
  State<AddPantryScreen> createState() => _AddPantryScreenState();
}

class _AddPantryScreenState extends State<AddPantryScreen>
    with TickerProviderStateMixin {
  // Camera — создаётся заново на каждую сессию (см. _startScanner)
  MobileScannerController? _scannerController;

  bool _isScanning = false;
  String _scanMode = 'none';
  bool _isProcessingOCR = false;
  bool _cameraLoading = false;
  bool _isBatchMode = false;
  final List<BarcodeProduct> _batchItems = [];
  DateTime? _lastScanTime;
  String _heroBg = 'forest';

  final _formKey = GlobalKey();

  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'г');
  final _barcodeCtrl = TextEditingController();
  DateTime? _expiresAt;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  late final AnimationController _scannerPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _loadBg();
  }

  Future<void> _loadBg() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('pantry_hero_bg') ?? 'forest';
    if (mounted) setState(() => _heroBg = value);
  }

  Future<void> _saveBg(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pantry_hero_bg', value);
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _scannerPulse.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _barcodeCtrl.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  CAMERA LIFECYCLE
  // ═══════════════════════════════════════════════════════════════
  Future<void> _startScanner() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final requested = await Permission.camera.request();
      if (!requested.isGranted) {
        if (!mounted) return;
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (_scannerController != null) {
      try {
        await _scannerController!.dispose();
      } catch (_) {}
      _scannerController = null;
    }

    if (!mounted) return;

    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    setState(() {
      _scannerController = controller;
      _scanMode = 'barcode';
      _isScanning = true;
      _cameraLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _cameraLoading) setState(() => _cameraLoading = false);
    });
  }

  Future<void> _closeScanner() async {
    final controller = _scannerController;

    if (mounted) {
      setState(() {
        _isScanning = false;
        _scanMode = 'none';
        _cameraLoading = false;
      });
    }

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      await controller?.dispose();
    } catch (_) {}
    _scannerController = null;
  }

  Future<void> _startBatchMode() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final requested = await Permission.camera.request();
      if (!requested.isGranted) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (_scannerController != null) {
      try {
        await _scannerController!.dispose();
      } catch (_) {}
      _scannerController = null;
    }

    if (!mounted) return;

    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    setState(() {
      _isBatchMode = true;
      _batchItems.clear();
      _scanMode = 'barcode';
      _isScanning = true;
      _cameraLoading = true;
      _scannerController = controller;
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _cameraLoading) setState(() => _cameraLoading = false);
    });
  }

  Future<void> _finishBatchMode() async {
    await _closeScanner();
    await Future.delayed(const Duration(milliseconds: 150));

    final total = _batchItems.length;
    if (!mounted) return;

    setState(() => _isBatchMode = false);

    if (total == 0) {
      Navigator.pop(context);
      return;
    }
    _showBatchCompleteDialog(total);
  }

  // ═══════════════════════════════════════════════════════════════
  //  PERMISSIONS & MESSAGES
  // ═══════════════════════════════════════════════════════════════
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.dangerSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.photo_camera_rounded,
                  color: _C.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Нужна камера', style: _T.h1(_C.ink)),
            ),
          ],
        ),
        content: Text(
          'Чтобы сканировать штрихкоды, разреши приложению использовать камеру в настройках.',
          style: _T.bodySm(_C.muted).copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: _T.body(_C.muted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Настройки'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    _snack(message, _C.danger, Icons.error_outline_rounded);
  }

  void _showSuccess(String message) {
    _snack(message, _C.primary, Icons.check_circle_rounded);
  }

  void _showInfo(String message) {
    _snack(message, _C.cool, Icons.info_outline_rounded,
        duration: const Duration(seconds: 1));
  }

  void _snack(String message, Color bg, IconData icon,
      {Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  OCR
  // ═══════════════════════════════════════════════════════════════
  void _showOcrSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _bottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHeader(
              icon: Icons.document_scanner_rounded,
              iconColor: _C.warm,
              iconBg: _C.warmSoft,
              title: 'Сканирование этикетки',
              subtitle: 'Распознает название и КБЖУ',
            ),
            const SizedBox(height: 20),
            _actionTile(
              emoji: '📸',
              title: 'Сфотографировать',
              subtitle: 'Навести на этикетку продукта',
              accent: _C.warm,
              onTap: () {
                Navigator.pop(context);
                _processImageOCR(source: ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            _actionTile(
              emoji: '🖼️',
              title: 'Выбрать из галереи',
              subtitle: 'Использовать готовое фото',
              accent: _C.cool,
              onTap: () {
                Navigator.pop(context);
                _processImageOCR(source: ImageSource.gallery);
              },
            ),
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
      final parsed =
      context.read<NutritionProvider>().parseOCRLabel(recognizedText.text);

      final firstLine = recognizedText.text.split('\n').firstWhere(
              (line) => line.trim().isNotEmpty && line.trim().length > 2,
          orElse: () => '');

      if (mounted) {
        setState(() {
          _nameCtrl.text =
          firstLine.isNotEmpty && !RegExp(r'^\d').hasMatch(firstLine)
              ? firstLine
              : '';
          if (parsed['quantity'] != null) {
            _qtyCtrl.text = parsed['quantity'].toString();
          }
          if (parsed['unit'] != null) _unitCtrl.text = parsed['unit'];
        });
        _showSuccess(parsed['quantity'] != null
            ? 'Распознано: ${parsed['quantity']} ${parsed['unit']}'
            : 'Текст распознан');
      }
    } catch (_) {
      if (mounted) _showError('Не удалось распознать текст');
    } finally {
      if (mounted) setState(() => _isProcessingOCR = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BARCODE HANDLING
  // ═══════════════════════════════════════════════════════════════
  Future<void> _handleBarcode(String rawCode) async {
    final provider = context.read<NutritionProvider>();
    _showInfo('Ищем продукт…');

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
      await provider.addToScanHistory(confirmed);

      final destination = await _showDestinationChoice(confirmed);
      if (destination == null || !mounted) return;

      await _sendToDestination(confirmed, destination, productId: saved.id);

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

  Future<void> _handleBatchScan(
      BarcodeLookupResult result, String rawCode) async {
    final provider = context.read<NutritionProvider>();
    BarcodeProduct? product = result.product;

    if (product == null) {
      final name = await _showQuickNameDialog(rawCode);
      if (name == null || !mounted) return;
      product = BarcodeProduct(
        barcode: rawCode,
        name: name,
        category: 'other',
        source: BarcodeSource.manual,
      );
    }

    final saved = await provider.saveScannedProduct(product);
    await provider.addToScanHistory(product);

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
      _showSuccess('${saved.name} · в корзине ${_batchItems.length}');
    }
  }

  Future<String?> _showQuickNameDialog(String barcode) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.goldSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child:
              const Icon(Icons.help_outline_rounded, color: _C.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Не найдено', style: _T.h1(_C.ink)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                barcode,
                style: TextStyle(
                  color: _C.muted,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: _T.body(_C.ink),
              decoration: InputDecoration(
                hintText: 'Название продукта',
                hintStyle: _T.body(_C.muted),
                filled: true,
                fillColor: _C.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Пропустить', style: _T.body(_C.muted)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Добавить',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotFoundChoice(
      NotFoundChoice choice, String barcode) async {
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
          BarcodeProduct(
            barcode: barcode,
            name: choice.local!.name,
            category: choice.local!.category,
          ),
          destination,
          productId: choice.local!.id,
        );
      }
      if (mounted) Navigator.pop(context);
    } else if (choice.manualName != null) {
      final name = await _showManualNameDialog(choice.manualName!, barcode);
      if (name == null || !mounted) return;

      final product =
      BarcodeProduct(barcode: barcode, name: name, source: BarcodeSource.manual);
      await provider.saveScannedProduct(product);
      await provider.addToScanHistory(product);

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
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Text('Название продукта', style: _T.h1(_C.ink)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: _T.body(_C.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: _C.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Отмена', style: _T.body(_C.muted)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Сохранить',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DESTINATION
  // ═══════════════════════════════════════════════════════════════
  Future<ScanDestination?> _showDestinationChoice(BarcodeProduct product) {
    return showModalBottomSheet<ScanDestination>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _bottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHeader(
              icon: Icons.place_rounded,
              iconColor: _C.primary,
              iconBg: _C.primarySoft,
              title: 'Куда добавить?',
              subtitle: product.displayName,
            ),
            const SizedBox(height: 20),
            _actionTile(
              emoji: '🧺',
              title: 'В кладовую',
              subtitle: 'Уже есть дома — учту срок годности',
              accent: _C.gold,
              onTap: () => Navigator.pop(context, ScanDestination.pantry),
            ),
            const SizedBox(height: 10),
            _actionTile(
              emoji: '🛒',
              title: 'В список покупок',
              subtitle: 'Нужно купить — добавлю в корзину',
              accent: _C.cool,
              onTap: () => Navigator.pop(context, ScanDestination.shopping),
            ),
            const SizedBox(height: 10),
            _actionTile(
              emoji: '🍽️',
              title: 'Сразу в дневник',
              subtitle: 'Уже съел — запишу в приём пищи',
              accent: _C.warm,
              onTap: () => Navigator.pop(context, ScanDestination.diary),
            ),
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
        if (mounted) _showSuccess('${product.displayName} → в кладовой');
        break;
      case ScanDestination.shopping:
        await provider.addShoppingItem(
          productId: productId,
          customName: product.displayName,
          quantity: 1,
          unit: 'шт',
        );
        if (mounted) _showSuccess('${product.displayName} → в покупках');
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
        if (mounted) _showSuccess('${product.displayName} → в дневнике');
        break;
    }
  }

  void _showBatchCompleteDialog(int total) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_C.primary, _C.primaryDeep],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                    spreadRadius: -4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.celebration_rounded,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 20),
            Text('Закупка завершена',
                style: _T.h1(_C.ink).copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              'Добавлено $total ${_itemsWord(total)} в список покупок',
              textAlign: TextAlign.center,
              style: _T.bodySm(_C.muted).copyWith(height: 1.4),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Готово',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  String _itemsWord(int n) =>
      n == 1 ? 'позиция' : (n >= 2 && n <= 4 ? 'позиции' : 'позиций');

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final recentScans = provider.recentScans;

    if (_isScanning && _scanMode == 'barcode' && _scannerController != null) {
      return _buildScannerScreen(provider);
    }

    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        physics:
        const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          if (recentScans.isNotEmpty)
            SliverToBoxAdapter(child: _buildRecentScans(recentScans, provider)),
          SliverToBoxAdapter(child: _buildFormSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ─── HERO ───
  Widget _buildHero() {
    final isImage = _isImagePath(_heroBg);
    final theme = isImage ? _heroThemes.first : _findTheme(_heroBg);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: isImage
                ? Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _heroBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [theme.top, theme.bottom],
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ],
            )
                : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.top, theme.bottom],
                ),
              ),
            ),
          ),
          if (!isImage)
            Positioned(
              top: 40,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.accent.withOpacity(0.22),
                        theme.accent.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Bottom fade into bg
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 90,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _C.bg.withOpacity(0.0),
                      _C.bg.withOpacity(0.2),
                      _C.bg.withOpacity(0.6),
                      _C.bg,
                    ],
                    stops: const [0.0, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _glassButton(
                          Icons.arrow_back_rounded, () => Navigator.pop(context)),
                      const Spacer(),
                      _glassButton(Icons.wallpaper_rounded, _openThemePicker),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'ДОБАВЛЕНИЕ',
                    style: _T.overline(Colors.white.withOpacity(0.75)).copyWith(
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Пополнить\nкладовую',
                    style: GoogleFonts.inter(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.4,
                      height: 1.05,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  // ─── QUICK ACTIONS ───
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('СПОСОБЫ ДОБАВЛЕНИЯ'),
          const SizedBox(height: 12),
          _PrimaryScanCard(onTap: _startScanner),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SecondaryCard(
                  emoji: '🔍',
                  title: 'Этикетка',
                  subtitle: 'Распознать КБЖУ',
                  accent: _C.warm,
                  soft: _C.warmSoft,
                  onTap: _isProcessingOCR ? null : _showOcrSourcePicker,
                  isLoading: _isProcessingOCR,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryCard(
                  emoji: '✍️',
                  title: 'Вручную',
                  subtitle: 'Заполнить форму',
                  accent: _C.cool,
                  soft: _C.coolSoft,
                  onTap: _scrollToForm,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BatchCard(onTap: _startBatchMode),
        ],
      ),
    );
  }

  void _scrollToForm() {
    final ctx = _formKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
      HapticFeedback.selectionClick();
    }
  }

  // ─── RECENT SCANS ───
  Widget _buildRecentScans(
      List<ScanHistoryEntry> recentScans, NutritionProvider provider) {
    final items = recentScans.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('НЕДАВНИЕ'),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.primarySoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${recentScans.length}',
                  style: _T.overline(_C.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.hairline),
              boxShadow: _cardShadow,
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(
                        height: 1,
                        color: _C.hairline,
                        indent: 16,
                        endIndent: 16),
                  _recentScanRow(items[i], provider),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentScanRow(ScanHistoryEntry scan, NutritionProvider provider) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.qr_code_rounded,
                  color: _C.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.body(_C.ink).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scan.barcode,
                    style: _T.bodySm(_C.muted).copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 0.6,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _C.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child:
              const Icon(Icons.add_rounded, color: _C.primary, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FORM ───
  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        key: _formKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('ДЕТАЛИ ПРОДУКТА'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _C.hairline),
              boxShadow: _cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(
                  ctrl: _nameCtrl,
                  hint: 'Название продукта',
                  icon: Icons.shopping_basket_rounded,
                  required: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _field(
                        ctrl: _qtyCtrl,
                        hint: 'Количество',
                        icon: Icons.numbers_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _field(
                        ctrl: _unitCtrl,
                        hint: 'Ед.',
                        icon: Icons.straighten_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(
                  ctrl: _barcodeCtrl,
                  hint: 'Штрихкод (если есть)',
                  icon: Icons.qr_code_rounded,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: _C.hairline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('СРОК ГОДНОСТИ', style: _T.overline(_C.muted)),
                    ),
                    Expanded(child: Container(height: 1, color: _C.hairline)),
                  ],
                ),
                const SizedBox(height: 20),
                _expiryPicker(),
                const SizedBox(height: 24),
                _saveButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool required = false,
    String? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: _C.muted, size: 18),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              style: _T.body(_C.ink),
              decoration: InputDecoration(
                hintText: required ? '$hint *' : hint,
                hintStyle: _T.body(_C.muted),
                suffixText: suffix,
                suffixStyle: _T.bodySm(_C.muted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expiryPicker() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 3650)),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: _C.primary),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: _C.primary),
                ),
              ),
              child: child!,
            ),
          );
          if (date != null) setState(() => _expiresAt = date);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
            _expiresAt != null ? _C.goldSoft.withOpacity(0.55) : _C.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _expiresAt != null
                  ? _C.gold.withOpacity(0.3)
                  : _C.hairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _expiresAt != null
                      ? _C.gold.withOpacity(0.15)
                      : _C.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: _expiresAt != null ? _C.gold : _C.muted,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Срок годности', style: _T.overline(_C.muted)),
                    const SizedBox(height: 3),
                    Text(
                      _expiresAt != null
                          ? '${_expiresAt!.day}.${_expiresAt!.month.toString().padLeft(2, '0')}.${_expiresAt!.year}'
                          : 'Не указан',
                      style: GoogleFonts.inter(
                        color: _expiresAt != null ? _C.ink : _C.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_expiresAt != null)
                InkWell(
                  onTap: () => setState(() => _expiresAt = null),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child:
                    const Icon(Icons.close_rounded, size: 16, color: _C.muted),
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded,
                    color: _C.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: _C.primary.withOpacity(0.4),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
              'СОХРАНИТЬ В КЛАДОВУЮ',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    final provider = context.read<NutritionProvider>();

    if (_nameCtrl.text.trim().isEmpty || _qtyCtrl.text.trim().isEmpty) {
      _showError('Введите название и количество');
      return;
    }

    await provider.addToPantry(
      customName: _nameCtrl.text.trim(),
      quantity:
      double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 1,
      unit: _unitCtrl.text.trim().isEmpty ? 'г' : _unitCtrl.text.trim(),
      expiresAt: _expiresAt,
    );

    if (!mounted) return;
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    _showSuccess('Добавлено в кладовую');
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: _C.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: _T.overline(_C.muted)),
      ],
    );
  }

  // ─── THEME PICKER ───
  Future<void> _openThemePicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints:
        BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.72),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                        color: _C.hairline,
                        borderRadius: BorderRadius.circular(3))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _C.warmSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.wallpaper_rounded,
                        color: _C.warm, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Фон экрана', style: _T.h1(_C.ink)),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('ЦВЕТОВЫЕ ТЕМЫ'),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                        children: _heroThemes.map((theme) {
                          final isSelected =
                              !_isImagePath(_heroBg) && theme.id == _heroBg;
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(ctx, theme.id);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? _C.primary
                                      : Colors.transparent,
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                      color:
                                      _C.primary.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ]
                                    : null,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [theme.top, theme.bottom],
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.0),
                                            Colors.black.withOpacity(0.5),
                                          ],
                                          stops: const [0.4, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                      left: 6,
                                      top: 6,
                                      child: Text(theme.emoji,
                                          style: const TextStyle(fontSize: 14))),
                                  Positioned(
                                    left: 6,
                                    right: 6,
                                    bottom: 6,
                                    child: Text(
                                      theme.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel('ФОТО ПРИРОДЫ'),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                        children: _heroBackgrounds.map((path) {
                          final isSelected =
                              _isImagePath(_heroBg) && _heroBg == path;
                          final label = _heroBgLabels[path] ?? '';
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(ctx, path);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? _C.primary
                                      : Colors.transparent,
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                      color:
                                      _C.primary.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ]
                                    : null,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(path,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          color: _C.hairline)),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.0),
                                            Colors.black.withOpacity(0.5),
                                          ],
                                          stops: const [0.4, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 6,
                                    right: 6,
                                    bottom: 6,
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && result != _heroBg) {
      await _saveBg(result);
      if (mounted) {
        setState(() => _heroBg = result);
        HapticFeedback.lightImpact();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  SCANNER SCREEN
  // ═══════════════════════════════════════════════════════════════
  Widget _buildScannerScreen(NutritionProvider provider) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController!,
            onDetect: (capture) async {
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue == null) continue;

                if (_isBatchMode) {
                  if (_lastScanTime != null &&
                      DateTime.now().difference(_lastScanTime!).inSeconds < 3) {
                    return;
                  }
                  _lastScanTime = DateTime.now();
                  if (!mounted) return;
                  await _handleBarcode(barcode.rawValue!);
                  return;
                }

                await _closeScanner();
                if (!mounted) return;
                await _handleBarcode(barcode.rawValue!);
                return;
              }
            },
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scannerPulse,
              builder: (_, __) => CustomPaint(
                painter: _ScannerOverlayPainter(
                  pulse: _scannerPulse.value,
                  isBatch: _isBatchMode,
                  accentColor: _isBatchMode ? _C.plum : _C.primary,
                ),
              ),
            ),
          ),
          if (_cameraLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.75),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                          AlwaysStoppedAnimation(_C.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Запуск камеры…',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _scannerButton(Icons.close_rounded, () async {
                      if (_isBatchMode) {
                        await _finishBatchMode();
                      } else {
                        await _closeScanner();
                      }
                    }),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _isBatchMode ? _C.plum : _C.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isBatchMode
                                ? 'ЗАКУПКА · ${_batchItems.length}'
                                : 'СКАНИРОВАНИЕ',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_isBatchMode)
                      _scannerButton(Icons.check_rounded, _finishBatchMode,
                          isAccent: true)
                    else
                      const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    if (_isBatchMode && _batchItems.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _C.primary,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: _C.primary.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _batchItems.last.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      _isBatchMode
                          ? 'Наводи на штрихкоды по очереди'
                          : 'Наведи камеру на штрихкод',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scannerButton(IconData icon, VoidCallback onTap,
      {bool isAccent = false}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isAccent ? _C.primary : Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border:
            Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOTTOM SHEET HELPERS
  // ═══════════════════════════════════════════════════════════════
  Widget _bottomSheet({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: _C.hairline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _sheetHeader({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _T.h2(_C.ink)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _T.bodySm(_C.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required String emoji,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                        _T.body(_C.ink).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: _T.bodySm(_C.muted)),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child:
                Icon(Icons.chevron_right_rounded, color: accent, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HERO CARDS (extracted widgets)
// ═══════════════════════════════════════════════════════════════════
class _PrimaryScanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimaryScanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.primary, _C.primaryDeep],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withOpacity(0.28),
                blurRadius: 28,
                offset: const Offset(0, 14),
                spreadRadius: -6,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -60,
                child: IgnorePointer(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'быстро',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Сканировать',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Наведи камеру на штрихкод',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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

class _SecondaryCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final Color soft;
  final VoidCallback? onTap;
  final bool isLoading;

  const _SecondaryCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.soft,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.hairline),
            boxShadow: _cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                )
                    : Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: _C.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: _C.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BatchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.hairline),
            boxShadow: _cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _C.plumSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: const Text('🛒', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Пакетная закупка',
                      style: GoogleFonts.inter(
                        color: _C.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Сканируй подряд — всё в покупки',
                      style: GoogleFonts.inter(
                        color: _C.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _C.plum.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_forward_rounded,
                    color: _C.plum, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SCANNER OVERLAY PAINTER
// ═══════════════════════════════════════════════════════════════════
class _ScannerOverlayPainter extends CustomPainter {
  final double pulse;
  final bool isBatch;
  final Color accentColor;

  _ScannerOverlayPainter({
    required this.pulse,
    required this.isBatch,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = math.min(size.width * 0.82, 360.0);
    final h = w * 0.6;

    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: w,
      height: h,
    );
    final rrect = RRect.fromRectAndRadius(scanRect, const Radius.circular(22));

    // Dark overlay with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.55));

    // Corner brackets
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const len = 26.0;
    const r = 20.0;

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(scanRect.left, scanRect.top, len, len),
        topLeft: Radius.circular(r),
      ),
      cornerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(scanRect.right - len, scanRect.top, len, len),
        topRight: Radius.circular(r),
      ),
      cornerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(scanRect.left, scanRect.bottom - len, len, len),
        bottomLeft: Radius.circular(r),
      ),
      cornerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
            scanRect.right - len, scanRect.bottom - len, len, len),
        bottomRight: Radius.circular(r),
      ),
      cornerPaint,
    );

    // Scan line
    final lineY = scanRect.top + 12 + (scanRect.height - 24) * pulse;
    final lineRect =
    Rect.fromLTWH(scanRect.left + 16, lineY - 1, scanRect.width - 32, 2);
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accentColor.withOpacity(0),
          accentColor.withOpacity(0.9),
          accentColor.withOpacity(0),
        ],
      ).createShader(lineRect)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(scanRect.left + 16, lineY),
      Offset(scanRect.right - 16, lineY),
      linePaint,
    );

    // Soft glow around rect
    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.08 + 0.06 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(22)),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter old) =>
      old.pulse != pulse ||
          old.isBatch != isBatch ||
          old.accentColor != accentColor;
}