import 'dart:convert';
import 'package:http/http.dart' as http;


class Weather {

    Future fetchWeatherData(latitude, longitude) async {
      if (latitude == null || longitude == null) {
        print("Received null coordinates, exiting forecast function.");
        return null;
      }
      
      final lat = double.parse(latitude.toStringAsFixed(4));
      final lon = double.parse(longitude.toStringAsFixed(4));

      final url = Uri.parse("https://api.met.no/weatherapi/locationforecast/2.0/complete?lat=$lat&lon=$lon");
      final response = await http.get(
      url,
      headers: {"User-Agent": "InstantWeather/1.0"}
      );

    //print("WEATHER DATA = ");
    //print(jsonDecode(response.body));
    return jsonDecode(response.body);
  }

  Map<String, dynamic> processWeatherData(weatherJson) {
    if (weatherJson == null) {
      print("Tried processing null weather JSON");
    }

    final next1hSymbolCode = weatherJson['properties']['timeseries'][0]['data']['next_1_hours']['summary']['symbol_code'];
    final next6hSymbolCode = weatherJson['properties']['timeseries'][0]['data']['next_6_hours']['summary']['symbol_code'];
    final next12hSymbolCode = weatherJson['properties']['timeseries'][0]['data']['next_12_hours']['summary']['symbol_code'];

    final next1hDetails = weatherJson['properties']['timeseries'][0]['data']['next_1_hours']['details'];
    final next6hDetails = weatherJson['properties']['timeseries'][0]['data']['next_6_hours']['details'];
    final next12hDetails = weatherJson['properties']['timeseries'][0]['data']['next_12_hours']['details'];
    
    final symbolCodes = {
      "next_1_hours": {
        "symbolCode": next1hSymbolCode, 
        "temp_min": next1hDetails["air_temperature_min"],
        "temp_max": next1hDetails["air_temperature_max"],
        "precipitation": next1hDetails["precipitation_amount"]
        },
      "next_6_hours": {
        "symbolCode": next6hSymbolCode, 
        "temp_min": next6hDetails["air_temperature_min"],
        "temp_max": next6hDetails["air_temperature_max"],
        "precipitation": next6hDetails["precipitation_amount"]
        },
      "next_12_hours": {
        "symbolCode": next12hSymbolCode, 
        "temp_min": next12hDetails["air_temperature_min"],
        "temp_max": next12hDetails["air_temperature_max"],
        "precipitation": next12hDetails["precipitation_amount"]
        },
    };

    return symbolCodes;
  }
}