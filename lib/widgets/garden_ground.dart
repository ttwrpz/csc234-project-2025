import 'package:flutter/material.dart';

class GardenBackground extends StatelessWidget {
  final bool isDarkMode;

  const GardenBackground({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.25, 0.5, 0.7, 0.85, 1.0],
          colors: isDarkMode ? _darkColors : _lightColors,
        ),
      ),
    );
  }

  static const _lightColors = [
    Color(0xFFD6E8F8), // Soft sky blue
    Color(0xFFE8F0F8), // Lighter sky
    Color(0xFFE0EFE0), // Sky-ground transition
    Color(0xFFD4E8C4), // Light meadow
    Color(0xFFB8D9A0), // Mid green
    Color(0xFF94C47A), // Rich ground
  ];

  static const _darkColors = [
    Color(0xFF0D1B2A), // Dark night sky
    Color(0xFF1B2838), // Deep blue
    Color(0xFF1A2E1A), // Dark sky-ground transition
    Color(0xFF1E3A1E), // Dark meadow
    Color(0xFF2A4A2A), // Dark mid green
    Color(0xFF1E3318), // Dark ground
  ];
}

class GardenSoil extends StatelessWidget {
  final bool isDarkMode;

  const GardenSoil({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    const Color(0xFF2A4A2A).withValues(alpha: 0.0),
                    const Color(0xFF1A3318),
                  ]
                : [
                    const Color(0xFF94C47A).withValues(alpha: 0.0),
                    const Color(0xFF7AA35C),
                  ],
          ),
        ),
      ),
    );
  }
}
