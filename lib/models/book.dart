import 'dart:convert';

/// Book model representing an EPUB book in the library.
class Book {
  final String id;
  final String title;
  final String? author;
  final String filePath;
  final String? coverPath;
  final String? lastReadCfi;
  final DateTime? lastReadAt;

  final double progress;

  // Formatting preferences (per-book)
  final double fontSize;
  final int fontIndex;
  final int lineSpacingIndex;
  final int textAlignmentIndex;

  const Book({
    required this.id,
    required this.title,
    this.author,
    required this.filePath,
    this.coverPath,
    this.lastReadCfi,
    this.lastReadAt,
    this.progress = 0.0,
    this.fontSize = 16.0,
    this.fontIndex = 0,
    this.lineSpacingIndex = 1, // Normal
    this.textAlignmentIndex = 1, // Justify
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? coverPath,
    String? lastReadCfi,
    DateTime? lastReadAt,
    double? progress,
    double? fontSize,
    int? fontIndex,
    int? lineSpacingIndex,
    int? textAlignmentIndex,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      coverPath: coverPath ?? this.coverPath,
      lastReadCfi: lastReadCfi ?? this.lastReadCfi,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      progress: progress ?? this.progress,
      fontSize: fontSize ?? this.fontSize,
      fontIndex: fontIndex ?? this.fontIndex,
      lineSpacingIndex: lineSpacingIndex ?? this.lineSpacingIndex,
      textAlignmentIndex: textAlignmentIndex ?? this.textAlignmentIndex,
    );
  }

  /// Convert to JSON map for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'coverPath': coverPath,
      'lastReadCfi': lastReadCfi,
      'lastReadAt': lastReadAt?.toIso8601String(),
      'progress': progress,
      'fontSize': fontSize,
      'fontIndex': fontIndex,
      'lineSpacingIndex': lineSpacingIndex,
      'textAlignmentIndex': textAlignmentIndex,
    };
  }

  /// Create from JSON map.
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      filePath: json['filePath'] as String,
      coverPath: json['coverPath'] as String?,
      lastReadCfi: json['lastReadCfi'] as String?,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.parse(json['lastReadAt'] as String)
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      fontIndex: json['fontIndex'] as int? ?? 0,
      lineSpacingIndex: json['lineSpacingIndex'] as int? ?? 1,
      textAlignmentIndex: json['textAlignmentIndex'] as int? ?? 1,
    );
  }

  /// Encode list of books to JSON string.
  static String encodeBooks(List<Book> books) {
    return jsonEncode(books.map((b) => b.toJson()).toList());
  }

  /// Decode list of books from JSON string.
  static List<Book> decodeBooks(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Book.fromJson(json)).toList();
  }
}
