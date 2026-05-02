import 'package:flutter/material.dart';

import 'second_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.onOpenWeekActivity});

  final VoidCallback onOpenWeekActivity;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Simple Flutter demo with bottom navigation and weekly coursework activities.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SecondScreenPage(),
                  ),
                );
              },
              child: const Text('Go to Second Screen'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onOpenWeekActivity,
              child: const Text('Open Week 3 Activity'),
            ),
          ],
        ),
      ),
    );
  }
}
