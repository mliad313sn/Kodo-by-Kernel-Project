/// The io binding: a file on disk, and sideloaded packs (`FR-M19-01`).
library;

import 'dart:io';

import 'file_session_store.dart';
import 'session.dart';

/// Where the session lives on a device with a filesystem. Beside the app's own data,
/// never in a cache directory the system may clear — losing a child's place is not a
/// cache miss.
Future<SessionStore> defaultSessionStore() async {
  final home = Platform.environment['KODO_DATA_DIR'] ??
      Platform.environment['HOME'] ??
      Directory.systemTemp.path;
  final dir = Directory('$home/.kodo');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return FileSessionStore(File('${dir.path}/session.json'));
}

/// Packs a teacher sideloaded from an SD card or a hotspot (`FR-M12-03`), on top of the
/// ones shipped with the app. Returns the raw JSON pairs; verification is the caller's,
/// because it is M14's and not the platform's.
Future<List<(String, String)>> sideloadedPackJson() async {
  final configured = Platform.environment['KODO_CONTENT_DIR'];
  final dir = Directory(
      configured == null || configured.isEmpty ? 'content' : configured);
  if (!dir.existsSync()) return const [];

  final out = <(String, String)>[];
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'world\d+\.json$').hasMatch(f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final manifest = File(file.path.replaceFirst('.json', '.manifest.json'));
    if (!manifest.existsSync()) continue;
    try {
      out.add((file.readAsStringSync(), manifest.readAsStringSync()));
    } catch (_) {
      // A pack that will not read is a pack that is not installed.
    }
  }
  return out;
}
