// features/nutrition/providers/color_settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 16 цветов палитры:
/// первые 8 — насыщенные, последние 8 — приглушённые (muted).
const List<Color> kAppPalette = [
  // ============ ЯРКИЕ (дефолтные) ============
  Color(0xFF00E5FF), // ice — голубой (дефолт)
  Color(0xFFB4FF39), // lime — лайм
  Color(0xFF00C853), // green — зелёный
  Color(0xFFFFCC00), // plasma — жёлтый
  Color(0xFFFF5500), // volt — оранжевый
  Color(0xFFFF2D55), // magma — малиновый
  Color(0xFF9C82FF), // violet — фиолетовый
  Color(0xFFFF3B30), // red — красный

  // ============ ПРИГЛУШЁННЫЕ (muted) ============
  Color(0xFF6BA3A8), // muted teal — приглушённый бирюзовый
  Color(0xFF8FA88A), // sage — шалфей
  Color(0xFFC99394), // dusty rose — пыльная роза
  Color(0xFFC9B896), // warm sand — тёплый песок
  Color(0xFFB58468), // terracotta — терракота
  Color(0xFF9B8FB8), // muted lavender — приглушённая лаванда
  Color(0xFF7A8CA8), // slate blue — серо-синий
  Color(0xFFC99090), // soft brick — мягкий кирпичный
];

class ColorSettingsProvider extends ChangeNotifier {
  static const _kAccent = 'fuel_accent_color';
  static const _kRay = 'fuel_ray_color';

  Color _accent = kAppPalette[0];
  Color _ray = kAppPalette[0];

  Color get accent => _accent;
  Color get ray => _ray;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getInt(_kAccent);
    final r = prefs.getInt(_kRay);
    if (a != null) _accent = Color(a);
    if (r != null) _ray = Color(r);
    notifyListeners();
  }

  Future<void> setAccent(Color c) async {
    if (c.value == _accent.value) return;
    _accent = c;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAccent, c.value);
  }

  Future<void> setRay(Color c) async {
    if (c.value == _ray.value) return;
    _ray = c;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRay, c.value);
  }
}