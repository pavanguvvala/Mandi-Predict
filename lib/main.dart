import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/localization.dart';

void main() {
  runApp(const MandiPredictApp());
}

class MandiPredictApp extends StatelessWidget {
  const MandiPredictApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, localeCode, child) {
        return MaterialApp(
          title: 'Mandi Price Predictor',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B5E20), // Deep Forest Green (Match Login)
              primary: const Color(0xFF1B5E20),
              secondary: const Color(0xFF66BB6A),
              surface: Colors.white,
              background: const Color(0xFFF1F8E9),
            ),
            scaffoldBackgroundColor: const Color(0xFFF1F8E9),

            // Typography
            fontFamily: 'Roboto',
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: -1.0,
                color: Color(0xFF1B5E20),
              ),
              headlineMedium: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              titleLarge: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),

            // Input Fields (Keep modernish but match general style)
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              prefixIconColor: const Color(0xFF1B5E20),
              labelStyle: TextStyle(color: Colors.grey[600]),
            ),

            // Floating Action Button
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            // Card Theme
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              margin: const EdgeInsets.only(bottom: 16),
            ),

            // Button Theme
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20), // Dark Green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF1B5E20).withOpacity(0.5),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
