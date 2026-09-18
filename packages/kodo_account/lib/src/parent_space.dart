/// The parent space (M11).
///
/// *"You are building the screen that earns a parent's trust in ninety seconds."*
///
/// The weekly summary's shape is set by `FR-M11-02` and by the module prompt's `Do not`:
/// time, concepts mastered, **what that concept actually is**, and one question to ask the
/// child at dinner — with no unexplained jargon. The last two are the ones that do the
/// work: a parent who can ask their child a good question at dinner has been given
/// something no dashboard gives them.
library;

import 'package:kodo_insight/kodo_insight.dart';

/// How the parent space is locked (`FR-M11-01`).
enum ParentGate { pin, biometric }

/// The gate. A child cannot pass it, and the test tries.
class ParentSpaceLock {
  ParentSpaceLock({required this.gate, String? pin}) : _pin = pin;

  final ParentGate gate;
  final String? _pin;
  bool _open = false;

  bool get isOpen => _open;

  /// A PIN is digits only and at least four of them. It is checked here rather than in a
  /// text field, because a validation that lives in the interface is one an alternative
  /// interface does not have.
  static bool isAcceptablePin(String pin) =>
      pin.length >= 4 && RegExp(r'^\d+$').hasMatch(pin);

  bool unlockWithPin(String attempt) {
    if (gate != ParentGate.pin) return false;
    _open = _pin != null && attempt == _pin;
    return _open;
  }

  bool unlockWithBiometric({required bool verified}) {
    if (gate != ParentGate.biometric) return false;
    _open = verified;
    return _open;
  }

  void close() => _open = false;
}

/// One concept, explained to someone who has never written a program.
class ConceptExplanation {
  const ConceptExplanation({
    required this.conceptId,
    required this.childWordsKeys,
    required this.parentWordsKeys,
    required this.dinnerQuestionKeys,
  });

  final String conceptId;

  /// What the tutorial called it, in the child's words. The **same string** the tutorial
  /// closed with (`FR-M5-06`) and the progress map shows — authored once, reused.
  final Map<String, String> childWordsKeys;

  /// What it actually is, for an adult with no coding background.
  final Map<String, String> parentWordsKeys;

  /// `FR-M11-02`'s one thing to ask at dinner.
  final Map<String, String> dinnerQuestionKeys;

  String childWordsIn(String locale) =>
      childWordsKeys[locale] ?? childWordsKeys['fr'] ?? conceptId;
  String parentWordsIn(String locale) =>
      parentWordsKeys[locale] ?? parentWordsKeys['fr'] ?? '';
  String dinnerQuestionIn(String locale) =>
      dinnerQuestionKeys[locale] ?? dinnerQuestionKeys['fr'] ?? '';
}

/// The one screen (`FR-M11-02`).
class WeeklySummary {
  const WeeklySummary({
    required this.weekEnding,
    required this.minutesThisWeek,
    required this.conceptsMastered,
    required this.explanations,
    required this.wellbeing,
    required this.locale,
  });

  final DateTime weekEnding;
  final int minutesThisWeek;
  final List<String> conceptsMastered;
  final Map<String, ConceptExplanation> explanations;

  /// The wellbeing counters, shown to the parent as well as to the Committee. A parent who
  /// is told their child was frustrated eleven times this week can do something about it;
  /// a parent shown only a streak cannot.
  final Map<EventKindSummary, int> wellbeing;

  final String locale;

  /// The dinner question for this week — one, from the most recent concept.
  String? get dinnerQuestion => conceptsMastered.isEmpty
      ? null
      : explanations[conceptsMastered.last]?.dinnerQuestionIn(locale);

  /// The lines the screen shows, in order. Returned as data so the readability and
  /// jargon checks can run over the real thing.
  List<String> lines() {
    final out = <String>[
      locale == 'en'
          ? 'This week: $minutesThisWeek minutes.'
          : 'Cette semaine : $minutesThisWeek minutes.',
    ];
    if (conceptsMastered.isEmpty) {
      out.add(locale == 'en'
          ? 'No new idea finished this week. That is normal.'
          : 'Aucune nouvelle idée terminée cette semaine. C\'est normal.');
    }
    for (final id in conceptsMastered) {
      final explanation = explanations[id];
      if (explanation == null) continue;
      out.add('${explanation.childWordsIn(locale)} — '
          '${explanation.parentWordsIn(locale)}');
    }
    final question = dinnerQuestion;
    if (question != null) {
      out.add(locale == 'en'
          ? 'Ask at dinner: $question'
          : 'À table, demande-lui : $question');
    }
    return out;
  }
}

/// What a guardian controls (`FR-M11-03`).
///
/// Every one of these is a switch a parent can find in ninety seconds. There is no
/// "advanced" section, because a control a parent cannot find is a control they do not
/// have.
enum ParentControl {
  dailyTimeCap,
  sharing,
  camera,
  microphone,
  sound,
  dataSync,
  dataExport,
  accountDeletion,
}

/// The purchase surface of `FR-M11-04`.
///
/// It lives here and only here, and under PO decision D-001 it is **empty in v1**. The type
/// exists so that the architecture makes the rule true — there is nowhere else in the
/// product that could hold one — rather than relying on nobody adding one elsewhere.
class PurchaseSurface {
  const PurchaseSurface({this.offers = const []});

  /// Empty at v1 by PO decision D-001: the whole learning path is free, permanently.
  final List<String> offers;

  bool get isEmpty => offers.isEmpty;

  /// Always false. A purchase surface is reachable only from inside an unlocked parent
  /// space, and a child cannot unlock one.
  static bool get visibleToChild => false;
}
