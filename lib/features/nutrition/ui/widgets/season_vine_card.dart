// lib/features/nutrition/ui/widgets/season_vine_card.dart
import 'package:flutter/material.dart';

import '../../providers/nutrition_provider.dart';
import '../../providers/wellness_provider.dart';
import 'season_vine_aurora.dart';
import 'season_vine_botanica.dart';
import 'season_vine_circuit.dart';
import 'season_vine_clock.dart';
import 'season_vine_conveyor.dart';
import 'season_vine_flipboard.dart';
import 'season_vine_hourglass.dart';
import 'season_vine_kintsugi.dart';
import 'season_vine_lighthouse.dart';
import 'season_vine_metro.dart';
import 'season_vine_postage.dart';
import 'season_vine_style.dart';

/// Публичный API — идентичен прежнему `SeasonVineCard`.
/// Внутри — делегирует одной из 11 реализаций по текущему стилю.
class SeasonVineCard extends StatelessWidget {
  final WellnessProvider wellness;
  final NutritionProvider nutrition;
  final double scale;
  final VoidCallback onOpenKnowledge;

  const SeasonVineCard({
    super.key,
    required this.wellness,
    required this.nutrition,
    required this.scale,
    required this.onOpenKnowledge,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SeasonVineStyle>(
      valueListenable: SeasonVineStyleController.current,
      builder: (context, style, _) {
        switch (style) {
          case SeasonVineStyle.postage:
            return SeasonVineCardPostage(
              wellness: wellness,
              nutrition: nutrition,
              scale: scale,
              onOpenKnowledge: onOpenKnowledge,
            );
          case SeasonVineStyle.botanica:
            return SeasonVineCardBotanica(
              wellness: wellness,
              nutrition: nutrition,
              scale: scale,
              onOpenKnowledge: onOpenKnowledge,
            );
          case SeasonVineStyle.aurora:
            return SeasonVineCardAurora(
              wellness: wellness,
              nutrition: nutrition,
              scale: scale,
              onOpenKnowledge: onOpenKnowledge,
            );
          case SeasonVineStyle.flipboard:
            return SeasonVineCardFlipboard(
              wellness: wellness,
              nutrition: nutrition,
              scale: scale,
              onOpenKnowledge: onOpenKnowledge,
            );
          case SeasonVineStyle.metro:
            return SeasonVineCardMetro(
              wellness: wellness,
              nutrition: nutrition,
              scale: scale,
              onOpenKnowledge: onOpenKnowledge,
            );
          case SeasonVineStyle.kintsugi:
            return SeasonVineCardKintsugi(
              wellness: wellness,
              nutrition: nutrition,
              scale: scale,
              onOpenKnowledge: onOpenKnowledge,
            );
          case SeasonVineStyle.hourglass:
            return SeasonVineCardHourglass(
              wellness: wellness,
              nutrition: nutrition,
              scale: scale,
              onOpenKnowledge: onOpenKnowledge,
            );
          case SeasonVineStyle.circuit:
            return SeasonVineCardCircuit(
              wellness: wellness,
              nutrition: nutrition,
              scale: scale,
              onOpenKnowledge: onOpenKnowledge,
            );
          case SeasonVineStyle.conveyor:
            return SeasonVineCardConveyor(
              wellness: wellness,
              nutrition: nutrition,
              scale: scale,
              onOpenKnowledge: onOpenKnowledge,
            );
          case SeasonVineStyle.clock:
            return SeasonVineCardClock(
              wellness: wellness,
              nutrition: nutrition,
              scale: scale,
              onOpenKnowledge: onOpenKnowledge,
            );
          case SeasonVineStyle.lighthouse:
            return SeasonVineCardLighthouse(
              wellness: wellness,
              nutrition: nutrition,
              scale: scale,
              onOpenKnowledge: onOpenKnowledge,
            );
        }
      },
    );
  }
}