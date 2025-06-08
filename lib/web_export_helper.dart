import 'dart:html' as html;
import 'dart:typed_data';

void downloadFileOnWeb(String csvData, String fileName) {
  final List<int> bytes = Uint8List.fromList(csvData.codeUnits);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor =
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
  html.Url.revokeObjectUrl(url);
}
