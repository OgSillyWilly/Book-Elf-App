class Series {
  final int? id;
  final String name;
  final String? description;
  final int totalBooks;
  final String? author;
  final int? booksCount; // Actual number of books in the series
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Series({
    this.id,
    required this.name,
    this.description,
    required this.totalBooks,
    this.author,
    this.booksCount,
    this.createdAt,
    this.updatedAt,
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse integers
    int? parseIntSafely(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper function to safely parse DateTime
    DateTime? parseDateTimeSafely(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return Series(
      id: parseIntSafely(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      totalBooks: parseIntSafely(json['total_books']) ?? 0,
      author: json['author']?.toString(),
      booksCount: parseIntSafely(json['books_count']),
      createdAt: parseDateTimeSafely(json['created_at']),
      updatedAt: parseDateTimeSafely(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'total_books': totalBooks,
      'author': author,
    };
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (totalBooks == 0) return 0.0;
    final count = booksCount ?? 0;
    return (count / totalBooks) * 100;
  }

  // Check if series is completed
  bool get isCompleted {
    return (booksCount ?? 0) >= totalBooks;
  }

  // Copy with method for easy updates
  Series copyWith({
    int? id,
    String? name,
    String? description,
    int? totalBooks,
    String? author,
    int? booksCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Series(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalBooks: totalBooks ?? this.totalBooks,
      author: author ?? this.author,
      booksCount: booksCount ?? this.booksCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
