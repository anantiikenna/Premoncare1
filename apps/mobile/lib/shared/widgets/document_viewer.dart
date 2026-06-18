import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/supabase_locator.dart';
import 'glass_card.dart';

class DocumentViewer extends StatefulWidget {
  final String bucket;
  final String path;
  final String title;
  final String? url;

  const DocumentViewer({
    super.key,
    required this.bucket,
    required this.path,
    required this.title,
    this.url,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  late Future<String?> _urlFuture;

  @override
  void initState() {
    super.initState();
    if (widget.url != null) {
      _urlFuture = Future.value(widget.url);
    } else {
      _urlFuture = _getSignedUrl();
    }
  }

  Future<String?> _getSignedUrl() async {
    try {
      final response = await supabase.storage
          .from(widget.bucket)
          .createSignedUrl(widget.path, 1800); // 30 minutes
      return response;
    } catch (e) {
      debugPrint('Error generating signed URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        leading: const CloseButton(color: Colors.white),
      ),
      body: FutureBuilder<String?>(
        future: _urlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load document',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() { _urlFuture = _getSignedUrl(); }),
                    child: const Text('Retry', style: TextStyle(color: Color(0xFF6366F1))),
                  ),
                ],
              ),
            );
          }

          final url = snapshot.data!;
          final isImage = _isImage(widget.path);

          if (isImage) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  url,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            );
          }

          // Fallback for non-images (PDFs, etc.)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: GlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.white, size: 80),
                    const SizedBox(height: 24),
                    const Text(
                      'Document format not supported for in-app preview',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PDF and other complex formats must be opened in an external viewer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _launchUrl(url),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open External Viewer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isImage(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.webp');
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external viewer')),
        );
      }
    }
  }
}
