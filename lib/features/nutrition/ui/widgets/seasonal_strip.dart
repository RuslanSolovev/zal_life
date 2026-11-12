// features/nutrition/ui/widgets/seasonal_strip.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_models.dart' show FoodProduct;
import '../../models/wellness_models.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/wellness_provider.dart';
import '../screens/knowledge_screen.dart';
import 'product_knowledge_sheet.dart';

class _P {
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF7C818A);
  static const divider = Color(0xFFE9EBEF);
  static const greenSoft = Color(0xFFE7F2ED);
  static const greenDeep = Color(0xFF6C9E88);
  static const peachDeep = Color(0xFFEF9563);
}

const _months = [
  '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];

/// Горизонтальная лента сезонных продуктов. Используется в Fuel Dashboard
/// и в Add Food.
class SeasonalStrip extends StatelessWidget {
  final EdgeInsets padding;
  final VoidCallback? onViewAll;
  const SeasonalStrip({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final wellness = context.watch<WellnessProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final seasonal = wellness.seasonalNow.take(8).toList();
    if (seasonal.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text('В сезоне · ${_months[wellness.currentMonth]}',
                  style: GoogleFonts.inter(
                    color: _P.text, fontSize: 17,
                    fontWeight: FontWeight.w600, letterSpacing: -0.4,
                  )),
              const Spacer(),
              if (onViewAll != null)
                _Press(
                  onTap: onViewAll!,
                  child: Row(children: [
                    Text('Знания', style: GoogleFonts.inter(
                      color: _P.textMuted, fontSize: 12,
                    )),
                    const Icon(Icons.chevron_right_rounded,
                        color: _P.textMuted, size: 14),
                  ]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: padding,
            itemCount: seasonal.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final k = seasonal[i];
              final product = _findProduct(nutrition, k);
              return _Press(
                onTap: () => showProductKnowledgeSheet(
                  context,
                  product: product,
                  knowledge: k,
                  nutrition: nutrition,
                ),
                child: Container(
                  width: 108,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _P.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _P.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _P.greenSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(k.emoji,
                            style: const TextStyle(fontSize: 18)),
                      ),
                      const Spacer(),
                      Text(k.displayName,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _P.text, fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.25, letterSpacing: -0.1,
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  FoodProduct? _findProduct(NutritionProvider nutrition, dynamic k) {
    for (final p in nutrition.products) {
      if (p.id == k.key) return p;
      final norm = p.name.toLowerCase().replaceAll('ё', 'е').replaceAll(' ', '_');
      if (norm.contains(k.key) || k.key.contains(norm)) return p;
    }
    return null;
  }
}

/// Хаб в конце Fuel Dashboard: Продукт дня + Сезон + Кнопка в Knowledge.
class WellnessHub extends StatelessWidget {
  const WellnessHub({super.key});

  @override
  Widget build(BuildContext context) {
    final wellness = context.watch<WellnessProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final daily = wellness.productOfDay;
    if (daily == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text('Здоровье и сезон',
                  style: GoogleFonts.inter(
                    color: _P.text, fontSize: 19,
                    fontWeight: FontWeight.w600, letterSpacing: -0.5,
                  )),
              const Spacer(),
              _Press(
                onTap: () => _openKnowledge(context, 0),
                child: Row(children: [
                  Text('Все знания', style: GoogleFonts.inter(
                    color: _P.textMuted, fontSize: 12,
                  )),
                  const Icon(Icons.chevron_right_rounded,
                      color: _P.textMuted, size: 14),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Press(
            onTap: () => showProductKnowledgeSheet(
              context,
              product: _findProduct(nutrition, daily),
              knowledge: daily,
              nutrition: nutrition,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1B2027), Color(0xFF161719)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _P.peachDeep.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text('ПРОДУКТ ДНЯ',
                                style: GoogleFonts.inter(
                                  color: _P.peachDeep, fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                )),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_outward_rounded,
                          color: Colors.white54, size: 16),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(daily.emoji,
                            style: const TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(daily.displayName,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.4,
                                )),
                            const SizedBox(height: 3),
                            Text(
                              daily.benefits.isEmpty
                                  ? 'Сезонный продукт'
                                  : daily.benefits
                                  .take(2)
                                  .map((b) => kBenefitMetas[b]!.name)
                                  .join(' · '),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (daily.richIn.isNotEmpty)
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: daily.richIn.take(3).map((n) {
                        final meta = kNutrientMetas[n]!;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: meta.color.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${meta.emoji} ${meta.name}',
                              style: TextStyle(
                                color: meta.color, fontSize: 10,
                                fontWeight: FontWeight.w600,
                              )),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openKnowledge(BuildContext context, int tab) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<WellnessProvider>(),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
                value: context.read<NutritionProvider>()),
          ],
          child: KnowledgeScreen(initialTab: tab),
        ),
      ),
    ));
  }

  FoodProduct? _findProduct(NutritionProvider nutrition, dynamic k) {
    for (final p in nutrition.products) {
      if (p.id == k.key) return p;
      final norm = p.name.toLowerCase().replaceAll('ё', 'е').replaceAll(' ', '_');
      if (norm.contains(k.key) || k.key.contains(norm)) return p;
    }
    return null;
  }
}

class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Press({required this.child, required this.onTap});
  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}