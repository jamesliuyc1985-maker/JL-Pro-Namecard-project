import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadCsvWeb(String fileName, String csvContent) {
  final bom = '\uFEFF';
  final bytes = utf8.encode('$bom$csvContent');
  final blob = html.Blob([Uint8List.fromList(bytes)], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
