/// Syntax highlighting (FR-M3-01, Annex B, FR-M16-01).
///
/// Annex B inherits the source manual's colour semantics and then says the thing that
/// matters: *"adjusted for WCAG AA and colour-blind safety"*. The original table was
/// written for a desktop editor on white; several of its colours do not clear 4.5:1 on a
/// dark background, and two of them collapse together under deuteranopia.
///
/// So the colours here are the Annex B **semantics** with the Annex B **values adjusted**,
/// and a test checks every one against both themes. A highlight scheme that fails contrast
/// is not a styling preference; it is a child who cannot read their own program.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The categories Annex B names.
enum SyntaxCategory {
  command,
  controlFlow,
  comment,
  brace,
  learn,
  string,
  number,
  boolean,
  variable,
  mathOperator,
  comparisonOperator,
  booleanOperator,
  error,
}

/// One category's appearance in one theme.
class SyntaxStyle {
  const SyntaxStyle(this.colour, {this.bold = false, this.italic = false});
  final Color colour;
  final bool bold;
  final bool italic;

  TextStyle toTextStyle(double fontSize, String? fontFamily) => TextStyle(
        color: colour,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );
}

/// A full scheme, plus the background it is read against.
class SyntaxTheme {
  const SyntaxTheme({
    required this.name,
    required this.background,
    required this.styles,
  });

  final String name;
  final Color background;
  final Map<SyntaxCategory, SyntaxStyle> styles;

  SyntaxStyle styleFor(SyntaxCategory category) =>
      styles[category] ?? styles[SyntaxCategory.command]!;

  /// WCAG 2.2 contrast ratio of [category] against [background].
  double contrastOf(SyntaxCategory category) =>
      _contrast(styleFor(category).colour, background);

  /// Annex B, on a light background.
  ///
  /// Two deliberate departures from the source table, both recorded rather than silently
  /// applied: grey comments are darkened from the usual mid-grey so they clear 4.5:1
  /// rather than the 3:1 that "decorative" text usually gets — a comment is a debugging
  /// tool in World 11, so a child has to be able to read it — and "light blue" comparison
  /// operators are darkened for the same reason.
  static const light = SyntaxTheme(
    name: 'clair',
    background: Color(0xFFFFFFFF),
    styles: {
      SyntaxCategory.command: SyntaxStyle(Color(0xFF00308F)),
      SyntaxCategory.controlFlow: SyntaxStyle(Color(0xFF111111), bold: true),
      SyntaxCategory.comment: SyntaxStyle(Color(0xFF5A5A5A), italic: true),
      SyntaxCategory.brace: SyntaxStyle(Color(0xFF14532D), bold: true),
      SyntaxCategory.learn: SyntaxStyle(Color(0xFF166534), bold: true),
      SyntaxCategory.string: SyntaxStyle(Color(0xFFB00020)),
      SyntaxCategory.number: SyntaxStyle(Color(0xFF8A1C1C)),
      SyntaxCategory.boolean: SyntaxStyle(Color(0xFF8A1C1C), bold: true),
      SyntaxCategory.variable: SyntaxStyle(Color(0xFF6A1B9A)),
      SyntaxCategory.mathOperator: SyntaxStyle(Color(0xFF4A4A4A)),
      SyntaxCategory.comparisonOperator:
          SyntaxStyle(Color(0xFF0B5A73), bold: true),
      SyntaxCategory.booleanOperator:
          SyntaxStyle(Color(0xFFA1176B), bold: true),
      SyntaxCategory.error: SyntaxStyle(Color(0xFFB00020), bold: true),
    },
  );

  /// The same semantics on a dark background. Not an inversion: each colour is re-chosen
  /// so that the *relationships* survive — commands stay blue, strings stay red — while
  /// every one clears AA against the new background.
  static const dark = SyntaxTheme(
    name: 'sombre',
    background: Color(0xFF14161A),
    styles: {
      SyntaxCategory.command: SyntaxStyle(Color(0xFF8AB4F8)),
      SyntaxCategory.controlFlow: SyntaxStyle(Color(0xFFF5F5F5), bold: true),
      SyntaxCategory.comment: SyntaxStyle(Color(0xFFA6A6A6), italic: true),
      SyntaxCategory.brace: SyntaxStyle(Color(0xFF7EE2A8), bold: true),
      SyntaxCategory.learn: SyntaxStyle(Color(0xFF9BE8B4), bold: true),
      SyntaxCategory.string: SyntaxStyle(Color(0xFFFF8A80)),
      SyntaxCategory.number: SyntaxStyle(Color(0xFFFFAB91)),
      SyntaxCategory.boolean: SyntaxStyle(Color(0xFFFFAB91), bold: true),
      SyntaxCategory.variable: SyntaxStyle(Color(0xFFD7A6F3)),
      SyntaxCategory.mathOperator: SyntaxStyle(Color(0xFFBDBDBD)),
      SyntaxCategory.comparisonOperator:
          SyntaxStyle(Color(0xFF7FD4EC), bold: true),
      SyntaxCategory.booleanOperator:
          SyntaxStyle(Color(0xFFF7A1CE), bold: true),
      SyntaxCategory.error: SyntaxStyle(Color(0xFFFF8A80), bold: true),
    },
  );

  static const all = [light, dark];
}

double _channel(int v) {
  final s = v / 255.0;
  return s <= 0.03928
      ? s / 12.92
      : math.pow((s + 0.055) / 1.055, 2.4) as double;
}

double _luminance(Color c) {
  final r = (c.r * 255).round();
  final g = (c.g * 255).round();
  final b = (c.b * 255).round();
  return 0.2126 * _channel(r) + 0.7152 * _channel(g) + 0.0722 * _channel(b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Exposed for the contrast audit test.
double contrastRatio(Color a, Color b) => _contrast(a, b);
