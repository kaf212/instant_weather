import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityChecker {

  Future<bool> hasInternetConnection() async {
    var connectivityResults = await Connectivity().checkConnectivity();
    return connectivityResults.isNotEmpty &&
      !connectivityResults.contains(ConnectivityResult.none);
  }

}