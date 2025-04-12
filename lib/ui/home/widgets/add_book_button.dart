import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../models/book.dart';
import '../../../providers/book_provider.dart';

class AddBookButton extends StatelessWidget {
  const AddBookButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _pickAndAddEpubBook(context);
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: const Icon(
                Icons.add_circle_outline,
                size: 40,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Book',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your favorite books to your library',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndAddEpubBook(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      _showLoadingDialog(context);

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final epubBook = await epubx.EpubReader.readBook(bytes);

      final uuid = const Uuid().v4();
      final savedFilePath = await _saveEpubFile(file, uuid);

      final book = await _createBookFromEpub(epubBook, savedFilePath);

      await _addBookToLibrary(context, book);

      Navigator.of(context).pop();

      _showSuccessSnackbar(context, book.title);
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorSnackbar(context, e.toString());
    }
  }

  Future<String> _saveEpubFile(File file, String uuid) async {
    final appDir = await getApplicationDocumentsDirectory();
    final bookDir = Directory('${appDir.path}/books');
    if (!await bookDir.exists()) {
      await bookDir.create(recursive: true);
    }

    final savedFilePath = '${bookDir.path}/$uuid.epub';
    await file.copy(savedFilePath);
    return savedFilePath;
  }

  Future<Book> _createBookFromEpub(
      epubx.EpubBook epubBook, String filePath) async {
    final uuid = const Uuid().v4();

    // Trích xuất thông tin từ EPUB trước
    String title = epubBook.Title?.trim() ?? 'Unknown Title';
    String author = epubBook.Author?.trim() ?? 'Unknown Author';
    String description = _extractDescription(epubBook);
    String category = 'Ebook';

    // Xử lý category từ EPUB
    if (epubBook.Schema?.Package?.Metadata != null) {
      final metadata = epubBook.Schema!.Package!.Metadata!;

      if (metadata.Subjects?.isNotEmpty == true) {
        final subjects = metadata.Subjects!
            .map((s) => s.toLowerCase().trim())
            .where((s) => s.length > 3 && !['ebook', 'unknown'].contains(s))
            .toList();
        if (subjects.isNotEmpty) {
          category =
              subjects.first[0].toUpperCase() + subjects.first.substring(1);
        }
      }

      if (category == 'Ebook' && metadata.MetaItems?.isNotEmpty == true) {
        for (var meta in metadata.MetaItems!) {
          final content = meta.Content?.toLowerCase().trim() ?? '';
          if ((meta.Name?.toLowerCase().contains('category') == true ||
                  meta.Name?.toLowerCase().contains('genre') == true) &&
              content.length > 3 &&
              !['ebook', 'unknown'].contains(content)) {
            category = content[0].toUpperCase() + content.substring(1);
            break;
          }
        }
      }
    }

    // Chỉ sử dụng Google Books API nếu thông tin từ EPUB không đầy đủ
    if (title == 'Unknown Title' ||
        author == 'Unknown Author' ||
        description == 'No description available' ||
        category == 'Ebook') {
      try {
        final searchQuery = Uri.encodeComponent('$title $author');
        final response = await http.get(
          Uri.parse(
              'https://www.googleapis.com/books/v1/volumes?q=$searchQuery'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['items'] != null && data['items'].isNotEmpty) {
            final bookData = data['items'][0]['volumeInfo'];

            // Chỉ cập nhật thông tin còn thiếu
            if (title == 'Unknown Title' && bookData['title'] != null) {
              title = bookData['title'];
            }

            if (author == 'Unknown Author' && bookData['authors'] != null) {
              author = bookData['authors'][0];
            }

            if (description == 'No description available' &&
                bookData['description'] != null) {
              description = bookData['description'];
            }

            if (category == 'Ebook' && bookData['categories'] != null) {
              category = bookData['categories'][0];
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching book info: $e');
      }
    }

    // Trích xuất và lưu ảnh bìa
    String coverPath = await _extractAndSaveCover(epubBook, uuid);

    return Book(
      id: uuid,
      title: title,
      author: author,
      imageUrl: coverPath,
      description: description,
      category: category,
      isFavorite: false,
      filePath: filePath,
    );
  }

  String _extractDescription(epubx.EpubBook epubBook) {
    String? description;

    if (epubBook.Schema?.Package?.Metadata != null) {
      final metadata = epubBook.Schema!.Package!.Metadata!;

      // Thử lấy từ Description chính
      description = metadata.Description?.trim();

      // Nếu không có, tìm trong MetaItems
      if (description == null && metadata.MetaItems != null) {
        for (var meta in metadata.MetaItems!) {
          if (meta.Name?.toLowerCase().contains('description') == true &&
              meta.Content?.isNotEmpty == true) {
            description = meta.Content!.trim();
            break;
          }
        }
      }
    }

    return description?.replaceAll(RegExp(r'<[^>]*>'), '') ??
        'No description available';
  }

  Future<String> _extractAndSaveCover(
      epubx.EpubBook epubBook, String uuid) async {
    final appDir = await getApplicationDocumentsDirectory();
    final coverDir = Directory('${appDir.path}/covers');
    await coverDir.create(recursive: true);
    final coverPath = '${coverDir.path}/$uuid.jpg';
    final coverFile = File(coverPath);

    try {
      // 1. Tìm trong metadata với property='cover-image'
      if (epubBook.Schema?.Package?.Metadata?.MetaItems != null) {
        String? coverId;

        // Tìm meta item với property='cover-image'
        for (var meta in epubBook.Schema!.Package!.Metadata!.MetaItems!) {
          if ((meta.Property?.toLowerCase() == 'cover-image' ||
                  meta.Name?.toLowerCase() == 'cover') &&
              meta.Content != null) {
            coverId = meta.Content;
            break;
          }
        }

        // Nếu tìm thấy coverId, tìm ảnh tương ứng
        if (coverId != null &&
            epubBook.Content?.Images != null &&
            epubBook.Schema?.Package?.Manifest?.Items != null) {
          for (var item in epubBook.Schema!.Package!.Manifest!.Items!) {
            if (item.Id == coverId && item.Href != null) {
              final hrefPath = item.Href!.startsWith('/')
                  ? item.Href!.substring(1)
                  : item.Href!;
              for (var entry in epubBook.Content!.Images!.entries) {
                if (entry.key.endsWith(hrefPath)) {
                  final imageFile = entry.value as epubx.EpubByteContentFile;
                  if (imageFile.Content != null &&
                      imageFile.Content!.isNotEmpty) {
                    await coverFile.writeAsBytes(imageFile.Content!);
                    return coverPath;
                  }
                }
              }
            }
          }
        }
      }

      // 2. Tìm trong tất cả ảnh với tên phù hợp
      if (epubBook.Content?.Images?.isNotEmpty == true) {
        var coverImages = epubBook.Content!.Images!.entries.where((entry) {
          final key = entry.key.toLowerCase();
          final imageFile = entry.value as epubx.EpubByteContentFile;

          // Kiểm tra kích thước và định dạng
          bool isValidSize = (imageFile.Content?.length ?? 0) > 10000;
          bool isImageFile = key.endsWith('.jpg') ||
              key.endsWith('.jpeg') ||
              key.endsWith('.png');

          // Kiểm tra tên file
          bool hasCoverKeyword = key.contains('cover') ||
              key.contains('title') ||
              key.contains('front') ||
              (key.contains('page') && key.contains('1'));

          return isValidSize && isImageFile && hasCoverKeyword;
        }).toList();

        if (coverImages.isNotEmpty) {
          // Sắp xếp theo độ ưu tiên và kích thước
          coverImages.sort((a, b) {
            final aFile = a.value as epubx.EpubByteContentFile;
            final bFile = b.value as epubx.EpubByteContentFile;
            final aSize = aFile.Content?.length ?? 0;
            final bSize = bFile.Content?.length ?? 0;

            // Ưu tiên file có từ khóa "cover"
            if (a.key.toLowerCase().contains('cover') &&
                !b.key.toLowerCase().contains('cover')) {
              return -1;
            }
            if (!a.key.toLowerCase().contains('cover') &&
                b.key.toLowerCase().contains('cover')) {
              return 1;
            }

            // Nếu cùng mức độ ưu tiên, so sánh kích thước
            return bSize.compareTo(aSize);
          });

          final imageFile =
              coverImages.first.value as epubx.EpubByteContentFile;
          await coverFile.writeAsBytes(imageFile.Content!);
          return coverPath;
        }

        // 3. Nếu không tìm thấy, lấy ảnh đầu tiên có kích thước phù hợp
        var firstLargeImage = epubBook.Content!.Images!.entries.where((entry) {
          final imageFile = entry.value as epubx.EpubByteContentFile;
          return (imageFile.Content?.length ?? 0) > 30000;
        }).firstOrNull;

        if (firstLargeImage != null) {
          final imageFile = firstLargeImage.value as epubx.EpubByteContentFile;
          await coverFile.writeAsBytes(imageFile.Content!);
          return coverPath;
        }
      }
    } catch (e) {
      debugPrint('Error extracting cover: $e');
    }

    // Sử dụng ảnh mặc định nếu không tìm thấy
    return 'assets/images/default_cover.jpg';
  }

  Future<void> _addBookToLibrary(BuildContext context, Book book) async {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.addBook(book);
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$title" to your library'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error adding book: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
