import 'package:flutter/material.dart';

class BookDescription extends StatefulWidget {
  final String description;

  const BookDescription({super.key, required this.description});

  @override
  _BookDescriptionState createState() => _BookDescriptionState();
}

class _BookDescriptionState extends State<BookDescription> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    String displayText = isExpanded
        ? widget.description
        : (widget.description.length > 100
            ? "${widget.description.substring(0, 100)}..."
            : widget.description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Book Description",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const Divider(),
        Text(
          displayText,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        if (widget.description.length > 100)
          GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Text(
              isExpanded ? "show less" : "show more",
              style: const TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ),
      ],
    );
  }
}
