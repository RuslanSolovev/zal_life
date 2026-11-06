// features/fitness/ui/screens/photo_comparison_screen.dart
// 🎨 design refinement: tokens, pressable, layered elevation, unified sheets
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/fitness_models.dart';
import '../../../providers/fitness_provider.dart';

// ==================== DESIGN TOKENS ====================

class _P {
  static const orange       = Color(0xFFFF6B35);
  static const orangeBright = Color(0xFFFF8B5C);
  static const orangeDeep   = Color(0xFFFF3D00);
  static const orangeSoft   = Color(0xFFFFF0EB);

  static const green     = Color(0xFF4CAF50);
  static const greenSoft = Color(0xFFE8F5E9);
  static const blue      = Color(0xFF4A9BFF);
  static const blueSoft  = Color(0xFFE8F1FF);
  static const red       = Color(0xFFF44336);
  static const redSoft   = Color(0xFFFFEBEA);
  static const grey      = Color(0xFF6C7A8A);
  static const greySoft  = Color(0xFFEEF1F4);

  static const darkBg    = Color(0xFF0A0D14);
  static const darkCard  = Color(0xFF1A1D24);
  static const darkCard2 = Color(0xFF252830);
  static const lightBg   = Color(0xFFF2F5F9);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCard2 = Color(0xFFF8F9FA);

  static Color bg(bool d) => d ? darkBg : lightBg;
  static Color card(bool d) => d ? darkCard : lightCard;
  static Color card2(bool d) => d ? darkCard2 : lightCard2;
  static Color textPrimary(bool d) =>
      d ? Colors.white : const Color(0xFF1A1D24);
  static Color textSecondary(bool d) => d
      ? Colors.white.withOpacity(0.62)
      : const Color(0xFF3C3C43).withOpacity(0.62);
  static Color textTertiary(bool d) => d
      ? Colors.white.withOpacity(0.32)
      : const Color(0xFF3C3C43).withOpacity(0.32);
  static Color separator(bool d) =>
      d ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

  static List<BoxShadow> softGlow(Color c, {double strength = 0.18}) =>
      [BoxShadow(color: c.withOpacity(strength), blurRadius: 16)];

  static List<BoxShadow> cardShadow(bool isDark, Color tint) => isDark
      ? [
    BoxShadow(
      color: Colors.black.withOpacity(0.45),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ]
      : [
    BoxShadow(
      color: tint.withOpacity(0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: tint.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

class _R {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 22.0;
  static const xxl = 28.0;
}

class _Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

class _Num {
  static const _feat = <FontFeature>[FontFeature.tabularFigures()];
  static TextStyle t(TextStyle base) => base.copyWith(fontFeatures: _feat);
}

// ==================== PRESSABLE ====================

class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
  });
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;
  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        if (widget.haptic) HapticFeedback.lightImpact();
        widget.onTap();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ==================== SCREEN ====================

class PhotoComparisonScreen extends StatefulWidget {
  final bool isDark;
  const PhotoComparisonScreen({super.key, this.isDark = false});

  @override
  State<PhotoComparisonScreen> createState() => _PhotoComparisonScreenState();
}

class _PhotoComparisonScreenState extends State<PhotoComparisonScreen>
    with TickerProviderStateMixin {
  int? _selectedPhotoIndex1;
  int? _selectedPhotoIndex2;
  bool _isCompareMode = false;
  bool _isSliderMode = false;
  double _sliderPosition = 0.5;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  String _selectedFilter = 'all';

  final List<FilterOption> _filterOptions = const [
    FilterOption(
      id: 'all',
      label: 'Все фото',
      icon: Icons.grid_view_rounded,
      color: _P.grey,
    ),
    FilterOption(
      id: 'progress',
      label: 'Прогресс',
      icon: Icons.trending_up_rounded,
      color: _P.green,
    ),
    FilterOption(
      id: 'workout',
      label: 'Тренировки',
      icon: Icons.fitness_center_rounded,
      color: _P.orange,
    ),
    FilterOption(
      id: 'measurements',
      label: 'Замеры',
      icon: Icons.straighten_rounded,
      color: _P.blue,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = context.watch<FitnessProvider>();
    final photos = provider.photos;

    return Scaffold(
      backgroundColor: _P.bg(isDark),
      appBar: _buildAppBar(isDark, provider),
      body: _isCompareMode
          ? _buildCompareView(isDark, photos)
          : _buildGalleryView(isDark, photos, provider),
      floatingActionButton: _buildFloatingButton(isDark, provider),
    );
  }

  // =====================================================================
  // APP BAR
  // =====================================================================

  PreferredSizeWidget _buildAppBar(bool isDark, FitnessProvider provider) {
    final photos = provider.photos;

    return AppBar(
      backgroundColor: _P.bg(isDark).withOpacity(0.92),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isCompareMode)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_P.orange, _P.orangeDeep],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: _P.softGlow(_P.orange, strength: 0.45),
              ),
              child: const Icon(Icons.photo_camera_rounded,
                  color: Colors.white, size: 18),
            ),
          const SizedBox(width: 10),
          Text(
            _isCompareMode ? 'Сравнение' : 'Фотоотчёты',
            style: TextStyle(
              color: _P.textPrimary(isDark),
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: -0.4,
            ),
          ),
          if (!_isCompareMode && photos.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: _Sp.sm),
              padding:
              const EdgeInsets.symmetric(horizontal: _Sp.sm, vertical: 2),
              decoration: BoxDecoration(
                color: _P.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(_R.sm),
              ),
              child: Text(
                '${photos.length}',
                style: _Num.t(const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _P.orange,
                )),
              ),
            ),
        ],
      ),
      actions: [
        if (_isCompareMode) ...[
          _Pressable(
            onTap: () => setState(() => _isSliderMode = !_isSliderMode),
            scale: 0.9,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  RotationTransition(turns: anim, child: child),
              child: Icon(
                _isSliderMode
                    ? Icons.compare_arrows_rounded
                    : Icons.swipe_rounded,
                key: ValueKey(_isSliderMode),
                color: _P.orange,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _Pressable(
            onTap: () {
              setState(() {
                _isCompareMode = false;
                _selectedPhotoIndex1 = null;
                _selectedPhotoIndex2 = null;
              });
            },
            scale: 0.9,
            child: Icon(Icons.close_rounded,
                color: _P.textTertiary(isDark)),
          ),
          const SizedBox(width: _Sp.sm),
        ] else if (photos.length >= 2) ...[
          _Pressable(
            onTap: () => setState(() => _isCompareMode = true),
            scale: 0.94,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _P.orangeSoft,
                borderRadius: BorderRadius.circular(_R.sm),
                border: Border.all(
                    color: _P.orange.withOpacity(0.22), width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.compare_rounded, size: 14, color: _P.orange),
                  SizedBox(width: 5),
                  Text(
                    'Сравнить',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _P.orange,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: _Sp.sm),
        ],
        const SizedBox(width: _Sp.sm),
      ],
    );
  }

  Widget _buildFloatingButton(bool isDark, FitnessProvider provider) {
    return AnimatedScale(
      scale: _scaleAnimation.value,
      duration: const Duration(milliseconds: 400),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow:
          _P.softGlow(_P.orange, strength: 0.45),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showAddPhotoDialog(context, isDark, provider);
          },
          backgroundColor: _P.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_R.md),
          ),
          icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
          label: const Text(
            'Добавить фото',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // GALLERY
  // =====================================================================

  Widget _buildGalleryView(
      bool isDark,
      List<FitnessPhoto> photos,
      FitnessProvider provider,
      ) {
    final filteredPhotos = _applyFilter(photos);

    if (photos.isEmpty) return _buildEmptyState(isDark, provider);

    return Column(
      children: [
        if (!_isCompareMode) _buildBeautifulFilterBar(isDark, photos),
        if (_isCompareMode) _buildCompareInfoBanner(isDark),
        Expanded(
          child: filteredPhotos.isEmpty
              ? _buildEmptyFilterState(isDark)
              : GridView.builder(
            padding: const EdgeInsets.all(_R.md),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: filteredPhotos.length,
            itemBuilder: (context, index) {
              final photo = filteredPhotos[index];
              final realIndex = photos.indexOf(photo);
              final isSelected = _selectedPhotoIndex1 == realIndex ||
                  _selectedPhotoIndex2 == realIndex;
              final selectionNumber =
              _selectedPhotoIndex1 == realIndex
                  ? 1
                  : _selectedPhotoIndex2 == realIndex
                  ? 2
                  : null;

              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _Pressable(
                    onTap: () => _handlePhotoTap(realIndex, provider),
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showPhotoOptions(
                          context, isDark, photo, provider);
                    },
                    child: _buildPhotoCard(
                        isDark, photo, isSelected, selectionNumber),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // FILTER BAR
  // =====================================================================

  Widget _buildBeautifulFilterBar(
      bool isDark, List<FitnessPhoto> photos) {
    return Container(
      padding: const EdgeInsets.fromLTRB(_Sp.lg, _Sp.sm, _Sp.lg, _Sp.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _filterOptions.map((filter) {
            final count = _getFilteredCount(photos, filter.id);
            final isActive = _selectedFilter == filter.id;
            return Padding(
              padding: const EdgeInsets.only(right: _Sp.sm),
              child: _buildFilterChip(isDark, filter, count, isActive),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      bool isDark, FilterOption filter, int count, bool isActive) {
    return _Pressable(
      onTap: () => setState(() => _selectedFilter = filter.id),
      scale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: _R.md, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? filter.color
              : _P.card2(isDark),
          borderRadius: BorderRadius.circular(_R.xl),
          border: Border.all(
            color: isActive
                ? filter.color
                : _P.separator(isDark),
            width: 1,
          ),
          boxShadow: isActive
              ? _P.softGlow(filter.color, strength: 0.32)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter.icon,
              color: isActive ? Colors.white : filter.color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              filter.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : _P.textSecondary(isDark),
                letterSpacing: -0.1,
              ),
            ),
            if (filter.id != 'all') ...[
              const SizedBox(width: _Sp.xs),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.22)
                      : filter.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(_R.xs),
                ),
                child: Text(
                  '$count',
                  style: _Num.t(TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isActive ? Colors.white : filter.color,
                  )),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getFilteredCount(List<FitnessPhoto> photos, String filterId) =>
      _applyFilterWithId(photos, filterId).length;

  List<FitnessPhoto> _applyFilter(List<FitnessPhoto> photos) =>
      _applyFilterWithId(photos, _selectedFilter);

  List<FitnessPhoto> _applyFilterWithId(
      List<FitnessPhoto> photos, String filterId) {
    switch (filterId) {
      case 'progress':
        return photos
            .where((p) =>
        (p.label != null &&
            p.label!.toLowerCase().contains('прогресс')) ||
            p.measurementsCount > 0)
            .toList();
      case 'workout':
        return photos
            .where((p) =>
        p.label != null &&
            (p.label!.toLowerCase().contains('тренировка') ||
                p.label!.toLowerCase().contains('workout')))
            .toList();
      case 'measurements':
        return photos.where((p) => p.measurementsCount > 0).toList();
      default:
        return photos;
    }
  }

  Widget _buildEmptyFilterState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _P.grey.withOpacity(0.14),
                  _P.grey.withOpacity(0.02),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.filter_alt_rounded,
              size: 40,
              color: _P.textTertiary(isDark),
            ),
          ),
          const SizedBox(height: _Sp.lg),
          Text(
            'Нет фото в этой категории',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _P.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: _Sp.xs),
          Text(
            'Попробуйте выбрать другой фильтр',
            style: TextStyle(
              fontSize: 12,
              color: _P.textTertiary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareInfoBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(_R.md),
      margin: const EdgeInsets.fromLTRB(_Sp.lg, _Sp.sm, _Sp.lg, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _P.orange.withOpacity(0.12),
            _P.orange.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(_R.md),
        border: Border.all(color: _P.orange.withOpacity(0.22), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded,
              color: _P.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedPhotoIndex1 == null
                  ? '👆 Выберите первое фото'
                  : _selectedPhotoIndex2 == null
                  ? '👆 Выберите второе фото для сравнения'
                  : '✅ Готово! Нажмите на фото для просмотра',
              style: const TextStyle(
                fontSize: 12,
                color: _P.orange,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ),
          if (_selectedPhotoIndex1 != null &&
              _selectedPhotoIndex2 != null)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: _Sp.sm, vertical: 4),
              decoration: BoxDecoration(
                color: _P.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(_R.xs),
              ),
              child: Text(
                '2/2',
                style: _Num.t(const TextStyle(
                  color: _P.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                )),
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================================
  // PHOTO CARD
  // =====================================================================

  Widget _buildPhotoCard(
      bool isDark,
      FitnessPhoto photo,
      bool isSelected,
      int? selectionNumber,
      ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_R.lg - 2),
        border: isSelected
            ? Border.all(color: _P.orange, width: 3)
            : Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            width: 1),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: _P.orange.withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ]
            : _P.cardShadow(isDark, _P.orange),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(isSelected ? 12 : 16),
            child: _buildPhotoImage(photo, isDark),
          ),
          // Bottom gradient for label overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_R.lg - 2),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
          if (selectionNumber != null)
            Positioned(
              top: _Sp.sm,
              left: _Sp.sm,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_P.orange, _P.orangeDeep],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _P.orange.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$selectionNumber',
                    style: _Num.t(const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    )),
                  ),
                ),
              ),
            ),
          if (photo.label != null && photo.label!.isNotEmpty)
            Positioned(
              top: _Sp.sm,
              right: _Sp.sm,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: _Sp.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(_R.xs),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.12), width: 0.6),
                ),
                child: Text(
                  photo.label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDate(photo.date),
                          style: _Num.t(const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          )),
                        ),
                        if (photo.weight != null)
                          Text(
                            '⚖️ ${photo.weight!.toStringAsFixed(1)} кг',
                            style: _Num.t(TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 9,
                            )),
                          ),
                      ],
                    ),
                  ),
                  if (photo.measurementsCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _P.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '📏 ${photo.measurementsCount}',
                        style: _Num.t(const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        )),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoImage(FitnessPhoto photo, bool isDark) {
    final file = File(photo.imageUrl);
    if (file.existsSync()) return Image.file(file, fit: BoxFit.cover);
    return Container(
      color: isDark ? _P.darkCard : _P.greySoft,
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 48,
          color: _P.textTertiary(isDark),
        ),
      ),
    );
  }

  void _handlePhotoTap(int index, FitnessProvider provider) {
    if (_isCompareMode) {
      setState(() {
        if (_selectedPhotoIndex1 == null) {
          _selectedPhotoIndex1 = index;
          HapticFeedback.lightImpact();
        } else if (_selectedPhotoIndex2 == null &&
            _selectedPhotoIndex1 != index) {
          _selectedPhotoIndex2 = index;
          HapticFeedback.mediumImpact();
          _scaleController.forward(from: 0.0);
        } else {
          _selectedPhotoIndex1 = index;
          _selectedPhotoIndex2 = null;
          HapticFeedback.lightImpact();
        }
      });
    } else {
      _showPhotoDetail(context, widget.isDark, provider.photos[index], provider);
    }
  }

  // =====================================================================
  // EMPTY STATE
  // =====================================================================

  Widget _buildEmptyState(bool isDark, FitnessProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _P.orange.withOpacity(0.16),
                  _P.orange.withOpacity(0.02),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: _P.softGlow(_P.orange, strength: 0.14),
            ),
            child: Icon(
              Icons.photo_camera_rounded,
              size: 56,
              color: _P.orange.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: _Sp.xxl),
          Text(
            'Нет фотографий',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: _P.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: _Sp.sm),
          Text(
            'Добавьте фото, чтобы отслеживать\nвизуальный прогресс',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _P.textSecondary(isDark),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _Pressable(
            onTap: () => _showAddPhotoDialog(context, isDark, provider),
            scale: 0.96,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: _P.orange,
                borderRadius: BorderRadius.circular(_R.md),
                boxShadow: _P.softGlow(_P.orange, strength: 0.4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_a_photo_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: _Sp.sm),
                  Text(
                    'Добавить первое фото',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // COMPARE VIEW
  // =====================================================================

  Widget _buildCompareView(bool isDark, List<FitnessPhoto> photos) {
    if (_selectedPhotoIndex1 == null || _selectedPhotoIndex2 == null) {
      return _buildGalleryView(
          isDark, photos, context.read<FitnessProvider>());
    }

    final photo1 = photos[_selectedPhotoIndex1!];
    final photo2 = photos[_selectedPhotoIndex2!];
    final sorted = [photo1, photo2]..sort((a, b) => a.date.compareTo(b.date));
    final beforePhoto = sorted[0];
    final afterPhoto = sorted[1];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(_Sp.lg),
            child: Container(
              padding: const EdgeInsets.all(_Sp.lg),
              decoration: BoxDecoration(
                color: _P.card(isDark),
                borderRadius: BorderRadius.circular(_R.xl - 2),
                boxShadow: _P.cardShadow(isDark, _P.orange),
              ),
              child: Row(
                children: [
                  _buildCompareInfoChip(isDark, 'ДО', beforePhoto, true),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _R.md, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_P.orange, _P.orangeDeep],
                      ),
                      borderRadius: BorderRadius.circular(_R.xl),
                      boxShadow: _P.softGlow(_P.orange, strength: 0.4),
                    ),
                    child: Text(
                      '⏳ ${_getDaysBetween(beforePhoto.date, afterPhoto.date)}',
                      style: _Num.t(const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      )),
                    ),
                  ),
                  const Spacer(),
                  _buildCompareInfoChip(isDark, 'ПОСЛЕ', afterPhoto, false),
                ],
              ),
            ),
          ),
          _buildCompareImages(isDark, beforePhoto, afterPhoto),
          const SizedBox(height: _Sp.lg),
          _buildMeasurementsComparison(isDark, beforePhoto, afterPhoto),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCompareInfoChip(
      bool isDark,
      String label,
      FitnessPhoto photo,
      bool isBefore,
      ) {
    final color = isBefore ? _P.orange : _P.green;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: _Sp.sm, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(_R.xs),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: _Sp.xs),
        Text(
          _formatDate(photo.date),
          style: _Num.t(TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _P.textSecondary(isDark),
          )),
        ),
        if (photo.weight != null)
          Text(
            '${photo.weight!.toStringAsFixed(1)} кг',
            style: _Num.t(TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _P.textPrimary(isDark),
            )),
          ),
      ],
    );
  }

  Widget _buildCompareImages(
      bool isDark, FitnessPhoto before, FitnessPhoto after) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _Sp.lg),
      child: _isSliderMode
          ? _buildSliderCompare(isDark, before, after)
          : _buildSideBySideCompare(isDark, before, after),
    );
  }

  Widget _buildSideBySideCompare(
      bool isDark, FitnessPhoto before, FitnessPhoto after) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Row(
        children: [
          Expanded(
            child: _buildCompareImageContainer(
                isDark, before, 'ДО', _P.orange),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: const LinearGradient(
                colors: [_P.orange, _P.green],
              ),
            ),
          ),
          Expanded(
            child: _buildCompareImageContainer(
                isDark, after, 'ПОСЛЕ', _P.green),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareImageContainer(
      bool isDark,
      FitnessPhoto photo,
      String label,
      Color borderColor,
      ) {
    final file = File(photo.imageUrl);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_R.lg - 2),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 2),
        boxShadow: _P.cardShadow(isDark, borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: isDark ? _P.darkBg : _P.greySoft,
            ),
            file.existsSync()
                ? Image.file(file, fit: BoxFit.contain)
                : Center(
              child: Icon(
                Icons.image_rounded,
                size: 48,
                color: _P.textTertiary(isDark),
              ),
            ),
            Positioned(
              top: _Sp.sm,
              left: _Sp.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(_R.xs),
                  border: Border.all(
                      color: borderColor.withOpacity(0.5), width: 1),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: borderColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            if (photo.measurementsCount > 0)
              Positioned(
                bottom: _Sp.sm,
                right: _Sp.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _Sp.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '📏 ${photo.measurementsCount}',
                    style: _Num.t(const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    )),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // SLIDER COMPARE
  // =====================================================================

  Widget _buildSliderCompare(
      bool isDark, FitnessPhoto before, FitnessPhoto after) {
    return AspectRatio(
      aspectRatio: 0.85,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanUpdate: (d) {
              setState(() {
                _sliderPosition =
                    (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
              });
            },
            onTapDown: (d) {
              setState(() {
                _sliderPosition =
                    (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
              });
            },
            child: Stack(
              children: [
                // AFTER — background
                _buildSliderLayer(
                  isDark: isDark,
                  photo: after,
                  label: 'ПОСЛЕ',
                  color: _P.green,
                  alignment: Alignment.topRight,
                ),
                // BEFORE — clipped
                ClipRect(
                  clipper: _HalfClipper(_sliderPosition),
                  child: _buildSliderLayer(
                    isDark: isDark,
                    photo: before,
                    label: 'ДО',
                    color: _P.orange,
                    alignment: Alignment.topLeft,
                  ),
                ),
                // Divider line
                Positioned(
                  left: constraints.maxWidth * _sliderPosition - 2,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_P.orange, _P.green],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _P.orange.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                // Handle
                Positioned(
                  left: constraints.maxWidth * _sliderPosition - 22,
                  top: constraints.maxHeight / 2 - 22,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_P.orange, _P.orangeDeep],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: _P.softGlow(_P.orange, strength: 0.45),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chevron_left_rounded,
                            color: Colors.white, size: 18),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
                // Percent indicator
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: _R.md, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(_R.md),
                      ),
                      child: Text(
                        '${(_sliderPosition * 100).toInt()}%',
                        style: _Num.t(const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliderLayer({
    required bool isDark,
    required FitnessPhoto photo,
    required String label,
    required Color color,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_R.lg - 2),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
        boxShadow: _P.cardShadow(isDark, color),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: isDark ? _P.darkBg : _P.greySoft),
            _buildCompareImageForSlider(isDark, photo),
            Positioned(
              top: _Sp.sm,
              left: alignment == Alignment.topLeft ? _Sp.sm : null,
              right: alignment == Alignment.topRight ? _Sp.sm : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(_R.xs),
                  border: Border.all(color: color.withOpacity(0.5), width: 1),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareImageForSlider(bool isDark, FitnessPhoto photo) {
    final file = File(photo.imageUrl);
    if (file.existsSync()) return Image.file(file, fit: BoxFit.contain);
    return Center(
      child: Icon(
        Icons.image_rounded,
        size: 48,
        color: _P.textTertiary(isDark),
      ),
    );
  }

  // =====================================================================
  // MEASUREMENTS COMPARISON
  // =====================================================================

  Widget _buildMeasurementsComparison(
      bool isDark, FitnessPhoto before, FitnessPhoto after) {
    final measurements = <_MeasurementItem>[
      _MeasurementItem('Вес', 'кг', before.weight, after.weight,
          isWeight: true),
      _MeasurementItem('Грудь', 'см', before.chest, after.chest),
      _MeasurementItem('Талия', 'см', before.waist, after.waist,
          smallerIsBetter: true),
      _MeasurementItem('Бёдра', 'см', before.hips, after.hips),
      _MeasurementItem('Бицепс', 'см', before.biceps, after.biceps),
      _MeasurementItem('Бедро', 'см', before.thigh, after.thigh),
      _MeasurementItem('Икра', 'см', before.calf, after.calf),
      _MeasurementItem('Шея', 'см', before.neck, after.neck),
      _MeasurementItem('Предплечье', 'см', before.forearm, after.forearm),
    ];

    final comparableItems = measurements
        .where((m) => m.before != null && m.after != null)
        .toList();
    final partialItems = measurements
        .where((m) =>
    (m.before != null || m.after != null) &&
        !(m.before != null && m.after != null))
        .toList();

    if (comparableItems.isEmpty && partialItems.isEmpty) {
      return _buildEmptyMeasurementsCard(isDark);
    }

    return Container(
      margin: const EdgeInsets.all(_Sp.lg),
      padding: const EdgeInsets.all(_R.lg),
      decoration: BoxDecoration(
        color: _P.card(isDark),
        borderRadius: BorderRadius.circular(_R.xl - 2),
        boxShadow: _P.cardShadow(isDark, _P.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _P.orange.withOpacity(0.20),
                      _P.orange.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(_R.sm),
                  boxShadow: _P.softGlow(_P.orange, strength: 0.22),
                ),
                child: const Icon(Icons.straighten_rounded,
                    color: _P.orange, size: 20),
              ),
              const SizedBox(width: _Sp.md),
              Text(
                'Измерения тела',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: _P.textPrimary(isDark),
                ),
              ),
              const Spacer(),
              if (comparableItems.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: _Sp.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: _P.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(_R.xs),
                  ),
                  child: Text(
                    '${comparableItems.length} совпад.',
                    style: _Num.t(const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: _P.green,
                    )),
                  ),
                ),
            ],
          ),
          const SizedBox(height: _R.md),
          // Table header
          Container(
            padding:
            const EdgeInsets.symmetric(vertical: _Sp.sm, horizontal: 10),
            decoration: BoxDecoration(
              color: _P.card2(isDark),
              borderRadius: BorderRadius.circular(_R.xs),
            ),
            child: Row(
              children: [
                _headerCell('Параметр', isDark, flex: 2, align: TextAlign.left),
                _headerCell('До', isDark),
                _headerCell('После', isDark),
                _headerCell('Δ', isDark),
              ],
            ),
          ),
          const SizedBox(height: _Sp.xs),
          ...comparableItems.map((item) =>
              _buildMeasurementRow(isDark, item, showDiff: true)),
          if (partialItems.isNotEmpty) ...[
            const SizedBox(height: _Sp.md),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: _Sp.xs),
              decoration: BoxDecoration(
                color: _P.card2(isDark),
                borderRadius: BorderRadius.circular(_R.xs),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: _P.textTertiary(isDark)),
                  const SizedBox(width: 6),
                  Text(
                    'Частичные данные',
                    style: TextStyle(
                      fontSize: 10,
                      color: _P.textTertiary(isDark),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _Sp.xs),
            ...partialItems.map((item) =>
                _buildMeasurementRow(isDark, item, showDiff: false)),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(
      String label,
      bool isDark, {
        int flex = 1,
        TextAlign align = TextAlign.center,
      }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          color: _P.textTertiary(isDark),
        ),
      ),
    );
  }

  Widget _buildEmptyMeasurementsCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(_Sp.lg),
      padding: const EdgeInsets.all(_R.xxl),
      decoration: BoxDecoration(
        color: _P.card(isDark),
        borderRadius: BorderRadius.circular(_R.xl - 2),
        boxShadow: _P.cardShadow(isDark, _P.orange),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _P.orange.withOpacity(0.15),
                  _P.orange.withOpacity(0.03),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.straighten_rounded,
                size: 32, color: _P.textTertiary(isDark)),
          ),
          const SizedBox(height: _Sp.lg),
          Text(
            'Нет данных для сравнения',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _P.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: _Sp.xs),
          Text(
            'Добавьте измерения к фото',
            style: TextStyle(
              fontSize: 12,
              color: _P.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: _R.md),
          _Pressable(
            onTap: () => setState(() => _isCompareMode = false),
            scale: 0.96,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: _Sp.lg, vertical: _Sp.sm),
              decoration: BoxDecoration(
                color: _P.orangeSoft,
                borderRadius: BorderRadius.circular(_R.sm),
                border: Border.all(
                    color: _P.orange.withOpacity(0.22), width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 16, color: _P.orange),
                  SizedBox(width: 6),
                  Text(
                    'Вернуться к галерее',
                    style: TextStyle(
                      color: _P.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(
      bool isDark,
      _MeasurementItem item, {
        bool showDiff = true,
      }) {
    final hasBoth = item.before != null && item.after != null;
    final diff = hasBoth ? item.after! - item.before! : 0.0;

    Color diffColor;
    IconData? diffIcon;
    if (!hasBoth || diff.abs() < 0.05) {
      diffColor = _P.textTertiary(isDark);
    } else {
      final isPositive = item.smallerIsBetter ? diff < 0 : diff > 0;
      diffColor = isPositive ? _P.green : _P.red;
      diffIcon = diff > 0
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _P.separator(isDark), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(item.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: _P.textPrimary(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              item.before != null ? item.before!.toStringAsFixed(1) : '—',
              textAlign: TextAlign.center,
              style: _Num.t(TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _P.textSecondary(isDark),
              )),
            ),
          ),
          Expanded(
            child: Text(
              item.after != null ? item.after!.toStringAsFixed(1) : '—',
              textAlign: TextAlign.center,
              style: _Num.t(TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _P.textSecondary(isDark),
              )),
            ),
          ),
          if (showDiff)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (diffIcon != null)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: diff > 0 ? 0.0 : 0.5,
                      child: Icon(diffIcon, size: 14, color: diffColor),
                    ),
                  const SizedBox(width: 2),
                  Text(
                    hasBoth
                        ? '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}'
                        : '—',
                    style: _Num.t(TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: diffColor,
                    )),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================================
  // PHOTO DETAIL SHEET
  // =====================================================================

  void _showPhotoDetail(BuildContext context, bool isDark, FitnessPhoto photo,
      FitnessProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(_Sp.xl),
        decoration: BoxDecoration(
          color: _P.card(isDark),
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(_R.xxl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _P.textTertiary(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: _Sp.lg),
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_R.lg),
                child: File(photo.imageUrl).existsSync()
                    ? Image.file(File(photo.imageUrl), fit: BoxFit.contain)
                    : Container(
                  color: _P.card2(isDark),
                  child: Icon(Icons.image_rounded,
                      size: 80,
                      color: _P.textTertiary(isDark)),
                ),
              ),
            ),
            const SizedBox(height: _Sp.lg),
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _P.orangeSoft,
                    borderRadius: BorderRadius.circular(_R.xs),
                  ),
                  child: Text(
                    _formatDate(photo.date),
                    style: _Num.t(const TextStyle(
                      color: _P.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    )),
                  ),
                ),
                const SizedBox(width: 10),
                if (photo.label != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _P.card2(isDark),
                      borderRadius: BorderRadius.circular(_R.xs),
                    ),
                    child: Text(
                      photo.label!,
                      style: TextStyle(
                        color: _P.textSecondary(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (photo.notes != null && photo.notes!.isNotEmpty) ...[
              const SizedBox(height: _Sp.sm),
              Text(
                photo.notes!,
                style: TextStyle(
                  fontSize: 13,
                  color: _P.textSecondary(isDark),
                  height: 1.4,
                ),
              ),
            ],
            if (photo.measurementsCount > 0) ...[
              const SizedBox(height: _Sp.sm),
              _buildMeasurementsPreview(isDark, photo),
            ],
            const SizedBox(height: _R.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Изменить',
                  color: _P.orange,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditPhotoDialog(context, isDark, photo, provider);
                  },
                ),
                _buildActionButton(
                  icon: Icons.compare_rounded,
                  label: 'Сравнить',
                  color: _P.blue,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _isCompareMode = true;
                      _selectedPhotoIndex1 =
                          provider.photos.indexOf(photo);
                      _selectedPhotoIndex2 = null;
                    });
                  },
                ),
                _buildActionButton(
                  icon: Icons.delete_rounded,
                  label: 'Удалить',
                  color: _P.red,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeletePhoto(context, isDark, photo, provider);
                  },
                ),
              ],
            ),
            const SizedBox(height: _Sp.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      onTap: onTap,
      scale: 0.92,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(_R.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: _Sp.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsPreview(bool isDark, FitnessPhoto photo) {
    final measurements = <MapEntry<String, String>>[];
    if (photo.weight != null)
      measurements.add(MapEntry(
          '⚖️ Вес', '${photo.weight!.toStringAsFixed(1)} кг'));
    if (photo.chest != null)
      measurements.add(MapEntry(
          '📏 Грудь', '${photo.chest!.toStringAsFixed(1)} см'));
    if (photo.waist != null)
      measurements.add(MapEntry(
          '📏 Талия', '${photo.waist!.toStringAsFixed(1)} см'));
    if (photo.hips != null)
      measurements.add(MapEntry(
          '📏 Бёдра', '${photo.hips!.toStringAsFixed(1)} см'));
    if (photo.biceps != null)
      measurements.add(MapEntry(
          '💪 Бицепс', '${photo.biceps!.toStringAsFixed(1)} см'));
    if (photo.thigh != null)
      measurements.add(MapEntry(
          '🦵 Бедро', '${photo.thigh!.toStringAsFixed(1)} см'));
    if (photo.calf != null)
      measurements.add(MapEntry(
          '🦵 Икра', '${photo.calf!.toStringAsFixed(1)} см'));
    if (photo.neck != null)
      measurements.add(MapEntry(
          '📏 Шея', '${photo.neck!.toStringAsFixed(1)} см'));
    if (photo.forearm != null)
      measurements.add(MapEntry(
          '💪 Предплечье', '${photo.forearm!.toStringAsFixed(1)} см'));

    return Container(
      padding: const EdgeInsets.all(_R.md),
      decoration: BoxDecoration(
        color: _P.card2(isDark),
        borderRadius: BorderRadius.circular(_R.md),
      ),
      child: Wrap(
        spacing: _Sp.sm,
        runSpacing: _Sp.sm,
        children: measurements.map((m) {
          return Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _P.card(isDark),
              borderRadius: BorderRadius.circular(_R.xs),
              border: Border.all(color: _P.separator(isDark), width: 0.6),
            ),
            child: Text(
              '${m.key}: ${m.value}',
              style: _Num.t(TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _P.textPrimary(isDark),
              )),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =====================================================================
  // PHOTO OPTIONS (long-press)
  // =====================================================================

  void _showPhotoOptions(BuildContext context, bool isDark, FitnessPhoto photo,
      FitnessProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(_Sp.xl),
        decoration: BoxDecoration(
          color: _P.card(isDark),
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(_R.xxl)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _P.textTertiary(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: _Sp.xl),
              _menuTile(
                isDark,
                icon: Icons.edit_rounded,
                color: _P.orange,
                label: 'Редактировать',
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditPhotoDialog(context, isDark, photo, provider);
                },
              ),
              _menuTile(
                isDark,
                icon: Icons.compare_rounded,
                color: _P.blue,
                label: 'Сравнить с другим',
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _isCompareMode = true;
                    _selectedPhotoIndex1 = provider.photos.indexOf(photo);
                    _selectedPhotoIndex2 = null;
                  });
                },
              ),
              _menuTile(
                isDark,
                icon: Icons.delete_rounded,
                color: _P.red,
                label: 'Удалить',
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeletePhoto(context, isDark, photo, provider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile(
      bool isDark, {
        required IconData icon,
        required Color color,
        required String label,
        required VoidCallback onTap,
      }) {
    return _Pressable(
      onTap: onTap,
      scale: 0.98,
      haptic: false,
      child: Container(
        margin: const EdgeInsets.only(bottom: _Sp.sm),
        padding: const EdgeInsets.all(_R.md),
        decoration: BoxDecoration(
          color: _P.card2(isDark),
          borderRadius: BorderRadius.circular(_R.md),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.20), color.withOpacity(0.06)],
                ),
                borderRadius: BorderRadius.circular(_R.sm - 1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: _Sp.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _P.textTertiary(isDark), size: 20),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // ADD PHOTO DIALOG
  // =====================================================================

  void _showAddPhotoDialog(
      BuildContext context, bool isDark, FitnessProvider provider) {
    final labelController = TextEditingController();
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    final chestController = TextEditingController();
    final waistController = TextEditingController();
    final hipsController = TextEditingController();
    final bicepsController = TextEditingController();
    final thighController = TextEditingController();
    final calfController = TextEditingController();
    final neckController = TextEditingController();
    final forearmController = TextEditingController();
    File? selectedImage;
    bool showMeasurements = true;
    bool isLoading = false;
    String? selectedCategory;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_R.xxl),
          ),
          backgroundColor: _P.card(isDark),
          insetPadding: const EdgeInsets.all(_Sp.xl),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(_Sp.xxl),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogHeader(
                    isDark,
                    icon: Icons.add_a_photo_rounded,
                    title: 'Новое фото',
                    subtitle: 'Добавьте фото для отслеживания прогресса',
                  ),
                  const SizedBox(height: _Sp.xl),
                  _buildImagePicker(
                    isDark,
                    selectedImage: selectedImage,
                    onTap: () => _showImageSourcePicker(
                      context,
                      isDark,
                          (source) async {
                        try {
                          final XFile? image = await picker.pickImage(
                              source: source, imageQuality: 85);
                          if (image != null) {
                            setDialogState(
                                    () => selectedImage = File(image.path));
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ошибка: $e'),
                              backgroundColor: _P.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(_R.md),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: _Sp.lg),
                  _buildCategorySelector(
                    isDark,
                    selectedCategory,
                        (category) =>
                        setDialogState(() => selectedCategory = category),
                  ),
                  const SizedBox(height: _R.md),
                  _buildFieldGroup(isDark, [
                    _styledTextField('Подпись', labelController,
                        Icons.label_rounded, isDark),
                    _styledTextField('Вес (кг)', weightController,
                        Icons.monitor_weight_outlined, isDark,
                        isNumber: true),
                  ]),
                  const SizedBox(height: _R.md),
                  _buildMeasurementToggle(
                      isDark, showMeasurements, setDialogState),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: showMeasurements
                        ? Padding(
                      padding: const EdgeInsets.only(top: _R.md),
                      child: _buildFieldGroup(isDark, [
                        _measurementField('Грудь (см)', chestController,
                            isDark, Icons.favorite_outline),
                        _measurementField('Талия (см)', waistController,
                            isDark, Icons.hourglass_empty),
                        _measurementField('Бёдра (см)', hipsController,
                            isDark, Icons.water_drop_outlined),
                        Row(
                          children: [
                            Expanded(
                              child: _measurementField(
                                  'Бицепс',
                                  bicepsController,
                                  isDark,
                                  Icons.fitness_center),
                            ),
                            const SizedBox(width: _Sp.sm),
                            Expanded(
                              child: _measurementField(
                                  'Предплечье',
                                  forearmController,
                                  isDark,
                                  Icons.fitness_center),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _measurementField(
                                  'Бедро',
                                  thighController,
                                  isDark,
                                  Icons.airline_seat_legroom_extra),
                            ),
                            const SizedBox(width: _Sp.sm),
                            Expanded(
                              child: _measurementField(
                                  'Икра',
                                  calfController,
                                  isDark,
                                  Icons.airline_seat_legroom_extra),
                            ),
                          ],
                        ),
                        _measurementField('Шея (см)', neckController,
                            isDark, Icons.panorama_fish_eye),
                      ]),
                    )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: _R.md),
                  _styledTextField('Заметки', notesController,
                      Icons.note_rounded, isDark,
                      maxLines: 2),
                  const SizedBox(height: _Sp.xl),
                  _buildDialogActions(
                    isDark,
                    isLoading: isLoading,
                    onCancel: () => Navigator.pop(ctx),
                    onConfirm: () async {
                      if (selectedImage == null) {
                        HapticFeedback.mediumImpact();
                        _showSnack(
                          context,
                          'Выберите фото',
                          _P.orange,
                          icon: Icons.warning_rounded,
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        String finalLabel = labelController.text.trim();
                        if (selectedCategory != null &&
                            selectedCategory!.isNotEmpty) {
                          const categoryMap = {
                            'progress': '📈 Прогресс',
                            'workout': '💪 Тренировка',
                            'measurement': '📏 Замер',
                          };
                          final prefix = categoryMap[selectedCategory] ?? '';
                          if (prefix.isNotEmpty) {
                            finalLabel = finalLabel.isNotEmpty
                                ? '$prefix: $finalLabel'
                                : prefix;
                          }
                        }
                        await provider.addPhoto(
                          imageUrl: selectedImage!.path,
                          label:
                          finalLabel.isNotEmpty ? finalLabel : null,
                          weight: double.tryParse(weightController.text),
                          notes: notesController.text.isNotEmpty
                              ? notesController.text
                              : null,
                          chest: double.tryParse(chestController.text),
                          waist: double.tryParse(waistController.text),
                          hips: double.tryParse(hipsController.text),
                          biceps: double.tryParse(bicepsController.text),
                          thigh: double.tryParse(thighController.text),
                          calf: double.tryParse(calfController.text),
                          neck: double.tryParse(neckController.text),
                          forearm: double.tryParse(forearmController.text),
                        );
                        _scaleController.forward(from: 0.0);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(
                            context,
                            'Фото добавлено! 📸',
                            _P.orange,
                            icon: Icons.check_circle_rounded,
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (!context.mounted) return;
                        _showSnack(context, 'Ошибка: $e', _P.red);
                      }
                    },
                    confirmLabel: 'Добавить',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // EDIT PHOTO DIALOG
  // =====================================================================

  void _showEditPhotoDialog(BuildContext context, bool isDark,
      FitnessPhoto photo, FitnessProvider provider) {
    final labelController = TextEditingController(text: photo.label);
    final weightController =
    TextEditingController(text: photo.weight?.toString() ?? '');
    final notesController = TextEditingController(text: photo.notes);
    final chestController =
    TextEditingController(text: photo.chest?.toString() ?? '');
    final waistController =
    TextEditingController(text: photo.waist?.toString() ?? '');
    final hipsController =
    TextEditingController(text: photo.hips?.toString() ?? '');
    final bicepsController =
    TextEditingController(text: photo.biceps?.toString() ?? '');
    final thighController =
    TextEditingController(text: photo.thigh?.toString() ?? '');
    final calfController =
    TextEditingController(text: photo.calf?.toString() ?? '');
    final neckController =
    TextEditingController(text: photo.neck?.toString() ?? '');
    final forearmController =
    TextEditingController(text: photo.forearm?.toString() ?? '');
    bool showMeasurements = photo.measurementsCount > 0;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_R.xxl),
          ),
          backgroundColor: _P.card(isDark),
          insetPadding: const EdgeInsets.all(_Sp.xl),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(_Sp.xxl),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogHeader(
                    isDark,
                    icon: Icons.edit_rounded,
                    title: 'Редактировать фото',
                    subtitle: 'Измените данные фото',
                  ),
                  const SizedBox(height: _Sp.lg),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: _P.card2(isDark),
                      borderRadius: BorderRadius.circular(_R.md),
                      border: Border.all(
                          color: _P.separator(isDark), width: 0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_R.md),
                      child: File(photo.imageUrl).existsSync()
                          ? Image.file(File(photo.imageUrl),
                          fit: BoxFit.contain)
                          : Center(
                        child: Icon(Icons.image_rounded,
                            size: 48,
                            color: _P.textTertiary(isDark)),
                      ),
                    ),
                  ),
                  const SizedBox(height: _Sp.lg),
                  _buildFieldGroup(isDark, [
                    _styledTextField('Подпись', labelController,
                        Icons.label_rounded, isDark),
                    _styledTextField('Вес (кг)', weightController,
                        Icons.monitor_weight_outlined, isDark,
                        isNumber: true),
                  ]),
                  const SizedBox(height: _R.md),
                  _buildMeasurementToggle(
                      isDark, showMeasurements, setDialogState),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: showMeasurements
                        ? Padding(
                      padding: const EdgeInsets.only(top: _R.md),
                      child: _buildFieldGroup(isDark, [
                        _measurementField('Грудь (см)', chestController,
                            isDark, Icons.favorite_outline),
                        _measurementField('Талия (см)', waistController,
                            isDark, Icons.hourglass_empty),
                        _measurementField('Бёдра (см)', hipsController,
                            isDark, Icons.water_drop_outlined),
                        Row(
                          children: [
                            Expanded(
                              child: _measurementField(
                                  'Бицепс',
                                  bicepsController,
                                  isDark,
                                  Icons.fitness_center),
                            ),
                            const SizedBox(width: _Sp.sm),
                            Expanded(
                              child: _measurementField(
                                  'Предплечье',
                                  forearmController,
                                  isDark,
                                  Icons.fitness_center),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _measurementField(
                                  'Бедро',
                                  thighController,
                                  isDark,
                                  Icons.airline_seat_legroom_extra),
                            ),
                            const SizedBox(width: _Sp.sm),
                            Expanded(
                              child: _measurementField(
                                  'Икра',
                                  calfController,
                                  isDark,
                                  Icons.airline_seat_legroom_extra),
                            ),
                          ],
                        ),
                        _measurementField('Шея (см)', neckController,
                            isDark, Icons.panorama_fish_eye),
                      ]),
                    )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: _R.md),
                  _styledTextField('Заметки', notesController,
                      Icons.note_rounded, isDark,
                      maxLines: 2),
                  const SizedBox(height: _Sp.xl),
                  _buildDialogActions(
                    isDark,
                    isLoading: isLoading,
                    onCancel: () => Navigator.pop(ctx),
                    onConfirm: () async {
                      setDialogState(() => isLoading = true);
                      try {
                        final updated = photo.copyWith(
                          label: labelController.text.isNotEmpty
                              ? labelController.text
                              : null,
                          weight: double.tryParse(weightController.text),
                          notes: notesController.text.isNotEmpty
                              ? notesController.text
                              : null,
                          chest: double.tryParse(chestController.text),
                          waist: double.tryParse(waistController.text),
                          hips: double.tryParse(hipsController.text),
                          biceps: double.tryParse(bicepsController.text),
                          thigh: double.tryParse(thighController.text),
                          calf: double.tryParse(calfController.text),
                          neck: double.tryParse(neckController.text),
                          forearm: double.tryParse(forearmController.text),
                          clearChest: chestController.text.isEmpty,
                          clearWaist: waistController.text.isEmpty,
                          clearHips: hipsController.text.isEmpty,
                          clearBiceps: bicepsController.text.isEmpty,
                          clearThigh: thighController.text.isEmpty,
                          clearCalf: calfController.text.isEmpty,
                          clearNeck: neckController.text.isEmpty,
                          clearForearm: forearmController.text.isEmpty,
                        );
                        await provider.updatePhoto(updated);
                        _scaleController.forward(from: 0.0);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(
                            context,
                            'Фото обновлено! ✨',
                            _P.orange,
                            icon: Icons.check_circle_rounded,
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (!context.mounted) return;
                        _showSnack(context, 'Ошибка: $e', _P.red);
                      }
                    },
                    confirmLabel: 'Сохранить',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // SHARED DIALOG PIECES
  // =====================================================================

  Widget _buildDialogHeader(
      bool isDark, {
        required IconData icon,
        required String title,
        required String subtitle,
      }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_P.orange, _P.orangeDeep],
            ),
            borderRadius: BorderRadius.circular(_R.md),
            boxShadow: _P.softGlow(_P.orange, strength: 0.4),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: _R.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _P.textPrimary(isDark),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: _P.textSecondary(isDark),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(
      bool isDark, {
        required File? selectedImage,
        required VoidCallback onTap,
      }) {
    return _Pressable(
      onTap: onTap,
      scale: 0.98,
      haptic: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: selectedImage == null ? 180 : 220,
        decoration: BoxDecoration(
          color: _P.card2(isDark),
          borderRadius: BorderRadius.circular(_R.lg - 2),
          border: Border.all(
            color: selectedImage != null
                ? _P.orange
                : _P.separator(isDark),
            width: selectedImage != null ? 2 : 1,
          ),
          boxShadow: selectedImage != null
              ? _P.softGlow(_P.orange, strength: 0.25)
              : null,
        ),
        child: selectedImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(selectedImage, fit: BoxFit.cover),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(_Sp.sm),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_P.orange, _P.orangeDeep],
                    ),
                    borderRadius: BorderRadius.circular(_R.xs),
                    boxShadow:
                    _P.softGlow(_P.orange, strength: 0.4),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: _R.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Нажмите, чтобы изменить фото',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(_R.xl),
              decoration: BoxDecoration(
                color: _P.orangeSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_rounded,
                  color: _P.orange, size: 44),
            ),
            const SizedBox(height: _R.md),
            Text(
              'Нажмите, чтобы выбрать фото',
              style: TextStyle(
                color: _P.textSecondary(isDark),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Камера или галерея',
              style: TextStyle(
                color: _P.textTertiary(isDark),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldGroup(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _P.card2(isDark),
        borderRadius: BorderRadius.circular(_R.md),
        border: Border.all(color: _P.separator(isDark), width: 0.5),
      ),
      padding: const EdgeInsets.all(_R.md),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementToggle(
      bool isDark,
      bool showMeasurements,
      StateSetter setDialogState,
      ) {
    return _Pressable(
      onTap: () => setDialogState(
              () => showMeasurements = !showMeasurements),
      scale: 0.98,
      haptic: false,
      child: Container(
        padding: const EdgeInsets.all(_R.md),
        decoration: BoxDecoration(
          color: showMeasurements
              ? _P.orangeSoft
              : _P.card2(isDark),
          borderRadius: BorderRadius.circular(_R.md),
          border: Border.all(
            color: showMeasurements
                ? _P.orange.withOpacity(0.28)
                : _P.separator(isDark),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(_Sp.sm),
              decoration: BoxDecoration(
                color: showMeasurements
                    ? _P.orange
                    : _P.card(isDark),
                borderRadius: BorderRadius.circular(_R.xs + 2),
                boxShadow: showMeasurements
                    ? _P.softGlow(_P.orange, strength: 0.3)
                    : null,
              ),
              child: Icon(
                Icons.straighten_rounded,
                color: showMeasurements
                    ? Colors.white
                    : _P.textTertiary(isDark),
                size: 20,
              ),
            ),
            const SizedBox(width: _R.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Обхваты тела',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: _P.textPrimary(isDark),
                    ),
                  ),
                  Text(
                    showMeasurements
                        ? 'Скрыть измерения'
                        : 'Добавить измерения',
                    style: TextStyle(
                      fontSize: 12,
                      color: _P.textTertiary(isDark),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: showMeasurements ? 0.5 : 0,
              child: Icon(Icons.expand_more_rounded,
                  color: _P.textTertiary(isDark), size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _styledTextField(
      String label,
      TextEditingController controller,
      IconData icon,
      bool isDark, {
        bool isNumber = false,
        int maxLines = 1,
      }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      style: TextStyle(
        color: _P.textPrimary(isDark),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _P.orange, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_R.sm),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _P.card(isDark),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: _R.md, vertical: _R.md),
        labelStyle: TextStyle(
          fontSize: 13,
          color: _P.textTertiary(isDark),
        ),
        floatingLabelStyle: const TextStyle(
          color: _P.orange,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _measurementField(
      String label,
      TextEditingController controller,
      bool isDark,
      IconData icon,
      ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: _Num.t(TextStyle(
        color: _P.textPrimary(isDark),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      )),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _P.orange, size: 18),
        labelStyle: TextStyle(
          fontSize: 12,
          color: _P.textTertiary(isDark),
        ),
        floatingLabelStyle: const TextStyle(
          color: _P.orange,
          fontWeight: FontWeight.w700,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: _R.md, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_R.xs + 2),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _P.card(isDark),
        isDense: true,
      ),
    );
  }

  Widget _buildDialogActions(
      bool isDark, {
        required bool isLoading,
        required VoidCallback onCancel,
        required VoidCallback onConfirm,
        required String confirmLabel,
      }) {
    return Row(
      children: [
        Expanded(
          child: _Pressable(
            onTap: isLoading ? () {} : onCancel,
            scale: 0.96,
            haptic: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: _R.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _P.card2(isDark),
                borderRadius: BorderRadius.circular(_R.sm),
              ),
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: _P.textSecondary(isDark),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _Pressable(
            onTap: isLoading ? () {} : onConfirm,
            scale: 0.96,
            haptic: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: _R.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _P.orange,
                borderRadius: BorderRadius.circular(_R.sm),
                boxShadow:
                isLoading ? null : _P.softGlow(_P.orange, strength: 0.4),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : Text(
                confirmLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
      bool isDark,
      String? selected,
      ValueChanged<String> onSelect,
      ) {
    const categories = [
      {
        'id': 'progress',
        'label': 'Прогресс',
        'color': _P.green,
        'emoji': '📈',
      },
      {
        'id': 'workout',
        'label': 'Тренировка',
        'color': _P.orange,
        'emoji': '💪',
      },
      {
        'id': 'measurement',
        'label': 'Замер',
        'color': _P.blue,
        'emoji': '📏',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_rounded,
                color: _P.textTertiary(isDark), size: 16),
            const SizedBox(width: 6),
            Text(
              'Категория',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: _P.textTertiary(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: _Sp.sm),
        Wrap(
          spacing: _Sp.sm,
          runSpacing: _Sp.sm,
          children: categories.map((cat) {
            final isSelected = selected == cat['id'];
            final color = cat['color'] as Color;
            final emoji = cat['emoji'] as String;
            final label = cat['label'] as String;
            final id = cat['id'] as String;
            return _Pressable(
              onTap: () => onSelect(isSelected ? '' : id),
              scale: 0.96,
              haptic: false,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                const EdgeInsets.symmetric(horizontal: _R.md, vertical: _Sp.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : _P.card2(isDark),
                  borderRadius: BorderRadius.circular(_R.sm),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : _P.separator(isDark),
                    width: isSelected ? 1.6 : 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color:
                        isSelected ? color : _P.textSecondary(isDark),
                      ),
                    ),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.check_rounded,
                            size: 16, color: color),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // =====================================================================
  // IMAGE SOURCE PICKER
  // =====================================================================

  void _showImageSourcePicker(
      BuildContext context, bool isDark, ValueChanged<ImageSource> onPick) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(_Sp.xl),
        decoration: BoxDecoration(
          color: _P.card(isDark),
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(_R.xxl)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _P.textTertiary(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: _Sp.lg),
              Text(
                'Выберите источник',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: _P.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: _Sp.lg),
              _sourceTile(
                isDark,
                icon: Icons.camera_alt_rounded,
                color: _P.orange,
                title: 'Камера',
                subtitle: 'Сделать новое фото',
                onTap: () {
                  Navigator.pop(ctx);
                  onPick(ImageSource.camera);
                },
              ),
              const SizedBox(height: _Sp.sm),
              _sourceTile(
                isDark,
                icon: Icons.photo_library_rounded,
                color: _P.blue,
                title: 'Галерея',
                subtitle: 'Выбрать из сохранённых',
                onTap: () {
                  Navigator.pop(ctx);
                  onPick(ImageSource.gallery);
                },
              ),
              const SizedBox(height: _Sp.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceTile(
      bool isDark, {
        required IconData icon,
        required Color color,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return _Pressable(
      onTap: onTap,
      scale: 0.98,
      haptic: false,
      child: Container(
        padding: const EdgeInsets.all(_R.md),
        decoration: BoxDecoration(
          color: _P.card2(isDark),
          borderRadius: BorderRadius.circular(_R.md),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.20),
                    color.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(_R.sm),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: _R.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -0.2,
                      color: _P.textPrimary(isDark),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _P.textSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _P.textTertiary(isDark), size: 20),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // DELETE CONFIRM (iOS style)
  // =====================================================================

  void _confirmDeletePhoto(BuildContext context, bool isDark,
      FitnessPhoto photo, FitnessProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? _P.darkCard2 : Colors.white,
            borderRadius: BorderRadius.circular(_R.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    _Sp.xl, _Sp.xl, _Sp.xl, _Sp.lg),
                child: Column(
                  children: [
                    Text(
                      'Удалить фото?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _P.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Фото будет удалено безвозвратно',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _P.textSecondary(isDark),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 0.5, color: _P.separator(isDark)),
              Row(
                children: [
                  Expanded(
                    child: _Pressable(
                      onTap: () => Navigator.pop(ctx),
                      scale: 0.96,
                      haptic: false,
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: _Sp.md),
                        alignment: Alignment.center,
                        child: const Text(
                          'Отмена',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: _P.orange,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                      width: 0.5,
                      height: 50,
                      color: _P.separator(isDark)),
                  Expanded(
                    child: _Pressable(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await provider.deletePhoto(photo.id);
                        try {
                          final file = File(photo.imageUrl);
                          if (file.existsSync()) await file.delete();
                        } catch (_) {}
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      scale: 0.96,
                      haptic: false,
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: _Sp.md),
                        alignment: Alignment.center,
                        child: const Text(
                          'Удалить',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _P.red,
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
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  void _showSnack(
      BuildContext context,
      String text,
      Color color, {
        IconData? icon,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: _Sp.sm),
            ],
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_R.md),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getDaysBetween(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    if (days < 30) return '$days дн.';
    if (days < 365) return '${(days / 30).round()} мес.';
    return '${(days / 365).toStringAsFixed(1)} г.';
  }
}

// ==================== HELPER CLASSES ====================

class FilterOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  const FilterOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _MeasurementItem {
  final String name;
  final String unit;
  final double? before;
  final double? after;
  final bool isWeight;
  final bool smallerIsBetter;

  String get icon {
    if (isWeight) return '⚖️';
    if (name == 'Грудь') return '👕';
    if (name == 'Талия') return '⏳';
    if (name == 'Бёдра') return '👖';
    if (name == 'Бицепс') return '💪';
    if (name == 'Бедро') return '🦵';
    if (name == 'Икра') return '🦵';
    if (name == 'Шея') return '👔';
    if (name == 'Предплечье') return '💪';
    return '📏';
  }

  _MeasurementItem(
      this.name,
      this.unit,
      this.before,
      this.after, {
        this.isWeight = false,
        this.smallerIsBetter = false,
      });
}

class _HalfClipper extends CustomClipper<Rect> {
  final double position;
  _HalfClipper(this.position);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * position, size.height);

  @override
  bool shouldReclip(_HalfClipper oldClipper) =>
      oldClipper.position != position;
}