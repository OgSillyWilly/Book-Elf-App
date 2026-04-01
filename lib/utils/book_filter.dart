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

  /// Filter books by type (genre)
  static bool matchesType(Book book, String? typeFilter) {
    if (typeFilter == null) return true;
    if (book.type == null) return false;
    
    // Normalize both to title case for case-insensitive comparison
    final normalizedBookType = book.type!.isNotEmpty 
        ? book.type![0].toUpperCase() + book.type!.substring(1).toLowerCase()
        : '';
    final normalizedFilter = typeFilter.isNotEmpty
        ? typeFilter[0].toUpperCase() + typeFilter.substring(1).toLowerCase()
        : '';
    
    return normalizedBookType == normalizedFilter;
  }

  /// Filter books by format
  static bool matchesFormat(Book book, String? formatFilter) {
    if (formatFilter == null) return true;
    return book.format == formatFilter;
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

  /// Filter books by rating
  static bool matchesRating(Book book, String? ratingFilter) {
    if (ratingFilter == null || ratingFilter == 'all') return true;
    
    final rating = book.rating ?? 0;
    
    // Unrated: books that are not read or have no rating
    if (ratingFilter == 'unrated') {
      return !book.isRead || rating == 0;
    }
    
    // For rated filters, only show read books
    if (!book.isRead) return false;
    
    if (ratingFilter == '5') return rating == 5;
    if (ratingFilter == '4') return rating == 4;
    if (ratingFilter == '3') return rating == 3;
    if (ratingFilter == '2') return rating == 2;
    if (ratingFilter == '1') return rating == 1;
    
    return true;
  }

  /// Apply all filters to a list of books
  static List<Book> applyFilters(
    List<Book> books, {
    String searchQuery = '',
    String readFilter = 'all',
    String? typeFilter,
    String? formatFilter,
    int? yearFilter,
    String? cabinetFilter,
    String? ratingFilter,
  }) {
    return books.where((book) {
      return matchesSearch(book, searchQuery) &&
          matchesReadStatus(book, readFilter) &&
          matchesType(book, typeFilter) &&
          matchesFormat(book, formatFilter) &&
          matchesYear(book, yearFilter) &&
          matchesCabinet(book, cabinetFilter) &&
          matchesRating(book, ratingFilter);
    }).toList();
  }

  /// Get unique types (genres) from books
  static List<String> getUniqueTypes(List<Book> books) {
    // Normalize types to title case to avoid duplicates like "kinderboek" and "Kinderboek"
    final types = books
        .where((book) => book.type != null && book.type!.isNotEmpty)
        .map((book) {
          final type = book.type!;
          return type[0].toUpperCase() + type.substring(1).toLowerCase();
        })
        .toSet()
        .toList();
    types.sort();
    return types;
  }

  /// Get unique formats from books
  static List<String> getUniqueFormats(List<Book> books) {
    final formats = books
        .where((book) => book.format != null && book.format!.isNotEmpty)
        .map((book) => book.format!)
        .toSet()
        .toList();
    formats.sort();
    return formats;
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
    
    // Numerieke sortering: 1, 2, 3, ... 9, 10 (niet 1, 10, 2, ...)
    cabinets.sort((a, b) {
      final numA = int.tryParse(a);
      final numB = int.tryParse(b);
      
      // Beiden zijn nummers? Sorteer numeriek
      if (numA != null && numB != null) {
        return numA.compareTo(numB);
      }
      
      // Als één geen nummer is, sorteer alfabetisch
      return a.compareTo(b);
    });
    
    return cabinets;
  }
}
