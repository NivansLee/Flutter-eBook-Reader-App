import 'package:flutter/material.dart';

class ReaderSettingsProvider with ChangeNotifier {
  double _fontSize = 16;
  double _brightness = 0.5;
  ReaderTheme _theme = ReaderTheme.light;

  double get fontSize => _fontSize;
  double get brightness => _brightness;
  ReaderTheme get theme => _theme;

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setBrightness(double value) {
    _brightness = value;
    notifyListeners();
  }

  void setTheme(ReaderTheme theme) {
    _theme = theme;
    notifyListeners();
  }
}

enum ReaderTheme {
  light,
  sepia,
  dark,
}

extension ReaderThemeExtension on ReaderTheme {
  Color get backgroundColor {
    switch (this) {
      case ReaderTheme.light:
        return Colors.white;
      case ReaderTheme.sepia:
        return const Color(0xFFF5E6C6);
      case ReaderTheme.dark:
        return Colors.black;
    }
  }

  Color get textColor {
    switch (this) {
      case ReaderTheme.light:
        return Colors.black;
      case ReaderTheme.sepia:
        return Colors.brown;
      case ReaderTheme.dark:
        return Colors.white;
    }
  }
} 