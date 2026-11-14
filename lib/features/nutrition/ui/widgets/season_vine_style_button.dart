// lib/features/nutrition/ui/widgets/season_vine_style_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'season_vine_style_picker.dart';

class SeasonVineStyleButton extends StatelessWidget {
  final double scale;
  final Color color;

  const SeasonVineStyleButton({
    super.key,
    required this.scale,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        SeasonVineStylePicker.show(context);
      },
      child: Container(
        width: scale * 28,
        height: scale * 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.10),
          border: Border.all(
            color: color.withOpacity(0.28),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.palette_outlined,
          color: color,
          size: scale * 14,
        ),
      ),
    );
  }
}