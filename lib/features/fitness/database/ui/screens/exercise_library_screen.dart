// features/fitness/ui/screens/exercise_library_screen.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zal_life/features/fitness/data/exercise_image_presets.dart';

import '../../../models/enums.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/fitness_provider.dart';
import '../widgets/image_picker_field.dart';
import 'exercise_detail_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  Soft Pastel Light — Design System
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const peach     = Color(0xFFFFB5A7);
  static const pink      = Color(0xFFFFAFC8);
  static const mint      = Color(0xFFA8DADC);
  static const lavender  = Color(0xFFCDB4DB);
  static const yellow    = Color(0xFFFFD6A5);
  static const sky       = Color(0xFFA8D8EA);
  static const sage      = Color(0xFFB5CBB7);

  static const peachSoft    = Color(0xFFFFE9E1);
  static const pinkSoft     = Color(0xFFFFE5EF);
  static const mintSoft     = Color(0xFFE3F3F4);
  static const lavenderSoft = Color(0xFFF1E8F5);
  static const yellowSoft   = Color(0xFFFFF2E2);
  static const skySoft      = Color(0xFFE3F1F7);
  static const sageSoft     = Color(0xFFE8F1E6);

  static const peachDeep    = Color(0xFFE57154);
  static const pinkDeep     = Color(0xFFD95C84);
  static const mintDeep     = Color(0xFF398B95);
  static const lavenderDeep = Color(0xFF8A5DA5);
  static const yellowDeep   = Color(0xFFD39838);
  static const skyDeep      = Color(0xFF3E7A9C);
  static const sageDeep     = Color(0xFF5C7E5E);

  static const bg       = Color(0xFFFAF7F2);
  static const surface  = Color(0xFFFFFFFF);
  static const elevated = Color(0xFFF3EEE6);

  static const text      = Color(0xFF2B2823);
  static const textMuted = Color(0xFF8A8278);
  static const textSoft  = Color(0xFFBFB7AB);

  static const divider = Color(0xFFEAE4DA);
}

class _T {
  static const title1 = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w800,
    letterSpacing: -0.6, height: 1.15,
  );
  static const title2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w800,
    letterSpacing: -0.5, height: 1.2,
  );
  static const title3 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    letterSpacing: -0.4, height: 1.2,
  );
  static const headline = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700,
    letterSpacing: -0.2, height: 1.3,
  );
  static const caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600,
    letterSpacing: 0.05, height: 1.3,
  );
  static const caption2 = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700,
    letterSpacing: 0.1, height: 1.3,
  );
  static const overline = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w800,
    letterSpacing: 1.4, height: 1.1,
  );
}

// ═══════════════════════════════════════════════════════════════════

class ExerciseLibraryScreen extends StatefulWidget {
  final bool isDark;
  final bool isCompact;

  const ExerciseLibraryScreen({
    super.key,
    this.isDark = false,
    this.isCompact = false,
  });

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen>
    with SingleTickerProviderStateMixin {
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

  List<Tab> get _tabs =>
      _tabsData.map((t) => Tab(text: t['label'] as String)).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType =
          _tabsData[_tabController.index]['type'] as ExerciseType?;
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

  // ═════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final exercises = _getFilteredExercises(provider);

    return Scaffold(
      backgroundColor: _P.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: _P.bg.withOpacity(0.94),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 60,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _P.divider, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _P.peachDeep.withOpacity(0.06),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: _P.text,
                    size: 22,
                  ),
                ),
              ),
            ),
            title: Text(
              'Упражнения',
              style: _T.headline.copyWith(
                fontSize: 15,
                color: _P.text,
                letterSpacing: -0.2,
              ),
            ),
            centerTitle: true,
          ),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'БАЗА ЗНАНИЙ',
                    style: _T.overline.copyWith(
                      color: _P.peachDeep,
                      fontSize: 9,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Упражнения',
                    style: _T.title1.copyWith(
                      color: _P.text,
                      fontSize: 28,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.exercises.length} упражнений в библиотеке',
                    style: _T.caption.copyWith(
                      color: _P.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search
          SliverToBoxAdapter(child: _buildSearchBar()),

          // Type tabs
          SliverToBoxAdapter(child: _buildTypeTabs()),

          // Muscle filter
          SliverToBoxAdapter(child: _buildMuscleFilter()),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Grid
          if (exercises.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(provider),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final exercise = exercises[index];
                    return _buildExerciseCard(exercise, provider);
                  },
                  childCount: exercises.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _P.peachDeep.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showAddExerciseDialog(context, provider);
            },
            backgroundColor: _P.peachDeep,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'СОЗДАТЬ',
              style: _T.caption2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontSize: 12,
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
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _P.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: _P.peachDeep.withOpacity(0.05),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _P.peachSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: _P.peachDeep,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: _T.headline.copyWith(
                  color: _P.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Найти упражнение…',
                  hintStyle: _T.headline.copyWith(
                    color: _P.textMuted,
                    fontSize: 14,
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
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.close_rounded,
                    color: _P.textMuted,
                    size: 16,
                  ),
                ),
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  TYPE TABS
  // ═════════════════════════════════════════════════════════
  Widget _buildTypeTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _P.elevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: _P.textMuted,
        indicator: BoxDecoration(
          color: _P.peachDeep,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: _P.peachDeep.withOpacity(0.20),
              blurRadius: 8,
              spreadRadius: -2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        tabAlignment: TabAlignment.start,
        tabs: _tabs,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  MUSCLE FILTER
  // ═════════════════════════════════════════════════════════
  Widget _buildMuscleFilter() {
    final muscles = MuscleGroup.values
        .where((m) =>
    m != MuscleGroup.cardio_vascular &&
        m != MuscleGroup.flexibility)
        .toList();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: muscles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? muscle.color.withOpacity(0.14)
                    : Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isSelected ? muscle.color : _P.divider,
                  width: isSelected ? 1 : 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(
                      Icons.check_rounded,
                      color: muscle.color,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    muscle.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                      color: isSelected ? muscle.color : _P.textMuted,
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
  Widget _buildExerciseCard(Exercise exercise, FitnessProvider provider) {
    final lastProgress = provider.getLastProgress(exercise.id);
    final accent = exercise.muscleGroups.isNotEmpty
        ? exercise.muscleGroups.first.color
        : _P.peachDeep;

    final hasImage =
        exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
            ChangeNotifierProvider<FitnessProvider>.value(
              value: provider,
              child: ExerciseDetailScreen(
                exercise: exercise,
                isDark: false,
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.divider, width: 1),
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
                    colors: [
                      accent.withOpacity(0.10),
                      accent.withOpacity(0.02),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // 🆕 Превью изображения или иконка
                    if (hasImage)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(17),
                          ),
                          child: _buildExerciseImage(
                            exercise.imageUrl!,
                            accent,
                            exercise.exerciseType,
                          ),
                        ),
                      )
                    else
                      _buildIconPlaceholder(accent, exercise.exerciseType),

                    // Бейдж "МОЁ"
                    if (exercise.isCustom)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: _P.lavenderDeep.withOpacity(0.30),
                              width: 0.7,
                            ),
                          ),
                          child: Text(
                            'МОЁ',
                            style: _T.caption2.copyWith(
                              color: _P.lavenderDeep,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),

                    // Бейдж эмодзи
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _P.divider,
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          exercise.exerciseType.emoji,
                          style: const TextStyle(fontSize: 11),
                        ),
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
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _T.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.2,
                        color: _P.text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (lastProgress != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _P.peachSoft,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              size: 10,
                              color: _P.peachDeep,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '${lastProgress.bestWeight.toStringAsFixed(0)}×${lastProgress.bestReps}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.1,
                                  color: _P.peachDeep,
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
                        style: _T.caption2.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: _P.textSoft,
                        ),
                      ),
                    const Spacer(),
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: exercise.muscleGroups.take(2).map((m) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: m.color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            m.displayName,
                            style: TextStyle(
                              fontSize: 7.5,
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
  Widget _buildExerciseImage(
      String url,
      Color accent,
      ExerciseType type,
      ) {
    // 🆕 Локальные assets
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildIconPlaceholder(accent, type),
      );
    }
    // Сеть
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildIconPlaceholder(accent, type),
        errorWidget: (_, __, ___) => _buildIconPlaceholder(accent, type),
      );
    }
    // Локальный файл (галерея)
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildIconPlaceholder(accent, type),
    );
  }

  Widget _buildIconPlaceholder(Color accent, ExerciseType type) {
    return Center(
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withOpacity(0.20),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _getExerciseIcon(type),
          size: 30,
          color: accent,
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ═════════════════════════════════════════════════════════
  Widget _buildEmptyState(FitnessProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: _P.peachSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              size: 36,
              color: _P.peachDeep,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ничего не найдено',
            style: _T.title3.copyWith(
              fontSize: 17,
              letterSpacing: -0.4,
              color: _P.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуй изменить фильтры\nили создай своё упражнение',
            textAlign: TextAlign.center,
            style: _T.caption.copyWith(
              fontSize: 12,
              height: 1.4,
              color: _P.textMuted,
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
      result = result
          .where((e) => e.muscleGroups.contains(_selectedMuscle))
          .toList();
    }

    if (_selectedType != null) {
      result =
          result.where((e) => e.exerciseType == _selectedType).toList();
    }

    return result;
  }

  // ═════════════════════════════════════════════════════════
  //  ADD EXERCISE DIALOG
  // ═════════════════════════════════════════════════════════
  void _showAddExerciseDialog(
      BuildContext context,
      FitnessProvider provider,
      ) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final tipsController = TextEditingController();
    var selectedType = ExerciseType.strength;
    var selectedMuscles = <MuscleGroup>[];
    // 🆕 изображение
    String? imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
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
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _P.textSoft,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _P.peachSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: _P.peachDeep,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'НОВОЕ УПРАЖНЕНИЕ',
                            style: _T.overline.copyWith(
                              color: _P.peachDeep,
                              fontSize: 9,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Создать',
                            style: _T.title2.copyWith(
                              color: _P.text,
                              fontSize: 20,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                _buildField(
                  controller: nameController,
                  label: 'НАЗВАНИЕ',
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: descController,
                  label: 'ОПИСАНИЕ',
                  maxLines: 3,
                ),

                // 🆕 Изображение
                const SizedBox(height: 14),
                ImagePickerField(
                  label: 'ИЗОБРАЖЕНИЕ',
                  value: imageUrl,
                  hint: selectedType == ExerciseType.cardio
                      ? ExerciseTypeHint.cardio
                      : selectedType == ExerciseType.boxing
                      ? ExerciseTypeHint.boxing
                      : selectedType == ExerciseType.yoga
                      ? ExerciseTypeHint.yoga
                      : ExerciseTypeHint.strength,
                  onChanged: (v) => setSheetState(() => imageUrl = v),
                ),

                const SizedBox(height: 12),

                // Type dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 5),
                      child: Text(
                        'ТИП',
                        style: _T.overline.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.2,
                          color: _P.textMuted,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _P.bg,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: _P.divider, width: 1),
                      ),
                      child: DropdownButtonFormField<ExerciseType>(
                        value: selectedType,
                        dropdownColor: Colors.white,
                        style: _T.headline.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _P.text,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _P.textMuted,
                        ),
                        items: ExerciseType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              '${type.emoji}  ${type.displayName}',
                              style: _T.headline.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _P.text,
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

                const SizedBox(height: 14),

                // Muscle groups
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 6),
                  child: Text(
                    'ГРУППЫ МЫШЦ',
                    style: _T.overline.copyWith(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      color: _P.textMuted,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MuscleGroup.values
                      .where((m) =>
                  m != MuscleGroup.fullBody &&
                      m != MuscleGroup.cardio_vascular &&
                      m != MuscleGroup.flexibility)
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? muscle.color.withOpacity(0.14)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? muscle.color
                                : _P.divider,
                            width: isSelected ? 1 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(
                                Icons.check_rounded,
                                color: muscle.color,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              muscle.displayName,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                                color: isSelected
                                    ? muscle.color
                                    : _P.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                _buildField(
                  controller: tipsController,
                  label: 'СОВЕТЫ ПО ТЕХНИКЕ',
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _P.text,
                            side: const BorderSide(
                              color: _P.divider,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: Text(
                            'Отмена',
                            style: _T.headline.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _P.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) {
                              HapticFeedback.mediumImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Введите название'),
                                  backgroundColor: _P.pinkDeep,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                              imageUrl: imageUrl, // 🆕
                              techniqueTips:
                              tipsController.text.trim().isNotEmpty
                                  ? tipsController.text.trim()
                                  : null,
                            );

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '«${nameController.text.trim()}» создано'),
                                backgroundColor: _P.sageDeep,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _P.peachDeep,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: Text(
                            'СОЗДАТЬ',
                            style: _T.caption2.copyWith(
                              color: Colors.white,
                              fontSize: 13,
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            label,
            style: _T.overline.copyWith(
              fontSize: 9,
              letterSpacing: 1.2,
              color: _P.textMuted,
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: _T.headline.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _P.text,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _P.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: _P.divider,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: _P.peachDeep,
                width: 1.4,
              ),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  //  HELPERS
  // ═════════════════════════════════════════════════════════
  IconData _getExerciseIcon(ExerciseType type) {
    switch (type) {
      case ExerciseType.strength:
        return Icons.fitness_center_rounded;
      case ExerciseType.cardio:
        return Icons.directions_run_rounded;
      case ExerciseType.bodyweight:
        return Icons.accessibility_new_rounded;
      case ExerciseType.boxing:
        return Icons.sports_mma_rounded;
      case ExerciseType.yoga:
        return Icons.self_improvement_rounded;
      case ExerciseType.other:
        return Icons.more_horiz_rounded;
    }
  }
}