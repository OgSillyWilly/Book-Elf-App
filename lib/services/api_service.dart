import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../config/app_config.dart';

class BooksResponse {
  final List<Book> books;
  final int total;

  BooksResponse({required this.books, required this.total});
}

class ApiService {
  // Get API base URL from settings or AppConfig default
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString('api_base_url');
    
    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }
    
    // Use AppConfig for platform-specific URLs
    return AppConfig.apiBaseUrl;
  }
  
  // Synchronous getter for direct usage (delegates to AppConfig)
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  static const Duration timeout = Duration(seconds: 15);
  static const Duration importTimeout = Duration(seconds: 45);

  // Test of de API bereikbaar is
  Future<bool> testConnection() async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/books'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Book>> getBooks() async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/books'),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle new API response structure with data and total
        List<dynamic> data;
        if (responseData is Map && responseData.containsKey('data')) {
          data = responseData['data'];
        } else if (responseData is List) {
          // Fallback for old API response format
          data = responseData;
        } else {
          throw Exception('Onverwachte API response structuur');
        }
        
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Server antwoordde met status ${response.statusCode}');
      }
    } on TimeoutException {
      final url = await getBaseUrl();
      throw Exception('Verbinding timeout - controleer of de server draait op $url');
    } catch (e) {
      throw Exception('Verbindingsfout: ${e.toString()}');
    }
  }

  // Nieuwe methode die ook het totaal aantal resultaten retourneert
  Future<BooksResponse> getBooksWithTotal() async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/books'),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle new API response structure with data and total
        List<dynamic> data;
        int total = 0;
        
        if (responseData is Map && responseData.containsKey('data')) {
          data = responseData['data'];
          total = responseData['total'] ?? data.length;
        } else if (responseData is List) {
          // Fallback for old API response format
          data = responseData;
          total = data.length;
        } else {
          throw Exception('Onverwachte API response structuur');
        }
        
        final books = data.map((json) => Book.fromJson(json)).toList();
        return BooksResponse(books: books, total: total);
      } else {
        throw Exception('Server antwoordde met status ${response.statusCode}');
      }
    } on TimeoutException {
      final url = await getBaseUrl();
      throw Exception('Verbinding timeout - controleer of de server draait op $url');
    } catch (e) {
      throw Exception('Verbindingsfout: ${e.toString()}');
    }
  }

  Future<Book> createBook(Map<String, dynamic> bookData) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/books'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(bookData),
      ).timeout(timeout);

      if (response.statusCode == 201) {
        return Book.fromJson(json.decode(response.body));
      } else {
        throw Exception('Kon boek niet aanmaken: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Verbinding timeout - controleer of de server draait');
    }
  }

  Future<Book> updateBook(int id, Map<String, dynamic> bookData) async {
    final url = await getBaseUrl();
    try {
      final response = await http.put(
        Uri.parse('$url/books/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(bookData),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return Book.fromJson(json.decode(response.body));
      } else {
        throw Exception('Kon boek niet bijwerken: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Verbinding timeout - controleer of de server draait');
    } catch (e) {
      // Meer gedetailleerde error info voor debugging
      throw Exception('Update mislukt: ${e.toString()}\n\nURL: $url/books/$id\n\nOm dit op te lossen:\n- Open Chrome DevTools (F12)\n- Ga naar Network tab\n- Probeer opnieuw\n- Check of er een CORS error is (rood)\n\nOf gebruik een mobiele versie/emulator waar dit probleem niet optreedt.');
    }
  }

  Future<void> deleteBook(int id) async {
    try {
      final url = await getBaseUrl();
      final response = await http.delete(
        Uri.parse('$url/books/$id'),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Kon boek niet verwijderen');
      }
    } on TimeoutException {
      throw Exception('Verbinding timeout - controleer of de server draait');
    }
  }

  Future<String> importBooks(String filePath, List<int> fileBytes) async {
    try {
      final url = await getBaseUrl();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$url/books/import'),
      );
      
      request.headers['Accept'] = 'application/json';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filePath.split('/').last,
        ),
      );

      final streamedResponse = await request.send().timeout(importTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] ?? 'Boeken succesvol geïmporteerd!';
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Kon boeken niet importeren');
      }
    } on TimeoutException {
      throw Exception('Import timeout - bestand is mogelijk te groot of server reageert niet');
    }
  }

  Future<String> getTemplateUrl() async {
    final url = await getBaseUrl();
    return '$url/books/template/download';
  }

  Future<List<Book>> getBooksByYear(int year) async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/books?year_read=$year'),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Server antwoordde met status ${response.statusCode}');
      }
    } on TimeoutException {
      final url = await getBaseUrl();
      throw Exception('Verbinding timeout - controleer of de server draait op $url');
    } catch (e) {
      throw Exception('Verbindingsfout: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getReadingHistory() async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/books/reading-history'),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Server antwoordde met status ${response.statusCode}');
      }
    } on TimeoutException {
      final url = await getBaseUrl();
      throw Exception('Verbinding timeout - controleer of de server draait op $url');
    } catch (e) {
      throw Exception('Verbindingsfout: ${e.toString()}');
    }
  }
}
