import 'package:flutter/material.dart';
import '../../../models/book.dart';
import '../../shared/book_grid_item.dart';

class NewBooksSection extends StatelessWidget {
  final List<Book> books;

  const NewBooksSection({
    super.key,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    // Chỉ lấy 2 sách mới nhất từ danh sách
    final latestBooks = books.length > 2 
        ? books.sublist(books.length - 2) 
        : books;
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Books',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: latestBooks.length,
          itemBuilder: (context, index) => BookGridItem(book: latestBooks[index]),
        ),
      ],
    );
  }
}
