import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:share_plus/share_plus.dart';
import '../../profile/providers/active_profile_provider.dart';

class FilePreviewScreen extends ConsumerStatefulWidget {
  final String fileUrl;
  final String? activeProfileName;
  final String? documentType;

  const FilePreviewScreen({
    super.key,
    required this.fileUrl,
    this.activeProfileName,
    this.documentType,
  });

  @override
  ConsumerState<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends ConsumerState<FilePreviewScreen> {
  bool _isPdf = false;

  @override
  void initState() {
    super.initState();
    final path = Uri.tryParse(widget.fileUrl)?.path.toLowerCase() ?? widget.fileUrl.toLowerCase();
    _isPdf = path.endsWith('.pdf');
    print('[Preview] File type detected: ${_isPdf ? 'PDF' : 'Image'} (${widget.fileUrl})');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPdf ? 'PDF Preview' : 'Image Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () async {
              if (widget.fileUrl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to share report.')),
                );
                return;
              }
              final activeProfileName = widget.activeProfileName ?? ref.read(activeProfileNameProvider).value ?? 'Self';
              final docType = widget.documentType ?? 'Report';
              final shareText = 'HealthSathi Medical Report\n\nProfile: $activeProfileName\n\nDocument Type: $docType\n\nView Report:\n${widget.fileUrl}';
              await SharePlus.instance.share(ShareParams(text: shareText));
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () async {
              print('[Preview] Opening in external browser: ${widget.fileUrl}');
              await launchInBrowser(widget.fileUrl);
            },
          ),
        ],
      ),
      body: _isPdf ? _buildPdfBody() : _buildImageBody(),
    );
  }

  Widget _buildImageBody() {
    print('[Preview] Image viewer opened');
    return Center(
      child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: widget.fileUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) {
              final msg = 'Image load failed: $error';
              print('[Preview] $msg');
              return _buildErrorView(msg);
            },
          ),
      ),
    );
  }

  Widget _buildPdfBody() {
    return PdfNetworkOrMemoryViewer(
      url: widget.fileUrl,
      onError: (msg) {
        print('[Preview] PDF viewer error: $msg');
      },
    );
  }

  Widget _buildErrorView(String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          SelectableText(widget.fileUrl, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open in browser'),
            onPressed: () => launchInBrowser(widget.fileUrl),
          ),
        ],
      ),
    );
  }

  Future<void> launchInBrowser(String url) async {
    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('[Preview] Could not open URL externally: $e');
    }
  }
}

class PdfNetworkOrMemoryViewer extends StatefulWidget {
  final String url;
  final void Function(String message)? onError;

  const PdfNetworkOrMemoryViewer({super.key, required this.url, this.onError});

  @override
  State<PdfNetworkOrMemoryViewer> createState() => _PdfNetworkOrMemoryViewerState();
}

class _PdfNetworkOrMemoryViewerState extends State<PdfNetworkOrMemoryViewer> {
  bool _useMemory = false;
  bool _isLoading = true;
  bool _isFallbackDownloading = false;
  Uint8List? _bytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('[Preview] PDF loading started');
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorView(_error!);
    }

    if (_useMemory && _bytes != null) {
      return SfPdfViewer.memory(
        _bytes!,
        onDocumentLoaded: (details) {
          print('[Preview] PDF loaded successfully (memory)');
        },
        onDocumentLoadFailed: (details) {
          final msg = 'PDF memory load failed: ${details.error}';
          print('[Preview] $msg');
          setState(() {
            _error = msg;
          });
        },
      );
    }

    return Stack(
      children: [
        SfPdfViewer.network(
          widget.url,
          onDocumentLoaded: (details) {
            print('[Preview] PDF loaded successfully (network)');
            setState(() {
              _isLoading = false;
            });
          },
          onDocumentLoadFailed: (details) async {
            final networkError = 'PDF network load failed: ${details.error}';
            print('[Preview] $networkError');
            await _startFallbackDownload(networkError);
          },
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Future<void> _startFallbackDownload(String networkError) async {
    setState(() {
      _isFallbackDownloading = true;
      _isLoading = false;
    });

    print('[Preview] Starting fallback download');
    try {
      final response = await http.get(Uri.parse(widget.url)).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        _bytes = response.bodyBytes;
        print('[Preview] Fallback download success');
        setState(() {
          _useMemory = true;
          _isFallbackDownloading = false;
        });
      } else {
        final msg = 'Fallback download failed: HTTP ${response.statusCode}';
        print('[Preview] $msg');
        setState(() {
          _error = '$networkError\n$msg';
          _isFallbackDownloading = false;
        });
        widget.onError?.call(_error!);
      }
    } catch (e) {
      final msg = 'Fallback download failed: $e';
      print('[Preview] $msg');
      setState(() {
        _error = '$networkError\n$msg';
        _isFallbackDownloading = false;
      });
      widget.onError?.call(_error!);
    }
  }

  Widget _buildErrorView(String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          SelectableText(widget.url, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            onPressed: _retry,
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open in browser'),
            onPressed: () async {
              await launchUrlString(widget.url, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _bytes = null;
      _useMemory = false;
      _isLoading = true;
      _isFallbackDownloading = false;
    });
  }
}
