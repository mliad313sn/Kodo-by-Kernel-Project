/// The web binding.
///
/// The browser has no filesystem, but it does have `localStorage`, which is what closes
/// `FR-M19-03` here: a web child who closes the tab comes back where they were. The first
/// version of this file returned a [MemorySessionStore] and recorded the gap honestly;
/// the gap is now shut rather than recorded, because "loses nothing" cannot be true on
/// one target and false on another.
///
/// What is still not possible here is **sideloading**: a browser cannot read a teacher's
/// SD card, which is what `FR-M12-03` is about, so the web build gets the packs shipped
/// with it and nothing else.
library;

import 'dart:js_interop';

import 'session.dart';

@JS('window.localStorage')
external _Storage? get _localStorage;

@JS()
@staticInterop
class _Storage {}

extension on _Storage {
  external String? getItem(String key);
  external void setItem(String key, String value);
}

/// The browser's own store, wrapped so a refusal is never a crash.
///
/// `localStorage` throws rather than returning null in a private window, when a quota is
/// reached, and when a site's data is blocked. A child in that browser loses their place
/// — which is the old behaviour, so the degradation is graceful — but they must never
/// lose their turn, so every access is guarded.
class BrowserSessionStore implements SessionStore {
  const BrowserSessionStore({this.key = 'kodo.session'});

  final String key;

  @override
  Future<String?> read() async {
    try {
      return _localStorage?.getItem(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String text) async {
    try {
      _localStorage?.setItem(key, text);
    } catch (_) {
      // A browser that refuses to store is a browser that forgets. It is not an error a
      // child should ever see.
    }
  }
}

Future<SessionStore> defaultSessionStore() async => const BrowserSessionStore();

Future<List<(String, String)>> sideloadedPackJson() async => const [];
