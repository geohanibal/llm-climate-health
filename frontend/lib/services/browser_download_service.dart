/// Triggers a browser file download from in-memory bytes. Shared by every
/// export feature (CSV, JSON, PDF) so there is exactly one place that talks
/// to the browser's download machinery.
///
/// The real implementation needs `package:web`'s JS-interop bindings, which
/// only compile for a web/JS target — conditionally exporting the stub
/// (browser_download_service_stub.dart) everywhere else keeps every
/// consumer of this file (and its own test suite, via `flutter test` on the
/// Dart VM) compiling and running without needing a browser at all.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

export 'browser_download_service_stub.dart'
    if (dart.library.html) 'browser_download_service_web.dart';
