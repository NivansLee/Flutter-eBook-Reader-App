import 'package:flutter/material.dart';

class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licenses'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildLicenseSection(
            'Flutter',
            'A UI toolkit for building beautiful, natively compiled applications.',
            'Copyright 2014 The Flutter Authors. All rights reserved.\n\n'
            'Redistribution and use in source and binary forms, with or without modification, '
            'are permitted provided that the following conditions are met:\n\n'
            '* Redistributions of source code must retain the above copyright '
            'notice, this list of conditions and the following disclaimer.',
          ),
          const Divider(),
          _buildLicenseSection(
            'epubx',
            'EPUB parsing and rendering library for Dart.',
            'MIT License\n\n'
            'Copyright (c) 2018 Seva Vaskin\n\n'
            'Permission is hereby granted, free of charge, to any person obtaining a copy '
            'of this software and associated documentation files.',
          ),
          const Divider(),
          _buildLicenseSection(
            'provider',
            'A wrapper around InheritedWidget to make them easier to use and more reusable.',
            'MIT License\n\n'
            'Copyright (c) 2019 Remi Rousselet\n\n'
            'Permission is hereby granted, free of charge, to any person obtaining a copy '
            'of this software and associated documentation files.',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLicenseSection(String title, String description, String licenseText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            title: const Text('View License'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  licenseText,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 