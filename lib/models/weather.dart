class Weather {
  final double temperature;
  final String description;
  final String iconUrl;
  final int humidity;
  final double windSpeed;

  Weather({
    required this.temperature,
    required this.description,
    required this.iconUrl,
    required this.humidity,
    required this.windSpeed,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      iconUrl: "https://openweathermap.org/img/wn/${json['weather'][0]['icon']}@2x.png",
      humidity: json['main']['humidity'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
    );
  }
}
