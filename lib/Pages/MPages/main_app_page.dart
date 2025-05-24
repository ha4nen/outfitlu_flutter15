import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/MPages/clalender%20page.dart';
import 'package:flutter_application_1/Pages/MPages/magic_page.dart';
import 'package:flutter_application_1/Pages/MPages/profile_page.dart';
import 'package:flutter_application_1/Pages/MPages/feed_page.dart';
import 'package:flutter_application_1/Pages/The+Button/AddItemOptionsPage.dart';

class MainAppPage extends StatefulWidget {
  final List<File> items;
  final VoidCallback onThemeChange;

  const MainAppPage({
    super.key,
    required this.items,
    required this.onThemeChange,
  });

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _nextIndex = 0;
  Offset _tapPosition = Offset.zero;

  late final List<Widget> _pages;
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pages = [
      WardrobePage(key: const ValueKey('FeedPage')),

      MagicPage(
        key: const ValueKey('MagicPage'),
        onThemeChange: widget.onThemeChange,
        fromCalendar: false,
      ),
      const FeedPage(key: ValueKey('CalendarPage')),
      ProfilePage(
        key: const ValueKey('ProfilePage'),
        items: widget.items,
        onThemeChange: widget.onThemeChange,
      ),
    ];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = _nextIndex;
          _isAnimating = false;
        });
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToPage(int index, Offset tapPosition) {
    if (index != _currentIndex && !_isAnimating) {
      setState(() {
        _nextIndex = index;
        _isAnimating = true;
        _tapPosition = tapPosition;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_currentIndex],
          if (_isAnimating)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ClipOval(
                  clipper: _RevealClipper(_animation.value, _tapPosition),
                  child: _pages[_nextIndex],
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          RenderBox? box = context.findRenderObject() as RenderBox?;
          Offset _ = box?.size.center(Offset.zero) ?? Offset.zero;

          // Calculate approximate tap position (adjust depending on icon location)
          double screenWidth = MediaQuery.of(context).size.width;
          double itemWidth = screenWidth / 4; // 4 items
          double x = itemWidth * (index + 0.5); // center of tapped item
          double y = MediaQuery.of(context).size.height; // bottom of screen

          _navigateToPage(
            index,
            Offset(x, y - 30),
          ); // Adjust slightly up to look cleaner
        },
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.feed_rounded),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Magic',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddItemOptionsPage(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onSecondary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  final double revealPercent;
  final Offset center;

  _RevealClipper(this.revealPercent, this.center);

  @override
  Rect getClip(Size size) {
    final maxRadius = size.longestSide * 1.2;
    final radius = maxRadius * revealPercent;
    return Rect.fromCircle(center: center, radius: radius);
  }

  @override
  bool shouldReclip(_RevealClipper oldClipper) =>
      revealPercent != oldClipper.revealPercent || center != oldClipper.center;
}
