/// The screens the shell shows.
///
/// Every one of them is a *composition*: it reads a module's API and renders it. None
/// computes a verdict, a mastery state or a next item — that is `FR-M19-06`, and the
/// dependency test in `test/m19_acceptance_test.dart` enforces it.
library;

import 'package:flutter/material.dart';
import 'package:kodo_access/kodo_access.dart';
import 'package:kodo_app/kodo_app.dart';
import 'package:kodo_art/kodo_art.dart';
import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';

import 'package:kodo_stage/kodo_stage.dart';

import 'drawing_painter.dart';
import 'learning.dart';
import 'shell.dart';

/// Every child-facing string comes from M15's catalogue. There is no literal here, and a
/// test scans this file to keep it that way.
String _s(BuildContext context, String key,
        [Map<String, String> args = const {}]) =>
    uiStrings.render(key, ShellScope.of(context).session.interfaceLocale, args);

/// The bottom bar of §9.1: five destinations, always there, never six.
///
/// It is shown on the roots and hidden inside a journey, because a child three screens
/// deep into an exercise who taps *Carte* loses their place — the tab bar is how you
/// choose where to be, not an escape hatch from where you are. `KodoScaffold.back` is the
/// escape hatch.
class KodoRootBar extends StatelessWidget {
  const KodoRootBar({super.key});

  /// The icon of each destination. Icon **and** word, never one alone (§9.2) — and each
  /// icon has a different silhouette, so the bar survives greyscale like everything else.
  static const _icons = <KodoScreen, IconData>{
    KodoScreen.carte: Icons.map_outlined,
    KodoScreen.entrainement: Icons.bolt_outlined,
    KodoScreen.studio: Icons.brush_outlined,
    KodoScreen.galerie: Icons.photo_library_outlined,
    KodoScreen.moi: Icons.face_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    final roots = KodoScreen.roots;
    final index = roots.indexOf(shell.current);
    /* The bar grows with the text rather than clipping it. At 200 % (`FR-M16-03`) a
       two-line label needs the room, and Material's default 80 dp does not have it: the
       M16 audit's finding about the status line was exactly this mistake one screen
       over. */
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return NavigationBar(
      key: const Key('root-bar'),
      height: 80 * scale.clamp(1.0, 2.0),
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (i) => shell.goRoot(roots[i]),
      destinations: [
        for (final root in roots)
          NavigationDestination(
            key: Key('root-${root.route}'),
            icon: Icon(_icons[root]),
            label: _s(context, 'root.${root.route}'),
          ),
      ],
    );
  }
}

/// A screen with a title and a way out — `FR-M19-02` asks that every screen be exitable.
class KodoScaffold extends StatelessWidget {
  const KodoScaffold({
    super.key,
    required this.titleKey,
    required this.child,
    this.actions = const [],
  });

  final String titleKey;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_s(context, titleKey)),
        leading: shell.canGoBack
            ? BackButton(key: const Key('back'), onPressed: shell.back)
            : null,
        actions: actions,
      ),
      body: SafeArea(child: child),
      bottomNavigationBar:
          shell.current.root ? const KodoRootBar() : null,
    );
  }
}

/// Choosing who is using the app. This is what replaces a login (`FR-M19-05`).
///
/// No password, no e-mail, no account: a child says it is them. The screen is drawn as a
/// welcome rather than as a form, because the first thing a child meets should look like
/// somewhere to go — the first version of this screen was one word in the corner of a
/// white page, which is what a settings dialog looks like.
class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key, required this.profileNames});

  /// Comes from M13. The shell does not own profiles; it shows them.
  final Map<String, String> profileNames;

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          key: const Key('profiles'),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 24),
            Center(
              child: Art(tikaPortrait,
                  size: 132,
                  highContrast: shell.session.accessibility.highContrast,
                  locale: shell.session.interfaceLocale.code),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(_s(context, 'profiles.who'),
                  style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 16),
            for (final entry in profileNames.entries)
              Card(
                child: ListTile(
                  key: Key('profile-${entry.key}'),
                  // A child's own first name is not an interface string.
                  title:
                      Text(entry.value, style: const TextStyle(fontSize: 24)),
                  minTileHeight: 64,
                  onTap: () => shell.chooseProfile(entry.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// **Carte** — §9.1's single entry point to learning.
///
/// Not a list of thirteen rows. Each world is a card with its own place drawn on it, from
/// `kodo_art`: the beach, the island, the rosace. A child who cannot yet read the word
/// *Rosace* can still tell world 2 from world 7, which is the point of drawing them.
class CarteScreen extends StatelessWidget {
  const CarteScreen({super.key, required this.worlds, this.reachable});

  /// world number → its name in the child's language, from the content packs.
  final Map<int, String> worlds;

  /// Which worlds a child may open. Comes from M7 — the shell never decides this. Null
  /// means "everything installed", which is what an offline install with no progress is.
  final Set<int>? reachable;

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    final locale = shell.session.interfaceLocale.code;
    final highContrast = shell.session.accessibility.highContrast;
    return KodoScaffold(
      titleKey: 'root.carte',
      child: GridView.count(
        key: const Key('worlds'),
        padding: const EdgeInsets.all(12),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
        children: [
          for (final entry in worlds.entries)
            _WorldCard(
              number: entry.key,
              name: entry.value,
              locale: locale,
              highContrast: highContrast,
              open: reachable?.contains(entry.key) ?? true,
              onTap: () => shell.go(KodoScreen.concept, worldId: entry.key),
            ),
        ],
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.number,
    required this.name,
    required this.locale,
    required this.highContrast,
    required this.open,
    required this.onTap,
  });

  final int number;
  final String name;
  final String locale;
  final bool highContrast;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final place = worldPlaces[number];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('world-$number'),
        onTap: open
            ? onTap
            : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_s(context, 'carte.locked')))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: place == null
                  /* A world with no place drawn yet gets its number on plain paper. A
                     placeholder that says "not drawn" — never another world's picture,
                     which would teach a child the wrong thing about where they are. */
                  ? ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Center(
                          child: Text('$number',
                              style: const TextStyle(fontSize: 32))),
                    )
                  : LayoutBuilder(
                      builder: (context, box) => Art(
                        place,
                        size: box.biggest.shortestSide,
                        highContrast: highContrast,
                        locale: locale,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  if (!open)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.hourglass_empty, size: 16),
                    ),
                  Expanded(
                    // A world's name is content, from the pack, not an interface string.
                    child: Text(name,
                        style: const TextStyle(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// **Entraînement** — §9.1's *"today's mix, one button"*.
///
/// One button, literally. What the mix contains is M7's scheduler and M6's delivery; this
/// screen knows only that there is something to do and how to start it, which is the whole
/// of `FR-M19-06` in one screen.
class EntrainementScreen extends StatelessWidget {
  const EntrainementScreen({super.key, required this.ready, this.onStart});

  /// Whether the scheduler has anything for today. From M7.
  final bool ready;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return KodoScaffold(
      titleKey: 'root.entrainement',
      child: Center(
        child: Column(
          key: const Key('entrainement'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tika asks; the child answers by pressing. §9.2's "icon + word".
            Art(tikaThinking,
                size: 140,
                highContrast:
                    ShellScope.of(context).session.accessibility.highContrast,
                locale: ShellScope.of(context).session.interfaceLocale.code),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('start-practice'),
              onPressed: ready ? onStart : null,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(220, 64),
                  textStyle: const TextStyle(fontSize: 22)),
              child: Text(_s(context, 'button.practice_start')),
            ),
          ],
        ),
      ),
    );
  }
}

/// **Galerie** — class and community projects, when a teacher has enabled them.
///
/// Empty is the normal state of a fresh install, and it is drawn as a place rather than as
/// an error: §10 forbids anything that reads to a child as a failure.
class GalerieScreen extends StatelessWidget {
  const GalerieScreen({super.key, this.projectTitles = const []});

  /// From M10. The shell does not moderate, rank or filter — it lists what it is given.
  final List<String> projectTitles;

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    return KodoScaffold(
      titleKey: 'root.galerie',
      child: projectTitles.isEmpty
          ? Center(
              child: Column(
                key: const Key('galerie-empty'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Art(tikaPortrait,
                      size: 120,
                      highContrast: shell.session.accessibility.highContrast,
                      locale: shell.session.interfaceLocale.code),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(_s(context, 'galerie.empty'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            )
          : ListView(
              key: const Key('galerie'),
              children: [
                for (final title in projectTitles)
                  Material(
                      child:
                          ListTile(title: Text(title), minTileHeight: 56)),
              ],
            ),
    );
  }
}

/// **Moi** — avatar, stars, and the door to settings.
///
/// The parent space is not a sixth tab (§9.1); it is behind a gate in here. The gate
/// itself is M11's, so this screen only shows the door.
class MoiScreen extends StatelessWidget {
  const MoiScreen({super.key, required this.stars, this.onParentSpace});

  /// From M8. The shell does not award, count or decay a star.
  final int stars;
  final VoidCallback? onParentSpace;

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    return KodoScaffold(
      titleKey: 'root.moi',
      child: ListView(
        key: const Key('moi'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Art(tikaPortrait,
                  size: 128,
                  highContrast: shell.session.accessibility.highContrast,
                  locale: shell.session.interfaceLocale.code),
            ),
          ),
          Center(
            child: Text(
              _s(context, 'moi.stars', {'count': stars.toString()}),
              key: const Key('stars'),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            child: ListTile(
              key: const Key('to-settings'),
              leading: const Icon(Icons.settings),
              title: Text(_s(context, 'label.interface_language')),
              minTileHeight: 56,
              onTap: () => shell.go(KodoScreen.settings),
            ),
          ),
          if (onParentSpace != null)
            Material(
              child: ListTile(
                key: const Key('to-parent-space'),
                leading: const Icon(Icons.lock_outline),
                title: Text(_s(context, 'label.parent_space')),
                minTileHeight: 56,
                onTap: onParentSpace,
              ),
            ),
        ],
      ),
    );
  }
}

/// The concepts of one world.
class ConceptScreen extends StatelessWidget {
  const ConceptScreen({super.key, required this.conceptIds});
  final List<String> conceptIds;

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    return KodoScaffold(
      titleKey: 'root.carte',
      child: ListView(
        key: const Key('concepts'),
        children: [
          for (final id in conceptIds)
            Material(
              child: ListTile(
                key: Key('concept-$id'),
                title: Text(id, style: const TextStyle(fontSize: 20)),
                minTileHeight: 56,
                /* Through the tutorial, not past it. §7.2: a concept is met before it
                   is practised, and an exercise on a concept nobody has shown the child
                   is a test. The tutorial screen moves them on when it is done. */
                onTap: () => shell.go(KodoScreen.tutoriel, conceptId: id),
              ),
            ),
        ],
      ),
    );
  }
}

/// One item: its prompt, the editor, the canvas, and a verdict.
///
/// The screen that makes the rest of the programme reachable. It composes and decides
/// nothing: the prompt is the item's, the verdict is M6's, the sentence under a wrong
/// answer is the *item's own* authored diagnostic, and which item comes next is M7's.
/// `LearningLoop` holds the bookkeeping between them.
class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key, required this.loop});

  final LearningLoop loop;

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  EditorController? _controller;
  String? _forItemId;

  /// A fresh editor per item, seeded with whatever the item starts the child on.
  ///
  /// Rebuilt when the item changes and never otherwise: a controller that survives the
  /// item would carry the last child's program into the next question.
  EditorController _controllerFor(ItemInFlight flight, String keywordLocale) {
    if (_forItemId == flight.item.id && _controller != null) return _controller!;
    _forItemId = flight.item.id;
    return _controller = EditorController(
      initialSource: flight.item.startingProgramSource ?? '',
      keywords: KeywordTables.of(keywordLocale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    final locale = shell.session.interfaceLocale.code;
    final prefs = shell.session.accessibility;

    return AnimatedBuilder(
      animation: widget.loop,
      builder: (context, _) {
        final loop = widget.loop;
        final flight = loop.current;

        if (flight == null) {
          return KodoScaffold(
            titleKey: 'root.entrainement',
            child: Center(
              child: Column(
                key: const Key('session-done'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Art(tikaPortrait,
                      size: 120,
                      highContrast: prefs.highContrast,
                      locale: locale),
                  const SizedBox(height: 16),
                  Text(_s(context, 'feedback.session_done'),
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(
                    _s(context, 'feedback.count_passed',
                        {'count': '${loop.passedThisSession}'}),
                    key: const Key('session-count'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }

        final item = flight.item;
        final choices = item.choices;

        return KodoScaffold(
          titleKey: 'root.entrainement',
          actions: [
            if (item.hints.isNotEmpty)
              IconButton(
                key: const Key('hint'),
                icon: const Icon(Icons.lightbulb_outline),
                tooltip: _s(context, 'button.help'),
                // Asking costs nothing (§10). The count is a signal, never a penalty.
                onPressed: loop.showHint,
              ),
          ],
          child: Column(
            children: [
              _Prompt(text: item.promptIn(locale), locale: locale, prefs: prefs),
              /* `FR-M6-06` — the rubric, before the child starts rather than after they
                 finish. An open build has no single right answer, so a child who cannot
                 see what "done" means can only produce something and hope; the rubric is
                 the difference between an open question and a guessing game. It is on
                 screen from the first frame and stays there while they work. */
              if (item.rubric.isNotEmpty)
                _Rubric(rubric: item.rubric, locale: locale),
              if (flight.hintsShown > 0 && loop.availableHint != null)
                _Panel(
                  key: const Key('hint-text'),
                  // The hint is the ITEM's, authored and reviewed as content.
                  text: loop.availableHint!.textKeys[locale] ??
                      loop.availableHint!.textKeys['fr'] ??
                      '',
                  tone: _Tone.neutral,
                ),
              Expanded(
                child: choices.isNotEmpty
                    ? _Choices(
                        choices: choices,
                        locale: locale,
                        enabled: loop.phase == LoopPhase.working,
                        onChoose: loop.choose,
                      )
                    : _Work(
                        controller: _controllerFor(
                            flight, shell.session.keywordLocale),
                        scope: PaletteScope.ofIds(item.paletteScope),
                        keywordLocale: shell.session.keywordLocale,
                        drawn: loop.drawn,
                        locale: locale,
                        choices: _choicesFor(item),
                      ),
              ),
              _Verdict(loop: loop, locale: locale, controller: _controller),
            ],
          ),
        );
      },
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.text, required this.locale, required this.prefs});
  final String text;
  final String locale;
  final AccessibilityPreferences prefs;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Art(tikaPortrait,
                size: 56, highContrast: prefs.highContrast, locale: locale),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  key: const Key('prompt'),
                  style: const TextStyle(fontSize: 20)),
            ),
          ],
        ),
      );
}

/// The editor and the drawing, side by side or stacked, depending on the room.
/// What "done" looks like, shown before the child starts (`FR-M6-06`).
///
/// Each line is one plain sentence the author wrote. The structural check behind it is
/// deliberately NOT shown: a child is told "ton dessin répète quelque chose", not
/// `contains(Repeat) >= 1`, and the whole point of the rubric is that it is readable.
/// The dropdown lists this item's blocks offer (`FR-M2-05`).
///
/// Read off the item's own stage rather than made up here. An item that never asked for a
/// stage has no sprites, and its `lutin` dropdown is honestly empty — which is right,
/// because such an item has no `lutin` block in its palette either.
BlockChoices _choicesFor(Item item) {
  final stage = item.stage;
  if (stage == null) return BlockChoices.empty;
  return BlockChoices(
    sprites: stage.sprites,
    backdrops: ['blank', ...stage.backdrops],
    // Sound names are content the pack carries; an item that names none offers none
    // rather than a list of sounds nobody recorded.
    sounds: const [],
  );
}

class _Rubric extends StatelessWidget {
  const _Rubric({required this.rubric, required this.locale});

  final List<RubricLine> rubric;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('rubric'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_s(context, 'rubric.title'),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          for (final line in rubric)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A bullet, not a tick: nothing has been judged yet.
                  const Text('• '),
                  Expanded(
                    child: Text(
                      line.textKeys[locale] ?? line.textKeys['fr'] ?? '',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Work extends StatelessWidget {
  const _Work({
    required this.controller,
    required this.scope,
    required this.keywordLocale,
    required this.drawn,
    required this.locale,
    this.choices = BlockChoices.empty,
  });

  final EditorController controller;
  final PaletteScope scope;
  final String keywordLocale;
  final VectorCanvas? drawn;
  final String locale;

  /// What the dropdowns inside blocks offer (`FR-M2-05`).
  final BlockChoices choices;

  @override
  Widget build(BuildContext context) {
    final canvas = drawn == null
        ? const SizedBox.shrink()
        : TurtleCanvasView(canvas: drawn!, locale: locale);

    return LayoutBuilder(
      builder: (context, box) {
        /* A 5.5-inch phone in portrait has no room for two columns. M2 already builds the
           phone layout `FR-M2-07` asks for — script above, palette as a bottom sheet —
           and the shell simply never asked for it: the first run in a browser at 360 dp
           put the palette in two thirds of the width and left the script a sliver, so a
           placed block rendered as "ava / nce". The editor had the answer; nobody passed
           the flag. */
        /* Measured on the editor's own share, not on the window. With the canvas beside
           it the editor gets half the room, and a 400 dp editor needs the phone layout
           as much as a 400 dp phone does — the first version asked the window, handed
           the block palette 260 of 400 dp, and left the script 140: a block rendered
           three characters wide. */
        final editorWidth = drawn == null ? box.maxWidth : box.maxWidth / 2;
        final compact = editorWidth < 600;
        final editor = BlockEditor(
          controller: controller,
          scope: scope,
          locale: keywordLocale,
          compact: compact,
          // `FR-M2-05`. The names come from the item's own stage, never from a list this
          // screen invented: an item with two sprites offers two, and one with none
          // offers none.
          choices: choices,
        );
        if (compact) {
          return Column(
            children: [
              Expanded(flex: 3, child: editor),
              if (drawn != null) Expanded(flex: 2, child: canvas),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: editor),
            if (drawn != null) Expanded(child: canvas),
          ],
        );
      },
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({
    required this.choices,
    required this.locale,
    required this.enabled,
    required this.onChoose,
  });

  final List<Choice> choices;
  final String locale;
  final bool enabled;
  final void Function(int) onChoose;

  @override
  Widget build(BuildContext context) => ListView(
        key: const Key('choices'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (var i = 0; i < choices.length; i++)
            Card(
              child: ListTile(
                key: Key('choice-$i'),
                // A choice's label is the item's content, not an interface string.
                title: Text(
                    choices[i].labelKeys[locale] ??
                        choices[i].labelKeys['fr'] ??
                        '',
                    style: const TextStyle(fontSize: 18)),
                minTileHeight: 56,
                onTap: enabled ? () => onChoose(i) : null,
              ),
            ),
        ],
      );
}

enum _Tone { neutral, good, again }

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.text, required this.tone});
  final String text;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = switch (tone) {
      _Tone.good => scheme.secondaryContainer,
      _Tone.again => scheme.tertiaryContainer,
      _Tone.neutral => scheme.surfaceContainerHighest,
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 18)),
    );
  }
}

/// The bottom strip: run, or the verdict and the way onward.
class _Verdict extends StatelessWidget {
  const _Verdict(
      {required this.loop, required this.locale, required this.controller});

  final LearningLoop loop;
  final String locale;
  final EditorController? controller;

  @override
  Widget build(BuildContext context) {
    final verdict = loop.verdict;
    final item = loop.current?.item;

    /* The sentence under a wrong answer is the ITEM's, rendered by M6 from the numbers it
       measured. When an author has not covered a situation the publish gate refuses the
       item, so at run time a null message means an item that skipped the gate — and the
       shell shows nothing rather than inventing "Incorrect". */
    final message = verdict == null || item == null
        ? null
        : verdict.messageFor(item, locale);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loop.phase == LoopPhase.passed)
            _Panel(
                key: const Key('verdict-good'),
                text: _s(context, 'feedback.correct'),
                tone: _Tone.good),
          if (loop.phase == LoopPhase.tryAgain && message != null)
            _Panel(
                key: const Key('verdict-again'),
                text: message,
                tone: _Tone.again),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: switch (loop.phase) {
              LoopPhase.passed => FilledButton(
                  key: const Key('keep-going'),
                  onPressed: loop.next,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  child: Text(_s(context, 'button.keep_going')),
                ),
              LoopPhase.tryAgain => FilledButton(
                  key: const Key('again'),
                  onPressed: loop.tryAgain,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  child: Text(_s(context, 'button.again')),
                ),
              LoopPhase.working || LoopPhase.finished => FilledButton(
                  key: const Key('run'),
                  onPressed: controller == null
                      ? null
                      : () => loop.submit(controller!.program),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  child: Text(_s(context, 'button.run')),
                ),
            },
          ),
        ],
      ),
    );
  }
}

/// The Studio. M9 owns what a project is; the shell owns the door to it.
class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key, required this.recipeTitles});
  final List<String> recipeTitles;

  @override
  Widget build(BuildContext context) {
    return KodoScaffold(
      titleKey: 'root.studio',
      child: ListView(
        key: const Key('recipes'),
        children: [
          for (final title in recipeTitles)
            Material(child: ListTile(title: Text(title), minTileHeight: 56)),
        ],
      ),
    );
  }
}

/// One place for every preference (`FR-M19-04`).
///
/// Interface language, keyword language and the accessibility settings of `FR-M16-03`, set
/// once and applied everywhere — because the shell rebuilds the whole tree from the
/// session, there is nowhere for a screen to keep its own copy.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    final s = shell.session;
    return KodoScaffold(
      titleKey: 'label.interface_language',
      child: ListView(
        key: const Key('settings'),
        children: [
          ListTile(
            title: Text(_s(context, 'label.interface_language')),
            trailing: DropdownButton<UiLocale>(
              key: const Key('interface-locale'),
              value: s.interfaceLocale,
              onChanged: (v) => v == null ? null : shell.setInterfaceLocale(v),
              items: [
                for (final locale in UiLocale.v1)
                  DropdownMenuItem(value: locale, child: Text(locale.endonym)),
              ],
            ),
          ),
          ListTile(
            title: Text(_s(context, 'label.keyword_language')),
            trailing: DropdownButton<String>(
              key: const Key('keyword-locale'),
              value: s.keywordLocale,
              onChanged: (v) => v == null ? null : shell.setKeywordLocale(v),
              /* The endonyms come from M15's locale table, not from literals here: a
                 language's own name for itself is locale data like any other. */
              items: [
                for (final locale in UiLocale.v1)
                  DropdownMenuItem(
                      value: locale.code, child: Text(locale.endonym)),
              ],
            ),
          ),
          ListTile(
            title: Text(_s(context, 'a11y.text_size', {
              'percent': (s.accessibility.textScale * 100).round().toString()
            })),
            subtitle: Slider(
              key: const Key('text-scale'),
              min: AccessibilityPreferences.minimumTextScale,
              max: AccessibilityPreferences.maximumTextScale,
              divisions: 10,
              value: s.accessibility.textScale,
              onChanged: (v) => shell
                  .setAccessibility(s.accessibility.copyWith(textScale: v)),
            ),
          ),
          SwitchListTile(
            key: const Key('reduced-motion'),
            title: Text(_s(context, 'a11y.reduced_motion')),
            value: s.accessibility.reducedMotion,
            onChanged: (v) => shell
                .setAccessibility(s.accessibility.copyWith(reducedMotion: v)),
          ),
          SwitchListTile(
            key: const Key('dyslexia-font'),
            title: Text(_s(context, 'a11y.dyslexia_font')),
            value: s.accessibility.font == ReadingFont.dyslexiaFriendly,
            onChanged: (v) => shell.setAccessibility(s.accessibility.copyWith(
                font: v ? ReadingFont.dyslexiaFriendly : ReadingFont.standard)),
          ),
          SwitchListTile(
            key: const Key('narration'),
            title: Text(_s(context, 'a11y.narration_on')),
            value: s.accessibility.narrationOn,
            onChanged: (v) => shell
                .setAccessibility(s.accessibility.copyWith(narrationOn: v)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// The tutorial (M5, FR-M5-01 to FR-M5-06)
// ---------------------------------------------------------------------------------------

/// Runs one tutorial: Tika does it, they do it together, the child does it.
///
/// Until this existed the programme had a tutorial *engine*, thirteen worlds of authored
/// tutorials, and no screen that mounted either — a child opening KODO went straight to
/// exercises for a concept nobody had shown them. §7.2's three beats were content sitting
/// in a pack.
///
/// It composes and decides nothing, like every screen here. Which step comes next, whether
/// the child has done it, and whether a step may be skipped are all [TutorialPlayer]'s;
/// the words are the pack's; the editor is M2's. What is this file's is the arrangement:
/// the narration always visible (`FR-M5-03`), the spotlight where the step points, and
/// exactly one thing to press (`FR-M5-02`).
class TutorielScreen extends StatefulWidget {
  const TutorielScreen({
    super.key,
    required this.tutorial,
    required this.firstPass,
    required this.onFinished,
  });

  final Tutorial tutorial;

  /// `FR-M5-04`: no step is skippable on a first pass, every step is on a repeat.
  final bool firstPass;

  /// Where the child goes once the concept has been named: the exercises.
  final VoidCallback onFinished;

  @override
  TutorielScreenState createState() => TutorielScreenState();
}

/// The host the player drives. It owns a scratch document and nothing else.
///
/// `FR-M5-05` is structural rather than promised: [TutorialHost] has no method that opens,
/// names or saves a project, so a tutorial cannot touch a child's own work even by
/// mistake. This class adds no such method either.
class _ScreenHost implements TutorialHost {
  _ScreenHost(this.onChanged);

  final VoidCallback onChanged;

  EditorController controller = EditorController(initialSource: '');
  final VectorCanvas canvas = VectorCanvas();
  SpotlightTarget? spotlightTarget;
  String narration = '';
  String? audioKey;
  List<String>? paletteIds;

  /// True while a demonstration is being shown but has not landed (`FR-M5-02`).
  bool showingGhost = false;

  @override
  Program get scratchProgram => controller.program;

  @override
  String get scratchPathSignature => canvas.pathSignature();

  @override
  void demonstrate(Program program, DemoPhase phase) {
    /* Ghosted, then real. A demo whose blocks simply appear is a magic trick — they were
       somewhere else, now they are here — and the child learns that the computer did it.
       The ghost is the promise; landing it is the demonstration. */
    showingGhost = phase == DemoPhase.ghosted;
    controller.setProgram(program, kind: 'tutorial_demo');
    canvas.reset();
    runProgram(program, canvas);
    onChanged();
  }

  @override
  void narrate(String text, {String? audioKey}) {
    narration = text;
    this.audioKey = audioKey;
    onChanged();
  }

  @override
  void restrictPalette(List<String> opcodeIds) {
    paletteIds = opcodeIds;
    onChanged();
  }

  @override
  void spotlight(SpotlightTarget? target) {
    spotlightTarget = target;
    onChanged();
  }

  void childChanged() {
    canvas.reset();
    runProgram(controller.program, canvas);
    onChanged();
  }
}

/// Public so the M19 acceptance test can ask the player where it is. The state itself is
/// bookkeeping; every decision in it belongs to [TutorialPlayer].
class TutorielScreenState extends State<TutorielScreen> {
  late final _ScreenHost _host = _ScreenHost(() {
    if (mounted) setState(() {});
  });
  late final TutorialPlayer _player = TutorialPlayer(
    tutorial: widget.tutorial,
    host: _host,
    locale: ShellScope.of(context).session.interfaceLocale.code,
    firstPass: widget.firstPass,
  );
  bool _started = false;
  String? _retryHint;

  TutorialPlayer get player => _player;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _player.start();
    _host.controller.addListener(_onChildEdit);
  }

  @override
  void dispose() {
    _host.controller.removeListener(_onChildEdit);
    super.dispose();
  }

  /// The child edited the scratch document, so ask the step whether that was the thing.
  ///
  /// Checking on every edit rather than on a button is deliberate: `FR-M5-02`'s single
  /// call to action means the step's one button is *continue*, and a child who has just
  /// placed the right block should not also have to tell the tutorial they did.
  void _onChildEdit() {
    _host.childChanged();
    if (_player.state != PlayerState.waiting) return;
    if (_player.checkProgress()) {
      setState(() => _retryHint = null);
    }
  }

  void _press() {
    if (_player.isFinished) {
      widget.onFinished();
      return;
    }
    if (_player.state == PlayerState.stepComplete) {
      setState(() {
        _retryHint = null;
        _player.advance();
      });
      return;
    }
    /* The child pressed continue without having done the step. That is not a failure and
       is never named as one: the step's own retry hint is offered, and the button stays
       exactly where it was. */
    setState(() => _retryHint = _player.retryHint());
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    final locale = shell.session.interfaceLocale.code;
    final prefs = shell.session.accessibility;
    final step = _player.current;
    final finished = _player.isFinished;

    return KodoScaffold(
      titleKey: 'root.tutoriel',
      child: Column(
        children: [
          /* `FR-M5-03`: the words are ALWAYS on screen, whether or not the recording
             plays. A tutorial a child has to hear is a tutorial a child in a noisy
             classroom, or with no headphones, or who is deaf, does not have. */
          _Prompt(
            text: finished
                ? _s(context, 'tutorial.learned',
                    {'concept': _player.closingLine()})
                : _host.narration,
            locale: locale,
            prefs: prefs,
          ),
          if (_retryHint != null)
            _Panel(
              key: const Key('tutorial-retry'),
              // The step's own sentence, authored as content. The shell never writes a
              // sentence about a child's work.
              text: _retryHint!,
              tone: _Tone.again,
            ),
          Expanded(
            child: _Spotlight(
              target: _host.spotlightTarget,
              label: _s(context, 'a11y.spotlight'),
              child: _Work(
                controller: _host.controller,
                /* The tutorial's own palette when it names one (`FR-M2-08`), and the
                   world's otherwise. A tutorial that showed a block it is not about is
                   a tutorial with something else to look at. */
                scope: _host.paletteIds == null
                    ? scopeForWorld(_worldOfConcept(widget.tutorial.conceptId))
                    : PaletteScope.ofIds(_host.paletteIds!),
                keywordLocale: shell.session.keywordLocale,
                drawn: _host.canvas,
                locale: locale,
              ),
            ),
          ),
          /* `FR-M5-02`: one button. Its words are the step's own — "Pose le bloc",
             "Appuie sur le vert" — because the one thing a child is asked to do is the
             one thing the step is about. */
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: minimumTouchTarget,
              child: FilledButton(
                key: const Key('tutorial-cta'),
                onPressed: _press,
                child: Text(finished
                    ? _s(context, 'button.to_exercises')
                    : step!.callToActionIn(locale)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `C11.4` lives in World 11: the digits after the `C` are the world, not the first one.
int _worldOfConcept(String conceptId) =>
    int.tryParse(conceptId.replaceAll(RegExp(r'^C'), '').split('.').first) ?? 1;

/// Dims everything but the one place the step points at (`FR-M5-02`).
///
/// A scrim rather than a moving cut-out, because the spotlight has to survive reduced
/// motion (`FR-M16-03`) and because a child on a 2 GB phone should not pay for an
/// animation to be told where to look. When a step points nowhere there is no scrim at
/// all: dimming the whole screen to highlight nothing is worse than not dimming it.
class _Spotlight extends StatelessWidget {
  const _Spotlight({
    required this.target,
    required this.label,
    required this.child,
  });

  final SpotlightTarget? target;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (target == null) return child;
    return Semantics(
      label: label,
      container: true,
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                key: Key('spotlight-${target!.name}'),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber.shade700, width: 3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
