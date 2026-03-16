import '../models/book.dart';

class BookSorter {
  /// Sort books by title (alphabetically, case-insensitive)
  static void sortByTitle(List<Book> books) {
    books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  /// Sort books by author (alphabetically, case-insensitive)
  static void sortByAuthor(List<Book> books) {
    books.sort((a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()));
  }

  /// Sort books by cabinet → shelf → position
  static void sortByCabinet(List<Book> books) {
    books.sort((a, b) {
      // Sort by cabinet first, then by shelf, then by position
      final cabinetCompare = (a.cabinet ?? '').compareTo(b.cabinet ?? '');
      if (cabinetCompare != 0) return cabinetCompare;
      
      final shelfCompare = (a.shelf ?? '').compareTo(b.shelf ?? '');
      if (shelfCompare != 0) return shelfCompare;
      
      return (a.position ?? 0).compareTo(b.position ?? 0);
    });
  }

  /// Apply sorting based on sort key
  static void applySorting(List<Book> books, String sortBy) {
    switch (sortBy) {
      case 'title':
        sortByTitle(books);
        break;
      case 'author':
        sortByAuthor(books);
        break;
      case 'cabinet':
        sortByCabinet(books);
        break;
      default:
        // No sorting or unknown sort key
        break;
    }
  }
}
