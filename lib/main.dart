import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // ← ДОБАВЛЕНО

import 'features/fitness/database/fitness_database.dart';
import 'features/fitness/providers/fitness_provider.dart';
import 'features/fitness/providers/pedometer_provider.dart';
import 'features/nutrition/providers/nutrition_provider.dart';
import 'features/nutrition/providers/color_settings_provider.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ УДАЛИ эту строку после первого успешного запуска:
  // await FitnessDatabase().deleteDatabaseFile();

  // ─── ЗАПРОС РАЗРЕШЕНИЙ ДЛЯ ФОНОВОЙ РАБОТЫ (Android) ───
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    await Permission.ignoreBatteryOptimizations.request();
  }
  // ───────────────────────────────────────────────────────

  final nutrition = NutritionProvider();
  await nutrition.init();

  final fitness = FitnessProvider();
  await fitness.init();

  final pedometer = PedometerProvider();
  await pedometer.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<FitnessProvider>.value(value: fitness),
        ChangeNotifierProvider<NutritionProvider>.value(value: nutrition),
        ChangeNotifierProvider<PedometerProvider>.value(value: pedometer),
        ChangeNotifierProvider<ColorSettingsProvider>(
          create: (_) => ColorSettingsProvider(),
        ),
      ],
      child: const ZalLifeApp(),
    ),
  );
}

class ZalLifeApp extends StatelessWidget {
  const ZalLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zal Life',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5500),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}