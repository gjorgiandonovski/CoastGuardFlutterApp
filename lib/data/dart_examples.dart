Future<String> fetchMissionDetails() async {
  await Future.delayed(const Duration(seconds: 2));
  return 'Apollo 11 Mission: Moon landing.';
}

int fibonacci(int n) {
  if (n == 0 || n == 1) {
    return n;
  }
  return fibonacci(n - 1) + fibonacci(n - 2);
}

List<int> fibonacciValues() {
  return List<int>.generate(7, fibonacci);
}

enum PlanetType { terrestrial, gas, ice }

enum Planet {
  mercury(planetType: PlanetType.terrestrial, moons: 0, hasRings: false),
  venus(planetType: PlanetType.terrestrial, moons: 0, hasRings: false),
  uranus(planetType: PlanetType.ice, moons: 27, hasRings: true),
  neptune(planetType: PlanetType.ice, moons: 14, hasRings: true);

  const Planet({
    required this.planetType,
    required this.moons,
    required this.hasRings,
  });

  final PlanetType planetType;
  final int moons;
  final bool hasRings;

  bool get isGiant =>
      planetType == PlanetType.gas || planetType == PlanetType.ice;
}

class Spacecraft {
  Spacecraft(this.name, this.launchDate);

  final String name;
  final DateTime launchDate;

  int get yearsSinceLaunch => DateTime.now().year - launchDate.year;

  String describe() {
    return '$name launched in ${launchDate.year} '
        '($yearsSinceLaunch years ago)';
  }
}

class Orbiter extends Spacecraft {
  Orbiter(super.name, super.launchDate, this.altitude);

  final double altitude;

  @override
  String describe() {
    return '${super.describe()} and orbits at $altitude km';
  }
}
