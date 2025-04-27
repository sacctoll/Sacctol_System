import 'dart:html' as html;

void downloadTextFile(String content, String fileName) {
  final bytes = html.Blob([content]);
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
