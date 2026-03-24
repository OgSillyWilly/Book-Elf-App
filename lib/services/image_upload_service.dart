import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageUploadService {
  static String get _baseUrl => dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';

  // Determine mime type from filename
  static String _getMimeType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg'; // fallback
    }
  }

  // Upload from File (mobile/desktop)
  static Future<String?> uploadBookCover(int bookId, File imageFile) async {
    if (kIsWeb) {
      throw Exception('Use uploadBookCoverFromBytes for web platform');
    }

    try {
      final uri = Uri.parse('$_baseUrl/books/$bookId/cover');
      
      var request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers['Accept'] = 'application/json';
      
      // Read file as bytes and use fromBytes instead of fromPath
      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.path.split('/').last;
      final mimeType = _getMimeType(filename);
      final mediaType = MediaType.parse(mimeType);
      
      request.files.add(http.MultipartFile.fromBytes(
        'cover',
        bytes,
        filename: filename,
        contentType: mediaType,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Construeer de volledige URL
        final coverPath = responseData['cover_url'] as String;
        final baseApiUrl = Uri.parse(_baseUrl);
        final fullUrl = '${baseApiUrl.scheme}://${baseApiUrl.host}:${baseApiUrl.port}$coverPath';
        
        return fullUrl;
      } else {
        throw Exception('Upload failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload cover: $e');
    }
  }

  // Upload from bytes (web platform)
  static Future<String?> uploadBookCoverFromBytes(int bookId, Uint8List imageBytes, String filename) async {
    try {
      final uri = Uri.parse('$_baseUrl/books/$bookId/cover');
      
      var request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers['Accept'] = 'application/json';
      
      final mimeType = _getMimeType(filename);
      final mediaType = MediaType.parse(mimeType);
      
      request.files.add(http.MultipartFile.fromBytes(
        'cover',
        imageBytes,
        filename: filename,
        contentType: mediaType,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Construeer de volledige URL
        final coverPath = responseData['cover_url'] as String;
        final baseApiUrl = Uri.parse(_baseUrl);
        final fullUrl = '${baseApiUrl.scheme}://${baseApiUrl.host}:${baseApiUrl.port}$coverPath';
        
        return fullUrl;
      } else {
        throw Exception('Upload failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload cover: $e');
    }
  }

  static Future<void> deleteBookCover(int bookId) async {
    try {
      final uri = Uri.parse('$_baseUrl/books/$bookId/cover');
      
      final response = await http.delete(uri);

      if (response.statusCode != 200) {
        throw Exception('Delete failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete cover: $e');
    }
  }
}
