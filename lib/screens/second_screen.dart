import 'package:flutter/material.dart';

import '../data/dart_examples.dart';
import 'third_screen.dart';

class SecondScreenPage extends StatelessWidget {
  const SecondScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orbiter = Orbiter('Hubble Telescope', DateTime(1990, 4, 24), 559);

    return Scaffold(
      appBar: AppBar(title: const Text('Second Screen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Fibonacci: ${fibonacciValues().join(', ')}'),
          const SizedBox(height: 12),
          Text('Planet Uranus has rings: ${Planet.uranus.hasRings}'),
          const SizedBox(height: 12),
          Text('Planet Venus is giant: ${Planet.venus.isGiant}'),
          const SizedBox(height: 12),
          Text('Inheritance: ${orbiter.describe()}'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ThirdScreenPage(),
                ),
              );
            },
            child: const Text('Go to Third Screen'),
          ),
        ],
      ),
    );
  }
}

class ExamplesScreen extends StatelessWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orbiter = Orbiter('Voyager I', DateTime(1977, 9, 5), 700);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ExampleCard(
          title: 'Recursive Function',
          text: 'Fibonacci values: ${fibonacciValues().join(', ')}',
        ),
        _ExampleCard(
          title: 'Enhanced Enums',
          text:
              'Mercury type: ${Planet.mercury.planetType.name}, Neptune moons: ${Planet.neptune.moons}',
        ),
        _ExampleCard(title: 'Inheritance', text: orbiter.describe()),
        _AsyncExampleCard(),
      ],
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class _AsyncExampleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<String>(
          future: fetchMissionDetails(),
          builder: (context, snapshot) {
            final text = snapshot.connectionState == ConnectionState.done
                ? snapshot.data ?? 'No data'
                : 'Loading mission details...';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Async and Await',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(text),
              ],
            );
          },
        ),
      ),
    );
  }
}
