import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/exercise_image_presets.dart';


// Дизайн-система (скопируйте _P и _T из ваших экранов или импортируйте)
class _P {
  static const peachDeep = Color(0xFFE57154);
  static const peachSoft = Color(0xFFFFE9E1);
  static const text = Color(0xFF2B2823);
  static const textMuted = Color(0xFF8A8278);
  static const divider = Color(0xFFEAE4DA);
  static const bg = Color(0xFFFAF7F2);
}
class _T {
  static const overline = TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4, height: 1.1);
  static const headline = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.3);
  static const caption2 = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.1, height: 1.3);
}

Future<String?> showExerciseImageSelector({
  required BuildContext context,
  required String? currentImageUrl,
  required bool isCustom,
  String? defaultImageUrl,
}) async {
  String? selectedUrl = currentImageUrl;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Container(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 5,
                  decoration: BoxDecoration(color: _P.textMuted.withOpacity(0.3), borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 20),
              Text('ИСТОЧНИК ИЗОБРАЖЕНИЯ', style: _T.overline.copyWith(color: _P.peachDeep)),
              const SizedBox(height: 16),

              // Текущее превью
              if (selectedUrl != null && selectedUrl!.isNotEmpty)
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _P.divider),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildImagePreview(selectedUrl!),
                  ),
                )
              else
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _P.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _P.divider, width: 1, style: BorderStyle.solid),
                  ),
                  child: const Center(child: Icon(Icons.image_not_supported_rounded, size: 48, color: _P.textMuted)),
                ),

              const SizedBox(height: 20),

              // Кнопки выбора
              _SelectorOptionButton(
                icon: Icons.photo_library_rounded,
                title: 'Выбрать из галереи',
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null) {
                    setSheetState(() => selectedUrl = picked.path);
                  }
                },
              ),
              const SizedBox(height: 10),
              _SelectorOptionButton(
                icon: Icons.link_rounded,
                title: 'Вставить ссылку (URL)',
                onTap: () async {
                  final url = await _showUrlInputDialog(ctx);
                  if (url != null) {
                    setSheetState(() => selectedUrl = url);
                  }
                },
              ),
              const SizedBox(height: 10),
              _SelectorOptionButton(
                icon: Icons.grid_view_rounded,
                title: 'Выбрать из библиотеки приложения',
                onTap: () async {
                  final preset = await _showPresetGridDialog(ctx);
                  if (preset != null) {
                    setSheetState(() => selectedUrl = preset);
                  }
                },
              ),

              if (!isCustom && defaultImageUrl != null && defaultImageUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                _SelectorOptionButton(
                  icon: Icons.refresh_rounded,
                  title: 'Сбросить к стандартному',
                  color: _P.peachDeep,
                  onTap: () {
                    setSheetState(() => selectedUrl = defaultImageUrl);
                  },
                ),
              ],

              if (selectedUrl != null && selectedUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _SelectorOptionButton(
                  icon: Icons.delete_outline_rounded,
                  title: 'Удалить изображение',
                  color: Colors.redAccent,
                  onTap: () {
                    setSheetState(() => selectedUrl = null);
                  },
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, selectedUrl),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _P.peachDeep,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('ГОТОВО', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return selectedUrl;
}

Widget _buildImagePreview(String url) {
  if (url.startsWith('http')) {
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48));
  }
  if (url.startsWith('assets/')) {
    return Image.asset(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48));
  }
  return Image.file(File(url), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48));
}

class _SelectorOptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _SelectorOptionButton({required this.icon, required this.title, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? _P.text;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _P.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: _T.headline.copyWith(color: c, fontSize: 14))),
            const Icon(Icons.chevron_right_rounded, color: _P.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

Future<String?> _showUrlInputDialog(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Вставьте ссылку на изображение'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'https://...', border: OutlineInputBorder()),
        keyboardType: TextInputType.url,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<String?> _showPresetGridDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(ctx).size.width * 0.9,
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Библиотека приложения', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: ExerciseImagePresets.all.length,
                itemBuilder: (ctx, i) {
                  final path = ExerciseImagePresets.all[i];
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, path),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(path, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}