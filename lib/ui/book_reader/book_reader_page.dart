import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import '../../models/book.dart';
import 'widgets/reader_content.dart';
import 'widgets/reader_settings.dart';
import 'widgets/bookmark_list.dart';

class BookReaderPage extends StatefulWidget {
  final Book book;
  final bool startFromBeginning;
  final int? specificPosition;

  const BookReaderPage({
    super.key,
    required this.book,
    this.startFromBeginning = false,
    this.specificPosition,
  });

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  EpubController? _epubController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initReader();
  }

  // Khởi tạo reader
  Future<void> _initReader() async {
    final (controller, error) = await ReaderContent.loadBook(widget.book);

    if (mounted) {
      setState(() {
        _epubController = controller;
        _errorMessage = error;
        _isLoading = false;
      });

      // Sau khi load xong, kiểm tra vị trí cần nhảy đến
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.specificPosition != null) {
          ReaderContent.jumpToPosition(
              _epubController, widget.specificPosition!, mounted);
        } else if (!widget.startFromBeginning) {
          ReaderContent.jumpToLastPosition(
              context, widget.book, _epubController, mounted);
        }
      });
    }
  }

  @override
  void dispose() {
    ReaderContent.savePosition(context, widget.book, _epubController, mounted);
    _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ReaderContent.savePosition(
            context, widget.book, _epubController, mounted);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.book.title),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              ReaderContent.savePosition(
                  context, widget.book, _epubController, mounted);
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_border, color: Colors.black),
              onPressed: () {
                if (_epubController != null) {
                  BookmarkList.handleAddBookmark(
                    context,
                    widget.book.id,
                    _epubController!,
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.bookmarks, color: Colors.black),
              onPressed: () {
                BookmarkList.showBookmarkList(
                  context,
                  widget.book,
                  (position) {
                    if (_epubController != null) {
                      _epubController!.jumpTo(index: position);
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () => ReaderSettings.showReaderSettings(context),
            ),
          ],
        ),
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ReaderContent.buildLoadingContent();
    }

    if (_errorMessage != null) {
      return ReaderContent.buildErrorContent(
          _errorMessage!, widget.book.description);
    }

    return ReaderContent(
      epubController: _epubController!,
      book: widget.book,
      onJumpToPosition: (position) =>
          ReaderContent.jumpToPosition(_epubController, position, mounted),
      onSavePosition: () => ReaderContent.savePosition(
          context, widget.book, _epubController, mounted),
    );
  }
}
