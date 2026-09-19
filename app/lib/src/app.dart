/// The application (`FR-M19-01`).
library;

import 'package:flutter/material.dart';
import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_progress/kodo_progress.dart';
import 'package:kodo_studio/kodo_studio.dart';

import 'learning.dart';
import 'screens.dart';
import 'shell.dart';

/// What the shell needs handed to it, rather than reaching for.
///
/// The shell does not load packs, read files or know where content lives: it is given the
/// installed library and the profiles. That keeps `FR-M19-06` true by construction — there
/// is no seam here for content or learning logic to arrive through.
class KodoContent {
  const KodoContent(
      {required this.packs, required this.profileNames, this.clock});

  /// The installed content, from M14. Empty is a legitimate first run.
  final List<ContentPack> packs;

  /// profile id → first name, from M13.
  final Map<String, String> profileNames;

  /// M7's clock. Injectable because mastery has a 72-hour retention rule and a test that
  /// has to wait three days to check it is a test nobody runs.
  final Clock? clock;
}

class KodoApp extends StatefulWidget {
  const KodoApp({super.key, required this.shell, required this.content});

  final KodoShell shell;
  final KodoContent content;

  @override
  State<KodoApp> createState() => _KodoAppState();
}

class _KodoAppState extends State<KodoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    for (final loop in _loops.values) {
      loop.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// `FR-M19-03`. The same rule M9's autosave follows: on a 2 GB device the next thing
  /// after backgrounding may be the process being killed, so the write is immediate.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      widget.shell.onBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      shell: widget.shell,
      child: AnimatedBuilder(
        animation: widget.shell,
        builder: (context, _) {
          final prefs = widget.shell.session.accessibility;
          return MaterialApp(
            title: 'KODO',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: prefs.font.family,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF00695C),
                // High contrast raises the floor rather than swapping a palette, so the
                // block-family colours of M2 keep the meaning §9 gave them.
                contrastLevel: prefs.highContrast ? 1.0 : 0.0,
              ),
            ),
            /* FR-M19-04 — one place sets it, every screen obeys. The text scale is applied
               at the root rather than by each screen, so a screen cannot forget it. */
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              minScaleFactor: prefs.textScale,
              maxScaleFactor: prefs.textScale,
              child: child!,
            ),
            home: _screenFor(widget.shell),
          );
        },
      ),
    );
  }

  Widget _screenFor(KodoShell shell) {
    final packs = widget.content.packs;
    switch (shell.current) {
      case KodoScreen.profiles:
        return ProfilesScreen(profileNames: widget.content.profileNames);

      case KodoScreen.carte:
        return CarteScreen(worlds: {
          for (final pack in packs)
            pack.world: pack.nameKeys[shell.session.interfaceLocale.code] ??
                pack.nameKeys['fr'] ??
                'Monde ${pack.world}',
        });

      /* Practice is ready when there is anything installed to practise. WHICH items it
         serves is M7's scheduler and M6's delivery — asking that question here is the
         second progression system `FR-M19-06` exists to prevent, so the screen is handed
         a boolean and a callback and knows nothing else. */
      case KodoScreen.entrainement:
        return EntrainementScreen(
          ready: packs.any((p) => p.items.isNotEmpty),
          onStart: packs.isEmpty
              ? null
              : () =>
                  shell.go(KodoScreen.item, conceptId: _firstConceptOf(packs)),
        );

      case KodoScreen.item:
        final conceptId = shell.session.lastPlace.conceptId;
        if (conceptId == null) {
          return const KodoScaffold(
              titleKey: 'root.entrainement', child: SizedBox.shrink());
        }
        /* One loop per concept, kept for as long as the child stays in it. Rebuilding it
           on every frame would re-ask the scheduler for an item mid-answer and throw the
           child's work away — and would lose the attempt history the mastery rule is
           computed from. */
        return ItemScreen(loop: _loopFor(conceptId));

      case KodoScreen.galerie:
        // Nothing is shared on a fresh install, and M10 is what fills this when sharing
        // is switched on. The shell does not moderate; it lists.
        return const GalerieScreen();

      case KodoScreen.moi:
        // The star count belongs to M8 and arrives with the profile; zero is honest until
        // it does, and never a number this screen computed.
        return const MoiScreen(stars: 0);

      /* M5, mounted. Thirteen worlds of authored tutorials existed and no screen showed
         them: a child opening KODO went straight to exercises for a concept nobody had
         taught. Which tutorial is the pack's, whether it may be skipped is M7's, and the
         three beats are M5's — this only decides that a concept starts here. */
      case KodoScreen.tutoriel:
        final conceptId = shell.session.lastPlace.conceptId;
        final tutorial = _tutorialFor(packs, conceptId);
        if (tutorial == null) {
          return const KodoScaffold(
              titleKey: 'root.tutoriel', child: SizedBox.shrink());
        }
        return TutorielScreen(
          tutorial: tutorial,
          // `FR-M5-04`: skippable only on a repeat, and "a repeat" is whether the child
          // has ever passed anything in this concept — M7's record, not a flag here.
          firstPass: _loopFor(conceptId!).passedThisSession == 0,
          onFinished: () => shell.go(KodoScreen.item, conceptId: conceptId),
        );

      case KodoScreen.concept:
        final world =
            packs.where((p) => p.world == shell.session.lastPlace.worldId);
        return ConceptScreen(
          conceptIds: world.isEmpty
              ? const []
              : (world.first.concepts.keys.toList()..sort()),
        );

      case KodoScreen.studio:
        return StudioScreen(recipeTitles: [
          for (final recipe in recettes)
            recipe.titleIn(shell.session.interfaceLocale.code),
        ]);

      case KodoScreen.settings:
        return const SettingsScreen();
    }
  }

  /// The tutorial that teaches [conceptId], or null when the pack ships none.
  ///
  /// A concept with no tutorial is content that is not finished, not a screen to invent
  /// something for — so the shell moves the child straight to the exercises rather than
  /// showing them an empty lesson.
  Tutorial? _tutorialFor(List<ContentPack> packs, String? conceptId) {
    if (conceptId == null) return null;
    for (final pack in packs) {
      for (final tutorial in pack.tutorials) {
        if (tutorial.conceptId == conceptId) return tutorial;
      }
    }
    return null;
  }

  /// Which item to show. Deliberately the first of the concept and nothing cleverer:
  /// *choosing* the next item is M7's scheduler, and doing it here would be the second
  /// progression system `FR-M19-06` exists to prevent.
  /// The first concept of the first installed pack — a door, not a curriculum. M7 decides
  /// what a child should actually do; this is what to open when nothing has decided yet.
  String? _firstConceptOf(List<ContentPack> packs) {
    for (final pack in packs) {
      final ids = pack.concepts.keys.toList()..sort();
      if (ids.isNotEmpty) return ids.first;
    }
    return null;
  }

  final Map<String, LearningLoop> _loops = {};

  /// The loop for a concept, created once and kept for as long as the child stays in it.
  ///
  /// Rebuilding it per frame would re-ask the scheduler for an item in the middle of an
  /// answer, throw the child's work away, and lose the attempt history the mastery rule
  /// is computed from.
  LearningLoop _loopFor(String conceptId) {
    final existing = _loops[conceptId];
    if (existing != null) return existing;
    final loop = LearningLoop(
      packs: widget.content.packs,
      conceptId: conceptId,
      clock: widget.content.clock ?? Clock.system,
    );
    _loops[conceptId] = loop;
    // Serving the first item is asynchronous because mastery is read from the attempt
    // store; the screen shows its empty state for one frame and then the item arrives.
    loop.start();
    return loop;
  }
}
