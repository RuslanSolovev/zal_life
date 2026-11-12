// features/nutrition/ui/widgets/product_knowledge_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/nutrition_models.dart' show FoodProduct;
import '../../models/wellness_models.dart';
import '../../providers/nutrition_provider.dart';
import 'season_visuals.dart';

class _P {
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF7C818A);
  static const divider = Color(0xFFE9EBEF);
  static const bg = Color(0xFFF6F7F9);
  static const peachDeep = Color(0xFFEF9563);
  static const peachSoft = Color(0xFFFBEDE4);
  static const greenDeep = Color(0xFF6C9E88);
  static const greenSoft = Color(0xFFE7F2ED);
  static const yellowDeep = Color(0xFFE0B054);
  static const yellowSoft = Color(0xFFFDF5E6);
  static const pinkDeep = Color(0xFFD17A8F);
}

void showProductKnowledgeSheet(
    BuildContext context, {
      required ProductKnowledge knowledge,
      FoodProduct? product,
      NutritionProvider? nutrition,
    }) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      height: MediaQuery.of(ctx).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36, height: 5,
              decoration: BoxDecoration(
                color: _P.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      children: [
                        Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(
                            color: _P.peachSoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Text(knowledge.emoji,
                              style: const TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(knowledge.displayName,
                                  style: GoogleFonts.inter(
                                    color: _P.text, fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                  )),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 4, runSpacing: 4,
                                children: [
                                  if (knowledge.isInSeason(DateTime.now()))
                                    _badge('🌱 В сезоне', _P.greenDeep, _P.greenSoft),
                                  if (product != null)
                                    _badge('${product.calories.round()} ккал/100 г',
                                        _P.peachDeep, _P.peachSoft),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Сезонная полоса ──
                    if (knowledge.seasonMonths.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: _P.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded,
                                    size: 12, color: _P.textMuted),
                                const SizedBox(width: 5),
                                Text(
                                  'В СЕЗОНЕ',
                                  style: GoogleFonts.inter(
                                    color: _P.textMuted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  knowledge.seasonMonths
                                      .map((m) => kMonthShort[m])
                                      .join(' · '),
                                  style: GoogleFonts.inter(
                                    color: _P.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SeasonMonthsBar(
                              months: knowledge.seasonMonths,
                              currentMonth: DateTime.now().month,
                              accent: metaForMonth(DateTime.now().month).accent,
                              height: 6,
                              showLabels: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Богат ──
                    if (knowledge.richIn.isNotEmpty) ...[
                      _sectionTitle('ЧЕМ БОГАТ'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: knowledge.richIn.map((n) {
                          final meta = kNutrientMetas[n]!;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: meta.color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: meta.color.withOpacity(0.20)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(meta.emoji,
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(meta.name,
                                    style: TextStyle(
                                      color: meta.color, fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Полезен ──
                    if (knowledge.benefits.isNotEmpty) ...[
                      _sectionTitle('ПОЛЕЗЕН ДЛЯ'),
                      const SizedBox(height: 10),
                      ...knowledge.benefits.map((b) {
                        final meta = kBenefitMetas[b]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: meta.color.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: meta.color.withOpacity(0.18)),
                            ),
                            child: Row(
                              children: [
                                Text(meta.emoji,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(meta.name,
                                          style: GoogleFonts.inter(
                                            color: meta.color, fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          )),
                                      const SizedBox(height: 1),
                                      Text(meta.tagline,
                                          style: GoogleFonts.inter(
                                            color: _P.textMuted, fontSize: 11,
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    // ── Осторожно ──
                    if (knowledge.contraindications.isNotEmpty) ...[
                      _sectionTitle('ОСТОРОЖНО'),
                      const SizedBox(height: 10),
                      ...knowledge.contraindications.map((c) {
                        final color = switch (c.severity) {
                          ContraSeverity.warning => _P.pinkDeep,
                          ContraSeverity.caution => _P.yellowDeep,
                          ContraSeverity.info => const Color(0xFF7E9DC6),
                        };
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: color.withOpacity(0.20)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 16, color: color),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(c.title,
                                          style: GoogleFonts.inter(
                                            color: color, fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          )),
                                      const SizedBox(height: 2),
                                      Text(c.message,
                                          style: GoogleFonts.inter(
                                            color: _P.text, fontSize: 12,
                                            height: 1.35,
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    // ── Fact ──
                    if (knowledge.funFact != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _P.peachSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(knowledge.funFact!,
                                  style: GoogleFonts.inter(
                                    color: _P.text, fontSize: 12,
                                    height: 1.4,
                                  )),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    Text(
                      'Информация носит справочный характер и не заменяет '
                          'консультацию врача.',
                      style: GoogleFonts.inter(
                        color: _P.textMuted, fontSize: 10, height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _sectionTitle(String text) => Text(
  text,
  style: GoogleFonts.inter(
    color: _P.textMuted, fontSize: 10,
    fontWeight: FontWeight.w700, letterSpacing: 1.2,
  ),
);

Widget _badge(String text, Color fg, Color bg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: bg, borderRadius: BorderRadius.circular(6),
  ),
  child: Text(text,
      style: TextStyle(
        color: fg, fontSize: 10, fontWeight: FontWeight.w600,
      )),
);