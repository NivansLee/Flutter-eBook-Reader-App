import 'dart:io';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:provider/provider.dart';
import '../../../providers/reader_settings_provider.dart';
import '../../../providers/book_provider.dart';
import '../../../models/book.dart';

class ReaderContent extends StatelessWidget {
  final EpubController epubController;
  final Book book;
  final Function(int) onJumpToPosition;
  final Function() onSavePosition;

  const ReaderContent({
    super.key,
    required this.epubController,
    required this.book,
    required this.onJumpToPosition,
    required this.onSavePosition,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderSettingsProvider>(
      builder: (context, settings, child) {
        return Container(
          color: settings.theme.backgroundColor,
          child: EpubView(
            controller: epubController,
            builders: EpubViewBuilders<DefaultBuilderOptions>(
              options: DefaultBuilderOptions(
                textStyle: TextStyle(
                  fontSize: settings.fontSize,
                  color: settings.theme.textColor,
                ),
              ),
              chapterDividerBuilder: (_) => const Divider(),
            ),
          ),
        );
      },
    );
  }

  // Hiển thị thông báo lỗi
  static Widget buildErrorContent(String errorMessage, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              'Book Description:\n\n$description',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị trạng thái đang tải
  static Widget buildLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // Nhảy đến vị trí cụ thể trong sách
  static void jumpToPosition(
      EpubController? controller, int position, bool isMounted) {
    if (controller == null) return;

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 500 * (i + 1)), () {
        if (isMounted && controller.document != null) {
          try {
            controller.jumpTo(index: position);
          } catch (e) {
            // Bỏ qua lỗi nếu có
          }
        }
      });
    }
  }

  // Nhảy đến vị trí đọc cuối cùng
  static void jumpToLastPosition(BuildContext context, Book book,
      EpubController? controller, bool isMounted) {
    if (controller == null) return;

    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final latestBook = bookProvider.getBookById(book.id);
    final lastPosition = latestBook?.lastReadingPosition;

    if (lastPosition != null) {
      jumpToPosition(controller, lastPosition, isMounted);
    }
  }

  // Tải file sách và khởi tạo EpubController
  static Future<(EpubController?, String?)> loadBook(Book book) async {
    try {
      if (book.filePath == null) {
        return (null, 'No book file available. Please add a book file.');
      }

      final File bookFile = File(book.filePath!);

      if (!await bookFile.exists()) {
        return (null, 'Book file not found. Please check the file path.');
      }

      final controller = EpubController(
        document: EpubDocument.openFile(bookFile),
      );

      return (controller, null);
    } catch (e) {
      return (null, 'Error loading book: ${e.toString()}');
    }
  }

  // Lưu vị trí đọc hiện tại
  static void savePosition(BuildContext context, Book book,
      EpubController? controller, bool isMounted) {
    if (controller == null) return;

    try {
      final currentPosition = controller.currentValue?.position;
      final currentIndex = currentPosition?.index;

      if (currentIndex != null) {
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        bookProvider.updateLastReadingPosition(book.id, currentIndex);

        if (isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reading progress saved'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      // Bỏ qua lỗi nếu có
    }
  }
}
