import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';

class EditBookPage extends StatefulWidget {
  final Book book;

  const EditBookPage({super.key, required this.book});

  @override
  _EditBookPageState createState() => _EditBookPageState();
}

class _EditBookPageState extends State<EditBookPage> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _descriptionController =
        TextEditingController(text: widget.book.description);
    _imageUrlController = TextEditingController(text: widget.book.imageUrl);
    _categoryController = TextEditingController(text: widget.book.category);

    // Lắng nghe thay đổi để cập nhật preview hình ảnh
    _imageUrlController.addListener(() {
      setState(() {});
    });
  }

  void _saveChanges() {
    final updatedBook = widget.book.copyWith(
      title: _titleController.text,
      author: _authorController.text,
      description: _descriptionController.text,
      imageUrl: _imageUrlController.text,
      category: _categoryController.text,
    );

    // Cập nhật sách thông qua BookProvider
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.updateBook(updatedBook);

    // Hiển thị thông báo cập nhật thành công
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${updatedBook.title} has been updated'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
      ),
    );

    Navigator.pop(context, updatedBook);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
    const textFieldStyle = TextStyle(fontSize: 18);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Book'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.black),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text('Title', style: labelStyle),
            TextField(
              controller: _titleController,
              style: textFieldStyle,
            ),
            const SizedBox(height: 16),

            // Author
            const Text('Author', style: labelStyle),
            TextField(
              controller: _authorController,
              style: textFieldStyle,
            ),
            const SizedBox(height: 16),

            // Description
            const Text('Description', style: labelStyle),
            TextField(
              controller: _descriptionController,
              style: textFieldStyle,
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Category
            const Text('Category', style: labelStyle),
            TextField(
              controller: _categoryController,
              style: textFieldStyle,
              decoration: const InputDecoration(
                hintText: 'Enter book category',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
