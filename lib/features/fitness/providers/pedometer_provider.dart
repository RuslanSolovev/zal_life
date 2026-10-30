import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:accurate_step_counter/accurate_step_counter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepDay {
  final DateTime date;
  final int steps;
  const StepDay({required this.date, required this.steps});
}

class DailyQuest {
  final String id;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final double progress;
  const DailyQuest({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.progress,
  });
}

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;
  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

class PedometerProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _kSteps = 'pedo_steps';
  static const _kDate = 'pedo_date';
  static const _kGoal = 'pedo_goal';
  static const _kHistoryPrefix = 'pedo_hist_';
  static const _kHourly = 'pedo_hourly';
  static const _kHeight = 'user_height';
  static const _kWeight = 'user_weight';
  static const _kCadence1 = 'pedo_cadence1';
  static const _kCadence2 = 'pedo_cadence2';
  static const _kCadence3 = 'pedo_cadence3';

  int _steps = 0;
  int _goal = 10000;
  String _todayKey = '';

  final _stepCounter = AccurateStepCounter();
  StreamSubscription<int>? _todayStepsSub;

  bool _isWalking = false;
  DateTime? _lastStepTime;

  final List<DateTime> _recentStepTimes = [];
  int _cadence = 0;
  int _zone1Seconds = 0;
  int _zone2Seconds = 0;
  int _zone3Seconds = 0;
  Timer? _cadenceTimer;

  DateTime? _walkStartTime;
  bool _isContinuousWalk = false;
  Duration _walkDuration = Duration.zero;
  Timer? _walkTimer;

  bool _available = true;
  bool _permissionDenied = false;
  String? _error;
  DateTime? _lastPersist;
  bool _initialized = false;

  double _heightCm = 175.0;
  double _weightKg = 70.0;

  Map<int, int> _hourlySteps = {};
  List<StepDay> _history = [];

  int get steps => _steps;
  int get goal => _goal;
  double get progress => _goal > 0 ? (_steps / _goal).clamp(0.0, 1.0) : 0.0;
  int get remaining => (_goal - _steps).clamp(0, _goal);
  bool get goalReached => _steps >= _goal;
  bool get isWalking => _isWalking;
  bool get available => _available;
  bool get permissionDenied => _permissionDenied;
  String? get error => _error;
  double get heightCm => _heightCm;
  double get weightKg => _weightKg;
  Map<int, int> get hourlySteps => _hourlySteps;
  List<StepDay> get history => _history;

  int get cadence => _cadence;
  double get zone1Minutes => _zone1Seconds / 60.0;
  double get zone2Minutes => _zone2Seconds / 60.0;
  double get zone3Minutes => _zone3Seconds / 60.0;
  bool get isContinuousWalk => _isContinuousWalk;
  Duration get walkDuration => _walkDuration;

  double get distanceKm => (_steps * (_heightCm * 0.415) / 100000.0);
  double get calories => _steps * (_weightKg * 0.0005);
  int get activeMinutes => (_steps / 100).round();
  bool get isOnFire => _steps > (_goal * 1.5);

  // ─── Данные для Транссиба (JourneyView) ───
  double get totalDistanceKmAllTime {
    double total = 0;
    for (final day in _history) {
      total += day.steps * (_heightCm * 0.415) / 100000.0;
    }
    return total;
  }

  int get totalStepsAllTime =>
      _history.fold<int>(0, (sum, d) => sum + d.steps);

  int get currentStreak {
    if (_history.isEmpty) return 0;
    int streak = 0;
    for (int i = _history.length - 2; i >= 0; i--) {
      if (_history[i].steps >= _goal) streak++;
      else break;
    }
    if (_steps >= _goal) streak++;
    return streak;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    try {
      final status = await Permission.activityRecognition.status;
      if (status.isDenied) {
        final result = await Permission.activityRecognition.request();
        if (!result.isGranted) {
          _permissionDenied = true;
          _available = false;
          _error = 'Доступ к физической активности запрещён';
          await _loadFromPrefs();
          notifyListeners();
          return;
        }
      } else if (status.isPermanentlyDenied) {
        _permissionDenied = true;
        _available = false;
        _error = 'Разрешите доступ в настройках';
        await _loadFromPrefs();
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Permission: $e');
    }

    await _loadFromPrefs();

    try {
      await _stepCounter.startTracking();
      _todayStepsSub = _stepCounter.watchTodaySteps().listen(
        _onTodaySteps,
        onError: (Object e) {
          _available = false;
          _error = '$e';
          _permissionDenied = true;
          notifyListeners();
        },
      );
    } catch (e) {
      _available = false;
      _error = '$e';
      notifyListeners();
    }

    _startCadenceTimer();
    notifyListeners();
  }

  Future<void> checkPermissionStatus() async {
    try {
      final status = await Permission.activityRecognition.status;
      _permissionDenied = status.isDenied || status.isPermanentlyDenied;
      if (_permissionDenied) _available = false;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncStepsNow();
    }
  }

  Future<void> _syncStepsNow() async {
    await _todayStepsSub?.cancel();
    try {
      _todayStepsSub = _stepCounter.watchTodaySteps().listen(
        _onTodaySteps,
        onError: (Object e) {
          _available = false;
          _error = '$e';
          notifyListeners();
        },
      );
    } catch (_) {}
  }

  void _onTodaySteps(int systemSteps) {
    final now = DateTime.now();
    final key = _dateKey(now);

    if (key != _todayKey) {
      _persistHistory(_todayKey, _steps);
      _todayKey = key;
      _hourlySteps = {};
      _steps = 0;
    }

    final delta = systemSteps - _steps;

    if (delta > 0) {
      _steps = systemSteps;
      _hourlySteps[now.hour] = (_hourlySteps[now.hour] ?? 0) + delta;
      _lastStepTime = now;

      for (int i = 0; i < delta; i++) {
        _recentStepTimes.add(now);
      }
      _recentStepTimes.removeWhere((t) => now.difference(t).inSeconds > 60);
      _cadence = _recentStepTimes.length;

      _updateWalkingState();
      _persistThrottled();
      _loadHistory();
      notifyListeners();
    } else if (delta < 0) {
      _steps = systemSteps;
      _persistThrottled();
      _loadHistory();
      notifyListeners();
    }
  }

  void _startCadenceTimer() {
    _cadenceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateWalkingState();

      if (_isWalking || _recentStepTimes.isNotEmpty) {
        _cadence = cadence;
        if (_cadence < 100) {
          _zone1Seconds += 5;
        } else if (_cadence >= 100 && _cadence <= 120) {
          _zone2Seconds += 5;
        } else if (_cadence > 120) {
          _zone3Seconds += 5;
        }
        _persistCadenceZones();
        notifyListeners();
      }
    });
  }

  void _updateWalkingState() {
    final now = DateTime.now();
    if (_lastStepTime != null && now.difference(_lastStepTime!).inSeconds < 10) {
      if (!_isWalking) {
        _isWalking = true;
        _walkStartTime ??= now;
        notifyListeners();
      }

      if (now.difference(_walkStartTime!).inMinutes >= 5 && !_isContinuousWalk) {
        _isContinuousWalk = true;
        _walkTimer?.cancel();
        _walkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _walkDuration += const Duration(seconds: 1);
          notifyListeners();
        });
      }
    } else {
      if (_isWalking) {
        _isWalking = false;
        _walkStartTime = null;
        if (_isContinuousWalk) {
          _isContinuousWalk = false;
          _walkTimer?.cancel();
          _walkDuration = Duration.zero;
        }
        notifyListeners();
      }
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _todayKey = _dateKey(DateTime.now());

    _heightCm = prefs.getDouble(_kHeight) ?? 175.0;
    _weightKg = prefs.getDouble(_kWeight) ?? 70.0;

    final savedDate = prefs.getString(_kDate);
    if (savedDate != _todayKey) {
      if (savedDate != null) {
        final old = prefs.getInt(_kSteps) ?? 0;
        await prefs.setInt('$_kHistoryPrefix$savedDate', old);
      }
      _steps = 0;
      _hourlySteps = {};
      _zone1Seconds = 0;
      _zone2Seconds = 0;
      _zone3Seconds = 0;
      await prefs.setString(_kDate, _todayKey);
      await prefs.setInt(_kSteps, 0);
      await prefs.remove(_kHourly);
      await prefs.remove(_kCadence1);
      await prefs.remove(_kCadence2);
      await prefs.remove(_kCadence3);
    } else {
      _steps = prefs.getInt(_kSteps) ?? 0;
      _zone1Seconds = prefs.getInt(_kCadence1) ?? 0;
      _zone2Seconds = prefs.getInt(_kCadence2) ?? 0;
      _zone3Seconds = prefs.getInt(_kCadence3) ?? 0;
      final hourlyStr = prefs.getString(_kHourly);
      if (hourlyStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(hourlyStr);
        _hourlySteps = decoded.map((k, v) => MapEntry(int.parse(k), v as int));
      }
    }
    _goal = prefs.getInt(_kGoal) ?? 10000;

    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_kHistoryPrefix)).toList();
    keys.sort(); // YYYY-MM-DD сортируется лексикографически

    _history = [];
    for (final key in keys) {
      final dateStr = key.replaceFirst(_kHistoryPrefix, '');
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        try {
          final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          final count = prefs.getInt(key) ?? 0;
          _history.add(StepDay(date: d, steps: count));
        } catch (_) {}
      }
    }

    // Гарантируем, что сегодняшний день есть в истории
    final todayKey = _dateKey(DateTime.now());
    bool todayExists = false;
    for (int i = 0; i < _history.length; i++) {
      if (_dateKey(_history[i].date) == todayKey) {
        _history[i] = StepDay(date: _history[i].date, steps: _steps);
        todayExists = true;
        break;
      }
    }
    if (!todayExists) {
      _history.add(StepDay(date: DateTime.now(), steps: _steps));
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSteps, _steps);
    await prefs.setString(_kDate, _todayKey);
    await prefs.setString(_kHourly, jsonEncode(_hourlySteps));
  }

  void _persistThrottled() {
    final now = DateTime.now();
    if (_lastPersist == null || now.difference(_lastPersist!).inSeconds >= 5) {
      _lastPersist = now;
      _persist();
    }
  }

  Future<void> _persistHistory(String dateKey, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kHistoryPrefix$dateKey', count);
  }

  Future<void> _persistCadenceZones() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCadence1, _zone1Seconds);
    await prefs.setInt(_kCadence2, _zone2Seconds);
    await prefs.setInt(_kCadence3, _zone3Seconds);
  }

  Future<void> setGoal(int newGoal) async {
    if (newGoal < 100) return;
    _goal = newGoal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGoal, newGoal);
    notifyListeners();
  }

  Future<void> setCalibration(double height, double weight) async {
    _heightCm = height;
    _weightKg = weight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kHeight, height);
    await prefs.setDouble(_kWeight, weight);
    notifyListeners();
  }

  Future<void> retryPermission() async {
    _permissionDenied = false;
    _error = null;
    _available = true;
    _initialized = false;
    await _todayStepsSub?.cancel();
    await init();
  }

  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  List<DailyQuest> get quests {
    final hour = DateTime.now().hour;
    final morningSteps = _hourlySteps.entries
        .where((e) => e.key < 10)
        .fold(0, (sum, e) => sum + e.value);

    return [
      DailyQuest(
        id: 'morning',
        title: 'Ранняя птичка',
        subtitle: 'Сделай 1000 шагов до 10:00',
        isCompleted: morningSteps >= 1000,
        progress: (morningSteps / 1000).clamp(0.0, 1.0),
      ),
      DailyQuest(
        id: 'half_goal',
        title: 'Половина пути',
        subtitle: 'Достигни 50% дневной цели',
        isCompleted: _steps >= (_goal / 2),
        progress: (_steps / (_goal / 2)).clamp(0.0, 1.0),
      ),
    ];
  }

  List<Achievement> get achievements {
    final maxHistory = _history.fold<int>(0, (m, d) => d.steps > m ? d.steps : m);
    final totalSteps = _history.fold<int>(0, (s, d) => s + d.steps);

    return [
      Achievement(
        id: 'first_step',
        emoji: '👟',
        title: 'Первый шаг',
        description: 'Сделайте 1 шаг',
        unlocked: totalSteps > 0,
      ),
      Achievement(
        id: '10k_day',
        emoji: '🔥',
        title: '10 000',
        description: 'Пройдите 10к за день',
        unlocked: maxHistory >= 10000,
      ),
      Achievement(
        id: 'streak_3',
        emoji: '⚡',
        title: 'Серия',
        description: '3 дня подряд',
        unlocked: currentStreak >= 3,
      ),
      Achievement(
        id: 'marathon',
        emoji: '🏅',
        title: 'Марафонец',
        description: 'Пройдите 42 км',
        unlocked: totalSteps * 0.0007 >= 42,
      ),
    ];
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _walkTimer?.cancel();
    _cadenceTimer?.cancel();
    _todayStepsSub?.cancel();
    super.dispose();
  }
}