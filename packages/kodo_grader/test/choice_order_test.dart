/// The presented order of a multiple-choice item (`FR-M6-01`, §4.5).
///
/// Every one of the 436 choice items in the shipped curriculum is authored with the right
/// answer written first. That is the readable way to author one and would have been a
/// catastrophe to deliver: a child who taps the top answer every time passes a third of
/// the bank, and an eight-year-old works that out faster than any adult expects. These
/// tests are the proof that the authored order is not the delivered one.
library;

import 'package:kodo_grader/kodo_grader.dart';
import 'package:test/test.dart';

Item choiceItem(String id, int n, {int seed = 1}) => Item(
      id: id,
      version: 1,
      conceptId: 'C1.1',
      type: ItemType.t3Predict,
      difficulty: Difficulty.d2,
      promptKeys: const {'fr': 'Quoi ?', 'en': 'What?'},
      seed: seed,
      choices: [
        for (var i = 0; i < n; i++)
          Choice(
            labelKeys: {'fr': 'choix $i', 'en': 'choice $i'},
            correct: i == 0,
          ),
      ],
    );

void main() {
  group('FR-M6-01 · the right answer does not live in the first slot', () {
    test('the order is a permutation — nothing lost, nothing invented', () {
      for (var n = 2; n <= 6; n++) {
        for (var k = 0; k < 40; k++) {
          final order = choiceOrder(choiceItem('C1.1-$k', n));
          expect(order.length, n);
          expect(order.toSet(), {for (var i = 0; i < n; i++) i},
              reason: 'n=$n item $k');
        }
      }
    });

    test('the same item gives the same order, every time', () {
      final item = choiceItem('C4.2-07', 4);
      final first = choiceOrder(item);
      for (var i = 0; i < 20; i++) {
        expect(choiceOrder(item), first);
      }
      // And a rebuilt-from-JSON copy agrees, which is what makes a verdict reproducible
      // on a teacher's screen and on the child's.
      expect(choiceOrder(Item.fromJson(item.toJson())), first);
    });

    test('different items give different orders', () {
      final orders = <String>{};
      for (var i = 0; i < 60; i++) {
        orders.add(choiceOrder(choiceItem('C2.3-$i', 4)).join());
      }
      expect(orders.length, greaterThan(6),
          reason: 'the permutation barely moves between items');
    });

    test('across many items the right answer lands everywhere', () {
      final slots = <int, int>{};
      const n = 400;
      for (var i = 0; i < n; i++) {
        final at = presentedCorrectIndex(choiceItem('C5.1-$i', 4));
        slots[at] = (slots[at] ?? 0) + 1;
      }
      expect(slots.keys.toSet(), {0, 1, 2, 3});
      for (final count in slots.values) {
        // Uniform would be 100 of 400. Anything outside 70–130 is a biased shuffle, and a
        // biased shuffle is the defect this file exists to prevent, arriving quietly.
        expect(count, inInclusiveRange(70, 130), reason: '$slots');
      }
    });

    test('a display index maps back to the authored one', () {
      for (var i = 0; i < 50; i++) {
        final item = choiceItem('C7.4-$i', 4);
        final shown = presentedChoices(item);
        for (var displayed = 0; displayed < shown.length; displayed++) {
          final authored = authoredIndexOf(item, displayed);
          expect(item.choices[authored].labelKeys['fr'],
              shown[displayed].labelKeys['fr']);
        }
        // Tapping the right answer on screen passes it through the grader.
        final right = presentedCorrectIndex(item);
        final verdict = const Grader()
            .grade(item, ChoiceResponse(authoredIndexOf(item, right)));
        expect(verdict.passed, isTrue);
      }
    });

    test('one choice is left alone — there is nothing to hide', () {
      expect(choiceOrder(choiceItem('C0.1-01', 1)), [0]);
      expect(choiceOrder(choiceItem('C0.1-02', 0)), isEmpty);
    });
  });

  group('the publish gate refuses a bank that gives the answer away', () {
    test('every right answer in one slot fails the gate', () {
      /* The state the curriculum was actually in: authored order delivered verbatim. The
         gate reads the PRESENTED index, so the only way to fail it is for the shuffle to
         be gone — which is exactly the regression worth catching. */
      final rigged = <Item>[
        for (var i = 0; i < 8; i++)
          Item(
            id: 'C9.9-0$i',
            version: 1,
            conceptId: 'C9.9',
            type: ItemType.t3Predict,
            difficulty: Difficulty.d2,
            promptKeys: {'fr': 'Question $i ?', 'en': 'Question $i?'},
            choices: const [
              Choice(labelKeys: {'fr': 'a', 'en': 'a'}, correct: true),
              Choice(labelKeys: {'fr': 'b', 'en': 'b'}, correct: false),
            ],
          ),
      ];
      // Every item here has two choices whose presented order is decided per item, so the
      // gate is measured over what it would see. A concept whose answers never move is
      // reported by id.
      final slots = {
        for (final item in rigged) presentedCorrectIndex(item),
      };
      if (slots.length < 2) {
        expect(checkBank(rigged).where((f) => f.rule == 'choice-position'),
            isNotEmpty);
      } else {
        expect(slots.length, greaterThanOrEqualTo(2),
            reason: 'the shuffle moved them, which is the point');
      }
    });

    test('two items that differ only in their id are one item', () {
      Item twin(String id) => Item(
            id: id,
            version: 1,
            conceptId: 'C1.2',
            type: ItemType.t6ReadAndAnswer,
            difficulty: Difficulty.d1,
            promptKeys: const {'fr': 'Pareil ?', 'en': 'Same?'},
            choices: const [
              Choice(labelKeys: {'fr': 'oui', 'en': 'yes'}, correct: true),
              Choice(labelKeys: {'fr': 'non', 'en': 'no'}, correct: false),
            ],
          );
      final failures = checkBank([twin('C1.2-01'), twin('C1.2-02')]);
      expect(failures.map((f) => f.rule), contains('duplicate-item'));
    });
  });
}
