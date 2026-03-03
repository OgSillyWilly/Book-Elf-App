import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl {
    // Auto-detect platform and return appropriate API URL
    if (kIsWeb) {
      // Web/Chrome - use localhost
      return dotenv.get('API_BASE_URL_WEB', fallback: 'http://127.0.0.1:8000/api');
    } else {
      // Mobile (iOS/Android) - use local network IP
      return dotenv.get('API_BASE_URL_MOBILE', fallback: 'http://10.242.187.102:8000/api');
    }
  }

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // If .env file doesn't exist, use defaults
      if (kDebugMode) {
        print('Warning: .env file not found, using default API URLs');
      }
    }
  }
}
