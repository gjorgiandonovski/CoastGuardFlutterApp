import 'package:flutter/material.dart';

import 'screens/examples_screen.dart';
import 'screens/map_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/third_screen.dart';
import 'screens/week_activity_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = const [
    'Home',
    'Dart Snippets',
    'Files',
    'Week 3 Activity',
    'Map',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      SplashScreen(onOpenWeekActivity: () => _onItemTapped(3)),
      const ExamplesScreen(),
      const ThirdScreen(),
      const WeekActivityScreen(),
      const MapScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.code), label: 'Examples'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.science), label: 'Week 3'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}
