/// Deterministic pseudo-random numbers (FR-M1-09).
///
/// `dart:math`'s `Random` gives no cross-platform, cross-version stability guarantee, and
/// grading depends on one: an item graded on a phone and re-graded on a school desktop
/// must reach the same verdict, and a shared project must replay identically. So the
/// generator is written out here — 32-bit xorshift, ten lines, and the same numbers
/// everywhere forever.
library;

class SeededRandom {
  SeededRandom(int seed)
      : _state = seed == 0 ? 0x9E3779B9 : (seed & 0xFFFFFFFF);

  int _state;

  int get seed => _state;

  int _next() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return _state;
  }

  /// Uniform integer in `[min, max]` inclusive.
  ///
  /// Inclusive at both ends because `hasard 1, 6` is a die, and a die that never rolls a
  /// six would be a bug a child notices before we do.
  int nextIntInclusive(int min, int max) {
    if (max <= min) return min;
    final span = max - min + 1;
    return min + (_next() % span);
  }

  double nextDouble() => _next() / 0x100000000;
}
