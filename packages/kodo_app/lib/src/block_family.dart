/// The ten block families (FR-M2-01, FR-M16-01, FR-M16-05).
///
/// *"each with a colour **and** an icon **and** a silhouette, so colour is never the only
/// signal."* That is `FR-M16-01`, and the M4 prompt's `Do not` puts the consequence
/// plainly: the block-family shapes must be decided **before the art is drawn**. So they
/// are decided here, in code, with a test that fails if two families ever become
/// indistinguishable without colour.
library;

import 'package:flutter/material.dart';

/// The shape of a block's outline. The second signal, after colour.
enum BlockSilhouette {
  /// A plain stack block: notch on top, tab underneath.
  stack,

  /// A hat block — nothing can sit above it. Events.
  hat,

  /// A C-block whose mouth encloses its body. Control.
  wrapper,

  /// A rounded reporter that slots into a hole. Operators, sensing, data.
  reporter,

  /// A pointed boolean that slots into a diamond hole.
  boolean,

  /// A cap block: nothing can follow it.
  cap,
}

/// The ten families of `FR-M2-01`, in the order the palette shows them.
enum BlockFamily {
  mouvement('family.mouvement', Color(0xFF1B62C4), Icons.open_with,
      BlockSilhouette.stack),
  apparence('family.apparence', Color(0xFF7A3EA8), Icons.visibility,
      BlockSilhouette.stack),
  son('family.son', Color(0xFFA8228A), Icons.music_note, BlockSilhouette.stack),
  stylo('family.stylo', Color(0xFF0B6E5E), Icons.edit, BlockSilhouette.stack),
  donnees('family.donnees', Color(0xFFB2560D), Icons.inbox,
      BlockSilhouette.reporter),
  evenements(
      'family.evenements', Color(0xFF8A6D00), Icons.flag, BlockSilhouette.hat),
  controle('family.controle', Color(0xFF9A5B00), Icons.loop,
      BlockSilhouette.wrapper),
  capteurs('family.capteurs', Color(0xFF1B6F8A), Icons.sensors,
      BlockSilhouette.reporter),
  operateurs('family.operateurs', Color(0xFF3F7A12), Icons.calculate,
      BlockSilhouette.boolean),
  mesBlocs('family.mesblocs', Color(0xFF9E2A5B), Icons.extension,
      BlockSilhouette.stack);

  const BlockFamily(this.nameKey, this.colour, this.icon, this.silhouette);

  /// A localisation key. The palette shows the word beside the icon — `FR-M2-01` and
  /// §9.2's rule that it is *"icon + word, never icon alone, never word alone"*.
  final String nameKey;

  final Color colour;
  final IconData icon;
  final BlockSilhouette silhouette;

  /// The three signals a child can use to tell this family from another.
  ///
  /// A family is distinguishable from another when **any** of them differs. The test that
  /// matters removes the first and checks the remaining two still separate every pair.
  ({Color colour, IconData icon, BlockSilhouette silhouette}) get signals =>
      (colour: colour, icon: icon, silhouette: silhouette);
}

/// Family names, per locale. Authored, never generated.
const familyNames = <String, Map<String, String>>{
  'fr': {
    'family.mouvement': 'Mouvement',
    'family.apparence': 'Apparence',
    'family.son': 'Son',
    'family.stylo': 'Stylo',
    'family.donnees': 'Données',
    'family.evenements': 'Événements',
    'family.controle': 'Contrôle',
    'family.capteurs': 'Capteurs',
    'family.operateurs': 'Opérateurs',
    'family.mesblocs': 'Mes blocs',
  },
  'en': {
    'family.mouvement': 'Motion',
    'family.apparence': 'Looks',
    'family.son': 'Sound',
    'family.stylo': 'Pen',
    'family.donnees': 'Data',
    'family.evenements': 'Events',
    'family.controle': 'Control',
    'family.capteurs': 'Sensing',
    'family.operateurs': 'Operators',
    'family.mesblocs': 'My blocks',
  },
};
