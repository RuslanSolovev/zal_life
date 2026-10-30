import 'package:flutter/material.dart';

class JourneyView extends StatefulWidget {
  final double walkedKm;
  final int totalSteps;
  final VoidCallback onBack;

  const JourneyView({
    super.key,
    required this.walkedKm,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  State<JourneyView> createState() => _JourneyViewState();
}

class _JourneyViewState extends State<JourneyView>
    with SingleTickerProviderStateMixin {
  static const double _totalDistance = 9300;

  late final List<City> _cities = _getCities();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int get _reachedCitiesCount =>
      _cities.where((city) => city.distanceFromMoscow <= widget.walkedKm).length;

  int get _remainingCitiesCount =>
      _cities.length - _reachedCitiesCount;

  double get _progressPercent =>
      (widget.walkedKm / _totalDistance).clamp(0.0, 1.0);

  City get _currentCity => _cities.lastWhere(
        (city) => city.distanceFromMoscow <= widget.walkedKm,
    orElse: () => _cities.first,
  );

  bool get _isDarkMode =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor =>
      _isDarkMode ? const Color(0xFF080B10) : const Color(0xFFF5F6F8);

  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF11161E) : Colors.white;

  Color get _surfaceColor2 =>
      _isDarkMode ? const Color(0xFF171D26) : const Color(0xFFF9FAFB);

  Color get _surfaceColor3 =>
      _isDarkMode ? const Color(0xFF1B222C) : const Color(0xFFF1F3F5);

  Color get _textColor =>
      _isDarkMode ? const Color(0xFFF5F7FA) : const Color(0xFF161A20);

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFF98A1AE) : const Color(0xFF737B86);

  Color get _mutedTextColor =>
      _isDarkMode ? const Color(0xFF66707D) : const Color(0xFFA0A7AF);

  Color get _borderColor =>
      _isDarkMode ? Colors.white.withOpacity(0.055) : Colors.black.withOpacity(0.055);

  Color get _dividerColor =>
      _isDarkMode ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);

  Color get _accent => const Color(0xFFFF7548);

  Color get _accentLight => const Color(0xFFFF9775);

  Color get _accentDark => const Color(0xFFE95C32);

  Color get _green => const Color(0xFF31C48D);

  Color get _blue => const Color(0xFF4B8DFF);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.985,
      end: 1.015,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = _cities.indexOf(_currentCity) + 1;

    final nextCity =
    nextIndex < _cities.length ? _cities[nextIndex] : null;

    final progressToNext = nextCity == null
        ? 1.0
        : ((widget.walkedKm - _currentCity.distanceFromMoscow) /
        (nextCity.distanceFromMoscow -
            _currentCity.distanceFromMoscow))
        .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 14),
          _buildQuickStats(),
          const SizedBox(height: 20),
          _buildCurrentCityCard(_currentCity),
          if (nextCity != null) ...[
            const SizedBox(height: 14),
            _buildNextCityCard(nextCity, progressToNext),
          ],
          const SizedBox(height: 24),
          _buildSectionHeader(),
          const SizedBox(height: 10),
          _buildTimeline(),
          const SizedBox(height: 24),
          _buildQuote(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leadingWidth: 62,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, top: 7, bottom: 7),
        child: Material(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: widget.onBack,
            borderRadius: BorderRadius.circular(15),
            child: Icon(
              Icons.arrow_back_rounded,
              color: _textColor,
              size: 21,
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Путешествие',
            style: TextStyle(
              color: _textColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'Москва → Владивосток',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final percent = _progressPercent * 100;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _accent.withOpacity(_isDarkMode ? 0.16 : 0.08),
                  _surfaceColor,
                  _surfaceColor2,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _accent.withOpacity(0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(
                    _isDarkMode ? 0.10 : 0.06,
                  ),
                  blurRadius: 30,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ТРАНССИБИРСКИЙ МАРШРУТ',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Твой путь до\nВладивостока',
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 27,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 108,
                      height: 108,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 108,
                            height: 108,
                            child: CircularProgressIndicator(
                              value: _progressPercent,
                              strokeWidth: 9,
                              backgroundColor: _isDarkMode
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.055),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _accent,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                percent.toStringAsFixed(1),
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '%',
                                style: TextStyle(
                                  color: _secondaryTextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progressPercent,
                    minHeight: 8,
                    backgroundColor: _isDarkMode
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.055),
                    valueColor: AlwaysStoppedAnimation<Color>(_accent),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildHeroMetric(
                        icon: Icons.directions_walk_rounded,
                        value: '${widget.totalSteps}',
                        label: 'шагов',
                      ),
                    ),
                    _buildMetricDivider(),
                    Expanded(
                      child: _buildHeroMetric(
                        icon: Icons.route_rounded,
                        value: widget.walkedKm.toStringAsFixed(1),
                        label: 'км пройдено',
                      ),
                    ),
                    _buildMetricDivider(),
                    Expanded(
                      child: _buildHeroMetric(
                        icon: Icons.flag_rounded,
                        value: '${(_totalDistance - widget.walkedKm).clamp(0, _totalDistance).toStringAsFixed(0)}',
                        label: 'км осталось',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: _accent,
          size: 18,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: _textColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 36,
      color: _dividerColor,
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            icon: Icons.location_city_rounded,
            value: '$_reachedCitiesCount',
            label: 'городов пройдено',
            color: _green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickStatCard(
            icon: Icons.explore_rounded,
            value: '$_remainingCitiesCount',
            label: 'городов впереди',
            color: _blue,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(_isDarkMode ? 0.12 : 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentCityCard(City city) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _accent.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(
              _isDarkMode ? 0.06 : 0.035,
            ),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accent,
                      _accentDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(
                          _isDarkMode ? 0.12 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ВЫ ЗДЕСЬ',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      city.name,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${city.distanceFromMoscow} км от Москвы',
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (city.isMajor)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _buildFactCard(
            icon: Icons.history_rounded,
            title: 'История',
            text: city.fact,
          ),
          const SizedBox(height: 8),
          _buildFactCard(
            icon: Icons.lightbulb_rounded,
            title: 'Факт',
            text: city.funFact1,
          ),
          const SizedBox(height: 8),
          _buildFactCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Интересно',
            text: city.funFact2,
          ),
          if (city.cuisine.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildCuisineCard(city.cuisine),
          ],
        ],
      ),
    );
  }

  Widget _buildFactCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surfaceColor2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _accent.withOpacity(
                _isDarkMode ? 0.10 : 0.07,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: _accent,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: _accent,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuisineCard(String cuisine) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                '🍽️',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Местная кухня  ',
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: cuisine,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
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

  Widget _buildNextCityCard(
      City city,
      double progress,
      ) {
    final remaining =
    (city.distanceFromMoscow - widget.walkedKm).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _blue.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(
                    _isDarkMode ? 0.11 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'СЛЕДУЮЩАЯ ОСТАНОВКА',
                  style: TextStyle(
                    color: _blue,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _blue.withOpacity(
                    _isDarkMode ? 0.11 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.navigation_rounded,
                  color: _blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.name,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$remaining км осталось',
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (city.isMajor)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _isDarkMode
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(_blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _accent.withOpacity(
              _isDarkMode ? 0.11 : 0.08,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.timeline_rounded,
            color: _accent,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ПОЛНЫЙ МАРШРУТ',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Все остановки Транссиба',
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Text(
            '$_reachedCitiesCount/${_cities.length}',
            style: TextStyle(
              color: _accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: _cities.asMap().entries.map((entry) {
        final index = entry.key;
        final city = entry.value;

        final isReached =
            city.distanceFromMoscow <= widget.walkedKm;

        final isCurrent = city == _currentCity;

        final isLast = index == _cities.length - 1;

        return InkWell(
          onTap: () => _showCityInfo(city),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 42,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        width: isCurrent
                            ? 30
                            : city.isMajor
                            ? 21
                            : 15,
                        height: isCurrent
                            ? 30
                            : city.isMajor
                            ? 21
                            : 15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isReached
                              ? _accent
                              : (_isDarkMode
                              ? const Color(0xFF27303B)
                              : const Color(0xFFE0E4E8)),
                          border: isCurrent
                              ? Border.all(
                            color: _surfaceColor,
                            width: 3,
                          )
                              : null,
                          boxShadow: isCurrent
                              ? [
                            BoxShadow(
                              color: _accent.withOpacity(0.35),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ]
                              : null,
                        ),
                        child: isCurrent
                            ? const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 15,
                        )
                            : isReached && city.isMajor
                            ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 12,
                        )
                            : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 48,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isReached
                                ? _accent.withOpacity(0.28)
                                : (_isDarkMode
                                ? const Color(0xFF252D37)
                                : const Color(0xFFE0E3E7)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? _accent.withOpacity(
                        _isDarkMode ? 0.08 : 0.05,
                      )
                          : _surfaceColor,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: isCurrent
                            ? _accent.withOpacity(0.16)
                            : _borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      city.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isReached
                                            ? _accent
                                            : _textColor,
                                        fontSize:
                                        city.isMajor ? 13.5 : 12,
                                        fontWeight: isCurrent ||
                                            city.isMajor
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 7),
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _accent.withOpacity(
                                          0.12,
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ТУТ',
                                        style: TextStyle(
                                          color: _accent,
                                          fontSize: 7,
                                          fontWeight:
                                          FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (city.isMajor) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${city.population} • ${city.founded}',
                                  style: TextStyle(
                                    color: _secondaryTextColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${city.distanceFromMoscow} км',
                          style: TextStyle(
                            color: isReached
                                ? _accent.withOpacity(0.8)
                                : _mutedTextColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: _mutedTextColor,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCityInfo(City city) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _mutedTextColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _accent,
                              _accentDark,
                            ],
                          ),
                          borderRadius:
                          BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.location_city_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              city.name,
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 24,
                                fontWeight:
                                FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${city.distanceFromMoscow} км от Москвы',
                              style: TextStyle(
                                color: _secondaryTextColor,
                                fontSize: 10.5,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (city.isMajor)
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.amber
                                .withOpacity(0.12),
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildModalSection(
                    'ОСНОВНАЯ ИНФОРМАЦИЯ',
                    [
                      '👥 Население: ${city.population}',
                      '🗺️ Площадь: ${city.area}',
                      '📅 Основан: ${city.founded}',
                    ],
                  ),
                  const SizedBox(height: 9),
                  _buildModalSection(
                    'ИСТОРИЧЕСКАЯ СПРАВКА',
                    [city.fact],
                  ),
                  const SizedBox(height: 9),
                  _buildModalSection(
                    'ИНТЕРЕСНЫЕ ФАКТЫ',
                    [
                      city.funFact1,
                      city.funFact2,
                      city.funFact3,
                      city.funFact4,
                    ],
                  ),
                  if (city.cuisine.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    _buildModalSection(
                      'МЕСТНАЯ КУХНЯ',
                      [city.cuisine],
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accent,
                            _accentDark,
                          ],
                        ),
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx),
                        child: const Text(
                          'Закрыть',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalSection(
      String title,
      List<String> lines,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surfaceColor2,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          ...lines.where((line) => line.trim().isNotEmpty).map(
                (line) {
              return Padding(
                padding:
                const EdgeInsets.only(bottom: 5),
                child: Text(
                  line,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuote() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        10,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accent.withOpacity(
                _isDarkMode ? 0.11 : 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote_rounded,
              color: _accent,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Дорога в тысячу миль\nначинается с одного шага',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textColor,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '— Лао-Цзы',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  static List<City> _getCities() {
    return [
      City(
        'Москва',
        0,
        '12,7 млн',
        '2 561 км²',
        '1147 г.',
        '🏛️ Сердце России. Москва — политический, экономический и культурный центр страны.',
        'Кремль — самая большая средневековая крепость в Европе, её стены протянулись на 2,2 км.',
        'В Москве 17 действующих вокзалов и 5 аэропортов, а также самое большое метро в Европе.',
        'Красная площадь — главная площадь страны, здесь находятся Храм Василия Блаженного и Мавзолей.',
        'Московский Кремль — резиденция президента РФ и объект Всемирного наследия ЮНЕСКО.',
        'Блины, пельмени, борщ',
        true,
      ),
      City(
        'Балашиха',
        22,
        '520 тыс.',
        '97 км²',
        '1830 г.',
        '🏭 Балашиха — крупнейший город-спутник Москвы, важный промышленный центр.',
        'В городе находится знаменитая усадьба Пехра-Яковлевское — образец русского классицизма.',
        'Балашихинский литейно-механический завод — одно из старейших предприятий региона.',
        'В Балашихе расположен крупнейший в Европе производственный комплекс Coca-Cola.',
        'Город активно застраивается новыми жилыми комплексами и парковыми зонами.',
        '',
        false,
      ),
      City(
        'Щёлково',
        30,
        '130 тыс.',
        '37 км²',
        '1925 г.',
        '🏭 Щёлково — текстильная столица региона, здесь работали крупнейшие мануфактуры XIX века.',
        'В городе находится Щёлковский историко-краеведческий музей с богатой коллекцией.',
        'Щёлковский район известен своими санаториями и домами отдыха на берегу Клязьмы.',
        'Здесь расположен аэродром Чкаловский — база военно-транспортной авиации России.',
        'В окрестностях города находится Медвежьи Озёра — популярное место отдыха москвичей.',
        '',
        false,
      ),
      City(
        'Фрязино',
        35,
        '60 тыс.',
        '9 км²',
        '1951 г.',
        '🔬 Фрязино — один из первых наукоградов России, центр радиоэлектроники и СВЧ-технологий.',
        'Здесь расположены ведущие НИИ в области электроники и космической связи.',
        'В городе находится музей радиоэлектроники «Фрязино-наукоград».',
        'Фрязино — один из самых благоустроенных и компактных городов Подмосковья.',
        'В парке «Фрязино» проводятся ежегодные фестивали науки и техники.',
        '',
        false,
      ),
      City(
        'Сергиев Посад',
        75,
        '100 тыс.',
        '50 км²',
        '1345 г.',
        '🏛️ Сергиев Посад — духовная столица России, центр православного паломничества.',
        'Троице-Сергиева Лавра — крупнейший мужской монастырь страны, объект ЮНЕСКО.',
        'В городе находится знаменитая Сергиево-Посадская игрушка — народный промысел.',
        'Здесь работал известный художник Михаил Нестеров, создавший цикл картин о св. Сергии.',
        'В городе проходят ежегодные ярмарки народных промыслов и фестивали колокольного звона.',
        'Сергиевские пряники',
        false,
      ),
      City(
        'Орехово-Зуево',
        95,
        '118 тыс.',
        '47 км²',
        '1917 г.',
        '🧵 Орехово-Зуево — родина Морозовской текстильной мануфактуры.',
        'В городе находится Саввино-Сторожевский монастырь.',
        'Здесь родился и жил знаменитый поэт Николай Заболоцкий.',
        'В Орехово-Зуеве расположен уникальный мост через Клязьму.',
        'Город известен своими традициями футбола — здесь базируется клуб «Знамя Труда».',
        '',
        false,
      ),
      City(
        'Владимир',
        180,
        '350 тыс.',
        '308 км²',
        '990 г.',
        '🏰 Владимир — жемчужина Золотого кольца, древняя столица Северо-Восточной Руси.',
        'Золотые ворота, Успенский и Дмитриевский соборы — объекты Всемирного наследия ЮНЕСКО.',
        'В городе находится знаменитый Владимирский централ.',
        'Здесь работали великие князья Андрей Боголюбский и Всеволод Большое Гнездо.',
        'Владимир славится своей вишнёвой настойкой и вишнёвыми садами.',
        'Владимирская вишня',
        false,
      ),
      City(
        'Муром',
        300,
        '110 тыс.',
        '44 км²',
        '862 г.',
        '🏰 Муром — родина былинного богатыря Ильи Муромца.',
        'Спасо-Преображенский монастырь — древнейший монастырь России.',
        'В городе находится уникальный памятник калачу.',
        'Муром — родина изобретателя телевидения Владимира Зворыкина.',
        'Каждое лето в Муроме проходит фестиваль «Муромское лето».',
        'Муромские калачи',
        false,
      ),
      City(
        'Нижний Новгород',
        400,
        '1,2 млн',
        '460 км²',
        '1221 г.',
        '🌅 Нижний Новгород — столица закатов, здесь находится самая длинная лестница в России.',
        'Нижегородский кремль — неприступная крепость.',
        'Город — родина изобретателя радио Александра Попова.',
        'Здесь находится знаменитая Нижегородская ярмарка.',
        'В городе расположен уникальный музей техники «ГАЗ».',
        'Нижегородский пряник',
        true,
      ),
      City(
        'Кстово',
        440,
        '66 тыс.',
        '18 км²',
        '1957 г.',
        '🛢️ Кстово — центр нефтепереработки.',
        'Озеро Святое — место паломничества.',
        'В окрестностях города расположен Щёлковский хутор.',
        'Кстово — город-спутник Нижнего Новгорода.',
        'Здесь находится уникальный храм.',
        '',
        false,
      ),
      City(
        'Шумерля',
        630,
        '30 тыс.',
        '13 км²',
        '1916 г.',
        '🚂 Шумерля — железнодорожный город.',
        'Шумерля знаменита своими валенками.',
        'В городе есть железнодорожный техникум.',
        'Шумерлинский завод специализируется на оборудовании для железных дорог.',
        'В окрестностях города находится заказник.',
        '',
        false,
      ),
      City(
        'Чебоксары',
        640,
        '497 тыс.',
        '233 км²',
        '1469 г.',
        '🌉 Чебоксары — жемчужина на Волге.',
        '46-метровая статуя Мать-покровительница.',
        'Чебоксарский залив — любимое место отдыха.',
        'Здесь находится один из крупнейших тракторных заводов.',
        'Чебоксары — родина космонавта Андрияна Николаева.',
        'Чебоксарский хмель',
        false,
      ),
      City(
        'Казань',
        800,
        '1,3 млн',
        '425 км²',
        '1005 г.',
        '🕌 Казань — третья столица России.',
        'Казанский Кремль — объект ЮНЕСКО.',
        'В городе находится большой европейский цирк.',
        'Казань — родина Фёдора Шаляпина.',
        'Казанский университет — один из старейших в России.',
        'Эчпочмак, чак-чак',
        true,
      ),
      City(
        'Набережные Челны',
        1020,
        '545 тыс.',
        '171 км²',
        '1626 г.',
        '🚚 Набережные Челны — город грузовиков КАМАЗ.',
        'КАМАЗ — крупнейшее автомобильное предприятие города.',
        'В городе работает музей истории КАМАЗа.',
        'Набережные Челны — один из самых молодых крупных городов.',
        'В городе расположен парк «Прибрежный».',
        '',
        false,
      ),
      City(
        'Пермь',
        1380,
        '1,0 млн',
        '799 км²',
        '1723 г.',
        '🎭 Пермь — культурная столица Урала.',
        'Пермская деревянная скульптура — уникальное явление.',
        'В городе есть памятник букве «Ё».',
        'Пермь — важный промышленный и культурный центр Урала.',
        'Пермский период назван в честь города.',
        'Пермские пельмени',
        false,
      ),
      City(
        'Екатеринбург',
        1800,
        '1,5 млн',
        '1 111 км²',
        '1723 г.',
        '⛰️ Екатеринбург — столица Урала.',
        'Здесь находится памятник границе Европы и Азии.',
        'В городе крупнейший музей за Уралом.',
        'Екатеринбург — родина Бориса Ельцина.',
        'Единственный в мире памятник клавиатуре.',
        'Уральские пельмени',
        true,
      ),
      City(
        'Тюмень',
        2100,
        '830 тыс.',
        '698 км²',
        '1586 г.',
        '🛢️ Тюмень — нефтяная столица России.',
        'Самый длинный мост города — Мост Влюблённых.',
        'В городе есть уникальные памятники городской истории.',
        'Тюменский драмтеатр — один из старейших.',
        'Город славится термальными источниками.',
        '',
        true,
      ),
      City(
        'Ишим',
        2420,
        '67 тыс.',
        '46 км²',
        '1687 г.',
        '📖 Ишим — родина автора «Конька-Горбунка».',
        'Памятник Коньку-Горбунку — один из символов города.',
        'Ишимский музей — один из заметных региональных музеев.',
        'Город стоит на Транссибирской магистрали.',
        'В Ишиме родился Михаил Пришвин.',
        '',
        false,
      ),
      City(
        'Омск',
        2700,
        '1,1 млн',
        '572 км²',
        '1716 г.',
        '🏰 Омск — врата Сибири.',
        'Омский драмтеатр — один из старейших.',
        'Крупный университетский и промышленный центр Сибири.',
        'Город расположен на Иртыше.',
        'Омск — родина актёра Михаила Ульянова.',
        '',
        true,
      ),
      City(
        'Барабинск',
        3050,
        '30 тыс.',
        '44 км²',
        '1893 г.',
        '🚂 Барабинск — крупный узел на Транссибе.',
        'Город связан с развитием железнодорожного сообщения Сибири.',
        'В городе установлен памятник железнодорожному прошлому.',
        'Барабинская степь — характерный природный ландшафт.',
        'Город играет важную роль как транспортный узел.',
        '',
        false,
      ),
      City(
        'Новосибирск',
        3400,
        '1,6 млн',
        '502 км²',
        '1893 г.',
        '🎭 Новосибирск — крупнейший город Сибири.',
        'Мост через Обь стал важнейшим объектом города.',
        'Академгородок — известный научный центр.',
        'Новосибирск стоит на реке Обь.',
        'Новосибирский зоопарк — один из самых известных в России.',
        '',
        true,
      ),
      City(
        'Томск',
        3570,
        '576 тыс.',
        '294 км²',
        '1604 г.',
        '🎓 Томск — старейший университетский город Сибири.',
        'Более 100 памятников деревянного зодчества.',
        'Томск — крупный научно-образовательный центр.',
        'Город известен своими университетскими традициями.',
        'Томские учёные работают в самых разных научных областях.',
        '',
        false,
      ),
      City(
        'Кемерово',
        3700,
        '557 тыс.',
        '282 км²',
        '1918 г.',
        '⛏️ Кемерово — столица Кузбасса.',
        'Город расположен на берегах реки Томь.',
        'Кузбасский ботанический сад.',
        'Регион известен своей угольной промышленностью.',
        'Кемерово — важный промышленный центр Сибири.',
        '',
        false,
      ),
      City(
        'Красноярск',
        4100,
        '1,1 млн',
        '348 км²',
        '1628 г.',
        '🌉 Красноярск — город на Енисее.',
        'Город известен своими мостами через Енисей.',
        'Красноярские Столбы — национальный парк.',
        'Красноярская ГЭС — один из крупнейших гидроэнергетических объектов России.',
        'Город окружён живописными сибирскими ландшафтами.',
        '',
        true,
      ),
      City(
        'Тайшет',
        4510,
        '34 тыс.',
        '40 км²',
        '1897 г.',
        '🚂 Тайшет — важный железнодорожный узел.',
        'Станция Тайшет связана с Транссибирской магистралью.',
        'Город имеет большое транспортное значение.',
        'В районе развиты лесная и деревообрабатывающая отрасли.',
        'Тайшет расположен в Иркутской области.',
        '',
        false,
      ),
      City(
        'Иркутск',
        5100,
        '617 тыс.',
        '277 км²',
        '1661 г.',
        '💎 Иркутск — ворота Байкала.',
        'Более 500 памятников архитектуры.',
        'Знаменский монастырь.',
        'Город известен сибирским барокко.',
        'Иркутское водохранилище расположено рядом с городом.',
        'Байкальский омуль',
        true,
      ),
      City(
        'Улан-Удэ',
        5600,
        '435 тыс.',
        '347 км²',
        '1666 г.',
        '🗿 Улан-Удэ — один из крупнейших культурных центров Бурятии.',
        'В городе находится знаменитый памятник Ленину.',
        'Город расположен в долине рек Уды и Селенги.',
        'Улан-Удэ связан с историей Транссиба.',
        'Этнографический музей народов Забайкалья расположен неподалёку.',
        'Позы (буузы)',
        true,
      ),
      City(
        'Чита',
        6200,
        '350 тыс.',
        '538 км²',
        '1653 г.',
        '⛰️ Чита — крупный город Забайкалья.',
        'Город связан с историей декабристов.',
        'В Чите расположен буддийский дацан.',
        'В окрестностях есть природные минеральные источники.',
        'Чита — важный транспортный центр региона.',
        '',
        true,
      ),
      City(
        'Нерчинск',
        6600,
        '15 тыс.',
        '24 км²',
        '1653 г.',
        '🏰 Нерчинск — один из старейших городов Забайкалья.',
        'Город связан с историей освоения Сибири.',
        'Здесь находится краеведческий музей.',
        'Нерчинск известен своей историей рудников.',
        'Через регион проходили важные исторические торговые пути.',
        '',
        false,
      ),
      City(
        'Свободный',
        7680,
        '54 тыс.',
        '58 км²',
        '1912 г.',
        '🚀 Свободный — город рядом с космодромом «Восточный».',
        'Город ранее назывался Алексеевском.',
        'Здесь есть драматический театр.',
        'Регион известен сельским хозяйством.',
        'В области развиты лесная и золотодобывающая отрасли.',
        '',
        false,
      ),
      City(
        'Белогорск',
        7950,
        '65 тыс.',
        '39 км²',
        '1860 г.',
        '🛩️ Белогорск — крупный транспортный и промышленный центр Амурской области.',
        'Город расположен на Транссибирской магистрали.',
        'Белогорск имеет большое значение для железнодорожного сообщения.',
        'Вокруг города расположены сельскохозяйственные территории.',
        'Регион связан с историей освоения Дальнего Востока.',
        '',
        false,
      ),
      City(
        'Хабаровск',
        8500,
        '617 тыс.',
        '386 км²',
        '1858 г.',
        '🐅 Хабаровск — столица Дальнего Востока.',
        'Символ региона — амурский тигр.',
        'Амурский мост — известный объект Транссиба.',
        'Город расположен на берегу Амура.',
        'Хабаровск — важный культурный и транспортный центр Дальнего Востока.',
        '',
        true,
      ),
      City(
        'Уссурийск',
        9140,
        '173 тыс.',
        '173 км²',
        '1866 г.',
        '🌸 Уссурийск — город рядом с уникальной природой Приморья.',
        'Заповедник «Кедровая Падь» расположен в регионе.',
        'Уссурийская тайга отличается необычным биоразнообразием.',
        'Город сохранил архитектуру начала XX века.',
        'Регион известен природными и сельскохозяйственными ресурсами.',
        '',
        false,
      ),
      City(
        'Владивосток',
        9300,
        '605 тыс.',
        '331 км²',
        '1860 г.',
        '🌊 Владивосток — конечная точка Транссибирской магистрали.',
        'Русский мост — один из символов города.',
        'Золотой мост перекинут через бухту Золотой Рог.',
        'В городе расположен штаб Тихоокеанского флота.',
        'Владивосток — крупнейший порт Дальнего Востока.',
        'Морепродукты, крабы',
        true,
      ),
    ];
  }
}

class City {
  final String name;
  final int distanceFromMoscow;
  final String population;
  final String area;
  final String founded;
  final String fact;
  final String funFact1;
  final String funFact2;
  final String funFact3;
  final String funFact4;
  final String cuisine;
  final bool isMajor;

  const City(
      this.name,
      this.distanceFromMoscow,
      this.population,
      this.area,
      this.founded,
      this.fact,
      this.funFact1,
      this.funFact2,
      this.funFact3,
      this.funFact4,
      this.cuisine,
      this.isMajor,
      );
}
