/// The progress map (FR-M7-06, FR-M7-07).
///
/// *"Progress is a map, not a list: worlds as islands, concepts as stars (0–3 stars by
/// mastery depth)."* And the requirement that follows it is the one worth writing a type
/// around: **nothing in the progression may be bought, skipped for payment, or unlocked by
/// watching an advertisement.**
///
/// There is therefore no `unlock()` method here, and no price, and no ad slot. A concept
/// opens when its prerequisites are mastered, and that is the only door.
library;

import 'mastery.dart';

/// One concept on the map.
class ConceptNode {
  const ConceptNode({
    required this.id,
    required this.world,
    required this.nameKeys,
    required this.prerequisites,
  });

  final String id;
  final int world;

  /// Child-language names, per locale — §4.1 requires a concept to have *"a name in child
  /// language"*, and the map is where the child reads it.
  final Map<String, String> nameKeys;

  final List<String> prerequisites;

  String nameIn(String locale) => nameKeys[locale] ?? nameKeys['fr'] ?? id;
}

/// A world: an island on the map.
class WorldNode {
  const WorldNode(
      {required this.number, required this.nameKeys, required this.concepts});
  final int number;
  final Map<String, String> nameKeys;
  final List<ConceptNode> concepts;

  String nameIn(String locale) =>
      nameKeys[locale] ?? nameKeys['fr'] ?? 'World $number';
}

/// The prerequisite graph plus a child's states.
class ProgressMap {
  const ProgressMap({required this.worlds});
  final List<WorldNode> worlds;

  Iterable<ConceptNode> get concepts => worlds.expand((w) => w.concepts);

  ConceptNode? concept(String id) {
    for (final c in concepts) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Concepts a child may be offered.
  ///
  /// A concept is open when every prerequisite is `Maîtrisé` **or** `À revoir` — a decayed
  /// concept still counts as learned, because taking away access to what a child already
  /// earned would be the punishment §10 forbids.
  Set<String> unlockedFor(Map<String, MasteryState> states) {
    final open = <String>{};
    for (final c in concepts) {
      final ready = c.prerequisites.every((p) {
        final s = states[p]?.state;
        return s == ConceptState.maitrise || s == ConceptState.aRevoir;
      });
      if (ready) open.add(c.id);
    }
    return open;
  }

  /// Stars per concept, 0 to 3.
  Map<String, int> starsFor(Map<String, MasteryState> states) => {
        for (final c in concepts) c.id: states[c.id]?.stars ?? 0,
      };

  /// A world's completion, for the island art. Not a percentage of *items*: a percentage
  /// of *stars*, so a child who finished everything without mastering anything does not
  /// see a full island.
  double worldProgress(int world, Map<String, MasteryState> states) {
    final w = worlds.firstWhere((w) => w.number == world,
        orElse: () => const WorldNode(number: -1, nameKeys: {}, concepts: []));
    if (w.concepts.isEmpty) return 0;
    final earned =
        w.concepts.fold<int>(0, (sum, c) => sum + (states[c.id]?.stars ?? 0));
    return earned / (w.concepts.length * 3);
  }

  /// Builds a map from the concept ledger in `spec/concepts.json`.
  static ProgressMap fromConceptLedger(List<Map<String, Object?>> rows) {
    final byWorld = <int, List<ConceptNode>>{};
    final worldNames = <int, Map<String, String>>{};
    for (final row in rows) {
      final world = row['world']! as int;
      worldNames[world] = {'fr': row['worldName']! as String};
      byWorld.putIfAbsent(world, () => []).add(ConceptNode(
            id: row['id']! as String,
            world: world,
            nameKeys: {
              'fr': row['fr']! as String,
              'en': row['en']! as String,
            },
            prerequisites:
                ((row['prerequisites'] as List<Object?>?) ?? const [])
                    .cast<String>(),
          ));
    }
    final worlds = byWorld.keys.toList()..sort();
    return ProgressMap(
      worlds: [
        for (final w in worlds)
          WorldNode(number: w, nameKeys: worldNames[w]!, concepts: byWorld[w]!),
      ],
    );
  }
}
