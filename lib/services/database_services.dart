import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';

class DatabaseServices {
  static final DatabaseServices instance = DatabaseServices._init();
  static Database? _database;

  DatabaseServices._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bookreader.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Định nghĩa kiểu dữ liệu cho SQLite
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const boolType = 'INTEGER NOT NULL'; // 0 = false, 1 = true
    const intNullableType = 'INTEGER';

    // Tạo bảng books
    await db.execute('''
    CREATE TABLE books (
      id $idType,
      title $textType,
      author $textType,
      imageUrl $textType,
      description $textType,
      category $textType,
      isFavorite $boolType,
      filePath $textNullableType,
      lastReadingPosition $intNullableType
    )
    ''');

    // Tạo bảng bookmarks
    await db.execute('''
    CREATE TABLE bookmarks (
      id $idType,
      bookId $textType,
      position $textType,
      title $textType,
      createdAt $textType,
      FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
    )
    ''');
  }

  // CÁC PHƯƠNG THỨC THAO TÁC VỚI BOOK

  // Thêm sách mới
  Future<void> insertBook(Book book) async {
    final db = await database;
    await db.insert(
      'books',
      {
        'id': book.id,
        'title': book.title,
        'author': book.author,
        'imageUrl': book.imageUrl,
        'description': book.description,
        'category': book.category,
        'isFavorite': book.isFavorite ? 1 : 0,
        'filePath': book.filePath,
        'lastReadingPosition': book.lastReadingPosition,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Cập nhật thông tin sách
  Future<void> updateBook(Book book) async {
    final db = await database;
    await db.update(
      'books',
      {
        'title': book.title,
        'author': book.author,
        'imageUrl': book.imageUrl,
        'description': book.description,
        'category': book.category,
        'isFavorite': book.isFavorite ? 1 : 0,
        'filePath': book.filePath,
        'lastReadingPosition': book.lastReadingPosition,
      },
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  // Xóa sách
  Future<void> deleteBook(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      // Xóa tất cả bookmarks của sách này
      await txn.delete('bookmarks', where: 'bookId = ?', whereArgs: [id]);
      // Xóa sách
      await txn.delete('books', where: 'id = ?', whereArgs: [id]);
    });
  }

  // Lấy tất cả sách
  Future<List<Book>> getBooks() async {
    final db = await database;

    final booksData = await db.query('books');
    List<Book> books = [];

    for (var bookData in booksData) {
      final bookId = bookData['id'] as String;
      final bookmarks = await getBookmarksByBookId(bookId);

      books.add(Book(
        id: bookId,
        title: bookData['title'] as String,
        author: bookData['author'] as String,
        imageUrl: bookData['imageUrl'] as String,
        description: bookData['description'] as String,
        category: bookData['category'] as String,
        isFavorite: bookData['isFavorite'] == 1,
        filePath: bookData['filePath'] as String? ?? '',
        lastReadingPosition: bookData['lastReadingPosition'] as int?,
        bookmarks: bookmarks,
      ));
    }

    return books;
  }

  // Lấy sách theo ID
  Future<Book?> getBookById(String id) async {
    final db = await database;
    final maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final bookmarks = await getBookmarksByBookId(id);
      return Book(
        id: maps.first['id'] as String,
        title: maps.first['title'] as String,
        author: maps.first['author'] as String,
        imageUrl: maps.first['imageUrl'] as String,
        description: maps.first['description'] as String,
        category: maps.first['category'] as String,
        isFavorite: maps.first['isFavorite'] == 1,
        filePath: maps.first['filePath'] as String? ?? '',
        lastReadingPosition: maps.first['lastReadingPosition'] as int?,
        bookmarks: bookmarks,
      );
    }
    return null;
  }

  // CÁC PHƯƠNG THỨC THAO TÁC VỚI BOOKMARK

  // Thêm bookmark mới
  Future<void> insertBookmark(String bookId, Bookmark bookmark) async {
    final db = await database;
    try {
      // Kiểm tra xem thời gian của bookmark có ở tương lai không
      final now = DateTime.now();
      final createdAt =
          bookmark.createdAt.isAfter(now) ? now : bookmark.createdAt;

      // Đảm bảo bookId tồn tại trong bảng books
      final bookExists = await db.query('books',
          where: 'id = ?', whereArgs: [bookId], limit: 1);

      if (bookExists.isEmpty) {
        throw Exception('Book with ID $bookId does not exist');
      }

      // Thêm bookmark vào cơ sở dữ liệu
      await db.insert(
        'bookmarks',
        {
          'id': bookmark.id,
          'bookId': bookId,
          'position': bookmark.position.toString(),
          'title': bookmark.title,
          'createdAt': createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // In ra thông báo để debug
      print('Bookmark inserted successfully: ${bookmark.title}');
    } catch (e) {
      print('Error inserting bookmark: $e');
      rethrow;
    }
  }

  // Xóa bookmark
  Future<void> deleteBookmark(String id) async {
    final db = await database;
    await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Lấy tất cả bookmarks của một sách
  Future<List<Bookmark>> getBookmarksByBookId(String bookId) async {
    final db = await database;

    try {
      final now = DateTime.now();

      // Sửa các bookmark có thời gian trong tương lai thay vì xóa chúng
      final List<Map<String, dynamic>> futureDates = await db.query(
        'bookmarks',
        where: 'bookId = ? AND createdAt > ?',
        whereArgs: [bookId, now.toIso8601String()],
      );

      // Cập nhật thời gian của các bookmark trong tương lai về thời gian hiện tại
      if (futureDates.isNotEmpty) {
        for (var bookmark in futureDates) {
          await db.update(
            'bookmarks',
            {'createdAt': now.toIso8601String()},
            where: 'id = ?',
            whereArgs: [bookmark['id']],
          );
        }
      }

      // Lấy danh sách bookmarks
      final maps = await db.query(
        'bookmarks',
        where: 'bookId = ?',
        whereArgs: [bookId],
        orderBy: 'createdAt DESC',
      );

      return maps
          .map((map) {
            try {
              final createdAtString = map['createdAt'] as String;
              DateTime createdAt;

              try {
                createdAt = DateTime.parse(createdAtString);
                // Đảm bảo thời gian không nằm trong tương lai
                if (createdAt.isAfter(now)) {
                  createdAt = now;
                }
              } catch (e) {
                // Nếu parse thất bại, sử dụng thời gian hiện tại
                createdAt = now;
              }

              return Bookmark(
                id: map['id'] as String,
                position: int.parse(map['position'] as String),
                title: map['title'] as String,
                createdAt: createdAt,
              );
            } catch (e) {
              return null;
            }
          })
          .where((bookmark) => bookmark != null)
          .cast<Bookmark>()
          .toList();
    } catch (e) {
      // Nếu có lỗi, trả về danh sách trống
      return [];
    }
  }

  // Xóa tất cả bookmark của một sách
  Future<void> deleteAllBookmarksByBookId(String bookId) async {
    final db = await database;
    await db.delete(
      'bookmarks',
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
  }

  // Đóng database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
