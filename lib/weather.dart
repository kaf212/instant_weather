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

      final url = Uri.parse("https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=$lat&lon=$lon");
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

    final next1h = weatherJson['properties']['timeseries'][0]['data']['next_1_hours']['summary']['symbol_code'];
    final next6h = weatherJson['properties']['timeseries'][0]['data']['next_6_hours']['summary']['symbol_code'];
    final next12h = weatherJson['properties']['timeseries'][0]['data']['next_12_hours']['summary']['symbol_code'];
    
    final symbolCodes = {
      "next_1_hours": next1h,
      "next_6_hours": next6h,
      "next_12_hours": next12h
    };

    return symbolCodes;
  }
}