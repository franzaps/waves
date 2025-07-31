import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final brightnessProvider = StateProvider<Brightness>((ref) => Brightness.dark);

// Theme provider that switches between light and dark
final themeProvider = Provider<ThemeData>((ref) {
  final brightness = ref.watch(brightnessProvider);
  return brightness == Brightness.light ? lightTheme : darkTheme;
});

// Helper function to scale text theme proportionally
TextTheme _scaleTextTheme(TextTheme baseTextTheme, double scaleFactor) {
  return TextTheme(
    displayLarge: baseTextTheme.displayLarge?.copyWith(
      fontSize: (baseTextTheme.displayLarge?.fontSize ?? 57) * scaleFactor,
    ),
    displayMedium: baseTextTheme.displayMedium?.copyWith(
      fontSize: (baseTextTheme.displayMedium?.fontSize ?? 45) * scaleFactor,
    ),
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      fontSize: (baseTextTheme.displaySmall?.fontSize ?? 36) * scaleFactor,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: (baseTextTheme.headlineLarge?.fontSize ?? 32) * scaleFactor,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: (baseTextTheme.headlineMedium?.fontSize ?? 28) * scaleFactor,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontSize: (baseTextTheme.headlineSmall?.fontSize ?? 24) * scaleFactor,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: (baseTextTheme.titleLarge?.fontSize ?? 22) * scaleFactor,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: (baseTextTheme.titleMedium?.fontSize ?? 16) * scaleFactor,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontSize: (baseTextTheme.titleSmall?.fontSize ?? 14) * scaleFactor,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: (baseTextTheme.bodyLarge?.fontSize ?? 16) * scaleFactor,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: (baseTextTheme.bodyMedium?.fontSize ?? 14) * scaleFactor,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontSize: (baseTextTheme.bodySmall?.fontSize ?? 12) * scaleFactor,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontSize: (baseTextTheme.labelLarge?.fontSize ?? 14) * scaleFactor,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontSize: (baseTextTheme.labelMedium?.fontSize ?? 12) * scaleFactor,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: (baseTextTheme.labelSmall?.fontSize ?? 11) * scaleFactor,
    ),
  );
}

// Light theme with darker blue aesthetic and Poppins font
final lightTheme =
    ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D47A1), // Deep blue seed
        brightness: Brightness.light,
        primary: const Color(0xFF0D47A1), // Deep blue primary
        secondary: const Color(0xFF1565C0), // Darker blue secondary
        surface: const Color(0xFFF8F9FA), // Light surface
        background: const Color(0xFFFFFFFF), // White background
        onPrimary: const Color(0xFFFFFFFF), // White on primary
        onSecondary: const Color(0xFFFFFFFF), // White on secondary
        onSurface: const Color(0xFF1A1C1E), // Dark text on surface
        onBackground: const Color(0xFF1A1C1E), // Dark text on background
      ),
      fontFamily: GoogleFonts.poppins().fontFamily,
      cardTheme: const CardThemeData(
        elevation: 3,
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16.0),
          ), // Moderately rounded
        ),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Moderately rounded
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Moderately rounded
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 14.0),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Moderately rounded
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 14.0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Moderately rounded
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 14.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 16.0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF0D47A1),
      ),
    ).copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(
        _scaleTextTheme(
          ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D47A1),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ).textTheme,
          1.15, // Larger fonts for better readability
        ),
      ),
    );

// Dark theme with darker blue aesthetic and Poppins font
final darkTheme =
    ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D47A1), // Deep blue seed
        brightness: Brightness.dark,
        primary: const Color(0xFF1976D2), // Medium blue primary for contrast
        secondary: const Color(0xFF42A5F5), // Light blue secondary
        surface: const Color(0xFF1A1D29), // Dark blue surface
        background: const Color(0xFF0D1117), // Very dark blue background
        onPrimary: const Color(0xFFFFFFFF), // White on primary
        onSecondary: const Color(0xFF000000), // Black on light secondary
        onSurface: const Color(0xFFE1E4E8), // Light text on surface
        onBackground: const Color(0xFFE1E4E8), // Light text on background
      ),
      scaffoldBackgroundColor: const Color(
        0xFF0D1117,
      ), // Very dark blue scaffold
      fontFamily: GoogleFonts.poppins().fontFamily,
      cardTheme: const CardThemeData(
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Color(0xFF212936), // Dark blue-tinted card background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16.0),
          ), // Moderately rounded
        ),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        backgroundColor: const Color(0xFF1976D2), // Darker blue chips
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Moderately rounded
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2), // Darker blue buttons
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Moderately rounded
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 14.0),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2), // Darker blue buttons
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Moderately rounded
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 14.0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Moderately rounded
          ),
          side: const BorderSide(
            color: Color(0xFF1976D2),
          ), // Darker blue outline
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 14.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: const Color(0xFF212936), // Dark blue input background
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: Color(0xFF1976D2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 16.0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF42A5F5),
        backgroundColor: Color(0xFF212936), // Dark blue navigation bar
        unselectedItemColor: Color(0xFF6B7280), // Gray unselected
      ),
    ).copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(
        _scaleTextTheme(
          ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D47A1),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ).textTheme,
          1.15, // Larger fonts for better readability
        ),
      ),
    );
