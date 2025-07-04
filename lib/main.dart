import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:instant_weather/geolocator.dart';
import 'package:instant_weather/storage.dart';
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
  Map<String, dynamic>? currentWeatherChanges;

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
    checkForWeatherChanges();
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

  Future<void> checkForWeatherChanges() async {
    final persistentStorage = PersistentStorage();
    
    final savedTemperature = await persistentStorage.readData("temperature");
    final savedHumidity = await persistentStorage.readData("humidity");
    final savedPressure = await persistentStorage.readData("pressure");

    final currentWeatherData = forecast?["now"]["data"]["instant"]["details"];
    final changes = {"temperature": 0.0, "humidity": 0.0, "pressure": 0.0};

    final currentTemperature = currentWeatherData["air_temperature"];
    final currentHumidity = currentWeatherData["relative_humidity"];
    final currentPressure = currentWeatherData['air_pressure_at_sea_level'];

    if (savedTemperature != null && savedHumidity != null && savedPressure != null) {

      if (savedTemperature != currentTemperature) {
        changes["temperature"] = double.parse(
          (currentTemperature - double.parse(savedTemperature)).toStringAsFixed(1)
          );
      }
      if (savedHumidity != currentHumidity) {
        changes["humidity"] = double.parse(
          (currentHumidity - double.parse(savedHumidity)).toStringAsFixed(1)
          );
      }
      if (savedPressure != currentPressure) {
        changes["pressure"] = double.parse(
          (currentPressure - double.parse(savedPressure)).toStringAsFixed(1)
          ); 
      }
    }

    persistentStorage.writeData("temperature", currentTemperature.toString());
    persistentStorage.writeData("humidity", currentHumidity.toString());
    persistentStorage.writeData("pressure", currentPressure.toString());

    currentWeatherChanges = changes;

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
            SizedBox(height: 20,),
            buildCurrentWeather(),
            SizedBox(height: 20),
            buildWeatherForecast(),
          ],
        ),
      ),
    );
  }

  Widget buildCurrentWeather() {
    if (forecast == null) {
      return Row(children: [
        Text("Loading weather data...")
      ],);
    }

    final currentWeatherData = forecast?["now"]["data"]["instant"]["details"];

    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Row(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey,
              child: Column(
                children: [
                  Text("Luftfeuchtigkeit"),
                  Text("${currentWeatherData['relative_humidity']}%",
                    style: TextStyle(fontSize: 35)),
                  Text(
                    currentWeatherChanges?["humidity"] != null && currentWeatherChanges!["humidity"] != 0
                        ? "${currentWeatherChanges!["humidity"] > 0 ? '+' : ''}${currentWeatherChanges!["humidity"]}"
                        : "",
                  )
                ],
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Container(
              color: Colors.grey,
              child: Column(
                children: [
                  Text("Temperatur"),
                  Text("${currentWeatherData['air_temperature']}°C",
                    style: TextStyle(fontSize: 35)),
                  Text(
                    currentWeatherChanges?["temperature"] != null && currentWeatherChanges!["temperature"] != 0
                        ? "${currentWeatherChanges!["temperature"] > 0 ? '+' : ''}${currentWeatherChanges!["temperature"]}"
                        : "",
                  )
                ],
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Container(
              color: Colors.grey,
              child: Column(
                children: [
                  Text("Luftdruck (hPa)"),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "${currentWeatherData['air_pressure_at_sea_level'].round()}",
                            style: TextStyle(fontSize: 35),
                        ),
                      Text(
                        currentWeatherChanges?["pressure"] != null && currentWeatherChanges!["pressure"] != 0
                            ? "${currentWeatherChanges!["pressure"] > 0 ? '+' : ''}${currentWeatherChanges!["pressure"]}"
                            : "",
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWeatherForecast() {
    final next1hForecast = forecast?["1h"];
    final next6hForecast = forecast?["6h"];
    final next12hForecast = forecast?["12h"];

    return Column(
      children: [
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Necessary
            children: [
            Container(
              color: Colors.grey,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                children: [
                Text("Nächste Stunde"), 
                buildForecastItem(next1hForecast)
                        
              ],),
            )
          ],),
        ),
        SizedBox(height: 15),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Necessary
            children: [
            Container(
              color: Colors.grey,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(children: [
                Text("Nächste 6 Stunden"), 
                buildForecastItem(next6hForecast)
              ],),
            )
          ],),
        ),
        SizedBox(height: 15),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Necessary
            children: [
            Container(
              color: Colors.grey,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(children: [
                Text("Nächste 12 Stunden"), 
                buildForecastItem(next12hForecast)
              ],),
            )
          ],),
        )
        ],);
  }

  Widget buildForecastItem(Map<String, dynamic> ?forecast) {
    if (forecast == null) {
      return Row(children: [
        Text("Loading weather data...")
      ],);
    }

    final forecastData = forecast["data"]["instant"]["details"];
    final symbolCode = forecast["data"]["next_1_hours"]["summary"]["symbol_code"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
      SizedBox(width: 10),
      Text("${forecastData["air_temperature"].toString()}°C", style: TextStyle(fontSize: 20),),

      SizedBox(width: 5),
      Text("|", style: TextStyle(fontSize: 20),),
      SizedBox(width: 5),

      Text("${forecastData["relative_humidity"].toString()} %", style: TextStyle(fontSize: 20),),

      SizedBox(width: 5),
      Text("|", style: TextStyle(fontSize: 20),),
      SizedBox(width: 5),

      Text("${forecastData["air_pressure_at_sea_level"].toString()} hPa",  style: TextStyle(fontSize: 20),),
      Spacer(),
      buildWeatherIcon(symbolCode),
      SizedBox(width: 10)
    ],);
  }

  Widget buildWeatherIcon(String symbolCode) {
    final path = 'assets/weather_icons/$symbolCode.png';
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

