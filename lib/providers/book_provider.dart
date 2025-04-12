import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/database_services.dart';

class BookProvider extends ChangeNotifier {
  List<Book> _books = [];
  bool _isInitialized = false;
  // Lưu thời gian đọc gần nhất cho mỗi cuốn sách trong bộ nhớ (key: bookId, value: lastReadTime)
  final Map<String, DateTime> _lastReadTimes = {};

  List<Book> get books => _books;

  // Khởi tạo dữ liệu từ database
  Future<void> initBooks() async {
    if (_isInitialized) return;

    _books = await DatabaseServices.instance.getBooks();

    // Kiểm tra và xóa bookmarks không hợp lệ khi khởi tạo
    for (var book in _books) {
      List<Bookmark> validBookmarks = [];
      List<Bookmark> invalidBookmarks = [];
      bool hasInvalidBookmarks = false;

      // Phân loại bookmark hợp lệ và không hợp lệ
      for (var bookmark in book.bookmarks) {
        // Kiểm tra các bookmark có thời gian trong tương lai hoặc là dữ liệu mẫu
        if (bookmark.createdAt.isAfter(DateTime.now())) {
          invalidBookmarks.add(bookmark);
          hasInvalidBookmarks = true;
        } else {
          // Giữ lại các bookmark hợp lệ
          validBookmarks.add(bookmark);
        }
      }

      // Nếu có bookmark không hợp lệ, cập nhật danh sách bookmark
      if (hasInvalidBookmarks) {
        // Xóa các bookmark không hợp lệ khỏi cơ sở dữ liệu
        for (var bookmark in invalidBookmarks) {
          await DatabaseServices.instance.deleteBookmark(bookmark.id);
        }

        // Cập nhật đối tượng sách với chỉ các bookmark hợp lệ
        if (validBookmarks.isNotEmpty) {
          final updatedBook = book.copyWith(bookmarks: validBookmarks);
          final index = _books.indexWhere((b) => b.id == book.id);
          if (index != -1) {
            _books[index] = updatedBook;
          }
        }
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  // Lấy sách theo id
  Book? getBookById(String id) {
    try {
      return _books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  // Cập nhật thông tin sách
  Future<void> updateBook(Book updatedBook) async {
    final index = _books.indexWhere((book) => book.id == updatedBook.id);
    if (index != -1) {
      _books[index] = updatedBook;
      await DatabaseServices.instance.updateBook(updatedBook);
      notifyListeners();
    }
  }

  // Thay đổi trạng thái yêu thích của sách
  Future<void> toggleFavorite(String bookId) async {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index != -1) {
      final book = _books[index];
      final updatedBook = book.copyWith(isFavorite: !book.isFavorite);
      _books[index] = updatedBook;
      await DatabaseServices.instance.updateBook(updatedBook);
      notifyListeners();
    }
  }

  // Lấy danh sách sách yêu thích
  List<Book> get favoriteBooks =>
      _books.where((book) => book.isFavorite).toList();

  // Lấy danh sách những cuốn sách gần đây đã đọc
  List<Book> getRecentReadBooks() {
    return _books.where((book) => book.lastReadingPosition != null).toList()
      ..sort((a, b) {
        // Sắp xếp theo thời gian đọc gần đây nhất từ map in-memory
        final aTime = _lastReadTimes[a.id];
        final bTime = _lastReadTimes[b.id];

        if (aTime == null && bTime == null) {
          // Nếu cả hai không có thời gian đọc, so sánh vị trí đọc
          return b.lastReadingPosition!.compareTo(a.lastReadingPosition!);
        }
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
  }

  // Lấy danh sách những cuốn sách có cùng tên tác giả
  List<Book> getBooksByAuthor(String author, {String? excludeBookId}) {
    if (author.isEmpty) {
      return [];
    }

    return _books.where((book) {
      if (book.author != author) return false;
      if (excludeBookId != null && book.id == excludeBookId) return false;
      return true;
    }).toList();
  }

  // Tìm kiếm sách theo tiêu đề, tác giả và lọc theo thể loại
  List<Book> searchBooks(String query, {String category = 'All'}) {
    return _books.where((book) {
      final matchesCategory = category == 'All' || book.category == category;
      final matchesSearch =
          book.title.toLowerCase().contains(query.toLowerCase()) ||
              book.author.toLowerCase().contains(query.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Lấy danh sách tất cả các thể loại sách
  List<String> get categories {
    final categorySet = _books.map((book) => book.category).toSet();
    return ['All', ...categorySet];
  }

  // Thêm sách mới vào thư viện
  Future<void> addBook(Book book) async {
    _books.add(book);
    await DatabaseServices.instance.insertBook(book);
    notifyListeners();
  }

  // Xóa sách khỏi thư viện
  Future<void> deleteBook(String id) async {
    _books.removeWhere((book) => book.id == id);
    await DatabaseServices.instance.deleteBook(id);
    notifyListeners();
  }

  // Hàm xác thực thời gian để đảm bảo không có thời gian ở tương lai
  static DateTime validateDateTime(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.isAfter(now)) {
      return now;
    }
    return dateTime;
  }

  // Thêm bookmark cho sách
  Future<void> addBookmark(String bookId, Bookmark bookmark) async {
    try {
      // Lưu bookmark vào cơ sở dữ liệu trước
      await DatabaseServices.instance.insertBookmark(bookId, bookmark);

      // Sau khi lưu thành công, cập nhật mô hình trong bộ nhớ
      final index = _books.indexWhere((book) => book.id == bookId);
      if (index != -1) {
        final bookmarks = [..._books[index].bookmarks];
        bookmarks.add(bookmark);
        _books[index] = _books[index].copyWith(bookmarks: bookmarks);
        notifyListeners();
        print('Bookmark thêm thành công trong provider: ${bookmark.title}');
      } else {
        print('Không tìm thấy sách với ID: $bookId');
      }
    } catch (e) {
      print('Lỗi khi thêm bookmark: $e');
      rethrow; // Ném lại lỗi để UI có thể xử lý
    }
  }

  // Xóa bookmark
  Future<void> removeBookmark(String bookId, String bookmarkId) async {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index != -1) {
      final book = _books[index];
      final updatedBookmarks =
          book.bookmarks.where((b) => b.id != bookmarkId).toList();
      final updatedBook = book.copyWith(bookmarks: updatedBookmarks);
      _books[index] = updatedBook;
      await DatabaseServices.instance.deleteBookmark(bookmarkId);
      notifyListeners();
    }
  }

  // Xóa tất cả bookmark của một sách
  Future<void> deleteAllBookmarks(String bookId) async {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index != -1) {
      final book = _books[index];
      final updatedBook = book.copyWith(bookmarks: []);
      _books[index] = updatedBook;
      await DatabaseServices.instance.deleteAllBookmarksByBookId(bookId);
      notifyListeners();
    }
  }

  // Cập nhật vị trí đọc cuối cùng
  Future<void> updateLastReadingPosition(String bookId, int position) async {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index != -1) {
      final book = _books[index];
      final updatedBook = book.copyWith(lastReadingPosition: position);
      _books[index] = updatedBook;
      // Cập nhật thời gian đọc gần nhất trong bộ nhớ
      _lastReadTimes[bookId] = DateTime.now();
      await DatabaseServices.instance.updateBook(updatedBook);
      notifyListeners();
    }
  }
}
