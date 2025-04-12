import 'package:flutter/material.dart';
import '../../../models/book.dart';
import '../../book_reader/book_reader_page.dart';
import 'package:provider/provider.dart';
import '../../../providers/book_provider.dart';
import 'dart:io';

class ContinueReadingSection extends StatelessWidget {
  const ContinueReadingSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final recentBooks = bookProvider.getRecentReadBooks();

    if (recentBooks.isEmpty) {
      return const SizedBox(); // Không hiển thị nếu không có sách nào đã đọc
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Continue Reading',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentBooks.length,
          itemBuilder: (context, index) =>
              ContinueReadingCard(book: recentBooks[index]),
        ),
      ],
    );
  }
}

class ContinueReadingCard extends StatelessWidget {
  final Book book;

  const ContinueReadingCard({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookReaderPage(book: book),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.imageUrl.startsWith('assets/')
                    ? Image.asset(
                        book.imageUrl,
                        width: 70,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 70,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, size: 40),
                          );
                        },
                      )
                    : Image.file(
                        File(book.imageUrl),
                        width: 70,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 70,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, size: 40),
                          );
                        },
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Continue where you left off",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
