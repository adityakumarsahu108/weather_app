import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  final String apiKey;
  final String baseUrl = "https://api.openweathermap.org/data/2.5/weather";

  WeatherService(this.apiKey);

  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    final String url = '$baseUrl?q=$city&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WeatherPage(
          apiKey:
              '1237c4ecf6497c0e0740a6e13c41315a'), // Replace with your actual API key
    );
  }
}

class WeatherPage extends StatefulWidget {
  final String apiKey;

  const WeatherPage({Key? key, required this.apiKey}) : super(key: key);

  @override
  WeatherPageState createState() => WeatherPageState();
}

class WeatherPageState extends State<WeatherPage> {
  late WeatherService weatherService;
  String city = 'bengaluru'; // Default city
  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    weatherService = WeatherService(widget.apiKey);
    fetchWeatherData();
  }

  void fetchWeatherData() async {
    try {
      var data = await weatherService.getCurrentWeather(city);
      setState(() {
        weatherData = data;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather App')),
      body: Center(
        child: weatherData != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'City: $city',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Temperature: ${weatherData!['main']['temp']}°C',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Description: ${weatherData!['weather'][0]['description']}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Humidity: ${weatherData!['main']['humidity']}%',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Max Temperature: ${weatherData!['main']['temp_max']}°C',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Min Temperature: ${weatherData!['main']['temp_min']}°C',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              )
            : const Text('Fetching weather data...'),
      ),
    );
  }
}
