import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised design tokens for Little Artist.
///
/// All colors, typography, spacing, shadows, and component sizes live here.
/// Always reference [Brand] — never hardcode design values elsewhere.
class Brand {
  Brand._();

  // ---------------------------------------------------------------------------
  // MARK: - Colors (Light)
  // ---------------------------------------------------------------------------

  static const Color primary = Color(0xFFF2784B);
  static final Color primaryTint = primary.withValues(alpha: 0.12);

  static const Color cream = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFFBF7);
  static const Color charcoal = Color(0xFF3D3D3D);
  static const Color warmGray = Color(0xFF8A8680);
  static const Color softTan = Color(0xFFE8E0D8);

  static const Color sage = Color(0xFFA8C5A0);
  static const Color sky = Color(0xFF7EB8DA);
  static const Color lavender = Color(0xFFB8A9D4);
  static const Color dustyRose = Color(0xFFD4736C);
  static const Color disabled = Color(0xFF8A8680);

  // ---------------------------------------------------------------------------
  // MARK: - Avatar Palette
  // ---------------------------------------------------------------------------

  static const List<String> avatarColors = [
    'F2784B',
    'A8C5A0',
    '7EB8DA',
    'B8A9D4',
    'E8C94A',
    'D4928A',
    '7BC8B5',
  ];
  static const String defaultAvatarColor = 'F2784B';

  // ---------------------------------------------------------------------------
  // MARK: - Typography
  // ---------------------------------------------------------------------------

  static TextStyle displayFont = GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );

  static TextStyle title1Font = GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static TextStyle title2Font = GoogleFonts.nunito(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static TextStyle title3Font = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );

  static TextStyle headlineFont = GoogleFonts.nunito(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyFont = TextStyle(fontSize: 17);

  static const TextStyle subheadlineFont = TextStyle(fontSize: 15);

  static const TextStyle captionFont = TextStyle(fontSize: 12);

  static const TextStyle caption2Font = TextStyle(fontSize: 11);

  // ---------------------------------------------------------------------------
  // MARK: - Corner Radii
  // ---------------------------------------------------------------------------

  static const double radiusOnboarding = 40;
  static const double radiusSheet = 20;
  static const double radiusCard = 18;
  static const double radiusButton = 16;
  static const double radiusField = 14;
  static const double radiusImage = 12;

  // ---------------------------------------------------------------------------
  // MARK: - Spacing
  // ---------------------------------------------------------------------------

  static const double screenPadding = 20;
  static const double formPadding = 32;
  static const double sectionSpacing = 28;
  static const double gallerySpacing = 24;
  static const double buttonPadding = 18;
  static const double fieldPadding = 14;

  // ---------------------------------------------------------------------------
  // MARK: - Component Sizes
  // ---------------------------------------------------------------------------

  static const double avatarSize = 60;
  static const double avatarRingSize = 68;
  static const double avatarRingStroke = 3;
  static const double avatarPreviewSize = 110;
  static const double sourceButtonSize = 56;
  static const double thumbnailWidth = 164;
  static const double thumbnailHeight = 180;
  static const double fabSize = 60;
  static const double onboardingCardHeight = 340;
  static const double colorCircleSize = 40;

  // ---------------------------------------------------------------------------
  // MARK: - Shadows
  // ---------------------------------------------------------------------------

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: charcoal.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> avatarShadow = [
    BoxShadow(
      color: charcoal.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> fabShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.40),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // ---------------------------------------------------------------------------
  // MARK: - ThemeData
  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: sage,
      onSecondary: charcoal,
      tertiary: lavender,
      onTertiary: charcoal,
      error: dustyRose,
      onError: Colors.white,
      surface: surface,
      onSurface: charcoal,
      surfaceContainerHighest: softTan,
    );

    final textTheme = TextTheme(
      displayLarge: displayFont.copyWith(color: charcoal),
      headlineLarge: title1Font.copyWith(color: charcoal),
      headlineMedium: title2Font.copyWith(color: charcoal),
      headlineSmall: title3Font.copyWith(color: charcoal),
      titleLarge: headlineFont.copyWith(color: charcoal),
      bodyLarge: bodyFont.copyWith(color: charcoal),
      bodyMedium: subheadlineFont.copyWith(color: charcoal),
      bodySmall: captionFont.copyWith(color: warmGray),
      labelSmall: caption2Font.copyWith(color: warmGray),
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: cream,
      dividerColor: softTan,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        foregroundColor: charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: title2Font.copyWith(color: charcoal),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cream,
        indicatorColor: primaryTint,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return captionFont.copyWith(
              color: primary,
              fontWeight: FontWeight.w600,
            );
          }
          return captionFont.copyWith(color: warmGray);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return const IconThemeData(color: warmGray);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
    );
  }
}
