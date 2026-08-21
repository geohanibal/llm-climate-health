/// Non-web fallback for [BrowserDownloadService]. The real implementation
/// (browser_download_service_web.dart) needs `package:web`'s JS-interop
/// bindings, which only compile for an actual web/JS target — this stub is
/// selected instead whenever the app or its test suite runs on the Dart VM
/// (e.g. `flutter test`), so exporting/uploading code stays testable there
/// without ever touching a browser.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:typed_data';

class BrowserDownloadService {
  const BrowserDownloadService();

  void downloadBytes(Uint8List bytes, String mimeType, String fileName) {
    throw UnsupportedError('File downloads are only available when running as a web app.');
  }

  void downloadText(String content, String mimeType, String fileName) {
    throw UnsupportedError('File downloads are only available when running as a web app.');
  }
}
