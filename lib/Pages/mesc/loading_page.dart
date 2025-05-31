import 'dart:io';
import 'package:flutter/material.dart';

class LoadingPage extends StatefulWidget {
  final Widget Function() nextPageBuilder; // Function to build the next page
  final File? imageFile; // Optional image file for specific cases

  const LoadingPage({super.key, required this.nextPageBuilder, this.imageFile});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    _simulateAIAnalysis();
  }

  Future<void> _simulateAIAnalysis() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate loading
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.nextPageBuilder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
