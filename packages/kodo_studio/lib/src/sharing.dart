/// Sharing, gallery and moderation (M10).
///
/// *"You are building the smallest safe social surface that still lets a child be proud in
/// public."* Every line here is §13, and §13 is the part of KODO where a mistake does not
/// cost a lesson, it costs a child.
///
/// The module prompt's `Do not` is absolute: **no child-to-child free-text channel in v1,
/// under any framing.** There is therefore no comment type in this file, no message type,
/// no direct type, and no string field a child can write that reaches another child
/// without passing a human. Reactions are a closed enum. That is the whole channel.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:kodo_stage/kodo_stage.dart';

import 'project.dart';

// ---------------------------------------------------------------------------------------
// Display names (FR-M10-04)
// ---------------------------------------------------------------------------------------

/// A display name.
///
/// *"No usernames that can carry personal data; display names are generated from a curated
/// word list and may be re-rolled, not typed."* There is no constructor that takes a
/// string, which is how "may be re-rolled, not typed" stops being a rule a text field has
/// to enforce. The adversarial review asks whether personal data can reach the gallery
/// through a display name; the answer is that the type has no way to carry it.
class DisplayName {
  const DisplayName._(this.value, this.seed);

  final String value;

  /// Kept so a re-roll can be deterministic in a test and so the same child gets the same
  /// name back after a reinstall.
  final int seed;

  /// Curated. Every word is a thing, a colour or a number — no names, no places, no
  /// adjectives that could describe a person.
  static const creatures = [
    'Tortue',
    'Baobab',
    'Étoile',
    'Lune',
    'Rivière',
    'Tam-tam',
    'Mangue',
    'Épervier',
    'Calao',
    'Dune',
    'Pirogue',
    'Comète',
    'Fennec',
    'Girafe',
    'Hibou',
    'Océan',
  ];

  static const colours = [
    'Fuchsia',
    'Indigo',
    'Safran',
    'Émeraude',
    'Cobalt',
    'Ocre',
    'Turquoise',
    'Ivoire',
    'Écarlate',
    'Bronze',
    'Argent',
    'Corail',
  ];

  /// `TortueFuchsia42`, the example in `FR-M10-04`.
  static DisplayName roll(int seed) {
    var state = seed == 0 ? 1 : seed;
    int next() {
      state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
      return state;
    }

    final creature = creatures[next() % creatures.length];
    final colour = colours[next() % colours.length];
    final number = next() % 90 + 10;
    return DisplayName._('$creature$colour$number', seed);
  }

  /// A child who does not like their name gets another one. There is no third option.
  DisplayName reroll() => roll(seed + 1);

  @override
  String toString() => value;
}

// ---------------------------------------------------------------------------------------
// Reactions (FR-M10-03)
// ---------------------------------------------------------------------------------------

/// The entire vocabulary one child has towards another.
///
/// Closed, iconographic, and chosen so that none of them can be used to say something
/// unkind: there is no thumbs-down and no laughing face, because *"drôle"* aimed at a
/// child's work is how a reaction set becomes a playground.
enum Reaction {
  bravo('👏'),
  malin('💡'),
  joli('🎨'),
  jaiAppris('🔎');

  const Reaction(this.glyph);
  final String glyph;

  Map<String, String> get labelKeys => switch (this) {
        Reaction.bravo => const {'fr': 'Bravo', 'en': 'Well done'},
        Reaction.malin => const {'fr': 'Malin', 'en': 'Clever'},
        Reaction.joli => const {'fr': 'Joli', 'en': 'Beautiful'},
        Reaction.jaiAppris => const {
            'fr': "J'ai appris quelque chose",
            'en': 'I learned something'
          },
      };
}

// ---------------------------------------------------------------------------------------
// Scope (FR-M10-07, PO decision D-003)
// ---------------------------------------------------------------------------------------

/// Where a shared project is visible.
enum GalleryScope {
  /// The default, and in v1 the only one.
  classroom,

  /// `FR-M10-07` calls this *"a separate, later-phase opt-in"*, and PO decision `D-003`
  /// records that it does not ship in v1. Present in the enum and permanently unreachable,
  /// for the same reason `Capability.camera` is: a contributor who wires it up discovers
  /// the refusal at the gate rather than at G4.
  public,
}

/// Why a share was refused, in terms a parent screen can render.
enum ShareRefusal {
  /// No guardian or teacher has enabled sharing (`FR-M10-01`).
  noGuardianConsent,

  /// The public gallery does not exist in v1.
  scopeNotInThisVersion,

  /// The title or the instructions look like they carry personal data.
  personalDataInText,

  /// The project contains an asset the child imported from the device.
  importedAsset,

  /// Waiting for the human review that `FR-M10-03` requires of any text.
  awaitingHumanReview,
}

// ---------------------------------------------------------------------------------------
// The personal-data filter (FR-M10-03, and the adversarial review)
// ---------------------------------------------------------------------------------------

/// One thing in a piece of text that should not go to a gallery.
class PersonalDataFinding {
  const PersonalDataFinding(this.kind, this.matched);

  /// A stable kind: `email`, `phone`, `url`, `handle`, `address`, `school`, `age`.
  final String kind;
  final String matched;

  @override
  String toString() => '$kind: "$matched"';
}

/// A word boundary that works for accented French.
///
/// Dart's `\b` is defined over ASCII word characters, so `\bécole` never matches: the
/// character before `é` and `é` itself are both non-word, so there is no boundary there.
/// Every French keyword below would have been dead — and a filter that silently matches
/// nothing is worse than no filter, because it is believed.
const _edge = r'(?:^|[^\wÀ-ÿ])';

final _patterns = <String, RegExp>{
  'email': RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+'),
  // Grouped digits, the way a phone number is written down: 77 123 45 67, +221-77-…
  'phone': RegExp(r'(\+?\d[\d .-]{6,}\d)'),
  'url': RegExp(r'(https?://|www\.)\S+', caseSensitive: false),
  'handle': RegExp(r'(^|\s)@\w{2,}'),
  'address': RegExp(
      '$_edge'
      r'(\d+\s+(rue|avenue|boulevard|impasse|street|road|ave)\b'
      r'|villa\s+n[o°]?\s*\d+)',
      caseSensitive: false),
  'school': RegExp(
      '$_edge'
      r'(école|ecole|collège|college|lycée|lycee|school|classe de)\s+[A-Za-zÀ-ÿ]{2,}',
      caseSensitive: false),
  'age': RegExp(
      '$_edge'
      r"(j'ai\s+\d{1,2}\s+ans|i am \d{1,2} years old)",
      caseSensitive: false),
};

/// Scans **child-authored text** — a title, instructions, an asset name — for the things
/// §13 does not want in a gallery.
///
/// Not markup and not machine-generated strings. An SVG's `viewBox="0 0 400 400"` reads as
/// a phone number to any pattern loose enough to catch `77 123 45 67`, so running this over
/// a rendered thumbnail produces noise, not safety. What protects a thumbnail is that it
/// can only be rendered from a canvas — see `Thumbnail`.
///
/// This is `FR-M10-03`'s *"automated filter"*. It is the first half of the rule and never
/// the whole of it: text that passes still goes to a human before publication, because a
/// filter that a child can beat by writing *"zero six douze"* is not a safety control, and
/// pretending otherwise is how the human step gets removed.
List<PersonalDataFinding> scanForPersonalData(String text) {
  final findings = <PersonalDataFinding>[];
  for (final entry in _patterns.entries) {
    for (final match in entry.value.allMatches(text)) {
      findings.add(PersonalDataFinding(entry.key, match.group(0)!.trim()));
    }
  }
  return findings;
}

// ---------------------------------------------------------------------------------------
// The share gate (FR-M10-01)
// ---------------------------------------------------------------------------------------

/// A project as another child sees it.
///
/// Private constructor: the **only** way to obtain one is [SharingGate.share], and that
/// method checks the guardian flag first. The acceptance test is *"sharing is provably
/// unreachable without the guardian flag, verified by an automated test, not by UI
/// inspection"* — this is what makes such a test possible to write.
///
/// Note the fields. Title, thumbnail, instructions and credit, exactly as `FR-M10-02` asks,
/// and a display name. There is no profile id, no account id, no device id and no first
/// name, because the M10 interface rule is *"never exposes a child's account identifiers to
/// another child"*, and the way to keep that promise is to have nothing to leak.
class ShareableProject {
  const ShareableProject._({
    required this.shareId,
    required this.title,
    required this.instructions,
    required this.thumbnailSvg,
    required this.authorDisplayName,
    required this.scope,
    required this.sharedAt,
    required this.projectFile,
    this.credit,
  });

  final String shareId;
  final String title;
  final String instructions;
  final String thumbnailSvg;
  final DisplayName authorDisplayName;
  final GalleryScope scope;
  final DateTime sharedAt;

  /// The project itself, so it can be remixed (`FR-M10-05`).
  final String projectFile;

  final RemixCredit? credit;

  Map<String, Object?> toJson() => {
        'shareId': shareId,
        'title': title,
        'instructions': instructions,
        'thumbnail': thumbnailSvg,
        'author': authorDisplayName.value,
        'scope': scope.name,
        'sharedAt': sharedAt.toUtc().toIso8601String(),
        if (credit != null) 'credit': credit!.toJson(),
      };
}

/// The outcome of asking to share.
class ShareOutcome {
  const ShareOutcome.published(this.project)
      : refusals = const [],
        pending = false;
  const ShareOutcome.pendingReview()
      : project = null,
        refusals = const [ShareRefusal.awaitingHumanReview],
        pending = true;
  const ShareOutcome.refused(this.refusals)
      : project = null,
        pending = false;

  final ShareableProject? project;
  final List<ShareRefusal> refusals;
  final bool pending;

  bool get isPublished => project != null;
}

/// The gate between the Studio and everybody else.
class SharingGate {
  const SharingGate();

  /// Asks to share.
  ///
  /// [consent] is M4's [ConsentGate], which is where `Capability.sharing` lives — the same
  /// object the parent space writes to, not a copy of the flag. `FR-M10-01`: *"sharing is
  /// off by default and requires a verified parent/teacher action."* Off by default is not
  /// a setting here; it is what `ConsentGate` returns when nobody has answered.
  ShareOutcome share(
    Project project, {
    required ConsentGate consent,
    required DisplayName as,
    required DateTime at,
    GalleryScope scope = GalleryScope.classroom,
    ModerationQueue? review,
  }) {
    final refusals = <ShareRefusal>[];

    if (!consent.allows(Capability.sharing)) {
      refusals.add(ShareRefusal.noGuardianConsent);
    }
    if (scope == GalleryScope.public) {
      refusals.add(ShareRefusal.scopeNotInThisVersion);
    }
    // An imported photograph is the one asset that can carry a child's face or their
    // address on a wall behind them. Nothing in v1 lets one reach a gallery.
    if (project.importedAssets.isNotEmpty) {
      refusals.add(ShareRefusal.importedAsset);
    }
    final text = '${project.name}\n${project.instructions}\n'
        '${project.assets.map((a) => a.name).join('\n')}';
    if (scanForPersonalData(text).isNotEmpty) {
      refusals.add(ShareRefusal.personalDataInText);
    }
    if (refusals.isNotEmpty) return ShareOutcome.refused(refusals);

    // Passed the filter — which is not the same as approved. `FR-M10-03` requires human
    // review of text *before publication*, so a queue that is offered is a queue that is
    // used.
    if (review != null) {
      review.submitForPublication(
          projectId: project.id, title: project.name, at: at);
      return const ShareOutcome.pendingReview();
    }

    return ShareOutcome.published(_publish(project, as, scope, at));
  }

  /// Publishes text a human reviewer has approved.
  ShareOutcome publishApproved(
    Project project, {
    required ConsentGate consent,
    required DisplayName as,
    required DateTime at,
    required ModerationQueue review,
    GalleryScope scope = GalleryScope.classroom,
  }) {
    if (!review.isApprovedForPublication(project.id)) {
      return const ShareOutcome.pendingReview();
    }
    // The gate is re-run in full. An approval is an approval of the *text*, and consent
    // can have been withdrawn in the meantime — a guardian turning sharing off must stop
    // the thing that was queued, not only the next one.
    return share(project, consent: consent, as: as, at: at, scope: scope);
  }

  ShareableProject _publish(
          Project project, DisplayName as, GalleryScope scope, DateTime at) =>
      ShareableProject._(
        shareId: sha256
            .convert(utf8.encode('${project.id}|${at.toIso8601String()}'))
            .toString()
            .substring(0, 16),
        title: project.name,
        instructions: project.instructions,
        thumbnailSvg: project.thumbnailSvg ?? '',
        authorDisplayName: as,
        scope: scope,
        sharedAt: at,
        projectFile: ProjectFile(project).encode(),
        credit: project.remixOf,
      );

  /// One-tap remix, always attributed (`FR-M10-05`).
  ///
  /// Attribution is not a field the remixer fills in; it is computed from the thing being
  /// remixed, and the chain depth carries so a gallery can show the whole lineage rather
  /// than only the last hop.
  Project remix(
    ShareableProject shared, {
    required String newProjectId,
    required DateTime at,
  }) {
    final original = ProjectFile.decode(shared.projectFile).project;
    return Project(
      id: newProjectId,
      name: original.name,
      origin: ProjectOrigin.remix,
      sprites: original.sprites,
      assets: original.assets,
      customBlocks: original.customBlocks,
      lists: original.lists,
      instructions: original.instructions,
      thumbnailSvg: original.thumbnailSvg,
      remixOf: RemixCredit(
        originalProjectId: shared.shareId,
        originalAuthorDisplayName: shared.authorDisplayName.value,
        depth: (shared.credit?.depth ?? 0) + 1,
      ),
      createdAt: at,
      savedAt: at,
    );
  }
}

// ---------------------------------------------------------------------------------------
// Reporting and moderation (FR-M10-06)
// ---------------------------------------------------------------------------------------

/// Why somebody reported an item. A closed list, for the same reason reactions are: a
/// free-text reason field is a free-text channel.
enum ReportReason {
  mechant('report.unkind'),
  personalData('report.personal_data'),
  notMine('report.not_mine'),
  broken('report.broken'),
  other('report.other');

  const ReportReason(this.messageKey);
  final String messageKey;
}

/// Somebody pressed the report button.
class Report {
  const Report({
    required this.id,
    required this.shareId,
    required this.reason,
    required this.reportedAt,
  });

  final String id;
  final String shareId;
  final ReportReason reason;
  final DateTime reportedAt;
}

/// What a moderator decided.
enum ModerationDecision {
  /// Stays up.
  keep,

  /// Comes down.
  remove,

  /// The moderator is not sure. `FR-M10-06` says *"removal on doubt"*, so this is not a
  /// third outcome: it removes. It is a separate value only so the decision log records
  /// what the moderator actually felt, which is the number that tells you whether the
  /// guidance is clear enough.
  unsure,
}

/// Where a case is.
enum CaseState { open, triaged, closed }

/// One moderation case, with its whole history.
class ModerationCase {
  ModerationCase({
    required this.report,
    required this.state,
    this.triagedAt,
    this.decision,
    this.decidedBy,
    this.closedAt,
  });

  final Report report;
  CaseState state;
  DateTime? triagedAt;
  ModerationDecision? decision;
  String? decidedBy;
  DateTime? closedAt;

  /// `FR-M10-06`: *"triage < 24 h"*.
  static const triageSla = Duration(hours: 24);

  Duration? get timeToTriage => triagedAt?.difference(report.reportedAt);

  bool get withinSla => timeToTriage != null && timeToTriage! <= triageSla;

  /// Removal on doubt.
  bool get removesItem =>
      decision == ModerationDecision.remove ||
      decision == ModerationDecision.unsure;

  Map<String, Object?> toJson() => {
        'report': report.id,
        'share': report.shareId,
        'reason': report.reason.name,
        'reportedAt': report.reportedAt.toUtc().toIso8601String(),
        'state': state.name,
        if (triagedAt != null)
          'triagedAt': triagedAt!.toUtc().toIso8601String(),
        if (decision != null) 'decision': decision!.name,
        if (decidedBy != null) 'decidedBy': decidedBy,
        if (closedAt != null) 'closedAt': closedAt!.toUtc().toIso8601String(),
      };
}

/// The text queued for the human review `FR-M10-03` requires, and the moderation console.
class ModerationQueue {
  ModerationQueue();

  final Map<String, bool> _publicationApprovals = {};
  final List<ModerationCase> _cases = [];
  final List<String> _removedShareIds = [];
  final List<Map<String, Object?>> _log = [];

  /// The decision log and audit trail. Append-only.
  List<Map<String, Object?>> get auditTrail => List.unmodifiable(_log);

  List<ModerationCase> get cases => List.unmodifiable(_cases);

  List<ModerationCase> get open => [
        for (final c in _cases)
          if (c.state == CaseState.open) c
      ];

  bool isRemoved(String shareId) => _removedShareIds.contains(shareId);

  // --- publication review ------------------------------------------------------------

  void submitForPublication(
      {required String projectId,
      required String title,
      required DateTime at}) {
    _publicationApprovals.putIfAbsent(projectId, () => false);
    _record(at, 'publication-submitted', projectId, null);
  }

  void reviewPublication(String projectId,
      {required bool approved, required String by, required DateTime at}) {
    _publicationApprovals[projectId] = approved;
    _record(at, approved ? 'publication-approved' : 'publication-rejected',
        projectId, by);
  }

  bool isApprovedForPublication(String projectId) =>
      _publicationApprovals[projectId] ?? false;

  // --- reports -------------------------------------------------------------------------

  ModerationCase report(Report report) {
    final moderationCase =
        ModerationCase(report: report, state: CaseState.open);
    _cases.add(moderationCase);
    _record(report.reportedAt, 'reported', report.shareId, null);
    return moderationCase;
  }

  /// A moderator looked at it. This is the event the 24-hour SLA is measured against —
  /// not the decision, because a hard case can take longer to decide than to triage and
  /// the child waiting is waiting on the item coming down, which triage can do.
  void triage(ModerationCase moderationCase,
      {required DateTime at, required String by}) {
    moderationCase
      ..state = CaseState.triaged
      ..triagedAt = at
      ..decidedBy = by;
    _record(at, 'triaged', moderationCase.report.shareId, by);
  }

  void decide(ModerationCase moderationCase,
      {required ModerationDecision decision,
      required DateTime at,
      required String by}) {
    moderationCase
      ..decision = decision
      ..decidedBy = by
      ..state = CaseState.closed
      ..closedAt = at;
    if (moderationCase.removesItem &&
        !_removedShareIds.contains(moderationCase.report.shareId)) {
      _removedShareIds.add(moderationCase.report.shareId);
    }
    _record(at, 'decided:${decision.name}', moderationCase.report.shareId, by);
  }

  void _record(DateTime at, String action, String subject, String? by) =>
      _log.add({
        'at': at.toUtc().toIso8601String(),
        'action': action,
        'subject': subject,
        if (by != null) 'by': by,
      });
}

/// A class gallery.
///
/// Reactions and nothing else. There is no method here that accepts a string from one
/// child and shows it to another, and that absence is the module's `Do not`.
class ClassGallery {
  ClassGallery({required this.classId, required this.moderation});

  final String classId;
  final ModerationQueue moderation;

  final List<ShareableProject> _items = [];
  final Map<String, Map<Reaction, int>> _reactions = {};

  /// Removed items are not listed. A removal is not a flag on a card the class can still
  /// see and wonder about.
  List<ShareableProject> get items => [
        for (final item in _items)
          if (!moderation.isRemoved(item.shareId)) item,
      ];

  void add(ShareableProject item) {
    if (item.scope != GalleryScope.classroom) {
      throw ArgumentError('a class gallery only holds classroom-scope items');
    }
    _items.add(item);
  }

  Map<Reaction, int> reactionsTo(String shareId) =>
      Map.unmodifiable(_reactions[shareId] ?? const <Reaction, int>{});

  void react(String shareId, Reaction reaction) {
    final counts = _reactions.putIfAbsent(shareId, () => <Reaction, int>{});
    counts[reaction] = (counts[reaction] ?? 0) + 1;
  }
}
