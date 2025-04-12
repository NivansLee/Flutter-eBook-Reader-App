import 'package:flutter/material.dart';
import '../../favorites/favorites_page.dart';
import '../about_page.dart';
import '../licenses_page.dart';

class SettingsList extends StatelessWidget {
  const SettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildSettingsItem(context, Icons.favorite_border_rounded, "Favorites"),
        _buildSettingsItem(context, Icons.info_outline_rounded, "About"),
        _buildSettingsItem(context, Icons.description_rounded, "Licenses"),
      ],
    );
  }

  /// Widget tạo từng mục trong danh sách cài đặt
  Widget _buildSettingsItem(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          // Xử lý khi nhấn vào
          if (title == "Favorites") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FavoritesPage()),
            );
          } else if (title == "About") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutPage()),
            );
          } else if (title == "Licenses") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LicensesPage()),
            );
          }
        },
        splashColor: Color.fromRGBO(128, 128, 128, 0.3),
        highlightColor: Color.fromRGBO(128, 128, 128, 0.3),
        child: ListTile(
          leading: Icon(icon, color: Colors.grey, size: 30),
          title: Text(title, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
