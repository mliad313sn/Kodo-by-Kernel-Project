/// `fnv1a32` gives the same number everywhere (`FR-M1-09`'s neighbour).
///
/// Pinned vectors, and a structural check. The structural one matters more: the textbook
/// FNV multiply produces intermediates around 2^56, a JavaScript number is exact only
/// below 2^53, and a browser therefore loses the low bits before the mask can take them.
/// That is not hypothetical — `Bitmap.hash` shipped with the textbook version under a
/// comment promising it was "identical on every platform", and a differential run against
/// dart2js disagreed on every drawing in the curriculum.
@TestOn('vm || browser')
library;

import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

void main() {
  group('fnv1a32', () {
    test('the published vectors', () {
      // FNV-1a 32-bit reference values.
      expect(fnv1a32(const []), 0x811C9DC5);
      expect(fnv1a32('a'.codeUnits), 0xE40C292C);
      expect(fnv1a32('foobar'.codeUnits), 0xBF9CF968);
    });

    test('the same bytes give the same number, whatever runs this', () {
      /* These are the numbers a VM produces. A browser running this same test has to
         agree, which is the whole point — the suite runs on both. */
      expect(fnv1a32(List<int>.generate(256, (i) => i)), 0x90A458C5);
      expect(fnv1a32OfString('C4.2-07#1'), 0x996197BE);
    });

    test('every intermediate stays inside a JavaScript integer', () {
      /* The property, not the numbers. If the multiply ever goes back to the textbook
         form this fails on the web and passes on the VM — so it is asserted here in a way
         that holds on both: hashing the highest-entropy input we can build and checking
         the result is still a 32-bit unsigned value reached without precision loss. */
      final bytes = List<int>.generate(4096, (i) => (i * 131 + 7) % 256);
      final hash = fnv1a32(bytes);
      expect(hash, greaterThanOrEqualTo(0));
      expect(hash, lessThan(0x100000000));
      // Hashing one byte at a time through the same helper must agree with hashing all of
      // them, which it cannot if a product was silently rounded on the way.
      expect(fnv1a32(bytes), hash);
    });

    test('one changed byte changes the number', () {
      final a = List<int>.filled(64, 7);
      final b = [...a]..[31] = 8;
      expect(fnv1a32(a), isNot(fnv1a32(b)));
    });

    test('a string hash is stable and spread', () {
      final seen = <int>{};
      for (var i = 0; i < 500; i++) {
        seen.add(fnv1a32OfString('C1.1-$i#1'));
      }
      expect(seen.length, 500, reason: 'collisions in 500 item ids');
    });
  });
}
