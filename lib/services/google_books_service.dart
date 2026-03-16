import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleBooksSearchResult {
  final List<Map<String, dynamic>> books;
  final int totalAvailable;
  
  GoogleBooksSearchResult({
    required this.books,
    required this.totalAvailable,
  });
}

class GoogleBooksService {
  static const int resultsPerRequest = 40;
  static const int maxTotalResults = 200;
  static const int maxPages = 10;
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration delayBetweenRequests = Duration(milliseconds: 100);

  /// Search Google Books API with pagination
  Future<GoogleBooksSearchResult> searchBooks({
    required String query,
    String searchType = 'title',
    String language = 'nl',
    String? authorForCombo,
  }) async {
    // Laad API key indien beschikbaar
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('google_books_api_key');
    
    final allResults = <Map<String, dynamic>>[];
    int pageCount = 0;
    int? totalAvailable;
    
    // Bouw de juiste query op basis van zoektype
    final searchQuery = _buildSearchQuery(
      query: query,
      searchType: searchType,
      authorForCombo: authorForCombo,
    );
    
    // Loop door pagina's om alle beschikbare resultaten op te halen
    while (allResults.length < maxTotalResults && pageCount < maxPages) {
      final startIndex = pageCount * resultsPerRequest;
      
      // Bouw URL met optionele API key
      final url = _buildUrl(
        searchQuery: searchQuery,
        language: language,
        startIndex: startIndex,
        apiKey: apiKey,
      );
      
      try {
        final response = await http.get(url).timeout(requestTimeout);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data['items'] as List<dynamic>?;
          
          // Haal het totaal aantal beschikbare resultaten op (eerste keer)
          if (totalAvailable == null && data['totalItems'] != null) {
            totalAvailable = data['totalItems'] as int;
          }
          
          // Voeg resultaten toe
          if (items != null && items.isNotEmpty) {
            allResults.addAll(items.cast<Map<String, dynamic>>());
            pageCount++;
            
            // Als we alle beschikbare resultaten hebben opgehaald
            if (totalAvailable != null && allResults.length >= totalAvailable) {
              break;
            }
            
            // Kleine pauze tussen requests om rate limiting te vermijden
            if (pageCount < maxPages) {
              await Future.delayed(delayBetweenRequests);
            }
          } else {
            // Geen items in deze response, stop
            break;
          }
        } else if (response.statusCode == 429) {
          // Rate limit bereikt
          throw GoogleBooksQuotaException('Google Books dagelijks quota bereikt');
        } else if (response.statusCode == 503) {
          throw GoogleBooksServiceException('Google Books tijdelijk niet beschikbaar');
        } else {
          throw GoogleBooksException('Onverwachte status code: ${response.statusCode}');
        }
      } catch (e) {
        if (e is GoogleBooksException) {
          rethrow;
        }
        // Re-throw met meer context
        throw GoogleBooksException('Fout bij zoeken: $e');
      }
    }
    
    return GoogleBooksSearchResult(
      books: allResults,
      totalAvailable: totalAvailable ?? allResults.length,
    );
  }

  String _buildSearchQuery({
    required String query,
    required String searchType,
    String? authorForCombo,
  }) {
    switch (searchType) {
      case 'title':
        // Voor korte titels (< 3 tekens) of algemene woorden, combineer met auteur indien beschikbaar
        if (query.length <= 2 || ['it', 'if', 'go', 'on'].contains(query.toLowerCase())) {
          if (authorForCombo != null && authorForCombo.isNotEmpty) {
            // Combineer titel + auteur voor betere resultaten
            return 'intitle:${Uri.encodeComponent(query)}+inauthor:${Uri.encodeComponent(authorForCombo)}';
          } else {
            // Als geen auteur, gebruik algemene zoekterm
            return Uri.encodeComponent(query);
          }
        } else {
          return 'intitle:${Uri.encodeComponent(query)}';
        }
      case 'author':
        return 'inauthor:${Uri.encodeComponent(query)}';
      case 'isbn':
        return 'isbn:${Uri.encodeComponent(query)}';
      case 'all':
      default:
        return Uri.encodeComponent(query);
    }
  }

  Uri _buildUrl({
    required String searchQuery,
    required String language,
    required int startIndex,
    String? apiKey,
  }) {
    var urlString = 'https://www.googleapis.com/books/v1/volumes?'
        'q=$searchQuery&'
        'langRestrict=$language&'
        'maxResults=$resultsPerRequest&'
        'startIndex=$startIndex';
    
    if (apiKey != null && apiKey.isNotEmpty) {
      urlString += '&key=$apiKey';
    }
    
    return Uri.parse(urlString);
  }

  /// Extract book data from Google Books API response
  Map<String, dynamic> extractBookData(Map<String, dynamic> book) {
    final volumeInfo = book['volumeInfo'] as Map<String, dynamic>;
    
    final authors = volumeInfo['authors'] as List<dynamic>?;
    final identifiers = volumeInfo['industryIdentifiers'] as List<dynamic>?;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    
    String? isbn;
    if (identifiers != null && identifiers.isNotEmpty) {
      isbn = identifiers.first['identifier'] as String?;
    }
    
    String? coverUrl;
    final rawCoverUrl = imageLinks?['thumbnail'] ?? imageLinks?['smallThumbnail'];
    if (rawCoverUrl is String) {
      // Zorg dat het HTTPS is en verwijder edge curl parameter voor betere kwaliteit
      var cleanUrl = rawCoverUrl.replaceFirst('http://', 'https://');
      cleanUrl = cleanUrl.replaceAll('&edge=curl', '');
      cleanUrl = cleanUrl.replaceAll('edge=curl', '');
      coverUrl = cleanUrl;
    }
    
    return {
      'title': volumeInfo['title'] as String? ?? '',
      'author': authors?.join(', ') ?? '',
      'isbn': isbn,
      'publisher': volumeInfo['publisher'] as String?,
      'publishedDate': volumeInfo['publishedDate'] as String?,
      'coverUrl': coverUrl,
    };
  }
}

// Custom exceptions for better error handling
class GoogleBooksException implements Exception {
  final String message;
  GoogleBooksException(this.message);
  
  @override
  String toString() => message;
}

class GoogleBooksQuotaException extends GoogleBooksException {
  GoogleBooksQuotaException(super.message);
}

class GoogleBooksServiceException extends GoogleBooksException {
  GoogleBooksServiceException(super.message);
}
