import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/enums.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/fitness_provider.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/exercise_image_selector.dart';
import 'exercise_detail_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM (Синхронизировано с HomeScreen)
// ═══════════════════════════════════════════════════════════════════
class _Palette {
  static const bg = Color(0xFFF6F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF263D36);
  static const textMuted = Color(0xFF7C8982);
  static const green = Color(0xFF426C59);
  static const greenSoft = Color(0xFFE7EFE5);
  static const sage = Color(0xFF8CAB93);
  static const peach = Color(0xFFC79475);
  static const peachSoft = Color(0xFFF5E6DC);
  static const pink = Color(0xFFBB8F9D);
  static const pinkSoft = Color(0xFFF2E4E7);
  static const lavender = Color(0xFFCDB4DB);
  static const lavenderDeep = Color(0xFF8A5DA5);
  static const yellow = Color(0xFFE7D9B8);
  static const divider = Color(0xFFE5E8E1);
}

class _R {
  final double scale;
  _R(BuildContext context) : scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);
  double s(double v) => v * scale;
  double fs(double v) => v * scale;
}

class _AppImg extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  final Widget? fallback;
  const _AppImg({this.path, this.fit = BoxFit.cover, this.fallback});

  @override
  Widget build(BuildContext context) {
    final p = path;
    final fb = fallback ?? const SizedBox.shrink();
    if (p == null || p.isEmpty) return fb;
    if (p.startsWith('assets/')) {
      return Image.asset(p, fit: fit, errorBuilder: (_, __, ___) => fb);
    }
    if (p.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: p,
        fit: fit,
        placeholder: (_, __) => fb,
        errorWidget: (_, __, ___) => fb,
      );
    }
    return Image.file(File(p), fit: fit, errorBuilder: (_, __, ___) => fb);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EXERCISE LIBRARY SCREEN
// ═══════════════════════════════════════════════════════════════════
class ExerciseLibraryScreen extends StatefulWidget {
  final bool isDark;
  final bool isCompact;

  const ExerciseLibraryScreen({super.key, this.isDark = false, this.isCompact = false});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  MuscleGroup? _selectedMuscle;
  ExerciseType? _selectedType;

  final List<Map<String, dynamic>> _tabsData = const [
    {'label': 'ВСЕ', 'type': null},
    {'label': 'СИЛОВЫЕ', 'type': ExerciseType.strength},
    {'label': 'КАРДИО', 'type': ExerciseType.cardio},
    {'label': 'СВОЙ ВЕС', 'type': ExerciseType.bodyweight},
    {'label': 'БОКС', 'type': ExerciseType.boxing},
    {'label': 'ЙОГА', 'type': ExerciseType.yoga},
  ];

  List<Tab> get _tabs => _tabsData.map((t) => Tab(text: t['label'] as String)).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType = _tabsData[_tabController.index]['type'] as ExerciseType?;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final exercises = _getFilteredExercises(provider);
    final r = _R(context);

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: _Palette.bg.withOpacity(0.94),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 60,
            leading: Padding(
              padding: EdgeInsets.only(left: r.s(16), top: r.s(10), bottom: r.s(10)),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                child: Container(
                  width: r.s(36),
                  height: r.s(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _Palette.divider, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _Palette.peach.withOpacity(0.06),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.chevron_left_rounded, color: _Palette.text, size: r.s(22)),
                ),
              ),
            ),
            title: Text(
              'Упражнения',
              style: GoogleFonts.inter(
                fontSize: r.fs(15),
                fontWeight: FontWeight.w600,
                color: _Palette.text,
                letterSpacing: -0.2,
              ),
            ),
            centerTitle: true,
          ),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), r.s(8), r.s(20), r.s(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'БАЗА ЗНАНИЙ',
                    style: GoogleFonts.inter(
                      color: _Palette.peach,
                      fontSize: r.fs(9),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  SizedBox(height: r.s(3)),
                  Text(
                    'Упражнения',
                    style: GoogleFonts.inter(
                      color: _Palette.text,
                      fontSize: r.fs(28),
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.7,
                    ),
                  ),
                  SizedBox(height: r.s(4)),
                  Text(
                    '${provider.exercises.length} упражнений в библиотеке',
                    style: GoogleFonts.inter(
                      color: _Palette.textMuted,
                      fontSize: r.fs(13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search
          SliverToBoxAdapter(child: _buildSearchBar(r)),

          // Type tabs
          SliverToBoxAdapter(child: _buildTypeTabs(r)),

          // Muscle filter
          SliverToBoxAdapter(child: _buildMuscleFilter(r)),

          SliverToBoxAdapter(child: SizedBox(height: r.s(12))),

          // Grid
          if (exercises.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState(r))
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(r.s(16), 0, r.s(16), r.s(120)),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: r.s(12),
                  mainAxisSpacing: r.s(12),
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final exercise = exercises[index];
                    return _buildExerciseCard(exercise, provider, r);
                  },
                  childCount: exercises.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: r.s(8)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r.s(16)),
            boxShadow: [
              BoxShadow(
                color: _Palette.peach.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showAddExerciseDialog(context, provider, r);
            },
            backgroundColor: _Palette.peach,
            elevation: 0,
            icon: Icon(Icons.add_rounded, color: Colors.white, size: r.s(20)),
            label: Text(
              'СОЗДАТЬ',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontSize: r.fs(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  SEARCH
  // ═════════════════════════════════════════════════════════
  Widget _buildSearchBar(_R r) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(8)),
      child: Container(
        height: r.s(50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.s(14)),
          border: Border.all(color: _Palette.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: _Palette.peach.withOpacity(0.05),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: r.s(12)),
            Container(
              width: r.s(28),
              height: r.s(28),
              decoration: BoxDecoration(
                color: _Palette.peachSoft,
                borderRadius: BorderRadius.circular(r.s(8)),
              ),
              child: Icon(Icons.search_rounded, color: _Palette.peach, size: r.s(16)),
            ),
            SizedBox(width: r.s(10)),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: GoogleFonts.inter(
                  color: _Palette.text,
                  fontSize: r.fs(14),
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Найти упражнение…',
                  hintStyle: GoogleFonts.inter(
                    color: _Palette.textMuted,
                    fontSize: r.fs(14),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Padding(
                  padding: EdgeInsets.all(r.s(10)),
                  child: Icon(Icons.close_rounded, color: _Palette.textMuted, size: r.s(16)),
                ),
              ),
            SizedBox(width: r.s(4)),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  TYPE TABS
  // ═════════════════════════════════════════════════════════
  Widget _buildTypeTabs(_R r) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(4)),
      padding: EdgeInsets.all(r.s(3)),
      decoration: BoxDecoration(
        color: _Palette.divider.withOpacity(0.3),
        borderRadius: BorderRadius.circular(r.s(14)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: _Palette.textMuted,
        indicator: BoxDecoration(
          color: _Palette.peach,
          borderRadius: BorderRadius.circular(r.s(11)),
          boxShadow: [
            BoxShadow(
              color: _Palette.peach.withOpacity(0.20),
              blurRadius: 8,
              spreadRadius: -2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w900, letterSpacing: 0.6),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: r.fs(11), fontWeight: FontWeight.w700, letterSpacing: 0.3),
        labelPadding: EdgeInsets.symmetric(horizontal: r.s(14)),
        tabAlignment: TabAlignment.start,
        tabs: _tabs,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  MUSCLE FILTER
  // ═════════════════════════════════════════════════════════
  Widget _buildMuscleFilter(_R r) {
    final muscles = MuscleGroup.values
        .where((m) => m != MuscleGroup.cardio_vascular && m != MuscleGroup.flexibility)
        .toList();

    return SizedBox(
      height: r.s(40),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(4)),
        itemCount: muscles.length,
        separatorBuilder: (_, __) => SizedBox(width: r.s(8)),
        itemBuilder: (context, index) {
          final muscle = muscles[index];
          final isSelected = _selectedMuscle == muscle;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedMuscle = isSelected ? null : muscle;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: r.s(13)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? muscle.color.withOpacity(0.14) : Colors.white,
                borderRadius: BorderRadius.circular(r.s(11)),
                border: Border.all(
                  color: isSelected ? muscle.color : _Palette.divider,
                  width: isSelected ? 1 : 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(Icons.check_rounded, color: muscle.color, size: r.s(13)),
                    SizedBox(width: r.s(4)),
                  ],
                  Text(
                    muscle.displayName,
                    style: GoogleFonts.inter(
                      fontSize: r.fs(11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                      color: isSelected ? muscle.color : _Palette.textMuted,
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

  // ═════════════════════════════════════════════════════════
  //  EXERCISE CARD
  // ═════════════════════════════════════════════════════════
  Widget _buildExerciseCard(Exercise exercise, FitnessProvider provider, _R r) {
    final lastProgress = provider.getLastProgress(exercise.id);
    final accent = exercise.muscleGroups.isNotEmpty ? exercise.muscleGroups.first.color : _Palette.peach;
    final hasImage = exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider<FitnessProvider>.value(
              value: provider,
              child: ExerciseDetailScreen(exercise: exercise, isDark: false),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.s(18)),
          border: Border.all(color: _Palette.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.06),
              blurRadius: 12,
              spreadRadius: -3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon / Image area
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withOpacity(0.10), accent.withOpacity(0.02)],
                  ),
                ),
                child: Stack(
                  children: [
                    if (hasImage)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(17))),
                          child: _buildExerciseImage(exercise.imageUrl!, accent, exercise.exerciseType, r),
                        ),
                      )
                    else
                      _buildIconPlaceholder(accent, exercise.exerciseType, r),

                    if (exercise.isCustom)
                      Positioned(
                        top: r.s(8),
                        right: r.s(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: r.s(7), vertical: r.s(3)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(r.s(7)),
                            border: Border.all(color: _Palette.lavenderDeep.withOpacity(0.30), width: 0.7),
                          ),
                          child: Text(
                            'МОЁ',
                            style: GoogleFonts.inter(
                              color: _Palette.lavenderDeep,
                              fontSize: r.fs(8),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      bottom: r.s(8),
                      left: r.s(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: r.s(7), vertical: r.s(4)),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(r.s(8)),
                          border: Border.all(color: _Palette.divider, width: 0.6),
                        ),
                        child: Text(exercise.exerciseType.emoji, style: TextStyle(fontSize: r.fs(11))),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.s(11), r.s(9), r.s(11), r.s(9)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: r.fs(13),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.2,
                        color: _Palette.text,
                      ),
                    ),
                    SizedBox(height: r.s(5)),
                    if (lastProgress != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: r.s(6), vertical: r.s(3)),
                        decoration: BoxDecoration(
                          color: _Palette.peachSoft,
                          borderRadius: BorderRadius.circular(r.s(5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up_rounded, size: r.s(10), color: _Palette.peach),
                            SizedBox(width: r.s(3)),
                            Flexible(
                              child: Text(
                                '${lastProgress.bestWeight.toStringAsFixed(0)}×${lastProgress.bestReps}',
                                style: GoogleFonts.inter(
                                  fontSize: r.fs(10.5),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.1,
                                  color: _Palette.peach,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'НЕТ ДАННЫХ',
                        style: GoogleFonts.inter(
                          fontSize: r.fs(9),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: _Palette.textMuted,
                        ),
                      ),
                    const Spacer(),
                    Wrap(
                      spacing: r.s(3),
                      runSpacing: r.s(3),
                      children: exercise.muscleGroups.take(2).map((m) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: r.s(5), vertical: r.s(2)),
                          decoration: BoxDecoration(
                            color: m.color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(r.s(4)),
                          ),
                          child: Text(
                            m.displayName,
                            style: GoogleFonts.inter(
                              fontSize: r.fs(7.5),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                              color: m.color,
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
    );
  }

  // ═════════════════════════════════════════════════════════
  //  IMAGE HELPERS
  // ═════════════════════════════════════════════════════════
  Widget _buildExerciseImage(String url, Color accent, ExerciseType type, _R r) {
    return _AppImg(
      path: url,
      fit: BoxFit.cover,
      fallback: _buildIconPlaceholder(accent, type, r),
    );
  }

  Widget _buildIconPlaceholder(Color accent, ExerciseType type, _R r) {
    return Center(
      child: Container(
        width: r.s(62),
        height: r.s(62),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.s(18)),
          border: Border.all(color: accent.withOpacity(0.20), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(_getExerciseIcon(type), size: r.s(30), color: accent),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ═════════════════════════════════════════════════════════
  Widget _buildEmptyState(_R r) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(40), r.s(40), r.s(40), r.s(40)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: r.s(84),
            height: r.s(84),
            decoration: const BoxDecoration(color: _Palette.peachSoft, shape: BoxShape.circle),
            child: Icon(Icons.fitness_center_rounded, size: r.s(36), color: _Palette.peach),
          ),
          SizedBox(height: r.s(20)),
          Text(
            'Ничего не найдено',
            style: GoogleFonts.inter(
              fontSize: r.fs(17),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: _Palette.text,
            ),
          ),
          SizedBox(height: r.s(8)),
          Text(
            'Попробуй изменить фильтры\nили создай своё упражнение',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: r.fs(12),
              height: 1.4,
              color: _Palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  FILTER LOGIC
  // ═════════════════════════════════════════════════════════
  List<Exercise> _getFilteredExercises(FitnessProvider provider) {
    List<Exercise> result = List.from(provider.exercises);
    if (_searchQuery.isNotEmpty) {
      result = provider.searchExercises(_searchQuery);
    }
    if (_selectedMuscle != null) {
      result = result.where((e) => e.muscleGroups.contains(_selectedMuscle)).toList();
    }
    if (_selectedType != null) {
      result = result.where((e) => e.exerciseType == _selectedType).toList();
    }
    return result;
  }

  // ═════════════════════════════════════════════════════════
  //  ADD EXERCISE DIALOG
  // ═════════════════════════════════════════════════════════
  void _showAddExerciseDialog(BuildContext context, FitnessProvider provider, _R r) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final tipsController = TextEditingController();
    var selectedType = ExerciseType.strength;
    var selectedMuscles = <MuscleGroup>[];
    String? imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: r.s(20),
            right: r.s(20),
            top: r.s(12),
            bottom: MediaQuery.of(ctx).viewInsets.bottom + r.s(24),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(28))),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: r.s(36),
                    height: r.s(5),
                    decoration: BoxDecoration(
                      color: _Palette.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(r.s(3)),
                    ),
                  ),
                ),
                SizedBox(height: r.s(20)),
                Row(
                  children: [
                    Container(
                      width: r.s(42),
                      height: r.s(42),
                      decoration: BoxDecoration(
                        color: _Palette.peachSoft,
                        borderRadius: BorderRadius.circular(r.s(12)),
                      ),
                      child: Icon(Icons.fitness_center_rounded, color: _Palette.peach, size: r.s(20)),
                    ),
                    SizedBox(width: r.s(11)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'НОВОЕ УПРАЖНЕНИЕ',
                            style: GoogleFonts.inter(
                              color: _Palette.peach,
                              fontSize: r.fs(9),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                          SizedBox(height: r.s(2)),
                          Text(
                            'Создать',
                            style: GoogleFonts.inter(
                              color: _Palette.text,
                              fontSize: r.fs(20),
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.s(18)),

                _buildField(nameController, 'НАЗВАНИЕ', r),
                SizedBox(height: r.s(12)),
                _buildField(descController, 'ОПИСАНИЕ', r, maxLines: 3),

                // Селектор изображений
                SizedBox(height: r.s(14)),
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final newUrl = await showExerciseImageSelector(
                      context: context,
                      currentImageUrl: imageUrl,
                      isCustom: true,
                      defaultImageUrl: null,
                    );
                    if (newUrl != null) {
                      setSheetState(() => imageUrl = newUrl.isEmpty ? null : newUrl);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(r.s(14)),
                    decoration: BoxDecoration(
                      color: _Palette.bg,
                      borderRadius: BorderRadius.circular(r.s(13)),
                      border: Border.all(color: _Palette.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: r.s(40),
                          height: r.s(40),
                          decoration: BoxDecoration(
                            color: _Palette.peachSoft,
                            borderRadius: BorderRadius.circular(r.s(10)),
                          ),
                          child: Icon(Icons.image_rounded, color: _Palette.peach, size: r.s(20)),
                        ),
                        SizedBox(width: r.s(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ИЗОБРАЖЕНИЕ',
                                style: GoogleFonts.inter(
                                  color: _Palette.textMuted,
                                  fontSize: r.fs(9),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: r.s(2)),
                              Text(
                                _imageStatusText(imageUrl),
                                style: GoogleFonts.inter(
                                  fontSize: r.fs(13),
                                  color: imageUrl != null && imageUrl!.isNotEmpty ? _Palette.text : _Palette.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: _Palette.textMuted, size: r.s(20)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: r.s(12)),

                // Type dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: r.s(2), bottom: r.s(5)),
                      child: Text(
                        'ТИП',
                        style: GoogleFonts.inter(
                          fontSize: r.fs(9),
                          letterSpacing: 1.2,
                          color: _Palette.textMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _Palette.bg,
                        borderRadius: BorderRadius.circular(r.s(13)),
                        border: Border.all(color: _Palette.divider, width: 1),
                      ),
                      child: DropdownButtonFormField<ExerciseType>(
                        value: selectedType,
                        dropdownColor: Colors.white,
                        style: GoogleFonts.inter(
                          fontSize: r.fs(14),
                          fontWeight: FontWeight.w600,
                          color: _Palette.text,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: r.s(14), vertical: r.s(13)),
                        ),
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: _Palette.textMuted),
                        items: ExerciseType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              '${type.emoji}  ${type.displayName}',
                              style: GoogleFonts.inter(
                                fontSize: r.fs(14),
                                fontWeight: FontWeight.w600,
                                color: _Palette.text,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          setSheetState(() => selectedType = value!);
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: r.s(14)),

                // Muscle groups
                Padding(
                  padding: EdgeInsets.only(left: r.s(2), bottom: r.s(6)),
                  child: Text(
                    'ГРУППЫ МЫШЦ',
                    style: GoogleFonts.inter(
                      fontSize: r.fs(9),
                      letterSpacing: 1.2,
                      color: _Palette.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Wrap(
                  spacing: r.s(8),
                  runSpacing: r.s(8),
                  children: MuscleGroup.values
                      .where((m) => m != MuscleGroup.fullBody && m != MuscleGroup.cardio_vascular && m != MuscleGroup.flexibility)
                      .map((muscle) {
                    final isSelected = selectedMuscles.contains(muscle);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setSheetState(() {
                          if (isSelected) {
                            selectedMuscles.remove(muscle);
                          } else {
                            selectedMuscles.add(muscle);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(horizontal: r.s(11), vertical: r.s(6)),
                        decoration: BoxDecoration(
                          color: isSelected ? muscle.color.withOpacity(0.14) : Colors.white,
                          borderRadius: BorderRadius.circular(r.s(10)),
                          border: Border.all(
                            color: isSelected ? muscle.color : _Palette.divider,
                            width: isSelected ? 1 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(Icons.check_rounded, color: muscle.color, size: r.s(12)),
                              SizedBox(width: r.s(4)),
                            ],
                            Text(
                              muscle.displayName,
                              style: GoogleFonts.inter(
                                fontSize: r.fs(11.5),
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                                color: isSelected ? muscle.color : _Palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: r.s(14)),
                _buildField(tipsController, 'СОВЕТЫ ПО ТЕХНИКЕ', r, maxLines: 2),
                SizedBox(height: r.s(20)),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: r.s(50),
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _Palette.text,
                            side: const BorderSide(color: _Palette.divider, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          ),
                          child: Text(
                            'Отмена',
                            style: GoogleFonts.inter(
                              fontSize: r.fs(14),
                              fontWeight: FontWeight.w700,
                              color: _Palette.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: r.s(10)),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: r.s(50),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) {
                              HapticFeedback.mediumImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Введите название'),
                                  backgroundColor: _Palette.pink,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                              return;
                            }

                            HapticFeedback.mediumImpact();

                            await provider.addExercise(
                              name: nameController.text.trim(),
                              description: descController.text.trim(),
                              muscleGroups: selectedMuscles,
                              exerciseType: selectedType,
                              imageUrl: imageUrl,
                              techniqueTips: tipsController.text.trim().isNotEmpty ? tipsController.text.trim() : null,
                            );

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('«${nameController.text.trim()}» создано'),
                                backgroundColor: _Palette.sage,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Palette.peach,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.s(13))),
                          ),
                          child: Text(
                            'СОЗДАТЬ',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: r.fs(13),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _imageStatusText(String? currentUrl) {
    if (currentUrl == null || currentUrl.isEmpty) return 'Нажмите, чтобы выбрать изображение';
    if (currentUrl.startsWith('assets/')) {
      final parts = currentUrl.split('/');
      return 'Из библиотеки: ${parts.last}';
    }
    if (currentUrl.startsWith('http')) {
      final short = currentUrl.length > 30 ? '${currentUrl.substring(0, 30)}…' : currentUrl;
      return 'Ссылка: $short';
    }
    return 'Из галереи';
  }

  Widget _buildField(TextEditingController controller, String label, _R r, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: r.s(2), bottom: r.s(5)),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: r.fs(9),
              letterSpacing: 1.2,
              color: _Palette.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: r.fs(14),
            fontWeight: FontWeight.w600,
            color: _Palette.text,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _Palette.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.s(13)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.s(13)),
              borderSide: const BorderSide(color: _Palette.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.s(13)),
              borderSide: const BorderSide(color: _Palette.peach, width: 1.4),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: r.s(13), vertical: r.s(13)),
          ),
        ),
      ],
    );
  }

  IconData _getExerciseIcon(ExerciseType type) {
    switch (type) {
      case ExerciseType.strength: return Icons.fitness_center_rounded;
      case ExerciseType.cardio: return Icons.directions_run_rounded;
      case ExerciseType.bodyweight: return Icons.accessibility_new_rounded;
      case ExerciseType.boxing: return Icons.sports_mma_rounded;
      case ExerciseType.yoga: return Icons.self_improvement_rounded;
      case ExerciseType.other: return Icons.more_horiz_rounded;
    }
  }
}