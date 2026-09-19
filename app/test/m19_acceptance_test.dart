/// M19 acceptance tests.
///
/// *"The app builds and launches on every target. Every screen is reachable and every
/// screen is exitable. A force-kill during an item loses nothing, measured 50 times.
/// Setting the keyword language once changes every screen. Cold start is measured on the
/// reference device with aircraft mode on."*
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo/src/app.dart';
import 'package:kodo/src/session.dart';
import 'package:kodo/src/shell.dart';
import 'package:kodo/src/drawing_painter.dart';
import 'package:kodo_access/kodo_access.dart';
import 'package:kodo_content/kodo_content.dart';

KodoContent emptyContent() =>
    const KodoContent(packs: [], profileNames: {'local': 'Moi'});

/// Three installed worlds, so the map has something to draw. Shapes only — the real packs
/// are loaded from `assets/content/` and checked for drift by their own test.
KodoContent mapContent() => const KodoContent(
      packs: [
        ContentPack(
            world: 0,
            version: 1,
            nameKeys: {'fr': 'Bonjour Tika', 'en': 'Hello Tika'},
            concepts: {'C0.1': []},
            tutorials: [],
            items: []),
        ContentPack(
            world: 1,
            version: 1,
            nameKeys: {'fr': 'La tortue bouge', 'en': 'The turtle moves'},
            concepts: {'C1.1': []},
            tutorials: [],
            items: []),
        ContentPack(
            world: 2,
            version: 1,
            nameKeys: {'fr': 'Encore et encore', 'en': 'Again and again'},
            concepts: {'C2.1': []},
            tutorials: [],
            items: []),
      ],
      profileNames: {'local': 'Moi'},
    );

Future<void> pump(WidgetTester tester, KodoShell shell,
    {KodoContent? content}) async {
  await tester
      .pumpWidget(KodoApp(shell: shell, content: content ?? emptyContent()));
  await tester.pumpAndSettle();
}

void main() {
  group('FR-M19-01 · there is an application', () {
    testWidgets(
        'it starts, and the first screen is a child choosing themselves',
        (t) async {
      final shell = KodoShell(store: MemorySessionStore());
      await pump(t, shell);
      expect(find.byKey(const Key('profiles')), findsOneWidget);
      // No login wall: choosing is one tap, and there is no password anywhere on it.
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const Key('profile-local')), findsOneWidget);
    });

    testWidgets('choosing a profile reaches the map', (t) async {
      final shell = KodoShell(store: MemorySessionStore());
      await pump(t, shell);
      await t.tap(find.byKey(const Key('profile-local')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('worlds')), findsOneWidget);
      // And the five destinations of §9.1 are there, all of them, from the first screen.
      expect(find.byKey(const Key('root-bar')), findsOneWidget);
      for (final root in KodoScreen.roots) {
        expect(find.byKey(Key('root-${root.route}')), findsOneWidget,
            reason: '${root.route} is missing from the bar');
      }
    });
  });

  group('FR-M19-02 · every screen is reachable, and every screen is exitable',
      () {
    test('§9.1 is five destinations, no more and no fewer', () {
      /* Carte · Entraînement · Studio · Galerie · Moi. A sixth tab is the way a product
         like this dies: the specification is explicit that the parent space is NOT one,
         so the count is asserted rather than trusted. */
      expect(KodoScreen.roots.map((r) => r.route), [
        'carte',
        'entrainement',
        'studio',
        'galerie',
        'moi',
      ]);
    });

    test('the navigation graph has no dead end and no unreachable screen', () {
      /* Reachable from the root. The five destinations are reachable from each other
         through the bar rather than through the graph — `goRoot`, because a tab is not a
         journey — so the walk seeds with all of them. */
      final seen = <KodoScreen>{KodoScreen.profiles, ...KodoScreen.roots};
      final queue = <KodoScreen>[KodoScreen.profiles, ...KodoScreen.roots];
      while (queue.isNotEmpty) {
        for (final KodoScreen next
            in navigationGraph[queue.removeLast()] ?? const <KodoScreen>[]) {
          if (seen.add(next)) queue.add(next);
        }
      }
      expect(seen, hasLength(KodoScreen.values.length),
          reason: 'unreachable: ${KodoScreen.values.toSet().difference(seen)}');

      // And every screen is in the graph at all — a screen with no entry is a screen
      // somebody forgot to declare, which is how a dead end gets in.
      for (final screen in KodoScreen.values) {
        expect(navigationGraph.containsKey(screen), isTrue,
            reason: screen.route);
      }
    });

    testWidgets('every screen below the root offers a way back', (t) async {
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await pump(t, shell);

      /* Every non-root screen, walked from the root it hangs off. A root has no back
         button by design — it is where back goes. */
      for (final from in KodoScreen.roots) {
        for (final KodoScreen destination
            in navigationGraph[from] ?? const <KodoScreen>[]) {
          shell.goRoot(from);
          await t.pumpAndSettle();
          expect(find.byKey(const Key('back')), findsNothing,
              reason: '${from.route} is a root and must not offer a way back');
          shell.go(destination);
          await t.pumpAndSettle();
          expect(find.byKey(const Key('back')), findsOneWidget,
              reason: '${destination.route} has no way out');
          await t.tap(find.byKey(const Key('back')));
          await t.pumpAndSettle();
          expect(shell.current, from);
        }
      }
    });

    testWidgets('a tab replaces the journey rather than growing it', (t) async {
      /* Four taps on four tabs must not leave four back presses waiting. A child who
         wanders the bar and then presses back should be where they started, not walking
         a history they did not know they were making. */
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await pump(t, shell);
      for (final root in KodoScreen.roots) {
        await t.tap(find.byKey(Key('root-${root.route}')));
        await t.pumpAndSettle();
        expect(shell.current, root);
        expect(shell.stack, hasLength(1), reason: 'a tab grew the stack');
        expect(shell.canGoBack, isFalse);
      }
    });

    testWidgets(
        'the root cannot be popped, so a child cannot reach a blank app',
        (t) async {
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await pump(t, shell);
      for (var i = 0; i < 5; i++) {
        shell.back();
      }
      await t.pumpAndSettle();
      expect(shell.current, KodoScreen.carte);
      expect(find.byKey(const Key('worlds')), findsOneWidget);
    });

    test('a move the graph does not have is refused loudly', () {
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      expect(() => shell.go(KodoScreen.item), throwsStateError,
          reason: 'an item is reached through a concept, never from the map');
      expect(() => shell.goRoot(KodoScreen.item), throwsStateError,
          reason: 'an item is not one of the five destinations');
    });
  });

  group('FR-M19-03 · a force-kill loses nothing, measured 50 times', () {
    test('50 pseudo-random sessions all come back where they were', () async {
      final random = Random(20260919);
      for (var run = 0; run < 50; run++) {
        final store = MemorySessionStore();
        final shell =
            KodoShell(store: store, session: const Session(profileId: 'local'));

        // A few minutes of a child moving around.
        final moves = 1 + random.nextInt(6);
        for (var i = 0; i < moves; i++) {
          // Back to the map first: a child reaches a concept from the map, and the
          // graph refuses anything else — which is the point of having a graph.
          switch (random.nextInt(4)) {
            case 0:
              shell.goRoot(KodoScreen.carte);
              shell.go(KodoScreen.concept, worldId: random.nextInt(3));
              shell.go(KodoScreen.item, conceptId: 'C${random.nextInt(3)}.1');
            case 1:
              shell.goRoot(KodoScreen.studio);
            case 2:
              shell.goRoot(KodoScreen.moi);
              shell.go(KodoScreen.settings);
            case 3:
              shell.goRoot(KodoScreen.entrainement);
              shell.go(KodoScreen.item, conceptId: 'C${random.nextInt(3)}.1');
          }
          if (random.nextBool() && shell.canGoBack) shell.back();
        }

        final before = shell.session.lastPlace;
        // The process dies here. Everything depends on what reached the store.
        await shell.onBackground();

        final restored = await KodoShell.restore(store);
        expect(restored.session.lastPlace.screen, before.screen,
            reason: 'run $run lost the screen');
        expect(restored.session.lastPlace.conceptId, before.conceptId,
            reason: 'run $run lost the concept');
        expect(restored.session.profileId, 'local',
            reason: 'run $run made the child choose themselves again');
      }
    });

    test('a corrupt session file starts the app rather than crashing it',
        () async {
      final shell =
          await KodoShell.restore(MemorySessionStore('{not json at all'));
      expect(shell.session.profileId, isNull);
      expect(shell.current, KodoScreen.profiles);
    });

    testWidgets('there is no window at all — every change is already written',
        (t) async {
      final store = MemorySessionStore();
      final shell =
          KodoShell(store: store, session: const Session(profileId: 'local'));
      await pump(t, shell);

      /* The first version of the shell debounced writes by 250 ms. That is a window in
         which a force-kill loses the child's place, which is exactly what FR-M19-03
         forbids, so the debounce was removed. This test pins its absence: the move is on
         disk before anybody backgrounds anything. */
      shell.goRoot(KodoScreen.moi);
      shell.go(KodoScreen.settings);
      expect(await store.read(), contains('settings'),
          reason: 'a navigation must be durable the moment it happens');

      shell.setKeywordLocale('en');
      expect(await store.read(), contains('"keywords":"en"'));

      // And backgrounding is still safe to call, and still lands.
      await shell.onBackground();
      expect(await store.read(), contains('settings'));
    });
  });

  group('FR-M19-04 · one setting, every screen', () {
    testWidgets('the keyword language is set once and the session carries it',
        (t) async {
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await pump(t, shell);
      shell.goRoot(KodoScreen.moi);
      shell.go(KodoScreen.settings);
      await t.pumpAndSettle();

      expect(shell.session.keywordLocale, 'fr');
      shell.setKeywordLocale('en');
      await t.pumpAndSettle();
      expect(shell.session.keywordLocale, 'en');
      // And the interface did NOT follow it — two settings, on purpose (§6).
      expect(shell.session.interfaceLocale, UiLocale.fr);
    });

    testWidgets('the interface language changes what every screen says',
        (t) async {
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await pump(t, shell);
      shell.goRoot(KodoScreen.moi);
      shell.go(KodoScreen.settings);
      await t.pumpAndSettle();
      expect(
          find.text(uiStrings.render('label.interface_language', UiLocale.fr)),
          findsWidgets);

      shell.setInterfaceLocale(UiLocale.en);
      await t.pumpAndSettle();
      expect(
          find.text(uiStrings.render('label.interface_language', UiLocale.en)),
          findsWidgets);
    });

    testWidgets('text scale is applied at the root, so no screen can forget it',
        (t) async {
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await pump(t, shell);

      shell.setAccessibility(const AccessibilityPreferences(textScale: 2.0));
      await t.pumpAndSettle();

      final scaler =
          MediaQuery.of(t.element(find.byKey(const Key('worlds')))).textScaler;
      expect(scaler.scale(10), 20, reason: '200 % text is 200 % everywhere');
    });

    testWidgets('the dyslexia font reaches the theme, not just the setting',
        (t) async {
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await pump(t, shell);
      shell.setAccessibility(
          const AccessibilityPreferences(font: ReadingFont.dyslexiaFriendly));
      await t.pumpAndSettle();

      final theme = Theme.of(t.element(find.byKey(const Key('worlds'))));
      expect(theme.textTheme.bodyMedium?.fontFamily,
          ReadingFont.dyslexiaFriendly.family);
    });
  });

  group('FR-M19-05 · cold start goes where the child was', () {
    test('a returning child does not choose themselves again', () async {
      final store = MemorySessionStore();
      final first =
          KodoShell(store: store, session: const Session(profileId: 'local'));
      first.go(KodoScreen.concept, worldId: 1);
      first.go(KodoScreen.item, conceptId: 'C1.2');
      await first.onBackground();

      final second = await KodoShell.restore(store);
      expect(second.current, KodoScreen.item);
      expect(second.session.lastPlace.conceptId, 'C1.2');
      expect(second.session.profileId, 'local');
    });

    test('a first run starts at the profile picker, not at an error', () async {
      final shell = await KodoShell.restore(MemorySessionStore());
      expect(shell.current, KodoScreen.profiles);
    });
  });

  group('FR-M19-01 · the worlds shipped with the app are the authored ones',
      () {
    test('the bundled copy has not drifted from content/', () {
      /* Flutter will not take an asset from outside the package, so the app carries a
         copy of the authored worlds. A stale copy would ship a child content that no
         longer matches the bank CI checked — which is exactly the failure the content
         gate exists to prevent, arriving by a different door. */
      for (final world in [0, 1, 2]) {
        for (final suffix in ['.json', '.manifest.json']) {
          final canonical = File('../content/world$world$suffix');
          final bundled = File('assets/content/world$world$suffix');
          expect(bundled.existsSync(), isTrue,
              reason:
                  '${bundled.path} is missing — run tool/bundle_content.sh');
          expect(bundled.readAsStringSync(), canonical.readAsStringSync(),
              reason:
                  '${bundled.path} has drifted — run tool/bundle_content.sh');
        }
      }
    });
  });

  group('FR-M19-06 · the shell owns no learning logic', () {
    /// The dependency test. A convention would not survive the second sprint; this fails
    /// the build the moment the shell starts deciding something it should be asking for.
    final shellSources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    test('there is source to check', () {
      expect(shellSources, isNotEmpty);
    });

    test(
        'the shell defines no grader, no mastery rule, no scheduler and no item',
        () {
      const forbidden = [
        'class Grader',
        'class MasteryCalculator',
        'class Scheduler',
        'class Item ',
        'class ContentPack',
        'class Attempt',
        'extends StructuralAssertion',
      ];
      for (final file in shellSources) {
        final source = file.readAsStringSync();
        for (final pattern in forbidden) {
          expect(source.contains(pattern), isFalse,
              reason:
                  '${file.path} defines "$pattern" — that belongs to a module');
        }
      }
    });

    test('the shell decides no verdict and computes no mastery', () {
      /* Calling a module's API is the point. Re-implementing its judgement is not.
         These are patterns, not substrings: the first version was `'.passed ='` and it
         flagged `LoopPhase.passed =>`, a switch arm in the verdict strip. A guard that
         cries wolf gets weakened or deleted, so it is worth making it say exactly what it
         means — an ASSIGNMENT to a verdict, never a match on one. */
      final forbiddenCalls = <String, RegExp>{
        'assigning a verdict': RegExp(r'\.passed\s*=(?!=|>)'),
        'assigning a mastery state': RegExp(r'ConceptState\.\w+\s*=(?!=|>)'),
        'computing the accuracy criterion': RegExp(r'firstAttemptRate'),
        'computing the volume criterion': RegExp(r'criterionVolume'),
        'choosing the next item': RegExp(r'nextItem\('),
      };
      for (final file in shellSources) {
        final source = file.readAsStringSync();
        for (final entry in forbiddenCalls.entries) {
          expect(entry.value.hasMatch(source), isFalse,
              reason: '${file.path} is ${entry.key} — that belongs to a module');
        }
      }
    });

    test('the guard is not vacuous — it catches the thing it forbids', () {
      // The same check, over source that really does do the forbidden thing.
      expect(RegExp(r'\.passed\s*=(?!=|>)').hasMatch('verdict.passed = true;'),
          isTrue);
      expect(RegExp(r'\.passed\s*=(?!=|>)').hasMatch('LoopPhase.passed => x'),
          isFalse);
      expect(RegExp(r'\.passed\s*=(?!=|>)').hasMatch('if (v.passed == true)'),
          isFalse);
    });

    test('every child-facing string comes from the catalogue, not from source',
        () {
      final found = <HardCodedString>[];
      for (final file in shellSources) {
        found.addAll(
            scanForHardCodedStrings(file.path, file.readAsStringSync()));
      }
      expect(found, isEmpty, reason: found.join('\n'));
    });
  });

  /* The art committee's clause (Part 2b of the committee charter): the universe is only
     real if a child meets it. Art that exists in a package and never reaches a screen is
     a folder of SVGs, not a product. */
  group('FR-M20-03 · §9 · the universe reaches the child', () {
    testWidgets('the map draws places, not rows', (t) async {
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await pump(t, shell, content: mapContent());
      expect(find.byKey(const Key('world-0')), findsOneWidget);
      expect(find.byType(Art), findsWidgets,
          reason: 'a world without its place drawn is a filing-cabinet row');
    });

    testWidgets('every drawing on screen says what it is, out loud', (t) async {
      /* FR-M16-04. An illustration a screen reader skips is worse than no illustration:
         the child who needs the description most gets the emptiest screen. */
      final handle = t.ensureSemantics();
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await pump(t, shell, content: mapContent());
      for (final element in find.byType(Art).evaluate()) {
        final art = element.widget as Art;
        final said = art.drawing.describeIn('fr');
        expect(said.trim(), isNotEmpty);
        /* A pattern, not the whole label: a card merges its picture's sentence with the
           world's name into one node, which is exactly what a screen reader should read
           — "Une plage au soleil. Tika arrive. Bonjour Tika" — so the assertion is that
           the sentence is IN what is spoken, not that it is all of it. */
        expect(find.bySemanticsLabel(RegExp(RegExp.escape(said))), findsWidgets,
            reason: '${art.drawing.id} is invisible to a screen reader');
      }
      handle.dispose();
    });

    testWidgets('the illustration follows the high-contrast setting',
        (t) async {
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await pump(t, shell, content: mapContent());
      expect(
          (find.byType(Art).evaluate().first.widget as Art).highContrast,
          isFalse);

      shell.setAccessibility(
          const AccessibilityPreferences(highContrast: true));
      await t.pumpAndSettle();
      expect(
          (find.byType(Art).evaluate().first.widget as Art).highContrast,
          isTrue,
          reason: 'a child who turns on high contrast still sees the picture, '
              'and it is the high-contrast picture');
    });

    testWidgets('the bottom bar still fits its words at 200 % text',
        (t) async {
      /* FR-M16-03 against §9.1. "Entraînement" is twelve characters; five of those
         across 360 dp at double size is exactly where a tab bar clips. The bar grows
         instead, and this test is what says so. */
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await pump(t, shell, content: mapContent());
      shell.setAccessibility(const AccessibilityPreferences(textScale: 2.0));
      await t.pumpAndSettle();
      /* A RenderFlex overflow is reported as an exception rather than a failure, so it
         has to be taken and asserted on, or the test passes over a clipped bar. */
      expect(t.takeException(), isNull,
          reason: 'the root bar overflowed at 200 % text');
      for (final root in KodoScreen.roots) {
        expect(find.byKey(Key('root-${root.route}')), findsOneWidget);
      }
    });
  });
}
