import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/issue.dart';
import '../services/notice_pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';

/// Visualização do ofício em PDF, com opções de baixar e imprimir.
class NoticePreviewScreen extends StatefulWidget {
  final Issue issue;
  const NoticePreviewScreen({super.key, required this.issue});

  @override
  State<NoticePreviewScreen> createState() => _NoticePreviewScreenState();
}

class _NoticePreviewScreenState extends State<NoticePreviewScreen> {
  final _service = NoticePdfService();
  late Future<Uint8List> _pdf;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _pdf = _service.build(widget.issue);
  }

  void _retry() {
    setState(() {
      _attempt++;
      _pdf = _service.build(widget.issue);
    });
  }

  Future<void> _download() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _pdf;
      await Printing.sharePdf(
          bytes: bytes, filename: _service.fileName(widget.issue));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível baixar o PDF.')));
    }
  }

  Future<void> _print() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _pdf;
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: _service.fileName(widget.issue),
      );
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível imprimir o PDF.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Ofício Nº ${_service.noticeNumber(widget.issue)}')),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              key: ValueKey(_attempt),
              build: (_) => _pdf,
              useActions: false,
              pdfFileName: _service.fileName(widget.issue),
              loadingWidget: const LoadingView(),
              onError: (context, error) => ErrorView(
                message: 'Não foi possível gerar o PDF.',
                onRetry: _retry,
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _print,
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Imprimir'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _download,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Baixar PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
