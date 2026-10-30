// features/fitness/ui/widgets/set_input_widget.dart
import 'package:flutter/material.dart';

class SetInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final bool isDark;
  final TextInputType keyboardType;

  const SetInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    this.isDark = false,
    this.keyboardType = TextInputType.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
          suffixText: suffix,
          suffixStyle: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFFFF6B35)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}