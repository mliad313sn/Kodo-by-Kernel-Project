/// The shell's own state (`FR-M19-03`, `FR-M19-04`, `FR-M19-05`).
///
/// This is the whole of what M19 remembers, and it is deliberately small: who is using the
/// app, what language they read, what language they code in, their accessibility
/// preferences, and where they were. Nothing else.
///
/// In particular it holds **no progress, no mastery and no attempt** — those belong to M7
/// and are computed from attempts, never stored as a total. The shell remembers the
/// *place*, not the *learning*.
library;

import 'dart:convert';

import 'package:kodo_access/kodo_access.dart';

/// Where the child was when the app last stopped.
///
/// `FR-M19-05`: cold start goes back here, with no login wall and no network call. A child
/// who was halfway through an item returns to that item.
class LastPlace {
  const LastPlace(
      {required this.screen, this.worldId, this.conceptId, this.itemId});

  /// A route name the shell knows. Never a class, so it survives serialisation.
  final String screen;
  final int? worldId;
  final String? conceptId;
  final String? itemId;

  static const home = LastPlace(screen: 'worlds');

  Map<String, Object?> toJson() => {
        'screen': screen,
        if (worldId != null) 'world': worldId,
        if (conceptId != null) 'concept': conceptId,
        if (itemId != null) 'item': itemId,
      };

  static LastPlace fromJson(Map<String, Object?> j) => LastPlace(
        screen: (j['screen'] as String?) ?? 'worlds',
        worldId: j['world'] as int?,
        conceptId: j['concept'] as String?,
        itemId: j['item'] as String?,
      );
}

/// Everything the shell restores on a cold start.
class Session {
  const Session({
    this.profileId,
    this.interfaceLocale = UiLocale.fr,
    this.keywordLocale = 'fr',
    this.accessibility = const AccessibilityPreferences(),
    this.lastPlace = LastPlace.home,
  });

  /// Null means nobody has chosen a profile yet — the only screen that shows.
  final String? profileId;

  /// `FR-M19-04`: the language of the screens…
  final UiLocale interfaceLocale;

  /// …and the language of the code, which is a different choice. A child may read French
  /// screens and write English keywords; §6 asks for exactly that, and one setting for
  /// both would make it impossible.
  final String keywordLocale;

  final AccessibilityPreferences accessibility;
  final LastPlace lastPlace;

  Session copyWith({
    String? profileId,
    UiLocale? interfaceLocale,
    String? keywordLocale,
    AccessibilityPreferences? accessibility,
    LastPlace? lastPlace,
  }) =>
      Session(
        profileId: profileId ?? this.profileId,
        interfaceLocale: interfaceLocale ?? this.interfaceLocale,
        keywordLocale: keywordLocale ?? this.keywordLocale,
        accessibility: accessibility ?? this.accessibility,
        lastPlace: lastPlace ?? this.lastPlace,
      );

  Map<String, Object?> toJson() => {
        if (profileId != null) 'profile': profileId,
        'interface': interfaceLocale.code,
        'keywords': keywordLocale,
        'textScale': accessibility.textScale,
        'font': accessibility.font.name,
        'reducedMotion': accessibility.reducedMotion,
        'narration': accessibility.narrationOn,
        'highContrast': accessibility.highContrast,
        'lastPlace': lastPlace.toJson(),
      };

  static Session fromJson(Map<String, Object?> j) => Session(
        profileId: j['profile'] as String?,
        interfaceLocale: UiLocale.byCode((j['interface'] as String?) ?? 'fr'),
        keywordLocale: (j['keywords'] as String?) ?? 'fr',
        accessibility: AccessibilityPreferences(
          textScale: (j['textScale'] as num?)?.toDouble() ?? 1.0,
          font: ReadingFont.values.firstWhere(
            (f) => f.name == j['font'],
            orElse: () => ReadingFont.standard,
          ),
          reducedMotion: (j['reducedMotion'] as bool?) ?? false,
          narrationOn: (j['narration'] as bool?) ?? true,
          highContrast: (j['highContrast'] as bool?) ?? false,
        ),
        lastPlace: j['lastPlace'] == null
            ? LastPlace.home
            : LastPlace.fromJson(j['lastPlace']! as Map<String, Object?>),
      );

  String encode() => jsonEncode(toJson());

  /// Never throws. A session file that cannot be read is a child who loses their place,
  /// not a child who cannot start — so a corrupt file yields a fresh session rather than
  /// an exception on the first frame.
  static Session decode(String? text) {
    if (text == null || text.trim().isEmpty) return const Session();
    try {
      return Session.fromJson(jsonDecode(text) as Map<String, Object?>);
    } catch (_) {
      return const Session();
    }
  }
}

/// Where the session is kept.
///
/// An interface, so the shell does not depend on a storage plugin and the tests do not
/// need one. The production binding writes a file in the app's own directory; there is no
/// network call, which is what `FR-M19-05` promises.
abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String text);
}

/// The in-memory store. Used by tests and by the first run, before anything is saved.
class MemorySessionStore implements SessionStore {
  MemorySessionStore([this._text]);
  String? _text;

  @override
  Future<String?> read() async => _text;

  @override
  Future<void> write(String text) async => _text = text;
}
