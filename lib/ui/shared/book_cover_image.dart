import 'dart:io';
import 'package:flutter/material.dart';

class BookCoverImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const BookCoverImage({
    super.key,
    required this.imageUrl,
    this.width = 100,
    this.height = 150,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    // Kiểm tra nếu imageUrl là đường dẫn asset
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    }
    
    // Nếu không, đó là đường dẫn file
    return Image.file(
      File(imageUrl),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: _errorBuilder,
    );
  }

  Widget _errorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, color: Colors.grey),
            const SizedBox(height: 4),
            Text(
              'No Cover',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 