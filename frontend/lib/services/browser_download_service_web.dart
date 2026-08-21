/// Web implementation of [BrowserDownloadService]: triggers a browser file
/// download from in-memory bytes, entirely client-side via a temporary
/// object URL and anchor click.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class BrowserDownloadService {
  const BrowserDownloadService();

  void downloadBytes(Uint8List bytes, String mimeType, String fileName) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    _triggerDownload(blob, fileName);
  }

  void downloadText(String content, String mimeType, String fileName) {
    final blob = web.Blob(
      [content.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    _triggerDownload(blob, fileName);
  }

  void _triggerDownload(web.Blob blob, String fileName) {
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName;
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }
}
