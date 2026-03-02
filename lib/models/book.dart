class Book {
  final int? id;
  final String title;
  final String author;
  final String? isbn;
  final String type;
  final String? publisher;
  final String? publicationDate;
  final String? coverUrl;
  final bool hasSlipcase;
  final bool hasDustjacket;
  final String? cabinet;
  final String? shelf;
  final int? position;
  final bool isRead;
  final String? startDate;
  final String? endDate;

  Book({
    this.id,
    required this.title,
    required this.author,
    this.isbn,
    required this.type,
    this.publisher,
    this.publicationDate,
    this.coverUrl,
    this.hasSlipcase = false,
    this.hasDustjacket = false,
    this.cabinet,
    this.shelf,
    this.position,
    this.isRead = false,
    this.startDate,
    this.endDate,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final rawCoverUrl = json['cover_url'];

    // Helper function to safely parse integers
    int? parseIntSafely(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper function to safely parse booleans
    bool parseBoolSafely(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }

    return Book(
      id: parseIntSafely(json['id']),
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      isbn: json['isbn']?.toString(),
      type: json['type']?.toString() ?? 'boek',
      publisher: json['publisher']?.toString(),
      publicationDate: json['publication_date']?.toString(),
      coverUrl: rawCoverUrl is String ? rawCoverUrl : null,
      hasSlipcase: parseBoolSafely(json['has_slipcase']),
      hasDustjacket: parseBoolSafely(json['has_dustjacket']),
      cabinet: json['cabinet']?.toString(),
      shelf: json['shelf']?.toString(),
      position: parseIntSafely(json['position']),
      isRead: parseBoolSafely(json['is_read']),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'isbn': isbn,
      'type': type,
      'publisher': publisher,
      'publication_date': publicationDate,
      'cover_url': coverUrl,
      'has_slipcase': hasSlipcase,
      'has_dustjacket': hasDustjacket,
      'cabinet': cabinet,
      'shelf': shelf,
      'position': position,
      'is_read': isRead,
      'start_date': startDate,
      'end_date': endDate,
    };
  }
}
