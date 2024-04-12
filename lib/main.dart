import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Future<Map<String, dynamic>> getCurrentLocationWeather(
      {required double latitude, required double longitude}) async {
    final String url =
        '$baseUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';
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

class WeatherPageState extends State<WeatherPage>
    with TickerProviderStateMixin {
  late WeatherService weatherService;
  String city = '';
  Map<String, dynamic>? weatherData;
  IconData weatherIcon = Icons.wb_sunny;
  double appBarHeight = 100.0;
  bool _locationPermissionGranted = false;
  TextEditingController _cityController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission(); // Request location permission
    _initWeatherService();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.repeat(reverse: true);
  }

  void _initWeatherService() {
    weatherService = WeatherService(widget.apiKey);
    // Call fetchWeatherData only if location permission is granted
    if (_locationPermissionGranted) {
      fetchWeatherData();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      setState(() {
        _locationPermissionGranted =
            true; // Set _locationPermissionGranted to true
      });
      _getLocationAndFetchWeather();
    } else if (status.isDenied) {
      // Handle the case when the user denies the permission
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Location Permission Denied'),
            content:
                const Text('Please grant location permission to use this app.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else if (status.isPermanentlyDenied) {
      // Handle the case when the user permanently denies the permission
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Location Permission Denied'),
            content: const Text(
                'Please enable location permissions in the device settings to use this app.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _getLocationAndFetchWeather() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      // Fetch weather data based on current location
      fetchWeatherData(
          latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void fetchWeatherData({double? latitude, double? longitude}) async {
    try {
      var data;
      if (latitude != null && longitude != null) {
        // Fetch weather data based on provided latitude and longitude
        data = await weatherService.getCurrentLocationWeather(
            latitude: latitude, longitude: longitude);
        setState(() {
          weatherData = data;
          updateWeatherIcon(data['weather'][0]['id']);
          city = data['name']; // Assign the city name from the weather data
        });
      } else {
        // Fetch weather data based on city name or current location
        String cityName = _cityController.text.trim();
        if (cityName.isNotEmpty) {
          data = await weatherService.getCurrentWeather(cityName);
          setState(() {
            weatherData = data;
            updateWeatherIcon(data['weather'][0]['id']);
            city = cityName; // Assign the city name from the user input
          });
        } else {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          data = await weatherService.getCurrentLocationWeather(
              latitude: position.latitude, longitude: position.longitude);
          setState(() {
            weatherData = data;
            updateWeatherIcon(data['weather'][0]['id']);
            city = data['name']; // Assign the city name from the weather data
          });
        }
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  void updateWeatherIcon(int weatherCode) {
    if (weatherCode >= 200 && weatherCode < 300) {
      weatherIcon = Icons.flash_on; // Thunderstorm
    } else if (weatherCode >= 300 && weatherCode < 400) {
      weatherIcon = Icons.grain; // Drizzle
    } else if (weatherCode >= 500 && weatherCode < 600) {
      weatherIcon = Icons.grain; // Rain
    } else if (weatherCode >= 600 && weatherCode < 700) {
      weatherIcon = Icons.ac_unit; // Snow
    } else if (weatherCode >= 700 && weatherCode < 800) {
      weatherIcon = Icons.cloud_circle; // Atmosphere
    } else if (weatherCode == 800) {
      weatherIcon = Icons.wb_sunny; // Clear
    } else if (weatherCode == 801) {
      weatherIcon = Icons.wb_cloudy; // Few clouds
    } else if (weatherCode == 802) {
      weatherIcon = Icons.wb_cloudy; // Scattered clouds
    } else if (weatherCode == 803 || weatherCode == 804) {
      weatherIcon = Icons.cloud; // Broken clouds or overcast clouds
    } else {
      weatherIcon = Icons.error; // Other conditions
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: appBarHeight,
            flexibleSpace: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.8),
                        Colors.blue.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20.0,
                  left: 20.0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: weatherData != null ? 1.0 : 0.0,
                    child: const Text(
                      'Weather App',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10.0,
                  right: 10.0,
                  child: RotationTransition(
                    turns: _animation,
                    child: const Icon(
                      Icons.cloud,
                      color: Colors.white,
                      size: 100.0,
                    ),
                  ),
                ),
              ],
            ),
            floating: true,
            pinned: true,
          ),
          SliverFillRemaining(
            child: Center(
              child: weatherData != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: TextField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              hintText: 'Enter city name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            fetchWeatherData();
                          },
                          child: const Text('Get Weather'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            primary: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'City: $city',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Icon(
                          weatherIcon,
                          size: 80,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Temperature: ${weatherData!['main']['temp']}°C',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.water_drop,
                              size: 30,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Humidity: ${weatherData!['main']['humidity']}%',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.thermostat,
                              size: 30,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Max Temperature: ${weatherData!['main']['temp_max']}°C',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.thermostat,
                              size: 30,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Min Temperature: ${weatherData!['main']['temp_min']}°C',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const Text('Fetching weather data...'),
            ),
          ),
        ],
      ),
    );
  }
}
