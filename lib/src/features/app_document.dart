import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ui/common.dart';
import '../ui/layout.dart';

enum AppDocument {
  guide('User guide', 'assets/documents/guide.json'),
  privacy('Privacy policy', 'assets/documents/privacy.json');

  const AppDocument(this.title, this.asset);
  final String title;
  final String asset;
}

/// Bundled documents remain readable without connectivity or website hosting.
class AppDocumentPage extends StatefulWidget {
  const AppDocumentPage({super.key, required this.document});
  final AppDocument document;

  @override
  State<AppDocumentPage> createState() => _AppDocumentPageState();
}

class _AppDocumentPageState extends State<AppDocumentPage> {
  late final Future<Map<String, dynamic>> _content = _load();

  Future<Map<String, dynamic>> _load() async =>
      jsonDecode(await rootBundle.loadString(widget.document.asset))
          as Map<String, dynamic>;

  Future<void> _open(String value) async {
    try {
      final uri = Uri.parse(value);
      if (uri.scheme != 'https' && uri.scheme != 'mailto') {
        throw const FormatException('Unsupported link');
      }
      if (!await launchUrl(uri)) throw StateError('Link unavailable');
    } catch (_) {
      if (mounted) {
        message(context, 'Could not open this link. Try again later.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: BowlLayout.toolbarHeight(context),
      title: Text(widget.document.title),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _content,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('This document could not be opened.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final content = snapshot.data!;
        return SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: BowlLayout.settingsWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Updated ${content['updated']}'),
                    for (final section in content['sections'] as List) ...[
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          section['heading'] as String,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      for (final paragraph in section['paragraphs'] as List)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            paragraph as String,
                            style: const TextStyle(height: 1.6),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    for (final link in content['links'] as List)
                      TextButton.icon(
                        onPressed: () => _open(link['url'] as String),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(link['label'] as String),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
