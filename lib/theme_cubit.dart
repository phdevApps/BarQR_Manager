import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barqr_manager/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(AppTheme.lightTheme) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('darkMode') ?? false;
    final colorIndex = prefs.getInt('primaryColor') ?? 0;

    // Ensure color index is within valid range
    final validIndex = colorIndex.clamp(0, AppColors.primaries.length - 1);

    emit(_buildTheme(
      darkMode: darkMode,
      primaryColor: AppColors.primaries[validIndex],
    ));
  }

  void toggleTheme({bool? darkMode, Color? primaryColor}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentDark = state.brightness == Brightness.dark;

    // Force dark mode toggle even when color hasn't changed
    final newDarkMode = darkMode ?? !currentDark;
    final newColor = primaryColor ?? state.colorScheme.primary;

    await prefs.setBool('darkMode', newDarkMode);
    await prefs.setInt('primaryColor', AppColors.primaries.indexOf(newColor));

    emit(_buildTheme(
      darkMode: newDarkMode,
      primaryColor: newColor,
    ));
  }

  ThemeData _buildTheme({required bool darkMode, required Color primaryColor}) {
    final baseTheme = darkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: darkMode ? Brightness.dark : Brightness.light,
      ),
      // Force rebuild of text themes
      textTheme: baseTheme.textTheme.apply(
        bodyColor: darkMode ? Colors.white : Colors.black,
        displayColor: darkMode ? Colors.white : Colors.black,
      ),
    );
  }
}