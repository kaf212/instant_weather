import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:instant_weather/geolocator.dart';
import 'package:instant_weather/weather.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final locator = Locator();
  final weather = Weather();
  StreamSubscription<Position>? positionSubscription;
  Position? currentCoordinates;
  String? currentPlace;
  Map<String, dynamic>? forecast;

  @override
  void initState() {
    super.initState();
      initialize();
  }

  void initialize() async {
  await getLocationStream();
}

  Future<void> getLocationStream() async {
  final stream = await locator.getPositionStream();
 positionSubscription = stream.listen((Position newPosition) {
  setState(() {
    currentCoordinates = newPosition;
  });
  getNameOfPlaceByCoordinates(newPosition);
  getForecast(newPosition);
});
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> getForecast(Position position) async {
  final weatherForecast = await weather.fetchWeatherData(position.latitude, position.longitude);
  final symbolCodes = weather.processWeatherData(weatherForecast);
  setState(() {
    forecast = symbolCodes;
  });
  return weatherForecast;
}

  void getNameOfPlaceByCoordinates(coordinates) {
    locator.getPlaceMark(coordinates.latitude, coordinates.longitude).then((placemarks) {
      setState(() {
        final locality = placemarks.first.locality;
        final name = placemarks.first.name;
        //print(placemarks.first);
        if (locality != "") {
          currentPlace = locality;
        } else {
          currentPlace = name;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$currentPlace',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
                SizedBox(height: 20),
            buildWeatherForecast(),
          ],
        ),
      ),
    );
  }

  Widget buildWeatherForecast() {
    final symbolCodes = forecast;
    final next1h = symbolCodes?["next_1_hours"];
    final next6h = symbolCodes?["next_6_hours"];
    final next12h = symbolCodes?["next_12_hours"];

    return Wrap(
      children: [
        Row(children: [
          Column(children: [
            Text("Nächste Stunde"), 
            Row(children: [
              Text("$next1h"),
              buildWeatherIcon(next1h)
            ],)
          ],)
        ],),
        Row(children: [
          Column(children: [
            Text("Nächste 6 Stunden"), 
            Row(children: [
              Text("$next6h"),
              buildWeatherIcon(next6h)
            ],)
          ],)
        ],),
        Row(children: [
          Column(children: [
            Text("Nächste 12 Stunden"), 
            Row(children: [
              Text("$next12h"),
              buildWeatherIcon(next12h)
            ],)
          ],)
        ],)
      ],
    );
  }

  Widget buildWeatherIcon(String? code) {
  if (code == null || code.isEmpty) return SizedBox.shrink();
  final path = 'assets/weather_icons/$code.png';
  return Image.asset(
    path,
    width: 80,
    height: 80,
    errorBuilder: (context, error, stackTrace) {
      return SizedBox.shrink();
    },
  );
}
}

