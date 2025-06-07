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
          contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF9800),
        scaffoldBackgroundColor: const Color(0xFF181818),
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFFF9800),        // Orange accent
          onPrimary: Colors.white,
          secondary: Color(0xFFFF9800),      // Light orange for chips etc.
          onSecondary: Color(0xFF333333),
          error: Color(0xFFD32F2F),
          onError: Colors.white,
          background: Color(0xFF181818),     // Very dark background
          onBackground: Colors.white,
          surface: Color(0xFF232323),        // Slightly lighter for cards/inputs
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF232323),
          foregroundColor: Color(0xFFFF9800),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF9800),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF232323),
          selectedItemColor: Color(0xFFFF9800),
          unselectedItemColor: Color(0xFFBDBDBD),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFFFF9800),
          textTheme: ButtonTextTheme.primary,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF232323),
          titleTextStyle: const TextStyle(
            color: Color(0xFFFF9800),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.black,
          contentTextStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 14),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          bodyMedium: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF232323),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFFF9800)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFFF9800)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFFF9800), width: 2),
          ),
          hintStyle: TextStyle(color: Colors.white70),
          labelStyle: TextStyle(color: Color(0xFFFF9800)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF232323),
          selectedColor: const Color(0xFFFF9800),
          labelStyle: const TextStyle(color: Colors.white),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          brightness: Brightness.dark,
          disabledColor: Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFF9800)),
          ),
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
