import 'package:flutter/material.dart';

class AppStyles {
  // Modern minimal colors - inspired by the design
  static const Color primaryColor = Color(0xFF2D3748); // Dark gray-blue
  static const Color accentColor = Color(0xFF4FD1C7); // Teal accent
  static const Color backgroundColor = Color(0xFFF7FAFC); // Very light gray
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
  static const Color cardBackground = Color(0xFFFFFFFF); // White cards
  
  // Soft colors for cards
  static const Color lightGreen = Color(0xFFE6FFFA); // Light teal
  static const Color lightBlue = Color(0xFFEBF8FF); // Light blue
  static const Color lightGray = Color(0xFFEDF2F7); // Light gray
  
  // Glass morphism colors - softer approach
  static const Color glassBackground = Color(0x15FFFFFF); // Very subtle
  static const Color glassBorder = Color(0x10000000); // Minimal border
  static const Color glassShadow = Color(0x05000000); // Very soft shadow
  
  // Modern gradient colors - subtle
  static final LinearGradient primaryGradient = LinearGradient(
    colors: [
      const Color(0xFF4FD1C7),
      const Color(0xFF81E6D9),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static final LinearGradient cardGradient = LinearGradient(
    colors: [
      const Color(0xFFFFFFFF),
      const Color(0xFFF7FAFC),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text colors - Modern minimal
  static const Color textPrimary = Color(0xFF2D3748); // Dark gray
  static const Color textSecondary = Color(0xFF718096); // Medium gray
  static const Color textTertiary = Color(0xFFA0AEC0); // Light gray
  static const Color textLight = Color(0xFFE2E8F0); // Very light gray

  // Status colors - Soft modern palette
  static const Color successColor = Color(0xFF38A169);
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color warningColor = Color(0xFFDD6B20);
  static const Color infoColor = Color(0xFF3182CE);

  // Modern card styles - more rounded, softer
  static const double cardRadius = 24.0; // More rounded
  static const double smallRadius = 16.0;
  static const double largeRadius = 32.0;
  static const double cardElevation = 0.0; // Flat design
  static const double softElevation = 2.0; // Very subtle elevation

  // Typography - Modern clean fonts
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800, // Extra bold for headings
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.2,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    letterSpacing: 0.1,
    height: 1.2,
  );

  // Modern card decoration - clean and minimal
  static BoxDecoration modernCardDecoration({
    double borderRadius = 24.0,
    Color? backgroundColor,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: withShadow ? [
        BoxShadow(
          color: glassShadow,
          blurRadius: 20,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ] : null,
    );
  }

  // Soft button decoration
  static BoxDecoration modernButtonDecoration({
    double borderRadius = 16.0,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      gradient: backgroundColor != null 
          ? LinearGradient(colors: [backgroundColor, backgroundColor])
          : primaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  // Minimal glass decoration - very subtle
  static BoxDecoration glassDecoration({
    Color? color,
    double borderRadius = 24.0,
    bool withBorder = false, // Default to no border for cleaner look
  }) {
    return BoxDecoration(
      color: color ?? cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: withBorder
          ? Border.all(
              color: glassBorder,
              width: 0.5,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: glassShadow,
          blurRadius: 20.0,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Modern button decoration - clean primary button style
  static BoxDecoration primaryButtonDecoration({
    double borderRadius = 16.0,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      gradient: backgroundColor != null 
          ? LinearGradient(colors: [backgroundColor, backgroundColor])
          : primaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
