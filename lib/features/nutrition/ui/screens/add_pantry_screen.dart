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
//  DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════════
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
  static const yellowSoft = Color(0xFFFDF5E6);
  static const yellowDeep = Color(0xFFE0B054);
  static const pinkSoft = Color(0xFFFCF0F2);
  static const pinkDeep = Color(0xFFD17A8F);
  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF9381BB);
  static const brownSoft = Color(0xFFF3E9DC);
  static const brownDeep = Color(0xFFA87B4F);
}

class _Hero {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const accent = Color(0xFFA87B4F);
  static const textHigh = Colors.white;
  static const textLow = Color(0xFFA4A6AA);
}

enum ScanDestination { pantry, shopping, diary }

// ═══════════════════════════════════════════════════════════════════
//  HERO THEMES + ФОТО
// ═══════════════════════════════════════════════════════════════════
class _HeroTheme {
  final String id;
  final String label;
  final String emoji;
  final Color top;
  final Color bottom;
  final Color accent;
  const _HeroTheme({
    required this.id, required this.label, required this.emoji,
    required this.top, required this.bottom, required this.accent,
  });
}

const List<_HeroTheme> _heroThemes = [
  _HeroTheme(id: 'kitchen', label: 'Кухня', emoji: '🍳',
      top: Color(0xFF4A2D1B), bottom: Color(0xFF2A1B0F), accent: Color(0xFFEF9563)),
  _HeroTheme(id: 'market', label: 'Рынок', emoji: '🥬',
      top: Color(0xFF1E3530), bottom: Color(0xFF0E1F1B), accent: Color(0xFF6C9E88)),
  _HeroTheme(id: 'pantry', label: 'Кладовая', emoji: '🧺',
      top: Color(0xFF4A3520), bottom: Color(0xFF2A1F10), accent: Color(0xFFE8B858)),
  _HeroTheme(id: 'current', label: 'Тёмный', emoji: '✨',
      top: Color(0xFF1B2027), bottom: Color(0xFF161719), accent: Color(0xFFA87B4F)),
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

// ═══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class AddPantryScreen extends StatefulWidget {
  const AddPantryScreen({super.key});
  @override
  State<AddPantryScreen> createState() => _AddPantryScreenState();
}

class _AddPantryScreenState extends State<AddPantryScreen> with TickerProviderStateMixin {
  bool _isScanning = false;
  String _scanMode = 'none';
  bool _isProcessingOCR = false;
  bool _cameraLoading = false;
  bool _isBatchMode = false;
  final List<BarcodeProduct> _batchItems = [];
  DateTime? _lastScanTime;
  String _heroBg = 'kitchen';

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

  late final AnimationController _scannerPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _loadBg();
  }

  Future<void> _loadBg() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('pantry_hero_bg') ?? 'kitchen';
    if (mounted) setState(() => _heroBg = value);
  }

  Future<void> _saveBg(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pantry_hero_bg', value);
  }

  @override
  void dispose() {
    _scannerController.stop();
    _scannerPulse.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _barcodeCtrl.dispose();
    _textRecognizer.close();
    _scannerController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  CAMERA & PERMISSIONS
  // ═══════════════════════════════════════════════════════════════
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
        _showError('Камера недоступна: ${e.toString()}');
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _P.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
        Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _P.pinkSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.photo_camera_rounded, color: _P.pinkDeep, size: 18),
      ),
      const SizedBox(width: 12),
      const Text('Нужна камера', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)
            ),
            const SizedBox(width: 12),
            const Text('Нужна камера', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Чтобы сканировать штрихкоды, разреши приложению использовать камеру в настройках.',
          style: TextStyle(color: _P.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: _P.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Настройки'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _P.skyDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: _P.pinkDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: _P.greenDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38, height: 5,
                  decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: _P.skySoft, borderRadius: BorderRadius.circular(13)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.document_scanner_rounded, color: _P.skyDeep, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Сканирование этикетки',
                            style: GoogleFonts.inter(color: _P.text, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text('Распознает название и КБЖУ',
                            style: GoogleFonts.inter(color: _P.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _scanActionTile(
                icon: Icons.camera_alt_rounded,
                emoji: '📸',
                title: 'Сфотографировать',
                subtitle: 'Навести на этикетку продукта',
                color: _P.skyDeep,
                softColor: _P.skySoft,
                onTap: () {
                  Navigator.pop(context);
                  _processImageOCR(source: ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              _scanActionTile(
                icon: Icons.photo_library_rounded,
                emoji: '🖼️',
                title: 'Выбрать из галереи',
                subtitle: 'Использовать готовое фото',
                color: _P.lavenderDeep,
                softColor: _P.lavenderSoft,
                onTap: () {
                  Navigator.pop(context);
                  _processImageOCR(source: ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanActionTile({
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: softColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(color: _P.text, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: GoogleFonts.inter(color: _P.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
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
          _nameCtrl.text = firstLine.isNotEmpty && !RegExp(r'^\d').hasMatch(firstLine) ? firstLine : '';
          if (parsed['quantity'] != null) _qtyCtrl.text = parsed['quantity'].toString();
          if (parsed['unit'] != null) _unitCtrl.text = parsed['unit'];
        });
        _showSuccess(parsed['quantity'] != null
            ? 'Распознано: ${parsed['quantity']} ${parsed['unit']}'
            : 'Текст распознан');
      }
    } catch (e) {
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
    _showInfo('🔍 Ищем продукт...');

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
      ScaffoldMessenger.of(context).clearSnackBars();
      _showSuccess('✅ ${saved.name} • В корзине ${_batchItems.length} шт');
    }
  }

  Future<String?> _showQuickNameDialog(String barcode) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _P.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _P.yellowSoft, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.help_outline_rounded, color: _P.yellowDeep, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Не найдено', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _P.bg, borderRadius: BorderRadius.circular(10)),
              child: Text(
                barcode,
                style: TextStyle(
                  color: _P.textMuted,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.inter(color: _P.text, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Введи название продукта',
                hintStyle: GoogleFonts.inter(color: _P.textMuted),
                filled: true,
                fillColor: _P.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Пропустить', style: TextStyle(color: _P.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _P.skyDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Добавить'),
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
        backgroundColor: _P.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Название продукта', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(color: _P.text, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: _P.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _P.greenDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DESTINATION CHOICE
  // ═══════════════════════════════════════════════════════════════
  Future<ScanDestination?> _showDestinationChoice(BarcodeProduct product) {
    return showModalBottomSheet<ScanDestination>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38, height: 5,
                  decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: _P.greenSoft, borderRadius: BorderRadius.circular(13)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.place_rounded, color: _P.greenDeep, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Куда добавить?',
                            style: GoogleFonts.inter(color: _P.text, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text(product.displayName,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(color: _P.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _destinationTile(
                icon: Icons.kitchen_rounded,
                emoji: '🧺',
                title: 'В кладовую',
                subtitle: 'Уже есть дома — учту срок годности',
                color: _P.brownDeep,
                softColor: _P.brownSoft,
                onTap: () => Navigator.pop(context, ScanDestination.pantry),
              ),
              const SizedBox(height: 10),
              _destinationTile(
                icon: Icons.shopping_basket_rounded,
                emoji: '🛒',
                title: 'В список покупок',
                subtitle: 'Нужно купить — добавлю в корзину',
                color: _P.skyDeep,
                softColor: _P.skySoft,
                onTap: () => Navigator.pop(context, ScanDestination.shopping),
              ),
              const SizedBox(height: 10),
              _destinationTile(
                icon: Icons.restaurant_menu_rounded,
                emoji: '🍽️',
                title: 'Сразу в дневник',
                subtitle: 'Уже съел — запишу в приём пищи',
                color: _P.peachDeep,
                softColor: _P.peachSoft,
                onTap: () => Navigator.pop(context, ScanDestination.diary),
              ),
            ],
          ),
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
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: softColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(color: _P.text, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: GoogleFonts.inter(color: _P.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chevron_right_rounded, color: color, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SEND TO DESTINATION
  // ═══════════════════════════════════════════════════════════════
  Future<void> _sendToDestination(BarcodeProduct product, ScanDestination dest, {String? productId}) async {
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
        if (mounted) _showSuccess('🧺 ${product.displayName} → в кладовой');
        break;
      case ScanDestination.shopping:
        await provider.addShoppingItem(
          productId: productId,
          customName: product.displayName,
          quantity: 1,
          unit: 'шт',
        );
        if (mounted) _showSuccess('🛒 ${product.displayName} → в покупках');
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
        if (mounted) _showSuccess('🍽️ ${product.displayName} → в дневнике');
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BATCH MODE
  // ═══════════════════════════════════════════════════════════════
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
        _showError('Камера недоступна');
      }
    }
  }

  Future<void> _finishBatchMode() async {
    // 1. Ждем полного освобождения камеры
    await _scannerController.stop();

    // 2. Даем нативной части 100-150 мс на корректное освобождение Surface
    await Future.delayed(const Duration(milliseconds: 150));

    final total = _batchItems.length;

    if (!mounted) return;

    setState(() {
      _isScanning = false;
      _isBatchMode = false;
    });

    if (total == 0) {
      if (mounted) Navigator.pop(context);
      return;
    }

    if (mounted) {
      _showBatchCompleteDialog(total);
    }
  }

  void _showBatchCompleteDialog(int total) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _P.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_P.greenDeep, Color(0xFF5A8A76)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _P.greenDeep.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Закупка завершена!',
                style: GoogleFonts.inter(color: _P.text, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Добавлено $total ${_itemsWord(total)}',
                style: GoogleFonts.inter(color: _P.textMuted, fontSize: 14)),
            const SizedBox(height: 8),
            Text('в список покупок',
                style: GoogleFonts.inter(color: _P.textMuted, fontSize: 13)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _P.greenDeep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Готово', style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  String _itemsWord(int n) => n == 1 ? 'позиция' : (n >= 2 && n <= 4 ? 'позиции' : 'позиций');

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: _P.skyDeep,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final recentScans = provider.recentScans;

    if (_isScanning && _scanMode == 'barcode') {
      return _buildScannerScreen(provider);
    }

    return Scaffold(
      backgroundColor: _P.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          if (recentScans.isNotEmpty) ...[
            SliverToBoxAdapter(child: _buildRecentScans(recentScans, provider)),
          ],
          SliverToBoxAdapter(child: _buildFormSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HERO
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHero() {
    final isImage = _isImagePath(_heroBg);
    final theme = isImage ? _heroThemes.first : _findTheme(_heroBg);
    final accent = theme.accent;

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
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.55),
                      ],
                      stops: const [0.0, 0.35, 1.0],
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
              top: 40, right: -60,
              child: IgnorePointer(
                child: Container(
                  width: 260, height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [accent.withOpacity(0.25), accent.withOpacity(0)],
                    ),
                  ),
                ),
              ),
            ),
          // Плавный переход
          Positioned(
            left: 0, right: 0, bottom: 0, height: 120,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _P.bg.withOpacity(0.0),
                      _P.bg.withOpacity(0.05),
                      _P.bg.withOpacity(0.15),
                      _P.bg.withOpacity(0.35),
                      _P.bg.withOpacity(0.65),
                      _P.bg.withOpacity(0.90),
                      _P.bg,
                    ],
                    stops: const [0.0, 0.15, 0.30, 0.50, 0.70, 0.85, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _glassPill(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ДОБАВЛЕНИЕ',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                  shadows: [Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 4)],
                                )),
                            const SizedBox(height: 2),
                            Text('Пополнить кладовую',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                  shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 6)],
                                )),
                          ],
                        ),
                      ),
                      _glassPill(Icons.wallpaper_rounded, _openThemePicker),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.20)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [accent.withOpacity(0.3), accent.withOpacity(0.15)]),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🧺', style: TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('3 способа добавить',
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text('Штрихкод · OCR · Вручную',
                                  style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassPill(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Future<void> _openThemePicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: _P.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 38, height: 5, decoration: BoxDecoration(color: _P.divider, borderRadius: BorderRadius.circular(3))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _P.peachSoft, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.wallpaper_rounded, color: _P.peachDeep, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Фон экрана', style: GoogleFonts.inter(color: _P.text, fontSize: 17, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ЦВЕТОВЫЕ ТЕМЫ', style: GoogleFonts.inter(color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.9,
                        children: _heroThemes.map((theme) {
                          final isSelected = !_isImagePath(_heroBg) && theme.id == _heroBg;
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(ctx, theme.id);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? _P.peachDeep : Colors.white, width: isSelected ? 3 : 1),
                                boxShadow: isSelected ? [BoxShadow(color: _P.peachDeep.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))] : null,
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
                                          colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.5)],
                                          stops: const [0.4, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(left: 6, top: 6, child: Text(theme.emoji, style: const TextStyle(fontSize: 14))),
                                  Positioned(
                                    left: 6, right: 6, bottom: 6,
                                    child: Text(theme.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text('ФОТО ПРИРОДЫ', style: GoogleFonts.inter(color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                        children: _heroBackgrounds.map((path) {
                          final isSelected = _isImagePath(_heroBg) && _heroBg == path;
                          final label = _heroBgLabels[path] ?? '';
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(ctx, path);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? _P.peachDeep : Colors.white, width: isSelected ? 3 : 1),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(path, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(color: _P.brownSoft)),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.5)],
                                          stops: const [0.4, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 6, right: 6, bottom: 6,
                                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
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
  //  QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.5),
          boxShadow: [
            BoxShadow(color: _P.text.withOpacity(0.04), blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: _P.greenSoft, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.bolt_rounded, size: 12, color: _P.greenDeep),
                ),
                const SizedBox(width: 8),
                Text('БЫСТРЫЕ ДЕЙСТВИЯ',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _P.textMuted, letterSpacing: 1.0)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _quickActionButton(
                    icon: Icons.qr_code_scanner_rounded,
                    emoji: '📷',
                    title: 'Штрихкод',
                    subtitle: 'Быстрый поиск',
                    color: _P.greenDeep,
                    softColor: _P.greenSoft,
                    onTap: _startScanner,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickActionButton(
                    icon: Icons.document_scanner_rounded,
                    emoji: '🔍',
                    title: 'Этикетка',
                    subtitle: 'Распознать КБЖУ',
                    color: _P.skyDeep,
                    softColor: _P.skySoft,
                    onTap: _isProcessingOCR ? null : _showOcrSourcePicker,
                    isLoading: _isProcessingOCR,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _batchButton(),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required Color softColor,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: softColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                      : Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.inter(color: _P.text, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(color: _P.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _batchButton() {
    return InkWell(
      onTap: _startBatchMode,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_P.lavenderDeep, Color(0xFF7A6BA8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _P.lavenderDeep.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: const Text('🛒', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Пакетная закупка',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Сканируй один за другим → всё в покупки',
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  RECENT SCANS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRecentScans(List<ScanHistoryEntry> recentScans, NutritionProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.5),
          boxShadow: [BoxShadow(color: _P.text.withOpacity(0.04), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: _P.skySoft, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.history_rounded, size: 12, color: _P.skyDeep),
                ),
                const SizedBox(width: 8),
                Text('НЕДАВНО СКАНИРОВАЛИ',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _P.textMuted, letterSpacing: 1.0)),
                const Spacer(),
                Text('${recentScans.length}',
                    style: GoogleFonts.inter(color: _P.skyDeep, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            ...recentScans.take(4).map((scan) => _recentScanTile(scan, provider)),
          ],
        ),
      ),
    );
  }

  Widget _recentScanTile(ScanHistoryEntry scan, NutritionProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _P.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _P.divider.withOpacity(0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.qr_code_rounded, size: 18, color: _P.greenDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scan.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: _P.text, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      scan.barcode,
                      style: TextStyle(
                        color: _P.textMuted,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: _P.greenSoft, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add_rounded, color: _P.greenDeep, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  FORM SECTION
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.5),
          boxShadow: [BoxShadow(color: _P.text.withOpacity(0.04), blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: _P.brownSoft, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.edit_rounded, size: 12, color: _P.brownDeep),
                ),
                const SizedBox(width: 8),
                Text('ДЕТАЛИ ПРОДУКТА',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _P.textMuted, letterSpacing: 1.0)),
              ],
            ),
            const SizedBox(height: 16),
            _textField(_nameCtrl, 'Название продукта', Icons.shopping_basket_rounded, required: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _textField(_qtyCtrl, 'Количество', Icons.numbers_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true), required: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _textField(_unitCtrl, 'Ед.', Icons.straighten_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _textField(_barcodeCtrl, 'Штрихкод (если есть)', Icons.qr_code_rounded),
            const SizedBox(height: 16),
            _expiryPicker(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _P.greenDeep,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: _P.greenDeep.withOpacity(0.4),
                ),
                child: Text('СОХРАНИТЬ В КЛАДОВУЮ',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType, bool required = false}) {
    return Container(
      decoration: BoxDecoration(
        color: _P.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.divider),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(icon, color: _P.textMuted, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              style: GoogleFonts.inter(color: _P.text, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint + (required ? ' *' : ''),
                hintStyle: GoogleFonts.inter(color: _P.textMuted, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expiryPicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: _P.peachDeep),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: _P.peachDeep),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) setState(() => _expiresAt = date);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _expiresAt != null ? _P.yellowSoft.withOpacity(0.5) : _P.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _expiresAt != null ? _P.yellowDeep.withOpacity(0.3) : _P.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              alignment: Alignment.center,
              child: Icon(Icons.calendar_today_rounded, color: _expiresAt != null ? _P.yellowDeep : _P.textMuted, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Срок годности',
                      style: GoogleFonts.inter(color: _P.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    _expiresAt != null
                        ? '${_expiresAt!.day}.${_expiresAt!.month.toString().padLeft(2, '0')}.${_expiresAt!.year}'
                        : 'Не указан',
                    style: GoogleFonts.inter(
                      color: _expiresAt != null ? _P.text : _P.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_expiresAt != null)
              InkWell(
                onTap: () => setState(() => _expiresAt = null),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close_rounded, size: 16, color: _P.textMuted),
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
      quantity: double.tryParse(_qtyCtrl.text) ?? 1,
      unit: _unitCtrl.text.trim().isEmpty ? 'г' : _unitCtrl.text.trim(),
      expiresAt: _expiresAt,
    );

    if (!mounted) return;
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    _showSuccess('✅ Добавлено в кладовую');
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
            controller: _scannerController,
            onDetect: (capture) async {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  if (!_isBatchMode) {
                    await _scannerController.stop();
                    // Небольшая пауза, чтобы нативная камера точно отпустила ресурс
                    // перед тем, как мы начнем показывать диалоги или менять UI
                    await Future.delayed(const Duration(milliseconds: 100));
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
          // Scan overlay with animated corners
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scannerPulse,
              builder: (_, __) {
                return CustomPaint(
                  painter: _ScannerOverlayPainter(
                    pulse: _scannerPulse.value,
                    isBatch: _isBatchMode,
                    accentColor: _isBatchMode ? _P.lavenderDeep : _P.greenDeep,
                  ),
                );
              },
            ),
          ),
          if (_cameraLoading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text('Запуск камеры...', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  ],
                ),
              ),
            ),
          // Top bar
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _scannerIconButton(Icons.close_rounded, () async {
                  if (_isBatchMode) {
                    // Если это пакетный режим, пусть _finishBatchMode сам всё корректно закроет
                    await _finishBatchMode();
                  } else {
                    // Обычный режим: останавливаем, ждем, меняем состояние
                    await _scannerController.stop();
                    await Future.delayed(const Duration(milliseconds: 150));

                    if (mounted) {
                      setState(() => _isScanning = false);
                    }
                  }
                }),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isBatchMode ? Icons.shopping_cart_rounded : Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isBatchMode
                            ? 'ЗАКУПКА • ${_batchItems.length}'
                            : 'Сканирование',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_isBatchMode)
                  _scannerIconButton(Icons.check_rounded, _finishBatchMode, isAccent: true)
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),
          // Bottom hint
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    _isBatchMode
                        ? 'Наводите на штрихкоды по очереди'
                        : 'Наведите камеру на штрихкод',
                    style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Batch items counter
          if (_isBatchMode && _batchItems.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (_, scale, __) => Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _P.greenDeep,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [BoxShadow(color: _P.greenDeep.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${_batchItems.last.displayName} добавлен',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scannerIconButton(IconData icon, VoidCallback onTap, {bool isAccent = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isAccent ? _P.greenDeep : Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
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
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 280,
      height: 180,
    );

    // Dark overlay outside scan area
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // Animated corner brackets
    final cornerPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;
    final cornerRadius = 16.0;

    // Top-left corner
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(scanRect.left, scanRect.top, cornerLength, cornerLength),
        topLeft: Radius.circular(cornerRadius),
        topRight: Radius.zero,
        bottomLeft: Radius.zero,
        bottomRight: Radius.zero,
      ),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(scanRect.right - cornerLength, scanRect.top, cornerLength, cornerLength),
        topLeft: Radius.zero,
        topRight: Radius.circular(cornerRadius),
        bottomLeft: Radius.zero,
        bottomRight: Radius.zero,
      ),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(scanRect.left, scanRect.bottom - cornerLength, cornerLength, cornerLength),
        topLeft: Radius.zero,
        topRight: Radius.zero,
        bottomLeft: Radius.circular(cornerRadius),
        bottomRight: Radius.zero,
      ),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(scanRect.right - cornerLength, scanRect.bottom - cornerLength, cornerLength, cornerLength),
        topLeft: Radius.zero,
        topRight: Radius.zero,
        bottomLeft: Radius.zero,
        bottomRight: Radius.circular(cornerRadius),
      ),
      cornerPaint,
    );

    // Scanning line animation
    final lineY = scanRect.top + (scanRect.height * pulse);
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accentColor.withOpacity(0),
          accentColor.withOpacity(0.8),
          accentColor.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(scanRect.left, lineY - 2, scanRect.width, 4))
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(scanRect.left + 20, lineY),
      Offset(scanRect.right - 20, lineY),
      linePaint,
    );

    // Glow effect around scan area
    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.15 + 0.1 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(20)),
      glowPaint..style = PaintingStyle.stroke..strokeWidth = 8,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter old) =>
      old.pulse != pulse || old.isBatch != isBatch || old.accentColor != accentColor;
}