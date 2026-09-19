/// What differs between a phone and a browser, and nothing else.
///
/// The shell itself is platform-free: it is handed a [SessionStore] and a list of packs.
/// This is the one seam where `dart:io` is allowed to exist, and the conditional export
/// keeps it out of the web build entirely — a `dart:io` call that compiles for the web
/// and throws on the first frame is how an app builds successfully and shows a blank page.
library;

export 'platform_io.dart' if (dart.library.js_interop) 'platform_web.dart';
