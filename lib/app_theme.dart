import 'package:flutter/material.dart';

class AppTheme {
  // Цвета (общие для обеих тем)
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyDark = Color(0xFF757575);
  
  // Тени
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.1),
      spreadRadius: 1,
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  // СВЕТЛАЯ ТЕМА
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: darkGreen,
        surface: Colors.white,
        surfaceContainerHighest: Color(0xFFF5F5F5),
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        titleTextStyle: TextStyle(
          color: primaryGreen,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  // ТЕМНАЯ ТЕМА
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: darkGreen,
        surface: Color(0xFF1E1E1E),
        surfaceContainerHighest: Color(0xFF2C2C2C),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: primaryGreen,
        titleTextStyle: TextStyle(
          color: primaryGreen,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: const Color(0xFF2C2C2C),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
      ),
    );
  }
}

// Стили для текста
class TextStyles {
  static const TextStyle habitTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  
  static const TextStyle habitTitleCompleted = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.grey,
    decoration: TextDecoration.lineThrough,
  );
  
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryGreen,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}

// Стили для кнопок
class ButtonStyles {
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryGreen,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  static ButtonStyle secondaryButton = TextButton.styleFrom(
    foregroundColor: AppTheme.primaryGreen,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );
}

// Стили для календаря
class CalendarStyles {
  static const headerStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryGreen,
  );
}

// Стили для статистики
class StatsStyles {
  static final statCard = BoxDecoration(
    color: AppTheme.lightGreen,
    borderRadius: BorderRadius.circular(12),
    boxShadow: AppTheme.cardShadow,
  );
  
  static const statNumber = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppTheme.primaryGreen,
  );
  
  static const statLabel = TextStyle(
    fontSize: 12,
    color: AppTheme.greyDark,
  );
}