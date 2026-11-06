import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

  await _requestPermissions();

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

Future<void> _requestPermissions() async {
  // Уведомления (нужно ДО foreground service на Android)
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // Физическая активность (Android) / Motion & Fitness (iOS)
  if (await Permission.activityRecognition.isDenied) {
    await Permission.activityRecognition.request();
  }
  if (await Permission.sensors.isDenied) {
    await Permission.sensors.request();
  }

  // Только Android: отключение оптимизации батареи
  if (Platform.isAndroid) {
    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }
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