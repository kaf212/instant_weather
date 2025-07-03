import 'package:shared_preferences/shared_preferences.dart';

Future<void> writeData(String key, String value) async {
  final sharedPreferences = await SharedPreferences.getInstance();

  await sharedPreferences.setString(key, value);
}

Future<String?> readData(String key) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getString(key);
}