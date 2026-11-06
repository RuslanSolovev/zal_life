// features/fitness/ui/screens/fitness_dashboard.dart
import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../nutrition/providers/nutrition_provider.dart';
import '../../../../nutrition/ui/screens/fuel_dashboard_screen.dart';
import '../../../models/enums.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/fitness_provider.dart';
import 'active_program_screen.dart';
import 'completed_programs_screen.dart';
import 'exercise_library_screen.dart';
import 'fitness_target_details_screen.dart';
import 'fitness_targets_screen.dart';
import 'photo_comparison_screen.dart';
import 'program_builder_screen.dart';
import 'program_view_screen.dart';
import 'progress_screen.dart';
import 'wellbeing_screen.dart';
import 'workout_execution_screen.dart';
import 'workout_log_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM — Premium Light + Dark Hero
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF7C818A);
  static const divider = Color(0xFFE9EBEF);
  static const elevated = Color(0xFFF0F1F4);

  static const peachSoft = Color(0xFFFBEDE4);
  static const peachDeep = Color(0xFFEF9563);

  static const lavenderSoft = Color(0xFFEEEAF8);
  static const lavenderDeep = Color(0xFF9381BB);

  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF6C9E88);

  static const skySoft = Color(0xFFE8EFF8);
  static const skyDeep = Color(0xFF7E9DC6);
}

class _Hero {
  static const bgTop = Color(0xFF1B2027);
  static const bgBottom = Color(0xFF161719);
  static const accent = Color(0xFFEF9563);
  static const textHigh = Colors.white;
  static const textLow = Color(0xFFA4A6AA);
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN DASHBOARD
// ═══════════════════════════════════════════════════════════════════
class FitnessDashboard extends StatefulWidget {
  final bool isDark;
  const FitnessDashboard({super.key, this.isDark = false});

  @override
  State<FitnessDashboard> createState() => _FitnessDashboardState();
}

class _FitnessDashboardState extends State<FitnessDashboard>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  NutritionProvider? _nutritionProvider;
  Future<NutritionProvider>? _nutritionFuture;
  String _avatarEmoji = '💪';
  String _profileName = 'Атлет';
  double _savedWeight = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _avatarEmoji = prefs.getString('avatar_emoji') ?? '💪';
      _profileName = prefs.getString('profile_name') ?? 'Александр';
      _savedWeight = prefs.getDouble('profile_weight') ?? 0;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<NutritionProvider> _getNutritionProvider() {
    _nutritionFuture ??= _initNutritionProvider();
    return _nutritionFuture!;
  }

  Future<NutritionProvider> _initNutritionProvider() async {
    if (_nutritionProvider != null) return _nutritionProvider!;
    final provider = NutritionProvider();
    await provider.init();
    _nutritionProvider = provider;
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final stats = provider.getStats();
    final profile = provider.profile;
    final activeSession = provider.activeSession;

    return Scaffold(
      backgroundColor: _P.bg,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildPowerHero(provider, profile, stats)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _buildKpiStrip(provider, stats)),
          if (activeSession != null) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _buildActiveProgramBanner(provider, activeSession),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          SliverToBoxAdapter(
            child: _buildSectionHeader('Достижения',
                actionText: 'Все', onTap: () {}),
          ),
          SliverToBoxAdapter(child: _buildAchievementsStrip(provider)),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(child: _buildTargetsPreview(provider)),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(child: _buildSectionHeader('Быстрый старт')),
          SliverToBoxAdapter(child: _buildQuickActionsGrid(provider, stats)),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: _buildSectionHeader('Питание',
                actionText: 'Сегодня',
                onTap: () async {
                  final nutritionProvider = await _getNutritionProvider();
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: nutritionProvider,
                        child: const FuelDashboardScreen(isDark: false),
                      ),
                    ),
                  );
                }),
          ),
          SliverToBoxAdapter(child: _buildFuelPreview()),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: _buildSectionHeader('Программы',
                actionText: 'Все',
                onTap: () => _showProgramsList(context, provider)),
          ),
          SliverToBoxAdapter(child: _buildProgramsRow(provider)),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: _buildSectionHeader('Ваш прогресс',
                actionText: 'Отчёт',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: const ProgressScreen(isDark: false),
                      ),
                    ),
                  );
                }),
          ),
          SliverToBoxAdapter(child: _buildProgressCards(provider, stats)),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(child: _buildSectionHeader('Больше возможностей')),
          SliverToBoxAdapter(child: _buildExtraGrid(provider)),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          SliverToBoxAdapter(
            child: Center(
              child: Text('Маленькие шаги. Большие перемены.',
                  style: GoogleFonts.inter(
                      color: _P.textMuted, fontSize: 10, letterSpacing: 0.2)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  UNIVERSAL IMAGE HELPERS
  // ═════════════════════════════════════════════════════════
  Widget _buildProgramCover(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: _P.bg),
      );
    }
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: _P.bg),
        errorWidget: (_, __, ___) => Container(color: _P.bg),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: _P.bg),
    );
  }

  Widget _buildThumbImage(String? url, String emoji, double size) {
    Widget fallback() => Center(
      child: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
    );
    if (url == null || url.isEmpty) return fallback();
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (_, __) => fallback(),
        errorWidget: (_, __, ___) => fallback(),
      );
    }
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HERO SECTION (Dark Mode)
  // ═════════════════════════════════════════════════════════
  Widget _buildPowerHero(FitnessProvider provider, UserFitnessProfile? profile,
      Map<String, dynamic> stats) {
    final now = DateTime.now();
    final last7 = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final weekWorkouts = last7.fold<int>(
        0,
            (sum, day) =>
        sum +
            provider
                .getLogsForDate(day)
                .where((log) => log.status == WorkoutDayStatus.completed)
                .length);
    final displayName =
    _profileName.isNotEmpty ? _profileName : (profile?.name ?? 'Атлет');
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final weight =
    _savedWeight > 0 ? _savedWeight : (profile?.currentWeight ?? 78.5);
    final volume = ((stats['totalVolume'] ?? 0.0) as num).toDouble();

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Hero.bgTop, _Hero.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 100,
              left: 100,
              child: IgnorePointer(
                child: Container(
                  width: 320,
                  height: 310,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _Hero.accent.withOpacity(0.23),
                        _Hero.accent.withOpacity(0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildPowerAvatar(provider),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Доброе утро,',
                                style: GoogleFonts.inter(
                                    color: _Hero.textLow, fontSize: 12)),
                            Text(displayName,
                                style: GoogleFonts.inter(
                                    color: _Hero.textHigh,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.4)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showEditWeightDialog(profile),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.09),
                                width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monitor_weight_outlined,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '${weight.toStringAsFixed(1)} кг',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 130,
                              height: 130,
                              child: CircularProgressIndicator(
                                value: (streak / 30).clamp(0.0, 1.0),
                                strokeWidth: 8,
                                backgroundColor:
                                Colors.white.withOpacity(0.06),
                                valueColor: const AlwaysStoppedAnimation(
                                    _Hero.accent),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$streak',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -2,
                                        height: 1)),
                                Text('дней подряд',
                                    style: GoogleFonts.inter(
                                        color: _Hero.textLow, fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text('ЭТА НЕДЕЛЯ',
                                          style: GoogleFonts.inter(
                                              color: _Hero.textLow,
                                              fontSize: 10,
                                              letterSpacing: 1.2)),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                        textBaseline:
                                        TextBaseline.alphabetic,
                                        children: [
                                          Text('$weekWorkouts',
                                              style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: -1)),
                                          const SizedBox(width: 4),
                                          Text('/ 4',
                                              style: GoogleFonts.inter(
                                                  color: _Hero.textLow,
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withOpacity(0.1)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text('ОБЪЕМ',
                                          style: GoogleFonts.inter(
                                              color: _Hero.textLow,
                                              fontSize: 10,
                                              letterSpacing: 1.2)),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                        textBaseline:
                                        TextBaseline.alphabetic,
                                        children: [
                                          Text(_formatVolume(volume),
                                              style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: -1)),
                                          const SizedBox(width: 4),
                                          Text('кг',
                                              style: GoogleFonts.inter(
                                                  color: _Hero.textLow,
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Ещё 2 дня до нового достижения',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFFC5BBB3),
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _buildHeroChip(
                              '⚡', '${_formatVolume(volume)} кг')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHeroChip('📏', '12,6 км')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHeroChip('🥊', '24 раунда')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerAvatar(FitnessProvider provider) {
    return GestureDetector(
      onTap: () => _showEditProfileDialog(provider),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.19), width: 1),
          color: _Hero.bgBottom,
        ),
        alignment: Alignment.center,
        child: Text(_avatarEmoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  Widget _buildHeroChip(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(text,
              style: GoogleFonts.inter(
                  color: const Color(0xFFDCDDE0), fontSize: 11)),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  KPI STRIP
  // ═════════════════════════════════════════════════════════
  Widget _buildKpiStrip(FitnessProvider provider, Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
              child: _buildKpiTile(
                  '${stats['workoutsThisWeek'] ?? 0}/4',
                  'Неделя',
                  Icons.calendar_today_rounded,
                  _P.lavenderSoft,
                  _P.lavenderDeep)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildKpiTile('${stats['totalWorkouts'] ?? 0}', 'Всего',
                  Icons.fitness_center_rounded, _P.greenSoft, _P.greenDeep)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildKpiTile(
                  '${provider.activeTargets.length}',
                  'Цели',
                  Icons.flag_rounded,
                  _P.peachSoft,
                  _P.peachDeep)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildKpiTile('${provider.photos.length}', 'Фото',
                  Icons.photo_camera_rounded, _P.skySoft, _P.skyDeep)),
        ],
      ),
    );
  }

  Widget _buildKpiTile(
      String value, String label, IconData icon, Color soft, Color deep) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _P.divider, width: 1),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1D2530).withOpacity(0.02),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: soft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: deep, size: 16),
          ),
          const SizedBox(height: 7),
          Text(value,
              style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5)),
          Text(label,
              style: GoogleFonts.inter(color: _P.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  ACTIVE PROGRAM — with cover
  // ═════════════════════════════════════════════════════════
  Widget _buildActiveProgramBanner(
      FitnessProvider provider, ProgramSession session) {
    final program = provider.programs.firstWhere(
            (p) => p.id == session.programId,
        orElse: () => WorkoutProgram(id: '', name: 'Неизвестная программа'));
    final progress = session.progressPercent;
    final currentDayIndex = session.currentDayIndex;
    final hasCover = program.backgroundImage != null &&
        program.backgroundImage!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: provider,
                child: ActiveProgramScreen(program: program, isDark: false),
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _P.divider, width: 1),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF1D2530).withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── COVER ──
              SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasCover)
                      _buildProgramCover(program.backgroundImage!)
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEEEBF7), Color(0xFFE7F0E8)],
                          ),
                        ),
                        child: Center(
                          child: Text(program.emoji,
                              style: const TextStyle(fontSize: 56)),
                        ),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: hasCover
                              ? [
                            Colors.transparent,
                            Colors.black.withOpacity(0.75)
                          ]
                              : [
                            Colors.transparent,
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                    // Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _P.greenDeep,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('ВАША ПРОГРАММА',
                                style: GoogleFonts.inter(
                                    color: _P.greenDeep,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                    ),
                    // Title on cover
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Text(
                        program.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: hasCover ? Colors.white : _P.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── BODY ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                            'День ${currentDayIndex + 1} из ${program.days.length}',
                            style: GoogleFonts.inter(
                                color: _P.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text('${(progress * 100).round()}%',
                            style: GoogleFonts.inter(
                                color: _P.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: _P.elevated,
                        valueColor:
                        const AlwaysStoppedAnimation(_P.greenDeep),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _P.greenDeep,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text('Продолжить',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
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
    );
  }

  // ═════════════════════════════════════════════════════════
  //  ACHIEVEMENTS
  // ═════════════════════════════════════════════════════════
  Widget _buildAchievementsStrip(FitnessProvider provider) {
    final achievements = _getAchievements(provider);
    achievements.sort((a, b) =>
        (b.isUnlocked ? 1 : 0).compareTo(a.isUnlocked ? 1 : 0));

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final a = achievements[index];
          final isLocked = !a.isUnlocked;
          return Container(
            width: 144,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isLocked ? _P.elevated : _P.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _P.divider, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: isLocked
                          ? _P.elevated
                          : a.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(a.emoji,
                      style: TextStyle(
                          fontSize: 22,
                          color: isLocked ? _P.textMuted : null)),
                ),
                const Spacer(),
                Text(a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: isLocked ? _P.textMuted : _P.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                    isLocked
                        ? '${(a.progress * 100).round()}% выполнено'
                        : a.requirement,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: _P.textMuted, fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  TARGETS — thumbnails + dual tap
  // ═════════════════════════════════════════════════════════
  Widget _buildTargetsPreview(FitnessProvider provider) {
    final active = provider.activeTargets;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _openTargets(provider),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _P.divider, width: 1),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF1D2530).withOpacity(0.02),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ваши цели',
                      style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6)),
                  GestureDetector(
                    onTap: () => _openTargets(provider),
                    child: Text('Изменить',
                        style: GoogleFonts.inter(
                            color: _P.textMuted, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (active.isEmpty)
                _buildEmptyTarget(provider)
              else
                ...active.take(2).map((t) => _buildTargetRow(t, provider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetRow(FitnessTarget target, FitnessProvider provider) {
    Exercise? exercise;
    if (target.exerciseId != null && target.exerciseId!.isNotEmpty) {
      try {
        exercise =
            provider.exercises.firstWhere((e) => e.id == target.exerciseId);
      } catch (_) {
        exercise = null;
      }
    }
    final emoji = exercise?.exerciseType.emoji ?? target.type.emoji;
    final imageUrl = exercise?.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: FitnessTargetDetailsScreen(
                  target: target, isDark: false),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: target.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: target.accentColor.withOpacity(0.20),
                    width: 0.8),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: hasImage
                  ? _buildThumbImage(imageUrl, emoji, 42)
                  : Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(target.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                color: _P.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text('${(target.progressPercent * 100).round()}%',
                          style: GoogleFonts.inter(
                              color: _P.textMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: target.progressPercent.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: _P.elevated,
                      valueColor:
                      AlwaysStoppedAnimation(target.accentColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: _P.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTarget(FitnessProvider provider) {
    return GestureDetector(
      onTap: () => _openTargets(provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _P.elevated, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: _P.peachDeep, shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Поставить первую цель',
                      style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text('Например, жим 100 кг',
                      style: GoogleFonts.inter(
                          color: _P.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _P.textMuted),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  QUICK ACTIONS — adaptive grid
  // ═════════════════════════════════════════════════════════
  Widget _buildQuickActionsGrid(
      FitnessProvider provider, Map<String, dynamic> stats) {
    final items = [
      _QuickItemData(
        title: 'Начать тренировку',
        subtitle: 'Быстрый старт',
        icon: Icons.play_arrow_rounded,
        soft: _P.peachSoft,
        deep: _P.peachDeep,
        onTap: () => _quickStartWorkout(provider),
      ),
      _QuickItemData(
        title: 'Упражнения',
        subtitle: 'Библиотека',
        icon: Icons.fitness_center_rounded,
        soft: _P.lavenderSoft,
        deep: _P.lavenderDeep,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const ExerciseLibraryScreen(isDark: false),
            ),
          ),
        ),
      ),
      _QuickItemData(
        title: 'Дневник',
        subtitle: 'Все тренировки',
        icon: Icons.book_rounded,
        soft: _P.skySoft,
        deep: _P.skyDeep,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const WorkoutLogScreen(isDark: false),
            ),
          ),
        ),
      ),
      _QuickItemData(
        title: 'Самочувствие',
        subtitle: 'Настроение',
        icon: Icons.mood_rounded,
        soft: _P.greenSoft,
        deep: _P.greenDeep,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const WellbeingScreen(isDark: false),
            ),
          ),
        ),
      ),
    ];
    return _buildAdaptiveGrid(items);
  }

  Widget _buildExtraGrid(FitnessProvider provider) {
    final items = [
      _QuickItemData(
        title: 'Шаблоны',
        subtitle: 'Пресеты',
        icon: Icons.bookmark_border_rounded,
        soft: _P.lavenderSoft,
        deep: _P.lavenderDeep,
        onTap: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Шаблоны скоро появятся'),
              backgroundColor: _P.lavenderDeep,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          );
        },
      ),
      _QuickItemData(
        title: 'Фотографии',
        subtitle: 'Прогресс в кадрах',
        icon: Icons.photo_library_outlined,
        soft: _P.peachSoft,
        deep: _P.peachDeep,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const PhotoComparisonScreen(isDark: false),
            ),
          ),
        ),
      ),
      _QuickItemData(
        title: 'История',
        subtitle: 'Программы',
        icon: Icons.history_rounded,
        soft: _P.skySoft,
        deep: _P.skyDeep,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const CompletedProgramsScreen(isDark: false),
            ),
          ),
        ),
      ),
      _QuickItemData(
        title: 'Самочувствие',
        subtitle: 'Сон и энергия',
        icon: Icons.self_improvement_rounded,
        soft: _P.greenSoft,
        deep: _P.greenDeep,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const WellbeingScreen(isDark: false),
            ),
          ),
        ),
      ),
    ];
    return _buildAdaptiveGrid(items);
  }

  Widget _buildAdaptiveGrid(List<_QuickItemData> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 128,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildQuickCard(items[index]),
      ),
    );
  }

  Widget _buildQuickCard(_QuickItemData item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        item.onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _P.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: item.soft,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(item.icon, color: item.deep, size: 18),
                ),
                const Spacer(),
                const Icon(Icons.arrow_outward_rounded,
                    color: _P.textMuted, size: 14),
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: _P.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  NUTRITION
  // ═════════════════════════════════════════════════════════
  Widget _buildFuelPreview() {
    return FutureBuilder<NutritionProvider>(
      future: _getNutritionProvider(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingCard();
        final nutritionProvider = snapshot.data!;
        return ChangeNotifierProvider.value(
          value: nutritionProvider,
          child: Consumer<NutritionProvider>(
            builder: (context, provider, _) {
              if (provider.defaultGoals == null) return _buildLoadingCard();
              final today = DateTime.now();
              final summary = provider.getSummaryForDate(today);
              final goals = provider.getGoalsForDate(today);
              if (summary == null || goals == null) return _buildLoadingCard();

              final percent = summary.percentOf(goals);
              final water = summary.waterPercentOf(goals);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: const FuelDashboardScreen(isDark: false),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _P.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _P.divider, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: CircularProgressIndicator(
                                        value: 1,
                                        strokeWidth: 8,
                                        valueColor:
                                        const AlwaysStoppedAnimation(
                                            _P.peachSoft)),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: CircularProgressIndicator(
                                        value: percent.clamp(0.0, 1.0),
                                        strokeWidth: 8,
                                        strokeCap: StrokeCap.round,
                                        valueColor:
                                        const AlwaysStoppedAnimation(
                                            _P.peachDeep)),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${summary.calories.round()}',
                                          style: GoogleFonts.inter(
                                              color: _P.text,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.5,
                                              height: 1)),
                                      Text(
                                          'из ${goals.calories.round()}',
                                          style: GoogleFonts.inter(
                                              color: _P.textMuted,
                                              fontSize: 9)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildMacroRow('Белки', summary.protein,
                                      goals.protein, _P.lavenderDeep),
                                  const SizedBox(height: 12),
                                  _buildMacroRow('Жиры', summary.fat,
                                      goals.fat, _P.peachDeep),
                                  const SizedBox(height: 12),
                                  _buildMacroRow('Углеводы', summary.carbs,
                                      goals.carbs, _P.greenDeep),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(height: 1, color: _P.divider),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.water_drop_rounded,
                                color: _P.skyDeep, size: 16),
                            const SizedBox(width: 6),
                            Text('Вода',
                                style: GoogleFonts.inter(
                                    color: _P.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Text(
                                '${(summary.waterMl / 1000).toStringAsFixed(1)} / ${(goals.waterMl / 1000).toStringAsFixed(1)} л',
                                style: GoogleFonts.inter(
                                    color: _P.textMuted, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(10, (i) {
                            final filled = (i / 10) < water;
                            return Expanded(
                              child: Container(
                                margin:
                                EdgeInsets.only(right: i < 9 ? 4 : 0),
                                height: 6,
                                decoration: BoxDecoration(
                                  color: filled ? _P.skyDeep : _P.skySoft,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMacroRow(
      String label, double current, double goal, Color color) {
    final pct = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: _P.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            Text('${current.round()} / ${goal.round()} г',
                style: GoogleFonts.inter(
                    color: _P.textMuted, fontSize: 9)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: _P.elevated,
              valueColor: AlwaysStoppedAnimation(color)),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() => Container(
    height: 200,
    margin: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: _P.elevated,
      borderRadius: BorderRadius.circular(24),
    ),
  );

  // ═════════════════════════════════════════════════════════
  //  PROGRAMS
  // ═════════════════════════════════════════════════════════
  Widget _buildProgramsRow(FitnessProvider provider) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: provider.programs.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == provider.programs.length) {
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: const ProgramBuilderScreen(isDark: false),
                  ),
                ),
              ),
              child: Container(
                width: 150,
                decoration: BoxDecoration(
                    color: _P.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _P.divider, width: 1)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                            color: _P.peachSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.add_rounded,
                            color: _P.peachDeep)),
                    const SizedBox(height: 12),
                    Text('Создать',
                        style: GoogleFonts.inter(
                            color: _P.text, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }
          final p = provider.programs[index];
          final isActive = provider.activeSession?.programId == p.id;
          return _buildProgramCard(p, isActive, provider);
        },
      ),
    );
  }

  Widget _buildProgramCard(
      WorkoutProgram p, bool isActive, FitnessProvider provider) {
    final hasBg =
        p.backgroundImage != null && p.backgroundImage!.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: isActive
                ? ActiveProgramScreen(program: p, isDark: false)
                : ProgramViewScreen(program: p, isDark: false),
          ),
        ),
      ),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _P.divider, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasBg) _buildProgramCover(p.backgroundImage!),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: hasBg
                        ? [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85)
                    ]
                        : [
                      Colors.transparent,
                      Colors.transparent
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: hasBg
                                ? Colors.white.withOpacity(0.2)
                                : _P.elevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(p.emoji,
                              style: const TextStyle(fontSize: 20)),
                        ),
                        const Spacer(),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: _P.greenDeep,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('АКТИВНА',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: hasBg ? Colors.white : _P.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${p.days.length} дней · ${p.sessionDurationMinutes} мин',
                      style: GoogleFonts.inter(
                        color: hasBg ? Colors.white70 : _P.textMuted,
                        fontSize: 11,
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

  // ═════════════════════════════════════════════════════════
  //  PROGRESS CARDS — tappable, clear, real progress
  // ═════════════════════════════════════════════════════════
  Widget _buildProgressCards(
      FitnessProvider provider, Map<String, dynamic> stats) {
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final total = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    final week = ((stats['workoutsThisWeek'] ?? 0) as num).toInt();
    const weekGoal = 4;

    void open() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const ProgressScreen(isDark: false),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildProgressCard(
              title: 'Серия',
              value: '$streak',
              unit: 'дн.',
              label: 'подряд',
              deep: _P.peachDeep,
              progress: (streak / 30).clamp(0.0, 1.0),
              onTap: open,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildProgressCard(
              title: 'Всего',
              value: '$total',
              unit: '',
              label: 'тренировок',
              deep: _P.lavenderDeep,
              progress: (total / 50).clamp(0.0, 1.0),
              onTap: open,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildProgressCard(
              title: 'Неделя',
              value: '$week',
              unit: '/$weekGoal',
              label: 'тренировок',
              deep: _P.greenDeep,
              progress: (week / weekGoal).clamp(0.0, 1.0),
              onTap: open,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String value,
    required String unit,
    required String label,
    required Color deep,
    required double progress,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _P.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: _P.textMuted, fontSize: 10)),
                const Spacer(),
                const Icon(Icons.arrow_outward_rounded,
                    size: 12, color: _P.textMuted),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1,
                          height: 1)),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(unit,
                      style: GoogleFonts.inter(
                          color: _P.textMuted, fontSize: 11)),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    color: _P.textMuted, fontSize: 10)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: _P.elevated,
                valueColor: AlwaysStoppedAnimation(deep),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HEADER & HELPERS
  // ═════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title,
      {String? actionText, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  color: _P.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.6)),
          if (actionText != null && onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Text(actionText,
                      style: GoogleFonts.inter(
                          color: _P.textMuted, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: _P.textMuted, size: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(1)}k';
    return volume.toStringAsFixed(0);
  }

  // ═════════════════════════════════════════════════════════
  //  NAVIGATION & MODALS
  // ═════════════════════════════════════════════════════════
  void _openTargets(FitnessProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const FitnessTargetsScreen(isDark: false),
        ),
      ),
    );
  }

  void _showProgramsList(BuildContext context, FitnessProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _P.divider,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Все программы',
                      style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded,
                        color: _P.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.6),
                child: provider.programs.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('Пока нет программ',
                      style: GoogleFonts.inter(color: _P.textMuted)),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: provider.programs.length,
                  itemBuilder: (context, i) {
                    final p = provider.programs[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _P.elevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(p.emoji,
                            style: const TextStyle(fontSize: 22)),
                      ),
                      title: Text(p.name,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${p.days.length} дней · ${p.sessionDurationMinutes} мин',
                          style: GoogleFonts.inter(
                              color: _P.textMuted, fontSize: 12)),
                      trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: _P.textMuted),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChangeNotifierProvider.value(
                                  value: provider,
                                  child: ProgramViewScreen(
                                      program: p, isDark: false),
                                ),
                          ),
                        );
                      },
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

  // ═════════════════════════════════════════════════════════
  //  QUICK START WORKOUT — full modal
  // ═════════════════════════════════════════════════════════
  void _quickStartWorkout(FitnessProvider provider) {
    HapticFeedback.mediumImpact();
    final quickDay = WorkoutDay(
      id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
      programId: 'quick',
      dayNumber: 1,
      exercises: [],
    );
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = provider.exercises
                .where((e) =>
            query.isEmpty || e.name.toLowerCase().contains(query))
                .toList();
            final canStart = quickDay.exercises.isNotEmpty;

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Container(
                      width: 38,
                      height: 5,
                      decoration: BoxDecoration(
                          color: _P.divider,
                          borderRadius: BorderRadius.circular(3))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                            color: _P.greenSoft,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.bolt_rounded,
                            color: _P.greenDeep, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Быстрая тренировка',
                                style: GoogleFonts.inter(
                                    color: _P.text,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Выберите упражнения',
                                style: GoogleFonts.inter(
                                    color: _P.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (_) => setSheetState(() {}),
                    style: GoogleFonts.inter(color: _P.text),
                    decoration: InputDecoration(
                      hintText: 'Поиск упражнений',
                      hintStyle: GoogleFonts.inter(color: _P.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _P.textMuted, size: 20),
                      filled: true,
                      fillColor: _P.bg,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                        child: Text('Ничего не найдено',
                            style: GoogleFonts.inter(
                                color: _P.textMuted)))
                        : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        final added = quickDay.exercises.any(
                                (item) =>
                            item.exerciseId == exercise.id);
                        final accent =
                        exercise.muscleGroups.isNotEmpty
                            ? exercise.muscleGroups.first.color
                            : _P.greenDeep;
                        final hasImage =
                            exercise.imageUrl != null &&
                                exercise.imageUrl!.isNotEmpty;

                        return Container(
                          decoration: BoxDecoration(
                            color: _P.bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _P.divider, width: 0.6),
                          ),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                borderRadius:
                                BorderRadius.circular(11),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: hasImage
                                  ? _buildThumbImage(
                                  exercise.imageUrl,
                                  exercise.exerciseType.emoji,
                                  40)
                                  : Center(
                                child: Text(
                                    exercise
                                        .exerciseType.emoji,
                                    style: const TextStyle(
                                        fontSize: 18)),
                              ),
                            ),
                            title: Text(exercise.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    color: _P.text,
                                    fontWeight: FontWeight.w500)),
                            trailing: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setSheetState(() {
                                  if (added) {
                                    quickDay.exercises.removeWhere(
                                            (item) =>
                                        item.exerciseId ==
                                            exercise.id);
                                  } else {
                                    quickDay.exercises.add(
                                        WorkoutExercise(
                                          id:
                                          'quick_ex_${quickDay.exercises.length}',
                                          exerciseId: exercise.id,
                                          order:
                                          quickDay.exercises.length,
                                          sets: [
                                            ExerciseSet(
                                                setNumber: 1,
                                                reps: 10,
                                                weight: 0)
                                          ],
                                        ));
                                  }
                                });
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: added
                                      ? _P.peachSoft
                                      : _P.greenSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                    added
                                        ? Icons.remove_rounded
                                        : Icons.add_rounded,
                                    color: added
                                        ? _P.peachDeep
                                        : _P.greenDeep,
                                    size: 20),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (canStart)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChangeNotifierProvider.value(
                                      value: provider,
                                      child: WorkoutExecutionScreen(
                                          day: quickDay, isDark: false),
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _P.greenDeep,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                              'НАЧАТЬ · ${quickDay.exercises.length} УПР.',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════
  //  WEIGHT & PROFILE DIALOGS
  // ═════════════════════════════════════════════════════════
  Future<void> _showEditWeightDialog(UserFitnessProfile? profile) async {
    final currentWeight = _savedWeight > 0
        ? _savedWeight
        : (profile?.currentWeight ?? 78.5);
    final controller =
    TextEditingController(text: currentWeight.toStringAsFixed(1));

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: _P.divider,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                Text('ВАШ ВЕС',
                    style: GoogleFonts.inter(
                        color: _P.greenDeep,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8)),
                const SizedBox(height: 4),
                Text('Вес тела',
                    style: GoogleFonts.inter(
                        color: _P.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: _P.text),
                  decoration: InputDecoration(
                    suffixText: 'кг',
                    suffixStyle: GoogleFonts.inter(
                        color: _P.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                    filled: true,
                    fillColor: _P.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final v = double.tryParse(
                          controller.text.replaceAll(',', '.'));
                      if (v == null || v <= 0 || v > 500) {
                        HapticFeedback.mediumImpact();
                        return;
                      }
                      Navigator.pop(ctx, v);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _P.greenDeep,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('СОХРАНИТЬ',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('profile_weight', result);
      if (!mounted) return;
      setState(() => _savedWeight = result);
      HapticFeedback.lightImpact();
    }
  }

  void _showEditProfileDialog(FitnessProvider provider) {
    final controller = TextEditingController(
        text: _profileName.isNotEmpty
            ? _profileName
            : (provider.profile?.name ?? ''));
    const emojis = [
      '💪', '🏋️', '🏃', '🧘', '🚴', '🤸', '🥊',
      '🔥', '⚡', '🦁', '🐺', '🦅', '👑', '🎯'
    ];
    String selectedEmoji = _avatarEmoji;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                        width: 38,
                        height: 5,
                        decoration: BoxDecoration(
                            color: _P.divider,
                            borderRadius: BorderRadius.circular(3))),
                  ),
                  const SizedBox(height: 20),
                  Text('ПРОФИЛЬ',
                      style: GoogleFonts.inter(
                          color: _P.greenDeep,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0)),
                  const SizedBox(height: 4),
                  Text('Атлет',
                      style: GoogleFonts.inter(
                          color: _P.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.8)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    style: GoogleFonts.inter(
                        color: _P.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Введите имя',
                      hintStyle:
                      GoogleFonts.inter(color: _P.textMuted),
                      filled: true,
                      fillColor: _P.bg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('АВАТАР',
                      style: GoogleFonts.inter(
                          color: _P.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emojis.map((emoji) {
                      final selected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => selectedEmoji = emoji);
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: selected ? _P.greenSoft : _P.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selected
                                    ? _P.greenDeep
                                    : Colors.transparent,
                                width: 1.5),
                          ),
                          child: Center(
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 24))),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newName = controller.text.trim();
                        final prefs =
                        await SharedPreferences.getInstance();
                        await prefs.setString(
                            'avatar_emoji', selectedEmoji);
                        if (newName.isNotEmpty) {
                          await prefs.setString(
                              'profile_name', newName);
                        }
                        if (!mounted) return;
                        setState(() {
                          _avatarEmoji = selectedEmoji;
                          if (newName.isNotEmpty) _profileName = newName;
                        });
                        Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _P.greenDeep,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('СОХРАНИТЬ',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Achievement> _getAchievements(FitnessProvider provider) {
    final stats = provider.getStats();
    final streak = ((stats['currentStreak'] ?? 0) as num).toInt();
    final total = ((stats['totalWorkouts'] ?? 0) as num).toInt();
    final volume = ((stats['totalVolume'] ?? 0) as num).toDouble();
    final week = ((stats['workoutsThisWeek'] ?? 0) as num).toInt();

    double progress(num current, num goal) =>
        goal <= 0 ? 0 : (current / goal).clamp(0.0, 1.0).toDouble();

    return [
      Achievement('🏁', 'Первый шаг', 'Проведи первую тренировку', 'Тренировки',
          _P.greenDeep, total >= 1, progress(total, 1), '1 тренировка'),
      Achievement('💪', 'Десятка', '10 полноценных тренировок', 'Тренировки',
          _P.skyDeep, total >= 10, progress(total, 10), '10 тренировок'),
      Achievement('🎖️', 'Полтинник', 'Пройди отметку в 50 тренировок',
          'Тренировки', _P.lavenderDeep, total >= 50, progress(total, 50),
          '50 тренировок'),
      Achievement('🔥', 'Серия 3', '3 дня тренировок подряд', 'Серии',
          _P.peachDeep, streak >= 3, progress(streak, 3), '3 дня подряд'),
      Achievement('🚀', 'Неделя силы', '7 дней тренировок подряд', 'Серии',
          _P.lavenderDeep, streak >= 7, progress(streak, 7), '7 дней подряд'),
      Achievement('🏋️', 'Тонна', 'Набери 10 000 кг тоннажа', 'Объёмы',
          _P.peachDeep, volume >= 10000, progress(volume, 10000),
          '10 000 кг'),
      Achievement('⚡', 'Неделя в ударе', '3 тренировки за неделю',
          'Тренировки', _P.peachDeep, week >= 3, progress(week, 3),
          '3 тренировки'),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════
class Achievement {
  final String emoji;
  final String title;
  final String description;
  final String category;
  final Color color;
  final bool isUnlocked;
  final double progress;
  final String requirement;
  const Achievement(this.emoji, this.title, this.description, this.category,
      this.color, this.isUnlocked, this.progress, this.requirement);
}

class _QuickItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color soft;
  final Color deep;
  final VoidCallback onTap;
  const _QuickItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.soft,
    required this.deep,
    required this.onTap,
  });
}