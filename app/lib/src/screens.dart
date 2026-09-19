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
                onTap: () => shell.go(KodoScreen.item, conceptId: id),
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
class _Work extends StatelessWidget {
  const _Work({
    required this.controller,
    required this.scope,
    required this.keywordLocale,
    required this.drawn,
    required this.locale,
  });

  final EditorController controller;
  final PaletteScope scope;
  final String keywordLocale;
  final VectorCanvas? drawn;
  final String locale;

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
        final compact = box.maxWidth < 600;
        final editor = BlockEditor(
          controller: controller,
          scope: scope,
          locale: keywordLocale,
          compact: compact,
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
