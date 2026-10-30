// features/fitness/ui/screens/exercise_library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/enums.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/fitness_provider.dart';
import 'exercise_detail_screen.dart';

// ==================== POWER MODE TOKENS ====================

class _Power {
  static const Color heroBase = Color(0xFF050505);
  static const Color heroDeep = Color(0xFF120700);

  static const Color volt = Color(0xFFFF5500);
  static const Color voltBright = Color(0xFFFF7A1A);
  static const Color magma = Color(0xFFFF2D55);
  static const Color plasma = Color(0xFFFFCC00);
  static const Color ice = Color(0xFF00E5FF);
  static const Color lime = Color(0xFFB4FF39);
  static const Color green = Color(0xFF00C853);
  static const Color red = Color(0xFFFF3B30);

  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkCard2 = Color(0xFF2C2C2E);
  static const Color lightBg = Color(0xFFF2F2F7);
  static const Color lightCard = Color(0xFFFFFFFF);

  static Color bg(bool isDark) => isDark ? darkBg : lightBg;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color card2(bool isDark) => isDark ? darkCard2 : const Color(0xFFF9FAFB);
  static Color textPrimary(bool isDark) => isDark ? Colors.white : Colors.black;
  static Color textSecondary(bool isDark) => isDark
      ? Colors.white.withOpacity(0.6)
      : const Color(0xFF3C3C43).withOpacity(0.6);
  static Color textTertiary(bool isDark) => isDark
      ? Colors.white.withOpacity(0.3)
      : const Color(0xFF3C3C43).withOpacity(0.3);
  static Color separator(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

  static List<BoxShadow> softGlow(Color color, {double strength = 0.18}) => [
    BoxShadow(color: color.withOpacity(strength), blurRadius: 16),
  ];

  static List<BoxShadow> glow(Color color,
      {double strength = 0.4, double blur = 24}) =>
      [
        BoxShadow(
          color: color.withOpacity(strength),
          blurRadius: blur,
          offset: const Offset(0, 6),
        ),
      ];
}

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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = context.watch<FitnessProvider>();
    final exercises = _getFilteredExercises(provider);

    return Scaffold(
      backgroundColor: _Power.bg(isDark),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: _Power.bg(isDark).withOpacity(0.85),
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
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: _Power.textPrimary(isDark),
                    size: 22,
                  ),
                ),
              ),
            ),
            title: Text(
              'Упражнения',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: _Power.textPrimary(isDark),
              ),
            ),
            centerTitle: true,
          ),

          // Large title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'БАЗА ЗНАНИЙ',
                    style: TextStyle(
                      color: _Power.volt,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Упражнения',
                    style: TextStyle(
                      color: _Power.textPrimary(isDark),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.exercises.length} упражнений в библиотеке',
                    style: TextStyle(
                      color: _Power.textSecondary(isDark),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search
          SliverToBoxAdapter(
            child: _buildSearchBar(isDark),
          ),

          // Type tabs
          SliverToBoxAdapter(
            child: _buildTypeTabs(isDark),
          ),

          // Muscle filter
          SliverToBoxAdapter(
            child: _buildMuscleFilter(isDark),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Grid
          if (exercises.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(isDark, provider),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverGrid(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final exercise = exercises[index];
                    return _buildExerciseCard(exercise, isDark, provider);
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
            shape: BoxShape.circle,
            boxShadow: _Power.glow(_Power.volt, strength: 0.4, blur: 20),
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showAddExerciseDialog(context, isDark, provider);
            },
            backgroundColor: _Power.volt,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'СОЗДАТЬ',
              style: TextStyle(
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

  // =====================================================================
  // SEARCH
  // =====================================================================

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: _Power.card(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _Power.separator(isDark),
            width: 0.5,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _Power.textPrimary(isDark),
          ),
          decoration: InputDecoration(
            hintText: 'Поиск…',
            hintStyle: TextStyle(
              color: _Power.textTertiary(isDark),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _Power.textTertiary(isDark),
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Container(
                margin: const EdgeInsets.all(10),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _Power.textTertiary(isDark).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: _Power.textSecondary(isDark),
                  size: 14,
                ),
              ),
            )
                : null,
            filled: false,
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // TYPE TABS
  // =====================================================================

  Widget _buildTypeTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _Power.card2(isDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: _Power.textSecondary(isDark),
        indicator: BoxDecoration(
          color: _Power.volt,
          borderRadius: BorderRadius.circular(11),
          boxShadow: _Power.softGlow(_Power.volt, strength: 0.35),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        tabAlignment: TabAlignment.start,
        tabs: _tabs,
      ),
    );
  }

  // =====================================================================
  // MUSCLE FILTER
  // =====================================================================

  Widget _buildMuscleFilter(bool isDark) {
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? muscle.color
                    : _Power.card(isDark),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? muscle.color
                      : muscle.color.withOpacity(0.28),
                  width: 0.8,
                ),
                boxShadow: isSelected
                    ? _Power.softGlow(muscle.color, strength: 0.35)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    muscle.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      color: isSelected
                          ? Colors.white
                          : _Power.textPrimary(isDark),
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

  // =====================================================================
  // EXERCISE CARD
  // =====================================================================

  Widget _buildExerciseCard(
      Exercise exercise,
      bool isDark,
      FitnessProvider provider,
      ) {
    final lastProgress = provider.getLastProgress(exercise.id);
    final accent = exercise.muscleGroups.isNotEmpty
        ? exercise.muscleGroups.first.color
        : _Power.volt;

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
                isDark: isDark,
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _Power.card(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _Power.separator(isDark),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon area
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withOpacity(0.18),
                      accent.withOpacity(0.04),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Icon
                    Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow:
                          _Power.softGlow(accent, strength: 0.25),
                        ),
                        child: Icon(
                          _getExerciseIcon(exercise.exerciseType),
                          size: 34,
                          color: accent,
                        ),
                      ),
                    ),

                    // Custom badge
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
                            color: _Power.volt,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: _Power.softGlow(_Power.volt,
                                strength: 0.4),
                          ),
                          child: const Text(
                            'МОЁ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),

                    // Type badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          exercise.exerciseType.emoji,
                          style: const TextStyle(fontSize: 12),
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.15,
                        color: _Power.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 5),

                    if (lastProgress != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 11,
                            color: _Power.volt,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${lastProgress.bestWeight.toStringAsFixed(0)}×${lastProgress.bestReps}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                color: _Power.volt,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'НЕТ ДАННЫХ',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: _Power.textTertiary(isDark),
                        ),
                      ),

                    const Spacer(),

                    // Muscle tags
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: exercise.muscleGroups.take(2).map((m) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: m.color.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            m.displayName,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
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

  // =====================================================================
  // EMPTY STATE
  // =====================================================================

  Widget _buildEmptyState(bool isDark, FitnessProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: _Power.volt.withOpacity(0.10),
              shape: BoxShape.circle,
              boxShadow: _Power.softGlow(_Power.volt, strength: 0.15),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              size: 38,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'НИЧЕГО НЕ НАЙДЕНО',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: _Power.volt,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Пусто',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
              color: _Power.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Попробуйте изменить фильтры или создайте своё упражнение',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: _Power.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // FILTER LOGIC
  // =====================================================================

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

  // =====================================================================
  // ADD EXERCISE DIALOG — iOS Sheet
  // =====================================================================

  void _showAddExerciseDialog(
      BuildContext context,
      bool isDark,
      FitnessProvider provider,
      ) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final tipsController = TextEditingController();
    final mistakesController = TextEditingController();
    var selectedType = ExerciseType.strength;
    var selectedMuscles = <MuscleGroup>[];

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
          decoration: BoxDecoration(
            color: _Power.card(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: _Power.textTertiary(isDark),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'НОВОЕ УПРАЖНЕНИЕ',
                  style: TextStyle(
                    color: _Power.volt,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Создать',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: _Power.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 20),

                _buildField(
                  controller: nameController,
                  label: 'НАЗВАНИЕ',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: descController,
                  label: 'ОПИСАНИЕ',
                  isDark: isDark,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Type dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'ТИП',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                          color: _Power.textTertiary(isDark),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _Power.card2(isDark),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<ExerciseType>(
                        value: selectedType,
                        dropdownColor: _Power.card(isDark),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _Power.textPrimary(isDark),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _Power.textSecondary(isDark),
                        ),
                        items: ExerciseType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              '${type.emoji}  ${type.displayName}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _Power.textPrimary(isDark),
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

                const SizedBox(height: 16),

                // Muscle groups
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'ГРУППЫ МЫШЦ',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      color: _Power.textTertiary(isDark),
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
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? muscle.color
                              : muscle.color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: isSelected
                                ? muscle.color
                                : muscle.color.withOpacity(0.28),
                            width: 0.8,
                          ),
                          boxShadow: isSelected
                              ? _Power.softGlow(muscle.color,
                              strength: 0.35)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              muscle.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                                color: isSelected
                                    ? Colors.white
                                    : muscle.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                _buildField(
                  controller: tipsController,
                  label: 'СОВЕТЫ ПО ТЕХНИКЕ',
                  isDark: isDark,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: mistakesController,
                  label: 'ЧАСТЫЕ ОШИБКИ',
                  isDark: isDark,
                  maxLines: 2,
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                            _Power.textSecondary(isDark),
                            side: BorderSide(
                              color: _Power.separator(isDark),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Отмена',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) {
                              HapticFeedback.mediumImpact();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Введите название'),
                                  backgroundColor: _Power.red,
                                  behavior:
                                  SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(14),
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
                                backgroundColor: _Power.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Power.volt,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            shadowColor:
                            _Power.volt.withOpacity(0.5),
                          ),
                          child: const Text(
                            'СОЗДАТЬ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
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
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: _Power.textTertiary(isDark),
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _Power.textPrimary(isDark),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _Power.card2(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

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