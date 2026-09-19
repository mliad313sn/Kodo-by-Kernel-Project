/// The web binding.
///
/// The browser has no filesystem, so the two io affordances have no equivalent here:
///
/// * **the session is not persisted.** A web child loses their place when the tab closes.
///   That is a real gap against `FR-M19-03`, recorded rather than hidden: closing it needs
///   a storage binding, and the reference device — Android 11, 2 GB — is where the
///   requirement is measured. `NFR-COMP-01` lists the browser as a supported target and
///   this is the honest state of it.
/// * **there is no sideloading.** A browser cannot read a teacher's SD card, which is what
///   `FR-M12-03` is about; the web build gets the packs shipped with it and nothing else.
library;

import 'session.dart';

Future<SessionStore> defaultSessionStore() async => MemorySessionStore();

Future<List<(String, String)>> sideloadedPackJson() async => const [];
