/// The Studio (M9).
///
/// Autosave and versions, the ungated palette, presentation mode, export, and the
/// **Recettes** panel.
///
/// The module prompt's `Do not` is the reason this file has no progress parameter anywhere
/// in it: *"do not gate any block behind progression in the Studio — the Studio is where a
/// child may attempt what they have not yet been taught."* [studioPalette] is a constant,
/// not a function of a learner, so there is nothing for a future contributor to filter.
library;

import 'dart:typed_data';

import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';

import 'project.dart';

// ---------------------------------------------------------------------------------------
// The palette (FR-M9-02, and the module prompt's `Do not`)
// ---------------------------------------------------------------------------------------

/// Every opcode, always.
///
/// In an exercise the palette is scoped by `Item.paletteScope`, because an exercise is a
/// question and a question narrows. The Studio is not a question.
const List<Opcode> studioPalette = Opcode.values;

// ---------------------------------------------------------------------------------------
// Autosave and versions (FR-M9-03)
// ---------------------------------------------------------------------------------------

/// The local project store.
///
/// `FR-M9-03`: *"autosave every 20 s and on background; local versions kept for 10 saves."*
/// Ten is a ring, not a cap — the eleventh save drops the oldest rather than refusing.
class ProjectStore {
  ProjectStore({this.retainedVersions = 10});

  static const autosaveInterval = Duration(seconds: 20);

  final int retainedVersions;

  final Map<String, List<Project>> _versions = {};

  /// Newest first, so "undo my last save" is `versions(id)[1]`.
  List<Project> versions(String projectId) =>
      List.unmodifiable(_versions[projectId] ?? const <Project>[]);

  Project? current(String projectId) => _versions[projectId]?.firstOrNull;

  List<String> get projectIds => _versions.keys.toList()..sort();

  /// Unlimited projects (`FR-M9-01`) — there is no count to check here, deliberately.
  Project save(Project project, {required DateTime at}) {
    final saved = project.copyWith(
      savedAt: at,
      version: (current(project.id)?.version ?? 0) + 1,
    );
    final list = _versions.putIfAbsent(project.id, () => <Project>[])
      ..insert(0, saved);
    if (list.length > retainedVersions) list.removeRange(retainedVersions, list.length);
    return saved;
  }

  /// Restores a retained version as the newest one. The version being replaced is kept,
  /// because a child who restores by mistake has to be able to come back.
  Project restore(String projectId, int index, {required DateTime at}) {
    final list = _versions[projectId];
    if (list == null || index < 0 || index >= list.length) {
      throw ArgumentError('no version $index of "$projectId"');
    }
    return save(list[index], at: at);
  }
}

/// Drives the autosave clock.
///
/// The acceptance test is *"force-kill during an edit loses at most 20 s of work, measured
/// 50 times"*. That is a property of when saves happen, not of how fast they are, so this
/// is where it is decided and where it is tested.
class Autosaver {
  Autosaver(this.store, {required this.projectId});

  final ProjectStore store;
  final String projectId;

  DateTime? _lastSavedAt;
  Project? _pending;

  DateTime? get lastSavedAt => _lastSavedAt;

  /// The child changed something. Nothing is written yet.
  void edited(Project project) => _pending = project;

  /// Called on a timer. Writes if the interval has elapsed and there is anything to write.
  bool tick(DateTime now) {
    final pending = _pending;
    if (pending == null) return false;
    final last = _lastSavedAt;
    if (last != null && now.difference(last) < ProjectStore.autosaveInterval) {
      return false;
    }
    _write(pending, now);
    return true;
  }

  /// The app went to the background — the home button, a phone call, the battery warning.
  /// This writes immediately whatever the timer thinks, because on a 2 GB device the next
  /// thing that happens may be the process being killed.
  bool onBackground(DateTime now) {
    final pending = _pending;
    if (pending == null) return false;
    _write(pending, now);
    return true;
  }

  void _write(Project project, DateTime now) {
    store.save(project, at: now);
    _lastSavedAt = now;
    _pending = null;
  }

  /// How much work a force-kill at [now] would destroy.
  ///
  /// Zero when nothing is unsaved. This is the number the acceptance test measures, and it
  /// is computed from the same state the saving uses rather than from a parallel model.
  Duration workAtRisk(DateTime now, {required DateTime lastEditAt}) {
    if (_pending == null) return Duration.zero;
    final since = _lastSavedAt ?? lastEditAt;
    final risk = now.difference(since);
    return risk.isNegative ? Duration.zero : risk;
  }
}

// ---------------------------------------------------------------------------------------
// Presentation (FR-M9-04)
// ---------------------------------------------------------------------------------------

/// Full-screen presentation of a finished project.
///
/// The child is showing it to somebody, so everything that is not the project goes away —
/// and, since a child in the room can reach the screen, so does everything that would let
/// a stray tap change the work.
class PresentationMode {
  const PresentationMode({this.showsPalette = false, this.editable = false});
  final bool showsPalette;
  final bool editable;

  bool get isSafeToHandOver => !showsPalette && !editable;
}

// ---------------------------------------------------------------------------------------
// Export (FR-M9-05)
// ---------------------------------------------------------------------------------------

/// Where the Studio is running. Screen capture is desktop-first by `FR-M9-05`.
enum StudioPlatform { android, ios, desktop, web }

/// What the export sheet offers.
enum ExportKind { projectFile, png, svg, screenCapture }

/// Export.
class StudioExport {
  const StudioExport();

  static const captureSeconds = 30;

  /// `FR-M9-05` says *"MP4 screen capture of a 30-second run (desktop first)"*. Offering
  /// the button on a 2 GB Android phone and then failing is worse than not offering it, so
  /// availability is answered here rather than discovered at the end of a recording.
  List<ExportKind> kindsOn(StudioPlatform platform) => [
        ExportKind.projectFile,
        ExportKind.png,
        ExportKind.svg,
        if (platform == StudioPlatform.desktop) ExportKind.screenCapture,
      ];

  String projectFile(Project project) => ProjectFile(project).encode();

  String svg(VectorCanvas canvas, {String title = 'KODO'}) =>
      canvas.toSvg(title: title);

  Uint8List png(VectorCanvas canvas, {double scale = 1.0}) =>
      canvas.toPng(scale: scale);
}

/// A project's thumbnail (`FR-M9-03`, and the adversarial review of M10).
///
/// Constructible **only** from a canvas. A thumbnail is a render of the child's own
/// program, never a picture from the device, so the M10 review question *"can personal
/// data be surfaced through a thumbnail"* has a structural answer rather than a policy
/// one: there is no constructor that takes an image.
class Thumbnail {
  const Thumbnail._(this.svg);

  final String svg;

  static Thumbnail ofCanvas(VectorCanvas canvas) =>
      Thumbnail._(canvas.toSvg(title: 'KODO'));
}

// ---------------------------------------------------------------------------------------
// Recettes (FR-M9-06)
// ---------------------------------------------------------------------------------------

/// One copy-a-pattern recipe.
///
/// *"the equivalent of the Conseils window"* — a thing a child copies into their project
/// when they know what they want and not how to say it. Every recipe ships runnable: the
/// acceptance test parses and runs each one, because a recipe that does not run teaches a
/// child that their copy of it was the thing that was wrong.
class Recipe {
  const Recipe({
    required this.id,
    required this.titleKeys,
    required this.wantKeys,
    required this.source,
  });

  final String id;

  /// The name in the panel, e.g. *faire rebondir*.
  final Map<String, String> titleKeys;

  /// What the child was trying to do, in their words. This is the line they scan, so it is
  /// written as the wish, not as the mechanism.
  final Map<String, String> wantKeys;

  /// French source. The Studio renders it in the child's keyword language through M1's
  /// renderer — there is no second copy of the recipe per language, because two copies
  /// drift.
  final String source;

  String titleIn(String locale) => titleKeys[locale] ?? titleKeys['fr']!;
  String wantIn(String locale) => wantKeys[locale] ?? wantKeys['fr']!;

  /// The recipe as a child in [locale] would read it.
  String sourceIn(String locale) {
    final parsed = parse(source, KeywordTables.fr);
    return render(parsed.program, KeywordTables.of(locale));
  }
}

/// The Recettes panel. `FR-M9-06` asks for twenty or more.
const List<Recipe> recettes = [
  Recipe(
    id: 'carre',
    titleKeys: {'fr': 'Dessiner un carré', 'en': 'Draw a square'},
    wantKeys: {'fr': 'Je veux un carré.', 'en': 'I want a square.'},
    source: 'répète 4 {\n  avance 80\n  tournedroite 90\n}\n',
  ),
  Recipe(
    id: 'etoile',
    titleKeys: {'fr': 'Dessiner une étoile', 'en': 'Draw a star'},
    wantKeys: {'fr': 'Je veux une étoile.', 'en': 'I want a star.'},
    source: 'répète 5 {\n  avance 120\n  tournedroite 144\n}\n',
  ),
  Recipe(
    id: 'cercle',
    titleKeys: {'fr': 'Dessiner un rond', 'en': 'Draw a circle'},
    wantKeys: {'fr': 'Je veux un rond.', 'en': 'I want a circle.'},
    source: 'répète 36 {\n  avance 10\n  tournedroite 10\n}\n',
  ),
  Recipe(
    id: 'rebondir',
    titleKeys: {'fr': 'Faire rebondir', 'en': 'Make it bounce'},
    wantKeys: {
      'fr': 'Je veux que ça reparte quand ça touche le bord.',
      'en': 'I want it to come back when it hits the edge.',
    },
    source: 'répète 12 {\n'
        '  avance 30\n'
        r'  si positionx > 150 {' '\n'
        '    tournedroite 180\n'
        '  }\n'
        r'  si positionx < -150 {' '\n'
        '    tournedroite 180\n'
        '  }\n'
        '}\n',
  ),
  Recipe(
    id: 'compter-les-points',
    titleKeys: {'fr': 'Compter les points', 'en': 'Keep the score'},
    wantKeys: {
      'fr': 'Je veux un score qui monte.',
      'en': 'I want a score that goes up.',
    },
    source: r'$points = 0' '\n'
        'répète 5 {\n'
        r'  $points = $points + 1' '\n'
        r'  écris $points' '\n'
        '}\n',
  ),
  Recipe(
    id: 'changer-decran',
    titleKeys: {'fr': "Changer d'écran", 'en': 'Change the screen'},
    wantKeys: {
      'fr': 'Je veux passer du menu au jeu.',
      'en': 'I want to go from the menu to the game.',
    },
    source: r'$écran = "menu"' '\n'
        r'si $écran == "menu" {' '\n'
        '  nettoietout\n'
        '  écris "Appuie pour jouer"\n'
        '} sinon {\n'
        '  nettoietout\n'
        '  avance 50\n'
        '}\n',
  ),
  Recipe(
    id: 'utiliser-la-reponse',
    titleKeys: {'fr': 'Utiliser la réponse', 'en': 'Use the answer'},
    wantKeys: {
      'fr': 'Je veux que le joueur choisisse le nombre de pas.',
      'en': 'I want the player to choose how many steps.',
    },
    source: r'$pas = demande "combien de pas ?"' '\n'
        r'avance nombre $pas' '\n'
        'montre\n',
  ),
  Recipe(
    id: 'gagner-perdre',
    titleKeys: {'fr': 'Gagner ou perdre', 'en': 'Win or lose'},
    wantKeys: {
      'fr': "Je veux dire si c'est gagné.",
      'en': 'I want to say whether it is won.',
    },
    source: r'$points = 3' '\n'
        r'si $points >= 3 {' '\n'
        '  message "Gagné !"\n'
        '} sinon {\n'
        '  message "Encore une fois"\n'
        '}\n',
  ),
  Recipe(
    id: 'spirale',
    titleKeys: {'fr': 'Faire une spirale', 'en': 'Make a spiral'},
    wantKeys: {
      'fr': 'Je veux que ça tourne en grandissant.',
      'en': 'I want it to spin and grow.',
    },
    source: r'pour $i = 1 à 40 {' '\n'
        r'  avance $i * 3' '\n'
        '  tournedroite 91\n'
        '}\n',
  ),
  Recipe(
    id: 'arc-en-ciel',
    titleKeys: {'fr': 'Changer de couleur', 'en': 'Change colour'},
    wantKeys: {
      'fr': 'Je veux plusieurs couleurs.',
      'en': 'I want several colours.',
    },
    source: 'répète 6 {\n'
        '  couleurcrayon hasard 0, 255, hasard 0, 255, hasard 0, 255\n'
        '  avance 60\n'
        '  tournedroite 60\n'
        '}\n',
  ),
  Recipe(
    id: 'ecrire-un-mot',
    titleKeys: {'fr': 'Écrire un mot', 'en': 'Write a word'},
    wantKeys: {
      'fr': "Je veux écrire quelque chose à l'écran.",
      'en': 'I want to write something on the screen.',
    },
    source: 'taillepolice 32\nécris "Bonjour"\n',
  ),
  Recipe(
    id: 'poser-une-question',
    titleKeys: {'fr': 'Poser une question', 'en': 'Ask a question'},
    wantKeys: {
      'fr': 'Je veux demander quelque chose au joueur.',
      'en': 'I want to ask the player something.',
    },
    source: r'$couleur = demande "Ta couleur ?"' '\n'
        r'écris $couleur' '\n',
  ),
  Recipe(
    id: 'attendre',
    titleKeys: {'fr': 'Attendre un instant', 'en': 'Wait a moment'},
    wantKeys: {
      'fr': 'Je veux que ça aille moins vite.',
      'en': 'I want it to go slower.',
    },
    source: 'répète 5 {\n  avance 40\n  attends 1\n}\n',
  ),
  Recipe(
    id: 'cacher-montrer',
    titleKeys: {'fr': 'Cacher et montrer', 'en': 'Hide and show'},
    wantKeys: {
      'fr': 'Je veux faire disparaître la tortue.',
      'en': 'I want to make the turtle disappear.',
    },
    source: 'cache\navance 60\nmontre\n',
  ),
  Recipe(
    id: 'tirer-au-hasard',
    titleKeys: {'fr': 'Tirer au hasard', 'en': 'Pick at random'},
    wantKeys: {
      'fr': 'Je veux que ce soit différent à chaque fois.',
      'en': 'I want it different every time.',
    },
    source: 'répète 10 {\n'
        '  avance hasard 20, 80\n'
        '  tournedroite hasard 0, 359\n'
        '}\n',
  ),
  Recipe(
    id: 'garder-une-liste',
    titleKeys: {'fr': 'Garder une liste', 'en': 'Keep a list'},
    wantKeys: {
      'fr': 'Je veux ranger plusieurs choses ensemble.',
      'en': 'I want to keep several things together.',
    },
    source: r'$amis = ["Awa", "Moussa", "Fatou"]' '\n'
        r'pour $i = 1 à 3 {' '\n'
        r'  écris $amis[$i]' '\n'
        '}\n',
  ),
  Recipe(
    id: 'mon-propre-bloc',
    titleKeys: {'fr': 'Créer mon bloc', 'en': 'Make my own block'},
    wantKeys: {
      'fr': 'Je veux réutiliser la même chose partout.',
      'en': 'I want to reuse the same thing everywhere.',
    },
    source: r'apprends carré $côté {' '\n'
        '  répète 4 {\n'
        r'    avance $côté' '\n'
        '    tournedroite 90\n'
        '  }\n'
        '}\n'
        'carré 40\n'
        'carré 80\n',
  ),
  Recipe(
    id: 'repeter-jusqu-a',
    titleKeys: {'fr': "Répéter jusqu'à", 'en': 'Repeat until'},
    wantKeys: {
      'fr': "Je veux continuer tant que ce n'est pas fini.",
      'en': 'I want to keep going until it is done.',
    },
    source: r'$faits = 0' '\n'
        r'tantque $faits < 5 {' '\n'
        '  avance 30\n'
        r'  $faits = $faits + 1' '\n'
        '}\n',
  ),
  Recipe(
    id: 'arreter-la-boucle',
    titleKeys: {'fr': 'Arrêter la boucle', 'en': 'Stop the loop'},
    wantKeys: {
      'fr': 'Je veux sortir avant la fin.',
      'en': 'I want to get out before the end.',
    },
    source: r'pour $i = 1 à 20 {' '\n'
        '  avance 20\n'
        r'  si $i > 5 {' '\n'
        '    coupure\n'
        '  }\n'
        '}\n',
  ),
  Recipe(
    id: 'changer-le-fond',
    titleKeys: {'fr': 'Changer le fond', 'en': 'Change the background'},
    wantKeys: {
      'fr': 'Je veux changer la couleur du fond.',
      'en': 'I want to change the background colour.',
    },
    source: 'couleurcanevas 20, 20, 60\n'
        'nettoietout\n'
        'couleurcrayon 255, 255, 0\n'
        'avance 80\n',
  ),
  Recipe(
    id: 'deux-endroits',
    titleKeys: {'fr': 'Dessiner à deux endroits', 'en': 'Draw in two places'},
    wantKeys: {
      'fr': 'Je veux deux dessins séparés.',
      'en': 'I want two separate drawings.',
    },
    source: 'lèvecrayon\n'
        'va -100, 0\n'
        'baissecrayon\n'
        'répète 4 {\n  avance 40\n  tournedroite 90\n}\n'
        'lèvecrayon\n'
        'va 100, 0\n'
        'baissecrayon\n'
        'répète 3 {\n  avance 50\n  tournedroite 120\n}\n',
  ),
  Recipe(
    id: 'compte-a-rebours',
    titleKeys: {'fr': 'Un compte à rebours', 'en': 'A countdown'},
    wantKeys: {
      'fr': "Je veux compter jusqu'à zéro.",
      'en': 'I want to count down to zero.',
    },
    source: r'pour $i = 5 à 1 pas -1 {' '\n'
        r'  écris $i' '\n'
        '}\n'
        'message "Partez !"\n',
  ),
];

/// Recipes are looked up by what the child wants, not by what they are called. A child who
/// knows the word *boucle* does not need the panel; the one who needs it is looking for
/// "que ça reparte quand ça touche le bord".
List<Recipe> recipesMatching(String wish, {String locale = 'fr'}) {
  final needle = wish.toLowerCase().trim();
  if (needle.isEmpty) return const [];
  return [
    for (final recipe in recettes)
      if (recipe.titleIn(locale).toLowerCase().contains(needle) ||
          recipe.wantIn(locale).toLowerCase().contains(needle))
        recipe,
  ];
}
