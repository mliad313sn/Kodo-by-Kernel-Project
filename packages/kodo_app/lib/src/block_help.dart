/// Block help (FR-M2-10).
///
/// *"Contextual help on any block: one tap, opens the reference entry with a runnable
/// 3-line example."* And the acceptance test: **every block has help content in FR and EN;
/// a coverage test fails the build otherwise.**
///
/// The help is authored here rather than generated from the opcode table, because "what
/// this block does" is content and gets the same review as every other string a child
/// reads.
library;

import 'package:kodo_lang/kodo_lang.dart';

import 'block_family.dart';

/// One block's reference entry.
class BlockHelp {
  const BlockHelp({
    required this.family,
    required this.summaryKeys,
    required this.exampleSource,
  });

  final BlockFamily family;

  /// One sentence, at the reading level of §4.2.
  final Map<String, String> summaryKeys;

  /// A runnable three-line example. It is parsed by a test, so it cannot rot.
  final String exampleSource;

  String summaryIn(String locale) =>
      summaryKeys[locale] ?? summaryKeys['fr'] ?? '';
}

Map<String, String> _b(String fr, String en) => {'fr': fr, 'en': en};

/// Help for every opcode. A missing entry fails the coverage test.
final Map<Opcode, BlockHelp> blockHelp = {
  Opcode.moveForward: BlockHelp(
    family: BlockFamily.mouvement,
    summaryKeys:
        _b('Fait avancer Tika tout droit.', 'Makes Tika move straight ahead.'),
    exampleSource: 'avance 100\ntournedroite 90\navance 100',
  ),
  Opcode.moveBack: BlockHelp(
    family: BlockFamily.mouvement,
    summaryKeys: _b('Fait reculer Tika, sans la faire tourner.',
        'Moves Tika backwards, without turning her.'),
    exampleSource: 'avance 80\nrecule 80\ntournedroite 90',
  ),
  Opcode.turnLeft: BlockHelp(
    family: BlockFamily.mouvement,
    summaryKeys: _b('Fait tourner Tika vers la gauche, sur place.',
        'Turns Tika to the left, where she stands.'),
    exampleSource: 'avance 60\ntournegauche 90\navance 60',
  ),
  Opcode.turnRight: BlockHelp(
    family: BlockFamily.mouvement,
    summaryKeys: _b('Fait tourner Tika vers la droite, sur place.',
        'Turns Tika to the right, where she stands.'),
    exampleSource: 'avance 60\ntournedroite 90\navance 60',
  ),
  Opcode.setDirection: BlockHelp(
    family: BlockFamily.mouvement,
    summaryKeys: _b('Fait pointer Tika dans une direction précise.',
        'Points Tika in an exact direction.'),
    exampleSource: 'direction 90\navance 80\ndirection 180',
  ),
  Opcode.getDirection: BlockHelp(
    family: BlockFamily.capteurs,
    summaryKeys: _b('Donne la direction dans laquelle Tika pointe.',
        'Gives the direction Tika is pointing.'),
    exampleSource: 'tournedroite 45\nécris obtenirdirection\navance 50',
  ),
  Opcode.center: BlockHelp(
    family: BlockFamily.mouvement,
    summaryKeys: _b('Ramène Tika au milieu, sans dessiner.',
        'Puts Tika back in the middle, without drawing.'),
    exampleSource: 'avance 100\ncentre\navance 50',
  ),
  Opcode.go: BlockHelp(
    family: BlockFamily.mouvement,
    summaryKeys: _b('Déplace Tika à un endroit précis, sans dessiner.',
        'Moves Tika to an exact spot, without drawing.'),
    exampleSource: 'va 100, 100\navance 50\nva 200, 200',
  ),
  Opcode.goX: BlockHelp(
    family: BlockFamily.mouvement,
    summaryKeys: _b('Déplace Tika de côté, sans changer sa hauteur.',
        'Moves Tika sideways, without changing her height.'),
    exampleSource: 'vax 150\navance 40\nvax 250',
  ),
  Opcode.goY: BlockHelp(
    family: BlockFamily.mouvement,
    summaryKeys: _b('Déplace Tika en hauteur, sans changer son côté.',
        'Moves Tika up or down, without changing her side.'),
    exampleSource: 'vay 150\navance 40\nvay 250',
  ),
  Opcode.positionX: BlockHelp(
    family: BlockFamily.capteurs,
    summaryKeys: _b('Donne la position de Tika de gauche à droite.',
        'Gives how far along Tika is, left to right.'),
    exampleSource: 'avance 50\nécris positionx\navance 50',
  ),
  Opcode.positionY: BlockHelp(
    family: BlockFamily.capteurs,
    summaryKeys: _b('Donne la position de Tika de haut en bas.',
        'Gives how far along Tika is, top to bottom.'),
    exampleSource: 'avance 50\nécris positiony\navance 50',
  ),
  Opcode.penUp: BlockHelp(
    family: BlockFamily.stylo,
    summaryKeys: _b('Lève le crayon : Tika bouge sans dessiner.',
        'Lifts the pen: Tika moves without drawing.'),
    exampleSource: 'avance 50\nlèvecrayon\navance 50',
  ),
  Opcode.penDown: BlockHelp(
    family: BlockFamily.stylo,
    summaryKeys: _b('Baisse le crayon : Tika dessine en bougeant.',
        'Puts the pen down: Tika draws as she moves.'),
    exampleSource: 'lèvecrayon\navance 50\nbaissecrayon',
  ),
  Opcode.penWidth: BlockHelp(
    family: BlockFamily.stylo,
    summaryKeys:
        _b('Change l\'épaisseur du trait.', 'Changes how thick the line is.'),
    exampleSource: 'largeurcrayon 5\navance 80\nlargeurcrayon 1',
  ),
  Opcode.penColor: BlockHelp(
    family: BlockFamily.stylo,
    summaryKeys: _b('Change la couleur du crayon, avec trois nombres.',
        'Changes the pen colour, using three numbers.'),
    exampleSource:
        'couleurcrayon 255, 0, 0\navance 80\ncouleurcrayon 0, 0, 255',
  ),
  Opcode.canvasSize: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys:
        _b('Change la taille de la feuille.', 'Changes the size of the paper.'),
    exampleSource: 'taillecanevas 300, 300\navance 80\ntournedroite 90',
  ),
  Opcode.canvasColor: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys:
        _b('Change la couleur du fond.', 'Changes the background colour.'),
    exampleSource: 'couleurcanevas 255, 255, 200\navance 80\ntournedroite 90',
  ),
  Opcode.clear: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b('Efface le dessin. Tika ne bouge pas.',
        'Erases the drawing. Tika does not move.'),
    exampleSource: 'avance 80\nnettoietout\navance 40',
  ),
  Opcode.reset: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b('Efface tout et remet Tika au départ.',
        'Erases everything and puts Tika back at the start.'),
    exampleSource: 'avance 80\ntournedroite 90\ninitialise',
  ),
  Opcode.show: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b('Montre Tika à l\'écran.', 'Shows Tika on the screen.'),
    exampleSource: 'cache\navance 60\nmontre',
  ),
  Opcode.hide: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys:
        _b('Cache Tika. Le dessin reste.', 'Hides Tika. The drawing stays.'),
    exampleSource: 'avance 60\ncache\navance 60',
  ),
  Opcode.print: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys:
        _b('Écrit un mot sur la feuille.', 'Writes a word on the paper.'),
    exampleSource: 'écris "bonjour"\navance 50\nécris "au revoir"',
  ),
  Opcode.fontSize: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b('Change la taille des mots écrits.',
        'Changes how big the written words are.'),
    exampleSource: 'taillepolice 24\nécris "grand"\ntaillepolice 10',
  ),
  Opcode.round: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys: _b('Donne le nombre entier le plus proche.',
        'Gives the nearest whole number.'),
    exampleSource: r'$n = arrondi 3.7' '\n' r'écris $n' '\navance 50',
  ),
  Opcode.random: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys: _b('Donne un nombre au hasard entre deux nombres.',
        'Gives a number at random between two numbers.'),
    exampleSource: 'avance hasard 20, 80\ntournedroite 90\navance 50',
  ),
  Opcode.mod: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys: _b('Donne ce qui reste après un partage.',
        'Gives what is left over after sharing.'),
    exampleSource: r'$r = mod 7, 3' '\n' r'écris $r' '\navance 50',
  ),
  Opcode.sqrt: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys: _b('Donne la racine carrée d\'un nombre.',
        'Gives the square root of a number.'),
    exampleSource: r'$c = racine 81' '\n' r'écris $c' '\navance 50',
  ),
  Opcode.pi: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys: _b('Donne le nombre pi.', 'Gives the number pi.'),
    exampleSource: r'$p = pi' '\n' r'écris $p' '\navance 50',
  ),
  Opcode.sin: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys:
        _b('Donne le sinus d\'un angle.', 'Gives the sine of an angle.'),
    exampleSource: r'$s = sin 30' '\n' r'écris $s' '\navance 50',
  ),
  Opcode.cos: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys:
        _b('Donne le cosinus d\'un angle.', 'Gives the cosine of an angle.'),
    exampleSource: r'$c = cos 60' '\n' r'écris $c' '\navance 50',
  ),
  Opcode.tan: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys:
        _b('Donne la tangente d\'un angle.', 'Gives the tangent of an angle.'),
    exampleSource: r'$t = tan 45' '\n' r'écris $t' '\navance 50',
  ),
  Opcode.arcsin: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys: _b('Retrouve l\'angle à partir d\'un sinus.',
        'Finds the angle back from a sine.'),
    exampleSource: r'$a = arcsin 0.5' '\n' r'écris $a' '\navance 50',
  ),
  Opcode.arccos: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys: _b('Retrouve l\'angle à partir d\'un cosinus.',
        'Finds the angle back from a cosine.'),
    exampleSource: r'$a = arccos 0.5' '\n' r'écris $a' '\navance 50',
  ),
  Opcode.arctan: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys: _b('Retrouve l\'angle à partir d\'une tangente.',
        'Finds the angle back from a tangent.'),
    exampleSource: r'$a = arctan 1' '\n' r'écris $a' '\navance 50',
  ),
  Opcode.message: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b(
        'Affiche un message dans une bulle.', 'Shows a message in a bubble.'),
    exampleSource: 'message "salut"\navance 50\nmessage "fini"',
  ),
  Opcode.ask: BlockHelp(
    family: BlockFamily.capteurs,
    summaryKeys: _b('Pose une question et attend la réponse.',
        'Asks a question and waits for the answer.'),
    exampleSource: r'$n = demande "ton âge ?"' '\n' r'écris $n' '\navance 50',
  ),
  Opcode.toNumber: BlockHelp(
    family: BlockFamily.operateurs,
    summaryKeys: _b('Transforme un texte en nombre, pour pouvoir compter avec.',
        'Turns text into a number, so you can count with it.'),
    exampleSource:
        r'$r = demande "combien ?"' '\n' r'avance nombre $r' '\n' r'écris $r',
  ),
  Opcode.wait: BlockHelp(
    family: BlockFamily.controle,
    summaryKeys: _b('Attend un moment avant de continuer.',
        'Waits a moment before carrying on.'),
    exampleSource: 'avance 50\nattends 1\navance 50',
  ),
  Opcode.assertion: BlockHelp(
    family: BlockFamily.controle,
    summaryKeys: _b('Vérifie que quelque chose est vrai.',
        'Checks that something is true.'),
    exampleSource: r'$x = 5' '\n' r'assertion $x == 5' '\navance 50',
  ),

  // --- Événements (D-014 / FR-M21-01) ---------------------------------------------------
  Opcode.whenFlag: BlockHelp(
    family: BlockFamily.evenements,
    summaryKeys: _b('Ce qui est dedans se fait quand tu appuies sur le drapeau.',
        'What is inside happens when you press the flag.'),
    exampleSource: 'quand drapeau {\n  avance 50\n}',
  ),
  Opcode.whenKey: BlockHelp(
    family: BlockFamily.evenements,
    summaryKeys: _b('Ce qui est dedans se fait quand tu appuies sur cette touche.',
        'What is inside happens when you press that key.'),
    exampleSource: 'quand touche "espace" {\n  avance 50\n}',
  ),
  Opcode.whenClicked: BlockHelp(
    family: BlockFamily.evenements,
    summaryKeys: _b('Ce qui est dedans se fait quand on clique sur Tika.',
        'What is inside happens when Tika is clicked.'),
    exampleSource: 'quand clic {\n  tournedroite 90\n}',
  ),

  // --- Capteurs (FR-M21-03) -------------------------------------------------------------
  Opcode.keyDown: BlockHelp(
    family: BlockFamily.capteurs,
    summaryKeys: _b('Vrai si cette touche est appuyée en ce moment.',
        'True if that key is being held down right now.'),
    exampleSource: 'si touchepressée "espace" {\n  avance 50\n}',
  ),
  Opcode.mouseX: BlockHelp(
    family: BlockFamily.capteurs,
    summaryKeys: _b('Le nombre horizontal du pointeur.',
        'The across number of the pointer.'),
    exampleSource: 'va sourisx, 200\navance 20\ntournedroite 90',
  ),
  Opcode.mouseY: BlockHelp(
    family: BlockFamily.capteurs,
    summaryKeys: _b('Le nombre vertical du pointeur.',
        'The down number of the pointer.'),
    exampleSource: 'va 200, sourisy\navance 20\ntournedroite 90',
  ),
  Opcode.mouseDown: BlockHelp(
    family: BlockFamily.capteurs,
    summaryKeys: _b('Vrai si on appuie sur l\'écran en ce moment.',
        'True if the screen is being pressed right now.'),
    exampleSource: 'si sourisappuyée {\n  avance 50\n}',
  ),
  Opcode.touchingEdge: BlockHelp(
    family: BlockFamily.capteurs,
    summaryKeys: _b('Vrai si Tika est arrivée au bord de la feuille.',
        'True if Tika has reached the edge of the paper.'),
    exampleSource: 'si touchebord {\n  tournedroite 180\n}',
  ),
  Opcode.touchingColour: BlockHelp(
    family: BlockFamily.capteurs,
    summaryKeys: _b('Vrai si Tika est posée sur un trait de cette couleur.',
        'True if Tika is standing on a line of that colour.'),
    exampleSource: 'si touchecouleur 255, 0, 0 {\n  tournedroite 90\n}',
  ),

  // --- Lutins, costumes, sons, scène (FR-M21-04) ----------------------------------------
  Opcode.nextCostume: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b('Passe au costume suivant. Deux d\'affilée font bouger Tika.',
        'Moves to the next costume. Two in a row make Tika move.'),
    exampleSource: 'costumesuivant\nattends 1\ncostumesuivant',
  ),
  Opcode.setCostume: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b('Choisit un costume par son numéro.',
        'Picks a costume by its number.'),
    exampleSource: 'costume 1\nattends 1\ncostume 2',
  ),
  Opcode.costumeNumber: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b('Le numéro du costume porté en ce moment.',
        'The number of the costume being worn right now.'),
    exampleSource: 'écris numérocostume\ncostumesuivant\nécris numérocostume',
  ),
  Opcode.setBackdrop: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b('Change le décor derrière Tika.',
        'Changes the scene behind Tika.'),
    exampleSource: 'arrièreplan "plage"\navance 50\ntournedroite 90',
  ),
  Opcode.setEffect: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b('Change la façon dont Tika est dessinée.',
        'Changes the way Tika is drawn.'),
    exampleSource: 'effet "fantôme", 50\navance 50\neffaceeffets',
  ),
  Opcode.clearEffects: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b('Enlève tous les effets d\'un coup.',
        'Takes every effect off at once.'),
    exampleSource: 'effet "tourbillon", 30\nattends 1\neffaceeffets',
  ),
  Opcode.say: BlockHelp(
    family: BlockFamily.apparence,
    summaryKeys: _b('Fait apparaître une bulle au-dessus de Tika.',
        'Puts a speech bubble above Tika.'),
    exampleSource: 'dis "bonjour"\nattends 1\ndis "au revoir"',
  ),
  Opcode.playSound: BlockHelp(
    family: BlockFamily.son,
    summaryKeys: _b('Joue un son enregistré.', 'Plays a recorded sound.'),
    exampleSource: 'jouson "miaou"\nattends 1\njouson "miaou"',
  ),
  Opcode.playDrum: BlockHelp(
    family: BlockFamily.son,
    summaryKeys: _b('Frappe un tambour pendant un moment.',
        'Hits a drum for a moment.'),
    exampleSource: 'tambour 2, 1\ntambour 5, 1\ntambour 2, 1',
  ),
  Opcode.playNote: BlockHelp(
    family: BlockFamily.son,
    summaryKeys: _b('Joue une note pendant un moment.',
        'Plays a note for a moment.'),
    exampleSource: 'note 60, 0.5\nnote 64, 0.5\nnote 67, 1',
  ),
};
