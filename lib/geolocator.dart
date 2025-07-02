import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


// Quelle: https://pub.dev/packages/geolocator

class Locator {
  Future<Stream<Position>> getPositionStream() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return Future.error("Location permissions have been denied");
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location permission is denied forever");
    }

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  
  }

  Future<List<Placemark>> getPlaceMark(latitude, longitude) async {
    return await placemarkFromCoordinates(latitude, longitude);
  }
}
