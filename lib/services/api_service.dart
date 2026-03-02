import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class ApiService {
  static String? _cachedBaseUrl;
  
  // Automatisch kiezen tussen localhost (web) en netwerk IP (mobiel)
  static Future<String> getBaseUrl() async {
    // Check for custom URL from settings
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString('api_base_url');
    
    if (customUrl != null && customUrl.isNotEmpty) {
      _cachedBaseUrl = customUrl;
      return customUrl;
    }
    
    // Default URLs
    if (kIsWeb) {
      // Web/Chrome: gebruik localhost
      _cachedBaseUrl = 'http://127.0.0.1:8000/api';
    } else {
      // iPhone/Android: gebruik netwerk IP
      // Pas dit aan naar je Mac IP adres (check met: ifconfig | grep "inet ")
      _cachedBaseUrl = 'http://10.242.187.102:8000/api';
    }
    
    return _cachedBaseUrl!;
  }
  
  // Voor backwards compatibility en direct gebruik waar nodig
  static String get baseUrl {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    return kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.242.187.102:8000/api';
  }
  
  static const Duration timeout = Duration(seconds: 15);
  static const Duration importTimeout = Duration(seconds: 45);

  // Test of de API bereikbaar is
  Future<bool> testConnection() async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/books'),
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

  Future<Book> createBook(Map<String, dynamic> bookData) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/books'),
        headers: {'Content-Type': 'application/json'},
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
    try {
      final url = await getBaseUrl();
      final response = await http.put(
        Uri.parse('$url/books/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bookData),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return Book.fromJson(json.decode(response.body));
      } else {
        throw Exception('Kon boek niet bijwerken: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Verbinding timeout - controleer of de server draait');
    }
  }

  Future<void> deleteBook(int id) async {
    try {
      final url = await getBaseUrl();
      final response = await http.delete(
        Uri.parse('$url/books/$id'),
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
}
