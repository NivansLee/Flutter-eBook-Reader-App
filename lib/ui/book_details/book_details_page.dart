import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../edit_book/edit_book_page.dart';
import './widgets/book_details_header.dart';
import './widgets/book_details_description.dart';
import './widgets/more_from_author.dart';
import '../book_reader/book_reader_page.dart';

class BookDetailPage extends StatelessWidget {
  final String bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final book = bookProvider.getBookById(bookId);

    if (book == null) {
      return const Scaffold(
        body: Center(child: Text('Book not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              book.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: book.isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: () {
              // Lưu trạng thái mới (ngược với trạng thái hiện tại)
              final newFavoriteStatus = !book.isFavorite;
              bookProvider.toggleFavorite(book.id);

              // Hiển thị thông báo thêm/xóa khỏi danh sách yêu thích
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(newFavoriteStatus
                      ? '${book.title} added to favorites'
                      : '${book.title} removed from favorites'),
                  backgroundColor:
                      newFavoriteStatus ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () async {
              final updatedBook = await Navigator.push<Book>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditBookPage(book: book),
                ),
              );
              if (updatedBook != null) {
                bookProvider.updateBook(updatedBook);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            onPressed: () {
              _showDeleteConfirmationDialog(context, book, bookProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookHeader(book: book),
            const SizedBox(height: 16),
            BookDescription(description: book.description),
            const SizedBox(height: 16),
            MoreFromAuthor(author: book.author, currentBookId: book.id),
          ],
        ),
      ),
    );
  }

  // Hàm hiển thị hộp thoại xác nhận xóa sách
  void _showDeleteConfirmationDialog(
      BuildContext context, Book book, BookProvider bookProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Book'),
          content: Text('Are you sure to delete "${book.title}" ?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                bookProvider.deleteBook(book.id);
                Navigator.of(context).pop(); // Đóng dialog

                // Hiển thị thông báo xóa sách thành công
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${book.title} has been deleted'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );

                Navigator.of(context).pop(); // Quay lại trang trước đó
              },
            ),
          ],
        );
      },
    );
  }
}
