/// The shell itself (`FR-M19-01`, `FR-M19-02`, `FR-M19-03`).
///
/// It holds the session, applies the preferences app-wide, and owns the navigation graph.
/// It computes nothing about learning: every screen it shows is fed by a module.
library;

import 'package:flutter/material.dart';
import 'package:kodo_access/kodo_access.dart';

import 'session.dart';

/// The routes the shell knows. A closed set, because `FR-M19-02` asks that every screen be
/// reachable and every screen exitable — a claim you can only test against a finite graph.
enum KodoScreen {
  profiles('profiles', root: false),

  /* §9.1's five root destinations, always reachable, never more:
     Carte · Entraînement · Studio · Galerie · Moi.

     They were missing from the first shell, which had worlds/concept/item/studio/settings
     — close, but not the architecture the specification names, and the difference matters:
     "Entraînement — today's mix, one button" is the whole of how a child who does not know
     what to do next finds something to do. */
  carte('carte', root: true),
  entrainement('entrainement', root: true),
  studio('studio', root: true),
  galerie('galerie', root: true),
  moi('moi', root: true),

  // Reached from a root, never roots themselves.
  concept('concept', root: false),
  item('item', root: false),
  settings('settings', root: false);

  const KodoScreen(this.route, {required this.root});
  final String route;

  /// Whether this is one of the five §9.1 destinations the tab bar shows.
  final bool root;

  static List<KodoScreen> get roots =>
      [for (final s in KodoScreen.values) if (s.root) s];

  static KodoScreen byRoute(String route) => KodoScreen.values
      .firstWhere((s) => s.route == route, orElse: () => KodoScreen.carte);
}

/// Which screens a child can reach from where.
///
/// Declared rather than implied, so the navigation test can walk it. Every screen except
/// the first has a way back; `profiles` is the root and needs none.
const Map<KodoScreen, List<KodoScreen>> navigationGraph = {
  KodoScreen.profiles: [KodoScreen.carte],
  /* The five roots reach each other through the tab bar, so they are not children of one
     another — `goRoot` handles that, and a tab is not a journey you come back from. */
  KodoScreen.carte: [KodoScreen.concept],
  KodoScreen.entrainement: [KodoScreen.item],
  KodoScreen.studio: [],
  KodoScreen.galerie: [],
  KodoScreen.moi: [KodoScreen.settings],
  KodoScreen.concept: [KodoScreen.item],
  KodoScreen.item: [],
  KodoScreen.settings: [],
};

/// The shell's state: the session, and the stack a child walked to get here.
class KodoShell extends ChangeNotifier {
  KodoShell({required SessionStore store, Session? session})
      : _store = store,
        _session = session ?? const Session() {
    _stack = [
      _session.profileId == null ? KodoScreen.profiles : _restoredScreen()
    ];
  }

  final SessionStore _store;
  Session _session;
  late List<KodoScreen> _stack;

  Session get session => _session;
  KodoScreen get current => _stack.last;
  List<KodoScreen> get stack => List.unmodifiable(_stack);
  bool get canGoBack => _stack.length > 1;

  KodoScreen _restoredScreen() => KodoScreen.byRoute(_session.lastPlace.screen);

  /// Cold start (`FR-M19-05`). Reads the session and goes where the child was.
  ///
  /// No login wall: a profile is chosen, never authenticated, and a returning child does
  /// not choose again. No network call — the store is a local file.
  static Future<KodoShell> restore(SessionStore store) async {
    final session = Session.decode(await store.read());
    return KodoShell(store: store, session: session);
  }

  // --- navigation (FR-M19-02) ------------------------------------------------------------

  /// Switches to one of the five roots (§9.1).
  ///
  /// A tab is not a journey: it replaces the stack rather than growing it, so a child who
  /// taps four tabs does not have four back presses waiting for them.
  void goRoot(KodoScreen root) {
    if (!root.root) throw StateError('${root.route} is not a root destination');
    _stack = [root];
    _remember(root);
  }

  void go(KodoScreen to, {int? worldId, String? conceptId, String? itemId}) {
    if (!(navigationGraph[current] ?? const []).contains(to)) {
      // A move the graph does not have is a bug in a caller, not a screen a child found.
      throw StateError('no route from ${current.route} to ${to.route}');
    }
    _stack.add(to);
    _remember(to, worldId: worldId, conceptId: conceptId, itemId: itemId);
  }

  /// Every screen is exitable. The root is not popped, so a child cannot reach a blank app.
  void back() {
    if (!canGoBack) return;
    _stack.removeLast();
    _remember(current);
  }

  /// Choosing a profile is what replaces a login. It resets the stack, because the previous
  /// child's place is not this child's place.
  void chooseProfile(String profileId) {
    _session =
        _session.copyWith(profileId: profileId, lastPlace: LastPlace.home);
    _stack = [KodoScreen.carte];
    _save();
    notifyListeners();
  }

  void _remember(KodoScreen screen,
      {int? worldId, String? conceptId, String? itemId}) {
    _session = _session.copyWith(
      lastPlace: LastPlace(
        screen: screen.route,
        worldId: worldId ?? _session.lastPlace.worldId,
        conceptId: conceptId ?? _session.lastPlace.conceptId,
        itemId: itemId ?? _session.lastPlace.itemId,
      ),
    );
    _save();
    notifyListeners();
  }

  // --- preferences, applied app-wide (FR-M19-04) -----------------------------------------

  void setInterfaceLocale(UiLocale locale) {
    _session = _session.copyWith(interfaceLocale: locale);
    _save();
    notifyListeners();
  }

  /// A different setting from the one above, on purpose.
  void setKeywordLocale(String code) {
    _session = _session.copyWith(keywordLocale: code);
    _save();
    notifyListeners();
  }

  void setAccessibility(AccessibilityPreferences prefs) {
    _session = _session.copyWith(accessibility: prefs);
    _save();
    notifyListeners();
  }

  // --- persistence (FR-M19-03) -----------------------------------------------------------

  /// Called when the app goes to the background.
  Future<void> onBackground() => _store.write(_session.encode());

  /// Writes on EVERY change, with no debounce.
  ///
  /// A debounce was the first thing written here and it was wrong. The session is about
  /// three hundred bytes and a child changes it a few times a minute, so batching saves
  /// nothing measurable — and it buys a window in which a force-kill loses the child's
  /// place, which is precisely what `FR-M19-03` forbids. The write is fire-and-forget
  /// because a failed write means a lost place, never a lost frame: [FileSessionStore]
  /// swallows its own errors and the child keeps playing.
  void _save() {
    _store.write(_session.encode());
  }

  /// Waits for the write to land. Used by tests and at shutdown.
  Future<void> flush() => onBackground();
}

/// Hands the shell down the widget tree.
class ShellScope extends InheritedNotifier<KodoShell> {
  const ShellScope({super.key, required KodoShell shell, required super.child})
      : super(notifier: shell);

  static KodoShell of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShellScope>();
    assert(scope != null, 'no ShellScope above this widget');
    return scope!.notifier!;
  }
}
