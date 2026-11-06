// features/fitness/ui/widgets/image_picker_field.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zal_life/features/fitness/data/exercise_image_presets.dart';


// ═══════════════════════════════════════════════════════════════════
//  Тема
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF7C818A);
  static const divider = Color(0xFFE9EBEF);
  static const border = Color(0xFFDCE0E5);
  static const greenDeep = Color(0xFF6C9E88);
  static const greenSoft = Color(0xFFEAF2ED);
  static const greenText = Color(0xFF47735F);
  static const redDeep = Color(0xFFE7708A);
}

class _T {
  static TextStyle headline = GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, color: _P.text);
  static TextStyle body = GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, color: _P.textMuted);
  static TextStyle caption = GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: _P.textMuted);
  static TextStyle title2 = GoogleFonts.inter(
      fontSize: 20, fontWeight: FontWeight.w600, color: _P.text);
}

// ═══════════════════════════════════════════════════════════════════
//  ОСНОВНОЙ ВИДЖЕТ
// ═══════════════════════════════════════════════════════════════════
class ImagePickerField extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final ExerciseTypeHint? hint;

  const ImagePickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'ИЗОБРАЖЕНИЕ',
    this.hint,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    final XFile? img = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      widget.onChanged(img.path);
    }
  }

  void _showUrlDialog() {
    final controller = TextEditingController(
      text: widget.value?.startsWith('http') == true ? widget.value : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ссылка на фото', style: _T.headline),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'https://...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) widget.onChanged(url);
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showPresets() {
    final categories = ExerciseImagePresets.byCategory.keys.toList();
    final defaultCat = widget.hint != null
        ? ExerciseImagePresets.defaultCategoryFor(widget.hint!)
        : null;
    int selectedTab = defaultCat != null
        ? categories.indexOf(defaultCat).clamp(0, categories.length - 1)
        : 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final items =
          ExerciseImagePresets.byCategory[categories[selectedTab]]!;
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _P.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('База изображений', style: _T.title2),
                    const Spacer(),
                    Text(
                      '${items.length}',
                      style: _T.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _P.greenText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final isSelected = i == selectedTab;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedTab = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? _P.greenDeep : _P.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            categories[i],
                            style: _T.caption.copyWith(
                              color: isSelected ? Colors.white : _P.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final url = items[index];
                      final isSelected = widget.value == url;
                      return GestureDetector(
                        onTap: () {
                          widget.onChanged(url);
                          Navigator.pop(ctx);
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: url.startsWith('assets/')
                                  ? Image.asset(url, fit: BoxFit.cover)
                                  : CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    Container(color: _P.bg),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _P.greenDeep, width: 2.5),
                                ),
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: _P.greenDeep,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreview() {
    final v = widget.value;
    if (v == null || v.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: _P.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.border),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_outlined, color: _P.textMuted, size: 32),
            const SizedBox(height: 8),
            Text('Нет изображения', style: _T.caption),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _buildImage(v, height: 160, width: double.infinity),
    );
  }

  Widget _buildImage(String path, {double? height, double? width}) {
    // 🆕 Если это локальная картинка из базы
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: _P.bg,
          height: height,
          width: width,
          child: const Icon(Icons.broken_image),
        ),
      );
    }
    // Если интернет-ссылка
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        height: height,
        width: width,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: _P.bg, height: height, width: width),
        errorWidget: (_, __, ___) => Container(
          color: _P.bg, height: height, width: width,
          child: const Icon(Icons.broken_image),
        ),
      );
    }
    // Если файл с телефона
    return Image.file(
      File(path),
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: _P.bg, height: height, width: width,
        child: const Icon(Icons.broken_image),
      ),
    );
  }

  Widget _bgButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _P.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _P.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: _P.greenDeep, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: _T.caption.copyWith(color: _P.text, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(widget.label,
                style: _T.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _P.divider),
          ),
          child: Column(
            children: [
              _buildPreview(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _bgButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Галерея',
                      onTap: _pickFromGallery,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _bgButton(
                      icon: Icons.link_rounded,
                      label: 'Ссылка',
                      onTap: _showUrlDialog,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _bgButton(
                      icon: Icons.grid_view_rounded,
                      label: 'База',
                      onTap: _showPresets,
                    ),
                  ),
                  if (widget.value != null && widget.value!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onChanged(null),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE9EC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: _P.redDeep, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}