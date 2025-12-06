import 'package:flutter/material.dart';

/// Color palette matching the web app (qrcode-raffle-web)
/// Uses OKLCH-equivalent colors converted to hex for Flutter
class AppColors {
  AppColors._();

  // ============================================================================
  // PRIMARY COLORS (Purple/Violet)
  // ============================================================================

  // Light mode primary: oklch(0.5338 0.2503 301.3750) ≈ #8B5CF6
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF7C3AED);

  // Dark mode primary: oklch(0.7833 0.1078 326.5445) ≈ #F472B6 (pink, swapped)
  static const Color primaryOnDark = Color(0xFFF472B6);

  // ============================================================================
  // SECONDARY COLORS (Pink)
  // ============================================================================

  // Light mode secondary: oklch(0.7833 0.1078 326.5445) ≈ #EC4899
  static const Color secondary = Color(0xFFEC4899);
  static const Color secondaryLight = Color(0xFFF472B6);
  static const Color secondaryDark = Color(0xFFDB2777);

  // Dark mode secondary: oklch(0.5338 0.2503 301.3750) ≈ #8B5CF6 (purple, swapped)
  static const Color secondaryOnDark = Color(0xFF8B5CF6);

  // ============================================================================
  // ACCENT COLORS
  // ============================================================================

  // Light accent: oklch(0.7619 0.1861 327.2096) ≈ #F472B6
  static const Color accent = Color(0xFFF472B6);
  // Dark accent: oklch(0.5534 0.2217 349.6868) ≈ #E11D48
  static const Color accentOnDark = Color(0xFFE11D48);

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================

  // Light: oklch(0.9940 0 0) ≈ #FEFEFE
  static const Color backgroundLight = Color(0xFFFEFEFE);
  // Dark: oklch(0.2393 0 0) ≈ #1C1C1C
  static const Color backgroundDark = Color(0xFF1C1C1C);

  // ============================================================================
  // SURFACE COLORS (Cards, Popovers)
  // ============================================================================

  // Light: oklch(0.9940 0 0) ≈ #FEFEFE
  static const Color surfaceLight = Color(0xFFFEFEFE);
  // Dark: oklch(0.2393 0 0) ≈ #1C1C1C
  static const Color surfaceDark = Color(0xFF1C1C1C);

  // ============================================================================
  // CARD COLORS
  // ============================================================================

  static const Color cardLight = Color(0xFFFFFFFF);
  // Slightly elevated from background
  static const Color cardDark = Color(0xFF262626);

  // ============================================================================
  // MUTED COLORS (Subtle backgrounds)
  // ============================================================================

  // Light muted: oklch(0.9551 0 0) ≈ #F3F3F3
  static const Color mutedLight = Color(0xFFF3F3F3);
  // Dark muted: oklch(0.3211 0 0) ≈ #3D3D3D
  static const Color mutedDark = Color(0xFF3D3D3D);

  // Muted foreground
  // Light: oklch(0.5555 0 0) ≈ #737373
  static const Color mutedForegroundLight = Color(0xFF737373);
  // Dark: oklch(0.7155 0 0) ≈ #A3A3A3
  static const Color mutedForegroundDark = Color(0xFFA3A3A3);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  // Light foreground: oklch(0.2739 0.0055 286.0326) ≈ #1C1C1E
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Dark foreground: oklch(0.9851 0 0) ≈ #FAFAFA
  static const Color textPrimaryDark = Color(0xFFFAFAFA);
  static const Color textSecondaryDark = Color(0xFFA3A3A3);

  // ============================================================================
  // BORDER COLORS
  // ============================================================================

  // Light: oklch(0.9401 0 0) ≈ #E5E5E5
  static const Color borderLight = Color(0xFFE5E5E5);
  // Dark: oklch(0.3485 0 0) ≈ #404040
  static const Color borderDark = Color(0xFF404040);

  // ============================================================================
  // STATUS COLORS
  // ============================================================================

  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);

  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFCD34D);

  // Destructive: oklch(0.6368 0.2078 25.3313) ≈ #DC2626
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFEF4444);
  // Dark destructive: oklch(0.7106 0.1661 22.2162) ≈ #F87171
  static const Color errorOnDark = Color(0xFFF87171);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);

  // ============================================================================
  // RAFFLE STATUS COLORS
  // ============================================================================

  static const Color statusActive = Color(0xFF22C55E);
  static const Color statusClosed = Color(0xFFFBBF24);
  static const Color statusDrawn = Color(0xFF8B5CF6);

  // ============================================================================
  // CHART COLORS
  // ============================================================================

  static const Color chart1 = Color(0xFF8B5CF6); // Purple
  static const Color chart2 = Color(0xFFF472B6); // Pink
  static const Color chart3 = Color(0xFFE11D48); // Red
  static const Color chart4 = Color(0xFFF472B6); // Light Pink
  static const Color chart5 = Color(0xFFC026D3); // Mauve

  // ============================================================================
  // SIDEBAR COLORS (matches web)
  // ============================================================================

  static const Color sidebar = Color(0xFF8B5CF6);
  static const Color sidebarForeground = Color(0xFFFFFFFF);
  static const Color sidebarAccent = Color(0xFFF472B6);

  // ============================================================================
  // GRADIENTS
  // ============================================================================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark background gradient (matches web admin layout)
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [
      backgroundDark,
      backgroundDark,
      Color(0xFF2D1F3D), // primary/5 equivalent
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Winner celebration gradient (yellow/orange)
  static const LinearGradient celebrationGradient = LinearGradient(
    colors: [
      Color(0xFFFDE047), // yellow-300
      Color(0xFFFACC15), // yellow-400
      Color(0xFFFB923C), // orange-400
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Logo/brand gradient
  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      Color(0xFF9333EA), // purple-600
      Color(0xFFDB2777), // pink-600
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // CONTEXT-AWARE COLOR METHODS (for easy theme-aware usage in widgets)
  // ============================================================================

  /// Primary text color - adapts to theme
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimaryDark
          : textPrimaryLight;

  /// Secondary text color - adapts to theme
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondaryDark
          : textSecondaryLight;

  /// Tertiary/muted text color - adapts to theme
  static Color textTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? mutedForegroundDark
          : mutedForegroundLight;

  /// Card background - adapts to theme
  static Color cardBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardDark : cardLight;

  /// Surface variant (subtle backgrounds) - adapts to theme
  static Color surfaceVariant(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? mutedDark : mutedLight;

  /// Border color - adapts to theme
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : borderLight;

  /// Shadow color - adapts to theme
  static Color shadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withAlpha(100)
          : Colors.black.withAlpha(25);

  /// Background color - adapts to theme
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? backgroundDark
          : backgroundLight;

  /// Surface color - adapts to theme
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;

  /// Primary color - adapts to theme
  static Color primaryAdaptive(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryOnDark : primary;

  /// Error color - adapts to theme
  static Color errorAdaptive(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? errorOnDark : error;

  /// Text color on primary surfaces (white/dark)
  static const Color textOnPrimary = Colors.white;
}
