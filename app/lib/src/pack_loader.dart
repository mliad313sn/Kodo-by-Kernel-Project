/// Loading what is installed (M14).
///
/// Two sources, in this order:
///   1. the packs shipped inside the app, as Flutter assets — this is what makes a fresh
///      install usable with the aircraft mode already on, which is `FR-M14-01`;
///   2. packs a teacher sideloaded, where the platform has a filesystem (`FR-M12-03`).
///
/// The shell reads packs; it does not author, verify or schedule them. Verification is
/// M14's `Sha256Integrity`, applied to what arrived from outside and *not* to what is
/// inside the app's own signed bundle — see [_verifyBundled] for why that distinction is
/// a cold start rather than a shortcut.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:kodo_content/kodo_content.dart';

import 'app.dart';
import 'platform.dart';

/// The worlds shipped with the app. Listed rather than globbed: an asset bundle has no
/// directory listing, and a world that is not named here is a world nobody decided to
/// ship.
///
/// It read `[0, 1, 2]` for as long as there were three worlds to read, and went on
/// reading it after the other ten were authored. The files were in the bundle, the
/// pubspec shipped them, every content test passed because they read the JSON off disk —
/// and the built application could not reach 974 of its 1 240 exercises. A list that has
/// to be edited when content is added is a list that will not be; the test beside this
/// one now compares it against the assets that are actually present.
const bundledWorlds = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

/// Whether a pack that came out of the app's own asset bundle is re-hashed at launch.
///
/// **No, and deliberately.** SHA-256 over thirteen worlds is about 4.7 MB of hashing:
/// half a second on a developer's machine and measured at two to three seconds on the
/// 2 GB reference device — spent before the first screen, on every cold start, to answer
/// a question that cannot come out wrong. An asset inside a signed APK cannot be modified
/// without breaking the signature the OS already checked, and the CI gate re-authors every
/// world and diffs it, so the bytes in the bundle are the bytes that passed the publish
/// gate.
///
/// A **sideloaded** pack is the opposite case in every respect: it arrived from an SD card
/// or a teacher's laptop, nothing has vouched for it, and it is verified in full. That is
/// the case `FR-M14-02` is about.
const _verifyBundled = false;

Future<KodoContent> loadInstalledContent() async {
  final library = ContentLibrary();
  final packs = <ContentPack>[];

  Future<void> tryInstall(String packJson, String manifestJson,
      {required bool verify}) async {
    try {
      final pack =
          ContentPack.fromJson(jsonDecode(packJson) as Map<String, Object?>);
      final manifest = PackManifest.fromJson(
          jsonDecode(manifestJson) as Map<String, Object?>);
      // M14's own verifier. A refusal is a refusal; the shell does not second-guess it.
      if (library.install(pack, manifest, verify: verify) == null) {
        packs.add(pack);
      }
    } catch (_) {
      // A pack that will not parse is a pack that is not installed.
    }
  }

  for (final world in bundledWorlds) {
    try {
      await tryInstall(
        await rootBundle.loadString('assets/content/world$world.json'),
        await rootBundle.loadString('assets/content/world$world.manifest.json'),
        verify: _verifyBundled,
      );
    } catch (_) {
      // Not shipped in this build.
    }
  }

  /* Everything from outside the bundle is hashed in full. A pack off an SD card has had
     nothing vouch for it. */
  for (final (packJson, manifestJson) in await sideloadedPackJson()) {
    await tryInstall(packJson, manifestJson, verify: true);
  }

  return KodoContent(
    packs: packs,
    /* Profiles come from M13's local store. Until that store is wired to disk, the shell
       offers the one profile a first run needs — it does not invent a child's name, it
       uses the word the interface already has for "me". */
    profileNames: const {'local': 'Moi'},
  );
}
