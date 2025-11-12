import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  Future<void> _loadThemeMode() async {
    _themeMode = await AppTheme.getThemeMode();
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    
    await AppTheme.saveThemeMode(_themeMode);
    notifyListeners();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await AppTheme.saveThemeMode(_themeMode);
    notifyListeners();
  }
  
  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
      default:
        // Return based on system brightness
        return WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    }
  }
}