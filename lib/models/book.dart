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

  const Book({
    required this.id,
    required this.title,
    this.author,
    required this.filePath,
    this.coverPath,
    this.lastReadCfi,
    this.lastReadAt,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? coverPath,
    String? lastReadCfi,
    DateTime? lastReadAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      coverPath: coverPath ?? this.coverPath,
      lastReadCfi: lastReadCfi ?? this.lastReadCfi,
      lastReadAt: lastReadAt ?? this.lastReadAt,
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
