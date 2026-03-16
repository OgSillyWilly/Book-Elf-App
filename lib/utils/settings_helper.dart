import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class SettingsHelper {
  /// Load the current API base URL from preferences
  static Future<String> loadApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ?? AppConfig.apiBaseUrl;
  }

  /// Save the API base URL to preferences
  static Future<void> saveApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  /// Load the Google Books API key from preferences
  static Future<String?> loadGoogleBooksApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('google_books_api_key');
  }

  /// Save the Google Books API key to preferences
  /// If key is empty, removes the stored key
  static Future<void> saveGoogleBooksApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key.isEmpty) {
      await prefs.remove('google_books_api_key');
    } else {
      await prefs.setString('google_books_api_key', key);
    }
  }
}
