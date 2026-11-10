import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show networkImage;

import '../models/issue.dart';

/// Monta o ofício formal em PDF de uma ocorrência que atingiu a meta de apoio.
class NoticePdfService {
  static const _city = 'São Paulo';
  static const _recipient = 'Prefeitura Municipal de São Paulo';
  static const _months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  /// Ex.: "0002/2026".
  String noticeNumber(Issue issue) {
    final id = issue.id;
    final tail =
        id.length > 4 ? id.substring(id.length - 4) : id.padLeft(4, '0');
    return '$tail/${DateTime.now().year}';
  }

  String fileName(Issue issue) =>
      'oficio_${noticeNumber(issue).replaceAll('/', '_')}.pdf';

  String _two(int value) => value.toString().padLeft(2, '0');

  Future<pw.ImageProvider?> _loadPhoto(String url) async {
    try {
      if (url.isEmpty) return null;
      if (url.startsWith('data:')) {
        return pw.MemoryImage(
            base64Decode(url.substring(url.indexOf(',') + 1)));
      }
      return await networkImage(url).timeout(const Duration(seconds: 8));
    } catch (_) {
      return null; // sem foto, o ofício continua válido
    }
  }

  pw.TableRow _row(
      String label, String value, pw.TextStyle bold, pw.TextStyle base) {
    return pw.TableRow(
      children: [
        pw.Container(
          color: PdfColors.grey200,
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label, style: bold),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value, style: base),
        ),
      ],
    );
  }

  Future<Uint8List> build(Issue issue) async {
    final now = DateTime.now();
    final number = noticeNumber(issue);
    final photo = await _loadPhoto(issue.imageUrl);
    final percent = (issue.progress * 100).round();
    final threshold = (Issue.thresholdRatio * 100).round();

    final base = pw.TextStyle(fontSize: 11, lineSpacing: 3);
    final bold = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
    final small = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);

    final doc =
        pw.Document(title: 'Ofício Nº $number', author: 'Plataforma Zelo');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(56, 48, 56, 48),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: small),
        ),
        build: (context) => [
          // Cabeçalho
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'ZELO - ZELADORIA URBANA COLABORATIVA',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                    'Plataforma de registro e apoio comunitário a ocorrências urbanas',
                    style: small),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.indigo800, thickness: 1.2),
          pw.SizedBox(height: 14),

          // Número e data
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('OFÍCIO Nº $number', style: bold),
              pw.Text(
                '$_city, ${now.day} de ${_months[now.month - 1]} de ${now.year}.',
                style: base,
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // Destinatário e assunto
          pw.Text('À $_recipient', style: bold),
          pw.Text('Secretaria responsável pela zeladoria urbana da região',
              style: base),
          pw.SizedBox(height: 14),
          pw.Text('Assunto: Solicitação de providências - ${issue.title}',
              style: bold),
          pw.SizedBox(height: 14),

          // Texto
          pw.Text('Senhor(a) Secretário(a),', style: base),
          pw.SizedBox(height: 10),
          pw.Text(
            'A plataforma Zelo, por meio da qual a comunidade registra e apoia ocorrências de '
            'zeladoria urbana, vem, respeitosamente, encaminhar a Vossa Senhoria a solicitação '
            'abaixo identificada, a qual obteve o apoio de ${issue.likes} de '
            '${issue.activeRegionalUsers} moradores ativos da região ($percent%), superando o '
            'patamar mínimo de $threshold% (oitenta por cento) de apoio comunitário definido '
            'pela plataforma para a emissão deste ofício.',
            style: base,
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 12),
          pw.Text('Dados da ocorrência:', style: bold),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.6),
            columnWidths: {
              0: pw.FixedColumnWidth(105),
              1: pw.FlexColumnWidth(),
            },
            children: [
              _row('Ocorrência', issue.title, bold, base),
              _row('Categoria', issue.category, bold, base),
              _row('Endereço', issue.address, bold, base),
              _row(
                'Localização',
                '${issue.latitude.toStringAsFixed(5)}, ${issue.longitude.toStringAsFixed(5)}',
                bold,
                base,
              ),
              _row('Descrição', issue.description, bold, base),
              _row(
                'Apoio comunitário',
                '${issue.likes} de ${issue.activeRegionalUsers} moradores ($percent%)',
                bold,
                base,
              ),
              _row('Meta de apoio', 'Mínimo de $threshold% - atingida', bold,
                  base),
              _row('Situação', issue.status, bold, base),
            ],
          ),
          if (photo != null) ...[
            pw.SizedBox(height: 12),
            pw.Text('Registro fotográfico:', style: bold),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Container(
                height: 190,
                child: pw.Image(photo, fit: pw.BoxFit.contain),
              ),
            ),
          ],
          pw.SizedBox(height: 14),
          pw.Text(
            'Diante do exposto, e considerando o expressivo apoio da população diretamente '
            'afetada, solicita-se a adoção das providências cabíveis para a verificação e a '
            'solução da ocorrência, bem como o retorno a esta plataforma quanto aos '
            'encaminhamentos adotados.',
            style: base,
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 12),
          pw.Text('Atenciosamente,', style: base),

          // Assinatura
          pw.SizedBox(height: 36),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Container(width: 220, height: 0.8, color: PdfColors.grey800),
                pw.SizedBox(height: 4),
                pw.Text('Plataforma Zelo', style: bold),
                pw.Text('Zeladoria Urbana Colaborativa', style: base),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Documento gerado automaticamente pela plataforma Zelo em '
            '${_two(now.day)}/${_two(now.month)}/${now.year} às ${_two(now.hour)}:${_two(now.minute)}. '
            'Identificador da ocorrência: ${issue.id}.',
            style: small,
          ),
        ],
      ),
    );

    return doc.save();
  }
}
