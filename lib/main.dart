// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/mesc/loading_page.dart';
import 'package:flutter_application_1/Pages/mesc/login_page.dart';
import 'package:flutter_application_1/Pages/mesc/register_page.dart';
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
          error: Color(0xFFB00020), // Error Red
          onError: Color(0xFFFFFFFF), // White
          background: Color(0xFFFFFFFF), // White
          onBackground: Color.fromARGB(255, 0, 0, 0), // black nav buttons
          surface: Color(0xFFF0F0F0), // Light Grey
          onSurface: Color(0xFFFFFFFF), // White
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF3C096C), // Dark Purple
        scaffoldBackgroundColor: const Color(0xFF000000), // Black
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF3C096C), // Dark Purple
          onPrimary: Color(0xFFD3D3D3), // Slightly Greyish White
          secondary: Color(0xFFC77DFF), // Electric Purple
          onSecondary: Color(0xFFD3D3D3), // Slightly Greyish White
          error: Color(0xFFCF6679), // Error Red
          onError: Color(0xFFD3D3D3), // Slightly Greyish White
          background: Color(0xFF000000), // Black
          onBackground: Color(0xFFD3D3D3), // Slightly Greyish White
          surface: Color(0xFF121212), // Very Dark Grey
          onSurface: Color(0xFFB0B0B0), // Soft Grey
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xFFD3D3D3),
          ), // Slightly Greyish White
          bodyMedium: TextStyle(color: Color(0xFFB0B0B0)), // Soft Grey
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3C096C), // Dark Purple
          foregroundColor: Color(0xFFD3D3D3), // Slightly Greyish White
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: const Color(0xFFC77DFF), // Electric Purple
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/':
            (context) => LoadingPage(
              imageFile: File('path/to/your/image'),
              nextPageBuilder: () => const LoginPage(),
            ), // Provide the required imageFile parameter
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main':
            (context) => MainAppPage(items: _items, onThemeChange: _cycleTheme),
      },
    );
  }
}
