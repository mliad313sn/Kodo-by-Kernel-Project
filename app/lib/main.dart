/// KODO — the application entry point.
///
/// This file is `FR-M19-01`, and until PO decision `D-012` it did not exist: eighteen
/// modules were built, all eighteen passed their acceptance tests, and none of them was
/// the application. A decomposition that names every organ and no body produces exactly
/// that.
///
/// What happens here, in order, and nothing else:
///   1. restore the session — no network call, no login wall (`FR-M19-05`);
///   2. load whatever content packs are installed (M14);
///   3. hand both to the shell.
library;

import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/pack_loader.dart';
import 'src/platform.dart';
import 'src/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final shell = await KodoShell.restore(await defaultSessionStore());
  final content = await loadInstalledContent();

  runApp(KodoApp(shell: shell, content: content));
}
