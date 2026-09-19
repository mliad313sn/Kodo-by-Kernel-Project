/// The production session store (`FR-M19-03`, `FR-M19-05`).
///
/// A file, written atomically. No network, no plugin, no database — the promise that a
/// cold start makes no network call is easiest to keep when there is nothing that could.
library;

import 'dart:io';

import 'session.dart';

class FileSessionStore implements SessionStore {
  FileSessionStore(this.file);

  final File file;

  @override
  Future<String?> read() async {
    try {
      return await file.exists() ? await file.readAsString() : null;
    } catch (_) {
      /* An unreadable session is a child who loses their place, not a child who cannot
         start. `Session.decode` turns null into a fresh session. */
      return null;
    }
  }

  @override
  Future<void> write(String text) async {
    /* Write beside, then rename. A process killed mid-write leaves the previous session
       intact rather than a truncated one — which is the difference between losing this
       session and losing every session. */
    final temp = File('${file.path}.tmp');
    try {
      await temp.writeAsString(text, flush: true);
      await temp.rename(file.path);
    } catch (_) {
      // Storage full or read-only: the child keeps playing, they just lose their place.
    }
  }
}
