import 'package:flutter/material.dart';

class LanguageBadge extends StatelessWidget {
  const LanguageBadge({super.key, required this.language});

  static const List<Color> _colors = <Color>[
    Color(0xFF2155CD),
    Color(0xFF167D68),
    Color(0xFF8A4FBF),
    Color(0xFFB05B1E),
    Color(0xFFB43B55),
    Color(0xFF426A8C),
  ];

  final String language;

  @override
  Widget build(BuildContext context) {
    final color = _colors[language.hashCode.abs() % _colors.length];
    return Chip(
      label: Text(language),
      labelStyle: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
