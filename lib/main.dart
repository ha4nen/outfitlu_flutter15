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
<<<<<<< HEAD
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Outfit App',
    theme: ThemeData(
      primaryColor: Color(0xFFF7B28C), // Warm soft orange
      hintColor: const Color(0xFFD9583B), // Coral red (Accent)
      scaffoldBackgroundColor: const Color.fromARGB(255, 248, 248, 248), // Light background
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF5C2E10)), // Deep brown
        bodyMedium: TextStyle(color: Color(0xFF5C2E10)),
=======
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outfit App',
      theme: ThemeData(
        primaryColor: const Color(0xFF3C096C), // Dark Purple
        hintColor: const Color(0xFFC77DFF), // Electric Purple
        scaffoldBackgroundColor: const Color(0xFFFFFFFF), // White
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color.fromARGB(255, 0, 0, 0)), // black
          bodyMedium: TextStyle(color: Color.fromARGB(255, 0, 0, 0)), // black
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3C096C), // Dark Purple
          foregroundColor: Color(0xFFFFFFFF), // White
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: const Color(0xFFC77DFF), // Electric Purple
          textTheme: ButtonTextTheme.primary,
        ),
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF3C096C), // Dark Purple
          onPrimary: Color(0xFFFFFFFF), // White
          secondary: Color(0xFFC77DFF), // Electric Purple
          onSecondary: Color(0xFFFFFFFF), // White
          error: Color.from(alpha: 1, red: 0.69, green: 0, blue: 0.125), // Error Red
          onError: Color(0xFFFFFFFF), // White
          background: Color(0xFFFFFFFF), // White
          onBackground: Color.fromARGB(255, 0, 0, 0), // black nav buttons
          surface: Color(0xFFF0F0F0), // Light Grey
          onSurface: Color.fromARGB(255, 0, 0, 0), // White
        ),
>>>>>>> 42f874c6b5cd514e1670b88b119c8d00986e160a
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7B28C), // Same as bottom navigation bar (secondary)
        foregroundColor: Color(0xFF5C2E10), // Deep brown
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFF7B28C), // Pale beige-pink (secondary)
        selectedItemColor: Color(0xFFD9583B), // Coral red (accent)
        unselectedItemColor: Color(0xFF5C2E10), // Deep brown
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: const Color(0xFFD9583B), // Coral red
        textTheme: ButtonTextTheme.primary,
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary:Color(0xFFF7B28C),
        onPrimary: Color(0xFF5C2E10),
        secondary: Color(0xFFFAE0C3),
        onSecondary: Color(0xFF5C2E10),
        error: Color(0xFFD9583B),
        onError: Color(0xFF5C2E10),
        background: Colors.white,
        onBackground: Color(0xFF5C2E10),
        surface: Color(0xFFF7B28C), // Updated surface color
        onSurface: Color(0xFF5C2E10),
      ),
    ),
    darkTheme: ThemeData.dark().copyWith(
      primaryColor:Color(0xFFF7B28C),
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
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor:Color(0xFFF7B28C),
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
        '/main':
            (context) => MainAppPage(items: _items, onThemeChange: _cycleTheme),
      },
    );
  }
}
