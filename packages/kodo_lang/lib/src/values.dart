/// KodoScript runtime values (FR-M1-03).
///
/// Dynamic typing with *explicit* coercion. A number is never silently true, because
/// "1 means yes" is a misconception the World-7 items exist to break (concept C7.1), and a
/// language that quietly agrees with a misconception teaches it.
library;

/// A value a KodoScript program can hold.
sealed class KodoValue {
  const KodoValue();

  /// The type name as a child sees it, used to build error messages. Locale-resolved by
  /// the message catalogue; this is the key, never the displayed text.
  String get typeKey;

  /// Rendered back into source text. Round-trips through the parser.
  String get source;
}

final class NumberValue extends KodoValue {
  const NumberValue(this.value);
  final num value;

  @override
  String get typeKey => 'type.number';

  @override
  String get source {
    if (value is int) return '$value';
    final d = value as double;
    if (d == d.roundToDouble() && d.abs() < 1e15) return '${d.toInt()}';
    // '.' is the decimal separator in source, whatever the display locale shows
    // (FR-M15-05: the parser accepts '.', the interface may display ',').
    return d.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is NumberValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class StringValue extends KodoValue {
  const StringValue(this.value);
  final String value;

  @override
  String get typeKey => 'type.string';

  @override
  String get source =>
      '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  @override
  bool operator ==(Object other) =>
      other is StringValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class BoolValue extends KodoValue {
  const BoolValue(this.value);
  final bool value;

  static const yes = BoolValue(true);
  static const no = BoolValue(false);

  @override
  String get typeKey => 'type.boolean';

  /// Booleans render as keywords, so they are locale-dependent. [source] gives the
  /// canonical form; the renderer substitutes the active keyword table.
  @override
  String get source => value ? 'true' : 'false';

  @override
  bool operator ==(Object other) => other is BoolValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class ListValue extends KodoValue {
  ListValue(this.items);
  final List<KodoValue> items;

  @override
  String get typeKey => 'type.list';

  @override
  String get source => '[${items.map((e) => e.source).join(', ')}]';
}

/// The result of a command that produces nothing — `avance 100` is an action, not a value.
///
/// Using one in an expression raises `E_NOT_A_VALUE` rather than silently yielding null,
/// because `$x = avance 100` is a real thing a nine-year-old writes and it deserves a
/// sentence, not a null.
final class VoidValue extends KodoValue {
  const VoidValue();
  static const instance = VoidValue();

  @override
  String get typeKey => 'type.nothing';

  @override
  String get source => '';
}
