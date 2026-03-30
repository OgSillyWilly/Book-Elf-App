class ReadingChallenge {
  final int? id;
  final String name;
  final String? description;
  final int goalBooks;
  final String periodType; // 'monthly', 'yearly', 'custom'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int booksRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Calculated properties from API
  final double? progressPercentage;
  final int? remainingBooks;
  final int? daysRemaining;
  final bool? isOnTrack;

  ReadingChallenge({
    this.id,
    required this.name,
    this.description,
    required this.goalBooks,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.booksRead = 0,
    this.createdAt,
    this.updatedAt,
    this.progressPercentage,
    this.remainingBooks,
    this.daysRemaining,
    this.isOnTrack,
  });

  factory ReadingChallenge.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse integers
    int? parseIntSafely(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper function to safely parse doubles
    double? parseDoubleSafely(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
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

    return ReadingChallenge(
      id: parseIntSafely(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      goalBooks: parseIntSafely(json['goal_books']) ?? 0,
      periodType: json['period_type']?.toString() ?? 'yearly',
      startDate: parseDateTimeSafely(json['start_date']) ?? DateTime.now(),
      endDate: parseDateTimeSafely(json['end_date']) ?? DateTime.now(),
      isActive: parseBoolSafely(json['is_active']),
      booksRead: parseIntSafely(json['books_read']) ?? 0,
      createdAt: parseDateTimeSafely(json['created_at']),
      updatedAt: parseDateTimeSafely(json['updated_at']),
      progressPercentage: parseDoubleSafely(json['progress_percentage']),
      remainingBooks: parseIntSafely(json['remaining_books']),
      daysRemaining: parseIntSafely(json['days_remaining']),
      isOnTrack: json['is_on_track'] != null ? parseBoolSafely(json['is_on_track']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'goal_books': goalBooks,
      'period_type': periodType,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'is_active': isActive,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Calculate local progress percentage if not provided by API
  double get localProgressPercentage {
    if (progressPercentage != null) return progressPercentage!;
    if (goalBooks == 0) return 0.0;
    return (booksRead / goalBooks) * 100;
  }

  // Calculate local remaining books if not provided by API
  int get localRemainingBooks {
    if (remainingBooks != null) return remainingBooks!;
    return goalBooks - booksRead;
  }

  // Copy with method for easy updates
  ReadingChallenge copyWith({
    int? id,
    String? name,
    String? description,
    int? goalBooks,
    String? periodType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? booksRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? progressPercentage,
    int? remainingBooks,
    int? daysRemaining,
    bool? isOnTrack,
  }) {
    return ReadingChallenge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      goalBooks: goalBooks ?? this.goalBooks,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      booksRead: booksRead ?? this.booksRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      remainingBooks: remainingBooks ?? this.remainingBooks,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      isOnTrack: isOnTrack ?? this.isOnTrack,
    );
  }
}
