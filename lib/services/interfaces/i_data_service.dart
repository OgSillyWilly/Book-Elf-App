import '../../models/book.dart';
import '../../models/series.dart';
import '../../models/reading_challenge.dart';

/// Response wrapper for paginated books
class BooksResponse {
  final List<Book> books;
  final int total;

  BooksResponse({required this.books, required this.total});
}

/// Single interface for all data operations
/// Can be implemented by API service or local database service
abstract class IDataService {
  // ==================== CONNECTION ====================
  
  /// Test if the service is available/reachable
  Future<bool> testConnection();
  
  // ==================== BOOKS ====================
  
  /// Get all books
  Future<List<Book>> getBooks();
  
  /// Get books with total count
  Future<BooksResponse> getBooksWithTotal();
  
  /// Get a single book by ID
  Future<Book> getBook(int id);
  
  /// Create a new book
  Future<Book> createBook(Map<String, dynamic> bookData);
  
  /// Update an existing book
  Future<Book> updateBook(int id, Map<String, dynamic> bookData);
  
  /// Delete a book
  Future<void> deleteBook(int id);
  
  /// Import books from file
  Future<String> importBooks(String filePath, List<int> fileBytes);
  
  /// Get template download URL
  Future<String> getTemplateUrl();
  
  /// Get books read in a specific year
  Future<List<Book>> getBooksByYear(int year);
  
  /// Get reading history grouped by year
  Future<List<Map<String, dynamic>>> getReadingHistory();
  
  // ==================== SERIES ====================
  
  /// Get all series with optional search filter
  Future<List<Series>> getSeries({String? search});
  
  /// Get a series with progress information and books
  Future<Map<String, dynamic>> getSeriesWithProgress(int id);
  
  /// Create a new series
  Future<Series> createSeries(Map<String, dynamic> seriesData);
  
  /// Update an existing series
  Future<Series> updateSeries(int id, Map<String, dynamic> seriesData);
  
  /// Delete a series
  Future<void> deleteSeries(int id);
  
  // ==================== READING CHALLENGES ====================
  
  /// Get all reading challenges
  Future<List<ReadingChallenge>> getReadingChallenges();
  
  /// Get the currently active challenge (if any)
  Future<ReadingChallenge?> getActiveChallenge();
  
  /// Get challenge with detailed progress and books
  Future<Map<String, dynamic>> getChallengeWithDetails(int id);
  
  /// Get book suggestions for a challenge
  Future<Map<String, dynamic>> getChallengeSuggestions(int challengeId, {int limit = 10});
  
  /// Create a new reading challenge
  Future<ReadingChallenge> createChallenge(Map<String, dynamic> challengeData);
  
  /// Update an existing challenge
  Future<ReadingChallenge> updateChallenge(int id, Map<String, dynamic> challengeData);
  
  /// Delete a challenge
  Future<void> deleteChallenge(int id);
  
  // ==================== STATISTICS ====================
  
  /// Get overview statistics (totals, reading progress, etc.)
  Future<Map<String, dynamic>> getStatisticsOverview();
  
  /// Get reading patterns for a specific year
  Future<Map<String, dynamic>> getReadingPatterns({int? year});
  
  /// Get series progress statistics
  Future<Map<String, dynamic>> getSeriesProgress();
  
  /// Get top rated books
  Future<List<Book>> getTopRatedBooks({int limit = 10});
}
