import '../models/book.dart';

class BookFilter {
  /// Filter books by search query
  static bool matchesSearch(Book book, String query) {
    if (query.isEmpty) return true;
    
    final lowerQuery = query.toLowerCase();
    return book.title.toLowerCase().contains(lowerQuery) ||
        book.author.toLowerCase().contains(lowerQuery);
  }

  /// Filter books by read status
  static bool matchesReadStatus(Book book, String readFilter) {
    if (readFilter == 'all') return true;
    if (readFilter == 'read') return book.isRead;
    if (readFilter == 'unread') return !book.isRead;
    return true;
  }

  /// Filter books by type
  static bool matchesType(Book book, String? typeFilter) {
    if (typeFilter == null) return true;
    return book.type == typeFilter;
  }

  /// Filter books by year (extracted from endDate)
  static bool matchesYear(Book book, int? yearFilter) {
    if (yearFilter == null) return true;
    if (book.endDate == null || book.endDate!.isEmpty) return false;
    
    try {
      final date = DateTime.parse(book.endDate!);
      return date.year == yearFilter;
    } catch (e) {
      return false;
    }
  }

  /// Filter books by cabinet
  static bool matchesCabinet(Book book, String? cabinetFilter) {
    if (cabinetFilter == null) return true;
    return book.cabinet != null && book.cabinet == cabinetFilter;
  }

  /// Apply all filters to a list of books
  static List<Book> applyFilters(
    List<Book> books, {
    String searchQuery = '',
    String readFilter = 'all',
    String? typeFilter,
    int? yearFilter,
    String? cabinetFilter,
  }) {
    return books.where((book) {
      return matchesSearch(book, searchQuery) &&
          matchesReadStatus(book, readFilter) &&
          matchesType(book, typeFilter) &&
          matchesYear(book, yearFilter) &&
          matchesCabinet(book, cabinetFilter);
    }).toList();
  }

  /// Get unique types from books
  static List<String> getUniqueTypes(List<Book> books) {
    final types = books.map((book) => book.type).toSet().toList();
    types.sort();
    return types;
  }

  /// Get unique years from books (from endDate)
  static List<int> getUniqueYears(List<Book> books) {
    final years = books
        .where((book) => book.endDate != null && book.endDate!.isNotEmpty)
        .map((book) {
          try {
            final date = DateTime.parse(book.endDate!);
            return date.year;
          } catch (e) {
            return null;
          }
        })
        .where((year) => year != null)
        .cast<int>()
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a)); // Descending order (newest first)
    return years;
  }

  /// Get unique cabinets from books
  static List<String> getUniqueCabinets(List<Book> books) {
    final cabinets = books
        .where((book) => book.cabinet != null && book.cabinet!.isNotEmpty)
        .map((book) => book.cabinet!)
        .toSet()
        .toList();
    cabinets.sort();
    return cabinets;
  }
}
