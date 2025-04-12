import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:epub_view/epub_view.dart';
import '../../../models/book.dart';
import '../../../providers/book_provider.dart';

class BookmarkList extends StatefulWidget {
  final Book book;
  final Function(int) onJumpToBookmark;
  final Function(List<Bookmark>) onBookmarksChanged;

  const BookmarkList({
    Key? key,
    required this.book,
    required this.onJumpToBookmark,
    required this.onBookmarksChanged,
  }) : super(key: key);

  @override
  State<BookmarkList> createState() => _BookmarkListState();

  // PHƯƠNG THỨC TĨNH
  /// Hiển thị danh sách bookmark trong một modal bottom sheet
  static void showBookmarkList(
    BuildContext context,
    Book book,
    Function(int) onJumpToBookmark,
  ) {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final latestBook = bookProvider.getBookById(book.id);

    if (latestBook == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.only(top: 8.0),
        child: BookmarkList(
          book: latestBook,
          onJumpToBookmark: onJumpToBookmark,
          onBookmarksChanged: (updatedBookmarks) {
            final updatedBook =
                latestBook.copyWith(bookmarks: updatedBookmarks);
            bookProvider.updateBook(updatedBook);
          },
        ),
      ),
    );
  }

  /// Hiển thị dialog để thêm bookmark mới
  static void showAddBookmarkDialog(
    BuildContext context,
    int currentIndex,
    String currentChapter,
    Function(String, int) onAddBookmark,
  ) {
    final TextEditingController titleController = TextEditingController();

    // Lấy tên chapter hiện tại nếu có
    titleController.text = currentChapter.isNotEmpty
        ? 'Bookmark at $currentChapter'
        : 'Bookmark at page ${currentIndex + 1}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bookmark'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Bookmark Title',
            hintText: 'Enter a name for this bookmark',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onAddBookmark(titleController.text, currentIndex);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Thêm bookmark mới
  static Future<void> addBookmark(
    BuildContext context,
    String bookId,
    String title,
    int position,
  ) async {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final book = bookProvider.getBookById(bookId);

    if (book == null) return;

    if (book.bookmarks.length >= 5) {
      _showErrorDialog(
        context,
        'Maximum Limit',
        'You can only save up to 5 bookmarks per book.',
      );
      return;
    }

    try {
      // Tạo bookmark mới với ID ngẫu nhiên và thời gian hiện tại
      final now = DateTime.now();
      final newBookmark = Bookmark(
        id: const Uuid().v4(),
        position: position,
        title: title,
        createdAt: now,
      );

      // Lưu bookmark vào cơ sở dữ liệu
      await bookProvider.addBookmark(bookId, newBookmark);

      // Hiển thị thông báo thành công
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Hiển thị thông báo lỗi
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Could not add bookmark. $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Error adding bookmark: $e');
    }
  }

  /// Hiển thị thông báo lỗi
  static void _showErrorDialog(
      BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Xử lý thêm bookmark mới từ vị trí hiện tại
  static void handleAddBookmark(
      BuildContext context, String bookId, EpubController controller) {
    final currentValue = controller.currentValue;
    final currentPosition = currentValue?.position;
    final currentIndex = currentPosition?.index;

    if (currentIndex == null) return;

    // Lấy tên chapter hiện tại nếu có
    final currentChapter = currentValue?.chapter?.Title ?? '';

    showAddBookmarkDialog(
      context,
      currentIndex,
      currentChapter,
      (title, position) => addBookmark(context, bookId, title, position),
    );
  }
}

class _BookmarkListState extends State<BookmarkList> {
  late List<Bookmark> _bookmarks;

  @override
  void initState() {
    super.initState();
    _bookmarks = List.from(widget.book.bookmarks);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bookmarks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (_bookmarks.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        label: const Text('Delete All',
                            style: TextStyle(color: Colors.red)),
                        onPressed: _showDeleteAllConfirmation,
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          _bookmarks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No bookmarks yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = _bookmarks[index];
                      return ListTile(
                        title: Text(bookmark.title),
                        subtitle: Text(
                            'Added on: ${_formatDate(bookmark.createdAt)}'),
                        leading: const Icon(Icons.bookmark, color: Colors.blue),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBookmark(index),
                        ),
                        onTap: () {
                          widget.onJumpToBookmark(bookmark.position);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  // PHƯƠNG THỨC INSTANCE
  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  void _deleteBookmark(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark'),
        content: const Text('Are you sure you want to delete this bookmark?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _bookmarks.removeAt(index);
                widget.onBookmarksChanged(_bookmarks);
              });
              Navigator.pop(context);

              // Hiển thị thông báo xóa bookmark thành công
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bookmark deleted successfully'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Hiển thị dialog xác nhận xóa tất cả bookmark
  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Bookmarks'),
        content: const Text('Are you sure you want to delete all bookmarks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _bookmarks.clear();
                widget.onBookmarksChanged(_bookmarks);
              });
              Navigator.pop(context);

              // Hiển thị thông báo xóa tất cả bookmark thành công
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All bookmarks deleted'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child:
                const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
