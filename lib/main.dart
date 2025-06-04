// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/mesc/loading_page.dart';
import 'package:flutter_application_1/Pages/mesc/login_page.dart';
import 'package:flutter_application_1/Pages/mesc/register_page.dart';
import 'package:flutter_application_1/Pages/mesc/GetStartedPage.dart';
import 'package:flutter_application_1/Pages/MPages/main_app_page.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _cycleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  final List<File> _items = []; // Initialize the shared items list

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outfit App',
      theme: ThemeData(
primaryColor: Color(0xFFFAFAFA),
scaffoldBackgroundColor: Color(0xFFFAFAFA),
textTheme: TextTheme(
  bodyLarge: TextStyle(color: Color(0xFF333333)),
  bodyMedium: TextStyle(color: Color(0xFF333333)),
),
appBarTheme: const AppBarTheme(
  centerTitle: true, // ✅ Center the title
  backgroundColor: Colors.white,
  foregroundColor: Color(0xFFFF9800),
  elevation: 0,
  titleTextStyle: TextStyle(
    fontSize: 22, // ⬆️ Slightly larger
    fontWeight: FontWeight.bold,
    color: Color(0xFFFF9800),
  ),
),


bottomNavigationBarTheme: BottomNavigationBarThemeData(
  backgroundColor: Colors.white,
  selectedItemColor: Color(0xFFFF9800),
  unselectedItemColor: Color(0xFFBDBDBD),
),
buttonTheme: ButtonThemeData(
  buttonColor: Color(0xFFD32F2F), // delete button red
),
colorScheme: ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFFF9800),
  onPrimary: Colors.white,
  secondary: Color(0xFFFFE0B2),
  onSecondary: Color(0xFF333333),
  error: Color(0xFFD32F2F),
  onError: Colors.white,
  background: Color(0xFFFAFAFA),
  onBackground: Color(0xFF333333),
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF333333),
),

        dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              titleTextStyle: TextStyle(
                color: Color(0xFFD9583B), // Coral red or use Colors.black
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              contentTextStyle: TextStyle(
                color: Colors.black, // Body text in black
                fontSize: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
snackBarTheme: SnackBarThemeData(
  backgroundColor: Colors.black,
  contentTextStyle: TextStyle(
    color: Colors.white,
    fontSize: 14,
  ),
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
),

   
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFF7B28C),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFF7B28C),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFFFAE0C3),
          onSecondary: Color(0xFFFFFFFF),
          error: Color(0xFFD9583B),
          onError: Color(0xFFFFFFFF),
          background: Color(0xFF1E1E1E),
          onBackground: Color(0xFFFFFFFF),
          surface: Color(0xFFFDE3C4), // Match light theme surface tone for consistency
          onSurface: Color(0xFFFFFFFF),
        ),
dialogTheme: DialogThemeData(
  backgroundColor: Colors.white,
  titleTextStyle: TextStyle(
    color: Color(0xFFD9583B),
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
  contentTextStyle: TextStyle(
    color: Colors.black,
    fontSize: 16,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
),
snackBarTheme: SnackBarThemeData(
  backgroundColor: Colors.black,
  contentTextStyle: TextStyle(
    color: Colors.white,
    fontSize: 14,
  ),
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7B28C),
          foregroundColor: Colors.white,
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: const Color(0xFFD9583B),
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const GetStartedPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => MainAppPage(items: _items, onThemeChange: _cycleTheme),
      },
    );
  }
}
