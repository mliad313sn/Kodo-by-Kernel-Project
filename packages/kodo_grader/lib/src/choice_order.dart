/// The order a child actually sees the choices in (`FR-M6-01`, §4.5).
///
/// **Why this file exists.** Every one of the 436 multiple-choice items in the shipped
/// curriculum was authored with the right answer written first — which is the readable way
/// to author one, and was a catastrophe to deliver. A child who taps the first answer every
/// time passes 35 % of the bank, and an eight-year-old finds that out faster than any
/// adult expects. The authored order is kept, because an author reading a JSON file should
/// see the right answer at the top; the *presented* order is derived.
///
/// **Why it is derived rather than shuffled at authoring time.** A verdict has to be
/// reproducible. `FR-M6-09` says a fix to an item never retroactively invalidates a child's
/// mastery, telemetry records which index was chosen, and a teacher looking over a
/// shoulder has to see the same screen the child sees. A permutation computed from the
/// item's own identity gives all of that: the same item shows the same order on a phone, on
/// a desktop and in a browser, this year and next, and nothing has to be stored.
///
/// **Why not per child.** Two children at one table seeing different orders would stop
/// them copying, and would also stop a teacher helping one of them. Per item is the
/// trade the classroom wants.
library;

import 'package:kodo_lang/kodo_lang.dart';

import 'item.dart';

/// The authored indices of [item]'s choices, in the order to put them on screen.
///
/// Empty for an item with no choices. A single choice is returned unchanged — there is
/// nothing to hide.
List<int> choiceOrder(Item item) {
  final n = item.choices.length;
  if (n < 2) return List<int>.generate(n, (i) => i);

  /* Seeded from the item's id and its own seed, through the web-safe FNV — so the order is
     a property of the item rather than of the device, the run or the clock. */
  final random = SeededRandom(
      (fnv1a32OfString('${item.id}#${item.seed}') & 0x7FFFFFFF) | 1);
  final order = List<int>.generate(n, (i) => i);

  /* Fisher-Yates, downwards, which is the one that is actually uniform. The naive
     "swap each element with a random one" is not, and a subtly biased shuffle would put
     the right answer in one slot slightly too often — exactly the defect this file is
     here to remove. */
  for (var i = n - 1; i > 0; i--) {
    final j = random.nextIntInclusive(0, i);
    final held = order[i];
    order[i] = order[j];
    order[j] = held;
  }
  return order;
}

/// [item]'s choices in the order the child sees them.
List<Choice> presentedChoices(Item item) =>
    [for (final i in choiceOrder(item)) item.choices[i]];

/// The authored index behind the [displayed]th thing on screen.
///
/// The grader is given authored indices and knows nothing about presentation — which is
/// what keeps a stored verdict readable a year later, when the shuffle may have been
/// changed and the telemetry has not.
int authoredIndexOf(Item item, int displayed) {
  final order = choiceOrder(item);
  if (displayed < 0 || displayed >= order.length) return displayed;
  return order[displayed];
}

/// Where the right answer ends up on screen. Used by the publish gate.
int presentedCorrectIndex(Item item) {
  final order = choiceOrder(item);
  for (var displayed = 0; displayed < order.length; displayed++) {
    if (item.choices[order[displayed]].correct) return displayed;
  }
  return -1;
}
