import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/../../providers/book_provider.dart';

class CategoryFilter extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách thể loại từ BookProvider
    final categories = Provider.of<BookProvider>(context).categories;
    final currentCategory = categories.contains(selectedCategory)
        ? selectedCategory
        : categories.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        value: currentCategory,
        onChanged: (String? newValue) {
          if (newValue != null) {
            onCategorySelected(newValue);
          }
        },
        items: categories.map<DropdownMenuItem<String>>((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        isExpanded: true,
        underline: Container(),
        icon: const Icon(Icons.arrow_drop_down),
        style: const TextStyle(color: Colors.black, fontSize: 14),
        dropdownColor: Colors.white,
      ),
    );
  }
}
