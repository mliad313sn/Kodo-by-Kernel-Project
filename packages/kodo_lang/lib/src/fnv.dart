/// A 32-bit hash that is the same number on every platform (`FR-M1-09`'s neighbour).
///
/// Written out here for the same reason [SeededRandom] is: KODO needs *one* number from a
/// given input, on an Android phone, on a school desktop and in a browser, forever. A
/// verdict, a choice order and a fingerprint all depend on it.
///
/// **Why it is not the textbook three lines.** FNV-1a is `h = (h ^ byte) * 16777619`, and
/// on a 64-bit VM that product is exact before it is masked. On the web a Dart `int` is a
/// JavaScript number: integers are exact only below 2^53, and `0xFFFFFFFF * 16777619` is
/// about 2^56. The low bits are gone *before* the mask can take them, so the same bytes
/// hash to a different number in a browser than on a phone. The multiply is therefore done
/// in two 16-bit halves, and every intermediate stays below 2^37.
///
/// This was not theoretical: `Bitmap.hash` carried the textbook version under a comment
/// promising it was "identical on every platform", and a differential run against dart2js
/// disagreed on every drawing in the curriculum.
library;

const int _fnvOffsetBasis = 0x811C9DC5;
const int _fnvPrimeLow = 0x0193; // 16777619 = 0x01000193
const int _fnvPrimeHigh = 0x0100;

/// FNV-1a over [bytes], as an unsigned 32-bit integer.
int fnv1a32(Iterable<int> bytes) {
  var hash = _fnvOffsetBasis;
  for (final byte in bytes) {
    hash ^= byte & 0xFF;
    hash = _mul32(hash);
  }
  return hash;
}

/// FNV-1a over the UTF-16 code units of [text].
///
/// Code units rather than UTF-8 bytes, because every caller here hashes an identifier that
/// is ASCII, and because "the same string gives the same number" is the only property
/// asked of it. It is a fingerprint, never a digest: nothing about it is a secret.
int fnv1a32OfString(String text) {
  var hash = _fnvOffsetBasis;
  for (final unit in text.codeUnits) {
    hash ^= unit & 0xFF;
    hash = _mul32(hash);
    hash ^= (unit >> 8) & 0xFF;
    hash = _mul32(hash);
  }
  return hash;
}

/// `(h * 16777619) & 0xFFFFFFFF`, with no intermediate above 2^37.
int _mul32(int h) {
  final low = h & 0xFFFF;
  final high = (h >> 16) & 0xFFFF;
  final lowProduct = low * _fnvPrimeLow;
  final crossProduct = (low * _fnvPrimeHigh + high * _fnvPrimeLow) & 0xFFFF;
  return (lowProduct + (crossProduct << 16)) & 0xFFFFFFFF;
}
