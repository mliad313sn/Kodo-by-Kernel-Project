/// Loading what is installed (M14).
///
/// Two sources, in this order:
///   1. the packs shipped inside the app, as Flutter assets — this is what makes a fresh
///      install usable with the aircraft mode already on, which is `FR-M14-01`;
///   2. packs a teacher sideloaded, where the platform has a filesystem (`FR-M12-03`).
///
/// The shell reads packs; it does not author, verify or schedule them. Verification is
/// M14's `Sha256Integrity`, applied here rather than skipped, because a pack that fails
/// its own checksum must not reach a child.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:kodo_content/kodo_content.dart';

import 'app.dart';
import 'platform.dart';

/// The worlds shipped with the app. Listed rather than globbed: an asset bundle has no
/// directory listing, and a world that is not named here is a world nobody decided to
/// ship.
const bundledWorlds = [0, 1, 2];

Future<KodoContent> loadInstalledContent() async {
  final library = ContentLibrary();
  final packs = <ContentPack>[];

  Future<void> tryInstall(String packJson, String manifestJson) async {
    try {
      final pack =
          ContentPack.fromJson(jsonDecode(packJson) as Map<String, Object?>);
      final manifest = PackManifest.fromJson(
          jsonDecode(manifestJson) as Map<String, Object?>);
      // M14's own verifier. A refusal is a refusal; the shell does not second-guess it.
      if (library.install(pack, manifest) == null) packs.add(pack);
    } catch (_) {
      // A pack that will not parse is a pack that is not installed.
    }
  }

  for (final world in bundledWorlds) {
    try {
      await tryInstall(
        await rootBundle.loadString('assets/content/world$world.json'),
        await rootBundle.loadString('assets/content/world$world.manifest.json'),
      );
    } catch (_) {
      // Not shipped in this build.
    }
  }

  for (final (packJson, manifestJson) in await sideloadedPackJson()) {
    await tryInstall(packJson, manifestJson);
  }

  return KodoContent(
    packs: packs,
    /* Profiles come from M13's local store. Until that store is wired to disk, the shell
       offers the one profile a first run needs — it does not invent a child's name, it
       uses the word the interface already has for "me". */
    profileNames: const {'local': 'Moi'},
  );
}
