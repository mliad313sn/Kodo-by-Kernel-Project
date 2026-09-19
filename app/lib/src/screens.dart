/// The screens the shell shows.
///
/// Every one of them is a *composition*: it reads a module's API and renders it. None
/// computes a verdict, a mastery state or a next item — that is `FR-M19-06`, and the
/// dependency test in `test/m19_acceptance_test.dart` enforces it.
library;

import 'package:flutter/material.dart';
import 'package:kodo_access/kodo_access.dart';
import 'package:kodo_app/kodo_app.dart';
import 'package:kodo_lang/kodo_lang.dart';

import 'shell.dart';

/// Every child-facing string comes from M15's catalogue. There is no literal here, and a
/// test scans this file to keep it that way.
String _s(BuildContext context, String key,
        [Map<String, String> args = const {}]) =>
    uiStrings.render(key, ShellScope.of(context).session.interfaceLocale, args);

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
    );
  }
}

/// Choosing who is using the app. This is what replaces a login (`FR-M19-05`).
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
          children: [
            for (final entry in profileNames.entries)
              Material(
                child: ListTile(
                  key: Key('profile-${entry.key}'),
                  // A child's own first name is not an interface string.
                  title:
                      Text(entry.value, style: const TextStyle(fontSize: 24)),
                  minTileHeight: 56,
                  onTap: () => shell.chooseProfile(entry.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The map of worlds. Progress comes from M7; the shell only draws it.
class WorldsScreen extends StatelessWidget {
  const WorldsScreen({super.key, required this.worlds});

  /// world number → its name in the child's language, from the content packs.
  final Map<int, String> worlds;

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    return KodoScaffold(
      titleKey: 'menu.recettes',
      actions: [
        IconButton(
          key: const Key('to-settings'),
          icon: const Icon(Icons.settings),
          tooltip: _s(context, 'label.interface_language'),
          onPressed: () => shell.go(KodoScreen.settings),
        ),
      ],
      child: ListView(
        key: const Key('worlds'),
        children: [
          for (final entry in worlds.entries)
            Material(
              child: ListTile(
                key: Key('world-${entry.key}'),
                title: Text(entry.value, style: const TextStyle(fontSize: 20)),
                minTileHeight: 56,
                onTap: () => shell.go(KodoScreen.concept, worldId: entry.key),
              ),
            ),
          Material(
            child: ListTile(
              key: const Key('to-studio'),
              title: Text(_s(context, 'menu.recettes')),
              minTileHeight: 56,
              onTap: () => shell.go(KodoScreen.studio),
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
      titleKey: 'menu.recettes',
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

/// One item: its prompt, the editor, and a run button.
///
/// The prompt text comes from the item; the editor is M2/M3; grading is M6 and is *not*
/// called here — the shell hands the program to the caller's `onRun`, which is where a
/// grader belongs.
class ItemScreen extends StatelessWidget {
  const ItemScreen({
    super.key,
    required this.prompt,
    required this.controller,
    required this.scope,
    this.onRun,
  });

  final String prompt;
  final EditorController controller;

  /// Which blocks this item offers. It comes from the ITEM (`Item.paletteScope`), not from
  /// the shell: an exercise is a question and a question narrows, and deciding that here
  /// would put curriculum logic in the shell.
  final PaletteScope scope;

  final void Function(Program program)? onRun;

  @override
  Widget build(BuildContext context) {
    return KodoScaffold(
      titleKey: 'button.run',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(prompt,
                key: const Key('prompt'), style: const TextStyle(fontSize: 20)),
          ),
          Expanded(
            child: BlockEditor(
              controller: controller,
              scope: scope,
              locale: ShellScope.of(context).session.keywordLocale,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: FilledButton(
              key: const Key('run'),
              onPressed:
                  onRun == null ? null : () => onRun!(controller.program),
              child: Text(_s(context, 'button.run')),
            ),
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
      titleKey: 'menu.recettes',
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
