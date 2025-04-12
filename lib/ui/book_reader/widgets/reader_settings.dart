import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/reader_settings_provider.dart';

class ReaderSettings extends StatelessWidget {
  const ReaderSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderSettingsProvider>(
      builder: (context, settings, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reader Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Font size slider
              Row(
                children: [
                  const Icon(Icons.text_fields),
                  const SizedBox(width: 8),
                  const Text('Font Size'),
                  Expanded(
                    child: Slider(
                      value: settings.fontSize,
                      min: 12,
                      max: 24,
                      divisions: 6,
                      label: settings.fontSize.round().toString(),
                      onChanged: (value) {
                        settings.setFontSize(value);
                      },
                    ),
                  ),
                ],
              ),
              // Brightness slider
              Row(
                children: [
                  const Icon(Icons.brightness_6),
                  const SizedBox(width: 8),
                  const Text('Brightness'),
                  Expanded(
                    child: Slider(
                      value: settings.brightness,
                      onChanged: (value) {
                        settings.setBrightness(value);
                      },
                    ),
                  ),
                ],
              ),
              // Theme selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildThemeOption(
                    context,
                    'Light',
                    ReaderTheme.light,
                    settings.theme == ReaderTheme.light,
                  ),
                  _buildThemeOption(
                    context,
                    'Sepia',
                    ReaderTheme.sepia,
                    settings.theme == ReaderTheme.sepia,
                  ),
                  _buildThemeOption(
                    context,
                    'Dark',
                    ReaderTheme.dark,
                    settings.theme == ReaderTheme.dark,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    ReaderTheme theme,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        Provider.of<ReaderSettingsProvider>(context, listen: false)
            .setTheme(theme);
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static void showReaderSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return const ReaderSettings();
      },
    );
  }
}
