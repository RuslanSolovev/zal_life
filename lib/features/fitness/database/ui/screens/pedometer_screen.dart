import 'dart:math' as math;
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:zal_life/features/fitness/providers/pedometer_provider.dart';
import 'package:zal_life/features/nutrition/providers/nutrition_provider.dart';
import 'package:zal_life/features/fitness/database/ui/screens/journey_view.dart' show JourneyView;

class PedometerScreen extends StatefulWidget {
  final bool isDark;
  const PedometerScreen({super.key, this.isDark = true});

  @override
  State<PedometerScreen> createState() => _PedometerScreenState();
}

class _PedometerScreenState extends State<PedometerScreen> with TickerProviderStateMixin {
  static const _green    = Color(0xFF32D74B);
  static const _teal     = Color(0xFF64D2FF);
  static const _purple   = Color(0xFFBF5AF2);
  static const _pink     = Color(0xFFFF375F);
  static const _gold     = Color(0xFFFFD60A);
  static const _bg       = Color(0xFF000000);
  static const _surface  = Color(0xFF0A0A0D);
  static const _elevated = Color(0xFF16161B);

  bool _isMonthlyChart = false;

  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  Color get _timeAccent {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return const Color(0xFFFFD60A);
    if (hour >= 12 && hour < 17) return const Color(0xFFFF9F0A);
    if (hour >= 17 && hour < 21) return const Color(0xFFBF5AF2);
    return const Color(0xFF0A84FF);
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PedometerProvider>().checkPermissionStatus();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pedo = context.watch<PedometerProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final accent = pedo.goalReached ? _green : _timeAccent;
    final waterToday = nutrition.getWaterForDate(DateTime.now());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _appBar(pedo)),
            if (pedo.isContinuousWalk) SliverToBoxAdapter(child: _activeWalkBanner(pedo)),
            SliverToBoxAdapter(child: _heroMultiRings(pedo, accent)),
            SliverToBoxAdapter(child: _statTiles(pedo, accent)),
            if (pedo.steps > 3000 && waterToday < 1000)
              SliverToBoxAdapter(child: _waterPrompt(nutrition)),
            SliverToBoxAdapter(child: _virtualWalkProgress(pedo)),
            SliverToBoxAdapter(child: _cadenceZones(pedo)),
            SliverToBoxAdapter(child: _calendarHeatmap(pedo)),
            SliverToBoxAdapter(child: _hourlyScroll(pedo)),
            SliverToBoxAdapter(child: _chartCard(pedo)),
            SliverToBoxAdapter(child: _questsSection(pedo)),
            SliverToBoxAdapter(child: _achievementsSection(pedo)),
            SliverToBoxAdapter(child: _goalCard(pedo)),
            if (pedo.permissionDenied)
              SliverToBoxAdapter(child: _permissionCard(pedo)),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }

  Widget _glassBox({required Widget child, Color? accent, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (accent ?? Colors.white).withOpacity(0.15), width: 1),
        boxShadow: [
          if (accent != null) BoxShadow(color: accent.withOpacity(0.05), blurRadius: 20, spreadRadius: -5),
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _appBar(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _circleBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
          const Spacer(),
          Text('ТРЕКЕР АКТИВНОСТИ', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
          const Spacer(),
          _circleBtn(Icons.tune_rounded, () => _showCalibration(pedo)),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _activeWalkBanner(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_green.withOpacity(0.2), _teal.withOpacity(0.1)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_walk_rounded, color: _green, size: 22),
            const SizedBox(width: 12),
            const Text('Активная прогулка', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const Spacer(),
            Text(
              '${pedo.walkDuration.inMinutes.toString().padLeft(2, '0')}:${(pedo.walkDuration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: _green, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroMultiRings(PedometerProvider pedo, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Center(
        child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glow = 0.3 + _pulseController.value * 0.2;
              return Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: accent.withOpacity(glow * 0.5), blurRadius: 60, spreadRadius: 10),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutExpo,
                      builder: (_, v, __) => CustomPaint(
                        size: const Size(260, 260),
                        painter: _MultiRingPainter(
                          stepProgress: pedo.progress * v,
                          distanceProgress: (pedo.distanceKm / 8.0).clamp(0.0, 1.0) * v,
                          calorieProgress: (pedo.calories / 500.0).clamp(0.0, 1.0) * v,
                          activeProgress: (pedo.activeMinutes / 30.0).clamp(0.0, 1.0) * v,
                          stepColor: accent,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_walk_rounded, color: accent, size: 28),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: pedo.steps.toDouble()),
                          duration: const Duration(milliseconds: 1000),
                          builder: (_, v, __) => Text(
                            v.round().toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.w900, letterSpacing: -2.5),
                          ),
                        ),
                        Text('ИЗ ${pedo.goal}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
              );
            }
        ),
      ),
    );
  }

  Widget _statTiles(PedometerProvider pedo, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _statTile(Icons.straighten_rounded, pedo.distanceKm.toStringAsFixed(2), 'КМ', _teal)),
          const SizedBox(width: 12),
          Expanded(child: _statTile(Icons.speed_rounded, '${pedo.cadence}', 'ШАГ/МИН', _pink)),
          const SizedBox(width: 12),
          Expanded(child: _statTile(Icons.local_fire_department, '${pedo.currentStreak}', 'СТРИК', accent)),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color) {
    return _glassBox(
      accent: color,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _waterPrompt(NutritionProvider nutrition) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: _glassBox(
        accent: _teal,
        child: Row(
          children: [
            const Text('💧', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Ты прошел 3000 шагов. Пора выпить стакан воды!', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                nutrition.addWater(250);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(12)),
                child: const Text('+250', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _virtualWalkProgress(PedometerProvider pedo) {
    const double totalRoute = 9300;
    final walked = pedo.totalDistanceKmAllTime;
    final progress = (walked / totalRoute).clamp(0.0, 1.0);
    final remaining = (totalRoute - walked).clamp(0.0, totalRoute);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JourneyView(
                walkedKm: walked,
                totalSteps: pedo.totalStepsAllTime,
                onBack: () => Navigator.pop(context),
              ),
            ),
          );
        },
        child: _glassBox(
          accent: _purple,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _purple.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Text('🚂', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Транссиб: Москва → Владивосток', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Исследуй 30 городов России', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: _purple, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation(_purple),
                    ),
                  ),
                  // Анимированный поезд
                  Positioned(
                    left: progress * (MediaQuery.of(context).size.width - 64) - 12,
                    top: -6,
                    child: const Text('🚂', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${walked.toStringAsFixed(1)} км пройдено', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  Text('${remaining.toStringAsFixed(0)} км до цели', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cadenceZones(PedometerProvider pedo) {
    final z1 = pedo.zone1Minutes;
    final z2 = pedo.zone2Minutes;
    final z3 = pedo.zone3Minutes;
    final total = z1 + z2 + z3;
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: _glassBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ЗОНЫ ИНТЕНСИВНОСТИ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _zoneRow('🐢 Прогулочная', '< 100 шаг/мин', z1, _teal),
            const SizedBox(height: 12),
            _zoneRow('🚶‍♂️ Активная', '100-120 шаг/мин', z2, _timeAccent),
            const SizedBox(height: 12),
            _zoneRow('🏃‍♂️ Быстрая', '> 120 шаг/мин', z3, _pink),
          ],
        ),
      ),
    );
  }

  Widget _zoneRow(String title, String subtitle, double minutes, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)])),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
            ],
          ),
        ),
        Text('${minutes.round()} мин', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _calendarHeatmap(PedometerProvider pedo) {
    List<StepDay> data;
    if (pedo.history.length >= 28) {
      data = pedo.history.sublist(pedo.history.length - 28);
    } else {
      data = List.generate(28, (i) {
        final d = DateTime.now().subtract(Duration(days: 27 - i));
        final existing = pedo.history.firstWhere(
              (h) => h.date.year == d.year && h.date.month == d.month && h.date.day == d.day,
          orElse: () => StepDay(date: d, steps: 0),
        );
        return existing;
      });
    }

    const daysOfWeek = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: _glassBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text('КАЛЕНДАРЬ АКТИВНОСТИ', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: daysOfWeek.map((day) => Text(day, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.w800))).toList(),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final day = data[index];
                final ratio = day.steps / pedo.goal;
                Color cellColor;
                Color borderColor = Colors.transparent;

                if (ratio >= 1.5) {
                  cellColor = _pink;
                } else if (ratio >= 1.0) {
                  cellColor = _green;
                } else if (ratio >= 0.5) {
                  cellColor = _green.withOpacity(0.5);
                } else if (ratio > 0) {
                  cellColor = _green.withOpacity(0.2);
                } else {
                  cellColor = Colors.white.withOpacity(0.04);
                }

                if (index == 27) borderColor = Colors.white.withOpacity(0.8); // Highlight today

                return Tooltip(
                  message: '${day.date.day}.${day.date.month} — ${day.steps} шагов',
                  triggerMode: TooltipTriggerMode.tap,
                  decoration: BoxDecoration(color: _elevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                  textStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _legendBox(Colors.white.withOpacity(0.04), '0'),
                _legendBox(_green.withOpacity(0.2), 'Мало'),
                _legendBox(_green.withOpacity(0.5), '50%'),
                _legendBox(_green, '100%'),
                _legendBox(_pink, '150%+'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendBox(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _hourlyScroll(PedometerProvider pedo) {
    final sortedHours = pedo.hourlySteps.keys.toList()..sort();
    if (sortedHours.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: sortedHours.length,
          itemBuilder: (context, index) {
            final hour = sortedHours[index];
            final steps = pedo.hourlySteps[hour] ?? 0;
            final maxSteps = sortedHours.map((h) => pedo.hourlySteps[h] ?? 0).reduce(math.max);
            final heightFactor = maxSteps > 0 ? steps / maxSteps : 0.0;

            return Container(
              width: 64,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 28,
                    height: 40 * heightFactor + 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [_timeAccent.withOpacity(0.8), _timeAccent.withOpacity(0.2)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('$hour:00', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('$steps', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Пульс недели (Line Chart с заливкой) ───
  Widget _chartCard(PedometerProvider pedo) {
    final data = _isMonthlyChart
        ? pedo.history
        : (pedo.history.length >= 7 ? pedo.history.sublist(pedo.history.length - 7) : pedo.history);
    if (data.isEmpty) return const SizedBox.shrink();

    final maxData = data.fold<double>(0, (m, d) => d.steps > m ? d.steps.toDouble() : m);
    final maxY = math.max(maxData, pedo.goal.toDouble()) * 1.2;

    // Формируем точки для графика
    final spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].steps.toDouble()));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _glassBox(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _timeAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Text('📈', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Text('ПУЛЬС НЕДЕЛИ', style: TextStyle(color: _timeAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _isMonthlyChart = !_isMonthlyChart),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: _elevated, borderRadius: BorderRadius.circular(12)),
                    child: Text(_isMonthlyChart ? '7 дней' : '30 дней', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => _elevated,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final d = data[spot.x.toInt()];
                          return LineTooltipItem(
                            '${d.steps} шагов\n${d.date.day}.${d.date.month}',
                            const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: pedo.goal.toDouble(),
                        color: _green.withOpacity(0.5),
                        strokeWidth: 1.5,
                        dashArray: [6, 6],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(color: _green, fontSize: 9, fontWeight: FontWeight.w800),
                          labelResolver: (_) => 'ЦЕЛЬ',
                        ),
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: _isMonthlyChart ? 5 : 1,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= data.length) return const SizedBox.shrink();
                          final d = data[i].date;
                          final text = _isMonthlyChart ? '${d.day}' : ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'][d.weekday - 1];
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(text, style: TextStyle(color: i == data.length - 1 ? _timeAccent : Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: i == data.length - 1 ? FontWeight.w900 : FontWeight.w700)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.4,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: index == data.length - 1 ? _timeAccent : _surface,
                            strokeWidth: 2,
                            strokeColor: _timeAccent,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _timeAccent.withOpacity(0.3),
                            _timeAccent.withOpacity(0.0),
                          ],
                        ),
                      ),
                      gradient: LinearGradient(
                        colors: [_timeAccent.withOpacity(0.5), _timeAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Квесты (Мощный дизайн) ───
  Widget _questsSection(PedometerProvider pedo) {
    final quests = pedo.quests;
    if (quests.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('ЕЖЕДНЕВНЫЕ КВЕСТЫ', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 14),
          ...quests.map((q) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: q.isCompleted ? _green.withOpacity(0.08) : _surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: q.isCompleted ? _green.withOpacity(0.3) : Colors.white.withOpacity(0.06)),
              boxShadow: q.isCompleted ? [BoxShadow(color: _green.withOpacity(0.05), blurRadius: 20, spreadRadius: -5)] : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: q.isCompleted ? _green.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(q.isCompleted ? Icons.check_rounded : Icons.flag_rounded, color: q.isCompleted ? _green : Colors.white38, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.title, style: TextStyle(color: Colors.white.withOpacity(q.isCompleted ? 0.5 : 1), fontSize: 14, fontWeight: FontWeight.w800, decoration: q.isCompleted ? TextDecoration.lineThrough : null)),
                      const SizedBox(height: 4),
                      Text(q.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11, fontWeight: FontWeight.w500)),
                      if (!q.isCompleted) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: q.progress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation(_timeAccent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!q.isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text('${(q.progress * 100).round()}%', style: TextStyle(color: _timeAccent, fontSize: 14, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ─── Медали (с эффектом Shimmer) ───
  Widget _achievementsSection(PedometerProvider pedo) {
    final achievements = pedo.achievements;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('ДОСТИЖЕНИЯ', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final a = achievements[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: a.unlocked
                        ? LinearGradient(colors: [_gold.withOpacity(0.15), _elevated], begin: Alignment.topLeft, end: Alignment.bottomRight)
                        : null,
                    color: a.unlocked ? null : _surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: a.unlocked ? _gold.withOpacity(0.4) : Colors.white.withOpacity(0.04), width: 0.8),
                    boxShadow: a.unlocked ? [BoxShadow(color: _gold.withOpacity(0.15), blurRadius: 24, spreadRadius: -5)] : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(a.emoji, style: TextStyle(fontSize: 32, color: a.unlocked ? null : Colors.white12)),
                          const SizedBox(height: 12),
                          Text(a.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: a.unlocked ? Colors.white : Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                        ],
                      ),
                      // Анимация блика для разблокированных медалей
                      if (a.unlocked)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                widthFactor: 0.5,
                                child: Transform.translate(
                                  offset: Offset((_shimmerController.value * 3 - 1.5) * 100, 0),
                                  child: Transform.rotate(
                                    angle: math.pi / 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.0)],
                                        ),
                                      ),
                                    ),
                                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _goalCard(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: _glassBox(
        accent: _timeAccent,
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: _timeAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Icon(Icons.flag_rounded, color: _timeAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ДНЕВНАЯ ЦЕЛЬ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text('${pedo.goal} шагов', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _editGoal(pedo),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: _timeAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Text('ИЗМЕНИТЬ', style: TextStyle(color: _timeAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionCard(PedometerProvider pedo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _glassBox(
        accent: _pink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: _pink, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text('Нет доступа к датчику движения', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => pedo.openSystemSettings(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: _pink.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: const Text('НАСТРОЙКИ', style: TextStyle(color: _pink, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => pedo.retryPermission(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: _elevated, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: const Text('ПОВТОРИТЬ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGoal(PedometerProvider pedo) async {
    final ctrl = TextEditingController(text: pedo.goal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Дневная цель', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            suffixText: 'шагов',
            suffixStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700))),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v >= 100) Navigator.pop(ctx, v);
            },
            child: Text('Сохранить', style: TextStyle(color: _timeAccent, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    if (result != null) await pedo.setGoal(result);
  }

  Future<void> _showCalibration(PedometerProvider pedo) async {
    final hCtrl = TextEditingController(text: pedo.heightCm.round().toString());
    final wCtrl = TextEditingController(text: pedo.weightKg.round().toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Калибровка', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Рост (см)',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: wCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Вес (кг)',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700))),
          TextButton(
            onPressed: () {
              final h = double.tryParse(hCtrl.text);
              final w = double.tryParse(wCtrl.text);
              if (h != null && w != null && h > 50 && w > 20) {
                pedo.setCalibration(h, w);
                Navigator.pop(ctx);
              }
            },
            child: Text('Сохранить', style: TextStyle(color: _timeAccent, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// MULTI-RING PAINTER
// =============================================================
class _MultiRingPainter extends CustomPainter {
  final double stepProgress;
  final double distanceProgress;
  final double calorieProgress;
  final double activeProgress;
  final Color stepColor;

  _MultiRingPainter({
    required this.stepProgress,
    required this.distanceProgress,
    required this.calorieProgress,
    required this.activeProgress,
    required this.stepColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    _drawRing(canvas, center, 110, 14, stepProgress, stepColor);
    _drawRing(canvas, center, 90, 14, distanceProgress, const Color(0xFF64D2FF));
    _drawRing(canvas, center, 70, 14, calorieProgress, const Color(0xFFFF375F));
    _drawRing(canvas, center, 50, 14, activeProgress, const Color(0xFFBF5AF2));
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double stroke, double progress, Color color) {
    // Фоновое кольцо
    canvas.drawCircle(
      center, radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withOpacity(0.04),
    );

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Свечение кольца
    canvas.drawArc(
      rect, startAngle, sweepAngle, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.5
        ..strokeCap = StrokeCap.round
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Основное кольцо
    canvas.drawArc(
      rect, startAngle, sweepAngle, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _MultiRingPainter old) =>
      old.stepProgress != stepProgress ||
          old.distanceProgress != distanceProgress ||
          old.calorieProgress != calorieProgress ||
          old.activeProgress != activeProgress;
}