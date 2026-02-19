import 'package:flutter/material.dart';

class KeyboardTheme {
  final String name;
  final Color backgroundColor;
  final Color keyColor;
  final Color specialKeyColor;
  final Color textColor;
  final Color specialKeyIconColor;

  const KeyboardTheme({
    required this.name,
    required this.backgroundColor,
    required this.keyColor,
    required this.specialKeyColor,
    required this.textColor,
    required this.specialKeyIconColor,
  });

  static const dark = KeyboardTheme(
    name: 'Dark',
    backgroundColor: Color(0xFF171717),
    keyColor: Color(0xFF3C4043),
    specialKeyColor: Color(0xFF2C2C2C),
    textColor: Colors.white,
    specialKeyIconColor: Colors.white,
  );

  
  static const oled = KeyboardTheme(
    name: 'OLED Black',
    backgroundColor: Colors.black,
    keyColor: Color(0xFF1E1E1E),
    specialKeyColor: Color(0xFF121212),
    textColor: Colors.white,
    specialKeyIconColor: Colors.grey,
  );
  
  static const oceanBlue = KeyboardTheme(
    name: 'Ocean Blue',
    backgroundColor: Color(0xFF0D1B2A),
    keyColor: Color(0xFF1B263B),
    specialKeyColor: Color(0xFF415A77),
    textColor: Colors.white,
    specialKeyIconColor: Color(0xFFE0E1DD),
  );
  
  static const crimsonRed = KeyboardTheme(
    name: 'Crimson Red',
    backgroundColor: Color(0xFF2B0505),
    keyColor: Color(0xFF5C1010),
    specialKeyColor: Color(0xFF8A1C1C),
    textColor: Colors.white,
    specialKeyIconColor: Colors.white,
  );
  
  static const forestGreen = KeyboardTheme(
    name: 'Forest Green',
    backgroundColor: Color(0xFF05190B),
    keyColor: Color(0xFF14361C),
    specialKeyColor: Color(0xFF2D5A38),
    textColor: Colors.white,
    specialKeyIconColor: Color(0xFFA7E8BD),
  );
  
  static const royalPurple = KeyboardTheme(
    name: 'Royal Purple',
    backgroundColor: Color(0xFF1A0524),
    keyColor: Color(0xFF320E44),
    specialKeyColor: Color(0xFF521970),
    textColor: Colors.white,
    specialKeyIconColor: Color(0xFFE3B5FA),
  );
  
  static const List<KeyboardTheme> themes = [
    dark, oled, oceanBlue, crimsonRed, forestGreen, royalPurple
  ];
}
