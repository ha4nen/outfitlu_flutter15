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
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _nextIndex = 0;
  Offset _tapPosition = Offset.zero;

  late final List<Widget> _pages;
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _fabPulseController;

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

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeInOut,
    );

    _revealController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = _nextIndex;
          _isAnimating = false;
        });
        _revealController.reset();
      }
    });

    _fabPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // Removed pulsing animation as per new style
    // _fabPulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _revealController.dispose();
    _fabPulseController.dispose();
    super.dispose();
  }

  void _navigateToPage(int index, Offset tapPosition) {
    if (index != _currentIndex && !_isAnimating) {
      _nextIndex = index;
      _tapPosition = tapPosition;
      _revealController.forward(from: 0.0);
      setState(() {
        _isAnimating = true;
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _pages[_currentIndex],
          if (_isAnimating)
            AnimatedBuilder(
              animation: _revealAnimation,
              builder: (context, child) {
                return ClipOval(
                  clipper: _RevealClipper(_revealAnimation.value, _tapPosition),
                  child: _pages[_nextIndex],
                );
              },
            ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNavBar(context),
      floatingActionButton: AnimatedBuilder(
        animation: _fabPulseController,
        builder: (context, child) {
          double scale = 1.0 + (_fabPulseController.value * 0.08);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Transform.scale(
              scale: scale,
              child: Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 6,
    offset: Offset(0, 3),
  ),
],
                ),
                child: FloatingActionButton(
                  shape: const CircleBorder(),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddItemOptionsPage(),
                    );
                  },
                  backgroundColor: Colors.orange,
                  elevation: 8,
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 12,
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAnimatedIcon(Icons.feed_rounded, 'Feed', 0),
            _buildAnimatedIcon(Icons.auto_awesome, 'Magic', 1),
            const SizedBox(width: 40),
            _buildAnimatedIcon(Icons.calendar_today, 'Calendar', 2),
            _buildAnimatedIcon(Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.orange : Colors.grey;

    return GestureDetector(
      onTapDown: (details) => _navigateToPage(index, details.globalPosition),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: isSelected ? 1.0 : 0.95, end: isSelected ? 1.3 : 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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
