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
  await getForecast();
}

  Future<Position> getLocationStream() async {
  final stream = await locator.getPositionStream();
  final firstPosition = await stream.first;

  setState(() {
    currentCoordinates = firstPosition;
  });

  getNameOfPlaceByCoordinates(currentCoordinates);

  return firstPosition;
}

  Future<Map<String, dynamic>> getForecast() async {
    final weatherForecast = await weather.fetchWeatherData(currentCoordinates?.latitude, currentCoordinates?.longitude);
    //print("WeatherForecast in getForecast() =");
    //print(weatherForecast);
    final symbolCodes = weather.processWeatherData(weatherForecast);
    setState(() {
      forecast = symbolCodes;
    });

    return weatherForecast;
  }

  void writeForecastToUI(symbolCodes) {
    
  }

  void getNameOfPlaceByCoordinates(coordinates) {
    locator.getPlaceMark(currentCoordinates?.latitude, currentCoordinates?.longitude).then((placemarks) {
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
    return Wrap(
      children: [
        Text("$symbolCodes")
      ],
    );
  }
}

