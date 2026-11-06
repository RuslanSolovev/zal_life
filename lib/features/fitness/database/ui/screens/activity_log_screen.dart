// features/fitness/database/ui/screens/activity_log_screen.dart
import 'package:flutter/material.dart';

import 'package:zal_life/features/fitness/providers/pedometer_provider.dart'
    show StepDay, Achievement;

// ═══════════════════════════════════════════════════════════════════
//  Soft Pastel — Design System (shared with pedometer_screen)
// ═══════════════════════════════════════════════════════════════════
class _P {
  static const peachDeep = Color(0xFFE57154);
  static const pinkDeep = Color(0xFFD95C84);
  static const mintDeep = Color(0xFF398B95);
  static const lavenderDeep = Color(0xFF8A5DA5);
  static const yellowDeep = Color(0xFFD39838);
  static const skyDeep = Color(0xFF3E7A9C);
  static const sageDeep = Color(0xFF5C7E5E);

  static const peachSoft = Color(0xFFFFE9E1);
  static const pinkSoft = Color(0xFFFFE5EF);
  static const mintSoft = Color(0xFFE3F3F4);
  static const lavenderSoft = Color(0xFFF1E8F5);
  static const yellowSoft = Color(0xFFFFF2E2);
  static const skySoft = Color(0xFFE3F1F7);
  static const sageSoft = Color(0xFFE8F1E6);

  static const bg = Color(0xFFFAF7F2);
  static const elevated = Color(0xFFF3EEE6);
  static const text = Color(0xFF2B2823);
  static const textMuted = Color(0xFF8A8278);
  static const textSoft = Color(0xFFBFB7AB);
  static const divider = Color(0xFFEAE4DA);
}

class _T {
  static const title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );
  static const title3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
  );
  static const headline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05,
    height: 1.3,
  );
  static const caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.3,
  );
  static const overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
    height: 1.1,
  );
}

// ═══════════════════════════════════════════════════════════════════

class ActivityLogScreen extends StatefulWidget {
  final List<StepDay> history;
  final List<Achievement> achievements;
  final int goal;
  final int currentStreak;
  final int level;
  final int achievementPoints;
  final double levelProgress;
  final double heightCm;
  final double weightKg;
  final Color accentColor;
  final int initialTab;

  const ActivityLogScreen({
    super.key,
    required this.history,
    required this.achievements,
    required this.goal,
    this.currentStreak = 0,
    this.level = 1,
    this.achievementPoints = 0,
    this.levelProgress = 0,
    this.heightCm = 175,
    this.weightKg = 70,
    this.accentColor = const Color(0xFFE57154),
    this.initialTab = 0,
  });

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final i = widget.initialTab;
    final idx = i < 0 ? 0 : (i > 2 ? 2 : i);
    _tabController = TabController(length: 3, vsync: this, initialIndex: idx);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Helpers ───
  Color get _accent => widget.accentColor;
  Color get _accentDark =>
      Color.lerp(_accent, Colors.black, 0.08) ?? _accent;

  double _km(int steps) => steps * widget.heightCm * 0.415 / 100000;
  double _kcal(int steps) => steps * widget.weightKg * 0.0005;

  List<StepDay> get _sortedHistory {
    final list = List<StepDay>.from(widget.history);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  int get _totalSteps => widget.history.fold<int>(0, (s, d) => s + d.steps);
  double get _totalKm => _km(_totalSteps);
  double get _totalKcal => _kcal(_totalSteps);
  int get _activeDays => widget.history.where((d) => d.steps > 0).length;

  StepDay? get _bestDay {
    if (widget.history.isEmpty) return null;
    StepDay? best;
    for (final d in widget.history) {
      if (d.steps > 0 && (best == null || d.steps > best.steps)) best = d;
    }
    return best;
  }

  int get _longestStreak {
    final list = List<StepDay>.from(widget.history)
      ..sort((a, b) => a.date.compareTo(b.date));
    int best = 0, cur = 0;
    for (final d in list) {
      if (d.steps >= widget.goal) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 0;
      }
    }
    return best;
  }

  int get _bestWeek {
    final list = List<StepDay>.from(widget.history)
      ..sort((a, b) => a.date.compareTo(b.date));
    if (list.isEmpty) return 0;
    if (list.length <= 7) {
      return list.fold<int>(0, (s, d) => s + d.steps);
    }
    int best = 0;
    for (int i = 0; i + 7 <= list.length; i++) {
      int sum = 0;
      for (int j = i; j < i + 7; j++) sum += list[j].steps;
      if (sum > best) best = sum;
    }
    return best;
  }

  int get _averagePerActiveDay =>
      _activeDays > 0 ? (_totalSteps / _activeDays).round() : 0;

  // ─── Achievement grouping ───
  List<Achievement> get _dailyAch => widget.achievements
      .where((a) =>
  !a.id.startsWith('streak_') &&
      !a.id.startsWith('dist_') &&
      a.id != 'marathon' &&
      !a.id.startsWith('steps_') &&
      !a.id.startsWith('cal_'))
      .toList();

  List<Achievement> get _streakAch => widget.achievements
      .where((a) => a.id.startsWith('streak_'))
      .toList();

  List<Achievement> get _distanceAch => widget.achievements
      .where((a) => a.id.startsWith('dist_') || a.id == 'marathon')
      .toList();

  List<Achievement> get _totalAch => widget.achievements
      .where((a) =>
  a.id.startsWith('steps_') || a.id.startsWith('cal_'))
      .toList();

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _appBar(),
            _tabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryTab(),
                  _buildAchievementsTab(),
                  _buildRecordsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _circleBtn(
            Icons.arrow_back_ios_new_rounded,
                () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Журнал', style: _T.title2.copyWith(color: _P.text)),
                const SizedBox(height: 2),
                Text(
                  'История · Достижения · Рекорды',
                  style: _T.caption2.copyWith(
                    color: _P.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _P.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: _P.text, size: 17),
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: -3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: LinearGradient(colors: [_accent, _accentDark]),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _P.textMuted,
        labelStyle: _T.caption2.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: _T.caption2.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        tabs: const [
          Tab(height: 40, text: 'История'),
          Tab(height: 40, text: 'Награды'),
          Tab(height: 40, text: 'Рекорды'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 1 — HISTORY
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHistoryTab() {
    final sorted = _sortedHistory;
    if (sorted.isEmpty) {
      return _emptyState(
        icon: Icons.directions_walk_rounded,
        title: 'История пуста',
        subtitle: 'Начните ходить — дни появятся здесь',
      );
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _historySummary(),
        const SizedBox(height: 14),
        ...sorted.map(_dayCard),
      ],
    );
  }

  Widget _historySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent.withOpacity(0.10), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accent.withOpacity(0.14), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              Icons.directions_walk_rounded,
              _fmtSteps(_totalSteps),
              'шагов',
              _P.skyDeep,
            ),
          ),
          Container(width: 1, height: 40, color: _P.divider),
          Expanded(
            child: _summaryItem(
              Icons.route_rounded,
              _totalKm.toStringAsFixed(1),
              'км',
              _P.sageDeep,
            ),
          ),
          Container(width: 1, height: 40, color: _P.divider),
          Expanded(
            child: _summaryItem(
              Icons.calendar_today_rounded,
              '$_activeDays',
              'дней',
              _accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _T.title3.copyWith(
            color: _P.text,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: _T.caption2.copyWith(
            color: _P.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _dayCard(StepDay day) {
    final isToday = _isToday(day.date);
    final goalReached = day.steps >= widget.goal;
    final progress = widget.goal > 0
        ? (day.steps / widget.goal).clamp(0.0, 1.0)
        : 0.0;
    final km = _km(day.steps);
    final kcal = _kcal(day.steps);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isToday ? _accent.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isToday ? _accent.withOpacity(0.18) : _P.divider,
            width: 1,
          ),
          boxShadow: isToday
              ? [
            BoxShadow(
              color: _accent.withOpacity(0.08),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            _dateTile(day.date, isToday),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _fmtSteps(day.steps),
                        style: _T.headline.copyWith(
                          color: _P.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'шагов',
                        style: _T.caption2.copyWith(
                          color: _P.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (goalReached) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _P.sageDeep.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: _P.sageDeep,
                            size: 10,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'СЕГОДНЯ',
                            style: _T.caption2.copyWith(
                              color: _accent,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${km.toStringAsFixed(2)} км · ${kcal.round()} ккал',
                    style: _T.caption2.copyWith(
                      color: _P.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: _P.divider,
                      valueColor: AlwaysStoppedAnimation(
                        goalReached ? _P.sageDeep : _accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(DateTime date, bool isToday) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isToday ? _accent.withOpacity(0.10) : _P.elevated,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekdayShort(date),
            style: _T.caption2.copyWith(
              color: isToday ? _accent : _P.textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${date.day}',
            style: _T.title3.copyWith(
              color: isToday ? _accent : _P.text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _monthShort(date.month),
            style: _T.caption2.copyWith(
              color: _P.textMuted,
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 2 — ACHIEVEMENTS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAchievementsTab() {
    final unlocked = widget.achievements.where((a) => a.unlocked).length;
    final total = widget.achievements.length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _achievementsSummary(unlocked, total),
        const SizedBox(height: 18),
        if (_dailyAch.isNotEmpty) ...[
          _categoryLabel('ДНЕВНЫЕ', Icons.today_rounded),
          const SizedBox(height: 10),
          ..._dailyAch.map(_achievementCard),
          const SizedBox(height: 18),
        ],
        if (_streakAch.isNotEmpty) ...[
          _categoryLabel('СЕРИИ', Icons.repeat_rounded),
          const SizedBox(height: 10),
          ..._streakAch.map(_achievementCard),
          const SizedBox(height: 18),
        ],
        if (_distanceAch.isNotEmpty) ...[
          _categoryLabel('ДИСТАНЦИЯ', Icons.route_rounded),
          const SizedBox(height: 10),
          ..._distanceAch.map(_achievementCard),
          const SizedBox(height: 18),
        ],
        if (_totalAch.isNotEmpty) ...[
          _categoryLabel('ВСЕГО', Icons.trending_up_rounded),
          const SizedBox(height: 10),
          ..._totalAch.map(_achievementCard),
        ],
      ],
    );
  }

  Widget _achievementsSummary(int unlocked, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.28),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            alignment: Alignment.center,
            child: Text(
              '${widget.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'УРОВЕНЬ ${widget.level}',
                  style: _T.overline.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 9,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$unlocked из $total открыто',
                  style: _T.headline.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.levelProgress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white.withOpacity(0.22),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Text(
              '${widget.achievementPoints} AP',
              style: _T.caption2.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 16),
        const SizedBox(width: 7),
        Text(
          text,
          style: _T.overline.copyWith(
            color: _accent,
            fontSize: 10,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _achievementCard(Achievement a) {
    final unlocked = a.unlocked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: unlocked ? _P.yellowSoft.withOpacity(0.55) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
            unlocked ? _P.yellowDeep.withOpacity(0.22) : _P.divider,
            width: 1,
          ),
          boxShadow: unlocked
              ? [
            BoxShadow(
              color: _P.yellowDeep.withOpacity(0.10),
              blurRadius: 12,
              spreadRadius: -4,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: unlocked
                    ? _P.yellowDeep.withOpacity(0.10)
                    : _P.elevated,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Opacity(
                opacity: unlocked ? 1.0 : 0.35,
                child: Text(
                  a.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: _T.caption.copyWith(
                      color: unlocked ? _P.text : _P.textMuted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    a.description,
                    style: _T.caption2.copyWith(
                      color: unlocked ? _P.textMuted : _P.textSoft,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (unlocked)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _P.sageDeep.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: _P.sageDeep,
                  size: 17,
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _P.elevated,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: _P.textSoft,
                  size: 15,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 3 — RECORDS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRecordsTab() {
    if (_totalSteps == 0) {
      return _emptyState(
        icon: Icons.stars_rounded,
        title: 'Рекордов пока нет',
        subtitle: 'Первые достижения появятся\nпосле прогулок',
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _recordsHero(),
        const SizedBox(height: 14),
        if (_bestDay != null)
          _recordCard(
            title: 'Лучший день',
            value: '${_fmtSteps(_bestDay!.steps)} шагов',
            subtitle:
            '${_fmtDate(_bestDay!.date)} · ${_km(_bestDay!.steps).toStringAsFixed(1)} км',
            icon: Icons.emoji_events_rounded,
            color: _P.yellowDeep,
            isTop: true,
          ),
        if (_longestStreak > 0)
          _recordCard(
            title: 'Самая длинная серия',
            value: '$_longestStreak ${_daysWord(_longestStreak)}',
            subtitle: 'Подряд с целью ${_fmtSteps(widget.goal)}',
            icon: Icons.local_fire_department_rounded,
            color: _P.pinkDeep,
          ),
        if (widget.currentStreak > 0)
          _recordCard(
            title: 'Текущая серия',
            value:
            '${widget.currentStreak} ${_daysWord(widget.currentStreak)}',
            subtitle: 'Прямо сейчас',
            icon: Icons.bolt_rounded,
            color: _accent,
          ),
        if (_bestWeek > 0)
          _recordCard(
            title: 'Лучшая неделя',
            value: '${_fmtSteps(_bestWeek)} шагов',
            subtitle: '${_km(_bestWeek).toStringAsFixed(1)} км за 7 дней',
            icon: Icons.date_range_rounded,
            color: _P.lavenderDeep,
          ),
        _recordCard(
          title: 'Всего пройдено',
          value: '${_fmtSteps(_totalSteps)} шагов',
          subtitle:
          '${_totalKm.toStringAsFixed(1)} км · ${_totalKcal.round()} ккал',
          icon: Icons.stars_rounded,
          color: _P.skyDeep,
        ),
        _recordCard(
          title: 'Средний день',
          value: '${_fmtSteps(_averagePerActiveDay)} шагов',
          subtitle: 'Среди $_activeDays ${_daysWord(_activeDays)} активности',
          icon: Icons.analytics_rounded,
          color: _P.sageDeep,
        ),
        _recordCard(
          title: 'Активных дней',
          value: '$_activeDays',
          subtitle: 'С хотя бы одним шагом',
          icon: Icons.calendar_month_rounded,
          color: _P.mintDeep,
        ),
      ],
    );
  }

  Widget _recordsHero() {
    final best = _bestDay;
    if (best == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _P.yellowDeep.withOpacity(0.18),
            _P.yellowSoft,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _P.yellowDeep.withOpacity(0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _P.yellowDeep.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_P.yellowDeep, const Color(0xFFE8B246)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ЛИЧНЫЙ РЕКОРД',
                      style: _T.overline.copyWith(
                        color: _P.yellowDeep,
                        fontSize: 9,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _fmtDate(best.date),
                      style: _T.caption2.copyWith(
                        color: _P.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtSteps(best.steps),
                style: _T.title2.copyWith(
                  color: _P.text,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'шагов',
                  style: _T.caption.copyWith(
                    color: _P.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_km(best.steps).toStringAsFixed(2)} км · ${_kcal(best.steps).round()} ккал',
            style: _T.caption2.copyWith(
              color: _P.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isTop = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: isTop ? _P.yellowDeep.withOpacity(0.25) : _P.divider,
            width: 1,
          ),
          boxShadow: isTop
              ? [
            BoxShadow(
              color: _P.yellowDeep.withOpacity(0.12),
              blurRadius: 14,
              spreadRadius: -4,
              offset: const Offset(0, 5),
            ),
          ]
              : [
            BoxShadow(
              color: color.withOpacity(0.03),
              blurRadius: 8,
              spreadRadius: -3,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: _T.caption.copyWith(
                            color: _P.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isTop) ...[
                        const SizedBox(width: 4),
                        const Text('👑', style: TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: _T.headline.copyWith(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _T.caption2.copyWith(
                      color: _P.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════════════════════════
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _P.divider, width: 1),
              ),
              child: Icon(icon, size: 38, color: _P.textSoft),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _T.title3.copyWith(
                color: _P.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: _T.caption.copyWith(
                color: _P.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════
  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _weekdayShort(DateTime d) {
    const wd = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    return wd[d.weekday - 1];
  }

  String _monthShort(int m) {
    const mn = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return mn[m - 1];
  }

  String _monthFull(int m) {
    const mn = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return mn[m - 1];
  }

  String _fmtDate(DateTime d) => '${d.day} ${_monthFull(d.month)}';

  String _daysWord(int n) {
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'дней';
    final mod10 = n % 10;
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }

  String _fmtSteps(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 100000) return '${(n / 1000).toStringAsFixed(0)}K';
    if (n < 1000) return '$n';
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}