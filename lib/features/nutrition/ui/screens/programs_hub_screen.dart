// features/nutrition/ui/screens/programs_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_program.dart';
import '../../providers/nutrition_provider.dart';
import 'plan_builder_screen.dart';
import 'plan_tracker_screen.dart';

class _P {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Colors.white;
  static const text = Color(0xFF1C2026);
  static const muted = Color(0xFF7C818A);
  static const divider = Color(0xFFE9EBEF);

  // Акцентные цвета
  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF5A8A73);
  static const pinkSoft = Color(0xFFFCF0F2);
  static const pinkDeep = Color(0xFFC16A7F);
  static const skySoft = Color(0xFFE8EFF8);
  static const skyDeep = Color(0xFF6A8AB5);
  static const amberSoft = Color(0xFFFDF5E6);
  static const amberDeep = Color(0xFFD0A040);
}

class ProgramsHubScreen extends StatefulWidget {
  const ProgramsHubScreen({super.key});

  @override
  State<ProgramsHubScreen> createState() => _ProgramsHubScreenState();
}

class _ProgramsHubScreenState extends State<ProgramsHubScreen> {
  int _selectedIndex = 0; // 0 = Активные, 1 = История

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final activePrograms = provider.programs.where((p) => p.isActive).toList();
    final historyPrograms = provider.programs.where((p) => !p.isActive).toList();

    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _P.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Программы', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: _P.text)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: _P.greenDeep, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanBuilderScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 🆕 Премиальный сегментированный переключатель
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _P.divider),
              ),
              child: Stack(
                children: [
                  // Анимированный фон выбранной вкладки
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: _selectedIndex == 0 ? 4 : (MediaQuery.of(context).size.width / 2) - 20,
                    top: 4,
                    bottom: 4,
                    child: Container(
                      width: (MediaQuery.of(context).size.width / 2) - 24,
                      decoration: BoxDecoration(
                        color: _P.greenDeep,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: _P.greenDeep.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedIndex = 0),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _selectedIndex == 0 ? Colors.white : _P.muted,
                              ),
                              child: Text('Активные (${activePrograms.length})'),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedIndex = 1),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _selectedIndex == 1 ? Colors.white : _P.muted,
                              ),
                              child: Text('История (${historyPrograms.length})'),
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
          const SizedBox(height: 12),
          // Контент с анимацией переключения
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedIndex == 0
                  ? _buildList(activePrograms, provider, isActiveTab: true, key: const ValueKey('active'))
                  : _buildList(historyPrograms, provider, isActiveTab: false, key: const ValueKey('history')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<NutritionProgram> programs, NutritionProvider provider, {required bool isActiveTab, required Key key}) {
    if (programs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: isActiveTab ? _P.greenSoft : _P.skySoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(isActiveTab ? '📭' : '📜', style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 20),
            Text(
              isActiveTab ? 'Нет активных программ' : 'История пуста',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _P.text),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                isActiveTab ? 'Создайте свой первый план питания, чтобы начать отслеживать прогресс' : 'Здесь будут отображаться завершенные или отмененные программы',
                style: GoogleFonts.inter(fontSize: 14, color: _P.muted, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
            if (isActiveTab) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanBuilderScreen())),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Создать программу'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _P.greenDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: programs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) {
        final p = programs[i];
        final totalDays = p.endDate.difference(p.startDate).inDays + 1;
        final daysPassed = DateTime.now().difference(p.startDate).inDays + 1;
        final progress = (daysPassed / totalDays).clamp(0.0, 1.0);
        final isFinished = DateTime.now().isAfter(p.endDate);

        return _ProgramCard(
          program: p,
          provider: provider,
          isActiveTab: isActiveTab,
          totalDays: totalDays,
          progress: progress,
          isFinished: isFinished,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PREMIUM PROGRAM CARD
// ═══════════════════════════════════════════════════════════════════
class _ProgramCard extends StatelessWidget {
  final NutritionProgram program;
  final NutritionProvider provider;
  final bool isActiveTab;
  final int totalDays;
  final double progress;
  final bool isFinished;

  const _ProgramCard({
    required this.program, required this.provider, required this.isActiveTab,
    required this.totalDays, required this.progress, required this.isFinished,
  });

  String _fmtDate(DateTime d) {
    const m = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${d.day} ${m[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = program.isActive;

    return Container(
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isActive ? _P.greenDeep.withOpacity(0.2) : _P.divider, width: isActive ? 1.5 : 1),
        boxShadow: isActive
            ? [BoxShadow(color: _P.greenDeep.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))]
            : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Верхняя часть карточки с градиентом для активных
          if (isActive)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_P.greenDeep.withOpacity(0.06), Colors.transparent],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
              ),
              child: _Header(isActive: true, program: program),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: _Header(isActive: false, program: program, isFinished: isFinished),
            ),

          const Divider(height: 1, color: _P.divider),

          // Прогресс и даты
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmtDate(program.startDate), style: GoogleFonts.inter(fontSize: 12, color: _P.muted, fontWeight: FontWeight.w500)),
                    Text(_fmtDate(program.endDate), style: GoogleFonts.inter(fontSize: 12, color: _P.muted, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: isActive ? progress : 1.0,
                    minHeight: 6,
                    backgroundColor: _P.divider,
                    valueColor: AlwaysStoppedAnimation(isActive ? _P.greenDeep : _P.skyDeep),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isActive ? 'День ${progress.clamp(0.0, 1.0) * totalDays ~/ 1} из $totalDays' : 'Всего $totalDays дней',
                  style: GoogleFonts.inter(fontSize: 12, color: _P.muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: _P.divider),

          // Кнопки действий
          Padding(
            padding: const EdgeInsets.all(16),
            child: isActiveTab
                ? Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanTrackerScreen())),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Открыть'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _P.greenDeep,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _ActionMenu(program: program, provider: provider),
              ],
            )
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmAction(context, 'Возобновить?', 'Эта программа станет активной, а текущая (если есть) будет приостановлена.', () => provider.startProgram(program.id)),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Возобновить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _P.surface,
                  foregroundColor: _P.greenDeep,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _P.greenDeep, width: 1.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAction(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _P.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(message, style: GoogleFonts.inter(color: _P.muted, height: 1.4)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена', style: TextStyle(color: _P.muted, fontWeight: FontWeight.w600))),
          FilledButton(
            onPressed: () { Navigator.pop(ctx); onConfirm(); HapticFeedback.mediumImpact(); },
            style: FilledButton.styleFrom(backgroundColor: _P.pinkDeep, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Text('Подтвердить', style: TextStyle(fontWeight: FontWeight.w600))),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CARD HEADER WIDGET
// ═══════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final bool isActive;
  final NutritionProgram program;
  final bool isFinished;

  const _Header({required this.isActive, required this.program, this.isFinished = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _P.greenSoft, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: _P.greenDeep, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('АКТИВНА', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _P.greenDeep, letterSpacing: 0.8)),
                    ],
                  ),
                )
              else if (isFinished)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _P.skySoft, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 12, color: _P.skyDeep),
                      const SizedBox(width: 4),
                      const Text('ЗАВЕРШЕНА', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _P.skyDeep, letterSpacing: 0.8)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _P.pinkSoft, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel_rounded, size: 12, color: _P.pinkDeep),
                      const SizedBox(width: 4),
                      const Text('ОТМЕНЕНА', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _P.pinkDeep, letterSpacing: 0.8)),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Text(program.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _P.text, height: 1.2)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, size: 14, color: _P.amberDeep),
                  const SizedBox(width: 4),
                  Text('${program.targetCalories.round()} ккал/день', style: GoogleFonts.inter(fontSize: 13, color: _P.muted, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  Icon(Icons.restaurant_rounded, size: 14, color: _P.greenDeep),
                  const SizedBox(width: 4),
                  Text(program.mode == ProgramMode.byMeals ? 'По слотам' : 'Свободный', style: GoogleFonts.inter(fontSize: 13, color: _P.muted, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ACTION MENU (DROPDOWN)
// ═══════════════════════════════════════════════════════════════════
class _ActionMenu extends StatelessWidget {
  final NutritionProgram program;
  final NutritionProvider provider;

  const _ActionMenu({required this.program, required this.provider});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _P.bg, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.more_horiz_rounded, color: _P.muted, size: 22),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'finish',
          child: Row(children: [const Icon(Icons.flag_rounded, color: _P.greenDeep, size: 20), const SizedBox(width: 12), const Text('Завершить', style: TextStyle(fontWeight: FontWeight.w600))]),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'cancel',
          child: Row(children: [const Icon(Icons.close_rounded, color: _P.pinkDeep, size: 20), const SizedBox(width: 12), const Text('Отменить', style: TextStyle(fontWeight: FontWeight.w600, color: _P.pinkDeep))]),
        ),
      ],
      onSelected: (value) {
        if (value == 'finish') {
          _confirmAction(context, 'Завершить программу?', 'Поздравляем! Программа будет перемещена в историю как успешная.', () => provider.finishProgram(program.id));
        } else if (value == 'cancel') {
          _confirmAction(context, 'Отменить программу?', 'Программа будет деактивирована и перемещена в историю.', () => provider.cancelProgram(program.id));
        }
      },
    );
  }

  void _confirmAction(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(message, style: GoogleFonts.inter(color: const Color(0xFF7C818A), height: 1.4)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена', style: TextStyle(color: Color(0xFF7C818A), fontWeight: FontWeight.w600))),
          FilledButton(
            onPressed: () { Navigator.pop(ctx); onConfirm(); HapticFeedback.mediumImpact(); },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC16A7F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Text('Подтвердить', style: TextStyle(fontWeight: FontWeight.w600))),
          ),
        ],
      ),
    );
  }
}