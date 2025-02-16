import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaries.first,
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.25),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.5),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.5),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, height: 1.5),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.small),
        borderSide: BorderSide(color: AppColors.border),
      ),
      contentPadding: EdgeInsets.all(AppSpacing.medium),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.medium,
          horizontal: AppSpacing.large,
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.small),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.medium),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.medium),
      ),
    ),
  );



  static ThemeData darkTheme = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaries.first,
      brightness: Brightness.dark,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.25, color: Colors.white),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.5, color: Colors.white),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.5, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: Colors.white70),
      bodySmall: TextStyle(fontSize: 12, height: 1.5, color: Colors.white60),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: Colors.white),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5, color: Colors.white),
    ),
    inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(labelStyle: TextStyle(color: Colors.grey[300]), hintStyle: TextStyle(color: Colors.grey[400]),),
    elevatedButtonTheme: lightTheme.elevatedButtonTheme,
    cardTheme: lightTheme.cardTheme,
    dialogTheme: lightTheme.dialogTheme,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.white,
    ),
  );
}

class AppColors {
  static List<Color> primaries = [
    Colors.blue.shade800,
    Colors.green.shade600,
    Colors.purple.shade700,
    Colors.orange.shade600,
  ];

  static Color success = Colors.green.shade600;
  static Color warning = Colors.orange.shade600;
  static Color error = Colors.red.shade400;
  static Color info = Colors.blue.shade200;
  static Color border = Colors.grey.shade400;
}

class AppSpacing {
  static double xxsmall = 2;
  static double xsmall = 4;
  static double small = 8;
  static double medium = 16;
  static double large = 24;
  static double xlarge = 32;
  static double xxlarge = 48;

  // Special dimensions
  static double previewWidth = 260;
  static double previewHeight = 140;
}