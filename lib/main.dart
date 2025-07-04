import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:instant_weather/connectivity.dart';
import 'package:instant_weather/geolocator.dart';
import 'package:instant_weather/storage.dart';
import 'package:instant_weather/weather.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';


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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color.fromARGB(255, 119, 209, 251),
        
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
  final connectivityChecker = ConnectivityChecker();

  StreamSubscription<Position>? positionSubscription;
  Position? currentCoordinates;
  String? currentPlace;
  Map<String, dynamic>? forecast;
  Map<String, dynamic>? currentWeatherChanges;
  String? date;

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
    final isConnectedToInternet = await connectivityChecker.hasInternetConnection();

    Map<String, dynamic> weatherForecast = {};
    Map<String, dynamic> symbolCodes = {};

    if (isConnectedToInternet) {
      weatherForecast = await weather.fetchWeatherData(position.latitude, position.longitude);
      symbolCodes = weather.processWeatherData(weatherForecast);
    }

    await initializeDateFormatting('de_DE', null);
    final formattedDate = DateFormat("EEEE, d. MMMM y", "de_DE").format(DateTime.now());

    setState(() {
      date = formattedDate;
      if (isConnectedToInternet) {
        forecast = symbolCodes;
      }
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
        backgroundColor: Colors.blueAccent,
        title: Row(
          children: [
            Text(
              "InstantWeather",
              style: TextStyle(fontSize: 30, color: Colors.white),
              
            ),
          ],
          ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '${currentPlace == null ? "Daten werden geladen..." : currentPlace}',
              style: TextStyle(fontSize: 40),
            ),
            Text(
              "${date == null ? "Daten werden geladen..." : date}",
              style: TextStyle(fontSize: 20)
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
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Text("Daten werden geladen...")
      ],);
    }

    final currentWeatherData = forecast?["now"]["data"]["instant"]["details"];

    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Row(
        children: [
          Expanded(
            child: Container(
              //color: Colors.white,
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
              //color: Colors.white,
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
              //color: Colors.white,
              child: Column(
                children: [
                  Text("Luftdruck (hPa)"),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
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
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
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
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
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
        Text("Daten werden geladen...")
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

