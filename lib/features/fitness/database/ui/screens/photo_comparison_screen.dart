import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/fitness_provider.dart';

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

  final List<FilterOption> _filterOptions = [
    const FilterOption(
      id: 'all',
      label: 'Все фото',
      icon: Icons.grid_view_rounded,
      color: Color(0xFF6C7A8A),
    ),
    const FilterOption(
      id: 'progress',
      label: 'Прогресс',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF4CAF50),
    ),
    const FilterOption(
      id: 'workout',
      label: 'Тренировки',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFFF6B35),
    ),
    const FilterOption(
      id: 'measurements',
      label: 'Замеры',
      icon: Icons.straighten_rounded,
      color: Color(0xFF4A9BFF),
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
      backgroundColor: isDark ? const Color(0xFF0A0D14) : const Color(0xFFF2F5F9),
      appBar: _buildAppBar(isDark, provider),
      body: _isCompareMode
          ? _buildCompareView(isDark, photos)
          : _buildGalleryView(isDark, photos, provider),
      floatingActionButton: _buildFloatingButton(isDark, provider),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, FitnessProvider provider) {
    final photos = provider.photos;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1D24) : Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isCompareMode)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.photo_camera_rounded,
                  color: Colors.white, size: 18),
            ),
          const SizedBox(width: 10),
          Text(
            _isCompareMode ? 'Сравнение' : 'Фотоотчёты',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          if (!_isCompareMode && photos.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${photos.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ),
        ],
      ),
      actions: [
        if (_isCompareMode) ...[
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isSliderMode
                    ? Icons.compare_arrows_rounded
                    : Icons.swipe_rounded,
                key: ValueKey(_isSliderMode),
                color: const Color(0xFFFF6B35),
              ),
            ),
            tooltip: _isSliderMode ? 'Рядом' : 'Слайдер',
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isSliderMode = !_isSliderMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _isCompareMode = false;
                _selectedPhotoIndex1 = null;
                _selectedPhotoIndex2 = null;
              });
            },
          ),
        ] else if (photos.length >= 2) ...[
          TextButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() => _isCompareMode = true);
            },
            icon: const Icon(Icons.compare_rounded, size: 16),
            label: const Text('Сравнить', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B35),
              backgroundColor: const Color(0xFFFF6B35).withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFloatingButton(bool isDark, FitnessProvider provider) {
    return AnimatedScale(
      scale: _scaleAnimation.value,
      duration: const Duration(milliseconds: 400),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddPhotoDialog(context, isDark, provider);
        },
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text(
          'Добавить фото',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryView(
      bool isDark, List<FitnessPhoto> photos, FitnessProvider provider) {
    final filteredPhotos = _applyFilter(photos);

    if (photos.isEmpty) {
      return _buildEmptyState(isDark, provider);
    }

    return Column(
      children: [
        if (!_isCompareMode) _buildBeautifulFilterBar(isDark, provider.photos),
        if (_isCompareMode) _buildCompareInfoBanner(isDark),
        Expanded(
          child: filteredPhotos.isEmpty
              ? _buildEmptyFilterState(isDark)
              : GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              final selectionNumber = _selectedPhotoIndex1 == realIndex
                  ? 1
                  : _selectedPhotoIndex2 == realIndex
                  ? 2
                  : null;

              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _handlePhotoTap(realIndex, provider);
                    },
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showPhotoOptions(context, isDark, photo, provider);
                    },
                    child: _buildPhotoCard(
                      isDark,
                      photo,
                      isSelected,
                      selectionNumber,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBeautifulFilterBar(bool isDark, List<FitnessPhoto> photos) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            final count = _getFilteredCount(photos, filter.id);
            final isActive = _selectedFilter == filter.id;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(isDark, filter, count, isActive),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      bool isDark, FilterOption filter, int count, bool isActive) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedFilter = filter.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? filter.color
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? filter.color
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: filter.color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]
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
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
              ),
            ),
            if (filter.id != 'all') ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.2)
                      : filter.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white70 : filter.color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getFilteredCount(List<FitnessPhoto> photos, String filterId) {
    return _applyFilterWithId(photos, filterId).length;
  }

  List<FitnessPhoto> _applyFilter(List<FitnessPhoto> photos) {
    return _applyFilterWithId(photos, _selectedFilter);
  }

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
          Icon(Icons.filter_alt_rounded,
              size: 48, color: isDark ? Colors.white12 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Нет фото в этой категории',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте выбрать другой фильтр',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareInfoBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.12),
            const Color(0xFFFF6B35).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF6B35).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: const Color(0xFFFF6B35), size: 18),
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
                color: Color(0xFFFF6B35),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_selectedPhotoIndex1 != null && _selectedPhotoIndex2 != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('2/2',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  )),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(
      bool isDark,
      FitnessPhoto photo,
      bool isSelected,
      int? selectionNumber,
      ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: isSelected
            ? Border.all(color: const Color(0xFFFF6B35), width: 3.5)
            : Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04)),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(isSelected ? 15 : 18),
            child: _buildPhotoImage(photo, isDark),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
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
              top: 8,
              left: 8,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$selectionNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          if (photo.label != null && photo.label!.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (photo.weight != null)
                          Text(
                            '⚖️ ${photo.weight!.toStringAsFixed(1)} кг',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (photo.measurementsCount > 0)
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '📏 ${photo.measurementsCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
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
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: isDark ? const Color(0xFF1A1D24) : Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 48,
          color: isDark ? Colors.white12 : Colors.grey.shade400,
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
      final photo = provider.photos[index];
      _showPhotoDetail(context, widget.isDark, photo, provider);
    }
  }

  Widget _buildEmptyState(bool isDark, FitnessProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B35).withOpacity(0.1),
                  const Color(0xFFFF3D00).withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF6B35).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.photo_camera_rounded,
              size: 60,
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Нет фотографий',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте фото, чтобы отслеживать\nвизуальный прогресс',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showAddPhotoDialog(context, isDark, provider);
            },
            icon: const Icon(Icons.add_a_photo_rounded),
            label: const Text('Добавить первое фото'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== РЕЖИМ СРАВНЕНИЯ ====================

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
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D24) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildCompareInfoChip('ДО', beforePhoto, true),
                  const Spacer(),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      '⏳ ${_getDaysBetween(beforePhoto.date, afterPhoto.date)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildCompareInfoChip('ПОСЛЕ', afterPhoto, false),
                ],
              ),
            ),
          ),
          // ==================== 🔧 ИСПРАВЛЕНО: Фото больше не увеличены ====================
          _buildCompareImages(isDark, beforePhoto, afterPhoto),
          const SizedBox(height: 16),
          _buildMeasurementsComparison(isDark, beforePhoto, afterPhoto),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==================== 🔧 ИСПРАВЛЕНО: Сравнение фото ====================

  Widget _buildCompareImages(
      bool isDark, FitnessPhoto before, FitnessPhoto after) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _isSliderMode
          ? _buildSliderCompare(isDark, before, after)
          : _buildSideBySideCompare(isDark, before, after),
    );
  }

  Widget _buildCompareInfoChip(
      String label, FitnessPhoto photo, bool isBefore) {
    final isDark = widget.isDark;
    final color = isBefore ? const Color(0xFFFF6B35) : const Color(0xFF4CAF50);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(photo.date),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        if (photo.weight != null)
          Text(
            '${photo.weight!.toStringAsFixed(1)} кг',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
      ],
    );
  }

  // ==================== 🔧 SIDE BY SIDE (ИСПРАВЛЕНО) ====================

  Widget _buildSideBySideCompare(
      bool isDark, FitnessPhoto before, FitnessPhoto after) {
    return AspectRatio(
      aspectRatio: 1.0, // 🔒 Квадратное соотношение — фото не растягивается
      child: Row(
        children: [
          Expanded(
            child: _buildCompareImageContainer(
                isDark, before, 'ДО', const Color(0xFFFF6B35)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B35),
                  const Color(0xFF4CAF50),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildCompareImageContainer(
                isDark, after, 'ПОСЛЕ', const Color(0xFF4CAF50)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareImageContainer(bool isDark, FitnessPhoto photo,
      String label, Color borderColor) {
    final file = File(photo.imageUrl);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 🔧 ИСПРАВЛЕНО: Фон для BoxFit.contain
            Container(
              color: isDark ? const Color(0xFF0A0D14) : Colors.grey.shade100,
            ),
            // 🔧 ИСПРАВЛЕНО: BoxFit.contain — фото целиком видно, не обрезается
            file.existsSync()
                ? Image.file(file, fit: BoxFit.contain)
                : Center(
              child: Icon(Icons.image_rounded,
                  size: 48,
                  color:
                  isDark ? Colors.white12 : Colors.grey.shade400),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: borderColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (photo.measurementsCount > 0)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '📏 ${photo.measurementsCount}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== 🔧 СЛАЙДЕР СРАВНЕНИЕ (ИСПРАВЛЕНО) ====================

  Widget _buildSliderCompare(
      bool isDark, FitnessPhoto before, FitnessPhoto after) {
    return AspectRatio(
      aspectRatio: 0.85, // 🔒 Фиксированное соотношение — не растягивается
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanUpdate: (details) {
              final newX = details.localPosition.dx;
              final width = constraints.maxWidth;
              setState(() {
                _sliderPosition = (newX / width).clamp(0.0, 1.0);
              });
            },
            onTapDown: (details) {
              final newX = details.localPosition.dx;
              final width = constraints.maxWidth;
              setState(() {
                _sliderPosition = (newX / width).clamp(0.0, 1.0);
              });
            },
            child: Stack(
              children: [
                // Фото "После" (фон)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.4),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: isDark
                              ? const Color(0xFF0A0D14)
                              : Colors.grey.shade100,
                        ),
                        _buildCompareImageForSlider(isDark, after, false),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF4CAF50).withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'ПОСЛЕ',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Фото "До" (обрезанное)
                ClipRect(
                  clipper: _HalfClipper(_sliderPosition),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.4),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: isDark
                                ? const Color(0xFF0A0D14)
                                : Colors.grey.shade100,
                          ),
                          _buildCompareImageForSlider(isDark, before, true),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                  const Color(0xFFFF6B35).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'ДО',
                                style: TextStyle(
                                  color: Color(0xFFFF6B35),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Вертикальная линия
                Positioned(
                  left: constraints.maxWidth * _sliderPosition - 2,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFF4CAF50)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                // Ручка слайдера
                Positioned(
                  left: constraints.maxWidth * _sliderPosition - 22,
                  top: constraints.maxHeight / 2 - 22,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
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
                // Индикатор процента
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${(_sliderPosition * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
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

  Widget _buildCompareImageForSlider(
      bool isDark, FitnessPhoto photo, bool isBefore) {
    final file = File(photo.imageUrl);
    if (file.existsSync()) {
      // 🔧 ИСПРАВЛЕНО: BoxFit.contain — фото целиком видно
      return Image.file(file, fit: BoxFit.contain);
    }
    return Center(
      child: Icon(
        Icons.image_rounded,
        size: 48,
        color: isDark ? Colors.white12 : Colors.grey.shade400,
      ),
    );
  }

  // ==================== СРАВНЕНИЕ ИЗМЕРЕНИЙ ====================

  Widget _buildMeasurementsComparison(
      bool isDark, FitnessPhoto before, FitnessPhoto after) {
    final measurements = <_MeasurementItem>[
      _MeasurementItem('Вес', 'кг', before.weight, after.weight, isWeight: true),
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

    final comparableItems =
    measurements.where((m) => m.before != null && m.after != null).toList();
    final partialItems = measurements
        .where((m) =>
    (m.before != null || m.after != null) &&
        !(m.before != null && m.after != null))
        .toList();

    if (comparableItems.isEmpty && partialItems.isEmpty) {
      return _buildEmptyMeasurementsCard(isDark);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
            const Color(0xFF1A1D24),
            const Color(0xFF252830),
          ]
              : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.straighten_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Измерения тела',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (comparableItems.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${comparableItems.length} совпад.',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Параметр',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade600)),
                ),
                Expanded(
                  child: Text('До',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade600)),
                ),
                Expanded(
                  child: Text('После',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade600)),
                ),
                Expanded(
                  child: Text('Δ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...comparableItems.map(
                  (item) => _buildMeasurementRow(isDark, item, showDiff: true)),
          if (partialItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text('Частичные данные',
                      style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...partialItems.map(
                    (item) => _buildMeasurementRow(isDark, item, showDiff: false)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyMeasurementsCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.straighten_rounded,
              size: 40, color: isDark ? Colors.white12 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Нет данных для сравнения',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Добавьте измерения к фото',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isCompareMode = false);
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Вернуться к галерее'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(
      bool isDark, _MeasurementItem item,
      {bool showDiff = true}) {
    final hasBoth = item.before != null && item.after != null;
    final diff = hasBoth ? item.after! - item.before! : 0.0;

    Color diffColor;
    IconData? diffIcon;
    if (!hasBoth) {
      diffColor = Colors.grey;
    } else if (diff.abs() < 0.05) {
      diffColor = Colors.grey;
    } else {
      final isPositive = item.smallerIsBetter ? diff < 0 : diff > 0;
      diffColor =
      isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
      diffIcon =
      diff > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade100,
          ),
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
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              item.before != null
                  ? '${item.before!.toStringAsFixed(1)}'
                  : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.after != null ? '${item.after!.toStringAsFixed(1)}' : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
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
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: diffColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==================== ДИАЛОГИ ====================

  void _showPhotoDetail(BuildContext context, bool isDark, FitnessPhoto photo,
      FitnessProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D24) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: File(photo.imageUrl).existsSync()
                    ? Image.file(File(photo.imageUrl), fit: BoxFit.contain)
                    : Container(
                  color:
                  isDark ? const Color(0xFF0F1115) : Colors.grey.shade200,
                  child: const Icon(Icons.image_rounded, size: 80),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDate(photo.date),
                    style: const TextStyle(
                      color: Color(0xFFFF6B35),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (photo.label != null)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      photo.label!,
                      style: TextStyle(
                        color:
                        isDark ? Colors.white70 : Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (photo.notes != null && photo.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  photo.notes!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ),
            if (photo.measurementsCount > 0) ...[
              const SizedBox(height: 8),
              _buildMeasurementsPreview(isDark, photo),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Изменить',
                  color: const Color(0xFFFF6B35),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditPhotoDialog(context, isDark, photo, provider);
                  },
                ),
                _buildActionButton(
                  icon: Icons.compare_rounded,
                  label: 'Сравнить',
                  color: const Color(0xFF4A9BFF),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _isCompareMode = true;
                      _selectedPhotoIndex1 = provider.photos.indexOf(photo);
                      _selectedPhotoIndex2 = null;
                    });
                  },
                ),
                _buildActionButton(
                  icon: Icons.delete_rounded,
                  label: 'Удалить',
                  color: Colors.red.shade400,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeletePhoto(context, isDark, photo, provider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsPreview(bool isDark, FitnessPhoto photo) {
    final measurements = <MapEntry<String, String>>[];
    if (photo.weight != null)
      measurements.add(
          MapEntry('⚖️ Вес', '${photo.weight!.toStringAsFixed(1)} кг'));
    if (photo.chest != null)
      measurements.add(
          MapEntry('📏 Грудь', '${photo.chest!.toStringAsFixed(1)} см'));
    if (photo.waist != null)
      measurements.add(
          MapEntry('📏 Талия', '${photo.waist!.toStringAsFixed(1)} см'));
    if (photo.hips != null)
      measurements.add(
          MapEntry('📏 Бёдра', '${photo.hips!.toStringAsFixed(1)} см'));
    if (photo.biceps != null)
      measurements.add(
          MapEntry('💪 Бицепс', '${photo.biceps!.toStringAsFixed(1)} см'));
    if (photo.thigh != null)
      measurements.add(
          MapEntry('🦵 Бедро', '${photo.thigh!.toStringAsFixed(1)} см'));
    if (photo.calf != null)
      measurements.add(
          MapEntry('🦵 Икра', '${photo.calf!.toStringAsFixed(1)} см'));
    if (photo.neck != null)
      measurements.add(
          MapEntry('📏 Шея', '${photo.neck!.toStringAsFixed(1)} см'));
    if (photo.forearm != null)
      measurements.add(MapEntry(
          '💪 Предплечье', '${photo.forearm!.toStringAsFixed(1)} см'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: measurements.map((m) {
          return Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200,
              ),
            ),
            child: Text(
              m.key + ': ' + m.value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showPhotoOptions(BuildContext context, bool isDark, FitnessPhoto photo,
      FitnessProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D24) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Color(0xFFFF6B35), size: 20),
              ),
              title: const Text('Редактировать',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showEditPhotoDialog(context, isDark, photo, provider);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9BFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.compare_rounded,
                    color: Color(0xFF4A9BFF), size: 20),
              ),
              title: const Text('Сравнить с другим',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _isCompareMode = true;
                  _selectedPhotoIndex1 = provider.photos.indexOf(photo);
                  _selectedPhotoIndex2 = null;
                });
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_rounded,
                    color: Colors.red.shade400, size: 20),
              ),
              title: Text('Удалить',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeletePhoto(context, isDark, photo, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 🔧 ИСПРАВЛЕННЫЙ ДИАЛОГ ДОБАВЛЕНИЯ ====================

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
    // 🔧 ИСПРАВЛЕНО: Открыто по умолчанию — измерения видны сразу
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
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1D24) : Colors.white,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Новое фото',
                              style: TextStyle(
                                color:
                                isDark ? Colors.white : Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Добавьте фото для отслеживания прогресса',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _showImageSourcePicker(
                      context,
                      isDark,
                          (source) async {
                        try {
                          final XFile? image = await picker.pickImage(
                            source: source,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            setDialogState(
                                    () => selectedImage = File(image.path));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ошибка: ${e.toString()}'),
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                        }
                      },
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: selectedImage == null ? 180 : 220,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F1115)
                            : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selectedImage != null
                              ? const Color(0xFFFF6B35)
                              : isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade300,
                          width: selectedImage != null ? 2 : 1.5,
                        ),
                        boxShadow: selectedImage != null
                            ? [
                          BoxShadow(
                            color:
                            const Color(0xFFFF6B35).withOpacity(0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                            : null,
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(selectedImage!,
                                fit: BoxFit.cover),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35),
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B35)
                                          .withOpacity(0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
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
                                child: Center(
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
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35)
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_a_photo_rounded,
                              color: const Color(0xFFFF6B35),
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Нажмите, чтобы выбрать фото',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Камера или галерея',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySelector(isDark, selectedCategory, (category) {
                    setDialogState(() => selectedCategory = category);
                  }),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade200,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildStyledTextField(
                          'Подпись',
                          labelController,
                          Icons.label_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildStyledTextField(
                          'Вес (кг)',
                          weightController,
                          Icons.monitor_weight_outlined,
                          isDark,
                          isNumber: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMeasurementToggle(
                    isDark,
                    showMeasurements,
                    setDialogState,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: showMeasurements
                        ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade200,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildMeasurementField(
                              'Грудь (см)',
                              chestController,
                              isDark,
                              Icons.favorite_outline,
                            ),
                            const SizedBox(height: 8),
                            _buildMeasurementField(
                              'Талия (см)',
                              waistController,
                              isDark,
                              Icons.hourglass_empty,
                            ),
                            const SizedBox(height: 8),
                            _buildMeasurementField(
                              'Бёдра (см)',
                              hipsController,
                              isDark,
                              Icons.water_drop_outlined,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMeasurementField(
                                    'Бицепс',
                                    bicepsController,
                                    isDark,
                                    Icons.fitness_center,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildMeasurementField(
                                    'Предплечье',
                                    forearmController,
                                    isDark,
                                    Icons.fitness_center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMeasurementField(
                                    'Бедро',
                                    thighController,
                                    isDark,
                                    Icons
                                        .airline_seat_legroom_extra,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildMeasurementField(
                                    'Икра',
                                    calfController,
                                    isDark,
                                    Icons
                                        .airline_seat_legroom_extra,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildMeasurementField(
                              'Шея (см)',
                              neckController,
                              isDark,
                              Icons.panorama_fish_eye,
                            ),
                          ],
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  _buildStyledTextField(
                    'Заметки',
                    notesController,
                    Icons.note_rounded,
                    isDark,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                          isLoading ? null : () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Отмена',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                            if (selectedImage == null) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.warning_rounded,
                                          color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Выберите фото'),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFFFF6B35),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            setDialogState(() => isLoading = true);

                            try {
                              String finalLabel =
                              labelController.text.trim();
                              if (selectedCategory != null &&
                                  selectedCategory!.isNotEmpty) {
                                final categoryMap = {
                                  'progress': '📈 Прогресс',
                                  'workout': '💪 Тренировка',
                                  'measurement': '📏 Замер',
                                };
                                final prefix =
                                    categoryMap[selectedCategory] ?? '';
                                if (prefix.isNotEmpty) {
                                  finalLabel = finalLabel.isNotEmpty
                                      ? '$prefix: $finalLabel'
                                      : prefix;
                                }
                              }

                              await provider.addPhoto(
                                imageUrl: selectedImage!.path,
                                label: finalLabel.isNotEmpty
                                    ? finalLabel
                                    : null,
                                weight: double.tryParse(
                                    weightController.text),
                                notes: notesController
                                    .text.isNotEmpty
                                    ? notesController.text
                                    : null,
                                chest: double.tryParse(
                                    chestController.text),
                                waist: double.tryParse(
                                    waistController.text),
                                hips: double.tryParse(
                                    hipsController.text),
                                biceps: double.tryParse(
                                    bicepsController.text),
                                thigh: double.tryParse(
                                    thighController.text),
                                calf: double.tryParse(
                                    calfController.text),
                                neck: double.tryParse(
                                    neckController.text),
                                forearm: double.tryParse(
                                    forearmController.text),
                              );

                              _scaleController.forward(from: 0.0);
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Фото добавлено! 📸'),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFFFF6B35),
                                    duration: Duration(seconds: 2),
                                    behavior:
                                    SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isLoading = false);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content:
                                  Text('Ошибка: ${e.toString()}'),
                                  backgroundColor: Colors.red.shade400,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isLoading ? 0 : 4,
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
                              : const Text(
                            'Добавить',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
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
      ),
    );
  }

  Widget _buildCategorySelector(
      bool isDark, String? selected, Function(String) onSelect) {
    final categories = [
      {
        'id': 'progress',
        'label': 'Прогресс',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF4CAF50),
        'emoji': '📈'
      },
      {
        'id': 'workout',
        'label': 'Тренировка',
        'icon': Icons.fitness_center_rounded,
        'color': const Color(0xFFFF6B35),
        'emoji': '💪'
      },
      {
        'id': 'measurement',
        'label': 'Замер',
        'icon': Icons.straighten_rounded,
        'color': const Color(0xFF4A9BFF),
        'emoji': '📏'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_rounded,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Категория',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = selected == cat['id'];
            final color = cat['color'] as Color;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onSelect(isSelected ? '' : cat['id'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color:
                  isSelected ? color.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat['emoji'] as String,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? color
                            : isDark
                            ? Colors.white54
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (selected == null || selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Выберите категорию для автоматической сортировки',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white24 : Colors.grey.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  void _showImageSourcePicker(
      BuildContext context, bool isDark, Function(ImageSource) onPick) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D24) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Выберите источник',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFFFF6B35), size: 28),
              ),
              title: const Text(
                'Камера',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              subtitle: const Text(
                'Сделать новое фото',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onPick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9BFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF4A9BFF), size: 28),
              ),
              title: const Text(
                'Галерея',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              subtitle: const Text(
                'Выбрать из сохранённых',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onPick(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField(
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
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B35), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor:
        isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white60 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildMeasurementToggle(
      bool isDark,
      bool showMeasurements,
      StateSetter setDialogState,
      ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setDialogState(() => showMeasurements = !showMeasurements);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: showMeasurements
              ? const Color(0xFFFF6B35).withOpacity(0.08)
              : isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: showMeasurements
                ? const Color(0xFFFF6B35).withOpacity(0.3)
                : isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: showMeasurements
                    ? const Color(0xFFFF6B35)
                    : isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.straighten_rounded,
                color: showMeasurements
                    ? Colors.white
                    : isDark
                    ? Colors.white38
                    : Colors.grey.shade500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Обхваты тела',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    showMeasurements ? 'Скрыть измерения' : 'Добавить измерения',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: showMeasurements ? 0.5 : 0,
              child: Icon(
                Icons.expand_more_rounded,
                color: isDark ? Colors.white54 : Colors.grey,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementField(
      String label,
      TextEditingController controller,
      bool isDark,
      IconData icon,
      ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B35), size: 18),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white60 : Colors.grey.shade600,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor:
        isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        isDense: true,
      ),
    );
  }

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
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1D24) : Colors.white,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Редактировать фото',
                              style: TextStyle(
                                color:
                                isDark ? Colors.white : Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Измените данные фото',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F1115)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: File(photo.imageUrl).existsSync()
                          ? Image.file(File(photo.imageUrl),
                          fit: BoxFit.contain)
                          : Center(
                        child: Icon(
                          Icons.image_rounded,
                          size: 48,
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade200,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildStyledTextField(
                          'Подпись',
                          labelController,
                          Icons.label_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildStyledTextField(
                          'Вес (кг)',
                          weightController,
                          Icons.monitor_weight_outlined,
                          isDark,
                          isNumber: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMeasurementToggle(
                    isDark,
                    showMeasurements,
                    setDialogState,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: showMeasurements
                        ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade200,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildMeasurementField(
                              'Грудь (см)',
                              chestController,
                              isDark,
                              Icons.favorite_outline,
                            ),
                            const SizedBox(height: 8),
                            _buildMeasurementField(
                              'Талия (см)',
                              waistController,
                              isDark,
                              Icons.hourglass_empty,
                            ),
                            const SizedBox(height: 8),
                            _buildMeasurementField(
                              'Бёдра (см)',
                              hipsController,
                              isDark,
                              Icons.water_drop_outlined,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMeasurementField(
                                    'Бицепс',
                                    bicepsController,
                                    isDark,
                                    Icons.fitness_center,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildMeasurementField(
                                    'Предплечье',
                                    forearmController,
                                    isDark,
                                    Icons.fitness_center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMeasurementField(
                                    'Бедро',
                                    thighController,
                                    isDark,
                                    Icons
                                        .airline_seat_legroom_extra,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildMeasurementField(
                                    'Икра',
                                    calfController,
                                    isDark,
                                    Icons
                                        .airline_seat_legroom_extra,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildMeasurementField(
                              'Шея (см)',
                              neckController,
                              isDark,
                              Icons.panorama_fish_eye,
                            ),
                          ],
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  _buildStyledTextField(
                    'Заметки',
                    notesController,
                    Icons.note_rounded,
                    isDark,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                          isLoading ? null : () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Отмена',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                            setDialogState(() => isLoading = true);

                            try {
                              final updated = photo.copyWith(
                                label: labelController
                                    .text.isNotEmpty
                                    ? labelController.text
                                    : null,
                                weight: double.tryParse(
                                    weightController.text),
                                notes: notesController
                                    .text.isNotEmpty
                                    ? notesController.text
                                    : null,
                                chest: double.tryParse(
                                    chestController.text),
                                waist: double.tryParse(
                                    waistController.text),
                                hips: double.tryParse(
                                    hipsController.text),
                                biceps: double.tryParse(
                                    bicepsController.text),
                                thigh: double.tryParse(
                                    thighController.text),
                                calf: double.tryParse(
                                    calfController.text),
                                neck: double.tryParse(
                                    neckController.text),
                                forearm: double.tryParse(
                                    forearmController.text),
                                clearChest:
                                chestController.text.isEmpty,
                                clearWaist:
                                waistController.text.isEmpty,
                                clearHips:
                                hipsController.text.isEmpty,
                                clearBiceps:
                                bicepsController.text.isEmpty,
                                clearThigh:
                                thighController.text.isEmpty,
                                clearCalf:
                                calfController.text.isEmpty,
                                clearNeck:
                                neckController.text.isEmpty,
                                clearForearm:
                                forearmController.text.isEmpty,
                              );
                              await provider.updatePhoto(updated);
                              _scaleController.forward(from: 0.0);
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Фото обновлено! ✨'),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFFFF6B35),
                                    duration: Duration(seconds: 2),
                                    behavior:
                                    SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isLoading = false);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content:
                                  Text('Ошибка: ${e.toString()}'),
                                  backgroundColor: Colors.red.shade400,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isLoading ? 0 : 4,
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
                              : const Text(
                            'Сохранить',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
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
      ),
    );
  }

  void _confirmDeletePhoto(BuildContext context, bool isDark,
      FitnessPhoto photo, FitnessProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1A1D24) : Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
            const SizedBox(width: 8),
            const Text('Удалить фото?',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('Фото будет удалено безвозвратно'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deletePhoto(photo.id);
              try {
                final file = File(photo.imageUrl);
                if (file.existsSync()) await file.delete();
              } catch (_) {}
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Удалить',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
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

// ==================== ВСПОМОГАТЕЛЬНЫЕ КЛАССЫ ====================

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
  bool shouldReclip(_HalfClipper oldClipper) => oldClipper.position != position;
}