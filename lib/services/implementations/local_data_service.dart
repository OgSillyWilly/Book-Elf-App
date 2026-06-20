import '../interfaces/i_data_service.dart';
import '../../models/book.dart';
import '../../models/series.dart';
import '../../models/reading_challenge.dart';

/// Local SQLite implementation of IDataService (STUB - Not yet implemented)
/// Will replace API calls with local database queries
class LocalDataService implements IDataService {
  
  // TODO: Add database instance
  // final Database _db;
  // LocalDataService(this._db);
  
  @override
  Future<bool> testConnection() async {
    // Local database is always available
    return true;
  }
  
  // ==================== BOOKS ====================
  
  @override
  Future<List<Book>> getBooks() async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<BooksResponse> getBooksWithTotal() async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<Book> getBook(int id) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<Book> createBook(Map<String, dynamic> bookData) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<Book> updateBook(int id, Map<String, dynamic> bookData) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<void> deleteBook(int id) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<String> importBooks(String filePath, List<int> fileBytes) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<String> getTemplateUrl() async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<List<Book>> getBooksByYear(int year) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<List<Map<String, dynamic>>> getReadingHistory() async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  // ==================== SERIES ====================
  
  @override
  Future<List<Series>> getSeries({String? search}) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<Map<String, dynamic>> getSeriesWithProgress(int id) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<Series> createSeries(Map<String, dynamic> seriesData) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<Series> updateSeries(int id, Map<String, dynamic> seriesData) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<void> deleteSeries(int id) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  // ==================== READING CHALLENGES ====================
  
  @override
  Future<List<ReadingChallenge>> getReadingChallenges() async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<ReadingChallenge?> getActiveChallenge() async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<Map<String, dynamic>> getChallengeWithDetails(int id) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<Map<String, dynamic>> getChallengeSuggestions(int challengeId, {int limit = 10}) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<ReadingChallenge> createChallenge(Map<String, dynamic> challengeData) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<ReadingChallenge> updateChallenge(int id, Map<String, dynamic> challengeData) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  @override
  Future<void> deleteChallenge(int id) async {
    throw UnimplementedError('Local implementation coming soon');
  }
  
  // ==================== STATISTICS ====================
  
  @override
  Future<Map<String, dynamic>> getStatisticsOverview() async {
    throw UnimplementedError('Local implementation coming soon');
  }
}
