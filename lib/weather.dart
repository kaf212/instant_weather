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

  Map<String, dynamic> processWeatherData(Map<String, dynamic> weatherJson) {
    final timeSeries = weatherJson["properties"]["timeseries"];
    final now = DateTime.now();
    final timeIn1h = now.add(Duration(hours: 1));
    final timeIn6h = now.add(Duration(hours: 6));
    final timeIn12h = now.add(Duration(hours: 12));


    var closestForecastTimestampNow = {"difference": Duration(days: 1000), "closestIndex": 0};
    var closestForecastTimestamp1h = {"difference": Duration(days: 1000), "closestIndex": 0};
    var closestForecastTimestamp6h = {"difference": Duration(days: 1000), "closestIndex": 0};
    var closestForecastTimestamp12h = {"difference": Duration(days: 1000), "closestIndex": 0};

    //print("time in 1 hour = $timeIn1h");
    //print("time in 6 hour = $timeIn6h");
    //print("time in 12 hour = $timeIn12h");

    var i = 0;

    timeSeries.forEach((forecastObject) {
      final forecastTimeUTC = DateTime.parse(forecastObject["time"]);
      final forecastTimeLocal = forecastTimeUTC.toLocal();

      print("$i: $forecastTimeLocal");
      
      final differenceNow = forecastTimeLocal.difference(now);
      final difference1h = forecastTimeLocal.difference(timeIn1h);
      final difference6h = forecastTimeLocal.difference(timeIn6h);
      final difference12h = forecastTimeLocal.difference(timeIn12h);

      if (differenceNow.abs().compareTo((closestForecastTimestampNow["difference"] as Duration).abs()) < 0) {        
        closestForecastTimestampNow["difference"] = differenceNow;
        closestForecastTimestampNow["closestIndex"] = i;
      }
      if (difference1h.abs().compareTo((closestForecastTimestamp1h["difference"] as Duration).abs()) < 0) {        
        closestForecastTimestamp1h["difference"] = difference1h;
        closestForecastTimestamp1h["closestIndex"] = i;
      }
      if (difference6h.abs().compareTo((closestForecastTimestamp6h["difference"] as Duration).abs()) < 0) {        
        closestForecastTimestamp6h["difference"] = difference6h;
        closestForecastTimestamp6h["closestIndex"] = i;
      }
      if (difference12h.abs().compareTo((closestForecastTimestamp12h["difference"] as Duration).abs()) < 0) {        
        closestForecastTimestamp12h["difference"] = difference12h;
        closestForecastTimestamp12h["closestIndex"] = i;
      }

      i++;

    });
    
    print(closestForecastTimestampNow);
    //print(closestForecastTimestamp1h);
    //print(closestForecastTimestamp6h);
    //print(closestForecastTimestamp12h);

    final closestForecastNow = timeSeries[closestForecastTimestampNow["closestIndex"]];
    final closestForecast1h = timeSeries[closestForecastTimestamp1h["closestIndex"]];
    final closestForecast6h = timeSeries[closestForecastTimestamp6h["closestIndex"]];
    final closestForecast12h = timeSeries[closestForecastTimestamp12h["closestIndex"]];

    //print(closestForecast1h);
    //print(closestForecast6h);
    //print(closestForecast12h);

    return {
      "now": closestForecastNow,
      "1h": closestForecast1h,
      "6h": closestForecast6h,
      "12h": closestForecast12h
      };

  }
}