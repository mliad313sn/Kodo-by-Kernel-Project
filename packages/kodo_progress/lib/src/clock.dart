/// Time, made testable and made hard to cheat.
///
/// Three things in §4.6 depend on time and all three are hostile environments: the
/// 72-hour retention window, the 21-day decay, and a child on a shared family phone whose
/// clock is wrong. Everything here is UTC, and the store keeps the latest time it has ever
/// seen so that a clock moved *backwards* cannot rewind a child's progress — or be used to
/// move it forwards.
library;

/// A source of the current time. Injected everywhere, so no test has to sleep.
abstract class Clock {
  DateTime nowUtc();

  static const Clock system = _SystemClock();
}

class _SystemClock implements Clock {
  const _SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// A clock a test drives by hand.
class TestClock implements Clock {
  TestClock(this._now);
  DateTime _now;

  @override
  DateTime nowUtc() => _now.toUtc();

  void advance(Duration by) => _now = _now.add(by);
  void set(DateTime to) => _now = to;
}

/// Wraps a [Clock] and refuses to go backwards.
///
/// A device clock that jumps back — a shared phone, a factory reset, a timezone the OS
/// got wrong — must not be able to un-earn a retention check or reset a decay counter.
/// The watermark is persisted with the rest of the profile, so it survives a restart.
class MonotonicClock implements Clock {
  MonotonicClock(this._inner, {DateTime? watermark})
      : _watermark = watermark?.toUtc() ?? _inner.nowUtc();

  final Clock _inner;
  DateTime _watermark;

  /// The latest instant ever observed. Persisted.
  DateTime get watermark => _watermark;

  @override
  DateTime nowUtc() {
    final now = _inner.nowUtc();
    if (now.isAfter(_watermark)) _watermark = now;
    return _watermark;
  }

  /// True when the device clock is currently behind what we have already seen.
  ///
  /// Worth surfacing to a teacher rather than hiding: a classroom of devices with wrong
  /// clocks is a real thing, and silently freezing every child's retention timer would be
  /// a mystery nobody could debug.
  bool get deviceClockIsBehind => _inner.nowUtc().isBefore(_watermark);
}
