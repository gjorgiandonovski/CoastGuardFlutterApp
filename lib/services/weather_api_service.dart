import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherApiService {
  final String _apiKey = "47167969439670b9e4f97e03d85ebfb4";

  Future<Weather?> getWeather(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return Weather.fromJson(json.decode(response.body));
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception fetching weather: $e');
      return null;
    }
  }
}
