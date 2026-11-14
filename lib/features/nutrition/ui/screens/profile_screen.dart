// lib/features/profile/ui/screens/profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Результат редактирования профиля — возвращается через Navigator.pop.
class ProfileResult {
  final String name;
  final String emoji;
  final String? imagePath;
  const ProfileResult({required this.name, required this.emoji, this.imagePath});
}

class _P {
  static const bg = Color(0xFFF6F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF263D36);
  static const textMuted = Color(0xFF7C8982);
  static const green = Color(0xFF426C59);
  static const greenSoft = Color(0xFFE7EFE5);
  static const peach = Color(0xFFC79475);
  static const peachSoft = Color(0xFFF5E6DC);
  static const divider = Color(0xFFE5E8E1);

  static const vividPeach = Color(0xFFFF8A65);
  static const electricBlue = Color(0xFF4A90E2);
  static const goldTop = Color(0xFFF4D06F);
  static const goldMid = Color(0xFFE8B858);
  static const goldBottom = Color(0xFFD4A04A);
}

class _Hero {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const textHigh = Colors.white;
  static const textLow = Color(0xFFA4A6AA);
}

class ProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmoji;
  final String? initialImagePath;
  final int level;
  final int streak;
  final int totalWorkouts;
  final double totalVolume;

  const ProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmoji,
    this.initialImagePath,
    this.level = 1,
    this.streak = 0,
    this.totalWorkouts = 0,
    this.totalVolume = 0,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  late String _emoji;
  late String? _imagePath;
  String? _nameError;
  bool _saving = false;

  static const _emojis = [
    '💪', '🏋️', '🏃', '🧘', '🚴', '🤸', '🥊', '🏊',
    '🔥', '⚡', '🦁', '🐺', '🦅', '👑', '🎯', '🌱',
    '🌿', '🍃', '⭐', '✨', '🎨', '🎸', '🧠', '💎',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _emoji = widget.initialEmoji;
    _imagePath = widget.initialImagePath;
    _nameCtrl.addListener(() {
      if (_nameError != null) setState(() => _nameError = null);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _hasPhoto => _imagePath != null && _imagePath!.isNotEmpty;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 900,
        maxHeight: 900,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null || !mounted) return;
      setState(() => _imagePath = picked.path);
      HapticFeedback.selectionClick();
    } catch (_) {
      if (!mounted) return;
      _snack(source == ImageSource.camera
          ? 'Не удалось открыть камеру'
          : 'Не удалось открыть галерею');
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Введи имя');
      HapticFeedback.lightImpact();
      return;
    }
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('avatar_emoji', _emoji);
    if (_hasPhoto) {
      await prefs.setString('avatar_image_path', _imagePath!);
    } else {
      await prefs.remove('avatar_image_path');
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(context, ProfileResult(
      name: name,
      emoji: _emoji,
      imagePath: _hasPhoto ? _imagePath : null,
    ));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _Hero.bgTop,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final r = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);
    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(r),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(r * 20, 8, r * 20, r * 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _avatarBlock(r),
                    SizedBox(height: r * 20),
                    _nameField(r),
                    if (widget.totalWorkouts > 0) ...[
                      SizedBox(height: r * 20),
                      _statsGrid(r),
                    ],
                    SizedBox(height: r * 24),
                    _avatarSection(r),
                    SizedBox(height: r * 20),
                    _emojiGrid(r),
                    SizedBox(height: r * 32),
                    _saveButton(r),
                    SizedBox(height: r * 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(double r) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r * 12, r * 12, r * 12, r * 8),
      child: Row(
        children: [
          _press(
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: r * 44,
              height: r * 44,
              child: Icon(Icons.close_rounded, size: r * 22, color: _P.text),
            ),
          ),
          Expanded(
            child: Text(
              'Профиль',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: r * 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: _P.text,
              ),
            ),
          ),
          SizedBox(width: r * 44),
        ],
      ),
    );
  }

  Widget _avatarBlock(double r) {
    final size = r * 120;
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: _showAvatarActions,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Hero.bgBottom,
                border: Border.all(
                  color: _P.surface,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: r * 20,
                    spreadRadius: -2,
                    offset: Offset(0, r * 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: _hasPhoto
                  ? Image.file(
                File(_imagePath!),
                width: size, height: size, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Text(_emoji, style: TextStyle(fontSize: size * 0.42)),
              )
                  : Text(_emoji, style: TextStyle(fontSize: size * 0.42)),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: r * 36,
              height: r * 36,
              decoration: BoxDecoration(
                color: _P.vividPeach,
                shape: BoxShape.circle,
                border: Border.all(color: _P.bg, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _P.vividPeach.withOpacity(0.45),
                    blurRadius: r * 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(Icons.photo_camera_rounded,
                  size: r * 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameField(double r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: r * 4, bottom: r * 6),
          child: Text(
            'ИМЯ',
            style: GoogleFonts.inter(
              color: _P.textMuted, fontSize: r * 10,
              fontWeight: FontWeight.w700, letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: r * 16),
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(r * 16),
            border: Border.all(
              color: _nameError != null ? _P.vividPeach : _P.divider,
              width: _nameError != null ? 1.4 : 1,
            ),
          ),
          child: TextField(
            controller: _nameCtrl,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(
              color: _P.text,
              fontSize: r * 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
            decoration: InputDecoration(
              hintText: 'Как тебя зовут?',
              hintStyle: GoogleFonts.inter(
                color: _P.textMuted,
                fontSize: r * 18,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: r * 16),
            ),
          ),
        ),
        if (_nameError != null)
          Padding(
            padding: EdgeInsets.only(left: r * 8, top: r * 6),
            child: Text(
              _nameError!,
              style: GoogleFonts.inter(
                color: _P.vividPeach, fontSize: r * 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        SizedBox(height: r * 12),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: r * 12, vertical: r * 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_P.goldTop, _P.goldMid, _P.goldBottom],
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: _P.goldMid.withOpacity(0.4),
                  blurRadius: r * 8,
                  offset: Offset(0, r * 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded,
                    color: Colors.white, size: r * 12),
                SizedBox(width: r * 4),
                Text('Level ${widget.level}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: r * 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statsGrid(double r) {
    return Container(
      padding: EdgeInsets.all(r * 4),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(r * 20),
        border: Border.all(color: _P.divider),
      ),
      child: Row(
        children: [
          _statItem(r, Icons.local_fire_department_rounded,
              '${widget.streak}', 'дней подряд', _P.peach),
          Container(width: 1, height: r * 40, color: _P.divider),
          _statItem(r, Icons.fitness_center_rounded,
              '${widget.totalWorkouts}', 'тренировок', _P.green),
          Container(width: 1, height: r * 40, color: _P.divider),
          _statItem(r, Icons.scale_rounded,
              _shortKg(widget.totalVolume), 'общий тоннаж', _P.vividPeach),
        ],
      ),
    );
  }

  Widget _statItem(double r, IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: r * 14, horizontal: r * 6),
        child: Column(
          children: [
            Icon(icon, size: r * 16, color: color),
            SizedBox(height: r * 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: GoogleFonts.inter(
                    color: _P.text,
                    fontSize: r * 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1,
                  )),
            ),
            SizedBox(height: r * 3),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: _P.textMuted,
                  fontSize: r * 10,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  Widget _avatarSection(double r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: r * 4, bottom: r * 10),
          child: Text(
            'АВАТАР',
            style: GoogleFonts.inter(
              color: _P.textMuted, fontSize: r * 10,
              fontWeight: FontWeight.w700, letterSpacing: 1.2,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _optionButton(
                r,
                icon: Icons.photo_camera_rounded,
                label: 'Фото',
                color: _P.vividPeach,
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
            SizedBox(width: r * 10),
            Expanded(
              child: _optionButton(
                r,
                icon: Icons.photo_library_rounded,
                label: 'Галерея',
                color: _P.electricBlue,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _optionButton(double r, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _press(
      onTap: onTap,
      child: Container(
        height: r * 52,
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(r * 14),
          border: Border.all(color: _P.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: r * 28, height: r * 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(r * 8),
              ),
              child: Icon(icon, color: color, size: r * 15),
            ),
            SizedBox(width: r * 8),
            Text(label,
                style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: r * 13,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  Widget _emojiGrid(double r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: r * 4, bottom: r * 10),
          child: Text(
            'ИЛИ ВЫБЕРИ ЭМОДЗИ',
            style: GoogleFonts.inter(
              color: _P.textMuted, fontSize: r * 10,
              fontWeight: FontWeight.w700, letterSpacing: 1.2,
            ),
          ),
        ),
        Wrap(
          spacing: r * 8,
          runSpacing: r * 8,
          children: _emojis.map((e) {
            final selected = !_hasPhoto && _emoji == e;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _emoji = e;
                  _imagePath = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: r * 52,
                height: r * 52,
                decoration: BoxDecoration(
                  color: selected ? _P.greenSoft : _P.surface,
                  borderRadius: BorderRadius.circular(r * 14),
                  border: Border.all(
                    color: selected ? _P.green : _P.divider,
                    width: selected ? 1.8 : 1,
                  ),
                ),
                child: Center(
                  child: Text(e, style: TextStyle(fontSize: r * 24)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _saveButton(double r) {
    return SizedBox(
      width: double.infinity,
      height: r * 54,
      child: _press(
        onTap: _saving ? null : _save,
        child: Opacity(
          opacity: _saving ? 0.6 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: _P.green,
              borderRadius: BorderRadius.circular(r * 16),
              boxShadow: [
                BoxShadow(
                  color: _P.green.withOpacity(0.30),
                  blurRadius: r * 16,
                  offset: Offset(0, r * 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, color: Colors.white, size: r * 20),
                SizedBox(width: r * 8),
                Text('СОХРАНИТЬ',
                    style: GoogleFonts.inter(
                      color: Colors.white, fontSize: r * 14,
                      fontWeight: FontWeight.w700, letterSpacing: 0.8,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAvatarActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final r = (MediaQuery.sizeOf(ctx).width / 390).clamp(0.85, 1.2);
        return Container(
          padding: EdgeInsets.all(r * 20),
          decoration: const BoxDecoration(
            color: Colors.white,
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
                    width: r * 38, height: r * 5,
                    decoration: BoxDecoration(
                      color: _P.divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                SizedBox(height: r * 20),
                Text('ИЗМЕНИТЬ АВАТАР',
                    style: GoogleFonts.inter(
                      color: _P.green, fontSize: r * 10,
                      fontWeight: FontWeight.w800, letterSpacing: 2.0,
                    )),
                SizedBox(height: r * 16),
                _press(
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                  child: _actionRow(r, Icons.photo_camera_rounded,
                      'Сделать фото', _P.vividPeach),
                ),
                SizedBox(height: r * 8),
                _press(
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                  child: _actionRow(r, Icons.photo_library_rounded,
                      'Из галереи', _P.electricBlue),
                ),
                SizedBox(height: r * 8),
                _press(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _imagePath = null);
                    // scroll to emoji section would be nice, but skip
                  },
                  child: _actionRow(r, Icons.emoji_emotions_rounded,
                      'Выбрать эмодзи', _P.peach),
                ),
                SizedBox(height: r * 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionRow(double r, IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(r * 14),
      decoration: BoxDecoration(
        color: _P.bg,
        borderRadius: BorderRadius.circular(r * 14),
      ),
      child: Row(
        children: [
          Container(
            width: r * 40, height: r * 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(r * 11),
            ),
            child: Icon(icon, color: color, size: r * 20),
          ),
          SizedBox(width: r * 12),
          Text(label,
              style: GoogleFonts.inter(
                color: _P.text, fontSize: r * 14,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _press({Widget? child, VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }

  String _shortKg(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return k >= 10 ? '${k.toStringAsFixed(0)}k' : '${k.toStringAsFixed(1)}k';
    }
    return v.round().toString();
  }
}