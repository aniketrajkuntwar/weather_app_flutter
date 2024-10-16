import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() => runApp(WeatherApp());

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF1B1E23), // Dark theme background
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final String apiKey = 'YOUR_API_KEY'; // Replace with your API key
  final String city = 'Pune'; // Set your city
  Map<String, dynamic> weatherData = {};
  bool isLoading = true;
  bool showWeekly = false;

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=pune&appid=3a0a4a0162b159d9f35bf607b276edf1&units=metric'));

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        print(
            'Failed to load weather data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: weatherData.isEmpty || weatherData['list'] == null
                    ? Center(child: Text('Failed to load weather data'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          SizedBox(height: 20),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildCurrentWeatherCard(),
                                  SizedBox(height: 20),
                                  showWeekly
                                      ? _buildWeeklyForecast()
                                      : _buildHourlyForecast(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          city,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          DateFormat('d MMMM, EEEE').format(DateTime.now()),
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () {
            setState(() {
              showWeekly = !showWeekly;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCurrentWeatherCard() {
    final currentWeather = weatherData['list'][0];
    final temp = currentWeather['main']['temp'].round();
    final condition = currentWeather['weather'][0]['main'];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF292D36), // Dark card background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$temp°',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                children: [
                  _getWeatherIcon(condition),
                  SizedBox(height: 10),
                  Text(
                    condition,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildWeatherDetails(currentWeather),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails(Map<String, dynamic> weather) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDetailItem(Icons.air, '${weather['wind']['speed'].round()} m/s'),
        _buildDetailItem(Icons.water_drop, '${weather['main']['humidity']}%'),
        _buildDetailItem(
            Icons.umbrella, '${((weather['pop'] ?? 0) * 100).round()}% Rain'),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hourly Forecast',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 8,
            itemBuilder: (context, index) {
              final hourlyWeather = weatherData['list'][index];
              final time = DateTime.fromMillisecondsSinceEpoch(
                  hourlyWeather['dt'] * 1000);
              final temp = hourlyWeather['main']['temp'].round();
              final condition = hourlyWeather['weather'][0]['main'];

              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Text(DateFormat('ha').format(time),
                        style: TextStyle(color: Colors.grey)),
                    _getWeatherIcon(condition, size: 30),
                    SizedBox(height: 8),
                    Text('$temp°', style: TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Forecast',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: 7,
          itemBuilder: (context, index) {
            final dailyWeather = weatherData['list'][index * 8];
            final date =
                DateTime.fromMillisecondsSinceEpoch(dailyWeather['dt'] * 1000);
            final tempMin = dailyWeather['main']['temp_min'].round();
            final tempMax = dailyWeather['main']['temp_max'].round();
            final condition = dailyWeather['weather'][0]['main'];

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE').format(date),
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Row(
                    children: [
                      _getWeatherIcon(condition, size: 24),
                      SizedBox(width: 8),
                      Text('$tempMin° / $tempMax°',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _getWeatherIcon(String condition, {double size = 64}) {
    IconData iconData;
    switch (condition.toLowerCase()) {
      case 'clear':
        iconData = Icons.wb_sunny;
        break;
      case 'clouds':
        iconData = Icons.cloud;
        break;
      case 'rain':
        iconData = Icons.grain;
        break;
      case 'thunderstorm':
        iconData = Icons.flash_on;
        break;
      default:
        iconData = Icons.cloud;
    }
    return Icon(iconData, size: size, color: Colors.white);
  }
}
