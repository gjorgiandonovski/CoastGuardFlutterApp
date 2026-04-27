import 'package:flutter/material.dart';

class ThirdScreenPage extends StatelessWidget {
  const ThirdScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Third Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Go Back to Home'),
        ),
      ),
    );
  }
}

class ThirdScreen extends StatelessWidget {
  const ThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Widgets are now organized into different files:'),
          SizedBox(height: 12),
          Text('app.dart'),
          Text('main_screen.dart'),
          Text('screens/splash_screen.dart'),
          Text('screens/second_screen.dart'),
          Text('screens/third_screen.dart'),
          Text('data/dart_examples.dart'),
        ],
      ),
    );
  }
}
