import 'package:flutter/material.dart';
import '../../../models/book.dart';
import '../../book_reader/book_reader_page.dart';
import '../../shared/book_cover_image.dart';

class BookHeader extends StatelessWidget {
  final Book book;

  const BookHeader({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookCoverImage(
          imageUrl: book.imageUrl,
          height: 140,
          width: 100,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                book.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Author: ${book.author}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Category: ${book.category}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BookReaderPage(
                                book: book,
                                startFromBeginning: true,
                              )),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Read Book"),
                ),
              ),
              if (book.lastReadingPosition != null) const SizedBox(height: 8),
              if (book.lastReadingPosition != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookReaderPage(
                            book: book,
                            startFromBeginning: false,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Continue Reading"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
