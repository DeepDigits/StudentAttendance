import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  MaterialColor _primaryColor = Colors.pink; // Default color

  // Use FlutterSecureStorage
  final _storage = const FlutterSecureStorage();

  // Keys for secure storage (must be strings)
  static const String _themeModeKey = 'settings_themeMode';
  static const String _primaryColorKey = 'settings_primaryColorIndex';

  ThemeMode get themeMode => _themeMode;
  MaterialColor get primaryColor => _primaryColor;

  final List<MaterialColor> _availableColors = [
    Colors.pink,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.red,
    Colors.indigo, // Added more colors
    Colors.cyan,
  ];

  List<MaterialColor> get availableColors => _availableColors;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Read from secure storage
      final themeModeIndexString = await _storage.read(key: _themeModeKey);
      final colorIndexString = await _storage.read(key: _primaryColorKey);

      // Parse stored values (handle null and parsing errors)
      final themeModeIndex =
          int.tryParse(themeModeIndexString ?? '') ?? ThemeMode.system.index;
      // Default to 0 (index of Colors.pink) if parsing fails or value is null
      final colorIndex = int.tryParse(colorIndexString ?? '') ?? 0;

      // Clamp indices to prevent range errors
      _themeMode = ThemeMode
          .values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)];
      _primaryColor =
          _availableColors[colorIndex.clamp(0, _availableColors.length - 1)];
    } catch (e) {
      print("Error loading settings: $e");
      // Keep default values if loading fails
      _themeMode = ThemeMode.system;
      _primaryColor = Colors.pink;
    } finally {
      notifyListeners(); // Notify listeners even if loading fails to update with defaults
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      // Write to secure storage as string
      await _storage.write(key: _themeModeKey, value: mode.index.toString());
    } catch (e) {
      print("Error saving theme mode: $e");
      // Optionally handle the error (e.g., show a toast)
    }
  }

  Future<void> setPrimaryColor(MaterialColor color) async {
    if (_primaryColor == color) return;
    _primaryColor = color;
    notifyListeners();
    final index = _availableColors.indexOf(color);
    if (index != -1) {
      try {
        // Write to secure storage as string
        await _storage.write(key: _primaryColorKey, value: index.toString());
      } catch (e) {
        print("Error saving primary color: $e");
        // Optionally handle the error
      }
    } else {
      print("Error: Selected color not found in available colors.");
      // Handle case where the color isn't in the list (shouldn't happen with UI)
    }
  }
}
