import '../providers/book_provider.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final String description;
  final String category;
  final bool isFavorite;
  final String filePath;
  final int? lastReadingPosition;
  final List<Bookmark> bookmarks;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.description,
    required this.category,
    this.isFavorite = false,
    required this.filePath,
    this.lastReadingPosition,
    this.bookmarks = const [],
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? imageUrl,
    String? description,
    String? category,
    bool? isFavorite,
    String? filePath,
    int? lastReadingPosition,
    List<Bookmark>? bookmarks,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      filePath: filePath ?? this.filePath,
      lastReadingPosition: lastReadingPosition ?? this.lastReadingPosition,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      category: json['category'],
      isFavorite: json['isFavorite'] == 1 ? true : false,
      filePath: json['filePath'],
      lastReadingPosition: json['lastReadingPosition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
      'isFavorite': isFavorite ? 1 : 0,
      'filePath': filePath,
      'lastReadingPosition': lastReadingPosition,
    };
  }
}

class Bookmark {
  final String id;
  final int position;
  final String title;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.position,
    required this.title,
    required DateTime createdAt,
  }) : createdAt = BookProvider.validateDateTime(createdAt);
}
