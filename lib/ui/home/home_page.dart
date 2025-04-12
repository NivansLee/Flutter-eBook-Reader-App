import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import 'widgets/add_book_button.dart';
import 'widgets/new_books_section.dart';
import 'widgets/continue_reading_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách sách từ BookProvider
    final books = Provider.of<BookProvider>(context).books;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Book Reader',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AddBookButton(),
              const SizedBox(height: 24),

              // Chỉ hiển thị NewBooksSection khi có sách
              if (books.isNotEmpty) NewBooksSection(books: books),

              const SizedBox(height: 24),

              // Hiển thị phần tiếp tục đọc (tự động kiểm tra sách đang đọc dở)
              const ContinueReadingSection(),
            ],
          ),
        ),
      ),
    );
  }
}
